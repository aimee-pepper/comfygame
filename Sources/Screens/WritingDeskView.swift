import SwiftUI

enum WritingDeskSourceRules {
    static func selectedPage(afterEnteringWrite: Bool, current: InstanceID?) -> InstanceID? {
        afterEnteringWrite ? nil : current
    }
}

enum WritingDeskInteractionCancellation {
    enum Trigger: CaseIterable { case outsidePage, bin, handOrInk, pane, back, pageActions }
    static func cancel(_ trigger: Trigger, ghost: inout GhostRune?, dismissalToken: inout Int) {
        ghost = nil
        dismissalToken &+= 1
    }
}

enum WritingDeskLayout {
    /// Three readable palette identities across an ordinary 368pt phone. Four technically fit,
    /// but authored names such as Frostbound and Archipelago collapse into ellipses.
    static let paletteChipMinimumWidth: CGFloat = 104

    static func paletteColumnCount(containerWidth: CGFloat, spacing: CGFloat = 6) -> Int {
        max(1, Int((containerWidth + spacing) / (paletteChipMinimumWidth + spacing)))
    }

    struct WritePaneMetrics: Equatable {
        var pageOuterSide: CGFloat
        var pageInset: CGFloat
        var cellSide: CGFloat
        var paletteColumns: Int
    }

    static func writePaneMetrics(containerWidth: CGFloat, containerHeight: CGFloat,
                                 displayScale: CGFloat = 2) -> WritePaneMetrics {
        let horizontalRoom = min(344, floor(containerWidth - 24))
        let fixedBelowPage: CGFloat = 8 + 44 + 6 + 44 + 6 + 58
        let heightRoom = max(128, floor(containerHeight - fixedBelowPage))
        let proposed = min(horizontalRoom, heightRoom)
        let scale = max(1, displayScale)
        let cell = max(18, ((proposed * 162 / 172 / 6) * scale).rounded() / scale)
        let page = proposed
        let inset = (page - cell * 6) / 2
        return .init(pageOuterSide: page, pageInset: inset, cellSide: cell,
                     paletteColumns: containerWidth >= 344 ? 3 : 2)
    }
}

private enum WritingDeskSheet: String, Identifiable {
    case inkWell
    var id: String { rawValue }
}

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
    @Environment(\.dismiss) private var dismiss
    @Environment(\.displayScale) private var displayScale
    /// The rune picked from the palette and now hovering over the page, waiting to be dragged into
    /// place. Owned here so choosing from the scrolling list and placing on the fixed page are the
    /// same act.
    @State private var ghost: GhostRune?
    @State private var pane: Pane = .write
    @State private var selectedWorldPageID: InstanceID?
    @State private var bornAnchored = false
    @State private var tutorialLesson: TutorialLessonID?
    @State private var pageInteractionDismissalToken = 0
    @State private var isConfirmingClear = false
    @State private var showsPageActions = false
    @State private var pagesSection: PagesSection = .collected
    @State private var isNamingTemplate = false
    @State private var templateName = ""
    @State private var renamingTemplateID: PageTemplateID?
    @State private var pendingTemplateLoad: PageTemplateID?
    @State private var pendingTemplateOverwrite: PageTemplateID?
    @State private var pendingTemplateDelete: PageTemplateID?
    @State private var templateError: String?
    @State private var presentedSheet: WritingDeskSheet?
    @State private var selectedPersonalCompoundID: PersonalCompoundID?
    @State private var personalCompoundMessage: String?
    @State private var writingAssetsReady = false
    @State private var productionPack: WritingDeskProductionPack?
    @State private var writingPackUnavailable = false
#if DEBUG
    private var debugBindRailProbe: ((Bool, String) -> Void)?
    private var debugBindRailFrameProbe: ((String, CGRect) -> Void)?
#endif

    @State private var bin: Bin = .compounds

    init() {
#if DEBUG
        debugBindRailProbe = nil
        debugBindRailFrameProbe = nil
#endif
    }

#if DEBUG
    init(debugInitialPane: String, debugBornAnchored: Bool = false,
         debugSelectedWorldPageID: InstanceID? = nil,
         debugBindRailProbe: ((Bool, String) -> Void)? = nil,
         debugBindRailFrameProbe: ((String, CGRect) -> Void)? = nil) {
        _pane = State(initialValue: Pane(rawValue: debugInitialPane) ?? .write)
        _bornAnchored = State(initialValue: debugBornAnchored)
        _selectedWorldPageID = State(initialValue: debugSelectedWorldPageID)
        self.debugBindRailProbe = debugBindRailProbe
        self.debugBindRailFrameProbe = debugBindRailFrameProbe
    }
