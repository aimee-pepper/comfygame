import Foundation

/// Turning a world's pressures into the animals in it.
///
/// **The mechanism** (creature-system-spec §1): a world's pressures produce **weights** over trait
/// axes and a **budget** scaled by Vitality. Each species is made by **spending that budget across
/// the costly axes, weighted-randomly** — so pressures decide what a world *tends* to build, the
/// budget decides how much there is to build with, and randomness decides where each species
/// actually lands. Free axes are shaped by pressures without spending anything.
///
/// **Why budget-allocation rather than independent rolls: it produces trade-offs for free.** A world
/// pushing both size and armour cannot have both maxed. Every species is a different answer to the
/// same constrained problem, which is what makes a cast feel like an ecosystem rather than a list.
///
/// **Two stages** (session 15 §1): a world draws a small **cast** of species, and every spawn is its
/// species plus small jitter. You meet the same few animals repeatedly, and each one is visibly its
/// own animal.
///
/// **Vitality sets cast *size*, not spread** (§2). A rich world holds six species where a barren one
/// holds two, but those six are no stranger. Abundance and strangeness are independent knobs, which
/// is what lets you write a teeming ordinary world and a sparse bizarre one and have them differ.
enum LifeRules {

    // MARK: - The cast

    /// The species a world settled on. Deterministic in the world's seed, so an **anchored world
    /// keeps its cast forever** (§3) — the same animals live there, and you learn them.
    static func cast(for readings: PressureReadings, seed: UInt64) -> [Species] {
        var rng = SeededRNG(seed: seed).derived(0x11FE)
        let world = WorldTendencies(readings: readings)
        let count = castSize(for: readings)

        var species: [Species] = []
        for _ in 0..<count {
            let traits = sampleSpecies(in: world, rng: &rng)
            species.append(Species(id: InstanceID(rawValue: rng.next()), traits: traits, worldSeed: seed))
        }
        return species
    }

    /// How many species. **Vitality, and only vitality** — 2 at barren, 6 at teeming.
    static func castSize(for readings: PressureReadings) -> Int {
        let vitality = readings["vitality"].peak
        let span = Tuning.Life.castSizeRange
        let raw = span.lowerBound + Int(vitality / Tuning.Life.vitalityPerExtraSpecies)
        return max(span.lowerBound, min(span.upperBound, raw))
    }

    // MARK: - One species

    /// Allocate the budget across the axes this world favours, then dress the result in the free
    /// axes. **No role is decided in advance** — identity is read off afterwards.
    static func sampleSpecies(in world: WorldTendencies, rng: inout SeededRNG) -> CreatureTraits {
        var traits = CreatureTraits()
        var weights = world.axisWeights

        // Which corner of the weapon triangle this one favours, decided before anything is spent
        // in it — so buying more armament sharpens what it already had rather than turning a biter
        // into a crusher halfway through being made.
        traits.armament.mix = WeaponMix(
            pierce: max(0.05, world.free.weaponMix.pierce + rng.double(in: -0.4...0.4)),
            crush: max(0.05, world.free.weaponMix.crush + rng.double(in: -0.4...0.4)),
            rend: max(0.05, world.free.weaponMix.rend + rng.double(in: -0.4...0.4))
        )

        // The defence branch is picked *before* allocation where it changes what gets bought, and
        // applied to appearance afterwards where it doesn't. One route, never a blend (spec §3).
        let branch = defenceBranch(in: world, rng: &rng)
        traits.defence = branch
        if let branch { apply(branch, to: &weights) }

        allocate(world.budget, across: weights, into: &traits, rng: &rng)
        applyFreeAxes(of: world, to: &traits, rng: &rng)
        if let branch { apply(branch, to: &traits, in: world, rng: &rng) }
        return traits
    }

