import XCTest
@testable import Bookbinder

/// Encounters and the gambit engine.
@MainActor
final class CombatTests: XCTestCase {

    // MARK: Setup helpers

    /// A store already standing in a world, with a fight in progress against `creatures`.
    /// Rule shorthands, so tests read as intent rather than as component ids.
    static let attackAny = GambitRule(id: InstanceID(rawValue: 101),
                                      subject: "subject_foe_any", action: "act_attack")
    static let attackWeakest = GambitRule(id: InstanceID(rawValue: 102),
                                          subject: "subject_foe_lowest", action: "act_attack")
    static let healHurtAlly = GambitRule(id: InstanceID(rawValue: 103),
                                         subject: "subject_ally_any",
                                         property: "prop_hp", comparator: "cmp_below", threshold: "thr_50",
                                         action: "act_heal")

    private func inFight(_ creatures: [CreatureID] = ["paper_moth"],
                         gambits: [GambitRule]? = nil) -> GameStore {
        let store = GameStore(io: .temporary(name: "combat-\(UUID().uuidString)"))
        store.setSymbol("plains", in: "terrain")
        store.bindAndDepart()
        if let gambits {
            store.mutate("set rules") { state in
                // Tests may use components a fresh game hasn't learned; grant them so the rule is
                // legal to run rather than silently skipped.
                state.base.ownedGambitComponents = Set(ContentCatalog.shared.gambitComponents.map(\.id))
                state.base.companion.gambits = gambits
            }
        }
        store.mutate("stage a fight") { state in
            guard var run = state.worlds.activeRun else { return }
            let enemies = creatures.enumerated().map { index, id in
                WorldEnemy(id: InstanceID(rawValue: UInt64(index + 1)), creatureID: id,
                           position: run.playerPosition, isAwake: true)
            }
            run.enemies = enemies
            state.worlds.activeRun = run
            WorldRules.beginEncounter(triggeredBy: enemies[0], in: &state)
        }
        return store
    }

    private func foes(_ store: GameStore) -> [FoeState] {
        store.activeEncounter?.foes ?? []
    }

    // MARK: Structure

    func testFoesCarryTheirOwnResolvedStats() throws {
        let store = inFight(["ink_hound"])
        let foe = try XCTUnwrap(foes(store).first)
        let creature = try XCTUnwrap(ContentCatalog.shared.creature("ink_hound"))

        XCTAssertEqual(foe.stats.maxHP, creature.maxHP)
        XCTAssertEqual(foe.stats.attack, creature.attack)
        XCTAssertEqual(foe.stats.displayName, creature.name)
        XCTAssertEqual(foe.currentHP, creature.maxHP)
    }

    /// The point of storing resolved stats: a fight keeps working when the catalog entry that
    /// spawned it is gone — which is what happens once creatures are generated, not authored.
    func testAFightSurvivesItsCreatureVanishingFromTheCatalog() throws {
        let store = inFight()
        store.mutate("content rewritten under us") { state in
            state.worlds.activeRun?.activeEncounter?.foes[0].creatureID = "a_creature_that_no_longer_exists"
        }
        XCTAssertNil(ContentCatalog.shared.creature("a_creature_that_no_longer_exists"))

        let before = try XCTUnwrap(foes(store).first).currentHP
        store.takeCombatAction(.attack(foe: try XCTUnwrap(foes(store).first).id))

        XCTAssertLessThan(try XCTUnwrap(foes(store).first).currentHP, before,
                          "The fight still resolves against stored stats")
    }

    func testTurnOrderIsPartyThenEnemiesAndSkipsTheDead() throws {
        let store = inFight(["paper_moth", "paper_moth"])
        let encounter = try XCTUnwrap(store.activeEncounter)

        XCTAssertEqual(encounter.order.first, .binder)
        XCTAssertEqual(encounter.order.dropFirst().first, .companion)
        XCTAssertEqual(encounter.order.count, 4)
        XCTAssertEqual(encounter.current, .binder, "The player moves first")
    }

    // MARK: Fighting

    func testAttackingDamagesTheTargetAndHandsTheTurnOn() throws {
        let store = inFight()
        let foeID = try XCTUnwrap(foes(store).first).id
        let before = try XCTUnwrap(foes(store).first).currentHP

        store.takeCombatAction(.attack(foe: foeID))

        XCTAssertLessThan(try XCTUnwrap(foes(store).first).currentHP, before)
        // The invariant that matters: after one tap, either the fight is over or it's your move
        // again. The player is never left looking at a screen that's waiting on nobody.
        let finished = store.activeEncounter?.outcome != nil
        XCTAssertTrue(finished || store.actingCombatant == .binder)
    }

