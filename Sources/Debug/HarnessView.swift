import SwiftUI

/// The force-quit/resume harness. Reached from the wrench in the Base screen's toolbar.
///
/// How to use it (this is the acceptance test from the brief):
///  1. Press actions until the state reads as something memorable — mid-encounter is the
///     interesting case.
///  2. Check that **in memory** and **on disk** show the same mutation number.
///  3. Force-quit from the app switcher.
///  4. Relaunch. Every number below must be identical, except `launches`, which goes up by one.
///
/// Portrait, one-handed: actions sit at the bottom of the scroll in the thumb zone, all ≥44pt.
struct HarnessView: View {
    @EnvironmentObject private var store: GameStore
    @State private var isShowingWipeConfirmation = false

    private var state: GameState { store.state }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                saveStatus
                realityCard
                baseCard
                worldsCard
                actions
                dangerZone
                footnote
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Save & Resume Test")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Save status

    private var saveStatus: some View {
        Card(title: "Save", icon: "externaldrive.fill") {
            Row("Loaded as", store.diagnostics.loadOutcome)
            Row("Changes in memory", "\(state.meta.mutationCount)")
            Row("Changes saved", "\(store.diagnostics.savedMutationCount)")
            Row("Last action", state.meta.lastAction)
            Row("Saves this session", "\(store.diagnostics.writeCount)")
            Row("Save-file size", store.diagnostics.saveFileByteCount.map { "\($0) bytes" } ?? "—")

            HStack(spacing: 8) {
                Circle()
                    .fill(isInSync ? Color.green : Color.orange)
                    .frame(width: 10, height: 10)
                Text(isInSync ? "Save is up to date — safe to force-quit" : "Saving changes…")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(isInSync ? .green : .orange)
            }
            .padding(.top, 4)

            if let error = store.diagnostics.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Text(store.diagnostics.saveURL.path(percentEncoded: false))
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .padding(.top, 4)
        }
    }

    private var isInSync: Bool {
        state.meta.mutationCount == store.diagnostics.savedMutationCount
    }

    // MARK: - Layers

    private var realityCard: some View {
        Card(title: "Shared progress — kept across saves", icon: "sparkles") {
            Row("Motes", "\(state.reality.motes)")
            Row("Creatures discovered", "\(state.reality.discovery.encounteredCreatureCount) of \(ContentCatalog.shared.creatures.count)")
            Row("Resources discovered", "\(state.reality.discovery.encounteredResourceCount) of \(ContentCatalog.shared.resources.count)")
            Row("Expeditions started", "\(state.reality.lifetime.runsStarted)")
            Row("Returned / lost to collapse", "\(state.reality.lifetime.runsBankedViaPortal) / \(state.reality.lifetime.runsLostToCollapse)")
            Row("World turns", "\(state.reality.lifetime.worldTurnsTaken)")
            Row("Encounters won", "\(state.reality.lifetime.encountersWon)")

            if !state.reality.discovery.creatures.isEmpty {
                DiscoveryStrip(discovery: state.reality.discovery)
                    .padding(.top, 4)
            }
        }
    }

    private var baseCard: some View {
        Card(title: "Village — kept between expeditions", icon: "house.fill") {
            Row("Essence", "\(state.base.essence)")
            Row("Sigils known", "\(state.base.ownedSymbols.count)")
            Row("Gambit parts known", "\(state.base.ownedGambitComponents.count) of \(ContentCatalog.shared.gambitComponents.count)")
            Row("Upgrades completed", "\(state.base.completedResearch.count) of \(ContentCatalog.shared.researchNodes.count)")
            Row("Stored item stacks", "\(state.base.inventory.stacks.count) / \(state.base.inventory.slots)")
            Row("Destinations unlocked", "\(state.base.stations.values.count(where: { $0.isUnlocked }))")
            if state.base.resources.isEmpty {
                Row("Resources", "—")
            } else {
                ForEach(state.base.resources.nonZero, id: \.id) { entry in
                    Row(ContentCatalog.shared.resource(entry.id)?.name.lowercased() ?? "Unknown resource", "\(entry.amount)")
                }
            }
        }
    }

