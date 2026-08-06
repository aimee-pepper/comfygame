import Foundation

/// How a fight resolves.
///
/// Turn-based to the bone: nothing advances except by a call from a player action. The party acts
/// in a fixed rotation, then the enemies (PLACEHOLDER — there's no speed stat in v0). Every roll
/// comes off the run's saved RNG, so a force-quit mid-round resumes to the same fight rather than
/// re-rolling in anyone's favour.
enum CombatRules {

    // MARK: Starting a fight

    /// **Turn order comes off initiative** (creature-system-spec §7), not off a fixed party-first
    /// rotation. Sleek, small and lightly armoured goes before you; a huge armoured thing goes after.
    /// Anything with far reach strikes first regardless — length beats speed at the moment of
    /// contact.
    ///
    /// The order is resolved once and stored, so a foe dying mid-round can't shift whose turn it is.
    static func makeEncounter(id: InstanceID, foes: [FoeState], rng: inout SeededRNG) -> EncounterState {
        var ranked: [(actor: Combatant, initiative: Int, first: Bool)] = [
            (.binder, Tuning.Encounter.binderInitiative, false),
            (.companion, Tuning.Encounter.companionInitiative, false)
        ]
        for foe in foes {
            let slow = foe.stats.damageKind == .crush ? Tuning.Encounter.crushInitiativePenalty : 0
            ranked.append((.foe(foe.id), foe.stats.initiative - slow, foe.stats.strikesFirst))
        }
        // Ties broken off the run's own stream rather than by declaration order, so two identical
        // animals don't always act in the order they happened to be placed.
        let jittered = ranked.map { ($0, rng.int(in: 0...99)) }
        let order = jittered
            .sorted {
                if $0.0.first != $1.0.first { return $0.0.first }
                if $0.0.initiative != $1.0.initiative { return $0.0.initiative > $1.0.initiative }
                return $0.1 > $1.1
            }
            .map(\.0.actor)

        return EncounterState(
            id: id,
            foes: foes,
            order: order,
            log: [foes.count == 1 ? "A \(foes[0].stats.displayName) notices you."
                                  : "They close in around you."]
        )
    }

    // MARK: Party numbers

    /// **What each of them is wearing.** The Binder has its own slots (Aimee, 5 Aug) — it's half
    /// the party, and an attack that was a `Tuning` constant meant the damage-type matchup never
    /// reached the player's own turns, which is the whole point of giving weapons a type.
    static func equipped(_ slot: GearSlot, for actor: Combatant, in state: GameState) -> EquippedPiece? {
        switch actor {
        case .binder: state.base.binderEquipped[slot]
        case .companion: state.base.companion.equipped[slot]
        case .foe: nil
        }
    }

    static func binderAttack(in state: GameState) -> Int {
        Tuning.Encounter.binderAttack
            + (equipped(.weapon, for: .binder, in: state)?.effectiveTier ?? 0)
                * Tuning.Encounter.attackPerWeaponTier
    }

    /// **What this one is swinging.** Each party member's own weapon decides the matchup, so
    /// carrying a piercing blade while Quill carries a rending one is a real answer to a world that
    /// grew both plated and furred things.
    static func damageKind(for actor: Combatant, in state: GameState) -> DamageKind? {
        equipped(.weapon, for: actor, in: state)?.gear?.damage
    }

    static func reach(for actor: Combatant, in state: GameState) -> Reach {
        equipped(.weapon, for: actor, in: state)?.gear?.reach ?? .close
    }

    /// **How well a damage type does against what a creature is wearing** (combat-depth-spec §1).
    ///
    /// | | hard covering | thick soft covering |
    /// |---|---|---|
    /// | **pierce** | strong — finds the gaps | weak — passes through without doing much |
    /// | **crush** | strong — force doesn't care about plate | weak — absorbed by padding |
    /// | **rend** | weak — can't get purchase | strong — tears |
    ///
    /// This is the change that closes the loop: kill a piercing creature, butcher its fang, carry a
    /// piercing weapon, and it's good against the armoured things and wasteful against the soft
    /// ones. **You read it off the covering word the encounter already prints.**
    static func effectiveness(of kind: DamageKind, against covering: Covering) -> Double {
        let hard = covering.armourValue / Tuning.Pressure.scaleMaximum
        let padded = covering.insulation / Tuning.Pressure.scaleMaximum
        let t = Tuning.Encounter.self

        let multiplier: Double = switch kind {
        case .pierce, .crush: 1 + hard * t.matchupBonus - padded * t.matchupPenalty
        case .rend: 1 + padded * t.matchupBonus - hard * t.matchupPenalty
        }
        return max(t.minimumMatchup, multiplier)
    }

