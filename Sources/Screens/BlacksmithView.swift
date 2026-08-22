import SwiftUI

enum BlacksmithTab: String, CaseIterable, Sendable {
    case make = "Make"
    case reforge = "Reforge"
    case learn = "Learn"
}

enum MakerStationPresentationRules {
    static func recipeColumns(isAccessibilitySize: Bool) -> Int {
        isAccessibilitySize ? 2 : 3
    }

    static func readinessLabel(_ readiness: PhysicalGearCraftingRules.Readiness) -> String {
        switch readiness {
        case .ready(let preview): "Ready · Tier \(preview.outputTier)"
        case .stationLocked: "Unavailable"
        case .researchLocked: "Learn first"
        case .tierLocked(let need): "Tier \(need)"
        case .needsSamples: "Needs stock"
        case .needsEssence: "Needs Essence"
        }
    }
}

/// The Blacksmith proves the shared maker-station grammar: families, exact retained pieces and
/// authored learning stay separate, while every price and eligibility answer still comes from the
/// existing rules previews.
struct BlacksmithView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var tab: BlacksmithTab = .make
    @State private var chosen: ReforgeTarget?
    @State private var chosenRecipe: PhysicalGearCraftingRules.Recipe?
    @State private var showingIdentity = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header
                Picker("Blacksmith work", selection: $tab) {
                    ForEach(BlacksmithTab.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("blacksmith-tabs")

                switch tab {
                case .make: makeGrid
                case .reforge: reforgeGrid
                case .learn: ResearchTree(station: Stations.blacksmith)
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Blacksmith")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $chosenRecipe) { recipe in
            ConstructionSheet(recipe: recipe).environmentObject(store)
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "hammer.fill")
                    .font(.title2)
                    .frame(width: 36, height: 36)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Blacksmith").font(.headline)
                    Text("Tier \(blacksmithTier)")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button { showingIdentity = true } label: {
                    Image(systemName: "info.circle").frame(width: 44, height: 44)
                }
                .accessibilityLabel("About the Blacksmith")
                .popover(isPresented: $showingIdentity) {
                    Text("Halloway constructs rigid physical gear and reforges an exact retained piece without crossing its construction tier.")
                        .font(.callout).padding(16).frame(idealWidth: 280)
                        .presentationCompactAdaptation(.popover)
                }
            }
            HStack(spacing: 10) {
                CurrencyChip(icon: "drop.fill", label: "Essence",
                             value: "\(store.state.base.essence)", tint: .teal)
                CurrencyChip(icon: "shippingbox", label: "Stock",
                             value: "\(store.materialSampleCount)")
            }
        }
    }

    private var makeGrid: some View {
        LazyVGrid(columns: recipeColumns, spacing: 10) {
            ForEach(PhysicalGearCraftingRules.recipes) { recipe in
                MakerRecipeTile(recipe: recipe,
                                readiness: store.physicalGearReadiness(recipe)) {
                    chosenRecipe = recipe
                }
            }
        }
        .accessibilityIdentifier("blacksmith-make-grid")
    }

    @ViewBuilder private var reforgeGrid: some View {
        if store.reforgeable.isEmpty {
            ContentUnavailableView("Nothing to reforge", systemImage: "hammer",
                                   description: Text("Bring Home a physical piece and qualifying stock."))
        } else {
            SixAcrossItemGrid(data: store.reforgeable, id: \.id) { target in
                AnchoredItemDetailButton(item: target, selection: $chosen) {
                    ItemIconTile(icon: target.icon, catalogueID: target.catalogID,
                                 rarity: target.rarity,
                                 quantity: target.count, identified: true,
                                 location: target.gridLocation,
                                 accessibilityName: target.displayName,
                                 isEnabled: SmithRules.requirement(
                                    for: target.catalogID, at: target.upgradeLevel) != nil)
                } detail: { target in
                    ReforgeSheet(target: target).environmentObject(store)
                }
            }
            .accessibilityIdentifier("blacksmith-reforge-grid")
        }
    }

    private var recipeColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 10),
              count: MakerStationPresentationRules.recipeColumns(
                isAccessibilitySize: dynamicTypeSize.isAccessibilitySize))
    }

    private var blacksmithTier: Int {
        guard let station = ContentCatalog.shared.station(Stations.blacksmith) else {
            return store.state.base.station(Stations.blacksmith).tier
        }
        return StationStaffingRules.effectiveTier(for: station, in: store.state)
    }
}

