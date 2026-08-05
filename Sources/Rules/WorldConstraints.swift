import Foundation

/// The cross-target constraints, and the energy budget.
///
/// The design docs call these **the teeth**, and they're load-bearing rather than polish: without
/// them every world produces everything-creatures — huge, armoured, insulated, ornamented, in a
/// world that couldn't feed a rabbit. Authored explicitly here rather than hoped for.
///
/// Applied as a pass *after* resolution, in a fixed order, because several of them feed each other.
/// The order is a decision, not an accident, and it's written down below.
enum WorldConstraints {

    /// Runs the constraints over freshly resolved pressures.
    ///
    /// Order: air conditions heat → heat decides what form water can take → water and light
    /// together cap life. Each step only reads what the steps before it settled, so there's no
    /// circularity to resolve and no iteration to converge.
    static func apply(to readings: PressureReadings) -> PressureReadings {
        var result = readings
        applyAtmosphereToThermal(&result)
        applyThermalToHydrology(&result)
        applyLifeCaps(&result)
        return result
    }

    // MARK: 1. Air conditions heat

    /// Thick air holds heat and narrows the swing; thin air holds nothing and widens it. Dense
    /// atmosphere as a heat retainer lives here rather than as its own source rune.
    private static func applyAtmosphereToThermal(_ readings: inout PressureReadings) {
        let air = readings["atmosphere"]
        guard var thermal = readings.readings["thermal"] else { return }

        let density = air.peak - (ContentCatalog.shared.pressureTarget("atmosphere")?.baseline ?? 50)
        let pull = density * Tuning.Pressure.atmosphereThermalRetention

        // Thick air pulls peak and floor together; thin air pushes them apart.
        thermal.peak = clamp(thermal.peak - pull)
        thermal.floor = clamp(thermal.floor + pull)
        if thermal.floor > thermal.peak {
            let midpoint = (thermal.peak + thermal.floor) / 2
            thermal.peak = midpoint
            thermal.floor = midpoint
        }
        if density < 0 { thermal.tags.insert("arid-swing") }
        if density > 0 { thermal.tags.insert("thermally-buffered") }
        readings.readings["thermal"] = thermal
    }

    // MARK: 2. Heat decides what form water takes

    /// Write "Sea" on a frozen world and you get a glacier whether you asked for one or not. The
    /// simulation correcting your description is the behaviour the fiction wants — you describe a
    /// world, you don't dictate to it.
    private static func applyThermalToHydrology(_ readings: inout PressureReadings) {
        let thermal = readings["thermal"]
        guard var water = readings.readings["hydrology"], !water.forms.isEmpty else { return }

        var forms = water.forms
        if thermal.floor < Tuning.Pressure.freezingFloor {
            // Standing water freezes first; flowing water resists longer.
            move(&forms, from: "standing", to: "frozen", fraction: 1.0)
            move(&forms, from: "flowing", to: "frozen", fraction: 0.5)
            water.tags.insert("frozen-over")
        }
        if thermal.peak > Tuning.Pressure.evaporatingPeak {
            move(&forms, from: "standing", to: "airborne", fraction: 0.6)
            water.tags.insert("evaporating")
        }
        water.forms = forms
        readings.readings["hydrology"] = water
    }

    private static func move(_ forms: inout [String: Double], from: String, to: String, fraction: Double) {
        let amount = (forms[from] ?? 0) * fraction
        guard amount > 0 else { return }
        forms[from] = (forms[from] ?? 0) - amount
        forms[to] = (forms[to] ?? 0) + amount
    }

    // MARK: 3. Water and light cap life

