import XCTest
@testable import Bookbinder

final class SaveSlotTests: XCTestCase {
    @MainActor
    private func authoredStarterPromisedGearState() throws -> GameState {
        let store = GameStore(io: .temporary(name: "slot-starter-gear-\(UUID().uuidString)"))
        store.mutate("test: fund authored starter") { $0.base.essence = 1_000 }
        XCTAssertTrue(store.bindAndDepart(
            worldPageInstanceID: WorldPageCatalog.starterInstances[0].id))
        return store.state
    }

    private func mutatingFirstGameplayFacts(
        in data: Data, _ mutation: (inout [String: Any]) -> Void
    ) throws -> Data {
        let root = try XCTUnwrap(JSONSerialization.jsonObject(with: data))
        func mutate(_ value: Any) -> (Any, Bool) {
            if var array = value as? [Any] {
                for index in array.indices {
                    let result = mutate(array[index]); array[index] = result.0
                    if result.1 { return (array, true) }
                }
                return (array, false)
            }
            guard var object = value as? [String: Any] else { return (value, false) }
            if var profile = object["gearProfile"] as? [String: Any],
               var facts = profile["gameplayFacts"] as? [String: Any] {
                mutation(&facts); profile["gameplayFacts"] = facts
                object["gearProfile"] = profile
                return (object, true)
            }
            for key in object.keys.sorted() {
                let result = mutate(object[key] as Any); object[key] = result.0
                if result.1 { return (object, true) }
            }
            return (object, false)
        }
        let result = mutate(root)
        XCTAssertTrue(result.1)
        return try JSONSerialization.data(withJSONObject: result.0, options: [.sortedKeys])
    }

    @MainActor
    func testAuthoredStarterPromisedGearRealSlotRoundTripAndMalformedFactsPreserveEnvelope()
        async throws {
        let root = directory()
        defer { try? FileManager.default.removeItem(at: root) }
        let slots = SaveSlotFileIO(directory: root)
        let state = try authoredStarterPromisedGearState()
        let created = try await slots.create(name: "Starter promised gear", state: state)
        let url = try await slots.exportURL(for: created.metadata.id)
        let validBytes = try Data(contentsOf: url)
        let validEnvelope = try SaveCodec.makeDecoder().decode(
            SaveSlotEnvelope.self, from: validBytes)
        let canonicalState = try SaveCodec.decode(validEnvelope.payload)
        let loaded = try await slots.load(created.metadata.id).state
        XCTAssertEqual(loaded, canonicalState)
        XCTAssertEqual(try Data(contentsOf: url), validBytes)

        let mutations: [(String, (inout [String: Any]) -> Void)] = [
            ("omitted required", { $0.removeValue(forKey: "sourceRevisionDigest") }),
            ("wrong optional type", { $0["damageKind"] = 44 }),
            ("malformed optional payload", { $0["specialRule"] = ["rule": "unknown"] }),
            ("contradictory facts", { $0["constructionTier"] = 999 }),
            ("partial contribution tuple", { $0["heatWard"] = 10 })
        ]
        for (name, mutation) in mutations {
            var envelope = validEnvelope
            envelope.payload = try mutatingFirstGameplayFacts(
                in: validEnvelope.payload, mutation)
            let bytes = try encoder().encode(envelope)
            try bytes.write(to: url, options: .atomic)
            do { _ = try await slots.load(created.metadata.id); XCTFail("accepted \(name)") }
            catch { }
            XCTAssertEqual(try Data(contentsOf: url), bytes, name)
        }
    }

    private func schemaNineteenEarthSlotState() -> GameState {
        var state = GameState.newGame()
        state.schemaVersion = 19
        state.base.collectedWorldPages.append(LegacyDebugVisibilityWorldV19.instance)
        return state
    }

    func testSchemaNineteenEarthSlotMigratesReadOnlyAndMalformedCopiesPreserveEnvelope() async throws {
        let root = directory()
        defer { try? FileManager.default.removeItem(at: root) }
        let slots = SaveSlotFileIO(directory: root)
        let created = try await slots.create(name: "Legacy DEBUG Earth")
        let url = try await slots.exportURL(for: created.metadata.id)
        var envelope = try SaveCodec.makeDecoder().decode(
            SaveSlotEnvelope.self, from: Data(contentsOf: url))
        envelope.payload = try SaveCodec.encode(schemaNineteenEarthSlotState())
        let validEnvelope = try SaveCodec.makeEncoder().encode(envelope)
        try validEnvelope.write(to: url, options: .atomic)

        let loaded = try await slots.load(created.metadata.id).state
        XCTAssertEqual(loaded.schemaVersion, 20)
        XCTAssertEqual(loaded.base.collectedWorldPages, WorldPageCatalog.starterInstances)
        XCTAssertEqual(try Data(contentsOf: url), validEnvelope)

        let mutations: [(String, (inout [[String: Any]]) -> Void)] = [
            ("duplicate", { $0.append($0.last!) }),
            ("alias instance", { $0[$0.count - 1]["id"] = 91_919 }),
            ("reserved ID alias definition", {
                var definition = $0[$0.count - 1]["definition"] as! [String: Any]
                definition["id"] = "starter_open_meadow"
                $0[$0.count - 1]["definition"] = definition
            }),
            ("tampered definition", {
                var definition = $0[$0.count - 1]["definition"] as! [String: Any]
                definition["promise"] = "tampered"
                $0[$0.count - 1]["definition"] = definition
            })
        ]
        for (name, mutation) in mutations {
            var malformed = envelope
            var payload = try XCTUnwrap(JSONSerialization.jsonObject(
                with: envelope.payload) as? [String: Any])
            var base = try XCTUnwrap(payload["base"] as? [String: Any])
            var pages = try XCTUnwrap(base["collectedWorldPages"] as? [[String: Any]])
            mutation(&pages)
            base["collectedWorldPages"] = pages; payload["base"] = base
            malformed.payload = try JSONSerialization.data(
                withJSONObject: payload, options: [.sortedKeys])
            let malformedEnvelope = try SaveCodec.makeEncoder().encode(malformed)
            try malformedEnvelope.write(to: url, options: .atomic)
            do { _ = try await slots.load(created.metadata.id); XCTFail("accepted \(name)") }
            catch { }
            XCTAssertEqual(try Data(contentsOf: url), malformedEnvelope, name)
        }
    }

    private func firstReturnTutorialSlotState() -> GameState {
        var state = GameState.newGame()
        state.reality.library.foundWritings = [
            FoundWritingRecord(id: "slot-selected", family: .fieldNote, prose: "Words.",
                               position: GridPoint(x: 0, y: 0))
        ]
        state.tutorial.firstReturnContext = .init(
            runIndex: 1, route: .library, reason: .fieldNote, writingID: "slot-selected")
        return state
    }

    private func currentRosterPlacementState() -> GameState {
        var state = GameState.newGame()
        var keeper = CompanionState()
        keeper.name = "Halloway"
        keeper.traveller = "halloway"
        keeper.persistentID = .traveller("halloway")
        state.base.roster.append(keeper)
        let book = BoundBook(written: [], essencePaid: 0)
        let generated = Worldgen.generate(book: book, seed: 92)
        let run = WorldRun(runIndex: 92, book: book, mapSeed: 92,
                           rng: SeededRNG(seed: 92), map: generated.map,
                           playerPosition: generated.start)
        state.worlds.anchoredRealms = [
            AnchoredRealm(runIndex: 92, name: "Slot roster validation", route: .bornAnchored,
                          assignedCompanions: [.traveller("halloway")], world: run)
        ]
        GameStore.recalculateAnchorProduction(in: &state)
        return state
    }

    private func activeAnimalState() throws -> GameState {
        var state = currentRosterPlacementState()
        var generatedMember = CompanionState()
        generatedMember.name = "Generated person"
        generatedMember.persistentID = .generated("slot-positive")
        state.base.roster.append(generatedMember)
        let enemyID = InstanceID(rawValue: 92_501)
        let seed: UInt64 = 92_001
        let condition = RealityState.AnimalTrustConditionV1.usefulOffering(
            property: .hardness, threshold: 0)
        let trust = RealityState.AnimalTrustRecordV1(
            worldSeed: seed, enemyID: enemyID, speciesID: .init(rawValue: 77), creatureID: nil,
            traits: CreatureTraits(), condition: condition, progress: 1,
            firstAttendedRunIndex: 1, firstAttendedTurn: 2, lastProgressTurn: nil,
            interactionCount: 1, completed: true)
        let rawID = "tamed:\(seed):\(enemyID.rawValue)"
        let animal = RealityState.TamedAnimalV1(
            id: rawID, originWorldSeed: seed, originEnemyID: enemyID,
            speciesID: .init(rawValue: 77), creatureID: nil, traits: trust.traits,
            trustCondition: condition, joinedRunIndex: 1, joinedTurn: 4)
        let id = TamedAnimalID(rawValue: rawID)
        let receipt = try XCTUnwrap(AnimalCompanionCombatRules.originReceipt(
            animal: animal, displayName: "Stable slot animal", icon: "questionmark",
            level: 1, provenance: .legacySchema14LevelOne))
        state.reality.animalTrustRecords[trust.key] = trust
        state.reality.tamedAnimals[rawID] = animal
        state.base.tamedAnimalCompanions[id] = .init(
            id: id, originReceipt: receipt, level: 1, experience: 0,
            gambits: [], posting: .activeParty)
        state.base.activeParty.append(.animal(rawID))
        return state
    }

    func testCurrentRosterPlacementCorruptionPreservesRealSlotEnvelopeBytes() async throws {
        let rootDirectory = directory()
        defer { try? FileManager.default.removeItem(at: rootDirectory) }
        let slots = SaveSlotFileIO(directory: rootDirectory)
        let created = try await slots.create(name: "Invalid roster matrix")
        let url = try await slots.exportURL(for: created.metadata.id)
        let validEnvelope = try SaveCodec.makeDecoder().decode(
            SaveSlotEnvelope.self, from: Data(contentsOf: url))
        let validPayload = try SaveCodec.encode(currentRosterPlacementState())
        let mutations: [(String, (inout [String: Any]) throws -> Void)] = [
            ("duplicate persistent ID", { root in
                var base = try XCTUnwrap(root["base"] as? [String: Any])
                var roster = try XCTUnwrap(base["roster"] as? [[String: Any]])
                roster[1]["persistentID"] = "founder:quill"
                base["roster"] = roster; root["base"] = base
            }),
            ("party and realm double placement", { root in
                var base = try XCTUnwrap(root["base"] as? [String: Any])
                base["activeParty"] = ["founder:quill", "traveller:halloway"]
                root["base"] = base
            }),
            ("dangling realm placement", { root in
                var worlds = try XCTUnwrap(root["worlds"] as? [String: Any])
                var realms = try XCTUnwrap(worlds["anchoredRealms"] as? [[String: Any]])
                realms[0]["assignedCompanions"] = ["generated:missing"]
                worlds["anchoredRealms"] = realms; root["worlds"] = worlds
            }),
            ("dormant realm placement", { root in
                var worlds = try XCTUnwrap(root["worlds"] as? [String: Any])
                var realms = try XCTUnwrap(worlds["anchoredRealms"] as? [[String: Any]])
                realms[0]["isDormant"] = true
                worlds["anchoredRealms"] = realms; root["worlds"] = worlds
            }),
            ("keeper identity mismatch", { root in
                var base = try XCTUnwrap(root["base"] as? [String: Any])
                var roster = try XCTUnwrap(base["roster"] as? [[String: Any]])
                roster[1]["persistentID"] = "generated:not-halloway"
                base["roster"] = roster; root["base"] = base
                var worlds = try XCTUnwrap(root["worlds"] as? [String: Any])
                var realms = try XCTUnwrap(worlds["anchoredRealms"] as? [[String: Any]])
                realms[0]["assignedCompanions"] = ["generated:not-halloway"]
                worlds["anchoredRealms"] = realms; root["worlds"] = worlds
            }),
            ("authored traveller missing canonical traveller", { root in
                var base = try XCTUnwrap(root["base"] as? [String: Any])
                var roster = try XCTUnwrap(base["roster"] as? [[String: Any]])
                roster[1].removeValue(forKey: "traveller")
                base["roster"] = roster; root["base"] = base
            }),
            ("animal identity in human roster", { root in
                var base = try XCTUnwrap(root["base"] as? [String: Any])
                var roster = try XCTUnwrap(base["roster"] as? [[String: Any]])
                roster[1]["persistentID"] = "animal:forged-human-owner"
                roster[1].removeValue(forKey: "traveller")
                base["roster"] = roster; root["base"] = base
                var worlds = try XCTUnwrap(root["worlds"] as? [String: Any])
                var realms = try XCTUnwrap(worlds["anchoredRealms"] as? [[String: Any]])
                realms[0]["assignedCompanions"] = ["animal:forged-human-owner"]
                worlds["anchoredRealms"] = realms; root["worlds"] = worlds
            })
        ]
        for (name, mutation) in mutations {
            var envelope = validEnvelope
            var payload = try XCTUnwrap(JSONSerialization.jsonObject(
                with: validPayload) as? [String: Any])
            try mutation(&payload)
            envelope.payload = try JSONSerialization.data(
                withJSONObject: payload, options: [.sortedKeys])
            let bytes = try encoder().encode(envelope)
            try bytes.write(to: url, options: .atomic)
            do { _ = try await slots.load(created.metadata.id); XCTFail("accepted \(name)") }
            catch { }
            XCTAssertEqual(try Data(contentsOf: url), bytes, name)
        }
    }

