import SwiftUI
import UIKit
import XCTest
@testable import Bookbinder

@MainActor
final class MakerStationPresentationTests: XCTestCase {
#if DEBUG
    private enum P3Screen {
        case trading(String)
        case tradingListing(P3TradingListingDebugHost.Mode)
        case tradingMaterial(TradingPostCommitResult?)
        case recycler
        case recyclerPreview(RecyclerPreview, RecyclerCommitResult?)
        case apothecary(ItemID?, CraftMaterialUnitID?, String?)
    }

    private struct P3Mount {
        let window: UIWindow
        let controller: UIHostingController<AnyView>
        let safe: UIEdgeInsets
        let image: UIImage
        let frozen: Data
    }

    private func p3Store(populated: Bool = true, recipes: Set<ItemID>? = nil,
                         reagent: Int = 4, resin: Int = 8,
                         qualifyingMaterial: Bool = true) -> GameStore {
        let store = GameStore(io: .temporary(name: "p3-safe-space-\(UUID().uuidString)"))
        store.mutate("fixture: p3 station presentation") { state in
            for lesson in TutorialLessonID.allCases {
                state.tutorial.complete(lesson, fact: "p3_safe_space")
            }
            state.base.essence = 999
            state.base.goldCoins = 999
            state.base.stations[Stations.apothecary] = StationState(isUnlocked: true, tier: 0)
            state.base.tradingPost.stock = []
            state.base.tradingPost.essenceBundlesRemaining = 0
            state.base.tradingPost.expeditionOutcomeID = nil
            state.base.knownConsumableRecipes = recipes ?? (populated
                ? Set(ConsumableCraftingRules.recipes.map(\.output)) : [])
            guard populated else {
                state.base.essence = 0
                state.base.goldCoins = 0
                return
            }
            state.base.tradingPost.expeditionOutcomeID = 77
            state.base.tradingPost.stock = [
                TradingPostStockLine(id: 70, kind: .resource("clay"),
                                     remainingQuantity: 3, unitPrice: 2)
            ]
            state.base.resources.add(7, of: "clay")
            state.base.resources.add(reagent, of: "reagent")
            state.base.resources.add(resin, of: "resin")
            let stored = ItemStack(id: InstanceID(rawValue: 700), catalogID: "blade_chipped")
            let waiting = ItemStack(id: InstanceID(rawValue: 701), catalogID: "blade_chipped")
            state.base.inventory.stacks = [stored]
            state.base.spillover = [waiting]
            if qualifyingMaterial { state.base.worldMaterialReserve.add(.init(
                id: .init(rawValue: "p3-hide"),
                sample: CraftMaterialUnitV1(kind: .hide,
                    properties: MaterialProperties(hardness: 55, density: 50,
                                                   insulation: 70, flexibility: 65,
                                                   lustre: 20, reactivity: 70),
                    grade: 70,
                    source: "A deliberately long exact source record retained for mounted metadata reachability",
                    qualifier: "kept")
            )) }
        }
        store.discoverConsumableRecipes()
        return store
    }