    func testWinningRemovesTheEnemyFromTheMapAndPaysOut() throws {
        let store = inFight()
        var guardCount = 0
        while store.activeEncounter?.outcome == nil, guardCount < 30 {
            guardCount += 1
            guard let foe = foes(store).first(where: \.isAlive) else { break }
            store.takeCombatAction(.attack(foe: foe.id))
        }

        XCTAssertEqual(store.activeEncounter?.outcome, .victory)
        store.endEncounterIfFinished()

        XCTAssertNil(store.activeEncounter)
        XCTAssertTrue(store.state.worlds.activeRun?.enemies.isEmpty ?? false,
                      "A defeated foe must leave the grid or the fight re-triggers forever")
        XCTAssertEqual(store.state.reality.lifetime.encountersWon, 1)
        XCTAssertFalse(store.state.worlds.activeRun?.satchel.isEmpty ?? true, "Victory pays out")
    }

    func testFleeingAlwaysWorksAndCostsTheRun() throws {
        let store = inFight()
        store.mutate("step in from somewhere") { state in
            guard var run = state.worlds.activeRun else { return }
            run.previousPosition = run.map.neighbours(of: run.playerPosition)
                .first { WorldRules.canEnter($0, in: run.map) }
            state.worlds.activeRun = run
        }
        let stabilityBefore = try XCTUnwrap(store.state.worlds.activeRun).stability
        let retreat = try XCTUnwrap(store.state.worlds.activeRun?.previousPosition)

        store.takeCombatAction(.flee)
        XCTAssertEqual(store.activeEncounter?.outcome, .fled)
        store.endEncounterIfFinished()

        let run = try XCTUnwrap(store.state.worlds.activeRun)
        XCTAssertEqual(run.stability, stabilityBefore - Tuning.Encounter.fleeStabilityCost, accuracy: 0.001)
        XCTAssertEqual(run.playerPosition, retreat, "Fleeing retreats the way you came")
        XCTAssertGreaterThan(run.encounterGraceTurns, 0, "…and buys a moment before the next bump")
        XCTAssertFalse(run.enemies.isEmpty, "Fleeing doesn't kill anything")
    }

    func testSkillGoesOnCooldownAndComesBack() throws {
        let store = inFight(["ink_hound"])
        XCTAssertTrue(store.isSkillReady)
        let skill = try XCTUnwrap(store.currentSkill)

        store.takeCombatAction(.damageSkill(foe: try XCTUnwrap(foes(store).first).id))
        let encounter = try XCTUnwrap(store.activeEncounter)
        XCTAssertGreaterThan(encounter.binderSkillCooldown, 0)
        XCTAssertFalse(store.isSkillReady, "A skill just used is not ready again")
        XCTAssertLessThanOrEqual(encounter.binderSkillCooldown, skill.cooldownRounds)
    }

    // MARK: The pillar

    /// Being mid-fight is the hardest resume case in the game. It has to be exact.
    func testAFightSurvivesAForceQuitMidRound() throws {
        let io = SaveFileIO.temporary(name: "fight-kill-\(UUID().uuidString)")
        defer { io.deleteEverything() }

        let first = GameStore(io: io)
        first.setSymbol("caverns", in: "terrain")
        first.bindAndDepart()
        first.mutate("stage a fight") { state in
            guard var run = state.worlds.activeRun else { return }
            run.enemies = [WorldEnemy(id: InstanceID(rawValue: 9), creatureID: "ink_hound",
                                      position: run.playerPosition, isAwake: true)]
            state.worlds.activeRun = run
            WorldRules.beginEncounter(triggeredBy: run.enemies[0], in: &state)
        }
        first.takeCombatAction(.attack(foe: InstanceID(rawValue: 9)))
        first.flushNow()
        let before = try XCTUnwrap(first.activeEncounter)

        let second = GameStore(io: io) // cold launch
        let after = try XCTUnwrap(second.activeEncounter)

        XCTAssertEqual(after, before, "Resuming lands in the same round of the same fight")
        XCTAssertEqual(second.state.worlds.activeRun?.rng, first.state.worlds.activeRun?.rng)
    }

    // MARK: Gambits

    /// Acceptance criterion: the companion fights a full encounter unattended.
    ///
    /// Deliberately an Ink Hound rather than a Paper Moth: a moth has 8 HP and the Binder hits for
    /// 4–8, so it can die before the companion ever gets a turn. That made this test pass or fail on
    /// a damage roll — it was asserting luck, not behaviour.
    func testTheCompanionFightsUnattended() throws {
        let store = inFight(["ink_hound"], gambits: [Self.attackAny])

        var guardCount = 0
        while store.activeEncounter?.outcome == nil, guardCount < 30 {
            guardCount += 1
            // The player does nothing but pass their own turn along.
            guard let foe = foes(store).first(where: \.isAlive) else { break }
            store.takeCombatAction(.attack(foe: foe.id))
        }

        let log = store.activeEncounter?.log.joined(separator: "\n") ?? ""
        XCTAssertTrue(log.contains("Quill"), "The companion acted on its own:\n\(log)")
    }

