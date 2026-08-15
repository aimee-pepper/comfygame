import CoreGraphics
import SwiftUI
import UIKit

/// Compact named-person identity shared by Party and Library.
///
/// Only an exact persisted/live `TravellerID` enters the immutable pack. Binder, Quill, generated
/// companions, unknown IDs, missing resources and validation failures retain the supplied SF
/// fallback; visible names and accessibility remain owned by the surrounding screen.
struct NamedCharacterPixelIdentity: View {
    let travellerID: TravellerID?
    let fallbackSystemIcon: String
    let fallbackColor: Color

    private static let adapter: any NamedCharacterVisualProviding =
        NamedCharacterVisualAdapter.live()

    var body: some View {
        Group {
            if let travellerID,
               let asset = Self.adapter.cameoAsset(for: travellerID),
               let image = Self.image(from: asset) {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
            } else {
                Image(systemName: fallbackSystemIcon)
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(fallbackColor)
            }
        }
        .accessibilityHidden(true)
    }

    private static func image(from asset: NativeVisualRuntime.GeneratedPixelAsset) -> UIImage? {
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

/// Top-down named-person identity for the explorable map. Facing is presentation state only;
/// identity always comes from the persisted `TravellerID`, never display copy or array position.
struct NamedCharacterMapPixelIdentity: View {
    let travellerID: TravellerID
    let facing: NativeVisualRuntime.MapFacing
    let fallbackSystemIcon: String
    let fallbackColor: Color

    private static let adapter: any NamedCharacterVisualProviding =
        NamedCharacterVisualAdapter.live()

    var body: some View {
        Group {
            if let asset = Self.adapter.mapSpriteAsset(for: travellerID, facing: facing),
               let image = Self.image(from: asset) {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
            } else {
                Image(systemName: fallbackSystemIcon)
                    .foregroundStyle(fallbackColor)
            }
        }
        .accessibilityHidden(true)
    }

    private static func image(from asset: NativeVisualRuntime.GeneratedPixelAsset) -> UIImage? {
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
