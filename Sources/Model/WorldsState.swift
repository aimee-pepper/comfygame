import Foundation

/// Layer 3 — Authored Worlds. Instanced runs; every v0 world is disposable.
///
/// Anchoring (making a world permanent) is an open design question (docs/open-questions.md Q-A)
/// and is deliberately NOT modelled here. When it lands it will most likely add a sibling
/// `anchored: [AnchoredWorld]` collection next to `activeRun`.
struct WorldsState: Codable, Equatable, Sendable {
    /// The run in progress, or `nil` when the player is at base. Saving this whole struct is what
    /// makes "force-quit mid-run, even mid-encounter" resume exactly (pillar 2).
    var activeRun: WorldRun?
    /// Monotonic run counter. Stamps discovery records — a turn/run count, never a date.
    var runIndex: Int = 0
    /// Deterministic source of world seeds; lives in the save so relaunching cannot re-roll a
    /// seed the player already saw in a pre-bind preview.
    var seeds: SeedSequence

    static func newGame(seeds: inout SeedSequence) -> WorldsState {
        WorldsState(activeRun: nil, runIndex: 0, seeds: seeds)
    }

    var isInRun: Bool { activeRun != nil }

    init(activeRun: WorldRun?, runIndex: Int, seeds: SeedSequence) {
        self.activeRun = activeRun
        self.runIndex = runIndex
        self.seeds = seeds
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        activeRun = try container.decodeIfPresent(WorldRun.self, forKey: .activeRun)
        runIndex = try container.decodeIfPresent(Int.self, forKey: .runIndex) ?? 0
        seeds = try container.decodeIfPresent(SeedSequence.self, forKey: .seeds) ?? SeedSequence.newGame()
    }
}

/// One instanced world run.
struct WorldRun: Codable, Equatable, Sendable {
    var runIndex: Int
    /// Composition this world was generated from. Kept so the map can be regenerated from the
    /// book + seed rather than serialising every tile.
    var book: BoundBook
    /// Worldgen input. Same seed + same book ⇒ byte-identical map, every regeneration.
    var mapSeed: UInt64
    /// Live stream for in-run rolls (drops, combat). Advances during play and is saved with the
    /// run, so a resume does not rewind randomness.
    var rng: SeededRNG

    /// The tile grid, with its fog, harvest and crumble state.
    var map: WorldMap
    var playerPosition: GridPoint
    /// Enemies standing on the grid. Removed when defeated in an encounter.
    var enemies: [WorldEnemy] = []

    /// 0–100, always visible. Decays per *player turn* only — never wall-clock (pillar 2).
    var stability: Double = Tuning.World.startingStability
    /// Player turns taken this run. The only clock the game has.
    var turnsTaken: Int = 0

    /// Unbanked haul. Kept 100% on portal exit, `collapseHaulKeptFraction` on collapse.
    var satchel: ResourcePool = ResourcePool()
    var satchelItems: Inventory = Inventory(slots: Tuning.Economy.startingInventorySlots)

    /// Non-nil ⇒ the player is mid-encounter. Force-quitting here must resume into the same
    /// encounter on the same turn (acceptance criterion).
    var activeEncounter: EncounterState?

    /// Where the player stood before their last step. Fleeing retreats here.
    var previousPosition: GridPoint?
    /// Turns before a bump can start another fight. Stops a flee from being undone immediately.
    var encounterGraceTurns: Int = 0

    var binderHP: Int = Tuning.Encounter.binderMaxHP
    var companionHP: Int = Tuning.Encounter.companionMaxHP

    /// Stability band drives the world's escalating behaviour. Thresholds are tunable.
    var stabilityBand: StabilityBand {
        if stability <= Tuning.World.collapseThreshold { return .collapsed }
        if stability <= Tuning.World.crumbleThreshold { return .crumbling }
        if stability <= Tuning.World.hazardThreshold { return .hazardous }
        return .stable
    }
}

enum StabilityBand: String, Codable, Sendable {
    case stable      // > 50
    case hazardous   // ≤ 50 — hazard tiles spawn at map edges
    case crumbling   // ≤ 25 — tiles crumble inward
    case collapsed   // ≤ 0  — run ends, partial haul
}

/// A composed, paid-for book. Every slot is resolved here: symbols the player chose plus the
/// random fills for slots they left empty, so the world is fully described by (book, seed).
struct BoundBook: Codable, Equatable, Sendable {
    var symbols: [SlotID: SymbolID]
    /// Slots that were random-filled at bind time — the UI reveals these as surprises.
    var randomlyFilled: Set<SlotID>
    var essencePaid: Int

    /// In catalog order, with anything in an unrecognised slot appended rather than dropped.
    ///
    /// A bound world outlives the content that made it: if the slot taxonomy is rewritten while a
    /// run is in progress, that run's symbols must still count toward its decay and its spawns.
    /// Silently losing them would change a world under a player mid-visit.
    var allSymbolIDs: [SymbolID] {
        let ordered = ContentCatalog.shared.slotIDsInOrder
        let known = ordered.compactMap { symbols[$0] }
        let orphans = symbols
            .filter { !ordered.contains($0.key) }
            .sorted { $0.key.rawValue < $1.key.rawValue }
            .map(\.value)
        return known + orphans
    }

    /// Slots the player chose deliberately, as opposed to left to chance.
    var chosenSymbolIDs: [SymbolID] {
        symbols.filter { !randomlyFilled.contains($0.key) }.map(\.value)
    }
}

/// Grid coordinate. Used by milestone 3's map; defined here so the run struct can adopt it
/// without a save-shape change.
struct GridPoint: Codable, Equatable, Hashable, Sendable {
    var x: Int
    var y: Int
}