    /// Acceptance criterion: reordering rules visibly changes behaviour.
    func testRuleOrderChangesWhatTheCompanionDoes() throws {
        // Heal-first vs attack-first, with an ally hurt enough to trigger the heal.
        let healFirst = inFight(["paper_moth"], gambits: [Self.healHurtAlly, Self.attackAny])
        let attackFirst = inFight(["paper_moth"], gambits: [Self.attackAny, Self.healHurtAlly])

        for store in [healFirst, attackFirst] {
            store.mutate("hurt the binder") { $0.worlds.activeRun?.binderHP = 5 }
        }

        let healDecision = try XCTUnwrap(GambitEngine.decide(in: healFirst.state))
        let attackDecision = try XCTUnwrap(GambitEngine.decide(in: attackFirst.state))

        XCTAssertEqual(healDecision.rule, Self.healHurtAlly)
        XCTAssertEqual(attackDecision.rule, Self.attackAny)
        XCTAssertNotEqual(healDecision.action, attackDecision.action,
                          "Same rules, different order, different behaviour")
    }

    /// The subtle one: a matching rule whose action can't happen falls through to the next rule,
    /// rather than wasting the turn.
    func testARuleThatCannotActFallsThroughToTheNext() throws {
        let store = inFight(["paper_moth"], gambits: [Self.healHurtAlly, Self.attackAny])
        store.mutate("hurt the binder, put the heal on cooldown") { state in
            state.worlds.activeRun?.binderHP = 5
            state.worlds.activeRun?.activeEncounter?.companionSkillCooldown = 2
        }

        let decision = try XCTUnwrap(GambitEngine.decide(in: store.state))
        XCTAssertEqual(decision.rule, Self.attackAny,
                       "Heal is on cooldown, so the rule below it fires instead")
    }

    func testRulesBeyondTheSlotCountDoNotFire() throws {
        // Three rules, two slots: the third is owned but idle.
        let store = inFight(["paper_moth"],
                            gambits: [Self.attackWeakest, Self.attackAny, Self.healHurtAlly])
        store.mutate("hurt the binder") { $0.worlds.activeRun?.binderHP = 1 }

        XCTAssertEqual(store.activeGambitSlots, Tuning.Encounter.startingGambitSlots)
        let decision = try XCTUnwrap(GambitEngine.decide(in: store.state))
        XCTAssertNotEqual(decision.rule, Self.healHurtAlly, "A rule with no slot must not fire")
    }

    func testNoMatchingRuleMeansTheCompanionWaits() throws {
        let store = inFight(["paper_moth"], gambits: [Self.healHurtAlly])
        // Everyone is healthy, so the only rule can't match.
        XCTAssertNil(GambitEngine.decide(in: store.state))
    }

    // MARK: Manual override

    func testOverrideHandsOneTurnToThePlayerThenClears() throws {
        let store = inFight(["ink_hound"], gambits: [Self.attackAny])

        store.toggleCompanionOverride()
        XCTAssertTrue(try XCTUnwrap(store.activeEncounter).isCompanionOverridden)

        // Take the Binder's turn; the game should now stop and wait on the companion.
        store.takeCombatAction(.attack(foe: try XCTUnwrap(foes(store).first).id))
        XCTAssertEqual(store.actingCombatant, .companion, "The override stops the gambits taking over")

        store.takeCombatAction(.attack(foe: try XCTUnwrap(foes(store).first).id))
        XCTAssertFalse(store.activeEncounter?.isCompanionOverridden ?? true,
                       "An override covers one turn, then hands control back")
    }

    // MARK: Editing rules

    /// Gambit editing is out-of-combat only. A locked decision, enforced in the store rather than
    /// only hidden in the UI.
    func testGambitsCannotBeEditedMidFight() throws {
        let store = inFight(["paper_moth"], gambits: [Self.attackAny, Self.attackWeakest])
        let before = store.state.base.companion.gambits

        XCTAssertFalse(store.canEditGambits)
        store.moveGambit(from: IndexSet(integer: 0), to: 2)
        store.removeGambit(at: IndexSet(integer: 0))
        store.addGambit(Self.healHurtAlly)

        XCTAssertEqual(store.state.base.companion.gambits, before, "Nothing may change mid-fight")
    }

    func testGambitsCanBeReorderedAtBase() throws {
        let store = GameStore(io: .temporary(name: "party-\(UUID().uuidString)"))
        store.mutate("set rules") { $0.base.companion.gambits = [Self.attackAny, Self.attackWeakest] }

        XCTAssertTrue(store.canEditGambits)
        store.moveGambit(from: IndexSet(integer: 1), to: 0)
        XCTAssertEqual(store.state.base.companion.gambits, [Self.attackWeakest, Self.attackAny])
    }

