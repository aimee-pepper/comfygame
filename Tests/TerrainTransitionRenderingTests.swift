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
}
