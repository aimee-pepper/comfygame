import XCTest
@testable import Bookbinder

/// Terrain — the prerequisite the generation spine names first. Until tiles had ground, **Relief
/// had nothing to write to**, and every "openness sets ambush versus pursuit" rule was
/// unimplementable.
final class TerrainTests: XCTestCase {

    // MARK: Substrate decides what's underfoot

    func testHardGroundMakesStoneAndDuctileGroundMakesSand() {
        let stony = ground(in: world(["granite": "substrate"]))
        let loose = ground(in: world(["sand": "substrate"]))
        XCTAssertGreaterThan(stony[.stone, default: 0], loose[.stone, default: 0],
                             "hard substrate didn't become stone")
        XCTAssertGreaterThan(loose[.sand, default: 0], stony[.sand, default: 0])
    }

    func testVolatileGroundIsBrokenAndAshy() {
        let volatile = ground(in: world(["sulfur": "substrate", "magma": "thermal"]))
        XCTAssertGreaterThan(volatile[.rubble, default: 0] + volatile[.ash, default: 0], 0,
                             "unstable ground came out as neither broken nor ashy")
    }

    // MARK: Hydrology paints water, thermal decides its form

    func testAWetWorldHasWaterInIt() {
        let wet = ground(in: world(["sea": "hydrology", "rain": "hydrology"]))
        let dry = ground(in: world(["sand": "substrate"]))
        let wetShare = wet[.water, default: 0] + wet[.deepWater, default: 0] + wet[.ice, default: 0]
        let dryShare = dry[.water, default: 0] + dry[.deepWater, default: 0] + dry[.ice, default: 0]
        XCTAssertGreaterThan(wetShare, dryShare, "a sea world had no more water than a desert")
    }

    /// Write "Sea" on a frozen world and you get a glacier whether you asked for one or not.
    ///
    /// The cold is written rather than rolled. This used to lean on a rolled atmosphere to get the
    /// thermal floor under freezing, which meant editing an unrelated source could break it.
    func testAFrozenWorldsWaterIsIce() {
        let frozen = ground(in: world(["sea": "hydrology", "glacier": "thermal",
                                       "ice": "thermal", "snow": "thermal"]))
        XCTAssertEqual(frozen[.water, default: 0], 0, "liquid water survived a frozen world")
        XCTAssertGreaterThan(frozen[.ice, default: 0], 0,
                             "a world of sea and glacier came out as bare rock")
    }

    func testLiquidWaterMakesAVisibleMudEdgeButIceDoesNot() {
        let wet = ground(in: world(["sea": "hydrology", "rain": "hydrology"]))
        let frozen = ground(in: world(["sea": "hydrology", "glacier": "thermal",
                                       "ice": "thermal", "snow": "thermal"]))
        XCTAssertGreaterThan(wet[.mud, default: 0], 0, "liquid water met soil without making mud")
        XCTAssertEqual(frozen[.mud, default: 0], 0, "a frozen shore somehow made mud")
    }

    // MARK: Vitality is cover — through the plants it grows

    func testAProductiveWorldIsOvergrown() {
        let lush = ground(in: world(["bloom": "vitality", "root": "vitality", "sun": "illumination"]))
        let covered = lush[.growth, default: 0] + lush[.groundcover, default: 0]
        XCTAssertGreaterThan(covered, 0, "nothing grew in a teeming world")
    }

    /// **Nothing paints growth but flora.** `growth` used to be scattered per-tile straight off
    /// Vitality, so cover was a uniform porosity with nothing to do with what grew here — which is
    /// the fault `flora-system-spec.md` §5 opens with.
    func testGroundIsOnlyOvergrownWhereSomethingGrows() {
        let readings = world(["bloom": "vitality", "root": "vitality", "sun": "illumination"])
        var map = WorldMap(width: 18, height: 18,
                           tiles: Array(repeating: Tile(), count: 324),
                           entry: GridPoint(x: 0, y: 0))
        var rng = SeededRNG(seed: 99)
        TerrainRules.paint(&map, readings: readings, flora: [], rng: &rng)
        XCTAssertFalse(map.tiles.contains { $0.ground.isOvergrown },
                       "a world with no flora was overgrown anyway")
    }

    /// Every overgrown tile knows which plant is on it — which is what lets the harvest, the hazard
    /// and the description all read the same thing.
    func testEveryOvergrownTileKnowsWhatIsGrowingOnIt() {
        let world = Worldgen.generate(book: book(["teeming_life", "sun"]), seed: 4242)
        let grown = Set(world.flora.map(\.id))
        XCTAssertFalse(grown.isEmpty, "a teeming lit world grew nothing")
        for point in world.map.allPoints where world.map[point].ground.isOvergrown {
            guard let id = world.map[point].flora else {
                return XCTFail("overgrown ground with nothing growing on it at \(point)")
            }
            XCTAssertTrue(grown.contains(id), "a tile pointed at a plant this world doesn't have")
        }
    }

    /// **Stature decides whether cover hides anything** (§5). Groundcover shouldn't; canopy should.
    func testShortGrowthDoesNotBreakASightlineAndTallGrowthDoes() {
        XCTAssertFalse(GroundType.groundcover.blocksSight, "you couldn't see over a lawn")
        XCTAssertTrue(GroundType.growth.blocksSight)
        XCTAssertTrue(GroundType.groundcover.isOvergrown && GroundType.growth.isOvergrown)
    }

    // MARK: Relief writes elevation

