import CryptoKit
import XCTest
@testable import Bookbinder

@MainActor final class TerrainProductionPackTests: XCTestCase {
    func testStrictPackOpensAndMatchesEveryAcceptedRGBAFixture() throws {
        let pack = MapAssetTestSupport.productionPack()
        try pack.open()
        let cases = try pack.conformanceCases
        XCTAssertEqual(cases.count, 149)
        for fixture in cases {
            let rgba = try pack.rgba(for: fixture.request)
            XCTAssertEqual(sha256(rgba), fixture.rgbaSHA256, fixture.id)
        }
    }

    func testAllTwelveGroundsAreRenderableAndOpaque() throws {
        XCTAssertEqual(TerrainProductionPack.Ground.allCases.map(\.rawValue), [
            "stone", "soil", "sand", "ice", "ash", "water", "deepWater", "rubble",
            "mud", "growth", "chasm", "groundcover",
        ])
        for ground in GroundType.allCases {
            let request = try MapAssetTestSupport.productionRequest(ground: ground)
            let pixels = try MapAssetTestSupport.productionPixels(request)
            XCTAssertEqual(pixels.count, 16 * 16 * 4, ground.rawValue)
            XCTAssertTrue(stride(from: 3, to: pixels.count, by: 4)
                .allSatisfy { pixels[$0] == 255 }, ground.rawValue)
        }
    }

    func testDepositsAreIndependentBoundedAndExcludedFromWater() throws {
        let none = try MapAssetTestSupport.productionPixels(
            MapAssetTestSupport.productionRequest(
                ground: .stone, point: .init(x: 2, y: 3), featureVariant: 1))
        let snow = try MapAssetTestSupport.productionPixels(
            MapAssetTestSupport.productionRequest(
                ground: .stone, point: .init(x: 2, y: 3), featureVariant: 1, snow: true))
        let ash = try MapAssetTestSupport.productionPixels(
            MapAssetTestSupport.productionRequest(
                ground: .stone, point: .init(x: 2, y: 3), featureVariant: 1,
                settledAsh: true))
        let both = try MapAssetTestSupport.productionPixels(
            MapAssetTestSupport.productionRequest(
                ground: .stone, point: .init(x: 2, y: 3), featureVariant: 1,
                snow: true, settledAsh: true))
        XCTAssertNotEqual(none, snow)
        XCTAssertNotEqual(none, ash)
        XCTAssertNotEqual(snow, both)
        XCTAssertNotEqual(ash, both)

        let changedPixels = stride(from: 0, to: both.count, by: 4).filter { index in
            Array(both[index..<(index + 4)]) != Array(none[index..<(index + 4)])
        }.count
        XCTAssertLessThanOrEqual(changedPixels, 179)

        let water = try MapAssetTestSupport.productionPixels(
            MapAssetTestSupport.productionRequest(ground: .water))
        let coveredWater = try MapAssetTestSupport.productionPixels(
            MapAssetTestSupport.productionRequest(
                ground: .water, snow: true, settledAsh: true))
        XCTAssertEqual(water, coveredWater)
    }

    func testStrictLoaderFailsClosedForChangedManifestOrAssetBytes() throws {
        let root = runtimeRoot
        let manifestChanged = TerrainProductionPack(rootURL: root) { url in
            var data = try Data(contentsOf: url)
            if url.lastPathComponent == "manifest.json" { data.append(0x20) }
            return data
        }
        XCTAssertThrowsError(try manifestChanged.open()) {
            XCTAssertEqual($0 as? TerrainProductionPack.PackError, .invalidManifest)
        }

        let assetChanged = TerrainProductionPack(rootURL: root) { url in
            var data = try Data(contentsOf: url)
            if url.pathExtension == "png", !data.isEmpty { data[data.startIndex] ^= 0xff }
            return data
        }
        XCTAssertThrowsError(try assetChanged.open()) {
            guard case .corruptAsset = $0 as? TerrainProductionPack.PackError else {
                return XCTFail("Unexpected error: \($0)")
            }
        }
    }

