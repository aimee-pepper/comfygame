import XCTest
@testable import Bookbinder

@MainActor
final class ConsumableCraftingTests: XCTestCase {
    func testScentMaskApothecaryRequiresAnExplicitExactResourceAndUsesQuoteCommitAPI() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf: root.appendingPathComponent(
            "Sources/Screens/ApothecaryView.swift"), encoding: .utf8)

        XCTAssertTrue(source.contains("ConsumableCraftingRules.scentMaskAnimalResources(in: store.state)"))
        XCTAssertTrue(source.contains("Text(\"Choose a resource\").tag(Optional<CraftMaterialUnitID>.none)"))
        XCTAssertTrue(source.contains("store.scentMaskQuote(using: $0)"))
        XCTAssertTrue(source.contains("store.craftScentMask(quote)"))
        XCTAssertTrue(source.contains("That exact animal resource or the Reagent is no longer available."))
        XCTAssertTrue(source.contains("1 Reagent + 1 selected animal resource (grade 25+) · 0 Essence · 12 turns"))
    }

    func testScentMaskFieldKitDisclosesRuntimeTruthAndDoesNotOfferARefresh() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf: root.appendingPathComponent(
            "Sources/Screens/WorldView.swift"), encoding: .utf8)

        XCTAssertTrue(source.contains("run.scentMaskTurnsRemaining"))
        XCTAssertTrue(source.contains("run.isScentMasked"))
        XCTAssertTrue(source.contains("Already masked · "))
        XCTAssertTrue(source.contains("It does not hide creatures or affect apexes."))
        XCTAssertTrue(source.contains("case .maskScent:"))
    }

    func testScentMaskAcceptsEveryAnimalKindAt25AndRejectsFloraAndBelowFloor() {
        let animalKinds = MaterialFamilyID.allCases.filter(\.isAnimalWorldResource)
        XCTAssertEqual(Set(animalKinds), [.plate, .quill, .pelt, .down, .hide, .chitin,
                                          .feather, .fin, .scale, .oil, .shell, .horn, .venom,
                                          .fang, .tusk, .claw, .bone, .ichor])
        for kind in animalKinds {
            XCTAssertTrue(kind.isAnimalWorldResource)
            XCTAssertEqual(CraftMaterialUnitV1(kind: kind, properties: .init(), grade: 25,
                                               source: "animal").qualityBand, .standard)
        }
        XCTAssertTrue(MaterialFamilyID.allCases.filter { !$0.isAnimalWorldResource }.allSatisfy {
            [.timber, .fibre, .pulp, .toxin, .reagent].contains($0)
        })

        var state = scentMaskCraftingState()
        state.base.worldMaterialReserve.add(.init(id: .init(rawValue: "below"),
            sample: .init(kind: .hide, properties: .init(), grade: 24.999, source: "animal")))
        state.base.worldMaterialReserve.add(.init(id: .init(rawValue: "flora"),
            sample: .init(kind: .reagent, properties: .init(reactivity: 100), grade: 100,
                          source: "claims to be animal")))
        XCTAssertTrue(ConsumableCraftingRules.scentMaskAnimalResources(in: state).isEmpty)
    }

    func testScentMaskExactInstanceCommitIsAtomicAndCostsNoRealityCurrency() throws {
        var state = scentMaskCraftingState()
        let chosen = CraftMaterialHoldingV1(id: .init(rawValue: "chosen"),
            sample: .init(kind: .pelt, properties: .init(), grade: 25, source: "chosen beast"))
        let twin = CraftMaterialHoldingV1(id: .init(rawValue: "twin"), sample: chosen.sample)
        state.base.worldMaterialReserve.add(chosen)
        state.base.worldMaterialReserve.add(twin)
        let selection = try XCTUnwrap(state.base.worldMaterialReserve.selections().first {
            $0.unitID == chosen.id
        })
        let quote = try XCTUnwrap(ConsumableCraftingRules.previewScentMask(using: selection,
                                                                          in: state))
        let essence = state.base.essence
        let motes = state.reality.motes
        XCTAssertEqual(ConsumableCraftingRules.craftScentMask(quote, in: &state), .prepared)
        XCTAssertEqual(state.base.resources["reagent"], 0)
        XCTAssertEqual(state.base.essence, essence)
        XCTAssertEqual(state.reality.motes, motes)
        XCTAssertEqual(state.base.worldMaterialReserve.selections().map(\.unitID), [twin.id])
        XCTAssertEqual(state.base.inventory.stacks.first?.catalogID, Items.scentMask)

        var stale = scentMaskCraftingState()
        stale.base.worldMaterialReserve.add(chosen)
        _ = stale.base.worldMaterialReserve.consume([selection])
        let before = stale
        XCTAssertEqual(ConsumableCraftingRules.craftScentMask(quote, in: &stale), .stale)
        XCTAssertEqual(stale, before)
    }

    func testScentMaskFullStorehouseUsesOrdinarySpillover() throws {
        var state = scentMaskCraftingState()
        state.base.inventory = Inventory(slots: 0)
        let unit = CraftMaterialHoldingV1(id: .init(rawValue: "animal"),
            sample: .init(kind: .bone, properties: .init(), grade: 25, source: "animal"))
        state.base.worldMaterialReserve.add(unit)
        let quote = try XCTUnwrap(ConsumableCraftingRules.previewScentMask(
            using: try XCTUnwrap(state.base.worldMaterialReserve.selections().first), in: state))
        XCTAssertEqual(ConsumableCraftingRules.craftScentMask(quote, in: &state), .prepared)
        XCTAssertEqual(state.base.spillover.map(\.catalogID), [Items.scentMask])
    }

    func testScentMaskFieldKitPacksExactDesiredQuantityAsProtectedReturn() throws {
        var state = GameState.newGame()
        state.base.inventory = Inventory(slots: 4, stacks: [
            ItemStack(id: .init(rawValue: 90), catalogID: Items.scentMask, count: 2)
        ])
        state.base.preparationLoadout = [
            .init(itemID: Items.scentMask, desiredCount: 1, order: 0)
        ]
        state.base.preparationLoadoutNeedsReview = false
        guard case .allowed(let plan) = GameStore.fieldKitDepartureQuote(in: state) else {
            return XCTFail("Scent Mask was not packable as a supply")
        }
        XCTAssertEqual(plan.packed.stacks.first?.count, 1)
        XCTAssertEqual(plan.remainingInventory.stacks.first?.count, 1)

        var packed = plan.packed
        for index in packed.stacks.indices {
            packed.stacks[index].protectedReturnCount = packed.stacks[index].count
        }
        XCTAssertEqual(packed.stacks.first?.protectedReturnCount, 1)
    }
    func testApothecaryPreparationActionStaysOutsideScrollableRecipeCatalogue() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf: root.appendingPathComponent(
            "Sources/Screens/ApothecaryView.swift"), encoding: .utf8)

        XCTAssertTrue(source.contains(".safeAreaInset(edge: .bottom, spacing: 0) { preparationActionBar }"))
        XCTAssertTrue(source.contains("PersistentActionBar("))
        XCTAssertTrue(source.contains("Label(\"Prepare \\(name)\", systemImage: \"cross.vial.fill\")"))
        XCTAssertTrue(source.contains("store.craftConsumable(recipe)"))
        XCTAssertEqual(source.components(separatedBy: "store.craftConsumable(recipe)").count - 1, 1,
                       "the persistent action bar should own the sole preparation mutation")
        XCTAssertTrue(source.contains("if store.craftConsumable(recipe)"))
        XCTAssertTrue(source.contains("Preparation not made"))
        XCTAssertTrue(source.contains("The required stock changed."))
    }

    func testEveryApothecaryRecipeProducesAnAuthoredConsumableEffect() {
        for recipe in ConsumableCraftingRules.recipes {
            let item = ContentCatalog.shared.item(recipe.output)
            XCTAssertEqual(item?.kind, .consumable, recipe.output.rawValue)
            XCTAssertNotNil(item?.consumable, recipe.output.rawValue)
        }
    }

    func testApothecaryPresentationUsesAuthoredNamesAndNeverLeaksUnknownIDs() throws {
        let recipe = try XCTUnwrap(ConsumableCraftingRules.recipes.first)
        let item = try XCTUnwrap(ContentCatalog.shared.item(recipe.output))
        XCTAssertEqual(ConsumableRecipePresentation.displayName(for: recipe.output), item.name)

        let unknown: ItemID = "internal_missing_recipe_id"
        XCTAssertEqual(ConsumableRecipePresentation.displayName(for: unknown),
                       ConsumableRecipePresentation.unknownName)
        XCTAssertFalse(ConsumableRecipePresentation.displayName(for: unknown)
            .contains(unknown.rawValue))

        let unknownResource: ResourceID = "internal_missing_resource_id"
        XCTAssertEqual(ConsumableRecipePresentation.resourceName(for: unknownResource),
                       ConsumableRecipePresentation.unknownResourceName)
        XCTAssertFalse(ConsumableRecipePresentation.resourceName(for: unknownResource)
            .contains(unknownResource.rawValue))
    }

    func testRecipeUsesWeakestQualifyingNaturalStockAndNamedReagents() throws {
        var state = stockedState(for: "salve_lesser")
        let recipe = try XCTUnwrap(ConsumableCraftingRules.recipe("salve_lesser"))
        state.base.inventory.stacks = [ItemStack(
            id: InstanceID(rawValue: 800), catalogID: Items.material,
            materials: [sample(.flexibility, 90), sample(.flexibility, 26)])]
        state.base.worldMaterialReserve.migrateLegacyStacks(&state.base.inventory.stacks,
                                                       location: "fixture.consumable")
        state.base.resources.add(1, of: "resin")

        XCTAssertTrue(ConsumableCraftingRules.craft(recipe, in: &state))
        XCTAssertEqual(state.base.resources["resin"], 0)
        XCTAssertEqual(state.base.worldMaterialReserve.units.first?.sample.properties.flexibility, 90)
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
        XCTAssertEqual(recipe.essence, 12)
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
        XCTAssertEqual(store.state.reality.curioFamilyKnowledge["curio_humming_shard"]?.observationCount, 1)
    }

    func testContextlessUnknownCurioConsumesNothingAndTeachesNothing() throws {
        let store = GameStore(io: .temporary(name: "curio-contextless-\(UUID().uuidString)"))
        var state = fieldState(item: "field_ration")
        let unknown = ItemStack(id: .init(rawValue: 70_201), catalogID: "curio_humming_shard",
                                identified: false)
        _ = state.worlds.activeRun?.satchelItems.add(unknown)
        store.mutate("full-health curio fixture") { $0 = state }
        let before = store.state

        XCTAssertTrue(store.curioTryTargets(unknown).isEmpty)
        store.useItemInWorld(unknown, on: .binder)
        XCTAssertEqual(store.state, before)
        XCTAssertNil(store.state.reality.curioFamilyKnowledge[unknown.catalogID])
    }

    func testValidFieldTryAppliesHiddenHealingConsumesTurnAndRecordsFamily() throws {
        let store = GameStore(io: .temporary(name: "curio-field-try-\(UUID().uuidString)"))
        var state = fieldState(item: "field_ration")
        let unknown = ItemStack(id: .init(rawValue: 70_202), catalogID: "curio_humming_shard",
                                identified: false)
        state.worlds.activeRun?.binderHP = 5
        _ = state.worlds.activeRun?.satchelItems.add(unknown)
        store.mutate("wounded curio fixture") { $0 = state }
        let turn = try XCTUnwrap(store.activeRun?.turnsTaken)

        XCTAssertEqual(store.curioTryTargets(unknown), [.binder])
        store.useItemInWorld(unknown, on: .binder)

        XCTAssertEqual(store.activeRun?.turnsTaken, turn + 1)
        XCTAssertEqual(store.activeRun?.binderHP, 15)
        XCTAssertNil(store.activeRun?.satchelItems.stacks.first { $0.id == unknown.id })
        XCTAssertEqual(store.state.reality.curioFamilyKnowledge[unknown.catalogID]?.observationCount, 1)
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
        state.worlds.activeRun?.torchVisionBonus = 10
        var hiddenTraits = CreatureTraits()
        hiddenTraits.defence = .crypsis
        let hidden = WorldEnemy(id: InstanceID(rawValue: 910), traits: hiddenTraits,
                                position: GridPoint(x: 7, y: 14))
        let visibleTraits = CreatureTraits()
        let visible = WorldEnemy(id: InstanceID(rawValue: 911), traits: visibleTraits,
                                 position: GridPoint(x: 8, y: 7))
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
        onlyHidden.worlds.activeRun?.torchVisionBonus = 10
        onlyHidden.worlds.activeRun?.enemies = [hidden]
        onlyHidden.worlds.activeRun?.map[hidden.position].isRevealed = true
        let hiddenLure = try XCTUnwrap(onlyHidden.worlds.activeRun?.satchelItems.stacks.first?.id)
        let before = try XCTUnwrap(onlyHidden.worlds.activeRun?.turnsTaken)
        let blocked = WorldRules.useItem(hiddenLure, on: .binder, in: &onlyHidden)
        XCTAssertEqual(blocked, [.blocked("No visible roaming creature answers the lure.")])
        XCTAssertEqual(onlyHidden.worlds.activeRun?.turnsTaken, before)
        XCTAssertNotNil(onlyHidden.worlds.activeRun?.satchelItems.stacks.first)
    }

    func testApothecaryHasNessaLifecycleAndExactBuildCost() throws {
        let station = try XCTUnwrap(ContentCatalog.shared.station(Stations.apothecary))
        XCTAssertFalse(station.unlockedAtStart)
        XCTAssertEqual(station.builtBy, "nessa")
        XCTAssertEqual(station.buildCost?.essence, 85)
        XCTAssertEqual(station.buildCost?.resources,
                       ["clay": 16, "quartz": 6, "reagent": 12])
    }

    func testNessaRecruitmentExposesExactlyOneSiteWithoutBuildingIt() throws {
        let store = apothecaryStore()
        let station = try XCTUnwrap(ContentCatalog.shared.station(Stations.apothecary))
        XCTAssertFalse(store.buildableStations.contains { $0.id == Stations.apothecary })
        XCTAssertFalse(store.build(station))

        store.mutate("find Nessa") { $0.reality.library.foundTravellers.insert("nessa") }

        XCTAssertEqual(store.buildableStations.filter { $0.id == Stations.apothecary }.count, 1)
        XCTAssertFalse(store.state.base.station(Stations.apothecary).isUnlocked)
    }

    func testBuildAtomicallyPaysUnlocksAndTeachesOnlyLesserSalve() throws {
        let store = apothecaryStore()
        let station = try XCTUnwrap(ContentCatalog.shared.station(Stations.apothecary))
        let cost = try XCTUnwrap(station.buildCost)
        store.mutate("fund Apothecary") { state in
            state.reality.library.foundTravellers.insert("nessa")
            state.base.essence = cost.essence
            for (id, amount) in cost.resources { state.base.resources.add(amount, of: id) }
        }
        let inventoryBefore = store.state.base.inventory
        let spilloverBefore = store.state.base.spillover

        XCTAssertTrue(store.build(station))
        XCTAssertTrue(store.state.base.station(Stations.apothecary).isUnlocked)
        XCTAssertEqual(store.state.base.station(Stations.apothecary).tier, 0)
        XCTAssertEqual(store.state.base.knownConsumableRecipes, ["salve_lesser"])
        XCTAssertEqual(store.state.base.essence, 0)
        for id in cost.resources.keys { XCTAssertEqual(store.state.base.resources[id], 0) }
        XCTAssertEqual(store.state.base.inventory, inventoryBefore)
        XCTAssertEqual(store.state.base.spillover, spilloverBefore)
        XCTAssertFalse(store.build(station), "a repeated build charged or duplicated the station")
        XCTAssertEqual(store.state.base.knownConsumableRecipes, ["salve_lesser"])
    }

    func testShortApothecaryFundsChangeNothing() throws {
        let store = apothecaryStore()
        let station = try XCTUnwrap(ContentCatalog.shared.station(Stations.apothecary))
        store.mutate("find Nessa") { $0.reality.library.foundTravellers.insert("nessa") }
        let before = store.state

        XCTAssertFalse(store.build(station))
        XCTAssertEqual(store.state, before)
    }

    func testStaleSameIDApothecaryQuoteIsRejectedWithoutMutation() throws {
        let store = apothecaryStore()
        let canonical = try XCTUnwrap(ContentCatalog.shared.station(Stations.apothecary))
        let cost = try XCTUnwrap(canonical.buildCost)
        store.mutate("fund Apothecary") { state in
            state.reality.library.foundTravellers.insert("nessa")
            state.base.essence = cost.essence
            for (id, amount) in cost.resources { state.base.resources.add(amount, of: id) }
        }
        let funded = store.state

        var missingCost = canonical
        missingCost.buildCost = nil
        XCTAssertFalse(store.canAfford(missingCost))
        XCTAssertFalse(store.build(missingCost))
        XCTAssertEqual(store.state, funded)

        var lowerCost = canonical
        lowerCost.buildCost = UpgradeCost(essence: 1)
        XCTAssertFalse(store.canAfford(lowerCost))
        XCTAssertFalse(store.build(lowerCost))
        XCTAssertEqual(store.state, funded)
    }

    func testLegacyUnlockedApothecaryLearnsLesserSalveExactlyOnceOnDecode() throws {
        var state = GameState.newGame()
        state.base.stations[Stations.apothecary] = StationState(isUnlocked: true, tier: 0)
        XCTAssertTrue(state.base.knownConsumableRecipes.isEmpty)

        let restored = try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(state))
        let restoredAgain = try JSONDecoder().decode(GameState.self,
                                                     from: JSONEncoder().encode(restored))

        XCTAssertEqual(restored.base.knownConsumableRecipes, ["salve_lesser"])
        XCTAssertEqual(restoredAgain.base.knownConsumableRecipes, ["salve_lesser"])
        XCTAssertTrue(restored.base.inventory.stacks.isEmpty)
        XCTAssertTrue(restored.base.spillover.isEmpty)
        XCTAssertEqual(restored.base.station(Stations.apothecary).tier, 0)
    }

    func testEveryRecipeUsesLiveCatalogueResourceIDsAndSettledEssenceCosts() {
        let expectedSpecialCosts: [ItemID: Int] = ["stillwater": 6, "waystone": 12]
        for recipe in ConsumableCraftingRules.recipes {
            XCTAssertNotNil(ContentCatalog.shared.item(recipe.output), recipe.output.rawValue)
            for id in recipe.resources.keys {
                XCTAssertNotNil(ContentCatalog.shared.resource(id),
                                "\(recipe.output.rawValue) uses unknown resource \(id.rawValue)")
            }
            XCTAssertEqual(recipe.essence, expectedSpecialCosts[recipe.output] ?? 0,
                           recipe.output.rawValue)
        }
        XCTAssertEqual(ConsumableCraftingRules.recipe("waystone")?.motes, 1)
    }

    func testCoatingsUseSettledExactRecipes() throws {
        let venom = try XCTUnwrap(ConsumableCraftingRules.recipe("venom"))
        let firebrand = try XCTUnwrap(ConsumableCraftingRules.recipe("firebrand"))
        let briarOil = try XCTUnwrap(ConsumableCraftingRules.recipe("briar_oil"))
        let flashsalt = try XCTUnwrap(ConsumableCraftingRules.recipe("flashsalt"))

        XCTAssertEqual(venom.resources, ["toxin": 1, "fiber": 1])
        XCTAssertEqual(firebrand.resources, ["reagent": 1, "sulfur": 1])
        XCTAssertEqual(briarOil.resources, ["fiber": 1, "resin": 1])
        XCTAssertEqual(flashsalt.resources, ["reagent": 1, "mercury": 1])
        XCTAssertEqual([venom, firebrand, briarOil, flashsalt].map(\.essence), [0, 0, 0, 0])
    }

    func testPartialSuggestiveStockInfersAndPersistsAnotherRecipe() throws {
        let store = apothecaryStore()
        store.mutate("built Apothecary with suggestive stock") { state in
            state.base.stations[Stations.apothecary] = StationState(isUnlocked: true, tier: 0)
            var properties = MaterialProperties()
            properties.lustre = 61
            state.base.inventory.stacks = [ItemStack(
                id: InstanceID(rawValue: 700), catalogID: Items.material,
                materials: [CraftMaterialUnitV1(kind: .reagent, properties: properties,
                                           grade: 61, source: "test")])]
            state.base.worldMaterialReserve.migrateLegacyStacks(&state.base.inventory.stacks,
                                                           location: "fixture.inference")
            state.base.resources.add(1, of: "mercury")
        }

        store.discoverConsumableRecipes()

        XCTAssertTrue(store.state.base.knownConsumableRecipes.contains("stillwater"))
        XCTAssertFalse(ConsumableCraftingRules.shortfall(
            try XCTUnwrap(ConsumableCraftingRules.recipe("stillwater")), in: store.state
        ).isEmpty)
        let restored = try JSONDecoder().decode(GameState.self,
                                                from: JSONEncoder().encode(store.state))
        XCTAssertTrue(restored.base.knownConsumableRecipes.contains("stillwater"))
    }

    private func stockedState(for recipe: ItemID) -> GameState {
        var state = GameState.newGame()
        state.base.essence = 500
        state.base.inventory.slots = 20
        state.base.knownConsumableRecipes.insert(recipe)
        return state
    }

    private func scentMaskCraftingState() -> GameState {
        var state = GameState.newGame()
        state.base.stations[Stations.apothecary] = .init(isUnlocked: true, tier: 0)
        state.base.knownConsumableRecipes.insert(Items.scentMask)
        state.base.resources.add(1, of: "reagent")
        return state
    }

    private func apothecaryStore() -> GameStore {
        GameStore(io: .temporary(name: "apothecary-reachability-\(UUID().uuidString)"))
    }

    private func sample(_ property: MaterialProperty, _ value: Double) -> CraftMaterialUnitV1 {
        var properties = MaterialProperties()
        properties[property] = value
        return CraftMaterialUnitV1(kind: .reagent, properties: properties, grade: value, source: "test")
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
