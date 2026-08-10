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
        var binID: InstanceID
        var index: Int
        var sample: MaterialSample
        var value: Double
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
        state.base.inventory.stacks.flatMap { bin in
            bin.materials.enumerated().compactMap { index, sample in
                let value = sample.properties[recipe.property]
                return value >= recipe.minimum
                    ? Candidate(binID: bin.id, index: index, sample: sample, value: value)
                    : nil
            }
        }
        // Never silently eat the player's exceptional sample when an ordinary one qualifies.
        .sorted { ($0.value, $0.sample.grade) < ($1.value, $1.sample.grade) }
    }

    static func readiness(for target: PressureTargetID, in state: GameState) -> Readiness {
        guard state.reality.instruments.contains(target) else { return .notOwned }
        guard let recipe = recipe(for: target, in: state) else { return .finished }
        let stock = candidates(for: recipe, in: state)
        guard stock.count >= recipe.count else {
            return .needsMaterials(have: stock.count, need: recipe.count)
        }
        guard state.base.essence >= recipe.essence else {
            return .needsEssence(have: state.base.essence, need: recipe.essence)
        }
        return .ready
    }

    @discardableResult
    static func craftUpgrade(for target: PressureTargetID, in state: inout GameState) -> Bool {
        guard let recipe = recipe(for: target, in: state),
              readiness(for: target, in: state) == .ready else { return false }
        let spending = Array(candidates(for: recipe, in: state).prefix(recipe.count))
        let byBin = Dictionary(grouping: spending, by: \.binID)
        for (binID, taken) in byBin {
            guard let binIndex = state.base.inventory.stacks.firstIndex(where: { $0.id == binID })
            else { return false }
            for candidate in taken.sorted(by: { $0.index > $1.index }) {
                state.base.inventory.stacks[binIndex].materials.remove(at: candidate.index)
            }
            state.base.inventory.stacks[binIndex].count = state.base.inventory.stacks[binIndex].materials.count
        }
        state.base.inventory.stacks.removeAll { $0.count == 0 }
        state.base.essence -= recipe.essence
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
