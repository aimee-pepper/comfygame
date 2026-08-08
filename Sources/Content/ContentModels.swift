import Foundation

// Content definitions: the *shape* of catalog data. The data itself is JSON under
// `Sources/Content/Data/`, per CLAUDE.md — symbols, gambit pieces, creatures, items and base
// stations are expected to grow a lot, so none of them may become hardcoded logic.
//
// All numbers in the JSON are `// PLACEHOLDER` stopgaps.

/// A symbol the player can write on a page.
struct SymbolDef: Codable, Equatable, Identifiable, Sendable {
    var id: SymbolID
    var name: String
    var blurb: String
    /// SF Symbol name — v0 has no art (design brief: SF Symbols/emoji + colour).
    var icon: String
    /// How the player gets it: part of the starting collection, or Workshop research.
    var acquisition: Acquisition
    /// Essence contribution to the bind cost.
    var essenceCost: Int
    // **There is deliberately no `stabilityDelta` here, and there must never be one again.**
    //
    // A symbol used to carry a hand-typed number — Rich Ore −45, Teeming Life −35 — and greed is
    // now *measured* off what the symbol says (`greedDelta`). Keeping both meant one world had two
    // prices depending on which vocabulary you happened to write it in: "Rich Ore" cost 45 and the
    // same world spelled out as *great iron, gold* cost 8. Q44's answer is to let the measurement
    // price them, and to make that **structural rather than remembered** — with no field to type a
    // greed number into, "no authored greed" is enforced by the compiler instead of by discipline.
    //
    // What a symbol may still assert by hand is `danger.stabilityTrade`, because that is a
    // different axis and not a restatement of greed. See `DangerProfile`.
    /// Multipliers on resource yield, keyed by resource. Absent = 1.0.
    var yieldModifiers: [ResourceID: Double]
    /// Additive weight changes to the enemy spawn table, keyed by creature.
    var enemyTableModifiers: [CreatureID: Double]
    /// Shifts the encounter difficulty tier shown in the pre-bind preview.
    var enemyTierDelta: Int
    /// Changes how far the player can see. The paired-tradeoff pattern from the decisions log:
    /// Dim Sky buys a longer-lived world with a ring of your sight.
    var visionDelta: Int
    /// What this symbol *says*, in the atomic vocabulary of the pressure model.
    ///
    /// The rune spec's own definition: "a **compound** is a learned single glyph meaning what
    /// several components mean together, at a smaller footprint" (§9). Every v0 symbol is exactly
    /// that — "Frostbound" is Ice and Snow written as one mark. Spelling them out here is
    /// translating the coarse vocabulary into the fine one, not adding a second system, and it's
    /// what lets a bound book produce real pressure readings before the page UI exists.
    ///
    /// The symbol's own `stabilityDelta`, `yieldModifiers` and the rest stay authoritative for the
    /// v0 loop. Pressures ride alongside and drive what the older fields can't describe — climate,
    /// creature character, and which sites a world can host.
    var expandsTo: [CompoundComponent]
    /// The target this symbol is *primarily* about — the dial it exists to set.
    ///
    /// Taken from the first component of its expansion, which is authored first for exactly this
    /// reason. It drives two things: which section of the palette the symbol appears in, and
    /// exclusivity — **one primary per target**, so you write one thing that makes light, one that
    /// shapes the land, one that sets the climate, and then decorate (decisions-session-11 §3).
    var primaryTarget: PressureTargetID? { expandsTo.first?.target }

    /// Modifiers layer freely; primaries compete for their target's single place.
    ///
    /// **[INTERPRETATION]** The spec distinguishes primary sources from modifiers, but the v0
    /// symbols are compounds and none is authored as a modifier yet, so everything with an
    /// expansion is currently a primary. When modifier runes exist this becomes a data field.
    var isPrimary: Bool { primaryTarget != nil }

