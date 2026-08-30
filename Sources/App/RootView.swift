import SwiftUI

enum RootPresentationRules {
    enum Surface: Equatable { case arrival, encounter, world, base }
    static func surface(hasArrival: Bool, hasEncounter: Bool, isInRun: Bool) -> Surface {
        if hasArrival { return .arrival }
        if hasEncounter { return .encounter }
        if isInRun { return .world }
        return .base
    }
}

enum RootNavigationRules {
    static func homePath(afterRunTransitionFrom wasInRun: Bool, to isInRun: Bool,
                         current: [AppRoute]) -> [AppRoute] {
        wasInRun && !isInRun ? [] : current
    }
}

enum RunExitRecapPresentation {
    static func resources(in lines: [RunExitSummary.ReceiptLine]) -> [RunExitSummary.ReceiptLine] {
        lines.filter {
            switch $0 {
            case .resource, .materialSample: true
            case .legacy(let line): line.stableID.contains("resource-")
            case .stackableItem, .uniqueItem: false
            }
        }
    }

    static func items(in lines: [RunExitSummary.ReceiptLine]) -> [RunExitSummary.ReceiptLine] {
        lines.filter {
            switch $0 {
            case .stackableItem, .uniqueItem: true
            case .legacy(let line): !line.stableID.contains("resource-")
            case .resource, .materialSample: false
            }
        }
    }
}

struct RunExitPermanentGainsPresentation: Equatable {
    struct Cell: Equatable, Identifiable {
        let id: String
        let heading: String
        let value: String
        let detail: String?
    }

    let cells: [Cell]

    init(summary: RunExitSummary, catalogue: ContentCatalog = .shared) {
        var cells: [Cell] = []
        let writingCount = summary.pages.count + summary.writings.count
        if writingCount > 0 {
            cells.append(.init(
                id: "writing", heading: "Writing found",
                value: "\(writingCount) \(writingCount == 1 ? "piece" : "pieces") of writing found",
                detail: "Added to the Library"
            ))
        }

        let names = summary.recruitedTravellers.compactMap { catalogue.traveller($0)?.name }
        let peopleCount = summary.recruitedTravellers.count
        cells.append(.init(
            id: "people", heading: "Joined the village",
            value: peopleCount == 0
                ? "No one joined the village"
                : peopleCount == 1
                    ? "1 person joined the village"
                    : "\(peopleCount) people joined the village",
            detail: names.isEmpty ? nil : names.joined(separator: " · ")
        ))

        if !summary.progress.isEmpty {
            let experience = Set(summary.progress.map(\.experience))
            let equal = experience.count == 1
            cells.append(.init(
                id: "xp", heading: "XP earned",
                value: equal ? "+\(experience.first ?? 0) XP each" : "Party earned XP",
                detail: equal
                    ? summary.progress.map(\.name).joined(separator: " · ")
                    : summary.progress.map { "\($0.name) +\($0.experience) XP" }.joined(separator: " · ")
            ))
        }

        let levelUps = summary.progress.reduce(0) { $0 + $1.levels }
        if levelUps > 0 {
            cells.append(.init(
                id: "levels", heading: "Level-ups",
                value: "\(levelUps) \(levelUps == 1 ? "level-up" : "level-ups") across the party",
                detail: nil
            ))
        }
        self.cells = cells
    }
}

/// Top-level routing.
///
/// Being inside a world is a *state*, not a navigation destination: if a run is active, that's the
/// screen you're on, full stop. Which means a force-quit mid-run can't strand you in the wrong
/// place — the save decides where you are, not a navigation stack we'd have to restore.
struct RootView: View {
    @EnvironmentObject private var store: GameStore
    @State private var debugBaseRoute: AppRoute = .base
    @State private var debugBugReporterSuppressed = false
    @State private var debugAuditPath: [AppRoute] = {
#if DEBUG
        if let rawRoute = ProcessInfo.processInfo.environment["BOOKBINDER_AUDIT_ROUTE"],
           let route = AppRoute(rawValue: rawRoute), route != .base {
            return [route]
        }
        let arguments = ProcessInfo.processInfo.arguments
        guard let marker = arguments.firstIndex(of: "--debug-audit-route"),
              arguments.indices.contains(marker + 1),
              let route = AppRoute(rawValue: arguments[marker + 1]),
              route != .base else { return [] }
        return [route]
#else
        return []
#endif
    }()

