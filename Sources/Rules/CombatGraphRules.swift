import Foundation

/// Pure prerequisite and legacy-mapping rules for CombatGraphVersion 2.
///
/// This deliberately does not activate v2 ownership yet. It lets catalogue, topology, route, and
/// migration fixtures become authoritative before the save writer stops emitting `branchDepth`.
enum CombatGraphRules {
    static let graphVersion = 2

    static func migratedLegacyNodes(branchDepth: [CombatBranchID: Int],
                                    catalogue: CombatGraphCatalogue) -> Set<CombatNodeID> {
        Set(catalogue.disciplines.flatMap { discipline in
            let depth = min(max(0, branchDepth[discipline.legacyBranchID] ?? 0), discipline.nodes.count)
            return discipline.nodes.prefix(depth).map(\.id)
        })
    }

    static func canPurchase(_ node: CombatGraphNodeDef, owned: Set<CombatNodeID>,
                            catalogue: CombatGraphCatalogue) -> Bool {
        guard !owned.contains(node.id),
              let tree = catalogue.tree(containing: node.id),
              let discipline = catalogue.discipline(containing: node.id) else { return false }
        if node.role == .root { return true }
        guard node.ordinaryParentAlternatives.contains(where: owned.contains) else { return false }
        guard node.role == .capstone else { return true }
        return capstoneGateSatisfied(node, tree: tree, discipline: discipline,
                                     owned: owned, catalogue: catalogue)
    }

    static func availableNodes(owned: Set<CombatNodeID>,
                               catalogue: CombatGraphCatalogue) -> [CombatGraphNodeDef] {
        catalogue.nodes.filter { canPurchase($0, owned: owned, catalogue: catalogue) }
    }

    static func isLegalPurchaseOrder(_ ids: [CombatNodeID],
                                     initialOwned: Set<CombatNodeID> = [],
                                     catalogue: CombatGraphCatalogue) -> Bool {
        var owned = initialOwned
        for id in ids {
            guard let node = catalogue.node(id),
                  canPurchase(node, owned: owned, catalogue: catalogue) else { return false }
            owned.insert(id)
        }
        return true
    }

    private static func capstoneGateSatisfied(_ node: CombatGraphNodeDef,
                                              tree: CombatGraphTreeDef,
                                              discipline: CombatDisciplineDef,
                                              owned: Set<CombatNodeID>,
                                              catalogue: CombatGraphCatalogue) -> Bool {
        let gate = catalogue.capstoneGate
        let treeIDs = Set(tree.disciplines.flatMap(\.nodes).map(\.id))
        let priorInTree = owned.intersection(treeIDs)
        guard priorInTree.count >= gate.minimumPriorNodesInTree else { return false }

        let ownNodes = discipline.nodes.filter { owned.contains($0.id) }
        guard let root = ownNodes.first(where: { $0.role == .root })?.id else { return false }
        guard gate.priorNodesMustFormOneConnectedPrerequisiteSubgraph else {
            return ownNodes.count + 1 >= gate.minimumNodesInCapstoneDisciplineIncludingCapstone
                && ownsRequiredDepths(ownNodes)
        }
        let connected = connectedComponent(from: root, within: priorInTree,
                                           tree: tree, catalogue: catalogue)
        let componentOwn = ownNodes.filter { connected.contains($0.id) }
        return connected.count >= gate.minimumPriorNodesInTree
            && componentOwn.count + 1 >= gate.minimumNodesInCapstoneDisciplineIncludingCapstone
            && ownsRequiredDepths(componentOwn)
    }

    private static func ownsRequiredDepths(_ nodes: [CombatGraphNodeDef]) -> Bool {
        nodes.contains(where: { $0.role == .root })
            && nodes.contains(where: { $0.role == .fundamentalA || $0.role == .fundamentalB })
            && nodes.contains(where: { $0.role == .developmentA || $0.role == .developmentB })
            && nodes.contains(where: { $0.role == .masteryA || $0.role == .masteryB })
    }

    private static func connectedComponent(from start: CombatNodeID,
                                           within owned: Set<CombatNodeID>,
                                           tree: CombatGraphTreeDef,
                                           catalogue: CombatGraphCatalogue) -> Set<CombatNodeID> {
        var neighbours: [CombatNodeID: Set<CombatNodeID>] = [:]
        for child in tree.disciplines.flatMap(\.nodes) {
            for parent in child.ordinaryParentAlternatives {
                neighbours[child.id, default: []].insert(parent)
                neighbours[parent, default: []].insert(child.id)
            }
        }
        var reached: Set<CombatNodeID> = []
        var pending = [start]
        while let current = pending.popLast() {
            guard owned.contains(current), reached.insert(current).inserted else { continue }
            pending.append(contentsOf: neighbours[current, default: []].filter { owned.contains($0) })
        }
        return reached
    }
}
