import Foundation

/// The companion's automation: an ordered list of `condition → action` rules, evaluated top-down,
/// **first match fires** (the FF12 execution model, locked in decisions-log).
///
/// One rule that matters more than it looks: **a rule whose action isn't available doesn't fire,
/// and evaluation continues down the list.** A heal rule while the heal is on cooldown falls
/// through to the attack rule below it. That's what makes ordering a real decision rather than a
/// formality — and it's why the Party screen's drag-reorder visibly changes how a fight goes.
///
/// Conditions and actions are interpreted from loose content specs, so the catalog can grow toward
/// FF12-scale granularity (research pass 3) without touching this file's shape.
enum GambitEngine {

    struct Decision: Equatable {
        var piece: GambitPieceID
        var action: CombatAction
    }

    /// What the companion does this turn, or `nil` if no rule both matched and could act.
    static func decide(in state: GameState) -> Decision? {
        guard let run = state.worlds.activeRun, let encounter = run.activeEncounter else { return nil }

        let slots = availableSlots(in: state)
        for id in state.base.companion.gambits.prefix(slots) {
            guard let piece = ContentCatalog.shared.gambitPiece(id) else { continue }
            guard let target = evaluate(piece.condition, run: run, encounter: encounter) else { continue }
            guard let action = action(for: piece.action, target: target, run: run, encounter: encounter) else {
                continue // matched, but couldn't act — try the next rule down
            }
            return Decision(piece: id, action: action)
        }
        return nil
    }

    /// How many rules the companion is actually running. Gambits past the slot count are owned but
    /// inactive — that's the progression, and the Party screen shows the cut-off.
    static func availableSlots(in state: GameState) -> Int {
        Tuning.Encounter.startingGambitSlots + state.reality.bonusGambitSlots
    }

    static func describe(_ id: GambitPieceID) -> String {
        ContentCatalog.shared.gambitPiece(id)?.name ?? id.rawValue
    }

    // MARK: Conditions

    /// What a matched condition points at, which the action then uses.
    private enum Target: Equatable {
        case foe(InstanceID)
        case ally(Combatant)
        case none
    }

    private static func evaluate(_ condition: GambitConditionSpec,
                                 run: WorldRun,
                                 encounter: EncounterState) -> Target? {
        let threshold = condition.threshold ?? 0

        switch condition.kind {
        case "foe.any":
            return encounter.livingFoes.first.map { .foe($0.id) }

        case "foe.lowestHP":
            return encounter.livingFoes.min { $0.currentHP < $1.currentHP }.map { .foe($0.id) }
                ?? encounter.livingFoes.first.map { .foe($0.id) }

        case "foe.hpBelow":
            return encounter.livingFoes
                .filter { fraction($0.currentHP, $0.maxHP) < threshold }
                .min { $0.currentHP < $1.currentHP }
                .map { .foe($0.id) }

        case "ally.hpBelow":
            // Includes the companion itself — "ally: any" in FF12 terms covers the whole party.
            return [Combatant.binder, .companion]
                .filter { CombatRules.isAlive($0, in: run) }
                .filter { member in
                    let health = CombatRules.health(of: member, in: run)
                    return fraction(health.current, health.max) < threshold
                }
                .min { lhs, rhs in
                    let l = CombatRules.health(of: lhs, in: run), r = CombatRules.health(of: rhs, in: run)
                    return fraction(l.current, l.max) < fraction(r.current, r.max)
                }
                .map { .ally($0) }

        case "self.hpBelow":
            let health = CombatRules.health(of: .companion, in: run)
            return fraction(health.current, health.max) < threshold ? .ally(.companion) : nil

        default:
            // An unknown condition never fires. Content can run ahead of the engine safely.
            return nil
        }
    }

    private static func fraction(_ current: Int, _ maximum: Int) -> Double {
        maximum > 0 ? Double(current) / Double(maximum) : 0
    }

    // MARK: Actions

    private static func action(for spec: GambitActionSpec,
                               target: Target,
                               run: WorldRun,
                               encounter: EncounterState) -> CombatAction? {
        switch spec.kind {
        case "attack":
            if case .foe(let id) = target { return .attack(foe: id) }
            // A rule like "Ally HP < 50% → Attack" still needs something to hit.
            return encounter.livingFoes.first.map { .attack(foe: $0.id) }

        case "heal":
            guard CombatRules.isSkillReady(for: .companion, in: encounter),
                  CombatRules.skill(for: .companion)?.kind == .heal
            else { return nil } // on cooldown ⇒ this rule can't fire; fall through to the next
            if case .ally(let member) = target { return .healSkill(ally: member) }
            return .healSkill(ally: .companion)

        case "skill":
            guard CombatRules.isSkillReady(for: .companion, in: encounter) else { return nil }
            switch CombatRules.skill(for: .companion)?.kind {
            case .heal:
                if case .ally(let member) = target { return .healSkill(ally: member) }
                return .healSkill(ally: .companion)
            case .damage:
                if case .foe(let id) = target { return .damageSkill(foe: id) }
                return encounter.livingFoes.first.map { .damageSkill(foe: $0.id) }
            case nil:
                return nil
            }

        case "flee":
            return .flee

        default:
            return nil
        }
    }
}
