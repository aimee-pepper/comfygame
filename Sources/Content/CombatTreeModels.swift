import Foundation

// The combat trees (`docs/combat-trees-full.md`). Three trees, three branches each, eight nodes per
// branch. Content, not code: adding a node is a JSON edit.

struct CombatTreeDef: Codable, Equatable, Identifiable, Sendable {
    var id: CombatTreeID
    var name: String
    var icon: String
    var blurb: String
    var branches: [CombatBranchDef]
}

struct CombatBranchDef: Codable, Equatable, Identifiable, Sendable {
    var id: CombatBranchID
    var name: String
    var icon: String
    var blurb: String
    /// In order. **Bought in order**, which is what makes depth a commitment rather than a
    /// shopping list — you cannot reach a capstone without everything under it.
    var nodes: [CombatNodeDef]
}

struct CombatNodeDef: Codable, Equatable, Sendable {
    /// 1–8 within its branch.
    var index: Int
    var name: String
    var blurb: String
    var effect: CombatNodeEffect
    /// A skill this node teaches. Six of nine branches teach two.
    var grantsSkill: SkillID?
}

/// **What a node does**, as data.
///
/// Deliberately a kind plus a few numbers rather than a closure or a switch in the UI: every kind
/// has to be *read* somewhere by `CombatTreeRules`, and `CombatTreeTests` asserts it. A node that
/// grants a value nothing consumes is the fossil pattern (`fossil-audit.md` §6), and seventy-two of
/// them is a lot of places for one to hide.
struct CombatNodeEffect: Codable, Equatable, Sendable {
    var kind: Kind
    /// The corner of the weapon triangle a `damageOfKind` node applies to.
    var damageKind: DamageKind?
    var amount: Double = 0
    var chance: Double = 0
    var fraction: Double = 0
    var threshold: Double = 0
    /// The bar a conditional node has to clear — armour, covering.
    var above: Double = 0

    enum Kind: String, Codable, Sendable, CaseIterable {
        /// A node whose whole effect is the skill it teaches.
        case skill

        // Offense
        case damageOfKind, damageVersusArmour, damageIfHeldRank, staggerChance
        case damagePerMissingInitiative, capstoneBreakingBlow
        case damageVersusCovering, critChance, damageVersusAfflicted, butcheryYield
        case capstoneKillingStroke
        case initiative, gearInitiativeRelief, healOnKill, splashDamage, initiativeOnKill
        case capstoneBlur

        // Defense
        case maxHP, armour, statusResistance, damageReductionWhenHurt, surviveOnce
        case capstoneImmovable
        case evasion, ambushResistance, evasionAfterAttacking, evasionPerCleanRound
        case capstoneGhost
        case allyArmour, partyAmbushResistance, shareBackRankDamage, frontRankArmour
        case partyHealOnKill, capstoneGuardian

        // Craft
        case poisonOnHit, consumablePotency, statusDuration, poisonReducesArmour
        case coatingCostRelief, capstoneBlight
        case encounterChance, sightedAtRange, damageFromConcealment, freeFlee
        case partySightedAtRange, capstoneUnseen
        case burnOnHit, elementResistance, elementalDamage, elementalChain, capstoneEmanant
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        kind = try c.decode(Kind.self, forKey: .kind)
        // The JSON says `kind` for the weapon corner inside a `damageOfKind` effect, which collides
        // with the effect's own kind. Read under its own key.
        damageKind = try c.decodeIfPresent(DamageKind.self, forKey: .damageKind)
        amount = try c.decodeIfPresent(Double.self, forKey: .amount) ?? 0
        chance = try c.decodeIfPresent(Double.self, forKey: .chance) ?? 0
        fraction = try c.decodeIfPresent(Double.self, forKey: .fraction) ?? 0
        threshold = try c.decodeIfPresent(Double.self, forKey: .threshold) ?? 0
        above = try c.decodeIfPresent(Double.self, forKey: .above) ?? 0
    }

    init(kind: Kind, damageKind: DamageKind? = nil, amount: Double = 0, chance: Double = 0,
         fraction: Double = 0, threshold: Double = 0, above: Double = 0) {
        self.kind = kind
        self.damageKind = damageKind
        self.amount = amount
        self.chance = chance
        self.fraction = fraction
        self.threshold = threshold
        self.above = above
    }

    private enum CodingKeys: String, CodingKey {
        case kind, damageKind, amount, chance, fraction, threshold, above
    }
}
