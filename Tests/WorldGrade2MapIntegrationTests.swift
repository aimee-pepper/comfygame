import Foundation
import XCTest
@testable import Bookbinder

final class WorldGrade2MapIntegrationTests: XCTestCase {
    private func descriptor(floraID: String? = nil) throws -> WorldGrade2V1.Descriptor {
        let cast = floraID.map {
            [WorldGrade2V1.FloraSpecies(
                speciesID: $0, formID: 0, stature: 35,
                resolvedColor: .init(srgb: [62, 122, 86],
                                     resolutionVersion: "resolved-color-1.0.0",
                                     provenance: "bindRandom"))]
        } ?? []
        return try WorldGrade2V1.resolve(.init(
            material: .init(identity: "mixedMineral", paletteFamilyID: "paleNeutral",
                            transform: .init(hue: 0, saturation: 1, value: 0)),
            atmosphere: .init(medium: "none", density: 0, paletteFamilyID: "clear"),
            flora: .init(coveragePercent: cast.isEmpty ? 0 : 40,
                         paletteRichness: 50, cast: cast),
            resolvedColors: .init()))
    }

    private func receipt(_ descriptor: WorldGrade2V1.Descriptor) throws -> WorldVisualReceipt {
        let request = WorldGrade2V1.Request(
            material: descriptor.material,
            atmosphere: descriptor.atmosphere,
            flora: .init(coveragePercent: descriptor.flora.coveragePercent,
                         paletteRichness: descriptor.flora.paletteRichness,
                         cast: descriptor.flora.cast),
            resolvedColors: .init(material: descriptor.resolvedColors.material,
                                  atmosphere: descriptor.resolvedColors.atmosphere,
                                  emitter: descriptor.resolvedColors.emitter))
        return try WorldVisualReceipt(request: request, descriptor: descriptor,
                                      descriptorHash: descriptor.canonicalDescriptorSHA256,
                                      selectedSourceByScope: [:])
    }

    private func run(receipt: WorldVisualReceipt?) -> WorldRun {
        let point = GridPoint(x: 0, y: 0)
        return WorldRun(
            runIndex: 1,
            book: BoundBook(symbols: [:], randomlyFilled: [], essencePaid: 0),
            mapSeed: 42,
            rng: SeededRNG(seed: 42),
            map: WorldMap(width: 1, height: 1,
                          tiles: [Tile(ground: .stone, isRevealed: true)], entry: point),
            playerPosition: point,
            worldVisualReceipt: receipt)
    }

    func testLegacyRunWithoutDescriptorDecodesNilAndRoundTrips() throws {
        let encoded = try JSONEncoder().encode(run(receipt: nil))
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        object.removeValue(forKey: "worldVisualReceipt")
        let legacy = try JSONSerialization.data(withJSONObject: object)
        let decoded = try JSONDecoder().decode(WorldRun.self, from: legacy)
        XCTAssertNil(decoded.worldVisualReceipt)
        XCTAssertNil(try JSONDecoder().decode(WorldRun.self,
                                              from: JSONEncoder().encode(decoded))
            .worldVisualReceipt)
    }

    func testValidDescriptorPersistsLosslesslyAndAnchoredSnapshotRetainsIt() throws {
        let expected = try descriptor()
        let expectedReceipt = try receipt(expected)
        let original = run(receipt: expectedReceipt)
        let decoded = try JSONDecoder().decode(WorldRun.self, from: JSONEncoder().encode(original))
        XCTAssertEqual(decoded.worldVisualReceipt, expectedReceipt)
        XCTAssertEqual(decoded.anchoredSnapshot.worldVisualReceipt, expectedReceipt)
    }

    func testCorruptHashAndUnsupportedVersionFailWorldRunDecode() throws {
        for mutation in ["hash", "version"] {
            // Invalid receipts refuse ordinary encoding too, so mutate their encoded valid shape.
            var object = try XCTUnwrap(JSONSerialization.jsonObject(
                with: JSONEncoder().encode(try receipt(descriptor()))) as? [String: Any])
            if mutation == "hash" {
                object["descriptorHash"] = String(repeating: "0", count: 64)
            } else if var descriptorObject = object["descriptor"] as? [String: Any],
                      var versions = descriptorObject["versions"] as? [String: Any] {
                versions["rendererVersion"] = "world-grade-2-renderer-2.0.0"
                descriptorObject["versions"] = versions
                object["descriptor"] = descriptorObject
            }
            var runObject = try XCTUnwrap(JSONSerialization.jsonObject(
                with: JSONEncoder().encode(run(receipt: nil))) as? [String: Any])
            runObject["worldVisualReceipt"] = object
            let encoded = try JSONSerialization.data(withJSONObject: runObject)
            XCTAssertThrowsError(try JSONDecoder().decode(WorldRun.self, from: encoded))
        }
    }

    @MainActor
    func testDescriptorIdentityAndTerrainRecolorAreVersionedAndDeterministic() throws {
        let receipt = try descriptor()
        let identity = try MapAssetTestSupport.descriptorCacheIdentity(receipt)
        XCTAssertTrue(identity.contains(receipt.versions.rendererVersion))
        XCTAssertTrue(identity.hasSuffix(receipt.canonicalDescriptorSHA256))
        let first = try MapAssetTestSupport.gradedTerrainPixels(ground: .stone,
                                                               descriptor: receipt)
        let second = try MapAssetTestSupport.gradedTerrainPixels(ground: .stone,
                                                                descriptor: receipt)
        XCTAssertEqual(first, second)
        XCTAssertNotEqual(first, MapAssetTestSupport.terrainPixels(ground: .stone))
    }

    @MainActor
    func testFogAndCanonicalResourcePixelsIgnoreDescriptor() throws {
        let receipt = try descriptor()
        XCTAssertEqual(try MapAssetTestSupport.gradedTerrainPixels(
            ground: .stone, descriptor: receipt, revealed: false),
            MapAssetTestSupport.terrainPixels(ground: .stone, revealed: false))
        let composition = try MapAssetTestSupport.gradedResourceComposition("copper",
                                                                             descriptor: receipt)
        for pixel in stride(from: 0, to: composition.resourceOverlay.count, by: 4)
        where composition.resourceOverlay[pixel + 3] > 0 {
            XCTAssertEqual(Array(composition.composed[pixel..<(pixel + 4)]),
                           Array(composition.resourceOverlay[pixel..<(pixel + 4)]),
                           "World grading changed resource pixel \(pixel / 4)")
        }
    }

    @MainActor
    func testFloraRequiresExactPersistedSpeciesIdentity() throws {
        let flora = Flora(id: InstanceID(rawValue: 7), traits: FloraTraits(), worldSeed: 42)
        let matched = try descriptor(floraID: "flora-7")
        XCTAssertFalse(try MapAssetTestSupport.gradedFloraPixels(flora, descriptor: matched).isEmpty)
        let missing = try descriptor(floraID: "flora-8")
        XCTAssertThrowsError(try MapAssetTestSupport.gradedFloraPixels(flora,
                                                                       descriptor: missing))
    }
}
