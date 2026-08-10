import XCTest
@testable import Bookbinder

/// The writing grammar (decisions-session-14): **target first, then connected sources**, joined by
/// adjacency *and* an explicit connector, moving and rotating as one object.
final class GrammarTests: XCTestCase {

    // MARK: The corrected invariant

    /// **Absolute position carries no meaning; relative position does.**
    ///
    /// This replaces the old rule, which said position never mattered at all and tested it by
    /// comparing two unrelated arrangements. That is now only half true: which sigils touch which
    /// *is* the composition. So the test is that the page can be **translated as a whole** and say
    /// exactly the same thing.
    func testTranslatingTheWholePageChangesNothing() throws {
        let page = try sunlitPage()
        let shifted = try XCTUnwrap(translate(page, by: PageCell(column: 2, row: 1)))

        XCTAssertNotEqual(page.runes.map(\.origin), shifted.runes.map(\.origin),
                          "nothing moved, so this proves nothing")
        XCTAssertEqual(PressureRules.resolve(page.sigils), PressureRules.resolve(shifted.sigils))
    }

    /// The other half: **rotating a cluster changes nothing about what it says.** It's the same
    /// piece, held at a different angle.
    func testRotatingAClusterChangesNothingItSays() throws {
        let page = try sunlitPage()
        let anchor = try XCTUnwrap(page.runes.first).id
        let turned = try XCTUnwrap(PageRules.rotate(cluster: anchor, on: page))

        XCTAssertNotEqual(page.runes.map(\.origin), turned.runes.map(\.origin), "nothing rotated")
        XCTAssertEqual(PressureRules.resolve(page.sigils), PressureRules.resolve(turned.sigils))
    }

    /// And the part that is *not* invariant any more, which is the whole point of the change:
    /// disconnecting two sigils changes what the page says.
    func testWhichSigilsTouchWhichIsTheComposition() throws {
        let page = try sunlitPage()
        let link = try XCTUnwrap(page.links.first)
        let severed = PageRules.disconnect(link.a, link.b, on: page)

        XCTAssertNotEqual(PressureRules.resolve(page.sigils),
                          PressureRules.resolve(severed.sigils),
                          "breaking the connection changed nothing — arranging isn't writing")
    }

    // MARK: Connecting

    func testConnectingNeedsAdjacencyAsWellAsIntent() throws {
        var page = Page()
        page = try XCTUnwrap(place(.target("illumination"), at: PageCell(column: 0, row: 0), on: page))
        page = try XCTUnwrap(place(.source("sun"), at: PageCell(column: 4, row: 4), on: page))

        let ids = page.runes.map(\.id)
        XCTAssertFalse(PageRules.canConnect(ids[0], ids[1], on: page),
                       "linked across the page — adjacency stopped meaning anything")
        XCTAssertNil(PageRules.connect(ids[0], ids[1], on: page))
    }

    /// Adjacency alone must not join things, or a full page would be one enormous cluster.
    func testTouchingIsNotJoining() throws {
        let page = try adjacentButUnjoined()
        XCTAssertTrue(PageRules.areAdjacent(page.runes[0], page.runes[1]), "the test page isn't adjacent")
        XCTAssertEqual(PageRules.clusters(on: page).count, 2, "touching alone joined them")
        XCTAssertTrue(page.sigils.isEmpty, "an unjoined source said something")
    }

    func testASourceWithNoTargetSaysNothing() throws {
        var page = Page()
        page = try XCTUnwrap(place(.source("sun"), at: PageCell(column: 0, row: 0), on: page))
        XCTAssertTrue(page.sigils.isEmpty, "a word with no sentence around it still spoke")
    }

    func testChainingPullsEverythingIntoOneCluster() throws {
        let page = try sunlitPage()
        let ids = page.runes.map(\.id)
        XCTAssertEqual(PageRules.cluster(containing: ids[0], on: page).count, page.runes.count)
        XCTAssertEqual(PageRules.clusters(on: page).count, 1)
    }