#endif

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
            case .target(let t): ContentCatalog.shared.pressureTarget(t)?.name ?? "Unknown Subject"
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
        case pages = "Pages"
        case world = "The world"
        var id: String { rawValue }
    }

    private enum PagesSection: String, CaseIterable, Identifiable {
        case collected = "Collected"
        case templates = "Templates"
        var id: String { rawValue }
    }

    private var state: GameState { store.state }
    private var draft: Page { store.writingDeskPage }

    var body: some View {
        VStack(spacing: 0) {
            writingHeader
            writingPaneTabs
            switch pane {
            case .write: writePane
            case .pages: pagesPane
            case .world: worldPane
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(WritingDeskPaperBackground())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if pane == .world { bindBar }
        }
        .toolbar(.hidden, for: .navigationBar)
        .confirmationDialog(
            "Clear this page?",
            isPresented: $isConfirmingClear,
            titleVisibility: .visible
        ) {
            Button(clearPageActionLabel, role: .destructive) {
                cancelPageInteraction(.pageActions)
                store.clearPage()
                ghost = nil
            }
            Button("Keep writing", role: .cancel) {}
        } message: {
            Text("Every placed Sigil and connection on this page will be removed.")
        }
        .modifier(TemplatePresentationModifier(
            markCount: draft.runes.count,
            isNaming: $isNamingTemplate,
            name: $templateName,
            renamingID: $renamingTemplateID,
            loadingID: $pendingTemplateLoad,
            overwritingID: $pendingTemplateOverwrite,
            deletingID: $pendingTemplateDelete,
            error: $templateError,
            save: { reportTemplateResult(store.savePageTemplate(named: $0)) },
            rename: { reportTemplateResult(store.renamePageTemplate($0, to: $1)) },
            load: performTemplateLoad,
            overwrite: { reportTemplateResult(store.overwritePageTemplate($0)) },
            delete: { reportTemplateResult(store.deletePageTemplate($0)) }))
        .sheet(item: $presentedSheet) { sheet in
            switch sheet {
            case .inkWell:
                InkWellSheet()
                    .environmentObject(store)
            }
        }
        .tutorialHoverOverlay(isPresented: tutorialLesson != nil) {
            if let id = tutorialLesson, let lesson = TutorialRules.definition(id) {
                TutorialCard(lesson: lesson,
                             gotIt: { tutorialLesson = nil },
                             notNow: { store.deferTutorial(id); tutorialLesson = nil })
            }
        }
        .onAppear {
            store.beginWritingDeskSession()
            store.reconcileStarterWorldPageBundle()
            presentWritingRequestIfNeeded()
            openWritingProductionPack()
        }
        .onDisappear {
            cancelPageInteraction(.back)
            store.endWritingDeskSession()
        }
        .onChange(of: ghost?.glyph) { _, glyph in
            guard glyph != nil else { return }
            present(.writingPageSpace)
        }
        .onChange(of: draft.runes.count) { _, count in
            if count > 0, store.state.tutorial[.writingPageSpace].status != .completed {
                store.completeTutorial(.writingPageSpace, fact: "mark_placed")
            }
        }
        .onChange(of: pane) { _, pane in
            cancelPageInteraction(.pane)
            selectedWorldPageID = WritingDeskSourceRules.selectedPage(
                afterEnteringWrite: pane == .write, current: selectedWorldPageID)
            guard pane == .world else { return }
            present(.writingPreview)
            store.completeTutorial(.writingPreview, fact: "world_pane_opened")
            store.openedComparisonPreview()
        }
        .onChange(of: bin) { _, _ in cancelPageInteraction(.bin) }
        .onChange(of: state.base.bestHand) { _, _ in cancelPageInteraction(.handOrInk) }
    }

    private var writingHeader: some View {
        HStack(spacing: 8) {
            Button { cancelPageInteraction(.back); dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .bold))
                    .frame(width: 32, height: 44)
            }
            .buttonStyle(.plain)
            .fullFacePressFeedback("writing.back")
            .accessibilityLabel("Back")

            Text("Writing Desk")
                .font(.custom("Jersey 10", size: 21))
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 8)
            if pane == .write {
                Button {
                    cancelPageInteraction(.pageActions)
                    showsPageActions = true
                } label: {
                    Image(systemName: "ellipsis")
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .fullFacePressFeedback("writing.page-actions")
                .disabled(!writingAssetsReady)
                .accessibilityLabel("Page actions")
            }
        }
        .foregroundStyle(PixelUITheme.text)
        .padding(.horizontal, 8)
        .frame(height: 52)
        .background(PixelUITheme.screen)
        .overlay(alignment: .leading) {
            Rectangle().fill(PixelUITheme.edge).frame(width: 4).padding(.vertical, 8)
        }
        .overlay(alignment: .bottom) {
            Rectangle().fill(PixelUITheme.edge).frame(height: 2)
        }
        .overlay(alignment: .topTrailing) {
            if showsPageActions, let productionPack {
                WritingDeskPageActionsPopover(
                    pack: productionPack,
                    canAct: writingAssetsReady && !draft.runes.isEmpty,
                    clearLabel: clearPageActionLabel,
                    save: {
                        showsPageActions = false
                        templateName = ""
                        isNamingTemplate = true
                    },
                    clear: {
                        showsPageActions = false
                        isConfirmingClear = true
                    }, assetFailure: writingPackFailed)
                    .offset(x: -8, y: 44)
                    .zIndex(100)
            } else if showsPageActions {
                WritingDeskNativePageActions(
                    canAct: !draft.runes.isEmpty,
                    clearLabel: clearPageActionLabel,
                    save: {
                        showsPageActions = false
                        templateName = ""
                        isNamingTemplate = true
                    },
                    clear: {
                        showsPageActions = false
                        isConfirmingClear = true
                    })
                    .offset(x: -8, y: 44)
                    .zIndex(100)
            }
        }
        .zIndex(showsPageActions ? 100 : 1)
    }

    private var clearPageActionLabel: String {
        let count = draft.runes.count
        return "Clear \(PlayerSigilCopy.count(count))"
    }

    private var writingPaneTabs: some View {
        HStack(spacing: 3) {
            ForEach(Pane.allCases) { entry in
                Button { pane = entry } label: {
                    Text(entry.rawValue)
                        .font(.custom("Tiny5", size: 10))
                        .frame(maxWidth: .infinity, minHeight: 38)
                        .foregroundStyle(PixelUITheme.text)
                        .background(pane == entry ? PixelUITheme.neutralHighlight : PixelUITheme.surfaceRaised)
                        .overlay(Rectangle().stroke(PixelUITheme.edge, lineWidth: 2))
                }
                .buttonStyle(.plain)
                .fullFacePressFeedback("writing.pane.\(entry.id)")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(PixelUITheme.screen)
    }

    // MARK: Pane 1 — writing

    /// The page is sized from the space the pane actually has, so it fills the width and can't be
    /// squeezed by the scroll view underneath it.
    private var writePane: some View {
        GeometryReader { proxy in
            let metrics = WritingDeskLayout.writePaneMetrics(
                containerWidth: proxy.size.width, containerHeight: proxy.size.height,
                displayScale: displayScale)

            VStack(spacing: 6) {
                PageGridView(ghost: $ghost, assetsReady: $writingAssetsReady,
                             productionPack: productionPack,
                             assetFailure: writingPackFailed,
                             side: metrics.cellSide, pageInset: metrics.pageInset,
                             dismissalToken: pageInteractionDismissalToken)
                    .frame(width: metrics.pageOuterSide, height: metrics.pageOuterSide)
                inkWellBar
                binTabs
                ScrollView { binContents(columns: metrics.paletteColumns).padding(.bottom, 8) }
                    .contentShape(Rectangle())
                    .background(Color.clear.contentShape(Rectangle()).onTapGesture {
                        cancelPageInteraction(.outsidePage)
                    })
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(WritingDeskWoodBackground())
        }
        .overlay(alignment: .top) {
            if writingPackUnavailable {
                Text("Writing visuals could not load; writing is still available.")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(PixelUITheme.text)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(PixelUITheme.surface.opacity(0.94))
                    .overlay(Rectangle().stroke(PixelUITheme.edge, lineWidth: 1))
                    .allowsHitTesting(false)
            }
        }
    }

    private func cancelPageInteraction(_ trigger: WritingDeskInteractionCancellation.Trigger) {
        WritingDeskInteractionCancellation.cancel(trigger,
            ghost: &ghost, dismissalToken: &pageInteractionDismissalToken)
        showsPageActions = false
    }

    private func openWritingProductionPack() {
        guard productionPack == nil, !writingPackUnavailable else { return }
        do {
            let pack = try WritingDeskProductionPack.bundled()
            try pack.open()
            productionPack = pack
            // Manifest validity is not presentation readiness. PageGrid promotes readiness only
            // after its currently interactive blank/mark/link surface has loaded successfully.
            writingAssetsReady = false
        } catch { writingPackFailed() }
    }

    private func writingPackFailed() {
        productionPack = nil
        // Visual failure must never disable the gameplay-owned writing surface.
        writingAssetsReady = true
        writingPackUnavailable = true
        cancelPageInteraction(.outsidePage)
    }

    private var inkWellBar: some View {
        let unlocked = state.base.hasCapability("inkMixing")
        let mixedCount = draft.runes.filter { $0.inkRecipe != nil }.count
        return Group {
            if let productionPack {
                WritingDeskPackToolStrip(
                    pack: productionPack, hand: state.base.bestHand,
                    title: state.base.bestHand.displayName,
                    subtitle: "Ash ink · color open", isEnabled: unlocked,
                    action: {
                        cancelPageInteraction(.handOrInk)
                        presentedSheet = .inkWell
                    }, failed: writingPackFailed)
            } else {
                Button {
                    cancelPageInteraction(.handOrInk)
                    if unlocked { presentedSheet = .inkWell }
                } label: {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(state.base.bestHand.displayName).font(.caption.weight(.semibold))
                        Text("Ash ink · color open").font(.caption2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .fullFacePressFeedback("writing.ink-well")
                .disabled(!unlocked)
            }
        }
        .frame(maxWidth: .infinity).frame(height: 44)
        .foregroundStyle(PixelUITheme.text)
        .background(PixelUITheme.surfaceInset)
        .overlay(Rectangle().stroke(PixelUITheme.edge, lineWidth: 2))
        .accessibilityLabel(unlocked ? "Ink well, \(mixedCount) mixed focuses"
                                    : "Ash ink, color left open, Ink Mixing not learned")
    }

    private var binTabs: some View {
        // One scrolling row along the bottom. Tab width is deliberately not a clean division of the
        // screen, so the next bin always peeks in at the edge — that peek, plus the fade, is what
        // makes it obvious there's more rather than leaving you to guess.
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 3) {
                ForEach(Bin.all) { entry in
                    Button { cancelPageInteraction(.bin); bin = entry } label: {
                        VStack(spacing: 2) {
                            Image(systemName: entry.icon).font(.footnote)
                            Text(entry.shortName)
                                .font(.caption2)
                                .lineLimit(1)
                        }
                        .frame(width: 76, height: 44)
                        .background(bin == entry ? PixelUITheme.edgeDark : PixelUITheme.surfaceRaised)
                        .foregroundStyle(bin == entry ? PixelUITheme.textOnEdgeDark : PixelUITheme.text)
                        .overlay(Rectangle().stroke(PixelUITheme.edge, lineWidth: 1))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .fullFacePressFeedback("writing.bin.\(entry.id)")
                }
            }
            .padding(.horizontal, 4)
        }
        .frame(height: 44)
        .background(PixelUITheme.surfaceInset)
        .overlay(Rectangle().stroke(PixelUITheme.edge, lineWidth: 2))
    }

    /// What's in the open bin.
    @ViewBuilder
    private func binContents(columns: Int) -> some View {
        switch bin {
        case .target(let id):
            let target = ContentCatalog.shared.pressureTarget(id)
            // **The word the palette never said out loud.** The eight bins are the eight things a
            // world has, and the player sees them constantly — but the category had no name, and
            // strings said *target* in one place and *subject* in another
            // (`jargon-audit.md`). Settled: **subject**, so the page reads as a sentence.
            sectionLabel("Subject")
            chips([Chip(glyph: id.rawValue, name: target?.name ?? "Unknown Subject", content: .target(id))], columns: columns)
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
                }, columns: columns)
            }
            let narrow = PageRules.writableQualifiers(for: id).filter { !$0.isGeneric }
            if !narrow.isEmpty {
                sectionLabel("Modifiers, only here")
                chips(narrow.map { Chip(glyph: $0.id.rawValue, name: $0.name, content: .qualifier($0.id)) }, columns: columns)
            }

        case .modifiers:
            // **Generic rungs only.** A narrow qualifier belongs in its own target's "Only here"
            // section — Scale lives on Relief and nowhere else, and offering it beside a Sun is how
            // "a giant sun" became a thing you could write that did nothing at all (Aimee, 6 Aug).
            ForEach(ContentCatalog.shared.qualifierLaddersInUse, id: \.self) { ladder in
                let rungs = PageRules.writableQualifiers().filter { $0.ladder == ladder && $0.isGeneric }
                if !rungs.isEmpty {
                    sectionLabel(ladder.displayName)
                    chips(rungs.map { Chip(glyph: $0.id.rawValue, name: $0.name, content: .qualifier($0.id)) }, columns: columns)
                }
            }

        case .compounds:
            if !state.base.personalCompounds.isEmpty {
                sectionLabel("My Runebook")
                personalCompoundPalette(columns: columns)
                if let record = selectedPersonalCompound {
                    personalCompoundDetail(record)
                }
            }
            ForEach(sections, id: \.target.id) { section in
                sectionLabel(section.target.name)
                chips(section.symbols.map {
                    // **Measured, not printed.** A compound used to carry a hand-typed number;
                    // it now costs what the runes inside it cost, on the same footing as the
                    // Focuses section above — what writing this one thing, alone, would do.
                    Chip(glyph: $0.id.rawValue, name: $0.name, content: .compound($0.id),
                         blockedBy: store.blockingPrimary(for: $0.id)?.name,
                         stability: BookRules.stabilityDelta(ofSymbolAlone: $0.id))
                }, columns: columns)
            }
        }
    }

    private var selectedPersonalCompound: PersonalCompoundRecord? {
        state.base.personalCompounds.first { $0.id == selectedPersonalCompoundID }
    }

    private func personalCompoundPalette(columns: Int) -> some View {
        LazyVGrid(columns: chipColumns(columns), spacing: 8) {
            ForEach(state.base.personalCompounds.sorted(by: {
                $0.creationOrdinal < $1.creationOrdinal
            })) { record in
                Button {
                    selectedPersonalCompoundID = record.id
                    personalCompoundMessage = nil
                } label: {
                    VStack(spacing: 2) {
                        RuneGlyph(id: record.target.rawValue).frame(width: 22, height: 22)
                        Text(record.nickname).font(.caption.weight(.medium)).lineLimit(1)
                        Text("\(PageRules.personalCompoundFootprint(record, hand: state.base.bestHand)) cells")
                            .font(.caption2.monospacedDigit()).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 58)
                }
                .buttonStyle(.bordered)
                .tint(selectedPersonalCompoundID == record.id ? .accentColor : .secondary)
            }
        }
    }

    private func personalCompoundDetail(_ record: PersonalCompoundRecord) -> some View {
        let footprint = PageRules.personalCompoundFootprint(record, hand: state.base.bestHand)
        let canPlace = PageRules.shape(forPersonalCompound: record, hand: state.base.bestHand)
            .map { !PageRules.validOrigins(for: $0, on: draft).isEmpty } ?? false
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(record.nickname).font(.subheadline.weight(.semibold))
                    Text(CompoundRunebookPresentation.expansion(record))
                        .font(.caption).foregroundStyle(.secondary)
                    Text(record.provenance).font(.caption2).foregroundStyle(.tertiary)
                }
                Spacer(minLength: 8)
                Button("Place") { placePersonalCompound(record) }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canPlace)
                    .frame(minHeight: 44)
            }
            Text("\(state.base.bestHand.displayName) · \(footprint) cells · Sigils saved at the time")
                .font(.caption2.monospacedDigit()).foregroundStyle(.secondary)
            if let personalCompoundMessage {
                Text(personalCompoundMessage).font(.caption2).foregroundStyle(.orange)
            }
        }
        .padding(10)
        .background(Color(.tertiarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .contain)
    }

    private func placePersonalCompound(_ record: PersonalCompoundRecord) {
        guard let shape = PageRules.shape(forPersonalCompound: record, hand: state.base.bestHand),
              let origin = PageRules.validOrigins(for: shape, on: draft).first,
              let updated = PageRules.place(record, hand: state.base.bestHand,
                                            at: origin, on: draft)
        else {
            personalCompoundMessage = "This compound does not fit in the current hand."
            return
        }
        store.replaceWritingDeskDraft(updated)
        personalCompoundMessage = nil
        cancelPageInteraction(.outsidePage)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.caption.weight(.semibold))
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 2)
    }

    // MARK: Pane 2 — what you're about to make

    private var pagesPane: some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                ForEach(PagesSection.allCases) { section in
                    Button { pagesSection = section } label: {
                        Text(section.rawValue)
                            .font(.custom("Tiny5", size: 10))
                            .frame(maxWidth: .infinity, minHeight: 38)
                            .background(pagesSection == section ? PixelUITheme.edgeDark : PixelUITheme.neutral)
                            .foregroundStyle(pagesSection == section ? PixelUITheme.screen : PixelUITheme.text)
                            .overlay(Rectangle().stroke(PixelUITheme.edge, lineWidth: 2))
                    }
                    .buttonStyle(.plain)
                    .fullFacePressFeedback("writing.pages.\(section.id)")
                }
            }
            .padding(.horizontal, 38)
            .padding(.top, 10)

            ScrollView {
                switch pagesSection {
                case .collected: collectedPagesGrid
                case .templates: templatesGrid
                }
            }
        }
    }

    @ViewBuilder private var collectedPagesGrid: some View {
        if state.base.collectedWorldPages.isEmpty {
            ContentUnavailableView("No collected pages", systemImage: "doc")
                .padding(.top, 48)
        } else {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
                ForEach(state.base.collectedWorldPages) { instance in
                    let concealsFieldPage = instance.fieldProvenance != nil && !instance.inspected
                    Button {
                        if store.inspectWorldPage(instance.id) {
                            selectedWorldPageID = instance.id
                            pane = .world
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 7) {
                            if concealsFieldPage {
                                Image(systemName: "doc.fill")
                                    .font(.system(size: 34))
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity)
                                    .aspectRatio(1, contentMode: .fit)
                                    .accessibilityHidden(true)
                            } else {
                                WorldPageReadOnlyThumbnail(page: instance.definition.page)
                                    .frame(maxWidth: .infinity)
                                    .aspectRatio(1, contentMode: .fit)
                            }
                            Text(concealsFieldPage ? "Unknown page" : instance.definition.title)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            if !concealsFieldPage {
                                Text(instance.definition.provenance)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                                if let knownFind = instance.definition.knownFind,
                                   let item = ContentCatalog.shared.item(knownFind) {
                                    Label("Known find · \(item.name)", systemImage: item.icon)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.primary)
                                } else if instance.definition.disposition == .starterUnique {
                                    Text("From an older save · no known find")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Text("Bind · \(instance.definition.worldPageCost) Essence")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tint)
                        }
                        .padding(10)
                        .background(Color(.secondarySystemGroupedBackground),
                                    in: RoundedRectangle(cornerRadius: 12))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedWorldPageID == instance.id
                                        ? Color.accentColor : Color.clear, lineWidth: 2)
                        }
                    }
                    .buttonStyle(.plain)
                    .fullFacePressFeedback("writing.collected.\(instance.id.rawValue)")
                    .accessibilityLabel("\(concealsFieldPage ? "Unknown page" : instance.definition.title), collected World Page, costs \(instance.definition.worldPageCost) Essence")
                }
            }
            .padding(12)
        }
    }

    @ViewBuilder private var templatesGrid: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(state.base.savedPageTemplates.count) of \(PageTemplateRules.capacity) Templates")
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityLabel("\(state.base.savedPageTemplates.count) of \(PageTemplateRules.capacity) Templates saved")

            if state.base.savedPageTemplates.isEmpty {
                ContentUnavailableView(
                    "No Templates",
                    systemImage: "square.grid.2x2",
                    description: Text("Write a page, then use Save Template to keep its layout."))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 36)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
                    ForEach(state.base.savedPageTemplates.sorted {
                        $0.creationOrdinal < $1.creationOrdinal
                    }) { template in
                        SavedPageTemplateCard(
                            template: template,
                            canOverwrite: !draft.runes.isEmpty,
                            load: { requestTemplateLoad(template.id) },
                            rename: {
                                templateName = template.name
                                renamingTemplateID = template.id
                            },
                            overwrite: { pendingTemplateOverwrite = template.id },
                            delete: { pendingTemplateDelete = template.id })
                    }
                }
            }
        }
        .padding(12)
    }

    private var worldPane: some View {
        ScrollView {
                if let review = store.writingDeskReviewModel(
                    selectedWorldPageID: selectedWorldPageID, bornAnchored: bornAnchored) {
                    let presentation = WritingDeskCausalPresentation.make(from: review)
                    VStack(alignment: .leading, spacing: 14) {
                        causalSourceCard(presentation)
                        causalSection("What the page says") {
                            if presentation.requests.isEmpty {
                                Text("No connected readable requests.")
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(Array(presentation.requests.enumerated()), id: \.offset) { _, request in
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(request.subject).font(.subheadline.weight(.semibold))
                                        Text(request.detail).font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                            }
                            if let copy = presentation.placedMarkState { Text(copy).font(.caption) }
                            if let copy = presentation.unreadMarkState { Text(copy).font(.caption) }
                        }
                        causalSection("What remains open") {
                            Text(presentation.uncertainty)
                        }
                        causalSection("Risk") {
                            Text(presentation.stability).font(.headline).monospacedDigit()
                            Text(presentation.collapse)
                            Text(presentation.sight)
                            if presentation.danger != presentation.sight { Text(presentation.danger) }
                        }
                        causalSection("Preparation") {
                            ForEach(presentation.preparation, id: \.self) { Text($0) }
                        }
                        DisclosureGroup("Further reading") {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(presentation.ecology)
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityIdentifier("writing.causal-review")
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .padding(.bottom, 8)
                } else {
                    ContentUnavailableView(
                        "Page unavailable",
                        systemImage: "doc.badge.ellipsis",
                        description: Text("This page changed before it could be reviewed."))
                        .accessibilityIdentifier("writing.causal-review-unavailable")
                }
        }
    }

    private func causalSourceCard(_ presentation: WritingDeskCausalPresentation) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(presentation.sourceTitle).font(.headline)
            Text(presentation.sourceState).font(.caption).foregroundStyle(.secondary)
            Text("Bind cost · \(totalCost) Essence").font(.caption.weight(.semibold))
        }
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
        .padding(10)
        .background(PixelUITheme.surfaceRaised)
        .overlay(Rectangle().stroke(PixelUITheme.edge, lineWidth: 2))
        .accessibilityIdentifier("writing.causal-source")
    }

    private func causalSection<Content: View>(
        _ title: String, @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline).accessibilityAddTraits(.isHeader)
            content().font(.callout)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

    private func chips(_ items: [Chip], columns: Int) -> some View {
        // Small tiles, four or five to a row. These were list rows with two lines of prose each,
        // which meant six sigils filled the screen — for a vocabulary of forty-one sources that is
        // a scrolling chore rather than a palette. Still a 44pt-plus target.
        LazyVGrid(columns: chipColumns(columns), spacing: 8) {
            ForEach(items) { item in
                let fits = item.blockedBy == nil && store.canWrite(item.content)
                Group {
                    if let productionPack {
                        WritingDeskPackVocabularyTile(
                            pack: productionPack, kind: packKind(item.content), id: item.glyph,
                            hand: state.base.bestHand,
                            state: !fits ? "unavailable" : (ghost?.glyph == item.glyph ? "selected" : "known"),
                            title: item.name,
                            detail: item.blockedBy != nil ? "taken" : paletteDetail(item),
                            isEnabled: fits && writingAssetsReady,
                            action: { selectPaletteItem(item, pack: productionPack) },
                            failed: writingPackFailed)
                    } else {
                        Button {
                            cancelPageInteraction(.outsidePage)
                            ghost = WritingDeskFallbackSelection.arm(
                                glyph: item.glyph, content: item.content,
                                origin: firstFreeOrigin(for: item.content))
                        } label: {
                            WritingDeskNativeVocabularyLabel(
                                title: item.name,
                                detail: item.blockedBy != nil ? "taken" : paletteDetail(item),
                                unavailable: true)
                        }
                        .buttonStyle(.plain)
                        .disabled(!fits)
                    }
                }
                .foregroundStyle(PixelUITheme.text)
                .opacity(fits ? 1 : 0.4)
            }
        }
        .frame(width: CGFloat(columns) * WritingDeskLayout.paletteChipMinimumWidth
                     + CGFloat(max(0, columns - 1)) * 8)
        .frame(maxWidth: .infinity)
    }

    private func selectPaletteItem(_ item: Chip, pack: WritingDeskProductionPack) {
        let candidate = WritingDeskFallbackSelection.arm(
            glyph: item.glyph, content: item.content,
            origin: firstFreeOrigin(for: item.content))
        guard let shape = PageRules.shape(for: item.content, hand: state.base.bestHand) else { return }
        let visualKind: WritingDeskVisibleMark.AuthoredKind = switch item.content {
        case .target: .target
        case .source, .rune: .source
        case .qualifier: .qualifier
        case .compound: .compound
        }
        let visible = WritingDeskVisibleMark(
            rendererAssetKey: item.glyph,
            visualRoute: .authored(visualKind), id: .init(rawValue: 0), hand: state.base.bestHand,
            origin: candidate.origin, shapeID: shape.id,
            cells: shape.offsets.map { .init(column: candidate.origin.column + $0.column,
                                             row: candidate.origin.row + $0.row) },
            inkRecipe: nil, displayName: "", accessibilityName: "", isReadable: true)
        do {
            guard case let .authored(key) = try pack.route(for: visible) else { return }
            let roles = try pack.markAssets(for: key)
            _ = try pack.assetData(sha256: roles.rgba.sha256)
            for state in ["legal", "illegal"] {
                let overlay = try pack.overlayAsset(shapeID: shape.id, state: state)
                _ = try pack.assetData(sha256: overlay.sha256)
            }
            cancelPageInteraction(.outsidePage)
            ghost = candidate
        } catch { writingPackFailed() }
    }

    private func chipColumns(_ count: Int) -> [GridItem] {
        Array(repeating: GridItem(.fixed(WritingDeskLayout.paletteChipMinimumWidth), spacing: 8), count: count)
    }

    private func packKind(_ content: MarkContent) -> String {
        switch content {
        case .target: "target"
        case .source, .rune: "source"
        case .qualifier: "qualifier"
        case .compound: "compound"
        }
    }

    private func paletteDetail(_ item: Chip) -> String {
        let footprint = "\(store.footprint(item.content))"
        guard let stability = item.stability, stability != 0 else { return footprint }
        return "\(footprint) · \(stability > 0 ? "+" : "")\(stability)"
    }

    private func firstFreeOrigin(for content: MarkContent) -> PageCell {
        guard let shape = PageRules.shape(for: content, hand: state.base.bestHand) else {
            return PageCell(column: 0, row: 0)
        }
        return PageRules.validOrigins(for: shape, on: draft).first
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
                        Text("Keep this world in the Atlas · +\(activeAnchoredPremium) essence")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 4)
                .accessibilityIdentifier("writing.born-anchored")
            }
            if selectedWorldPageID != nil {
                Text("Collected World Page · consumed only when departure succeeds")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Button {
                let committed = if let id = selectedWorldPageID {
                    store.bindAndDepart(worldPageInstanceID: id, bornAnchored: bornAnchored)
                } else {
                    store.bindAndDepart(bornAnchored: bornAnchored)
                }
                if committed {
                    store.completeTutorial(.writingPageRequest, fact: "first_bind")
                    store.completeTutorial(.writingBind, fact: "first_run_created")
                }
            } label: {
                HStack {
                    Label("Bind & Depart", systemImage: "book.closed.fill")
                }
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 50)
                .padding(.horizontal, 4)
            }
            .buttonStyle(.borderedProminent)
            .fullFacePressFeedback("writing.bind-depart")
            .accessibilityIdentifier("writing.bind-depart")
            .disabled(!activeBindAvailability.isReady)
            .background { debugBindFrame("capsule") }

            if let error = store.bindError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("writing.bind-error")
            }

            Text(bindFootnote)
                .font(.caption)
                .foregroundStyle(activeBindAvailability.isReady ? Color.secondary : Color.orange)
                .multilineTextAlignment(.center)
                .background { debugBindFrame("footnote") }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(.bar)
        .background { debugBindFrame("rail") }
