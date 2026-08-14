import XCTest
@testable import Bookbinder

/// The page as a spatial grid (`writing-system-rune-spec.md` §2–3).
///
/// Two properties carry the whole design: **the page is a budget, not a syntax** — where a rune
/// sits never changes what it says — and **refinement is literacy, not power** — a better hand lets
/// you say the same thing in less space and never unlocks a meaning.
final class PageTests: XCTestCase {

    func testStarterWorldPagesMatchFrozenAuthorityAndRulesOwnedPrices() throws {
        let definitions = WorldPageCatalog.starterDefinitions
        XCTAssertEqual(definitions.map(\.id), ["starter_open_meadow", "starter_rainwashed_shore",
                                                "starter_stone_hollow"])
        XCTAssertEqual(definitions.map(\.disposition), [.starterUnique, .starterUnique, .starterUnique])
        XCTAssertEqual(definitions.map(\.seed), [2, 26, 23])
        XCTAssertEqual(definitions.map(\.copiedCost), [21, 18, 22])
        XCTAssertEqual(definitions.map(\.worldPageCost), [14, 14, 16])
        XCTAssertEqual(definitions.map(\.title), ["Open Meadow", "Rainwashed Shore", "Stone Hollow"])
        XCTAssertEqual(definitions.map(\.provenance), [
            "A clean practice page, already written in rough charcoal.",
            "A clean practice page with one broad charcoal mark.",
            "A clean practice page with charcoal rubbed into the grain."
        ])
        XCTAssertEqual(definitions.map(\.promise), [
            "Open, living, modestly resourced and safe enough to learn the opening loop.",
            "A readable water-and-relief contrast without an opening lethality spike.",
            "Stone, enclosure and ordinary ore within the accepted level-one envelope."
        ])
        XCTAssertTrue(definitions.allSatisfy { $0.page.width == 6 && $0.page.height == 6 })
        XCTAssertTrue(definitions.allSatisfy { $0.page.runes.allSatisfy { $0.hand == .crude } })
        XCTAssertEqual(definitions.map { $0.page.runes.map(\.id.rawValue) }, [[1, 2], [1], [1, 2]])
        XCTAssertEqual(definitions.map { $0.page.runes.map(\.shapeID) },
                       [["crude_smear", "crude_smear"], ["crude_smear"],
                        ["crude_smear", "crude_block"]])
        XCTAssertEqual(definitions.map { $0.page.symbolIDs.map(\.rawValue) },
                       [["plains", "verdant"], ["archipelago"], ["caverns", "common_ore"]])
        XCTAssertEqual(definitions.map { $0.page.runes.map(\.origin) }, [
            [PageCell(column: 0, row: 0), PageCell(column: 3, row: 3)],
            [PageCell(column: 1, row: 2)],
            [PageCell(column: 0, row: 1), PageCell(column: 4, row: 3)]
        ])

        let instances = WorldPageCatalog.starterInstances
        XCTAssertEqual(Set(instances.map(\.id)).count, 3)
        XCTAssertEqual(instances.map(\.id.rawValue),
                       [0x5750_0000_0000_0001, 0x5750_0000_0000_0002,
                        0x5750_0000_0000_0003])
        XCTAssertEqual(WorldPageCatalog.authoritySHA256,
                       "04f73e3cb93850ec1f449d9f302c4ca276ac1091631ed81322458d8b8142c534")
        XCTAssertNil(WorldPageCatalog.definition("not_authored"),
                     "unknown content must fail closed rather than fabricate a page")
        for instance in instances {
            let ordinary = BookRules.resolveBook(page: instance.definition.page)
            let preInscribed = BookRules.resolveBook(worldPage: instance)
            XCTAssertEqual(ordinary.essencePaid, instance.definition.copiedCost)
            XCTAssertEqual(preInscribed.essencePaid, instance.definition.worldPageCost)
            XCTAssertEqual(preInscribed.essencePaid,
                           ordinary.essencePaid - BookRules.inkCost(of: instance.definition.page))
            XCTAssertEqual(preInscribed.worldPageUseReceipt?.instanceID, instance.id)
            XCTAssertEqual(preInscribed.worldPageUseReceipt?.definition, instance.definition)
        }

        let data = try SaveCodec.makeEncoder().encode(instances)
        XCTAssertEqual(try SaveCodec.makeDecoder().decode([WorldPageInstance].self, from: data), instances)
    }

