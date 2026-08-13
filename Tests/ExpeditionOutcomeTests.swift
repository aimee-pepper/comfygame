import XCTest
@testable import Bookbinder

@MainActor
final class ExpeditionOutcomeTests: XCTestCase {
    private func fundedStore(_ name: String = #function) -> GameStore {
        let store = GameStore(io: .temporary(name: "outcome-\(name)-\(UUID().uuidString)"))
        store.mutate("fixture: fund") { $0.base.essence = 5_000 }
        return store
    }

    func testResolvedExpeditionsMintOneSharedMonotonicReceipt() throws {
        let store = fundedStore()

        XCTAssertTrue(store.bindAndDepart())
        store.portalHome()
        XCTAssertEqual(store.state.worlds.outcomeSequence, 1)
        XCTAssertEqual(store.state.worlds.lastExit?.outcomeID, 1)
        XCTAssertEqual(store.state.worlds.lastSpringOutcomeID, 1)
        XCTAssertEqual(store.state.base.tradingPost.expeditionOutcomeID, 1)

        store.dismissRunExitSummary()
        XCTAssertEqual(store.state.worlds.outcomeSequence, 1,
                       "acknowledging a recap is not another expedition outcome")

        XCTAssertTrue(store.bindAndDepart())
        store.endRunWithPartialHaul(reason: "fixture collapse", kind: .collapse)
        XCTAssertEqual(store.state.worlds.outcomeSequence, 2)
        XCTAssertEqual(store.state.worlds.lastExit?.outcomeID, 2)
        XCTAssertEqual(store.state.worlds.lastSpringOutcomeID, 2)
        XCTAssertEqual(store.state.base.tradingPost.expeditionOutcomeID, 2)
    }

    func testRepeatedVisitsToSameRunIndexReceiveDistinctOutcomeIDs() throws {
        let store = fundedStore()
        XCTAssertTrue(store.bindAndDepart())
        let original = try XCTUnwrap(store.state.worlds.activeRun)

        store.portalHome()
        let firstRunIndex = try XCTUnwrap(store.state.worlds.lastExit).runIndex
        XCTAssertEqual(firstRunIndex, original.runIndex)
        XCTAssertEqual(store.state.worlds.lastExit?.outcomeID, 1)

        store.dismissRunExitSummary()
        store.mutate("fixture: revisit same saved world") { state in
            var revisit = original
            revisit.turnsTaken = 3
            state.worlds.activeRun = revisit
        }
        store.endRunWithPartialHaul(reason: "fixture revisit", kind: .defeat)

        XCTAssertEqual(store.state.worlds.lastExit?.runIndex, firstRunIndex)
        XCTAssertEqual(store.state.worlds.lastExit?.outcomeID, 2)
        XCTAssertEqual(store.state.worlds.outcomeSequence, 2)
    }

    func testOutcomeReceiptsSurviveSaveRoundTrip() throws {
        let store = fundedStore()
        XCTAssertTrue(store.bindAndDepart())
        store.endRunWithPartialHaul(reason: "fixture defeat", kind: .defeat)

        let data = try SaveCodec.makeEncoder().encode(store.state)
        let restored = try SaveCodec.makeDecoder().decode(GameState.self, from: data)

        XCTAssertEqual(restored.worlds.outcomeSequence, 1)
        XCTAssertEqual(restored.worlds.lastExit?.outcomeID, 1)
        XCTAssertEqual(restored.worlds.lastSpringOutcomeID, 1)
        XCTAssertEqual(restored.base.tradingPost.expeditionOutcomeID, 1)
    }

    func testOldWorldsStateDefaultsReceiptFieldsWithoutFabricatingHistory() throws {
        var seeds = SeedSequence.newGame()
        let legacy = WorldsState.newGame(seeds: &seeds)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(
            with: SaveCodec.makeEncoder().encode(legacy)) as? [String: Any])
        object.removeValue(forKey: "outcomeSequence")
        object.removeValue(forKey: "pendingAnchorSettlementOutcomeID")
        object.removeValue(forKey: "lastSpringOutcomeID")