    @ViewBuilder
    private var worldsCard: some View {
        Card(title: "Current expedition — cleared after return", icon: "globe.europe.africa.fill") {
            if let run = state.worlds.activeRun {
                Row("Expedition", "#\(run.runIndex)")
                Row("Internal world seed", String(run.mapSeed, radix: 16, uppercase: true))
                Row("Page Sigils", run.book.allSymbolIDs.map { id in
                    ContentCatalog.shared.symbol(id)?.name ?? "Unknown Sigil"
                }.joined(separator: " + "))
                Row("Sigils chosen by the world", run.book.randomlyFilled.isEmpty
                    ? "none"
                    : run.book.randomlyFilled.map { slot in
                        run.book.symbols[slot].flatMap { ContentCatalog.shared.symbol($0)?.name }
                            ?? "Unknown Sigil"
                    }.sorted().joined(separator: ", "))
                Row("Turns taken", "\(run.turnsTaken)")
                Row("World cycle", "\(run.clock.bandName) · underlying period \(run.clock.isStopped ? "—" : "\(run.clock.basePeriod) turns")")
                Row("Light-cycle settings", "peak \(Int(run.clock.cyclePeak.rounded())) · regularity \(Int(run.clock.regularity.rounded())) · amplitude \(Int(run.clock.amplitude.rounded()))")
                Row("Time of day", run.clock.isStopped
                    ? (run.isNight ? "held dark" : "held day")
                    : run.dayPhase.formatted(.percent.precision(.fractionLength(0))))
                let transitions = run.nextLightTransitions()
                Row("Next changes", transitions.isEmpty
                    ? "none"
                    : transitions.map { "t\($0.turn) \($0.isNight ? "nightfall" : "daybreak")" }
                        .joined(separator: " · "))
                Row("Creature species", "\(run.cast.count)")
                Row("Creature placements", "\(run.enemies.count)")
                Row("Flora placements", "\(run.flora.count)")
                Row("Apex", run.enemies.contains(where: \.isApex) ? "placed" : "none")
                Row("Writing found", "\(run.map.allPoints.count { point in if case .diaryPage = run.map[point].content { true } else { false } }) diary · \(run.foundWritings.count) other")
                Row("Binder HP", "\(run.binderHP) / \(Tuning.Encounter.binderMaxHP)")
                Row("Internal random draws", "\(run.rng.drawCount)")

                StabilityBar(stability: run.stability, band: run.stabilityBand)
                    .padding(.vertical, 4)

                if run.satchel.isEmpty {
                    Row("satchel", "empty")
                } else {
                    ForEach(run.satchel.nonZero, id: \.id) { entry in
                        Row("satchel · \(ContentCatalog.shared.resource(entry.id)?.name.lowercased() ?? "Unknown resource")", "\(entry.amount)")
                    }
                }

                if let encounter = run.activeEncounter {
                    Divider().padding(.vertical, 4)
                    Text("IN ENCOUNTER · round \(encounter.roundNumber)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.red)
                    ForEach(encounter.foes) { foe in
                        Row(foe.stats.displayName, "\(foe.currentHP) / \(foe.maxHP) HP")
                    }
                    if let last = encounter.log.last {
                        Text(last).font(.caption).foregroundStyle(.secondary)
                    }
                }
            } else {
                Row("Status", "At the Village — no active expedition")
                Row("Expeditions so far", "\(state.worlds.runIndex)")
                Row("Next world seed · internal", String(state.worlds.seeds.peekNextSeed(), radix: 16, uppercase: true))
                Row("World preview cost", costRange)
            }
        }
    }

    private var costRange: String {
        let cost = store.bookProjection.essenceCost
        return cost.isPoint ? "\(cost.lowerBound) essence" : "\(cost.lowerBound)–\(cost.upperBound) essence"
    }

    // MARK: - Actions

    private var actions: some View {
        Card(title: "Actions", icon: "hand.tap.fill") {
            Text("World actions remain on the World screen during an expedition. This test is available from the Village.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom, 4)

            HarnessButton("Find a mote", icon: "star.fill") { store.harnessGainMote() }
            HarnessButton("Grant every piece of gear", icon: "shield.lefthalf.filled") { store.harnessGrantGear() }
            HarnessButton("Prepare instrument crafting", icon: "wrench.adjustable.fill") {
                store.harnessPrepareInstrumentCrafting()
            }
            HarnessButton("Prepare the Apothecary", icon: "cross.vial.fill") {
                store.harnessPrepareApothecary()
            }
            HarnessButton("Analysis tier: \(store.state.reality.analysisTier) of \(Tuning.Analysis.livingTier)",
                          icon: "eyeglasses") { store.harnessCycleAnalysisTier() }
        }
    }

    private var dangerZone: some View {
        Card(title: "Layer separation", icon: "square.3.layers.3d") {
            Text("This clears village and expedition data but keeps Motes, Bestiary entries, and lifetime statistics shared across saves.")
                .font(.caption)
                .foregroundStyle(.secondary)
            HarnessButton("Reset Village, keep shared progress", icon: "arrow.counterclockwise", role: .destructive) {
                store.resetBaseKeepingReality()
            }
            HarnessButton("Wipe the save entirely", icon: "trash.fill", role: .destructive) {
                isShowingWipeConfirmation = true
            }
            .confirmationDialog("Wipe the save?", isPresented: $isShowingWipeConfirmation, titleVisibility: .visible) {
                Button("Wipe everything", role: .destructive) { store.resetEverything() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private var footnote: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Force-quit test")
                .font(.footnote.weight(.semibold))
            Text("Note the numbers above, force-quit from the app switcher, relaunch. Everything must match, except **launches**, which goes up by one. Try it mid-encounter.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
    }
}

// MARK: - Small pieces

private struct Card<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.bottom, 2)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct Row: View {
    let label: String
    let value: String

    init(_ label: String, _ value: String) {
        self.label = label
        self.value = value
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.callout)
                .foregroundStyle(.secondary)
            Spacer(minLength: 12)
            Text(value)
                .font(.system(.callout, design: .monospaced))
                .multilineTextAlignment(.trailing)
        }
    }
}

private struct HarnessButton: View {
    let title: String
    let icon: String
    var role: ButtonRole?
    var isEnabled: Bool
    let action: () -> Void

    init(_ title: String, icon: String, role: ButtonRole? = nil, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.role = role
        self.isEnabled = isEnabled
        self.action = action
    }

    var body: some View {
        Button(role: role, action: action) {
            Label(title, systemImage: icon)
                .font(.callout.weight(.medium))
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(minHeight: 44) // pillar 3: ≥44pt touch targets
                .contentShape(Rectangle())
        }
        .buttonStyle(.bordered)
        .tint(role == .destructive ? .red : .accentColor)
        .disabled(!isEnabled)
    }
}

/// Stability meter — always visible during a run.
private struct StabilityBar: View {
    let stability: Double
    let band: StabilityBand

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Stability").font(.callout).foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(stability.rounded())) · \(band.displayName)")
                    .font(.system(.callout, design: .monospaced))
                    .foregroundStyle(color)
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.tertiarySystemFill))
                    Capsule()
                        .fill(color)
                        .frame(width: proxy.size.width * (stability / Tuning.World.startingStability))
                }
            }
            .frame(height: 8)
        }
    }

    private var color: Color {
        switch band {
        case .stable: .green
        case .hazardous: .yellow
        case .crumbling: .orange
        case .collapsed: .red
        }
    }
}

/// The encounter-flag registry, rendered the way the pre-bind preview eventually will:
/// silhouette until encountered, real icon afterwards.
private struct DiscoveryStrip: View {
    let discovery: DiscoveryLog

    var body: some View {
        HStack(spacing: 12) {
            ForEach(ContentCatalog.shared.creatures) { creature in
                let seen = discovery.hasEncountered(creature: creature.id)
                VStack(spacing: 2) {
                    Image(systemName: seen ? creature.icon : "questionmark")
                        .font(.title3)
                        .foregroundStyle(seen ? Color.primary : Color.secondary.opacity(0.4))
                    Text(seen ? "×\(discovery.creatures[creature.id]?.timesEncountered ?? 0)" : "—")
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                }
                .frame(minWidth: 44, minHeight: 44)
            }
            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        HarnessView()
            .environmentObject(GameStore(io: .temporary(name: "preview")))
    }
}
