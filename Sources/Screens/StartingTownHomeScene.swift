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
    static let assetName = "town-starting-v1"
    static let authoredAssetSHA256 = "287d28f294139a6ce9c37e10602c110c10202b5ebe24c7810088b9f53c0939c3"
    static let displayAssetName = "town-starting-home-v1-phone-v2"
    static let displayPixelSize = CGSize(width: 941, height: 1672)
    static let displayAssetSHA256 = "ddc4b29ecda5428378e86aaa0dd3abe7b58dc9db7d6b956dcf4e2df708cf07f2"
    static let homeRoutes: [AppRoute] = [
        .writingDesk, .workshop, .storehouse, .essenceSpring, .firepit
    ]

    static func load(manifestURL: URL, assetURL: URL) -> Scene? {
        guard let data = try? Data(contentsOf: manifestURL),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              Set(object.keys) == Set(["schemaVersion", "assetName", "pixelWidth", "pixelHeight", "sha256", "hotspots"]),
              let decoded = try? JSONDecoder().decode(Scene.self, from: data),
              decoded.schemaVersion == 1,
              decoded.assetName == assetName,
              decoded.pixelWidth == 1408, decoded.pixelHeight == 3048,
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
        // Home shares the exact aspect-fill contract used by the other village panes: preserve
        // the authored proportions and crop only the centered overflow required to fill the
        // available page. Hotspots use this same rendered rectangle below.
        let scale = max(containerSize.width / imageSize.width,
                        containerSize.height / imageSize.height)
        let renderedSize = CGSize(width: imageSize.width * scale,
                                  height: imageSize.height * scale)
        return CGRect(x: (containerSize.width - renderedSize.width) / 2,
                      y: (containerSize.height - renderedSize.height) / 2,
                      width: renderedSize.width, height: renderedSize.height)
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
              let image = image(named: StartingTownHomeRules.displayAssetName),
              image.cgImage?.width == Int(StartingTownHomeRules.displayPixelSize.width),
              image.cgImage?.height == Int(StartingTownHomeRules.displayPixelSize.height) else { return nil }
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
    let destinationQuotes: [AppRoute: HomeDestinationQuoteV1]
    let admission: PhoneControlAdmissionV1
    let openedRoute: (AppRoute, HomeDestinationQuoteV1?) -> Void

    var body: some View {
        GeometryReader { geometry in
            let imageRect = StartingTownHomeRules.renderedImageRect(
                imageSize: StartingTownHomeRules.displayPixelSize,
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
                        Button {
                            openedRoute(route, destinationQuotes[route])
                        } label: {
                            ZStack {
                                Color.clear
                                TownHotspotSign(title: hotspot.label,
                                                subtitle: subtitle(for: hotspot.id))
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .fullFacePressFeedback("village.route.\(route.rawValue)",
                                               admission: admission)
                        .accessibilityIdentifier("base-town-\(route.rawValue)")
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

    private func subtitle(for hotspotID: String) -> String {
        switch hotspotID {
        case "writingDesk": "compose"
        case "workshop": "make"
        case "storehouse": "stored goods"
        case "essenceSpring": "refine"
        case "firepit": "gather"
        default: ""
        }
    }
}

private struct TownHotspotSign: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 1) {
            Text(title)
                .font(.custom("Tiny5", size: 9))
            Text(subtitle)
                .font(.custom("Tiny5", size: 7))
                .foregroundStyle(PixelUITheme.neutralHighlight)
        }
            .foregroundStyle(.white)
            .lineLimit(2)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(PixelUITheme.edgeDark.opacity(0.85))
            .overlay {
                Rectangle().stroke(PixelUITheme.neutralHighlight, lineWidth: 1)
            }
            .background {
                Rectangle()
                    .fill(PixelUITheme.shadow.opacity(0.6))
                    .offset(x: 3, y: 3)
            }
    }
}