    /// Spend the budget. Draw an axis by weight, raise it one step, pay the marginal price; stop
    /// when nothing affordable is left. The superlinear curve means extremes are bought late and
    /// dearly, which is what makes a maxed-out anything rare enough to be worth meeting.
    static func allocate(_ budget: Double,
                         across weights: [CostlyAxis: Double],
                         into traits: inout CreatureTraits,
                         rng: inout SeededRNG) {
        // A creature has to exist before it can be anything, so the first thing every world buys is
        // a body. Without this the allocator happily produces size-0 animals carrying enormous
        // claws, which is not a trade-off — it's nothing with teeth.
        traits.size = max(traits.size, Tuning.Life.minimumSize)
        traits.covering.coverage = max(traits.covering.coverage, Tuning.Life.baselineCoverage)
        var remaining = budget - LifeCost.totalCost(of: traits)
        var live = weights.filter { $0.value > 0 }
        let step = Tuning.Life.allocationStep

        while !live.isEmpty, remaining > 0 {
            let table = live.map { (value: $0.key, weight: $0.value) }
                .sorted { $0.value.rawValue < $1.value.rawValue }   // stable order ⇒ stable seed
            guard let axis = rng.pickWeighted(table) else { break }

            let current = traits[axis]
            guard current + step <= Tuning.Pressure.scaleMaximum else { live[axis] = nil; continue }
            let price = LifeCost.marginal(axis, to: current + step, in: traits)
            guard price <= remaining else { live[axis] = nil; continue }

            traits[axis] = current + step
            remaining -= price
        }
    }

    // MARK: - Free axes

    /// Shape, colour, senses and appendages. Shaped by pressures, paid for by nobody — so even a
    /// starving world produces animals that look like themselves rather than like nothing.
    static func applyFreeAxes(of world: WorldTendencies, to traits: inout CreatureTraits, rng: inout SeededRNG) {
        let free = world.free

        traits.build = clamp(free.build + rng.double(in: -1...1) * free.buildSpread)

        traits.armament.reach = rng.pickWeighted(free.reachWeights.map { (value: $0.key, weight: $0.value) }
            .sorted { $0.value.rawValue < $1.value.rawValue }) ?? .close
        traits.armament.delivery = rng.pickWeighted(free.deliveryWeights.map { (value: $0.key, weight: $0.value) }
            .sorted { $0.value.rawValue < $1.value.rawValue }) ?? .single

        traits.appendages.type = rng.pickWeighted(free.appendageTypeWeights.map { (value: $0.key, weight: $0.value) }
            .sorted { $0.value.rawValue < $1.value.rawValue }) ?? .limbed
        traits.appendages.count = traits.appendages.type == .none
            ? 0
            : max(0, min(8, Int((free.appendageCount + rng.double(in: -1.4...1.4)).rounded())))

        // Sensory is an *allocation*: a creature that sees badly necessarily senses something else
        // well, which is what makes a blind world's animals read as adapted rather than deprived.
        var sensory = Sensory()
        sensory.vision = max(0, free.sensory.vision + rng.double(in: -8...8))
        sensory.mechano = max(0, free.sensory.mechano + rng.double(in: -8...8))
        sensory.chemo = max(0, free.sensory.chemo + rng.double(in: -8...8))
        sensory.thermo = max(0, free.sensory.thermo + rng.double(in: -8...8))
        sensory.normalise()
        traits.sensory = sensory

        var colour = Coloration()
        colour.cyan = max(0, rng.double(in: 0...100))
        colour.magenta = max(0, rng.double(in: 0...100))
        colour.yellow = max(0, rng.double(in: 0...100))
        colour.normalise()
        colour.depth = clamp(free.colorationDepth + rng.double(in: -12...12))
        colour.patterning = clamp(free.patterning + rng.double(in: -12...12))
        traits.coloration = colour

        // Ornament buys the surface, so lustre follows what was actually spent — one direction only.
        // (The spec describes the ornament↔finish relationship from both ends; taking the loop out
        // is the only non-circular reading. Logged in questions-for-design.)
        var finish = Finish()
        finish.shine = max(0, traits.ornament * 0.5 + free.shineBias + rng.double(in: -8...8))
        finish.schiller = max(0, traits.ornament * 0.3 + free.schillerBias + rng.double(in: -8...8))
        finish.opacity = max(5, 100 - finish.shine - finish.schiller)
        finish.normalise()
        traits.finish = finish

        if free.emanationAllowed, rng.chance(free.emanationChance) {
            traits.emanation = Emanation(strength: clamp(free.emanationStrength + rng.double(in: -15...15)),
                                         light: free.emanationLight,
                                         heat: free.emanationHeat,
                                         caustic: free.emanationCaustic)
        }
    }

    // MARK: - Defence branching

