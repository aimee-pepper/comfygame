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
    /// **The species this world settled on** (session 15 §1). Sampled at bind from the readings and
    /// the seed, and saved with the run so a resume finds the same animals — and so an anchored
    /// world will keep its cast forever without anything further being built.
    var cast: [Species] = []
    /// **What grows here.** Every overgrown tile points into this by id, so the harvest knows
    /// whether a thicket is timber or poison and the map knows what you are standing in.
    var flora: [Flora] = []
    /// Turns of lingering harm from something toxic you walked through.
    ///
    /// **Chemical defence is the one that stays with you** (`flora-system-spec.md` §6) — thorns cost
    /// you once and poison keeps costing — and a counter on the run is the only place that can
    /// survive a force-quit halfway through it.
    var floraPoisonTurns: Int = 0

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

    /// Where in the world's day this turn falls, 0 at dawn and approaching 1 at the next dawn.
    ///
    /// Driven by `turnsTaken`, never by wall-clock — the day turns because you moved, which is what
    /// keeps the interruptibility pillar true.
    var dayPhase: Double {
        guard Tuning.DayNight.turnsPerDay > 0 else { return 0 }
        return Double(turnsTaken % Tuning.DayNight.turnsPerDay) / Double(Tuning.DayNight.turnsPerDay)
    }

    /// **A world lit by something constant never has a night at all.** Darkness only happens where
    /// the light comes and goes, which is what finally makes Illumination's dynamic range mean
    /// something (session 13 §6).
    var isNight: Bool {
        guard hasDayAndNight else { return false }
        return dayPhase >= 1 - Tuning.DayNight.nightFraction
    }

    /// Whether this world turns at all. A sourceless glow doesn't set.
    var hasDayAndNight: Bool {
        let light = BookRules.readings(for: book, seed: mapSeed)["illumination"]
        return light.range > Tuning.Pressure.wideRangeThreshold && !light.has("sourceless")
    }

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

    /// The turn the meter reached zero, or nil while the world is still holding.
    ///
    /// Kept so crumbling can accelerate the longer you stay in a world that has already gone —
    /// stability clamps at zero and can't say how long ago that was.
    var collapsedOnTurn: Int?

    var binderHP: Int = Tuning.Encounter.binderMaxHP
    /// **Health per person at the fire**, keyed by roster index.
    ///
    /// It was one number, which is the other half of why a party of five couldn't exist: there was
    /// exactly one place to keep a companion's health, so a second one had nowhere to be hurt.
    /// Anybody absent from the dictionary is at full — joining mid-run shouldn't arrive wounded.
    var companionHP: [Int: Int] = [:]

    init(runIndex: Int, book: BoundBook, mapSeed: UInt64, rng: SeededRNG, map: WorldMap,
         playerPosition: GridPoint, enemies: [WorldEnemy] = [], sites: [PlacedSite] = [],
         travellersHere: [TravellerID] = [], cast: [Species] = [], flora: [Flora] = [],
         binderHP: Int = Tuning.Encounter.binderMaxHP,
         companionHP: [Int: Int] = [:],
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
        self.cast = cast
        self.flora = flora
        self.binderHP = binderHP
        self.companionHP = companionHP
        self.satchelItems = satchelItems
    }

    /// The species a given enemy belongs to, where the run still has it.
    func species(of enemy: WorldEnemy) -> Species? {
        enemy.speciesID.flatMap { id in cast.first { $0.id == id } }
    }

    /// The plant a given tile is overgrown with, where the run still has it.
    func plant(at point: GridPoint) -> Flora? {
        guard map.contains(point), let id = map[point].flora else { return nil }
        return flora.first { $0.id == id }
    }

    /// Every plant's name, resolved together so no two of this world's plants share one.
    var floraNames: [InstanceID: FloraIdentity.Match] { FloraIdentity.names(for: flora) }

    /// What this world's animals are like on average — what any one of them gets named against.
    var namingContext: Naming.Context { Naming.Context(of: cast.map(\.traits)) }

    /// Every species' name, **resolved together** so no two of this world's animals share one.
    /// Derived rather than stored, per "store the observation, derive the meaning" — expanding the
    /// vocabulary later gives old worlds better names for free.
    var castNames: [InstanceID: CreatureIdentity.Match] { CreatureIdentity.names(for: cast) }

    /// What to call one of this world's animals, named against the rest of them.
    func identity(of enemy: WorldEnemy) -> CreatureIdentity.Match? {
        guard let id = enemy.speciesID, let match = castNames[id] else {
            return enemy.traits.map { CreatureIdentity.match($0, in: namingContext) }
        }
        return match
    }

    func name(of enemy: WorldEnemy) -> String {
        // **A plant that stands up is still a plant.** It fights through the creature system, but
        // naming it off its combat vector would call it "a hulking limbless shape" — it is the
        // thing you have been walking past all afternoon, and it should say so.
        if let floraID = enemy.floraID, let match = floraNames[floraID] { return match.name }
        return identity(of: enemy)?.name ?? enemy.displayName
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
        cast = try container.decodeIfPresent([Species].self, forKey: .cast) ?? []
        flora = try container.decodeIfPresent([Flora].self, forKey: .flora) ?? []
        floraPoisonTurns = try container.decodeIfPresent(Int.self, forKey: .floraPoisonTurns) ?? 0
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
        collapsedOnTurn = try container.decodeIfPresent(Int.self, forKey: .collapsedOnTurn)
        binderHP = try container.decodeIfPresent(Int.self, forKey: .binderHP) ?? Tuning.Encounter.binderMaxHP
        // A run saved when only one person could come brings that one person's health with it.
        if let perMember = try? container.decodeIfPresent([Int: Int].self, forKey: .companionHP) {
            companionHP = perMember ?? [:]
        } else if let single = try? container.decode(Int.self, forKey: .companionHP) {
            companionHP = [0: single]
        } else {
            companionHP = [:]
        }
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
    /// **What the page actually said**, resolved at bind and kept.
    ///
    /// Without this a bound book carried only its *compound* symbol ids, because `page.symbolIDs`
    /// returns compounds and nothing else — so every target and source cluster the player wrote was
    /// dropped on the way into the world. The preview resolved the page directly and looked right;
    /// the world it bound was generated from the compounds alone. Everything downstream of a bound
    /// world — terrain, sites, creatures, stability — reads this.
    var composition: [Sigil] = []
    /// How much world this book asked for. Read off the Scale qualifier at bind, and kept, so the
    /// map is reproducible from the book alone.
    var scale: WorldScale = .ordinary
    var symbols: [SlotID: SymbolID]
    /// Slots that were random-filled at bind time — the UI reveals these as surprises.
    var randomlyFilled: Set<SlotID>
    var essencePaid: Int

    /// Everything this book says, in a stable order.
    ///
    /// **A bound world outlives the content that made it.** The slot taxonomy it was written in is
    /// gone — `slots.json` and `SlotDef` went with the fossil audit — and a run that was in progress
    /// when that happened still has to count its symbols toward its decay and its spawns. Silently
    /// losing them would change a world under a player mid-visit.
    ///
    /// So the ordering is by slot *name* rather than by a catalogue order that no longer exists.
    /// Order only decides how a legacy book reads out; nothing downstream depends on it.
    var allSymbolIDs: [SymbolID] {
        if !written.isEmpty { return written }
        return symbols.sorted { $0.key.rawValue < $1.key.rawValue }.map(\.value)
    }

    /// Slots the player chose deliberately, as opposed to left to chance.
    var chosenSymbolIDs: [SymbolID] {
        if !written.isEmpty { return written }
        return symbols.filter { !randomlyFilled.contains($0.key) }.map(\.value)
    }

    init(written: [SymbolID], composition: [Sigil] = [], scale: WorldScale = .ordinary,
         essencePaid: Int) {
        self.written = written
        self.composition = composition
        self.scale = scale
        self.symbols = [:]
        self.randomlyFilled = []
        self.essencePaid = essencePaid
    }

    init(symbols: [SlotID: SymbolID], randomlyFilled: Set<SlotID>, essencePaid: Int) {
        self.written = []
        self.composition = []
        self.scale = .ordinary
        self.symbols = symbols
        self.randomlyFilled = randomlyFilled
        self.essencePaid = essencePaid
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        written = try c.decodeIfPresent([SymbolID].self, forKey: .written) ?? []
        composition = try c.decodeIfPresent([Sigil].self, forKey: .composition) ?? []
        scale = try c.decodeIfPresent(WorldScale.self, forKey: .scale) ?? .ordinary
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
