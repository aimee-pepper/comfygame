import SwiftUI

/// The whole world at a glance, beside the movement arrows and above the portal/action column.
///
/// Three states, and the third is the one that earns it (decisions-session-13 §4): **explored**,
/// **unexplored**, and **nothing there**. Knowing an area is empty is as useful as knowing it's
/// unseen — it's what makes a big map navigable instead of tedious, because it tells you where not
/// to walk.
struct MinimapView: View {
    let run: WorldRun

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
                context.fill(Path(rect), with: .color(colour(for: tile)))
            }

            // Where you are. Landmark glyphs draw over this marker so the entry portal remains
            // visible even while you're standing on it.
            let you = CGRect(x: inset.x + CGFloat(run.playerPosition.x) * side - side * 0.5,
                             y: inset.y + CGFloat(run.playerPosition.y) * side - side * 0.5,
                             width: side * 2, height: side * 2)
            context.fill(Path(ellipseIn: you), with: .color(.accentColor))

            // These are navigation promises, not discoveries: the minimap always tells you where
            // the way home, the writing, and the world's singular apex are.
            for point in run.map.allPoints {
                switch run.map[point].content {
                case .portal:
                    draw("portal", at: point, side: side, inset: inset, context: &context)
                case .diaryPage:
                    draw("page", at: point, side: side, inset: inset, context: &context)
                case .foundWriting:
                    draw("page", at: point, side: side, inset: inset, context: &context)
                default:
                    break
                }
            }
            for enemy in run.enemies where enemy.isApex {
                draw("apex", at: enemy.position, side: side, inset: inset, context: &context)
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
        }
        .frame(width: 112, height: 112)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.primary.opacity(0.08))
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

    private func colour(for tile: Tile) -> Color {
        guard tile.isRevealed else { return Color(.systemFill) }        // unexplored
        if tile.isCrumbled { return .clear }                            // gone
        switch tile.content {
        case .empty:
            // Explored and empty — but *what* it's made of still matters when you're deciding
            // where to walk, so water and cover read differently from bare ground.
            return switch tile.ground {
            case .deepWater, .water, .ice: Color.blue.opacity(0.35)
            // Cover you can't see past reads stronger than cover you can — on a minimap, "where
            // are my sightlines" is most of what you're asking.
            case .growth, .rubble: Color.green.opacity(0.30)
            case .groundcover: Color.green.opacity(0.15)
            case .mud: Color.brown.opacity(0.40)
            default: Palette.mapFloor.opacity(0.3)
            }
        case .hazard: return .orange.opacity(0.7)
        case .portal: return .blue.opacity(0.8)
        default: return Palette.mapFloor.opacity(0.95)                  // explored, something here
        }
    }
}
