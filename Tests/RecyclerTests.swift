import XCTest
@testable import Bookbinder

final class RecyclerPresentationTests: XCTestCase {
    func testRecyclerProprietorUsesExactNollIdentity() throws {
        XCTAssertEqual(RecyclerPresentation.proprietorID, TravellerID(rawValue: "noll"))
        let noll = try XCTUnwrap(ContentCatalog.shared.traveller(RecyclerPresentation.proprietorID))
        XCTAssertEqual(noll.name, "Noll")
    }

    func testRecoveredResourceNamesUseCatalogueAndHideUnknownIDs() throws {
        let clay = try XCTUnwrap(ContentCatalog.shared.resource("clay"))
        XCTAssertEqual(RecyclerPresentation.resourceName(clay.id), clay.name)

        let unknown: ResourceID = "internal_missing_resource_id"
        XCTAssertEqual(RecyclerPresentation.resourceName(unknown), "Unknown resource")
        XCTAssertFalse(RecyclerPresentation.resourceName(unknown).contains(unknown.rawValue))

        let summary = RecyclerPresentation.recoveredResourceSummary([
            (id: clay.id, amount: 2), (id: unknown, amount: 1)
        ])
        XCTAssertEqual(summary, "\(clay.name) ×2 · Unknown resource ×1")
        XCTAssertFalse(summary.contains(unknown.rawValue))
    }
}

final class TradingPostMaterialReserveRoutingTests: XCTestCase {
    private func sample(_ grade: Double, source: String) -> CraftMaterialUnitV1 {
        CraftMaterialUnitV1(kind: .hide, properties: MaterialProperties(flexibility: grade),
                       grade: grade, source: source)
    }

    func testMaterialSalePriceUsesBoundedRulesOwnedGradeBands() {
        XCTAssertEqual(TradingPostRules.materialSaleUnitPrice(for: sample(-10, source: "low")), 1)
        XCTAssertEqual(TradingPostRules.materialSaleUnitPrice(for: sample(0, source: "zero")), 1)
        XCTAssertEqual(TradingPostRules.materialSaleUnitPrice(for: sample(25, source: "supplier")), 2)
        XCTAssertEqual(TradingPostRules.materialSaleUnitPrice(for: sample(39, source: "supplier")), 2)
        XCTAssertEqual(TradingPostRules.materialSaleUnitPrice(for: sample(500, source: "high")), 6)
    }

    func testExactSelectedReserveSalePaysInOrderAndFreezesRepurchaseStock() throws {
        let ordinary = sample(25, source: "Vance's supplier")
        let finest = sample(90, source: "apex")
        var base = BaseState.newGame()
        base.worldMaterialReserve = WorldMaterialReserve(units: [
            CraftMaterialHoldingV1(id: .init(rawValue: "ordinary"), sample: ordinary),
            CraftMaterialHoldingV1(id: .init(rawValue: "finest"), sample: finest)
        ])
        let byID = Dictionary(uniqueKeysWithValues:
            base.worldMaterialReserve.selections().map { ($0.unitID.rawValue, $0) })
        let chosen = [try XCTUnwrap(byID["finest"]), try XCTUnwrap(byID["ordinary"])]
        let preview = try XCTUnwrap(TradingPostRules.previewMaterialSale(chosen, in: base))

        XCTAssertEqual(preview.unitPrices, [5, 2])
        XCTAssertEqual(TradingPostRules.commit(preview, in: &base), .committed)
        XCTAssertTrue(base.worldMaterialReserve.isEmpty)
        XCTAssertEqual(base.goldCoins, 7)
        XCTAssertTrue(base.inventory.stacks.isEmpty)
        XCTAssertTrue(base.spillover.isEmpty)
        XCTAssertEqual(base.tradingPost.stock.map(\.kind),
                       [.material(finest), .material(ordinary)])
        XCTAssertEqual(base.tradingPost.stock.map(\.unitPrice), [6, 3])
        XCTAssertEqual(base.tradingPost.stock.map { $0.frozenUnits.first?.materials },
                       [[finest], [ordinary]])
    }