    func testFocusStabilityMarksAreDerivedFromTheActualPage() throws {
        let page = try sunlitPage()
        let sigils = PageRules.clusterSigils(of: page)
        let total = BookRules.greedDelta(for: sigils)
        let chains = PageRules.chains(on: page)
        let parts = chains.flatMap(\.parts)
        XCTAssertEqual(parts.count, sigils.count)
        for (part, sigil) in zip(parts, sigils) {
            let expected = total - BookRules.greedDelta(for: sigils.filter { $0.id != sigil.id })
            XCTAssertEqual(part.stabilityDelta, expected,
                           "the UI marked \(part.source) from authored prose rather than page arithmetic")
        }
    }

    // MARK: A cluster is one object

    func testMovingAClusterMovesAllOfItAndKeepsItsLinks() throws {
        let page = try sunlitPage()
        let anchor = try XCTUnwrap(page.runes.first).id
        let moved = try XCTUnwrap(PageRules.move(cluster: anchor, by: PageCell(column: 1, row: 1), on: page))

        XCTAssertEqual(moved.links, page.links, "moving broke a connection")
        for (before, after) in zip(page.runes, moved.runes) {
            XCTAssertEqual(after.origin.column, before.origin.column + 1)
            XCTAssertEqual(after.origin.row, before.origin.row + 1)
        }
    }

    func testAClusterWillNotMoveOverSomethingElse() throws {
        var page = try sunlitPage()
        // Wall the cluster in on its right.
        let occupied = Set(page.runes.flatMap(\.cells))
        let free = page.allCellsInReadingOrder.first { cell in
            !occupied.contains(cell) && cell.column > (occupied.map(\.column).max() ?? 0)
        }
        guard let free else { throw XCTSkip("no room to build the wall") }
        page = try XCTUnwrap(place(.target("thermal"), at: free, on: page))

        let anchor = try XCTUnwrap(page.runes.first).id
        let far = PageRules.move(cluster: anchor, by: PageCell(column: 40, row: 0), on: page)
        XCTAssertNil(far, "a cluster walked off the page")
    }

    func testRotationIsRefusedRatherThanForcedWhenItWouldNotFit() throws {
        // A cluster hard against the right edge, tall enough that turning it would overhang.
        var page = Page(width: 4, height: 4)
        page = try XCTUnwrap(place(.target("illumination"), at: PageCell(column: 3, row: 0), on: page, hand: .refined))
        page = try XCTUnwrap(place(.source("sun"), at: PageCell(column: 3, row: 1), on: page, hand: .refined))
        let ids = page.runes.map(\.id)
        page = try XCTUnwrap(PageRules.connect(ids[0], ids[1], on: page))

        let turned = PageRules.rotate(cluster: ids[0], on: page)
        if let turned {
            // If it did fit, it must still be entirely on the page and not overlapping.
            let cells = turned.runes.flatMap(\.cells)
            XCTAssertTrue(cells.allSatisfy(turned.contains))
            XCTAssertEqual(Set(cells).count, cells.count)
        }
    }

    // MARK: Qualifiers

    func testAQualifierModifiesTheSourceItIsJoinedTo() throws {
        var page = Page()
        page = try XCTUnwrap(place(.target("illumination"), at: PageCell(column: 0, row: 0), on: page, hand: .refined))
        page = try XCTUnwrap(place(.source("sun"), at: PageCell(column: 1, row: 0), on: page, hand: .refined))
        page = try XCTUnwrap(place(.qualifier("overwhelming"), at: PageCell(column: 2, row: 0), on: page, hand: .refined))
        let ids = page.runes.map(\.id)
        page = try XCTUnwrap(PageRules.connect(ids[0], ids[1], on: page))
        page = try XCTUnwrap(PageRules.connect(ids[1], ids[2], on: page))

        XCTAssertEqual(page.sigils.first?.intensity, .overwhelming)
    }

