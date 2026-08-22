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

    func testGeneratedTerrainElevationIsCoherentAfterOverlays() {
        for seed in UInt64(1)...24 {
            let map = Worldgen.generate(book: book(["caverns", "sulfur", "sand"]), seed: seed).map
            for point in map.allPoints where !map[point].baseGround.isOvergrown {
                for neighbour in map.neighbours(of: point) {
                    XCTAssertLessThanOrEqual(abs(map[point].elevation - map[neighbour].elevation), 1)
                }
            }
        }
    }

    func testSubstrateStagePreservesExactQuotasConnectivityAndVariesBySeed() {
        let weights: [(GroundType, Double)] = [
            (.stone, 41), (.soil, 29), (.sand, 17), (.rubble, 9), (.ash, 4),
        ]
        var signatures: Set<String> = []
        for seed in UInt64(1)...8 {
            let result = TerrainRules.substrateStageForTesting(
                width: 18, height: 18, weights: weights, dispersion: 82, seed: seed)
            XCTAssertEqual(result.diagnostics.quotas.values.reduce(0, +), 324)
            for material in [GroundType.stone, .soil, .sand, .rubble, .ash] {
                XCTAssertEqual(result.map.tiles.count { $0.baseGround == material },
                               result.diagnostics.quotas[material, default: 0])
                XCTAssertLessThanOrEqual(result.diagnostics.componentSizes[material, default: []].count, 4)
                XCTAssertTrue(result.diagnostics.componentSizes[material, default: []].allSatisfy { $0 > 1 })
            }
            XCTAssertTrue(result.map.allPoints.allSatisfy { point in
                result.map.neighbours(of: point).contains {
                    result.map[$0].baseGround == result.map[point].baseGround
                }
            })
            var remaining = Set(result.map.allPoints)
            while let start = remaining.sorted(by: { ($0.y, $0.x) < ($1.y, $1.x) }).first {
                let material = result.map[start].baseGround
                var component: Set<GridPoint> = [start], queue = [start]
                remaining.remove(start)
                while let point = queue.popLast() {
                    for next in result.map.neighbours(of: point)
                    where remaining.contains(next) && result.map[next].baseGround == material {
                        remaining.remove(next); component.insert(next); queue.append(next)
                    }
                }
                if component.count >= 8 {
                    XCTAssertGreaterThan(Set(component.map(\.x)).count, 1)
                    XCTAssertGreaterThan(Set(component.map(\.y)).count, 1)
                    XCTAssertTrue(component.contains { point in
                        component.contains(.init(x: point.x + 1, y: point.y))
                            && component.contains(.init(x: point.x, y: point.y + 1))
                            && component.contains(.init(x: point.x + 1, y: point.y + 1))
                    }, "large substrate component was a stripe")
                }
            }
            signatures.insert(result.map.tiles.map(\.baseGround.rawValue).joined(separator: ","))
        }
        XCTAssertGreaterThan(signatures.count, 4, "terrain shapes did not materially vary by seed")
    }

    func testSubstrateRetriesCoverLiveSizesWeightExtremesAndDispersionBands() {
        let weights: [[(GroundType, Double)]] = [
            [(.stone, 1)],
            [(.stone, 99), (.soil, 1)],
            [(.stone, 20), (.soil, 20), (.sand, 20), (.rubble, 20), (.ash, 20)],
            [(.stone, 41), (.soil, 29), (.sand, 17), (.rubble, 9), (.ash, 4)],
        ]
        for size in [12, 15, 18, 23, 28] {
            for dispersion in [0.0, 50, 100] {
                for (weightIndex, distribution) in weights.enumerated() {
                    let seed = UInt64(weightIndex * 100_000 + size * 1_000 + Int(dispersion))
                    guard let result = TerrainRules.substrateStageIfPossibleForTesting(
                        width: size, height: size, weights: distribution,
                        dispersion: dispersion, seed: seed) else {
                        XCTFail("failed size \(size), dispersion \(dispersion), weights \(weightIndex)")
                        continue
                    }
                    XCTAssertEqual(result.diagnostics.quotas.values.reduce(0, +), size * size)
                    for material in [GroundType.stone, .soil, .sand, .rubble, .ash] {
                        let components = result.diagnostics.components[material, default: []]
                        XCTAssertEqual(components.reduce(0) { $0 + $1.count },
                                       result.diagnostics.quotas[material, default: 0])
                        XCTAssertTrue(components.allSatisfy { $0.count > 1 })
                        for component in components where component.count >= 8 {
                            let owned = Set(component)
                            XCTAssertGreaterThan(Set(component.map(\.x)).count, 1)
                            XCTAssertGreaterThan(Set(component.map(\.y)).count, 1)
                            XCTAssertTrue(component.contains { point in
                                owned.contains(.init(x: point.x + 1, y: point.y))
                                    && owned.contains(.init(x: point.x, y: point.y + 1))
                                    && owned.contains(.init(x: point.x + 1, y: point.y + 1))
                            }, "stripe at size \(size), dispersion \(dispersion), weights \(weightIndex)")
                        }
                    }
                }
            }
        }
    }

    func testSurfaceDepositsAreTwoIndependentPersistedBitsAndAmplitudeIsMonotonic() throws {
        func painted(_ sigils: [Sigil]) -> WorldMap {
            let readings = PressureRules.resolve(sigils)
            var map = WorldMap(width: 18, height: 18,
                               tiles: Array(repeating: Tile(), count: 324),
                               entry: .init(x: 0, y: 0))
            var rng = SeededRNG(seed: 777)
            TerrainRules.paint(&map, readings: readings, resolvedSigils: sigils,
                               visualSeed: 777, rng: &rng)
            return map
        }
        func sigil(_ id: UInt64, _ source: String, _ target: String,
                   _ intensity: Intensity) -> Sigil {
            .init(id: .init(rawValue: id), source: .init(rawValue: source),
                  target: .init(rawValue: target), intensity: intensity)
        }
        let faint = painted([sigil(1, "snow", "hydrology", .faint)])
        let moderate = painted([sigil(1, "snow", "hydrology", .moderate)])
        let great = painted([sigil(1, "snow", "hydrology", .great)])
        let overwhelming = painted([sigil(1, "snow", "hydrology", .overwhelming)])
        let counts = [faint, moderate, great, overwhelming].map {
            $0.tiles.count { $0.surfaceDeposits.snow }
        }
        XCTAssertTrue(zip(counts, counts.dropFirst()).allSatisfy { $0 < $1 })
        let doubled = painted([sigil(1, "snow", "hydrology", .moderate),
                               sigil(2, "snow", "hydrology", .moderate)])
        XCTAssertGreaterThan(doubled.tiles.count { $0.surfaceDeposits.snow }, counts[1])
        let scaleCounts = [1, 2, 3, 4].map { scale in
            painted([.init(id: .init(rawValue: 9), source: "snow", target: "hydrology",
                            intensity: .moderate, scale: scale)])
                .tiles.count { $0.surfaceDeposits.snow }
        }
        XCTAssertTrue(zip(scaleCounts, scaleCounts.dropFirst()).allSatisfy { $0 < $1 })
        let countCounts = [1, 2, 4].map { count in
            painted([.init(id: .init(rawValue: 10), source: "snow", target: "hydrology",
                            intensity: .moderate, count: count)])
                .tiles.count { $0.surfaceDeposits.snow }
        }
        XCTAssertTrue(zip(countCounts, countCounts.dropFirst()).allSatisfy { $0 < $1 })
        let none = painted([])
        XCTAssertFalse(none.tiles.contains { $0.surfaceDeposits.snow || $0.surfaceDeposits.settledAsh })
        let ashOnly = painted([sigil(2, "ash", "substrate", .great)])
        XCTAssertFalse(ashOnly.tiles.contains { $0.surfaceDeposits.snow })
        XCTAssertTrue(ashOnly.tiles.contains { $0.surfaceDeposits.settledAsh })
        let both = painted([sigil(1, "snow", "hydrology", .great),
                            sigil(2, "ash", "substrate", .great)])
        XCTAssertTrue(both.tiles.contains { $0.surfaceDeposits.snow })
        XCTAssertTrue(both.tiles.contains { $0.surfaceDeposits.settledAsh })
        XCTAssertTrue(both.tiles.contains { $0.surfaceDeposits.snow && $0.surfaceDeposits.settledAsh })
        XCTAssertEqual(try SaveCodec.makeDecoder().decode(WorldMap.self,
            from: SaveCodec.makeEncoder().encode(both)), both)
    }

    func testControlledHydrologyFormsAndThermalConversionPreserveCoverage() {
        func reading(forms: [String: Double], peak: Double = 100) -> PressureReading {
            .init(target: .init(rawValue: "hydrology"), peak: peak, demand: peak, floor: peak,
                  opposedMagnitude: 0, aspects: ["dispersion": 20], forms: forms, tags: [])
        }
        func wetCount(_ map: WorldMap) -> Int {
            map.tiles.count { [.water, .deepWater, .ice].contains($0.baseGround) }
        }
        let standing = TerrainRules.hydrologyStageForTesting(
            width: 18, height: 18, water: reading(forms: ["standing": 1]),
            freezing: false, seed: 81)
        let frozen = TerrainRules.hydrologyStageForTesting(
            width: 18, height: 18, water: reading(forms: ["frozen": 1]),
            freezing: false, seed: 81)
        let airborne = TerrainRules.hydrologyStageForTesting(
            width: 18, height: 18, water: reading(forms: ["airborne": 1]),
            freezing: false, seed: 81)
        let thermallyFrozen = TerrainRules.hydrologyStageForTesting(
            width: 18, height: 18, water: reading(forms: ["standing": 0.6, "flowing": 0.4]),
            freezing: true, seed: 81)
        let liquid = TerrainRules.hydrologyStageForTesting(
            width: 18, height: 18, water: reading(forms: ["standing": 0.6, "flowing": 0.4]),
            freezing: false, seed: 81)

        XCTAssertGreaterThan(standing.tiles.count { $0.baseGround == .water || $0.baseGround == .deepWater }, 0)
        XCTAssertGreaterThan(frozen.tiles.count { $0.baseGround == .ice }, 0)
        XCTAssertEqual(wetCount(airborne), 0)
        XCTAssertEqual(wetCount(thermallyFrozen), wetCount(liquid),
                       "thermal freezing minted or removed surface-water coverage")
        XCTAssertEqual(thermallyFrozen.tiles.count { $0.baseGround == .ice }, wetCount(thermallyFrozen))
        XCTAssertEqual(Set(thermallyFrozen.allPoints.filter { thermallyFrozen[$0].baseGround == .ice }),
                       Set(liquid.allPoints.filter {
                           liquid[$0].baseGround == .water || liquid[$0].baseGround == .deepWater
                               || liquid[$0].baseGround == .ice
                       }), "thermal freezing changed authored hydrology morphology")

        var remainingWater = Set(standing.allPoints.filter {
            standing[$0].baseGround == .water || standing[$0].baseGround == .deepWater
        })
        while let first = remainingWater.sorted(by: { ($0.y, $0.x) < ($1.y, $1.x) }).first {
            var body: Set<GridPoint> = [first], queue = [first]
            remainingWater.remove(first)
            while let point = queue.popLast() {
                for next in standing.neighbours(of: point)
                where remainingWater.remove(next) != nil { body.insert(next); queue.append(next) }
            }
            let deep = body.filter { standing[$0].baseGround == .deepWater }
            guard let deepFirst = deep.first else { continue }
            var seen: Set<GridPoint> = [deepFirst], deepQueue = [deepFirst]
            while let point = deepQueue.popLast() {
                for next in standing.neighbours(of: point)
                where deep.contains(next) && seen.insert(next).inserted { deepQueue.append(next) }
            }
            XCTAssertEqual(seen, Set(deep), "one Standing body's deep core was disconnected")
            XCTAssertTrue(deep.allSatisfy { point in
                standing.neighbours(of: point).contains(where: body.contains)
            }, "deep cell was isolated from its owning body")
        }
    }

    func testControlledFlowingWaterRoutesDownhillToBoundary() {
        let width = 12, height = 12
        let elevations = (0..<(width * height)).map { index in
            max(0, 3 - index / width / 3)
        }
        let result = TerrainRules.flowingStageForTesting(
            width: width, height: height, elevations: elevations, quota: 18,
            dispersion: 0, peak: 80, seed: 404)
        let route = try! XCTUnwrap(result.diagnostics.first?.route)
        let channel = try! XCTUnwrap(result.diagnostics.first)
        XCTAssertTrue(channel.source.x > 0 && channel.source.y > 0
            && channel.source.x < width - 1 && channel.source.y < height - 1)
        let sorted = elevations.sorted()
        let quartile = sorted[max(0, sorted.count * 3 / 4 - 1)]
        XCTAssertGreaterThanOrEqual(result.map[route[0]].elevation, quartile)
        XCTAssertTrue(zip(route, route.dropFirst()).allSatisfy { lhs, rhs in
            abs(lhs.x - rhs.x) + abs(lhs.y - rhs.y) == 1
                && result.map[rhs].elevation <= result.map[lhs].elevation
        })
        let outlet = route.last!
        XCTAssertTrue(outlet.x == 0 || outlet.y == 0 || outlet.x == width - 1 || outlet.y == height - 1)
        XCTAssertEqual(result.map.tiles.count {
            $0.baseGround == .water || $0.baseGround == .deepWater
        }, 18)
        let xs = channel.tiles.map(\.x), ys = channel.tiles.map(\.y)
        XCTAssertGreaterThanOrEqual((xs.max()! - xs.min()!) + (ys.max()! - ys.min()!),
                                    channel.tiles.count / 3)
        let owned = Set(channel.tiles)
        let blocks = channel.tiles.count { point in
            owned.contains(.init(x: point.x + 1, y: point.y))
                && owned.contains(.init(x: point.x, y: point.y + 1))
                && owned.contains(.init(x: point.x + 1, y: point.y + 1))
        }
        XCTAssertLessThanOrEqual(blocks, channel.tiles.count / 4,
                                 "Flowing allocation broadened into a pond")

        let flat = TerrainRules.flowingStageForTesting(
            width: width, height: height, elevations: Array(repeating: 1, count: width * height),
            quota: 12, dispersion: 0, peak: 80, seed: 405)
        XCTAssertFalse(flat.diagnostics.isEmpty, "flat Flowing water fell back to Standing")
        XCTAssertEqual(flat.map.tiles.count {
            $0.baseGround == .water || $0.baseGround == .deepWater
        }, 12)
    }

    func testFlowingChannelsCanJoinAndMixedFormsKeepLargestRemainderBudgets() {
        let width = 18, height = 18
        let flat = Array(repeating: 1, count: width * height)
        let joined = TerrainRules.flowingStageForTesting(
            width: width, height: height, elevations: flat, quota: 48,
            dispersion: 100, peak: 80, seed: 901)
        XCTAssertGreaterThan(joined.diagnostics.count, 1)
        XCTAssertTrue(joined.diagnostics.dropFirst().contains(where: \.joinedExistingChannel))

        let water = PressureReading(
            target: "hydrology", peak: 100, demand: 100, floor: 100,
            opposedMagnitude: 0, aspects: ["dispersion": 20],
            forms: ["standing": 0.3, "flowing": 0.4, "frozen": 0.3], tags: [])
        let mixed = TerrainRules.hydrologyStageWithDiagnosticsForTesting(
            width: width, height: height, elevations: flat,
            water: water, freezing: false, seed: 902)
        XCTAssertEqual(mixed.diagnostics.allocated.reduce(0, +), 146)
        XCTAssertEqual(mixed.diagnostics.allocated, [44, 58, 44])
        XCTAssertEqual(mixed.diagnostics.standingTiles, 44)
        XCTAssertEqual(mixed.diagnostics.flowingTiles, 58)
        XCTAssertEqual(mixed.diagnostics.frozenTiles, 44)
        XCTAssertEqual(mixed.map.tiles.count {
            $0.baseGround == .water || $0.baseGround == .deepWater || $0.baseGround == .ice
        }, 146)
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
        tile.baseGround = .stone
        tile.surfaceDeposits = .init(snow: true, settledAsh: true)
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
