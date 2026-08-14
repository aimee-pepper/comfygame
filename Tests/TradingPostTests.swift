import XCTest
@testable import Bookbinder

final class TradingPostTests: XCTestCase {
    func testTradingPostProprietorUsesExactVanceIdentity() throws {
        XCTAssertEqual(TradingPostPresentation.proprietorID, TravellerID(rawValue: "vance"))
        let vance = try XCTUnwrap(ContentCatalog.shared.traveller(TradingPostPresentation.proprietorID))
        XCTAssertEqual(vance.name, "Vance")
    }

    func testTradingPostPresentationUsesAuthoredNamesAndHidesUnknownIDs() throws {
        let clay = try XCTUnwrap(ContentCatalog.shared.resource("clay"))
        let salve = try XCTUnwrap(ContentCatalog.shared.item("salve_lesser"))
        XCTAssertEqual(TradingPostPresentation.resourceName(clay.id), clay.name)
        XCTAssertEqual(TradingPostPresentation.itemName(salve.id), salve.name)

        let unknownResource: ResourceID = "internal_missing_resource_id"
        let unknownItem: ItemID = "internal_missing_item_id"
        XCTAssertEqual(TradingPostPresentation.resourceName(unknownResource), "Unknown resource")
        XCTAssertEqual(TradingPostPresentation.itemName(unknownItem), "Unknown item")
        XCTAssertFalse(TradingPostPresentation.resourceName(unknownResource)
            .contains(unknownResource.rawValue))
        XCTAssertFalse(TradingPostPresentation.itemName(unknownItem)
            .contains(unknownItem.rawValue))
    }