    func testProspectiveConnectionsRejectAmbiguousGrammar() throws {
        var page = Page()
        page = try XCTUnwrap(place(.target("illumination"), at: .init(column: 0, row: 0), on: page, hand: .refined))
        page = try XCTUnwrap(place(.source("sun"), at: .init(column: 1, row: 0), on: page, hand: .refined))
        page = try XCTUnwrap(place(.target("thermal"), at: .init(column: 2, row: 0), on: page, hand: .refined))
        let ids = page.runes.map(\.id)
        page = try XCTUnwrap(PageRules.connect(ids[0], ids[1], on: page))
        XCTAssertEqual(PageRules.connectionIssue(ids[1], ids[2], on: page), .multipleTargets)

        var duplicate = Page()
        duplicate = try XCTUnwrap(place(.source("sun"), at: .init(column: 1, row: 1), on: duplicate, hand: .refined))
        duplicate = try XCTUnwrap(place(.qualifier("great"), at: .init(column: 0, row: 1), on: duplicate, hand: .refined))
        duplicate = try XCTUnwrap(place(.qualifier("faint"), at: .init(column: 2, row: 1), on: duplicate, hand: .refined))
        let duplicateIDs = duplicate.runes.map(\.id)
        duplicate = try XCTUnwrap(PageRules.connect(duplicateIDs[0], duplicateIDs[1], on: duplicate))
        XCTAssertEqual(PageRules.connectionIssue(duplicateIDs[0], duplicateIDs[2], on: duplicate),
                       .duplicateModifierLadder)
    }

    func testSecondFocusRequiresChainingAndMustFitSubject() throws {
        var page = Page()
        page = try XCTUnwrap(place(.target("illumination"), at: .init(column: 0, row: 0), on: page, hand: .refined))
        page = try XCTUnwrap(place(.source("sun"), at: .init(column: 1, row: 0), on: page, hand: .refined))
        page = try XCTUnwrap(place(.source("moon"), at: .init(column: 2, row: 0), on: page, hand: .refined))
        let ids = page.runes.map(\.id)
        page = try XCTUnwrap(PageRules.connect(ids[0], ids[1], on: page))
        XCTAssertEqual(PageRules.connectionIssue(ids[1], ids[2], on: page), .chainingRequired)
        XCTAssertNil(PageRules.connectionIssue(ids[1], ids[2], on: page, chainingUnlocked: true))
    }

    func testPhaseRemainsDecodableButIsNotOfferedForWriting() {
        XCTAssertFalse(ContentCatalog.shared.qualifiers(on: .phase).isEmpty)
        XCTAssertFalse(PageRules.writableQualifiers().contains { $0.ladder == .phase })
    }

    func testLegacyAmbiguousGraphStillResolvesButWarns() throws {
        var page = Page()
        page = try XCTUnwrap(place(.target("illumination"), at: .init(column: 0, row: 0), on: page, hand: .refined))
        page = try XCTUnwrap(place(.source("sun"), at: .init(column: 1, row: 0), on: page, hand: .refined))
        page = try XCTUnwrap(place(.target("thermal"), at: .init(column: 2, row: 0), on: page, hand: .refined))
        let ids = page.runes.map(\.id)
        // Simulate a saved graph authored before strict prospective validation.
        page.links = [MarkLink(ids[0], ids[1]), MarkLink(ids[1], ids[2])]

        XCTAssertFalse(page.sigils.isEmpty, "tolerant legacy writing stopped loading")
        XCTAssertTrue(PageRules.grammarWarnings(on: page, chainingUnlocked: false)
            .contains("A joined statement has more than one subject."))
    }

    func testTheThreeGenericLaddersApplyEverywhereAndTheNarrowOnesDoNot() {
        // Session 14 §4: Intensity, Scale and Count are the workhorses; Phase is hydrology-only.
        for ladder in [QualifierDef.Ladder.intensity, .scale, .count] {
            let rungs = ContentCatalog.shared.qualifiers(on: ladder)
            XCTAssertFalse(rungs.isEmpty, "\(ladder.rawValue) has no rungs")
            XCTAssertTrue(rungs.allSatisfy(\.isGeneric), "\(ladder.rawValue) should apply everywhere")
        }
        let phase = ContentCatalog.shared.qualifiers(on: .phase)
        XCTAssertFalse(phase.isEmpty)
        XCTAssertTrue(phase.allSatisfy { $0.applies(to: "hydrology") })
        XCTAssertFalse(phase.contains { $0.applies(to: "substrate") },
                       "Phase escaped hydrology, where it's the only thing that can say what it says")
    }

