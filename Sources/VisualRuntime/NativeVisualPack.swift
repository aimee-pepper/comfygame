import Foundation

extension NativeVisualRuntime {
    struct ArtPackIdentityV1: Equatable, Hashable, Sendable {
        var packID: String
        var manifestSHA256: String
        var registryContentSHA256: String
    }

    struct GeneratedFinalArtAssetReceiptV1: Equatable, Sendable {
        var key: GeneratedVisualKey
        var sourceRasterSHA256: String
        var productionDecodedRGBASHA256: String
    }

    struct GeneratedFinalArtReceiptV1: Equatable, Sendable {
        var pack: ArtPackIdentityV1
        var provider: String
        var generationReceiptSHA256: String
        var aimeeApprovalReceiptSHA256: String
        var assets: [GeneratedFinalArtAssetReceiptV1]
    }

    struct AimeeAuthoredFinalArtAssetReceiptV1: Equatable, Sendable {
        var key: GeneratedVisualKey
        var semanticSourcePath: String
        var sourceFileSHA256: String
        var sourceDecodedRGBASHA256: String
        var productionDecodedRGBASHA256: String
    }

    struct AimeeAuthoredFinalArtReceiptV1: Equatable, Sendable {
        var pack: ArtPackIdentityV1
        var author: String
        var aimeeAuthorshipReceiptSHA256: String
        var exporterID: String
        var exporterCheckSHA256: String
        var assets: [AimeeAuthoredFinalArtAssetReceiptV1]
    }

    indirect enum ArtProductionProvenanceV1: Equatable, Sendable {
        /// Exact frozen functional geometry. It is never final art and cannot gain another ID.
        case functionalPlaceholder(ArtPackIdentityV1)
        /// New final-product pixels created by an agent must use this authority.
        case imageGeneratedFinal(GeneratedFinalArtReceiptV1)
        /// Final art personally supplied or hand-authored by Aimee remains truthfully human-authored.
        case aimeeAuthoredFinal(AimeeAuthoredFinalArtReceiptV1)
        /// Exact pre-guard compatibility boundaries; their complete runtime contents are frozen.
        case frozenLegacy(ArtPackIdentityV1)
        case frozenCompatibilityComposite(ArtPackIdentityV1)
#if DEBUG
        /// Unit-test fixtures only. This case does not exist in a Release product.
        case testOnly
#endif
    }

    struct GeneratedVisualKey: Codable, Equatable, Hashable, Sendable {
        var catalogueID: String
        var identified: Bool
    }

    struct Entry: Codable, Equatable, Sendable {
        var key: GeneratedVisualKey
        var asset: GeneratedPixelAsset
    }

    /// Immutable generated-pack input. Registries are value descriptions that may be cached and
    /// read from any actor; conformers must therefore expose only `Sendable` state.
    protocol Registry: Sendable {
        var manifestSHA256: String { get }
        var pipelineVersion: String { get }
        var artProvenance: ArtProductionProvenanceV1 { get }
        var canvasWidth: UInt8 { get }
        var canvasHeight: UInt8 { get }
        var assets: [Entry] { get }
        var explicitlyUnsupportedIDs: [String] { get }
    }

    struct Pack: Sendable {
        let manifestSHA256: String
        let pipelineVersion: String
        let canvasWidth: UInt8
        let canvasHeight: UInt8
        private let assetsByKey: [GeneratedVisualKey: GeneratedPixelAsset]
        private let unsupported: Set<String>

