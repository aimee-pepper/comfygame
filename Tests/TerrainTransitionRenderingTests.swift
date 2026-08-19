import XCTest
@testable import Bookbinder

@MainActor final class TerrainTransitionRenderingTests: XCTestCase {
    func testEveryGroundOwnsTheCompleteAdjacencyGrammar() {
        for ground in GroundType.allCases {
            let variants = Set((0..<16).map { adjacency in
                MapAssetTestSupport.terrainPixels(
                    ground: ground,
                    adjacency: adjacency,
                    featureVariant: 0,
                    seed: 404
                )
            })
            XCTAssertEqual(variants.count, 16,
                           "\(ground.rawValue) must expose every centre/edge/corner adjacency state")
        }
    }

    func testJoinedGroundSuppressesOnlyItsSharedSide() {
        for ground in GroundType.allCases {
            let isolated = MapAssetTestSupport.terrainPixels(ground: ground, adjacency: 0, seed: 404)
            let joinedNorth = MapAssetTestSupport.terrainPixels(ground: ground, adjacency: 1, seed: 404)
            let joinedEast = MapAssetTestSupport.terrainPixels(ground: ground, adjacency: 2, seed: 404)
            XCTAssertNotEqual(isolated, joinedNorth)
            XCTAssertNotEqual(isolated, joinedEast)
            XCTAssertNotEqual(joinedNorth, joinedEast)
        }
    }

    func testLiftedStoneUsesTerrainDerivedSidewallInsteadOfBlackBackdrop() {
        let pixels = try! MapAssetTestSupport.renderedTerrainPixels(
            ground: .stone, adjacency: 15, elevation: 3,
            southExposureLevels: 3, seed: 404)
        let unshaded = MapAssetTestSupport.terrainPixels(
            ground: .stone, adjacency: 15, elevation: 3,
            southExposureLevels: 3, seed: 404)
        let face = Array(pixels[((17 * 16 + 8) * 4)..<((17 * 16 + 8) * 4 + 4)])
        let unshadedFace = Array(unshaded[((17 * 16 + 8) * 4)..<((17 * 16 + 8) * 4 + 4)])
        XCTAssertEqual(face, [23, 23, 26, 255])
        XCTAssertEqual(face[3], 255)
        XCTAssertLessThan(face[0], unshadedFace[0])
        XCTAssertLessThan(face[1], unshadedFace[1])
        XCTAssertLessThan(face[2], unshadedFace[2])
    }

    func testEveryLiftedTileOwnsAnOpaqueLogicalFootprint() {
        for ground in GroundType.allCases {
            for elevation in 0...MapAssetContract.maximumElevation {
                let pixels = MapAssetTestSupport.terrainPixels(
                    ground: ground, adjacency: 15, elevation: elevation,
                    southExposureLevels: 0, seed: 404)
                for y in MapAssetContract.maximumElevation..<MapAssetContract.spriteHeight {
                    for x in 0..<MapAssetContract.spriteWidth {
                        XCTAssertEqual(pixels[(y * MapAssetContract.spriteWidth + x) * 4 + 3], 255,
                                       "\(ground.rawValue) elevation \(elevation) left alpha at \(x),\(y)")
                    }
                }
            }
        }
    }

    func testWaterAnimatesContinuouslyInFourCrispFrames() {
        let frames = (0..<4).map {
            MapAssetTestSupport.animatedTerrainPixels(ground: .water, tick: $0)
        }
        XCTAssertEqual(Set(frames).count, 4)
        XCTAssertEqual(frames[0], MapAssetTestSupport.animatedTerrainPixels(
            ground: .water, tick: 4))
    }

    func testIceGlintsBrieflyRatherThanPulsingContinuously() {
        let frames = (0..<32).map {
            MapAssetTestSupport.terrainAnimationFrame(ground: .ice, tick: $0)
        }
        XCTAssertEqual(frames.compactMap { $0 }.count, 3)
        XCTAssertEqual(Set(frames.compactMap { $0 }), Set([0, 1, 2]))
    }

    func testGroundcoverMovesOnlyDuringWindGusts() {
        XCTAssertTrue((0..<32).allSatisfy {
            MapAssetTestSupport.terrainAnimationFrame(
                ground: .groundcover, tick: $0, atmosphereMotion: 50) == nil
        })
        let windyFrames = (0..<32).map {
            MapAssetTestSupport.terrainAnimationFrame(
                ground: .groundcover, tick: $0, atmosphereMotion: 80)
        }
        XCTAssertTrue(windyFrames.contains(where: { $0 != nil }))
        XCTAssertTrue(windyFrames.contains(where: { $0 == nil }))
    }

    func testOccasionalTerrainEffectsAreDesynchronisedByTileIdentity() {
        let first = (0..<32).map {
            MapAssetTestSupport.terrainAnimationFrame(
                ground: .ice, tick: $0, point: .init(x: 1, y: 1))
        }
        let second = (0..<32).map {
            MapAssetTestSupport.terrainAnimationFrame(
                ground: .ice, tick: $0, point: .init(x: 2, y: 1))
        }
        XCTAssertNotEqual(first, second)
    }
}
