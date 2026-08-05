import XCTest
@testable import Bookbinder

/// Q10: banking never discards. Anything that doesn't fit waits at the Storehouse until the player
/// sorts it, at home, with full information.
@MainActor
final class SpilloverTests: XCTestCase {

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

    func testDiscardingIsTheOnlyWayLootLeaves() {
        let store = makeStore()
        let spilled = stack("spilled")
        store.mutate("test: spill") { state in state.base.spillover = [spilled] }
        store.discardSpilled(spilled)
        XCTAssertTrue(store.spillover.isEmpty)
        XCTAssertTrue(store.state.base.inventory.stacks.isEmpty)
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

    // MARK: Helpers

    private func makeStore() -> GameStore {
        let store = GameStore(io: .temporary(name: "spillover-\(UUID().uuidString)"))
        store.mutate("test: fund") { state in state.base.essence = 500 }
        store.setSymbol("plains", in: "terrain")
        store.bindAndDepart()
        return store
    }

    private func stack(_ name: String) -> ItemStack {
        ItemStack(id: InstanceID(rawValue: UInt64(abs(name.hashValue))),
                  catalogID: ItemID(rawValue: "curio_humming_shard"))
    }
}
