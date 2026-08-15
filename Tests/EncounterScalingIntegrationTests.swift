import XCTest
@testable import Bookbinder

@MainActor
final class EncounterScalingIntegrationTests: XCTestCase {
    func testPhonePairUsesDisposableExactIsolatedProductionEncounters() throws {
        for kind in EncounterScalingPhoneFixtureKind.allCases {
            let store = try GameStore.makeEncounterScalingPhoneFixture(kind: kind)
            let run = try XCTUnwrap(store.activeRun)
            let encounter = try XCTUnwrap(run.activeEncounter)
            let preview = try XCTUnwrap(encounter.scalingPreview)

            XCTAssertTrue(store.diagnostics.saveURL.path.contains("phone-scaling-"))
            XCTAssertEqual(try XCTUnwrap(run.healthCaps).map(\.maximum).reduce(0, +), 54)
            XCTAssertGreaterThan(run.binderHP + run.companionHP.values.reduce(0, +), 0)
            XCTAssertLessThanOrEqual(run.binderHP + run.companionHP.values.reduce(0, +), 54)
            XCTAssertTrue(store.state.base.binderEquipped.isEmpty)
            XCTAssertTrue(store.state.base.roster[0].equipped.isEmpty)
            XCTAssertEqual(encounter.foes.count, 1)
            XCTAssertEqual(encounter.foes[0].identityKey, "grazer")
            XCTAssertEqual(encounter.foes[0].level, 1)
            XCTAssertEqual(preview.partyCount, 2)
            XCTAssertEqual(preview.anchorLevel, 1)
            XCTAssertEqual(preview.cappedPartyPowerBudget, 1.5)
            XCTAssertEqual(preview.scalingRulesVersion,
                           EncounterScalingRules.additivePartyPowerRulesVersion)
            XCTAssertNotNil(DebugEncounterScalingEvidence.capture(from: store.state))
        }
    }