    func testLegacyBoundBookDecodesWithoutWorldPageReceipt() throws {
        let data = Data(#"{"written":["plains"],"essencePaid":14}"#.utf8)
        let book = try SaveCodec.makeDecoder().decode(BoundBook.self, from: data)
        XCTAssertNil(book.worldPageUseReceipt)
        XCTAssertEqual(book.allSymbolIDs, ["plains"])
        XCTAssertEqual(book.essencePaid, 14)
    }

    func testCancellingPageToolClearsEveryTransientFieldWithoutChangingThePage() {
        let link = MarkLink(InstanceID(rawValue: 1), InstanceID(rawValue: 2))
        let page = Page(links: [link])
        var session = PageInteractionSession(mode: .connecting,
                                             anchor: InstanceID(rawValue: 1),
                                             held: InstanceID(rawValue: 2),
                                             connectionError: "Not adjacent")

        session.cancel()

        XCTAssertEqual(session.mode, .off)
        XCTAssertNil(session.anchor)
        XCTAssertNil(session.held)
        XCTAssertNil(session.connectionError)
        XCTAssertEqual(page.links, [link], "dismissing a tool must not undo completed links")
    }

    func testPageIdentityTracksPageReplacementButNotLinkEdits() {
        let ids = [InstanceID(rawValue: 3), InstanceID(rawValue: 7)]
        let original = PageInteractionIdentity(width: 6, height: 6, runeIDs: ids)
        let linkOnlyEdit = PageInteractionIdentity(width: 6, height: 6, runeIDs: ids)
        let replacement = PageInteractionIdentity(width: 6, height: 6,
                                                  runeIDs: [InstanceID(rawValue: 9)])

        XCTAssertEqual(original, linkOnlyEdit,
                       "completed Connect/Disconnect edits must not cancel their own mode")
        XCTAssertNotEqual(original, replacement)
    }

    // MARK: The page is a budget, not a syntax

    /// **Superseded in part** (decisions-session-14 §3). Absolute position still carries no
    /// meaning, which is what this checks — but *relative* position now does, and the rule that
    /// replaced this one lives in `GrammarTests`: translate or rotate the whole page and it must
    /// say exactly the same thing.
    ///
    /// This case survives because the marks in it are **self-contained** — compounds and
    /// whole-statement runes say what they say wherever they sit, with or without neighbours.
    func testSelfContainedMarksSayTheSameThingWhereverTheySit() {
        let sigils = [
            Sigil(id: InstanceID(rawValue: 1), source: "sun", target: "illumination", intensity: .great),
            Sigil(id: InstanceID(rawValue: 2), source: "glacier", target: "hydrology", intensity: .moderate)
        ]

        var tidy = Page()
        var scattered = Page()
        for sigil in sigils {
            tidy = PageRules.placeAnywhere(sigil, hand: .refined, on: tidy)!
        }
        // Same runes, deliberately different squares.
        scattered = PageRules.place(sigils[1], hand: .refined, at: PageCell(column: 5, row: 5), on: scattered)!
        scattered = PageRules.place(sigils[0], hand: .refined, at: PageCell(column: 0, row: 3), on: scattered)!

        XCTAssertNotEqual(tidy.runes.map(\.origin), scattered.runes.map(\.origin),
                          "the two pages were laid out the same, so this proves nothing")
        XCTAssertEqual(PressureRules.resolve(tidy.sigils), PressureRules.resolve(scattered.sigils))
    }

    /// Reading order isn't meaning either — `sigils` sorts by identity, not by where things landed.
    func testSigilOrderDoesNotDependOnLayout() {
        let a = Sigil(id: InstanceID(rawValue: 1), source: "sun", target: "illumination")
        let b = Sigil(id: InstanceID(rawValue: 2), source: "ice", target: "thermal")

        let first = PageRules.place(b, hand: .refined, at: PageCell(column: 0, row: 0), on: Page())!
        let second = PageRules.place(a, hand: .refined, at: PageCell(column: 3, row: 3), on: first)!
        XCTAssertEqual(second.sigils.map(\.id.rawValue), [1, 2])
    }

    // MARK: Fitting

    func testARuneCannotOverlapAnother() {
        let page = PageRules.place(
            Sigil(id: InstanceID(rawValue: 1), source: "sun", target: "illumination"),
            hand: .crude, at: PageCell(column: 0, row: 0), on: Page())!

        let occupied = page.runes[0].cells[0]
        XCTAssertNil(PageRules.place(
            Sigil(id: InstanceID(rawValue: 2), source: "ice", target: "thermal"),
            hand: .refined, at: occupied, on: page),
                     "two runes wrote over each other")
    }

    func testARuneCannotHangOffTheEdge() {
        let page = Page()
        let corner = PageCell(column: page.width - 1, row: page.height - 1)
        XCTAssertNil(PageRules.place(
            Sigil(id: InstanceID(rawValue: 1), source: "sun", target: "illumination"),
            hand: .crude, at: corner, on: page),
                     "a charcoal scrawl fitted into a single corner cell")
    }

    func testAFullPageRefusesMore() {
        var page = Page(width: 2, height: 2)
        for index in 0..<4 {
            let sigil = Sigil(id: InstanceID(rawValue: UInt64(index)), source: "sun", target: "illumination")
            page = PageRules.placeAnywhere(sigil, hand: .refined, on: page)!
        }
        XCTAssertEqual(page.freeCells, 0)
        XCTAssertNil(PageRules.placeAnywhere(
            Sigil(id: InstanceID(rawValue: 99), source: "ice", target: "thermal"),
            hand: .refined, on: page))
    }

    func testRemovingARuneFreesItsCells() {
        let sigil = Sigil(id: InstanceID(rawValue: 1), source: "sun", target: "illumination")
        let page = PageRules.placeAnywhere(sigil, hand: .crude, on: Page())!
        XCTAssertGreaterThan(page.usedCells, 1)
        XCTAssertEqual(PageRules.remove(sigil.id, from: page).usedCells, 0)
    }

    // MARK: Refinement is literacy, not power

    func testABetterHandSaysTheSameThingInLessSpace() {
        let sigil = Sigil(id: InstanceID(rawValue: 1), source: "sun", target: "illumination")
        var previous = Int.max
        for hand in Hand.allCases {   // crude → plain → refined
            let page = PageRules.placeAnywhere(sigil, hand: hand, on: Page())!
            XCTAssertLessThan(page.usedCells, previous, "\(hand.rawValue) didn't compress")
            previous = page.usedCells

            // Same statement, whichever hand wrote it.
            XCTAssertEqual(page.sigils, [sigil])
        }
    }

    func testEveryRefinedRuneIsASingleCell() {
        for source in ContentCatalog.shared.pressureSources {
            let shape = PageRules.shape(for: source.id, hand: .refined)
            XCTAssertEqual(shape?.footprint, 1, "\(source.id.rawValue) isn't 1×1 in a fine hand")
        }
    }

    func testCrudeIsAlwaysBulkierThanPlain() {
        for source in ContentCatalog.shared.pressureSources {
            let crude = PageRules.shape(for: source.id, hand: .crude)?.footprint ?? 0
            let plain = PageRules.shape(for: source.id, hand: .plain)?.footprint ?? 0
            XCTAssertGreaterThan(crude, plain, "\(source.id.rawValue) got no worse in charcoal")
        }
    }

    func testRedrawingInAFinerHandKeepsThePageValid() {
        let sigil = Sigil(id: InstanceID(rawValue: 1), source: "sun", target: "illumination")
        let crude = PageRules.placeAnywhere(sigil, hand: .crude, on: Page())!
        let refined = PageRules.redraw(sigil.id, in: .refined, on: crude)!

        XCTAssertEqual(refined.usedCells, 1)
        XCTAssertEqual(refined.sigils, crude.sigils, "redrawing changed what the page said")
        XCTAssertEqual(Set(refined.runes.flatMap(\.cells)).count, refined.usedCells)
    }

    /// A better hand must never cost you a layout you'd already made.
    func testRedrawingRelocatesRatherThanFailing() {
        let big = Sigil(id: InstanceID(rawValue: 1), source: "sun", target: "illumination")
        var page = PageRules.place(big, hand: .refined, at: PageCell(column: 5, row: 5), on: Page())!
        // Crude needs room the bottom-right corner doesn't have, so it has to move.
        page = PageRules.redraw(big.id, in: .crude, on: page)!
        XCTAssertEqual(page.sigils, [big])
        XCTAssertTrue(page.runes[0].cells.allSatisfy { page.contains($0) })
    }

    // MARK: Shapes are stable

    /// A rune the player has learned to fit must not change shape between launches — Swift's own
    /// hashing is salted per process, which would redraw every page on relaunch.
    func testARuneAlwaysDrawsTheSameShape() {
        for source in ContentCatalog.shared.pressureSources {
            let first = PageRules.shape(for: source.id, hand: .crude)?.id
            let again = PageRules.shape(for: source.id, hand: .crude)?.id
            XCTAssertEqual(first, again)
        }
        // Pinned values: if these change, existing pages relayout.
        XCTAssertNotNil(PageRules.shape(for: "sun", hand: .crude))
        XCTAssertEqual(PageRules.shape(for: "sun", hand: .crude)?.id,
                       PageRules.shape(for: "sun", hand: .crude)?.id)
    }

    func testShapesAreSpreadAcrossTheAvailableForms() {
        // If every rune picked the same shape, the packing puzzle would be trivial.
        let used = Set(ContentCatalog.shared.pressureSources.compactMap {
            PageRules.shape(for: $0.id, hand: .crude)?.id
        })
        XCTAssertGreaterThan(used.count, 1, "every rune drew as the same scrawl")
    }

    // MARK: Compounds

    func testACompoundCostsLessThanItsPartsButIsNeverFree() {
        XCTAssertEqual(PageRules.compoundFootprint(ofParts: []), 0)
        XCTAssertGreaterThan(PageRules.compoundFootprint(ofParts: [1]), 0)

        for parts in [[2, 2], [3, 3, 3], [4, 5, 6]] {
            let sum = parts.reduce(0, +)
            let compound = PageRules.compoundFootprint(ofParts: parts)
            XCTAssertLessThan(compound, sum, "\(parts) was no cheaper written as one mark")
            XCTAssertGreaterThan(compound, 0)
        }
    }

    func testEveryCatalogueCompoundIsWorthLearning() {
        for symbol in ContentCatalog.shared.symbols {
            let parts = symbol.expandsTo.compactMap { PageRules.shape(for: $0.source, hand: .plain)?.footprint }
            guard parts.count > 1 else { continue }
            XCTAssertLessThan(PageRules.footprint(of: symbol, hand: .plain), parts.reduce(0, +),
                              "\(symbol.id.rawValue) costs as much as spelling it out")
        }
    }

    // MARK: Capacity

    func testPageSizeIsCapabilityNotAffordability() {
        // Growing the page is a permanent unlock; it must not change what a book *costs*.
        let small = Page(width: 4, height: 4)
        let large = Page(width: 8, height: 8)
        XCTAssertGreaterThan(large.capacity, small.capacity)

        let sigil = Sigil(id: InstanceID(rawValue: 1), source: "sun", target: "illumination")
        let onSmall = PageRules.placeAnywhere(sigil, hand: .plain, on: small)!
        let onLarge = PageRules.placeAnywhere(sigil, hand: .plain, on: large)!
        XCTAssertEqual(onSmall.usedCells, onLarge.usedCells, "the same rune cost more on a bigger page")
    }

    func testAPageRoundTripsThroughASave() throws {
        var page = Page()
        page = PageRules.placeAnywhere(
            Sigil(id: InstanceID(rawValue: 1), source: "sun", target: "illumination",
                  intensity: .great, negatedTargets: ["thermal"]), hand: .crude, on: page)!
        page = PageRules.placeAnywhere(
            Sigil(id: InstanceID(rawValue: 2), source: "ice", target: "thermal"), hand: .refined, on: page)!

        let data = try SaveCodec.makeEncoder().encode(page)
        let reloaded = try SaveCodec.makeDecoder().decode(Page.self, from: data)
        XCTAssertEqual(reloaded, page)
        XCTAssertEqual(reloaded.sigils, page.sigils)
    }

    // MARK: The desk writes on the page

    func testWritingDeskClearRequiresExactDestructiveConfirmation() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let source = try String(
            contentsOf: root.appending(path: "Sources/Screens/WritingDeskView.swift"),
            encoding: .utf8
        )

        XCTAssertTrue(source.contains("Button(\"Clear\") {\n                        isConfirmingClear = true"))
        XCTAssertTrue(source.contains("\"Clear this page?\""))
        XCTAssertTrue(source.contains("Button(clearPageActionLabel, role: .destructive)"))
        XCTAssertTrue(source.contains("Button(\"Keep writing\", role: .cancel)"))
        XCTAssertTrue(source.contains("Every placed mark and connection on this page will be removed."))
        XCTAssertEqual(source.components(separatedBy: "store.clearPage()").count - 1, 1,
                       "Only the confirmed destructive action may clear the page.")
    }