    /// **One** of four routes where predation pressure is high, never a blend. Which one is per
    /// world: open ground rewards running, enclosed ground rewards hiding, a mineral world can
    /// afford plate, and only a rich world can afford to advertise.
    static func defenceBranch(in world: WorldTendencies, rng: inout SeededRNG) -> DefenceBranch? {
        guard world.predation >= Tuning.Life.predationThreshold else { return nil }
        let table: [(value: DefenceBranch, weight: Double)] = [
            (.armour, world.armourAffordance),
            (.speed, world.speedAffordance),
            (.crypsis, world.crypsisAffordance),
            (.aposematism, world.aposematismAffordance)
        ]
        return rng.pickWeighted(table)
    }

    private static func apply(_ branch: DefenceBranch, to weights: inout [CostlyAxis: Double]) {
        switch branch {
        case .armour:
            weights[.coveringHardness, default: 0] *= 2.4
            weights[.coveringCoverage, default: 0] *= 2.0
            weights[.boneDensity, default: 0] *= 1.4
        case .speed:
            weights[.size] = (weights[.size] ?? 0) * 0.45
            weights[.coveringHardness] = (weights[.coveringHardness] ?? 0) * 0.25
            weights[.coveringCoverage] = (weights[.coveringCoverage] ?? 0) * 0.5
            weights[.boneDensity] = (weights[.boneDensity] ?? 0) * 0.5
        case .crypsis, .aposematism:
            break // appearance, not investment
        }
    }

    private static func apply(_ branch: DefenceBranch,
                              to traits: inout CreatureTraits,
                              in world: WorldTendencies,
                              rng: inout SeededRNG) {
        switch branch {
        case .armour:
            break
        case .speed:
            traits.build = clamp(Tuning.Life.sleekBuild + rng.double(in: -6...6))
        case .crypsis:
            // Matched to the ambient rather than simply dark: a pale world hides pale things.
            traits.coloration.depth = clamp(world.free.ambientDepth + rng.double(in: -6...6))
            traits.coloration.patterning = clamp(45 + rng.double(in: -15...15))
        case .aposematism:
            // Maximally contrasting, and honest about it.
            traits.coloration.patterning = clamp(88 + rng.double(in: -8...8))
            traits.coloration.depth = clamp(world.free.ambientDepth > 50 ? 18 : 86)
            traits.isToxic = true
        }
    }

    // MARK: - A spawn

    /// One animal: its species, plus jitter. **[PLACEHOLDER]** coloration ±10, size ±5%, finish ±5.
    ///
    /// **Jitter must never change identity, combat behaviour, or which materials drop** (spec §5).
    /// It's texture: you meet the same animal, and this one is a bit paler and a bit smaller.
    static func spawn(of species: Species, rng: inout SeededRNG) -> CreatureTraits {
        var traits = species.traits
        let j = Tuning.Life.jitter

        traits.coloration.cyan = max(0, traits.coloration.cyan + rng.double(in: -j.coloration...j.coloration))
        traits.coloration.magenta = max(0, traits.coloration.magenta + rng.double(in: -j.coloration...j.coloration))
        traits.coloration.yellow = max(0, traits.coloration.yellow + rng.double(in: -j.coloration...j.coloration))
        traits.coloration.normalise()
        traits.coloration.depth = clamp(traits.coloration.depth + rng.double(in: -j.coloration...j.coloration))

        traits.size = clamp(traits.size * (1 + rng.double(in: -j.sizeFraction...j.sizeFraction)))

        traits.finish.shine = max(0, traits.finish.shine + rng.double(in: -j.finish...j.finish))
        traits.finish.schiller = max(0, traits.finish.schiller + rng.double(in: -j.finish...j.finish))
        traits.finish.normalise()

        return traits
    }

    private static func clamp(_ v: Double) -> Double { min(Tuning.Pressure.scaleMaximum, max(0, v)) }
}

// MARK: - Costly axes

/// The axes the budget is spent on. Everything else about a creature is free.
///
/// **Armament is one axis, not three.** How much a creature has invested in hurting you is a single
/// decision; *which corner of the weapon triangle* it spends that in is free. Charging pierce, crush
/// and rend separately gave weapons a third of every world's budget and produced creatures with no
/// body and enormous claws — and a thing that is simultaneously the best piercer, crusher and render
/// isn't a trade-off at all, which is the one thing the triangle exists to be.
enum CostlyAxis: String, CaseIterable, Codable, Equatable, Sendable {
    case size
    case coveringHardness, coveringLength, coveringCoverage
    case boneDensity
    case armament
    case ornament
}