    func testProgressionPhoneFixturesFreezeRulesOwnedLevelsHealthAndEnemyAllocation() throws {
        let receipts = try EncounterScalingProgressionFixtureKind.allCases.map { kind in
            let store = try GameStore.makeEncounterScalingProgressionFixture(kind: kind)
            return try XCTUnwrap(GameStore.progressionReceipt(kind: kind, rootSeed: 101, from: store))
        }
        let fresh = try XCTUnwrap(receipts.first { $0.kind == .freshSolo })
        let solo = try XCTUnwrap(receipts.first { $0.kind == .experiencedSolo })
        let party = try XCTUnwrap(receipts.first { $0.kind == .experiencedParty })

        XCTAssertEqual(fresh.partyLevels, [1])
        XCTAssertEqual(solo.partyLevels, [8])
        XCTAssertEqual(party.partyLevels, [8, 8, 6, 4])
        XCTAssertEqual(receipts.map(\.rootSeed), [101, 101, 101])
        XCTAssertEqual(Set(receipts.map(\.mapSeed)).count, 1)
        XCTAssertTrue(receipts.allSatisfy {
            $0.scalingRulesVersion == EncounterScalingRules.additivePartyPowerRulesVersion
                && $0.foeIDs == $0.foeIDs.sorted { $0.rawValue < $1.rawValue }
                && $0.partyCount == $0.partyLevels.count
                && $0.healthCaps.count == $0.partyCount
        })
        XCTAssertEqual(fresh.anchorLevel, 1)
        XCTAssertEqual(solo.anchorLevel, 8)
        XCTAssertEqual(party.anchorLevel, 8)
        XCTAssertEqual(fresh.healthCaps, [30])
        XCTAssertEqual(solo.healthCaps, [30])
        XCTAssertEqual(party.healthCaps, [30, 24, 24, 24])
        XCTAssertEqual(fresh.worldLevel, 1)
        XCTAssertEqual(solo.worldLevel, 6)
        XCTAssertEqual(party.worldLevel, 6)
        XCTAssertEqual(fresh.foeLevels, [1])
        XCTAssertEqual(solo.foeLevels, [6])
        XCTAssertEqual(party.foeLevels, [6])
        XCTAssertEqual(fresh.foeHP, [12])
        XCTAssertEqual(solo.foeHP, [18])
        XCTAssertEqual(party.foeHP, [22])
        XCTAssertEqual(fresh.groupingRadius, 1)
        XCTAssertEqual(solo.groupingRadius, 1)
        XCTAssertEqual(party.groupingRadius, 2)
        XCTAssertEqual(party.cappedPartyPowerBudget, 2.275052602165878,
                       accuracy: 0.000_000_001)
        XCTAssertEqual(party.hpAllocationByFoeID.values.reduce(0, +), 4)
        XCTAssertGreaterThan(solo.worldLevel, fresh.worldLevel)
        XCTAssertTrue(zip(solo.foeLevels, fresh.foeLevels).allSatisfy { $0 >= $1 })
        XCTAssertGreaterThan(solo.foeHP.reduce(0, +), fresh.foeHP.reduce(0, +))
        XCTAssertGreaterThan(party.cappedPartyPowerBudget, solo.cappedPartyPowerBudget)
        XCTAssertGreaterThanOrEqual(party.groupingRadius, solo.groupingRadius)
        XCTAssertGreaterThanOrEqual(party.foeIDs.count, solo.foeIDs.count)
        XCTAssertGreaterThanOrEqual(party.foeHP.reduce(0, +), solo.foeHP.reduce(0, +))
        let expectedPressure = EncounterScalingRules.additivePressure(
            partyPowerBudget: party.cappedPartyPowerBudget,
            realFoeCount: party.foeIDs.count)
        XCTAssertEqual(party.wholePressureSlots, expectedPressure.wholePressureSlots)
        XCTAssertEqual(party.totalHPAdditionFraction,
                       expectedPressure.totalHPAdditionFraction, accuracy: 0.000_001)
        XCTAssertTrue(Set(party.hpAllocationByFoeID.keys).isSubset(of:
            Set(party.foeIDs.map { String($0.rawValue) })))

        let repeatedStore = try GameStore.makeEncounterScalingProgressionFixture(
            kind: .experiencedParty)
        let repeated = try XCTUnwrap(GameStore.progressionReceipt(
            kind: .experiencedParty, rootSeed: 101, from: repeatedStore))
        XCTAssertEqual(repeated, party,
                       "the same disclosed root and party vector must freeze the same receipt")
        let encodedEncounter = try JSONEncoder().encode(
            try XCTUnwrap(repeatedStore.activeEncounter))
        let resumed = try JSONDecoder().decode(EncounterState.self, from: encodedEncounter)
        XCTAssertEqual(resumed.scalingPreview, repeatedStore.activeEncounter?.scalingPreview)

        for receipt in receipts { print("SCALING_PROGRESSION \(receipt)") }
    }

