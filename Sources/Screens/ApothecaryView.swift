import SwiftUI

struct ApothecaryView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var selectedRecipeID: ItemID?

    private var known: [ConsumableCraftingRules.Recipe] {
        ConsumableCraftingRules.recipes.filter {
            store.state.base.knownConsumableRecipes.contains($0.output)
        }
    }

    private var selectedRecipe: ConsumableCraftingRules.Recipe? {
        known.first { $0.output == selectedRecipeID }
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
                        }
                    }

                    if let selectedRecipe {
                        ConsumableRecipeDetail(recipe: selectedRecipe)
                            .id(selectedRecipe.output)
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
        .safeAreaInset(edge: .bottom, spacing: 0) { preparationActionBar }
        .background(Color(.systemGroupedBackground))
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
            let missing = ConsumableCraftingRules.shortfall(recipe, in: store.state)
            let name = ContentCatalog.shared.item(recipe.output)?.name ?? recipe.output.rawValue
            PersistentActionBar(
                message: missing.isEmpty ? "Exact stock is ready." : missing.joined(separator: " · "),
                messageTint: missing.isEmpty ? .secondary : .orange
            ) {
                Button {
                    store.craftConsumable(recipe)
                } label: {
                    Label("Prepare \(name)", systemImage: "cross.vial.fill")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!missing.isEmpty)
                .accessibilityIdentifier("apothecary.craft.\(recipe.output.rawValue)")
            }
        }
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
            Text(item?.name ?? recipe.output.rawValue)
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
                Text(item?.name ?? recipe.output.rawValue)
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
            "\(amount) \(ContentCatalog.shared.resource(id)?.name.lowercased() ?? id.rawValue)"
        }
        if recipe.motes > 0 { parts.append("\(recipe.motes) mote") }
        parts.append("\(recipe.essence) essence")
        return parts.joined(separator: " · ")
    }
}