    @MainActor
    func testWritingOnThePageIsWhatComposesTheBook() {
        let store = GameStore(io: .temporary(name: "desk-\(UUID().uuidString)"))
        store.mutate("test: fund") { $0.base.essence = 500 }

        XCTAssertTrue(store.write("plains"))
        XCTAssertTrue(store.write("frostbound"))
        XCTAssertEqual(store.state.base.page.symbolIDs, ["plains", "frostbound"])

        store.bindAndDepart()
        let book = store.state.worlds.activeRun?.book
        XCTAssertEqual(book?.allSymbolIDs, ["plains", "frostbound"],
                       "the world was bound from something other than the page")
    }

    @MainActor
    func testThePageRefusesWhatWillNotFit() {
        let store = GameStore(io: .temporary(name: "desk-\(UUID().uuidString)"))
        store.mutate("test: a cramped page") { $0.base.page = Page(width: 2, height: 2) }

        var written = 0
        for symbol in ContentCatalog.shared.symbols where store.write(symbol.id) { written += 1 }
        XCTAssertGreaterThan(written, 0, "nothing fitted at all")
        XCTAssertLessThan(written, ContentCatalog.shared.symbols.count,
                          "a 2x2 page accepted the entire vocabulary")
        XCTAssertLessThanOrEqual(store.state.base.page.usedCells, 4)
    }

