import XCTest
@testable import Bookbinder

final class CombatGraphLayoutTests: XCTestCase {
    private let graph = ContentCatalog.shared.combatGraph

    func testEveryTreeLaysOutAllNodesAndEveryAuthoredEdgeExactlyOnce() {
        for tree in graph.trees {
            let layout = CombatGraphLayout(tree: tree)
            XCTAssertEqual(layout.placements.count, 24)
            XCTAssertEqual(Set(layout.placements.map(\.id)).count, 24)
            let expected = tree.disciplines.flatMap(\.nodes).reduce(0) {
                $0 + $1.sameDisciplineParents.count + $1.hybridAlternativeParents.count
            }
            XCTAssertEqual(layout.edges.count, expected)
            XCTAssertEqual(Set(layout.edges.map(\.id)).count, expected)
        }
    }

    func testFanForkUsesThreeLanesFiveDepthsAndPairedMiddleSiblings() {
        for tree in graph.trees {
            let layout = CombatGraphLayout(tree: tree)
            XCTAssertEqual(Set(layout.placements.map { $0.node.depth }), Set(1...5))
            for discipline in tree.disciplines {
                let lane = layout.placements.filter { $0.discipline.id == discipline.id }
                XCTAssertEqual(lane.filter { $0.node.depth == 1 }.map(\.siblingOffset), [0])
                for depth in 2...4 {
                    XCTAssertEqual(Set(lane.filter { $0.node.depth == depth }.map(\.siblingOffset)), [-1, 1])
                }
                XCTAssertEqual(lane.filter { $0.node.depth == 5 }.map(\.siblingOffset), [0])
            }
        }
    }

    func testSemanticTraversalIsDepthThenDisciplineAndKeepsAllNodes() {
        for tree in graph.trees {
            let layout = CombatGraphLayout(tree: tree)
            XCTAssertEqual(layout.orderedByDepth.map { $0.node.depth },
                           layout.orderedByDepth.map { $0.node.depth }.sorted())
            XCTAssertEqual(Set(layout.orderedByDepth.map(\.id)), Set(layout.placements.map(\.id)))
        }
    }

    func testHybridEdgesExactlyMatchManifestAlternatives() {
        for tree in graph.trees {
            let layout = CombatGraphLayout(tree: tree)
            let actual = Set(layout.edges.filter(\.isHybrid).map(\.id))
            let expected = Set(tree.disciplines.flatMap(\.nodes).flatMap { node in
                node.hybridAlternativeParents.map { "\($0.rawValue)>\(node.id.rawValue)" }
            })
            XCTAssertEqual(actual, expected)
        }
    }

    func testAcceptedPhoneGeometryKeepsTargetsSeparatedAndAllRoleShapesInBounds() {
        for tree in graph.trees {
            let layout = CombatGraphLayout(tree: tree)
            let pairs = layout.placements.map { ($0, layout.point(for: $0, width: 368)) }
            let points = pairs.map(\.1)
            for left in points.indices {
                for right in points.indices where right > left {
                    let dx = abs(points[left].x - points[right].x)
                    let dy = abs(points[left].y - points[right].y)
                    XCTAssertTrue(dx >= 54 || dy >= 44, "44pt targets must not overlap")
                }
            }
            for (placement, point) in pairs {
                let halfExtent: CGFloat = placement.node.role == .capstone ? 32 : 22
                XCTAssertGreaterThanOrEqual(point.x - halfExtent, 0)
                XCTAssertLessThanOrEqual(point.x + halfExtent, 368)
                XCTAssertGreaterThanOrEqual(point.y - halfExtent, 0)
                XCTAssertLessThanOrEqual(point.y + halfExtent, CombatGraphLayout.canvasHeight)
            }
        }
    }

    func testLocalRouteBudgetPurchaseAndResetHaveNoCampaignDependency() throws {
        var route = CombatGraphRouteState()
        XCTAssertEqual(route.pointBudget, 8)
        let root = try XCTUnwrap(graph.trees[0].disciplines[0].nodes.first)
        XCTAssertTrue(route.purchase(root, catalogue: graph))
        XCTAssertEqual(route.owned, [root.id])
        XCTAssertEqual(route.pointsRemaining, 7)
        route.selectPointBudget(17)
        XCTAssertTrue(route.owned.isEmpty)
        XCTAssertEqual(route.pointsRemaining, 17)
        XCTAssertTrue(route.purchase(root, catalogue: graph))
        XCTAssertEqual(route.pointsRemaining, 16)
        route.selectPointBudget(25)
        XCTAssertTrue(route.owned.isEmpty)
        XCTAssertEqual(route.pointsRemaining, 25)
        XCTAssertTrue(route.purchase(root, catalogue: graph))
        XCTAssertEqual(route.pointsRemaining, 24)
        route.selectPointBudget(8)
        XCTAssertTrue(route.owned.isEmpty)
        XCTAssertEqual(route.pointsRemaining, 8)
    }

    func testProductionTrainingUsesStableGraphPurchaseAndTruthfulOpeningHold() throws {
        let source = try String(contentsOf: URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Sources/Screens/CombatTreeView.swift"), encoding: .utf8)
        XCTAssertTrue(source.contains("CombatGraphLayout(tree: tree)"))
        XCTAssertTrue(source.contains("previewCombatNodePurchase(node.id, for: member)"))
        XCTAssertTrue(source.contains("purchaseCombatNode(quote, for: member)"))
        XCTAssertTrue(source.contains("node.depth > CombatGraphRules.openingMaximumDepth"))
        XCTAssertTrue(source.contains("PurchaseRefusal.unavailable.rawValue"))
        XCTAssertFalse(source.contains("spendPoint(in:"))
        XCTAssertFalse(source.contains("buyNext"))
    }
}
