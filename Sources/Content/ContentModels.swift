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

    enum Acquisition: String, Codable, Sendable {
        case starter, research, worldDrop
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
