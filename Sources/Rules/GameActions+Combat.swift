import Foundation

/// Player actions inside an encounter.
///
/// Every one flushes to disk: mid-encounter is the hardest resume case in the game, and the one the
/// acceptance criteria name. One tap, one saved fight state.
extension GameStore {

    var activeEncounter: EncounterState? { state.worlds.activeRun?.activeEncounter }

    /// Whose turn it is, when the game is waiting on the player.
    var actingCombatant: Combatant? {
        guard let encounter = activeEncounter, encounter.outcome == nil else { return nil }
        return CombatRules.needsPlayerInput(state) ? encounter.current : nil
    }

    var isSkillReady: Bool {
        guard let encounter = activeEncounter, let actor = actingCombatant else { return false }
        return CombatRules.isSkillReady(for: actor, in: encounter)
    }

    var currentSkill: SkillDef? { actingCombatant.flatMap { CombatRules.skill(for: $0) } }

    /// **Everything whoever's acting could do**, and which of those are up this turn.
    var actorSkills: [SkillDef] {
        actingCombatant.map { CombatRules.skills(for: $0, in: state) } ?? []
    }

    var readySkills: [SkillDef] {
        guard let encounter = activeEncounter, let actor = actingCombatant else { return [] }
        return CombatRules.skills(for: actor, in: state).filter { CombatRules.isReady($0, for: actor, in: encounter) }
    }

    var hasAnyReadySkill: Bool { !readySkills.isEmpty }

    /// Rounds until a given skill is up again, for the list.
    func cooldown(of skill: SkillDef) -> Int {
        guard let encounter = activeEncounter, let actor = actingCombatant else { return 0 }
        return CombatRules.cooldown(of: skill, for: actor, in: encounter)
    }

    /// Consumables carried into the world. Milestone 5 gives you ways to get them.
    var usableItems: [ItemStack] {
        (state.worlds.activeRun?.satchelItems.stacks ?? []).filter {
            guard $0.identified,
                  let effect = ContentCatalog.shared.item($0.catalogID)?.consumable?.effect
            else { return false }
            return [.heal, .clearPoison, .clearElemental, .clearAnyStatus, .preventStatus,
                    .coatPoison, .coatBurn, .coatBleed, .coatDazzle].contains(effect)
        }
    }

    /// Take the acting combatant's turn, then let everything automatic run until it's your move
    /// again or the fight is over.
    ///
    /// A finished fight is deliberately *not* dismissed here. The result stays on screen — who fell,
    /// what it cost — until the player taps through it. Clearing the board the instant the last foe
    /// drops would swallow the one moment the fight was building to.
    /// **What a second tap means: "you pick."**
    ///
    /// Aimee, 7 Aug: *"if you just hit the attack button again it auto attacks either the first mob
    /// or it uses whatever self applied gambit logic exists if there is any."*
    ///
    /// Choosing between four identical wolves is not a decision, it's a tap — and it's the tap you
    /// make most often in the game. So the second press commits, and what it commits to is, in
    /// order:
    ///
    ///  1. **The skill you already picked**, if one is pending. You chose the verb; the noun is the
    ///     part that wasn't worth asking about.
    ///  2. **Your own rule list**, if you've learned to write one. This is the nice one: the game
    ///     already has a system for *act without me*, and the second tap is exactly that question,
    ///     so it should be answered by the rules you wrote rather than by a hidden default.
    ///  3. **The first thing standing**, which is what the list is showing you anyway.
    func defaultCombatAction(pendingSkill: SkillID? = nil) -> CombatAction? {
        guard let encounter = activeEncounter, let first = encounter.livingFoes.first else { return nil }
        if let pendingSkill { return .skill(pendingSkill, foe: first.id) }
        if let decided = GambitEngine.decide(for: .binder, in: state)?.action { return decided }
        return .attack(foe: first.id)
    }

    /// Whether a second tap would hand the turn to your own rules rather than to the default —
    /// so the prompt can say which, instead of the player having to find out by pressing it.
    var wouldActOnOwnRules: Bool {
        GambitEngine.decide(for: .binder, in: state) != nil
    }

    func takeCombatAction(_ action: CombatAction) {
        guard let actor = actingCombatant else { return }
        mutate("combat: \(label(for: action))", flush: true) { state in
            CombatRules.perform(action, by: actor, in: &state)
            CombatRules.runAutomaticTurns(in: &state)
        }
    }

    /// Hand the companion's *next* turn to the player. The FF12 rule: an override is for that turn
    /// only, and it clears once used.
    ///
    /// Deliberately armed from your own turn rather than interrupting theirs — the companion is
    /// supposed to fight unattended by default, and a mandatory "let it act?" tap every round would
    /// quietly undo that.
    func toggleCompanionOverride() {
        guard activeEncounter?.outcome == nil else { return }
        mutate("companion override", flush: true) { state in
            state.worlds.activeRun?.activeEncounter?.isCompanionOverridden.toggle()
        }
    }

    /// Dismiss a finished fight and take its consequences.
    func endEncounterIfFinished() {
        guard let encounter = activeEncounter, let outcome = encounter.outcome else { return }

        var events: [WorldRules.Event] = []
        mutate("encounter \(outcome.rawValue)", flush: true) { state in
            events = CombatRules.conclude(in: &state)
        }
        if !events.isEmpty { recentEvents = events }

        if outcome == .defeated {
            // No death state in v0 — you're carried home with a fraction of the haul.
            endRunWithPartialHaul(reason: "You were carried home.", kind: .defeat)
        }
    }

