import CoreGraphics
import SwiftUI
import UIKit

/// Player-facing bridge from stable catalogue identity to an immutable generated pixel pack.
/// Missing packs, unsupported IDs and missing identified/unidentified variants retain the
/// existing explicit SF Symbol fallback.
struct CatalogueItemPixelIdentity: View {
    let itemID: ItemID?
    let identified: Bool
    let fallbackSystemIcon: String
    let fallbackColor: Color

    private static let adapter = CatalogueItemVisualAdapter.live()

    var body: some View {
        Group {
            if let itemID,
               let asset = Self.adapter.asset(for: itemID, identified: identified),
               let image = Self.image(from: asset) {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
            } else {
                Image(systemName: identified ? fallbackSystemIcon : "questionmark")
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(fallbackColor)
            }
        }
        .accessibilityHidden(true)
    }

    static func image(from asset: NativeVisualRuntime.GeneratedPixelAsset) -> UIImage? {
        guard let pixels = try? NativeVisualRuntime.decodedRGBA(
            width: asset.width, height: asset.height, commands: asset.commands),
              let provider = CGDataProvider(data: pixels as CFData),
              let image = CGImage(
                width: Int(asset.width), height: Int(asset.height),
                bitsPerComponent: 8, bitsPerPixel: 32,
                bytesPerRow: Int(asset.width) * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
                provider: provider, decode: nil,
                shouldInterpolate: false, intent: .defaultIntent) else { return nil }
        return UIImage(cgImage: image)
    }
}

/// Exact harvested-material identity. Grade, provenance and inherited properties remain text/state;
/// the central 32px silhouette is selected only by the stable material kind.
struct CraftMaterialUnitPixelIdentity: View {
    let kind: MaterialFamilyID
    let fallbackColor: Color

    var body: some View {
        Group {
            if let asset = MobGearSpriteV1Registry.mobDropAsset(for: kind),
               let image = CatalogueItemPixelIdentity.image(from: asset) {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
            } else {
                Image(systemName: kind.icon)
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(fallbackColor)
            }
        }
        .accessibilityHidden(true)
    }
}
