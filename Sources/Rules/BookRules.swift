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
        var symbols: [SlotID: SymbolID] = [:]
        var randomlyFilled: Set<SlotID> = []

        // Slot list comes from content, in its canonical order, so the same seed keeps producing
        // the same fills. Reordering slots.json would reshuffle them — acceptable, since that's a
        // deliberate content change, not a runtime one.
        for slot in ContentCatalog.shared.slotIDsInOrder {
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
    static func candidates(for slot: SlotID, ownedSymbols: Set<SymbolID>) -> [SymbolDef] {
        ContentCatalog.shared.symbols(in: slot)
            .filter { ownedSymbols.contains($0.id) }
            .sorted { $0.id.rawValue < $1.id.rawValue }
    }

    // MARK: Costs and decay

    static func bindCost(of book: BoundBook) -> Int {
        bindCost(chosenSymbolIDs: book.chosenSymbolIDs, randomSlots: book.randomlyFilled.count)
    }

    /// Precision costs, serendipity is cheap.
    ///
    /// You pay each symbol's own price for the slots you filled, and a flat cheap rate for each
    /// slot you left to chance — regardless of what rolls into it. Which means the price of a book
    /// is fully known while you're still composing it: there is no range, and nothing to discover
    /// at the moment of payment.
    static func bindCost(chosenSymbolIDs: [SymbolID], randomSlots: Int) -> Int {
        let chosenValue = chosenSymbolIDs.reduce(0) { $0 + (ContentCatalog.shared.symbol($1)?.essenceCost ?? 0) }
        return Tuning.Book.baseBindCostEssence
            + Int((Double(chosenValue) * Tuning.Book.symbolCostMultiplier).rounded())
            + randomSlots * Tuning.Book.randomSlotCostEssence
    }

    static func instability(of book: BoundBook) -> Double {
        instability(symbolIDs: book.allSymbolIDs)
    }

    static func instability(symbolIDs: [SymbolID]) -> Double {
        symbolIDs.reduce(0.0) { $0 + (ContentCatalog.shared.symbol($1)?.instabilityWeight ?? 0) }
    }

    /// The 0–100 headline number on a book ("Stability 68").
    ///
    /// Distinct from the in-run meter, which always starts at 100 and empties as you move — but no
    /// longer *unrelated* to it: the score is what sets how fast that meter empties.
    static func stabilityScore(instability: Double) -> Int {
        let score = Tuning.Book.neutralStabilityScore - instability * Tuning.Book.stabilityScorePerInstability
        return Int(min(100, max(0, score)).rounded())
    }

    /// **How many player turns a world of this stability lasts.**
    ///
    /// The heart of the rebalance: stability is measured in *steps you get*, not in an abstract
    /// rate. Low scores are literal — 5 means five moves — and each band above multiplies. See
    /// `Tuning.World.stabilityTurnBands` for the table and why the cliffs are deliberate.
    static func turnsAvailable(stabilityScore score: Int) -> Int {
        guard score < 100 else { return Tuning.World.indefiniteTurns }
        let multiplier = Tuning.World.stabilityTurnBands
            .first { score >= $0.minimumScore }?.multiplier ?? 1
        // Even a stability of zero gives you one turn: you arrive, and then it goes.
        return max(1, score * multiplier)
    }

    static func turnsAvailable(for book: BoundBook) -> Int {
        turnsAvailable(stabilityScore: stabilityScore(instability: instability(of: book)))
    }

    /// Stability lost per player turn — derived from the turn budget, so the meter empties exactly
    /// as the book promised it would.
    static func decayPerTurn(for book: BoundBook) -> Double {
        decayPerTurn(instability: instability(of: book))
    }

    static func decayPerTurn(instability: Double) -> Double {
        let turns = turnsAvailable(stabilityScore: stabilityScore(instability: instability))
        return Tuning.World.startingStability / Double(max(1, turns))
    }

    /// How many player turns are left from a full meter. Inverse of `decayPerTurn`, kept so the
    /// preview and the in-run header can't disagree.
    static func turnsUntilCollapse(decayPerTurn: Double) -> Int {
        guard decayPerTurn > 0 else { return Tuning.World.indefiniteTurns }
        return Int((Tuning.World.startingStability / decayPerTurn).rounded(.down))
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
