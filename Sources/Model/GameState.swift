import Foundation

/// The entire save file.
///
/// The three persistence layers live in three sibling sub-structs and never reach into each
/// other. A future "reset base, keep reality" is then literally:
///
///     state.base = BaseState.newGame()
///     state.worlds = WorldsState.newGame(...)
///     // state.reality untouched
///
/// Nothing in this tree may store wall-clock time as a gameplay input (pillar 2). `SaveMeta`
/// carries timestamps for *diagnostics only* and no game rule may read them.
struct GameState: Codable, Equatable, Sendable {
    var schemaVersion: Int
    var meta: SaveMeta

    // MARK: The three layers
    /// Layer 1 — survives everything, including future base resets.
    var reality: RealityState
    /// Layer 2 — persists between runs, wiped by a future reset.
    var base: BaseState
    /// Layer 3 — instanced runs; disposable in v0.
    var worlds: WorldsState
    /// Versioned, durable contextual-help progress. It is neither world simulation nor campaign
    /// progression, and old saves infer already-accomplished lessons without presenting them.
    var tutorial: TutorialState

    static func newGame() -> GameState {
        var seeds = SeedSequence.newGame()
        return GameState(
            schemaVersion: Tuning.saveSchemaVersion,
            meta: SaveMeta(),
            reality: RealityState.newGame(),
            base: BaseState.newGame(),
            worlds: WorldsState.newGame(seeds: &seeds),
            tutorial: TutorialState()
        )
    }

    // Decoded tolerantly: a save written by an older build that lacks a whole layer still loads
    // (that layer resets to its new-game value) instead of taking the player's progress with it.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? Tuning.saveSchemaVersion
        meta = try container.decodeIfPresent(SaveMeta.self, forKey: .meta) ?? SaveMeta()
        reality = try container.decodeIfPresent(RealityState.self, forKey: .reality) ?? .newGame()
        base = try container.decodeIfPresent(BaseState.self, forKey: .base) ?? .newGame()
        tutorial = TutorialState()
        var seeds = SeedSequence.newGame()
        worlds = try container.decodeIfPresent(WorldsState.self, forKey: .worlds) ?? .newGame(seeds: &seeds)
        if schemaVersion >= 12 {
            let runs = [worlds.activeRun].compactMap { $0 } + worlds.anchoredRealms.map(\.world)
            guard runs.allSatisfy({ run in
                if let receipt = run.recoveredTeachingExpedition {
                    return receipt.validates(map: run.map, worldSeed: run.mapSeed,
                                             recovered: reality.library.recoveredTeachings)
                }
                return !run.map.tiles.contains { tile in
                    if case .recoveredTeaching = tile.content { return true }
                    return false
                }
            }) else { throw CocoaError(.coderInvalidValue) }
        }
        if schemaVersion >= 13 {
            let recognized = Set(reality.curioFamilyKnowledge.values.filter(\.isRecognized)
                .map(\.familyID))
            let runs = [worlds.activeRun].compactMap { $0 } + worlds.anchoredRealms.map(\.world)
            let owned = base.inventory.stacks + base.spillover
                + runs.flatMap { $0.satchelItems.stacks + $0.offeredItems }
            guard !owned.contains(where: { !$0.identified && recognized.contains($0.catalogID) })
            else { throw CocoaError(.coderInvalidValue) }
        }
        if schemaVersion >= 14 {
            for animal in reality.tamedAnimals.values {
                let key = RealityState.AnimalTrustRecordV1.key(
                    worldSeed: animal.originWorldSeed, enemyID: animal.originEnemyID)
                guard let trust = reality.animalTrustRecords[key], trust.completed,
                      trust.traits == animal.traits, trust.speciesID == animal.speciesID,
                      trust.creatureID == animal.creatureID,
                      trust.condition == animal.trustCondition else {
                    throw CocoaError(.coderInvalidValue)
                }
            }
            let runs = [worlds.activeRun].compactMap { $0 } + worlds.anchoredRealms.map(\.world)
            guard runs.allSatisfy({ run in
                !run.enemies.contains { enemy in
                    reality.tamedAnimals.values.contains {
                        $0.originWorldSeed == run.mapSeed && $0.originEnemyID == enemy.id
                    }
                }
            }) else { throw CocoaError(.coderInvalidValue) }
        }
        if schemaVersion >= 15, !validatesAnimalCompanionCombat() {
            throw CocoaError(.coderInvalidValue)
        }
        if schemaVersion >= 19 {
            guard worlds.expeditionReviewQueue.pending.allSatisfy({
                $0.summary.validatesPhysicalGearCustody()
            }), validatesPhysicalGearReceipts(), validatesLiveSeamwardCustody() else {
                throw CocoaError(.coderInvalidValue)
            }
        }
        if schemaVersion >= 4 {
            let runs = [worlds.activeRun].compactMap { $0 } + worlds.anchoredRealms.map(\.world)
            for run in runs {
                for tile in run.map.tiles {
                    if case .node(let node) = tile.content,
                       ResourceExtractionRules.validatedRequirement(of: node) == nil {
                        throw CocoaError(.coderInvalidValue)
                    }
                }
            }
        }
        // Trading Post shipped briefly before the campaign-wide receipt source. Seed the new
        // sequence from every durable consumer so the first post-migration return cannot reuse
        // an already-processed identifier and silently skip a refresh.
        worlds.outcomeSequence = [
            worlds.outcomeSequence,
            worlds.lastExit?.outcomeID?.rawValue ?? 0,
            worlds.pendingAnchorSettlementOutcomeID?.rawValue ?? 0,
            worlds.lastSpringOutcomeID?.rawValue ?? 0,
            base.tradingPost.expeditionOutcomeID?.rawValue ?? 0
        ].max() ?? 0
        if let savedTutorial = try container.decodeIfPresent(TutorialState.self, forKey: .tutorial) {
            tutorial = savedTutorial
        } else {
            // Only pre-tutorial saves infer completed notes. Re-running inference on every decode
            // would mutate an explicitly saved (and deliberately resettable) tutorial record.
            tutorial = TutorialState()
            var reconciled = tutorial
            reconciled.reconcile(with: self)
            tutorial = reconciled
        }
        if RosterPlacementRules.reconcileLegacyProjections(in: &self) {
#if DEBUG
            print("[older-save placement update] Repaired conflicting traveller locations between the party and Village.")
#endif
        }
        // The schematic field postdates its authored page. Recover knowledge from the exact page
        // receipt, never from station/item ownership, then canonical encoding persists it normally.
        if reality.library.hasFound("oda_emanation_housing") {
            reality.library.knownSchematics.insert("emanation_housing")
        }
        // The Blacksmith's opening construction teaching is bundled with its paid build.
        // Reconcile older built saves idempotently; item ownership never teaches it.
        if base.station(Stations.blacksmith).isUnlocked {
            reality.library.knownSchematics.insert("pointed_blade")
        }
    }

    init(schemaVersion: Int, meta: SaveMeta, reality: RealityState, base: BaseState, worlds: WorldsState,
         tutorial: TutorialState = TutorialState()) {
        self.schemaVersion = schemaVersion
        self.meta = meta
        self.reality = reality
        self.base = base
        self.worlds = worlds
        self.tutorial = tutorial
    }
}

