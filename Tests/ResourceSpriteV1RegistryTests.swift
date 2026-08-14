import CryptoKit
import XCTest
@testable import Bookbinder

final class ResourceSpriteV1RegistryTests: XCTestCase {
    private func sha(_ bytes: [UInt8]) -> String {
        SHA256.hash(data: Data(bytes)).map { String(format: "%02x", $0) }.joined()
    }

    func testRegistryCoversExactLiveResourceCatalogueInOrder() {
        XCTAssertEqual(ResourceSpriteV1Registry.packID, "resource-sprites-v1")
        XCTAssertEqual(ResourceSpriteV1Registry.orderedResourceIDs,
                       ContentCatalog.shared.resources.map(\.id))
        XCTAssertEqual(ResourceSpriteV1Registry.orderedResourceIDs.count, 23)
    }

    func testProfilesHaveExactDimensionsAndDecodedHashes() throws {
        for id in ResourceSpriteV1Registry.orderedResourceIDs {
            for profile in ResourceSpriteV1Profile.allCases {
                let asset = ResourceSpriteV1Registry.asset(for: id, profile: profile)
                if id == Resources.mote && profile == .map {
                    XCTAssertNil(asset)
                    continue
                }
                let sprite = try XCTUnwrap(asset, "\(profile.rawValue)/\(id.rawValue)")
                let side = switch profile { case .inventory: 32; case .map: 16; case .field: 8 }
                XCTAssertEqual(sprite.width, side)
                XCTAssertEqual(sprite.height, side)
                XCTAssertEqual(sprite.rgbaPixels.count, side * side * 4)
                XCTAssertEqual(sha(sprite.rgbaPixels), sprite.decodedRGBASHA256)
                XCTAssertTrue(stride(from: 3, to: sprite.rgbaPixels.count, by: 4)
                    .contains { sprite.rgbaPixels[$0] == 0 })
            }
        }
    }

    func testUnknownResourceFailsClosed() {
        XCTAssertNil(ResourceSpriteV1Registry.asset(
            for: ResourceID(rawValue: "not_a_live_resource"), profile: .inventory))
    }

    @MainActor
    func testProductionRendererConsumesTheAuthoredMapAndInventoryProfiles() throws {
        for id in ResourceSpriteV1Registry.orderedResourceIDs {
            let inventory = try XCTUnwrap(ResourceSpriteV1Registry.asset(for: id, profile: .inventory))
            XCTAssertEqual(MapAssetTestSupport.productionInventoryResourcePixels(id),
                           inventory.rgbaPixels, "inventory/\(id.rawValue)")
            let field = try XCTUnwrap(ResourceSpriteV1Registry.asset(for: id, profile: .field))
            XCTAssertEqual(MapAssetTestSupport.productionFieldResourcePixels(id),
                           field.rgbaPixels, "field/\(id.rawValue)")
            if id == Resources.mote {
                XCTAssertTrue(MapAssetTestSupport.productionMapResourcePixels(id).allSatisfy { $0 == 0 })
            } else {
                let map = try XCTUnwrap(ResourceSpriteV1Registry.asset(for: id, profile: .map))
                XCTAssertEqual(MapAssetTestSupport.productionMapResourcePixels(id),
                               map.rgbaPixels, "map/\(id.rawValue)")
            }
        }
    }

    func testWorldHaulConsumesTheIndependentFieldProfile() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf: root.appending(path: "Sources/Screens/WorldView.swift"),
                                encoding: .utf8)
        XCTAssertTrue(source.contains("ResourceFieldMarkerIdentity("))
        XCTAssertTrue(source.contains(".frame(width: 8, height: 8)"))
    }
}
