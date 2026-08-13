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
    /// The rune picked from the palette and now hovering over the page, waiting to be dragged into
    /// place. Owned here so choosing from the scrolling list and placing on the fixed page are the
    /// same act.
    @State private var ghost: GhostRune?
    @State private var pane: Pane = .write
    @State private var bornAnchored = false
    @State private var tutorialLesson: TutorialLessonID?
    @State private var pageInteractionDismissalToken = 0

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
                Button("Clear") {
                    dismissPageInteraction()
                    store.clearPage()
                    ghost = nil
                }
                    .disabled(state.base.page.runes.isEmpty)
            }
        }
        .tutorialHoverOverlay(isPresented: tutorialLesson != nil) {
            if let id = tutorialLesson, let lesson = TutorialRules.definition(id) {
                TutorialCard(lesson: lesson,
                             gotIt: { tutorialLesson = nil },
                             notNow: { store.deferTutorial(id); tutorialLesson = nil })
            }
        }
        .onAppear { presentWritingRequestIfNeeded() }
        .onDisappear { dismissPageInteraction() }
        .onChange(of: ghost?.glyph) { _, glyph in
            guard glyph != nil else { return }
            present(.writingPageSpace)
        }
        .onChange(of: state.base.page.runes.count) { _, count in
            if count > 0 { store.completeTutorial(.writingPageSpace, fact: "mark_placed") }
        }
        .onChange(of: pane) { _, pane in
            dismissPageInteraction()
            guard pane == .world else { return }
            present(.writingPreview)
            store.completeTutorial(.writingPreview, fact: "world_pane_opened")
            store.openedComparisonPreview()
        }
        .onChange(of: bin) { _, _ in dismissPageInteraction() }
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
                PageGridView(ghost: $ghost, side: side,
                             dismissalToken: pageInteractionDismissalToken)
                ScrollView { binContents }
                    .contentShape(Rectangle())
                    .simultaneousGesture(TapGesture().onEnded { dismissPageInteraction() })
                binTabs
                    .simultaneousGesture(TapGesture().onEnded { dismissPageInteraction() })
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 2)
        }
    }

    private func dismissPageInteraction() {
        pageInteractionDismissalToken &+= 1
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
            // **Only what you've learned.** Hidden rather than shown-and-locked, matching how the
            // compounds bin has always treated `ownedSymbols`: a word you don't have isn't a thing
            // to want, it's a thing you haven't met yet.
            let sources = ContentCatalog.shared.pressureSources
                .filter { $0.canAttach(to: id) }
                .filter { store.state.base.ownedSources.contains($0.id) }
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
            let narrow = PageRules.writableQualifiers(for: id).filter { !$0.isGeneric }
            if !narrow.isEmpty {
                sectionLabel("Modifiers, only here")
                chips(narrow.map { Chip(glyph: $0.id.rawValue, name: $0.name, content: .qualifier($0.id)) })
            }

        case .modifiers:
            // **Generic rungs only.** A narrow qualifier belongs in its own target's "Only here"
            // section — Scale lives on Relief and nowhere else, and offering it beside a Sun is how
            // "a giant sun" became a thing you could write that did nothing at all (Aimee, 6 Aug).
            ForEach(ContentCatalog.shared.qualifierLaddersInUse, id: \.self) { ladder in
                let rungs = PageRules.writableQualifiers().filter { $0.ladder == ladder && $0.isGeneric }
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

    private var bindBar: some View {
        VStack(spacing: 6) {
            if state.base.station(Stations.anchorage).isUnlocked {
                Toggle(isOn: $bornAnchored) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Born anchored").font(.subheadline.weight(.semibold))
                        Text("Keep this world in the Atlas · +\(store.bornAnchoredPremium) essence")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 4)
                .accessibilityIdentifier("writing.born-anchored")
            }
            Button {
                if store.bindAndDepart(bornAnchored: bornAnchored) {
                    store.completeTutorial(.writingPageRequest, fact: "first_bind")
                    store.completeTutorial(.writingBind, fact: "first_run_created")
                }
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
            .disabled(!store.canBindAndDepart(bornAnchored: bornAnchored))

            if let error = store.bindError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("writing.bind-error")
            }

            Text(bindFootnote)
                .font(.caption)
                .foregroundStyle(store.canBindAndDepart(bornAnchored: bornAnchored) ? Color.secondary : Color.orange)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(.bar)
    }

    private var totalCost: Int { projection.cost + (bornAnchored ? store.bornAnchoredPremium : 0) }
    private var costLabel: String { "\(totalCost)" }

    private var bindFootnote: String {
        if !store.canBindAndDepart(bornAnchored: bornAnchored) {
            if store.needsToRefine {
                let raw = state.base.resources[Resources.essenceRaw]
                return "You have \(state.base.essence) essence and \(raw) raw. Refine it at the Essence Spring — raw essence can't be written with."
            }
            return "You have \(state.base.essence) essence; this binding costs \(totalCost). Erase a mark or bind it without anchoring."
        }
        return "Costs \(totalCost) essence of your \(state.base.essence)."
    }

    private func presentWritingRequestIfNeeded() {
        store.tutorialEligible(.writingPageRequest)
        present(.writingPageRequest)
    }

    private func present(_ id: TutorialLessonID) {
        guard tutorialLesson == nil, store.state.tutorial[id].status != .completed else { return }
        store.tutorialEligible(id)
        tutorialLesson = id
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
