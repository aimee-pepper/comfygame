import Foundation

/// Stable insertion point for Aimee-authored catalogue item art.
///
/// The immutable generated registry may extend this marker to conform to
/// `CatalogueItemVisualRegistryProvider`. Until then, every item keeps its existing fallback.
enum GeneratedCatalogueItemVisualRegistry {}

protocol CatalogueItemVisualRegistryProvider {
    static var registry: any NativeVisualRuntime.Registry { get }
}

extension CatalogueItemVisualAdapter {
    static func live() -> Self {
        guard let provider = GeneratedCatalogueItemVisualRegistry.self
            as? any CatalogueItemVisualRegistryProvider.Type,
              let pack = try? NativeVisualRuntime.Pack(
                registry: provider.registry,
                requiredCatalogueIDs: Set(ContentCatalog.shared.items.map(\.id.rawValue))) else {
            return .init(pack: nil)
        }
        return .init(pack: pack)
    }
}