    /// How this symbol makes the world hostile — or, for Peace, less so.
    ///
    /// The **danger↔time axis** (`contradiction-danger-spec.md` §5). Danger runes accept hostility
    /// and buy stability; Peace spends stability to buy calm. Danger runes are the release valve
    /// that makes greedy worlds viable at all: a world rich enough to be worth writing may be too
    /// unstable to survive, and you buy it time by accepting that it crawls with things.
    var danger: DangerProfile?

    enum Acquisition: String, Codable, Sendable {
        case starter, research, worldDrop
    }
}

/// What a symbol does to how hostile a world is.
///
/// Deliberately several dials rather than one "danger" number: stacking danger runes is supposed to
/// **broaden the kinds of danger** rather than multiply one of them, so Swarm and Predation have to
/// be able to pull in opposite directions on the same axis.
struct DangerProfile: Codable, Equatable, Sendable {
    /// **What accepting this hostility buys, in the Stability headline's own units.**
    ///
    /// The one number a symbol is still allowed to assert by hand, and it lives here rather than on
    /// the symbol so it cannot be mistaken for greed (Q44). Greed is measured off what a symbol
    /// *says*; this is a **trade** — accept that the world crawls with things, and it holds together
    /// longer. Nothing in the physical reading of a stormy world can produce that number, because
    /// the bargain is with the player rather than with the world.
    ///
    /// Positive on the danger runes. Negative on Peace, which is the inverse: it spends stability to
    /// buy calm. The positive side is capped in aggregate (`Tuning.Danger.maximumStabilityGift`);
    /// the negative side is a cost and is never capped.
    var stabilityTrade: Int
    /// Scales how many creatures the world holds. Swarm raises it; Predation lowers it.
    var spawnMultiplier: Double
    /// Shifts creature tier. Predation raises it; Swarm lowers it.
    var tierDelta: Int
    /// Hazard tiles placed at generation, before any stability-driven crumbling.
    var hazardTiles: Int
    /// Damage taken per player turn simply for being here. Miasma's whole idea.
    var damagePerTurn: Int
    /// Which description clause this arms, so the panel can say what kind of hostile it is.
    var flavour: String?

    static let none = DangerProfile(stabilityTrade: 0, spawnMultiplier: 1, tierDelta: 0,
                                    hazardTiles: 0, damagePerTurn: 0)

    /// Peace is recognised by giving stability *back* — it's the only profile that calms.
    var isCalming: Bool { spawnMultiplier < 1 && tierDelta < 0 }

    init(stabilityTrade: Int = 0, spawnMultiplier: Double = 1, tierDelta: Int = 0,
         hazardTiles: Int = 0, damagePerTurn: Int = 0, flavour: String? = nil) {
        self.stabilityTrade = stabilityTrade
        self.spawnMultiplier = spawnMultiplier
        self.tierDelta = tierDelta
        self.hazardTiles = hazardTiles
        self.damagePerTurn = damagePerTurn
        self.flavour = flavour
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        stabilityTrade = try c.decodeIfPresent(Int.self, forKey: .stabilityTrade) ?? 0
        spawnMultiplier = try c.decodeIfPresent(Double.self, forKey: .spawnMultiplier) ?? 1
        tierDelta = try c.decodeIfPresent(Int.self, forKey: .tierDelta) ?? 0
        hazardTiles = try c.decodeIfPresent(Int.self, forKey: .hazardTiles) ?? 0
        damagePerTurn = try c.decodeIfPresent(Int.self, forKey: .damagePerTurn) ?? 0
        flavour = try c.decodeIfPresent(String.self, forKey: .flavour)
    }
}

/// One sigil inside a compound. The same statement a player will one day place by hand.
struct CompoundComponent: Codable, Equatable, Sendable {
    var source: PressureSourceID
    var target: PressureTargetID
    var intensity: Intensity
    /// Targets this component explicitly denies — "a sun that does not warm".
    var negates: Set<PressureTargetID>

