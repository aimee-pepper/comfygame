import Foundation

/// Pure prerequisite and legacy-mapping rules for CombatGraphVersion 2.
///
/// Canonical depth-1–3 purchase, prerequisite and legacy-mapping authority.
enum CombatGraphRules {
    static let graphVersion = 2
    static let openingMaximumDepth = 3
    static let firstCompleteRouteNodeIDs: Set<CombatNodeID> = [
        "combat.defense.fortitude.thick_hide",
        "combat.defense.fortitude.iron_skin",
        "combat.defense.fortitude.brace",
        "combat.defense.fortitude.constitution",
        "combat.defense.fortitude.endurance",
        "combat.defense.fortitude.ward",
        "combat.defense.fortitude.unyielding",
        "combat.defense.fortitude.immovable",
    ]
    static let protectionCompleteRouteNodeIDs: Set<CombatNodeID> = [
        "combat.defense.protection.bulwark",
        "combat.defense.protection.watchful",
        "combat.defense.protection.draw_off",
        "combat.defense.protection.cover",
        "combat.defense.protection.shieldwall",
        "combat.defense.protection.interpose",
        "combat.defense.protection.rally",
        "combat.defense.protection.guardian",
    ]
    static let evasionCompleteRouteNodeIDs: Set<CombatNodeID> = [
        "combat.defense.evasion.footwork",
        "combat.defense.evasion.light_frame",
        "combat.defense.evasion.sidestep",
        "combat.defense.evasion.slippery",
        "combat.defense.evasion.fall_back",
        "combat.defense.evasion.feint",
        "combat.defense.evasion.untouchable",
        "combat.defense.evasion.ghost",
    ]
    static let precisionCompleteRouteNodeIDs: Set<CombatNodeID> = [
        "combat.offense.precision.keen_eye",
        "combat.offense.precision.weak_point",
        "combat.offense.precision.pry",
        "combat.offense.precision.steady_hand",
        "combat.offense.precision.exploit",
        "combat.offense.precision.finish",
        "combat.offense.precision.anatomy",
        "combat.offense.precision.killing_stroke",
    ]

    enum PurchaseRefusal: Error, Equatable, Sendable {
        case unavailable, alreadyOwned, missingPoint, illegalParent, invalidChoice
        case encounterActive, ineligibleMember, stale

        var playerCopy: String {
            switch self {
            case .unavailable: "This development is not implemented yet."
            case .alreadyOwned: "Already learned."
            case .missingPoint: "No combat point is available."
            case .illegalParent: "Learn one of this development’s exact prerequisites first."
            case .invalidChoice: "That selection is not available for this development."
            case .encounterActive: "Combat practice cannot change during an encounter."
            case .ineligibleMember: "This party member cannot learn human combat practice."
            case .stale: "This character changed. Review the development and try again."
            }
        }
    }

    struct PurchaseQuote: Equatable, Sendable {
        var nodeID: CombatNodeID
        var choice: StableChoiceID?
        var ownedBefore: Set<CombatNodeID>
        var pointsBefore: Int
        var graphVersion: Int
        var characterRevision: UInt64
    }

    enum PurchaseResult: Equatable, Sendable {
        case committed(CombatNodeID)
        case refused(PurchaseRefusal)
    }

    struct LegacyReconciliation: Equatable, Sendable {
        var owned: Set<CombatNodeID>
        var refundedPoints: Int
    }

    static func implementedOpeningNodeIDs(in catalogue: CombatGraphCatalogue) -> Set<CombatNodeID> {
        Set(catalogue.nodes.filter { $0.depth <= openingMaximumDepth }.map(\.id))
    }

    static func implementedNodeIDs(in catalogue: CombatGraphCatalogue) -> Set<CombatNodeID> {
        implementedOpeningNodeIDs(in: catalogue)
            .union(firstCompleteRouteNodeIDs)
            .union(protectionCompleteRouteNodeIDs)
            .union(evasionCompleteRouteNodeIDs)
            .union(precisionCompleteRouteNodeIDs)
    }

