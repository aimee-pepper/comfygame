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
    /// Incremented by the owning screen whenever an off-page interaction or navigation transition
    /// occurs. It is a signal, not persisted state, so the same tap can continue to its ordinary
    /// destination after dismissing the modal page tool.
    let dismissalToken: Int

    /// The written mark being dragged, and how far. Kept apart from `ghost` so a written rune and
    /// an unwritten one can never be in flight at once.
    ///
    /// **`@GestureState`, not `@State`, and that is the whole point.** A long press starts this drag
    /// *and* opens the context menu; the menu then swallows the gesture, so `onEnded` never runs. As
    /// plain state, the mark stayed "being dragged" at whatever offset it had reached — drawn
    /// somewhere it isn't, often clean off the page. That was the sigil vanishing when you chose
    /// Connect. `@GestureState` resets itself when a gesture is cancelled, which is exactly the
    /// guarantee this needs.
    @GestureState private var drag: MarkDrag?
    @State private var ghostDrag: CGSize = .zero

    private struct MarkDrag: Equatable {
        var id: InstanceID
        var translation: CGSize
    }

    private var dragging: InstanceID? { drag?.id }
    /// Connecting or disconnecting. Entered from a sigil's menu, left by tapping bare page.
    @State private var interaction = PageInteractionSession()
    /// The sigil the mode is anchored on — what the next tap joins to or unjoins from.
    /// The mark you're holding, whose actions are showing in the footer.
    ///
    /// Plain `@State` rather than a gesture state: the row has to stay up while you reach for a
    /// button, which is the opposite of a gesture's lifetime. Cleared by choosing something,
    /// cancelling, or touching bare page.
    private var mode: PageMode {
        get { interaction.mode }
        nonmutating set { interaction.mode = newValue }
    }
    private var anchor: InstanceID? {
        get { interaction.anchor }
        nonmutating set { interaction.anchor = newValue }
    }
    private var held: InstanceID? {
        get { interaction.held }
        nonmutating set { interaction.held = newValue }
    }
    private var connectionError: String? {
        get { interaction.connectionError }
        nonmutating set { interaction.connectionError = newValue }
    }


    private var page: Page { store.state.base.page }
    private var pageSize: CGSize {
        CGSize(width: side * CGFloat(page.width), height: side * CGFloat(page.height))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topLeading) {
                gridBackground
                // **Each joined group gets its own coloured outline** (session 14 §2). Drawn under
                // the marks so the border reads as around the whole piece. Without this a page's
                // meaning lives in an invisible adjacency graph: two clusters touching look exactly
                // like one cluster, and there is no way to tell what you've actually written.
                ForEach(page.runes) { mark in
                    markView(mark, side: side, pageSize: pageSize)
                }
                // **Each joined group gets its own coloured outline** (session 14 §2). Drawn over
                // the marks rather than under them — underneath, their own borders hid almost all
                // of it, which defeats the point. Never hit-testable, so it costs no touches.
                ForEach(Array(PageRules.clusters(on: page).enumerated()), id: \.offset) { _, group in
                    if group.count > 1 {
                        clusterOutline(group, side: side)
                            .offset(x: dragOffset(for: group[0]).width,
                                    y: dragOffset(for: group[0]).height)
                    }
                }
                if let ghost { ghostView(ghost, side: side) }
            }
            .frame(width: pageSize.width, height: pageSize.height, alignment: .topLeading)
            // Only speaks when there's something to say — an always-present instruction strip is a
            // permanent tax on the page for a sentence you read once.
            // Always present, even when it says nothing. Making it conditional saved a strip of
            // space and cost the page a stable size — the card grew and shrank as you placed and
            // moved sigils, which is intolerable on the one surface you're trying to arrange things
            // on.
            footer.foregroundStyle(held == nil ? footerTint : Color.primary)
                // **Pinned to the page's own width.** The footer's text and buttons are wider than
                // the grid, and a leading-aligned VStack takes the width of its widest child — so
                // the card grew sideways and shifted the whole page across the moment a ghost
                // appeared or a mode started. The one surface you arrange things on has to hold
                // still.
                .frame(width: pageSize.width, alignment: .leading)
        }
        .frame(width: pageSize.width, alignment: .leading)
        .padding(8)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
        .onChange(of: dismissalToken) { _, _ in interaction.cancel() }
        .onChange(of: pageInteractionIdentity) { _, _ in interaction.cancel() }
        .onDisappear { interaction.cancel() }
    }

    private var pageInteractionIdentity: PageInteractionIdentity {
        PageInteractionIdentity(width: page.width, height: page.height, runeIDs: page.runes.map(\.id))
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
    private var hint: String? { mode.hint }

    /// Marks are written and none of them are joined into anything with a target in it.
    private var isWrittenButSilent: Bool {
        !page.runes.isEmpty && PageRules.sigils(of: page).isEmpty
    }

    /// A rung written where it changes nothing about the target it's joined to. Same class of trap
    /// as an unjoined mark, one level down, and it cost a real session (6 Aug).
    private var inert: (qualifier: QualifierDef, target: PressureTargetDef)? {
        PageRules.inertQualifiers(on: page).first
    }

    private var grammarWarning: String? {
        PageRules.grammarWarnings(on: page,
                                  chainingUnlocked: store.state.base.hasChainingUnlock).first
    }

    private var footerTint: Color {
        if mode != .off { return mode.tint }
        guard ghost == nil, dragging == nil else { return .secondary }
        return isWrittenButSilent || inert != nil || grammarWarning != nil ? .orange : .secondary
    }

    private var footer: some View {
        HStack(spacing: 10) {
            if let held, let mark = page.runes.first(where: { $0.id == held }) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(mark.displayName)
                        .font(.caption2.weight(.medium))
                    // What it *is*, in the settled words — the focus, what it's joined to, and any
                    // modifiers on it. The cheapest possible discoverability for a vocabulary
                    // heading toward 149 runes.
                    if let reading = PageRules.reading(of: mark, on: page) {
                        Text(reading)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            // Two lines, and the strip is tall enough for them whatever it's
                            // showing — the card must not change shape as you touch things.
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
                actions(for: mark)
                // **An icon, not the word.** "Cancel" was being squeezed to "Ca n…" beside three
                // icons on a page-width row (Aimee, 6 Aug).
                iconButton("xmark", "Done with this sigil") { self.held = nil }
            }
            else if let hint = connectionError ?? mode.hint {
                Image(systemName: mode.icon).font(.caption2)
                Text(hint).font(.caption2)
                Spacer()
                Button("Done") { interaction.cancel() }
                    .font(.caption2)
                    .frame(minWidth: 44, minHeight: 44)
            }
            else if let ghost {
                Text(fits(ghost) ? "Drag into place, then let go" : "Won't fit there")
                    .font(.caption)
                    .foregroundStyle(fits(ghost) ? Color.secondary : Color.orange)
                Spacer()
                Button("Cancel") { self.ghost = nil }
                    .font(.caption)
                    .frame(minWidth: 60, minHeight: 44)
                    .layoutPriority(1)
            } else if dragging != nil {
                Text("Drag off the page to erase")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            } else if let inert {
                // **Says what it does instead**, rather than only that it doesn't. Hiding the rung
                // would fight session 14, which makes Scale a generic workhorse; naming the mistake
                // where it was made teaches the grammar.
                Image(systemName: "exclamationmark.triangle.fill").font(.caption2)
                Text("\(inert.qualifier.name) says nothing about \(inert.target.name). \(inert.qualifier.ladder.displayName) sets \(inert.qualifier.ladder.job).")
                    .font(.caption2)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
            } else if let grammarWarning {
                Image(systemName: "exclamationmark.triangle.fill").font(.caption2)
                Text("Loaded writing: \(grammarWarning)")
                    .font(.caption2)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
            } else if isWrittenButSilent {
                // **The trap this exists for.** Adjacency alone joins nothing (session 14 §2), so a
                // page can look full and describe nothing at all — and the world comes out entirely
                // random, at full stability, exactly as if you had written nothing.
                Image(systemName: "exclamationmark.triangle.fill").font(.caption2)
                Text("Not joined — hold a sigil to Connect.")
                    .font(.caption2)
                Spacer()
            }
        }
        .lineLimit(2)
        // **Fixed, not minimum.** Reserved for the tallest thing it ever shows, so the page above
        // it never moves — the card changing shape as you arrange sigils was intolerable on the one
        // surface you arrange things on.
        .frame(height: 48)
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
        // Hit-testable only while a mode is running, so a tap on bare page can end it — and can't
        // interfere with anything the rest of the time.
        .allowsHitTesting(mode != .off || held != nil)
        .onTapGesture { interaction.cancel() }
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
        let discarding = willDiscard(mark, side: side, pageSize: pageSize)
        let tint = discarding ? Color.red : Color.accentColor
        // Inside a cluster the individual borders step back, so the outline around the whole thing
        // is what you read. Adjacent-and-joined has to look unmistakably unlike adjacent-and-not.
        let inCluster = PageRules.cluster(containing: mark.id, on: page).count > 1
        let isAnchor = (anchor == mark.id && mode != .off) || held == mark.id
        let actionable = isActionable(mark)

        return ZStack(alignment: .topLeading) {
            cells(of: shape, side: side) { cell in
                RoundedRectangle(cornerRadius: inCluster ? 0 : side * 0.12)
                    .fill(tint.opacity(isDragging ? 0.45 : 0.28))
                    .overlay(RoundedRectangle(cornerRadius: inCluster ? 0 : side * 0.12)
                        .stroke(tint.opacity(isDragging ? 1 : (inCluster ? 0.06 : 0.65)),
                                lineWidth: isDragging ? 2 : 1))
                    // What the mode is anchored on, and what it can reach from there.
                    .overlay(RoundedRectangle(cornerRadius: inCluster ? 0 : side * 0.12)
                        // Held with no mode running still has to show which one you're holding, and
                        // `.off` has no tint of its own.
                        .stroke(mode == .off ? Color.accentColor : mode.tint,
                                lineWidth: isAnchor ? 3 : (actionable ? 2 : 0))
                        .opacity(isAnchor ? 1 : (actionable ? 0.85 : 0)))
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
        .onTapGesture { tapped(mark) }
        // **Hold opens the actions; drag moves it.** Both are attached here and the drag's
        // minimum distance keeps them apart, so a hold that wanders a little still counts as a hold.
        .onLongPressGesture(minimumDuration: 0.35) {
            held = mark.id
            mode = .off
            anchor = nil
        }
        .gesture(markDrag(mark, side: side, pageSize: pageSize))
        .accessibilityLabel("\(mark.displayName), \(mark.cells.count) cells. Drag to move, or off the page to erase.")
    }

    /// A cluster drags as one, so every mark in it follows the one under the finger.
    private func dragOffset(for mark: PlacedRune) -> CGSize {
        guard let drag,
              PageRules.cluster(containing: drag.id, on: page).contains(where: { $0.id == mark.id })
        else { return .zero }
        return drag.translation
    }

    /// Whether letting go now would erase what's in flight.
    private func willDiscard(_ mark: PlacedRune, side: CGFloat, pageSize: CGSize) -> Bool {
        guard let drag, drag.id == mark.id else { return false }
        return !isOverPage(mark, translation: drag.translation, side: side, pageSize: pageSize)
    }

    /// Enter a mode, or turn the piece. Nothing else.
    ///
    /// Connecting and disconnecting are **modes** rather than one-shot actions: you usually join
    /// several sigils in a row, and a mode lets you keep going instead of reopening a menu for each
    /// one. Tapping bare page leaves the mode.
    ///
    /// **This is our own row, not `.contextMenu`, and that's a bug fix.** The system menu snapshots
    /// the view it's attached to and puts it back on dismissal — and these marks are positioned by
    /// `.offset` while being dragged, so the restore left the sigil invisible until something else
    /// forced a layout pass. Aimee reported it twice: *"pressing and holding a sigil and choosing an
    /// option still vanishes the sigil until you click the screen again."* The same attachment was
    /// also what swallowed the drag gesture in session 16.
    ///
    /// It's better here anyway: the buttons are 44pt in the footer, in the thumb zone, instead of a
    /// floating menu that covers the page you're trying to read.
    @ViewBuilder
    private func actions(for mark: PlacedRune) -> some View {
        iconButton("link", "Connect") {
            mode = .connecting
            anchor = mark.id
            held = nil
        }

        if page.links.contains(where: { $0.involves(mark.id) }) {
            // **One tap severs.** Entering the mode is only so you can keep going down a chain.
            iconButton("scissors", "Disconnect", tint: .red) {
                mode = .disconnecting
                anchor = nil
                held = nil
            }
        }

        if PageRules.rotate(cluster: mark.id, on: page) != nil {
            iconButton("rotate.right", "Turn") {
                store.rotateCluster(mark.id)
                held = nil
            }
        }
    }

    /// A square 44pt tap target with a glyph in it, and a spoken name for VoiceOver.
    ///
    /// Icons rather than labels because the row shares a page-width strip with the sigil's name —
    /// four words and three glyphs don't fit, and what got squeezed was the text.
    private func iconButton(_ systemName: String, _ label: String,
                            tint: Color = .accentColor,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.footnote)
                .foregroundStyle(tint)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    /// A tap on a sigil while a mode is running.
    ///
    /// **Connecting names a pair; disconnecting doesn't.** Disconnect used to borrow connect's
    /// shape — set an anchor, then tap a second sigil — so the first tap looked inert and the
    /// second only worked if that sigil happened to be joined to the anchor. Aimee: *"disconnecting
    /// a sigil only works on the first sigil I click I think? It should disconnect anything I
    /// click."* One tap, and it comes loose from everything.
    ///
    /// That also answers session 14's open question about breaking a mid-chain link: the tapped
    /// sigil comes loose and whatever remains splits as its own geometry dictates. One rule.
    private func tapped(_ mark: PlacedRune) {
        switch mode {
        case .off:
            // **Naming what you touched.** The glyphs are abstract on purpose and will stay
            // abstract once the real hand lands — so "what is this one?" has to have an answer, or
            // an alphabet you learn to read is just an unreadable one.
            held = mark.id
        case .connecting:
            guard let from = anchor else { anchor = mark.id; connectionError = nil; return }
            // Chaining: whatever you just joined becomes the anchor, so you can keep going.
            if store.connect(from, mark.id) {
                anchor = mark.id
                connectionError = nil
            } else {
                connectionError = store.connectionIssue(from, mark.id)?.message
                    ?? "Those marks cannot be joined."
            }
        case .disconnecting:
            store.disconnectAll(mark.id)
        }
    }

    /// Whether this sigil is something the running mode can act on — drives the highlight.
    private func isActionable(_ mark: PlacedRune) -> Bool {
        guard let from = anchor, from != mark.id else { return false }
        switch mode {
        case .off: return false
        case .connecting: return store.canConnect(from, mark.id)
        case .disconnecting: return page.links.contains(MarkLink(from, mark.id))
        }
    }

    /// The border round a cluster, marking it as one object. Touching-but-unjoined clusters have
    /// their own borders, so adjacent-and-separate reads differently from adjacent-and-joined.
    private func clusterOutline(_ group: [PlacedRune], side: CGFloat) -> some View {
        let cells = Set(group.flatMap(\.cells))
        let hue = Self.hue(of: group)
        return ZStack(alignment: .topLeading) {
            ForEach(Array(cells).sorted { ($0.row, $0.column) < ($1.row, $1.column) }, id: \.self) { cell in
                Rectangle()
                    .fill(hue.opacity(0.16))
                    .frame(width: side, height: side)
                    .offset(x: CGFloat(cell.column) * side, y: CGFloat(cell.row) * side)
            }
        }
        .overlay(alignment: .topLeading) {
            ForEach(Array(cells).sorted { ($0.row, $0.column) < ($1.row, $1.column) }, id: \.self) { cell in
                ClusterEdges(cell: cell, cells: cells, side: side, hue: hue)
            }
        }
        .allowsHitTesting(false)
    }

    /// A cluster's own colour, so two joined groups sitting side by side are unmistakably two.
    ///
    /// Taken from the target the cluster is about, so an Illumination piece is the same colour every
    /// time you write one — the hue means something rather than being a rotating palette. Clusters
    /// with no target fall back to their position in the catalogue.
    static func hue(of group: [PlacedRune]) -> Color {
        let targets = ContentCatalog.shared.pressureTargetsInOrder
        let index = group.compactMap(\.targetID)
            .compactMap { id in targets.firstIndex { $0.id == id } }
            .min()
            ?? Int(group.map(\.id.rawValue).min() ?? 0) % max(1, targets.count)
        return Color(hue: Double(index) / Double(max(1, targets.count)),
                     saturation: 0.75, brightness: 0.72)
    }

    private func markDrag(_ mark: PlacedRune, side: CGFloat, pageSize: CGSize) -> some Gesture {
        // Far enough that the long press which opens the context menu doesn't read as a drag.
        DragGesture(minimumDistance: 8)
            .updating($drag) { value, state, _ in
                state = MarkDrag(id: mark.id, translation: value.translation)
            }
            .onChanged { _ in if held != nil { held = nil } }
            .onEnded { value in
                let discard = !isOverPage(mark, translation: value.translation, side: side, pageSize: pageSize)
                let delta = PageCell(column: Int((value.translation.width / side).rounded()),
                                     row: Int((value.translation.height / side).rounded()))
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
    let hue: Color

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
        .stroke(hue, lineWidth: 4)
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

/// What the page is currently doing to itself.
enum PageMode: Equatable {
    case off
    case connecting
    case disconnecting

    var hint: String? {
        switch self {
        case .off: nil
        case .connecting: "Tap a neighbouring sigil to join it."
        case .disconnecting: "Tap a joined sigil to separate it."
        }
    }

    var icon: String {
        switch self {
        case .off: "link"
        case .connecting: "link"
        case .disconnecting: "scissors"
        }
    }

    var tint: Color {
        switch self {
        case .off: .clear
        case .connecting: .accentColor
        case .disconnecting: .orange
        }
    }
}

struct PageInteractionIdentity: Equatable {
    let width: Int
    let height: Int
    let runeIDs: [InstanceID]
}

struct PageInteractionSession: Equatable {
    var mode: PageMode = .off
    var anchor: InstanceID?
    var held: InstanceID?
    var connectionError: String?

    mutating func cancel() {
        mode = .off
        anchor = nil
        held = nil
        connectionError = nil
    }
}