#if DEBUG
        .onAppear {
            debugBindRailProbe?(!activeBindAvailability.isReady, bindFootnote)
        }
#endif
    }

    @ViewBuilder private func debugBindFrame(_ identity: String) -> some View {
#if DEBUG
        GeometryReader { proxy in
            Color.clear
                .onAppear { debugBindRailFrameProbe?(identity, proxy.frame(in: .global)) }
                .onChange(of: proxy.frame(in: .global)) { _, frame in
                    debugBindRailFrameProbe?(identity, frame)
                }
        }
#else
        EmptyView()
#endif
    }

    private var activeBindAvailability: BindAvailability {
        store.writingDeskReviewModel(
            selectedWorldPageID: selectedWorldPageID,
            bornAnchored: bornAnchored)?.bindAvailability
            ?? .unavailable("This page changed before it could be reviewed.")
    }

    private var totalCost: Int {
        if case .ready(let total) = activeBindAvailability { return total }
        return currentSourceCost + (bornAnchored ? activeAnchoredPremium : 0)
    }
    private var activeAnchoredPremium: Int {
        GameStore.bornAnchoredPremium(forBookCost: currentSourceCost)
    }
    private var currentSourceCost: Int {
        store.writingDeskReviewModel(
            selectedWorldPageID: selectedWorldPageID,
            bornAnchored: bornAnchored)?.costQuote ?? 0
    }
    private var costLabel: String { "\(totalCost)" }

    private var bindFootnote: String {
        if !activeBindAvailability.isReady {
            if let refusal = activeBindAvailability.refusalMessage { return refusal }
            if store.needsToRefine {
                let raw = state.base.resources[Resources.essenceRaw]
                return "You have \(state.base.essenceCrystalCount) essence and \(raw) raw. Refine it at the Essence Spring — raw essence can't be written with."
            }
            return "You have \(state.base.essenceCrystalCount) essence; this binding costs \(totalCost). Erase a Sigil or bind it without anchoring."
        }
        return "Essence \(state.base.essenceCrystalCount) → \(state.base.essenceCrystalCount - totalCost)"
    }

    private func presentWritingRequestIfNeeded() {
        guard store.state.tutorial[.writingPageRequest].status != .completed else { return }
        store.tutorialEligible(.writingPageRequest)
        present(.writingPageRequest)
    }

    private func present(_ id: TutorialLessonID) {
        guard tutorialLesson == nil, store.state.tutorial[id].status != .completed else { return }
        store.tutorialEligible(id)
        tutorialLesson = id
    }

    private func requestTemplateLoad(_ id: PageTemplateID) {
        guard let template = state.base.savedPageTemplates.first(where: { $0.id == id }) else {
            templateError = "That Template is no longer available."
            return
        }
        if !draft.runes.isEmpty,
           !PageTemplateRules.structurallyEquivalent(draft, template.page) {
            pendingTemplateLoad = id
        } else {
            performTemplateLoad(id)
        }
    }

    private func performTemplateLoad(_ id: PageTemplateID) {
        let result = store.loadPageTemplate(id)
        reportTemplateResult(result)
        guard result.succeeded else { return }
        cancelPageInteraction(.pane)
        ghost = nil
        selectedWorldPageID = nil
        pane = .write
    }

    private func reportTemplateResult(_ result: PageTemplateActionResult) {
        switch result {
        case .saved, .updated, .deleted, .loaded, .noChange:
            break
        case .emptyDraft:
            templateError = "Write at least one Sigil before saving or overwriting a Template."
        case .invalidDraft:
            templateError = "This page contains a Sigil or connection that can no longer be copied safely."
        case .capacityReached(let limit):
            templateError = "You can keep up to \(limit) Templates. Delete one before saving another."
        case .staleTemplate:
            templateError = "That Template changed or was removed before the action completed."
        }
    }
}