    /// Dry caps life. Dark caps life *unless* something is eating rather than photosynthesising —
    /// which is exactly the interesting case, and why the fungal exemption is worth having.
    private static func applyLifeCaps(_ readings: inout PressureReadings) {
        let water = readings["hydrology"]
        let light = readings["illumination"]
        guard var life = readings.readings["vitality"] else { return }

        // Frozen water is water the world can't use.
        let waterCap = water.availableMagnitude * Tuning.Pressure.vitalityPerWater
        var caps = [waterCap]

        let feedsInTheDark = life.has("fungal") || life.has("decaying")
        if !feedsInTheDark {
            caps.append(light.peak * Tuning.Pressure.vitalityPerLight)
        }

        if let cap = caps.min(), life.peak > cap {
            life.peak = cap
            life.floor = cap
            life.tags.insert(waterCap <= (caps.min() ?? 0) ? "water-limited" : "light-limited")
        }
        if life.peak < Tuning.Pressure.barrenThreshold { life.tags.insert("barren") }
        readings.readings["vitality"] = life
    }

    private static func clamp(_ value: Double) -> Double {
        min(Tuning.Pressure.scaleMaximum, max(0, value))
    }

    // MARK: - The energy budget

    /// One budget, drawn on by size, armour, insulation, weapons and ornament alike.
    ///
    /// This single mechanic reproduces the square-cube law, the defence-versus-mobility trade and
    /// costly signalling all at once, and it is what guarantees no world produces an
    /// everything-creature: a rich world can afford a large armoured thing *or* a gaudy fast one,
    /// and a poor world can afford neither.
    static func energyBudget(in readings: PressureReadings) -> Double {
        let life = readings["vitality"]
        return life.peak * Tuning.Pressure.budgetPerProductivity
    }

    /// The ceiling on how big anything gets. Cold and poor together is the hard case: insulation
    /// and bulk both cost, and a world that can't feed them doesn't get them.
    static func maximumCreatureSize(in readings: PressureReadings) -> Double {
        let budget = energyBudget(in: readings)
        let thermal = readings["thermal"]
        // Insulation is bought out of the same purse, so cold worlds have less left for size.
        let insulationCost = max(0, Tuning.Pressure.comfortableFloor - thermal.floor)
            * Tuning.Pressure.insulationCostPerDegree
        return max(0, budget - insulationCost)
    }

    // MARK: - Reading a world's character

    /// The qualitative facts the docs call for, derived rather than authored — what a world is
    /// *like*, in the terms the creature generator will eventually ask in.
    static func character(of readings: PressureReadings) -> Set<String> {
        var traits: Set<String> = []
        let light = readings["illumination"]
        let thermal = readings["thermal"]
        let water = readings["hydrology"]
        let relief = readings["relief"]
        let substrate = readings["substrate"]

        // Openness sets the ambush↔pursuit axis, which then constrains build, reach and crypsis.
        traits.insert(relief.aspect("openness") >= Tuning.Pressure.openTerrainThreshold ? "pursuit" : "ambush")

        // Cold has four co-valid answers, and the *other* targets pick between them: fur fails when
        // it's wet, so wet-cold favours fat and bulk while dry-cold favours covering.
        if thermal.floor < Tuning.Pressure.coldFloor {
            traits.insert(water.availableMagnitude > Tuning.Pressure.wetThreshold ? "wet-cold" : "dry-cold")
            traits.insert(water.share(of: "frozen") > 0.3 ? "white-biasing" : "dark-biasing")
        }
        if thermal.peak > Tuning.Pressure.hotPeak {
            traits.insert(water.availableMagnitude < Tuning.Pressure.aridThreshold ? "arid-syndrome" : "humid-heat")
        }

        // Iridescence needs light to signal in *and* something hard and layered to refract it.
        if light.peak > Tuning.Pressure.iridescenceLight, substrate.share(of: "hard") > 0.3 {
            traits.insert("iridescence-enabled")
        }
        // Bioluminescence is overwhelmingly a dark-environment adaptation.
        if light.has("sourceless") || light.peak < Tuning.Pressure.aphoticPeak {
            traits.insert("emanation-favoured")
        }
        if light.floor < 5, light.range > Tuning.Pressure.wideRangeThreshold {
            traits.insert("two-niches") // a diurnal and a nocturnal population in one world
        }
        return traits
    }
}
