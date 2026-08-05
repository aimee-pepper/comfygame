import XCTest
@testable import Bookbinder

/// Content is data, so content mistakes are data mistakes — these tests are the spellchecker.
/// Adding a symbol/creature/station to JSON and getting an ID wrong should fail here, loudly,
/// rather than silently spawning nothing in a world.
final class ContentTests: XCTestCase {

    func testCatalogLoadsAndValidates() throws {
        let catalog = try ContentCatalog.load()
        XCTAssertNoThrow(try catalog.validate())
    }

    func testStarterCollectionMatchesTheBrief() {
        // The brief names eleven (Q2). "Ore" is a twelfth, added on Aimee's instruction that the
        // bounty slot needs a neutral middle rung — see questions-for-design Q15.
        let expected: Set<SymbolID> = [
            "plains", "caverns", "archipelago",
            "verdant", "ashen", "frostbound",
            "sparse_ore", "common_ore", "rich_ore", "teeming_life",
            "dim_sky", "gilded_veins",
        ]
        XCTAssertEqual(Set(ContentCatalog.shared.starterSymbolIDs), expected)
    }

    /// The rule that makes the bounty slot a decision instead of a toll: below the baseline calms a
    /// world, the baseline costs nothing, above it destabilises.
    func testTheBountyLadderRunsBelowAtAndAboveTheBaseline() throws {
        let sparse = try XCTUnwrap(ContentCatalog.shared.symbol("sparse_ore"))
        let ordinary = try XCTUnwrap(ContentCatalog.shared.symbol("common_ore"))
        let rich = try XCTUnwrap(ContentCatalog.shared.symbol("rich_ore"))

        XCTAssertGreaterThan(sparse.stabilityDelta, 0, "Asking for less than there is calms a world")
        XCTAssertEqual(ordinary.stabilityDelta, 0, "Asking for what's already there costs nothing")
        XCTAssertLessThan(rich.stabilityDelta, 0, "Asking for more than there is, is greed")

        // …and the yields have to follow the same ladder, or the names are lying.
        let sparseOre = sparse.yieldModifiers[Resources.ore] ?? 1
        let ordinaryOre = ordinary.yieldModifiers[Resources.ore] ?? 1
        let richOre = rich.yieldModifiers[Resources.ore] ?? 1
        XCTAssertLessThan(sparseOre, ordinaryOre)
        XCTAssertLessThan(ordinaryOre, richOre)
    }

    func testEverySlotHasAtLeastOneStarterSymbol() {
        // Random-filling an empty slot needs a candidate the player owns, in every slot.
        for slot in ContentCatalog.shared.slotIDsInOrder {
            let owned = ContentCatalog.shared.symbols(in: slot).filter { $0.acquisition == .starter }
            XCTAssertFalse(owned.isEmpty, "Slot '\(slot)' has no starter symbol to random-fill with")
        }
    }

    /// Sight belongs to the creature, so later ones can notice you from further off.
    func testEveryCreatureCanSee() {
        for creature in ContentCatalog.shared.creatures {
            XCTAssertGreaterThan(creature.sightRadius, 0, "'\(creature.id)' would never notice you")
        }
    }

    func testThreeCreatureTypesShip() {
        XCTAssertEqual(ContentCatalog.shared.creatures.count, 3, "v0 ships exactly three enemy types")
    }

    /// You start able to say a little, and everything else is learned. Every starter component
    /// has to exist, or a new game begins with rules it can't read.
    func testStarterComponentsAllExist() {
        for id in GambitStarter.components {
            XCTAssertNotNil(ContentCatalog.shared.gambitComponent(id), "Unknown starter component '\(id)'")
        }
        for rule in GambitStarter.rules {
            XCTAssertTrue(rule.isWritable(with: Set(GambitStarter.components)),
                          "A starter rule uses something a new player doesn't have")
        }
    }

    /// Every kind of component needs at least one instance or the grammar has a hole in it.
    func testTheGrammarIsComplete() {
        for kind in GambitComponentDef.Kind.allCases {
            XCTAssertFalse(ContentCatalog.shared.components(kind).isEmpty,
                           "No '\(kind.rawValue)' components exist")
        }
    }

    /// All research is gated behind a themed branch — there is no flat shopping list.
    func testEveryBranchHasReachableWork() {
        for branch in ContentCatalog.shared.branchesInOrder {
            let nodes = ContentCatalog.shared.nodes(in: branch.id)
            XCTAssertFalse(nodes.isEmpty, "Branch '\(branch.id)' has no nodes")
            XCTAssertTrue(nodes.contains { $0.requires.isEmpty },
                          "Branch '\(branch.id)' has no entry point — every node is behind another")
        }
    }