    init(source: PressureSourceID,
         target: PressureTargetID,
         intensity: Intensity = .moderate,
         negates: Set<PressureTargetID> = []) {
        self.source = source
        self.target = target
        self.intensity = intensity
        self.negates = negates
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        source = try container.decode(PressureSourceID.self, forKey: .source)
        target = try container.decode(PressureTargetID.self, forKey: .target)
        intensity = try container.decodeIfPresent(Intensity.self, forKey: .intensity) ?? .moderate
        negates = try container.decodeIfPresent(Set<PressureTargetID>.self, forKey: .negates) ?? []
    }
}

/// An enemy type. v0 ships three (design brief: enemy variety is explicitly out of scope).
struct CreatureDef: Codable, Equatable, Identifiable, Sendable {
    var id: CreatureID
    var name: String
    var icon: String
    var tier: Int
    var maxHP: Int
    var attack: Int
    /// Base weight in the spawn table before symbol modifiers.
    var spawnWeight: Double
    /// How far off it notices you. Two is the baseline; later creatures are expected to see
    /// further, so this belongs to the creature rather than to `Tuning`.
    var sightRadius: Int
    /// Conditions without which this doesn't live here at all.
    var requires: [PressureCondition]
    /// Conditions that each multiply its share of the roster.
    var favours: [PressureCondition]
    /// What it draws from the world's energy budget. A poor world can't afford the expensive things
    /// — the square-cube law, the defence-mobility trade and costly signalling in one number.
    var appetite: Double

    /// Whether this world can support it, and how strongly it belongs here.
    func affinity(in readings: PressureReadings) -> Double {
        guard requires.allSatisfy({ $0.holds(in: readings) }) else { return 0 }
        return favours.reduce(spawnWeight) { total, condition in
            condition.holds(in: readings) ? total * Tuning.Pressure.affinityBonus : total
        }
    }

    /// Whether this is out at night. **[PLACEHOLDER]** which creatures — the roster swapping at
    /// nightfall is what session 13 §6 asks for; who's in it is content.
    var isNocturnal: Bool

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(CreatureID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        icon = try c.decode(String.self, forKey: .icon)
        tier = try c.decode(Int.self, forKey: .tier)
        maxHP = try c.decode(Int.self, forKey: .maxHP)
        attack = try c.decode(Int.self, forKey: .attack)
        spawnWeight = try c.decode(Double.self, forKey: .spawnWeight)
        sightRadius = try c.decodeIfPresent(Int.self, forKey: .sightRadius) ?? 2
        isNocturnal = try c.decodeIfPresent(Bool.self, forKey: .isNocturnal) ?? false
        requires = try c.decodeIfPresent([PressureCondition].self, forKey: .requires) ?? []
        favours = try c.decodeIfPresent([PressureCondition].self, forKey: .favours) ?? []
        appetite = try c.decodeIfPresent(Double.self, forKey: .appetite) ?? 8
    }
}

/// How much world there is.
///
/// Not a mechanism of its own — it's a reading of the **Scale** qualifier, which was already in the
/// vocabulary and already placeable. Bigger is not simply better: a vast world holds more but needs
/// more turns to cross, so it costs stability. Writing one you can't finish exploring is a real and
/// instructive mistake (decisions-session-13 §5).
enum WorldScale: String, Codable, CaseIterable, Sendable {
    case minute, small, ordinary, large, vast

    /// The rung of the Scale ladder this corresponds to. `ordinary` is what you get by not writing
    /// one at all, so it has no rung.
    init?(rung: QualifierID) {
        switch rung.rawValue {
        case "minute": self = .minute
        case "small": self = .small
        case "large": self = .large
        case "vast": self = .vast
        default: return nil
        }
    }

    /// Grid edge. **[PLACEHOLDER]** — session 13 §2 starts a middling world around 18 across,
    /// against the 14 it used to always be.
    var gridSide: Int {
        switch self {
        case .minute: 12
        case .small: 15
        case .ordinary: 18
        case .large: 23
        case .vast: 28
        }
    }

    /// What asking for this much world costs, in the Stability headline's own units. Ordinary is
    /// free; more than a world would ordinarily carry is the same greed as asking for rich ore.
    /// **[PLACEHOLDER]**
    var stabilityDelta: Int {
        switch self {
        case .minute: 12
        case .small: 6
        case .ordinary: 0
        case .large: -14
        case .vast: -30
        }
    }

