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
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topLeading) {
                gridBackground
                ForEach(page.runes) { mark in
                    markView(mark, side: side, pageSize: pageSize)
                }
                if let ghost { ghostView(ghost, side: side) }
            }
            .frame(width: pageSize.width, height: pageSize.height, alignment: .topLeading)
            // Only speaks when there's something to say — an always-present instruction strip is a
            // permanent tax on the page for a sentence you read once.
            if hint != nil || dragging != nil || ghost != nil { footer }
        }
        .padding(8)
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

    /// Nil when there's nothing worth saying, so the strip disappears entirely.
    private var hint: String? { nil }

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
            }
        }
        .frame(height: 30)
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
        // Inside a cluster the individual borders step back, so the outline around the whole thing
        // is what you read. Adjacent-and-joined has to look unmistakably unlike adjacent-and-not.
        let inCluster = PageRules.cluster(containing: mark.id, on: page).count > 1

        return ZStack(alignment: .topLeading) {
            cells(of: shape, side: side) { cell in
                RoundedRectangle(cornerRadius: inCluster ? 0 : side * 0.12)
                    .fill(tint.opacity(isDragging ? 0.45 : 0.28))
                    .overlay(RoundedRectangle(cornerRadius: inCluster ? 0 : side * 0.12)
                        .stroke(tint.opacity(isDragging ? 1 : (inCluster ? 0.15 : 0.65)),
                                lineWidth: isDragging ? 2 : 1))
                    .frame(width: side, height: side)
                    .offset(x: CGFloat(cell.column) * side, y: CGFloat(cell.row) * side)
            }
            // Drawn in a cell the shape actually occupies. A plus-shaped footprint doesn't cover
            // its own bounding-box corner, so anchoring the glyph at the origin left it floating
            // outside its own rune.
            RuneGlyph(id: mark.glyphID, lineWidth: max(1.5, side * 0.07))
                .frame(width: side, height: side)
                .foregroundStyle(tint)
                .offset(x: CGFloat(glyphCell(shape).column) * side,
                        y: CGFloat(glyphCell(shape).row) * side)
        }
        .frame(width: CGFloat(shape?.width ?? 1) * side,
               height: CGFloat(shape?.height ?? 1) * side,
               alignment: .topLeading)
        // The hit area is the rune's **actual cells**, not its bounding box. A plus-shaped
        // footprint doesn't fill its own box, and a rectangular hit area let it swallow taps on
        // squares it doesn't occupy — so a neighbour sitting in one of those corners couldn't be
        // tapped at all.
        .contentShape(CellsShape(cells: shape?.offsets ?? [PageCell(column: 0, row: 0)], side: side))
        .offset(x: CGFloat(mark.origin.column) * side + (dragOffset(for: mark).width),
                y: CGFloat(mark.origin.row) * side + (dragOffset(for: mark).height))
        .zIndex(isDragging ? 2 : 0)
        .gesture(markDrag(mark, side: side, pageSize: pageSize))
        .contextMenu { menu(for: mark) }
        .accessibilityLabel("\(mark.displayName), \(mark.cells.count) cells. Drag to move, or off the page to rub out.")
    }

    /// A cluster drags as one, so every mark in it follows the one under the finger.
    private func dragOffset(for mark: PlacedRune) -> CGSize {
        guard let dragging,
              PageRules.cluster(containing: dragging, on: page).contains(where: { $0.id == mark.id })
        else { return .zero }
        return translation
    }

    /// What you can do to this sigil, given what's around it.
    ///
    /// Replaces the connect *mode*. A mode is a thing you have to remember you're in, and the whole
    /// interaction was two taps plus a button press to say something the page could work out for
    /// itself: a sigil knows which of its neighbours it isn't joined to, and can simply offer them
    /// by name.
    @ViewBuilder
    private func menu(for mark: PlacedRune) -> some View {
        let joinable = page.runes.filter { PageRules.canConnect(mark.id, $0.id, on: page) }
        let joined = page.links.compactMap { $0.other(than: mark.id) }
            .compactMap { id in page.runes.first { $0.id == id } }

        ForEach(joinable) { neighbour in
            Button {
                store.connect(mark.id, neighbour.id)
            } label: {
                Label("Join to \(neighbour.displayName)", systemImage: "link")
            }
        }

        if !joined.isEmpty {
            Divider()
            ForEach(joined) { neighbour in
                Button(role: .destructive) {
                    store.disconnect(mark.id, neighbour.id)
                } label: {
                    Label("Unjoin from \(neighbour.displayName)", systemImage: "link.badge.plus")
                }
            }
        }

        Divider()
        if PageRules.rotate(cluster: mark.id, on: page) != nil {
            Button {
                store.rotateCluster(mark.id)
            } label: {
                Label(PageRules.cluster(containing: mark.id, on: page).count > 1 ? "Turn the piece" : "Turn",
                      systemImage: "rotate.right")
            }
        }
        Button(role: .destructive) {
            store.erase(mark.id)
        } label: {
            Label("Rub out", systemImage: "eraser")
        }
    }

    /// The border round a cluster, marking it as one object. Touching-but-unjoined clusters have
    /// their own borders, so adjacent-and-separate reads differently from adjacent-and-joined.
    private func clusterOutline(_ group: [PlacedRune], side: CGFloat) -> some View {
        let cells = Set(group.flatMap(\.cells))
        return ZStack(alignment: .topLeading) {
            ForEach(Array(cells).sorted { ($0.row, $0.column) < ($1.row, $1.column) }, id: \.self) { cell in
                Rectangle()
                    .fill(Color.primary.opacity(0.07))
                    .frame(width: side, height: side)
                    .offset(x: CGFloat(cell.column) * side, y: CGFloat(cell.row) * side)
            }
        }
        .overlay(alignment: .topLeading) {
            ForEach(Array(cells).sorted { ($0.row, $0.column) < ($1.row, $1.column) }, id: \.self) { cell in
                ClusterEdges(cell: cell, cells: cells, side: side)
            }
        }
        .allowsHitTesting(false)
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
                let delta = PageCell(column: Int((value.translation.width / side).rounded()),
                                     row: Int((value.translation.height / side).rounded()))
                dragging = nil
                translation = .zero
                willDiscard = false
                if discard {
                    store.erase(mark.id)
                } else if PageRules.cluster(containing: mark.id, on: page).count > 1 {
                    store.moveCluster(mark.id, by: delta)
                } else {
                    store.move(mark.id, to: PageCell(column: mark.origin.column + delta.column,
                                                     row: mark.origin.row + delta.row))
                }
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
            RuneGlyph(id: ghost.glyph, lineWidth: max(1.5, side * 0.07))
                .frame(width: side, height: side)
                .foregroundStyle(tint)
                .offset(x: CGFloat(glyphCell(shape).column) * side,
                        y: CGFloat(glyphCell(shape).row) * side)
        }
        .frame(width: CGFloat(shape?.width ?? 1) * side,
               height: CGFloat(shape?.height ?? 1) * side,
               alignment: .topLeading)
        .contentShape(CellsShape(cells: shape?.offsets ?? [PageCell(column: 0, row: 0)], side: side))
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
                    if fits(moved), store.write(ghost.content, glyph: ghost.glyph, at: target) {
                        self.ghost = nil
                    } else {
                        self.ghost = moved
                    }
                }
        )
        .accessibilityLabel("Not yet written. Drag to place.")
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

    /// Where in a footprint the glyph sits: the middle-most occupied cell, so it reads as the
    /// centre of the mark rather than as a corner of it.
    private func glyphCell(_ shape: RuneShapeDef?) -> PageCell {
        let cells = shape?.offsets ?? [PageCell(column: 0, row: 0)]
        guard let first = cells.first else { return PageCell(column: 0, row: 0) }
        let midColumn = Double(cells.map(\.column).reduce(0, +)) / Double(cells.count)
        let midRow = Double(cells.map(\.row).reduce(0, +)) / Double(cells.count)
        return cells.min {
            pow(Double($0.column) - midColumn, 2) + pow(Double($0.row) - midRow, 2)
                < pow(Double($1.column) - midColumn, 2) + pow(Double($1.row) - midRow, 2)
        } ?? first
    }

    private func shape(of ghost: GhostRune) -> RuneShapeDef? {
        PageRules.shape(for: ghost.content, hand: store.state.base.bestHand)
    }

    private func fits(_ ghost: GhostRune) -> Bool {
        guard let shape = shape(of: ghost) else { return false }
        return PageRules.canPlace(shape: shape, at: ghost.origin, on: page)
    }
}