    // MARK: - Fighting what the world grew (creature-system-spec §7)

    /// A fight against a species, rather than against a catalogue entry.
    private func inFightWith(_ traits: [CreatureTraits]) -> GameStore {
        let store = GameStore(io: .temporary(name: "traits-\(UUID().uuidString)"))
        store.setSymbol("plains", in: "terrain")
        store.bindAndDepart()
        store.mutate("stage a fight") { state in
            guard var run = state.worlds.activeRun else { return }
            run.cast = traits.enumerated().map { index, t in
                Species(id: InstanceID(rawValue: UInt64(index + 1)), traits: t, worldSeed: 1)
            }
            run.enemies = run.cast.map { species in
                WorldEnemy(id: InstanceID(rawValue: species.id.rawValue), speciesID: species.id,
                           traits: species.traits, position: run.playerPosition, isAwake: true)
            }
            state.worlds.activeRun = run
            WorldRules.beginEncounter(triggeredBy: run.enemies[0], in: &state)
        }
        return store
    }

    private func armoured() -> CreatureTraits {
        var t = CreatureTraits()
        t.size = 85; t.build = 92; t.boneDensity = 75
        t.covering = Covering(hardness: 90, length: 15, coverage: 95)
        t.armament.mix = WeaponMix(pierce: 0, crush: 1, rend: 0)
        t.armament.setTotal(70)
        return t
    }

    func testAFoeGrownByTheWorldFightsFromItsTraits() throws {
        let store = inFightWith([armoured()])
        let foe = try XCTUnwrap(foes(store).first)

        XCTAssertNil(foe.creatureID, "a grown creature reached for the old catalogue")
        XCTAssertNotNil(foe.traits)
        XCTAssertGreaterThan(foe.stats.armour, 0, "plate that covers 95% of it soaked nothing")
        XCTAssertEqual(foe.stats.damageKind, .crush)
        XCTAssertEqual(foe.currentHP, foe.stats.maxHP)
    }

    /// **Armour makes a fight longer, not unwinnable.** A hit always does something.
    func testArmourSoaksButNeverStopsYouEntirely() throws {
        let store = inFightWith([armoured()])
        let foe = try XCTUnwrap(foes(store).first)
        let before = foe.currentHP
        store.takeCombatAction(.attack(foe: foe.id))
        let after = try XCTUnwrap(foes(store).first).currentHP

        XCTAssertLessThan(after, before, "armour made it untouchable")
        XCTAssertGreaterThanOrEqual(before - after, Tuning.Encounter.minimumDamage)
    }

    /// **Warning colours are honest** — hitting something that advertises costs you.
    func testHittingSomethingThatAdvertisesCostsYou() throws {
        // Big and thick-boned, so it survives the blow — retaliation only happens if there's
        // something left to retaliate. And the turn is handed to the Binder explicitly, because
        // initiative decides who swings first and this test isn't about that.
        var toxic = CreatureTraits()
        toxic.size = 90
        toxic.boneDensity = 90
        toxic.isToxic = true
        toxic.covering = Covering(hardness: 0, length: 0, coverage: 40)
        let store = inFightWith([toxic])
        let foe = try XCTUnwrap(foes(store).first)
        giveTheTurnTo(.binder, in: store)
        let hpBefore = store.state.worlds.activeRun?.binderHP ?? 0

        store.mutate("test: swing at it") {
            CombatRules.perform(.attack(foe: foe.id), by: .binder, in: &$0)
        }

        XCTAssertLessThan(store.state.worlds.activeRun?.binderHP ?? 0, hpBefore,
                          "you traded blows with something toxic and paid nothing")
    }

    /// Reach beats speed at the moment of contact, whatever the initiative says.
    func testSomethingWithLongReachOpensTheFight() throws {
        var reacher = CreatureTraits()
        reacher.size = 90; reacher.boneDensity = 90   // slow by every other measure
        reacher.armament.reach = .far
        let store = inFightWith([reacher])
        let encounter = try XCTUnwrap(store.activeEncounter)

        XCTAssertEqual(encounter.order.first?.foeID, foes(store).first?.id,
                       "the thing with the longest reach waited its turn")
    }

    /// Sleek and small goes before you; huge and armoured goes after.
    func testTurnOrderComesOffWhatThingsAre() throws {
        var quick = CreatureTraits()
        quick.size = 12; quick.build = Tuning.Life.sleekBuild; quick.boneDensity = 5
        quick.covering = Covering(hardness: 0, length: 0, coverage: 20)

        let fast = inFightWith([quick])
        XCTAssertEqual(try XCTUnwrap(fast.activeEncounter).order.first?.foeID,
                       foes(fast).first?.id, "something built to run didn't get the jump on you")

        let slow = inFightWith([armoured()])
        XCTAssertEqual(try XCTUnwrap(slow.activeEncounter).order.first, .binder,
                       "a huge armoured thing outran you")
    }

