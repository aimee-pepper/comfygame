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

/// Who is acting.
///
/// **The companion carries a durable party identity**, because roster order is presentation.
/// and this was the type that made that impossible: with one nameless `.companion` there was exactly
/// one slot in the turn order, one place to keep HP, and one rule list to run, so choosing four
/// people at the fire could only ever have been a lie.
///
/// `foe` carries an id for the same reason — things come and go and have to stay distinguishable.
enum Combatant: Codable, Equatable, Hashable, Sendable {
    case binder
    case companion(PersistentPartyMemberID)
    case foe(InstanceID)

    var isParty: Bool {
        switch self {
        case .binder, .companion: true
        case .foe: false
        }
    }

    var foeID: InstanceID? { if case .foe(let id) = self { id } else { nil } }
    /// Which of the roster this is, if it's one of yours.
    var persistentPartyMemberID: PersistentPartyMemberID? {
        if case .companion(let id) = self { id } else { nil }
    }

    /// Who this is on the Party screen — the same person, asked about outside a fight.
    var member: PartyMember {
        switch self {
        case .binder: .binder
        case .companion(let id): .member(id)
        case .foe: .binder
        }
    }

    /// A stable string for dictionary keys inside the encounter — cooldowns, wards, turn debts.
    var storageKey: String {
        switch self {
        case .binder: "binder"
        case .companion(let id): "party-\(id.rawValue)"
        case .foe(let id): "foe-\(id.rawValue)"
        }
    }
}

/// What a combatant can do on their turn.
enum CombatAction: Codable, Equatable, Sendable {
    case attack(foe: InstanceID)
    /// **A named skill.** Twelve of them now, so which one is part of the action rather than
    /// something inferred from the single skill a member used to own.
    case skill(SkillID, foe: InstanceID? = nil, ally: Combatant? = nil)
    /// Modern Ward always carries the exact disclosed harm selected at quote time. Keeping this
    /// separate preserves the encoded shape of legacy `.skill("ward")` actions.
    case ward(Harm)
    /// Canonical Quench carries both the exact ally and the saved affliction application receipt.
    case quench(ally: Combatant, afflictionReceipt: UInt64)
    /// Blur has no legacy SkillDef row. Its stable combat-tree node is the complete action identity.
    case blur
    /// The two the gambit vocabulary still speaks in: "use your damage skill", "use your heal".
    /// Resolved against whatever the member actually carries.
    case damageSkill(foe: InstanceID)
    case healSkill(ally: Combatant)
    case useItem(stack: InstanceID, ally: Combatant, afflictionReceipt: UInt64? = nil)
    /// Always succeeds, and costs the run stability. The escape hatch, not a gamble.
    case flee
}

struct FoeState: Codable, Equatable, Identifiable, Sendable {
    var id: InstanceID
    /// Exact generated-species identity copied from the map specimen at encounter creation.
    var speciesID: InstanceID?
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
    /// **What the world raised it to** (session 17 §3). Scaled with the party, and further in
    /// worlds that are unstable or greedy — so the risk already priced into those two shows up as
    /// difficulty rather than only as hazard frequency.
    var level: Int = 1
    /// The adjective this creature went by, resolved with its world's cast at spawn. Materials
    /// inherit it: a pelt off a *shaggy browser* is a *shaggy pelt*.
    var qualifier: String?
    /// **Something the world couldn't afford** (`apex-encounters.md`). Carried into the fight so the
    /// spoils know to pay out the thing you can't make, and so the encounter can say what this is.
    var isApex: Bool = false
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

    init(id: InstanceID, speciesID: InstanceID? = nil,
         creatureID: CreatureID? = nil, identityKey: String = "unknown",
         traits: CreatureTraits? = nil, stats: CombatStats, currentHP: Int,
         qualifier: String? = nil, bleedRounds: Int = 0, level: Int = 1,
         isApex: Bool = false) {
        self.id = id
        self.speciesID = speciesID
        self.creatureID = creatureID
        self.identityKey = identityKey
        self.traits = traits
        self.stats = stats
        self.currentHP = currentHP
        self.qualifier = qualifier
        self.isApex = isApex
        self.bleedRounds = bleedRounds
        self.level = level
    }

    /// Tolerant decoding — this is the mid-encounter resume case the acceptance criteria name.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(InstanceID.self, forKey: .id)
        speciesID = try c.decodeIfPresent(InstanceID.self, forKey: .speciesID)
        creatureID = try c.decodeIfPresent(CreatureID.self, forKey: .creatureID)
        identityKey = try c.decodeIfPresent(String.self, forKey: .identityKey)
            ?? creatureID?.rawValue ?? "unknown"
        traits = try c.decodeIfPresent(CreatureTraits.self, forKey: .traits)
        stats = try c.decode(CombatStats.self, forKey: .stats)
        currentHP = try c.decodeIfPresent(Int.self, forKey: .currentHP) ?? 1
        qualifier = try c.decodeIfPresent(String.self, forKey: .qualifier)
        isApex = try c.decodeIfPresent(Bool.self, forKey: .isApex) ?? false
        bleedRounds = try c.decodeIfPresent(Int.self, forKey: .bleedRounds) ?? 0
        level = try c.decodeIfPresent(Int.self, forKey: .level) ?? 1
    }
}

/// A fight in progress. Saved in full — being mid-encounter is the hardest resume case in the game,
/// and the one the acceptance criteria call out by name.
struct EncounterState: Codable, Equatable, Sendable {
    struct AnimalCombatParticipantReceiptV1: Codable, Equatable, Sendable {
        static let version = 1
        var version = Self.version
        var animalID: TamedAnimalID
        var memberID: PersistentPartyMemberID
        var frozenDisplayName: String
        var level: Int
        var scaledStats: CombatStats
        var reach: Reach
        var availableActionIDs: [String]
        var dominantTechnique: AnimalDominantTechniqueV1
        var gambits: [GambitRule]
        var gambitSlotCount: Int
        var commitStrengthMultiplier: Double
        var originReceipt: AnimalCombatOriginReceiptV1

        func validates(companion: TamedAnimalCompanionStateV1) -> Bool {
            version == Self.version && animalID == companion.id
                && memberID == .animal(animalID.rawValue)
                && frozenDisplayName == companion.originReceipt.frozenDisplayName
                && level == companion.level
                && scaledStats == AnimalCompanionCombatRules.scaledStats(companion)
                && reach == companion.originReceipt.reach
                && availableActionIDs == [AnimalCompanionCombatRules.instinctiveActionID,
                                          companion.originReceipt.dominantTechnique.rawValue]
                && dominantTechnique == companion.originReceipt.dominantTechnique
                && gambits == companion.gambits && gambitSlotCount >= 1
                && commitStrengthMultiplier.isFinite && commitStrengthMultiplier > 0
                && originReceipt == companion.originReceipt
        }
    }
    struct DebugGodModeReceipt: Codable, Equatable, Sendable {
        static let schemaVersion = 1
        var version = schemaVersion
        var preventedLethalDamageCount = 0
    }
    enum PersonalExpansionSource: String, Codable, Equatable, Sendable {
        case quicken, blur, legacy
    }