    var displayName: String { rawValue.capitalized }
}

/// What a piece of gear is worth wearing for.
struct GearDef: Codable, Equatable, Sendable {
    var slot: GearSlot
    /// Same units the combat maths already used when research bought these numbers.
    var tier: Int
    /// **Which corner of the weapon triangle this swings in** (combat-depth-spec §1).
    ///
    /// Foes have had a weapon triangle since creatures were generated; the player's weapons had no
    /// damage type at all, so a plated bulwark and a shaggy browser were fought identically. Nil on
    /// armour, and on anything that predates the field.
    var damage: DamageKind?
    /// How far it reaches. Length beats speed at the moment of contact.
    var reach: Reach = .close
    /// **What it's made of, in the two properties that had no job** (Q36's addition, audit #9).
    ///
    /// Hardness, flexibility, density and lustre each decide what the Blacksmith asks for.
    /// Insulation and reactivity decided nothing at all, so a warm pelt and a volatile ichor were
    /// worth nothing to wear. Authored here rather than read off a material because **found gear
    /// isn't made of anything yet** — crafting doesn't exist, and a piece off the ground is a
    /// catalogue entry. When crafting lands these become the crafted piece's own properties.
    var insulation: Double = 0
    var reactivity: Double = 0
    /// **The rule this piece breaks**, on the eight wild-only weapons and nowhere else
    /// (`apex-encounters.md` §4). Nil on everything you can make.
    var breaks: WildRule?
    /// What `innateStatus` leaves in the wound, and what `wardWhileHeld` turns aside.
    var statusKind: String?
    var wardsAgainst: DamageKind?

    init(slot: GearSlot, tier: Int, damage: DamageKind? = nil, reach: Reach = .close,
         insulation: Double = 0, reactivity: Double = 0, breaks: WildRule? = nil,
         statusKind: String? = nil, wardsAgainst: DamageKind? = nil) {
        self.slot = slot
        self.tier = tier
        self.damage = damage
        self.reach = reach
        self.insulation = insulation
        self.reactivity = reactivity
        self.breaks = breaks
        self.statusKind = statusKind
        self.wardsAgainst = wardsAgainst
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        slot = try c.decode(GearSlot.self, forKey: .slot)
        tier = try c.decodeIfPresent(Int.self, forKey: .tier) ?? 0
        damage = try c.decodeIfPresent(DamageKind.self, forKey: .damage)
        reach = try c.decodeIfPresent(Reach.self, forKey: .reach) ?? .close
        insulation = try c.decodeIfPresent(Double.self, forKey: .insulation) ?? 0
        reactivity = try c.decodeIfPresent(Double.self, forKey: .reactivity) ?? 0
        breaks = try c.decodeIfPresent(WildRule.self, forKey: .breaks)
        statusKind = try c.decodeIfPresent(String.self, forKey: .statusKind)
        wardsAgainst = try c.decodeIfPresent(DamageKind.self, forKey: .wardsAgainst)
    }
}

/// `CodingKeyRepresentable` so `[GearSlot: ItemID]` encodes as a JSON *object* rather than the
/// flat alternating array Swift uses by default — the same reason `StringIdentifier` conforms.
/// Saves stay readable, and a hand-edited one round-trips.
/// **A standard assortment** (Aimee, 6 Aug), rather than a sword and a shirt.
///
/// `armor` keeps its old raw value even though it reads as "Body" — it's a key inside every save's
/// `equipped` dictionary, and renaming it would quietly empty everybody's armour slot.
///
/// Tool and Keepsake come from `materials-crafting-spec.md` §7: a tool is what lets you work harder
/// ground, and a keepsake is somewhere for the singular things to live — the artefact you keep
/// because there isn't another one.
enum GearSlot: String, Codable, CaseIterable, Sendable, CodingKeyRepresentable {
    case weapon
    case offhand
    case head
    case armor
    case hands
    case feet
    case tool
    case keepsake

