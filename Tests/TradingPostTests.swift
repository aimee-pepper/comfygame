import XCTest
@testable import Bookbinder

final class TradingPostTests: XCTestCase {
    func testOldBaseSaveDefaultsToEmptyTradingPostAndSeparateZeroGoldWallet() throws {
        let old = try SaveCodec.makeDecoder().decode(BaseState.self, from: Data("{\"essence\":37}".utf8))

        XCTAssertEqual(old.goldCoins, 0)
        XCTAssertEqual(old.tradingPost, TradingPostState())
        XCTAssertEqual(old.resources["gold"], 0, "Gold Ore remains a resource, not the wallet")
    }

    func testPartialTradingPostSaveToleratesNewFields() throws {
        let saved = Data("{\"refreshSequence\":4}".utf8)
        let restored = try SaveCodec.makeDecoder().decode(TradingPostState.self, from: saved)
        XCTAssertEqual(restored.refreshSequence, 4)
        XCTAssertEqual(restored.stock, [])
        XCTAssertEqual(restored.nextStockLineID, 1)
        XCTAssertEqual(restored.inventoryRevision, 0)
    }

    func testEveryResourceHasAnExplicitTradeClassification() {
        XCTAssertEqual(TradingPostRules.unclassifiedResourceIDs(), [])
        XCTAssertEqual(TradingPostRules.tradeBand(for: "essence_raw"), .nontradeable)
        XCTAssertEqual(TradingPostRules.tradeBand(for: "mote"), .nontradeable)
        XCTAssertEqual(TradingPostRules.tradeBand(for: "gold"), .precious)
    }

    func testEveryCatalogItemHasExplicitTransferabilityClassification() {
        XCTAssertEqual(TradingPostRules.unclassifiedItemIDs(), [])
        XCTAssertTrue(TradingPostRules.isAuthoredTransferable("salve_lesser"))
        XCTAssertTrue(TradingPostRules.isAuthoredTransferable("blade_chipped"))
        XCTAssertFalse(TradingPostRules.isAuthoredTransferable("anchor_frame"))
        XCTAssertFalse(TradingPostRules.isAuthoredTransferable("two_natured_blade"))
    }

    func testOldItemFlagsDefaultFalseAndRoundTripThroughWornGear() throws {
        let old = try SaveCodec.makeDecoder().decode(ItemStack.self, from: Data(
            "{\"id\":{\"rawValue\":1},\"catalogID\":\"salve_lesser\",\"count\":2}".utf8))
        XCTAssertFalse(old.isFavorite)
        XCTAssertFalse(old.isLocked)

        var blade = ItemStack(id: InstanceID(rawValue: 77), catalogID: "blade_keen")
        blade.isFavorite = true
        blade.isLocked = true
        let worn = EquippedPiece(blade)
        let saved = try SaveCodec.makeEncoder().encode(worn)
        let restored = try SaveCodec.makeDecoder().decode(EquippedPiece.self, from: saved)
        XCTAssertTrue(restored.isFavorite)
        XCTAssertTrue(restored.isLocked)
        XCTAssertEqual(restored.asStack(id: InstanceID(rawValue: 999)).id, blade.id)
        XCTAssertTrue(restored.asStack(id: InstanceID(rawValue: 999)).isFavorite)
        XCTAssertTrue(restored.asStack(id: InstanceID(rawValue: 999)).isLocked)
    }

    func testFavoriteAndLockedStacksNeverMergeWithUnprotectedStock() {
        var inventory = Inventory(slots: 4)
        var favorite = ItemStack(id: InstanceID(rawValue: 1), catalogID: "salve_lesser", count: 2)
        favorite.isFavorite = true
        XCTAssertTrue(inventory.add(favorite))
        XCTAssertTrue(inventory.add(ItemStack(id: InstanceID(rawValue: 2),
                                              catalogID: "salve_lesser", count: 3)))
        XCTAssertEqual(inventory.stacks.count, 2)
    }

