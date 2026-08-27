import SwiftUI
import UIKit
import XCTest
@testable import Bookbinder

final class BaseBoardTests: XCTestCase {
    @MainActor
    func testVillagePrimaryFacesExposeImmediatePressedStateWithoutMutation() throws {
        let store = GameStore(io: .temporary(name: "base-press-\(UUID().uuidString)"))
        store.mutate("prepare press fixture") { state in
            for lesson in TutorialLessonID.allCases {
                state.tutorial.complete(lesson, fact: "press_fixture")
            }
        }
        let before = try SaveCodec.encode(store.state)
        for id in ["village.tab.home", "village.party", "village.bind-depart"] {
            FullFacePressMeasurements.reset()
            let controller = UIHostingController(rootView:
                NavigationStack { BaseView().environmentObject(store) }
                    .environment(\.fullFacePressFixtureID, id)
                    .environment(\.dynamicTypeSize, .large)
                    .frame(width: 368, height: 800))
            let window = UIWindow(frame: .init(x: 0, y: 0, width: 368, height: 800))
            window.rootViewController = controller; window.makeKeyAndVisible()
            controller.additionalSafeAreaInsets = .init(top: 59, left: 0, bottom: 34, right: 0)
            controller.view.frame = window.bounds; controller.view.layoutIfNeeded()
            RunLoop.main.run(until: Date().addingTimeInterval(0.08))
            let measurement = try XCTUnwrap(FullFacePressMeasurements.values[id], id)
            XCTAssertTrue(measurement.isEnabled, id)
            XCTAssertTrue(measurement.isPressed, id)
            XCTAssertGreaterThan(measurement.frame.width, 0, id)
            XCTAssertGreaterThan(measurement.frame.height, 0, id)
            XCTAssertGreaterThanOrEqual(measurement.frame.minX, 0, id)
            XCTAssertLessThanOrEqual(measurement.frame.maxX, 368, id)
            window.isHidden = true
        }
        XCTAssertEqual(try SaveCodec.encode(store.state), before)
    }

    private func rgba(_ image: UIImage, x: Int, y: Int) throws -> [UInt8] {
        let cg = try XCTUnwrap(image.cgImage)
        let data = try XCTUnwrap(cg.dataProvider?.data)
        let bytes = CFDataGetBytePtr(data)!
        let offset = y * cg.bytesPerRow + x * 4
        return Array(UnsafeBufferPointer(start: bytes + offset, count: 4))
    }

    @MainActor
    func testApprovedHomeRendersAt368By800InLightAndDark() throws {
        let store = GameStore(io: .temporary(name: "base-render-\(UUID().uuidString)"))
        store.mutate("prepare base render fixture") { state in
            for lesson in TutorialLessonID.allCases {
                state.tutorial.complete(lesson, fact: "visual_fixture")
            }
        }
        for scheme in [ColorScheme.light, .dark] {
            let controller = UIHostingController(rootView:
                NavigationStack { BaseView().environmentObject(store) }
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
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
            let image = UIGraphicsImageRenderer(size: window.bounds.size).image { _ in
                controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
            }
            window.isHidden = true
            XCTAssertEqual(image.size, CGSize(width: 368, height: 800))
            XCTAssertNotEqual(try rgba(image, x: 184, y: 10), [0, 0, 0, 255],
                              "Village top unsafe region must use its semantic backdrop")
            XCTAssertNotEqual(try rgba(image, x: 184, y: 785), [0, 0, 0, 255],
                              "Village bottom unsafe region must use its semantic backdrop")
            let attachment = XCTAttachment(image: image)
            attachment.name = "base-home-\(scheme == .light ? "light" : "dark")"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }

    func testVillageSafeSpaceChangeOwnsBackdropOnly() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf: root.appending(path: "Sources/Screens/BaseView.swift"),
                                encoding: .utf8)
        XCTAssertTrue(source.contains(".background(PixelUITheme.screen.ignoresSafeArea())"))
        XCTAssertTrue(source.contains("districtPager(containerSize: geometry.size)\n                        .frame(maxWidth: .infinity, maxHeight: .infinity)"))
        XCTAssertTrue(source.contains(".safeAreaInset(edge: .bottom, spacing: 0)"))
    }

