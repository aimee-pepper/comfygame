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
    /// Discrete placed things — ruins, landmarks, warrens. Looted state lives on the instance
    /// rather than the definition, because an anchored world has to remember that *this* ruin is
    /// empty while its ordinary resources replenish (Q12).
    var sites: [PlacedSite] = []
    /// Travellers whose signature this world satisfies. Found on arrival — a traveller is simply
    /// *at* a signature, so writing the right world is the whole of finding them.
    var travellersHere: [TravellerID] = []

    /// 0–100, always visible. Decays per *player turn* only — never wall-clock (pillar 2).
    var stability: Double = Tuning.World.startingStability

    /// The Stability headline this world runs at.
    ///
    /// **Sites deliberately do not move this yet.** `docs/sites-system.md` §5 proposes charging
    /// greed instability on what a world contains, sites included — but it's tagged [PROPOSAL],
    /// and it collides head-on with a ruling that isn't: *a symbol moves the headline by exactly
    /// its printed number*, which is the whole reason stability was rebalanced in session 5. Since
    /// the sites that land are rolled at bind, folding them in would mean the meter shows a number
    /// no symbol accounts for — the precise complaint that prompted the rebalance.
    ///
    /// `SiteRules.stabilityDelta` is built and tested and ready to be added here the moment the
    /// preview is allowed to show it. See questions-for-design Q19.
    var effectiveStabilityScore: Int { BookRules.stabilityScore(of: book) }


    var decayPerTurn: Double { BookRules.decayPerTurn(stabilityScore: effectiveStabilityScore) }
    /// Player turns taken this run. The only clock the game has.
    var turnsTaken: Int = 0

    /// Unbanked haul. Kept 100% on portal exit, `collapseHaulKeptFraction` on collapse.
    var satchel: ResourcePool = ResourcePool()
    var satchelItems: Inventory = Inventory(slots: Tuning.Economy.startingInventorySlots)

    /// Non-nil ⇒ the player is mid-encounter. Force-quitting here must resume into the same
    /// encounter on the same turn (acceptance criterion).
    var activeEncounter: EncounterState?

    /// Loot that wouldn't fit, waiting on you to choose. Held in the save rather than resolved
    /// on the spot, because "drop something or leave it" is a decision the player makes — and a
    /// force-quit in the middle of making it has to resume with the choice still open (pillar 2).
    var offeredItems: [ItemStack] = []

    /// Where the player stood before their last step. Fleeing retreats here.
    var previousPosition: GridPoint?
    /// Turns before a bump can start another fight. Stops a flee from being undone immediately.
    var encounterGraceTurns: Int = 0

    var binderHP: Int = Tuning.Encounter.binderMaxHP
    var companionHP: Int = Tuning.Encounter.companionMaxHP

    init(runIndex: Int, book: BoundBook, mapSeed: UInt64, rng: SeededRNG, map: WorldMap,
         playerPosition: GridPoint, enemies: [WorldEnemy] = [], sites: [PlacedSite] = [],
         travellersHere: [TravellerID] = [],
         satchelItems: Inventory = Inventory(slots: Tuning.Economy.startingInventorySlots)) {
        self.runIndex = runIndex
        self.book = book
        self.mapSeed = mapSeed
        self.rng = rng
        self.map = map
        self.playerPosition = playerPosition
        self.enemies = enemies
        self.sites = sites
        self.travellersHere = travellersHere
        self.satchelItems = satchelItems
    }

    /// Tolerant decoding, per the policy in `Migrations.swift`: adding a field must never cost a
    /// player their in-progress world. Synthesised decoding would *throw* on a save written before
    /// the field existed — which quarantines the whole save, mid-run, on the next launch.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        runIndex = try container.decode(Int.self, forKey: .runIndex)
        book = try container.decode(BoundBook.self, forKey: .book)
        mapSeed = try container.decode(UInt64.self, forKey: .mapSeed)
        rng = try container.decode(SeededRNG.self, forKey: .rng)
        map = try container.decode(WorldMap.self, forKey: .map)
        playerPosition = try container.decode(GridPoint.self, forKey: .playerPosition)
        enemies = try container.decodeIfPresent([WorldEnemy].self, forKey: .enemies) ?? []
        sites = try container.decodeIfPresent([PlacedSite].self, forKey: .sites) ?? []
        travellersHere = try container.decodeIfPresent([TravellerID].self, forKey: .travellersHere) ?? []
        stability = try container.decodeIfPresent(Double.self, forKey: .stability)
            ?? Tuning.World.startingStability
        turnsTaken = try container.decodeIfPresent(Int.self, forKey: .turnsTaken) ?? 0
        satchel = try container.decodeIfPresent(ResourcePool.self, forKey: .satchel) ?? ResourcePool()
        satchelItems = try container.decodeIfPresent(Inventory.self, forKey: .satchelItems)
            ?? Inventory(slots: Tuning.Economy.startingInventorySlots)
        activeEncounter = try container.decodeIfPresent(EncounterState.self, forKey: .activeEncounter)
        offeredItems = try container.decodeIfPresent([ItemStack].self, forKey: .offeredItems) ?? []
        previousPosition = try container.decodeIfPresent(GridPoint.self, forKey: .previousPosition)
        encounterGraceTurns = try container.decodeIfPresent(Int.self, forKey: .encounterGraceTurns) ?? 0
        binderHP = try container.decodeIfPresent(Int.self, forKey: .binderHP) ?? Tuning.Encounter.binderMaxHP
        companionHP = try container.decodeIfPresent(Int.self, forKey: .companionHP) ?? Tuning.Encounter.companionMaxHP
    }

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
    /// What was written on the page, in placement order.
    ///
    /// This is the composition now. `symbols` below is the old slot taxonomy, kept so worlds bound
    /// before the page existed still resolve — a bound world outlives the content that made it.
    var written: [SymbolID] = []
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
        if !written.isEmpty { return written }
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
        if !written.isEmpty { return written }
        return symbols.filter { !randomlyFilled.contains($0.key) }.map(\.value)
    }

    init(written: [SymbolID], essencePaid: Int) {
        self.written = written
        self.symbols = [:]
        self.randomlyFilled = []
        self.essencePaid = essencePaid
    }

    init(symbols: [SlotID: SymbolID], randomlyFilled: Set<SlotID>, essencePaid: Int) {
        self.written = []
        self.symbols = symbols
        self.randomlyFilled = randomlyFilled
        self.essencePaid = essencePaid
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        written = try c.decodeIfPresent([SymbolID].self, forKey: .written) ?? []
        symbols = try c.decodeIfPresent([SlotID: SymbolID].self, forKey: .symbols) ?? [:]
        randomlyFilled = try c.decodeIfPresent(Set<SlotID>.self, forKey: .randomlyFilled) ?? []
        essencePaid = try c.decodeIfPresent(Int.self, forKey: .essencePaid) ?? 0
    }
}

/// Grid coordinate. Used by milestone 3's map; defined here so the run struct can adopt it
/// without a save-shape change.
struct GridPoint: Codable, Equatable, Hashable, Sendable {
    var x: Int
    var y: Int
}
