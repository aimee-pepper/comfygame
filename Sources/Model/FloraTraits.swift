import Foundation

/// What grows in a world, as numbers rather than as a name.
///
/// **The same model as `CreatureTraits`, deliberately** (`flora-system-spec.md` §4): a world's
/// pressures produce weights over trait axes and a budget scaled by Vitality, each species is made
/// by spending that budget, and identity is read off the result afterwards. Two systems with one
/// mechanism, so a player who has learned to read animals can already read plants.
///
/// **What flora does that creatures don't** (§1), and only the last of the four overlaps:
///  1. **It is terrain.** Flora writes `growth`, which is the cover that makes ambush real.
///  2. **It is harvestable** — the non-mineral half of the material economy.
///  3. **It can be hostile** — a hazard you walk into rather than one that comes to you.
///  4. **It gates life.** Trophic depth needs a base; a world with no producers supports nothing.
struct FloraTraits: Codable, Equatable, Sendable {

    // MARK: Costly — these spend the world's budget

    /// groundcover (0) → shrub (50) → canopy (100). **The dominant cost**, and the axis that decides
    /// whether what grows here blocks a sightline.
    var stature: Double = 0
    /// **How much of it there is.** One axis, not three.
    ///
    /// The same lesson armament taught: charging woody, fibrous and fleshy separately would hand
    /// tissue three of every world's five draws and produce canopy trees made of nothing. *How much*
    /// a plant has invested in being made of something is a single decision; **which corner of the
    /// triangle** it spends that in is free, and comes from `mix`.
    var tissue = Tissue()
    /// What it has invested in not being eaten. Costly, because defence is never free.
    var defence: Double = 0

    // MARK: Free — shaped by pressures, paid for by nobody

    /// Thorns, poison, or it actually moves. Meaningless below `Tuning.Flora.defendedThreshold`.
    var defenceType: DefenceType = .physical
    /// How it arranges itself on the ground, and therefore how `growth` is patterned.
    var habit: Habit = .clustered
    var coloration = Coloration()
    var finish = Finish()

    // MARK: Chosen, not blended

    /// **How it makes a living**, and the axis that decides whether a world can live at all.
    var metabolism: Metabolism = .photosynthetic

    /// What this cost the world to grow. Same superlinear curve the allocator spends against.
    var appetite: Double { FloraCost.totalCost(of: self) }

    /// Whether it is defended enough to be worth walking around.
    var isDefended: Bool { defence >= Tuning.Flora.defendedThreshold }

    /// **Whether it stands up when you touch it.** Rare on purpose (§6): a world where the
    /// undergrowth attacks you is a world you remember, and it shouldn't be common.
    var isPredatory: Bool {
        defenceType == .active && defence >= Tuning.Flora.activeDefenceThreshold
    }

    /// Whether growing here breaks a sightline. **Groundcover shouldn't hide anything; canopy
    /// should** (§5) — the [PROPOSAL] made real, as two ground types rather than one type with a
    /// hidden property (§9.5).
    var blocksSight: Bool { stature >= Tuning.Flora.sightBlockingStature }

    init() {}

    /// Tolerant decoding, per the policy in `Migrations.swift`. Flora is saved inside a run; a field
    /// added here must never quarantine somebody's world.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        stature = try c.decodeIfPresent(Double.self, forKey: .stature) ?? 0
        tissue = try c.decodeIfPresent(Tissue.self, forKey: .tissue) ?? Tissue()
        defence = try c.decodeIfPresent(Double.self, forKey: .defence) ?? 0
        defenceType = try c.decodeIfPresent(DefenceType.self, forKey: .defenceType) ?? .physical
        habit = try c.decodeIfPresent(Habit.self, forKey: .habit) ?? .clustered
        coloration = try c.decodeIfPresent(Coloration.self, forKey: .coloration) ?? Coloration()
        finish = try c.decodeIfPresent(Finish.self, forKey: .finish) ?? Finish()
        metabolism = try c.decodeIfPresent(Metabolism.self, forKey: .metabolism) ?? .photosynthetic
    }
}

// MARK: - Metabolism

