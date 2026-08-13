import SwiftUI

/// Top-level routing.
///
/// Being inside a world is a *state*, not a navigation destination: if a run is active, that's the
/// screen you're on, full stop. Which means a force-quit mid-run can't strand you in the wrong
/// place — the save decides where you are, not a navigation stack we'd have to restore.
struct RootView: View {
    @EnvironmentObject private var store: GameStore
    @State private var debugBaseRoute: AppRoute = .base
    @State private var debugBugReporterSuppressed = false

    var body: some View {
        Group {
            if store.activeEncounter != nil {
                EncounterView()
            } else if store.state.worlds.isInRun {
                WorldView()
            } else {
                NavigationStack {
                    BaseView()
                        .navigationDestination(for: AppRoute.self) { route in
                            destination(for: route)
                                .onAppear { debugBaseRoute = route }
                                .onDisappear { debugBaseRoute = .base }
                        }
                }
            }
        }
        .sheet(item: Binding(get: { store.state.worlds.lastExit }, set: { value in
            if value == nil { store.dismissRunExitSummary() }
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

private struct RunExitSummaryView: View {
    @EnvironmentObject private var store: GameStore
    @State private var tutorialHidden = false
    let summary: RunExitSummary
    let dismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 18) {
                    sectionHeading("Outcome")
                    Image(systemName: summary.haulKeptFraction >= 1 ? "checkmark.circle.fill" : "heart.slash.fill")
                        .font(.system(size: 42))
                        .foregroundStyle(summary.haulKeptFraction >= 1 ? Color.green : Color.red)
                    Text(summary.kind.title)
                        .font(.title2.bold())
                    Text(summary.reason)
                        .multilineTextAlignment(.center)
                    VStack(spacing: 6) {
                        Text("World \(summary.runIndex) · \(summary.turnsTaken) turns")
                        Text(summary.haulKeptFraction >= 1
                             ? "All of your haul came home."
                             : "About half of your haul came home.")
                    }
                    .font(.callout)
                    .foregroundStyle(.secondary)

                    sectionHeading("Recovered")
                    recapSection("Resources", gains: summary.resources)
                    recapSection("Loot", gains: summary.items)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Essence runway").font(.headline)
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
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color(.secondarySystemGroupedBackground),
                                in: RoundedRectangle(cornerRadius: 14))

                    sectionHeading("Lost")
                    recapSection("Resources", gains: summary.lostResources)
                    recapSection("Loot", gains: summary.lostItems)

                    sectionHeading("Kept for good")
                    writingSection
                    travellersSection

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Party progress").font(.headline)
                        if summary.progress.isEmpty {
                            Text("No progress recorded for this run.").foregroundStyle(.secondary)
                        } else {
                            if !experienceSources.isEmpty {
                                Text("Each active party member earned")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                ViewThatFits(in: .horizontal) {
                                    HStack(spacing: 12) { experienceSourceLabels }
                                    VStack(alignment: .leading, spacing: 4) { experienceSourceLabels }
                                }
                                Divider()
                            }
                            ForEach(summary.progress) { gain in
                                HStack {
                                    Image(systemName: gain.member == .binder ? "person.fill" : "person.2.fill")
                                        .foregroundStyle(.tint)
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
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color(.secondarySystemGroupedBackground),
                                in: RoundedRectangle(cornerRadius: 14))
                }
                .padding(24)
            }
            Button("Continue", action: dismiss)
                .buttonStyle(.borderedProminent)
                .frame(minHeight: 44)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                .accessibilityIdentifier("run-exit.continue")
        }
        .presentationDetents([.large])
        .interactiveDismissDisabled()
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

    private func sectionHeading(_ title: String) -> some View {
        Text(title)
            .font(.title3.bold())
            .frame(maxWidth: .infinity, alignment: .leading)
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

    private func recapSection(_ title: String, gains: [RunExitGain]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline)
            if gains.isEmpty {
                Text("None this trip.").foregroundStyle(.secondary)
            } else {
                ForEach(gains) { gain in
                    HStack {
                        Image(systemName: gain.icon).foregroundStyle(.tint).frame(width: 22)
                        Text(gain.name)
                        Spacer()
                        Text("+\(gain.count)").monospacedDigit()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    private var writingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Writing recovered").font(.headline)
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    private var travellersSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("People who came home").font(.headline)
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
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
