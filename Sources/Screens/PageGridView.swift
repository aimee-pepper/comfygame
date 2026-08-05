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
    /// The mark currently picked up. Tapping a cell puts it down there.
    @State private var lifted: InstanceID?

    private var page: Page { store.state.base.page }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            GeometryReader { proxy in
                let side = proxy.size.width / CGFloat(page.width)
                ZStack(alignment: .topLeading) {
                    grid(side: side)
                    ForEach(page.runes) { mark in
                        markView(mark, side: side)
                    }
                }
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
            if let lifted, let mark = page.runes.first(where: { $0.id == lifted }) {
                Text("Holding \(mark.displayName.lowercased())")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("Rub out", role: .destructive) {
                    store.erase(lifted)
                    self.lifted = nil
                }
                .font(.caption)
                .frame(minHeight: 44)
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

    private func markView(_ mark: PlacedRune, side: CGFloat) -> some View {
        let isLifted = lifted == mark.id
        return ZStack(alignment: .topLeading) {
            // One tinted square per cell, so an awkward shape reads as the awkward shape it is.
            ForEach(Array(mark.cells.enumerated()), id: \.offset) { _, cell in
                RoundedRectangle(cornerRadius: side * 0.12)
                    .fill(Color.accentColor.opacity(isLifted ? 0.5 : 0.28))
                    .overlay(RoundedRectangle(cornerRadius: side * 0.12)
                        .stroke(Color.accentColor.opacity(isLifted ? 1 : 0.65),
                                lineWidth: isLifted ? 2 : 1))
                    .frame(width: side, height: side)
                    .offset(x: CGFloat(cell.column) * side, y: CGFloat(cell.row) * side)
            }
            Image(systemName: mark.icon)
                .font(.system(size: side * 0.5))
                .foregroundStyle(Color.accentColor)
                .frame(width: side, height: side)
                .offset(x: CGFloat(mark.origin.column) * side, y: CGFloat(mark.origin.row) * side)
        }
        .contentShape(Rectangle())
        .onTapGesture { lifted = isLifted ? nil : mark.id }
        .accessibilityLabel("\(mark.displayName), \(mark.cells.count) cells."
                            + (isLifted ? " Picked up. Tap a square to put it down."
                                        : " Tap to pick up."))
    }

    private func tap(_ cell: PageCell) {
        if let lifted {
            // Putting down what's in your hand takes priority over writing something new.
            if store.move(lifted, to: cell) { self.lifted = nil }
        } else if let pending, store.write(pending, at: cell) {
            onPlaced()
        }
    }
}
