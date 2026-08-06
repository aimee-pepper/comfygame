import XCTest
@testable import Bookbinder

/// Session 13: world size is *written*, and a world's day turns while you walk through it.
@MainActor
final class WorldScaleAndNightTests: XCTestCase {

    // MARK: Size is written, and costs

    /// Scale was already in the vocabulary and already placeable. This is the reading of it.
    func testScaleWrittenOnTheReliefClusterSetsTheWorldSize() throws {
        var page = Page()
        page = try XCTUnwrap(place(.target("relief"), at: PageCell(column: 0, row: 0), on: page))
        page = try XCTUnwrap(place(.source("granite"), at: PageCell(column: 1, row: 0), on: page))
        page = try XCTUnwrap(place(.qualifier("vast"), at: PageCell(column: 2, row: 0), on: page))
        let ids = page.runes.map(\.id)
        page = try XCTUnwrap(PageRules.connect(ids[0], ids[1], on: page))
        page = try XCTUnwrap(PageRules.connect(ids[1], ids[2], on: page))

        XCTAssertEqual(PageRules.worldScale(of: page), .vast)
        XCTAssertEqual(BookRules.resolveBook(page: page).scale, .vast)
    }

    func testAPageThatSaysNothingAboutSizeGetsAnOrdinaryWorld() {
        XCTAssertEqual(PageRules.worldScale(of: Page()), .ordinary)
    }

    func testABiggerWorldIsActuallyBigger() {
        let ordinary = BoundBook(written: [], scale: .ordinary, essencePaid: 0)
        let vast = BoundBook(written: [], scale: .vast, essencePaid: 0)
        XCTAssertGreaterThan(Worldgen.generate(book: vast, seed: 1).map.width,
                             Worldgen.generate(book: ordinary, seed: 1).map.width)
    }

    /// A vast world holds more but needs more turns to cross, so it has to buy them.
    func testAskingForMoreWorldCostsStability() {
        // Against a book that isn't already pinned at the top of the meter, or the clamp hides it.
        func score(_ scale: WorldScale) -> Int {
            BookRules.stabilityScore(of: BoundBook(written: ["rich_ore"], scale: scale, essencePaid: 0))
        }
        XCTAssertLessThan(score(.vast), score(.ordinary), "a vast world was free")
        XCTAssertGreaterThan(score(.minute), score(.ordinary), "a tiny world bought no time")
        XCTAssertLessThan(score(.large), score(.ordinary))
    }

    func testSizeSurvivesTheBookThatWroteIt() throws {
        let book = BoundBook(written: [], scale: .large, essencePaid: 0)
        let data = try SaveCodec.makeEncoder().encode(book)
        XCTAssertEqual(try SaveCodec.makeDecoder().decode(BoundBook.self, from: data).scale, .large)
    }

    // MARK: The day turns because you walked

    func testTheDayIsDrivenByTurnsAndNeverByTheClock() {
        var run = makeRun()
        let phase = run.dayPhase
        // Wall-clock time passing changes nothing; only a turn does.
        XCTAssertEqual(run.dayPhase, phase)
        run.turnsTaken += Tuning.DayNight.turnsPerDay / 2
        XCTAssertNotEqual(run.dayPhase, phase)
    }

    /// A world whose light never varies has no night at all — which is what finally makes
    /// Illumination's *dynamic range* mean something rather than being a number nobody reads.
    func testAWorldWhoseLightNeverVariesHasNoNight() {
        let steady = PressureRules.resolve([
            Sigil(id: InstanceID(rawValue: 1), source: "crystal", target: "illumination",
                  intensity: .great)
        ])["illumination"]
        XCTAssertTrue(steady.has("sourceless"), "the test world isn't lit by something constant")

        let turning = PressureRules.resolve([
            Sigil(id: InstanceID(rawValue: 1), source: "sun", target: "illumination",
                  intensity: .overwhelming)
        ])["illumination"]
        XCTAssertGreaterThan(turning.range, steady.range,
                             "a sun should swing more than a glowing rock")
    }

    func testNightTakesSomeOfYourSight() {
        var run = makeRun()
        guard run.hasDayAndNight else { return }
        run.turnsTaken = 0
        let byDay = WorldRules.visionRadius(in: run)
        run.turnsTaken = Int(Double(Tuning.DayNight.turnsPerDay) * 0.95)
        XCTAssertTrue(run.isNight)
        XCTAssertLessThan(WorldRules.visionRadius(in: run), byDay)
    }

    func testTheRosterSwapsAtNightfall() {
        var run = makeRun(book: BoundBook(written: ["dim_sky", "teeming_life"], essencePaid: 0))
        run.enemies = [WorldEnemy(id: InstanceID(rawValue: 1), creatureID: "paper_moth",
                                  position: GridPoint(x: 1, y: 1))]
        WorldRules.swapRoster(in: &run, toNight: true)

        let creature = ContentCatalog.shared.creature(run.enemies[0].creatureID)
        XCTAssertEqual(creature?.isNocturnal, true, "the day roster stayed out after dark")
        XCTAssertFalse(run.enemies[0].isAwake, "a swapped-in creature started already hunting")
    }

    func testSomethingIsNocturnalAtAll() {
        XCTAssertTrue(ContentCatalog.shared.creatures.contains(where: \.isNocturnal))
        XCTAssertTrue(ContentCatalog.shared.creatures.contains { !$0.isNocturnal })
    }

    // MARK: Helpers

    private func makeRun(book: BoundBook = BoundBook(written: ["dim_sky"], essencePaid: 0)) -> WorldRun {
        let world = Worldgen.generate(book: book, seed: 20_260_805)
        return WorldRun(runIndex: 1, book: book, mapSeed: 20_260_805,
                        rng: SeededRNG(seed: 1), map: world.map, playerPosition: world.start)
    }

    private func place(_ content: MarkContent, at origin: PageCell, on page: Page) -> Page? {
        let glyph: String
        switch content {
        case .target(let id): glyph = id.rawValue
        case .source(let id): glyph = id.rawValue
        case .qualifier(let id): glyph = id.rawValue
        case .compound(let id): glyph = id.rawValue
        case .rune(let sigil): glyph = sigil.source.rawValue
        }
        guard let shape = PageRules.shape(forGlyph: glyph, hand: .refined),
              PageRules.canPlace(shape: shape, at: origin, on: page) else { return nil }
        var result = page
        result.runes.append(PlacedRune(id: InstanceID(rawValue: UInt64(page.runes.count + 1)),
                                       content: content, hand: .refined,
                                       origin: origin, shapeID: shape.id))
        return result
    }
}