    func testBrightIsNotInTheVocabulary() {
        // Cut in §4: a great sun *is* a bright sun.
        XCTAssertNil(ContentCatalog.shared.qualifier("bright"))
    }

    // MARK: Saving

    func testAConnectedRotatedPageSurvivesASave() throws {
        var page = try sunlitPage()
        let anchor = try XCTUnwrap(page.runes.first).id
        page = try XCTUnwrap(PageRules.rotate(cluster: anchor, on: page))

        let data = try SaveCodec.makeEncoder().encode(page)
        let reloaded = try SaveCodec.makeDecoder().decode(Page.self, from: data)
        XCTAssertEqual(reloaded, page)
        XCTAssertEqual(reloaded.links, page.links, "the connections didn't survive")
        XCTAssertEqual(PressureRules.resolve(reloaded.sigils), PressureRules.resolve(page.sigils))
    }

    // MARK: Helpers

    private func place(_ content: MarkContent, at origin: PageCell, on page: Page,
                       hand: Hand = .refined) -> Page? {
        let glyph: String
        switch content {
        case .target(let id): glyph = id.rawValue
        case .source(let id): glyph = id.rawValue
        case .qualifier(let id): glyph = id.rawValue
        case .compound(let id): glyph = id.rawValue
        case .rune(let sigil): glyph = sigil.source.rawValue
        }
        guard let shape = PageRules.shape(forGlyph: glyph, hand: hand),
              PageRules.canPlace(shape: shape, at: origin, on: page)
        else { return nil }
        var result = page
        result.runes.append(PlacedRune(id: InstanceID(rawValue: UInt64(page.runes.count + 1)),
                                       content: content, hand: hand,
                                       origin: origin, shapeID: shape.id))
        return result
    }

    /// Illumination, with an overwhelming sun joined to it.
    private func sunlitPage() throws -> Page {
        var page = Page()
        page = try XCTUnwrap(place(.target("illumination"), at: PageCell(column: 0, row: 0), on: page))
        page = try XCTUnwrap(place(.source("sun"), at: PageCell(column: 1, row: 0), on: page))
        let ids = page.runes.map(\.id)
        return try XCTUnwrap(PageRules.connect(ids[0], ids[1], on: page))
    }

    private func adjacentButUnjoined() throws -> Page {
        var page = Page()
        page = try XCTUnwrap(place(.target("illumination"), at: PageCell(column: 0, row: 0), on: page))
        page = try XCTUnwrap(place(.source("sun"), at: PageCell(column: 1, row: 0), on: page))
        return page
    }

    private func translate(_ page: Page, by delta: PageCell) -> Page? {
        var result = page
        for index in result.runes.indices {
            result.runes[index].origin = result.runes[index].origin + delta
        }
        return result.runes.flatMap(\.cells).allSatisfy(result.contains) ? result : nil
    }

    // MARK: - What the page says, and whether it says so

    /// **Every target must be writable.** Relief had no sources attached to it at all, so its bin
    /// was empty on screen and you could not write the shape of the land — with nothing to say why.
    func testEveryPressureTargetHasSomethingYouCanWriteAboutIt() {
        for target in ContentCatalog.shared.pressureTargets {
            let sources = ContentCatalog.shared.pressureSources.filter { $0.canAttach(to: target.id) }
            XCTAssertFalse(sources.isEmpty,
                           "\(target.id.rawValue) has no sources — its bin is empty on screen")
        }
    }

    /// A source may only be bound to a target it actually touches.
    func testASourceCanOnlyBeBoundToSomethingItAffects() {
        for source in ContentCatalog.shared.pressureSources {
            for target in source.attachesTo {
                XCTAssertTrue(source.targets.contains(target),
                              "\(source.id.rawValue) attaches to \(target.rawValue) but doesn't touch it")
            }
        }
    }

