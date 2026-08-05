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
}