    var body: some View {
        let splash = store.state.worlds.pendingWorldSplashPresentation
        return Group {
            switch RootPresentationRules.surface(hasArrival: splash != nil,
                                                 hasEncounter: store.activeEncounter != nil,
                                                 isInRun: store.state.worlds.isInRun) {
            case .arrival:
                if let splash {
                    WorldArrivalView(presentation: splash)
                }
            case .encounter:
                EncounterView()
            case .world:
                WorldView()
            case .base:
                NavigationStack(path: $debugAuditPath) {
                    BaseView()
                        .environment(\.phoneRouteAction) { route in
                            debugAuditPath.append(route)
                        }
                        .navigationDestination(for: AppRoute.self) { route in
                            destination(for: route)
                                .onAppear {
                                    debugBaseRoute = route
                                    _ = store.openedFirstReturnDestination(route)
                                }
                                .onDisappear { debugBaseRoute = .base }
                        }
                }
            }
        }
        .onAppear { reconcileArrivalPresentation() }
        .onChange(of: store.state.worlds.pendingWorldArrivalReceiptID) {
            reconcileArrivalPresentation()
        }
        .sheet(item: Binding(get: { store.state.worlds.pendingExpeditionReview }, set: { _ in
            // The WorldView -> BaseView identity transition can ask the presentation host to
            // dismiss. That is not player acknowledgement. Only the recap's Continue action may
            // consume this durable receipt.
        })) { review in
            if let quote = store.expeditionReviewContinueQuote(), quote.head == review {
                RunExitSummaryView(quote: quote) { retainedQuote in
                    store.acknowledgeExpeditionReview(quote: retainedQuote)
                }
                .id(quote.controlID)
            }
        }
        .sheet(isPresented: Binding(
            get: {
                store.state.worlds.pendingAnchorSettlement
                    && store.state.worlds.expeditionReviewQueue.pending.isEmpty
            },
            set: { _ in }
        )) {
            AnchorSettlementView().environmentObject(store)
        }
        .onChange(of: store.state.worlds.isInRun) { wasInRun, isInRun in
            let updated = RootNavigationRules.homePath(afterRunTransitionFrom: wasInRun,
                                                       to: isInRun,
                                                       current: debugAuditPath)
            guard updated != debugAuditPath else { return }
            debugAuditPath = updated
            if !isInRun { debugBaseRoute = .base }
        }
#if DEBUG
        .onPreferenceChange(DebugBugReporterSuppressedPreferenceKey.self) {
            debugBugReporterSuppressed = $0
        }
        .overlay {
            if !debugBugReporterSuppressed {
                DebugBugReporterOverlay(store: store, route: debugBaseRoute)
            }
        }
#endif
    }

    private func reconcileArrivalPresentation() {
        _ = store.reconcileOrphanWorldArrival()
    }
}

#if DEBUG
struct DebugBugReporterSuppressedPreferenceKey: PreferenceKey {
    static let defaultValue = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}
#endif

private struct AnchorSettlementView: View {
    @EnvironmentObject private var store: GameStore
    @State private var decisions: [Int: GameStore.AnchorSettlementDecision] = [:]

