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
        let bare = BookRules.dangerTradeDelta(symbolIDs: ["rich_ore"])
        let stormy = BookRules.dangerTradeDelta(symbolIDs: ["rich_ore", "storm"])
        XCTAssertGreaterThan(stormy, bare, "a danger rune has to buy time or it has no purpose")
    }

    func testPeaceSpendsStabilityToBuyCalm() {
        let bare = BookRules.dangerTradeDelta(symbolIDs: ["plains"])
        let peaceful = BookRules.dangerTradeDelta(symbolIDs: ["plains", "peace"])
        XCTAssertLessThan(peaceful, bare, "Peace is not a free upgrade — it costs the world time")

        let profile = BookRules.dangerProfile(symbolIDs: ["peace"])
        XCTAssertLessThan(profile.spawnMultiplier, 1, "Peace should thin the inhabitants")
        XCTAssertLessThan(profile.tierDelta, 0, "Peace should make what's left milder")
        XCTAssertTrue(profile.isCalming)
    }

    /// The greedy world the release valve exists for: unwritable without danger, writable with it.
    func testDangerMakesAGreedyWorldSurvivable() {
        // **Whole books**, because the trade only means anything against something to trade against:
        // greed is measured now, so a book judged on its authored numbers alone is a book with no
        // greed in it at all, and both sides came out at a hundred.
        let greedy = BoundBook(written: ["rich_ore", "teeming_life"], essencePaid: 0)
        let bought = BoundBook(written: ["rich_ore", "teeming_life", "predation", "tremor"],
                               essencePaid: 0)

        let bareTurns = BookRules.turnsAvailable(for: greedy)
        let boughtTurns = BookRules.turnsAvailable(for: bought)
        XCTAssertLessThan(BookRules.stabilityScore(of: greedy), 60,
                          "the greedy book has to be in real trouble, or there is nothing to buy")

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

    /// **A symbol with no danger block moves the meter only by what it asks the world for** (Q44).
    ///
    /// This replaces "a symbol moves the headline by exactly its printed number". There is no
    /// printed number any more: greed is measured off the expansion, and the only thing a symbol may
    /// still assert by hand is a danger trade. So an ordinary symbol's whole effect on the headline
    /// has to *be* its greed, with nothing added beside it.
    func testAnOrdinarySymbolMovesTheMeterOnlyByWhatItAsksFor() throws {
        for symbol in ContentCatalog.shared.symbols where symbol.danger == nil {
            XCTAssertEqual(BookRules.stabilityDelta(ofSymbolAlone: symbol.id),
                           BookRules.greedDelta(for: BookRules.sigils(of: symbol)),
                           "\(symbol.id.rawValue) moves the meter by something other than its own demand")
        }
    }

    /// **No symbol may assert greed by hand.** The structural half of Q44's answer: the split is
    /// enforceable rather than remembered, because there is nowhere left to type the number.
    ///
    /// Written as a test rather than left to the compiler because the *point* is the invariant, and
    /// a future `stabilityDelta` would be added back for a reason that seemed good at the time.
    func testTheOnlyHandAuthoredStabilityIsADangerTrade() throws {
        let json = try XCTUnwrap(Bundle.contentBundle.url(forResource: "symbols", withExtension: "json"))
        let raw = try JSONSerialization.jsonObject(with: Data(contentsOf: json))
        let entries = try XCTUnwrap((raw as? [String: Any])?["symbols"] as? [[String: Any]])
        XCTAssertEqual(entries.count, ContentCatalog.shared.symbols.count)

        for entry in entries {
            let id = entry["id"] as? String ?? "?"
            XCTAssertNil(entry["stabilityDelta"],
                         "\(id) carries a hand-typed greed number; greed is measured (answer-q44.md §1)")
            if let danger = entry["danger"] as? [String: Any] {
                XCTAssertNotNil(danger["stabilityTrade"],
                                "\(id) has a danger block with no trade — it accepts hostility and buys nothing")
            }
        }
    }

    /// The fault Q44 was asked to check for, expressed so it cannot come back: **nothing may be
    /// charged twice for one sin.** A symbol's authored trade and its measured greed must never both
    /// be large and pointing the same way — that combination is the double-charge by definition.
    func testNothingIsChargedTwiceForOneSin() {
        for symbol in ContentCatalog.shared.symbols {
            let trade = symbol.danger?.stabilityTrade ?? 0
            let greed = BookRules.greedDelta(for: BookRules.sigils(of: symbol))
            let bothLarge = abs(trade) >= 10 && abs(greed) >= 10
            XCTAssertFalse(bothLarge && (trade < 0) == (greed < 0),
                           "\(symbol.id.rawValue) is charged twice: trade \(trade), greed \(greed)")
        }
    }

    /// The shortfall has to be *visible*. Hidden non-linearity is the failure mode the spec calls
    /// out for stacking contradictions, and the same reasoning applies here.
    func testThePreviewReportsWhatTheCapWithheld() {
        var page = Page()
        for id in ["tremor", "rich_ore"] as [SymbolID] {
            guard let symbol = ContentCatalog.shared.symbol(id),
                  let placed = PageRules.placeAnywhere(symbol, hand: .refined, on: page)
            else { return XCTFail("couldn't write \(id.rawValue)") }
            page = placed
        }
        let projection = BookProjection.project(page: page, seed: 1)
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
        // Counted in total rather than seed by seed. Population is an integer, so on small worlds
        // the two books round to the same number often enough that a strict per-seed comparison
        // measures rounding rather than the spawn multiplier.
        var swarmTotal = 0, predationTotal = 0, fewer = 0
        for seed in UInt64(1)...40 {
            let a = count("swarm_rune", seed: seed), b = count("predation", seed: seed)
            swarmTotal += a
            predationTotal += b
            if a < b { fewer += 1 }
        }
        XCTAssertGreaterThan(swarmTotal, predationTotal, "Swarm should out-populate Predation")
        XCTAssertLessThan(fewer, 8, "Swarm came out thinner than Predation too often")
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
                XCTAssertLessThan(danger.stabilityTrade, 0,
                                  "\(symbol.id.rawValue) calms the world and costs nothing")
            } else {
                XCTAssertGreaterThan(danger.stabilityTrade, 0,
                                     "\(symbol.id.rawValue) adds danger and buys no time — a strict downgrade")
                let expresses = danger.hazardTiles > 0 || danger.damagePerTurn > 0
                    || danger.spawnMultiplier != 1 || danger.tierDelta != 0
                XCTAssertTrue(expresses, "\(symbol.id.rawValue) claims to be dangerous but does nothing")
            }
        }
    }
}