enum WritingDeskFallbackSelection {
    static func arm(glyph: String, content: MarkContent, origin: PageCell) -> GhostRune {
        GhostRune(glyph: glyph, content: content, origin: origin)
    }
}

private struct TemplatePresentationModifier: ViewModifier {
    let markCount: Int
    @Binding var isNaming: Bool
    @Binding var name: String
    @Binding var renamingID: PageTemplateID?
    @Binding var loadingID: PageTemplateID?
    @Binding var overwritingID: PageTemplateID?
    @Binding var deletingID: PageTemplateID?
    @Binding var error: String?
    let save: (String) -> Void
    let rename: (PageTemplateID, String) -> Void
    let load: (PageTemplateID) -> Void
    let overwrite: (PageTemplateID) -> Void
    let delete: (PageTemplateID) -> Void

    func body(content: Content) -> some View {
        content
            .alert("Save Template", isPresented: $isNaming) {
                TextField("Template name", text: $name)
                Button("Save") { save(name) }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Save this page with \(PlayerSigilCopy.count(markCount)) as a reusable layout.")
            }
            .alert("Rename Template", isPresented: optionalBinding($renamingID)) {
                TextField("Template name", text: $name)
                Button("Rename") {
                    if let id = renamingID { rename(id, name) }
                    renamingID = nil
                }
                Button("Cancel", role: .cancel) { renamingID = nil }
            }
            .confirmationDialog(
                "Replace the current page?", isPresented: optionalBinding($loadingID),
                titleVisibility: .visible
            ) {
                Button("Replace \(PlayerSigilCopy.count(markCount))", role: .destructive) {
                    if let id = loadingID { load(id) }
                    loadingID = nil
                }
                Button("Keep current page", role: .cancel) { loadingID = nil }
            } message: {
                Text("Loading this Template replaces every Sigil and connection on the current page.")
            }
            .confirmationDialog(
                "Overwrite this Template?", isPresented: optionalBinding($overwritingID),
                titleVisibility: .visible
            ) {
                Button("Overwrite Template", role: .destructive) {
                    if let id = overwritingID { overwrite(id) }
                    overwritingID = nil
                }
                Button("Cancel", role: .cancel) { overwritingID = nil }
            } message: {
                Text("Its saved layout will be replaced by the current page.")
            }
            .confirmationDialog(
                "Delete this Template?", isPresented: optionalBinding($deletingID),
                titleVisibility: .visible
            ) {
                Button("Delete Template", role: .destructive) {
                    if let id = deletingID { delete(id) }
                    deletingID = nil
                }
                Button("Cancel", role: .cancel) { deletingID = nil }
            } message: {
                Text("The current page and previously bound worlds will not change.")
            }
            .alert("Template unavailable", isPresented: Binding(
                get: { error != nil }, set: { if !$0 { error = nil } }
            )) {
                Button("OK") { error = nil }
            } message: {
                Text(error ?? "This Template could not be changed.")
            }
    }

