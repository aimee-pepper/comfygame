import XCTest
@testable import Bookbinder

/// Terrain — the prerequisite the generation spine names first. Until tiles had ground, **Relief
/// had nothing to write to**, and every "openness sets ambush versus pursuit" rule was
/// unimplementable.
final class TerrainTests: XCTestCase {

    func testEveryMineralHostClauseMatchesMachineAuthorityExhaustively() throws {
        struct Authority: Decodable { let resourceHosts: [Host] }
        struct Host: Decodable {
            let resourceID: String
            let placementKind: String
            let clauses: [Clause]?
        }
        struct Clause: Decodable {
            let baseGroundIDs: [String]
            let minimumElevation: Int
            let maximumElevation: Int
            let adjacentAnyGroundIDs: [String]?
        }
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let authority = try JSONDecoder().decode(Authority.self, from: Data(contentsOf:
            root.appending(path: "docs/world-terrain-resource-host-authority.json")))
        let mineralRows = authority.resourceHosts.filter { $0.placementKind == "mineralNode" }
        XCTAssertEqual(mineralRows.count, 13)
        XCTAssertEqual(authority.resourceHosts.count - mineralRows.count, 10,
                       "a non-mineral disposition entered the 13-row mineral adapter census")

        for row in mineralRows {
            let clauses = try XCTUnwrap(row.clauses)
            var exercised = Array(repeating: false, count: clauses.count)
            for base in GroundType.allCases {
                for elevation in 0...3 {
                    for neighbour in [GroundType?](arrayLiteral: nil) + GroundType.allCases.map(Optional.some) {
                        let expectedClauses = clauses.enumerated().filter { _, clause in
                            clause.baseGroundIDs.contains(base.rawValue)
                                && (clause.minimumElevation...clause.maximumElevation).contains(elevation)
                                && (clause.adjacentAnyGroundIDs?.isEmpty != false
                                    || neighbour.map { clause.adjacentAnyGroundIDs!.contains($0.rawValue) } == true)
                        }
                        expectedClauses.forEach { exercised[$0.offset] = true }
                        var map = WorldMap(width: 3, height: 3,
                            tiles: Array(repeating: Tile(), count: 9), entry: .init(x: 1, y: 1))
                        let point = GridPoint(x: 1, y: 1)
                        map[point] = Tile(ground: base, baseGround: base, elevation: elevation)
                        if let neighbour {
                            let north = GridPoint(x: 1, y: 0)
                            map[north] = Tile(ground: neighbour, baseGround: neighbour)
                        }
                        let actual = Worldgen.resourceHostAllows(
                            ResourceID(rawValue: row.resourceID), at: point, in: map)
                        XCTAssertEqual(actual, !expectedClauses.isEmpty,
                            "host mismatch for \(row.resourceID): base=\(base.rawValue), elevation=\(elevation), neighbour=\(neighbour?.rawValue ?? "none")")
                    }
                }
            }
            XCTAssertTrue(exercised.allSatisfy { $0 },
                          "not every machine-authority clause was exercised for \(row.resourceID)")
        }
    }

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
        let standingProof = TerrainRules.hydrologyStageWithDiagnosticsForTesting(
            width: 18, height: 18, water: reading(forms: ["standing": 1]),
            freezing: false, seed: 81)

