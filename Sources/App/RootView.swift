import SwiftUI

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
        Group {
            if store.activeEncounter != nil {
                EncounterView()
            } else if store.state.worlds.isInRun {
                WorldView()
            } else {
                NavigationStack(path: $debugAuditPath) {
                    BaseView()
                        .navigationDestination(for: AppRoute.self) { route in
                            destination(for: route)
                                .onAppear { debugBaseRoute = route }
                                .onDisappear { debugBaseRoute = .base }
                        }
                }
            }
        }
        .sheet(item: Binding(get: { store.state.worlds.lastExit }, set: { _ in
            // The WorldView -> BaseView identity transition can ask the presentation host to
            // dismiss. That is not player acknowledgement. Only the recap's Continue action may
            // consume this durable receipt.
        })) { summary in
            RunExitSummaryView(summary: summary) {
                store.acknowledgeFirstReturnRecap()
            }
        }
        .sheet(isPresented: Binding(
            get: { store.state.worlds.pendingAnchorSettlement && store.state.worlds.lastExit == nil },
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
    private var remaining: Int { store.state.base.essence - total }
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
                        summary("Available", store.state.base.essence)
                        summary("Payment", total)
                        summary("Remaining", remaining)
                    }
                    HStack {
                        Text("Authored-bind runway: \(bindRunway)")
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

struct RunExitSummaryView: View {
    @EnvironmentObject private var store: GameStore
    @State private var tutorialHidden = false
    @State private var selectedReceipt: RunExitSummary.ReceiptLine?
    let summary: RunExitSummary
    let dismiss: () -> Void

    init(summary: RunExitSummary, dismiss: @escaping () -> Void,
         selectedReceipt: RunExitSummary.ReceiptLine? = nil) {
        self.summary = summary
        self.dismiss = dismiss
        _selectedReceipt = State(initialValue: selectedReceipt)
    }

    var body: some View {
        VStack(spacing: 0) {
            recapHeader
            ScrollView {
                VStack(spacing: 9) {
                    outcomePanel
                    sectionHeading("Recovered")
                    receiptSection("Resources", lines: RunExitRecapPresentation.resources(
                        in: summary.recoveredLines))
                    receiptSection("Items", lines: RunExitRecapPresentation.items(
                        in: summary.recoveredLines))
                    worldPageSection("World Pages kept", pages: summary.keptWorldPages)

                    sectionHeading("Kept with you")
                    writingSection
                    travellersSection
                    partyProgressSection

                    sectionHeading("Lost")
                    receiptSection("Resources", lines: RunExitRecapPresentation.resources(
                        in: summary.lostLines), isLost: true)
                    receiptSection("Items", lines: RunExitRecapPresentation.items(
                        in: summary.lostLines), isLost: true)
                    worldPageSection("World Pages lost", pages: summary.lostWorldPages,
                                     isLost: true)

                    VStack(alignment: .leading, spacing: 7) {
                        Text("NEXT DEPARTURE")
                            .font(.custom("Tiny5", size: 10))
                            .foregroundStyle(PixelUITheme.muted)
                        Text("Essence runway")
                            .font(.custom("Jersey 10", size: 18))
                        LabeledContent("Raw Essence collected", value: "\(summary.essenceEconomy.rawCollected)")
                        if summary.essenceEconomy.refinedEquivalent > 0 {
                            LabeledContent("Value at current rate",
                                           value: "\(summary.essenceEconomy.refinedEquivalent) Essence")
                        }
                        if summary.essenceEconomy.rawAutoRefined > 0 {
                            LabeledContent("Continuous settling",
                                           value: "\(summary.essenceEconomy.rawAutoRefined) Raw → \(summary.essenceEconomy.automaticallyRefinedEssence) Essence")
                        }
                        LabeledContent("Bind cost paid", value: "\(summary.essenceEconomy.bindCostPaid)")
                        LabeledContent("Spring yield", value: "+\(summary.essenceEconomy.springYield)")
                        if summary.essenceEconomy.antiLockSubsidy > 0 {
                            LabeledContent("Spring shortfall aid", value: "+\(summary.essenceEconomy.antiLockSubsidy)")
                        }
                        LabeledContent("Spendable runway", value: "\(summary.essenceEconomy.netRunway)")
                    }
                    .recapPanel()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
            }
            .scrollBounceBehavior(.basedOnSize)

            VStack {
                Button("Return to Base", action: dismiss)
                    .font(.custom("Tiny5", size: 13))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .background(PixelUITheme.primary)
                    .overlay(Rectangle().stroke(PixelUITheme.edgeDark, lineWidth: 2))
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("run-exit.continue")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(PixelUITheme.headerB)
            .overlay(alignment: .top) { Rectangle().fill(PixelUITheme.edge).frame(height: 2) }
        }
        .foregroundStyle(PixelUITheme.text)
        .background(PixelUITheme.screen)
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

    private var recapHeader: some View {
        HStack(alignment: .center) {
            Rectangle().fill(PixelUITheme.clasp).frame(width: 5, height: 38)
            Text("Expedition return")
                .font(.custom("Jersey 10", size: 25))
            Spacer()
            Text("World \(summary.runIndex) · \(summary.kind == .collapse ? "collapsed" : "returned")")
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
                Text(summary.reason)
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
        case "Kept with you": "Writing, travellers & progress"
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
                        receiptTile(line).opacity(isLost ? 0.62 : 1)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selectedReceipt?.id == line.id ? .isSelected : [])
                }
            }
        }
        .recapPanel()
    }

    @ViewBuilder
    private func receiptTile(_ line: RunExitSummary.ReceiptLine) -> some View {
        switch line {
        case .resource(let resource):
            ResourceIconTile(resourceID: resource.id, icon: resource.fallbackIcon,
                             quantity: resource.quantity,
                             accessibilityName: resource.fallbackName)
        case .stackableItem(let item), .uniqueItem(let item):
            ItemIconTile(icon: item.fallbackIcon, catalogueID: item.snapshot.catalogID,
                         rarity: ContentCatalog.shared.item(item.snapshot.catalogID)?.rarity ?? .common,
                         quantity: item.quantity, identified: item.snapshot.identified,
                         location: .carried, accessibilityName: item.fallbackName)
        case .materialSample(let material):
            ItemIconTile(icon: material.fallbackIcon, catalogueID: material.catalogID,
                         rarity: ContentCatalog.shared.item(material.catalogID)?.rarity ?? .common,
                         quantity: 1, identified: material.identified,
                         location: .carried, accessibilityName: material.fallbackName)
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
                LabeledContent("Resource", value: resource.id.rawValue)
            case .stackableItem(let item), .uniqueItem(let item):
                LabeledContent("Quantity", value: "\(item.quantity)")
                LabeledContent("Identity", value: item.snapshot.catalogID.rawValue)
                LabeledContent("State", value: item.snapshot.identified ? "Identified" : "Unidentified")
            case .materialSample(let material):
                LabeledContent("Kind", value: material.sample.kind.displayName)
                LabeledContent("Grade", value: "\(material.sample.grade)")
                LabeledContent("Source", value: material.sample.source)
            case .legacy(let legacy):
                LabeledContent("Quantity", value: "\(legacy.quantity)")
                Text("Legacy receipt · visual identity unavailable")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(16)
    }

    private func receiptDetailOverlay(_ line: RunExitSummary.ReceiptLine) -> some View {
        ZStack {
            Color.black.opacity(0.32).ignoresSafeArea()
                .onTapGesture { selectedReceipt = nil }
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("RECEIPT DETAIL")
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

    private var travellersSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("People who came home").font(.custom("Tiny5", size: 10))
            if summary.recruitedTravellers.isEmpty {
                Text("None this trip.").foregroundStyle(.secondary)
            } else {
                ForEach(summary.recruitedTravellers, id: \.self) { id in
                    HStack {
                        Image(systemName: "person.crop.circle.badge.checkmark")
                            .foregroundStyle(.tint).frame(width: 22)
                        Text(ContentCatalog.shared.traveller(id)?.name ?? id.rawValue)
                    }
                }
            }
        }
        .recapPanel()
    }

    private var partyProgressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Party progress").font(.custom("Tiny5", size: 10))
            if summary.progress.isEmpty {
                Text("No progress recorded for this run.").foregroundStyle(PixelUITheme.muted)
            } else {
                if !experienceSources.isEmpty {
                    Text("Each active party member earned")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(PixelUITheme.muted)
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 12) { experienceSourceLabels }
                        VStack(alignment: .leading, spacing: 4) { experienceSourceLabels }
                    }
                    Divider()
                }
                ForEach(summary.progress) { gain in
                    HStack {
                        Image(systemName: gain.member == .binder ? "person.fill" : "person.2.fill")
                            .foregroundStyle(PixelUITheme.primary)
                        Text(gain.name)
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("+\(gain.experience) XP").monospacedDigit()
                            if gain.levels > 0 {
                                Text("Level \(gain.finalLevel) · +\(gain.levels)")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.green)
                            }
                        }
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
        case .bestiary: BestiaryView()
        case .blacksmith: BlacksmithView()
        case .tradingPost: TradingPostView()
        case .recycler: RecyclerView()
        case .tannery: TanneryView()
        case .bowyer: BowyerView()
        case .armoury: ArmouryView()
        case .weaponsmith: WeaponsmithView()
        case .worldHistory: WorldHistoryView()
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
}

#Preview {
    RootView()
        .environmentObject(GameStore(io: .temporary(name: "preview-root")))
}
