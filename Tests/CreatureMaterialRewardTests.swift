import XCTest
@testable import Bookbinder

final class CreatureMaterialRewardTests: XCTestCase {
    func testSourceDangerFreezesSixExactBandsAndRejectsMismatchedInput() throws {
        XCTAssertEqual((0...5).map { WorldSourceDangerReceiptV1(sourceBand: $0).qualityInput },
                       [20, 35, 50, 65, 80, 95])
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with:
            SaveCodec.makeEncoder().encode(WorldSourceDangerReceiptV1(sourceBand: 2))) as? [String: Any])
        object["qualityInput"] = 51
        XCTAssertThrowsError(try SaveCodec.makeDecoder().decode(
            WorldSourceDangerReceiptV1.self,
            from: JSONSerialization.data(withJSONObject: object)))
        object["qualityInput"] = 50
        object["extra"] = true
        XCTAssertThrowsError(try SaveCodec.makeDecoder().decode(
            WorldSourceDangerReceiptV1.self,
            from: JSONSerialization.data(withJSONObject: object)))
    }

    func testQualityBandsAndHalfUpFormulaAreExact() {
        let boundaries: [(Int, CreatureMaterialQualityBand)] = [
            (24, .rough), (25, .standard), (54, .standard), (55, .fine),
            (74, .fine), (75, .superior), (89, .superior), (90, .exceptional),
            (97, .exceptional), (98, .peerless)
        ]
        for (score, band) in boundaries {
            XCTAssertEqual(CreatureMaterialRewardRules.qualityBand(score: score), band)
        }
        XCTAssertEqual(CreatureMaterialRewardRules.qualityScore(
            partExpression: 50, sourceQuality: 20), 43)
        XCTAssertEqual(CreatureMaterialRewardRules.qualityScore(
            partExpression: 49, sourceQuality: 35), 46)
    }

    func testExactSpeciesIdentityProducesOrderedProjectionUnits() throws {
        let projection = CreatureMaterialProjectionReceiptV1(entries: [
            .init(family: .hide,
                  capabilityA: .init(id: .coveringCoverage, value: 60),
                  capabilityB: .init(id: .derivedFlexibility, value: 40),
                  partExpression: 50, quantityPerDefeatedSpecimen: 2),
            .init(family: .bone,
                  capabilityA: .init(id: .boneDensity, value: 30),
                  capabilityB: .init(id: .size, value: 50),
                  partExpression: 40, quantityPerDefeatedSpecimen: 1)
        ])
        let speciesID = InstanceID(rawValue: 91)
        var run = fixtureRun()
        run.cast = [Species(id: speciesID, traits: CreatureTraits(), worldSeed: 8,
                            habitat: .terrestrial, materialProjection: projection)]
        var rng = SeededRNG(seed: 1)
        let foe = FoeState(id: InstanceID(rawValue: 7), speciesID: speciesID,
                           traits: CreatureTraits(),
                           stats: .init(displayName: "Same name", icon: "ant", maxHP: 1, attack: 1),
                           currentHP: 0)
        let encounter = CombatRules.makeEncounter(id: InstanceID(rawValue: 44), foes: [foe],
                                                   party: [.binder], rng: &rng)
        guard case .eligible(let receipt, let units) =
                CreatureMaterialRewardRules.evaluate(run: run, encounter: encounter) else {
            return XCTFail("expected exact generated-species reward")
        }
        XCTAssertEqual(receipt.entries.map(\.family), [.hide, .bone])
        XCTAssertEqual(receipt.entries.map(\.quantity), [2, 1])
        XCTAssertEqual(units.map(\.sample.kind), [.hide, .hide, .bone])
        XCTAssertEqual(Set(units.map(\.id)).count, 3)
        XCTAssertNoThrow(try receipt.validate())
    }

    func testAuthoredAndProjectionNilFoesDoNotFallThroughToGenericRewards() {
        var run = fixtureRun()
        let legacyID = InstanceID(rawValue: 92)
        run.cast = [Species(id: legacyID, traits: CreatureTraits(), worldSeed: 2)]
        let stats = CombatStats(displayName: "Same name", icon: "ant", maxHP: 1, attack: 1)
        var rng = SeededRNG(seed: 2)
        let encounter = CombatRules.makeEncounter(id: InstanceID(rawValue: 45), foes: [
            FoeState(id: InstanceID(rawValue: 8), creatureID: "paper_moth", stats: stats, currentHP: 0),
            FoeState(id: InstanceID(rawValue: 9), speciesID: legacyID, stats: stats, currentHP: 0)
        ], party: [.binder], rng: &rng)
        XCTAssertEqual(CreatureMaterialRewardRules.evaluate(run: run, encounter: encounter),
                       .noEligibleSpecimens)
    }

    func testDuplicateFoeAndSpeciesIdentityFailBeforeAllocation() {
        var run = fixtureRun()
        let species = Species(id: InstanceID(rawValue: 3), traits: CreatureTraits(), worldSeed: 1)
        run.cast = [species, species]
        let stats = CombatStats(displayName: "A", icon: "ant", maxHP: 1, attack: 1)
        let foe = FoeState(id: InstanceID(rawValue: 4), speciesID: species.id,
                           stats: stats, currentHP: 0)
        var rng = SeededRNG(seed: 3)
        let encounter = CombatRules.makeEncounter(id: InstanceID(rawValue: 46), foes: [foe],
                                                   party: [.binder], rng: &rng)
        XCTAssertEqual(CreatureMaterialRewardRules.evaluate(run: run, encounter: encounter),
                       .duplicateSpeciesIdentity)
    }

    func testSchemaFiveMigrationFreezesActiveAndAnchoredSourceDangerIdempotently() throws {
        let book = BoundBook(written: [], essencePaid: 0)
        let bookObject = try JSONSerialization.jsonObject(with: SaveCodec.makeEncoder().encode(book))
        let root: [String: Any] = [
            "schemaVersion": 5,
            "worlds": [
                "activeRun": ["book": bookObject],
                "anchoredRealms": [["world": ["book": bookObject]]]
            ]
        ]
        let migrated = try Migrations.migrateIfNeeded(
            JSONSerialization.data(withJSONObject: root, options: [.sortedKeys]))
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: migrated) as? [String: Any])
        XCTAssertEqual(object["schemaVersion"] as? Int, Tuning.saveSchemaVersion)
        let worlds = try XCTUnwrap(object["worlds"] as? [String: Any])
        let active = try XCTUnwrap(worlds["activeRun"] as? [String: Any])
        XCTAssertNotNil(active["sourceDangerReceipt"])
        let anchored = try XCTUnwrap(worlds["anchoredRealms"] as? [[String: Any]])
        XCTAssertNotNil((anchored[0]["world"] as? [String: Any])?["sourceDangerReceipt"])
        XCTAssertEqual(try Migrations.migrateIfNeeded(migrated), migrated)
    }

    func testSchemaFiveMalformedPresentSourceDangerFailsWithoutMutatingInput() throws {
        let book = try JSONSerialization.jsonObject(with:
            SaveCodec.makeEncoder().encode(BoundBook(written: [], essencePaid: 0)))
        let root: [String: Any] = [
            "schemaVersion": 5,
            "worlds": ["activeRun": ["book": book, "sourceDangerReceipt": NSNull()]]
        ]
        let raw = try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys])
        XCTAssertThrowsError(try Migrations.migrateIfNeeded(raw))
        XCTAssertEqual(try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys]), raw)
    }

    func testPendingEncounterRoundTripsWithoutMintingOrResolvingRewards() throws {
        var state = GameState.newGame()
        var run = fixtureRun()
        let stats = CombatStats(displayName: "Guardian", icon: "ant", maxHP: 4, attack: 1)
        var rng = SeededRNG(seed: 9)
        run.activeEncounter = CombatRules.makeEncounter(
            id: InstanceID(rawValue: 51),
            foes: [FoeState(id: InstanceID(rawValue: 52), creatureID: "paper_moth",
                            stats: stats, currentHP: 4)], party: [.binder], rng: &rng)
        state.worlds.activeRun = run
        let decoded = try SaveCodec.decode(SaveCodec.encode(state))
        XCTAssertEqual(decoded.worlds.activeRun?.activeEncounter, run.activeEncounter)
    }

    func testSchemaFivePendingGeneratedEncounterCopiesExactWorldEnemySpeciesAndAwardsAfterRelaunch() throws {
        let speciesID = InstanceID(rawValue: 91)
        let foeID = InstanceID(rawValue: 52)
        var state = GameState.newGame()
        var run = fixtureRun()
        let projection = CreatureMaterialProjectionReceiptV1(entries: [
            .init(family: .hide,
                  capabilityA: .init(id: .coveringCoverage, value: 60),
                  capabilityB: .init(id: .derivedFlexibility, value: 40),
                  partExpression: 50, quantityPerDefeatedSpecimen: 1)
        ])
        let traits = CreatureTraits()
        run.cast = [.init(id: speciesID, traits: traits, worldSeed: 8,
                          habitat: .terrestrial, materialProjection: projection)]
        run.enemies = [.init(id: foeID, speciesID: speciesID, traits: traits,
                             position: .init(x: 0, y: 0))]
        var rng = SeededRNG(seed: 9)
        run.activeEncounter = CombatRules.makeEncounter(
            id: .init(rawValue: 51),
            foes: [.init(id: foeID, traits: traits,
                         stats: .init(displayName: "Generated", icon: "ant", maxHP: 1, attack: 1),
                         currentHP: 0)], party: [.binder], rng: &rng)
        state.worlds.activeRun = run

        var root = try XCTUnwrap(JSONSerialization.jsonObject(
            with: SaveCodec.makeEncoder().encode(state)) as? [String: Any])
        root["schemaVersion"] = 5
        var worlds = try XCTUnwrap(root["worlds"] as? [String: Any])
        var active = try XCTUnwrap(worlds["activeRun"] as? [String: Any])
        active.removeValue(forKey: "sourceDangerReceipt")
        var encounter = try XCTUnwrap(active["activeEncounter"] as? [String: Any])
        active["activeEncounter"] = encounter; worlds["activeRun"] = active; root["worlds"] = worlds

        let migrated = try Migrations.migrateIfNeeded(
            JSONSerialization.data(withJSONObject: root, options: [.sortedKeys]))
        var decoded = try SaveCodec.decode(migrated)
        XCTAssertEqual(decoded.worlds.activeRun?.activeEncounter?.foes.first?.speciesID, speciesID)
        CombatRules.checkOutcome(in: &decoded)
        guard case .awarded(let receipt)? = decoded.worlds.activeRun?.activeEncounter?.creatureMaterialRewardResolution else {
            return XCTFail("victory must atomically award")
        }
        XCTAssertEqual(receipt.entries.first?.speciesID, speciesID)
        XCTAssertEqual(decoded.worlds.activeRun?.materialReserve.units.count, 1)
        let relaunched = try SaveCodec.decode(SaveCodec.encode(decoded))
        XCTAssertEqual(relaunched.worlds.activeRun?.creatureMaterialRewardReceipts, [receipt])
        XCTAssertEqual(relaunched.worlds.activeRun?.materialReserve.units.count, 1)
    }

    func testSchemaFiveTransitionalPendingRetainsMatchingSpeciesAndRejectsMismatchAtomically() throws {
        let speciesID = InstanceID(rawValue: 91)
        let foeID = InstanceID(rawValue: 52)
        var state = GameState.newGame()
        var run = fixtureRun()
        let traits = CreatureTraits()
        run.cast = [.init(id: speciesID, traits: traits, worldSeed: 8,
                          habitat: .terrestrial, materialProjection: .init(entries: []))]
        run.enemies = [.init(id: foeID, speciesID: speciesID, traits: traits,
                             position: .init(x: 0, y: 0))]
        var rng = SeededRNG(seed: 9)
        run.activeEncounter = CombatRules.makeEncounter(
            id: .init(rawValue: 51),
            foes: [.init(id: foeID, speciesID: speciesID, traits: traits,
                         stats: .init(displayName: "Generated", icon: "ant", maxHP: 1, attack: 1),
                         currentHP: 1)], party: [.binder], rng: &rng)
        state.worlds.activeRun = run

        func schemaFiveRoot() throws -> [String: Any] {
            var root = try XCTUnwrap(JSONSerialization.jsonObject(
                with: SaveCodec.makeEncoder().encode(state)) as? [String: Any])
            root["schemaVersion"] = 5
            var worlds = try XCTUnwrap(root["worlds"] as? [String: Any])
            var active = try XCTUnwrap(worlds["activeRun"] as? [String: Any])
            active.removeValue(forKey: "sourceDangerReceipt")
            worlds["activeRun"] = active; root["worlds"] = worlds
            return root
        }

        let matching = try schemaFiveRoot()
        let migrated = try Migrations.migrateIfNeeded(
            JSONSerialization.data(withJSONObject: matching, options: [.sortedKeys]))
        XCTAssertEqual(try SaveCodec.decode(migrated).worlds.activeRun?
            .activeEncounter?.foes.first?.speciesID, speciesID)

        var mismatched = try schemaFiveRoot()
        var worlds = try XCTUnwrap(mismatched["worlds"] as? [String: Any])
        var active = try XCTUnwrap(worlds["activeRun"] as? [String: Any])
        var encounter = try XCTUnwrap(active["activeEncounter"] as? [String: Any])
        var foes = try XCTUnwrap(encounter["foes"] as? [[String: Any]])
        foes[0]["speciesID"] = ["rawValue": 999]
        encounter["foes"] = foes; active["activeEncounter"] = encounter
        worlds["activeRun"] = active; mismatched["worlds"] = worlds
        let raw = try JSONSerialization.data(withJSONObject: mismatched, options: [.sortedKeys])
        XCTAssertThrowsError(try Migrations.migrateIfNeeded(raw))
        XCTAssertEqual(raw, try JSONSerialization.data(withJSONObject: mismatched, options: [.sortedKeys]))
    }

    func testSchemaFiveGeneratedEncounterWithoutExactWorldEnemyFailsAtomically() throws {
        var state = GameState.newGame()
        var run = fixtureRun()
        var rng = SeededRNG(seed: 1)
        run.activeEncounter = CombatRules.makeEncounter(
            id: .init(rawValue: 10),
            foes: [.init(id: .init(rawValue: 99), traits: CreatureTraits(),
                         stats: .init(displayName: "Generated", icon: "ant", maxHP: 1, attack: 1),
                         currentHP: 1)], party: [.binder], rng: &rng)
        state.worlds.activeRun = run
        var root = try XCTUnwrap(JSONSerialization.jsonObject(
            with: SaveCodec.makeEncoder().encode(state)) as? [String: Any])
        root["schemaVersion"] = 5
        var worlds = try XCTUnwrap(root["worlds"] as? [String: Any])
        var active = try XCTUnwrap(worlds["activeRun"] as? [String: Any])
        active.removeValue(forKey: "sourceDangerReceipt")
        var encounter = try XCTUnwrap(active["activeEncounter"] as? [String: Any])
        encounter.removeValue(forKey: "creatureMaterialRewardResolution")
        active["activeEncounter"] = encounter; worlds["activeRun"] = active; root["worlds"] = worlds
        let raw = try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys])
        XCTAssertThrowsError(try Migrations.migrateIfNeeded(raw))
        XCTAssertEqual(raw, try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys]))
    }

    func testCurrentSchemaSevenOmissionsFailClosedInsteadOfReconstructing() throws {
        var state = GameState.newGame()
        var run = fixtureRun()
        let stats = CombatStats(displayName: "Guardian", icon: "ant", maxHP: 4, attack: 1)
        var rng = SeededRNG(seed: 9)
        run.activeEncounter = CombatRules.makeEncounter(
            id: .init(rawValue: 51),
            foes: [.init(id: .init(rawValue: 52), creatureID: "paper_moth",
                         stats: stats, currentHP: 4)], party: [.binder], rng: &rng)
        state.worlds.activeRun = run
        let encoded = try SaveCodec.makeEncoder().encode(state)

        var missingDanger = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        var worlds = try XCTUnwrap(missingDanger["worlds"] as? [String: Any])
        var active = try XCTUnwrap(worlds["activeRun"] as? [String: Any])
        active.removeValue(forKey: "sourceDangerReceipt")
        worlds["activeRun"] = active; missingDanger["worlds"] = worlds
        XCTAssertThrowsError(try SaveCodec.decode(
            JSONSerialization.data(withJSONObject: missingDanger, options: [.sortedKeys])))

        var missingResolution = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        worlds = try XCTUnwrap(missingResolution["worlds"] as? [String: Any])
        active = try XCTUnwrap(worlds["activeRun"] as? [String: Any])
        var encounter = try XCTUnwrap(active["activeEncounter"] as? [String: Any])
        encounter.removeValue(forKey: "creatureMaterialRewardResolution")
        active["activeEncounter"] = encounter; worlds["activeRun"] = active
        missingResolution["worlds"] = worlds
        XCTAssertThrowsError(try SaveCodec.decode(
            JSONSerialization.data(withJSONObject: missingResolution, options: [.sortedKeys])))
    }

    func testGeneratedApexVictoryAwardsBodyMaterialsAndOneApexTrophy() throws {
        let speciesID = InstanceID(rawValue: 101)
        let foeID = InstanceID(rawValue: 102)
        let projection = CreatureMaterialProjectionReceiptV1(entries: [
            .init(family: .hide,
                  capabilityA: .init(id: .coveringCoverage, value: 60),
                  capabilityB: .init(id: .derivedFlexibility, value: 40),
                  partExpression: 50, quantityPerDefeatedSpecimen: 1)
        ])
        var state = GameState.newGame()
        var run = fixtureRun()
        run.cast = [.init(id: speciesID, traits: CreatureTraits(), worldSeed: 8,
                          habitat: .terrestrial, materialProjection: projection)]
        var rng = SeededRNG(seed: 9)
        run.activeEncounter = CombatRules.makeEncounter(
            id: .init(rawValue: 103),
            foes: [.init(id: foeID, speciesID: speciesID, traits: CreatureTraits(),
                         stats: .init(displayName: "Apex", icon: "ant", maxHP: 1, attack: 1),
                         currentHP: 0, isApex: true)], party: [.binder], rng: &rng)
        state.worlds.activeRun = run

        CombatRules.checkOutcome(in: &state)

        let awardedRun = try XCTUnwrap(state.worlds.activeRun)
        XCTAssertEqual(awardedRun.materialReserve.units.map(\.sample.kind), [.hide])
        XCTAssertEqual(awardedRun.creatureMaterialRewardReceipts.count, 1)
        let trophies = awardedRun.satchelItems.stacks + awardedRun.offeredItems
        XCTAssertEqual(trophies.count, 1)
        XCTAssertTrue(ApexRules.wildWeapons.contains(trophies[0].catalogID))
    }

    func testReturnFreezesRewardReceiptAndAnchoredSnapshotClearsExpeditionReceipt() throws {
        let speciesID = InstanceID(rawValue: 111)
        var run = fixtureRun()
        let projection = CreatureMaterialProjectionReceiptV1(entries: [
            .init(family: .bone,
                  capabilityA: .init(id: .boneDensity, value: 30),
                  capabilityB: .init(id: .size, value: 50),
                  partExpression: 40, quantityPerDefeatedSpecimen: 1)
        ])
        run.cast = [.init(id: speciesID, traits: CreatureTraits(), worldSeed: 8,
                          habitat: .terrestrial, materialProjection: projection)]
        var rng = SeededRNG(seed: 4)
        let encounter = CombatRules.makeEncounter(
            id: .init(rawValue: 112),
            foes: [.init(id: .init(rawValue: 113), speciesID: speciesID,
                         stats: .init(displayName: "Animal", icon: "ant", maxHP: 1, attack: 1),
                         currentHP: 0)], party: [.binder], rng: &rng)
        guard case .eligible(let receipt, _) =
                CreatureMaterialRewardRules.evaluate(run: run, encounter: encounter) else {
            return XCTFail("expected reward receipt")
        }
        run.creatureMaterialRewardReceipts = [receipt]
        let summary = RunExitSummary(runIndex: run.runIndex, kind: .portal, reason: "fixture",
                                     turnsTaken: run.turnsTaken, haulKeptFraction: 1,
                                     creatureMaterialRewardReceipts: run.creatureMaterialRewardReceipts)

        XCTAssertEqual(summary.creatureMaterialRewardReceipts, [receipt])
        XCTAssertEqual(try SaveCodec.makeDecoder().decode(
            RunExitSummary.self, from: SaveCodec.makeEncoder().encode(summary)), summary)
        XCTAssertTrue(run.anchoredSnapshot.creatureMaterialRewardReceipts.isEmpty)
    }

    private func fixtureRun() -> WorldRun {
        let point = GridPoint(x: 0, y: 0)
        return WorldRun(runIndex: 3, book: BoundBook(written: [], essencePaid: 0),
                        mapSeed: 5, rng: SeededRNG(seed: 6),
                        map: WorldMap(width: 1, height: 1,
                                      tiles: [Tile(isRevealed: true)], entry: point),
                        playerPosition: point,
                        sourceDangerReceipt: .init(sourceBand: 2))
    }
}
