import XCTest
@testable import Bookbinder

final class StationRunwayRulesTests: XCTestCase {
    private func world(_ id: UInt64, written: Bool = true, paid: Int?) -> VisitedWorld {
        VisitedWorld(id: InstanceID(rawValue: id), seed: id, runIndex: Int(id),
                     descriptionSentence: "", written: written ? ["Substrate ← Stone"] : [],
                     inertModifiers: [], readings: [:], travellersPresent: [],
                     bindEssencePaid: paid)
    }

    func testRunwayIncludesRefinableRawUsesRecentMedianAndWarnsFactually() throws {
        var state = GameState.newGame()
        state.base.essence = 10
        state.base.resources.add(5, of: Resources.essenceRaw)
        state.reality.library.visitedWorlds = [
            world(1, paid: 10), world(2, paid: 12), world(3, paid: 14),
            world(4, paid: 16), world(5, paid: 18), world(6, paid: 20)
        ]
        let station = try XCTUnwrap(ContentCatalog.shared.station(Stations.recycler))
        let preview = StationRunwayRules.preview(for: station, in: state)
        XCTAssertEqual(preview.refinableRawEssence, EconomyRules.refine(rawUnits: 5))
        XCTAssertEqual(preview.spendableNow, 10 + EconomyRules.refine(rawUnits: 5))
        XCTAssertEqual(preview.spendableAfter, preview.spendableNow - 15)
        XCTAssertEqual(preview.recentMedianBindCost, 16,
                       "only the five most recent authored paid worlds should set the median")
        XCTAssertEqual(preview.warning, .belowOne)
    }

    func testRunwayExcludesBlankZeroAndLegacyUnknownCosts() throws {
        var state = GameState.newGame()
        state.base.essence = 50
        state.reality.library.visitedWorlds = [
            world(1, written: false, paid: 20), world(2, paid: 0), world(3, paid: nil),
            world(4, paid: 12)
        ]
        let station = try XCTUnwrap(ContentCatalog.shared.station(Stations.tradingPost))
        let preview = StationRunwayRules.preview(for: station, in: state)
        XCTAssertEqual(preview.recentMedianBindCost, 12)
        XCTAssertEqual(preview.authoredBindsRemaining, 40.0 / 12.0)
        XCTAssertNil(preview.warning)
    }

    func testVisitedWorldBindCostIsTolerantAndRoundTrips() throws {
        let legacyData = try SaveCodec.makeEncoder().encode(world(1, paid: nil))
        let legacy = try SaveCodec.makeDecoder().decode(VisitedWorld.self, from: legacyData)
        XCTAssertNil(legacy.bindEssencePaid)
        let current = world(2, paid: 17)
        let restored = try SaveCodec.makeDecoder().decode(VisitedWorld.self,
            from: SaveCodec.makeEncoder().encode(current))
        XCTAssertEqual(restored.bindEssencePaid, 17)
    }

    func testLibraryRecordFreezesExactPaidBindCost() {
        let book = BoundBook(written: [], essencePaid: 23)
        let record = LibraryRules.record(book: book, page: Page(), seed: 44, runIndex: 2,
                                         travellers: [])
        XCTAssertEqual(record.bindEssencePaid, 23)
    }
}
