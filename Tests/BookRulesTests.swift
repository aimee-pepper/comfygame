import XCTest
@testable import Bookbinder

/// The legibility pillar, tested: what the Writing Desk promises is what the bind delivers.
final class BookRulesTests: XCTestCase {

    // MARK: Preview matches reality

    /// The whole point of the preview: **the number you are shown is the number you get.**
    ///
    /// It used to be about a "fully specified" book — every slot chosen, nothing left to chance —
    /// and slots are gone (`fossil-audit.md` §4–5). What replaced them is better: a page always
    /// costs exactly what it says, because the price is the ink and the marks, both of which are on
    /// the table in front of you.
    func testTheProjectionMatchesTheBoundBookExactly() throws {
        let page = try page(["caverns", "ashen", "rich_ore", "gilded_veins"])
        let projection = BookProjection.project(page: page)
        XCTAssertTrue(projection.essenceCost.isPoint, "The price of a book is exact before committing")

        let book = BookRules.resolveBook(page: page)
        XCTAssertEqual(book.essencePaid, projection.essenceCost.lowerBound)
        XCTAssertEqual(BookRules.enemyTier(of: book), projection.enemyTier.lowerBound)
        XCTAssertTrue(projection.stabilityScore.contains(BookRules.stabilityScore(of: book)))
    }

    /// **Under-specification is a subject you said nothing about**, and the band the player is
    /// shown has to hold whatever gets rolled into that silence.
    ///
    /// The page version of the old "every possible random fill lands inside the projected range".
    /// The price stays exact — ink is charged by the cell, and silence has no cells — while what
    /// the world turns out to be does not.
    func testWhatIsRolledIntoTheSilenceLandsInsideTheBand() throws {
        let sparse = try page(["dim_sky"])
        let projection = BookProjection.project(page: sparse)
        XCTAssertFalse(projection.isFullySpecified, "one mark can't speak to eight subjects")
        XCTAssertTrue(projection.essenceCost.isPoint, "The price of a book is exact before committing")

        let book = BookRules.resolveBook(page: sparse)
        for seed in (0..<200).map({ UInt64($0) &* 2_654_435_761 }) {
            XCTAssertEqual(BookRules.resolveBook(page: sparse).essencePaid,
                           projection.essenceCost.lowerBound,
                           "the silence changed the price")
            let sigils = BookRules.sigils(for: book)
            let filled = sigils + PressureRules.rollUnwritten(after: sigils, seed: seed)
            let score = BookRules.stabilityScore(
                delta: BookRules.stabilityDelta(of: book, sigils: filled,
                                                contradictionPenalty: BookRules.contradictionPenalty(of: book)))
            XCTAssertTrue(projection.stabilityScore.contains(score),
                          "Stability \(score) escaped \(projection.stabilityScore)")
        }
    }

    /// **Chance reaches past what you know.** A subject you said nothing about can be filled with a
    /// word you have never learned, which is the whole reason under-specification is a surprise
    /// rather than an error.
    func testTheSilenceCanBeFilledWithSomethingYouCouldNotHaveWritten() throws {
        let starters = Set(ContentCatalog.shared.starterSourceIDs)
        var reachedBeyond = false
        for seed in (0..<80).map({ UInt64($0) &* 2_654_435_761 }) {
            let rolled = PressureRules.rollUnwritten(after: [], seed: seed)
            if rolled.contains(where: { !starters.contains($0.source) }) { reachedBeyond = true; break }
        }
        XCTAssertTrue(reachedBeyond, "chance can only ever hand back words you already had")
    }

    /// …but you can only *deliberately* write what you've learned.
    func testYouCanOnlyWriteWhatYouOwn() {
        let catalogue = Set(ContentCatalog.shared.pressureSources.map(\.id))
        let starters = Set(ContentCatalog.shared.starterSourceIDs)
        XCTAssertLessThan(starters.count, catalogue.count,
                          "if you start knowing every word, the vocabulary isn't a progression")
    }

    // MARK: The risk/reward dial

    /// The core tension: a greedier book must be more expensive, more dangerous, and shorter-lived.
    func testGreedierBooksCostMoreAndLastLess() throws {
        let calmProjection = BookProjection.project(
            page: try page(["plains", "frostbound", "sparse_ore", "dim_sky"]))
        let greedyProjection = BookProjection.project(
            page: try page(["caverns", "ashen", "rich_ore", "gilded_veins"]))

        XCTAssertLessThan(calmProjection.essenceCost.lowerBound, greedyProjection.essenceCost.lowerBound)
        XCTAssertGreaterThan(calmProjection.stabilityScore.lowerBound, greedyProjection.stabilityScore.lowerBound)
        XCTAssertGreaterThan(calmProjection.turnsUntilCollapse.lowerBound, greedyProjection.turnsUntilCollapse.lowerBound)
        XCTAssertLessThanOrEqual(calmProjection.enemyTier.upperBound, greedyProjection.enemyTier.lowerBound)
    }

