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
        XCTAssertEqual(object["schemaVersion"] as? Int, 6)
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
