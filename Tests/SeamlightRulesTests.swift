import XCTest
@testable import Bookbinder

final class SeamlightRulesTests: XCTestCase {
    private func makeRun(portals: [GridPoint] = [.init(x: 2, y: 0)],
                     player: GridPoint = .init(x: 0, y: 0),
                     stacks: [ItemStack] = []) -> WorldRun {
        var tiles = Array(repeating: Tile(ground: .soil, isRevealed: false), count: 9)
        for point in portals { tiles[point.y * 3 + point.x].content = .portal(isEntry: false) }
        return WorldRun(runIndex: 7,
                        book: BoundBook(symbols: [:], randomlyFilled: [], essencePaid: 0),
                        mapSeed: 77, rng: SeededRNG(seed: 77),
                        map: WorldMap(width: 3, height: 3, tiles: tiles,
                                      entry: .init(x: 2, y: 0)),
                        playerPosition: player,
                        satchelItems: Inventory(slots: 8, stacks: stacks))
    }

    private func state(_ run: WorldRun?) -> GameState {
        var state = GameState.newGame(); state.worlds.activeRun = run; return state
    }

    func testSL01CatalogueRecipeAndMerchantMetadata() throws {
        let item = try XCTUnwrap(ContentCatalog.shared.item(Items.seamlight))
        XCTAssertEqual(item.name, "Seamlight")
        XCTAssertEqual(item.kind, .consumable)
        XCTAssertEqual(item.rarity, .uncommon)
        XCTAssertEqual(item.consumable?.effect, .seamlightGuidance)
        XCTAssertEqual(item.consumableMerchantStockAccess, .independent)
        let recipe = try XCTUnwrap(ConsumableCraftingRules.recipe(Items.seamlight))
        XCTAssertEqual(recipe.family, .fieldwork)
        XCTAssertEqual(recipe.resources, ["quartz": 1, "resin": 1, "fiber": 1])
        XCTAssertNil(recipe.material); XCTAssertEqual(recipe.essence, 0); XCTAssertEqual(recipe.motes, 0)
    }

    func testSL02ExactStackActivatesConsumesOnceAndAdvancesOneTurn() throws {
        let selected = ItemStack(id: .init(rawValue: 10), catalogID: Items.seamlight, count: 2)
        let other = ItemStack(id: .init(rawValue: 11), catalogID: Items.seamlight, count: 2)
        var state = state(makeRun(stacks: [selected, other]))
        let quote = try XCTUnwrap(try? SeamlightRules.evaluate(
            sourceItemInstanceID: selected.id, in: state).get())
        let result = SeamlightRules.commit(quote, in: &state)
        guard case .activated(let receipt, let events) = result else { return XCTFail("activation") }
        XCTAssertEqual(receipt.sourceItemInstanceID, selected.id)
        XCTAssertEqual(state.worlds.activeRun?.satchelItems.stacks.first { $0.id == selected.id }?.count, 1)
        XCTAssertEqual(state.worlds.activeRun?.satchelItems.stacks.first { $0.id == other.id }?.count, 2)
        XCTAssertEqual(state.worlds.activeRun?.turnsTaken, 1)
        XCTAssertEqual(events.first, .seamlightActivated)
    }

    func testSL03DuplicateAndSL04NoRouteAreAtomic() throws {
        let stack = ItemStack(id: .init(rawValue: 10), catalogID: Items.seamlight)
        var active = makeRun(stacks: [stack])
        active.seamlightGuidance = .init(version: 1, sourceItemID: Items.seamlight,
                                          sourceItemInstanceID: stack.id, activatedOnTurn: 0)
        let duplicate = state(active)
        XCTAssertEqual(SeamlightRules.evaluate(sourceItemInstanceID: stack.id, in: duplicate),
                       .failure(.alreadyActive))
        let noRoute = state(makeRun(portals: [], stacks: [stack]))
        XCTAssertEqual(SeamlightRules.evaluate(sourceItemInstanceID: stack.id, in: noRoute),
                       .failure(.noReachablePortal))
        XCTAssertEqual(try SaveCodec.encode(duplicate), try SaveCodec.encode(duplicate))
    }

