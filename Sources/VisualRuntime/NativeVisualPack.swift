import Foundation

extension NativeVisualRuntime {
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

            manifestSHA256 = registry.manifestSHA256
            pipelineVersion = registry.pipelineVersion
            canvasWidth = registry.canvasWidth
            canvasHeight = registry.canvasHeight
            assetsByKey = indexed
            self.unsupported = unsupported
        }

        func asset(for key: GeneratedVisualKey) -> GeneratedPixelAsset? { assetsByKey[key] }
        func explicitlyUnsupported(_ catalogueID: String) -> Bool {
            unsupported.contains(catalogueID)
        }
    }
}
