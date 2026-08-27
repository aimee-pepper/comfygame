import Foundation

/// What an animal actually is, as numbers rather than as a name.
///
/// **Identity is derived, never imposed** (decisions-session-15 §4, creature-system-spec §6). Traits
/// are produced by spending a world's energy budget across the axes its pressures favour, and what
/// the creature *is* — ambusher, tank, grazer — is read off the result afterwards. Deciding roles in
/// advance would smuggle Earth's ecology into worlds that were never meant to have it: not every
/// world has grazers, and if nothing grows, nothing grazes.
///
/// The stored record is always the vector. Identity definitions, combat derivation and the loot
/// table can then all change without breaking a single save — the same rule the bestiary relies on.
///
/// **Costly axes spend budget; free axes don't** (spec §2). That split is the whole mechanism: a
/// world pushing both size and armour cannot have both maxed, so every species is a different answer
/// to the same constrained problem. Shape, colour and sensory allocation cost nothing, so even a
/// starving world produces animals that look like themselves.
struct CreatureTraits: Codable, Equatable, Sendable {

    // MARK: Costly — these spend the world's budget

    /// The dominant cost, and it raises the price of covering and bone on top of its own.
    var size: Double = 0
    var covering = Covering()
    var boneDensity: Double = 0
    var armament = Armament()
    /// What it spends on looking expensive. A costly signal — only affordable in rich worlds.
    var ornament: Double = 0

    // MARK: Free — shaped by pressures, paid for by nobody

    /// sinuous (0) → sleek (50) → bulky (100). Shape, not investment.
    var build: Double = 50
    /// The axial body layout. Kept independent from appendages so a serpent may have wings and a
    /// quadruped may have fins without either being flattened into a generic `winged` body.
    var bodyPlan: CreatureBodyPlan = .quadruped
    /// A small but identity-bearing head silhouette. This is morphology, not ornament value:
    /// long ears remain long ears whether the animal is plain or extravagantly coloured.
    var cranialFeature: CranialFeature = .none
    var appendages = Appendages()
    var coloration = Coloration()
    var finish = Finish()
    var sensory = Sensory()
    /// Makes its own light. Rare, and gated by pressures rather than bought.
    var emanation: Emanation?

    // MARK: Chosen, not blended

    /// **One** answer to predation, never a mixture (spec §3). Blending is what produces mush.
    var defence: DefenceBranch?
    /// Set by the aposematism branch. Warning colours are honest — attacking it costs you.
    var isToxic: Bool = false

    /// What this cost the world to build. The same superlinear curve the allocator spends against,
    /// so "appetite" and "what was actually spent" can never drift apart.
    var appetite: Double { LifeCost.totalCost(of: self) }

    init() {}

    /// Tolerant decoding, per the policy in `Migrations.swift`. A trait vector is saved inside a
    /// run; a field added here must never quarantine somebody's world.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        size = try c.decodeIfPresent(Double.self, forKey: .size) ?? 0
        covering = try c.decodeIfPresent(Covering.self, forKey: .covering) ?? Covering()
        boneDensity = try c.decodeIfPresent(Double.self, forKey: .boneDensity) ?? 0
        armament = try c.decodeIfPresent(Armament.self, forKey: .armament) ?? Armament()
        ornament = try c.decodeIfPresent(Double.self, forKey: .ornament) ?? 0
        build = try c.decodeIfPresent(Double.self, forKey: .build) ?? 50
        bodyPlan = try c.decodeIfPresent(CreatureBodyPlan.self, forKey: .bodyPlan) ?? .quadruped
        cranialFeature = try c.decodeIfPresent(CranialFeature.self, forKey: .cranialFeature) ?? .none
        appendages = try c.decodeIfPresent(Appendages.self, forKey: .appendages) ?? Appendages()
        coloration = try c.decodeIfPresent(Coloration.self, forKey: .coloration) ?? Coloration()
        finish = try c.decodeIfPresent(Finish.self, forKey: .finish) ?? Finish()
        sensory = try c.decodeIfPresent(Sensory.self, forKey: .sensory) ?? Sensory()
        emanation = try c.decodeIfPresent(Emanation.self, forKey: .emanation)
        defence = try c.decodeIfPresent(DefenceBranch.self, forKey: .defence)
        isToxic = try c.decodeIfPresent(Bool.self, forKey: .isToxic) ?? false
    }
}

