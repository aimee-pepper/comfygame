import Foundation

/// Turning a world's pressures into the things that grow in it.
///
/// **The same mechanism as `LifeRules`** (`flora-system-spec.md` §4): pressures produce weights over
/// trait axes and a budget scaled by Vitality; each species spends that budget; identity is read off
/// afterwards. What differs is what flora is *for* — it is terrain before it is anything else.
///
/// **Metabolism is the axis that decides whether a world can live at all** (§2). It is the newest
/// idea in the spec and it carries the most: a lightless world with volatile substrate grows
/// chemosynthetic things and is **not barren**, which is the interesting case and was previously
/// impossible. Every dark world was either sterile or a cellar of mushrooms.
enum FloraRules {

    // MARK: - Metabolism

    /// **How well each way of making a living works here.** 0–1 each, read off the readings alone
    /// and never off the seed — the pre-bind preview has to be able to say this, and the seal rule
    /// says a preview describes what you wrote rather than what was rolled.
    static func viability(in readings: PressureReadings) -> [Metabolism: Double] {
        let light = readings["illumination"]
        let water = readings["hydrology"]
        let substrate = readings["substrate"]

        // Light, and nothing else. Below the aphotic peak there is simply not enough of it.
        let photosynthetic = clamp01(
            (light.peak - Tuning.Flora.photosynthesisFloor)
                / max(1, Tuning.Flora.photosynthesisFull - Tuning.Flora.photosynthesisFloor))

        // Rot needs somewhere damp to happen, and **darkness is what makes it the base of a food web
        // rather than a footnote in one**. Fungi live in a meadow too; they are simply not what the
        // meadow is standing on. So moisture sets the ceiling and darkness decides how much of that
        // ceiling is reached — which is the difference between "there are mushrooms here" and "this
        // world runs on mushrooms".
        let damp = clamp01(water.availableMagnitude / Tuning.Flora.fungalFullMoisture)
        let darkness = 1 - photosynthetic
        let reach = Tuning.Flora.fungalInLight
            + (Tuning.Flora.fungalCeiling - Tuning.Flora.fungalInLight) * darkness
        // A world already full of rot raises the ceiling; it does not remove the damp. **Rot needs
        // somewhere wet to happen**, and adding the bonus on top rather than into the reach let a
        // bone-dry world that happened to be tagged decaying support a fungal food web on nothing.
        let alreadyRotting = readings["vitality"].has("decaying") ? Tuning.Flora.fungalDecayBonus : 0
        let fungal = clamp01(damp * (reach + alreadyRotting))

        // Rock with something left in it. Both terms matter: a volatile share of a world with no
        // substrate at all is a share of nothing.
        let volatility = substrate.share(of: "volatile")
        let chemosynthetic = clamp01(
            volatility / max(0.0001, Tuning.Flora.chemosynthesisFullShare)
                * clamp01(substrate.peak / Tuning.Flora.chemosynthesisFullSubstrate))

        return [.photosynthetic: photosynthetic, .fungal: fungal, .chemosynthetic: chemosynthetic]
    }

    /// The best living to be made here, 0–1. **Zero means nothing grows**, and a world where nothing
    /// grows supports nothing above it either.
    static func bestViability(in readings: PressureReadings) -> Double {
        viability(in: readings).values.max() ?? 0
    }

    /// What a world's flora runs on, where it runs on anything.
    static func dominantMetabolism(in readings: PressureReadings) -> Metabolism? {
        let scores = viability(in: readings)
        // Ties break on the case name, so a world's answer never depends on dictionary order.
        let best = scores
            .filter { $0.value >= Tuning.Flora.viabilityFloor }
            .sorted { $0.value == $1.value ? $0.key.rawValue < $1.key.rawValue : $0.value > $1.value }
        return best.first?.key
    }

