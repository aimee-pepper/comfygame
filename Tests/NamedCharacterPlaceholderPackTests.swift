import Foundation
import XCTest
@testable import Bookbinder

final class NamedCharacterPlaceholderPackTests: XCTestCase {
    private func manifestData() throws -> Data {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        return try Data(contentsOf: root
            .appendingPathComponent("AssetLab/integration/named-character-placeholders-v1/manifest.json"))
    }

    func testFrozenManifestHasExactCompleteNativeCoverage() throws {
        let pack = try NativeVisualRuntime.NamedCharacterPlaceholderPack(
            manifestData: manifestData())
        XCTAssertEqual(pack.count, 29 * 5)
        XCTAssertEqual(NativeVisualRuntime.NamedCharacterPlaceholderPack
            .canonicalManifestSHA256,
            "e0bccbfa9a6637c0a0aee9e536e842b555b3b2c2866566db06d98189ce55447b")

        for travellerID in NativeVisualRuntime.NamedCharacterPlaceholderPack
            .supportedTravellerIDs {
            let cameo = try XCTUnwrap(pack.cameo(for: travellerID))
            XCTAssertEqual(cameo.asset.width, 16)
            XCTAssertEqual(cameo.asset.height, 16)
            XCTAssertNoThrow(try NativeVisualRuntime.validate(cameo.asset))
            XCTAssertEqual(cameo.sourceCommandSHA256.count, 64)

            for facing in NativeVisualRuntime.MapFacing.allCases {
                let map = try XCTUnwrap(pack.mapSprite(for: travellerID, facing: facing))
                XCTAssertNoThrow(try NativeVisualRuntime.validate(map.asset))
                XCTAssertEqual(map.sourceCommandSHA256.count, 64)
            }
        }
    }

    func testProfilesNeverSubstituteAndUnknownIdentityFailsClosed() throws {
        let pack = try NativeVisualRuntime.NamedCharacterPlaceholderPack(
            manifestData: manifestData())
        let mara: TravellerID = "mara"
        XCTAssertNotEqual(pack.cameo(for: mara)?.asset,
                          pack.mapSprite(for: mara, facing: .north)?.asset)
        XCTAssertNil(pack.cameo(for: "generated-person-1"))
        XCTAssertNil(pack.mapSprite(for: "unknown", facing: .south))
    }

    func testAnyByteDriftFailsThePinnedImmutableManifest() throws {
        var data = try manifestData()
        data[data.startIndex] ^= 0x01
        XCTAssertThrowsError(try NativeVisualRuntime.NamedCharacterPlaceholderPack(
            manifestData: data)) {
            XCTAssertEqual($0 as? NativeVisualRuntime.NamedCharacterPackError,
                           .rawManifestHashMismatch)
        }
    }
}