private struct MakerRecipeTile: View {
    let recipe: PhysicalGearCraftingRules.Recipe
    let readiness: PhysicalGearCraftingRules.Readiness
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 7) {
                CatalogueItemPixelIdentity(
                    itemID: recipe.catalogFallback,
                    identified: true,
                    fallbackSystemIcon: ContentCatalog.shared.item(recipe.catalogFallback)?.icon ?? "hammer",
                    fallbackColor: .accentColor
                )
                .frame(width: 34, height: 30)
                Text(recipe.displayName)
                    .font(.subheadline.weight(.semibold)).lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                Text(MakerStationPresentationRules.readinessLabel(readiness))
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 6).padding(.vertical, 3)
                    .background(readinessTint.opacity(0.14), in: Capsule())
                    .foregroundStyle(readinessTint)
            }
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: 112, maxHeight: 120, alignment: .topLeading)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 13))
            .contentShape(RoundedRectangle(cornerRadius: 13))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(recipe.displayName), \(MakerStationPresentationRules.readinessLabel(readiness))")
    }

    private var readinessTint: Color {
        if case .ready = readiness { return .green }
        switch readiness {
        case .needsSamples, .needsEssence: return .orange
        default: return .secondary
        }
    }
}

private extension ReforgeTarget {
    var gridLocation: ItemGridLocation {
        switch self {
        case .stored: .stored
        case .overflow: .waiting
        case .worn: .worn
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
                CatalogueItemPixelIdentity(
                    itemID: recipe.catalogFallback,
                    identified: true,
                    fallbackSystemIcon: ContentCatalog.shared.item(recipe.catalogFallback)?.icon ?? "hammer",
                    fallbackColor: .teal
                )
                .frame(width: 32, height: 32)
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
        "Needs \(GearPresentationCopy.piecesOfStock(recipe.requirements.count)) · Tier 1–\(PhysicalGearCraftingRules.constructionCap(for: recipe, in: store.state))"
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
                    Text("Choose one familiar protective piece. Bracken keeps its name, equipment slot, and current wearer while rebuilding what its Construction does.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                StationCard(title: "Protective pieces", icon: "shield") {
                    Toggle("Include gear from older saves", isOn: $showLegacy)
                    let targets = ArmouryRules.targets(in: store.state, includeLegacy: showLegacy)
                    if targets.isEmpty {
                        EmptyNote(showLegacy
                                  ? "No eligible protective pieces are stored or worn."
                                  : "No eligible standard protective gear. Include gear from older saves to see compatible pieces.")
                    } else {
                        SixAcrossItemGrid(data: targets, id: \.id) { target in
                            Button { chosenTarget = target } label: {
                                ItemIconTile(
                                    icon: targetDefinition(target)?.icon ?? "shield",
                                    catalogueID: target.catalogID,
                                    rarity: targetRarity(target),
                                    quantity: 1,
                                    identified: targetIsIdentified(target),
                                    location: targetLocation(target),
                                    accessibilityName: target.displayName
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        Text("Tap a stored or worn piece to choose its Construction.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
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
            ArmouryTargetSheet(target: target)
                .environmentObject(store)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private func targetDefinition(_ target: ArmouryRules.Target) -> ItemDef? {
        ContentCatalog.shared.item(target.catalogID)
    }

    private func targetRarity(_ target: ArmouryRules.Target) -> Rarity {
        switch target {
        case .stored(let stack): stack.rarity
        case .worn: targetDefinition(target)?.rarity ?? .common
        }
    }

    private func targetLocation(_ target: ArmouryRules.Target) -> ItemGridLocation {
        switch target {
        case .stored: .stored
        case .worn: .worn
        }
    }

    private func targetIsIdentified(_ target: ArmouryRules.Target) -> Bool {
        switch target {
        case .stored(let stack): stack.identified
        case .worn: true
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
                        EmptyNote("The Fitted Polearm Schematic is recorded in Maud’s diary.")
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
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Rebuild as")
                        .font(.headline)
                    LazyVGrid(columns: profileColumns, spacing: 10) {
                    ForEach(ArmouryRules.profiles) { profile in
                        let available = ArmouryRules.isAvailable(profile, for: target, in: store.state)
                        Button { if available { chosenProfile = profile } } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: profileIcon(profile))
                                        .font(.title2)
                                        .frame(height: 28)
                                    Text(profile.name)
                                        .font(.caption.weight(.semibold))
                                        .multilineTextAlignment(.center)
                                        .foregroundStyle(.primary)
                                    Text(available ? profileSummary(profile)
                                                   : "Needs Tier \(profile.minimumEffectiveTier)")
                                        .font(.caption2)
                                        .multilineTextAlignment(.center)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                                .frame(maxWidth: .infinity, minHeight: 112)
                                .padding(8)
                                .background(Color(.secondarySystemGroupedBackground),
                                            in: RoundedRectangle(cornerRadius: 12))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(available ? Color.accentColor.opacity(0.55)
                                                                : Color.secondary.opacity(0.25))
                                }
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .disabled(!available)
                    }
                    }
                    Text("Choose a Construction. Exact stock and the final comparison follow without leaving this rebuild.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(target.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .sheet(item: $chosenProfile) { profile in
                ArmouryRebuildSheet(target: target, profile: profile).environmentObject(store)
            }
        }
    }

    private func profileSummary(_ profile: ArmouryRules.Profile) -> String {
        let physical = GearPresentationCopy.physicalProtection(offset: profile.physicalOffset)
        return "\(GearPresentationCopy.piecesOfStock(profile.requirements.count)) · \(physical)"
    }

    private var profileColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)
    }

    private func profileIcon(_ profile: ArmouryRules.Profile) -> String {
        switch profile.id {
        case ArmouryRules.rigid.id: "shield.fill"
        case ArmouryRules.insulated.id: "square.3.layers.3d"
        default: "circle.grid.cross"
        }
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
                            Label("Reforge \(target.reforgeRank) will reset to 0.",
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
                } else {
                    Section { EmptyNote("You do not have four distinct qualifying pieces of stock for this Construction.") }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if let preview { rebuildActionBar(preview) }
            }
            .navigationTitle(profile.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .alert("Use this stock?", isPresented: $confirmingOrdinary) {
                Button("Cancel", role: .cancel) {}
                Button("Rebuild") { if let preview { commit(preview, allowLegacy: false) } }
            } message: { Text("The shown tier and essence cost are final. Selected stock will be consumed.") }
            .alert("Replace upgrade from older save?", isPresented: $confirmingLegacy) {
                Button("Cancel", role: .cancel) {}
                Button("Rebuild", role: .destructive) { if let preview { commit(preview, allowLegacy: true) } }
            } message: {
                if let preview {
                    let reforge = target.hasReforgeWork
                        ? " and resets Reforge \(target.reforgeRank) to 0"
                        : ""
                    Text("This rebuild removes +\(target.legacyPowerCredit) power carried forward from an older save\(reforge). Physical \(String(format: "%.1f", preview.currentPhysical)) → \(String(format: "%.1f", preview.rebuiltPhysical)); insulation \(Int(preview.currentInsulation)) → \(Int(preview.insulation)). This cannot be undone.")
                }
            }
        }
    }

    private func rebuildActionBar(_ preview: ArmouryRules.Preview) -> some View {
        PersistentActionBar(message: rebuildActionFootnote(preview),
                            messageTint: rebuildActionHasFailure(preview) ? .orange : .secondary) {
            Button {
                if preview.destroysLegacyWork { confirmingLegacy = true }
                else if preview.isBelowSpecialistHeadline || preview.wastesGradeAboveCap {
                    confirmingOrdinary = true
                } else { commit(preview, allowLegacy: false) }
            } label: {
                Text("Rebuild · \(preview.essence) essence").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(store.state.base.essence < preview.essence)
        }
    }

    private func rebuildActionFootnote(_ preview: ArmouryRules.Preview) -> String {
        if let commitFailure { return commitFailure }
        if store.state.base.essence < preview.essence {
            return "Needs \(preview.essence - store.state.base.essence) more essence."
        }
        return "The selected stock, tier, and cost are checked again before rebuilding."
    }

    private func rebuildActionHasFailure(_ preview: ArmouryRules.Preview) -> Bool {
        commitFailure != nil || store.state.base.essence < preview.essence
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
    @State private var activeRequirementID: String?
    @State private var openedCandidate: PhysicalGearCraftingRules.CandidateAssessment?

    private var selections: [PhysicalGearCraftingRules.Selection]? {
        let defaults = PhysicalGearCraftingRules.defaultSelections(for: recipe, in: store.state) ?? []
        let resolved = recipe.requirements.compactMap { requirement in
            selected[requirement.id]
                ?? defaults.first { $0.requirementID == requirement.id }
        }
        return resolved.count == recipe.requirements.count ? resolved : nil
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
                    requirementSockets(preview.selections)
                    candidateTray
                } else {
                    Section {
                        EmptyNote("You do not yet have a distinct qualifying piece of stock for every part of this piece.")
                    }
                    requirementSockets([])
                    candidateTray
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if let preview { constructionActionBar(preview) }
            }
            .navigationTitle(recipe.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .onAppear {
                if activeRequirementID == nil { activeRequirementID = recipe.requirements.first?.id }
            }
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

    private func constructionActionBar(_ preview: PhysicalGearCraftingRules.Preview) -> some View {
        PersistentActionBar(message: constructionActionFootnote(preview),
                            messageTint: constructionActionHasFailure(preview) ? .orange : .secondary) {
            Button {
                if preview.wastesGradeAboveCap {
                    confirmingWastedGrade = true
                } else if recipe.specialistHeadlineTier != nil,
                          preview.isBelowSpecialistHeadline {
                    confirmingBelowHeadline = true
                } else {
                    commit(preview)
                }
            } label: {
                Text("Construct · \(preview.essence) essence").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(store.state.base.essence < preview.essence)
        }
    }

    private func constructionActionFootnote(_ preview: PhysicalGearCraftingRules.Preview) -> String {
        if let commitFailure { return commitFailure }
        if store.state.base.essence < preview.essence {
            return "Needs \(preview.essence - store.state.base.essence) more essence."
        }
        return "One persistent piece. Its selected stock and origins stay with it."
    }

    private func constructionActionHasFailure(_ preview: PhysicalGearCraftingRules.Preview) -> Bool {
        commitFailure != nil || store.state.base.essence < preview.essence
    }

    private func commit(_ preview: PhysicalGearCraftingRules.Preview) {
        if store.craftPhysicalGear(preview) { dismiss() }
        else { commitFailure = "The station, pattern, stock, tier, or cost changed. Review the refreshed preview and try again." }
    }

    private var stationName: String {
        ContentCatalog.shared.station(recipe.station)?.name ?? "station"
    }

    @ViewBuilder
    private func requirementSockets(_ previewSelections: [PhysicalGearCraftingRules.Selection]) -> some View {
        Section("Requirements") {
            ForEach(recipe.requirements) { requirement in
                let current = selected[requirement.id]
                    ?? previewSelections.first { $0.requirementID == requirement.id }
                Button { activeRequirementID = requirement.id } label: {
                    HStack(spacing: 10) {
                        Image(systemName: current?.sample.kind.icon ?? "circle.dashed")
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(requirement.displayName).font(.callout.weight(.medium))
                            Text(requirement.summary).font(.caption2).foregroundStyle(.secondary)
                            if let current {
                                Text(current.sample.displayName)
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        if activeRequirementID == requirement.id {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.tint)
                        }
                    }
                    .frame(minHeight: 44).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(activeRequirementID == requirement.id ? .isSelected : [])
            }
            Button("Reset suggestion") {
                selected.removeAll()
                activeRequirementID = recipe.requirements.first?.id
            }
            .font(.caption)
        }
    }

    @ViewBuilder private var candidateTray: some View {
        if let requirement = activeRequirement {
            let assessments = activeAssessments
            let eligible = assessments.filter(\.isEligible)
            let rejected = assessments.filter { !$0.isEligible }
            Section {
                if eligible.isEmpty {
                    EmptyNote("No stored piece of stock currently satisfies this part.")
                } else {
                    SixAcrossItemGrid(data: eligible, id: \.id) { assessment in
                        AnchoredItemDetailButton(item: assessment, selection: $openedCandidate) {
                            ItemIconTile(icon: assessment.selection.sample.kind.icon,
                                         materialKind: assessment.selection.sample.kind,
                                         rarity: assessment.selection.sample.rarity,
                                         quantity: 1, identified: true, location: .stored,
                                         accessibilityName: assessment.selection.sample.displayName,
                                         isSelected: selected[requirement.id]?.stockKey
                                            == assessment.selection.stockKey)
                        } detail: { assessment in
                            CandidateStockDetail(requirement: requirement, assessment: assessment) {
                                selected[requirement.id] = assessment.selection
                                openedCandidate = nil
                            }
                        }
                    }
                }
                if !rejected.isEmpty {
                    DisclosureGroup("Why \(rejected.count) other pieces of stock do not fit") {
                        ForEach(rejected.prefix(8)) { assessment in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(assessment.selection.sample.displayName).font(.caption.weight(.medium))
                                Text(assessment.rejectionReason ?? "Unavailable")
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .font(.caption)
                }
            } header: {
                Text("Stock · \(requirement.displayName)")
            } footer: {
                Text("Each icon is one exact stored piece of stock. Opening it changes nothing until you choose Use.")
            }
        }
    }

    private var activeRequirement: PhysicalGearCraftingRules.SampleRequirement? {
        recipe.requirements.first { $0.id == activeRequirementID } ?? recipe.requirements.first
    }

    private var activeAssessments: [PhysicalGearCraftingRules.CandidateAssessment] {
        guard let requirement = activeRequirement else { return [] }
        let current = Array(selected.values) + (selections ?? [])
        let occupied = Set(current.filter { $0.requirementID != requirement.id }.map(\.stockKey))
        return PhysicalGearCraftingRules.assessments(for: requirement, in: store.state)
            .filter { !occupied.contains($0.selection.stockKey) }
    }
}

private struct CandidateStockDetail: View {
    let requirement: PhysicalGearCraftingRules.SampleRequirement
    let assessment: PhysicalGearCraftingRules.CandidateAssessment
    let use: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Label(assessment.selection.sample.displayName,
                      systemImage: assessment.selection.sample.kind.icon)
                    .font(.headline)
                if !assessment.selection.sample.source.isEmpty {
                    LabeledContent("History", value: assessment.selection.sample.source)
                }
                LabeledContent("Grade", value: String(format: "%.1f", assessment.selection.sample.grade))
                Text(requirement.summary).font(.caption).foregroundStyle(.secondary)
                if let reason = assessment.rejectionReason {
                    Label(reason, systemImage: "xmark.circle")
                        .font(.caption).foregroundStyle(.orange)
                } else {
                    Button("Use for \(requirement.displayName)", action: use)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .buttonStyle(.borderedProminent)
                }
            }
            .padding(16)
        }
        .frame(minWidth: 260)
    }
}

private struct SamplePicker: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss
    let requirement: PhysicalGearCraftingRules.SampleRequirement
    let otherSelections: [PhysicalGearCraftingRules.Selection]
    @Binding var selection: PhysicalGearCraftingRules.Selection
    @State private var openedCandidate: PhysicalGearCraftingRules.Selection?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(requirement.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                SixAcrossItemGrid(data: available, id: \.id) { candidate in
                    AnchoredItemDetailButton(item: candidate, selection: $openedCandidate) {
                        ItemIconTile(icon: candidate.sample.kind.icon,
                                     rarity: candidate.sample.rarity,
                                     quantity: 1, identified: true, location: .stored,
                                     accessibilityName: candidate.sample.displayName,
                                     isSelected: candidate.stockKey == selection.stockKey)
                    } detail: { candidate in
                        ArmourySampleDetail(requirement: requirement, candidate: candidate) {
                            selection = candidate
                            openedCandidate = nil
                            dismiss()
                        }
                    }
                }
                Text("Pieces of stock already selected for another part are unavailable.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(requirement.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var available: [PhysicalGearCraftingRules.Selection] {
        let occupied = Set(otherSelections.map(\.stockKey))
        return PhysicalGearCraftingRules.candidates(for: requirement, in: store.state)
            .filter { !occupied.contains($0.stockKey) }
    }

}

private struct ArmourySampleDetail: View {
    let requirement: PhysicalGearCraftingRules.SampleRequirement
    let candidate: PhysicalGearCraftingRules.Selection
    let use: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Label(candidate.sample.displayName, systemImage: candidate.sample.kind.icon)
                    .font(.headline)
                if !candidate.sample.source.isEmpty {
                    LabeledContent("History", value: candidate.sample.source)
                }
                LabeledContent("Grade", value: String(format: "%.1f", candidate.sample.grade))
                ForEach(requirement.floors, id: \.property) { floor in
                    LabeledContent(floor.property.displayName,
                                   value: "\(Int(candidate.sample.properties[floor.property])) · needs \(Int(floor.minimum))+")
                }
                Button("Use for \(requirement.displayName)", action: use)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .buttonStyle(.borderedProminent)
            }
            .padding(16)
        }
        .frame(minWidth: 260)
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
            chip("+0.2 power", .green)
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
    @State private var commitFailure: String?

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
                                   value: String(format: "power %.1f", target.effectivePower + 0.2))
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
                                        Text("From \(candidate.sample.source)")
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

                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if SmithRules.requirement(for: target.catalogID, at: target.upgradeLevel) != nil {
                    reforgeActionBar
                }
            }
            .navigationTitle("The anvil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
    }

    private var reforgeActionBar: some View {
        let readiness = store.readiness(of: target)
        return PersistentActionBar(
            message: reforgeActionFootnote(readiness),
            messageTint: commitFailure == nil && readiness.isReady ? .secondary : .orange
        ) {
            Button {
                if store.reforge(target) { dismiss() }
                else { commitFailure = "The piece, stock, or cost changed. Review the refreshed result." }
            } label: {
                Text("Reforge").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!readiness.isReady)
        }
    }

    private func reforgeActionFootnote(_ readiness: SmithRules.Readiness) -> String {
        if let commitFailure { return commitFailure }
        switch readiness {
        case .ready:
            return "The piece, stock, and cost are checked again before reforging."
        case .finished:
            return "This piece is already fully reforged."
        case .needsMaterials(let have, let need):
            let missing = max(0, need - have)
            return "Needs \(GearPresentationCopy.moreQualifyingPiecesOfStock(missing))."
        case .needsEssence(let have, let need):
            return "Needs \(max(0, need - have)) more essence."
        }
    }

    /// Reforging contributes fractionally until the existing final combat rounding boundary.
    private var effectText: String {
        guard let slot = target.definition?.gear?.slot else { return "" }
        let unit = slot == .weapon ? "damage" : "protection"
        return "+0.2 power toward final \(unit). Construction tier stays \(target.constructionTier). This exact piece keeps it."
    }
}