        init(registry: any Registry, requiredCatalogueIDs: Set<String>) throws {
            guard registry.manifestSHA256.range(
                of: "^[0-9a-f]{64}$", options: .regularExpression) != nil,
                  !registry.pipelineVersion.isEmpty,
                  registry.canvasWidth > 0, registry.canvasHeight > 0 else {
                throw ValidationError.invalidManifestMetadata
            }
            var indexed: [GeneratedVisualKey: GeneratedPixelAsset] = [:]
            for entry in registry.assets {
                guard indexed[entry.key] == nil else {
                    throw ValidationError.duplicateKey(entry.key)
                }
                guard entry.asset.width == registry.canvasWidth,
                      entry.asset.height == registry.canvasHeight else {
                    throw ValidationError.inconsistentCanvas
                }
                try validate(entry.asset)
                indexed[entry.key] = entry.asset
            }
            let unsupportedList = registry.explicitlyUnsupportedIDs
            let unsupported = Set(unsupportedList)
            guard unsupported.count == unsupportedList.count else {
                let duplicate = unsupportedList.first { id in
                    unsupportedList.filter { $0 == id }.count > 1
                } ?? ""
                throw ValidationError.duplicateUnsupportedID(duplicate)
            }
            let assetIDs = Set(indexed.keys.map(\.catalogueID))
            if let collision = assetIDs.intersection(unsupported).sorted().first {
                throw ValidationError.assetAlsoUnsupported(collision)
            }
            let covered = assetIDs.union(unsupported)
            let missing = requiredCatalogueIDs.subtracting(covered).sorted()
            guard missing.isEmpty else { throw ValidationError.incompleteCoverage(missing) }
            let unexpected = covered.subtracting(requiredCatalogueIDs).sorted()
            guard unexpected.isEmpty else { throw ValidationError.unexpectedCoverage(unexpected) }
            try Self.validateArtProvenance(
                registry.artProvenance,
                registryManifestSHA256: registry.manifestSHA256,
                registryContentSHA256: Self.registryContentSHA256(registry),
                indexedAssets: indexed
            )

            manifestSHA256 = registry.manifestSHA256
            pipelineVersion = registry.pipelineVersion
            canvasWidth = registry.canvasWidth
            canvasHeight = registry.canvasHeight
            assetsByKey = indexed
            self.unsupported = unsupported
        }

        // These are compatibility receipts, not extensible naming conventions. Any key, command,
        // pixel hash, unsupported ID, canvas, or manifest change alters registryContentSHA256 and
        // therefore fails closed until Aimee approves a new generated-art receipt.
        private static let frozenFunctionalPlaceholders: Set<ArtPackIdentityV1> = [
            .init(
                packID: "catalogue-consumables-placeholder-v1",
                manifestSHA256: "70a6d7c6c71f93c9c8488969439aed051e35a47a3579d3c219d556c160fee4a9",
                registryContentSHA256: "54566ac920549ee0b75fe1a2662ccbd4548ce2f507dde5142ea8eaff882b4481"
            ),
        ]
        private static let frozenLegacyPacks: Set<ArtPackIdentityV1> = [
            .init(
                packID: "mob-gear-sprites-v1",
                manifestSHA256: "eff8f3bdb8d50fa15242ee75aea457f674c75f9e3af1640e5dbd598ebe9f87d4",
                registryContentSHA256: "1edc9814e108be9f1ee00d2f393b71331b21ad232de538c760c784969a1be0fe"
            ),
        ]
        private static let frozenCompatibilityComposites: Set<ArtPackIdentityV1> = [
            .init(
                packID: "catalogue-item-compatibility-composite-v1",
                manifestSHA256: "eff8f3bdb8d50fa15242ee75aea457f674c75f9e3af1640e5dbd598ebe9f87d4",
                registryContentSHA256: "17f7d5428b3bc910c7f0700aea5d64f925cd53a9df7108746ef0a5aa321dfc20"
            ),
        ]

        /// Empty by design until a real image-generation result is bound to its exact pixels and
        /// Aimee approves that exact receipt fingerprint in source review.
        private static let approvedGeneratedFinalReceiptSHA256: Set<String> = []
        /// Separate domain and empty allowlist: generated-art approval can never authorize Aimee-authored art.
        private static let approvedAimeeAuthoredFinalReceiptSHA256: Set<String> = []

