import XCTest
@testable import Bookbinder

/// The legibility pillar, tested: what the Writing Desk promises is what the bind delivers.
final class BookRulesTests: XCTestCase {

    private let owned = Set(ContentCatalog.shared.starterSymbolIDs)

    // MARK: Preview matches reality

    /// The whole point of the preview. A fully-specified book's projection must equal what you
    /// actually get charged and what the world actually decays at.
    func testFullySpecifiedProjectionMatchesTheBoundBookExactly() {
        var draft = BookDraft()
        draft["terrain"] = "caverns"
        draft["biome"] = "ashen"
        draft["bounty"] = "rich_ore"
        draft["quirk"] = "gilded_veins"

        let projection = BookProjection.project(draft: draft, ownedSymbols: owned)
        XCTAssertTrue(projection.isFullySpecified)
        XCTAssertTrue(projection.essenceCost.isPoint, "Nothing is left to chance, so nothing is a range")

        // Every seed must give the same book, because no slot is random.
        for seed in [UInt64(1), 999, 123_456_789] {
            let book = BookRules.resolveBook(draft: draft, ownedSymbols: owned, seed: seed)
            XCTAssertEqual(book.essencePaid, projection.essenceCost.lowerBound)
            XCTAssertEqual(BookRules.enemyTier(of: book), projection.enemyTier.lowerBound)
            XCTAssertEqual(BookRules.stabilityScore(of: book),
                           projection.stabilityScore.lowerBound)
            XCTAssertTrue(book.randomlyFilled.isEmpty)
        }
    }

    /// An under-specified book must land inside the range the player was shown — for every
    /// possible random fill, not just the one we happened to roll.
    func testEveryPossibleRandomFillLandsInsideTheProjectedRange() {
        let draft = BookDraft() // nothing chosen: maximum uncertainty
        let projection = BookProjection.project(draft: draft, ownedSymbols: owned)
        XCTAssertFalse(projection.isFullySpecified)
        // Cost is the one thing an unfilled slot does NOT widen: a slot left to chance costs a
        // flat rate whatever rolls into it (decisions-log session 2). The world stays uncertain;
        // the price does not.
        XCTAssertTrue(projection.essenceCost.isPoint, "The price of a book is exact before committing")
        XCTAssertFalse(projection.stabilityScore.isPoint, "…but what you get for it is not")

        for seed in (0..<200).map({ UInt64($0) &* 2_654_435_761 }) {
            let book = BookRules.resolveBook(draft: draft, ownedSymbols: owned, seed: seed)
            XCTAssertTrue(projection.essenceCost.contains(book.essencePaid),
                          "Cost \(book.essencePaid) escaped \(projection.essenceCost)")
            XCTAssertTrue(projection.enemyTier.contains(BookRules.enemyTier(of: book)))
            let score = BookRules.stabilityScore(of: book)
            XCTAssertTrue(projection.stabilityScore.contains(score),
                          "Stability \(score) escaped \(projection.stabilityScore)")
            let turns = BookRules.turnsAvailable(for: book)
            XCTAssertTrue(projection.turnsUntilCollapse.contains(turns),
                          "Turns \(turns) escaped \(projection.turnsUntilCollapse)")
        }
    }

    func testChosenSymbolsAreNeverOverwrittenByRandomFill() {
        var draft = BookDraft()
        draft["quirk"] = "dim_sky"

        for seed in (0..<50).map({ UInt64($0) &* 7_919 }) {
            let book = BookRules.resolveBook(draft: draft, ownedSymbols: owned, seed: seed)
            XCTAssertEqual(book.symbols["quirk"], "dim_sky")
            XCTAssertFalse(book.randomlyFilled.contains("quirk"))
        }
    }