    func testFreshBinderAndQuillNormalVersusTeemingDiagnosticDistribution() throws {
        let roots: [UInt64] = [101, 202, 303, 404, 505, 606, 707, 808, 909, 1_010, 1_111, 1_212]
        let normal = try roots.prefix(6).map { try openingSample(rootSeed: $0, teeming: false) }
        let teeming = try roots.prefix(6).map { try openingSample(rootSeed: $0, teeming: true) }
        let normalAdjacent = try roots.prefix(3).map {
            try adjacentGroupingSample(rootSeed: $0, teeming: false)
        }
        let teemingAdjacent = try roots.prefix(3).map {
            try adjacentGroupingSample(rootSeed: $0, teeming: true)
        }

        for sample in normal + teeming {
            XCTAssertEqual(sample.partyCount, 2)
            XCTAssertEqual(sample.partyBudget, 1.5, accuracy: 0.000_001)
            XCTAssertEqual(sample.anchorLevel, 1)
            XCTAssertEqual(sample.scalingRulesVersion,
                           EncounterScalingRules.additivePartyPowerRulesVersion)
            XCTAssertFalse(sample.species.isEmpty)
            XCTAssertGreaterThan(sample.groupSize, 0)
            XCTAssertLessThanOrEqual(sample.groupSize, Tuning.Encounter.maxFoes)
            XCTAssertGreaterThan(sample.worldLevel, 0)
            XCTAssertGreaterThan(sample.startingAggregateHP, 0)
            XCTAssertEqual(sample.startingAggregateHP, 54)
            XCTAssertGreaterThanOrEqual(sample.aggregateHPSpent, 0)
            XCTAssertLessThanOrEqual(sample.aggregateHPSpent, sample.startingAggregateHP)
            XCTAssertGreaterThan(sample.rounds, 0)
            XCTAssertLessThanOrEqual(sample.rounds, 30)
            XCTAssertNotNil(sample.outcome)
        }
        XCTAssertGreaterThan(teeming.map(\.generatedPopulation).reduce(0, +),
                             normal.map(\.generatedPopulation).reduce(0, +),
                             "Teeming's density attribution must remain visible before grouping")
        XCTAssertTrue((normalAdjacent + teemingAdjacent).allSatisfy { $0.groupSize == 2 })
        XCTAssertTrue(normal.allSatisfy {
            $0.outcome == .victory && (2...4).contains($0.rounds) && $0.aggregateHPSpent <= 11
        }, "fresh Normal openings left the settled 2–4 round / roughly 20% HP band")
        XCTAssertTrue(teeming.allSatisfy {
            $0.outcome == .victory && (2...4).contains($0.rounds)
        }, "an isolated Teeming opening became an ordinary death trap")

        printDistribution("Normal", normal)
        printDistribution("Teeming", teeming)
        print("SCALING adjacent Normal \(normalAdjacent)")
        print("SCALING adjacent Teeming \(teemingAdjacent)")
    }