    private func optionalBinding<T>(_ value: Binding<T?>) -> Binding<Bool> {
        Binding(get: { value.wrappedValue != nil },
                set: { if !$0 { value.wrappedValue = nil } })
    }
}

private struct SavedPageTemplateCard: View {
    let template: SavedPageTemplate
    let canOverwrite: Bool
    let load: () -> Void
    let rename: () -> Void
    let overwrite: () -> Void
    let delete: () -> Void
    @State private var showsActions = false

    var body: some View {
        Button { showsActions = true } label: {
            VStack(alignment: .leading, spacing: 7) {
                WorldPageReadOnlyThumbnail(page: template.page)
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1, contentMode: .fit)
                Text(template.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(PlayerSigilCopy.count(template.page.runes.count))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(10)
            .background(Color(.secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .fullFacePressFeedback("writing.template.\(template.id.rawValue)")
        .accessibilityLabel("\(template.name), Template, \(PlayerSigilCopy.count(template.page.runes.count))")
        .popover(isPresented: $showsActions, arrowEdge: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(template.name).font(.headline).padding(.bottom, 4)
                Button("Load", systemImage: "doc.on.doc", action: dismissing(load))
                Button("Rename", systemImage: "pencil", action: dismissing(rename))
                Button("Overwrite", systemImage: "arrow.triangle.2.circlepath",
                       action: dismissing(overwrite))
                    .disabled(!canOverwrite)
                Divider()
                Button("Delete", systemImage: "trash", role: .destructive,
                       action: dismissing(delete))
            }
            .buttonStyle(.borderless)
            .padding(16)
            .frame(idealWidth: 230)
            .presentationCompactAdaptation(.popover)
        }
    }

    private func dismissing(_ action: @escaping () -> Void) -> () -> Void {
        {
            showsActions = false
            action()
        }
    }
}

private struct InkWellSheet: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMarkID: InstanceID?
    @State private var cyan = 82.0
    @State private var magenta = 0.0
    @State private var yellow = 3.0
    @State private var depth = 7.0
    @State private var mixtureName = ""
    @State private var message: String?

    private var eligibleMarks: [PlacedRune] {
        store.writingDeskPage.runes.filter {
            $0.hand != .crude
                && $0.inkEligibleSourceID.map(InkEconomyRules.supportedSourceIDs.contains) == true
        }
    }

    private var recipe: InkRecipe? {
        let channels = [cyan, magenta, yellow, depth].map {
            UInt8(min(100, max(0, Int($0.rounded()))))
        }
        guard channels.contains(where: { $0 > 0 }) else { return nil }
        return InkRecipe(cyan: channels[0], magenta: channels[1],
                         yellow: channels[2], depth: channels[3])
    }

    private var preparedApplications: Int {
        guard let recipe else { return 0 }
        return store.state.base.preparedInkVials
            .filter { $0.recipe == recipe }
            .reduce(0) { $0 + $1.remainingApplications }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    targetCard
                    mixerCard
                    savedCard
                    preparationCard
                    if let message {
                        Text(message).font(.caption).foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Ink well")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onAppear {
            if selectedMarkID == nil { selectedMarkID = eligibleMarks.first?.id }
            loadSelectedMarkInk()
        }
        .onChange(of: selectedMarkID) { _, _ in loadSelectedMarkInk() }
    }

    private var targetCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("FOCUS").font(.caption.weight(.semibold)).foregroundStyle(.tertiary)
            if eligibleMarks.isEmpty {
                Text("Place a Brush or Fountain pen Sun, Smoke, Granite or Bloom focus first.")
                    .font(.subheadline).foregroundStyle(.secondary)
            } else {
                Picker("Focus", selection: $selectedMarkID) {
                    ForEach(eligibleMarks) { mark in
                        Text(mark.inkEligibleSourceID.flatMap { ContentCatalog.shared.pressureSource($0)?.name }
                             ?? "Unknown Focus")
                            .tag(Optional(mark.id))
                    }
                }
                .pickerStyle(.menu)
                HStack {
                    Button("Apply mixture") { applyRecipe() }
                        .buttonStyle(.borderedProminent)
                        .disabled(recipe == nil || selectedMarkID == nil)
                    Button("Return to Ash") { returnToAsh() }
                        .buttonStyle(.bordered)
                        .disabled(selectedMarkID == nil)
                }
                Button("Use for next focus") {
                    store.useInkForNextFocus(recipe)
                    message = "The next eligible focus you place will use this mixture."
                }
                .buttonStyle(.bordered)
                .disabled(recipe == nil)
                if store.state.base.nextFocusInkRecipe != nil {
                    Button("Next focus: return to Ash") {
                        store.useInkForNextFocus(nil)
                        message = "The next focus will use Ash."
                    }
                    .font(.caption)
                }
            }
        }
        .inkCard()
    }

