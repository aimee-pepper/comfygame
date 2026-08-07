import Foundation

// Research and gambit grammar. Both are content, both grow, neither is a flat list.

/// What a research node costs. Essence plus, usually, raw materials — ore and fibre need a sink,
/// and paying for knowledge with the stuff you hauled home ties the two halves of the loop together.
struct UpgradeCost: Codable, Equatable, Sendable {
    var essence: Int
    var resources: [ResourceID: Int]

    init(essence: Int, resources: [ResourceID: Int] = [:]) {
        self.essence = essence
        self.resources = resources
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        essence = try container.decodeIfPresent(Int.self, forKey: .essence) ?? 0
        resources = try container.decodeIfPresent([ResourceID: Int].self, forKey: .resources) ?? [:]
    }
}

/// A themed branch of the research tree.
///
/// **All** research is gated behind one of these — there is no shopping list anywhere in the game.
/// A branch is a subject you're getting better at, and its nodes are the steps.
struct ResearchBranchDef: Codable, Equatable, Identifiable, Sendable {
    var id: ResearchBranchID
    var name: String
    var icon: String
    var blurb: String
    var order: Int

    /// **Which building teaches this** (Q40, Aimee's idea, answered yes 6 Aug).
    ///
    /// One tree at the Workshop made session 12 only half true: you find a smith, and then buy
    /// everything she knows from a generic menu that existed before you met her. A building owning
    /// the branch about it fixes that, and settles Q37 without a judgement call — capacity is what
    /// a tanner knows, so The Hold belongs at the Tannery.
    ///
    /// The split: **everything you learn yourself lives at the Workshop; everything you learn from
    /// a person lives with that person's building.** Nil means the Workshop.
    var station: StationID?

    /// **How many rungs are reachable before you've found the person**, counted from the roots.
    ///
    /// Q40's gating rule: finding somebody *accelerates and deepens, it never unblocks*. Nobody
    /// should sit at 16 storehouse slots because a four-condition tanner hasn't turned up.
    ///
    /// **Zero is the deliberate exception.** `hands-and-calligrapher-spec.md` §3: *"the player MUST
    /// meet the calligrapher to progress. it's core to the game."* The hands aren't a convenience
    /// the game withholds — they are what the game is about, and a Binder who can only scrawl in
    /// charcoal hasn't been blocked by a missing shopkeeper, they haven't yet found the person who
    /// teaches the Art.
    var freeRungs: Int = 99

    init(id: ResearchBranchID, name: String, icon: String, blurb: String, order: Int,
         station: StationID? = nil, freeRungs: Int = 99) {
        self.id = id
        self.name = name
        self.icon = icon
        self.blurb = blurb
        self.order = order
        self.station = station
        self.freeRungs = freeRungs
    }

    /// Tolerant, per the policy in `Migrations.swift` — and this one bit immediately. A property
    /// with a default is *not* optional to synthesised decoding: every branch already in the file
    /// lacked the new keys and the whole catalogue refused to load.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(ResearchBranchID.self, forKey: .id)
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? id.rawValue
        icon = try c.decodeIfPresent(String.self, forKey: .icon) ?? "book"
        blurb = try c.decodeIfPresent(String.self, forKey: .blurb) ?? ""
        order = try c.decodeIfPresent(Int.self, forKey: .order) ?? 0
        station = try c.decodeIfPresent(StationID.self, forKey: .station)
        freeRungs = try c.decodeIfPresent(Int.self, forKey: .freeRungs) ?? 99
    }
}

/// One unlock in a branch.
///
/// Deliberately one-time. Repeatable-feeling upgrades (shelving I/II/III) are separate nodes
/// chained by `requires`, which keeps the tree readable and means "rank" doesn't have to exist.
struct ResearchNodeDef: Codable, Equatable, Identifiable, Sendable {
    var id: ResearchNodeID
    var branch: ResearchBranchID
    var name: String
    var icon: String
    var blurb: String
    var cost: UpgradeCost
    /// Nodes that must be completed first. Empty = available from the start of the branch.
    var requires: [ResearchNodeID]
    var grants: [ResearchGrant]
    /// **The tier its building must have reached.** `maxTier` has never had a job; this is it
    /// (Q40). The fountain pen wants a Scriptorium at tier 2 — Aimee's "last upgrade gated behind
    /// a shop upgrade".
    var needsStationTier: Int = 0

