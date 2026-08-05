import SwiftUI

/// The page: where a book is actually written.
///
/// Tap an empty cell to place the selected mark; tap a mark to rub it out. The grid is the whole
/// composition surface — page size is what you're *capable* of writing, and fitting things onto it
/// is deliberate gameplay rather than a formality (`writing-system-rune-spec.md` §2–3).
///
/// Position is never meaning. Where a mark sits changes nothing about the world it describes, so
/// this view can be as free-form as it likes without the simulation caring.
struct PageGridView: View {
    @EnvironmentObject private var store: GameStore
    /// What tapping an empty cell will write, if anything.
    let pending: SymbolID?
    var onPlaced: () -> Void = {}
    /// Where the page sits on screen, so a rune dragged from the palette knows when it's over it.
    @Binding var frame: CGRect
    /// A rune being dragged in from the palette: its id, and where the finger is.
    @Binding var incoming: IncomingRune?
    /// The mark under the player's finger, and how far it has been dragged.
    @State private var dragging: InstanceID?
    @State private var translation: CGSize = .zero
    /// True while the drag has left the page — the mark will be rubbed out if released here.
    @State private var willDiscard = false

    private var page: Page { store.state.base.page }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            GeometryReader { proxy in
                let side = proxy.size.width / CGFloat(page.width)
                ZStack(alignment: .topLeading) {
                    grid(side: side)
                    ForEach(page.runes) { mark in
                        markView(mark, side: side, pageSize: proxy.size)
                    }
                    if let incoming, let cell = cell(for: incoming.location, side: side) {
                        dropPreview(incoming, at: cell, side: side)
                    }
                }
                .onAppear { frame = proxy.frame(in: .global) }
                .onChange(of: proxy.frame(in: .global)) { _, new in frame = new }
            }
            .aspectRatio(CGFloat(page.width) / CGFloat(page.height), contentMode: .fit)
            footer
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    private var header: some View {
        HStack {
            Label("The page", systemImage: "square.grid.3x3")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
            Text(store.state.base.bestHand.displayName)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var footer: some View {
        HStack {
            Text("\(page.usedCells) of \(page.capacity) cells")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
            Spacer()
            if dragging != nil {
                Text(willDiscard ? "Let go to rub it out" : "Drag off the page to rub it out")
                    .font(.caption)
                    .foregroundStyle(willDiscard ? Color.red : Color.secondary)
            } else if let pending, let symbol = ContentCatalog.shared.symbol(pending) {
                Text(store.canWrite(pending)
                     ? "Tap to place \(symbol.name.lowercased()) — \(store.footprint(of: pending)) cells"
                     : "No room left for \(symbol.name.lowercased())")
                    .font(.caption)
                    .foregroundStyle(store.canWrite(pending) ? Color.secondary : Color.orange)
            }
        }
    }

    private func grid(side: CGFloat) -> some View {
        VStack(spacing: 0) {
            ForEach(0..<page.height, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<page.width, id: \.self) { column in
                        let cell = PageCell(column: column, row: row)
                        Rectangle()
                            .fill(Color(.tertiarySystemGroupedBackground))
                            .overlay(Rectangle().stroke(Palette.mapGrid, lineWidth: 0.5))
                            .frame(width: side, height: side)
                            .contentShape(Rectangle())
                            .onTapGesture { tap(cell) }
                    }
                }
            }
        }
    }

    private func markView(_ mark: PlacedRune, side: CGFloat, pageSize: CGSize) -> some View {
        let isDragging = dragging == mark.id
        return ZStack(alignment: .topLeading) {
            // One tinted square per cell, so an awkward shape reads as the awkward shape it is.
            ForEach(Array(mark.cells.enumerated()), id: \.offset) { _, cell in
                RoundedRectangle(cornerRadius: side * 0.12)
                    .fill((isDragging && willDiscard ? Color.red : Color.accentColor)
                        .opacity(isDragging ? 0.45 : 0.28))
                    .overlay(RoundedRectangle(cornerRadius: side * 0.12)
                        .stroke((isDragging && willDiscard ? Color.red : Color.accentColor)
                            .opacity(isDragging ? 1 : 0.65), lineWidth: isDragging ? 2 : 1))
                    .frame(width: side, height: side)
                    .offset(x: CGFloat(cell.column) * side, y: CGFloat(cell.row) * side)
            }
            Image(systemName: mark.icon)
                .font(.system(size: side * 0.5))
                .foregroundStyle(isDragging && willDiscard ? Color.red : Color.accentColor)
                .frame(width: side, height: side)
                .offset(x: CGFloat(mark.origin.column) * side, y: CGFloat(mark.origin.row) * side)
        }
        .contentShape(Rectangle())
        .offset(isDragging ? translation : .zero)
        .zIndex(isDragging ? 1 : 0)
        .animation(.snappy(duration: 0.12), value: isDragging)
        .gesture(drag(mark, side: side, pageSize: pageSize))
        .accessibilityLabel("\(mark.displayName), \(mark.cells.count) cells. Drag to move, or off the page to rub out.")
    }

