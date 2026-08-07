import Foundation

/// Layer 1 — Reality. Survives everything, including the future base-reset / NG+ flow.
///
/// Only put something here if losing it in a reset would feel like losing the *player's* history
/// rather than the *character's* possessions.
struct RealityState: Codable, Equatable, Sendable {
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
    /// never taken back. Raised by crafted instruments, which aren't built yet — so for now this
    /// only ever sits at the starting tier, and the Harness can push it up to see the later panels.
    var analysisTier: Int = Tuning.Analysis.startingTier

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
        visitedWorldSeeds = try container.decodeIfPresent(Set<UInt64>.self, forKey: .visitedWorldSeeds) ?? []
        library = try container.decodeIfPresent(LibraryState.self, forKey: .library) ?? LibraryState()
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
