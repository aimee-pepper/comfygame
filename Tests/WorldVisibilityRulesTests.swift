import XCTest
@testable import Bookbinder

final class WorldVisibilityRulesTests: XCTestCase {
    func testVisibilityCompositionUsesHalfBlurForRememberedTerrain() {
        let ordinary = WorldRules.visibilityProfile(illumination: 45)
        XCTAssertEqual(
            WorldVisibilityCompositePresentation.currentTerrainBlurFraction(profile: ordinary),
            ordinary.fringeBlurFraction,
            accuracy: 0.000_001)
        XCTAssertEqual(WorldVisibilityCompositePresentation.rememberedTerrainBlurRatio, 0.5,
                       accuracy: 0.000_001)
        XCTAssertTrue(WorldVisibilityCompositePresentation.clipsTerrainBlurToTileBounds,
                      "terrain blur must never sample across tile boundaries")
        XCTAssertEqual(
            WorldVisibilityCompositePresentation.rememberedTerrainBlurFraction(profile: ordinary),
            WorldVisibilityCompositePresentation.currentTerrainBlurFraction(profile: ordinary)
                * WorldVisibilityCompositePresentation.rememberedTerrainBlurRatio,
            accuracy: 0.000_001)

        XCTAssertTrue(WorldVisibilityCompositePresentation.softenedLayerRendersTerrain(
            currentVisibility: .fringe, terrainVisibility: .fringe, pass: .current))
        XCTAssertFalse(WorldVisibilityCompositePresentation.softenedLayerRendersTerrain(
            currentVisibility: .fringe, terrainVisibility: .fringe, pass: .remembered))
        XCTAssertFalse(WorldVisibilityCompositePresentation.softenedLayerRendersTerrain(
            currentVisibility: .hidden, terrainVisibility: .fringe, pass: .current))
        XCTAssertTrue(WorldVisibilityCompositePresentation.softenedLayerRendersTerrain(
            currentVisibility: .hidden, terrainVisibility: .fringe, pass: .remembered))
        XCTAssertFalse(WorldVisibilityCompositePresentation.softenedLayerRendersTerrain(
            currentVisibility: .hidden, terrainVisibility: .hidden, pass: .remembered),
                       "opaque unseen terrain must not enter either blur pass")

        XCTAssertTrue(WorldVisibilityCompositePresentation.softenedLayerRendersTerrain(
            visibility: .full))
        XCTAssertTrue(WorldVisibilityCompositePresentation.softenedLayerRendersTerrain(
            visibility: .fringe))
        XCTAssertFalse(WorldVisibilityCompositePresentation.softenedLayerRendersTerrain(
            visibility: .hidden))

        XCTAssertTrue(WorldVisibilityCompositePresentation.crispLayerRendersContent(
            visibility: .full))
        XCTAssertFalse(WorldVisibilityCompositePresentation.crispLayerRendersContent(
            visibility: .fringe), "fringe remains terrain-only")
        XCTAssertFalse(WorldVisibilityCompositePresentation.crispLayerRendersContent(
            visibility: .hidden))
    }

    func testPitchBlackCompositionDoesNotBlurOpaqueFog() {
        let pitchBlack = WorldRules.visibilityProfile(illumination: 0)
        XCTAssertEqual(
            WorldVisibilityCompositePresentation.currentTerrainBlurFraction(profile: pitchBlack), 0,
            accuracy: 0.000_001)
        XCTAssertEqual(
            WorldVisibilityCompositePresentation.rememberedTerrainBlurFraction(profile: pitchBlack),
            Tuning.Visibility.defaultFringeBlurFraction
                * WorldVisibilityCompositePresentation.rememberedTerrainBlurRatio,
            accuracy: 0.000_001)
    }

    func testViewportVisibilityFieldIsOnePlayerCentredRadialGradient() {
        let profile = WorldRules.visibilityProfile(illumination: 45)
        let field = WorldVisibilityCompositePresentation.radialField(
            player: GridPoint(x: 12, y: 8), origin: GridPoint(x: 7, y: 2),
            viewportColumns: 11, viewportRows: 13, profile: profile)

        XCTAssertEqual(field.centerX, 0.5, accuracy: 0.000_001)
        XCTAssertEqual(field.centerY, 0.5, accuracy: 0.000_001)
        XCTAssertLessThan(field.clearStop, field.fringeStop)
        XCTAssertEqual(field.clearStop * field.endRadiusInTiles,
                       Double(profile.fullRadius) + 0.5, accuracy: 0.000_001)
        XCTAssertEqual(field.fringeStop * field.endRadiusInTiles,
                       Double(profile.fullRadius + profile.fringeWidth) + 0.5,
                       accuracy: 0.000_001)
        XCTAssertEqual(field.fringeShadeOpacity, 1 - profile.fringeOpacity,
                       accuracy: 0.000_001)
    }

    func testClampedCameraKeepsRadialFieldCentredOnPlayerWithinViewport() {
        let field = WorldVisibilityCompositePresentation.radialField(
            player: GridPoint(x: 1, y: 2), origin: GridPoint(x: 0, y: 0),
            viewportColumns: 11, viewportRows: 13,
            profile: WorldRules.visibilityProfile(illumination: 20))

        XCTAssertEqual(field.centerX, 1.5 / 11, accuracy: 0.000_001)
        XCTAssertEqual(field.centerY, 2.5 / 13, accuracy: 0.000_001)
        XCTAssertGreaterThan(field.endRadiusInTiles, 10)
    }