    struct PersonalTurnReceipt: Codable, Equatable, Sendable {
        var owner: Combatant
        var setupAvailable = true
        var normalCreditsRemaining = 1
        var expansionSource: PersonalExpansionSource?
    }
    struct DebugV2InitiativeReceipt: Codable, Equatable, Sendable {
        struct Component: Codable, Equatable, Sendable {
            var nodeID: CombatNodeID
            var amount: Int
        }
        struct Entry: Codable, Equatable, Sendable {
            var actor: Combatant
            var baseline: Int
            var components: [Component]
            var total: Int
            var strikesFirst: Bool
            var finalPosition: Int?
        }
        var entries: [Entry]

        func entry(for actor: Combatant) -> Entry? { entries.first { $0.actor == actor } }
    }

    struct DebugV2BinderAttackReceipt: Codable, Equatable, Sendable {
        static let schemaVersion = 1
        var version = schemaVersion
        var ordinaryWeaponKind: DamageKind?
        var crushBonus: CombatDerivedStatsRules.PreMatchupAttackBonus
        var pierceBonus: CombatDerivedStatsRules.PreMatchupAttackBonus

        func preMatchupBonus(for kind: DamageKind?) -> CombatDerivedStatsRules.PreMatchupAttackBonus {
            switch kind {
            case .crush: crushBonus
            case .pierce: pierceBonus
            case .rend, nil: .init(components: [])
            }
        }
    }
    struct DirectHitComponent: Codable, Equatable, Sendable {
        var nodeID: CombatNodeID
        var amount: Int
    }
    struct DebugV2ArmourReceipt: Codable, Equatable, Sendable {
        struct Entry: Codable, Equatable, Sendable {
            var actor: Combatant
            var equipmentProtectivePower: Double
            var sturdiness: Double
            var ownedNodeIDs: Set<CombatNodeID>
            var entryRank: Rank
        }
        var entries: [Entry]

        func entry(for actor: Combatant) -> Entry? { entries.first { $0.actor == actor } }
    }
    struct DebugV2EvasionReceipt: Codable, Equatable, Sendable {
        struct Component: Codable, Equatable, Sendable {
            var nodeID: CombatNodeID
            var amount: Double
        }
        struct Entry: Codable, Equatable, Sendable {
            var actor: Combatant
            var characterEvasion: Double
            var components: [Component]
            /// Optional for tolerant decoding of encounters frozen before these consumers existed.
            var ownsFeint: Bool? = nil
            var ownsUntouchable: Bool? = nil
            var total: Double { min(0.85, characterEvasion + components.reduce(0) { $0 + $1.amount }) }
        }
        var entries: [Entry]
        func entry(for actor: Combatant) -> Entry? { entries.first { $0.actor == actor } }
    }
    struct DebugV2ResistanceReceipt: Codable, Equatable, Sendable {
        struct Entry: Codable, Equatable, Sendable {
            var actor: Combatant
            /// Nil is an explicit enabled-v2 counterfactual, including missing/unknown choices.
            var insulationChoice: EmanationKind?
        }
        var entries: [Entry]
        func entry(for actor: Combatant) -> Entry? { entries.first { $0.actor == actor } }
    }
    struct EvasionAttempt: Codable, Equatable, Sendable {
        enum Resolution: String, Codable, Equatable, Sendable {
            case sidestep, ghost, probabilityHit, probabilityMiss
            var playerLabel: String {
                switch self {
                case .probabilityHit: "Hit"
                case .probabilityMiss: "Missed"
                case .sidestep: "Sidestepped"
                case .ghost: "Avoided with Ghost"
                }
            }
        }
        var actor: Combatant
        var characterEvasion: Double
        var components: [DebugV2EvasionReceipt.Component]
        var finalChance: Double
        var roll: Double?
        var resolution: Resolution
        var missed: Bool
    }
    struct UntouchableState: Codable, Equatable, Sendable {
        var percentagePoints: Int = 0
        var targetedDirectCount: Int = 0
        var landedDirectCount: Int = 0
    }
    struct PendingStagger: Codable, Equatable, Sendable {
        var foeID: InstanceID
        var applyingRound: Int
        var sourceActors: Set<Combatant>
        var sourceNodeIDs: Set<CombatNodeID>
        var automatic: Bool
    }
    struct StaggerAttempt: Codable, Equatable, Sendable {
        var actor: Combatant
        var foeID: InstanceID
        var roll: Double?
        var succeeded: Bool
        var automatic: Bool
        var applyingRound: Int?
        var merged: Bool
    }
    enum FoeDamageProvenance: String, Codable, Equatable, Sendable {
        case direct, killingStroke, carried, affliction, environment
    }
    struct DefeatTransition: Codable, Equatable, Sendable {
        var receipt: UInt64
        var foeID: InstanceID
        var sourceActor: Combatant?
        var provenance: FoeDamageProvenance
        var damage: Int
        var sourceNodeID: CombatNodeID?
    }

    struct CarriedDamageEvent: Codable, Equatable, Sendable {
        var receipt: UInt64
        var sourceActor: Combatant
        var sourceNodeID: CombatNodeID
        var primaryFoeID: InstanceID
        var secondaryFoeID: InstanceID
        var primaryActualLoss: Int
        var damage: Int
        var copiedAfflictionReceipt: UInt64?
    }
    /// The saved fact of how contact began. Combat consumers read this instead of reconstructing
    /// an opening from post-contact enemy awareness or map visibility.
    enum Opening: Codable, Equatable, Sendable {
        case partyApproach
        case mutualContact
        case creatureAmbush
        case scripted(scriptID: String, overridesWatchful: Bool,
                      allowsPartyOpeningAttack: Bool)
    }

    struct OpeningResolution: Codable, Equatable, Sendable {
        /// Whether the triggering creature was actually present in the pre-action map presentation.
        var preContactDisclosed: Bool
        /// What contact was before any learned protection acted.
        var initial: Opening
        /// Slippery is one saved comparison, not an encounter-occurrence reroll.
        var slipperyProbability: Double?
        var slipperyRoll: Double?
        var slipperyPrevented: Bool
        /// Watchful preserves the ambush classification but removes its forced foe actions.
        var watchfulSuppressedOpening: Bool
        var resolved: Opening
        /// Stored relative foe order still owed before ordinary initiative begins.
        var pendingFoeActions: [InstanceID]

        init(preContactDisclosed: Bool, initial: Opening,
             slipperyProbability: Double?, slipperyRoll: Double?, slipperyPrevented: Bool,
             watchfulSuppressedOpening: Bool, resolved: Opening,
             pendingFoeActions: [InstanceID]) {
            self.preContactDisclosed = preContactDisclosed
            self.initial = initial
            self.slipperyProbability = slipperyProbability
            self.slipperyRoll = slipperyRoll
            self.slipperyPrevented = slipperyPrevented
            self.watchfulSuppressedOpening = watchfulSuppressedOpening
            self.resolved = resolved
            self.pendingFoeActions = pendingFoeActions
        }

