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
    /// - Parameter party: everybody who walked out with you. **All of them get a place in the
    ///   order** — this is where a party of five becomes real, and it used to be a hardcoded two.
    static func makeEncounter(id: InstanceID, foes: [FoeState], party: [Combatant] = [.binder, .companion(0)],
                              names: [Int: String] = [:],
                              apexActionSlots: [InstanceID: Int] = [:],
                              ordinaryPressureSlots: Int = 0,
                              initiallyUnrecordedSpecies: Set<String> = [],
                              debugV2BinderAttack: EncounterState.DebugV2BinderAttackReceipt? = nil,
                              rng: inout SeededRNG) -> EncounterState {
        var ranked: [(actor: Combatant, initiative: Int, first: Bool)] = party.map { member in
            (member, member == .binder ? Tuning.Encounter.binderInitiative
                                       : Tuning.Encounter.companionInitiative, false)
        }
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

        var slots = order.map { EncounterState.TurnSlot(actor: $0) }
        for (foeID, count) in apexActionSlots.sorted(by: { $0.key.rawValue < $1.key.rawValue }) where count > 1 {
            guard var previous = slots.firstIndex(where: { $0.actor == .foe(foeID) }) else { continue }
            for ordinal in 2...min(3, count) {
                // Place each lighter action after another actor whenever the remaining initiative
                // order permits it. Re-resolve from the last insertion: using the original primary
                // index for every insertion can accidentally bunch slots 2 and 3 together.
                let intervening = slots.indices.first { $0 > previous && slots[$0].actor != .foe(foeID) }
                let index = intervening.map { $0 + 1 } ?? slots.endIndex
                slots.insert(.init(actor: .foe(foeID), kind: .apexFollowUp(ordinal),
                                   strengthMultiplier: 0.60, suppressesAfflictions: true), at: index)
                previous = index
            }
        }
        let ordinaryFoeOrder = order.compactMap(\.foeID).filter { foeID in
            foes.contains { $0.id == foeID && !$0.isApex }
        }
        if !ordinaryFoeOrder.isEmpty, ordinaryPressureSlots > 0 {
            for ordinal in 1...ordinaryPressureSlots {
                let foeID = ordinaryFoeOrder[(ordinal - 1) % ordinaryFoeOrder.count]
                let previous = slots.lastIndex(where: { $0.actor == .foe(foeID) }) ?? 0
                let intervening = slots.indices.first { $0 > previous && slots[$0].actor != .foe(foeID) }
                let index = intervening.map { $0 + 1 } ?? slots.endIndex
                slots.insert(.init(actor: .foe(foeID), kind: .ordinaryPressureFollowUp(ordinal),
                                   strengthMultiplier: 0.55, suppressesAfflictions: true), at: index)
            }
        }
        var opening = [foes.count == 1 ? "A \(foes[0].stats.displayName) notices you."
                                       : "They close in around you."]
        if let relentless = apexActionSlots.values.max(), relentless > 1 {
            opening.append("Relentless — \(relentless) actions; follow-ups lighter.")
        }
        if ordinaryPressureSlots > 0 {
            opening.append("Pressed — \(ordinaryPressureSlots) lighter follow-up\(ordinaryPressureSlots == 1 ? "" : "s").")
        }
        return EncounterState(
            id: id,
            foes: foes,
            partyNames: names,
            order: order,
            turnSlots: slots,
            initiallyUnrecordedSpecies: initiallyUnrecordedSpecies,
            debugV2BinderAttack: debugV2BinderAttack,
            log: opening
        )
    }

    // MARK: Party numbers

    /// **What each of them is wearing.** The Binder has its own slots (Aimee, 5 Aug) — it's half
    /// the party, and an attack that was a `Tuning` constant meant the damage-type matchup never
    /// reached the player's own turns, which is the whole point of giving weapons a type.
    static func equipped(_ slot: GearSlot, for actor: Combatant, in state: GameState) -> EquippedPiece? {
        switch actor {
        case .binder: state.base.binderEquipped[slot]
        case .companion(let index): state.base.worn(slot, by: .member(index))
        case .foe: nil
        }
    }

    /// **What somebody is, on top of what they're holding** (session 17 §1).
    ///
    /// Might for crush, Finesse for pierce and rend — so a character and their weapon want to
    /// agree, and a high-Might character carrying a piercing blade is wasting half of what they
    /// are. That's a real equipping decision rather than "wear the highest tier".
    static func stats(of actor: Combatant, in state: GameState) -> CharacterStats? {
        switch actor {
        case .binder: state.base.binderCharacter.stats
        case .companion(let index): state.base.character(.member(index)).stats
        case .foe: nil
        }
    }

    static func rank(of actor: Combatant, in state: GameState) -> Rank {
        switch actor {
        case .binder: state.base.binderCharacter.rank
        case .companion(let index): state.base.character(.member(index)).rank
        case .foe: .front
        }
    }

    static func binderAttack(in state: GameState) -> Int {
        let power = equipped(.weapon, for: .binder, in: state)?.effectivePower ?? 0
        let total = Double(Tuning.Encounter.binderAttack
            + CharacterRules.damageBonus(state.base.binderCharacter.stats,
                                         with: damageKind(for: .binder, in: state)))
            + power * Double(Tuning.Encounter.attackPerWeaponTier)
        return Int(total.rounded())
    }

    /// **What this one is swinging.** Each party member's own weapon decides the matchup, so
    /// carrying a piercing blade while Quill carries a rending one is a real answer to a world that
    /// grew both plated and furred things.
    static func damageKind(for actor: Combatant, in state: GameState) -> DamageKind? {
        equipped(.weapon, for: actor, in: state)?.frozenDamage
    }

    static func reach(for actor: Combatant, in state: GameState) -> Reach {
        equipped(.weapon, for: actor, in: state)?.frozenReach ?? .close
    }

    /// Whether this foe can include a party member in any attack it can currently perform. Foes
    /// have one derived hostile action today: single delivery respects the front line, while area
    /// and multi delivery, emanation, and first-strike reach can cross it.
    static func canReach(_ target: Combatant, foe: FoeState,
                         in state: GameState, run: WorldRun) -> Bool {
        let standing = party(of: state).filter { isAlive($0, in: run) }
        guard standing.contains(target) else { return false }
        if rank(of: target, in: state) == .front { return true }
        if standing.allSatisfy({ rank(of: $0, in: state) == .back }) { return true }
        if foe.stats.delivery != .single { return true }
        return foe.stats.strikesFirst || foe.stats.element != nil
    }

    /// **The rule this hand is breaking**, on the eight wild-only weapons and nowhere else
    /// (`apex-encounters.md` §4). Nil on everything you can make.
    static func wildRule(for actor: Combatant, in state: GameState) -> WildRule? {
        equipped(.weapon, for: actor, in: state)?.gear?.breaks
    }

    static func wardedHaftMultiplier(against kind: DamageKind, for actor: Combatant,
                                     in state: GameState) -> Double {
        let weapon = equipped(.weapon, for: actor, in: state)
        return weapon?.gear?.breaks == .wardWhileHeld && weapon?.gear?.wardsAgainst == kind
            ? 1 - Tuning.Apex.wardedHaftReduction : 1
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
    /// **A two-natured blade picks whichever hurts more** — the one thing no material can do,
    /// because nothing has two dominant armaments (`apex-encounters.md` §4).
    static func effectiveness(of kind: DamageKind, against covering: Covering,
                              breaking rule: WildRule?) -> Double {
        CombatDamageRules.effectiveness(of: kind, against: covering, breaking: rule)
    }

    static func effectiveness(of kind: DamageKind, against covering: Covering) -> Double {
        CombatDamageRules.effectiveness(of: kind, against: covering)
    }

    static func companionAttack(_ index: Int, in state: GameState) -> Int {
        let member = PartyMember.member(index)
        let power = state.base.worn(.weapon, by: member)?.effectivePower ?? 0
        let total = Double(Tuning.Encounter.companionBaseAttack
            + CharacterRules.damageBonus(state.base.character(member).stats,
                                         with: damageKind(for: .companion(index), in: state)))
            + power * Double(Tuning.Encounter.attackPerWeaponTier)
        return Int(total.rounded())
    }

    /// Armour softens what lands on the party. Never below a floor — armour shouldn't make a fight
    /// unloseable, just survivable.
    ///
    /// `armourIgnored` is what a piercing attack goes straight through, which is the whole reason
    /// the weapon triangle exists: the same armour is worth more against some things than others.
    /// **What a piece is made of, beyond its tier** (Q36's addition, audit #9: *"for insulation and
    /// reactivity, don't wait for new slots — give them secondary effects on existing gear"*).
    ///
    /// Four of the six material properties had a job: hardness, flexibility, density and lustre
    /// each decide what the Blacksmith asks for. Insulation and reactivity had none at all outside
    /// that one bar, so a warm pelt and a volatile ichor were worth nothing to wear.
    ///
    /// Now they are: **insulation on what you wear turns aside heat**, and **reactivity on what you
    /// swing carries a status into the wound.** Which ties gear to the world it came from — a cold
    /// world is one you dress for.
    static func insulation(of actor: Combatant, in state: GameState) -> Double {
        GearSlot.allCases
            .filter(\.isProtective)
            .compactMap { equipped($0, for: actor, in: state)?.frozenInsulation }
            .reduce(0, +) / Tuning.Pressure.scaleMaximum
    }

    /// What the weapon in somebody's hand is volatile enough to leave behind.
    static func coating(of actor: Combatant, in state: GameState) -> StatusKind? {
        guard let weapon = equipped(.weapon, for: actor, in: state),
              weapon.frozenReactivity >= Tuning.Encounter.coatingReactivity
        else { return nil }
        return .poison
    }

    /// Whether a blow simply misses somebody. **Finesse, on the party's side of the fight** — the
    /// mirror of a creature's evasion, which has existed since creatures were generated.
    static func evades(_ actor: Combatant, in state: GameState, run: inout WorldRun,
                       encounter: EncounterState? = nil) -> Bool {
        // **Sidestep and Ghost are certainties, not chances.** A skill that says "that one misses"
        // has to mean it, or it is a slightly better Footwork.
        if let encounter {
            if (encounter.dodging[actor] ?? 0) > 0 { return true }
            let ghost = loadout(of: actor, in: state).firstAttackAlwaysMisses
            if ghost, encounter.roundNumber == 1 { return true }
        }
        guard let stats = stats(of: actor, in: state) else { return false }
        let fromTree = loadout(of: actor, in: state).evasion
        return run.rng.chance(min(0.85, CharacterRules.evasion(stats) + fromTree))
    }

    static func damageTaken(_ raw: Int, by actor: Combatant, in state: GameState,
                            armourIgnored: Double = 0) -> Int {
        // **Iron Skin, and Immovable.** The capstone is the one thing in the game that makes armour
        // work against a piercing blow, which is what "armour is armour, whatever it is against"
        // has to mean if it is worth eight points.
        let tree = loadout(of: actor, in: state)
        let ignored = tree.armourAppliesToEverything ? 0 : armourIgnored
        // **Everything protective counts**, not just the body piece — a helm and boots are armour
        // too, and only the companion's chest plate used to be read at all.
        let power = GearSlot.allCases
            .filter(\.isProtective)
            .reduce(0.0) { total, slot in
                guard let piece = equipped(slot, for: actor, in: state) else { return total }
                return total + (piece.gearProfile?.protectivePower ?? piece.effectivePower)
            }
        // **Fortitude decides what that armour is worth to you** (session 17 §1). The same plate
        // does more for a sturdy character than a slight one, which is what stops Fortitude being a
        // second health bar.
        let sturdiness = stats(of: actor, in: state).map(CharacterRules.armourMultiplier) ?? 1
        let armour = power * Double(Tuning.Encounter.defencePerArmorTier) * sturdiness
            + Double(tree.armour)
        let effective = Int((armour * (1 - ignored)).rounded())

        // **Standing at the back is worth something**, and only against something in reach
        // (session 17 §4).
        var incoming = Double(raw)
        if rank(of: actor, in: state) == .back { incoming *= 1 - Tuning.Encounter.backRankProtection }
        return max(Tuning.Encounter.minimumDamage, Int(incoming.rounded()) - effective)
    }

    // MARK: Skills

    /// **Everything this member can do**, in catalogue order.
    ///
    /// One each was the whole player side of combat while foes had trait-derived armour, damage
    /// character, reach and retaliation (`resources-skills-spec.md` §2, audit #9's second priority).
    /// **What somebody can do, from where they spent** (`docs/combat-trees-full.md`).
    ///
    /// It used to read `SkillDef.Owner` — *the Binder's skills, or the companion's* — which was a
    /// fossil of a party that was exactly two people with fixed lists. Skills come from branches
    /// now, so a smith who spent in Shadow can Conceal and a soldier who didn't, can't.
    ///
    /// Identity techniques remain separate from graph ownership: Binder carries Unbind/Sight,
    /// Quill carries Mend/Read, and Ashe carries Ground. `SkillDef.owner` and Rout are legacy input.
    static func skills(for actor: Combatant, in state: GameState) -> [SkillDef] {
        let owned = CombatActionOwnershipRules.availableSkillIDs(for: actor, in: state)
        return ContentCatalog.shared.skills.filter { owned.contains($0.id) }
    }

    /// The first skill of a kind this member could use *right now*. Nil if they haven't got one or
    /// it's still cooling.
    static func ready(_ kind: SkillDef.Kind, for actor: Combatant,
                      in encounter: EncounterState, state: GameState) -> SkillDef? {
        skills(for: actor, in: state).first {
            $0.kind == kind && isReady($0, for: actor, in: encounter)
        }
    }

    /// What a gambit means by "use a skill" now that there are twelve.
    ///
    /// Heal a hurt ally if anything is hurt and a heal is up; otherwise the strongest ready thing
    /// that isn't a heal. Deliberately simple — the player's own rule list is where nuance belongs,
    /// and inventing a hidden priority order here would fight it.
    static func bestReadySkill(for actor: Combatant, in encounter: EncounterState,
                               state: GameState) -> SkillDef? {
        guard let run = state.worlds.activeRun else { return nil }
        let hurt = party(of: state).contains {
            let hp = health(of: $0, in: run)
            return hp.current > 0 && hp.current < hp.max
        }
        if hurt, let heal = ready(.heal, for: actor, in: encounter, state: state) { return heal }
        return skills(for: actor, in: state)
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
        guard cooldown(of: skill, for: actor, in: encounter) == 0 else { return false }
        if skill.kind == .ambush {
            guard !encounter.completedFirstActions.contains(actor),
                  !encounter.openingAttackConsumed.contains(actor)
            else { return false }
            switch encounter.opening?.resolved {
            case .creatureAmbush: return false
            case .scripted(_, _, let allowsPartyOpeningAttack): return allowsPartyOpeningAttack
            case .partyApproach, .mutualContact: return true
            case nil: return false
            }
        }
        return true
    }

    /// Exact consequence shown before the ordinary retreat commits.
    static func withdrawalStabilityCost(for actor: Combatant, in state: GameState) -> Double {
        canVanishWithdraw(actor, in: state) ? 0 : Tuning.Encounter.fleeStabilityCost
    }

    private static func canVanishWithdraw(_ actor: Combatant, in state: GameState) -> Bool {
        guard let run = state.worlds.activeRun else { return false }
        return loadout(of: actor, in: state).freeFlee && !run.vanishWithdrawSpent
    }

    /// Frozen v2 bonus for the two explicitly typed weapon techniques in this first slice.
    /// Unbind and other legacy `.damage` skills are intentionally not weapon hits.
    private static func debugV2WeaponTechniqueBonus(for actor: Combatant, kind: DamageKind,
                                                     encounter: EncounterState) -> Int {
        guard actor == .binder, let receipt = encounter.debugV2BinderAttack else { return 0 }
        return receipt.preMatchupBonus(for: kind).total
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
                            weaponKind: DamageKind?, stats: CharacterStats?,
                            standingBack: Bool, reach: Reach,
                            state: inout GameState) {
        let foe = foeID.flatMap { id in encounter.foes.first { $0.id == id && $0.isAlive } }
        // **Wit is what a skill is worth in your hands** (session 17 §1) — potency here, and the
        // cooldown at the bottom of this function.
        let power = stats.map { CharacterRules.skillPower(skill.power, $0) } ?? skill.power
        let rankNow: Rank = standingBack ? .back : .front

        switch skill.kind {
        case .damage:
            guard let foe else { return }
            strike(foe.id, damage: power, by: actor, kind: skill.damage ?? weaponKind,
                   run: &run, encounter: &encounter, verb: skill.name,
                   standingBack: standingBack, reachOfActor: reach)

        case .heal:
            let target = ally ?? actor
            let amount = roll(around: power, run: &run)
            heal(target, by: amount, run: &run, encounter: &encounter, source: skill.name, healer: actor)

        case .armourIgnoring:
            // **Pry.** Goes under the plate entirely, and hits for very little. The answer to a
            // bulwark whose armour is eating four fifths of every honest swing.
            guard let foe else { return }
            strike(foe.id, damage: power + debugV2WeaponTechniqueBonus(for: actor, kind: .pierce,
                                                                       encounter: encounter),
                   by: actor, kind: .pierce,
                   run: &run, encounter: &encounter, verb: skill.name, ignoresArmour: true,
                   standingBack: standingBack, reachOfActor: reach)

        case .overbear:
            // **Overbear.** All your weight behind it, and you're out of position afterwards.
            guard let foe else { return }
            strike(foe.id, damage: power + debugV2WeaponTechniqueBonus(for: actor, kind: .crush,
                                                                       encounter: encounter),
                   by: actor, kind: .crush,
                   run: &run, encounter: &encounter, verb: skill.name,
                   standingBack: standingBack, reachOfActor: reach)
            encounter.skippedTurns[actor, default: 0] += 1
            encounter.note("You're off balance.")

        case .bleed:
            // **Flense.** Scales with how much covering there is to open — nothing on a plated
            // thing, a great deal on something shaggy. The mirror of the creature system's own rend.
            guard let foe else { return }
            let purchase = (foe.traits?.covering.insulation ?? 0) / Tuning.Pressure.scaleMaximum
            let perRound = max(1, Int((Double(power) * purchase).rounded()))
            encounter.foeBleeds[foe.id] = BleedState(damage: perRound, rounds: skill.rounds)
            encounter.note(purchase < Tuning.Encounter.thinCovering
                           ? "\(skill.name): there's nothing here to open."
                           : "\(skill.name). \(foe.stats.displayName) is bleeding.")

        case .reveal:
            // **Sight.** The covering word is what the whole damage triangle is read off, and
            // without this you only learn it by taking a bad trade first.
            guard let foe else { return }
            encounter.revealed.insert(foe.id)
            remember(foe, in: &state.reality.discovery, runIndex: run.runIndex)
            let covering = foe.coveringWord ?? "nothing much"
            // **Knowledge as equipment** (`crafting-spec.md` PART TWO). Sight fits no combat branch
            // and was never meant to: what it tells you scales with how well you can *read*, so a
            // low tier says "plated" and a high one gives you the numbers behind it. That is the
            // payoff for the analysis axis reaching outside the writing desk.
            var line = "\(foe.stats.displayName): \(covering), and it \(foe.stats.damageKind.verb)."
            if state.reality.analysisTier >= Tuning.Analysis.targetsTier {
                line += " \(foe.currentHP) of \(foe.stats.maxHP) health, \(foe.stats.armour) armour."
            }
            if state.reality.analysisTier >= Tuning.Analysis.sigilAttributionTier {
                line += " It strikes for about \(foe.stats.attack)."
            }
            encounter.note(line)

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

        case .reposition:
            // **Fall Back.** The last of the twelve, and it was waiting on ranks rather than on
            // anything else (`resources-skills-spec.md` §2). Swapping where you stand *without*
            // spending the turn is the whole point — otherwise you'd just take the hit.
            let swapped: Rank = rankNow == .front ? .back : .front
            switch actor {
            case .binder: state.base.binderCharacter.rank = swapped
            case .companion(let index): state.base.withCharacter(.member(index)) { $0.rank = swapped }
            case .foe: break
            }
            encounter.extraTurns[actor, default: 0] += 1
            encounter.note(swapped == .back ? "You give ground." : "You step up.")

        case .read:
            // **Read.** A bestiary entry without a kill, which makes collecting a thing you can do
            // *instead* of killing rather than only by killing.
            guard let foe else { return }
            encounter.revealed.insert(foe.id)
            remember(foe, in: &state.reality.discovery, runIndex: run.runIndex)
            encounter.note("You take \(foe.stats.displayName) in properly. You'll know it again.")

        // MARK: The ten the combat trees teach

        case .sunder:
            // **Shatter.** The one thing that changes what a foe *is* for the rest of the fight.
            guard let foe, let index = encounter.foes.firstIndex(where: { $0.id == foe.id }) else { return }
            let taken = min(encounter.foes[index].stats.armour, max(1, power))
            encounter.foes[index].stats.armour -= taken
            encounter.note("\(skill.name). \(foe.stats.displayName) is \(taken) less protected than it was.")

        case .execute:
            // **Finish.** Large, and only against something already nearly gone — so it rewards
            // having done the work rather than replacing it.
            guard let foe else { return }
            let share = Double(foe.currentHP) / Double(max(1, foe.stats.maxHP))
            let scaled = share <= Tuning.TreeSkills.finishThreshold ? power : power / 3
            strike(foe.id, damage: scaled, by: actor, kind: skill.damage ?? weaponKind,
                   run: &run, encounter: &encounter, verb: skill.name,
                   standingBack: standingBack, reachOfActor: reach)

        case .preempt:
            // Legacy First Strike behavior remains until the direct-hit/action-receipt slice.
            encounter.extraTurns[actor, default: 0] += 1
            encounter.note("\(skill.name): you move before they do.")

        case .ambush:
            // A conditional zero-turn direct attack. The extra-turn debt keeps the ordinary
            // schedule on this actor after `perform` hands on; the receipt survives relaunch.
            guard let foe, !encounter.openingAttackConsumed.contains(actor) else { return }
            encounter.openingAttackConsumed.insert(actor)
            encounter.extraTurns[actor, default: 0] += 1
            strike(foe.id, damage: power, by: actor, kind: skill.damage ?? weaponKind,
                   run: &run, encounter: &encounter, verb: skill.name,
                   standingBack: standingBack, reachOfActor: reach)

        case .brace:
            encounter.braced[actor] = skill.rounds
            encounter.note("\(skill.name): you set yourself.")

        case .dodge:
            encounter.dodging[actor] = skill.rounds
            encounter.note("\(skill.name): the next one finds nothing.")

        case .conceal:
            encounter.concealed[actor] = skill.rounds
            encounter.note("\(skill.name): they lose sight of you.")

        case .intercept:
            encounter.interposing[actor] = skill.rounds
            encounter.note("\(skill.name): you step in front.")

        case .ground:
            encounter.grounding[actor] = skill.rounds
            encounter.note("\(skill.name): Ashe prepares to receive what escapes its housing.")

        case .envenom:
            encounter.envenomed[actor] = skill.rounds + Tuning.TreeSkills.envenomExtraRounds
            encounter.note("\(skill.name): coated, and it will last a while.")

        case .elemental:
            // **Emanation Strike.** The answer to a warded foe: emanated harm delivered by a blade.
            guard let foe else { return }
            strike(foe.id, damage: power, by: actor, kind: skill.damage ?? weaponKind,
                   run: &run, encounter: &encounter, verb: skill.name,
                   standingBack: standingBack, reachOfActor: reach)
            encounter.statuses[.foe(foe.id), default: []]
                .append(StatusState(kind: .burn, damage: max(1, power / 4), rounds: skill.rounds + 1))
        }

        let cooling = stats.map { CharacterRules.cooldown(skill.cooldownRounds, $0) } ?? skill.cooldownRounds
        encounter.cooldowns[cooldownKey(skill, for: actor)] = cooling
        setCooldown(cooling, for: actor, in: &encounter)
    }

    /// A bestiary entry without a kill — which is what makes Read a real alternative to killing
    /// rather than a convenience.
    private static func remember(_ foe: FoeState, in discovery: inout DiscoveryLog, runIndex: Int) {
        discovery.recordSpecies(foe.identityKey, runIndex: runIndex)
        if foe.isApex { discovery.recordApex(foe.id, species: foe.identityKey, runIndex: runIndex) }
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
    @discardableResult
    private static func afflict(_ target: Combatant, with kind: StatusKind, damage: Int,
                                rounds: Int, encounter: inout EncounterState) -> Bool {
        if consumeStatusGuard(on: target, encounter: &encounter) { return false }
        var carried = encounter.statuses[target] ?? []
        if let index = carried.firstIndex(where: { $0.kind == kind }) {
            carried[index].damage = max(carried[index].damage, damage)
            carried[index].rounds = max(carried[index].rounds, rounds)
        } else {
            carried.append(StatusState(kind: kind, damage: damage, rounds: rounds))
        }
        encounter.statuses[target] = carried
        return true
    }

    private static func consumeStatusGuard(on target: Combatant,
                                           encounter: inout EncounterState) -> Bool {
        guard (encounter.statusGuards[target] ?? 0) > 0 else { return false }
        encounter.statusGuards[target, default: 0] -= 1
        if encounter.statusGuards[target] == 0 { encounter.statusGuards[target] = nil }
        encounter.note("The Stonebark holds; the affliction does not take.")
        return true
    }

    static func has(_ kind: StatusKind, _ actor: Combatant, in encounter: EncounterState) -> Bool {
        (encounter.statuses[actor] ?? []).contains { $0.kind == kind }
    }

    /// **What somebody can take**, which is Fortitude on top of the base (session 17 §1).
    ///
    /// **This is also where the party is put right.** A run begins at these values and health is
    /// run-scoped, so coming home restores everybody — the run is the unit of risk and the base is
    /// where things are mended (Aimee, 6 Aug). Deliberately one place: staged recovery, a healer to
    /// pay, or resting at the tavern are all a change here rather than a hunt.
    static func maximumHealth(of actor: Combatant, in state: GameState) -> Int {
        switch actor {
        case .binder:
            CharacterRules.maximumHealth(state.base.binderCharacter, base: Tuning.Encounter.binderMaxHP)
                + loadout(of: actor, in: state).maxHP
        case .companion(let index):
            CharacterRules.maximumHealth(state.base.character(.member(index)),
                                         base: state.base.roster.indices.contains(index)
                                             ? state.base.roster[index].maxHP
                                             : Tuning.Encounter.companionMaxHP)
                + loadout(of: actor, in: state).maxHP
        case .foe:
            0
        }
    }

    static func health(of actor: Combatant, in run: WorldRun) -> (current: Int, max: Int) {
        switch actor {
        case .binder: (run.binderHP, Tuning.Encounter.binderMaxHP)
        case .companion(let index):
            (run.companionHP[index] ?? Tuning.Encounter.companionMaxHP, Tuning.Encounter.companionMaxHP)
        case .foe(let id):
            run.activeEncounter?.foes.first { $0.id == id }.map { ($0.currentHP, $0.maxHP) } ?? (0, 1)
        }
    }

    static func isAlive(_ actor: Combatant, in run: WorldRun) -> Bool {
        health(of: actor, in: run).current > 0
    }

    /// **Out of the fight, not out of the game** (session 17 §6). Nobody dies here — a companion at
    /// zero has passed out, takes no more turns, and is on their feet again at the base.
    static func hasPassedOut(_ actor: Combatant, in run: WorldRun) -> Bool {
        actor.isParty && health(of: actor, in: run).current <= 0
    }

    // MARK: Resolving one action

    /// Applies an action and hands the turn on. The only way an encounter advances.
    static func perform(_ action: CombatAction, by actor: Combatant, in state: inout GameState) {
        guard var run = state.worlds.activeRun, var encounter = run.activeEncounter, encounter.outcome == nil
        else { return }
        if case .skill(let id, _, _) = action {
            guard let skill = ContentCatalog.shared.skill(id),
                  skills(for: actor, in: state).contains(skill),
                  isReady(skill, for: actor, in: encounter)
            else {
                // Saved palette selections and old Rout actions remain decodable, but an action
                // the actor no longer owns cannot spend a turn during one-way migration.
                return
            }
        }

        switch action {
        case .attack(let foeID):
            strike(foeID, damage: baseAttack(of: actor, in: state), by: actor,
                   kind: damageKind(for: actor, in: state), run: &run, encounter: &encounter,
                   standingBack: rank(of: actor, in: state) == .back,
                   reachOfActor: reach(for: actor, in: state),
                   coating: coating(of: actor, in: state),
                   breaking: wildRule(for: actor, in: state),
                   innateStatus: equipped(.weapon, for: actor, in: state)?.gear?.statusKind)

        case .skill(let id, let foeID, let allyID):
            if let skill = ContentCatalog.shared.skill(id), skills(for: actor, in: state).contains(skill),
               isReady(skill, for: actor, in: encounter) {
                use(skill, by: actor, on: foeID, ally: allyID, run: &run, encounter: &encounter,
                    weaponKind: damageKind(for: actor, in: state),
                    stats: stats(of: actor, in: state),
                    standingBack: rank(of: actor, in: state) == .back,
                    reach: reach(for: actor, in: state), state: &state)
            }

        case .damageSkill(let foeID):
            // The gambit vocabulary's "damage skill" — whichever damaging one is up.
            if let skill = skills(for: actor, in: state).first(where: {
                $0.power > 0 && $0.kind != .heal && isReady($0, for: actor, in: encounter)
            }) {
                use(skill, by: actor, on: foeID, ally: nil, run: &run, encounter: &encounter,
                    weaponKind: damageKind(for: actor, in: state),
                    stats: stats(of: actor, in: state),
                    standingBack: rank(of: actor, in: state) == .back,
                    reach: reach(for: actor, in: state), state: &state)
            }

        case .healSkill(let ally):
            if let skill = ready(.heal, for: actor, in: encounter, state: state) {
                use(skill, by: actor, on: nil, ally: ally, run: &run, encounter: &encounter,
                    weaponKind: damageKind(for: actor, in: state),
                    stats: stats(of: actor, in: state),
                    standingBack: rank(of: actor, in: state) == .back,
                    reach: reach(for: actor, in: state), state: &state)
            }

        case .useItem(let stackID, let ally):
            useItem(stackID, on: ally, run: &run, encounter: &encounter)

        case .flee:
            // Always succeeds — it costs the run, not a dice roll. Vanish pays for one Withdraw
            // per expedition; the receipt prevents a later encounter in the same world reusing it.
            if canVanishWithdraw(actor, in: state) {
                run.vanishWithdrawSpent = true
                encounter.note("The party withdraws without disturbing the world.")
            } else {
                run.stability = max(0, run.stability - Tuning.Encounter.fleeStabilityCost)
                encounter.note("The party withdraws. The world notices.")
            }
            encounter.outcome = .fled
        }

        // The FF12 rule: an override covers that turn and then hands control back.
        if actor.rosterIndex != nil { encounter.isCompanionOverridden = false }
        // Recovery knowledge describes exactly the first completed action after the debt cleared.
        encounter.recoveryComplete.remove(actor)

        run.activeEncounter = encounter
        state.worlds.activeRun = run
        let wasZeroTurnOpeningAttack: Bool = if case .skill(let id, _, _) = action {
            ContentCatalog.shared.skill(id)?.kind == .ambush
        } else { false }
        if encounter.outcome == nil {
            advanceTurn(in: &state, completedAction: !wasZeroTurnOpeningAttack)
        }
        checkOutcome(in: &state)
    }

    private static func baseAttack(of actor: Combatant, in state: GameState) -> Int {
        switch actor {
        case .binder:
            let frozen = state.worlds.activeRun?.activeEncounter?.debugV2BinderAttack
            return binderAttack(in: state)
                + (frozen?.preMatchupBonus(for: frozen?.ordinaryWeaponKind).total ?? 0)
        case .companion(let index): return companionAttack(index, in: state)
        case .foe(let id):
            return state.worlds.activeRun?.activeEncounter?.foes.first { $0.id == id }?.stats.attack ?? 1
        }
    }

    static func debugV2DirectAttackPreview(foe: FoeState, in state: GameState,
                                           standingBack: Bool = false) -> CombatDamageRules.Preview? {
        guard let receipt = state.worlds.activeRun?.activeEncounter?.debugV2BinderAttack else { return nil }
        let power = binderAttack(in: state)
            + receipt.preMatchupBonus(for: receipt.ordinaryWeaponKind).total
        let spread = max(1, Int((Double(power) * Tuning.Encounter.damageVariance).rounded()))
        let range = max(Tuning.Encounter.minimumDamage, power - spread)...max(Tuning.Encounter.minimumDamage,
                                                                               power + spread)
        return CombatDamageRules.preview(rolledPower: range,
            in: .init(damageKind: receipt.ordinaryWeaponKind,
                      covering: foe.traits?.covering ?? Covering(),
                      wildRule: wildRule(for: .binder, in: state),
                      standingBack: standingBack,
                      reach: reach(for: .binder, in: state), armour: foe.stats.armour))
    }

    private static func strike(_ foeID: InstanceID,
                               damage: Int,
                               by actor: Combatant,
                               kind: DamageKind?,
                               run: inout WorldRun,
                               encounter: inout EncounterState,
                               verb: String? = nil,
                               ignoresArmour: Bool = false,
                               standingBack: Bool = false,
                               reachOfActor: Reach = .close,
                               coating: StatusKind? = nil,
                               /// The rule the attacker's weapon breaks, where it breaks one. Passed
                               /// in rather than looked up, because `strike` has no `state` — the
                               /// same reason `coating` is.
                               breaking: WildRule? = nil,
                               innateStatus: String? = nil) {
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
        let rolledPower = roll(around: damage, run: &run)
        let resolved = CombatDamageRules.resolve(
            rolledPower: rolledPower,
            in: .init(damageKind: kind,
                      covering: foe.traits?.covering ?? Covering(),
                      wildRule: breaking,
                      standingBack: standingBack,
                      reach: reachOfActor,
                      armour: foe.stats.armour,
                      ignoresArmour: ignoresArmour)
        )
        let raw = resolved.rawDamage
        let amount = resolved.finalDamage
        encounter.foes[index].currentHP = max(0, encounter.foes[index].currentHP - amount)

        let soaked = raw - amount
        // "You hits" — the log addresses the Binder in the second person, so the verb has to agree.
        let hits = actor == .binder ? "hit" : "hits"
        let note = verb.map { "\(who) — \($0) — \(hits) \(name) for \(amount)." }
            ?? "\(who) \(hits) \(name) for \(amount)."
        encounter.note(soaked > 1 ? note + " Its \(armourWord(for: foe)) takes the rest." : note)

        // **Throughstroke.** It carries the damage that actually landed through the selected foe,
        // rather than rolling a second attack or inventing enemy ranks for one weapon.
        if breaking == .bothRanks,
           let second = encounter.foes.indices.first(where: { $0 != index && encounter.foes[$0].isAlive }) {
            let carried = max(Tuning.Encounter.minimumDamage, amount / 2)
            let secondName = encounter.foes[second].stats.displayName
            encounter.foes[second].currentHP = max(0, encounter.foes[second].currentHP - carried)
            encounter.note("The point keeps going into \(secondName) for \(carried).")
            if !encounter.foes[second].isAlive {
                encounter.note("\(secondName.capitalisedSentence) goes down.")
            }
        }

        // **A volatile weapon leaves something in the wound** (Q36). What your blade was made of
        // reaches the fight, which is what makes an ichor worth carrying home.
        if let coating, encounter.foes[index].isAlive {
            // Reactive material predates the general status collection and is intentionally a
            // wound payload. Preserve that save/behavior contract; prepared Apothecary coatings
            // below use their explicit poison/burn/bleed/dazzle mapping.
            encounter.foeBleeds[foe.id] = BleedState(
                damage: Tuning.Encounter.statusDamage[coating.rawValue] ?? 2,
                rounds: Tuning.Encounter.statusRounds[coating.rawValue] ?? 3)
            encounter.note("Whatever that blade is made of is in the wound now.")
        }

        // Apothecary coatings are prepared choices, not material properties. One successful
        // weapon strike spends the treatment even when the blow itself finishes the foe.
        if let prepared = encounter.preparedCoatings.removeValue(forKey: actor),
           encounter.foes[index].isAlive {
            switch prepared {
            case .bleed:
                encounter.foes[index].bleedRounds = max(encounter.foes[index].bleedRounds,
                                                        Tuning.Encounter.bleedRounds)
            case .poison, .burn, .dazzle:
                let kind: StatusKind = switch prepared {
                case .poison: .poison
                case .burn: .burn
                case .dazzle: .dazzle
                case .bleed: .poison // unreachable; keeps the switch total
                }
                afflict(.foe(foe.id), with: kind,
                        damage: Tuning.Encounter.statusDamage[kind.rawValue] ?? 0,
                        rounds: Tuning.Encounter.statusRounds[kind.rawValue] ?? 2,
                        encounter: &encounter)
            }
            encounter.note("The \(prepared.rawValue) coating leaves the weapon in the wound.")
        }

        // Rending tears: the wound goes on costing it after the blow. This is what finally makes
        // `bleedRounds` live on the foe's side of the fight rather than only on yours.
        //
        // **The Bloodletter's doesn't stop.** Every status in the game has a duration; this is the
        // one thing in it that doesn't, which is the sentence it exists to say.
        if kind == .rend, encounter.foes[index].isAlive {
            encounter.foes[index].bleedRounds = breaking == .endlessBleed
                ? Tuning.Encounter.endlessBleedRounds
                : Tuning.Encounter.bleedRounds
        }

        // **Something in the wound, with nothing consumed to put it there.** Coatings are spent;
        // the Barbed Edge simply is what it is. Its code ID remains `rimed_edge` for old saves.
        if breaking == .innateStatus, encounter.foes[index].isAlive, let named = innateStatus {
            encounter.foeBleeds[foe.id] = BleedState(
                damage: Tuning.Encounter.statusDamage[named] ?? 2,
                rounds: Tuning.Encounter.statusRounds[named] ?? 2)
            encounter.note("The barbs stay in the wound.")
        }

        // **Attacking out of cover, and staying in it.** Nothing else in Shadow allows this.
        if breaking == .quietStrike, (encounter.concealed[actor] ?? 0) > 0 {
            encounter.concealed[actor, default: 0] += 1
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
        case .companion(let index):
            run.companionHP[index] = max(0, (run.companionHP[index] ?? Tuning.Encounter.companionMaxHP) - amount)
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
        case .companion(let index):
            run.companionHP[index] = min(Tuning.Encounter.companionMaxHP,
                                         (run.companionHP[index] ?? Tuning.Encounter.companionMaxHP) + amount)
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

        guard let effect = item.consumable else { return }
        switch effect.effect {
        case .heal:
            heal(ally, by: effect.potency, run: &run, encounter: &encounter,
                 source: item.name, healer: ally)
        case .clearPoison:
            encounter.statuses[ally]?.removeAll { $0.kind == .poison }
            clearBleed(on: ally, encounter: &encounter)
            encounter.note("\(item.name) clears the wound and the poison.")
        case .clearElemental:
            encounter.statuses[ally]?.removeAll { $0.kind == .burn || $0.kind == .dazzle }
            encounter.note("\(item.name) quenches what was clinging to \(actorName(ally, encounter: encounter)).")
        case .clearAnyStatus:
            if !(encounter.statuses[ally]?.isEmpty ?? true) {
                encounter.statuses[ally]?.removeFirst()
            } else {
                clearBleed(on: ally, encounter: &encounter)
            }
            encounter.note("\(item.name) draws one affliction out.")
        case .preventStatus:
            encounter.statusGuards[ally] = max(1, effect.potency)
            encounter.note("\(item.name) will turn aside the next affliction.")
        case .coatPoison, .coatBurn, .coatBleed, .coatDazzle:
            let coating: PreparedCoating = switch effect.effect {
            case .coatPoison: .poison
            case .coatBurn: .burn
            case .coatBleed: .bleed
            case .coatDazzle: .dazzle
            default: .poison
            }
            encounter.preparedCoatings[ally] = coating
            encounter.note("\(item.name) is ready on \(actorName(ally, encounter: encounter))'s weapon.")
        case .restoreStability, .returnHome, .lightWorld, .farsight, .identifyCurio, .lureCreature:
            return
        }
        // Through the bin rather than by poking `count`, so a stack that also carries samples
        // can't have its count drift away from what's actually in it.
        _ = run.satchelItems.stacks[index].removing(1)
        if run.satchelItems.stacks[index].isEmpty {
            run.satchelItems.stacks.remove(at: index)
        }
    }

    private static func clearBleed(on ally: Combatant, encounter: inout EncounterState) {
        switch ally {
        case .binder: encounter.binderBleedRounds = 0
        case .companion: encounter.companionBleedRounds = 0
        case .foe: break
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
        case .companion(let index): encounter.partyNames[index] ?? "Your companion"
        case .foe(let id): encounter.foes.first { $0.id == id }?.stats.displayName ?? "Something"
        }
    }

    /// **What somebody's spent points are worth**, in the fight. One lookup so a node's effect
    /// reaches combat rather than only the tree screen.
    static func loadout(of actor: Combatant, in state: GameState) -> CombatTreeRules.Loadout {
        guard actor.isParty else { return CombatTreeRules.Loadout() }
        return CombatTreeRules.loadout(for: state.base.character(actor.member))
    }

    /// Everybody who came, as combatants. The one place that answers "who is the party".
    static func party(of state: GameState) -> [Combatant] {
        state.base.partyMembers.map(\.combatant)
    }

    // MARK: Turn order

    /// Moves to the next living combatant, ticking the round over when the rotation wraps.
    static func advanceTurn(in state: inout GameState, completedAction: Bool = true) {
        guard var run = state.worlds.activeRun, var encounter = run.activeEncounter else { return }

        // **A turn owed is taken before the order moves on** — that's what Quicken buys, and it
        // has to be spent here rather than by shuffling `order`, which is stored precisely so a
        // death mid-round can't shift whose turn it is.
        let acting = encounter.current
        if completedAction { encounter.completedFirstActions.insert(acting) }
        if let owed = encounter.extraTurns[acting], owed > 0 {
            encounter.extraTurns[acting] = owed - 1
            encounter.note("Again, before it can answer.")
            run.activeEncounter = encounter
            state.worlds.activeRun = run
            return
        }
        var roundTurned = false
        let scheduleCount = max(1, encounter.turnSlots.isEmpty ? encounter.order.count : encounter.turnSlots.count)
        for step in 1...scheduleCount {
            let next = (encounter.turnIndex + step) % scheduleCount
            if next <= encounter.turnIndex { startNewRound(&encounter); roundTurned = true }
            encounter.turnIndex = next
            let who = encounter.turnSlots.isEmpty ? encounter.order[next] : encounter.turnSlots[next].actor
            guard isAlive(who, in: withEncounter(encounter, on: run)) else { continue }
            // …and a turn borrowed is a turn skipped. Overbear and Quicken both pay here.
            if let owing = encounter.skippedTurns[who], owing > 0 {
                encounter.skippedTurns[who] = owing - 1
                if owing == 1 { encounter.recoveryComplete.insert(who) }
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
        encounter.apexTargetsThisRound.removeAll()
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
        // The five the trees leave on somebody. **A clock that never ticks is a permanent effect**,
        // which is what Brace and Conceal would silently have become.
        tick(&encounter.braced); tick(&encounter.dodging); tick(&encounter.concealed)
        tick(&encounter.interposing); tick(&encounter.grounding); tick(&encounter.envenomed)
    }

    private static func tick(_ clock: inout [Combatant: Int]) {
        for (who, rounds) in clock {
            if rounds <= 1 { clock[who] = nil } else { clock[who] = rounds - 1 }
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
        if encounter.companionBleedRounds > 0 {
            encounter.companionBleedRounds -= 1
            for index in run.companionHP.keys where (run.companionHP[index] ?? 0) > 0 {
                run.companionHP[index] = max(0, (run.companionHP[index] ?? 0) - damage)
            }
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
        if encounter.opening?.pendingFoeActions.isEmpty == false { return false }
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
            guard var encounter = state.worlds.activeRun?.activeEncounter else { return }
            if let foeID = encounter.opening?.pendingFoeActions.first {
                encounter.opening?.pendingFoeActions.removeFirst()
                state.worlds.activeRun?.activeEncounter = encounter
                performFoeTurn(.foe(foeID), slot: .init(actor: .foe(foeID)),
                               advancesOrdinarySchedule: false, in: &state)
                continue
            }
            let actor = encounter.current

            switch actor {
            case .foe:
                performFoeTurn(actor, slot: encounter.currentTurnSlot, in: &state)
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
    private static func performFoeTurn(_ actor: Combatant, slot: EncounterState.TurnSlot,
                                       advancesOrdinarySchedule: Bool = true,
                                       in state: inout GameState) {
        guard var run = state.worlds.activeRun, var encounter = run.activeEncounter,
              let foeID = actor.foeID, let foe = encounter.foes.first(where: { $0.id == foeID })
        else { return }

        let standing: [Combatant] = party(of: state).filter { isAlive($0, in: run) }
        let visibleTargets = standing.filter { (encounter.concealed[$0] ?? 0) <= 0 }
        // Concealment redirects attention while another legal target exists; an entirely concealed
        // party does not make the encounter unable to act.
        let targetable = visibleTargets.isEmpty ? standing : visibleTargets

        // **The front rank takes the melee** (session 17 §4). Targeting was uniform, so standing at
        // the back was pure upside — less damage, no more risk of being chosen — which is half a
        // rank system. Something with far reach ignores the line entirely, which is what reach is
        // *for*, and if everybody is at the back there's nobody to hide behind.
        let front = targetable.filter { rank(of: $0, in: state) == .front }
        let reachesPast = foe.stats.strikesFirst || foe.stats.element != nil
        let reachable = (reachesPast || front.isEmpty) ? targetable : front

        // **Draw Off.** Something you've taunted comes for you and doesn't get a choice — the only
        // way in the game to take a hit meant for somebody else.
        let taunted = (encounter.taunts[foeID] ?? 0) > 0 && isAlive(.binder, in: run)
        let unused = reachable.filter { !(encounter.apexTargetsThisRound[foeID] ?? []).contains($0) }
        guard let primary = taunted ? .binder : run.rng.pick(unused.isEmpty ? reachable : unused) else {
            run.activeEncounter = encounter
            state.worlds.activeRun = run
            checkOutcome(in: &state)
            return
        }
        if case .ordinaryPressureFollowUp(let ordinal) = slot.kind {
            encounter.note("Lighter follow-up \(ordinal) — \(foe.stats.displayName.capitalisedSentence).")
        }

        // Delivery decides how many of you it reaches, and at what cost to each blow.
        let isFollowUp: Bool = switch slot.kind {
        case .primary: false
        case .apexFollowUp, .ordinaryPressureFollowUp: true
        }
        let delivery: ([Combatant], Double)
        if isFollowUp {
            delivery = ([primary], slot.strengthMultiplier)
        } else {
            delivery = switch foe.stats.delivery {
            case .single: ([primary], 1)
            case .multi: (targetable, Tuning.Encounter.multiDeliveryShare)
            case .area: (targetable, Tuning.Encounter.areaDeliveryShare)
            }
        }
        let (targets, share) = delivery

        for originalTarget in targets {
            let hasLighterFollowUp = encounter.turnSlots.contains {
                $0.actor == .foe(foeID) && $0.kind != .primary
            }
            if (foe.isApex || hasLighterFollowUp),
               !(encounter.apexTargetsThisRound[foeID] ?? []).contains(originalTarget) {
                encounter.apexTargetsThisRound[foeID, default: []].append(originalTarget)
            }
            var target = originalTarget
            var grounded = false
            if foe.stats.element != nil, !encounter.snuffed.contains(foeID),
               let ashe = standing.first(where: { member in
                   member.rosterIndex.flatMap {
                       state.base.roster.indices.contains($0) ? state.base.roster[$0].traveller : nil
                   } == TravellerID(rawValue: "ashe")
               }), originalTarget != ashe, (encounter.grounding[ashe] ?? 0) > 0 {
                encounter.grounding.removeValue(forKey: ashe)
                target = ashe
                grounded = true
                encounter.note("Ground: Ashe receives the emanation meant for \(actorName(originalTarget, encounter: encounter).lowercased()).")
            }
            // **Not where the blow landed** (session 17 §1). Finesse on the party's side, the
            // mirror of the evasion creatures have had since they were generated.
            if evades(target, in: state, run: &run) {
                encounter.note("\(foe.stats.displayName.capitalisedSentence) finds nothing where \(actorName(target, encounter: encounter).lowercased()) was.")
                continue
            }
            var raw = Double(roll(around: foe.stats.attack, run: &run)) * share
            if grounded { raw *= 0.5 }
            if foe.stats.damageKind == .crush { raw *= 1 + Tuning.Encounter.crushDamageBonus }

            // **What you're wearing turns aside heat**, whatever it was made of (Q36).
            if foe.stats.element == .heat {
                raw *= 1 - min(Tuning.Encounter.maximumInsulation,
                               insulation(of: target, in: state) * Tuning.Encounter.insulationPerPoint)
            }

            // **Ward.** Turns aside one harm, so you have to know what's coming — which is what
            // Sight is for. Guessing wrong costs you the round you spent setting it.
            let incoming: Harm = (encounter.snuffed.contains(foeID) ? nil : foe.stats.element)
                .map(Harm.emanation) ?? .blow(foe.stats.damageKind)
            if encounter.wards[target]?.harm == incoming {
                raw *= 1 - Tuning.Encounter.wardReduction
            }
            // The Haft is a modest continuous ward against one authored blow type. Applied after
            // the skill ward so the two stack multiplicatively rather than replacing each other.
            if case .blow(let kind) = incoming {
                raw *= wardedHaftMultiplier(against: kind, for: target, in: state)
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
            let wasStanding = isAlive(target, in: run)
            hurt(target, by: amount, run: &run, encounter: &encounter)
            if wasStanding, !isAlive(target, in: run), target.rosterIndex != nil {
                encounter.note("\(actorName(target, encounter: encounter)) goes down. They'll be all right at home.")
            }

            let verb = (encounter.snuffed.contains(foeID) ? nil : foe.stats.element)
                .map(elementalVerb) ?? foe.stats.damageKind.verb
            // "You" is a pronoun mid-sentence and "Quill" is a name, so only one of them lowers.
            let whom = target == .binder
                ? actorName(target, encounter: encounter).lowercased()
                : actorName(target, encounter: encounter)
            encounter.note("\(foe.stats.displayName.capitalisedSentence) \(verb) \(whom) for \(amount).")

            // Rend's wound outlives the blow.
            if foe.stats.damageKind == .rend, !slot.suppressesAfflictions {
                if !consumeStatusGuard(on: target, encounter: &encounter) {
                    switch target {
                    case .binder: encounter.binderBleedRounds = Tuning.Encounter.bleedRounds
                    case .companion: encounter.companionBleedRounds = Tuning.Encounter.bleedRounds
                    case .foe: break
                    }
                    encounter.note("The wound won't close.")
                }
            }

            // **And so does what it gives off** (Q42). Emanation was generated, named in the
            // description, and did nothing beyond one armour-ignoring hit. Snuff puts a stop to it.
            if let element = foe.stats.element, !encounter.snuffed.contains(foeID), !slot.suppressesAfflictions {
                let status = StatusKind.from(element)
                let landed = afflict(target, with: status,
                                     damage: Tuning.Encounter.statusDamage[status.rawValue] ?? 0,
                                     rounds: Tuning.Encounter.statusRounds[status.rawValue] ?? 2,
                                     encounter: &encounter)
                if landed {
                    encounter.note(status == .dazzle
                                   ? "The after-image sits in your eyes."
                                   : "It's still \(status == .burn ? "burning" : "spreading").")
                }
            }
        }

        run.activeEncounter = encounter
        state.worlds.activeRun = run
        if advancesOrdinarySchedule { advanceTurn(in: &state) }
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
            awardExperience(for: encounter.foes, run: &run, encounter: &encounter, state: &state)
            let grown = growLivingHooks(in: &state)
            encounter.spoils.append(contentsOf: grown)
        } else if run.binderHP <= 0 {
            // **Nobody dies, and the Binder going down ends the run** (session 17 §6): *"companions
            // can never die. They pass out and are revived back in town. If the Binder passes out,
            // it's treated exactly like a world collapsing."*
            //
            // This used to require **both** of you to be down, which meant a Binder at zero kept
            // walking around a world on Quill's legs. The Binder is the one holding the book.
            encounter.outcome = .defeated
            encounter.note("You go down. Somebody gets you home.")
        }
        run.activeEncounter = encounter
        state.worlds.activeRun = run
    }

    /// One growth credit per won encounter, regardless of hits or killing blows. Growth belongs to
    /// the equipped instance and is distinct from Blacksmith upgrades.
    private static func growLivingHooks(in state: inout GameState) -> [String] {
        var lines: [String] = []
        func grow(_ piece: inout EquippedPiece?) {
            guard piece?.gear?.breaks == .growingGrade,
                  let current = piece?.wildGrowth,
                  current < Tuning.Apex.livingHookGrowthCap else { return }
            piece?.wildGrowth = current + 1
            if let name = piece?.displayName { lines.append("\(name) grew after the fight") }
        }
        grow(&state.base.binderEquipped[.weapon])
        for index in state.base.activeParty where state.base.roster.indices.contains(index) {
            grow(&state.base.roster[index].equipped[.weapon])
        }
        return lines
    }

    /// **What the fight was worth**, scaled by what you beat rather than flat — picking on
    /// something far below you stops paying (session 17 §2).
    ///
    /// Both of them get it. A companion who levelled only when you did wouldn't be a character,
    /// and one who levelled separately would drift out of the party.
    private static func awardExperience(for foes: [FoeState], run: inout WorldRun,
                                        encounter: inout EncounterState,
                                        state: inout GameState) {
        let partyLevel = state.base.partyMembers.map { state.base.character($0).level }.max() ?? 1
        let earned = foes.reduce(0) {
            $0 + CharacterRules.experience(forDefeating: $1, partyLevel: partyLevel)
        }
        guard earned > 0 else { return }

        var gained: [String] = []
        for member in state.base.partyMembers {
            var levels = 0
            state.base.withCharacter(member) { levels = CharacterRules.award(earned, to: &$0) }
            if levels > 0 {
                let name: String
                if let index = member.rosterIndex, state.base.roster.indices.contains(index) {
                    name = "\(state.base.roster[index].name) is"
                } else {
                    name = "You are"
                }
                gained.append("\(name) level \(state.base.character(member).level).")
            }
        }
        run.experienceBreakdown.combat += earned
        encounter.note("\(earned) experience.")
        for line in gained { encounter.note(line) }
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

            // **What an apex leaves, and what luck occasionally leaves instead** (`apex-encounters.md`
            // §4–5). The apex is the *reliable* path and the lottery is the surprise: a player who
            // never fights one still occasionally finds something they cannot make, and that is a
            // better memory than a guaranteed drop precisely because it wasn't earned.
            let hunted = foe.isApex
            if hunted || run.rng.chance(Tuning.Apex.ordinaryCreatureChance) {
                let readings = BookRules.readings(for: run.book, seed: run.mapSeed)
                if let id = ApexRules.weapon(for: readings, rng: &run.rng) {
                    let name = ContentCatalog.shared.item(id)?.name ?? "Something you couldn't make"
                    let stack = ItemStack(id: InstanceID(rawValue: run.rng.next()), catalogID: id)
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

        let events: [WorldRules.Event] = []

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