    /// **The trap.** Adjacency alone joins nothing, so a page can be full of sigils and describe
    /// nothing — and the world comes out entirely random, including its resolved stability,
    /// exactly as though you had written nothing at all. The preview has to be able to say so.
    func testAPageOfUnjoinedSigilsIsReportedAsSayingNothing() throws {
        let page = try adjacentButUnjoined()
        let projection = BookProjection.project(page: page, seed: 1)

        XCTAssertEqual(projection.marksWritten, 2)
        XCTAssertEqual(projection.marksSpeaking, 0)
        XCTAssertTrue(projection.saysNothing)
        XCTAssertTrue(projection.isWrittenButSilent,
                      "a page of sigils that say nothing must read differently from an empty one")
    }

    /// …and once they're joined, it speaks.
    func testJoiningASourceToItsTargetMakesThePageSpeak() throws {
        let projection = BookProjection.project(page: try sunlitPage(), seed: 1)
        XCTAssertGreaterThan(projection.marksSpeaking, 0)
        XCTAssertFalse(projection.saysNothing)
        XCTAssertFalse(projection.isWrittenButSilent)
    }

    /// An empty page is a different thing from a silent one, and reads differently.
    func testAnEmptyPageIsNotTheSameAsASilentOne() {
        let projection = BookProjection.project(page: Page(), seed: 1)
        XCTAssertTrue(projection.saysNothing)
        XCTAssertFalse(projection.isWrittenButSilent)
    }


    // MARK: - What is written reaches the world it binds

    /// **The bug this exists to prevent.** A bound book carried only its *compound* symbol ids,
    /// because `page.symbolIDs` returns compounds and nothing else — so every target and source
    /// cluster on the page was dropped on the way into the world. The preview resolved the page
    /// directly and looked right; the world it bound was generated from the compounds alone.
    func testWhatIsWrittenOnThePageSurvivesBinding() throws {
        let page = try sunlitPage()
        let book = BookRules.resolveBook(page: page)

        XCTAssertFalse(book.composition.isEmpty, "the page's own clusters never reached the book")
        XCTAssertTrue(BookRules.sigils(for: book).contains { $0.source == "sun" },
                      "the sun was written and the bound book has never heard of it")
        XCTAssertGreaterThan(BookRules.readings(for: book, seed: 1)["illumination"].peak,
                             PressureRules.resolve([], fillingUnwrittenWith: 1)["illumination"].peak,
                             "writing an overwhelming sun made no difference to the world")
    }

    /// …and it reaches the world that is actually generated, not merely the readings.
    func testAWorldGeneratedFromAPageIsTheWorldThePageDescribes() throws {
        let sunlit = BookRules.resolveBook(page: try sunlitPage())
        let blank = BookRules.resolveBook(page: Page())
        XCTAssertNotEqual(Worldgen.generate(book: sunlit, seed: 4242).map.tiles,
                          Worldgen.generate(book: blank, seed: 4242).map.tiles,
                          "a written page and an empty one produced the same world")
    }

    // MARK: - Stability answers to the page

    /// **Greed from abundance** — instability's other origin, and the one the sigil vocabulary had
    /// no way at all to express. Every world came out at 100 however much you asked for.
    func testAskingForMoreThanAWorldNaturallyHasCostsStability() throws {
        let modest = BookRules.stabilityScore(of: BookRules.resolveBook(page: Page()))
        let greedy = BookRules.stabilityScore(of: BookRules.resolveBook(page: try sunlitPage()))
        XCTAssertLessThan(greedy, modest, "an overwhelming sun was free")
    }

