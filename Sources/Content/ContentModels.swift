import Foundation

// Content definitions: the *shape* of catalog data. The data itself is JSON under
// `Sources/Content/Data/`, per CLAUDE.md — symbols, gambit pieces, creatures, items and base
// stations are expected to grow a lot, so none of them may become hardcoded logic.
//
// All numbers in the JSON are `// PLACEHOLDER` stopgaps.

/// A kind of slot a book has.
///
/// Content, not code — see `SlotID`. Adding, removing or renaming a slot is a `slots.json` edit;
/// books, the Writing Desk, the projection and the save format all follow.
struct SlotDef: Codable, Equatable, Identifiable, Sendable {
    var id: SlotID
    var name: String
    var blurb: String
    var order: Int
}

/// A symbol the player can drop into a book slot.
struct SymbolDef: Codable, Equatable, Identifiable, Sendable {
    var id: SymbolID
    var name: String
    var slot: SlotID
    var blurb: String
    /// SF Symbol name — v0 has no art (design brief: SF Symbols/emoji + colour).
    var icon: String
    /// How the player gets it: part of the starting collection, or Workshop research.
    var acquisition: Acquisition
    /// Essence contribution to the bind cost.
    var essenceCost: Int
    /// How much this symbol moves the book's Stability headline, **in the headline's own units**.
    ///
    /// Positive stabilises, negative destabilises, and the numbers simply add: a book starts at 100
    /// and a symbol reading "−25 stability" moves it to 75. No conversion factor, no separate
    /// instability scale — the number on the symbol is the number on the meter, because anything
    /// else makes composing a book guesswork.
    var stabilityDelta: Int
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

    static let none = DangerProfile(spawnMultiplier: 1, tierDelta: 0, hazardTiles: 0, damagePerTurn: 0)

    /// Peace is recognised by giving stability *back* — it's the only profile that calms.
    var isCalming: Bool { spawnMultiplier < 1 && tierDelta < 0 }

    init(spawnMultiplier: Double = 1, tierDelta: Int = 0, hazardTiles: Int = 0,
         damagePerTurn: Int = 0, flavour: String? = nil) {
        self.spawnMultiplier = spawnMultiplier
        self.tierDelta = tierDelta
        self.hazardTiles = hazardTiles
        self.damagePerTurn = damagePerTurn
        self.flavour = flavour
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
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
}

/// A stackable resource. Never consumes an inventory slot.
struct ResourceDef: Codable, Equatable, Identifiable, Sendable {
    var id: ResourceID
    var name: String
    var icon: String
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

    enum Kind: String, Codable, Sendable {
        case consumable
        case key       // opens a locked cache — in a *different* world than the one it dropped in
        case curio     // drops unidentified
        case gear
        case treasure
    }
}

/// One Skill. Each party member has exactly one in v0.
struct SkillDef: Codable, Equatable, Identifiable, Sendable {
    var id: SkillID
    var name: String
    var icon: String
    var blurb: String
    var kind: Kind
    /// Damage dealt or health restored, before variance.
    var power: Int
    /// Rounds before it can be used again. Rounds — never seconds (pillar 1).
    var cooldownRounds: Int
    /// Which party member owns it. Moves onto the character when the party grows past two.
    var owner: Owner

    enum Kind: String, Codable, Sendable { case damage, heal }
    enum Owner: String, Codable, Sendable { case binder, companion }
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
