import XCTest
@testable import Bookbinder

@MainActor
final class TradingPostFlowTests: XCTestCase {
    func testStarterSandWritingDeterministicallyReachesVance() throws {
        let base = BaseState.newGame()
        XCTAssertTrue(base.ownedSources.contains("sand"), "Vance's opening route must use a starter focus")

        let writing = [
            Sigil(id: InstanceID(rawValue: 1), source: "sand", target: "relief",
                  intensity: .moderate)
        ]
        let readings = PressureRules.resolve(writing)
        let vance = try XCTUnwrap(ContentCatalog.shared.traveller("vance"))

        XCTAssertGreaterThanOrEqual(readings["relief"].aspect("openness"), 68)
        XCTAssertTrue(vance.isFound(in: readings))
        XCTAssertTrue(LibraryRules.travellersPresent(in: readings).contains { $0.id == vance.id })
    }

    func testRecruitBuildReturnAndSellIsOnePlayableStoreFlow() throws {
        let store = GameStore(io: .temporary(name: "trading-flow-\(UUID().uuidString)"))
        let vanceID: TravellerID = "vance"
        let portal = GridPoint(x: 0, y: 0)
        let meetingPoint = GridPoint(x: 1, y: 0)
        let map = WorldMap(width: 2, height: 1,
                           tiles: [Tile(content: .portal(isEntry: true), isRevealed: true),
                                   Tile(content: .traveller(vanceID), isRevealed: true)],
                           entry: portal)
        let run = WorldRun(runIndex: 1,
                           book: BoundBook(symbols: [:], randomlyFilled: [], essencePaid: 0),
                           mapSeed: 0xA11CE,
                           rng: SeededRNG(seed: 0xA11CE),
                           map: map,
                           playerPosition: meetingPoint,
                           travellersHere: [vanceID])

        store.mutate("fixture: meet Vance") { state in
            state.base.essence = 20
            state.base.resources.add(3, of: "rubble")
            state.worlds.activeRun = run
        }

        XCTAssertEqual(store.travellerHere?.id, vanceID)
        store.recruit(vanceID)
        XCTAssertTrue(store.state.reality.library.foundTravellers.contains(vanceID))
        XCTAssertTrue(store.buildableStations.contains { $0.id == Stations.tradingPost })

        // Walk back onto the portal after the conversation. The ordinary return path must freeze
        // the first persisted stock snapshot before construction.
        store.mutate("fixture: return to portal") { $0.worlds.activeRun?.playerPosition = portal }
        XCTAssertTrue(store.canPortalHere)
        store.portalHome()
        XCTAssertNil(store.state.worlds.activeRun)
        XCTAssertEqual(store.state.base.tradingPost.refreshSequence, 1)
        XCTAssertEqual(store.state.base.tradingPost.expeditionOutcomeID, 1)
        XCTAssertFalse(store.state.base.tradingPost.stock.isEmpty)

        let station = try XCTUnwrap(ContentCatalog.shared.station(Stations.tradingPost))
        XCTAssertTrue(store.build(station))
        XCTAssertTrue(store.state.base.station(Stations.tradingPost).isUnlocked)
        XCTAssertEqual(AppRoute(rawValue: station.route), .tradingPost)

        let revision = store.state.base.tradingPost.inventoryRevision
        XCTAssertEqual(store.sellAtTradingPost(resources: ["rubble": 2],
                                               expectedRevision: revision), .committed)
        XCTAssertEqual(store.state.base.resources["rubble"], 1)
        XCTAssertEqual(store.state.base.goldCoins, 2)
    }

    func testPortalCollapseAndDefeatEachRefreshExactlyOnce() {
        let store = GameStore(io: .temporary(name: "trading-exits-\(UUID().uuidString)"))
        store.mutate("fixture: fund") { $0.base.essence = 5_000 }

        store.write("plains")
        store.bindAndDepart()
        store.portalHome()
        XCTAssertEqual(store.state.base.tradingPost.refreshSequence, 1)

        store.dismissRunExitSummary()
        store.bindAndDepart()
        store.endRunWithPartialHaul(reason: "fixture collapse", kind: .collapse)
        XCTAssertEqual(store.state.base.tradingPost.refreshSequence, 2)

        store.dismissRunExitSummary()
        store.bindAndDepart()
        store.endRunWithPartialHaul(reason: "fixture defeat", kind: .defeat)
        XCTAssertEqual(store.state.base.tradingPost.refreshSequence, 3)
        XCTAssertEqual(store.state.base.tradingPost.expeditionOutcomeID, 3)
    }
}
