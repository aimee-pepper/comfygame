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

    // MARK: Skills

    /// **Everything this member can do**, in catalogue order.
    ///
    /// One each was the whole player side of combat while foes had trait-derived armour, damage
    /// character, reach and retaliation (`resources-skills-spec.md` §2, audit #9's second priority).
    static func skills(for actor: Combatant) -> [SkillDef] {
        switch actor {
        case .binder: ContentCatalog.shared.skills(ownedBy: .binder)
        case .companion: ContentCatalog.shared.skills(ownedBy: .companion)
        case .foe: []
        }
    }

    /// The first skill of a kind this member could use *right now*. Nil if they haven't got one or
    /// it's still cooling.
    static func ready(_ kind: SkillDef.Kind, for actor: Combatant,
                      in encounter: EncounterState) -> SkillDef? {
        skills(for: actor).first { $0.kind == kind && cooldown(of: $0, for: actor, in: encounter) == 0 }
    }

    /// What a gambit means by "use a skill" now that there are twelve.
    ///
    /// Heal a hurt ally if anything is hurt and a heal is up; otherwise the strongest ready thing
    /// that isn't a heal. Deliberately simple — the player's own rule list is where nuance belongs,
    /// and inventing a hidden priority order here would fight it.
    static func bestReadySkill(for actor: Combatant, in encounter: EncounterState,
                               state: GameState) -> SkillDef? {
        guard let run = state.worlds.activeRun else { return nil }
        let hurt = [Combatant.binder, .companion].contains {
            let hp = health(of: $0, in: run)
            return hp.current > 0 && hp.current < hp.max
        }
        if hurt, let heal = ready(.heal, for: actor, in: encounter) { return heal }
        return skills(for: actor)
            .filter { $0.kind != .heal && $0.kind != .rout }
            .filter { cooldown(of: $0, for: actor, in: encounter) == 0 }
            .max { $0.power < $1.power }
    }

    /// Cooldowns are keyed per skill, because twelve sharing one timer means picking the best and
    /// never seeing the other eleven.
    static func cooldownKey(_ skill: SkillDef, for actor: Combatant) -> String {
        "\(actor.storageKey)|\(skill.id.rawValue)"
    }

    static func cooldown(of skill: SkillDef, for actor: Combatant,
                         in encounter: EncounterState) -> Int {
        if let counted = encounter.cooldowns[cooldownKey(skill, for: actor)] { return counted }
        // **Only** a save written before per-skill timers existed falls back to the single number,
        // and only while nothing has been used since. Reading the legacy field the moment any key
        // is missing would put every unused skill on the cooldown of the one you just spent.
        guard encounter.cooldowns.isEmpty else { return 0 }
        switch actor {
        case .binder: return encounter.binderSkillCooldown
        case .companion: return encounter.companionSkillCooldown
        case .foe: return 0
        }
    }

    static func isReady(_ skill: SkillDef, for actor: Combatant, in encounter: EncounterState) -> Bool {
        cooldown(of: skill, for: actor, in: encounter) == 0
    }

    /// **Every skill's effect.**
    ///
    /// The design rule the whole set is built on (`resources-skills-spec.md` §2): *every skill
    /// answers a specific kind of creature.* If it's good against everything it's just a bigger
    /// attack. So each of these reads something the creature system already computes — its
    /// covering, its armour, what it gives off — and is worth reaching for exactly when that
    /// reading is bad news.
    private static func use(_ skill: SkillDef, by actor: Combatant,
                            on foeID: InstanceID?, ally: Combatant?,
                            run: inout WorldRun, encounter: inout EncounterState,
                            discovery: inout DiscoveryLog, weaponKind: DamageKind?) {
        let foe = foeID.flatMap { id in encounter.foes.first { $0.id == id && $0.isAlive } }

        switch skill.kind {
        case .damage:
            guard let foe else { return }
            strike(foe.id, damage: skill.power, by: actor, kind: skill.damage ?? weaponKind,
                   run: &run, encounter: &encounter, verb: skill.name)

        case .heal:
            let target = ally ?? actor
            let amount = roll(around: skill.power, run: &run)
            heal(target, by: amount, run: &run, encounter: &encounter, source: skill.name, healer: actor)

        case .armourIgnoring:
            // **Pry.** Goes under the plate entirely, and hits for very little. The answer to a
            // bulwark whose armour is eating four fifths of every honest swing.
            guard let foe else { return }
            strike(foe.id, damage: skill.power, by: actor, kind: .pierce,
                   run: &run, encounter: &encounter, verb: skill.name, ignoresArmour: true)

        case .overbear:
            // **Overbear.** All your weight behind it, and you're out of position afterwards.
            guard let foe else { return }
            strike(foe.id, damage: skill.power, by: actor, kind: .crush,
                   run: &run, encounter: &encounter, verb: skill.name)
            encounter.skippedTurns[actor, default: 0] += 1
            encounter.note("You're off balance.")

        case .bleed:
            // **Flense.** Scales with how much covering there is to open — nothing on a plated
            // thing, a great deal on something shaggy. The mirror of the creature system's own rend.
            guard let foe else { return }
            let purchase = (foe.traits?.covering.insulation ?? 0) / Tuning.Pressure.scaleMaximum
            let perRound = max(1, Int((Double(skill.power) * purchase).rounded()))
            encounter.foeBleeds[foe.id] = BleedState(damage: perRound, rounds: skill.rounds)
            encounter.note(purchase < Tuning.Encounter.thinCovering
                           ? "\(skill.name): there's nothing here to open."
                           : "\(skill.name). \(foe.stats.displayName) is bleeding.")

        case .reveal:
            // **Sight.** The covering word is what the whole damage triangle is read off, and
            // without this you only learn it by taking a bad trade first.
            guard let foe else { return }
            encounter.revealed.insert(foe.id)
            remember(foe, in: &discovery, runIndex: run.runIndex)
            let covering = foe.coveringWord ?? "nothing much"
            encounter.note("\(foe.stats.displayName): \(covering), and it \(foe.stats.damageKind.verb).")

        case .ward:
            // **Ward.** Against one of six things, which is the point — you have to know what's
            // coming, and Sight is how you find out. A ward against "elemental" in general would be
            // the good-against-everything shape the whole skill set is built to avoid.
            let against = skill.damage.map(Harm.blow) ?? mostCommonIncoming(in: encounter)
            encounter.wards[actor] = WardState(against: against, rounds: skill.rounds)
            encounter.note("\(skill.name): set against \(against.displayName).")

        case .taunt:
            // **Draw Off.** The only way to take a hit meant for somebody else.
            guard let foe else { return }
            encounter.taunts[foe.id] = skill.rounds
            encounter.note("\(foe.stats.displayName) turns on you.")

        case .snuff:
            // **Snuff.** Puts out whatever it was giving off — which is what was doing damage every
            // round whether you touched it or not.
            guard let foe else { return }
            encounter.snuffed.insert(foe.id)
            encounter.note("\(foe.stats.displayName) goes dark.")

        case .quicken:
            // **Quicken.** Borrowed against the round after. Worth it to finish something.
            encounter.extraTurns[actor, default: 0] += 1
            encounter.skippedTurns[actor, default: 0] += 1
            encounter.note("\(skill.name).")

        case .cleanse:
            // **Steady.** Closes whatever is still open — a wound, a burn, a poison, or the
            // after-image of something that flared at you.
            let target = ally ?? actor
            switch target {
            case .binder: encounter.binderBleedRounds = 0
            case .companion: encounter.companionBleedRounds = 0
            case .foe: break
            }
            let carried = encounter.statuses[target] ?? []
            encounter.statuses[target] = []
            encounter.note(carried.isEmpty
                           ? "\(skill.name): the bleeding stops."
                           : "\(skill.name): the \(carried.map { $0.kind.rawValue }.joined(separator: " and ")) stops.")

        case .rout:
            // **Rout.** Leaving without the world noticing — the answer to a fight you shouldn't
            // have started, and the reason fleeing stops being a pure penalty.
            encounter.note("You break away clean.")
            encounter.outcome = .fled

        case .read:
            // **Read.** A bestiary entry without a kill, which makes collecting a thing you can do
            // *instead* of killing rather than only by killing.
            guard let foe else { return }
            encounter.revealed.insert(foe.id)
            remember(foe, in: &discovery, runIndex: run.runIndex)
            encounter.note("You take \(foe.stats.displayName) in properly. You'll know it again.")
        }

        encounter.cooldowns[cooldownKey(skill, for: actor)] = skill.cooldownRounds
        setCooldown(skill.cooldownRounds, for: actor, in: &encounter)
    }

    /// A bestiary entry without a kill — which is what makes Read a real alternative to killing
    /// rather than a convenience.
    private static func remember(_ foe: FoeState, in discovery: inout DiscoveryLog, runIndex: Int) {
        discovery.recordSpecies(foe.identityKey, runIndex: runIndex)
        if let traits = foe.traits {
            discovery.recordSpecimen(traits, of: foe.identityKey, runIndex: runIndex)
        }
    }

    /// What most of what's still standing brings, so a Ward with nothing stated guards the likeliest
    /// thing rather than nothing. **An emanation wins over a blow** — nothing you wear stops one,
    /// so it's the harm most worth turning aside.
    private static func mostCommonIncoming(in encounter: EncounterState) -> Harm {
        let elements = encounter.livingFoes.compactMap(\.stats.element)
        if let commonest = EmanationKind.allCases.max(by: { a, b in
            elements.count { $0 == a } < elements.count { $0 == b }
        }), elements.contains(commonest) {
            return .emanation(commonest)
        }
        let kinds = encounter.livingFoes.map(\.stats.damageKind)
        return .blow(DamageKind.allCases.max { a, b in
            kinds.count { $0 == a } < kinds.count { $0 == b }
        } ?? .pierce)
    }

    // MARK: Harm that outlives the blow

    /// Lays a status on somebody, replacing a weaker one of the same kind rather than stacking.
    /// Stacking would make two emanating creatures arithmetic rather than a threat.
    private static func afflict(_ target: Combatant, with kind: StatusKind, damage: Int,
                                rounds: Int, encounter: inout EncounterState) {
        var carried = encounter.statuses[target] ?? []
        if let index = carried.firstIndex(where: { $0.kind == kind }) {
            carried[index].damage = max(carried[index].damage, damage)
            carried[index].rounds = max(carried[index].rounds, rounds)
        } else {
            carried.append(StatusState(kind: kind, damage: damage, rounds: rounds))
        }
        encounter.statuses[target] = carried
    }

    static func has(_ kind: StatusKind, _ actor: Combatant, in encounter: EncounterState) -> Bool {
        (encounter.statuses[actor] ?? []).contains { $0.kind == kind }
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

        case .skill(let id, let foeID, let allyID):
            if let skill = ContentCatalog.shared.skill(id), skills(for: actor).contains(skill),
               isReady(skill, for: actor, in: encounter) {
                use(skill, by: actor, on: foeID, ally: allyID, run: &run, encounter: &encounter,
                    discovery: &state.reality.discovery, weaponKind: damageKind(for: actor, in: state))
            }

        case .damageSkill(let foeID):
            // The gambit vocabulary's "damage skill" — whichever damaging one is up.
            if let skill = skills(for: actor).first(where: {
                $0.power > 0 && $0.kind != .heal && isReady($0, for: actor, in: encounter)
            }) {
                use(skill, by: actor, on: foeID, ally: nil, run: &run, encounter: &encounter,
                    discovery: &state.reality.discovery, weaponKind: damageKind(for: actor, in: state))
            }

        case .healSkill(let ally):
            if let skill = ready(.heal, for: actor, in: encounter) {
                use(skill, by: actor, on: nil, ally: ally, run: &run, encounter: &encounter,
                    discovery: &state.reality.discovery, weaponKind: damageKind(for: actor, in: state))
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
                               verb: String? = nil,
                               ignoresArmour: Bool = false) {
        guard let index = encounter.foes.firstIndex(where: { $0.id == foeID }), encounter.foes[index].isAlive
        else { return }

        let foe = encounter.foes[index]
        let name = foe.stats.displayName
        let who = actorName(actor, encounter: encounter)

        // **Dazzled, you swing at where it was.** A light emanation now costs you your accuracy
        // rather than only a point of health (Q42).
        let dazzled = has(.dazzle, actor, in: encounter) ? Tuning.Encounter.dazzleMissChance : 0
        if dazzled > 0, run.rng.chance(dazzled) {
            encounter.note("\(who) \(actor == .binder ? "swing" : "swings") at where \(name) was.")
            return
        }

        // **Sleek and small is hard to hit.** A miss is the price of chasing something built to run.
        if run.rng.chance(foe.stats.evasion) {
            encounter.note("\(who) \(actor == .binder ? "swing" : "swings") at \(name) and find\(actor == .binder ? "" : "s") nothing there.")
            return
        }

        // **The matchup.** What you're swinging against what it's wearing, then armour on what's
        // left — and a piercing weapon goes through a share of that armour rather than all of it.
        let matchup = kind.map { effectiveness(of: $0, against: foe.traits?.covering ?? Covering()) } ?? 1
        let raw = Int((Double(roll(around: damage, run: &run)) * matchup).rounded())
        // **Pry goes under it entirely**, which is the one thing armour has no answer to.
        let ignored = ignoresArmour ? 1.0 : (kind == .pierce ? Tuning.Encounter.pierceArmourIgnored : 0)
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

        // **Warning colours are honest.** Hitting something that advertises costs you — and if it
        // was advertising *venom*, it costs you for a while (Q42).
        if foe.stats.retaliation > 0, encounter.foes[index].isAlive {
            hurt(actor, by: foe.stats.retaliation, run: &run, encounter: &encounter)
            encounter.note("\(name.capitalisedSentence) is not safe to touch — \(foe.stats.retaliation) back.")
            if foe.traits?.isToxic == true {
                afflict(actor, with: .poison,
                        damage: Tuning.Encounter.statusDamage["poison"] ?? 0,
                        rounds: Tuning.Encounter.statusRounds["poison"] ?? 3,
                        encounter: &encounter)
                encounter.note("It's in you now.")
            }
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

        // **A turn owed is taken before the order moves on** — that's what Quicken buys, and it
        // has to be spent here rather than by shuffling `order`, which is stored precisely so a
        // death mid-round can't shift whose turn it is.
        let acting = encounter.order.isEmpty ? Combatant.binder : encounter.order[encounter.turnIndex % encounter.order.count]
        if let owed = encounter.extraTurns[acting], owed > 0 {
            encounter.extraTurns[acting] = owed - 1
            encounter.note("Again, before it can answer.")
            run.activeEncounter = encounter
            state.worlds.activeRun = run
            return
        }

        var roundTurned = false
        for step in 1...max(1, encounter.order.count) {
            let next = (encounter.turnIndex + step) % encounter.order.count
            if next <= encounter.turnIndex { startNewRound(&encounter); roundTurned = true }
            encounter.turnIndex = next
            let who = encounter.order[next]
            guard isAlive(who, in: withEncounter(encounter, on: run)) else { continue }
            // …and a turn borrowed is a turn skipped. Overbear and Quicken both pay here.
            if let owing = encounter.skippedTurns[who], owing > 0 {
                encounter.skippedTurns[who] = owing - 1
                encounter.note("\(actorName(who, encounter: encounter)) is still recovering.")
                continue
            }
            break
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
        // Every skill's own timer, and every effect with a clock on it. Rounds, never seconds.
        for (key, value) in encounter.cooldowns { encounter.cooldowns[key] = max(0, value - 1) }
        for (who, ward) in encounter.wards {
            if ward.rounds <= 1 { encounter.wards[who] = nil }
            else { encounter.wards[who]?.rounds = ward.rounds - 1 }
        }
        for (foe, rounds) in encounter.taunts {
            if rounds <= 1 { encounter.taunts[foe] = nil } else { encounter.taunts[foe] = rounds - 1 }
        }
    }

    /// Wounds that keep costing you, ticked once per round. Run from `advanceTurn` where the round
    /// actually turns over, so a force-quit between rounds can't skip or double a tick.
    private static func bleed(in state: inout GameState) {
        guard var run = state.worlds.activeRun, var encounter = run.activeEncounter else { return }
        let damage = Tuning.Encounter.bleedDamage

        // **Burns, poisons and dazzles**, ticked with everything else so a force-quit between
        // rounds can't skip or double one.
        for (who, carried) in encounter.statuses {
            var remaining: [StatusState] = []
            for status in carried {
                if status.damage > 0, isAlive(who, in: withEncounter(encounter, on: run)) {
                    hurt(who, by: status.damage, run: &run, encounter: &encounter)
                    encounter.note("\(actorName(who, encounter: encounter)) \(status.kind.verb) — \(status.damage).")
                }
                if status.rounds > 1 {
                    var next = status
                    next.rounds -= 1
                    remaining.append(next)
                }
            }
            encounter.statuses[who] = remaining
        }

        // **Wounds you opened.** Flense's, which are per-foe and carry their own severity — a
        // shaggy thing bleeds far worse than a plated one, which is the whole reading.
        for (foeID, state) in encounter.foeBleeds {
            guard let index = encounter.foes.firstIndex(where: { $0.id == foeID }),
                  encounter.foes[index].isAlive
            else { encounter.foeBleeds[foeID] = nil; continue }
            encounter.foes[index].currentHP = max(0, encounter.foes[index].currentHP - state.damage)
            encounter.note("\(encounter.foes[index].stats.displayName) bleeds for \(state.damage).")
            if state.rounds <= 1 { encounter.foeBleeds[foeID] = nil }
            else { encounter.foeBleeds[foeID]?.rounds = state.rounds - 1 }
        }

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
        // **Draw Off.** Something you've taunted comes for you and doesn't get a choice — the only
        // way in the game to take a hit meant for somebody else.
        let taunted = (encounter.taunts[foeID] ?? 0) > 0 && isAlive(.binder, in: run)
        guard let primary = taunted ? .binder : run.rng.pick(standing) else {
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

            // **Ward.** Turns aside one harm, so you have to know what's coming — which is what
            // Sight is for. Guessing wrong costs you the round you spent setting it.
            let incoming: Harm = (encounter.snuffed.contains(foeID) ? nil : foe.stats.element)
                .map(Harm.emanation) ?? .blow(foe.stats.damageKind)
            if encounter.wards[target]?.harm == incoming {
                raw *= 1 - Tuning.Encounter.wardReduction
            }

            let amount: Int
            // **Snuff** puts out whatever it was giving off, and with it the damage nothing you
            // wear could stop.
            if foe.stats.element != nil, !encounter.snuffed.contains(foeID) {
                // Nothing you're wearing stops caustic, heat or light.
                amount = max(Tuning.Encounter.minimumDamage, Int(raw.rounded()))
            } else {
                let ignored = foe.stats.damageKind == .pierce ? Tuning.Encounter.pierceArmourIgnored : 0
                amount = damageTaken(Int(raw.rounded()), by: target, in: state, armourIgnored: ignored)
            }
            hurt(target, by: amount, run: &run, encounter: &encounter)

            let verb = (encounter.snuffed.contains(foeID) ? nil : foe.stats.element)
                .map(elementalVerb) ?? foe.stats.damageKind.verb
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

            // **And so does what it gives off** (Q42). Emanation was generated, named in the
            // description, and did nothing beyond one armour-ignoring hit. Snuff puts a stop to it.
            if let element = foe.stats.element, !encounter.snuffed.contains(foeID) {
                let status = StatusKind.from(element)
                afflict(target, with: status,
                        damage: Tuning.Encounter.statusDamage[status.rawValue] ?? 0,
                        rounds: Tuning.Encounter.statusRounds[status.rawValue] ?? 2,
                        encounter: &encounter)
                encounter.note(status == .dazzle
                               ? "The after-image sits in your eyes."
                               : "It's still \(status == .burn ? "burning" : "spreading").")
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
            // **What a world pays comes off its readings, not off a symbol's table.** The
            // book-level table gives every resource the same flat weight, so with a real catalogue
            // it would drop adamant off a barren world as readily as rubble — describing a world it
            // did not generate (`audit-what-pressures-actually-do.md` §4.1). Node placement has read
            // the pressures since that audit; kill drops hadn't caught up.
            let paid = BookRules.yieldTable(from: BookRules.readings(for: run.book, seed: run.mapSeed))
            if let resource = run.rng.pickWeighted(paid) {
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