        let decoded = try SaveCodec.makeDecoder().decode(
            WorldsState.self, from: JSONSerialization.data(withJSONObject: object))
        XCTAssertEqual(decoded.outcomeSequence, 0)
        XCTAssertNil(decoded.pendingAnchorSettlementOutcomeID)
        XCTAssertNil(decoded.lastSpringOutcomeID)
    }

    func testLegacyExitRowsDecodeAsVisibleFallbackWithoutGuessingTypedIdentity() throws {
        let legacy = RunExitSummary(
            runIndex: 4, kind: .collapse, reason: "legacy", turnsTaken: 7,
            haulKeptFraction: 0.5,
            resources: [.init(name: "Ore", icon: "cube", count: 2)],
            items: [.init(name: "Unknown blade", icon: "shippingbox", count: 1)])
        var object = try XCTUnwrap(JSONSerialization.jsonObject(
            with: SaveCodec.makeEncoder().encode(legacy)) as? [String: Any])
        object.removeValue(forKey: "recoveredLines")
        object.removeValue(forKey: "lostLines")

        let decoded = try SaveCodec.makeDecoder().decode(
            RunExitSummary.self, from: JSONSerialization.data(withJSONObject: object))

        XCTAssertEqual(decoded.recoveredLines.count, 2)
        guard case .legacy(let resource) = decoded.recoveredLines[0],
              case .legacy(let item) = decoded.recoveredLines[1] else {
            return XCTFail("old rows must remain visibly legacy rather than acquiring guessed IDs")
        }
        XCTAssertEqual(resource.fallbackName, "Ore")
        XCTAssertEqual(item.fallbackName, "Unknown blade")
        XCTAssertNotEqual(decoded.recoveredLines[0].id, decoded.recoveredLines[1].id)

        let secondDecode = try SaveCodec.makeDecoder().decode(
            RunExitSummary.self, from: SaveCodec.makeEncoder().encode(decoded))
        XCTAssertEqual(secondDecode.resources, decoded.resources)
        XCTAssertEqual(secondDecode.items, decoded.items,
                       "legacy compatibility rows must survive canonical re-encoding")
    }

    func testFullReturnFreezesDistinctGearIdentityAndProfileInTypedReceipt() throws {
        let store = fundedStore()
        XCTAssertTrue(store.bindAndDepart())
        var first = ItemStack(id: InstanceID(rawValue: 71), catalogID: "blade_keen")
        first.upgradeLevel = 2
        first.isFavorite = true
        var second = ItemStack(id: InstanceID(rawValue: 72), catalogID: "blade_keen")
        second.upgradeLevel = 1
        store.mutate("fixture: exact returned gear") { state in
            state.worlds.activeRun?.satchelItems.stacks = [first, second]
        }

        let runBeforeReturn = try XCTUnwrap(store.state.worlds.activeRun)
        var lossPreviewState = store.state
        var lossRNG = runBeforeReturn.rng
        let allLost = GameStore.bankHaul(of: runBeforeReturn, outcomeID: 99,
                                         into: &lossPreviewState,
                                         fraction: 0, rng: &lossRNG)
        let lostIDs = allLost.lostLines.compactMap { line -> InstanceID? in
            guard case .uniqueItem(let item) = line else { return nil }
            return item.instanceID
        }
        XCTAssertEqual(Set(lostIDs), [first.id, second.id],
                       "loss must not aggregate property-bearing items by catalogue ID")

        store.portalHome()
        let summary = try XCTUnwrap(store.state.worlds.lastExit)
        let gear = summary.recoveredLines.compactMap { line -> RunExitSummary.ReceiptLine.Item? in
            guard case .uniqueItem(let item) = line else { return nil }
            return item
        }

        XCTAssertEqual(Set(gear.map(\.instanceID)), [first.id, second.id])
        XCTAssertEqual(gear.first(where: { $0.instanceID == first.id })?.snapshot.upgradeLevel, 2)
        XCTAssertEqual(gear.first(where: { $0.instanceID == first.id })?.snapshot.isFavorite, true)
        XCTAssertEqual(gear.first(where: { $0.instanceID == first.id })?.snapshot.gearProfile,
                       first.gearProfile)
        XCTAssertEqual(summary.items.filter { $0.name.contains("Keen") }.count, 2,
                       "the compatibility projection must include protected/guaranteed returns too")

        let restored = try SaveCodec.makeDecoder().decode(
            GameState.self, from: SaveCodec.makeEncoder().encode(store.state))
        XCTAssertEqual(restored.worlds.lastExit?.recoveredLines, summary.recoveredLines)
    }

    func testOneReturnConstructorKeepsNonLossFieldsIdenticalAcrossExitKinds() throws {
        let store = fundedStore()
        XCTAssertTrue(store.bindAndDepart())
        let run = try XCTUnwrap(store.state.worlds.activeRun)
        let typed: [RunExitSummary.ReceiptLine] = [
            .resource(.init(lineID: "40-recovered-ore", id: Resources.ore, quantity: 3,
                            fallbackName: "Ore", fallbackIcon: "cube"))
        ]
        let banked = GameStore.BankedHaul(
            resources: [.init(name: "Ore", icon: "cube", count: 3)], items: [],
            lostResources: [], lostItems: [], recoveredLines: typed, lostLines: [],
            unidentifiedItemIDs: [], returnedRawEssence: false)

        let full = GameStore.makeReturnReceipt(
            run: run, outcomeID: 40, kind: .portal, reason: "full", fraction: 1,
            banked: banked, autoRefinedRaw: 0, autoRefinedEssence: 0,
            springYield: 2, state: store.state)
        let partial = GameStore.makeReturnReceipt(
            run: run, outcomeID: 41, kind: .defeat, reason: "partial", fraction: 0.5,
            banked: banked, autoRefinedRaw: 0, autoRefinedEssence: 0,
            springYield: 2, state: store.state)

        XCTAssertEqual(full.resources, partial.resources)
        XCTAssertEqual(full.recoveredLines, partial.recoveredLines)
        XCTAssertEqual(full.progress, partial.progress)
        XCTAssertEqual(full.pages, partial.pages)
        XCTAssertEqual(full.writings, partial.writings)
        XCTAssertEqual(full.recruitedTravellers, partial.recruitedTravellers)
        XCTAssertEqual(full.experienceBreakdown, partial.experienceBreakdown)
        XCTAssertEqual(full.essenceEconomy, partial.essenceEconomy)
    }

    func testTypedLinesAreTheOnlyAuthorityForCompatibilityRows() throws {
        let typed: [RunExitSummary.ReceiptLine] = [
            .resource(.init(lineID: "1-recovered-ore", id: Resources.ore, quantity: 3,
                            fallbackName: "Frozen ore", fallbackIcon: "cube"))
        ]
        let summary = RunExitSummary(
            runIndex: 1, kind: .portal, reason: "fixture", turnsTaken: 1,
            haulKeptFraction: 1,
            resources: [.init(name: "Contradictory row", icon: "xmark", count: 99)],
            recoveredLines: typed)

        XCTAssertEqual(summary.resources, [RunExitGain(name: "Frozen ore", icon: "cube", count: 3)])
        XCTAssertTrue(summary.items.isEmpty)

        var object = try XCTUnwrap(JSONSerialization.jsonObject(
            with: SaveCodec.makeEncoder().encode(summary)) as? [String: Any])
        object["resources"] = [["name": "Tampered", "icon": "xmark", "count": 500]]
        let restored = try SaveCodec.makeDecoder().decode(
            RunExitSummary.self, from: JSONSerialization.data(withJSONObject: object))
        XCTAssertEqual(restored.resources, summary.resources,
                       "typed frozen lines must override stale or tampered compatibility rows")
    }

    func testMaterialReceiptFreezesEverySampleAsItsOwnStableLine() throws {
        let store = fundedStore()
        XCTAssertTrue(store.bindAndDepart())
        let pale = MaterialSample(kind: .hide, properties: .init(insulation: 31),
                                  grade: 42, source: "pale browser", qualifier: "pale")
        let shaggy = MaterialSample(kind: .hide, properties: .init(insulation: 67),
                                    grade: 81, source: "shaggy groper", qualifier: "shaggy")
        let bin = ItemStack(id: InstanceID(rawValue: 902), catalogID: Items.material,
                            materials: [pale, shaggy])
        store.mutate("fixture: exact material samples") {
            $0.worlds.activeRun?.satchelItems.stacks = [bin]
        }

        store.portalHome()
        let lines = try XCTUnwrap(store.state.worlds.lastExit).recoveredLines.compactMap {
            line -> RunExitSummary.ReceiptLine.Material? in
            guard case .materialSample(let material) = line else { return nil }
            return material
        }

        XCTAssertEqual(lines.count, 2)
        XCTAssertEqual(Set(lines.map(\.lineID)), ["1-recovered-902-0", "1-recovered-902-1"])
        XCTAssertTrue(lines.map(\.sample).contains(pale))
        XCTAssertTrue(lines.map(\.sample).contains(shaggy))
        XCTAssertEqual(Set(lines.map(\.sourceStackID)), [bin.id])
    }

    func testSplitMaterialReceiptIDsCannotCollideAcrossRecoveredAndLostSides() throws {
        let store = fundedStore()
        XCTAssertTrue(store.bindAndDepart())
        let first = MaterialSample(kind: .hide, properties: .init(insulation: 31),
                                   grade: 42, source: "first")
        let second = MaterialSample(kind: .hide, properties: .init(insulation: 67),
                                    grade: 81, source: "second")
        store.mutate("fixture: split material samples") {
            $0.worlds.activeRun?.satchelItems.stacks = [
                ItemStack(id: InstanceID(rawValue: 903), catalogID: Items.material,
                          materials: [first, second])
            ]
        }
        let run = try XCTUnwrap(store.state.worlds.activeRun)
        var state = store.state
        var rng = run.rng

        let banked = GameStore.bankHaul(of: run, outcomeID: 77, into: &state,
                                        fraction: 0.5, rng: &rng)
        let recovered = banked.recoveredLines.compactMap { line -> RunExitSummary.ReceiptLine.Material? in
            guard case .materialSample(let material) = line else { return nil }
            return material
        }
        let lost = banked.lostLines.compactMap { line -> RunExitSummary.ReceiptLine.Material? in
            guard case .materialSample(let material) = line else { return nil }
            return material
        }

        XCTAssertEqual(recovered.count, 1)
        XCTAssertEqual(lost.count, 1)
        XCTAssertEqual(Set((recovered + lost).map(\.lineID)).count, 2)
        XCTAssertTrue(recovered[0].lineID.contains("-recovered-"))
        XCTAssertTrue(lost[0].lineID.contains("-lost-"))
        XCTAssertTrue((recovered + lost).map(\.sample).contains(first))
        XCTAssertTrue((recovered + lost).map(\.sample).contains(second))
    }

    func testReturnReceiptFreezesAntiLockSubsidyAndFinalRunwayAtomically() throws {
        let store = GameStore(io: .temporary(name: "return-subsidy-\(UUID().uuidString)"))
        let required = EconomyRules.minimumBindCost(in: store.state)
        store.mutate("fixture: exactly one departure") { state in
            state.base.essence = required
            state.base.resources = ResourcePool()
        }
        XCTAssertTrue(store.bindAndDepart())

        store.endRunWithPartialHaul(reason: "empty return", kind: .defeat)

        let receipt = try XCTUnwrap(store.state.worlds.lastExit?.essenceEconomy)
        XCTAssertGreaterThan(receipt.antiLockSubsidy, 0)
        XCTAssertEqual(receipt.netRunway, EconomyRules.spendableEssence(in: store.state))
        XCTAssertGreaterThanOrEqual(receipt.netRunway,
                                    EconomyRules.minimumBindCost(in: store.state))
    }

    func testMigrationContinuesAfterTemporaryTradingPostReceipt() throws {
        var legacy = GameState.newGame()
        legacy.base.tradingPost.expeditionOutcomeID = 7
        legacy.base.tradingPost.refreshSequence = 7
        var object = try XCTUnwrap(JSONSerialization.jsonObject(
            with: SaveCodec.makeEncoder().encode(legacy)) as? [String: Any])
        var worlds = try XCTUnwrap(object["worlds"] as? [String: Any])
        worlds.removeValue(forKey: "outcomeSequence")
        object["worlds"] = worlds

        var decoded = try SaveCodec.makeDecoder().decode(
            GameState.self, from: JSONSerialization.data(withJSONObject: object))
        XCTAssertEqual(decoded.worlds.outcomeSequence, 7)
        XCTAssertEqual(decoded.worlds.mintOutcomeID(), 8)
    }
}