    func testBaseSaveMenuIsADirectFullSizeSettingsDestination() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf: root.appending(path: "Sources/Screens/BaseView.swift"),
                                encoding: .utf8)
        XCTAssertTrue(source.contains("NavigationLink(value: AppRoute.settings)"))
        XCTAssertTrue(source.contains(".accessibilityLabel(\"Settings and save games\")"))
        XCTAssertFalse(source.contains("Menu {\n                NavigationLink(value: AppRoute.settings)"))
        let context = try XCTUnwrap(source.range(of: "contextRow"))
        let route = try XCTUnwrap(source.range(of: "firstReturnRouteCard",
                                               range: context.upperBound..<source.endIndex))
        XCTAssertNotNil(source.range(of: "sectionPicker", range: route.upperBound..<source.endIndex))
        XCTAssertFalse(source.contains(".overlay(alignment: .top) {\n            firstReturnRouteCard"))
    }

    func testEveryCurrentStationAuthorsOneUniqueBoardPosition() throws {
        let stations = ContentCatalog.shared.stations
        XCTAssertTrue(stations.allSatisfy { $0.homeSection != nil && $0.sectionOrder != nil })
        let positions = try stations.map { station in
            "\(try XCTUnwrap(station.homeSection).rawValue):\(try XCTUnwrap(station.sectionOrder))"
        }
        XCTAssertEqual(Set(positions).count, stations.count)
    }

    func testCompleteTwentySixIDCompatibilityMapMatchesSettledBoard() throws {
        let expected: [(StationID, StationHomeSection, Int)] = [
            ("writing_desk", .home, 0), ("storehouse", .home, 1), ("party", .home, 2),
            ("firepit", .home, 3), ("essence_spring", .home, 4), ("workshop", .home, 5),
            ("trading_post", .make, 0), ("recycler", .make, 1), ("blacksmith", .make, 2),
            ("apothecary", .make, 3), ("tannery", .make, 4), ("bowyer", .make, 5),
            ("armoury", .make, 6), ("weaponsmith", .make, 7), ("distillery", .make, 8),
            ("channelworks", .make, 9),
            ("library", .study, 0), ("constellation", .study, 1), ("bestiary", .study, 2),
            ("survey_post", .study, 3), ("reliquary", .study, 4), ("scriptorium", .study, 5),
            ("wayfarers_table", .realms, 0), ("menagerie", .realms, 1),
            ("deep_works", .realms, 2), ("anchorage", .realms, 3)
        ]

        XCTAssertEqual(expected.count, 26)
        for (id, section, order) in expected {
            let placement = try XCTUnwrap(StationDef.boardPlacement(for: id))
            XCTAssertEqual(placement.section, section, id.rawValue)
            XCTAssertEqual(placement.order, order, id.rawValue)
        }
    }

    func testBoardOrderingDoesNotDependOnJSONArrayOrder() {
        let expected: [StationID] = [
            "writing_desk", "storehouse", "party", "firepit", "essence_spring", "workshop",
            "trading_post", "recycler", "blacksmith", "apothecary", "tannery", "bowyer", "armoury",
            "weaponsmith", "distillery", "channelworks",
            "library", "constellation", "bestiary", "survey_post", "reliquary", "scriptorium",
            "wayfarers_table", "anchorage"
        ]
        let forward = ContentCatalog.boardOrderedStations(ContentCatalog.shared.stations).map(\.id)
        let reversed = ContentCatalog.boardOrderedStations(Array(ContentCatalog.shared.stations.reversed())).map(\.id)
        XCTAssertEqual(forward, expected)
        XCTAssertEqual(reversed, expected)
    }

    func testKnownAndFoundationStationsShareOneTileAndUnknownStationsStayAbsent() throws {
        let stations = ContentCatalog.shared.stationsInOrder
        let known = BaseBoardRules.knownStations(
            stations,
            unlocked: ["writing_desk", "trading_post"],
            foundations: ["trading_post"]
        )
        XCTAssertEqual(known.count { $0.id == "trading_post" }, 1)
        XCTAssertTrue(known.contains { $0.id == "writing_desk" })
        XCTAssertFalse(known.contains { $0.id == "blacksmith" })
        XCTAssertEqual(BaseBoardRules.availableSections(for: known), StationHomeSection.allCases,
                       "Unknown districts stay navigable even before they contain a known place")
        XCTAssertEqual(BaseBoardRules.stations(in: .make, from: known).map(\.id), ["trading_post"])
    }

    func testFreshBaseKeepsEveryDistrictVisibleAndNamesEmptyDistrictsTruthfully() throws {
        XCTAssertEqual(BaseBoardRules.availableSections(for: []), StationHomeSection.allCases)

        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf: root.appending(path: "Sources/Screens/BaseView.swift"),
                                encoding: .utf8)
        XCTAssertTrue(source.contains("No known destinations"))
        XCTAssertTrue(source.contains("No places are known in \\(section.title) yet."))
    }

    func testBoardUsesThreeColumnsNormallyAndTwoForAccessibilityText() {
        XCTAssertEqual(BaseBoardRules.columnCount(isAccessibilitySize: false), 3)
        XCTAssertEqual(BaseBoardRules.columnCount(isAccessibilitySize: true), 2)
    }

    func testDistrictCaptionNeverCallsAFoundationReady() {
        XCTAssertEqual(BaseBoardRules.districtCaption(section: .home, readyCount: 0,
                                                       foundationCount: 0),
                       "Home · 5 places ready")
        XCTAssertEqual(BaseBoardRules.districtCaption(section: .make, readyCount: 2,
                                                       foundationCount: 1),
                       "Make · 2 ready · 1 foundation")
        XCTAssertEqual(BaseBoardRules.districtCaption(section: .study, readyCount: 1,
                                                       foundationCount: 0),
                       "Study · 1 place ready")
        XCTAssertEqual(BaseBoardRules.districtCaption(section: .realms, readyCount: 0,
                                                       foundationCount: 2),
                       "Realms · 2 foundations")
        XCTAssertEqual(BaseBoardRules.districtCaption(section: .realms, readyCount: 0,
                                                       foundationCount: 0),
                       "Realms · no known places")
    }

    func testTownPagesPreserveEveryStationInOrderWithFourPlotsPerPage() {
        let stations = BaseBoardRules.destinations(from: ContentCatalog.shared.stationsInOrder)
        let pages = BaseBoardRules.townPages(stations)
        XCTAssertTrue(pages.allSatisfy { !$0.isEmpty && $0.count <= 4 })
        XCTAssertEqual(pages.flatMap { $0 }.map(\.id), stations.map(\.id))
        XCTAssertEqual(BaseBoardRules.townPlotPositions, [
            CGPoint(x: 0.24, y: 0.49), CGPoint(x: 0.75, y: 0.42),
            CGPoint(x: 0.25, y: 0.72), CGPoint(x: 0.75, y: 0.70)
        ])
        XCTAssertTrue(BaseBoardRules.townPlotPositions.allSatisfy {
            (0...1).contains($0.x) && (0...1).contains($0.y)
        })
    }

    func testBestiaryIsLibraryOwnedAndNeverAnIndependentBaseDestination() {
        let destinations = BaseBoardRules.destinations(from: ContentCatalog.shared.stationsInOrder)
        XCTAssertFalse(destinations.contains { $0.id == "bestiary" })
        XCTAssertTrue(destinations.contains { $0.id == "library" })
        XCTAssertEqual(AppRoute.bestiary.rawValue, "bestiary",
                       "The nested Library/deep-link route must remain stable")
    }

    func testTownPlotCoordinatesFollowTheAspectFilledBackdropCrop() {
        let image = CGSize(width: 1408, height: 3048)
        let container = CGSize(width: 344, height: 430)
        let frame = BaseBoardRules.townAspectFillFrame(imageSize: image, containerSize: container)

        XCTAssertEqual(frame.width, 344, accuracy: 0.001)
        XCTAssertGreaterThan(frame.height, container.height)
        XCTAssertLessThan(frame.minY, 0, "The tall source is cropped vertically in this frame")

        let normalized = CGPoint(x: 0.75, y: 0.70)
        let point = BaseBoardRules.townPlotPoint(normalized, imageSize: image,
                                                 containerSize: container)
        XCTAssertEqual(point.x, frame.minX + frame.width * normalized.x, accuracy: 0.001)
        XCTAssertEqual(point.y, frame.minY + frame.height * normalized.y, accuracy: 0.001)
        XCTAssertNotEqual(point.y, container.height * normalized.y,
                          "Plot and image must share the aspect-fill crop transform")
    }

    func testEveryNonHomeDistrictConsumesThePagedImageVillageScene() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf: root.appending(path: "Sources/Screens/BaseView.swift"),
                                encoding: .utf8)

        XCTAssertTrue(source.contains("section != .home"))
        XCTAssertTrue(source.contains("townDistrictBoard(section: section, containerSize: containerSize)"))
        XCTAssertTrue(source.contains("BaseBoardRules.townPages(destinations)"))
        XCTAssertTrue(source.contains("TownDistrictScene("))
        XCTAssertTrue(source.contains("base-town-scene-\\(section.rawValue)"))
        XCTAssertTrue(source.contains("populatedPages.isEmpty ? [[]] : populatedPages"),
                      "An empty district must retain its image-backed screen instead of disappearing")
        XCTAssertFalse(source.contains("let sceneHeight"))
        XCTAssertFalse(source.contains(".frame(height: sceneHeight)"))
        XCTAssertFalse(source.contains("TownDistrictScene(\n                    section: selectedSection") &&
                       source.contains(".padding(.horizontal, 1)"))

        let start = try XCTUnwrap(source.range(of: "private struct TownDistrictScene"))
        let end = try XCTUnwrap(source.range(of: "private struct TownStationPlot",
                                             range: start.upperBound..<source.endIndex))
        let scene = String(source[start.lowerBound..<end.lowerBound])
        XCTAssertTrue(scene.contains(".clipped()"))
        XCTAssertFalse(scene.contains("clipShape(RoundedRectangle"))
        XCTAssertFalse(scene.contains("overlay(RoundedRectangle"))
    }

    func testDistrictPickerAndSwipePagerShareOneSelectionWithoutNestedSwipePaging() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf: root.appending(path: "Sources/Screens/BaseView.swift"),
                                encoding: .utf8)
        XCTAssertTrue(source.contains("TabView(selection: $selectedSection)"))
        XCTAssertTrue(source.contains(".tag(section)"))
        XCTAssertTrue(source.contains("base-district-pager"))
        XCTAssertTrue(source.contains("selectedSection = section"))
        XCTAssertTrue(source.contains("base-section-picker"))
        XCTAssertTrue(source.contains("base-district-caption"))
        XCTAssertTrue(source.contains("townPageBySection[section]"))
        XCTAssertTrue(source.contains("Button(\"Previous\")"))
        XCTAssertTrue(source.contains("Button(\"Next\")"))
        XCTAssertEqual(source.components(separatedBy: "TabView").count - 1, 1,
                       "Station pagination must not compete with district swipe paging")
    }

    func testApprovedHomeChromeUsesSharedThemeWithoutChangingRoutes() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf: root.appending(path: "Sources/Screens/BaseView.swift"),
                                encoding: .utf8)
        XCTAssertTrue(source.contains("PixelUITheme.screen"))
        XCTAssertTrue(source.contains("PixelUITheme.headerB"))
        XCTAssertTrue(source.contains("PixelUITheme.surfaceRaised"))
        XCTAssertTrue(source.contains("PixelUITheme.primaryHighlight"))
        XCTAssertTrue(source.contains("NavigationLink(value: AppRoute.party)"))
        XCTAssertTrue(source.contains("NavigationLink(value: AppRoute.writingDesk)"))
        XCTAssertTrue(source.contains(".foregroundStyle(PixelUITheme.text)"))
        XCTAssertTrue(source.contains(".background(PixelUITheme.surfaceRaised)"))
        let pickerStart = try XCTUnwrap(source.range(of: "private var sectionPicker"))
        let pagerStart = try XCTUnwrap(source.range(of: "private func districtPager",
                                                    range: pickerStart.upperBound..<source.endIndex))
        let picker = String(source[pickerStart.lowerBound..<pagerStart.lowerBound])
        XCTAssertFalse(picker.contains("Color(red:"))
        XCTAssertFalse(picker.contains(".shadow("),
                       "Section-button shadows must not be inherited by their text")
    }

    func testTownBuildingArtIsExactIDOnlyAndUnknownStationsUseSemanticFallback() {
        XCTAssertEqual(BaseBoardRules.townBuildingAsset(for: "workshop"), "building-workshop-v1")
        XCTAssertEqual(BaseBoardRules.townBuildingAsset(for: "storehouse"), "building-storehouse-v1")
        XCTAssertEqual(BaseBoardRules.townBuildingAsset(for: "library"), "building-library-v1")
        XCTAssertEqual(BaseBoardRules.townBuildingAsset(for: "constellation"), "building-constellation-v1")
        XCTAssertEqual(BaseBoardRules.townBuildingAsset(for: "bestiary"), "building-bestiary-v1")
        XCTAssertEqual(BaseBoardRules.townBuildingAsset(for: "apothecary"), "building-apothecary-v1")
        XCTAssertEqual(BaseBoardRules.townBuildingAsset(for: "survey_post"), "building-survey-post-v1")
        XCTAssertEqual(BaseBoardRules.townBuildingAsset(for: "reliquary"), "building-reliquary-v1")
        XCTAssertEqual(BaseBoardRules.townBuildingAsset(for: "scriptorium"), "building-scriptorium-v1")
        XCTAssertEqual(BaseBoardRules.townBuildingAsset(for: "essence_spring"), "building-essence-spring-v1")
        XCTAssertNil(BaseBoardRules.townBuildingAsset(for: "blacksmith"))
        XCTAssertNil(BaseBoardRules.townBuildingAsset(for: "invented"))
    }

    func testEveryMappedTownBuildingIsPresentInTheBuiltAppBundle() {
        let mappedIDs: [StationID] = [
            "workshop", "storehouse", "library", "constellation", "bestiary", "apothecary", "survey_post",
            "reliquary", "scriptorium", "essence_spring"
        ]

        for stationID in mappedIDs {
            guard let asset = BaseBoardRules.townBuildingAsset(for: stationID) else {
                return XCTFail("Missing exact town-art mapping for \(stationID.rawValue)")
            }
            XCTAssertNotNil(
                Bundle.main.url(forResource: asset, withExtension: "png"),
                "\(asset).png is mapped but absent from the built app bundle"
            )
        }
    }

    func testGeneratedTownBuildingsPreserveFirstReturnRouteBookkeeping() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf: root.appending(path: "Sources/Screens/BaseView.swift"),
                                encoding: .utf8)
        let start = try XCTUnwrap(source.range(of: "private struct TownStationPlot"))
        let end = try XCTUnwrap(source.range(of: "private struct TownHotspotSign",
                                             range: start.upperBound..<source.endIndex))
        let plot = String(source[start.lowerBound..<end.lowerBound])

        XCTAssertTrue(plot.contains("openedRoute(route)"))
    }

    func testPartyIsAUtilityAndNotADestinationTile() {
        let destinations = BaseBoardRules.destinations(from: ContentCatalog.shared.stationsInOrder)
        XCTAssertFalse(destinations.contains { $0.route == AppRoute.party.rawValue })
        XCTAssertTrue(destinations.contains { $0.route == AppRoute.writingDesk.rawValue })
        XCTAssertTrue(destinations.contains { $0.route == AppRoute.storehouse.rawValue })
    }

    func testFoundationSheetReportsAStaleConstructionFailure() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(
            contentsOf: root.appending(path: "Sources/Screens/BaseView.swift"),
            encoding: .utf8
        )

        XCTAssertTrue(source.contains("if store.build(station)"))
        XCTAssertTrue(source.contains("Station not built"))
        XCTAssertTrue(source.contains("The builder, materials, Essence, or available space changed."))
    }

    func testFoundationBuildActionStaysOutsideScrollableRequirements() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(
            contentsOf: root.appending(path: "Sources/Screens/BaseView.swift"),
            encoding: .utf8
        )
        let sheetStart = try XCTUnwrap(source.range(of: "private struct StationFoundationSheet"))
        let sheetEnd = try XCTUnwrap(source.range(of: "struct CurrencyChip"))
        let sheet = String(source[sheetStart.lowerBound..<sheetEnd.lowerBound])

        XCTAssertTrue(sheet.contains(".safeAreaInset(edge: .bottom, spacing: 0) { foundationActionBar }"))
        XCTAssertTrue(sheet.contains("PersistentActionBar("))
        XCTAssertTrue(sheet.contains("Label(\"Build it\", systemImage: \"hammer\")"))
        XCTAssertTrue(sheet.contains(".disabled(!missing.isEmpty)"))
    }

    func testFoundationCostNeverFallsBackToAnInternalResourceID() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf: root.appending(path: "Sources/Screens/BaseView.swift"), encoding: .utf8)
        XCTAssertTrue(source.contains("StationCataloguePresentation.resourceName(id).lowercased()"))
        XCTAssertFalse(source.contains("name.lowercased() ?? id.rawValue"))
    }
}
