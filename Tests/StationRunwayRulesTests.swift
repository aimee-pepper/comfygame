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
        XCTAssertEqual(preview.affordability.essenceAvailableNow, 10)
        XCTAssertEqual(preview.affordability.essenceAfterRefining,
                       10 + EconomyRules.refine(rawUnits: 5))
        XCTAssertEqual(preview.affordability.afterActionLabel,
                       "Essence after refining and construction")
        XCTAssertEqual(preview.affordability.worldCountLabel,
                       "Worlds you can afford after refining and construction")
        XCTAssertEqual(preview.affordability.basisLabel,
                       "Typical cost of a recent world written by you")
        XCTAssertTrue(preview.telemetryLabel.contains("Essence after refining and construction="))
        XCTAssertTrue(preview.telemetryLabel.contains(
            "Worlds you can afford after refining and construction="))
        XCTAssertTrue(preview.telemetryLabel.contains(
            "Typical cost of a recent world written by you="))
        XCTAssertFalse(preview.telemetryLabel.contains("spendableNow"))
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
        XCTAssertTrue(preview.telemetryLabel.contains("Essence available after construction="))
        XCTAssertTrue(preview.telemetryLabel.contains("Worlds you can afford after construction="))
        XCTAssertFalse(preview.telemetryLabel.contains("after refining and construction"))
        XCTAssertFalse(preview.telemetryLabel.contains("Essence after refining="))
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

    func testSharedEssencePresentationPinsThresholdsAndNoBasisCopy() {
        func presentation(after: Int) -> EssenceAffordabilityPresentation {
            EssenceAffordabilityPresentation(
                action: .construction, essenceAvailableNow: after, refinableRawEquivalent: 0,
                actionCost: 0, basis: .recentWorld, basisCost: 10)
        }
        XCTAssertEqual(presentation(after: 0).worldsAffordable, 0)
        XCTAssertEqual(presentation(after: 9).worldsAffordable, 0.9)
        XCTAssertEqual(presentation(after: 10).worldsAffordable, 1.0)
        XCTAssertEqual(presentation(after: 19).worldsAffordable, 1.9)
        XCTAssertEqual(presentation(after: 20).worldsAffordable, 2.0)
        XCTAssertEqual(presentation(after: 9).warningCopy,
                       "This would leave less Essence than a typical recent world written by you costs.")
        XCTAssertEqual(presentation(after: 10).warningCopy,
                       "This would leave Essence for fewer than 2 worlds at the shown cost.")
        XCTAssertNil(presentation(after: 20).warningCopy)

        let noBasis = EssenceAffordabilityPresentation(
            action: .construction, essenceAvailableNow: 10, refinableRawEquivalent: 0,
            actionCost: 4, basis: nil, basisCost: nil)
        XCTAssertEqual(noBasis.noBasisCopy,
                       "Bind a world written by you to estimate how many worlds you can afford afterward.")
    }

    func testRecentWorldMedianCoversOddAndEvenHistories() throws {
        var state = GameState.newGame()
        state.base.essence = 100
        let station = try XCTUnwrap(ContentCatalog.shared.station(Stations.tradingPost))
        state.reality.library.visitedWorlds = [10, 20, 30].enumerated().map {
            world(UInt64($0.offset + 1), paid: $0.element)
        }
        XCTAssertEqual(StationRunwayRules.preview(for: station, in: state).recentMedianBindCost, 20)
        state.reality.library.visitedWorlds.append(world(4, paid: 40))
        XCTAssertEqual(StationRunwayRules.preview(for: station, in: state).recentMedianBindCost, 25)
    }

    func testNamedAffordabilitySurfacesUseCanonicalHumanCopy() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent()
        let paths = ["Sources/Screens/BaseView.swift", "Sources/Screens/ResearchTreeLayout.swift",
                     "Sources/App/RootView.swift", "Sources/Rules/StationRunwayRules.swift"]
        let source = try paths.map {
            try String(contentsOf: root.appending(path: $0), encoding: .utf8)
        }.joined(separator: "\n")
        for required in ["Essence available now", "Essence after refining",
                         "Typical cost of a recent world written by you",
                         "Worlds you can afford", "Current World preview cost",
                         "ESSENCE AVAILABLE", "Enough to bind at least one more world"] {
            XCTAssertTrue(source.contains(required), required)
        }
        for retired in ["Spendable Essence", "Low writing runway", "Authored-bind runway",
                        "Recent median authored bind", "Current authored bind preview",
                        "Ordinary authored binds remaining", "Essence held"] {
            XCTAssertFalse(source.contains(retired), retired)
        }
    }
}