    func testCurrentActiveTamedAnimalStableIdentityRealSlotRoundTrip() async throws {
        let root = directory()
        defer { try? FileManager.default.removeItem(at: root) }
        let slots = SaveSlotFileIO(directory: root)
        let state = try activeAnimalState()
        let created = try await slots.create(name: "Active stable animal", state: state)
        let url = try await slots.exportURL(for: created.metadata.id)
        let bytes = try Data(contentsOf: url)
        let loaded = try await slots.load(created.metadata.id).state
        XCTAssertEqual(loaded, state)
        XCTAssertEqual(loaded.base.activeParty.last, state.base.activeParty.last)
        XCTAssertTrue(loaded.validatesAnimalCompanionCombat())
        XCTAssertEqual(try Data(contentsOf: url), bytes)
    }

    @MainActor func testFirstReturnTutorialRefusalPreservesRealSlotEnvelopeAndCommitRelaunches() async throws {
        let root = directory()
        defer { try? FileManager.default.removeItem(at: root) }
        let slots = SaveSlotFileIO(directory: root)
        let created = try await slots.create(
            name: "First return fact", state: firstReturnTutorialSlotState())
        _ = try await slots.acquireWriterLease(for: created.metadata.id)
        let payloadIO = try await slots.payloadIOForLeasedSlot()
        let store = GameStore(io: payloadIO)
        let url = try await slots.exportURL(for: created.metadata.id)
        let envelopeBefore = try Data(contentsOf: url)
        let stateBefore = store.state
        let diagnosticsBefore = store.diagnostics

        XCTAssertEqual(store.openedFirstReturnDestination(.storehouse),
                       .refused(.wrongDestination(expected: .library, actual: .storehouse)))
        XCTAssertEqual(store.state, stateBefore)
        XCTAssertEqual(try SaveCodec.encode(store.state), try SaveCodec.encode(stateBefore))
        XCTAssertEqual(store.state.meta.mutationCount, stateBefore.meta.mutationCount)
        XCTAssertEqual(store.state.meta.semanticActionTrail, stateBefore.meta.semanticActionTrail)
        XCTAssertEqual(store.state.meta.lastSavedAt, stateBefore.meta.lastSavedAt)
        XCTAssertEqual(store.diagnostics.writeCount, diagnosticsBefore.writeCount)
        XCTAssertEqual(store.diagnostics.savedMutationCount, diagnosticsBefore.savedMutationCount)
        XCTAssertEqual(store.diagnostics.lastError, diagnosticsBefore.lastError)
        XCTAssertFalse(store.diagnostics.hasPendingWrite)
        XCTAssertEqual(try Data(contentsOf: url), envelopeBefore)

        XCTAssertEqual(store.openedFirstReturnDestination(.library), .committed)
        let context = try XCTUnwrap(store.state.tutorial.firstReturnContext)
        XCTAssertEqual(store.displayedFirstReturnWriting(context), .committed)
        store.flushNow()
        let committed = store.state
        let envelopeAfterCommit = try Data(contentsOf: url)
        let loaded = try await slots.load(created.metadata.id).state
        XCTAssertEqual(loaded.tutorial, committed.tutorial)
        XCTAssertEqual(loaded.meta.mutationCount, committed.meta.mutationCount)
        XCTAssertEqual(loaded.meta.semanticActionTrail, committed.meta.semanticActionTrail)

        XCTAssertEqual(store.openedFirstReturnDestination(.library), .alreadyCompleted)
        XCTAssertEqual(store.displayedFirstReturnWriting(context), .alreadyCompleted)
        XCTAssertEqual(store.state, committed)
        XCTAssertFalse(store.diagnostics.hasPendingWrite)
        XCTAssertEqual(try Data(contentsOf: url), envelopeAfterCommit)
    }

    func testForgedGameplayContributionFailsWithoutRewritingRealSlotEnvelope() async throws {
        let root = directory()
        defer { try? FileManager.default.removeItem(at: root) }
        let io = SaveSlotFileIO(directory: root)
        let created = try await io.create(name: "Forged contribution")
        let url = try await io.exportURL(for: created.metadata.id)
        var envelope = try SaveCodec.makeDecoder().decode(
            SaveSlotEnvelope.self, from: Data(contentsOf: url))
        var state = created.state
        state.base.inventory.add(ItemStack(id: .init(rawValue: 81_091), catalogID: "guard_padded"))
        var payload = try XCTUnwrap(JSONSerialization.jsonObject(
            with: SaveCodec.encode(state)) as? [String: Any])
        var base = payload["base"] as! [String: Any]
        var inventory = base["inventory"] as! [String: Any]
        var stacks = inventory["stacks"] as! [[String: Any]]
        var profile = stacks.last!["gearProfile"] as! [String: Any]
        var facts = profile["gameplayFacts"] as! [String: Any]
        facts["initiativeModifier"] = 999
        facts["heatWard"] = 0
        facts["valueModifier"] = 0.0
        facts["appliedContributionIDs"] = []
        profile["gameplayFacts"] = facts
        stacks[stacks.count - 1]["gearProfile"] = profile
        inventory["stacks"] = stacks
        base["inventory"] = inventory
        payload["base"] = base
        envelope.payload = try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
        let forgedEnvelope = try SaveCodec.makeEncoder().encode(envelope)
        try forgedEnvelope.write(to: url, options: .atomic)

        do {
            _ = try await io.load(created.metadata.id)
            XCTFail("forged contribution must fail closed")
        } catch {}
        XCTAssertEqual(try Data(contentsOf: url), forgedEnvelope)
    }

    func testSchemaEighteenPhysicalCustodyRealSlotMigratesWithoutRewritingEnvelope() async throws {
        let root = directory()
        defer { try? FileManager.default.removeItem(at: root) }
        let slots = SaveSlotFileIO(directory: root)
        let created = try await slots.create(name: "Legacy physical custody")
        let url = try await slots.exportURL(for: created.metadata.id)
        var envelope = try SaveCodec.makeDecoder().decode(
            SaveSlotEnvelope.self, from: Data(contentsOf: url))
        var state = GameState.newGame()
        let gear = ItemStack(id: InstanceID(rawValue: 19_181), catalogID: "blade_keen")
        let line = RunExitSummary.ReceiptLine.uniqueItem(.init(
            lineID: "legacy-lost-gear", instanceID: gear.id, snapshot: gear, quantity: 1,
            fallbackName: gear.displayName, fallbackIcon: gear.icon,
            recoveredDestination: nil))
        XCTAssertTrue(state.worlds.appendExpeditionReview(.init(
            runIndex: 8, outcomeID: 1, kind: .collapse, reason: "lost",
            turnsTaken: 12, haulKeptFraction: 0.5, recoveredLines: [], lostLines: [line])))
        var payload = try XCTUnwrap(JSONSerialization.jsonObject(
            with: SaveCodec.encode(state)) as? [String: Any])
        payload["schemaVersion"] = 18
        func strip(_ value: Any) -> Any {
            if var object = value as? [String: Any] {
                object.removeValue(forKey: "custodyReceiptVersion")
                for (key, child) in object { object[key] = strip(child) }
                return object
            }
            if let array = value as? [Any] { return array.map(strip) }
            return value
        }
        payload = strip(payload) as! [String: Any]
        envelope.payload = try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
        let originalBytes = try encoder().encode(envelope)
        try originalBytes.write(to: url, options: .atomic)

        let loaded = try await slots.load(created.metadata.id).state
        XCTAssertEqual(loaded.schemaVersion, Tuning.saveSchemaVersion)
        XCTAssertEqual(loaded.worlds.pendingExpeditionReview?.summary.custodyReceiptVersion, 0)
        guard case .uniqueItem(let migrated) = loaded.worlds.pendingExpeditionReview?
            .summary.lostLines.first else { return XCTFail("legacy lost gear missing") }
        XCTAssertEqual(migrated.snapshot, gear)
        XCTAssertNil(migrated.recoveredDestination)
        XCTAssertEqual(try Data(contentsOf: url), originalBytes,
                       "read-only slot migration must preserve the envelope bytes")
    }

    func testCurioKnowledgeSchemaTwelveRealSlotMigratesEmpty() async throws {
        let root = directory()
        defer { try? FileManager.default.removeItem(at: root) }
        let slots = SaveSlotFileIO(directory: root)
        let created = try await slots.create(name: "Schema twelve curio migration")
        let url = try await slots.exportURL(for: created.metadata.id)
        var envelope = try SaveCodec.makeDecoder().decode(
            SaveSlotEnvelope.self, from: Data(contentsOf: url))
        var payload = try XCTUnwrap(JSONSerialization.jsonObject(
            with: SaveCodec.encode(.newGame())) as? [String: Any])
        payload["schemaVersion"] = 12
        var reality = try XCTUnwrap(payload["reality"] as? [String: Any])
        reality.removeValue(forKey: "curioFamilyKnowledge")
        reality.removeValue(forKey: "animalTrustRecords")
        reality.removeValue(forKey: "tamedAnimals")
        payload["reality"] = reality
        envelope.payload = try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
        try encoder().encode(envelope).write(to: url, options: .atomic)

        let loaded = try await slots.load(created.metadata.id)
        XCTAssertEqual(loaded.state.schemaVersion, Tuning.saveSchemaVersion)
        XCTAssertTrue(loaded.state.reality.curioFamilyKnowledge.isEmpty)
        XCTAssertTrue(loaded.state.reality.animalTrustRecords.isEmpty)
        XCTAssertTrue(loaded.state.reality.tamedAnimals.isEmpty)
    }

    func testCurrentCurioKnowledgeMalformedRealSlotPreservesExactEnvelope() async throws {
        for mutation in ["null", "negative"] {
            let root = directory()
            defer { try? FileManager.default.removeItem(at: root) }
            let slots = SaveSlotFileIO(directory: root)
            let created = try await slots.create(name: "Malformed curio knowledge")
            let url = try await slots.exportURL(for: created.metadata.id)
            var envelope = try SaveCodec.makeDecoder().decode(
                SaveSlotEnvelope.self, from: Data(contentsOf: url))
            var state = GameState.newGame()
            state.reality.curioFamilyKnowledge["curio_humming_shard"] = .init(
                familyID: "curio_humming_shard", revealedItemID: "salve_lesser",
                observationCount: 1, firstResolutionRunIndex: 0, isRecognized: false)
            var payload = try XCTUnwrap(JSONSerialization.jsonObject(with: SaveCodec.encode(state))
                                         as? [String: Any])
            var reality = try XCTUnwrap(payload["reality"] as? [String: Any])
            if mutation == "null" {
                reality["curioFamilyKnowledge"] = NSNull()
            } else {
                var knowledge = try XCTUnwrap(reality["curioFamilyKnowledge"] as? [String: Any])
                var receipt = try XCTUnwrap(knowledge["curio_humming_shard"] as? [String: Any])
                receipt["observationCount"] = -1
                knowledge["curio_humming_shard"] = receipt
                reality["curioFamilyKnowledge"] = knowledge
            }
            payload["reality"] = reality
            envelope.payload = try JSONSerialization.data(withJSONObject: payload,
                                                            options: [.sortedKeys])
            let bytes = try encoder().encode(envelope)
            try bytes.write(to: url, options: .atomic)
            do { _ = try await slots.load(created.metadata.id); XCTFail("expected strict failure") }
            catch { }
            XCTAssertEqual(try Data(contentsOf: url), bytes)
        }
    }