    func testRefreshIsPersistedIdempotentAndDeterministic() throws {
        var first = BaseState.newGame()
        var second = BaseState.newGame()

        XCTAssertTrue(TradingPostRules.refresh(after: 14, campaignSeed: 0xB00C, in: &first))
        XCTAssertTrue(TradingPostRules.refresh(after: 14, campaignSeed: 0xB00C, in: &second))
        XCTAssertEqual(first.tradingPost, second.tradingPost)
        XCTAssertFalse(TradingPostRules.refresh(after: 14, campaignSeed: 0xB00C, in: &first))

        let saved = try SaveCodec.makeEncoder().encode(first)
        let restored = try SaveCodec.makeDecoder().decode(BaseState.self, from: saved)
        XCTAssertEqual(restored.tradingPost, first.tradingPost)
        XCTAssertTrue(restored.tradingPost.stock.allSatisfy { line in
            line.remainingQuantity > 0 && line.unitPrice >= 3
        })
    }

    func testResolvedRunWrapperAdvancesOnePersistedSnapshotPerSequentialCall() {
        let book = BoundBook(symbols: [:], randomlyFilled: [], essencePaid: 0)
        let generated = Worldgen.generate(book: book, seed: 440)
        let run = WorldRun(runIndex: 1, book: book, mapSeed: 440, rng: SeededRNG(seed: 440),
                           map: generated.map, playerPosition: generated.start)
        let nextGenerated = Worldgen.generate(book: book, seed: 441)
        let nextRun = WorldRun(runIndex: 2, book: book, mapSeed: 441, rng: SeededRNG(seed: 441),
                               map: nextGenerated.map, playerPosition: nextGenerated.start)
        var state = GameState.newGame()

        GameStore.refreshTradingPost(after: run, in: &state)
        XCTAssertEqual(state.base.tradingPost.refreshSequence, 1)
        XCTAssertEqual(state.base.tradingPost.expeditionOutcomeID, 1)
        GameStore.refreshTradingPost(after: nextRun, in: &state)
        XCTAssertEqual(state.base.tradingPost.refreshSequence, 2)
        XCTAssertEqual(state.base.tradingPost.expeditionOutcomeID, 2)
    }

    func testResourceSaleUsesExactBandsAndCommitsAtomically() {
        var base = BaseState.newGame()
        base.resources.add(4, of: "rubble")
        base.resources.add(2, of: "copper")
        base.resources.add(1, of: "gold")
        base.essence = 30

        let preview = TradingPostRules.previewSale(
            resources: ["rubble": 3, "copper": 2, "gold": 1], essence: 20, in: base)
        XCTAssertEqual(preview?.goldTotal, 21) // 3 + 4 + 12 + 2 essence conversions
        XCTAssertEqual(TradingPostRules.commit(try! XCTUnwrap(preview), in: &base), .committed)
        XCTAssertEqual(base.goldCoins, 21)
        XCTAssertEqual(base.resources["rubble"], 1)
        XCTAssertEqual(base.resources["copper"], 0)
        XCTAssertEqual(base.resources["gold"], 0)
        XCTAssertEqual(base.essence, 10)
    }

    func testRawEssenceCannotBeSoldAndStaleSaleChangesNothing() throws {
        var base = BaseState.newGame()
        base.resources.add(4, of: "essence_raw")
        base.resources.add(2, of: "rubble")
        XCTAssertNil(TradingPostRules.previewSale(resources: ["essence_raw": 1], in: base))

        let preview = try XCTUnwrap(TradingPostRules.previewSale(resources: ["rubble": 1], in: base))
        base.tradingPost.inventoryRevision += 1
        let before = base
        XCTAssertEqual(TradingPostRules.commit(preview, in: &base), .stale)
        XCTAssertEqual(base, before)
    }

    func testBuyingStockAndEssenceDebitsExactPersistedOffer() throws {
        var base = BaseState.newGame()
        base.goldCoins = 20
        base.tradingPost.stock = [
            TradingPostStockLine(id: 44, kind: .resource("clay"), remainingQuantity: 3, unitPrice: 3)
        ]
        base.tradingPost.essenceBundlesRemaining = 2

        let stock = try XCTUnwrap(TradingPostRules.previewPurchase(lineID: 44, quantity: 2, in: base))
        XCTAssertEqual(TradingPostRules.commit(stock, in: &base), .committed)
        XCTAssertEqual(base.goldCoins, 14)
        XCTAssertEqual(base.resources["clay"], 2)
        XCTAssertEqual(base.tradingPost.stock[0].remainingQuantity, 1)

        let essence = try XCTUnwrap(TradingPostRules.previewEssencePurchase(bundles: 1, in: base))
        XCTAssertEqual(TradingPostRules.commit(essence, in: &base), .committed)
        XCTAssertEqual(base.goldCoins, 6)
        XCTAssertEqual(base.essence, Tuning.Economy.startingEssence + 10)
        XCTAssertEqual(base.tradingPost.essenceBundlesRemaining, 1)
    }

