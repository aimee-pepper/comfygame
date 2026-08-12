import SwiftUI

/// Settings. Currently appearance; it'll grow.
struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var store: GameStore
    @EnvironmentObject private var campaigns: CampaignAppCoordinator

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                StationCard(title: "Appearance", icon: "circle.lefthalf.filled") {
                    ForEach(AppTheme.allCases) { theme in
                        Button {
                            settings.theme = theme
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: theme.icon)
                                    .frame(width: 24)
                                    .foregroundStyle(.tint)
                                Text(theme.displayName)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if settings.theme == theme {
                                    Image(systemName: "checkmark").foregroundStyle(.tint)
                                }
                            }
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }

                NavigationLink {
                    FieldNotesView().environmentObject(store)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "text.book.closed").frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Field Notes")
                            Text("How writing and expeditions work")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold)).foregroundStyle(.tertiary)
                    }
                    .frame(minHeight: 44)
                    .padding(14)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("settings.field-notes")

                Button {
                    campaigns.returnToCampaigns()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "books.vertical").frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Save games")
                            Text("Return to the campaign chooser")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.backward")
                            .font(.caption.weight(.semibold)).foregroundStyle(.tertiary)
                    }
                    .frame(minHeight: 44)
                    .padding(14)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("settings.save-games")

#if DEBUG
                NavigationLink {
                    DebugToolsView()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "wrench.and.screwdriver.fill").frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Debug Tools")
                            Text("Roadmap, balancing and authored-text review")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(.tertiary)
                    }
                    .frame(minHeight: 44)
                    .padding(14)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("settings.debug-tools")