    func testCurrentAnimalTrustMalformedRealSlotPreservesExactEnvelope() async throws {
        for mutation in ["null", "negative"] {
            let root = directory()
            defer { try? FileManager.default.removeItem(at: root) }
            let slots = SaveSlotFileIO(directory: root)
            let created = try await slots.create(name: "Malformed animal trust")
            let url = try await slots.exportURL(for: created.metadata.id)
            var envelope = try SaveCodec.makeDecoder().decode(
                SaveSlotEnvelope.self, from: Data(contentsOf: url))
            var state = GameState.newGame()
            let record = RealityState.AnimalTrustRecordV1(
                worldSeed: 14, enemyID: .init(rawValue: 7), speciesID: nil,
                creatureID: nil, traits: CreatureTraits(),
                condition: .patientPresence(requiredTurns: 2), progress: 0,
                firstAttendedRunIndex: 1, firstAttendedTurn: 0,
                lastProgressTurn: nil, interactionCount: 1, completed: false)
            state.reality.animalTrustRecords[record.key] = record
            var payload = try XCTUnwrap(JSONSerialization.jsonObject(with: SaveCodec.encode(state))
                                         as? [String: Any])
            var reality = try XCTUnwrap(payload["reality"] as? [String: Any])
            if mutation == "null" {
                reality["animalTrustRecords"] = NSNull()
            } else {
                var records = try XCTUnwrap(reality["animalTrustRecords"] as? [String: Any])
                var receipt = try XCTUnwrap(records[record.key] as? [String: Any])
                receipt["progress"] = -1
                records[record.key] = receipt
                reality["animalTrustRecords"] = records
            }
            payload["reality"] = reality
            envelope.payload = try JSONSerialization.data(withJSONObject: payload,
                                                            options: [.sortedKeys])
            let bytes = try encoder().encode(envelope)
            try bytes.write(to: url, options: .atomic)
            do { _ = try await slots.load(created.metadata.id); XCTFail("expected strict failure") }
            catch { }
            XCTAssertEqual(try Data(contentsOf: url), bytes)
        }
    }

    func testB111ASchemaTenMalformedQueueMigrationPreservesRealSlotEnvelope() async throws {
        let root = directory()
        defer { try? FileManager.default.removeItem(at: root) }
        let slots = SaveSlotFileIO(directory: root)
        let created = try await slots.create(name: "Malformed expedition review")
        let url = try await slots.exportURL(for: created.metadata.id)
        var envelope = try SaveCodec.makeDecoder().decode(
            SaveSlotEnvelope.self, from: Data(contentsOf: url))
        var payload = try XCTUnwrap(JSONSerialization.jsonObject(
            with: SaveCodec.encode(GameState.newGame())) as? [String: Any])
        payload["schemaVersion"] = 10
        var worlds = try XCTUnwrap(payload["worlds"] as? [String: Any])
        worlds.removeValue(forKey: "expeditionReviewQueue")
        for malformed: Any in [NSNull(), -1, 1.5, true, "1"] {
            worlds["outcomeSequence"] = malformed
            payload["worlds"] = worlds
            envelope.payload = try JSONSerialization.data(
                withJSONObject: payload, options: [.sortedKeys])
            let original = try encoder().encode(envelope)
            try original.write(to: url, options: .atomic)
            do {
                _ = try await slots.load(created.metadata.id)
                XCTFail("present malformed sequence must fail: \(malformed)")
            } catch { }
            XCTAssertEqual(try Data(contentsOf: url), original)
        }
    }

    func testB111ACurrentQueueCrossFieldFailurePreservesRealSlotEnvelope() async throws {
        let root = directory()
        defer { try? FileManager.default.removeItem(at: root) }
        let slots = SaveSlotFileIO(directory: root)
        let created = try await slots.create(name: "Mismatched expedition review")
        let url = try await slots.exportURL(for: created.metadata.id)
        var envelope = try SaveCodec.makeDecoder().decode(
            SaveSlotEnvelope.self, from: Data(contentsOf: url))
        var state = GameState.newGame()
        state.worlds.outcomeSequence = 1
        XCTAssertTrue(state.worlds.appendExpeditionReview(.init(
            runIndex: 1, outcomeID: 1, kind: .portal, reason: "frozen",
            turnsTaken: 3, haulKeptFraction: 1)))
        var payload = try XCTUnwrap(JSONSerialization.jsonObject(
            with: SaveCodec.encode(state)) as? [String: Any])
        var worlds = try XCTUnwrap(payload["worlds"] as? [String: Any])
        var queue = try XCTUnwrap(worlds["expeditionReviewQueue"] as? [String: Any])
        var pending = try XCTUnwrap(queue["pending"] as? [[String: Any]])
        var first = pending[0]
        first["reviewID"] = ["kind": "outcome", "outcomeID": 2]
        pending[0] = first
        queue["pending"] = pending
        worlds["expeditionReviewQueue"] = queue
        payload["worlds"] = worlds
        envelope.payload = try JSONSerialization.data(
            withJSONObject: payload, options: [.sortedKeys])
        let original = try encoder().encode(envelope)
        try original.write(to: url, options: .atomic)
        do { _ = try await slots.load(created.metadata.id); XCTFail("expected mismatch failure") }
        catch { }
        XCTAssertEqual(try Data(contentsOf: url), original)
    }

    func testCurrentRecoveredTeachingNullFailsSlotLoadWithoutRewritingEnvelope() async throws {
        let root = directory()
        defer { try? FileManager.default.removeItem(at: root) }
        let slots = SaveSlotFileIO(directory: root)
        let created = try await slots.create(name: "Malformed recovered teaching")
        let url = try await slots.exportURL(for: created.metadata.id)
        var envelope = try SaveCodec.makeDecoder().decode(
            SaveSlotEnvelope.self, from: Data(contentsOf: url))
        var payload = try XCTUnwrap(JSONSerialization.jsonObject(
            with: SaveCodec.encode(.newGame())) as? [String: Any])
        var reality = try XCTUnwrap(payload["reality"] as? [String: Any])
        var library = try XCTUnwrap(reality["library"] as? [String: Any])
        library["recoveredTeachingOffers"] = NSNull()
        reality["library"] = library; payload["reality"] = reality
        envelope.payload = try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
        let bytes = try encoder().encode(envelope)
        try bytes.write(to: url, options: .atomic)
        do { _ = try await slots.load(created.metadata.id); XCTFail("expected strict failure") }
        catch { }
        XCTAssertEqual(try Data(contentsOf: url), bytes)
    }

    func testCurrentRecoveredTeachingCrossFieldMismatchFailsSlotWithoutRewritingEnvelope() async throws {
        let root = directory()
        defer { try? FileManager.default.removeItem(at: root) }
        let slots = SaveSlotFileIO(directory: root)
        let created = try await slots.create(name: "Mismatched teaching receipt")
        let url = try await slots.exportURL(for: created.metadata.id)
        var envelope = try SaveCodec.makeDecoder().decode(
            SaveSlotEnvelope.self, from: Data(contentsOf: url))
        var state = GameState.newGame()
        var run = WorldRun(
            runIndex: 1, book: .init(written: [], essencePaid: 0), mapSeed: 71,
            rng: .init(seed: 71),
            map: .init(width: 1, height: 1, tiles: [Tile()], entry: .init(x: 0, y: 0)),
            playerPosition: .init(x: 0, y: 0))
        run.recoveredTeachingExpedition = .init(
            offeredTeachingID: "teaching.focus.stars", placement: .init(x: 0, y: 0),
            resultingOfferStates: [.init(teachingID: "teaching.focus.stars", isDue: true)],
            resolvedAtOutcomeID: nil)
        state.worlds.activeRun = run
        var payload = try XCTUnwrap(JSONSerialization.jsonObject(with: SaveCodec.encode(state))
                                     as? [String: Any])
        var worlds = try XCTUnwrap(payload["worlds"] as? [String: Any])
        var active = try XCTUnwrap(worlds["activeRun"] as? [String: Any])
        var receipt = try XCTUnwrap(active["recoveredTeachingExpedition"] as? [String: Any])
        var states = try XCTUnwrap(receipt["resultingOfferStates"] as? [[String: Any]])
        states[0]["isDue"] = false
        receipt["resultingOfferStates"] = states
        active["recoveredTeachingExpedition"] = receipt; worlds["activeRun"] = active
        payload["worlds"] = worlds
        envelope.payload = try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
        let bytes = try encoder().encode(envelope)
        try bytes.write(to: url, options: .atomic)
        do { _ = try await slots.load(created.metadata.id); XCTFail("expected strict failure") }
        catch { }
        XCTAssertEqual(try Data(contentsOf: url), bytes)
    }

    func testCurrentRecoveredTeachingInvalidNonSelectedOfferPreservesRealSlotEnvelope() async throws {
        for mutation in ["future-version", "negative-counter"] {
            let root = directory()
            defer { try? FileManager.default.removeItem(at: root) }
            let slots = SaveSlotFileIO(directory: root)
            let created = try await slots.create(name: "Invalid non-selected teaching offer")
            let url = try await slots.exportURL(for: created.metadata.id)
            var envelope = try SaveCodec.makeDecoder().decode(
                SaveSlotEnvelope.self, from: Data(contentsOf: url))
            var state = GameState.newGame()
            var tile = Tile(); tile.content = .recoveredTeaching("teaching.focus.stars")
            var run = WorldRun(
                runIndex: 1, book: .init(written: [], essencePaid: 0), mapSeed: 71,
                rng: .init(seed: 71),
                map: .init(width: 1, height: 1, tiles: [tile], entry: .init(x: 0, y: 0)),
                playerPosition: .init(x: 0, y: 0))
            run.recoveredTeachingExpedition = .init(
                offeredTeachingID: "teaching.focus.stars", placement: .init(x: 0, y: 0),
                resultingOfferStates: [
                    .init(teachingID: "teaching.focus.stars", isDue: true),
                    .init(teachingID: "teaching.focus.mist", eligibleWorldsWithoutOffer: 1)
                ], resolvedAtOutcomeID: nil)
            state.worlds.activeRun = run
            var payload = try XCTUnwrap(JSONSerialization.jsonObject(with: SaveCodec.encode(state))
                                         as? [String: Any])
            var worlds = try XCTUnwrap(payload["worlds"] as? [String: Any])
            var active = try XCTUnwrap(worlds["activeRun"] as? [String: Any])
            var receipt = try XCTUnwrap(active["recoveredTeachingExpedition"] as? [String: Any])
            var states = try XCTUnwrap(receipt["resultingOfferStates"] as? [[String: Any]])
            if mutation == "future-version" { states[1]["version"] = 2 }
            else { states[1]["eligibleWorldsWithoutOffer"] = -1 }
            receipt["resultingOfferStates"] = states
            active["recoveredTeachingExpedition"] = receipt; worlds["activeRun"] = active
            payload["worlds"] = worlds
            envelope.payload = try JSONSerialization.data(withJSONObject: payload,
                                                            options: [.sortedKeys])
            let bytes = try encoder().encode(envelope)
            try bytes.write(to: url, options: .atomic)
            do { _ = try await slots.load(created.metadata.id); XCTFail("expected strict failure") }
            catch { }
            XCTAssertEqual(try Data(contentsOf: url), bytes)
        }
    }

    func testCurrentRecoveredTeachingReceiptMapMismatchPreservesRealSlotEnvelope() async throws {
        let root = directory()
        defer { try? FileManager.default.removeItem(at: root) }
        let slots = SaveSlotFileIO(directory: root)
        let created = try await slots.create(name: "Mismatched teaching map")
        let url = try await slots.exportURL(for: created.metadata.id)
        var envelope = try SaveCodec.makeDecoder().decode(
            SaveSlotEnvelope.self, from: Data(contentsOf: url))
        var state = GameState.newGame()
        var tile = Tile(); tile.content = .recoveredTeaching("teaching.focus.stars")
        var run = WorldRun(
            runIndex: 1, book: .init(written: [], essencePaid: 0), mapSeed: 71,
            rng: .init(seed: 71),
            map: .init(width: 1, height: 1, tiles: [tile], entry: .init(x: 0, y: 0)),
            playerPosition: .init(x: 0, y: 0))
        run.recoveredTeachingExpedition = .init(
            offeredTeachingID: "teaching.focus.stars", placement: .init(x: 0, y: 0),
            resultingOfferStates: [.init(teachingID: "teaching.focus.stars", isDue: true)],
            resolvedAtOutcomeID: nil)
        state.worlds.activeRun = run
        var payload = try XCTUnwrap(JSONSerialization.jsonObject(with: SaveCodec.encode(state))
                                     as? [String: Any])
        var worlds = try XCTUnwrap(payload["worlds"] as? [String: Any])
        var active = try XCTUnwrap(worlds["activeRun"] as? [String: Any])
        var receipt = try XCTUnwrap(active["recoveredTeachingExpedition"] as? [String: Any])
        receipt["placement"] = ["x": 9, "y": 0]
        active["recoveredTeachingExpedition"] = receipt; worlds["activeRun"] = active
        payload["worlds"] = worlds
        envelope.payload = try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
        let bytes = try encoder().encode(envelope)
        try bytes.write(to: url, options: .atomic)
        do { _ = try await slots.load(created.metadata.id); XCTFail("expected map mismatch failure") }
        catch { }
        XCTAssertEqual(try Data(contentsOf: url), bytes)
    }