    /// **Whether the rock itself is feeding this world.**
    ///
    /// Read by `WorldConstraints` to lift *both* life caps, because eating rock needs neither light
    /// nor water. **This is the case the metabolism axis exists for** — the one the spec says was
    /// previously impossible: "lets dark, dead, mineral worlds have life."
    ///
    /// Deliberately chemosynthesis alone. Fungal darkness is already answered by
    /// `darkLifeFraction` — a dark world keeps most of the life it was written with and is told it
    /// grew mushrooms — and making damp-and-dark exempt outright would have erased the difference
    /// between *writing* Fungus and merely happening to roll a dark world. Writing the word has to
    /// be worth something. Damp also still binds a fungal world, which is right: rot needs wet.
    static func eatsTheRock(_ readings: PressureReadings) -> Bool {
        (viability(in: readings)[.chemosynthetic] ?? 0) >= Tuning.Flora.darkFeedingThreshold
    }

    // MARK: - Productivity

    /// **What the food web stands on** (§7).
    ///
    /// `trophicDepth = f(productivity)`, and productivity is what the page asked for in producers
    /// multiplied by whether this world can actually deliver it. Two consequences the spec names:
    ///
    ///  - A world with **no viable metabolism has no flora, therefore no herbivores, therefore no
    ///    predators.** Whatever lives there subsists on something else entirely.
    ///  - **Chemosynthetic worlds get full food webs in total darkness**, which is a genuinely
    ///    strange and writable place.
    ///
    /// Read off the readings, never the seed, because `WorldConstraints` runs before anything is
    /// sampled and the preview has to agree with the world.
    static func productivity(in readings: PressureReadings) -> Double {
        let life = readings["vitality"]
        // You cannot have more producers than you have life: `producedPeak` is the producer share of
        // the *demand*, and the caps have already had their say about what the world supports.
        let asked = min(life.producedPeak, max(life.peak, 0))
        return max(0, asked) * bestViability(in: readings)
    }

    // MARK: - The cast

    /// What grows here. Deterministic in the world's seed, so an **anchored world keeps its flora**
    /// exactly as it keeps its animals.
    static func cast(for readings: PressureReadings, seed: UInt64) -> [Flora] {
        var rng = SeededRNG(seed: seed).derived(0xF104A)
        let count = castSize(for: readings)
        guard count > 0 else { return [] }
        let world = GrowingConditions(readings: readings)

        var cast: [Flora] = []
        for _ in 0..<count {
            let traits = sampleSpecies(in: world, rng: &rng)
            cast.append(Flora(id: InstanceID(rawValue: rng.next()), traits: traits, worldSeed: seed))
        }
        return cast
    }

    /// How many kinds of plant. **Vitality sets how many, never how strange** — the same rule the
    /// animals get (session 15). Measured against `teemingVitality` rather than a hundred nothing
    /// reaches, and **zero where nothing can make a living**, which is the whole point of the
    /// metabolism axis.
    static func castSize(for readings: PressureReadings) -> Int {
        guard bestViability(in: readings) >= Tuning.Flora.viabilityFloor else { return 0 }
        guard readings["vitality"].peak > 0 else { return 0 }
        let span = Tuning.Flora.castSizeRange
        let raw = span.lowerBound + Int(readings["vitality"].peak / Tuning.Flora.vitalityPerExtraSpecies)
        return max(span.lowerBound, min(span.upperBound, raw))
    }

    // MARK: - What the preview may say

    /// What the Writing Desk can honestly promise about what will grow here, **before it is bound**.
    /// Read off the readings and never off the seed, same seal rule as `LifeRules.projection`.
    struct FloraProjection: Equatable, Sendable {
        var kindCount: Int
        var metabolism: Metabolism?
        var notes: [String]

        var sentence: String {
            guard kindCount > 0, let metabolism else { return "Nothing grows here." }
            let kinds = kindCount == 1
                ? "One thing grows here, and it \(metabolism.singularBlurb)"
                : "\(spelled(kindCount)) things grow here, and they \(metabolism.blurb)"
            guard !notes.isEmpty else { return kinds + "." }
            return "\(kinds) — \(notes.joined(separator: ", "))."
        }

        private func spelled(_ n: Int) -> String {
            let words = ["Zero", "One", "Two", "Three", "Four", "Five", "Six"]
            return words.indices.contains(n) ? words[n] : "\(n)"
        }
    }

