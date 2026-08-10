import SwiftUI

struct ApothecaryView: View {
    @EnvironmentObject private var store: GameStore

    private var known: [ConsumableCraftingRules.Recipe] {
        ConsumableCraftingRules.recipes.filter {
            store.state.base.knownConsumableRecipes.contains($0.output)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    CurrencyChip(icon: "drop.fill", label: "Essence",
                                 value: "\(store.state.base.essence)", tint: .teal)
                    CurrencyChip(icon: "star.fill", label: "Motes",
                                 value: "\(store.state.reality.motes)", tint: .purple)
                }

                StationCard(title: "Preparations", icon: "cross.vial.fill") {
                    Text("A recipe becomes legible when you bring Nessa stock that suggests it. Once understood, it stays understood. Natural samples substitute by property; named reagents keep their particular chemical jobs.")
                        .font(.caption).foregroundStyle(.secondary)
                    if known.isEmpty {
                        Text("Nothing on the shelves suggests a preparation yet.")
                            .font(.caption).foregroundStyle(.tertiary)
                    } else {
                        ForEach(known) { recipe in ConsumableRecipeRow(recipe: recipe) }
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("The Apothecary")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { store.discoverConsumableRecipes() }
    }
}

private struct ConsumableRecipeRow: View {
    @EnvironmentObject private var store: GameStore
    let recipe: ConsumableCraftingRules.Recipe

    private var item: ItemDef? { ContentCatalog.shared.item(recipe.output) }
    private var missing: [String] { ConsumableCraftingRules.shortfall(recipe, in: store.state) }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Label(item?.name ?? recipe.output.rawValue, systemImage: item?.icon ?? "cross.vial")
                    .font(.callout.weight(.medium))
                Spacer()
                Button("Prepare") { store.craftConsumable(recipe) }
                    .buttonStyle(.borderedProminent).controlSize(.small)
                    .disabled(!missing.isEmpty)
                    .accessibilityIdentifier("apothecary.craft.\(recipe.output.rawValue)")
            }
            Text(requirements).font(.caption2).foregroundStyle(.secondary)
            if !missing.isEmpty {
                Text("Needs: " + missing.joined(separator: " · "))
                    .font(.caption2).foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
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
