import XCTest
@testable import Bookbinder

@MainActor
final class EncounterScalingIntegrationTests: XCTestCase {
    func testGroupingRadiusMatchesEverySupportedPartyCount() throws {
        let store = GameStore(io: .temporary(name: "scaling-radius-\(UUID().uuidString)"))
        store.write("plains")
        store.bindAndDepart()
        var run = try XCTUnwrap(store.activeRun)
        var tiles = Array(repeating: Tile(), count: 7)
        for index in tiles.indices { tiles[index].isRevealed = true }
        run.map = WorldMap(width: 7, height: 1, tiles: tiles, entry: GridPoint(x: 0, y: 0))
        run.playerPosition = GridPoint(x: 0, y: 0)
        let trigger = enemy(1, 0, 0)
        run.enemies = [trigger]

        let expected = [1: 1, 2: 1, 3: 2, 4: 2, 5: 3]
        for partyCount in 1...5 {
            XCTAssertEqual(WorldRules.encounterGroup(triggeredBy: trigger, in: run,
                                                      partyCount: partyCount).radius,
                           expected[partyCount])
        }
    }

    func testFrozenLegacyGroupingStaysAdjacentWhileAdditiveV2UsesPartyRadius() throws {
        let store = GameStore(io: .temporary(name: "scaling-frozen-group-\(UUID().uuidString)"))
        store.write("plains")
        store.bindAndDepart()
        var run = try XCTUnwrap(store.activeRun)
        var tiles = Array(repeating: Tile(), count: 4)
        for index in tiles.indices { tiles[index].isRevealed = true }
        run.map = WorldMap(width: 4, height: 1, tiles: tiles, entry: GridPoint(x: 0, y: 0))
        run.playerPosition = GridPoint(x: 0, y: 0)
        let trigger = enemy(1, 0, 0)
        let distant = enemy(2, 3, 0)
        run.enemies = [trigger, distant]

        let legacy = WorldRules.encounterGroup(triggeredBy: trigger, in: run,
                                               partyCount: 5, adaptiveRadius: false)
        let additive = WorldRules.encounterGroup(triggeredBy: trigger, in: run,
                                                 partyCount: 5, adaptiveRadius: true)
        XCTAssertEqual(legacy.foes.map(\.id), [trigger.id])
        XCTAssertEqual(legacy.exclusionReasons["2"], "outside historical radius 1")
        XCTAssertEqual(additive.foes.map(\.id), [trigger.id, distant.id])
    }

    func testReachableVisibleGroupUsesPartyRadiusStableOrderAndHonestExclusions() throws {
        let store = GameStore(io: .temporary(name: "scaling-group-\(UUID().uuidString)"))
        store.write("plains")
        store.bindAndDepart()
        var run = try XCTUnwrap(store.activeRun)
        var tiles = Array(repeating: Tile(), count: 15)
        for index in tiles.indices { tiles[index].isRevealed = true }
        run.map = WorldMap(width: 5, height: 3, tiles: tiles, entry: GridPoint(x: 0, y: 1))
        run.playerPosition = GridPoint(x: 0, y: 1)
        for y in 0..<3 { run.map[GridPoint(x: 3, y: y)].ground = .chasm }

        let trigger = enemy(100, 0, 1)
        let stableTieFirst = enemy(10, 2, 1)
        let nearer = enemy(30, 1, 1)
        let beyondWall = enemy(5, 4, 1)
        var asleep = enemy(6, 1, 2); asleep.isAwake = false
        var hidden = enemy(7, 2, 0)
        var crypsis = CreatureTraits(); crypsis.defence = .crypsis
        hidden.traits = crypsis
        run.enemies = [beyondWall, stableTieFirst, asleep, trigger, hidden, nearer]

        let selection = WorldRules.encounterGroup(triggeredBy: trigger, in: run, partyCount: 5)
        XCTAssertEqual(selection.radius, 3)
        XCTAssertEqual(selection.foes.map(\.id), [100, 30, 10].map { InstanceID(rawValue: UInt64($0)) })
        XCTAssertEqual(selection.exclusionReasons["5"], "outside passable radius 3")
        XCTAssertEqual(selection.exclusionReasons["6"], "asleep")
        XCTAssertEqual(selection.exclusionReasons["7"], "eligible after three-foe cap")
    }

    func testPressureHPAllocationIsExactStableAndOrderIndependent() {
        let foes = [foe(3, hp: 30), foe(1, hp: 10), foe(2, hp: 20)]
        let forward = WorldRules.pressureHPAllocation(for: foes, additionFraction: 0.15)
        let reverse = WorldRules.pressureHPAllocation(for: Array(foes.reversed()), additionFraction: 0.15)
        XCTAssertEqual(forward, reverse)
        XCTAssertEqual(forward.values.reduce(0, +), 9)
        XCTAssertEqual(forward[InstanceID(rawValue: 1)], 2)
        XCTAssertEqual(forward[InstanceID(rawValue: 2)], 3)
        XCTAssertEqual(forward[InstanceID(rawValue: 3)], 4)
    }

