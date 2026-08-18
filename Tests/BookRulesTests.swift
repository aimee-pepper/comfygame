import XCTest
@testable import Bookbinder

/// The legibility pillar, tested: what the Writing Desk promises is what the bind delivers.
final class BookRulesTests: XCTestCase {
    func testEmptyPageResolvesToDeterministicButVariedStability() {
        let book = BookRules.resolveBook(page: Page())
        let seeds = (0..<256).map(UInt64.init)
        let scores = seeds.map { BookRules.resolvedStabilityScore(of: book, seed: $0) }

        XCTAssertEqual(BookRules.resolvedStabilityScore(of: book, seed: 42),
                       BookRules.resolvedStabilityScore(of: book, seed: 42))
        XCTAssertGreaterThan(Set(scores).count, 3,
                             "silence still resolves to one hidden stability preset")
        XCTAssertTrue(scores.contains { $0 < 76 },
                      "empty pages never reached a meaningfully unstable band")
        XCTAssertTrue(scores.contains { $0 >= 76 },
                      "chance lost the possibility of a forgiving world")
    }

    func testRawEssenceNeverConsumesCurrentOrLegacyHarvestNodeWeight() {
        let readings = PressureRules.resolve([])
        XCTAssertFalse(BookRules.yieldTable(from: readings).contains { $0.value == Resources.essenceRaw })
        let legacy = BoundBook(symbols: [:], randomlyFilled: [], essencePaid: 0)
        XCTAssertFalse(BookRules.yieldTable(for: legacy).contains { $0.value == Resources.essenceRaw })
    }

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

    func testTierFourBreakdownUsesTheSameTermsAsTheHeadline() throws {
        let page = try page(["caverns", "ashen", "rich_ore", "gilded_veins"])
        let projection = BookProjection.project(page: page,
                                                analysisTier: Tuning.Analysis.attributionTier)
        let book = BookRules.resolveBook(page: page)
        let sigils = BookRules.sigils(for: book)
        let expected = BookRules.stabilityDelta(of: book, sigils: sigils,
                                                contradictionPenalty: projection.contradictionPenalty)
        XCTAssertEqual(projection.greedStabilityDelta + projection.sizeStabilityDelta
                       + projection.dangerStabilityDelta - projection.contradictionPenalty,
                       expected)
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

    /// …and the world they get for it is not empty. A stable world pays elsewhere: here, in the
    /// dark. Collapsing every trade onto one axis is the failure this guards against.
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
    }

    func testProjectionNamesTheFullVisibilityRadiusClearSight() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let source = try String(
            contentsOf: root.appending(path: "Sources/Screens/PreviewPanel.swift"),
            encoding: .utf8
        )

        XCTAssertTrue(source.contains("StatCell(label: \"Clear sight\", value: sightText"))
        XCTAssertFalse(source.contains("StatCell(label: \"Sight\", value: sightText"),
                       "The full-radius value must not imply that the dim fringe is equally clear")
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
    func testBindingPersistsOneVisualReceiptInRunAndHistory() throws {
        let store = GameStore(io: .temporary(name: "visual-bind-\(UUID().uuidString)"))
        store.write("caverns")
        store.write("frostbound")

        XCTAssertTrue(store.bindAndDepart())

        let run = try XCTUnwrap(store.state.worlds.activeRun)
        let history = try XCTUnwrap(store.state.reality.library.visitedWorlds.last)
        let receipt = try XCTUnwrap(run.worldVisualReceipt)
        XCTAssertEqual(history.worldVisualReceipt, receipt,
                       "History and the active world must retain the same immutable visual fact")
        let restored = try JSONDecoder().decode(
            GameState.self, from: JSONEncoder().encode(store.state))
        XCTAssertEqual(restored.worlds.activeRun?.worldVisualReceipt, receipt)
        XCTAssertEqual(restored.reality.library.visitedWorlds.last?.worldVisualReceipt, receipt)
    }

