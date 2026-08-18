import XCTest
@testable import Bookbinder

/// Session 11: **one primary per pressure target**, plus modifiers, until chaining is learned.
///
/// One thing making light, one thing shaping the land, one thing setting the climate — then
/// decorate. It makes the early game legibly constrained, and it turns "a world with two kinds of
/// land in it" into an earned capability rather than something you could always do.
@MainActor
final class ExclusivityTests: XCTestCase {

    func testEverySymbolDeclaresWhatItIsPrimarilyAbout() {
        for symbol in ContentCatalog.shared.symbols {
            XCTAssertNotNil(symbol.primaryTarget,
                            "\(symbol.id.rawValue) belongs to no section of the palette")
        }
    }

    func testASecondPrimaryOnTheSameTargetIsRefused() {
        let store = makeStore()
        let (first, second) = try! twoSharingATarget()

        XCTAssertTrue(store.write(first.id))
        XCTAssertFalse(store.canWrite(second.id),
                       "\(second.id.rawValue) and \(first.id.rawValue) both decide "
                       + "\(first.primaryTarget!.rawValue)")
        XCTAssertFalse(store.write(second.id))
        XCTAssertEqual(store.state.base.page.symbolIDs, [first.id])
    }

    /// The refusal has to be *explicable*. A greyed-out button teaches nothing; naming the rune
    /// already in the way teaches the rule.
    func testTheBlockingRuneIsNamed() {
        let store = makeStore()
        let (first, second) = try! twoSharingATarget()
        store.write(first.id)
        XCTAssertEqual(store.blockingPrimary(for: second.id)?.id, first.id)
    }

    func testDifferentTargetsDoNotCompete() {
        let store = makeStore()
        var placed: [SymbolID] = []
        var seen: Set<PressureTargetID> = []
        for symbol in ContentCatalog.shared.symbols {
            guard let target = symbol.primaryTarget, !seen.contains(target) else { continue }
            if store.write(symbol.id) { placed.append(symbol.id); seen.insert(target) }
        }
        XCTAssertGreaterThan(placed.count, 2, "one per target should let several coexist")
        XCTAssertEqual(Set(placed).count, placed.count)
    }

    func testChainingLiftsTheRestriction() {
        let store = makeStore()
        let (first, second) = try! twoSharingATarget()
        store.write(first.id)
        XCTAssertFalse(store.canWrite(second.id))

        store.mutate("test: learn chaining") { $0.base.hasChainingUnlock = true }
        XCTAssertTrue(store.canWrite(second.id), "chaining should allow two lands in one world")
        XCTAssertTrue(store.write(second.id))
        XCTAssertEqual(store.state.base.page.symbolIDs.count, 2)
    }

    func testChainingIsReachableThroughResearch() {
        // A capability nothing grants is dead content.
        let grants = ContentCatalog.shared.researchNodes.flatMap(\.grants)
        XCTAssertTrue(grants.contains { $0.kind == .capability && $0.id == "chaining" },
                      "no research node teaches chaining")
        XCTAssertTrue(grants.contains { $0.effect == .finerHand }, "no research node grants a finer hand")
    }

    func testResearchingAFinerHandShrinksWhatYouWrite() {
        let store = makeStore()
        let symbol = ContentCatalog.shared.symbols.first { $0.expandsTo.count > 1 }!
        let before = store.footprint(of: symbol.id)

        store.mutate("test: a pencil") { $0.base.ownedHands.insert(.plain) }
        XCTAssertLessThan(store.footprint(of: symbol.id), before,
                          "a better instrument has to buy room, or it buys nothing")
    }

    func testImplementedCompoundAssemblyIsPurchasableAndUnlocksItsLiveProvider() throws {
        let store = fundedScriptoriumStore()
        let node = try XCTUnwrap(ContentCatalog.shared.researchNode("pen_compounds"))
        XCTAssertNil(EconomyRules.implementationAllows(node))
        XCTAssertTrue(store.canResearch(node))
        XCTAssertTrue(store.research(node))
        XCTAssertTrue(store.state.base.completedResearch.contains(node.id))
        XCTAssertNotEqual(
            store.previewCompoundFormalization(fingerprint: "not-yet-proven", nickname: "Test"),
            .refused(.locked),
            "The completed node is the live provider's durable unlock"
        )
    }