        private static func validateArtProvenance(
            _ provenance: ArtProductionProvenanceV1,
            registryManifestSHA256: String,
            registryContentSHA256: String,
            indexedAssets: [GeneratedVisualKey: GeneratedPixelAsset]
        ) throws {
            switch provenance {
            case let .functionalPlaceholder(identity):
                try validateIdentity(identity, manifest: registryManifestSHA256,
                                     content: registryContentSHA256)
                guard frozenFunctionalPlaceholders.contains(identity) else {
                    throw ValidationError.unapprovedFunctionalPlaceholder(identity.packID)
                }
            case let .imageGeneratedFinal(receipt):
                try validateIdentity(receipt.pack, manifest: registryManifestSHA256,
                                     content: registryContentSHA256)
                guard receipt.provider == "openai-imagegen" else {
                    throw ValidationError.finalArtMustUseImageGeneration(receipt.provider)
                }
                guard isCanonicalSHA256(receipt.generationReceiptSHA256),
                      isCanonicalSHA256(receipt.aimeeApprovalReceiptSHA256),
                      !receipt.assets.isEmpty else {
                    throw ValidationError.invalidGeneratedFinalArtReceipt
                }
                let sortedReceipts = receipt.assets.sorted { canonicalKey($0.key) < canonicalKey($1.key) }
                guard Set(sortedReceipts.map(\.key)).count == sortedReceipts.count,
                      Set(sortedReceipts.map(\.key)) == Set(indexedAssets.keys) else {
                    throw ValidationError.generatedFinalAssetReceiptMismatch
                }
                for assetReceipt in sortedReceipts {
                    guard isCanonicalSHA256(assetReceipt.sourceRasterSHA256),
                          isCanonicalSHA256(assetReceipt.productionDecodedRGBASHA256),
                          indexedAssets[assetReceipt.key]?.decodedRGBASHA256
                            == assetReceipt.productionDecodedRGBASHA256 else {
                        throw ValidationError.generatedFinalAssetReceiptMismatch
                    }
                }
                let fingerprint = generatedFinalReceiptSHA256(receipt)
                guard approvedGeneratedFinalReceiptSHA256.contains(fingerprint) else {
                    throw ValidationError.unapprovedGeneratedFinalArt(receipt.pack.packID)
                }
            case let .aimeeAuthoredFinal(receipt):
                try validateIdentity(receipt.pack, manifest: registryManifestSHA256,
                                     content: registryContentSHA256)
                guard receipt.author == "aimee-pepper",
                      isCanonicalSHA256(receipt.aimeeAuthorshipReceiptSHA256),
                      isCanonicalSHA256(receipt.exporterCheckSHA256),
                      isSemanticExporterID(receipt.exporterID),
                      !receipt.assets.isEmpty else {
                    throw ValidationError.invalidAimeeAuthoredFinalArtReceipt
                }
                let sortedReceipts = receipt.assets.sorted {
                    canonicalKey($0.key) < canonicalKey($1.key)
                }
                guard Set(sortedReceipts.map(\.key)).count == sortedReceipts.count,
                      Set(sortedReceipts.map(\.key)) == Set(indexedAssets.keys) else {
                    throw ValidationError.aimeeAuthoredFinalAssetReceiptMismatch
                }
                for assetReceipt in sortedReceipts {
                    guard isSemanticAimeeSourcePath(assetReceipt.semanticSourcePath),
                          isCanonicalSHA256(assetReceipt.sourceFileSHA256),
                          isCanonicalSHA256(assetReceipt.sourceDecodedRGBASHA256),
                          isCanonicalSHA256(assetReceipt.productionDecodedRGBASHA256),
                          indexedAssets[assetReceipt.key]?.decodedRGBASHA256
                            == assetReceipt.productionDecodedRGBASHA256 else {
                        throw ValidationError.aimeeAuthoredFinalAssetReceiptMismatch
                    }
                }
                let fingerprint = aimeeAuthoredFinalReceiptSHA256(receipt)
                guard approvedAimeeAuthoredFinalReceiptSHA256.contains(fingerprint) else {
                    throw ValidationError.unapprovedAimeeAuthoredFinalArt(receipt.pack.packID)
                }
            case let .frozenLegacy(identity):
                try validateIdentity(identity, manifest: registryManifestSHA256,
                                     content: registryContentSHA256)
                guard frozenLegacyPacks.contains(identity) else {
                    throw ValidationError.unapprovedLegacyArtPack(identity.packID)
                }
            case let .frozenCompatibilityComposite(identity):
                try validateIdentity(identity, manifest: registryManifestSHA256,
                                     content: registryContentSHA256)
                guard frozenCompatibilityComposites.contains(identity) else {
                    throw ValidationError.unapprovedCompatibilityPack(identity.packID)
                }
#if DEBUG
            case .testOnly:
                break
#endif
            }
        }

        private static func validateIdentity(_ identity: ArtPackIdentityV1,
                                             manifest: String, content: String) throws {
            guard !identity.packID.isEmpty,
                  isCanonicalSHA256(identity.manifestSHA256),
                  isCanonicalSHA256(identity.registryContentSHA256),
                  identity.manifestSHA256 == manifest,
                  identity.registryContentSHA256 == content else {
                throw ValidationError.artPackIdentityMismatch(identity.packID)
            }
        }

