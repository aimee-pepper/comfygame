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
    private func sample(_ grade: Double, source: String) -> MaterialSample {
        MaterialSample(kind: .hide, properties: MaterialProperties(flexibility: grade),
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
        base.materialReserve = MaterialReserve(units: [
            MaterialReserveUnit(id: .init(rawValue: "ordinary"), sample: ordinary),
            MaterialReserveUnit(id: .init(rawValue: "finest"), sample: finest)
        ])
        let byID = Dictionary(uniqueKeysWithValues:
            base.materialReserve.selections().map { ($0.unitID.rawValue, $0) })
        let chosen = [try XCTUnwrap(byID["finest"]), try XCTUnwrap(byID["ordinary"])]
        let preview = try XCTUnwrap(TradingPostRules.previewMaterialSale(chosen, in: base))

        XCTAssertEqual(preview.unitPrices, [5, 2])
        XCTAssertEqual(TradingPostRules.commit(preview, in: &base), .committed)
        XCTAssertTrue(base.materialReserve.isEmpty)
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
        base.materialReserve = MaterialReserve(units: [
            MaterialReserveUnit(id: .init(rawValue: "ordinary"), sample: ordinary),
            MaterialReserveUnit(id: .init(rawValue: "finest"), sample: finest)
        ])
        let selections = base.materialReserve.selections()
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
        changed.materialReserve = MaterialReserve(units: [
            MaterialReserveUnit(id: .init(rawValue: "ordinary"), sample: changedOrdinary),
            MaterialReserveUnit(id: .init(rawValue: "finest"), sample: finest)
        ])
        let changedBefore = try SaveCodec.makeEncoder().encode(changed)
        XCTAssertEqual(TradingPostRules.commit(preview, in: &changed), .invalid)
        XCTAssertEqual(try SaveCodec.makeEncoder().encode(changed), changedBefore)

        XCTAssertEqual(TradingPostRules.commit(preview, in: &base), .committed)
        XCTAssertEqual(base.materialReserve.selections().map(\.sample), [finest],
                       "an explicit ordinary selection must never auto-sell the finest sample")
    }

    func testTradingPostMaterialPurchaseEntersReserveWithoutUsingItemSlotsOrWaiting() throws {
        let sample = MaterialSample(kind: .hide,
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

        XCTAssertEqual(base.materialReserve.selections().map(\.sample), [sample])
        XCTAssertTrue(base.inventory.stacks.isEmpty)
        XCTAssertTrue(base.spillover.isEmpty)
        XCTAssertEqual(base.goldCoins, 0)
        XCTAssertEqual(base.tradingPost.stock[0].remainingQuantity, 0)
        XCTAssertTrue(base.tradingPost.stock[0].frozenUnits.isEmpty)
    }

    func testTradingPostMaterialIdentityCollisionRejectsAtomically() throws {
        let sample = MaterialSample(kind: .plate, properties: MaterialProperties(hardness: 35),
                                    grade: 30, source: "Vance's supplier")
        let frozen = ItemStack(id: InstanceID(rawValue: 909), catalogID: Items.material,
                               identified: true, materials: [sample])
        var base = BaseState.newGame()
        base.goldCoins = 3
        base.materialReserve.add(MaterialReserveUnit(
            id: MaterialReserveUnitID(rawValue: "trading-post-909"), sample: sample))
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
        XCTAssertTrue(source.contains("gear without recorded provenance stay protected"))
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

    private func sample(_ kind: MaterialKind = .hide, grade: Double,
                        source: String) -> MaterialSample {
        MaterialSample(kind: kind,
                       properties: MaterialProperties(hardness: grade / 2,
                                                      density: grade / 3,
                                                      insulation: grade,
                                                      flexibility: grade - 1,
                                                      lustre: 7, reactivity: 9),
                       grade: grade, source: source, qualifier: "kept")
    }

    private func gear(_ catalogID: ItemID = "blade_chipped", id: UInt64 = 700,
                      tier: Int = 1, receipt: [MaterialSample] = []) -> ItemStack {
        var result = ItemStack(id: InstanceID(rawValue: id), catalogID: catalogID)
        result.gearProfile?.constructionTier = tier
        result.gearProfile?.consumedSamples = receipt
        return result
    }

    private func base(containing stack: ItemStack, overflow: Bool = false) -> BaseState {
        var result = BaseState.newGame()
        result.inventory.stacks = []
        result.spillover = []
        if overflow { result.spillover = [stack] } else { result.inventory.stacks = [stack] }
        return result
    }

    func testOldBaseSaveAndPartialRecyclerStateDecodeTolerantly() throws {
        let old = try SaveCodec.makeDecoder().decode(BaseState.self,
                                                      from: Data("{\"essence\":37}".utf8))
        XCTAssertEqual(old.recycler, RecyclerState())

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

    func testReceiptDefaultSelectsHighestGradesStablyAndPreservesExactSamples() throws {
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
        XCTAssertEqual(preview.selectedReceiptIndices, [1, 2])
        XCTAssertEqual(preview.returnedSamples, [receipt[1], receipt[2]])
        XCTAssertTrue(preview.returnedResources.isEmpty)
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

    func testOrganicFoundSalvageProducesBoundedHonestReclaimedHide() throws {
        let stack = gear("guard_padded", tier: 4)
        let preview = try XCTUnwrap(RecyclerRules.preview(location: .stored, stackID: stack.id,
                                                          serviceTier: 1,
                                                          in: base(containing: stack)))
        let hide = try XCTUnwrap(preview.returnedSamples.first)
        XCTAssertEqual(hide.kind, .hide)
        XCTAssertEqual(hide.source, "Recycler reclamation")
        XCTAssertEqual(hide.qualifier, "reclaimed")
        XCTAssertEqual(hide.grade, 80)
        XCTAssertEqual(hide.rarity, .rare)
        XCTAssertEqual(preview.returnedResources["fiber"], 2)
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
        XCTAssertEqual(base.materialReserve.selections().map(\.sample), [receipt[1]])
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
        XCTAssertEqual(base.materialReserve.selections().map(\.sample), [receipt[1]])
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
        XCTAssertEqual(base.materialReserve.selections().map(\.sample),
                       Array(receipt.prefix(2)))
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
        base.materialReserve.add(MaterialReserveUnit(
            id: MaterialReserveUnitID(rawValue: "recycler-700-0"), sample: returned))
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
