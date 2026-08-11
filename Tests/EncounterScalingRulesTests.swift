import XCTest
@testable import Bookbinder

final class EncounterScalingRulesTests: XCTestCase {
    private func member(_ identity: String, _ level: Int) -> EncounterScalingRules.PartyMemberInput {
        .init(identity: identity, level: level)
    }

    func testEqualLevelPartiesReproduceExactRecommendedBudgetsAndApexValues() {
        for level in [1, 8, 16] {
            for count in 1...5 {
                let companions = (1..<count).map { member("m\($0)", level) }
                let ledger = EncounterScalingRules.partyPower(anchorLevel: level, companions: companions)
                XCTAssertEqual(ledger.cappedBudget, 1 + 0.5 * Double(count - 1), accuracy: 0.000_001)
                XCTAssertEqual(ledger.scalingRulesVersion,
                               EncounterScalingRules.additivePartyPowerRulesVersion)
                XCTAssertEqual(ledger.anchorLevel, level)
                XCTAssertEqual(ledger.contributions.first?.identity, "binder")

                let apex = EncounterScalingRules.additiveApexValues(
                    ledger: ledger, worldLevel: 1, partyCount: count)
                XCTAssertEqual(apex.levelFloor, level + 2)
                XCTAssertEqual(apex.hp, min(2.4, 1 + 0.35 * Double(count - 1)), accuracy: 0.000_001)
                XCTAssertEqual(apex.offence, min(1.4, 1 + 0.10 * Double(count - 1)), accuracy: 0.000_001)
                XCTAssertEqual(apex.slots, count <= 2 ? 1 : (count <= 4 ? 2 : 3))
            }
        }
    }

    func testEveryLevelInDomainAddsNonnegativePowerAndCannotLowerApexScaling() {
        for anchor in 1...25 {
            let baseline = EncounterScalingRules.partyPower(anchorLevel: anchor, companions: [])
            for level in 1...25 {
                let one = EncounterScalingRules.partyPower(
                    anchorLevel: anchor, companions: [member("one", level)])
                XCTAssertGreaterThanOrEqual(one.cappedBudget, baseline.cappedBudget)
                XCTAssertGreaterThanOrEqual(one.contributions[1].contribution, 0.25)
                XCTAssertLessThanOrEqual(one.contributions[1].contribution, 1.5)
                var previous = one
                for count in 2...4 {
                    let next = EncounterScalingRules.partyPower(
                        anchorLevel: anchor,
                        companions: (1...count).map { member("m\($0)", level) })
                    XCTAssertGreaterThanOrEqual(next.cappedBudget, previous.cappedBudget)
                    let oldApex = EncounterScalingRules.additiveApexValues(
                        ledger: previous, worldLevel: 1, partyCount: count)
                    let newApex = EncounterScalingRules.additiveApexValues(
                        ledger: next, worldLevel: 1, partyCount: count + 1)
                    XCTAssertGreaterThanOrEqual(newApex.hp, oldApex.hp)
                    XCTAssertGreaterThanOrEqual(newApex.offence, oldApex.offence)
                    XCTAssertGreaterThanOrEqual(newApex.levelFloor, oldApex.levelFloor)
                    previous = next
                }
            }
        }
    }

    func testExtremeLevelClampsAreExact() {
        let low = EncounterScalingRules.partyPower(
            anchorLevel: 25, companions: [member("low", 1)])
        XCTAssertEqual(low.contributions[1].contribution, 0.25)
        let high = EncounterScalingRules.partyPower(
            anchorLevel: 1, companions: [member("high", 25)])
        XCTAssertEqual(high.contributions[1].contribution, 1.5)
    }

    func testCompanionReorderingChangesNeitherLedgerNorBudget() {
        let members = [member("c", 3), member("a", 19), member("d", 1), member("b", 8)]
        let expected = EncounterScalingRules.partyPower(anchorLevel: 9, companions: members)
        for permutation in permutations(members) {
            XCTAssertEqual(EncounterScalingRules.partyPower(anchorLevel: 9,
                                                             companions: permutation), expected)
        }
    }

    func testNamedMonotonicVectorsNeverFall() {
        let vectors = [
            (9, [[Int](), [1], [1, 1]]),
            (1, [[Int](), [9], [9, 9]]),
            (2, [[4, 6, 20], [4, 6, 8, 20]])
        ]
        for (anchor, steps) in vectors {
            var last = 0.0
            for levels in steps {
                let ledger = EncounterScalingRules.partyPower(
                    anchorLevel: anchor,
                    companions: levels.enumerated().map { member("m\($0.offset)", $0.element) })
                XCTAssertGreaterThanOrEqual(ledger.cappedBudget, last)
                last = ledger.cappedBudget
            }
        }
    }

    func testCompanionInputsExposeCurrentStableIdentityBoundary() {
        var state = GameState.newGame()
        state.base.roster[0].character.level = 6
        state.base.activeParty = [0]
        XCTAssertEqual(EncounterScalingRules.companionInputs(in: state),
                       [member("quill", 6)])
        state.base.roster[0].traveller = "mara"
        XCTAssertEqual(EncounterScalingRules.companionInputs(in: state),
                       [member("traveller:mara", 6)])
    }

    func testOrdinaryPressureExamplesUseSlotsPlusFractionalDurability() {
        let examples: [(Double, Int, Int, Double, Double)] = [
            (1.5, 1, 0, 0.5, 0.15),
            (2.0, 1, 1, 0, 0.15),
            (2.5, 2, 0, 0.5, 0.15),
            (3.0, 1, 2, 0, 0.30),
            (3.0, 2, 1, 0, 0.15),
            (3.0, 3, 0, 0, 0)
        ]
        for (budget, foes, slots, fraction, hp) in examples {
            let pressure = EncounterScalingRules.additivePressure(
                partyPowerBudget: budget, realFoeCount: foes)
            XCTAssertEqual(pressure.wholePressureSlots, slots)
            XCTAssertEqual(pressure.fractionalShortfall, fraction, accuracy: 0.000_001)
            XCTAssertEqual(pressure.totalHPAdditionFraction, hp, accuracy: 0.000_001)
        }
    }