    private var realms: [AnchoredRealm] {
        store.state.worlds.anchoredRealms.filter { !$0.isDormant && $0.projectedShortfall > 0 }
    }
    private var total: Int {
        realms.filter { decisions[$0.id] == .sustain }.reduce(0) { $0 + $1.projectedShortfall }
    }
    private var remaining: Int { store.state.base.essenceCrystalCount - total }
    private var bindCost: Int { EconomyRules.minimumBindCost(in: store.state) }
    private var bindRunway: Int { max(0, remaining) / max(1, bindCost) }
    private var restCount: Int { decisions.values.filter { $0 == .letRest }.count }
    private var allDecided: Bool {
        Set(decisions.keys) == Set(realms.map(\.id))
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(realms) { realm in
                        VStack(alignment: .leading, spacing: 10) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(realm.name).font(.headline)
                                Text("Production \(realm.productionContribution) · obligation \(realm.sustainObligation)")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Picker("Decision for \(realm.name)", selection: Binding(
                                get: { decisions[realm.id] },
                                set: { decisions[realm.id] = $0 }
                            )) {
                                Text("Choose…").tag(nil as GameStore.AnchorSettlementDecision?)
                                Text("Sustain · \(realm.projectedShortfall) Essence")
                                    .tag(GameStore.AnchorSettlementDecision.sustain as GameStore.AnchorSettlementDecision?)
                                Text("Let rest")
                                    .tag(GameStore.AnchorSettlementDecision.letRest as GameStore.AnchorSettlementDecision?)
                            }
                            .pickerStyle(.menu)
                        }
                    }
                } header: {
                    Text("Decide each realm")
                } footer: {
                    Text("Let rest makes a realm dormant, never deleted. Its assigned companions return safely.")
                }
            }
            .navigationTitle("Anchorage settlement")
            .interactiveDismissDisabled()
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 8) {
                    HStack {
                        summary("Available", store.state.base.essenceCrystalCount)
                        summary("Payment", total)
                        summary("Remaining", remaining)
                    }
                    HStack {
                        Text("Worlds you can afford at \(bindCost) Essence each: \(bindRunway)")
                        Spacer()
                        Text("Resting: \(restCount)")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    if remaining < 0 {
                        Text("You need \(-remaining) more Essence for these choices.")
                            .font(.caption.bold())
                            .foregroundStyle(.red)
                    }
                    Button("Confirm settlement") {
                        _ = store.settleAnchoredRealms(decisions: decisions)
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .disabled(!allDecided || remaining < 0)
                }
                .padding()
                .background(.bar)
            }
        }
    }

    private func summary(_ label: String, _ value: Int) -> some View {
        VStack(spacing: 2) {
            Text("\(value)").font(.headline).monospacedDigit()
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#if DEBUG
@MainActor enum RunExitSafeSpaceMeasurement {
    static var scrollFrame: CGRect = .zero
    static var actionFrame: CGRect = .zero
    static var receiptFrames: [RunExitReceiptSemanticID: CGRect] = [:]
}

struct RunExitReceiptSemanticID: Hashable, Sendable {
    enum Side: String, Hashable, Sendable { case recovered, lost }
    let side: Side
    let lineID: String
    let destination: RunExitSummary.ReceiptLine.RecoveredItemDestination?
}

private struct RunExitSafeSpaceProbe: UIViewRepresentable {
    enum Region { case scroll, action }
    let region: Region

    final class ProbeView: UIView {
        var region: Region = .scroll
        private func recordFrame() {
            guard let window, abs(window.bounds.width - 368) < 0.5 else { return }
            let frame = convert(bounds, to: window)
            switch region {
            case .scroll: RunExitSafeSpaceMeasurement.scrollFrame = frame
            case .action: RunExitSafeSpaceMeasurement.actionFrame = frame
            }
        }
        override func didMoveToWindow() {
            super.didMoveToWindow()
            DispatchQueue.main.async { [weak self] in self?.recordFrame() }
        }
        override func layoutSubviews() { super.layoutSubviews(); recordFrame() }
    }

    func makeUIView(context: Context) -> ProbeView {
        let view = ProbeView(frame: .zero); view.region = region; return view
    }
    func updateUIView(_ uiView: ProbeView, context: Context) { uiView.region = region }
}

private struct RunExitReceiptSemanticProbe: UIViewRepresentable {
    let identity: RunExitReceiptSemanticID

    final class ProbeView: UIView {
        var identity = RunExitReceiptSemanticID(side: .recovered, lineID: "", destination: nil)
        private func recordFrame() {
            guard let window, abs(window.bounds.width - 368) < 0.5 else { return }
            RunExitSafeSpaceMeasurement.receiptFrames[identity] = convert(bounds, to: window)
        }
        override func didMoveToWindow() {
            super.didMoveToWindow()
            DispatchQueue.main.async { [weak self] in self?.recordFrame() }
        }
        override func layoutSubviews() { super.layoutSubviews(); recordFrame() }
    }

    func makeUIView(context: Context) -> ProbeView {
        let view = ProbeView(frame: .zero); view.identity = identity; return view
    }
    func updateUIView(_ uiView: ProbeView, context: Context) { uiView.identity = identity }
}
#endif

struct RunExitSummaryView: View {
    @EnvironmentObject private var store: GameStore
    @State private var tutorialHidden = false
    @State private var selectedReceipt: RunExitSummary.ReceiptLine?
    @State private var continueRefusalCopy: String?
    @StateObject private var continueAdmission = PhoneControlAdmissionV1()
    let summary: RunExitSummary
    let dismiss: () -> Void
    let continueQuote: ExpeditionReviewContinueQuoteV1?
    let continueAction: ((ExpeditionReviewContinueQuoteV1)
                         -> ExpeditionReviewContinueResultV1)?

    init(summary: RunExitSummary, dismiss: @escaping () -> Void,
         selectedReceipt: RunExitSummary.ReceiptLine? = nil) {
        self.summary = summary
        self.dismiss = dismiss
        self.continueQuote = nil
        self.continueAction = nil
        _selectedReceipt = State(initialValue: selectedReceipt)
    }

    init(quote: ExpeditionReviewContinueQuoteV1,
         continueAction: @escaping (ExpeditionReviewContinueQuoteV1)
            -> ExpeditionReviewContinueResultV1) {
        summary = quote.head.summary
        dismiss = {}
        continueQuote = quote
        self.continueAction = continueAction
    }

    var body: some View {
        VStack(spacing: 0) {
            recapHeader
            ScrollView {
                VStack(spacing: 9) {
                    outcomePanel
                    compactReceiptSection(
                        eyebrow: "RECOVERED",
                        title: "Resources · \(RunExitRecapPresentation.resources(in: summary.recoveredLines).reduce(0) { $0 + $1.compatibilityGain.count }) units",
                        lines: summary.recoveredLines,
                        pages: summary.keptWorldPages
                    )
                    keptLedger
                    compactReceiptSection(
                        eyebrow: "LOST",
                        title: "\(lostThingCount) things left behind",
                        lines: summary.lostLines,
                        pages: summary.lostWorldPages,
                        isLost: true
                    )
                    essenceRunway
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
            }
            .scrollBounceBehavior(.basedOnSize)
#if DEBUG
            .background { RunExitSafeSpaceProbe(region: .scroll) }
#endif

            VStack {
                if let continueRefusalCopy {
                    Text(continueRefusalCopy)
                        .font(.custom("Tiny5", size: 10))
                        .foregroundStyle(PixelUITheme.text)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Button("Return to Village", action: continueTapped)
                    .font(.custom("Tiny5", size: 13))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .background(PixelUITheme.primary)
                    .overlay(Rectangle().stroke(PixelUITheme.edgeDark, lineWidth: 2))
                    .buttonStyle(.plain)
                    .fullFacePressFeedback(continueControlID, admission: continueAdmission)
                    .accessibilityIdentifier("run-exit.continue")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(PixelUITheme.headerB)
            .overlay(alignment: .top) { Rectangle().fill(PixelUITheme.edge).frame(height: 2) }
#if DEBUG
            .background { RunExitSafeSpaceProbe(region: .action) }
#endif
        }
        .foregroundStyle(PixelUITheme.text)
        .background(PixelUITheme.screen.ignoresSafeArea())
        .presentationDetents([.large])
        .interactiveDismissDisabled()
        .overlay {
            if let selectedReceipt {
                receiptDetailOverlay(selectedReceipt)
            }
        }
        .tutorialHoverOverlay(
            isPresented: !tutorialHidden
                && store.state.tutorial.firstReturnContext?.runIndex == summary.runIndex,
            alignment: .top
        ) {
            if !tutorialHidden,
               store.state.tutorial.firstReturnContext?.runIndex == summary.runIndex,
               let lesson = TutorialRules.definition(.returnPersistenceBoundary) {
                TutorialCard(lesson: lesson,
                             gotIt: { tutorialHidden = true },
                             notNow: {
                                 store.deferTutorial(.returnPersistenceBoundary)
                                 tutorialHidden = true
                             })
            }
        }
    }

    private var continueControlID: String {
        continueQuote?.controlID ?? "run-exit.continue"
    }

    private func continueTapped() {
        guard let continueQuote, let continueAction else {
            dismiss()
            return
        }
        _ = continueAdmission.release(controlID: continueControlID) {
            switch continueAction(continueQuote) {
            case .acknowledged:
                continueRefusalCopy = nil
                return .success(.committed)
            case .alreadyAcknowledged:
                continueRefusalCopy = "This expedition recap was already continued."
                return .success(.noChange)
            case .stale(let reason):
                continueRefusalCopy = reason.playerCopy
                return .failure(.stale)
            case .refused(let reason):
                continueRefusalCopy = reason.playerCopy
                return .failure(.disabled(reason.playerCopy))
            case .busy:
                return .failure(.busy)
            }
        }
    }

    private var recapHeader: some View {
        HStack(alignment: .center) {
            Rectangle().fill(PixelUITheme.clasp).frame(width: 5, height: 38)
            Text("Expedition return")
                .font(.custom("Jersey 10", size: 25))
            Spacer()
            Text("World \(summary.runIndex) · complete")
                .font(.custom("Tiny5", size: 10))
                .foregroundStyle(PixelUITheme.muted)
        }
        .padding(.horizontal, 12)
        .frame(height: 62)
        .background(PixelUITheme.headerB)
        .overlay(alignment: .bottom) { Rectangle().fill(PixelUITheme.edge).frame(height: 2) }
    }

    private var outcomePanel: some View {
        HStack(spacing: 8) {
            Text(summary.haulKeptFraction >= 1 ? "◆" : "×")
                .font(.custom("Jersey 10", size: 24))
                .frame(width: 46, height: 46)
                .background(PixelUITheme.surfaceInset)
                .overlay(Rectangle().stroke(PixelUITheme.clasp, lineWidth: 2))
            VStack(alignment: .leading, spacing: 2) {
                Text(summary.haulKeptFraction >= 1 ? "RETURN COMPLETE" : "WORLD CLOSED")
                    .font(.custom("Tiny5", size: 9))
                    .foregroundStyle(PixelUITheme.muted)
                Text(summary.kind.title)
                    .font(.custom("Jersey 10", size: 18))
                Text(summary.departureCopy)
                    .font(.system(size: 12))
                    .lineLimit(2)
            }
            Spacer(minLength: 2)
            VStack(alignment: .trailing, spacing: 4) {
                recapFact("Turns", value: "\(summary.turnsTaken)")
                recapFact("Haul", value: "\(recoveredThingCount) / \(recoveredThingCount + lostThingCount)")
            }
        }
        .padding(10)
        .foregroundStyle(PixelUITheme.text)
        .background(PixelUITheme.surfaceInset)
        .overlay(Rectangle().stroke(PixelUITheme.edge, lineWidth: 2))
    }

    private func recapFact(_ label: String, value: String) -> some View {
        VStack(alignment: .trailing, spacing: 1) {
            Text(label.uppercased()).font(.custom("Tiny5", size: 8))
            Text(value).font(.custom("Tiny5", size: 10))
        }
    }

    private var recoveredThingCount: Int {
        summary.recoveredLines.reduce(0) { $0 + $1.compatibilityGain.count }
            + summary.keptWorldPages.count
    }

    private var lostThingCount: Int {
        summary.lostLines.reduce(0) { $0 + $1.compatibilityGain.count }
            + summary.lostWorldPages.count
    }

    private func compactReceiptSection(
        eyebrow: String,
        title: String,
        lines: [RunExitSummary.ReceiptLine],
        pages: [WorldPageInstance],
        isLost: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(eyebrow).font(.custom("Tiny5", size: 9))
                        .foregroundStyle(PixelUITheme.muted)
                    Text(title).font(.custom("Jersey 10", size: 16))
                }
                Spacer()
                if !isLost { Text("Storehouse").font(.custom("Tiny5", size: 9)) }
            }
            .padding(.bottom, 5)
            .overlay(alignment: .bottom) { Rectangle().fill(PixelUITheme.edge).frame(height: 1) }

            if lines.isEmpty && pages.isEmpty {
                Text("None").font(.custom("Tiny5", size: 10)).foregroundStyle(PixelUITheme.muted)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 6), spacing: 4) {
                    ForEach(lines, id: \.id) { line in
                        Button { selectedReceipt = line } label: {
                            receiptTile(line, isLost: isLost).opacity(isLost ? 0.62 : 1)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier(receiptSemanticIdentifier(line, isLost: isLost))
#if DEBUG
                        .background {
                            RunExitReceiptSemanticProbe(identity: .init(
                                side: isLost ? .lost : .recovered,
                                lineID: line.id,
                                destination: line.recoveredItemDestination))
                        }
#endif
                    }
                    ForEach(pages) { page in
                        Image(systemName: "doc.text")
                            .font(.system(size: 17))
                            .frame(maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fit)
                            .foregroundStyle(isLost ? PixelUITheme.muted : PixelUITheme.text)
                            .background(PixelUITheme.neutral)
                            .overlay(Rectangle().stroke(PixelUITheme.edgeDark, lineWidth: 2))
                            .accessibilityLabel(page.inspected ? page.definition.title : "Unknown page")
                    }
                }
            }
        }
        .padding(8)
        .background(PixelUITheme.surface)
        .overlay(Rectangle().stroke(PixelUITheme.edge, lineWidth: 2))
    }

    private var keptLedger: some View {
        let presentation = RunExitPermanentGainsPresentation(summary: summary)
        return VStack(alignment: .leading, spacing: 6) {
            Text("PERMANENT GAINS").font(.custom("Tiny5", size: 9))
                .foregroundStyle(PixelUITheme.muted)
            Text("Writing, people & XP").font(.custom("Jersey 10", size: 16))
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 4) {
                ForEach(presentation.cells) { cell in
                    ledgerCell(cell.heading, cell.value, cell.detail)
                }
            }
        }
        .padding(8)
        .background(PixelUITheme.surface)
        .overlay(Rectangle().stroke(PixelUITheme.edge, lineWidth: 2))
    }

    private func ledgerCell(_ heading: String, _ value: String, _ detail: String?) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(heading.uppercased()).font(.custom("Tiny5", size: 8))
                .foregroundStyle(PixelUITheme.muted)
            Text(value).font(.custom("Tiny5", size: 10)).fixedSize(horizontal: false, vertical: true)
            if let detail, !detail.isEmpty {
                Text(detail).font(.custom("Tiny5", size: 8))
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundStyle(PixelUITheme.muted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(5)
        .background(PixelUITheme.neutral)
        .overlay(Rectangle().stroke(PixelUITheme.edge, lineWidth: 1))
    }

    private var essenceRunway: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("ESSENCE AVAILABLE").font(.custom("Tiny5", size: 9))
                    .foregroundStyle(PixelUITheme.muted)
                Text("\(summary.essenceEconomy.netRunway) after refining")
                    .font(.custom("Tiny5", size: 10))
            }
            Spacer()
            Text("Enough to bind at least one more world")
                .font(.custom("Tiny5", size: 9))
        }
        .padding(8)
        .background(PixelUITheme.surfaceInset)
        .overlay(Rectangle().stroke(PixelUITheme.edge, lineWidth: 2))
    }

    private func sectionHeading(_ title: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text(title.uppercased())
                    .font(.custom("Tiny5", size: 9))
                    .foregroundStyle(PixelUITheme.muted)
                Text(sectionSubtitle(title))
                    .font(.custom("Jersey 10", size: 16))
            }
            Spacer()
        }
        .padding(.bottom, 4)
        .overlay(alignment: .bottom) { Rectangle().fill(PixelUITheme.edge).frame(height: 1) }
    }

    private func sectionSubtitle(_ title: String) -> String {
        switch title {
        case "Recovered": "Resources, items & pages"
        case "Kept with you": "Writing, people & XP"
        case "Lost": "Things left behind"
        default: title
        }
    }

    private func worldPageSection(_ title: String, pages: [WorldPageInstance],
                                  isLost: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title).font(.custom("Tiny5", size: 10))
                Spacer()
                Text("\(pages.count)").font(.custom("Tiny5", size: 9))
            }
            if pages.isEmpty {
                Text("None").foregroundStyle(PixelUITheme.muted)
            } else {
                ForEach(pages) { page in
                    Label(page.inspected ? page.definition.title : "Unknown page",
                          systemImage: "doc.text")
                        .foregroundStyle(isLost ? PixelUITheme.muted : PixelUITheme.text)
                }
            }
        }
        .recapPanel()
    }

    private var experienceSources: [(name: String, amount: Int)] {
        let xp = summary.experienceBreakdown
        return [("Combat", xp.combat), ("New species", xp.species), ("New sites", xp.sites),
                ("Writing", xp.pages), ("New travellers", xp.travellers)]
            .filter { $0.amount > 0 }
    }

    @ViewBuilder private var experienceSourceLabels: some View {
        ForEach(experienceSources.indices, id: \.self) { index in
            let source = experienceSources[index]
            Text("\(source.name) +\(source.amount)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }

    private func receiptSection(_ title: String, lines: [RunExitSummary.ReceiptLine],
                                isLost: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title).font(.custom("Tiny5", size: 10))
                Spacer()
                Text("\(lines.reduce(0) { $0 + $1.compatibilityGain.count }) units")
                    .font(.custom("Tiny5", size: 9))
                    .foregroundStyle(PixelUITheme.muted)
            }
            if lines.isEmpty {
                Text("No \(title.lowercased()) this trip.").foregroundStyle(PixelUITheme.muted)
            } else {
                SixAcrossItemGrid(data: lines, id: \.id) { line in
                    Button { selectedReceipt = line } label: {
                        receiptTile(line, isLost: isLost).opacity(isLost ? 0.62 : 1)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier(receiptSemanticIdentifier(line, isLost: isLost))
                    .accessibilityAddTraits(selectedReceipt?.id == line.id ? .isSelected : [])
#if DEBUG
                    .background {
                        RunExitReceiptSemanticProbe(identity: .init(
                            side: isLost ? .lost : .recovered,
                            lineID: line.id,
                            destination: line.recoveredItemDestination))
                    }
#endif
                }
            }
        }
        .recapPanel()
    }

    @ViewBuilder
    private func receiptTile(_ line: RunExitSummary.ReceiptLine, isLost: Bool) -> some View {
        switch line {
        case .resource(let resource):
            ResourceIconTile(resourceID: resource.id, icon: resource.fallbackIcon,
                             quantity: resource.quantity,
                             accessibilityName: resource.fallbackName)
        case .stackableItem(let item), .uniqueItem(let item):
            if let location = receiptItemLocation(item.recoveredDestination, isLost: isLost) {
                ItemIconTile(icon: item.fallbackIcon, catalogueID: item.snapshot.catalogID,
                             rarity: ContentCatalog.shared.item(item.snapshot.catalogID)?.rarity ?? .common,
                             quantity: item.quantity, identified: item.snapshot.identified,
                             location: location, accessibilityName: item.fallbackName,
                             gearQualityBand: item.snapshot.gearProfile?.qualityBand)
            } else {
                RunExitUnrecordedItemTile(icon: item.fallbackIcon,
                                          catalogueID: item.snapshot.catalogID,
                                          materialKind: nil,
                                          rarity: ContentCatalog.shared
                                            .item(item.snapshot.catalogID)?.rarity ?? .common,
                                          quantity: item.quantity,
                                          identified: item.snapshot.identified,
                                          accessibilityName: item.fallbackName,
                                          gearQualityBand: item.snapshot.gearProfile?.qualityBand)
            }
        case .materialSample(let material):
            if let location = receiptItemLocation(material.recoveredDestination, isLost: isLost) {
                ItemIconTile(icon: material.fallbackIcon, catalogueID: material.catalogID,
                             materialKind: material.sample.kind,
                             rarity: ContentCatalog.shared.item(material.catalogID)?.rarity ?? .common,
                             quantity: 1, identified: material.identified,
                             location: location, accessibilityName: material.fallbackName)
            } else {
                RunExitUnrecordedItemTile(icon: material.fallbackIcon,
                                          catalogueID: material.catalogID,
                                          materialKind: material.sample.kind,
                                          rarity: ContentCatalog.shared.item(material.catalogID)?.rarity ?? .common,
                                          quantity: 1, identified: material.identified,
                                          accessibilityName: material.fallbackName)
            }
        case .legacy(let legacy):
            LegacyReceiptIconTile(icon: legacy.fallbackIcon, quantity: legacy.quantity,
                                  accessibilityName: legacy.fallbackName)
        }
    }

    private func receiptDetail(_ line: RunExitSummary.ReceiptLine) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(line.compatibilityGain.name).font(.headline)
            switch line {
            case .resource(let resource):
                LabeledContent("Quantity", value: "\(resource.quantity)")
            case .stackableItem(let item), .uniqueItem(let item):
                LabeledContent("Quantity", value: "\(item.quantity)")
                LabeledContent("State", value: item.snapshot.identified ? "Identified" : "Unidentified")
                receiptDisposition(line)
            case .materialSample(let material):
                LabeledContent("Kind", value: material.sample.kind.displayName)
                LabeledContent("Quality", value: material.sample.qualityBand.displayName)
                LabeledContent("Source", value: material.sample.source)
                receiptDisposition(line)
            case .legacy(let legacy):
                LabeledContent("Quantity", value: "\(legacy.quantity)")
                Text(GearPresentationCopy.olderSaveArtUnavailable)
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(16)
    }

    @ViewBuilder
    private func receiptDisposition(_ line: RunExitSummary.ReceiptLine) -> some View {
        if summary.lostLines.contains(where: { $0.id == line.id }) {
            LabeledContent("Disposition", value: "Lost on Return")
                .accessibilityIdentifier("run-exit.receipt-disposition.\(line.id).lost")
        } else {
            let destination = line.recoveredItemDestination
            LabeledContent("Destination", value: destination?.playerCopy ?? "Destination not recorded")
                .accessibilityIdentifier(
                    "run-exit.receipt-destination.\(line.id).\(destination?.rawValue ?? "not-recorded")")
        }
    }

    private func receiptItemLocation(
        _ destination: RunExitSummary.ReceiptLine.RecoveredItemDestination?, isLost: Bool
    ) -> ItemGridLocation? {
        if isLost { return .carried }
        switch destination {
        case .stored: return .stored
        case .waitingToSort: return .waiting
        case nil: return nil
        }
    }

    private func receiptSemanticIdentifier(
        _ line: RunExitSummary.ReceiptLine, isLost: Bool
    ) -> String {
        let side = isLost ? "lost" : "recovered"
        let destination = line.recoveredItemDestination?.rawValue ?? "none"
        return "run-exit.receipt.\(side).\(line.id).\(destination)"
    }

    private func receiptDetailOverlay(_ line: RunExitSummary.ReceiptLine) -> some View {
        ZStack {
            Color.black.opacity(0.32).ignoresSafeArea()
                .onTapGesture { selectedReceipt = nil }
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("DETAILS")
                        .font(.custom("Tiny5", size: 10))
                        .foregroundStyle(PixelUITheme.muted)
                    Spacer()
                    Button("Done") { selectedReceipt = nil }
                        .font(.custom("Tiny5", size: 10))
                        .frame(minWidth: 54, minHeight: 44)
                        .background(PixelUITheme.neutral)
                        .overlay(Rectangle().stroke(PixelUITheme.edge, lineWidth: 2))
                        .buttonStyle(.plain)
                }
                receiptDetail(line)
            }
            .padding(12)
            .foregroundStyle(PixelUITheme.text)
            .background(PixelUITheme.surface)
            .background {
                Rectangle()
                    .fill(PixelUITheme.shadow.opacity(0.7))
                    .offset(x: 7, y: 7)
            }
            .overlay(Rectangle().stroke(PixelUITheme.edgeDark, lineWidth: 3))
            .padding(.horizontal, 16)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("run-exit.receipt-detail")
    }

    private var writingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Writing recovered").font(.custom("Tiny5", size: 10))
            if summary.pages.isEmpty && summary.writings.isEmpty {
                Text("None this trip.").foregroundStyle(.secondary)
            } else {
                ForEach(summary.pages, id: \.self) { id in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "doc.text.fill").foregroundStyle(.indigo).frame(width: 22)
                        VStack(alignment: .leading, spacing: 2) {
                            if let page = ContentCatalog.shared.diaryPage(id) {
                                Text(ContentCatalog.shared.traveller(page.diary).map { "A page from \($0.name)" }
                                     ?? "Diary page")
                                Text(page.prose).font(.caption).foregroundStyle(.secondary)
                                    .lineLimit(3)
                            } else {
                                Text("Diary page")
                            }
                        }
                        Spacer(minLength: 0)
                    }
                }
                ForEach(summary.writings) { writing in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "doc.text.fill").foregroundStyle(.indigo).frame(width: 22)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(writing.title)
                            Text(writing.prose).font(.caption).foregroundStyle(.secondary)
                                .lineLimit(3)
                        }
                        Spacer(minLength: 0)
                    }
                }
            }
        }
        .recapPanel()
    }

}

