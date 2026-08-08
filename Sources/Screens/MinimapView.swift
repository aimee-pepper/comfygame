import SwiftUI

/// The whole world at a glance, under the movement arrows.
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

            // Where you are, drawn last so nothing sits on top of it.
            let you = CGRect(x: inset.x + CGFloat(run.playerPosition.x) * side - side * 0.5,
                             y: inset.y + CGFloat(run.playerPosition.y) * side - side * 0.5,
                             width: side * 2, height: side * 2)
            context.fill(Path(ellipseIn: you), with: .color(.accentColor))
        }
        .frame(height: 64)
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 6))
        .accessibilityLabel("Map overview")
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
            default: Palette.mapFloor.opacity(0.3)
            }
        case .hazard: return .orange.opacity(0.7)
        case .portal: return .blue.opacity(0.8)
        default: return Palette.mapFloor.opacity(0.95)                  // explored, something here
        }
    }
}
