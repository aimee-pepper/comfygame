import XCTest
import CryptoKit
@testable import Bookbinder

/// Worldgen determinism, movement, decay, and the rules that end a run.
final class WorldTests: XCTestCase {

    private let owned = Set(ContentCatalog.shared.starterSymbolIDs)

    private func book(_ symbols: [SlotID: SymbolID]) -> BoundBook {
        BoundBook(symbols: symbols, randomlyFilled: [], essencePaid: 0)
    }

    private func wildPageRun(seed: UInt64) -> WorldRun {
        WorldRun(runIndex: 3, book: book([:]), mapSeed: seed,
                 rng: SeededRNG(seed: seed),
                 map: WorldMap(width: 2, height: 2,
                               tiles: Array(repeating: Tile(), count: 4),
                               entry: GridPoint(x: 0, y: 0)),
                 playerPosition: GridPoint(x: 0, y: 0))
    }

    // MARK: Worldgen

    func testWildWorldPageSelectionIsDeterministicOrderIndependentAndPityGuaranteed() throws {
        let context = WildWorldPageSelectionRules.Context(
            resolvedExpeditions: 5, drought: 5, ownedCopies: [:],
            worldContextTags: ["hydrology", "atmosphere"], suppressesRandomPage: false)
        let first = try XCTUnwrap(WildWorldPageSelectionRules.select(seed: 991, context: context))
        let second = try XCTUnwrap(WildWorldPageSelectionRules.select(
            seed: 991, context: context,
            definitions: Array(WorldPageCatalog.repeatableDefinitions.reversed())))
        XCTAssertEqual(first, second)
        XCTAssertNotEqual(first.instanceID.rawValue, 0)
        XCTAssertEqual(first.definition.id, WorldPageCatalog.definition(first.definition.id)?.id)

        var collision = context
        collision.occupiedInstanceIDs = [first.instanceID]
        let advanced = try XCTUnwrap(WildWorldPageSelectionRules.select(seed: 991,
                                                                         context: collision))
        XCTAssertNotEqual(advanced.instanceID, first.instanceID)
        XCTAssertEqual(advanced.definition, first.definition,
                       "identity collision handling must not reroll authored content")
    }

    func testWildWorldPageSelectionHonoursPacingCopyLimitAndSuppression() {
        let base = WildWorldPageSelectionRules.Context(
            resolvedExpeditions: 1, drought: 5, ownedCopies: [:], worldContextTags: [],
            suppressesRandomPage: false)
        let early = WildWorldPageSelectionRules.select(seed: 4, context: base)
        XCTAssertNotNil(early)
        XCTAssertEqual(early?.definition.minimumResolvedExpeditions, 1)

        var capped = base
        capped.ownedCopies = Dictionary(uniqueKeysWithValues:
            WorldPageCatalog.repeatableDefinitions.map { ($0.id, 2) })
        XCTAssertNil(WildWorldPageSelectionRules.select(seed: 4, context: capped))

        var suppressed = base
        suppressed.suppressesRandomPage = true
        XCTAssertNil(WildWorldPageSelectionRules.select(seed: 4, context: suppressed))

        var opening = base
        opening.resolvedExpeditions = 0
        XCTAssertNil(WildWorldPageSelectionRules.select(seed: 4, context: opening))
    }

    func testWildWorldPageContextWeightingDoesNotEliminateBaselineCandidates() {
        let context = WildWorldPageSelectionRules.Context(
            resolvedExpeditions: 5, drought: 5, ownedCopies: [:],
            worldContextTags: ["hydrology"], suppressesRandomPage: false)
        let selected = (0..<512).compactMap {
            WildWorldPageSelectionRules.select(seed: UInt64($0), context: context)?.definition
        }
        XCTAssertEqual(selected.count, 512)
        XCTAssertTrue(selected.contains { $0.contextTags.contains("hydrology") })
        XCTAssertTrue(selected.contains { !$0.contextTags.contains("hydrology") },
                      "3x context weighting must not make other repeatables unreachable")
    }

    func testWildPagePlacementIsDeterministicReachableAndNeverDisplacesWriting() throws {
        let selection = try XCTUnwrap(WildWorldPageSelectionRules.select(
            seed: 991,
            context: .init(resolvedExpeditions: 5, drought: 5, ownedCopies: [:],
                           worldContextTags: ["hydrology"], suppressesRandomPage: false)))
        var map = WorldMap(width: 4, height: 3,
                           tiles: Array(repeating: Tile(), count: 12),
                           entry: GridPoint(x: 0, y: 1))
        map[map.entry].content = .portal(isEntry: true)
        let writing = GridPoint(x: 1, y: 1)
        map[writing].content = .foundWriting("guaranteed")
        map[GridPoint(x: 2, y: 0)].ground = .chasm
        map[GridPoint(x: 2, y: 1)].ground = .chasm
        map[GridPoint(x: 2, y: 2)].ground = .chasm

        let first = try XCTUnwrap(WildWorldPagePlacementRules.place(
            selection, originRunIndex: 6, originWorldSeed: 991, in: map))
        let second = WildWorldPagePlacementRules.place(
            selection, originRunIndex: 6, originWorldSeed: 991, in: map)
        XCTAssertEqual(first, second)
        XCTAssertNotEqual(first.fieldProvenance?.position, map.entry)
        XCTAssertNotEqual(first.fieldProvenance?.position, writing)
        XCTAssertLessThan(first.fieldProvenance?.position.x ?? 99, 2,
                          "the host must be in the start-connected region")
        XCTAssertEqual(map[writing].content, .foundWriting("guaranteed"))
    }

    func testWildPagePlacementFailsClosedWhenNoReachableEmptyHostExists() throws {
        let selection = try XCTUnwrap(WildWorldPageSelectionRules.select(
            seed: 992,
            context: .init(resolvedExpeditions: 5, drought: 5, ownedCopies: [:],
                           worldContextTags: [], suppressesRandomPage: false)))
        var map = WorldMap(width: 1, height: 1, tiles: [Tile()], entry: GridPoint(x: 0, y: 0))
        map[map.entry].content = .portal(isEntry: true)
        XCTAssertNil(WildWorldPagePlacementRules.place(
            selection, originRunIndex: 6, originWorldSeed: 992, in: map))
    }

    func testWorldgenReservesWildPageAfterGuaranteedWritingBeforeOptionalContent() throws {
        let selection = try XCTUnwrap(WildWorldPageSelectionRules.select(
            seed: 1_404,
            context: .init(resolvedExpeditions: 5, drought: 5, ownedCopies: [:],
                           worldContextTags: [], suppressesRandomPage: false)))
        let generated = Worldgen.generate(
            book: book([:]), seed: 1_404, wildPageSelection: selection,
            wildPageOriginRunIndex: 6)
        let page = try XCTUnwrap(generated.wildPage)
        let point = try XCTUnwrap(page.fieldProvenance?.position)
        XCTAssertTrue(generated.diagnostics.writingWasGuaranteed)
        XCTAssertFalse(generated.pages.isEmpty && generated.writings.isEmpty)
        XCTAssertEqual(generated.map[point].content, .empty,
                       "later optional placement must preserve the reserved overlay host")
        XCTAssertEqual(page.fieldProvenance?.originRunIndex, 6)
        XCTAssertEqual(page.fieldProvenance?.originWorldSeed, 1_404)
    }

    func testStarterPagesPlaceExactDisclosedTierOneFindSafelyNearEntry() throws {
        for instance in WorldPageCatalog.starterInstances {
            let book = BookRules.resolveBook(worldPage: instance)
            let first = Worldgen.generate(book: book, seed: instance.definition.seed)
            let second = Worldgen.generate(book: book, seed: instance.definition.seed)
            let finds = first.map.allPoints.compactMap { point -> (GridPoint, ItemStack)? in
                guard case .item(let stack) = first.map[point].content else { return nil }
                return (point, stack)
            }
            XCTAssertEqual(finds.count, 1)
            let find = try XCTUnwrap(finds.first)
            XCTAssertEqual(find.1.catalogID, instance.definition.knownFind)
            XCTAssertEqual(find.1.id, StarterKnownFindPlacementRules.stableInstanceID(
                for: try XCTUnwrap(book.worldPageUseReceipt)))
            XCTAssertEqual(first.map[find.0], second.map[find.0])
            XCTAssertTrue(first.map[find.0].isRevealed)
            XCTAssertTrue(first.map[find.0].isPassable)
            XCTAssertEqual(first.map[find.0].ground.movementCost, 1)
            var distance: [GridPoint: Int] = [first.map.entry: 0]
            var queue = [first.map.entry]
            while !queue.isEmpty, distance[find.0] == nil {
                let point = queue.removeFirst()
                for next in first.map.neighbours(of: point)
                where distance[next] == nil && first.map[next].isPassable {
                    distance[next] = distance[point, default: 0] + 1
                    queue.append(next)
                }
            }
            XCTAssertTrue((1...2).contains(try XCTUnwrap(distance[find.0])))
        }
    }

    func testKnownFindPickupIsAtomicAndLeavesExactItemWhenSatchelIsFull() throws {
        let destination = GridPoint(x: 1, y: 0)
        let promised = ItemStack(id: InstanceID(rawValue: 4_444), catalogID: "field_maul")
        var map = WorldMap(width: 2, height: 1,
                           tiles: [Tile(content: .portal(isEntry: true), isRevealed: true),
                                   Tile(content: .item(promised), isRevealed: true)],
                           entry: GridPoint(x: 0, y: 0))
        var fullRun = WorldRun(runIndex: 1, book: book([:]), mapSeed: 1,
                               rng: SeededRNG(seed: 1), map: map,
                               playerPosition: map.entry,
                               satchelItems: Inventory(slots: 1, stacks: [
                                ItemStack(id: InstanceID(rawValue: 9), catalogID: "bone_awl")
                               ]))
        var fullState = GameState.newGame()
        fullState.worlds.activeRun = fullRun

        let refusal = WorldRules.step(to: destination, in: &fullState)
        XCTAssertTrue(refusal.contains { if case .satchelFull = $0 { true } else { false } })
        XCTAssertEqual(fullState.worlds.activeRun?.map[destination].content, .item(promised))
        XCTAssertEqual(fullState.worlds.activeRun?.satchelItems.stacks.count, 1)

        map[destination].content = .item(promised)
        fullRun = WorldRun(runIndex: 1, book: book([:]), mapSeed: 1,
                           rng: SeededRNG(seed: 1), map: map,
                           playerPosition: map.entry, satchelItems: Inventory(slots: 1))
        var openState = GameState.newGame()
        openState.worlds.activeRun = fullRun
        let pickup = WorldRules.step(to: destination, in: &openState)
        XCTAssertTrue(pickup.contains { if case .pickedUpItem = $0 { true } else { false } })
        XCTAssertEqual(openState.worlds.activeRun?.map[destination].content, .empty)
        XCTAssertEqual(openState.worlds.activeRun?.satchelItems.stacks, [promised])
    }

    func testWorldRunKeepsPagesSeparateWhileChargingSharedSatchelSlots() throws {
        let definition = try XCTUnwrap(WorldPageCatalog.definition("wild_moss_and_mist"))
        let page = WorldPageInstance(id: InstanceID(rawValue: 700), definition: definition,
                                     fieldProvenance: .init(originRunIndex: 2,
                                                            originWorldSeed: 20,
                                                            generationSeed: 30,
                                                            position: GridPoint(x: 1, y: 1)))
        var run = WorldRun(runIndex: 2, book: book([:]), mapSeed: 20,
                           rng: SeededRNG(seed: 20),
                           map: WorldMap(width: 2, height: 2,
                                         tiles: Array(repeating: Tile(), count: 4),
                                         entry: GridPoint(x: 0, y: 0)),
                           playerPosition: GridPoint(x: 0, y: 0),
                           satchelItems: Inventory(slots: 2), carriedWorldPages: [page])
        XCTAssertEqual(run.occupiedSatchelSlots, 1)
        XCTAssertEqual(run.freeSatchelSlots, 1)
        run.offeredWorldPages = [WorldPageInstance(id: InstanceID(rawValue: 701),
                                                   definition: definition)]
        XCTAssertEqual(run.freeSatchelSlots, 1, "offered pages do not occupy the satchel")

        let restored = try SaveCodec.makeDecoder().decode(
            WorldRun.self, from: SaveCodec.makeEncoder().encode(run))
        XCTAssertEqual(restored.carriedWorldPages, [page])
        XCTAssertEqual(restored.offeredWorldPages.map(\.id), [InstanceID(rawValue: 701)])
        XCTAssertTrue(restored.anchoredSnapshot.carriedWorldPages.isEmpty)
        XCTAssertTrue(restored.anchoredSnapshot.offeredWorldPages.isEmpty)
    }

    func testLegacyWorldStateAndRunDecodeWithNoWildPagePayload() throws {
        var worldsObject = try XCTUnwrap(JSONSerialization.jsonObject(
            with: SaveCodec.makeEncoder().encode(
                WorldsState(activeRun: nil, runIndex: 3,
                            seeds: SeedSequence(rootSeed: 9)))) as? [String: Any])
        worldsObject.removeValue(forKey: "randomWorldPageDrought")
        worldsObject.removeValue(forKey: "worldPageBankedOutcomeIDs")
        let worlds = try SaveCodec.makeDecoder().decode(
            WorldsState.self, from: JSONSerialization.data(withJSONObject: worldsObject))
        XCTAssertEqual(worlds.randomWorldPageDrought, 0)
        XCTAssertEqual(worlds.worldPageBankedOutcomeIDs, [])
    }

    func testWildPageInspectAndTakeRevalidateExactPhysicalInstanceAtomically() throws {
        let definition = try XCTUnwrap(WorldPageCatalog.definition("wild_moss_and_mist"))
        let position = GridPoint(x: 1, y: 1)
        let page = WorldPageInstance(
            id: InstanceID(rawValue: 880), definition: definition,
            fieldProvenance: .init(originRunIndex: 3, originWorldSeed: 44, generationSeed: 55,
                                   position: position))
        var run = wildPageRun(seed: 44)
        run.playerPosition = position
        run.map[position].isRevealed = true
        run.offeredWorldPages = [page]

        let quote = try XCTUnwrap(WildWorldPageFieldRules.quote(page.id, in: run))
        XCTAssertEqual(WildWorldPageFieldRules.inspect(quote, in: &run),
                       .inspected(WorldPageInstance(id: page.id, definition: definition,
                                                    inspected: true,
                                                    fieldProvenance: page.fieldProvenance)))
        let staleUninspectedQuote = quote
        let beforeStale = run
        XCTAssertEqual(WildWorldPageFieldRules.take(staleUninspectedQuote, in: &run), .stale)
        XCTAssertEqual(run, beforeStale)

        let fresh = try XCTUnwrap(WildWorldPageFieldRules.quote(page.id, in: run))
        guard case .taken(let taken) = WildWorldPageFieldRules.take(fresh, in: &run) else {
            return XCTFail("expected exact page to be taken")
        }
        XCTAssertTrue(taken.inspected)
        XCTAssertEqual(run.carriedWorldPages, [taken])
        XCTAssertTrue(run.offeredWorldPages.isEmpty)
    }

    func testWildPageTakeRefusesFullSatchelWrongTileAndDuplicateWithoutMutation() throws {
        let definition = try XCTUnwrap(WorldPageCatalog.definition("wild_storm_coast"))
        let position = GridPoint(x: 1, y: 1)
        let page = WorldPageInstance(
            id: InstanceID(rawValue: 881), definition: definition,
            fieldProvenance: .init(originRunIndex: 3, originWorldSeed: 44, generationSeed: 55,
                                   position: position))
        var run = wildPageRun(seed: 44)
        run.playerPosition = position
        run.map[position].isRevealed = true
        run.offeredWorldPages = [page]
        let quote = try XCTUnwrap(WildWorldPageFieldRules.quote(page.id, in: run))

        run.playerPosition = GridPoint(x: 0, y: 0)
        XCTAssertNil(WildWorldPageFieldRules.quote(page.id, in: run))
        run.playerPosition = position
        run.satchelItems.slots = 0
        let full = run
        XCTAssertEqual(WildWorldPageFieldRules.take(quote, in: &run), .satchelFull)
        XCTAssertEqual(run, full)

        run.satchelItems.slots = 1
        run.carriedWorldPages = [page]
        let duplicate = run
        XCTAssertEqual(WildWorldPageFieldRules.take(quote, in: &run), .duplicateIdentity)
        XCTAssertEqual(run, duplicate)
    }

    func testWildPageFullSatchelSwapRevalidatesExactOccupantWithoutLoss() throws {
        let definition = try XCTUnwrap(WorldPageCatalog.definition("wild_storm_coast"))
        let point = GridPoint(x: 1, y: 1)
        let offered = WorldPageInstance(
            id: InstanceID(rawValue: 890), definition: definition, inspected: true,
            fieldProvenance: .init(originRunIndex: 3, originWorldSeed: 44,
                                   generationSeed: 55, position: point))
        var run = wildPageRun(seed: 44)
        run.playerPosition = point
        run.map[point].isRevealed = true
        run.offeredWorldPages = [offered]
        run.satchelItems.slots = 1
        let stack = ItemStack(id: InstanceID(rawValue: 891), catalogID: "salve", count: 2)
        _ = run.satchelItems.add(stack)
        let quote = try XCTUnwrap(WildWorldPageFieldRules.quote(offered.id, in: run))

        let staleBefore = run
        XCTAssertEqual(WildWorldPageFieldRules.swap(
            quote, discarding: .itemStack(InstanceID(rawValue: 999)), in: &run), .stale)
        XCTAssertEqual(run, staleBefore)

        XCTAssertEqual(WildWorldPageFieldRules.swap(
            quote, discarding: .itemStack(stack.id), in: &run),
            .swapped(offered, discarded: .itemStack(stack)))
        XCTAssertEqual(run.carriedWorldPages, [offered])
        XCTAssertTrue(run.offeredWorldPages.isEmpty)
        XCTAssertTrue(run.satchelItems.stacks.isEmpty)
        XCTAssertEqual(run.occupiedSatchelSlots, 1)
    }