    /// The cell under a point given in global coordinates.
    func cell(for globalPoint: CGPoint, side: CGFloat) -> PageCell? {
        guard frame.contains(globalPoint) else { return nil }
        let local = CGPoint(x: globalPoint.x - frame.minX, y: globalPoint.y - frame.minY)
        let cell = PageCell(column: Int(local.x / side), row: Int(local.y / side))
        return page.contains(cell) ? cell : nil
    }

    /// A ghost of the rune being dragged in, so you can see whether it will fit before letting go.
    @ViewBuilder
    private func dropPreview(_ incoming: IncomingRune, at cell: PageCell, side: CGFloat) -> some View {
        if let symbol = ContentCatalog.shared.symbol(incoming.symbol),
           let shape = PageRules.shape(forCompound: symbol, hand: store.state.base.bestHand) {
            let fits = PageRules.canPlace(shape: shape, at: cell, on: page)
            ForEach(Array(shape.offsets.enumerated()), id: \.offset) { _, offset in
                RoundedRectangle(cornerRadius: side * 0.12)
                    .fill((fits ? Color.accentColor : Color.red).opacity(0.3))
                    .frame(width: side, height: side)
                    .offset(x: CGFloat(cell.column + offset.column) * side,
                            y: CGFloat(cell.row + offset.row) * side)
            }
            .allowsHitTesting(false)
        }
    }

    /// Drag to rearrange; drag clear of the page to rub out.
    ///
    /// Rearranging is free until you bind, so this is deliberately loose — you can shuffle the page
    /// as much as you like. A drop that doesn't fit snaps back rather than being forced somewhere
    /// near, because where a mark goes is the player's decision.
    private func drag(_ mark: PlacedRune, side: CGFloat, pageSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                dragging = mark.id
                translation = value.translation
                willDiscard = !isOverPage(mark, translation: value.translation,
                                          side: side, pageSize: pageSize)
            }
            .onEnded { value in
                defer { dragging = nil; translation = .zero; willDiscard = false }
                if !isOverPage(mark, translation: value.translation, side: side, pageSize: pageSize) {
                    store.erase(mark.id)
                    return
                }
                let target = PageCell(
                    column: mark.origin.column + Int((value.translation.width / side).rounded()),
                    row: mark.origin.row + Int((value.translation.height / side).rounded()))
                store.move(mark.id, to: target)   // refused ⇒ it simply snaps back
            }
    }

    /// Whether the mark's own body is still over the page. Uses the mark rather than the finger, so
    /// letting go with your thumb just past the edge doesn't throw away something you meant to keep.
    private func isOverPage(_ mark: PlacedRune, translation: CGSize,
                            side: CGFloat, pageSize: CGSize) -> Bool {
        let width = CGFloat(mark.shape?.width ?? 1) * side
        let height = CGFloat(mark.shape?.height ?? 1) * side
        let x = CGFloat(mark.origin.column) * side + translation.width
        let y = CGFloat(mark.origin.row) * side + translation.height
        // Over the page if any meaningful part of the mark still overlaps it.
        return x + width * 0.5 > 0 && x + width * 0.5 < pageSize.width
            && y + height * 0.5 > 0 && y + height * 0.5 < pageSize.height
    }

    private func tap(_ cell: PageCell) {
        if let pending, store.write(pending, at: cell) { onPlaced() }
    }

}

/// A rune on its way from the palette to the page.
struct IncomingRune: Equatable {
    var symbol: SymbolID
    var location: CGPoint
}
