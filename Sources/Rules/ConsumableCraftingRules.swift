import Foundation

/// Apothecary recipes combine named reagents with property-matched natural stock. Named resources
/// keep their authored chemical jobs; animal and plant samples remain freely substitutable.
enum ConsumableCraftingRules {
    struct MaterialRequirement: Equatable, Sendable {
        var property: MaterialProperty
        var minimum: Double
        var count: Int
    }

    struct Recipe: Identifiable, Equatable, Sendable {
        var id: ItemID { output }
        var output: ItemID
        var material: MaterialRequirement?
        var resources: [ResourceID: Int]
        var motes: Int = 0
        var essence: Int
    }

    static let recipes: [Recipe] = [
        Recipe(output: "salve_lesser", material: .init(property: .flexibility, minimum: 25, count: 1),
               resources: ["resin": 1], essence: 0),
        Recipe(output: "salve", material: .init(property: .insulation, minimum: 40, count: 1),
               resources: ["pulp": 2, "spore": 1, "resin": 1], essence: 0),
        Recipe(output: "salve_greater", material: .init(property: .reactivity, minimum: 60, count: 1),
               resources: ["ichor": 1, "spore": 2, "resin": 2], essence: 0),
        Recipe(output: "draught_clearing", material: .init(property: .reactivity, minimum: 35, count: 1),
               resources: ["pulp": 1, "salt": 1], essence: 0),
        Recipe(output: "draught_quenching", material: .init(property: .insulation, minimum: 45, count: 1),
               resources: ["reagent": 1, "resin": 1], essence: 0),
        Recipe(output: "antidote_broad", material: .init(property: .reactivity, minimum: 65, count: 1),
               resources: ["ichor": 1, "reagent": 1, "spore": 1], essence: 0),
        Recipe(output: "stonebark_tonic", material: .init(property: .hardness, minimum: 45, count: 1),
               resources: ["timber": 1, "resin": 1], essence: 0),
        Recipe(output: "venom", material: .init(property: .reactivity, minimum: 55, count: 1),
               resources: ["toxin": 1, "fiber": 1], essence: 0),
        Recipe(output: "firebrand", material: .init(property: .reactivity, minimum: 60, count: 1),
               resources: ["reagent": 1, "sulfur": 1], essence: 0),
        Recipe(output: "briar_oil", material: .init(property: .flexibility, minimum: 50, count: 1),
               resources: ["fiber": 1, "resin": 1], essence: 0),
        Recipe(output: "flashsalt", material: .init(property: .lustre, minimum: 55, count: 1),
               resources: ["reagent": 1, "mercury": 1], essence: 0),
        Recipe(output: "solvent", material: .init(property: .reactivity, minimum: 40, count: 1),
               resources: ["reagent": 1, "salt": 1], essence: 0),
        Recipe(output: "lure", material: .init(property: .reactivity, minimum: 50, count: 1),
               resources: ["toxin": 1, "pulp": 1], essence: 0),
        Recipe(output: "stillwater", material: .init(property: .lustre, minimum: 60, count: 1),
               resources: ["rift_glass": 1, "mercury": 1], essence: 6),
        Recipe(output: "waystone", material: .init(property: .hardness, minimum: 70, count: 1),
               resources: ["rift_glass": 1], motes: 1, essence: 12),
        Recipe(output: "torch", material: .init(property: .reactivity, minimum: 30, count: 1),
               resources: ["resin": 1, "timber": 2], essence: 0),
        Recipe(output: "farsight_draught", material: .init(property: .lustre, minimum: 50, count: 1),
               resources: ["quartz": 1, "ichor": 1], essence: 0)
    ]

    static func recipe(_ id: ItemID) -> Recipe? { recipes.first { $0.output == id } }

    static func qualifyingSamples(for recipe: Recipe, in state: GameState) -> [SmithRules.Candidate] {
        guard let need = recipe.material else { return [] }
        let smithNeed = SmithRules.Requirement(property: need.property, minimum: need.minimum,
                                               count: need.count, essence: 0, level: 0)
        return SmithRules.candidates(for: smithNeed, in: state)
    }

    static func canInfer(_ recipe: Recipe, in state: GameState) -> Bool {
        let hasSample = recipe.material == nil || !qualifyingSamples(for: recipe, in: state).isEmpty
        let hasReagent = recipe.resources.keys.contains { state.base.resources[$0] > 0 }
        return hasSample && (recipe.resources.isEmpty || hasReagent)
    }

    static func shortfall(_ recipe: Recipe, in state: GameState) -> [String] {
        var missing: [String] = []
        if let need = recipe.material {
            let have = qualifyingSamples(for: recipe, in: state).count
            if have < need.count { missing.append("\(need.count - have) × \(need.property.stockWord) \(Int(need.minimum))+") }
        }
        for (id, amount) in recipe.resources where state.base.resources[id] < amount {
            let name = ContentCatalog.shared.resource(id)?.name.lowercased() ?? id.rawValue
            missing.append("\(amount - state.base.resources[id]) \(name)")
        }
        if state.reality.motes < recipe.motes { missing.append("\(recipe.motes - state.reality.motes) mote") }
        if state.base.essence < recipe.essence { missing.append("\(recipe.essence - state.base.essence) essence") }
        return missing.sorted()
    }

    @discardableResult
    static func craft(_ recipe: Recipe, in state: inout GameState) -> Bool {
        guard state.base.knownConsumableRecipes.contains(recipe.output),
              shortfall(recipe, in: state).isEmpty else { return false }
        if let need = recipe.material {
            let spending = Array(qualifyingSamples(for: recipe, in: state).prefix(need.count))
            guard SmithRules.consume(spending, in: &state) else { return false }
        }
        for (id, amount) in recipe.resources { state.base.resources.spend(amount, of: id) }
        state.reality.motes -= recipe.motes
        state.base.essence -= recipe.essence
        state.base.store(ItemStack(id: InstanceID(rawValue: state.base.nextItemID()),
                                   catalogID: recipe.output))
        return true
    }
}