    @MainActor
    func testStoreInspectionTeachesOnlyAfterExactVisibleQuoteCommits() throws {
        let definition = try XCTUnwrap(WorldPageCatalog.definition("wild_gilded_caverns"))
        let position = GridPoint(x: 1, y: 1)
        let page = WorldPageInstance(
            id: InstanceID(rawValue: 882), definition: definition,
            fieldProvenance: .init(originRunIndex: 3, originWorldSeed: 45,
                                   generationSeed: 56, position: position))
        var run = wildPageRun(seed: 45)
        run.playerPosition = position
        run.map[position].isRevealed = true
        run.offeredWorldPages = [page]
        let store = GameStore(io: .temporary(name: "wild-page-field-\(UUID().uuidString)"))
        store.mutate("install wild page fixture") { $0.worlds.activeRun = run }

        let quote = try XCTUnwrap(store.offeredWorldPageQuote(page.id))
        XCTAssertEqual(store.state.reality.encounteredLexemes, [])
        guard case .inspected = store.inspectOfferedWorldPage(quote) else {
            return XCTFail("expected inspection")
        }
        XCTAssertEqual(store.state.reality.encounteredLexemes,
                       definition.page.encounteredLexemes)

        let afterInspectionRun = store.state.worlds.activeRun
        let afterInspectionLexemes = store.state.reality.encounteredLexemes
        XCTAssertEqual(store.takeOfferedWorldPage(quote), .stale)
        XCTAssertEqual(store.state.worlds.activeRun, afterInspectionRun)
        XCTAssertEqual(store.state.reality.encounteredLexemes, afterInspectionLexemes)
        let fresh = try XCTUnwrap(store.offeredWorldPageQuote(page.id))
        guard case .taken(let taken) = store.takeOfferedWorldPage(fresh) else {
            return XCTFail("expected exact take")
        }
        XCTAssertEqual(store.state.worlds.activeRun?.carriedWorldPages, [taken])
    }

    func testWildPagesShareOneFailureBudgetWithItemsAndBankIdempotently() throws {
        let firstDefinition = try XCTUnwrap(WorldPageCatalog.definition("wild_moss_and_mist"))
        let secondDefinition = try XCTUnwrap(WorldPageCatalog.definition("wild_storm_coast"))
        var run = wildPageRun(seed: 71)
        run.runIndex = 4
        run.carriedWorldPages = [
            WorldPageInstance(id: InstanceID(rawValue: 901), definition: firstDefinition),
            WorldPageInstance(id: InstanceID(rawValue: 902), definition: secondDefinition)
        ]
        _ = run.satchelItems.add(ItemStack(id: InstanceID(rawValue: 903),
                                           catalogID: "salve", count: 2))
        var state = GameState.newGame()
        state.worlds.randomWorldPageDrought = 4
        let beforeStarterCount = state.base.collectedWorldPages.count

        let first = GameStore.bankHaul(of: run, outcomeID: 71, into: &state, fraction: 0.5)
        let keptItemUnits = first.items.reduce(0) { $0 + $1.count }
        XCTAssertEqual(keptItemUnits + first.keptWorldPages.count, 2,
                       "ceil(4 × 0.5) is one outcome-wide object budget")
        XCTAssertEqual(first.keptWorldPages.count + first.lostWorldPages.count, 2)
        XCTAssertEqual(state.base.collectedWorldPages.count,
                       beforeStarterCount + first.keptWorldPages.count)
        XCTAssertEqual(state.worlds.randomWorldPageDrought,
                       first.keptWorldPages.isEmpty ? 5 : 0)

        let afterFirst = state
        let replay = GameStore.bankHaul(of: run, outcomeID: 71, into: &state, fraction: 0.5)
        XCTAssertEqual(replay.keptWorldPages, first.keptWorldPages)
        XCTAssertEqual(replay.lostWorldPages, first.lostWorldPages)
        XCTAssertEqual(state.base.collectedWorldPages, afterFirst.base.collectedWorldPages)
        XCTAssertEqual(state.worlds.randomWorldPageDrought,
                       afterFirst.worlds.randomWorldPageDrought)
        XCTAssertEqual(state.worlds.worldPageBankedOutcomeIDs, [71])

        let receipt = GameStore.makeReturnReceipt(
            run: run, outcomeID: 71, kind: .collapse, reason: "fixture", fraction: 0.5,
            banked: first, autoRefinedRaw: 0, autoRefinedEssence: 0, springYield: 0,
            state: state)
        let restored = try SaveCodec.makeDecoder().decode(
            RunExitSummary.self, from: SaveCodec.makeEncoder().encode(receipt))
        XCTAssertEqual(restored.keptWorldPages, first.keptWorldPages)
        XCTAssertEqual(restored.lostWorldPages, first.lostWorldPages)
    }

    func testProtectedWildPageIsKeptOutsideZeroFailureBudget() throws {
        var definition = try XCTUnwrap(WorldPageCatalog.definition("wild_mote_understone"))
        definition.disposition = .uniqueProtected
        var run = wildPageRun(seed: 72)
        run.runIndex = 4
        let page = WorldPageInstance(id: InstanceID(rawValue: 904), definition: definition)
        run.carriedWorldPages = [page]
        var state = GameState.newGame()
        let banked = GameStore.bankHaul(of: run, outcomeID: 72, into: &state, fraction: 0)
        XCTAssertEqual(banked.keptWorldPages, [page])
        XCTAssertTrue(banked.lostWorldPages.isEmpty)
    }

    func testSameSeedRegeneratesTheSameWorld() {
        let composition = book(["terrain": "caverns", "biome": "ashen", "bounty": "rich_ore", "quirk": "gilded_veins"])
        let first = Worldgen.generate(book: composition, seed: 8_675_309)
        let second = Worldgen.generate(book: composition, seed: 8_675_309)

        XCTAssertEqual(first.map, second.map)
        XCTAssertEqual(first.enemies, second.enemies)
        XCTAssertEqual(first.start, second.start)
    }

    func testDifferentSeedsGiveDifferentWorlds() {
        let composition = book(["terrain": "plains"])
        XCTAssertNotEqual(Worldgen.generate(book: composition, seed: 1).map,
                          Worldgen.generate(book: composition, seed: 2).map)
    }

    func testNativeMapTerrainSeedUsesFrozenPayloadAndFNV1a() {
        XCTAssertEqual(MapAssetContract.terrainSeed(mapSeed: 0, point: GridPoint(x: 0, y: 0)), 1_940_317_494)
        XCTAssertEqual(MapAssetContract.terrainSeed(mapSeed: 0, point: GridPoint(x: 0, y: 0)) & 3, 2)
        XCTAssertEqual(MapAssetContract.terrainSeed(mapSeed: .max, point: GridPoint(x: 10, y: 10)), 3_919_347_185)
        XCTAssertEqual(MapAssetContract.terrainSeed(mapSeed: .max, point: GridPoint(x: 10, y: 10)) & 3, 1)
    }

    func testNativeMapWorldGradeMatchesCrossLanguageVectors() {
        func readings(thermal: Double, water: Double, life: Double, light: Double, mineral: Double) -> PressureReadings {
            func reading(_ id: PressureTargetID, _ value: Double) -> PressureReading {
                PressureReading(target: id, peak: value, demand: value, floor: value,
                                opposedMagnitude: 0, aspects: [:], forms: [:], tags: [])
            }
            return PressureReadings(readings: [
                "thermal": reading("thermal", thermal), "hydrology": reading("hydrology", water),
                "vitality": reading("vitality", life), "illumination": reading("illumination", light),
                "substrate": reading("substrate", mineral)
            ])
        }
        XCTAssertEqual(WorldGrade.from(readings(thermal: 50, water: 50, life: 50, light: 50, mineral: 50)),
                       WorldGrade(red: 0, green: 0, blue: 0, value: 0))
        XCTAssertEqual(WorldGrade.from(readings(thermal: 90, water: 20, life: 25, light: 80, mineral: 75)),
                       WorldGrade(red: 23, green: -16, blue: -18, value: 12))
        XCTAssertEqual(WorldGrade.from(readings(thermal: 10, water: 90, life: 85, light: 20, mineral: 30)),
                       WorldGrade(red: -22, green: 22, blue: 22, value: -11))
    }