        /// Additive opening evidence must not quarantine a mid-fight save. Unknown enum cases are
        /// handled by EncounterState as an absent/legacy opening, which conservatively forbids
        /// opening-only player actions.
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            preContactDisclosed = try c.decodeIfPresent(Bool.self, forKey: .preContactDisclosed) ?? false
            initial = try c.decodeIfPresent(Opening.self, forKey: .initial) ?? .mutualContact
            slipperyProbability = try c.decodeIfPresent(Double.self, forKey: .slipperyProbability)
            slipperyRoll = try c.decodeIfPresent(Double.self, forKey: .slipperyRoll)
            slipperyPrevented = try c.decodeIfPresent(Bool.self, forKey: .slipperyPrevented) ?? false
            watchfulSuppressedOpening = try c.decodeIfPresent(Bool.self,
                                                               forKey: .watchfulSuppressedOpening) ?? false
            resolved = try c.decodeIfPresent(Opening.self, forKey: .resolved) ?? initial
            pendingFoeActions = try c.decodeIfPresent([InstanceID].self,
                                                       forKey: .pendingFoeActions) ?? []
        }
    }

    struct TurnSlot: Codable, Equatable, Sendable {
        enum Kind: Codable, Equatable, Sendable {
            case primary
            case apexFollowUp(Int)
            /// Saved 55% single-target, affliction-free pressure action for an ordinary foe.
            case ordinaryPressureFollowUp(Int)
        }
        var actor: Combatant
        var kind: Kind = .primary
        var strengthMultiplier: Double = 1
        var suppressesAfflictions = false
    }
    struct EncounterPressureOwnerReceiptV1: Codable, Equatable, Sendable {
        static let currentVersion = 1
        struct Entry: Codable, Equatable, Sendable {
            var ordinal: Int
            var foeID: InstanceID
        }
        var version = currentVersion
        var entries: [Entry]
    }
    var id: InstanceID
    var foes: [FoeState]
    /// **What everyone in the party is called**, resolved when the fight starts and kept.
    ///
    /// The same rule the foes follow: a save stores resolved facts, not pointers into content that
    /// can change underneath it. It also means the log doesn't need the roster passed into every
    /// function that writes a line, which is what made a party of five awkward to name.
    var partyNames: [PersistentPartyMemberID: String] = [:]
    /// Frozen exact-animal combat truth. Nil is legacy; modern encounters use an authoritative map.
    var animalParticipants: [Combatant: AnimalCombatParticipantReceiptV1]? = nil
    /// Frozen exact-human loadouts. Animals remain owned solely by `animalParticipants`.
    var gearProjections: [Combatant: GearLoadoutProjectionV1]? = nil
    /// Frozen DEBUG comparison inputs/results. Existing encounters decode without it.
    var scalingPreview: EncounterScalingRules.Preview?
    /// Non-nil only when DEBUG God mode was enabled as this encounter opened. Persisted so
    /// relaunch, the banner, and bug evidence all retain the same frozen testing truth.
    var debugGodMode: DebugGodModeReceipt?
    /// Binder-only DEBUG harness receipt. It is frozen at encounter entry and never inferred from
    /// legacy branch depth. Release encounters and old saves have no receipt.
    var debugV2BinderAttack: DebugV2BinderAttackReceipt?
    /// Exact DEBUG initiative inputs and the final tie-broken position frozen at contact.
    var debugV2Initiative: DebugV2InitiativeReceipt?
    /// Frozen equipment, sturdiness and explicit DEBUG-v2 ownership. Formation rank and
    /// consciousness remain encounter-owned dynamic facts.
    var debugV2Armour: DebugV2ArmourReceipt?
    /// Frozen personal evasion plus exact Footwork ownership for the DEBUG-v2 route.
    var debugV2Evasion: DebugV2EvasionReceipt?
    /// Frozen typed Insulation ownership. Nil is legacy; an enabled empty/counterfactual route has
    /// entries whose choices are nil and never silently defaults to Heat.
    var debugV2Resistance: DebugV2ResistanceReceipt?
    /// Explicit frozen ownership for consumers that do not yet have a dedicated derived receipt.
    /// Nil is legacy; an empty dictionary is an enabled-v2 comparison with no owned nodes.
    var debugV2OwnedNodeIDs: [Combatant: Set<CombatNodeID>]?
    /// Nil is a frozen legacy encounter. A nonnil empty map is modern and must never infer a harm.
    var wardReceipts: [Combatant: WardReceipt]?
    /// Saved rank at each actor's previous completed normal-cost action. Nil is legacy; an empty
    /// modern receipt is deliberately distinct and never reconstructed from mutable Base state.
    var rankAtPreviousCompletedAction: [Combatant: Rank]?
    /// Current formation rank belongs to this encounter. Fall Back mutates this saved receipt,
    /// never the mutable Base loadout under an already-open fight.
    var partyRanks: [Combatant: Rank] = [:]
    var opening: OpeningResolution?
    /// Ordinary actions completed by each actor. Opening foe actions and zero-turn opening attacks
    /// do not enter this set.
    var completedFirstActions: Set<Combatant> = []
    /// One saved receipt per actor for free opening attacks such as Ambush.
    var openingAttackConsumed: Set<Combatant> = []

    /// Resolved from initiative at the start of the fight, and **stored** rather than recomputed so
    /// that a foe dying mid-round can't shift whose turn it is.
    var order: [Combatant]
    /// Exact resolved round schedule. `order` remains as a tolerant compatibility mirror.
    var turnSlots: [TurnSlot] = []
    /// Immutable ordinal-to-ordinary-foe authority. Dynamic effects may move slots, never rewrite it.
    var pressureOwners: EncounterPressureOwnerReceiptV1?
    /// Targets already chosen by each apex this round, for distinct-target follow-up preference.
    var apexTargetsThisRound: [InstanceID: [Combatant]] = [:]
    var turnIndex: Int = 0
    var roundNumber: Int = 1
    var pendingStaggers: [InstanceID: PendingStagger] = [:]
    var staggerAttempts: [StaggerAttempt] = []
    /// Exact actors whose automatic Breaking Blow Stagger has been spent in the current scheduled
    /// personal-turn window. Nil is a legacy encounter; modern enabled-v2 encounters persist even
    /// an empty set so relaunch never invents a second use.
    var breakingBlowScheduledSpent: Set<Combatant>?
    /// Ambush and any later explicitly classified opening strike use a separate one-shot window.
    /// It never borrows from or consumes the actor's first scheduled personal turn.
    var breakingBlowOpeningSpent: Set<Combatant>?
    /// Bounded, persisted first-zero evidence. Consequences drain synchronously; retaining the
    /// transition makes relaunch/debug reporting truthful without making it replayable.
    var defeatTransitions: [DefeatTransition] = []
    var nextDefeatTransitionReceipt: UInt64 = 1
    /// Saved encounter-only Cascade gains per exact actor, capped at three.
    var cascadeStacks: [Combatant: Int] = [:]
    /// Bounded terminal consequence evidence. These events never re-enter the direct-hit pipeline.
    var carriedDamageEvents: [CarriedDamageEvent] = []
    var nextCarriedDamageReceipt: UInt64 = 1

    /// Rounds until each side's skill comes back. Counted in *rounds*, never seconds.
    ///
    /// **Legacy**: one skill each, one cooldown each. Kept so a save written mid-fight before the
    /// party had more than two skills between them still loads and still resumes correctly.
    var binderSkillCooldown: Int = 0
    var companionSkillCooldown: Int = 0

    /// Rounds until each *individual* skill comes back, keyed `owner|skill`. Per skill, because
    /// twelve skills sharing one timer would mean picking the best one and never seeing the rest.
    var cooldowns: [String: Int] = [:]

    /// **Wounds that keep opening**, per foe. Rend's own trick, now available to you (Flense).
    var foeBleeds: [InstanceID: BleedState] = [:]
    /// What each of you is currently turning aside, and for how long (Ward).
    var wards: [Combatant: WardState] = [:]
    /// Foes that have to come for the Binder instead of choosing, and for how many rounds
    /// (Draw Off). The only way to take a hit meant for somebody else.
    var taunts: [InstanceID: Int] = [:]
    struct DrawOffReceipt: Codable, Equatable, Sendable {
        var owner: Combatant
        var activationRound: Int
        var expiresBeforeRound: Int
    }
    /// Nil is the legacy Binder-only duration adapter; modern receipts name the exact owner.
    var drawOffReceipts: [InstanceID: DrawOffReceipt]?
    /// Foes whose traits you've actually looked at (Sight). Nothing else reveals a covering.
    var revealed: Set<InstanceID> = []
    /// Species absent from the bestiary when this fight began. World encounter setup records a
    /// sighting before the first gambit can run, so this snapshot preserves the meaningful
    /// "first encounter" window for Kestrel's subject.
    var initiallyUnrecordedSpecies: Set<String> = []
    /// Foes no longer giving anything off (Snuff).
    var snuffed: Set<InstanceID> = []
    /// Modern Snuff counts complete scheduled foe turns. Nil preserves the legacy permanent set.
    var snuffReceipts: [InstanceID: SnuffReceipt]?
    /// **Burns, poisons and dazzles**, per combatant. Emanation was a generated trait that reached
    /// the prose and never the fight; now it leaves something behind (Q42).
    var statuses: [Combatant: [StatusState]] = [:]
    /// Canonical exact-combatant afflictions. `nil` is a legacy encounter awaiting one-time
    /// adoption; an empty array is modern authoritative state and must never remint old mirrors.
    var afflictions: [AfflictionInstance]?
    var nextAfflictionReceipt: UInt64 = 1
    struct CorrodeReceipt: Codable, Hashable, Sendable {
        var source: Combatant
        var target: InstanceID
        var round: Int
    }
    /// Encounter-local armour loss caused by Corrode. This is a derived negative component, not a
    /// mutation of a foe's frozen stats, and therefore disappears with the encounter.
    var foeArmourErosion: [InstanceID: Int] = [:]
    /// At most one Corrode contribution from one exact source to one target in one global round.
    var corrodeReceipts: Set<CorrodeReceipt> = []
    /// One lethal-event survival receipt per exact modern-v2 owner. Nil marks a legacy encounter;
    /// an empty set is modern and unspent, so relaunch/healing cannot remint a spent charge.
    var unyieldingSpent: Set<Combatant>?
    struct BraceReceipt: Codable, Equatable, Sendable {
        var owner: Combatant
        var hostileActor: Combatant?
        var round: Int?
        var slotIndex: Int?
        var triggered = false
    }
    /// Exact next-hostile-slot receipts. Nil is legacy; modern empty is authoritative/spent.
    var braceReceipts: [Combatant: BraceReceipt]?
    /// One prepared refusal of the next affliction. Kept as a count-shaped value so a future
    /// upgrade can grant more than one without changing the save shape; Stonebark currently sets 1.
    var statusGuards: [Combatant: Int] = [:]
    /// Consumed by this combatant's next successful weapon strike, including a weapon skill.
    var preparedCoatings: [Combatant: PreparedCoating] = [:]
    /// Decode-only compatibility source. Modern v2 encounters adopt these into personal turns.
    var extraTurns: [Combatant: Int] = [:]
    /// Nil is legacy/unadopted. Modern state owns one currently scheduled personal block.
    var personalTurn: PersonalTurnReceipt?
    /// Blur is once per encounter for each exact owner. Modern empty is authoritative/unspent.
    var blurSpent: Set<Combatant>?
    /// The first normal-cost action is spent even when it misses.
    var firstNormalActionCompleted: Set<Combatant>?
    /// **What the Craft and Defense branches leave on somebody**, in rounds remaining.
    ///
    /// One shape for five effects rather than five fields: bracing softens everything, dodging eats
    /// the next blow outright, concealment takes you off the target list, interposing puts you in
    /// front of the back rank, and a coated weapon poisons what it touches.
    var braced: [Combatant: Int] = [:]
    var dodging: [Combatant: Int] = [:]
    /// One saved Ghost receipt per exact owner. `nil` means a legacy/unadopted encounter; an empty
    /// set is modern and spent, so relaunch cannot mint the guarantee again.
    var ghostEvasionAvailable: Set<Combatant>?
    /// `nil` is legacy/unadopted. Modern empty state must stay empty across relaunch.
    var feintActive: Set<Combatant>?
    var untouchableStates: [Combatant: UntouchableState]?
    /// Bounded DEBUG/bug-report evidence from the authoritative final-target miss resolver.
    var evasionAttempts: [EvasionAttempt] = []
    var concealed: [Combatant: Int] = [:]
    var interposing: [Combatant: Int] = [:]
    struct InterposeReceipt: Codable, Equatable, Sendable {
        var owner: Combatant
        /// Animal Interpose protects one exact selected ally. `nil` is retained for the existing
        /// human Protection-node receipt, whose action has no ally parameter.
        var selectedAlly: Combatant? = nil
        var activationSequence: UInt64
    }
    var interposeReceipts: [InterposeReceipt]?
    var nextInterposeActivationSequence: UInt64 = 1
    /// Ashe's consented interception of one active emanation event aimed at somebody else.
    var grounding: [Combatant: Int] = [:]
    var envenomed: [Combatant: Int] = [:]
    var skippedTurns: [Combatant: Int] = [:]
    /// First actionable turn after the last skipped-turn debt was paid.
    var recoveryComplete: Set<Combatant> = []

    /// Set by tapping the companion: their next turn is yours to direct instead of the gambits'.
    /// Clears once used — an override is for that turn only (the FF12 rule).
    var isCompanionOverridden: Bool = false
    /// Exact animal whose next actionable turn is manually directed.
    var manualOverrideOwner: Combatant? = nil
    /// Nil is legacy. Modern animal encounters keep exact-owner target-priority receipts.
    var animalSlipAwayOwners: Set<Combatant>? = nil
    var animalWarningDisplayOwners: Set<Combatant>? = nil

    /// Non-nil once the fight is over and waiting to be dismissed.
    var outcome: EncounterOutcome?
    /// Explicit once-only body-material transaction state.
    var creatureMaterialRewardResolution: CreatureMaterialRewardResolutionV1 = .pending

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
    var current: Combatant {
        if !turnSlots.isEmpty { return turnSlots[turnIndex % turnSlots.count].actor }
        return order.isEmpty ? .binder : order[turnIndex % order.count]
    }
    var currentTurnSlot: TurnSlot {
        if !turnSlots.isEmpty { return turnSlots[turnIndex % turnSlots.count] }
        return TurnSlot(actor: current)
    }

    mutating func note(_ line: String) {
        log.append(line)
        if log.count > 24 { log.removeFirst(log.count - 24) }
    }

    init(id: InstanceID, foes: [FoeState], partyNames: [PersistentPartyMemberID: String] = [:],
         order: [Combatant], turnSlots: [TurnSlot] = [],
         pressureOwners: EncounterPressureOwnerReceiptV1? = nil,
         initiallyUnrecordedSpecies: Set<String> = [],
         debugV2BinderAttack: DebugV2BinderAttackReceipt? = nil,
         debugV2Initiative: DebugV2InitiativeReceipt? = nil,
         debugV2Armour: DebugV2ArmourReceipt? = nil,
         debugV2Evasion: DebugV2EvasionReceipt? = nil,
         debugV2Resistance: DebugV2ResistanceReceipt? = nil,
         animalParticipants: [Combatant: AnimalCombatParticipantReceiptV1]? = nil,
         gearProjections: [Combatant: GearLoadoutProjectionV1]? = nil,
         ghostEvasionAvailable: Set<Combatant>? = nil,
         debugV2OwnedNodeIDs: [Combatant: Set<CombatNodeID>]? = nil,
         partyRanks: [Combatant: Rank] = [:],
         log: [String] = []) {
        self.id = id
        self.foes = foes
        self.partyNames = partyNames
        self.order = order
        self.turnSlots = turnSlots.isEmpty ? order.map { TurnSlot(actor: $0) } : turnSlots
        self.pressureOwners = pressureOwners
        self.initiallyUnrecordedSpecies = initiallyUnrecordedSpecies
        self.debugV2BinderAttack = debugV2BinderAttack
        self.debugV2Initiative = debugV2Initiative
        self.debugV2Armour = debugV2Armour
        self.debugV2Evasion = debugV2Evasion
        self.debugV2Resistance = debugV2Resistance
        self.animalParticipants = animalParticipants
        self.gearProjections = gearProjections ?? Dictionary(uniqueKeysWithValues:
            order.compactMap { actor -> (Combatant, GearLoadoutProjectionV1)? in
                if actor.foeID != nil || animalParticipants?[actor] != nil { return nil }
                let owner: PartyMember
                switch actor {
                case .binder: owner = .binder
                case .companion(let id): owner = .member(id)
                case .foe: return nil
                }
                guard case .projected(let projection) =
                        GearGameplayProjectionRulesV1.project(owner: owner, equipped: [:])
                else { return nil }
                return (actor, projection)
            })
        self.animalSlipAwayOwners = animalParticipants == nil ? nil : []
        self.animalWarningDisplayOwners = animalParticipants == nil ? nil : []
        self.debugGodMode = nil
        self.ghostEvasionAvailable = ghostEvasionAvailable
        self.debugV2OwnedNodeIDs = debugV2OwnedNodeIDs
        self.wardReceipts = debugV2OwnedNodeIDs == nil ? nil : [:]
        self.snuffReceipts = debugV2OwnedNodeIDs == nil ? nil : [:]
        self.interposeReceipts = debugV2OwnedNodeIDs == nil ? nil : []
        self.drawOffReceipts = debugV2OwnedNodeIDs == nil ? nil : [:]
        self.unyieldingSpent = debugV2OwnedNodeIDs == nil ? nil : []
        self.braceReceipts = debugV2OwnedNodeIDs == nil ? nil : [:]
        self.breakingBlowScheduledSpent = debugV2OwnedNodeIDs == nil ? nil : []
        self.breakingBlowOpeningSpent = debugV2OwnedNodeIDs == nil ? nil : []
        self.blurSpent = debugV2OwnedNodeIDs == nil ? nil : []
        self.firstNormalActionCompleted = debugV2OwnedNodeIDs == nil ? nil : []
        self.partyRanks = partyRanks
        self.rankAtPreviousCompletedAction = debugV2OwnedNodeIDs == nil ? nil : partyRanks
        self.afflictions = []
        self.log = log
        self.creatureMaterialRewardResolution = .pending
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
        partyNames = try c.decodeIfPresent([PersistentPartyMemberID: String].self,
                                            forKey: .partyNames) ?? [:]
        animalParticipants = try c.decodeIfPresent(
            [Combatant: AnimalCombatParticipantReceiptV1].self, forKey: .animalParticipants)
        gearProjections = try c.decodeIfPresent(
            [Combatant: GearLoadoutProjectionV1].self, forKey: .gearProjections)
        scalingPreview = try c.decodeIfPresent(EncounterScalingRules.Preview.self, forKey: .scalingPreview)
        debugGodMode = try c.decodeIfPresent(DebugGodModeReceipt.self, forKey: .debugGodMode)
        debugV2BinderAttack = try c.decodeIfPresent(DebugV2BinderAttackReceipt.self,
                                                     forKey: .debugV2BinderAttack)
        debugV2Initiative = try c.decodeIfPresent(DebugV2InitiativeReceipt.self,
                                                   forKey: .debugV2Initiative)
        debugV2Armour = try c.decodeIfPresent(DebugV2ArmourReceipt.self,
                                              forKey: .debugV2Armour)
        debugV2Evasion = try c.decodeIfPresent(DebugV2EvasionReceipt.self,
                                               forKey: .debugV2Evasion)
        debugV2Resistance = try c.decodeIfPresent(DebugV2ResistanceReceipt.self,
                                                  forKey: .debugV2Resistance)
        debugV2OwnedNodeIDs = try c.decodeIfPresent([Combatant: Set<CombatNodeID>].self,
                                                     forKey: .debugV2OwnedNodeIDs)
        wardReceipts = try c.decodeIfPresent([Combatant: WardReceipt].self, forKey: .wardReceipts)
            ?? (debugV2OwnedNodeIDs == nil ? nil : [:])
        partyRanks = try c.decodeIfPresent([Combatant: Rank].self, forKey: .partyRanks) ?? [:]
        rankAtPreviousCompletedAction = try c.decodeIfPresent([Combatant: Rank].self,
                                                               forKey: .rankAtPreviousCompletedAction)
        opening = try? c.decodeIfPresent(OpeningResolution.self, forKey: .opening)
        completedFirstActions = try c.decodeIfPresent(Set<Combatant>.self,
                                                       forKey: .completedFirstActions) ?? []
        openingAttackConsumed = try c.decodeIfPresent(Set<Combatant>.self,
                                                       forKey: .openingAttackConsumed) ?? []
        order = try c.decodeIfPresent([Combatant].self, forKey: .order) ?? [.binder, .companion(0)]
        turnSlots = try c.decodeIfPresent([TurnSlot].self, forKey: .turnSlots)
            ?? order.map { TurnSlot(actor: $0) }
        pressureOwners = try c.decodeIfPresent(EncounterPressureOwnerReceiptV1.self,
                                                forKey: .pressureOwners)
        apexTargetsThisRound = try c.decodeIfPresent([InstanceID: [Combatant]].self,
                                                      forKey: .apexTargetsThisRound) ?? [:]
        turnIndex = try c.decodeIfPresent(Int.self, forKey: .turnIndex) ?? 0
        roundNumber = try c.decodeIfPresent(Int.self, forKey: .roundNumber) ?? 1
        pendingStaggers = try c.decodeIfPresent([InstanceID: PendingStagger].self,
                                                forKey: .pendingStaggers) ?? [:]
        staggerAttempts = try c.decodeIfPresent([StaggerAttempt].self,
                                                forKey: .staggerAttempts) ?? []
        breakingBlowScheduledSpent = try c.decodeIfPresent(Set<Combatant>.self,
                                                            forKey: .breakingBlowScheduledSpent)
            ?? (debugV2OwnedNodeIDs == nil ? nil : [])
        breakingBlowOpeningSpent = try c.decodeIfPresent(Set<Combatant>.self,
                                                          forKey: .breakingBlowOpeningSpent)
            ?? (debugV2OwnedNodeIDs == nil ? nil : [])
        defeatTransitions = try c.decodeIfPresent([DefeatTransition].self,
                                                   forKey: .defeatTransitions) ?? []
        nextDefeatTransitionReceipt = try c.decodeIfPresent(UInt64.self,
                                                             forKey: .nextDefeatTransitionReceipt)
            ?? ((defeatTransitions.map(\.receipt).max() ?? 0) + 1)
        cascadeStacks = try c.decodeIfPresent([Combatant: Int].self,
                                               forKey: .cascadeStacks) ?? [:]
        carriedDamageEvents = try c.decodeIfPresent([CarriedDamageEvent].self,
                                                      forKey: .carriedDamageEvents) ?? []
        nextCarriedDamageReceipt = try c.decodeIfPresent(UInt64.self,
                                                          forKey: .nextCarriedDamageReceipt)
            ?? ((carriedDamageEvents.map(\.receipt).max() ?? 0) + 1)
        binderSkillCooldown = try c.decodeIfPresent(Int.self, forKey: .binderSkillCooldown) ?? 0
        companionSkillCooldown = try c.decodeIfPresent(Int.self, forKey: .companionSkillCooldown) ?? 0
        cooldowns = try c.decodeIfPresent([String: Int].self, forKey: .cooldowns) ?? [:]
        braced = try c.decodeIfPresent([Combatant: Int].self, forKey: .braced) ?? [:]
        dodging = try c.decodeIfPresent([Combatant: Int].self, forKey: .dodging) ?? [:]
        ghostEvasionAvailable = try c.decodeIfPresent(Set<Combatant>.self,
                                                       forKey: .ghostEvasionAvailable)
        feintActive = try c.decodeIfPresent(Set<Combatant>.self, forKey: .feintActive)
        untouchableStates = try c.decodeIfPresent([Combatant: UntouchableState].self,
                                                   forKey: .untouchableStates)
        evasionAttempts = try c.decodeIfPresent([EvasionAttempt].self,
                                                 forKey: .evasionAttempts) ?? []
        concealed = try c.decodeIfPresent([Combatant: Int].self, forKey: .concealed) ?? [:]
        interposing = try c.decodeIfPresent([Combatant: Int].self, forKey: .interposing) ?? [:]
        interposeReceipts = try c.decodeIfPresent([InterposeReceipt].self,
                                                   forKey: .interposeReceipts)
            ?? (debugV2OwnedNodeIDs == nil ? nil : [])
        nextInterposeActivationSequence = try c.decodeIfPresent(
            UInt64.self, forKey: .nextInterposeActivationSequence)
            ?? ((interposeReceipts?.map(\.activationSequence).max() ?? 0) + 1)
        grounding = try c.decodeIfPresent([Combatant: Int].self, forKey: .grounding) ?? [:]
        envenomed = try c.decodeIfPresent([Combatant: Int].self, forKey: .envenomed) ?? [:]
        foeBleeds = try c.decodeIfPresent([InstanceID: BleedState].self, forKey: .foeBleeds) ?? [:]
        wards = try c.decodeIfPresent([Combatant: WardState].self, forKey: .wards) ?? [:]
        taunts = try c.decodeIfPresent([InstanceID: Int].self, forKey: .taunts) ?? [:]
        drawOffReceipts = try c.decodeIfPresent([InstanceID: DrawOffReceipt].self,
                                                 forKey: .drawOffReceipts)
            ?? (debugV2OwnedNodeIDs == nil ? nil : [:])
        revealed = try c.decodeIfPresent(Set<InstanceID>.self, forKey: .revealed) ?? []
        initiallyUnrecordedSpecies = try c.decodeIfPresent(Set<String>.self,
                                                           forKey: .initiallyUnrecordedSpecies) ?? []
        snuffed = try c.decodeIfPresent(Set<InstanceID>.self, forKey: .snuffed) ?? []
        snuffReceipts = try c.decodeIfPresent([InstanceID: SnuffReceipt].self,
                                               forKey: .snuffReceipts)
            ?? (debugV2OwnedNodeIDs == nil ? nil : [:])
        statuses = try c.decodeIfPresent([Combatant: [StatusState]].self, forKey: .statuses) ?? [:]
        afflictions = try c.decodeIfPresent([AfflictionInstance].self, forKey: .afflictions)
        nextAfflictionReceipt = try c.decodeIfPresent(UInt64.self,
                                                       forKey: .nextAfflictionReceipt) ?? 1
        foeArmourErosion = try c.decodeIfPresent([InstanceID: Int].self,
                                                  forKey: .foeArmourErosion) ?? [:]
        corrodeReceipts = try c.decodeIfPresent(Set<CorrodeReceipt>.self,
                                                 forKey: .corrodeReceipts) ?? []
        unyieldingSpent = try c.decodeIfPresent(Set<Combatant>.self, forKey: .unyieldingSpent)
            ?? (debugV2OwnedNodeIDs == nil ? nil : [])
        braceReceipts = try c.decodeIfPresent([Combatant: BraceReceipt].self,
                                               forKey: .braceReceipts)
            ?? (debugV2OwnedNodeIDs == nil ? nil : [:])
        statusGuards = try c.decodeIfPresent([Combatant: Int].self, forKey: .statusGuards) ?? [:]
        preparedCoatings = try c.decodeIfPresent([Combatant: PreparedCoating].self,
                                                 forKey: .preparedCoatings) ?? [:]
        extraTurns = try c.decodeIfPresent([Combatant: Int].self, forKey: .extraTurns) ?? [:]
        personalTurn = try c.decodeIfPresent(PersonalTurnReceipt.self, forKey: .personalTurn)
        blurSpent = try c.decodeIfPresent(Set<Combatant>.self, forKey: .blurSpent)
            ?? (debugV2OwnedNodeIDs == nil ? nil : [])
        firstNormalActionCompleted = try c.decodeIfPresent(Set<Combatant>.self,
                                                            forKey: .firstNormalActionCompleted)
            ?? (debugV2OwnedNodeIDs == nil ? nil : [])
        skippedTurns = try c.decodeIfPresent([Combatant: Int].self, forKey: .skippedTurns) ?? [:]
        recoveryComplete = try c.decodeIfPresent(Set<Combatant>.self, forKey: .recoveryComplete) ?? []
        isCompanionOverridden = try c.decodeIfPresent(Bool.self, forKey: .isCompanionOverridden) ?? false
        manualOverrideOwner = try c.decodeIfPresent(Combatant.self, forKey: .manualOverrideOwner)
        if manualOverrideOwner == nil, isCompanionOverridden {
            manualOverrideOwner = order.first { if case .companion = $0 { true } else { false } }
        }
        animalSlipAwayOwners = try c.decodeIfPresent(Set<Combatant>.self,
                                                       forKey: .animalSlipAwayOwners)
        animalWarningDisplayOwners = try c.decodeIfPresent(Set<Combatant>.self,
                                                            forKey: .animalWarningDisplayOwners)
        outcome = try c.decodeIfPresent(EncounterOutcome.self, forKey: .outcome)
        if c.contains(.creatureMaterialRewardResolution) {
            guard try !c.decodeNil(forKey: .creatureMaterialRewardResolution) else {
                throw CocoaError(.coderInvalidValue)
            }
            creatureMaterialRewardResolution = try c.decode(
                CreatureMaterialRewardResolutionV1.self,
                forKey: .creatureMaterialRewardResolution)
        } else {
            throw CocoaError(.coderInvalidValue)
        }
        binderBleedRounds = try c.decodeIfPresent(Int.self, forKey: .binderBleedRounds) ?? 0
        companionBleedRounds = try c.decodeIfPresent(Int.self, forKey: .companionBleedRounds) ?? 0
        log = try c.decodeIfPresent([String].self, forKey: .log) ?? []
        spoils = try c.decodeIfPresent([String].self, forKey: .spoils) ?? []
        adoptLegacyAfflictionsIfNeeded()
    }

    mutating func adoptLegacyAfflictionsIfNeeded() {
        guard afflictions == nil else { return }
        afflictions = []
        func adopt(_ kind: AfflictionID, target: Combatant, damage: Int, ticks: Int,
                   endless: Bool = false) {
            guard ticks > 0 || endless else { return }
            let existing = afflictions?.firstIndex { $0.target == target && $0.kind == kind }
            if let existing {
                var merged = afflictions![existing]
                merged.damage = max(merged.damage, damage)
                merged.ticksRemaining = max(merged.ticksRemaining, ticks)
                merged.endless = merged.endless || endless
                afflictions![existing] = merged
            } else {
                afflictions?.append(.init(kind: kind, target: target, source: nil,
                                         provenance: .migratedUnknown, damage: damage,
                                         ticksRemaining: ticks, endless: endless,
                                         applicationReceipt: nextAfflictionReceipt))
                nextAfflictionReceipt &+= 1
            }
        }
        for (target, carried) in statuses {
            for status in carried {
                adopt(status.kind.afflictionID, target: target, damage: status.damage,
                      ticks: status.rounds)
            }
        }
        for (foeID, wound) in foeBleeds {
            adopt(.bleed, target: .foe(foeID), damage: wound.damage, ticks: wound.rounds)
        }
        for foe in foes where foe.bleedRounds > 0 {
            adopt(.bleed, target: .foe(foe.id), damage: Tuning.Encounter.bleedDamage,
                  ticks: foe.bleedRounds,
                  endless: foe.bleedRounds >= Tuning.Encounter.endlessBleedRounds)
        }
        adopt(.bleed, target: .binder, damage: Tuning.Encounter.bleedDamage,
              ticks: binderBleedRounds)
        if companionBleedRounds > 0 {
            let companions = Set(order.compactMap { actor -> Combatant? in
                if case .companion = actor { return actor }
                return nil
            })
            if companions.count == 1, let target = companions.first {
                adopt(.bleed, target: target, damage: Tuning.Encounter.bleedDamage,
                      ticks: companionBleedRounds)
            } else {
                note("A legacy shared companion wound could not be assigned safely and was cleared.")
            }
        }
        statuses = [:]
        foeBleeds = [:]
        binderBleedRounds = 0
        companionBleedRounds = 0
        for index in foes.indices { foes[index].bleedRounds = 0 }
    }
}