    /// Rend leaves a wound that keeps costing you after the blow lands.
    func testARendingCreatureLeavesAWoundThatKeepsCosting() throws {
        var render = CreatureTraits()
        render.size = 50
        render.armament.mix = WeaponMix(pierce: 0, crush: 0, rend: 1)
        render.armament.setTotal(80)
        let store = inFightWith([render])

        // Let the fight run until it has hit somebody.
        for _ in 0..<6 where store.activeEncounter?.outcome == nil {
            if let foe = foes(store).first(where: \.isAlive) {
                store.takeCombatAction(.attack(foe: foe.id))
            }
        }
        let encounter = try XCTUnwrap(store.activeEncounter)
        XCTAssertTrue(encounter.binderBleedRounds > 0 || encounter.companionBleedRounds > 0
                      || encounter.log.contains { $0.contains("bleeding") || $0.contains("won\'t close") },
                      "nothing rent anybody in six rounds against a pure render")
    }

    /// **Crypsis is a map behaviour**: it isn't there until it's on you.
    func testSomethingMatchedToTheGroundDoesntShowUntilItsOnYou() {
        let store = GameStore(io: .temporary(name: "crypsis-\(UUID().uuidString)"))
        store.setSymbol("plains", in: "terrain")
        store.bindAndDepart()
        store.mutate("hide something") { state in
            guard var run = state.worlds.activeRun else { return }
            var hidden = CreatureTraits()
            hidden.defence = .crypsis
            let far = GridPoint(x: run.playerPosition.x + 5, y: run.playerPosition.y)
            let near = GridPoint(x: run.playerPosition.x + 1, y: run.playerPosition.y)
            run.enemies = [
                WorldEnemy(id: InstanceID(rawValue: 1), traits: hidden, position: far),
                WorldEnemy(id: InstanceID(rawValue: 2), traits: hidden, position: near)
            ]
            state.worlds.activeRun = run
        }
        let run = store.state.worlds.activeRun!
        XCTAssertFalse(WorldRules.isVisible(run.enemies[0], in: run), "you saw it coming")
        XCTAssertTrue(WorldRules.isVisible(run.enemies[1], in: run), "it stayed invisible on top of you")
    }

    /// A mid-encounter save written before a stat existed must still load. This is the acceptance
    /// criterion the brief names by hand, and the shape of the bug that quarantined a real save.
    func testAnEncounterMissingEveryNewFieldStillLoads() throws {
        let json = """
        {"id": {"rawValue": 1}, "foes": [], "order": []}
        """
        let encounter = try SaveCodec.makeDecoder().decode(EncounterState.self, from: Data(json.utf8))
        XCTAssertEqual(encounter.roundNumber, 1)
        XCTAssertEqual(encounter.binderBleedRounds, 0)
        XCTAssertNil(encounter.outcome)
    }

    /// **A fight is never left waiting on nobody.** Turn order comes off initiative now, so an
    /// encounter can open on a creature's turn — and if nothing kicks the automatic turns off, the
    /// player is looking at a screen where their own buttons do nothing.
    func testAFightThatOpensOnACreaturesTurnStillStarts() throws {
        var quick = CreatureTraits()
        quick.size = 10; quick.build = Tuning.Life.sleekBuild; quick.boneDensity = 0
        quick.covering = Covering(hardness: 0, length: 0, coverage: 10)
        let store = inFightWith([quick])

        let encounter = try XCTUnwrap(store.activeEncounter)
        XCTAssertEqual(encounter.order.first?.foeID, foes(store).first?.id,
                       "this test needs the creature to be first, or it proves nothing")
        XCTAssertTrue(store.actingCombatant == .binder || encounter.outcome != nil,
                      "the fight opened on the creature's turn and then nobody moved")
        XCTAssertGreaterThan(encounter.log.count, 1, "the creature that went first did nothing")
    }

    // MARK: - Damage types versus armour (combat-depth-spec §1)

    /// **The change that closes the loop.** Pierce and crush beat hard coverings; rend beats thick
    /// soft ones. A plated bulwark and a shaggy browser were fought identically before this.
    func testTheRightDamageTypeIsWorthMoreThanTheWrong() {
        var plated = CreatureTraits()
        plated.covering = Covering(hardness: 95, length: 5, coverage: 95)
        var furred = CreatureTraits()
        furred.covering = Covering(hardness: 5, length: 95, coverage: 95)

        XCTAssertGreaterThan(CombatRules.effectiveness(of: .pierce, against: plated.covering),
                             CombatRules.effectiveness(of: .rend, against: plated.covering),
                             "rending a plated thing did as well as piercing it")
        XCTAssertGreaterThan(CombatRules.effectiveness(of: .rend, against: furred.covering),
                             CombatRules.effectiveness(of: .pierce, against: furred.covering),
                             "piercing a pelt did as well as tearing it")
        XCTAssertGreaterThan(CombatRules.effectiveness(of: .crush, against: plated.covering), 1)
    }