    func testCurrentSeamwardNullFailsSlotLoadWithoutRewritingEnvelope() async throws {
        let root = directory()
        defer { try? FileManager.default.removeItem(at: root) }
        let slots = SaveSlotFileIO(directory: root)
        let created = try await slots.create(name: "Malformed Seamward")
        let url = try await slots.exportURL(for: created.metadata.id)
        var envelope = try SaveCodec.makeDecoder().decode(
            SaveSlotEnvelope.self, from: Data(contentsOf: url))
        var state = GameState.newGame()
        var run = WorldRun(
            runIndex: 1, book: .init(symbols: [:], randomlyFilled: [], essencePaid: 0),
            mapSeed: 1, rng: .init(seed: 1),
            map: .init(width: 1, height: 1,
                       tiles: [Tile(content: .portal(isEntry: true), ground: .soil)],
                       entry: .init(x: 0, y: 0)), playerPosition: .init(x: 0, y: 0))
        run.seamwardExpedition = .init(contributors: [
            .init(member: .binder, gearStableInstanceID: .init(rawValue: 70), slot: .armor,
                  definitionID: "seamward", rulesVersion: 1, inkRecipe: nil)
        ], activatedOnTurn: 0)
        state.worlds.activeRun = run
        var payload = try XCTUnwrap(JSONSerialization.jsonObject(
            with: SaveCodec.encode(state)) as? [String: Any])
        var worlds = try XCTUnwrap(payload["worlds"] as? [String: Any])
        var active = try XCTUnwrap(worlds["activeRun"] as? [String: Any])
        var receipt = try XCTUnwrap(active["seamwardExpedition"] as? [String: Any])
        receipt["activatedOnTurn"] = NSNull()
        active["seamwardExpedition"] = receipt; worlds["activeRun"] = active
        payload["worlds"] = worlds
        envelope.payload = try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
        let bytes = try encoder().encode(envelope)
        try bytes.write(to: url, options: .atomic)

        do { _ = try await slots.load(created.metadata.id); XCTFail("expected strict failure") }
        catch { }
        XCTAssertEqual(try Data(contentsOf: url), bytes)
    }

    func testChannelworksSchemaEightRealSlotFailurePreservesEnvelope() async throws {
        let root = directory()
        defer { try? FileManager.default.removeItem(at: root) }
        let slots = SaveSlotFileIO(directory: root)
        let created = try await slots.create(name: "Channelworks migration")
        let url = try await slots.exportURL(for: created.metadata.id)
        var envelope = try SaveCodec.makeDecoder().decode(
            SaveSlotEnvelope.self, from: Data(contentsOf: url))
        var state = GameState.newGame()
        state.base.stations[Stations.channelworks] = .init(isUnlocked: true, tier: 0)
        var payload = try XCTUnwrap(JSONSerialization.jsonObject(with: SaveCodec.encode(state))
                                     as? [String: Any])
        payload["schemaVersion"] = 8
        var base = try XCTUnwrap(payload["base"] as? [String: Any])
        base.removeValue(forKey: "channelworksRestoration")
        base["odaFixtureRestored"] = NSNull(); payload["base"] = base
        envelope.payload = try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
        let original = try encoder().encode(envelope)
        try original.write(to: url, options: .atomic)
        do { _ = try await slots.load(created.metadata.id); XCTFail("Expected corrupt legacy receipt") }
        catch { }
        XCTAssertEqual(try Data(contentsOf: url), original)
    }

    func testSchemaFiveTransitionalPendingGeneratedSpeciesMigrationInRealSlotEnvelope() async throws {
        enum Fixture { case missing, matching, mismatched }
        for fixture in [Fixture.missing, .matching, .mismatched] {
            let root = directory()
            defer { try? FileManager.default.removeItem(at: root) }
            let slots = SaveSlotFileIO(directory: root)
            let created = try await slots.create(name: "Pending generated encounter")
            let url = try await slots.exportURL(for: created.metadata.id)
            var envelope = try SaveCodec.makeDecoder().decode(
                SaveSlotEnvelope.self, from: Data(contentsOf: url))
            let speciesID = InstanceID(rawValue: 91)
            let foeID = InstanceID(rawValue: 52)
            let traits = CreatureTraits()
            var state = GameState.newGame()
            var run = WorldRun(runIndex: 1, book: .init(written: [], essencePaid: 0),
                               mapSeed: 1, rng: .init(seed: 1),
                               map: .init(width: 1, height: 1,
                                          tiles: [.init(isRevealed: true)],
                                          entry: .init(x: 0, y: 0)),
                               playerPosition: .init(x: 0, y: 0),
                               sourceDangerReceipt: .init(sourceBand: 1))
            run.cast = [.init(id: speciesID, traits: traits, worldSeed: 1,
                              habitat: .terrestrial, materialProjection: .init(entries: []))]
            run.enemies = [.init(id: foeID, speciesID: speciesID, traits: traits,
                                 position: .init(x: 0, y: 0))]
            var rng = SeededRNG(seed: 2)
            run.activeEncounter = CombatRules.makeEncounter(
                id: .init(rawValue: 3),
                foes: [.init(id: foeID, speciesID: speciesID, traits: traits,
                             stats: .init(displayName: "Generated", icon: "ant", maxHP: 2, attack: 1),
                             currentHP: 2)], party: [.binder], rng: &rng)
            state.worlds.activeRun = run
            var payload = try XCTUnwrap(JSONSerialization.jsonObject(
                with: SaveCodec.makeEncoder().encode(state)) as? [String: Any])
            payload["schemaVersion"] = 5
            var base = try XCTUnwrap(payload["base"] as? [String: Any])
            base.removeValue(forKey: "worldMaterialReserve")
            base.removeValue(forKey: "creatureMaterialReserve")
            base["materialReserve"] = ["units": []]
            payload["base"] = base
            var worlds = try XCTUnwrap(payload["worlds"] as? [String: Any])
            var active = try XCTUnwrap(worlds["activeRun"] as? [String: Any])
            active.removeValue(forKey: "sourceDangerReceipt")
            active.removeValue(forKey: "worldMaterialReserve")
            active.removeValue(forKey: "creatureMaterialReserve")
            active["materialReserve"] = ["units": []]
            var encounter = try XCTUnwrap(active["activeEncounter"] as? [String: Any])
            var foes = try XCTUnwrap(encounter["foes"] as? [[String: Any]])
            switch fixture {
            case .missing: foes[0].removeValue(forKey: "speciesID")
            case .matching: break
            case .mismatched: foes[0]["speciesID"] = ["rawValue": 999]
            }
            encounter["foes"] = foes; active["activeEncounter"] = encounter
            worlds["activeRun"] = active; payload["worlds"] = worlds
            envelope.payload = try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
            let original = try encoder().encode(envelope)
            try original.write(to: url, options: .atomic)

            switch fixture {
            case .missing, .matching:
                let loaded = try await slots.load(created.metadata.id).state
                XCTAssertEqual(loaded.worlds.activeRun?.activeEncounter?.foes.first?.speciesID,
                               speciesID)
            case .mismatched:
                do { _ = try await slots.load(created.metadata.id); XCTFail("Expected mismatch failure") }
                catch { }
                XCTAssertEqual(try Data(contentsOf: url), original)
            }
        }
    }

    func testSchemaSixMissingCreatureRewardAuthorityPreservesRealSlotEnvelope() async throws {
        let root = directory()
        defer { try? FileManager.default.removeItem(at: root) }
        let slots = SaveSlotFileIO(directory: root)
        let created = try await slots.create(name: "Missing reward authority")
        let url = try await slots.exportURL(for: created.metadata.id)
        var envelope = try SaveCodec.makeDecoder().decode(
            SaveSlotEnvelope.self, from: Data(contentsOf: url))
        var state = GameState.newGame()
        let point = GridPoint(x: 0, y: 0)
        var run = WorldRun(runIndex: 1, book: .init(written: [], essencePaid: 0),
                           mapSeed: 1, rng: .init(seed: 1),
                           map: .init(width: 1, height: 1,
                                      tiles: [.init(isRevealed: true)], entry: point),
                           playerPosition: point, sourceDangerReceipt: .init(sourceBand: 1))
        var rng = SeededRNG(seed: 2)
        run.activeEncounter = CombatRules.makeEncounter(
            id: .init(rawValue: 3),
            foes: [.init(id: .init(rawValue: 4), creatureID: "paper_moth",
                         stats: .init(displayName: "Guardian", icon: "ant", maxHP: 2, attack: 1),
                         currentHP: 2)], party: [.binder], rng: &rng)
        state.worlds.activeRun = run
        var payload = try XCTUnwrap(JSONSerialization.jsonObject(
            with: SaveCodec.makeEncoder().encode(state)) as? [String: Any])
        var worlds = try XCTUnwrap(payload["worlds"] as? [String: Any])
        var active = try XCTUnwrap(worlds["activeRun"] as? [String: Any])
        var encounter = try XCTUnwrap(active["activeEncounter"] as? [String: Any])
        encounter.removeValue(forKey: "creatureMaterialRewardResolution")
        active["activeEncounter"] = encounter; worlds["activeRun"] = active; payload["worlds"] = worlds
        envelope.payload = try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
        let original = try encoder().encode(envelope)
        try original.write(to: url, options: .atomic)
        do { _ = try await slots.load(created.metadata.id); XCTFail("Expected current-schema omission") }
        catch { }
        XCTAssertEqual(try Data(contentsOf: url), original)
    }

    func testInspectionReportsExactCompletedAndTotalFileUnits() async throws {
        let directory = directory()
        let io = SaveSlotFileIO(directory: directory)
        _ = try await io.create(name: "One")
        _ = try await io.create(name: "Two")
        final class Recorder: @unchecked Sendable {
            private let lock = NSLock()
            private var values: [(Int, Int)] = []
            func append(_ completed: Int, _ total: Int) {
                lock.lock(); defer { lock.unlock() }
                values.append((completed, total))
            }
            var snapshot: [(Int, Int)] {
                lock.lock(); defer { lock.unlock() }
                return values
            }
        }
        let recorder = Recorder()

        let inspected = await io.inspect(progress: recorder.append)

        XCTAssertEqual(inspected.count, 2)
        XCTAssertEqual(recorder.snapshot.map(\.0), [0, 1, 2])
        XCTAssertEqual(recorder.snapshot.map(\.1), [2, 2, 2])
    }
    private func directory() -> URL {
        FileManager.default.temporaryDirectory
            .appending(path: "bookbinder-slot-tests/\(UUID().uuidString)", directoryHint: .isDirectory)
    }

    private func encoder() -> JSONEncoder {
        let value = JSONEncoder()
        value.dateEncodingStrategy = .iso8601
        return value
    }