    static func projection(for readings: PressureReadings) -> FloraProjection {
        let count = castSize(for: readings)
        guard count > 0 else { return FloraProjection(kindCount: 0, metabolism: nil, notes: []) }
        let world = GrowingConditions(readings: readings)
        var notes: [String] = []

        func ratio(_ axis: FloraAxis) -> Double {
            (world.axisWeights[axis] ?? 0) / max(0.0001, Tuning.Flora.baseAxisWeight(axis))
        }

        if ratio(.stature) > 1.4 { notes.append("tall") }
        else if ratio(.stature) < 0.7 { notes.append("low to the ground") }
        if ratio(.defence) > 1.5 { notes.append("and it defends itself") }
        switch world.free.tissueMix.dominant {
        case .woody: notes.append("hard-stemmed")
        case .fibrous: notes.append("stringy")
        case .fleshy: notes.append("swollen with water")
        }
        return FloraProjection(kindCount: count,
                               metabolism: dominantMetabolism(in: readings),
                               notes: notes)
    }

    // MARK: - One species

    /// Allocate the budget across the axes this world favours, then dress the result in the free
    /// axes. **No role is decided in advance** — identity is read off afterwards.
    static func sampleSpecies(in world: GrowingConditions, rng: inout SeededRNG) -> FloraTraits {
        var traits = FloraTraits()

        // Which corner of the tissue triangle this one favours, decided before anything is spent in
        // it — so buying more tissue thickens what it already had rather than turning a reed into a
        // tree halfway through being made.
        traits.tissue.mix = TissueMix(
            woody: max(0.05, world.free.tissueMix.woody + rng.double(in: -0.4...0.4)),
            fibrous: max(0.05, world.free.tissueMix.fibrous + rng.double(in: -0.4...0.4)),
            fleshy: max(0.05, world.free.tissueMix.fleshy + rng.double(in: -0.4...0.4))
        )

        // **Metabolism is drawn per species, from what the world can support.** A world with light
        // *and* volatile rock genuinely grows both, which is the richest case the axis produces.
        traits.metabolism = rng.pickWeighted(
            world.metabolismWeights
                .map { (value: $0.key, weight: $0.value) }
                .sorted { $0.value.rawValue < $1.value.rawValue }
        ) ?? .photosynthetic

        allocate(world.budget, across: world.axisWeights, into: &traits, rng: &rng)
        applyFreeAxes(of: world, to: &traits, rng: &rng)
        return traits
    }

    /// Spend the budget. Draw an axis by weight, raise it one step, pay the marginal price; stop
    /// when nothing affordable is left.
    static func allocate(_ budget: Double,
                         across weights: [FloraAxis: Double],
                         into traits: inout FloraTraits,
                         rng: inout SeededRNG) {
        // A plant has to be made of *something* before it can be tall or thorny, the same way a
        // creature has to have a body. Without this the allocator produces heights of nothing.
        traits.tissue.setTotal(max(traits.tissue.total, Tuning.Flora.minimumTissue))
        var remaining = budget - FloraCost.totalCost(of: traits)
        var live = weights.filter { $0.value > 0 }
        let step = Tuning.Flora.allocationStep

        while !live.isEmpty, remaining > 0 {
            let table = live.map { (value: $0.key, weight: $0.value) }
                .sorted { $0.value.rawValue < $1.value.rawValue }   // stable order ⇒ stable seed
            guard let axis = rng.pickWeighted(table) else { break }

            let current = traits[axis]
            guard current + step <= Tuning.Pressure.scaleMaximum else { live[axis] = nil; continue }
            let price = FloraCost.marginal(axis, to: current + step, in: traits)
            guard price <= remaining else { live[axis] = nil; continue }

            traits[axis] = current + step
            remaining -= price
        }
    }

