import Foundation

/// Turning a world's pressures into the animals in it.
///
/// **Two stages** (decisions-session-15 §1): a world draws a small **cast** of species from its
/// distributions, and every spawn is its species plus small jitter. You meet the same few animals
/// repeatedly, and each one is visibly its own animal.
///
/// **Vitality sets cast *size*, not spread** (§2). A rich world holds six species where a barren one
/// holds two, but those six are no stranger — spread stays governed by the pressures that shaped the
/// distribution. Abundance and strangeness are independent knobs, which is what lets you write a
/// teeming ordinary world and a sparse bizarre one and have them be different places.
enum LifeRules {

    // MARK: The cast

    /// The species a world settled on. Deterministic in the world's seed, so an **anchored world
    /// keeps its cast forever** (§3) — the same animals live there, and you learn them.
    static func cast(for readings: PressureReadings, seed: UInt64) -> [Species] {
        var rng = SeededRNG(seed: seed).derived(0x11FE)
        let distribution = distribution(from: readings)
        let budget = WorldConstraints.energyBudget(in: readings)

        var species: [Species] = []
        var attempts = 0
        while species.count < castSize(for: readings), attempts < Tuning.Life.samplingAttempts {
            attempts += 1
            let traits = sample(distribution, rng: &rng)
            // The world has to be able to feed it. This is the only gate — nothing else is
            // rejected, because **free sampling** is the point: identity is read off afterwards.
            guard traits.appetite <= budget else { continue }
            species.append(Species(id: InstanceID(rawValue: rng.next()), traits: traits, worldSeed: seed))
        }
        // A world too poor to afford anything still holds the cheapest thing it drew. Empty for
        // reasons the player can't see is worse than sparse.
        if species.isEmpty {
            species.append(Species(id: InstanceID(rawValue: rng.next()),
                                   traits: sample(distribution, rng: &rng), worldSeed: seed))
        }
        return species
    }

    /// How many species. **Vitality, and only vitality.**
    static func castSize(for readings: PressureReadings) -> Int {
        let productivity = readings["vitality"].peak / Tuning.Pressure.scaleMaximum
        let span = Tuning.Life.castSizeRange
        return max(span.lowerBound,
                   min(span.upperBound,
                       span.lowerBound + Int((Double(span.count) * productivity).rounded())))
    }

    // MARK: A spawn

    /// One animal: its species, plus jitter. **Small on purpose** — mostly coloration and minor
    /// form, never enough to change what it is or how it fights.
    static func spawn(of species: Species, rng: inout SeededRNG) -> CreatureTraits {
        var traits = species.traits
        let jitter = Tuning.Life.jitter
        func nudge(_ value: Double, by amount: Double) -> Double {
            clamp(value + rng.double(in: -1...1) * amount)
        }
        // Appearance varies freely; anything that decides a fight barely moves.
        traits.conspicuousness = nudge(traits.conspicuousness, by: jitter * 2)
        traits.ornament = nudge(traits.ornament, by: jitter * 1.5)
        traits.size = nudge(traits.size, by: jitter)
        traits.build = nudge(traits.build, by: jitter)
        traits.covering = nudge(traits.covering, by: jitter)
        traits.reach = nudge(traits.reach, by: jitter * 0.5)
        traits.armament = nudge(traits.armament, by: jitter * 0.4)
        return traits
    }

    // MARK: Distributions

    /// A mean and a spread per axis, nudged by every pressure that has an opinion.
    ///
    /// Every shift is a **nudge, never a fixed outcome** — two worlds with the same pressures still
    /// produce different animals, and one world produces a population that varies.
    struct TraitDistribution {
        var centre = CreatureTraits()
        var spread: Double = Tuning.Life.baseSpread
    }