    func testImplementedPenmanshipProgressionRemainsAvailable() throws {
        let brushStore = fundedScriptoriumStore(completed: [])
        let brush = try XCTUnwrap(ContentCatalog.shared.researchNode("pen_brush"))
        XCTAssertTrue(brushStore.canResearch(brush))

        let chainingStore = fundedScriptoriumStore()
        let chaining = try XCTUnwrap(ContentCatalog.shared.researchNode("pen_chaining"))
        XCTAssertNil(EconomyRules.implementationAllows(chaining))
        XCTAssertTrue(chainingStore.canResearch(chaining))
        XCTAssertTrue(chainingStore.research(chaining))
        XCTAssertTrue(chainingStore.state.base.hasChainingUnlock)

        let inkStore = fundedScriptoriumStore()
        let ink = try XCTUnwrap(ContentCatalog.shared.researchNode("pen_ink_mixing"))
        XCTAssertNil(EconomyRules.implementationAllows(ink))
        XCTAssertTrue(inkStore.canResearch(ink))
        XCTAssertTrue(inkStore.research(ink))
        XCTAssertTrue(inkStore.state.base.completedResearch.contains(ink.id))

        let fountainStore = fundedScriptoriumStore(
            completed: ["pen_brush", "pen_desk", "pen_chaining"], tier: 2)
        let fountain = try XCTUnwrap(ContentCatalog.shared.researchNode("pen_fountain"))
        XCTAssertTrue(fountainStore.canResearch(fountain))
    }

    func testExclusivityIsEnforcedOnThePageNotJustInTheUI() {
        // The rule lives in PageRules, so nothing can route around it by calling the model directly.
        let (first, second) = try! twoSharingATarget()
        var page = PageRules.placeAnywhere(first, hand: .refined, on: Page())!
        XCTAssertNotNil(PageRules.exclusivityConflict(writing: second, on: page, chainingUnlocked: false))
        XCTAssertNil(PageRules.exclusivityConflict(writing: second, on: page, chainingUnlocked: true))
        page = PageRules.placeAnywhere(second, hand: .refined, on: page)!
        XCTAssertEqual(page.symbolIDs.count, 2, "PageRules itself doesn't police it — GameActions does")
    }

    // MARK: Helpers

    private func makeStore() -> GameStore {
        let store = GameStore(io: .temporary(name: "excl-\(UUID().uuidString)"))
        store.mutate("test: know everything") { state in
            state.base.ownedSymbols = Set(ContentCatalog.shared.symbols.map(\.id))
            state.base.essence = 500
        }
        return store
    }

    private func fundedScriptoriumStore(
        completed: Set<ResearchNodeID> = ["pen_brush", "pen_desk"],
        tier: Int = 1
    ) -> GameStore {
        let store = GameStore(io: .temporary(name: "penmanship-capability-\(UUID().uuidString)"))
        store.mutate("fund Penmanship") { state in
            state.base.completedResearch = completed
            state.base.stations[Stations.scriptorium] = StationState(isUnlocked: true, tier: tier)
            state.base.essence = 100_000
            for resource in ContentCatalog.shared.resources {
                state.base.resources.add(9_999, of: resource.id)
            }
        }
        return store
    }

    /// Two symbols that both claim the same pressure target.
    private func twoSharingATarget() throws -> (SymbolDef, SymbolDef) {
        let byTarget = Dictionary(grouping: ContentCatalog.shared.symbols) { $0.primaryTarget }
        for (target, symbols) in byTarget where target != nil && symbols.count >= 2 {
            return (symbols[0], symbols[1])
        }
        throw XCTSkip("no two symbols share a primary target")
    }
}
