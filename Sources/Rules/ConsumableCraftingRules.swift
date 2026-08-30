import Foundation
import CryptoKit

/// Apothecary recipes combine named reagents with property-matched natural stock. Named resources
/// keep their authored chemical jobs; animal and plant samples remain freely substitutable.
enum ConsumableCraftingRules {
    static let craftRulesVersion = 1

    struct NamedResourceCostV1: Equatable, Sendable {
        var id: ResourceID
        var amount: Int
        var amountBefore: Int
    }

    enum OutputDestinationV1: Equatable, Sendable {
        case storehouse
        case waiting
    }

    enum OutputPlacementV1: Equatable, Sendable {
        case storehouseMerge(targetBefore: ItemStack, resultingStack: ItemStack)
        case storehouseNew(stack: ItemStack)
        case waitingNew(stack: ItemStack)

        var destination: OutputDestinationV1 {
            switch self {
            case .storehouseMerge, .storehouseNew: .storehouse
            case .waitingNew: .waiting
            }
        }

        var persistedOutput: ItemStack {
            switch self {
            case .storehouseMerge(_, let resultingStack): resultingStack
            case .storehouseNew(let stack), .waitingNew(let stack): stack
            }
        }
    }

    struct ConsumableCraftQuoteV1: Equatable, Sendable {
        var version: Int
        var output: ItemID
        var recipeFingerprint: String
        var selectedMaterials: [CraftMaterialSelection]
        var resourceCosts: [NamedResourceCostV1]
        var moteCost: Int
        var essenceCost: Int
        var stateRevision: Int
        var inventoryBefore: Inventory
        var waitingBefore: [ItemStack]
        var materialHoldingsBefore: [CraftMaterialHoldingV1]
        var motesBefore: Int
        var essenceBefore: Int
        var apothecaryState: StationState
        var knownRecipes: Set<ItemID>
        var outputDefinition: ItemDef
        var expectedOutput: ItemStack
        var outputPlacement: OutputPlacementV1
        var destination: OutputDestinationV1
        var inventoryAfter: Inventory
        var waitingAfter: [ItemStack]
        var noActiveRun: Bool
    }

    enum ConsumableCraftRefusalV1: Equatable, Sendable {
        case noCanonicalRecipe, notAtHome, apothecaryUnavailable, recipeUnknown
        case unavailableStock, staleQuote, invalidCatalogue, invalidAuthority
    }

    enum ConsumableCraftCommitResultV1: Equatable, Sendable {
        case committed(output: ItemStack, destination: OutputDestinationV1)
        case refused(ConsumableCraftRefusalV1)
    }
    enum Family: String, Codable, Sendable { case treatments, coatings, fieldwork }
    static let scentMaskDuration = 12
    static let scentMaskFamilies: Set<MaterialFamilyID> = [.hide, .pelt, .down, .oil]

    struct ScentMaskQuote: Equatable, Sendable {
        var animalResource: CraftMaterialSelection
        var reagentCost: Int
        var output: ItemID
    }