    /// **The legibility rule, restated for a measured meter.**
    ///
    /// It used to be "a symbol's printed number is the number the headline moves by", and that rule
    /// died with the printed numbers (Q44): greed is measured off resolved abundance, and two
    /// symbols pushing the same subject stack with diminishing returns, so nothing is additive any
    /// more. What legibility needs instead — and what it always actually needed — is that **the
    /// number you are shown is the number you get**, and that a greedier choice reads as worse.
    func testTheHeadlineYouAreShownIsTheHeadlineYouGet() throws {
        // Deliberately mid-range, away from the 0 and 100 clamps, where the movement is visible.
        let dark = try page(["caverns", "ashen", "rich_ore", "dim_sky"])
        let before = BookRules.stabilityScore(of: BookRules.resolveBook(page: dark))
        XCTAssertGreaterThan(before, 0, "Test book must sit away from the clamps")
        XCTAssertLessThan(before, 100)

        // The preview and the bind are the same computation, so they cannot disagree.
        XCTAssertTrue(BookProjection.project(page: dark).stabilityScore.contains(before),
                      "the panel promised a headline the world doesn't honour")

        // Swapping a dim sky for a seam of gold asks the world for more, and must cost.
        let gilded = try page(["caverns", "ashen", "rich_ore", "gilded_veins"])
        let after = BookRules.stabilityScore(of: BookRules.resolveBook(page: gilded))
        XCTAssertLessThan(after, before, "trading darkness for gold has to read as the greedier book")
        XCTAssertTrue(BookProjection.project(page: gilded).stabilityScore.contains(after))
    }

    /// Aimee's case: choosing stabilising symbols should read as *clearly* stable, not as a
    /// coin-flip. Before the rescale this book came out at about 50.
    func testABookOfStabilisersReadsAsStable() throws {
        let book = BookRules.resolveBook(page: try page(["plains", "frostbound", "sparse_ore", "dim_sky"]))
        XCTAssertGreaterThan(BookRules.stabilityScore(of: book), 75,
                             "Three stabilisers should be obviously stable")
    }

    /// Stacking neutral and stabilising choices **must** be able to produce a stable world.
    /// What that costs you is elsewhere — sight, danger, yield — never the possibility.
    func testStackingNeutralAndStabilisingSymbolsReachesAStableWorld() {
        // The four calmest things the catalogue can say, whatever they happen to be — asserting
        // against a slot-by-slot sweep stopped being possible when slots went.
        let calmest = ContentCatalog.shared.symbols
            .map { (id: $0.id, delta: BookRules.stabilityDelta(ofSymbolAlone: $0.id)) }
            .sorted { $0.delta > $1.delta }
            .prefix(4)
        let best = BookRules.stabilityScore(delta: calmest.reduce(0) { $0 + $1.delta })
        XCTAssertEqual(best, 100, "A careful writer can hold a world open indefinitely")
    }

    /// …and the world they get for it is not empty. A stable world pays elsewhere: in the dark, or
    /// in what lives there. Collapsing every trade onto one axis is the failure this guards against.
    func testAStableWorldStillCostsSomethingElse() throws {
        let page = try page(["plains", "frostbound", "sparse_ore", "dim_sky"])
        let projection = BookProjection.project(page: page)
        XCTAssertEqual(BookRules.stabilityScore(of: BookRules.resolveBook(page: page)), 100)

        // It still yields things…
        XCTAssertFalse(projection.resourceMix.filter { $0.share > 0.05 }.isEmpty,
                       "A stable world is not an empty one")
        // …and it charges for the privilege somewhere else.
        let plainSight = Tuning.World.baseVisionRadius
            + (ContentCatalog.shared.symbol("plains")?.visionDelta ?? 0)
        XCTAssertLessThan(projection.visionRadius.upperBound, plainSight,
                          "Dim Sky's stability is bought with sight")
        XCTAssertGreaterThan(projection.enemyTier.lowerBound, Tuning.World.baseEnemyTier,
                             "…and with what hunts there")
    }

    // MARK: Stability is measured in steps