    /// Habit, colour, finish, and what kind of defence it went in for. Shaped by pressures, paid for
    /// by nobody.
    static func applyFreeAxes(of world: GrowingConditions, to traits: inout FloraTraits,
                              rng: inout SeededRNG) {
        let free = world.free

        traits.habit = rng.pickWeighted(free.habitWeights.map { (value: $0.key, weight: $0.value) }
            .sorted { $0.value.rawValue < $1.value.rawValue }) ?? .clustered

        // **Active defence is rare and doubly gated** (§6): a world where the undergrowth attacks
        // you is a world you remember, and it shouldn't be common. It needs the world to be rich
        // enough to afford it *and* this plant to have actually spent on defence.
        var types: [(value: DefenceType, weight: Double)] = [
            (.physical, free.physicalDefenceWeight),
            (.chemical, free.chemicalDefenceWeight)
        ]
        if world.allowsActiveDefence, traits.defence >= Tuning.Flora.activeDefenceThreshold {
            types.append((.active, Tuning.Flora.activeDefenceWeight))
        }
        traits.defenceType = rng.pickWeighted(types) ?? .physical

        var colour = Coloration()
        colour.cyan = max(0, rng.double(in: 0...100))
        colour.magenta = max(0, rng.double(in: 0...100))
        colour.yellow = max(0, rng.double(in: 0...100))
        colour.normalise()
        colour.depth = clamp(free.colorationDepth + rng.double(in: -12...12))
        colour.patterning = clamp(free.patterning + rng.double(in: -12...12))
        traits.coloration = colour

        var finish = Finish()
        finish.shine = max(0, free.shineBias + rng.double(in: -8...8))
        finish.schiller = max(0, free.schillerBias + rng.double(in: -6...6))
        finish.opacity = max(5, 100 - finish.shine - finish.schiller)
        finish.normalise()
        traits.finish = finish
    }

    // MARK: - Flora → harvest

    /// **What cutting this down gives you** (§6). Dominant tissue decides the kind; chemical defence
    /// and chemosynthesis each override it, because a toxic plant is worth more as poison than as
    /// timber and a rock-eater is worth more as reagent than as either.
    static func yield(of traits: FloraTraits) -> ResourceID {
        if traits.metabolism == .chemosynthetic { return Resources.reagent }
        if traits.isDefended, traits.defenceType == .chemical { return Resources.toxin }
        if traits.metabolism == .fungal { return Resources.spore }
        switch traits.tissue.dominant {
        case .woody: return traits.stature >= Tuning.Flora.timberStature ? Resources.timber : Resources.fiber
        case .fibrous: return Resources.fiber
        case .fleshy: return Resources.pulp
        }
    }

    /// Every organic resource, so worldgen can tell a flora node from a mineral one.
    static let floraResources: Set<ResourceID> = [
        Resources.timber, Resources.fiber, Resources.pulp,
        Resources.toxin, Resources.spore, Resources.reagent
    ]

    static func isFloraResource(_ id: ResourceID) -> Bool { floraResources.contains(id) }

    static func yieldsSecondaryResin(_ traits: FloraTraits) -> Bool {
        traits.metabolism == .photosynthetic && traits.tissue.dominant == .woody
            && traits.isDefended
    }

    /// **How much a node of this is worth**, before the world's own concentration bonus. Quantity
    /// from stature, exactly as creature quantity comes from size.
    static func harvestQuantity(of traits: FloraTraits) -> Int {
        let scaled = Tuning.Flora.baseHarvest
            + traits.stature / Tuning.Pressure.scaleMaximum * Tuning.Flora.harvestPerStature
        return max(1, Int(scaled.rounded()))
    }

    /// What a cut plant leaves, as a material with properties — the parallel of `ButcheryRules`.
    ///
    /// **Grade scales with trait extremity**, same rule as creature loot, so an ordinary shrub gives
    /// ordinary fibre and a towering ironbarked thing gives timber worth carrying home.
    static func material(from traits: FloraTraits, named source: String,
                         qualifier: String? = nil) -> MaterialSample {
        let kind: MaterialKind = switch yield(of: traits) {
        case Resources.timber: .timber
        case Resources.toxin: .toxin
        case Resources.reagent: .reagent
        case Resources.pulp: .pulp
        default: .fibre
        }
        let woodiness = traits.tissue.woody
        return MaterialSample(
            kind: kind,
            properties: MaterialProperties(
                hardness: woodiness * Tuning.Flora.hardnessPerWoody,
                density: woodiness * Tuning.Flora.densityPerWoody,
                // Fleshy tissue is water and air, and both of those are what keeps the cold out.
                insulation: traits.tissue.fleshy * Tuning.Flora.insulationPerFleshy,
                flexibility: traits.tissue.fibrous * Tuning.Flora.flexibilityPerFibrous,
                lustre: traits.finish.lustre,
                // What a plant defends itself with is what an apothecary wants from it.
                reactivity: reactivity(of: traits)
            ),
            grade: ButcheryRules.grade(of: [traits.stature, traits.tissue.total, traits.defence],
                                       lustre: traits.finish.lustre),
            source: source,
            qualifier: qualifier
        )
    }

