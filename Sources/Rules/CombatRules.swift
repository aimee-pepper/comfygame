import Foundation

/// How a fight resolves.
///
/// Turn-based to the bone: nothing advances except by a call from a player action. The party acts
/// in a fixed rotation, then the enemies (PLACEHOLDER — there's no speed stat in v0). Every roll
/// comes off the run's saved RNG, so a force-quit mid-round resumes to the same fight rather than
/// re-rolling in anyone's favour.
enum CombatRules {

    // MARK: Starting a fight

    static func makeEncounter(id: InstanceID, foes: [FoeState]) -> EncounterState {
        EncounterState(
            id: id,
            foes: foes,
            // Party first, then enemies, and the order is fixed for the whole fight — a foe dying
            // mid-round must never shift whose turn it is.
            order: [.binder, .companion] + foes.map { Combatant.foe($0.id) },
            log: [foes.count == 1 ? "Something notices you." : "They close in around you."]
        )
    }

    // MARK: Party numbers

    static func binderAttack(in state: GameState) -> Int { Tuning.Encounter.binderAttack }

    static func companionAttack(in state: GameState) -> Int {
        Tuning.Encounter.companionBaseAttack
            + state.base.companion.weaponTier * Tuning.Encounter.attackPerWeaponTier
    }

    /// Armour softens what lands on the party. Never below a floor — armour shouldn't make a fight
    /// unloseable, just survivable.
    static func damageTaken(_ raw: Int, by actor: Combatant, in state: GameState) -> Int {
        guard actor == .companion else { return max(Tuning.Encounter.minimumDamage, raw) }
        let reduced = raw - state.base.companion.armorTier * Tuning.Encounter.defencePerArmorTier
        return max(Tuning.Encounter.minimumDamage, reduced)
    }

    static func skill(for actor: Combatant) -> SkillDef? {
        switch actor {
        case .binder: ContentCatalog.shared.skill(ownedBy: .binder)
        case .companion: ContentCatalog.shared.skill(ownedBy: .companion)
        case .foe: nil
        }
    }

    static func skillCooldown(for actor: Combatant, in encounter: EncounterState) -> Int {
        switch actor {
        case .binder: encounter.binderSkillCooldown
        case .companion: encounter.companionSkillCooldown
        case .foe: 0
        }
    }

    static func isSkillReady(for actor: Combatant, in encounter: EncounterState) -> Bool {
        skill(for: actor) != nil && skillCooldown(for: actor, in: encounter) == 0
    }

    static func health(of actor: Combatant, in run: WorldRun) -> (current: Int, max: Int) {
        switch actor {
        case .binder: (run.binderHP, Tuning.Encounter.binderMaxHP)
        case .companion: (run.companionHP, Tuning.Encounter.companionMaxHP)
        case .foe(let id):
            run.activeEncounter?.foes.first { $0.id == id }.map { ($0.currentHP, $0.maxHP) } ?? (0, 1)
        }
    }

    static func isAlive(_ actor: Combatant, in run: WorldRun) -> Bool {
        health(of: actor, in: run).current > 0
    }

    // MARK: Resolving one action

    /// Applies an action and hands the turn on. The only way an encounter advances.
    static func perform(_ action: CombatAction, by actor: Combatant, in state: inout GameState) {
        guard var run = state.worlds.activeRun, var encounter = run.activeEncounter, encounter.outcome == nil
        else { return }

        switch action {
        case .attack(let foeID):
            strike(foeID, damage: baseAttack(of: actor, in: state), by: actor, run: &run, encounter: &encounter)

        case .damageSkill(let foeID):
            if let skill = skill(for: actor), isSkillReady(for: actor, in: encounter) {
                strike(foeID, damage: skill.power, by: actor, run: &run, encounter: &encounter, verb: skill.name)
                setCooldown(skill.cooldownRounds, for: actor, in: &encounter)
            }

        case .healSkill(let ally):
            if let skill = skill(for: actor), isSkillReady(for: actor, in: encounter) {
                let amount = roll(around: skill.power, run: &run)
                heal(ally, by: amount, run: &run, encounter: &encounter, source: skill.name, healer: actor)
                setCooldown(skill.cooldownRounds, for: actor, in: &encounter)
            }

        case .useItem(let stackID, let ally):
            useItem(stackID, on: ally, run: &run, encounter: &encounter)

        case .flee:
            // Always succeeds — it costs the run, not a dice roll.
            run.stability = max(0, run.stability - Tuning.Encounter.fleeStabilityCost)
            encounter.note("You break away. The world notices.")
            encounter.outcome = .fled
        }

        // The FF12 rule: an override covers that turn and then hands control back.
        if actor == .companion { encounter.isCompanionOverridden = false }

        run.activeEncounter = encounter
        state.worlds.activeRun = run
        if encounter.outcome == nil { advanceTurn(in: &state) }
        checkOutcome(in: &state)
    }