    private var mixerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("MIX").font(.caption.weight(.semibold)).foregroundStyle(.tertiary)
            inkSwatch
            InkChannelSlider(name: "Cyan", value: $cyan)
            InkChannelSlider(name: "Magenta", value: $magenta)
            InkChannelSlider(name: "Yellow", value: $yellow)
            InkChannelSlider(name: "Depth", value: $depth)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 6) {
                ForEach(Self.presets, id: \.name) { preset in
                    Button(preset.name) { load(preset.recipe) }
                        .buttonStyle(.bordered)
                        .font(.caption2)
                }
            }
        }
        .inkCard()
    }

    private var inkSwatch: some View {
        let rgb = recipe?.resolvedSRGB ?? [32, 30, 28]
        let color = Color(red: Double(rgb[0]) / 255,
                          green: Double(rgb[1]) / 255,
                          blue: Double(rgb[2]) / 255)
        return ZStack {
            RoundedRectangle(cornerRadius: 10).fill(color)
            HStack(spacing: 7) {
                ForEach(0..<7, id: \.self) { _ in
                    Rectangle().fill(Color.white.opacity(0.42)).frame(width: 2).rotationEffect(.degrees(28))
                }
            }
            Text(recipe == nil ? "Ash · color left open" : "Mixed ink · explicit color")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .shadow(radius: 2)
        }
        .frame(height: 58)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(recipe == nil ? "Ash ink, color left open"
                            : "Mixed ink, Cyan \(Int(cyan)), Magenta \(Int(magenta)), Yellow \(Int(yellow)), Depth \(Int(depth))")
    }

    private var savedCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SAVED MIXTURES").font(.caption.weight(.semibold)).foregroundStyle(.tertiary)
            if !store.state.base.savedInkMixtures.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(store.state.base.savedInkMixtures) { mixture in
                            Button(mixture.name) { load(mixture.recipe) }
                                .buttonStyle(.bordered)
                        }
                    }
                }
            }
            HStack {
                TextField("Mixture name", text: $mixtureName)
                    .textFieldStyle(.roundedBorder)
                Button("Save") { saveMixture() }
                    .buttonStyle(.bordered)
                    .disabled(recipe == nil)
            }
        }
        .inkCard()
    }

    private var preparationCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PREPARE FOR BINDING").font(.caption.weight(.semibold)).foregroundStyle(.tertiary)
            if let recipe {
                let quote = store.inkVialPreparationQuote(recipe)
                Text("Prepared: \(preparedApplications) focus applications")
                    .font(.subheadline.weight(.semibold))
                Text(preparationSummary(quote))
                    .font(.caption).foregroundStyle(.secondary)
                Button("Prepare 12 applications") { prepare(quote) }
                    .buttonStyle(.borderedProminent)
                    .disabled(!quote.isReady)
                if let refusal = quote.refusal {
                    Text(refusal).font(.caption).foregroundStyle(.orange)
                }
            } else {
                Text("Ash is unlimited and never needs preparation.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .inkCard()
    }

    private func loadSelectedMarkInk() {
        guard let id = selectedMarkID,
              let mark = eligibleMarks.first(where: { $0.id == id }),
              let ink = mark.inkRecipe else { return }
        load(ink)
    }

    private func load(_ value: InkRecipe) {
        cyan = Double(value.cyan); magenta = Double(value.magenta)
        yellow = Double(value.yellow); depth = Double(value.depth)
    }

    private func applyRecipe() {
        guard let recipe, let selectedMarkID else { return }
        switch store.applyInkRecipe(recipe, to: selectedMarkID) {
        case .applied: message = "Mixture applied. Pigment is spent only when binding succeeds."
        case .noChange: message = "That focus already uses this mixture."
        default: message = "That focus could not be re-inked. Nothing was spent."
        }
    }

    private func returnToAsh() {
        guard let selectedMarkID else { return }
        switch store.returnMarkToAsh(selectedMarkID) {
        case .returnedToAsh: message = "Focus returned to Ash. Its world color is open again."
        case .noChange: message = "That focus already uses Ash."
        default: message = "That focus could not be changed."
        }
    }

    private func saveMixture() {
        guard let recipe else { return }
        if case .savedMixture = store.saveInkMixture(named: mixtureName, recipe: recipe) {
            message = "Mixture saved."
            mixtureName = ""
        }
    }

    private func prepare(_ quote: InkVialPreparationQuote) {
        switch store.prepareInkVial(quote) {
        case .prepared(_, let count): message = "Prepared \(count) focus applications."
        case .insufficient(let reason): message = reason
        case .staleQuote: message = "Stock changed. Review the preparation again; nothing was spent."
        case .mixingLocked: message = "Ink Mixing is not learned."
        }
    }

    private func preparationSummary(_ quote: InkVialPreparationQuote) -> String {
        let measures = PigmentBase.allCases.compactMap { base -> String? in
            let count = quote.measureCost[base] ?? 0
            return count == 0 ? nil : "\(count) \(base.rawValue.capitalized)"
        }.joined(separator: " · ")
        let resources = quote.resourcesToProcess.map { id, count in
            "\(count) \(ContentCatalog.shared.resource(id)?.name ?? "Unknown resource")"
        }.sorted().joined(separator: " · ")
        return [measures, resources.isEmpty ? nil : "process \(resources)", "1 Resin"]
            .compactMap { $0 }.joined(separator: "\n")
    }

    private static let presets: [(name: String, recipe: InkRecipe)] = [
        ("Red", .init(cyan: 0, magenta: 82, yellow: 78, depth: 12)),
        ("Yellow", .init(cyan: 0, magenta: 4, yellow: 88, depth: 5)),
        ("Green", .init(cyan: 72, magenta: 0, yellow: 76, depth: 10)),
        ("Cyan", .init(cyan: 82, magenta: 0, yellow: 3, depth: 7)),
        ("Blue", .init(cyan: 76, magenta: 68, yellow: 0, depth: 14)),
        ("Violet", .init(cyan: 48, magenta: 78, yellow: 0, depth: 12)),
        ("Dark", .init(cyan: 68, magenta: 68, yellow: 68, depth: 76))
    ]
}

