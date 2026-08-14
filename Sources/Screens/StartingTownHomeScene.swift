import CryptoKit
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

    static func load(manifestURL: URL, assetURL: URL) -> Scene? {
        guard let data = try? Data(contentsOf: manifestURL),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              Set(object.keys) == Set(["schemaVersion", "assetName", "pixelWidth", "pixelHeight", "sha256", "hotspots"]),
              let decoded = try? JSONDecoder().decode(Scene.self, from: data),
              decoded.schemaVersion == 1,
              decoded.assetName == assetName,
              decoded.pixelWidth == 1122, decoded.pixelHeight == 1402,
              decoded.sha256.range(of: "^[0-9a-f]{64}$", options: .regularExpression) != nil,
              let assetData = try? Data(contentsOf: assetURL),
              SHA256.hash(data: assetData).map({ String(format: "%02x", $0) }).joined() == decoded.sha256,
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

    static func sceneHeight(containerSize: CGSize, horizontalPadding: CGFloat = 24) -> CGFloat? {
        let width = max(0, containerSize.width - horizontalPadding)
        let ideal = width * CGFloat(1402) / CGFloat(1122)
        return max(0, containerSize.height - 190) >= ideal ? ideal : nil
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
            ZStack {
                Image(uiImage: scene.image)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .allowsHitTesting(false)

                ForEach(scene.definition.hotspots) { hotspot in
                    if let route = hotspot.appRoute {
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
                        .frame(width: max(54, geometry.size.width * hotspot.size.width),
                               height: max(44, geometry.size.height * hotspot.size.height))
                        .position(x: geometry.size.width * hotspot.point.x,
                                  y: geometry.size.height * hotspot.point.y)
                    }
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.16)))
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