    func testSL05RefusalCopyAndUnavailableTruth() {
        let id = InstanceID(rawValue: 9)
        XCTAssertEqual(SeamlightRules.evaluate(sourceItemInstanceID: id, in: state(nil)),
                       .failure(.noActiveExpedition))
        XCTAssertEqual(SeamlightRules.playerCopy(for: .itemUnavailable),
                       "That Seamlight is no longer in the Field Kit.")
        XCTAssertEqual(SeamlightRules.playerCopy(for: .noReachablePortal),
                       "No portal seam answers the light.")
    }

    func testSL06StableShortestBFSAndSL09Bands() {
        var short = makeRun(portals: [.init(x: 0, y: 1), .init(x: 1, y: 0)])
        short.seamlightGuidance = .init(version: 1, sourceItemID: Items.seamlight,
                                        sourceItemInstanceID: .init(rawValue: 1), activatedOnTurn: 0)
        XCTAssertEqual(SeamlightRules.route(in: short), [.init(x: 0, y: 0), .init(x: 1, y: 0)])
        XCTAssertEqual(SeamlightRules.projection(in: short), .directional(.east, .near))
        var same = short; same.playerPosition = .init(x: 1, y: 0)
        XCTAssertEqual(SeamlightRules.projection(in: same), .onPortal)
        var far = short; far.map[.init(x: 1, y: 0)].content = .empty
        XCTAssertEqual(SeamlightRules.projection(in: far), .directional(.south, .near))
    }

    func testSL10RouteIsDisclosureNeutralAndSL11PersistenceClearsAnchoredReceipt() throws {
        var active = makeRun()
        active.seamlightGuidance = .init(version: 1, sourceItemID: Items.seamlight,
                                          sourceItemInstanceID: .init(rawValue: 4), activatedOnTurn: 0)
        let revealBefore = active.map.tiles.map(\.isRevealed)
        _ = SeamlightRules.projection(in: active)
        XCTAssertEqual(active.map.tiles.map(\.isRevealed), revealBefore)
        let decoded = try JSONDecoder().decode(WorldRun.self, from: JSONEncoder().encode(active))
        XCTAssertEqual(decoded.seamlightGuidance, active.seamlightGuidance)
        XCTAssertNil(active.anchoredSnapshot.seamlightGuidance)

        var malformed = try XCTUnwrap(JSONSerialization.jsonObject(
            with: JSONEncoder().encode(active)) as? [String: Any])
        var receipt = try XCTUnwrap(malformed["seamlightGuidance"] as? [String: Any])
        receipt["version"] = 2
        malformed["seamlightGuidance"] = receipt
        let failedClosed = try JSONDecoder().decode(
            WorldRun.self, from: JSONSerialization.data(withJSONObject: malformed))
        XCTAssertNil(failedClosed.seamlightGuidance)
        XCTAssertEqual(failedClosed.playerPosition, active.playerPosition)
        XCTAssertEqual(failedClosed.map, active.map)
    }

    func testSL12DiscoveryAndCraftingUseExactResources() {
        var state = GameState.newGame()
        state.base.stations[Stations.apothecary] = .init(isUnlocked: true, tier: 0)
        state.base.resources.add(1, of: "quartz")
        let recipe = ConsumableCraftingRules.recipe(Items.seamlight)!
        XCTAssertTrue(ConsumableCraftingRules.canInfer(recipe, in: state))
        state.base.knownConsumableRecipes.insert(Items.seamlight)
        state.base.resources.add(1, of: "resin"); state.base.resources.add(1, of: "fiber")
        XCTAssertTrue(ConsumableCraftingRules.craft(recipe, in: &state))
        XCTAssertEqual(state.base.resources["quartz"], 0)
        XCTAssertEqual(state.base.resources["resin"], 0)
        XCTAssertEqual(state.base.resources["fiber"], 0)
        XCTAssertEqual(state.base.inventory.stacks.first { $0.catalogID == Items.seamlight }?.count, 1)
    }
}
