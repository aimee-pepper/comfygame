import SwiftUI

/// Top-level routing.
///
/// Being inside a world is a *state*, not a navigation destination: if a run is active, that's the
/// screen you're on, full stop. Which means a force-quit mid-run can't strand you in the wrong
/// place — the save decides where you are, not a navigation stack we'd have to restore.
struct RootView: View {
    @EnvironmentObject private var store: GameStore

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
        .overlay { DebugBugReporterOverlay(store: store) }
#endif
    }
}

private struct AnchorSettlementView: View {
    @EnvironmentObject private var store: GameStore
    @State private var paying: Set<Int> = []

    private var realms: [AnchoredRealm] {
        store.state.worlds.anchoredRealms.filter { !$0.isDormant && $0.projectedShortfall > 0 }
    }
    private var total: Int {
        realms.filter { paying.contains($0.id) }.reduce(0) { $0 + $1.projectedShortfall }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(realms) { realm in
                        Button {
                            if paying.contains(realm.id) { paying.remove(realm.id) }
                            else { paying.insert(realm.id) }
                        } label: {
                            HStack {
                                Image(systemName: paying.contains(realm.id) ? "checkmark.circle.fill" : "circle")
                                VStack(alignment: .leading) {
                                    Text(realm.name)
                                    Text("Production \(realm.productionContribution) · obligation \(realm.sustainObligation)")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("\(realm.projectedShortfall)").monospacedDigit()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Choose realms to sustain")
                } footer: {
                    Text("Any unchecked realm becomes dormant, never deleted. Assigned companions return safely.")
                }

                Section {
                    LabeledContent("Available essence", value: "\(store.state.base.essence)")
                    LabeledContent("Selected payment", value: "\(total)")
                    Button("Confirm settlement") {
                        store.settleAnchoredRealms(paying: paying)
                    }
                    .disabled(total > store.state.base.essence)
                }
            }
            .navigationTitle("Anchorage settlement")
            .interactiveDismissDisabled()
        }
    }
}

private struct RunExitSummaryView: View {
    @EnvironmentObject private var store: GameStore
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

                    if store.state.tutorial.firstReturnContext?.runIndex == summary.runIndex {
                        Text("Resources and objects crossed into the Base. Writing, discoveries and people are remembered in Reality even when part of a haul was lost.")
                            .font(.callout)
                            .multilineTextAlignment(.center)
                    }

                    sectionHeading("Recovered")
                    recapSection("Resources", gains: summary.resources)
                    recapSection("Loot", gains: summary.items)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Essence runway").font(.headline)
                        LabeledContent("Raw Essence collected", value: "\(summary.essenceEconomy.rawCollected)")
                        LabeledContent("Refined equivalent", value: "\(summary.essenceEconomy.refinedEquivalent)")
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
