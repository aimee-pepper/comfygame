import SwiftUI

enum ConsumableRecipePresentation {
    static let unknownName = "Unknown preparation"
    static let unknownResourceName = "Unknown resource"

    static func displayName(for output: ItemID,
                            catalogue: ContentCatalog = .shared) -> String {
        catalogue.item(output)?.name ?? unknownName
    }

    static func resourceName(for id: ResourceID,
                             catalogue: ContentCatalog = .shared) -> String {
        catalogue.resource(id)?.name ?? unknownResourceName
    }
}

struct ApothecaryView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var selectedRecipeID: ItemID?
    @State private var selectedScentMaskUnitID: MaterialReserveUnitID?
    @State private var preparationFailure: String?

#if DEBUG
    init(debugSelectedRecipeID: ItemID? = nil,
         debugSelectedScentMaskUnitID: MaterialReserveUnitID? = nil,
         debugFailure: String? = nil) {
        _selectedRecipeID = State(initialValue: debugSelectedRecipeID)
        _selectedScentMaskUnitID = State(initialValue: debugSelectedScentMaskUnitID)
        _preparationFailure = State(initialValue: debugFailure)
    }
#endif

    private var known: [ConsumableCraftingRules.Recipe] {
        ConsumableCraftingRules.recipes.filter {
            store.state.base.knownConsumableRecipes.contains($0.output)
        }
    }

    private var selectedRecipe: ConsumableCraftingRules.Recipe? {
        known.first { $0.output == selectedRecipeID }
    }

    private var scentMaskAnimalResources: [MaterialReserveSelection] {
        ConsumableCraftingRules.scentMaskAnimalResources(in: store.state)
    }

    private var selectedScentMaskResource: MaterialReserveSelection? {
        scentMaskAnimalResources.first { $0.unitID == selectedScentMaskUnitID }
    }

    private var columns: [GridItem] {
        let count = dynamicTypeSize.isAccessibilitySize ? 1 : 3
        return Array(repeating: GridItem(.flexible(), spacing: 10), count: count)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                contextRow

                if known.isEmpty {
                    ContentUnavailableView(
                        "Nothing understood yet",
                        systemImage: "cross.vial",
                        description: Text("Bring Nessa stock whose properties suggest a preparation. Once understood, a recipe stays understood.")
                    )
                    .frame(maxWidth: .infinity, minHeight: 280)
#if DEBUG
                    .background { P3SafeSpaceProbe("apothecary.main.empty", identity: "no-known-recipes") }
#endif
                } else {
                    Text("Preparations")
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)

                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(known) { recipe in
                            Button {
                                selectedRecipeID = recipe.output
                            } label: {
                                ConsumableRecipeTile(
                                    recipe: recipe,
                                    selected: selectedRecipeID == recipe.output
                                )
                            }
                            .buttonStyle(.plain)
#if DEBUG
                            .background {
                                if recipe.id == known.first?.id {
                                    P3SafeSpaceProbe("apothecary.main.first",
                                                     identity: recipe.id.rawValue)
                                }
                                if recipe.id == known.last?.id {
                                    P3SafeSpaceProbe("apothecary.main.last",
                                                     identity: recipe.id.rawValue)
                                }
                            }
#endif
                        }
                    }

                    if let selectedRecipe {
                        if selectedRecipe.output == Items.scentMask {
                            ScentMaskRecipeDetail(
                                resources: scentMaskAnimalResources,
                                selectedUnitID: $selectedScentMaskUnitID
                            )
                            .id(selectedRecipe.output)
#if DEBUG
                            .background {
                                P3SafeSpaceProbe("apothecary.main.final",
                                                 identity: selectedRecipe.output.rawValue)
                            }
#endif
                        } else {
                            ConsumableRecipeDetail(recipe: selectedRecipe)
                                .id(selectedRecipe.output)
#if DEBUG
                                .background {
                                    P3SafeSpaceProbe("apothecary.main.final",
                                                     identity: selectedRecipe.output.rawValue)
                                }
#endif
                        }
                    } else {
                        Text("Choose a preparation to see its exact stock and prepare it.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .background(Color(.secondarySystemGroupedBackground),
                                        in: RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
            .padding(16)
        }
#if DEBUG
        .background { P3SafeSpaceProbe("apothecary.main.scroll") }
        .background {
            if let preparationFailure {
                P3SafeSpaceProbe("apothecary.main.failure", identity: preparationFailure)
            }
        }
#endif
        .safeAreaInset(edge: .bottom, spacing: 0) { preparationActionBar }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("The Apothecary")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            store.discoverConsumableRecipes()
            if selectedRecipeID == nil { selectedRecipeID = known.first?.output }
        }
        .onChange(of: known.map(\.output)) { _, ids in
            if let selectedRecipeID, !ids.contains(selectedRecipeID) {
                self.selectedRecipeID = ids.first
            } else if selectedRecipeID == nil {
                selectedRecipeID = ids.first
            }
        }
        .onChange(of: scentMaskAnimalResources.map(\.unitID)) { _, ids in
            if let selectedScentMaskUnitID, !ids.contains(selectedScentMaskUnitID) {
                self.selectedScentMaskUnitID = nil
            }
        }
        .alert("Preparation not made", isPresented: Binding(
            get: { preparationFailure != nil },
            set: { if !$0 { preparationFailure = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(preparationFailure ?? "The preparation could not be made.")
        }
    }

    private var contextRow: some View {
        HStack(spacing: 14) {
            Label("\(store.state.base.essence)", systemImage: "drop.fill")
                .foregroundStyle(.teal)
            Label("\(store.state.reality.motes)", systemImage: "star.fill")
                .foregroundStyle(.purple)
            Spacer()
            Text("\(known.count) known")
                .foregroundStyle(.secondary)
        }
        .font(.subheadline.weight(.semibold).monospacedDigit())
        .frame(minHeight: 44)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder private var preparationActionBar: some View {
        if let recipe = selectedRecipe {
            if recipe.output == Items.scentMask {
                scentMaskPreparationActionBar
            } else {
            let missing = ConsumableCraftingRules.shortfall(recipe, in: store.state)
            let name = ConsumableRecipePresentation.displayName(for: recipe.output)
            PersistentActionBar(
                message: missing.isEmpty ? "Exact stock is ready." : missing.joined(separator: " · "),
                messageTint: missing.isEmpty ? .secondary : .orange
            ) {
                Button {
                    if store.craftConsumable(recipe) {
                        preparationFailure = nil
                    } else {
                        preparationFailure = "The required stock changed. Review the exact recipe and try again."
                    }
                } label: {
                    Label("Prepare \(name)", systemImage: "cross.vial.fill")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!missing.isEmpty)
                .accessibilityIdentifier("apothecary.craft.\(recipe.output.rawValue)")
            }
#if DEBUG
            .background {
                P3SafeSpaceProbe("apothecary.main.action",
                                 identity: missing.isEmpty ? "ready" : missing.joined(separator: " · "))
            }
#endif
            }
        }
    }

    private var scentMaskPreparationActionBar: some View {
        let quote = selectedScentMaskResource.flatMap { store.scentMaskQuote(using: $0) }
        return PersistentActionBar(
            message: scentMaskActionMessage(quote: quote),
            messageTint: quote == nil ? .orange : .secondary
        ) {
            Button {
                guard let quote else {
                    preparationFailure = "Choose one exact grade 25+ animal resource and keep 1 Reagent available."
                    return
                }
                switch store.craftScentMask(quote) {
                case .prepared:
                    preparationFailure = nil
                    selectedScentMaskUnitID = nil
                case .stale:
                    preparationFailure = "That exact animal resource or the Reagent is no longer available. Choose the resource again."
                    selectedScentMaskUnitID = nil
                }
            } label: {
                Label("Prepare Scent Mask", systemImage: "wind")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.borderedProminent)
            .disabled(quote == nil)
            .accessibilityIdentifier("apothecary.craft.scent_mask")
        }
#if DEBUG
        .background {
            P3SafeSpaceProbe("apothecary.main.action",
                             identity: scentMaskActionMessage(quote: quote))
        }
#endif
    }

    private func scentMaskActionMessage(
        quote: ConsumableCraftingRules.ScentMaskQuote?
    ) -> String {
        if quote != nil { return "This exact resource + 1 Reagent · 0 Essence" }
        if selectedScentMaskResource == nil { return "Choose one exact grade 25+ animal resource." }
        return "Needs 1 Reagent."
    }
}

private struct ScentMaskRecipeDetail: View {
    @EnvironmentObject private var store: GameStore
    let resources: [MaterialReserveSelection]
    @Binding var selectedUnitID: MaterialReserveUnitID?

    private var preparedCount: Int {
        store.state.base.inventory.stacks
            .filter { $0.catalogID == Items.scentMask }.map(\.count).reduce(0, +)
        + store.state.base.spillover
            .filter { $0.catalogID == Items.scentMask }.map(\.count).reduce(0, +)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Scent Mask").font(.headline)
                Spacer()
                Text("Prepared ×\(preparedCount)")
                    .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            }

            Text("1 Reagent + 1 selected animal resource (grade 25+) · 0 Essence · 12 turns")
                .font(.callout).foregroundStyle(.secondary)

            Picker("Exact animal resource", selection: $selectedUnitID) {
                Text("Choose a resource").tag(Optional<MaterialReserveUnitID>.none)
                ForEach(resources, id: \.unitID) { resource in
                    Text(resourceLabel(resource)).tag(Optional(resource.unitID))
                }
            }
            .pickerStyle(.menu)
            .accessibilityIdentifier("apothecary.scent-mask.animal-resource")

            if resources.isEmpty {
                Label("No grade 25+ animal resources in reserve.", systemImage: "exclamationmark.circle")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Text("Animals relying only on scent hesitate for one action. Other senses and close contact still detect you. It does not hide creatures or affect apexes.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .contain)
    }

    private func resourceLabel(_ resource: MaterialReserveSelection) -> String {
        let sample = resource.sample
        let source = sample.source.isEmpty ? "unknown source" : sample.source
        let grade = sample.grade.formatted(.number.precision(.fractionLength(0...1)))
        return "\(sample.displayName) · grade \(grade) · from \(source)"
    }
}

private struct ConsumableRecipeTile: View {
    @EnvironmentObject private var store: GameStore
    let recipe: ConsumableCraftingRules.Recipe
    let selected: Bool

    private var item: ItemDef? { ContentCatalog.shared.item(recipe.output) }
    private var ready: Bool { ConsumableCraftingRules.shortfall(recipe, in: store.state).isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            CatalogueItemPixelIdentity(
                itemID: recipe.output,
                identified: true,
                fallbackSystemIcon: item?.icon ?? "cross.vial",
                fallbackColor: item?.rarity.tint ?? .secondary
            )
                .frame(width: 34, height: 34)
            Spacer(minLength: 0)
            Text(ConsumableRecipePresentation.displayName(for: recipe.output))
                .font(.caption.weight(.semibold))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            Label(ready ? "Ready" : "Needs stock",
                  systemImage: ready ? "checkmark.circle.fill" : "circle.dashed")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(ready ? Color.green : Color.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(selected ? Color.accentColor : Color.clear, lineWidth: 3)
        }
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityHint("Shows recipe requirements and preparation action")
    }
}

private struct ConsumableRecipeDetail: View {
    @EnvironmentObject private var store: GameStore
    let recipe: ConsumableCraftingRules.Recipe

    private var item: ItemDef? { ContentCatalog.shared.item(recipe.output) }
    private var missing: [String] { ConsumableCraftingRules.shortfall(recipe, in: store.state) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                CatalogueItemPixelIdentity(
                    itemID: recipe.output,
                    identified: true,
                    fallbackSystemIcon: item?.icon ?? "cross.vial",
                    fallbackColor: item?.rarity.tint ?? .secondary
                )
                .frame(width: 32, height: 32)
                Text(ConsumableRecipePresentation.displayName(for: recipe.output))
                    .font(.headline)
                Spacer()
                Text(missing.isEmpty ? "Ready" : "Missing stock")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(missing.isEmpty ? Color.green : Color.secondary)
            }

            Text(requirements)
                .font(.callout)
                .foregroundStyle(.secondary)

            if !missing.isEmpty {
                Label(missing.joined(separator: " · "), systemImage: "exclamationmark.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .contain)
    }

    private var requirements: String {
        var parts: [String] = []
        if let need = recipe.material {
            parts.append("\(need.count) × \(need.property.stockWord) \(Int(need.minimum))+")
        }
        parts += recipe.resources.sorted { $0.key.rawValue < $1.key.rawValue }.map { id, amount in
            "\(amount) \(ConsumableRecipePresentation.resourceName(for: id).lowercased())"
        }
        if recipe.motes > 0 { parts.append("\(recipe.motes) mote") }
        parts.append("\(recipe.essence) essence")
        return parts.joined(separator: " · ")
    }
}