    static func companionAttack(in state: GameState) -> Int {
        Tuning.Encounter.companionBaseAttack
            + state.base.companion.weaponTier * Tuning.Encounter.attackPerWeaponTier
    }

    /// Armour softens what lands on the party. Never below a floor — armour shouldn't make a fight
    /// unloseable, just survivable.
    ///
    /// `armourIgnored` is what a piercing attack goes straight through, which is the whole reason
    /// the weapon triangle exists: the same armour is worth more against some things than others.
    static func damageTaken(_ raw: Int, by actor: Combatant, in state: GameState,
                            armourIgnored: Double = 0) -> Int {
        // **Everything protective counts**, not just the body piece — a helm and boots are armour
        // too, and only the companion's chest plate used to be read at all.
        let tier = GearSlot.allCases
            .filter(\.isProtective)
            .reduce(0) { $0 + (equipped($1, for: actor, in: state)?.effectiveTier ?? 0) }
        let armour = Double(tier * Tuning.Encounter.defencePerArmorTier)
        let effective = Int((armour * (1 - armourIgnored)).rounded())
        return max(Tuning.Encounter.minimumDamage, raw - effective)
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
            strike(foeID, damage: baseAttack(of: actor, in: state), by: actor,
                   kind: damageKind(for: actor, in: state), run: &run, encounter: &encounter)

        case .damageSkill(let foeID):
            if let skill = skill(for: actor), isSkillReady(for: actor, in: encounter) {
                strike(foeID, damage: skill.power, by: actor, kind: damageKind(for: actor, in: state),
                       run: &run, encounter: &encounter, verb: skill.name)
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
                               kind: DamageKind?,
                               run: inout WorldRun,
                               encounter: inout EncounterState,
                               verb: String? = nil) {
        guard let index = encounter.foes.firstIndex(where: { $0.id == foeID }), encounter.foes[index].isAlive
        else { return }

        let foe = encounter.foes[index]
        let name = foe.stats.displayName
        let who = actorName(actor, encounter: encounter)

        // **Sleek and small is hard to hit.** A miss is the price of chasing something built to run.
        if run.rng.chance(foe.stats.evasion) {
            encounter.note("\(who) \(actor == .binder ? "swing" : "swings") at \(name) and find\(actor == .binder ? "" : "s") nothing there.")
            return
        }

        // **The matchup.** What you're swinging against what it's wearing, then armour on what's
        // left — and a piercing weapon goes through a share of that armour rather than all of it.
        let matchup = kind.map { effectiveness(of: $0, against: foe.traits?.covering ?? Covering()) } ?? 1
        let raw = Int((Double(roll(around: damage, run: &run)) * matchup).rounded())
        let ignored = kind == .pierce ? Tuning.Encounter.pierceArmourIgnored : 0
        let armour = Int((Double(foe.stats.armour) * (1 - ignored)).rounded())
        let amount = max(Tuning.Encounter.minimumDamage, raw - armour)
        encounter.foes[index].currentHP = max(0, encounter.foes[index].currentHP - amount)

        let soaked = raw - amount
        // "You hits" — the log addresses the Binder in the second person, so the verb has to agree.
        let hits = actor == .binder ? "hit" : "hits"
        let note = verb.map { "\(who) — \($0) — \(hits) \(name) for \(amount)." }
            ?? "\(who) \(hits) \(name) for \(amount)."
        encounter.note(soaked > 1 ? note + " Its \(armourWord(for: foe)) takes the rest." : note)

        // Rending tears: the wound goes on costing it after the blow. This is what finally makes
        // `bleedRounds` live on the foe's side of the fight rather than only on yours.
        if kind == .rend, encounter.foes[index].isAlive {
            encounter.foes[index].bleedRounds = Tuning.Encounter.bleedRounds
        }

        // **Warning colours are honest.** Hitting something that advertises costs you.
        if foe.stats.retaliation > 0, encounter.foes[index].isAlive {
            hurt(actor, by: foe.stats.retaliation, run: &run, encounter: &encounter)
            encounter.note("\(name.capitalisedSentence) is not safe to touch — \(foe.stats.retaliation) back.")
        }
        if !encounter.foes[index].isAlive { encounter.note("\(name.capitalisedSentence) goes down.") }
    }

    private static func armourWord(for foe: FoeState) -> String {
        guard let traits = foe.traits else { return "hide" }
        if traits.covering.hardness > 70 { return traits.finish.schiller > 30 ? "shell" : "plate" }
        if traits.covering.length > 55 { return "pelt" }
        return "hide"
    }

    /// Damage onto one of the party, wherever it comes from.
    private static func hurt(_ target: Combatant,
                             by amount: Int,
                             run: inout WorldRun,
                             encounter: inout EncounterState) {
        switch target {
        case .binder: run.binderHP = max(0, run.binderHP - amount)
        case .companion: run.companionHP = max(0, run.companionHP - amount)
        case .foe(let id):
            if let index = encounter.foes.firstIndex(where: { $0.id == id }) {
                encounter.foes[index].currentHP = max(0, encounter.foes[index].currentHP - amount)
            }
        }
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
        // Through the bin rather than by poking `count`, so a stack that also carries samples
        // can't have its count drift away from what's actually in it.
        _ = run.satchelItems.stacks[index].removing(1)
        if run.satchelItems.stacks[index].isEmpty {
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

        var roundTurned = false
        for step in 1...max(1, encounter.order.count) {
            let next = (encounter.turnIndex + step) % encounter.order.count
            if next <= encounter.turnIndex { startNewRound(&encounter); roundTurned = true }
            encounter.turnIndex = next
            if isAlive(encounter.order[next], in: withEncounter(encounter, on: run)) { break }
        }

        run.activeEncounter = encounter
        state.worlds.activeRun = run
        if roundTurned { bleed(in: &state) }
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

    /// Wounds that keep costing you, ticked once per round. Run from `advanceTurn` where the round
    /// actually turns over, so a force-quit between rounds can't skip or double a tick.
    private static func bleed(in state: inout GameState) {
        guard var run = state.worlds.activeRun, var encounter = run.activeEncounter else { return }
        let damage = Tuning.Encounter.bleedDamage

        if encounter.binderBleedRounds > 0 {
            encounter.binderBleedRounds -= 1
            run.binderHP = max(0, run.binderHP - damage)
            encounter.note("You're still bleeding — \(damage).")
        }
        if encounter.companionBleedRounds > 0, run.companionHP > 0 {
            encounter.companionBleedRounds -= 1
            run.companionHP = max(0, run.companionHP - damage)
            encounter.note("Quill is still bleeding — \(damage).")
        }
        for index in encounter.foes.indices where encounter.foes[index].bleedRounds > 0
            && encounter.foes[index].isAlive {
            encounter.foes[index].bleedRounds -= 1
            encounter.foes[index].currentHP = max(0, encounter.foes[index].currentHP - damage)
            encounter.note("\(encounter.foes[index].stats.displayName.capitalisedSentence) is still bleeding — \(damage).")
        }

        run.activeEncounter = encounter
        state.worlds.activeRun = run
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

    /// Foes attack whoever is standing, in the manner their traits decided. PLACEHOLDER target
    /// selection — the design's automation interest is on the player's side of the fight.
    ///
    /// **How it hits you is what it is** (creature-system-spec §7): pierce goes through armour,
    /// crush lands heavier, rend leaves a wound that keeps costing you, and something that carries
    /// its own heat or venom isn't stopped by armour at all.
    private static func performFoeTurn(_ actor: Combatant, in state: inout GameState) {
        guard var run = state.worlds.activeRun, var encounter = run.activeEncounter,
              let foeID = actor.foeID, let foe = encounter.foes.first(where: { $0.id == foeID })
        else { return }

        let standing: [Combatant] = [.binder, .companion].filter { isAlive($0, in: run) }
        guard let primary = run.rng.pick(standing) else {
            run.activeEncounter = encounter
            state.worlds.activeRun = run
            checkOutcome(in: &state)
            return
        }

        // Delivery decides how many of you it reaches, and at what cost to each blow.
        let (targets, share): ([Combatant], Double) = switch foe.stats.delivery {
        case .single: ([primary], 1)
        case .multi: (standing, Tuning.Encounter.multiDeliveryShare)
        case .area: (standing, Tuning.Encounter.areaDeliveryShare)
        }

        for target in targets {
            var raw = Double(roll(around: foe.stats.attack, run: &run)) * share
            if foe.stats.damageKind == .crush { raw *= 1 + Tuning.Encounter.crushDamageBonus }

            let amount: Int
            if foe.stats.element != nil {
                // Nothing you're wearing stops caustic, heat or light.
                amount = max(Tuning.Encounter.minimumDamage, Int(raw.rounded()))
            } else {
                let ignored = foe.stats.damageKind == .pierce ? Tuning.Encounter.pierceArmourIgnored : 0
                amount = damageTaken(Int(raw.rounded()), by: target, in: state, armourIgnored: ignored)
            }
            hurt(target, by: amount, run: &run, encounter: &encounter)

            let verb = foe.stats.element.map(elementalVerb) ?? foe.stats.damageKind.verb
            // "You" is a pronoun mid-sentence and "Quill" is a name, so only one of them lowers.
            let whom = target == .binder
                ? actorName(target, encounter: encounter).lowercased()
                : actorName(target, encounter: encounter)
            encounter.note("\(foe.stats.displayName.capitalisedSentence) \(verb) \(whom) for \(amount).")

            // Rend's wound outlives the blow.
            if foe.stats.damageKind == .rend {
                switch target {
                case .binder: encounter.binderBleedRounds = Tuning.Encounter.bleedRounds
                case .companion: encounter.companionBleedRounds = Tuning.Encounter.bleedRounds
                case .foe: break
                }
                encounter.note("The wound won't close.")
            }
        }

        run.activeEncounter = encounter
        state.worlds.activeRun = run
        advanceTurn(in: &state)
        checkOutcome(in: &state)
    }

    private static func elementalVerb(_ element: EmanationKind) -> String {
        switch element {
        case .light: "sears"
        case .heat: "scorches"
        case .caustic: "burns"
        }
    }

    private static func performAutomatedTurn(_ actor: Combatant, in state: inout GameState) {
        guard let run = state.worlds.activeRun, let encounter = run.activeEncounter else { return }

        if let decision = GambitEngine.decide(for: actor, in: state) {
            state.worlds.activeRun?.activeEncounter?.note(
                "\(actorName(actor, encounter: encounter)): \(decision.rule.displayText)"
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
            awardSpoils(run: &run, encounter: &encounter, state: &state)
        } else if run.binderHP <= 0 && run.companionHP <= 0 {
            // No death state in v0 — you're carried home with what survived.
            encounter.outcome = .defeated
            encounter.note("You can't go on.")
        }
        run.activeEncounter = encounter
        state.worlds.activeRun = run
    }

    /// Rolls what the fight paid out, straight into the satchel, and records it in plain words.
    ///
    /// Two halves. **Resources** come off the *world's own* yield table, so what you win reflects
    /// where you are — an ore-rich world pays in ore. **Materials** come off the creature itself
    /// (creature-system-spec §8): the parts that composed it compose what it leaves, so a world that
    /// grows monstrous armoured things drops monstrous plates.
    private static func awardSpoils(run: inout WorldRun, encounter: inout EncounterState, state: inout GameState) {
        var gained = ResourcePool()
        var found: [String] = []

        for foe in encounter.foes {
            // How much a kill is worth follows what the world spent making it, rather than an
            // authored tier — a world that grows monstrous things pays out for monstrous things.
            let tier = foe.traits.map(CreatureIdentity.tier(of:))
                ?? foe.creatureID.flatMap { ContentCatalog.shared.creature($0)?.tier }
                ?? 1
            let amount = tier * run.rng.int(in: Tuning.Encounter.lootPerTierRange)
            if let resource = run.rng.pickWeighted(BookRules.yieldTable(for: run.book)) {
                run.satchel.add(amount, of: resource)
                gained.add(amount, of: resource)
                state.reality.discovery.recordResource(resource, runIndex: run.runIndex)
            }
            if let traits = foe.traits {
                found.append(contentsOf: butcher(traits, named: foe.stats.displayName,
                                                 qualifier: foe.qualifier, run: &run))
            }
            // **Gear drops too** (Aimee, 5 Aug). Sites were the only source, so a run that fought
            // its way across a world and found no ruin came home with nothing to wear — and now
            // that weapons carry a damage type, what you're carrying is the decision a fight is
            // supposed to reward.
            if run.rng.chance(Tuning.Economy.gearDropChance * Double(tier)) {
                let gear = ContentCatalog.shared.items
                    .filter { $0.kind == .gear && ($0.gear?.tier ?? 0) <= tier + 1 }
                    .map(\.id).sorted { $0.rawValue < $1.rawValue }
                if let piece = run.rng.pick(gear) {
                    let name = ContentCatalog.shared.item(piece)?.name ?? "Something worn"
                    let stack = ItemStack(id: InstanceID(rawValue: run.rng.next()), catalogID: piece)
                    if run.satchelItems.add(stack) {
                        found.append(name)
                    } else {
                        run.offeredItems.append(stack)
                        found.append("\(name) — no room; waiting on you")
                    }
                }
            }

            // Curios drop unidentified — this is where keys enter the world, one identify and one
            // long walk before they open anything.
            if run.rng.chance(Tuning.Economy.curioDropChance) {
                let curios = ContentCatalog.shared.items.filter { $0.kind == .curio }
                    .map(\.id).sorted { $0.rawValue < $1.rawValue }
                if let curio = run.rng.pick(curios) {
                    let name = ContentCatalog.shared.item(curio)?.unidentifiedName ?? "Something odd"
                    let stack = ItemStack(id: InstanceID(rawValue: run.rng.next()),
                                          catalogID: curio, count: 1, identified: false)
                    // A full satchel neither swallows the loot nor discards it — it hands you
                    // the choice. Held on the run until you make it, so a force-quit mid-decision
                    // resumes with the decision still open.
                    if run.satchelItems.add(stack) {
                        found.append(name)
                    } else {
                        run.offeredItems.append(stack)
                        found.append("\(name) — no room; waiting on you")
                    }
                }
            }
        }

        encounter.spoils = gained.nonZero.map { entry in
            "\(entry.amount) \(ContentCatalog.shared.resource(entry.id)?.name.lowercased() ?? entry.id.rawValue)"
        } + found
    }

    /// Cuts a body into the parts it was made of, into the satchel.
    ///
    /// A full satchel neither swallows a material nor discards it: it goes onto `offeredItems` and
    /// waits on the player, the same rule curios follow, so a force-quit mid-decision resumes with
    /// the decision still open.
    private static func butcher(_ traits: CreatureTraits, named name: String,
                                qualifier: String?, run: inout WorldRun) -> [String] {
        var lines: [String] = []
        let count = ButcheryRules.quantity(from: traits, rng: &run.rng)

        for sample in ButcheryRules.materials(from: traits, named: name, qualifier: qualifier) {
            let stack = ItemStack(id: InstanceID(rawValue: run.rng.next()),
                                  catalogID: Items.material,
                                  count: count,
                                  material: sample)
            if run.satchelItems.add(stack) {
                lines.append(count > 1 ? "\(sample.displayName) ×\(count)" : sample.displayName)
            } else {
                run.offeredItems.append(stack)
                lines.append("\(sample.displayName) — no room; waiting on you")
            }
        }
        return lines
    }

    /// Closes out a finished fight: bestiary, and taking the defeated off the grid.
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
            // Spoils were already rolled and banked into the satchel at the moment of victory, so
            // the victory screen could show them. Nothing left to do but clear the board.

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
