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
    /// Which creature this was. Kept for the bestiary — *not* for working out how it fights.
    var creatureID: CreatureID
    /// How it fights, resolved at spawn. See `CombatStats`.
    var stats: CombatStats
    var currentHP: Int

    var isAlive: Bool { currentHP > 0 }
    var maxHP: Int { stats.maxHP }
}

/// A fight in progress. Saved in full — being mid-encounter is the hardest resume case in the game,
/// and the one the acceptance criteria call out by name.
struct EncounterState: Codable, Equatable, Sendable {
    var id: InstanceID
    var foes: [FoeState]

    /// Fixed rotation, party then enemies (PLACEHOLDER — there is no speed stat in v0). Stored
    /// rather than recomputed so that a foe dying mid-round can't shift whose turn it is.
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
}

enum EncounterOutcome: String, Codable, Equatable, Sendable {
    case victory
    case fled
    /// Party down. No death state in v0 — you're carried home with a partial haul.
    case defeated
}
