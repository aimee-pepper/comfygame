import SwiftUI

/// The page: where a book is actually written.
///
/// **The page is fixed and always fully visible** — it never scrolls and never grows
/// (decisions-session-10). The vocabulary scrolls beneath it; the page stays put, because you are
/// arranging things on it and it has to stay where you left it.
///
/// Placing works the way fitting a shape into a space should: pick a rune from the palette and a
/// **ghost** of it appears on the page, which you drag into position and let go. Runes already
/// written drag too, and dragging one clear of the page rubs it out. Arranging is free until you
/// bind.
///
/// Position is never meaning. Where a rune sits changes nothing about the world it describes, so
/// this view is free to be as physical as it likes without the simulation caring.
struct PageGridView: View {
    @EnvironmentObject private var store: GameStore
    /// The rune chosen but not yet written, and where its origin currently sits.
    @Binding var ghost: GhostRune?
    /// Cell size, computed by the pane that owns the layout.
    ///
    /// Passed in rather than derived here on purpose: the page shares a screen with a scroll view,
    /// and a scroll view is greedy — left to negotiate, it squeezed the grid to two-thirds of the
    /// width available and the page came out small and off-centre.
    let side: CGFloat

    /// The written mark being dragged, and how far. Kept apart from `ghost` so a written rune and
    /// an unwritten one can never be in flight at once.
    @State private var dragging: InstanceID?
    @State private var translation: CGSize = .zero
    @State private var ghostDrag: CGSize = .zero
    @State private var willDiscard = false

    private var page: Page { store.state.base.page }
    private var pageSize: CGSize {
        CGSize(width: side * CGFloat(page.width), height: side * CGFloat(page.height))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            ZStack(alignment: .topLeading) {
                gridBackground
                ForEach(page.runes) { mark in
                    markView(mark, side: side, pageSize: pageSize)
                }
                if let ghost { ghostView(ghost, side: side) }
            }
            .frame(width: pageSize.width, height: pageSize.height, alignment: .topLeading)
            footer
        }
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: Chrome

