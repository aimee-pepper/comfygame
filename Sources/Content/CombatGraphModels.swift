import Foundation

/// Stable semantic ownership for the v2 combat graph. Unlike the retired branch-depth key, this
/// identity survives catalogue reorder and graph presentation changes.
struct CombatNodeID: StringIdentifier, Identifiable {
    var rawValue: String
    init(rawValue: String) { self.rawValue = rawValue }
    var id: String { rawValue }
}

struct StableChoiceID: StringIdentifier {
    var rawValue: String
    init(rawValue: String) { self.rawValue = rawValue }
}

struct CombatDisciplineID: StringIdentifier {
    var rawValue: String
    init(rawValue: String) { self.rawValue = rawValue }
}

enum CombatGraphRole: String, Codable, CaseIterable, Sendable {
    case root, fundamentalA, fundamentalB, developmentA, developmentB, masteryA, masteryB, capstone
}

struct CombatGraphNodeDef: Codable, Equatable, Identifiable, Sendable {
    var id: CombatNodeID
    var slug: String
    var legacyBranchID: CombatBranchID
    var formerIndex: Int
    var role: CombatGraphRole
    var depth: Int
    var name: String
    var blurb: String
    /// Decode/migration parity only. Known stale legacy meanings must not become v2 authority.
    var legacyEffect: CombatNodeEffect
    var legacyTechniqueID: SkillID?
    var sameDisciplineParents: [CombatNodeID]
    var hybridAlternativeParents: [CombatNodeID]

    var ordinaryParentAlternatives: [CombatNodeID] {
        sameDisciplineParents + hybridAlternativeParents
    }
}

struct CombatDisciplineDef: Codable, Equatable, Identifiable, Sendable {
    var id: CombatDisciplineID
    var legacyBranchID: CombatBranchID
    var name: String
    var icon: String
    var blurb: String
    var nodes: [CombatGraphNodeDef]
}

struct CombatGraphTreeDef: Codable, Equatable, Identifiable, Sendable {
    var id: CombatTreeID
    var name: String
    var icon: String
    var blurb: String
    var disciplines: [CombatDisciplineDef]
}

struct CombatCapstoneGate: Codable, Equatable, Sendable {
    var minimumPriorNodesInTree: Int
    var minimumNodesInCapstoneDisciplineIncludingCapstone: Int
    var requiredOwnedRolesInCapstoneDiscipline: [String]
    var priorNodesMustFormOneConnectedPrerequisiteSubgraph: Bool
    var connectivityTreatsOwnedEdgesAsUndirected: Bool
}

struct CombatGraphCatalogue: Codable, Equatable, Sendable {
    var schemaVersion: Int
    var graphVersion: Int
    var capstoneGate: CombatCapstoneGate
    var trees: [CombatGraphTreeDef]

    var disciplines: [CombatDisciplineDef] { trees.flatMap(\.disciplines) }
    var nodes: [CombatGraphNodeDef] { disciplines.flatMap(\.nodes) }

    func node(_ id: CombatNodeID) -> CombatGraphNodeDef? { nodes.first { $0.id == id } }
    func tree(containing id: CombatNodeID) -> CombatGraphTreeDef? {
        trees.first { tree in tree.disciplines.contains { $0.nodes.contains { $0.id == id } } }
    }
    func discipline(containing id: CombatNodeID) -> CombatDisciplineDef? {
        disciplines.first { $0.nodes.contains { $0.id == id } }
    }
}