    func testBrokenCountryIsHighCountryAndOpenGroundIsFlat() {
        let broken = Worldgen.generate(book: book(["caverns"]), seed: 7).map
        let flat = Worldgen.generate(book: book(["plains"]), seed: 7).map
        let brokenHeight = broken.tiles.reduce(0) { $0 + $1.elevation }
        let flatHeight = flat.tiles.reduce(0) { $0 + $1.elevation }
        XCTAssertGreaterThanOrEqual(brokenHeight, flatHeight,
                                    "enclosed country was no more broken than open ground")
    }

    // MARK: The ground has to be liveable

    func testYouNeverArriveSomewhereYouCannotStand() {
        for seed in UInt64(1)...40 {
            let world = Worldgen.generate(book: book(["archipelago"]), seed: seed)
            XCTAssertTrue(world.map[world.start].isPassable,
                          "spawned in deep water, seed \(seed)")
        }
    }

    func testNothingIsPlacedWhereNobodyCanStand() {
        for seed in UInt64(1)...30 {
            let world = Worldgen.generate(book: book(["archipelago"]), seed: seed)
            for point in world.map.allPoints where world.map[point].content != .empty {
                XCTAssertTrue(world.map[point].isPassable,
                              "something was placed in impassable ground, seed \(seed)")
            }
            for enemy in world.enemies {
                XCTAssertTrue(world.map[enemy.position].isPassable, "an enemy stood in deep water")
            }
        }
    }

    // MARK: Cover stops sight

    func testYouSeeFurtherAcrossOpenGroundThanThroughCover() {
        func revealed(_ symbols: [SymbolID]) -> Int {
            var world = Worldgen.generate(book: book(symbols), seed: 4242)
            var map = world.map
            map.tiles.indices.forEach { map.tiles[$0].isRevealed = false }
            WorldRules.reveal(around: world.start, in: &map, radius: 4)
            world.map = map
            return map.tiles.count { $0.isRevealed }
        }
        // A world thick with growth should reveal less from one spot than a bare one.
        XCTAssertLessThanOrEqual(revealed(["teeming_life"]), revealed(["sparse_ore"]) + 4,
                                 "cover didn't shorten sightlines at all")
    }

    func testTheThingBlockingYourViewIsItselfVisible() {
        // You can see the thicket. You just can't see past it.
        var map = WorldMap(width: 5, height: 1,
                           tiles: Array(repeating: Tile(), count: 5),
                           entry: GridPoint(x: 0, y: 0))
        map[GridPoint(x: 2, y: 0)].ground = .growth
        WorldRules.reveal(around: GridPoint(x: 0, y: 0), in: &map, radius: 4)

        XCTAssertTrue(map[GridPoint(x: 2, y: 0)].isRevealed, "the cover itself was invisible")
        XCTAssertFalse(map[GridPoint(x: 4, y: 0)].isRevealed, "sight went straight through cover")
    }

    // MARK: Saving

    func testTerrainSurvivesASaveAndAnOlderOneStillLoads() throws {
        var tile = Tile()
        tile.ground = .ice
        tile.elevation = 2
        let data = try SaveCodec.makeEncoder().encode(tile)
        XCTAssertEqual(try SaveCodec.makeDecoder().decode(Tile.self, from: data), tile)

        // A tile written before ground existed.
        let old = Data(#"{"isRevealed":true,"isCrumbled":false,"content":{"empty":{}}}"#.utf8)
        let loaded = try SaveCodec.makeDecoder().decode(Tile.self, from: old)
        XCTAssertEqual(loaded.ground, .soil)
        XCTAssertTrue(loaded.isRevealed)
    }

    // MARK: Helpers

    private func book(_ symbols: [SymbolID]) -> BoundBook {
        BoundBook(written: symbols, essencePaid: 0)
    }

    /// - Parameter rollingTheRest: whether the subjects you didn't write are filled from a seed.
    ///
    ///   **Off by default.** A test asserting *"a frozen world's water is ice"* is about what was
    ///   written, and letting six other subjects roll around it means the assertion can be broken by
    ///   editing an unrelated source — which is exactly what happened when Second Light and Rift
    ///   were cut and a fixed seed started picking different focuses (6 Aug).
    private func world(_ pairs: [String: String], rollingTheRest: Bool = false) -> PressureReadings {
        let sigils = pairs.sorted { $0.key < $1.key }.enumerated().map { index, pair in
            Sigil(id: InstanceID(rawValue: UInt64(index + 1)),
                  source: PressureSourceID(rawValue: pair.key),
                  target: PressureTargetID(rawValue: pair.value),
                  intensity: .great)
        }
        return rollingTheRest
            ? PressureRules.resolve(sigils, fillingUnwrittenWith: 20_260_805)
            : PressureRules.resolve(sigils)
    }

    /// Share of the map given over to each ground type.
    ///
    /// Flora is sampled from the same readings, because that is how a world is painted now: cover
    /// comes from what grows, not from Vitality directly.
    private func ground(in readings: PressureReadings) -> [GroundType: Double] {
        var map = WorldMap(width: 18, height: 18,
                           tiles: Array(repeating: Tile(), count: 324),
                           entry: GridPoint(x: 0, y: 0))
        var rng = SeededRNG(seed: 99)
        TerrainRules.paint(&map, readings: readings,
                           flora: FloraRules.cast(for: readings, seed: 99), rng: &rng)
        var counts: [GroundType: Double] = [:]
        for tile in map.tiles { counts[tile.ground, default: 0] += 1 / Double(map.tiles.count) }
        return counts
    }
}
