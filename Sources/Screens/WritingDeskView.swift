import SwiftUI

/// Compose a book, see what it will cost you and what it will become, then commit.
///
/// **Two panes.** *Write* is the page and the vocabulary — the page fixed at the top, never
/// scrolling, with the runes you know scrolling beneath it. *The world* is what you're about to
/// make: its description, its numbers, and the button that commits to it.
///
/// Splitting them keeps each one whole on a phone screen. Composing is a spatial job that wants the
/// page big and everything else out of the way; deciding whether to go is a reading job. Trying to
/// do both at once left the page squeezed into a third of the screen and the projection half
/// off-stage.
struct WritingDeskView: View {
    @EnvironmentObject private var store: GameStore
    @State private var editingSlot: SlotID?
    /// The rune picked from the palette and now hovering over the page, waiting to be dragged into
    /// place. Owned here so choosing from the scrolling list and placing on the fixed page are the
    /// same act.
    @State private var ghost: GhostRune?
    @State private var pane: Pane = .write

    @State private var bin: Bin = .compounds

    /// One bin per pressure target, plus compounds and the ladders that apply everywhere.
    ///
    /// A target's bin holds **everything you'd write about that target**: the target sigil itself,
    /// every source that pushes on it, and any modifier that only makes sense there. So writing
    /// about light means opening one bin, not hunting across three lists.
    private enum Bin: Hashable, Identifiable {
        case target(PressureTargetID)
        case modifiers
        case compounds

        var id: String {
            switch self {
            case .target(let t): t.rawValue
            case .modifiers: "modifiers"
            case .compounds: "compounds"
            }
        }

        static var all: [Bin] {
            ContentCatalog.shared.pressureTargetsInOrder.map { .target($0.id) } + [.modifiers, .compounds]
        }

        var shortName: String {
            switch self {
            case .target(let t): ContentCatalog.shared.pressureTarget(t)?.name ?? t.rawValue
            case .modifiers: "Modifiers"
            case .compounds: "Compounds"
            }
        }

        var icon: String {
            switch self {
            case .target(let t): ContentCatalog.shared.pressureTarget(t)?.icon ?? "circle"
            case .modifiers: "slider.horizontal.3"
            case .compounds: "square.stack.3d.up"
            }
        }
    }

    private enum Pane: String, CaseIterable, Identifiable {
        case write = "Write"
        case world = "The world"
        var id: String { rawValue }
    }

    private var state: GameState { store.state }
    private var projection: BookProjection { store.bookProjection }