private extension View {
    func recapPanel() -> some View {
        frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(PixelUITheme.surface)
            .overlay(Rectangle().stroke(PixelUITheme.edge, lineWidth: 2))
    }
}

private struct LegacyReceiptIconTile: View {
    let icon: String
    let quantity: Int
    let accessibilityName: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 9)
                .fill(Color(.secondarySystemGroupedBackground))
            RoundedRectangle(cornerRadius: 9)
                .strokeBorder(Color.secondary.opacity(0.65), lineWidth: 1.5)
            Image(systemName: icon).font(.title3).foregroundStyle(.secondary)
            if quantity > 1 {
                Text("\(quantity)")
                    .font(.system(size: 10, weight: .bold, design: .rounded).monospacedDigit())
                    .padding(.horizontal, 4).padding(.vertical, 1)
                    .background(.ultraThinMaterial, in: Capsule())
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(4)
            }
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

private struct RunExitUnrecordedItemTile: View {
    let icon: String
    let catalogueID: ItemID?
    let materialKind: MaterialFamilyID?
    let rarity: Rarity
    let quantity: Int
    let identified: Bool
    let accessibilityName: String
    /// Frozen receipt instance authority. Nil is reserved for catalogue-only/non-gear records.
    var gearQualityBand: CraftMaterialQualityBand? = nil

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 9)
                .fill(Color(.secondarySystemGroupedBackground))
            RoundedRectangle(cornerRadius: 9)
                .strokeBorder(rarity.tint.opacity(0.72), lineWidth: 1.5)
            if let materialKind {
                CraftMaterialUnitPixelIdentity(kind: materialKind,
                                            fallbackColor: identified ? rarity.tint : .secondary)
                    .frame(width: 32, height: 32)
            } else {
                CatalogueItemPixelIdentity(itemID: catalogueID, identified: identified,
                                           fallbackSystemIcon: icon,
                                           fallbackColor: identified ? rarity.tint : .secondary)
                    .frame(width: 32, height: 32)
            }
            if quantity > 1 {
                Text("\(quantity)")
                    .font(.system(size: 10, weight: .bold, design: .rounded).monospacedDigit())
                    .padding(.horizontal, 4).padding(.vertical, 1)
                    .background(.ultraThinMaterial, in: Capsule())
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(4)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(minWidth: 44, minHeight: 44)
        .contentShape(RoundedRectangle(cornerRadius: 9))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        let identity = identified ? accessibilityName : "Unknown item"
        let quality = GearPresentationCopy.itemGridQuality(instanceBand: gearQualityBand,
                                                           catalogueID: catalogueID,
                                                           fallbackRarity: rarity)
        return "\(identity), \(quality), destination not recorded"
            + (quantity > 1 ? ", quantity \(quantity)" : "")
    }
}