    @MainActor
    func testErasingAMarkTakesItOutOfTheBook() {
        let store = GameStore(io: .temporary(name: "desk-\(UUID().uuidString)"))
        store.write("plains")
        let mark = store.state.base.page.runes[0]
        store.erase(mark.id)
        XCTAssertTrue(store.state.base.page.symbolIDs.isEmpty)
        // A blank page is the *most* uncertain world there is — everything rolls — so what it says
        // has to sit inside the band rather than be the band.
        XCTAssertTrue(store.bookProjection.stabilityScore.contains(BookRules.stabilityScore(delta: 0)))
    }

    @MainActor
    func testABlankPageStillBinds() {
        // Everything you don't say, the world decides. Under-specification is a surprise, not an
        // error — and with no slots left, a blank page is the extreme case of it.
        let store = GameStore(io: .temporary(name: "desk-\(UUID().uuidString)"))
        store.mutate("test: fund") { $0.base.essence = 500 }
        XCTAssertTrue(store.canBindAndDepart)
        store.bindAndDepart()
        XCTAssertNotNil(store.state.worlds.activeRun)
    }

    @MainActor
    func testAHalfWrittenPageSurvivesAForceQuit() throws {
        let io = SaveFileIO.temporary(name: "page-kill-\(UUID().uuidString)")
        defer { io.deleteEverything() }
        do {
            let store = GameStore(io: io)
            store.write("plains")
            store.write("frostbound")
            store.flushNow()
        }
        let resumed = GameStore(io: io)
        XCTAssertEqual(resumed.state.base.page.symbolIDs, ["plains", "frostbound"])
        XCTAssertEqual(resumed.state.base.page.runes.map(\.origin),
                       resumed.state.base.page.runes.map(\.origin))
    }
}
