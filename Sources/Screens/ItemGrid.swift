import SwiftUI

enum ItemGridMetrics {
    static let columns = 6
    static let spacing: CGFloat = 4
    static let minimumCellSide: CGFloat = 44

    static func cellSide(for contentWidth: CGFloat) -> CGFloat {
        (contentWidth - CGFloat(columns - 1) * spacing) / CGFloat(columns)
    }
}

/// The shared phone grammar for owned and offered items: six graphical identities per row.
/// Names and prose belong in the detail sheet opened by a tap, not beneath every icon.
struct SixAcrossItemGrid<Data: RandomAccessCollection, ID: Hashable, Cell: View>: View {
    let data: Data
    let id: KeyPath<Data.Element, ID>
    @ViewBuilder let cell: (Data.Element) -> Cell

    private let columns = Array(
        repeating: GridItem(.flexible(minimum: ItemGridMetrics.minimumCellSide),
                            spacing: ItemGridMetrics.spacing),
        count: ItemGridMetrics.columns)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(data, id: id) { element in cell(element) }
        }
    }
}

enum ItemGridLocation: String, Sendable {
    case stored, worn, waiting, carried, offered

    var icon: String {
        switch self {
        case .stored: "archivebox.fill"
        case .worn: "figure.stand"
        case .waiting: "exclamationmark.triangle.fill"
        case .carried: "backpack.fill"
        case .offered: "sparkles"
        }
    }

    var displayName: String {
        switch self {
        case .stored: "Stored"
        case .worn: "Worn"
        case .waiting: "Waiting to sort"
        case .carried: "Carried"
        case .offered: "New loot"
        }
    }
}

struct ItemIconTile: View {
    let icon: String
    let rarity: Rarity
    let quantity: Int
    let identified: Bool
    let location: ItemGridLocation
    let accessibilityName: String
    var isSelected = false
    var isEnabled = true

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 9)
                .fill(Color(.secondarySystemGroupedBackground))
            RoundedRectangle(cornerRadius: 9)
                .strokeBorder(rarity.tint.opacity(isSelected ? 1 : 0.72),
                              style: StrokeStyle(lineWidth: isSelected ? 3 : 1.5,
                                                 dash: rarityDash))
            Image(systemName: identified ? icon : "questionmark")
                .font(.system(size: 21, weight: .semibold))
                .foregroundStyle(identified ? rarity.tint : Color.secondary)

            VStack {
                HStack {
                    Image(systemName: rarityMark)
                        .font(.system(size: 8, weight: .black))
                        .foregroundStyle(rarity.tint)
                    Spacer()
                    if quantity > 1 {
                        Text("\(quantity)")
                            .font(.system(size: 10, weight: .bold, design: .rounded).monospacedDigit())
                            .padding(.horizontal, 4).padding(.vertical, 1)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                }
                Spacer()
                HStack {
                    Spacer()
                    Image(systemName: location.icon)
                        .font(.system(size: 9, weight: .bold))
                        .padding(3)
                        .background(.ultraThinMaterial, in: Circle())
                }
            }
            .padding(4)
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(minWidth: 44, minHeight: 44)
        .contentShape(RoundedRectangle(cornerRadius: 9))
        .opacity(isEnabled ? 1 : 0.55)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var accessibilityLabel: String {
        let identity = identified ? accessibilityName : "Unknown item"
        let count = quantity > 1 ? ", quantity \(quantity)" : ""
        return "\(identity), \(rarity.displayName), \(location.displayName)\(count)"
    }

    private var rarityMark: String {
        switch rarity {
        case .common: "circle.fill"
        case .uncommon: "diamond.fill"
        case .rare: "star.fill"
        case .mythic: "sparkles"
        }
    }

    private var rarityDash: [CGFloat] {
        switch rarity {
        case .common: []
        case .uncommon: [5, 2]
        case .rare: [2, 2]
        case .mythic: [6, 2, 1, 2]
        }
    }
}
