import XCTest
@testable import Bookbinder

final class WorldVisibilityRulesTests: XCTestCase {
    func testOrdinaryLightProducesSevenPlusTwoProfile() {
        let profile = WorldRules.visibilityProfile(illumination: 45)
        XCTAssertEqual(profile.fullRadius, 7)
        XCTAssertEqual(profile.fringeWidth, 2)
        XCTAssertEqual(profile.fringeOpacity, 0.5, accuracy: 0.000_001)
        XCTAssertEqual(profile.fringeBlurFraction, 0.5, accuracy: 0.000_001)
        XCTAssertEqual(profile.fogEdgeBlurPoints, 2, accuracy: 0.000_001)
    }

    func testPitchBlackLeavesOnlyImmediateRingAndNoFringe() {
        let profile = WorldRules.visibilityProfile(illumination: 0)
        XCTAssertEqual(profile.fullRadius, 1)
        XCTAssertEqual(profile.fringeWidth, 0)
        XCTAssertEqual(profile.fringeOpacity, 0, accuracy: 0.000_001)
    }

    func testLowLightContractsFullSightToTwoTiles() {
        XCTAssertEqual(WorldRules.visibilityProfile(illumination: 20).fullRadius, 2)
    }

    func testDenseObscurantContractsAndSoftensBothBands() {
        let profile = WorldRules.visibilityProfile(illumination: 45, obscurantDensity: 85)
        XCTAssertEqual(profile.fullRadius, 3)
        XCTAssertEqual(profile.fringeWidth, 1)
        XCTAssertEqual(profile.fringeOpacity, 0.16, accuracy: 0.000_001)
        XCTAssertEqual(profile.fringeBlurFraction, 0.925, accuracy: 0.000_001)
        XCTAssertEqual(profile.fogEdgeBlurPoints, 5.4, accuracy: 0.000_001)
    }

    func testObscurantCanNeverHideTheImmediateRing() {
        let profile = WorldRules.visibilityProfile(illumination: 6, obscurantDensity: 100)
        XCTAssertEqual(profile.fullRadius, 1)
    }

    func testVisibilityUsesCircularBandsRatherThanSquareCorners() {
        let centre = GridPoint(x: 10, y: 10)
        let map = openMap(width: 21, height: 21, entry: centre)
        let profile = WorldRules.visibilityProfile(illumination: 45)

        XCTAssertEqual(WorldRules.visibility(of: GridPoint(x: 17, y: 12), from: centre,
                                             in: map, profile: profile), .full)
        XCTAssertEqual(WorldRules.visibility(of: GridPoint(x: 17, y: 13), from: centre,
                                             in: map, profile: profile), .fringe)
        XCTAssertEqual(WorldRules.visibility(of: GridPoint(x: 19, y: 13), from: centre,
                                             in: map, profile: profile), .fringe)
        XCTAssertEqual(WorldRules.visibility(of: GridPoint(x: 19, y: 14), from: centre,
                                             in: map, profile: profile), .hidden)
    }

    func testBlockingGroundAndElevationStopBothVisibilityBands() {
        let centre = GridPoint(x: 1, y: 2)
        var map = openMap(width: 7, height: 5, entry: centre)
        map[GridPoint(x: 2, y: 2)].ground = .growth
        let profile = WorldRules.visibilityProfile(illumination: 45)

        XCTAssertEqual(WorldRules.visibility(of: GridPoint(x: 2, y: 2), from: centre,
                                             in: map, profile: profile), .full,
                       "the blocking tile itself remains visible")
        XCTAssertEqual(WorldRules.visibility(of: GridPoint(x: 3, y: 2), from: centre,
                                             in: map, profile: profile), .hidden)

        map[GridPoint(x: 2, y: 2)].ground = .soil
        map[GridPoint(x: 2, y: 2)].elevation = 1
        XCTAssertEqual(WorldRules.visibility(of: GridPoint(x: 3, y: 2), from: centre,
                                             in: map, profile: profile), .hidden)
    }

    func testOnlyFullCircleBecomesPersistentExploration() {
        let centre = GridPoint(x: 10, y: 10)
        var map = openMap(width: 21, height: 21, entry: centre)
        let profile = WorldRules.visibilityProfile(illumination: 45)

        WorldRules.reveal(around: centre, in: &map, radius: profile.fullRadius)

        XCTAssertTrue(map[GridPoint(x: 17, y: 12)].isRevealed)
        XCTAssertFalse(map[GridPoint(x: 17, y: 13)].isRevealed,
                       "a current fringe tile must not become minimap exploration")
        XCTAssertFalse(map[GridPoint(x: 18, y: 10)].isRevealed)
    }

