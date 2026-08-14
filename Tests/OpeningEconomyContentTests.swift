import XCTest
@testable import Bookbinder

final class OpeningEconomyContentTests: XCTestCase {
    func testVanceIsTheFirstAuthoredFindWithOneStarterWritableCondition() throws {
        let vance = try XCTUnwrap(ContentCatalog.shared.traveller("vance"))

        XCTAssertEqual(vance.authoredOrder, 1)
        XCTAssertEqual(vance.campaignPhase, .opening)
        XCTAssertEqual(vance.signature.count, 1)
        XCTAssertEqual(vance.signature[0].condition.target, "relief")
        XCTAssertEqual(vance.signature[0].condition.measure, .aspect)
        XCTAssertEqual(vance.signature[0].condition.key, "openness")
        XCTAssertEqual(vance.signature[0].condition.minimum, 68)
        XCTAssertEqual(vance.signature[0].passage,
                       "The land is broad and open, with few barriers between one horizon and the next. A loaded cart could cross without the ground inventing a toll.")
    }

    func testTradingPostIsOwnedByVanceAndCheapToEstablish() throws {
        let station = try XCTUnwrap(ContentCatalog.shared.station("trading_post"))

        XCTAssertEqual(station.name, "Trading Post")
        XCTAssertEqual(station.route, "tradingPost")
        XCTAssertEqual(station.builtBy, "vance")
        XCTAssertEqual(station.buildCost?.essence, 10)
        XCTAssertEqual(station.buildCost?.resources, [:])
        XCTAssertFalse(station.unlockedAtStart)
    }

    func testLegacyVancePageIDsRemainReadableButNoLongerClaimRemovedClues() throws {
        let pages = ContentCatalog.shared.diaryPages.filter { $0.diary == "vance" }
        let locationPages = pages.filter { $0.kind == .locationClue }

        XCTAssertEqual(locationPages.map(\.id), ["vance_where_0"])
        for id in ["vance_where_1", "vance_where_2", "vance_world_repaired_handle"] as [DiaryPageID] {
            XCTAssertNotNil(pages.first { $0.id == id }, "old saves must still resolve \(id.rawValue)")
        }
        XCTAssertEqual(pages.first { $0.id == "vance_where_1" }?.kind, .worldWorthWriting)
        XCTAssertEqual(pages.first { $0.id == "vance_where_2" }?.kind, .worldWorthWriting)
    }

    func testOpeningOrderIncludesLiveRecyclerKeeperInSecondSlot() throws {
        let order = Dictionary(uniqueKeysWithValues: ContentCatalog.shared.travellers.compactMap {
            traveller in traveller.authoredOrder.map { (traveller.id, $0) }
        })

        XCTAssertEqual(order["vance"], 1)
        XCTAssertEqual(order["noll"], 2)
        XCTAssertEqual(order["halloway"], 3)
        XCTAssertEqual(order["mara"], 4)
        XCTAssertEqual(order["edren"], 5)
        XCTAssertEqual(order["tovin"], 27)
        XCTAssertEqual(order["nine"], 29)
    }
}
