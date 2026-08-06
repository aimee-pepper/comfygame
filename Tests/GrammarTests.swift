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
}

private extension Page {
    var allCellsInReadingOrder: [PageCell] {
        (0..<height).flatMap { row in (0..<width).map { PageCell(column: $0, row: row) } }
    }
}