    /// A bad matchup is wasteful, never useless — a fight you can't win with what you brought is a
    /// dead end rather than a decision.
    func testNoMatchupIsEverCompletelyUseless() {
        var plated = CreatureTraits()
        plated.covering = Covering(hardness: 100, length: 100, coverage: 100)
        for kind in DamageKind.allCases {
            XCTAssertGreaterThanOrEqual(CombatRules.effectiveness(of: kind, against: plated.covering),
                                        Tuning.Encounter.minimumMatchup)
        }
    }

    /// Something wearing nothing much doesn't care what you're swinging.
    func testABareCreatureIsIndifferentToWhatYouSwing() {
        let bare = Covering(hardness: 0, length: 0, coverage: 10)
        let spread = DamageKind.allCases.map { CombatRules.effectiveness(of: $0, against: bare) }
        XCTAssertEqual(spread.max()! - spread.min()!, 0, accuracy: 0.05)
    }

    /// The read that makes the matchup a decision: the encounter says what it's wearing.
    func testTheEncounterSaysWhatItIsWearing() {
        var plated = CreatureTraits()
        plated.covering = Covering(hardness: 90, length: 5, coverage: 90)
        let foe = FoeState(id: InstanceID(rawValue: 1), traits: plated,
                           stats: CombatStats.derived(from: plated, name: "x", icon: "y"),
                           currentHP: 10)
        XCTAssertEqual(foe.coveringWord, "plated")

        var furred = CreatureTraits()
        furred.covering = Covering(hardness: 5, length: 90, coverage: 90)
        let soft = FoeState(id: InstanceID(rawValue: 2), traits: furred,
                            stats: CombatStats.derived(from: furred, name: "x", icon: "y"),
                            currentHP: 10)
        XCTAssertEqual(soft.coveringWord, "furred")
    }

    /// The party's weapon carries its type into the fight, and a rending one leaves a wound.
    func testARendingWeaponLeavesAWoundOnTheThingYouHit() throws {
        var thick = CreatureTraits()
        thick.size = 60
        thick.covering = Covering(hardness: 5, length: 90, coverage: 90)
        let store = inFightWith([thick])
        // **Both of them carry it.** Turn order comes off initiative now, so whether the Binder or
        // Quill swings first varies with the seed — arming only one made this assert about whoever
        // happened to go first.
        store.mutate("carry something that tears") { state in
            state.base.companion.equipped[.weapon] = "blade_chipped"   // rend
            state.base.binderEquipped[.weapon] = "blade_chipped"
        }
        let foe = try XCTUnwrap(foes(store).first)
        store.takeCombatAction(.attack(foe: foe.id))

        XCTAssertTrue(foes(store).first?.bleedRounds ?? 0 > 0 || foes(store).first?.isAlive == false,
                      "a rending weapon left no wound")
    }

    /// A piercing weapon goes through a share of plate rather than all of it.
    func testPiercingGoesThroughSomeOfWhatItIsWearing() throws {
        var plated = CreatureTraits()
        plated.size = 70
        plated.covering = Covering(hardness: 95, length: 5, coverage: 95)

        func damageDealt(with weapon: EquippedPiece?) throws -> Int {
            let store = inFightWith([plated])
            store.mutate("equip") { state in
                state.base.companion.equipped[.weapon] = weapon
                state.base.binderEquipped[.weapon] = weapon
            }
            let foe = try XCTUnwrap(foes(store).first)
            let before = foe.currentHP
            store.takeCombatAction(.attack(foe: foe.id))
            return before - (foes(store).first?.currentHP ?? 0)
        }

        // Averaged over the damage wobble, piercing plate has to beat tearing at it.
        var pierce = 0, rend = 0
        for _ in 0..<12 {
            pierce += try damageDealt(with: "blade_keen")
            rend += try damageDealt(with: "blade_chipped")
        }
        XCTAssertGreaterThan(pierce, rend, "piercing a plated thing did no better than tearing it")
    }

    /// Gear written before weapons had a type still loads.
    func testGearWithNoDamageTypeStillLoads() throws {
        let json = """
        {"slot": "weapon", "tier": 2}
        """
        let gear = try SaveCodec.makeDecoder().decode(GearDef.self, from: Data(json.utf8))
        XCTAssertNil(gear.damage)
        XCTAssertEqual(gear.reach, .close)
        XCTAssertEqual(gear.tier, 2)
    }


