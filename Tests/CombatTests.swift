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
    static let attackAfterRecovery = GambitRule(id: InstanceID(rawValue: 104),
                                                subject: "subject_self_recovery_complete",
                                                action: "act_attack")
    static let healBackRank = GambitRule(id: InstanceID(rawValue: 105),
                                         subject: "subject_ally_back_rank",
                                         action: "act_heal")
    static let attackOutOfReach = GambitRule(id: InstanceID(rawValue: 106),
                                             subject: "subject_foe_cannot_reach_self",
                                             action: "act_attack")
    static let attackWhenCrowded = GambitRule(id: InstanceID(rawValue: 107),
                                              subject: "subject_foes_present_at_least_3",
                                              action: "act_attack")
    static let attackUnrecorded = GambitRule(id: InstanceID(rawValue: 108),
                                             subject: "subject_foe_unrecorded_species",
                                             action: "act_attack")
    static let healWhenAnyoneLow = GambitRule(id: InstanceID(rawValue: 109),
                                              subject: "subject_ally_hp_below_any",
                                              property: "prop_hp", comparator: "cmp_below",
                                              threshold: "thr_50", action: "act_heal")
    static let attackEmanating = GambitRule(id: InstanceID(rawValue: 110),
                                            subject: "subject_foe_emanating",
                                            action: "act_attack")


    /// **Skills come from the trees now**, so a test about *what a skill does* has to buy it first.
    /// Everything, at full depth: these tests are about behaviour, not about unlocking.
    private static func learnEverything(_ state: inout GameState) {
        var depths: [CombatBranchID: Int] = [:]
        for branch in ContentCatalog.shared.combatBranches { depths[branch.id] = branch.nodes.count }
        // **Depths only, not levels.** Foes scale to the party's level (session 17 §3), so raising
        // it here would quietly turn every stat test into a test about levelling.
        state.base.binderCharacter.branchDepth = depths
        for index in state.base.roster.indices {
            state.base.roster[index].character.branchDepth = depths
        }
    }

    private func inFight(_ creatures: [CreatureID] = ["paper_moth"],
                         gambits: [GambitRule]? = nil) -> GameStore {
        let store = GameStore(io: .temporary(name: "combat-\(UUID().uuidString)"))
        store.mutate("test: everything learned") { Self.learnEverything(&$0) }
        store.write("plains")
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
            // Most combat fixtures test the underlying creature/skill rule, not the Recommended
            // comparison layer. Keep those baselines byte-stable; dedicated scaling fixtures opt in.
            run.tuning.encounterScalingProfile = .current
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

    func testRecommendedEncounterScalingAnchorsFoeLevelToBinder() throws {
        let store = GameStore(io: .temporary(name: "scaling-party-\(UUID().uuidString)"))
        store.write("plains")
        store.bindAndDepart()
        store.mutate("stage uneven active party") { state in
            state.base.binderCharacter.level = 2
            while state.base.roster.count < 3 { state.base.roster.append(CompanionState()) }
            state.base.roster[0].character.level = 4
            state.base.roster[1].character.level = 6
            state.base.roster[2].character.level = 20
            state.base.activeParty = [0, 1, 2]
            guard var run = state.worlds.activeRun else { return }
            let enemy = WorldEnemy(id: InstanceID(rawValue: 991), creatureID: "paper_moth",
                                   position: run.playerPosition, isAwake: true)
            run.enemies = [enemy]
            state.worlds.activeRun = run
            WorldRules.beginEncounter(triggeredBy: enemy, in: &state)
        }
        let run = try XCTUnwrap(store.activeRun)
        let expected = CharacterRules.foeLevel(partyLevel: 2, stability: run.stability,
                                                greed: Double(BookRules.greedDelta(for: BookRules.sigils(for: run.book))))
        XCTAssertEqual(try XCTUnwrap(store.activeEncounter?.foes.first).level, expected)
        XCTAssertEqual(EncounterScalingRules.partyLevels(in: store.state), [2, 4, 6, 20])
        XCTAssertEqual(store.activeEncounter?.scalingPreview?.anchorLevel, 2)
        XCTAssertEqual(store.activeEncounter?.scalingPreview?.totalOrdinaryLevelAdjustment, 0)
    }

    func testEncounterScalingCandidateMatrixIsDeterministicMonotonicAndVisible() {
        let one = [WorldEnemy(id: InstanceID(rawValue: 44), creatureID: "paper_moth",
                              position: GridPoint(x: 1, y: 1), isAwake: true)]
        let three = (44...46).map { WorldEnemy(id: InstanceID(rawValue: UInt64($0)), creatureID: "paper_moth",
                                               position: GridPoint(x: $0 - 43, y: 1), isAwake: true) }
        for profile in [EncounterScalingRules.Profile.reserved, .recommended, .pressing] {
            for band in [1, 8, 16] {
                var previousBudget = 0.0
                var previousHP = 0.0
                for count in [1, 2, 3, 5] {
                    let levels = Array(repeating: band, count: count)
                    let preview = EncounterScalingRules.preview(profile: profile, partyLevels: levels,
                        visibleFoes: one, mapSeed: 7_777, triggerID: one[0].id, worldLevel: band)
                    XCTAssertGreaterThanOrEqual(preview.ordinaryBudget, previousBudget)
                    XCTAssertGreaterThanOrEqual(preview.apexHPMultiplier, previousHP)
                    XCTAssertLessThanOrEqual(preview.visibleFoeCount, Tuning.Encounter.maxFoes)
                    XCTAssertEqual(preview.foeIDs, [one[0].id], "Scaling invented an off-map combatant")
                    XCTAssertEqual(preview, EncounterScalingRules.preview(profile: profile, partyLevels: levels,
                        visibleFoes: one, mapSeed: 7_777, triggerID: one[0].id, worldLevel: band))
                    previousBudget = preview.ordinaryBudget
                    previousHP = preview.apexHPMultiplier
                }
            }
            let capped = EncounterScalingRules.preview(profile: profile,
                partyLevels: [8, 8, 8, 8, 8], visibleFoes: three,
                mapSeed: 7_777, triggerID: three[0].id, worldLevel: 8)
            XCTAssertEqual(capped.foeIDs.count, 3)
            XCTAssertEqual(capped.missingFoeConversion, 0)
        }
        XCTAssertEqual(EncounterScalingRules.upperMedian([2, 4, 6, 8, 20]), 6)
    }

    func testSelectedEncounterProfileFreezesWithoutInventingFoesAndSurvivesSave() throws {
        let store = GameStore(io: .temporary(name: "scaling-freeze-\(UUID().uuidString)"))
        store.write("plains")
        store.bindAndDepart()
        store.mutate("stage recommended comparison") { state in
            while state.base.roster.count < 4 { state.base.roster.append(CompanionState()) }
            state.base.binderCharacter.level = 8
            for index in 0..<4 { state.base.roster[index].character.level = 8 }
            state.base.activeParty = [0, 1, 2, 3]
            guard var run = state.worlds.activeRun else { return }
            run.tuning.encounterScalingProfile = .recommended
            let enemy = WorldEnemy(id: InstanceID(rawValue: 771), creatureID: "ink_hound",
                                   position: run.playerPosition, isAwake: true)
            run.enemies = [enemy]
            state.worlds.activeRun = run
            WorldRules.beginEncounter(triggeredBy: enemy, in: &state)
        }
        let encounter = try XCTUnwrap(store.activeEncounter)
        let preview = try XCTUnwrap(encounter.scalingPreview)
        XCTAssertEqual(encounter.foes.map(\.id), [InstanceID(rawValue: 771)])
        XCTAssertEqual(preview.partyLevels, [8, 8, 8, 8, 8])
        XCTAssertEqual(preview.wholePressureSlots, 2)
        XCTAssertEqual(preview.missingFoeConversion, 0)
        XCTAssertEqual(preview.apexActionSlots, 3)

        let data = try JSONEncoder().encode(store.state)
        let resumed = try JSONDecoder().decode(GameState.self, from: data)
        XCTAssertEqual(resumed.worlds.activeRun?.activeEncounter?.scalingPreview, preview)
        XCTAssertEqual(resumed.worlds.activeRun?.activeEncounter?.foes.map(\.id), encounter.foes.map(\.id))
        XCTAssertEqual(resumed.worlds.activeRun?.activeEncounter?.turnSlots, encounter.turnSlots)
    }

    func testApexTurnSchedulePersistsLighterAfflictionFreeFollowUps() throws {
        var rng = SeededRNG(seed: 4_242)
        let apexID = InstanceID(rawValue: 90)
        let ordinaryID = InstanceID(rawValue: 91)
        var apexStats = CombatStats(displayName: "Apex", icon: "crown", maxHP: 100, attack: 12)
        apexStats.delivery = .area
        apexStats.element = .heat
        apexStats.initiative = 100
        let foes = [
            FoeState(id: apexID, stats: apexStats, currentHP: apexStats.maxHP, isApex: true),
            FoeState(id: ordinaryID,
                     stats: CombatStats(displayName: "Ordinary", icon: "pawprint", maxHP: 10, attack: 3),
                     currentHP: 10)
        ]
        let encounter = CombatRules.makeEncounter(
            id: InstanceID(rawValue: 1), foes: foes,
            party: [.binder, .companion(0), .companion(1), .companion(2), .companion(3)],
            apexActionSlots: [apexID: 3], rng: &rng)

        let apexSlots = encounter.turnSlots.filter { $0.actor == .foe(apexID) }
        XCTAssertEqual(apexSlots.count, 3)
        XCTAssertEqual(apexSlots[0], .init(actor: .foe(apexID)))
        for (ordinal, slot) in apexSlots.dropFirst().enumerated() {
            XCTAssertEqual(slot.kind, .apexFollowUp(ordinal + 2))
            XCTAssertEqual(slot.strengthMultiplier, 0.60, accuracy: 0.0001)
            XCTAssertTrue(slot.suppressesAfflictions)
        }
        XCTAssertTrue(encounter.log.contains("Relentless — 3 actions; follow-ups lighter."))
        let indices = encounter.turnSlots.indices.filter { encounter.turnSlots[$0].actor == .foe(apexID) }
        XCTAssertTrue(zip(indices, indices.dropFirst()).allSatisfy { $1 - $0 > 1 },
                      "Apex follow-ups should be distributed through the round when other actors exist")

        let resumed = try JSONDecoder().decode(EncounterState.self,
                                                from: JSONEncoder().encode(encounter))
        XCTAssertEqual(resumed.turnSlots, encounter.turnSlots)
    }

    func testMixedApexAndOrdinaryScalingKeepsAdjustmentsOnTheirOwnFoes() throws {
        let store = GameStore(io: .temporary(name: "scaling-mixed-\(UUID().uuidString)"))
        store.write("plains")
        store.bindAndDepart()
        store.mutate("stage mixed encounter") { state in
            while state.base.roster.count < 4 { state.base.roster.append(CompanionState()) }
            state.base.binderCharacter.level = 8
            for index in 0..<4 { state.base.roster[index].character.level = 8 }
            state.base.activeParty = [0, 1, 2, 3]
            guard var run = state.worlds.activeRun else { return }
            run.tuning.encounterScalingProfile = .recommended
            var apexTraits = CreatureTraits()
            apexTraits.armament.pierce = 65
            apexTraits.armament.crush = 45
            apexTraits.armament.rend = 55
            var ordinaryTraits = CreatureTraits()
            ordinaryTraits.armament.pierce = 20
            ordinaryTraits.armament.crush = 20
            ordinaryTraits.armament.rend = 20
            let apex = WorldEnemy(id: InstanceID(rawValue: 801), traits: apexTraits,
                                  position: run.playerPosition, isAwake: true, isApex: true)
            let ordinary = WorldEnemy(id: InstanceID(rawValue: 802), traits: ordinaryTraits,
                                      position: run.playerPosition, isAwake: true)
            run.enemies = [apex, ordinary]
            state.worlds.activeRun = run
            WorldRules.beginEncounter(triggeredBy: apex, in: &state)
        }

        let encounter = try XCTUnwrap(store.activeEncounter)
        let preview = try XCTUnwrap(encounter.scalingPreview)
        let apex = try XCTUnwrap(encounter.foes.first(where: \.isApex))
        let ordinary = try XCTUnwrap(encounter.foes.first(where: { !$0.isApex }))
        let run = try XCTUnwrap(store.activeRun)
        let expectedOrdinaryLevel = CharacterRules.foeLevel(
            partyLevel: store.state.base.binderCharacter.level,
            stability: run.stability,
            greed: Double(BookRules.greedDelta(for: BookRules.sigils(for: run.book))))
        var expectedOrdinaryStats = CombatStats.derived(
            from: try XCTUnwrap(ordinary.traits), name: ordinary.stats.displayName,
            icon: ordinary.stats.icon)
        expectedOrdinaryStats.maxHP = CharacterRules.scaled(expectedOrdinaryStats.maxHP,
                                                             toLevel: expectedOrdinaryLevel)
        XCTAssertEqual(apex.level, preview.apexLevelFloor)
        XCTAssertEqual(ordinary.level, expectedOrdinaryLevel)
        XCTAssertEqual(ordinary.stats.maxHP, expectedOrdinaryStats.maxHP,
                       "Mixed ordinary bodies receive neither apex nor ordinary pressure durability")
        XCTAssertEqual(preview.wholePressureSlots, 0)
        XCTAssertEqual(preview.totalHPAdditionFraction, 0)
        XCTAssertEqual(preview.hpAllocationByFoeID, [:])
        XCTAssertEqual(encounter.turnSlots.filter { $0.actor == .foe(apex.id) }.count,
                       preview.apexActionSlots)
        XCTAssertEqual(encounter.turnSlots.filter { $0.actor == .foe(ordinary.id) }.count, 1)
        XCTAssertEqual(Set(preview.finalFoes.map(\.id)), Set(encounter.foes.map(\.id)))
    }

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
        XCTAssertEqual(encounter.order.dropFirst().first, .companion(0))
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

        // Vanish (Shadow 6) makes leaving free, and the fixture hands out every branch — so for
        // *this* test, unlearn it. That the capstone branch removes the cost is its own test.
        store.mutate("test: no shadow") { state in
            state.base.binderCharacter.branchDepth["shadow"] = 0
            for index in state.base.roster.indices { state.base.roster[index].character.branchDepth["shadow"] = 0 }
        }
        store.takeCombatAction(.flee)
        XCTAssertEqual(store.activeEncounter?.outcome, .fled)
        store.endEncounterIfFinished()

        let run = try XCTUnwrap(store.state.worlds.activeRun)
        XCTAssertEqual(run.stability, stabilityBefore - Tuning.Encounter.fleeStabilityCost, accuracy: 0.001)
        XCTAssertEqual(run.playerPosition, retreat, "Fleeing retreats the way you came")
        XCTAssertGreaterThan(run.encounterGraceTurns, 0, "…and buys a moment before the next bump")
        XCTAssertFalse(run.enemies.isEmpty, "Fleeing doesn't kill anything")
    }

    func testVanishMakesExactlyOneWithdrawPerExpeditionFree() throws {
        let store = inFight()
        let before = try XCTUnwrap(store.activeRun).stability
        XCTAssertEqual(CombatRules.withdrawalStabilityCost(for: .binder, in: store.state), 0)

        store.mutate("test: first Vanish withdraw") {
            CombatRules.perform(.flee, by: .binder, in: &$0)
        }
        XCTAssertEqual(try XCTUnwrap(store.activeRun).stability, before, accuracy: 0.001)
        XCTAssertEqual(store.activeRun?.vanishWithdrawSpent, true)
        XCTAssertEqual(CombatRules.withdrawalStabilityCost(for: .binder, in: store.state),
                       Tuning.Encounter.fleeStabilityCost)

        store.mutate("test: another encounter in same expedition") { state in
            state.worlds.activeRun?.activeEncounter?.outcome = nil
            CombatRules.perform(.flee, by: .binder, in: &state)
        }
        XCTAssertEqual(try XCTUnwrap(store.activeRun).stability,
                       before - Tuning.Encounter.fleeStabilityCost, accuracy: 0.001)
    }

    func testVanishWithdrawReceiptRoundTripsAndLegacyRunDefaultsUnused() throws {
        let store = inFight()
        store.mutate("test: spend Vanish") { CombatRules.perform(.flee, by: .binder, in: &$0) }
        let spent = try XCTUnwrap(store.activeRun)
        XCTAssertTrue(try JSONDecoder().decode(WorldRun.self,
                                               from: JSONEncoder().encode(spent)).vanishWithdrawSpent)

        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(spent))
            as? [String: Any])
        object.removeValue(forKey: "vanishWithdrawSpent")
        let legacy = try JSONSerialization.data(withJSONObject: object)
        XCTAssertFalse(try JSONDecoder().decode(WorldRun.self, from: legacy).vanishWithdrawSpent)
    }

    func testLegacyRoutDecodeIsInertAndDoesNotSpendTurn() throws {
        let store = inFight()
        giveTheTurnTo(.binder, in: store)
        let before = try XCTUnwrap(store.activeEncounter)

        store.mutate("test: decoded legacy Rout") {
            CombatRules.perform(.skill("rout"), by: .binder, in: &$0)
        }

        let after = try XCTUnwrap(store.activeEncounter)
        XCTAssertEqual(after.turnIndex, before.turnIndex)
        XCTAssertEqual(after.roundNumber, before.roundNumber)
        XCTAssertEqual(after.outcome, before.outcome)
        XCTAssertEqual(after.cooldowns, before.cooldowns)
    }

    func testSkillGoesOnCooldownAndComesBack() throws {
        let store = inFight(["ink_hound"])
        XCTAssertTrue(store.isSkillReady)
        let skill = try XCTUnwrap(store.readySkills.first { $0.kind == .damage })
        let sight = try XCTUnwrap(CombatRules.skills(for: .binder, in: store.state)
            .first { $0.id == "sight" })
        let foe = try XCTUnwrap(foes(store).first)
        giveTheTurnTo(.binder, in: store)

        store.mutate("test: exact skill cooldown") {
            CombatRules.perform(.damageSkill(foe: foe.id), by: .binder, in: &$0)
        }
        let encounter = try XCTUnwrap(store.activeEncounter)
        XCTAssertGreaterThan(encounter.binderSkillCooldown, 0)
        XCTAssertGreaterThan(CombatRules.cooldown(of: skill, for: .binder, in: encounter), 0,
                             "the exact skill just used is ready again")
        XCTAssertFalse(CombatRules.isReady(skill, for: .binder, in: encounter))
        XCTAssertTrue(CombatRules.isReady(sight, for: .binder, in: encounter),
                      "cooling Unbind incorrectly hid the Binder's independently ready Sight")
        XCTAssertLessThanOrEqual(encounter.binderSkillCooldown, skill.cooldownRounds)
    }

    // MARK: The pillar

    /// Being mid-fight is the hardest resume case in the game. It has to be exact.
    func testAFightSurvivesAForceQuitMidRound() throws {
        let io = SaveFileIO.temporary(name: "fight-kill-\(UUID().uuidString)")
        defer { io.deleteEverything() }

        let first = GameStore(io: io)
        first.write("caverns")
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

        XCTAssertEqual(store.activeGambitSlots(for: .companion(0)), Tuning.Encounter.startingGambitSlots)
        let decision = try XCTUnwrap(GambitEngine.decide(in: store.state))
        XCTAssertNotEqual(decision.rule, Self.healHurtAlly, "A rule with no slot must not fire")
    }

    func testNoMatchingRuleMeansTheCompanionWaits() throws {
        let store = inFight(["paper_moth"], gambits: [Self.healHurtAlly])
        // Everyone is healthy, so the only rule can't match.
        XCTAssertNil(GambitEngine.decide(in: store.state))
    }

    func testBackRankSubjectTargetsOnlyAnAllyInTheBackRank() throws {
        let store = inFight(["paper_moth"], gambits: [Self.healBackRank])
        store.mutate("put only the binder in back") { state in
            state.worlds.activeRun?.activeEncounter?.partyRanks[.binder] = .back
            state.worlds.activeRun?.activeEncounter?.partyRanks[.companion(0)] = .front
        }

        XCTAssertEqual(GambitEngine.decide(in: store.state)?.action, .healSkill(ally: .binder))

        store.mutate("move the binder forward") {
            $0.worlds.activeRun?.activeEncounter?.partyRanks[.binder] = .front
        }
        XCTAssertNil(GambitEngine.decide(in: store.state))
    }

    func testCannotReachSubjectReadsTheCurrentRanksAndFoeAction() throws {
        let store = inFight(["paper_moth"], gambits: [Self.attackOutOfReach])
        store.mutate("hold behind a front line") { state in
            state.worlds.activeRun?.activeEncounter?.partyRanks[.binder] = .front
            state.worlds.activeRun?.activeEncounter?.partyRanks[.companion(0)] = .back
        }
        XCTAssertEqual(GambitEngine.decide(in: store.state)?.rule, Self.attackOutOfReach)

        store.mutate("leave nobody in front") {
            $0.worlds.activeRun?.activeEncounter?.partyRanks[.binder] = .back
        }
        XCTAssertNil(GambitEngine.decide(in: store.state),
                     "a foe can close when the whole standing party is in back")
    }

    func testThreeFoesSubjectStopsWhenTheCrowdThins() {
        let store = inFight(["paper_moth", "paper_moth", "paper_moth"],
                            gambits: [Self.attackWhenCrowded])
        XCTAssertEqual(GambitEngine.decide(in: store.state)?.rule, Self.attackWhenCrowded)

        store.mutate("one foe falls") { $0.worlds.activeRun?.activeEncounter?.foes[0].currentHP = 0 }
        XCTAssertNil(GambitEngine.decide(in: store.state))
    }

    func testUnrecordedSpeciesSubjectUsesTheEncounterOpeningSnapshot() {
        let store = inFight(["paper_moth"], gambits: [Self.attackUnrecorded])
        XCTAssertEqual(GambitEngine.decide(in: store.state)?.rule, Self.attackUnrecorded,
                       "encounter setup records the sighting before gambits evaluate")

        store.mutate("stage a species already known before this fight") {
            $0.worlds.activeRun?.activeEncounter?.initiallyUnrecordedSpecies = []
        }
        XCTAssertNil(GambitEngine.decide(in: store.state))
    }

    func testAnyLowAllySubjectQualifiesWithoutRetargetingTheAction() {
        let store = inFight(["paper_moth"], gambits: [Self.healWhenAnyoneLow])
        store.mutate("hurt someone other than the actor") { $0.worlds.activeRun?.binderHP = 1 }

        XCTAssertEqual(GambitEngine.decide(in: store.state)?.action,
                       .healSkill(ally: .companion(0)),
                       "the global subject must not secretly select the qualifying ally")

        store.mutate("everyone is healthy") { state in
            state.worlds.activeRun?.binderHP = Tuning.Encounter.binderMaxHP
        }
        XCTAssertNil(GambitEngine.decide(in: store.state))
    }

    func testRecoveryCompleteMatchesOnlyFirstActionAfterFinalSkippedTurn() throws {
        let store = inFight(["ink_hound"], gambits: [Self.attackAfterRecovery, Self.attackAny])
        store.mutate("owe two recovery turns") { state in
            state.worlds.activeRun?.activeEncounter?.skippedTurns[.companion(0)] = 2
            CombatRules.advanceTurn(in: &state)
        }
        XCTAssertFalse(try XCTUnwrap(store.activeEncounter).recoveryComplete.contains(.companion(0)),
                       "earlier debt in a stack must not mark recovery complete")

        store.mutate("reach the final recovery turn") { state in
            guard var encounter = state.worlds.activeRun?.activeEncounter,
                  let beforeCompanion = encounter.order.firstIndex(of: .binder) else { return }
            encounter.turnIndex = beforeCompanion
            state.worlds.activeRun?.activeEncounter = encounter
            CombatRules.advanceTurn(in: &state)
        }
        store.mutate("make the recovered companion actionable") { state in
            guard var encounter = state.worlds.activeRun?.activeEncounter,
                  let index = encounter.order.firstIndex(of: .companion(0)) else { return }
            encounter.turnIndex = index
            state.worlds.activeRun?.activeEncounter = encounter
        }
        XCTAssertEqual(GambitEngine.decide(in: store.state)?.rule, Self.attackAfterRecovery)
        let action = try XCTUnwrap(GambitEngine.decide(in: store.state)?.action)
        store.mutate("complete recovered action") { CombatRules.perform(action, by: .companion(0), in: &$0) }
        XCTAssertFalse(try XCTUnwrap(store.activeEncounter).recoveryComplete.contains(.companion(0)))
    }

    // MARK: Manual override

    func testOverrideHandsOneTurnToThePlayerThenClears() throws {
        let store = inFight(["ink_hound"], gambits: [Self.attackAny])

        store.toggleCompanionOverride()
        XCTAssertTrue(try XCTUnwrap(store.activeEncounter).isCompanionOverridden)

        // Take the Binder's turn; the game should now stop and wait on the companion.
        store.takeCombatAction(.attack(foe: try XCTUnwrap(foes(store).first).id))
        XCTAssertEqual(store.actingCombatant, .companion(0), "The override stops the gambits taking over")

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
        store.mutate("test: everything learned") { Self.learnEverything(&$0) }
        store.write("plains")
        store.bindAndDepart()
        store.mutate("stage a fight") { state in
            guard var run = state.worlds.activeRun else { return }
            // **Pinned, so a fight in a test is the same fight every time.** A new game draws its
            // seed sequence from real entropy, so every combat roll — evasion above all — came out
            // differently on each run, and any test asserting a consequence of *hitting* failed a
            // fifth of the time. Flaky tests are worse than missing ones: they train you to re-run.
            run.rng = SeededRNG(seed: 0xC0FFEE)
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
        // Summed over several fights: a swing can simply miss, and a miss is not a trade.
        var paid = 0
        for _ in 0..<10 {
            let store = inFightWith([toxic])
            guard let foe = foes(store).first, foe.isAlive else { continue }
            giveTheTurnTo(.binder, in: store)
            let hpBefore = store.state.worlds.activeRun?.binderHP ?? 0
            store.mutate("test: swing at it") {
                CombatRules.perform(.attack(foe: foe.id), by: .binder, in: &$0)
            }
            paid += hpBefore - (store.state.worlds.activeRun?.binderHP ?? 0)
        }
        XCTAssertGreaterThan(paid, 0,
                             "you traded blows with something toxic ten times and paid nothing")
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
        store.write("plains")
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
            giveTheTurnTo(.companion(0), in: store)
            store.mutate("test: use it") { CombatRules.perform(.skill("flense", foe: foeID), by: .companion(0), in: &$0) }
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
                if let against { encounter.wards[.binder] = WardState(against: .blow(against), rounds: 3) }
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

        giveTheTurnTo(.companion(0), in: store)
        store.mutate("test: use it") { CombatRules.perform(.skill("read", foe: foe.id), by: .companion(0), in: &$0) }

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

    // MARK: Statuses — the producers finally reach the fight

    func testStonebarkBlocksExactlyOneAfflictionButNotTheHit() throws {
        var burning = CreatureTraits()
        burning.size = 80; burning.build = 70
        burning.emanation = emanation(of: .heat)
        burning.armament.setTotal(60)
        let store = inFightWith([burning])
        let tonic = ItemStack(id: InstanceID(rawValue: 70_001), catalogID: "stonebark_tonic")
        store.mutate("test: carry tonic") { state in
            _ = state.worlds.activeRun?.satchelItems.add(tonic)
            guard let foe = state.worlds.activeRun?.activeEncounter?.foes.first else { return }
            state.worlds.activeRun?.activeEncounter?.order = [.binder, .foe(foe.id)]
            state.worlds.activeRun?.activeEncounter?.turnIndex = 0
        }

        let hpBefore = try XCTUnwrap(store.activeRun).binderHP
        store.mutate("test: drink tonic") {
            CombatRules.perform(.useItem(stack: tonic.id, ally: .binder), by: .binder, in: &$0)
        }
        XCTAssertEqual(store.activeEncounter?.statusGuards[.binder], 1)

        // Stage only the foe's immediate action so automatic companion turns cannot obscure which
        // body was protected. Repeat for evasion; the guard is spent only when an affliction lands.
        store.mutate("test: foe only") { state in
            guard let foe = state.worlds.activeRun?.activeEncounter?.foes.first else { return }
            state.worlds.activeRun?.activeEncounter?.order = [.binder, .foe(foe.id)]
            state.worlds.activeRun?.activeEncounter?.turnIndex = 1
        }
        for _ in 0..<12 where (store.activeEncounter?.statusGuards[.binder] ?? 0) > 0 {
            forceTheFoeToStrike(in: store)
        }

        XCTAssertLessThan(store.activeRun?.binderHP ?? hpBefore, hpBefore, "Stonebark stopped attack damage")
        XCTAssertNil(store.activeEncounter?.statusGuards[.binder])
        XCTAssertTrue((store.activeEncounter?.statuses[.binder] ?? []).isEmpty)
    }

    func testEachPreparedCoatingMapsToItsExistingCombatEffectAndIsSpent() throws {
        let cases: [(ItemID, PreparedCoating)] = [
            ("venom", .poison), ("firebrand", .burn),
            ("briar_oil", .bleed), ("flashsalt", .dazzle)
        ]
        for (itemID, expected) in cases {
            let store = inFightWith([armoured()])
            let stack = ItemStack(id: InstanceID(rawValue: 71_000 + UInt64(cases.firstIndex { $0.0 == itemID } ?? 0)),
                                  catalogID: itemID)
            store.mutate("test: carry coating") { state in
                _ = state.worlds.activeRun?.satchelItems.add(stack)
            }
            giveTheTurnTo(.binder, in: store)
            store.mutate("test: prepare coating") {
                CombatRules.perform(.useItem(stack: stack.id, ally: .binder), by: .binder, in: &$0)
            }
            XCTAssertEqual(store.activeEncounter?.preparedCoatings[.binder], expected)

            let foeID = try XCTUnwrap(store.activeEncounter?.foes.first?.id)
            for _ in 0..<12 where store.activeEncounter?.preparedCoatings[.binder] != nil {
                giveTheTurnTo(.binder, in: store)
                store.mutate("test: coated strike") {
                    CombatRules.perform(.attack(foe: foeID), by: .binder, in: &$0)
                }
            }
            XCTAssertNil(store.activeEncounter?.preparedCoatings[.binder], "\(itemID) was not spent")
            if expected == .bleed {
                XCTAssertGreaterThan(store.activeEncounter?.foes.first?.bleedRounds ?? 0, 0)
            } else {
                let kind: StatusKind = expected == .poison ? .poison : (expected == .burn ? .burn : .dazzle)
                XCTAssertTrue((store.activeEncounter?.statuses[.foe(foeID)] ?? []).contains { $0.kind == kind })
            }
        }
    }

    /// **An emanating creature leaves something behind** (Q42). Emanation is a generated trait that
    /// reached the creature's description and did nothing in the fight beyond one armour-ignoring
    /// blow. Three statuses now, one per emanation, because Ward needs something specific to turn
    /// aside — a ward against "elemental" would be the good-against-everything shape the whole
    /// skill set exists to avoid.
    func testWhatACreatureGivesOffKeepsCostingYou() throws {
        for element in EmanationKind.allCases {
            var emanating = CreatureTraits()
            emanating.size = 80; emanating.build = 70
            emanating.emanation = emanation(of: element)
            emanating.armament.setTotal(60)

            let store = inFightWith([emanating])
            guard let foe = store.activeEncounter?.foes.first, foe.stats.element != nil else {
                XCTFail("\(element.rawValue) didn't survive into the fight's stats")
                continue
            }
            // **Until it connects.** The claim is that a blow which lands leaves something behind,
            // not that every swing lands — and the party evades on a roll off a stream seeded from
            // real entropy at new-game, so a single strike made this assert fail about one run in
            // five. It was flaky before flora and it is not flora's; it is a test that asserted a
            // consequence of hitting after an action that can miss.
            var carried: [StatusState] = []
            for _ in 0..<12 {
                forceTheFoeToStrike(in: store)
                carried = store.activeEncounter?.statuses.values.flatMap { $0 } ?? []
                if carried.contains(where: { $0.kind == StatusKind.from(element) }) { break }
            }
            XCTAssertTrue(carried.contains { $0.kind == StatusKind.from(element) },
                          "a \(element.rawValue) creature hit somebody and left no \(StatusKind.from(element).rawValue)")
        }
    }

    /// **Snuff puts it out**, which is what makes it an answer to a specific kind of creature
    /// rather than a bigger attack.
    func testSnuffStopsIt() throws {
        var burning = CreatureTraits()
        burning.size = 80; burning.build = 70
        burning.emanation = emanation(of: .heat)
        burning.armament.setTotal(60)

        let store = inFightWith([burning])
        let foeID = try XCTUnwrap(store.activeEncounter?.foes.first).id
        giveTheTurnTo(.companion(0), in: store)
        store.mutate("test: snuff it") { CombatRules.perform(.skill("snuff", foe: foeID), by: .companion(0), in: &$0) }
        forceTheFoeToStrike(in: store)

        let carried = store.activeEncounter?.statuses.values.flatMap { $0 } ?? []
        XCTAssertFalse(carried.contains { $0.kind == .burn },
                       "snuffed it and it still set somebody on fire")
    }

    /// **Steady clears them.** Otherwise a status is a tax rather than a problem with an answer.
    func testSteadyClearsWhatIsStillWorking() throws {
        let store = inFightWith([armoured()])
        store.mutate("test: poisoned") { state in
            state.worlds.activeRun?.activeEncounter?.statuses[.binder] =
                [StatusState(kind: .poison, damage: 2, rounds: 4)]
        }
        giveTheTurnTo(.companion(0), in: store)
        store.mutate("test: steady") { CombatRules.perform(.skill("steady", ally: .binder), by: .companion(0), in: &$0) }
        XCTAssertTrue((store.activeEncounter?.statuses[.binder] ?? []).isEmpty,
                      "Steady left the poison in")
    }

    /// A Ward can be set against an **emanation**, not only a blow — six things to choose between,
    /// which is what makes spending a round on Sight first worth doing.
    func testAWardCanBeSetAgainstWhatSomethingGivesOff() throws {
        var burning = CreatureTraits()
        burning.size = 80; burning.build = 70
        burning.emanation = emanation(of: .heat)
        burning.armament.setTotal(60)

        let store = inFightWith([burning])
        giveTheTurnTo(.companion(0), in: store)
        store.mutate("test: ward") { CombatRules.perform(.skill("ward"), by: .companion(0), in: &$0) }

        // With nothing stated, a Ward guards the likeliest harm — and an emanation wins, because
        // nothing you wear stops one.
        XCTAssertEqual(store.activeEncounter?.wards[.companion(0)]?.harm, .emanation(.heat),
                       "the Ward guarded a blow while something was busy setting fire to us")
    }

    /// A creature that gives off one particular thing, strongly enough for it to count.
    private func emanation(of kind: EmanationKind) -> Emanation {
        Emanation(strength: 80,
                  light: kind == .light ? 100 : 0,
                  heat: kind == .heat ? 100 : 0,
                  caustic: kind == .caustic ? 100 : 0)
    }

    func testGroundBelongsToAsheAndReceivesOneEmanationEvent() throws {
        var burning = CreatureTraits()
        burning.size = 80; burning.build = 70
        burning.emanation = emanation(of: .heat)
        burning.armament.setTotal(60)
        let store = inFightWith([burning])
        let foeID = try XCTUnwrap(store.activeEncounter?.foes.first?.id)
        store.mutate("test: companion is Ashe") { state in
            state.base.roster[0].traveller = "ashe"
            state.base.roster[0].name = "Ashe"
            state.worlds.activeRun?.activeEncounter?.taunts[foeID] = 1
        }
        XCTAssertTrue(CombatRules.skills(for: .companion(0), in: store.state).contains { $0.id == "ground" })

        let binderBefore = try XCTUnwrap(store.activeRun).binderHP
        let asheBefore = try XCTUnwrap(try XCTUnwrap(store.activeRun).companionHP[0])
        giveTheTurnTo(.companion(0), in: store)
        store.mutate("test: ground") {
            CombatRules.perform(.skill("ground"), by: .companion(0), in: &$0)
            CombatRules.runAutomaticTurns(in: &$0)
        }

        XCTAssertEqual(store.activeRun?.binderHP, binderBefore, "the protected target still took the event")
        XCTAssertLessThan(store.activeRun?.companionHP[0] ?? asheBefore, asheBefore,
                          "Ashe did not receive the redirected damage")
        XCTAssertNil(store.activeEncounter?.grounding[.companion(0)], "Ground caught more than one event")
        XCTAssertTrue((store.activeEncounter?.statuses[.companion(0)] ?? []).contains { $0.kind == .burn },
                      "the redirected affliction did not follow the event")
    }

    func testEmanatingSubjectStopsMatchingWhenSnuffed() throws {
        var burning = CreatureTraits()
        burning.emanation = emanation(of: .heat)
        let store = inFightWith([burning])
        store.mutate("test: teach rule") { state in
            state.base.ownedGambitComponents = Set(ContentCatalog.shared.gambitComponents.map(\.id))
            state.base.roster[0].gambits = [Self.attackEmanating]
        }
        XCTAssertNotNil(GambitEngine.decide(for: .companion(0), in: store.state))
        store.mutate("test: snuffed") { state in
            guard let foe = state.worlds.activeRun?.activeEncounter?.foes.first else { return }
            state.worlds.activeRun?.activeEncounter?.snuffed.insert(foe.id)
        }
        XCTAssertNil(GambitEngine.decide(for: .companion(0), in: store.state))
    }

    /// Hands the turn to whatever foe is present and lets it swing.
    private func forceTheFoeToStrike(in store: GameStore) {
        store.mutate("test: their move") { state in
            guard var run = state.worlds.activeRun, var encounter = run.activeEncounter,
                  let foe = encounter.foes.first
            else { return }
            encounter.turnIndex = encounter.order.firstIndex(of: .foe(foe.id)) ?? 0
            run.activeEncounter = encounter
            state.worlds.activeRun = run
            CombatRules.runAutomaticTurns(in: &state)
        }
    }

    // MARK: Deviations from the stated design, caught by audit

    /// **Nobody dies, and the Binder going down ends the run** (session 17 §6).
    ///
    /// Defeat used to require *both* of you at zero, so a Binder at zero kept walking a world on
    /// Quill's legs. The Binder is the one holding the book.
    func testTheBinderGoingDownEndsIt() throws {
        let store = inFightWith([armoured()])
        store.mutate("test: you're finished") { $0.worlds.activeRun?.binderHP = 0 }
        store.mutate("test: check") { CombatRules.checkOutcome(in: &$0) }
        XCTAssertEqual(store.activeEncounter?.outcome, .defeated,
                       "the Binder is down and the fight carried on")
    }

    func testVictoryExperienceIsAttributedToCombatWithoutBeingDivided() throws {
        let store = inFight(["paper_moth"])
        let foe = try XCTUnwrap(store.activeEncounter?.foes.first)
        let partyLevel = store.state.base.partyMembers.map { store.state.base.character($0).level }.max() ?? 1
        let expected = CharacterRules.experience(forDefeating: foe, partyLevel: partyLevel)
        let binderBefore = store.state.base.binderCharacter.experience
        let companionBefore = store.state.base.companion.character.experience

        store.mutate("test: foe falls") { state in
            state.worlds.activeRun?.activeEncounter?.foes[0].currentHP = 0
            CombatRules.checkOutcome(in: &state)
        }

        XCTAssertEqual(store.state.base.binderCharacter.experience - binderBefore, expected)
        XCTAssertEqual(store.state.base.companion.character.experience - companionBefore, expected,
                       "the full award remains equal for every active party member")
        XCTAssertEqual(store.activeRun?.experienceBreakdown.combat, expected)
    }

    /// …and a companion at zero has **passed out**, not died. They take no more turns and are on
    /// their feet at the base — health is run-scoped, so coming home is the revival.
    func testACompanionPassesOutRatherThanDying() throws {
        let store = inFightWith([armoured()])
        store.mutate("test: they go down") { $0.worlds.activeRun?.companionHP[0] = 0 }
        store.mutate("test: check") { CombatRules.checkOutcome(in: &$0) }

        let run = try XCTUnwrap(store.state.worlds.activeRun)
        XCTAssertNil(run.activeEncounter?.outcome, "a companion going down ended the fight")
        XCTAssertTrue(CombatRules.hasPassedOut(.companion(0), in: run))
        XCTAssertFalse(CombatRules.hasPassedOut(.binder, in: run))
    }

    /// **The front rank takes the melee** (session 17 §4).
    ///
    /// Targeting was uniform, so standing at the back was pure upside — less damage taken and no
    /// less chance of being chosen. That's half a rank system.
    func testTheFrontRankTakesTheHits() {
        var brute = CreatureTraits()
        brute.size = 80; brute.build = 85
        brute.armament.mix = WeaponMix(pierce: 0, crush: 1, rend: 0)
        brute.armament.setTotal(70)

        var hitTheBack = 0
        for _ in 0..<14 {
            let store = inFightWith([brute])
            store.mutate("test: Quill up front, you behind") { state in
                state.base.binderCharacter.rank = .back
                state.base.companion.character.rank = .front
                guard var run = state.worlds.activeRun, var encounter = run.activeEncounter,
                      let foe = encounter.foes.first
                else { return }
                encounter.turnIndex = encounter.order.firstIndex(of: .foe(foe.id)) ?? 0
                run.activeEncounter = encounter
                state.worlds.activeRun = run
                CombatRules.runAutomaticTurns(in: &state)
            }
            let hp = store.state.worlds.activeRun?.binderHP ?? 0
            if hp < CombatRules.maximumHealth(of: .binder, in: store.state) { hitTheBack += 1 }
        }
        XCTAssertLessThan(hitTheBack, 4,
                          "something in melee reached past the front rank \(hitTheBack) times in 14")
    }

    /// **Fall Back** — the twelfth skill, held back only until ranks existed. It swaps where you
    /// stand *without* spending the turn, which is the whole point of it.
    func testFallBackChangesWhereYouStandAndGivesTheTurnBack() throws {
        let store = inFightWith([armoured()])
        giveTheTurnTo(.binder, in: store)
        XCTAssertEqual(store.state.base.binderCharacter.rank, .front)

        store.mutate("test: give ground") { CombatRules.perform(.skill("fall_back"), by: .binder, in: &$0) }
        XCTAssertEqual(store.activeEncounter?.partyRanks[.binder], .back)
        XCTAssertEqual(store.state.base.binderCharacter.rank, .front,
                       "encounter movement must not rewrite the departing formation")
        // **And it's still your move.** The owed turn is spent the instant the order tries to move
        // on, which is what "without spending the turn" means from the player's side.
        XCTAssertEqual(store.activeEncounter?.current, .binder,
                       "Fall Back cost the turn it exists to save")
    }

    /// **Q36's addition** (audit #9): the two material properties with no job now have one. What
    /// you wear turns aside heat; what you swing leaves something in the wound.
    func testWhatYourGearIsMadeOfReachesTheFight() throws {
        let warm = ContentCatalog.shared.items.first { ($0.gear?.insulation ?? 0) > 0 }
        XCTAssertNotNil(warm, "nothing in the game is warm to wear")
        let volatile = ContentCatalog.shared.items.first { ($0.gear?.reactivity ?? 0) > 0 }
        XCTAssertNotNil(volatile, "nothing in the game is volatile to swing")

        // A volatile blade leaves a wound that goes on costing.
        let store = inFightWith([armoured()])
        let blade = try XCTUnwrap(volatile)
        store.mutate("test: carry it") { state in
            state.base.binderEquipped[.weapon] = EquippedPiece(catalogID: blade.id)
        }
        let foeID = try XCTUnwrap(store.activeEncounter?.foes.first).id
        giveTheTurnTo(.binder, in: store)
        store.mutate("test: swing") { CombatRules.perform(.attack(foe: foeID), by: .binder, in: &$0) }
        XCTAssertNotNil(store.activeEncounter?.foeBleeds[foeID],
                        "a volatile weapon left nothing behind")
    }

    func testBarbedEdgeLeavesLegacyBleedWithoutAConsumedCoating() throws {
        let edge = try XCTUnwrap(ContentCatalog.shared.item("rimed_edge"))
        XCTAssertEqual(edge.name, "Barbed Edge")
        XCTAssertEqual(edge.gear?.statusKind, "bleed")

        let store = inFightWith([armoured()])
        store.mutate("test: equip barbed edge") {
            $0.base.binderEquipped[.weapon] = EquippedPiece(catalogID: edge.id)
        }
        let foeID = try XCTUnwrap(store.activeEncounter?.foes.first?.id)
        for _ in 0..<12 where store.activeEncounter?.foeBleeds[foeID] == nil {
            giveTheTurnTo(.binder, in: store)
            store.mutate("test: strike with barbed edge") {
                CombatRules.perform(.attack(foe: foeID), by: .binder, in: &$0)
            }
        }
        XCTAssertNotNil(store.activeEncounter?.foeBleeds[foeID])
        XCTAssertNil(store.activeEncounter?.preparedCoatings[.binder])
    }

    // MARK: The second tap

    /// **Choosing between four identical wolves is a tap, not a decision** (Aimee, 7 Aug: *"if you
    /// just hit the attack button again it auto attacks either the first mob or it uses whatever
    /// self applied gambit logic exists if there is any."*).
    @MainActor
    func testTheSecondTapTakesTheFirstThingStanding() throws {
        let store = try storeInAFightWithSeveralFoes()
        let encounter = try XCTUnwrap(store.activeEncounter)
        XCTAssertGreaterThan(encounter.livingFoes.count, 1, "fixture: needs a choice to skip")

        let first = try XCTUnwrap(encounter.livingFoes.first)
        let action = try XCTUnwrap(store.defaultCombatAction())
        XCTAssertEqual(action, .attack(foe: first.id),
                       "with no rules of your own, the second tap takes the first thing standing")
    }

    /// The nicer half: the game already has a system for *act without me*, so the second tap is
    /// answered by the rules you wrote rather than by a hidden default.
    @MainActor
    func testTheSecondTapFollowsYourOwnRulesOnceYouHaveThem() throws {
        let store = try storeInAFightWithSeveralFoes()
        let encounter = try XCTUnwrap(store.activeEncounter)
        let weakest = try XCTUnwrap(encounter.livingFoes.min { $0.currentHP < $1.currentHP })
        XCTAssertNotEqual(weakest.id, encounter.livingFoes.first?.id,
                          "fixture: the rule has to disagree with the plain default")

        XCTAssertFalse(store.wouldActOnOwnRules, "you haven't learned to write your own hand yet")

        store.mutate("test: write your own hand") { state in
            state.base.hasAutomateSelfUnlock = true
            state.base.binderGambits = [
                GambitRule(id: InstanceID(rawValue: 1), subject: "subject_foe_lowest", action: "act_attack")
            ]
            state.base.ownedGambitComponents.insert("subject_foe_lowest")
        }

        XCTAssertTrue(store.wouldActOnOwnRules, "the prompt would lie about what a second tap does")
        XCTAssertEqual(store.defaultCombatAction(), .attack(foe: weakest.id),
                       "the second tap ignored the rules the player wrote")
    }

    /// A verb you already chose doesn't get re-asked either.
    @MainActor
    func testTheSecondTapCommitsAPendingSkill() throws {
        let store = try storeInAFightWithSeveralFoes()
        let encounter = try XCTUnwrap(store.activeEncounter)
        let first = try XCTUnwrap(encounter.livingFoes.first)
        let skill = try XCTUnwrap(ContentCatalog.shared.skills.first { $0.needsFoe })

        XCTAssertEqual(store.defaultCombatAction(pendingSkill: skill.id),
                       .skill(skill.id, foe: first.id),
                       "you picked the verb; it shouldn't make you pick the noun as well")
    }

    /// A fight with three things in it, one of them nearly dead, so "the first thing standing" and
    /// "the weakest" are different answers and the test can tell them apart.
    @MainActor
    private func storeInAFightWithSeveralFoes() throws -> GameStore {
        let store = GameStore(io: .temporary(name: "secondtap-\(UUID().uuidString)"))
        store.mutate("test: fund") { $0.base.essence = 5000 }
        store.bindAndDepart()
        guard store.state.worlds.activeRun != nil else { throw XCTSkip("couldn't depart") }

        var traits = CreatureTraits()
        traits.covering = Covering(hardness: 20, length: 20, coverage: 40)
        let stats = CombatStats.derived(from: traits, name: "Thing", icon: "pawprint")

        store.mutate("test: three of them") { state in
            guard var run = state.worlds.activeRun else { return }
            var rng = SeededRNG(seed: 4242)
            let foes = (1...3).map {
                FoeState(id: InstanceID(rawValue: UInt64($0)), traits: traits,
                         stats: stats, currentHP: stats.maxHP)
            }
            var encounter = CombatRules.makeEncounter(id: InstanceID(rawValue: 7), foes: foes, rng: &rng)
            encounter.foes[encounter.foes.count - 1].currentHP = 1
            encounter.turnIndex = encounter.order.firstIndex(of: .binder) ?? 0
            run.activeEncounter = encounter
            state.worlds.activeRun = run
        }
        return store
    }

    // MARK: A party of five

    /// **Everybody who came gets a turn.** Aimee asked for this repeatedly and I kept deferring it;
    /// the type was the reason — one nameless `.companion` meant one slot in the order, one place to
    /// keep health, and one rule list, so choosing four people at the fire could only ever be a lie.
    @MainActor
    func testEverybodyWhoCameIsInTheTurnOrder() throws {
        let store = try storeWithAFullParty()
        let encounter = try XCTUnwrap(store.activeEncounter)

        for index in store.state.base.activeParty {
            XCTAssertTrue(encounter.order.contains(.companion(index)),
                          "roster \(index) came along and never gets to move")
        }
        XCTAssertTrue(encounter.order.contains(.binder))
        XCTAssertEqual(encounter.order.filter(\.isParty).count, store.state.base.partyMembers.count)
    }

    /// **They are hurt separately.** One shared health field is the other half of why five couldn't
    /// fight: a second person had nowhere to be wounded.
    @MainActor
    func testEachOfThemIsHurtSeparately() throws {
        let store = try storeWithAFullParty()
        let party = store.state.base.activeParty
        XCTAssertGreaterThan(party.count, 1, "fixture: needs more than one of them")

        let first = party[0], second = party[1]
        store.mutate("test: hurt one of them") { state in
            let full = state.worlds.activeRun?.companionHP[first] ?? Tuning.Encounter.companionMaxHP
            state.worlds.activeRun?.companionHP[first] = full - 5
        }
        let run = try XCTUnwrap(store.state.worlds.activeRun)
        XCTAssertLessThan(CombatRules.health(of: .companion(first), in: run).current,
                          CombatRules.health(of: .companion(second), in: run).current,
                          "hurting one of them hurt all of them")
    }

    /// Each of them runs their own rules, and the log says so by name.
    @MainActor
    func testEachOfThemActsOnTheirOwnRulesAndIsNamed() throws {
        let store = try storeWithAFullParty()
        let expectedNames = Set(store.state.base.activeParty.map { store.state.base.roster[$0].name })
        var seenNames = Set<String>()
        var guardCount = 0
        while store.activeEncounter?.outcome == nil, seenNames != expectedNames, guardCount < 40 {
            guardCount += 1
            guard let foe = store.activeEncounter?.livingFoes.first else { break }
            store.takeCombatAction(.attack(foe: foe.id))
            let log = store.activeEncounter?.log ?? []
            seenNames.formUnion(expectedNames.filter { name in
                log.contains { $0.contains(name) }
            })
        }
        let log = store.activeEncounter?.log.joined(separator: "\n") ?? ""
        for name in expectedNames {
            XCTAssertTrue(seenNames.contains(name), "\(name) came along and never did anything:\n\(log)")
        }
    }

    /// Healing reaches whoever is worst off across the whole party, not whichever of two.
    @MainActor
    func testTheWholePartyIsSearchedForWhoeverIsWorstOff() throws {
        let store = try storeWithAFullParty()
        let party = store.state.base.activeParty
        let unlucky = party[party.count - 1]
        store.mutate("test: nearly out") { state in
            state.worlds.activeRun?.companionHP[unlucky] = 1
        }
        let run = try XCTUnwrap(store.state.worlds.activeRun)
        let worst = CombatRules.party(of: store.state)
            .filter { CombatRules.isAlive($0, in: run) }
            .min { a, b in
                let ha = CombatRules.health(of: a, in: run), hb = CombatRules.health(of: b, in: run)
                return Double(ha.current) / Double(ha.max) < Double(hb.current) / Double(hb.max)
            }
        XCTAssertEqual(worst, .companion(unlucky),
                       "the party search stopped at the first two people")
    }

    /// Three people at the fire, all of them coming, in a fight.
    @MainActor
    private func storeWithAFullParty() throws -> GameStore {
        let store = GameStore(io: .temporary(name: "party5-\(UUID().uuidString)"))
        store.mutate("test: fund") { $0.base.essence = 5000 }
        store.mutate("test: a fire with people at it") { state in
            var second = CompanionState(); second.name = "Bramwell"; second.gambits = GambitStarter.rules
            var third = CompanionState(); third.name = "Corvin"; third.gambits = GambitStarter.rules
            state.base.roster = [CompanionState(), second, third]
            state.base.activeParty = [0, 1, 2]
        }
        store.bindAndDepart()
        guard store.state.worlds.activeRun != nil else { throw XCTSkip("couldn't depart") }

        var traits = CreatureTraits()
        traits.covering = Covering(hardness: 10, length: 10, coverage: 20)
        let stats = CombatStats.derived(from: traits, name: "Thing", icon: "pawprint")
        store.mutate("test: a fight") { state in
            guard var run = state.worlds.activeRun else { return }
            var rng = SeededRNG(seed: 99)
            // Tough enough that the fight lasts a full round or two — with four of you swinging,
            // a couple of soft things die before everybody has had a turn.
            var burly = stats
            burly.maxHP = 400
            let foes = (1...2).map {
                FoeState(id: InstanceID(rawValue: UInt64($0)), traits: traits,
                         stats: burly, currentHP: burly.maxHP)
            }
            run.activeEncounter = CombatRules.makeEncounter(
                id: InstanceID(rawValue: 7), foes: foes,
                party: CombatRules.party(of: state),
                names: state.base.activeParty.reduce(into: [Int: String]()) {
                    $0[$1] = state.base.roster[$1].name
                },
                rng: &rng)
            state.worlds.activeRun = run
            // A fight may open on somebody else's turn, and the real path kicks the automatic ones
            // off after building the encounter. Without this the fixture just stands there.
            CombatRules.runAutomaticTurns(in: &state)
        }
        return store
    }

    func testDebugV2EnabledEmptyReceiptIsDistinctFromLegacyAndFreezesAcrossRelaunch() throws {
        var rng = SeededRNG(seed: 44)
        let empty = EncounterState.DebugV2BinderAttackReceipt(
            ordinaryWeaponKind: .crush, crushBonus: .init(components: []),
            pierceBonus: .init(components: []))
        let v2 = CombatRules.makeEncounter(id: InstanceID(rawValue: 1), foes: [], party: [.binder],
                                           debugV2BinderAttack: empty, rng: &rng)
        let legacy = CombatRules.makeEncounter(id: InstanceID(rawValue: 2), foes: [], party: [.binder], rng: &rng)
        XCTAssertEqual(v2.debugV2BinderAttack?.preMatchupBonus(for: .crush).total, 0)
        XCTAssertNil(legacy.debugV2BinderAttack)
        XCTAssertEqual(try JSONDecoder().decode(EncounterState.self,
                                                from: JSONEncoder().encode(v2)).debugV2BinderAttack,
                       empty)
    }

    func testThickHideExpeditionCapsArePersonalAcrossFivePartyMembers() throws {
        var state = GameState.newGame()
        while state.base.roster.count < 4 { state.base.roster.append(CompanionState()) }
        state.base.activeParty = [0, 1, 2, 3]
        var tuning = DebugTuningProfile.defaults
        tuning.debugCombatV2BinderAttackEnabled = true
        tuning.debugCombatV2BinderNodeIDs = [CombatDerivedStatsRules.Node.thickHide]
        tuning.debugCombatV2CompanionNodeIDs = [2: [CombatDerivedStatsRules.Node.thickHide]]

        let caps = CombatRules.expeditionHealthCaps(in: state, tuning: tuning)
        XCTAssertEqual(caps.count, 5)
        for member in state.base.partyMembers {
            let cap = try XCTUnwrap(caps.first { $0.member == member })
            let expectedComponent = member == .binder || member == .member(2) ? 6 : 0
            XCTAssertEqual(cap.maximum, cap.ordinaryMaximum + expectedComponent, member.id)
            XCTAssertEqual(cap.components.map(\.nodeID), expectedComponent == 0
                           ? [] : [CombatDerivedStatsRules.Node.thickHide], member.id)
        }
    }

    func testDepartureFreezesThickHideAndLaterPreferenceChangesCannotRewriteRun() throws {
        let defaults = UserDefaults.standard
        let prior = defaults.data(forKey: DebugTuningProfile.storageKey)
        defer {
            if let prior { defaults.set(prior, forKey: DebugTuningProfile.storageKey) }
            else { defaults.removeObject(forKey: DebugTuningProfile.storageKey) }
        }
        var tuning = DebugTuningProfile.defaults
        tuning.debugCombatV2BinderAttackEnabled = true
        tuning.debugCombatV2BinderNodeIDs = [CombatDerivedStatsRules.Node.thickHide]
        defaults.set(try JSONEncoder().encode(tuning), forKey: DebugTuningProfile.storageKey)

        let io = SaveFileIO.temporary(name: "thick-hide-departure-\(UUID().uuidString)")
        defer { io.deleteEverything() }
        let store = GameStore(io: io)
        store.write("plains")
        XCTAssertTrue(store.bindAndDepart())
        let frozen = try XCTUnwrap(store.activeRun?.healthCap(for: .binder))
        XCTAssertEqual(frozen.maximum, frozen.ordinaryMaximum + 6)
        XCTAssertEqual(store.activeRun?.binderHP, frozen.maximum)

        tuning.debugCombatV2BinderNodeIDs = []
        defaults.set(try JSONEncoder().encode(tuning), forKey: DebugTuningProfile.storageKey)
        XCTAssertEqual(store.activeRun?.healthCap(for: .binder), frozen)
        store.flushNow()
        let relaunched = GameStore(io: io)
        XCTAssertEqual(relaunched.activeRun?.healthCap(for: .binder), frozen)
        XCTAssertEqual(relaunched.activeRun?.binderHP, frozen.maximum)
    }

    func testFrozenHealthCapDrivesWorldAndCombatHealing() throws {
        let store = inFight(["paper_moth"])
        let worldSalve = ItemStack(id: InstanceID(rawValue: 88_001), catalogID: "salve_lesser")
        store.mutate("freeze test health cap") { state in
            guard var run = state.worlds.activeRun else { return }
            run.healthCaps = [RunHealthCapEntry(member: .binder, ordinaryMaximum: 20,
                                                components: [.init(
                                                    nodeID: CombatDerivedStatsRules.Node.thickHide,
                                                    amount: 6)])]
            run.binderHP = 25
            _ = run.satchelItems.add(worldSalve)
            run.activeEncounter = nil
            state.worlds.activeRun = run
            _ = WorldRules.useItem(worldSalve.id, on: .binder, in: &state)
        }
        XCTAssertEqual(store.activeRun?.binderHP, 26)
        XCTAssertEqual(CombatRules.health(of: .binder, in: try XCTUnwrap(store.activeRun)).max, 26)

        let combatSalve = ItemStack(id: InstanceID(rawValue: 88_002), catalogID: "salve_lesser")
        store.mutate("stage combat healing against same receipt") { state in
            guard var run = state.worlds.activeRun else { return }
            var rng = run.rng
            run.activeEncounter = CombatRules.makeEncounter(id: InstanceID(rawValue: 88_003),
                                                             foes: [], party: [.binder], rng: &rng)
            run.activeEncounter?.order = [.binder]
            run.activeEncounter?.turnIndex = 0
            run.binderHP = 25
            _ = run.satchelItems.add(combatSalve)
            state.worlds.activeRun = run
            CombatRules.perform(.useItem(stack: combatSalve.id, ally: .binder),
                                by: .binder, in: &state)
        }
        XCTAssertEqual(store.activeRun?.binderHP, 26)
    }

    func testLegacyRunHealthAdoptionPreservesSavedCurrentWithoutV2Provenance() throws {
        var state = GameState.newGame()
        var map = WorldMap(width: 1, height: 1, tiles: [Tile(isRevealed: true)],
                           entry: GridPoint(x: 0, y: 0))
        map[GridPoint(x: 0, y: 0)].content = .portal(isEntry: true)
        state.worlds.activeRun = WorldRun(runIndex: 1,
                                          book: BoundBook(written: [], essencePaid: 0),
                                          mapSeed: 9, rng: SeededRNG(seed: 9), map: map,
                                          playerPosition: GridPoint(x: 0, y: 0), binderHP: 99)
        XCTAssertTrue(CombatRules.reconcileExpeditionHealth(in: &state))
        let cap = try XCTUnwrap(state.worlds.activeRun?.healthCap(for: .binder))
        XCTAssertEqual(cap.maximum, 99)
        XCTAssertEqual(cap.components, [])
        XCTAssertEqual(state.worlds.activeRun?.binderHP, 99)
        XCTAssertFalse(CombatRules.reconcileExpeditionHealth(in: &state),
                       "adoption must be idempotent")
    }

    func testAdoptionKeepsAlreadyFrozenV2ThickHideProvenanceWithoutHealing() throws {
        var state = GameState.newGame()
        var map = WorldMap(width: 1, height: 1, tiles: [Tile(isRevealed: true)],
                           entry: GridPoint(x: 0, y: 0))
        map[GridPoint(x: 0, y: 0)].content = .portal(isEntry: true)
        var tuning = DebugTuningProfile.defaults
        tuning.debugCombatV2BinderAttackEnabled = true
        tuning.debugCombatV2BinderNodeIDs = [CombatDerivedStatsRules.Node.thickHide]
        var run = WorldRun(runIndex: 1, book: BoundBook(written: [], essencePaid: 0),
                           mapSeed: 11, rng: SeededRNG(seed: 11), map: map,
                           playerPosition: GridPoint(x: 0, y: 0), binderHP: 7,
                           tuning: tuning)
        run.healthCaps = nil
        state.worlds.activeRun = run

        XCTAssertTrue(CombatRules.reconcileExpeditionHealth(in: &state))
        let adopted = try XCTUnwrap(state.worlds.activeRun?.healthCap(for: .binder))
        XCTAssertEqual(adopted.components, [.init(
            nodeID: CombatDerivedStatsRules.Node.thickHide, amount: 6)])
        XCTAssertEqual(state.worlds.activeRun?.binderHP, 7, "adoption must not heal")
        XCTAssertGreaterThanOrEqual(adopted.maximum, 7)
    }

    func testSavedHealthReceiptNormalizesDuplicateComponentsAndClampsOverCapOnce() throws {
        var state = GameState.newGame()
        var map = WorldMap(width: 1, height: 1, tiles: [Tile(isRevealed: true)],
                           entry: GridPoint(x: 0, y: 0))
        map[GridPoint(x: 0, y: 0)].content = .portal(isEntry: true)
        let cap = RunHealthCapEntry(member: .binder, ordinaryMaximum: 20, components: [
            .init(nodeID: CombatDerivedStatsRules.Node.thickHide, amount: 6),
            .init(nodeID: CombatDerivedStatsRules.Node.thickHide, amount: 6)
        ])
        XCTAssertEqual(cap.maximum, 26)
        XCTAssertEqual(cap.components.count, 1)
        state.worlds.activeRun = WorldRun(runIndex: 1,
                                          book: BoundBook(written: [], essencePaid: 0),
                                          mapSeed: 10, rng: SeededRNG(seed: 10), map: map,
                                          playerPosition: GridPoint(x: 0, y: 0), binderHP: 40,
                                          healthCaps: [cap])
        XCTAssertTrue(CombatRules.reconcileExpeditionHealth(in: &state))
        XCTAssertEqual(state.worlds.activeRun?.binderHP, 26)
        XCTAssertFalse(CombatRules.reconcileExpeditionHealth(in: &state))
    }

    func testThickHideComposesLevelAndLegacyCompatibilityExactlyOnce() throws {
        var state = GameState.newGame()
        state.base.binderCharacter.level = 8
        state.base.binderCharacter.branchDepth["defense_fortitude"] = 1
        let characterOnly = CharacterRules.maximumHealth(state.base.binderCharacter,
                                                          base: Tuning.Encounter.binderMaxHP)
        var v2 = DebugTuningProfile.defaults
        v2.debugCombatV2BinderAttackEnabled = true
        v2.debugCombatV2BinderNodeIDs = [CombatDerivedStatsRules.Node.thickHide]
        let v2Cap = try XCTUnwrap(CombatRules.expeditionHealthCaps(in: state, tuning: v2)
            .first { $0.member == .binder })
        XCTAssertEqual(v2Cap.ordinaryMaximum, characterOnly)
        XCTAssertEqual(v2Cap.maximum, characterOnly + 6,
                       "legacy maxHP and canonical Thick Hide must not both be added")

        let legacyCap = try XCTUnwrap(CombatRules.expeditionHealthCaps(
            in: state, tuning: .legacyFrozenRunDefaults).first { $0.member == .binder })
        XCTAssertEqual(legacyCap.maximum, CombatRules.maximumHealth(of: .binder, in: state))
        XCTAssertTrue(legacyCap.components.isEmpty)
    }

    func testFrozenCapOwnsGambitFractionAndPassedOutState() throws {
        let store = inFight(["paper_moth"], gambits: [Self.healHurtAlly])
        store.mutate("freeze twenty-six health") { state in
            state.worlds.activeRun?.healthCaps = [RunHealthCapEntry(
                member: .binder, ordinaryMaximum: 20,
                components: [.init(nodeID: CombatDerivedStatsRules.Node.thickHide, amount: 6)])]
            state.worlds.activeRun?.binderHP = 13
        }
        XCTAssertNil(GambitEngine.decide(in: store.state), "13 / 26 is not below half")
        store.mutate("drop below frozen half") { $0.worlds.activeRun?.binderHP = 12 }
        XCTAssertEqual(GambitEngine.decide(in: store.state)?.rule, Self.healHurtAlly)
        store.mutate("pass out") { $0.worlds.activeRun?.binderHP = 0 }
        XCTAssertTrue(CombatRules.hasPassedOut(.binder, in: try XCTUnwrap(store.activeRun)))
    }

    func testFrozenDebugInitiativeDrivesOrderAndExplainsContactPriority() throws {
        let quick = CombatDerivedStatsRules.Node.quickStep
        let frame = CombatDerivedStatsRules.Node.lightFrame
        var stats = CombatStats(displayName: "Ordinary", icon: "circle",
                                maxHP: 20, attack: 2, armour: 0,
                                damageKind: .pierce, initiative: 45)
        stats.strikesFirst = false
        let ordinaryFoe = FoeState(id: InstanceID(rawValue: 90), stats: stats, currentHP: 20)
        stats.initiative = 1
        stats.strikesFirst = true
        let priorityFoe = FoeState(id: InstanceID(rawValue: 91), stats: stats, currentHP: 20)
        let draft = try XCTUnwrap(CombatDerivedStatsRules.debugInitiativeReceipt(
            enabled: true, party: [.binder, .companion(2), .companion(7)],
            foes: [ordinaryFoe, priorityFoe], binderNodeIDs: [quick],
            companionNodeIDs: [2: [frame], 7: [quick]]))
        var rng = SeededRNG(seed: 700)
        let encounter = CombatRules.makeEncounter(
            id: InstanceID(rawValue: 3), foes: [ordinaryFoe, priorityFoe],
            party: [.binder, .companion(2), .companion(7)],
            debugV2Initiative: draft, rng: &rng)

        XCTAssertEqual(encounter.order.first, .foe(priorityFoe.id),
                       "strikesFirst remains separate from the numeric initiative total")
        XCTAssertLessThan(try XCTUnwrap(encounter.order.firstIndex(of: .binder)),
                          try XCTUnwrap(encounter.order.firstIndex(of: .foe(ordinaryFoe.id))),
                          "Quick Step must cross the ordinary foe's initiative")
        let saved = try XCTUnwrap(encounter.debugV2Initiative)
        XCTAssertEqual(saved.entry(for: .binder)?.total, 46)
        XCTAssertEqual(saved.entry(for: .companion(2))?.total, 43)
        XCTAssertEqual(saved.entry(for: .companion(7))?.total, 44)
        XCTAssertEqual(saved.entry(for: .foe(priorityFoe.id))?.strikesFirst, true)
        XCTAssertEqual(saved.entries.compactMap(\.finalPosition).sorted(), Array(1...5))
        XCTAssertEqual(try JSONDecoder().decode(EncounterState.self,
                                                from: JSONEncoder().encode(encounter)).debugV2Initiative,
                       saved)
    }

    func testDebugInitiativeDisabledAndEnabledEmptyPreserveLegacyOrder() throws {
        let foe = FoeState(id: InstanceID(rawValue: 92),
                           stats: CombatStats(displayName: "Tie", icon: "circle",
                                              maxHP: 10, attack: 1, armour: 0, initiative: 42),
                           currentHP: 10)
        var legacyRNG = SeededRNG(seed: 808)
        var emptyRNG = SeededRNG(seed: 808)
        let legacy = CombatRules.makeEncounter(id: InstanceID(rawValue: 1), foes: [foe], party: [.binder, .companion(4)],
                                               rng: &legacyRNG)
        let emptyDraft = try XCTUnwrap(CombatDerivedStatsRules.debugInitiativeReceipt(
            enabled: true, party: [.binder, .companion(4)], foes: [foe],
            binderNodeIDs: [], companionNodeIDs: [:]))
        let empty = CombatRules.makeEncounter(id: InstanceID(rawValue: 2), foes: [foe], party: [.binder, .companion(4)],
                                              debugV2Initiative: emptyDraft, rng: &emptyRNG)
        XCTAssertEqual(empty.order, legacy.order)
        XCTAssertNil(legacy.debugV2Initiative)
        XCTAssertNotNil(empty.debugV2Initiative)
    }

    func testWorldRulesFreezesDebugInitiativeFromRunTuningAtContact() throws {
        let io = SaveFileIO.temporary(name: "v2-initiative-entry-\(UUID().uuidString)")
        defer { io.deleteEverything() }
        let store = GameStore(io: io)
        store.write("plains")
        XCTAssertTrue(store.bindAndDepart())
        store.mutate("configure exact v2 initiative ownership") { state in
            guard var run = state.worlds.activeRun, let enemy = run.enemies.first else { return }
            run.tuning.debugCombatV2BinderAttackEnabled = true
            run.tuning.debugCombatV2BinderNodeIDs = [CombatDerivedStatsRules.Node.quickStep]
            run.tuning.debugCombatV2CompanionNodeIDs = [0: [CombatDerivedStatsRules.Node.lightFrame]]
            state.worlds.activeRun = run
            WorldRules.beginEncounter(triggeredBy: enemy, runsAutomaticTurns: false, in: &state)
        }
        let frozen = try XCTUnwrap(store.activeEncounter?.debugV2Initiative)
        XCTAssertEqual(frozen.entry(for: .binder)?.total, 46)
        if CombatRules.party(of: store.state).contains(.companion(0)) {
            XCTAssertEqual(frozen.entry(for: .companion(0))?.total, 43)
        }

        store.mutate("change harness after contact") { state in
            state.worlds.activeRun?.tuning.debugCombatV2BinderNodeIDs = []
            state.worlds.activeRun?.tuning.debugCombatV2CompanionNodeIDs = [:]
        }
        XCTAssertEqual(store.activeEncounter?.debugV2Initiative, frozen)
        store.flushNow()
        let relaunched = GameStore(io: io)
        XCTAssertEqual(relaunched.activeEncounter?.debugV2Initiative, frozen)
        XCTAssertEqual(relaunched.activeEncounter?.order, store.activeEncounter?.order)
    }

    func testDebugInitiativeDetailsPresentWithoutGrowingEncounterHeaderByActorCount() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf: root.appendingPathComponent("Sources/Screens/EncounterView.swift"),
                                encoding: .utf8)
        let headerStart = try XCTUnwrap(source.range(of: "private func header(_ encounter:"))
        let headerEnd = try XCTUnwrap(source.range(of: "private func turnText", range: headerStart.upperBound..<source.endIndex))
        let header = String(source[headerStart.lowerBound..<headerEnd.lowerBound])

        XCTAssertTrue(header.contains("Button(\"V2 order · \\(receipt.entries.count) actors\")"))
        XCTAssertFalse(header.contains("ForEach"))
        XCTAssertFalse(header.contains("receipt.entries.sorted"),
                       "receipt rows belong in presented detail, never the gameplay header")
        XCTAssertTrue(source.contains(".sheet(isPresented: $isShowingDebugV2Order)"))
        XCTAssertTrue(source.contains("Contact priority places this actor before ordinary initiative totals."))
    }

    func testFrozenDebugV2ReceiptUsesOnlyTheMatchingExactNode() throws {
        let heavy = CombatDerivedStatsRules.Node.heavyHand
        let keen = CombatDerivedStatsRules.Node.keenEye
        let crush = CombatDerivedStatsRules.preMatchupAttackBonus(
            ownedNodeIDs: [heavy, keen], weaponDamageKind: .crush)
        XCTAssertEqual(crush.total, 2)
        XCTAssertEqual(crush.components.map(\.nodeID), [heavy])
        XCTAssertEqual(CombatDerivedStatsRules.preMatchupAttackBonus(
            ownedNodeIDs: [heavy], weaponDamageKind: .pierce).total, 0)
        XCTAssertEqual(CombatDerivedStatsRules.preMatchupAttackBonus(
            ownedNodeIDs: [keen], weaponDamageKind: .pierce).total, 2)

        var rng = SeededRNG(seed: 9)
        let encounter = CombatRules.makeEncounter(
            id: InstanceID(rawValue: 1), foes: [], party: [.binder],
            debugV2BinderAttack: .init(ordinaryWeaponKind: .crush, crushBonus: crush,
                                       pierceBonus: CombatDerivedStatsRules.preMatchupAttackBonus(
                                        ownedNodeIDs: [heavy, keen], weaponDamageKind: .pierce)), rng: &rng)
        var changedPreference = DebugTuningProfile()
        changedPreference.debugCombatV2BinderAttackEnabled = true
        changedPreference.debugCombatV2BinderNodeIDs = [keen]
        XCTAssertEqual(encounter.debugV2BinderAttack?.preMatchupBonus(for: .crush), crush,
                       "post-entry DEBUG changes cannot mutate the frozen encounter receipt")
    }

    func testFrozenV2AttackMatrixUsesPreviewAndCommittedPathExactlyOnce() throws {
        let cases: [(weapon: ItemID, kind: DamageKind, nodes: Set<CombatNodeID>, bonus: Int)] = [
            ("field_maul", .crush, [CombatDerivedStatsRules.Node.heavyHand], 2),
            ("blade_keen", .pierce, [CombatDerivedStatsRules.Node.keenEye], 2),
            ("blade_keen", .pierce, [CombatDerivedStatsRules.Node.heavyHand], 0),
            ("field_maul", .crush, [], 0)
        ]
        for (offset, fixture) in cases.enumerated() {
            let store = GameStore(io: .temporary(name: "v2-hit-\(UUID().uuidString)"))
            store.write("plains")
            store.bindAndDepart()
            let foeID = InstanceID(rawValue: UInt64(501 + offset))
            var traits = CreatureTraits()
            traits.covering = Covering(hardness: 0, length: 0, coverage: 0)
            var stats = CombatStats.derived(from: traits, name: "Target", icon: "circle")
            stats.maxHP = 500; stats.armour = 0; stats.evasion = 0
            store.mutate("stage fixed v2 hit") { state in
                state.base.binderEquipped[.weapon] = EquippedPiece(catalogID: fixture.weapon)
                guard var run = state.worlds.activeRun else { return }
                var orderRNG = SeededRNG(seed: 1)
                run.activeEncounter = CombatRules.makeEncounter(
                    id: InstanceID(rawValue: 2),
                    foes: [FoeState(id: foeID, traits: traits, stats: stats, currentHP: stats.maxHP)],
                    party: [.binder],
                    debugV2BinderAttack: .init(
                        ordinaryWeaponKind: fixture.kind,
                        crushBonus: CombatDerivedStatsRules.preMatchupAttackBonus(
                            ownedNodeIDs: fixture.nodes, weaponDamageKind: .crush),
                        pierceBonus: CombatDerivedStatsRules.preMatchupAttackBonus(
                            ownedNodeIDs: fixture.nodes, weaponDamageKind: .pierce)),
                    rng: &orderRNG)
                state.worlds.activeRun = run
            }
            let receipt = try XCTUnwrap(store.activeEncounter?.debugV2BinderAttack)
            XCTAssertEqual(receipt.preMatchupBonus(for: fixture.kind).total, fixture.bonus)
            let preview = try XCTUnwrap(CombatRules.debugV2DirectAttackPreview(
                foe: try XCTUnwrap(store.activeEncounter?.foes.first), in: store.state))
            let basePower = CombatRules.binderAttack(in: store.state) + fixture.bonus
            let spread = max(1, Int((Double(basePower) * Tuning.Encounter.damageVariance).rounded()))
            var fixedRNG = try XCTUnwrap(store.state.worlds.activeRun).rng
            let fixedRoll = max(Tuning.Encounter.minimumDamage,
                                basePower + fixedRNG.int(in: -spread...spread))
            let expected = CombatDamageRules.resolve(
                rolledPower: fixedRoll,
                in: .init(damageKind: fixture.kind, covering: traits.covering, armour: 0))
            let before = try XCTUnwrap(store.activeEncounter?.foes.first?.currentHP)
            store.mutate("commit fixed attack") {
                CombatRules.perform(.attack(foe: foeID), by: .binder, in: &$0)
            }
            let committed = before - (try XCTUnwrap(store.activeEncounter?.foes.first?.currentHP))
            XCTAssertTrue((preview.lower.finalDamage...preview.upper.finalDamage).contains(committed))
            XCTAssertEqual(committed, expected.finalDamage,
                           "fixed-roll preview and commit diverged for \(fixture.kind)")
        }
    }

    func testFrozenHeavyHandAndKeenEyeReachOnlyTheirExplicitWeaponTechniques() throws {
        let fixtures: [(skill: SkillID, weapon: ItemID, kind: DamageKind,
                        node: CombatNodeID, isWeaponTechnique: Bool)] = [
            ("overbear", "blade_keen", .crush, CombatDerivedStatsRules.Node.heavyHand, true),
            ("pry", "field_maul", .pierce, CombatDerivedStatsRules.Node.keenEye, true),
            ("unbind", "field_maul", .crush, CombatDerivedStatsRules.Node.heavyHand, false)
        ]
        for fixture in fixtures {
            for nodes: Set<CombatNodeID> in [[fixture.node], []] {
                let store = GameStore(io: .temporary(name: "v2-technique-\(UUID().uuidString)"))
                store.mutate("learn techniques") { Self.learnEverything(&$0) }
                store.write("plains"); store.bindAndDepart()
                let foeID = InstanceID(rawValue: 701)
                var traits = CreatureTraits()
                traits.covering = Covering(hardness: 0, length: 0, coverage: 0)
                var stats = CombatStats.derived(from: traits, name: "Target", icon: "circle")
                stats.maxHP = 500; stats.armour = 0; stats.evasion = 0
                store.mutate("stage weapon technique") { state in
                    Self.learnEverything(&state)
                    state.base.binderEquipped[.weapon] = EquippedPiece(catalogID: fixture.weapon)
                    guard var run = state.worlds.activeRun else { return }
                    var orderRNG = SeededRNG(seed: 2)
                    let ordinaryKind: DamageKind = fixture.weapon == "field_maul" ? .crush : .pierce
                    run.activeEncounter = CombatRules.makeEncounter(
                        id: InstanceID(rawValue: 3),
                        foes: [FoeState(id: foeID, traits: traits, stats: stats, currentHP: stats.maxHP)],
                        party: [.binder],
                        debugV2BinderAttack: .init(
                            ordinaryWeaponKind: ordinaryKind,
                            crushBonus: CombatDerivedStatsRules.preMatchupAttackBonus(
                                ownedNodeIDs: nodes, weaponDamageKind: .crush),
                            pierceBonus: CombatDerivedStatsRules.preMatchupAttackBonus(
                                ownedNodeIDs: nodes, weaponDamageKind: .pierce)), rng: &orderRNG)
                    state.worlds.activeRun = run
                }
                let skill = try XCTUnwrap(ContentCatalog.shared.skill(fixture.skill))
                let ordinaryPower = CharacterRules.skillPower(skill.power,
                                                               store.state.base.binderCharacter.stats)
                let bonus = nodes.isEmpty || !fixture.isWeaponTechnique ? 0 : 2
                let power = ordinaryPower + bonus
                let spread = max(1, Int((Double(power) * Tuning.Encounter.damageVariance).rounded()))
                var fixedRNG = try XCTUnwrap(store.state.worlds.activeRun).rng
                let fixedRoll = max(Tuning.Encounter.minimumDamage,
                                    power + fixedRNG.int(in: -spread...spread))
                let expected = CombatDamageRules.resolve(
                    rolledPower: fixedRoll,
                    in: .init(damageKind: fixture.kind, covering: traits.covering,
                              armour: 0, ignoresArmour: fixture.skill == "pry"))
                let before = try XCTUnwrap(store.activeEncounter?.foes.first?.currentHP)
                store.mutate("commit weapon technique") {
                    CombatRules.perform(.skill(fixture.skill, foe: foeID), by: .binder, in: &$0)
                }
                XCTAssertEqual(before - (try XCTUnwrap(store.activeEncounter?.foes.first?.currentHP)),
                               expected.finalDamage)
            }
        }
    }

    func testFrozenV2ArmourCombinesPersonalAndStrongestOnceFormationBonuses() throws {
        let iron = CombatDerivedStatsRules.Node.ironSkin
        let bulwark = CombatDerivedStatsRules.Node.bulwark
        let shieldwall = CombatDerivedStatsRules.Node.shieldwall
        let receipt = EncounterState.DebugV2ArmourReceipt(entries: [
            .init(actor: .binder, equipmentProtectivePower: 3, sturdiness: 1.5,
                  ownedNodeIDs: [iron, bulwark], entryRank: .front),
            .init(actor: .companion(0), equipmentProtectivePower: 0, sturdiness: 1,
                  ownedNodeIDs: [bulwark, shieldwall], entryRank: .front),
            .init(actor: .companion(1), equipmentProtectivePower: 0, sturdiness: 1,
                  ownedNodeIDs: [bulwark, shieldwall], entryRank: .front),
            .init(actor: .companion(2), equipmentProtectivePower: 0, sturdiness: 1,
                  ownedNodeIDs: [bulwark], entryRank: .back),
            .init(actor: .companion(3), equipmentProtectivePower: 0, sturdiness: 1,
                  ownedNodeIDs: [], entryRank: .back)
        ])
        let allConscious: Set<Combatant> = [.binder, .companion(0), .companion(1),
                                            .companion(2), .companion(3)]
        let ranks: [Combatant: Rank] = [.binder: .front, .companion(0): .front,
                                        .companion(1): .front, .companion(2): .back,
                                        .companion(3): .back]
        let result = CombatDerivedStatsRules.incomingDamage(
            raw: 30, receiver: .binder, receipt: receipt, ranks: ranks,
            conscious: allConscious, armourIgnored: 0)

        XCTAssertEqual(result.breakdown.equipment, 3 * 1.5 * Double(Tuning.Encounter.defencePerArmorTier))
        XCTAssertEqual(result.breakdown.components.filter { $0.nodeID == iron }.map(\.amount), [2])
        XCTAssertEqual(result.breakdown.components.filter { $0.nodeID == bulwark }.map(\.amount), [1, 2],
                       "personal Bulwark and one strongest ally aura coexist")
        XCTAssertEqual(result.breakdown.components.filter { $0.nodeID == shieldwall }.map(\.amount), [2],
                       "duplicate Shieldwalls must apply strongest-once")

        var movedRanks = ranks
        movedRanks[.binder] = .back
        let moved = CombatDerivedStatsRules.incomingDamage(
            raw: 30, receiver: .binder, receipt: receipt, ranks: movedRanks,
            conscious: allConscious, armourIgnored: 0)
        XCTAssertFalse(moved.breakdown.components.contains { $0.nodeID == shieldwall })
        XCTAssertEqual(moved.breakdown.components.filter { $0.nodeID == bulwark }.map(\.amount), [1, 2],
                       "current-rank back Bulwark may come from the conscious back ally")

        let passedOut = CombatDerivedStatsRules.incomingDamage(
            raw: 30, receiver: .binder, receipt: receipt, ranks: ranks,
            conscious: [.binder, .companion(2), .companion(3)], armourIgnored: 0)
        XCTAssertFalse(passedOut.breakdown.components.contains { $0.nodeID == shieldwall })
        XCTAssertEqual(passedOut.breakdown.components.filter { $0.nodeID == bulwark }.map(\.amount), [1],
                       "passed-out aura owners stop contributing")

        let ignored = CombatDerivedStatsRules.incomingDamage(
            raw: 30, receiver: .binder, receipt: receipt, ranks: ranks,
            conscious: allConscious, armourIgnored: 1)
        XCTAssertEqual(ignored.breakdown.effectiveArmour, 0)
        XCTAssertEqual(ignored.finalDamage, 30)
    }

    func testV2ArmourMissingEntryAndRankFailClosedWithoutLiveLegacyFallback() throws {
        var state = GameState.newGame()
        state.base.binderCharacter.branchDepth["defense_fortitude"] = 3
        let missingReceiver = EncounterState.DebugV2ArmourReceipt(entries: [
            .init(actor: .companion(0), equipmentProtectivePower: 99, sturdiness: 2,
                  ownedNodeIDs: [CombatDerivedStatsRules.Node.bulwark], entryRank: .back)
        ])
        var rng = SeededRNG(seed: 44)
        let encounter = CombatRules.makeEncounter(
            id: InstanceID(rawValue: 44), foes: [], party: [.binder],
            debugV2Armour: missingReceiver, partyRanks: [:], rng: &rng)
        var map = WorldMap(width: 1, height: 1, tiles: [Tile(isRevealed: true)],
                           entry: GridPoint(x: 0, y: 0))
        map[GridPoint(x: 0, y: 0)].content = .portal(isEntry: true)
        let run = WorldRun(runIndex: 1, book: BoundBook(written: [], essencePaid: 0),
                           mapSeed: 44, rng: SeededRNG(seed: 44), map: map,
                           playerPosition: GridPoint(x: 0, y: 0), binderHP: 20)
        let result = try XCTUnwrap(CombatRules.v2IncomingDamage(
            12, by: .binder, in: state, run: run, encounter: encounter))
        XCTAssertEqual(result.rank, .front)
        XCTAssertEqual(result.breakdown.totalBeforeIgnore, 0)
        XCTAssertEqual(result.finalDamage, 12,
                       "corrupt v2 receipt must not mix in mutable legacy tree or gear")

        let frozenRank = EncounterState.DebugV2ArmourReceipt(entries: [
            .init(actor: .binder, equipmentProtectivePower: 0, sturdiness: 1,
                  ownedNodeIDs: [], entryRank: .back)
        ])
        let fallback = CombatDerivedStatsRules.incomingDamage(
            raw: 12, receiver: .binder, receipt: frozenRank, ranks: [:],
            conscious: [.binder], armourIgnored: 0)
        XCTAssertEqual(fallback.rank, .back, "missing saved rank adopts the frozen entry rank")
    }

    func testDebugV2ArmourDisabledAndEnabledEmptyPreserveLegacyDamage() throws {
        let state = GameState.newGame()
        let empty = try XCTUnwrap(CombatRules.debugArmourReceipt(
            enabled: true, party: [.binder], in: state,
            binderNodeIDs: [], companionNodeIDs: [:]))
        var rng = SeededRNG(seed: 45)
        let encounter = CombatRules.makeEncounter(
            id: InstanceID(rawValue: 45), foes: [], party: [.binder],
            debugV2Armour: empty, partyRanks: [.binder: .front], rng: &rng)
        var map = WorldMap(width: 1, height: 1, tiles: [Tile(isRevealed: true)],
                           entry: GridPoint(x: 0, y: 0))
        map[GridPoint(x: 0, y: 0)].content = .portal(isEntry: true)
        let run = WorldRun(runIndex: 1, book: BoundBook(written: [], essencePaid: 0),
                           mapSeed: 45, rng: SeededRNG(seed: 45), map: map,
                           playerPosition: GridPoint(x: 0, y: 0), binderHP: 20)
        XCTAssertEqual(CombatRules.damageTaken(17, by: .binder, in: state,
                                               run: run, encounter: encounter),
                       CombatRules.damageTaken(17, by: .binder, in: state))
        XCTAssertNotNil(encounter.debugV2Armour,
                        "enabled with zero nodes remains a real frozen v2 comparison route")
    }

    func testWorldContactFreezesV2ArmourAndSharedPreviewCommitAcrossRelaunch() throws {
        let io = SaveFileIO.temporary(name: "v2-armour-entry-\(UUID().uuidString)")
        defer { io.deleteEverything() }
        let store = GameStore(io: io)
        store.write("plains")
        XCTAssertTrue(store.bindAndDepart())
        store.mutate("freeze exact armour receipt") { state in
            guard var run = state.worlds.activeRun, let enemy = run.enemies.first else { return }
            run.tuning.debugCombatV2BinderAttackEnabled = true
            run.tuning.debugCombatV2BinderNodeIDs = [CombatDerivedStatsRules.Node.ironSkin,
                                                      CombatDerivedStatsRules.Node.bulwark]
            state.worlds.activeRun = run
            WorldRules.beginEncounter(triggeredBy: enemy, runsAutomaticTurns: false, in: &state)
        }
        let encounter = try XCTUnwrap(store.activeEncounter)
        let receipt = try XCTUnwrap(encounter.debugV2Armour)
        XCTAssertEqual(encounter.debugV2OwnedNodeIDs?[.binder],
                       [CombatDerivedStatsRules.Node.ironSkin,
                        CombatDerivedStatsRules.Node.bulwark])
        XCTAssertNotNil(receipt.entry(for: .binder))
        XCTAssertEqual(encounter.partyRanks[.binder], receipt.entry(for: .binder)?.entryRank)
        let before = try XCTUnwrap(CombatRules.v2IncomingDamage(
            25, by: .binder, in: store.state, run: try XCTUnwrap(store.activeRun),
            encounter: encounter))
        XCTAssertEqual(CombatRules.damageTaken(
            25, by: .binder, in: store.state, run: try XCTUnwrap(store.activeRun),
            encounter: encounter), before.finalDamage,
                       "preview and committed incoming-damage route must share one calculation")

        store.mutate("change mutable base after contact") { state in
            state.base.binderCharacter.stats.fortitude = 99
            state.base.binderCharacter.branchDepth["fortitude"] = 8
            state.base.binderEquipped[.armor] = EquippedPiece(catalogID: "guard_vault")
            state.base.binderCharacter.rank = state.base.binderCharacter.rank == .front ? .back : .front
            state.worlds.activeRun?.tuning.debugCombatV2BinderNodeIDs = []
        }
        let after = try XCTUnwrap(CombatRules.v2IncomingDamage(
            25, by: .binder, in: store.state, run: try XCTUnwrap(store.activeRun),
            encounter: try XCTUnwrap(store.activeEncounter)))
        XCTAssertEqual(after, before)

        store.flushNow()
        let relaunched = GameStore(io: io)
        XCTAssertEqual(relaunched.activeEncounter?.debugV2Armour, receipt)
        let reloaded = try XCTUnwrap(CombatRules.v2IncomingDamage(
            25, by: .binder, in: relaunched.state, run: try XCTUnwrap(relaunched.activeRun),
            encounter: try XCTUnwrap(relaunched.activeEncounter)))
        XCTAssertEqual(reloaded, before)
    }

    func testStaggerRollBoundaryAndAutomaticProducerSeam() throws {
        XCTAssertTrue(CombatRules.staggerSucceeds(roll: 0.299_999, automatic: false))
        XCTAssertFalse(CombatRules.staggerSucceeds(roll: 0.30, automatic: false))
        XCTAssertTrue(CombatRules.staggerSucceeds(roll: 1, automatic: true))

        let foeID = InstanceID(rawValue: 8_001)
        let stats = CombatStats(displayName: "Stoneback", icon: "circle", maxHP: 20, attack: 2)
        var encounter = EncounterState(
            id: InstanceID(rawValue: 8_000),
            foes: [.init(id: foeID, stats: stats, currentHP: 20)],
            order: [.binder, .foe(foeID)],
            debugV2OwnedNodeIDs: [.binder: []])
        var map = WorldMap(width: 1, height: 1, tiles: [Tile(isRevealed: true)],
                           entry: GridPoint(x: 0, y: 0))
        map[GridPoint(x: 0, y: 0)].content = .portal(isEntry: true)
        var run = WorldRun(runIndex: 1, book: BoundBook(written: [], essencePaid: 0),
                           mapSeed: 8, rng: SeededRNG(seed: 8), map: map,
                           playerPosition: GridPoint(x: 0, y: 0), binderHP: 20)
        CombatRules.attemptStagger(foeID: foeID, actor: .binder, automatic: true,
                                   run: &run, encounter: &encounter,
                                   sourceNodeID: CombatDerivedStatsRules.Node.breakingBlow)
        XCTAssertEqual(encounter.pendingStaggers[foeID]?.applyingRound, 2)
        XCTAssertEqual(encounter.pendingStaggers[foeID]?.sourceNodeIDs,
                       [CombatDerivedStatsRules.Node.breakingBlow])
        XCTAssertTrue(encounter.pendingStaggers[foeID]?.automatic == true)
        XCTAssertEqual(run.rng.drawCount, 0, "an automatic future producer consumes no Stagger roll")

        var noNode = encounter
        noNode.pendingStaggers = [:]
        noNode.debugV2OwnedNodeIDs = [.binder: []]
        let before = run.rng
        CombatRules.attemptStagger(foeID: foeID, actor: .binder, automatic: false,
                                   run: &run, encounter: &noNode)
        XCTAssertEqual(run.rng, before, "enabled-empty ownership consumes no Stagger RNG")
        XCTAssertTrue(noNode.pendingStaggers.isEmpty)
    }

    func testStaggerMovesEveryFoeSlotOneLivingPositionWithoutGatheringBurst() throws {
        let delayed = InstanceID(rawValue: 8_101)
        let next = InstanceID(rawValue: 8_102)
        let stats = CombatStats(displayName: "Ram", icon: "circle", maxHP: 20, attack: 2)
        var encounter = EncounterState(
            id: InstanceID(rawValue: 8_100),
            foes: [.init(id: delayed, stats: stats, currentHP: 20),
                   .init(id: next, stats: .init(displayName: "Moth", icon: "circle", maxHP: 20, attack: 2),
                         currentHP: 20)],
            order: [.binder, .foe(delayed), .companion(0), .foe(next)],
            turnSlots: [
                .init(actor: .binder),
                .init(actor: .foe(delayed)),
                .init(actor: .companion(0)),
                .init(actor: .foe(delayed), kind: .apexFollowUp(2), strengthMultiplier: 0.6,
                      suppressesAfflictions: true),
                .init(actor: .foe(next))
            ],
            debugV2OwnedNodeIDs: [.binder: [CombatDerivedStatsRules.Node.stagger]])
        encounter.pendingStaggers[delayed] = .init(
            foeID: delayed, applyingRound: 2, sourceActors: [.binder],
            sourceNodeIDs: [CombatDerivedStatsRules.Node.stagger], automatic: false)
        var map = WorldMap(width: 1, height: 1, tiles: [Tile(isRevealed: true)],
                           entry: GridPoint(x: 0, y: 0))
        map[GridPoint(x: 0, y: 0)].content = .portal(isEntry: true)
        let run = WorldRun(runIndex: 1, book: BoundBook(written: [], essencePaid: 0),
                           mapSeed: 9, rng: SeededRNG(seed: 9), map: map,
                           playerPosition: GridPoint(x: 0, y: 0), binderHP: 20,
                           companionHP: [0: 20])
        CombatRules.applyPendingStaggers(for: 2, run: run, encounter: &encounter)
        let actors = encounter.turnSlots.map(\.actor)
        XCTAssertEqual(actors, [.binder, .companion(0), .foe(delayed), .foe(next), .foe(delayed)])
        XCTAssertEqual(encounter.turnSlots.filter { $0.actor == .foe(delayed) }.count, 2,
                       "primary and follow-up are preserved without being gathered into a burst")
        XCTAssertEqual(encounter.turnSlots.last?.kind, .apexFollowUp(2))
        XCTAssertEqual(encounter.turnSlots.last?.strengthMultiplier, 0.6)
        XCTAssertTrue(encounter.turnSlots.last?.suppressesAfflictions == true)
        XCTAssertNil(encounter.pendingStaggers[delayed])
        XCTAssertEqual(encounter.log.filter { $0 == "Ram falls one place later." }.count, 1)
    }

    func testStaggerAlreadyLastConsumesWithTruthfulFeedback() {
        let foeID = InstanceID(rawValue: 8_151)
        let stats = CombatStats(displayName: "Last hound", icon: "circle", maxHP: 20, attack: 2)
        var encounter = EncounterState(
            id: InstanceID(rawValue: 8_150),
            foes: [.init(id: foeID, stats: stats, currentHP: 20)],
            order: [.binder, .foe(foeID)],
            turnSlots: [.init(actor: .binder), .init(actor: .foe(foeID)),
                        .init(actor: .foe(foeID), kind: .ordinaryPressureFollowUp(1),
                              strengthMultiplier: 0.55, suppressesAfflictions: true)])
        encounter.pendingStaggers[foeID] = .init(
            foeID: foeID, applyingRound: 2, sourceActors: [.binder],
            sourceNodeIDs: [CombatDerivedStatsRules.Node.stagger], automatic: false)
        var map = WorldMap(width: 1, height: 1, tiles: [Tile(isRevealed: true)],
                           entry: GridPoint(x: 0, y: 0))
        map[GridPoint(x: 0, y: 0)].content = .portal(isEntry: true)
        let run = WorldRun(runIndex: 1, book: BoundBook(written: [], essencePaid: 0),
                           mapSeed: 9, rng: SeededRNG(seed: 9), map: map,
                           playerPosition: GridPoint(x: 0, y: 0), binderHP: 20)
        CombatRules.applyPendingStaggers(for: 2, run: run, encounter: &encounter)
        XCTAssertNil(encounter.pendingStaggers[foeID])
        XCTAssertEqual(encounter.turnSlots.map(\.actor), [.binder, .foe(foeID), .foe(foeID)],
                       "adjacent slots from the same foe do not count as a delayed opening")
        XCTAssertTrue(encounter.log.contains("Last hound has no later opening."))
    }

    func testStaggerReceiptMergesWithoutPushingRoundAndSurvivesRelaunch() throws {
        let foeID = InstanceID(rawValue: 8_201)
        let stats = CombatStats(displayName: "Hound", icon: "circle", maxHP: 20, attack: 2)
        var encounter = EncounterState(
            id: InstanceID(rawValue: 8_200), foes: [.init(id: foeID, stats: stats, currentHP: 20)],
            order: [.binder, .foe(foeID)],
            debugV2OwnedNodeIDs: [.binder: [CombatDerivedStatsRules.Node.stagger],
                                  .companion(0): [CombatDerivedStatsRules.Node.stagger]])
        var map = WorldMap(width: 1, height: 1, tiles: [Tile(isRevealed: true)],
                           entry: GridPoint(x: 0, y: 0))
        map[GridPoint(x: 0, y: 0)].content = .portal(isEntry: true)
        var run = WorldRun(runIndex: 1, book: BoundBook(written: [], essencePaid: 0),
                           mapSeed: 10, rng: SeededRNG(seed: 10), map: map,
                           playerPosition: GridPoint(x: 0, y: 0), binderHP: 20)
        CombatRules.attemptStagger(foeID: foeID, actor: .binder, automatic: true,
                                   run: &run, encounter: &encounter,
                                   sourceNodeID: CombatDerivedStatsRules.Node.breakingBlow)
        CombatRules.attemptStagger(foeID: foeID, actor: .companion(0), automatic: true,
                                   run: &run, encounter: &encounter,
                                   sourceNodeID: CombatDerivedStatsRules.Node.breakingBlow)
        let pending = try XCTUnwrap(encounter.pendingStaggers[foeID])
        XCTAssertEqual(pending.applyingRound, 2)
        XCTAssertEqual(pending.sourceActors, [.binder, .companion(0)])
        XCTAssertEqual(encounter.log.filter { $0.contains("loses footing") }.count, 1)
        let resumed = try JSONDecoder().decode(EncounterState.self,
                                                from: JSONEncoder().encode(encounter))
        XCTAssertEqual(resumed.pendingStaggers, encounter.pendingStaggers)
        XCTAssertEqual(resumed.staggerAttempts, encounter.staggerAttempts)
        XCTAssertEqual(resumed.debugV2OwnedNodeIDs, encounter.debugV2OwnedNodeIDs)
    }

    func testProductionAttackCreatesStaggerOnlyForSurvivingCrushHit() throws {
        func staged(kind: DamageKind, hp: Int, seed: UInt64) -> (GameState, InstanceID) {
            var state = GameState.newGame()
            state.base.binderEquipped[.weapon] = EquippedPiece(
                catalogID: kind == .crush ? "field_maul" : "blade_keen")
            let foeID = InstanceID(rawValue: seed + 9_000)
            var stats = CombatStats(displayName: "Target", icon: "circle", maxHP: max(1, hp), attack: 1)
            stats.evasion = 0; stats.armour = 0
            let encounter = EncounterState(
                id: InstanceID(rawValue: seed),
                foes: [.init(id: foeID, stats: stats, currentHP: hp)],
                order: [.binder, .foe(foeID)],
                debugV2OwnedNodeIDs: [.binder: [CombatDerivedStatsRules.Node.stagger]],
                partyRanks: [.binder: .front])
            var map = WorldMap(width: 1, height: 1, tiles: [Tile(isRevealed: true)],
                               entry: GridPoint(x: 0, y: 0))
            map[GridPoint(x: 0, y: 0)].content = .portal(isEntry: true)
            var run = WorldRun(runIndex: 1, book: BoundBook(written: [], essencePaid: 0),
                               mapSeed: seed, rng: SeededRNG(seed: seed), map: map,
                               playerPosition: GridPoint(x: 0, y: 0), binderHP: 20)
            run.activeEncounter = encounter
            state.worlds.activeRun = run
            return (state, foeID)
        }

        var successSeed: UInt64 = 1
        while true {
            var probe = SeededRNG(seed: successSeed)
            _ = probe.int(in: -2...2)
            if probe.double(in: 0...1) < 0.30 { break }
            successSeed += 1
        }
        var (crush, crushID) = staged(kind: .crush, hp: 500, seed: successSeed)
        CombatRules.perform(.attack(foe: crushID), by: .binder, in: &crush)
        let landed = try XCTUnwrap(crush.worlds.activeRun?.activeEncounter)
        XCTAssertNotNil(landed.pendingStaggers[crushID])
        XCTAssertEqual(crush.worlds.activeRun?.rng.drawCount, 2,
                       "one damage roll plus exactly one eligible Stagger roll")

        var (pierce, pierceID) = staged(kind: .pierce, hp: 500, seed: 77)
        CombatRules.perform(.attack(foe: pierceID), by: .binder, in: &pierce)
        XCTAssertNil(pierce.worlds.activeRun?.activeEncounter?.pendingStaggers[pierceID])
        XCTAssertEqual(pierce.worlds.activeRun?.rng.drawCount, 1,
                       "non-Crush landed hit consumes only its damage roll")

        var (lethal, lethalID) = staged(kind: .crush, hp: 1, seed: 78)
        CombatRules.perform(.attack(foe: lethalID), by: .binder, in: &lethal)
        XCTAssertNil(lethal.worlds.activeRun?.activeEncounter?.pendingStaggers[lethalID])
        XCTAssertTrue(lethal.worlds.activeRun?.activeEncounter?.staggerAttempts.isEmpty == true,
                      "a defeating blow records no Stagger attempt before victory reward RNG")
    }

    func testRealZeroTurnAmbushSchedulesStaggerNextRoundWithoutMovingCursor() throws {
        let store = inFight()
        let foeID = try XCTUnwrap(store.activeEncounter?.foes.first?.id)
        var seed: UInt64 = 1
        while true {
            var probe = SeededRNG(seed: seed)
            _ = probe.int(in: -2...2)
            if probe.double(in: 0...1) < 0.30 { break }
            seed += 1
        }
        store.mutate("stage zero-turn Ambush Stagger") { state in
            state.base.binderEquipped[.weapon] = EquippedPiece(catalogID: "field_maul")
            guard var run = state.worlds.activeRun, var encounter = run.activeEncounter else { return }
            run.rng = SeededRNG(seed: seed)
            encounter.order = [.binder, .foe(foeID)]
            encounter.turnSlots = encounter.order.map { .init(actor: $0) }
            encounter.turnIndex = 0
            encounter.roundNumber = 1
            encounter.opening = .init(preContactDisclosed: true, initial: .partyApproach,
                                      slipperyProbability: nil, slipperyRoll: nil,
                                      slipperyPrevented: false, watchfulSuppressedOpening: false,
                                      resolved: .partyApproach, pendingFoeActions: [])
            encounter.debugV2OwnedNodeIDs = [.binder: [CombatDerivedStatsRules.Node.stagger]]
            run.activeEncounter = encounter
            state.worlds.activeRun = run
            CombatRules.perform(.skill("ambush", foe: foeID),
                                by: .binder, in: &state)
        }
        let encounter = try XCTUnwrap(store.activeEncounter)
        XCTAssertEqual(encounter.pendingStaggers[foeID]?.applyingRound, 2)
        XCTAssertEqual(encounter.roundNumber, 1)
        XCTAssertEqual(encounter.turnIndex, 0, "zero-turn Ambush retains the current ordinary slot")
    }

    func testMultiplePendingStaggersProcessDescendingWithoutDuplicateSlots() {
        let a = InstanceID(rawValue: 9_201), b = InstanceID(rawValue: 9_202)
        let stats = CombatStats(displayName: "Foe", icon: "circle", maxHP: 20, attack: 2)
        var encounter = EncounterState(
            id: InstanceID(rawValue: 9_200),
            foes: [.init(id: a, stats: stats, currentHP: 20),
                   .init(id: b, stats: stats, currentHP: 20)],
            order: [.binder, .foe(a), .foe(b), .companion(0)],
            turnSlots: [.init(actor: .binder), .init(actor: .foe(a)), .init(actor: .foe(b)),
                        .init(actor: .companion(0)),
                        .init(actor: .foe(a), kind: .ordinaryPressureFollowUp(1),
                              strengthMultiplier: 0.55, suppressesAfflictions: true)])
        for id in [a, b] {
            encounter.pendingStaggers[id] = .init(
                foeID: id, applyingRound: 2, sourceActors: [.binder],
                sourceNodeIDs: [CombatDerivedStatsRules.Node.stagger], automatic: false)
        }
        var map = WorldMap(width: 1, height: 1, tiles: [Tile(isRevealed: true)],
                           entry: GridPoint(x: 0, y: 0))
        map[GridPoint(x: 0, y: 0)].content = .portal(isEntry: true)
        let run = WorldRun(runIndex: 1, book: BoundBook(written: [], essencePaid: 0),
                           mapSeed: 92, rng: SeededRNG(seed: 92), map: map,
                           playerPosition: GridPoint(x: 0, y: 0), binderHP: 20,
                           companionHP: [0: 20])
        let before = encounter.turnSlots
        CombatRules.applyPendingStaggers(for: 2, run: run, encounter: &encounter)
        XCTAssertEqual(encounter.turnSlots.count, before.count)
        XCTAssertEqual(encounter.turnSlots.map(\.actor),
                       [.binder, .companion(0), .foe(a), .foe(b), .foe(a)],
                       "pending foes process by descending primary position and each slot crosses at most one other actor")
        XCTAssertEqual(encounter.turnSlots.last?.kind, .ordinaryPressureFollowUp(1))
        XCTAssertEqual(encounter.turnSlots.last?.strengthMultiplier, 0.55)
        XCTAssertEqual(encounter.turnSlots.last?.suppressesAfflictions, true,
                       "the final A slot keeps its exact pressure-follow-up payload")
        XCTAssertTrue(encounter.pendingStaggers.isEmpty)
        XCTAssertEqual(encounter.turnSlots.map(\.kind).map(String.init(describing:)).sorted(),
                       before.map(\.kind).map(String.init(describing:)).sorted(),
                       "saved payload kinds remain present without duplicate scheduling")
    }
}
