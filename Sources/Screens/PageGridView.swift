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
    @Binding var assetsReady: Bool
    let productionPack: WritingDeskProductionPack?
    let assetFailure: () -> Void
    /// Cell size, computed by the pane that owns the layout.
    ///
    /// Passed in rather than derived here on purpose: the page shares a screen with a scroll view,
    /// and a scroll view is greedy — left to negotiate, it squeezed the grid to two-thirds of the
    /// width available and the page came out small and off-centre.
    let side: CGFloat
    let pageInset: CGFloat
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
    @State private var blankPageImage: UIImage?
    @State private var actionChromeReady = false
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


    private var page: Page { store.writingDeskPage }
    private var visibleMarksByID: [InstanceID: WritingDeskVisibleMark] {
        Dictionary(uniqueKeysWithValues: (store.writingDeskReviewModel()?.visibleMarks ?? []).map { ($0.id, $0) })
    }
    private var pageSize: CGSize {
        CGSize(width: side * CGFloat(page.width), height: side * CGFloat(page.height))
    }
    private var outerPageSize: CGSize {
        CGSize(width: pageSize.width + pageInset * 2, height: pageSize.height + pageInset * 2)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            if let blankPageImage {
                Image(uiImage: blankPageImage)
                    .interpolation(.none)
                    .resizable()
                    .frame(width: outerPageSize.width, height: outerPageSize.height)
            } else {
                Rectangle()
                    .fill(PixelUITheme.surface)
                    .overlay(Rectangle().stroke(PixelUITheme.edge, lineWidth: 2))
                    .frame(width: outerPageSize.width, height: outerPageSize.height)
            }
            ZStack(alignment: .topLeading) {
                gridBackground.opacity(0.001)
                if let productionPack {
                    ForEach(Array(page.links).sorted {
                        ($0.a.rawValue, $0.b.rawValue) < ($1.a.rawValue, $1.b.rawValue)
                    }, id: \.self) { link in
                        if let first = visibleMarksByID[link.a], let second = visibleMarksByID[link.b] {
                            WritingDeskPackLinkArtwork(pack: productionPack, first: first, second: second,
                                                       cellSide: side, failed: markPackUnavailable)
                        }
                    }
                }
                ForEach(page.runes) { mark in markView(mark, side: side, pageSize: pageSize) }
                if let ghost { ghostView(ghost, side: side) }
                if let held, let mark = page.runes.first(where: { $0.id == held }),
                   let productionPack {
                    rootActionPopover(for: mark, pack: productionPack).zIndex(100)
                }
                if let message = containedStatusMessage {
                    Text(message)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(footerTint)
                        .lineLimit(2)
                        .padding(.horizontal, 8)
                        .frame(maxWidth: pageSize.width - 12, minHeight: 28, maxHeight: 36)
                        .background(.ultraThinMaterial)
                        .overlay(Rectangle().stroke(footerTint.opacity(0.65), lineWidth: 1))
                        .frame(maxWidth: pageSize.width, maxHeight: pageSize.height, alignment: .bottom)
                        .padding(.bottom, 6)
                        .allowsHitTesting(false)
                        .zIndex(20)
                }
            }
            .frame(width: pageSize.width, height: pageSize.height)
            .offset(x: pageInset, y: pageInset)
            if !assetsReady && productionPack != nil {
                Text("Writing assets unavailable")
                    .font(.caption.weight(.semibold))
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .frame(width: outerPageSize.width, height: outerPageSize.height)
            }
        }
        .frame(width: outerPageSize.width, height: outerPageSize.height, alignment: .topLeading)
        .allowsHitTesting(assetsReady || productionPack == nil)
        .onChange(of: dismissalToken) { _, _ in interaction.cancel() }
        .onChange(of: pageInteractionIdentity) { _, _ in interaction.cancel() }
        .onDisappear { interaction.cancel() }
        .task(id: pageLoadIdentity) {
            guard let productionPack else {
                blankPageImage = nil
                assetsReady = true
                return
            }
            assetsReady = false
            do {
                let blank = try productionPack.blankPageSpec()
                guard blank.writingArea == .init(x: 5, y: 5, width: 162, height: 162),
                      let image = UIImage(data: try WritingDeskProductionPack.productionParchmentData()),
                      image.size == CGSize(width: 172, height: 172)
                else { throw WritingDeskProductionPack.PackError.corruptAsset(
                    WritingDeskProductionPack.parchmentSHA256) }
                for mark in visibleMarksByID.values where mark.visualRoute != .personalCompoundCompatibility {
                    guard case let .authored(key) = try productionPack.route(for: mark) else { continue }
                    let roles = try productionPack.markAssets(for: key)
                    guard UIImage(data: try productionPack.assetData(sha256: roles.rgba.sha256)) != nil
                    else { throw WritingDeskProductionPack.PackError.corruptAsset(roles.rgba.sha256) }
                }
                for link in page.links {
                    guard let first = visibleMarksByID[link.a], let second = visibleMarksByID[link.b]
                    else { continue }
                    let placement = try productionPack.link(between: first, and: second)
                    guard UIImage(data: try productionPack.assetData(sha256: placement.asset.sha256)) != nil
                    else { throw WritingDeskProductionPack.PackError.corruptAsset(placement.asset.sha256) }
                }
                blankPageImage = image
                assetsReady = true
            } catch {
                blankPageImage = nil
                assetsReady = false
                ghost = nil
                interaction.cancel()
                assetFailure()
            }
        }
    }

    private var pageInteractionIdentity: PageInteractionIdentity {
        PageInteractionIdentity(width: page.width, height: page.height, runeIDs: page.runes.map(\.id))
    }

    private var pageLoadIdentity: PageGridLoadIdentity {
        .init(page: pageInteractionIdentity, packAvailable: productionPack != nil)
    }

    @ViewBuilder
    private func rootActionPopover(for mark: PlacedRune,
                                   pack: WritingDeskProductionPack) -> some View {
        let rows = 1 + (page.links.contains(where: { $0.involves(mark.id) }) ? 1 : 0)
            + (PageRules.rotate(cluster: mark.id, on: page) != nil ? 1 : 0)
        let height = CGFloat(rows * 44 + 8)
        let anchorX = CGFloat(mark.origin.column) * side
        let anchorY = CGFloat(mark.origin.row) * side
        let markWidth = CGFloat(mark.shape?.width ?? 1) * side
        let markHeight = CGFloat(mark.shape?.height ?? 1) * side
        let placeBelow = anchorY + markHeight + height <= pageSize.height
        let alignRight = anchorX + 164 > pageSize.width
        let x = alignRight ? max(0, anchorX + markWidth - 164) : anchorX
        let y = placeBelow ? anchorY + markHeight : max(0, anchorY - height)
        let variant = "\(placeBelow ? "above" : "below")\(alignRight ? "Right" : "Left")"

        ZStack {
            WritingDeskPackPopoverChrome(pack: pack, rows: rows, pointerVariant: variant,
                                          isReady: $actionChromeReady,
                                          failed: markPackUnavailable)
            if actionChromeReady {
                VStack(spacing: 0) { actions(for: mark) }.buttonStyle(.plain)
            }
        }
        .frame(width: 164, height: height)
        .offset(x: x, y: y)
        .onDisappear { actionChromeReady = false }
    }

    private func markPackUnavailable() {
        assetsReady = false
        ghost = nil
        interaction.cancel()
        assetFailure()
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

    private var containedStatusMessage: String? {
        if let error = connectionError { return error }
        if let hint = mode.hint { return hint }
        if let ghost { return fits(ghost) ? "Drag into place, then let go" : "Won't fit there" }
        if dragging != nil { return "Drag off the page to erase" }
        if let inert {
            return "\(inert.qualifier.name) says nothing about \(inert.target.name)."
        }
        if let grammarWarning { return "Loaded writing: \(grammarWarning)" }
        if isWrittenButSilent { return "Not joined — hold a Sigil to Connect." }
        return nil
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
                iconButton("xmark", "Done with this Sigil") { self.held = nil }
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
        let isAnchor = (anchor == mark.id && mode != .off) || held == mark.id
        let actionable = isActionable(mark)

        return ZStack(alignment: .topLeading) {
            if mark.personalCompound != nil {
                RuneGlyph(id: mark.glyphID, lineWidth: max(1.5, side * 0.07))
                    .frame(width: side, height: side)
                    .foregroundStyle(tint)
                    .offset(x: CGFloat(glyphCell(shape).column) * side,
                            y: CGFloat(glyphCell(shape).row) * side)
            } else if let productionPack, let visible = visibleMarksByID[mark.id] {
                WritingDeskPackMarkArtwork(
                    pack: productionPack, mark: visible,
                    overlayState: isAnchor ? "selected" : (actionable ? "legal" : nil),
                    width: CGFloat(shape?.width ?? 1) * side,
                    height: CGFloat(shape?.height ?? 1) * side,
                    failed: markPackUnavailable)
            } else {
                cells(of: shape, side: side) { cell in
                    Rectangle().fill(tint.opacity(0.16))
                        .overlay(Rectangle().stroke(tint.opacity(0.55), lineWidth: 1))
                        .frame(width: side, height: side)
                        .offset(x: CGFloat(cell.column) * side, y: CGFloat(cell.row) * side)
                }
                RuneGlyph(id: mark.glyphID, lineWidth: max(1.5, side * 0.07))
                    .frame(width: side, height: side)
                    .foregroundStyle(tint)
                    .offset(x: CGFloat(glyphCell(shape).column) * side,
                            y: CGFloat(glyphCell(shape).row) * side)
            }
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
        .accessibilityLabel("\(mark.displayName), Sigil, \(mark.cells.count) cells. Drag to move, or off the page to erase.")
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
        Button("Connect") {
            mode = .connecting
            anchor = mark.id
            held = nil
        }
        .frame(minWidth: 152, minHeight: 44)

        if page.links.contains(where: { $0.involves(mark.id) }) {
            // **One tap severs.** Entering the mode is only so you can keep going down a chain.
            Button("Disconnect") {
                mode = .disconnecting
                anchor = nil
                held = nil
            }
            .foregroundStyle(.red)
            .frame(minWidth: 152, minHeight: 44)
        }

        if PageRules.rotate(cluster: mark.id, on: page) != nil {
            Button("Turn") {
                store.rotateCluster(mark.id)
                held = nil
            }
            .frame(minWidth: 152, minHeight: 44)
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
                    ?? "Those Sigils cannot be joined."
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

        return ZStack(alignment: .topLeading) {
            if let productionPack, let visible = visibleGhost(ghost) {
                WritingDeskPackMarkArtwork(
                    pack: productionPack, mark: visible,
                    overlayState: ok ? "legal" : "illegal",
                    width: CGFloat(shape?.width ?? 1) * side,
                    height: CGFloat(shape?.height ?? 1) * side,
                    failed: markPackUnavailable)
            } else {
                cells(of: shape, side: side) { cell in
                    Rectangle().fill((ok ? Color.accentColor : Color.red).opacity(0.16))
                        .overlay(Rectangle().stroke(ok ? Color.accentColor : Color.red, lineWidth: 1))
                        .frame(width: side, height: side)
                        .offset(x: CGFloat(cell.column) * side, y: CGFloat(cell.row) * side)
                }
                RuneGlyph(id: ghost.glyph, lineWidth: max(1.5, side * 0.07))
                    .frame(width: side, height: side)
                    .foregroundStyle(ok ? Color.accentColor : Color.red)
                    .offset(x: CGFloat(glyphCell(shape).column) * side,
                            y: CGFloat(glyphCell(shape).row) * side)
            }
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

    private func visibleGhost(_ ghost: GhostRune) -> WritingDeskVisibleMark? {
        guard let shape = shape(of: ghost) else { return nil }
        let route: WritingDeskVisibleMark.VisualRoute = switch ghost.content {
        case .target: .authored(.target)
        case .source, .rune: .authored(.source)
        case .qualifier: .authored(.qualifier)
        case .compound: .authored(.compound)
        }
        return .init(rendererAssetKey: ghost.glyph, visualRoute: route,
                     id: .init(rawValue: 0), hand: store.state.base.bestHand,
                     origin: ghost.origin, shapeID: shape.id,
                     cells: shape.offsets.map {
                         PageCell(column: ghost.origin.column + $0.column,
                                  row: ghost.origin.row + $0.row)
                     }, inkRecipe: nil, displayName: "", accessibilityName: "", isReadable: true)
    }

    private func fits(_ ghost: GhostRune) -> Bool {
        guard let shape = shape(of: ghost) else { return false }
        return PageRules.canPlace(shape: shape, at: ghost.origin, on: page)
    }

}

private struct WritingDeskPackPopoverChrome: View {
    let pack: WritingDeskProductionPack
    let rows: Int
    let pointerVariant: String
    @Binding var isReady: Bool
    let failed: () -> Void
    @State private var image: UIImage?
    @State private var pointer: UIImage?

    var body: some View {
        ZStack(alignment: pointerVariant.hasSuffix("Right") ? .topTrailing : .topLeading) {
            if let image {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable(capInsets: EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
            }
            if let pointer {
                Image(uiImage: pointer).interpolation(.none).resizable()
                    .frame(width: 10, height: 6)
                    .offset(x: pointerVariant.hasSuffix("Right") ? -14 : 14,
                            y: pointerVariant.hasPrefix("above") ? -6 : 0)
            }
        }
        .task(id: "\(rows)-\(pointerVariant)") {
            do {
                let asset = try pack.popoverBody(rows: rows).asset
                let pointerAsset = try pack.popoverPointer(variant: pointerVariant)
                guard let body = UIImage(data: try pack.assetData(sha256: asset.sha256)),
                      let tip = UIImage(data: try pack.assetData(sha256: pointerAsset.sha256))
                else { throw WritingDeskProductionPack.PackError.corruptAsset(asset.sha256) }
                image = body; pointer = tip; isReady = true
            } catch { image = nil; pointer = nil; isReady = false; failed() }
        }
    }
}

private struct WritingDeskPackMarkArtwork: View {
    let pack: WritingDeskProductionPack
    let mark: WritingDeskVisibleMark
    let overlayState: String?
    let width: CGFloat
    let height: CGFloat
    let failed: () -> Void
    @State private var rgba: UIImage?
    @State private var tintMask: UIImage?
    @State private var overlay: UIImage?

    var body: some View {
        ZStack {
            if let rgba {
                Image(uiImage: rgba).interpolation(.none).resizable()
            }
            if let tintMask, let recipe = mark.inkRecipe {
                let rgb = recipe.resolvedSRGB
                Color(red: Double(rgb[0]) / 255, green: Double(rgb[1]) / 255,
                      blue: Double(rgb[2]) / 255)
                    .mask(Image(uiImage: tintMask).interpolation(.none).resizable())
            }
            if let overlay {
                Image(uiImage: overlay).interpolation(.none).resizable()
            }
        }
        .frame(width: width, height: height)
        .allowsHitTesting(false)
        .task(id: "\(mark.shapeID)-\(overlayState ?? "none")") { load() }
    }

    private func load() {
        do {
            guard case let .authored(key) = try pack.route(for: mark) else { return }
            let assets = try pack.markAssets(for: key)
            rgba = UIImage(data: try pack.assetData(sha256: assets.rgba.sha256))
            tintMask = mark.inkRecipe == nil ? nil
                : UIImage(data: try pack.assetData(sha256: assets.tintMask.sha256))
            if let overlayState {
                let asset = try pack.overlayAsset(shapeID: mark.shapeID, state: overlayState)
                overlay = UIImage(data: try pack.assetData(sha256: asset.sha256))
            } else { overlay = nil }
        } catch {
            rgba = nil; tintMask = nil; overlay = nil
            failed()
        }
    }
}

private struct WritingDeskPackLinkArtwork: View {
    let pack: WritingDeskProductionPack
    let first: WritingDeskVisibleMark
    let second: WritingDeskVisibleMark
    let cellSide: CGFloat
    let failed: () -> Void
    @State private var image: UIImage?
    @State private var placement: WritingDeskProductionPack.LinkPlacement?

    var body: some View {
        Group {
            if let image, let placement {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .frame(width: CGFloat(placement.width) * cellSide / 27,
                           height: CGFloat(placement.height) * cellSide / 27)
                    .offset(x: CGFloat(placement.topLeft.x - 5) * cellSide / 27,
                            y: CGFloat(placement.topLeft.y - 5) * cellSide / 27)
            }
        }
        .allowsHitTesting(false)
        .task(id: geometryIdentity) {
            do {
                let value = try pack.link(between: first, and: second)
                placement = value
                image = UIImage(data: try pack.assetData(sha256: value.asset.sha256))
            } catch { image = nil; placement = nil; failed() }
        }
    }

    private var geometryIdentity: String {
        [first.shapeID, second.shapeID, first.hand.rawValue, second.hand.rawValue,
         first.cells.map { "\($0.column),\($0.row)" }.joined(separator: ";"),
         second.cells.map { "\($0.column),\($0.row)" }.joined(separator: ";")]
            .joined(separator: "|")
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

struct PageInteractionIdentity: Equatable, Hashable {
    let width: Int
    let height: Int
    let runeIDs: [InstanceID]
}

struct PageGridLoadIdentity: Equatable, Hashable {
    var page: PageInteractionIdentity
    var packAvailable: Bool
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