    func testSaveSlotSchemaOneScalarOnlyMigrationAllocatesUniqueCrystalIDAndIsIdempotent() async throws {
        let root = directory()
        defer { try? FileManager.default.removeItem(at: root) }
        let slots = SaveSlotFileIO(directory: root)
        let created = try await slots.create(name: "Legacy Essence")
        let url = try await slots.exportURL(for: created.metadata.id)
        var envelope = try SaveCodec.makeDecoder().decode(
            SaveSlotEnvelope.self, from: Data(contentsOf: url))
        envelope.payload = Data(#"""
        {
          "schemaVersion":1,
          "base":{
            "roster":[{"name":"Quill"}],
            "essence":19,
            "inventory":{"slots":8,"stacks":[
              {"id":{"rawValue":1201},"catalogID":"salve_lesser","count":1,"identified":true}
            ]},
            "spillover":[
              {"id":{"rawValue":1302},"catalogID":"field_ration","count":1,"identified":true}
            ]
          }
        }
        """#.utf8)
        try encoder().encode(envelope).write(to: url, options: .atomic)

        let first = try await slots.load(created.metadata.id).state
        let crystalID = try XCTUnwrap(first.base.essenceCrystals?.id)
        XCTAssertGreaterThan(crystalID.rawValue, 1302)
        XCTAssertEqual(first.base.essenceCrystalCount, 19)
        let allIDs = first.base.inventory.stacks.map(\.id)
            + first.base.spillover.map(\.id) + [crystalID]
        XCTAssertEqual(Set(allIDs).count, allIDs.count)

        _ = try await slots.save(created.metadata.id, state: first)
        let relaunched = try await slots.load(created.metadata.id).state
        XCTAssertEqual(relaunched.base.essenceCrystals?.id, crystalID)
        XCTAssertEqual(relaunched, first)
    }

    func testSaveSlotSchemaTwoPartyMigrationIsLosslessAndIdempotent() async throws {
        let root = directory()
        defer { try? FileManager.default.removeItem(at: root) }
        let slots = SaveSlotFileIO(directory: root)
        let created = try await slots.create(name: "Legacy party")
        let url = try await slots.exportURL(for: created.metadata.id)
        var envelope = try SaveCodec.makeDecoder().decode(
            SaveSlotEnvelope.self, from: Data(contentsOf: url))
        envelope.payload = Data(#"""
        {"schemaVersion":2,"base":{"roster":[
          {"name":"Quill"},{"name":"Mara","traveller":"mara"}
        ],"activeParty":[0,1]}}
        """#.utf8)
        let originalEnvelope = try encoder().encode(envelope)
        try originalEnvelope.write(to: url, options: .atomic)

        let migrated = try await slots.load(created.metadata.id).state
        XCTAssertEqual(migrated.base.activeParty, [.founderQuill, .traveller("mara")])
        XCTAssertEqual(migrated.base.roster.map(\.persistentID),
                       [.founderQuill, .traveller("mara")])
        let canonical = try SaveCodec.decode(SaveCodec.encode(migrated))
        XCTAssertEqual(canonical, migrated)
    }

    func testSaveSlotUnknownLegacyPartyActorFailsWithoutRewritingEnvelope() async throws {
        let payloads = [
            #"{"schemaVersion":2,"base":{"roster":[{"name":"Quill"}],"activeParty":[4]}}"#,
            #"{"schemaVersion":2,"base":{"roster":[{"name":"Mara","traveller":"mara"}],"activeParty":[0]}}"#,
            #"{"schemaVersion":2,"base":{"roster":[{"name":"Quill"},{"name":"Unknown","traveller":"missing"}],"activeParty":[1]}}"#,
            #"{"schemaVersion":2,"base":{"roster":[{"name":"Quill"},{"name":"Mara","traveller":"mara"},{"name":"Again","traveller":"mara"}],"activeParty":[1]}}"#,
            #"{"schemaVersion":2,"base":{"roster":[{"name":"Quill"},{"name":"Mara","traveller":"mara"}],"activeParty":[0]},"worlds":{"activeRun":{"activeEncounter":{"actor":{"companion":{"_0":8}}}}}}"#
        ]
        for payload in payloads {
            let root = directory()
            defer { try? FileManager.default.removeItem(at: root) }
            let slots = SaveSlotFileIO(directory: root)
            let created = try await slots.create(name: "Corrupt party")
            let url = try await slots.exportURL(for: created.metadata.id)
            var envelope = try SaveCodec.makeDecoder().decode(
                SaveSlotEnvelope.self, from: Data(contentsOf: url))
            envelope.payload = Data(payload.utf8)
            let bytes = try encoder().encode(envelope)
            try bytes.write(to: url, options: .atomic)

            do { _ = try await slots.load(created.metadata.id); XCTFail("Expected corrupt migration") }
            catch { }
            XCTAssertEqual(try Data(contentsOf: url), bytes)
        }
    }

    func testSaveSlotMalformedPersistentIDsFailWithoutRewritingEnvelope() async throws {
        let malformedValues = [
            "number": "7",
            "object": #"{"rawValue":"traveller:mara"}"#,
            "array": #"["traveller:mara"]"#,
            "boolean": "true",
            "null": "null"
        ]
        for (name, value) in malformedValues {
            let payloads = [
                #"{"schemaVersion":2,"base":{"roster":[{"name":"Quill","persistentID":\#(value)}],"activeParty":[0]}}"#,
                #"{"schemaVersion":2,"base":{"roster":[{"name":"Quill"},{"name":"Mara","traveller":"mara","persistentID":\#(value)}],"activeParty":[1]}}"#
            ]
            for payload in payloads {
                let root = directory()
                defer { try? FileManager.default.removeItem(at: root) }
                let slots = SaveSlotFileIO(directory: root)
                let created = try await slots.create(name: "Malformed persistent ID \(name)")
                let url = try await slots.exportURL(for: created.metadata.id)
                var envelope = try SaveCodec.makeDecoder().decode(
                    SaveSlotEnvelope.self, from: Data(contentsOf: url))
                envelope.payload = Data(payload.utf8)
                let bytes = try encoder().encode(envelope)
                try bytes.write(to: url, options: .atomic)

                do { _ = try await slots.load(created.metadata.id); XCTFail("Expected \(name) rejection") }
                catch { }
                XCTAssertEqual(try Data(contentsOf: url), bytes,
                               "failed \(name) migration must preserve slot bytes")
            }
        }
    }

    func testSaveSlotMigrationRejectsMalformedItemStackIDsWithoutRewritingEnvelope() async throws {
        let malformedValues = [
            "negative": "-1",
            "fractional": "1.5",
            "boolean": "true",
            "overflow": "18446744073709551616",
            "maximum": "18446744073709551615"
        ]

        for (name, rawValue) in malformedValues {
            for existingCrystal in [false, true] {
                let root = directory()
                defer { try? FileManager.default.removeItem(at: root) }
                let slots = SaveSlotFileIO(directory: root)
                let created = try await slots.create(name: "Malformed \(name)")
                let url = try await slots.exportURL(for: created.metadata.id)
                var envelope = try SaveCodec.makeDecoder().decode(
                    SaveSlotEnvelope.self, from: Data(contentsOf: url))
                let stack = existingCrystal
                    ? #""essenceCrystals":{"id":{"rawValue":\#(rawValue)},"catalogID":"essence_crystal","count":2,"identified":true},"#
                    : #""inventory":{"slots":8,"stacks":[{"id":{"rawValue":\#(rawValue)},"catalogID":"salve_lesser","count":1,"identified":true}]},"#
                envelope.payload = Data(#"""
                {"schemaVersion":1,"base":{"roster":[{"name":"Quill"}],"essence":7,\#(stack)"goldCoins":3}}
                """#.utf8)
                let originalEnvelope = try encoder().encode(envelope)
                try originalEnvelope.write(to: url, options: .atomic)

                do {
                    _ = try await slots.load(created.metadata.id)
                    XCTFail("\(existingCrystal ? "existing" : "allocation") path accepted \(name)")
                } catch {
                    XCTAssertEqual(try Data(contentsOf: url), originalEnvelope,
                                   "failed migration must not rewrite the slot")
                }
            }
        }
    }

    func testSchemaSevenGearProfileNumericAndPartialProvenanceFailuresPreserveEnvelopeBytes() async throws {
        let mutations: [(String, (inout [String: Any]) -> Void)] = [
            ("fractional tier", { $0["constructionTier"] = 2.5 }),
            ("null credit", { $0["legacyPowerCredit"] = NSNull() }),
            ("partial provenance", { profile in
                profile["recipeVersion"] = 1
                profile["consumedSamples"] = []
            }),
        ]
        for (label, mutate) in mutations {
            let root = directory()
            defer { try? FileManager.default.removeItem(at: root) }
            let slots = SaveSlotFileIO(directory: root)
            let created = try await slots.create(name: "Schema 7 gear \(label)")
            let url = try await slots.exportURL(for: created.metadata.id)
            var envelope = try SaveCodec.makeDecoder().decode(
                SaveSlotEnvelope.self, from: Data(contentsOf: url))

            var state = GameState.newGame()
            state.base.inventory.add(ItemStack(id: .init(rawValue: 88_001), catalogID: "blade_keen"))
            var payload = try XCTUnwrap(JSONSerialization.jsonObject(
                with: SaveCodec.encode(state)) as? [String: Any])
            payload["schemaVersion"] = 7
            var base = try XCTUnwrap(payload["base"] as? [String: Any])
            var inventory = try XCTUnwrap(base["inventory"] as? [String: Any])
            var stacks = try XCTUnwrap(inventory["stacks"] as? [[String: Any]])
            var profile = try XCTUnwrap(stacks[0]["gearProfile"] as? [String: Any])
            profile["version"] = 1
            profile.removeValue(forKey: "qualityBand")
            profile.removeValue(forKey: "legacyEffectivePowerCredit")
            profile.removeValue(forKey: "foundReceipt")
            mutate(&profile)
            stacks[0]["gearProfile"] = profile
            inventory["stacks"] = stacks
            base["inventory"] = inventory
            payload["base"] = base
            envelope.payload = try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
            let original = try encoder().encode(envelope)
            try original.write(to: url, options: .atomic)

            do { _ = try await slots.load(created.metadata.id); XCTFail("accepted \(label)") }
            catch { }
            XCTAssertEqual(try Data(contentsOf: url), original,
                           "failed schema-7 gear migration rewrote the slot")
        }
    }

    func testLegacyAdoptionIsIdempotentAndPreservesExactPayloadBytes() async throws {
        let root = directory()
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        var legacy = GameState.newGame()
        legacy.base.essence = 321
        let payload = try SaveCodec.encode(legacy)
        try payload.write(to: root.appending(path: "bookbinder-save.json"))
        let io = SaveSlotFileIO(directory: root)

        let adopted = try await io.adoptLegacyIfNeeded(now: Date(timeIntervalSince1970: 10))
        let first = try XCTUnwrap(adopted)
        let repeatedAdoption = try await io.adoptLegacyIfNeeded(now: Date(timeIntervalSince1970: 20))
        XCTAssertNil(repeatedAdoption)
        let slots = await io.inspect()
        XCTAssertEqual(slots.count, 1)
        XCTAssertEqual(slots.first?.id, first)
        let envelopeURL = await io.slotsDirectory.appending(path: "\(first.description).slot.json")
        let envelope = try SaveCodec.makeDecoder().decode(
            SaveSlotEnvelope.self, from: Data(contentsOf: envelopeURL))
        XCTAssertEqual(envelope.payload, payload, "Adoption owns the exact legacy bytes without rewriting progress")
        let loadedLegacy = try await io.load(first)
        XCTAssertEqual(loadedLegacy.state, legacy)
        XCTAssertTrue(FileManager.default.fileExists(
            atPath: root.appending(path: "bookbinder-save.json.legacy-adopted")
                .path(percentEncoded: false)))
    }

    func testCorruptLegacyPrimaryRequiresExplicitRecoveryAndPreservesBoth() async throws {
        let root = directory()
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let corrupt = Data("not json".utf8)
        var healthy = GameState.newGame(); healthy.base.essence = 818
        let healthyBytes = try SaveCodec.encode(healthy)
        try corrupt.write(to: root.appending(path: "bookbinder-save.json"))
        try healthyBytes.write(to: root.appending(path: "bookbinder-save.json.backup"))
        let io = SaveSlotFileIO(directory: root)

        let automaticAdoption = try await io.adoptLegacyIfNeeded()
        XCTAssertNil(automaticAdoption)
        let assessed = await io.assessRawRecovery()
        let assessment = try XCTUnwrap(assessed)
        guard case .recoverableRawBackup(let primaryFingerprint, _) = assessment.classification else {
            return XCTFail("expected explicit recovery")
        }
        XCTAssertEqual(try Data(contentsOf: root.appending(path: "bookbinder-save.json")), corrupt)
        XCTAssertEqual(try Data(contentsOf: root.appending(path: "bookbinder-save.json.backup")), healthyBytes)
        let recoveredID = try await io.recoverRawBackup(assessment)
        XCTAssertEqual(recoveredID, SaveSlotFileIO.legacyID(for: healthyBytes))
        XCTAssertEqual(try Data(contentsOf: root.appending(path: "bookbinder-save.json")), healthyBytes)
        XCTAssertEqual(try Data(contentsOf: root.appending(path: "bookbinder-save.json.backup")), healthyBytes)
        XCTAssertEqual(try Data(contentsOf: root.appending(
            path: "bookbinder-save.json.recovery-original-\(primaryFingerprint.sha256)")), corrupt)
    }

    func testRecoveryAcceptsSchemaSeventeenStoredAndWornGearThenProjectionMigrates() async throws {
        let root = directory()
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let corrupt = Data("broken schema-17 primary".utf8)
        var state = GameState.newGame()
        XCTAssertTrue(state.base.inventory.add(ItemStack(
            id: .init(rawValue: 88_101), catalogID: "guard_padded")))
        state.base.binderEquipped[.weapon] = EquippedPiece(ItemStack(
            id: .init(rawValue: 88_102), catalogID: "blade_keen"))
        var payload = try XCTUnwrap(JSONSerialization.jsonObject(
            with: SaveCodec.encode(state)) as? [String: Any])
        func schemaSeventeen(_ value: Any) -> Any {
            if let array = value as? [Any] { return array.map(schemaSeventeen) }
            guard var object = value as? [String: Any] else { return value }
            if (object["version"] as? NSNumber)?.intValue == 4,
               object["stableInstanceID"] != nil, object["slot"] != nil {
                object["version"] = 3
                object.removeValue(forKey: "gameplayFacts")
            }
            for (key, child) in object { object[key] = schemaSeventeen(child) }
            return object
        }
        payload = schemaSeventeen(payload) as! [String: Any]
        payload["schemaVersion"] = 17
        let backup = try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
        let primaryURL = root.appending(path: "bookbinder-save.json")
        let backupURL = root.appending(path: "bookbinder-save.json.backup")
        try corrupt.write(to: primaryURL)
        try backup.write(to: backupURL)
        let io = SaveSlotFileIO(directory: root)

        let assessed = await io.assessRawRecovery()
        let assessment = try XCTUnwrap(assessed)
        guard case .recoverableRawBackup = assessment.classification else {
            return XCTFail("expected schema-17 backup to be recoverable")
        }
        XCTAssertEqual(try Data(contentsOf: primaryURL), corrupt)
        XCTAssertEqual(try Data(contentsOf: backupURL), backup)
        _ = try await io.recoverRawBackup(assessment)
        XCTAssertEqual(try Data(contentsOf: primaryURL), backup)
        XCTAssertEqual(try Data(contentsOf: backupURL), backup)

        let migrated = try XCTUnwrap(SaveFileIO(directory: root).load().state)
        XCTAssertEqual(migrated.schemaVersion, 18)
        XCTAssertEqual(migrated.base.inventory.stacks.first?.gearProfile?.version, 4)
        XCTAssertEqual(migrated.base.binderEquipped[.weapon]?.gearProfile?.version, 4)
    }

    func testMissingPrimaryAndFutureBackupClassifiesFutureWithoutMutation() async throws {
        let root = directory()
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let backupURL = root.appending(path: "bookbinder-save.json.backup")
        var object = try XCTUnwrap(JSONSerialization.jsonObject(
            with: SaveCodec.encode(.newGame())) as? [String: Any])
        object["schemaVersion"] = Tuning.saveSchemaVersion + 1
        let future = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
        try future.write(to: backupURL)
        let io = SaveSlotFileIO(directory: root)

        let assessed = await io.assessRawRecovery()
        let assessment = try XCTUnwrap(assessed)
        guard case .futureIncompatible(let found, let supported) = assessment.classification else {
            return XCTFail("expected future backup classification")
        }
        XCTAssertEqual(found, Tuning.saveSchemaVersion + 1)
        XCTAssertEqual(supported, Tuning.saveSchemaVersion)
        XCTAssertFalse(FileManager.default.fileExists(
            atPath: root.appending(path: "bookbinder-save.json").path))
        XCTAssertEqual(try Data(contentsOf: backupURL), future)
    }

    func testCorruptPrimaryAndFutureBackupClassifiesFutureAndPreservesBoth() async throws {
        let root = directory()
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let primaryURL = root.appending(path: "bookbinder-save.json")
        let backupURL = root.appending(path: "bookbinder-save.json.backup")
        let corrupt = Data("corrupt primary with future backup".utf8)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(
            with: SaveCodec.encode(.newGame())) as? [String: Any])
        object["schemaVersion"] = Tuning.saveSchemaVersion + 2
        let future = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
        try corrupt.write(to: primaryURL)
        try future.write(to: backupURL)
        let io = SaveSlotFileIO(directory: root)

        let assessed = await io.assessRawRecovery()
        let assessment = try XCTUnwrap(assessed)
        guard case .futureIncompatible(let found, let supported) = assessment.classification else {
            return XCTFail("expected future backup classification")
        }
        XCTAssertEqual(found, Tuning.saveSchemaVersion + 2)
        XCTAssertEqual(supported, Tuning.saveSchemaVersion)
        XCTAssertEqual(try Data(contentsOf: primaryURL), corrupt)
        XCTAssertEqual(try Data(contentsOf: backupURL), future)
    }

    func testRawRecoveryAssessmentRejectsChangedSourceWithoutMutation() async throws {
        let root = directory()
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let primaryURL = root.appending(path: "bookbinder-save.json")
        let backupURL = root.appending(path: "bookbinder-save.json.backup")
        let corrupt = Data("broken primary".utf8)
        let backup = try SaveCodec.encode(.newGame())
        try corrupt.write(to: primaryURL)
        try backup.write(to: backupURL)
        let io = SaveSlotFileIO(directory: root)
        let assessed = await io.assessRawRecovery()
        let assessment = try XCTUnwrap(assessed)
        let changed = Data("changed after assessment".utf8)
        try changed.write(to: primaryURL)

        do {
            _ = try await io.recoverRawBackup(assessment)
            XCTFail("expected stale assessment")
        } catch {
            XCTAssertEqual(error as? CampaignRecoveryRefusalV1, .staleAssessment)
        }
        XCTAssertEqual(try Data(contentsOf: primaryURL), changed)
        XCTAssertEqual(try Data(contentsOf: backupURL), backup)
    }

    func testSlotRecoveryAssessmentSeparatesFuturePayloadAndPreservesEnvelope() async throws {
        let root = directory()
        defer { try? FileManager.default.removeItem(at: root) }
        let io = SaveSlotFileIO(directory: root)
        let created = try await io.create(name: "Future")
        let url = try await io.exportURL(for: created.metadata.id)
        var envelope = try SaveCodec.makeDecoder().decode(
            SaveSlotEnvelope.self, from: Data(contentsOf: url))
        var payload = try XCTUnwrap(JSONSerialization.jsonObject(with: envelope.payload)
            as? [String: Any])
        payload["schemaVersion"] = Tuning.saveSchemaVersion + 1
        envelope.payload = try JSONSerialization.data(withJSONObject: payload)
        let bytes = try SaveCodec.makeEncoder().encode(envelope)
        try bytes.write(to: url, options: .atomic)

        let assessment = await io.assessSlotRecovery(created.metadata.id)
        guard case .futureIncompatible(let found, let supported) = assessment.classification else {
            return XCTFail("expected future payload")
        }
        XCTAssertEqual(found, Tuning.saveSchemaVersion + 1)
        XCTAssertEqual(supported, Tuning.saveSchemaVersion)
        XCTAssertEqual(try Data(contentsOf: url), bytes)
    }

    func testRawRecoveryIsIdempotentAndCreatesOneDeterministicArchive() async throws {
        let root = directory()
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let primaryURL = root.appending(path: "bookbinder-save.json")
        let backupURL = root.appending(path: "bookbinder-save.json.backup")
        let corrupt = Data("corrupt idempotent primary".utf8)
        let backup = try SaveCodec.encode(.newGame())
        try corrupt.write(to: primaryURL)
        try backup.write(to: backupURL)
        let io = SaveSlotFileIO(directory: root)
        let assessed = await io.assessRawRecovery()
        let assessment = try XCTUnwrap(assessed)
        guard case .recoverableRawBackup(let primaryFingerprint, _) = assessment.classification else {
            return XCTFail("expected recovery")
        }

        let first = try await io.recoverRawBackup(assessment)
        let second = try await io.recoverRawBackup(assessment)
        XCTAssertEqual(first, second)
        XCTAssertEqual(try Data(contentsOf: primaryURL), backup)
        XCTAssertEqual(try Data(contentsOf: backupURL), backup)
        let archiveName = "bookbinder-save.json.recovery-original-\(primaryFingerprint.sha256)"
        XCTAssertEqual(try Data(contentsOf: root.appending(path: archiveName)), corrupt)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: root.path)
            .filter { $0.hasPrefix("bookbinder-save.json.recovery-original-") }.count, 1)
    }

    func testRawRecoveryArchiveAndDestinationCollisionsAreAtomic() async throws {
        for collision in ["archive", "destination"] {
            let root = directory()
            defer { try? FileManager.default.removeItem(at: root) }
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
            let primaryURL = root.appending(path: "bookbinder-save.json")
            let backupURL = root.appending(path: "bookbinder-save.json.backup")
            let corrupt = Data("collision primary".utf8)
            let backup = try SaveCodec.encode(.newGame())
            try corrupt.write(to: primaryURL)
            try backup.write(to: backupURL)
            let io = SaveSlotFileIO(directory: root)
            let assessed = await io.assessRawRecovery()
            let assessment = try XCTUnwrap(assessed)
            guard case .recoverableRawBackup(let primaryFingerprint, let backupFingerprint) =
                    assessment.classification else { return XCTFail("expected recovery") }
            if collision == "archive" {
                try Data("different archive".utf8).write(to: root.appending(
                    path: "bookbinder-save.json.recovery-original-\(primaryFingerprint.sha256)"))
            } else {
                let slots = root.appending(path: "bookbinder-slots", directoryHint: .isDirectory)
                try FileManager.default.createDirectory(at: slots, withIntermediateDirectories: true)
                try Data("different destination".utf8).write(to: slots.appending(
                    path: "\(backupFingerprint.identity.description).slot.json"))
            }
            do {
                _ = try await io.recoverRawBackup(assessment)
                XCTFail("expected collision refusal")
            } catch { }
            XCTAssertEqual(try Data(contentsOf: primaryURL), corrupt)
            XCTAssertEqual(try Data(contentsOf: backupURL), backup)
        }
    }

    func testSlotIdentityMismatchAssessmentPreservesExactEnvelope() async throws {
        let root = directory()
        defer { try? FileManager.default.removeItem(at: root) }
        let io = SaveSlotFileIO(directory: root)
        let created = try await io.create(name: "Identity")
        let url = try await io.exportURL(for: created.metadata.id)
        var envelope = try SaveCodec.makeDecoder().decode(
            SaveSlotEnvelope.self, from: Data(contentsOf: url))
        envelope.metadata.id = SaveSlotID()
        let bytes = try SaveCodec.makeEncoder().encode(envelope)
        try bytes.write(to: url, options: .atomic)

        let assessment = await io.assessSlotRecovery(created.metadata.id)
        XCTAssertEqual(assessment.classification, .invalid(.slotIdentityMismatch))
        XCTAssertEqual(try Data(contentsOf: url), bytes)
    }

    func testCompletePendingTransactionClassifiesPlayableWithoutMutation() async throws {
        let root = directory()
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        var state = GameState.newGame()
        state.worlds.pendingAnchorSettlement = true
        let bytes = try SaveCodec.encode(state)
        let primaryURL = root.appending(path: "bookbinder-save.json")
        try bytes.write(to: primaryURL)
        let io = SaveSlotFileIO(directory: root)

        let assessed = await io.assessRawRecovery()
        let assessment = try XCTUnwrap(assessed)
        guard case .playable(_, _, let hasPending) = assessment.classification else {
            return XCTFail("expected playable")
        }
        XCTAssertTrue(hasPending)
        XCTAssertEqual(try Data(contentsOf: primaryURL), bytes)
    }

    func testCorruptLegacyPrimaryAndBackupBecomeOneVisibleInvalidSlot() async throws {
        let root = directory()
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try Data("bad primary".utf8).write(to: root.appending(path: "bookbinder-save.json"))
        try Data("bad backup".utf8).write(to: root.appending(path: "bookbinder-save.json.backup"))
        let io = SaveSlotFileIO(directory: root)

        _ = try await io.adoptLegacyIfNeeded()
        let slots = await io.inspect()
        XCTAssertEqual(slots.count, 1)
        XCTAssertFalse(slots[0].isValid)
        let continued = await io.continueSlot()
        let repeated = try await io.adoptLegacyIfNeeded()
        XCTAssertNil(continued)
        XCTAssertNil(repeated)
    }

    func testTwoCampaignsRemainIndependentAcrossCreateSaveAndSwitch() async throws {
        let root = directory()
        defer { try? FileManager.default.removeItem(at: root) }
        let io = SaveSlotFileIO(directory: root)
        let t1 = Date(timeIntervalSince1970: 100)
        let t2 = Date(timeIntervalSince1970: 200)
        var first = GameState.newGame(); first.base.essence = 11
        let one = try await io.create(name: "One", state: first, now: t1)
        _ = try await io.acquireWriterLease(for: one.metadata.id)
        first.base.essence = 12
        var second = GameState.newGame(); second.base.essence = 22
        let two = try await io.create(name: "Two", state: second, now: t2,
                                      flushingActiveState: first)
        _ = try await io.acquireWriterLease(for: two.metadata.id)
        second.base.essence = 23

        let reopenedOne = try await io.switchTo(one.metadata.id,
                                                flushingActiveState: second,
                                                now: Date(timeIntervalSince1970: 300))
        XCTAssertEqual(reopenedOne.state.base.essence, 12)
        let savedTwo = try await io.load(two.metadata.id)
        let active = await io.activeSlotID()
        XCTAssertEqual(savedTwo.state.base.essence, 23)
        XCTAssertEqual(active, one.metadata.id)
    }

    func testChangingOwnershipRequiresTheActiveCampaignFlush() async throws {
        let root = directory()
        defer { try? FileManager.default.removeItem(at: root) }
        let io = SaveSlotFileIO(directory: root)
        let first = try await io.create(name: "First")
        _ = try await io.acquireWriterLease(for: first.metadata.id)
        do {
            _ = try await io.create(name: "Second")
            XCTFail("Expected active flush requirement")
        } catch {
            XCTAssertEqual(error as? SaveSlotError, .activeFlushRequired(first.metadata.id))
        }
        let afterFailedCreate = await io.inspect()
        XCTAssertEqual(afterFailedCreate.count, 1)
    }

    func testContinueChoosesMostRecentValidAndIgnoresCorruptSlot() async throws {
        let root = directory()
        defer { try? FileManager.default.removeItem(at: root) }
        let io = SaveSlotFileIO(directory: root)
        var oneState = GameState.newGame(); oneState.base.essence = 10
        let one = try await io.create(name: "Old", state: oneState,
                                      now: Date(timeIntervalSince1970: 10))
        var twoState = GameState.newGame(); twoState.base.essence = 20
        _ = try await io.create(name: "Recent", state: twoState,
                                now: Date(timeIntervalSince1970: 20))
        let corruptID = SaveSlotID()
        let slotsDirectory = await io.slotsDirectory
        try FileManager.default.createDirectory(at: slotsDirectory, withIntermediateDirectories: true)
        try Data("not an envelope".utf8)
            .write(to: slotsDirectory.appending(path: "\(corruptID.description).slot.json"))

        let continued = await io.continueSlot()
        let chosen = try XCTUnwrap(continued)
        XCTAssertEqual(chosen.metadata.name, "Recent")
        XCTAssertEqual(chosen.state.base.essence, 20)
        let inspected = await io.inspect()
        let corrupt = try XCTUnwrap(inspected.first { $0.id == corruptID })
        XCTAssertFalse(corrupt.isValid)
        let savedOne = try await io.load(one.metadata.id)
        XCTAssertEqual(savedOne.state.base.essence, 10)
    }

    func testInspectingCorruptSlotIsNonmutating() async throws {
        let root = directory()
        defer { try? FileManager.default.removeItem(at: root) }
        let io = SaveSlotFileIO(directory: root)
        let id = SaveSlotID()
        let slotsDirectory = await io.slotsDirectory
        try FileManager.default.createDirectory(at: slotsDirectory, withIntermediateDirectories: true)
        let url = slotsDirectory.appending(path: "\(id.description).slot.json")
        let bytes = Data("broken".utf8)
        try bytes.write(to: url)

        let first = await io.inspect()
        let second = await io.inspect()
        XCTAssertEqual(first, second)
        XCTAssertEqual(try Data(contentsOf: url), bytes)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path(percentEncoded: false)))
    }

    func testFuturePayloadRemainsVisibleButCannotLoadOrBecomeContinue() async throws {
        let root = directory()
        defer { try? FileManager.default.removeItem(at: root) }
        let io = SaveSlotFileIO(directory: root)
        let id = SaveSlotID()
        let now = Date(timeIntervalSince1970: 50)
        var state = GameState.newGame()
        state.schemaVersion = Tuning.saveSchemaVersion + 10
        let metadata = SaveSlotMetadata.make(id: id, name: "Future", state: state,
                                             createdAt: now, lastPlayedAt: now)
        let envelope = SaveSlotEnvelope(metadata: metadata,
                                        payload: try SaveCodec.makeEncoder().encode(state))
        let slotsDirectory = await io.slotsDirectory
        try FileManager.default.createDirectory(at: slotsDirectory, withIntermediateDirectories: true)
        try encoder().encode(envelope)
            .write(to: slotsDirectory.appending(path: "\(id.description).slot.json"))

        let futureSlots = await io.inspect()
        let listed = try XCTUnwrap(futureSlots.first)
        XCTAssertEqual(listed.validity,
                       .futureIncompatible(schemaVersion: Tuning.saveSchemaVersion + 10))
        let futureContinue = await io.continueSlot()
        XCTAssertNil(futureContinue)
        do { _ = try await io.load(id); XCTFail("Expected future rejection") }
        catch {
            XCTAssertEqual(error as? SaveSlotError,
                           .futureIncompatible(schemaVersion: Tuning.saveSchemaVersion + 10))
        }
    }

    func testCurrentCombatOpeningOmissionFailsSlotLoadWithoutRewritingEnvelope() async throws {
        let root = directory()
        defer { try? FileManager.default.removeItem(at: root) }
        let io = SaveSlotFileIO(directory: root)
        let id = SaveSlotID()
        let now = Date(timeIntervalSince1970: 55)
        let state = GameState.newGame()
        var payload = try XCTUnwrap(JSONSerialization.jsonObject(
            with: SaveCodec.encode(state)) as? [String: Any])
        var base = try XCTUnwrap(payload["base"] as? [String: Any])
        var binder = try XCTUnwrap(base["binderCharacter"] as? [String: Any])
        binder.removeValue(forKey: "ownedCombatNodeIDs")
        base["binderCharacter"] = binder
        payload["base"] = base
        let malformedPayload = try JSONSerialization.data(withJSONObject: payload,
                                                           options: [.sortedKeys])
        let metadata = SaveSlotMetadata.make(id: id, name: "Malformed combat", state: state,
                                             createdAt: now, lastPlayedAt: now)
        let envelope = SaveSlotEnvelope(metadata: metadata, payload: malformedPayload)
        let bytes = try encoder().encode(envelope)
        let slotsDirectory = await io.slotsDirectory
        try FileManager.default.createDirectory(at: slotsDirectory, withIntermediateDirectories: true)
        let url = slotsDirectory.appending(path: "\(id.description).slot.json")
        try bytes.write(to: url)

        do { _ = try await io.load(id); XCTFail("Expected malformed combat ownership rejection") }
        catch { }
        XCTAssertEqual(try Data(contentsOf: url), bytes)
        let adapter = SaveSlotPayloadIO(saveURL: url, slotID: id, lease: SaveSlotWriterLease())
        guard case .unrecoverable = adapter.load() else {
            return XCTFail("Malformed current combat ownership must fail closed")
        }
        XCTAssertEqual(try Data(contentsOf: url), bytes)
    }

    func testDuplicateMerchantPhysicalGearIdentityFailsRawAndSlotWithoutRewritingBytes() async throws {
        var state = GameState.newGame()
        let stack = ItemStack(id: .init(rawValue: 98_001), catalogID: "blade_chipped")
        XCTAssertTrue(state.base.inventory.add(stack))
        state.base.tradingPost.stock = [.init(
            id: 301, kind: .item(stack.catalogID), remainingQuantity: 1,
            unitPrice: 20, frozenUnits: [stack])]
        state.base.tradingPost.nextStockLineID = 302
        let payload = try SaveCodec.encode(state)
        XCTAssertThrowsError(try SaveCodec.decode(payload))

        let root = directory()
        defer { try? FileManager.default.removeItem(at: root) }
        let io = SaveSlotFileIO(directory: root)
        let id = SaveSlotID()
        let now = Date(timeIntervalSince1970: 56)
        let metadata = SaveSlotMetadata.make(id: id, name: "Duplicate merchant gear", state: state,
                                             createdAt: now, lastPlayedAt: now)
        let bytes = try encoder().encode(SaveSlotEnvelope(metadata: metadata, payload: payload))
        let slotsDirectory = await io.slotsDirectory
        try FileManager.default.createDirectory(at: slotsDirectory, withIntermediateDirectories: true)
        let url = slotsDirectory.appending(path: "\(id.description).slot.json")
        try bytes.write(to: url)

        do { _ = try await io.load(id); XCTFail("Expected duplicate physical identity rejection") }
        catch { }
        XCTAssertEqual(try Data(contentsOf: url), bytes)
    }

    func testMalformedPhysicalGearIdentityAuthorityFailsRawAndSlotWithoutRewritingBytes() async throws {
        let valid = try SaveCodec.encode(GameState.newGame())
        let corruptValues: [Any] = [0, -1, true, NSNull()]
        for (offset, corruptValue) in corruptValues.enumerated() {
            var root = try XCTUnwrap(JSONSerialization.jsonObject(with: valid) as? [String: Any])
            var base = try XCTUnwrap(root["base"] as? [String: Any])
            base["nextPhysicalGearInstanceID"] = corruptValue
            root["base"] = base
            let payload = try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys])
            XCTAssertThrowsError(try SaveCodec.decode(payload))

            let directory = directory()
            defer { try? FileManager.default.removeItem(at: directory) }
            let io = SaveSlotFileIO(directory: directory)
            let id = SaveSlotID()
            let now = Date(timeIntervalSince1970: TimeInterval(70 + offset))
            let metadata = SaveSlotMetadata.make(
                id: id, name: "Malformed gear identity", state: .newGame(),
                createdAt: now, lastPlayedAt: now)
            let bytes = try encoder().encode(SaveSlotEnvelope(metadata: metadata, payload: payload))
            let slotsDirectory = await io.slotsDirectory
            try FileManager.default.createDirectory(at: slotsDirectory, withIntermediateDirectories: true)
            let url = slotsDirectory.appending(path: "\(id.description).slot.json")
            try bytes.write(to: url)
            do { _ = try await io.load(id); XCTFail("Expected malformed identity rejection") }
            catch { }
            XCTAssertEqual(try Data(contentsOf: url), bytes)
        }
    }

    func testFutureEnvelopeWithCurrentPayloadIsVisibleExportableAndNeverDecodedOrRewritten() async throws {
        let root = directory()
        defer { try? FileManager.default.removeItem(at: root) }
        let io = SaveSlotFileIO(directory: root)
        let id = SaveSlotID()
        let now = Date(timeIntervalSince1970: 60)
        let current = GameState.newGame()
        let metadata = SaveSlotMetadata.make(id: id, name: "Future envelope", state: current,
                                             createdAt: now, lastPlayedAt: now)
        var envelope = SaveSlotEnvelope(metadata: metadata, payload: try SaveCodec.encode(current))
        envelope.schemaVersion = SaveSlotEnvelope.schemaVersion + 7
        let bytes = try encoder().encode(envelope)
        let slotsDirectory = await io.slotsDirectory
        try FileManager.default.createDirectory(at: slotsDirectory, withIntermediateDirectories: true)
        let url = slotsDirectory.appending(path: "\(id.description).slot.json")
        try bytes.write(to: url)

        let inspected = await io.inspect()
        let listed = try XCTUnwrap(inspected.first)
        XCTAssertEqual(listed.validity,
                       .futureIncompatible(schemaVersion: SaveSlotEnvelope.schemaVersion + 7))
        let export = try await io.exportURL(for: id)
        XCTAssertEqual(try Data(contentsOf: export), bytes)
        do { _ = try await io.load(id); XCTFail("Expected future envelope rejection") }
        catch {
            XCTAssertEqual(error as? SaveSlotError,
                           .futureIncompatible(schemaVersion: SaveSlotEnvelope.schemaVersion + 7))
        }

        let adapter = SaveSlotPayloadIO(saveURL: url, slotID: id, lease: SaveSlotWriterLease())
        guard case .unrecoverable = adapter.load() else {
            return XCTFail("A future envelope must not expose its current-looking payload")
        }
        var changed = current; changed.base.essence = 999
        XCTAssertThrowsError(try adapter.write(SaveCodec.encode(changed))) { error in
            XCTAssertEqual(error as? SaveSlotPayloadError,
                           .futureIncompatible(schemaVersion: SaveSlotEnvelope.schemaVersion + 7))
        }
        XCTAssertEqual(try Data(contentsOf: url), bytes)
    }

    func testDeleteRequiresExactNameAndSoftMovesOnlyConfirmedSlot() async throws {
        let root = directory()
        defer { try? FileManager.default.removeItem(at: root) }
        let io = SaveSlotFileIO(directory: root)
        let oneState = GameState.newGame()
        let one = try await io.create(name: "Keep", state: oneState)
        let two = try await io.create(name: "Delete me", state: .newGame())
        do {
            try await io.delete(two.metadata.id, confirmingName: "Wrong",
                                flushingActiveState: .newGame())
            XCTFail("Expected confirmation mismatch")
        } catch { XCTAssertEqual(error as? SaveSlotError, .confirmationMismatch) }
        let afterCancelledDelete = await io.inspect()
        XCTAssertEqual(afterCancelledDelete.count, 2)

        try await io.delete(two.metadata.id, confirmingName: "Delete me",
                            flushingActiveState: .newGame(),
                            now: Date(timeIntervalSince1970: 500))
        let remaining = await io.inspect()
        XCTAssertEqual(remaining.map(\.id), [one.metadata.id])
        let activeAfterDelete = await io.activeSlotID()
        XCTAssertNil(activeAfterDelete)
        let trashed = try FileManager.default.contentsOfDirectory(at: await io.trashDirectory,
                                                                  includingPropertiesForKeys: nil)
        XCTAssertEqual(trashed.count, 1)
        XCTAssertTrue(trashed[0].lastPathComponent.contains(two.metadata.id.description))
    }

    func testCorruptSlotCanBeConfirmedAndSoftDeletedWithoutPlayableDecode() async throws {
        let root = directory()
        defer { try? FileManager.default.removeItem(at: root) }
        let io = SaveSlotFileIO(directory: root)
        let id = SaveSlotID()
        let slotsDirectory = await io.slotsDirectory
        try FileManager.default.createDirectory(at: slotsDirectory, withIntermediateDirectories: true)
        try Data("broken envelope".utf8)
            .write(to: slotsDirectory.appending(path: "\(id.description).slot.json"))
        let corruptSlots = await io.inspect()
        let descriptor = try XCTUnwrap(corruptSlots.first)

        try await io.delete(id, confirmingName: descriptor.displayName,
                            flushingActiveState: nil)
        let remaining = await io.inspect()
        let trash = try FileManager.default.contentsOfDirectory(at: await io.trashDirectory,
                                                                 includingPropertiesForKeys: nil)
        XCTAssertEqual(remaining, [])
        XCTAssertEqual(trash.count, 1)
        XCTAssertTrue(trash[0].lastPathComponent.contains(id.description))
    }

    func testFutureSlotCanBeConfirmedAndSoftDeletedByEnvelopeMetadata() async throws {
        let root = directory()
        defer { try? FileManager.default.removeItem(at: root) }
        let io = SaveSlotFileIO(directory: root)
        let id = SaveSlotID()
        let now = Date(timeIntervalSince1970: 80)
        var future = GameState.newGame(); future.schemaVersion = Tuning.saveSchemaVersion + 1
        let metadata = SaveSlotMetadata.make(id: id, name: "Future test", state: future,
                                             createdAt: now, lastPlayedAt: now)
        let envelope = SaveSlotEnvelope(metadata: metadata,
                                        payload: try SaveCodec.makeEncoder().encode(future))
        let slotsDirectory = await io.slotsDirectory
        try FileManager.default.createDirectory(at: slotsDirectory, withIntermediateDirectories: true)
        try encoder().encode(envelope)
            .write(to: slotsDirectory.appending(path: "\(id.description).slot.json"))

        try await io.delete(id, confirmingName: "Future test", flushingActiveState: nil)
        let remaining = await io.inspect()
        XCTAssertEqual(remaining, [])
    }

    func testDeletingNonactiveSlotFlushesActiveWithoutCrossWiringEitherIdentity() async throws {
        let root = directory()
        defer { try? FileManager.default.removeItem(at: root) }
        let io = SaveSlotFileIO(directory: root)
        var firstState = GameState.newGame(); firstState.base.essence = 1
        let first = try await io.create(name: "First", state: firstState)
        let secondState = GameState.newGame()
        let second = try await io.create(name: "Second", state: secondState)
        _ = try await io.switchTo(first.metadata.id, flushingActiveState: nil)
        _ = try await io.acquireWriterLease(for: first.metadata.id)
        firstState.base.essence = 99

        try await io.delete(second.metadata.id, confirmingName: "Second",
                            flushingActiveState: firstState)
        let activeAfterDeletingOther = await io.activeSlotID()
        let preservedFirst = try await io.load(first.metadata.id)
        XCTAssertEqual(activeAfterDeletingOther, first.metadata.id)
        XCTAssertEqual(preservedFirst.state.base.essence, 99)
    }

    func testStableIdentityNeverUsesNameOrListPosition() async throws {
        let root = directory()
        defer { try? FileManager.default.removeItem(at: root) }
        let io = SaveSlotFileIO(directory: root)
        let sameName = "Campaign"
        let first = try await io.create(name: sameName)
        let second = try await io.create(name: sameName)
        XCTAssertNotEqual(first.metadata.id, second.metadata.id)
        let namedSlots = await io.inspect()
        XCTAssertEqual(Set(namedSlots.map(\.id)),
                       Set([first.metadata.id, second.metadata.id]))
    }

    func testPersistedSelectionAfterRelaunchIsNotMistakenForALiveWriter() async throws {
        let root = directory()
        defer { try? FileManager.default.removeItem(at: root) }
        let firstProcess = SaveSlotFileIO(directory: root)
        let old = try await firstProcess.create(name: "Old")

        let relaunched = SaveSlotFileIO(directory: root)
        let new = try await relaunched.create(name: "New", flushingActiveState: nil)
        _ = try await relaunched.switchTo(old.metadata.id, flushingActiveState: nil)
        try await relaunched.delete(new.metadata.id, confirmingName: "New",
                                    flushingActiveState: nil)
        let relaunchedActive = await relaunched.activeSlotID()
        let relaunchedSlots = await relaunched.inspect()
        XCTAssertEqual(relaunchedActive, old.metadata.id)
        XCTAssertEqual(relaunchedSlots.map(\.id), [old.metadata.id])
    }

    func testSwitchTouchesLastPlayedSoImmediateRelaunchContinuesSelectedSlot() async throws {
        let root = directory()
        defer { try? FileManager.default.removeItem(at: root) }
        let io = SaveSlotFileIO(directory: root)
        let older = try await io.create(name: "Older", now: Date(timeIntervalSince1970: 10))
        _ = try await io.create(name: "Newer", now: Date(timeIntervalSince1970: 20))
        let selectedAt = Date(timeIntervalSince1970: 30)
        let selected = try await io.switchTo(older.metadata.id, flushingActiveState: nil,
                                             now: selectedAt)
        XCTAssertEqual(selected.metadata.lastPlayedAt, selectedAt)

        let relaunched = SaveSlotFileIO(directory: root)
        let continuedResult = await relaunched.continueSlot()
        let continued = try XCTUnwrap(continuedResult)
        XCTAssertEqual(continued.metadata.id, older.metadata.id)
        XCTAssertEqual(continued.metadata.lastPlayedAt, selectedAt)
    }

    func testGameStorePreparationAutosavesIntoSameEnvelopeWithoutShadowRawFile() async throws {
        let root = directory()
        defer { try? FileManager.default.removeItem(at: root) }
        let slots = SaveSlotFileIO(directory: root)
        let createdAt = Date(timeIntervalSince1970: 123)
        let created = try await slots.create(name: "Atlas A", now: createdAt)
        _ = try await slots.acquireWriterLease(for: created.metadata.id)
        let payloadIO = try await slots.payloadIOForLeasedSlot()

        let prepared = try GameStore.prepareLaunch(io: payloadIO)
        let loaded = try await slots.load(created.metadata.id)
        XCTAssertEqual(loaded.state, prepared.state)
        XCTAssertEqual(loaded.metadata.name, "Atlas A")
        XCTAssertEqual(loaded.metadata.createdAt, createdAt)
        XCTAssertEqual(loaded.metadata.binderLevel, prepared.state.base.binderCharacter.level)
        XCTAssertFalse(FileManager.default.fileExists(
            atPath: root.appending(path: "bookbinder-save.json").path(percentEncoded: false)))
    }

    func testSwitchFlushRetiresOldPayloadAdapterAndPreventsLateCrossWrite() async throws {
        let root = directory()
        defer { try? FileManager.default.removeItem(at: root) }
        let slots = SaveSlotFileIO(directory: root)
        var firstState = GameState.newGame(); firstState.base.essence = 40
        let first = try await slots.create(name: "First", state: firstState)
        let second = try await slots.create(name: "Second")
        _ = try await slots.switchTo(first.metadata.id, flushingActiveState: nil)
        _ = try await slots.acquireWriterLease(for: first.metadata.id)
        let oldAdapter = try await slots.payloadIOForLeasedSlot()
        firstState.base.essence = 41

        _ = try await slots.switchTo(second.metadata.id, flushingActiveState: firstState)
        var stale = firstState; stale.base.essence = 999
        XCTAssertThrowsError(try oldAdapter.write(SaveCodec.encode(stale))) { error in
            XCTAssertEqual(error as? SaveSlotPayloadError, .retiredWriter)
        }
        let preserved = try await slots.load(first.metadata.id)
        XCTAssertEqual(preserved.state.base.essence, 41)
        let active = await slots.activeSlotID()
        XCTAssertEqual(active, second.metadata.id)
    }

    func testCorruptEnvelopeExportIsByteExactAndNonmutating() async throws {
        let root = directory()
        defer { try? FileManager.default.removeItem(at: root) }
        let slots = SaveSlotFileIO(directory: root)
        let id = SaveSlotID()
        let bytes = Data("whole corrupt envelope".utf8)
        let directory = await slots.slotsDirectory
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let original = directory.appending(path: "\(id.description).slot.json")
        try bytes.write(to: original)

        let export = try await slots.exportURL(for: id)
        XCTAssertEqual(export, original)
        XCTAssertEqual(try Data(contentsOf: export), bytes)
        XCTAssertEqual(try Data(contentsOf: original), bytes)
    }

    func testCancelledPreparationRetiresAdapterWithoutTouchingPayloadOrSelection() async throws {
        let root = directory()
        defer { try? FileManager.default.removeItem(at: root) }
        let slots = SaveSlotFileIO(directory: root)
        let created = try await slots.create(name: "Kept")
        _ = try await slots.acquireWriterLease(for: created.metadata.id)
        let adapter = try await slots.payloadIOForLeasedSlot()
        let bytesBefore = try Data(contentsOf: adapter.saveURL)

        await slots.releaseWriterLeaseWithoutSaving()
        XCTAssertThrowsError(try adapter.write(SaveCodec.encode(.newGame()))) { error in
            XCTAssertEqual(error as? SaveSlotPayloadError, .retiredWriter)
        }
        XCTAssertEqual(try Data(contentsOf: adapter.saveURL), bytesBefore)
        let active = await slots.activeSlotID()
        XCTAssertEqual(active, created.metadata.id)
    }

    func testReturnToCampaignsFlushesAndRetiresWhileLeavingSelection() async throws {
        let root = directory()
        defer { try? FileManager.default.removeItem(at: root) }
        let slots = SaveSlotFileIO(directory: root)
        let created = try await slots.create(name: "Active")
        _ = try await slots.acquireWriterLease(for: created.metadata.id)
        let adapter = try await slots.payloadIOForLeasedSlot()
        var final = created.state; final.base.essence = 707

        _ = try await slots.releaseWriterLease(flushing: final)
        let loaded = try await slots.load(created.metadata.id)
        let active = await slots.activeSlotID()
        XCTAssertEqual(loaded.state.base.essence, 707)
        XCTAssertEqual(active, created.metadata.id)
        XCTAssertThrowsError(try adapter.write(SaveCodec.encode(.newGame()))) { error in
            XCTAssertEqual(error as? SaveSlotPayloadError, .retiredWriter)
        }
    }

    func testDiagnosticCampaignReferenceIsStableDistinctAndDoesNotExposeSlotID() async throws {
        let firstID = SaveSlotID()
        let secondID = SaveSlotID()
        let first = SaveSlotPayloadIO(
            saveURL: directory().appending(path: "first.slot.json"),
            slotID: firstID,
            lease: SaveSlotWriterLease()
        )
        let same = SaveSlotPayloadIO(
            saveURL: directory().appending(path: "same.slot.json"),
            slotID: firstID,
            lease: SaveSlotWriterLease()
        )
        let second = SaveSlotPayloadIO(
            saveURL: directory().appending(path: "second.slot.json"),
            slotID: secondID,
            lease: SaveSlotWriterLease()
        )

        let firstReference = try XCTUnwrap(first.diagnosticCampaignReference)
        XCTAssertEqual(firstReference, same.diagnosticCampaignReference)
        XCTAssertNotEqual(firstReference, second.diagnosticCampaignReference)
        XCTAssertEqual(firstReference.count, 12)
        XCTAssertFalse(firstID.description.lowercased().contains(firstReference))
        XCTAssertFalse(firstReference.contains(firstID.description.lowercased()))
    }
}
