import XCTest
@testable import Bookbinder

final class CreatureMaterialProjectionTests: XCTestCase {
    func testFeatherAndDownFreezeExactCapabilitiesExpressionAndQuantity() throws {
        var traits = CreatureTraits()
        traits.size = 60
        traits.appendages = Appendages(count: 4, type: .feathered)
        traits.covering = Covering(hardness: 20, length: 60, coverage: 60)
        traits.finish.shine = 30
        traits.finish.schiller = 20

        let receipt = try frozen(traits, habitat: .terrestrial)
        XCTAssertEqual(receipt.entries.map(\.family), [.feather, .down])
        assert(receipt.entries[0], .feather, .derivedAppendageExtent, 50,
               .derivedFinishLustre, 50, expression: 50, quantity: 3)
        assert(receipt.entries[1], .down, .derivedInsulation, 36,
               .derivedFlexibility, 64, expression: 50, quantity: 3)
    }

    func testAquaticScaledFixtureFreezesCanonicalOrder() throws {
        var traits = CreatureTraits()
        traits.size = 50
        traits.bodyPlan = .piscine
        traits.covering = Covering(hardness: 40, length: 80, coverage: 60)
        traits.appendages = Appendages(count: 6, type: .finned)
        traits.boneDensity = 30
        traits.armament.pierce = 50
        traits.armament.crush = 0
        traits.armament.rend = 0

        let receipt = try frozen(traits, habitat: .aquatic)
        XCTAssertEqual(receipt.entries.map(\.family), [.scale, .fin, .fang, .bone, .oil])
        XCTAssertEqual(receipt.entries.map(\.partExpression), [50, 65, 40, 40, 49])
        XCTAssertEqual(receipt.entries.map(\.quantityPerDefeatedSpecimen), [3, 3, 1, 2, 1])
    }

    func testAmorphousToxicFixtureHasSpecialsAndNoBone() throws {
        var traits = CreatureTraits()
        traits.bodyPlan = .amorphous
        traits.covering.coverage = 0
        traits.boneDensity = 100
        traits.isToxic = true
        traits.coloration.patterning = 80
        traits.ornament = 40
        traits.emanation = Emanation(strength: 80, light: 60, heat: 20, caustic: 20)
        traits.finish.shine = 20
        traits.finish.schiller = 10

        let receipt = try frozen(traits, habitat: .terrestrial)
        XCTAssertEqual(receipt.entries.map(\.family), [.venom, .ichor])
        XCTAssertEqual(receipt.entries.map(\.partExpression), [74, 55])
        XCTAssertEqual(receipt.entries.map(\.quantityPerDefeatedSpecimen), [1, 2])
    }

    func testAllTenPrimaryRulesUseFrozenFirstMatchOrder() throws {
        func primary(body: CreatureBodyPlan = .quadruped,
                     appendage: AppendageType = .none, count: Int = 0,
                     hardness: Double, length: Double = 0, coverage: Double,
                     habitat: CreatureHabitat = .terrestrial) throws -> CreatureMaterialFamilyID? {
            var traits = CreatureTraits()
            traits.bodyPlan = body
            traits.appendages = Appendages(count: count, type: appendage)
            traits.covering = Covering(hardness: hardness, length: length, coverage: coverage)
            return try frozen(traits, habitat: habitat).entries.first?.family
        }
        XCTAssertEqual(try primary(appendage: .feathered, count: 1,
                                   hardness: 100, coverage: 100), .feather)
        XCTAssertEqual(try primary(hardness: 25, coverage: 15, habitat: .aquatic), .scale)
        XCTAssertEqual(try primary(body: .piscine, hardness: 24, coverage: 15), .hide)
        XCTAssertEqual(try primary(body: .segmented, hardness: 55, coverage: 15), .chitin)
        XCTAssertEqual(try primary(body: .radial, hardness: 55, coverage: 15), .shell)
        XCTAssertEqual(try primary(hardness: 55, length: 45, coverage: 15), .quill)
        XCTAssertEqual(try primary(hardness: 70, coverage: 15), .plate)
        XCTAssertEqual(try primary(hardness: 35, coverage: 15), .scale)
        XCTAssertEqual(try primary(hardness: 34, length: 45, coverage: 50), .pelt)
        XCTAssertEqual(try primary(hardness: 0, coverage: 15), .hide)
        XCTAssertNil(try primary(hardness: 100, coverage: 14.9))
    }

    func testArmamentDominanceUsesClampedValuesAndPierceCrushRendTieOrder() throws {
        func armamentFamily(pierce: Double, crush: Double,
                            rend: Double) throws -> CreatureMaterialFamilyID? {
            var traits = CreatureTraits()
            traits.bodyPlan = .amorphous
            traits.armament.pierce = pierce
            traits.armament.crush = crush
            traits.armament.rend = rend
            return try frozen(traits, habitat: .terrestrial).entries.first?.family
        }
        XCTAssertEqual(try armamentFamily(pierce: 101, crush: 102, rend: 0), .fang,
                       "clamping creates a 100/100 tie owned by Pierce")
        XCTAssertEqual(try armamentFamily(pierce: 99, crush: 102, rend: 0), .tusk,
                       "a strictly greater clamped Crush value owns the armament")
        XCTAssertEqual(try armamentFamily(pierce: 0, crush: 99, rend: 102), .claw,
                       "a strictly greater clamped Rend value owns the armament")
    }

