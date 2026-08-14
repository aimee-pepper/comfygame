import XCTest
@testable import Bookbinder

final class ResearchGraphLayoutTests: XCTestCase {
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