private struct InkChannelSlider: View {
    let name: String
    @Binding var value: Double

    var body: some View {
        HStack(spacing: 8) {
            Text(name).font(.caption).frame(width: 58, alignment: .leading)
            Slider(value: $value, in: 0...100, step: 1)
                .accessibilityLabel(name)
                .accessibilityValue("\(Int(value)) percent")
            Text("\(Int(value))").font(.caption.monospacedDigit())
                .frame(width: 28, alignment: .trailing)
        }
    }
}

private extension View {
    func inkCard() -> some View {
        padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct WritingDeskPaperBackground: View {
    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(PixelUITheme.screen))
            var grid = Path()
            stride(from: CGFloat.zero, through: size.width, by: 8).forEach { x in
                grid.move(to: CGPoint(x: x, y: 0))
                grid.addLine(to: CGPoint(x: x, y: size.height))
            }
            stride(from: CGFloat.zero, through: size.height, by: 8).forEach { y in
                grid.move(to: CGPoint(x: 0, y: y))
                grid.addLine(to: CGPoint(x: size.width, y: y))
            }
            context.stroke(grid, with: .color(PixelUITheme.edge.opacity(0.08)), lineWidth: 0.5)
        }
        .allowsHitTesting(false)
    }
}

private struct WritingDeskWoodBackground: View {
    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)),
                         with: .color(Color(red: 0.45, green: 0.28, blue: 0.17)))
            stride(from: CGFloat.zero, through: size.width, by: 28).forEach { x in
                context.fill(Path(CGRect(x: x, y: 0, width: 10, height: size.height)),
                             with: .color(Color(red: 0.53, green: 0.33, blue: 0.20)))
            }
            context.stroke(Path(CGRect(origin: .zero, size: size)),
                           with: .color(PixelUITheme.edgeDark), lineWidth: 3)
        }
        .allowsHitTesting(false)
    }
}