    var body: some View {
        VStack(spacing: 0) {
            switch pane {
            case .write: writePane
            case .world: worldPane
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // The pane switch *is* the title. A title bar and a picker underneath it were two rows
            // spending screen on saying where you are twice.
            ToolbarItem(placement: .principal) {
                Picker("", selection: $pane) {
                    ForEach(Pane.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .frame(width: 220)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Clear") { store.clearPage(); ghost = nil }
                    .disabled(state.base.page.runes.isEmpty)
            }
        }
    }

    // MARK: Pane 1 — writing

    /// The page is sized from the space the pane actually has, so it fills the width and can't be
    /// squeezed by the scroll view underneath it.
    private var writePane: some View {
        GeometryReader { proxy in
            let available = proxy.size.width - 24
            let byWidth = available / CGFloat(state.base.page.width)
            let byHeight = (proxy.size.height * 0.46) / CGFloat(state.base.page.height)
            let side = floor(min(byWidth, byHeight))

            VStack(spacing: 6) {
                PageGridView(ghost: $ghost, side: side)
                ScrollView { binContents }
                binTabs
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 2)
        }
    }

    private var binTabs: some View {
        // One scrolling row along the bottom. Tab width is deliberately not a clean division of the
        // screen, so the next bin always peeks in at the edge — that peek, plus the fade, is what
        // makes it obvious there's more rather than leaving you to guess.
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 3) {
                ForEach(Bin.all) { entry in
                    Button { bin = entry } label: {
                        VStack(spacing: 2) {
                            Image(systemName: entry.icon).font(.footnote)
                            Text(entry.shortName)
                                .font(.system(size: 9))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(width: 66, height: 40)
                        .background(bin == entry ? Color.accentColor.opacity(0.18) : Color.clear,
                                    in: RoundedRectangle(cornerRadius: 8))
                        .foregroundStyle(bin == entry ? Color.accentColor : Color.secondary)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
        }
        .frame(height: 46)
        .mask(
            // Fades at both ends, so a cut-off tab reads as "keep going" rather than as a bug.
            LinearGradient(stops: [.init(color: .clear, location: 0),
                                   .init(color: .black, location: 0.035),
                                   .init(color: .black, location: 0.965),
                                   .init(color: .clear, location: 1)],
                           startPoint: .leading, endPoint: .trailing)
        )
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
    }

    /// What's in the open bin.
    @ViewBuilder
    private var binContents: some View {
        switch bin {
        case .target(let id):
            let target = ContentCatalog.shared.pressureTarget(id)
            // **The word the palette never said out loud.** The eight bins are the eight things a
            // world has, and the player sees them constantly — but the category had no name, and
            // strings said *target* in one place and *subject* in another
            // (`jargon-audit.md`). Settled: **subject**, so the page reads as a sentence.
            sectionLabel("Subject")
            chips([Chip(glyph: id.rawValue, name: target?.name ?? id.rawValue, content: .target(id))])
            // Only what can be *bound* here. Filtering on "affects this target at all" put rain
            // under Illumination because rain dims light — true, and not something you'd ever write.
            let sources = ContentCatalog.shared.pressureSources
                .filter { $0.canAttach(to: id) }
                .sorted { $0.name < $1.name }
            if !sources.isEmpty {
                // **Focuses**, settled 6 Aug (`vocabulary-settled.md`). A page reads as a sentence:
                // a subject, its main focus, and modifiers. "Causes" was my word and Aimee's answer
                // was that it doesn't make sense.
                sectionLabel("Focuses")
                chips(sources.map {
                    Chip(glyph: $0.id.rawValue, name: $0.name, content: .source($0.id),
                         stability: store.stabilityOfWriting($0.id, on: id))
                })
            }
            let narrow = ContentCatalog.shared.qualifiers.filter { !$0.isGeneric && $0.applies(to: id) }
            if !narrow.isEmpty {
                sectionLabel("Modifiers, only here")
                chips(narrow.map { Chip(glyph: $0.id.rawValue, name: $0.name, content: .qualifier($0.id)) })
            }

        case .modifiers:
            // **Generic rungs only.** A narrow qualifier belongs in its own target's "Only here"
            // section — Scale lives on Relief and nowhere else, and offering it beside a Sun is how
            // "a giant sun" became a thing you could write that did nothing at all (Aimee, 6 Aug).
            ForEach(ContentCatalog.shared.qualifierLaddersInUse, id: \.self) { ladder in
                let rungs = ContentCatalog.shared.qualifiers(on: ladder).filter(\.isGeneric)
                if !rungs.isEmpty {
                    sectionLabel(ladder.displayName)
                    chips(rungs.map { Chip(glyph: $0.id.rawValue, name: $0.name, content: .qualifier($0.id)) })
                }
            }

        case .compounds:
            ForEach(sections, id: \.target.id) { section in
                sectionLabel(section.target.name)
                chips(section.symbols.map {
                    // **Measured, not printed.** A compound used to carry a hand-typed number;
                    // it now costs what the runes inside it cost, on the same footing as the
                    // Focuses section above — what writing this one thing, alone, would do.
                    Chip(glyph: $0.id.rawValue, name: $0.name, content: .compound($0.id),
                         blockedBy: store.blockingPrimary(for: $0.id)?.name,
                         stability: BookRules.stabilityDelta(ofSymbolAlone: $0.id))
                })
            }
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 9).weight(.semibold))
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 2)
    }

    // MARK: Pane 2 — what you're about to make

    private var worldPane: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 12) {
                    PreviewPanel(projection: projection, discovery: state.reality.discovery)
                    if state.base.page.runes.isEmpty { blankPageNote }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
            bindBar
        }
    }

    // MARK: The palette

    /// What you know how to write. Selecting one arms the page; tapping a cell places it.
    ///
    /// Deliberately shows the footprint: what a mark *costs in space* is the decision the page
    /// exists to create, and it changes with the hand you're writing in.
    private struct Chip: Identifiable {
        var glyph: String
        var name: String
        var content: MarkContent
        var blockedBy: String?
        /// **What writing this does to the meter**, if anything. Shown on the tile so a book can be
        /// planned by reading the palette rather than by writing something, tabbing to The World to
        /// see what it cost, and tabbing back.
        var stability: Int?
        var id: String { glyph }
    }

    private func chips(_ items: [Chip]) -> some View {
        // Small tiles, four or five to a row. These were list rows with two lines of prose each,
        // which meant six sigils filled the screen — for a vocabulary of forty-one sources that is
        // a scrolling chore rather than a palette. Still a 44pt-plus target.
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 74), spacing: 4)], spacing: 4) {
            ForEach(items) { item in
                let fits = item.blockedBy == nil && store.canWrite(item.content)
                Button {
                    ghost = GhostRune(glyph: item.glyph, content: item.content,
                                      origin: firstFreeOrigin(for: item.content))
                } label: {
                    VStack(spacing: 1) {
                        RuneGlyph(id: item.glyph).frame(width: 20, height: 20)
                        Text(item.name)
                            .font(.system(size: 9).weight(.medium))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                        // Two bare numbers: what it costs in space, and what it does to the meter.
                        // The words were repeated forty times down the screen to say what the
                        // numbers already say.
                        if let blocked = item.blockedBy, !blocked.isEmpty {
                            Text("taken")
                                .font(.system(size: 8))
                                .foregroundStyle(.secondary)
                        } else {
                            HStack(spacing: 4) {
                                Text("\(store.footprint(item.content))")
                                    .foregroundStyle(.secondary)
                                if let stability = item.stability, stability != 0 {
                                    Text(stability > 0 ? "+\(stability)" : "\(stability)")
                                        .foregroundStyle(stability > 0 ? Color.green : Color.orange)
                                }
                            }
                            .font(.system(size: 8).monospacedDigit())
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.bordered)
                .tint(ghost?.glyph == item.glyph ? .accentColor : .secondary)
                .opacity(fits ? 1 : 0.4)
                .disabled(!fits)
            }
        }
    }

    private func firstFreeOrigin(for content: MarkContent) -> PageCell {
        guard let shape = PageRules.shape(for: content, hand: state.base.bestHand) else {
            return PageCell(column: 0, row: 0)
        }
        return PageRules.validOrigins(for: shape, on: state.base.page).first
            ?? PageCell(column: 0, row: 0)
    }

    /// The palette is sectioned **by pressure target** (session 11 §2), which is the same axis
    /// exclusivity runs on — so the vocabulary's organisation and its grammar are one thing, and
    /// "one per section" is a rule you can read straight off the screen.
    private var sections: [(target: PressureTargetDef, symbols: [SymbolDef])] {
        let owned = ContentCatalog.shared.symbols
            .filter { state.base.ownedSymbols.contains($0.id) }
        return ContentCatalog.shared.pressureTargetsInOrder.compactMap { target in
            let symbols = owned
                .filter { $0.primaryTarget == target.id }
                .sorted { $0.name < $1.name }
            return symbols.isEmpty ? nil : (target, symbols)
        }
    }

    private var blankPageNote: some View {
        Text("A blank page still binds. Everything you don't say, the world decides for itself.")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Slots — the old taxonomy, no longer the composition surface

    private var slotGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            ForEach(projection.slotPlans) { plan in
                Button {
                    editingSlot = plan.slot
                } label: {
                    SlotCard(plan: plan)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var chanceNote: some View {
        Label {
            Text("Empty slots are filled at random when the book is bound, and cost a flat \(Tuning.Book.randomSlotCostEssence) each however they roll. You know the price now; you find out what you bought when you arrive.")
        } icon: {
            Image(systemName: "dice")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: Bind

    private var bindBar: some View {
        VStack(spacing: 6) {
            Button {
                store.bindAndDepart()
            } label: {
                HStack {
                    Label("Bind & Depart", systemImage: "book.closed.fill")
                    Spacer()
                    Text(costLabel).monospacedDigit()
                }
                .font(.headline)
                .frame(minHeight: 56)
                .padding(.horizontal, 4)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!store.canBindAndDepart)

            Text(bindFootnote)
                .font(.caption)
                .foregroundStyle(store.canBindAndDepart ? Color.secondary : Color.orange)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(.bar)
    }

    private var costLabel: String { "\(projection.cost)" }

    private var bindFootnote: String {
        if !store.canBindAndDepart {
            if store.needsToRefine {
                let raw = state.base.resources[Resources.essenceRaw]
                return "You have \(state.base.essence) essence and \(raw) raw. Refine it at the Workshop — raw essence can't be written with."
            }
            return "You have \(state.base.essence) essence; this book costs \(projection.cost). Leave slots to chance to write something cheaper."
        }
        let count = projection.randomSlots.count
        if count > 0 {
            return "Costs \(projection.cost) of your \(state.base.essence) — including \(count) slot\(count == 1 ? "" : "s") left to chance at \(Tuning.Book.randomSlotCostEssence) each."
        }
        return "Costs \(projection.cost) essence of your \(state.base.essence)."
    }
}

// MARK: - Slot card

private struct SlotCard: View {
    let plan: BookProjection.SlotPlan

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(slotName.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(plan.chosen == nil ? Color.secondary : Color.accentColor)
                    .frame(width: 26)
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(plan.chosen == nil ? .secondary : .primary)
                    .lineLimit(1)
            }

            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2, reservesSpace: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 92)
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(plan.chosen == nil ? Color.secondary.opacity(0.25) : Color.accentColor.opacity(0.5),
                              style: StrokeStyle(lineWidth: 1.5, dash: plan.chosen == nil ? [4, 3] : []))
        )
    }

    private var slotName: String {
        ContentCatalog.shared.slot(plan.slot)?.name ?? plan.slot.rawValue
    }

    private var icon: String {
        if let chosen = plan.chosen { return chosen.icon }
        return plan.isEmpty ? "nosign" : "dice"
    }

    private var title: String {
        if let chosen = plan.chosen { return chosen.name }
        return plan.isEmpty ? "Nothing to draw on" : "Left to chance"
    }

    private var subtitle: String {
        if let chosen = plan.chosen { return chosen.blurb }
        if plan.isEmpty { return "Nothing could fill this." }
        return "Any of \(plan.candidates.count) — including things you can't write yet."
    }
}

// MARK: - Symbol picker

private struct SymbolPickerView: View {
    @EnvironmentObject private var store: GameStore
    let slot: SlotID
    let chosen: SymbolID?
    let onPick: (SymbolID?) -> Void

    @Environment(\.dismiss) private var dismiss

    private var owned: [SymbolDef] {
        BookRules.writable(in: slot, ownedSymbols: store.state.base.ownedSymbols)
    }

    private var slotName: String {
        ContentCatalog.shared.slot(slot)?.name ?? slot.rawValue
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button { onPick(nil) } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "dice").frame(width: 26)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Leave to chance").font(.body)
                                Text("Filled at random when you bind").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if chosen == nil { Image(systemName: "checkmark").foregroundStyle(.tint) }
                        }
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                Section("Your \(slotName.lowercased()) symbols") {
                    ForEach(owned) { symbol in
                        Button { onPick(symbol.id) } label: {
                            SymbolRow(symbol: symbol, isChosen: symbol.id == chosen)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle(slotName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

private struct SymbolRow: View {
    let symbol: SymbolDef
    let isChosen: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol.icon)
                .font(.body)
                .frame(width: 26)
                .foregroundStyle(.tint)

            VStack(alignment: .leading, spacing: 2) {
                Text(symbol.name).font(.body)
                Text(symbol.blurb).font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 10) {
                    Label("\(symbol.essenceCost)", systemImage: "drop")
                    StabilityTag(delta: BookRules.stabilityDelta(ofSymbolAlone: symbol.id))
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.top, 1)
            }

            Spacer(minLength: 8)
            if isChosen { Image(systemName: "checkmark").foregroundStyle(.tint) }
        }
        .frame(minHeight: 44)
        .contentShape(Rectangle())
    }
}

/// Stability is the whole risk/reward dial, and this prints it **in the same units as the
/// headline** — pick this symbol and the Stability number moves by exactly this much. Anything
/// else turns composing a book into guesswork.
struct StabilityTag: View {
    let delta: Int

    var body: some View {
        Label(text, systemImage: delta > 0 ? "shield" : (delta == 0 ? "equal" : "flame"))
            .foregroundStyle(color)
    }

    private var text: String {
        switch delta {
        case 0: "no cost"
        case 1...: "+\(delta) stability"
        default: "\(delta) stability" // already carries its minus sign
        }
    }

    private var color: Color {
        switch delta {
        case 1...: .green
        case 0: .secondary
        case (-20)...(-1): .orange
        default: .red
        }
    }
}

#Preview {
    NavigationStack {
        WritingDeskView().environmentObject(GameStore(io: .temporary(name: "preview-desk")))
    }
}
