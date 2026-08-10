import XCTest
@testable import Bookbinder

@MainActor
final class ConsumableCraftingTests: XCTestCase {
    func testEveryApothecaryRecipeProducesAnAuthoredConsumableEffect() {
        for recipe in ConsumableCraftingRules.recipes {
            let item = ContentCatalog.shared.item(recipe.output)
            XCTAssertEqual(item?.kind, .consumable, recipe.output.rawValue)
            XCTAssertNotNil(item?.consumable, recipe.output.rawValue)
        }
    }

    func testRecipeUsesWeakestQualifyingNaturalStockAndNamedReagents() throws {
        var state = stockedState(for: "salve_lesser")
        let recipe = try XCTUnwrap(ConsumableCraftingRules.recipe("salve_lesser"))
        state.base.inventory.stacks = [ItemStack(
            id: InstanceID(rawValue: 800), catalogID: Items.material,
            materials: [sample(.flexibility, 90), sample(.flexibility, 26)])]
        state.base.resources.add(1, of: "resin")

        XCTAssertTrue(ConsumableCraftingRules.craft(recipe, in: &state))
        XCTAssertEqual(state.base.resources["resin"], 0)
        XCTAssertEqual(state.base.inventory.stacks.first { !$0.materials.isEmpty }?
            .materials.first?.properties.flexibility, 90)
        XCTAssertEqual(state.base.inventory.stacks.first { $0.catalogID == "salve_lesser" }?.count, 1)
    }

    func testARecipeStaysKnownAfterItsSuggestingStockIsGoneAndAcrossSave() throws {
        var base = BaseState.newGame()
        base.knownConsumableRecipes.insert("stillwater")
        let data = try SaveCodec.makeEncoder().encode(base)
        let decoded = try SaveCodec.makeDecoder().decode(BaseState.self, from: data)
        XCTAssertTrue(decoded.knownConsumableRecipes.contains("stillwater"))
    }

    func testStillwaterRestoresStabilityAndCostsOneTurn() throws {
        var state = fieldState(item: "stillwater")
        state.worlds.activeRun?.stability = 20
        let before = try XCTUnwrap(state.worlds.activeRun?.turnsTaken)
        let id = try XCTUnwrap(state.worlds.activeRun?.satchelItems.stacks.first?.id)

        _ = WorldRules.useItem(id, on: .binder, in: &state)

        XCTAssertGreaterThan(state.worlds.activeRun?.stability ?? 0, 20)
        XCTAssertEqual(state.worlds.activeRun?.turnsTaken, before + 1)
        XCTAssertTrue(state.worlds.activeRun?.satchelItems.stacks.isEmpty == true)
    }

    func testTorchRaisesVisionForTheRestOfTheRun() throws {
        var state = fieldState(item: "torch")
        let before = try XCTUnwrap(state.worlds.activeRun.map { WorldRules.visionRadius(in: $0) })
        let id = try XCTUnwrap(state.worlds.activeRun?.satchelItems.stacks.first?.id)

        _ = WorldRules.useItem(id, on: .binder, in: &state)

        XCTAssertEqual(state.worlds.activeRun.map { WorldRules.visionRadius(in: $0) }, before + 2)
    }

    func testWaystoneReturnsTheWholeHaulAndNamesTheExit() throws {
        let store = GameStore(io: .temporary(name: "waystone-\(UUID().uuidString)"))
        store.mutate("field state") { $0 = self.fieldState(item: "waystone") }
        store.mutate("haul") { $0.worlds.activeRun?.satchel.add(3, of: "quartz") }
        let stack = try XCTUnwrap(store.activeRun?.satchelItems.stacks.first)

        store.useItemInWorld(stack, on: .binder)

        XCTAssertNil(store.activeRun)
        XCTAssertEqual(store.state.base.resources["quartz"], 3)
        XCTAssertTrue(store.state.worlds.lastExit?.reason.contains("Waystone") == true)
        XCTAssertEqual(store.state.worlds.lastExit?.haulKeptFraction, 1)
        XCTAssertEqual(store.state.worlds.lastExit?.kind, .waystone)
    }

    func testWaystoneUsesTheReversibleRiftGlassRecipe() throws {
        let recipe = try XCTUnwrap(ConsumableCraftingRules.recipe("waystone"))

        XCTAssertEqual(recipe.material?.property, .hardness)
        XCTAssertEqual(recipe.material?.minimum, 70)
        XCTAssertEqual(recipe.material?.count, 1)
        XCTAssertEqual(recipe.resources, ["rift_glass": 1])
        XCTAssertEqual(recipe.motes, 1)
        XCTAssertEqual(recipe.essence, 30)
    }

    func testSolventIdentifiesOneCurioInTheFieldAndCostsOneTurn() throws {
        let store = GameStore(io: .temporary(name: "solvent-\(UUID().uuidString)"))
        store.mutate("field state") { $0 = self.fieldState(item: "solvent") }
        let curio = ItemStack(id: InstanceID(rawValue: 901), catalogID: "curio_humming_shard",
                              identified: false)
        store.mutate("curio") { _ = $0.worlds.activeRun?.satchelItems.add(curio) }
        let solvent = try XCTUnwrap(store.activeRun?.satchelItems.stacks.first { $0.catalogID == "solvent" })
        let before = try XCTUnwrap(store.activeRun?.turnsTaken)

        store.useSolventInWorld(solvent, on: curio)

        XCTAssertEqual(store.activeRun?.turnsTaken, before + 1)
        XCTAssertFalse(store.activeRun?.satchelItems.stacks.contains { $0.catalogID == "solvent" } ?? true)
        XCTAssertTrue(store.activeRun?.satchelItems.stacks.contains {
            $0.catalogID == "salve_lesser" && $0.identified
        } == true)
    }

