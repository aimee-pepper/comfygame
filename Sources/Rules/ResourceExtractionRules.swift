import Foundation

enum ResourceExtractionRules {
    struct ToolQualification: Equatable, Sendable {
        var rank: Int
        var instanceID: InstanceID?
        var catalogID: ItemID
    }

    struct ResourceExtractionQuoteV1: Equatable, Sendable {
        var rulesVersion = ResourceExtractionRequirementReceiptV1.currentRulesVersion
        var worldRunID: String
        var nodePoint: GridPoint
        var interactionPosition: GridPoint
        var resourceID: ResourceID
        var nodeSnapshot: ResourceNode
        var requiredExtractionRank: Int
        var currentPartyExtractionRank: Int
        var qualifyingToolInstanceID: InstanceID?
        var inputStateHash: String
    }

    enum ResourceExtractionRefusal: Equatable, Sendable {
        case noActiveWorld
        case encounterActive
        case noDisclosedNode
        case outOfReach
        case exhausted
        case unsupportedResource
        case underEquipped(requiredRank: Int, currentRank: Int,
                           qualifyingToolInstanceID: InstanceID?)
        case stale
    }

    enum ResourceExtractionEvaluation: Equatable, Sendable {
        case available(ResourceExtractionQuoteV1)
        case refused(ResourceExtractionRefusal)
    }

    struct ResourceExtractionSuccessV1: Equatable, Sendable {
        var resourceID: ResourceID
        var primaryAmount: Int
        var secondaryResourceID: ResourceID?
        var secondaryAmount: Int
        var remainingHarvests: Int
        var exhausted: Bool
        var turnsSpent: Int = 1
    }

    enum ResourceExtractionCommitResult: Equatable, Sendable {
        case committed(ResourceExtractionSuccessV1)
        case refused(ResourceExtractionRefusal)
    }

    struct CommitOutcome: Equatable, Sendable {
        var result: ResourceExtractionCommitResult
        var events: [WorldRules.Event]
    }

    static func requirementReceipt(for resourceID: ResourceID,
                                   catalog: ContentCatalog = .shared)
        -> ResourceExtractionRequirementReceiptV1? {
        guard let resource = catalog.resource(resourceID) else { return nil }
        return .init(resourceID: resourceID, disposition: resource.extractionDisposition,
                     requiredExtractionRank: resource.requiredExtractionRank)
    }

    /// Geometry only. Equipment, disclosure, enemies and route reachability deliberately do not enter.
    static func legalInteractionPositions(nodePoint: GridPoint, map: WorldMap) -> [GridPoint] {
        guard map.contains(nodePoint), case .node = map[nodePoint].content else { return [] }
        return ([nodePoint] + map.neighbours(of: nodePoint))
            .filter { map[$0].isPassable }
            .sorted { map.index(of: $0) < map.index(of: $1) }
    }

    static func bestTool(in state: GameState) -> ToolQualification? {
        let members: [PartyMember] = [.binder] + state.base.activeParty.compactMap { id in
            state.base.rosterIndex(for: id) == nil ? nil : .member(id)
        }
        return members.compactMap { member in
            state.base.worn(.tool, by: member).flatMap(qualification(for:))
        }.max {
            if $0.rank != $1.rank { return $0.rank < $1.rank }
            let lhs = $0.instanceID?.rawValue ?? 0
            let rhs = $1.instanceID?.rawValue ?? 0
            if lhs != rhs { return lhs > rhs }
            return $0.catalogID.rawValue > $1.catalogID.rawValue
        }
    }

    static func partyExtractionRank(in state: GameState) -> Int {
        bestTool(in: state)?.rank ?? 0
    }

    static func evaluate(in state: GameState) -> ResourceExtractionEvaluation {
        guard let run = state.worlds.activeRun else { return .refused(.noActiveWorld) }
        guard run.activeEncounter == nil else { return .refused(.encounterActive) }

        guard let target = selectedDisclosedNode(in: state)?.0 else {
            return .refused(.noDisclosedNode)
        }
        return evaluate(nodePoint: target, in: state)
    }

    static func selectedDisclosedNode(in state: GameState) -> (GridPoint, ResourceNode)? {
        guard let run = state.worlds.activeRun else { return nil }
        let candidates = disclosedCandidatePoints(in: run).compactMap { point -> (GridPoint, ResourceNode)? in
            guard case .node(let node) = run.map[point].content else { return nil }
            return (point, node)
        }
        // Target ownership is shared by context, evaluate and commit staging: a live node under the
        // party wins, otherwise the first live cardinal neighbour wins. Only when no live target
        // exists does an exhausted node become the selected refusal target.
        return candidates.first(where: { !$0.1.isExhausted }) ?? candidates.first
    }