        static func registryContentSHA256(_ registry: any Registry) -> String {
            var fields = [
                "bookbinder-art-registry-content-v1",
                registry.pipelineVersion,
                String(registry.canvasWidth),
                String(registry.canvasHeight),
            ]
            for entry in registry.assets.sorted(by: {
                canonicalKey($0.key) < canonicalKey($1.key)
            }) {
                fields.append(contentsOf: [
                    entry.key.catalogueID,
                    entry.key.identified ? "identified" : "unidentified",
                    String(entry.asset.width),
                    String(entry.asset.height),
                    entry.asset.commandSHA256,
                    entry.asset.decodedRGBASHA256,
                ])
            }
            fields.append("explicitly-unsupported")
            fields.append(contentsOf: registry.explicitlyUnsupportedIDs.sorted())
            return NativeVisualRuntime.sha256(lengthPrefixed(fields))
        }

        private static func generatedFinalReceiptSHA256(
            _ receipt: GeneratedFinalArtReceiptV1
        ) -> String {
            var fields = [
                "bookbinder-generated-final-art-receipt-v1",
                receipt.pack.packID,
                receipt.pack.manifestSHA256,
                receipt.pack.registryContentSHA256,
                receipt.provider,
                receipt.generationReceiptSHA256,
                receipt.aimeeApprovalReceiptSHA256,
            ]
            for asset in receipt.assets.sorted(by: {
                canonicalKey($0.key) < canonicalKey($1.key)
            }) {
                fields.append(contentsOf: [
                    asset.key.catalogueID,
                    asset.key.identified ? "identified" : "unidentified",
                    asset.sourceRasterSHA256,
                    asset.productionDecodedRGBASHA256,
                ])
            }
            return NativeVisualRuntime.sha256(lengthPrefixed(fields))
        }

        private static func aimeeAuthoredFinalReceiptSHA256(
            _ receipt: AimeeAuthoredFinalArtReceiptV1
        ) -> String {
            var fields = [
                "bookbinder-aimee-authored-final-art-receipt-v1",
                receipt.pack.packID,
                receipt.pack.manifestSHA256,
                receipt.pack.registryContentSHA256,
                receipt.author,
                receipt.aimeeAuthorshipReceiptSHA256,
                receipt.exporterID,
                receipt.exporterCheckSHA256,
            ]
            for asset in receipt.assets.sorted(by: {
                canonicalKey($0.key) < canonicalKey($1.key)
            }) {
                fields.append(contentsOf: [
                    asset.key.catalogueID,
                    asset.key.identified ? "identified" : "unidentified",
                    asset.semanticSourcePath,
                    asset.sourceFileSHA256,
                    asset.sourceDecodedRGBASHA256,
                    asset.productionDecodedRGBASHA256,
                ])
            }
            return NativeVisualRuntime.sha256(lengthPrefixed(fields))
        }

        private static func canonicalKey(_ key: GeneratedVisualKey) -> String {
            "\(key.catalogueID.utf8.count):\(key.catalogueID):\(key.identified ? 1 : 0)"
        }

        private static func lengthPrefixed(_ fields: [String]) -> Data {
            Data(fields.flatMap { field in
                Array("\(field.utf8.count):\(field)".utf8)
            })
        }

        private static func isCanonicalSHA256(_ value: String) -> Bool {
            value.range(of: "^[0-9a-f]{64}$", options: .regularExpression) != nil
        }

        private static func isSemanticExporterID(_ value: String) -> Bool {
            !value.isEmpty
                && value.range(of: "^[a-z0-9][a-z0-9._/-]*$", options: .regularExpression) != nil
                && !value.split(separator: "/").contains("..")
        }

        private static func isSemanticAimeeSourcePath(_ value: String) -> Bool {
            guard value.hasPrefix("AssetSources/"),
                  !value.hasPrefix("/"),
                  !value.contains("\\"),
                  !value.split(separator: "/").contains(where: { $0 == "." || $0 == ".." }),
                  let filename = value.split(separator: "/").last.map(String.init),
                  filename.range(
                    of: "(?: |\\()\\d+\\)?(?=\\.[^.]+$)", options: .regularExpression
                  ) == nil else {
                return false
            }
            let stem = filename.split(separator: ".", omittingEmptySubsequences: false).first.map(String.init)
                ?? ""
            return stem.range(of: "^[0-9a-fA-F]{32,}$", options: .regularExpression) == nil
        }

        func asset(for key: GeneratedVisualKey) -> GeneratedPixelAsset? { assetsByKey[key] }
        func explicitlyUnsupported(_ catalogueID: String) -> Bool {
            unsupported.contains(catalogueID)
        }
    }
}