    private var header: some View {
        HStack {
            Text("\(page.usedCells)/\(page.capacity) cells")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
            Spacer()
            Text(store.state.base.bestHand.displayName)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var footer: some View {
        HStack(spacing: 10) {
            if let ghost {
                Text(fits(ghost) ? "Drag into place, then let go" : "Won't fit there")
                    .font(.caption)
                    .foregroundStyle(fits(ghost) ? Color.secondary : Color.orange)
                Spacer()
                Button("Cancel") { self.ghost = nil }
                    .font(.caption)
                    .frame(minWidth: 60, minHeight: 44)
            } else if dragging != nil {
                Text(willDiscard ? "Let go to rub it out" : "Drag off the page to rub it out")
                    .font(.caption)
                    .foregroundStyle(willDiscard ? Color.red : Color.secondary)
                Spacer()
            } else {
                Text("Pick a rune below, then drag it into place.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
            }
        }
        .frame(height: 44)
    }

    /// Drawn behind everything, and deliberately not hit-testable — every touch on the page
    /// belongs to a rune. Square cells sized from the available width, so the page always fills it.
    private var gridBackground: some View {
        VStack(spacing: 0) {
            ForEach(0..<page.height, id: \.self) { _ in
                HStack(spacing: 0) {
                    ForEach(0..<page.width, id: \.self) { _ in
                        Rectangle()
                            .fill(Color(.tertiarySystemGroupedBackground))
                            .overlay(Rectangle().stroke(Palette.mapGrid, lineWidth: 0.5))
                            .frame(width: side, height: side)
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: Written runes

    /// A written rune, sized to **its own footprint** and positioned there.
    ///
    /// The frame matters more than it looks. An earlier version drew the cells at an offset inside
    /// a full-size `ZStack`, which made every rune's hit area the whole page — so the last one drawn
    /// swallowed every touch and nothing could be dragged at all.
    private func markView(_ mark: PlacedRune, side: CGFloat, pageSize: CGSize) -> some View {
        let shape = mark.shape
        let isDragging = dragging == mark.id
        let tint = isDragging && willDiscard ? Color.red : Color.accentColor

        return ZStack(alignment: .topLeading) {
            cells(of: shape, side: side) { cell in
                RoundedRectangle(cornerRadius: side * 0.12)
                    .fill(tint.opacity(isDragging ? 0.45 : 0.28))
                    .overlay(RoundedRectangle(cornerRadius: side * 0.12)
                        .stroke(tint.opacity(isDragging ? 1 : 0.65), lineWidth: isDragging ? 2 : 1))
                    .frame(width: side, height: side)
                    .offset(x: CGFloat(cell.column) * side, y: CGFloat(cell.row) * side)
            }
            RuneGlyph(id: mark.symbolID?.rawValue ?? String(mark.id.rawValue),
                      lineWidth: max(1.5, side * 0.07))
                .frame(width: side, height: side)
                .foregroundStyle(tint)
        }
        .frame(width: CGFloat(shape?.width ?? 1) * side,
               height: CGFloat(shape?.height ?? 1) * side,
               alignment: .topLeading)
        .contentShape(Rectangle())
        .offset(x: CGFloat(mark.origin.column) * side + (isDragging ? translation.width : 0),
                y: CGFloat(mark.origin.row) * side + (isDragging ? translation.height : 0))
        .zIndex(isDragging ? 2 : 0)
        .gesture(markDrag(mark, side: side, pageSize: pageSize))
        .accessibilityLabel("\(mark.displayName), \(mark.cells.count) cells. Drag to move, or off the page to rub out.")
    }

    private func markDrag(_ mark: PlacedRune, side: CGFloat, pageSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                dragging = mark.id
                translation = value.translation
                willDiscard = !isOverPage(mark, translation: value.translation, side: side, pageSize: pageSize)
            }
            .onEnded { value in
                let discard = !isOverPage(mark, translation: value.translation, side: side, pageSize: pageSize)
                let target = PageCell(
                    column: mark.origin.column + Int((value.translation.width / side).rounded()),
                    row: mark.origin.row + Int((value.translation.height / side).rounded()))
                dragging = nil
                translation = .zero
                willDiscard = false
                if discard { store.erase(mark.id) } else { store.move(mark.id, to: target) }
            }
    }

    /// Uses the rune's own body rather than the finger, so letting go with your thumb just past the
    /// edge doesn't throw away something you meant to keep.
    private func isOverPage(_ mark: PlacedRune, translation: CGSize,
                            side: CGFloat, pageSize: CGSize) -> Bool {
        let width = CGFloat(mark.shape?.width ?? 1) * side
        let height = CGFloat(mark.shape?.height ?? 1) * side
        let x = CGFloat(mark.origin.column) * side + translation.width + width / 2
        let y = CGFloat(mark.origin.row) * side + translation.height + height / 2
        return x > 0 && x < pageSize.width && y > 0 && y < pageSize.height
    }

    // MARK: The ghost

    /// A rune chosen but not yet written. Drag it where you want it and let go.
    private func ghostView(_ ghost: GhostRune, side: CGFloat) -> some View {
        let shape = shape(of: ghost)
        let ok = fits(ghost)
        let tint = ok ? Color.accentColor : Color.red

        return ZStack(alignment: .topLeading) {
            cells(of: shape, side: side) { cell in
                RoundedRectangle(cornerRadius: side * 0.12)
                    .fill(tint.opacity(0.22))
                    .overlay(RoundedRectangle(cornerRadius: side * 0.12)
                        .strokeBorder(tint, style: StrokeStyle(lineWidth: 2, dash: [4, 3])))
                    .frame(width: side, height: side)
                    .offset(x: CGFloat(cell.column) * side, y: CGFloat(cell.row) * side)
            }
            RuneGlyph(id: ghost.symbol.rawValue, lineWidth: max(1.5, side * 0.07))
                .frame(width: side, height: side)
                .foregroundStyle(tint)
        }
        .frame(width: CGFloat(shape?.width ?? 1) * side,
               height: CGFloat(shape?.height ?? 1) * side,
               alignment: .topLeading)
        .contentShape(Rectangle())
        .offset(x: CGFloat(ghost.origin.column) * side + ghostDrag.width,
                y: CGFloat(ghost.origin.row) * side + ghostDrag.height)
        .zIndex(3)
        .gesture(
            DragGesture(minimumDistance: 2)
                .onChanged { ghostDrag = $0.translation }
                .onEnded { value in
                    let target = PageCell(
                        column: ghost.origin.column + Int((value.translation.width / side).rounded()),
                        row: ghost.origin.row + Int((value.translation.height / side).rounded()))
                    ghostDrag = .zero
                    var moved = ghost
                    moved.origin = target
                    // Let go somewhere it fits and it's written. Somewhere it doesn't, and the
                    // ghost just stays there — still yours to move, nothing lost.
                    if fits(moved), store.write(ghost.symbol, at: target) {
                        self.ghost = nil
                    } else {
                        self.ghost = moved
                    }
                }
        )
        .accessibilityLabel("\(ContentCatalog.shared.symbol(ghost.symbol)?.name ?? "A rune"), not yet written. Drag to place.")
    }

    // MARK: Helpers

    @ViewBuilder
    private func cells<Content: View>(of shape: RuneShapeDef?, side: CGFloat,
                                      @ViewBuilder content: @escaping (PageCell) -> Content) -> some View {
        let offsets = shape?.offsets ?? [PageCell(column: 0, row: 0)]
        ForEach(Array(offsets.enumerated()), id: \.offset) { _, cell in
            content(cell)
        }
    }

    private func shape(of ghost: GhostRune) -> RuneShapeDef? {
        ContentCatalog.shared.symbol(ghost.symbol)
            .flatMap { PageRules.shape(forCompound: $0, hand: store.state.base.bestHand) }
    }

    private func fits(_ ghost: GhostRune) -> Bool {
        guard let shape = shape(of: ghost) else { return false }
        return PageRules.canPlace(shape: shape, at: ghost.origin, on: page)
    }
}

/// A rune picked from the palette and hovering over the page, not yet written.
struct GhostRune: Equatable {
    var symbol: SymbolID
    var origin: PageCell

    /// Where a freshly picked rune appears: the first place it would fit, so it starts somewhere
    /// legal and the player is adjusting rather than hunting.
    static func appearing(_ symbol: SymbolDef, hand: Hand, on page: Page) -> GhostRune {
        let shape = PageRules.shape(forCompound: symbol, hand: hand)
        let origin = shape.flatMap { PageRules.validOrigins(for: $0, on: page).first }
            ?? PageCell(column: 0, row: 0)
        return GhostRune(symbol: symbol.id, origin: origin)
    }
}