    /// Every slot gets filled, whatever the player knows. A beginner's book is *more* of a
    /// gamble than an expert's, not a smaller one — they simply have less say in it.
    func testEverySlotIsFilledEvenForABeginner() {
        let onlyTerrain: Set<SymbolID> = ["plains"]
        let book = BookRules.resolveBook(draft: BookDraft(), ownedSymbols: onlyTerrain, seed: 5)

        XCTAssertEqual(book.allSymbolIDs.count, ContentCatalog.shared.slotIDsInOrder.count,
                       "Chance fills what you couldn't")
        XCTAssertEqual(book.randomlyFilled.count, ContentCatalog.shared.slotIDsInOrder.count)
    }

    /// Chance is not a shuffle. A slot left open can hand you a symbol you never learned — which
    /// is the whole reason under-specification is a surprise rather than an error.
    func testChanceCanFillASlotWithSomethingYouDoNotOwn() {
        let onlyPlains: Set<SymbolID> = ["plains"]
        var seenUnowned = false
        for seed in (0..<80).map({ UInt64($0) &* 2_654_435_761 }) {
            let book = BookRules.resolveBook(draft: BookDraft(), ownedSymbols: onlyPlains, seed: seed)
            if book.allSymbolIDs.contains(where: { !onlyPlains.contains($0) }) { seenUnowned = true; break }
        }
        XCTAssertTrue(seenUnowned, "A chance-filled slot must be able to reach beyond what you know")
    }

    /// …but you can only *deliberately* write what you've learned.
    func testYouCanOnlyChooseWhatYouOwn() {
        let onlyPlains: Set<SymbolID> = ["plains"]
        for slot in ContentCatalog.shared.slotIDsInOrder {
            for symbol in BookRules.writable(in: slot, ownedSymbols: onlyPlains) {
                XCTAssertTrue(onlyPlains.contains(symbol.id))
            }
        }
    }

    // MARK: The risk/reward dial

    /// The core tension: a greedier book must be more expensive, more dangerous, and shorter-lived.
    func testGreedierBooksCostMoreAndLastLess() {
        var calm = BookDraft()
        calm["terrain"] = "plains"
        calm["biome"] = "frostbound"
        calm["bounty"] = "sparse_ore"
        calm["quirk"] = "dim_sky"

        var greedy = BookDraft()
        greedy["terrain"] = "caverns"
        greedy["biome"] = "ashen"
        greedy["bounty"] = "rich_ore"
        greedy["quirk"] = "gilded_veins"

        let calmProjection = BookProjection.project(draft: calm, ownedSymbols: owned)
        let greedyProjection = BookProjection.project(draft: greedy, ownedSymbols: owned)

        XCTAssertLessThan(calmProjection.essenceCost.lowerBound, greedyProjection.essenceCost.lowerBound)
        XCTAssertGreaterThan(calmProjection.stabilityScore.lowerBound, greedyProjection.stabilityScore.lowerBound)
        XCTAssertGreaterThan(calmProjection.turnsUntilCollapse.lowerBound, greedyProjection.turnsUntilCollapse.lowerBound)
        XCTAssertLessThanOrEqual(calmProjection.enemyTier.upperBound, greedyProjection.enemyTier.lowerBound)
    }

    /// The legibility rule, pinned: **a symbol's printed number is the number the headline moves
    /// by.** No conversion factor, nothing to work out. This is what makes a book something you can
    /// reason about while composing rather than after paying.
    func testASymbolMovesTheHeadlineByExactlyItsPrintedNumber() throws {
        // Deliberately mid-range, away from the 0 and 100 clamps, where the arithmetic is visible.
        var draft = BookDraft()
        draft["terrain"] = "caverns"
        draft["biome"] = "ashen"
        draft["bounty"] = "sparse_ore"
        draft["quirk"] = "dim_sky"

        let before = BookProjection.project(draft: draft, ownedSymbols: owned).stabilityScore.lowerBound

        // Swap one symbol and check the headline moves by exactly the difference printed on them.
        draft["quirk"] = "gilded_veins"
        let after = BookProjection.project(draft: draft, ownedSymbols: owned).stabilityScore.lowerBound

        let dimSky = try XCTUnwrap(ContentCatalog.shared.symbol("dim_sky")).stabilityDelta
        let gilded = try XCTUnwrap(ContentCatalog.shared.symbol("gilded_veins")).stabilityDelta
        XCTAssertEqual(after - before, gilded - dimSky)
        XCTAssertGreaterThan(before, 0, "Test book must sit away from the clamps")
        XCTAssertLessThan(before, 100)
    }