    @MainActor
    private func p3Mount(_ screen: P3Screen, scheme: ColorScheme,
                         store: GameStore) throws -> P3Mount {
        P3SafeSpaceMeasurement.reset(); P3SafeSpaceMeasurement.isArmed = true
        let content: AnyView = switch screen {
        case .trading(let tab): AnyView(TradingPostView(debugTab: tab).environmentObject(store))
        case .tradingListing(let mode): AnyView(P3TradingListingDebugHost(mode: mode).environmentObject(store))
        case .tradingMaterial(let failure):
            AnyView(P3TradingMaterialDebugHost(failure: failure).environmentObject(store))
        case .recycler: AnyView(RecyclerView().environmentObject(store))
        case .recyclerPreview(let preview, let failure):
            AnyView(P3RecyclerPreviewDebugHost(preview: preview, failure: failure).environmentObject(store))
        case .apothecary(let recipe, let unit, let failure):
            AnyView(ApothecaryView(debugSelectedRecipeID: recipe,
                                   debugSelectedScentMaskUnitID: unit,
                                   debugFailure: failure).environmentObject(store))
        }
        let controller = UIHostingController(rootView: AnyView(
            NavigationStack { content }
                .environment(\.colorScheme, scheme)
                .environment(\.dynamicTypeSize, .large)
        ))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 368, height: 800))
        window.rootViewController = controller
        controller.additionalSafeAreaInsets = UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0)
        window.makeKeyAndVisible()
        controller.view.frame = window.bounds
        controller.view.setNeedsLayout(); controller.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.12))
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1; format.opaque = true
        let image = UIGraphicsImageRenderer(size: window.bounds.size, format: format).image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
        return P3Mount(window: window, controller: controller,
                       safe: controller.view.safeAreaInsets, image: image,
                       frozen: try SaveCodec.encode(store.state))
    }

    @MainActor private func p3Views(_ view: UIView) -> [UIView] {
        [view] + view.subviews.flatMap(p3Views)
    }

    @MainActor private func p3RootScroll(_ mount: P3Mount) throws -> UIScrollView {
        try XCTUnwrap(p3Views(mount.controller.view).compactMap { $0 as? UIScrollView }
            .max(by: { $0.bounds.height < $1.bounds.height }))
    }

    @MainActor private func p3ScrollToEnd(_ mount: P3Mount) throws {
        let scroll = try p3RootScroll(mount)
        let bottom = max(-scroll.adjustedContentInset.top,
                         scroll.contentSize.height - scroll.bounds.height + scroll.adjustedContentInset.bottom)
        scroll.setContentOffset(CGPoint(x: scroll.contentOffset.x, y: bottom), animated: false)
        scroll.layoutIfNeeded(); RunLoop.main.run(until: Date().addingTimeInterval(0.05))
    }

    @MainActor private func p3VisibleScrollRect(_ mount: P3Mount) throws -> CGRect {
        let scroll = try p3RootScroll(mount)
        let frame = scroll.convert(scroll.bounds, to: mount.window)
        return CGRect(x: frame.minX,
                      y: frame.minY + scroll.adjustedContentInset.top,
                      width: frame.width,
                      height: frame.height - scroll.adjustedContentInset.top
                          - scroll.adjustedContentInset.bottom)
    }

    private func p3Frame(_ key: String, file: StaticString = #filePath,
                         line: UInt = #line) throws -> CGRect {
        try XCTUnwrap(P3SafeSpaceMeasurement.frames[key], "missing real probe \(key)",
                      file: file, line: line)
    }

    private func p3AssertFinal(_ key: String, inside viewport: CGRect,
                               identity: String? = nil,
                               file: StaticString = #filePath, line: UInt = #line) throws {
        let frame = try p3Frame(key, file: file, line: line)
        XCTAssertGreaterThanOrEqual(frame.minY, viewport.minY - 0.75, file: file, line: line)
        XCTAssertLessThanOrEqual(frame.maxY, viewport.maxY + 0.75, file: file, line: line)
        if let identity {
            XCTAssertEqual(P3SafeSpaceMeasurement.identities[key], identity, file: file, line: line)
        }
    }

    private func p3Preview(location: TradingPostItemLocation = .stored,
                           route: RecyclerRecoveryRoute = .constructionReceipt,
                           resources: ResourcePool = ResourcePool(),
                           samples: [CraftMaterialUnitV1] = [], id: UInt64 = 800) -> RecyclerPreview {
        let stack = ItemStack(id: InstanceID(rawValue: id), catalogID: "blade_chipped")
        return RecyclerPreview(revision: 0, location: location, stackID: stack.id,
                               snapshot: stack, serviceTier: 1, route: route,
                               selectedReceiptIndices: samples.indices.map { $0 },
                               recoveryCapacity: samples.count, returnedSamples: samples,
                               returnedResources: resources)
    }

    private func p3RGBA(_ image: UIImage, x: Int, y: Int) throws -> [UInt8] {
        let cg = try XCTUnwrap(image.cgImage)
        let data = try XCTUnwrap(cg.dataProvider?.data)
        let bytes = CFDataGetBytePtr(data)!
        let offset = y * cg.bytesPerRow + x * 4
        return Array(UnsafeBufferPointer(start: bytes + offset, count: 4))
    }

    @MainActor private func p3AssertRootGeometry(_ mount: P3Mount) throws {
        XCTAssertGreaterThanOrEqual(mount.safe.top, 59)
        XCTAssertGreaterThanOrEqual(mount.safe.bottom, 34)
        XCTAssertNotEqual(try p3RGBA(mount.image, x: 184, y: 10), [0, 0, 0, 255])
        XCTAssertNotEqual(try p3RGBA(mount.image, x: 184, y: 785), [0, 0, 0, 255])
        let scroll = try p3RootScroll(mount)
        let frame = try p3VisibleScrollRect(mount)
        XCTAssertGreaterThan(frame.height, 500)
        XCTAssertGreaterThanOrEqual(frame.minY, mount.safe.top - 0.75)
        XCTAssertLessThanOrEqual(frame.maxY, 800 - mount.safe.bottom + 0.75)
        for control in p3Views(mount.controller.view).compactMap({ $0 as? UIControl })
        where !control.isHidden && control.alpha > 0.01 {
            let controlFrame = control.convert(control.bounds, to: mount.window)
            XCTAssertGreaterThanOrEqual(controlFrame.minY, mount.safe.top - 0.75)
            XCTAssertLessThanOrEqual(controlFrame.maxY, 800 - mount.safe.bottom + 0.75)
        }
    }

    private func p3Source(_ name: String) throws -> String {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        return try String(contentsOf: root.appending(path: "Sources/Screens/\(name)"), encoding: .utf8)
    }

    func testP3_01SemanticBackdropOnlyFillsUnsafeRegionsInLightAndDark() throws {
        for scheme in [ColorScheme.light, .dark] {
            for (name, screen) in [("trading", P3Screen.trading("buy")),
                                   ("recycler", .recycler),
                                   ("apothecary", .apothecary("salve_lesser", nil, nil))] {
                let store = p3Store(); let mount = try p3Mount(screen, scheme: scheme, store: store)
                try p3AssertRootGeometry(mount)
                let attachment = XCTAttachment(image: mount.image)
                attachment.name = "p3-\(name)-\(scheme)-368x800"
                attachment.lifetime = .keepAlways; add(attachment)
                XCTAssertEqual(try SaveCodec.encode(store.state), mount.frozen)
                mount.window.isHidden = true
            }
        }
    }

    func testP3_02EachRootScrollOwnsItsAllocatedSafeRemainder() throws {
        for screen in [P3Screen.trading("buy"), .recycler,
                       .apothecary("salve_lesser", nil, nil)] {
            let mount = try p3Mount(screen, scheme: .light, store: p3Store())
            let scroll = try p3RootScroll(mount)
            let frame = try p3VisibleScrollRect(mount)
            if let action = P3SafeSpaceMeasurement.frames["apothecary.main.action"] {
                XCTAssertEqual(frame.maxY, action.minY, accuracy: 0.75)
            } else {
                XCTAssertEqual(frame.maxY, 800 - mount.safe.bottom, accuracy: 0.75)
            }
            mount.window.isHidden = true
        }
    }

    func testP3_03TradingMainPreservesBuySellAndEmptyOwnership() throws {
        for scheme in [ColorScheme.light, .dark] {
            for tab in ["buy", "sell"] {
                let mount = try p3Mount(.trading(tab), scheme: scheme, store: p3Store())
                let scroll = try p3VisibleScrollRect(mount)
                let firstID = try XCTUnwrap(P3SafeSpaceMeasurement.identities["trading.main.first"])
                try p3AssertFinal("trading.main.first", inside: scroll, identity: firstID)
                try p3ScrollToEnd(mount)
                try p3AssertFinal("trading.main.last", inside: scroll)
                XCTAssertFalse(firstID.isEmpty)
                mount.window.isHidden = true
            }
            for tab in ["buy", "sell"] {
                let mount = try p3Mount(.trading(tab), scheme: scheme,
                                        store: p3Store(populated: false, recipes: []))
                try p3AssertFinal("trading.main.empty", inside: try p3VisibleScrollRect(mount),
                                  identity: tab)
                mount.window.isHidden = true
            }
        }
    }

    func testP3_04TradingListingListRemainsAboveItsFixedActionRail() throws {
        for mode in [P3TradingListingDebugHost.Mode.affordable, .unaffordable, .unavailable,
                     .stored, .waiting, .quantity, .stale] {
            let mount = try p3Mount(.tradingListing(mode), scheme: .light, store: p3Store())
            try p3ScrollToEnd(mount)
            let list = try p3VisibleScrollRect(mount)
            let action = try p3Frame("trading.listing.action")
            XCTAssertLessThanOrEqual(list.maxY, action.minY + 0.75)
            try p3AssertFinal("trading.listing.final",
                              inside: CGRect(x: list.minX, y: list.minY,
                                             width: list.width, height: action.minY - list.minY))
            mount.window.isHidden = true
        }
    }

    func testP3_05TradingMaterialDetailRetainsExactUnitAndFailureOwnership() throws {
        for failure in [Optional<TradingPostCommitResult>.none, .some(.stale), .some(.invalid)] {
            let mount = try p3Mount(.tradingMaterial(failure), scheme: .dark, store: p3Store())
            try p3ScrollToEnd(mount)
            let list = try p3VisibleScrollRect(mount)
            let action = try p3Frame("trading.material.action")
            XCTAssertLessThanOrEqual(list.maxY, action.minY + 0.75)
            try p3AssertFinal("trading.material.final", inside: list)
            mount.window.isHidden = true
        }
    }

    func testP3_06RecyclerMainRetainsEligibleAndProtectedHoldingsStates() throws {
        let empty = try p3Mount(.recycler, scheme: .light,
                                store: p3Store(populated: false, recipes: []))
        try p3AssertFinal("recycler.main.empty", inside: try p3VisibleScrollRect(empty),
                          identity: "no-eligible-gear")
        empty.window.isHidden = true
        let store = p3Store()
        store.mutate("fixture: protected recycler") { state in
            func piece(_ id: UInt64, _ catalog: ItemID = "blade_chipped") -> ItemStack {
                ItemStack(id: InstanceID(rawValue: id), catalogID: catalog)
            }
            var stacked = piece(790); stacked.count = 2
            var unidentified = piece(791); unidentified.identified = false
            var favorite = piece(792); favorite.isFavorite = true
            var locked = piece(793); locked.isLocked = true
            var unique = piece(794); unique.gearProfile?.authoredUniqueRuleID = "p3-unique"
            var narrative = piece(795); narrative.gearProfile?.authoredUniqueRuleID = "p3-narrative"
            var legacy = piece(796); legacy.gearProfile?.legacyPowerCredit = 1
            var protected = [stacked, unidentified, favorite, locked,
                             piece(797, Items.conduitFixture), piece(798, "salve_lesser"),
                             unique, narrative, legacy]
            if let apex = ContentCatalog.shared.items.first(where: { $0.gear?.breaks != nil }) {
                protected.append(piece(799, apex.id))
            }
            if let unprofiled = RecyclerRules.unprofiledOrdinaryGearIDs().first {
                protected.append(piece(806, unprofiled))
            }
            state.base.inventory.stacks.append(contentsOf: protected)
            state.base.binderEquipped[.weapon] = EquippedPiece(catalogID: "blade_chipped")
        }
        let populated = try p3Mount(.recycler, scheme: .dark, store: store)
        let recyclerScroll = try p3VisibleScrollRect(populated)
        let firstRecyclerID = try XCTUnwrap(P3SafeSpaceMeasurement.identities["recycler.main.first"])
        try p3AssertFinal("recycler.main.first", inside: recyclerScroll, identity: firstRecyclerID)
        try p3ScrollToEnd(populated)
        try p3AssertFinal("recycler.main.last", inside: recyclerScroll)
        XCTAssertNotNil(P3SafeSpaceMeasurement.frames["recycler.main.protected"])
        let renderedReasons = Set((P3SafeSpaceMeasurement.identities["recycler.main.protected"] ?? "")
            .split(separator: ",").map(String.init))
        let expectedReasons = Set(RecyclerRules.Ineligibility.allCases.map(\.rawValue))
        XCTAssertTrue(expectedReasons.isSubset(of: renderedReasons),
                      "missing protected groups: \(expectedReasons.subtracting(renderedReasons))")
        populated.window.isHidden = true
    }

    func testP3_07RecyclerPreviewListRemainsAboveDismantleActionRail() throws {
        var resources = ResourcePool(); resources.add(2, of: "ore")
        let material = CraftMaterialUnitV1(kind: .plate, properties: .init(hardness: 60),
                                      grade: 60, source: "recorded construction stock")
        let fixtures: [(RecyclerPreview, RecyclerCommitResult?)] = [
            (p3Preview(resources: resources), nil),
            (p3Preview(location: .overflow, route: .authoredSalvage(profileID: "forged_edge_v1"),
                       resources: resources, id: 801), nil),
            (p3Preview(samples: [material], id: 802), nil),
            (p3Preview(id: 803), nil),
            (p3Preview(id: 804), .stale),
            (p3Preview(id: 805), .invalid)
        ]
        for (preview, failure) in fixtures {
            let mount = try p3Mount(.recyclerPreview(preview, failure), scheme: .light,
                                    store: p3Store())
            try p3ScrollToEnd(mount)
            let list = try p3VisibleScrollRect(mount)
            let action = try p3Frame("recycler.preview.action")
            XCTAssertLessThanOrEqual(list.maxY, action.minY + 0.75)
            try p3AssertFinal("recycler.preview.final", inside: list)
            mount.window.isHidden = true
        }
    }

    func testP3_08ApothecaryEmptyOwnsFullSafeIntervalWithoutActionBarContent() throws {
        let store = p3Store(populated: false, recipes: [])
        store.discoverConsumableRecipes()
        XCTAssertTrue(store.state.base.knownConsumableRecipes.isEmpty)
        let mount = try p3Mount(.apothecary(nil, nil, nil), scheme: .light, store: store)
        try p3AssertFinal("apothecary.main.empty", inside: try p3VisibleScrollRect(mount),
                          identity: "no-known-recipes")
        XCTAssertNil(P3SafeSpaceMeasurement.frames["apothecary.main.action"])
        let scroll = try p3VisibleScrollRect(mount)
        XCTAssertEqual(scroll.maxY, 800 - mount.safe.bottom, accuracy: 0.75)
        mount.window.isHidden = true
    }

    func testP3_09ApothecarySelectedRecipeKeepsDetailAboveActionRail() throws {
        for (ready, failure) in [(true, Optional<String>.none),
                                 (false, nil),
                                 (true, "The required stock changed. Review the exact recipe and try again.")] {
            let store = p3Store(resin: ready ? 8 : 0,
                                qualifyingMaterial: ready)
            let expectedAction = ConsumableCraftingRules.shortfall(
                try XCTUnwrap(ConsumableCraftingRules.recipe("salve_lesser")), in: store.state
            ).joined(separator: " · ")
            let mount = try p3Mount(.apothecary("salve_lesser", nil, failure),
                                    scheme: .dark, store: store)
            try p3ScrollToEnd(mount)
            let scroll = try p3VisibleScrollRect(mount)
            let action = try p3Frame("apothecary.main.action")
            XCTAssertLessThanOrEqual(scroll.maxY, action.minY + 0.75)
            XCTAssertEqual(P3SafeSpaceMeasurement.identities["apothecary.main.action"],
                           ready ? "ready" : expectedAction)
            try p3AssertFinal("apothecary.main.final", inside: scroll,
                              identity: "salve_lesser")
            mount.window.isHidden = true
        }
    }

    func testP3_10ScentMaskSelectionAndRefusalTruthRemainUnchanged() throws {
        for (unit, reagent, expected) in [
            (Optional<CraftMaterialUnitID>.none, 4, "Choose one exact grade 25+ animal resource."),
            (Optional(.init(rawValue: "p3-hide")), 4, "This exact resource + 1 Reagent · 0 Essence"),
            (Optional(.init(rawValue: "p3-hide")), 0, "Needs 1 Reagent.")
        ] {
            let store = p3Store(reagent: reagent)
            XCTAssertEqual(store.state.base.resources[Resources.reagent], reagent)
            XCTAssertEqual(store.state.base.worldMaterialReserve.selections().first?.unitID.rawValue,
                           "p3-hide")
            let mount = try p3Mount(.apothecary(Items.scentMask, unit, nil),
                                    scheme: .light, store: store)
            try p3ScrollToEnd(mount)
            XCTAssertEqual(P3SafeSpaceMeasurement.identities["apothecary.main.action"], expected)
            try p3AssertFinal("apothecary.main.final",
                              inside: try p3VisibleScrollRect(mount),
                              identity: Items.scentMask.rawValue)
            mount.window.isHidden = true
        }
        let staleStore = p3Store()
        let stale = try p3Mount(.apothecary(Items.scentMask,
                                            .init(rawValue: "p3-hide"),
                                            "That exact animal resource or the Reagent is no longer available. Choose the resource again."),
                                  scheme: .light, store: staleStore)
        XCTAssertEqual(P3SafeSpaceMeasurement.identities["apothecary.main.action"],
                       "This exact resource + 1 Reagent · 0 Essence")
        XCTAssertEqual(P3SafeSpaceMeasurement.identities["apothecary.main.failure"],
                       "That exact animal resource or the Reagent is no longer available. Choose the resource again.")
        stale.window.isHidden = true
    }

    func testP3_11MountedSafeSpaceIsSaveCodecAndTurnInert() throws {
        let fixtures: [(P3Screen, GameStore)] = [
            (.trading("buy"), p3Store()), (.trading("sell"), p3Store()),
            (.recycler, p3Store()),
            (.apothecary(nil, nil, nil), p3Store(populated: false, recipes: [])),
            (.apothecary("salve_lesser", nil, nil), p3Store())
        ]
        for (screen, store) in fixtures {
            store.discoverConsumableRecipes()
            let frozen = try SaveCodec.encode(store.state)
            let turn = store.state.worlds.activeRun?.turnsTaken
            let mount = try p3Mount(screen, scheme: .dark, store: store)
            _ = try p3RootScroll(mount)
            XCTAssertEqual(try SaveCodec.encode(store.state), frozen)
            XCTAssertEqual(store.state.worlds.activeRun?.turnsTaken, turn)
            mount.window.isHidden = true
        }
    }

    func testP3_12ExactFourFileBoundaryAndNoLayoutSubstituteContract() throws {
        for file in ["TradingPostView.swift", "RecyclerView.swift", "ApothecaryView.swift"] {
            let source = try p3Source(file)
            XCTAssertTrue(source.contains("Color(.systemGroupedBackground).ignoresSafeArea()"))
            XCTAssertFalse(source.contains("frame(height: 430"))
        }
    }
