import Foundation

/// A combatant's fighting numbers, **resolved and stored** rather than looked up.
///
/// Locked principle from decisions-log session 3: *saves store resolved facts, not pointers into
/// regenerable content.* A foe carries how it fights, so a force-quit mid-round resumes to the same
/// fight even if the content that spawned it has changed underneath — which it will, once creatures
/// are generated from trait vectors rather than authored.
struct CombatStats: Codable, Equatable, Sendable {
    var displayName: String
    var icon: String
    var maxHP: Int
    var attack: Int
    /// Soaks damage. `covering.hardness × covering.coverage` — armour that reaches none of the
    /// animal protects none of it.
    var armour: Int = 0
    /// Which corner of the weapon triangle it fights from. Pierce ignores some armour, crush hits
    /// hard and slow, rend bleeds.
    var damageKind: DamageKind = .crush
    /// Whether it hits one of you, several, or everything.
    var delivery: Delivery = .single
    /// Decides the turn order. Sleek, small and lightly built goes first.
    var initiative: Int = 0
    /// 0–1. Chance an attack simply misses it.
    var evasion: Double = 0
    /// Warning colours are honest: hitting it in melee costs you this much.
    var retaliation: Int = 0
    /// Far reach strikes first on engagement regardless of initiative.
    var strikesFirst: Bool = false
    /// Non-nil where it carries its own light, heat or venom.
    var element: EmanationKind?

    init(displayName: String, icon: String, maxHP: Int, attack: Int, armour: Int = 0,
         damageKind: DamageKind = .crush, delivery: Delivery = .single, initiative: Int = 0,
         evasion: Double = 0, retaliation: Int = 0, strikesFirst: Bool = false,
         element: EmanationKind? = nil) {
        self.displayName = displayName
        self.icon = icon
        self.maxHP = maxHP
        self.attack = attack
        self.armour = armour
        self.damageKind = damageKind
        self.delivery = delivery
        self.initiative = initiative
        self.evasion = evasion
        self.retaliation = retaliation
        self.strikesFirst = strikesFirst
        self.element = element
    }

    /// Tolerant decoding, per the policy in `Migrations.swift`. These are saved mid-encounter, which
    /// is the hardest resume case in the game — a new stat must never cost somebody their fight.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        displayName = try c.decodeIfPresent(String.self, forKey: .displayName) ?? "Something"
        icon = try c.decodeIfPresent(String.self, forKey: .icon) ?? "questionmark"
        maxHP = try c.decodeIfPresent(Int.self, forKey: .maxHP) ?? 1
        attack = try c.decodeIfPresent(Int.self, forKey: .attack) ?? 1
        armour = try c.decodeIfPresent(Int.self, forKey: .armour) ?? 0
        damageKind = try c.decodeIfPresent(DamageKind.self, forKey: .damageKind) ?? .crush
        delivery = try c.decodeIfPresent(Delivery.self, forKey: .delivery) ?? .single
        initiative = try c.decodeIfPresent(Int.self, forKey: .initiative) ?? 0
        evasion = try c.decodeIfPresent(Double.self, forKey: .evasion) ?? 0
        retaliation = try c.decodeIfPresent(Int.self, forKey: .retaliation) ?? 0
        strikesFirst = try c.decodeIfPresent(Bool.self, forKey: .strikesFirst) ?? false
        element = try c.decodeIfPresent(EmanationKind.self, forKey: .element)
    }

    /// **How a creature fights, read off what it is** (creature-system-spec §7). This is what makes
    /// a bulky armoured ambusher play differently from a swift fragile pursuer, which was not true
    /// of anything while every creature carried a flat stat block.
    static func derived(from traits: CreatureTraits, name: String, icon: String) -> CombatStats {
        let t = Tuning.Encounter.self
        let bulk = max(0, traits.build - 50) / 50           // 0 at sleek, 1 at fully bulky

        let hp = t.baseFoeHP
            + traits.size * t.hpPerSize
            + bulk * t.hpPerBulk
            + traits.boneDensity * t.hpPerBone

        // A big animal hits harder with the same weapons. An unarmed one still has mass.
        let attack = t.baseFoeAttack
            + traits.armament.total * t.attackPerArmament
            + traits.size * t.attackPerSize

        // Light, sleek and lightly armoured moves first — and is the thing that dodges.
        let initiative = t.baseInitiative
            - traits.size * t.initiativePerSize
            - traits.boneDensity * t.initiativePerBone
            - traits.covering.coverage * t.initiativePerCoverage
            + (50 - abs(traits.build - Tuning.Life.sleekBuild)) * t.initiativePerSleekness

        let evasion = max(0, min(t.maximumEvasion,
                                 (50 - abs(traits.build - Tuning.Life.sleekBuild)) * t.evasionPerSleekness
                                 - traits.size * t.evasionPerSize))

        return CombatStats(
            displayName: name,
            icon: icon,
            maxHP: max(1, Int(hp.rounded())),
            attack: max(0, Int(attack.rounded())),
            armour: Int((traits.covering.armourValue * t.armourPerCovering).rounded()),
            // **An unarmed animal has no weapon corner.** It still has mass and it will barge into
            // you, but a grazer with nothing to tear you with must not leave a rending wound —
            // `dominant` always names a corner, so the unarmed case has to be caught here.
            damageKind: traits.armament.isUnarmed ? .crush : traits.armament.dominant,
            delivery: traits.armament.delivery,
            initiative: Int(initiative.rounded()),
            evasion: evasion,
            retaliation: traits.isToxic ? max(1, Int((traits.size * t.retaliationPerSize).rounded())) : 0,
            // Length beats speed at the moment of contact, and so does not being seen coming.
            strikesFirst: traits.armament.reach == .far || traits.defence == .crypsis,
            element: traits.emanation.map(\.dominant)
        )
    }

    /// The old authored creatures, kept as the fallback for a world bound before the cast existed.
    static func resolved(from creature: CreatureDef) -> CombatStats {
        CombatStats(displayName: creature.name, icon: creature.icon, maxHP: creature.maxHP, attack: creature.attack)
    }
}