/// **Harm that outlives the blow.** Three of them (Aimee, 6 Aug: *"q42 is 3 for sure"*).
///
/// Three rather than one `elemental` status carrying its element, and the reason is Ward: a Ward
/// that turns aside *elemental in general* is exactly the good-against-everything shape the skill
/// rule warns against. Three gives it a real question — you watched it sear, so you ward burn.
///
/// **These three because these three have producers.** `EmanationKind` is a generated creature
/// trait with exactly three cases, and toxicity is a separate flag; burn and freeze and shock would
/// have been two effects with nothing in the game making them, which is the inverse of the bug
/// this fixes.
enum StatusKind: String, Codable, Hashable, CaseIterable, Sendable {
    /// From a **heat** emanation. Burns through armour, briefly and hard.
    case burn
    /// From a **caustic** emanation, and from anything toxic you were unwise enough to hit.
    /// Slower, longer, and armour was never going to help.
    case poison
    /// From a **light** emanation. You can't see what you're swinging at.
    case dazzle

    var displayName: String { rawValue.capitalisedSentence }

    /// What produces it, so a creature's emanation reaches the fight rather than only the prose.
    static func from(_ element: EmanationKind) -> StatusKind {
        switch element {
        case .heat: .burn
        case .caustic: .poison
        case .light: .dazzle
        }
    }