    func testLureWakesNearestRoamingCreatureAndCostsATurn() throws {
        var state = fieldState(item: "lure")
        var traits = CreatureTraits()
        traits.size = 40
        let enemy = WorldEnemy(id: InstanceID(rawValue: 902), speciesID: InstanceID(rawValue: 903),
                               traits: traits, position: GridPoint(x: 0, y: 0), isAwake: false)
        state.worlds.activeRun?.enemies = [enemy]
        state.worlds.activeRun?.map[enemy.position].isRevealed = true
        let id = try XCTUnwrap(state.worlds.activeRun?.satchelItems.stacks.first?.id)
        let before = try XCTUnwrap(state.worlds.activeRun?.turnsTaken)

        _ = WorldRules.useItem(id, on: .binder, in: &state)

        XCTAssertEqual(state.worlds.activeRun?.turnsTaken, before + 1)
        XCTAssertTrue(state.worlds.activeRun?.enemies.first?.isAwake == true)
        XCTAssertTrue(state.worlds.activeRun?.satchelItems.stacks.isEmpty == true)
    }

    func testLureIgnoresHiddenCrypsisAndConsumesNothingWithoutAVisibleTarget() throws {
        var state = fieldState(item: "lure")
        state.worlds.activeRun?.map = WorldMap(width: 15, height: 15,
            tiles: Array(repeating: Tile(isRevealed: false), count: 225),
            entry: GridPoint(x: 7, y: 7))
        state.worlds.activeRun?.playerPosition = GridPoint(x: 7, y: 7)
        var hiddenTraits = CreatureTraits()
        hiddenTraits.defence = .crypsis
        let hidden = WorldEnemy(id: InstanceID(rawValue: 910), traits: hiddenTraits,
                                position: GridPoint(x: 7, y: 14))
        let visibleTraits = CreatureTraits()
        let visible = WorldEnemy(id: InstanceID(rawValue: 911), traits: visibleTraits,
                                 position: GridPoint(x: 0, y: 0))
        state.worlds.activeRun?.enemies = [hidden, visible]
        state.worlds.activeRun?.map[hidden.position].isRevealed = true
        state.worlds.activeRun?.map[visible.position].isRevealed = true
        let id = try XCTUnwrap(state.worlds.activeRun?.satchelItems.stacks.first?.id)

        _ = WorldRules.useItem(id, on: .binder, in: &state)
        XCTAssertFalse(state.worlds.activeRun?.enemies[0].isAwake ?? true)
        XCTAssertTrue(state.worlds.activeRun?.enemies[1].isAwake == true)

        var onlyHidden = fieldState(item: "lure")
        onlyHidden.worlds.activeRun?.map = WorldMap(width: 15, height: 15,
            tiles: Array(repeating: Tile(isRevealed: false), count: 225),
            entry: GridPoint(x: 7, y: 7))
        onlyHidden.worlds.activeRun?.playerPosition = GridPoint(x: 7, y: 7)
        onlyHidden.worlds.activeRun?.enemies = [hidden]
        onlyHidden.worlds.activeRun?.map[hidden.position].isRevealed = true
        let hiddenLure = try XCTUnwrap(onlyHidden.worlds.activeRun?.satchelItems.stacks.first?.id)
        let before = try XCTUnwrap(onlyHidden.worlds.activeRun?.turnsTaken)
        let blocked = WorldRules.useItem(hiddenLure, on: .binder, in: &onlyHidden)
        XCTAssertEqual(blocked, [.blocked("No visible roaming creature answers the lure.")])
        XCTAssertEqual(onlyHidden.worlds.activeRun?.turnsTaken, before)
        XCTAssertNotNil(onlyHidden.worlds.activeRun?.satchelItems.stacks.first)
    }

    private func stockedState(for recipe: ItemID) -> GameState {
        var state = GameState.newGame()
        state.base.essence = 500
        state.base.inventory.slots = 20
        state.base.knownConsumableRecipes.insert(recipe)
        return state
    }

    private func sample(_ property: MaterialProperty, _ value: Double) -> MaterialSample {
        var properties = MaterialProperties()
        properties[property] = value
        return MaterialSample(kind: .reagent, properties: properties, grade: value, source: "test")
    }

    private func fieldState(item: ItemID) -> GameState {
        var state = GameState.newGame()
        var map = WorldMap(width: 3, height: 3,
                           tiles: Array(repeating: Tile(isRevealed: false), count: 9),
                           entry: GridPoint(x: 1, y: 1))
        map[GridPoint(x: 1, y: 1)].content = .portal(isEntry: true)
        var satchel = Inventory(slots: 8)
        satchel.add(ItemStack(id: InstanceID(rawValue: 900), catalogID: item))
        state.worlds.activeRun = WorldRun(
            runIndex: 1,
            book: BoundBook(written: [], essencePaid: 0),
            mapSeed: 42,
            rng: SeededRNG(seed: 42),
            map: map,
            playerPosition: GridPoint(x: 1, y: 1),
            satchelItems: satchel)
        return state
    }
}
