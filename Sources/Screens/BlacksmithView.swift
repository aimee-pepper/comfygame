import SwiftUI

/// The Blacksmith: where the piece you already carry gets better.
///
/// The screen has one job, and it's a question the player arrives with: *what should I put my
/// materials into?* So it lists everything reforgeable — worn and stored, both party members — and
/// each row says the price and whether you can pay it, without you having to open anything.
struct BlacksmithView: View {
    @EnvironmentObject private var store: GameStore
    @State private var chosen: ReforgeTarget?
    @State private var chosenRecipe: PhysicalGearCraftingRules.Recipe?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    CurrencyChip(icon: "drop.fill", label: "Essence",
                                 value: "\(store.state.base.essence)", tint: .teal)
                    CurrencyChip(icon: "shippingbox", label: "Stock",
                                 value: "\(store.materialSampleCount)")
                }

                StationCard(title: "At the anvil", icon: "hammer.fill") {
                    Text("Reforging asks for stock with the right quality in it, never for a named thing. A monstrous plate does a blade as much good as ore does — what matters is how hard it is.")
                        .font(.caption).foregroundStyle(.secondary)
                }

                StationCard(title: "Construct", icon: "hammer.circle") {
                    ForEach(PhysicalGearCraftingRules.recipes) { recipe in
                        ConstructionRow(recipe: recipe) { chosenRecipe = recipe }
                    }
                }

                if store.reforgeable.isEmpty {
                    StationCard(title: "Nothing to work on", icon: "questionmark") {
                        EmptyNote("Bring back something to wear, and something hard to work it with.")
                    }
                } else {
                    StationCard(title: "Gear", icon: "shield.lefthalf.filled") {
                        ForEach(store.reforgeable) { target in
                            ReforgeRow(target: target) { chosen = target }
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Blacksmith")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $chosen) { target in
            ReforgeSheet(target: target).environmentObject(store)
        }
        .sheet(item: $chosenRecipe) { recipe in
            ConstructionSheet(recipe: recipe).environmentObject(store)
        }
    }
}

private struct ConstructionRow: View {
    @EnvironmentObject private var store: GameStore
    let recipe: PhysicalGearCraftingRules.Recipe
    let tap: () -> Void

    var body: some View {
        Button(action: tap) {
            HStack(spacing: 10) {
                Image(systemName: ContentCatalog.shared.item(recipe.catalogFallback)?.icon ?? "hammer")
                    .frame(width: 22).foregroundStyle(.teal)
                VStack(alignment: .leading, spacing: 2) {
                    Text(recipe.displayName).font(.callout.weight(.medium))
                    Text(summary).font(.caption2).foregroundStyle(.secondary)
                }
                Spacer(minLength: 6)
                status
                Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.tertiary)
            }
            .frame(minHeight: 44).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var summary: String {
        "\(recipe.requirements.count) selected samples · Tier 1–\(PhysicalGearCraftingRules.constructionCap(for: recipe, in: store.state))"
    }

    @ViewBuilder private var status: some View {
        switch store.physicalGearReadiness(recipe) {
        case .ready(let preview):
            Text("Tier \(preview.outputTier) · \(preview.essence)")
                .font(.caption2.weight(.medium)).foregroundStyle(.green)
        case .stationLocked:
            Text("locked").font(.caption2).foregroundStyle(.secondary)
        case .researchLocked:
            Text("learn Wear").font(.caption2).foregroundStyle(.secondary)
        case .tierLocked(let need):
            Text("tier \(need)").font(.caption2).foregroundStyle(.secondary)
        case .needsSamples:
            Text("needs stock").font(.caption2).foregroundStyle(.orange)
        case .needsEssence(_, let need):
            Text("\(need) essence").font(.caption2).foregroundStyle(.orange)
        }
    }
}

struct BowyerView: View {
    @EnvironmentObject private var store: GameStore
    @State private var chosenRecipe: PhysicalGearCraftingRules.Recipe?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    CurrencyChip(icon: "drop.fill", label: "Essence",
                                 value: "\(store.state.base.essence)", tint: .green)
                    CurrencyChip(icon: "shippingbox", label: "Stock",
                                 value: "\(store.materialSampleCount)")
                }
                StationCard(title: "Far reach", icon: "arrow.up.right") {
                    Text("Fen builds maintained ranged sets rather than ammunition chores. Every family reaches the far rank; the selected materials decide its quality and history.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                StationCard(title: "Construct", icon: "arrow.up.right.circle") {
                    ForEach(PhysicalGearCraftingRules.bowyerRecipes) { recipe in
                        ConstructionRow(recipe: recipe) { chosenRecipe = recipe }
                    }
                }
                StationCard(title: "Fen's work", icon: "point.3.connected.trianglepath.dotted") {
                    ResearchTree(station: Stations.bowyer)
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Bowyer")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $chosenRecipe) { recipe in
            ConstructionSheet(recipe: recipe).environmentObject(store)
        }
    }
}

