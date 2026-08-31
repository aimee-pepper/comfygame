import Foundation
import XCTest
@testable import Bookbinder

final class NativeVisualPackTests: XCTestCase {
    private struct Registry: NativeVisualRuntime.Registry {
        var manifestSHA256 = String(repeating: "a", count: 64)
        var pipelineVersion = "catalogue-items-placeholder-v1-test"
        var artProvenance: NativeVisualRuntime.ArtProductionProvenanceV1 = .testOnly
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

    private func identity(for registry: Registry, packID: String = "test-art-pack")
        -> NativeVisualRuntime.ArtPackIdentityV1 {
        .init(
            packID: packID,
            manifestSHA256: registry.manifestSHA256,
            registryContentSHA256: NativeVisualRuntime.Pack.registryContentSHA256(registry)
        )
    }

    private func finalReceipt(
        for registry: Registry,
        provider: String = "openai-imagegen"
    ) -> NativeVisualRuntime.GeneratedFinalArtReceiptV1 {
        .init(
            pack: identity(for: registry),
            provider: provider,
            generationReceiptSHA256: String(repeating: "1", count: 64),
            aimeeApprovalReceiptSHA256: String(repeating: "4", count: 64),
            assets: registry.assets.map {
                .init(
                    key: $0.key,
                    sourceRasterSHA256: String(repeating: "2", count: 64),
                    productionDecodedRGBASHA256: $0.asset.decodedRGBASHA256
                )
            }
        )
    }