    func testNativeMapPinsCorrectedCanonicalManifest() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let data = try Data(contentsOf: root.appendingPathComponent("AssetLab/integration/lifted-terrain-v1/manifest.json"))
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(json["canonicalManifestSha256"] as? String, MapAssetContract.manifestSHA256)
        let profile = try XCTUnwrap(json["profile"] as? [String: Any])
        XCTAssertEqual(profile["pixelWidth"] as? Int, MapAssetContract.spriteWidth)
        XCTAssertEqual(profile["pixelHeight"] as? Int, MapAssetContract.spriteHeight)
    }

    @MainActor
    func testNativeFloraAdapterMatchesPublishedLiveVectorsAndKeysNormalizedTraits() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let data = try Data(contentsOf: root.appendingPathComponent("AssetLab/integration/map-slice-v1/manifest.json"))
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let contract = try XCTUnwrap(json["liveInputContract"] as? [String: Any])
        let vectors = try XCTUnwrap(contract["floraFixtureVectors"] as? [[String: Any]])

        func flora(from vector: [String: Any]) throws -> Flora {
            let swift = try XCTUnwrap(vector["swift"] as? [String: Any])
            let idObject = try XCTUnwrap(swift["id"] as? [String: Any])
            let id = UInt64(try XCTUnwrap(idObject["rawValue"] as? String))!
            let seed = UInt64(try XCTUnwrap(swift["worldSeed"] as? String))!
            let source = try XCTUnwrap(swift["traits"] as? [String: Any])
            let tissue = try XCTUnwrap(source["tissue"] as? [String: Any])
            let colour = try XCTUnwrap(source["coloration"] as? [String: Any])
            let finish = try XCTUnwrap(source["finish"] as? [String: Any])
            var traits = FloraTraits()
            traits.stature = try XCTUnwrap(source["stature"] as? Double)
            traits.tissue.woody = try XCTUnwrap(tissue["woody"] as? Double)
            traits.tissue.fibrous = try XCTUnwrap(tissue["fibrous"] as? Double)
            traits.tissue.fleshy = try XCTUnwrap(tissue["fleshy"] as? Double)
            traits.defence = try XCTUnwrap(source["defence"] as? Double)
            traits.defenceType = try XCTUnwrap(DefenceType(rawValue: try XCTUnwrap(source["defenceType"] as? String)))
            traits.habit = try XCTUnwrap(Habit(rawValue: try XCTUnwrap(source["habit"] as? String)))
            traits.coloration.cyan = try XCTUnwrap(colour["cyan"] as? Double)
            traits.coloration.magenta = try XCTUnwrap(colour["magenta"] as? Double)
            traits.coloration.yellow = try XCTUnwrap(colour["yellow"] as? Double)
            traits.coloration.depth = try XCTUnwrap(colour["depth"] as? Double)
            traits.coloration.patterning = try XCTUnwrap(colour["patterning"] as? Double)
            traits.finish.opacity = try XCTUnwrap(finish["opacity"] as? Double)
            traits.finish.shine = try XCTUnwrap(finish["shine"] as? Double)
            traits.finish.schiller = try XCTUnwrap(finish["schiller"] as? Double)
            traits.metabolism = try XCTUnwrap(Metabolism(rawValue: try XCTUnwrap(source["metabolism"] as? String)))
            return Flora(id: InstanceID(rawValue: id), traits: traits, worldSeed: seed)
        }

        XCTAssertEqual(vectors.count, 2)
        for vector in vectors {
            let flora = try flora(from: vector)
            let pixels = MapAssetTestSupport.floraPixels(flora)
            let actual = SHA256.hash(data: Data(pixels)).map { String(format: "%02x", $0) }.joined()
            XCTAssertEqual(actual, vector["pixelSha256"] as? String)
        }

        let original = try flora(from: vectors[0])
        var changedTraits = original.traits
        changedTraits.coloration.cyan += 10
        let changed = Flora(id: original.id, traits: changedTraits, worldSeed: original.worldSeed)
        XCTAssertNotEqual(MapAssetTestSupport.floraCacheKey(original), MapAssetTestSupport.floraCacheKey(changed))
        XCTAssertNotEqual(MapAssetTestSupport.floraPixels(original), MapAssetTestSupport.floraPixels(changed))
    }

    @MainActor
    func testNativeLiftedTerrainRasterMatchesFrozenAssetLabConformanceFixtures() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let data = try Data(contentsOf: root.appendingPathComponent("AssetLab/integration/lifted-terrain-v1/manifest.json"))
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let outputs = try XCTUnwrap(json["outputs"] as? [[String: Any]])
        let vectors: [(GroundType, Int, UInt32, Int, WorldGrade, Int, Int, Bool)] = [
            (.soil, 15, 82_734_192, 2, WorldGrade(red: 14, green: 3, blue: -12, value: -4), 2, 1, false),
            (.stone, 6, 305_419_896, 3, WorldGrade(red: -22, green: 22, blue: 22, value: -11), 3, 3, true)
        ]
        XCTAssertEqual(outputs.count, vectors.count)
        for (output, vector) in zip(outputs, vectors) {
            let pixels = MapAssetTestSupport.terrainPixels(ground: vector.0, adjacency: vector.1,
                                                           featureVariant: vector.3, grade: vector.4,
                                                           elevation: vector.5, cracking: vector.7,
                                                           southExposureLevels: vector.6, seed: vector.2)
            let actual = SHA256.hash(data: Data(pixels)).map { String(format: "%02x", $0) }.joined()
            XCTAssertEqual(actual, output["decodedRgbaSha256"] as? String,
                           output["id"] as? String ?? vector.0.rawValue)
        }
    }

    @MainActor
    func testLiftedTerrainForcesZeroAndNeverBuildsWallsAgainstFogOrBoundary() {
        for ground in [GroundType.water, .deepWater, .chasm, .ice, .growth, .groundcover] {
            var tile = Tile(ground: ground, elevation: 3, isRevealed: true)
            XCTAssertEqual(MapAssetContract.resolvedElevation(for: tile), 0)
            tile.isRevealed = false
            XCTAssertEqual(MapAssetContract.resolvedElevation(for: tile), 0)
        }
        var raised = Tile(ground: .soil, elevation: 3, isRevealed: true)
        XCTAssertEqual(MapAssetContract.resolvedElevation(for: raised), 3)
        raised.isCrumbled = true
        XCTAssertEqual(MapAssetContract.resolvedElevation(for: raised), 0)

        let raisedSurface = Tile(ground: .soil, elevation: 3, isRevealed: true)
        XCTAssertEqual(MapAssetContract.southExposure(center: raisedSurface, south: nil), 0)
        XCTAssertEqual(MapAssetContract.southExposure(
            center: raisedSurface, south: Tile(ground: .soil, elevation: 0, isRevealed: false)), 0)
        XCTAssertEqual(MapAssetContract.southExposure(
            center: raisedSurface, south: Tile(ground: .soil, elevation: 1, isRevealed: true)), 2)
    }

    func testEveryMinimapPOIFamilyIsFogGated() {
        let cases: [(TileContent, MinimapDisclosure.Marker)] = [
            (.portal(isEntry: true), .portal), (.diaryPage("page"), .page),
            (.foundWriting("note"), .page), (.site(InstanceID(rawValue: 1)), .site),
            (.node(ResourceNode(resource: "ore", remainingHarvests: 1, yieldPerHarvest: 1)), .resource),
            (.wildDrop(resource: "essence_raw", amount: 1), .resource),
            (.item(ItemStack(id: InstanceID(rawValue: 44), catalogID: "field_maul")), .item),
            (.traveller("mara"), .traveller),
            (.lockedCache, .cache), (.hazard, .hazard)
        ]
        for (content, expected) in cases {
            XCTAssertNil(MinimapDisclosure.marker(for: Tile(content: content, isRevealed: false), enemy: nil))
            XCTAssertEqual(MinimapDisclosure.marker(for: Tile(content: content, isRevealed: true), enemy: nil), expected)
        }
        let ordinary = WorldEnemy(id: InstanceID(rawValue: 2), position: GridPoint(x: 0, y: 0))
        let apex = WorldEnemy(id: InstanceID(rawValue: 3), position: GridPoint(x: 0, y: 0), isApex: true)
        XCTAssertNil(MinimapDisclosure.marker(for: Tile(isRevealed: false), enemy: ordinary))
        XCTAssertNil(MinimapDisclosure.marker(for: Tile(isRevealed: false), enemy: apex))
        XCTAssertEqual(MinimapDisclosure.marker(for: Tile(isRevealed: true), enemy: ordinary), .encounter)
        XCTAssertEqual(MinimapDisclosure.marker(for: Tile(isRevealed: true), enemy: apex), .apex)
    }

    @MainActor func testMinimapDoesNotLeakSleepingCrypsisOnRevealedTerrain() {
        let store = GameStore(io: .temporary(name: "minimap-crypsis-\(UUID().uuidString)"))
        store.write("plains")
        store.bindAndDepart()
        var run = store.state.worlds.activeRun!
        var traits = CreatureTraits()
        traits.defence = .crypsis
        let point = GridPoint(x: run.playerPosition.x + 4, y: run.playerPosition.y)
        run.map[point].content = .empty
        run.map[point].isRevealed = true
        run.enemies = [WorldEnemy(id: InstanceID(rawValue: 77), traits: traits, position: point)]
        XCTAssertNil(MinimapDisclosure.marker(at: point, in: run))
        run.enemies[0].isAwake = true
        XCTAssertEqual(MinimapDisclosure.marker(at: point, in: run), .encounter)
    }

    /// Acceptance criterion: two books with different symbols must produce visibly different worlds.
    func testGreedyBooksProduceDenserMoreDangerousWorlds() {
        // Averaged over seeds — any single world can be an outlier.
        var calmNodes = 0, greedyNodes = 0, calmEnemies = 0, greedyEnemies = 0
        // **Same terrain and biome on both sides**, so only the greed dials differ — the bounty and
        // the quirk. Population answers to vitality now (Aimee, 6 Aug), so a pairing that also
        // swapped verdant for ashen would be measuring how *alive* the two worlds are rather than
        // how greedy, and an ash-choked world genuinely should hold less.
        let calm = book(["terrain": "plains", "biome": "verdant", "bounty": "sparse_ore", "quirk": "dim_sky"])
        let greedy = book(["terrain": "plains", "biome": "verdant", "bounty": "rich_ore", "quirk": "gilded_veins"])

        for seed in (1...25).map({ UInt64($0) &* 1_000_003 }) {
            let a = Worldgen.generate(book: calm, seed: seed)
            let b = Worldgen.generate(book: greedy, seed: seed)
            calmNodes += a.map.tiles.count { if case .node = $0.content { true } else { false } }
            greedyNodes += b.map.tiles.count { if case .node = $0.content { true } else { false } }
            calmEnemies += a.enemies.count
            greedyEnemies += b.enemies.count
        }

        XCTAssertGreaterThan(greedyNodes, calmNodes, "A greedier book must put more on the ground")
        XCTAssertGreaterThan(greedyEnemies, calmEnemies, "…and more in the way")
    }

    func testEveryWorldHasAnEntryAndAtLeastOneOtherPortal() {
        for seed in (1...30).map({ UInt64($0) &* 65_537 }) {
            let world = Worldgen.generate(book: book(["terrain": "plains"]), seed: seed)
            XCTAssertEqual(world.map[world.start].content, .portal(isEntry: true))
            let portals = world.map.tiles.count { $0.content.isPortal }
            XCTAssertGreaterThanOrEqual(portals, 2, "Brief requires at least one exit besides the entry")
        }
    }

    func testNothingIsPlacedOnTopOfAnythingElse() {
        let world = Worldgen.generate(book: book(["bounty": "teeming_life"]), seed: 4242)
        var seen = Set<GridPoint>()
        for point in world.map.allPoints where world.map[point].content != .empty {
            XCTAssertTrue(seen.insert(point).inserted)
        }
        // A guardian stands *on* its site — the fight is the price of the search, not a separate
        // mechanic (`sites-system.md`). Everything else stands on open ground.
        let guarded = Set(world.sites.filter { $0.definition?.contents.guardian != nil }.map(\.position))
        for enemy in world.enemies where !guarded.contains(enemy.position) {
            XCTAssertEqual(world.map[enemy.position].content, .empty, "Enemies stand on open ground")
        }
    }

    func testYouDoNotArriveNextToAnEnemy() {
        for seed in (1...30).map({ UInt64($0) &* 2_654_435_761 }) {
            let world = Worldgen.generate(book: book(["biome": "ashen"]), seed: seed)
            for enemy in world.enemies {
                XCTAssertGreaterThanOrEqual(
                    enemy.position.chebyshevDistance(to: world.start),
                    Tuning.World.enemyFreeRadiusAroundEntry,
                    "No ambush the moment you arrive"
                )
            }
        }
    }

    /// Dim Sky's paired tradeoff: a longer-lived world costs you a ring of sight.
    func testDimSkyReducesVision() {
        let plain = book(["terrain": "plains"])
        let dim = book(["terrain": "plains", "quirk": "dim_sky"])
        XCTAssertLessThan(WorldRules.visionRadius(for: dim, seed: 0),
                          WorldRules.visionRadius(for: plain, seed: 0))
        XCTAssertGreaterThanOrEqual(WorldRules.visionRadius(for: dim, seed: 0),
                                    Tuning.World.minimumVisionRadius)

        // Measure the two radii on deliberately open ground. A generated fixture makes this claim
        // depend on whichever chance-filled focuses happen to exist in the content catalogue: a
        // ridge or thicket beside the entry can hide both outer rings and make the counts equal.
        let centre = GridPoint(x: 5, y: 5)
        let openMap = WorldMap(width: 11, height: 11,
                               tiles: Array(repeating: Tile(), count: 121), entry: centre)
        func revealed(radius: Int) -> Int {
            var map = openMap
            WorldRules.reveal(around: centre, in: &map, radius: radius)
            return map.revealedCount
        }
        XCTAssertLessThan(revealed(radius: WorldRules.visionRadius(for: dim, seed: 0)),
                          revealed(radius: WorldRules.visionRadius(for: plain, seed: 0)),
                          "You arrive seeing less of a dim world")
    }

    func testExpeditionTuningChangesProjectionAndIsSnapshottedOnTheRun() throws {
        let composition = book(["terrain": "plains"])
        var tuning = DebugTuningProfile.defaults
        tuning.stabilityDurationMultiplier = 2
        tuning.collapseRecoveryFraction = 1
        tuning.baseVisionRadius = Tuning.World.baseVisionRadius + 2
        tuning.slowGroundExtraTurns = 3
        tuning.activeFloraFrequencyMultiplier = 0
        tuning.floraHazardSeverityMultiplier = 2

        let ordinary = BookProjection.project(page: Page(), seed: 991)
        let tuned = BookProjection.project(page: Page(), seed: 991, tuning: tuning)
        XCTAssertEqual(tuned.turnsUntilCollapse.lowerBound,
                       ordinary.turnsUntilCollapse.lowerBound * 2)
        XCTAssertGreaterThan(tuned.visionRadius.lowerBound, ordinary.visionRadius.lowerBound)

        let generated = Worldgen.generate(book: composition, seed: 991, tuning: tuning)
        let run = WorldRun(runIndex: 1, book: composition, mapSeed: 991,
                           rng: SeededRNG(seed: 991), map: generated.map,
                           playerPosition: generated.start, tuning: tuning)
        let baseline = WorldRun(runIndex: 1, book: composition, mapSeed: 991,
                                rng: SeededRNG(seed: 991), map: generated.map,
                                playerPosition: generated.start)
        XCTAssertEqual(run.decayPerTurn, baseline.decayPerTurn / 2, accuracy: 0.000_001)
        XCTAssertGreaterThan(WorldRules.visionRadius(in: run), WorldRules.visionRadius(in: baseline))

        let data = try SaveCodec.makeEncoder().encode(run)
        XCTAssertEqual(try SaveCodec.makeDecoder().decode(WorldRun.self, from: data).tuning, tuning)
    }

    func testSlowGroundDebugCostUsesTheRunSnapshot() {
        XCTAssertEqual(WorldRules.movementCost(.growth, slowGroundExtraTurns: 0), 1)
        XCTAssertEqual(WorldRules.movementCost(.mud, slowGroundExtraTurns: 3), 4)
        XCTAssertEqual(WorldRules.movementCost(.stone, slowGroundExtraTurns: 3), 1)
    }

    func testZeroApexMultiplierActuallyMeansNone() {
        var tuning = DebugTuningProfile.defaults
        tuning.apexChanceMultiplier = 0
        let greedy = book(["terrain": "caverns", "biome": "verdant",
                           "bounty": "rich_ore", "quirk": "gilded_veins"])
        for seed in UInt64(1)...40 {
            XCTAssertFalse(Worldgen.generate(book: greedy, seed: seed, tuning: tuning)
                .enemies.contains(where: \.isApex))
        }
    }

    func testGenerationDiagnosticsAreDeterministicAndSurviveMutableMapChanges() throws {
        var tuning = DebugTuningProfile.defaults
        tuning.additionalPageChance = 1
        let composition = book(["terrain": "plains", "biome": "verdant"])
        let first = Worldgen.generate(book: composition, seed: 20_260_809, tuning: tuning)
        let again = Worldgen.generate(book: composition, seed: 20_260_809, tuning: tuning)

        XCTAssertEqual(first.diagnostics, again.diagnostics)
        XCTAssertEqual(first.diagnostics.placedDiaryPages, first.pages)
        XCTAssertEqual(first.diagnostics.placedOtherWritings, first.writings.map(\.id))
        XCTAssertEqual(first.diagnostics.rawEssenceDropsPlaced,
                       first.map.tiles.count {
                           if case .wildDrop(let resource, _) = $0.content {
                               return resource == Resources.essenceRaw
                           }
                           return false
                       })

        var run = WorldRun(runIndex: 1, book: composition, mapSeed: 20_260_809,
                           rng: SeededRNG(seed: 20_260_809), map: first.map,
                           playerPosition: first.start,
                           generationDiagnostics: first.diagnostics, tuning: tuning)
        if let page = run.map.allPoints.first(where: {
            if case .diaryPage = run.map[$0].content { return true }
            return false
        }) {
            run.map[page].content = .empty
        }
        XCTAssertEqual(run.generationDiagnostics.placedDiaryPages,
                       first.diagnostics.placedDiaryPages,
                       "Initial placement is a snapshot, not a scan of collectible tiles")

        let data = try SaveCodec.makeEncoder().encode(run)
        XCTAssertEqual(try SaveCodec.makeDecoder().decode(WorldRun.self, from: data)
            .generationDiagnostics, first.diagnostics)
    }

    func testRawEssenceRecommendedProfileIsTheDefaultAndLegacyRemainsComparable() throws {
        XCTAssertEqual(DebugTuningProfile.defaults.rawEssenceProfile, .recommended)
        XCTAssertEqual(DebugTuningProfile.RawEssenceProfile.recommended.dropRange, 5...7)
        XCTAssertEqual(DebugTuningProfile.RawEssenceProfile.recommended.amountRange, 2...3)
        XCTAssertEqual(DebugTuningProfile.RawEssenceProfile.legacy.dropRange, 2...4)
        XCTAssertEqual(DebugTuningProfile.RawEssenceProfile.legacy.amountRange, 1...2)

        let composition = book(["terrain": "plains"])
        for seed in UInt64(1)...20 {
            let recommended = Worldgen.generate(book: composition, seed: seed,
                                                tuning: .defaults).diagnostics
            XCTAssertTrue((5...7).contains(recommended.rawEssenceDropsPlaced))
            XCTAssertGreaterThanOrEqual(recommended.rawEssenceObtainable,
                                        recommended.rawEssenceDropsPlaced * 2)
            XCTAssertLessThanOrEqual(recommended.rawEssenceObtainable,
                                     recommended.rawEssenceDropsPlaced * 3)

            var legacyTuning = DebugTuningProfile.defaults
            legacyTuning.rawEssenceProfile = .legacy
            let legacy = Worldgen.generate(book: composition, seed: seed,
                                           tuning: legacyTuning).diagnostics
            XCTAssertTrue((2...4).contains(legacy.rawEssenceDropsPlaced))
            XCTAssertGreaterThanOrEqual(legacy.rawEssenceObtainable, legacy.rawEssenceDropsPlaced)
            XCTAssertLessThanOrEqual(legacy.rawEssenceObtainable, legacy.rawEssenceDropsPlaced * 2)
        }
    }

    func testRawEssenceProfileAndIndependentMultipliersAreSnapshottedDeterministically() {
        let composition = book(["terrain": "plains"])
        var tuning = DebugTuningProfile.defaults
        tuning.rawEssenceProfile = .lean
        tuning.rawEssenceFrequencyMultiplier = 0.5
        tuning.rawEssenceYieldMultiplier = 2
        let first = Worldgen.generate(book: composition, seed: 81_919, tuning: tuning)
        let again = Worldgen.generate(book: composition, seed: 81_919, tuning: tuning)
        XCTAssertEqual(first.diagnostics, again.diagnostics)
        XCTAssertTrue((2...3).contains(first.diagnostics.rawEssenceDropsPlaced))
        XCTAssertGreaterThanOrEqual(first.diagnostics.rawEssenceObtainable,
                                    first.diagnostics.rawEssenceDropsPlaced * 4)
        let run = WorldRun(runIndex: 1, book: composition, mapSeed: 81_919,
                           rng: SeededRNG(seed: 81_919), map: first.map,
                           playerPosition: first.start, generationDiagnostics: first.diagnostics,
                           tuning: tuning)
        XCTAssertEqual(run.tuning, tuning)
    }

    func testOpeningEnvelopeRelocatesRatherThanDeletesOnlyOnFreshFirstExpedition() throws {
        let composition = book(["terrain": "plains", "biome": "teeming_life"])
        var clear = DebugTuningProfile.defaults
        clear.creatureDensityMultiplier = 3
        clear.baseVisionRadius = 6
        clear.openingEncounterEnvelope = .clearApproach

        let seed = try XCTUnwrap((UInt64(1)...500).first { candidate in
            let world = Worldgen.generate(book: composition, seed: candidate, tuning: clear,
                                          isFreshFirstExpedition: false)
            return world.enemies.count { enemy in
                world.map[enemy.position].isRevealed && !enemy.isSessile && !enemy.isApex
                    && !world.sites.map(\.position).contains(enemy.position)
            } >= 2
        })
        let natural = Worldgen.generate(book: composition, seed: seed, tuning: clear,
                                        isFreshFirstExpedition: false)
        let protectedPositions = Set(natural.sites.map(\.position))
        let protectedEnemies = natural.enemies.filter {
            $0.isSessile || $0.isApex || protectedPositions.contains($0.position)
        }

        let cleared = Worldgen.generate(book: composition, seed: seed, tuning: clear,
                                        isFreshFirstExpedition: true)
        XCTAssertEqual(cleared.enemies.count, natural.enemies.count)
        XCTAssertEqual(cleared.enemies.filter { $0.isSessile || $0.isApex
            || protectedPositions.contains($0.position) }, protectedEnemies)
        XCTAssertFalse(cleared.enemies.contains {
            cleared.map[$0.position].isRevealed && !$0.isSessile && !$0.isApex
                && !protectedPositions.contains($0.position)
        })
        XCTAssertTrue(cleared.diagnostics.openingEnvelopeApplied)
        XCTAssertGreaterThan(cleared.diagnostics.openingEnemiesRelocated, 0)

        let ignored = Worldgen.generate(book: composition, seed: seed, tuning: clear,
                                        isFreshFirstExpedition: false)
        XCTAssertEqual(ignored.enemies, natural.enemies)
        XCTAssertFalse(ignored.diagnostics.openingEnvelopeApplied)

        var gentle = clear
        gentle.openingEncounterEnvelope = .gentle
        let softened = Worldgen.generate(book: composition, seed: seed, tuning: gentle,
                                         isFreshFirstExpedition: true)
        XCTAssertLessThanOrEqual(softened.enemies.count {
            softened.map[$0.position].isRevealed && !$0.isSessile && !$0.isApex
                && !protectedPositions.contains($0.position)
        }, 1)
        XCTAssertEqual(softened.enemies.count, natural.enemies.count)
    }

    func testMapIsWidthOwnedAndNeverShrinksForBottomChrome() {
        XCTAssertEqual(WorldMapLayout.backdropRGB, [23, 23, 26],
                       "transparent lifted-sprite pixels reveal fog, never a white card seam")
        let phone = WorldMapLayout.maximumSide(containerWidth: 368, viewportHeight: 260,
                                                viewportTiles: 11, displayScale: 3)
        XCTAssertEqual(phone, 1100.0 / 3.0, accuracy: 0.001)
        XCTAssertEqual((phone * 3).truncatingRemainder(dividingBy: 11), 0, accuracy: 0.001,
                       "The bottom border lands after a complete device-pixel cell")

        let underlyingWithTutorial = WorldMapLayout.maximumSide(containerWidth: 368,
                                                                 viewportHeight: 260,
                                                                 viewportTiles: 11,
                                                                 displayScale: 3)
        XCTAssertEqual(phone, underlyingWithTutorial,
                       "Tutorial presentation is an overlay and cannot alter map/control geometry")

        let ordinary = WorldMapLayout.maximumSide(containerWidth: 368, viewportHeight: 500,
                                                   viewportTiles: 11, displayScale: 3)
        XCTAssertEqual(ordinary, phone, accuracy: 0.001,
                       "Extra vertical room cannot change a width-owned map")

        let cramped = WorldMapLayout.maximumSide(containerWidth: 320, viewportHeight: 100,
                                                  viewportTiles: 11, displayScale: 3)
        XCTAssertEqual(cramped, 319, accuracy: 0.001)
        XCTAssertGreaterThan(cramped, 310,
                             "Bottom panels may require scrolling but may never miniaturize the map")
        XCTAssertEqual((cramped * 3).truncatingRemainder(dividingBy: 11), 0, accuracy: 0.001)

        XCTAssertEqual(WorldMapLayout.viewportRows(mapWidth: phone, availableHeight: 260,
                                                   viewportColumns: 11, mapRows: 30), 7)
        XCTAssertEqual(WorldMapLayout.viewportRows(mapWidth: phone, availableHeight: 500,
                                                   viewportColumns: 11, mapRows: 30), 14)
        XCTAssertEqual(WorldMapLayout.viewportRows(mapWidth: phone, availableHeight: 500,
                                                   viewportColumns: 11, mapRows: 9), 9)
        let rows = WorldMapLayout.viewportRows(mapWidth: phone, availableHeight: 500,
                                               viewportColumns: 11, mapRows: 30)
        XCTAssertLessThanOrEqual(phone / 11 * CGFloat(rows), 500,
                               "Only complete rows that fit may be admitted to the viewport")
    }

    func testWorldControlsHaveExactlyTwoActionsInOneNonOverlappingBottomDock() throws {
        XCTAssertEqual(WorldControlsLayout.actionCount, 2)
        XCTAssertEqual(WorldControlsLayout.actionRows, 1,
                       "Interact and Look must remain side by side, never stacked")
        XCTAssertEqual(WorldControlsLayout.actionHeight, 44)

        let frames = WorldControlsLayout.actionFrames(containerWidth: 368)
        XCTAssertEqual(frames.count, 2)
        XCTAssertGreaterThanOrEqual(frames[0].width, 44)
        XCTAssertGreaterThanOrEqual(frames[1].width, 44)
        XCTAssertEqual(frames[0].height, 44)
        XCTAssertEqual(frames[1].height, 44)
        XCTAssertEqual(frames[0].minX, 191, accuracy: 0.01)
        XCTAssertGreaterThan(frames[0].width, 70)
        XCTAssertLessThanOrEqual(frames[0].maxX, frames[1].minX)
        XCTAssertEqual(frames[1].maxX, 352, accuracy: 0.01)

        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf: root.appending(path: "Sources/Screens/WorldView.swift"),
                                encoding: .utf8)
        XCTAssertFalse(source.contains(".safeAreaInset(edge: .bottom"),
                       "The bottom dock must reserve an ordinary sibling frame, never composite over the map")
        let geometry = try XCTUnwrap(source.range(of: "GeometryReader { viewport in"))
        let satchel = try XCTUnwrap(source.range(of: "satchel(run)",
                                                 range: geometry.upperBound..<source.endIndex))
        let controls = try XCTUnwrap(source.range(of: "controls(run)",
                                                  range: satchel.upperBound..<source.endIndex))
        XCTAssertLessThan(geometry.lowerBound, satchel.lowerBound)
        XCTAssertLessThan(satchel.lowerBound, controls.lowerBound,
                          "Map, Field Kit, and navigation are ordered siblings in one layout")
        XCTAssertTrue(source.contains("MapGrid("))
        XCTAssertFalse(source.contains("MapGrid(") && source.contains("eventLog.padding(8)"))
        XCTAssertTrue(source.contains("eventLog\n                            .padding(.horizontal, 12)\n                            .padding(.bottom, 8)"),
                      "Narration floats at the viewport boundary immediately above the bottom HUD")
        XCTAssertTrue(source.contains("Color(.systemBackground).opacity(0.42)"))
        XCTAssertTrue(source.contains(".allowsHitTesting(false)"))
        XCTAssertTrue(source.contains("HStack(alignment: .center, spacing: WorldControlsLayout.navigationSpacing)"))
        XCTAssertTrue(source.contains("VStack(spacing: 12)"),
                      "The actions need deliberate separation from the minimap")
        XCTAssertTrue(source.contains(".frame(width: 96, height: 96)"))
        XCTAssertTrue(source.contains("Button(\"Interact\")"))
        XCTAssertTrue(source.contains("Button(isLookArmed ? \"Cancel\" : \"Look\")"))
        XCTAssertTrue(source.contains(".padding(.vertical, 8)"),
                      "The control pair must be vertically centered inside symmetric padding")
        XCTAssertTrue(source.contains(".overlay(alignment: .top) { Divider() }"))
        XCTAssertTrue(source.contains(".clipShape(RoundedRectangle(cornerRadius: 10))"),
                      "No map pixels may escape the viewport or render beneath the Field Kit border")
    }

    func testFieldKitIsACompactTwoTrayInventoryInsteadOfAFullWidthList() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf: root.appending(path: "Sources/Screens/WorldView.swift"),
                                encoding: .utf8)
        let start = try XCTUnwrap(source.range(of: "private struct FieldKitSheet"))
        let fieldKit = String(source[start.lowerBound...])

        XCTAssertTrue(fieldKit.contains("Picker(\"Field Kit section\""))
        XCTAssertTrue(fieldKit.contains("case instruments = \"Instruments\""))
        XCTAssertTrue(fieldKit.contains("case supplies = \"Supplies\""))
        XCTAssertTrue(fieldKit.contains("SixAcrossItemGrid(data: store.carriedConsumables"))
        XCTAssertTrue(fieldKit.contains("AnchoredItemDetailButton(item: stack"))
        XCTAssertTrue(fieldKit.contains(".presentationDetents([.medium, .large])"))
        XCTAssertFalse(fieldKit.contains("List {"),
                       "Field Kit browsing is a compact tray; only selected-item detail may become prose")
    }

    // MARK: Fog and movement

    func testFogRevealsAroundThePlayerAndStaysRevealed() {
        var state = startedRun(book(["terrain": "plains"]), seed: 31)
        let run = state.worlds.activeRun!
        let start = run.playerPosition
        XCTAssertTrue(run.map[start].isRevealed)

        let step = run.map.neighbours(of: start).first { WorldRules.canEnter($0, in: run.map) }!
        _ = WorldRules.step(to: step, in: &state)
        let after = state.worlds.activeRun!

        XCTAssertTrue(after.map[start].isRevealed, "Revealed tiles stay revealed")
        XCTAssertTrue(after.map[step].isRevealed)
        XCTAssertEqual(after.playerPosition, step)
    }

    func testAStepIsExactlyOneTurn() {
        var state = startedRun(book(["terrain": "plains"]), seed: 12)
        let before = state.worlds.activeRun!
        let step = before.map.neighbours(of: before.playerPosition).first { WorldRules.canEnter($0, in: before.map) }!

        _ = WorldRules.step(to: step, in: &state)
        let after = state.worlds.activeRun!

        XCTAssertEqual(after.turnsTaken, before.turnsTaken + 1)
        XCTAssertEqual(after.stability, before.stability - before.decayPerTurn, accuracy: 0.0001)
    }

    func testResolvedStabilitySurvivesRelaunchAndMigratesOldRunsDeterministically() throws {
        let run = try XCTUnwrap(startedRun(book([:]), seed: 91).worlds.activeRun)
        let encoded = try JSONEncoder().encode(run)
        let resumed = try JSONDecoder().decode(WorldRun.self, from: encoded)
        XCTAssertEqual(resumed.resolvedStabilityScore, run.resolvedStabilityScore)
        XCTAssertEqual(resumed.decayPerTurn, run.decayPerTurn)

        var legacy = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        legacy.removeValue(forKey: "resolvedStabilityScore")
        let migrated = try JSONDecoder().decode(
            WorldRun.self, from: JSONSerialization.data(withJSONObject: legacy))
        XCTAssertEqual(migrated.resolvedStabilityScore,
                       BookRules.resolvedStabilityScore(of: run.book, seed: run.mapSeed))
    }

    func testTallGrowthAndMudEachCostTwoTurns() {
        for ground in [GroundType.growth, .mud] {
            var state = startedRun(book(["terrain": "plains"]), seed: 120)
            let before = state.worlds.activeRun!
            let step = before.map.neighbours(of: before.playerPosition)
                .first { WorldRules.canEnter($0, in: before.map) }!
            state.worlds.activeRun?.map[step].ground = ground

            let events = WorldRules.step(to: step, in: &state)

            XCTAssertEqual(state.worlds.activeRun?.turnsTaken, before.turnsTaken + 2)
            XCTAssertTrue(events.contains(.enteredSlowGround(ground.displayName)))
        }
    }

    func testPathfindingPrefersAQuickerRouteAroundSlowGround() {
        var map = WorldMap(width: 5, height: 3,
                           tiles: Array(repeating: Tile(), count: 15),
                           entry: GridPoint(x: 0, y: 1))
        let start = GridPoint(x: 0, y: 1)
        let destination = GridPoint(x: 4, y: 1)
        for x in 1...3 { map[GridPoint(x: x, y: 1)].ground = .growth }

        let route = WorldRules.path(from: start, to: destination, in: map)

        XCTAssertFalse(route.dropLast().contains { map[$0].ground == .growth },
                       "the route chose fewer squares even though they cost more turns")
        XCTAssertEqual(route.last, destination)

        let freeSlowRoute = WorldRules.path(from: start, to: destination, in: map,
                                            slowGroundExtraTurns: 0)
        XCTAssertTrue(freeSlowRoute.dropLast().contains { map[$0].ground == .growth },
                      "path weights ignored the zero-extra-turn run snapshot")
    }

    func testNonAdjacentStepsAreRefused() {
        var state = startedRun(book(["terrain": "plains"]), seed: 13)
        let run = state.worlds.activeRun!
        let far = run.map.allPoints.first { $0.manhattanDistance(to: run.playerPosition) > 3 }!

        let events = WorldRules.step(to: far, in: &state)
        XCTAssertEqual(state.worlds.activeRun?.playerPosition, run.playerPosition)
        XCTAssertEqual(state.worlds.activeRun?.turnsTaken, 0, "A refused move must not burn a turn")
        XCTAssertTrue(events.contains { if case .blocked = $0 { true } else { false } })
    }

    func testPathfindingReachesAndRoutesAroundCrumbledGround() {
        var state = startedRun(book(["terrain": "plains"]), seed: 14)
        var run = state.worlds.activeRun!
        let start = run.playerPosition
        let target = run.map.allPoints.last { $0 != start && WorldRules.canEnter($0, in: run.map) }!

        let route = WorldRules.path(from: start, to: target, in: run.map)
        XCTAssertFalse(route.isEmpty)
        XCTAssertEqual(route.last, target)
        for (index, point) in route.enumerated() {
            let previous = index == 0 ? start : route[index - 1]
            XCTAssertTrue(WorldRules.isAdjacent(previous, point), "Every path step must be one tile")
        }

        // Wall off a neighbour and confirm the route never crosses crumbled ground.
        for neighbour in run.map.neighbours(of: start).dropLast() {
            run.map[neighbour].isCrumbled = true
        }
        state.worlds.activeRun = run
        let detour = WorldRules.path(from: start, to: target, in: run.map)
        for point in detour {
            XCTAssertFalse(run.map[point].isCrumbled)
        }
    }

    // MARK: Harvesting

    func testHarvestingFillsTheSatchelAndExhaustsTheNode() throws {
        var state = startedRun(book(["bounty": "teeming_life"]), seed: 99)
        var run = state.worlds.activeRun!
        // Put a known node under the player rather than hunting the map for one.
        run.map[run.playerPosition].content = .node(ResourceNode(resource: Resources.fiber,
                                                                 remainingHarvests: 2,
                                                                 yieldPerHarvest: 3))
        state.worlds.activeRun = run

        _ = WorldRules.harvest(in: &state)
        XCTAssertEqual(state.worlds.activeRun?.satchel[Resources.fiber], 3)
        XCTAssertEqual(state.worlds.activeRun?.turnsTaken, 1, "A pull costs a turn")
        XCTAssertTrue(state.reality.discovery.hasEncountered(resource: Resources.fiber),
                      "Harvesting logs the resource for the preview's silhouettes")

        _ = WorldRules.harvest(in: &state)
        XCTAssertEqual(state.worlds.activeRun?.satchel[Resources.fiber], 6)
        XCTAssertEqual(state.worlds.activeRun?.map[state.worlds.activeRun!.playerPosition].content, .empty,
                       "A spent node clears itself off the map")
    }

    func testWayfarersTableImprovesOrganicHarvestAndPacking() throws {
        var state = startedRun(book(["bounty": "teeming_life"]), seed: 99)
        let ordinaryCapacity = state.base.satchelCapacity
        state.base.stations[Stations.wayfarersTable] = StationState(isUnlocked: true, tier: 0)
        XCTAssertEqual(state.base.satchelCapacity,
                       ordinaryCapacity + Tuning.Economy.fieldcraftSatchelBonus)

        var run = try XCTUnwrap(state.worlds.activeRun)
        run.map[run.playerPosition].content = .node(ResourceNode(resource: Resources.fiber,
                                                                 remainingHarvests: 1,
                                                                 yieldPerHarvest: 3))
        state.worlds.activeRun = run
        _ = WorldRules.harvest(in: &state)
        XCTAssertEqual(state.worlds.activeRun?.satchel[Resources.fiber],
                       3 + Tuning.Economy.fieldcraftOrganicYieldBonus)
    }

    func testWildDropsArePickedUpByWalkingOverThem() {
        var state = startedRun(book(["terrain": "plains"]), seed: 21)
        var run = state.worlds.activeRun!
        let target = run.map.neighbours(of: run.playerPosition).first { WorldRules.canEnter($0, in: run.map) }!
        run.map[target].content = .wildDrop(resource: Resources.essenceRaw, amount: 2)
        state.worlds.activeRun = run

        _ = WorldRules.step(to: target, in: &state)
        XCTAssertEqual(state.worlds.activeRun?.satchel[Resources.essenceRaw], 2)
        XCTAssertEqual(state.worlds.activeRun?.map[target].content, .empty, "A wild drop is taken, not left")
    }

    func testDiaryPageExperienceIsPaidOnlyForANewlyReadPage() throws {
        let page = try XCTUnwrap(ContentCatalog.shared.diaryPages.first)

        func stateWithPage(alreadyKnown: Bool) -> (GameState, GridPoint) {
            var state = startedRun(book(["terrain": "plains"]), seed: 2_026_081_011)
            var run = state.worlds.activeRun!
            run.enemies = []
            let target = run.map.neighbours(of: run.playerPosition)
                .first { WorldRules.canEnter($0, in: run.map) }!
            run.map[target].content = .diaryPage(page.id)
            state.worlds.activeRun = run
            if alreadyKnown { state.reality.library.foundPages.append(page.id) }
            return (state, target)
        }

        var (fresh, freshTarget) = stateWithPage(alreadyKnown: false)
        let freshXP = fresh.base.binderCharacter.experience
        _ = WorldRules.step(to: freshTarget, in: &fresh)
        XCTAssertEqual(fresh.base.binderCharacter.experience - freshXP,
                       Tuning.Character.experienceForPage)
        XCTAssertEqual(fresh.worlds.activeRun?.experienceBreakdown.pages,
                       Tuning.Character.experienceForPage)

        var (known, knownTarget) = stateWithPage(alreadyKnown: true)
        let knownXP = known.base.binderCharacter.experience
        _ = WorldRules.step(to: knownTarget, in: &known)
        XCTAssertEqual(known.base.binderCharacter.experience, knownXP,
                       "a stale duplicate page tile must not pay discovery XP again")
        XCTAssertEqual(known.worlds.activeRun?.experienceBreakdown.pages, 0)
        XCTAssertEqual(known.worlds.activeRun?.map[knownTarget].content, .empty)
    }

    func testExperienceBreakdownIsTolerantAndFrozenIntoARecap() throws {
        var run = try XCTUnwrap(startedRun(book([:]), seed: 741).worlds.activeRun)
        run.experienceBreakdown = RunExperienceBreakdown(combat: 36, species: 14,
                                                         sites: 20, pages: 25, travellers: 0)
        let encodedRun = try SaveCodec.makeEncoder().encode(run)
        XCTAssertEqual(try SaveCodec.makeDecoder().decode(WorldRun.self, from: encodedRun)
            .experienceBreakdown.total, 95)

        var legacy = try XCTUnwrap(JSONSerialization.jsonObject(with: encodedRun) as? [String: Any])
        legacy.removeValue(forKey: "experienceBreakdown")
        let legacyData = try JSONSerialization.data(withJSONObject: legacy)
        XCTAssertEqual(try SaveCodec.makeDecoder().decode(WorldRun.self, from: legacyData)
            .experienceBreakdown, RunExperienceBreakdown())

        let summary = RunExitSummary(runIndex: 1, kind: .portal, reason: "Home", turnsTaken: 4,
                                     haulKeptFraction: 1,
                                     experienceBreakdown: run.experienceBreakdown)
        let resumed = try SaveCodec.makeDecoder().decode(
            RunExitSummary.self, from: SaveCodec.makeEncoder().encode(summary))
        XCTAssertEqual(resumed.experienceBreakdown, run.experienceBreakdown)
    }

    // MARK: The world turning against you

    func testHazardsOnlyAppearOnceStabilityFalls() {
        var state = startedRun(book(["terrain": "plains"]), seed: 55)
        func hazardCount() -> Int { state.worlds.activeRun?.map.tiles.count { $0.content == .hazard } ?? 0 }

        // Well above the threshold: nothing changes.
        for _ in 0..<3 { _ = WorldRules.advanceTurn(in: &state) }
        XCTAssertEqual(hazardCount(), 0)

        // Drop below it and the edges start turning.
        state.worlds.activeRun?.stability = Tuning.World.hazardThreshold - 1
        for _ in 0..<6 { _ = WorldRules.advanceTurn(in: &state) }
        XCTAssertGreaterThan(hazardCount(), 0, "Past the threshold, hazards spawn at the edges")
    }

    func testCrumblingWarnsTheOutsideRingBeforeItFalls() {
        var state = startedRun(book(["terrain": "plains"]), seed: 56)
        state.worlds.activeRun?.stability = Tuning.World.crumbleThreshold - 1
        state.worlds.activeRun?.playerPosition = GridPoint(x: 7, y: 7) // middle of the map

        _ = WorldRules.advanceTurn(in: &state)
        let run = state.worlds.activeRun!

        let cracking = run.map.allPoints.filter { run.map[$0].isCracking }
        XCTAssertFalse(cracking.isEmpty)
        XCTAssertTrue(run.map.allPoints.allSatisfy { !run.map[$0].isCrumbled },
                      "a tile vanished on the same turn its warning appeared")
        for point in cracking {
            XCTAssertEqual(run.map.ring(of: point), 0, "Crumbling starts at the outermost ring")
        }
    }

    func testThePlayersTileGetsAFullWarningTurnBeforeItFalls() {
        var state = startedRun(book(["terrain": "plains"]), seed: 561)
        state.worlds.activeRun?.stability = 0
        state.worlds.activeRun?.collapsedOnTurn = 0
        guard let player = state.worlds.activeRun?.playerPosition else { return XCTFail("no player") }
        // Leave only the player's block, forcing it to be the next target.
        for point in state.worlds.activeRun!.map.allPoints where point != player {
            state.worlds.activeRun?.map[point].isCrumbled = true
        }

        var events = WorldRules.advanceTurn(in: &state)
        XCTAssertTrue(state.worlds.activeRun?.map[player].isCracking == true)
        XCTAssertFalse(state.worlds.activeRun?.map[player].isCrumbled == true)
        XCTAssertFalse(events.contains(.floorGaveWay))

        events = WorldRules.advanceTurn(in: &state)
        XCTAssertTrue(events.contains(.floorGaveWay))
    }

    func testCrackWarningsDoNotHalveSteadyStateCollapseSpeed() {
        var state = startedRun(book(["terrain": "plains"]), seed: 562)
        state.worlds.activeRun?.stability = 0
        state.worlds.activeRun?.collapsedOnTurn = 0

        _ = WorldRules.advanceTurn(in: &state) // primes the warning pipeline
        guard let primed = state.worlds.activeRun else { return XCTFail("run ended while priming") }
        let expected = WorldRules.crumbleRate(in: primed)
        let before = primed.map.allPoints.count { primed.map[$0].isCrumbled }
        _ = WorldRules.advanceTurn(in: &state)
        guard let afterRun = state.worlds.activeRun else { return XCTFail("run ended too early") }
        let after = afterRun.map.allPoints.count { afterRun.map[$0].isCrumbled }
        XCTAssertEqual(after - before, expected)
        XCTAssertGreaterThan(afterRun.map.allPoints.count { afterRun.map[$0].isCracking }, 0,
                             "collapse removed the warned wave but failed to warn the next one")
    }

    /// The meter emptying is announced — and **does not end the run**. You are still standing in a
    /// world that has begun to come apart, which is the whole of the decision it creates.
    func testCollapseIsAnnouncedAtZeroStabilityAndDoesNotEndTheRun() {
        let composition = book(["terrain": "plains"])
        var state = startedRun(composition, seed: 57)
        // Exactly one turn's worth left, whatever this book's rate happens to be — pinning a
        // literal here would break every time the stability scale is retuned.
        state.worlds.activeRun?.stability = BookRules.decayPerTurn(for: composition)

        let events = WorldRules.advanceTurn(in: &state)
        XCTAssertTrue(events.contains(.collapsed))
        XCTAssertFalse(events.contains(.floorGaveWay),
                       "an empty meter threw the player out of a world that was still there")
        XCTAssertNotNil(state.worlds.activeRun, "the run ended on a number rather than on the floor")
    }

    /// **You are only forced out when the block you're standing on goes.**
    func testYouAreOnlyThrownOutWhenTheFloorUnderYouGoes() {
        var state = startedRun(book(["terrain": "plains"]), seed: 57)
        state.worlds.activeRun?.stability = 0
        state.worlds.activeRun?.collapsedOnTurn = 0

        // Crumble until it reaches the player, which it now can.
        var events: [WorldRules.Event] = []
        for _ in 0..<400 where !events.contains(.floorGaveWay) {
            events = WorldRules.advanceTurn(in: &state)
            guard state.worlds.activeRun != nil else { break }
        }
        XCTAssertTrue(events.contains(.floorGaveWay),
                      "a world crumbled away entirely and never reached the player standing in it")
    }

    /// A collapsed world genuinely runs out rather than nibbling its edges forever.
    func testACollapsedWorldSpeedsUpTheLongerYouStay() {
        var state = startedRun(book(["terrain": "plains"]), seed: 57)
        state.worlds.activeRun?.stability = 0
        state.worlds.activeRun?.collapsedOnTurn = 0
        state.worlds.activeRun?.turnsTaken = 0
        let atOnce = WorldRules.crumbleRate(in: state.worlds.activeRun!)

        state.worlds.activeRun?.turnsTaken = 30
        XCTAssertGreaterThan(WorldRules.crumbleRate(in: state.worlds.activeRun!), atOnce)
    }

    /// **A spared portal is no use behind a wall.** Entry portals sit on the map edge, which is the
    /// first ring to crumble — so sparing the portal tile while eating everything around it left
    /// the player looking at an intact way out they couldn't reach, waiting to be thrown out. Which
    /// is exactly what sparing them was meant to prevent.
    func testAPortalStaysReachableForAsLongAsThePlayerIsStanding() {
        for seed in [UInt64(3), 57, 909] {
            var state = startedRun(book(["terrain": "plains"]), seed: seed)
            state.worlds.activeRun?.stability = 0
            state.worlds.activeRun?.collapsedOnTurn = 0
            // **Standing away from the way out**, which is the whole case. The run starts *on* the
            // entry portal, so a test that leaves the player there proves nothing at all.
            if let run = state.worlds.activeRun {
                let middle = run.map.allPoints
                    .filter { WorldRules.canEnter($0, in: run.map) && !run.map[$0].content.isPortal }
                    .max { run.map.ring(of: $0) < run.map.ring(of: $1) }
                if let middle { state.worlds.activeRun?.playerPosition = middle }
            }
            XCTAssertFalse(state.worlds.activeRun?.map[state.worlds.activeRun!.playerPosition]
                .content.isPortal ?? true, "the player has to start away from a portal")

            for _ in 0..<200 {
                let events = WorldRules.advanceTurn(in: &state)
                guard let run = state.worlds.activeRun, !events.contains(.floorGaveWay) else { break }
                XCTAssertTrue(
                    WorldRules.canReachAPortal(from: run.playerPosition, in: run.map),
                    "seed \(seed): the player was marooned with a portal standing and their own floor intact")
            }
        }
    }

    /// The way out is the last thing to go, or "reach a portal in time" becomes "wait to be thrown
    /// out", which is no decision at all.
    func testPortalsAreTheLastThingToCrumble() {
        var state = startedRun(book(["terrain": "plains"]), seed: 57)
        state.worlds.activeRun?.stability = 0
        state.worlds.activeRun?.collapsedOnTurn = 0

        for _ in 0..<60 {
            _ = WorldRules.advanceTurn(in: &state)
            guard let run = state.worlds.activeRun else { break }
            let portalsGone = run.map.allPoints.contains {
                run.map[$0].isCrumbled && run.map[$0].content.isPortal
            }
            let floorLeft = run.map.allPoints.contains {
                !run.map[$0].isCrumbled && !run.map[$0].content.isPortal
            }
            XCTAssertFalse(portalsGone && floorLeft, "a portal went while there was still floor")
        }
    }

    // MARK: Enemies

    func testEnemiesSleepUntilYouAreCloseThenWalkAtYou() {
        var state = startedRun(book(["terrain": "plains"]), seed: 61)
        var run = state.worlds.activeRun!
        run.enemies = []
        run.playerPosition = GridPoint(x: 7, y: 7)
        let sleeper = GridPoint(x: 7, y: 12) // far away
        run.enemies = [WorldEnemy(id: InstanceID(rawValue: 1), creatureID: "paper_moth", position: sleeper)]
        state.worlds.activeRun = run

        _ = WorldRules.advanceTurn(in: &state)
        XCTAssertEqual(state.worlds.activeRun?.enemies.first?.position, sleeper, "Inert until you come close")
        XCTAssertFalse(state.worlds.activeRun?.enemies.first?.isAwake ?? true)

        // Detection and contact are separate: the discovery turn wakes it in place, then a later
        // world turn lets the already-pursuing creature close the distance.
        state.worlds.activeRun?.enemies[0].position = GridPoint(x: 7, y: 9)
        _ = WorldRules.advanceTurn(in: &state)
        XCTAssertTrue(state.worlds.activeRun!.enemies[0].isAwake)
        XCTAssertEqual(state.worlds.activeRun!.enemies[0].position, GridPoint(x: 7, y: 9))

        _ = WorldRules.advanceTurn(in: &state)
        XCTAssertLessThan(state.worlds.activeRun!.enemies[0].position
            .chebyshevDistance(to: GridPoint(x: 7, y: 7)), 2)
    }

    func testQuietStepCreatesOnePersistedAlertTurnRatherThanAnInvisibleRoll() throws {
        var state = startedRun(book(["terrain": "plains"]), seed: 6_101)
        state.base.binderCharacter.level = 3
        state.base.binderCharacter.branchDepth["shadow"] = 1
        var run = try XCTUnwrap(state.worlds.activeRun)
        run.enemies = []
        run.playerPosition = GridPoint(x: 7, y: 7)
        let position = GridPoint(x: 7, y: 9)
        run.map[position].isRevealed = true
        run.enemies = [WorldEnemy(id: InstanceID(rawValue: 61), creatureID: "paper_moth",
                                  position: position)]
        state.worlds.activeRun = run

        let first = WorldRules.advanceTurn(in: &state)
        let alerted = try XCTUnwrap(state.worlds.activeRun?.enemies.first)
        if case .alert(_, let reason) = alerted.awareness { XCTAssertEqual(reason, .quietStep) }
        else { XCTFail("Quiet Step did not create an alert state") }
        XCTAssertTrue(alerted.quietStepHesitationUsed)
        XCTAssertEqual(alerted.position, position)
        XCTAssertTrue(first.contains { if case .enemyAlerted = $0 { true } else { false } })

        var cryptic = alerted
        var crypticTraits = CreatureTraits()
        crypticTraits.defence = .crypsis
        cryptic.traits = crypticTraits
        XCTAssertTrue(WorldRules.isVisible(cryptic, in: try XCTUnwrap(state.worlds.activeRun)),
                      "The earned alert warned about a creature the map still hid")

        _ = WorldRules.advanceTurn(in: &state)
        XCTAssertTrue(state.worlds.activeRun?.enemies.first?.isAwake == true)

        let data = try JSONEncoder().encode(state.worlds.activeRun?.enemies.first)
        let resumed = try JSONDecoder().decode(WorldEnemy.self, from: data)
        XCTAssertTrue(resumed.isAwake)
        XCTAssertTrue(resumed.quietStepHesitationUsed)
    }

    func testEncounterOpeningFreezesApproachMutualContactAndAmbushFromPreActionDisclosure() throws {
        func opening(disclosed: Bool, approached: Bool, apex: Bool = false) throws -> EncounterState.OpeningResolution {
            var state = startedRun(book(["terrain": "plains"]), seed: apex ? 8_103 : 8_101)
            var run = try XCTUnwrap(state.worlds.activeRun)
            let enemy = WorldEnemy(id: InstanceID(rawValue: apex ? 8103 : 8101),
                                   creatureID: "paper_moth", position: run.playerPosition,
                                   isApex: apex)
            run.enemies = [enemy]
            state.worlds.activeRun = run
            let snapshot = WorldRules.PreContactSnapshot(
                disclosedEnemyIDs: disclosed ? [enemy.id] : [],
                approachedEnemyID: approached ? enemy.id : nil
            )
            WorldRules.beginEncounter(triggeredBy: enemy, preContact: snapshot,
                                      runsAutomaticTurns: false, in: &state)
            return try XCTUnwrap(state.worlds.activeRun?.activeEncounter?.opening)
        }

        XCTAssertEqual(try opening(disclosed: true, approached: true).resolved, .partyApproach)
        XCTAssertEqual(try opening(disclosed: true, approached: false).resolved, .mutualContact)
        let ambush = try opening(disclosed: false, approached: false)
        XCTAssertEqual(ambush.initial, .creatureAmbush)
        XCTAssertEqual(ambush.resolved, .creatureAmbush)
        XCTAssertFalse(ambush.pendingFoeActions.isEmpty)
        XCTAssertEqual(try opening(disclosed: false, approached: false, apex: true).resolved,
                       .partyApproach, "an apex never gains an ordinary creature ambush")
    }

    func testRealStepUsesThePresentationBeforeMovementAndReveal() throws {
        var state = startedRun(book(["terrain": "plains"]), seed: 8_105)
        var run = try XCTUnwrap(state.worlds.activeRun)
        let destination = try XCTUnwrap(run.map.neighbours(of: run.playerPosition)
            .first { WorldRules.canEnter($0, in: run.map) })
        run.map[destination].isRevealed = true
        let enemy = WorldEnemy(id: InstanceID(rawValue: 8105), creatureID: "paper_moth",
                               position: destination)
        run.enemies = [enemy]
        state.worlds.activeRun = run

        _ = WorldRules.step(to: destination, in: &state)

        let opening = try XCTUnwrap(state.worlds.activeRun?.activeEncounter?.opening)
        XCTAssertTrue(opening.preContactDisclosed)
        XCTAssertEqual(opening.initial, .mutualContact)
        XCTAssertEqual(opening.resolved, .mutualContact)
    }

    func testApexAdjacencyIsSafeAndOnlyOccupiedTileEntryStartsCombat() throws {
        var state = GameState.newGame()
        let start = GridPoint(x: 0, y: 0)
        let destination = GridPoint(x: 1, y: 0)
        let apexPoint = GridPoint(x: 2, y: 0)
        let map = WorldMap(width: 3, height: 1,
                           tiles: [Tile(isRevealed: true), Tile(isRevealed: true),
                                   Tile(isRevealed: true)], entry: start)
        let composition = book(["terrain": "plains"])
        let apex = WorldEnemy(id: InstanceID(rawValue: 8106), creatureID: "paper_moth",
                              position: apexPoint, isApex: true)
        state.worlds.activeRun = WorldRun(runIndex: 1, book: composition, mapSeed: 8_106,
                                          rng: SeededRNG(seed: 8_106), map: map,
                                          playerPosition: start, enemies: [apex])

        _ = WorldRules.step(to: destination, in: &state)

        XCTAssertEqual(state.worlds.activeRun?.playerPosition, destination)
        XCTAssertNil(state.worlds.activeRun?.activeEncounter)
        XCTAssertTrue(WorldRules.automaticTravelMustStop(
            before: apexPoint, in: try XCTUnwrap(state.worlds.activeRun)))

        let beforeLook = try XCTUnwrap(state.worlds.activeRun)
        _ = WorldRules.inspect(apexPoint, in: beforeLook)
        XCTAssertEqual(state.worlds.activeRun, beforeLook, "Look must be byte-state neutral")
        _ = WorldRules.advanceTurn(in: &state)
        XCTAssertNil(state.worlds.activeRun?.activeEncounter,
                     "waiting beside an apex must not manufacture contact")

        _ = WorldRules.step(to: apexPoint, in: &state)
        XCTAssertEqual(state.worlds.activeRun?.activeEncounter?.opening?.resolved, .partyApproach)
    }

    func testActiveFloraAdjacencyIsSafeAndOnlyOccupiedTileEntryStartsCombat() throws {
        var state = GameState.newGame()
        let start = GridPoint(x: 0, y: 0), beside = GridPoint(x: 1, y: 0)
        let occupied = GridPoint(x: 2, y: 0)
        let map = WorldMap(width: 3, height: 1,
                           tiles: Array(repeating: Tile(isRevealed: true), count: 3), entry: start)
        let flora = WorldEnemy(id: InstanceID(rawValue: 8107), creatureID: "paper_moth",
                               position: occupied, isSessile: true)
        state.worlds.activeRun = WorldRun(runIndex: 1, book: book(["terrain": "plains"]),
                                          mapSeed: 8_107, rng: SeededRNG(seed: 8_107), map: map,
                                          playerPosition: start, enemies: [flora])

        _ = WorldRules.step(to: beside, in: &state)
        XCTAssertNil(state.worlds.activeRun?.activeEncounter)
        _ = WorldRules.advanceTurn(in: &state)
        XCTAssertNil(state.worlds.activeRun?.activeEncounter)
        _ = WorldRules.step(to: occupied, in: &state)
        XCTAssertEqual(state.worlds.activeRun?.activeEncounter?.opening?.resolved, .partyApproach)
    }

    func testEnteringOrdinaryAdjacencyWakesWithoutFabricatingContact() throws {
        var state = GameState.newGame()
        let start = GridPoint(x: 0, y: 0), beside = GridPoint(x: 1, y: 0)
        let occupied = GridPoint(x: 2, y: 0)
        let map = WorldMap(width: 3, height: 1,
                           tiles: Array(repeating: Tile(isRevealed: true), count: 3), entry: start)
        let enemy = WorldEnemy(id: InstanceID(rawValue: 8108), creatureID: "paper_moth",
                               position: occupied)
        state.worlds.activeRun = WorldRun(runIndex: 1, book: book(["terrain": "plains"]),
                                          mapSeed: 8_108, rng: SeededRNG(seed: 8_108), map: map,
                                          playerPosition: start, enemies: [enemy])

        _ = WorldRules.step(to: beside, in: &state)
        XCTAssertNil(state.worlds.activeRun?.activeEncounter)
        XCTAssertEqual(state.worlds.activeRun?.enemies.first?.position, occupied)
        XCTAssertTrue(state.worlds.activeRun?.enemies.first?.isAwake == true)
    }

    func testCreatureAmbushOpeningActionsRunBeforeOrdinaryInitiativeAndPersist() throws {
        var state = startedRun(book(["terrain": "plains"]), seed: 8_111)
        var run = try XCTUnwrap(state.worlds.activeRun)
        let enemy = WorldEnemy(id: InstanceID(rawValue: 8111), creatureID: "paper_moth",
                               position: run.playerPosition)
        let second = WorldEnemy(id: InstanceID(rawValue: 8112), creatureID: "paper_moth",
                                position: run.playerPosition, isAwake: true)
        run.enemies = [enemy, second]
        state.worlds.activeRun = run
        WorldRules.beginEncounter(triggeredBy: enemy,
                                  preContact: .init(disclosedEnemyIDs: [], approachedEnemyID: nil),
                                  runsAutomaticTurns: false, in: &state)
        let frozen = try XCTUnwrap(state.worlds.activeRun?.activeEncounter)
        let relativeFoeOrder = frozen.order.compactMap(\.foeID)
        XCTAssertEqual(frozen.opening?.pendingFoeActions, relativeFoeOrder)
        XCTAssertEqual(relativeFoeOrder.count, 2)

        let resumed = try SaveCodec.makeDecoder().decode(
            EncounterState.self, from: SaveCodec.makeEncoder().encode(frozen))
        XCTAssertEqual(resumed.opening, frozen.opening)

        let logCount = frozen.log.count
        let ordinaryTurnIndex = frozen.turnIndex
        CombatRules.runAutomaticTurns(in: &state)
        let after = try XCTUnwrap(state.worlds.activeRun?.activeEncounter)
        XCTAssertTrue(after.opening?.pendingFoeActions.isEmpty == true)
        XCTAssertGreaterThanOrEqual(after.log.count, logCount + 2,
                                    "each living foe did not resolve one opening action")
        XCTAssertEqual(after.turnIndex, ordinaryTurnIndex,
                       "an opening action incorrectly consumed the foe's ordinary initiative slot")
    }

    func testWatchfulSuppressesActionsWithoutReclassifyingAmbush() throws {
        var state = startedRun(book(["terrain": "plains"]), seed: 8_121)
        state.base.binderCharacter.branchDepth["protection"] = 2
        var run = try XCTUnwrap(state.worlds.activeRun)
        let enemy = WorldEnemy(id: InstanceID(rawValue: 8121), creatureID: "paper_moth",
                               position: run.playerPosition)
        run.enemies = [enemy]
        state.worlds.activeRun = run
        WorldRules.beginEncounter(triggeredBy: enemy,
                                  preContact: .init(disclosedEnemyIDs: [], approachedEnemyID: nil),
                                  runsAutomaticTurns: false, in: &state)

        let opening = try XCTUnwrap(state.worlds.activeRun?.activeEncounter?.opening)
        XCTAssertEqual(opening.resolved, .creatureAmbush)
        XCTAssertTrue(opening.watchfulSuppressedOpening)
        XCTAssertTrue(opening.pendingFoeActions.isEmpty)
    }

    func testSlipperyRollIsSavedAndUnseenAndAmbushReadTheFrozenOpening() throws {
        var preventedState: GameState?
        for seed in UInt64(8_130)...8_194 {
            var state = startedRun(book(["terrain": "plains"]), seed: seed)
            state.base.binderCharacter.branchDepth["evasion"] = 4
            var run = try XCTUnwrap(state.worlds.activeRun)
            let enemy = WorldEnemy(id: InstanceID(rawValue: seed), creatureID: "paper_moth",
                                   position: run.playerPosition)
            run.enemies = [enemy]
            state.worlds.activeRun = run
            WorldRules.beginEncounter(triggeredBy: enemy,
                                      preContact: .init(disclosedEnemyIDs: [], approachedEnemyID: nil),
                                      runsAutomaticTurns: false, in: &state)
            if state.worlds.activeRun?.activeEncounter?.opening?.slipperyPrevented == true {
                preventedState = state
                break
            }
        }
        let slippery = try XCTUnwrap(preventedState)
        let slipperyOpening = try XCTUnwrap(slippery.worlds.activeRun?.activeEncounter?.opening)
        XCTAssertEqual(slipperyOpening.initial, .creatureAmbush)
        XCTAssertEqual(slipperyOpening.resolved, .mutualContact)
        XCTAssertNotNil(slipperyOpening.slipperyRoll)
        XCTAssertTrue(slipperyOpening.pendingFoeActions.isEmpty)

        var unseen = startedRun(book(["terrain": "plains"]), seed: 8_195)
        unseen.base.binderCharacter.branchDepth["shadow"] = 8
        var run = try XCTUnwrap(unseen.worlds.activeRun)
        let enemy = WorldEnemy(id: InstanceID(rawValue: 8195), creatureID: "paper_moth",
                               position: run.playerPosition)
        run.enemies = [enemy]
        unseen.worlds.activeRun = run
        WorldRules.beginEncounter(triggeredBy: enemy,
                                  preContact: .init(disclosedEnemyIDs: [], approachedEnemyID: nil),
                                  runsAutomaticTurns: false, in: &unseen)
        let encounter = try XCTUnwrap(unseen.worlds.activeRun?.activeEncounter)
        XCTAssertEqual(encounter.opening?.resolved, .creatureAmbush)
        XCTAssertEqual(encounter.concealed[.binder], 1)
        let ambushSkill = try XCTUnwrap(ContentCatalog.shared.skill("ambush"))
        XCTAssertFalse(CombatRules.isReady(ambushSkill, for: .binder, in: encounter))

        var approach = unseen
        approach.worlds.activeRun?.activeEncounter = nil
        WorldRules.beginEncounter(triggeredBy: enemy,
                                  preContact: .init(disclosedEnemyIDs: [enemy.id],
                                                    approachedEnemyID: enemy.id),
                                  runsAutomaticTurns: false, in: &approach)
        let approached = try XCTUnwrap(approach.worlds.activeRun?.activeEncounter)
        XCTAssertTrue(CombatRules.isReady(ambushSkill, for: .binder, in: approached))
        var legacyEncounter = approached
        legacyEncounter.opening = nil
        legacyEncounter.roundNumber = 5
        XCTAssertFalse(CombatRules.isReady(ambushSkill, for: .binder, in: legacyEncounter),
                       "a legacy mid-fight save gained a new free opening attack")
        var scriptedAllows = approached
        scriptedAllows.opening?.resolved = .scripted(scriptID: "test.opening", overridesWatchful: true,
                                                      allowsPartyOpeningAttack: true)
        XCTAssertTrue(CombatRules.isReady(ambushSkill, for: .binder, in: scriptedAllows))
        var scriptedForbids = approached
        scriptedForbids.opening?.resolved = .scripted(scriptID: "test.opening", overridesWatchful: false,
                                                      allowsPartyOpeningAttack: false)
        XCTAssertFalse(CombatRules.isReady(ambushSkill, for: .binder, in: scriptedForbids),
                       "scripted Ambush policy was inferred from Watchful policy")
        let turnIndex = approached.turnIndex
        CombatRules.perform(.skill(ambushSkill.id, foe: enemy.id), by: .binder, in: &approach)
        let afterAmbush = try XCTUnwrap(approach.worlds.activeRun?.activeEncounter)
        XCTAssertTrue(afterAmbush.openingAttackConsumed.contains(.binder))
        XCTAssertFalse(afterAmbush.completedFirstActions.contains(.binder))
        XCTAssertEqual(afterAmbush.turnIndex, turnIndex, "Ambush consumed the actor's ordinary turn")
        let frozenAfterUse = afterAmbush
        CombatRules.perform(.skill(ambushSkill.id, foe: enemy.id), by: .binder, in: &approach)
        XCTAssertEqual(approach.worlds.activeRun?.activeEncounter, frozenAfterUse,
                       "a repeated or stale Ambush tap mutated the encounter")

        var quickenFirst = unseen
        quickenFirst.base.binderCharacter.branchDepth["swiftness"] = 3
        quickenFirst.base.binderCharacter.branchDepth["shadow"] = 5
        quickenFirst.worlds.activeRun?.activeEncounter = nil
        WorldRules.beginEncounter(triggeredBy: enemy,
                                  preContact: .init(disclosedEnemyIDs: [enemy.id],
                                                    approachedEnemyID: enemy.id),
                                  runsAutomaticTurns: false, in: &quickenFirst)
        CombatRules.perform(.skill("quicken"), by: .binder, in: &quickenFirst)
        let afterQuicken = try XCTUnwrap(quickenFirst.worlds.activeRun?.activeEncounter)
        XCTAssertFalse(afterQuicken.completedFirstActions.contains(.binder),
                       "Quicken was incorrectly recorded as a normal-cost first action")
        XCTAssertTrue(afterQuicken.openingAttackConsumed.contains(.binder),
                      "choosing Quicken did not close the separate Ambush opportunity")
        XCTAssertFalse(CombatRules.isReady(ambushSkill, for: .binder, in: afterQuicken),
                       "Quicken left Ambush available on its borrowed action")

        var partial = try XCTUnwrap(JSONSerialization.jsonObject(
            with: JSONEncoder().encode(approached)) as? [String: Any])
        var openingObject = try XCTUnwrap(partial["opening"] as? [String: Any])
        openingObject.removeValue(forKey: "pendingFoeActions")
        openingObject.removeValue(forKey: "slipperyPrevented")
        openingObject.removeValue(forKey: "watchfulSuppressedOpening")
        partial["opening"] = openingObject
        let tolerant = try JSONDecoder().decode(
            EncounterState.self, from: JSONSerialization.data(withJSONObject: partial))
        XCTAssertEqual(tolerant.opening?.pendingFoeActions, [])
        XCTAssertEqual(tolerant.opening?.slipperyPrevented, false)
        XCTAssertEqual(tolerant.opening?.watchfulSuppressedOpening, false)
    }

    func testUnseenExcludesOnlyItsOwnerFromOpeningTargetsThroughFirstOrdinaryRound() throws {
        var state = startedRun(book(["terrain": "plains"]), seed: 8_201)
        state.base.binderCharacter.branchDepth["shadow"] = 8
        var companion = CompanionState()
        companion.name = "Quill"
        state.base.roster = [companion]
        state.base.activeParty = [0]
        var run = try XCTUnwrap(state.worlds.activeRun)
        run.companionHP[0] = companion.maxHP
        let enemy = WorldEnemy(id: InstanceID(rawValue: 8201), creatureID: "paper_moth",
                               position: run.playerPosition)
        run.enemies = [enemy]
        state.worlds.activeRun = run
        WorldRules.beginEncounter(triggeredBy: enemy,
                                  preContact: .init(disclosedEnemyIDs: [], approachedEnemyID: nil),
                                  runsAutomaticTurns: false, in: &state)

        let binderHP = try XCTUnwrap(state.worlds.activeRun?.binderHP)
        CombatRules.runAutomaticTurns(in: &state)
        let afterOpening = try XCTUnwrap(state.worlds.activeRun?.activeEncounter)
        XCTAssertEqual(state.worlds.activeRun?.binderHP, binderHP,
                       "Unseen's owner was a legal foe-opening target")
        XCTAssertTrue(afterOpening.log.suffix(2).contains { $0.contains("Quill") },
                      "the visible companion was not used as the legal opening target")
        XCTAssertEqual(afterOpening.concealed[.binder], 1)

        var safety = 0
        while state.worlds.activeRun?.activeEncounter?.roundNumber == 1, safety < 8 {
            CombatRules.advanceTurn(in: &state)
            safety += 1
        }
        XCTAssertNil(state.worlds.activeRun?.activeEncounter?.concealed[.binder],
                     "Unseen lasted beyond the end of the first ordinary round")

        var allUnseen = startedRun(book(["terrain": "plains"]), seed: 8_202)
        allUnseen.base.binderCharacter.branchDepth["shadow"] = 8
        var hiddenCompanion = CompanionState()
        hiddenCompanion.name = "Quill"
        hiddenCompanion.character.branchDepth["shadow"] = 8
        allUnseen.base.roster = [hiddenCompanion]
        allUnseen.base.activeParty = [0]
        var allHiddenRun = try XCTUnwrap(allUnseen.worlds.activeRun)
        allHiddenRun.companionHP[0] = hiddenCompanion.maxHP
        let secondEnemy = WorldEnemy(id: InstanceID(rawValue: 8202), creatureID: "paper_moth",
                                     position: allHiddenRun.playerPosition)
        allHiddenRun.enemies = [secondEnemy]
        allUnseen.worlds.activeRun = allHiddenRun
        WorldRules.beginEncounter(triggeredBy: secondEnemy,
                                  preContact: .init(disclosedEnemyIDs: [], approachedEnemyID: nil),
                                  runsAutomaticTurns: false, in: &allUnseen)
        let beforeAllHidden = try XCTUnwrap(allUnseen.worlds.activeRun?.activeEncounter?.log.count)
        CombatRules.runAutomaticTurns(in: &allUnseen)
        let afterAllHidden = try XCTUnwrap(allUnseen.worlds.activeRun?.activeEncounter)
        XCTAssertTrue(afterAllHidden.opening?.pendingFoeActions.isEmpty == true)
        XCTAssertGreaterThan(afterAllHidden.log.count, beforeAllHidden,
                             "an all-concealed party incorrectly erased every legal target")
    }

    func testUnseenExcludesItsOwnerFromMultiAndAreaOpeningDelivery() throws {
        for (offset, delivery) in [Delivery.multi, .area].enumerated() {
            var state = startedRun(book(["terrain": "plains"]), seed: 8_210 + UInt64(offset))
            state.base.binderCharacter.branchDepth["shadow"] = 8
            var companion = CompanionState()
            companion.name = "Quill"
            state.base.roster = [companion]
            state.base.activeParty = [0]
            var run = try XCTUnwrap(state.worlds.activeRun)
            run.companionHP[0] = companion.maxHP
            let enemy = WorldEnemy(id: InstanceID(rawValue: 8210 + UInt64(offset)),
                                   creatureID: "paper_moth", position: run.playerPosition)
            run.enemies = [enemy]
            state.worlds.activeRun = run
            WorldRules.beginEncounter(triggeredBy: enemy,
                                      preContact: .init(disclosedEnemyIDs: [], approachedEnemyID: nil),
                                      runsAutomaticTurns: false, in: &state)
            state.worlds.activeRun?.activeEncounter?.foes[0].stats.delivery = delivery
            state.worlds.activeRun?.activeEncounter?.foes[0].stats.attack = 20
            let binderHP = try XCTUnwrap(state.worlds.activeRun?.binderHP)
            let companionHP = try XCTUnwrap(state.worlds.activeRun?.companionHP[0])

            CombatRules.runAutomaticTurns(in: &state)

            XCTAssertEqual(state.worlds.activeRun?.binderHP, binderHP,
                           "\(delivery) bypassed opening target legality")
            XCTAssertLessThan(try XCTUnwrap(state.worlds.activeRun?.companionHP[0]), companionHP)
        }
    }

    func testOldEnemyAwakeFlagMigratesToSingleAwarenessAuthority() throws {
        let awake = WorldEnemy(id: InstanceID(rawValue: 71), creatureID: "paper_moth",
                               position: GridPoint(x: 1, y: 1), isAwake: true)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(awake)) as? [String: Any])
        object.removeValue(forKey: "awareness")
        let migrated = try JSONDecoder().decode(WorldEnemy.self,
            from: JSONSerialization.data(withJSONObject: object))
        XCTAssertEqual(migrated.awareness, .pursuing)
        migrated.isAwake ? XCTAssertTrue(true) : XCTFail("Legacy awake state was lost")

        var sleepingObject = object
        sleepingObject["isAwake"] = false
        let sleeping = try JSONDecoder().decode(WorldEnemy.self,
            from: JSONSerialization.data(withJSONObject: sleepingObject))
        XCTAssertEqual(sleeping.awareness, .unaware)
    }

    func testFieldRadiusSkillsArePartyScopedNonstackingAndHomeDoesNotHelp() {
        var state = GameState.newGame()
        state.base.binderCharacter.level = 5
        state.base.binderCharacter.branchDepth["shadow"] = 2
        XCTAssertEqual(WorldRules.fieldConcealment(in: state).radiusReduction, 1)

        var traveller = CompanionState()
        traveller.character.level = 10
        traveller.character.branchDepth["shadow"] = 7
        state.base.roster = [traveller, traveller]
        state.base.activeParty = [0]
        XCTAssertEqual(WorldRules.fieldConcealment(in: state).radiusReduction, 2)
        state.base.activeParty = []
        XCTAssertEqual(WorldRules.fieldConcealment(in: state).radiusReduction, 1,
                       "A skilled person left at Home affected the travelling party")
    }

    func testWalkingIntoAnEnemyOpensAnEncounterAndLogsTheCreature() {
        var state = startedRun(book(["terrain": "plains"]), seed: 62)
        var run = state.worlds.activeRun!
        let target = run.map.neighbours(of: run.playerPosition).first { WorldRules.canEnter($0, in: run.map) }!
        run.enemies = [WorldEnemy(id: InstanceID(rawValue: 7), creatureID: "ink_hound", position: target, isAwake: true)]
        state.worlds.activeRun = run

        let events = WorldRules.step(to: target, in: &state)
        XCTAssertTrue(events.contains(.encounterBegan))
        XCTAssertNotNil(state.worlds.activeRun?.activeEncounter)
        XCTAssertEqual(state.worlds.activeRun?.activeEncounter?.foes.first?.creatureID, "ink_hound")
        XCTAssertTrue(state.reality.discovery.hasEncountered(creature: "ink_hound"))
    }

    // MARK: Banking

    @MainActor
    func testPortalHomeKeepsEverything() {
        let store = GameStore(io: .temporary(name: "portal-\(UUID().uuidString)"))
        store.write("plains")
        store.bindAndDepart()
        store.mutate("stock the satchel") { $0.worlds.activeRun?.satchel.add(9, of: Resources.ore) }

        XCTAssertTrue(store.canPortalHere)
        store.portalHome()

        XCTAssertNil(store.state.worlds.activeRun)
        XCTAssertEqual(store.state.base.resources[Resources.ore], 9, "Portalling out keeps the lot")
        XCTAssertEqual(store.state.reality.lifetime.runsBankedViaPortal, 1)
    }

    @MainActor
    func testCollapseKeepsOnlyAFractionAndBanksMotesToReality() {
        let store = GameStore(io: .temporary(name: "collapse-\(UUID().uuidString)"))
        store.write("plains")
        store.bindAndDepart()
        store.mutate("stock the satchel") { state in
            state.worlds.activeRun?.satchel.add(10, of: Resources.ore)
            state.worlds.activeRun?.satchel.add(4, of: Resources.mote)
        }

        store.endRunWithPartialHaul(reason: "collapse")

        XCTAssertNil(store.state.worlds.activeRun)
        XCTAssertEqual(store.state.base.resources[Resources.ore],
                       Int(10 * Tuning.World.collapseHaulKeptFraction))
        XCTAssertEqual(store.state.reality.motes, Int(4 * Tuning.World.collapseHaulKeptFraction),
                       "Motes bank to Reality, not Base")
        XCTAssertEqual(store.state.reality.lifetime.runsLostToCollapse, 1)
        XCTAssertEqual(store.state.worlds.lastExit?.kind, .collapse)
        XCTAssertEqual(store.state.worlds.lastExit?.lostResources.reduce(0) { $0 + $1.count }, 7,
                       "the recap should list the five ore and two motes that did not return")
    }

    @MainActor
    func testCollapseUsesTheRecoveryFractionFrozenIntoTheRun() {
        let store = GameStore(io: .temporary(name: "collapse-tuning-\(UUID().uuidString)"))
        store.write("plains")
        store.bindAndDepart()
        store.mutate("tune this fixture") { state in
            state.worlds.activeRun?.tuning.collapseRecoveryFraction = 1
            state.worlds.activeRun?.satchel.add(10, of: Resources.ore)
        }

        store.endRunWithPartialHaul(reason: "collapse")

        XCTAssertEqual(store.state.base.resources[Resources.ore], 10)
        XCTAssertEqual(store.state.worlds.lastExit?.haulKeptFraction, 1)
        XCTAssertTrue(store.state.worlds.lastExit?.lostResources.isEmpty == true)
    }

    @MainActor
    func testDefeatIsNotCountedAsCollapse() {
        let store = GameStore(io: .temporary(name: "defeat-outcome-\(UUID().uuidString)"))
        store.write("plains")
        store.bindAndDepart()

        store.endRunWithPartialHaul(reason: "You were carried home.", kind: .defeat)

        XCTAssertEqual(store.state.worlds.lastExit?.kind, .defeat)
        XCTAssertEqual(store.state.reality.lifetime.runsLostToCollapse, 0)
    }

    func testPartialHaulAlwaysReturnsUnusedStartingItems() {
        var state = GameState.newGame()
        state.base.inventory.stacks = []
        var run = WorldRun(runIndex: 1, book: book([:]), mapSeed: 1, rng: SeededRNG(seed: 1),
                           map: WorldMap(width: 1, height: 1, tiles: [Tile()],
                                         entry: GridPoint(x: 0, y: 0)),
                           playerPosition: GridPoint(x: 0, y: 0))
        var salves = ItemStack(id: InstanceID(rawValue: 10), catalogID: "salve", count: 2)
        salves.protectedReturnCount = 2
        run.satchelItems = Inventory(slots: 4, stacks: [salves])
        var rng = SeededRNG(seed: 3)

        GameStore.bankHaul(of: run, into: &state, fraction: 0, rng: &rng)

        XCTAssertEqual(state.base.inventory.stacks.first { $0.catalogID == "salve" }?.count, 2)
        XCTAssertEqual(state.base.inventory.stacks.first?.protectedReturnCount, 0)
    }

    func testConsumedStartingItemsDoNotDuplicateOnPartialReturn() {
        var state = GameState.newGame()
        state.base.inventory.stacks = []
        var run = WorldRun(runIndex: 1, book: book([:]), mapSeed: 1, rng: SeededRNG(seed: 1),
                           map: WorldMap(width: 1, height: 1, tiles: [Tile()],
                                         entry: GridPoint(x: 0, y: 0)),
                           playerPosition: GridPoint(x: 0, y: 0))
        var salves = ItemStack(id: InstanceID(rawValue: 10), catalogID: "salve", count: 2)
        salves.protectedReturnCount = 2
        _ = salves.removing(1)
        run.satchelItems = Inventory(slots: 4, stacks: [salves])
        var rng = SeededRNG(seed: 3)

        GameStore.bankHaul(of: run, into: &state, fraction: 0, rng: &rng)

        XCTAssertEqual(state.base.inventory.stacks.first { $0.catalogID == "salve" }?.count, 1)
    }

    func testNewLootMergedIntoStartingStackRemainsAtRisk() {
        var state = GameState.newGame()
        state.base.inventory.stacks = []
        var run = WorldRun(runIndex: 1, book: book([:]), mapSeed: 1, rng: SeededRNG(seed: 1),
                           map: WorldMap(width: 1, height: 1, tiles: [Tile()],
                                         entry: GridPoint(x: 0, y: 0)),
                           playerPosition: GridPoint(x: 0, y: 0))
        var salves = ItemStack(id: InstanceID(rawValue: 10), catalogID: "salve", count: 2)
        salves.protectedReturnCount = 2
        run.satchelItems = Inventory(slots: 4, stacks: [salves])
        _ = run.satchelItems.add(ItemStack(id: InstanceID(rawValue: 11), catalogID: "salve", count: 2))
        var rng = SeededRNG(seed: 3)

        let banked = GameStore.bankHaul(of: run, into: &state, fraction: 0, rng: &rng)

        XCTAssertEqual(state.base.inventory.stacks.first { $0.catalogID == "salve" }?.count, 2,
                       "the packed pair returns, while the acquired pair is exposed to loss")
        XCTAssertEqual(banked.lostItems.first { $0.name == "Salve" }?.count, 2)
    }

    /// The pillar, at world scale: a kill mid-run resumes on the same tile of the same map.
    @MainActor
    func testTheWholeMapSurvivesAForceQuit() throws {
        let io = SaveFileIO.temporary(name: "world-kill-\(UUID().uuidString)")
        defer { io.deleteEverything() }

        let first = GameStore(io: io)
        // Every slot filled. This test is about the map surviving a kill, and a book left partly
        // to chance can roll itself a world that collapses inside these five steps — which fails
        // it for a reason that has nothing to do with persistence.
        first.write("caverns")
        first.write("frostbound")
        first.write("sparse_ore")
        first.write("dim_sky")
        first.bindAndDepart()
        // Wander a bit so fog, position and RNG have all moved off their initial values.
        for _ in 0..<5 {
            guard let run = first.state.worlds.activeRun else { break }
            guard let step = run.map.neighbours(of: run.playerPosition)
                .first(where: { WorldRules.canEnter($0, in: run.map) }) else { break }
            first.step(to: step)
        }
        first.flushNow()
        let before = try XCTUnwrap(first.state.worlds.activeRun)

        let second = GameStore(io: io) // cold launch
        let after = try XCTUnwrap(second.state.worlds.activeRun)

        XCTAssertEqual(after.map, before.map)
        XCTAssertEqual(after.playerPosition, before.playerPosition)
        XCTAssertEqual(after.enemies, before.enemies)
        XCTAssertEqual(after.turnsTaken, before.turnsTaken)
        XCTAssertEqual(after.rng, before.rng)
    }

    /// Pillar 2, stated as a test: nothing advances unless the player acts.
    @MainActor
    func testNothingHappensWithoutAPlayerAction() async throws {
        let store = GameStore(io: .temporary(name: "idle-\(UUID().uuidString)"))
        store.write("gilded_veins") // fastest-decaying symbol we have
        store.bindAndDepart()
        let before = try XCTUnwrap(store.state.worlds.activeRun)

        try await Task.sleep(for: .milliseconds(300))

        let after = try XCTUnwrap(store.state.worlds.activeRun)
        XCTAssertEqual(after.stability, before.stability, "Time passing must not decay a world")
        XCTAssertEqual(after.turnsTaken, before.turnsTaken)
        XCTAssertEqual(after.enemies, before.enemies)
    }

    // MARK: Helpers

    private func startedRun(_ composition: BoundBook, seed: UInt64) -> GameState {
        var state = GameState.newGame()
        let world = Worldgen.generate(book: composition, seed: seed)
        state.worlds.runIndex = 1
        state.worlds.activeRun = WorldRun(
            runIndex: 1,
            book: composition,
            mapSeed: seed,
            rng: SeededRNG(seed: seed).derived(0xA11CE),
            map: world.map,
            playerPosition: world.start,
            enemies: world.enemies
        )
        return state
    }

    /// **Stability is a range, because the world is** (Aimee, 6 Aug).
    ///
    /// The headline counted only what you wrote, which is right — the panel must not reveal rolled
    /// content. But every unwritten subject is rolled at bind, and a rolled focus carries its own
    /// stability delta, its own greed, and its own capacity to contradict what you wrote. Six of
    /// eight unwritten is normal, so the number shown could be off by a lot.
    ///
    /// The design is careful about this everywhere else: **the price is certain, the world is not.**
    func testStabilityIsRangedWhileTheWorldIsUnwritten() {
        var page = Page()
        page.runes = [
            PlacedRune(id: InstanceID(rawValue: 1), content: .target("illumination"),
                       hand: .crude, origin: PageCell(column: 0, row: 0), shapeID: "crude_block"),
            PlacedRune(id: InstanceID(rawValue: 2), content: .source("sun"),
                       hand: .crude, origin: PageCell(column: 2, row: 0), shapeID: "crude_block"),
        ]
        page.links = [MarkLink(InstanceID(rawValue: 1), InstanceID(rawValue: 2))]

        let sparse = BookProjection.project(page: page, seed: 99)
        XCTAssertLessThan(sparse.stabilityScore.lowerBound, sparse.stabilityScore.upperBound,
                          "one subject written of eight and stability is shown as a certainty")
        XCTAssertLessThanOrEqual(sparse.turnsUntilCollapse.lowerBound,
                                 sparse.turnsUntilCollapse.upperBound)
    }

    /// Write every subject and there is nothing left to roll — so the band closes to a point, and
    /// the promise "the price is certain, the world is not" becomes "and you can make it certain".
    func testAFullyWrittenPageIsCertain() {
        var page = Page()
        var next: UInt64 = 1
        let pairs: [(PressureTargetID, PressureSourceID)] = [
            ("illumination", "sun"), ("thermal", "magma"), ("hydrology", "sea"),
            ("substrate", "granite"), ("relief", "granite"), ("vitality", "root"),
            ("atmosphere", "wind"), ("cycle", "moon"),
        ]
        for (index, pair) in pairs.enumerated() {
            page.runes.append(PlacedRune(id: InstanceID(rawValue: next), content: .target(pair.0),
                                         hand: .crude, origin: PageCell(column: 0, row: index),
                                         shapeID: "refined_dot"))
            let target = next
            next += 1
            page.runes.append(PlacedRune(id: InstanceID(rawValue: next), content: .source(pair.1),
                                         hand: .crude, origin: PageCell(column: 1, row: index),
                                         shapeID: "refined_dot"))
            page.links.insert(MarkLink(InstanceID(rawValue: target), InstanceID(rawValue: next)))
            next += 1
        }
        XCTAssertTrue(BookProjection.project(page: page, seed: 7).stabilityScore.isPoint,
                      "nothing left unwritten and the world is still uncertain")
    }

    /// **And writing more narrows the band** — which makes the value of specificity a number for
    /// the first time.
    func testWritingMoreSubjectsNarrowsTheStabilityBand() {
        func band(_ subjects: [(PressureTargetID, PressureSourceID)]) -> Int {
            var page = Page()
            var next: UInt64 = 1
            for (index, pair) in subjects.enumerated() {
                page.runes.append(PlacedRune(id: InstanceID(rawValue: next), content: .target(pair.0),
                                             hand: .crude,
                                             origin: PageCell(column: 0, row: index * 2),
                                             shapeID: "refined_dot"))
                let target = next
                next += 1
                page.runes.append(PlacedRune(id: InstanceID(rawValue: next), content: .source(pair.1),
                                             hand: .crude,
                                             origin: PageCell(column: 1, row: index * 2),
                                             shapeID: "refined_dot"))
                page.links.insert(MarkLink(InstanceID(rawValue: target), InstanceID(rawValue: next)))
                next += 1
            }
            let projection = BookProjection.project(page: page, seed: 4242)
            return projection.stabilityScore.upperBound - projection.stabilityScore.lowerBound
        }

        let one = band([("illumination", "sun")])
        let many = band([("illumination", "sun"), ("thermal", "magma"), ("hydrology", "sea"),
                         ("substrate", "granite"), ("relief", "granite"), ("vitality", "root"),
                         ("atmosphere", "wind"), ("cycle", "moon")])
        XCTAssertLessThan(many, one,
                          "writing every subject left as much uncertainty as writing one")
    }

    func testReportWhatEachFocusCostsNow() {
        let cases: [(PressureSourceID, PressureTargetID)] = [
            ("sun","illumination"), ("gold","substrate"), ("magma","illumination"),
            ("root","vitality"), ("crystal","illumination"), ("sea","hydrology"),
            ("granite","substrate"), ("ice","hydrology"), ("wind","atmosphere"),
            ("salt","vitality"), ("granite","relief"),
        ]
        print("WHAT A FOCUS COSTS (was: sun −25, gold −18, wind +16)")
        for (source, target) in cases {
            let cost = BookRules.greedDelta(for: [Sigil(id: InstanceID(rawValue: 1),
                                                        source: source, target: target)])
            print(String(format: "  %-10s on %-13s %+d", (source.rawValue as NSString).utf8String!,
                         (target.rawValue as NSString).utf8String!, cost))
        }
    }

    func testReportWhatARealBookCostsNow() {
        let books: [(String, [SlotID: SymbolID])] = [
            ("plains · verdant · sparse ore · dim sky",
             ["terrain": "plains", "biome": "verdant", "bounty": "sparse_ore", "quirk": "dim_sky"]),
            ("plains · verdant · rich ore · gilded",
             ["terrain": "plains", "biome": "verdant", "bounty": "rich_ore", "quirk": "gilded_veins"]),
            ("caverns · ashen · rich ore · gilded",
             ["terrain": "caverns", "biome": "ashen", "bounty": "rich_ore", "quirk": "gilded_veins"]),
        ]
        print("WHAT A BOOK SCORES — authored deltas vs emergent greed")
        for (label, symbols) in books {
            let bound = book(symbols)
            let authored = BookRules.dangerTradeDelta(symbolIDs: bound.allSymbolIDs)
            let greed = BookRules.greedDelta(for: BookRules.sigils(for: bound))
            print(String(format: "  %-42s authored %+4d   greed %+4d   score %3d",
                         (label as NSString).utf8String!, authored, greed,
                         BookRules.stabilityScore(delta: authored + greed)))
        }
    }

    /// **A sun is not an outrage** (Aimee, 7 Aug: *"the sun as a focus SHOULD NOT DESTABILIZE SO
    /// MUCH MORE THAN EVERYTHING ELSE WHEN IT IS THE MOST STANDARD SOURCE OF ILLUMINATION IN ANY
    /// WORLD"*).
    ///
    /// Greed was charged against each subject's *baseline*, and four of eight baselines are zero —
    /// so "ordinary" meant pitch dark, and any light at all read as an extravagant demand. A sun
    /// cost −25: more than a vein of gold, and more than half of Rich Ore, whose whole identity is
    /// greed. The meter was teaching that light is reckless and darkness is safe, which is exactly
    /// backwards from the fiction.
    func testASunCostsLessThanAVeinOfGold() {
        func cost(_ source: PressureSourceID, _ target: PressureTargetID) -> Int {
            BookRules.greedDelta(for: [Sigil(id: InstanceID(rawValue: 1),
                                             source: source, target: target)])
        }
        let sun = cost("sun", "illumination")
        let gold = cost("gold", "substrate")
        XCTAssertGreaterThan(sun, gold, "a sunny world is greedier than a gold-veined one")
        XCTAssertGreaterThan(sun, -10, "a plain sun is still being charged like a demand")
    }

    /// **A world resists being asked for more; it does not resist being asked for less.**
    ///
    /// So a barren world is a gift and a teeming one scales — which is the half Aimee described:
    /// *"a barren world increases stability since it's worse than the norm, and a verdant lush
    /// world slowly scales up destabilization."*
    func testAskingForLessThanOrdinaryCalmsAWorld() {
        let teeming = BookRules.greedDelta(for: [
            Sigil(id: InstanceID(rawValue: 1), source: "bloom", target: "vitality", intensity: .great),
            Sigil(id: InstanceID(rawValue: 2), source: "root", target: "vitality", intensity: .great),
        ])
        let barren = BookRules.greedDelta(for: [
            Sigil(id: InstanceID(rawValue: 1), source: "salt", target: "vitality", intensity: .great),
        ])
        XCTAssertLessThan(teeming, 0, "a lush world costs nothing to hold open")
        XCTAssertGreaterThan(barren, 0, "a dead world isn't easier to hold than a living one")
    }

    /// **Wealth is charged heavily; strangeness lightly.** Deviation alone would bill a mountainous
    /// world like a gold-veined one, which is the other half of the fault — greed was supposed to
    /// mean *you asked the world for wealth*, and it meant *you asked the world for anything*.
    func testWealthCostsMoreThanMereStrangeness() {
        func cost(_ source: PressureSourceID, _ target: PressureTargetID) -> Int {
            BookRules.greedDelta(for: [Sigil(id: InstanceID(rawValue: 1), source: source,
                                             target: target, intensity: .great)])
        }
        XCTAssertLessThan(cost("gold", "substrate"), cost("granite", "relief"),
                          "a mountain is billed like a gold seam")
    }

    @MainActor
    func testNaturalAnchorIsAVisibleCheaperRouteToTheSameDurableRealm() throws {
        let blank = book([:])
        var found: (seed: UInt64, map: WorldMap, sites: [PlacedSite], anchor: PlacedSite)?
        for seed in UInt64(1)...200 {
            let world = Worldgen.generate(book: blank, seed: seed)
            if let anchor = world.sites.first(where: { $0.definition?.providesNaturalAnchor == true }) {
                found = (seed, world.map, world.sites, anchor)
                break
            }
        }
        let seeded = try XCTUnwrap(found)
        let store = GameStore(io: .temporary(name: "natural-anchor-\(UUID().uuidString)"))
        store.mutate("stand at an anchor point") { state in
            state.base.stations[Stations.anchorage] = StationState(isUnlocked: true, tier: 0)
            state.base.essence = 100
            state.worlds.runIndex = 1
            state.worlds.activeRun = WorldRun(runIndex: 1, book: blank, mapSeed: seeded.seed,
                                               rng: SeededRNG(seed: seeded.seed), map: seeded.map,
                                               playerPosition: seeded.anchor.position,
                                               sites: seeded.sites)
        }

        XCTAssertNotNil(store.naturalAnchorHere)
        let cost = store.naturalAnchorCost
        XCTAssertEqual(cost, 25, "a blank book's 100-essence born premium makes a 25-essence seam")
        XCTAssertTrue(store.anchorAtNaturalPoint())
        XCTAssertEqual(store.state.base.essence, 100 - cost)
        XCTAssertEqual(store.state.worlds.anchoredRealms.first?.route, .naturalPoint)
        XCTAssertEqual(store.state.worlds.anchoredRealms.first?.world.map, seeded.map)
        XCTAssertFalse(store.anchorAtNaturalPoint(), "one realm cannot be paid for twice")
    }

    @MainActor
    func testAnchorFrameOnlyConsumesOnValidOrdinaryGroundAndChargesNoEssence() throws {
        let blank = book([:])
        let generated = Worldgen.generate(book: blank, seed: 404)
        let clear = try XCTUnwrap(generated.map.allPoints.first {
            generated.map[$0].content == .empty && !generated.map[$0].isCrumbled
        })
        var run = WorldRun(runIndex: 1, book: blank, mapSeed: 404, rng: SeededRNG(seed: 404),
                           map: generated.map, playerPosition: generated.start)
        XCTAssertTrue(run.satchelItems.add(ItemStack(id: InstanceID(rawValue: 77),
                                                     catalogID: Items.anchorFrame)))
        let store = GameStore(io: .temporary(name: "anchor-frame-\(UUID().uuidString)"))
        store.mutate("carry frame") { state in
            state.base.stations[Stations.anchorage] = StationState(isUnlocked: true, tier: 0)
            state.base.essence = 63
            state.worlds.activeRun = run
        }

        XCTAssertFalse(store.placeAnchorFrame(), "a portal is not a valid placement tile")
        XCTAssertNotNil(store.carriedAnchorFrame, "an invalid attempt must not consume the frame")
        store.mutate("step onto clear ground") { $0.worlds.activeRun?.playerPosition = clear }

        XCTAssertTrue(store.placeAnchorFrame())
        XCTAssertNil(store.carriedAnchorFrame)
        XCTAssertEqual(store.state.base.essence, 63, "the crafted frame has no second essence cost")
        XCTAssertEqual(store.state.worlds.anchoredRealms.first?.route, .craftedFrame)
    }

    @MainActor
    func testAnchorFrameVisibleRequirementsDeriveFromRecipeNeeds() {
        XCTAssertEqual(AnchorFrameRules.groupedNeeds, [
            .init(property: .hardness, minimum: 65, count: 2),
            .init(property: .density, minimum: 65, count: 2),
            .init(property: .flexibility, minimum: 55, count: 1),
            .init(property: .reactivity, minimum: 65, count: 1),
        ])
        XCTAssertEqual(AnchorFrameRules.groupedNeeds.reduce(0) { $0 + $1.count },
                       AnchorFrameRules.needs.count)
    }

    @MainActor
    func testAnchorFrameRecipeUsesSixDistinctWeakestQualifyingSamples() throws {
        func sample(hardness: Double = 0, density: Double = 0,
                    flexibility: Double = 0, reactivity: Double = 0) -> MaterialSample {
            MaterialSample(kind: .chitin,
                           properties: MaterialProperties(hardness: hardness, density: density,
                                                          flexibility: flexibility, reactivity: reactivity),
                           grade: max(hardness, density, flexibility, reactivity), source: "test world")
        }
        let store = GameStore(io: .temporary(name: "frame-recipe-\(UUID().uuidString)"))
        store.mutate("stock Anchorage") { state in
            state.base.stations[Stations.anchorage] = StationState(isUnlocked: true, tier: 0)
            state.base.essence = 100
            let samples = [sample(hardness: 65), sample(hardness: 66),
                           sample(density: 65), sample(density: 66),
                           sample(flexibility: 55), sample(reactivity: 65),
                           sample(hardness: 100, density: 100, flexibility: 100, reactivity: 100)]
            state.base.materialReserve = MaterialReserve(units: samples.enumerated().map { index, sample in
                MaterialReserveUnit(id: .init(rawValue: "anchor-frame-\(index)"), sample: sample)
            })
        }

        XCTAssertTrue(store.craftAnchorFrame())
        XCTAssertEqual(store.state.base.essence, 40)
        XCTAssertEqual(store.state.base.materialReserve.units.map(\.sample.grade), [100],
                       "weakest qualifying stock should be consumed first")
        XCTAssertEqual(store.state.base.inventory.stacks.first(where: { $0.catalogID == Items.anchorFrame })?.count, 1)
    }

    @MainActor
    func testSustainSettlementSpendsOnlyChosenEssenceAndDormancyNeverDeletes() {
        let blank = book([:])
        let generated = Worldgen.generate(book: blank, seed: 9)
        let run = WorldRun(runIndex: 1, book: blank, mapSeed: 9, rng: SeededRNG(seed: 9),
                           map: generated.map, playerPosition: generated.start)
        let store = GameStore(io: .temporary(name: "sustain-\(UUID().uuidString)"))
        store.mutate("prepare settlement") { state in
            state.base.essence = 40
            state.worlds.anchoredRealms = [
                AnchoredRealm(runIndex: 1, name: "First", route: .bornAnchored, world: run),
                AnchoredRealm(runIndex: 2, name: "Chosen", route: .naturalPoint,
                              sustainObligation: 10, world: run),
                AnchoredRealm(runIndex: 3, name: "Resting", route: .craftedFrame,
                              sustainObligation: 20, assignedCompanions: [0], world: run),
            ]
            state.worlds.pendingAnchorSettlement = true
        }

        XCTAssertFalse(store.settleAnchoredRealms(decisions: [:]),
                       "an untouched settlement must never rest every realm")
        XCTAssertEqual(store.state.base.essence, 40)
        XCTAssertFalse(store.state.worlds.anchoredRealms[2].isDormant)

        XCTAssertTrue(store.settleAnchoredRealms(decisions: [
            2: .sustain,
            3: .letRest,
        ]))
        XCTAssertEqual(store.state.base.essence, 30)
        XCTAssertFalse(store.state.worlds.anchoredRealms[1].isDormant)
        XCTAssertTrue(store.state.worlds.anchoredRealms[2].isDormant)
        XCTAssertTrue(store.state.worlds.anchoredRealms[2].assignedCompanions.isEmpty)
        XCTAssertEqual(store.state.worlds.anchoredRealms.count, 3, "dormancy must never delete a realm")
        XCTAssertTrue(store.reactivateAnchoredRealm(3))
        XCTAssertFalse(store.state.worlds.anchoredRealms[2].isDormant)
    }

    @MainActor
    func testRealmAssignmentIsExclusiveAndProductionIsVisible() {
        let blank = book([:])
        let generated = Worldgen.generate(book: blank, seed: 12)
        let run = WorldRun(runIndex: 1, book: blank, mapSeed: 12, rng: SeededRNG(seed: 12),
                           map: generated.map, playerPosition: generated.start)
        let store = GameStore(io: .temporary(name: "realm-assignment-\(UUID().uuidString)"))
        store.mutate("prepare realms") { state in
            state.worlds.anchoredRealms = [
                AnchoredRealm(runIndex: 1, name: "One", route: .bornAnchored, world: run),
                AnchoredRealm(runIndex: 2, name: "Two", route: .naturalPoint, world: run),
            ]
        }

        XCTAssertTrue(store.assignCompanion(0, toAnchoredRealm: 1))
        XCTAssertFalse(store.state.base.activeParty.contains(0))
        XCTAssertEqual(store.state.worlds.anchoredRealms[0].productionContribution,
                       Tuning.Anchoring.worldworkBaseContribution + store.state.base.roster[0].worldwork)
        XCTAssertTrue(store.assignCompanion(0, toAnchoredRealm: 2))
        XCTAssertTrue(store.state.worlds.anchoredRealms[0].assignedCompanions.isEmpty)
        XCTAssertEqual(store.state.worlds.anchoredRealms[0].productionContribution, 0)
        XCTAssertEqual(store.state.worlds.anchoredRealms[1].assignedCompanions, [0])
    }

    @MainActor
    func testTakingRealmWorkerIsAtomicAndReturningSendsThemHome() throws {
        let blank = book([:])
        let generated = Worldgen.generate(book: blank, seed: 13)
        let run = WorldRun(runIndex: 1, book: blank, mapSeed: 13, rng: SeededRNG(seed: 13),
                           map: generated.map, playerPosition: generated.start)
        let store = GameStore(io: .temporary(name: "realm-party-transfer-\(UUID().uuidString)"))
        store.mutate("prepare worker") { state in
            var worker = CompanionState()
            worker.name = "Worker"
            worker.worldwork = 2
            state.base.roster = [CompanionState(), worker]
            state.base.activeParty = [0]
            state.worlds.anchoredRealms = [
                AnchoredRealm(runIndex: 1, name: "Moss Archive", route: .bornAnchored,
                              sustainObligation: 10, assignedCompanions: [1], world: run),
            ]
            GameStore.recalculateAnchorProduction(in: &state)
        }

        let preview = try XCTUnwrap(store.partyTransferPreview(for: 1))
        XCTAssertEqual(preview.source, .anchoredRealm(id: 1, name: "Moss Archive"))
        XCTAssertEqual(preview.realmProductionBefore, 3)
        XCTAssertEqual(preview.realmProductionAfter, 0)
        XCTAssertEqual(preview.realmShortfallBefore, 7)
        XCTAssertEqual(preview.realmShortfallAfter, 10)

        XCTAssertFalse(store.setComing(1, true, expected: .home), "stale source must not transfer")
        XCTAssertEqual(store.state.worlds.anchoredRealms[0].assignedCompanions, [1])
        XCTAssertEqual(store.setComing(preview), .committed)
        XCTAssertEqual(store.state.base.activeParty, [0, 1])
        XCTAssertTrue(store.state.worlds.anchoredRealms[0].assignedCompanions.isEmpty)
        XCTAssertEqual(store.state.worlds.anchoredRealms[0].productionContribution, 0)

        XCTAssertTrue(store.setComing(1, false, expected: .activeParty))
        XCTAssertEqual(store.placement(of: 1), .home)
        XCTAssertFalse(store.state.base.activeParty.contains(1))
        XCTAssertTrue(store.state.worlds.anchoredRealms[0].assignedCompanions.isEmpty,
                      "returning Home must not restore the old realm posting")
    }

    @MainActor
    func testPartyTransferRefusesWhenDisplayedRealmImpactGoesStale() throws {
        let blank = book([:])
        let generated = Worldgen.generate(book: blank, seed: 13)
        let run = WorldRun(runIndex: 1, book: blank, mapSeed: 13, rng: SeededRNG(seed: 13),
                           map: generated.map, playerPosition: generated.start)
        let store = GameStore(io: .temporary(name: "stale-party-impact-\(UUID().uuidString)"))
        store.mutate("prepare realm worker") { state in
            var worker = CompanionState()
            worker.name = "Worker"
            worker.worldwork = 2
            state.base.roster = [CompanionState(), worker]
            state.base.activeParty = [0]
            state.worlds.anchoredRealms = [
                AnchoredRealm(runIndex: 1, name: "Moss Archive", route: .bornAnchored,
                              sustainObligation: 10, assignedCompanions: [1],
                              world: run)
            ]
            GameStore.recalculateAnchorProduction(in: &state)
        }
        let quote = try XCTUnwrap(store.partyTransferPreview(for: 1))
        store.mutate("change contribution behind confirmation") { state in
            state.base.roster[1].worldwork = 6
            GameStore.recalculateAnchorProduction(in: &state)
        }

        guard case .refused = store.setComing(quote) else {
            return XCTFail("A stale production quote moved the worker")
        }
        XCTAssertEqual(store.placement(of: 1), .anchoredRealm(id: 1, name: "Moss Archive"))
        XCTAssertFalse(store.state.base.activeParty.contains(1))
    }

    @MainActor
    func testTakingHomeKeeperPreviewsAndSuspendsStationBenefit() throws {
        let store = GameStore(io: .temporary(name: "keeper-party-transfer-\(UUID().uuidString)"))
        store.mutate("prepare keeper") { state in
            var keeper = CompanionState()
            keeper.name = "Halloway"
            keeper.traveller = "halloway"
            state.base.roster = [CompanionState(), keeper]
            state.base.activeParty = [0]
            state.base.stations[Stations.blacksmith] = StationState(isUnlocked: true, tier: 0)
        }
        let blacksmith = try XCTUnwrap(ContentCatalog.shared.stations.first { $0.id == Stations.blacksmith })
        XCTAssertTrue(StationStaffingRules.keeperIsHome(for: blacksmith, in: store.state))

        let preview = try XCTUnwrap(store.partyTransferPreview(for: 1))
        XCTAssertEqual(preview.source, .home)
        XCTAssertEqual(preview.stationNames, ["Blacksmith"])
        XCTAssertTrue(store.setComing(1, true, expected: .home))
        XCTAssertFalse(StationStaffingRules.keeperIsHome(for: blacksmith, in: store.state))
    }

    func testLegacyContradictoryPersonPlacementsReconcileDeterministically() throws {
        let blank = book([:])
        let generated = Worldgen.generate(book: blank, seed: 14)
        let run = WorldRun(runIndex: 1, book: blank, mapSeed: 14, rng: SeededRNG(seed: 14),
                           map: generated.map, playerPosition: generated.start)
        var state = GameState.newGame()
        state.base.roster = [CompanionState(), CompanionState(), CompanionState()]
        state.base.activeParty = [1, 1, 99]
        state.worlds.anchoredRealms = [
            AnchoredRealm(runIndex: 2, name: "Later", route: .naturalPoint,
                          assignedCompanions: [0, 1, 2, 2], world: run),
            AnchoredRealm(runIndex: 1, name: "Earlier", route: .bornAnchored,
                          assignedCompanions: [0, 2], world: run),
            AnchoredRealm(runIndex: 3, name: "Dormant", route: .craftedFrame, isDormant: true,
                          assignedCompanions: [0], world: run),
        ]

        let decoded = try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(state))
        XCTAssertEqual(decoded.base.activeParty, [1], "party wins and duplicates/invalid IDs are removed")
        XCTAssertTrue(decoded.worlds.anchoredRealms[0].assignedCompanions.isEmpty)
        XCTAssertEqual(decoded.worlds.anchoredRealms[1].assignedCompanions, [0, 2],
                       "lowest stable realm ID wins a contradictory posting")
        XCTAssertTrue(decoded.worlds.anchoredRealms[2].assignedCompanions.isEmpty)
        XCTAssertEqual(decoded.worlds.anchoredRealms[1].productionContribution, 4)
    }
}