struct ArmouryView: View {
    @EnvironmentObject private var store: GameStore
    @State private var showLegacy = false
    @State private var chosenTarget: ArmouryRules.Target?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                StationCard(title: "Rebuild protection", icon: "shield.lefthalf.filled") {
                    Text("Choose one familiar protective piece. Bracken keeps its identity, slot and wearer while rebuilding what its construction does.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                StationCard(title: "Protective pieces", icon: "shield") {
                    Toggle("Show legacy masterworks", isOn: $showLegacy)
                    ForEach(ArmouryRules.targets(in: store.state, includeLegacy: showLegacy)) { target in
                        Button { chosenTarget = target } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(target.displayName).foregroundStyle(.primary)
                                    Text(target.slot?.rawValue.capitalisedSentence ?? "Unknown slot")
                                        .font(.caption2).foregroundStyle(.secondary)
                                }
                                Spacer()
                                if target.isLegacyMasterwork {
                                    Text("Legacy").font(.caption2).foregroundStyle(.orange)
                                }
                                Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.tertiary)
                            }.frame(minHeight: 44)
                        }.buttonStyle(.plain)
                    }
                }
                StationCard(title: "Bracken's work", icon: "point.3.connected.trianglepath.dotted") {
                    ResearchTree(station: Stations.armoury)
                }
            }.padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Armoury")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $chosenTarget) { target in
            ArmouryTargetSheet(target: target).environmentObject(store)
        }
    }
}

struct WeaponsmithView: View {
    @EnvironmentObject private var store: GameStore
    @State private var chosenRecipe: PhysicalGearCraftingRules.Recipe?

    private var knowsPolearm: Bool {
        store.state.reality.library.knownPatterns.contains(PhysicalGearCraftingRules.maudFittingPattern)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                StationCard(title: "Fit the motion", icon: "hammer.fill") {
                    Text("Choose consequence and reach. Might or Finesse is visible advice, never a wearer lock or hidden fit score.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                StationCard(title: "Close forms", icon: "scope") {
                    ForEach(PhysicalGearCraftingRules.weaponsmithRecipes) { recipe in
                        ConstructionRow(recipe: recipe) { chosenRecipe = recipe }
                    }
                }
                StationCard(title: "Fitted polearm", icon: "arrow.left.and.right") {
                    if knowsPolearm {
                        ForEach(DamageKind.allCases, id: \.self) { kind in
                            let recipe = PhysicalGearCraftingRules.fittedPolearm(damage: kind)
                            Button { chosenRecipe = recipe } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(kind.rawValue.capitalisedSentence) polearm")
                                        Text("Mid reach · \(recipe.intendedLean ?? "")")
                                            .font(.caption2).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.tertiary)
                                }.frame(minHeight: 44)
                            }.buttonStyle(.plain)
                        }
                    } else {
                        EmptyNote("A fitting pattern in Maud's diary completes this form.")
                    }
                }
                StationCard(title: "Maud's work", icon: "point.3.connected.trianglepath.dotted") {
                    ResearchTree(station: Stations.weaponsmith)
                }
            }.padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Weaponsmith")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $chosenRecipe) { recipe in
            ConstructionSheet(recipe: recipe).environmentObject(store)
        }
    }
}