/// A sigil picked from the palette and hovering over the page, not yet written.
struct GhostRune: Equatable {
    /// What it draws as, and what it will say once placed.
    var glyph: String
    var content: MarkContent
    var origin: PageCell
}

/// Draws a border only on the outside of a cluster, so the cluster reads as one shape rather than
/// as a grid of separately-boxed cells.
private struct ClusterEdges: View {
    let cell: PageCell
    let cells: Set<PageCell>
    let side: CGFloat

    var body: some View {
        Path { path in
            let x = CGFloat(cell.column) * side, y = CGFloat(cell.row) * side
            if !cells.contains(PageCell(column: cell.column, row: cell.row - 1)) {
                path.move(to: CGPoint(x: x, y: y)); path.addLine(to: CGPoint(x: x + side, y: y))
            }
            if !cells.contains(PageCell(column: cell.column, row: cell.row + 1)) {
                path.move(to: CGPoint(x: x, y: y + side)); path.addLine(to: CGPoint(x: x + side, y: y + side))
            }
            if !cells.contains(PageCell(column: cell.column - 1, row: cell.row)) {
                path.move(to: CGPoint(x: x, y: y)); path.addLine(to: CGPoint(x: x, y: y + side))
            }
            if !cells.contains(PageCell(column: cell.column + 1, row: cell.row)) {
                path.move(to: CGPoint(x: x + side, y: y)); path.addLine(to: CGPoint(x: x + side, y: y + side))
            }
        }
        .stroke(Color.primary, lineWidth: 3)
    }
}

/// A hit area made of a rune's occupied cells rather than its bounding box.
private struct CellsShape: Shape {
    let cells: [PageCell]
    let side: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        for cell in cells {
            path.addRect(CGRect(x: CGFloat(cell.column) * side, y: CGFloat(cell.row) * side,
                                width: side, height: side))
        }
        return path
    }
}