    private static func baseAttack(of actor: Combatant, in state: GameState) -> Int {
        switch actor {
        case .binder: binderAttack(in: state)
        case .companion: companionAttack(in: state)
        case .foe(let id):
            state.worlds.activeRun?.activeEncounter?.foes.first { $0.id == id }?.stats.attack ?? 1
        }
    }

    private static func strike(_ foeID: InstanceID,
                               damage: Int,
                               by actor: Combatant,
                               run: inout WorldRun,
                               encounter: inout EncounterState,
                               verb: String? = nil) {
        guard let index = encounter.foes.firstIndex(where: { $0.id == foeID }), encounter.foes[index].isAlive
        else { return }

        let amount = roll(around: damage, run: &run)
        encounter.foes[index].currentHP = max(0, encounter.foes[index].currentHP - amount)
        let name = encounter.foes[index].stats.displayName
        let who = actorName(actor, encounter: encounter)
        encounter.note(verb.map { "\(who) — \($0) — hits \(name) for \(amount)." }
            ?? "\(who) hits \(name) for \(amount).")
        if !encounter.foes[index].isAlive { encounter.note("\(name) goes down.") }
    }

    private static func heal(_ ally: Combatant,
                             by amount: Int,
                             run: inout WorldRun,
                             encounter: inout EncounterState,
                             source: String,
                             healer: Combatant) {
        switch ally {
        case .binder: run.binderHP = min(Tuning.Encounter.binderMaxHP, run.binderHP + amount)
        case .companion: run.companionHP = min(Tuning.Encounter.companionMaxHP, run.companionHP + amount)
        case .foe: return
        }
        encounter.note("\(actorName(healer, encounter: encounter)) — \(source) — restores \(amount) to \(actorName(ally, encounter: encounter)).")
    }

    private static func useItem(_ stackID: InstanceID,
                                on ally: Combatant,
                                run: inout WorldRun,
                                encounter: inout EncounterState) {
        guard let index = run.satchelItems.stacks.firstIndex(where: { $0.id == stackID }),
              let item = ContentCatalog.shared.item(run.satchelItems.stacks[index].catalogID),
              item.kind == .consumable
        else { return }

        heal(ally, by: Tuning.Encounter.consumableHealAmount, run: &run, encounter: &encounter,
             source: item.name, healer: ally)
        if run.satchelItems.stacks[index].count > 1 {
            run.satchelItems.stacks[index].count -= 1
        } else {
            run.satchelItems.stacks.remove(at: index)
        }
    }

    private static func setCooldown(_ rounds: Int, for actor: Combatant, in encounter: inout EncounterState) {
        switch actor {
        case .binder: encounter.binderSkillCooldown = rounds
        case .companion: encounter.companionSkillCooldown = rounds
        case .foe: break
        }
    }

    /// Damage and healing wobble a little so fights aren't arithmetic. Off the run's saved RNG.
    private static func roll(around power: Int, run: inout WorldRun) -> Int {
        let spread = max(1, Int((Double(power) * Tuning.Encounter.damageVariance).rounded()))
        return max(Tuning.Encounter.minimumDamage, power + run.rng.int(in: -spread...spread))
    }