private struct ArmouryTargetSheet: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss
    let target: ArmouryRules.Target
    @State private var chosenProfile: ArmouryRules.Profile?

    var body: some View {
        NavigationStack {
            List {
                Section("Rebuild as") {
                    ForEach(ArmouryRules.profiles) { profile in
                        let available = ArmouryRules.isAvailable(profile, for: target, in: store.state)
                        Button { if available { chosenProfile = profile } } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(profile.name).foregroundStyle(.primary)
                                    Text(profileSummary(profile)).font(.caption2).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(available ? "" : "Tier \(profile.minimumEffectiveTier)")
                                    .font(.caption2).foregroundStyle(.secondary)
                                Image(systemName: available ? "chevron.right" : "lock")
                                    .font(.caption2).foregroundStyle(.tertiary)
                            }.frame(minHeight: 44)
                        }.buttonStyle(.plain).disabled(!available)
                    }
                }
            }
            .navigationTitle(target.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .sheet(item: $chosenProfile) { profile in
                ArmouryRebuildSheet(target: target, profile: profile).environmentObject(store)
            }
        }
    }

    private func profileSummary(_ profile: ArmouryRules.Profile) -> String {
        let physical = profile.physicalOffset == 0 ? "full physical" : "\(profile.physicalOffset) physical"
        return "\(profile.requirements.count) selected samples · \(physical)"
    }
}

