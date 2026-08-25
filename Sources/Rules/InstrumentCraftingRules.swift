import Foundation

/// Property-driven recipes for improving field instruments.
///
/// The instrument names are authored; their stock is not. A Sunglass cares whether a sample is
/// lustrous enough, not whether it was called quartz, chitin, or anything else when found.
enum InstrumentCraftingRules {
    struct Recipe: Equatable, Sendable {
        var target: PressureTargetID
        var output: RealityState.InstrumentPrecision
        var property: MaterialProperty
        var minimum: Double
        var count: Int
        var essence: Int

        var summary: String { "\(count) × \(property.stockWord) \(Int(minimum))+" }
    }

    struct Candidate: Equatable, Sendable {
        var unitID: MaterialReserveUnitID
        var sample: MaterialSample
        var value: Double

        var selection: MaterialReserveSelection {
            MaterialReserveSelection(unitID: unitID, sample: sample)
        }
    }

    enum Readiness: Equatable, Sendable {
        case ready
        case notOwned
        case finished
        case needsMaterials(have: Int, need: Int)
        case needsEssence(have: Int, need: Int)

        var isReady: Bool { self == .ready }
    }

    static func workingProperty(for target: PressureTargetID) -> MaterialProperty {
        switch target.rawValue {
        case "illumination", "cycle": .lustre
        case "thermal": .insulation
        case "hydrology": .flexibility
        case "substrate": .hardness
        case "relief", "atmosphere": .density
        case "vitality": .reactivity
        default: .lustre
        }
    }

    static func recipe(for target: PressureTargetID, in state: GameState) -> Recipe? {
        guard state.reality.instruments.contains(target) else { return nil }
        let current = state.reality.instrumentPrecision(for: target)
        let output: RealityState.InstrumentPrecision
        switch current {
        case .crude: output = .good
        case .good: output = .fine
        case .fine: return nil
        }
        let fine = output == .fine
        return Recipe(target: target,
                      output: output,
                      property: workingProperty(for: target),
                      minimum: fine ? 65 : 35,
                      count: fine ? 3 : 2,
                      essence: fine ? 50 : 20)
    }

    static func candidates(for recipe: Recipe, in state: GameState) -> [Candidate] {
        state.base.materialReserve.selections { sample in
            sample.properties[recipe.property] >= recipe.minimum
        }
        .map { selection in
            Candidate(unitID: selection.unitID, sample: selection.sample,
                      value: selection.sample.properties[recipe.property])
        }
        // Never silently eat the player's exceptional sample when an ordinary one qualifies.
        .sorted { ($0.value, $0.sample.grade, $0.unitID)
            < ($1.value, $1.sample.grade, $1.unitID) }
    }

    static func readiness(for target: PressureTargetID, in state: GameState) -> Readiness {
        guard state.reality.instruments.contains(target) else { return .notOwned }
        guard let recipe = recipe(for: target, in: state) else { return .finished }
        let stock = candidates(for: recipe, in: state)
        guard stock.count >= recipe.count else {
            return .needsMaterials(have: stock.count, need: recipe.count)
        }
        guard state.base.essenceCrystalCount >= recipe.essence else {
            return .needsEssence(have: state.base.essenceCrystalCount, need: recipe.essence)
        }
        return .ready
    }

    @discardableResult
    static func craftUpgrade(for target: PressureTargetID, in state: inout GameState) -> Bool {
        guard let recipe = recipe(for: target, in: state),
              state.base.essenceCrystalCount >= recipe.essence else { return false }
        let spending = Array(candidates(for: recipe, in: state).prefix(recipe.count))
        guard spending.count == recipe.count,
              state.base.materialReserve.consume(spending.map(\.selection)) != nil else { return false }
        guard state.base.spendEssenceCrystals(recipe.essence) else { return false }
        state.reality.instrumentPrecisions[target] = recipe.output
        return true
    }
}

extension RealityState.InstrumentPrecision {
    var displayName: String {
        switch self {
        case .crude: "Crude"
        case .good: "Good"
        case .fine: "Fine"
        }
    }
}
