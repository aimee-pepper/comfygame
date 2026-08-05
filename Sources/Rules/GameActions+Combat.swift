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

    /// Consumables carried into the world. Milestone 5 gives you ways to get them.
    var usableItems: [ItemStack] {
        (state.worlds.activeRun?.satchelItems.stacks ?? []).filter {
            $0.identified && ContentCatalog.shared.item($0.catalogID)?.kind == .consumable
        }
    }

    /// Take the acting combatant's turn, then let everything automatic run until it's your move
    /// again or the fight is over.
    ///
    /// A finished fight is deliberately *not* dismissed here. The result stays on screen — who fell,
    /// what it cost — until the player taps through it. Clearing the board the instant the last foe
    /// drops would swallow the one moment the fight was building to.
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
            endRunWithPartialHaul(reason: "You were carried home.")
        }
    }

    private func label(for action: CombatAction) -> String {
        switch action {
        case .attack: "attack"
        case .damageSkill, .healSkill: "skill"
        case .useItem: "item"
        case .flee: "flee"
        }
    }

    // MARK: - Party screen (out of combat only)

    /// Reordering rules is the whole point of gambits, so it must be impossible to do it mid-fight —
    /// a locked decision, enforced here rather than only hidden in the UI.
    var canEditGambits: Bool { activeEncounter == nil }

    func gambits(for owner: Combatant) -> [GambitPieceID] {
        owner == .binder ? state.base.binderGambits : state.base.companion.gambits
    }

    /// One accessor for both rule lists, so editing can't accidentally diverge between them.
    private func withGambits(_ owner: Combatant, _ body: @escaping (inout [GambitPieceID]) -> Void) -> (inout GameState) -> Void {
        { state in
            if owner == .binder { body(&state.base.binderGambits) } else { body(&state.base.companion.gambits) }
        }
    }

    func moveGambit(from source: IndexSet, to destination: Int, for owner: Combatant = .companion) {
        guard canEditGambits else { return }
        mutate("reorder gambits", flush: true, withGambits(owner) { $0.move(fromOffsets: source, toOffset: destination) })
    }

    func removeGambit(at offsets: IndexSet, for owner: Combatant = .companion) {
        guard canEditGambits else { return }
        mutate("remove gambit", withGambits(owner) { $0.remove(atOffsets: offsets) })
    }

    func addGambit(_ id: GambitPieceID, for owner: Combatant = .companion) {
        guard canEditGambits, state.base.ownedGambitPieces.contains(id) else { return }
        mutate("add gambit", withGambits(owner) { list in
            guard !list.contains(id) else { return }
            list.append(id)
        })
    }

    /// Rules beyond this index are owned but inactive — the slot count is the progression.
    var activeGambitSlots: Int { GambitEngine.availableSlots(in: state) }
}
