import Foundation

/// **A creature the world cannot afford** (`apex-encounters.md`).
///
/// `LifeRules` spends one fixed ordinary budget, while Vitality controls how many species and bodies
/// the world supports. An apex breaks the ordinary ceiling on purpose: its budget is lifted far past
/// that shared limit, so it is bigger, harder and stranger than anything else that belongs here.
///
/// **That is a good fiction as well as a good mechanic.** It is the exceptional body in an ecology,
/// either intruding from somewhere else or consuming far beyond an ordinary animal's share.
///
/// **No new creature model.** It is the same trait system with the budget lifted, so its identity
/// still derives, its butchery yields are exceptional because its traits are, and it fights through
/// the machinery every other animal fights through.
enum ApexRules {

    // MARK: - Whether one is here at all

    /// **How likely this world is to be holding something it can't feed.**
    ///
    /// Weighted toward the things that already mean *this world is dangerous and worth it*
    /// (`apex-encounters.md` §3). The greed term is the important one: writing a greedy world costs
    /// stability and buys materials, and now it also **draws something** — which makes the decision
    /// richer rather than merely more expensive. *Do I want what's in this world enough to share it?*
    static func chance(greed: Int, stabilityScore: Int, dangerTiles: Int, sites: Int) -> Double {
        var chance = Tuning.Apex.baseChance
        chance += max(0, Double(greed)) / Tuning.Apex.greedForFullDraw * Tuning.Apex.chancePerGreed
        chance += max(0, Double(Tuning.World.startingStability - Double(stabilityScore)))
            / Tuning.World.startingStability * Tuning.Apex.chancePerInstability
        if dangerTiles > 0 { chance += Tuning.Apex.chanceWhenDangerWritten }
        if sites > 0 { chance += Tuning.Apex.chanceWhenSitePresent }
        return min(Tuning.Apex.maximumChance, chance)
    }

    // MARK: - What it is

    /// One apex for a world, or nil where nothing came.
    ///
    /// **At most one** (§2's [PROPOSAL]): two makes them scenery. Deterministic in the world's seed
    /// like everything else, so a resume finds the same animal standing in the same place.
    static func sample(for readings: PressureReadings, seed: UInt64, chance: Double) -> Species? {
        var rng = SeededRNG(seed: seed).derived(0xA9E)
        guard rng.chance(chance) else { return nil }

        // **The same sampling, with the budget lifted.** Everything else about how this world builds
        // an animal still applies — a cold world's apex is still wrapped up, a mineral world's is
        // still armoured — it simply had far more to spend than the world could ever pay.
        var world = WorldTendencies(readings: readings)
        world.budget = max(world.budget, Tuning.Apex.minimumBudget) * Tuning.Apex.budgetMultiple
        // Something that large is what everything else is afraid of, so it is armed like it.
        world.axisWeights[.size, default: 0] *= Tuning.Apex.sizeWeighting
        world.axisWeights[.armament, default: 0] *= Tuning.Apex.armamentWeighting

        let traits = LifeRules.sampleSpecies(in: world, rng: &rng)
        return Species(id: InstanceID(rawValue: rng.next()), traits: traits, worldSeed: seed)
    }

    // MARK: - What it leaves

    /// **The eight things you cannot make** (§4).
    ///
    /// A unique weapon should break a *rule*, not carry bigger numbers: a +3 sword is a crafting
    /// tier, and a weapon that does something no crafted piece can is a reason to go looking. Each
    /// of these is one sentence a crafted weapon can't say.
    ///
    /// **They are not strictly better.** A two-natured blade at a mediocre grade is a real trade
    /// against a superb crafted one — you are buying the rule, not the numbers.
    static var wildWeapons: [ItemID] {
        ContentCatalog.shared.items.compactMap { item in
            guard case .eligible = GearCatalogueDispositionRules.evaluate(
                item.id, route: .apexReward) else { return nil }
            return item.id
        }.sorted { $0.rawValue < $1.rawValue }
    }

    /// Which of them this world would grow, weighted toward its own character.
    ///
    /// **[PROPOSAL] weighted toward the world's own character** (§5), so a cold world's rare drop is
    /// the wild weapon. It should feel like it came from *there* — the alternative is a lottery that
    /// happens to pay out in this world rather than one that belongs to it.
    static func weapon(for readings: PressureReadings, rng: inout SeededRNG) -> ItemID? {
        let relief = readings["relief"], light = readings["illumination"]
        var table: [(value: ItemID, weight: Double)] = wildWeapons.map { (value: $0, weight: 1) }

        func favour(_ id: ItemID, _ bonus: Double) {
            guard let index = table.firstIndex(where: { $0.value == id }) else { return }
            table[index].weight += bonus
        }
        // `rimed_edge` is the save-compatible ID of Barbed Edge. Its old cold affinity belonged to
        // the retired frost fiction; give it a new authored hunting signature in the later affinity pass.
        if light.peak < Tuning.Pressure.aphoticPeak { favour("quiet_knife", Tuning.Apex.characterBonus) }
        if relief.aspect("openness") > Tuning.Pressure.openTerrainThreshold {
            favour("long_fang", Tuning.Apex.characterBonus)
            favour("ranked_spear", Tuning.Apex.characterBonus)
        }
        if readings["vitality"].aspect("trophicDepth") > Tuning.Life.predationThreshold {
            favour("bloodletter", Tuning.Apex.characterBonus)
        }
        return rng.pickWeighted(table)
    }

    /// The cache lottery is deliberately a separate gate so its weapon can sit beside the cache's
    /// guaranteed progression reward rather than replacing it.
    static func cacheBonus(for readings: PressureReadings,
                           chance: Double = Tuning.Apex.lockedCacheChance,
                           rng: inout SeededRNG) -> ItemID? {
        guard rng.chance(chance) else { return nil }
        return weapon(for: readings, rng: &rng)
    }
}

/// **The rule an apex weapon breaks.** One case, one sentence, one place in combat that reads it.
///
/// Authored on the item rather than derived, because these are precisely the things a crafted piece
/// *cannot* produce — a crafted weapon's properties come off its materials, and no material has two
/// dominant armaments or a reach that isn't its haft's.
enum WildRule: String, Codable, CaseIterable, Equatable, Sendable {
    /// Carries **two damage types at once**, and uses whichever the target likes least.
    case twoNatured
    /// **Far reach on a close weapon.** Reach comes from the haft; this one doesn't.
    case reachWithoutHaft
    /// Strikes **both ranks** in one blow. Nothing crafted reaches past the front.
    case bothRanks
    /// Applies a status **without a coating**. Coatings are consumed; this isn't.
    case innateStatus
    /// **Grade rises as you use it.** Grade is set by the material at forging.
    case growingGrade
    /// Attacking **doesn't break concealment**. Nothing else in Shadow allows it.
    case quietStrike
    /// Bleed that **doesn't expire**. Every status has a duration.
    case endlessBleed
    /// Turns aside one damage type **while held**. Wards are a skill, not an object.
    case wardWhileHeld

    var sentence: String {
        switch self {
        case .twoNatured: "Two edges, and it picks the one that hurts more."
        case .reachWithoutHaft: "It reaches further than it has any business reaching."
        case .bothRanks: "It goes through the front rank and into the one behind."
        case .innateStatus: "It leaves something behind without being asked to."
        case .growingGrade: "It is getting better, and you didn't do anything."
        case .quietStrike: "You can use it without being seen using it."
        case .endlessBleed: "What it opens does not close."
        case .wardWhileHeld: "Holding it turns something aside."
        }
    }
}
