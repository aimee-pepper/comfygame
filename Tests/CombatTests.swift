import SwiftUI
import UIKit
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
    static let useSkill = GambitRule(id: InstanceID(rawValue: 111),
                                     subject: "subject_foe_any", action: "act_skill")


    /// **Skills come from the trees now**, so a test about *what a skill does* has to buy it first.
    /// Everything, at full depth: these tests are about behaviour, not about unlocking.
    private static func learnEverything(_ state: inout GameState) {
        let owned = Set(ContentCatalog.shared.combatGraph.nodes
            .filter { $0.depth <= CombatGraphRules.openingMaximumDepth && $0.techniqueID != nil }
            .map(\.id))
        // **Depths only, not levels.** Foes scale to the party's level (session 17 §3), so raising
        // it here would quietly turn every stat test into a test about levelling.
        state.base.binderCharacter.ownedCombatNodeIDs = owned
        for index in state.base.roster.indices {
            state.base.roster[index].character.ownedCombatNodeIDs = owned
        }
    }

    private func inFight(_ creatures: [CreatureID] = ["paper_moth"],
                         gambits: [GambitRule]? = nil) -> GameStore {
        let store = GameStore(io: .temporary(name: "combat-\(UUID().uuidString)"))
        store.mutate("test: everything learned") { Self.learnEverything(&$0) }
        store.write("plains")
        XCTAssertTrue(store.bindAndDepart(), store.bindError ?? "bind failed without a reason")
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

    private func renderedRGBA(_ image: UIImage, x: Int, y: Int) throws -> [UInt8] {
        let cg = try XCTUnwrap(image.cgImage)
        let data = try XCTUnwrap(cg.dataProvider?.data)
        let bytes = CFDataGetBytePtr(data)!
        let offset = y * cg.bytesPerRow + x * 4
        return Array(UnsafeBufferPointer(start: bytes + offset, count: 4))
    }

    // MARK: Structure

    func testEncounterSafeSpaceBackdropAndBattleLogOwnFormerSpacerRemainder() throws {
        EncounterSafeSpaceMeasurement.isArmed = true
        defer { EncounterSafeSpaceMeasurement.isArmed = false }
        let store = GameStore(io: .temporary(name: "encounter-safe-space-\(UUID().uuidString)"))
        store.mutate("safe-space encounter fixture", flush: true) { state in
            let point = GridPoint(x: 0, y: 0)
            var map = WorldMap(width: 1, height: 1, tiles: [Tile(isRevealed: true)], entry: point)
            map[point].content = .portal(isEntry: true)
            var run = WorldRun(runIndex: 1, book: BoundBook(written: [], essencePaid: 0),
                               mapSeed: 1, rng: SeededRNG(seed: 1), map: map,
                               playerPosition: point)
            var rng = SeededRNG(seed: 2)
            let stats = CombatStats(displayName: "Paper Moth", icon: "ant",
                                    maxHP: 12, attack: 2)
            let foe = FoeState(id: InstanceID(rawValue: 9), stats: stats, currentHP: 12)
            run.activeEncounter = CombatRules.makeEncounter(
                id: InstanceID(rawValue: 10), foes: [foe], party: [.binder], rng: &rng)
            run.activeEncounter?.log = [
                "First event.", "Second event.", "Third event.", "Latest event."
            ]
            state.worlds.activeRun = run
        }
        XCTAssertNotNil(store.activeEncounter)

        func mount(_ name: String) throws {
            let frozen = try SaveCodec.encode(store.state)
            let controller = UIHostingController(rootView:
                EncounterView().environmentObject(store))
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 368, height: 800))
            window.rootViewController = controller
            controller.additionalSafeAreaInsets = UIEdgeInsets(top: 59, left: 0,
                                                                bottom: 34, right: 0)
            window.makeKeyAndVisible()
            controller.view.frame = window.bounds
            controller.view.layoutIfNeeded()
            RunLoop.main.run(until: Date().addingTimeInterval(0.08))

            let safe = controller.view.safeAreaInsets
            let header = EncounterSafeSpaceMeasurement.headerFrame
            let log = EncounterSafeSpaceMeasurement.battleLogFrame
            let action = EncounterSafeSpaceMeasurement.actionFrame
            XCTAssertEqual(header.minY, safe.top, accuracy: 0.75)
            XCTAssertGreaterThan(log.height, 62,
                                 "the battle log must own the former flexible spacer remainder")
            XCTAssertEqual(log.maxY, action.minY, accuracy: 0.75,
                           "no unowned spacer may remain above the action/outcome rail")
            XCTAssertEqual(action.maxY, 800 - safe.bottom, accuracy: 0.75)
            XCTAssertEqual(try SaveCodec.encode(store.state), frozen)

            let image = UIGraphicsImageRenderer(size: window.bounds.size).image { _ in
                controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
            }
            XCTAssertNotEqual(try renderedRGBA(image, x: 184, y: 10), [0, 0, 0, 255])
            XCTAssertNotEqual(try renderedRGBA(image, x: 184, y: 785), [0, 0, 0, 255])
            let attachment = XCTAttachment(image: image)
            attachment.name = "encounter-safe-space-\(name)-368x800"
            attachment.lifetime = .keepAlways
            add(attachment)
            window.isHidden = true
        }

        try mount("in-progress")
        store.mutate("safe-space completed branch", flush: true) {
            $0.worlds.activeRun?.activeEncounter?.outcome = .victory
        }
        try mount("completed")
#if DEBUG
        store.mutate("safe-space debug branch", flush: true) {
            $0.worlds.activeRun?.activeEncounter?.outcome = nil
            $0.worlds.activeRun?.activeEncounter?.debugGodMode = .init()
        }
        try mount("debug")
