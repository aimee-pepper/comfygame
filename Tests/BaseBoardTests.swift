import XCTest
@testable import Bookbinder

final class BaseBoardTests: XCTestCase {
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
            "trading_post", "blacksmith", "apothecary", "tannery", "bowyer", "armoury",
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
        XCTAssertEqual(BaseBoardRules.availableSections(for: known), [.home, .make])
        XCTAssertEqual(BaseBoardRules.stations(in: .make, from: known).map(\.id), ["trading_post"])
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
}