    static func isImplemented(_ node: CombatGraphNodeDef) -> Bool {
        node.depth <= openingMaximumDepth
            || firstCompleteRouteNodeIDs.contains(node.id)
            || protectionCompleteRouteNodeIDs.contains(node.id)
            || evasionCompleteRouteNodeIDs.contains(node.id)
            || precisionCompleteRouteNodeIDs.contains(node.id)
    }

    static func migratedLegacyNodes(branchDepth: [CombatBranchID: Int],
                                    catalogue: CombatGraphCatalogue) -> Set<CombatNodeID> {
        Set(catalogue.disciplines.flatMap { discipline in
            let depth = min(max(0, branchDepth[discipline.legacyBranchID] ?? 0), discipline.nodes.count)
            return discipline.nodes.prefix(depth).map(\.id)
        })
    }

    static func reconcileLegacy(branchDepth: [CombatBranchID: Int],
                                catalogue: CombatGraphCatalogue) -> LegacyReconciliation {
        let owned = migratedLegacyNodes(branchDepth: branchDepth, catalogue: catalogue)
        let claimed = branchDepth.values.reduce(0) { $0 + max(0, $1) }
        return LegacyReconciliation(owned: owned, refundedPoints: max(0, claimed - owned.count))
    }

    static func ownedNodes(for character: CharacterState,
                           catalogue: CombatGraphCatalogue) -> Set<CombatNodeID> {
        character.ownedCombatNodeIDs
    }

    static func unspentPoints(for character: CharacterState,
                              catalogue: CombatGraphCatalogue) -> Int {
        character.unspentCombatPoints
    }

    static func previewPurchase(_ nodeID: CombatNodeID, choice: StableChoiceID? = nil,
                                for character: CharacterState,
                                catalogue: CombatGraphCatalogue)
        -> Result<PurchaseQuote, PurchaseRefusal> {
        guard let node = catalogue.node(nodeID), isImplemented(node) else {
            return .failure(.unavailable)
        }
        let owned = ownedNodes(for: character, catalogue: catalogue)
        guard !owned.contains(nodeID) else { return .failure(.alreadyOwned) }
        guard unspentPoints(for: character, catalogue: catalogue) > 0 else {
            return .failure(.missingPoint)
        }
        guard canPurchase(node, owned: owned, catalogue: catalogue) else {
            return .failure(.illegalParent)
        }
        if node.purchaseChoices.isEmpty {
            guard choice == nil else { return .failure(.invalidChoice) }
        } else {
            guard let choice, node.purchaseChoices.contains(choice) else {
                return .failure(.invalidChoice)
            }
        }
        return .success(PurchaseQuote(nodeID: nodeID, choice: choice,
                                      ownedBefore: owned,
                                      pointsBefore: character.unspentCombatPoints,
                                      graphVersion: catalogue.graphVersion,
                                      characterRevision: revision(of: character)))
    }

    @discardableResult
    static func commit(_ quote: PurchaseQuote, for character: inout CharacterState,
                       catalogue: CombatGraphCatalogue) -> PurchaseResult {
        guard case .success(let current) = previewPurchase(quote.nodeID, choice: quote.choice,
                                                           for: character, catalogue: catalogue),
              current == quote,
              quote.graphVersion == graphVersion else { return .refused(.stale) }
        var owned = current.ownedBefore
        owned.insert(current.nodeID)
        character.ownedCombatNodeIDs = owned
        character.unspentCombatPoints -= 1
        character.combatNodeChoices = character.combatNodeChoices.filter { owned.contains($0.key) }
        if let choice = current.choice { character.combatNodeChoices[current.nodeID] = choice }
        return .committed(current.nodeID)
    }

    static func revision(of character: CharacterState) -> UInt64 {
        var value: UInt64 = 14_695_981_039_346_656_037
        let fields = character.ownedCombatNodeIDs.map(\.rawValue).sorted()
            + character.combatNodeChoices.sorted { $0.key.rawValue < $1.key.rawValue }
                .flatMap { [$0.key.rawValue, $0.value.rawValue] }
            + [String(character.unspentCombatPoints)]
        for byte in fields.joined(separator: "|").utf8 {
            value = (value ^ UInt64(byte)) &* 1_099_511_628_211
        }
        return value
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
        catalogue.nodes.filter { isImplemented($0)
            && canPurchase($0, owned: owned, catalogue: catalogue) }
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
