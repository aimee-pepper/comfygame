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

    static func newGame() -> RealityState { RealityState() }

    // MARK: Derived unlocks
    // Every rule that reads the Constellation goes through here, so adding a node is a
    // data change plus one accessor, not a hunt through gameplay code.

    func rank(of node: ConstellationNodeID) -> Int { constellation[node] ?? 0 }

    /// +1 book slot per rank. PLACEHOLDER effect shape.
    var bonusBookSlots: Int { rank(of: ConstellationNodes.extraSymbolSlot) }
    /// +1 gambit slot per rank. PLACEHOLDER effect shape.
    var bonusGambitSlots: Int { rank(of: ConstellationNodes.extraGambitSlot) }
    /// Starting-essence bonus applied after a future reset. PLACEHOLDER effect shape.
    var startingEssenceMultiplier: Double { 1.0 + 0.10 * Double(rank(of: ConstellationNodes.essenceHead)) }

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
    }
}

/// Well-known node IDs. The *definitions* (name, cost, blurb, max rank) are data; these
/// constants exist only so gameplay code can ask about a specific node without a magic string.
enum ConstellationNodes {
    static let extraSymbolSlot: ConstellationNodeID = "extra_symbol_slot"
    static let extraGambitSlot: ConstellationNodeID = "extra_gambit_slot"
    static let essenceHead: ConstellationNodeID = "essence_head_start"
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