private struct ArmouryRebuildSheet: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss
    let target: ArmouryRules.Target
    let profile: ArmouryRules.Profile
    @State private var selected: [String: ArmouryRules.Selection] = [:]
    @State private var confirmingOrdinary = false
    @State private var confirmingLegacy = false
    @State private var commitFailure: String?

    private var selections: [ArmouryRules.Selection]? {
        guard let defaults = ArmouryRules.defaultSelections(for: profile, in: store.state) else { return nil }
        return profile.requirements.compactMap { requirement in
            selected[requirement.id] ?? defaults.first { $0.requirementID == requirement.id }
        }
    }
    private var preview: ArmouryRules.Preview? {
        ArmouryRules.preview(profile, target: target, selections: selections,
                             includeLegacy: target.isLegacyMasterwork, in: store.state)
    }

    var body: some View {
        NavigationStack {
            List {
                if let preview {
                    Section("Comparison") {
                        LabeledRow(icon: "shield", label: "Physical protection",
                                   value: String(format: "%.1f → %.1f", preview.currentPhysical, preview.rebuiltPhysical))
                        LabeledRow(icon: "thermometer.medium", label: "Insulation",
                                   value: String(format: "%.0f → %.0f", preview.currentInsulation, preview.insulation))
                        LabeledRow(icon: "hammer", label: profile.name, value: "Tier \(preview.outputTier)")
                        if preview.isBelowSpecialistHeadline {
                            Label("This stock yields Tier \(preview.outputTier); this Armoury can do better.",
                                  systemImage: "exclamationmark.triangle").font(.caption).foregroundStyle(.orange)
                        }
                        if preview.wastesGradeAboveCap {
                            Label("This stock naturally reaches Tier \(preview.naturalTier), but the Armoury currently caps it at Tier \(preview.outputTier).",
                                  systemImage: "exclamationmark.triangle").font(.caption).foregroundStyle(.orange)
                        }
                        if target.hasReforgeWork {
                            Label("Reforged rank \(target.reforgeRank) will reset to 0.",
                                  systemImage: "arrow.counterclockwise")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Section("Selected stock") {
                        ForEach(profile.requirements) { requirement in
                            if let choice = preview.selections.first(where: { $0.requirementID == requirement.id }) {
                                NavigationLink {
                                    SamplePicker(requirement: requirement,
                                        otherSelections: preview.selections.filter { $0.requirementID != requirement.id },
                                        selection: Binding(get: { selected[requirement.id] ?? choice },
                                                           set: { selected[requirement.id] = $0 }))
                                } label: {
                                    Label(choice.sample.displayName, systemImage: choice.sample.kind.icon)
                                }
                            }
                        }
                    }
                    Section {
                        Button("Rebuild · \(preview.essence) essence") {
                            if preview.destroysLegacyWork { confirmingLegacy = true }
                            else if preview.isBelowSpecialistHeadline || preview.wastesGradeAboveCap {
                                confirmingOrdinary = true
                            } else { commit(preview, allowLegacy: false) }
                        }.frame(maxWidth: .infinity, minHeight: 44).buttonStyle(.borderedProminent)
                            .disabled(store.state.base.essence < preview.essence)
                        if store.state.base.essence < preview.essence {
                            Text("Needs \(preview.essence - store.state.base.essence) more essence.")
                                .font(.caption).foregroundStyle(.orange)
                        }
                        if let commitFailure {
                            Text(commitFailure).font(.caption).foregroundStyle(.orange)
                        }
                    }
                } else {
                    Section { EmptyNote("You do not have four distinct qualifying samples for this profile.") }
                }
            }
            .navigationTitle(profile.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .alert("Use this stock?", isPresented: $confirmingOrdinary) {
                Button("Cancel", role: .cancel) {}
                Button("Rebuild") { if let preview { commit(preview, allowLegacy: false) } }
            } message: { Text("The shown tier and essence cost are final. Selected stock will be consumed.") }
            .alert("Remove legacy work?", isPresented: $confirmingLegacy) {
                Button("Cancel", role: .cancel) {}
                Button("Rebuild", role: .destructive) { if let preview { commit(preview, allowLegacy: true) } }
            } message: {
                if let preview {
                    let reforge = target.hasReforgeWork
                        ? " and resets Reforged rank \(target.reforgeRank) to 0"
                        : ""
                    Text("This rebuild removes Legacy masterwork +\(target.legacyPowerCredit)\(reforge). Physical \(String(format: "%.1f", preview.currentPhysical)) → \(String(format: "%.1f", preview.rebuiltPhysical)); insulation \(Int(preview.currentInsulation)) → \(Int(preview.insulation)). This cannot be undone.")
                }
            }
        }
    }

    private func commit(_ preview: ArmouryRules.Preview, allowLegacy: Bool) {
        if store.rebuildArmoury(preview, allowLegacyLoss: allowLegacy) {
            dismiss()
        } else {
            commitFailure = "The gear, stock, station tier, or cost changed. Review the refreshed preview and try again."
        }
    }
}

struct TanneryView: View {
    @EnvironmentObject private var store: GameStore
    @State private var chosenRecipe: PhysicalGearCraftingRules.Recipe?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    CurrencyChip(icon: "drop.fill", label: "Essence",
                                 value: "\(store.state.base.essence)", tint: .brown)
                    CurrencyChip(icon: "shippingbox", label: "Stock",
                                 value: "\(store.materialSampleCount)")
                }
                StationCard(title: "Wear", icon: "jacket") {
                    Text("Corrin fits flexible living material for repeated contact. The material's warmth and origin remain part of the finished piece.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                StationCard(title: "Construct", icon: "scissors") {
                    ForEach(PhysicalGearCraftingRules.tanneryRecipes) { recipe in
                        ConstructionRow(recipe: recipe) { chosenRecipe = recipe }
                    }
                }
                StationCard(title: "Corrin's work", icon: "point.3.connected.trianglepath.dotted") {
                    ResearchTree(station: Stations.tannery)
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Tannery")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $chosenRecipe) { recipe in
            ConstructionSheet(recipe: recipe).environmentObject(store)
        }
    }
}

private struct ConstructionSheet: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss
    let recipe: PhysicalGearCraftingRules.Recipe
    @State private var selected: [String: PhysicalGearCraftingRules.Selection] = [:]
    @State private var confirmingBelowHeadline = false
    @State private var confirmingWastedGrade = false
    @State private var commitFailure: String?

    private var selections: [PhysicalGearCraftingRules.Selection]? {
        guard let defaults = PhysicalGearCraftingRules.defaultSelections(for: recipe, in: store.state)
        else { return nil }
        return recipe.requirements.compactMap { requirement in
            selected[requirement.id]
                ?? defaults.first { $0.requirementID == requirement.id }
        }
    }

    private var preview: PhysicalGearCraftingRules.Preview? {
        PhysicalGearCraftingRules.preview(recipe, selections: selections, in: store.state)
    }

    var body: some View {
        NavigationStack {
            List {
                if let preview {
                    Section("Result") {
                        LabeledRow(icon: "hammer", label: recipe.displayName,
                                   value: "Tier \(preview.outputTier)", tint: .teal)
                        LabeledRow(icon: "gauge.with.dots.needle.50percent", label: "Craft grade",
                                   value: String(format: "%.1f", preview.craftGrade))
                        if let damage = recipe.damage {
                            LabeledRow(icon: "scope", label: "Consequence and reach",
                                       value: "\(damage.rawValue.capitalisedSentence) · \(recipe.reach.rawValue.capitalisedSentence)")
                        }
                        if let lean = recipe.intendedLean {
                            LabeledRow(icon: "figure.stand", label: "Suggested lean", value: lean)
                        }
                        if preview.homeDiscountRate > 0 {
                            LabeledRow(icon: "person.crop.circle.badge.checkmark", label: "Keeper at Home",
                                       value: "\(Int((preview.homeDiscountRate * 100).rounded()))% off")
                        }
                        if preview.wastesGradeAboveCap {
                            Label("This stock naturally reaches Tier \(preview.naturalTier), but this station caps the result at Tier \(preview.outputTier).",
                                  systemImage: "exclamationmark.triangle")
                                .font(.caption).foregroundStyle(.orange)
                        }
                        if let headline = recipe.specialistHeadlineTier,
                           preview.isBelowSpecialistHeadline {
                            Label("This stock yields Tier \(preview.outputTier), below the \(stationName)'s Tier \(headline) specialist headline.",
                                  systemImage: "exclamationmark.triangle")
                                .font(.caption).foregroundStyle(.orange)
                        }
                    }
                    Section {
                        ForEach(recipe.requirements) { requirement in
                            if let selection = preview.selections.first(where: {
                                $0.requirementID == requirement.id
                            }) {
                                NavigationLink {
                                    SamplePicker(requirement: requirement,
                                                 otherSelections: preview.selections.filter {
                                                     $0.requirementID != requirement.id
                                                 },
                                                 selection: Binding(
                                                    get: { selected[requirement.id] ?? selection },
                                                    set: { selected[requirement.id] = $0 }
                                                 ))
                                } label: {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(requirement.displayName).font(.caption).foregroundStyle(.secondary)
                                        Label(selection.sample.displayName,
                                              systemImage: selection.sample.kind.icon)
                                            .font(.callout)
                                        if !selection.sample.source.isEmpty {
                                            Text(selection.sample.source)
                                                .font(.caption2).foregroundStyle(.secondary)
                                        }
                                    }
                                    .padding(.vertical, 3)
                                }
                            }
                        }
                    } header: {
                        Text("Selected stock")
                    } footer: {
                        Text("The weakest qualifying stock is selected first. Open any part to replace it deliberately.")
                    }
                    Section {
                        Button("Construct · \(preview.essence) essence") {
                            if preview.wastesGradeAboveCap {
                                confirmingWastedGrade = true
                            } else if recipe.specialistHeadlineTier != nil,
                                      preview.isBelowSpecialistHeadline {
                                confirmingBelowHeadline = true
                            } else {
                                commit(preview)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .buttonStyle(.borderedProminent)
                        .disabled(store.state.base.essence < preview.essence)
                        if store.state.base.essence < preview.essence {
                            Text("Needs \(preview.essence - store.state.base.essence) more essence.")
                                .font(.caption).foregroundStyle(.orange)
                        }
                        if let commitFailure {
                            Text(commitFailure).font(.caption).foregroundStyle(.orange)
                        }
                    } footer: {
                        Text("One persistent piece. The selected samples and their origins stay with it.")
                    }
                } else {
                    Section {
                        EmptyNote("You do not yet have a distinct qualifying sample for every part of this piece.")
                    }
                }
            }
            .navigationTitle(recipe.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .alert("Construct below the specialist headline?", isPresented: $confirmingBelowHeadline) {
                Button("Cancel", role: .cancel) {}
                Button("Construct") {
                    guard let preview else { return }
                    commit(preview)
                }
            } message: {
                if let preview, let headline = recipe.specialistHeadlineTier {
                    Text("The selected stock yields Tier \(preview.outputTier), not Tier \(headline). It will still be consumed at the shown Tier \(preview.outputTier) cost.")
                }
            }
            .alert("Use stock above this station's cap?", isPresented: $confirmingWastedGrade) {
                Button("Cancel", role: .cancel) {}
                Button("Construct") { if let preview { commit(preview) } }
            } message: {
                if let preview {
                    Text("The stock naturally reaches Tier \(preview.naturalTier), but this station will produce Tier \(preview.outputTier). The selected stock will still be consumed.")
                }
            }
        }
    }

    private func commit(_ preview: PhysicalGearCraftingRules.Preview) {
        if store.craftPhysicalGear(preview) { dismiss() }
        else { commitFailure = "The station, pattern, stock, tier, or cost changed. Review the refreshed preview and try again." }
    }

    private var stationName: String {
        ContentCatalog.shared.station(recipe.station)?.name ?? "station"
    }
}

private struct SamplePicker: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss
    let requirement: PhysicalGearCraftingRules.SampleRequirement
    let otherSelections: [PhysicalGearCraftingRules.Selection]
    @Binding var selection: PhysicalGearCraftingRules.Selection

    var body: some View {
        List {
            Section {
                ForEach(available) { candidate in
                    Button {
                        selection = candidate
                        dismiss()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: candidate.sample.kind.icon)
                                .frame(width: 22).foregroundStyle(candidate.sample.rarity.tint)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(candidate.sample.displayName).foregroundStyle(.primary)
                                Text(detail(candidate.sample))
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if candidate.stockKey == selection.stockKey {
                                Image(systemName: "checkmark").foregroundStyle(.teal)
                            }
                        }
                        .frame(minHeight: 44)
                    }
                }
            } header: {
                Text(requirement.summary)
            } footer: {
                Text("Samples already selected for another part are unavailable.")
            }
        }
        .navigationTitle(requirement.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var available: [PhysicalGearCraftingRules.Selection] {
        let occupied = Set(otherSelections.map(\.stockKey))
        return PhysicalGearCraftingRules.candidates(for: requirement, in: store.state)
            .filter { !occupied.contains($0.stockKey) }
    }

    private func detail(_ sample: MaterialSample) -> String {
        let values = requirement.floors.map {
            "\($0.property.displayName) \(Int(sample.properties[$0.property]))"
        }
        return ([sample.source] + values).filter { !$0.isEmpty }.joined(separator: " · ")
    }
}

private extension PhysicalGearCraftingRules.SampleRequirement {
    var displayName: String { id.replacingOccurrences(of: "_", with: " ").capitalisedSentence }

    var summary: String {
        let kinds = allowedKinds.map { $0.map(\.displayName).sorted().joined(separator: ", ") }
        let floors = floors.map { "\($0.property.displayName) \(Int($0.minimum))+" }
        let alternatives = alternativeFloors.isEmpty ? [] : [
            alternativeFloors.map { "\($0.property.displayName) \(Int($0.minimum))+" }
                .joined(separator: " or ")
        ]
        return ([kinds].compactMap { $0 } + floors + alternatives).joined(separator: " · ")
    }
}

/// One piece and what the next step up would cost.
private struct ReforgeRow: View {
    @EnvironmentObject private var store: GameStore
    let target: ReforgeTarget
    let tap: () -> Void

    var body: some View {
        let requirement = SmithRules.requirement(for: target.catalogID, at: target.upgradeLevel)
        let readiness = store.readiness(of: target)

        Button(action: tap) {
            HStack(spacing: 10) {
                Image(systemName: target.icon)
                    .foregroundStyle(target.rarity.tint)
                    .frame(width: 22)
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 6) {
                        Text(target.displayName)
                            .font(.callout.weight(.medium))
                            .foregroundStyle(target.rarity.tint)
                        if target.count > 1 {
                            Text("×\(target.count)")
                                .font(.caption2.monospacedDigit()).foregroundStyle(.secondary)
                        }
                        // Worn pieces are reforged in place, so it has to be obvious which one of
                        // the two identical blades on this screen is the one you're carrying.
                        if let wearer = target.wearer {
                            Text(wearer)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color(.tertiarySystemFill), in: Capsule())
                        }
                    }
                    if let requirement {
                        Text("\(requirement.summary) · \(requirement.essence) essence")
                            .font(.caption2).foregroundStyle(.secondary)
                    } else {
                        Text("As far as it goes.")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 6)
                ReadinessChip(readiness: readiness)
                if requirement != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption2).foregroundStyle(.tertiary)
                }
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(requirement == nil)
    }
}

