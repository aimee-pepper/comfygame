import XCTest
@testable import Bookbinder

@MainActor
final class ExpeditionOutcomeTests: XCTestCase {
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