    static func distribution(from readings: PressureReadings) -> TraitDistribution {
        var d = TraitDistribution()
        let thermal = readings["thermal"]
        let light = readings["illumination"]
        let water = readings["hydrology"]
        let substrate = readings["substrate"]
        let relief = readings["relief"]
        let life = readings["vitality"]
        let cycle = readings["cycle"]

        // Cold: bigger, better wrapped, shorter extremities. Wet-cold favours bulk, dry-cold favours
        // covering — both are valid answers, which is why this nudges rather than decides.
        if thermal.floor < Tuning.Pressure.coldFloor {
            let cold = (Tuning.Pressure.coldFloor - thermal.floor) / 50
            d.centre.size += 18 * cold
            d.centre.reach -= 15 * cold
            if water.availableMagnitude > Tuning.Pressure.wetThreshold {
                d.centre.build += 20 * cold
            } else {
                d.centre.covering += 24 * cold
            }
        }
        // Heat: smaller, barer, longer — radiators, and pale against the sun.
        if thermal.peak > Tuning.Pressure.hotPeak {
            let heat = (thermal.peak - Tuning.Pressure.hotPeak) / 50
            d.centre.size -= 14 * heat
            d.centre.covering -= 20 * heat
            d.centre.reach += 14 * heat
        }

        // Light. Dim worlds grow eyes; dark ones give up on them entirely.
        switch light.peak {
        case ..<10:
            d.centre.vision -= 35
            d.centre.nonVisualSense += 35
            d.centre.reach += 12
        case 10..<35:
            d.centre.vision += 25
        case 75...:
            d.centre.vision += 15
            if substrate.share(of: "hard") > 0.3 { d.centre.ornament += 12 }
        default: break
        }
        // Light with no sky to come from is the bioluminescence case.
        if light.floor > 0 && !light.has("celestial") { d.centre.emanation += 45 }

        // Stone in the ground becomes stone on the animal.
        d.centre.coveringHardness += substrate.peak * 0.25
        d.centre.boneDensity += substrate.peak * 0.2
        if substrate.share(of: "volatile") > 0.3 { d.centre.emanation += 15 }

        // Open ground makes pursuers; enclosed ground makes ambushers.
        let openness = relief.aspect("openness")
        if openness > Tuning.Pressure.openTerrainThreshold {
            d.centre.build -= 15
            d.centre.reach += 12
        } else {
            d.centre.build += 10
            d.centre.conspicuousness -= 20
            d.centre.armament += 12
        }

        // A world can only afford what it can feed.
        let productivity = life.peak / Tuning.Pressure.scaleMaximum
        d.centre.size += 20 * (productivity - 0.5)
        d.centre.armament += 18 * (productivity - 0.5)
        d.centre.ornament += 25 * max(0, productivity - 0.5)

        // A world that swings breeds generalists and widens everything; a buffered one breeds
        // specialists — and fragile things.
        d.spread += (cycle.aspect("amplitude") - 40) * Tuning.Life.spreadPerAmplitude

        d.centre = clamped(d.centre)
        d.spread = max(2, d.spread)
        return d
    }

    private static func sample(_ d: TraitDistribution, rng: inout SeededRNG) -> CreatureTraits {
        var t = d.centre
        func draw(_ mean: Double) -> Double { clamp(mean + rng.double(in: -1...1) * d.spread) }
        t.size = draw(t.size)
        t.build = draw(t.build)
        t.covering = draw(t.covering)
        t.coveringHardness = draw(t.coveringHardness)
        t.boneDensity = draw(t.boneDensity)
        t.reach = draw(t.reach)
        t.armament = draw(t.armament)
        t.conspicuousness = draw(t.conspicuousness)
        t.ornament = draw(t.ornament)
        t.vision = draw(t.vision)
        t.nonVisualSense = draw(t.nonVisualSense)
        t.emanation = draw(t.emanation)
        return t
    }

    private static func clamp(_ v: Double) -> Double { min(100, max(0, v)) }

    private static func clamped(_ t: CreatureTraits) -> CreatureTraits {
        var t = t
        t.size = clamp(t.size); t.build = clamp(t.build); t.covering = clamp(t.covering)
        t.coveringHardness = clamp(t.coveringHardness); t.boneDensity = clamp(t.boneDensity)
        t.reach = clamp(t.reach); t.armament = clamp(t.armament)
        t.conspicuousness = clamp(t.conspicuousness); t.ornament = clamp(t.ornament)
        t.vision = clamp(t.vision); t.nonVisualSense = clamp(t.nonVisualSense)
        t.emanation = clamp(t.emanation)
        return t
    }
}