/// Axial body identity. Flight is deliberately not a body plan: wings are appendages, which keeps
/// combinations such as a winged serpent or a membrane-winged quadruped representable.
enum CreatureBodyPlan: String, Codable, Equatable, Sendable, CaseIterable {
    case quadruped, biped, serpentine, segmented, radial, piscine, amorphous
}

/// Coarse head features that remain legible in the 16-pixel map identity.
enum CranialFeature: String, Codable, Equatable, Sendable, CaseIterable {
    case none, longEars, horns, crest, sensoryFan
}

// MARK: - Covering

/// Three axes rather than one, because they buy different things: hardness is armour, length is
/// insulation and quills, coverage is how much of the animal any of it actually reaches. A bare
/// plated ridge and a full pelt are both "covered" and play nothing alike.
struct Covering: Codable, Equatable, Sendable {
    /// Soft ↔ hard. Biomineralisation lives here.
    var hardness: Double = 0
    /// Close-cropped ↔ long. Insulation and quills.
    var length: Double = 0
    /// Bare ↔ dense.
    var coverage: Double = 0

    /// Armour is only armour where it covers something.
    var armourValue: Double { hardness * coverage / 100 }
    /// Warmth is length that actually reaches round the animal.
    var insulation: Double { length * coverage / 100 }

    init() {}
    init(hardness: Double, length: Double, coverage: Double) {
        self.hardness = hardness
        self.length = length
        self.coverage = coverage
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        hardness = try c.decodeIfPresent(Double.self, forKey: .hardness) ?? 0
        length = try c.decodeIfPresent(Double.self, forKey: .length) ?? 0
        coverage = try c.decodeIfPresent(Double.self, forKey: .coverage) ?? 0
    }
}

// MARK: - Armament

/// The weapon triangle. All three low means unarmed, which is a real and common answer — most
/// things in most worlds are not trying to hurt you.
struct Armament: Codable, Equatable, Sendable {
    var pierce: Double = 0
    var crush: Double = 0
    var rend: Double = 0
    var reach: Reach = .close
    var delivery: Delivery = .single

    var total: Double { pierce + crush + rend }
    var isUnarmed: Bool { total < Tuning.Life.unarmedThreshold }

    /// Which corner it sits in. Decides the damage type, and therefore how the fight goes.
    var dominant: DamageKind {
        if pierce >= crush && pierce >= rend { return .pierce }
        if crush >= rend { return .crush }
        return .rend
    }

    /// How the three corners divide whatever was spent on weapons. Set by pressures at sampling;
    /// re-spending keeps the same mix, so buying more armament sharpens what it already had rather
    /// than turning a biter into a crusher halfway through being made.
    var mix = WeaponMix()

    /// Spends a total across the corners in the species' own proportions.
    mutating func setTotal(_ value: Double) {
        let sum = max(0.0001, mix.pierce + mix.crush + mix.rend)
        pierce = value * mix.pierce / sum
        crush = value * mix.crush / sum
        rend = value * mix.rend / sum
    }

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        pierce = try c.decodeIfPresent(Double.self, forKey: .pierce) ?? 0
        crush = try c.decodeIfPresent(Double.self, forKey: .crush) ?? 0
        rend = try c.decodeIfPresent(Double.self, forKey: .rend) ?? 0
        reach = try c.decodeIfPresent(Reach.self, forKey: .reach) ?? .close
        delivery = try c.decodeIfPresent(Delivery.self, forKey: .delivery) ?? .single
        mix = try c.decodeIfPresent(WeaponMix.self, forKey: .mix) ?? WeaponMix()
    }
}

/// The proportions of the weapon triangle, before any budget is spent in it.
struct WeaponMix: Codable, Equatable, Sendable {
    var pierce: Double = 1
    var crush: Double = 1
    var rend: Double = 1

    init() {}
    init(pierce: Double, crush: Double, rend: Double) {
        self.pierce = pierce
        self.crush = crush
        self.rend = rend
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        pierce = try c.decodeIfPresent(Double.self, forKey: .pierce) ?? 1
        crush = try c.decodeIfPresent(Double.self, forKey: .crush) ?? 1
        rend = try c.decodeIfPresent(Double.self, forKey: .rend) ?? 1
    }
}

/// How far off it can hit you. `far` strikes first on engagement regardless of initiative.
enum Reach: String, Codable, Equatable, Sendable, CaseIterable {
    case close, mid, far
}