    func testMaterialSaleRequiresExplicitExactSelectionAndRejectsStaleAtomically() throws {
        let ordinary = sample(30, source: "ordinary")
        let finest = sample(95, source: "finest")
        var base = BaseState.newGame()
        base.worldMaterialReserve = WorldMaterialReserve(units: [
            CraftMaterialHoldingV1(id: .init(rawValue: "ordinary"), sample: ordinary),
            CraftMaterialHoldingV1(id: .init(rawValue: "finest"), sample: finest)
        ])
        let selections = base.worldMaterialReserve.selections()
        let ordinarySelection = try XCTUnwrap(selections.first { $0.unitID.rawValue == "ordinary" })
        let preview = try XCTUnwrap(
            TradingPostRules.previewMaterialSale([ordinarySelection], in: base))
        XCTAssertNil(TradingPostRules.previewMaterialSale(
            [ordinarySelection, ordinarySelection], in: base))

        var stale = base
        stale.tradingPost.inventoryRevision &+= 1
        let staleBefore = try SaveCodec.makeEncoder().encode(stale)
        XCTAssertEqual(TradingPostRules.commit(preview, in: &stale), .stale)
        XCTAssertEqual(try SaveCodec.makeEncoder().encode(stale), staleBefore)

        var changed = base
        let changedOrdinary = sample(31, source: "changed")
        changed.worldMaterialReserve = WorldMaterialReserve(units: [
            CraftMaterialHoldingV1(id: .init(rawValue: "ordinary"), sample: changedOrdinary),
            CraftMaterialHoldingV1(id: .init(rawValue: "finest"), sample: finest)
        ])
        let changedBefore = try SaveCodec.makeEncoder().encode(changed)
        XCTAssertEqual(TradingPostRules.commit(preview, in: &changed), .invalid)
        XCTAssertEqual(try SaveCodec.makeEncoder().encode(changed), changedBefore)

        XCTAssertEqual(TradingPostRules.commit(preview, in: &base), .committed)
        XCTAssertEqual(base.worldMaterialReserve.selections().map(\.sample), [finest],
                       "an explicit ordinary selection must never auto-sell the finest sample")
    }

    func testTradingPostMaterialPurchaseEntersReserveWithoutUsingItemSlotsOrWaiting() throws {
        let sample = CraftMaterialUnitV1(kind: .hide,
                                    properties: MaterialProperties(flexibility: 34),
                                    grade: 31,
                                    source: "Vance's supplier")
        let frozen = ItemStack(id: InstanceID(rawValue: 808), catalogID: Items.material,
                               identified: true, materials: [sample])
        var base = BaseState.newGame()
        base.inventory = Inventory(slots: 0)
        base.goldCoins = 3
        base.tradingPost.stock = [
            TradingPostStockLine(id: 12, kind: .material(sample),
                                 remainingQuantity: 1, unitPrice: 3,
                                 frozenUnits: [frozen])
        ]

        let preview = try XCTUnwrap(
            TradingPostRules.previewPurchase(lineID: 12, quantity: 1, in: base))
        XCTAssertEqual(TradingPostRules.commit(preview, in: &base), .committed)

        XCTAssertEqual(base.worldMaterialReserve.selections().map(\.sample), [sample])
        XCTAssertTrue(base.inventory.stacks.isEmpty)
        XCTAssertTrue(base.spillover.isEmpty)
        XCTAssertEqual(base.goldCoins, 0)
        XCTAssertEqual(base.tradingPost.stock[0].remainingQuantity, 0)
        XCTAssertTrue(base.tradingPost.stock[0].frozenUnits.isEmpty)
    }

    func testTradingPostMaterialIdentityCollisionRejectsAtomically() throws {
        let sample = CraftMaterialUnitV1(kind: .plate, properties: MaterialProperties(hardness: 35),
                                    grade: 30, source: "Vance's supplier")
        let frozen = ItemStack(id: InstanceID(rawValue: 909), catalogID: Items.material,
                               identified: true, materials: [sample])
        var base = BaseState.newGame()
        base.goldCoins = 3
        base.worldMaterialReserve.add(CraftMaterialHoldingV1(
            id: CraftMaterialUnitID(rawValue: "trading-post-909"), sample: sample))
        base.tradingPost.stock = [
            TradingPostStockLine(id: 13, kind: .material(sample), remainingQuantity: 1,
                                 unitPrice: 3, frozenUnits: [frozen])
        ]
        let preview = try XCTUnwrap(
            TradingPostRules.previewPurchase(lineID: 13, quantity: 1, in: base))
        let before = base

        XCTAssertEqual(TradingPostRules.commit(preview, in: &base), .invalid)
        XCTAssertEqual(base, before)
    }
}

