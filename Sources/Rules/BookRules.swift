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
    static func dangerTradeDelta(of book: BoundBook) -> Int {
        dangerTradeDelta(symbolIDs: book.allSymbolIDs)
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
    ///
    /// **Compounds are charged here too**, by their expansion, which is what retiring the authored
    /// numbers means in practice (Q44). A compound is *one glyph meaning what several runes mean
    /// together* — so it must cost what those runes cost, or the two vocabularies price the same
    /// world differently and the cheaper one is simply correct play.
    static func greedDelta(for sigils: [Sigil]) -> Int {
        let touched = Set(sigils.map(\.target))
        guard !touched.isEmpty else { return 0 }

        // **Two axes** (`greed-formula-fix.md` §3). A world resists being asked for *more*; it
        // does not resist being asked for less.
        //
        // **Deviation** — how far past ordinary, lightly, on everything. A strange world is hard to
        // hold, whether it's strange with mountains or strange with light.
        //
        // **Value** — how much of what you asked for is wealth, heavily, and only on the subjects
        // that carry any: Substrate and Vitality. `pressure-model.md` §4.4 said this outright and it
        // was never implemented — *"Sun does not contribute; sunlight isn't loot"* — so the formula
        // billed you for daylight at the same rate as gold.
        //
        // Deviation alone charges a mountainous world like a gold-veined one. Value alone lets you
        // write a blazing, drowned, shattered world for nothing as long as it's poor. Together they
        // say the true thing: **a strange world is hard to hold, and a rich one is harder.**
        // **What you asked for, not what the world could manage.** Resolved without the
        // constraints pass: a lush world written in the dark gets its vitality capped, and charging
        // greed on the capped figure would make an over-reach *cheaper* than a modest ask. You are
        // billed for the demand — that is what greed is.
        let asWritten = PressureRules.resolveUnconstrained(sigils)
        let greed = ContentCatalog.shared.pressureTargets
            .filter { touched.contains($0.id) }
            .reduce(0.0) { total, target in
                let ordinary = target.neutral ?? target.baseline
                // **The demand, not the clamped reading.** A world can refuse to be more than
                // wholly golden; you are still charged for having asked.
                let excess = asWritten[target.id].demand - ordinary
                let weight = target.greedWeight ?? Tuning.Book.ordinaryGreedWeight
                // Asking for *less* than ordinary calms a world, and by the same measure. A dead,
                // frozen, lightless world is easy to hold together — there's nothing in it to hold.
                return total - excess * weight
            }
        return Int((greed * Tuning.Book.stabilityPerAbundance).rounded())
    }

    /// The stability the danger runes are *asking* for, and what they actually get.
    ///
    /// Stacking danger is supposed to broaden the kinds of danger, not multiply the reward, so the
    /// gift is capped. The shortfall is returned rather than folded away because the preview has to
    /// show it — the same discipline the contradiction escalation term is held to, and for the same
    /// reason: a player who can't see a non-linear term can't reason about it.
    static func dangerStabilityGift(symbolIDs: [SymbolID]) -> (claimed: Int, granted: Int) {
        let claimed = symbolIDs
            .compactMap { ContentCatalog.shared.symbol($0)?.danger?.stabilityTrade }
            .filter { $0 > 0 }
            .reduce(0, +)
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

    /// **What the danger runes trade for**, and the only thing a symbol still asserts by hand.
    ///
    /// Everything else a symbol does to the meter is measured from its expansion (`greedDelta`).
    /// Peace's cost is included and never capped — the ceiling exists so that stacking danger can't
    /// buy an arbitrarily greedy world, and a cost has no such failure mode.
    static func dangerTradeDelta(symbolIDs: [SymbolID]) -> Int {
        let trades = symbolIDs.compactMap { ContentCatalog.shared.symbol($0)?.danger?.stabilityTrade }
        let costs = trades.filter { $0 < 0 }.reduce(0, +)
        // The only place a symbol doesn't move the meter by exactly its printed number. It applies
        // solely to *stacked* danger runes, and the preview shows the shortfall on its own line —
        // see `dangerStabilityGift` and questions-for-design Q23.
        return costs + dangerStabilityGift(symbolIDs: symbolIDs).granted
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
    /// Greed is charged on **everything the book says**, clusters and compounds alike, because a
    /// compound is only a shorthand for the runes inside it. It used to be charged on `composition`
    /// alone, with compounds paying a hand-typed number instead; that made *Rich Ore* cost 45 and
    /// the identical world written out as *great iron, gold* cost 8 (Q44).
    static func stabilityScore(of book: BoundBook) -> Int {
        stabilityScore(delta: stabilityDelta(of: book,
                                             sigils: sigils(for: book),
                                             contradictionPenalty: contradictionPenalty(of: book)))
    }

    /// The stability of the world that was actually bound, including everything the page left to
    /// chance. The authored-only score above is still useful while composing; it is not the truth
    /// of a resolved world.
    static func resolvedStabilityScore(of book: BoundBook, seed: UInt64) -> Int {
        let written = sigils(for: book)
        let filled = written + PressureRules.rollUnwritten(after: written, seed: seed)
        let readings = PressureRules.resolve(filled)
        let contradictions = ContradictionRules.fired(in: filled, readings: readings)
        return stabilityScore(delta: stabilityDelta(
            of: book,
            sigils: filled,
            contradictionPenalty: ContradictionRules.totalPenalty(for: contradictions)))
    }

    /// **Everything that moves the headline, in one place.**
    ///
    /// Three callers needed this sum — the bind, the preview, and the preview's rolled band — and
    /// each had written it out separately. That was survivable while the terms never changed; it
    /// stopped being survivable the moment they did. The preview cannot drift from the bind if
    /// there is only one implementation, which is what the legibility pillar actually requires.
    ///
    /// `sigils` is passed in rather than derived because the callers legitimately differ: the bind
    /// and the preview charge what was *written*, while the band charges written-plus-rolled to
    /// find out how far a roll could move the number.
    static func stabilityDelta(of book: BoundBook, sigils: [Sigil], contradictionPenalty: Int) -> Int {
        // Size is written, and writing more world costs — a vast world needs more turns to cross,
        // so it has to buy them (decisions-session-13 §5).
        dangerTradeDelta(of: book)
            + book.scale.stabilityDelta
            + greedDelta(for: sigils)
            - contradictionPenalty
    }

    /// What one symbol does to the headline **on an otherwise empty page**.
    ///
    /// The palette's number, and the draft path's. Not additive across symbols, and it can't be:
    /// greed is measured off resolved abundance, and two symbols pushing the same subject stack with
    /// diminishing returns. It was additive when every symbol carried a hand-typed constant, which
    /// is precisely the false precision that let *Rich Ore* claim −45 for a world it doesn't write.
    static func stabilityDelta(ofSymbolAlone id: SymbolID) -> Int {
        guard let symbol = ContentCatalog.shared.symbol(id) else { return 0 }
        return (symbol.danger?.stabilityTrade ?? 0) + greedDelta(for: sigils(of: symbol))
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
        // Floored, so even the most reckless book buys a day and a walk across. What a greedy
        // world costs you is safety, not the trip.
        return max(Tuning.World.minimumTurnsPerRun, Int((Double(score) * multiplier).rounded()))
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
        // **Nearest, not down.** The decay rate is the promised turns divided into the meter, so
        // dividing back out lands a hair under — 100 / (100/91) is 90.99999, and flooring it made
        // the world quietly report one turn fewer than the book had promised.
        return Int((Tuning.World.startingStability / decayPerTurn).rounded())
    }

    static func enemyTier(of book: BoundBook, legacyOrdinaryTierDeltas: Bool = true) -> Int {
        enemyTier(symbolIDs: book.allSymbolIDs,
                  legacyOrdinaryTierDeltas: legacyOrdinaryTierDeltas)
    }

    static func enemyTier(symbolIDs: [SymbolID], legacyOrdinaryTierDeltas: Bool = true) -> Int {
        let delta = legacyOrdinaryTierDeltas
            ? symbolIDs.reduce(0) { $0 + (ContentCatalog.shared.symbol($1)?.enemyTierDelta ?? 0) }
            : 0
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
            .filter { !$0.isRealityCurrency && $0.id != Resources.essenceRaw }
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
        for resource in ContentCatalog.shared.resources
        where !resource.isRealityCurrency && resource.id != Resources.essenceRaw {
            weights[resource.id] = Tuning.World.baseResourceWeight
        }
        for id in book.allSymbolIDs {
            guard let symbol = ContentCatalog.shared.symbol(id) else { continue }
            for (resource, multiplier) in symbol.yieldModifiers {
                // A symbol can introduce a resource the base table doesn't carry (Mote Vein).
                guard resource != Resources.essenceRaw else { continue }
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
            return sigils(of: symbol, index: symbolIndex)
        }
    }

    /// What one compound says, spelled out. The same statement a player could place by hand.
    static func sigils(of symbol: SymbolDef, index: Int = 0) -> [Sigil] {
        symbol.expandsTo.enumerated().map { componentIndex, component in
            Sigil(id: InstanceID(rawValue: UInt64(index) << 32 | UInt64(componentIndex)),
                  source: component.source,
                  target: component.target,
                  intensity: component.intensity,
                  negatedTargets: component.negates)
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
