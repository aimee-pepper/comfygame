import Foundation
import XCTest
@testable import Bookbinder

final class CatalogueItemVisualAdapterTests: XCTestCase {
    private struct Registry: NativeVisualRuntime.Registry {
        let manifestSHA256 = String(repeating: "b", count: 64)
        let pipelineVersion = "aimee-authored-catalogue-items-v1-test"
        let canvasWidth: UInt8 = 2
        let canvasHeight: UInt8 = 2
        var assets: [NativeVisualRuntime.Entry]
        var explicitlyUnsupportedIDs: [String]
    }

    private func asset(_ rgba: UInt32) throws -> NativeVisualRuntime.GeneratedPixelAsset {
        let commands = [NativeVisualRuntime.PixelCommand(
            x: 0, y: 0, width: 2, height: 2, rgba: rgba)]
        return try .init(width: 2, height: 2, commands: commands,
                         commandSHA256: NativeVisualRuntime.commandSHA256(commands),
                         decodedRGBASHA256: NativeVisualRuntime.sha256(
                            NativeVisualRuntime.decodedRGBA(width: 2, height: 2,
                                                            commands: commands)))
    }

    func testAdapterUsesExactCatalogueAndIdentificationKeyWithoutGuessing() throws {
        let hidden = try asset(0x111111ff), known = try asset(0xeeeeeeff)
        let pack = try NativeVisualRuntime.Pack(
            registry: Registry(assets: [
                .init(key: .init(catalogueID: "salve", identified: false), asset: hidden),
                .init(key: .init(catalogueID: "salve", identified: true), asset: known),
            ], explicitlyUnsupportedIDs: []), requiredCatalogueIDs: ["salve"])
        let adapter = CatalogueItemVisualAdapter(pack: pack)
        XCTAssertEqual(adapter.asset(for: "salve", identified: false), hidden)
        XCTAssertEqual(adapter.asset(for: "salve", identified: true), known)
        XCTAssertNil(adapter.asset(for: "cache_key", identified: true))
    }

    func testUnsupportedMissingRegistryAndMissingVariantReturnNilFallback() throws {
        let known = try asset(0xeeeeeeff)
        let pack = try NativeVisualRuntime.Pack(
            registry: Registry(assets: [
                .init(key: .init(catalogueID: "salve", identified: true), asset: known),
            ], explicitlyUnsupportedIDs: ["legacy_token"]),
            requiredCatalogueIDs: ["salve", "legacy_token"])
        let adapter = CatalogueItemVisualAdapter(pack: pack)
        XCTAssertNil(adapter.asset(for: "salve", identified: false),
                     "An absent unidentified variant must not borrow identified art")
        XCTAssertNil(adapter.asset(for: "legacy_token", identified: true))
        XCTAssertNil(CatalogueItemVisualAdapter(pack: nil)
            .asset(for: "salve", identified: true))
    }
}