    private func label(for action: CombatAction) -> String {
        switch action {
        case .attack: "attack"
        case .skill(let id, _, _): "skill \(id.rawValue)"
        case .damageSkill, .healSkill: "skill"
        case .useItem: "item"
        case .flee: "flee"
        }
    }

    // MARK: - Party screen (out of combat only)

    /// Reordering rules is the whole point of gambits, so it must be impossible to do it mid-fight —
    /// a locked decision, enforced here rather than only hidden in the UI.
    var canEditGambits: Bool { activeEncounter == nil }

    func gambits(for owner: Combatant) -> [GambitRule] {
        guard let index = owner.rosterIndex else { return state.base.binderGambits }
        return state.base.roster.indices.contains(index) ? state.base.roster[index].gambits : []
    }

    /// Components you own, of one kind — what the rule builder can offer you.
    func ownedComponents(_ kind: GambitComponentDef.Kind) -> [GambitComponentDef] {
        ContentCatalog.shared.components(kind)
            .filter { state.base.ownedGambitComponents.contains($0.id) }
    }

    /// Whether you know enough to write a condition at all. Until you've learned a property, a
    /// comparator and a threshold, rules are just "subject → action".
    var canWriteConditions: Bool {
        !ownedComponents(.property).isEmpty
            && !ownedComponents(.comparator).isEmpty
            && !ownedComponents(.threshold).isEmpty
    }

    /// One accessor for both rule lists, so editing can't accidentally diverge between them.
    /// Whose rule list is being edited. **Everybody at the fire has their own** — it used to be
    /// "the Binder's, or the companion's", which was fine while there was one of them.
    private func withGambits(_ owner: Combatant, _ body: @escaping (inout [GambitRule]) -> Void) -> (inout GameState) -> Void {
        { state in
            guard let index = owner.rosterIndex else { return body(&state.base.binderGambits) }
            guard state.base.roster.indices.contains(index) else { return }
            body(&state.base.roster[index].gambits)
        }
    }

    func moveGambit(from source: IndexSet, to destination: Int, for owner: Combatant = .companion(0)) {
        guard canEditGambits else { return }
        mutate("reorder rules", flush: true, withGambits(owner) { $0.move(fromOffsets: source, toOffset: destination) })
    }

    func removeGambit(at offsets: IndexSet, for owner: Combatant = .companion(0)) {
        guard canEditGambits else { return }
        mutate("remove rule", withGambits(owner) { $0.remove(atOffsets: offsets) })
    }

    /// Write a new rule from components you own. Refused if any part isn't yours — the grammar is
    /// gated by what you've learned, which is the whole point of it being a grammar.
    @discardableResult
    /// Change one segment of a rule in place. The whole point of the editor is that you never
    /// leave the list to do this.
    func setGambitPart(_ ruleID: InstanceID, kind: GambitComponentDef.Kind,
                       to component: GambitComponentID?, for owner: Combatant = .companion(0)) {
        mutate("edit rule", flush: true, withGambits(owner) { rules in
            guard let index = rules.firstIndex(where: { $0.id == ruleID }) else { return }
            switch kind {
            case .subject: if let component { rules[index].subject = component }
            case .action: if let component { rules[index].action = component }
            case .property: rules[index].property = component
            case .comparator: rules[index].comparator = component
            case .threshold: rules[index].threshold = component
            }
        })
    }

    /// Switch a rule off without losing it, so an order can be tested rather than rebuilt.
    func setGambitEnabled(_ ruleID: InstanceID, _ isEnabled: Bool, for owner: Combatant = .companion(0)) {
        mutate("toggle rule", flush: true, withGambits(owner) { rules in
            guard let index = rules.firstIndex(where: { $0.id == ruleID }) else { return }
            rules[index].isEnabled = isEnabled
        })
    }

    /// Add an unconditional rule using whatever the player owns, ready to be edited in place.
    ///
    /// Deliberately not a blank: a rule with no subject and no action can't be rendered as a
    /// sentence, and a half-sentence is harder to fix than a wrong one.
    @discardableResult
    func addBlankGambit(for owner: Combatant = .companion(0)) -> Bool {
        guard let subject = ownedComponents(.subject).first,
              let action = ownedComponents(.action).first
        else { return false }
        return addGambit(GambitRule(id: InstanceID(rawValue: UInt64(state.meta.mutationCount) &+ 1),
                                    subject: subject.id, action: action.id), for: owner)
    }

    func addGambit(_ rule: GambitRule, for owner: Combatant = .companion(0)) -> Bool {
        guard canEditGambits, rule.isWritable(with: state.base.ownedGambitComponents) else { return false }
        mutate("write a rule", flush: true, withGambits(owner) { list in
            var written = rule
            written.id = InstanceID(rawValue: UInt64(list.count + 1) &* 2_654_435_761 &+ UInt64(list.count))
            list.append(written)
        })
        return true
    }

    /// Rules beyond this index are owned but inactive — the slot count is the progression.
    /// **Whose list this is decides how long it may be.** Wit governs rule length, so the number
    /// differs per person — which is the whole reason the stat exists.
    func activeGambitSlots(for actor: Combatant) -> Int {
        GambitEngine.availableSlots(for: actor, in: state)
    }
}
