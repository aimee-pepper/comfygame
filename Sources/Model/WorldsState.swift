import Foundation

/// One campaign-local receipt for an expedition-to-Base transition. Unlike `runIndex`, this
/// advances for every visit to an anchored realm as well as every newly bound world.
struct ExpeditionOutcomeID: RawRepresentable, Codable, Equatable, Hashable, Comparable, Sendable,
                            ExpressibleByIntegerLiteral {
    var rawValue: UInt64
    init(rawValue: UInt64) { self.rawValue = rawValue }
    init(integerLiteral value: UInt64) { rawValue = value }
    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

/// Layer 3 — Authored Worlds. Instanced expeditions plus realms rebound into the Atlas.
struct WorldsState: Codable, Equatable, Sendable {
    /// The run in progress, or `nil` when the player is at base. Saving this whole struct is what
    /// makes "force-quit mid-run, even mid-encounter" resume exactly (pillar 2).
    var activeRun: WorldRun?
    /// Monotonic run counter. Stamps discovery records — a turn/run count, never a date.
    var runIndex: Int = 0
    /// Monotonic receipt source for completed expeditions. Never derived from a world's identity.
    var outcomeSequence: UInt64 = 0
    /// Deterministic source of world seeds; lives in the save so relaunching cannot re-roll a
    /// seed the player already saw in a pre-bind preview.
    var seeds: SeedSequence
    /// The last trip's ending, kept until acknowledged so routing home cannot swallow why it ended.
    var lastExit: RunExitSummary?
    /// Durable world snapshots. They survive expedition endings and never age by wall clock.
    var anchoredRealms: [AnchoredRealm] = []
    /// A return-time player decision. Never resolved by a clock or hidden automatic spending.
    var pendingAnchorSettlement: Bool = false
    var pendingAnchorSettlementOutcomeID: ExpeditionOutcomeID?
    /// Spring income is an automatic outcome consumer and must never replay after relaunch.
    var lastSpringOutcomeID: ExpeditionOutcomeID?

    static func newGame(seeds: inout SeedSequence) -> WorldsState {
        WorldsState(activeRun: nil, runIndex: 0, seeds: seeds, lastExit: nil,
                    anchoredRealms: [], pendingAnchorSettlement: false)
    }

    var isInRun: Bool { activeRun != nil }

    init(activeRun: WorldRun?, runIndex: Int, seeds: SeedSequence, lastExit: RunExitSummary? = nil,
         anchoredRealms: [AnchoredRealm] = [], pendingAnchorSettlement: Bool = false,
         outcomeSequence: UInt64 = 0,
         pendingAnchorSettlementOutcomeID: ExpeditionOutcomeID? = nil,
         lastSpringOutcomeID: ExpeditionOutcomeID? = nil) {
        self.activeRun = activeRun
        self.runIndex = runIndex
        self.outcomeSequence = outcomeSequence
        self.seeds = seeds
        self.lastExit = lastExit
        self.anchoredRealms = anchoredRealms
        self.pendingAnchorSettlement = pendingAnchorSettlement
        self.pendingAnchorSettlementOutcomeID = pendingAnchorSettlementOutcomeID
        self.lastSpringOutcomeID = lastSpringOutcomeID
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        activeRun = try container.decodeIfPresent(WorldRun.self, forKey: .activeRun)
        runIndex = try container.decodeIfPresent(Int.self, forKey: .runIndex) ?? 0
        outcomeSequence = try container.decodeIfPresent(UInt64.self, forKey: .outcomeSequence) ?? 0
        seeds = try container.decodeIfPresent(SeedSequence.self, forKey: .seeds) ?? SeedSequence.newGame()
        lastExit = try container.decodeIfPresent(RunExitSummary.self, forKey: .lastExit)
        anchoredRealms = try container.decodeIfPresent([AnchoredRealm].self, forKey: .anchoredRealms) ?? []
        pendingAnchorSettlement = try container.decodeIfPresent(Bool.self, forKey: .pendingAnchorSettlement) ?? false
        pendingAnchorSettlementOutcomeID = try container.decodeIfPresent(
            ExpeditionOutcomeID.self, forKey: .pendingAnchorSettlementOutcomeID)
        lastSpringOutcomeID = try container.decodeIfPresent(ExpeditionOutcomeID.self,
                                                             forKey: .lastSpringOutcomeID)
    }

    mutating func mintOutcomeID() -> ExpeditionOutcomeID {
        outcomeSequence &+= 1
        return ExpeditionOutcomeID(rawValue: outcomeSequence)
    }
}

/// How a realm was rebound. This is history only: every route produces the same durable realm.
enum AnchorRoute: String, Codable, Equatable, Sendable {
    case bornAnchored
    case naturalPoint
    case craftedFrame
}

/// A permanent realm in Tovin's Anchorage.
///
/// The complete run snapshot preserves authored layout and depleted unique finds. Transient
/// expedition fields are normalised when anchoring/revisiting lands, rather than throwing away
/// information here that later persistence rules may need.
struct AnchoredRealm: Codable, Equatable, Identifiable, Sendable {
    var runIndex: Int
    var name: String
    var route: AnchorRoute
    var isDormant: Bool
    var sustainObligation: Int
    var productionContribution: Int
    var assignedCompanions: [Int]
    var world: WorldRun

    var id: Int { runIndex }
    var projectedShortfall: Int { max(0, sustainObligation - productionContribution) }

    init(runIndex: Int, name: String, route: AnchorRoute, isDormant: Bool = false,
         sustainObligation: Int = 0, productionContribution: Int = 0,
         assignedCompanions: [Int] = [], world: WorldRun) {
        self.runIndex = runIndex
        self.name = name
        self.route = route
        self.isDormant = isDormant
        self.sustainObligation = sustainObligation
        self.productionContribution = productionContribution
        self.assignedCompanions = assignedCompanions
        self.world = world
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        runIndex = try c.decode(Int.self, forKey: .runIndex)
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? "Realm \(runIndex)"
        route = try c.decodeIfPresent(AnchorRoute.self, forKey: .route) ?? .naturalPoint
        isDormant = try c.decodeIfPresent(Bool.self, forKey: .isDormant) ?? false
        sustainObligation = try c.decodeIfPresent(Int.self, forKey: .sustainObligation) ?? 0
        productionContribution = try c.decodeIfPresent(Int.self, forKey: .productionContribution) ?? 0
        assignedCompanions = try c.decodeIfPresent([Int].self, forKey: .assignedCompanions) ?? []
        world = try c.decode(WorldRun.self, forKey: .world)
    }
}

/// Equal per-member experience earned during one expedition, retained by source so the recap can
/// explain a total instead of presenting an opaque number such as "+100".
struct RunExperienceBreakdown: Codable, Equatable, Sendable {
    var combat: Int = 0
    var species: Int = 0
    var sites: Int = 0
    var pages: Int = 0
    var travellers: Int = 0

    var total: Int { combat + species + sites + pages + travellers }

    mutating func record(_ discovery: CharacterRules.Discovery) {
        switch discovery {
        case .species: species += discovery.experience
        case .site: sites += discovery.experience
        case .page: pages += discovery.experience
        case .traveller: travellers += discovery.experience
        }
    }
}

struct RunExitSummary: Codable, Equatable, Identifiable, Sendable {
    struct RecoveredWriting: Codable, Equatable, Identifiable, Sendable {
        enum Kind: String, Codable, Sendable {
            case diaryPage, fieldNote, routeMark, siteFragment, workingScrap
        }
        var id: String
        var kind: Kind
        var title: String
        var prose: String
    }
    struct EssenceEconomy: Codable, Equatable, Sendable {
        var rawCollected: Int = 0
        var refinedEquivalent: Int = 0
        var bindCostPaid: Int = 0
        var springYield: Int = 0
        var antiLockSubsidy: Int = 0
        var netRunway: Int = 0
    }
    enum Kind: String, Codable, Equatable, Sendable {
        case portal, waystone, defeat, collapse, abandon

        var title: String {
            switch self {
            case .portal: "Returned through a portal"
            case .waystone: "Returned by Waystone"
            case .defeat: "Carried home"
            case .collapse: "Lost to the collapsing world"
            case .abandon: "Expedition abandoned"
            }
        }
    }

    var runIndex: Int
    var outcomeID: ExpeditionOutcomeID?
    var kind: Kind
    var reason: String
    var turnsTaken: Int
    var haulKeptFraction: Double
    var resources: [RunExitGain] = []
    var items: [RunExitGain] = []
    var lostResources: [RunExitGain] = []
    var lostItems: [RunExitGain] = []
    var progress: [RunProgressGain] = []
    var pages: [DiaryPageID] = []
    var writings: [RecoveredWriting] = []
    var recruitedTravellers: [TravellerID] = []
    var essenceEconomy = EssenceEconomy()
    var experienceBreakdown = RunExperienceBreakdown()

    var id: String { outcomeID.map { "outcome-\($0.rawValue)" } ?? "legacy-run-\(runIndex)" }

    init(runIndex: Int, outcomeID: ExpeditionOutcomeID? = nil,
         kind: Kind, reason: String, turnsTaken: Int, haulKeptFraction: Double,
         resources: [RunExitGain] = [], items: [RunExitGain] = [],
         lostResources: [RunExitGain] = [], lostItems: [RunExitGain] = [],
         progress: [RunProgressGain] = [],
         pages: [DiaryPageID] = [], writings: [RecoveredWriting] = [],
         recruitedTravellers: [TravellerID] = [],
         experienceBreakdown: RunExperienceBreakdown = RunExperienceBreakdown(),
         essenceEconomy: EssenceEconomy = EssenceEconomy()) {
        self.runIndex = runIndex
        self.outcomeID = outcomeID
        self.kind = kind
        self.reason = reason
        self.turnsTaken = turnsTaken
        self.haulKeptFraction = haulKeptFraction
        self.resources = resources
        self.items = items
        self.lostResources = lostResources
        self.lostItems = lostItems
        self.progress = progress
        self.pages = pages
        self.writings = writings
        self.recruitedTravellers = recruitedTravellers
        self.essenceEconomy = essenceEconomy
        self.experienceBreakdown = experienceBreakdown
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        runIndex = try c.decode(Int.self, forKey: .runIndex)
        outcomeID = try c.decodeIfPresent(ExpeditionOutcomeID.self, forKey: .outcomeID)
        let fraction = try c.decode(Double.self, forKey: .haulKeptFraction)
        kind = try c.decodeIfPresent(Kind.self, forKey: .kind) ?? (fraction >= 1 ? .portal : .collapse)
        reason = try c.decode(String.self, forKey: .reason)
        turnsTaken = try c.decode(Int.self, forKey: .turnsTaken)
        haulKeptFraction = fraction
        resources = try c.decodeIfPresent([RunExitGain].self, forKey: .resources) ?? []
        items = try c.decodeIfPresent([RunExitGain].self, forKey: .items) ?? []
        lostResources = try c.decodeIfPresent([RunExitGain].self, forKey: .lostResources) ?? []
        lostItems = try c.decodeIfPresent([RunExitGain].self, forKey: .lostItems) ?? []
        progress = try c.decodeIfPresent([RunProgressGain].self, forKey: .progress) ?? []
        pages = try c.decodeIfPresent([DiaryPageID].self, forKey: .pages) ?? []
        writings = try c.decodeIfPresent([RecoveredWriting].self, forKey: .writings) ?? []
        recruitedTravellers = try c.decodeIfPresent([TravellerID].self,
                                                     forKey: .recruitedTravellers) ?? []
        essenceEconomy = try c.decodeIfPresent(EssenceEconomy.self, forKey: .essenceEconomy) ?? EssenceEconomy()
        experienceBreakdown = try c.decodeIfPresent(RunExperienceBreakdown.self,
                                                     forKey: .experienceBreakdown)
            ?? RunExperienceBreakdown()
    }
}

struct RunExitGain: Codable, Equatable, Identifiable, Sendable {
    var name: String
    var icon: String
    var count: Int
    var id: String { "\(name)-\(icon)" }
}

struct RunProgressGain: Codable, Equatable, Identifiable, Sendable {
    var member: PartyMember
    var name: String
    var experience: Int
    var levels: Int
    var finalLevel: Int
    var id: String { member.id }
}

struct RunProgressStart: Codable, Equatable, Sendable {
    var member: PartyMember
    var name: String
    var experience: Int
    var level: Int
}

/// A world's deterministic, turn-driven phase schedule.
///
/// `entryTurn` and `entryPhase` are migration anchors as well as useful explicit state. New worlds
/// begin at dawn. A save made under the former fixed forty-turn clock begins the new schedule at
/// precisely the phase it had when decoded, so updating cannot jump somebody into darkness.
struct WorldClock: Codable, Equatable, Sendable {
    var cyclePeak: Double
    var regularity: Double
    var amplitude: Double
    var entryTurn: Int
    var entryPhase: Double
    var entryIsNight: Bool
    var seed: UInt64

    var isStopped: Bool { cyclePeak <= Tuning.DayNight.stoppedMaximumPeak }

    init(cyclePeak: Double, regularity: Double, amplitude: Double = 40,
         entryTurn: Int = 0, entryPhase: Double = 0, entryIsNight: Bool = false,
         seed: UInt64) {
        self.cyclePeak = cyclePeak
        self.regularity = regularity
        self.amplitude = amplitude
        self.entryTurn = entryTurn
        self.entryPhase = entryPhase
        self.entryIsNight = entryIsNight
        self.seed = seed
    }

    var basePeriod: Int {
        switch cyclePeak {
        case ...Tuning.DayNight.stoppedMaximumPeak: 0
        case ...Tuning.DayNight.slowMaximumPeak: Tuning.DayNight.slowTurnsPerCycle
        case ...Tuning.DayNight.measuredMaximumPeak: Tuning.DayNight.measuredTurnsPerCycle
        case ...Tuning.DayNight.quickMaximumPeak: Tuning.DayNight.quickTurnsPerCycle
        default: Tuning.DayNight.restlessTurnsPerCycle
        }
    }

    var bandName: String {
        switch cyclePeak {
        case ...Tuning.DayNight.stoppedMaximumPeak: "Stopped"
        case ...Tuning.DayNight.slowMaximumPeak: "Slow"
        case ...Tuning.DayNight.measuredMaximumPeak: "Measured"
        case ...Tuning.DayNight.quickMaximumPeak: "Quick"
        default: "Restless"
        }
    }

    init(book: BoundBook, seed: UInt64) {
        let readings = BookRules.readings(for: book, seed: seed)
        let cycle = readings["cycle"]
        let light = readings["illumination"]
        cyclePeak = cycle.peak
        regularity = cycle.aspect("regularity")
        amplitude = cycle.aspect("amplitude")
        entryTurn = 0
        entryPhase = 0
        // A stopped sky with no usable light holds dark. A cyclic or constant usable light holds
        // at day; the source remains present, it simply does not traverse the sky.
        entryIsNight = light.peak < Tuning.Pressure.trueDarkFloor
        self.seed = seed
    }

    static func migratingLegacy(book: BoundBook, seed: UInt64, turnsTaken: Int) -> WorldClock {
        var clock = WorldClock(book: book, seed: seed)
        let oldPeriod = max(1, Tuning.DayNight.turnsPerDay)
        clock.entryTurn = turnsTaken
        clock.entryPhase = Double(turnsTaken % oldPeriod) / Double(oldPeriod)
        let light = BookRules.readings(for: book, seed: seed)["illumination"]
        let oldHadNight = light.range > Tuning.Pressure.wideRangeThreshold && !light.has("sourceless")
        clock.entryIsNight = oldHadNight
            && clock.entryPhase >= 1 - Tuning.DayNight.nightFraction
        return clock
    }

    /// The length of one complete cycle. Each index has its own stable draw; querying the clock
    /// never consumes the run's live RNG or depends on how many times the UI redraws.
    func period(forCycle index: Int) -> Int {
        guard !isStopped else { return 0 }
        let clampedRegularity = min(100, max(0, regularity))
        let jitter = Tuning.DayNight.maximumJitterFraction * (1 - clampedRegularity / 100)
        var rng = SeededRNG(seed: seed).derived(0xC1C1E &+ UInt64(max(0, index)))
        let multiplier = rng.double(in: (1 - jitter)...(1 + jitter))
        return max(Tuning.DayNight.minimumTurnsPerCycle,
                   Int((Double(basePeriod) * multiplier).rounded()))
    }

    /// Phase in `[0, 1)`, monotonically advancing and wrapping only at a completed cycle.
    func phase(at turn: Int) -> Double {
        guard !isStopped else { return entryPhase }
        var remaining = max(0, turn - entryTurn)
        var phase = min(0.999_999, max(0, entryPhase))
        var index = 0
        while remaining > 0 {
            let period = period(forCycle: index)
            let turnsToBoundary = max(1, Int(ceil((1 - phase) * Double(period))))
            if remaining < turnsToBoundary {
                return min(0.999_999, phase + Double(remaining) / Double(period))
            }
            remaining -= turnsToBoundary
            phase = 0
            index += 1
        }
        return phase
    }
}

/// Facts captured while a world is made. These are observations, not inputs: diagnostics must
/// never reconstruct a generation decision from mutable tiles or by consuming the world's RNG.
struct WorldGenerationDiagnostics: Codable, Equatable, Sendable {
    var writingWasGuaranteed: Bool = true
    var selectedDiaryPages: [DiaryPageID] = []
    var selectedOtherWritingCount: Int = 0
    var placedDiaryPages: [DiaryPageID] = []
    var placedOtherWritings: [FoundWritingID] = []
    var secondWritingRollSucceeded: Bool = false

    var rawEssenceEligibleTiles: Int = 0
    var rawEssencePlacementAttempts: Int = 0
    var rawEssenceDropsPlaced: Int = 0
    var rawEssenceObtainable: Int = 0
    var ordinaryResourceNodes: [ResourceID: Int] = [:]

    var creatureSpeciesCount: Int = 0
    var creatureInstancesPlaced: Int = 0
    var floraSpeciesCount: Int = 0
    var floraInstancesPlaced: Int = 0
    var activeFloraPlaced: Int = 0
    var apexChance: Double = 0
    var apexRollSucceeded: Bool = false
    var apexPlaced: Bool = false

    var initialTurnBudget: Int = 0
    var projectedCollapseTurn: Int = 0
    var travellerCandidates: [TravellerID] = []
    var travellerSignatureMatches: [TravellerID] = []
    var travellersPlaced: [TravellerID] = []

    var openingEnvelopeRequested: DebugTuningProfile.OpeningEncounterEnvelope = .natural
    var openingEnvelopeApplied: Bool = false
    var openingEnemiesRelocated: Int = 0

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        writingWasGuaranteed = try c.decodeIfPresent(Bool.self, forKey: .writingWasGuaranteed) ?? true
        selectedDiaryPages = try c.decodeIfPresent([DiaryPageID].self, forKey: .selectedDiaryPages) ?? []
        selectedOtherWritingCount = try c.decodeIfPresent(Int.self, forKey: .selectedOtherWritingCount) ?? 0
        placedDiaryPages = try c.decodeIfPresent([DiaryPageID].self, forKey: .placedDiaryPages) ?? []
        placedOtherWritings = try c.decodeIfPresent([FoundWritingID].self, forKey: .placedOtherWritings) ?? []
        secondWritingRollSucceeded = try c.decodeIfPresent(Bool.self, forKey: .secondWritingRollSucceeded) ?? false
        rawEssenceEligibleTiles = try c.decodeIfPresent(Int.self, forKey: .rawEssenceEligibleTiles) ?? 0
        rawEssencePlacementAttempts = try c.decodeIfPresent(Int.self, forKey: .rawEssencePlacementAttempts) ?? 0
        rawEssenceDropsPlaced = try c.decodeIfPresent(Int.self, forKey: .rawEssenceDropsPlaced) ?? 0
        rawEssenceObtainable = try c.decodeIfPresent(Int.self, forKey: .rawEssenceObtainable) ?? 0
        ordinaryResourceNodes = try c.decodeIfPresent([ResourceID: Int].self, forKey: .ordinaryResourceNodes) ?? [:]
        creatureSpeciesCount = try c.decodeIfPresent(Int.self, forKey: .creatureSpeciesCount) ?? 0
        creatureInstancesPlaced = try c.decodeIfPresent(Int.self, forKey: .creatureInstancesPlaced) ?? 0
        floraSpeciesCount = try c.decodeIfPresent(Int.self, forKey: .floraSpeciesCount) ?? 0
        floraInstancesPlaced = try c.decodeIfPresent(Int.self, forKey: .floraInstancesPlaced) ?? 0
        activeFloraPlaced = try c.decodeIfPresent(Int.self, forKey: .activeFloraPlaced) ?? 0
        apexChance = try c.decodeIfPresent(Double.self, forKey: .apexChance) ?? 0
        apexRollSucceeded = try c.decodeIfPresent(Bool.self, forKey: .apexRollSucceeded) ?? false
        apexPlaced = try c.decodeIfPresent(Bool.self, forKey: .apexPlaced) ?? false
        initialTurnBudget = try c.decodeIfPresent(Int.self, forKey: .initialTurnBudget) ?? 0
        projectedCollapseTurn = try c.decodeIfPresent(Int.self, forKey: .projectedCollapseTurn) ?? 0
        travellerCandidates = try c.decodeIfPresent([TravellerID].self, forKey: .travellerCandidates) ?? []
        travellerSignatureMatches = try c.decodeIfPresent([TravellerID].self, forKey: .travellerSignatureMatches) ?? []
        travellersPlaced = try c.decodeIfPresent([TravellerID].self, forKey: .travellersPlaced) ?? []
        openingEnvelopeRequested = try c.decodeIfPresent(DebugTuningProfile.OpeningEncounterEnvelope.self,
                                                          forKey: .openingEnvelopeRequested) ?? .natural
        openingEnvelopeApplied = try c.decodeIfPresent(Bool.self, forKey: .openingEnvelopeApplied) ?? false
        openingEnemiesRelocated = try c.decodeIfPresent(Int.self, forKey: .openingEnemiesRelocated) ?? 0
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
    /// Development-only creation profile snapshotted into the run. Defaults in release and for
    /// old saves; keeping it here is what makes changing Settings unable to rewrite a live world.
    var tuning: DebugTuningProfile
    /// Optional frozen visual receipt for the accepted world-grade-2 renderer. Worlds bound
    /// before that contract omit it and retain the v1 appearance; it is never inferred on load.
    var worldVisualReceipt: WorldVisualReceipt?
    var generationDiagnostics: WorldGenerationDiagnostics
    /// The resolved Cycle pressure made operational. Stored with the run so phase scheduling is
    /// deterministic across saves and anchored revisits, while old runs can preserve their phase
    /// at the migration boundary.
    var clock: WorldClock

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
    var foundWritings: [FoundWritingRecord] = []
    /// Turns of lingering harm from something toxic you walked through.
    ///
    /// **Chemical defence is the one that stays with you** (`flora-system-spec.md` §6) — thorns cost
    /// you once and poison keeps costing — and a counter on the run is the only place that can
    /// survive a force-quit halfway through it.
    var floraPoisonTurns: Int = 0

    /// 0–100, always visible. Decays per *player turn* only — never wall-clock (pillar 2).
    var stability: Double = Tuning.World.startingStability

    /// Frozen when the world is bound. This includes seeded rolls for every subject the page left
    /// unwritten, so relaunches and anchored revisits cannot reinterpret the same world.
    var resolvedStabilityScore: Int

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
    var effectiveStabilityScore: Int { resolvedStabilityScore }


    var decayPerTurn: Double {
        BookRules.decayPerTurn(stabilityScore: effectiveStabilityScore)
            / max(0.01, tuning.stabilityDurationMultiplier)
    }
    /// Player turns taken this run. The only clock the game has.
    var turnsTaken: Int = 0

    /// Where in the world's day this turn falls, 0 at dawn and approaching 1 at the next dawn.
    ///
    /// Driven by `turnsTaken`, never by wall-clock — the day turns because you moved, which is what
    /// keeps the interruptibility pillar true.
    var dayPhase: Double {
        clock.phase(at: turnsTaken)
    }

    /// **A world lit by something constant never has a night at all.** Darkness only happens where
    /// the light comes and goes, which is what finally makes Illumination's dynamic range mean
    /// something (session 13 §6).
    var isNight: Bool {
        if clock.isStopped { return clock.entryIsNight }
        guard hasDayAndNight else { return false }
        return dayPhase >= 1 - Tuning.DayNight.nightFraction
    }

    /// Whether this world turns at all. A sourceless glow doesn't set.
    var hasDayAndNight: Bool {
        let light = BookRules.readings(for: book, seed: mapSeed)["illumination"]
        return !clock.isStopped
            && light.range > Tuning.Pressure.wideRangeThreshold && !light.has("sourceless")
    }

    /// Read-only debug schedule. It deliberately derives rather than mutates, so opening the
    /// diagnostics screen cannot consume RNG or advance the world.
    func nextLightTransitions(count: Int = 2) -> [(turn: Int, isNight: Bool)] {
        guard count > 0, hasDayAndNight else { return [] }
        var result: [(Int, Bool)] = []
        var previous = isNight
        var turn = turnsTaken
        let searchLimit = turnsTaken + max(256, clock.basePeriod * (count + 2))
        while result.count < count && turn < searchLimit {
            turn += 1
            let phase = clock.phase(at: turn)
            let night = phase >= 1 - Tuning.DayNight.nightFraction
            if night != previous {
                result.append((turn, night))
                previous = night
            }
        }
        return result
    }

    /// Unbanked haul. Kept 100% on portal exit, `collapseHaulKeptFraction` on collapse.
    var satchel: ResourcePool = ResourcePool()
    var satchelItems: Inventory = Inventory(slots: Tuning.Economy.startingInventorySlots)
    /// Frozen at departure: changing next trip's kit cannot alter a world already in progress.
    var carriedInstruments: Set<PressureTargetID> = []
    /// Grade is frozen at departure along with the packing choice.
    var carriedInstrumentPrecisions: [PressureTargetID: RealityState.InstrumentPrecision] = [:]
    /// Extra sight granted by a torch for the rest of this trip.
    var torchVisionBonus: Int = 0

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
    /// Progress when the party crossed the threshold, for the return-home recap.
    var partyProgressAtStart: [RunProgressStart] = []
    /// Equal per-member awards earned since that threshold, retained by source for an honest recap.
    var experienceBreakdown = RunExperienceBreakdown()
    /// Items deliberately brought from home, excluded from the "loot obtained" recap.
    var carriedItemCountsAtStart: [ItemID: Int] = [:]
    /// Pages already known on departure, so the recap can name only discoveries from this trip.
    var foundPagesAtStart: Set<DiaryPageID> = []
    var foundWritingsAtStart: Set<FoundWritingID> = []
    var foundTravellersAtStart: Set<TravellerID> = []

    init(runIndex: Int, book: BoundBook, mapSeed: UInt64, rng: SeededRNG, map: WorldMap,
         playerPosition: GridPoint, enemies: [WorldEnemy] = [], sites: [PlacedSite] = [],
         travellersHere: [TravellerID] = [], cast: [Species] = [], flora: [Flora] = [],
         foundWritings: [FoundWritingRecord] = [],
         binderHP: Int = Tuning.Encounter.binderMaxHP,
         companionHP: [Int: Int] = [:],
         satchelItems: Inventory = Inventory(slots: Tuning.Economy.startingInventorySlots),
         carriedInstruments: Set<PressureTargetID> = [],
         carriedInstrumentPrecisions: [PressureTargetID: RealityState.InstrumentPrecision] = [:],
         partyProgressAtStart: [RunProgressStart] = [],
         carriedItemCountsAtStart: [ItemID: Int] = [:],
         foundPagesAtStart: Set<DiaryPageID> = [],
         foundWritingsAtStart: Set<FoundWritingID> = [],
         foundTravellersAtStart: Set<TravellerID> = [],
         resolvedStabilityScore: Int? = nil,
         generationDiagnostics: WorldGenerationDiagnostics = WorldGenerationDiagnostics(),
         tuning: DebugTuningProfile = .defaults,
         worldVisualReceipt: WorldVisualReceipt? = nil) {
        self.runIndex = runIndex
        self.book = book
        self.mapSeed = mapSeed
        self.rng = rng
        self.tuning = tuning
        self.worldVisualReceipt = worldVisualReceipt
        self.generationDiagnostics = generationDiagnostics
        self.clock = WorldClock(book: book, seed: mapSeed)
        self.map = map
        self.playerPosition = playerPosition
        self.enemies = enemies
        self.sites = sites
        self.travellersHere = travellersHere
        self.cast = cast
        self.flora = flora
        self.foundWritings = foundWritings
        self.binderHP = binderHP
        self.companionHP = companionHP
        self.satchelItems = satchelItems
        self.carriedInstruments = carriedInstruments
        self.carriedInstrumentPrecisions = carriedInstrumentPrecisions
        self.partyProgressAtStart = partyProgressAtStart
        self.carriedItemCountsAtStart = carriedItemCountsAtStart
        self.foundPagesAtStart = foundPagesAtStart
        self.foundWritingsAtStart = foundWritingsAtStart
        self.foundTravellersAtStart = foundTravellersAtStart
        self.resolvedStabilityScore = resolvedStabilityScore
            ?? BookRules.resolvedStabilityScore(of: book, seed: mapSeed)
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
        // A run bound before tuning snapshots existed is already a historical Legacy run. The
        // newly promoted preference default applies only at the next bind, never during decode.
        tuning = try container.decodeIfPresent(DebugTuningProfile.self, forKey: .tuning)
            ?? .legacyFrozenRunDefaults
        worldVisualReceipt = try container.decodeIfPresent(WorldVisualReceipt.self,
                                                            forKey: .worldVisualReceipt)
        try worldVisualReceipt?.validate()
        generationDiagnostics = try container.decodeIfPresent(WorldGenerationDiagnostics.self,
                                                                forKey: .generationDiagnostics)
            ?? WorldGenerationDiagnostics()
        map = try container.decode(WorldMap.self, forKey: .map)
        playerPosition = try container.decode(GridPoint.self, forKey: .playerPosition)
        enemies = try container.decodeIfPresent([WorldEnemy].self, forKey: .enemies) ?? []
        sites = try container.decodeIfPresent([PlacedSite].self, forKey: .sites) ?? []
        travellersHere = try container.decodeIfPresent([TravellerID].self, forKey: .travellersHere) ?? []
        cast = try container.decodeIfPresent([Species].self, forKey: .cast) ?? []
        flora = try container.decodeIfPresent([Flora].self, forKey: .flora) ?? []
        foundWritings = try container.decodeIfPresent([FoundWritingRecord].self,
                                                       forKey: .foundWritings) ?? []
        floraPoisonTurns = try container.decodeIfPresent(Int.self, forKey: .floraPoisonTurns) ?? 0
        stability = try container.decodeIfPresent(Double.self, forKey: .stability)
            ?? Tuning.World.startingStability
        resolvedStabilityScore = try container.decodeIfPresent(Int.self,
                                                                forKey: .resolvedStabilityScore)
            ?? BookRules.resolvedStabilityScore(of: book, seed: mapSeed)
        turnsTaken = try container.decodeIfPresent(Int.self, forKey: .turnsTaken) ?? 0
        clock = try container.decodeIfPresent(WorldClock.self, forKey: .clock)
            ?? WorldClock.migratingLegacy(book: book, seed: mapSeed, turnsTaken: turnsTaken)
        satchel = try container.decodeIfPresent(ResourcePool.self, forKey: .satchel) ?? ResourcePool()
        satchelItems = try container.decodeIfPresent(Inventory.self, forKey: .satchelItems)
            ?? Inventory(slots: Tuning.Economy.startingInventorySlots)
        carriedInstruments = try container.decodeIfPresent(Set<PressureTargetID>.self,
                                                            forKey: .carriedInstruments) ?? []
        carriedInstrumentPrecisions = try container.decodeIfPresent(
            [PressureTargetID: RealityState.InstrumentPrecision].self,
            forKey: .carriedInstrumentPrecisions) ?? [:]
        torchVisionBonus = try container.decodeIfPresent(Int.self, forKey: .torchVisionBonus) ?? 0
        activeEncounter = try container.decodeIfPresent(EncounterState.self, forKey: .activeEncounter)
        offeredItems = try container.decodeIfPresent([ItemStack].self, forKey: .offeredItems) ?? []
        previousPosition = try container.decodeIfPresent(GridPoint.self, forKey: .previousPosition)
        encounterGraceTurns = try container.decodeIfPresent(Int.self, forKey: .encounterGraceTurns) ?? 0
        collapsedOnTurn = try container.decodeIfPresent(Int.self, forKey: .collapsedOnTurn)
        binderHP = try container.decodeIfPresent(Int.self, forKey: .binderHP) ?? Tuning.Encounter.binderMaxHP
        partyProgressAtStart = try container.decodeIfPresent([RunProgressStart].self,
                                                              forKey: .partyProgressAtStart) ?? []
        experienceBreakdown = try container.decodeIfPresent(RunExperienceBreakdown.self,
                                                              forKey: .experienceBreakdown)
            ?? RunExperienceBreakdown()
        carriedItemCountsAtStart = try container.decodeIfPresent([ItemID: Int].self,
                                                                  forKey: .carriedItemCountsAtStart) ?? [:]
        // Saves already in a world predate per-stack protection. Reconstruct conservatively from
        // their departure counts: never risk deleting an item that may have crossed from Home.
        if !carriedItemCountsAtStart.isEmpty,
           satchelItems.stacks.allSatisfy({ $0.protectedReturnCount == 0 }) {
            var remaining = carriedItemCountsAtStart
            for index in satchelItems.stacks.indices {
                let id = satchelItems.stacks[index].catalogID
                let protected = min(satchelItems.stacks[index].count, remaining[id] ?? 0)
                satchelItems.stacks[index].protectedReturnCount = protected
                remaining[id, default: 0] -= protected
            }
        }
        foundPagesAtStart = try container.decodeIfPresent(Set<DiaryPageID>.self,
                                                           forKey: .foundPagesAtStart) ?? []
        foundWritingsAtStart = try container.decodeIfPresent(Set<FoundWritingID>.self,
                                                              forKey: .foundWritingsAtStart) ?? []
        foundTravellersAtStart = try container.decodeIfPresent(Set<TravellerID>.self,
                                                                forKey: .foundTravellersAtStart) ?? []
        // A run saved when only one person could come brings that one person's health with it.
        if let perMember = try? container.decodeIfPresent([Int: Int].self, forKey: .companionHP) {
            companionHP = perMember
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

extension WorldRun {
    /// The durable world, stripped of things that belong to one expedition rather than the realm.
    var anchoredSnapshot: WorldRun {
        var snapshot = self
        snapshot.satchel = ResourcePool()
        snapshot.satchelItems = Inventory(slots: Tuning.Economy.startingSatchelSlots)
        snapshot.carriedInstruments = []
        snapshot.carriedInstrumentPrecisions = [:]
        snapshot.activeEncounter = nil
        snapshot.offeredItems = []
        snapshot.partyProgressAtStart = []
        snapshot.experienceBreakdown = RunExperienceBreakdown()
        snapshot.carriedItemCountsAtStart = [:]
        snapshot.foundPagesAtStart = []
        return snapshot
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