    /// Aimee's curve: stability isn't an abstract rate, it's how many moves you get. **The bands
    /// are deliberate cliffs**, so a player has thresholds to aim for rather than a gradient to
    /// squint at — and there's a floor, because a greedy world should be dangerous rather than
    /// pointless.
    func testStabilityScoreConvertsToTurnsOnTheAgreedCurve() {
        let floor = Tuning.World.minimumTurnsPerRun
        XCTAssertEqual(BookRules.turnsAvailable(stabilityScore: 0), floor,
                       "even the most reckless book buys a day and a walk across")
        XCTAssertEqual(BookRules.turnsAvailable(stabilityScore: 25), floor)
        XCTAssertEqual(BookRules.turnsAvailable(stabilityScore: 26), 91)
        XCTAssertEqual(BookRules.turnsAvailable(stabilityScore: 50), 175)
        XCTAssertEqual(BookRules.turnsAvailable(stabilityScore: 51), 255)
        XCTAssertEqual(BookRules.turnsAvailable(stabilityScore: 75), 375)
        XCTAssertEqual(BookRules.turnsAvailable(stabilityScore: 76), 532)
        XCTAssertEqual(BookRules.turnsAvailable(stabilityScore: 100), Tuning.World.indefiniteTurns,
                       "Full stability is explorable indefinitely")
    }

    /// Every band boundary is a real step up, or there's no threshold worth aiming for.
    func testEachBandIsACliff() {
        for edge in [26, 51, 76] {
            let below = BookRules.turnsAvailable(stabilityScore: edge - 1)
            let above = BookRules.turnsAvailable(stabilityScore: edge)
            XCTAssertGreaterThan(above, below + 20, "crossing into \(edge) barely bought anything")
        }
    }

    /// **Every world sees a nightfall.** Below the floor the whole day/night system and the
    /// nocturnal roster were invisible on exactly the worlds most likely to be interesting.
    func testEvenTheWorstWorldSeesOneNight() {
        XCTAssertGreaterThan(BookRules.turnsAvailable(stabilityScore: 0),
                             Tuning.DayNight.turnsPerDay)
    }

    /// The meter has to empty exactly when the book said it would — the preview promises a number
    /// of turns, and the world has to honour it.
    func testTheMeterEmptiesExactlyOverThePromisedTurns() {
        for score in [5, 10, 25, 26, 50, 75, 90] {
            let turns = BookRules.turnsAvailable(stabilityScore: score)
            let decay = Tuning.World.startingStability / Double(turns)
            XCTAssertEqual(BookRules.turnsUntilCollapse(decayPerTurn: decay), turns,
                           "Score \(score) promised \(turns) turns")
        }
    }

    /// The point of the curve: how far you can explore is a decision you make at the desk.
    func testTheSymbolSetSpansUnexplorableToNearlyComplete() throws {
        let tiles = Tuning.World.gridWidth * Tuning.World.gridHeight
        let calmTurns = BookRules.turnsAvailable(
            for: BookRules.resolveBook(page: try page(["plains", "frostbound", "sparse_ore", "dim_sky"])))
        let greedyTurns = BookRules.turnsAvailable(
            for: BookRules.resolveBook(page: try page(["caverns", "ashen", "rich_ore", "gilded_veins"])))

        XCTAssertGreaterThan(calmTurns, tiles / 2, "A stabilised book should reach most of the map")
        // Measured as a *span*, not against an absolute floor: a greedy world is dangerous rather
        // than pointless now, so what it costs you is most of the map, not the trip itself.
        XCTAssertLessThan(greedyTurns * 3, calmTurns,
                          "A gold-hungry book barely costs you anything")
    }

    func testMixesAreNormalisedAndSorted() {
        let projection = BookProjection.project(page: Page(), seed: 4242)

        let resourceTotal = projection.resourceMix.reduce(0) { $0 + $1.share }
        XCTAssertEqual(resourceTotal, 1.0, accuracy: 0.001)
        XCTAssertEqual(projection.resourceMix.map(\.share), projection.resourceMix.map(\.share).sorted(by: >))

    }

    /// Symbols steer the world's contents, not just its numbers (acceptance criterion: two books
    /// must produce visibly different worlds).
    func testSymbolsShiftTheHarvestAndEnemyMix() throws {
        let ore = try page(["rich_ore"])
        let life = try page(["teeming_life"])

        // Averaged over seeds, because seven subjects are still silent and a single seed measures
        // the roll rather than the rule.
        var oreShare = 0.0, lifeOreShare = 0.0
        for seed in UInt64(1)...40 {
            oreShare += share(of: Resources.ore, in: BookProjection.project(page: ore, seed: seed))
            lifeOreShare += share(of: Resources.ore, in: BookProjection.project(page: life, seed: seed))
        }
        XCTAssertGreaterThan(oreShare, lifeOreShare, "Rich Ore must actually mean more ore")

        // The preview no longer lists a roster — worlds grow their own animals — so the claim is
        // the acceptance criterion itself: two books must produce visibly different worlds, which
        // now means different animals rather than a different mix of the same three.
        let lifeWorld = Worldgen.generate(book: BookRules.resolveBook(page: life), seed: 7)
        let oreWorld = Worldgen.generate(book: BookRules.resolveBook(page: ore), seed: 7)
        XCTAssertNotEqual(lifeWorld.cast.map(\.traits), oreWorld.cast.map(\.traits),
                          "Teeming Life and Rich Ore grew exactly the same animals")
        // Measured over seeds, not on one: seven subjects are still silent on both pages, and a
        // single seed can roll the ore world a richer vitality than the one you *wrote*.
        var lifeKinds = 0, oreKinds = 0
        for seed in UInt64(1)...25 {
            lifeKinds += Worldgen.generate(book: BookRules.resolveBook(page: life), seed: seed).cast.count
            oreKinds += Worldgen.generate(book: BookRules.resolveBook(page: ore), seed: seed).cast.count
        }
        XCTAssertGreaterThan(lifeKinds, oreKinds, "Teeming Life must mean more life")
    }

