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
            }), validatesPhysicalGearReceipts(), validatesLiveSeamwardCustody(),
                  RosterPlacementRules.validatesCurrentState(self) else {
                throw CocoaError(.coderInvalidValue)
            }
        }
        if schemaVersion >= 20 {
            guard !base.collectedWorldPages.contains(where: {
                $0.id == LegacyDebugVisibilityWorldV19.instanceID
                    || $0.definition.id == LegacyDebugVisibilityWorldV19.definitionID
            }), EncounterSnapshotRulesV1.validatesAll(in: self) else {
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
        if schemaVersion < 19, RosterPlacementRules.reconcileLegacyProjections(in: &self) {
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

/// Composed current-save authority for the exact live bodies and actors frozen into a fight.
/// Dynamic HP/status/combat receipts remain encounter-owned and are deliberately not rederived.
enum EncounterSnapshotRulesV1 {
    static func validatesAll(in state: GameState) -> Bool {
        let runs = [state.worlds.activeRun].compactMap { $0 }
            + state.worlds.anchoredRealms.map(\.world)
        return runs.allSatisfy { run in
            guard let encounter = run.activeEncounter else { return true }
            return validates(encounter: encounter, run: run, in: state)
        }
    }

    static func validates(encounter: EncounterState, in state: GameState) -> Bool {
        guard let run = state.worlds.activeRun,
              run.activeEncounter?.id == encounter.id else { return false }
        return validates(encounter: encounter, run: run, in: state)
    }

    private static func validates(encounter: EncounterState, run: WorldRun,
                                  in state: GameState) -> Bool {
        guard !encounter.foes.isEmpty,
              Set(encounter.foes.map(\.id)).count == encounter.foes.count,
              Set(run.enemies.map(\.id)).count == run.enemies.count else { return false }
        for foe in encounter.foes {
            guard let enemy = run.enemies.first(where: { $0.id == foe.id }),
                  foe.speciesID == enemy.speciesID,
                  foe.creatureID == enemy.creatureID,
                  foe.identityKey == enemy.identityKey,
                  foe.traits == enemy.traits,
                  foe.isApex == enemy.isApex else { return false }
        }

        let party = CombatRules.party(of: state)
        guard party.first == .binder, Set(party).count == party.count else { return false }
        let foeActors = encounter.foes.map { Combatant.foe($0.id) }
        let closedActors = Set(party + foeActors)
        guard encounter.order.count == closedActors.count,
              Set(encounter.order) == closedActors,
              !encounter.turnSlots.isEmpty,
              encounter.turnSlots.allSatisfy({ closedActors.contains($0.actor) }) else { return false }
        let primaryActors = encounter.turnSlots.compactMap { slot -> Combatant? in
            if case .primary = slot.kind { return slot.actor }
            return nil
        }
        guard primaryActors.count == closedActors.count,
              Set(primaryActors) == closedActors else { return false }
        var apexActionSlots: [InstanceID: Int] = [:]
        var ordinaryPressureSlots = 0
        if let preview = encounter.scalingPreview {
            guard (1...3).contains(preview.apexActionSlots) else { return false }
            let apexFoes = encounter.foes.filter(\.isApex)
            if apexFoes.isEmpty {
                if preview.scalingRulesVersion == EncounterScalingRules.additivePartyPowerRulesVersion {
                    guard let frozen = preview.wholePressureSlots, (0...2).contains(frozen) else {
                        return false
                    }
                    ordinaryPressureSlots = frozen
                }
            } else {
                guard (preview.wholePressureSlots ?? 0) == 0 else { return false }
                apexActionSlots = Dictionary(uniqueKeysWithValues:
                    apexFoes.map { ($0.id, preview.apexActionSlots) })
            }
        }
        let expectedSlots = CombatRules.turnSlots(order: encounter.order, foes: encounter.foes,
                                                   apexActionSlots: apexActionSlots,
                                                   ordinaryPressureSlots: ordinaryPressureSlots)
        // Cascade reorders primary slots while deliberately leaving follow-up positions in place;
        // Stagger moves a foe's persisted slots later without rebuilding the schedule. Validate the
        // frozen authority carried by every actor's slot sequence, not a fresh global interleaving.
        // The primary projection still has to be the exact persisted actor order.
        guard encounter.turnSlots.filter({ $0.kind == .primary }).map(\.actor) == encounter.order else {
            return false
        }
        guard encounter.turnSlots.allSatisfy({ slot in
            switch slot.kind {
            case .primary:
                return slot.strengthMultiplier == 1 && !slot.suppressesAfflictions
            case .apexFollowUp:
                guard case .foe(let id) = slot.actor else { return false }
                return apexActionSlots[id] != nil
            case .ordinaryPressureFollowUp:
                guard case .foe(let id) = slot.actor else { return false }
                return encounter.foes.contains { $0.id == id && !$0.isApex }
            }
        }) else { return false }
        for actor in closedActors {
            let actualPrimary = encounter.turnSlots.filter { $0.actor == actor && $0.kind == .primary }
            guard actualPrimary == [.init(actor: actor)] else { return false }
            if case .foe(let id) = actor, apexActionSlots[id] != nil {
                let actual = encounter.turnSlots.filter { $0.actor == actor }
                let expected = expectedSlots.filter { $0.actor == actor }
                guard actual == expected else { return false }
            } else if actor.foeID == nil || encounter.foes.contains(where: {
                $0.id == actor.foeID && $0.isApex
            }) {
                guard encounter.turnSlots.filter({ $0.actor == actor }).count == 1 else { return false }
            }
        }
        let pressure = encounter.turnSlots.compactMap { slot -> (Int, Combatant)? in
            guard case .ordinaryPressureFollowUp(let ordinal) = slot.kind else { return nil }
            return (ordinal, slot.actor)
        }
        let expectedPressure: [(Int, Combatant)]
        if state.schemaVersion >= 21 {
            guard let receipt = encounter.pressureOwners,
                  receipt.version == EncounterState.EncounterPressureOwnerReceiptV1.currentVersion,
                  receipt.entries.count == ordinaryPressureSlots,
                  Set(receipt.entries.map(\.ordinal)).count == receipt.entries.count,
                  receipt.entries.map(\.ordinal).sorted()
                    == Array(1..<(ordinaryPressureSlots + 1)),
                  receipt.entries.allSatisfy({ entry in
                      encounter.foes.contains { $0.id == entry.foeID && !$0.isApex }
                  }) else { return false }
            expectedPressure = receipt.entries.map { ($0.ordinal, .foe($0.foeID)) }
        } else {
            // Schema 20 compatibility exists only so migration can decode and prevalidate it.
            expectedPressure = pressure.sorted { $0.0 < $1.0 }
        }
        guard pressure.count == ordinaryPressureSlots,
              pressure.map(\.0).sorted() == Array(1..<(ordinaryPressureSlots + 1)),
              pressure.sorted(by: { $0.0 < $1.0 }).elementsEqual(expectedPressure, by: {
                  $0.0 == $1.0 && $0.1 == $1.1
              }),
              pressure.allSatisfy({ ordinal, actor in
                  guard actor.foeID != nil,
                        encounter.foes.contains(where: { $0.id == actor.foeID && !$0.isApex }),
                        let slot = encounter.turnSlots.first(where: {
                            $0.actor == actor && $0.kind == .ordinaryPressureFollowUp(ordinal)
                        }) else { return false }
                  return slot.strengthMultiplier == 0.55 && slot.suppressesAfflictions
              }) else { return false }

        let expectedNames = state.base.activeParty.reduce(into: [PersistentPartyMemberID: String]()) {
            if let animal = state.base.animalCompanion(for: $1) {
                $0[$1] = animal.originReceipt.frozenDisplayName
            } else if let index = state.base.rosterIndex(for: $1) {
                $0[$1] = state.base.roster[index].name
            }
        }
        guard encounter.partyNames == expectedNames else { return false }
        let animalActors = Set(party.filter {
            guard case .companion(let id) = $0 else { return false }
            return state.base.animalCompanion(for: id) != nil
        })
        guard let animals = encounter.animalParticipants,
              Set(animals.keys) == animalActors,
              animals.allSatisfy({ $0.key == .companion($0.value.memberID) }) else { return false }
        let humanActors = Set(party).subtracting(animalActors)
        guard let projections = encounter.gearProjections,
              Set(projections.keys) == humanActors,
              projections.allSatisfy({ $0.value.owner.combatant == $0.key && $0.value.validates() })
        else { return false }
        if let trigger = encounter.scalingPreview?.triggerFoeID {
            guard foeActors.filter({ $0 == .foe(trigger) }).count == 1,
                  run.enemies.filter({ $0.id == trigger }).count == 1 else { return false }
        }
        return true
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
