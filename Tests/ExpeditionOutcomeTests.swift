import SwiftUI
import UIKit
import XCTest
@testable import Bookbinder

@MainActor
final class ExpeditionOutcomeTests: XCTestCase {
    @MainActor
    func testReturnActionWholeFaceShowsPressedStateWithoutDismissing() throws {
        let summary = RunExitSummary(
            runIndex: 1, kind: .portal, reason: "Returned.", departureState: .holding,
            turnsTaken: 1, haulKeptFraction: 1, resources: [], items: [],
            lostResources: [], lostItems: [], progress: [], writings: [],
            recruitedTravellers: [], essenceEconomy: .init(rawCollected: 0, bindCostPaid: 0,
                                                            springYield: 0, netRunway: 0))
        var dismissals = 0
        let store = GameStore(io: .temporary(name: "return-press-\(UUID().uuidString)"))
        FullFacePressMeasurements.reset()
        let controller = UIHostingController(rootView:
            RunExitSummaryView(summary: summary, dismiss: { dismissals += 1 })
                .environmentObject(store)
                .environment(\.fullFacePressFixtureID, "run-exit.continue")
                .frame(width: 368, height: 800))
        let window = UIWindow(frame: .init(x: 0, y: 0, width: 368, height: 800))
        window.rootViewController = controller; window.makeKeyAndVisible()
        controller.view.frame = window.bounds; controller.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.08))
        let measurement = try XCTUnwrap(FullFacePressMeasurements.values["run-exit.continue"])
        XCTAssertTrue(measurement.isPressed)
        XCTAssertEqual(measurement.frame.width, 344, accuracy: 0.5)
        XCTAssertEqual(measurement.frame.height, 54, accuracy: 0.5)
        XCTAssertEqual(dismissals, 0)
        window.isHidden = true
    }

    private func rgba(_ image: UIImage, x: Int, y: Int) throws -> [UInt8] {
        let cg = try XCTUnwrap(image.cgImage)
        let data = try XCTUnwrap(cg.dataProvider?.data)
        let bytes = CFDataGetBytePtr(data)!
        let offset = y * cg.bytesPerRow + x * 4
        return Array(UnsafeBufferPointer(start: bytes + offset, count: 4))
    }

    private func departureRun(player: GridPoint = .init(x: 0, y: 0),
                              tiles: [Tile] = Array(repeating: Tile(), count: 4),
                              collapsedOnTurn: Int? = nil) -> WorldRun {
        var run = WorldRun(
            runIndex: 9, book: BoundBook(symbols: [:], randomlyFilled: [], essencePaid: 0),
            mapSeed: 90, rng: SeededRNG(seed: 90),
            map: WorldMap(width: 2, height: 2, tiles: tiles,
                          entry: GridPoint(x: 0, y: 0)),
            playerPosition: player
        )
        run.collapsedOnTurn = collapsedOnTurn
        return run
    }

    func testWorldDepartureStateUsesExactPreClearPhysicalClassificationAndCorruptionFallback() {
        XCTAssertEqual(WorldDepartureState.capture(from: departureRun()), .holding)

        var cracking = Array(repeating: Tile(), count: 4)
        cracking[3].isCracking = true
        XCTAssertEqual(WorldDepartureState.capture(from: departureRun(tiles: cracking,
                                                                       collapsedOnTurn: 12)),
                       .cracking)

        var breaking = cracking
        breaking[2].isCrumbled = true
        XCTAssertEqual(WorldDepartureState.capture(from: departureRun(tiles: breaking,
                                                                       collapsedOnTurn: 12)),
                       .breaking)

        var reached = breaking
        reached[0].isCrumbled = true
        XCTAssertEqual(WorldDepartureState.capture(from: departureRun(tiles: reached,
                                                                       collapsedOnTurn: 12)),
                       .collapseReachedParty)

        XCTAssertNil(WorldDepartureState.capture(from: departureRun(collapsedOnTurn: 12)),
                     "collapse metadata without physical evidence must retain the saved reason")
        XCTAssertNil(WorldDepartureState.capture(from: departureRun(
            player: GridPoint(x: 99, y: 99))), "corrupt coordinates must fail closed")
    }

    func testDepartureStatePersistsByteEquivalentlyAndOldSaveKeepsItsReason() throws {
        let summary = RunExitSummary(
            runIndex: 4, kind: .portal, reason: "Saved legacy departure reason.",
            departureState: .cracking, turnsTaken: 7, haulKeptFraction: 1
        )
        let encoded = try SaveCodec.makeEncoder().encode(summary)
        let restored = try SaveCodec.makeDecoder().decode(RunExitSummary.self, from: encoded)
        XCTAssertEqual(restored, summary)
        XCTAssertEqual(restored.departureCopy, "Cracks were spreading when you left.")

        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        object.removeValue(forKey: "departureState")
        let legacy = try SaveCodec.makeDecoder().decode(
            RunExitSummary.self, from: JSONSerialization.data(withJSONObject: object))
        XCTAssertNil(legacy.departureState)
        XCTAssertEqual(legacy.departureCopy, "Saved legacy departure reason.")

        let oldPortal = RunExitSummary(runIndex: 5, kind: .portal,
                                       reason: "You returned through a portal.",
                                       turnsTaken: 2, haulKeptFraction: 1)
        let decodedPortal = try SaveCodec.makeDecoder().decode(
            RunExitSummary.self, from: SaveCodec.makeEncoder().encode(oldPortal))
        XCTAssertNil(decodedPortal.departureState)
        XCTAssertEqual(decodedPortal.departureCopy,
                       "This Expedition record is from an older save, so the world’s departure state was not recorded.")

        let oldDefeat = RunExitSummary(runIndex: 6, kind: .defeat,
                                       reason: "Your party was carried home after the Binder fell.",
                                       turnsTaken: 9, haulKeptFraction: 0.5)
        XCTAssertEqual(oldDefeat.departureCopy,
                       "Your party was carried home after the Binder fell.")
    }

    func testPermanentGainsPresentationCoversEmptyFullAndMixedFactsExactly() {
        let empty = RunExitPermanentGainsPresentation(summary: RunExitSummary(
            runIndex: 1, kind: .portal, reason: "done", turnsTaken: 1, haulKeptFraction: 1))
        XCTAssertEqual(empty.cells.map(\.id), ["people"])
        XCTAssertEqual(empty.cells.first?.value, "No one joined the village")
        XCTAssertNil(empty.cells.first?.detail)

        let full = RunExitSummary(
            runIndex: 2, kind: .portal, reason: "done", turnsTaken: 3, haulKeptFraction: 1,
            progress: [
                .init(member: .binder, name: "Binder", experience: 7, levels: 1, finalLevel: 2),
                .init(member: .member(0), name: "Mara", experience: 7, levels: 0, finalLevel: 1)
            ], pages: ["mara_where_0"], recruitedTravellers: ["mara"]
        )
        let fullCells = RunExitPermanentGainsPresentation(summary: full).cells
        XCTAssertEqual(fullCells.map(\.id), ["writing", "people", "xp", "levels"])
        XCTAssertEqual(fullCells[0].value, "1 piece of writing found")
        XCTAssertEqual(fullCells[1].value, "1 person joined the village")
        XCTAssertEqual(fullCells[2].value, "+7 XP each")
        XCTAssertEqual(fullCells[2].detail, "Binder · Mara")
        XCTAssertEqual(fullCells[3].value, "1 level-up across the party")
        XCTAssertNil(fullCells[3].detail)

        let mixed = RunExitSummary(
            runIndex: 3, kind: .defeat, reason: "done", turnsTaken: 9, haulKeptFraction: 0.5,
            progress: [
                .init(member: .binder, name: "Binder", experience: 9, levels: 1, finalLevel: 4),
                .init(member: .member(0), name: "Mara", experience: 7, levels: 1, finalLevel: 3),
                .init(member: .member(1), name: "Edren", experience: 5, levels: 0, finalLevel: 2),
                .init(member: .member(2), name: "Sela", experience: 3, levels: 0, finalLevel: 2),
                .init(member: .member(3), name: "Tovin", experience: 1, levels: 0, finalLevel: 1)
            ], pages: ["mara_where_0"],
            writings: [.init(id: "writing-two", kind: .fieldNote, title: "Two", prose: "Two")],
            recruitedTravellers: ["mara", "edren"]
        )
        let mixedCells = RunExitPermanentGainsPresentation(summary: mixed).cells
        XCTAssertEqual(mixedCells[0].value, "2 pieces of writing found")
        XCTAssertEqual(mixedCells[1].value, "2 people joined the village")
        XCTAssertEqual(mixedCells[2].value, "Party earned XP")
        XCTAssertEqual(mixedCells[2].detail,
                       "Binder +9 XP · Mara +7 XP · Edren +5 XP · Sela +3 XP · Tovin +1 XP")
        XCTAssertEqual(mixedCells[3].value, "2 level-ups across the party")
    }

    func testLiveReturnPathsFreezeDepartureBeforeClearingAndConstructorCoversAbandon() throws {
        func store(with run: WorldRun, name: String) -> GameStore {
            let store = GameStore(io: .temporary(name: "departure-\(name)-\(UUID().uuidString)"))
            store.mutate("fixture: departure path") { state in state.worlds.activeRun = run }
            return store
        }

        var portalRun = departureRun()
        portalRun.map.tiles[0].content = .portal(isEntry: true)
        let portal = store(with: portalRun, name: "portal")
        portal.portalHome()
        XCTAssertEqual(portal.state.worlds.lastExit?.kind, .portal)
        XCTAssertEqual(portal.state.worlds.lastExit?.departureState, .holding)
        XCTAssertNil(portal.state.worlds.activeRun)

        var waystoneRun = departureRun()
        waystoneRun.map.tiles[2].isCracking = true
        let waystoneStack = ItemStack(id: InstanceID(rawValue: 400), catalogID: "waystone")
        waystoneRun.satchelItems.stacks = [waystoneStack]
        let waystone = store(with: waystoneRun, name: "waystone")
        waystone.useItemInWorld(waystoneStack, on: .binder)
        XCTAssertEqual(waystone.state.worlds.lastExit?.kind, .waystone)
        XCTAssertEqual(waystone.state.worlds.lastExit?.departureState, .cracking)

        var defeatRun = departureRun(collapsedOnTurn: 8)
        defeatRun.map.tiles[2].isCrumbled = true
        let defeat = store(with: defeatRun, name: "defeat")
        defeat.endRunWithPartialHaul(reason: "defeat", kind: .defeat)
        XCTAssertEqual(defeat.state.worlds.lastExit?.departureState, .breaking)

        var collapseRun = departureRun(collapsedOnTurn: 8)
        collapseRun.map.tiles[0].isCrumbled = true
        let collapse = store(with: collapseRun, name: "collapse")
        collapse.endRunWithPartialHaul(reason: "collapse", kind: .collapse)
        XCTAssertEqual(collapse.state.worlds.lastExit?.departureState, .collapseReachedParty)

        let emptyBank = GameStore.BankedHaul(
            resources: [], items: [], lostResources: [], lostItems: [],
            recoveredLines: [], lostLines: [], unidentifiedItemIDs: [], returnedRawEssence: false)
        for kind in [RunExitSummary.Kind.portal, .waystone, .defeat, .collapse, .abandon] {
            let receipt = GameStore.makeReturnReceipt(
                run: portalRun, outcomeID: 900, kind: kind, reason: "fallback", fraction: 1,
                banked: emptyBank, departureState: .holding,
                autoRefinedRaw: 0, autoRefinedEssence: 0, springYield: 0,
                state: portal.state)
            XCTAssertEqual(receipt.kind, kind)
            XCTAssertEqual(receipt.departureState, .holding)
        }
        XCTAssertNil(portal.state.worlds.activeRun,
                     "portal proves capture survived the destructive clear transaction")
    }

    func testReturnVisibleStringCensusUsesCanonicalPermanentGainTerms() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent()
        let source = try String(contentsOf: root.appending(path: "Sources/App/RootView.swift"),
                                encoding: .utf8)
        XCTAssertTrue(source.contains("Text(\"PERMANENT GAINS\")"))
        XCTAssertTrue(source.contains("Text(\"Knowledge, people & party\")"))
        XCTAssertTrue(source.contains("heading: \"Joined the village\""))
        XCTAssertTrue(source.contains("heading: \"XP earned\""))
        for retired in ["KEPT WITH YOU", "Writing & travellers", "current draft",
                        "People who came home", "Party progress", "party total"] {
            XCTAssertFalse(source.contains("Text(\"\(retired)"), retired)
        }
    }

    func testReturnRecapCanOnlyCloseThroughItsExplicitContinueAction() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent()
        let source = try String(contentsOf: root.appending(path: "Sources/App/RootView.swift"),
                                encoding: .utf8)
        XCTAssertTrue(source.contains(".sheet(item: Binding(get: { store.state.worlds.lastExit }, set: { _ in"))
        XCTAssertTrue(source.contains("Button(\"Return to Base\", action: dismiss)"))
        XCTAssertTrue(source.contains(".interactiveDismissDisabled()"))
        XCTAssertFalse(source.contains("if value == nil { store.dismissRunExitSummary() }"))
        XCTAssertFalse(source.contains("Recovered</button>"))
        XCTAssertFalse(source.contains("Lost</button>"))
        XCTAssertFalse(source.contains("Button(\"History\""))
    }

    func testReturnRecapUsesApprovedSingleReceiptComposition() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent()
        let source = try String(contentsOf: root.appending(path: "Sources/App/RootView.swift"),
                                encoding: .utf8)
        XCTAssertTrue(source.contains("Text(\"Expedition return\")"))
        XCTAssertTrue(source.contains("outcomePanel"))
        XCTAssertTrue(source.contains("compactReceiptSection("))
        XCTAssertTrue(source.contains("eyebrow: \"RECOVERED\""))
        XCTAssertTrue(source.contains("keptLedger"))
        XCTAssertTrue(source.contains("eyebrow: \"LOST\""))
        XCTAssertTrue(source.contains("Text(\"ESSENCE AVAILABLE\")"))
        XCTAssertTrue(source.contains("after refining"))
        XCTAssertTrue(source.contains("Enough to bind at least one more world"))
        XCTAssertTrue(source.contains(".scrollBounceBehavior(.basedOnSize)"))
        XCTAssertTrue(source.contains("count: 6"))
    }

    func testReturnRecapRendersAtApprovedOrdinaryPhoneSize() throws {
        let store = GameStore(io: .temporary(name: "return-recap-render-\(UUID().uuidString)"))
        func fixture(kind: RunExitSummary.Kind) -> RunExitSummary {
            RunExitSummary(
            runIndex: 12, kind: kind,
            reason: kind == .collapse ? "The world ended before every carried thing crossed over."
                                      : "The Atlas released the party at Base.",
            departureState: kind == .collapse ? .collapseReachedParty : .holding,
            turnsTaken: 24, haulKeptFraction: kind == .collapse ? 0.45 : 1,
            resources: [RunExitGain(name: "Resin", icon: "leaf", count: 4),
                        RunExitGain(name: "Copper", icon: "diamond", count: 2)],
            items: [RunExitGain(name: "Lesser Salve", icon: "cross.case", count: 1)],
            lostResources: [RunExitGain(name: "Briar", icon: "leaf", count: 1)],
            lostItems: [RunExitGain(name: "Chipped blade", icon: "shield", count: 1)],
            progress: [RunProgressGain(member: .binder, name: "Binder", experience: 2,
                                       levels: 0, finalLevel: 4)],
            writings: [.init(id: "fixture-writing", kind: .fieldNote,
                             title: "Weathered field note", prose: "A route home, kept for good.")],
            recruitedTravellers: ["mara"],
            essenceEconomy: .init(rawCollected: 12, bindCostPaid: 8,
                                  springYield: 4, netRunway: 40))
        }
        let returned = fixture(kind: .portal)
        let collapsed = fixture(kind: .collapse)
        var mixed = returned
        mixed.pages = ["mara_where_0"]
        mixed.writings = [
            .init(id: "fixture-writing-two", kind: .fieldNote,
                  title: "A second piece", prose: "A second permanent piece of writing.")
        ]
        mixed.recruitedTravellers = ["mara", "edren"]
        mixed.progress = [
            .init(member: .binder, name: "Binder", experience: 11, levels: 1, finalLevel: 5),
            .init(member: .member(0), name: "Mara", experience: 9, levels: 1, finalLevel: 4),
            .init(member: .member(1), name: "Edren", experience: 7, levels: 0, finalLevel: 3),
            .init(member: .member(2), name: "Sela", experience: 5, levels: 0, finalLevel: 2),
            .init(member: .member(3), name: "Tovin", experience: 3, levels: 0, finalLevel: 2)
        ]
        store.mutate("fixture: approved return recap") { state in
            for lesson in TutorialLessonID.allCases {
                state.tutorial.complete(lesson, fact: "visual_fixture")
            }
        }

        let states: [(name: String, summary: RunExitSummary,
                      detail: RunExitSummary.ReceiptLine?)] = [
            ("returned", returned, nil),
            ("collapsed", collapsed, nil),
            ("longest-mixed", mixed, nil),
            ("receipt-detail", returned, returned.recoveredLines.first)
        ]
        for state in states {
          for scheme in [ColorScheme.light, .dark] {
            let controller = UIHostingController(rootView:
                RunExitSummaryView(summary: state.summary, dismiss: {},
                                   selectedReceipt: state.detail).environmentObject(store)
                    .environment(\.colorScheme, scheme)
                    .environment(\.dynamicTypeSize, .large)
                    .frame(width: 368, height: 800)
            )
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 368, height: 800))
            window.rootViewController = controller
            controller.additionalSafeAreaInsets = UIEdgeInsets(top: 59, left: 0,
                                                                bottom: 34, right: 0)
            window.makeKeyAndVisible()
            controller.view.frame = window.bounds
            controller.view.layoutIfNeeded()
            RunLoop.main.run(until: Date().addingTimeInterval(0.2))
            let image = UIGraphicsImageRenderer(size: window.bounds.size).image { _ in
                controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
            }
            window.isHidden = true
            XCTAssertEqual(image.size, CGSize(width: 368, height: 800))
            XCTAssertNotEqual(try rgba(image, x: 184, y: 10), [0, 0, 0, 255])
            XCTAssertNotEqual(try rgba(image, x: 184, y: 785), [0, 0, 0, 255])
            let scrollFrame = RunExitSafeSpaceMeasurement.scrollFrame
            let actionFrame = RunExitSafeSpaceMeasurement.actionFrame
            XCTAssertGreaterThan(scrollFrame.height, 0)
            XCTAssertGreaterThan(actionFrame.height, 0)
            XCTAssertLessThanOrEqual(scrollFrame.maxY, actionFrame.minY + 0.5,
                                     "the fixed action may not cover the final recap row")
            let attachment = XCTAttachment(image: image)
            attachment.name = "return-recap-\(state.name)-\(scheme == .light ? "light" : "dark")"
            attachment.lifetime = .keepAlways
            add(attachment)
          }
        }
    }

    func testReturnRecapSafeSpaceChangeOwnsBackdropOnly() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent()
        let source = try String(contentsOf: root.appending(path: "Sources/App/RootView.swift"),
                                encoding: .utf8)
        let start = try XCTUnwrap(source.range(of: "struct RunExitSummaryView"))
        let end = try XCTUnwrap(source.range(of: "private var recapHeader",
                                             range: start.upperBound..<source.endIndex))
        let recap = String(source[start.lowerBound..<end.lowerBound])
        XCTAssertTrue(recap.contains(".background(PixelUITheme.screen.ignoresSafeArea())"))
        XCTAssertTrue(recap.contains("recapHeader\n            ScrollView"))
        XCTAssertFalse(recap.contains("Spacer("))
    }

    func testReturnRecapKeepsWorldPagesSeparateAndDoesNotLeakUninspectedTitles() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent()
        let source = try String(contentsOf: root.appending(path: "Sources/App/RootView.swift"),
                                encoding: .utf8)
        XCTAssertTrue(source.contains("pages: summary.keptWorldPages"))
        XCTAssertTrue(source.contains("pages: summary.lostWorldPages"))
        XCTAssertTrue(source.contains("page.inspected ? page.definition.title : \"Unknown page\""))
        XCTAssertFalse(source.contains("recapSection(\"World Pages"),
                       "physical pages must not be projected as generic item/resource gains")
    }
    private func fundedStore(_ name: String = #function) -> GameStore {
        let store = GameStore(io: .temporary(name: "outcome-\(name)-\(UUID().uuidString)"))
        store.mutate("fixture: fund") { $0.base.addEssenceCrystals(5_000) }
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
        let hide = CraftMaterialUnitV1(kind: .hide, properties: MaterialProperties(flexibility: 62),
                                  grade: 57, source: "plain grazer")
        let bone = CraftMaterialUnitV1(kind: .bone, properties: MaterialProperties(density: 78),
                                  grade: 71, source: "dense walker")
        run.creatureMaterialReserve.addHarvested(hide, count: 19,
                                         sourceReceipt: "run:1:foe:100", dropOrdinal: 0)
        run.creatureMaterialReserve.addHarvested(bone, count: 6,
                                         sourceReceipt: "run:1:foe:101", dropOrdinal: 0)
        let fibre = CraftMaterialUnitV1(kind: .fibre,
                                        properties: MaterialProperties(flexibility: 50),
                                        grade: 55, source: "field fibre")
        run.worldMaterialReserve.addHarvested(fibre, count: 2,
                                              sourceReceipt: "run:1:harvest:102", dropOrdinal: 0)
        var state = store.state
        let banked = GameStore.bankHaul(of: run, outcomeID: 44, into: &state, fraction: 1)

        XCTAssertEqual(banked.resources.first { $0.name == "Hides" }?.count, 19)
        XCTAssertEqual(banked.resources.first { $0.name == "Bones" }?.count, 6)
        XCTAssertTrue(banked.items.isEmpty)
        let materialLines = banked.recoveredLines.compactMap { line -> RunExitSummary.ReceiptLine.Material? in
            guard case .materialSample(let material) = line else { return nil }
            return material
        }
        XCTAssertEqual(materialLines.count, 27)
        XCTAssertEqual(Set(materialLines.compactMap(\.reserveUnitID)).count, 27)
        XCTAssertEqual(state.base.creatureMaterialReserve.count, 25)
        XCTAssertEqual(state.base.worldMaterialReserve.count, 2)

        let summary = RunExitSummary(runIndex: 1, kind: .portal, reason: "fixture",
                                     turnsTaken: 1, haulKeptFraction: 1,
                                     resources: banked.resources, items: banked.items,
                                     recoveredLines: banked.recoveredLines)
        XCTAssertEqual(summary.resources.first { $0.name == "Hides" }?.count, 19)
        XCTAssertEqual(summary.resources.first { $0.name == "Bones" }?.count, 6)
        XCTAssertTrue(summary.items.isEmpty)
    }

    func testReturnRecapCombinesTypedResourcesAndItemsInOneApprovedReceipt() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf: root.appending(path: "Sources/App/RootView.swift"),
                                encoding: .utf8)
        XCTAssertTrue(source.contains("eyebrow: \"RECOVERED\""))
        XCTAssertTrue(source.contains("lines: summary.recoveredLines"))
        XCTAssertTrue(source.contains("if lines.isEmpty && pages.isEmpty"))
        XCTAssertTrue(source.contains("Text(\"None\")"))
        XCTAssertFalse(source.contains("recapSection(\"Loot\""))
    }

    func testReserveUnitsConcludeExactlyAcrossFullPartialAndFailureOutcomes() throws {
        for (label, fraction) in [("full", 1.0), ("partial", 0.5), ("failure", 0.0)] {
            let store = fundedStore("reserve-\(label)")
            XCTAssertTrue(store.bindAndDepart())
            let arrivalID = try XCTUnwrap(store.state.worlds.pendingWorldArrivalReceiptID)
            XCTAssertTrue(store.enterPendingWorld(arrivalReceiptID: arrivalID))
            var run = try XCTUnwrap(store.state.worlds.activeRun)
            run.tuning.collapseRecoveryFraction = fraction
            for index in 0..<6 {
                let kind: MaterialFamilyID = index.isMultiple(of: 2) ? .hide : .bone
                let sample = CraftMaterialUnitV1(
                    kind: kind, properties: MaterialProperties(
                        hardness: Double(20 + index), flexibility: Double(40 + index)
                    ),
                    grade: Double(60 + index), source: "\(label)-sample-\(index)",
                    qualifier: index.isMultiple(of: 2) ? "pale" : "dense"
                )
                run.creatureMaterialReserve.add(CraftMaterialHoldingV1(
                    id: .init(rawValue: "\(label)-unit-\(index)"), sample: sample,
                    protectedReturn: index < 2
                ))
            }
            for index in 0..<2 {
                let family: MaterialFamilyID = index == 0 ? .timber : .fibre
                let sample = CraftMaterialUnitV1(
                    kind: family, properties: MaterialProperties(flexibility: Double(50 + index)),
                    grade: Double(55 + index), source: "\(label)-world-\(index)")
                run.worldMaterialReserve.add(CraftMaterialHoldingV1(
                    id: .init(rawValue: "\(label)-world-unit-\(index)"), sample: sample))
            }
            let expected = partitionCraftMaterialsForFailure(
                world: run.worldMaterialReserve, creature: run.creatureMaterialReserve,
                fraction: fraction, outcomeID: 1)
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
                           Set((expected.keptWorld.units + expected.keptCreature.units).map(\.id)), label)
            XCTAssertEqual(Set(lost.compactMap { $0.reserveUnitID }),
                           Set((expected.lostWorld.units + expected.lostCreature.units).map(\.id)), label)
            XCTAssertTrue(run.creatureMaterialReserve.units.filter(\.protectedReturn).allSatisfy { unit in
                recovered.contains { $0.reserveUnitID == unit.id && $0.sample == unit.sample }
            }, label)
            XCTAssertEqual(Set(store.state.base.worldMaterialReserve.units.map(\.id)),
                           Set(expected.keptWorld.units.map(\.id)), label)
            XCTAssertEqual(Set(store.state.base.creatureMaterialReserve.units.map(\.id)),
                           Set(expected.keptCreature.units.map(\.id)), label)
            XCTAssertTrue(store.state.base.worldMaterialReserve.units.allSatisfy {
                !$0.protectedReturn
            }, label)
            XCTAssertTrue(store.state.base.creatureMaterialReserve.units.allSatisfy {
                !$0.protectedReturn
            }, label)

            let expectedCounts = Dictionary(
                grouping: expected.keptWorld.units + expected.keptCreature.units,
                by: \.sample.kind)
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

    func testReturnReceiptFreezesStoredAndWaitingDestinationsAtBankTime() throws {
        var stored = ItemStack(id: InstanceID(rawValue: 71), catalogID: "blade_keen")
        stored.upgradeLevel = 1
        stored.protectedReturnCount = 1
        stored.isFavorite = true
        var waiting = ItemStack(id: InstanceID(rawValue: 72), catalogID: "shield_plain")
        waiting.upgradeLevel = 1
        waiting.identified = false
        waiting.isLocked = true
        var run = departureRun()
        run.satchelItems.stacks = [stored, waiting]
        var bankedState = GameState.newGame()
        bankedState.base.inventory = Inventory(slots: 1)
        bankedState.base.spillover = []
        let banked = GameStore.bankHaul(of: run, outcomeID: 82,
                                        into: &bankedState, fraction: 1)
        let summary = RunExitSummary(
            runIndex: run.runIndex, outcomeID: 82, kind: .portal, reason: "fixture",
            turnsTaken: run.turnsTaken, haulKeptFraction: 1,
            recoveredLines: banked.recoveredLines, lostLines: banked.lostLines)
        bankedState.worlds.lastExit = summary
        let items = summary.recoveredLines.compactMap { line -> RunExitSummary.ReceiptLine.Item? in
            switch line {
            case .stackableItem(let item), .uniqueItem(let item): item
            case .resource, .materialSample, .legacy: nil
            }
        }
        XCTAssertEqual(Set(items.map(\.instanceID)), [stored.id, waiting.id])
        XCTAssertEqual(items.map(\.recoveredDestination), [.stored, .waitingToSort])
        var returnedStored = stored
        returnedStored.protectedReturnCount = 0
        XCTAssertEqual(items.first { $0.instanceID == stored.id }?.snapshot, returnedStored,
                       "protection guarantees banking and is cleared by the existing return rule")
        XCTAssertEqual(items.first { $0.instanceID == waiting.id }?.snapshot, waiting)
        XCTAssertEqual(bankedState.base.inventory.stacks.map(\.id), [items[0].instanceID],
                       "the first rules-partitioned return must receive the first available slot")
        XCTAssertEqual(bankedState.base.spillover.map(\.id), [items[1].instanceID],
                       "the next rules-partitioned return must retain overflow ownership")

        bankedState.base.inventory.stacks = [waiting]
        bankedState.base.spillover = [stored]
        XCTAssertEqual(bankedState.worlds.lastExit?.recoveredLines, summary.recoveredLines,
                       "the immutable receipt must not reconstruct destination from current storage")

        let restored = try SaveCodec.makeDecoder().decode(
            GameState.self, from: SaveCodec.makeEncoder().encode(bankedState))
        XCTAssertEqual(restored.worlds.lastExit?.recoveredLines, summary.recoveredLines)

        var lossRun = run
        lossRun.satchelItems.stacks = [waiting]
        var allLostState = GameState.newGame()
        let allLost = GameStore.bankHaul(of: lossRun, outcomeID: 83,
                                         into: &allLostState, fraction: 0)
        XCTAssertTrue(allLost.recoveredLines.isEmpty)
        XCTAssertTrue(allLost.lostLines.allSatisfy { $0.recoveredItemDestination == nil },
                      "lost-side receipt lines retain their existing Return disposition")
    }

    func testRecoveredMaterialDestinationsAreFrozenWithoutChangingReserveBanking() throws {
        var run = departureRun()
        let sample = CraftMaterialUnitV1(kind: .hide, properties: .init(flexibility: 55),
                                    grade: 63, source: "receipt fixture")
        let unitID = CraftMaterialUnitID(rawValue: "receipt-hide")
        run.creatureMaterialReserve.add(CraftMaterialHoldingV1(id: unitID, sample: sample))
        let worldID = CraftMaterialUnitID(rawValue: "receipt-timber")
        let timber = CraftMaterialUnitV1(kind: .timber, properties: .init(hardness: 55),
                                         grade: 63, source: "world receipt fixture")
        run.worldMaterialReserve.add(CraftMaterialHoldingV1(id: worldID, sample: timber))
        var state = GameState.newGame()

        let banked = GameStore.bankHaul(of: run, outcomeID: 81, into: &state, fraction: 1)
        let material = try XCTUnwrap(banked.recoveredLines.compactMap {
            line -> RunExitSummary.ReceiptLine.Material? in
            guard case .materialSample(let material) = line else { return nil }
            return material
        }.first)
        XCTAssertEqual(material.recoveredDestination, .stored)
        XCTAssertTrue(state.base.creatureMaterialReserve.units.contains { $0.id == unitID })
        XCTAssertTrue(state.base.worldMaterialReserve.units.contains { $0.id == worldID })
    }

    func testLegacyTypedRecoveredItemDecodesWithDestinationNotRecorded() throws {
        let item = RunExitSummary.ReceiptLine.Item(
            lineID: "legacy-typed", instanceID: .init(rawValue: 91),
            snapshot: ItemStack(id: .init(rawValue: 91), catalogID: "blade_keen"), quantity: 1,
            fallbackName: "Keen blade", fallbackIcon: "shield")
        let summary = RunExitSummary(
            runIndex: 3, kind: .portal, reason: "legacy typed receipt", turnsTaken: 2,
            haulKeptFraction: 1, recoveredLines: [.uniqueItem(item)])

        let decoded = try SaveCodec.makeDecoder().decode(
            RunExitSummary.self, from: SaveCodec.makeEncoder().encode(summary))
        guard case .uniqueItem(let decodedItem) = try XCTUnwrap(decoded.recoveredLines.first) else {
            return XCTFail("expected exact typed receipt item")
        }
        XCTAssertNil(decodedItem.recoveredDestination,
                     "missing additive destination means the older receipt did not record it")
    }

#if DEBUG
    @MainActor
    func testReturnReceiptSemanticFramesCarryExactFrozenDestinationAndSide() throws {
        let stored = RunExitSummary.ReceiptLine.uniqueItem(.init(
            lineID: "stored", instanceID: .init(rawValue: 101),
            snapshot: ItemStack(id: .init(rawValue: 101), catalogID: "blade_keen"), quantity: 1,
            fallbackName: "Stored blade", fallbackIcon: "shield",
            recoveredDestination: .stored))
        let waiting = RunExitSummary.ReceiptLine.stackableItem(.init(
            lineID: "waiting", instanceID: .init(rawValue: 102),
            snapshot: ItemStack(id: .init(rawValue: 102), catalogID: Items.essenceCrystal, count: 2), quantity: 2,
            fallbackName: "Waiting crystals", fallbackIcon: "diamond",
            recoveredDestination: .waitingToSort))
        let legacyTyped = RunExitSummary.ReceiptLine.uniqueItem(.init(
            lineID: "not-recorded", instanceID: .init(rawValue: 103),
            snapshot: ItemStack(id: .init(rawValue: 103), catalogID: "shield_plain"), quantity: 1,
            fallbackName: "Older shield", fallbackIcon: "shield"))
        let lost = RunExitSummary.ReceiptLine.uniqueItem(.init(
            lineID: "lost", instanceID: .init(rawValue: 104),
            snapshot: ItemStack(id: .init(rawValue: 104), catalogID: "blade_keen"), quantity: 1,
            fallbackName: "Lost blade", fallbackIcon: "shield"))
        let summary = RunExitSummary(
            runIndex: 9, kind: .collapse, reason: "fixture", turnsTaken: 4,
            haulKeptFraction: 0.5, recoveredLines: [stored, waiting, legacyTyped],
            lostLines: [lost])
        let store = GameStore(io: .temporary(name: "return-destination-frames-\(UUID().uuidString)"))
        store.mutate("fixture: hide tutorial") { state in
            for lesson in TutorialLessonID.allCases {
                state.tutorial.complete(lesson, fact: "return_destination_fixture")
            }
        }
        RunExitSafeSpaceMeasurement.receiptFrames = [:]
        let controller = UIHostingController(rootView:
            RunExitSummaryView(summary: summary, dismiss: {}).environmentObject(store)
                .frame(width: 368, height: 800))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 368, height: 800))
        window.rootViewController = controller
        controller.additionalSafeAreaInsets = UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0)
        window.makeKeyAndVisible()
        controller.view.frame = window.bounds
        controller.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))

        let expected: [RunExitReceiptSemanticID] = [
            .init(side: .recovered, lineID: stored.id, destination: .stored),
            .init(side: .recovered, lineID: waiting.id, destination: .waitingToSort),
            .init(side: .recovered, lineID: legacyTyped.id, destination: nil),
            .init(side: .lost, lineID: lost.id, destination: nil),
        ]
        for identity in expected {
            let frame = try XCTUnwrap(RunExitSafeSpaceMeasurement.receiptFrames[identity])
            XCTAssertGreaterThan(frame.width, 0)
            XCTAssertGreaterThan(frame.height, 0)
            XCTAssertGreaterThanOrEqual(frame.minY, 59)
            XCTAssertLessThanOrEqual(frame.maxY, 766)
        }
        window.isHidden = true
    }
