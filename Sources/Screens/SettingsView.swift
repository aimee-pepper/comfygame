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
                    SettingsDestinationRow(
                        icon: "text.book.closed",
                        title: "Field Notes",
                        subtitle: "How writing and expeditions work"
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("settings.field-notes")

                Button {
                    campaigns.returnToCampaigns()
                } label: {
                    SettingsDestinationRow(
                        icon: "books.vertical",
                        title: "Save games",
                        subtitle: "Return to the campaign chooser",
                        directionIcon: "rectangle.portrait.and.arrow.right"
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("settings.save-games")

#if DEBUG
                NavigationLink {
                    DesignHomeworkView()
                } label: {
                    SettingsDestinationRow(
                        icon: "checklist.checked",
                        title: "Homework",
                        subtitle: "Design questions waiting for your decision"
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("settings.homework")

                NavigationLink {
                    DebugToolsView()
                } label: {
                    SettingsDestinationRow(
                        icon: "wrench.and.screwdriver.fill",
                        title: "Debug Tools",
                        subtitle: "Roadmap, balancing and authored-text review"
                    )
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

            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SettingsDestinationRow: View {
    let icon: String
    let title: String
    let subtitle: String
    var directionIcon = "chevron.right"

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Image(systemName: directionIcon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .frame(minHeight: 44)
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .contentShape(Rectangle())
    }
}

#if DEBUG
struct DesignHomeworkChoice: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let detail: String
}

struct DesignHomeworkQuestion: Codable, Identifiable, Equatable {
    struct ReviewItem: Codable, Identifiable, Equatable {
        let id: String
        let label: String
        let candidate: String
    }

    let id: String
    let title: String
    let context: String
    let recommendation: String
    let reviewItems: [ReviewItem]?
    let choices: [DesignHomeworkChoice]
}

struct DesignHomeworkCatalogue: Codable {
    let schemaVersion: Int
    let updated: String
    let questions: [DesignHomeworkQuestion]

    static let current: Self = {
        guard let url = Bundle.main.url(forResource: "design-homework", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let catalogue = try? JSONDecoder().decode(Self.self, from: data)
        else { preconditionFailure("Missing or invalid design-homework.json") }
        return catalogue
    }()
}

struct DesignHomeworkAnswer: Codable, Equatable {
    let questionID: String
    var choiceID: String?
    var customText: String
    var savedAt: Date
    var catalogueUpdated: String?
    var questionTitle: String?
    var choiceTitle: String?
}

struct DesignHomeworkExport: Codable {
    let schemaVersion: Int
    let catalogueUpdated: String
    var answers: [DesignHomeworkAnswer]
}

@MainActor
final class DesignHomeworkStore: ObservableObject {
    @Published private(set) var answers: [String: DesignHomeworkAnswer] = [:]
    let catalogue = DesignHomeworkCatalogue.current

    private let fileURL: URL

    init(fileURL: URL? = nil) {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.fileURL = fileURL ?? documents.appendingPathComponent("DesignHomeworkAnswers.json")
        if let data = try? Data(contentsOf: self.fileURL),
           let export = try? JSONDecoder().decode(DesignHomeworkExport.self, from: data) {
            answers = Dictionary(uniqueKeysWithValues: export.answers.map { ($0.questionID, $0) })
        }
    }

    func answer(for questionID: String) -> DesignHomeworkAnswer? { answers[questionID] }

    func save(questionID: String, choiceID: String?, customText: String) throws {
        let trimmed = customText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard choiceID != nil || !trimmed.isEmpty else { return }
        let question = catalogue.questions.first { $0.id == questionID }
        answers[questionID] = DesignHomeworkAnswer(
            questionID: questionID,
            choiceID: choiceID,
            customText: trimmed,
            savedAt: Date(),
            catalogueUpdated: catalogue.updated,
            questionTitle: question?.title,
            choiceTitle: question?.choices.first { $0.id == choiceID }?.title
        )
        try persist()
    }

    var exportURL: URL? {
        guard !answers.isEmpty else { return nil }
        try? persist()
        return fileURL
    }

    private func persist() throws {
        let payload = DesignHomeworkExport(
            schemaVersion: catalogue.schemaVersion,
            catalogueUpdated: catalogue.updated,
            answers: answers.values.sorted { $0.questionID < $1.questionID }
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(payload).write(to: fileURL, options: .atomic)
    }
}

private struct DesignHomeworkView: View {
    @StateObject private var store = DesignHomeworkStore()

    var body: some View {
        List {
            Section {
                Text("Each card is one decision. Answers stay on this device until you share the answer package or Engineering retrieves it from the connected development phone.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("Questions") {
                ForEach(store.catalogue.questions) { question in
                    NavigationLink {
                        DesignHomeworkQuestionView(question: question, store: store)
                    } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(question.title)
                                Text(store.answer(for: question.id) == nil ? "Needs an answer" : "Saved")
                                    .font(.caption)
                                    .foregroundStyle(store.answer(for: question.id) == nil ? .orange : .green)
                            }
                        } icon: {
                            Image(systemName: store.answer(for: question.id) == nil ? "questionmark.circle" : "checkmark.circle.fill")
                        }
                    }
                }
            }

            if let url = store.exportURL {
                Section("Review with the team") {
                    ShareLink(item: url) {
                        Label("Export saved answers", systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
        .navigationTitle("Homework")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct DesignHomeworkQuestionView: View {
    let question: DesignHomeworkQuestion
    @ObservedObject var store: DesignHomeworkStore
    @Environment(\.dismiss) private var dismiss
    @State private var selectedChoiceID: String?
    @State private var customText = ""
    @State private var saveError: String?
    private let retiredChoiceTitle: String?

    init(question: DesignHomeworkQuestion, store: DesignHomeworkStore) {
        self.question = question
        self.store = store
        let existing = store.answer(for: question.id)
        let currentChoiceIDs = Set(question.choices.map(\.id))
        let currentChoiceID = existing?.choiceID.flatMap { currentChoiceIDs.contains($0) ? $0 : nil }
        _selectedChoiceID = State(initialValue: currentChoiceID)
        _customText = State(initialValue: existing?.customText ?? "")
        retiredChoiceTitle = existing?.choiceID != nil && currentChoiceID == nil
            ? (existing?.choiceTitle ?? "A previous option")
            : nil
    }

    var body: some View {
        Form {
            Section {
                Text(question.context)
                VStack(alignment: .leading, spacing: 5) {
                    Label("Design recommendation", systemImage: "sparkles")
                        .font(.headline)
                    Text(question.recommendation)
                }
                .padding(.vertical, 4)
            }

            if let reviewItems = question.reviewItems, !reviewItems.isEmpty {
                Section("Exact proposed copy") {
                    ForEach(reviewItems) { item in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(item.label).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                            Text(item.candidate)
                        }
                        .padding(.vertical, 3)
                    }
                }
            }

            Section("Choose one") {
                if let retiredChoiceTitle {
                    Label("Previously saved: \(retiredChoiceTitle). That option has since been revised; choose again to update it.", systemImage: "clock.arrow.circlepath")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                ForEach(question.choices) { choice in
                    Button {
                        selectedChoiceID = choice.id
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: selectedChoiceID == choice.id ? "largecircle.fill.circle" : "circle")
                                .foregroundStyle(.tint)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(choice.title).foregroundStyle(.primary)
                                Text(choice.detail).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            Section("Something else") {
                Button {
                    selectedChoiceID = nil
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: selectedChoiceID == nil ? "largecircle.fill.circle" : "circle")
                            .foregroundStyle(.tint)
                        Text("None of these — write my answer")
                            .foregroundStyle(.primary)
                    }
                }
                .buttonStyle(.plain)
                TextEditor(text: $customText)
                    .frame(minHeight: 110)
                Text("Use this if none of the choices fit. You can also use it to qualify a selected answer.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            if let saveError {
                Section { Text(saveError).foregroundStyle(.red) }
            }
        }
        .navigationTitle(question.title)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button("Save answer") {
                do {
                    try store.save(questionID: question.id, choiceID: selectedChoiceID, customText: customText)
                    dismiss()
                } catch {
                    saveError = "Could not save this answer: \(error.localizedDescription)"
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedChoiceID == nil && customText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .frame(maxWidth: .infinity)
            .padding()
            .background(.bar)
        }
    }
}
#endif

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
#if DEBUG
                NavigationLink("Open level-one Normal / Teeming phone pair") {
                    EncounterScalingPhoneAcceptanceView()
                }
#endif
                resetSection("Creatures") {
                    settings.debugTuning.creatureDensityMultiplier = 1
                    settings.debugTuning.apexChanceMultiplier = 1
                    settings.debugTuning.encounterScalingProfile = .recommended
                }
            }

            Section("Combat v2 comparison harness") {
                NavigationLink("Open native true-graph route explorer") {
                    CombatGraphRouteExplorer()
                }
                Toggle("Use frozen v2 combat inputs", isOn: $settings.debugTuning.debugCombatV2BinderAttackEnabled)
                debugCombatNodeToggle("Heavy Hand · Crush +2",
                                      id: CombatDerivedStatsRules.Node.heavyHand)
                debugCombatNodeToggle("Keen Eye · Pierce +2",
                                      id: CombatDerivedStatsRules.Node.keenEye)
                debugCombatNodeToggle("Quick Step · initiative +4",
                                      id: CombatDerivedStatsRules.Node.quickStep)
                debugCombatNodeToggle("Light Frame · initiative +3",
                                      id: CombatDerivedStatsRules.Node.lightFrame)
                debugCombatNodeToggle("Thick Hide · next-expedition maximum HP +6",
                                      id: CombatDerivedStatsRules.Node.thickHide)
                debugCombatNodeToggle("Iron Skin · personal armour +2",
                                      id: CombatDerivedStatsRules.Node.ironSkin)
                debugCombatNodeToggle("Bulwark · self +1, same-rank allies +2",
                                      id: CombatDerivedStatsRules.Node.bulwark)
                debugCombatNodeToggle("Shieldwall · conscious front line +2",
                                      id: CombatDerivedStatsRules.Node.shieldwall)
                debugCombatNodeToggle("Immovable · armour applies to Pierce and emanation",
                                      id: CombatDerivedStatsRules.Node.immovable)
                debugCombatNodeToggle("Stagger · landed Crush has 30% next-round delay",
                                      id: CombatDerivedStatsRules.Node.stagger)
                debugCombatNodeToggle("Footwork · personal miss chance +6 points",
                                      id: CombatDerivedStatsRules.Node.footwork)
                debugCombatNodeToggle("Ghost · first direct attack misses once",
                                      id: CombatDerivedStatsRules.Node.ghost)
                debugCombatNodeToggle("Feint · +10 evasion after direct attack",
                                      id: CombatDerivedStatsRules.Node.feint)
                debugCombatNodeToggle("Untouchable · targeted misses build +5 evasion",
                                      id: CombatDerivedStatsRules.Node.untouchable)
                Picker("Binder Insulation", selection: debugBinderInsulationChoice) {
                    Text("Not owned").tag(EmanationKind?.none)
                    ForEach(EmanationKind.allCases, id: \.self) { kind in
                        Text(kind.rawValue.capitalized).tag(Optional(kind))
                    }
                }
                ForEach(store.state.base.activeParty, id: \.self) { index in
                    if store.state.base.roster.indices.contains(index) {
                        let name = store.state.base.roster[index].name
                        Text("\(name) v2 ownership").font(.subheadline.weight(.semibold))
                        debugCompanionNodeToggle("Quick Step · +4", index: index,
                                                 id: CombatDerivedStatsRules.Node.quickStep)
                        debugCompanionNodeToggle("Light Frame · +3", index: index,
                                                 id: CombatDerivedStatsRules.Node.lightFrame)
                        debugCompanionNodeToggle("Thick Hide · maximum HP +6", index: index,
                                                 id: CombatDerivedStatsRules.Node.thickHide)
                        debugCompanionNodeToggle("Iron Skin · personal armour +2", index: index,
                                                 id: CombatDerivedStatsRules.Node.ironSkin)
                        debugCompanionNodeToggle("Bulwark · self +1, same-rank allies +2", index: index,
                                                 id: CombatDerivedStatsRules.Node.bulwark)
                        debugCompanionNodeToggle("Shieldwall · conscious front line +2", index: index,
                                                 id: CombatDerivedStatsRules.Node.shieldwall)
                        debugCompanionNodeToggle("Immovable · armour applies to Pierce and emanation",
                                                 index: index,
                                                 id: CombatDerivedStatsRules.Node.immovable)
                        debugCompanionNodeToggle("Stagger · Crush delay", index: index,
                                                 id: CombatDerivedStatsRules.Node.stagger)
                        debugCompanionNodeToggle("Footwork · miss chance +6", index: index,
                                                 id: CombatDerivedStatsRules.Node.footwork)
                        debugCompanionNodeToggle("Ghost · one guaranteed miss", index: index,
                                                 id: CombatDerivedStatsRules.Node.ghost)
                        debugCompanionNodeToggle("Feint · +10 after direct attack", index: index,
                                                 id: CombatDerivedStatsRules.Node.feint)
                        debugCompanionNodeToggle("Untouchable · targeted misses build +5", index: index,
                                                 id: CombatDerivedStatsRules.Node.untouchable)
                        Picker("\(name) Insulation", selection: debugCompanionInsulationChoice(index)) {
                            Text("Not owned").tag(EmanationKind?.none)
                            ForEach(EmanationKind.allCases, id: \.self) { kind in
                                Text(kind.rawValue.capitalized).tag(Optional(kind))
                            }
                        }
                    }
                }
                if settings.debugTuning.debugCombatV2BinderAttackEnabled,
                   let preview = debugInitiativePreview {
                    ForEach(preview.entries, id: \.actor) { entry in
                        Text("\(debugActorName(entry.actor)) · \(entry.baseline)\(debugComponents(entry.components)) = \(entry.total)\(debugTieNote(entry, in: preview))")
                            .font(.caption.monospacedDigit())
                    }
                }
                if settings.debugTuning.debugCombatV2BinderAttackEnabled {
                    Text("Next encounter personal evasion")
                        .font(.subheadline.weight(.semibold))
                    ForEach(debugEvasionPreview?.entries ?? [], id: \.actor) { entry in
                        let footwork = entry.components.first {
                            $0.nodeID == CombatDerivedStatsRules.Node.footwork
                        }?.amount ?? 0
                        let ghostOwned: Bool = switch entry.actor {
                        case .binder: settings.debugTuning.debugCombatV2BinderNodeIDs.contains(CombatDerivedStatsRules.Node.ghost)
                        case .companion(let index): (settings.debugTuning.debugCombatV2CompanionNodeIDs[index] ?? []).contains(CombatDerivedStatsRules.Node.ghost)
                        case .foe: false
                        }
                        Text("\(debugActorName(entry.actor)) · base \(Int(entry.characterEvasion * 100))%\(footwork > 0 ? " + Footwork 6%" : "") = \(Int(entry.total * 100))% · frozen ownership: Ghost \(ghostOwned ? "owned" : "not owned"), Feint \(entry.ownsFeint == true ? "owned" : "not owned"), Untouchable \(entry.ownsUntouchable == true ? "owned" : "not owned")")
                            .font(.caption.monospacedDigit())
                    }
                    Text("Next encounter Insulation")
                        .font(.subheadline.weight(.semibold))
                    ForEach(debugResistancePreview?.entries ?? [], id: \.actor) { entry in
                        Text("\(debugActorName(entry.actor)) · \(entry.insulationChoice.map { "35% less \($0.rawValue.capitalized) emanation damage" } ?? "not owned or no valid choice")")
                            .font(.caption)
                    }
                    Text("Next expedition health caps")
                        .font(.subheadline.weight(.semibold))
                    ForEach(debugHealthCapPreview, id: \.member) { entry in
                        let thickHide = entry.components.first {
                            $0.nodeID == CombatDerivedStatsRules.Node.thickHide
                        }?.amount ?? 0
                        Text("\(debugActorName(entry.member.combatant)) · ordinary \(entry.ordinaryMaximum) → frozen \(entry.maximum) · \(thickHide == 0 ? "Thick Hide not owned" : "Thick Hide +\(thickHide)")")
                            .font(.caption.monospacedDigit())
                    }
                }
                if settings.debugTuning.debugCombatV2BinderAttackEnabled,
                   let receipt = debugArmourReceipt {
                    Text("Next encounter armour · current formation")
                        .font(.subheadline.weight(.semibold))
                    ForEach(receipt.entries, id: \.actor) { entry in
                        let breakdown = CombatDerivedStatsRules.incomingDamage(
                            raw: 0,
                            receiver: entry.actor,
                            receipt: receipt,
                            ranks: debugArmourRanks,
                            conscious: Set(receipt.entries.map(\.actor)),
                            armourIgnored: 0
                        ).breakdown
                        Text(debugArmourLine(entry.actor, breakdown: breakdown))
                            .font(.caption.monospacedDigit())
                        if entry.ownedNodeIDs.contains(CombatDerivedStatsRules.Node.immovable) {
                            Text("Immovable · this armour also applies to Pierce and direct Heat, Caustic, and Light")
                                .font(.caption)
                        }
                    }
                }
                Text("Explicit DEBUG ownership only. Party totals preview before contact; equal totals remain unresolved until the encounter's saved RNG breaks the tie. Exact inputs and final order freeze when combat opens.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Armour formation bonuses are resolved from the saved encounter rank and current consciousness. They intentionally have no single pre-contact total.")
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

    private var debugBinderInsulationChoice: Binding<EmanationKind?> {
        Binding(
            get: {
                guard settings.debugTuning.debugCombatV2BinderNodeIDs
                    .contains(CombatDerivedStatsRules.Node.insulation),
                      let choice = settings.debugTuning.debugCombatV2BinderChoices[
                        CombatDerivedStatsRules.Node.insulation]
                else { return nil }
                return EmanationKind(rawValue: choice.rawValue)
            },
            set: { choice in
                if let choice {
                    settings.debugTuning.debugCombatV2BinderNodeIDs
                        .insert(CombatDerivedStatsRules.Node.insulation)
                    settings.debugTuning.debugCombatV2BinderChoices[
                        CombatDerivedStatsRules.Node.insulation] = .init(rawValue: choice.rawValue)
                } else {
                    settings.debugTuning.debugCombatV2BinderNodeIDs
                        .remove(CombatDerivedStatsRules.Node.insulation)
                    settings.debugTuning.debugCombatV2BinderChoices[
                        CombatDerivedStatsRules.Node.insulation] = nil
                }
            })
    }

    private func debugCompanionInsulationChoice(_ index: Int) -> Binding<EmanationKind?> {
        Binding(
            get: {
                guard settings.debugTuning.debugCombatV2CompanionNodeIDs[index]?
                    .contains(CombatDerivedStatsRules.Node.insulation) == true,
                      let choice = settings.debugTuning.debugCombatV2CompanionChoices[index]?[
                        CombatDerivedStatsRules.Node.insulation]
                else { return nil }
                return EmanationKind(rawValue: choice.rawValue)
            },
            set: { choice in
                var nodes = settings.debugTuning.debugCombatV2CompanionNodeIDs[index] ?? []
                var choices = settings.debugTuning.debugCombatV2CompanionChoices[index] ?? [:]
                if let choice {
                    nodes.insert(CombatDerivedStatsRules.Node.insulation)
                    choices[CombatDerivedStatsRules.Node.insulation] = .init(rawValue: choice.rawValue)
                } else {
                    nodes.remove(CombatDerivedStatsRules.Node.insulation)
                    choices[CombatDerivedStatsRules.Node.insulation] = nil
                }
                settings.debugTuning.debugCombatV2CompanionNodeIDs[index] = nodes.isEmpty ? nil : nodes
                settings.debugTuning.debugCombatV2CompanionChoices[index] = choices.isEmpty ? nil : choices
            })
    }

    private var debugInitiativePreview: EncounterState.DebugV2InitiativeReceipt? {
        CombatDerivedStatsRules.debugInitiativeReceipt(
            enabled: settings.debugTuning.debugCombatV2BinderAttackEnabled,
            party: CombatRules.party(of: store.state), foes: [],
            binderNodeIDs: settings.debugTuning.debugCombatV2BinderNodeIDs,
            companionNodeIDs: settings.debugTuning.debugCombatV2CompanionNodeIDs)
    }

    private var debugHealthCapPreview: [RunHealthCapEntry] {
        CombatRules.expeditionHealthCaps(in: store.state, tuning: settings.debugTuning)
    }

    private var debugEvasionPreview: EncounterState.DebugV2EvasionReceipt? {
        CombatDerivedStatsRules.debugEvasionReceipt(
            enabled: settings.debugTuning.debugCombatV2BinderAttackEnabled,
            party: CombatRules.party(of: store.state), in: store.state,
            binderNodeIDs: settings.debugTuning.debugCombatV2BinderNodeIDs,
            companionNodeIDs: settings.debugTuning.debugCombatV2CompanionNodeIDs)
    }

    private var debugResistancePreview: EncounterState.DebugV2ResistanceReceipt? {
        CombatDerivedStatsRules.debugResistanceReceipt(
            enabled: settings.debugTuning.debugCombatV2BinderAttackEnabled,
            party: CombatRules.party(of: store.state),
            binderNodeIDs: settings.debugTuning.debugCombatV2BinderNodeIDs,
            binderChoices: settings.debugTuning.debugCombatV2BinderChoices,
            companionNodeIDs: settings.debugTuning.debugCombatV2CompanionNodeIDs,
            companionChoices: settings.debugTuning.debugCombatV2CompanionChoices)
    }

    private var debugArmourReceipt: EncounterState.DebugV2ArmourReceipt? {
        CombatRules.debugArmourReceipt(
            enabled: settings.debugTuning.debugCombatV2BinderAttackEnabled,
            party: store.state.base.partyMembers.map(\.combatant),
            in: store.state,
            binderNodeIDs: settings.debugTuning.debugCombatV2BinderNodeIDs,
            companionNodeIDs: settings.debugTuning.debugCombatV2CompanionNodeIDs
        )
    }

    private var debugArmourRanks: [Combatant: Rank] {
        Dictionary(uniqueKeysWithValues: store.state.base.partyMembers.map {
            ($0.combatant, CombatRules.rank(of: $0.combatant, in: store.state))
        })
    }

    private func debugArmourLine(
        _ actor: Combatant,
        breakdown: CombatDerivedStatsRules.ArmourBreakdown
    ) -> String {
        let equipment = String(format: "%.1f", breakdown.equipment)
        let components = breakdown.components.map {
            let source = $0.source == actor ? "self" : debugActorName($0.source)
            return "\($0.nodeID.rawValue.split(separator: ".").last?.replacingOccurrences(of: "_", with: " ").capitalisedSentence ?? $0.nodeID.rawValue) \(source) +\(Int($0.amount))"
        }
        let suffix = components.isEmpty ? "no v2 formation bonus" : components.joined(separator: ", ")
        return "\(debugActorName(actor)) · equipment×sturdiness \(equipment) · \(suffix) · total \(String(format: "%.1f", breakdown.totalBeforeIgnore))"
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

#if DEBUG
private struct EncounterScalingPhoneAcceptanceView: View {
    @State private var session: EncounterScalingPhoneFixtureSession?
    @State private var progressionSession: EncounterScalingProgressionFixtureSession?
    @State private var error: String?

    var body: some View {
        List {
            Section("Controlled pair") {
                Text("Both disposable fixtures use root 101, a fresh level-one Binder and Quill, no equipped weapons, Recommended scaling, full expedition HP and one disclosed level-one grazer. They never read or write a campaign slot.")
                    .font(.callout)
                ForEach(EncounterScalingPhoneFixtureKind.allCases) { kind in
                    Button {
                        do { session = try EncounterScalingPhoneFixtureSession(kind: kind) }
                        catch { self.error = error.localizedDescription }
                    } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(kind.title).font(.headline)
                            Text(kind.detail).font(.caption).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    }
                }
            }
            Section("Capture") {
                Text("Use the red bug button at the opening and again immediately before the finishing action. Record readability, fairness and whether retreat looked viable. Close returns here without changing the selected campaign.")
                    .font(.callout)
            }
            Section("Progression vectors") {
                Text("Ordinary fixtures keep root 101 and production scaling fixed while only party level and membership change. The apex fixture uses disclosed root 909. All are additive to the accepted level-one pair above.")
                    .font(.callout)
                ForEach(EncounterScalingProgressionFixtureKind.allCases) { kind in
                    Button {
                        do { progressionSession = try EncounterScalingProgressionFixtureSession(kind: kind) }
                        catch { self.error = error.localizedDescription }
                    } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(kind.title).font(.headline)
                            Text(kind.detail).font(.caption).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    }
                }
            }
            if let error {
                Section { Text(error).foregroundStyle(.red) }
            }
        }
        .navigationTitle("Level-one scaling")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $session) { fixture in
            ZStack(alignment: .topTrailing) {
                RootView().environmentObject(fixture.store)
                Button {
                    session = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .black.opacity(0.72))
                        .frame(width: 48, height: 48)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Close scaling fixture")
                .padding(.top, 4)
                .padding(.trailing, 4)
                .zIndex(20_000)
            }
        }
        .fullScreenCover(item: $progressionSession) { fixture in
            ZStack(alignment: .topTrailing) {
                RootView().environmentObject(fixture.store)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Frozen scaling receipt").font(.caption.bold())
                    ForEach(fixture.receipt.phoneSummaryLines, id: \.self) { line in
                        Text(line).font(.caption2.monospacedDigit())
                    }
                }
                .padding(10)
                .background(.black.opacity(0.82), in: RoundedRectangle(cornerRadius: 10))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 52)
                .padding(.horizontal, 10)
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("progression-scaling-receipt")
                .zIndex(19_999)
                Button { progressionSession = nil } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .black.opacity(0.72))
                        .frame(width: 48, height: 48)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Close progression scaling fixture")
                .padding(.top, 4).padding(.trailing, 4).zIndex(20_000)
            }
        }
    }
}
#endif
#endif

#Preview {
    NavigationStack {
        SettingsView().environmentObject(AppSettings())
    }
}