extension CreatureTraits {
    subscript(axis: CostlyAxis) -> Double {
        get {
            switch axis {
            case .size: size
            case .coveringHardness: covering.hardness
            case .coveringLength: covering.length
            case .coveringCoverage: covering.coverage
            case .boneDensity: boneDensity
            case .armament: armament.total
            case .ornament: ornament
            }
        }
        set {
            switch axis {
            case .size: size = newValue
            case .coveringHardness: covering.hardness = newValue
            case .coveringLength: covering.length = newValue
            case .coveringCoverage: covering.coverage = newValue
            case .boneDensity: boneDensity = newValue
            case .armament: armament.setTotal(newValue)
            case .ornament: ornament = newValue
            }
        }
    }
}

/// What each point of each axis costs the world.
///
/// **Superlinear so extremes are expensive** (spec §4): `cost = (value/100)^1.5 × axisWeight`. Size
/// costs the most, because the square–cube law says a big animal needs dense bone and thick limbs to
/// exist at all — and **[PROPOSAL]** size additionally raises the price of covering and bone, so
/// large armoured creatures are genuinely rare and worth the world that grows them.
enum LifeCost {
    static func price(of axis: CostlyAxis, at value: Double, size: Double) -> Double {
        let normalised = max(0, value) / Tuning.Pressure.scaleMaximum
        let base = pow(normalised, Tuning.Life.costExponent) * Tuning.Life.axisCost(axis)
        return base * sizeCoupling(for: axis, size: size)
    }

    /// What it costs to raise one axis, *given everything the creature already is*.
    ///
    /// Priced off the whole vector rather than off the axis alone so that spend telescopes exactly
    /// to `totalCost`: growing bigger re-prices the armour you're already carrying, which is both
    /// physically right and what keeps "what this cost" and "what was actually spent" identical. An
    /// axis-local marginal would let a creature buy armour cheap and then grow into it for free.
    static func marginal(_ axis: CostlyAxis, to newValue: Double, in traits: CreatureTraits) -> Double {
        var after = traits
        after[axis] = newValue
        return totalCost(of: after) - totalCost(of: traits)
    }

    static func totalCost(of traits: CreatureTraits) -> Double {
        CostlyAxis.allCases.reduce(0) { $0 + price(of: $1, at: traits[$1], size: traits.size) }
    }

    /// Bulk makes armour and bone dearer. Nothing else scales with it.
    private static func sizeCoupling(for axis: CostlyAxis, size: Double) -> Double {
        switch axis {
        case .coveringHardness, .coveringLength, .coveringCoverage, .boneDensity:
            1 + (size / Tuning.Pressure.scaleMaximum) * Tuning.Life.sizeCostCoupling
        default:
            1
        }
    }
}

// MARK: - Pressures → weights

/// What a world tends to build, and how much it has to build with.
///
/// **Weights, not values** (spec §3) — this is what keeps two worlds with the same pressures from
/// producing the same animals, and one world from producing five copies of one animal.
struct WorldTendencies: Equatable, Sendable {
    var axisWeights: [CostlyAxis: Double]
    var budget: Double
    var free: FreeAxisTendencies
    /// How much is trying to eat you. Drives whether species take a defence branch at all.
    var predation: Double
    var armourAffordance: Double
    var speedAffordance: Double
    var crypsisAffordance: Double
    var aposematismAffordance: Double