    func testLegacyNilAndEcologyAwareCastFreezeWithoutChangingLegacyCast() throws {
        let readings = PressureRules.resolve([])
        let legacy = LifeRules.cast(for: readings, seed: 411)
        XCTAssertTrue(legacy.allSatisfy { $0.habitat == nil && $0.materialProjection == nil })

        let map = WorldMap(width: 5, height: 5,
                           tiles: Array(repeating: Tile(ground: .soil), count: 25),
                           entry: GridPoint(x: 0, y: 2))
        let habitats = CreatureHabitatAvailability.resolve(in: map, from: GridPoint(x: 2, y: 2))
        let frozenCast = LifeRules.cast(for: readings, seed: 411, habitats: habitats)
        XCTAssertEqual(frozenCast.map { $0.id }, legacy.map { $0.id })
        XCTAssertEqual(frozenCast.map { $0.traits }, legacy.map { $0.traits })
        XCTAssertTrue(frozenCast.allSatisfy { $0.habitat != nil && $0.materialProjection != nil })
    }

    func testValidationRejectsDuplicateWrongOrderAndInconsistentExpression() throws {
        var traits = CreatureTraits()
        traits.covering.coverage = 20
        let entry = try XCTUnwrap(frozen(traits, habitat: .terrestrial).entries.first)
        XCTAssertThrowsError(try CreatureMaterialProjectionRules.validate(
            CreatureMaterialProjectionReceiptV1(entries: [entry, entry])))
        var inconsistent = entry
        inconsistent.partExpression += 1
        XCTAssertThrowsError(try CreatureMaterialProjectionRules.validate(
            CreatureMaterialProjectionReceiptV1(entries: [inconsistent])))
    }

