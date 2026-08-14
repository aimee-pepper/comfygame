import XCTest
@testable import Bookbinder

final class BaseBoardTests: XCTestCase {
    func testBaseSaveMenuIsADirectFullSizeSettingsDestination() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf: root.appending(path: "Sources/Screens/BaseView.swift"),
                                encoding: .utf8)
        XCTAssertTrue(source.contains("NavigationLink(value: AppRoute.settings)"))
        XCTAssertTrue(source.contains(".accessibilityLabel(\"Settings and save games\")"))
        XCTAssertFalse(source.contains("Menu {\n                NavigationLink(value: AppRoute.settings)"))
        XCTAssertTrue(source.contains("contextRow\n                firstReturnRouteCard\n                sectionPicker"))
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
        XCTAssertTrue(source.contains("No places are known in \\(selectedSection.title) yet."))
    }

    func testBoardUsesThreeColumnsNormallyAndTwoForAccessibilityText() {
        XCTAssertEqual(BaseBoardRules.columnCount(isAccessibilitySize: false), 3)
        XCTAssertEqual(BaseBoardRules.columnCount(isAccessibilitySize: true), 2)
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
}