/// **How a living thing here makes a living.**
///
/// The newest idea in the flora spec and the one carrying the most (§9.1), because it is the whole
/// reason a lightless world can be anything other than dead. A world's flora draws its metabolism
/// from what is actually available: **a lightless world with volatile substrate grows chemosynthetic
/// things and is not barren**, which is the interesting case and was previously impossible.
enum Metabolism: String, Codable, CaseIterable, Equatable, Sendable {
    /// The default. Needs light, and scales with it.
    case photosynthetic
    /// Decay, moisture, and a tolerance for the dark. **Lets dark worlds have life.**
    case fungal
    /// Volatile substrate. **Lets dark, dead, mineral worlds have life.**
    case chemosynthetic

    var displayName: String {
        switch self {
        case .photosynthetic: "photosynthetic"
        case .fungal: "fungal"
        case .chemosynthetic: "chemosynthetic"
        }
    }

    /// What a world with this at its base is doing, as a plural clause — the preview says *they*,
    /// because it is talking about however many kinds a world settled on.
    var blurb: String {
        switch self {
        case .photosynthetic: "grow toward the light"
        case .fungal: "feed on what has already died"
        case .chemosynthetic: "eat the rock itself"
        }
    }

    /// The same clause for a world that settled on exactly one thing.
    var singularBlurb: String {
        switch self {
        case .photosynthetic: "grows toward the light"
        case .fungal: "feeds on what has already died"
        case .chemosynthetic: "eats the rock itself"
        }
    }
}

// MARK: - Tissue

/// The material triangle: **woody is structure, fibrous is tensile, fleshy is storage** (§2).
///
/// Split like `Armament`: a single costly total, divided by a free mix. The dominant corner is what
/// the plant is made of, and therefore what you get for cutting it down.
struct Tissue: Codable, Equatable, Sendable {
    var woody: Double = 0
    var fibrous: Double = 0
    var fleshy: Double = 0

    /// Proportions before any budget is spent, set by the world's pressures.
    var mix = TissueMix()

    var total: Double { woody + fibrous + fleshy }

    /// Which corner it sits in. Decides what it yields, the same way `Armament.dominant` decides
    /// whether a creature leaves a fang or a tusk.
    var dominant: TissueKind {
        if woody >= fibrous && woody >= fleshy { return .woody }
        if fibrous >= fleshy { return .fibrous }
        return .fleshy
    }

    /// Spends a total across the corners in this species' own proportions.
    mutating func setTotal(_ value: Double) {
        let sum = max(0.0001, mix.woody + mix.fibrous + mix.fleshy)
        woody = value * mix.woody / sum
        fibrous = value * mix.fibrous / sum
        fleshy = value * mix.fleshy / sum
    }

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        woody = try c.decodeIfPresent(Double.self, forKey: .woody) ?? 0
        fibrous = try c.decodeIfPresent(Double.self, forKey: .fibrous) ?? 0
        fleshy = try c.decodeIfPresent(Double.self, forKey: .fleshy) ?? 0
        mix = try c.decodeIfPresent(TissueMix.self, forKey: .mix) ?? TissueMix()
    }
}

/// The proportions of the tissue triangle, before any budget is spent in it.
struct TissueMix: Codable, Equatable, Sendable {
    var woody: Double = 1
    var fibrous: Double = 1
    var fleshy: Double = 1

    init() {}
    init(woody: Double, fibrous: Double, fleshy: Double) {
        self.woody = woody
        self.fibrous = fibrous
        self.fleshy = fleshy
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        woody = try c.decodeIfPresent(Double.self, forKey: .woody) ?? 1
        fibrous = try c.decodeIfPresent(Double.self, forKey: .fibrous) ?? 1
        fleshy = try c.decodeIfPresent(Double.self, forKey: .fleshy) ?? 1
    }
}

enum TissueKind: String, Codable, CaseIterable, Equatable, Sendable {
    case woody, fibrous, fleshy
}

// MARK: - Free axes

/// **How defended flora fights back** (§6). Three different experiences of the same tile.
enum DefenceType: String, Codable, CaseIterable, Equatable, Sendable {
    /// Thorns. Entering the tile costs you, once, immediately.
    case physical
    /// Toxic. Entering leaves something in you that keeps costing for a few turns.
    case chemical
    /// **It moves.** Standing in it starts a fight.
    case active