    var verb: String {
        switch self {
        case .burn: "burns"
        case .poison: "is working through"
        case .dazzle: "can't see straight"
        }
    }

    var afflictionID: AfflictionID {
        switch self {
        case .burn: .burn
        case .poison: .poison
        case .dazzle: .dazzle
        }
    }
}

enum AfflictionID: String, Codable, Hashable, CaseIterable, Sendable {
    case burn, poison, dazzle, bleed

    var legacyVerb: String {
        switch self {
        case .burn: "burns"
        case .poison: "is working through"
        case .dazzle: "can't see straight"
        case .bleed: "bleeds"
        }
    }
}

enum AfflictionFamily: String, Codable, Sendable {
    case damageOverTime, accuracy
}

enum AfflictionCureFamily: String, Codable, Hashable, Sendable {
    case clearing, quenching, broad, quench
}

struct AfflictionDefinition: Equatable, Sendable {
    let id: AfflictionID
    let displayName: String
    let glyph: String
    let family: AfflictionFamily
    let defaultDamage: Int
    let defaultTicks: Int
    let cures: Set<AfflictionCureFamily>
    let order: Int
    let allowsSeverityOverride: Bool
    let allowsDurationOverride: Bool
    let stonebarkEligible: Bool

    static let all: [AfflictionDefinition] = [
        .init(id: .burn, displayName: "Burn", glyph: "flame.fill",
              family: .damageOverTime,
              defaultDamage: Tuning.Encounter.statusDamage["burn"] ?? 4,
              defaultTicks: Tuning.Encounter.statusRounds["burn"] ?? 2,
              cures: [.quenching, .broad, .quench], order: 0,
              allowsSeverityOverride: true, allowsDurationOverride: true,
              stonebarkEligible: true),
        .init(id: .poison, displayName: "Poison", glyph: "drop.triangle.fill",
              family: .damageOverTime,
              defaultDamage: Tuning.Encounter.statusDamage["poison"] ?? 2,
              defaultTicks: Tuning.Encounter.statusRounds["poison"] ?? 4,
              cures: [.clearing, .broad, .quench], order: 1,
              allowsSeverityOverride: true, allowsDurationOverride: true,
              stonebarkEligible: true),
        .init(id: .dazzle, displayName: "Dazzle", glyph: "sun.max.fill",
              family: .accuracy,
              defaultDamage: Tuning.Encounter.statusDamage["dazzle"] ?? 0,
              defaultTicks: Tuning.Encounter.statusRounds["dazzle"] ?? 2,
              cures: [.quenching, .broad, .quench], order: 2,
              allowsSeverityOverride: false, allowsDurationOverride: true,
              stonebarkEligible: true),
        .init(id: .bleed, displayName: "Bleed", glyph: "drop.fill",
              family: .damageOverTime, defaultDamage: Tuning.Encounter.bleedDamage,
              defaultTicks: Tuning.Encounter.bleedRounds,
              cures: [.clearing, .broad], order: 3,
              allowsSeverityOverride: true, allowsDurationOverride: true,
              stonebarkEligible: true)
    ]

