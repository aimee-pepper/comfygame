import XCTest
@testable import Bookbinder

final class AnimalCompanionCombatTests: XCTestCase {
    private func animalState(posting: AnimalPostingV1 = .menagerie,
                             level: Int = 1) throws -> (GameState, TamedAnimalID) {
        var state = GameState.newGame()
        let enemyID = InstanceID(rawValue: 501)
        let seed: UInt64 = 9001
        let condition = RealityState.AnimalTrustConditionV1.usefulOffering(
            property: .hardness, threshold: 0)
        let trust = RealityState.AnimalTrustRecordV1(
            worldSeed: seed, enemyID: enemyID, speciesID: InstanceID(rawValue: 77), creatureID: nil,
            traits: CreatureTraits(), condition: condition, progress: 1,
            firstAttendedRunIndex: 1, firstAttendedTurn: 2, lastProgressTurn: nil,
            interactionCount: 1, completed: true)
        let rawID = "tamed:\(seed):\(enemyID.rawValue)"
        let tamed = RealityState.TamedAnimalV1(
            id: rawID, originWorldSeed: seed, originEnemyID: enemyID,
            speciesID: InstanceID(rawValue: 77), creatureID: nil, traits: trust.traits,
            trustCondition: condition, joinedRunIndex: 1, joinedTurn: 4)
        let id = TamedAnimalID(rawValue: rawID)
        let receipt = try XCTUnwrap(AnimalCompanionCombatRules.originReceipt(
            animal: tamed, displayName: "Test animal", icon: "questionmark",
            level: level, provenance: .legacySchema14LevelOne))
        state.reality.animalTrustRecords[trust.key] = trust
        state.reality.tamedAnimals[rawID] = tamed
        state.base.tamedAnimalCompanions[id] = .init(
            id: id, originReceipt: receipt, level: level,
            experience: CharacterRules.experienceForLevel(level), gambits: [], posting: posting)
        if posting == .activeParty {
            state.base.activeParty.append(.animal(rawID))
        }
        return (state, id)
    }

    func testDominantTechniqueUsesOnlySavedDefenceBranch() {
        var traits = CreatureTraits()
        traits.defence = .armour
        XCTAssertEqual(AnimalCompanionCombatRules.dominantTechnique(for: traits), .interpose)
        traits.defence = .speed
        XCTAssertEqual(AnimalCompanionCombatRules.dominantTechnique(for: traits), .harrier)
        traits.defence = .crypsis
        XCTAssertEqual(AnimalCompanionCombatRules.dominantTechnique(for: traits), .slipAway)
        traits.defence = .aposematism
        XCTAssertEqual(AnimalCompanionCombatRules.dominantTechnique(for: traits), .warningDisplay)
        traits.defence = nil
        XCTAssertEqual(AnimalCompanionCombatRules.dominantTechnique(for: traits), .commit)
    }

    func testExactAnimalPartyPostingAndCapacityAreAtomic() throws {
        var (state, id) = try animalState()
        let quote = try AnimalCompanionCombatRules.evaluatePartyChange(id, in: state).get()
        XCTAssertEqual(AnimalCompanionCombatRules.commitPartyChange(quote, in: &state), .committed)
        XCTAssertEqual(state.base.tamedAnimalCompanions[id]?.posting, .activeParty)
        XCTAssertTrue(state.base.activeParty.contains(.animal(id.rawValue)))

        let before = try SaveCodec.makeEncoder().encode(state)
        var stale = quote
        stale.expected.level = 2
        XCTAssertEqual(AnimalCompanionCombatRules.commitPartyChange(stale, in: &state),
                       .refused(.staleQuote))
        XCTAssertEqual(try SaveCodec.makeEncoder().encode(state), before)
    }

