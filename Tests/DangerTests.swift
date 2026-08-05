import XCTest
@testable import Bookbinder

/// The danger↔time axis (`contradiction-danger-spec.md` §5).
///
/// Peace spends stability to buy calm; danger runes spend calm to buy stability. Danger runes are
/// the release valve that makes a greedy world viable at all — a world rich enough to be worth
/// writing may be too unstable to survive, and you buy it time by accepting that it crawls with
/// things.
final class DangerTests: XCTestCase {

    // MARK: The axis

    func testADangerRuneBuysStability() {
        let bare = BookRules.stabilityDelta(symbolIDs: ["rich_ore"])
        let stormy = BookRules.stabilityDelta(symbolIDs: ["rich_ore", "storm"])
        XCTAssertGreaterThan(stormy, bare, "a danger rune has to buy time or it has no purpose")
    }

    func testPeaceSpendsStabilityToBuyCalm() {
        let bare = BookRules.stabilityDelta(symbolIDs: ["plains"])
        let peaceful = BookRules.stabilityDelta(symbolIDs: ["plains", "peace"])
        XCTAssertLessThan(peaceful, bare, "Peace is not a free upgrade — it costs the world time")

        let profile = BookRules.dangerProfile(symbolIDs: ["peace"])
        XCTAssertLessThan(profile.spawnMultiplier, 1, "Peace should thin the inhabitants")
        XCTAssertLessThan(profile.tierDelta, 0, "Peace should make what's left milder")
        XCTAssertTrue(profile.isCalming)
    }

    /// The greedy world the release valve exists for: unwritable without danger, writable with it.
    func testDangerMakesAGreedyWorldSurvivable() {
        let greedy: [SymbolID] = ["rich_ore", "teeming_life"]
        let bought = greedy + ["predation", "tremor"]

        let bareTurns = BookRules.turnsAvailable(stabilityScore: BookRules.stabilityScore(
            delta: BookRules.stabilityDelta(symbolIDs: greedy)))
        let boughtTurns = BookRules.turnsAvailable(stabilityScore: BookRules.stabilityScore(
            delta: BookRules.stabilityDelta(symbolIDs: bought)))

        XCTAssertGreaterThan(boughtTurns, bareTurns,
                             "accepting danger has to visibly buy turns, or nobody will take the trade")
    }

    // MARK: The cap

    func testStackingBroadensDangerWithoutMultiplyingTheReward() {
        let all: [SymbolID] = ["storm", "blight", "swarm_rune", "predation", "miasma_rune", "tremor"]
        let gift = BookRules.dangerStabilityGift(symbolIDs: all)

        XCTAssertGreaterThan(gift.claimed, gift.granted, "six danger runes should hit the ceiling")
        XCTAssertEqual(gift.granted, Tuning.Danger.maximumStabilityGift)

        // But the *kinds* of danger all still apply — that's the point of capping the gift rather
        // than capping the danger.
        let profile = BookRules.dangerProfile(symbolIDs: all)
        XCTAssertGreaterThan(profile.hazardTiles, 0)
        XCTAssertGreaterThan(profile.damagePerTurn, 0)
    }

    func testOneDangerRuneIsPaidInFull() {
        // The cap must not bite on ordinary play, or the headline stops meaning what it says.
        for rune: SymbolID in ["storm", "blight", "swarm_rune", "predation", "miasma_rune", "tremor"] {
            XCTAssertEqual(BookRules.dangerCapShortfall(symbolIDs: [rune]), 0,
                           "\(rune.rawValue) alone was short-changed")
        }
    }

    func testASymbolStillMovesTheHeadlineByItsPrintedNumber() throws {
        // Aimee's rule, and the cap is the single exception to it. Everything else must still sum.
        for symbol in ContentCatalog.shared.symbols where symbol.danger == nil {
            let alone = BookRules.stabilityScore(delta: BookRules.stabilityDelta(symbolIDs: [symbol.id]))
            XCTAssertEqual(alone, BookRules.stabilityScore(delta: symbol.stabilityDelta),
                           "\(symbol.id.rawValue) didn't move the meter by its printed number")
        }
    }

    /// The shortfall has to be *visible*. Hidden non-linearity is the failure mode the spec calls
    /// out for stacking contradictions, and the same reasoning applies here.
    func testThePreviewReportsWhatTheCapWithheld() {
        var draft = BookDraft()
        draft.slots = ["quirk": "tremor", "bounty": "rich_ore"]
        let projection = BookProjection.project(draft: draft, ownedSymbols: [], seed: 1)
        XCTAssertEqual(projection.dangerCapShortfall,
                       BookRules.dangerCapShortfall(symbolIDs: ["tremor", "rich_ore"]))
    }