    @MainActor
    func testSuccessfulBindAloneMintsIdempotentPositionFreeStatementProof() throws {
        let io = SaveFileIO.temporary(name: "compound-proof-\(UUID().uuidString)")
        defer { io.deleteEverything() }
        let store = GameStore(io: io)
        let source = try XCTUnwrap(ContentCatalog.shared.pressureSources.first).id
        let target = PlacedRune(id: .init(rawValue: 1), content: .target("illumination"),
                                hand: .crude, origin: .init(column: 0, row: 0), shapeID: "refined_dot")
        let focus = PlacedRune(id: .init(rawValue: 2), content: .source(source),
                               hand: .crude, origin: .init(column: 1, row: 0), shapeID: "refined_dot")
        store.mutate("install atomic statement") { state in
            state.base.ownedSources.insert(source)
            state.base.page = Page(runes: [target, focus], links: [MarkLink(target.id, focus.id)])
        }
        XCTAssertTrue(store.bindAndDepart())
        let receipt = try XCTUnwrap(store.state.base.provenStatementReceipts.first)
        XCTAssertEqual(store.activeRun?.book.provenStatementReceipts, [receipt])
        XCTAssertEqual(receipt.firstBoundRunIndex, 1)
        store.flushNow()
        let relaunched = GameStore(io: io)
        XCTAssertEqual(relaunched.state.base.provenStatementReceipts, [receipt])

        let failed = GameStore(io: .temporary(name: "compound-proof-fail-\(UUID().uuidString)"))
        failed.mutate("install unaffordable statement") { state in
            state.base.ownedSources.insert(source)
            state.base.page = Page(runes: [target, focus], links: [MarkLink(target.id, focus.id)])
            state.base.essence = 0
        }
        XCTAssertFalse(failed.bindAndDepart())
        XCTAssertTrue(failed.state.base.provenStatementReceipts.isEmpty)
    }

    @MainActor
    func testFormalizeRenameDeleteAreQuotedAtomicAndNeverAliasHistory() throws {
        let io = SaveFileIO.temporary(name: "compound-actions-\(UUID().uuidString)")
        defer { io.deleteEverything() }
        let store = GameStore(io: io)
        let source = try XCTUnwrap(ContentCatalog.shared.pressureSources.first).id
        let atom = CompoundSemanticAtom(Sigil(id: .init(rawValue: 1), source: source,
                                               target: "illumination"))
        let receipt = ProvenStatementReceipt(
            fingerprint: PageRules.statementFingerprint(target: "illumination", atoms: [atom]),
            target: "illumination", atoms: [atom],
            vocabulary: [.target("illumination"), .source(source)], vocabularySchemaVersion: 1,
            firstBoundRunIndex: 1)
        store.mutate("unlock and provision formalization") { state in
            state.base.completedResearch.insert("pen_compounds")
            state.base.ownedSources.insert(source)
            state.base.provenStatementReceipts = [receipt]
            state.base.essence = 100
            state.base.resources.add(20, of: Resources.pulp)
        }
        let beforeEssence = store.state.base.essence
        let beforePulp = store.state.base.resources[Resources.pulp]
        guard case .ready(let quote) = store.previewCompoundFormalization(
            fingerprint: receipt.fingerprint, nickname: "  Bright shorthand  ") else {
            return XCTFail("expected ready formalization")
        }
        XCTAssertEqual(store.formalizeCompound(quote), .formalized(.init(rawValue: 1)))
        XCTAssertEqual(store.state.base.essence,
                       beforeEssence - Tuning.Page.personalCompoundFormalizeEssence)
        XCTAssertEqual(store.state.base.resources[Resources.pulp],
                       beforePulp - Tuning.Page.personalCompoundFormalizePulp)
        let original = try XCTUnwrap(store.state.base.personalCompounds.first)
        XCTAssertEqual(original.nickname, "Bright shorthand")
        XCTAssertTrue(PageRules.isEffectEquivalent(original, to: receipt))
        XCTAssertEqual(store.formalizeCompound(quote), .stale)
        XCTAssertEqual(store.state.base.personalCompounds.count, 1)

        let placed = try XCTUnwrap(PageRules.place(original, hand: .refined,
                                                   at: .init(column: 0, row: 0), on: Page()))
        let historical = try XCTUnwrap(placed.runes.first?.personalCompound)
        let rename = try XCTUnwrap(store.previewCompoundRename(original.id, nickname: "Sunward"))
        XCTAssertEqual(store.renameCompound(rename), .renamed(original.id))
        XCTAssertEqual(historical.nickname, "Bright shorthand")
        let deletion = try XCTUnwrap(store.previewCompoundDeletion(original.id))
        XCTAssertEqual(store.deleteCompound(deletion), .deleted(original.id))
        XCTAssertTrue(store.state.base.personalCompounds.isEmpty)
        XCTAssertEqual(store.state.base.provenStatementReceipts, [receipt])

        guard case .ready(let secondQuote) = store.previewCompoundFormalization(
            fingerprint: receipt.fingerprint, nickname: "Made again") else {
            return XCTFail("expected retained proof to permit re-formalization")
        }
        XCTAssertNotEqual(secondQuote.compoundID, original.id)
        XCTAssertEqual(store.formalizeCompound(secondQuote), .formalized(secondQuote.compoundID))
        store.flushNow()
        let relaunched = GameStore(io: io)
        XCTAssertEqual(relaunched.state.base.personalCompounds.map(\.id), [secondQuote.compoundID])
        XCTAssertGreaterThan(relaunched.state.base.nextPersonalCompoundID,
                             secondQuote.compoundID.rawValue)
    }