    static func actorName(_ actor: Combatant, encounter: EncounterState) -> String {
        switch actor {
        case .binder: "You"
        case .companion: "Quill" // PLACEHOLDER — reads from CompanionState once the party grows
        case .foe(let id): encounter.foes.first { $0.id == id }?.stats.displayName ?? "Something"
        }
    }

    // MARK: Turn order

    /// Moves to the next living combatant, ticking the round over when the rotation wraps.
    static func advanceTurn(in state: inout GameState) {
        guard var run = state.worlds.activeRun, var encounter = run.activeEncounter else { return }

        for step in 1...max(1, encounter.order.count) {
            let next = (encounter.turnIndex + step) % encounter.order.count
            if next <= encounter.turnIndex { startNewRound(&encounter) }
            encounter.turnIndex = next
            if isAlive(encounter.order[next], in: withEncounter(encounter, on: run)) { break }
        }

        run.activeEncounter = encounter
        state.worlds.activeRun = run
    }

    private static func withEncounter(_ encounter: EncounterState, on run: WorldRun) -> WorldRun {
        var copy = run
        copy.activeEncounter = encounter
        return copy
    }

    private static func startNewRound(_ encounter: inout EncounterState) {
        encounter.roundNumber += 1
        encounter.binderSkillCooldown = max(0, encounter.binderSkillCooldown - 1)
        encounter.companionSkillCooldown = max(0, encounter.companionSkillCooldown - 1)
    }

    /// Whether the current actor is waiting on the player rather than acting for itself.
    static func needsPlayerInput(_ state: GameState) -> Bool {
        guard let encounter = state.worlds.activeRun?.activeEncounter, encounter.outcome == nil else { return false }
        switch encounter.current {
        case .binder:
            // Manual until you've bought the right to automate yourself, and still manual if you
            // bought it and set no rules — an empty list shouldn't mean "stand there".
            return !state.base.hasAutomateSelfUnlock || state.base.binderGambits.isEmpty
        case .companion: return encounter.isCompanionOverridden
        case .foe: return false
        }
    }

    /// Runs everything that acts for itself — foes, and the companion via its gambits — until the
    /// player is on the clock again or the fight is over.
    ///
    /// Bounded rather than `while true`: a rule that somehow declines to act must not hang the app.
    static func runAutomaticTurns(in state: inout GameState) {
        var guardCount = 0
        while !needsPlayerInput(state),
              state.worlds.activeRun?.activeEncounter?.outcome == nil,
              guardCount < Tuning.Encounter.maxAutomaticTurnsPerInput {
            guardCount += 1
            guard let encounter = state.worlds.activeRun?.activeEncounter else { return }
            let actor = encounter.current

            switch actor {
            case .foe:
                performFoeTurn(actor, in: &state)
            case .companion, .binder:
                performAutomatedTurn(actor, in: &state)
            }
        }
    }

    /// Foes attack whoever is standing. PLACEHOLDER AI — the design's automation interest is on
    /// the player's side of the fight, not this one.
    private static func performFoeTurn(_ actor: Combatant, in state: inout GameState) {
        guard var run = state.worlds.activeRun, var encounter = run.activeEncounter,
              let foeID = actor.foeID, let foe = encounter.foes.first(where: { $0.id == foeID })
        else { return }

        let targets: [Combatant] = [.binder, .companion].filter { isAlive($0, in: run) }
        guard let target = run.rng.pick(targets) else {
            run.activeEncounter = encounter
            state.worlds.activeRun = run
            checkOutcome(in: &state)
            return
        }

        let raw = roll(around: foe.stats.attack, run: &run)
        let amount = damageTaken(raw, by: target, in: state)
        switch target {
        case .binder: run.binderHP = max(0, run.binderHP - amount)
        case .companion: run.companionHP = max(0, run.companionHP - amount)
        case .foe: break
        }
        encounter.note("\(foe.stats.displayName) hits \(actorName(target, encounter: encounter).lowercased()) for \(amount).")

        run.activeEncounter = encounter
        state.worlds.activeRun = run
        advanceTurn(in: &state)
        checkOutcome(in: &state)
    }

