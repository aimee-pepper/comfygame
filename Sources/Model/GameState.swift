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
        var seeds = SeedSequence.newGame()
        worlds = try container.decodeIfPresent(WorldsState.self, forKey: .worlds) ?? .newGame(seeds: &seeds)
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
    /// Number of app launches that loaded this save. Useful in the kill-test.
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