    var displayName: String {
        switch self {
        case .weapon: "Weapon"
        case .offhand: "Off-hand"
        case .head: "Head"
        case .armor: "Body"
        case .hands: "Hands"
        case .feet: "Feet"
        case .tool: "Tool"
        case .keepsake: "Keepsake"
        }
    }

    var icon: String {
        switch self {
        case .weapon: "hammer"
        case .offhand: "shield.lefthalf.filled"
        case .head: "circle.dashed"
        case .armor: "shield"
        case .hands: "hand.raised"
        case .feet: "shoeprints.fill"
        case .tool: "wrench.and.screwdriver"
        case .keepsake: "sparkles"
        }
    }

    /// Whether this slot contributes to soaking damage. The weapon, the tool and the keepsake do
    /// other jobs.
    var isProtective: Bool {
        switch self {
        case .offhand, .head, .armor, .hands, .feet: true
        case .weapon, .tool, .keepsake: false
        }
    }

    var codingKey: CodingKey { StringCodingKey(rawValue) }
    init?<T: CodingKey>(codingKey: T) { self.init(rawValue: codingKey.stringValue) }
}

/// A stackable resource. Never consumes an inventory slot.
struct ResourceDef: Codable, Equatable, Identifiable, Sendable {
    var id: ResourceID
    var name: String
    var icon: String
    /// The target whose magnitude decides how much of this a world holds.
    var drivenBy: PressureTargetID?
    /// Conditions without which there is none at all.
    var requires: [PressureCondition] = []
    /// Conditions that each multiply its share.
    var favours: [PressureCondition] = []

    /// How much of the ground is this, given what the world is made of.
    ///
    /// **This is the wiring the pressure model was missing** — until content derived from readings,
    /// the eight targets described worlds they did not generate
    /// (`audit-what-pressures-actually-do.md` §4.1).
    func abundance(in readings: PressureReadings) -> Double {
        guard requires.allSatisfy({ $0.holds(in: readings) }) else { return 0 }
        let magnitude = drivenBy.map { readings[$0].peak } ?? Tuning.Pressure.scaleMaximum / 2
        let base = max(Tuning.World.baseResourceWeight, magnitude / 10)
        return favours.reduce(base) { total, condition in
            condition.holds(in: readings) ? total * Tuning.Pressure.affinityBonus : total
        }
    }
    /// Motes are the Reality-layer currency and are banked separately from base resources.
    var isRealityCurrency: Bool
}

/// A slot-consuming item.
struct ItemDef: Codable, Equatable, Identifiable, Sendable {
    var id: ItemID
    var name: String
    var icon: String
    var rarity: Rarity
    var blurb: String
    var kind: Kind
    /// For unidentified curios: what this becomes at the Storehouse.
    var identifiesInto: ItemID?
    /// Teaser name shown before identification ("A humming shard…").
    var unidentifiedName: String?
    /// What wearing this does. Gear is **found, never researched** (decisions-session-12 §3–4):
    /// you don't study your way to a better sword, you take one off a ruin floor — and later you
    /// find a smith who can make one.
    var gear: GearDef?

    enum Kind: String, Codable, Sendable {
        case consumable
        case key       // opens a locked cache — in a *different* world than the one it dropped in
        case curio     // drops unidentified
        case gear
        case treasure
    }
}

/// One Skill. Each party member has exactly one in v0.
/// One thing a party member can do instead of swinging.
///
/// **The design rule from `resources-skills-spec.md` §2: every skill answers a specific kind of
/// creature.** If it's good against everything it's just a bigger attack, and the game had exactly
/// two of those — one damage, one heal — while foes had trait-derived armour, damage character,
/// retaliation and reach. The player side of every fight was two buttons.
struct SkillDef: Codable, Equatable, Identifiable, Sendable {
    var id: SkillID
    var name: String
    var icon: String
    var blurb: String
    var kind: Kind
    /// Damage dealt or health restored, before variance. Zero on skills that do neither.
    var power: Int
    /// Rounds before it can be used again. Rounds — never seconds (pillar 1).
    ///
    /// **The only limiter**, deliberately: `resources-skills-spec.md` §2 rules out a mana pool,
    /// because a second resource to track in every fight is the wrong overhead for this game.
    /// Stronger skills carry longer cooldowns instead.
    var cooldownRounds: Int
    /// Which party member owns it. Moves onto the character when the party grows past two.
    var owner: Owner
    /// How many rounds the effect lasts, for the ones that leave something behind.
    var rounds: Int = 1
    /// What this is *for*, in one line, shown under the name. The spec insists every skill name the
    /// problem it solves, so the UI says it rather than making you infer it.
    var answers: String = ""
    /// Which corner of the triangle a damaging skill swings in, when it isn't the weapon's own.
    var damage: DamageKind?

