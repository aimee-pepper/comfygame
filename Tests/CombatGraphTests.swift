import XCTest
@testable import Bookbinder

final class CombatGraphTests: XCTestCase {
    private var graph: CombatGraphCatalogue { ContentCatalog.shared.combatGraph }

    func testGeneratedAuthorityHasExactClosedShapeAndStableIdentity() {
        XCTAssertEqual(graph.schemaVersion, 2)
        XCTAssertEqual(graph.graphVersion, 2)
        XCTAssertEqual(graph.trees.count, 3)
        XCTAssertEqual(graph.disciplines.count, 9)
        XCTAssertEqual(graph.nodes.count, 72)
        XCTAssertEqual(Set(graph.nodes.map(\.id)).count, 72)
        XCTAssertEqual(graph.nodes.filter { $0.role == .capstone }.count, 9)
        XCTAssertTrue(graph.nodes.allSatisfy {
            $0.id.rawValue == "combat.\(graph.tree(containing: $0.id)!.id.rawValue)."
                + "\(graph.discipline(containing: $0.id)!.id.rawValue).\($0.slug)"
        })
    }

    func testSchemaTwoOwnsExactTechniqueAndEffectCoverage() {
        XCTAssertEqual(graph.nodes.filter { $0.techniqueID != nil }.count, 20)
        XCTAssertEqual(graph.nodes.filter { $0.techniqueID == nil }.count, 52)
        XCTAssertTrue(graph.nodes.allSatisfy { !$0.effectCopy.isEmpty })
        XCTAssertEqual(graph.node(id("offense", "swiftness", "blur"))?.techniqueID, "blur")
        XCTAssertEqual(graph.node(id("craft", "emanation", "emanation_strike"))?.techniqueID,
                       "emanation_strike")
        XCTAssertEqual(graph.node(id("craft", "emanation", "quench"))?.techniqueID, "quench")
        XCTAssertNil(graph.node(id("offense", "force", "heavy_hand"))?.techniqueID)
    }

    func testEveryLegacyDepthMapsToExactFormerPrefixesWithoutLosingPoints() {
        for discipline in graph.disciplines {
            for depth in 0...8 {
                let migrated = CombatGraphRules.migratedLegacyNodes(
                    branchDepth: [discipline.legacyBranchID: depth], catalogue: graph)
                XCTAssertEqual(migrated, Set(discipline.nodes.prefix(depth).map(\.id)),
                               "\(discipline.id) depth \(depth)")
                XCTAssertEqual(migrated.count, depth)
            }
        }
        let emanation = graph.disciplines.first { $0.id == "emanation" }!
        XCTAssertEqual(emanation.legacyBranchID, "kindling")
    }

    func testEveryRootExposesBothFundamentalsAndAllParentsExistInTree() {
        for tree in graph.trees {
            let treeIDs = Set(tree.disciplines.flatMap(\.nodes).map(\.id))
            for discipline in tree.disciplines {
                let root = discipline.nodes.first { $0.role == .root }!
                let children = discipline.nodes.filter { $0.sameDisciplineParents.contains(root.id) }
                XCTAssertEqual(Set(children.map(\.role)), [.fundamentalA, .fundamentalB])
            }
            for node in tree.disciplines.flatMap(\.nodes) {
                XCTAssertTrue(node.ordinaryParentAlternatives.allSatisfy(treeIDs.contains), node.id.rawValue)
            }
        }
    }

    func testEveryTreeHasAtLeastThirtyDistinctEightPointCapstoneRoutes() {
        for tree in graph.trees {
            var states: Set<Set<CombatNodeID>> = [[]]
            for _ in 0..<7 {
                var next: Set<Set<CombatNodeID>> = []
                for owned in states {
                    for node in tree.disciplines.flatMap(\.nodes)
                    where node.role != .capstone
                        && CombatGraphRules.canPurchase(node, owned: owned, catalogue: graph) {
                        next.insert(owned.union([node.id]))
                    }
                }
                states = next
            }
            var capstoneRoutes: Set<Set<CombatNodeID>> = []
            for owned in states {
                for capstone in tree.disciplines.flatMap(\.nodes).filter({ $0.role == .capstone })
                where CombatGraphRules.canPurchase(capstone, owned: owned, catalogue: graph) {
                    capstoneRoutes.insert(owned.union([capstone.id]))
                }
            }
            XCTAssertGreaterThanOrEqual(capstoneRoutes.count, 30, tree.id.rawValue)
            for capstone in tree.disciplines.flatMap(\.nodes).filter({ $0.role == .capstone }) {
                XCTAssertTrue(capstoneRoutes.contains(where: { $0.contains(capstone.id) }), capstone.id.rawValue)
            }
        }
    }

