import CoreGraphics

/// Stable phone placement for one authored 24-node combat tree. Combat depth and discipline are
/// explicit authority; prerequisites and display names never infer position.
struct CombatGraphLayout {
    static let canvasHeight: CGFloat = 466
    struct Placement: Identifiable, Equatable {
        let node: CombatGraphNodeDef
        let discipline: CombatDisciplineDef
        let disciplineIndex: Int
        let siblingOffset: Int
        var id: CombatNodeID { node.id }
    }

    struct Edge: Identifiable, Equatable {
        let parent: CombatNodeID
        let child: CombatNodeID
        let isHybrid: Bool
        var id: String { "\(parent.rawValue)>\(child.rawValue)" }
    }

    let tree: CombatGraphTreeDef
    let placements: [Placement]
    let edges: [Edge]

    init(tree: CombatGraphTreeDef) {
        self.tree = tree
        placements = tree.disciplines.enumerated().flatMap { disciplineIndex, discipline in
            discipline.nodes.map { node in
                Placement(node: node, discipline: discipline, disciplineIndex: disciplineIndex,
                          siblingOffset: Self.siblingOffset(for: node.role))
            }
        }
        edges = tree.disciplines.flatMap(\.nodes).flatMap { node in
            node.sameDisciplineParents.map { Edge(parent: $0, child: node.id, isHybrid: false) }
                + node.hybridAlternativeParents.map { Edge(parent: $0, child: node.id, isHybrid: true) }
        }
    }

    static func siblingOffset(for role: CombatGraphRole) -> Int {
        switch role {
        case .fundamentalA, .developmentA, .masteryA: -1
        case .fundamentalB, .developmentB, .masteryB: 1
        case .root, .capstone: 0
        }
    }

    func point(for placement: Placement, width: CGFloat) -> CGPoint {
        let centres = [width * (70.0 / 368.0), width * 0.5, width * (298.0 / 368.0)]
        let offset = width * (27.0 / 368.0)
        return CGPoint(x: centres[placement.disciplineIndex] + CGFloat(placement.siblingOffset) * offset,
                       y: 26 + CGFloat(placement.node.depth - 1) * 98)
    }

    var orderedByDepth: [Placement] {
        placements.sorted {
            if $0.node.depth != $1.node.depth { return $0.node.depth < $1.node.depth }
            if $0.disciplineIndex != $1.disciplineIndex { return $0.disciplineIndex < $1.disciplineIndex }
            if $0.siblingOffset != $1.siblingOffset { return $0.siblingOffset < $1.siblingOffset }
            return $0.id.rawValue < $1.id.rawValue
        }
    }
}

/// Local DEBUG route state. It deliberately has no GameState/CharacterState dependency, making it
/// impossible for route-explorer taps to mutate an ordinary campaign.
struct CombatGraphRouteState: Equatable {
    var pointBudget: Int = 8
    var owned: Set<CombatNodeID> = []

    var pointsRemaining: Int { max(0, pointBudget - owned.count) }

    func canPurchase(_ node: CombatGraphNodeDef, catalogue: CombatGraphCatalogue) -> Bool {
        pointsRemaining > 0 && CombatGraphRules.canPurchase(node, owned: owned, catalogue: catalogue)
    }

    @discardableResult
    mutating func purchase(_ node: CombatGraphNodeDef, catalogue: CombatGraphCatalogue) -> Bool {
        guard canPurchase(node, catalogue: catalogue) else { return false }
        owned.insert(node.id)
        return true
    }

    mutating func reset() { owned = [] }

    mutating func selectPointBudget(_ value: Int) {
        guard pointBudget != value else { return }
        pointBudget = value
        owned = []
    }
}

enum CombatGraphNodeState: String {
    case owned = "Owned"
    case available = "Available"
    case blocked = "Blocked"

    var playerLabel: String {
        switch self {
        case .owned: "Learned"
        case .available: "Available"
        case .blocked: "Blocked"
        }
    }
}
