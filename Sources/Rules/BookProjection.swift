import Foundation

/// Everything the Writing Desk shows before the player commits — pillar 5, legibility before
/// commitment (the fix for Mystcraft's #1 flaw).
///
/// The interesting decision here: **an unfilled slot produces a range, not a guess.** Two locked
/// rules pull against each other — empty slots are random-filled as a *surprise*, and the player
/// must be able to see what they're committing to. A range satisfies both: you always know the
/// bounds you're signing up for, you just don't know where in them you'll land. Fill every slot and
/// every range collapses to an exact number.
///
/// Ranges are computed per-slot rather than by enumerating combinations, which is exact because
/// cost, instability and enemy tier are all additive over slots.
struct BookProjection {

    struct SlotPlan: Identifiable {
        var slot: SymbolSlot
        /// The symbol the player put here, or nil if the slot is left to chance.
        var chosen: SymbolDef?
        /// What a random fill could draw from (only symbols the player owns).
        var candidates: [SymbolDef]

        var id: SymbolSlot { slot }
        var isRandom: Bool { chosen == nil }
        /// A slot with nothing to draw from generates nothing at all.
        var isEmpty: Bool { chosen == nil && candidates.isEmpty }
    }

    var slotPlans: [SlotPlan]
    var essenceCost: ClosedRange<Int>
    var instability: ClosedRange<Double>
    /// The 0–100 headline. Note this runs *inverted* against instability, so its bounds swap.
    var stabilityScore: ClosedRange<Int>
    var turnsUntilCollapse: ClosedRange<Int>
    var enemyTier: ClosedRange<Int>
    var mapWidth: Int
    var mapHeight: Int
    /// Expected share of harvests by resource, descending. Expected, not ranged — a pile of ranged
    /// percentages is unreadable, and the mix is the qualitative half of the preview.
    var resourceMix: [(resource: ResourceDef, share: Double)]
    /// Expected share of encounters by creature, descending. The UI silhouettes any creature the
    /// player has never met (`DiscoveryLog`).
    var creatureMix: [(creature: CreatureDef, share: Double)]

    /// True when every slot is chosen, so nothing is left to chance and every range is a point.
    var isFullySpecified: Bool { slotPlans.allSatisfy { !$0.isRandom } }
    var randomSlots: [SymbolSlot] { slotPlans.filter(\.isRandom).map(\.slot) }
    /// The player must be able to afford the *worst* case before departing.
    var maximumCost: Int { essenceCost.upperBound }

    // MARK: - Computation

    static func project(draft: BookDraft, ownedSymbols: Set<SymbolID>) -> BookProjection {
        let plans = SymbolSlot.allCases.map { slot in
            SlotPlan(
                slot: slot,
                chosen: draft[slot].flatMap { ContentCatalog.shared.symbol($0) },
                candidates: BookRules.candidates(for: slot, ownedSymbols: ownedSymbols)
            )
        }

        // Additive quantities: summing per-slot extremes gives the exact overall extremes.
        var costLow = Tuning.Book.baseBindCostEssence, costHigh = Tuning.Book.baseBindCostEssence
        var instabilityLow = 0.0, instabilityHigh = 0.0
        var tierLow = Tuning.World.baseEnemyTier, tierHigh = Tuning.World.baseEnemyTier

        for plan in plans {
            let options = plan.chosen.map { [$0] } ?? plan.candidates
            guard !options.isEmpty else { continue }
            costLow += options.map(\.essenceCost).min() ?? 0
            costHigh += options.map(\.essenceCost).max() ?? 0
            instabilityLow += options.map(\.instabilityWeight).min() ?? 0
            instabilityHigh += options.map(\.instabilityWeight).max() ?? 0
            tierLow += options.map(\.enemyTierDelta).min() ?? 0
            tierHigh += options.map(\.enemyTierDelta).max() ?? 0
        }

        // More instability ⇒ lower stability and fewer turns, so these bounds cross over.
        let decayFast = BookRules.decayPerTurn(instability: instabilityHigh)
        let decaySlow = BookRules.decayPerTurn(instability: instabilityLow)
        let scoreLow = BookRules.stabilityScore(instability: instabilityHigh)
        let scoreHigh = BookRules.stabilityScore(instability: instabilityLow)
        let turnsLow = BookRules.turnsUntilCollapse(decayPerTurn: decayFast)
        let turnsHigh = BookRules.turnsUntilCollapse(decayPerTurn: decaySlow)

        return BookProjection(
            slotPlans: plans,
            essenceCost: costLow...max(costLow, costHigh),
            instability: instabilityLow...max(instabilityLow, instabilityHigh),
            stabilityScore: scoreLow...max(scoreLow, scoreHigh),
            turnsUntilCollapse: turnsLow...max(turnsLow, turnsHigh),
            enemyTier: max(1, tierLow)...max(1, max(tierLow, tierHigh)),
            mapWidth: Tuning.World.gridWidth,
            mapHeight: Tuning.World.gridHeight,
            resourceMix: expectedResourceMix(plans),
            creatureMix: expectedCreatureMix(plans)
        )
    }

    /// Yield modifiers multiply, so an unfilled slot contributes the *average* of its candidates'
    /// multipliers. Approximate by construction — this drives a bar chart, not a promise.
    private static func expectedResourceMix(_ plans: [SlotPlan]) -> [(resource: ResourceDef, share: Double)] {
        var weights: [ResourceID: Double] = [:]
        for resource in ContentCatalog.shared.resources where !resource.isRealityCurrency {
            weights[resource.id] = Tuning.World.baseResourceWeight
        }

        for plan in plans {
            let options = plan.chosen.map { [$0] } ?? plan.candidates
            guard !options.isEmpty else { continue }
            let affected = Set(options.flatMap { $0.yieldModifiers.keys })
            for resource in affected {
                let average = options.reduce(0.0) { $0 + ($1.yieldModifiers[resource] ?? 1.0) } / Double(options.count)
                weights[resource] = (weights[resource] ?? Tuning.World.baseResourceWeight) * average
            }
        }

        let table = weights.filter { $0.value > 0 }.map { (value: $0.key, weight: $0.value) }
        return BookRules.shares(table)
            .compactMap { entry in
                ContentCatalog.shared.resource(entry.value).map { (resource: $0, share: entry.share) }
            }
            .sorted { $0.share > $1.share }
    }

    /// Enemy-table modifiers add, so an unfilled slot contributes the average of its candidates'
    /// deltas.
    private static func expectedCreatureMix(_ plans: [SlotPlan]) -> [(creature: CreatureDef, share: Double)] {
        var weights: [CreatureID: Double] = [:]
        for creature in ContentCatalog.shared.creatures {
            weights[creature.id] = creature.spawnWeight
        }

        for plan in plans {
            let options = plan.chosen.map { [$0] } ?? plan.candidates
            guard !options.isEmpty else { continue }
            let affected = Set(options.flatMap { $0.enemyTableModifiers.keys })
            for creature in affected {
                let average = options.reduce(0.0) { $0 + ($1.enemyTableModifiers[creature] ?? 0) } / Double(options.count)
                weights[creature] = (weights[creature] ?? 0) + average
            }
        }

        let table = ContentCatalog.shared.creatures.map { (value: $0, weight: max(0, weights[$0.id] ?? 0)) }
        return BookRules.shares(table)
            .map { (creature: $0.value, share: $0.share) }
            .sorted { $0.share > $1.share }
    }
}

extension ClosedRange where Bound: Equatable {
    /// A range whose ends match is really just a number — the UI reads this to drop the "–".
    var isPoint: Bool { lowerBound == upperBound }
}
