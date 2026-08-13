import XCTest
@testable import Bookbinder

@MainActor
final class EssenceSpringRefiningTests: XCTestCase {
    private func store(_ name: String = #function) -> GameStore {
        GameStore(io: .temporary(name: "spring-\(name)-\(UUID().uuidString)"))
    }

    func testSpringSectionsKeepRefiningStudyAndUnlearningSeparate() {
        XCTAssertEqual(EssenceSpringTab.allCases, [.refine, .study, .unlearn])
        XCTAssertEqual(Set(EssenceSpringTab.allCases.map(\.title)).count, 3)
    }

    func testRefineryUsesOneCompactPeerActionRowWithExactOutputs() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(
            contentsOf: root.appending(path: "Sources/Screens/SpendingViews.swift"),
            encoding: .utf8
        )

        XCTAssertTrue(source.contains("HStack(spacing: 10)"))
        XCTAssertTrue(source.contains("title: raw > 0 ? \"Refine selected\""))
        XCTAssertTrue(source.contains("RefineryActionLabel(title: \"Refine all\""))
        XCTAssertTrue(source.contains("Text(result).font(.caption2).monospacedDigit().opacity(0.82)"))
        XCTAssertTrue(source.contains("if store.refineEssence(rawUnits: selected)"))
        XCTAssertTrue(source.contains("Essence not refined"))
        XCTAssertTrue(source.contains("The available Raw Essence changed."))
    }

    func testUnidentifiedCuriosUseTheSharedDisclosureNeutralItemIdentity() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(
            contentsOf: root.appending(path: "Sources/Screens/SpendingViews.swift"),
            encoding: .utf8
        )

        XCTAssertTrue(source.contains("CatalogueItemPixelIdentity("))
        XCTAssertTrue(source.contains("itemID: stack.catalogID"))
        XCTAssertTrue(source.contains("identified: stack.identified"))
        XCTAssertTrue(source.contains("fallbackSystemIcon: stack.icon"))
        XCTAssertTrue(source.contains("Text(\"Identify · \\(Tuning.Economy.identifyCostEssence)\")"))
        XCTAssertTrue(source.contains("Image(systemName: \"drop.fill\")"))
    }

    func testBaselineSelectedRefinementIsExactAndBuildsPractice() {
        let store = store()
        store.mutate("raw") { state in
            state.base.resources.add(7, of: Resources.essenceRaw)
        }
        let before = store.state.base.essence

        XCTAssertTrue(store.refineEssence(rawUnits: 3))
        XCTAssertEqual(store.state.base.resources[Resources.essenceRaw], 4)
        XCTAssertEqual(store.state.base.essence, before + 6)
        XCTAssertEqual(store.state.base.lifetimeRawEssenceRefined, 3)
    }

    func testStaleExactAmountMutatesNothing() {
        let store = store()
        store.mutate("raw") { $0.base.resources.add(2, of: Resources.essenceRaw) }
        let before = store.state

        XCTAssertFalse(store.refineEssence(rawUnits: 3))
        XCTAssertEqual(store.state, before)
    }

    func testSecondPassNeedsPracticeAndChangesOnlyFutureConversions() throws {
        let store = store()
        let node = try XCTUnwrap(ContentCatalog.shared.researchNode(EconomyRules.secondPassNode))
        store.mutate("stock") { state in
            state.base.essence = 500
            state.base.resources.add(10, of: "quartz")
            state.base.resources.add(60, of: Resources.essenceRaw)
        }

        XCTAssertFalse(store.isAvailable(node))
        XCTAssertTrue(store.missingPrerequisites(for: node).contains { $0.contains("50 more") },
                      "missing reasons: \(store.missingPrerequisites(for: node))")
        XCTAssertTrue(store.refineEssence(rawUnits: 50),
                      "baseline rejected with \(store.state.base.resources[Resources.essenceRaw]) Raw")
        let afterBaseline = store.state.base.essence
        XCTAssertTrue(store.isAvailable(node), "missing: \(store.missingPrerequisites(for: node))")
        XCTAssertTrue(store.canResearch(node), "shortfall: \(store.shortfall(for: node))")
        XCTAssertTrue(store.research(node), "research transaction rejected after readiness")
        XCTAssertEqual(EconomyRules.refinementRate(in: store.state), 3)
        XCTAssertTrue(store.refineEssence(rawUnits: 10),
                      "second-pass conversion rejected with \(store.state.base.resources[Resources.essenceRaw]) Raw")
        XCTAssertEqual(store.state.base.essence, afterBaseline - 80 + 30)
        XCTAssertEqual(store.state.base.lifetimeRawEssenceRefined, 60)
    }

    func testContinuousSettlingTouchesOnlyNewRawAndOnlyOncePerOutcome() {
        var state = GameState.newGame()
        state.base.completedResearch.insert(EconomyRules.secondPassNode)
        state.base.completedResearch.insert(EconomyRules.continuousSettlingNode)
        state.base.stations[Stations.essenceSpring] = StationState(isUnlocked: true, tier: 1)
        state.base.autoRefineReturnedRawEssence = true
        state.base.resources.add(12, of: Resources.essenceRaw) // 8 old + 4 newly retained
        let before = state.base.essence
        let outcome: ExpeditionOutcomeID = 41

        let receipt = EconomyRules.commitContinuousSettling(rawUnits: 4, outcomeID: outcome,
                                                             in: &state)
        XCTAssertEqual(receipt, .init(rawSpent: 4, essenceGained: 12, rate: 3))
        XCTAssertEqual(state.base.resources[Resources.essenceRaw], 8)
        XCTAssertEqual(state.base.essence, before + 12)
        XCTAssertEqual(state.base.lifetimeRawEssenceRefined, 4)
        XCTAssertNil(EconomyRules.commitContinuousSettling(rawUnits: 4, outcomeID: outcome,
                                                            in: &state))
        XCTAssertEqual(state.base.resources[Resources.essenceRaw], 8)
    }

    func testContinuousSettlingRequiresUnlockAndToggle() {
        var state = GameState.newGame()
        state.base.resources.add(3, of: Resources.essenceRaw)
        XCTAssertNil(EconomyRules.commitContinuousSettling(rawUnits: 3, outcomeID: 1, in: &state))
        state.base.completedResearch.insert(EconomyRules.continuousSettlingNode)
        XCTAssertNil(EconomyRules.commitContinuousSettling(rawUnits: 3, outcomeID: 1, in: &state))
        XCTAssertEqual(state.base.resources[Resources.essenceRaw], 3)
    }

    func testPortalReturnAutoRefinesTheFrozenRetainedRawAndReportsIt() throws {
        let store = store()
        let portal = GridPoint(x: 0, y: 0)
        let map = WorldMap(width: 1, height: 1,
                           tiles: [Tile(content: .portal(isEntry: true), isRevealed: true)],
                           entry: portal)
        var run = WorldRun(runIndex: 1,
                           book: BoundBook(symbols: [:], randomlyFilled: [], essencePaid: 0),
                           mapSeed: 91, rng: SeededRNG(seed: 91),
                           map: map, playerPosition: portal)
        run.satchel.add(4, of: Resources.essenceRaw)
        store.mutate("continuous fixture") { state in
            state.base.completedResearch.formUnion([
                EconomyRules.secondPassNode, EconomyRules.continuousSettlingNode
            ])
            state.base.stations[Stations.essenceSpring] = StationState(isUnlocked: true, tier: 1)
            state.base.autoRefineReturnedRawEssence = true
            state.base.resources.add(5, of: Resources.essenceRaw)
            state.worlds.activeRun = run
        }
        let before = store.state.base.essence

        store.portalHome()

        XCTAssertEqual(store.state.base.resources[Resources.essenceRaw], 5,
                       "stored Raw must not be swept into an outcome conversion")
        XCTAssertEqual(store.state.base.essence, before + 12 + store.essenceSpringYield)
        XCTAssertEqual(store.state.base.lifetimeRawEssenceRefined, 4)
        XCTAssertEqual(store.state.base.lastAutoRefinedOutcomeID, 1)
        let recap = try XCTUnwrap(store.state.worlds.lastExit?.essenceEconomy)
        XCTAssertEqual(recap.rawCollected, 4)
        XCTAssertEqual(recap.rawAutoRefined, 4)
        XCTAssertEqual(recap.automaticallyRefinedEssence, 12)
        XCTAssertEqual(recap.refinedEquivalent, 0,
                       "automatically converted Raw must not be counted again as held value")
    }

    func testPortalReturnValuesUnrefinedRawWithoutConvertingIt() throws {
        let store = store()
        let portal = GridPoint(x: 0, y: 0)
        var run = WorldRun(
            runIndex: 1, book: BoundBook(symbols: [:], randomlyFilled: [], essencePaid: 0),
            mapSeed: 92, rng: SeededRNG(seed: 92),
            map: WorldMap(width: 1, height: 1,
                          tiles: [Tile(content: .portal(isEntry: true), isRevealed: true)],
                          entry: portal),
            playerPosition: portal)
        run.satchel.add(3, of: Resources.essenceRaw)
        store.mutate("manual fixture") { $0.worlds.activeRun = run }

        store.portalHome()

        let recap = try XCTUnwrap(store.state.worlds.lastExit?.essenceEconomy)
        XCTAssertEqual(recap.rawCollected, 3)
        XCTAssertEqual(recap.refinedEquivalent, 6)
        XCTAssertEqual(recap.rawAutoRefined, 0)
        XCTAssertEqual(recap.automaticallyRefinedEssence, 0)
        XCTAssertEqual(store.state.base.resources[Resources.essenceRaw], 3)
    }

    func testSpringResearchOwnsDeepenAndEfficiencyWithoutShelving() throws {
        let deepen = try XCTUnwrap(ContentCatalog.shared.researchNode("deepen_spring"))
        let second = try XCTUnwrap(ContentCatalog.shared.researchNode(EconomyRules.secondPassNode))
        let continuous = try XCTUnwrap(ContentCatalog.shared.researchNode(EconomyRules.continuousSettlingNode))
        XCTAssertEqual(deepen.branch, "spring")
        XCTAssertTrue(deepen.requires.isEmpty)
        XCTAssertEqual(second.branch, "spring")
        XCTAssertEqual(second.needsLifetimeRawRefined, 50)
        XCTAssertEqual(continuous.requires, [EconomyRules.secondPassNode])
        XCTAssertEqual(continuous.needsStationTier, 1)
        XCTAssertEqual(ContentCatalog.shared.researchBranch("spring")?.station, Stations.essenceSpring)
    }

    func testLegacyBaseAndRecapDecodeWithNoRefiningFields() throws {
        let base = try SaveCodec.makeDecoder().decode(BaseState.self, from: Data("{}".utf8))
        XCTAssertEqual(base.lifetimeRawEssenceRefined, 0)
        XCTAssertFalse(base.autoRefineReturnedRawEssence)
        XCTAssertNil(base.lastAutoRefinedOutcomeID)

        let economy = try SaveCodec.makeDecoder().decode(RunExitSummary.EssenceEconomy.self,
                                                          from: Data("{}".utf8))
        XCTAssertEqual(economy, .init())
    }

    func testRefiningProgressToggleAndOutcomeReceiptSurviveSaveRoundTrip() throws {
        var state = GameState.newGame()
        state.base.lifetimeRawEssenceRefined = 73
        state.base.autoRefineReturnedRawEssence = true
        state.base.lastAutoRefinedOutcomeID = 12
        state.base.completedResearch.formUnion([
            EconomyRules.secondPassNode, EconomyRules.continuousSettlingNode
        ])
        let restored = try SaveCodec.makeDecoder().decode(
            GameState.self, from: SaveCodec.makeEncoder().encode(state))
        XCTAssertEqual(restored.base.lifetimeRawEssenceRefined, 73)
        XCTAssertTrue(restored.base.autoRefineReturnedRawEssence)
        XCTAssertEqual(restored.base.lastAutoRefinedOutcomeID, 12)
        XCTAssertEqual(EconomyRules.refinementRate(in: restored), 3)
    }

    func testSpendableAndRunwayUseTheUnlockedRate() throws {
        var state = GameState.newGame()
        state.base.essence = 5
        state.base.resources.add(4, of: Resources.essenceRaw)
        XCTAssertEqual(EconomyRules.spendableEssence(in: state), 13)
        state.base.completedResearch.insert(EconomyRules.secondPassNode)
        XCTAssertEqual(EconomyRules.spendableEssence(in: state), 17)
        let spring = try XCTUnwrap(ContentCatalog.shared.station(Stations.essenceSpring))
        XCTAssertEqual(StationRunwayRules.preview(for: spring, in: state).refinableRawEssence, 12)
    }
}