    func testOrdinaryPressureScheduleIsSavedInterleavedAndAfflictionFree() throws {
        var rng = SeededRNG(seed: 909)
        let first = foe(11, hp: 20)
        let second = foe(12, hp: 20)
        let encounter = CombatRules.makeEncounter(
            id: InstanceID(rawValue: 1), foes: [first, second],
            party: [.binder, .companion(0), .companion(1)], ordinaryPressureSlots: 2,
            rng: &rng)
        let pressure = encounter.turnSlots.filter {
            if case .ordinaryPressureFollowUp = $0.kind { return true }
            return false
        }
        XCTAssertEqual(pressure.count, 2)
        XCTAssertEqual(Set(pressure.map(\.actor)),
                       Set([Combatant.foe(InstanceID(rawValue: 11)),
                            Combatant.foe(InstanceID(rawValue: 12))]))
        XCTAssertTrue(pressure.allSatisfy { $0.strengthMultiplier == 0.55 && $0.suppressesAfflictions })
        for index in encounter.turnSlots.indices.dropFirst() {
            if case .ordinaryPressureFollowUp = encounter.turnSlots[index].kind {
                XCTAssertNotEqual(encounter.turnSlots[index - 1].actor,
                                  encounter.turnSlots[index].actor)
            }
        }
        let resumed = try JSONDecoder().decode(EncounterState.self,
                                                from: JSONEncoder().encode(encounter))
        XCTAssertEqual(resumed.turnSlots, encounter.turnSlots)
        XCTAssertTrue(resumed.log.contains("Pressed — 2 lighter follow-ups."))
    }

    func testPressureFollowUpForcesSingleTargetAndCannotAfflict() throws {
        let store = GameStore(io: .temporary(name: "pressure-execution-\(UUID().uuidString)"))
        store.write("plains")
        store.bindAndDepart()
        store.mutate("stage isolated lighter action") { state in
            if state.base.roster.isEmpty { state.base.roster.append(CompanionState()) }
            state.base.activeParty = [0]
            guard var run = state.worlds.activeRun else { return }
            var stats = CombatStats(displayName: "Haze", icon: "cloud", maxHP: 20, attack: 10)
            stats.delivery = .area
            stats.element = .heat
            let enemy = FoeState(id: InstanceID(rawValue: 91), stats: stats, currentHP: 20)
            run.binderHP = Tuning.Encounter.binderMaxHP
            run.companionHP[0] = Tuning.Encounter.companionMaxHP
            run.activeEncounter = EncounterState(
                id: InstanceID(rawValue: 7), foes: [enemy], partyNames: [0: "Mara"],
                order: [.foe(InstanceID(rawValue: 91)), .binder],
                turnSlots: [.init(actor: .foe(InstanceID(rawValue: 91)), kind: .ordinaryPressureFollowUp(1),
                                  strengthMultiplier: 0.55, suppressesAfflictions: true),
                            .init(actor: .binder)])
            state.worlds.activeRun = run
            CombatRules.runAutomaticTurns(in: &state)
        }
        let run = try XCTUnwrap(store.activeRun)
        let companionHP = run.companionHP[0] ?? Tuning.Encounter.companionMaxHP
        let damaged = [run.binderHP < Tuning.Encounter.binderMaxHP,
                       companionHP < Tuning.Encounter.companionMaxHP]
        XCTAssertEqual(damaged.filter { $0 }.count, 1, "A lighter area follow-up is one target only")
        XCTAssertTrue(try XCTUnwrap(run.activeEncounter).statuses.isEmpty)
        XCTAssertTrue(try XCTUnwrap(run.activeEncounter).log.contains {
            $0.contains("Lighter follow-up 1")
        })
    }

    func testFrozenV1RecommendedRunDoesNotAdoptAdditiveRulesMidExpedition() throws {
        let store = GameStore(io: .temporary(name: "scaling-v1-recommended-\(UUID().uuidString)"))
        store.write("plains")
        store.bindAndDepart()
        store.mutate("stage frozen v1 recommended") { state in
            while state.base.roster.count < 4 { state.base.roster.append(CompanionState()) }
            state.base.binderCharacter.level = 2
            for index in 0..<4 { state.base.roster[index].character.level = 8 }
            state.base.activeParty = [0, 1, 2, 3]
            guard var run = state.worlds.activeRun else { return }
            run.tuning.encounterScalingProfileSchemaVersion = 1
            run.tuning.encounterScalingProfile = .recommended
            let enemy = WorldEnemy(id: InstanceID(rawValue: 44), creatureID: "paper_moth",
                                   position: run.playerPosition, isAwake: true)
            run.enemies = [enemy]
            state.worlds.activeRun = run
            WorldRules.beginEncounter(triggeredBy: enemy, in: &state)
        }
        let preview = try XCTUnwrap(store.activeEncounter?.scalingPreview)
        XCTAssertNil(preview.scalingRulesVersion)
        XCTAssertEqual(preview.upperMedian, 8)
        XCTAssertNil(preview.wholePressureSlots)
    }

    func testLegacyRunWithoutTuningStaysLegacyWhileNewPreferenceIsRecommended() throws {
        let store = GameStore(io: .temporary(name: "legacy-run-scaling-\(UUID().uuidString)"))
        store.write("plains")
        store.bindAndDepart()
        var object = try XCTUnwrap(JSONSerialization.jsonObject(
            with: JSONEncoder().encode(try XCTUnwrap(store.activeRun))) as? [String: Any])
        object.removeValue(forKey: "tuning")
        let decoded = try JSONDecoder().decode(WorldRun.self,
            from: JSONSerialization.data(withJSONObject: object))
        XCTAssertEqual(decoded.tuning.encounterScalingProfile, .current)
        XCTAssertEqual(DebugTuningProfile.defaults.encounterScalingProfile, .recommended)
    }

    private func enemy(_ id: UInt64, _ x: Int, _ y: Int) -> WorldEnemy {
        WorldEnemy(id: InstanceID(rawValue: id), creatureID: "paper_moth",
                   position: GridPoint(x: x, y: y), isAwake: true)
    }

    private func foe(_ id: UInt64, hp: Int) -> FoeState {
        FoeState(id: InstanceID(rawValue: id),
                 stats: CombatStats(displayName: "Foe \(id)", icon: "pawprint",
                                    maxHP: hp, attack: 4), currentHP: hp)
    }
}
