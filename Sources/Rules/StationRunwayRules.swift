import Foundation

enum StationRunwayRules {
    static let recentBindLimit = 5

    enum Warning: Equatable, Sendable {
        case low
        case belowOne
    }

    struct Preview: Equatable, Sendable {
        var spendableNow: Int
        var refinableRawEssence: Int
        var constructionEssence: Int
        var spendableAfter: Int
        var recentMedianBindCost: Double?
        var authoredBindsRemaining: Double?
        var warning: Warning?
        var affordability: EssenceAffordabilityPresentation

        var telemetryLabel: String {
            let basis = recentMedianBindCost.map { String(format: "%.1f", $0) } ?? "none"
            let worlds = authoredBindsRemaining.map { String(format: "%.2f", $0) } ?? "unknown"
            return "Essence available now=\(affordability.essenceAvailableNow) Essence after refining=\(affordability.essenceAfterRefining) construction cost=\(constructionEssence) Essence after construction=\(affordability.essenceAfterAction) typical world cost=\(basis) worlds affordable after construction=\(worlds)"
        }
    }

    static func preview(for station: StationDef, in state: GameState) -> Preview {
        let rawEquivalent = EconomyRules.refine(rawUnits: state.base.resources[Resources.essenceRaw],
                                                 in: state)
        let now = state.base.essence + rawEquivalent
        let cost = max(0, station.buildCost?.essence ?? 0)
        let after = max(0, now - cost)
        let paid = state.reality.library.visitedWorlds.reversed().compactMap { world -> Int? in
            guard !world.semanticRequests.isEmpty,
                  let amount = world.bindEssencePaid, amount > 0 else { return nil }
            return amount
        }.prefix(recentBindLimit).sorted()
        let median: Double? = {
            guard !paid.isEmpty else { return nil }
            let middle = paid.count / 2
            if paid.count.isMultiple(of: 2) {
                return Double(paid[middle - 1] + paid[middle]) / 2
            }
            return Double(paid[middle])
        }()
        let remaining = median.map { $0 > 0 ? Double(after) / $0 : 0 }
        let warning = remaining.flatMap { value -> Warning? in
            if value < 1 { return .belowOne }
            if value < 2 { return .low }
            return nil
        }
        let affordability = EssenceAffordabilityPresentation(
            action: .construction, essenceAvailableNow: state.base.essence,
            refinableRawEquivalent: rawEquivalent, actionCost: cost,
            basis: median == nil ? nil : .recentWorld, basisCost: median)
        return Preview(spendableNow: now, refinableRawEssence: rawEquivalent,
                       constructionEssence: cost, spendableAfter: after,
                       recentMedianBindCost: median, authoredBindsRemaining: remaining,
                       warning: warning, affordability: affordability)
    }
}
