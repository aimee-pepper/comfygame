import XCTest
@testable import Bookbinder

/// Session 13: world size is *written*, and a world's day turns while you walk through it.
@MainActor
final class WorldScaleAndNightTests: XCTestCase {

    func testWrittenScaleRungsStraddleUnwrittenOrdinary() {
        XCTAssertEqual(PressureRules.scaleOffset(0), 0)
        XCTAssertEqual(PressureRules.scaleOffset(1), -2)
        XCTAssertEqual(PressureRules.scaleOffset(2), -1)
        XCTAssertEqual(PressureRules.scaleOffset(3), 1)
        XCTAssertEqual(PressureRules.scaleOffset(4), 2)
    }

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
        run.clock = WorldClock(cyclePeak: 50, regularity: 100, seed: run.mapSeed)
        let phase = run.dayPhase
        // Wall-clock time passing changes nothing; only a turn does.
        XCTAssertEqual(run.dayPhase, phase)
        run.turnsTaken += Tuning.DayNight.turnsPerDay / 2
        XCTAssertNotEqual(run.dayPhase, phase)
    }

    func testCyclePeakEightStopsAndNineRunsSlowly() {
        let stopped = WorldClock(cyclePeak: 8, regularity: 70, seed: 1)
        let slow = WorldClock(cyclePeak: 9, regularity: 70, seed: 1)
        XCTAssertTrue(stopped.isStopped)
        XCTAssertEqual(stopped.basePeriod, 0)
        XCTAssertFalse(slow.isStopped)
        XCTAssertEqual(slow.basePeriod, 64)
    }

    func testClockScheduleIsDeterministicAndSurvivesSaveRoundTrip() throws {
        let clock = WorldClock(cyclePeak: 50, regularity: 12, seed: 5515)
        let phases = (0...180).map(clock.phase(at:))
        let data = try SaveCodec.makeEncoder().encode(clock)
        let restored = try SaveCodec.makeDecoder().decode(WorldClock.self, from: data)
        XCTAssertEqual((0...180).map(restored.phase(at:)), phases)
        XCTAssertEqual((0...5).map(clock.period(forCycle:)),
                       (0...5).map(restored.period(forCycle:)))
    }

    func testLowRegularityJittersPeriodsWithinTheAuthoredBound() {
        let clock = WorldClock(cyclePeak: 50, regularity: 0, seed: 991)
        let periods = (0..<12).map(clock.period(forCycle:))
        XCTAssertGreaterThan(Set(periods).count, 1)
        XCTAssertTrue(periods.allSatisfy { (24...56).contains($0) }, "got \(periods)")
    }

    func testStoppedClockNeverChangesPhaseOrSwapsRoster() {
        var run = makeRun()
        run.clock = WorldClock(cyclePeak: 8, regularity: 70, entryPhase: 0.75,
                               entryIsNight: false, seed: run.mapSeed)
        run.cast = [species(nocturnal: false, id: 10), species(nocturnal: true, id: 11)]
        run.enemies = [Worldgen.spawn(run.cast[0], at: GridPoint(x: 1, y: 1), rng: &run.rng)]
        var state = GameState.newGame()
        state.worlds.activeRun = run

        let events = WorldRules.advanceTurn(in: &state)
        XCTAssertEqual(state.worlds.activeRun?.dayPhase, 0.75)
        XCTAssertFalse(events.contains(.nightfall))
        XCTAssertFalse(events.contains(.daybreak))
        XCTAssertEqual(state.worlds.activeRun?.species(of: state.worlds.activeRun!.enemies[0])?.isNocturnal,
                       false)
    }

    func testPreviewNamesClockBandOnlyForWrittenCalibratedCycle() throws {
        var page = Page()
        page = try XCTUnwrap(place(.target("cycle"), at: PageCell(column: 0, row: 0), on: page))
        page = try XCTUnwrap(place(.source("tide"), at: PageCell(column: 1, row: 0), on: page))
        page = try XCTUnwrap(PageRules.connect(page.runes[0].id, page.runes[1].id, on: page))

        XCTAssertNil(BookProjection.project(page: page,
                                             analysisTier: Tuning.Analysis.targetsTier,
                                             measuring: []).clockBand)
        XCTAssertNotNil(BookProjection.project(page: page,
                                                analysisTier: Tuning.Analysis.targetsTier,
                                                measuring: ["cycle"]).clockBand)
        XCTAssertNil(BookProjection.project(page: Page(),
                                             analysisTier: Tuning.Analysis.targetsTier,
                                             measuring: ["cycle"]).clockBand,
                     "an unwritten rolled Cycle leaked into the pre-bind preview")
    }

    func testTransitionDiagnosticsAreReadOnlyAndStoppedWorldsHaveNone() {
        var run = makeRun()
        run.clock = WorldClock(cyclePeak: 50, regularity: 20, seed: run.mapSeed)
        let before = run
        let transitions = run.nextLightTransitions()
        XCTAssertEqual(transitions.count, run.hasDayAndNight ? 2 : 0)
        XCTAssertEqual(run, before, "reading diagnostics changed the run")

        run.clock = WorldClock(cyclePeak: 8, regularity: 70, seed: run.mapSeed)
        XCTAssertTrue(run.nextLightTransitions().isEmpty)
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

    /// The world doesn't repopulate at nightfall — what was out in the day goes, and what's out at
    /// night arrives in its place. Both rosters come from the world's own cast.
    func testTheRosterSwapsAtNightfall() {
        var run = makeRun(book: BoundBook(written: ["dim_sky", "teeming_life"], essencePaid: 0))
        run.cast = [species(nocturnal: false, id: 10), species(nocturnal: true, id: 11)]
        run.enemies = [Worldgen.spawn(run.cast[0], at: GridPoint(x: 1, y: 1), rng: &run.rng)]

        WorldRules.swapRoster(in: &run, toNight: true)

        XCTAssertEqual(run.species(of: run.enemies[0])?.isNocturnal, true,
                       "the day roster stayed out after dark")
        XCTAssertFalse(run.enemies[0].isAwake, "a swapped-in creature started already hunting")
        XCTAssertNotNil(run.enemies[0].traits, "the night shift arrived without a body")
    }

    /// A world whose animals all keep the same hours simply doesn't change shift — better than
    /// emptying the map at dusk.
    func testAWorldWithNoNightShiftKeepsWhatItHas() {
        var run = makeRun()
        run.cast = [species(nocturnal: false, id: 10)]
        run.enemies = [Worldgen.spawn(run.cast[0], at: GridPoint(x: 1, y: 1), rng: &run.rng)]
        let before = run.enemies

        WorldRules.swapRoster(in: &run, toNight: true)
        XCTAssertEqual(run.enemies, before)
    }

    /// Nocturnality is **derived**, not authored: a thing that hunts by touch has no reason to keep
    /// daytime hours, and neither has a thing that carries its own light.
    func testWhoKeepsNightHoursIsReadOffWhatTheySenseWith() {
        var eyed = CreatureTraits()
        eyed.sensory = Sensory.allocation(vision: 80, mechano: 10, chemo: 5, thermo: 5)
        XCTAssertFalse(CreatureIdentity.isNocturnal(eyed))

        var groper = CreatureTraits()
        groper.sensory = Sensory.allocation(vision: 4, mechano: 60, chemo: 30, thermo: 6)
        XCTAssertTrue(CreatureIdentity.isNocturnal(groper))
    }

    /// Darkness costs a creature that doesn't use its eyes nothing at all.
    func testTheDarkCostsAnEyedCreatureItsRangeAndABlindOneNothing() {
        var run = makeRun()
        guard run.hasDayAndNight else { return }
        let eyed = Worldgen.spawn(species(nocturnal: false, id: 1), at: GridPoint(x: 1, y: 1), rng: &run.rng)
        let blind = Worldgen.spawn(species(nocturnal: true, id: 2), at: GridPoint(x: 2, y: 2), rng: &run.rng)

        run.turnsTaken = 0
        let eyedByDay = WorldRules.detectionRadius(of: eyed, in: run)
        let blindByDay = WorldRules.detectionRadius(of: blind, in: run)
        run.turnsTaken = Int(Double(Tuning.DayNight.turnsPerDay) * 0.95)
        XCTAssertTrue(run.isNight)

        XCTAssertLessThan(WorldRules.detectionRadius(of: eyed, in: run), eyedByDay,
                          "the dark cost an eyed creature nothing")
        XCTAssertEqual(WorldRules.detectionRadius(of: blind, in: run), blindByDay,
                       "the dark blinded something that doesn't use its eyes")
    }

    // MARK: Helpers

    private func makeRun(book: BoundBook = BoundBook(written: ["dim_sky"], essencePaid: 0)) -> WorldRun {
        let world = Worldgen.generate(book: book, seed: 20_260_805)
        return WorldRun(runIndex: 1, book: book, mapSeed: 20_260_805,
                        rng: SeededRNG(seed: 1), map: world.map, playerPosition: world.start,
                        cast: world.cast)
    }

    private func species(nocturnal: Bool, id: UInt64) -> Species {
        var traits = CreatureTraits()
        traits.size = 40
        traits.sensory = nocturnal
            ? Sensory.allocation(vision: 3, mechano: 60, chemo: 30, thermo: 7)
            : Sensory.allocation(vision: 80, mechano: 10, chemo: 5, thermo: 5)
        return Species(id: InstanceID(rawValue: id), traits: traits, worldSeed: 1)
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
