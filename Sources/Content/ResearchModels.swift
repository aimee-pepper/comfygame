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