/// Who is acting. The party is fixed at two in v0; `foe` carries an id because foes come and go.
enum Combatant: Codable, Equatable, Hashable, Sendable {
    case binder
    case companion
    case foe(InstanceID)

    var isParty: Bool { self == .binder || self == .companion }
    var foeID: InstanceID? { if case .foe(let id) = self { id } else { nil } }
}

/// What a combatant can do on their turn. `Skill` is one each, per the brief.
enum CombatAction: Codable, Equatable, Sendable {
    case attack(foe: InstanceID)
    case damageSkill(foe: InstanceID)
    case healSkill(ally: Combatant)
    case useItem(stack: InstanceID, ally: Combatant)
    /// Always succeeds, and costs the run stability. The escape hatch, not a gamble.
    case flee
}

struct FoeState: Codable, Equatable, Identifiable, Sendable {
    var id: InstanceID
    /// An authored creature. **Legacy**, and nil for anything a world grew itself.
    var creatureID: CreatureID?
    /// Which bestiary entry this belongs under. Derived from the traits at spawn and stored, so a
    /// later change to the identity regions can't rename a creature mid-fight.
    var identityKey: String = "unknown"
    /// What it is. Kept for the bestiary and for loot — *not* re-read to work out how it fights,
    /// which was resolved once into `stats`.
    var traits: CreatureTraits?
    /// How it fights, resolved at spawn. See `CombatStats`.
    var stats: CombatStats
    var currentHP: Int
    /// The adjective this creature went by, resolved with its world's cast at spawn. Materials
    /// inherit it: a pelt off a *shaggy browser* is a *shaggy pelt*.
    var qualifier: String?
    /// Rounds of bleeding left. Rend's wound outlives the blow.
    ///
    /// Nothing the party carries rends yet, so today this is only set when creatures fight each
    /// other — which is `living-worlds-spec.md`, not yet built. The ticker handles it either way so
    /// that landing predation doesn't need to touch the encounter loop.
    var bleedRounds: Int = 0

    var isAlive: Bool { currentHP > 0 }
    var maxHP: Int { stats.maxHP }

    /// **What it's wearing, in one word.** The read that turns the damage-type matchup into a
    /// decision rather than a guess (combat-depth-spec §6.3): plate and shell want pierce or crush,
    /// a pelt wants rend. Nil where it isn't wearing enough to matter.
    var coveringWord: String? {
        guard let traits, traits.covering.coverage > Tuning.Materials.minimumCoverageToYield
        else { return nil }
        switch ButcheryRules.coveringMaterial(of: traits) {
        case .plate: return "plated"
        case .chitin: return "shelled"
        case .quill: return "quilled"
        case .pelt: return "furred"
        case .down: return "downy"
        default: return traits.covering.armourValue > 30 ? "hidebound" : nil
        }
    }

    init(id: InstanceID, creatureID: CreatureID? = nil, identityKey: String = "unknown",
         traits: CreatureTraits? = nil, stats: CombatStats, currentHP: Int,
         qualifier: String? = nil, bleedRounds: Int = 0) {
        self.id = id
        self.creatureID = creatureID
        self.identityKey = identityKey
        self.traits = traits
        self.stats = stats
        self.currentHP = currentHP
        self.qualifier = qualifier
        self.bleedRounds = bleedRounds
    }