/// Whether it hits one of you, several, or everything.
enum Delivery: String, Codable, Equatable, Sendable, CaseIterable {
    case single, multi, area
}

/// Pierce ignores some armour · crush hits hard and slow · rend bleeds.
enum DamageKind: String, Codable, Equatable, Sendable, CaseIterable {
    case pierce, crush, rend

    var verb: String {
        switch self {
        case .pierce: "pierces"
        case .crush: "slams"
        case .rend: "tears"
        }
    }
}

// MARK: - Free axes

struct Appendages: Codable, Equatable, Sendable {
    /// 0–8.
    var count: Int = 4
    var type: AppendageType = .limbed

    init() {}
    init(count: Int, type: AppendageType) {
        self.count = count
        self.type = type
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        count = try c.decodeIfPresent(Int.self, forKey: .count) ?? 4
        type = try c.decodeIfPresent(AppendageType.self, forKey: .type) ?? .limbed
    }
}

enum AppendageType: String, Codable, Equatable, Sendable, CaseIterable {
    case none, membrane, feathered, finned, limbed
}

/// Colour, as a CMY triangle plus the two things a triangle can't say.
///
/// **Depth and patterning are separate from hue on purpose.** The spec's pressure table asks for
/// pale, dark, countershaded and maximally-contrasting colorations, and none of those are hue —
/// a normalised triangle has no room for how dark or how patterned a thing is. **[PLACEHOLDER]**
/// extension of creature-system-spec §2; logged in questions-for-design.
struct Coloration: Codable, Equatable, Sendable {
    /// The triangle. Normalised to sum 100.
    var cyan: Double = 33
    var magenta: Double = 33
    var yellow: Double = 34
    /// Pale (0) ↔ near-black (100).
    var depth: Double = 50
    /// Flat (0) ↔ banded, striped, blotched (100). What makes warning colours read as warnings.
    var patterning: Double = 20

    /// Normalises the triangle without touching depth or patterning.
    mutating func normalise() {
        let total = cyan + magenta + yellow
        guard total > 0 else { cyan = 33; magenta = 33; yellow = 34; return }
        cyan = cyan / total * 100
        magenta = magenta / total * 100
        yellow = yellow / total * 100
    }

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        cyan = try c.decodeIfPresent(Double.self, forKey: .cyan) ?? 33
        magenta = try c.decodeIfPresent(Double.self, forKey: .magenta) ?? 33
        yellow = try c.decodeIfPresent(Double.self, forKey: .yellow) ?? 34
        depth = try c.decodeIfPresent(Double.self, forKey: .depth) ?? 50
        patterning = try c.decodeIfPresent(Double.self, forKey: .patterning) ?? 20
    }
}

/// How the surface behaves in light. Opacity / shine / schiller, summing to 100.
///
/// Schiller is the layered iridescence of beetle wing-cases and fish scales — it's what turns a
/// hard covering into chitin rather than plate, so the loot table reads this directly.
struct Finish: Codable, Equatable, Sendable {
    var opacity: Double = 70
    var shine: Double = 20
    var schiller: Double = 10

    /// How expensive the surface *looks*. Ornament buys this; the loot table sells it as lustre.
    var lustre: Double { shine + schiller }

    mutating func normalise() {
        let total = opacity + shine + schiller
        guard total > 0 else { opacity = 70; shine = 20; schiller = 10; return }
        opacity = opacity / total * 100
        shine = shine / total * 100
        schiller = schiller / total * 100
    }

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        opacity = try c.decodeIfPresent(Double.self, forKey: .opacity) ?? 70
        shine = try c.decodeIfPresent(Double.self, forKey: .shine) ?? 20
        schiller = try c.decodeIfPresent(Double.self, forKey: .schiller) ?? 10
    }
}

/// **An allocation, not an amount** (spec §2). These sum to 100, so a creature that sees badly
/// necessarily senses something else well — which is what makes a blind world's animals feel like
/// an adaptation rather than a deficiency.
struct Sensory: Codable, Equatable, Sendable {
    var vision: Double = 45
    /// Touch, vibration, pressure. What a thing in the dark hunts with.
    var mechano: Double = 25
    /// Smell and taste.
    var chemo: Double = 20
    /// Heat. Finds a warm body in a cold world.
    var thermo: Double = 10

    /// Everything that isn't eyes. Darkness costs a creature nothing if this is where it lives.
    var nonVisual: Double { mechano + chemo + thermo }