    func testPartyAwareProfileIsSharedByTerrainAndEnemyDisclosure() {
        let origin = GridPoint(x: 1, y: 1)
        let enemyPoint = GridPoint(x: 9, y: 1)
        let map = openMap(width: 12, height: 3, entry: origin)
        let enemy = WorldEnemy(id: InstanceID(rawValue: 901), creatureID: "paper_moth",
                               position: enemyPoint)
        let run = WorldRun(runIndex: 1, book: BoundBook(written: [], essencePaid: 0), mapSeed: 901,
                           rng: SeededRNG(seed: 901), map: map, playerPosition: origin,
                           enemies: [enemy])
        let ordinary = WorldRules.visibilityProfile(illumination: 45)
        let perceptive = WorldRules.visibilityProfile(illumination: 45, sightBonus: 1)

        XCTAssertEqual(WorldRules.visibility(of: enemyPoint, from: origin, in: map,
                                             profile: ordinary), .fringe)
        XCTAssertFalse(WorldRules.isCurrentlyVisible(enemy, in: run, profile: ordinary))
        XCTAssertEqual(WorldRules.visibility(of: enemyPoint, from: origin, in: map,
                                             profile: perceptive), .full)
        XCTAssertTrue(WorldRules.isCurrentlyVisible(enemy, in: run, profile: perceptive),
                      "the enemy must consume the same party-aware profile as its tile")
    }

    func testHistoricalRevealDoesNotDiscloseCurrentlyDarkFoeOrStopTravel() {
        let origin = GridPoint(x: 1, y: 1)
        let enemyPoint = GridPoint(x: 18, y: 1)
        var map = openMap(width: 20, height: 3, entry: origin)
        map[enemyPoint].isRevealed = true
        let enemy = WorldEnemy(id: InstanceID(rawValue: 902), creatureID: "paper_moth",
                               position: enemyPoint, isApex: true)
        let run = WorldRun(runIndex: 1, book: BoundBook(written: [], essencePaid: 0), mapSeed: 902,
                           rng: SeededRNG(seed: 902), map: map, playerPosition: origin,
                           enemies: [enemy])

        XCTAssertFalse(WorldRules.preContactSnapshot(in: run).disclosed(enemy))
        XCTAssertFalse(WorldRules.automaticTravelMustStop(before: enemyPoint, in: run),
                       "persistent minimap knowledge must not become current creature disclosure")
        XCTAssertTrue(run.map[enemyPoint].isRevealed,
                      "suppressing a dark foe must not erase durable terrain exploration")
    }

    func testUndefinedIlluminationUsesTheWorldSeedForEntryAndCurrentSight() {
        let book = BoundBook(symbols: [:], randomlyFilled: [], essencePaid: 0)
        let seedZeroRadius = WorldRules.visionRadius(for: book, seed: 0)
        var exercisedSeedDependentIllumination = false

        for seed in UInt64(1)...256 {
            let expected = WorldRules.visionRadius(for: book, seed: seed)
            guard expected != seedZeroRadius else { continue }
            exercisedSeedDependentIllumination = true

            let generated = Worldgen.generate(book: book, seed: seed)
            let run = WorldRun(runIndex: 1, book: book, mapSeed: seed,
                               rng: SeededRNG(seed: seed), map: generated.map,
                               playerPosition: generated.start)
            XCTAssertEqual(expected, WorldRules.visibilityProfile(in: run).fullRadius,
                           "entry reveal and derived current sight must read the same seed")
            for point in generated.map.allPoints where generated.map[point].isRevealed {
                XCTAssertLessThanOrEqual(
                    WorldRules.circularDistance(from: generated.start, to: point),
                    Double(expected) + 0.5,
                    "worldgen persisted exploration beyond the seed-resolved full radius")
            }
        }

        XCTAssertTrue(exercisedSeedDependentIllumination,
                      "the fixture must exercise an unwritten, seed-dependent illumination result")
    }

    func testWorldgenDoesNotPreRevealRemoteApexLocation() throws {
        var tuning = DebugTuningProfile.defaults
        tuning.apexChanceMultiplier = 100
        let greedy = BoundBook(written: ["rich_ore", "gilded_veins"], essencePaid: 0)
        var inspectedRemoteApex = false

        for seed in UInt64(1)...256 {
            let generated = Worldgen.generate(book: greedy, seed: seed, tuning: tuning)
            let entryRadius = WorldRules.visionRadius(for: greedy, seed: seed,
                                                      base: tuning.baseVisionRadius)
            for apex in generated.enemies where apex.isApex
                && WorldRules.circularDistance(from: generated.start, to: apex.position)
                    > Double(entryRadius) + 0.5 {
                inspectedRemoteApex = true
                XCTAssertFalse(generated.map[apex.position].isRevealed,
                               "placing an apex must not disclose its remote map location")
            }
            if inspectedRemoteApex { break }
        }

        XCTAssertTrue(inspectedRemoteApex, "fixture failed to generate a remote apex")
    }

    private func openMap(width: Int, height: Int, entry: GridPoint) -> WorldMap {
        WorldMap(width: width, height: height,
                 tiles: Array(repeating: Tile(), count: width * height), entry: entry)
    }
}