        XCTAssertTrue(standingProof.diagnostics.succeeded)
        XCTAssertEqual(wetCount(standing), standingProof.diagnostics.allocated[0])
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
        var visibleBodies: [Set<GridPoint>] = []
        while let first = remainingWater.sorted(by: { ($0.y, $0.x) < ($1.y, $1.x) }).first {
            var body: Set<GridPoint> = [first], queue = [first]
            remainingWater.remove(first)
            while let point = queue.popLast() {
                for next in standing.neighbours(of: point)
                where remainingWater.remove(next) != nil { body.insert(next); queue.append(next) }
            }
            visibleBodies.append(body)
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
        XCTAssertEqual(Set(standingProof.diagnostics.standingBodies.map(Set.init)),
                       Set(visibleBodies), "authored Standing bodies differed from visible lakes")
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

        let impossible = TerrainRules.hydrologyStageWithDiagnosticsForTesting(
            width: 2, height: 1, elevations: [1, 1],
            water: .init(target: "hydrology", peak: 100, demand: 100, floor: 100,
                         opposedMagnitude: 0, aspects: ["dispersion": 0],
                         forms: ["flowing": 1], tags: []),
            freezing: false, seed: 406)
        XCTAssertFalse(impossible.diagnostics.succeeded)
        XCTAssertEqual(impossible.diagnostics.flowingTiles, 0)
        XCTAssertEqual(impossible.diagnostics.standingTiles, 0,
                       "failed Flowing quota was silently repainted as Standing")
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
        XCTAssertTrue(mixed.diagnostics.succeeded)
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

    func testPlayableEntryCapacityRejectsDegenerateAndMissingMandatoryHosts() {
        func line(_ grounds: [GroundType]) -> WorldMap {
            WorldMap(width: grounds.count, height: 1,
                     tiles: grounds.map { Tile(ground: $0) },
                     entry: GridPoint(x: 0, y: 0))
        }
        for grounds in [[GroundType.soil], [.soil, .soil], [.soil, .soil, .soil]] {
            let map = line(grounds)
            XCTAssertFalse(Worldgen.openingCapacityForTesting(
                at: map.entry, in: map, component: Set(map.allPoints),
                needsStarterFind: false, exitCount: 1))
        }

        let noStarterRoute = line([.soil, .mud, .mud, .soil, .soil, .soil, .soil])
        XCTAssertFalse(Worldgen.openingCapacityForTesting(
            at: noStarterRoute.entry, in: noStarterRoute,
            component: Set(noStarterRoute.allPoints), needsStarterFind: true, exitCount: 1))

        let capable = line(Array(repeating: .soil, count: 8))
        XCTAssertTrue(Worldgen.openingCapacityForTesting(
            at: capable.entry, in: capable, component: Set(capable.allPoints),
            needsStarterFind: false, exitCount: 1))
        XCTAssertTrue(Worldgen.openingCapacityForTesting(
            at: capable.entry, in: capable, component: Set(capable.allPoints),
            needsStarterFind: true, exitCount: 1))
    }

    func testPlayableEntryGate13EnumeratesAdversarialReservationShapes() {
        func map(_ width: Int, _ height: Int = 1,
                 blocked: Set<GridPoint> = []) -> WorldMap {
            let points = (0..<height).flatMap { y in (0..<width).map { GridPoint(x: $0, y: y) } }
            return WorldMap(width: width, height: height,
                tiles: points.map { Tile(ground: blocked.contains($0) ? .deepWater : .soil) },
                entry: .init(x: 0, y: 0))
        }
        struct Case { let name: String; let map: WorldMap; let entry: GridPoint; let starter: Bool; let exits: Int; let accepted: Bool }
        let cases: [Case] = [
            .init(name: "singleton", map: map(1), entry: .init(x: 0, y: 0), starter: false, exits: 1, accepted: false),
            .init(name: "two-tile", map: map(2), entry: .init(x: 0, y: 0), starter: false, exits: 1, accepted: false),
            .init(name: "fully-reachable-no-writing-host", map: map(3), entry: .init(x: 0, y: 0), starter: false, exits: 1, accepted: false),
            .init(name: "capable-component-member", map: map(8), entry: .init(x: 0, y: 0), starter: false, exits: 1, accepted: true),
            .init(name: "interior-capable", map: map(9, 3), entry: .init(x: 4, y: 1), starter: false, exits: 1, accepted: true),
            .init(name: "riven-zero-exit", map: map(5), entry: .init(x: 0, y: 0), starter: false, exits: 0, accepted: true),
            .init(name: "non-riven-insufficient-distinct-reservations", map: map(4), entry: .init(x: 0, y: 0), starter: true, exits: 2, accepted: false),
        ]
        for fixture in cases {
            let component = Set(fixture.map.allPoints.filter { fixture.map[$0].isPassable })
            XCTAssertEqual(Worldgen.openingCapacityForTesting(
                at: fixture.entry, in: fixture.map, component: component,
                needsStarterFind: fixture.starter, exitCount: fixture.exits), fixture.accepted,
                fixture.name)
        }

        var alternateMap = map(8)
        for point in [GridPoint(x: 0, y: 0), .init(x: 6, y: 0), .init(x: 7, y: 0)] {
            alternateMap[point].content = .portal(isEntry: false)
        }
        let rejectedInitial = GridPoint(x: 3, y: 0)
        let selected = Worldgen.selectedPlayableEntryForTesting(
            in: alternateMap, component: Set(alternateMap.allPoints), preferred: .init(x: 0, y: 0),
            initial: rejectedInitial, needsStarterFind: false, exitCount: 1)
        XCTAssertNotEqual(selected, rejectedInitial)
        XCTAssertNotNil(selected, "a capable alternate must be selected when the original fails")

        var tied = map(9, 3, blocked: Set((0..<3).map { GridPoint(x: 4, y: $0) }))
        var tiedRNG1 = SeededRNG(seed: 77), tiedRNG2 = SeededRNG(seed: 77)
        let tiedEntry1 = TerrainRules.entryPoint(in: tied, near: .init(x: 4, y: 0), rng: &tiedRNG1)
        let tiedEntry2 = TerrainRules.entryPoint(in: tied, near: .init(x: 4, y: 0), rng: &tiedRNG2)
        let left = TerrainRules.reachable(from: .init(x: 0, y: 0), in: tied)
        let right = TerrainRules.reachable(from: .init(x: 8, y: 0), in: tied)
        XCTAssertTrue(left.isDisjoint(with: right))
        XCTAssertEqual(left.count, right.count)
        XCTAssertEqual(tiedEntry1, tiedEntry2, "equal largest components must resolve deterministically")
        XCTAssertEqual(tiedEntry1, GridPoint(x: 3, y: 0))
        let reversedSet = Set(tied.allPoints.reversed().filter { tied[$0].isPassable })
        XCTAssertEqual(Worldgen.selectedPlayableEntryForTesting(
            in: tied, component: left, preferred: .init(x: 4, y: 0),
            initial: .init(x: 0, y: 0), needsStarterFind: false, exitCount: 1, seed: 33),
            Worldgen.selectedPlayableEntryForTesting(
                in: tied, component: reversedSet.intersection(left), preferred: .init(x: 4, y: 0),
                initial: .init(x: 0, y: 0), needsStarterFind: false, exitCount: 1, seed: 33))

        let interiorPassable = Set((2...8).flatMap { y in (2...8).map { GridPoint(x: $0, y: y) } })
        tied = map(11, 11, blocked: Set((0..<11).flatMap { y in (0..<11).compactMap { x in
            let point = GridPoint(x: x, y: y)
            return interiorPassable.contains(point) ? nil : point
        }}))
        var interiorRNG = SeededRNG(seed: 8)
        let interior = try? XCTUnwrap(TerrainRules.entryPoint(
            in: tied, near: .init(x: 0, y: 0), rng: &interiorRNG))
        XCTAssertNotNil(interior)
        if let interior {
            XCTAssertNotEqual(tied.ring(of: interior), 0)
            XCTAssertTrue(Worldgen.openingCapacityForTesting(
                at: interior, in: tied, component: interiorPassable,
                needsStarterFind: true, exitCount: 2))
        }
    }

    func testExitReservationPrefersFarHostsFallsBackNearAndCannotConsumeWritingHost() throws {
        func line(_ count: Int) -> WorldMap {
            WorldMap(width: count, height: 1, tiles: Array(repeating: Tile(ground: .soil), count: count),
                     entry: .init(x: 0, y: 0))
        }
        let farMap = line(10)
        let far = try XCTUnwrap(Worldgen.openingExitReservationForTesting(
            at: farMap.entry, in: farMap, component: Set(farMap.allPoints),
            needsStarterFind: false, exitCount: 1))
        XCTAssertGreaterThanOrEqual(try XCTUnwrap(far.first).chebyshevDistance(to: farMap.entry),
                                    Tuning.World.minimumExitPortalDistance)

        let nearMap = line(5)
        let near = try XCTUnwrap(Worldgen.openingExitReservationForTesting(
            at: nearMap.entry, in: nearMap, component: Set(nearMap.allPoints),
            needsStarterFind: false, exitCount: 1))
        XCTAssertLessThan(try XCTUnwrap(near.first).chebyshevDistance(to: nearMap.entry),
                          Tuning.World.minimumExitPortalDistance)

        let collisionMap = line(4)
        let collisionSafe = try XCTUnwrap(Worldgen.openingExitReservationForTesting(
            at: collisionMap.entry, in: collisionMap, component: Set(collisionMap.allPoints),
            needsStarterFind: false, exitCount: 1))
        XCTAssertNotEqual(collisionSafe, [GridPoint(x: 3, y: 0)],
                          "the exit may not consume the sole ordinary-writing host")

        var farWouldConsumeWriting = line(7)
        for x in 3...5 { farWouldConsumeWriting[GridPoint(x: x, y: 0)].content = .portal(isEntry: false) }
        let nearOnlyValid = try XCTUnwrap(Worldgen.openingExitReservationForTesting(
            at: farWouldConsumeWriting.entry, in: farWouldConsumeWriting,
            component: Set(farWouldConsumeWriting.allPoints), needsStarterFind: false,
            exitCount: 1, seed: 9))
        XCTAssertLessThan(try XCTUnwrap(nearOnlyValid.first).chebyshevDistance(
            to: farWouldConsumeWriting.entry), Tuning.World.minimumExitPortalDistance,
            "near fallback is legal only after every far joint plan consumes the sole writing host")

        let healthy = line(10)
        let original = try XCTUnwrap(Worldgen.originalExitDrawForTesting(
            at: healthy.entry, in: healthy, component: Set(healthy.allPoints),
            exitCount: 2, seed: 41))
        let reserved = try XCTUnwrap(Worldgen.openingReservationStateForTesting(
            at: healthy.entry, in: healthy, component: Set(healthy.allPoints),
            needsStarterFind: true, exitCount: 2, seed: 41))
        XCTAssertEqual(reserved.exits, original.exits,
                       "a healthy original exit draw must not drift through fallback planning")
        var expectedRNG = original.rng
        let expectedNext = expectedRNG.next()
        var actualRNG = reserved.rng
        XCTAssertEqual(actualRNG.next(), expectedNext,
                       "the healthy fast path must preserve the exact advanced layout stream")
        let forwardComponent = Set(healthy.allPoints)
        var reversedComponent = Set<GridPoint>()
        for point in healthy.allPoints.reversed() { reversedComponent.insert(point) }
        XCTAssertEqual(Worldgen.openingExitReservationForTesting(
            at: healthy.entry, in: healthy, component: forwardComponent,
            needsStarterFind: true, exitCount: 2, seed: 41),
            Worldgen.openingExitReservationForTesting(
                at: healthy.entry, in: healthy, component: reversedComponent,
                needsStarterFind: true, exitCount: 2, seed: 41),
            "Set insertion order must not alter the exact reservation")

        var sequenceMap = line(5)
        let starterBook = BookRules.resolveBook(worldPage: try XCTUnwrap(
            WorldPageCatalog.starterInstances.first))
        let starterReceipt = try XCTUnwrap(starterBook.worldPageUseReceipt)
        let sequenceExits = try XCTUnwrap(Worldgen.openingExitReservationForTesting(
            at: sequenceMap.entry, in: sequenceMap, component: Set(sequenceMap.allPoints),
            needsStarterFind: true, exitCount: 1, seed: 7))
        let placed = try XCTUnwrap(Worldgen.openingMandatoryPlacementSequenceForTesting(
            map: &sequenceMap, exits: sequenceExits, receipt: starterReceipt, seed: 7))
        XCTAssertGreaterThan(placed.writing.chebyshevDistance(to: sequenceMap.entry), 2)
        XCTAssertTrue((1...2).contains(placed.starter.chebyshevDistance(to: sequenceMap.entry)))
        XCTAssertNotEqual(placed.writing, placed.starter)
        guard case .foundWriting = sequenceMap[placed.writing].content else {
            return XCTFail("the reserved ordinary-writing class must remain available")
        }
        guard case .item(let stack) = sequenceMap[placed.starter].content else {
            return XCTFail("the starter must survive the actual post-exit writing-first sequence")
        }
        XCTAssertEqual(stack.id, StarterKnownFindPlacementRules.stableInstanceID(for: starterReceipt))
    }

    func testHealthyOriginalEntryIsRetainedAndRejectedCandidateIsNotPrepared() throws {
        var healthy = WorldMap(width: 9, height: 2,
            tiles: Array(repeating: Tile(ground: .soil), count: 18), entry: .init(x: 0, y: 0))
        let initial = GridPoint(x: 0, y: 0)
        let before = healthy.tiles
        XCTAssertEqual(Worldgen.selectedPlayableEntryForTesting(
            in: healthy, component: Set(healthy.allPoints), preferred: .init(x: 8, y: 1),
            initial: initial, needsStarterFind: false, exitCount: 1), initial)
        XCTAssertEqual(healthy.tiles, before, "selection must not prepare or alter any candidate")

        let rejected = GridPoint(x: 0, y: 0)
        var firstEdgeFailure = WorldMap(width: 8, height: 1, tiles: [
            Tile(ground: .growth, baseGround: .soil, flora: InstanceID(rawValue: 99)),
            Tile(ground: .mud), Tile(ground: .soil), Tile(ground: .soil),
            Tile(ground: .soil), Tile(ground: .soil), Tile(ground: .soil), Tile(ground: .soil),
        ], entry: rejected)
        let rejectedBefore = firstEdgeFailure[rejected]
        XCTAssertFalse(Worldgen.openingCapacityForTesting(
            at: rejected, in: firstEdgeFailure, component: Set(firstEdgeFailure.allPoints),
            needsStarterFind: true, exitCount: 1))
        let alternate = Worldgen.selectedPlayableEntryForTesting(
            in: firstEdgeFailure, component: Set(firstEdgeFailure.allPoints),
            preferred: rejected, initial: rejected, needsStarterFind: true, exitCount: 1)
        XCTAssertNotNil(alternate)
        XCTAssertNotEqual(alternate, rejected)
        XCTAssertEqual(firstEdgeFailure[rejected], rejectedBefore,
                       "a rejected entry candidate must retain ground and flora byte-for-byte")
    }

    func testPlayableEntryReceiptCertifiesFinalEntryPortalAndExactStarterIdentity() throws {
        var map = WorldMap(width: 5, height: 1,
                           tiles: Array(repeating: Tile(ground: .soil), count: 5),
                           entry: GridPoint(x: 0, y: 0))
        map[map.entry].content = .portal(isEntry: true)
        let starterBook = BookRules.resolveBook(worldPage: try XCTUnwrap(
            WorldPageCatalog.starterInstances.first))
        let receipt = try XCTUnwrap(starterBook.worldPageUseReceipt)
        var occupied: Set<GridPoint> = [map.entry]
        let starter = try XCTUnwrap(StarterKnownFindPlacementRules.place(
            receipt: receipt, in: &map, avoiding: &occupied))

        var certified = Worldgen.playableEntryReceiptForTesting(
            map: map, entry: map.entry, starterReceipt: receipt, starterPoint: starter,
            requiredExitPortalCount: 0)
        XCTAssertTrue(certified.hasCardinalFirstMove)
        XCTAssertTrue(certified.promisedStarterFindPlaced)

        let exactStack = map[starter].content
        map[starter].content = .empty
        certified = Worldgen.playableEntryReceiptForTesting(
            map: map, entry: map.entry, starterReceipt: receipt, starterPoint: starter,
            requiredExitPortalCount: 0)
        XCTAssertFalse(certified.promisedStarterFindPlaced,
                       "a reachable planned point cannot certify an absent final item")

        let promisedID = try XCTUnwrap(receipt.definition.knownFind)
        map[starter].content = .item(ItemStack(id: InstanceID(rawValue: 999), catalogID: promisedID))
        certified = Worldgen.playableEntryReceiptForTesting(
            map: map, entry: map.entry, starterReceipt: receipt, starterPoint: starter,
            requiredExitPortalCount: 0)
        XCTAssertFalse(certified.promisedStarterFindPlaced,
                       "the promised definition with the wrong physical instance is not exact")

        map[starter].content = exactStack
        map[map.entry].content = .empty
        certified = Worldgen.playableEntryReceiptForTesting(
            map: map, entry: map.entry, starterReceipt: receipt, starterPoint: starter,
            requiredExitPortalCount: 0)
        XCTAssertFalse(certified.hasCardinalFirstMove,
                       "a passable entry coordinate without the entry Portal cannot certify playability")

        map[map.entry].content = .portal(isEntry: false)
        certified = Worldgen.playableEntryReceiptForTesting(
            map: map, entry: map.entry, starterReceipt: receipt, starterPoint: starter,
            requiredExitPortalCount: 0)
        XCTAssertFalse(certified.hasCardinalFirstMove,
                       "a non-entry Portal cannot stand in for the arrival Portal")
    }

    func testPlayableEntryGate14CoversEveryLiveScaleAndExtremeProfileDeterministically() {
        XCTAssertEqual(WorldScale.allCases.map(\.gridSide), [12, 15, 18, 23, 28])
        let water = Sigil(id: .init(rawValue: 1), source: "sea", target: "hydrology",
                          intensity: .overwhelming, scale: 5, count: 5)
        let chasm = Sigil(id: .init(rawValue: 2), source: "chasm", target: "substrate",
                          intensity: .overwhelming, scale: 5, count: 5)
        let profiles: [(name: String, composition: [Sigil])] = [
            ("ordinary", []), ("maximum-water", [water]),
            ("maximum-chasm", [chasm]), ("combined-extremes", [water, chasm])
        ]
        let maximumWater = PressureRules.resolve([water])["hydrology"]
        XCTAssertEqual(maximumWater.peak, Tuning.Pressure.scaleMaximum)
        XCTAssertEqual(maximumWater.peak / Tuning.Pressure.scaleMaximum
            * Tuning.Terrain.maximumWaterCoverage, Tuning.Terrain.maximumWaterCoverage)
        XCTAssertEqual(TerrainRules.chasmCoverage(in: PressureRules.resolve([chasm])),
                       Tuning.Terrain.chasmCoverageCeiling)
        let seeds: [UInt64] = [1, 12, 31]
        for scale in WorldScale.allCases {
            for profile in profiles {
                for seed in seeds {
                    let resolved = BoundBook(written: [], composition: profile.composition,
                                             scale: scale, essencePaid: 0)
                    let first = Worldgen.generate(book: resolved, seed: seed)
                    let second = Worldgen.generate(book: resolved, seed: seed)
                    let permuted = BoundBook(written: [], composition: Array(profile.composition.reversed()),
                                             scale: scale, essencePaid: 0)
                    let reordered = Worldgen.generate(book: permuted, seed: seed)
                    let label = "scale=\(scale.rawValue) profile=\(profile.name) seed=\(seed)"
                    XCTAssertTrue(first.diagnostics.terrainGenerationSucceeded, label)
                    XCTAssertEqual(first.diagnostics.playableEntry?.isAccepted, true, label)
                    XCTAssertEqual(first.map, second.map, "same-seed map drift: \(label)")
                    XCTAssertEqual(first.start, second.start, "same-seed entry drift: \(label)")
                    XCTAssertEqual(first.diagnostics, second.diagnostics, "diagnostic drift: \(label)")
                    XCTAssertEqual(first.map, reordered.map, "input-order drift: \(label)")
                    XCTAssertEqual(first.start, reordered.start, "input-order entry drift: \(label)")
                    XCTAssertEqual(first.diagnostics, reordered.diagnostics,
                                   "input-order diagnostic drift: \(label)")
                    XCTAssertEqual(first.enemies, second.enemies, label)
                    XCTAssertEqual(first.sites, second.sites, label)
                    XCTAssertEqual(first.pages, second.pages, label)
                    XCTAssertEqual(first.writings, second.writings, label)
                    XCTAssertEqual(first.wildPage, second.wildPage, label)
                    XCTAssertEqual(first.travellers, second.travellers, label)
                    XCTAssertEqual(first.cast, second.cast, label)
                    XCTAssertEqual(first.flora, second.flora, label)
                    XCTAssertEqual(first.enemies, reordered.enemies, "input-order enemy drift: \(label)")
                    XCTAssertEqual(first.sites, reordered.sites, "input-order site drift: \(label)")
                    XCTAssertEqual(first.pages, reordered.pages, "input-order page drift: \(label)")
                    XCTAssertEqual(first.writings, reordered.writings, "input-order writing drift: \(label)")
                    XCTAssertEqual(first.wildPage, reordered.wildPage, "input-order World Page drift: \(label)")
                    XCTAssertEqual(first.travellers, reordered.travellers, "input-order traveller drift: \(label)")
                    XCTAssertEqual(first.cast, reordered.cast, "input-order species drift: \(label)")
                    XCTAssertEqual(first.flora, reordered.flora, "input-order flora drift: \(label)")
                    XCTAssertEqual(first.map.width, scale.gridSide, label)
                    XCTAssertEqual(first.map.height, scale.gridSide, label)
                    let reached = TerrainRules.reachable(from: first.start, in: first.map)
                    let step = first.map.neighbours(of: first.start).first {
                        reached.contains($0) && WorldRules.canEnter($0, in: first.map)
                    }
                    XCTAssertNotNil(step, label)
                    if let step {
                        XCTAssertEqual(WorldRules.path(from: first.start, to: step, in: first.map),
                                       [step], "the first move must be executable: \(label)")
                        XCTAssertEqual(WorldRules.path(from: step, to: first.start, in: first.map),
                                       [first.start], "the portal return must be executable: \(label)")
                    }
                    XCTAssertGreaterThanOrEqual(first.diagnostics.reachableTerrainFraction,
                                                Tuning.Terrain.reachableGroundFraction, label)
                    XCTAssertTrue(first.map.allPoints.allSatisfy {
                        first.map[$0].content == .empty || reached.contains($0)
                    }, label)
                    XCTAssertTrue(first.sites.allSatisfy { reached.contains($0.position) }, label)
                    XCTAssertTrue(first.enemies.allSatisfy { reached.contains($0.position) }, label)
                    let exits = first.map.allPoints.filter {
                        $0 != first.start && first.map[$0].content.isPortal
                    }
                    let receipt = first.diagnostics.playableEntry!
                    XCTAssertEqual(exits.count, receipt.requiredExitPortalCount, label)
                    XCTAssertEqual(exits.count, receipt.placedExitPortalCount, label)
                    let riven = TerrainRules.isRiven(asWritten: PressureRules.resolve(profile.composition))
                    if riven {
                        XCTAssertEqual(exits.count, 0, label)
                        XCTAssertEqual(receipt.requiredExitPortalCount, 0, label)
                        XCTAssertEqual(receipt.placedExitPortalCount, 0, label)
                    } else {
                        XCTAssertGreaterThan(exits.count, 0, label)
                        XCTAssertTrue(Tuning.World.exitPortalCountRange.contains(exits.count), label)
                        XCTAssertTrue(Tuning.World.exitPortalCountRange.contains(
                            receipt.requiredExitPortalCount), label)
                    }
                    XCTAssertTrue(first.map.allPoints.contains { point in
                        guard reached.contains(point), point.chebyshevDistance(to: first.start) > 2 else { return false }
                        switch first.map[point].content {
                        case .diaryPage, .foundWriting: return true
                        default: return false
                        }
                    }, "ordinary writing missing: \(label)")
                }
            }
        }
    }

    func testPlayableEntryGate14PlacesExactPromisedStarterFindAtEveryLiveScale() throws {
        for scale in WorldScale.allCases {
            for instance in WorldPageCatalog.starterInstances {
                var resolved = BookRules.resolveBook(worldPage: instance)
                resolved.scale = scale
                let generated = Worldgen.generate(book: resolved, seed: instance.definition.seed)
                let receipt = try XCTUnwrap(resolved.worldPageUseReceipt)
                let expectedID = StarterKnownFindPlacementRules.stableInstanceID(for: receipt)
                let found = generated.map.allPoints.compactMap { point -> (GridPoint, ItemStack)? in
                    guard case .item(let stack) = generated.map[point].content,
                          stack.id == expectedID else { return nil }
                    return (point, stack)
                }
                XCTAssertEqual(found.count, 1, "scale=\(scale.rawValue), page=\(instance.id)")
                let placed = try XCTUnwrap(found.first)
                XCTAssertEqual(placed.1.catalogID, instance.definition.knownFind)
                let reached = TerrainRules.reachable(from: generated.start, in: generated.map)
                XCTAssertTrue(reached.contains(placed.0))
                var distances: [GridPoint: Int] = [generated.start: 0]
                var queue = [generated.start]
                while !queue.isEmpty, distances[placed.0] == nil {
                    let point = queue.removeFirst()
                    for next in generated.map.neighbours(of: point)
                    where distances[next] == nil && WorldRules.canEnter(next, in: generated.map) {
                        distances[next] = distances[point, default: 0] + 1
                        queue.append(next)
                    }
                }
                XCTAssertTrue((1...2).contains(try XCTUnwrap(distances[placed.0])))
                XCTAssertEqual(generated.diagnostics.playableEntry?.promisedStarterFindPlaced, true)
            }
        }
    }

    func testYouNeverArriveSomewhereYouCannotStand() {
        for seed in UInt64(1)...40 {
            let world = Worldgen.generate(book: book(["archipelago"]), seed: seed)
            XCTAssertTrue(world.diagnostics.terrainGenerationSucceeded, "terrain failed, seed \(seed)")
            XCTAssertEqual(world.diagnostics.playableEntry?.isAccepted, true,
                           "playable-entry receipt failed, seed \(seed)")
            XCTAssertGreaterThanOrEqual(world.diagnostics.reachableTerrainFraction,
                                        Tuning.Terrain.reachableGroundFraction,
                                        "reachable terrain was too small, seed \(seed)")
            XCTAssertTrue(world.map[world.start].isPassable,
                          "spawned in deep water, seed \(seed)")
            let reached = TerrainRules.reachable(from: world.start, in: world.map)
            for point in world.map.allPoints where world.map[point].content != .empty {
                XCTAssertTrue(reached.contains(point), "content stranded, seed \(seed), \(point)")
            }
            for site in world.sites {
                XCTAssertTrue(reached.contains(site.position), "site stranded, seed \(seed)")
            }
            for enemy in world.enemies {
                XCTAssertTrue(reached.contains(enemy.position), "enemy stranded, seed \(seed)")
            }
        }
    }

    func testWaterHeavyAndBrokenWorldsAlwaysLeaveTheEntryPortalAPlayableRoute() {
        let pages: [[SymbolID]] = [
            ["archipelago"],
            ["archipelago", "caverns"],
            ["archipelago", "glacier", "caverns"],
        ]
        for symbols in pages {
            for seed in [UInt64(1), 2, 7, 12, 19, 31] {
                let world = Worldgen.generate(book: book(symbols), seed: seed)
                XCTAssertTrue(world.diagnostics.terrainGenerationSucceeded,
                              "terrain failed for \(symbols), seed \(seed)")
                XCTAssertEqual(world.diagnostics.playableEntry?.isAccepted, true)
                let entry = world.start
                XCTAssertTrue(world.map[entry].content.isPortal)
                let legalSteps = world.map.neighbours(of: entry).filter { world.map[$0].isPassable }
                XCTAssertFalse(legalSteps.isEmpty,
                               "entry had no legal step for \(symbols), seed \(seed)")
                let reached = TerrainRules.reachable(from: entry, in: world.map)
                XCTAssertGreaterThan(reached.count, 1,
                                     "entry had no route into the world for \(symbols), seed \(seed)")
                let passable = world.map.allPoints.count { world.map[$0].isPassable }
                XCTAssertEqual(Double(reached.count) / Double(passable),
                               world.diagnostics.reachableTerrainFraction, accuracy: 0.000_000_1)
                XCTAssertGreaterThanOrEqual(world.diagnostics.reachableTerrainFraction,
                                            Tuning.Terrain.reachableGroundFraction)
                for point in world.map.allPoints where world.map[point].content != .empty {
                    XCTAssertTrue(reached.contains(point), "content stranded at \(point)")
                }
                for site in world.sites { XCTAssertTrue(reached.contains(site.position)) }
                for enemy in world.enemies { XCTAssertTrue(reached.contains(enemy.position)) }
            }
        }
    }

    func testEntryClearsFloraAndRestoresBothOvergrownGroundKinds() {
        for overgrown in [GroundType.growth, .groundcover] {
            let point = GridPoint(x: 0, y: 0)
            var map = WorldMap(width: 1, height: 1,
                               tiles: [Tile(ground: overgrown, baseGround: .stone,
                                            flora: InstanceID(rawValue: 7))], entry: point)
            TerrainRules.prepareEntry(at: point, in: &map)
            XCTAssertNil(map[point].flora)
            XCTAssertEqual(map[point].ground, .stone)
            XCTAssertEqual(map[point].baseGround, .stone)
        }
    }

    func testReachabilityRepairFailsClosedForAnInvalidImpassableStart() {
        let point = GridPoint(x: 0, y: 0)
        var map = WorldMap(width: 1, height: 1,
                           tiles: [Tile(ground: .deepWater)], entry: point)
        var rng = SeededRNG(seed: 1)
        let result = TerrainRules.openTheWayWithDiagnostics(from: point, in: &map, rng: &rng)
        XCTAssertFalse(result.succeeded)
        XCTAssertEqual(result.reachableFraction, 0)
        XCTAssertEqual(result.softenedDeepWater, 0)
        XCTAssertEqual(result.filledChasm, 0)
    }

    func testReachabilityRepairChangesOnlyOneBlockingDeepWaterOrChasmTile() {
        for blocker in [GroundType.deepWater, .chasm] {
            let start = GridPoint(x: 0, y: 0)
            var map = WorldMap(width: 3, height: 2, tiles: [
                Tile(ground: .soil), Tile(ground: blocker), Tile(ground: .soil),
                Tile(ground: .soil), Tile(ground: blocker), Tile(ground: .soil),
            ], entry: start)
            let untouched = GridPoint(x: 1, y: 1)
            let before = map[untouched]
            var rng = SeededRNG(seed: 4)
            let result = TerrainRules.openTheWayWithDiagnostics(from: start, in: &map, rng: &rng)
            XCTAssertTrue(result.succeeded)
            XCTAssertEqual(result.softenedDeepWater, blocker == .deepWater ? 1 : 0)
            XCTAssertEqual(result.filledChasm, blocker == .chasm ? 1 : 0)
            XCTAssertEqual(map[untouched], before, "unrelated basin/barrier tile changed")
        }
    }

    func testSeed12StartsInMeaningfulDryTerrainAndKeepsItsApex() {
        let world = Worldgen.generate(book: book([]), seed: 12)
        XCTAssertTrue(world.diagnostics.terrainGenerationSucceeded)
        XCTAssertGreaterThanOrEqual(world.diagnostics.reachableTerrainFraction,
                                    Tuning.Terrain.reachableGroundFraction)
        XCTAssertEqual(world.diagnostics.softenedDeepWaterTiles, 0)
        XCTAssertEqual(world.diagnostics.filledChasmTiles, 0)
        XCTAssertNotEqual(world.map[world.start].baseGround, .water)
        let reached = TerrainRules.reachable(from: world.start, in: world.map)
        let passable = world.map.allPoints.count { world.map[$0].isPassable }
        XCTAssertEqual(Double(reached.count) / Double(passable),
                       world.diagnostics.reachableTerrainFraction, accuracy: 0.000_000_1)
        for point in world.map.allPoints where world.map[point].content != .empty {
            XCTAssertTrue(reached.contains(point), "content stranded at \(point)")
        }
        for site in world.sites { XCTAssertTrue(reached.contains(site.position)) }
        for enemy in world.enemies { XCTAssertTrue(reached.contains(enemy.position)) }
        XCTAssertTrue(world.diagnostics.apexRollSucceeded)
        XCTAssertTrue(world.diagnostics.apexPlaced)
        XCTAssertEqual(world.enemies.count(where: \.isApex), 1)
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