#endif

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

    func testRunExitRecapSourceUsesTypedSixAcrossTilesAndExactReceiptDetailFallback() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf: root.appending(path: "Sources/App/RootView.swift"),
                                encoding: .utf8)
        XCTAssertTrue(source.contains("lines: summary.recoveredLines"))
        XCTAssertTrue(source.contains("lines: summary.lostLines"))
        XCTAssertTrue(source.contains("count: 6"))
        XCTAssertTrue(source.contains("Button { selectedReceipt = line }"))
        XCTAssertTrue(source.contains("receiptDetailOverlay(selectedReceipt)"))
        XCTAssertTrue(source.contains("run-exit.receipt-detail"))
        XCTAssertTrue(source.contains("ResourceIconTile(resourceID:"))
        XCTAssertTrue(source.contains("ItemIconTile(icon:"))
        XCTAssertTrue(source.contains("LegacyReceiptIconTile(icon:"))
        XCTAssertFalse(source.contains("recapSection(\"Resources\", gains: summary.resources)"))
        XCTAssertFalse(source.contains("recapSection(\"Items\", gains: summary.items)"))
        XCTAssertTrue(source.contains(
            "gearQualityBand: item.snapshot.gearProfile?.qualityBand"),
            "recorded and unrecorded Return tiles must retain frozen instance quality")
        XCTAssertTrue(source.contains(
            "GearPresentationCopy.itemGridQuality(instanceBand: gearQualityBand"),
            "unrecorded Return must not append catalogue rarity over instance quality")
    }

    func testFrozenRoughGearOverridesSuperiorCatalogueAcrossGearAndReturnSurfaces() throws {
        var superiorCatalogueInstance = ItemStack(id: .init(rawValue: 8_801),
                                                  catalogID: "silvered_helm")
        superiorCatalogueInstance.gearProfile?.qualityBand = .rough
        XCTAssertEqual(ContentCatalog.shared.item("silvered_helm")?
            .gearCatalogueDisposition?.foundReceipt?.qualityBand, .superior)
        XCTAssertEqual(GearPresentationCopy.instanceQuality(superiorCatalogueInstance), "Rough")
        XCTAssertEqual(GearPresentationCopy.itemGridQuality(
            instanceBand: superiorCatalogueInstance.gearProfile?.qualityBand,
            catalogueID: superiorCatalogueInstance.catalogID,
            fallbackRarity: .mythic), "Rough")

        let frozenReturn = RunExitSummary.ReceiptLine.Item(
            lineID: "rough-silvered", instanceID: superiorCatalogueInstance.id,
            snapshot: superiorCatalogueInstance, quantity: 1,
            fallbackName: superiorCatalogueInstance.displayName,
            fallbackIcon: superiorCatalogueInstance.icon)
        XCTAssertEqual(frozenReturn.snapshot.gearProfile?.qualityBand, .rough,
                       "both recorded and unrecorded Return paths consume this frozen snapshot")
        XCTAssertFalse(frozenReturn.fallbackName.contains("Superior"))
    }

    func testRunExitRecapRoutesEveryMaterialKindToExistingPixelIdentity() throws {
        XCTAssertEqual(MaterialFamilyID.allCases.count, 16)
        XCTAssertEqual(Set(MaterialFamilyID.allCases.map(\.rawValue)).count, 16)

        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf: root.appending(path: "Sources/App/RootView.swift"),
                                encoding: .utf8)
        let materialCase = try XCTUnwrap(
            source.range(of: "case .materialSample(let material):")
        )
        let legacyCase = try XCTUnwrap(
            source.range(of: "case .legacy(let legacy):", range: materialCase.upperBound..<source.endIndex)
        )
        let materialRoute = String(source[materialCase.lowerBound..<legacyCase.lowerBound])

        XCTAssertTrue(materialRoute.contains("ItemIconTile(icon: material.fallbackIcon"))
        XCTAssertTrue(materialRoute.contains("materialKind: material.sample.kind"))
        XCTAssertFalse(materialRoute.contains("MaterialFamilyID."),
                       "the recap must route the frozen kind, not special-case a subset")
    }

    func testMaterialReceiptFreezesEverySampleAsItsOwnStableLine() throws {
        let store = fundedStore()
        XCTAssertTrue(store.bindAndDepart())
        let pale = CraftMaterialUnitV1(kind: .hide, properties: .init(insulation: 31),
                                  grade: 42, source: "pale browser", qualifier: "pale")
        let shaggy = CraftMaterialUnitV1(kind: .hide, properties: .init(insulation: 67),
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
        let first = CraftMaterialUnitV1(kind: .hide, properties: .init(insulation: 31),
                                   grade: 42, source: "first")
        let second = CraftMaterialUnitV1(kind: .hide, properties: .init(insulation: 67),
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
        let pale = CraftMaterialUnitV1(kind: .hide, properties: .init(insulation: 31),
                                  grade: 42, source: "pale")
        let shaggy = CraftMaterialUnitV1(kind: .hide, properties: .init(insulation: 67),
                                    grade: 81, source: "shaggy")
        let materials = ItemStack(id: InstanceID(rawValue: 902), catalogID: Items.material,
                                  materials: [pale, shaggy])
        let inventory = Inventory(slots: 8, stacks: [gear, materials])
        let partition = inventory.partitionedForFailure(fraction: 0.5, outcomeID: 61)
        let all = partition.kept.stacks + partition.lost.stacks
        XCTAssertEqual(all.reduce(0) { $0 + $1.count }, 3)
        XCTAssertEqual(all.flatMap { $0.materials }.sorted {
            $0.qualityBand.rawValue < $1.qualityBand.rawValue
        }, [pale, shaggy])
        XCTAssertEqual(all.first { $0.catalogID == gear.catalogID }?.upgradeLevel, 2)
        XCTAssertEqual(partition.kept.stacks.reduce(0) { $0 + $1.count }, 2)
    }

    func testDecision207ProtectedMaterialsAreComplementaryExactSamples() {
        let samples = [
            CraftMaterialUnitV1(kind: .hide, properties: .init(insulation: 11),
                           grade: 10, source: "first"),
            CraftMaterialUnitV1(kind: .hide, properties: .init(insulation: 22),
                           grade: 20, source: "second"),
            CraftMaterialUnitV1(kind: .hide, properties: .init(insulation: 33),
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
            CraftMaterialUnitV1(kind: .hide, properties: .init(hardness: 13, insulation: 19),
                           grade: 21, source: "alpha", qualifier: "ashen"),
            CraftMaterialUnitV1(kind: .hide, properties: .init(density: 29, flexibility: 31),
                           grade: 37, source: "beta", qualifier: "shaggy"),
            CraftMaterialUnitV1(kind: .hide, properties: .init(lustre: 41, reactivity: 43),
                           grade: 47, source: "gamma", qualifier: "pale"),
            CraftMaterialUnitV1(kind: .hide, properties: .init(insulation: 53),
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
        let samplesBySource: (Inventory) -> [CraftMaterialUnitV1] = {
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
        let recovered = banked.recoveredLines.compactMap { line -> CraftMaterialUnitV1? in
            guard case .materialSample(let material) = line else { return nil }
            return material.sample
        }.sorted { $0.source < $1.source }
        let lost = banked.lostLines.compactMap { line -> CraftMaterialUnitV1? in
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
