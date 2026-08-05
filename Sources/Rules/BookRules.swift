import Foundation

/// The rules that turn a book composition into a world's character.
///
/// Pure functions over (book, catalog, tuning) — no state, no isolation, no side effects. Both the
/// pre-bind preview and the actual bind call *these same functions*, which is what makes the
/// legibility pillar true rather than aspirational: the preview cannot drift from reality, because
/// there is only one implementation.
enum BookRules {

    // MARK: Resolution

    /// Empty slots are random-filled at generation — under-specification is a surprise, not an
    /// error (the Mystcraft rule, locked in decisions-log).
    ///
    /// Random fills draw only from symbols the player owns, from a sorted candidate list, so the
    /// same seed always produces the same book.
    static func resolveBook(draft: BookDraft, ownedSymbols: Set<SymbolID>, seed: UInt64) -> BoundBook {
        var rng = SeededRNG(seed: seed).derived(0xB00C)
        var symbols: [SymbolSlot: SymbolID] = [:]
        var randomlyFilled: Set<SymbolSlot> = []

        for slot in SymbolSlot.allCases {
            if let chosen = draft[slot] {
                symbols[slot] = chosen
            } else if let pick = rng.pick(candidates(for: slot, ownedSymbols: ownedSymbols).map(\.id)) {
                symbols[slot] = pick
                randomlyFilled.insert(slot)
            }
        }
        var book = BoundBook(symbols: symbols, randomlyFilled: randomlyFilled, essencePaid: 0)
        book.essencePaid = bindCost(of: book)
        return book
    }

    /// What a random fill for this slot could draw from. Sorted for determinism.
    static func candidates(for slot: SymbolSlot, ownedSymbols: Set<SymbolID>) -> [SymbolDef] {
        ContentCatalog.shared.symbols(in: slot)
            .filter { ownedSymbols.contains($0.id) }
            .sorted { $0.id.rawValue < $1.id.rawValue }
    }

    // MARK: Costs and decay

    static func bindCost(of book: BoundBook) -> Int {
        bindCost(symbolIDs: book.allSymbolIDs)
    }

    static func bindCost(symbolIDs: [SymbolID]) -> Int {
        let symbolValue = symbolIDs.reduce(0) { $0 + (ContentCatalog.shared.symbol($1)?.essenceCost ?? 0) }
        return Tuning.Book.baseBindCostEssence
            + Int((Double(symbolValue) * Tuning.Book.symbolCostMultiplier).rounded())
    }

    static func instability(of book: BoundBook) -> Double {
        instability(symbolIDs: book.allSymbolIDs)
    }

    static func instability(symbolIDs: [SymbolID]) -> Double {
        symbolIDs.reduce(0.0) { $0 + (ContentCatalog.shared.symbol($1)?.instabilityWeight ?? 0) }
    }

    /// Stability lost per player turn. Greedier books burn their world down faster.
    static func decayPerTurn(for book: BoundBook) -> Double {
        decayPerTurn(instability: instability(of: book))
    }

    static func decayPerTurn(instability: Double) -> Double {
        let raw = Tuning.World.baseStabilityDecayPerTurn + instability * Tuning.World.instabilityDecayScale
        return min(max(raw, Tuning.World.minStabilityDecayPerTurn), Tuning.World.maxStabilityDecayPerTurn)
    }

    /// How many player turns the world lasts from full stability to collapse.
    static func turnsUntilCollapse(decayPerTurn: Double) -> Int {
        Int((Tuning.World.startingStability / decayPerTurn).rounded(.down))
    }

    /// The 0–100 headline number shown before binding ("Stability 68").
    /// Distinct from the in-run stability meter, which always starts at 100 and ticks down.
    static func stabilityScore(instability: Double) -> Int {
        let score = 100 - instability * Tuning.Book.stabilityScorePerInstability
        return Int(min(100, max(0, score)).rounded())
    }

    static func enemyTier(of book: BoundBook) -> Int {
        enemyTier(symbolIDs: book.allSymbolIDs)
    }

    static func enemyTier(symbolIDs: [SymbolID]) -> Int {
        let delta = symbolIDs.reduce(0) { $0 + (ContentCatalog.shared.symbol($1)?.enemyTierDelta ?? 0) }
        return max(1, Tuning.World.baseEnemyTier + delta)
    }

    // MARK: Spawn tables

    /// Relative weights for which resource a harvested node yields.
    static func yieldTable(for book: BoundBook) -> [(value: ResourceID, weight: Double)] {
        var weights: [ResourceID: Double] = [:]
        for resource in ContentCatalog.shared.resources where !resource.isRealityCurrency {
            weights[resource.id] = Tuning.World.baseResourceWeight
        }
        for id in book.allSymbolIDs {
            guard let symbol = ContentCatalog.shared.symbol(id) else { continue }
            for (resource, multiplier) in symbol.yieldModifiers {
                // A symbol can introduce a resource the base table doesn't carry (Mote Vein).
                weights[resource] = (weights[resource] ?? Tuning.World.baseResourceWeight) * multiplier
            }
        }
        return weights
            .filter { $0.value > 0 }
            .map { (value: $0.key, weight: $0.value) }
            .sorted { $0.value.rawValue < $1.value.rawValue }
    }

    /// Relative weights for which creature a bump-encounter rolls.
    static func enemyTable(for book: BoundBook) -> [(value: CreatureDef, weight: Double)] {
        var weights: [CreatureID: Double] = [:]
        for creature in ContentCatalog.shared.creatures {
            weights[creature.id] = creature.spawnWeight
        }
        for id in book.allSymbolIDs {
            guard let symbol = ContentCatalog.shared.symbol(id) else { continue }
            for (creature, delta) in symbol.enemyTableModifiers {
                weights[creature] = (weights[creature] ?? 0) + delta
            }
        }
        return ContentCatalog.shared.creatures.map { (value: $0, weight: max(0, weights[$0.id] ?? 0)) }
    }

    /// Normalises any weight table into shares that sum to 1, for the preview's mix bars.
    static func shares<T>(_ table: [(value: T, weight: Double)]) -> [(value: T, share: Double)] {
        let total = table.reduce(0) { $0 + max(0, $1.weight) }
        guard total > 0 else { return table.map { (value: $0.value, share: 0) } }
        return table.map { (value: $0.value, share: max(0, $0.weight) / total) }
    }
}