    /// How much of it ends up in the wound, or in the flask.
    static func reactivity(of traits: FloraTraits) -> Double {
        var value = 0.0
        if traits.isDefended, traits.defenceType == .chemical { value += traits.defence }
        if traits.metabolism == .chemosynthetic { value += Tuning.Flora.chemosyntheticReactivity }
        return min(Tuning.Pressure.scaleMaximum, value)
    }

    // MARK: - Flora → hazard

    /// **What walking into this costs you** (§6), and how long for.
    ///
    /// Physical hurts once. Chemical keeps hurting. Active doesn't do damage here at all — it stands
    /// up and fights, which is a `WorldEnemy` rather than a tile effect.
    struct Harm: Equatable, Sendable {
        var immediate: Int
        /// Turns of lingering damage after the tile itself.
        var lingering: Int

        static let none = Harm(immediate: 0, lingering: 0)
        var isSomething: Bool { immediate > 0 || lingering > 0 }
    }

    static func harm(of traits: FloraTraits, severity: Double = 1) -> Harm {
        guard traits.isDefended else { return .none }
        let bite = traits.defence / Tuning.Pressure.scaleMaximum
        switch traits.defenceType {
        case .physical:
            return Harm(immediate: max(1, Int((bite * Tuning.Flora.thornDamage * max(0, severity)).rounded())),
                        lingering: 0)
        case .chemical:
            // Less on the way in, and it stays with you — which is what makes toxic growth a
            // different decision from a thorn hedge rather than the same one at another number.
            return Harm(immediate: max(1, Int((bite * Tuning.Flora.toxinDamage * max(0, severity)).rounded())),
                        lingering: max(1, Int((Double(Tuning.Flora.toxinRounds)
                                              * max(0, severity)).rounded())))
        case .active:
            return .none
        }
    }

    /// **The animal a predatory plant is, for combat purposes.**
    ///
    /// `flora-system-spec.md` §9.3 asks whether an active-defence plant belongs in the creature
    /// system with `build: sessile` instead of in flora. The conservative answer is *both*: it is
    /// grown by the flora system and fought by the creature system, so there is no second combat
    /// model and no second loot table. It is armed with its defence, armoured by its woodiness, and
    /// it does not move — which the map enforces rather than the traits.
    static func combatant(from traits: FloraTraits) -> CreatureTraits {
        var creature = CreatureTraits()
        creature.size = traits.stature
        creature.covering = Covering(hardness: traits.tissue.woody,
                                     length: traits.tissue.fibrous * 0.5,
                                     coverage: min(Tuning.Pressure.scaleMaximum, traits.tissue.total))
        creature.boneDensity = traits.tissue.woody * Tuning.Flora.boneFromWoody
        // Thorns tear and grip. Nothing about a plant crushes.
        creature.armament.mix = WeaponMix(pierce: 1.4, crush: 0.1, rend: 1.2)
        creature.armament.setTotal(traits.defence * Tuning.Flora.armamentFromDefence)
        creature.armament.reach = .close
        creature.armament.delivery = .single
        creature.build = Tuning.Flora.sessileBuild
        creature.appendages = Appendages(count: 0, type: .none)
        creature.coloration = traits.coloration
        creature.finish = traits.finish
        // It has no eyes and it does not need them: you are standing in it.
        creature.sensory = Sensory.allocation(vision: 0, mechano: 70, chemo: 30, thermo: 0)
        creature.isToxic = traits.defenceType == .chemical
        return creature
    }