    init(readings: PressureReadings) {
        let thermal = readings["thermal"]
        let light = readings["illumination"]
        let water = readings["hydrology"]
        let substrate = readings["substrate"]
        let relief = readings["relief"]
        let vitality = readings["vitality"]
        let atmosphere = readings["atmosphere"]

        var w: [CostlyAxis: Double] = [:]
        for axis in CostlyAxis.allCases { w[axis] = Tuning.Life.baseAxisWeight(axis) }
        var free = FreeAxisTendencies()

        // Cold: bigger, better wrapped, shorter reach. Wet-cold favours bulk over fur, because fur
        // fails when it's wet — both are valid answers, which is why this weights rather than sets.
        //
        // The ramps run 0→1 across the whole cold (or hot) range rather than over an arbitrary 50
        // points, because the spec marks these ↑↑ — its strongest signal. A ramp that only reaches
        // half strength at the coldest temperature the game can write leaves glaciers full of naked
        // animals, which is the one thing the cold rules exist to prevent.
        if thermal.floor < Tuning.Pressure.coldFloor {
            let cold = min(1, (Tuning.Pressure.coldFloor - thermal.floor) / Tuning.Pressure.coldFloor)
            let wet = water.availableMagnitude > Tuning.Pressure.wetThreshold
            w[.size]! *= 1 + 1.4 * cold
            if wet {
                free.build += 26 * cold                       // fat, not fur
                w[.coveringLength]! *= 1 + 0.4 * cold
                w[.coveringCoverage]! *= 1 + 0.5 * cold
            } else {
                w[.coveringLength]! *= 1 + 2.6 * cold
                w[.coveringCoverage]! *= 1 + 2.2 * cold
            }
            w[.ornament]! *= max(0.2, 1 - 0.7 * cold)         // nothing spare for display
            free.reachWeights[.close]! += 0.9 * cold
            free.appendageCount += 1.2 * cold                 // cold water grows extra limbs
        }
        // Heat: smaller, barer, longer. Radiators, and pale against the sun.
        if thermal.peak > Tuning.Pressure.hotPeak {
            let heat = min(1, (thermal.peak - Tuning.Pressure.hotPeak)
                / (Tuning.Pressure.scaleMaximum - Tuning.Pressure.hotPeak))
            w[.size]! *= max(0.25, 1 - 0.7 * heat)
            w[.coveringCoverage]! *= max(0.2, 1 - 0.8 * heat)
            free.reachWeights[.far]! += 1.1 * heat
            free.colorationDepth -= 22 * heat
        }

        // Light. Dim worlds grow eyes; dark ones give up on them entirely and grow everything else.
        switch light.peak {
        case ..<10:
            free.sensory = Sensory.allocation(vision: 3, mechano: 44, chemo: 33, thermo: 20)
            free.colorationDepth -= 25
            free.appendageCount += 1.6
        case 10..<35:
            free.sensory = Sensory.allocation(vision: 68, mechano: 14, chemo: 12, thermo: 6)
            free.colorationDepth += 18
        case 75...:
            w[.ornament]! *= 1.9                              // signalling pays where it can be seen
            free.colorationDepth -= 8                          // countershaded rather than uniform
            free.patterning += 18
            free.schillerBias += 10
        default:
            break
        }
        // Light with nothing in the sky to come from is the bioluminescence case.
        if light.floor > 0 && !light.has("celestial") {
            free.emanationAllowed = true
            free.emanationChance = Tuning.Life.emanationChanceWhenSourceless
            free.emanationStrength = 55 + light.floor * 0.3
        }
        free.ambientDepth = min(100, max(0, 70 - light.peak * 0.5))

        // Water. Saturation darkens everything; a body of water you can actually swim in is a
        // different claim, and only that one reshapes the animal.
        //
        // **The gate matters.** Wet-cold wants bulk (fat, not fur) and open water wants sinuous, so
        // applying the aquatic body plan to mere wetness would have rain cancelling out the one
        // thing a cold rainy world is supposed to grow. The spec gates it on standing-and-flowing
        // water for exactly this reason.
        let wetness = water.availableMagnitude
        if wetness > Tuning.Pressure.wetThreshold { free.colorationDepth += 10 }
        let openWater = water.share(of: "standing") + water.share(of: "flowing")
        if wetness > Tuning.Pressure.wetThreshold, openWater > 0.5 {
            free.appendageTypeWeights[.finned]! += 1.4
            free.build -= 14                                   // sinuous
            let deep = water.share(of: "standing") > 0.5 && water.aspect("dispersion") < 40
            w[.boneDensity]! *= deep ? 0.55 : 1.5
        }

        // Stone in the ground becomes stone on the animal.
        let mineral = substrate.peak / Tuning.Pressure.scaleMaximum
        w[.coveringHardness]! *= 1 + 1.5 * mineral * (substrate.share(of: "hard") + 0.4)
        w[.boneDensity]! *= 1 + 0.8 * mineral
        if substrate.share(of: "hard") > 0.35 { free.shineBias += 12 }
        if substrate.share(of: "volatile") > 0.3 {
            free.emanationAllowed = true
            free.emanationChance = max(free.emanationChance, Tuning.Life.emanationChanceWhenVolatile)
            free.emanationStrength = max(free.emanationStrength, 45)
            free.emanationHeat += 30
            free.emanationCaustic += 20
            free.schillerBias += 8
        }

        // Open ground makes pursuers; enclosed ground makes ambushers.
        let openness = relief.aspect("openness")
        if openness > Tuning.Pressure.openTerrainThreshold {
            w[.coveringCoverage]! *= 0.7
            free.build += 8                                    // sleek
            free.reachWeights[.mid]! += 1.2
            free.appendageTypeWeights[.limbed]! += 0.8
        } else {
            free.weaponMix.pierce += 1.4                       // ambush weapons
            free.build -= 6                                    // compact
            free.reachWeights[.close]! += 1.0
            free.patterning += 12
        }
        // Heavy bone and hard ground make things that hit rather than bite.
        free.weaponMix.crush += 1.2 * mineral
        free.weaponMix.rend += 0.8 * (openness / Tuning.Pressure.scaleMaximum)
        if relief.aspect("verticality") > 55 {
            free.appendageTypeWeights[.membrane]! += 0.9
            w[.boneDensity]! *= 0.8
        }

        // Thin air lets small things grow; thick air carries fliers.
        if atmosphere.peak > 60 { w[.size]! *= 1.2 }
        if atmosphere.aspect("motion") > 55 { free.appendageTypeWeights[.feathered]! += 0.9 }

        // A world can only afford what it can feed.
        budget = Tuning.Life.baseBudget + vitality.peak * Tuning.Life.budgetPerVitality
        let productivity = vitality.peak / Tuning.Pressure.scaleMaximum
        w[.ornament]! *= 0.3 + 1.7 * productivity

        // Trophic depth is predation: deep webs push armament hard on some and to nothing on others,
        // which is exactly the split the defence branch is for.
        predation = vitality.aspect("trophicDepth")
        let depth = predation / Tuning.Pressure.scaleMaximum
        w[.armament]! *= 0.4 + 1.6 * depth

        armourAffordance = 0.4 + mineral * 1.6 + productivity
        speedAffordance = 0.5 + (openness / Tuning.Pressure.scaleMaximum) * 1.5
        crypsisAffordance = 0.5 + (1 - openness / Tuning.Pressure.scaleMaximum) * 1.5
        aposematismAffordance = 0.2 + productivity * 1.4

        free.clampToRanges()
        axisWeights = w
        self.free = free
    }
}