    // MARK: Skills — every one answers a specific kind of creature

    /// Turn order comes off initiative, so which of you acts first varies with the seed. Tests that
    /// are about a *skill* shouldn't also be about who got to move.
    private func giveTheTurnTo(_ actor: Combatant, in store: GameStore) {
        store.mutate("test: whose turn") { state in
            guard var run = state.worlds.activeRun, var encounter = run.activeEncounter else { return }
            encounter.turnIndex = encounter.order.firstIndex(of: actor) ?? 0
            run.activeEncounter = encounter
            state.worlds.activeRun = run
        }
    }

    /// A skill that's good against everything is just a bigger attack
    /// (`resources-skills-spec.md` §2). This is the test that keeps the set honest: **Pry does more
    /// to a plated thing than Unbind does, and less to a bare one**, which is the definition of
    /// answering something in particular.
    func testPryBeatsAnHonestSwingOnlyAgainstArmour() throws {
        /// Summed over several fresh fights, and **only over fights that were still running**.
        ///
        /// Damage carries variance, a creature can evade, and Quill may well have finished the
        /// thing before the Binder ever gets a turn — none of which this test is about. Sampling
        /// once measured the dice; counting a fight that was already over measured nothing at all.
        func damageDone(_ skill: SkillID, to traits: CreatureTraits) throws -> Int {
            var total = 0, sampled = 0
            for _ in 0..<20 where sampled < 12 {
                let store = inFightWith([traits])
                guard let encounter = store.activeEncounter, encounter.outcome == nil,
                      let foe = encounter.foes.first, foe.isAlive
                else { continue }
                sampled += 1
                let before = foe.currentHP
                giveTheTurnTo(.binder, in: store)
                store.mutate("test: use it") { CombatRules.perform(.skill(skill, foe: foe.id), by: .binder, in: &$0) }
                let after = store.activeEncounter?.foes.first { $0.id == foe.id }?.currentHP ?? 0
                total += before - after
            }
            XCTAssertGreaterThan(sampled, 6, "too few usable fights to say anything")
            return total
        }

        // Both big and thick-boned, so neither dies inside a sample and the comparison is about
        // armour rather than about who got the first swing.
        var plated = CreatureTraits()
        plated.size = 95; plated.build = 90; plated.boneDensity = 95
        plated.covering = Covering(hardness: 95, length: 5, coverage: 95)

        var bare = CreatureTraits()
        bare.size = 95; bare.build = 90; bare.boneDensity = 95
        bare.covering = Covering(hardness: 0, length: 0, coverage: 5)

        let pryPlated = try damageDone("pry", to: plated)
        let swingPlated = try damageDone("unbind", to: plated)
        let pryBare = try damageDone("pry", to: bare)
        let swingBare = try damageDone("unbind", to: bare)

        XCTAssertGreaterThan(pryPlated, swingPlated,
                             "Pry is supposed to be the answer to armour and isn't")
        XCTAssertLessThan(pryBare, swingBare,
                          "Pry is beating an honest swing on a bare creature, so it answers nothing")
    }

    /// **Flense scales with how much there is to open.** Nothing on plate, a great deal on fur —
    /// the mirror of the creature system's own rend, and what stops it being a universal DOT.
    func testFlenseOpensFurAndFindsNothingOnPlate() throws {
        // Flense's severity is read straight off the covering, with no roll in it — so one
        // sample is the whole answer here.
        func bleedPerRound(_ traits: CreatureTraits) throws -> Int {
            let store = inFightWith([traits])
            let foeID = try XCTUnwrap(store.activeEncounter?.foes.first).id
            giveTheTurnTo(.companion, in: store)
            store.mutate("test: use it") { CombatRules.perform(.skill("flense", foe: foeID), by: .companion, in: &$0) }
            return store.activeEncounter?.foeBleeds[foeID]?.damage ?? 0
        }

        var shaggy = CreatureTraits()
        shaggy.size = 60
        shaggy.covering = Covering(hardness: 5, length: 95, coverage: 95)

        var plated = CreatureTraits()
        plated.size = 60
        plated.covering = Covering(hardness: 95, length: 2, coverage: 95)

        XCTAssertGreaterThan(try bleedPerRound(shaggy), try bleedPerRound(plated) * 2,
                             "Flense doesn't care what it's cutting, so it answers nothing")
    }

