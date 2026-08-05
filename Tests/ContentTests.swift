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
        // The brief heads this list "Starter collection (10 symbols)" and then names ELEVEN
        // (3 terrain + 3 biome + 3 bounty + 2 quirk). Conservative reading: ship all eleven that
        // Aimee named rather than silently dropping one to hit the count. See
        // docs/questions-for-design.md Q2.
        let expected: Set<SymbolID> = [
            "plains", "caverns", "archipelago",
            "verdant", "ashen", "frostbound",
            "sparse_ore", "rich_ore", "teeming_life",
            "dim_sky", "gilded_veins",
        ]
        XCTAssertEqual(Set(ContentCatalog.shared.starterSymbolIDs), expected)
    }

    func testEverySlotHasAtLeastOneStarterSymbol() {
        // Random-filling an empty slot needs a candidate the player owns, in every slot.
        for slot in ContentCatalog.shared.slotIDsInOrder {
            let owned = ContentCatalog.shared.symbols(in: slot).filter { $0.acquisition == .starter }
            XCTAssertFalse(owned.isEmpty, "Slot '\(slot)' has no starter symbol to random-fill with")
        }
    }

    func testThreeCreatureTypesShip() {
        XCTAssertEqual(ContentCatalog.shared.creatures.count, 3, "v0 ships exactly three enemy types")
    }

    func testStarterGambitPiecesMatchTheBrief() {
        let starters = ContentCatalog.shared.starterGambitPieceIDs
        XCTAssertEqual(Set(starters), ["foe_any_attack", "ally_hp_below_50_heal", "foe_lowest_hp_attack"])
        XCTAssertGreaterThanOrEqual(starters.count, Tuning.Encounter.startingGambitSlots)
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
        XCTAssertEqual(state.base.companion.gambits.count, Tuning.Encounter.startingGambitSlots)
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
            gambitPieces: catalog.gambitPieces,
            stations: catalog.stations,
            constellationNodes: catalog.constellationNodes
        )
        XCTAssertThrowsError(try sabotaged.validate())
    }
}