    /// Tolerant decoding — this is the mid-encounter resume case the acceptance criteria name.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(InstanceID.self, forKey: .id)
        creatureID = try c.decodeIfPresent(CreatureID.self, forKey: .creatureID)
        identityKey = try c.decodeIfPresent(String.self, forKey: .identityKey)
            ?? creatureID?.rawValue ?? "unknown"
        traits = try c.decodeIfPresent(CreatureTraits.self, forKey: .traits)
        stats = try c.decode(CombatStats.self, forKey: .stats)
        currentHP = try c.decodeIfPresent(Int.self, forKey: .currentHP) ?? 1
        qualifier = try c.decodeIfPresent(String.self, forKey: .qualifier)
        bleedRounds = try c.decodeIfPresent(Int.self, forKey: .bleedRounds) ?? 0
    }
}

/// A fight in progress. Saved in full — being mid-encounter is the hardest resume case in the game,
/// and the one the acceptance criteria call out by name.
struct EncounterState: Codable, Equatable, Sendable {
    var id: InstanceID
    var foes: [FoeState]

    /// Resolved from initiative at the start of the fight, and **stored** rather than recomputed so
    /// that a foe dying mid-round can't shift whose turn it is.
    var order: [Combatant]
    var turnIndex: Int = 0
    var roundNumber: Int = 1

    /// Rounds until each side's skill comes back. Counted in *rounds*, never seconds.
    var binderSkillCooldown: Int = 0
    var companionSkillCooldown: Int = 0

    /// Set by tapping the companion: their next turn is yours to direct instead of the gambits'.
    /// Clears once used — an override is for that turn only (the FF12 rule).
    var isCompanionOverridden: Bool = false

    /// Non-nil once the fight is over and waiting to be dismissed.
    var outcome: EncounterOutcome?

    /// Rounds of bleeding left on each of you. Rend's wound outlives the blow, which is what makes
    /// a rending creature worth fleeing rather than trading with.
    var binderBleedRounds: Int = 0
    var companionBleedRounds: Int = 0

    /// Rolling battle log shown above the action bar.
    var log: [String] = []

    /// What you won, in plain words, shown on the victory screen.
    ///
    /// Rolled the moment the fight is won rather than when it's dismissed — otherwise the payout
    /// lands after the screen that should be reporting it, which reads as "nothing dropped".
    var spoils: [String] = []

    var livingFoes: [FoeState] { foes.filter(\.isAlive) }
    var isResolved: Bool { foes.allSatisfy { !$0.isAlive } }
    var current: Combatant { order.isEmpty ? .binder : order[turnIndex % order.count] }

    mutating func note(_ line: String) {
        log.append(line)
        if log.count > 24 { log.removeFirst(log.count - 24) }
    }

    init(id: InstanceID, foes: [FoeState], order: [Combatant], log: [String] = []) {
        self.id = id
        self.foes = foes
        self.order = order
        self.log = log
    }

    /// Tolerant decoding, per the policy in `Migrations.swift`.
    ///
    /// **This one had synthesised `Codable` until a bleed counter was added to it**, which is the
    /// same shape as the bug that quarantined a real save on a real device: a field added here has
    /// no key in an older save, and synthesised decoding *throws* rather than defaulting. Being
    /// mid-encounter is the hardest resume case the acceptance criteria name, so it is the last
    /// place in the save that should be brittle.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(InstanceID.self, forKey: .id)
        foes = try c.decodeIfPresent([FoeState].self, forKey: .foes) ?? []
        order = try c.decodeIfPresent([Combatant].self, forKey: .order) ?? [.binder, .companion]
        turnIndex = try c.decodeIfPresent(Int.self, forKey: .turnIndex) ?? 0
        roundNumber = try c.decodeIfPresent(Int.self, forKey: .roundNumber) ?? 1
        binderSkillCooldown = try c.decodeIfPresent(Int.self, forKey: .binderSkillCooldown) ?? 0
        companionSkillCooldown = try c.decodeIfPresent(Int.self, forKey: .companionSkillCooldown) ?? 0
        isCompanionOverridden = try c.decodeIfPresent(Bool.self, forKey: .isCompanionOverridden) ?? false
        outcome = try c.decodeIfPresent(EncounterOutcome.self, forKey: .outcome)
        binderBleedRounds = try c.decodeIfPresent(Int.self, forKey: .binderBleedRounds) ?? 0
        companionBleedRounds = try c.decodeIfPresent(Int.self, forKey: .companionBleedRounds) ?? 0
        log = try c.decodeIfPresent([String].self, forKey: .log) ?? []
        spoils = try c.decodeIfPresent([String].self, forKey: .spoils) ?? []
    }
}

enum EncounterOutcome: String, Codable, Equatable, Sendable {
    case victory
    case fled
    /// Party down. No death state in v0 — you're carried home with a partial haul.
    case defeated
}
