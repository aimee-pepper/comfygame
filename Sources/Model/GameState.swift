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

    static func newGame() -> GameState {
        var seeds = SeedSequence.newGame()
        return GameState(
            schemaVersion: Tuning.saveSchemaVersion,
            meta: SaveMeta(),
            reality: RealityState.newGame(),
            base: BaseState.newGame(),
            worlds: WorldsState.newGame(seeds: &seeds)
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
    }

    init(schemaVersion: Int, meta: SaveMeta, reality: RealityState, base: BaseState, worlds: WorldsState) {
        self.schemaVersion = schemaVersion
        self.meta = meta
        self.reality = reality
        self.base = base
        self.worlds = worlds
    }
}

/// Bookkeeping about the save itself. Never a gameplay input.
struct SaveMeta: Codable, Equatable, Sendable {
    /// Incremented by `GameStore` on every mutation. The force-quit harness compares the value
    /// in memory against the value on disk to prove nothing was lost.
    var mutationCount: Int = 0
    /// Label of the most recent mutation — makes a resumed save self-describing.
    var lastAction: String = "new game"
    /// Diagnostics only. No game rule may read this (pillar 2: no wall-clock gameplay).
    var lastSavedAt: Date? = nil
    /// Number of app launches that loaded this save. Useful in the kill-test.
    var launchCount: Int = 0

    init(mutationCount: Int = 0, lastAction: String = "new game", lastSavedAt: Date? = nil, launchCount: Int = 0) {
        self.mutationCount = mutationCount
        self.lastAction = lastAction
        self.lastSavedAt = lastSavedAt
        self.launchCount = launchCount
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        mutationCount = try container.decodeIfPresent(Int.self, forKey: .mutationCount) ?? 0
        lastAction = try container.decodeIfPresent(String.self, forKey: .lastAction) ?? "unknown"
        lastSavedAt = try container.decodeIfPresent(Date.self, forKey: .lastSavedAt)
        launchCount = try container.decodeIfPresent(Int.self, forKey: .launchCount) ?? 0
    }
}