    mutating func normalise() {
        let total = vision + mechano + chemo + thermo
        guard total > 0 else { vision = 45; mechano = 25; chemo = 20; thermo = 10; return }
        vision = vision / total * 100
        mechano = mechano / total * 100
        chemo = chemo / total * 100
        thermo = thermo / total * 100
    }

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        vision = try c.decodeIfPresent(Double.self, forKey: .vision) ?? 45
        mechano = try c.decodeIfPresent(Double.self, forKey: .mechano) ?? 25
        chemo = try c.decodeIfPresent(Double.self, forKey: .chemo) ?? 20
        thermo = try c.decodeIfPresent(Double.self, forKey: .thermo) ?? 10
    }
}

/// Light of its own. Absent on most things; an element triangle where present.
struct Emanation: Codable, Equatable, Sendable {
    /// How much of it there is, 0–100. The triangle below says what kind.
    var strength: Double = 0
    var light: Double = 60
    var heat: Double = 20
    var caustic: Double = 20

    var dominant: EmanationKind {
        if light >= heat && light >= caustic { return .light }
        if heat >= caustic { return .heat }
        return .caustic
    }

    init(strength: Double, light: Double, heat: Double, caustic: Double) {
        self.strength = strength
        self.light = light
        self.heat = heat
        self.caustic = caustic
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        strength = try c.decodeIfPresent(Double.self, forKey: .strength) ?? 0
        light = try c.decodeIfPresent(Double.self, forKey: .light) ?? 60
        heat = try c.decodeIfPresent(Double.self, forKey: .heat) ?? 20
        caustic = try c.decodeIfPresent(Double.self, forKey: .caustic) ?? 20
    }
}

enum EmanationKind: String, Codable, Equatable, Sendable, CaseIterable {
    case light, heat, caustic
}

/// The four answers to being hunted. **One per species, never blended** (spec §3).
enum DefenceBranch: String, Codable, Equatable, Sendable, CaseIterable {
    /// Hardness and coverage. Slow and expensive.
    case armour
    /// Sleek, small, bare. Cheap and fragile.
    case speed
    /// Matched to the ambient. Doesn't show on the map until it's on you.
    case crypsis
    /// Maximally contrasting, and it means it.
    case aposematism
}

// MARK: - Species

/// A species: a trait vector a world settled on, and the animals that vary around it.
///
/// **Two levels** (session 15 §1). A world holds a small **cast** of species, and every spawn is its
/// species plus small **jitter** — mostly coloration and minor form, never enough to change what it
/// is or how it fights. So you meet the same few animals repeatedly and each one is visibly its own
/// animal.
///
/// This is what the bestiary's two tiers were waiting for: the **species** is the entry, and
/// individual spawns are **specimens** under it.
struct Species: Codable, Equatable, Identifiable, Sendable {
    var id: InstanceID
    /// The centre this species varies around.
    var traits: CreatureTraits
    /// Which world it belongs to, so an anchored world keeps its cast forever.
    var worldSeed: UInt64
    /// Frozen for newly generated ecology-aware worlds. Nil preserves legacy casts exactly.
    var habitat: CreatureHabitat?
    /// Whether it's out after dark. Derived from what it senses with, not authored.
    var isNocturnal: Bool { CreatureIdentity.isNocturnal(traits) }

    /// Read off the traits, never stored. See `CreatureIdentity`.
    ///
    /// Pass the world's cast where you have it: a name says what sets this one apart **from its own
    /// world**, so "armoured" is worth saying only where not everything is.
    func identity(in context: Naming.Context = .none) -> CreatureIdentity.Match {
        CreatureIdentity.match(traits, in: context)
    }
    var identity: CreatureIdentity.Match { identity() }
    var displayName: String { identity.name }

    init(id: InstanceID, traits: CreatureTraits, worldSeed: UInt64,
         habitat: CreatureHabitat? = nil) {
        self.id = id
        self.traits = traits
        self.worldSeed = worldSeed
        self.habitat = habitat
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(InstanceID.self, forKey: .id)
        traits = try c.decodeIfPresent(CreatureTraits.self, forKey: .traits) ?? CreatureTraits()
        worldSeed = try c.decodeIfPresent(UInt64.self, forKey: .worldSeed) ?? 0
        habitat = try c.decodeIfPresent(CreatureHabitat.self, forKey: .habitat)
    }
}