    private static func performAutomatedTurn(_ actor: Combatant, in state: inout GameState) {
        guard let run = state.worlds.activeRun, let encounter = run.activeEncounter else { return }

        if let decision = GambitEngine.decide(for: actor, in: state) {
            state.worlds.activeRun?.activeEncounter?.note(
                "\(actorName(actor, encounter: encounter)): \(GambitEngine.describe(decision.piece))"
            )
            perform(decision.action, by: actor, in: &state)
        } else {
            // No rule matched, or every matching rule wanted something unavailable. Standing there
            // is the honest outcome — it's what makes rule ORDER matter, and it's visible.
            state.worlds.activeRun?.activeEncounter?.note("\(actorName(actor, encounter: encounter)) waits — no rule fits.")
            advanceTurn(in: &state)
        }
    }

    // MARK: Ending

    static func checkOutcome(in state: inout GameState) {
        guard var run = state.worlds.activeRun, var encounter = run.activeEncounter, encounter.outcome == nil
        else { return }

        if encounter.isResolved {
            encounter.outcome = .victory
            encounter.note("Nothing left standing.")
        } else if run.binderHP <= 0 && run.companionHP <= 0 {
            // No death state in v0 — you're carried home with what survived.
            encounter.outcome = .defeated
            encounter.note("You can't go on.")
        }
        run.activeEncounter = encounter
        state.worlds.activeRun = run
    }

    /// Closes out a finished fight: loot, bestiary, and taking the defeated off the grid.
    ///
    /// Defeated foes must leave the map — a foe shares its id with the `WorldEnemy` that spawned
    /// it, and leaving it standing on the player's tile would re-trigger the same fight forever.
    @discardableResult
    static func conclude(in state: inout GameState) -> [WorldRules.Event] {
        guard var run = state.worlds.activeRun,
              let encounter = run.activeEncounter,
              let outcome = encounter.outcome
        else { return [] }

        var events: [WorldRules.Event] = []

        switch outcome {
        case .victory:
            let defeated = Set(encounter.foes.map(\.id))
            run.enemies.removeAll { defeated.contains($0.id) }
            state.reality.lifetime.encountersWon += 1
            // Loot: rolled off the world's own yield table, so what you win reflects where you are.
            for foe in encounter.foes {
                let tier = ContentCatalog.shared.creature(foe.creatureID)?.tier ?? 1
                if let resource = run.rng.pickWeighted(BookRules.yieldTable(for: run.book)) {
                    run.satchel.add(tier, of: resource)
                    state.reality.discovery.recordResource(resource, runIndex: run.runIndex)
                }
                // Curios drop unidentified — this is where keys enter the world, one identify and
                // one long walk before they open anything.
                if run.rng.chance(Tuning.Economy.curioDropChance) {
                    let curios = ContentCatalog.shared.items.filter { $0.kind == .curio }
                        .map(\.id).sorted { $0.rawValue < $1.rawValue }
                    if let curio = run.rng.pick(curios) {
                        let stack = ItemStack(id: InstanceID(rawValue: run.rng.next()),
                                              catalogID: curio, count: 1, identified: false)
                        // A full satchel refuses loot rather than silently swallowing it.
                        if run.satchelItems.add(stack) {
                            let name = ContentCatalog.shared.item(curio)?.unidentifiedName ?? "Something odd"
                            events.append(.pickedUpItem(name))
                        } else {
                            events.append(.satchelFull(ContentCatalog.shared.item(curio)?.unidentifiedName ?? "Something odd"))
                        }
                    }
                }
            }

        case .fled:
            state.reality.lifetime.encountersFled += 1
            // Retreat to where you came from, and hold off bumps for a turn — otherwise the foe
            // you just fled walks straight back into you and "flee" means nothing.
            if let previous = run.previousPosition, WorldRules.canEnter(previous, in: run.map),
               !run.enemies.contains(where: { $0.position == previous }) {
                run.playerPosition = previous
            }
            run.encounterGraceTurns = Tuning.Encounter.fleeGraceTurns

        case .defeated:
            break // the run ends; the caller banks a partial haul
        }

        run.activeEncounter = nil
        state.worlds.activeRun = run
        return events
    }
}