private struct WorldPageReadOnlyThumbnail: View {
    let page: Page

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width / CGFloat(page.width),
                           proxy.size.height / CGFloat(page.height))
            ZStack(alignment: .topLeading) {
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(side), spacing: 0),
                                         count: page.width), spacing: 0) {
                    ForEach(0..<(page.width * page.height), id: \.self) { _ in
                        Rectangle().fill(Color(.systemBackground))
                            .border(Color.secondary.opacity(0.15), width: 0.5)
                            .frame(width: side, height: side)
                    }
                }
                ForEach(page.runes) { rune in
                    RuneGlyph(id: glyphID(for: rune.content))
                        .frame(width: side * 0.75, height: side * 0.75)
                        .offset(x: CGFloat(rune.origin.column) * side + side * 0.125,
                                y: CGFloat(rune.origin.row) * side + side * 0.125)
                }
            }
            .frame(width: side * CGFloat(page.width), height: side * CGFloat(page.height))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .accessibilityHidden(true)
    }

    private func glyphID(for content: MarkContent) -> String {
        switch content {
        case .target(let id): id.rawValue
        case .source(let id): id.rawValue
        case .qualifier(let id): id.rawValue
        case .compound(let id): id.rawValue
        case .rune(let sigil): sigil.source.rawValue
        }
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

/// Pack-owned two-row chrome with native text/actions. It is loaded only when Write's trailing
/// page-actions button opens; no production-pack I/O occurs during app launch.
private struct WritingDeskPageActionsPopover: View {
    let pack: WritingDeskProductionPack
    let canAct: Bool
    let clearLabel: String
    let save: () -> Void
    let clear: () -> Void
    let assetFailure: () -> Void
    @State private var bodyImage: UIImage?
    @State private var pointerImage: UIImage?
    @State private var failed = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let bodyImage {
                Image(uiImage: bodyImage)
                    .interpolation(.none)
                    .resizable(capInsets: EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
                    .frame(width: 164, height: 96)
            }
            if bodyImage != nil, pointerImage != nil {
                VStack(spacing: 0) {
                    Button("Save Template", action: save)
                        .disabled(!canAct)
                        .frame(width: 164, height: 44)
                    Button(clearLabel, action: clear)
                        .disabled(!canAct)
                        .foregroundStyle(PixelUITheme.danger)
                        .frame(width: 164, height: 44)
                }
                .padding(.top, 4)
            } else if failed {
                Text("Writing assets unavailable")
                    .font(.caption2)
                    .frame(width: 164, height: 96)
                    .background(PixelUITheme.surface)
            } else {
                ProgressView().frame(width: 164, height: 96)
            }
            if let pointerImage {
                Image(uiImage: pointerImage)
                    .interpolation(.none)
                    .resizable()
                    .frame(width: 10, height: 6)
                    .offset(x: -14, y: -6)
            }
        }
        .frame(width: 164, height: 96)
        .buttonStyle(.plain)
        .fullFacePressFeedback("writing.page-actions-popover")
        .task { loadPackChrome() }
    }

    private func loadPackChrome() {
        guard bodyImage == nil else { return }
        do {
            let body = try pack.popoverBody(rows: 2).asset
            let pointer = try pack.popoverPointer(variant: "aboveRight")
            bodyImage = UIImage(data: try pack.assetData(sha256: body.sha256))
            pointerImage = UIImage(data: try pack.assetData(sha256: pointer.sha256))
        } catch {
            bodyImage = nil
            pointerImage = nil
            failed = true
            assetFailure()
        }
    }
}

private struct WritingDeskPackToolStrip: View {
    let pack: WritingDeskProductionPack
    let hand: Hand
    let title: String
    let subtitle: String
    let isEnabled: Bool
    let action: () -> Void
    let failed: () -> Void
    @State private var image: UIImage?
    @State private var reserve: WritingDeskProductionPack.Rect?

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topLeading) {
                if let image { Image(uiImage: image).interpolation(.none).resizable() }
                if let reserve {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(title).font(.custom("Tiny5", size: 11)).lineLimit(1)
                        Text(subtitle).font(.custom("Tiny5", size: 9)).lineLimit(1)
                    }
                    .frame(width: CGFloat(reserve.width) * 2, height: CGFloat(reserve.height) * 2,
                           alignment: .leading)
                    .offset(x: CGFloat(reserve.x) * 2, y: CGFloat(reserve.y) * 2)
                }
            }
        }
        .buttonStyle(.plain)
        .fullFacePressFeedback("writing.ink-well")
        .disabled(image == nil || !isEnabled)
        .frame(height: 44)
        .task(id: hand) { load() }
    }

    private func load() {
        do {
            let spec = try pack.toolStripSpec(hand: hand, usesMixedInk: false)
            guard let loaded = UIImage(data: try pack.assetData(sha256: spec.assets.rgba.sha256))
            else { throw WritingDeskProductionPack.PackError.corruptAsset(spec.assets.rgba.sha256) }
            image = loaded
            reserve = spec.runtimeTextReserve
        } catch { image = nil; reserve = nil; failed() }
    }
}

private struct WritingDeskPackVocabularyTile: View {
    let pack: WritingDeskProductionPack
    let kind: String
    let id: String
    let hand: Hand
    let state: String
    let title: String
    let detail: String
    let isEnabled: Bool
    let action: () -> Void
    let failed: () -> Void
    @State private var image: UIImage?

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                if let image { Image(uiImage: image).interpolation(.none).resizable() }
                // Player-facing identity is native text, never information encoded only in a
                // temporary sprite. It remains present during loading and in refusal states.
                WritingDeskNativeVocabularyLabel(
                    title: title, detail: detail, unavailable: image == nil)
            }
        }
        .buttonStyle(.plain)
        .fullFacePressFeedback("writing.vocabulary.\(kind).\(id)")
        .disabled(image == nil || !isEnabled)
        .frame(height: 58)
        .task(id: "\(kind)-\(id)-\(hand)-\(state)") { load() }
    }

    private func load() {
        do {
            let asset = try pack.vocabularyAsset(kind: kind, id: id, hand: hand, state: state)
            guard let loaded = UIImage(data: try pack.assetData(sha256: asset.sha256))
            else { throw WritingDeskProductionPack.PackError.corruptAsset(asset.sha256) }
            image = loaded
        } catch { image = nil; failed() }
    }
}

private struct WritingDeskNativeVocabularyLabel: View {
    let title: String
    let detail: String
    let unavailable: Bool

    var body: some View {
        HStack(spacing: 0) {
            // The pack reserves an 18x21 logical glyph well at the left (36x42 at 2x).
            // Player identity text owns the remaining region and can never cross those pixels.
            Color.clear.frame(width: 38)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.custom("Tiny5", size: 10)).lineLimit(2)
                Text(detail).font(.custom("Tiny5", size: 8)).lineLimit(1)
            }
            .padding(.horizontal, 3).padding(.vertical, 3)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .background(PixelUITheme.surface.opacity(0.94))
        }
        .foregroundStyle(PixelUITheme.text)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(unavailable ? PixelUITheme.surfaceRaised : Color.clear)
    }
}

private struct WritingDeskNativePageActions: View {
    let canAct: Bool
    let clearLabel: String
    let save: () -> Void
    let clear: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button("Save Template", action: save).disabled(!canAct)
                .frame(width: 164, height: 44)
            Button(clearLabel, action: clear).disabled(!canAct)
                .foregroundStyle(PixelUITheme.danger)
                .frame(width: 164, height: 44)
        }
        .buttonStyle(.plain)
        .padding(4)
        .background(PixelUITheme.surface)
        .overlay(Rectangle().stroke(PixelUITheme.edge, lineWidth: 2))
    }
}

#Preview {
    NavigationStack {
        WritingDeskView().environmentObject(GameStore(io: .temporary(name: "preview-desk")))
    }
}