    func testSchemaFourteenMigratesTamedAnimalsToLevelOneMenagerie() throws {
        var (legacy, id) = try animalState()
        legacy.schemaVersion = 14
        legacy.base.tamedAnimalCompanions = [:]
        var root = try XCTUnwrap(JSONSerialization.jsonObject(
            with: SaveCodec.makeEncoder().encode(legacy)) as? [String: Any])
        var base = try XCTUnwrap(root["base"] as? [String: Any])
        base.removeValue(forKey: "tamedAnimalCompanions")
        root["base"] = base
        let raw = try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys])

        let migrated = try Migrations.migrateIfNeeded(raw)
        let decoded = try SaveCodec.makeDecoder().decode(GameState.self, from: migrated)
        let companion = try XCTUnwrap(decoded.base.tamedAnimalCompanions[id])
        XCTAssertEqual(decoded.schemaVersion, 15)
        XCTAssertEqual(companion.level, 1)
        XCTAssertEqual(companion.experience, 0)
        XCTAssertEqual(companion.posting, .menagerie)
        XCTAssertEqual(companion.originReceipt.sourceProvenance, .legacySchema14LevelOne)
        XCTAssertTrue(decoded.validatesAnimalCompanionCombat())
    }

    func testCurrentMissingCompanionOwnerFailsBeforeStateConstruction() throws {
        let (state, _) = try animalState()
        var root = try XCTUnwrap(JSONSerialization.jsonObject(
            with: SaveCodec.makeEncoder().encode(state)) as? [String: Any])
        var base = try XCTUnwrap(root["base"] as? [String: Any])
        base.removeValue(forKey: "tamedAnimalCompanions")
        root["base"] = base
        let raw = try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys])
        XCTAssertThrowsError(try Migrations.migrateIfNeeded(raw))
    }

    func testMalformedAnimalCompanionRealSlotPreservesExactEnvelope() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("animal-companion-slot-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let slots = SaveSlotFileIO(directory: directory)
        let created = try await slots.create(name: "Animal companion malformed")
        let url = try await slots.exportURL(for: created.metadata.id)
        var envelope = try SaveCodec.makeDecoder().decode(
            SaveSlotEnvelope.self, from: Data(contentsOf: url))
        let (state, id) = try animalState()
        var root = try XCTUnwrap(JSONSerialization.jsonObject(
            with: SaveCodec.makeEncoder().encode(state)) as? [String: Any])
        var base = try XCTUnwrap(root["base"] as? [String: Any])
        var companions = try XCTUnwrap(base["tamedAnimalCompanions"] as? [String: Any])
        var malformed = try XCTUnwrap(companions[id.rawValue] as? [String: Any])
        malformed["version"] = 2
        companions[id.rawValue] = malformed
        base["tamedAnimalCompanions"] = companions
        root["base"] = base
        envelope.payload = try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys])
        try SaveCodec.makeEncoder().encode(envelope).write(to: url, options: .atomic)
        let before = try Data(contentsOf: url)

        do {
            _ = try await slots.load(created.metadata.id)
            XCTFail("future companion receipt loaded")
        } catch {}
        XCTAssertEqual(try Data(contentsOf: url), before)
    }

    func testAnimalParticipantFreezesScaledIdentityAndNoWitSlots() throws {
        let (state, id) = try animalState(posting: .activeParty, level: 5)
        let companion = try XCTUnwrap(state.base.tamedAnimalCompanions[id])
        let actor = Combatant.companion(.animal(id.rawValue))
        let receipt = EncounterState.AnimalCombatParticipantReceiptV1(
            animalID: id, memberID: .animal(id.rawValue),
            frozenDisplayName: companion.originReceipt.frozenDisplayName,
            level: companion.level, scaledStats: AnimalCompanionCombatRules.scaledStats(companion),
            reach: companion.originReceipt.reach,
            availableActionIDs: [AnimalCompanionCombatRules.instinctiveActionID,
                                 companion.originReceipt.dominantTechnique.rawValue],
            dominantTechnique: companion.originReceipt.dominantTechnique,
            gambits: companion.gambits,
            gambitSlotCount: GambitEngine.availableSlots(for: actor, in: state),
            commitStrengthMultiplier: Tuning.AnimalCompanionCombat.commitStrengthMultiplier,
            originReceipt: companion.originReceipt)
        XCTAssertTrue(receipt.validates(companion: companion))
        XCTAssertEqual(receipt.gambitSlotCount,
                       Tuning.Encounter.startingGambitSlots + state.base.purchasedGambitSlots
                           + state.reality.bonusGambitSlots)
        XCTAssertEqual(CombatRules.maximumHealth(of: actor, in: state), receipt.scaledStats.maxHP)
        XCTAssertEqual(CombatRules.companionAttack(.animal(id.rawValue), in: state),
                       receipt.scaledStats.attack)
    }

    func testCommitQuoteIsExactOwnerAtomicAndCreatesOneRecoveryDebt() throws {
        var (state, id) = try animalState(posting: .activeParty)
        let actor = Combatant.companion(.animal(id.rawValue))
        let companion = try XCTUnwrap(state.base.tamedAnimalCompanions[id])
        let participant = EncounterState.AnimalCombatParticipantReceiptV1(
            animalID: id, memberID: .animal(id.rawValue),
            frozenDisplayName: companion.originReceipt.frozenDisplayName,
            level: companion.level, scaledStats: AnimalCompanionCombatRules.scaledStats(companion),
            reach: companion.originReceipt.reach,
            availableActionIDs: [AnimalCompanionCombatRules.instinctiveActionID,
                                 AnimalDominantTechniqueV1.commit.rawValue],
            dominantTechnique: .commit, gambits: [], gambitSlotCount: 1,
            commitStrengthMultiplier: Tuning.AnimalCompanionCombat.commitStrengthMultiplier,
            originReceipt: companion.originReceipt)
        // The frozen origin must agree with the saved nil-defence specimen, whose technique is Commit.
        XCTAssertTrue(participant.validates(companion: companion))
        let point = GridPoint(x: 0, y: 0)
        var map = WorldMap(width: 1, height: 1, tiles: [Tile(isRevealed: true)], entry: point)
        map[point].content = .portal(isEntry: true)
        var run = WorldRun(runIndex: 1, book: BoundBook(written: [], essencePaid: 0),
                           mapSeed: 1, rng: SeededRNG(seed: 1), map: map,
                           playerPosition: point)
        let foeID = InstanceID(rawValue: 991)
        let foe = FoeState(id: foeID,
                           stats: CombatStats(displayName: "Target", icon: "ant",
                                              maxHP: 50, attack: 1), currentHP: 50)
        var encounter = EncounterState(id: InstanceID(rawValue: 992), foes: [foe],
                                       partyNames: [.animal(id.rawValue): "Test animal"],
                                       order: [actor, .foe(foeID)],
                                       turnSlots: [.init(actor: actor), .init(actor: .foe(foeID))],
                                       animalParticipants: [actor: participant],
                                       partyRanks: [actor: .front])
        encounter.revealed.insert(foeID)
        run.companionHP[.animal(id.rawValue)] = participant.scaledStats.maxHP
        run.activeEncounter = encounter
        state.worlds.activeRun = run

        let quote = try AnimalCompanionCombatRules.evaluate(
            .commit(foe: foeID), owner: actor, in: state).get()
        var staleState = state
        staleState.worlds.activeRun?.activeEncounter?.roundNumber += 1
        let staleBytes = try SaveCodec.makeEncoder().encode(staleState)
        XCTAssertEqual(AnimalCompanionCombatRules.commit(quote, in: &staleState),
                       .refused(.staleQuote))
        XCTAssertEqual(try SaveCodec.makeEncoder().encode(staleState), staleBytes)

        XCTAssertEqual(AnimalCompanionCombatRules.commit(quote, in: &state), .committed)
        XCTAssertEqual(state.worlds.activeRun?.activeEncounter?.skippedTurns[actor], 1)
        XCTAssertEqual(state.worlds.activeRun?.activeEncounter?
            .animalParticipants?[actor]?.scaledStats, participant.scaledStats)
    }
}
