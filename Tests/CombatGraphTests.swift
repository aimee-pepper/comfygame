import XCTest
@testable import Bookbinder

func legacyCombatNodes(_ depths: [CombatBranchID: Int]) -> Set<CombatNodeID> {
    CombatGraphRules.migratedLegacyNodes(branchDepth: depths,
                                         catalogue: ContentCatalog.shared.combatGraph)
}

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

    func testEveryCombatRequirementResolvesAndHybridCopyPreservesAnyOneSemantics() throws {
        XCTAssertTrue(graph.nodes.flatMap(\.ordinaryParentAlternatives)
            .allSatisfy { graph.node($0) != nil })
        let hybrid = try XCTUnwrap(graph.nodes.first { $0.ordinaryParentAlternatives.count > 1 })
        let names = hybrid.ordinaryParentAlternatives.compactMap { graph.node($0)?.name }
        XCTAssertEqual(ProgressionRequirementPresentation.requirement(
            noun: .skill, relationship: .any,
            requiredIDs: hybrid.ordinaryParentAlternatives.map(\.rawValue), resolvedNames: names),
            names.count == 2
                ? "Requires any one of: \(names[0]) or \(names[1])."
                : "Requires any one of: \(names.dropLast().joined(separator: ", ")), or \(names.last!).")
        for parent in hybrid.ordinaryParentAlternatives {
            XCTAssertTrue(CombatGraphRules.canPurchase(hybrid, owned: [parent], catalogue: graph))
        }
    }

    func testCanonicalCombatCopyKeepsCapstoneGateSeparateFromOrdinaryParents() {
        XCTAssertEqual(CombatGraphNodeState.owned.playerLabel, "Learned")
        XCTAssertEqual(CombatGraphNodeState.available.playerLabel, "Available")
        XCTAssertEqual(CombatGraphNodeState.blocked.playerLabel, "Blocked")
        XCTAssertEqual(EncounterState.EvasionAttempt.Resolution.probabilityHit.playerLabel, "Hit")
        XCTAssertEqual(EncounterState.EvasionAttempt.Resolution.probabilityMiss.playerLabel, "Missed")
        XCTAssertEqual(EncounterState.EvasionAttempt.Resolution.sidestep.playerLabel, "Sidestepped")
        XCTAssertEqual(EncounterState.EvasionAttempt.Resolution.ghost.playerLabel, "Avoided with Ghost")
        XCTAssertEqual(CombatGraphRules.PurchaseRefusal.illegalParent.playerCopy,
                       "Learn one of this development’s exact prerequisites first.")
        XCTAssertEqual(CombatGraphRules.PurchaseRefusal.unavailable.playerCopy,
                       "This development is not implemented yet.")
        XCTAssertEqual(CombatGraphRules.PurchaseRefusal.invalidChoice.playerCopy,
                       "That selection is not available for this development.")
        XCTAssertEqual(CombatGraphRules.PurchaseRefusal.stale.playerCopy,
                       "This character changed. Review the development and try again.")
        XCTAssertEqual(ProgressionRequirementPresentation.capstoneRequirement,
                       "Capstone requirement: learn a connected route of 7 earlier Skills in this tree, including this discipline’s Root, one Fundamental, one Development, and one Mastery.")
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

    func testExactFortyFiveDepthOneThroughThreeNodesAreImplemented() {
        let opening = CombatGraphRules.implementedOpeningNodeIDs(in: graph)
        XCTAssertEqual(opening.count, 45)
        XCTAssertEqual(opening, Set(graph.nodes.filter { (1...3).contains($0.depth) }.map(\.id)))
        XCTAssertTrue(graph.nodes.filter { $0.depth > 3 }.allSatisfy { !opening.contains($0.id) })
    }

    func testFortitudeRemainsTheExactFirstCompleteEightPointRoute() throws {
        let route: [CombatNodeID] = [
            "combat.defense.fortitude.thick_hide",
            "combat.defense.fortitude.iron_skin",
            "combat.defense.fortitude.brace",
            "combat.defense.fortitude.constitution",
            "combat.defense.fortitude.endurance",
            "combat.defense.fortitude.ward",
            "combat.defense.fortitude.unyielding",
            "combat.defense.fortitude.immovable",
        ]
        XCTAssertEqual(CombatGraphRules.firstCompleteRouteNodeIDs, Set(route))
        let implemented = CombatGraphRules.implementedNodeIDs(in: graph)
        XCTAssertEqual(implemented.count, 54)
        XCTAssertEqual(
            implemented.subtracting(CombatGraphRules.implementedOpeningNodeIDs(in: graph)),
            CombatGraphRules.firstCompleteRouteNodeIDs
                .union(CombatGraphRules.protectionCompleteRouteNodeIDs)
                .union(CombatGraphRules.evasionCompleteRouteNodeIDs)
                .subtracting(CombatGraphRules.implementedOpeningNodeIDs(in: graph)))
        XCTAssertTrue(graph.nodes.filter {
            $0.depth > 3
                && !CombatGraphRules.firstCompleteRouteNodeIDs.contains($0.id)
                && !CombatGraphRules.protectionCompleteRouteNodeIDs.contains($0.id)
                && !CombatGraphRules.evasionCompleteRouteNodeIDs.contains($0.id)
        }
            .allSatisfy { !implemented.contains($0.id) })

        var character = CharacterState(level: 8)
        for id in route.prefix(7) {
            let quote = try CombatGraphRules.previewPurchase(id, for: character,
                                                             catalogue: graph).get()
            XCTAssertEqual(CombatGraphRules.commit(quote, for: &character, catalogue: graph),
                           .committed(id))
        }
        XCTAssertEqual(character.unspentCombatPoints, 0)
        XCTAssertEqual(CombatGraphRules.previewPurchase(route[7], for: character,
                                                        catalogue: graph),
                       .failure(.missingPoint))

        CharacterRules.grow(&character)
        XCTAssertEqual(character.level, 9)
        let capstone = try CombatGraphRules.previewPurchase(route[7], for: character,
                                                            catalogue: graph).get()
        XCTAssertEqual(CombatGraphRules.commit(capstone, for: &character, catalogue: graph),
                       .committed(route[7]))
        XCTAssertEqual(character.ownedCombatNodeIDs, Set(route))
        XCTAssertEqual(character.unspentCombatPoints, 0)

        let laterOther: CombatNodeID = "combat.offense.precision.killing_stroke"
        XCTAssertEqual(CombatGraphRules.previewPurchase(laterOther, for: CharacterState(level: 25),
                                                        catalogue: graph),
                       .failure(.unavailable))
        let roundTrip = try JSONDecoder().decode(CharacterState.self,
            from: JSONEncoder().encode(character))
        XCTAssertEqual(roundTrip, character)
    }

    func testProtectionRemainsTheExactSecondCompleteEightPointRoute() throws {
        let route: [CombatNodeID] = [
            "combat.defense.protection.bulwark",
            "combat.defense.protection.watchful",
            "combat.defense.protection.draw_off",
            "combat.defense.protection.cover",
            "combat.defense.protection.shieldwall",
            "combat.defense.protection.interpose",
            "combat.defense.protection.rally",
            "combat.defense.protection.guardian",
        ]
        XCTAssertEqual(CombatGraphRules.protectionCompleteRouteNodeIDs, Set(route))
        let implemented = CombatGraphRules.implementedNodeIDs(in: graph)
        XCTAssertEqual(implemented.count, 54)
        XCTAssertEqual(
            implemented.subtracting(CombatGraphRules.implementedOpeningNodeIDs(in: graph)),
            CombatGraphRules.firstCompleteRouteNodeIDs
                .union(CombatGraphRules.protectionCompleteRouteNodeIDs)
                .union(CombatGraphRules.evasionCompleteRouteNodeIDs)
                .subtracting(CombatGraphRules.implementedOpeningNodeIDs(in: graph)))
        XCTAssertTrue(graph.nodes.filter {
            $0.depth > 3
                && !CombatGraphRules.firstCompleteRouteNodeIDs.contains($0.id)
                && !Set(route).contains($0.id)
                && !CombatGraphRules.evasionCompleteRouteNodeIDs.contains($0.id)
        }.allSatisfy { !implemented.contains($0.id) })

        var character = CharacterState(level: 9)
        for id in route {
            let quote = try CombatGraphRules.previewPurchase(id, for: character,
                                                             catalogue: graph).get()
            XCTAssertEqual(CombatGraphRules.commit(quote, for: &character, catalogue: graph),
                           .committed(id))
        }
        XCTAssertEqual(character.ownedCombatNodeIDs, Set(route))
        XCTAssertEqual(character.unspentCombatPoints, 0)

        var missingMastery = CharacterState(level: 9)
        missingMastery.ownedCombatNodeIDs = Set(route.dropLast()).subtracting([route[5]])
        missingMastery.unspentCombatPoints = 1
        XCTAssertEqual(CombatGraphRules.previewPurchase(route[7], for: missingMastery,
                                                        catalogue: graph),
                       .failure(.illegalParent))

        let laterOther: CombatNodeID = "combat.offense.precision.killing_stroke"
        XCTAssertEqual(CombatGraphRules.previewPurchase(laterOther,
                                                        for: CharacterState(level: 25),
                                                        catalogue: graph),
                       .failure(.unavailable))
        XCTAssertEqual(try JSONDecoder().decode(CharacterState.self,
            from: JSONEncoder().encode(character)), character)

        CombatTreeRules.respec(&character)
        XCTAssertEqual(character.ownedCombatNodeIDs, [])
        XCTAssertEqual(character.unspentCombatPoints, 8)
        XCTAssertEqual(character.combatNodeChoices, [:])
    }

    func testEvasionIsTheExactThirdCompleteEightPointRoute() throws {
        let route: [CombatNodeID] = [
            "combat.defense.evasion.footwork",
            "combat.defense.evasion.light_frame",
            "combat.defense.evasion.sidestep",
            "combat.defense.evasion.slippery",
            "combat.defense.evasion.fall_back",
            "combat.defense.evasion.feint",
            "combat.defense.evasion.untouchable",
            "combat.defense.evasion.ghost",
        ]
        XCTAssertEqual(CombatGraphRules.evasionCompleteRouteNodeIDs, Set(route))
        let implemented = CombatGraphRules.implementedNodeIDs(in: graph)
        XCTAssertEqual(implemented.count, 54)
        XCTAssertEqual(
            implemented.subtracting(CombatGraphRules.implementedOpeningNodeIDs(in: graph)),
            CombatGraphRules.firstCompleteRouteNodeIDs
                .union(CombatGraphRules.protectionCompleteRouteNodeIDs)
                .union(CombatGraphRules.evasionCompleteRouteNodeIDs)
                .subtracting(CombatGraphRules.implementedOpeningNodeIDs(in: graph)))
        XCTAssertTrue(graph.nodes.filter {
            $0.depth > 3
                && !CombatGraphRules.firstCompleteRouteNodeIDs.contains($0.id)
                && !CombatGraphRules.protectionCompleteRouteNodeIDs.contains($0.id)
                && !Set(route).contains($0.id)
        }.allSatisfy { !implemented.contains($0.id) })

        var character = CharacterState(level: 9)
        for id in route {
            let quote = try CombatGraphRules.previewPurchase(id, for: character,
                                                             catalogue: graph).get()
            XCTAssertEqual(CombatGraphRules.commit(quote, for: &character, catalogue: graph),
                           .committed(id))
        }
        XCTAssertEqual(character.ownedCombatNodeIDs, Set(route))
        XCTAssertEqual(character.unspentCombatPoints, 0)

        var missingMastery = CharacterState(level: 9)
        missingMastery.ownedCombatNodeIDs = Set(route.dropLast()).subtracting([route[5]])
        missingMastery.unspentCombatPoints = 1
        XCTAssertEqual(CombatGraphRules.previewPurchase(route[7], for: missingMastery,
                                                        catalogue: graph),
                       .failure(.illegalParent))

        let laterOther: CombatNodeID = "combat.offense.precision.killing_stroke"
        XCTAssertEqual(CombatGraphRules.previewPurchase(laterOther,
                                                        for: CharacterState(level: 25),
                                                        catalogue: graph),
                       .failure(.unavailable))
        XCTAssertEqual(try JSONDecoder().decode(CharacterState.self,
            from: JSONEncoder().encode(character)), character)

        CombatTreeRules.respec(&character)
        XCTAssertEqual(character.ownedCombatNodeIDs, [])
        XCTAssertEqual(character.unspentCombatPoints, 8)
        XCTAssertEqual(character.combatNodeChoices, [:])
    }

    func testEveryOpeningHybridIsLegalFromEitherExactParentAndNotFromDestinationRoot() throws {
        let hybrids = graph.nodes.filter { $0.depth == 3 && !$0.hybridAlternativeParents.isEmpty }
        XCTAssertFalse(hybrids.isEmpty)
        for node in hybrids {
            for parent in node.ordinaryParentAlternatives {
                XCTAssertTrue(CombatGraphRules.canPurchase(node, owned: [parent], catalogue: graph))
            }
            let root = try XCTUnwrap(graph.discipline(containing: node.id)?.nodes
                .first(where: { $0.role == .root }))
            XCTAssertFalse(CombatGraphRules.canPurchase(node, owned: [root.id], catalogue: graph))
        }
    }

    func testStableOpeningPurchasesSpendOnePointPersistAndHoldLaterDepths() throws {
        var character = CharacterState(level: 4)
        let route: [CombatNodeID] = ["combat.offense.force.heavy_hand",
                                     "combat.offense.force.follow_through",
                                     "combat.offense.force.bracing_stance"]
        for nodeID in route {
            let before = CombatGraphRules.unspentPoints(for: character, catalogue: graph)
            let quote = try CombatGraphRules.previewPurchase(nodeID, for: character,
                                                             catalogue: graph).get()
            XCTAssertEqual(CombatGraphRules.commit(quote, for: &character, catalogue: graph),
                           .committed(nodeID))
            XCTAssertEqual(CombatGraphRules.unspentPoints(for: character, catalogue: graph), before - 1)
        }
        XCTAssertEqual(character.ownedCombatNodeIDs, Set(route))
        let relaunched = try JSONDecoder().decode(CharacterState.self,
                                                   from: JSONEncoder().encode(character))
        XCTAssertEqual(relaunched.ownedCombatNodeIDs, Set(route))
        XCTAssertEqual(CombatGraphRules.previewPurchase("combat.offense.force.shatter",
                                                        for: relaunched, catalogue: graph),
                       .failure(.unavailable))
    }

    func testLegacyMigrationUsesOnlySettledIDsAndRefundsUnresolvedPoints() throws {
        var legacy = CharacterState(level: Tuning.Character.maximumLevel)
        let legacyDepths: [CombatBranchID: Int] = ["force": 2, "removed_branch": 3]
        let reconciliation = CombatGraphRules.reconcileLegacy(branchDepth: legacyDepths,
                                                               catalogue: graph)
        let migrated: Set<CombatNodeID> = ["combat.offense.force.heavy_hand",
                                           "combat.offense.force.follow_through"]
        XCTAssertEqual(reconciliation.owned, migrated)
        XCTAssertEqual(reconciliation.refundedPoints, 3)
        legacy.ownedCombatNodeIDs = reconciliation.owned
        legacy.unspentCombatPoints = reconciliation.refundedPoints + 1
        let root: CombatNodeID = "combat.defense.fortitude.thick_hide"
        let quote = try CombatGraphRules.previewPurchase(root, for: legacy, catalogue: graph).get()
        XCTAssertEqual(CombatGraphRules.commit(quote, for: &legacy, catalogue: graph),
                       .committed(root))
        XCTAssertEqual(legacy.ownedCombatNodeIDs, reconciliation.owned.union([root]))
    }

    func testOpeningChoiceAndTechniqueAuthorityIsClosed() throws {
        let opening = graph.nodes.filter { $0.depth <= 3 }
        XCTAssertEqual(opening.filter { $0.role == .root }.count, 9)
        XCTAssertEqual(opening.filter { $0.role == .fundamentalA || $0.role == .fundamentalB }.count, 18)
        XCTAssertEqual(opening.filter { $0.role == .developmentA || $0.role == .developmentB }.count, 18)
        XCTAssertEqual(opening.compactMap(\.techniqueID).count, 13)
        let choiceNodes = opening.filter { !$0.purchaseChoices.isEmpty }
        XCTAssertEqual(choiceNodes.count, 1)
        let insulation = try XCTUnwrap(choiceNodes.first)
        XCTAssertEqual(insulation.id, "combat.craft.emanation.insulation")
        XCTAssertEqual(insulation.purchaseChoices, ["heat", "caustic", "light"])

        for choice in insulation.purchaseChoices {
            var character = CharacterState(level: 3)
            let root: CombatNodeID = "combat.craft.emanation.sparkhand"
            let rootQuote = try CombatGraphRules.previewPurchase(root, for: character,
                                                                 catalogue: graph).get()
            _ = CombatGraphRules.commit(rootQuote, for: &character, catalogue: graph)
            let quote = try CombatGraphRules.previewPurchase(insulation.id, choice: choice,
                                                              for: character, catalogue: graph).get()
            XCTAssertEqual(CombatGraphRules.commit(quote, for: &character, catalogue: graph),
                           .committed(insulation.id))
            XCTAssertEqual(character.combatNodeChoices[insulation.id], choice)
        }
        var character = CharacterState(level: 3)
        let root: CombatNodeID = "combat.craft.emanation.sparkhand"
        _ = CombatGraphRules.commit(try CombatGraphRules.previewPurchase(root, for: character,
                                                                         catalogue: graph).get(),
                                    for: &character, catalogue: graph)
        XCTAssertEqual(CombatGraphRules.previewPurchase(insulation.id, for: character,
                                                        catalogue: graph), .failure(.invalidChoice))
        XCTAssertEqual(CombatGraphRules.previewPurchase(insulation.id, choice: "cold",
                                                        for: character, catalogue: graph),
                       .failure(.invalidChoice))
    }

    func testDurablePointTotalsAndLevelAwards() {
        for (level, points) in [(1, 0), (2, 1), (3, 2), (4, 3), (5, 4),
                                (9, 8), (17, 16), (25, 24)] {
            XCTAssertEqual(CharacterState(level: level).unspentCombatPoints, points)
        }
        var character = CharacterState(level: 1)
        for _ in 1..<4 { CharacterRules.grow(&character) }
        XCTAssertEqual(character.unspentCombatPoints, 3)
    }

    func testIllegalInvalidAndStaleOpeningPurchasesMutateNothing() throws {
        var character = CharacterState(level: 4)
        let development: CombatNodeID = "combat.offense.force.stagger"
        XCTAssertEqual(CombatGraphRules.previewPurchase(development, for: character,
                                                        catalogue: graph),
                       .failure(.illegalParent))
        let root: CombatNodeID = "combat.offense.force.heavy_hand"
        XCTAssertEqual(CombatGraphRules.previewPurchase(root, choice: "invented", for: character,
                                                        catalogue: graph),
                       .failure(.invalidChoice))
        let stale = try CombatGraphRules.previewPurchase(root, for: character, catalogue: graph).get()
        let other = try CombatGraphRules.previewPurchase("combat.defense.fortitude.thick_hide",
                                                         for: character, catalogue: graph).get()
        XCTAssertEqual(CombatGraphRules.commit(other, for: &character, catalogue: graph),
                       .committed(other.nodeID))
        let afterOther = character
        XCTAssertEqual(CombatGraphRules.commit(stale, for: &character, catalogue: graph),
                       .refused(.stale))
        XCTAssertEqual(character, afterOther)
    }

    @MainActor
    func testStorePurchaseFlushesStableOwnershipAndStaleRefusalRecordsNoMutation() throws {
        let io = SaveFileIO.temporary(name: "combat-opening-\(UUID().uuidString)")
        let store = GameStore(io: io)
        store.mutate("reach level two", flush: true) {
            $0.base.binderCharacter.level = 2
            $0.base.binderCharacter.unspentCombatPoints = 1
        }
        let heavy: CombatNodeID = "combat.offense.force.heavy_hand"
        let thick: CombatNodeID = "combat.defense.fortitude.thick_hide"
        let heavyQuote = try store.previewCombatNodePurchase(heavy, for: .binder).get()
        let staleThickQuote = try store.previewCombatNodePurchase(thick, for: .binder).get()
        XCTAssertEqual(store.purchaseCombatNode(heavyQuote, for: .binder), .committed(heavy))
        let mutationAfterPurchase = store.state.meta.mutationCount
        XCTAssertEqual(store.purchaseCombatNode(staleThickQuote, for: .binder), .refused(.stale))
        XCTAssertEqual(store.state.meta.mutationCount, mutationAfterPurchase)

        let relaunched = GameStore(io: io)
        XCTAssertEqual(relaunched.state.base.binderCharacter.ownedCombatNodeIDs, [heavy])
        XCTAssertEqual(CombatGraphRules.unspentPoints(for: relaunched.state.base.binderCharacter,
                                                      catalogue: graph), 0)
    }

    private func id(_ tree: String, _ discipline: String, _ slug: String) -> CombatNodeID {
        CombatNodeID(rawValue: "combat.\(tree).\(discipline).\(slug)")
    }

    private func ids(_ tree: String, _ entries: [(String, String)]) -> [CombatNodeID] {
        entries.map { id(tree, $0.0, $0.1) }
    }
}