#endif
    }

    func testEncounterSafeSpaceSourcePreservesLogOrderAndRemovesOnlyTopLevelSpacer() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent()
        let source = try String(contentsOf: root.appending(path: "Sources/Screens/EncounterView.swift"),
                                encoding: .utf8)
        XCTAssertTrue(source.contains(".background(Color(.systemGroupedBackground).ignoresSafeArea())"))
        XCTAssertTrue(source.contains("encounter.log.suffix(3).enumerated()"))
        XCTAssertTrue(source.contains("minHeight: 62, maxHeight: .infinity"))
        let bodyStart = try XCTUnwrap(source.range(of: "var body: some View"))
        let bodyEnd = try XCTUnwrap(source.range(of: "// MARK: Header",
                                                 range: bodyStart.upperBound..<source.endIndex))
        XCTAssertFalse(source[bodyStart.lowerBound..<bodyEnd.lowerBound]
            .contains("Spacer(minLength: 0)"))
    }

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
            state.base.binderCharacter.ownedCombatNodeIDs.formUnion(legacyCombatNodes(["shadow": 0]))
            for index in state.base.roster.indices { state.base.roster[index].character.ownedCombatNodeIDs.formUnion(legacyCombatNodes(["shadow": 0])) }
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

    func testSkillRowUsesTheSameActorAdjustedPowerAndCooldownAsCommit() throws {
        let skill = try XCTUnwrap(ContentCatalog.shared.skill("unbind"))
        var ordinaryState = GameState.newGame()
        var sharpState = ordinaryState
        sharpState.base.binderCharacter.stats.wit = Tuning.Character.startingStat
            + Tuning.Character.witPerCooldownRound * 2
        let encounter = EncounterState(id: InstanceID(rawValue: 43_001), foes: [], order: [.binder])

        let ordinary = CombatSkillRowPresentation.make(skill: skill, actor: .binder,
                                                       encounter: encounter, state: ordinaryState)
        let sharp = CombatSkillRowPresentation.make(skill: skill, actor: .binder,
                                                    encounter: encounter, state: sharpState)

        XCTAssertEqual(ordinary.potency,
                       CharacterRules.skillPower(skill.power, ordinaryState.base.binderCharacter.stats))
        XCTAssertEqual(sharp.potency,
                       CharacterRules.skillPower(skill.power, sharpState.base.binderCharacter.stats))
        XCTAssertEqual(ordinary.cooldownDuration,
                       CharacterRules.cooldown(skill.cooldownRounds,
                                               ordinaryState.base.binderCharacter.stats))
        XCTAssertEqual(sharp.cooldownDuration,
                       CharacterRules.cooldown(skill.cooldownRounds,
                                               sharpState.base.binderCharacter.stats))
        XCTAssertGreaterThan(sharp.potency ?? 0, ordinary.potency ?? 0)
        XCTAssertLessThan(sharp.cooldownDuration, ordinary.cooldownDuration)
        XCTAssertEqual(sharp.cooldownText, "Ready · \(sharp.cooldownDuration)-round cooldown")
    }

    func testSkillRowDistinguishesSavedRemainingCooldownFromMintedDurationAndLabelsBoth() throws {
        let skill = try XCTUnwrap(ContentCatalog.shared.skill("unbind"))
        let state = GameState.newGame()
        var encounter = EncounterState(id: InstanceID(rawValue: 43_002), foes: [], order: [.binder])
        encounter.cooldowns[CombatRules.cooldownKey(skill, for: .binder)] = 1

        let row = CombatSkillRowPresentation.make(skill: skill, actor: .binder,
                                                  encounter: encounter, state: state)

        XCTAssertEqual(row.remainingCooldown, 1)
        XCTAssertEqual(row.cooldownText, "Ready in 1 round")
        XCTAssertTrue(row.accessibilityValue.contains("Potency \(try XCTUnwrap(row.potency))"))
        XCTAssertTrue(row.accessibilityValue.contains("Ready in 1 round"))
        XCTAssertTrue(CombatSkillRowPresentation.footerText.contains("Potency and cooldown"))
        XCTAssertFalse(CombatSkillRowPresentation.footerText.contains("A number on the right"))
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

    /// Duration-shaped compatibility tests are about the legacy contract, not whichever DEBUG-v2
    /// comparison the simulator last persisted. Freeze that authority explicitly at their edge.
    private func freezeLegacyCombat(in store: GameStore) {
        store.mutate("test: freeze legacy combat authority") { state in
            state.worlds.activeRun?.activeEncounter?.debugV2OwnedNodeIDs = nil
            state.worlds.activeRun?.activeEncounter?.wardReceipts = nil
            state.worlds.activeRun?.activeEncounter?.snuffReceipts = nil
            state.worlds.activeRun?.activeEncounter?.interposeReceipts = nil
            state.worlds.activeRun?.activeEncounter?.drawOffReceipts = nil
            state.worlds.activeRun?.activeEncounter?.braceReceipts = nil
            state.worlds.activeRun?.activeEncounter?.partyRanks = [:]
            state.worlds.activeRun?.activeEncounter?.debugV2BinderAttack = nil
            state.worlds.activeRun?.activeEncounter?.debugV2Initiative = nil
            state.worlds.activeRun?.activeEncounter?.debugV2Armour = nil
            state.worlds.activeRun?.activeEncounter?.debugV2Evasion = nil
            state.worlds.activeRun?.activeEncounter?.debugV2Resistance = nil
        }
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
        XCTAssertTrue(encounter.afflictions?.contains { $0.kind == .bleed && $0.target.isParty } == true
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

        XCTAssertTrue(store.activeEncounter?.afflictions?.contains {
            $0.kind == .bleed && $0.target == .foe(foe.id)
        } == true || foes(store).first?.isAlive == false,
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
            store.mutate("test: exact Flense owner") {
                $0.worlds.activeRun?.activeEncounter?.debugV2OwnedNodeIDs?[.companion(0)] = [
                    CombatDerivedStatsRules.Node.flense
                ]
            }
            giveTheTurnTo(.companion(0), in: store)
            store.mutate("test: use it") { CombatRules.perform(.skill("flense", foe: foeID), by: .companion(0), in: &$0) }
            return store.activeEncounter?.afflictions?.first {
                $0.target == .foe(foeID) && $0.kind == .bleed
            }?.damage ?? 0
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
            freezeLegacyCombat(in: store)
            store.mutate("test: stand and take it") { state in
                guard var run = state.worlds.activeRun, var encounter = run.activeEncounter else { return }
                // Ward is the variable under test; the all-nodes fixture also owns Ghost.
                encounter.ghostEvasionAvailable = []
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
        freezeLegacyCombat(in: store)
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
        XCTAssertTrue(CombatRules.afflictions(on: .binder,
                                              in: try XCTUnwrap(store.activeEncounter)).isEmpty)
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
                XCTAssertTrue(store.activeEncounter?.afflictions?.contains {
                    $0.target == .foe(foeID) && $0.kind == .bleed
                } == true)
            } else {
                let kind: AfflictionID = expected == .poison ? .poison : (expected == .burn ? .burn : .dazzle)
                XCTAssertTrue(store.activeEncounter?.afflictions?.contains {
                    $0.target == .foe(foeID) && $0.kind == kind
                } == true)
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
            var carried: [AfflictionInstance] = []
            for _ in 0..<12 {
                forceTheFoeToStrike(in: store)
                carried = store.activeEncounter?.afflictions ?? []
                if carried.contains(where: { $0.kind == StatusKind.from(element).afflictionID }) { break }
            }
            XCTAssertTrue(carried.contains { $0.kind == StatusKind.from(element).afflictionID },
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
        freezeLegacyCombat(in: store)
        let foeID = try XCTUnwrap(store.activeEncounter?.foes.first).id
        giveTheTurnTo(.companion(0), in: store)
        store.mutate("test: snuff it") { CombatRules.perform(.skill("snuff", foe: foeID), by: .companion(0), in: &$0) }
        forceTheFoeToStrike(in: store)

        let carried = store.activeEncounter?.afflictions ?? []
        XCTAssertFalse(carried.contains { $0.kind == .burn },
                       "snuffed it and it still set somebody on fire")
    }

    /// **Steady clears them.** Otherwise a status is a tax rather than a problem with an answer.
    func testSteadyClearsWhatIsStillWorking() throws {
        let store = inFightWith([armoured()])
        freezeLegacyCombat(in: store)
        store.mutate("test: poisoned") { state in
            guard var encounter = state.worlds.activeRun?.activeEncounter else { return }
            _ = CombatRules.applyAffliction(.poison, to: .binder, source: nil,
                                            provenance: .environment, damage: 2, ticks: 4,
                                            targetIsStanding: true, encounter: &encounter)
            state.worlds.activeRun?.activeEncounter = encounter
        }
        giveTheTurnTo(.companion(0), in: store)
        store.mutate("test: steady") { CombatRules.perform(.skill("steady", ally: .binder), by: .companion(0), in: &$0) }
        XCTAssertTrue(CombatRules.afflictions(on: .binder,
                                              in: try XCTUnwrap(store.activeEncounter)).isEmpty,
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
        freezeLegacyCombat(in: store)
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
        freezeLegacyCombat(in: store)
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
            // This fixture isolates Ground; `learnEverything` also owns Ghost, whose now-correct
            // one-use receipt would otherwise consume the redirected direct attack first.
            $0.worlds.activeRun?.activeEncounter?.ghostEvasionAvailable = []
            CombatRules.perform(.skill("ground"), by: .companion(0), in: &$0)
            CombatRules.runAutomaticTurns(in: &$0)
        }

        XCTAssertEqual(store.activeRun?.binderHP, binderBefore, "the protected target still took the event")
        XCTAssertLessThan(store.activeRun?.companionHP[0] ?? asheBefore, asheBefore,
                          "Ashe did not receive the redirected damage")
        XCTAssertNil(store.activeEncounter?.grounding[.companion(0)], "Ground caught more than one event")
        XCTAssertTrue(store.activeEncounter?.afflictions?.contains {
            $0.target == .companion(0) && $0.kind == .burn
        } == true,
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
            freezeLegacyCombat(in: store)
            let binderBefore = store.state.worlds.activeRun?.binderHP ?? 0
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
            if hp < binderBefore { hitTheBack += 1 }
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
        XCTAssertTrue(store.activeEncounter?.afflictions?.contains {
            $0.target == .foe(foeID) && $0.kind == .bleed
        } == true,
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
        for _ in 0..<12 where store.activeEncounter?.afflictions?.contains(where: {
            $0.target == .foe(foeID) && $0.kind == .bleed
        }) != true {
            giveTheTurnTo(.binder, in: store)
            store.mutate("test: strike with barbed edge") {
                CombatRules.perform(.attack(foe: foeID), by: .binder, in: &$0)
            }
        }
        XCTAssertTrue(store.activeEncounter?.afflictions?.contains {
            $0.target == .foe(foeID) && $0.kind == .bleed
        } == true)
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
        let expectedNames = Set(store.state.base.activeParty.compactMap {
            store.state.base.rosterIndex(for: $0).map { store.state.base.roster[$0].name }
        })
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
                names: state.base.activeParty.reduce(into: [PersistentPartyMemberID: String]()) {
                    if let index = state.base.rosterIndex(for: $1) {
                        $0[$1] = state.base.roster[index].name
                    }
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
        state.base.binderCharacter.ownedCombatNodeIDs.formUnion(legacyCombatNodes(["fortitude": 1]))
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

    func testCarriedRemediesChooseOneCompactItemBeforeListingRecipients() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf: root.appendingPathComponent("Sources/Screens/EncounterView.swift"),
                                encoding: .utf8)
        let sheetStart = try XCTUnwrap(source.range(of: "private struct CombatItemSheet"))
        let sheet = String(source[sheetStart.lowerBound...])

        XCTAssertTrue(sheet.contains("SixAcrossItemGrid(data: store.usableItems"))
        XCTAssertTrue(sheet.contains("selectedStackID = stack.id"))
        XCTAssertTrue(sheet.contains(".safeAreaInset(edge: .bottom, spacing: 0) { selectedRemedyActionBar }"))
        XCTAssertTrue(sheet.contains("PersistentActionBar(message: itemEffect(item))"))
        XCTAssertTrue(sheet.contains("Label(\"Use on…\", systemImage: \"person.crop.circle.badge.checkmark\")"))
        XCTAssertTrue(sheet.contains("beginUse(stack, on: ally)"))
        XCTAssertFalse(sheet.contains("ForEach(store.usableItems) { stack in\n                    if let item"),
                       "remedies must not duplicate a full recipient list beneath every item")
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
                var encounter = CombatRules.makeEncounter(
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
                encounter.order = [.binder, .foe(foeID)]
                encounter.turnSlots = encounter.order.map { .init(actor: $0) }
                encounter.turnIndex = 0
                run.activeEncounter = encounter
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
                    var encounter = CombatRules.makeEncounter(
                        id: InstanceID(rawValue: 3),
                        foes: [FoeState(id: foeID, traits: traits, stats: stats, currentHP: stats.maxHP)],
                        party: [.binder],
                        debugV2BinderAttack: .init(
                            ordinaryWeaponKind: ordinaryKind,
                            crushBonus: CombatDerivedStatsRules.preMatchupAttackBonus(
                                ownedNodeIDs: nodes, weaponDamageKind: .crush),
                            pierceBonus: CombatDerivedStatsRules.preMatchupAttackBonus(
                                ownedNodeIDs: nodes, weaponDamageKind: .pierce)), rng: &orderRNG)
                    encounter.order = [.binder, .foe(foeID)]
                    encounter.turnSlots = encounter.order.map { .init(actor: $0) }
                    encounter.turnIndex = 0
                    run.activeEncounter = encounter
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
        state.base.binderCharacter.ownedCombatNodeIDs.formUnion(legacyCombatNodes(["fortitude": 3]))
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
            state.base.binderCharacter.ownedCombatNodeIDs.formUnion(legacyCombatNodes(["fortitude": 8]))
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

    func testOrdinaryStableOpeningOwnershipFreezesExistingConsumersWithoutDebugTuning() throws {
        let io = SaveFileIO.temporary(name: "opening-stable-consumers-\(UUID().uuidString)")
        defer { io.deleteEverything() }
        let store = GameStore(io: io)
        store.write("plains")
        let heavy = CombatDerivedStatsRules.Node.heavyHand
        let iron = CombatDerivedStatsRules.Node.ironSkin
        let thick = CombatDerivedStatsRules.Node.thickHide
        let held: CombatNodeID = "combat.offense.force.shatter"
        store.mutate("own ordinary opening nodes") { state in
            state.base.binderCharacter.ownedCombatNodeIDs = [heavy, iron, thick, held]
            state.base.binderEquipped[.weapon] = EquippedPiece(catalogID: "field_maul")
        }
        XCTAssertTrue(store.bindAndDepart())
        let cap = try XCTUnwrap(store.activeRun?.healthCap(for: .binder))
        XCTAssertEqual(cap.maximum, cap.ordinaryMaximum + 6)
        XCTAssertEqual(cap.components.map(\.nodeID), [thick])
        store.mutate("begin ordinary stable encounter") { state in
            guard var run = state.worlds.activeRun, let enemy = run.enemies.first else { return }
            run.tuning.debugCombatV2BinderAttackEnabled = false
            XCTAssertFalse(run.tuning.debugCombatV2BinderAttackEnabled)
            state.worlds.activeRun = run
            WorldRules.beginEncounter(triggeredBy: enemy, runsAutomaticTurns: false, in: &state)
        }
        let encounter = try XCTUnwrap(store.activeEncounter)
        XCTAssertEqual(encounter.debugV2OwnedNodeIDs?[.binder], [heavy, iron, thick])
        XCTAssertFalse(try XCTUnwrap(encounter.debugV2OwnedNodeIDs?[.binder]).contains(held))
        XCTAssertEqual(encounter.debugV2BinderAttack?.preMatchupBonus(for: .crush).total, 2)
        XCTAssertTrue(try XCTUnwrap(encounter.debugV2Armour?.entry(for: .binder))
            .ownedNodeIDs.contains(iron))
        store.flushNow()
        let relaunched = GameStore(io: io)
        XCTAssertEqual(relaunched.activeEncounter?.debugV2OwnedNodeIDs?[.binder], [heavy, iron, thick])
    }

    func testImmovableUsesFrozenExactOwnerArmourForPierceAndEmanationOnly() throws {
        let immovable = CombatDerivedStatsRules.Node.immovable
        let receipt = EncounterState.DebugV2ArmourReceipt(entries: [
            .init(actor: .binder, equipmentProtectivePower: 4, sturdiness: 1,
                  ownedNodeIDs: [immovable], entryRank: .back),
            .init(actor: .companion(0), equipmentProtectivePower: 4, sturdiness: 1,
                  ownedNodeIDs: [], entryRank: .back)
        ])
        let ranks: [Combatant: Rank] = [.binder: .back, .companion(0): .back]
        let conscious: Set<Combatant> = [.binder, .companion(0)]

        let binderPierce = CombatDerivedStatsRules.incomingDamage(
            raw: 20, receiver: .binder, receipt: receipt, ranks: ranks,
            conscious: conscious, armourIgnored: 0)
        let companionPierce = CombatDerivedStatsRules.incomingDamage(
            raw: 20, receiver: .companion(0), receipt: receipt, ranks: ranks,
            conscious: conscious, armourIgnored: Tuning.Encounter.pierceArmourIgnored)
        XCTAssertLessThan(binderPierce.finalDamage, companionPierce.finalDamage)

        let emanation = CombatDerivedStatsRules.emanationArmourDamage(
            raw: 20, receiver: .binder, receipt: receipt, ranks: ranks,
            conscious: conscious)
        XCTAssertEqual(emanation.raw, 20)
        XCTAssertEqual(emanation.finalDamage,
                       max(Tuning.Encounter.minimumDamage,
                           20 - emanation.breakdown.effectiveArmour),
                       "Immovable emanation uses armour but not physical back-rank protection")

        let zeroArmour = EncounterState.DebugV2ArmourReceipt(entries: [
            .init(actor: .binder, equipmentProtectivePower: 0, sturdiness: 1,
                  ownedNodeIDs: [immovable], entryRank: .front)
        ])
        XCTAssertEqual(CombatDerivedStatsRules.emanationArmourDamage(
            raw: 13, receiver: .binder, receipt: zeroArmour,
            ranks: [.binder: .front], conscious: [.binder]).finalDamage, 13)
        XCTAssertFalse(receipt.entry(for: .companion(0))!.ownedNodeIDs.contains(immovable),
                       "Immovable is exact-owner, never an aura")
    }

    func testImmovableEmanationArmourKeepsFormationDynamicAndFreezesAcrossRelaunch() throws {
        let io = SaveFileIO.temporary(name: "v2-immovable-\(UUID().uuidString)")
        defer { io.deleteEverything() }
        let store = GameStore(io: io)
        store.mutate("test: everything learned") { Self.learnEverything(&$0) }
        store.write("plains")
        XCTAssertTrue(store.bindAndDepart())
        store.mutate("stage fight") { state in
            guard var run = state.worlds.activeRun else { return }
            var rng = SeededRNG(seed: 55)
            run.activeEncounter = CombatRules.makeEncounter(
                id: InstanceID(rawValue: 55), foes: [], party: [.binder, .companion(0)],
                rng: &rng)
            state.worlds.activeRun = run
        }
        store.mutate("freeze Immovable") { state in
            guard var run = state.worlds.activeRun, var encounter = run.activeEncounter else { return }
            encounter.debugV2Armour = .init(entries: [
                .init(actor: .binder, equipmentProtectivePower: 2, sturdiness: 1,
                      ownedNodeIDs: [CombatDerivedStatsRules.Node.immovable], entryRank: .front),
                .init(actor: .companion(0), equipmentProtectivePower: 0, sturdiness: 1,
                      ownedNodeIDs: [CombatDerivedStatsRules.Node.shieldwall], entryRank: .front)
            ])
            encounter.partyRanks = [.binder: .front, .companion(0): .front]
            run.binderHP = 20
            run.companionHP[0] = 20
            run.activeEncounter = encounter
            state.worlds.activeRun = run
        }
        let before = try XCTUnwrap(CombatRules.v2EmanationArmourDamage(
            20, by: .binder, in: store.state, run: try XCTUnwrap(store.activeRun),
            encounter: try XCTUnwrap(store.activeEncounter)))
        store.mutate("move formation and alter Base") { state in
            state.worlds.activeRun?.activeEncounter?.partyRanks[.binder] = .back
            state.base.binderCharacter.stats.fortitude = 99
            state.worlds.activeRun?.tuning.debugCombatV2BinderNodeIDs = []
        }
        let moved = try XCTUnwrap(CombatRules.v2EmanationArmourDamage(
            20, by: .binder, in: store.state, run: try XCTUnwrap(store.activeRun),
            encounter: try XCTUnwrap(store.activeEncounter)))
        XCTAssertFalse(moved.breakdown.components.contains {
            $0.nodeID == CombatDerivedStatsRules.Node.shieldwall
        })
        XCTAssertEqual(moved.breakdown.equipment, before.breakdown.equipment)
        store.flushNow()
        let relaunched = GameStore(io: io)
        XCTAssertEqual(try XCTUnwrap(CombatRules.v2EmanationArmourDamage(
            20, by: .binder, in: relaunched.state, run: try XCTUnwrap(relaunched.activeRun),
            encounter: try XCTUnwrap(relaunched.activeEncounter))), moved)
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

    func testFootworkReceiptIsExactOwnerFrozenAndClampedWithoutAura() throws {
        var state = GameState.newGame()
        while state.base.roster.count < 4 { state.base.roster.append(CompanionState()) }
        state.base.activeParty = [0, 1, 2, 3]
        state.base.binderCharacter.stats.finesse = 100
        let party = CombatRules.party(of: state)
        let receipt = try XCTUnwrap(CombatDerivedStatsRules.debugEvasionReceipt(
            enabled: true, party: party, in: state,
            binderNodeIDs: [CombatDerivedStatsRules.Node.footwork],
            companionNodeIDs: [2: [CombatDerivedStatsRules.Node.footwork]]))
        XCTAssertEqual(receipt.entries.count, 5)
        XCTAssertEqual(receipt.entry(for: .binder)?.components.map(\.nodeID),
                       [CombatDerivedStatsRules.Node.footwork])
        XCTAssertEqual(receipt.entry(for: .companion(2))?.components.map(\.nodeID),
                       [CombatDerivedStatsRules.Node.footwork])
        XCTAssertTrue([0, 1, 3].allSatisfy {
            receipt.entry(for: .companion($0))?.components.isEmpty == true
        }, "Footwork is personal and cannot become a five-person aura")
        let frozenTotal = try XCTUnwrap(receipt.entry(for: .binder)?.total)
        XCTAssertEqual(frozenTotal, min(0.85,
            try XCTUnwrap(receipt.entry(for: .binder)?.characterEvasion) + 0.06))
        let clamped = EncounterState.DebugV2EvasionReceipt.Entry(
            actor: .binder, characterEvasion: 0.82,
            components: [.init(nodeID: CombatDerivedStatsRules.Node.footwork, amount: 0.06)])
        XCTAssertEqual(clamped.total, 0.85)

        state.base.binderCharacter.stats.finesse = 0
        let frozen = try XCTUnwrap(receipt.entry(for: .binder))
        XCTAssertEqual(frozen.total, frozenTotal, "post-contact Base edits cannot rewrite the receipt")
        XCTAssertNil(CombatDerivedStatsRules.debugEvasionReceipt(
            enabled: false, party: party, in: state,
            binderNodeIDs: [CombatDerivedStatsRules.Node.footwork], companionNodeIDs: [:]))
    }

    func testSidestepThenGhostThenProbabilityConsumeInExactOrder() throws {
        let state = GameState.newGame()
        var map = WorldMap(width: 1, height: 1, tiles: [Tile(isRevealed: true)],
                           entry: GridPoint(x: 0, y: 0))
        map[GridPoint(x: 0, y: 0)].content = .portal(isEntry: true)
        var run = WorldRun(runIndex: 1, book: BoundBook(written: [], essencePaid: 0),
                           mapSeed: 1, rng: SeededRNG(seed: 12), map: map,
                           playerPosition: .init(x: 0, y: 0), binderHP: 20)
        var encounter = EncounterState(id: .init(rawValue: 1), foes: [], order: [.binder],
            debugV2Evasion: .init(entries: [.init(actor: .binder, characterEvasion: 0,
                components: [.init(nodeID: CombatDerivedStatsRules.Node.footwork, amount: 0.06)])]),
            ghostEvasionAvailable: [.binder])
        encounter.dodging[.binder] = 1
        encounter.dodging[.companion(0)] = 1
        let before = run.rng.drawCount
        XCTAssertTrue(CombatRules.resolvePartyMiss(.binder, in: state, run: &run, encounter: &encounter))
        XCTAssertNil(encounter.dodging[.binder])
        XCTAssertEqual(encounter.evasionAttempts.last?.resolution, .sidestep)
        XCTAssertEqual(run.rng.drawCount, before)

        CombatRules.startNewRound(&encounter, run: run)
        XCTAssertEqual(encounter.dodging[.binder], nil,
                       "Sidestep was consumed by the attack, not expired by the round")
        XCTAssertEqual(encounter.dodging[.companion(0)], 1,
                       "an unused Sidestep persists across round transitions")
        XCTAssertTrue(CombatRules.resolvePartyMiss(.binder, in: state, run: &run, encounter: &encounter))
        XCTAssertEqual(encounter.evasionAttempts.last?.resolution, .ghost)
        XCTAssertEqual(encounter.ghostEvasionAvailable, [])
        XCTAssertEqual(run.rng.drawCount, before)

        _ = CombatRules.resolvePartyMiss(.binder, in: state, run: &run, encounter: &encounter)
        XCTAssertNotNil(encounter.evasionAttempts.last?.roll)
        XCTAssertEqual(run.rng.drawCount, before + 1)
    }

    func testLegacyGhostAdoptsOnceAndSpentReceiptDoesNotRemintAfterReload() throws {
        var state = GameState.newGame()
        Self.learnEverything(&state)
        var map = WorldMap(width: 1, height: 1, tiles: [Tile(isRevealed: true)],
                           entry: .init(x: 0, y: 0))
        map[.init(x: 0, y: 0)].content = .portal(isEntry: true)
        var run = WorldRun(runIndex: 1, book: BoundBook(written: [], essencePaid: 0), mapSeed: 1,
                           rng: SeededRNG(seed: 3), map: map, playerPosition: .init(x: 0, y: 0), binderHP: 20)
        var legacy = EncounterState(id: .init(rawValue: 2), foes: [], order: [.binder])
        XCTAssertNil(legacy.ghostEvasionAvailable)
        XCTAssertTrue(CombatRules.resolvePartyMiss(.binder, in: state, run: &run, encounter: &legacy))
        XCTAssertEqual(legacy.evasionAttempts.last?.resolution, .ghost)
        XCTAssertEqual(legacy.ghostEvasionAvailable, [])
        var resumed = try JSONDecoder().decode(EncounterState.self,
                                                from: JSONEncoder().encode(legacy))
        XCTAssertEqual(resumed.ghostEvasionAvailable, [])
        _ = CombatRules.resolvePartyMiss(.binder, in: state, run: &run, encounter: &resumed)
        XCTAssertNotEqual(resumed.evasionAttempts.last?.resolution, .ghost,
                          "modern spent-empty must never rederive Ghost from legacy ownership")
    }

    func testAreaAndMultiFoeAttacksDoNotConsumePersonalEvasionReceiptsOrRoll() throws {
        for delivery in [Delivery.area, .multi] {
            let store = inFight()
            store.mutate("stage \(delivery) exclusion") { state in
                guard var run = state.worlds.activeRun, var encounter = run.activeEncounter,
                      !encounter.foes.isEmpty else { return }
                encounter.foes[0].stats.delivery = delivery
                encounter.foes[0].stats.evasion = 0
                encounter.foes[0].stats.attack = 2
                encounter.order = [.foe(encounter.foes[0].id), .binder]
                encounter.turnSlots = encounter.order.map { .init(actor: $0) }
                encounter.turnIndex = 0
                encounter.debugV2Evasion = .init(entries: [.init(actor: .binder,
                    characterEvasion: 0.79,
                    components: [.init(nodeID: CombatDerivedStatsRules.Node.footwork, amount: 0.06)])])
                encounter.ghostEvasionAvailable = [.binder]
                encounter.dodging[.binder] = 1
                run.activeEncounter = encounter
                state.worlds.activeRun = run
                CombatRules.runAutomaticTurns(in: &state)
            }
            let encounter = try XCTUnwrap(store.activeEncounter)
            XCTAssertTrue(encounter.evasionAttempts.isEmpty, "\(delivery) must bypass personal evasion")
            XCTAssertEqual(encounter.dodging[.binder], 1)
            XCTAssertEqual(encounter.ghostEvasionAvailable, [.binder])
        }
    }

    func testRealSingleTargetFoeRouteUsesFootworkForMissAndHitAndMissSuppressesPayload() throws {
        func staged(seed: UInt64) -> GameStore {
            let store = inFight()
            store.mutate("stage direct Footwork route") { state in
                guard var run = state.worlds.activeRun, var encounter = run.activeEncounter,
                      !encounter.foes.isEmpty else { return }
                run.rng = SeededRNG(seed: seed)
                run.binderHP = 20
                run.companionHP[0] = 0
                encounter.foes[0].stats.delivery = .single
                encounter.foes[0].stats.element = .heat
                encounter.foes[0].stats.attack = 6
                encounter.order = [.foe(encounter.foes[0].id), .binder]
                encounter.turnSlots = encounter.order.map { .init(actor: $0) }
                encounter.turnIndex = 0
                encounter.debugV2Evasion = .init(entries: [.init(actor: .binder,
                    characterEvasion: 0.50,
                    components: [.init(nodeID: CombatDerivedStatsRules.Node.footwork, amount: 0.06)])])
                encounter.ghostEvasionAvailable = []
                encounter.dodging.removeAll()
                encounter.afflictions = []
                run.activeEncounter = encounter
                state.worlds.activeRun = run
                CombatRules.runAutomaticTurns(in: &state)
            }
            return store
        }
        func seed(where predicate: (Double) -> Bool) -> UInt64 {
            var seed: UInt64 = 1
            while true {
                var probe = SeededRNG(seed: seed)
                _ = probe.int(in: 0...0) // exact production target selection
                if predicate(probe.double(in: 0...1)) { return seed }
                seed += 1
            }
        }
        let miss = staged(seed: seed { $0 < 0.56 })
        XCTAssertEqual(miss.activeEncounter?.evasionAttempts.last?.resolution, .probabilityMiss)
        XCTAssertEqual(miss.activeRun?.binderHP, 20)
        XCTAssertTrue(miss.activeEncounter?.afflictions?.contains { $0.target == .binder } != true,
                      "a missed direct hit cannot land its Heat affliction")

        let hit = staged(seed: seed { $0 >= 0.56 })
        XCTAssertEqual(hit.activeEncounter?.evasionAttempts.last?.resolution, .probabilityHit)
        XCTAssertLessThan(hit.activeRun?.binderHP ?? 20, 20)
    }

    func testWorldContactFreezesExactGhostAndEvasionReceiptsAcrossToggleAndReload() throws {
        let store = GameStore(io: .temporary(name: "footwork-contact-\(UUID().uuidString)"))
        store.write("plains")
        store.bindAndDepart()
        store.mutate("stage exact v2 evasion contact") { state in
            while state.base.roster.count < 2 { state.base.roster.append(CompanionState()) }
            state.base.activeParty = [0, 1]
            guard var run = state.worlds.activeRun else { return }
            run.tuning.debugCombatV2BinderAttackEnabled = true
            run.tuning.debugCombatV2BinderNodeIDs = [CombatDerivedStatsRules.Node.footwork,
                                                     CombatDerivedStatsRules.Node.ghost]
            run.tuning.debugCombatV2CompanionNodeIDs = [1: [CombatDerivedStatsRules.Node.ghost]]
            let enemy = WorldEnemy(id: .init(rawValue: 98_001), creatureID: "paper_moth",
                                   position: run.playerPosition, isAwake: true)
            run.enemies = [enemy]
            state.worlds.activeRun = run
            WorldRules.beginEncounter(triggeredBy: enemy, runsAutomaticTurns: false, in: &state)
        }
        let frozen = try XCTUnwrap(store.activeEncounter)
        XCTAssertEqual(frozen.ghostEvasionAvailable, [.binder, .companion(1)])
        XCTAssertEqual(frozen.debugV2Evasion?.entry(for: .binder)?.components.map(\.nodeID),
                       [CombatDerivedStatsRules.Node.footwork])
        XCTAssertTrue(frozen.debugV2Evasion?.entry(for: .companion(0))?.components.isEmpty == true)
        XCTAssertTrue(frozen.debugV2Evasion?.entry(for: .companion(1))?.components.isEmpty == true)

        store.mutate("change DEBUG ownership after contact") { state in
            state.worlds.activeRun?.tuning.debugCombatV2BinderNodeIDs = []
            state.worlds.activeRun?.tuning.debugCombatV2CompanionNodeIDs = [:]
        }
        XCTAssertEqual(store.activeEncounter?.ghostEvasionAvailable, frozen.ghostEvasionAvailable)
        XCTAssertEqual(store.activeEncounter?.debugV2Evasion, frozen.debugV2Evasion)
        let resumed = try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(store.state))
        XCTAssertEqual(resumed.worlds.activeRun?.activeEncounter?.ghostEvasionAvailable,
                       frozen.ghostEvasionAvailable)
        XCTAssertEqual(resumed.worlds.activeRun?.activeEncounter?.debugV2Evasion,
                       frozen.debugV2Evasion)
    }

    func testFeintAndUntouchableOwnershipFreezeWithoutAura() throws {
        var state = GameState.newGame()
        while state.base.roster.count < 4 { state.base.roster.append(CompanionState()) }
        state.base.activeParty = [0, 1, 2, 3]
        let receipt = try XCTUnwrap(CombatDerivedStatsRules.debugEvasionReceipt(
            enabled: true, party: CombatRules.party(of: state), in: state,
            binderNodeIDs: [CombatDerivedStatsRules.Node.feint],
            companionNodeIDs: [2: [CombatDerivedStatsRules.Node.untouchable]]))
        XCTAssertEqual(receipt.entry(for: .binder)?.ownsFeint, true)
        XCTAssertEqual(receipt.entry(for: .binder)?.ownsUntouchable, false)
        XCTAssertEqual(receipt.entry(for: .companion(2))?.ownsUntouchable, true)
        XCTAssertTrue([0, 1, 3].allSatisfy {
            receipt.entry(for: .companion($0))?.ownsFeint == false
                && receipt.entry(for: .companion($0))?.ownsUntouchable == false
        })
    }

    func testFeintArmsAfterCommittedDirectMissRefreshesAndExpiresAfterNormalActionOnly() throws {
        let store = inFight()
        store.mutate("stage Feint action lifecycle") { state in
            Self.learnEverything(&state)
            guard var run = state.worlds.activeRun, var encounter = run.activeEncounter,
                  let foe = encounter.foes.first else { return }
            encounter.order = [.binder]
            encounter.turnSlots = [.init(actor: .binder)]
            encounter.turnIndex = 0
            encounter.foes[0].stats.evasion = 1
            encounter.foes[0].stats.maxHP = 500
            encounter.foes[0].currentHP = 500
            encounter.debugV2Evasion = .init(entries: [
                .init(actor: .binder, characterEvasion: 0, components: [], ownsFeint: true,
                      ownsUntouchable: false)
            ])
            encounter.feintActive = []
            encounter.untouchableStates = [:]
            encounter.debugV2OwnedNodeIDs = [.binder: [CombatDerivedStatsRules.Node.brace,
                                                        "combat.offense.swiftness.quicken"]]
            encounter.braceReceipts = [:]
            run.activeEncounter = encounter
            state.worlds.activeRun = run

            CombatRules.perform(.attack(foe: foe.id), by: .binder, in: &state)
            XCTAssertEqual(state.worlds.activeRun?.activeEncounter?.feintActive, [.binder],
                           "a committed direct miss still arms Feint")

            // Quicken is zero-turn setup: it neither expires nor refreshes Feint.
            CombatRules.perform(.skill("quicken"), by: .binder, in: &state)
            XCTAssertEqual(state.worlds.activeRun?.activeEncounter?.feintActive, [.binder])

            state.worlds.activeRun?.activeEncounter?.foes[0].stats.evasion = 0
            CombatRules.perform(.attack(foe: foe.id), by: .binder, in: &state)
            XCTAssertEqual(state.worlds.activeRun?.activeEncounter?.feintActive, [.binder],
                           "a later direct action refreshes rather than stacks")

            CombatRules.perform(.skill("brace"), by: .binder, in: &state)
            XCTAssertEqual(state.worlds.activeRun?.activeEncounter?.feintActive, [],
                           "the next normal-cost action expires Feint after its consequences")
        }
    }

    func testUntouchableProductionRouteCountsOnlySingleDirectAndGrowsAtRoundBoundary() throws {
        let store = inFight()
        store.mutate("stage Untouchable direct miss") { state in
            guard var run = state.worlds.activeRun, var encounter = run.activeEncounter,
                  let foe = encounter.foes.first else { return }
            run.rng = SeededRNG(seed: 41)
            run.binderHP = 30
            run.companionHP[0] = 0
            encounter.order = [.foe(foe.id), .binder]
            encounter.turnSlots = encounter.order.map { .init(actor: $0) }
            encounter.turnIndex = 0
            encounter.foes[0].stats.delivery = .single
            encounter.debugV2Evasion = .init(entries: [
                .init(actor: .binder, characterEvasion: 1, components: [], ownsFeint: false,
                      ownsUntouchable: true)
            ])
            encounter.ghostEvasionAvailable = []
            encounter.dodging[.binder] = 1
            encounter.feintActive = []
            encounter.untouchableStates = [.binder: .init()]
            run.activeEncounter = encounter
            state.worlds.activeRun = run
            CombatRules.runAutomaticTurns(in: &state)

            var after = state.worlds.activeRun!.activeEncounter!
            XCTAssertEqual(after.untouchableStates?[.binder]?.targetedDirectCount, 1)
            XCTAssertEqual(after.untouchableStates?[.binder]?.landedDirectCount, 0)
            CombatRules.startNewRound(&after, run: state.worlds.activeRun!)
            XCTAssertEqual(after.untouchableStates?[.binder]?.percentagePoints, 5)
            XCTAssertEqual(after.untouchableStates?[.binder]?.targetedDirectCount, 0)
            XCTAssertEqual(after.untouchableStates?[.binder]?.landedDirectCount, 0)
        }
    }

    func testUntouchableLandedDirectResetsAndAreaNeverTouchesCounters() throws {
        for delivery in [Delivery.single, .area, .multi] {
            let store = inFight()
            store.mutate("stage Untouchable \(delivery)") { state in
                guard var run = state.worlds.activeRun, var encounter = run.activeEncounter,
                      let foe = encounter.foes.first else { return }
                run.rng = SeededRNG(seed: 91)
                run.binderHP = 30
                run.companionHP[0] = 0
                encounter.order = [.foe(foe.id), .binder]
                encounter.turnSlots = encounter.order.map { .init(actor: $0) }
                encounter.turnIndex = 0
                encounter.foes[0].stats.delivery = delivery
                encounter.debugV2Evasion = .init(entries: [
                    .init(actor: .binder, characterEvasion: 0, components: [], ownsFeint: false,
                          ownsUntouchable: true)
                ])
                encounter.ghostEvasionAvailable = []
                encounter.feintActive = []
                encounter.untouchableStates = [.binder: .init(percentagePoints: 15)]
                run.activeEncounter = encounter
                state.worlds.activeRun = run
                CombatRules.runAutomaticTurns(in: &state)
            }
            let saved = try XCTUnwrap(store.activeEncounter?.untouchableStates?[.binder])
            if delivery == .single {
                XCTAssertEqual(saved.targetedDirectCount, 1)
                XCTAssertEqual(saved.landedDirectCount, 1)
                XCTAssertEqual(saved.percentagePoints, 0)
            } else {
                XCTAssertEqual(saved, .init(percentagePoints: 15),
                               "area/multi bypass both avoidance and Untouchable counters")
            }
        }
    }

    func testForcedOpeningCannotGrowUntouchableButLandedOpeningResetsIt() throws {
        func staged(misses: Bool) throws -> EncounterState.UntouchableState {
            let store = inFight()
            store.mutate("stage forced opening Untouchable") { state in
                guard var run = state.worlds.activeRun, var encounter = run.activeEncounter,
                      let foe = encounter.foes.first else { return }
                run.rng = SeededRNG(seed: 71)
                run.binderHP = 30
                run.companionHP[0] = 0
                encounter.order = [.binder, .foe(foe.id)]
                encounter.turnSlots = encounter.order.map { .init(actor: $0) }
                encounter.turnIndex = 0
                encounter.opening = .init(preContactDisclosed: false, initial: .creatureAmbush,
                                          slipperyProbability: nil, slipperyRoll: nil,
                                          slipperyPrevented: false, watchfulSuppressedOpening: false,
                                          resolved: .creatureAmbush, pendingFoeActions: [foe.id])
                encounter.foes[0].stats.delivery = .single
                encounter.debugV2Evasion = .init(entries: [
                    .init(actor: .binder, characterEvasion: misses ? 1 : 0, components: [],
                          ownsFeint: false, ownsUntouchable: true)
                ])
                encounter.ghostEvasionAvailable = []
                if misses { encounter.dodging[.binder] = 1 }
                encounter.feintActive = []
                encounter.untouchableStates = [.binder: .init(percentagePoints: 10)]
                run.activeEncounter = encounter
                state.worlds.activeRun = run
                CombatRules.runAutomaticTurns(in: &state)
                if var current = state.worlds.activeRun?.activeEncounter,
                   let activeRun = state.worlds.activeRun {
                    CombatRules.startNewRound(&current, run: activeRun)
                    state.worlds.activeRun?.activeEncounter = current
                }
            }
            return try XCTUnwrap(store.activeEncounter?.untouchableStates?[.binder])
        }
        XCTAssertEqual(try staged(misses: true).percentagePoints, 10,
                       "forced-opening misses cannot award a pre-round step")
        XCTAssertEqual(try staged(misses: false).percentagePoints, 0,
                       "a landed forced-opening direct attack resets an existing stack")
    }

    func testFeintAndUntouchableModernStatePersistsWithoutRemintAfterReload() throws {
        var encounter = EncounterState(id: .init(rawValue: 67), foes: [], order: [.binder],
            debugV2Evasion: .init(entries: [
                .init(actor: .binder, characterEvasion: 0.2, components: [], ownsFeint: true,
                      ownsUntouchable: true)
            ]))
        encounter.feintActive = [.binder]
        encounter.untouchableStates = [.binder: .init(percentagePoints: 20,
                                                       targetedDirectCount: 2,
                                                       landedDirectCount: 0)]
        let resumed = try JSONDecoder().decode(EncounterState.self,
                                                from: JSONEncoder().encode(encounter))
        XCTAssertEqual(resumed.feintActive, [.binder])
        XCTAssertEqual(resumed.untouchableStates, encounter.untouchableStates)

        var rng = SeededRNG(seed: 68)
        let enabledEmpty = CombatRules.makeEncounter(
            id: .init(rawValue: 68), foes: [], party: [.binder],
            debugV2Evasion: .init(entries: [
                .init(actor: .binder, characterEvasion: 0.2, components: [], ownsFeint: false,
                      ownsUntouchable: false)
            ]), rng: &rng)
        XCTAssertEqual(enabledEmpty.feintActive, [])
        XCTAssertEqual(enabledEmpty.untouchableStates, [:],
                       "enabled-empty freezes an explicit modern zero-state, distinct from legacy nil")
    }

    func testFinalTargetResolverConsumesFeintAndUntouchableExactlyOnceWithOneClamp() throws {
        let state = GameState.newGame()
        func resolve(owns: Bool, base: Double, points: Int) throws
            -> EncounterState.EvasionAttempt {
            var map = WorldMap(width: 1, height: 1, tiles: [Tile(isRevealed: true)],
                               entry: .init(x: 0, y: 0))
            map[.init(x: 0, y: 0)].content = .portal(isEntry: true)
            var run = WorldRun(runIndex: 1, book: BoundBook(written: [], essencePaid: 0),
                               mapSeed: 991, rng: SeededRNG(seed: 991), map: map,
                               playerPosition: .init(x: 0, y: 0), binderHP: 20)
            var encounter = EncounterState(id: .init(rawValue: 991), foes: [], order: [.binder],
                debugV2Evasion: .init(entries: [
                    .init(actor: .binder, characterEvasion: base, components: [],
                          ownsFeint: owns, ownsUntouchable: owns)
                ]), ghostEvasionAvailable: [])
            encounter.feintActive = [.binder]
            encounter.untouchableStates = [.binder: .init(percentagePoints: points)]
            _ = CombatRules.resolvePartyMiss(.binder, in: state, run: &run, encounter: &encounter)
            return try XCTUnwrap(encounter.evasionAttempts.last)
        }

        let active = try resolve(owns: true, base: 0.50, points: 20)
        XCTAssertEqual(active.components.map(\.nodeID), [CombatDerivedStatsRules.Node.feint,
                                                         CombatDerivedStatsRules.Node.untouchable])
        XCTAssertEqual(active.components.map(\.amount), [0.10, 0.20])
        XCTAssertEqual(active.finalChance, 0.80, accuracy: 0.000_001,
                       "the final-target resolver adds each live receipt exactly once")

        let noOwnership = try resolve(owns: false, base: 0.50, points: 20)
        XCTAssertTrue(noOwnership.components.isEmpty)
        XCTAssertEqual(noOwnership.finalChance, 0.50, accuracy: 0.000_001,
                       "enabled-empty ownership cannot consume persisted-looking dynamic state")
        XCTAssertEqual(active.roll, noOwnership.roll, "the counterfactual uses the same one RNG draw")

        let clamped = try resolve(owns: true, base: 0.70, points: 20)
        XCTAssertEqual(clamped.finalChance, 0.85, accuracy: 0.000_001,
                       "base + Feint + Untouchable is summed continuously and clamped once")
    }

    func testStaleDirectSelectionDoesNotArmExpireAdvanceOrMutate() throws {
        let store = inFight()
        store.mutate("stage stale Feint selection") { state in
            guard var run = state.worlds.activeRun, var encounter = run.activeEncounter else { return }
            encounter.order = [.binder]
            encounter.turnSlots = [.init(actor: .binder)]
            encounter.turnIndex = 0
            encounter.debugV2Evasion = .init(entries: [
                .init(actor: .binder, characterEvasion: 0, components: [], ownsFeint: true,
                      ownsUntouchable: false)
            ])
            encounter.feintActive = [.binder]
            encounter.untouchableStates = [:]
            let stale = InstanceID(rawValue: UInt64.max)
            let before = encounter
            run.activeEncounter = encounter
            state.worlds.activeRun = run
            CombatRules.perform(.attack(foe: stale), by: .binder, in: &state)
            XCTAssertEqual(state.worlds.activeRun?.activeEncounter, before)
        }
    }

    func testCommittedActionOutcomeSeparatesNormalNondirectFromRejectedActions() throws {
        let store = inFight()
        store.mutate("stage typed action outcomes") { state in
            Self.learnEverything(&state)
            guard var run = state.worlds.activeRun, var encounter = run.activeEncounter,
                  let foe = encounter.foes.first else { return }
            encounter.order = [.binder]
            encounter.turnSlots = [.init(actor: .binder)]
            encounter.turnIndex = 0
            encounter.foes[0].currentHP = 500
            encounter.foes[0].stats.maxHP = 500
            encounter.debugV2Evasion = .init(entries: [
                .init(actor: .binder, characterEvasion: 0, components: [], ownsFeint: true,
                      ownsUntouchable: false)
            ])
            encounter.feintActive = [.binder]
            encounter.untouchableStates = [:]
            for skill in CombatRules.skills(for: .binder, in: state)
                where skill.power > 0 && skill.id != "flense" {
                encounter.cooldowns[CombatRules.cooldownKey(skill, for: .binder)] = 2
            }
            run.activeEncounter = encounter
            state.worlds.activeRun = run

            CombatRules.perform(.damageSkill(foe: foe.id), by: .binder, in: &state)
            XCTAssertEqual(state.worlds.activeRun?.activeEncounter?.feintActive, [],
                           "Flense is a committed normal-cost non-direct action")
            XCTAssertTrue(state.worlds.activeRun?.activeEncounter?.afflictions?.contains {
                $0.target == .foe(foe.id) && $0.kind == .bleed
            } == true)

            state.worlds.activeRun?.activeEncounter?.feintActive = [.binder]
            state.worlds.activeRun?.activeEncounter?.cooldowns = [:]
            state.worlds.activeRun?.activeEncounter?.binderSkillCooldown = 0
            CombatRules.perform(.skill("first_strike", foe: foe.id), by: .binder, in: &state)
            XCTAssertEqual(state.worlds.activeRun?.activeEncounter?.feintActive, [.binder],
                           "spent First Strike is rejected atomically after a prior normal action")

            state.worlds.activeRun?.activeEncounter?.feintActive = [.binder]
            let beforeItem = state.worlds.activeRun?.activeEncounter
            CombatRules.perform(.useItem(stack: .init(rawValue: UInt64.max), ally: .binder),
                                by: .binder, in: &state)
            XCTAssertEqual(state.worlds.activeRun?.activeEncounter, beforeItem,
                           "a stale item is rejected without expiry or schedule mutation")

            state.worlds.activeRun?.activeEncounter?.binderSkillCooldown = 2
            state.worlds.activeRun?.activeEncounter?.cooldowns = [:]
            let beforeHeal = state.worlds.activeRun?.activeEncounter
            CombatRules.perform(.healSkill(ally: .binder), by: .binder, in: &state)
            XCTAssertEqual(state.worlds.activeRun?.activeEncounter, beforeHeal,
                           "no ready heal is rejected without expiry or schedule mutation")
        }
    }

    func testInsulationReceiptFreezesExactTypedOwnerWithoutAuraOrHeatDefault() throws {
        let party: [Combatant] = [.binder, .companion(0), .companion(1), .companion(2), .companion(3)]
        let insulation = CombatDerivedStatsRules.Node.insulation
        let receipt = try XCTUnwrap(CombatDerivedStatsRules.debugResistanceReceipt(
            enabled: true, party: party,
            binderNodeIDs: [insulation],
            binderChoices: [insulation: .init(rawValue: EmanationKind.caustic.rawValue)],
            companionNodeIDs: [0: [insulation], 1: [insulation], 2: [insulation]],
            companionChoices: [
                0: [insulation: .init(rawValue: EmanationKind.heat.rawValue)],
                1: [insulation: .init(rawValue: EmanationKind.light.rawValue)],
                2: [insulation: .init(rawValue: "unknown")]
            ]))
        XCTAssertEqual(receipt.entry(for: .binder)?.insulationChoice, .caustic)
        XCTAssertEqual(receipt.entry(for: .companion(0))?.insulationChoice, .heat)
        XCTAssertEqual(receipt.entry(for: .companion(1))?.insulationChoice, .light)
        XCTAssertNil(receipt.entry(for: .companion(2))?.insulationChoice,
                     "unknown choices must not silently become Heat")
        XCTAssertNil(receipt.entry(for: .companion(3))?.insulationChoice,
                     "another owner's choice is never an aura")
        XCTAssertNil(CombatDerivedStatsRules.debugResistanceReceipt(
            enabled: false, party: party, binderNodeIDs: [insulation], binderChoices: [:],
            companionNodeIDs: [:], companionChoices: [:]))
    }

    func testRealFoeCommitAppliesImmovableOnlyToPierceAndDirectEmanation() throws {
        func staged(kind: DamageKind, element: EmanationKind?, immovable: Bool) -> GameStore {
            let store = inFight()
            store.mutate("stage Immovable commit counterfactual") { state in
                guard var run = state.worlds.activeRun, var encounter = run.activeEncounter,
                      !encounter.foes.isEmpty else { return }
                run.rng = SeededRNG(seed: 91)
                run.binderHP = 40
                run.companionHP[0] = 0
                encounter.foes[0].stats.delivery = .single
                encounter.foes[0].stats.damageKind = kind
                encounter.foes[0].stats.element = element
                encounter.foes[0].stats.attack = 18
                encounter.order = [.foe(encounter.foes[0].id), .binder]
                encounter.turnSlots = encounter.order.map { .init(actor: $0) }
                encounter.turnIndex = 0
                encounter.partyRanks = [.binder: .front]
                encounter.debugV2Armour = .init(entries: [
                    .init(actor: .binder, equipmentProtectivePower: 5, sturdiness: 1,
                          ownedNodeIDs: immovable ? [CombatDerivedStatsRules.Node.immovable] : [],
                          entryRank: .front)
                ])
                encounter.debugV2Resistance = .init(entries: [
                    .init(actor: .binder, insulationChoice: element)
                ])
                encounter.debugV2Evasion = .init(entries: [
                    .init(actor: .binder, characterEvasion: 0, components: [])
                ])
                encounter.ghostEvasionAvailable = []
                encounter.afflictions = []
                run.activeEncounter = encounter
                state.worlds.activeRun = run
                CombatRules.runAutomaticTurns(in: &state)
            }
            return store
        }

        let pierceOwned = staged(kind: .pierce, element: nil, immovable: true)
        let pierceEmpty = staged(kind: .pierce, element: nil, immovable: false)
        XCTAssertGreaterThan(pierceOwned.activeRun?.binderHP ?? 0,
                             pierceEmpty.activeRun?.binderHP ?? 0)

        for kind in [DamageKind.crush, .rend] {
            XCTAssertEqual(staged(kind: kind, element: nil, immovable: true).activeRun?.binderHP,
                           staged(kind: kind, element: nil, immovable: false).activeRun?.binderHP,
                           "Immovable must not alter \(kind) damage")
        }

        let emanationOwned = staged(kind: .crush, element: .caustic, immovable: true)
        let emanationEmpty = staged(kind: .crush, element: .caustic, immovable: false)
        XCTAssertGreaterThan(emanationOwned.activeRun?.binderHP ?? 0,
                             emanationEmpty.activeRun?.binderHP ?? 0)
        XCTAssertEqual(CombatRules.afflictions(on: .binder,
                                               in: try XCTUnwrap(emanationOwned.activeEncounter)),
                       CombatRules.afflictions(on: .binder,
                                               in: try XCTUnwrap(emanationEmpty.activeEncounter)),
                       "Immovable changes direct damage, never the emanation affliction payload")
        XCTAssertTrue(emanationOwned.activeEncounter?.afflictions?.contains {
            $0.target == .binder && $0.kind == .poison
        } == true)
    }

    func testInsulationPureDamageMatchesOnlyChosenEmanationAndRoundsContinuousMultipliersOnce() {
        for choice in EmanationKind.allCases {
            let receipt = EncounterState.DebugV2ResistanceReceipt(entries: [
                .init(actor: .binder, insulationChoice: choice)
            ])
            let matching = CombatDerivedStatsRules.emanationDamage(
                raw: 19, element: choice, receiver: .binder, receipt: receipt)
            XCTAssertEqual(matching.combinedMultiplier, 0.65, accuracy: 0.000_001)
            XCTAssertEqual(matching.finalDamage, 12)
            XCTAssertEqual(matching.components.map(\.nodeID), [CombatDerivedStatsRules.Node.insulation])

            let other = EmanationKind.allCases.first { $0 != choice }!
            XCTAssertEqual(CombatDerivedStatsRules.emanationDamage(
                raw: 19, element: other, receiver: .binder, receipt: receipt).finalDamage, 19)
            XCTAssertEqual(CombatDerivedStatsRules.emanationDamage(
                raw: 0, element: choice, receiver: .binder, receipt: receipt).finalDamage,
                           Tuning.Encounter.minimumDamage)
            XCTAssertEqual(CombatDerivedStatsRules.emanationDamage(
                raw: 1, element: choice, receiver: .binder, receipt: receipt).finalDamage,
                           Tuning.Encounter.minimumDamage)
        }
        let heat = EncounterState.DebugV2ResistanceReceipt(entries: [
            .init(actor: .binder, insulationChoice: .heat)
        ])
        let composed = CombatDerivedStatsRules.emanationDamage(
            raw: 23, element: .heat, receiver: .binder, receipt: heat,
            wornInsulationMultiplier: 0.8, wardMultiplier: 0.6)
        XCTAssertEqual(composed.combinedMultiplier, 0.8 * 0.6 * 0.65, accuracy: 0.000_001)
        XCTAssertEqual(composed.roundedDamage, Int(floor(23 * 0.8 * 0.6 * 0.65)))
        XCTAssertEqual(composed.components.map(\.source), [.wornInsulation, .ward, .insulation])

        let enabledEmpty = EncounterState.DebugV2ResistanceReceipt(entries: [
            .init(actor: .binder, insulationChoice: nil)
        ])
        let fractionalLegacy = 24.0 * 0.8 * 0.6
        let emptyResult = CombatDerivedStatsRules.emanationDamage(
            raw: 24, element: .heat, receiver: .binder, receipt: enabledEmpty,
            wornInsulationMultiplier: 0.8, wardMultiplier: 0.6)
        XCTAssertEqual(emptyResult.finalDamage, Int(fractionalLegacy.rounded()),
                       "enabled-empty must preserve legacy rounding")
        XCTAssertNotEqual(Int(fractionalLegacy.rounded()), Int(floor(fractionalLegacy)),
                          "fixture must distinguish round from floor")
        XCTAssertEqual(composed.roundedDamage, Int(floor(23 * 0.8 * 0.6 * 0.65)),
                       "matching Insulation uses the new single floor point")
    }

    func testRealEmanationRouteUsesFrozenInsulationAndStillCarriesAffliction() throws {
        func staged(choice: EmanationKind?) -> GameStore {
            let store = inFight()
            store.mutate("stage Insulation route") { state in
                guard var run = state.worlds.activeRun, var encounter = run.activeEncounter,
                      !encounter.foes.isEmpty else { return }
                run.rng = SeededRNG(seed: 73)
                run.binderHP = 30
                run.companionHP[0] = 0
                encounter.foes[0].stats.delivery = .single
                encounter.foes[0].stats.element = .caustic
                encounter.foes[0].stats.damageKind = .crush
                encounter.foes[0].stats.attack = 12
                encounter.order = [.foe(encounter.foes[0].id), .binder]
                encounter.turnSlots = encounter.order.map { .init(actor: $0) }
                encounter.turnIndex = 0
                encounter.debugV2Resistance = .init(entries: [
                    .init(actor: .binder, insulationChoice: choice)
                ])
                encounter.debugV2Evasion = .init(entries: [
                    .init(actor: .binder, characterEvasion: 0, components: [])
                ])
                encounter.ghostEvasionAvailable = []
                encounter.afflictions = []
                run.activeEncounter = encounter
                state.worlds.activeRun = run
                CombatRules.runAutomaticTurns(in: &state)
            }
            return store
        }
        let matching = staged(choice: .caustic)
        let nonmatching = staged(choice: .light)
        XCTAssertGreaterThan(matching.activeRun?.binderHP ?? 0, nonmatching.activeRun?.binderHP ?? 0)
        XCTAssertTrue(matching.activeEncounter?.afflictions?.contains {
            $0.target == .binder && $0.kind == .poison
        } == true, "damage resistance must not erase the landed affliction payload")
        XCTAssertEqual(CombatRules.afflictions(on: .binder,
                                               in: try XCTUnwrap(matching.activeEncounter)),
                       CombatRules.afflictions(on: .binder,
                                               in: try XCTUnwrap(nonmatching.activeEncounter)))
    }

    func testPhysicalDirectRouteNeverReadsFrozenInsulationChoice() throws {
        func staged(choice: EmanationKind?) -> GameStore {
            let store = inFight()
            store.mutate("stage physical Insulation counterfactual") { state in
                guard var run = state.worlds.activeRun, var encounter = run.activeEncounter,
                      !encounter.foes.isEmpty else { return }
                run.rng = SeededRNG(seed: 91)
                run.binderHP = 30
                run.companionHP[0] = 0
                encounter.foes[0].stats.delivery = .single
                encounter.foes[0].stats.element = nil
                encounter.foes[0].stats.damageKind = .crush
                encounter.foes[0].stats.attack = 12
                encounter.order = [.foe(encounter.foes[0].id), .binder]
                encounter.turnSlots = encounter.order.map { .init(actor: $0) }
                encounter.turnIndex = 0
                encounter.debugV2Resistance = .init(entries: [
                    .init(actor: .binder, insulationChoice: choice)
                ])
                encounter.debugV2Evasion = .init(entries: [
                    .init(actor: .binder, characterEvasion: 0, components: [])
                ])
                encounter.ghostEvasionAvailable = []
                run.activeEncounter = encounter
                state.worlds.activeRun = run
                CombatRules.runAutomaticTurns(in: &state)
            }
            return store
        }
        let owned = staged(choice: .heat)
        let enabledEmpty = staged(choice: nil)
        XCTAssertEqual(owned.activeRun?.binderHP, enabledEmpty.activeRun?.binderHP)
        XCTAssertEqual(owned.activeEncounter?.log, enabledEmpty.activeEncounter?.log)
        XCTAssertEqual(owned.activeRun?.rng, enabledEmpty.activeRun?.rng)
    }

    func testWorldContactFreezesTypedInsulationAcrossHarnessMutationAndRelaunch() throws {
        let store = GameStore(io: .temporary(name: "insulation-contact-\(UUID().uuidString)"))
        store.write("plains")
        store.bindAndDepart()
        store.mutate("stage typed Insulation contact") { state in
            guard var run = state.worlds.activeRun else { return }
            let node = CombatDerivedStatsRules.Node.insulation
            run.tuning.debugCombatV2BinderAttackEnabled = true
            run.tuning.debugCombatV2BinderNodeIDs.insert(node)
            run.tuning.debugCombatV2BinderChoices[node] = .init(rawValue: EmanationKind.light.rawValue)
            let enemy = WorldEnemy(id: .init(rawValue: 98_002), creatureID: "paper_moth",
                                   position: run.playerPosition, isAwake: true)
            run.enemies = [enemy]
            state.worlds.activeRun = run
            WorldRules.beginEncounter(triggeredBy: enemy, runsAutomaticTurns: false, in: &state)
        }
        let frozen = try XCTUnwrap(store.activeEncounter?.debugV2Resistance)
        XCTAssertEqual(frozen.entry(for: .binder)?.insulationChoice, .light)
        store.mutate("change Insulation after contact") { state in
            let node = CombatDerivedStatsRules.Node.insulation
            state.worlds.activeRun?.tuning.debugCombatV2BinderNodeIDs.remove(node)
            state.worlds.activeRun?.tuning.debugCombatV2BinderChoices[node] =
                .init(rawValue: EmanationKind.heat.rawValue)
        }
        XCTAssertEqual(store.activeEncounter?.debugV2Resistance, frozen)
        let resumed = try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(store.state))
        XCTAssertEqual(resumed.worlds.activeRun?.activeEncounter?.debugV2Resistance, frozen)
    }

    func testCanonicalAfflictionRegistryIsExactlyTheFourAuthoredKinds() {
        XCTAssertEqual(AfflictionDefinition.all.map(\.id), [.burn, .poison, .dazzle, .bleed])
        XCTAssertEqual(Set(AfflictionDefinition.all.flatMap(\.cures)),
                       [.clearing, .quenching, .broad, .quench])
        XCTAssertTrue(AfflictionDefinition.all.allSatisfy(\.stonebarkEligible))
        XCTAssertFalse(AfflictionDefinition.definition(.bleed).cures.contains(.quench))
    }

    func testCanonicalAfflictionMaxRefreshPreservesExactTargetAndTickSource() throws {
        var encounter = EncounterState(id: .init(rawValue: 81), foes: [],
                                       order: [.binder, .companion(0), .companion(1)])
        XCTAssertEqual(
            CombatRules.applyAffliction(.bleed, to: .companion(0), source: .binder,
                                        provenance: .direct, damage: 2, ticks: 3,
                                        targetIsStanding: true, encounter: &encounter),
            .added(try XCTUnwrap(encounter.afflictions?.first))
        )
        let firstReceipt = try XCTUnwrap(encounter.afflictions?.first?.applicationReceipt)
        _ = CombatRules.applyAffliction(.bleed, to: .companion(0), source: .companion(1),
                                        provenance: .coating, damage: 2, ticks: 5,
                                        targetIsStanding: true, encounter: &encounter)
        var wound = try XCTUnwrap(encounter.afflictions?.first)
        XCTAssertEqual(wound.source, .binder, "duration-only refresh stole tick ownership")
        XCTAssertEqual(wound.ticksRemaining, 5)
        XCTAssertNotEqual(wound.applicationReceipt, firstReceipt)

        _ = CombatRules.applyAffliction(.bleed, to: .companion(0), source: .companion(1),
                                        provenance: .coating, damage: 3, ticks: 2,
                                        targetIsStanding: true, encounter: &encounter)
        wound = try XCTUnwrap(encounter.afflictions?.first)
        XCTAssertEqual(wound.source, .companion(1))
        XCTAssertEqual(wound.provenance, .coating)
        XCTAssertEqual(wound.damage, 3)
        XCTAssertEqual(wound.ticksRemaining, 5)
        XCTAssertTrue(CombatRules.afflictions(on: .companion(1), in: encounter).isEmpty,
                      "an exact companion affliction became party-wide")
    }

    func testThreeTickAfflictionHasExactlyThreeFutureBoundariesAcrossRelaunch() throws {
        let store = inFight()
        var run = try XCTUnwrap(store.activeRun)
        var encounter = try XCTUnwrap(run.activeEncounter)
        run.binderHP = 20
        encounter.afflictions = []
        _ = CombatRules.applyAffliction(.bleed, to: .binder, source: .foe(.init(rawValue: 1)),
                                        provenance: .direct, damage: 2, ticks: 3,
                                        targetIsStanding: true, encounter: &encounter)
        XCTAssertEqual(run.binderHP, 20, "application dealt an unauthorized immediate tick")

        CombatRules.tickAfflictions(run: &run, encounter: &encounter)
        XCTAssertEqual(run.binderHP, 18)
        XCTAssertEqual(encounter.afflictions?.first?.ticksRemaining, 2)

        let resumedRun = try JSONDecoder().decode(WorldRun.self, from: JSONEncoder().encode(run))
        var resumedEncounter = try JSONDecoder().decode(EncounterState.self,
                                                        from: JSONEncoder().encode(encounter))
        var mutableRun = resumedRun
        CombatRules.tickAfflictions(run: &mutableRun, encounter: &resumedEncounter)
        XCTAssertEqual(mutableRun.binderHP, 16)
        XCTAssertEqual(resumedEncounter.afflictions?.first?.ticksRemaining, 1)
        CombatRules.tickAfflictions(run: &mutableRun, encounter: &resumedEncounter)
        XCTAssertEqual(mutableRun.binderHP, 14)
        XCTAssertTrue(resumedEncounter.afflictions?.isEmpty == true)
        CombatRules.tickAfflictions(run: &mutableRun, encounter: &resumedEncounter)
        XCTAssertEqual(mutableRun.binderHP, 14, "expired affliction ticked a fourth time")
    }

    func testStonebarkConsumesOnlyForMeaningfulStandingApplication() throws {
        var encounter = EncounterState(id: .init(rawValue: 82), foes: [], order: [.binder])
        _ = CombatRules.applyAffliction(.burn, to: .binder, source: .foe(.init(rawValue: 1)),
                                        provenance: .direct, damage: 3, ticks: 3,
                                        targetIsStanding: true, bypassGuard: true,
                                        encounter: &encounter)
        encounter.statusGuards[.binder] = 1
        XCTAssertEqual(
            CombatRules.applyAffliction(.burn, to: .binder, source: nil,
                                        provenance: .environment, damage: 2, ticks: 2,
                                        targetIsStanding: true, encounter: &encounter),
            .noChange
        )
        XCTAssertEqual(encounter.statusGuards[.binder], 1)
        XCTAssertEqual(
            CombatRules.applyAffliction(.burn, to: .binder, source: nil,
                                        provenance: .environment, damage: 4, ticks: 3,
                                        targetIsStanding: true, encounter: &encounter),
            .prevented
        )
        XCTAssertNil(encounter.statusGuards[.binder])
        encounter.statusGuards[.binder] = 1
        XCTAssertEqual(
            CombatRules.applyAffliction(.poison, to: .binder, source: nil,
                                        provenance: .environment, damage: 2, ticks: 3,
                                        targetIsStanding: false, encounter: &encounter),
            .noChange
        )
        XCTAssertEqual(encounter.statusGuards[.binder], 1)
    }

    func testLegacyAfflictionsAdoptOnceWithoutParallelActiveMirrors() throws {
        var encounter = EncounterState(id: .init(rawValue: 83), foes: [],
                                       order: [.binder, .companion(0)])
        encounter.afflictions = nil
        encounter.statuses[.binder] = [.init(kind: .poison, damage: 2, rounds: 4)]
        encounter.binderBleedRounds = 3
        encounter.companionBleedRounds = 2
        encounter.foeBleeds[.init(rawValue: 9)] = .init(damage: 4, rounds: 2)
        CombatRules.adoptLegacyAfflictions(in: &encounter)

        XCTAssertEqual(CombatRules.afflictions(on: .binder, in: encounter).map(\.kind),
                       [.poison, .bleed])
        XCTAssertEqual(CombatRules.afflictions(on: .companion(0), in: encounter).map(\.kind),
                       [.bleed])
        XCTAssertEqual(CombatRules.afflictions(on: .foe(.init(rawValue: 9)), in: encounter).first?.damage, 4)
        XCTAssertTrue(encounter.statuses.isEmpty)
        XCTAssertTrue(encounter.foeBleeds.isEmpty)
        XCTAssertEqual(encounter.binderBleedRounds, 0)
        XCTAssertEqual(encounter.companionBleedRounds, 0)

        let resumed = try JSONDecoder().decode(EncounterState.self,
                                               from: JSONEncoder().encode(encounter))
        XCTAssertNotNil(resumed.afflictions)
        XCTAssertEqual(resumed.afflictions, encounter.afflictions)
        XCTAssertTrue(resumed.statuses.isEmpty)
        XCTAssertTrue(resumed.foeBleeds.isEmpty)
    }

    func testBroadCureRevalidatesExactReceiptAndNeverChoosesArrayFirst() throws {
        var encounter = EncounterState(id: .init(rawValue: 84), foes: [], order: [.binder])
        _ = CombatRules.applyAffliction(.burn, to: .binder, source: nil,
                                        provenance: .environment, damage: 3, ticks: 2,
                                        targetIsStanding: true, encounter: &encounter)
        _ = CombatRules.applyAffliction(.poison, to: .binder, source: nil,
                                        provenance: .environment, damage: 2, ticks: 3,
                                        targetIsStanding: true, encounter: &encounter)
        XCTAssertFalse(CombatRules.cureAfflictions(for: .clearAnyStatus, on: .binder,
                                                   selectedReceipt: nil, encounter: &encounter))
        XCTAssertEqual(CombatRules.afflictions(on: .binder, in: encounter).count, 2)
        let poison = try XCTUnwrap(CombatRules.afflictions(on: .binder, in: encounter)
            .first { $0.kind == .poison })
        XCTAssertFalse(CombatRules.cureAfflictions(for: .clearAnyStatus, on: .companion(0),
                                                   selectedReceipt: poison.applicationReceipt,
                                                   encounter: &encounter))
        XCTAssertTrue(CombatRules.cureAfflictions(for: .clearAnyStatus, on: .binder,
                                                  selectedReceipt: poison.applicationReceipt,
                                                  encounter: &encounter))
        XCTAssertEqual(CombatRules.afflictions(on: .binder, in: encounter).map(\.kind), [.burn])
        XCTAssertFalse(CombatRules.cureAfflictions(for: .clearAnyStatus, on: .binder,
                                                   selectedReceipt: poison.applicationReceipt,
                                                   encounter: &encounter), "stale receipt was accepted")
    }

    func testCureFamiliesAndQuenchUseExactAuthoredMembership() throws {
        func loaded() -> EncounterState {
            var encounter = EncounterState(id: .init(rawValue: 85), foes: [], order: [.binder])
            for kind in AfflictionID.allCases {
                _ = CombatRules.applyAffliction(kind, to: .binder, source: nil,
                                                provenance: .environment,
                                                damage: kind == .dazzle ? 0 : 2, ticks: 3,
                                                targetIsStanding: true, encounter: &encounter)
            }
            return encounter
        }
        var clearing = loaded()
        XCTAssertTrue(CombatRules.cureAfflictions(for: .clearPoison, on: .binder,
                                                  selectedReceipt: nil, encounter: &clearing))
        XCTAssertEqual(CombatRules.afflictions(on: .binder, in: clearing).map(\.kind),
                       [.burn, .dazzle])
        var quenching = loaded()
        XCTAssertTrue(CombatRules.cureAfflictions(for: .clearElemental, on: .binder,
                                                  selectedReceipt: nil, encounter: &quenching))
        XCTAssertEqual(CombatRules.afflictions(on: .binder, in: quenching).map(\.kind),
                       [.poison, .bleed])
        var quench = loaded()
        let poison = try XCTUnwrap(CombatRules.afflictions(on: .binder, in: quench)
            .first { $0.kind == .poison })
        let bleed = try XCTUnwrap(CombatRules.afflictions(on: .binder, in: quench)
            .first { $0.kind == .bleed })
        XCTAssertFalse(CombatRules.quenchAffliction(on: .binder,
                                                    selectedReceipt: bleed.applicationReceipt,
                                                    encounter: &quench))
        XCTAssertTrue(CombatRules.quenchAffliction(on: .binder,
                                                   selectedReceipt: poison.applicationReceipt,
                                                   encounter: &quench))
        XCTAssertTrue(CombatRules.afflictions(on: .binder, in: quench).contains { $0.kind == .bleed })
    }

    func testLethalCoatedHitSpendsCoatingWithoutAfflictionOrStonebark() throws {
        let store = inFightWith([armoured()])
        let foeID = try XCTUnwrap(store.activeEncounter?.foes.first?.id)
        store.mutate("stage lethal coated hit") { state in
            state.base.binderEquipped[.weapon] = "blade_keen"
            guard var encounter = state.worlds.activeRun?.activeEncounter,
                  let index = encounter.foes.firstIndex(where: { $0.id == foeID }) else { return }
            encounter.foes[index].currentHP = 1
            encounter.foes[index].stats.evasion = 0
            encounter.preparedCoatings[.binder] = .poison
            encounter.statusGuards[.foe(foeID)] = 1
            encounter.order = [.binder, .foe(foeID)]
            encounter.turnSlots = encounter.order.map { .init(actor: $0) }
            encounter.turnIndex = 0
            state.worlds.activeRun?.activeEncounter = encounter
            CombatRules.perform(.attack(foe: foeID), by: .binder, in: &state)
        }
        XCTAssertNil(store.activeEncounter?.preparedCoatings[.binder])
        XCTAssertFalse(store.activeEncounter?.foes.first(where: { $0.id == foeID })?.isAlive ?? true)
        XCTAssertFalse(store.activeEncounter?.afflictions?.contains { $0.target == .foe(foeID) } == true)
        XCTAssertEqual(store.activeEncounter?.statusGuards[.foe(foeID)], 1)
    }

    func testLegacyDecodeImmediatelyResavesWithCanonicalStateOnly() throws {
        var legacy = EncounterState(id: .init(rawValue: 90), foes: [], order: [.binder])
        legacy.afflictions = nil
        legacy.statuses[.binder] = [.init(kind: .poison, damage: 2, rounds: 3)]
        legacy.binderBleedRounds = 2
        let decoded = try SaveCodec.makeDecoder().decode(
            EncounterState.self, from: SaveCodec.makeEncoder().encode(legacy))
        XCTAssertEqual(decoded.afflictions?.count, 2)
        XCTAssertTrue(decoded.statuses.isEmpty)
        XCTAssertEqual(decoded.binderBleedRounds, 0)
        let reloaded = try SaveCodec.makeDecoder().decode(
            EncounterState.self, from: SaveCodec.makeEncoder().encode(decoded))
        XCTAssertEqual(reloaded.afflictions, decoded.afflictions)
        XCTAssertTrue(reloaded.statuses.isEmpty)
        XCTAssertEqual(reloaded.binderBleedRounds, 0)
    }

    func testCombatItemConsumerRequiresSelectionAndCommitsExactCurrentReceipt() throws {
        let store = inFight()
        let antidote = ItemStack(id: .init(rawValue: 91_001), catalogID: "antidote_broad", count: 2)
        store.mutate("stage consumer cure") { state in
            guard var run = state.worlds.activeRun, var encounter = run.activeEncounter else { return }
            encounter.order = [.binder]
            encounter.turnSlots = [.init(actor: .binder)]
            encounter.turnIndex = 0
            encounter.afflictions = []
            _ = CombatRules.applyAffliction(.burn, to: .binder, source: nil,
                                            provenance: .environment, damage: 3, ticks: 2,
                                            targetIsStanding: true, encounter: &encounter)
            _ = CombatRules.applyAffliction(.poison, to: .binder, source: nil,
                                            provenance: .environment, damage: 2, ticks: 3,
                                            targetIsStanding: true, encounter: &encounter)
            _ = run.satchelItems.add(antidote)
            run.activeEncounter = encounter
            state.worlds.activeRun = run
        }

        guard case .refused(.selectionRequired(let choices)) =
                store.combatItemUseEvaluation(stack: antidote, on: .binder) else {
            return XCTFail("Broad cure did not require an exact current selection")
        }
        let poison = try XCTUnwrap(choices.first { $0.kind == .poison })
        guard case .ready(let quote) = store.combatItemUseEvaluation(
            stack: antidote, on: .binder, selecting: poison.applicationReceipt
        ) else { return XCTFail("Exact current selection was not quotable") }
        XCTAssertEqual(store.commitCombatItemUse(quote), .committed)
        XCTAssertEqual(store.activeRun?.satchelItems.stacks.first { $0.id == antidote.id }?.count, 1)
        XCTAssertEqual(CombatRules.afflictions(on: .binder,
                                               in: try XCTUnwrap(store.activeEncounter)).map(\.kind),
                       [.burn])
    }

    func testCombatItemConsumerRejectsEveryStaleAuthorityWithoutLoss() throws {
        let store = inFight()
        let antidote = ItemStack(id: .init(rawValue: 91_002), catalogID: "antidote_broad", count: 2)
        store.mutate("stage stale consumer cure") { state in
            guard var run = state.worlds.activeRun, var encounter = run.activeEncounter else { return }
            encounter.order = [.binder]
            encounter.turnSlots = [.init(actor: .binder)]
            encounter.turnIndex = 0
            encounter.afflictions = []
            _ = CombatRules.applyAffliction(.poison, to: .binder, source: nil,
                                            provenance: .environment, damage: 2, ticks: 3,
                                            targetIsStanding: true, encounter: &encounter)
            _ = run.satchelItems.add(antidote)
            run.activeEncounter = encounter
            state.worlds.activeRun = run
        }
        let receipt = try XCTUnwrap(store.activeEncounter?.afflictions?.first?.applicationReceipt)
        guard case .ready(let quote) = store.combatItemUseEvaluation(
            stack: antidote, on: .binder, selecting: receipt
        ) else { return XCTFail("fixture did not quote") }

        store.mutate("refresh affliction behind sheet") { state in
            guard var encounter = state.worlds.activeRun?.activeEncounter else { return }
            _ = CombatRules.applyAffliction(.poison, to: .binder, source: nil,
                                            provenance: .environment, damage: 3, ticks: 4,
                                            targetIsStanding: true, encounter: &encounter)
            state.worlds.activeRun?.activeEncounter = encounter
        }
        let stateBefore = store.state
        XCTAssertEqual(store.commitCombatItemUse(quote), .refused(.staleAffliction))
        XCTAssertEqual(store.state, stateBefore, "stale receipt changed item, turn, or affliction")

        var staleStack = antidote
        staleStack.count = 1
        XCTAssertEqual(store.combatItemUseEvaluation(stack: staleStack, on: .binder),
                       .refused(.staleItem))
        staleStack = antidote
        staleStack.identified = false
        XCTAssertEqual(store.combatItemUseEvaluation(stack: staleStack, on: .binder),
                       .refused(.staleItem))

        store.mutate("target falls behind sheet") { $0.worlds.activeRun?.binderHP = 0 }
        XCTAssertEqual(store.combatItemUseEvaluation(stack: antidote, on: .binder),
                       .refused(.invalidTarget))
    }

    func testCombatItemSheetDismissesOnlyAfterTypedCommit() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf: root.appendingPathComponent("Sources/Screens/EncounterView.swift"),
                                encoding: .utf8)
        XCTAssertTrue(source.contains("case .committed: dismiss()"))
        XCTAssertTrue(source.contains("case .refused(let refusal): refusalMessage = refusal.message"))
        XCTAssertFalse(source.contains("onUse(stack, ally)\n                                    dismiss()"))
    }

    func testConditionalDirectHitComponentsUseExactThresholdsAndSumOnce() {
        let nodes: Set<CombatNodeID> = [
            CombatDerivedStatsRules.Node.followThrough,
            CombatDerivedStatsRules.Node.bracingStance,
            CombatDerivedStatsRules.Node.weakPoint,
            CombatDerivedStatsRules.Node.exploit
        ]
        let all = CombatDerivedStatsRules.conditionalDirectHitComponents(
            ownedNodeIDs: nodes,
            snapshot: .init(targetArmour: 8, coveringDensity: 50,
                            actorHeldRank: true, targetHasAffliction: true))
        XCTAssertEqual(all.reduce(0) { $0 + $1.amount }, 13)
        XCTAssertEqual(Set(all.map(\.nodeID)), nodes)

        let below = CombatDerivedStatsRules.conditionalDirectHitComponents(
            ownedNodeIDs: nodes,
            snapshot: .init(targetArmour: 7, coveringDensity: 49.999,
                            actorHeldRank: false, targetHasAffliction: false))
        XCTAssertTrue(below.isEmpty)
        XCTAssertTrue(CombatDerivedStatsRules.conditionalDirectHitComponents(
            ownedNodeIDs: [],
            snapshot: .init(targetArmour: 99, coveringDensity: 100,
                            actorHeldRank: true, targetHasAffliction: true)).isEmpty)
    }

    func testConditionalDirectHitReceiptPersistsFrozenRanksAndEnabledEmpty() throws {
        var rng = SeededRNG(seed: 44)
        var encounter = CombatRules.makeEncounter(
            id: InstanceID(rawValue: 44), foes: [], party: [.binder],
            debugV2OwnedNodeIDs: [.binder: [CombatDerivedStatsRules.Node.bracingStance]],
            partyRanks: [.binder: .front], rng: &rng)
        XCTAssertEqual(encounter.rankAtPreviousCompletedAction?[.binder], encounter.partyRanks[.binder])
        encounter.partyRanks[.binder] = .back
        let decoded = try JSONDecoder().decode(EncounterState.self,
                                               from: JSONEncoder().encode(encounter))
        XCTAssertEqual(decoded.rankAtPreviousCompletedAction?[.binder], .front)
        XCTAssertEqual(decoded.partyRanks[.binder], .back)

        var emptyRNG = SeededRNG(seed: 45)
        let empty = CombatRules.makeEncounter(id: InstanceID(rawValue: 45), foes: [], party: [.binder],
                                              debugV2OwnedNodeIDs: [:], rng: &emptyRNG)
        XCTAssertNotNil(empty.rankAtPreviousCompletedAction)
        XCTAssertEqual(empty.debugV2OwnedNodeIDs, [:])
    }

    func testConditionalDirectHitOrdinaryAttackPreviewAndCommitShareFrozenSnapshot() throws {
        let allNodes: Set<CombatNodeID> = [
            CombatDerivedStatsRules.Node.followThrough,
            CombatDerivedStatsRules.Node.bracingStance,
            CombatDerivedStatsRules.Node.weakPoint,
            CombatDerivedStatsRules.Node.exploit
        ]
        for nodes in [allNodes, Set<CombatNodeID>()] {
            let store = GameStore(io: .temporary(name: "conditional-hit-\(UUID().uuidString)"))
            store.write("plains"); store.bindAndDepart()
            let foeID = InstanceID(rawValue: 8_401)
            var traits = CreatureTraits()
            traits.covering = Covering(hardness: 60, length: 0, coverage: 50)
            var stats = CombatStats.derived(from: traits, name: "Marked target", icon: "circle")
            stats.maxHP = 500; stats.armour = 8; stats.evasion = 0
            store.mutate("stage conditional direct hit") { state in
                state.base.binderEquipped[.weapon] = EquippedPiece(catalogID: "field_maul")
                guard var run = state.worlds.activeRun else { return }
                var orderRNG = SeededRNG(seed: 88)
                var encounter = CombatRules.makeEncounter(
                    id: InstanceID(rawValue: 8_400),
                    foes: [.init(id: foeID, traits: traits, stats: stats, currentHP: stats.maxHP)],
                    party: [.binder],
                    debugV2BinderAttack: .init(
                        ordinaryWeaponKind: .crush,
                        crushBonus: .init(components: []),
                        pierceBonus: .init(components: [])),
                    debugV2OwnedNodeIDs: [.binder: nodes],
                    partyRanks: [.binder: .front], rng: &orderRNG)
                encounter.order = [.binder, .foe(foeID)]
                encounter.turnSlots = encounter.order.map { .init(actor: $0) }
                encounter.turnIndex = 0
                _ = CombatRules.applyAffliction(.burn, to: .foe(foeID), source: .binder,
                                                provenance: .direct, damage: 1, ticks: 2,
                                                targetIsStanding: true, encounter: &encounter)
                run.activeEncounter = encounter
                state.worlds.activeRun = run
            }
            let foe = try XCTUnwrap(store.activeEncounter?.foes.first)
            let preview = try XCTUnwrap(CombatRules.debugV2DirectAttackPreview(foe: foe, in: store.state))
            let conditional = nodes.isEmpty ? 0 : 13
            let power = CombatRules.binderAttack(in: store.state) + conditional
            let spread = max(1, Int((Double(power) * Tuning.Encounter.damageVariance).rounded()))
            var fixedRNG = try XCTUnwrap(store.state.worlds.activeRun).rng
            let roll = max(Tuning.Encounter.minimumDamage, power + fixedRNG.int(in: -spread...spread))
            let expected = CombatDamageRules.resolve(
                rolledPower: roll,
                in: .init(damageKind: .crush, covering: traits.covering, armour: stats.armour))
            let before = foe.currentHP
            store.mutate("commit conditional direct hit") {
                CombatRules.perform(.attack(foe: foeID), by: .binder, in: &$0)
            }
            let committed = before - (try XCTUnwrap(store.activeEncounter?.foes.first?.currentHP))
            XCTAssertEqual(committed, expected.finalDamage)
            XCTAssertTrue((preview.lower.finalDamage...preview.upper.finalDamage).contains(committed))
        }
    }

    func testPryAndFinishUseSharedExactTechniquePreviewAndCommit() throws {
        let cases: [(skill: SkillID, hp: Int, expectedBranch: Int, ignoresArmour: Bool)] = [
            ("pry", 100, 7, true),
            ("finish", 35, 14, false),
            ("finish", 36, 4, false)
        ]
        for fixture in cases {
            let store = GameStore(io: .temporary(name: "targeted-technique-\(UUID().uuidString)"))
            store.mutate("learn targeted techniques") { Self.learnEverything(&$0) }
            store.write("plains"); store.bindAndDepart()
            let foeID = InstanceID(rawValue: 8_501)
            var traits = CreatureTraits()
            traits.covering = Covering(hardness: 90, length: 0, coverage: 90)
            var stats = CombatStats.derived(from: traits, name: "Plated target", icon: "circle")
            stats.maxHP = 100; stats.armour = 12; stats.evasion = 0
            store.mutate("stage targeted technique") { state in
                Self.learnEverything(&state)
                state.base.binderEquipped[.weapon] = EquippedPiece(catalogID: "field_maul")
                guard var run = state.worlds.activeRun else { return }
                var orderRNG = SeededRNG(seed: 91)
                var encounter = CombatRules.makeEncounter(
                    id: InstanceID(rawValue: 8_500),
                    foes: [.init(id: foeID, traits: traits, stats: stats, currentHP: fixture.hp)],
                    party: [.binder],
                    debugV2BinderAttack: .init(
                        ordinaryWeaponKind: .crush,
                        crushBonus: .init(components: []),
                        pierceBonus: CombatDerivedStatsRules.preMatchupAttackBonus(
                            ownedNodeIDs: [CombatDerivedStatsRules.Node.keenEye], weaponDamageKind: .pierce)),
                    debugV2OwnedNodeIDs: [.binder: [CombatDerivedStatsRules.Node.followThrough]],
                    partyRanks: [.binder: .front], rng: &orderRNG)
                encounter.order = [.binder, .foe(foeID)]
                encounter.turnSlots = encounter.order.map { .init(actor: $0) }
                encounter.turnIndex = 0
                run.activeEncounter = encounter
                state.worlds.activeRun = run
            }
            let foe = try XCTUnwrap(store.activeEncounter?.foes.first)
            let preview = try XCTUnwrap(CombatRules.debugV2DirectTechniquePreview(
                skillID: fixture.skill, actor: .binder, foe: foe, in: store.state))
            XCTAssertEqual(preview.branchPower, fixture.expectedBranch)
            XCTAssertEqual(preview.kind, .pierce)
            XCTAssertEqual(preview.ignoresArmour, fixture.ignoresArmour)
            if fixture.ignoresArmour {
                XCTAssertEqual(preview.damage.lower.effectiveArmour, 0)
            } else {
                XCTAssertGreaterThan(preview.damage.lower.effectiveArmour, 0)
            }
            let before = foe.currentHP
            store.mutate("commit targeted technique") {
                CombatRules.perform(.skill(fixture.skill, foe: foeID), by: .binder, in: &$0)
            }
            let committed = before - (try XCTUnwrap(store.activeEncounter?.foes.first?.currentHP))
            XCTAssertTrue((preview.damage.lower.finalDamage...preview.damage.upper.finalDamage).contains(committed))
        }
    }

    func testSteadyHandThresholdAndPreviewBranchesDoNotAdvanceRNG() throws {
        XCTAssertTrue(CombatRules.steadyHandCritical(roll: 0.119_999, ownsNode: true))
        XCTAssertFalse(CombatRules.steadyHandCritical(roll: 0.12, ownsNode: true))
        XCTAssertFalse(CombatRules.steadyHandCritical(roll: 0, ownsNode: false))

        let store = GameStore(io: .temporary(name: "steady-hand-preview-\(UUID().uuidString)"))
        store.mutate("learn Steady Hand") { Self.learnEverything(&$0) }
        store.write("plains"); store.bindAndDepart()
        let foeID = InstanceID(rawValue: 8_601)
        var stats = CombatStats.derived(from: CreatureTraits(), name: "Target", icon: "circle")
        stats.maxHP = 100; stats.armour = 5; stats.evasion = 0
        store.mutate("stage Steady Hand preview") { state in
            state.base.binderEquipped[.weapon] = EquippedPiece(catalogID: "field_maul")
            guard var run = state.worlds.activeRun else { return }
            var orderRNG = SeededRNG(seed: 101)
            var encounter = CombatRules.makeEncounter(
                id: InstanceID(rawValue: 8_600),
                foes: [.init(id: foeID, traits: CreatureTraits(), stats: stats, currentHP: 100)],
                party: [.binder],
                debugV2BinderAttack: .init(ordinaryWeaponKind: .crush,
                                           crushBonus: .init(components: []),
                                           pierceBonus: .init(components: [])),
                debugV2OwnedNodeIDs: [.binder: [CombatDerivedStatsRules.Node.steadyHand]],
                partyRanks: [.binder: .front], rng: &orderRNG)
            encounter.order = [.binder, .foe(foeID)]
            encounter.turnSlots = encounter.order.map { .init(actor: $0) }
            encounter.turnIndex = 0
            run.activeEncounter = encounter
            state.worlds.activeRun = run
        }
        let rngBefore = try XCTUnwrap(store.state.worlds.activeRun).rng
        let preview = try XCTUnwrap(CombatRules.debugV2DirectAttackCriticalPreview(
            foe: try XCTUnwrap(store.activeEncounter?.foes.first), in: store.state))
        XCTAssertNotNil(preview.critical)
        XCTAssertEqual(try XCTUnwrap(store.state.worlds.activeRun).rng, rngBefore)
        XCTAssertGreaterThanOrEqual(try XCTUnwrap(preview.critical).lower.rawDamage,
                                    preview.ordinary.lower.rawDamage)

        let power = CombatRules.binderAttack(in: store.state)
        let spread = max(1, Int((Double(power) * Tuning.Encounter.damageVariance).rounded()))
        var chosen = SeededRNG(seed: 1)
        var expectedRoll = 0
        for seed in 1...10_000 {
            var candidate = SeededRNG(seed: UInt64(seed))
            let rolled = max(Tuning.Encounter.minimumDamage,
                             power + candidate.int(in: -spread...spread))
            if candidate.double(in: 0...1) < 0.12 {
                chosen = SeededRNG(seed: UInt64(seed)); expectedRoll = rolled; break
            }
        }
        XCTAssertGreaterThan(expectedRoll, 0)
        store.mutate("force saved Steady Hand success") { $0.worlds.activeRun?.rng = chosen }
        let before = try XCTUnwrap(store.activeEncounter?.foes.first?.currentHP)
        let expected = CombatDamageRules.resolve(
            rolledPower: expectedRoll,
            in: .init(damageKind: .crush, armour: 5, isCritical: true))
        store.mutate("commit Steady Hand attack") {
            CombatRules.perform(.attack(foe: foeID), by: .binder, in: &$0)
        }
        XCTAssertEqual(before - (try XCTUnwrap(store.activeEncounter?.foes.first?.currentHP)),
                       expected.finalDamage)
        XCTAssertTrue(try XCTUnwrap(store.activeEncounter).log.contains("Critical — Steady Hand."))
    }

    func testFlenseUsesFrozenExactOwnerCanonicalBleedAndTruthfulPreview() throws {
        let store = GameStore(io: .temporary(name: "flense-v2-\(UUID().uuidString)"))
        store.mutate("learn Flense") { Self.learnEverything(&$0) }
        store.write("plains"); store.bindAndDepart()
        let foeID = InstanceID(rawValue: 8_701)
        var traits = CreatureTraits()
        traits.covering = Covering(hardness: 0, length: 80, coverage: 75)
        var stats = CombatStats.derived(from: traits, name: "Shaggy target", icon: "circle")
        stats.maxHP = 100; stats.evasion = 0
        store.mutate("stage frozen Flense owner") { state in
            state.base.binderCharacter.stats.wit = 99
            guard var run = state.worlds.activeRun else { return }
            var orderRNG = SeededRNG(seed: 111)
            var encounter = CombatRules.makeEncounter(
                id: InstanceID(rawValue: 8_700),
                foes: [.init(id: foeID, traits: traits, stats: stats, currentHP: 100)],
                party: [.binder, .companion(0)],
                debugV2OwnedNodeIDs: [.binder: [CombatDerivedStatsRules.Node.flense],
                                      .companion(0): []],
                partyRanks: [.binder: .front, .companion(0): .front], rng: &orderRNG)
            encounter.order = [.binder, .companion(0), .foe(foeID)]
            encounter.turnSlots = encounter.order.map { .init(actor: $0) }
            encounter.turnIndex = 0
            encounter.preparedCoatings[.binder] = .poison
            run.activeEncounter = encounter
            state.worlds.activeRun = run
        }
        let foe = try XCTUnwrap(store.activeEncounter?.foes.first)
        let hidden = try XCTUnwrap(CombatRules.debugV2FlensePreview(actor: .binder, foe: foe,
                                                                    in: store.state))
        XCTAssertEqual(hidden.tickDamage, 1...9)
        XCTAssertFalse(hidden.isExact)
        XCTAssertNil(CombatRules.debugV2FlensePreview(actor: .companion(0), foe: foe, in: store.state),
                     "Flense leaked as a legacy-role aura")
        store.mutate("reveal covering") { $0.worlds.activeRun?.activeEncounter?.revealed.insert(foeID) }
        let exact = try XCTUnwrap(CombatRules.debugV2FlensePreview(actor: .binder, foe: foe,
                                                                   in: store.state))
        XCTAssertEqual(exact.tickDamage.lowerBound, CombatRules.flenseTickDamage(covering: traits.covering))
        XCTAssertEqual(exact.tickDamage.lowerBound, exact.tickDamage.upperBound)
        let hpBefore = try XCTUnwrap(store.activeEncounter?.foes.first?.currentHP)
        store.mutate("commit Flense") {
            CombatRules.perform(.skill("flense", foe: foeID), by: .binder, in: &$0)
        }
        XCTAssertEqual(store.activeEncounter?.foes.first?.currentHP, hpBefore,
                       "Flense incorrectly dealt immediate direct damage")
        XCTAssertEqual(store.activeEncounter?.preparedCoatings[.binder], .poison,
                       "Flense consumed a weapon coating despite not being a weapon hit")
        let bleed = try XCTUnwrap(store.activeEncounter?.afflictions?.first {
            $0.target == .foe(foeID) && $0.kind == .bleed
        })
        XCTAssertEqual(bleed.damage, exact.tickDamage.lowerBound)
        XCTAssertEqual(bleed.ticksRemaining, 3)
        XCTAssertEqual(bleed.source, .binder)
        XCTAssertEqual(bleed.provenance, .direct)
        let reloaded = try JSONDecoder().decode(EncounterState.self,
                                                from: JSONEncoder().encode(try XCTUnwrap(store.activeEncounter)))
        XCTAssertEqual(reloaded.afflictions?.first?.applicationReceipt, bleed.applicationReceipt)
        XCTAssertEqual(reloaded.debugV2OwnedNodeIDs?[.binder], [CombatDerivedStatsRules.Node.flense])
    }

    func testBreakingBlowExactOwnerIgnoresArmourAndAutoStaggersOnlyFirstCrushInWindow() throws {
        let store = GameStore(io: .temporary(name: "breaking-blow-\(UUID().uuidString)"))
        store.mutate("learn combat techniques") { Self.learnEverything(&$0) }
        store.write("plains"); store.bindAndDepart()
        let foeID = InstanceID(rawValue: 8_801)
        var stats = CombatStats.derived(from: CreatureTraits(), name: "Armoured target", icon: "circle")
        stats.maxHP = 200; stats.armour = 12; stats.evasion = 0
        store.mutate("stage exact Breaking Blow owner") { state in
            state.base.binderEquipped[.weapon] = EquippedPiece(catalogID: "field_maul")
            guard var run = state.worlds.activeRun else { return }
            var orderRNG = SeededRNG(seed: 121)
            var encounter = CombatRules.makeEncounter(
                id: InstanceID(rawValue: 8_800),
                foes: [.init(id: foeID, traits: CreatureTraits(), stats: stats, currentHP: 200)],
                party: [.binder],
                debugV2BinderAttack: .init(ordinaryWeaponKind: .crush,
                                           crushBonus: .init(components: []),
                                           pierceBonus: .init(components: [])),
                debugV2OwnedNodeIDs: [.binder: [CombatDerivedStatsRules.Node.breakingBlow]],
                partyRanks: [.binder: .front], rng: &orderRNG)
            encounter.order = [.binder, .foe(foeID)]
            encounter.turnSlots = encounter.order.map { .init(actor: $0) }
            encounter.turnIndex = 0
            encounter.extraTurns[.binder] = 1
            run.rng = SeededRNG(seed: 122)
            run.activeEncounter = encounter
            state.worlds.activeRun = run
        }

        let foe = try XCTUnwrap(store.activeEncounter?.foes.first)
        let preview = try XCTUnwrap(CombatRules.debugV2DirectAttackPreview(foe: foe, in: store.state))
        XCTAssertEqual(preview.lower.effectiveArmour, 0)
        XCTAssertTrue(CombatRules.breakingBlowEffect(actor: .binder, kind: .crush,
                                                     encounter: try XCTUnwrap(store.activeEncounter))
            .automaticStaggerAvailable)
        let before = foe.currentHP
        store.mutate("first landed Crush") {
            CombatRules.perform(.attack(foe: foeID), by: .binder, in: &$0)
        }
        let firstDamage = before - (try XCTUnwrap(store.activeEncounter?.foes.first?.currentHP))
        XCTAssertTrue((preview.lower.finalDamage...preview.upper.finalDamage).contains(firstDamage))
        XCTAssertEqual(store.activeEncounter?.staggerAttempts.filter(\.automatic).count, 1)
        XCTAssertEqual(store.activeEncounter?.pendingStaggers[foeID]?.sourceNodeIDs,
                       [CombatDerivedStatsRules.Node.breakingBlow])
        XCTAssertEqual(store.activeEncounter?.breakingBlowScheduledSpent, [.binder])

        store.mutate("second Crush in same expanded window") {
            CombatRules.perform(.attack(foe: foeID), by: .binder, in: &$0)
        }
        XCTAssertEqual(store.activeEncounter?.staggerAttempts.filter(\.automatic).count, 1,
                       "a later action credit minted another automatic Stagger")
        XCTAssertTrue(CombatRules.breakingBlowEffect(actor: .binder, kind: .crush,
                                                     encounter: try XCTUnwrap(store.activeEncounter))
            .ignoresArmour)
        store.mutate("complete foe slot and reach a fresh Binder turn") {
            CombatRules.advanceTurn(in: &$0)
        }
        XCTAssertEqual(store.activeEncounter?.current, .binder)
        XCTAssertEqual(store.activeEncounter?.breakingBlowScheduledSpent, [],
                       "a fresh scheduled personal turn did not mint a new window")
    }

    func testBreakingBlowMissAndWrongKindDoNotSpendAndRelaunchPreservesSeparateWindows() throws {
        let store = GameStore(io: .temporary(name: "breaking-blow-window-\(UUID().uuidString)"))
        store.mutate("learn combat techniques") { Self.learnEverything(&$0) }
        store.write("plains"); store.bindAndDepart()
        let foeID = InstanceID(rawValue: 8_811)
        var stats = CombatStats.derived(from: CreatureTraits(), name: "Elusive target", icon: "circle")
        stats.maxHP = 200; stats.armour = 10; stats.evasion = 1
        store.mutate("stage miss then hit") { state in
            state.base.binderEquipped[.weapon] = EquippedPiece(catalogID: "field_maul")
            guard var run = state.worlds.activeRun else { return }
            var orderRNG = SeededRNG(seed: 131)
            var encounter = CombatRules.makeEncounter(
                id: InstanceID(rawValue: 8_810),
                foes: [.init(id: foeID, traits: CreatureTraits(), stats: stats, currentHP: 200)],
                party: [.binder], debugV2OwnedNodeIDs: [
                    .binder: [CombatDerivedStatsRules.Node.breakingBlow]],
                partyRanks: [.binder: .front], rng: &orderRNG)
            encounter.order = [.binder, .foe(foeID)]
            encounter.turnSlots = encounter.order.map { .init(actor: $0) }
            encounter.turnIndex = 0
            encounter.extraTurns[.binder] = 1
            run.activeEncounter = encounter
            state.worlds.activeRun = run
        }
        store.mutate("miss") { CombatRules.perform(.attack(foe: foeID), by: .binder, in: &$0) }
        XCTAssertEqual(store.activeEncounter?.breakingBlowScheduledSpent, [])
        XCTAssertTrue(store.activeEncounter?.staggerAttempts.isEmpty == true)
        store.mutate("make next Crush land") {
            $0.worlds.activeRun?.activeEncounter?.foes[0].stats.evasion = 0
            CombatRules.perform(.attack(foe: foeID), by: .binder, in: &$0)
        }
        XCTAssertEqual(store.activeEncounter?.breakingBlowScheduledSpent, [.binder])

        var saved = try XCTUnwrap(store.activeEncounter)
        saved.breakingBlowOpeningSpent = []
        let reloaded = try JSONDecoder().decode(EncounterState.self,
                                                from: JSONEncoder().encode(saved))
        XCTAssertEqual(reloaded.breakingBlowScheduledSpent, [.binder])
        XCTAssertEqual(reloaded.breakingBlowOpeningSpent, [])
        XCTAssertFalse(CombatRules.breakingBlowEffect(actor: .binder, kind: .pierce,
                                                      encounter: reloaded).ignoresArmour)
        XCTAssertFalse(CombatRules.breakingBlowEffect(actor: .binder, kind: .crush,
                                                      allowsDirectWeapon: false,
                                                      encounter: reloaded).ignoresArmour,
                       "a nonweapon action such as Unbind inherited Breaking Blow")
        XCTAssertTrue(CombatRules.breakingBlowEffect(actor: .binder, kind: .crush,
                                                     window: .opening, encounter: reloaded)
            .automaticStaggerAvailable)
        XCTAssertFalse(CombatRules.breakingBlowEffect(actor: .companion(0), kind: .crush,
                                                      encounter: reloaded).ignoresArmour,
                       "Breaking Blow leaked to a non-owner")
    }

    func testBreakingBlowUsesDeclaredOverbearCrushAcrossNonCrushEquipment() throws {
        let store = GameStore(io: .temporary(name: "breaking-blow-overbear-\(UUID().uuidString)"))
        store.mutate("learn Overbear") { Self.learnEverything(&$0) }
        store.write("plains"); store.bindAndDepart()
        let foeID = InstanceID(rawValue: 8_821)
        var stats = CombatStats.derived(from: CreatureTraits(), name: "Plate", icon: "circle")
        stats.maxHP = 200; stats.armour = 15; stats.evasion = 0
        store.mutate("stage cross-equipped Overbear") { state in
            state.base.binderEquipped[.weapon] = EquippedPiece(catalogID: "bone_awl")
            guard var run = state.worlds.activeRun else { return }
            var orderRNG = SeededRNG(seed: 141)
            var encounter = CombatRules.makeEncounter(
                id: InstanceID(rawValue: 8_820),
                foes: [.init(id: foeID, traits: CreatureTraits(), stats: stats, currentHP: 200)],
                party: [.binder], debugV2OwnedNodeIDs: [
                    .binder: [CombatDerivedStatsRules.Node.breakingBlow,
                              "combat.offense.force.overbear"]],
                partyRanks: [.binder: .front], rng: &orderRNG)
            encounter.order = [.binder, .foe(foeID)]
            encounter.turnSlots = encounter.order.map { .init(actor: $0) }
            encounter.turnIndex = 0
            run.rng = SeededRNG(seed: 142)
            run.activeEncounter = encounter
            state.worlds.activeRun = run
        }
        let skill = try XCTUnwrap(ContentCatalog.shared.skill("overbear"))
        let before = try XCTUnwrap(store.activeEncounter?.foes.first?.currentHP)
        var expectedRNG = try XCTUnwrap(store.state.worlds.activeRun).rng
        let spread = max(1, Int((Double(skill.power) * Tuning.Encounter.damageVariance).rounded()))
        let rolled = max(Tuning.Encounter.minimumDamage,
                         skill.power + expectedRNG.int(in: -spread...spread))
        let expected = CombatDamageRules.resolve(
            rolledPower: rolled, in: .init(damageKind: .crush, armour: stats.armour,
                                           ignoresArmour: true))
        store.mutate("commit Overbear") {
            CombatRules.perform(.skill("overbear", foe: foeID), by: .binder, in: &$0)
        }
        XCTAssertEqual(before - (try XCTUnwrap(store.activeEncounter?.foes.first?.currentHP)),
                       expected.finalDamage)
        XCTAssertEqual(store.activeEncounter?.pendingStaggers[foeID]?.sourceNodeIDs,
                       [CombatDerivedStatsRules.Node.breakingBlow])
    }

    func testKillingStrokeUsesExactIntegerThresholdAndPreviewBranches() throws {
        let node = CombatNodeID(rawValue: "combat.offense.precision.killing_stroke")
        let foeID = InstanceID(rawValue: 8_831)
        var stats = CombatStats.derived(from: CreatureTraits(), name: "Threshold", icon: "circle")
        stats.maxHP = 100
        let encounter = EncounterState(
            id: InstanceID(rawValue: 8_830), foes: [], order: [.binder],
            debugV2OwnedNodeIDs: [.binder: [node]])

        func foe(hp: Int, apex: Bool = false) -> FoeState {
            .init(id: foeID, traits: CreatureTraits(), stats: stats, currentHP: hp, isApex: apex)
        }

        XCTAssertEqual(CombatRules.killingStrokeOutcome(
            actor: .binder, primaryDamage: 1, foe: foe(hp: 16),
            allowsDirectHit: true, encounter: encounter), .defeat)
        XCTAssertEqual(CombatRules.killingStrokeOutcome(
            actor: .binder, primaryDamage: 1, foe: foe(hp: 17),
            allowsDirectHit: true, encounter: encounter), .none)
        XCTAssertEqual(CombatRules.killingStrokeOutcome(
            actor: .binder, primaryDamage: 15, foe: foe(hp: 15),
            allowsDirectHit: true, encounter: encounter), .none,
            "a primary lethal hit must not create a second defeat event")
        XCTAssertEqual(CombatRules.killingStrokeOutcome(
            actor: .binder, primaryDamage: 1, foe: foe(hp: 16, apex: true),
            allowsDirectHit: true, encounter: encounter), .apexDamage(4))
        XCTAssertEqual(CombatRules.killingStrokeOutcome(
            actor: .binder, primaryDamage: 14, foe: foe(hp: 16, apex: true),
            allowsDirectHit: true, encounter: encounter), .apexDamage(4),
            "the apex consequence remains an authored four-damage event even when it overkills")
        XCTAssertEqual(CombatRules.killingStrokeOutcome(
            actor: .binder, primaryDamage: 1, foe: foe(hp: 16),
            allowsDirectHit: false, encounter: encounter), .none,
            "carried, status and emanation events are not eligible direct hits")
        XCTAssertEqual(CombatRules.killingStrokeOutcome(
            actor: .companion(0), primaryDamage: 1, foe: foe(hp: 16),
            allowsDirectHit: true, encounter: encounter), .none,
            "Killing Stroke leaked from its exact owner")
        let legacy = EncounterState(id: InstanceID(rawValue: 8_832), foes: [], order: [.binder])
        XCTAssertEqual(CombatRules.killingStrokeOutcome(
            actor: .binder, primaryDamage: 1, foe: foe(hp: 16),
            allowsDirectHit: true, encounter: legacy), .none,
            "legacy encounters must not infer canonical ownership")

        let damage = CombatDamageRules.preview(rolledPower: 4...6, in: .init(damageKind: .pierce))
        XCTAssertEqual(CombatRules.killingStrokePreview(
            actor: .binder, damage: damage, foe: foe(hp: 20), encounter: encounter),
            .init(lower: .none, upper: .defeat),
            "a preview crossing the threshold must show both branches rather than promise one")
    }

    func testKillingStrokePryCommitsNonApexDefeatAndApexFourThroughFrozenOwnership() throws {
        let node = CombatNodeID(rawValue: "combat.offense.precision.killing_stroke")
        let skill = try XCTUnwrap(ContentCatalog.shared.skill("pry"))

        func staged(apex: Bool, owns: Bool, suffix: String) throws -> GameStore {
            let store = GameStore(io: .temporary(name: "killing-stroke-\(suffix)-\(UUID().uuidString)"))
            store.mutate("learn Pry") { Self.learnEverything(&$0) }
            store.write("plains"); store.bindAndDepart()
            let foeID = InstanceID(rawValue: apex ? 8_842 : 8_841)
            var traits = CreatureTraits()
            var stats = CombatStats.derived(from: traits, name: apex ? "Apex" : "Ordinary", icon: "circle")
            stats.maxHP = 100; stats.armour = 0; stats.evasion = 0
            var expectedRNG = SeededRNG(seed: 152)
            let spread = max(1, Int((Double(skill.power) * Tuning.Encounter.damageVariance).rounded()))
            let rolled = max(Tuning.Encounter.minimumDamage,
                             skill.power + expectedRNG.int(in: -spread...spread))
            let primary = CombatDamageRules.resolve(
                rolledPower: rolled,
                in: .init(damageKind: .pierce, covering: traits.covering, ignoresArmour: true)
            ).finalDamage
            let currentHP = primary + 4
            store.mutate("stage exact Killing Stroke owner") { state in
                state.base.binderEquipped[.weapon] = EquippedPiece(catalogID: "bone_awl")
                guard var run = state.worlds.activeRun else { return }
                var orderRNG = SeededRNG(seed: 151)
                var encounter = CombatRules.makeEncounter(
                    id: InstanceID(rawValue: apex ? 8_852 : 8_851),
                    foes: [.init(id: foeID, traits: traits, stats: stats,
                                  currentHP: currentHP, isApex: apex)],
                    party: [.binder],
                    debugV2BinderAttack: .init(ordinaryWeaponKind: .pierce,
                                               crushBonus: .init(components: []),
                                               pierceBonus: .init(components: [])),
                    debugV2OwnedNodeIDs: [.binder: owns ? [node] : []],
                    partyRanks: [.binder: .front], rng: &orderRNG)
                encounter.order = [.binder, .foe(foeID)]
                encounter.turnSlots = encounter.order.map { .init(actor: $0) }
                encounter.turnIndex = 0
                run.rng = SeededRNG(seed: 152)
                run.activeEncounter = encounter
                state.worlds.activeRun = run
            }
            return store
        }

        let ordinary = try staged(apex: false, owns: true, suffix: "ordinary")
        let ordinaryID = try XCTUnwrap(ordinary.activeEncounter?.foes.first?.id)
        ordinary.mutate("commit ordinary execute") {
            CombatRules.perform(.skill("pry", foe: ordinaryID), by: .binder, in: &$0)
        }
        XCTAssertEqual(ordinary.activeEncounter?.foes.first?.currentHP, 0)
        XCTAssertTrue(ordinary.activeEncounter?.log.contains {
            $0 == "Killing Stroke — the fight goes out of Ordinary."
        } == true)
        XCTAssertEqual(ordinary.activeEncounter?.log.filter { $0 == "Ordinary goes down." }.count, 1)

        let apex = try staged(apex: true, owns: true, suffix: "apex")
        let apexID = try XCTUnwrap(apex.activeEncounter?.foes.first?.id)
        apex.mutate("commit apex consequence") {
            CombatRules.perform(.skill("pry", foe: apexID), by: .binder, in: &$0)
        }
        XCTAssertEqual(apex.activeEncounter?.foes.first?.currentHP, 0)
        XCTAssertEqual(apex.activeEncounter?.log.filter { $0.contains("Killing Stroke") }.count, 1)
        XCTAssertTrue(apex.activeEncounter?.log.contains { $0 == "Killing Stroke — Apex takes 4 more." } == true)
        XCTAssertEqual(apex.activeEncounter?.log.filter { $0 == "Apex goes down." }.count, 1)

        let empty = try staged(apex: false, owns: false, suffix: "empty")
        let emptyID = try XCTUnwrap(empty.activeEncounter?.foes.first?.id)
        empty.mutate("commit enabled-empty counterfactual") {
            CombatRules.perform(.skill("pry", foe: emptyID), by: .binder, in: &$0)
        }
        XCTAssertEqual(empty.activeEncounter?.foes.first?.currentHP, 4)
        XCTAssertFalse(empty.activeEncounter?.log.contains { $0.contains("Killing Stroke") } == true)

        let attack = try staged(apex: false, owns: true, suffix: "ordinary-attack")
        let attackID = try XCTUnwrap(attack.activeEncounter?.foes.first?.id)
        let initialFoe = try XCTUnwrap(attack.activeEncounter?.foes.first)
        let attackPreview = try XCTUnwrap(CombatRules.debugV2DirectAttackPreview(
            foe: initialFoe, in: attack.state))
        attack.mutate("put ordinary Attack safely across the threshold") {
            $0.worlds.activeRun?.activeEncounter?.foes[0].currentHP = attackPreview.upper.finalDamage + 1
        }
        let stagedFoe = try XCTUnwrap(attack.activeEncounter?.foes.first)
        XCTAssertEqual(try XCTUnwrap(CombatRules.debugV2KillingStrokeAttackPreview(
            foe: stagedFoe, in: attack.state)).lower, .defeat)
        attack.mutate("commit ordinary Killing Stroke") {
            CombatRules.perform(.attack(foe: attackID), by: .binder, in: &$0)
        }
        XCTAssertEqual(attack.activeEncounter?.foes.first?.currentHP, 0)
        XCTAssertEqual(attack.activeEncounter?.log.filter { $0.contains("Killing Stroke") }.count, 1)

        let techniquePreviewFoe = try XCTUnwrap(empty.activeEncounter?.foes.first)
        XCTAssertEqual(try XCTUnwrap(CombatRules.debugV2KillingStrokeTechniquePreview(
            skillID: "pry", actor: .binder, foe: techniquePreviewFoe, in: empty.state)),
                       .init(lower: .none, upper: .none),
                       "enabled-empty technique preview promised an unowned consequence")

        let saved = try JSONEncoder().encode(try XCTUnwrap(ordinary.activeEncounter))
        let reloaded = try JSONDecoder().decode(EncounterState.self, from: saved)
        XCTAssertEqual(reloaded.debugV2OwnedNodeIDs?[.binder], [node],
                       "relaunch or a later DEBUG toggle must not rewrite frozen ownership")
    }

    func testDefeatTransitionRewardsExactSourceOnceAndRejectsUnknownSources() throws {
        let store = inFight(["paper_moth", "paper_moth"])
        let secondWind: CombatNodeID = "combat.offense.swiftness.second_wind"
        let rally: CombatNodeID = "combat.defense.protection.rally"
        store.mutate("stage defeat rewards") { state in
            guard var run = state.worlds.activeRun, var encounter = run.activeEncounter,
                  encounter.foes.count == 2 else { return }
            let first = encounter.foes[0].id, second = encounter.foes[1].id
            encounter.turnSlots = [.init(actor: .binder), .init(actor: .companion(0)),
                                   .init(actor: .companion(1)), .init(actor: .foe(first)),
                                   .init(actor: .foe(second))]
            encounter.debugV2OwnedNodeIDs = [.binder: [secondWind, rally]]
            run.healthCaps = [
                .init(member: .binder, ordinaryMaximum: 20,
                      components: [.init(nodeID: CombatDerivedStatsRules.Node.thickHide, amount: 6)]),
                .init(member: .member(0), ordinaryMaximum: 20, components: []),
                .init(member: .member(1), ordinaryMaximum: 20, components: [])
            ]
            run.binderHP = 24; run.companionHP = [0: 17, 1: 0]
            encounter.foes[0].currentHP = 2; encounter.foes[1].currentHP = 1
            XCTAssertNotNil(CombatRules.applyFoeDamage(
                foeID: first, amount: 2, sourceActor: .binder, provenance: .direct,
                run: &run, encounter: &encounter))
            XCTAssertEqual(run.binderHP, 26)
            XCTAssertEqual(run.companionHP[0], 19)
            XCTAssertEqual(run.companionHP[1], 0)
            XCTAssertNil(CombatRules.applyFoeDamage(
                foeID: first, amount: 20, sourceActor: .binder, provenance: .carried,
                run: &run, encounter: &encounter))
            XCTAssertNil(CombatRules.applyFoeDamage(
                foeID: second, amount: 1, sourceActor: nil, provenance: .environment,
                run: &run, encounter: &encounter))
            XCTAssertEqual(encounter.foes[1].currentHP, 0)
            encounter.foes[1].currentHP = 1
            XCTAssertNil(CombatRules.applyFoeDamage(
                foeID: second, amount: 1, sourceActor: .foe(first), provenance: .direct,
                run: &run, encounter: &encounter))
            XCTAssertEqual(encounter.defeatTransitions.count, 1)
            run.activeEncounter = encounter; state.worlds.activeRun = run
        }
        let transition = try XCTUnwrap(store.activeEncounter?.defeatTransitions.first)
        XCTAssertEqual(transition.sourceActor, .binder)
        XCTAssertEqual(transition.provenance, .direct)
        let encoded = try JSONEncoder().encode(try XCTUnwrap(store.activeEncounter))
        let reloaded = try JSONDecoder().decode(EncounterState.self, from: encoded)
        XCTAssertEqual(reloaded.defeatTransitions, store.activeEncounter?.defeatTransitions)
        XCTAssertEqual(reloaded.nextDefeatTransitionReceipt, 2)
    }

    func testCascadePreservesFollowupSlotsAndPersistsItsFrozenStack() throws {
        let store = inFight(["paper_moth", "paper_moth"])
        let cascade: CombatNodeID = "combat.offense.swiftness.cascade"
        store.mutate("stage cascade") { state in
            guard var run = state.worlds.activeRun, var encounter = run.activeEncounter,
                  encounter.foes.count == 2 else { return }
            let a = encounter.foes[0].id, b = encounter.foes[1].id
            encounter.turnSlots = [
                .init(actor: .binder), .init(actor: .foe(a)),
                .init(actor: .foe(b), kind: .ordinaryPressureFollowUp(1),
                      strengthMultiplier: 0.55, suppressesAfflictions: true),
                .init(actor: .companion(0)),
                .init(actor: .foe(a), kind: .ordinaryPressureFollowUp(2),
                      strengthMultiplier: 0.55, suppressesAfflictions: true)
            ]
            encounter.turnIndex = 0
            encounter.debugV2OwnedNodeIDs = [.companion(0): [cascade]]
            encounter.debugV2Initiative = .init(entries: [
                .init(actor: .binder, baseline: 42, components: [], total: 42,
                      strikesFirst: false, finalPosition: 1),
                .init(actor: .companion(0), baseline: 40, components: [], total: 40,
                      strikesFirst: false, finalPosition: 4),
                .init(actor: .foe(a), baseline: 41, components: [], total: 41,
                      strikesFirst: false, finalPosition: 2),
                .init(actor: .foe(b), baseline: 39, components: [], total: 39,
                      strikesFirst: false, finalPosition: 3)
            ])
            encounter.foes[1].currentHP = 1
            _ = CombatRules.applyFoeDamage(foeID: b, amount: 1,
                sourceActor: .companion(0), provenance: .direct,
                run: &run, encounter: &encounter)
            XCTAssertEqual(encounter.cascadeStacks[.companion(0)], 1)
            XCTAssertEqual(encounter.turnSlots.map(\.actor),
                           [.binder, .companion(0), .foe(a), .foe(b), .foe(a)],
                           "the unacted owner crosses the first lower-total primary immediately")
            CombatRules.startNewRound(&encounter, run: run)
            XCTAssertEqual(encounter.turnSlots.map(\.kind),
                           [.primary, .primary, .primary, .ordinaryPressureFollowUp(1),
                            .ordinaryPressureFollowUp(2)])
            XCTAssertEqual(encounter.turnSlots[3].actor, .foe(b))
            XCTAssertEqual(encounter.turnSlots[4].actor, .foe(a))
            run.activeEncounter = encounter; state.worlds.activeRun = run
        }
        let encoded = try JSONEncoder().encode(try XCTUnwrap(store.activeEncounter))
        let reloaded = try JSONDecoder().decode(EncounterState.self, from: encoded)
        XCTAssertEqual(reloaded.cascadeStacks[.companion(0)], 1)
    }

    func testAfflictionDefeatKeepsExactTickSourceForSecondWind() throws {
        let store = inFight(["paper_moth"])
        let secondWind: CombatNodeID = "combat.offense.swiftness.second_wind"
        store.mutate("stage attributed tick") { state in
            guard var run = state.worlds.activeRun, var encounter = run.activeEncounter,
                  let foeID = encounter.foes.first?.id else { return }
            encounter.debugV2OwnedNodeIDs = [.binder: [secondWind]]
            encounter.foes[0].currentHP = 2; run.binderHP = 10
            _ = CombatRules.applyAffliction(.burn, to: .foe(foeID), source: .binder,
                                            provenance: .coating, damage: 2, ticks: 1,
                                            targetIsStanding: true, encounter: &encounter)
            CombatRules.tickAfflictions(run: &run, encounter: &encounter)
            run.activeEncounter = encounter; state.worlds.activeRun = run
        }
        let transition = try XCTUnwrap(store.activeEncounter?.defeatTransitions.last)
        XCTAssertEqual(transition.sourceActor, .binder)
        XCTAssertEqual(transition.provenance, .affliction)
        XCTAssertEqual(store.activeRun?.binderHP, 13)
    }

    func testThroughstrokeCarriedDefeatUsesTheOriginalActorAndEnabledEmptyHasNoReward() throws {
        let secondWind: CombatNodeID = "combat.offense.swiftness.second_wind"
        func staged(owns: Bool) throws -> GameStore {
            let store = inFight(["paper_moth", "paper_moth"])
            store.mutate("stage ranked spear carried defeat") { state in
                guard var run = state.worlds.activeRun, var encounter = run.activeEncounter else { return }
                state.base.binderEquipped[.weapon] = "ranked_spear"
                encounter.debugV2OwnedNodeIDs = [.binder: owns ? [secondWind] : []]
                encounter.order = [.binder] + encounter.foes.map { .foe($0.id) }
                encounter.turnSlots = encounter.order.map { .init(actor: $0) }
                encounter.turnIndex = 0
                encounter.foes[0].currentHP = 99
                encounter.foes[1].currentHP = 1
                run.binderHP = 10
                run.activeEncounter = encounter; state.worlds.activeRun = run
            }
            return store
        }
        let owned = try staged(owns: true)
        let target = try XCTUnwrap(owned.activeEncounter?.foes.first?.id)
        owned.mutate("commit Throughstroke before automatic turns") {
            CombatRules.perform(.attack(foe: target), by: .binder, in: &$0)
        }
        let carried = try XCTUnwrap(owned.activeEncounter?.defeatTransitions.first {
            $0.provenance == .carried
        })
        XCTAssertEqual(carried.sourceActor, .binder)
        XCTAssertEqual(owned.activeEncounter?.log.filter { $0.contains("Second Wind") }.count, 1)

        let empty = try staged(owns: false)
        let emptyTarget = try XCTUnwrap(empty.activeEncounter?.foes.first?.id)
        empty.takeCombatAction(.attack(foe: emptyTarget))
        XCTAssertEqual(empty.activeEncounter?.log.filter { $0.contains("Second Wind") }.count, 0)
        XCTAssertEqual(empty.activeEncounter?.defeatTransitions.filter {
            $0.provenance == .carried
        }.count, 1, "enabled-empty preserves gameplay and receipt attribution without rewards")
    }

    func testFlurryCarriesFortyPercentOfActualLossOnceWithoutDirectHitRecursion() throws {
        XCTAssertEqual([0, 1, 2, 3, 5, 20].map {
            CombatRules.carriedDamageAmount(actualLoss: $0, fraction: 0.4)
        }, [0, 1, 1, 1, 2, 8])
        XCTAssertEqual([0, 1, 2, 3, 5, 20].map {
            CombatRules.carriedDamageAmount(actualLoss: $0, fraction: 0.5)
        }, [0, 1, 1, 1, 2, 10])
        let node: CombatNodeID = "combat.offense.swiftness.flurry"
        let store = inFight(["paper_moth", "paper_moth"])
        var secondaryBefore = 0
        store.mutate("stage exact Flurry owner") { state in
            guard var run = state.worlds.activeRun, var encounter = run.activeEncounter,
                  encounter.foes.count == 2 else { return }
            encounter.debugV2OwnedNodeIDs = [.binder: [node]]
            encounter.order = [.binder] + encounter.foes.map { .foe($0.id) }
            encounter.turnSlots = encounter.order.map { .init(actor: $0) }
            encounter.turnIndex = 0
            encounter.foes[0].currentHP = 5
            encounter.foes[1].currentHP = 1
            secondaryBefore = 1
            run.activeEncounter = encounter; state.worlds.activeRun = run
        }
        let primary = try XCTUnwrap(store.activeEncounter?.foes.first?.id)
        store.takeCombatAction(.attack(foe: primary))
        let event = try XCTUnwrap(store.activeEncounter?.carriedDamageEvents.last)
        XCTAssertEqual(event.sourceNodeID, node)
        XCTAssertEqual(event.sourceActor, .binder)
        XCTAssertEqual(event.damage, max(1, Int(floor(Double(event.primaryActualLoss) * 0.4))))
        let secondary = try XCTUnwrap(store.activeEncounter?.foes.first {
            $0.id == event.secondaryFoeID
        })
        XCTAssertEqual(secondary.currentHP, max(0, secondaryBefore - event.damage))
        XCTAssertEqual(store.activeEncounter?.defeatTransitions.filter {
            $0.foeID == event.secondaryFoeID && $0.provenance == .carried
        }.count, secondary.isAlive ? 0 : 1)
        XCTAssertEqual(store.activeEncounter?.carriedDamageEvents.count, 1,
                       "a carried event must not recursively produce another Flurry")
    }

    func testConductionCarriesHalfAndCopiesHalfDurationBurnOnlyToDisclosedFoe() throws {
        let node: CombatNodeID = "combat.craft.emanation.conduction"
        func staged(disclosed: Bool) throws -> GameStore {
            let store = inFight(["paper_moth", "paper_moth"])
            store.mutate("stage exact Conduction owner") { state in
                guard var run = state.worlds.activeRun, var encounter = run.activeEncounter,
                      encounter.foes.count == 2 else { return }
                state.base.binderCharacter.ownedCombatNodeIDs.formUnion(legacyCombatNodes(["kindling": 3]))
                encounter.debugV2OwnedNodeIDs = [.binder: [node]]
                encounter.order = [.binder] + encounter.foes.map { .foe($0.id) }
                encounter.turnSlots = encounter.order.map { .init(actor: $0) }
                encounter.turnIndex = 0
                encounter.foes[0].currentHP = 99
                encounter.foes[1].currentHP = 30
                if disclosed { encounter.revealed.insert(encounter.foes[1].id) }
                run.activeEncounter = encounter; state.worlds.activeRun = run
            }
            return store
        }
        let visible = try staged(disclosed: true)
        let primary = try XCTUnwrap(visible.activeEncounter?.foes.first?.id)
        visible.mutate("commit Conduction before automatic round ticks") {
            CombatRules.perform(.skill("elemental_strike", foe: primary), by: .binder, in: &$0)
        }
        let event = try XCTUnwrap(visible.activeEncounter?.carriedDamageEvents.last)
        XCTAssertEqual(event.sourceNodeID, node)
        XCTAssertEqual(event.damage, max(1, event.primaryActualLoss / 2))
        let primaryBurn = try XCTUnwrap(visible.activeEncounter?.afflictions?.first {
            $0.target == .foe(primary) && $0.kind == .burn
        })
        let copied = try XCTUnwrap(visible.activeEncounter?.afflictions?.first {
            $0.target == .foe(event.secondaryFoeID) && $0.kind == .burn
        })
        XCTAssertEqual(copied.source, .binder)
        XCTAssertEqual(copied.provenance, .copied)
        XCTAssertEqual(copied.damage, primaryBurn.damage)
        XCTAssertEqual(copied.ticksRemaining, max(1, (primaryBurn.ticksRemaining + 1) / 2))
        XCTAssertEqual(event.copiedAfflictionReceipt, copied.applicationReceipt)

        let hidden = try staged(disclosed: false)
        let hiddenPrimary = try XCTUnwrap(hidden.activeEncounter?.foes.first?.id)
        hidden.mutate("commit hidden Conduction counterfactual") {
            CombatRules.perform(.skill("elemental_strike", foe: hiddenPrimary), by: .binder, in: &$0)
        }
        XCTAssertTrue(hidden.activeEncounter?.carriedDamageEvents.isEmpty == true)
        XCTAssertEqual(hidden.activeEncounter?.afflictions?.filter { $0.provenance == .copied }.count, 0)
    }

    func testCarriedReceiptRelaunchAndEnabledEmptyParity() throws {
        let node: CombatNodeID = "combat.offense.swiftness.flurry"
        let store = inFight(["paper_moth", "paper_moth"])
        store.mutate("stage Flurry receipt") { state in
            guard var run = state.worlds.activeRun, var encounter = run.activeEncounter else { return }
            encounter.debugV2OwnedNodeIDs = [.binder: [node]]
            encounter.order = [.binder] + encounter.foes.map { .foe($0.id) }
            encounter.turnSlots = encounter.order.map { .init(actor: $0) }
            encounter.turnIndex = 0
            encounter.foes[0].currentHP = 99
            run.activeEncounter = encounter; state.worlds.activeRun = run
        }
        let target = try XCTUnwrap(store.activeEncounter?.foes.first?.id)
        store.takeCombatAction(.attack(foe: target))
        let encoded = try JSONEncoder().encode(try XCTUnwrap(store.activeEncounter))
        let reloaded = try JSONDecoder().decode(EncounterState.self, from: encoded)
        XCTAssertEqual(reloaded.carriedDamageEvents, store.activeEncounter?.carriedDamageEvents)
        XCTAssertEqual(reloaded.nextCarriedDamageReceipt, 2)

        let empty = inFight(["paper_moth", "paper_moth"])
        empty.mutate("stage enabled-empty") { state in
            guard var run = state.worlds.activeRun, var encounter = run.activeEncounter else { return }
            encounter.debugV2OwnedNodeIDs = [.binder: []]
            encounter.order = [.binder] + encounter.foes.map { .foe($0.id) }
            encounter.turnSlots = encounter.order.map { .init(actor: $0) }
            encounter.turnIndex = 0
            encounter.foes[0].currentHP = 99
            run.activeEncounter = encounter; state.worlds.activeRun = run
        }
        let emptyTarget = try XCTUnwrap(empty.activeEncounter?.foes.first?.id)
        empty.takeCombatAction(.attack(foe: emptyTarget))
        XCTAssertTrue(empty.activeEncounter?.carriedDamageEvents.isEmpty == true)
    }

    func testVirulenceExtendsOnlyExactOwnerDirectAndCoatingApplicationsBeforeRefresh() throws {
        let owner: Combatant = .binder
        for kind in AfflictionID.allCases {
            var encounter = try XCTUnwrap(inFight().activeEncounter)
            encounter.debugV2OwnedNodeIDs = [owner: [CombatDerivedStatsRules.Node.virulence]]
            let target: Combatant = .foe(try XCTUnwrap(encounter.foes.first?.id))
            let outcome = CombatRules.applyAffliction(kind, to: target, source: owner,
                provenance: .direct, damage: 2, ticks: 3, targetIsStanding: true,
                encounter: &encounter)
            guard case .added(let row) = outcome else { return XCTFail("expected added \(kind)") }
            XCTAssertEqual(row.ticksRemaining, 5)

            for excluded in [AfflictionProvenance.copied, .retaliation, .environment,
                             .migratedUnknown] {
                var excludedEncounter = try XCTUnwrap(inFight().activeEncounter)
                excludedEncounter.debugV2OwnedNodeIDs = [owner: [CombatDerivedStatsRules.Node.virulence]]
                let excludedTarget: Combatant = .foe(try XCTUnwrap(excludedEncounter.foes.first?.id))
                _ = CombatRules.applyAffliction(kind, to: excludedTarget, source: owner,
                    provenance: excluded, damage: 2, ticks: 3, targetIsStanding: true,
                    encounter: &excludedEncounter)
                XCTAssertEqual(excludedEncounter.afflictions?.first?.ticksRemaining, 3,
                               "\(excluded) cannot receive Virulence")
            }
        }

        var encounter = try XCTUnwrap(inFight().activeEncounter)
        encounter.debugV2OwnedNodeIDs = [.binder: [CombatDerivedStatsRules.Node.virulence]]
        let target: Combatant = .foe(try XCTUnwrap(encounter.foes.first?.id))
        _ = CombatRules.applyAffliction(.poison, to: target, source: .companion(0),
            provenance: .direct, damage: 4, ticks: 7, targetIsStanding: true,
            encounter: &encounter)
        _ = CombatRules.applyAffliction(.poison, to: target, source: .binder,
            provenance: .coating, damage: 3, ticks: 3, targetIsStanding: true,
            encounter: &encounter)
        let retained = try XCTUnwrap(encounter.afflictions?.first)
        XCTAssertEqual(retained.ticksRemaining, 7)
        XCTAssertEqual(retained.source, .companion(0), "weaker/equal refresh cannot steal tick credit")
    }

    func testBlightCopiesProspectivePoisonHalfRoundedUpInStableDisclosedOrderWithoutRecursion() throws {
        var encounter = try XCTUnwrap(inFight(["paper_moth", "paper_moth", "paper_moth"]).activeEncounter)
        encounter.debugV2OwnedNodeIDs = [.binder: [CombatDerivedStatsRules.Node.virulence,
                                                   CombatDerivedStatsRules.Node.blight]]
        let ids = encounter.foes.map(\.id)
        encounter.revealed = Set(ids.dropFirst())
        _ = CombatRules.applyAffliction(.poison, to: .foe(ids[0]), source: .binder,
            provenance: .direct, damage: 5, ticks: 3, targetIsStanding: true,
            encounter: &encounter)
        let primary = try XCTUnwrap(encounter.afflictions?.first { $0.target == .foe(ids[0]) })
        let copy = try XCTUnwrap(encounter.afflictions?.first { $0.provenance == .copied })
        XCTAssertEqual(primary.ticksRemaining, 5)
        XCTAssertEqual(copy.target, .foe(ids[1]))
        XCTAssertEqual(copy.damage, 3)
        XCTAssertEqual(copy.ticksRemaining, 3)
        XCTAssertEqual(copy.source, .binder)
        XCTAssertEqual(encounter.afflictions?.filter { $0.provenance == .copied }.count, 1)

        // A no-op refresh and a Stonebark-prevented primary cannot produce another copy.
        _ = CombatRules.applyAffliction(.poison, to: .foe(ids[0]), source: .binder,
            provenance: .direct, damage: 1, ticks: 1, targetIsStanding: true,
            encounter: &encounter)
        XCTAssertEqual(encounter.afflictions?.filter { $0.provenance == .copied }.count, 1)
        encounter.statusGuards[.foe(ids[1])] = 1
        _ = CombatRules.applyAffliction(.poison, to: .foe(ids[0]), source: .binder,
            provenance: .direct, damage: 1, ticks: 1, targetIsStanding: true,
            encounter: &encounter)
        XCTAssertEqual(encounter.statusGuards[.foe(ids[1])], 1,
                       "a no-op primary cannot consume the secondary's Stonebark")
        encounter.statusGuards[.foe(ids[2])] = 1
        _ = CombatRules.applyAffliction(.poison, to: .foe(ids[2]), source: .binder,
            provenance: .direct, damage: 9, ticks: 9, targetIsStanding: true,
            encounter: &encounter)
        XCTAssertNil(encounter.afflictions?.first { $0.target == .foe(ids[2]) })

        var guarded = try XCTUnwrap(inFight(["paper_moth", "paper_moth"]).activeEncounter)
        guarded.debugV2OwnedNodeIDs = [.binder: [CombatDerivedStatsRules.Node.blight]]
        let guardedIDs = guarded.foes.map(\.id)
        guarded.revealed.insert(guardedIDs[1])
        guarded.statusGuards[.foe(guardedIDs[1])] = 1
        _ = CombatRules.applyAffliction(.poison, to: .foe(guardedIDs[0]), source: .binder,
            provenance: .direct, damage: 5, ticks: 3, targetIsStanding: true,
            encounter: &guarded)
        XCTAssertNotNil(guarded.afflictions?.first { $0.target == .foe(guardedIDs[0]) })
        XCTAssertNil(guarded.afflictions?.first { $0.target == .foe(guardedIDs[1]) })
        XCTAssertNil(guarded.statusGuards[.foe(guardedIDs[1])],
                     "the secondary independently spends its own Stonebark")
    }

    func testPreparedPoisonProductionRouteUsesVirulenceAndBlightAfterLandedHit() throws {
        let store = inFight(["paper_moth", "paper_moth"])
        store.mutate("stage exact venom owners and prepared coating") { state in
            guard var run = state.worlds.activeRun, var encounter = run.activeEncounter else { return }
            encounter.debugV2OwnedNodeIDs = [.binder: [CombatDerivedStatsRules.Node.virulence,
                                                       CombatDerivedStatsRules.Node.blight]]
            encounter.preparedCoatings[.binder] = .poison
            encounter.order = [.binder] + encounter.foes.map { .foe($0.id) }
            encounter.turnSlots = encounter.order.map { .init(actor: $0) }
            encounter.turnIndex = 0
            encounter.foes[0].currentHP = 99
            encounter.revealed.insert(encounter.foes[1].id)
            run.activeEncounter = encounter; state.worlds.activeRun = run
        }
        let target = try XCTUnwrap(store.activeEncounter?.foes.first?.id)
        store.mutate("commit prepared Poison before automatic round ticks") {
            CombatRules.perform(.attack(foe: target), by: .binder, in: &$0)
        }
        let rows = try XCTUnwrap(store.activeEncounter?.afflictions)
        let primary = try XCTUnwrap(rows.first { $0.target == .foe(target) && $0.kind == .poison })
        let copy = try XCTUnwrap(rows.first { $0.provenance == .copied })
        XCTAssertEqual(primary.provenance, .coating)
        XCTAssertEqual(primary.ticksRemaining,
                       (Tuning.Encounter.statusRounds["poison"] ?? 3) + 2)
        XCTAssertEqual(copy.ticksRemaining, max(1, (primary.ticksRemaining + 1) / 2))
        XCTAssertEqual(copy.damage, max(1, (primary.damage + 1) / 2))
        XCTAssertNil(store.activeEncounter?.preparedCoatings[.binder])
    }

    func testCorrodeTicksOncePerSourceTargetRoundAndPersistsErosionWithoutMutatingBaseArmour() throws {
        let store = inFight()
        store.mutate("stage source-owned Corrode poison") { state in
            guard var run = state.worlds.activeRun, var encounter = run.activeEncounter,
                  let foe = encounter.foes.first else { return }
            encounter.debugV2OwnedNodeIDs = [.binder: [CombatDerivedStatsRules.Node.corrode]]
            encounter.foes[0].currentHP = 99
            encounter.foes[0].stats.armour = 5
            _ = CombatRules.applyAffliction(.poison, to: .foe(foe.id), source: .binder,
                provenance: .direct, damage: 1, ticks: 3, targetIsStanding: true,
                encounter: &encounter)
            CombatRules.tickAfflictions(run: &run, encounter: &encounter)
            // A duplicate boundary invocation in the same saved round cannot multiply erosion.
            CombatRules.tickAfflictions(run: &run, encounter: &encounter)
            run.activeEncounter = encounter; state.worlds.activeRun = run
        }
        let encounter = try XCTUnwrap(store.activeEncounter)
        let foe = try XCTUnwrap(encounter.foes.first)
        XCTAssertEqual(encounter.foeArmourErosion[foe.id], min(1, foe.stats.armour))
        XCTAssertEqual(encounter.corrodeReceipts.count, 1)
        XCTAssertEqual(foe.stats.armour, 5)
        let breakdown = CombatRules.foeArmourBreakdown(foe, encounter: encounter)
        XCTAssertEqual(breakdown.beforeIgnore, max(0, foe.stats.armour - (encounter.foeArmourErosion[foe.id] ?? 0)))

        let reloaded = try JSONDecoder().decode(EncounterState.self,
            from: JSONEncoder().encode(encounter))
        XCTAssertEqual(reloaded.foeArmourErosion, encounter.foeArmourErosion)
        XCTAssertEqual(reloaded.corrodeReceipts, encounter.corrodeReceipts)
    }

    func testCorrodeRequiresRetainedExactSourceAndAllowsTwoOwnersOnceEach() throws {
        var run = try XCTUnwrap(inFight().state.worlds.activeRun)
        var encounter = try XCTUnwrap(run.activeEncounter)
        let foeID = try XCTUnwrap(encounter.foes.first?.id)
        encounter.foes[0].currentHP = 99
        encounter.foes[0].stats.armour = 5
        encounter.debugV2OwnedNodeIDs = [
            .binder: [CombatDerivedStatsRules.Node.corrode],
            .companion(0): [CombatDerivedStatsRules.Node.corrode]
        ]
        _ = CombatRules.applyAffliction(.poison, to: .foe(foeID), source: .binder,
            provenance: .direct, damage: 3, ticks: 3, targetIsStanding: true,
            encounter: &encounter)
        _ = CombatRules.applyAffliction(.poison, to: .foe(foeID), source: .companion(0),
            provenance: .direct, damage: 3, ticks: 8, targetIsStanding: true,
            encounter: &encounter)
        CombatRules.tickAfflictions(run: &run, encounter: &encounter)
        XCTAssertEqual(encounter.foeArmourErosion[foeID], min(1, encounter.foes[0].stats.armour),
                       "equal damage/duration refresh must not steal source credit")

        // A genuinely stronger source takes ownership. If a migrated/copy edge exposes a second
        // boundary in the same round, that other exact owner may contribute once too.
        _ = CombatRules.applyAffliction(.poison, to: .foe(foeID), source: .companion(0),
            provenance: .direct, damage: 4, ticks: 8, targetIsStanding: true,
            encounter: &encounter)
        CombatRules.tickAfflictions(run: &run, encounter: &encounter)
        XCTAssertEqual(encounter.corrodeReceipts.filter { $0.target == foeID }.count, 2)
        XCTAssertEqual(Set(encounter.corrodeReceipts.map(\.round)), [encounter.roundNumber])
        XCTAssertEqual(encounter.foeArmourErosion[foeID], min(2, encounter.foes[0].stats.armour))

        var unknown = try XCTUnwrap(inFight().state.worlds.activeRun)
        var unknownEncounter = try XCTUnwrap(unknown.activeEncounter)
        let unknownID = try XCTUnwrap(unknownEncounter.foes.first?.id)
        unknownEncounter.foes[0].currentHP = 99
        unknownEncounter.foes[0].stats.armour = 5
        unknownEncounter.debugV2OwnedNodeIDs = [.binder: [CombatDerivedStatsRules.Node.corrode]]
        _ = CombatRules.applyAffliction(.poison, to: .foe(unknownID), source: nil,
            provenance: .migratedUnknown, damage: 2, ticks: 2, targetIsStanding: true,
            encounter: &unknownEncounter)
        CombatRules.tickAfflictions(run: &unknown, encounter: &unknownEncounter)
        XCTAssertNil(unknownEncounter.foeArmourErosion[unknownID])
        XCTAssertTrue(unknownEncounter.corrodeReceipts.isEmpty)
    }

    func testFoeArmourErosionFloorsBeforeIgnoreAndEnabledEmptyIsParity() {
        let empty = CombatDerivedStatsRules.foeArmour(base: 7, erosion: 0, ignoredFraction: 0.5)
        let legacy = CombatDerivedStatsRules.foeArmour(base: 7, erosion: 0, ignoredFraction: 0.5)
        XCTAssertEqual(empty, legacy)
        let eroded = CombatDerivedStatsRules.foeArmour(base: 7, erosion: 3, ignoredFraction: 0.5)
        XCTAssertEqual(eroded.beforeIgnore, 4)
        XCTAssertEqual(eroded.components, [.init(nodeID: CombatDerivedStatsRules.Node.corrode,
                                                  amount: -3)])
        XCTAssertEqual(eroded.effective, 2)
        XCTAssertEqual(CombatDerivedStatsRules.foeArmour(base: 2, erosion: 99).effective, 0)
    }

    func testCorrodeErosionChangesRealLaterStrikeWithoutChangingFrozenFoeArmour() throws {
        func staged(erosion: Int) throws -> GameStore {
            let store = inFight()
            store.mutate("stage real Corrode armour counterfactual") { state in
                guard var run = state.worlds.activeRun, var encounter = run.activeEncounter else { return }
                state.base.binderCharacter.stats.might = 20
                state.base.binderCharacter.stats.finesse = 20
                run.rng = SeededRNG(seed: 0xC0770DE)
                encounter.debugV2OwnedNodeIDs = [.binder: erosion > 0
                    ? [CombatDerivedStatsRules.Node.corrode] : []]
                encounter.order = [.binder] + encounter.foes.map { .foe($0.id) }
                encounter.turnSlots = encounter.order.map { .init(actor: $0) }
                encounter.turnIndex = 0
                encounter.foes[0].currentHP = 99
                encounter.foes[0].stats.armour = 6
                encounter.foes[0].stats.evasion = 0
                encounter.foeArmourErosion[encounter.foes[0].id] = erosion
                run.activeEncounter = encounter; state.worlds.activeRun = run
            }
            return store
        }
        let plain = try staged(erosion: 0)
        let eroded = try staged(erosion: 2)
        let plainID = try XCTUnwrap(plain.activeEncounter?.foes.first?.id)
        let erodedID = try XCTUnwrap(eroded.activeEncounter?.foes.first?.id)
        plain.takeCombatAction(.attack(foe: plainID))
        eroded.takeCombatAction(.attack(foe: erodedID))
        let plainLoss = 99 - (plain.activeEncounter?.foes.first?.currentHP ?? 99)
        let erodedLoss = 99 - (eroded.activeEncounter?.foes.first?.currentHP ?? 99)
        XCTAssertEqual(erodedLoss, plainLoss + 2)
        XCTAssertEqual(eroded.activeEncounter?.foes.first?.stats.armour, 6)
    }

    func testConstitutionRunsAfterVirulenceBeforeRefreshForAllAfflictions() throws {
        for kind in AfflictionID.allCases {
            var encounter = try XCTUnwrap(inFight().activeEncounter)
            let target: Combatant = .companion(0)
            encounter.debugV2OwnedNodeIDs = [
                .binder: [CombatDerivedStatsRules.Node.virulence],
                target: [CombatDerivedStatsRules.Node.constitution]
            ]
            _ = CombatRules.applyAffliction(kind, to: target, source: .binder,
                provenance: .direct, damage: 2, ticks: 3, targetIsStanding: true,
                encounter: &encounter)
            XCTAssertEqual(encounter.afflictions?.first?.ticksRemaining, 3,
                           "Virulence 3+2 then Constitution ceil-half")
            _ = CombatRules.applyAffliction(kind, to: target, source: .binder,
                provenance: .direct, damage: 1, ticks: 1, targetIsStanding: true,
                encounter: &encounter)
            XCTAssertEqual(encounter.afflictions?.first?.ticksRemaining, 3,
                           "shorter prospective duration is a canonical no-op")
        }
        XCTAssertEqual(CombatDerivedStatsRules.constitutionTicks(authored: 1, endless: false,
                                                                  ownsNode: true), 1)
        XCTAssertEqual(CombatDerivedStatsRules.constitutionTicks(authored: 7, endless: false,
                                                                  ownsNode: true), 4)
        XCTAssertEqual(CombatDerivedStatsRules.constitutionTicks(authored: 7, endless: true,
                                                                  ownsNode: true), 7)
    }

    func testPurchasedFortitudeRouteOwnsExpeditionAndFrozenEncounterConsumers() throws {
        let route: Set<CombatNodeID> = CombatGraphRules.firstCompleteRouteNodeIDs
        let io = SaveFileIO.temporary(name: "fortitude-route-\(UUID().uuidString)")
        let store = GameStore(io: io)
        store.mutate("own the exact first complete route", flush: true) { state in
            state.base.binderCharacter.level = 9
            state.base.binderCharacter.ownedCombatNodeIDs = route
            state.base.binderCharacter.unspentCombatPoints = 0
        }
        store.write("plains")
        XCTAssertTrue(store.bindAndDepart(), store.bindError ?? "bind failed")
        let cap = try XCTUnwrap(store.activeRun?.healthCap(for: .binder))
        XCTAssertEqual(cap.components,
                       [.init(nodeID: CombatDerivedStatsRules.Node.thickHide, amount: 6)])
        XCTAssertEqual(store.activeRun?.binderHP, cap.maximum)

        var state = store.state
        var run = try XCTUnwrap(state.worlds.activeRun)
        let enemy = WorldEnemy(id: .init(rawValue: 0xF047), creatureID: "paper_moth",
                               position: run.playerPosition, isAwake: true)
        run.enemies = [enemy]
        run.encounterGraceTurns = 0
        state.worlds.activeRun = run
        WorldRules.beginEncounter(triggeredBy: enemy, runsAutomaticTurns: false, in: &state)

        let encounter = try XCTUnwrap(state.worlds.activeRun?.activeEncounter)
        XCTAssertEqual(encounter.debugV2OwnedNodeIDs?[.binder], route)
        XCTAssertEqual(encounter.debugV2Armour?.entry(for: .binder)?.ownedNodeIDs,
                       [CombatDerivedStatsRules.Node.ironSkin,
                        CombatDerivedStatsRules.Node.immovable])
        XCTAssertEqual(encounter.braceReceipts, [:])
        XCTAssertEqual(encounter.wardReceipts, [:])
        XCTAssertEqual(encounter.unyieldingSpent, [])
        XCTAssertTrue(CombatRules.skills(for: .binder, in: state).contains { $0.id == "brace" })
        XCTAssertTrue(CombatRules.skills(for: .binder, in: state).contains { $0.id == "ward" })

        let relaunched = try SaveCodec.decode(SaveCodec.encode(state))
        XCTAssertEqual(relaunched.worlds.activeRun?.healthCaps, state.worlds.activeRun?.healthCaps)
        XCTAssertEqual(relaunched.worlds.activeRun?.activeEncounter?
            .debugV2OwnedNodeIDs?[.binder], route)
        XCTAssertEqual(relaunched.worlds.activeRun?.activeEncounter?.braceReceipts, [:])
        XCTAssertEqual(relaunched.worlds.activeRun?.activeEncounter?.wardReceipts, [:])
        XCTAssertEqual(relaunched.worlds.activeRun?.activeEncounter?.unyieldingSpent, [])
    }

    func testEnduranceThresholdCrossingAndMinimumArePureAndFrozenMaximumAware() {
        let node = true
        XCTAssertEqual(CombatDerivedStatsRules.enduranceDamage(
            8, currentHP: 11, maximumHP: 20, eventMinimum: 1, ownsNode: node), 8)
        XCTAssertEqual(CombatDerivedStatsRules.enduranceDamage(
            8, currentHP: 10, maximumHP: 20, eventMinimum: 1, ownsNode: node), 6)
        XCTAssertEqual(CombatDerivedStatsRules.enduranceDamage(
            1, currentHP: 1, maximumHP: 26, eventMinimum: 1, ownsNode: node), 1)
        XCTAssertEqual(CombatDerivedStatsRules.enduranceDamage(
            0, currentHP: 1, maximumHP: 26, eventMinimum: 1, ownsNode: node), 0)
        XCTAssertEqual(CombatDerivedStatsRules.enduranceDamage(
            8, currentHP: 5, maximumHP: 26, eventMinimum: 1, ownsNode: false), 8)
    }

    func testUnyieldingAndEnduranceApplyOnCanonicalAfflictionTicksPersistAndDoNotRecharge() throws {
        let store = inFight()
        store.mutate("stage lethal status against exact survival owner") { state in
            guard var run = state.worlds.activeRun, var encounter = run.activeEncounter else { return }
            encounter.debugV2OwnedNodeIDs = [.binder: [CombatDerivedStatsRules.Node.endurance,
                                                       CombatDerivedStatsRules.Node.unyielding]]
            encounter.unyieldingSpent = []
            run.binderHP = 4
            _ = CombatRules.applyAffliction(.burn, to: .binder, source: .foe(encounter.foes[0].id),
                provenance: .direct, damage: 8, ticks: 2, targetIsStanding: true,
                encounter: &encounter)
            CombatRules.tickAfflictions(run: &run, encounter: &encounter)
            run.activeEncounter = encounter; state.worlds.activeRun = run
        }
        XCTAssertEqual(store.state.worlds.activeRun?.binderHP, 1)
        XCTAssertEqual(store.activeEncounter?.unyieldingSpent, [.binder])
        XCTAssertTrue(store.activeEncounter?.log.contains { $0.contains("Endurance") } == true)
        XCTAssertTrue(store.activeEncounter?.log.contains { $0.contains("Unyielding") } == true)

        let encoded = try JSONEncoder().encode(try XCTUnwrap(store.activeEncounter))
        var encounter = try JSONDecoder().decode(EncounterState.self, from: encoded)
        var run = try XCTUnwrap(store.state.worlds.activeRun)
        run.binderHP = 5 // healing does not restore the spent receipt
        CombatRules.tickAfflictions(run: &run, encounter: &encounter)
        XCTAssertEqual(run.binderHP, 0)
        XCTAssertEqual(encounter.unyieldingSpent, [.binder])
    }

    func testDebugGodModeFreezesAtEncounterOpenAndOnlyPreventsPartyDefeat() throws {
        let store = GameStore(io: .temporary(name: "god-mode-\(UUID().uuidString)"))
        store.write("plains")
        store.bindAndDepart()
        store.mutate("open God mode encounter") { state in
            guard var run = state.worlds.activeRun else { return }
            let enemy = WorldEnemy(id: .init(rawValue: 908_001), creatureID: "paper_moth",
                                   position: run.playerPosition, isAwake: true)
            run.enemies = [enemy]
            state.worlds.activeRun = run
            WorldRules.beginEncounter(triggeredBy: enemy, runsAutomaticTurns: false,
                                      debugGodModeEnabled: true, in: &state)
            guard var liveRun = state.worlds.activeRun,
                  var encounter = liveRun.activeEncounter else { return }
            liveRun.binderHP = 2
            _ = CombatRules.applyAffliction(.burn, to: .binder,
                source: .foe(enemy.id), provenance: .direct, damage: 8, ticks: 2,
                targetIsStanding: true, encounter: &encounter)
            CombatRules.tickAfflictions(run: &liveRun, encounter: &encounter)
            if encounter.order.contains(.companion(0)) {
                liveRun.companionHP[0] = 2
                _ = CombatRules.applyAffliction(.poison, to: .companion(0),
                    source: .foe(enemy.id), provenance: .direct, damage: 8, ticks: 1,
                    targetIsStanding: true, encounter: &encounter)
                CombatRules.tickAfflictions(run: &liveRun, encounter: &encounter)
            }
            liveRun.activeEncounter = encounter
            state.worlds.activeRun = liveRun
        }

        XCTAssertEqual(store.activeRun?.binderHP, 1)
        XCTAssertEqual(store.activeRun?.companionHP[0], 1)
        XCTAssertNil(store.activeEncounter?.outcome)
        XCTAssertEqual(store.activeEncounter?.debugGodMode?.preventedLethalDamageCount, 3,
                       "the Binder's remaining Burn tick and the companion's Poison stay ordinary lethal events")
        XCTAssertTrue(store.activeEncounter?.log.contains {
            $0.contains("God mode records lethal damage")
                && $0.contains("Combat-balance evidence for this encounter is invalid")
        } == true)
        let resumed = try JSONDecoder().decode(GameState.self,
                                                from: JSONEncoder().encode(store.state))
        XCTAssertEqual(resumed.worlds.activeRun?.activeEncounter?.debugGodMode,
                       store.activeEncounter?.debugGodMode)
    }

    func testDebugGodModeOffLeavesNextEncounterOrdinarilyDefeatable() throws {
        let store = inFight()
        store.mutate("stage ordinary lethal damage") { state in
            guard var run = state.worlds.activeRun, var encounter = run.activeEncounter else { return }
            encounter.debugGodMode = nil
            encounter.debugV2OwnedNodeIDs = [.binder: []]
            encounter.unyieldingSpent = []
            run.binderHP = 2
            _ = CombatRules.applyAffliction(.burn, to: .binder,
                source: .foe(encounter.foes[0].id), provenance: .direct, damage: 8, ticks: 1,
                targetIsStanding: true, encounter: &encounter)
            CombatRules.tickAfflictions(run: &run, encounter: &encounter)
            run.activeEncounter = encounter
            state.worlds.activeRun = run
            CombatRules.checkOutcome(in: &state)
        }
        XCTAssertEqual(store.activeRun?.binderHP, 0)
        XCTAssertEqual(store.activeEncounter?.outcome, .defeated)
    }

    func testSurvivalNodesAreExactOwnerAndEnabledEmptyParity() throws {
        var encounter = try XCTUnwrap(inFight().activeEncounter)
        encounter.debugV2OwnedNodeIDs = [.binder: [], .companion(0): []]
        encounter.unyieldingSpent = []
        let target: Combatant = .companion(0)
        _ = CombatRules.applyAffliction(.poison, to: target, source: .binder,
            provenance: .direct, damage: 2, ticks: 5, targetIsStanding: true,
            encounter: &encounter)
        XCTAssertEqual(encounter.afflictions?.first?.ticksRemaining, 5)
        XCTAssertEqual(encounter.unyieldingSpent, [])

        var exact = try XCTUnwrap(inFight().activeEncounter)
        exact.debugV2OwnedNodeIDs = [.binder: [CombatDerivedStatsRules.Node.constitution],
                                     .companion(0): []]
        _ = CombatRules.applyAffliction(.poison, to: target, source: .binder,
            provenance: .direct, damage: 2, ticks: 5, targetIsStanding: true,
            encounter: &exact)
        XCTAssertEqual(exact.afflictions?.first?.ticksRemaining, 5, "no party aura")
    }

    func testBraceAndEnduranceComposeOnceWithMinimum() {
        XCTAssertEqual(CombatDerivedStatsRules.survivalDamage(
            20, currentHP: 5, maximumHP: 20, eventMinimum: 1,
            ownsEndurance: true, braceApplies: true), 9)
        XCTAssertEqual(CombatDerivedStatsRules.survivalDamage(
            20, currentHP: 11, maximumHP: 20, eventMinimum: 1,
            ownsEndurance: true, braceApplies: true), 13)
        XCTAssertEqual(CombatDerivedStatsRules.survivalDamage(
            1, currentHP: 1, maximumHP: 20, eventMinimum: 1,
            ownsEndurance: true, braceApplies: true), 1)
        XCTAssertEqual(CombatDerivedStatsRules.survivalDamage(
            0, currentHP: 1, maximumHP: 20, eventMinimum: 1,
            ownsEndurance: true, braceApplies: true), 0)
    }

    func testBraceExactOwnerArmsPersistsAndQualifyingFoeSlotConsumes() throws {
        func staged(armed: Bool) -> GameStore {
            let store = inFight()
            store.mutate("stage exact Brace counterfactual") { state in
                guard var run = state.worlds.activeRun, var encounter = run.activeEncounter else { return }
                encounter.debugV2OwnedNodeIDs = [.binder: armed
                    ? [CombatDerivedStatsRules.Node.brace] : [], .companion(0): []]
                encounter.braceReceipts = [:]
                encounter.order = [.binder, .foe(encounter.foes[0].id), .companion(0)]
                encounter.turnSlots = encounter.order.map { .init(actor: $0) }
                encounter.turnIndex = 0
                run.activeEncounter = encounter; state.worlds.activeRun = run
            }
            if armed {
                store.mutate("arm Brace without advancing") {
                    CombatRules.perform(.skill("brace"), by: .binder, in: &$0)
                }
            }
            return store
        }
        func runHostileSlot(_ store: GameStore) {
            store.mutate("run the exact hostile slot") { state in
                guard var run = state.worlds.activeRun, var encounter = run.activeEncounter else { return }
                encounter.turnIndex = 1
                run.rng = SeededRNG(seed: 0xBACE)
                run.companionHP[0] = 0
                encounter.debugV2Evasion = .init(entries: [
                    .init(actor: .binder, characterEvasion: 0, components: [])
                ])
                encounter.ghostEvasionAvailable = []
                run.activeEncounter = encounter; state.worlds.activeRun = run
                CombatRules.runAutomaticTurns(in: &state)
            }
        }
        let store = staged(armed: true)
        let armed = try XCTUnwrap(store.activeEncounter?.braceReceipts?[.binder])
        XCTAssertFalse(armed.triggered)
        let reloaded = try JSONDecoder().decode(EncounterState.self,
            from: JSONEncoder().encode(try XCTUnwrap(store.activeEncounter)))
        XCTAssertEqual(reloaded.braceReceipts?[.binder], armed)

        let plain = staged(armed: false)
        let before = try XCTUnwrap(store.activeRun?.binderHP)
        runHostileSlot(store)
        runHostileSlot(plain)
        XCTAssertNil(store.activeEncounter?.braceReceipts?[.binder])
        let bracedLoss = before - (store.activeRun?.binderHP ?? before)
        let plainLoss = before - (plain.activeRun?.binderHP ?? before)
        XCTAssertEqual(bracedLoss, CombatDerivedStatsRules.survivalDamage(
            plainLoss, currentHP: before, maximumHP: store.activeRun?.healthCap(for: .binder)?.maximum
                ?? Tuning.Encounter.binderMaxHP, eventMinimum: 1,
            ownsEndurance: false, braceApplies: true))
        XCTAssertLessThan(bracedLoss, plainLoss)
    }

    func testBraceRejectsNonOwnerAndLegacyDurationRemainsParityAdapter() throws {
        let modern = inFight()
        modern.mutate("stage enabled empty Brace") { state in
            guard var run = state.worlds.activeRun, var encounter = run.activeEncounter else { return }
            encounter.debugV2OwnedNodeIDs = [.binder: []]
            encounter.braceReceipts = [:]
            run.activeEncounter = encounter; state.worlds.activeRun = run
        }
        modern.mutate("try unowned Brace") {
            CombatRules.perform(.skill("brace"), by: .binder, in: &$0)
        }
        XCTAssertTrue(modern.activeEncounter?.braceReceipts?.isEmpty == true)

        let legacy = inFight()
        legacy.mutate("stage legacy adapter") { state in
            guard var run = state.worlds.activeRun, var encounter = run.activeEncounter else { return }
            encounter.debugV2OwnedNodeIDs = nil
            encounter.braceReceipts = nil
            run.activeEncounter = encounter; state.worlds.activeRun = run
        }
        legacy.mutate("use legacy Brace") {
            CombatRules.perform(.skill("brace"), by: .binder, in: &$0)
        }
        XCTAssertGreaterThan(legacy.activeEncounter?.braced[.binder] ?? 0, 0)
    }

    func testModernWardRequiresExactOwnerAndDisclosedExplicitChoice() throws {
        let store = inFight()
        store.mutate("stage modern Ward") { state in
            guard var run = state.worlds.activeRun, var encounter = run.activeEncounter else { return }
            encounter.debugV2OwnedNodeIDs = [.binder: [CombatDerivedStatsRules.Node.ward],
                                               .companion(0): []]
            encounter.wardReceipts = [:]
            encounter.revealed.removeAll()
            encounter.order = [.binder, .companion(0), .foe(encounter.foes[0].id)]
            encounter.turnSlots = encounter.order.map { .init(actor: $0) }
            encounter.turnIndex = 0
            run.activeEncounter = encounter; state.worlds.activeRun = run
        }
        let initialCooldown = store.activeEncounter?.binderSkillCooldown
        store.takeCombatAction(.ward(.blow(.pierce)))
        XCTAssertTrue(store.activeEncounter?.wardReceipts?.isEmpty == true)
        XCTAssertEqual(store.activeEncounter?.binderSkillCooldown, initialCooldown)

        store.mutate("disclose exact foe") { state in
            guard var run = state.worlds.activeRun, var encounter = run.activeEncounter else { return }
            encounter.revealed.insert(encounter.foes[0].id)
            run.activeEncounter = encounter; state.worlds.activeRun = run
        }
        let disclosed = try XCTUnwrap(store.activeEncounter?.foes.first?.stats.damageKind)
        store.takeCombatAction(.ward(.blow(disclosed)))
        let receipt = try XCTUnwrap(store.activeEncounter?.wardReceipts?[.binder])
        XCTAssertEqual(receipt.harm, .blow(disclosed))
        XCTAssertEqual(receipt.activationRound, 1)
        XCTAssertEqual(receipt.expiresBeforeRound, 3)
        XCTAssertTrue(store.activeEncounter?.log.contains {
            $0.contains(disclosed.rawValue) && $0.contains("round 2")
        } == true)
    }

    func testModernWardReplacementRelaunchAndLegacySkillDoNotInfer() throws {
        let store = inFight()
        store.mutate("stage modern Ward replacement") { state in
            guard var run = state.worlds.activeRun, var encounter = run.activeEncounter else { return }
            encounter.debugV2OwnedNodeIDs = [.binder: [CombatDerivedStatsRules.Node.ward]]
            encounter.wardReceipts = [.binder: .init(harm: .blow(.crush), activationRound: 4,
                                                       expiresBeforeRound: 6)]
            encounter.roundNumber = 5
            encounter.revealed = Set(encounter.foes.map(\.id))
            encounter.order = [.binder, .foe(encounter.foes[0].id)]
            encounter.turnSlots = encounter.order.map { .init(actor: $0) }
            encounter.turnIndex = 0
            run.activeEncounter = encounter; state.worlds.activeRun = run
        }
        store.mutate("legacy unquoted Ward must reject") {
            CombatRules.perform(.skill("ward"), by: .binder, in: &$0)
        }
        XCTAssertEqual(store.activeEncounter?.wardReceipts?[.binder]?.harm, .blow(.crush))

        let harm = Harm.blow(try XCTUnwrap(store.activeEncounter?.foes.first?.stats.damageKind))
        store.mutate("replace modern Ward") { CombatRules.perform(.ward(harm), by: .binder, in: &$0) }
        let replaced = try XCTUnwrap(store.activeEncounter?.wardReceipts?[.binder])
        XCTAssertEqual(replaced, .init(harm: harm, activationRound: 5, expiresBeforeRound: 7))
        let reloaded = try JSONDecoder().decode(EncounterState.self,
            from: JSONEncoder().encode(try XCTUnwrap(store.activeEncounter)))
        XCTAssertEqual(reloaded.wardReceipts?[.binder], replaced)
    }

    func testWardGambitUsesOnlyDisclosedHarmAndLegacyReceiptRemainsLegacy() throws {
        let store = inFight(gambits: [Self.useSkill])
        store.mutate("stage Ward gambit query") { state in
            guard var run = state.worlds.activeRun, var encounter = run.activeEncounter else { return }
            encounter.debugV2OwnedNodeIDs = [.companion(0): [CombatDerivedStatsRules.Node.ward]]
            encounter.wardReceipts = [:]
            encounter.revealed.removeAll()
            run.activeEncounter = encounter; state.worlds.activeRun = run
        }
        XCTAssertNil(store.activeEncounter.flatMap(CombatRules.recommendedWardHarm))
        store.mutate("disclose for Ward gambit") { state in
            guard var run = state.worlds.activeRun, var encounter = run.activeEncounter else { return }
            encounter.revealed = Set(encounter.foes.map(\.id))
            run.activeEncounter = encounter; state.worlds.activeRun = run
        }
        let expected = try XCTUnwrap(store.activeEncounter?.foes.first).stats.element
            .map(Harm.emanation) ?? .blow(try XCTUnwrap(store.activeEncounter?.foes.first).stats.damageKind)
        XCTAssertEqual(store.activeEncounter.flatMap(CombatRules.recommendedWardHarm), expected)
        XCTAssertEqual(GambitEngine.decide(for: .companion(0), in: store.state)?.action,
                       .ward(expected))

        var legacy = try XCTUnwrap(store.activeEncounter)
        legacy.debugV2OwnedNodeIDs = nil
        legacy.wardReceipts = nil
        legacy.wards[.binder] = .init(against: .blow(.rend), rounds: 2)
        let decoded = try JSONDecoder().decode(EncounterState.self, from: JSONEncoder().encode(legacy))
        XCTAssertNil(decoded.wardReceipts)
        XCTAssertEqual(decoded.wards[.binder], legacy.wards[.binder])
    }

    func testModernSnuffRequiresExactOwnerDisclosedLiveEmanationAndRejectsFullRefresh() throws {
        var burning = CreatureTraits()
        burning.size = 80; burning.build = 70
        burning.emanation = emanation(of: .heat)
        burning.armament.setTotal(60)
        let store = inFightWith([burning])
        let foeID = try XCTUnwrap(store.activeEncounter?.foes.first?.id)
        store.mutate("stage modern Snuff") { state in
            guard var run = state.worlds.activeRun, var encounter = run.activeEncounter else { return }
            encounter.debugV2OwnedNodeIDs = [.companion(0): [CombatDerivedStatsRules.Node.snuff],
                                               .binder: []]
            encounter.snuffReceipts = [:]
            encounter.revealed.removeAll()
            encounter.order = [.companion(0), .foe(foeID), .binder]
            encounter.turnSlots = encounter.order.map { .init(actor: $0) }
            encounter.turnIndex = 0
            run.activeEncounter = encounter; state.worlds.activeRun = run
        }
        store.mutate("hidden Snuff rejects") {
            CombatRules.perform(.skill("snuff", foe: foeID), by: .companion(0), in: &$0)
        }
        XCTAssertTrue(store.activeEncounter?.snuffReceipts?.isEmpty == true)
        XCTAssertEqual(store.activeEncounter?.companionSkillCooldown, 0)

        store.mutate("disclose and Snuff") { state in
            guard var run = state.worlds.activeRun, var encounter = run.activeEncounter else { return }
            encounter.revealed.insert(foeID)
            encounter.debugV2OwnedNodeIDs?[.companion(0)] = []
            run.activeEncounter = encounter; state.worlds.activeRun = run
            CombatRules.perform(.skill("snuff", foe: foeID), by: .companion(0), in: &state)
        }
        XCTAssertTrue(store.activeEncounter?.snuffReceipts?.isEmpty == true)
        store.mutate("grant exact owner and Snuff") { state in
            guard var run = state.worlds.activeRun, var encounter = run.activeEncounter else { return }
            encounter.debugV2OwnedNodeIDs?[.companion(0)] = [CombatDerivedStatsRules.Node.snuff]
            run.activeEncounter = encounter; state.worlds.activeRun = run
            CombatRules.perform(.skill("snuff", foe: foeID), by: .companion(0), in: &state)
        }
        XCTAssertEqual(store.activeEncounter?.snuffReceipts?[foeID],
                       .init(remainingScheduledTurns: 2, suppressedRound: nil))

        store.mutate("try full refresh without spending") { state in
            guard var run = state.worlds.activeRun, var encounter = run.activeEncounter else { return }
            encounter.turnIndex = 0
            encounter.cooldowns.removeAll(); encounter.companionSkillCooldown = 0
            run.activeEncounter = encounter; state.worlds.activeRun = run
            CombatRules.perform(.skill("snuff", foe: foeID), by: .companion(0), in: &state)
        }
        XCTAssertEqual(store.activeEncounter?.snuffReceipts?[foeID],
                       .init(remainingScheduledTurns: 2, suppressedRound: nil))
        XCTAssertEqual(store.activeEncounter?.companionSkillCooldown, 0)
    }

    func testModernSnuffSuppressesCompleteScheduledTurnAndPersistsBetweenSlots() throws {
        var burning = CreatureTraits()
        burning.size = 80; burning.build = 70
        burning.emanation = emanation(of: .heat)
        burning.armament.setTotal(60)
        let store = inFightWith([burning])
        let foeID = try XCTUnwrap(store.activeEncounter?.foes.first?.id)
        store.mutate("stage interleaved Snuff block") { state in
            guard var run = state.worlds.activeRun, var encounter = run.activeEncounter else { return }
            encounter.debugV2OwnedNodeIDs = [.companion(0): [CombatDerivedStatsRules.Node.snuff]]
            encounter.snuffReceipts = [foeID: .init(remainingScheduledTurns: 2, suppressedRound: nil)]
            encounter.debugV2Evasion = .init(entries: CombatRules.party(of: state).map {
                .init(actor: $0, characterEvasion: 0, components: [])
            })
            encounter.ghostEvasionAvailable = []
            encounter.order = [.foe(foeID), .binder, .companion(0)]
            encounter.turnSlots = [
                .init(actor: .foe(foeID)), .init(actor: .binder),
                .init(actor: .foe(foeID), kind: .ordinaryPressureFollowUp(1),
                      strengthMultiplier: 0.55, suppressesAfflictions: true),
                .init(actor: .binder)
            ]
            encounter.turnIndex = 0
            run.rng = SeededRNG(seed: 0x5A11)
            run.activeEncounter = encounter; state.worlds.activeRun = run
        }
        store.mutate("resolve primary Snuffed slot") { state in
            CombatRules.runAutomaticTurns(in: &state)
        }
        let betweenSlots = try XCTUnwrap(store.activeEncounter?.snuffReceipts?[foeID])
        XCTAssertEqual(betweenSlots.remainingScheduledTurns, 2)
        XCTAssertEqual(betweenSlots.suppressedRound, store.activeEncounter?.roundNumber)
        let midBlockReload = try JSONDecoder().decode(EncounterState.self,
            from: JSONEncoder().encode(try XCTUnwrap(store.activeEncounter)))
        XCTAssertEqual(midBlockReload.snuffReceipts?[foeID], betweenSlots)
        store.mutate("resolve saved Snuffed follow-up") { state in
            guard var run = state.worlds.activeRun, var encounter = run.activeEncounter else { return }
            encounter.turnIndex = 2
            run.activeEncounter = encounter; state.worlds.activeRun = run
            CombatRules.runAutomaticTurns(in: &state)
        }
        let receipt = try XCTUnwrap(store.activeEncounter?.snuffReceipts?[foeID])
        XCTAssertEqual(receipt.remainingScheduledTurns, 1)
        XCTAssertNil(receipt.suppressedRound)
        XCTAssertFalse((store.activeEncounter?.afflictions ?? []).contains { $0.kind == .burn })
        let reloaded = try JSONDecoder().decode(EncounterState.self,
            from: JSONEncoder().encode(try XCTUnwrap(store.activeEncounter)))
        XCTAssertEqual(reloaded.snuffReceipts?[foeID], receipt)
    }

    func testLegacySnuffSetRemainsFrozenAdapterAndModernEmptyDoesNotInfer() throws {
        var encounter = try XCTUnwrap(inFight().activeEncounter)
        let foeID = try XCTUnwrap(encounter.foes.first?.id)
        encounter.debugV2OwnedNodeIDs = nil
        encounter.snuffReceipts = nil
        encounter.snuffed = [foeID]
        let legacy = try JSONDecoder().decode(EncounterState.self,
            from: JSONEncoder().encode(encounter))
        XCTAssertNil(legacy.snuffReceipts)
        XCTAssertTrue(CombatRules.isSnuffed(foeID, in: legacy))

        encounter.debugV2OwnedNodeIDs = [:]
        encounter.snuffReceipts = [:]
        let modern = try JSONDecoder().decode(EncounterState.self,
            from: JSONEncoder().encode(encounter))
        XCTAssertFalse(CombatRules.isSnuffed(foeID, in: modern))
    }

    func testModernQuenchRemovesOnlyExactSelectedEligibleReceipt() throws {
        let store = inFight()
        store.mutate("stage exact Quench choices") { state in
            guard var run = state.worlds.activeRun, var encounter = run.activeEncounter else { return }
            encounter.debugV2OwnedNodeIDs = [.companion(0): [CombatDerivedStatsRules.Node.quench],
                                               .binder: []]
            encounter.afflictions = []
            _ = CombatRules.applyAffliction(.burn, to: .binder, source: nil,
                provenance: .environment, damage: 3, ticks: 3, targetIsStanding: true,
                encounter: &encounter)
            _ = CombatRules.applyAffliction(.poison, to: .binder, source: nil,
                provenance: .environment, damage: 2, ticks: 4, targetIsStanding: true,
                encounter: &encounter)
            _ = CombatRules.applyAffliction(.bleed, to: .binder, source: nil,
                provenance: .environment, damage: 2, ticks: 3, targetIsStanding: true,
                encounter: &encounter)
            encounter.order = [.companion(0), .binder, .foe(encounter.foes[0].id)]
            encounter.turnSlots = encounter.order.map { .init(actor: $0) }
            encounter.turnIndex = 0
            run.activeEncounter = encounter; state.worlds.activeRun = run
        }
        let poison = try XCTUnwrap(store.activeEncounter?.afflictions?.first { $0.kind == .poison })
        XCTAssertEqual(store.activeEncounter?.current, .companion(0))
        XCTAssertNil(store.actingCombatant,
                     "the exact Quench picker, not a general companion override, owns this input")
        store.takeCombatAction(.quench(ally: .binder, afflictionReceipt: poison.applicationReceipt))
        let remaining = store.activeEncounter?.afflictions ?? []
        XCTAssertFalse(remaining.contains { $0.applicationReceipt == poison.applicationReceipt })
        XCTAssertTrue(remaining.contains { $0.kind == .burn })
        XCTAssertTrue(remaining.contains { $0.kind == .bleed })
        XCTAssertGreaterThan(store.activeEncounter?.companionSkillCooldown ?? 0, 0)
    }

    func testModernQuenchRejectsStaleBleedWrongTargetAndUnownedAtomically() throws {
        let store = inFight()
        store.mutate("stage rejected Quench") { state in
            guard var run = state.worlds.activeRun, var encounter = run.activeEncounter else { return }
            encounter.debugV2OwnedNodeIDs = [.companion(0): [CombatDerivedStatsRules.Node.quench]]
            encounter.afflictions = []
            _ = CombatRules.applyAffliction(.bleed, to: .binder, source: nil,
                provenance: .environment, damage: 2, ticks: 3, targetIsStanding: true,
                encounter: &encounter)
            encounter.order = [.companion(0), .binder, .foe(encounter.foes[0].id)]
            encounter.turnSlots = encounter.order.map { .init(actor: $0) }
            encounter.turnIndex = 0
            run.activeEncounter = encounter; state.worlds.activeRun = run
        }
        let bleed = try XCTUnwrap(store.activeEncounter?.afflictions?.first)
        XCTAssertEqual(store.activeEncounter?.current, .companion(0))
        XCTAssertNil(store.actingCombatant)
        let before = store.activeEncounter
        for receipt in [bleed.applicationReceipt, UInt64.max] {
            store.takeCombatAction(.quench(ally: .binder, afflictionReceipt: receipt))
            XCTAssertEqual(store.activeEncounter, before)
        }
        store.mutate("remove exact ownership") { state in
            state.worlds.activeRun?.activeEncounter?.debugV2OwnedNodeIDs?[.companion(0)] = []
        }
        store.takeCombatAction(.quench(ally: .binder, afflictionReceipt: bleed.applicationReceipt))
        XCTAssertEqual(store.activeEncounter?.afflictions, before?.afflictions)
    }

    func testQuenchGambitChoosesSoleExactRowButNotMultipleAndCooldownMigrates() throws {
        let store = inFight(gambits: [Self.useSkill])
        store.mutate("stage sole Quench gambit") { state in
            guard var run = state.worlds.activeRun, var encounter = run.activeEncounter else { return }
            encounter.debugV2OwnedNodeIDs = [.companion(0): [CombatDerivedStatsRules.Node.quench]]
            encounter.afflictions = []
            _ = CombatRules.applyAffliction(.dazzle, to: .companion(0), source: nil,
                provenance: .environment, damage: 0, ticks: 2, targetIsStanding: true,
                encounter: &encounter)
            run.activeEncounter = encounter; state.worlds.activeRun = run
        }
        let row = try XCTUnwrap(store.activeEncounter?.afflictions?.first)
        XCTAssertEqual(GambitEngine.decide(for: .companion(0), in: store.state)?.action,
                       .quench(ally: .companion(0), afflictionReceipt: row.applicationReceipt))
        store.mutate("stage legacy Quench cooldown key") {
            $0.worlds.activeRun?.activeEncounter?.cooldowns["companion-0|steady"] = 1
        }
        XCTAssertEqual(CombatRules.cooldown(of: try XCTUnwrap(ContentCatalog.shared.skill("quench")),
                                             for: .companion(0),
                                             in: try XCTUnwrap(store.activeEncounter)), 1)
        store.mutate("add second Quench choice") { state in
            guard var encounter = state.worlds.activeRun?.activeEncounter else { return }
            _ = CombatRules.applyAffliction(.burn, to: .companion(0), source: nil,
                provenance: .environment, damage: 3, ticks: 2, targetIsStanding: true,
                encounter: &encounter)
            encounter.cooldowns.removeAll()
            state.worlds.activeRun?.activeEncounter = encounter
        }
        XCTAssertNil(GambitEngine.decide(for: .companion(0), in: store.state))
    }

    func testLegacySteadyRemainsLegacyOnlyAndModernUnquotedActionRejects() throws {
        let modern = inFight()
        modern.mutate("stage modern legacy-action rejection") { state in
            guard var run = state.worlds.activeRun, var encounter = run.activeEncounter else { return }
            encounter.debugV2OwnedNodeIDs = [.companion(0): [CombatDerivedStatsRules.Node.quench]]
            encounter.afflictions = []
            _ = CombatRules.applyAffliction(.burn, to: .binder, source: nil,
                provenance: .environment, damage: 3, ticks: 2, targetIsStanding: true,
                encounter: &encounter)
            encounter.order = [.companion(0), .binder, .foe(encounter.foes[0].id)]
            encounter.turnSlots = encounter.order.map { .init(actor: $0) }; encounter.turnIndex = 0
            run.activeEncounter = encounter; state.worlds.activeRun = run
        }
        let before = modern.activeEncounter
        XCTAssertFalse(CombatRules.skills(for: .companion(0), in: modern.state).contains { $0.id == "steady" })
        XCTAssertTrue(CombatRules.skills(for: .companion(0), in: modern.state).contains { $0.id == "quench" })
        modern.mutate("try decode-only Steady") {
            CombatRules.perform(.skill("steady", ally: .binder), by: .companion(0), in: &$0)
        }
        XCTAssertEqual(modern.activeEncounter, before)

        let legacy = inFight()
        legacy.mutate("stage legacy Steady") { state in
            guard var run = state.worlds.activeRun, var encounter = run.activeEncounter else { return }
            encounter.debugV2OwnedNodeIDs = nil
            encounter.afflictions = []
            _ = CombatRules.applyAffliction(.burn, to: .binder, source: nil,
                provenance: .environment, damage: 3, ticks: 2, targetIsStanding: true,
                encounter: &encounter)
            encounter.order = [.companion(0), .binder, .foe(encounter.foes[0].id)]
            encounter.turnSlots = encounter.order.map { .init(actor: $0) }; encounter.turnIndex = 0
            run.activeEncounter = encounter; state.worlds.activeRun = run
            CombatRules.perform(.skill("steady", ally: .binder), by: .companion(0), in: &state)
        }
        XCTAssertTrue((legacy.activeEncounter?.afflictions ?? []).isEmpty)
    }

    func testModernInterposeRequiresExactOwnerAndQueuesIndependentReceipts() throws {
        let store = inFight()
        store.mutate("stage modern Interpose") { state in
            guard var run = state.worlds.activeRun, var encounter = run.activeEncounter else { return }
            encounter.debugV2OwnedNodeIDs = [.binder: [],
                                               .companion(0): [CombatDerivedStatsRules.Node.interpose]]
            encounter.interposeReceipts = []
            encounter.order = [.binder, .companion(0), .foe(encounter.foes[0].id)]
            encounter.turnSlots = encounter.order.map { .init(actor: $0) }
            encounter.turnIndex = 0
            run.activeEncounter = encounter; state.worlds.activeRun = run
        }
        let before = store.activeEncounter
        store.mutate("unowned Interpose rejects") {
            CombatRules.perform(.skill("interpose"), by: .binder, in: &$0)
        }
        XCTAssertEqual(store.activeEncounter, before)
        store.mutate("two exact owners Interpose") { state in
            guard var run = state.worlds.activeRun, var encounter = run.activeEncounter else { return }
            encounter.debugV2OwnedNodeIDs?[.binder] = [CombatDerivedStatsRules.Node.interpose]
            encounter.turnIndex = 0
            run.activeEncounter = encounter; state.worlds.activeRun = run
            CombatRules.perform(.skill("interpose"), by: .binder, in: &state)
            guard var updated = state.worlds.activeRun?.activeEncounter else { return }
            updated.cooldowns.removeAll(); updated.binderSkillCooldown = 0
            updated.turnIndex = 1
            state.worlds.activeRun?.activeEncounter = updated
            CombatRules.perform(.skill("interpose"), by: .companion(0), in: &state)
        }
        XCTAssertEqual(store.activeEncounter?.interposeReceipts?.map(\.activationSequence), [1, 2])
        XCTAssertEqual(store.activeEncounter?.nextInterposeActivationSequence, 3)
        store.mutate("same owner replaces their queued Interpose") { state in
            guard var run = state.worlds.activeRun, var encounter = run.activeEncounter else { return }
            encounter.turnIndex = 1
            encounter.cooldowns.removeAll(); encounter.companionSkillCooldown = 0
            run.activeEncounter = encounter; state.worlds.activeRun = run
            CombatRules.perform(.skill("interpose"), by: .companion(0), in: &state)
        }
        XCTAssertEqual(store.activeEncounter?.interposeReceipts?.map(\.activationSequence), [1, 3])
        XCTAssertTrue(CombatRules.skills(for: .binder, in: store.state).contains { $0.id == "interpose" })
    }

    func testInterposeReplacesFinalTargetBeforeGhostAndConsumesOnMissAcrossRelaunch() throws {
        let store = inFight()
        let foeID = try XCTUnwrap(store.activeEncounter?.foes.first?.id)
        store.mutate("stage exact Interpose miss") { state in
            guard var run = state.worlds.activeRun, var encounter = run.activeEncounter else { return }
            encounter.debugV2OwnedNodeIDs = [.companion(0): [CombatDerivedStatsRules.Node.interpose]]
            encounter.interposeReceipts = [.init(owner: .companion(0), activationSequence: 7)]
            encounter.nextInterposeActivationSequence = 8
            encounter.drawOffReceipts = [foeID: .init(owner: .binder, activationRound: 1,
                                                       expiresBeforeRound: 3)]
            encounter.concealed[.companion(0)] = 2
            encounter.ghostEvasionAvailable = [.companion(0)]
            encounter.order = [.foe(foeID), .binder, .companion(0)]
            encounter.turnSlots = encounter.order.map { .init(actor: $0) }
            encounter.turnIndex = 0
            run.activeEncounter = encounter; state.worlds.activeRun = run
        }
        let encoded = try JSONEncoder().encode(try XCTUnwrap(store.activeEncounter))
        let decoded = try JSONDecoder().decode(EncounterState.self, from: encoded)
        XCTAssertEqual(decoded.interposeReceipts, store.activeEncounter?.interposeReceipts)
        let binderBefore = try XCTUnwrap(store.activeRun?.binderHP)
        let companionBefore = try XCTUnwrap(store.activeRun?.companionHP[0])
        store.mutate("resolve redirected miss") { CombatRules.runAutomaticTurns(in: &$0) }
        XCTAssertEqual(store.activeRun?.binderHP, binderBefore)
        XCTAssertEqual(store.activeRun?.companionHP[0], companionBefore)
        XCTAssertTrue(store.activeEncounter?.interposeReceipts?.isEmpty == true)
        XCTAssertFalse(store.activeEncounter?.ghostEvasionAvailable?.contains(.companion(0)) == true)
        XCTAssertNil(store.activeEncounter?.concealed[.companion(0)])
    }

    func testInterposeDoesNotConsumeForAreaAndLegacyDurationRemainsLegacy() throws {
        let store = inFight()
        let foeID = try XCTUnwrap(store.activeEncounter?.foes.first?.id)
        store.mutate("stage area Interpose exclusion") { state in
            guard var run = state.worlds.activeRun, var encounter = run.activeEncounter else { return }
            encounter.debugV2OwnedNodeIDs = [.companion(0): [CombatDerivedStatsRules.Node.interpose]]
            encounter.interposeReceipts = [.init(owner: .companion(0), activationSequence: 1)]
            if let index = encounter.foes.firstIndex(where: { $0.id == foeID }) {
                encounter.foes[index].stats.delivery = .area
            }
            encounter.debugV2Evasion = .init(entries: CombatRules.party(of: state).map {
                .init(actor: $0, characterEvasion: 0, components: [])
            })
            encounter.ghostEvasionAvailable = []
            encounter.order = [.foe(foeID), .binder, .companion(0)]
            encounter.turnSlots = encounter.order.map { .init(actor: $0) }; encounter.turnIndex = 0
            run.activeEncounter = encounter; state.worlds.activeRun = run
        }
        store.mutate("resolve area without Interpose") { CombatRules.runAutomaticTurns(in: &$0) }
        XCTAssertEqual(store.activeEncounter?.interposeReceipts?.count, 1)

        var legacy = try XCTUnwrap(store.activeEncounter)
        legacy.debugV2OwnedNodeIDs = nil
        legacy.interposeReceipts = nil
        legacy.interposing[.binder] = 2
        let decoded = try JSONDecoder().decode(EncounterState.self,
            from: JSONEncoder().encode(legacy))
        XCTAssertNil(decoded.interposeReceipts)
        XCTAssertEqual(decoded.interposing[.binder], 2)
    }

    func testGuardianFiltersSingleTargetFarReachToVisibleFrontWithoutAura() throws {
        let store = inFight()
        store.mutate("stage Guardian target set") { state in
            guard var run = state.worlds.activeRun, var encounter = run.activeEncounter else { return }
            encounter.debugV2OwnedNodeIDs = [
                .binder: [CombatDerivedStatsRules.Node.guardian], .companion(0): []
            ]
            encounter.partyRanks = [.binder: .front, .companion(0): .back]
            run.activeEncounter = encounter; state.worlds.activeRun = run
        }
        let encounter = try XCTUnwrap(store.activeEncounter)
        let run = try XCTUnwrap(store.activeRun)
        XCTAssertEqual(CombatRules.guardianFilteredTargets([.binder, .companion(0)],
            isSingleTargetDirect: true, run: run, encounter: encounter, state: store.state), [.binder])
        XCTAssertEqual(CombatRules.guardianFilteredTargets([.binder, .companion(0)],
            isSingleTargetDirect: false, run: run, encounter: encounter, state: store.state),
                       [.binder, .companion(0)])

        var noOwner = encounter
        noOwner.debugV2OwnedNodeIDs?[.binder] = []
        XCTAssertEqual(CombatRules.guardianFilteredTargets([.binder, .companion(0)],
            isSingleTargetDirect: true, run: run, encounter: noOwner, state: store.state),
                       [.binder, .companion(0)])
    }

    func testGuardianRequiresConsciousVisibleFrontOwnerAndSurvivesRelaunch() throws {
        let store = inFight()
        store.mutate("stage Guardian consciousness") { state in
            guard var run = state.worlds.activeRun, var encounter = run.activeEncounter else { return }
            encounter.debugV2OwnedNodeIDs = [
                .companion(0): [CombatDerivedStatsRules.Node.guardian], .binder: []
            ]
            encounter.partyRanks = [.companion(0): .front, .binder: .back]
            run.activeEncounter = encounter; state.worlds.activeRun = run
        }
        let encoded = try JSONEncoder().encode(try XCTUnwrap(store.activeEncounter))
        let reloaded = try JSONDecoder().decode(EncounterState.self, from: encoded)
        let run = try XCTUnwrap(store.activeRun)
        XCTAssertEqual(CombatRules.guardianFilteredTargets([.binder, .companion(0)],
            isSingleTargetDirect: true, run: run, encounter: reloaded, state: store.state),
                       [.companion(0)])

        var passedOut = run
        passedOut.companionHP[0] = 0
        XCTAssertEqual(CombatRules.guardianFilteredTargets([.binder, .companion(0)],
            isSingleTargetDirect: true, run: passedOut, encounter: reloaded, state: store.state),
                       [.binder, .companion(0)])
        var backOwner = reloaded
        backOwner.partyRanks[.companion(0)] = .back
        XCTAssertEqual(CombatRules.guardianFilteredTargets([.binder, .companion(0)],
            isSingleTargetDirect: true, run: run, encounter: backOwner, state: store.state),
                       [.binder, .companion(0)])
    }

    func testGuardianProductionPreventsIllegalLegacyTauntButNotAreaIntent() throws {
        let store = inFight()
        let foeID = try XCTUnwrap(store.activeEncounter?.foes.first?.id)
        store.mutate("stage Guardian against taunt") { state in
            guard var run = state.worlds.activeRun, var encounter = run.activeEncounter else { return }
            encounter.debugV2OwnedNodeIDs = [
                .companion(0): [CombatDerivedStatsRules.Node.guardian], .binder: []
            ]
            encounter.partyRanks = [.companion(0): .front, .binder: .back]
            encounter.taunts[foeID] = 2
            encounter.debugV2Evasion = .init(entries: CombatRules.party(of: state).map {
                .init(actor: $0, characterEvasion: 0, components: [])
            })
            encounter.ghostEvasionAvailable = []
            encounter.order = [.foe(foeID), .binder, .companion(0)]
            encounter.turnSlots = encounter.order.map { .init(actor: $0) }; encounter.turnIndex = 0
            run.rng = SeededRNG(seed: 0x6A12)
            run.activeEncounter = encounter; state.worlds.activeRun = run
        }
        let binderBefore = try XCTUnwrap(store.activeRun?.binderHP)
        let companionBefore = try XCTUnwrap(store.activeRun?.companionHP[0])
        store.mutate("resolve Guardian-filtered foe") { CombatRules.runAutomaticTurns(in: &$0) }
        XCTAssertEqual(store.activeRun?.binderHP, binderBefore)
        XCTAssertLessThan(store.activeRun?.companionHP[0] ?? companionBefore, companionBefore)
    }

    func testModernDrawOffRequiresExactOwnerDisclosedFoeAndEndsConceal() throws {
        let store = inFight()
        let foeID = try XCTUnwrap(store.activeEncounter?.foes.first?.id)
        store.mutate("stage modern Draw Off") { state in
            guard var run = state.worlds.activeRun, var encounter = run.activeEncounter else { return }
            encounter.debugV2OwnedNodeIDs = [.companion(0): [CombatDerivedStatsRules.Node.drawOff],
                                               .binder: []]
            encounter.drawOffReceipts = [:]
            encounter.concealed[.companion(0)] = 2
            encounter.revealed.removeAll()
            encounter.order = [.companion(0), .binder, .foe(foeID)]
            encounter.turnSlots = encounter.order.map { .init(actor: $0) }; encounter.turnIndex = 0
            run.activeEncounter = encounter; state.worlds.activeRun = run
        }
        let before = store.activeEncounter
        store.mutate("hidden Draw Off rejects") {
            CombatRules.perform(.skill("draw_off", foe: foeID), by: .companion(0), in: &$0)
        }
        XCTAssertEqual(store.activeEncounter, before)
        store.mutate("disclose and Draw Off") { state in
            guard var run = state.worlds.activeRun, var encounter = run.activeEncounter else { return }
            encounter.revealed.insert(foeID)
            run.activeEncounter = encounter; state.worlds.activeRun = run
            CombatRules.perform(.skill("draw_off", foe: foeID), by: .companion(0), in: &state)
        }
        XCTAssertEqual(store.activeEncounter?.drawOffReceipts?[foeID],
                       .init(owner: .companion(0), activationRound: 1, expiresBeforeRound: 3))
        XCTAssertNil(store.activeEncounter?.concealed[.companion(0)])
        XCTAssertTrue(CombatRules.skills(for: .companion(0), in: store.state).contains { $0.id == "draw_off" })
    }

    func testDrawOffExactCompanionOverridesPrimaryAndSurvivesRelaunch() throws {
        let store = inFight()
        let foeID = try XCTUnwrap(store.activeEncounter?.foes.first?.id)
        store.mutate("stage exact Draw Off target") { state in
            guard var run = state.worlds.activeRun, var encounter = run.activeEncounter else { return }
            encounter.debugV2OwnedNodeIDs = [.companion(0): [CombatDerivedStatsRules.Node.drawOff]]
            encounter.drawOffReceipts = [foeID: .init(owner: .companion(0), activationRound: 1,
                                                       expiresBeforeRound: 3)]
            encounter.partyRanks = [.binder: .front, .companion(0): .front]
            encounter.debugV2Evasion = .init(entries: CombatRules.party(of: state).map {
                .init(actor: $0, characterEvasion: 0, components: [])
            })
            encounter.ghostEvasionAvailable = []
            encounter.order = [.foe(foeID), .binder, .companion(0)]
            encounter.turnSlots = encounter.order.map { .init(actor: $0) }; encounter.turnIndex = 0
            run.rng = SeededRNG(seed: 0xD2A0)
            run.activeEncounter = encounter; state.worlds.activeRun = run
        }
        let decoded = try JSONDecoder().decode(EncounterState.self,
            from: JSONEncoder().encode(try XCTUnwrap(store.activeEncounter)))
        XCTAssertEqual(decoded.drawOffReceipts, store.activeEncounter?.drawOffReceipts)
        let binderBefore = try XCTUnwrap(store.activeRun?.binderHP)
        let companionBefore = try XCTUnwrap(store.activeRun?.companionHP[0])
        store.mutate("resolve exact Draw Off") { CombatRules.runAutomaticTurns(in: &$0) }
        XCTAssertEqual(store.activeRun?.binderHP, binderBefore)
        XCTAssertLessThan(store.activeRun?.companionHP[0] ?? companionBefore, companionBefore)
    }

    func testDrawOffIllegalOwnerFallsBackAndGlobalExpiryIsExact() throws {
        let store = inFight()
        let foeID = try XCTUnwrap(store.activeEncounter?.foes.first?.id)
        store.mutate("stage illegal back Draw Off") { state in
            guard var run = state.worlds.activeRun, var encounter = run.activeEncounter else { return }
            encounter.debugV2OwnedNodeIDs = [.companion(0): [CombatDerivedStatsRules.Node.drawOff],
                                               .binder: []]
            encounter.drawOffReceipts = [foeID: .init(owner: .companion(0), activationRound: 1,
                                                       expiresBeforeRound: 3)]
            encounter.partyRanks = [.binder: .front, .companion(0): .back]
            encounter.order = [.foe(foeID), .binder, .companion(0)]
            encounter.turnSlots = encounter.order.map { .init(actor: $0) }; encounter.turnIndex = 0
            encounter.debugV2Evasion = .init(entries: CombatRules.party(of: state).map {
                .init(actor: $0, characterEvasion: 0, components: [])
            })
            encounter.ghostEvasionAvailable = []
            run.activeEncounter = encounter; state.worlds.activeRun = run
        }
        let binderBefore = try XCTUnwrap(store.activeRun?.binderHP)
        let companionBefore = try XCTUnwrap(store.activeRun?.companionHP[0])
        store.mutate("fallback from illegal Draw Off") { CombatRules.runAutomaticTurns(in: &$0) }
        XCTAssertLessThan(store.activeRun?.binderHP ?? binderBefore, binderBefore)
        XCTAssertEqual(store.activeRun?.companionHP[0], companionBefore)

        var encounter = try XCTUnwrap(store.activeEncounter)
        encounter.roundNumber = 3
        encounter.drawOffReceipts = encounter.drawOffReceipts?.filter {
            $0.value.expiresBeforeRound > encounter.roundNumber
        }
        XCTAssertTrue(encounter.drawOffReceipts?.isEmpty == true)

        encounter.debugV2OwnedNodeIDs = nil
        encounter.drawOffReceipts = nil
        encounter.taunts[foeID] = 2
        let legacy = try JSONDecoder().decode(EncounterState.self,
            from: JSONEncoder().encode(encounter))
        XCTAssertNil(legacy.drawOffReceipts)
        XCTAssertEqual(legacy.taunts[foeID], 2)
    }

    func testCoverAllocatesFinalIntegerOneThroughTenWithRemainderOnTarget() throws {
        let store = inFight()
        store.mutate("stage Cover allocation") { state in
            state.worlds.activeRun?.activeEncounter?.debugV2OwnedNodeIDs = [
                .binder: [CombatDerivedStatsRules.Node.cover], .companion(0): []]
            state.worlds.activeRun?.activeEncounter?.partyRanks = [
                .binder: .front, .companion(0): .back]
        }
        let run = try XCTUnwrap(store.activeRun)
        let encounter = try XCTUnwrap(store.activeEncounter)
        for total in 1...10 {
            let allocation = CombatRules.coverAllocation(finalDamage: total,
                target: .companion(0), wasInterposed: false, run: run,
                encounter: encounter, state: store.state)
            if total < 4 {
                XCTAssertNil(allocation)
            } else {
                XCTAssertEqual(allocation?.owner, .binder)
                XCTAssertEqual(allocation?.coverDamage, Int((Double(total) * 0.3).rounded(.down)))
                XCTAssertEqual((allocation?.coverDamage ?? 0) + (allocation?.targetDamage ?? 0), total)
            }
        }
    }

    func testCoverRequiresExactConsciousFrontOwnerAndExcludesInterpose() throws {
        let store = inFight()
        store.mutate("stage exact Cover owner") { state in
            state.worlds.activeRun?.activeEncounter?.debugV2OwnedNodeIDs = [
                .binder: [CombatDerivedStatsRules.Node.cover], .companion(0): []]
            state.worlds.activeRun?.activeEncounter?.partyRanks = [
                .binder: .front, .companion(0): .back]
        }
        let encounter = try XCTUnwrap(store.activeEncounter)
        let run = try XCTUnwrap(store.activeRun)
        XCTAssertNotNil(CombatRules.coverAllocation(finalDamage: 10, target: .companion(0),
            wasInterposed: false, run: run, encounter: encounter, state: store.state))
        XCTAssertNil(CombatRules.coverAllocation(finalDamage: 10, target: .companion(0),
            wasInterposed: true, run: run, encounter: encounter, state: store.state))
        var noOwner = encounter
        noOwner.debugV2OwnedNodeIDs?[.binder] = []
        XCTAssertNil(CombatRules.coverAllocation(finalDamage: 10, target: .companion(0),
            wasInterposed: false, run: run, encounter: noOwner, state: store.state))
        var passedOut = run; passedOut.binderHP = 0
        XCTAssertNil(CombatRules.coverAllocation(finalDamage: 10, target: .companion(0),
            wasInterposed: false, run: passedOut, encounter: encounter, state: store.state))
    }

    func testCoverProductionSplitsOneMitigatedHitWithoutChangingTotal() throws {
        func staged(cover: Bool) -> GameStore {
            let store = inFight()
            let foeID = store.activeEncounter!.foes[0].id
            store.mutate("stage production Cover") { state in
                guard var run = state.worlds.activeRun, var encounter = run.activeEncounter else { return }
                encounter.debugV2OwnedNodeIDs = [
                    .binder: cover ? [CombatDerivedStatsRules.Node.cover] : [],
                    .companion(0): [CombatDerivedStatsRules.Node.drawOff]]
                encounter.partyRanks = [.binder: .front, .companion(0): .back]
                if let index = encounter.foes.firstIndex(where: { $0.id == foeID }) {
                    encounter.foes[index].stats.element = .heat
                    // Cover owns 30% rounded down and intentionally has no allocation below four
                    // final damage. Stage a qualifying blow; Paper Moth's catalogue attack is too
                    // small to exercise the production split at all.
                    encounter.foes[index].stats.attack = max(12, encounter.foes[index].stats.attack)
                }
                encounter.drawOffReceipts = [foeID: .init(owner: .companion(0),
                    activationRound: 1, expiresBeforeRound: 3)]
                encounter.debugV2Evasion = .init(entries: CombatRules.party(of: state).map {
                    .init(actor: $0, characterEvasion: 0, components: [])
                })
                encounter.ghostEvasionAvailable = []
                encounter.order = [.foe(foeID), .binder, .companion(0)]
                encounter.turnSlots = encounter.order.map { .init(actor: $0) }; encounter.turnIndex = 0
                run.rng = SeededRNG(seed: 0xC0FE)
                run.activeEncounter = encounter; state.worlds.activeRun = run
            }
            return store
        }
        let covered = staged(cover: true), plain = staged(cover: false)
        let binderBefore = try XCTUnwrap(covered.activeRun?.binderHP)
        let companionBefore = try XCTUnwrap(covered.activeRun?.companionHP[0])
        covered.mutate("resolve covered hit") { CombatRules.runAutomaticTurns(in: &$0) }
        plain.mutate("resolve plain hit") { CombatRules.runAutomaticTurns(in: &$0) }
        let coverLoss = binderBefore - (covered.activeRun?.binderHP ?? binderBefore)
        let targetLoss = companionBefore - (covered.activeRun?.companionHP[0] ?? companionBefore)
        let plainLoss = companionBefore - (plain.activeRun?.companionHP[0] ?? companionBefore)
        XCTAssertEqual(coverLoss + targetLoss, plainLoss)
        XCTAssertGreaterThan(coverLoss, 0)
    }

    func testQuickenCreatesExactlyTwoNormalCreditsThenOneSkippedBlock() throws {
        let store = inFight()
        let foe = try XCTUnwrap(store.activeEncounter?.foes.first?.id)
        store.mutate("stage modern Quicken") { state in
            guard var run = state.worlds.activeRun, var encounter = run.activeEncounter else { return }
            encounter.debugV2OwnedNodeIDs = [.binder: [
                "combat.offense.swiftness.quicken", "combat.offense.swiftness.blur"]]
            encounter.order = [.binder]; encounter.turnSlots = [.init(actor: .binder)]; encounter.turnIndex = 0
            encounter.personalTurn = .init(owner: .binder)
            encounter.blurSpent = []; encounter.firstNormalActionCompleted = []
            encounter.foes[0].currentHP = 500; encounter.foes[0].stats.maxHP = 500
            encounter.foes[0].stats.evasion = 0
            run.activeEncounter = encounter; state.worlds.activeRun = run
        }
        store.mutate("quicken and spend two credits") { state in
            CombatRules.perform(.skill("quicken"), by: .binder, in: &state)
            XCTAssertEqual(state.worlds.activeRun?.activeEncounter?.personalTurn?.normalCreditsRemaining, 2)
            XCTAssertEqual(state.worlds.activeRun?.activeEncounter?.skippedTurns[.binder], 1)
            if let quicken = ContentCatalog.shared.skill("quicken"),
               let current = state.worlds.activeRun?.activeEncounter {
                XCTAssertFalse(CombatRules.isReady(quicken, for: .binder, in: current))
            }
            let afterQuicken = state.worlds.activeRun?.activeEncounter
            CombatRules.perform(.blur, by: .binder, in: &state)
            XCTAssertEqual(state.worlds.activeRun?.activeEncounter, afterQuicken,
                           "expansions share one setup slot")
            CombatRules.perform(.attack(foe: foe), by: .binder, in: &state)
            XCTAssertEqual(state.worlds.activeRun?.activeEncounter?.personalTurn?.normalCreditsRemaining, 1)
            CombatRules.perform(.attack(foe: foe), by: .binder, in: &state)
            XCTAssertEqual(state.worlds.activeRun?.activeEncounter?.skippedTurns[.binder], 0)
            XCTAssertTrue(state.worlds.activeRun?.activeEncounter?.recoveryComplete.contains(.binder) == true)
        }
    }

    func testBlurIsOncePerEncounterAndPersistsBetweenCredits() throws {
        let store = inFight()
        let foe = try XCTUnwrap(store.activeEncounter?.foes.first?.id)
        store.mutate("stage modern Blur") { state in
            guard var run = state.worlds.activeRun, var encounter = run.activeEncounter else { return }
            encounter.debugV2OwnedNodeIDs = [.binder: ["combat.offense.swiftness.blur"]]
            encounter.order = [.binder]; encounter.turnSlots = [.init(actor: .binder)]; encounter.turnIndex = 0
            encounter.personalTurn = .init(owner: .binder); encounter.blurSpent = []
            encounter.firstNormalActionCompleted = []
            encounter.foes[0].currentHP = 500; encounter.foes[0].stats.maxHP = 500
            run.activeEncounter = encounter; state.worlds.activeRun = run
            CombatRules.perform(.blur, by: .binder, in: &state)
        }
        XCTAssertEqual(store.activeEncounter?.personalTurn?.expansionSource, .blur)
        XCTAssertEqual(store.activeEncounter?.blurSpent, [.binder])
        let data = try JSONEncoder().encode(try XCTUnwrap(store.activeEncounter))
        let relaunched = try JSONDecoder().decode(EncounterState.self, from: data)
        XCTAssertEqual(relaunched.personalTurn?.normalCreditsRemaining, 2)
        XCTAssertEqual(relaunched.blurSpent, [.binder])
        store.mutate("spend and reject second Blur") { state in
            CombatRules.perform(.attack(foe: foe), by: .binder, in: &state)
            let before = state.worlds.activeRun?.activeEncounter
            CombatRules.perform(.blur, by: .binder, in: &state)
            XCTAssertEqual(state.worlds.activeRun?.activeEncounter, before)
        }
    }

    func testOverbearDebtStacksForBothExpandedCredits() throws {
        let store = inFight()
        let foe = try XCTUnwrap(store.activeEncounter?.foes.first?.id)
        store.mutate("stage expansion techniques") { state in
            guard var run = state.worlds.activeRun, var encounter = run.activeEncounter else { return }
            encounter.debugV2OwnedNodeIDs = [.binder: [
                "combat.offense.swiftness.quicken", "combat.offense.force.overbear"]]
            encounter.order = [.binder]; encounter.turnSlots = [.init(actor: .binder)]; encounter.turnIndex = 0
            encounter.personalTurn = .init(owner: .binder); encounter.blurSpent = []
            encounter.firstNormalActionCompleted = []
            encounter.foes[0].currentHP = 500; encounter.foes[0].stats.maxHP = 500
            encounter.foes[0].stats.evasion = 0
            run.activeEncounter = encounter; state.worlds.activeRun = run
            CombatRules.perform(.skill("quicken"), by: .binder, in: &state)
            CombatRules.perform(.skill("overbear", foe: foe), by: .binder, in: &state)
            XCTAssertEqual(state.worlds.activeRun?.activeEncounter?.personalTurn?.normalCreditsRemaining, 1)
            CombatRules.perform(.skill("overbear", foe: foe), by: .binder, in: &state)
            XCTAssertEqual(state.worlds.activeRun?.activeEncounter?.skippedTurns[.binder], 2,
                           "three debts were committed and the next scheduled block paid one")
        }
    }

    func testFirstStrikeAddsFourOnceAndMissStillSpendsIt() throws {
        func staged(firstStrike: Bool, evasion: Double = 0) -> GameStore {
            let store = inFight()
            store.mutate("stage First Strike") { state in
                guard var run = state.worlds.activeRun, var encounter = run.activeEncounter else { return }
                encounter.debugV2OwnedNodeIDs = [.binder: firstStrike
                    ? ["combat.offense.swiftness.first_strike"] : []]
                encounter.order = [.binder]; encounter.turnSlots = [.init(actor: .binder)]; encounter.turnIndex = 0
                encounter.personalTurn = .init(owner: .binder); encounter.blurSpent = []
                encounter.firstNormalActionCompleted = []
                encounter.foes[0].currentHP = 500; encounter.foes[0].stats.maxHP = 500
                encounter.foes[0].stats.evasion = evasion
                run.rng = SeededRNG(seed: 0xF1757); run.activeEncounter = encounter
                state.worlds.activeRun = run
            }
            return store
        }
        let strike = staged(firstStrike: true), plain = staged(firstStrike: false)
        let foe = try XCTUnwrap(strike.activeEncounter?.foes.first?.id)
        XCTAssertEqual(CombatRules.firstStrikeRawBonus(actor: .binder,
            encounter: try XCTUnwrap(strike.activeEncounter)), 4)
        XCTAssertEqual(CombatRules.firstStrikeRawBonus(actor: .binder,
            encounter: try XCTUnwrap(plain.activeEncounter)), 0)
        let ordinaryPreview = try XCTUnwrap(CombatRules.debugV2DirectAttackPreview(
            foe: try XCTUnwrap(strike.activeEncounter?.foes.first), in: strike.state))
        let firstPreview = try XCTUnwrap(CombatRules.debugV2DirectAttackPreview(
            foe: try XCTUnwrap(strike.activeEncounter?.foes.first), in: strike.state,
            personalRawBonus: CombatRules.firstStrikeRawBonus(
                actor: .binder, encounter: try XCTUnwrap(strike.activeEncounter))))
        XCTAssertGreaterThan(firstPreview.lower.rolledPower, ordinaryPreview.lower.rolledPower)
        XCTAssertGreaterThan(firstPreview.upper.rolledPower, ordinaryPreview.upper.rolledPower)
        XCTAssertEqual(firstPreview.lower.rolledPower + firstPreview.upper.rolledPower,
                       ordinaryPreview.lower.rolledPower + ordinaryPreview.upper.rolledPower + 8,
                       "the disclosed range remains centred on exactly +4 raw power")
        strike.mutate("First Strike") { CombatRules.perform(.skill("first_strike", foe: foe), by: .binder, in: &$0) }
        plain.mutate("ordinary attack") { CombatRules.perform(.attack(foe: foe), by: .binder, in: &$0) }
        let strikeLoss = 500 - (strike.activeEncounter?.foes[0].currentHP ?? 500)
        let plainLoss = 500 - (plain.activeEncounter?.foes[0].currentHP ?? 500)
        XCTAssertGreaterThan(strikeLoss, plainLoss)
        XCTAssertEqual(strike.activeEncounter?.firstNormalActionCompleted, [.binder])
        XCTAssertFalse(CombatRules.isReady(try XCTUnwrap(ContentCatalog.shared.skill("first_strike")),
                                           for: .binder,
                                           in: try XCTUnwrap(strike.activeEncounter)))

        let missed = staged(firstStrike: true, evasion: 1)
        missed.mutate("miss First Strike") {
            CombatRules.perform(.skill("first_strike", foe: foe), by: .binder, in: &$0)
        }
        XCTAssertEqual(missed.activeEncounter?.firstNormalActionCompleted, [.binder])
    }

    func testLegacyExtraTurnsAdoptOnceIntoModernPersonalCredits() throws {
        let store = inFight()
        store.mutate("stage legacy credit adoption") { state in
            guard var run = state.worlds.activeRun, var encounter = run.activeEncounter else { return }
            encounter.debugV2OwnedNodeIDs = [.binder: ["combat.offense.swiftness.quicken"]]
            encounter.personalTurn = nil; encounter.extraTurns[.binder] = 2
            encounter.order = [.binder]
            encounter.turnSlots = [.init(actor: .binder)]
            encounter.turnIndex = 0
            run.activeEncounter = encounter; state.worlds.activeRun = run
            CombatRules.advanceTurn(in: &state, completedAction: false)
        }
        XCTAssertEqual(store.activeEncounter?.personalTurn?.normalCreditsRemaining, 3)
        XCTAssertEqual(store.activeEncounter?.personalTurn?.expansionSource, .legacy)
        XCTAssertNil(store.activeEncounter?.extraTurns[.binder])
    }
}
