import Foundation
import XCTest
@testable import Bookbinder

final class NativeVisualPackTests: XCTestCase {
    private struct Registry: NativeVisualRuntime.Registry {
        var manifestSHA256 = String(repeating: "a", count: 64)
        var pipelineVersion = "catalogue-items-v1-test"
        var canvasWidth: UInt8 = 4
        var canvasHeight: UInt8 = 4
        var assets: [NativeVisualRuntime.Entry]
        var explicitlyUnsupportedIDs: [String] = []
    }

    private func asset(commands: [NativeVisualRuntime.PixelCommand] = [
        .init(x: 1, y: 1, width: 2, height: 2, rgba: 0x112233ff)
    ]) throws -> NativeVisualRuntime.GeneratedPixelAsset {
        let pixels = try NativeVisualRuntime.decodedRGBA(width: 4, height: 4,
                                                         commands: commands)
        return .init(width: 4, height: 4, commands: commands,
                     commandSHA256: NativeVisualRuntime.commandSHA256(commands),
                     decodedRGBASHA256: NativeVisualRuntime.sha256(pixels))
    }

    func testNormalizedCommandAndDecodedHashesAreDeterministic() throws {
        let commands: [NativeVisualRuntime.PixelCommand] = [
            .init(x: 0, y: 0, width: 4, height: 4, rgba: 0x01020304),
            .init(x: 1, y: 1, width: 2, height: 2, rgba: 0xaabbccdd),
        ]
        let first = try asset(commands: commands)
        let second = try asset(commands: commands)
        XCTAssertEqual(first, second)
        XCTAssertNoThrow(try NativeVisualRuntime.validate(first))
        let pixels = try NativeVisualRuntime.decodedRGBA(width: 4, height: 4,
                                                         commands: commands)
        XCTAssertEqual(Array(pixels[20..<24]), [0xaa, 0xbb, 0xcc, 0xdd])
    }

    func testBoundsAndEvidenceHashesAreStrict() throws {
        let outside = [NativeVisualRuntime.PixelCommand(
            x: 3, y: 0, width: 2, height: 1, rgba: 0xffffffff)]
        XCTAssertThrowsError(try NativeVisualRuntime.decodedRGBA(
            width: 4, height: 4, commands: outside)) {
            XCTAssertEqual($0 as? NativeVisualRuntime.ValidationError,
                           .rectangleOutOfBounds(0))
        }
        var badCommand = try asset(); badCommand.commandSHA256 = String(repeating: "0", count: 64)
        XCTAssertThrowsError(try NativeVisualRuntime.validate(badCommand))
        var badPixels = try asset(); badPixels.decodedRGBASHA256 = String(repeating: "f", count: 64)
        XCTAssertThrowsError(try NativeVisualRuntime.validate(badPixels))
        var malformed = try asset(); malformed.commandSHA256 = "not-a-hash"
        XCTAssertThrowsError(try NativeVisualRuntime.validate(malformed))
    }

    func testPackRejectsDuplicateKeysCanvasMismatchAndCoverageErrors() throws {
        let key = NativeVisualRuntime.GeneratedVisualKey(catalogueID: "salve", identified: true)
        let entry = NativeVisualRuntime.Entry(key: key, asset: try asset())
        XCTAssertThrowsError(try NativeVisualRuntime.Pack(
            registry: Registry(assets: [entry, entry]), requiredCatalogueIDs: ["salve"]))

        var wrongCanvas = try asset(); wrongCanvas.width = 3
        XCTAssertThrowsError(try NativeVisualRuntime.Pack(
            registry: Registry(assets: [.init(key: key, asset: wrongCanvas)]),
            requiredCatalogueIDs: ["salve"]))

        XCTAssertThrowsError(try NativeVisualRuntime.Pack(
            registry: Registry(assets: []), requiredCatalogueIDs: ["salve"])) {
            XCTAssertEqual($0 as? NativeVisualRuntime.ValidationError,
                           .incompleteCoverage(["salve"]))
        }
        XCTAssertThrowsError(try NativeVisualRuntime.Pack(
            registry: Registry(assets: [entry]), requiredCatalogueIDs: [])) {
            XCTAssertEqual($0 as? NativeVisualRuntime.ValidationError,
                           .unexpectedCoverage(["salve"]))
        }
    }

    func testUnsupportedCoverageIsExplicitUniqueAndDisjointFromAssets() throws {
        XCTAssertNoThrow(try NativeVisualRuntime.Pack(
            registry: Registry(assets: [], explicitlyUnsupportedIDs: ["legacy_token"]),
            requiredCatalogueIDs: ["legacy_token"]))
        XCTAssertThrowsError(try NativeVisualRuntime.Pack(
            registry: Registry(assets: [], explicitlyUnsupportedIDs: ["x", "x"]),
            requiredCatalogueIDs: ["x"]))

        let entry = NativeVisualRuntime.Entry(
            key: .init(catalogueID: "salve", identified: true), asset: try asset())
        XCTAssertThrowsError(try NativeVisualRuntime.Pack(
            registry: Registry(assets: [entry], explicitlyUnsupportedIDs: ["salve"]),
            requiredCatalogueIDs: ["salve"]))
    }
}
