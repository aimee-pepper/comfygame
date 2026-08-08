import Foundation

/// Automation: an ordered list of assembled rules, evaluated top-down, **first match fires** (the
/// FF12 execution model, locked in decisions-log).
///
/// One rule that matters more than it looks: **a rule whose action isn't available doesn't fire,
/// and evaluation continues down the list.** A heal rule while the heal is on cooldown falls
/// through to the attack rule below it. That's what makes ordering a real decision rather than a
/// formality — and it's why the Party screen's drag-reorder visibly changes how a fight goes.
///
/// Rules are composed from components (`GambitRule`), so this interprets a small grammar rather
/// than a list of special cases. Adding "Foe: highest HP" or "above 70%" to the game is a content
/// edit; nothing in here changes.
enum GambitEngine {

    struct Decision: Equatable {
        var rule: GambitRule
        var action: CombatAction
    }

    /// What an automated combatant does this turn, or `nil` if no rule both matched and could act.
    static func decide(for actor: Combatant = .companion(0), in state: GameState) -> Decision? {
        guard let run = state.worlds.activeRun, let encounter = run.activeEncounter else { return nil }

        // Disabled rules still occupy their slot and their position — switching one off is a way
        // of testing an order, not a way of getting a free slot.
        for rule in rules(for: actor, in: state).prefix(availableSlots(in: state)) where rule.isEnabled {
            guard rule.isWritable(with: state.base.ownedGambitComponents) else { continue }
            guard let target = target(of: rule, actor: actor, run: run, encounter: encounter, state: state) else { continue }
            guard let action = action(of: rule, target: target, actor: actor,
                                      encounter: encounter, state: state) else {
                continue // matched, but couldn't act — try the next rule down
            }
            return Decision(rule: rule, action: action)
        }
        return nil
    }

    /// Whose rule list to run. The Binder's is only consulted once "write your own hand" is learned.
    static func rules(for actor: Combatant, in state: GameState) -> [GambitRule] {
        switch actor {
        case .companion(let index):
            state.base.roster.indices.contains(index) ? state.base.roster[index].gambits : []
        case .binder: state.base.hasAutomateSelfUnlock ? state.base.binderGambits : []
        case .foe: []
        }
    }

    /// How many rules are actually running. Rules past this are owned but idle — that's the
    /// progression, and the Party screen shows the cut-off.
    static func availableSlots(in state: GameState) -> Int {
        Tuning.Encounter.startingGambitSlots
            + state.base.purchasedGambitSlots     // researched; lost in a reset
            + state.reality.bonusGambitSlots      // bought with motes; survives everything
    }

    // MARK: - Interpreting a rule

    private enum Target: Equatable {
        case foe(InstanceID)
        case ally(Combatant)
    }

    /// Who the rule is about, if anyone satisfies it.
    private static func target(of rule: GambitRule,
                               actor: Combatant,
                               run: WorldRun,
                               encounter: EncounterState,
                               state: GameState) -> Target? {
        guard let subject = ContentCatalog.shared.gambitComponent(rule.subject),
              let selector = subject.selector
        else { return nil }

        switch selector {
        case "self":
            return matches(rule, combatant: actor, run: run) ? .ally(actor) : nil

        case "ally.any":
            // Whoever is worst off among those that match — the obvious intent of "an ally is hurt".
            return party(in: run, state: state)
                .filter { matches(rule, combatant: $0, run: run) }
                .min { healthFraction($0, in: run) < healthFraction($1, in: run) }
                .map { .ally($0) }

        case "foe.any":
            return encounter.livingFoes.first { matches(rule, foe: $0) }.map { .foe($0.id) }

        case "foe.lowestHP":
            return encounter.livingFoes.filter { matches(rule, foe: $0) }
                .min { $0.currentHP < $1.currentHP }.map { .foe($0.id) }

        case "foe.highestHP":
            return encounter.livingFoes.filter { matches(rule, foe: $0) }
                .max { $0.currentHP < $1.currentHP }.map { .foe($0.id) }

        default:
            // An unknown selector never fires. Content can run ahead of the engine safely.
            return nil
        }
    }

    /// Everybody standing. **The whole party**, not the two the engine used to know about — an
    /// "ally is hurt" rule that could only ever see one ally is a rule that stops working the
    /// moment a second person comes along.
    private static func party(in run: WorldRun, state: GameState) -> [Combatant] {
        CombatRules.party(of: state).filter { CombatRules.isAlive($0, in: run) }
    }

    private static func healthFraction(_ combatant: Combatant, in run: WorldRun) -> Double {
        let health = CombatRules.health(of: combatant, in: run)
        return health.max > 0 ? Double(health.current) / Double(health.max) : 0
    }

    // MARK: Conditions

    private static func matches(_ rule: GambitRule, combatant: Combatant, run: WorldRun) -> Bool {
        guard rule.hasCondition else { return true }
        return compare(rule, value: healthFraction(combatant, in: run))
    }

    private static func matches(_ rule: GambitRule, foe: FoeState) -> Bool {
        guard rule.hasCondition else { return true }
        let fraction = foe.maxHP > 0 ? Double(foe.currentHP) / Double(foe.maxHP) : 0
        return compare(rule, value: fraction)
    }

    private static func compare(_ rule: GambitRule, value: Double) -> Bool {
        let catalog = ContentCatalog.shared
        guard let property = rule.property.flatMap({ catalog.gambitComponent($0) })?.property,
              let comparator = rule.comparator.flatMap({ catalog.gambitComponent($0) })?.comparator,
              let threshold = rule.threshold.flatMap({ catalog.gambitComponent($0) })?.value
        else { return false }

        // Only health exists to measure so far; status and resources are later vocabulary.
        guard property == "hp" else { return false }

        switch comparator {
        case "below": return value < threshold
        case "above": return value > threshold
        default: return false
        }
    }

    // MARK: Actions

    private static func action(of rule: GambitRule,
                               target: Target,
                               actor: Combatant,
                               encounter: EncounterState,
                               state: GameState) -> CombatAction? {
        guard let kind = ContentCatalog.shared.gambitComponent(rule.action)?.action else { return nil }

        switch kind {
        case "attack":
            if case .foe(let id) = target { return .attack(foe: id) }
            // A rule like "Ally hurt → Attack" still needs something to hit.
            return encounter.livingFoes.first.map { .attack(foe: $0.id) }

        case "heal":
            // The best heal this member is carrying and can actually use right now.
            guard CombatRules.ready(.heal, for: actor, in: encounter, state: state) != nil
            else { return nil } // on cooldown ⇒ this rule can't fire; fall through to the next
            if case .ally(let member) = target { return .healSkill(ally: member) }
            return .healSkill(ally: actor)

        case "skill":
            // **Whatever's ready.** With twelve skills the gambit can't mean "the skill" any more,
            // so it means "something better than swinging" — heal a hurt ally if that's what's up,
            // otherwise put a skill into whatever you were aiming at.
            guard let skill = CombatRules.bestReadySkill(for: actor, in: encounter, state: state)
            else { return nil }
            if skill.needsAlly {
                if case .ally(let member) = target { return .skill(skill.id, ally: member) }
                return .skill(skill.id, ally: actor)
            }
            if skill.needsFoe {
                if case .foe(let id) = target { return .skill(skill.id, foe: id) }
                return encounter.livingFoes.first.map { .skill(skill.id, foe: $0.id) }
            }
            return .skill(skill.id)

        case "flee":
            return .flee

        default:
            return nil
        }
    }
}