    func testUnavailableBuyStockKeepsPurchaseLanguage() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf: root.appending(path: "Sources/Screens/TradingPostView.swift"),
                                encoding: .utf8)

        XCTAssertTrue(source.contains("case unavailablePurchase"))
        XCTAssertTrue(source.contains("case .buyStock, .buyEssence, .unavailablePurchase: true"))
        XCTAssertFalse(source.contains("case unavailable\n"))
        XCTAssertTrue(source.contains("You can inspect this stock, but Vance cannot sell it yet."))
        XCTAssertFalse(source.contains("capacity-safe purchase path"))
        XCTAssertTrue(source.contains("NamedCharacterPixelIdentity("))
        XCTAssertTrue(source.contains("travellerID: person?.id"))
        XCTAssertTrue(source.contains("TradingPostPresentation.proprietorID"))
    }

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

    func testLegacyResourceStockRowDecodesRoundTripsAndRemainsPurchasable() throws {
        let modern = TradingPostStockLine(id: 9, kind: .resource("clay"),
                                          remainingQuantity: 2, unitPrice: 3)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(
            with: SaveCodec.makeEncoder().encode(modern)) as? [String: Any])
        object.removeValue(forKey: "frozenUnits")
        let legacy = try SaveCodec.makeDecoder().decode(
            TradingPostStockLine.self, from: JSONSerialization.data(withJSONObject: object))
        XCTAssertEqual(legacy.frozenUnits, [])
        XCTAssertEqual(try SaveCodec.makeDecoder().decode(
            TradingPostStockLine.self, from: SaveCodec.makeEncoder().encode(legacy)), legacy)

        var base = BaseState.newGame()
        base.goldCoins = 6
        base.tradingPost.stock = [legacy]
        let preview = try XCTUnwrap(TradingPostRules.previewPurchase(lineID: 9, quantity: 2, in: base))
        XCTAssertEqual(TradingPostRules.commit(preview, in: &base), .committed)
        XCTAssertEqual(base.resources["clay"], 2)
        XCTAssertEqual(base.goldCoins, 0)
    }

    func testLegacyItemAndMaterialRowsDecodeButFailClosedWithoutFrozenIdentity() throws {
        let sample = MaterialSample(kind: .hide, properties: .init(flexibility: 30),
                                    grade: 28, source: "legacy supplier")
        for modern in [
            TradingPostStockLine(id: 10, kind: .item("salve_lesser"),
                                 remainingQuantity: 1, unitPrice: 6),
            TradingPostStockLine(id: 11, kind: .material(sample),
                                 remainingQuantity: 1, unitPrice: 3)
        ] {
            var object = try XCTUnwrap(JSONSerialization.jsonObject(
                with: SaveCodec.makeEncoder().encode(modern)) as? [String: Any])
            object.removeValue(forKey: "frozenUnits")
            let legacy = try SaveCodec.makeDecoder().decode(
                TradingPostStockLine.self, from: JSONSerialization.data(withJSONObject: object))
            XCTAssertEqual(legacy.frozenUnits, [])
            var base = BaseState.newGame()
            base.goldCoins = 100
            base.tradingPost.stock = [legacy]
            XCTAssertNil(TradingPostRules.previewPurchase(lineID: legacy.id, quantity: 1, in: base))
        }
    }

    func testEveryResourceHasAnExplicitTradeClassification() throws {
        XCTAssertTrue(ContentCatalog.shared.resources.allSatisfy {
            TradingPostRules.tradeBand(for: $0.id) == $0.tradeBand
        })
        XCTAssertEqual(TradingPostRules.tradeBand(for: "essence_raw"), .nontradeable)
        XCTAssertEqual(TradingPostRules.tradeBand(for: "mote"), .nontradeable)
        XCTAssertEqual(TradingPostRules.tradeBand(for: "gold"), .precious)
        XCTAssertNil(TradingPostRules.tradeBand(for: "missing_resource"))

        var object = try XCTUnwrap(JSONSerialization.jsonObject(
            with: JSONEncoder().encode(try XCTUnwrap(ContentCatalog.shared.resource("clay"))))
            as? [String: Any])
        object.removeValue(forKey: "tradeBand")
        XCTAssertThrowsError(try JSONDecoder().decode(
            ResourceDef.self, from: JSONSerialization.data(withJSONObject: object)))
    }

    func testEveryCatalogItemHasExplicitTransferabilityClassification() throws {
        XCTAssertTrue(TradingPostRules.isAuthoredTransferable("salve_lesser"))
        XCTAssertTrue(TradingPostRules.isAuthoredTransferable("blade_chipped"))
        XCTAssertFalse(TradingPostRules.isAuthoredTransferable("anchor_frame"))
        XCTAssertFalse(TradingPostRules.isAuthoredTransferable("two_natured_blade"))
        XCTAssertFalse(TradingPostRules.isAuthoredTransferable("missing_item"))

        var object = try XCTUnwrap(JSONSerialization.jsonObject(
            with: JSONEncoder().encode(try XCTUnwrap(ContentCatalog.shared.item("salve_lesser"))))
            as? [String: Any])
        object.removeValue(forKey: "tradingPostDisposition")
        XCTAssertThrowsError(try JSONDecoder().decode(
            ItemDef.self, from: JSONSerialization.data(withJSONObject: object)))
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

    func testCompleteRefreshFreezesBoundedKnownShelvesAndOneTierOneWeapon() throws {
        var first = BaseState.newGame()
        first.knownConsumableRecipes = ["salve_lesser", "salve", "salve_greater"]
        var second = first
        XCTAssertTrue(TradingPostRules.refresh(after: 30, campaignSeed: 0xCAFE, in: &first))
        XCTAssertTrue(TradingPostRules.refresh(after: 30, campaignSeed: 0xCAFE, in: &second))
        XCTAssertEqual(first.tradingPost, second.tradingPost)

        let materials = first.tradingPost.stock.filter {
            if case .material = $0.kind { return true }; return false
        }
        let itemLines = first.tradingPost.stock.filter {
            if case .item = $0.kind { return true }; return false
        }
        let equipment = itemLines.filter { line in
            guard case .item(let id) = line.kind else { return false }
            return ContentCatalog.shared.item(id)?.gear != nil
        }
        let consumables = itemLines.filter { line in
            guard case .item(let id) = line.kind else { return false }
            return ContentCatalog.shared.item(id)?.kind == .consumable
        }
        XCTAssertLessThanOrEqual(materials.count, 2)
        XCTAssertLessThanOrEqual(consumables.count, 2)
        XCTAssertEqual(equipment.count, 1)
        XCTAssertEqual(ContentCatalog.shared.item(equipment[0].frozenUnits[0].catalogID)?.gear?.tier, 1)
        XCTAssertEqual(ContentCatalog.shared.item(equipment[0].frozenUnits[0].catalogID)?.gear?.slot, .weapon)
        XCTAssertEqual(equipment[0].remainingQuantity, 1)
        XCTAssertEqual(equipment[0].unitPrice,
                       try XCTUnwrap(TradingPostRules.saleUnitPrice(for: equipment[0].frozenUnits[0])) * 3)
        XCTAssertTrue(consumables.allSatisfy { line in
            guard case .item(let id) = line.kind,
                  let rarity = ContentCatalog.shared.item(id)?.rarity else { return false }
            return first.knownConsumableRecipes.contains(id)
                && (rarity == .common || rarity == .uncommon)
                && (1...2).contains(line.remainingQuantity)
                && line.unitPrice == (rarity == .common ? 6 : 15)
                && line.frozenUnits.count == line.remainingQuantity
        })
        XCTAssertTrue(materials.allSatisfy { line in
            guard case .material(let sample) = line.kind else { return false }
            return line.remainingQuantity == 1 && line.unitPrice == 3
                && line.frozenUnits.first?.materials == [sample]
                && sample.source == "Vance's supplier" && sample.qualifier == nil
                && (25...39).contains(Int(sample.grade))
        })

        let restored = try SaveCodec.makeDecoder().decode(
            BaseState.self, from: SaveCodec.makeEncoder().encode(first))
        XCTAssertEqual(restored.tradingPost, first.tradingPost)
    }

    func testOwnedWeaponRefreshAllowsAnyOrdinaryTierOneSlotAndExcludesForbiddenGear() {
        var sawNonWeapon = false
        for seed in UInt64(1)...100 where !sawNonWeapon {
            var base = BaseState.newGame()
            base.inventory.stacks = [
                ItemStack(id: InstanceID(rawValue: 400), catalogID: "blade_chipped")
            ]
            XCTAssertTrue(TradingPostRules.refresh(after: 1, campaignSeed: seed, in: &base))
            let equipment = base.tradingPost.stock.first { line in
                guard case .item(let id) = line.kind else { return false }
                return ContentCatalog.shared.item(id)?.gear != nil
            }
            guard let equipment, case .item(let id) = equipment.kind,
                  let gear = ContentCatalog.shared.item(id)?.gear else {
                return XCTFail("every refresh requires one equipment line")
            }
            XCTAssertEqual(gear.tier, 1)
            XCTAssertNil(gear.breaks)
            XCTAssertTrue(TradingPostRules.isAuthoredTransferable(id))
            sawNonWeapon = gear.slot != .weapon
        }
        XCTAssertTrue(sawNonWeapon, "weapon ownership must broaden the frozen refresh eligibility")
    }

    func testFrozenItemPurchaseUsesWaitingAndRejectsStaleSnapshotAtomically() throws {
        var base = BaseState.newGame()
        base.knownConsumableRecipes = ["salve_lesser"]
        base.inventory.slots = 0
        base.inventory.stacks = []
        base.goldCoins = 10_000
        XCTAssertTrue(TradingPostRules.refresh(after: 80, campaignSeed: 0xBAD5EED, in: &base))
        let equipment = try XCTUnwrap(base.tradingPost.stock.first { line in
            guard case .item(let id) = line.kind else { return false }
            return ContentCatalog.shared.item(id)?.gear != nil
        })
        let frozen = try XCTUnwrap(equipment.frozenUnits.first)
        let preview = try XCTUnwrap(TradingPostRules.previewPurchase(
            lineID: equipment.id, quantity: 1, in: base))
        let stale = preview
        XCTAssertEqual(TradingPostRules.commit(preview, in: &base), .committed)
        XCTAssertEqual(base.spillover.last, frozen)
        XCTAssertEqual(base.tradingPost.stock.first(where: { $0.id == equipment.id })?.remainingQuantity, 0)

        let before = base
        XCTAssertEqual(TradingPostRules.commit(stale, in: &base), .stale)
        XCTAssertEqual(base, before)
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

        GameStore.refreshTradingPost(after: run, outcomeID: 1, in: &state)
        XCTAssertEqual(state.base.tradingPost.refreshSequence, 1)
        XCTAssertEqual(state.base.tradingPost.expeditionOutcomeID, 1)
        GameStore.refreshTradingPost(after: nextRun, outcomeID: 2, in: &state)
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

    func testMaterialSaleQuotesAndCommitsOnlyTheExplicitExactReserveUnit() throws {
        let coarse = MaterialSample(kind: .hide, properties: .init(flexibility: 12),
                                    grade: 19, source: "reed grazer", qualifier: "mottled")
        let fine = MaterialSample(kind: .hide, properties: .init(flexibility: 81),
                                  grade: 84, source: "ridge prowler", qualifier: "ashen")
        var base = BaseState.newGame()
        base.materialReserve = MaterialReserve(units: [
            .init(id: MaterialReserveUnitID(rawValue: "hide-coarse"), sample: coarse),
            .init(id: MaterialReserveUnitID(rawValue: "hide-fine"), sample: fine)
        ])
        let selected = try XCTUnwrap(base.materialReserve.selections().first {
            $0.unitID == MaterialReserveUnitID(rawValue: "hide-coarse")
        })
        let preview = try XCTUnwrap(TradingPostRules.previewMaterialSale([selected], in: base))
        XCTAssertEqual(preview.selections, [selected])
        XCTAssertEqual(preview.goldTotal, 1)

        XCTAssertEqual(TradingPostRules.commit(preview, in: &base), .committed)
        XCTAssertEqual(base.goldCoins, 1)
        XCTAssertEqual(base.materialReserve.selections().map(\.unitID),
                       [MaterialReserveUnitID(rawValue: "hide-fine")])
        XCTAssertEqual(base.tradingPost.stock.last?.kind, .material(coarse))
        XCTAssertEqual(base.tradingPost.stock.last?.unitPrice,
                       TradingPostRules.materialSaleUnitPrice(for: coarse) + 1)
        XCTAssertEqual(base.inventory.stacks, [])
        XCTAssertEqual(base.spillover, [])
    }

    func testMaterialSalePreviewRejectsDuplicateAndCommitRejectsStaleOrChangedReceiptAtomically() throws {
        let sample = MaterialSample(kind: .bone, properties: .init(hardness: 44),
                                    grade: 42, source: "fen hart", qualifier: "pale")
        var base = BaseState.newGame()
        base.materialReserve = MaterialReserve(units: [
            .init(id: MaterialReserveUnitID(rawValue: "bone-1"), sample: sample)
        ])
        let selected = try XCTUnwrap(base.materialReserve.selections().first)
        XCTAssertNil(TradingPostRules.previewMaterialSale([selected, selected], in: base))

        let preview = try XCTUnwrap(TradingPostRules.previewMaterialSale([selected], in: base))
        base.tradingPost.inventoryRevision &+= 1
        let staleBefore = base
        XCTAssertEqual(TradingPostRules.commit(preview, in: &base), .stale)
        XCTAssertEqual(base, staleBefore)

        var changed = selected
        changed.sample.grade = 99
        let invalid = TradingPostRules.MaterialSalePreview(
            revision: base.tradingPost.inventoryRevision, selections: [changed],
            unitPrices: [TradingPostRules.materialSaleUnitPrice(for: changed.sample)], goldTotal: 5)
        let invalidBefore = base
        XCTAssertEqual(TradingPostRules.commit(invalid, in: &base), .invalid)
        XCTAssertEqual(base, invalidBefore)
    }

    func testMaterialReserveSalePersistsExactRepurchaseSourceAcrossRelaunch() throws {
        let sample = MaterialSample(kind: .plate, properties: .init(hardness: 63),
                                    grade: 67, source: "salt drake", qualifier: "glassy")
        var base = BaseState.newGame()
        base.materialReserve = MaterialReserve(units: [
            .init(id: MaterialReserveUnitID(rawValue: "plate-1"), sample: sample)
        ])
        let preview = try XCTUnwrap(TradingPostRules.previewMaterialSale(
            [try XCTUnwrap(base.materialReserve.selections().first)], in: base))
        XCTAssertEqual(TradingPostRules.commit(preview, in: &base), .committed)

        let restored = try SaveCodec.makeDecoder().decode(
            BaseState.self, from: SaveCodec.makeEncoder().encode(base))
        XCTAssertEqual(restored, base)
        guard case .material(let restoredSample) = restored.tradingPost.stock.last?.kind else {
            return XCTFail("Expected exact material repurchase row")
        }
        XCTAssertEqual(restoredSample.source, "salt drake")
        XCTAssertEqual(restoredSample.qualifier, "glassy")
        XCTAssertEqual(restoredSample.grade, 67)
    }

    func testMaterialSaleUIUsesGroupedExplicitStableSelectionsAndNoSlotInventory() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf: root.appending(path: "Sources/Screens/TradingPostView.swift"),
                                encoding: .utf8)
        XCTAssertTrue(source.contains("Text(\"Resources\")"))
        XCTAssertTrue(source.contains("DisclosureGroup"))
        XCTAssertTrue(source.contains("ForEach(group.selections, id: \\.unitID)"))
        XCTAssertTrue(source.contains("AnchoredItemDetailButton(item: listing"))
        XCTAssertTrue(source.contains("LabeledContent(\"Source\""))
        XCTAssertTrue(source.contains("LabeledContent(\"Qualifier\""))
        XCTAssertTrue(source.contains("LabeledContent(\"Grade\""))
        XCTAssertTrue(source.contains("TradingPostRules.materialSaleUnitPrice"))
        XCTAssertTrue(source.contains("TradingPostRules.commit(listing.preview"))
        XCTAssertTrue(source.contains("never use Storehouse slots"))
        XCTAssertFalse(source.contains("units(of: group.kind).max"))
    }
}