    var displayName: String {
        switch self {
        case .physical: "thorned"
        case .chemical: "toxic"
        case .active: "predatory"
        }
    }
}

/// How it arranges itself, and therefore **how `growth` is patterned** (§5).
enum Habit: String, Codable, CaseIterable, Equatable, Sendable {
    /// Large connected swathes.
    case spreading
    /// Thickets with gaps between them.
    case clustered
    /// Scattered single tiles.
    case solitary

    /// How many tiles one patch of this runs to, before the density budget stops it.
    var patchLength: Int {
        switch self {
        case .spreading: Tuning.Flora.spreadingPatchLength
        case .clustered: Tuning.Flora.clusteredPatchLength
        case .solitary: 1
        }
    }
}

// MARK: - A species

/// One kind of plant a world settled on.
///
/// The parallel of `Species`, and kept separate rather than generalised: a plant has no sensory
/// allocation and an animal has no metabolism, and a shared supertype would be a struct of optionals
/// pretending to be a model.
///
/// **Deterministic in the world's seed**, so an anchored world keeps what grows in it exactly as it
/// keeps its animals.
struct Flora: Codable, Equatable, Identifiable, Sendable {
    var id: InstanceID
    var traits: FloraTraits
    /// Which world it belongs to, so an anchored world keeps its flora forever.
    var worldSeed: UInt64

    /// Read off the traits, never stored. See `FloraIdentity`.
    func identity(in context: FloraIdentity.Context = .none) -> FloraIdentity.Match {
        FloraIdentity.match(traits, in: context)
    }
    var identity: FloraIdentity.Match { identity() }
    var displayName: String { identity.name }

    init(id: InstanceID, traits: FloraTraits, worldSeed: UInt64) {
        self.id = id
        self.traits = traits
        self.worldSeed = worldSeed
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(InstanceID.self, forKey: .id)
        traits = try c.decodeIfPresent(FloraTraits.self, forKey: .traits) ?? FloraTraits()
        worldSeed = try c.decodeIfPresent(UInt64.self, forKey: .worldSeed) ?? 0
    }
}

// MARK: - Costly axes

/// The axes a world's growing budget is spent on. Everything else about a plant is free.
enum FloraAxis: String, CaseIterable, Codable, Equatable, Sendable {
    case stature
    case tissue
    case defence
}

extension FloraTraits {
    subscript(axis: FloraAxis) -> Double {
        get {
            switch axis {
            case .stature: stature
            case .tissue: tissue.total
            case .defence: defence
            }
        }
        set {
            switch axis {
            case .stature: stature = newValue
            case .tissue: tissue.setTotal(newValue)
            case .defence: defence = newValue
            }
        }
    }
}

/// What each point of each axis costs the world.
///
/// Superlinear, exactly as `LifeCost` is, so extremes are bought late and dearly. **Stature raises
/// the price of tissue**, which is the plant version of the square–cube law: holding yourself up
/// against gravity costs more the taller you get, and it is why a canopy is expensive and a mat is
/// not.
enum FloraCost {
    static func price(of axis: FloraAxis, at value: Double, stature: Double) -> Double {
        let normalised = max(0, value) / Tuning.Pressure.scaleMaximum
        let base = pow(normalised, Tuning.Flora.costExponent) * Tuning.Flora.axisCost(axis)
        return base * statureCoupling(for: axis, stature: stature)
    }

    /// What it costs to raise one axis, given everything the plant already is. Priced off the whole
    /// vector so spend telescopes exactly to `totalCost` — the same reason `LifeCost` does it.
    static func marginal(_ axis: FloraAxis, to newValue: Double, in traits: FloraTraits) -> Double {
        var after = traits
        after[axis] = newValue
        return totalCost(of: after) - totalCost(of: traits)
    }

    static func totalCost(of traits: FloraTraits) -> Double {
        FloraAxis.allCases.reduce(0) { $0 + price(of: $1, at: traits[$1], stature: traits.stature) }
    }

    /// Height makes tissue dearer. Nothing else scales with it.
    private static func statureCoupling(for axis: FloraAxis, stature: Double) -> Double {
        switch axis {
        case .tissue:
            1 + (stature / Tuning.Pressure.scaleMaximum) * Tuning.Flora.statureCostCoupling
        default:
            1
        }
    }
}