#endif

                Label {
                    Text("System follows your phone, including its sunset schedule. Dark overrides it — for when the phone is bright and you are not.")
                } icon: {
                    Image(systemName: "moon.zzz")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))

                ComingLater("Text size, haptics and a colour-blind-safe palette belong here too — milestone 6 is the ergonomics pass.")
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if DEBUG
struct BalancingView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var store: GameStore
    @AppStorage("debug.simpleMapRenderer") private var useSimpleMapRenderer = false

    var body: some View {
        Form {
            if !settings.debugTuning.isDefault {
                Section {
                    Label("Custom tuning applies to the next world you bind.", systemImage: "exclamationmark.circle.fill")
                        .foregroundStyle(.orange)
                }
            }

            Section("Resources") {
                Picker("Raw essence profile", selection: $settings.debugTuning.rawEssenceProfile) {
                    ForEach(DebugTuningProfile.RawEssenceProfile.allCases, id: \.self) {
                        Text($0.displayName).tag($0)
                    }
                }
                tuningSlider("Raw essence frequency", value: $settings.debugTuning.rawEssenceFrequencyMultiplier)
                tuningSlider("Raw essence yield", value: $settings.debugTuning.rawEssenceYieldMultiplier)
                tuningSlider("World-resource node density", value: $settings.debugTuning.resourceNodeDensityMultiplier)
                resetSection("Resources") {
                    settings.debugTuning.rawEssenceProfile = .recommended
                    settings.debugTuning.rawEssenceFrequencyMultiplier = 1
                    settings.debugTuning.rawEssenceYieldMultiplier = 1
                    settings.debugTuning.resourceNodeDensityMultiplier = 1
                }
            }

            Section("Writing") {
                percentageSlider("Chance of a second page",
                                 value: $settings.debugTuning.additionalPageChance,
                                 range: 0...0.5,
                                 defaultValue: Tuning.Library.additionalPageChance)
                percentageSlider("Diary share",
                                 value: $settings.debugTuning.diaryWritingShare,
                                 range: 0...1,
                                 defaultValue: Tuning.Library.diaryWritingShare)
                integerStepper("Diary patience floor",
                               value: $settings.debugTuning.diaryPatienceWorlds,
                               range: 0...20,
                               suffix: " worlds",
                               defaultValue: Tuning.Library.patienceInWorlds)
                integerStepper("Blind traveller window",
                               value: $settings.debugTuning.blindDiscoveryWindow,
                               range: 1...6,
                               suffix: " places",
                               defaultValue: 3)
                tuningSlider("Recovered-clue evidence weight",
                             value: $settings.debugTuning.travellerClueEvidenceWeight,
                             range: 0...4, defaultValue: 1)
                tuningSlider("Causally authored evidence weight",
                             value: $settings.debugTuning.travellerAuthoredEvidenceWeight,
                             range: 0...4, defaultValue: 2)
                percentageSlider("Traveller arrival floor",
                                 value: $settings.debugTuning.travellerArrivalChanceFloor,
                                 range: 0...1, defaultValue: 0.25)
                percentageSlider("Traveller near-miss protection",
                                 value: $settings.debugTuning.travellerArrivalNearMissIncrement,
                                 range: 0...1, defaultValue: 0.25)
                Text("Every world still guarantees one writing. This only controls the chance of another.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                resetSection("Writing") {
                    settings.debugTuning.additionalPageChance = Tuning.Library.additionalPageChance
                    settings.debugTuning.diaryWritingShare = Tuning.Library.diaryWritingShare
                    settings.debugTuning.diaryPatienceWorlds = Tuning.Library.patienceInWorlds
                    settings.debugTuning.blindDiscoveryWindow = 3
                    settings.debugTuning.travellerClueEvidenceWeight = 1
                    settings.debugTuning.travellerAuthoredEvidenceWeight = 2
                    settings.debugTuning.travellerArrivalChanceFloor = 0.25
                    settings.debugTuning.travellerArrivalNearMissIncrement = 0.25
                }
            }

            Section("Creatures") {
                tuningSlider("Creature density", value: $settings.debugTuning.creatureDensityMultiplier)
                tuningSlider("Apex chance", value: $settings.debugTuning.apexChanceMultiplier,
                             range: 0...3)
                Picker("Encounter scaling comparison", selection: $settings.debugTuning.encounterScalingProfile) {
                    ForEach(DebugTuningProfile.EncounterScalingProfile.allCases, id: \.self) {
                        Text($0.displayName).tag($0)
                    }
                }
                Text("Recommended anchors level to the Binder, adds only visible reachable foes, and freezes additive party pressure plus apex tempo when combat opens. Legacy, Reserved and Pressing remain historical DEBUG comparisons.")
                    .font(.caption).foregroundStyle(.secondary)
                resetSection("Creatures") {
                    settings.debugTuning.creatureDensityMultiplier = 1
                    settings.debugTuning.apexChanceMultiplier = 1
                    settings.debugTuning.encounterScalingProfile = .recommended
                }
            }

            Section("Combat v2 comparison harness") {
                Toggle("Use frozen v2 combat inputs", isOn: $settings.debugTuning.debugCombatV2BinderAttackEnabled)
                debugCombatNodeToggle("Heavy Hand · Crush +2",
                                      id: CombatDerivedStatsRules.Node.heavyHand)
                debugCombatNodeToggle("Keen Eye · Pierce +2",
                                      id: CombatDerivedStatsRules.Node.keenEye)
                debugCombatNodeToggle("Quick Step · initiative +4",
                                      id: CombatDerivedStatsRules.Node.quickStep)
                debugCombatNodeToggle("Light Frame · initiative +3",
                                      id: CombatDerivedStatsRules.Node.lightFrame)
                ForEach(store.state.base.activeParty, id: \.self) { index in
                    if store.state.base.roster.indices.contains(index) {
                        let name = store.state.base.roster[index].name
                        Text("\(name) initiative ownership").font(.subheadline.weight(.semibold))
                        debugCompanionNodeToggle("Quick Step · +4", index: index,
                                                 id: CombatDerivedStatsRules.Node.quickStep)
                        debugCompanionNodeToggle("Light Frame · +3", index: index,
                                                 id: CombatDerivedStatsRules.Node.lightFrame)
                    }
                }
                if settings.debugTuning.debugCombatV2BinderAttackEnabled,
                   let preview = debugInitiativePreview {
                    ForEach(preview.entries, id: \.actor) { entry in
                        Text("\(debugActorName(entry.actor)) · \(entry.baseline)\(debugComponents(entry.components)) = \(entry.total)\(debugTieNote(entry, in: preview))")
                            .font(.caption.monospacedDigit())
                    }
                }
                Text("Explicit DEBUG ownership only. Party totals preview before contact; equal totals remain unresolved until the encounter's saved RNG breaks the tie. Exact inputs and final order freeze when combat opens.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Picker("Opening encounter envelope",
                       selection: $settings.debugTuning.openingEncounterEnvelope) {
                    ForEach(DebugTuningProfile.OpeningEncounterEnvelope.allCases, id: \.self) {
                        Text($0.displayName).tag($0)
                    }
                }
                Text("Only the first expedition of a fresh campaign. Gentle keeps at most one ordinary mobile enemy in the revealed entry area; Clear approach keeps none. Enemies are relocated, never deleted.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("Reset Test Setup") {
                    settings.debugTuning.openingEncounterEnvelope = .natural
                }
                .font(.caption)
            } header: {
                Text("Test Setup")
            } footer: {
                if settings.debugTuning.openingEncounterEnvelope != .natural {
                    Label("TEST SETUP ACTIVE", systemImage: "wrench.and.screwdriver.fill")
                        .foregroundStyle(.orange)
                }
            }

            Section {
                tuningSlider("Stability duration", value: $settings.debugTuning.stabilityDurationMultiplier,
                             range: 0.5...2)
                percentageSlider("Collapse recovery",
                                 value: $settings.debugTuning.collapseRecoveryFraction,
                                 range: 0...1,
                                 defaultValue: Tuning.World.collapseHaulKeptFraction)
                resetSection("World duration") {
                    settings.debugTuning.stabilityDurationMultiplier = 1
                    settings.debugTuning.collapseRecoveryFraction = Tuning.World.collapseHaulKeptFraction
                }
            } header: {
                Text("World duration")
            } footer: {
                Text("Scope: next world. Existing expeditions keep the values they began with.")
            }

            Section("Navigation") {
                integerStepper("Base vision radius",
                               value: $settings.debugTuning.baseVisionRadius,
                               range: 1...6,
                               suffix: " tiles",
                               defaultValue: Tuning.World.baseVisionRadius)
                integerStepper("Slow-ground extra turns",
                               value: $settings.debugTuning.slowGroundExtraTurns,
                               range: 0...3, suffix: " turns", defaultValue: 1)
                resetSection("Navigation") {
                    settings.debugTuning.baseVisionRadius = Tuning.World.baseVisionRadius
                    settings.debugTuning.slowGroundExtraTurns = 1
                }
            }

            Section("Rendering") {
                Toggle("Use simple map renderer", isOn: $useSimpleMapRenderer)
                Text("DEBUG fallback for comparing the native 16px terrain/flora renderer with the previous flat map. It does not change world rules or save data.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Flora") {
                tuningSlider("Active-flora frequency",
                             value: $settings.debugTuning.activeFloraFrequencyMultiplier,
                             range: 0...3)
                tuningSlider("Thorn / toxin severity",
                             value: $settings.debugTuning.floraHazardSeverityMultiplier,
                             range: 0.5...2)
                resetSection("Flora") {
                    settings.debugTuning.activeFloraFrequencyMultiplier = 1
                    settings.debugTuning.floraHazardSeverityMultiplier = 1
                }
            }

            Section {
                Button("Reset All", role: .destructive) {
                    settings.debugTuning = .defaults
                }
                .disabled(settings.debugTuning.isDefault)
            } footer: {
                Text("This profile is stored separately from your game save. Existing worlds never change.")
            }
        }
        .navigationTitle("Balancing")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func debugCombatNodeToggle(_ title: String, id: CombatNodeID) -> some View {
        Toggle(title, isOn: Binding(
            get: { settings.debugTuning.debugCombatV2BinderNodeIDs.contains(id) },
            set: { enabled in
                if enabled { settings.debugTuning.debugCombatV2BinderNodeIDs.insert(id) }
                else { settings.debugTuning.debugCombatV2BinderNodeIDs.remove(id) }
            }))
    }

    private func debugCompanionNodeToggle(_ title: String, index: Int,
                                          id: CombatNodeID) -> some View {
        Toggle(title, isOn: Binding(
            get: { settings.debugTuning.debugCombatV2CompanionNodeIDs[index]?.contains(id) == true },
            set: { enabled in
                var nodes = settings.debugTuning.debugCombatV2CompanionNodeIDs[index] ?? []
                if enabled { nodes.insert(id) } else { nodes.remove(id) }
                if nodes.isEmpty { settings.debugTuning.debugCombatV2CompanionNodeIDs.removeValue(forKey: index) }
                else { settings.debugTuning.debugCombatV2CompanionNodeIDs[index] = nodes }
            }))
    }

    private var debugInitiativePreview: EncounterState.DebugV2InitiativeReceipt? {
        CombatDerivedStatsRules.debugInitiativeReceipt(
            enabled: settings.debugTuning.debugCombatV2BinderAttackEnabled,
            party: CombatRules.party(of: store.state), foes: [],
            binderNodeIDs: settings.debugTuning.debugCombatV2BinderNodeIDs,
            companionNodeIDs: settings.debugTuning.debugCombatV2CompanionNodeIDs)
    }

    private func debugActorName(_ actor: Combatant) -> String {
        switch actor {
        case .binder: "Binder"
        case .companion(let index):
            store.state.base.roster.indices.contains(index) ? store.state.base.roster[index].name : "Companion \(index)"
        case .foe: "Foe"
        }
    }

    private func debugComponents(_ components: [EncounterState.DebugV2InitiativeReceipt.Component]) -> String {
        components.map { " + \($0.amount) [\($0.nodeID.rawValue)]" }.joined()
    }

    private func debugTieNote(_ entry: EncounterState.DebugV2InitiativeReceipt.Entry,
                              in receipt: EncounterState.DebugV2InitiativeReceipt) -> String {
        receipt.entries.filter { $0.total == entry.total }.count > 1 ? " · equal total: order unresolved" : ""
    }

    private func tuningSlider(_ title: String, value: Binding<Double>,
                              range: ClosedRange<Double> = 0.25...3,
                              defaultValue: Double = 1) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                Spacer()
                Text(value.wrappedValue.formatted(.number.precision(.fractionLength(2)))
                     + "× · default \(defaultValue.formatted(.number.precision(.fractionLength(2))))×")
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: range, step: 0.25)
                .accessibilityLabel(title)
        }
        .padding(.vertical, 4)
    }

    private func percentageSlider(_ title: String, value: Binding<Double>,
                                  range: ClosedRange<Double>, defaultValue: Double) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                Spacer()
                Text(value.wrappedValue.formatted(.percent.precision(.fractionLength(0)))
                     + " · default \(defaultValue.formatted(.percent.precision(.fractionLength(0))))")
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: range, step: 0.05)
                .accessibilityLabel(title)
        }
        .padding(.vertical, 4)
    }

    private func integerStepper(_ title: String, value: Binding<Int>,
                                range: ClosedRange<Int>, suffix: String,
                                defaultValue: Int) -> some View {
        Stepper(value: value, in: range) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text("\(value.wrappedValue)\(suffix) · default \(defaultValue)\(suffix)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func resetSection(_ name: String, action: @escaping () -> Void) -> some View {
        Button("Reset \(name)", action: action)
            .font(.caption)
    }
}
#endif

#Preview {
    NavigationStack {
        SettingsView().environmentObject(AppSettings())
    }
}