#endif
    func testGearPresentationCopyUsesNaturalStockCountsAndOlderSaveCopy() {
        XCTAssertEqual(GearPresentationCopy.piecesOfStock(0), "0 pieces of stock")
        XCTAssertEqual(GearPresentationCopy.piecesOfStock(1), "1 piece of stock")
        XCTAssertEqual(GearPresentationCopy.piecesOfStock(4), "4 pieces of stock")
        XCTAssertEqual(GearPresentationCopy.moreQualifyingPiecesOfStock(1),
                       "1 more qualifying piece of stock")
        XCTAssertEqual(GearPresentationCopy.moreQualifyingPiecesOfStock(3),
                       "3 more qualifying pieces of stock")
        XCTAssertEqual(GearPresentationCopy.olderSaveArtUnavailable,
                       "From an older save. Detailed item art is unavailable.")
        XCTAssertEqual(GearPresentationCopy.physicalProtection(offset: 0), "full physical protection")
        XCTAssertEqual(GearPresentationCopy.physicalProtection(offset: -0.5), "0.5 less physical protection")
        XCTAssertEqual(GearPresentationCopy.physicalProtection(offset: -1), "1 less physical protection")
        XCTAssertEqual(GearPresentationCopy.physicalProtection(offset: 0.5), "0.5 more physical protection")
        XCTAssertEqual(GearPresentationCopy.rarity(.common), "Common")
        XCTAssertEqual(GearPresentationCopy.rarity(.uncommon), "Uncommon")
        XCTAssertEqual(GearPresentationCopy.rarity(.rare), "Rare")
        XCTAssertEqual(GearPresentationCopy.rarity(.mythic), "Mythic")
        XCTAssertEqual(GearPresentationCopy.damage(.rend), "Rend")
        XCTAssertEqual(GearPresentationCopy.damage(.pierce), "Pierce")
        XCTAssertEqual(GearPresentationCopy.reach(.close), "Close")
        XCTAssertEqual(GearPresentationCopy.reach(.mid), "Mid")
        XCTAssertEqual(GearPresentationCopy.reach(.far), "Far")
    }

    func testStepFivePlayerCopyAvoidsImplementationTermsOnScopedSurfaces() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let paths = [
            "Sources/App/RootView.swift", "Sources/Screens/BlacksmithView.swift",
            "Sources/Screens/RecyclerView.swift", "Sources/Screens/TradingPostView.swift",
            "Sources/Screens/AuthoredTextAtlasView.swift", "Sources/Screens/WorldView.swift",
            "Sources/Rules/RecyclerRules.swift"
        ]
        let visibleStringPattern = try NSRegularExpression(pattern: #"\"(?:[^\"\\]|\\.)*\""#)
        let strings = try paths.flatMap { path -> [String] in
            let source = try String(contentsOf: root.appending(path: path), encoding: .utf8)
            let range = NSRange(source.startIndex..., in: source)
            return visibleStringPattern.matches(in: source, range: range).compactMap {
                Range($0.range, in: source).map { String(source[$0]).lowercased() }
            }
        }.joined(separator: "\n")
        for retired in ["receipt detail", "legacy receipt", "legacy masterwork",
                        "construction profile", "authored salvage profile", "provenance",
                        "workshop pattern", "a rune"] {
            XCTAssertFalse(strings.contains(retired), "retired player copy: \(retired)")
        }
        let blacksmith = try String(contentsOf: root.appending(path: "Sources/Screens/BlacksmithView.swift"), encoding: .utf8)
        let blacksmithStrings = visibleStringPattern.matches(
            in: blacksmith, range: NSRange(blacksmith.startIndex..., in: blacksmith)
        ).compactMap { Range($0.range, in: blacksmith).map { String(blacksmith[$0]) } }
        XCTAssertFalse(blacksmithStrings.contains {
            let playerCopy = $0.replacingOccurrences(of: #"\\\([^)]*\)"#, with: "", options: .regularExpression)
            return playerCopy.range(of: #"\bsamples?\b"#, options: .regularExpression) != nil
        })
    }

    func testReturnDetailsLeadWithCanonicalNameAndHideRawKeys() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf: root.appending(path: "Sources/App/RootView.swift"), encoding: .utf8)
        let start = try XCTUnwrap(source.range(of: "private func receiptDetail("))
        let end = try XCTUnwrap(source.range(of: "private func receiptDetailOverlay("))
        let detail = String(source[start.lowerBound..<end.lowerBound])
        XCTAssertTrue(detail.contains("Text(line.compatibilityGain.name)"))
        XCTAssertTrue(detail.contains("GearPresentationCopy.olderSaveArtUnavailable"))
        XCTAssertFalse(detail.contains("resource.id.rawValue"))
        XCTAssertFalse(detail.contains("item.snapshot.catalogID.rawValue"))
        XCTAssertFalse(detail.contains("LabeledContent(\"Identity\""))
        XCTAssertTrue(source.contains("Text(\"DETAILS\")"))
    }

    func testScriptoriumExposesOnlyRealHandsInksRunebookCapabilitiesAndFrozenTransactions() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf: root.appending(path: "Sources/Screens/StationViews.swift"),
                                encoding: .utf8)

        XCTAssertTrue(source.contains("case hands = \"Hands\""))
        XCTAssertTrue(source.contains("case inks = \"Inks\""))
        XCTAssertTrue(source.contains("case runebook = \"Runebook\""))
        XCTAssertTrue(source.contains("completedResearch.contains(\"pen_ink_mixing\")"))
        XCTAssertTrue(source.contains("completedResearch.contains(\"pen_compounds\")"))
        XCTAssertTrue(source.contains("previewCompoundFormalization(fingerprint:"))
        XCTAssertTrue(source.contains("store.formalizeCompound(quote)"))
        XCTAssertTrue(source.contains("store.previewCompoundRename(record.id"))
        XCTAssertTrue(source.contains("store.renameCompound(quote)"))
        XCTAssertTrue(source.contains("store.previewCompoundDeletion(record.id)"))
        XCTAssertTrue(source.contains("store.deleteCompound(quote)"))
        XCTAssertTrue(source.contains("Array(repeating: GridItem(.flexible(), spacing: 6), count: 3)"))
        XCTAssertFalse(source.contains("selectedAtoms"), "Runebook must formalize proven receipts, not arbitrary atoms")
    }

    func testCompoundRunebookPresentationDisclosesReadingFootprintAndExactRefusal() throws {
        let source = try XCTUnwrap(ContentCatalog.shared.pressureSources.first).id
        let atom = CompoundSemanticAtom(Sigil(id: .init(rawValue: 1), source: source,
                                               target: "illumination"))
        let receipt = ProvenStatementReceipt(
            fingerprint: PageRules.statementFingerprint(target: "illumination", atoms: [atom]),
            target: "illumination", atoms: [atom],
            vocabulary: [.target("illumination"), .source(source)],
            vocabularySchemaVersion: ProvenStatementReceipt.currentVocabularySchemaVersion,
            firstBoundRunIndex: 1)

        XCTAssertTrue(CompoundRunebookPresentation.reading(receipt).contains("Illumination"))
        XCTAssertTrue(CompoundRunebookPresentation.reading(receipt).contains("Moderate"))
        XCTAssertEqual(CompoundRunebookPresentation.sigilCount(receipt), "2 Sigils in this Compound")
        XCTAssertTrue(CompoundRunebookPresentation.accessibilityLabel(receipt).hasPrefix(
            "2 Sigils in this Compound. Illumination:"))
        XCTAssertTrue(CompoundRunebookPresentation.footprint(receipt, hand: .crude)
            .contains("spelled out"))
        XCTAssertEqual(CompoundRunebookPresentation.message(.ineligible(.nestedCompound)),
                       "A Compound cannot contain another Compound.")
        XCTAssertEqual(CompoundRunebookPresentation.message(.insufficientResources),
                       "Formalization needs more Essence or pulp.")
    }

    func testCompoundSigilCountUsesFrozenVocabularyNotSemanticAtomMultiplicity() throws {
        let source = try XCTUnwrap(ContentCatalog.shared.pressureSources.first).id
        var atom = CompoundSemanticAtom(Sigil(id: .init(rawValue: 1), source: source,
                                               target: "illumination"))
        func receipt(_ vocabulary: [LexemeIdentity]) -> ProvenStatementReceipt {
            ProvenStatementReceipt(fingerprint: "fixture", target: "illumination", atoms: [atom],
                                   vocabulary: vocabulary,
                                   vocabularySchemaVersion: ProvenStatementReceipt.currentVocabularySchemaVersion,
                                   firstBoundRunIndex: 1)
        }
        XCTAssertEqual(CompoundRunebookPresentation.sigilCount(receipt([])), "0 Sigils in this Compound")
        XCTAssertEqual(CompoundRunebookPresentation.sigilCount(receipt([.target("illumination")])),
                       "1 Sigil in this Compound")
        let basic = receipt([.target("illumination"), .source(source)])
        XCTAssertEqual(atom.count, 1)
        XCTAssertEqual(CompoundRunebookPresentation.sigilCount(basic), "2 Sigils in this Compound")
        XCTAssertEqual(CompoundRunebookPresentation.sigilCount(
            receipt([.target("illumination"), .source(source), .qualifier("great")])),
            "3 Sigils in this Compound")
        atom.count = 17
        let multiplied = receipt([.target("illumination"), .source(source)])
        XCTAssertNotEqual(multiplied.atoms, basic.atoms)
        XCTAssertEqual(CompoundRunebookPresentation.sigilCount(multiplied),
                       CompoundRunebookPresentation.sigilCount(basic))
    }

    func testCompoundEligibilityIssuesHaveExactPlayerCopyWithoutChangingRawCompatibility() {
        let expected: [(PageRules.CompoundEligibilityIssue, String)] = [
            (.incomplete, "A Compound needs one complete Subject-and-Focus statement."),
            (.multipleTargets, "A Compound can have exactly one Subject."),
            (.tooFewAtoms, "A Compound needs at least two Sigils."),
            (.tooManyAtoms, "A Compound can contain at most five Sigils."),
            (.nestedCompound, "A Compound cannot contain another Compound."),
            (.unknownAtom, "Every Sigil must be known before this statement can be formalized.")
        ]
        for (issue, copy) in expected {
            XCTAssertEqual(CompoundRunebookPresentation.message(.ineligible(issue)), copy)
            XCTAssertFalse(issue.rawValue.isEmpty)
        }
        XCTAssertEqual(PageRules.CompoundEligibilityIssue.tooFewAtoms.rawValue,
                       "A compound needs at least two atomic Sigils.")
    }

    func testCompoundAssemblyVisibleStringsDoNotExposeAtomTerminologyAndCountCanWrap() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf: root.appending(path: "Sources/Screens/StationViews.swift"), encoding: .utf8)
        let pattern = try NSRegularExpression(pattern: #"\"(?:[^\"\\]|\\.)*\""#)
        let strings = pattern.matches(in: source, range: NSRange(source.startIndex..., in: source))
            .compactMap { Range($0.range, in: source).map { String(source[$0]) } }
        XCTAssertFalse(strings.contains { value in
            let playerCopy = value.replacingOccurrences(of: #"\\\([^)]*\)"#, with: "", options: .regularExpression)
            return playerCopy.range(of: #"\batom(?:ic|s)?\b"#, options: [.regularExpression, .caseInsensitive]) != nil
        })
        XCTAssertTrue(source.contains("CompoundRunebookPresentation.sigilCount(receipt)"))
        XCTAssertTrue(source.contains(".fixedSize(horizontal: false, vertical: true)"))
        XCTAssertTrue(source.contains(".accessibilityLabel(CompoundRunebookPresentation.accessibilityLabel(receipt))"))
        XCTAssertFalse(source.contains("Text(\"\\(receipt.atoms.count) atoms\")"))
    }

    func testStationResourceNamesUseCatalogueAndNeverExposeUnknownIDs() throws {
        let clay = try XCTUnwrap(ContentCatalog.shared.resource("clay"))
        XCTAssertEqual(StationCataloguePresentation.resourceName(clay.id), clay.name)
        let unknown: ResourceID = "internal_missing_station_resource"
        let fallback = StationCataloguePresentation.resourceName(unknown)
        XCTAssertEqual(fallback, "Unknown resource")
        XCTAssertFalse(fallback.contains(unknown.rawValue))
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf: root.appending(path: "Sources/Screens/StationViews.swift"), encoding: .utf8)
        XCTAssertFalse(source.contains("option.resource.rawValue.capitalisedSentence"))
        XCTAssertFalse(source.contains("resource(resource)?.name ?? resource.rawValue"))
        XCTAssertFalse(source.contains("definition?.name ?? entry.id.rawValue"))
        XCTAssertTrue(source.contains("Text(\"From \\(sample.source)\")"))
        XCTAssertFalse(source.contains("Text(\"off a \\(sample.source)\")"))
    }

    func testConstructionRowsDescribeRequirementsRatherThanClaimingASelection() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf: root.appending(path: "Sources/Screens/BlacksmithView.swift"), encoding: .utf8)
        XCTAssertTrue(source.contains("GearPresentationCopy.piecesOfStock(recipe.requirements.count)"))
        XCTAssertFalse(source.contains("\\(recipe.requirements.count) selected samples"))
    }

    func testReforgeUsesTheSamePowerTermAsEquipmentDetails() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf: root.appending(path: "Sources/Screens/BlacksmithView.swift"), encoding: .utf8)
        XCTAssertTrue(source.contains("chip(\"+0.2 power\", .green)"))
        XCTAssertTrue(source.contains("String(format: \"power %.1f\", target.effectivePower + 0.2)"))
        XCTAssertTrue(source.contains("+0.2 power toward final"))
        XCTAssertFalse(source.contains("+0.2 rating"))
        XCTAssertFalse(source.contains("gear rating toward final"))
    }

    func testArmouryUsesCompactProfileAndExactSampleGrids() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(
            contentsOf: root.appending(path: "Sources/Screens/BlacksmithView.swift"),
            encoding: .utf8
        )
        let armoury = try XCTUnwrap(source.range(of: "private struct ArmouryTargetSheet"))
        let picker = try XCTUnwrap(source.range(of: "private struct SamplePicker"))
        let armourySource = String(source[armoury.lowerBound..<picker.lowerBound])
        let pickerSource = String(source[picker.lowerBound...])

        XCTAssertTrue(armourySource.contains("LazyVGrid(columns: profileColumns"))
        XCTAssertTrue(armourySource.contains("count: 3"))
        XCTAssertFalse(armourySource.contains("Section(\"Rebuild as\")"))
        XCTAssertTrue(pickerSource.contains("SixAcrossItemGrid(data: available"))
        XCTAssertTrue(pickerSource.contains("AnchoredItemDetailButton"))
        XCTAssertTrue(pickerSource.contains("ArmourySampleDetail"))
    }

    func testArmouryProtectivePiecesUseTheSharedPhysicalItemTray() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(
            contentsOf: root.appending(path: "Sources/Screens/BlacksmithView.swift"),
            encoding: .utf8
        )
        let armouryStart = try XCTUnwrap(source.range(of: "struct ArmouryView"))
        let armouryEnd = try XCTUnwrap(source.range(of: "struct WeaponsmithView"))
        let armoury = String(source[armouryStart.lowerBound..<armouryEnd.lowerBound])

        XCTAssertTrue(armoury.contains("SixAcrossItemGrid(data: targets, id: \\.id)"))
        XCTAssertTrue(armoury.contains("catalogueID: target.catalogID"))
        XCTAssertTrue(armoury.contains("identified: targetIsIdentified(target)"))
        XCTAssertTrue(armoury.contains("location: targetLocation(target)"))
        XCTAssertTrue(armoury.contains("case .stored: .stored"))
        XCTAssertTrue(armoury.contains("case .worn: .worn"))
        XCTAssertTrue(armoury.contains("case .stored(let stack): stack.identified"))
        XCTAssertTrue(armoury.contains(".presentationDetents([.medium, .large])"))
        XCTAssertTrue(armoury.contains(".presentationDragIndicator(.visible)"))
        XCTAssertTrue(armoury.contains("if targets.isEmpty"))
        XCTAssertTrue(armoury.contains("No eligible protective pieces are stored or worn."))
        XCTAssertTrue(armoury.contains("No eligible ordinary protective pieces. Include gear from older saves to see compatible pieces."))
        XCTAssertFalse(armoury.contains("Image(systemName: \"chevron.right\")"))
    }
    func testPlayerFacingReforgeLabelsUseRulesOwnedMaximum() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let paths = [
            "Sources/Screens/GearView.swift",
            "Sources/Screens/TradingPostView.swift",
            "Sources/Screens/StationViews.swift",
            "Sources/Rules/SmithRules.swift",
            "Sources/Model/Inventory.swift"
        ]
        let sources = try paths.map {
            try String(contentsOf: root.appending(path: $0), encoding: .utf8)
        }

        XCTAssertFalse(sources.contains { $0.contains("Reforged \\(upgradeLevel)/3") })
        XCTAssertFalse(sources.contains { $0.contains("Reforged \\(profile.reforgeRank)/3") })
        XCTAssertTrue(sources[0].contains("SmithRules.maximumReforgeLevel"))
        XCTAssertTrue(sources[1].contains("SmithRules.maximumReforgeLevel"))
        XCTAssertTrue(sources[2].contains("SmithRules.maximumReforgeLevel"))
        XCTAssertTrue(sources[3].contains("SmithRules.maximumReforgeLevel"))
        XCTAssertTrue(sources[4].contains("Tuning.Smith.maximumReforgeRank"))
    }

    func testBlacksmithRecipeGridReflowsBeforeTextShrinks() {
        XCTAssertEqual(MakerStationPresentationRules.recipeColumns(isAccessibilitySize: false), 3)
        XCTAssertEqual(MakerStationPresentationRules.recipeColumns(isAccessibilitySize: true), 2)
    }

    func testTradingPostKeepsTradeActionOutsideScrollableDetails() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(
            contentsOf: root.appending(path: "Sources/Screens/TradingPostView.swift"),
            encoding: .utf8
        )

        XCTAssertTrue(source.contains(".safeAreaInset(edge: .bottom, spacing: 0) { tradeActionBar }"))
        XCTAssertTrue(source.contains("Text(actionTitle).frame(maxWidth: .infinity)"))
        XCTAssertFalse(source.contains("Section {\n                    Button(actionTitle)"))
    }

    func testBlacksmithKeepsConstructAndReforgeActionsOutsideScrollableDetails() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(
            contentsOf: root.appending(path: "Sources/Screens/BlacksmithView.swift"),
            encoding: .utf8
        )

        XCTAssertTrue(source.contains("if let preview { constructionActionBar(preview) }"))
        XCTAssertTrue(source.contains("Text(\"Construct · \\(preview.essence) essence\").frame(maxWidth: .infinity)"))
        XCTAssertTrue(source.contains("reforgeActionBar"))
        XCTAssertTrue(source.contains("Text(\"Reforge\").frame(maxWidth: .infinity)"))
        XCTAssertTrue(source.contains("reforgeActionFootnote(readiness)"))
        XCTAssertTrue(source.contains("Needs \\(missing) more qualifying stock"))
        XCTAssertTrue(source.contains("Needs \\(max(0, need - have)) more essence."))
        XCTAssertTrue(source.contains("if let preview { rebuildActionBar(preview) }"))
        XCTAssertTrue(source.contains("Text(\"Rebuild · \\(preview.essence) essence\").frame(maxWidth: .infinity)"))
    }

    func testBlacksmithRecipesUseTheirExactSharedCatalogueIdentity() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(
            contentsOf: root.appending(path: "Sources/Screens/BlacksmithView.swift"),
            encoding: .utf8
        )

        let recipeTile = try XCTUnwrap(source.range(of: "private struct MakerRecipeTile"))
        let armouryTarget = try XCTUnwrap(source.range(of: "private struct ArmouryTargetSheet"))
        let recipeSurfaces = String(source[recipeTile.lowerBound..<armouryTarget.lowerBound])

        XCTAssertEqual(recipeSurfaces.components(separatedBy: "CatalogueItemPixelIdentity(").count - 1, 2)
        XCTAssertEqual(recipeSurfaces.components(separatedBy: "itemID: recipe.catalogFallback").count - 1, 2)
        XCTAssertEqual(recipeSurfaces.components(separatedBy: "identified: true").count - 1, 2)
    }

    func testLandingReadinessCopyComesFromRulesPreview() throws {
        var state = GameState.newGame()
        state.base.stations[Stations.blacksmith] = StationState(isUnlocked: true, tier: 0)
        state.base.essence = 100
        state.base.worldMaterialReserve.add(.init(
            id: .init(rawValue: "landing-point"),
            sample: sample(.fang, hardness: 60, source: "point")
        ))
        state.base.worldMaterialReserve.add(.init(
            id: .init(rawValue: "landing-grip"),
            sample: sample(.fibre, flexibility: 60, source: "grip")
        ))

        let readiness = PhysicalGearCraftingRules.readiness(
            PhysicalGearCraftingRules.pointedBlade, in: state)
        guard case .ready(let preview) = readiness else { return XCTFail("expected ready") }
        XCTAssertEqual(MakerStationPresentationRules.readinessLabel(readiness),
                       "Ready · Tier \(preview.outputTier)")
    }

    func testCandidateAssessmentExplainsWrongKindAndLowProperty() throws {
        let requirement = PhysicalGearCraftingRules.pointedBlade.requirements[0]
        XCTAssertEqual(PhysicalGearCraftingRules.rejectionReason(
            for: sample(.hide, hardness: 100, source: "wrong kind"), requirement: requirement),
            "Needs Bone, Fang, Quill.")
        XCTAssertEqual(PhysicalGearCraftingRules.rejectionReason(
            for: sample(.fang, hardness: 10, source: "soft point"), requirement: requirement),
            "Hardness 10 of 35 required.")
        XCTAssertNil(PhysicalGearCraftingRules.rejectionReason(
            for: sample(.fang, hardness: 35, source: "enough"), requirement: requirement))
    }

    func testOverflowGearCanBeReforgedAtomicallyWithoutLosingItsIdentity() throws {
        var state = GameState.newGame()
        state.base.essence = 999
        state.base.inventory.slots = 1
        let gear = ItemStack(id: InstanceID(rawValue: 902), catalogID: "blade_chipped")
        let requirement = try XCTUnwrap(SmithRules.requirement(for: gear.catalogID, at: 0))
        let stock = (0..<requirement.count).map { index in
            sample(.plate, hardness: requirement.minimum + 5, source: "stock \(index)")
        }
        for (index, sample) in stock.enumerated() {
            state.base.worldMaterialReserve.add(.init(
                id: .init(rawValue: "overflow-reforge-\(index)"), sample: sample
            ))
        }
        state.base.spillover = [gear]

        let result = try XCTUnwrap(SmithRules.reforge(overflow: gear, in: &state))
        XCTAssertEqual(result.id, gear.id)
        XCTAssertEqual(result.gearProfile?.reforgeRank, 1)
        let returned = state.base.spillover.first { $0.id == gear.id }
            ?? state.base.inventory.stacks.first { $0.id == gear.id }
        XCTAssertEqual(returned?.gearProfile?.stableInstanceID, gear.gearProfile?.stableInstanceID)
        XCTAssertEqual(returned?.gearProfile?.reforgeRank, 1)
        XCTAssertEqual(state.base.essence, 999 - requirement.essence)
    }

    func testStaleOverflowTargetRejectsWithoutPayment() {
        var state = GameState.newGame()
        state.base.essence = 999
        let gear = ItemStack(id: InstanceID(rawValue: 904), catalogID: "blade_chipped")
        let before = state
        XCTAssertNil(SmithRules.reforge(overflow: gear, in: &state))
        XCTAssertEqual(state, before)
    }

    func testEssenceSpringNamesAndConfirmsUnlearningBeforeMutation() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf: root.appendingPathComponent(
            "Sources/Screens/StationViews.swift"), encoding: .utf8)
        let spring = try XCTUnwrap(source.range(of: "struct EssenceSpringView: View"))
        let tabs = try XCTUnwrap(source.range(of: "enum EssenceSpringTab", range: spring.lowerBound..<source.endIndex))
        let view = String(source[spring.lowerBound..<tabs.lowerBound])

        XCTAssertTrue(view.contains("Button(cost == 0 ? \"Nothing to unlearn\" : \"Unlearn · \\(cost)\")"))
        XCTAssertTrue(view.contains("pendingUnlearning = member"))
        XCTAssertTrue(view.contains("Button(\"Cancel\", role: .cancel)"))
        XCTAssertTrue(view.contains("Button(\"Unlearn\", role: .destructive)"))
        XCTAssertTrue(view.contains("This returns \\(points) learned points and costs \\(cost) essence."))
        XCTAssertEqual(view.components(separatedBy: "store.respec(member)").count - 1, 1,
                       "unlearning should mutate only from the confirmed destructive action")
    }

    private func sample(_ kind: MaterialFamilyID, hardness: Double = 0,
                        flexibility: Double = 0, source: String) -> CraftMaterialUnitV1 {
        CraftMaterialUnitV1(kind: kind,
                       properties: MaterialProperties(hardness: hardness,
                                                      flexibility: flexibility),
                       grade: 50, source: source)
    }
}
