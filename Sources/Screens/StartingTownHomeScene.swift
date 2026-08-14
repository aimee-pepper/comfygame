import SwiftUI
import UIKit

enum StartingTownHomeRules {
    struct Hotspot: Identifiable, Hashable, Sendable, Codable {
        let id: String
        let label: String
        let route: String
        let x: Double
        let y: Double
        let width: Double
        let height: Double

        var appRoute: AppRoute? { AppRoute(rawValue: route) }
        var point: CGPoint { CGPoint(x: x + width / 2, y: y + height / 2) }
        var size: CGSize { CGSize(width: width, height: height) }
    }

    struct Scene: Hashable, Sendable, Codable {
        let schemaVersion: Int
        let assetName: String
        let pixelWidth: Int
        let pixelHeight: Int
        let sha256: String
        let hotspots: [Hotspot]
    }

    static let manifestName = "starting-town-home-v1"
    static let assetName = "town-starting-home-v1"
    static let authoredAssetSHA256 = "f4ca74c5c03b38f303ed921d7da95d06d154348211f64124028af42eaf379f63"

    static func load(manifestURL: URL, assetURL: URL) -> Scene? {
        guard let data = try? Data(contentsOf: manifestURL),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              Set(object.keys) == Set(["schemaVersion", "assetName", "pixelWidth", "pixelHeight", "sha256", "hotspots"]),
              let decoded = try? JSONDecoder().decode(Scene.self, from: data),
              decoded.schemaVersion == 1,
              decoded.assetName == assetName,
              decoded.pixelWidth == 1122, decoded.pixelHeight == 1402,
              decoded.sha256.range(of: "^[0-9a-f]{64}$", options: .regularExpression) != nil,
              decoded.sha256 == authoredAssetSHA256,
              let image = UIImage(contentsOfFile: assetURL.path),
              image.cgImage?.width == decoded.pixelWidth,
              image.cgImage?.height == decoded.pixelHeight,
              decoded.hotspots.map(\.id) == ["writingDesk", "workshop", "storehouse", "essenceSpring", "firepit"],
              decoded.hotspots.map(\.route) == ["writingDesk", "workshop", "storehouse", "essenceSpring", "firepit"],
              Set(decoded.hotspots.map(\.id)).count == decoded.hotspots.count,
              decoded.hotspots.allSatisfy({ hotspot in
                  hotspot.appRoute != nil && hotspot.x >= 0 && hotspot.y >= 0 &&
                  hotspot.width > 0 && hotspot.height > 0 &&
                  hotspot.x + hotspot.width <= 1 && hotspot.y + hotspot.height <= 1
              }) else { return nil }
        return decoded
    }

    static func renderedImageRect(imageSize: CGSize, in containerSize: CGSize) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0,
              containerSize.width > 0, containerSize.height > 0 else { return .zero }
        // This is authored as the complete Home page, not as a card inside the town viewport.
        // Map its full normalized canvas onto the full available page so no authored edge is
        // cropped and no unexplained letterbox/card gutter is introduced around it.
        return CGRect(origin: .zero, size: containerSize)
    }

    static func hotspotRect(_ hotspot: Hotspot, imageRect: CGRect,
                            containerSize: CGSize) -> CGRect {
        let width = min(containerSize.width, max(54, imageRect.width * hotspot.size.width))
        let height = min(containerSize.height, max(44, imageRect.height * hotspot.size.height))
        let proposed = CGPoint(x: imageRect.minX + imageRect.width * hotspot.point.x,
                               y: imageRect.minY + imageRect.height * hotspot.point.y)
        let center = CGPoint(x: min(containerSize.width - width / 2, max(width / 2, proposed.x)),
                             y: min(containerSize.height - height / 2, max(height / 2, proposed.y)))
        return CGRect(x: center.x - width / 2, y: center.y - height / 2,
                      width: width, height: height)
    }
}

@MainActor enum StartingTownHomeResource {
    private static let cache = NSCache<NSString, UIImage>()

    static func scene() -> (definition: StartingTownHomeRules.Scene, image: UIImage)? {
        guard let manifestURL = Bundle.main.url(forResource: StartingTownHomeRules.manifestName,
                                                withExtension: "json"),
              let assetURL = Bundle.main.url(forResource: StartingTownHomeRules.assetName,
                                             withExtension: "png"),
              let definition = StartingTownHomeRules.load(manifestURL: manifestURL, assetURL: assetURL),
              let image = image(named: definition.assetName) else { return nil }
        return (definition, image)
    }

    private static func image(named name: String) -> UIImage? {
        if let image = cache.object(forKey: name as NSString) { return image }
        guard let path = Bundle.main.path(forResource: name, ofType: "png"),
              let image = UIImage(contentsOfFile: path) else { return nil }
        cache.setObject(image, forKey: name as NSString,
                        cost: Int(image.size.width * image.scale * image.size.height * image.scale * 4))
        return image
    }
}

struct StartingTownHomeScene: View {
    let scene: (definition: StartingTownHomeRules.Scene, image: UIImage)
    let openedRoute: (AppRoute) -> Void

    var body: some View {
        GeometryReader { geometry in
            let imageRect = StartingTownHomeRules.renderedImageRect(
                imageSize: CGSize(width: scene.definition.pixelWidth,
                                  height: scene.definition.pixelHeight),
                in: geometry.size)
            ZStack {
                Image(uiImage: scene.image)
                    .resizable()
                    .interpolation(.none)
                    .frame(width: imageRect.width, height: imageRect.height)
                    .position(x: imageRect.midX, y: imageRect.midY)
                    .allowsHitTesting(false)

                ForEach(scene.definition.hotspots) { hotspot in
                    if let route = hotspot.appRoute {
                        let hitRect = StartingTownHomeRules.hotspotRect(
                            hotspot, imageRect: imageRect, containerSize: geometry.size)
                        NavigationLink(value: route) {
                            ZStack {
                                Color.clear
                                TownHotspotSign(title: hotspot.label)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("base-town-\(route.rawValue)")
                        .simultaneousGesture(TapGesture().onEnded { openedRoute(route) })
                        .zIndex(1)
                        .frame(width: hitRect.width, height: hitRect.height)
                        .position(x: hitRect.midX, y: hitRect.midY)
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
        }
        .clipped()
    }
}

private struct TownHotspotSign: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color.black.opacity(0.78), in: RoundedRectangle(cornerRadius: 5, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .stroke(Color(red: 0.91, green: 0.84, blue: 0.68).opacity(0.92), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.45), radius: 2, y: 1)
    }
}