    /// **Ward turns aside the kind you set it against, and nothing else.** Which is what makes
    /// Sight worth a round first — guessing wrong costs you the round you spent.
    func testWardOnlyHelpsAgainstWhatYouSetItFor() {
        var crusher = CreatureTraits()
        crusher.size = 80; crusher.build = 90
        crusher.armament.mix = WeaponMix(pierce: 0, crush: 1, rend: 0)
        crusher.armament.setTotal(80)

        // Also summed: a single blow's roll can swamp a 60% reduction.
        func binderHPAfterBeingHit(warding against: DamageKind?) -> Int {
            var total = 0
            for _ in 0..<8 { total += onceHit(warding: against) }
            return total
        }

        func onceHit(warding against: DamageKind?) -> Int {
            let store = inFightWith([crusher])
            store.mutate("test: stand and take it") { state in
                guard var run = state.worlds.activeRun, var encounter = run.activeEncounter else { return }
                if let against { encounter.wards[.binder] = WardState(against: against, rounds: 3) }
                // Force the foe to act next, at the Binder.
                let foe = encounter.foes[0].id
                encounter.taunts[foe] = 3
                encounter.turnIndex = encounter.order.firstIndex(of: .foe(foe)) ?? 0
                run.activeEncounter = encounter
                state.worlds.activeRun = run
            }
            store.mutate("test: let it swing") { CombatRules.runAutomaticTurns(in: &$0) }
            return store.state.worlds.activeRun?.binderHP ?? 0
        }

        let warded = binderHPAfterBeingHit(warding: .crush)
        let wrong = binderHPAfterBeingHit(warding: .pierce)
        XCTAssertGreaterThan(warded, wrong, "a Ward set correctly didn't turn anything aside")
    }

    /// **Draw Off is the only way to take a hit meant for somebody else.**
    func testDrawOffMakesItComeForYou() throws {
        let store = inFightWith([armoured()])
        let foeID = try XCTUnwrap(store.activeEncounter?.foes.first).id
        giveTheTurnTo(.binder, in: store)
        store.mutate("test: use it") { CombatRules.perform(.skill("draw_off", foe: foeID), by: .binder, in: &$0) }
        XCTAssertGreaterThan(store.activeEncounter?.taunts[foeID] ?? 0, 0)
    }

    /// **Read is a bestiary entry without a kill** — the non-violent option, which matters in a game
    /// whose progression is literacy rather than slaughter.
    func testReadLearnsACreatureWithoutKillingIt() throws {
        let store = inFightWith([armoured()])
        let foe = try XCTUnwrap(store.activeEncounter?.foes.first)
        // Meeting something already counts it as seen; what Read adds is **the specimen** — this
        // particular animal, kept so the entry can say how this one compared.
        let specimensBefore = store.state.reality.discovery.specimens.count

        giveTheTurnTo(.companion, in: store)
        store.mutate("test: use it") { CombatRules.perform(.skill("read", foe: foe.id), by: .companion, in: &$0) }

        XCTAssertGreaterThan(store.state.reality.discovery.specimens.count, specimensBefore,
                             "Read didn't write a bestiary specimen")
        XCTAssertNotNil(store.state.reality.discovery.species[foe.identityKey],
                        "Read didn't write a bestiary entry")
        XCTAssertTrue(store.activeEncounter?.foes.first?.isAlive ?? false,
                      "Read killed it, which is the one thing it must not do")
    }

    /// Every skill has its own timer. Twelve sharing one would mean using the best and never
    /// meeting the other eleven.
    func testSkillsCoolSeparately() throws {
        let store = inFightWith([armoured()])
        let foeID = try XCTUnwrap(store.activeEncounter?.foes.first).id
        giveTheTurnTo(.binder, in: store)
        store.mutate("test: use it") { CombatRules.perform(.skill("pry", foe: foeID), by: .binder, in: &$0) }

        let encounter = try XCTUnwrap(store.activeEncounter)
        let pry = try XCTUnwrap(ContentCatalog.shared.skill("pry"))
        let sight = try XCTUnwrap(ContentCatalog.shared.skill("sight"))
        XCTAssertGreaterThan(CombatRules.cooldown(of: pry, for: .binder, in: encounter), 0)
        XCTAssertEqual(CombatRules.cooldown(of: sight, for: .binder, in: encounter), 0,
                       "using one skill put another on cooldown")
    }

    /// The set has to be big enough to be a set, and every one of them has to say what it's for.
    func testEverySkillNamesTheProblemItSolves() {
        XCTAssertGreaterThanOrEqual(ContentCatalog.shared.skills.count, 12,
                                    "the player side of combat is still a couple of buttons")
        for skill in ContentCatalog.shared.skills {
            XCTAssertFalse(skill.answers.isEmpty,
                           "\(skill.name) doesn't say what kind of creature it answers")
        }
        // Both of them get a real list, not one a piece.
        for owner in [SkillDef.Owner.binder, .companion] {
            XCTAssertGreaterThanOrEqual(ContentCatalog.shared.skills(ownedBy: owner).count, 5)
        }
    }
}
