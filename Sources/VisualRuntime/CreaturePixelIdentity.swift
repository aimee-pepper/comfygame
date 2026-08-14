import SwiftUI

/// A deliberately small procedural identity, not final creature art. The body plan owns the axial
/// silhouette; wings/fins/legs and the head feature layer independently, matching the persisted
/// morphology contract instead of collapsing every animal into one SF Symbol.
struct CreaturePixelIdentity: View {
    let traits: CreatureTraits?
    let fallbackSystemIcon: String

    var body: some View {
        if let traits {
            Canvas { context, size in
                let scale = min(size.width, size.height) / 16
                let origin = CGPoint(x: (size.width - scale * 16) / 2,
                                     y: (size.height - scale * 16) / 2)
                for cell in CreaturePixelSilhouette.cells(for: traits) {
                    let rect = CGRect(x: origin.x + CGFloat(cell.x) * scale,
                                      y: origin.y + CGFloat(cell.y) * scale,
                                      width: CGFloat(cell.width) * scale,
                                      height: CGFloat(cell.height) * scale)
                    context.fill(Path(rect), with: .color(cell.layer == .accent ? .orange : .primary))
                }
            }
        } else {
            Image(systemName: fallbackSystemIcon)
        }
    }
}

enum CreaturePixelSilhouette {
    enum Layer: Equatable { case body, accent }

    struct Cell: Equatable {
        let x: Int
        let y: Int
        let width: Int
        let height: Int
        let layer: Layer

        init(_ x: Int, _ y: Int, _ width: Int = 1, _ height: Int = 1,
             _ layer: Layer = .body) {
            self.x = x; self.y = y; self.width = width; self.height = height; self.layer = layer
        }
    }

    static func cells(for traits: CreatureTraits) -> [Cell] {
        var cells: [Cell] = switch traits.bodyPlan {
        case .quadruped:
            [Cell(3, 7, 8, 4), Cell(10, 6, 3, 3), Cell(4, 10, 1, 4),
             Cell(9, 10, 1, 4), Cell(2, 8, 2, 1)]
        case .biped:
            [Cell(6, 5, 5, 6), Cell(7, 3, 3, 3), Cell(6, 10, 1, 4), Cell(10, 10, 1, 4)]
        case .serpentine:
            [Cell(2, 11, 4, 2), Cell(5, 9, 2, 3), Cell(6, 7, 4, 2),
             Cell(9, 8, 2, 3), Cell(10, 10, 4, 2), Cell(12, 7, 3, 3)]
        case .segmented:
            [Cell(2, 8, 3, 4), Cell(5, 7, 3, 4), Cell(8, 8, 3, 4), Cell(11, 7, 3, 4)]
        case .radial:
            [Cell(5, 5, 6, 6), Cell(2, 7, 3, 2), Cell(11, 7, 3, 2),
             Cell(7, 2, 2, 3), Cell(7, 11, 2, 3)]
        case .piscine:
            [Cell(4, 6, 8, 5), Cell(2, 5, 2, 7), Cell(12, 7, 2, 2)]
        case .amorphous:
            [Cell(3, 8, 10, 4), Cell(5, 5, 6, 4), Cell(4, 11, 2, 2), Cell(10, 11, 2, 2)]
        }

        addAppendages(traits, to: &cells)
        addCranialFeature(traits, to: &cells)
        return cells
    }

    private static func addAppendages(_ traits: CreatureTraits, to cells: inout [Cell]) {
        switch traits.appendages.type {
        case .membrane:
            cells += [Cell(2, 3, 5, 3, .accent), Cell(10, 3, 5, 3, .accent),
                      Cell(3, 2, 2, 1, .accent), Cell(13, 2, 1, 1, .accent)]
        case .feathered:
            cells += [Cell(1, 4, 5, 1, .accent), Cell(2, 3, 4, 1, .accent),
                      Cell(11, 4, 4, 1, .accent), Cell(12, 3, 3, 1, .accent)]
        case .finned:
            cells += [Cell(6, 3, 3, 2, .accent), Cell(6, 12, 3, 2, .accent)]
        case .limbed:
            if traits.bodyPlan == .serpentine {
                cells += [Cell(5, 11, 1, 3, .accent), Cell(10, 10, 1, 3, .accent)]
            }
        case .none:
            break
        }
    }

    private static func addCranialFeature(_ traits: CreatureTraits, to cells: inout [Cell]) {
        switch traits.cranialFeature {
        case .none: break
        case .longEars:
            cells += [Cell(10, 2, 1, 4, .accent), Cell(12, 1, 1, 5, .accent)]
        case .horns:
            cells += [Cell(10, 3, 1, 3, .accent), Cell(13, 3, 1, 3, .accent)]
        case .crest:
            cells += [Cell(11, 3, 1, 3, .accent), Cell(12, 2, 1, 4, .accent),
                      Cell(13, 4, 1, 2, .accent)]
        case .sensoryFan:
            cells += [Cell(10, 2, 4, 1, .accent), Cell(9, 3, 5, 1, .accent)]
        }
    }
}