    func testFullDisciplineRoutesReachCapstonesAtExactlyPointEightNeverEarlier() {
        for discipline in graph.disciplines {
            let route = discipline.nodes.filter { $0.role != .capstone }.map(\.id)
            XCTAssertEqual(route.count, 7)
            XCTAssertTrue(CombatGraphRules.isLegalPurchaseOrder(route, catalogue: graph), discipline.id.rawValue)
            let capstone = discipline.nodes.first { $0.role == .capstone }!
            XCTAssertFalse(CombatGraphRules.canPurchase(capstone,
                                                        owned: Set(route.dropLast()), catalogue: graph))
            XCTAssertTrue(CombatGraphRules.canPurchase(capstone,
                                                       owned: Set(route), catalogue: graph))
        }
    }

    func testSixAuthoredExampleRoutesAreLegalAndEndInCapstone() {
        let routes: [[CombatNodeID]] = [
            ids("offense", [("force", "heavy_hand"), ("force", "follow_through"), ("precision", "keen_eye"), ("precision", "pry"), ("force", "bracing_stance"), ("precision", "exploit"), ("force", "shatter"), ("force", "breaking_blow")]),
            ids("offense", [("precision", "keen_eye"), ("precision", "pry"), ("swiftness", "quick_step"), ("swiftness", "quicken"), ("precision", "exploit"), ("swiftness", "flurry"), ("precision", "finish"), ("precision", "killing_stroke")]),
            ids("defense", [("fortitude", "thick_hide"), ("fortitude", "brace"), ("fortitude", "endurance"), ("fortitude", "unyielding"), ("protection", "bulwark"), ("protection", "watchful"), ("protection", "cover"), ("fortitude", "immovable")]),
            ids("defense", [("evasion", "footwork"), ("evasion", "light_frame"), ("evasion", "slippery"), ("evasion", "feint"), ("protection", "bulwark"), ("protection", "draw_off"), ("protection", "shieldwall"), ("evasion", "ghost")]),
            ids("craft", [("venom", "tainted_edge"), ("venom", "apothecary_s_hand"), ("venom", "virulence"), ("emanation", "sparkhand"), ("emanation", "emanation_strike"), ("emanation", "snuff"), ("venom", "corrode"), ("venom", "blight")]),
            ids("craft", [("shadow", "quiet_step"), ("shadow", "conceal"), ("shadow", "ambush"), ("shadow", "shadowed"), ("emanation", "sparkhand"), ("emanation", "insulation"), ("emanation", "attunement"), ("shadow", "unseen")]),
        ]
        for route in routes {
            XCTAssertTrue(CombatGraphRules.isLegalPurchaseOrder(route, catalogue: graph),
                          route.map(\.rawValue).joined(separator: " → "))
            XCTAssertEqual(graph.node(route.last!)?.role, .capstone)
        }
    }

    func testDisconnectedGrandfatheredNodeNeitherPoisonsNorSatisfiesCapstoneGate() {
        let valid = ids("offense", [
            ("force", "heavy_hand"), ("force", "follow_through"),
            ("precision", "keen_eye"), ("precision", "pry"),
            ("force", "bracing_stance"), ("precision", "exploit"), ("force", "shatter"),
        ])
        let capstone = graph.node(id("offense", "force", "breaking_blow"))!
        let disconnected = id("offense", "force", "momentum")
        XCTAssertTrue(CombatGraphRules.canPurchase(capstone,
                                                   owned: Set(valid + [disconnected]), catalogue: graph))

        let withoutConnectedMastery = Array(valid.dropLast()) + [disconnected]
        XCTAssertFalse(CombatGraphRules.canPurchase(capstone,
                                                    owned: Set(withoutConnectedMastery), catalogue: graph))
    }

    private func id(_ tree: String, _ discipline: String, _ slug: String) -> CombatNodeID {
        CombatNodeID(rawValue: "combat.\(tree).\(discipline).\(slug)")
    }

    private func ids(_ tree: String, _ entries: [(String, String)]) -> [CombatNodeID] {
        entries.map { id(tree, $0.0, $0.1) }
    }
}