    static func definition(_ id: AfflictionID) -> AfflictionDefinition {
        all.first { $0.id == id }!
    }
}

enum AfflictionProvenance: String, Codable, Hashable, Sendable {
    case direct, coating, copied, retaliation, environment, migratedUnknown
}

struct AfflictionInstance: Codable, Equatable, Identifiable, Sendable {
    var id: UInt64 { applicationReceipt }
    var kind: AfflictionID
    var target: Combatant
    var source: Combatant?
    /// Every same-kind contributor merged into this application. `provenance` below remains the
    /// damage-owning component used for source credit; this set preserves the complete hit receipt.
    var provenances: Set<AfflictionProvenance>
    var provenance: AfflictionProvenance
    var damage: Int
    var ticksRemaining: Int
    var endless: Bool = false
    var applicationReceipt: UInt64

    init(kind: AfflictionID, target: Combatant, source: Combatant?,
         provenance: AfflictionProvenance, damage: Int, ticksRemaining: Int,
         endless: Bool = false, applicationReceipt: UInt64) {
        self.kind = kind
        self.target = target
        self.source = source
        self.provenances = [provenance]
        self.provenance = provenance
        self.damage = damage
        self.ticksRemaining = ticksRemaining
        self.endless = endless
        self.applicationReceipt = applicationReceipt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        kind = try c.decode(AfflictionID.self, forKey: .kind)
        target = try c.decode(Combatant.self, forKey: .target)
        source = try c.decodeIfPresent(Combatant.self, forKey: .source)
        provenance = try c.decodeIfPresent(AfflictionProvenance.self, forKey: .provenance)
            ?? .migratedUnknown
        provenances = try c.decodeIfPresent(Set<AfflictionProvenance>.self,
                                             forKey: .provenances) ?? [provenance]
        damage = try c.decodeIfPresent(Int.self, forKey: .damage) ?? 0
        ticksRemaining = try c.decodeIfPresent(Int.self, forKey: .ticksRemaining) ?? 0
        endless = try c.decodeIfPresent(Bool.self, forKey: .endless) ?? false
        applicationReceipt = try c.decodeIfPresent(UInt64.self,
                                                     forKey: .applicationReceipt) ?? 0
    }
}