    // MARK: Danger expressed in the world

    func testSwarmAndPredationPullAgainstEachOther() {
        let swarm = BookRules.dangerProfile(symbolIDs: ["swarm_rune"])
        let predation = BookRules.dangerProfile(symbolIDs: ["predation"])

        XCTAssertGreaterThan(swarm.spawnMultiplier, 1)
        XCTAssertLessThan(swarm.tierDelta, 0)
        XCTAssertLessThan(predation.spawnMultiplier, 1)
        XCTAssertGreaterThan(predation.tierDelta, 0)

        // Written together they should partly cancel rather than one simply winning.
        let both = BookRules.dangerProfile(symbolIDs: ["swarm_rune", "predation"])
        XCTAssertLessThan(both.spawnMultiplier, swarm.spawnMultiplier)
        XCTAssertGreaterThan(both.spawnMultiplier, predation.spawnMultiplier)
        XCTAssertEqual(both.tierDelta, swarm.tierDelta + predation.tierDelta)
    }

    func testSwarmPutsMoreThingsOnTheGridThanPredation() {
        func count(_ quirk: SymbolID, seed: UInt64) -> Int {
            let book = BoundBook(symbols: ["quirk": quirk], randomlyFilled: [], essencePaid: 0)
            return Worldgen.generate(book: book, seed: seed).enemies.count
        }
        let swarmier = (UInt64(1)...40).filter { count("swarm_rune", seed: $0) > count("predation", seed: $0) }
        XCTAssertGreaterThan(swarmier.count, 30, "Swarm should reliably out-populate Predation")
    }

    func testStormAndTremorPutHazardsOnTheGroundBeforeAnythingCrumbles() {
        for quirk: SymbolID in ["storm", "tremor"] {
            let book = BoundBook(symbols: ["quirk": quirk], randomlyFilled: [], essencePaid: 0)
            let world = Worldgen.generate(book: book, seed: 4242)
            let hazards = world.map.tiles.count { $0.content == .hazard }
            XCTAssertGreaterThan(hazards, 0, "\(quirk.rawValue) placed no hazards")
            // Never on the doorstep — arriving into damage isn't a trade, it's a mugging.
            for point in world.map.allPoints where world.map[point].content == .hazard {
                XCTAssertGreaterThanOrEqual(point.chebyshevDistance(to: world.start),
                                            Tuning.World.enemyFreeRadiusAroundEntry)
            }
        }
    }

    @MainActor
    func testMiasmaCostsYouHealthEveryTurn() {
        let store = GameStore(io: .temporary(name: "danger-\(UUID().uuidString)"))
        store.mutate("test: fund") { $0.base.essence = 500 }
        store.write("miasma_rune")
        store.bindAndDepart()

        guard let run = store.state.worlds.activeRun else { return XCTFail("couldn't depart") }
        let before = run.binderHP
        guard let step = run.map.neighbours(of: run.playerPosition)
            .first(where: { WorldRules.canEnter($0, in: run.map) })
        else { return XCTFail("nowhere to step") }

        store.step(to: step)
        XCTAssertLessThan(store.state.worlds.activeRun?.binderHP ?? before, before,
                          "the air was supposed to be against you")
    }

    @MainActor
    func testAPeacefulWorldIsQuieterThanADangerousOne() {
        func enemies(_ quirk: SymbolID) -> Int {
            let book = BoundBook(symbols: ["quirk": quirk], randomlyFilled: [], essencePaid: 0)
            return (UInt64(1)...30).reduce(0) { $0 + Worldgen.generate(book: book, seed: $1).enemies.count }
        }
        XCTAssertLessThan(enemies("peace"), enemies("swarm_rune"))
    }

    // MARK: Content

    func testEveryDangerRuneTradesInBothDirections() {
        for symbol in ContentCatalog.shared.symbols {
            guard let danger = symbol.danger else { continue }
            if danger.isCalming {
                XCTAssertLessThan(symbol.stabilityDelta, 0,
                                  "\(symbol.id.rawValue) calms the world and costs nothing")
            } else {
                XCTAssertGreaterThan(symbol.stabilityDelta, 0,
                                     "\(symbol.id.rawValue) adds danger and buys no time — a strict downgrade")
                let expresses = danger.hazardTiles > 0 || danger.damagePerTurn > 0
                    || danger.spawnMultiplier != 1 || danger.tierDelta != 0
                XCTAssertTrue(expresses, "\(symbol.id.rawValue) claims to be dangerous but does nothing")
            }
        }
    }
}