/// Bookkeeping about the save itself. Never a gameplay input.
struct SaveMeta: Codable, Equatable, Sendable {
    /// Incremented by `GameStore` on every mutation. The force-quit harness compares the value
    /// in memory against the value on disk to prove nothing was lost.
    var mutationCount: Int = 0
    /// Label of the most recent mutation — makes a resumed save self-describing.
    var lastAction: String = "new game"
    /// Diagnostics-only bounded semantic history. Game rules must never read this.
    var semanticActionTrail: [String] = []
    /// Diagnostics only. No game rule may read this (pillar 2: no wall-clock gameplay).
    var lastSavedAt: Date? = nil
    /// Legacy diagnostics-only field. Retained for tolerant decode; new launches use measured
    /// coordinator timings and do not rewrite a campaign merely to increment this value.
    var launchCount: Int = 0

    init(mutationCount: Int = 0, lastAction: String = "new game",
         semanticActionTrail: [String] = [], lastSavedAt: Date? = nil, launchCount: Int = 0) {
        self.mutationCount = mutationCount
        self.lastAction = lastAction
        self.semanticActionTrail = Array(semanticActionTrail.suffix(Self.actionTrailLimit))
        self.lastSavedAt = lastSavedAt
        self.launchCount = launchCount
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        mutationCount = try container.decodeIfPresent(Int.self, forKey: .mutationCount) ?? 0
        lastAction = try container.decodeIfPresent(String.self, forKey: .lastAction) ?? "unknown"
        semanticActionTrail = Array((try container.decodeIfPresent([String].self, forKey: .semanticActionTrail)
                                     ?? [lastAction]).suffix(Self.actionTrailLimit))
        lastSavedAt = try container.decodeIfPresent(Date.self, forKey: .lastSavedAt)
        launchCount = try container.decodeIfPresent(Int.self, forKey: .launchCount) ?? 0
    }

    static let actionTrailLimit = 20

    mutating func recordSemanticAction(_ action: String) {
        lastAction = action
        semanticActionTrail.append(action)
        if semanticActionTrail.count > Self.actionTrailLimit {
            semanticActionTrail.removeFirst(semanticActionTrail.count - Self.actionTrailLimit)
        }
    }
}