    func testAuthoredSouthWallPackPinsManifestAndEveryStableRoute() throws {
        let pack = TerrainSouthWallPack(rootURL: southWallRuntimeRoot)
        try pack.open()
        let descriptor = try identicalDescriptor()
        let grounds: [TerrainProductionPack.Ground] = [
            .stone, .soil, .sand, .ash, .rubble, .mud,
        ]
        for ground in grounds { for depth in 1...3 {
            for west in [false, true] { for east in [false, true] { for variant in 0...3 {
                let request = try TerrainSouthWallPack.Request(
                    ground: ground, depth: depth, westContinuation: west,
                    eastContinuation: east, featureVariant: variant)
                let rgba = try pack.rgba(for: request, descriptor: descriptor)
                XCTAssertEqual(rgba.count, 16 * 3 * 4)
                XCTAssertTrue(stride(from: 3, to: rgba.count, by: 4).contains {
                    rgba[$0] == 255
                })
            }}}
        }}
        let span = try pack.rgba(
            for: TerrainSouthWallPack.Request(
                ground: .stone, depth: 3, westContinuation: true,
                eastContinuation: true, featureVariant: 0),
            descriptor: descriptor)
        XCTAssertEqual(sha256(span),
                       "0308d6397bdc95ccf0215d953d70bdb1419424e24f0e85c03efe302176ce5bb7")
    }

    func testBuiltAppContainsBothRuntimePacksAtTheirExactNames() throws {
        let terrain = try TerrainProductionPack.bundled()
        try terrain.open()
        let walls = try TerrainSouthWallPack.bundled()
        try walls.open()
        XCTAssertTrue(FileManager.default.isReadableFile(atPath: Bundle.main.bundleURL
            .appendingPathComponent("TerrainProductionPack-v1/manifest.json").path))
        XCTAssertTrue(FileManager.default.isReadableFile(atPath: Bundle.main.bundleURL
            .appendingPathComponent("TerrainSouthWallPack-v1/manifest.json").path))
    }

    func testSouthWallPackFailsClosedForManifestAssetAndIllegalGround() throws {
        let changedManifest = TerrainSouthWallPack(rootURL: southWallRuntimeRoot) { url in
            var data = try Data(contentsOf: url)
            if url.lastPathComponent == "manifest.json" { data.append(0x20) }
            return data
        }
        XCTAssertThrowsError(try changedManifest.open()) {
            XCTAssertEqual($0 as? TerrainSouthWallPack.WallError, .invalidManifest)
        }
        XCTAssertThrowsError(try TerrainSouthWallPack.Request(
            ground: .water, depth: 1, westContinuation: false,
            eastContinuation: false, featureVariant: 0))

        let descriptor = try identicalDescriptor()
        let changedAsset = TerrainSouthWallPack(rootURL: southWallRuntimeRoot) { url in
            var data = try Data(contentsOf: url)
            if url.pathExtension == "png", !data.isEmpty { data[data.startIndex] ^= 0xff }
            return data
        }
        let request = try TerrainSouthWallPack.Request(
            ground: .soil, depth: 2, westContinuation: false,
            eastContinuation: true, featureVariant: 1)
        XCTAssertThrowsError(try changedAsset.rgba(for: request, descriptor: descriptor)) {
            guard case .corruptAsset = $0 as? TerrainSouthWallPack.WallError else {
                return XCTFail("Unexpected error: \($0)")
            }
        }
    }

    private var runtimeRoot: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("RuntimePacks/TerrainProductionPack-v1", isDirectory: true)
    }

    private var southWallRuntimeRoot: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("RuntimePacks/TerrainSouthWallPack-v1", isDirectory: true)
    }

    private func identicalDescriptor() throws -> WorldGrade2V1.Descriptor {
        let green = WorldGrade2V1.ResolvedColor(
            srgb: [62, 122, 86], resolutionVersion: "resolved-color-1.0.0",
            provenance: "bindRandom")
        return try WorldGrade2V1.resolve(.init(
            material: .init(identity: "mixedMineral", paletteFamilyID: "paleNeutral",
                            transform: .init(hue: 0, saturation: 1, value: 0)),
            atmosphere: .init(medium: "none", density: 0, paletteFamilyID: "clear"),
            flora: .init(coveragePercent: 40, paletteRichness: 50,
                         cast: [.init(speciesID: "flora-a", formID: 0, stature: 35,
                                      resolvedColor: green)]),
            resolvedColors: .init()))
    }

    private func sha256(_ bytes: [UInt8]) -> String {
        SHA256.hash(data: Data(bytes)).map { String(format: "%02x", $0) }.joined()
    }
}
