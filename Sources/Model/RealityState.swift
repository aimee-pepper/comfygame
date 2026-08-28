import Foundation

/// Layer 1 — Reality. Survives everything, including the future base-reset / NG+ flow.
///
/// Only put something here if losing it in a reset would feel like losing the *player's* history
/// rather than the *character's* possessions.
struct RealityState: Codable, Equatable, Sendable {
    struct CurioFamilyKnowledgeV1: Codable, Equatable, Sendable {
        static let version = 1

        var version: Int = Self.version
        var familyID: ItemID
        var revealedItemID: ItemID
        var observationCount: Int
        var firstResolutionRunIndex: Int
        var isRecognized: Bool

        func validates(key: ItemID? = nil) -> Bool {
            guard version == Self.version, key == nil || key == familyID,
                  observationCount > 0, firstResolutionRunIndex >= 0,
                  let family = ContentCatalog.shared.item(familyID), family.kind == .curio,
                  family.identifiesInto == revealedItemID,
                  ContentCatalog.shared.item(revealedItemID) != nil else { return false }
            return isRecognized == (observationCount >= Tuning.Economy.curioRecognitionThreshold)
        }
    }
    enum InstrumentPrecision: Int, Codable, Comparable, Sendable {
        case crude = 1, good = 2, fine = 3

        static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
    }

    struct SubjectObservation: Codable, Equatable, Sendable {
        var count: Int
        var lowest: Double
        var highest: Double
        var bestPrecision: InstrumentPrecision

        mutating func add(peak: Double, floor: Double, precision: InstrumentPrecision) {
            count += 1
            lowest = min(lowest, floor)
            highest = max(highest, peak)
            bestPrecision = max(bestPrecision, precision)
        }
    }
    /// Rare currency; spent only on Constellation nodes.
    var motes: Int = 0
    /// Purchased rank per Constellation node (absent = unpurchased). Data-driven: node
    /// definitions live in `Content/Data/constellation.json`.
    var constellation: [ConstellationNodeID: Int] = [:]
    /// The encounter-flag registry (see `DiscoveryLog`).
    var discovery: DiscoveryLog = DiscoveryLog()
    /// Permanent tallies. Turn/run counts only — never wall-clock (pillar 2).
    var lifetime: LifetimeStats = LifetimeStats()

    /// How well the player can *read* a world — the third progression axis, alongside vocabulary
    /// and page space (decisions-session-8).
    ///
    /// In the Reality layer because readings are permanent knowledge, like specimens: measuring
    /// thermal in a volcanic world teaches you about volcanic worlds generally, and knowledge is
    /// never taken back. **Raised by the page lens** at Isolde's Scriptorium, which is itself gated
    /// on how many field instruments you have built — see `instruments` below.
    var analysisTier: Int = Tuning.Analysis.startingTier

    /// **The subjects you own a field instrument for** (`crafting-spec.md` PART TWO).
    ///
    /// One instrument per subject, made at Mara's Survey Post: a Sunglass reads Illumination, a
    /// Chronometer reads Cycle. Two families, and the second is fed by the first — **field
    /// instruments measure the world you are standing in, and the page lens only shows you what you
    /// have already measured.** So going out and measuring is how prediction is earned, and the
    /// lens grows subject by subject as the field kit does rather than in one jump.
    ///
    /// **[PLACEHOLDER] In Reality rather than Base**, alongside `analysisTier`, because they are the
    /// same axis and splitting them would leave a reset with a lens and nothing to feed it. An
    /// instrument is also a made object, and made objects are usually Base — so if a base reset ever
    /// should take your kit away, this is the line to move. Logged for Aimee.
    var instruments: Set<PressureTargetID> = []

    /// The best physical instrument owned for each subject. Kept beside `instruments` for tolerant
    /// migration: old saves still decode their owned set, and each old instrument begins crude.
    var instrumentPrecisions: [PressureTargetID: InstrumentPrecision] = [:]

    func instrumentPrecision(for target: PressureTargetID) -> InstrumentPrecision {
        instrumentPrecisions[target] ?? .crude
    }

    /// Compact permanent field knowledge. Ownership lets an instrument work in a world; an entry
    /// here means the player has actually taken that reading and calibrated the desk lens with it.
    var observations: [PressureTargetID: SubjectObservation] = [:]

    /// Whether this subject's numbers are readable at home. Buying the tool alone is not a reading.
    func measures(_ target: PressureTargetID) -> Bool { observations[target] != nil }
    var calibratedSubjects: Set<PressureTargetID> { Set(observations.keys) }

    /// Seeds of worlds the player has actually stood in.
    ///
    /// **The reveal trigger** (decisions-session-11 §1): a world you've been to has no secrets, so
    /// its rolled values may be shown in full. A world you haven't written and haven't seen has
    /// nothing but secrets. Anchoring is the other trigger and doesn't exist yet.
    ///
    /// In Reality because it's knowledge, and knowledge is never taken back.
    var visitedWorldSeeds: Set<UInt64> = []