    func testAdditivePreviewPopulatesNewLedgerAndNeutralizesHistoricalLevelAdjustment() {
        let foe = WorldEnemy(id: InstanceID(rawValue: 4),
                             position: GridPoint(x: 0, y: 0))
        let preview = EncounterScalingRules.additivePreview(
            anchorLevel: 8, companions: [member("traveller:mara", 8)],
            visibleFoes: [foe], worldLevel: 8, groupingRadius: 1,
            inclusionReasons: ["4": "triggering map entity"],
            exclusionReasons: ["9": "outside gathering radius"])
        XCTAssertEqual(preview.scalingRulesVersion,
                       EncounterScalingRules.additivePartyPowerRulesVersion)
        XCTAssertEqual(preview.anchorLevel, 8)
        XCTAssertEqual(preview.cappedPartyPowerBudget, 1.5)
        XCTAssertEqual(preview.realFoeCount, 1)
        XCTAssertEqual(preview.shortfall, 0.5)
        XCTAssertEqual(preview.wholePressureSlots, 0)
        XCTAssertEqual(preview.fractionalShortfall, 0.5)
        XCTAssertEqual(preview.totalHPAdditionFraction, 0.15)
        XCTAssertEqual(preview.hpAllocationByFoeID, [:])
        XCTAssertEqual(preview.exclusionReasons?["9"], "outside gathering radius")
        XCTAssertEqual(preview.missingFoeConversion, 0)
        XCTAssertEqual(preview.remainderUpgrade, 0)
        XCTAssertEqual(preview.totalOrdinaryLevelAdjustment, 0)
    }

    func testNewAndMissingPreferencesUseRecommendedButFrozenLegacyDecodeStaysLegacy() throws {
        XCTAssertEqual(DebugTuningProfile.defaults.encounterScalingProfile, .recommended)
        XCTAssertEqual(DebugTuningProfile.defaults.encounterScalingProfileSchemaVersion, 2)
        XCTAssertEqual(DebugTuningProfile.legacyFrozenRunDefaults.encounterScalingProfile, .current)
        XCTAssertEqual(DebugTuningProfile.legacyFrozenRunDefaults.encounterScalingProfileSchemaVersion, 1)

        let frozenLegacy = try JSONDecoder().decode(DebugTuningProfile.self,
                                                     from: Data("{}".utf8))
        XCTAssertEqual(frozenLegacy.encounterScalingProfile, .current)
        XCTAssertEqual(frozenLegacy.encounterScalingProfileSchemaVersion, 1)

        let suite = "encounter-scaling-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(Data("{}".utf8), forKey: DebugTuningProfile.storageKey)
        let migrated = DebugTuningProfile.load(from: defaults)
        XCTAssertEqual(migrated.encounterScalingProfile, .recommended)
        XCTAssertEqual(migrated.encounterScalingProfileSchemaVersion, 2)
        let persisted = try XCTUnwrap(defaults.data(forKey: DebugTuningProfile.storageKey))
        let persistedProfile = try JSONDecoder().decode(DebugTuningProfile.self, from: persisted)
        XCTAssertEqual(persistedProfile.encounterScalingProfile, .recommended)
        XCTAssertEqual(persistedProfile.encounterScalingProfileSchemaVersion, 2)
    }

    func testExplicitLegacySurvivesAfterPreferenceMigrationVersion() throws {
        var deliberate = DebugTuningProfile()
        deliberate.encounterScalingProfile = .current
        deliberate.encounterScalingProfileSchemaVersion = 2
        let suite = "encounter-scaling-explicit-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(try JSONEncoder().encode(deliberate),
                     forKey: DebugTuningProfile.storageKey)
        XCTAssertEqual(DebugTuningProfile.load(from: defaults).encounterScalingProfile, .current)
    }

    func testHistoricalPreviewWithoutAdditiveFieldsStillDecodes() throws {
        let foe = WorldEnemy(id: InstanceID(rawValue: 4),
                             position: GridPoint(x: 0, y: 0))
        let historical = EncounterScalingRules.preview(
            profile: .recommended, partyLevels: [8, 8], visibleFoes: [foe],
            mapSeed: 1, triggerID: foe.id, worldLevel: 8)
        let data = try JSONEncoder().encode(historical)
        let decoded = try JSONDecoder().decode(EncounterScalingRules.Preview.self, from: data)
        XCTAssertEqual(decoded, historical)
        XCTAssertNil(decoded.scalingRulesVersion)
        XCTAssertNil(decoded.partyPowerLedger)
    }

    func testOrdinaryPressureTurnSlotKindRoundTrips() throws {
        let slot = EncounterState.TurnSlot(actor: .foe(InstanceID(rawValue: 7)),
                                           kind: .ordinaryPressureFollowUp(2),
                                           strengthMultiplier: 0.55,
                                           suppressesAfflictions: true)
        let decoded = try JSONDecoder().decode(
            EncounterState.TurnSlot.self, from: JSONEncoder().encode(slot))
        XCTAssertEqual(decoded, slot)
    }

    private func permutations<T>(_ values: [T]) -> [[T]] {
        guard let first = values.first else { return [[]] }
        return permutations(Array(values.dropFirst())).flatMap { tail in
            (0...tail.count).map { index in
                var value = tail
                value.insert(first, at: index)
                return value
            }
        }
    }
}