    private func share(of resource: ResourceID, in projection: BookProjection) -> Double {
        projection.resourceMix.first { $0.resource.id == resource }?.share ?? 0
    }

    // MARK: Binding

    @MainActor
    func testBindingSpendsEssenceAndStartsTheRun() {
        let store = GameStore(io: .temporary(name: "bind-\(UUID().uuidString)"))
        defer { SaveFileIO.temporary(name: "unused").deleteEverything() }

        store.write("caverns")
        store.write("frostbound")
        store.write("sparse_ore")
        store.write("dim_sky")

        let essenceBefore = store.state.base.essence
        let quoted = store.bookProjection.essenceCost
        XCTAssertTrue(quoted.isPoint)

        XCTAssertTrue(store.bindAndDepart())

        let run = try? XCTUnwrap(store.state.worlds.activeRun)
        XCTAssertEqual(store.state.base.essence, essenceBefore - quoted.lowerBound,
                       "The player is charged exactly what the desk quoted")
        XCTAssertEqual(run?.book.essencePaid, quoted.lowerBound)
        XCTAssertEqual(run?.stability, Tuning.World.startingStability)
        XCTAssertEqual(store.state.reality.lifetime.runsStarted, 1)
        XCTAssertFalse(store.canBindAndDepart, "Can't bind a second book while already in a world")
    }

    @MainActor
    func testBindingIsRefusedWhenTheWorstCaseIsUnaffordable() {
        let store = GameStore(io: .temporary(name: "poor-\(UUID().uuidString)"))
        store.mutate("go broke") { $0.base.essence = 0 }

        XCTAssertFalse(store.canBindAndDepart)
        XCTAssertFalse(store.bindAndDepart())
        XCTAssertNil(store.state.worlds.activeRun)
    }

    /// A half-written page is state like any other: it survives a kill.
    @MainActor
    func testAHalfWrittenPageSurvivesRelaunch() {
        let io = SaveFileIO.temporary(name: "draft-\(UUID().uuidString)")
        defer { io.deleteEverything() }

        let first = GameStore(io: io)
        first.write("archipelago")
        first.write("verdant")
        first.flushNow()

        let second = GameStore(io: io)
        let written = Set(second.state.base.page.runes.compactMap(\.symbolID))
        XCTAssertTrue(written.contains("archipelago"))
        XCTAssertTrue(written.contains("verdant"))
        XCTAssertFalse(written.contains("rich_ore"), "marks nobody wrote arrived anyway")
    }

    /// Writes symbols onto a blank page, failing the test rather than silently producing a blank.
    private func page(_ ids: [SymbolID]) throws -> Page {
        var page = Page()
        for id in ids {
            let symbol = try XCTUnwrap(ContentCatalog.shared.symbol(id), "no symbol '\(id.rawValue)'")
            page = try XCTUnwrap(PageRules.placeAnywhere(symbol, hand: .refined, on: page),
                                 "'\(id.rawValue)' wouldn't fit")
        }
        return page
    }

    /// The Spring is credited by an action, never by elapsed time.
    @MainActor
    func testEssenceSpringPaysOnReturnHome() {
        let store = GameStore(io: .temporary(name: "spring-\(UUID().uuidString)"))
        store.write("plains")
        store.bindAndDepart()

        let essenceInWorld = store.state.base.essence
        // You arrive standing on a portal, so coming straight home is one tap.
        XCTAssertTrue(store.canPortalHere, "The entry tile is a portal you can leave through")
        store.portalHome()

        XCTAssertEqual(store.state.base.essence, essenceInWorld + store.essenceSpringYield)
        XCTAssertGreaterThan(store.essenceSpringYield, 0, "Tier 1 of the Spring is built into the base")
    }
}