/// A prepared one-hit weapon treatment. Bleed remains separate because it predates the newer
/// status list and has its own wound timing; the other three use `StatusKind` when they land.
enum PreparedCoating: String, Codable, Hashable, Sendable {
    case poison, burn, bleed, dazzle
}

/// One affliction on one combatant.
struct StatusState: Codable, Equatable, Sendable {
    var kind: StatusKind
    /// Per round. Zero for `dazzle`, which costs you accuracy rather than health.
    var damage: Int
    var rounds: Int

    init(kind: StatusKind, damage: Int, rounds: Int) {
        self.kind = kind
        self.damage = damage
        self.rounds = rounds
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        kind = try c.decodeIfPresent(StatusKind.self, forKey: .kind) ?? .burn
        damage = try c.decodeIfPresent(Int.self, forKey: .damage) ?? 0
        rounds = try c.decodeIfPresent(Int.self, forKey: .rounds) ?? 0
    }
}

/// **What a Ward can be set against.** Six things, not two — which is what makes setting one a
/// decision, and what makes spending a round on Sight first worth doing.
enum Harm: Codable, Hashable, Sendable {
    case blow(DamageKind)
    case emanation(EmanationKind)

    var displayName: String {
        switch self {
        case .blow(let kind): kind.rawValue
        case .emanation(let element): element.rawValue
        }
    }
}

