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

    /// A slot the player has no symbols for generates nothing at all, rather than crashing or
    /// silently borrowing from another slot.
    func testSlotWithNoOwnedSymbolsIsLeftUnfilled() {
        let onlyTerrain: Set<SymbolID> = ["plains"]
        let book = BookRules.resolveBook(draft: BookDraft(), ownedSymbols: onlyTerrain, seed: 5)
        XCTAssertEqual(book.symbols["terrain"], "plains")
        XCTAssertNil(book.symbols["biome"])
        XCTAssertEqual(book.allSymbolIDs.count, 1)

        let projection = BookProjection.project(draft: BookDraft(), ownedSymbols: onlyTerrain)
        XCTAssertTrue(projection.slotPlans.first { $0.slot == "biome" }?.isEmpty ?? false)
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
        var draft = BookDraft()
        draft["terrain"] = "plains"
        draft["biome"] = "verdant"
        draft["bounty"] = "sparse_ore"
        draft["quirk"] = "dim_sky"

        let before = BookProjection.project(draft: draft, ownedSymbols: owned).stabilityScore.lowerBound

        // Swap one symbol and check the headline moves by exactly the difference printed on them.
        draft["quirk"] = "gilded_veins"
        let after = BookProjection.project(draft: draft, ownedSymbols: owned).stabilityScore.lowerBound

        let dimSky = try XCTUnwrap(ContentCatalog.shared.symbol("dim_sky")).stabilityDelta
        let gilded = try XCTUnwrap(ContentCatalog.shared.symbol("gilded_veins")).stabilityDelta
        XCTAssertEqual(after - before, gilded - dimSky)
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

    /// You can only write a perfectly stable world by asking it for nothing — and then there's
    /// nothing in it. That's what keeps "indefinite" out of reach.
    func testNoWritableBookReachesIndefinite() {
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
        XCTAssertLessThan(best, 100, "Every book asks for something, and asking costs stability")
        XCTAssertGreaterThan(best, 85, "…but a careful one should still be nearly perfect")
    }

    // MARK: Stability is measured in steps

    /// Aimee's curve, pinned. Stability isn't an abstract rate — it's how many moves you get.
    /// The low end is literal; each band above multiplies.
    func testStabilityScoreConvertsToTurnsOnTheAgreedCurve() {
        XCTAssertEqual(BookRules.turnsAvailable(stabilityScore: 0), 1, "You arrive, and then it goes")
        XCTAssertEqual(BookRules.turnsAvailable(stabilityScore: 5), 5, "5% is five steps, literally")
        XCTAssertEqual(BookRules.turnsAvailable(stabilityScore: 10), 10)
        XCTAssertEqual(BookRules.turnsAvailable(stabilityScore: 25), 25)
        XCTAssertEqual(BookRules.turnsAvailable(stabilityScore: 26), 52, "Past 25 it doubles")
        XCTAssertEqual(BookRules.turnsAvailable(stabilityScore: 50), 100)
        XCTAssertEqual(BookRules.turnsAvailable(stabilityScore: 51), 153, "Past 50 it triples")
        XCTAssertEqual(BookRules.turnsAvailable(stabilityScore: 75), 225)
        XCTAssertEqual(BookRules.turnsAvailable(stabilityScore: 76), 304, "Past 75 it quadruples")
        XCTAssertEqual(BookRules.turnsAvailable(stabilityScore: 100), Tuning.World.indefiniteTurns,
                       "Full stability is explorable indefinitely")
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
        XCTAssertLessThan(greedyTurns, tiles / 8, "A gold-hungry one should barely leave the doorstep")
        XCTAssertLessThan(calmTurns, Tuning.World.indefiniteTurns,
                          "Indefinite is unreachable with v0 symbols — that's what anchoring is for")
    }

    func testMixesAreNormalisedAndSorted() {
        let projection = BookProjection.project(draft: BookDraft(), ownedSymbols: owned)

        let resourceTotal = projection.resourceMix.reduce(0) { $0 + $1.share }
        XCTAssertEqual(resourceTotal, 1.0, accuracy: 0.001)
        XCTAssertEqual(projection.resourceMix.map(\.share), projection.resourceMix.map(\.share).sorted(by: >))

        let creatureTotal = projection.creatureMix.reduce(0) { $0 + $1.share }
        XCTAssertEqual(creatureTotal, 1.0, accuracy: 0.001)
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

        let mothShare = BookProjection.project(draft: life, ownedSymbols: owned)
            .creatureMix.first { $0.creature.id == "paper_moth" }?.share ?? 0
        let baseMothShare = BookProjection.project(draft: ore, ownedSymbols: owned)
            .creatureMix.first { $0.creature.id == "paper_moth" }?.share ?? 0
        XCTAssertGreaterThan(mothShare, baseMothShare, "Teeming Life must actually mean more life")
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
