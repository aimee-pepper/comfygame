import SwiftUI

/// The whole world at a glance, beside the movement arrows and above the portal/action column.
///
/// Three states, and the third is the one that earns it (decisions-session-13 §4): **explored**,
/// **unexplored**, and **nothing there**. Knowing an area is empty is as useful as knowing it's
/// unseen — it's what makes a big map navigable instead of tedious, because it tells you where not
/// to walk.
struct MinimapView: View {
    let run: WorldRun
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Canvas { context, size in
            let side = min(size.width / CGFloat(run.map.width),
                           size.height / CGFloat(run.map.height))
            let inset = CGPoint(x: (size.width - side * CGFloat(run.map.width)) / 2,
                                y: (size.height - side * CGFloat(run.map.height)) / 2)

            for point in run.map.allPoints {
                let tile = run.map[point]
                let rect = CGRect(x: inset.x + CGFloat(point.x) * side,
                                  y: inset.y + CGFloat(point.y) * side,
                                  width: side, height: side)
                let appearance: MinimapTerrainStyle.Appearance = colorScheme == .dark ? .dark : .light
                context.fill(Path(rect), with: .color(
                    MinimapTerrainStyle.resolve(tile: tile, appearance: appearance).fill.color))
            }

            // Where you are. Landmark glyphs draw over this marker so the entry portal remains
            // visible even while you're standing on it.
            let you = CGRect(x: inset.x + CGFloat(run.playerPosition.x) * side - side * 0.5,
                             y: inset.y + CGFloat(run.playerPosition.y) * side - side * 0.5,
                             width: side * 2, height: side * 2)
            context.fill(Path(ellipseIn: you), with: .color(.accentColor))

            // POIs are exploration knowledge. Rendering never grants discovery through fog.
            for point in run.map.allPoints {
                if let marker = MinimapDisclosure.marker(at: point, in: run) {
                    draw(marker.rawValue, at: point, side: side, inset: inset, context: &context)
                }
            }
        } symbols: {
            Image(systemName: "arrow.down.left.circle.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.blue)
                .tag("portal")
            Image(systemName: "doc.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.purple)
                .tag("page")
            Image(systemName: "crown.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.orange)
                .tag("apex")
            Image(systemName: "building.columns.fill").font(.system(size: 9, weight: .bold)).foregroundStyle(.brown).tag("site")
            Image(systemName: "cube.fill").font(.system(size: 8, weight: .bold)).foregroundStyle(.teal).tag("resource")
            Image(systemName: "shippingbox.fill").font(.system(size: 8, weight: .bold)).foregroundStyle(.yellow).tag("item")
            Image(systemName: "person.fill").font(.system(size: 9, weight: .bold)).foregroundStyle(.green).tag("traveller")
            Image(systemName: "pawprint.fill").font(.system(size: 9, weight: .bold)).foregroundStyle(.red).tag("encounter")
            Image(systemName: "lock.fill").font(.system(size: 8, weight: .bold)).foregroundStyle(.purple).tag("cache")
            Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 8, weight: .bold)).foregroundStyle(.orange).tag("hazard")
        }
        .aspectRatio(1, contentMode: .fit)
        .background(Color.black)
        .overlay {
            Rectangle().stroke(PixelUITheme.edge, lineWidth: 2)
        }
        .accessibilityLabel("Map overview")
        .accessibilityIdentifier("world.minimap")
    }

    private func draw(_ symbol: String, at point: GridPoint, side: CGFloat,
                      inset: CGPoint, context: inout GraphicsContext) {
        let centre = CGPoint(x: inset.x + (CGFloat(point.x) + 0.5) * side,
                             y: inset.y + (CGFloat(point.y) + 0.5) * side)
        guard let marker = context.resolveSymbol(id: symbol) else { return }
        context.draw(marker, at: centre)
    }

}

/// Pure minimap terrain presentation. Gameplay and disclosure own whether a tile is remembered;
/// this resolver only turns that already-sanitized fact into an opaque symbolic fill.
enum MinimapTerrainStyle {
    enum Appearance: CaseIterable { case light, dark }
    enum TerrainClass: CaseIterable {
        case hidden, crumbled, firmGround, looseGround, shallowWater, deepWater, ice, lowCover,
             tallGrowth, chasm
    }