/// Where the free axes sit before a species is drawn. Shifted by pressures, never bought.
struct FreeAxisTendencies: Equatable, Sendable {
    var build: Double = 50
    var buildSpread: Double = 16
    var reachWeights: [Reach: Double] = [.close: 1, .mid: 1, .far: 0.5]
    var deliveryWeights: [Delivery: Double] = [.single: 3, .multi: 1, .area: 0.4]
    var appendageCount: Double = 4
    var appendageTypeWeights: [AppendageType: Double] = [
        .limbed: 2.4, .finned: 0.3, .membrane: 0.3, .feathered: 0.3, .none: 0.5
    ]
    var sensory = Sensory.allocation(vision: 45, mechano: 25, chemo: 20, thermo: 10)
    /// Which corner of the weapon triangle this world tends toward, before a species varies from it.
    var weaponMix = WeaponMix()
    var colorationDepth: Double = 50
    var patterning: Double = 22
    var shineBias: Double = 0
    var schillerBias: Double = 0
    var emanationAllowed: Bool = false
    var emanationChance: Double = 0
    var emanationStrength: Double = 0
    var emanationLight: Double = 60
    var emanationHeat: Double = 20
    var emanationCaustic: Double = 20
    /// How dark this world reads. What crypsis matches itself to.
    var ambientDepth: Double = 50

    mutating func clampToRanges() {
        build = min(100, max(0, build))
        colorationDepth = min(100, max(0, colorationDepth))
        patterning = min(100, max(0, patterning))
        appendageCount = min(8, max(0, appendageCount))
    }
}

extension Sensory {
    static func allocation(vision: Double, mechano: Double, chemo: Double, thermo: Double) -> Sensory {
        var s = Sensory()
        s.vision = vision
        s.mechano = mechano
        s.chemo = chemo
        s.thermo = thermo
        s.normalise()
        return s
    }
}