    @MainActor
    func testVisualReceiptFailureLeavesTheEntireCampaignUnchanged() throws {
        let store = GameStore(io: .temporary(name: "visual-bind-fail-\(UUID().uuidString)"))
        store.write("caverns")
        store.write("frostbound")
        let before = store.state

        let didBind = store.bindAndDepart { _, _, _ in
            throw WorldGrade2BindAdapter.Error.missingOpenColorAuthority(.material)
        }

        XCTAssertFalse(didBind)
        XCTAssertEqual(store.state, before,
                       "A failed visual receipt must spend no Essence, seed, page, or history fact")
        XCTAssertNil(store.state.worlds.activeRun)
        XCTAssertNotNil(store.bindError)
    }

    @MainActor
    func testMixedInkRequiresPreparedApplicationsAndFreezesAuthoredWorldColor() throws {
        let store = GameStore(io: .temporary(name: "mixed-ink-bind-\(UUID().uuidString)"))
        let recipe = InkRecipe(cyan: 82, magenta: 0, yellow: 3, depth: 7)
        let sun = PlacedRune(id: .init(rawValue: 44), content: .source("sun"), hand: .plain,
                             origin: .init(column: 0, row: 0), shapeID: "plain_bar",
                             inkRecipe: recipe)
        let illumination = PlacedRune(id: .init(rawValue: 46), content: .target("illumination"),
                                      hand: .plain, origin: .init(column: 0, row: 2),
                                      shapeID: "plain_bar")
        store.mutate("test: colored Sun") { state in
            state.base.ownedHands.insert(.plain)
            state.base.completedResearch.insert("pen_ink_mixing")
            state.base.page = Page(runes: [sun, illumination],
                                   links: [MarkLink(sun.id, illumination.id)])
            state.base.essence = 500
        }
        let beforeRefusal = store.state
        XCTAssertFalse(store.bindAndDepart())
        XCTAssertEqual(store.state, beforeRefusal)
        XCTAssertTrue(store.bindError?.contains("prepare more ink") == true)

        store.mutate("test: prepared exact ink") { state in
            state.base.preparedInkVials = [
                .init(id: 1, recipe: recipe, remainingApplications: 2)
            ]
            state.base.nextPreparedInkVialID = 2
        }
        XCTAssertTrue(store.bindAndDepart())
        XCTAssertEqual(store.state.base.preparedInkVials.first?.remainingApplications, 1)
        let receipt = try XCTUnwrap(store.state.worlds.activeRun?.worldVisualReceipt)
        XCTAssertEqual(receipt.selectedSourceByScope[.emitter], sun.id)
        XCTAssertEqual(receipt.request.resolvedColors.emitter?.provenance, "authoredMix")
        XCTAssertEqual(store.state.reality.library.visitedWorlds.last?.worldVisualReceipt, receipt)
    }

    @MainActor
    func testUnsupportedMixedInkSourceFailsBeforeSpendingAnything() {
        let store = GameStore(io: .temporary(name: "unsupported-ink-bind-\(UUID().uuidString)"))
        let recipe = InkRecipe(cyan: 50, magenta: 0, yellow: 50, depth: 0)
        let plains = PlacedRune(id: .init(rawValue: 45), content: .source("plains"), hand: .plain,
                                origin: .init(column: 0, row: 0), shapeID: "plain_bar",
                                inkRecipe: recipe)
        store.mutate("test: unsupported colored source") { state in
            state.base.page = Page(runes: [plains])
            state.base.essence = 500
            state.base.preparedInkVials = [
                .init(id: 1, recipe: recipe, remainingApplications: 12)
            ]
        }
        let before = store.state
        XCTAssertFalse(store.bindAndDepart())
        XCTAssertEqual(store.state, before)
        XCTAssertNil(store.state.worlds.activeRun)
    }