    struct Fill: Equatable {
        let red: UInt8
        let green: UInt8
        let blue: UInt8
        let alpha: UInt8

        var color: Color {
            Color(red: Double(red) / 255, green: Double(green) / 255,
                  blue: Double(blue) / 255, opacity: Double(alpha) / 255)
        }

        var luminance: Int { (Int(red) * 54 + Int(green) * 183 + Int(blue) * 19) / 256 }
    }

    struct Resolution: Equatable {
        let terrainClass: TerrainClass
        let fill: Fill
    }

    static func resolve(tile: Tile, appearance: Appearance) -> Resolution {
        guard tile.isRevealed else { return resolution(.hidden, appearance: appearance) }
        guard !tile.isCrumbled else { return resolution(.crumbled, appearance: appearance) }
        let terrainClass: TerrainClass = switch tile.ground {
        case .stone, .rubble: .firmGround
        case .soil, .sand, .ash, .mud: .looseGround
        case .water: .shallowWater
        case .deepWater: .deepWater
        case .ice: .ice
        case .groundcover: .lowCover
        case .growth: .tallGrowth
        case .chasm: .chasm
        }
        return resolution(terrainClass, appearance: appearance)
    }

    private static func resolution(_ terrainClass: TerrainClass,
                                   appearance: Appearance) -> Resolution {
        let fill: Fill = switch (terrainClass, appearance) {
        case (.hidden, _): .init(red: 0, green: 0, blue: 0, alpha: 255)
        case (.crumbled, .dark): .init(red: 79, green: 74, blue: 84, alpha: 255)
        case (.crumbled, .light): .init(red: 133, green: 128, blue: 139, alpha: 255)
        case (.firmGround, .dark): .init(red: 82, green: 87, blue: 88, alpha: 255)
        case (.firmGround, .light): .init(red: 166, green: 169, blue: 165, alpha: 255)
        case (.looseGround, .dark): .init(red: 105, green: 78, blue: 56, alpha: 255)
        case (.looseGround, .light): .init(red: 181, green: 148, blue: 105, alpha: 255)
        case (.shallowWater, .dark): .init(red: 43, green: 105, blue: 119, alpha: 255)
        case (.shallowWater, .light): .init(red: 91, green: 157, blue: 169, alpha: 255)
        case (.deepWater, .dark): .init(red: 24, green: 67, blue: 88, alpha: 255)
        case (.deepWater, .light): .init(red: 56, green: 112, blue: 139, alpha: 255)
        case (.ice, .dark): .init(red: 91, green: 139, blue: 151, alpha: 255)
        case (.ice, .light): .init(red: 170, green: 211, blue: 215, alpha: 255)
        case (.lowCover, .dark): .init(red: 65, green: 104, blue: 61, alpha: 255)
        case (.lowCover, .light): .init(red: 124, green: 163, blue: 99, alpha: 255)
        case (.tallGrowth, .dark): .init(red: 39, green: 82, blue: 49, alpha: 255)
        case (.tallGrowth, .light): .init(red: 82, green: 137, blue: 77, alpha: 255)
        case (.chasm, .dark): .init(red: 30, green: 34, blue: 47, alpha: 255)
        case (.chasm, .light): .init(red: 91, green: 96, blue: 112, alpha: 255)
        }
        return Resolution(terrainClass: terrainClass, fill: fill)
    }
}

enum MinimapDisclosure {
    enum Marker: String, CaseIterable { case portal, page, apex, site, resource, item, traveller, encounter, cache, hazard }

    static func marker(for tile: Tile, enemy: WorldEnemy?) -> Marker? {
        guard tile.isRevealed else { return nil }
        if let enemy { return enemy.isApex ? .apex : .encounter }
        return switch tile.content {
        case .empty: nil
        case .portal: .portal
        case .diaryPage, .foundWriting: .page
        case .site: .site
        case .node, .wildDrop: .resource
        case .item: .item
        case .traveller: .traveller
        case .lockedCache: .cache
        case .hazard: .hazard
        }
    }

    static func marker(at point: GridPoint, in run: WorldRun) -> Marker? {
        let visibleEnemy = run.enemies.first {
            $0.position == point && WorldRules.isCurrentlyVisible($0, in: run)
        }
        return marker(for: run.map[point], enemy: visibleEnemy)
    }
}