final class RecyclerTests: XCTestCase {
    func testRecyclerIneligibilityUsesCanonicalPlayerReasons() {
        XCTAssertEqual(RecyclerRules.Ineligibility.unique.explanation, "One-of-a-kind gear cannot be dismantled.")
        XCTAssertEqual(RecyclerRules.Ineligibility.apex.explanation, "Apex gear cannot be dismantled.")
        XCTAssertEqual(RecyclerRules.Ineligibility.narrative.explanation, "Story items remain intact.")
        XCTAssertEqual(RecyclerRules.Ineligibility.channelworks.explanation, "This belongs at Channelworks and cannot be dismantled here.")
        XCTAssertEqual(RecyclerRules.Ineligibility.legacyCredit.explanation,
                       "Gear with power carried forward from an older save stays protected until you rebuild it at the Armoury.")
        XCTAssertEqual(RecyclerRules.Ineligibility.noRecoveryProfile.explanation,
                       "This piece has no recorded construction stock or standard salvage.")
    }

    func testRecoveryPreviewKeepsDestructiveActionOutsideScrollableDetails() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(
            contentsOf: root.appending(path: "Sources/Screens/RecyclerView.swift"),
            encoding: .utf8
        )

        XCTAssertTrue(source.contains(".safeAreaInset(edge: .bottom, spacing: 0) { dismantleActionBar }"))
        XCTAssertTrue(source.contains("private var recyclerEmptyState: some View"))
        XCTAssertTrue(source.contains("No gear to dismantle"))
        XCTAssertTrue(source.contains("gear without recorded construction stock or standard salvage stay protected"))
        XCTAssertTrue(source.contains("ItemIconTile(icon: preview.snapshot.icon"))
        XCTAssertTrue(source.contains("NamedCharacterPixelIdentity("))
        XCTAssertTrue(source.contains("travellerID: person?.id"))
        XCTAssertTrue(source.contains("RecyclerPresentation.proprietorID"))
        XCTAssertTrue(source.contains("SixAcrossItemGrid(data: preview.returnedResources.nonZero"))
        XCTAssertTrue(source.contains("ResourceIconTile(resourceID: entry.id"))
        XCTAssertTrue(source.contains("Text(\"Dismantle this piece\").frame(maxWidth: .infinity)"))
        XCTAssertTrue(source.contains("message: failure.map(message(for:))"))
        XCTAssertTrue(source.contains("messageTint: failure == nil ? .secondary : .red"))
        XCTAssertTrue(source.contains("The selected piece is consumed only after recovery succeeds."))
        XCTAssertFalse(source.contains("successful atomic recovery"))
        XCTAssertTrue(source.contains(".disabled(failure != nil)"))
        XCTAssertTrue(source.contains(".presentationDetents([.medium, .large])"))
        XCTAssertTrue(source.contains(".presentationDragIndicator(.visible)"))
        XCTAssertFalse(source.contains("Section {\n                    Button(\"Dismantle this piece\""))
    }

    private func sample(_ kind: MaterialFamilyID = .hide, grade: Double,
                        source: String) -> CraftMaterialUnitV1 {
        CraftMaterialUnitV1(kind: kind,
                       properties: MaterialProperties(hardness: grade / 2,
                                                      density: grade / 3,
                                                      insulation: grade,
                                                      flexibility: grade - 1,
                                                      lustre: 7, reactivity: 9),
                       grade: grade, source: source, qualifier: "kept")
    }

    private func gear(_ catalogID: ItemID = "blade_chipped", id: UInt64 = 700,
                      tier: Int = 1, receipt: [CraftMaterialUnitV1] = []) -> ItemStack {
        var result = ItemStack(id: InstanceID(rawValue: id), catalogID: catalogID)
        result.gearProfile?.constructionTier = tier
        result.gearProfile?.consumedSamples = receipt
        if !receipt.isEmpty { result.gearProfile?.freezeGameplayFacts() }
        return result
    }

    private func state(containing stack: ItemStack, overflow: Bool = false,
                       recyclerTier: Int = 0) -> GameState {
        var state = GameState.newGame()
        state.base = base(containing: stack, overflow: overflow)
        state.base.stations[Stations.recycler] = .init(isUnlocked: true, tier: recyclerTier)
        return state
    }

    private func base(containing stack: ItemStack, overflow: Bool = false) -> BaseState {
        var result = BaseState.newGame()
        result.inventory.stacks = []
        result.spillover = []
        if overflow { result.spillover = [stack] } else { result.inventory.stacks = [stack] }
        return result
    }

    func testCurrentBaseRequiresTypedReservesWhilePartialRecyclerStateRemainsCompatible() throws {
        XCTAssertThrowsError(try SaveCodec.makeDecoder().decode(
            BaseState.self, from: Data("{\"essence\":37}".utf8)))
        let partial = try SaveCodec.makeDecoder().decode(
            RecyclerState.self, from: Data("{\"inventoryRevision\":8}".utf8))
        XCTAssertEqual(partial.schemaVersion, RecyclerState.schemaVersion)
        XCTAssertEqual(partial.inventoryRevision, 8)

        var base = BaseState.newGame()
        base.recycler.inventoryRevision = 19
        let restored = try SaveCodec.makeDecoder().decode(
            BaseState.self, from: SaveCodec.makeEncoder().encode(base))
        XCTAssertEqual(restored.recycler.inventoryRevision, 19)
    }

    func testEveryOrdinaryCatalogGearHasExplicitSalvageOrReceiptRoute() throws {
        XCTAssertEqual(RecyclerRules.unprofiledOrdinaryGearIDs(), [])
        XCTAssertEqual(RecyclerRules.invalidCatalogueItemIDs(), [])

        var object = try XCTUnwrap(JSONSerialization.jsonObject(
            with: JSONEncoder().encode(try XCTUnwrap(ContentCatalog.shared.item("blade_chipped"))))
            as? [String: Any])
        object.removeValue(forKey: "recyclerDisposition")
        XCTAssertThrowsError(try JSONDecoder().decode(
            ItemDef.self, from: JSONSerialization.data(withJSONObject: object)))

        var unknownProfile = try XCTUnwrap(ContentCatalog.shared.item("blade_chipped"))
        unknownProfile.salvageProfileID = "missing_profile"
        XCTAssertFalse(RecyclerRules.hasValidCatalogueDisposition(unknownProfile))
    }

    func testServiceTierEfficienciesAndCapacitiesAreExact() {
        XCTAssertEqual(RecyclerRules.efficiency(serviceTier: 1), 0.40)
        XCTAssertEqual(RecyclerRules.efficiency(serviceTier: 2), 0.55)
        XCTAssertEqual(RecyclerRules.efficiency(serviceTier: 3), 0.70)
        XCTAssertEqual(RecyclerRules.recoveryCapacity(receiptCount: 1, serviceTier: 3), 0)
        XCTAssertEqual(RecyclerRules.recoveryCapacity(receiptCount: 2, serviceTier: 1), 1)
        XCTAssertEqual(RecyclerRules.recoveryCapacity(receiptCount: 5, serviceTier: 1), 2)
        XCTAssertEqual(RecyclerRules.recoveryCapacity(receiptCount: 5, serviceTier: 2), 2)
        XCTAssertEqual(RecyclerRules.recoveryCapacity(receiptCount: 5, serviceTier: 3), 3)
    }

    func testReceiptDefaultUsesFrozenConstructionOrderAndPreservesExactUnits() throws {
        let receipt = [sample(.hide, grade: 50, source: "first"),
                       sample(.plate, grade: 80, source: "best-first"),
                       sample(.plate, grade: 80, source: "best-second"),
                       sample(.ichor, grade: 20, source: "last")]
        let stack = gear(receipt: receipt)
        let preview = try XCTUnwrap(RecyclerRules.preview(location: .stored, stackID: stack.id,
                                                          serviceTier: 2,
                                                          in: base(containing: stack)))
        XCTAssertEqual(preview.route, .constructionReceipt)
        XCTAssertEqual(preview.recoveryCapacity, 2)
        XCTAssertEqual(preview.selectedReceiptIndices, [0, 1])
        XCTAssertEqual(preview.returnedSamples, [receipt[0], receipt[1]])
        XCTAssertTrue(preview.returnedResources.isEmpty)

        var committedBase = base(containing: stack)
        XCTAssertEqual(RecyclerRules.commit(preview, in: &committedBase), .committed)
        XCTAssertEqual(committedBase.creatureMaterialReserve.units.map(\.unit),
                       [receipt[0], receipt[1]])
        XCTAssertEqual(committedBase.creatureMaterialReserve.units.map(\.id),
                       [receipt[0].stableUnitID, receipt[1].stableUnitID])
        XCTAssertFalse(committedBase.creatureMaterialReserve.units.contains {
            $0.id.rawValue.hasPrefix("recycler-")
        })
    }

    func testLivePhysicalReceiptRouteRequiresHomeStationAndBindsBothRevisions() throws {
        let receipt = [sample(.plate, grade: 50, source: "creature plate"),
                       sample(.fibre, grade: 60, source: "world binding")]
        let stack = gear(receipt: receipt)
        var state = state(containing: stack)
        let quote = try XCTUnwrap(RecyclerRules.previewPhysicalReceipt(
            location: .stored, stackID: stack.id, in: state))
        XCTAssertEqual(quote.revision, state.base.recycler.inventoryRevision)
        XCTAssertEqual(quote.ownershipRevision, state.base.physicalGearOwnershipRevision)
        XCTAssertEqual(quote.returnedSamples, [receipt[0]])
        XCTAssertTrue(quote.returnedResources.isEmpty)

        var stale = state
        stale.base.physicalGearOwnershipRevision += 1
        let staleBytes = try SaveCodec.encode(stale)
        XCTAssertEqual(RecyclerRules.commitPhysicalReceipt(quote, in: &stale), .stale)
        XCTAssertEqual(try SaveCodec.encode(stale), staleBytes)

        var away = state
        let point = GridPoint(x: 0, y: 0)
        away.worlds.activeRun = WorldRun(
            runIndex: 1, book: .init(written: [], essencePaid: 0), mapSeed: 77,
            rng: .init(seed: 78),
            map: .init(width: 1, height: 1, tiles: [.init(isRevealed: true)], entry: point),
            playerPosition: point, sourceDangerReceipt: .init(sourceBand: 1))
        XCTAssertNil(RecyclerRules.previewPhysicalReceipt(
            location: .stored, stackID: stack.id, in: away))
        away.worlds.activeRun = nil
        away.base.stations[Stations.recycler] = .init(isUnlocked: false, tier: 0)
        XCTAssertNil(RecyclerRules.previewPhysicalReceipt(
            location: .stored, stackID: stack.id, in: away))

        XCTAssertEqual(RecyclerRules.commitPhysicalReceipt(quote, in: &state), .committed)
        XCTAssertFalse(state.base.inventory.stacks.contains { $0.id == stack.id })
        XCTAssertEqual(state.base.creatureMaterialReserve.units.map(\.unit), [receipt[0]])
        XCTAssertEqual(state.base.creatureMaterialReserve.units.map(\.id),
                       [receipt[0].stableUnitID])
        XCTAssertGreaterThan(state.base.nextPhysicalGearInstanceID, stack.id.rawValue)
        let committedBytes = try SaveCodec.encode(state)
        XCTAssertEqual(RecyclerRules.commitPhysicalReceipt(quote, in: &state), .stale)
        XCTAssertEqual(try SaveCodec.encode(state), committedBytes)
    }

    func testPhysicalReceiptSelectionPreservesRevisionOrderDomainsAndDestroysInscription() throws {
        let receipt = [sample(.plate, grade: 20, source: "revision zero creature"),
                       sample(.fibre, grade: 30, source: "revision zero world"),
                       sample(.hide, grade: 40, source: "revision one creature"),
                       sample(.timber, grade: 50, source: "revision one world")]
        var stack = gear(id: 701, receipt: Array(receipt.prefix(2)))
        var profile = try XCTUnwrap(stack.gearProfile)
        let prior = try XCTUnwrap(profile.physicalReceipt?.revisions.first)
        profile.physicalReceipt?.revisions.append(.init(
            ordinal: 1,
            authority: .rebuild(stationID: Stations.armoury,
                                profileID: "armoury_rigid_shell", rulesVersion: 1),
            components: Array(receipt.suffix(2)).enumerated().map {
                .init(ordinal: $0.offset, role: .authoredSocket("rebuild-\($0.offset)"),
                      unit: $0.element)
            }, resultingQualityBand: profile.qualityBand,
            resultingConstructionTier: profile.constructionTier))
        profile.freezeGameplayFacts()
        XCTAssertEqual(profile.physicalReceipt?.revisions.first, prior)
        profile.inscription = .init(version: 1, definitionID: "future-inert", sourceItemID: "future-source",
                                    rulesVersion: 1, inkRecipe: nil)
        stack.gearProfile = profile
        var state = state(containing: stack, overflow: true, recyclerTier: 2)
        let quote = try XCTUnwrap(RecyclerRules.previewPhysicalReceipt(
            location: .overflow, stackID: stack.id, selectedReceiptIndices: [3, 1], in: state))
        XCTAssertEqual(quote.selectedReceiptIndices, [1, 3])
        XCTAssertEqual(quote.returnedSamples, [receipt[1], receipt[3]])
        XCTAssertEqual(RecyclerRules.commitPhysicalReceipt(quote, in: &state), .committed)
        XCTAssertEqual(state.base.worldMaterialReserve.units.map(\.unit), [receipt[1], receipt[3]])
        XCTAssertTrue(state.base.creatureMaterialReserve.isEmpty)
        XCTAssertTrue(state.base.spillover.isEmpty)
    }

    func testPhysicalReceiptGraphCollisionRefusesBeforeQuote() throws {
        let receipt = [sample(.plate, grade: 30, source: "one"),
                       sample(.fibre, grade: 60, source: "two")]
        let stack = gear(receipt: receipt)
        var state = state(containing: stack)
        state.base.creatureMaterialReserve.add(.init(unit: receipt[0], protectedReturn: false))
        let bytes = try SaveCodec.makeEncoder().encode(state.base)
        XCTAssertNil(RecyclerRules.previewPhysicalReceipt(
            location: .stored, stackID: stack.id, in: state))
        XCTAssertEqual(try SaveCodec.makeEncoder().encode(state.base), bytes)
    }

    func testReceiptSelectionRejectsDuplicatesOutOfRangeAndOverCapacity() {
        let receipt = (0..<5).map { sample(grade: Double($0 * 10), source: "s\($0)") }
        let stack = gear(receipt: receipt)
        let base = base(containing: stack)
        XCTAssertNil(RecyclerRules.preview(location: .stored, stackID: stack.id, serviceTier: 1,
                                            selectedReceiptIndices: [0, 0], in: base))
        XCTAssertNil(RecyclerRules.preview(location: .stored, stackID: stack.id, serviceTier: 1,
                                            selectedReceiptIndices: [99], in: base))
        XCTAssertNil(RecyclerRules.preview(location: .stored, stackID: stack.id, serviceTier: 1,
                                            selectedReceiptIndices: [0, 1, 2], in: base))
    }

    func testConstructionReceiptWinsOverAuthoredFoundSalvageAndIgnoresReforgeRank() throws {
        let receipt = [sample(.plate, grade: 61, source: "ore-a"),
                       sample(.fibre, grade: 62, source: "fibre-b")]
        var stack = gear("blade_chipped", receipt: receipt)
        stack.gearProfile?.reforgeRank = 3
        let preview = try XCTUnwrap(RecyclerRules.preview(location: .stored, stackID: stack.id,
                                                          serviceTier: 1,
                                                          in: base(containing: stack)))
        XCTAssertEqual(preview.route, .constructionReceipt)
        XCTAssertEqual(preview.returnedSamples.count, 1)
        XCTAssertTrue(preview.returnedResources.isEmpty)
    }

    func testAllTwelveFoundReceiptsDeferStoredAndOverflowRecoveryWithoutMutation() throws {
        let ids = ContentCatalog.shared.items.compactMap { item in
            item.gearCatalogueDisposition?.foundReceipt == nil ? nil : item.id
        }.sorted { $0.rawValue < $1.rawValue }
        XCTAssertEqual(ids.count, 12)
        XCTAssertTrue(ids.contains("copper_buckler"))
        XCTAssertTrue(ids.contains("timber_longbow"))
        XCTAssertTrue(ids.contains("rubble_sling"))
        XCTAssertTrue(ids.contains("ironwork_blade"))
        XCTAssertTrue(ids.contains("resinbound_boots"))
        XCTAssertTrue(ids.contains("golden_keepsake"))
        XCTAssertTrue(ids.contains("riftglass_rapier"))

        for (ordinal, id) in ids.enumerated() {
            for location in [TradingPostItemLocation.stored, .overflow] {
                let stack = gear(id, id: UInt64(80_000 + ordinal))
                var state = base(containing: stack, overflow: location == .overflow)
                let before = try SaveCodec.makeEncoder().encode(state)
                let revision = state.recycler.inventoryRevision
                XCTAssertEqual(RecyclerRules.ineligibility(of: stack),
                               .foundReceiptRecoveryUndefined, id.rawValue)
                XCTAssertNil(RecyclerRules.preview(location: location, stackID: stack.id,
                                                    serviceTier: 3, in: state), id.rawValue)

                var forged = RecyclerPreview(
                    revision: revision, location: location, stackID: stack.id, snapshot: stack,
                    serviceTier: 3, route: .constructionReceipt,
                    selectedReceiptIndices: [], recoveryCapacity: 0,
                    returnedSamples: [], returnedResources: ResourcePool())
                XCTAssertEqual(RecyclerRules.commit(forged, in: &state), .invalid)
                XCTAssertEqual(try SaveCodec.makeEncoder().encode(state), before, id.rawValue)
                forged.revision &+= 1
                XCTAssertEqual(RecyclerRules.commit(forged, in: &state), .stale)
                XCTAssertEqual(try SaveCodec.makeEncoder().encode(state), before, id.rawValue)
            }
        }
    }

    func testFoundSalvageUsesAuthoredTierSequenceWithoutInventingReceipt() throws {
        for (tier, expectedOre, expectedTimber) in [(1, 1, 0), (3, 1, 1), (4, 2, 1)] {
            let stack = gear("blade_chipped", id: UInt64(700 + tier), tier: tier)
            let preview = try XCTUnwrap(RecyclerRules.preview(location: .stored, stackID: stack.id,
                                                              serviceTier: 1,
                                                              in: base(containing: stack)))
            XCTAssertEqual(preview.route, .authoredSalvage(profileID: "forged_edge_v1"))
            XCTAssertEqual(preview.returnedResources["ore"], expectedOre)
            XCTAssertEqual(preview.returnedResources["timber"], expectedTimber)
            XCTAssertEqual(preview.returnedSamples, [])
        }
    }

    func testOrganicFoundSalvageUsesBulkFibreWithoutInventedCreatureProvenance() throws {
        let stack = gear("guard_padded", tier: 4)
        let preview = try XCTUnwrap(RecyclerRules.preview(location: .stored, stackID: stack.id,
                                                          serviceTier: 1,
                                                          in: base(containing: stack)))
        XCTAssertTrue(preview.returnedSamples.isEmpty)
        XCTAssertEqual(preview.returnedResources["fiber"], 3)
    }

    func testProtectedUnknownUniqueLegacyAndUnprofiledGearAreRejected() {
        var favorite = gear(); favorite.isFavorite = true
        var locked = gear(); locked.isLocked = true
        var unknown = gear(); unknown.identified = false
        var legacy = gear(); legacy.gearProfile?.legacyPowerCredit = 1
        for stack in [favorite, locked, unknown, legacy] {
            XCTAssertNil(RecyclerRules.preview(location: .stored, stackID: stack.id,
                                                serviceTier: 1, in: base(containing: stack)))
        }
        let apex = gear("two_natured_blade")
        XCTAssertNil(RecyclerRules.preview(location: .stored, stackID: apex.id,
                                            serviceTier: 1, in: base(containing: apex)))
        XCTAssertEqual(RecyclerRules.ineligibility(of: favorite), .favorite)
        XCTAssertEqual(RecyclerRules.ineligibility(of: locked), .locked)
        XCTAssertEqual(RecyclerRules.ineligibility(of: unknown), .unidentified)
        XCTAssertEqual(RecyclerRules.ineligibility(of: legacy), .legacyCredit)
        XCTAssertEqual(RecyclerRules.ineligibility(of: apex), .apex)
        XCTAssertEqual(RecyclerRules.ineligibility(ofEquipped: EquippedPiece(apex)), .equipped)
        XCTAssertTrue(RecyclerRules.Ineligibility.allCases.allSatisfy { !$0.explanation.isEmpty })
    }

    func testUniqueNarrativeChannelworksAndMissingReceiptExplainTheirRejection() {
        var unique = gear(); unique.gearProfile?.authoredUniqueRuleID = "singular_work"
        var narrative = gear(); narrative.gearProfile?.authoredUniqueRuleID = "narrative_key"
        let conduit = ItemStack(id: InstanceID(rawValue: 99), catalogID: Items.conduitFixture)
        var unprofiled = gear("blade_chipped")
        unprofiled.catalogID = "unmapped_test_gear"

        XCTAssertEqual(RecyclerRules.ineligibility(of: unique), .unique)
        XCTAssertEqual(RecyclerRules.ineligibility(of: narrative), .narrative)
        XCTAssertEqual(RecyclerRules.ineligibility(of: conduit), .channelworks)
        XCTAssertEqual(RecyclerRules.ineligibility(of: unprofiled), .notGear)
    }

    func testStoredReceiptCommitRemovesExactGearReturnsSampleAndNeverPaysCurrency() throws {
        let receipt = [sample(.plate, grade: 41, source: "one"),
                       sample(.fibre, grade: 71, source: "two")]
        let stack = gear(receipt: receipt)
        var base = base(containing: stack)
        base.goldCoins = 9
        base.essence = 17
        let preview = try XCTUnwrap(RecyclerRules.preview(location: .stored, stackID: stack.id,
                                                          serviceTier: 1, in: base))
        XCTAssertEqual(RecyclerRules.commit(preview, in: &base), .committed)
        XCTAssertFalse(base.inventory.stacks.contains { $0.id == stack.id })
        XCTAssertEqual(base.creatureMaterialReserve.selections().map(\.sample.familyID), [.plate])
        XCTAssertTrue(base.inventory.stacks.flatMap(\.materials).isEmpty)
        XCTAssertTrue(base.spillover.flatMap(\.materials).isEmpty)
        XCTAssertEqual(base.goldCoins, 9)
        XCTAssertEqual(base.essence, 17)
        XCTAssertEqual(base.recycler.inventoryRevision, 1)
    }

    func testOverflowCommitUsesExactIdentityAndFullStorehouseSpillsRecoveredMaterialSafely() throws {
        let receipt = [sample(.plate, grade: 30, source: "one"),
                       sample(.fibre, grade: 60, source: "two")]
        let stack = gear(id: 901, receipt: receipt)
        var base = base(containing: stack, overflow: true)
        base.inventory = Inventory(slots: 1, stacks: [ItemStack(id: InstanceID(rawValue: 12),
                                                               catalogID: "salve_lesser")])
        let preview = try XCTUnwrap(RecyclerRules.preview(location: .overflow, stackID: stack.id,
                                                          serviceTier: 1, in: base))
        XCTAssertEqual(RecyclerRules.commit(preview, in: &base), .committed)
        XCTAssertFalse(base.spillover.contains { $0.id == stack.id })
        XCTAssertEqual(base.spillover.count, 0)
        XCTAssertEqual(base.creatureMaterialReserve.selections().map(\.sample.familyID), [.plate])
    }

    func testMixedKindReceiptReturnsThroughExactNonSlotReserveUnits() throws {
        let receipt = [sample(.plate, grade: 90, source: "plate"),
                       sample(.fibre, grade: 80, source: "fibre"),
                       sample(.hide, grade: 30, source: "hide"),
                       sample(.ichor, grade: 20, source: "ichor")]
        let stack = gear(receipt: receipt)
        var base = base(containing: stack)
        let preview = try XCTUnwrap(RecyclerRules.preview(location: .stored, stackID: stack.id,
                                                          serviceTier: 2, in: base))
        XCTAssertEqual(RecyclerRules.commit(preview, in: &base), .committed)
        XCTAssertEqual(base.creatureMaterialReserve.selections().map(\.sample.familyID), [.plate])
        XCTAssertEqual(base.worldMaterialReserve.selections().map(\.sample.familyID), [.fibre])
        XCTAssertTrue(base.inventory.stacks.flatMap(\.materials).isEmpty)
        XCTAssertTrue(base.spillover.flatMap(\.materials).isEmpty)
    }

    func testStaleRevisionAndChangedSnapshotAreAtomicNoOps() throws {
        let stack = gear(tier: 4)
        var staleBase = base(containing: stack)
        let stalePreview = try XCTUnwrap(RecyclerRules.preview(location: .stored, stackID: stack.id,
                                                               serviceTier: 1, in: staleBase))
        staleBase.recycler.inventoryRevision = 1
        let staleBefore = staleBase
        XCTAssertEqual(RecyclerRules.commit(stalePreview, in: &staleBase), .stale)
        XCTAssertEqual(staleBase, staleBefore)

        var changedBase = base(containing: stack)
        let changedPreview = try XCTUnwrap(RecyclerRules.preview(location: .stored, stackID: stack.id,
                                                                 serviceTier: 1, in: changedBase))
        changedBase.inventory.stacks[0].isLocked = true
        let changedBefore = changedBase
        XCTAssertEqual(RecyclerRules.commit(changedPreview, in: &changedBase), .invalid)
        XCTAssertEqual(changedBase, changedBefore)
    }

    func testReserveIdentityCollisionRejectsRecyclerCommitBeforeRemovingGear() throws {
        let receipt = [sample(.plate, grade: 30, source: "one"),
                       sample(.fibre, grade: 60, source: "two")]
        let stack = gear(receipt: receipt)
        var base = base(containing: stack)
        let preview = try XCTUnwrap(RecyclerRules.preview(
            location: .stored, stackID: stack.id, serviceTier: 1, in: base))
        let returned = try XCTUnwrap(preview.returnedSamples.first)
        base.creatureMaterialReserve.add(CraftMaterialHoldingV1(
            id: CraftMaterialUnitID(rawValue: "recycler-700-0"), sample: returned))
        let before = base

        XCTAssertEqual(RecyclerRules.commit(preview, in: &base), .invalid)
        XCTAssertEqual(base, before)
        XCTAssertNotNil(base.inventory.stacks.first { $0.id == stack.id })
    }

    func testExceptionalOneSampleReceiptReturnsNothingWithoutFabricatingSalvage() throws {
        let stack = gear(receipt: [sample(.plate, grade: 91, source: "only")])
        let preview = try XCTUnwrap(RecyclerRules.preview(location: .stored, stackID: stack.id,
                                                          serviceTier: 3,
                                                          in: base(containing: stack)))
        XCTAssertEqual(preview.route, .constructionReceipt)
        XCTAssertEqual(preview.recoveryCapacity, 0)
        XCTAssertEqual(preview.returnedSamples, [])
        XCTAssertTrue(preview.returnedResources.isEmpty)
    }
}
