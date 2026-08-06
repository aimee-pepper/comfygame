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
    /// Random fills draw from the **whole** catalog, not just what the player owns (Aimee, session
    /// 5): a chance slot that could only return things you already knew is a shuffle, not a
    /// surprise. Drawing it does not teach you the symbol — you write the world, you don't learn
    /// the word (Q16). The candidate list is sorted, so the same seed always produces the same book.
    /// Binds what is written on the page.
    ///
    /// No slots, no per-slot random fill: the page holds as many marks as you could fit, and what
    /// you *didn't* say is rolled at resolution by `PressureRules.rollUnwritten`. Under-specifying
    /// is still a surprise — it just isn't counted in slots any more.
    static func resolveBook(page: Page) -> BoundBook {
        var book = BoundBook(written: page.symbolIDs,
                             composition: PageRules.clusterSigils(of: page),
                             scale: PageRules.worldScale(of: page),
                             essencePaid: 0)
        // **What's on the page is what you pay for.** `page.symbolIDs` is compounds only, so a
        // book written entirely in the sigil vocabulary cost exactly the base rate however much was
        // on it. Ink is charged by the cell: a six-cell volcano costs more to write than a
        // one-cell target, which is the same thing the footprint numbers are already telling you.
        book.essencePaid = bindCost(of: book) + inkCost(of: page)
        return book
    }

    /// What the marks themselves cost to write, by the space they take up.
    static func inkCost(of page: Page) -> Int {
        Int((Double(page.usedCells) * Tuning.Book.essencePerCell).rounded())
    }

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

    /// What you can deliberately put in a slot: only what you've learned to write.
    static func writable(in slot: SlotID, ownedSymbols: Set<SymbolID>) -> [SymbolDef] {
        ContentCatalog.shared.symbols(in: slot)
            .filter { ownedSymbols.contains($0.id) }
            .sorted { $0.id.rawValue < $1.id.rawValue }
    }

    /// What **chance** can put in a slot: anything at all.
    ///
    /// Deliberately *not* limited to what the player owns. Under-specification is supposed to be a
    /// surprise, and a chance-fill that could only ever hand back things you already knew isn't a
    /// surprise — it's a shuffle. Leaving a slot open is how a world turns out to be something you
    /// don't yet know how to ask for.
    static func candidates(for slot: SlotID, ownedSymbols: Set<SymbolID>) -> [SymbolDef] {
        ContentCatalog.shared.symbols(in: slot)
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

    /// The total the symbols move stability by. Plain addition, in the headline's own units.
    static func stabilityDelta(of book: BoundBook) -> Int {
        stabilityDelta(symbolIDs: book.allSymbolIDs)
    }

    /// **Greed: how much more world you asked for than a world naturally has.**
    ///
    /// Instability has two origins (decisions-log): *greed* from abundance, and *contradiction*
    /// from opposed magnitude. Contradiction has been wired since session 5. Greed never was for
    /// the sigil vocabulary — `page.symbolIDs` returns only compounds, so a page of targets and
    /// sources moved the meter by exactly nothing and every world it described came out at 100.
    ///
    /// Run in **both directions**, which is the Mystcraft model the stability curve is built on:
    /// asking for less than the baseline calms a world, asking for the baseline costs nothing,
    /// asking for more is the greed that destabilises. A dim sky is genuinely a stabilising choice.
    ///
    /// **Only what you actually wrote is charged for**, and it is resolved *without* the random
    /// fill. Unwritten targets are rolled at resolution, and a rolled source can push a target you
    /// did write — so billing off the filled readings would make the headline move with the seed.
    /// The number has to be one you can work out while composing, from the page alone.
    /// Charged on the dials you **explicitly bound**, not on everything your sources happen to
    /// touch. Secondaries are consequences rather than requests — a glacier bound to Thermal is a
    /// request for cold, and billing it for the water it also brings would make the headline
    /// something you can't work out while composing, which is the whole point of the number.
    static func greedDelta(for sigils: [Sigil]) -> Int {
        let touched = Set(sigils.map(\.target))
        guard !touched.isEmpty else { return 0 }

        let asWritten = PressureRules.resolve(sigils)
        let deviation = ContentCatalog.shared.pressureTargets
            .filter { touched.contains($0.id) }
            .reduce(0.0) { total, target in
                total + (target.baseline - asWritten[target.id].peak)
            }
        return Int((deviation * Tuning.Book.stabilityPerAbundance).rounded())
    }

    /// The stability the danger runes are *asking* for, and what they actually get.
    ///
    /// Stacking danger is supposed to broaden the kinds of danger, not multiply the reward, so the
    /// gift is capped. The shortfall is returned rather than folded away because the preview has to
    /// show it — the same discipline the contradiction escalation term is held to, and for the same
    /// reason: a player who can't see a non-linear term can't reason about it.
    static func dangerStabilityGift(symbolIDs: [SymbolID]) -> (claimed: Int, granted: Int) {
        let claimed = symbolIDs
            .compactMap { ContentCatalog.shared.symbol($0) }
            .filter { $0.danger != nil && $0.stabilityDelta > 0 }
            .reduce(0) { $0 + $1.stabilityDelta }
        return (claimed, min(claimed, Tuning.Danger.maximumStabilityGift))
    }

    /// How much the cap took off. Zero unless the player stacked danger runes.
    static func dangerCapShortfall(symbolIDs: [SymbolID]) -> Int {
        let gift = dangerStabilityGift(symbolIDs: symbolIDs)
        return gift.claimed - gift.granted
    }

    /// Everything the world's danger runes do to how hostile it is, combined.
    ///
    /// Multipliers multiply and the rest add, so Swarm and Predation genuinely pull against each
    /// other on spawn count instead of one simply overriding the other.
    static func dangerProfile(symbolIDs: [SymbolID]) -> DangerProfile {
        let profiles = symbolIDs.compactMap { ContentCatalog.shared.symbol($0)?.danger }
        guard !profiles.isEmpty else { return .none }
        return DangerProfile(
            spawnMultiplier: profiles.reduce(1.0) { $0 * $1.spawnMultiplier },
            tierDelta: profiles.reduce(0) { $0 + $1.tierDelta },
            hazardTiles: max(0, profiles.reduce(0) { $0 + $1.hazardTiles }),
            damagePerTurn: max(0, profiles.reduce(0) { $0 + $1.damagePerTurn }),
            flavour: nil
        )
    }

    static func dangerProfile(for book: BoundBook) -> DangerProfile {
        dangerProfile(symbolIDs: book.allSymbolIDs)
    }

    static func stabilityDelta(symbolIDs: [SymbolID]) -> Int {
        let printed = symbolIDs.reduce(0) { $0 + (ContentCatalog.shared.symbol($1)?.stabilityDelta ?? 0) }
        // The only place a symbol doesn't move the meter by exactly its printed number. It applies
        // solely to *stacked* danger runes, and the preview shows the shortfall on its own line —
        // see `dangerStabilityGift` and questions-for-design Q23.
        return printed - dangerCapShortfall(symbolIDs: symbolIDs)
    }

    /// The 0–100 headline number on a book ("Stability 68").
    ///
    /// Base 100, plus whatever the symbols say. Deliberately the *same units* the symbols are
    /// labelled in, so a book's number is something you can work out in your head while composing
    /// rather than something the game reveals afterwards.
    static func stabilityScore(delta: Int) -> Int {
        min(100, max(0, Tuning.Book.baseStabilityScore + delta))
    }

    /// The headline. **Independent of the seed** — everything in it comes off what was written.
    ///
    /// Greed is charged on `composition` alone, never on the compounds. **A symbol moves the
    /// headline by exactly its printed number** (session 5, locked) — a compound's printed number
    /// *is* its declared greed, and charging it twice would break the one rule that makes the meter
    /// something you can work out in your head. A cluster prints no number, so abundance is the
    /// only thing there is to read.
    static func stabilityScore(of book: BoundBook) -> Int {
        // Size is written, and writing more world costs — a vast world needs more turns to cross,
        // so it has to buy them (decisions-session-13 §5).
        stabilityScore(delta: stabilityDelta(of: book)
                       + book.scale.stabilityDelta
                       + greedDelta(for: book.composition)
                       - contradictionPenalty(of: book))
    }

    /// What a book's contradictions cost it, in the headline's own units.
    ///
    /// Base plus the disclosed escalation term (`contradiction-danger-spec.md` §3). This was built
    /// and tested and then never read by anything, which is how a world could name *Green in the
    /// dark* and still read Stability 100.
    static func contradictionPenalty(of book: BoundBook) -> Int {
        ContradictionRules.totalPenalty(for: ContradictionRules.fired(in: sigils(for: book)))
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
        turnsAvailable(stabilityScore: stabilityScore(of: book))
    }

    /// Stability lost per player turn — derived from the turn budget, so the meter empties exactly
    /// as the book promised it would.
    static func decayPerTurn(for book: BoundBook) -> Double {
        decayPerTurn(stabilityScore: stabilityScore(of: book))
    }

    static func decayPerTurn(stabilityScore score: Int) -> Double {
        Tuning.World.startingStability / Double(max(1, turnsAvailable(stabilityScore: score)))
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
        // Danger runes carry their tier shift on the profile rather than on `enemyTierDelta`, so
        // there's one place a rune's hostility is described.
        return max(1, Tuning.World.baseEnemyTier + delta + dangerProfile(symbolIDs: symbolIDs).tierDelta)
    }

    // MARK: Spawn tables

    /// Relative weights for which resource a harvested node yields.
    /// What the ground is made of, **derived from what the world is**.
    ///
    /// The old version multiplied flat per-symbol `yieldModifiers`, which meant a world could read
    /// "frozen over, barren, nothing keeps time" while its spawns came from a symbol's table. The
    /// eight targets now generate the world rather than describing one they don't
    /// (`audit-what-pressures-actually-do.md` §4.1).
    static func yieldTable(from readings: PressureReadings) -> [(value: ResourceID, weight: Double)] {
        ContentCatalog.shared.resources
            .filter { !$0.isRealityCurrency }
            .map { (value: $0.id, weight: $0.abundance(in: readings)) }
            .filter { $0.weight > 0 }
    }

    /// Who lives here, **derived from what the world is** — and capped by what it can feed.
    ///
    /// The energy budget is the reason no world produces an everything-creature: a rich world can
    /// afford a large armoured thing *or* a gaudy fast one, and a poor world can afford neither.
    static func enemyTable(from readings: PressureReadings) -> [(value: CreatureDef, weight: Double)] {
        let budget = WorldConstraints.energyBudget(in: readings)
        let affordable = ContentCatalog.shared.creatures.filter { $0.appetite <= budget }
        // A world too poor to feed anything still holds the cheapest thing in it, or it would be
        // empty for reasons the player can't see.
        let pool = affordable.isEmpty
            ? [ContentCatalog.shared.creatures.min { $0.appetite < $1.appetite }].compactMap { $0 }
            : affordable
        return pool
            .map { (value: $0, weight: $0.affinity(in: readings)) }
            .filter { $0.weight > 0 }
    }

    /// How far things here notice you.
    ///
    /// **Openness sets ambush versus pursuit** — specced since the pressure model and, until now,
    /// doing nothing. Open ground means you're seen coming; enclosed means you aren't, and neither
    /// is what's waiting.
    static func sightRadius(of creature: CreatureDef, in readings: PressureReadings) -> Int {
        let pursuit = WorldConstraints.character(of: readings).contains("pursuit")
        return max(1, creature.sightRadius + (pursuit ? Tuning.World.sightBonusInOpenGround : 0))
    }

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
    // MARK: Pressures

    /// Everything a book says, in the pressure model's atomic vocabulary.
    ///
    /// Each symbol is a compound (rune spec §9) and expands to its components. Sigil identity is
    /// derived from the symbol and its position in the expansion rather than rolled, so the same
    /// book always yields the same page — no RNG is consumed here.
    /// Everything a bound book says, in the resolver's own terms.
    ///
    /// **The page's own clusters come first**, because they are the composition now; the compound
    /// expansion below is the legacy vocabulary, still read so that books bound before the page
    /// existed resolve to the same worlds they always did.
    static func sigils(for book: BoundBook) -> [Sigil] {
        book.composition + compoundSigils(for: book)
    }

    private static func compoundSigils(for book: BoundBook) -> [Sigil] {
        book.allSymbolIDs.enumerated().flatMap { symbolIndex, symbolID -> [Sigil] in
            guard let symbol = ContentCatalog.shared.symbol(symbolID) else { return [] }
            return symbol.expandsTo.enumerated().map { componentIndex, component in
                Sigil(id: InstanceID(rawValue: UInt64(symbolIndex) << 32 | UInt64(componentIndex)),
                      source: component.source,
                      target: component.target,
                      intensity: component.intensity,
                      negatedTargets: component.negates)
            }
        }
    }

    /// What the world a book describes is actually *like*.
    ///
    /// Targets the book says nothing about are rolled from the seed rather than left at baseline
    /// (Aimee, session 5) — a sensible default would make every under-specified world the same
    /// tepid place. Derived on demand rather than stored: it's a pure function of the book and the
    /// seed, and both of those are already in the save.
    static func readings(for book: BoundBook, seed: UInt64) -> PressureReadings {
        PressureRules.resolve(sigils(for: book), fillingUnwrittenWith: seed)
    }

    static func shares<T>(_ table: [(value: T, weight: Double)]) -> [(value: T, share: Double)] {
        let total = table.reduce(0) { $0 + max(0, $1.weight) }
        guard total > 0 else { return table.map { (value: $0.value, share: 0) } }
        return table.map { (value: $0.value, share: max(0, $0.weight) / total) }
    }
}