    enum Kind: String, Codable, Sendable {
        /// Plain damage, using whatever the actor is carrying.
        case damage
        case heal
        /// **Pry** — goes under armour entirely. Low power, and the answer to a plated thing.
        case armourIgnoring
        /// **Overbear** — heavy crush, and you act last next round for having swung it.
        case overbear
        /// **Flense** — a wound that keeps opening. Scales with how long the covering is.
        case bleed
        /// **Sight** — what is this thing actually wearing.
        case reveal
        /// **Ward** — turns aside one kind of damage for a while.
        case ward
        /// **Draw Off** — it comes for you instead of for them.
        case taunt
        /// **Snuff** — puts out whatever it was giving off.
        case snuff
        /// **Quicken** — twice next round, nothing the round after.
        case quicken
        /// **Steady** — closes a wound that was still open.
        case cleanse
        /// **Rout** — leave, and the world doesn't notice.
        case rout
        /// **Read** — learn it properly, without killing it.
        case read
        /// **Fall Back** — change where you're standing without spending the turn on it.
        case reposition

        // The ten the combat trees teach (`docs/combat-trees-full.md`).
        /// **Shatter** — what it was wearing is not what it is wearing now.
        case sunder
        /// **Finish** — large damage to something already nearly gone.
        case execute
        /// **First Strike** — act before the exchange properly begins.
        case preempt
        /// **Brace** — take everything softer for a turn.
        case brace
        /// **Sidestep** — the next one misses outright.
        case dodge
        /// **Interpose** — take a hit meant for somebody else.
        case intercept
        /// **Envenom** — coat a weapon, for several hits.
        case envenom
        /// **Conceal** — untargetable for a turn.
        case conceal
        /// **Ambush** — open a fight with a free attack.
        case ambush
        /// **Elemental Strike** — burn, freeze or shock.
        case elemental
    }

    enum Owner: String, Codable, Sendable { case binder, companion }

    /// Whether using it needs a foe picked out.
    var needsFoe: Bool {
        switch kind {
        case .damage, .armourIgnoring, .overbear, .bleed, .reveal, .taunt, .snuff, .read,
             .sunder, .execute, .ambush, .elemental: true
        case .heal, .ward, .quicken, .cleanse, .rout, .reposition,
             .preempt, .brace, .dodge, .envenom, .conceal: false
        case .intercept: false
        }
    }

    /// Whether it needs an ally picked out — the ones you point at your own side.
    var needsAlly: Bool {
        switch kind {
        case .heal, .cleanse, .intercept: true
        default: false
        }
    }

    init(id: SkillID, name: String, icon: String, blurb: String, kind: Kind, power: Int,
         cooldownRounds: Int, owner: Owner, rounds: Int = 1, answers: String = "",
         damage: DamageKind? = nil) {
        self.id = id
        self.name = name
        self.icon = icon
        self.blurb = blurb
        self.kind = kind
        self.power = power
        self.cooldownRounds = cooldownRounds
        self.owner = owner
        self.rounds = rounds
        self.answers = answers
        self.damage = damage
    }