    /// Pages read and people found. Knowledge, so it lives here and is never taken back.
    var library: LibraryState = LibraryState()

    /// Glyph identities the player has actually inspected. Meaning is deliberately not persisted:
    /// whether an entry is known is always derived from the same Base ownership that licenses the
    /// Writing Desk. Unknown/retired IDs remain here so save migration never erases a sighting.
    var encounteredLexemes: Set<LexemeIdentity> = []

    /// Permanent knowledge keyed by the unidentified family. Physical examples resolve one at a
    /// time; the second independent resolution recognizes the family for this Reality forever.
    var curioFamilyKnowledge: [ItemID: CurioFamilyKnowledgeV1] = [:]

    mutating func recordEncounter(on page: Page) {
        encounteredLexemes.formUnion(page.encounteredLexemes)
    }

    static func newGame() -> RealityState { RealityState() }

    // MARK: Derived unlocks
    // Every rule that reads the Constellation goes through here, so adding a node is a
    // data change plus one accessor, not a hunt through gameplay code.

    func rank(of node: ConstellationNodeID) -> Int { constellation[node] ?? 0 }

    /// +1 gambit slot per rank. PLACEHOLDER effect shape.
    ///
    /// **The only one left**, and that's the point (`fossil-audit.md` §6). Two others sold effects
    /// nothing read: a book slot for books that stopped having slots when the page grid landed, and
    /// a starting-essence bonus that pays out after a reset the game cannot perform. Every accessor
    /// here must be consumed somewhere outside this file — `EconomyTests` asserts it.
    var bonusGambitSlots: Int { rank(of: ConstellationNodes.extraGambitSlot) }

    init(motes: Int = 0,
         constellation: [ConstellationNodeID: Int] = [:],
         discovery: DiscoveryLog = DiscoveryLog(),
         lifetime: LifetimeStats = LifetimeStats()) {
        self.motes = motes
        self.constellation = constellation
        self.discovery = discovery
        self.lifetime = lifetime
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        motes = try container.decodeIfPresent(Int.self, forKey: .motes) ?? 0
        constellation = try container.decodeIfPresent([ConstellationNodeID: Int].self, forKey: .constellation) ?? [:]
        discovery = try container.decodeIfPresent(DiscoveryLog.self, forKey: .discovery) ?? DiscoveryLog()
        lifetime = try container.decodeIfPresent(LifetimeStats.self, forKey: .lifetime) ?? LifetimeStats()
        analysisTier = try container.decodeIfPresent(Int.self, forKey: .analysisTier)
            ?? Tuning.Analysis.startingTier
        instruments = try container.decodeIfPresent(Set<PressureTargetID>.self, forKey: .instruments) ?? []
        instrumentPrecisions = try container.decodeIfPresent(
            [PressureTargetID: InstrumentPrecision].self, forKey: .instrumentPrecisions) ?? [:]
        observations = try container.decodeIfPresent([PressureTargetID: SubjectObservation].self,
                                                      forKey: .observations) ?? [:]
        visitedWorldSeeds = try container.decodeIfPresent(Set<UInt64>.self, forKey: .visitedWorldSeeds) ?? []
        library = try container.decodeIfPresent(LibraryState.self, forKey: .library) ?? LibraryState()
        encounteredLexemes = try container.decodeIfPresent(
            Set<LexemeIdentity>.self, forKey: .encounteredLexemes) ?? []
        curioFamilyKnowledge = try container.decodeIfPresent(
            [ItemID: CurioFamilyKnowledgeV1].self, forKey: .curioFamilyKnowledge) ?? [:]
        guard curioFamilyKnowledge.allSatisfy({ $0.value.validates(key: $0.key) }) else {
            throw CocoaError(.coderInvalidValue)
        }
    }
}

/// Well-known node IDs. The *definitions* (name, cost, blurb, max rank) are data; these
/// constants exist only so gameplay code can ask about a specific node without a magic string.
enum ConstellationNodes {
    static let extraGambitSlot: ConstellationNodeID = "extra_gambit_slot"
}

struct LifetimeStats: Codable, Equatable, Sendable {
    var runsStarted: Int = 0
    var runsBankedViaPortal: Int = 0
    var runsLostToCollapse: Int = 0
    var encountersWon: Int = 0
    var encountersFled: Int = 0
    var worldTurnsTaken: Int = 0

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        runsStarted = try container.decodeIfPresent(Int.self, forKey: .runsStarted) ?? 0
        runsBankedViaPortal = try container.decodeIfPresent(Int.self, forKey: .runsBankedViaPortal) ?? 0
        runsLostToCollapse = try container.decodeIfPresent(Int.self, forKey: .runsLostToCollapse) ?? 0
        encountersWon = try container.decodeIfPresent(Int.self, forKey: .encountersWon) ?? 0
        encountersFled = try container.decodeIfPresent(Int.self, forKey: .encountersFled) ?? 0
        worldTurnsTaken = try container.decodeIfPresent(Int.self, forKey: .worldTurnsTaken) ?? 0
    }
}
