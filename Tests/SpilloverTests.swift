import XCTest
@testable import Bookbinder

/// Q10: banking never discards. Anything that doesn't fit waits at the Storehouse until the player
/// sorts it, at home, with full information.
@MainActor
final class SpilloverTests: XCTestCase {

    func testLiveStationScreensDoNotAdvertiseUnavailableFutureProducts() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(
            contentsOf: root.appending(path: "Sources/Screens/StationViews.swift"),
            encoding: .utf8
        )

        let distilleryStart = try XCTUnwrap(source.range(of: "struct DistilleryView"))
        let channelworksStart = try XCTUnwrap(source.range(
            of: "struct ChannelworksView",
            range: distilleryStart.upperBound..<source.endIndex
        ))
        let reliquaryStart = try XCTUnwrap(source.range(
            of: "struct ReliquaryView",
            range: channelworksStart.upperBound..<source.endIndex
        ))
        let distillery = String(source[distilleryStart.lowerBound..<channelworksStart.lowerBound])
        let channelworks = String(source[channelworksStart.lowerBound..<reliquaryStart.lowerBound])

        XCTAssertTrue(distillery.contains("Crystallise essence"))
        XCTAssertTrue(distillery.contains("attunementCard(attunement)"))
        XCTAssertFalse(distillery.contains("ComingLater"))
        XCTAssertTrue(channelworks.contains("Construct Heat Conduit fixture"))
        XCTAssertTrue(channelworks.contains("Requires one Heat core"))
        XCTAssertTrue(channelworks.contains("Heat core ready"))
        XCTAssertTrue(channelworks.contains(".disabled(!hasHeatCore)"))
        XCTAssertFalse(channelworks.contains("ComingLater"))
    }

    func testWorkshopShowsItsResearchWithoutAWallOfOtherStationPlaceholders() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(
            contentsOf: root.appending(path: "Sources/Screens/StationViews.swift"),
            encoding: .utf8
        )
        let start = try XCTUnwrap(source.range(of: "struct WorkshopView"))
        let end = try XCTUnwrap(source.range(of: "struct ScriptoriumView", range: start.upperBound..<source.endIndex))
        let workshop = String(source[start.lowerBound..<end.lowerBound])

        XCTAssertTrue(workshop.contains("ResearchTree()"))
        XCTAssertFalse(workshop.contains("ComingLater"))
        XCTAssertFalse(workshop.contains("branchesInOrder.filter { $0.station != nil }"))
    }

    func testAnchorageWorkerRowsKeepIdentityFactsClearOfTheReturnAction() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(
            contentsOf: root.appending(path: "Sources/Screens/StationViews.swift"),
            encoding: .utf8
        )
        let start = try XCTUnwrap(source.range(of: "struct AnchorageView"))
        let end = try XCTUnwrap(source.range(
            of: "private extension AnchorRoute",
            range: start.upperBound..<source.endIndex
        ))
        let anchorage = String(source[start.lowerBound..<end.lowerBound])

        XCTAssertTrue(anchorage.contains("VStack(alignment: .leading, spacing: 2)"))
        XCTAssertTrue(anchorage.contains("Worldwork \\(worker.worldwork) · +\\(contribution)"))
        XCTAssertTrue(anchorage.contains("Button(\"Return\")"))
        XCTAssertTrue(anchorage.contains(".buttonStyle(.bordered)"))
        XCTAssertTrue(anchorage.contains(".frame(minHeight: 44)"))
    }

    func testDormantRealmNamesExactEssenceShortfallBesideDisabledReactivation() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(
            contentsOf: root.appending(path: "Sources/Screens/StationViews.swift"),
            encoding: .utf8
        )
        let start = try XCTUnwrap(source.range(of: "struct AnchorageView"))
        let end = try XCTUnwrap(source.range(
            of: "private extension AnchorRoute",
            range: start.upperBound..<source.endIndex
        ))
        let anchorage = String(source[start.lowerBound..<end.lowerBound])

        XCTAssertTrue(anchorage.contains("let missingEssence = max(0, cost - store.state.base.essence)"))
        XCTAssertTrue(anchorage.contains("Needs \\(missingEssence) more Essence to reactivate."))
        XCTAssertTrue(anchorage.contains(".disabled(store.state.base.essence < cost)"))
    }

    func testAnchorageReportsStaleAssignmentRevisitAndReactivationFailures() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(
            contentsOf: root.appending(path: "Sources/Screens/StationViews.swift"),
            encoding: .utf8
        )
        let start = try XCTUnwrap(source.range(of: "struct AnchorageView"))
        let end = try XCTUnwrap(source.range(
            of: "private extension AnchorRoute",
            range: start.upperBound..<source.endIndex
        ))
        let anchorage = String(source[start.lowerBound..<end.lowerBound])

        XCTAssertTrue(anchorage.contains("if store.assignCompanion(index, toAnchoredRealm: realm.id)"))
        XCTAssertTrue(anchorage.contains("if store.revisitAnchoredRealm(realm.id)"))
        XCTAssertTrue(anchorage.contains("if store.reactivateAnchoredRealm(realm.id)"))
        XCTAssertTrue(anchorage.contains("Anchorage action not completed"))
        XCTAssertTrue(anchorage.contains("if store.craftAnchorFrame()"))
        XCTAssertTrue(anchorage.contains("The stock, Essence, or Storehouse space changed."))
        XCTAssertFalse(anchorage.contains("Button(store.state.base.roster[index].name) {\n                                            store.assignCompanion"))
        XCTAssertFalse(anchorage.contains("Button {\n                        store.craftAnchorFrame()"))
    }

    func testStorehouseSortingActionsRemainOutsideScrollableDetails() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(
            contentsOf: root.appending(path: "Sources/Screens/StationViews.swift"),
            encoding: .utf8
        )

        XCTAssertTrue(source.contains(".safeAreaInset(edge: .bottom, spacing: 0) { sortingActionBar }"))
        XCTAssertTrue(source.contains(".safeAreaInset(edge: .bottom, spacing: 0) { swapActionBar }"))
        XCTAssertTrue(source.contains("Text(\"Throw away\").frame(maxWidth: .infinity)"))
        XCTAssertTrue(source.contains("Button(action: commitSwap)"))
    }

    func testInstrumentImprovementReportsAStaleReadinessFailure() throws {
        let source = try String(contentsOfFile: "Sources/Screens/StationViews.swift", encoding: .utf8)

        XCTAssertTrue(source.contains("if store.improveInstrument(target.id)"))
        XCTAssertTrue(source.contains("Instrument not improved"))
        XCTAssertTrue(source.contains("The qualifying stock or Essence changed."))
        XCTAssertFalse(source.contains("Button(\"Improve\") { store.improveInstrument(target.id) }"))
    }


    func testBankingAFullStorehouseSpillsRatherThanDrops() {
        let store = makeStore()
        let carried = 3
        store.mutate("test: fill home and satchel") { state in
            state.base.inventory = Inventory(slots: 1, stacks: [stack("kept")])
            for index in 0..<carried {
                state.worlds.activeRun?.satchelItems.add(stack("hauled-\(index)"))
            }
        }
        let broughtHome = store.state.worlds.activeRun?.satchelItems.stacks.count ?? 0
        XCTAssertEqual(broughtHome, carried, "the satchel didn't actually hold the test's loot")

        store.portalHome()

        XCTAssertEqual(store.state.base.inventory.stacks.count, 1, "storehouse was already full")
        XCTAssertEqual(store.spillover.count, carried,
                       "loot vanished on banking — the exact thing Q10 forbids")
    }

    func testNothingSpillsWhenThereIsRoom() {
        let store = makeStore()
        store.mutate("test: haul one home") { state in
            state.base.inventory = Inventory(slots: 8)
            state.worlds.activeRun?.satchelItems.add(stack("hauled"))
        }
        store.portalHome()
        XCTAssertEqual(store.state.base.inventory.stacks.count, 1)
        XCTAssertTrue(store.spillover.isEmpty)
    }

    func testStoringASpilledItemMovesItExactlyOnce() {
        let store = makeStore()
        let spilled = stack("spilled")
        store.mutate("test: spill") { state in
            state.base.inventory = Inventory(slots: 2)
            state.base.spillover = [spilled]
        }
        XCTAssertTrue(store.storeSpilled(spilled))
        XCTAssertEqual(store.state.base.inventory.stacks.map(\.id), [spilled.id])
        XCTAssertTrue(store.spillover.isEmpty)

        // Asking again must not conjure a second copy.
        XCTAssertFalse(store.storeSpilled(spilled))
        XCTAssertEqual(store.state.base.inventory.stacks.count, 1)
    }

    func testStoringIsRefusedWhileTheStorehouseIsStillFull() {
        let store = makeStore()
        let spilled = stack("spilled")
        store.mutate("test: spill into a full house") { state in
            state.base.inventory = Inventory(slots: 1, stacks: [stack("kept")])
            state.base.spillover = [spilled]
        }
        XCTAssertFalse(store.storeSpilled(spilled))
        XCTAssertEqual(store.spillover.count, 1, "refusing to store must not consume the item")
    }

    func testSwappingExchangesTheTwoWithoutLosingEither() {
        let store = makeStore()
        let spilled = stack("spilled")
        let stored = stack("stored")
        store.mutate("test: spill into a full house") { state in
            state.base.inventory = Inventory(slots: 1, stacks: [stored])
            state.base.spillover = [spilled]
        }
        store.swapSpilled(spilled, for: stored)

        XCTAssertEqual(store.state.base.inventory.stacks.map(\.id), [spilled.id])
        XCTAssertEqual(store.spillover.map(\.id), [stored.id],
                       "the displaced item must go back to the pile, not be destroyed")
    }

    func testStaleStoreQuoteRefusesWithoutMovingTheUpdatedStack() throws {
        let store = makeStore()
        let spilled = stack("spilled")
        store.mutate("prepare waiting stack") { state in
            state.base.inventory = Inventory(slots: 2)
            state.base.spillover = [spilled]
        }
        guard case .allowed(let quote) = store.storeSpilledQuote(spilled) else {
            return XCTFail("Valid waiting stack did not quote")
        }
        store.mutate("change waiting quantity") { $0.base.spillover[0].count = 2 }

        guard case .refused = store.storeSpilled(quote) else {
            return XCTFail("Stale store quote committed")
        }
        XCTAssertTrue(store.state.base.inventory.stacks.isEmpty)
        XCTAssertEqual(store.spillover.first?.count, 2)
    }

    func testStaleSwapQuoteRefusesWithoutLosingEitherSide() throws {
        let store = makeStore()
        let spilled = stack("spilled")
        let stored = stack("stored")
        store.mutate("prepare quoted swap") { state in
            state.base.inventory = Inventory(slots: 1, stacks: [stored])
            state.base.spillover = [spilled]
        }
        guard case .allowed(let quote) = store.swapSpilledQuote(spilled, for: stored) else {
            return XCTFail("Valid swap did not quote")
        }
        store.mutate("change stored quantity") { $0.base.inventory.stacks[0].count = 2 }

        guard case .refused = store.swapSpilled(quote) else {
            return XCTFail("Stale swap quote committed")
        }
        XCTAssertEqual(store.spillover.map(\.id), [spilled.id])
        XCTAssertEqual(store.state.base.inventory.stacks.first?.count, 2)
    }

    func testDiscardingIsTheOnlyWayLootLeaves() {
        let store = makeStore()
        let spilled = stack("spilled")
        store.mutate("test: spill") { state in state.base.spillover = [spilled] }
        store.discardSpilled(spilled)
        XCTAssertTrue(store.spillover.isEmpty)
        XCTAssertTrue(store.state.base.inventory.stacks.isEmpty)
    }

    func testStaleDiscardQuoteCannotDeleteAChangedWaitingStack() throws {
        let store = makeStore()
        let spilled = stack("discard-stale")
        store.mutate("prepare discard quote") { $0.base.spillover = [spilled] }
        guard case .allowed(let quote) = store.discardSpilledQuote(spilled) else {
            return XCTFail("Current waiting stack did not quote for discard")
        }
        store.mutate("change waiting stack behind discard confirmation") {
            $0.base.spillover[0].count = 2
        }

        guard case .refused = store.discardSpilled(quote) else {
            return XCTFail("A stale discard quote deleted the changed stack")
        }
        XCTAssertEqual(store.spillover.first?.count, 2)
        XCTAssertEqual(store.spillover.count, 1)
    }

    func testCapacityMutationAfterStoreQuoteRefusesWithoutLossOrDuplication() throws {
        let store = makeStore()
        let spilled = stack("capacity-stale")
        store.mutate("prepare capacity-safe store") {
            $0.base.inventory = Inventory(slots: 1)
            $0.base.spillover = [spilled]
        }
        guard case .allowed(let quote) = store.storeSpilledQuote(spilled) else {
            return XCTFail("Capacity-safe store did not quote")
        }
        store.mutate("fill Storehouse behind store confirmation") {
            $0.base.inventory.stacks = [self.stack("new-occupant")]
        }

        guard case .refused = store.storeSpilled(quote) else {
            return XCTFail("Store committed after capacity disappeared")
        }
        XCTAssertEqual(store.spillover, [spilled])
        XCTAssertEqual(store.state.base.inventory.stacks.count, 1)
        XCTAssertEqual(store.spillover.count + store.state.base.inventory.stacks.count, 2)
    }

    func testCapacityMutationAfterSwapQuoteRefusesWithoutLossOrDuplication() throws {
        let store = makeStore()
        let spilled = stack("swap-capacity-stale")
        let stored = stack("swap-stored")
        store.mutate("prepare capacity-safe swap") {
            $0.base.inventory = Inventory(slots: 1, stacks: [stored])
            $0.base.spillover = [spilled]
        }
        guard case .allowed(let quote) = store.swapSpilledQuote(spilled, for: stored) else {
            return XCTFail("Capacity-safe swap did not quote")
        }
        store.mutate("remove Storehouse capacity behind swap confirmation") {
            $0.base.inventory.slots = 0
        }

        guard case .refused = store.swapSpilled(quote) else {
            return XCTFail("Swap committed after capacity disappeared")
        }
        XCTAssertEqual(store.spillover, [spilled])
        XCTAssertEqual(store.state.base.inventory.stacks, [stored])
        XCTAssertEqual(store.spillover.count + store.state.base.inventory.stacks.count, 2)
    }

    func testSpilloverSurvivesAForceQuit() {
        let io = SaveFileIO.temporary(name: "spillover-\(UUID().uuidString)")
        let spilled = stack("spilled")
        do {
            let store = GameStore(io: io)
            store.mutate("test: spill", flush: true) { state in state.base.spillover = [spilled] }
        }
        let resumed = GameStore(io: io)
        XCTAssertEqual(resumed.spillover.map(\.id), [spilled.id],
                       "loot waiting to be sorted didn't survive a relaunch")
    }

    func testStorehouseDetailSheetsResolveCurrentStateInsteadOfFrozenQuantities() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf: root.appending(path: "Sources/Screens/StationViews.swift"),
                                encoding: .utf8)
        XCTAssertTrue(source.contains("private var currentAmount: Int"))
        XCTAssertTrue(source.contains("private var currentStack: ItemStack?"))
        XCTAssertTrue(source.contains("private var currentBin: ItemStack?"))
        XCTAssertTrue(source.contains("No longer stored"))
    }

    // MARK: Helpers

    private func makeStore() -> GameStore {
        let store = GameStore(io: .temporary(name: "spillover-\(UUID().uuidString)"))
        store.mutate("test: fund") { state in state.base.essence = 500 }
        store.write("plains")
        store.bindAndDepart()
        return store
    }

    /// **Distinct by name**, because items of the same kind now share a bin — three of the same
    /// curio take one slot, so a test about slot pressure has to use three different things.
    private func stack(_ name: String) -> ItemStack {
        ItemStack(id: InstanceID(rawValue: UInt64(abs(name.hashValue))),
                  catalogID: ItemID(rawValue: name))
    }
}