    static func evaluate(nodePoint: GridPoint, in state: GameState)
        -> ResourceExtractionEvaluation {
        guard let run = state.worlds.activeRun else { return .refused(.noActiveWorld) }
        guard run.activeEncounter == nil else { return .refused(.encounterActive) }
        guard run.map.contains(nodePoint), run.map[nodePoint].isRevealed,
              case .node(let node) = run.map[nodePoint].content else {
            return .refused(.noDisclosedNode)
        }
        guard !node.isExhausted else { return .refused(.exhausted) }
        guard legalInteractionPositions(nodePoint: nodePoint, map: run.map)
            .contains(run.playerPosition) else { return .refused(.outOfReach) }
        guard let requirement = validatedRequirement(of: node) else {
            return .refused(.unsupportedResource)
        }
        let tool = bestTool(in: state)
        let currentRank = tool?.rank ?? 0
        let requiredRank = requirement.requiredExtractionRank ?? 0
        guard currentRank >= requiredRank else {
            return .refused(.underEquipped(requiredRank: requiredRank, currentRank: currentRank,
                                           qualifyingToolInstanceID: tool?.instanceID))
        }
        let worldRunID = runID(run)
        let hash = inputHash(worldRunID: worldRunID, nodePoint: nodePoint,
                             interactionPosition: run.playerPosition, node: node,
                             currentRank: currentRank, tool: tool)
        return .available(.init(
            worldRunID: worldRunID, nodePoint: nodePoint,
            interactionPosition: run.playerPosition, resourceID: node.resource,
            nodeSnapshot: node, requiredExtractionRank: requiredRank,
            currentPartyExtractionRank: currentRank,
            qualifyingToolInstanceID: tool?.instanceID, inputStateHash: hash))
    }

    static func commit(_ quote: ResourceExtractionQuoteV1, in state: inout GameState)
        -> CommitOutcome {
        guard let run = state.worlds.activeRun else {
            return refusal(.noActiveWorld)
        }
        guard run.activeEncounter == nil else { return refusal(.encounterActive) }
        guard quote.rulesVersion == ResourceExtractionRequirementReceiptV1.currentRulesVersion,
              quote.worldRunID == runID(run), quote.interactionPosition == run.playerPosition,
              run.map.contains(quote.nodePoint), run.map[quote.nodePoint].isRevealed else {
            return refusal(.stale)
        }
        guard case .node(let currentNode) = run.map[quote.nodePoint].content else {
            return refusal(.noDisclosedNode)
        }
        guard !currentNode.isExhausted else { return refusal(.exhausted) }
        guard legalInteractionPositions(nodePoint: quote.nodePoint, map: run.map)
            .contains(run.playerPosition) else { return refusal(.outOfReach) }
        guard validatedRequirement(of: currentNode) != nil else { return refusal(.unsupportedResource) }
        guard currentNode == quote.nodeSnapshot,
              currentNode.resource == quote.resourceID else { return refusal(.stale) }
        let tool = bestTool(in: state)
        let currentRank = tool?.rank ?? 0
        let currentHash = inputHash(worldRunID: quote.worldRunID, nodePoint: quote.nodePoint,
                                    interactionPosition: run.playerPosition, node: currentNode,
                                    currentRank: currentRank, tool: tool)
        guard currentHash == quote.inputStateHash,
              currentRank == quote.currentPartyExtractionRank,
              tool?.instanceID == quote.qualifyingToolInstanceID else { return refusal(.stale) }
        guard currentRank >= quote.requiredExtractionRank else { return refusal(.stale) }

        var candidate = state
        guard var candidateRun = candidate.worlds.activeRun,
              case .node(var node) = candidateRun.map[quote.nodePoint].content else {
            return refusal(.stale)
        }
        node.remainingHarvests -= 1
        let fieldcraftBonus = candidate.base.station(Stations.wayfarersTable).isUnlocked
            && node.extractionRequirement?.disposition == .floraPrimary
            ? Tuning.Economy.fieldcraftOrganicYieldBonus : 0
        let primary = node.yieldPerHarvest + fieldcraftBonus
        candidateRun.satchel.add(primary, of: node.resource)
        candidate.reality.discovery.recordResource(node.resource, runIndex: candidateRun.runIndex)
        let secondaryAmount = node.secondaryResource == nil ? 0 : max(0, node.secondaryYieldPerHarvest)
        if let secondary = node.secondaryResource, secondaryAmount > 0 {
            candidateRun.satchel.add(secondaryAmount, of: secondary)
            candidate.reality.discovery.recordResource(secondary, runIndex: candidateRun.runIndex)
        }
        // Exhaustion remains a node state. Presentation can distinguish worked-out ground from absence.
        candidateRun.map[quote.nodePoint].content = .node(node)
        candidate.worlds.activeRun = candidateRun

        var events: [WorldRules.Event] = [
            .harvested(node.resource, amount: primary, exhausted: node.isExhausted)
        ]
        if let secondary = node.secondaryResource, secondaryAmount > 0 {
            events.append(.harvested(secondary, amount: secondaryAmount,
                                     exhausted: node.isExhausted))
        }
        events.append(contentsOf: WorldRules.advanceTurn(in: &candidate))
        state = candidate
        return .init(result: .committed(.init(
            resourceID: node.resource, primaryAmount: primary,
            secondaryResourceID: node.secondaryResource, secondaryAmount: secondaryAmount,
            remainingHarvests: node.remainingHarvests, exhausted: node.isExhausted)), events: events)
    }

