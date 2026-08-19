import XCTest
@testable import Bookbinder

@MainActor
final class ExpeditionOutcomeTests: XCTestCase {
    func testReturnRecapCanOnlyCloseThroughItsExplicitContinueAction() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent()
        let source = try String(contentsOf: root.appending(path: "Sources/App/RootView.swift"),
                                encoding: .utf8)
        XCTAssertTrue(source.contains(".sheet(item: Binding(get: { store.state.worlds.lastExit }, set: { _ in"))
        XCTAssertTrue(source.contains("Button(\"Continue\", action: dismiss)"))
        XCTAssertTrue(source.contains(".interactiveDismissDisabled()"))
        XCTAssertFalse(source.contains("if value == nil { store.dismissRunExitSummary() }"))
    }

    func testReturnRecapKeepsWorldPagesSeparateAndDoesNotLeakUninspectedTitles() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent()
        let source = try String(contentsOf: root.appending(path: "Sources/App/RootView.swift"),
                                encoding: .utf8)
        XCTAssertTrue(source.contains("World Pages kept"))
        XCTAssertTrue(source.contains("World Pages lost"))
        XCTAssertTrue(source.contains("page.inspected ? page.definition.title : \"Unknown page\""))
        XCTAssertFalse(source.contains("recapSection(\"World Pages"),
                       "physical pages must not be projected as generic item/resource gains")
    }
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

    func testMaterialReserveRecapAggregatesResourcesWhileFreezingEveryExactUnit() throws {
        let store = fundedStore()
        XCTAssertTrue(store.bindAndDepart())
        var run = try XCTUnwrap(store.state.worlds.activeRun)
        let hide = MaterialSample(kind: .hide, properties: MaterialProperties(flexibility: 62),
                                  grade: 57, source: "plain grazer")
        let bone = MaterialSample(kind: .bone, properties: MaterialProperties(density: 78),
                                  grade: 71, source: "dense walker")
        run.materialReserve.addHarvested(hide, count: 19,
                                         sourceReceipt: "run:1:foe:100", dropOrdinal: 0)
        run.materialReserve.addHarvested(bone, count: 6,
                                         sourceReceipt: "run:1:foe:101", dropOrdinal: 0)
        var state = store.state
        let banked = GameStore.bankHaul(of: run, outcomeID: 44, into: &state, fraction: 1)

        XCTAssertEqual(banked.resources.first { $0.name == "Hides" }?.count, 19)
        XCTAssertEqual(banked.resources.first { $0.name == "Bones" }?.count, 6)
        XCTAssertTrue(banked.items.isEmpty)
        let materialLines = banked.recoveredLines.compactMap { line -> RunExitSummary.ReceiptLine.Material? in
            guard case .materialSample(let material) = line else { return nil }
            return material
        }
        XCTAssertEqual(materialLines.count, 25)
        XCTAssertEqual(Set(materialLines.compactMap(\.reserveUnitID)).count, 25)
        XCTAssertEqual(state.base.materialReserve.count, 25)

        let summary = RunExitSummary(runIndex: 1, kind: .portal, reason: "fixture",
                                     turnsTaken: 1, haulKeptFraction: 1,
                                     resources: banked.resources, items: banked.items,
                                     recoveredLines: banked.recoveredLines)
        XCTAssertEqual(summary.resources.first { $0.name == "Hides" }?.count, 19)
        XCTAssertEqual(summary.resources.first { $0.name == "Bones" }?.count, 6)
        XCTAssertTrue(summary.items.isEmpty)
    }

    func testReturnRecapNamesResourcesAndItemsWithCategorySpecificEmptyCopy() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf: root.appending(path: "Sources/App/RootView.swift"),
                                encoding: .utf8)
        XCTAssertTrue(source.contains("receiptSection(\"Resources\", lines: RunExitRecapPresentation.resources("))
        XCTAssertTrue(source.contains("receiptSection(\"Items\", lines: RunExitRecapPresentation.items("))
        XCTAssertTrue(source.contains("No \\(title.lowercased()) this trip."))
        XCTAssertFalse(source.contains("recapSection(\"Loot\""))
    }

    func testReserveUnitsConcludeExactlyAcrossFullPartialAndFailureOutcomes() throws {
        for (label, fraction) in [("full", 1.0), ("partial", 0.5), ("failure", 0.0)] {
            let store = fundedStore("reserve-\(label)")
            XCTAssertTrue(store.bindAndDepart())
            var run = try XCTUnwrap(store.state.worlds.activeRun)
            run.tuning.collapseRecoveryFraction = fraction
            for index in 0..<6 {
                let kind: MaterialKind = index.isMultiple(of: 2) ? .hide : .bone
                let sample = MaterialSample(
                    kind: kind, properties: MaterialProperties(
                        hardness: Double(20 + index), flexibility: Double(40 + index)
                    ),
                    grade: Double(60 + index), source: "\(label)-sample-\(index)",
                    qualifier: index.isMultiple(of: 2) ? "pale" : "dense"
                )
                run.materialReserve.add(MaterialReserveUnit(
                    id: .init(rawValue: "\(label)-unit-\(index)"), sample: sample,
                    protectedReturn: index < 2
                ))
            }
            let expected = run.materialReserve.partitionedForFailure(
                fraction: fraction, outcomeID: 1
            )
            store.mutate("fixture: reserve outcome \(label)") {
                $0.worlds.activeRun = run
            }

            store.endRunWithPartialHaul(reason: "fixture \(label)", kind: .defeat)

            let summary = try XCTUnwrap(store.state.worlds.lastExit)
            let recovered: [RunExitSummary.ReceiptLine.Material] = summary.recoveredLines.compactMap {
                line in
                guard case .materialSample(let material) = line else { return nil }
                return material
            }
            let lost: [RunExitSummary.ReceiptLine.Material] = summary.lostLines.compactMap {
                line in
                guard case .materialSample(let material) = line else { return nil }
                return material
            }
            XCTAssertEqual(Set(recovered.compactMap { $0.reserveUnitID }),
                           Set(expected.kept.units.map(\.id)), label)
            XCTAssertEqual(Set(lost.compactMap { $0.reserveUnitID }),
                           Set(expected.lost.units.map(\.id)), label)
            XCTAssertTrue(run.materialReserve.units.filter(\.protectedReturn).allSatisfy { unit in
                recovered.contains { $0.reserveUnitID == unit.id && $0.sample == unit.sample }
            }, label)
            XCTAssertEqual(Set(store.state.base.materialReserve.units.map(\.id)),
                           Set(expected.kept.units.map(\.id)), label)
            XCTAssertTrue(store.state.base.materialReserve.units.allSatisfy {
                !$0.protectedReturn
            }, label)

            let expectedCounts = Dictionary(grouping: expected.kept.units, by: \.sample.kind)
                .mapValues(\.count)
            for (kind, count) in expectedCounts {
                let name = count == 1 ? kind.displayName : kind.pluralName.capitalisedSentence
                XCTAssertEqual(summary.resources.first { $0.name == name }?.count, count, label)
            }
            XCTAssertTrue(summary.items.isEmpty, label)
            XCTAssertFalse(store.state.base.inventory.stacks.contains {
                $0.catalogID == Items.material
            }, label)
            XCTAssertFalse(store.state.base.spillover.contains {
                $0.catalogID == Items.material
            }, label)

            let concluded = store.state
            store.endRunWithPartialHaul(reason: "replayed \(label)", kind: .defeat)
            XCTAssertEqual(store.state, concluded, "concluding \(label) twice must be idempotent")
        }
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

    func testRunExitRecapSeparatesTypedResourcesAndItemsWithoutFlatteningIdentity() {
        let lines: [RunExitSummary.ReceiptLine] = [
            .resource(.init(lineID: "ore", id: Resources.ore, quantity: 3,
                            fallbackName: "Ore", fallbackIcon: "cube")),
            .materialSample(.init(lineID: "hide", sourceStackID: nil,
                                  catalogID: Items.material,
                                  sample: .init(kind: .hide, properties: .init(),
                                                grade: 42, source: "browser"),
                                  identified: true, fallbackName: "Hide",
                                  fallbackIcon: "shippingbox")),
            .stackableItem(.init(lineID: "tonic", instanceID: .init(rawValue: 71),
                                 snapshot: .init(id: .init(rawValue: 71),
                                                 catalogID: Items.essenceCrystal, count: 2),
                                 quantity: 2, fallbackName: "Tonic", fallbackIcon: "flask")),
            .legacy(.init(stableID: "legacy-resource-ore", fallbackName: "Old ore",
                          fallbackIcon: "cube", quantity: 1)),
            .legacy(.init(stableID: "legacy-item-tonic", fallbackName: "Old tonic",
                          fallbackIcon: "flask", quantity: 1)),
        ]

        XCTAssertEqual(RunExitRecapPresentation.resources(in: lines).map(\.id),
                       [lines[0].id, lines[1].id, lines[3].id])
        XCTAssertEqual(RunExitRecapPresentation.items(in: lines).map(\.id),
                       [lines[2].id, lines[4].id])
    }

    func testRunExitRecapSourceUsesTypedSixAcrossTilesAndAnchoredLegacyFallback() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf: root.appending(path: "Sources/App/RootView.swift"),
                                encoding: .utf8)
        XCTAssertTrue(source.contains("in: summary.recoveredLines"))
        XCTAssertTrue(source.contains("in: summary.lostLines"))
        XCTAssertTrue(source.contains("SixAcrossItemGrid(data: lines"))
        XCTAssertTrue(source.contains("AnchoredItemDetailButton(item: line"))
        XCTAssertTrue(source.contains("ResourceIconTile(resourceID:"))
        XCTAssertTrue(source.contains("ItemIconTile(icon:"))
        XCTAssertTrue(source.contains("LegacyReceiptIconTile(icon:"))
        XCTAssertFalse(source.contains("recapSection(\"Resources\", gains: summary.resources)"))
        XCTAssertFalse(source.contains("recapSection(\"Items\", gains: summary.items)"))
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

    func testDecision207ResourceBudgetIsOutcomeWideAndLargestRemainderStable() {
        for fraction in [0.25, 0.5, 0.75] {
            let oneKind = ResourcePool([Resources.ore: 4])
            let fragmented = ResourcePool([Resources.ore: 1, Resources.fiber: 1,
                                           Resources.resin: 1, Resources.essenceRaw: 1])
            let expected = Int(ceil(4 * fraction))
            XCTAssertEqual(oneKind.retainedForFailure(fraction: fraction, outcomeID: 41).totalUnits,
                           expected)
            let first = fragmented.retainedForFailure(fraction: fraction, outcomeID: 41)
            XCTAssertEqual(first.totalUnits, expected)
            XCTAssertEqual(first, fragmented.retainedForFailure(fraction: fraction, outcomeID: 41))
        }
        XCTAssertEqual(ResourcePool([Resources.ore: 1])
            .retainedForFailure(fraction: 0.5, outcomeID: 9).totalUnits, 1)
        XCTAssertTrue(ResourcePool([Resources.ore: 9])
            .retainedForFailure(fraction: 0, outcomeID: 9).isEmpty)
    }

    func testDecision207DiscreteBudgetIgnoresStackFragmentationAndProtectsPackedUnits() throws {
        let merged = Inventory(slots: 8, stacks: [
            ItemStack(id: InstanceID(rawValue: 800), catalogID: "salve", count: 4)
        ])
        let fragmented = Inventory(slots: 8, stacks: [
            ItemStack(id: InstanceID(rawValue: 801), catalogID: "salve", count: 1),
            ItemStack(id: InstanceID(rawValue: 802), catalogID: "draught_clearing", count: 1),
            ItemStack(id: InstanceID(rawValue: 803), catalogID: "draught_quenching", count: 1),
            ItemStack(id: InstanceID(rawValue: 804), catalogID: "antidote_broad", count: 1)
        ])
        for fraction in [0.25, 0.5, 0.75] {
            let expected = Int(ceil(4 * fraction))
            let mergedPartition = merged.partitionedForFailure(fraction: fraction, outcomeID: 51)
            let fragmentedPartition = fragmented.partitionedForFailure(fraction: fraction, outcomeID: 51)
            XCTAssertEqual(mergedPartition.kept.stacks.reduce(0) { $0 + $1.count }, expected)
            XCTAssertEqual(fragmentedPartition.kept.stacks.reduce(0) { $0 + $1.count }, expected)

            let reordered = Inventory(slots: 8, stacks: Array(fragmented.stacks.reversed()))
                .partitionedForFailure(fraction: fraction, outcomeID: 51)
            XCTAssertEqual(Set(fragmentedPartition.kept.stacks.map(\.id)),
                           Set(reordered.kept.stacks.map(\.id)))

            let roundTripped = try JSONDecoder().decode(
                Inventory.self,
                from: JSONEncoder().encode(fragmented)
            ).partitionedForFailure(fraction: fraction, outcomeID: 51)
            XCTAssertEqual(Set(fragmentedPartition.kept.stacks.map(\.id)),
                           Set(roundTripped.kept.stacks.map(\.id)))
        }

        var carried = ItemStack(id: InstanceID(rawValue: 805), catalogID: "salve", count: 4)
        carried.protectedReturnCount = 2
        let store = fundedStore()
        XCTAssertTrue(store.bindAndDepart())
        var run = try XCTUnwrap(store.state.worlds.activeRun)
        run.satchelItems = Inventory(slots: 8, stacks: [carried])
        var state = GameState.newGame()
        state.base.inventory.stacks = []
        var rng = run.rng
        let banked = GameStore.bankHaul(of: run, outcomeID: 52, into: &state,
                                        fraction: 0, rng: &rng)
        XCTAssertEqual(banked.items.reduce(0) { $0 + $1.count }, 2)
        XCTAssertEqual(banked.lostItems.reduce(0) { $0 + $1.count }, 2)
    }

    func testDecision207PartitionPreservesExactGearAndMaterialUnitsWithoutDuplication() throws {
        var gear = ItemStack(id: InstanceID(rawValue: 901), catalogID: "blade_keen")
        gear.upgradeLevel = 2
        let pale = MaterialSample(kind: .hide, properties: .init(insulation: 31),
                                  grade: 42, source: "pale")
        let shaggy = MaterialSample(kind: .hide, properties: .init(insulation: 67),
                                    grade: 81, source: "shaggy")
        let materials = ItemStack(id: InstanceID(rawValue: 902), catalogID: Items.material,
                                  materials: [pale, shaggy])
        let inventory = Inventory(slots: 8, stacks: [gear, materials])
        let partition = inventory.partitionedForFailure(fraction: 0.5, outcomeID: 61)
        let all = partition.kept.stacks + partition.lost.stacks
        XCTAssertEqual(all.reduce(0) { $0 + $1.count }, 3)
        XCTAssertEqual(all.flatMap { $0.materials }.sorted { $0.grade < $1.grade }, [pale, shaggy])
        XCTAssertEqual(all.first { $0.catalogID == gear.catalogID }?.upgradeLevel, 2)
        XCTAssertEqual(partition.kept.stacks.reduce(0) { $0 + $1.count }, 2)
    }

    func testDecision207ProtectedMaterialsAreComplementaryExactSamples() {
        let samples = [
            MaterialSample(kind: .hide, properties: .init(insulation: 11),
                           grade: 10, source: "first"),
            MaterialSample(kind: .hide, properties: .init(insulation: 22),
                           grade: 20, source: "second"),
            MaterialSample(kind: .hide, properties: .init(insulation: 33),
                           grade: 30, source: "third")
        ]
        var stack = ItemStack(id: InstanceID(rawValue: 910), catalogID: Items.material,
                              materials: samples)
        stack.protectedReturnCount = 1

        let parts = stack.partitionedForReturn()
        XCTAssertEqual(parts.protected?.materials, Array(samples.prefix(1)))
        XCTAssertEqual(parts.atRisk?.materials, Array(samples.suffix(2)))
        XCTAssertEqual((parts.protected?.materials ?? []) + (parts.atRisk?.materials ?? []), samples)
        XCTAssertEqual((parts.protected?.count ?? 0) + (parts.atRisk?.count ?? 0), samples.count)
    }

    func testDecision207MaterialSelectionIgnoresReorderSplitMergeAndFreezesTypedSides() throws {
        let samples = [
            MaterialSample(kind: .hide, properties: .init(hardness: 13, insulation: 19),
                           grade: 21, source: "alpha", qualifier: "ashen"),
            MaterialSample(kind: .hide, properties: .init(density: 29, flexibility: 31),
                           grade: 37, source: "beta", qualifier: "shaggy"),
            MaterialSample(kind: .hide, properties: .init(lustre: 41, reactivity: 43),
                           grade: 47, source: "gamma", qualifier: "pale"),
            MaterialSample(kind: .hide, properties: .init(insulation: 53),
                           grade: 59, source: "delta")
        ]
        let merged = Inventory(slots: 8, stacks: [
            ItemStack(id: InstanceID(rawValue: 920), catalogID: Items.material,
                      materials: samples)
        ])
        let splitReordered = Inventory(slots: 8, stacks: [
            ItemStack(id: InstanceID(rawValue: 922), catalogID: Items.material,
                      materials: [samples[3], samples[1]]),
            ItemStack(id: InstanceID(rawValue: 921), catalogID: Items.material,
                      materials: [samples[2], samples[0]])
        ])
        let mergedPartition = merged.partitionedForFailure(fraction: 0.5, outcomeID: 71)
        let splitPartition = splitReordered.partitionedForFailure(fraction: 0.5, outcomeID: 71)
        let samplesBySource: (Inventory) -> [MaterialSample] = {
            $0.stacks.flatMap { $0.materials }.sorted { $0.source < $1.source }
        }
        XCTAssertEqual(samplesBySource(mergedPartition.kept), samplesBySource(splitPartition.kept))
        XCTAssertEqual(samplesBySource(mergedPartition.lost), samplesBySource(splitPartition.lost))

        let store = fundedStore()
        XCTAssertTrue(store.bindAndDepart())
        var run = try XCTUnwrap(store.state.worlds.activeRun)
        run.satchelItems = splitReordered
        var state = GameState.newGame()
        state.base.inventory.stacks = []
        var rng = run.rng
        let rngBefore = rng
        let banked = GameStore.bankHaul(of: run, outcomeID: 71, into: &state,
                                        fraction: 0.5, rng: &rng)
        XCTAssertEqual(rng, rngBefore, "failure partition must not consume the live run RNG")
        let recovered = banked.recoveredLines.compactMap { line -> MaterialSample? in
            guard case .materialSample(let material) = line else { return nil }
            return material.sample
        }.sorted { $0.source < $1.source }
        let lost = banked.lostLines.compactMap { line -> MaterialSample? in
            guard case .materialSample(let material) = line else { return nil }
            return material.sample
        }.sorted { $0.source < $1.source }
        XCTAssertEqual(recovered, samplesBySource(splitPartition.kept))
        XCTAssertEqual(lost, samplesBySource(splitPartition.lost))
        XCTAssertEqual((recovered + lost).sorted { $0.source < $1.source },
                       samples.sorted { $0.source < $1.source })
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