    // MARK: - Helpers

    private static func clamp(_ v: Double) -> Double { min(Tuning.Pressure.scaleMaximum, max(0, v)) }
    private static func clamp01(_ v: Double) -> Double { min(1, max(0, v)) }
}

// MARK: - Pressures → weights

/// What a world tends to grow, and how much it has to grow it with.
///
/// **Weights, not values**, exactly as `WorldTendencies` is — which is what keeps two worlds with
/// the same pressures from producing the same plants, and one world from producing four copies of
/// one plant.
struct GrowingConditions: Equatable, Sendable {
    var axisWeights: [FloraAxis: Double]
    var budget: Double
    var metabolismWeights: [Metabolism: Double]
    var free: FreeGrowthTendencies
    /// Whether this world is rich enough to afford a plant that fights back.
    var allowsActiveDefence: Bool

    init(readings: PressureReadings) {
        let light = readings["illumination"]
        let water = readings["hydrology"]
        let substrate = readings["substrate"]
        let thermal = readings["thermal"]
        let vitality = readings["vitality"]
        let cycle = readings["cycle"]

        var w: [FloraAxis: Double] = [:]
        for axis in FloraAxis.allCases { w[axis] = Tuning.Flora.baseAxisWeight(axis) }
        var free = FreeGrowthTendencies()

        // **Light is a race.** Where there is plenty of it, the way to get it is to be taller than
        // whatever is next to you — which is why a lit world grows canopy and a dark one grows mats.
        let brightness = Self.clamp01(light.peak / Tuning.Pressure.scaleMaximum)
        w[.stature]! *= Tuning.Flora.statureInDark
            + (Tuning.Flora.statureInFullLight - Tuning.Flora.statureInDark) * brightness
        free.colorationDepth += 20 * brightness      // sun-facing tissue is darker
        if light.peak < Tuning.Pressure.aphoticPeak {
            free.colorationDepth -= 30               // nothing pale needs to be pale for a reason
            free.habitWeights[.spreading]! += 0.8    // grow sideways when up buys nothing
        }

        // **Water.** Saturation grows big soft things that don't bother defending themselves —
        // there is always more where that came from. Drought grows small swollen ones that do:
        // spines are reduced leaves, which is the neatest fact in the whole table.
        let wetness = water.availableMagnitude
        if wetness > Tuning.Pressure.wetThreshold {
            let wet = Self.clamp01((wetness - Tuning.Pressure.wetThreshold)
                / max(1, Tuning.Pressure.scaleMaximum - Tuning.Pressure.wetThreshold))
            free.tissueMix.fleshy += 1.0 * wet
            w[.stature]! *= 1 + 0.5 * wet
            w[.defence]! *= max(0.35, 1 - 0.6 * wet)
        } else if wetness < Tuning.Pressure.aridThreshold {
            let dry = Self.clamp01((Tuning.Pressure.aridThreshold - wetness) / Tuning.Pressure.aridThreshold)
            free.tissueMix.fleshy += 1.4 * dry       // succulence
            w[.stature]! *= max(0.2, 1 - 0.8 * dry)  // ↓↓
            w[.defence]! *= 1 + 1.2 * dry
            free.physicalDefenceWeight += 1.4 * dry  // spines are reduced leaves
            free.habitWeights[.solitary]! += 0.9 * dry
        }

        // **The resource availability hypothesis**: slow growth defends what it cannot replace. Poor
        // ground grows woody, well-armed things; rich ground grows soft ones that don't bother.
        let fertility = Self.clamp01(substrate.peak / Tuning.Pressure.scaleMaximum)
        if fertility < Tuning.Flora.poorSubstrate {
            let poor = 1 - fertility / max(0.0001, Tuning.Flora.poorSubstrate)
            free.tissueMix.woody += 1.2 * poor
            w[.defence]! *= 1 + 1.6 * poor           // ↑↑
        } else {
            let rich = (fertility - Tuning.Flora.poorSubstrate)
                / max(0.0001, 1 - Tuning.Flora.poorSubstrate)
            free.tissueMix.fleshy += 0.8 * rich
            w[.defence]! *= max(0.4, 1 - 0.5 * rich)
        }
        if substrate.share(of: "volatile") > 0.3 || readings["atmosphere"].has("toxic") {
            free.chemicalDefenceWeight += 1.2       // a world that supplies the poison
            free.schillerBias += 6
        }

        // **Cold.** Low, woody, and huddled together — which is what a treeline actually looks like.
        if thermal.floor < Tuning.Pressure.coldFloor {
            let cold = Self.clamp01((Tuning.Pressure.coldFloor - thermal.floor) / Tuning.Pressure.coldFloor)
            w[.stature]! *= max(0.25, 1 - 0.7 * cold)
            free.tissueMix.woody += 1.1 * cold
            free.habitWeights[.clustered]! += 1.2 * cold
        }
        // Heat with no water to go with it is the same answer drought gave, harder.
        if thermal.peak > Tuning.Pressure.hotPeak, wetness < Tuning.Pressure.aridThreshold {
            let heat = Self.clamp01((thermal.peak - Tuning.Pressure.hotPeak)
                / max(1, Tuning.Pressure.scaleMaximum - Tuning.Pressure.hotPeak))
            w[.stature]! *= max(0.2, 1 - 0.6 * heat)
            free.tissueMix.fleshy += 0.9 * heat
            free.physicalDefenceWeight += 1.0 * heat
            free.shineBias += 14 * heat              // a waxy skin is how you keep water in
        }

        // **A hard year needs a store to live off.** Amplitude is the size of the swing; storage is
        // the answer to it, and storage is fleshy tissue.
        let amplitude = cycle.aspect("amplitude") / Tuning.Pressure.scaleMaximum
        free.tissueMix.fleshy += 1.0 * amplitude

        // **Herbivore pressure wins.** Rich ground says don't bother defending; things eating you
        // says defend anyway, and it overrides — which is real ecology and what stops flora defence
        // from being a single-variable readout of soil quality (§3).
        let grazing = Self.clamp01(vitality.aspect("trophicDepth") / Tuning.Pressure.scaleMaximum)
        if grazing > Tuning.Flora.grazingThreshold {
            w[.defence]! = max(w[.defence]!, Tuning.Flora.baseAxisWeight(.defence))
                * (1 + Tuning.Flora.defenceUnderGrazing * grazing)
        }

        // A world can only grow what it can feed.
        budget = Tuning.Flora.baseBudget + vitality.peak * Tuning.Flora.budgetPerVitality

        // Metabolism, drawn from what actually works here. Anything below the floor is not on the
        // table at all, which is what makes "nothing grows in this world" a reachable state.
        metabolismWeights = FloraRules.viability(in: readings)
            .filter { $0.value >= Tuning.Flora.viabilityFloor }

        // Predatory undergrowth needs both a rich world and heavy predation to be worth it.
        allowsActiveDefence = vitality.peak >= Tuning.Flora.activeDefenceVitality
            && grazing >= Tuning.Flora.activeDefenceGrazing

        free.clampToRanges()
        axisWeights = w
        self.free = free
    }

    private static func clamp01(_ v: Double) -> Double { min(1, max(0, v)) }
}

/// Where the free axes sit before a species is drawn. Shifted by pressures, never bought.
struct FreeGrowthTendencies: Equatable, Sendable {
    var tissueMix = TissueMix()
    var habitWeights: [Habit: Double] = [.spreading: 1, .clustered: 1.4, .solitary: 0.7]
    var physicalDefenceWeight: Double = 1.6
    var chemicalDefenceWeight: Double = 0.9
    var colorationDepth: Double = 50
    var patterning: Double = 14
    var shineBias: Double = 8
    var schillerBias: Double = 2

    mutating func clampToRanges() {
        colorationDepth = min(100, max(0, colorationDepth))
        patterning = min(100, max(0, patterning))
    }
}

extension TissueMix {
    /// Which corner this world leans toward before any one plant varies from it.
    var dominant: TissueKind {
        if woody >= fibrous && woody >= fleshy { return .woody }
        if fibrous >= fleshy { return .fibrous }
        return .fleshy
    }
}