    static func playerCopy(for refusal: ResourceExtractionRefusal,
                           resourceName: String? = nil,
                           vanishedAtCommit: Bool = false) -> String {
        switch refusal {
        case .noActiveWorld: "There is nothing to use here."
        case .noDisclosedNode: vanishedAtCommit
            ? "Nothing here to harvest." : "There is nothing to use here."
        case .encounterActive: "Finish the encounter first."
        case .outOfReach: "Move onto or beside this resource to extract it."
        case .exhausted: "This resource is depleted."
        case .unsupportedResource: "This resource cannot be extracted here."
        case .underEquipped(let required, let current, _):
            "\(resourceName ?? "This resource") needs Extraction \(required). Your party has Extraction \(current)."
        case .stale: "The resource or equipped Field Pick changed. Review it and try again."
        }
    }

    private static func qualification(for piece: EquippedPiece) -> ToolQualification? {
        guard piece.frozenSlot == .tool,
              let profile = piece.gearProfile,
              let capability = profile.gameplayFacts?.toolCapability,
              capability.validates() else { return nil }
        return .init(rank: capability.rank, instanceID: profile.stableInstanceID,
                     catalogID: piece.catalogID)
    }

    static func validatedRequirement(of node: ResourceNode)
        -> ResourceExtractionRequirementReceiptV1? {
        guard let receipt = node.extractionRequirement,
              receipt.rulesVersion == ResourceExtractionRequirementReceiptV1.currentRulesVersion,
              receipt.resourceID == node.resource,
              ContentCatalog.shared.resource(node.resource) != nil else { return nil }
        switch receipt.disposition {
        case .mineralNode:
            guard let rank = receipt.requiredExtractionRank, (0...4).contains(rank) else { return nil }
        case .floraPrimary:
            guard receipt.requiredExtractionRank == nil else { return nil }
        case .floraSecondary, .directPickup, .realityAward, .creatureMaterialOnly:
            return nil
        }
        return receipt
    }

    private static func disclosedCandidatePoints(in run: WorldRun) -> [GridPoint] {
        let under = run.playerPosition
        let adjacent = run.map.neighbours(of: under)
            .sorted { run.map.index(of: $0) < run.map.index(of: $1) }
        return ([under] + adjacent).filter { point in
            run.map[point].isRevealed && {
                if case .node = run.map[point].content { return true }
                return false
            }()
        }
    }

    private static func runID(_ run: WorldRun) -> String { "\(run.runIndex):\(run.mapSeed)" }

    private static func inputHash(worldRunID: String, nodePoint: GridPoint,
                                  interactionPosition: GridPoint, node: ResourceNode,
                                  currentRank: Int, tool: ToolQualification?) -> String {
        let receipt = node.extractionRequirement
        var fields: [String] = []
        fields.append(worldRunID)
        fields.append("\(nodePoint.x),\(nodePoint.y)")
        fields.append("\(interactionPosition.x),\(interactionPosition.y)")
        fields.append(node.resource.rawValue)
        fields.append(String(node.remainingHarvests))
        fields.append(String(node.generatedHarvests ?? -1))
        fields.append(String(node.yieldPerHarvest))
        fields.append(node.secondaryResource?.rawValue ?? "-")
        fields.append(String(node.secondaryYieldPerHarvest))
        fields.append(receipt?.rulesVersion ?? "-")
        fields.append(receipt?.disposition.rawValue ?? "-")
        fields.append(String(receipt?.requiredExtractionRank ?? -1))
        fields.append(String(currentRank))
        fields.append(String(tool?.instanceID?.rawValue ?? 0))
        fields.append(tool?.catalogID.rawValue ?? "-")
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in fields.map { "\($0.utf8.count):\($0)" }.joined().utf8 {
            hash ^= UInt64(byte); hash = hash &* 0x100000001b3
        }
        return String(hash, radix: 16)
    }

    private static func refusal(_ refusal: ResourceExtractionRefusal) -> CommitOutcome {
        .init(result: .refused(refusal), events: [])
    }
}