    private func aimeeAuthoredReceipt(
        for registry: Registry,
        author: String = "aimee-pepper",
        sourcePath: String = "AssetSources/CatalogueItems-v1/salve/identified/source/salve--identified.png"
    ) -> NativeVisualRuntime.AimeeAuthoredFinalArtReceiptV1 {
        .init(
            pack: identity(for: registry),
            author: author,
            aimeeAuthorshipReceiptSHA256: String(repeating: "5", count: 64),
            exporterID: "assetlab/export-native-raster-v1",
            exporterCheckSHA256: String(repeating: "6", count: 64),
            assets: registry.assets.map {
                .init(
                    key: $0.key,
                    semanticSourcePath: sourcePath,
                    sourceFileSHA256: String(repeating: "7", count: 64),
                    sourceDecodedRGBASHA256: String(repeating: "8", count: 64),
                    productionDecodedRGBASHA256: $0.asset.decodedRGBASHA256
                )
            }
        )
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

    func testFinalArtRejectsHandAuthoredPixelCommandProvenance() throws {
        let entry = NativeVisualRuntime.Entry(
            key: .init(catalogueID: "salve", identified: true), asset: try asset())
        let base = Registry(
            pipelineVersion: "catalogue-items-final-v1-test",
            assets: [entry]
        )
        let receipt = finalReceipt(for: base, provider: "hand-authored-pixel-commands")
        XCTAssertThrowsError(try NativeVisualRuntime.Pack(
            registry: Registry(
                pipelineVersion: "catalogue-items-final-v1-test",
                artProvenance: .imageGeneratedFinal(receipt),
                assets: [entry]
            ),
            requiredCatalogueIDs: ["salve"]
        )) {
            XCTAssertEqual(
                $0 as? NativeVisualRuntime.ValidationError,
                .finalArtMustUseImageGeneration("hand-authored-pixel-commands")
            )
        }
    }

    func testInventedGeneratedFinalReceiptIsRejectedEvenWhenWellShaped() throws {
        let entry = NativeVisualRuntime.Entry(
            key: .init(catalogueID: "salve", identified: true), asset: try asset())
        let base = Registry(
            pipelineVersion: "catalogue-items-final-v1-test",
            assets: [entry]
        )
        let invented = finalReceipt(for: base)
        XCTAssertThrowsError(try NativeVisualRuntime.Pack(
            registry: Registry(
                pipelineVersion: "catalogue-items-final-v1-test",
                artProvenance: .imageGeneratedFinal(invented),
                assets: [entry]
            ),
            requiredCatalogueIDs: ["salve"]
        )) {
            XCTAssertEqual($0 as? NativeVisualRuntime.ValidationError,
                           .unapprovedGeneratedFinalArt("test-art-pack"))
        }
    }

    func testGeneratedFinalArtRequiresCompletePixelBoundReceipt() throws {
        let entry = NativeVisualRuntime.Entry(
            key: .init(catalogueID: "salve", identified: true), asset: try asset())
        let base = Registry(assets: [entry])
        var valid = finalReceipt(for: base)

        var missingApproval = valid
        missingApproval.aimeeApprovalReceiptSHA256 = ""
        XCTAssertThrowsError(try NativeVisualRuntime.Pack(
            registry: Registry(
                artProvenance: .imageGeneratedFinal(missingApproval),
                assets: [entry]
            ),
            requiredCatalogueIDs: ["salve"]
        )) {
            XCTAssertEqual(
                $0 as? NativeVisualRuntime.ValidationError,
                .invalidGeneratedFinalArtReceipt
            )
        }

        valid.assets[0].productionDecodedRGBASHA256 = String(repeating: "3", count: 64)
        XCTAssertThrowsError(try NativeVisualRuntime.Pack(
            registry: Registry(artProvenance: .imageGeneratedFinal(valid), assets: [entry]),
            requiredCatalogueIDs: ["salve"]
        )) {
            XCTAssertEqual($0 as? NativeVisualRuntime.ValidationError,
                           .generatedFinalAssetReceiptMismatch)
        }
    }

    func testAimeeAuthoredFinalArtHasSeparateFailClosedAuthority() throws {
        let entry = NativeVisualRuntime.Entry(
            key: .init(catalogueID: "salve", identified: true), asset: try asset())
        let base = Registry(assets: [entry])

        let unapproved = aimeeAuthoredReceipt(for: base)
        XCTAssertThrowsError(try NativeVisualRuntime.Pack(
            registry: Registry(artProvenance: .aimeeAuthoredFinal(unapproved), assets: [entry]),
            requiredCatalogueIDs: ["salve"]
        )) {
            XCTAssertEqual($0 as? NativeVisualRuntime.ValidationError,
                           .unapprovedAimeeAuthoredFinalArt("test-art-pack"))
        }

        let wrongAuthor = aimeeAuthoredReceipt(for: base, author: "agent")
        XCTAssertThrowsError(try NativeVisualRuntime.Pack(
            registry: Registry(artProvenance: .aimeeAuthoredFinal(wrongAuthor), assets: [entry]),
            requiredCatalogueIDs: ["salve"]
        )) {
            XCTAssertEqual($0 as? NativeVisualRuntime.ValidationError,
                           .invalidAimeeAuthoredFinalArtReceipt)
        }

        let generatedRelabel = finalReceipt(for: base, provider: "aimee-pepper")
        XCTAssertThrowsError(try NativeVisualRuntime.Pack(
            registry: Registry(artProvenance: .imageGeneratedFinal(generatedRelabel), assets: [entry]),
            requiredCatalogueIDs: ["salve"]
        )) {
            XCTAssertEqual($0 as? NativeVisualRuntime.ValidationError,
                           .finalArtMustUseImageGeneration("aimee-pepper"))
        }
    }

    func testAimeeAuthoredFinalArtRequiresSemanticSourceAndExactProductionPixels() throws {
        let entry = NativeVisualRuntime.Entry(
            key: .init(catalogueID: "salve", identified: true), asset: try asset())
        let base = Registry(assets: [entry])
        for path in [
            "AssetSources/CatalogueItems-v1/salve/identified/source/" + String(repeating: "a", count: 64) + ".png",
            "AssetSources/CatalogueItems-v1/salve/identified/source/salve 2.png",
            "AssetSources/../outside.png",
            "AssetEvidence/CatalogueItems-v1/salve.png",
        ] {
            let receipt = aimeeAuthoredReceipt(for: base, sourcePath: path)
            XCTAssertThrowsError(try NativeVisualRuntime.Pack(
                registry: Registry(artProvenance: .aimeeAuthoredFinal(receipt), assets: [entry]),
                requiredCatalogueIDs: ["salve"]
            )) {
                XCTAssertEqual($0 as? NativeVisualRuntime.ValidationError,
                               .aimeeAuthoredFinalAssetReceiptMismatch)
            }
        }

        var wrongPixels = aimeeAuthoredReceipt(for: base)
        wrongPixels.assets[0].productionDecodedRGBASHA256 = String(repeating: "9", count: 64)
        XCTAssertThrowsError(try NativeVisualRuntime.Pack(
            registry: Registry(artProvenance: .aimeeAuthoredFinal(wrongPixels), assets: [entry]),
            requiredCatalogueIDs: ["salve"]
        )) {
            XCTAssertEqual($0 as? NativeVisualRuntime.ValidationError,
                           .aimeeAuthoredFinalAssetReceiptMismatch)
        }
    }

    func testPlaceholderAndLegacyCannotBeRelabelledAsNewFinalPacks() throws {
        let placeholderBase = Registry(
            pipelineVersion: "catalogue-items-final-v1-test",
            assets: []
        )
        let placeholderIdentity = identity(
            for: placeholderBase,
            packID: "new-final-placeholder-v1"
        )
        XCTAssertThrowsError(try NativeVisualRuntime.Pack(
            registry: Registry(
                pipelineVersion: "catalogue-items-final-v1-test",
                artProvenance: .functionalPlaceholder(placeholderIdentity),
                assets: []
            ),
            requiredCatalogueIDs: []
        )) {
            XCTAssertEqual(
                $0 as? NativeVisualRuntime.ValidationError,
                .unapprovedFunctionalPlaceholder("new-final-placeholder-v1")
            )
        }

        let legacyBase = Registry(pipelineVersion: "new-final-pack-v1", assets: [])
        let legacyIdentity = identity(for: legacyBase, packID: "new-hand-authored-pack")
        XCTAssertThrowsError(try NativeVisualRuntime.Pack(
            registry: Registry(
                pipelineVersion: "new-final-pack-v1",
                artProvenance: .frozenLegacy(legacyIdentity),
                assets: []
            ),
            requiredCatalogueIDs: []
        )) {
            XCTAssertEqual(
                $0 as? NativeVisualRuntime.ValidationError,
                .unapprovedLegacyArtPack("new-hand-authored-pack")
            )
        }

        let forgedApprovedIdentity = NativeVisualRuntime.ArtPackIdentityV1(
            packID: "mob-gear-sprites-v1",
            manifestSHA256: "eff8f3bdb8d50fa15242ee75aea457f674c75f9e3af1640e5dbd598ebe9f87d4",
            registryContentSHA256: "1edc9814e108be9f1ee00d2f393b71331b21ad232de538c760c784969a1be0fe"
        )
        let forgedEntry = NativeVisualRuntime.Entry(
            key: .init(catalogueID: "new-hand-authored-id", identified: true),
            asset: try asset()
        )
        XCTAssertThrowsError(try NativeVisualRuntime.Pack(
            registry: Registry(
                manifestSHA256: forgedApprovedIdentity.manifestSHA256,
                pipelineVersion: "mob-gear-sprites-v1",
                artProvenance: .frozenLegacy(forgedApprovedIdentity),
                assets: [forgedEntry]
            ),
            requiredCatalogueIDs: ["new-hand-authored-id"]
        )) {
            XCTAssertEqual($0 as? NativeVisualRuntime.ValidationError,
                           .artPackIdentityMismatch("mob-gear-sprites-v1"))
        }
    }

    func testRegistryContentReceiptChangesForPixelsKeysAndUnsupportedCoverage() throws {
        let first = NativeVisualRuntime.Entry(
            key: .init(catalogueID: "salve", identified: true), asset: try asset())
        let baseline = Registry(assets: [first])
        let baselineHash = NativeVisualRuntime.Pack.registryContentSHA256(baseline)
        XCTAssertEqual(baselineHash, NativeVisualRuntime.Pack.registryContentSHA256(baseline))

        let changedPixels = NativeVisualRuntime.Entry(
            key: first.key,
            asset: try asset(commands: [
                .init(x: 0, y: 0, width: 1, height: 1, rgba: 0xffffffff)
            ]))
        XCTAssertNotEqual(
            baselineHash,
            NativeVisualRuntime.Pack.registryContentSHA256(Registry(assets: [changedPixels]))
        )
        XCTAssertNotEqual(
            baselineHash,
            NativeVisualRuntime.Pack.registryContentSHA256(
                Registry(assets: [first], explicitlyUnsupportedIDs: ["new-id"])
            )
        )
        XCTAssertNotEqual(
            baselineHash,
            NativeVisualRuntime.Pack.registryContentSHA256(
                Registry(pipelineVersion: "relabelled-pipeline", assets: [first])
            )
        )
    }
}