    init(id: ResearchNodeID, branch: ResearchBranchID, name: String, icon: String, blurb: String,
         cost: UpgradeCost, requires: [ResearchNodeID] = [], grants: [ResearchGrant] = [],
         needsStationTier: Int = 0) {
        self.id = id
        self.branch = branch
        self.name = name
        self.icon = icon
        self.blurb = blurb
        self.cost = cost
        self.requires = requires
        self.grants = grants
        self.needsStationTier = needsStationTier
    }

    /// Tolerant, per the policy in `Migrations.swift`.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(ResearchNodeID.self, forKey: .id)
        branch = try c.decode(ResearchBranchID.self, forKey: .branch)
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? id.rawValue
        icon = try c.decodeIfPresent(String.self, forKey: .icon) ?? "circle"
        blurb = try c.decodeIfPresent(String.self, forKey: .blurb) ?? ""
        cost = try c.decodeIfPresent(UpgradeCost.self, forKey: .cost) ?? UpgradeCost(essence: 0)
        requires = try c.decodeIfPresent([ResearchNodeID].self, forKey: .requires) ?? []
        grants = try c.decodeIfPresent([ResearchGrant].self, forKey: .grants) ?? []
        needsStationTier = try c.decodeIfPresent(Int.self, forKey: .needsStationTier) ?? 0
    }
}

/// What completing a node hands you.
struct ResearchGrant: Codable, Equatable, Sendable {
    var kind: Kind
    /// The thing granted, for `gambitComponent` and `symbol`.
    var id: String?
    /// The state change, for `effect`.
    var effect: Effect?

    enum Kind: String, Codable, Sendable {
        case gambitComponent
        case symbol
        case effect
    }

    /// Effects mutate base state directly. Each maps to exactly one field, so nothing is stored twice.
    enum Effect: String, Codable, Sendable {
        case storehouseTier
        case satchelTier
        case gambitSlot
        case essenceSpringTier
        case automateSelf
        case companionWeapon
        case companionArmor
        /// Lifts the one-primary-per-target restriction across every target at once. A world with
        /// two kinds of land in it is an earned capability, not something you could always do.
        case chaining
        /// The next instrument up: charcoal → pencil → fountain pen. Refinement is literacy, not
        /// power — it lets you say the same things in less space, never new things.
        case finerHand
        /// Raises the Scriptorium, which is what gates the rungs above it (Q40's tier rule).
        case scriptoriumTier
    }
}

/// One part of a gambit rule.
///
/// Rules are **assembled**, never bought whole: subject + optional (property, comparator,
/// threshold) + action. So research reads "you learned to notice 30%" rather than "you bought
/// *Foe HP < 30% → Attack*", and every component you learn multiplies with everything you already
/// know. Same philosophy as the writing system — literacy, not inventory.
struct GambitComponentDef: Codable, Equatable, Identifiable, Sendable {
    var id: GambitComponentID
    var kind: Kind
    var name: String
    var icon: String
    var blurb: String

    /// `subject` — who the rule looks at, and how it picks between them.
    /// One of: self · ally.any · foe.any · foe.lowestHP · foe.highestHP
    var selector: String?
    /// `property` — what gets measured. Currently only "hp"; status and resources come later.
    var property: String?
    /// `comparator` — "below" or "above".
    var comparator: String?
    /// `threshold` — the fraction being compared against.
    var value: Double?
    /// `action` — "attack" · "heal" · "skill" · "flee".
    var action: String?

    enum Kind: String, Codable, CaseIterable, Sendable {
        case subject, property, comparator, threshold, action

        var displayName: String {
            switch self {
            case .subject: "Subject"
            case .property: "Property"
            case .comparator: "Comparator"
            case .threshold: "Threshold"
            case .action: "Action"
            }
        }
    }
}
