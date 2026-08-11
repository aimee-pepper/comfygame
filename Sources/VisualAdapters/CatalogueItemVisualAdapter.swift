import Foundation

/// Thin catalogue boundary: generated packs own pixels; game content owns the stable item ID and
/// whether that identity has been learned. Missing, unsupported and unknown entries stay nil so
/// the caller can use its existing honest fallback.
struct CatalogueItemVisualAdapter: Sendable {
    private let pack: NativeVisualRuntime.Pack?

    init(pack: NativeVisualRuntime.Pack?) { self.pack = pack }

    func asset(for itemID: ItemID, identified: Bool) -> NativeVisualRuntime.GeneratedPixelAsset? {
        guard let pack, !pack.explicitlyUnsupported(itemID.rawValue) else { return nil }
        return pack.asset(for: .init(catalogueID: itemID.rawValue, identified: identified))
    }
}