    /// Aimee's case: choosing stabilising symbols should read as *clearly* stable, not as a
    /// coin-flip. Before the rescale this book came out at about 50.
    func testABookOfStabilisersReadsAsStable() {
        var draft = BookDraft()
        draft["terrain"] = "plains"
        draft["biome"] = "frostbound"
        draft["bounty"] = "sparse_ore"
        draft["quirk"] = "dim_sky"

        let score = BookProjection.project(draft: draft, ownedSymbols: owned).stabilityScore
        XCTAssertTrue(score.isPoint)
        XCTAssertGreaterThan(score.lowerBound, 75, "Three stabilisers should be obviously stable")
    }

    /// Stacking neutral and stabilising choices **must** be able to produce a stable world.
    /// What that costs you is elsewhere — sight, danger, yield — never the possibility.
    func testStackingNeutralAndStabilisingSymbolsReachesAStableWorld() {
        var best = 0
        for terrain in ContentCatalog.shared.symbols(in: "terrain") {
            for biome in ContentCatalog.shared.symbols(in: "biome") {
                for bounty in ContentCatalog.shared.symbols(in: "bounty") {
                    for quirk in ContentCatalog.shared.symbols(in: "quirk") {
                        let delta = terrain.stabilityDelta + biome.stabilityDelta
                            + bounty.stabilityDelta + quirk.stabilityDelta
                        best = max(best, BookRules.stabilityScore(delta: delta))
                    }
                }
            }
        }
        XCTAssertEqual(best, 100, "A careful writer can hold a world open indefinitely")
    }