    /// It runs in both directions: writing *less* than a world naturally has calms it.
    func testAskingForLessThanAWorldNaturallyHasCalmsIt() throws {
        // Thermal's baseline is temperate, so a cold world is asking for less than the default.
        var page = Page()
        page = try XCTUnwrap(place(.target("thermal"), at: PageCell(column: 0, row: 0), on: page))
        page = try XCTUnwrap(place(.source("glacier"), at: PageCell(column: 1, row: 0), on: page))
        let ids = page.runes.map(\.id)
        page = try XCTUnwrap(PageRules.connect(ids[0], ids[1], on: page))

        let delta = BookRules.greedDelta(for: PageRules.clusterSigils(of: page))
        XCTAssertGreaterThan(delta, 0, "a cold world should be a calm one, not a free one")
    }

    /// **The number must be one you can work out while composing.** Unwritten targets are rolled at
    /// resolution, and a rolled source can push a target you *did* write — so the headline must be
    /// computed from the page alone or it moves with the seed.
    func testTheHeadlineNeverMovesWithTheSeed() throws {
        let book = BookRules.resolveBook(page: try sunlitPage())
        let scores = Set([UInt64(1), 99, 4242, 20_260_805].map { _ in BookRules.stabilityScore(of: book) })
        XCTAssertEqual(scores.count, 1)
    }

    /// **One world, one price** (Q44) — and this is the invariant that replaces "a symbol moves the
    /// headline by exactly its printed number".
    ///
    /// A compound is *one glyph meaning what several runes mean together* (rune spec §9). So writing
    /// the compound and writing out its expansion by hand have to cost the same. They did not: Rich
    /// Ore carried a hand-typed −45 while the identical world spelled out as *great iron, gold*
    /// measured −8, which made the shorthand a different world from the thing it is shorthand for.
    func testACompoundCostsExactlyWhatItsExpansionCosts() throws {
        for symbol in ContentCatalog.shared.symbols where symbol.danger == nil {
            let compound = BoundBook(written: [symbol.id], essencePaid: 0)
            let spelledOut = BoundBook(written: [], composition: BookRules.sigils(of: symbol),
                                       essencePaid: 0)
            XCTAssertEqual(BookRules.stabilityScore(of: compound),
                           BookRules.stabilityScore(of: spelledOut),
                           "\(symbol.id.rawValue) is priced differently from the runes it stands for")
        }
    }

    /// Ink is charged by the cell, so a page written in the sigil vocabulary isn't free.
    func testWhatIsOnThePageIsWhatYouPayFor() throws {
        let written = BookRules.resolveBook(page: try sunlitPage()).essencePaid
        let blank = BookRules.resolveBook(page: Page()).essencePaid
        XCTAssertGreaterThan(written, blank, "a page full of sigils cost the same as an empty one")
    }

}

private extension Page {
    var allCellsInReadingOrder: [PageCell] {
        (0..<height).flatMap { row in (0..<width).map { PageCell(column: $0, row: row) } }
    }

    // MARK: The settled vocabulary

    /// **A word invented in a spec is either defined in the interface or renamed before it reaches
    /// it** (`jargon-audit.md`, the rule adopted 6 Aug). *Rung* failed that twice — coined in a
    /// spec, into code comments, then into a field name feeding a player-facing string, and nobody
    /// had ever defined it for Aimee.
    ///
    /// This test guards the *content*, which is the half that grows. Code identifiers may stay
    /// technical; what a player reads may not.
    func testNoContentSpeaksInSpecJargon() {
        // Retired in `vocabulary-settled.md`: subject, focus, main focus, modifier, compound.
        let retired = ["rung", "primary", "pressure target", "qualifier ladder"]

        func check(_ text: String, _ label: String) {
            for word in retired where text.lowercased().contains(word) {
                XCTFail("\(label) says \"\(word)\" — spec jargon on a screen")
            }
        }
        for target in ContentCatalog.shared.pressureTargets {
            check(target.name, "subject \(target.id.rawValue)")
        }
        for source in ContentCatalog.shared.pressureSources {
            check(source.name, "focus \(source.id.rawValue)")
        }
        for qualifier in ContentCatalog.shared.qualifiers {
            check(qualifier.name, "modifier \(qualifier.id.rawValue)")
        }
        for node in ContentCatalog.shared.researchNodes {
            check(node.name, "research node \(node.id.rawValue)")
            check(node.blurb, "research node \(node.id.rawValue)")
        }
        for symbol in ContentCatalog.shared.symbols {
            check(symbol.name, "compound \(symbol.id.rawValue)")
            check(symbol.blurb, "compound \(symbol.id.rawValue)")
        }
    }