    @MainActor
    func testBornAnchoredBindingPaysThePreviewedPremiumAndKeepsTheRealm() throws {
        let store = GameStore(io: .temporary(name: "anchor-bind-\(UUID().uuidString)"))
        store.mutate("prepare anchorage") { state in
            state.base.stations[Stations.anchorage] = StationState(isUnlocked: true, tier: 0)
            state.base.essence = 1_000
        }
        let essenceBefore = store.state.base.essence
        let total = store.bookProjection.cost + store.bornAnchoredPremium

        XCTAssertTrue(store.canBindAndDepart(bornAnchored: true))
        XCTAssertTrue(store.bindAndDepart(bornAnchored: true))

        let run = try XCTUnwrap(store.state.worlds.activeRun)
        let realm = try XCTUnwrap(store.state.worlds.anchoredRealms.first)
        XCTAssertEqual(store.state.base.essence, essenceBefore - total)
        XCTAssertEqual(realm.runIndex, run.runIndex)
        XCTAssertEqual(realm.route, .bornAnchored)
        XCTAssertTrue(realm.world.satchelItems.stacks.isEmpty,
                      "carried expedition supplies are not part of the permanent realm")

        store.mutate("simulate return") { $0.worlds.activeRun = nil }
        XCTAssertTrue(store.revisitAnchoredRealm(realm.id))
        XCTAssertEqual(store.state.worlds.activeRun?.map, realm.world.map,
                       "revisiting restores the saved realm instead of generating another world")
    }

    @MainActor
    func testBindingIsRefusedWhenTheWorstCaseIsUnaffordable() {
        let store = GameStore(io: .temporary(name: "poor-\(UUID().uuidString)"))
        store.mutate("go broke") { $0.base.essence = 0 }

        XCTAssertFalse(store.canBindAndDepart)
        XCTAssertFalse(store.bindAndDepart())
        XCTAssertNil(store.state.worlds.activeRun)
        XCTAssertEqual(store.bindError,
                       "This binding needs 10 Essence; you currently have 0.")
    }

    @MainActor
    func testBindingRefusalUsesCurrentStateAfterAnEarlierReadyRender() {
        let store = GameStore(io: .temporary(name: "stale-bind-\(UUID().uuidString)"))
        XCTAssertEqual(store.bindAvailability(bornAnchored: false), .ready(totalCost: 10))

        store.mutate("simulate state changing after render") { state in
            state.base.essence = 0
        }

        XCTAssertFalse(store.bindAndDepart())
        XCTAssertNil(store.state.worlds.activeRun)
        XCTAssertEqual(store.state.worlds.runIndex, 0)
        XCTAssertEqual(store.bindError,
                       "This binding needs 10 Essence; you currently have 0.")
    }

    @MainActor
    func testBornAnchoredRefusalNamesTheCurrentMissingRequirement() {
        let store = GameStore(io: .temporary(name: "anchor-refusal-\(UUID().uuidString)"))

        XCTAssertEqual(store.bindAvailability(bornAnchored: true), .anchorageLocked)
        XCTAssertFalse(store.bindAndDepart(bornAnchored: true))
        XCTAssertEqual(store.bindError,
                       "Born anchored requires the Anchorage. Turn it off or build the Anchorage first.")
    }

    @MainActor
    func testBindingRefusalNamesAnExistingExpeditionWithoutMutation() {
        let store = GameStore(io: .temporary(name: "active-run-refusal-\(UUID().uuidString)"))
        XCTAssertTrue(store.bindAndDepart(), "A blank page is an eligible bind")
        let before = store.state

        XCTAssertEqual(store.bindAvailability(bornAnchored: false), .activeExpedition)
        XCTAssertFalse(store.bindAndDepart())
        XCTAssertEqual(store.state, before)
        XCTAssertEqual(store.bindError,
                       "You are already in an expedition. Return Home before binding another world.")
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