    enum ScentMaskCommitResult: Equatable, Sendable {
        case prepared
        case stale
    }

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
        var family: Family = .treatments
    }

    static let recipes: [Recipe] = [
        Recipe(output: Items.seamlight, material: nil,
               resources: ["quartz": 1, "resin": 1, "fiber": 1], essence: 0,
               family: .fieldwork),
        Recipe(output: Items.scentMask, material: nil, resources: ["reagent": 1], essence: 0),
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

    static func recipeFingerprint(_ recipe: Recipe) -> String {
        let material = recipe.material.map {
            "\($0.property.rawValue):\($0.minimum):\($0.count)"
        } ?? "none"
        let resources = recipe.resources.sorted { $0.key.rawValue < $1.key.rawValue }
            .map { "\($0.key.rawValue):\($0.value)" }.joined(separator: ",")
        let canonical = ["v\(craftRulesVersion)", recipe.output.rawValue, material, resources,
                         "m\(recipe.motes)", "e\(recipe.essence)", recipe.family.rawValue]
            .joined(separator: "|")
        return SHA256.hash(data: Data(canonical.utf8))
            .map { String(format: "%02x", $0) }.joined()
    }

    private static func validOutput(_ definition: ItemDef, for output: ItemID) -> Bool {
        guard definition.id == output, definition.kind == .consumable,
              definition.consumable != nil else { return false }
        if output == "torch" {
            return definition.rarity == .common
                && definition.consumable?.effect == .lightWorld
                && definition.consumable?.potency == 2
        }
        return true
    }

    private static func evaluated(_ output: ItemID, in source: GameState)
        -> (ConsumableCraftQuoteV1, GameState)? {
        guard source.worlds.activeRun == nil,
              let canonical = recipe(output), canonical.output != Items.scentMask,
              source.base.station(Stations.apothecary).isUnlocked,
              source.base.knownConsumableRecipes.contains(output),
              let definition = ContentCatalog.shared.item(output),
              validOutput(definition, for: output),
              shortfall(canonical, in: source).isEmpty else { return nil }

        let selected: [SmithRules.Candidate]
        if let need = canonical.material {
            selected = Array(qualifyingSamples(for: canonical, in: source).prefix(need.count))
            guard selected.count == need.count else { return nil }
        } else {
            selected = []
        }
        let expectedOutput = ItemStack(id: .init(rawValue: source.base.nextItemID()),
                                       catalogID: output, count: 1, identified: true)
        let mergeTarget = source.base.inventory.stacks.first {
            $0.binKey == expectedOutput.binKey
        }
        var candidate = source
        if !selected.isEmpty {
            guard SmithRules.consume(selected, in: &candidate) else { return nil }
        } else if canonical.material != nil {
            return nil
        }
        for (id, amount) in canonical.resources {
            guard candidate.base.resources.spend(amount, of: id) else { return nil }
        }
        guard candidate.reality.motes >= canonical.motes,
              candidate.base.spendEssenceCrystals(canonical.essence) else { return nil }
        candidate.reality.motes -= canonical.motes
        candidate.base.store(expectedOutput)
        let outputPlacement: OutputPlacementV1
        if let mergeTarget,
           let resulting = candidate.base.inventory.stacks.first(where: {
               $0.id == mergeTarget.id
           }) {
            outputPlacement = .storehouseMerge(targetBefore: mergeTarget,
                                               resultingStack: resulting)
        } else if candidate.base.spillover != source.base.spillover {
            outputPlacement = .waitingNew(stack: expectedOutput)
        } else {
            outputPlacement = .storehouseNew(stack: expectedOutput)
        }
        let holdings = source.base.worldMaterialReserve.units
            + source.base.creatureMaterialReserve.units
        let costs = canonical.resources.sorted { $0.key.rawValue < $1.key.rawValue }.map {
            NamedResourceCostV1(id: $0.key, amount: $0.value,
                                amountBefore: source.base.resources[$0.key])
        }
        let quote = ConsumableCraftQuoteV1(
            version: craftRulesVersion, output: output,
            recipeFingerprint: recipeFingerprint(canonical),
            selectedMaterials: selected.map(\.reserveSelection), resourceCosts: costs,
            moteCost: canonical.motes, essenceCost: canonical.essence,
            stateRevision: source.meta.mutationCount, inventoryBefore: source.base.inventory,
            waitingBefore: source.base.spillover, materialHoldingsBefore: holdings,
            motesBefore: source.reality.motes, essenceBefore: source.base.essenceCrystalCount,
            apothecaryState: source.base.station(Stations.apothecary),
            knownRecipes: source.base.knownConsumableRecipes, outputDefinition: definition,
            expectedOutput: expectedOutput, outputPlacement: outputPlacement,
            destination: outputPlacement.destination,
            inventoryAfter: candidate.base.inventory, waitingAfter: candidate.base.spillover,
            noActiveRun: true)
        return (quote, candidate)
    }

    static func preview(_ output: ItemID, in state: GameState) -> ConsumableCraftQuoteV1? {
        evaluated(output, in: state)?.0
    }

    static func commit(_ quote: ConsumableCraftQuoteV1, in state: inout GameState)
        -> ConsumableCraftCommitResultV1 {
        guard quote.version == craftRulesVersion,
              let (current, candidate) = evaluated(quote.output, in: state),
              current == quote else { return .refused(.staleQuote) }
        state = candidate
        return .committed(output: quote.outputPlacement.persistedOutput,
                          destination: quote.outputPlacement.destination)
    }

    static func qualifyingSamples(for recipe: Recipe, in state: GameState) -> [SmithRules.Candidate] {
        if recipe.output == Items.scentMask { return [] }
        guard let need = recipe.material else { return [] }
        let smithNeed = SmithRules.Requirement(property: need.property, minimum: need.minimum,
                                               count: need.count, essence: 0, level: 0)
        return SmithRules.candidates(for: smithNeed, in: state)
    }

    static func canInfer(_ recipe: Recipe, in state: GameState) -> Bool {
        guard state.base.station(Stations.apothecary).isUnlocked else { return false }
        if recipe.output == Items.seamlight {
            return [ResourceID("quartz"), "resin", "fiber"].contains {
                state.base.resources[$0] > 0
            }
        }
        if recipe.output == Items.scentMask {
            return state.base.resources["reagent"] > 0
                && !scentMaskAnimalResources(in: state).isEmpty
        }
        let hasSample = recipe.material == nil || !qualifyingSamples(for: recipe, in: state).isEmpty
        let hasReagent = recipe.resources.keys.contains { state.base.resources[$0] > 0 }
        return hasSample && (recipe.resources.isEmpty || hasReagent)
    }

    static func shortfall(_ recipe: Recipe, in state: GameState) -> [String] {
        var missing: [String] = []
        if recipe.output == Items.scentMask,
           scentMaskAnimalResources(in: state).isEmpty {
            missing.append("1 creature Hide, Pelt, Down, or Oil")
        }
        if let need = recipe.material {
            let have = qualifyingSamples(for: recipe, in: state).count
            if have < need.count { missing.append("\(need.count - have) × \(need.property.stockWord) \(Int(need.minimum))+") }
        }
        for (id, amount) in recipe.resources where state.base.resources[id] < amount {
            let name = ContentCatalog.shared.resource(id)?.name.lowercased() ?? id.rawValue
            missing.append("\(amount - state.base.resources[id]) \(name)")
        }
        if state.reality.motes < recipe.motes { missing.append("\(recipe.motes - state.reality.motes) mote") }
        if state.base.essenceCrystalCount < recipe.essence { missing.append("\(recipe.essence - state.base.essenceCrystalCount) essence") }
        return missing.sorted()
    }

    @discardableResult
    static func craft(_ recipe: Recipe, in state: inout GameState) -> Bool {
        // Scent Mask has an exact-instance commit API. Refuse the legacy automatic-sample path so
        // presentation can never quote one animal resource and silently consume another.
        guard recipe.output != Items.scentMask,
              Self.recipe(recipe.output) == recipe else { return false }
        if recipe.output == Items.seamlight {
            var candidate = state
            guard candidate.base.knownConsumableRecipes.contains(Items.seamlight),
                  shortfall(recipe, in: candidate).isEmpty else { return false }
            for (id, amount) in recipe.resources {
                guard candidate.base.resources.spend(amount, of: id) else { return false }
            }
            candidate.base.store(ItemStack(id: .init(rawValue: candidate.base.nextItemID()),
                                           catalogID: Items.seamlight))
            state = candidate
            return true
        }
        guard state.base.knownConsumableRecipes.contains(recipe.output),
              shortfall(recipe, in: state).isEmpty else { return false }
        if let need = recipe.material {
            let spending = Array(qualifyingSamples(for: recipe, in: state).prefix(need.count))
            guard SmithRules.consume(spending, in: &state) else { return false }
        }
        for (id, amount) in recipe.resources { state.base.resources.spend(amount, of: id) }
        state.reality.motes -= recipe.motes
        guard state.base.spendEssenceCrystals(recipe.essence) else { return false }
        state.base.store(ItemStack(id: InstanceID(rawValue: state.base.nextItemID()),
                                   catalogID: recipe.output))
        return true
    }

    static func scentMaskAnimalResources(in state: GameState) -> [CraftMaterialSelection] {
        state.base.creatureMaterialReserve.selections {
            scentMaskFamilies.contains($0.familyID)
        }
    }

    static func previewScentMask(
        using animalResource: CraftMaterialSelection, in state: GameState
    ) -> ScentMaskQuote? {
        guard state.base.station(Stations.apothecary).isUnlocked,
              state.base.station(Stations.apothecary).tier >= 0,
              state.base.knownConsumableRecipes.contains(Items.scentMask),
              state.base.resources["reagent"] >= 1,
              animalResource.unit.domain == .creature,
              scentMaskFamilies.contains(animalResource.unit.familyID),
              state.base.creatureMaterialReserve.selections().contains(animalResource)
        else { return nil }
        return .init(animalResource: animalResource, reagentCost: 1, output: Items.scentMask)
    }

    /// Revalidates the frozen selection and all costs on a candidate copy, then adopts the entire
    /// result. Stale exact IDs, changed samples, or changed stock therefore mutate nothing.
    static func craftScentMask(_ quote: ScentMaskQuote, in state: inout GameState)
        -> ScentMaskCommitResult {
        guard quote.output == Items.scentMask, quote.reagentCost == 1,
              quote.animalResource.unit.domain == .creature,
              scentMaskFamilies.contains(quote.animalResource.unit.familyID) else { return .stale }
        var candidate = state
        guard candidate.base.station(Stations.apothecary).isUnlocked,
              candidate.base.station(Stations.apothecary).tier >= 0,
              candidate.base.knownConsumableRecipes.contains(Items.scentMask),
              candidate.base.resources.spend(quote.reagentCost, of: "reagent"),
              candidate.base.creatureMaterialReserve.consume([quote.animalResource]) != nil
        else { return .stale }
        candidate.base.store(ItemStack(id: .init(rawValue: candidate.base.nextItemID()),
                                       catalogID: Items.scentMask))
        state = candidate
        return .prepared
    }
}