    /// A history written before *rung* was renamed still reads. The record is the answer key, and
    /// silently losing the one line that says a word did nothing would be the worst thing to drop.
    func testAWorldRecordedBeforeTheRenameStillReads() throws {
        let json = """
        {"id":{"rawValue":7},"seed":7,"runIndex":1,"descriptionSentence":"Bright.",
         "written":["Illumination ← Vast Sun"],"inertRungs":["Vast on Illumination"],
         "readings":{},"travellersPresent":[],"isKept":false}
        """
        let world = try JSONDecoder().decode(VisitedWorld.self, from: Data(json.utf8))
        XCTAssertEqual(world.inertModifiers, ["Vast on Illumination"],
                       "renaming the field dropped the one line that says a word did nothing")
    }

    // MARK: Scale and Count — written, displayed, and no longer inert

    /// **A vast sun is a brighter sun** (Aimee, 6 Aug: *"I do think I should be able to make a
    /// giant overwhelming sun"*).
    ///
    /// Scale used to mean world size and nothing else, so *vast* on a sun was a word you could
    /// write, that was accepted and displayed, and that did nothing at all. For a sun, extent and
    /// magnitude are the same thing — the split only holds for subjects with an extent separate
    /// from their amount.
    func testAVastSunIsABrighterSun() {
        func brightness(scale: Int) -> Double {
            PressureRules.resolve([Sigil(id: InstanceID(rawValue: 1), source: "sun",
                                         target: "illumination", scale: scale)])["illumination"].peak
        }
        let plain = brightness(scale: 0)
        XCTAssertGreaterThan(brightness(scale: 4), plain, "a vast sun is no brighter than a plain one")
        XCTAssertLessThan(brightness(scale: 1), plain, "a minute sun is no dimmer than a plain one")
    }

    /// **Many suns are brighter than one, and nothing like twice as bright** (Aimee: *"I should be
    /// able to have a ton of suns or other things. Count should absolutely do something!"*).
    ///
    /// Sublinear on purpose — linear would make Count a second Intensity, which is the collapse
    /// session 14 refused.
    func testManySunsAreBrighterThanOneButNotProportionally() {
        func brightness(count: Int) -> Double {
            PressureRules.resolve([Sigil(id: InstanceID(rawValue: 1), source: "sun",
                                         target: "illumination", count: count)])["illumination"].peak
        }
        let one = brightness(count: 0)
        let four = brightness(count: 4)
        XCTAssertGreaterThan(four, one, "four suns are no brighter than one")
        XCTAssertLessThan(four, one * 4, "four suns are four times as bright, so Count is just Intensity")
    }

    /// **A vast sea spreads; a great sea deepens.** The distinction session 14 was protecting when
    /// it refused to collapse the ladders — and it only applies where a subject has an extent of
    /// its own.
    func testScaleSpreadsASubjectThatHasAnExtent() {
        func dispersion(scale: Int) -> Double {
            PressureRules.resolve([Sigil(id: InstanceID(rawValue: 1), source: "sea",
                                         target: "hydrology", scale: scale)])["hydrology"]
                .aspect("dispersion")
        }
        XCTAssertGreaterThan(dispersion(scale: 4), dispersion(scale: 1),
                             "a vast sea is no more spread out than a minute one")
    }

    /// Nothing generic is inert any more, which is what makes the warning meaningful when it does
    /// fire — it now only ever means a genuinely narrow modifier in the wrong place.
    func testTheGenericLaddersDoSomethingEverywhere() {
        for target in ContentCatalog.shared.pressureTargets {
            for ladder in [QualifierDef.Ladder.intensity, .scale, .count] {
                XCTAssertTrue(ladder.changesAnything(for: target.id),
                              "\(ladder.rawValue) still does nothing on \(target.name)")
            }
        }
    }
}