    func testBuyThenSellAlwaysLosesGold() throws {
        var base = BaseState.newGame()
        base.goldCoins = 10
        base.tradingPost.stock = [
            TradingPostStockLine(id: 1, kind: .resource("rubble"), remainingQuantity: 1, unitPrice: 3)
        ]
        let buy = try XCTUnwrap(TradingPostRules.previewPurchase(lineID: 1, quantity: 1, in: base))
        XCTAssertEqual(TradingPostRules.commit(buy, in: &base), .committed)
        let sell = try XCTUnwrap(TradingPostRules.previewSale(resources: ["rubble": 1], in: base))
        XCTAssertEqual(TradingPostRules.commit(sell, in: &base), .committed)
        XCTAssertEqual(base.goldCoins, 8)
    }

    func testOrdinaryItemAndGearPricesAndProtectedExclusions() {
        let salve = ItemStack(id: InstanceID(rawValue: 1), catalogID: "salve_lesser", count: 3)
        XCTAssertEqual(TradingPostRules.saleUnitPrice(for: salve), 2)
        let blade = ItemStack(id: InstanceID(rawValue: 2), catalogID: "blade_keen")
        XCTAssertEqual(TradingPostRules.saleUnitPrice(for: blade),
                       max(4, Int(floor(4 * blade.effectivePower))))

        var unidentified = salve
        unidentified.identified = false
        XCTAssertNil(TradingPostRules.saleUnitPrice(for: unidentified))
        var favorite = salve
        favorite.isFavorite = true
        XCTAssertNil(TradingPostRules.saleUnitPrice(for: favorite))
        var locked = salve
        locked.isLocked = true
        XCTAssertNil(TradingPostRules.saleUnitPrice(for: locked))
        XCTAssertNil(TradingPostRules.saleUnitPrice(for:
            ItemStack(id: InstanceID(rawValue: 3), catalogID: "two_natured_blade")))
        var legacy = blade
        legacy.gearProfile?.legacyPowerCredit = 1
        XCTAssertNil(TradingPostRules.saleUnitPrice(for: legacy))
    }

    func testItemSaleRemovesExactStoredAndOverflowQuantitiesAtomically() throws {
        var base = BaseState.newGame()
        XCTAssertTrue(base.inventory.add(ItemStack(id: InstanceID(rawValue: 201),
                                                    catalogID: "salve_lesser", count: 3)))
        base.spillover = [ItemStack(id: InstanceID(rawValue: 202), catalogID: "blade_chipped")]
        let requests = [
            TradingPostItemSaleRequest(location: .stored, stackID: InstanceID(rawValue: 201), quantity: 2),
            TradingPostItemSaleRequest(location: .overflow, stackID: InstanceID(rawValue: 202), quantity: 1)
        ]
        let preview = try XCTUnwrap(TradingPostRules.previewSale(resources: [:], items: requests, in: base))
        let bladePrice = try XCTUnwrap(TradingPostRules.saleUnitPrice(for: base.spillover[0]))
        XCTAssertEqual(preview.goldTotal, 4 + bladePrice)
        XCTAssertEqual(TradingPostRules.commit(preview, in: &base), .committed)
        XCTAssertEqual(base.inventory.stacks.first?.id, InstanceID(rawValue: 201))
        XCTAssertEqual(base.inventory.stacks.first?.count, 1)
        XCTAssertEqual(base.spillover, [])
        XCTAssertEqual(base.goldCoins, 4 + bladePrice)
    }

    func testChangedItemSnapshotRejectsSaleWithoutRemovingOrCreditingAnything() throws {
        var base = BaseState.newGame()
        XCTAssertTrue(base.inventory.add(ItemStack(id: InstanceID(rawValue: 301),
                                                    catalogID: "salve_lesser", count: 2)))
        let request = TradingPostItemSaleRequest(location: .stored,
                                                 stackID: InstanceID(rawValue: 301), quantity: 1)
        let preview = try XCTUnwrap(TradingPostRules.previewSale(resources: [:], items: [request], in: base))
        base.inventory.stacks[0].isLocked = true
        let before = base
        XCTAssertEqual(TradingPostRules.commit(preview, in: &base), .invalid)
        XCTAssertEqual(base, before)
    }
}