    /// …and the world they get for it is not empty. A stable world pays elsewhere: in the dark, or
    /// in what lives there. Collapsing every trade onto one axis is the failure this guards against.
    func testAStableWorldStillCostsSomethingElse() {
        var draft = BookDraft()
        draft["terrain"] = "plains"
        draft["biome"] = "frostbound"
        draft["bounty"] = "sparse_ore"
        draft["quirk"] = "dim_sky"

        let projection = BookProjection.project(draft: draft, ownedSymbols: owned)
        XCTAssertEqual(projection.stabilityScore.lowerBound, 100)

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
    func testTheSymbolSetSpansUnexplorableToNearlyComplete() {
        let tiles = Tuning.World.gridWidth * Tuning.World.gridHeight

        var calm = BookDraft()
        calm["terrain"] = "plains"; calm["biome"] = "frostbound"
        calm["bounty"] = "sparse_ore"; calm["quirk"] = "dim_sky"

        var greedy = BookDraft()
        greedy["terrain"] = "caverns"; greedy["biome"] = "ashen"
        greedy["bounty"] = "rich_ore"; greedy["quirk"] = "gilded_veins"

        let owned = Set(ContentCatalog.shared.starterSymbolIDs)
        let calmTurns = BookRules.turnsAvailable(for: BookRules.resolveBook(draft: calm, ownedSymbols: owned, seed: 1))
        let greedyTurns = BookRules.turnsAvailable(for: BookRules.resolveBook(draft: greedy, ownedSymbols: owned, seed: 1))

        XCTAssertGreaterThan(calmTurns, tiles / 2, "A stabilised book should reach most of the map")
        // Measured as a *span*, not against an absolute floor: a greedy world is dangerous rather
        // than pointless now, so what it costs you is most of the map, not the trip itself.
        XCTAssertLessThan(greedyTurns * 3, calmTurns,
                          "A gold-hungry book barely costs you anything")
    }

    func testMixesAreNormalisedAndSorted() {
        let projection = BookProjection.project(draft: BookDraft(), ownedSymbols: owned)

        let resourceTotal = projection.resourceMix.reduce(0) { $0 + $1.share }
        XCTAssertEqual(resourceTotal, 1.0, accuracy: 0.001)
        XCTAssertEqual(projection.resourceMix.map(\.share), projection.resourceMix.map(\.share).sorted(by: >))

    }

    /// Symbols steer the world's contents, not just its numbers (acceptance criterion: two books
    /// must produce visibly different worlds).
    func testSymbolsShiftTheHarvestAndEnemyMix() {
        var ore = BookDraft()
        ore["bounty"] = "rich_ore"
        var life = BookDraft()
        life["bounty"] = "teeming_life"

        let oreShare = share(of: Resources.ore, in: BookProjection.project(draft: ore, ownedSymbols: owned))
        let lifeOreShare = share(of: Resources.ore, in: BookProjection.project(draft: life, ownedSymbols: owned))
        XCTAssertGreaterThan(oreShare, lifeOreShare, "Rich Ore must actually mean more ore")

        // The preview no longer lists a roster — worlds grow their own animals — so the claim is
        // the acceptance criterion itself: two books must produce visibly different worlds, which
        // now means different animals rather than a different mix of the same three.
        let lifeWorld = Worldgen.generate(
            book: BookRules.resolveBook(draft: life, ownedSymbols: owned, seed: 7), seed: 7)
        let oreWorld = Worldgen.generate(
            book: BookRules.resolveBook(draft: ore, ownedSymbols: owned, seed: 7), seed: 7)
        XCTAssertNotEqual(lifeWorld.cast.map(\.traits), oreWorld.cast.map(\.traits),
                          "Teeming Life and Rich Ore grew exactly the same animals")
        XCTAssertGreaterThanOrEqual(lifeWorld.cast.count, oreWorld.cast.count,
                                    "Teeming Life must never mean less life")
    }

    private func share(of resource: ResourceID, in projection: BookProjection) -> Double {
        projection.resourceMix.first { $0.resource.id == resource }?.share ?? 0
    }

    // MARK: Binding

    @MainActor
    func testBindingSpendsEssenceAndStartsTheRun() {
        let store = GameStore(io: .temporary(name: "bind-\(UUID().uuidString)"))
        defer { SaveFileIO.temporary(name: "unused").deleteEverything() }

        store.setSymbol("caverns", in: "terrain")
        store.setSymbol("frostbound", in: "biome")
        store.setSymbol("sparse_ore", in: "bounty")
        store.setSymbol("dim_sky", in: "quirk")

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

    /// A half-composed book is state like any other: it survives a kill.
    @MainActor
    func testBookDraftSurvivesRelaunch() {
        let io = SaveFileIO.temporary(name: "draft-\(UUID().uuidString)")
        defer { io.deleteEverything() }

        let first = GameStore(io: io)
        first.setSymbol("archipelago", in: "terrain")
        first.setSymbol("verdant", in: "biome")
        first.flushNow()

        let second = GameStore(io: io)
        XCTAssertEqual(second.state.base.bookDraft["terrain"], "archipelago")
        XCTAssertEqual(second.state.base.bookDraft["biome"], "verdant")
        XCTAssertNil(second.state.base.bookDraft["bounty"])
    }

    /// The Spring is credited by an action, never by elapsed time.
    @MainActor
    func testEssenceSpringPaysOnReturnHome() {
        let store = GameStore(io: .temporary(name: "spring-\(UUID().uuidString)"))
        store.setSymbol("plains", in: "terrain")
        store.bindAndDepart()

        let essenceInWorld = store.state.base.essence
        // You arrive standing on a portal, so coming straight home is one tap.
        XCTAssertTrue(store.canPortalHere, "The entry tile is a portal you can leave through")
        store.portalHome()

        XCTAssertEqual(store.state.base.essence, essenceInWorld + store.essenceSpringYield)
        XCTAssertGreaterThan(store.essenceSpringYield, 0, "Tier 1 of the Spring is built into the base")
    }
}
