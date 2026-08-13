import Foundation

/// Narrow dependency supplied to Party, Library and map presentation. Consumers never parse the
/// immutable AssetLab manifest and never infer visual identity from names, callings or array order.
protocol NamedCharacterVisualProviding: Sendable {
    func cameoAsset(for travellerID: TravellerID)
        -> NativeVisualRuntime.GeneratedPixelAsset?
    func mapSpriteAsset(for travellerID: TravellerID, facing: NativeVisualRuntime.MapFacing)
        -> NativeVisualRuntime.GeneratedPixelAsset?
}

/// Game-facing adapter over one validated immutable named-character pack.
///
/// A nil pack is an intentional fail-closed configuration: existing native fallback presentation
/// remains responsible for every identity until the bundle composition root supplies the pack.
struct NamedCharacterVisualAdapter: NamedCharacterVisualProviding, Sendable {
    private let pack: NativeVisualRuntime.NamedCharacterPlaceholderPack?

    init(pack: NativeVisualRuntime.NamedCharacterPlaceholderPack?) {
        self.pack = pack
    }

    /// The only manifest-aware construction point. Build this once at app composition, then inject
    /// the adapter rather than passing bytes or registries into screens.
    static func validated(manifestData: Data) throws -> Self {
        .init(pack: try .init(manifestData: manifestData))
    }

    /// Release composition point. A missing, renamed, corrupt or drifted bundle resource is an
    /// intentional fallback-only configuration rather than a partially trusted visual pack.
    static func live(bundle: Bundle = .main) -> Self {
        // PBX displays the resource with its unique pack name but Copy Bundle Resources preserves
        // the source basename `manifest.json`. Prefer a future physically renamed resource, then
        // accept the current basename only through the same exact immutable hash validation.
        for resource in ["named-character-placeholders-v1", "manifest"] {
            guard let url = bundle.url(forResource: resource, withExtension: "json"),
                  let data = try? Data(contentsOf: url),
                  let adapter = try? validated(manifestData: data) else { continue }
            return adapter
        }
        return fallbackOnly
    }

    static let fallbackOnly = Self(pack: nil)

    func cameoAsset(for travellerID: TravellerID)
        -> NativeVisualRuntime.GeneratedPixelAsset? {
        pack?.cameo(for: travellerID)?.asset
    }

    func mapSpriteAsset(for travellerID: TravellerID, facing: NativeVisualRuntime.MapFacing)
        -> NativeVisualRuntime.GeneratedPixelAsset? {
        pack?.mapSprite(for: travellerID, facing: facing)?.asset
    }
}