    func testCorrectedNormalUpperHPMissesHaveFrozenSingleFactorCounterfactuals() throws {
        XCTAssertEqual(Tuning.Encounter.multiDeliveryShare, 0.5,
                       "the measured two-person opening correction drifted")
        for root in [UInt64(202), 303, 606] {
            let frozen = try frozenOpeningState(rootSeed: root)
            let encounter = try XCTUnwrap(frozen.worlds.activeRun?.activeEncounter)
            XCTAssertEqual(encounter.foes.count, 1)
            XCTAssertTrue(encounter.foes.allSatisfy { $0.stats.damageKind != .rend },
                          "root \(root) unexpectedly introduced a rend payload")

            let observed = try counterfactual(from: frozen, variant: .observed,
                                              strategy: .shippingDefault)
            let explicitBasic = try counterfactual(from: frozen, variant: .observed,
                                                   strategy: .explicitBasicAttack)
            let noAfflictions = try counterfactual(from: frozen, variant: .suppressAfflictions,
                                                   strategy: .shippingDefault)
            let forcedSingle = try counterfactual(from: frozen, variant: .forceSingleDelivery,
                                                  strategy: .shippingDefault)

            XCTAssertEqual(observed, explicitBasic,
                           "fresh-save Binder had an available action beyond the disclosed basic attack")
            XCTAssertEqual(observed, noAfflictions,
                           "non-rend root \(root) changed when affliction payloads were suppressed")
            if encounter.foes[0].stats.delivery == .multi {
                XCTAssertNotEqual(observed.hpSpent, forcedSingle.hpSpent,
                                  "multi delivery had no measurable HP effect for root \(root)")
            } else {
                XCTAssertEqual(observed, forcedSingle,
                               "forcing an already-single foe changed root \(root)")
            }

            print("SCALING_COUNTERFACTUAL root=\(root) foe=\(encounter.foes[0].identityKey) "
                  + "stats=HP\(encounter.foes[0].stats.maxHP):ATK\(encounter.foes[0].stats.attack):"
                  + "\(encounter.foes[0].stats.damageKind.rawValue):\(encounter.foes[0].stats.delivery.rawValue) "
                  + "observed=\(observed) forcedSingle=\(forcedSingle) "
                  + "noAfflictions=\(noAfflictions) explicitBasic=\(explicitBasic)")
        }
    }

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
                                                 partyCount: 5, adaptiveRadius: true,
                                                 partySightBonus: 10)
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
        let fartherVisible = enemy(10, 2, 1)
        let nearer = enemy(30, 1, 1)
        let beyondWall = enemy(5, 4, 1)
        var asleep = enemy(6, 1, 2); asleep.isAwake = false
        var brokenCover = enemy(7, 2, 0)
        var crypsis = CreatureTraits(); crypsis.defence = .crypsis
        brokenCover.traits = crypsis
        run.enemies = [beyondWall, fartherVisible, asleep, trigger, brokenCover, nearer]

        let selection = WorldRules.encounterGroup(triggeredBy: trigger, in: run,
                                                  partyCount: 5, partySightBonus: 10)
        XCTAssertEqual(selection.radius, 3)
        XCTAssertEqual(selection.foes.map(\.id), [100, 30, 10].map { InstanceID(rawValue: UInt64($0)) })
        XCTAssertEqual(selection.exclusionReasons["5"], "outside passable radius 3")
        XCTAssertEqual(selection.exclusionReasons["6"], "asleep")
        XCTAssertEqual(selection.exclusionReasons["7"], "eligible after three-foe cap")
        XCTAssertNil(selection.exclusionReasons["10"])
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

    private struct OpeningSample {
        var rootSeed: UInt64
        var mapSeed: UInt64
        var generatedPopulation: Int
        var groupSize: Int
        var worldLevel: Int
        var stabilityContribution: Double
        var greedContribution: Double
        var partyCount: Int
        var partyBudget: Double
        var anchorLevel: Int
        var scalingRulesVersion: String
        var species: [String]
        var foeStats: [String]
        var rounds: Int
        var startingAggregateHP: Int
        var aggregateHPSpent: Int
        var outcome: EncounterOutcome?
    }

    private enum CounterfactualVariant { case observed, forceSingleDelivery, suppressAfflictions }
    private enum CounterfactualStrategy { case shippingDefault, explicitBasicAttack }

    private struct CounterfactualReceipt: Equatable, CustomStringConvertible {
        var hpSpent: Int
        var binderHP: Int
        var quillHP: Int
        var rounds: Int
        var playerActions: Int
        var outcome: EncounterOutcome?
        var rngState: UInt64
        var afflictions: [AfflictionInstance]
        var log: [String]

        var description: String {
            "hp=\(hpSpent)/54 binder=\(binderHP) quill=\(quillHP) rounds=\(rounds) "
                + "actions=\(playerActions) outcome=\(String(describing: outcome)) "
                + "rng=\(rngState) afflictions=\(afflictions.count)"
        }
    }

    private func frozenOpeningState(rootSeed: UInt64) throws -> GameState {
        let store = GameStore(io: .temporary(
            name: "scaling-frozen-normal-\(rootSeed)-\(UUID().uuidString)"))
        store.mutate("freeze counterfactual root") { state in
            state.worlds.seeds = SeedSequence(rootSeed: rootSeed)
            state.base.binderCharacter = CharacterState(rank: .front)
            state.base.binderEquipped = [:]
            var quill = CompanionState()
            quill.maxHP = Tuning.Encounter.companionMaxHP
            quill.character = CharacterState(rank: .front)
            quill.gambits = GambitStarter.rules
            quill.equipped = [:]
            state.base.roster = [quill]
            state.base.activeParty = [0]
        }
        XCTAssertTrue(store.write("plains"))
        XCTAssertTrue(store.bindAndDepart())
        store.mutate("stage frozen disclosed opening") { state in
            guard var run = state.worlds.activeRun, !run.enemies.isEmpty else { return }
            run.tuning = .defaults
            run.binderHP = Tuning.Encounter.binderMaxHP
            run.companionHP = [0: Tuning.Encounter.companionMaxHP]
            run.healthCaps = [
                .init(member: .binder, ordinaryMaximum: Tuning.Encounter.binderMaxHP, components: []),
                .init(member: .member(0), ordinaryMaximum: Tuning.Encounter.companionMaxHP,
                      components: [])
            ]
            run.rng = SeededRNG(seed: run.mapSeed).derived(0xA11CE)
            for point in run.map.allPoints { run.map[point].isRevealed = true }
            for index in run.enemies.indices { run.enemies[index].isAwake = true }
            let trigger = run.enemies.min {
                let lhs = abs($0.position.x - run.playerPosition.x)
                    + abs($0.position.y - run.playerPosition.y)
                let rhs = abs($1.position.x - run.playerPosition.x)
                    + abs($1.position.y - run.playerPosition.y)
                return lhs == rhs ? $0.id.rawValue < $1.id.rawValue : lhs < rhs
            }!
            state.worlds.activeRun = run
            WorldRules.beginEncounter(triggeredBy: trigger, runsAutomaticTurns: false, in: &state)
            CombatRules.runAutomaticTurns(in: &state)
        }
        let frozen = try JSONDecoder().decode(GameState.self,
                                               from: JSONEncoder().encode(store.state))
        XCTAssertNotNil(frozen.worlds.activeRun?.activeEncounter)
        return frozen
    }

    private func counterfactual(from frozen: GameState, variant: CounterfactualVariant,
                                strategy: CounterfactualStrategy) throws -> CounterfactualReceipt {
        let state = try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(frozen))
        let store = GameStore(io: .temporary(name: "scaling-counterfactual-\(UUID().uuidString)"))
        store.mutate("adopt frozen opening") { $0 = state }
        store.mutate("apply single-factor counterfactual") { state in
            guard var encounter = state.worlds.activeRun?.activeEncounter else { return }
            switch variant {
            case .observed:
                break
            case .forceSingleDelivery:
                for index in encounter.foes.indices { encounter.foes[index].stats.delivery = .single }
            case .suppressAfflictions:
                for index in encounter.turnSlots.indices {
                    if encounter.turnSlots[index].actor.foeID != nil {
                        encounter.turnSlots[index].suppressesAfflictions = true
                    }
                }
            }
            state.worlds.activeRun?.activeEncounter = encounter
        }

        var playerActions = 0
        while store.activeEncounter?.outcome == nil, playerActions < 30 {
            let action: CombatAction?
            switch strategy {
            case .shippingDefault:
                action = store.defaultCombatAction()
                if case .some(.attack) = action {} else {
                    XCTFail("fresh Binder default was not the disclosed basic attack")
                }
            case .explicitBasicAttack:
                action = store.activeEncounter?.livingFoes.first.map { .attack(foe: $0.id) }
            }
            guard let action else { break }
            store.takeCombatAction(action)
            playerActions += 1
        }
        let run = try XCTUnwrap(store.activeRun)
        let encounter = try XCTUnwrap(run.activeEncounter)
        let quillHP = run.companionHP[0] ?? Tuning.Encounter.companionMaxHP
        return CounterfactualReceipt(
            hpSpent: 54 - run.binderHP - quillHP,
            binderHP: run.binderHP, quillHP: quillHP, rounds: encounter.roundNumber,
            playerActions: playerActions, outcome: encounter.outcome, rngState: run.rng.state,
            afflictions: encounter.afflictions ?? [], log: encounter.log)
    }

    private func openingSample(rootSeed: UInt64, teeming: Bool) throws -> OpeningSample {
        let label = teeming ? "teeming" : "normal"
        let store = GameStore(io: .temporary(
            name: "scaling-sample-\(label)-\(rootSeed)-\(UUID().uuidString)"))
        store.mutate("freeze diagnostic root seed") { state in
            state.worlds.seeds = SeedSequence(rootSeed: rootSeed)
            state.base.binderCharacter = CharacterState(rank: .front)
            state.base.binderEquipped = [:]
            var quill = CompanionState()
            quill.maxHP = Tuning.Encounter.companionMaxHP
            quill.character = CharacterState(rank: .front)
            quill.gambits = GambitStarter.rules
            quill.equipped = [:]
            state.base.roster = [quill]
            state.base.activeParty = [0]
        }
        XCTAssertTrue(store.write("plains"))
        if teeming { XCTAssertTrue(store.write("teeming_life")) }
        XCTAssertTrue(store.bindAndDepart())

        store.mutate("stage disclosed opening contact") { state in
            guard var run = state.worlds.activeRun, !run.enemies.isEmpty else { return }
            run.tuning = .defaults
            run.binderHP = Tuning.Encounter.binderMaxHP
            run.companionHP = [0: Tuning.Encounter.companionMaxHP]
            run.healthCaps = [
                RunHealthCapEntry(member: .binder,
                                  ordinaryMaximum: Tuning.Encounter.binderMaxHP, components: []),
                RunHealthCapEntry(member: .member(0),
                                  ordinaryMaximum: Tuning.Encounter.companionMaxHP, components: [])
            ]
            run.rng = SeededRNG(seed: run.mapSeed).derived(0xA11CE)
            for point in run.map.allPoints { run.map[point].isRevealed = true }
            for index in run.enemies.indices { run.enemies[index].isAwake = true }
            let trigger = run.enemies.min {
                let lhs = abs($0.position.x - run.playerPosition.x)
                    + abs($0.position.y - run.playerPosition.y)
                let rhs = abs($1.position.x - run.playerPosition.x)
                    + abs($1.position.y - run.playerPosition.y)
                return lhs == rhs ? $0.id.rawValue < $1.id.rawValue : lhs < rhs
            }!
            state.worlds.activeRun = run
            WorldRules.beginEncounter(triggeredBy: trigger, runsAutomaticTurns: false, in: &state)
            CombatRules.runAutomaticTurns(in: &state)
        }

        let openingRun = try XCTUnwrap(store.activeRun,
                                       "seed \(rootSeed) generated no usable opening run")
        let opening = try XCTUnwrap(openingRun.activeEncounter,
                                    "seed \(rootSeed) generated no ordinary encounter")
        XCTAssertFalse(opening.foes.contains(where: \.isApex),
                       "opening diagnostic excludes optional apex contact")
        let preview = try XCTUnwrap(opening.scalingPreview)
        let startingHP = try XCTUnwrap(openingRun.healthCaps).map(\.maximum).reduce(0, +)
        let species = opening.foes.map(\.identityKey).sorted()
        let stats = opening.foes.sorted { $0.id.rawValue < $1.id.rawValue }.map {
            "\($0.identityKey):L\($0.level):HP\($0.stats.maxHP):ATK\($0.stats.attack):ARM\($0.stats.armour):\($0.stats.damageKind.rawValue):\($0.stats.delivery.rawValue)"
        }

        var actions = 0
        while store.activeEncounter?.outcome == nil, actions < 30 {
            guard let action = store.defaultCombatAction() else { break }
            store.takeCombatAction(action)
            actions += 1
        }
        let finished = try XCTUnwrap(store.activeEncounter)
        let endingRun = try XCTUnwrap(store.activeRun)
        let endingHP = endingRun.binderHP + endingRun.companionHP.values.reduce(0, +)
        return OpeningSample(
            rootSeed: rootSeed, mapSeed: openingRun.mapSeed,
            generatedPopulation: openingRun.enemies.count,
            groupSize: opening.foes.count, worldLevel: try XCTUnwrap(preview.worldLevel),
            stabilityContribution: preview.stabilityLevelContribution,
            greedContribution: preview.greedLevelContribution,
            partyCount: preview.partyCount,
            partyBudget: try XCTUnwrap(preview.cappedPartyPowerBudget),
            anchorLevel: try XCTUnwrap(preview.anchorLevel),
            scalingRulesVersion: try XCTUnwrap(preview.scalingRulesVersion),
            species: species, foeStats: stats, rounds: finished.roundNumber,
            startingAggregateHP: startingHP,
            aggregateHPSpent: max(0, startingHP - endingHP), outcome: finished.outcome)
    }

    private func printDistribution(_ label: String, _ samples: [OpeningSample]) {
        let rounds = samples.map(\.rounds).sorted()
        let spent = samples.map(\.aggregateHPSpent).sorted()
        let groups = samples.map(\.groupSize).sorted()
        let populations = samples.map(\.generatedPopulation).sorted()
        print("SCALING \(label) rounds=\(rounds) hpSpent=\(spent) groups=\(groups) populations=\(populations)")
        for sample in samples {
            print("SCALING \(label) root=\(sample.rootSeed) map=\(sample.mapSeed) population=\(sample.generatedPopulation) group=\(sample.groupSize) worldLevel=\(sample.worldLevel) stability=\(sample.stabilityContribution) greed=\(sample.greedContribution) rounds=\(sample.rounds) hp=\(sample.aggregateHPSpent)/\(sample.startingAggregateHP) outcome=\(String(describing: sample.outcome)) species=\(sample.species.joined(separator: "|")) stats=\(sample.foeStats.joined(separator: "|"))")
        }
    }

    private struct AdjacentGroupingSample: CustomStringConvertible {
        var rootSeed: UInt64
        var generatedPopulation: Int
        var groupSize: Int
        var inclusionReasons: [String: String]
        var description: String {
            "root=\(rootSeed):population=\(generatedPopulation):group=\(groupSize):reasons=\(inclusionReasons)"
        }
    }

    private func adjacentGroupingSample(rootSeed: UInt64, teeming: Bool) throws
        -> AdjacentGroupingSample {
        let label = teeming ? "teeming" : "normal"
        let store = GameStore(io: .temporary(
            name: "scaling-adjacent-\(label)-\(rootSeed)-\(UUID().uuidString)"))
        store.mutate("freeze adjacent diagnostic") { state in
            state.worlds.seeds = SeedSequence(rootSeed: rootSeed)
            state.base.binderCharacter = CharacterState(rank: .front)
            state.base.binderEquipped = [:]
            var quill = CompanionState()
            quill.character = CharacterState(rank: .front)
            quill.gambits = GambitStarter.rules
            state.base.roster = [quill]
            state.base.activeParty = [0]
        }
        XCTAssertTrue(store.write("plains"))
        if teeming { XCTAssertTrue(store.write("teeming_life")) }
        XCTAssertTrue(store.bindAndDepart())
        let generatedPopulation = try XCTUnwrap(store.activeRun).enemies.count
        XCTAssertGreaterThanOrEqual(generatedPopulation, 2,
                                    "counterfactual needs two generated bodies, never fabricated foes")

        store.mutate("stage two disclosed adjacent generated bodies") { state in
            guard var run = state.worlds.activeRun, run.enemies.count >= 2 else { return }
            run.tuning = .defaults
            for point in run.map.allPoints { run.map[point].isRevealed = true }
            let triggerIndex = run.enemies.indices.min {
                let lhs = abs(run.enemies[$0].position.x - run.playerPosition.x)
                    + abs(run.enemies[$0].position.y - run.playerPosition.y)
                let rhs = abs(run.enemies[$1].position.x - run.playerPosition.x)
                    + abs(run.enemies[$1].position.y - run.playerPosition.y)
                return lhs == rhs
                    ? run.enemies[$0].id.rawValue < run.enemies[$1].id.rawValue : lhs < rhs
            }!
            let secondIndex = run.enemies.indices.first { $0 != triggerIndex }!
            // This counterfactual is explicitly about two disclosed contacts. Historical reveal
            // alone is not current sight, so anchor the observer at the generated trigger before
            // placing the second body in its adjacent, currently visible tile.
            run.playerPosition = run.enemies[triggerIndex].position
            let occupied = Set(run.enemies.indices.filter { $0 != secondIndex }
                .map { run.enemies[$0].position })
            let adjacent = run.map.neighbours(of: run.enemies[triggerIndex].position)
                .first { run.map[$0].isPassable && !occupied.contains($0) }!
            for index in run.enemies.indices { run.enemies[index].isAwake = false }
            run.enemies[triggerIndex].isAwake = true
            run.enemies[secondIndex].isAwake = true
            run.enemies[secondIndex].position = adjacent
            let trigger = run.enemies[triggerIndex]
            state.worlds.activeRun = run
            WorldRules.beginEncounter(triggeredBy: trigger, runsAutomaticTurns: false, in: &state)
        }
        let preview = try XCTUnwrap(store.activeEncounter?.scalingPreview)
        return AdjacentGroupingSample(rootSeed: rootSeed,
                                      generatedPopulation: generatedPopulation,
                                      groupSize: try XCTUnwrap(preview.realFoeCount),
                                      inclusionReasons: preview.inclusionReasons)
    }
}