/// A wound that keeps opening. Damage per round, and how many rounds are left.
struct BleedState: Codable, Equatable, Sendable {
    var damage: Int
    var rounds: Int

    init(damage: Int, rounds: Int) {
        self.damage = damage
        self.rounds = rounds
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        damage = try c.decodeIfPresent(Int.self, forKey: .damage) ?? 0
        rounds = try c.decodeIfPresent(Int.self, forKey: .rounds) ?? 0
    }
}

/// What somebody is turning aside, and for how long. A ward is against **one kind** — the whole
/// point is that you have to know what's coming.
struct WardState: Codable, Equatable, Sendable {
    var harm: Harm
    var rounds: Int

    init(against harm: Harm, rounds: Int) {
        self.harm = harm
        self.rounds = rounds
    }

    /// Accepts the bare `DamageKind` this used to hold, so a save written mid-fight before wards
    /// could guard an emanation still resumes with the ward it had.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        rounds = try c.decodeIfPresent(Int.self, forKey: .rounds) ?? 0
        if let harm = try c.decodeIfPresent(Harm.self, forKey: .harm) {
            self.harm = harm
        } else if let kind = try c.decodeIfPresent(DamageKind.self, forKey: .against) {
            harm = .blow(kind)
        } else {
            harm = .blow(.pierce)
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(harm, forKey: .harm)
        try c.encode(rounds, forKey: .rounds)
    }

    private enum CodingKeys: String, CodingKey { case harm, rounds, against }
}

/// Modern Ward is bounded by global encounter rounds, not by the owner's personal turns.
struct WardReceipt: Codable, Equatable, Sendable {
    var harm: Harm
    var activationRound: Int
    var expiresBeforeRound: Int
}

struct SnuffReceipt: Codable, Equatable, Sendable {
    var remainingScheduledTurns: Int
    /// Frozen at the primary slot so interleaved follow-ups use the same delivery truth.
    var suppressedRound: Int?
}

enum EncounterOutcome: String, Codable, Equatable, Sendable {
    case victory
    case fled
    /// Party down. No death state in v0 — you're carried home with a partial haul.
    case defeated
}