    func testFullyExploredTerrainNeverFallsBelowFringeAfterLeavingSight() {
        XCTAssertEqual(WorldRules.terrainVisibility(current: .hidden, wasRevealed: true), .fringe)
        XCTAssertEqual(WorldRules.terrainVisibility(current: .fringe, wasRevealed: true), .fringe)
        XCTAssertEqual(WorldRules.terrainVisibility(current: .full, wasRevealed: true), .full)
        XCTAssertEqual(WorldRules.terrainVisibility(current: .hidden, wasRevealed: false), .hidden)

        let pitchBlack = WorldRules.visibilityProfile(illumination: 0)
        XCTAssertEqual(WorldTileVisibilityPresentation.fringeOpacity(
            profile: pitchBlack, remembered: true), Tuning.Visibility.defaultFringeOpacity)
        XCTAssertEqual(WorldTileVisibilityPresentation.fringeBlurFraction(
            profile: pitchBlack, remembered: true), Tuning.Visibility.defaultFringeBlurFraction)
        XCTAssertEqual(WorldTileVisibilityPresentation.fringeOpacity(
            profile: pitchBlack, remembered: false), 0)
    }

    func testHiddenNeighboursCannotChangeVisibleTileArtContext() throws {
        let origin = GridPoint(x: 1, y: 1)
        let point = GridPoint(x: 2, y: 2)
        let east = GridPoint(x: 3, y: 2)
        let south = GridPoint(x: 2, y: 3)
        var map = openMap(width: 5, height: 5, entry: origin)
        map[point].ground = .stone
        map[point].elevation = 3
        map[east].ground = .stone
        map[south].ground = .stone
        map[south].elevation = 3
        let profile = WorldRules.visibilityProfile(illumination: 0)

        func resolved(_ candidate: WorldMap) throws -> MapTileArtRequest {
            let run = WorldRun(runIndex: 1, book: BoundBook(written: [], essencePaid: 0),
                               mapSeed: 77, rng: SeededRNG(seed: 77), map: candidate,
                               playerPosition: origin)
            var tile = candidate[point]
            tile.isRevealed = true
            return try XCTUnwrap(WorldTileVisibilityPresentation.resolve(
                run: run, point: point, tile: tile, visibility: .full,
                profile: profile, grade: .neutral).artRequest)
        }

        let before = try resolved(map)
        map[east].ground = .water
        map[east].elevation = 0
        map[south].ground = .chasm
        map[south].elevation = 0
        let after = try resolved(map)

        XCTAssertEqual(before.adjacency, after.adjacency)
        XCTAssertEqual(before.southExposureLevels, after.southExposureLevels)
        XCTAssertEqual(before.adjacency, 0)
        XCTAssertEqual(before.southExposureLevels, 0)
    }

    func testVisibleNeighboursParticipateInOrdinaryBoundaryGrammar() throws {
        let origin = GridPoint(x: 1, y: 1)
        let point = GridPoint(x: 2, y: 2)
        let east = GridPoint(x: 3, y: 2)
        let south = GridPoint(x: 2, y: 3)
        var map = openMap(width: 5, height: 5, entry: origin)
        map[point].ground = .stone
        map[point].elevation = 3
        map[east].ground = .stone
        map[south].ground = .stone
        map[south].elevation = 3
        let profile = WorldRules.visibilityProfile(illumination: 45)

        func resolved(_ candidate: WorldMap) throws -> MapTileArtRequest {
            let run = WorldRun(runIndex: 1, book: BoundBook(written: [], essencePaid: 0),
                               mapSeed: 78, rng: SeededRNG(seed: 78), map: candidate,
                               playerPosition: point)
            var tile = candidate[point]
            tile.isRevealed = true
            return try XCTUnwrap(WorldTileVisibilityPresentation.resolve(
                run: run, point: point, tile: tile, visibility: .full,
                profile: profile, grade: .neutral).artRequest)
        }

        let connected = try resolved(map)
        map[east].ground = .water
        map[south].ground = .chasm
        map[south].elevation = 0
        let separated = try resolved(map)

        XCTAssertNotEqual(connected.adjacency, separated.adjacency)
        XCTAssertNotEqual(connected.southExposureLevels, separated.southExposureLevels)
    }

    func testHiddenTerrainProducesIdenticalOpaquePixelsWithoutArtRequest() {
        let point = GridPoint(x: 3, y: 1)
        var stoneMap = openMap(width: 5, height: 3, entry: .init(x: 0, y: 1))
        stoneMap[point].ground = .stone
        var waterMap = stoneMap
        waterMap[point].ground = .water
        let profile = WorldRules.visibilityProfile(illumination: 0)

        func hiddenRequest(in map: WorldMap) -> MapTileArtRequest? {
            let run = WorldRun(runIndex: 1, book: BoundBook(written: [], essencePaid: 0),
                               mapSeed: 9, rng: SeededRNG(seed: 9), map: map,
                               playerPosition: map.entry)
            return WorldTileVisibilityPresentation.resolve(
                run: run, point: point, tile: map[point], visibility: .hidden,
                profile: profile, grade: .neutral).artRequest
        }

        XCTAssertNil(hiddenRequest(in: stoneMap))
        XCTAssertNil(hiddenRequest(in: waterMap))
        let hiddenStone = WorldTileVisibilityPresentation.opaqueFogPixels()
        let hiddenWater = WorldTileVisibilityPresentation.opaqueFogPixels()

        XCTAssertEqual(hiddenStone, hiddenWater)
        XCTAssertEqual(Set(stride(from: 0, to: hiddenStone.count, by: 4).map {
            Array(hiddenStone[$0..<($0 + 4)])
        }), Set([[UInt8(0), 0, 0, 255]]))
    }

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
