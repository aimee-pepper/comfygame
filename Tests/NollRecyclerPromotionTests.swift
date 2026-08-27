import XCTest
@testable import Bookbinder

final class NollRecyclerPromotionTests: XCTestCase {
    func testNollPromotionKeepsOpeningTrioAndHeldKitBoundaryExact() throws {
        let catalog = ContentCatalog.shared
        let noll = try XCTUnwrap(catalog.traveller("noll"))
        XCTAssertEqual(catalog.travellers.count, 29)
        XCTAssertEqual(noll.authoredOrder, 2)
        XCTAssertEqual(noll.storyArrivalBand, 0)
        XCTAssertEqual(noll.campaignPhase, .opening)
        XCTAssertEqual(noll.calling, "a Salvager")
        XCTAssertEqual(noll.signature.count, 2)
        XCTAssertEqual(noll.combatGraphVersion, 2)
        XCTAssertEqual(noll.combatNodePlan, [
            "combat.offense.precision.keen_eye", "combat.defense.protection.bulwark",
        ])
        XCTAssertEqual(catalog.traveller("vance")?.authoredOrder, 1)
        XCTAssertEqual(catalog.traveller("halloway")?.authoredOrder, 3)
        XCTAssertEqual(catalog.diary(of: "noll").map(\.id),
                       ["noll_where_0", "noll_where_1", "noll_word_vance",
                        "noll_word_halloway", "noll_world_join"])
        XCTAssertNil(catalog.diaryPage("noll_field_separation_kit"))
        XCTAssertFalse(catalog.researchNodes.contains { $0.id.rawValue.contains("field_separation") })
    }

    func testNollMeetingAndCorrectedLiveExchangeIDsUseOwnerPrefixes() throws {
        let noll = try XCTUnwrap(ContentCatalog.shared.traveller("noll"))
        XCTAssertEqual(noll.meeting?.questions.map(\.id), ["noll.join_left", "noll.repair", "noll.vance"])
        XCTAssertEqual(noll.meeting?.questions.first { $0.id == "noll.repair" }?.reply,
                       "\u{201c}Yes. That is not the same as saying it should be.\u{201d} They indicate the bowed edge. \u{201c}Repair preserves a whole. Salvage preserves uses. Sentiment becomes waste when it refuses to name which one it wants.\u{201d}")

        for id: TravellerID in ["sela", "halloway", "noll"] {
            let meeting = try XCTUnwrap(ContentCatalog.shared.traveller(id)?.meeting)
            XCTAssertTrue(meeting.questions.allSatisfy { $0.id.hasPrefix("\(id.rawValue).") })
        }
    }

    func testRecyclerIsNollOwnedDistinctAndCostsOnlyFifteenEssence() throws {
        let station = try XCTUnwrap(ContentCatalog.shared.station(Stations.recycler))
        XCTAssertEqual(station.name, "Recycler")
        XCTAssertEqual(station.route, AppRoute.recycler.rawValue)
        XCTAssertEqual(station.builtBy, "noll")
        XCTAssertEqual(station.buildCost?.essence, 15)
        XCTAssertTrue(station.buildCost?.resources.isEmpty == true)
        XCTAssertNotEqual(station.id, Stations.tradingPost)
        XCTAssertFalse(BaseState.newGame().station(Stations.recycler).isUnlocked)
    }
}