    /// Tolerant, per the policy in `Migrations.swift`.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(SkillID.self, forKey: .id)
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? id.rawValue
        icon = try c.decodeIfPresent(String.self, forKey: .icon) ?? "sparkle"
        blurb = try c.decodeIfPresent(String.self, forKey: .blurb) ?? ""
        kind = try c.decodeIfPresent(Kind.self, forKey: .kind) ?? .damage
        power = try c.decodeIfPresent(Int.self, forKey: .power) ?? 0
        cooldownRounds = try c.decodeIfPresent(Int.self, forKey: .cooldownRounds) ?? 2
        owner = try c.decodeIfPresent(Owner.self, forKey: .owner) ?? .binder
        rounds = try c.decodeIfPresent(Int.self, forKey: .rounds) ?? 1
        answers = try c.decodeIfPresent(String.self, forKey: .answers) ?? ""
        damage = try c.decodeIfPresent(DamageKind.self, forKey: .damage)
    }
}

/// A base station. The Base screen is a data-driven list of these, not hardcoded buttons —
/// v1+ adds blacksmith, tavern, distillery, and they should be a JSON edit.
struct StationDef: Codable, Equatable, Identifiable, Sendable {
    var id: StationID
    var name: String
    var icon: String
    var blurb: String
    var sortOrder: Int
    var unlockedAtStart: Bool
    var startingTier: Int
    var maxTier: Int
    /// Which screen this station routes to. Matches a case of `AppRoute`.
    var route: String

    /// **Who has to be found before this can be built** (Aimee, 6 Aug).
    ///
    /// A forge is not a thing you buy — it's a person you meet out there and persuade to come home
    /// with you. So the crafting buildings hang off the search loop that already exists: write a
    /// world matching a traveller's signature, meet them, and the building site appears at the base.
    /// Nil means the building needs nobody.
    var builtBy: TravellerID?
    /// What raising it costs once you have the person. Nil means it costs nothing.
    var buildCost: UpgradeCost?
    /// The line on the building site, before it's built. Written from the person's point of view,
    /// because they're the reason it exists.
    var buildBlurb: String?

    init(id: StationID, name: String, icon: String, blurb: String, sortOrder: Int,
         unlockedAtStart: Bool, startingTier: Int, maxTier: Int, route: String,
         builtBy: TravellerID? = nil, buildCost: UpgradeCost? = nil, buildBlurb: String? = nil) {
        self.id = id
        self.name = name
        self.icon = icon
        self.blurb = blurb
        self.sortOrder = sortOrder
        self.unlockedAtStart = unlockedAtStart
        self.startingTier = startingTier
        self.maxTier = maxTier
        self.route = route
        self.builtBy = builtBy
        self.buildCost = buildCost
        self.buildBlurb = buildBlurb
    }

    /// Tolerant, per the policy in `Migrations.swift` — a stations file written before buildings
    /// could be built still loads.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(StationID.self, forKey: .id)
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? id.rawValue
        icon = try c.decodeIfPresent(String.self, forKey: .icon) ?? "square"
        blurb = try c.decodeIfPresent(String.self, forKey: .blurb) ?? ""
        sortOrder = try c.decodeIfPresent(Int.self, forKey: .sortOrder) ?? 0
        unlockedAtStart = try c.decodeIfPresent(Bool.self, forKey: .unlockedAtStart) ?? false
        startingTier = try c.decodeIfPresent(Int.self, forKey: .startingTier) ?? 0
        maxTier = try c.decodeIfPresent(Int.self, forKey: .maxTier) ?? 0
        route = try c.decodeIfPresent(String.self, forKey: .route) ?? "base"
        builtBy = try c.decodeIfPresent(TravellerID.self, forKey: .builtBy)
        buildCost = try c.decodeIfPresent(UpgradeCost.self, forKey: .buildCost)
        buildBlurb = try c.decodeIfPresent(String.self, forKey: .buildBlurb)
    }
}

/// A Reality-layer Constellation node.
struct ConstellationNodeDef: Codable, Equatable, Identifiable, Sendable {
    var id: ConstellationNodeID
    var name: String
    var icon: String
    var blurb: String
    var maxRank: Int
    /// Mote cost per rank, index = rank being bought - 1.
    var moteCostPerRank: [Int]
}