/// Says in one chip whether you can pay, and if not, exactly what's short — the difference between
/// a greyed-out button and knowing to go and find two more hard things.
private struct ReadinessChip: View {
    let readiness: SmithRules.Readiness

    var body: some View {
        switch readiness {
        case .ready:
            chip("+0.2 rating", .green)
        case .finished:
            chip("finished", .secondary)
        case .needsMaterials(let have, let need):
            chip("\(have)/\(need) stock", .orange)
        case .needsEssence(let have, let need):
            chip("\(have)/\(need) essence", .orange)
        }
    }

    private func chip(_ text: String, _ tint: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.medium))
            .foregroundStyle(tint)
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(tint.opacity(0.14), in: Capsule())
    }
}

/// The confirmation: what it costs, **which samples it would take**, and what you get.
///
/// Naming the exact samples matters — the smith spends the worst thing that clears the bar, and
/// seeing that written down is what makes it safe to keep your best pelt in the same bin.
private struct ReforgeSheet: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss
    let target: ReforgeTarget

    var body: some View {
        NavigationStack {
            List {
                if let requirement = SmithRules.requirement(for: target.catalogID,
                                                            at: target.upgradeLevel) {
                    let spending = Array(
                        SmithRules.candidates(for: requirement, in: store.state)
                            .prefix(requirement.count)
                    )

                    Section {
                        LabeledRow(icon: target.icon, label: target.displayName,
                                   value: "tier \(target.constructionTier)", tint: target.rarity.tint)
                        LabeledRow(icon: "arrow.up.circle", label: "Becomes",
                                   value: String(format: "rating %.1f", target.effectivePower + 0.2))
                        if let wearer = target.wearer {
                            LabeledRow(icon: "person.fill", label: "Worn by", value: wearer)
                        }
                    } header: {
                        Text("Reforging")
                    } footer: {
                        Text(effectText)
                    }

                    Section {
                        LabeledRow(icon: requirement.property.icon,
                                   label: "\(requirement.property.displayName) of at least",
                                   value: "\(Int(requirement.minimum))")
                        LabeledRow(icon: "drop.fill", label: "Essence",
                                   value: "\(requirement.essence)")
                    } header: {
                        Text("Asks for")
                    }

                    Section {
                        if spending.isEmpty {
                            EmptyNote("Nothing you're holding is \(requirement.property.stockWord) enough.")
                                .frame(minHeight: 44)
                        }
                        ForEach(Array(spending.enumerated()), id: \.offset) { _, candidate in
                            HStack(spacing: 10) {
                                Image(systemName: candidate.sample.kind.icon)
                                    .font(.footnote).frame(width: 20)
                                    .foregroundStyle(candidate.sample.rarity.tint)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(candidate.sample.displayName)
                                        .font(.callout)
                                        .foregroundStyle(candidate.sample.rarity.tint)
                                    if !candidate.sample.source.isEmpty {
                                        Text("off a \(candidate.sample.source)")
                                            .font(.caption2).foregroundStyle(.secondary)
                                    }
                                }
                                Spacer(minLength: 8)
                                Text("\(Int(candidate.value))")
                                    .font(.callout.monospacedDigit()).foregroundStyle(.secondary)
                            }
                            .frame(minHeight: 44)
                        }
                    } header: {
                        Text("Would take \(spending.count) of \(requirement.count)")
                    } footer: {
                        Text("The worst stock that clears the bar goes in first. Your best is left where it is.")
                    }

                    Section {
                        Button {
                            store.reforge(target)
                            dismiss()
                        } label: {
                            Text("Reforge")
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!store.readiness(of: target).isReady)
                    }
                }
            }
            .navigationTitle("The anvil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
    }

    /// Reforging contributes fractionally until the existing final combat rounding boundary.
    private var effectText: String {
        guard let slot = target.definition?.gear?.slot else { return "" }
        let unit = slot == .weapon ? "damage" : "protection"
        return "+0.2 gear rating toward final \(unit). Construction tier stays \(target.constructionTier). This exact piece keeps it."
    }
}
