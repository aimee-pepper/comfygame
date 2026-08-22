import XCTest
@testable import Bookbinder

final class ResearchGraphLayoutTests: XCTestCase {
    func testCanonicalProgressionRequirementCopyCoversNounsRelationshipsAndPunctuation() {
        let p = ProgressionRequirementPresentation.self
        XCTAssertEqual(p.requirement(noun: .upgrade, relationship: .all,
                                     requiredIDs: [], resolvedNames: []),
                       "Requires no earlier Upgrade.")
        XCTAssertEqual(p.requirement(noun: .skill, relationship: .any,
                                     requiredIDs: [], resolvedNames: []),
                       "Requires no earlier Skill.")
        XCTAssertEqual(p.requirement(noun: .upgrade, relationship: .all,
                                     requiredIDs: ["a"], resolvedNames: ["A"]), "Requires A.")
        XCTAssertEqual(p.requirement(noun: .skill, relationship: .any,
                                     requiredIDs: ["a"], resolvedNames: ["A"]), "Requires A.")
        XCTAssertEqual(p.requirement(noun: .upgrade, relationship: .all,
                                     requiredIDs: ["a", "b"], resolvedNames: ["A", "B"]),
                       "Requires A and B.")
        XCTAssertEqual(p.requirement(noun: .skill, relationship: .any,
                                     requiredIDs: ["a", "b"], resolvedNames: ["A", "B"]),
                       "Requires any one of: A or B.")
        XCTAssertEqual(p.requirement(noun: .upgrade, relationship: .all,
                                     requiredIDs: ["a", "b", "c"], resolvedNames: ["A", "B", "C"]),
                       "Requires A, B, and C.")
        XCTAssertEqual(p.requirement(noun: .skill, relationship: .any,
                                     requiredIDs: ["a", "b", "c"], resolvedNames: ["A", "B", "C"]),
                       "Requires any one of: A, B, or C.")
        XCTAssertEqual(p.requirement(noun: .upgrade, relationship: .any,
                                     requiredIDs: ["missing"], resolvedNames: []),
                       "Required Upgrade information is unavailable.")
        XCTAssertEqual(p.requirement(noun: .skill, relationship: .all,
                                     requiredIDs: ["missing"], resolvedNames: [""]),
                       "Required Skill information is unavailable.")
        XCTAssertEqual(p.skillsLearned(0), "0 Skills learned")
        XCTAssertEqual(p.skillsLearned(1), "1 Skill learned")
        XCTAssertEqual(p.skillsLearned(2), "2 Skills learned")
        XCTAssertEqual(p.pointsReady(0), "0 points ready")
        XCTAssertEqual(p.pointsReady(1), "1 point ready")
        XCTAssertEqual(p.pointsReady(2), "2 points ready")
    }

    @MainActor
    func testEveryAuthoredResearchRequirementResolvesAndMultiRequirementMeansAll() throws {
        let nodes = ContentCatalog.shared.researchNodes
        let byID = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) })
        XCTAssertTrue(nodes.flatMap(\.requires).allSatisfy { byID[$0] != nil })
        let multi = try XCTUnwrap(ContentCatalog.shared.researchNode("bargain_peace"))
        XCTAssertEqual(multi.requires.count, 2)
        let names = multi.requires.compactMap { byID[$0]?.name }
        XCTAssertEqual(ProgressionRequirementPresentation.requirement(
            noun: .upgrade, relationship: .all, requiredIDs: multi.requires.map(\.rawValue),
            resolvedNames: names),
            "Requires \(names.dropLast().joined(separator: ", ")), and \(names.last!).")
        let store = GameStore(io: .temporary(name: "multi-upgrade-\(UUID().uuidString)"))
        store.mutate("complete all but one earlier Upgrade") {
            $0.base.completedResearch.formUnion(multi.requires.dropLast())
        }
        XCTAssertFalse(store.isAvailable(multi))
        XCTAssertTrue(store.missingPrerequisites(for: multi).contains(names.last!))
        store.mutate("complete every earlier Upgrade") {
            $0.base.completedResearch.insert(multi.requires.last!)
        }
        XCTAssertTrue(store.isAvailable(multi), store.missingPrerequisites(for: multi).joined(separator: ", "))
        XCTAssertTrue(EconomyRules.isAvailable(multi, in: store.state))
    }

    func testEveryResearchEdgeRunsFromEarlierVisualRow() {
        for branch in ContentCatalog.shared.branchesInOrder {
            let nodes = ContentCatalog.shared.nodes(in: branch.id)
            let layout = ResearchGraphLayout(nodes: nodes)
            let placement = Dictionary(uniqueKeysWithValues: layout.placements.map { ($0.node.id, $0) })

            XCTAssertTrue(layout.placements.allSatisfy { (0...2).contains($0.column) })
            XCTAssertEqual(Set(layout.placements.map(\.node.id)).count, nodes.count)
            for child in nodes {
                for parentID in child.requires where placement[parentID] != nil {
                    XCTAssertLessThan(placement[parentID]!.row, placement[child.id]!.row,
                                      "\(parentID) must render above \(child.id)")
                }
            }
        }
    }

    func testCatalogueShuffleDoesNotMoveResearchNodes() {
        for branch in ContentCatalog.shared.branchesInOrder {
            let nodes = ContentCatalog.shared.nodes(in: branch.id)
            let forward = ResearchGraphLayout(nodes: nodes).placements
            let reversed = ResearchGraphLayout(nodes: Array(nodes.reversed())).placements
            let a = Dictionary(uniqueKeysWithValues: forward.map { ($0.node.id, [$0.rank, $0.row, $0.column]) })
            let b = Dictionary(uniqueKeysWithValues: reversed.map { ($0.node.id, [$0.rank, $0.row, $0.column]) })
            XCTAssertEqual(a, b)
        }
    }
}