extension RootView {
    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .writingDesk: WritingDeskView()
        case .storehouse: StorehouseView()
        case .workshop: WorkshopView()
        case .party: PartyRosterView()
        case .essenceSpring: EssenceSpringView()
        case .constellation: ConstellationView()
        case .library: LibraryView()
        case .bestiary:
            BestiaryView().onAppear { checkLibraryShelf(.bestiary) }
        case .blacksmith: BlacksmithView()
        case .tradingPost: TradingPostView()
        case .recycler: RecyclerView()
        case .tannery: TanneryView()
        case .bowyer: BowyerView()
        case .armoury: ArmouryView()
        case .weaponsmith: WeaponsmithView()
        case .worldHistory:
            WorldHistoryView().onAppear { checkLibraryShelf(.worldHistory) }
        case .scriptorium: ScriptoriumView()
        case .surveyPost: SurveyPostView()
        case .apothecary: ApothecaryView()
        case .reliquary: ReliquaryView()
        case .wayfarersTable: WayfarersTableView()
        case .anchorage: AnchorageView()
        case .distillery: DistilleryView()
        case .channelworks: ChannelworksView()
        case .firepit: FirepitView()
        case .settings: SettingsView()
        case .harness: HarnessView()
        case .base, .world, .encounter: BaseView()
        }
    }

    private func checkLibraryShelf(_ id: LibraryShelfID) {
        guard LibraryShelfPresentation.make(in: store.state).contains(where: {
            $0.id == id
        }) else { return }
        store.checkLibraryContent(LibraryShelfPresentation.contentIDs(for: id, in: store.state))
    }
}

#Preview {
    RootView()
        .environmentObject(GameStore(io: .temporary(name: "preview-root")))
}