    func testSchemaFourMigrationFreezesActiveAndAnchoredButPreservesLegacyNil() throws {
        let ecology = #"{"id":{"rawValue":1},"traits":{},"worldSeed":9,"habitat":"terrestrial"}"#
        let legacy = #"{"id":{"rawValue":2},"traits":{},"worldSeed":9}"#
        let raw = Data(#"{"schemaVersion":4,"worlds":{"activeRun":{"cast":[\#(ecology),\#(legacy)]},"anchoredRealms":[{"world":{"cast":[\#(ecology)]}}]}}"#.utf8)
        let migrated = try Migrations.migrateIfNeeded(raw)
        let root = try XCTUnwrap(JSONSerialization.jsonObject(with: migrated) as? [String: Any])
        XCTAssertEqual(root["schemaVersion"] as? Int, 5)
        let worlds = try XCTUnwrap(root["worlds"] as? [String: Any])
        let active = try XCTUnwrap(worlds["activeRun"] as? [String: Any])
        let cast = try XCTUnwrap(active["cast"] as? [[String: Any]])
        XCTAssertNotNil(cast[0]["materialProjection"])
        XCTAssertNil(cast[1]["materialProjection"])
        XCTAssertEqual(try Migrations.migrateIfNeeded(migrated), migrated)
    }

    func testPersistedProjectionIsValidatedButNotComparedWithCurrentTraits() throws {
        var traits = CreatureTraits()
        traits.covering.coverage = 80
        let receipt = try frozen(traits, habitat: .terrestrial)
        let species = Species(id: InstanceID(rawValue: 9), traits: CreatureTraits(), worldSeed: 2,
                              habitat: .terrestrial, materialProjection: receipt)
        XCTAssertEqual(try SaveCodec.makeDecoder().decode(
            Species.self, from: SaveCodec.makeEncoder().encode(species)).materialProjection, receipt)
    }

    func testStrictPersistedShapeRejectsNullFutureUnknownAndExtraFields() throws {
        let valid = try frozen(CreatureTraits(), habitat: .terrestrial)
        let validObject = try XCTUnwrap(JSONSerialization.jsonObject(
            with: SaveCodec.makeEncoder().encode(valid)) as? [String: Any])
        let mutations: [(String, (inout [String: Any]) -> Void)] = [
            ("future", { $0["schemaVersion"] = 2 }),
            ("authority", { $0["authorityID"] = "later-authority" }),
            ("extra", { $0["unexpected"] = true }),
            ("null entries", { $0["entries"] = NSNull() }),
        ]
        for (name, mutate) in mutations {
            var object = validObject
            mutate(&object)
            XCTAssertThrowsError(try SaveCodec.makeDecoder().decode(
                CreatureMaterialProjectionReceiptV1.self,
                from: JSONSerialization.data(withJSONObject: object)), name)
        }

        let speciesWithNullProjection = Data(
            #"{"id":{"rawValue":1},"traits":{},"worldSeed":2,"habitat":"terrestrial","materialProjection":null}"#.utf8)
        XCTAssertThrowsError(try SaveCodec.makeDecoder().decode(
            Species.self, from: speciesWithNullProjection))
    }

    func testMigrationFailurePreservesRawAndRealSlotEnvelopeBytes() async throws {
        let malformedProjection = #"{"schemaVersion":2,"authorityID":"creature-material-projection-v1","entries":[]}"#
        let raw = Data(#"{"schemaVersion":4,"worlds":{"activeRun":{"cast":[{"id":{"rawValue":1},"traits":{},"worldSeed":9,"habitat":"terrestrial","materialProjection":\#(malformedProjection)}]}}}"#.utf8)
        XCTAssertThrowsError(try Migrations.migrateIfNeeded(raw))

        let root = FileManager.default.temporaryDirectory
            .appending(path: "bookbinder-projection-slot/\(UUID().uuidString)",
                       directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: root) }
        let slots = SaveSlotFileIO(directory: root)
        let created = try await slots.create(name: "Projection migration")
        let url = try await slots.exportURL(for: created.metadata.id)
        var envelope = try SaveCodec.makeDecoder().decode(
            SaveSlotEnvelope.self, from: Data(contentsOf: url))
        envelope.payload = raw
        let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601
        let originalEnvelope = try encoder.encode(envelope)
        try originalEnvelope.write(to: url, options: .atomic)

        do {
            _ = try await slots.load(created.metadata.id)
            XCTFail("malformed projection should fail the slot load")
        } catch { }
        XCTAssertEqual(try Data(contentsOf: url), originalEnvelope)
    }

    func testRealSlotMigratesActiveAndAnchoredEcologyAndIsIdempotent() async throws {
        let ecology = Species(id: InstanceID(rawValue: 41), traits: CreatureTraits(), worldSeed: 9,
                              habitat: .terrestrial, materialProjection: nil)
        let legacy = Species(id: InstanceID(rawValue: 42), traits: CreatureTraits(), worldSeed: 9)
        func run(_ index: Int) -> WorldRun {
            WorldRun(runIndex: index, book: BoundBook(written: [], essencePaid: 0), mapSeed: 9,
                     rng: SeededRNG(seed: 9),
                     map: WorldMap(width: 2, height: 1, tiles: [Tile(), Tile()],
                                   entry: GridPoint(x: 0, y: 0)),
                     playerPosition: GridPoint(x: 0, y: 0), cast: [ecology, legacy])
        }
        var state = GameState.newGame()
        state.worlds.activeRun = run(1)
        state.worlds.anchoredRealms = [AnchoredRealm(
            runIndex: 2, name: "Frozen", route: .naturalPoint, world: run(2))]
        var object = try XCTUnwrap(JSONSerialization.jsonObject(
            with: SaveCodec.encode(state)) as? [String: Any])
        object["schemaVersion"] = 4
        let payload = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])

        let root = FileManager.default.temporaryDirectory
            .appending(path: "bookbinder-projection-slot/\(UUID().uuidString)",
                       directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: root) }
        let slots = SaveSlotFileIO(directory: root)
        let created = try await slots.create(name: "Ecology migration")
        let url = try await slots.exportURL(for: created.metadata.id)
        var envelope = try SaveCodec.makeDecoder().decode(
            SaveSlotEnvelope.self, from: Data(contentsOf: url))
        envelope.payload = payload
        let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(envelope).write(to: url, options: .atomic)

        let migrated = try await slots.load(created.metadata.id).state
        XCTAssertNotNil(migrated.worlds.activeRun?.cast[0].materialProjection)
        XCTAssertNil(migrated.worlds.activeRun?.cast[1].materialProjection)
        XCTAssertNotNil(migrated.worlds.anchoredRealms[0].world.cast[0].materialProjection)
        _ = try await slots.save(created.metadata.id, state: migrated)
        let relaunched = try await slots.load(created.metadata.id).state
        XCTAssertEqual(relaunched, migrated)
    }

    private func frozen(_ traits: CreatureTraits,
                        habitat: CreatureHabitat) throws -> CreatureMaterialProjectionReceiptV1 {
        guard case .frozen(let receipt) = CreatureMaterialProjectionRules.freeze(
            traits: traits, habitat: habitat) else { throw CocoaError(.coderInvalidValue) }
        try CreatureMaterialProjectionRules.validate(receipt)
        return receipt
    }

    private func assert(_ entry: CreatureMaterialProjectionEntryV1,
                        _ family: CreatureMaterialFamilyID,
                        _ a: CreatureMaterialCapabilityID, _ av: Double,
                        _ b: CreatureMaterialCapabilityID, _ bv: Double,
                        expression: Int, quantity: Int, file: StaticString = #filePath,
                        line: UInt = #line) {
        XCTAssertEqual(entry.family, family, file: file, line: line)
        XCTAssertEqual(entry.capabilityA, .init(id: a, value: av), file: file, line: line)
        XCTAssertEqual(entry.capabilityB, .init(id: b, value: bv), file: file, line: line)
        XCTAssertEqual(entry.partExpression, expression, file: file, line: line)
        XCTAssertEqual(entry.quantityPerDefeatedSpecimen, quantity, file: file, line: line)
    }
}
