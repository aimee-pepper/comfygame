import SwiftUI

enum ItemGridMetrics {
    static let columns = 6
    static let accessibilityColumns = 3
    static let spacing: CGFloat = 2
    static let minimumCellSide: CGFloat = 44

    static func cellSide(for contentWidth: CGFloat) -> CGFloat {
        (contentWidth - CGFloat(columns - 1) * spacing) / CGFloat(columns)
    }

    static func columnCount(dynamicTypeSize: DynamicTypeSize) -> Int {
        dynamicTypeSize.isAccessibilitySize ? accessibilityColumns : columns
    }
}

/// The shared phone grammar for owned and offered items: six graphical identities per row.
/// Names and prose belong in the detail sheet opened by a tap, not beneath every icon.
struct SixAcrossItemGrid<Data: RandomAccessCollection, ID: Hashable, Cell: View>: View {
    let data: Data
    let id: KeyPath<Data.Element, ID>
    @ViewBuilder let cell: (Data.Element) -> Cell

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(minimum: ItemGridMetrics.minimumCellSide),
                                  spacing: ItemGridMetrics.spacing),
              count: ItemGridMetrics.columnCount(dynamicTypeSize: dynamicTypeSize))
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(data, id: id) { element in cell(element) }
        }
    }
}

/// A resource uses the same six-across spatial grammar as items, while keeping its identity and
/// quantity legible without adding a prose label beneath every tile.
struct ResourceIconTile: View {
    let icon: String
    let quantity: Int
    let accessibilityName: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 9)
                .fill(Color(.secondarySystemGroupedBackground))
            RoundedRectangle(cornerRadius: 9)
                .strokeBorder(Color.accentColor.opacity(0.65), lineWidth: 1.5)
            Image(systemName: icon)
                .font(.system(size: 21, weight: .semibold))
                .foregroundStyle(.tint)
            VStack {
                HStack {
                    Spacer()
                    Text("\(quantity)")
                        .font(.system(size: 10, weight: .bold, design: .rounded).monospacedDigit())
                        .padding(.horizontal, 4).padding(.vertical, 1)
                        .background(.ultraThinMaterial, in: Capsule())
                }
                Spacer()
            }
            .padding(4)
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(minWidth: ItemGridMetrics.minimumCellSide,
               minHeight: ItemGridMetrics.minimumCellSide)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityName)
        .accessibilityValue("Quantity \(quantity)")
    }
}

enum ItemDetailPresentationPolicy {
    static func usesSheet(dynamicTypeSize: DynamicTypeSize) -> Bool {
        dynamicTypeSize.isAccessibilitySize
    }

    /// An arrow at the bottom places the body above its source; an arrow at the top places it below.
    static func preferredArrowEdge(sourceMidY: CGFloat, screenHeight: CGFloat) -> Edge {
        sourceMidY > screenHeight * 0.58 ? .bottom : .top
    }
}

private struct ItemDetailSourceFrameKey: PreferenceKey {
    static let defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) { value = nextValue() }
}

/// A tile tap that preserves the tile as the visual and accessibility anchor for compact detail.
///
/// Native popover placement owns safe-area collision and horizontal inward shifting. Accessibility
/// sizes intentionally fall back to a sheet: fitting the same detail beside a 44-point source is
/// less important than keeping its labels and actions readable.
struct AnchoredItemDetailButton<Item: Identifiable, Label: View, Detail: View>: View
where Item.ID: Equatable {
    @Binding private var selection: Item?
    private let item: Item
    private let label: () -> Label
    private let detail: (Item) -> Detail

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @AccessibilityFocusState private var sourceIsFocused: Bool
    @State private var sourceFrame: CGRect = .zero
    @State private var ownedPresentationWasOpen = false

    init(item: Item, selection: Binding<Item?>,
         @ViewBuilder label: @escaping () -> Label,
         @ViewBuilder detail: @escaping (Item) -> Detail) {
        self.item = item
        self._selection = selection
        self.label = label
        self.detail = detail
    }

    var body: some View {
        Group {
            if ItemDetailPresentationPolicy.usesSheet(dynamicTypeSize: dynamicTypeSize) {
                sourceButton
                    .sheet(isPresented: isPresented) {
                        detail(item)
                            .presentationDetents([.medium, .large])
                            .presentationBackgroundInteraction(.enabled)
                    }
            } else {
                sourceButton
                    .popover(isPresented: isPresented, attachmentAnchor: .rect(.bounds),
                             arrowEdge: preferredArrowEdge) {
                        detail(item)
                            .presentationCompactAdaptation(.popover)
                            .presentationBackgroundInteraction(.enabled)
                    }
            }
        }
        .onChange(of: isSelected) { _, selected in
            if selected {
                ownedPresentationWasOpen = true
            } else if ownedPresentationWasOpen {
                ownedPresentationWasOpen = false
                sourceIsFocused = true
            }
        }
    }

    private var sourceButton: some View {
        Button { selection = item } label: { label() }
            .buttonStyle(.plain)
            .accessibilityFocused($sourceIsFocused)
            .background {
                GeometryReader { proxy in
                    Color.clear.preference(key: ItemDetailSourceFrameKey.self,
                                           value: proxy.frame(in: .global))
                }
            }
            .onPreferenceChange(ItemDetailSourceFrameKey.self) { sourceFrame = $0 }
    }

    private var isSelected: Bool { selection?.id == item.id }
    private var isPresented: Binding<Bool> {
        Binding(get: { isSelected }, set: { presented in
            if !presented, isSelected { selection = nil }
        })
    }
    private var preferredArrowEdge: Edge {
        ItemDetailPresentationPolicy.preferredArrowEdge(sourceMidY: sourceFrame.midY,
                                                        screenHeight: UIScreen.main.bounds.height)
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