    /// A prerequisite cycle would make part of the tree permanently unreachable, and it wouldn't
    /// be obvious from reading the JSON.
    func testTheResearchTreeHasNoCycles() {
        var resolved = Set<ResearchNodeID>()
        var progressed = true
        while progressed {
            progressed = false
            for node in ContentCatalog.shared.researchNodes where !resolved.contains(node.id) {
                if node.requires.allSatisfy({ resolved.contains($0) }) {
                    resolved.insert(node.id)
                    progressed = true
                }
            }
        }
        let unreachable = ContentCatalog.shared.researchNodes.filter { !resolved.contains($0.id) }
        XCTAssertTrue(unreachable.isEmpty,
                      "Unreachable research: \(unreachable.map(\.id.rawValue).joined(separator: ", "))")
    }

    func testCuriosIdentifyIntoAConsumableAndAKey() {
        let curios = ContentCatalog.shared.items.filter { $0.kind == .curio }
        XCTAssertEqual(curios.count, 2, "v0 ships two unidentified curio types")

        let outcomes = curios.compactMap { $0.identifiesInto }.compactMap { ContentCatalog.shared.item($0)?.kind }
        XCTAssertTrue(outcomes.contains(.consumable), "One curio must identify into a consumable")
        XCTAssertTrue(outcomes.contains(.key), "One curio must identify into a key (the locked-cache payoff)")
    }

    /// Every station in the data must route to a screen that exists.
    func testStationRoutesResolveToRealScreens() {
        for station in ContentCatalog.shared.stations {
            XCTAssertNotNil(AppRoute(rawValue: station.route),
                            "Station '\(station.id)' routes to unknown screen '\(station.route)'")
        }
    }

    func testStationsCoverTheSixV0Screens() {
        let ids = Set(ContentCatalog.shared.stations.map(\.id))
        for required in [Stations.writingDesk, Stations.storehouse, Stations.workshop,
                         Stations.party, Stations.essenceSpring, Stations.constellation] {
            XCTAssertTrue(ids.contains(required), "Missing station '\(required)'")
        }
    }

    func testConstellationHasThreeNodes() {
        XCTAssertEqual(ContentCatalog.shared.constellationNodes.count, 3, "v0 Constellation ships three nodes")
        for node in ContentCatalog.shared.constellationNodes {
            XCTAssertEqual(node.moteCostPerRank.count, node.maxRank, "Node '\(node.id)' needs a cost per rank")
        }
    }

    /// A new game must be internally consistent with whatever the catalogs currently say.
    func testNewGameIsBuiltFromTheCatalog() {
        let state = GameState.newGame()
        XCTAssertEqual(state.base.ownedSymbols.count, ContentCatalog.shared.starterSymbolIDs.count)
        XCTAssertEqual(state.base.stations.count, ContentCatalog.shared.stations.count)
        XCTAssertEqual(state.base.companion.gambits.count, GambitStarter.rules.count)
        for id in state.base.ownedSymbols {
            XCTAssertNotNil(ContentCatalog.shared.symbol(id), "New game grants unknown symbol '\(id)'")
        }
    }

    /// Tier counts upgrades purchased, so a fresh Storehouse (tier 0) grants no bonus slots.
    func testInventoryStartsAtEightSlotsAndGrowsPerStorehouseTier() {
        var base = BaseState.newGame()
        XCTAssertEqual(base.inventory.slots, 8, "The brief specifies 8 starting inventory slots")

        base.stations[Stations.storehouse] = StationState(isUnlocked: true, tier: 2)
        base.syncInventoryCapacity()
        XCTAssertEqual(base.inventory.slots, 8 + 2 * Tuning.Economy.inventorySlotsPerStorehouseTier)
    }

    func testStationMaxTiersAreReachable() {
        for station in ContentCatalog.shared.stations {
            XCTAssertLessThanOrEqual(station.startingTier, station.maxTier,
                                     "Station '\(station.id)' starts above its max tier")
        }
    }

    func testValidationCatchesADanglingReference() throws {
        let catalog = try ContentCatalog.load()
        var broken = catalog.symbols
        broken[0].yieldModifiers = ["not_a_real_resource": 2.0]
        let sabotaged = ContentCatalog(
            slots: catalog.slots,
            symbols: broken,
            creatures: catalog.creatures,
            resources: catalog.resources,
            items: catalog.items,
            skills: catalog.skills,
            pressureTargets: catalog.pressureTargets,
            pressureSources: catalog.pressureSources,
            researchBranches: catalog.researchBranches,
            researchNodes: catalog.researchNodes,
            gambitComponents: catalog.gambitComponents,
            stations: catalog.stations,
            constellationNodes: catalog.constellationNodes,
            sites: catalog.sites,
            contradictions: catalog.contradictions,
            descriptionClauses: catalog.descriptionClauses
        )
        XCTAssertThrowsError(try sabotaged.validate())
    }
}
