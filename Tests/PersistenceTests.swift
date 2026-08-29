import XCTest
@testable import Bookbinder

/// The interruptibility pillar, tested. Anything that breaks here breaks pillar 2.
final class PersistenceTests: XCTestCase {
    private func resourceNodeAuthorityState() -> GameState {
        var state = GameState.newGame()
        let point = GridPoint(x: 0, y: 0)
        let mineral = ResourceNode(resource: Resources.ore,
                                   extractionRequirement: .init(
                                    resourceID: Resources.ore, disposition: .mineralNode,
                                    requiredExtractionRank: 4),
                                   remainingHarvests: 2, yieldPerHarvest: 3)
        let flora = ResourceNode(resource: Resources.fiber,
                                 extractionRequirement: .init(
                                    resourceID: Resources.fiber, disposition: .floraPrimary,
                                    requiredExtractionRank: nil),
                                 remainingHarvests: 2, yieldPerHarvest: 2)
        let active = WorldRun(runIndex: 801, book: .init(written: [], essencePaid: 0),
                              mapSeed: 801_001, rng: .init(seed: 801_001),
                              map: .init(width: 1, height: 1,
                                         tiles: [Tile(content: .node(mineral), isRevealed: true)],
                                         entry: point), playerPosition: point)
        let anchored = WorldRun(runIndex: 802, book: .init(written: [], essencePaid: 0),
                                mapSeed: 802_001, rng: .init(seed: 802_001),
                                map: .init(width: 1, height: 1,
                                           tiles: [Tile(content: .node(flora), isRevealed: true)],
                                           entry: point), playerPosition: point)
        state.worlds.activeRun = active
        state.worlds.anchoredRealms = [
            .init(runIndex: anchored.runIndex, name: "Frozen grove", route: .bornAnchored,
                  world: anchored)
        ]
        return state
    }

    private func mutatingResourceNode(
        in data: Data, anchored: Bool = false,
        _ mutation: (inout [String: Any]) -> Void
    ) throws -> Data {
        var root = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        var worlds = try XCTUnwrap(root["worlds"] as? [String: Any])
        var run: [String: Any]
        var realms = worlds["anchoredRealms"] as? [[String: Any]] ?? []
        if anchored {
            run = try XCTUnwrap(realms[0]["world"] as? [String: Any])
        } else {
            run = try XCTUnwrap(worlds["activeRun"] as? [String: Any])
        }
        var map = try XCTUnwrap(run["map"] as? [String: Any])
        var tiles = try XCTUnwrap(map["tiles"] as? [[String: Any]])
        var content = try XCTUnwrap(tiles[0]["content"] as? [String: Any])
        var associated = try XCTUnwrap(content["node"] as? [String: Any])
        var node = try XCTUnwrap(associated["_0"] as? [String: Any])
        mutation(&node)
        associated["_0"] = node; content["node"] = associated; tiles[0]["content"] = content
        map["tiles"] = tiles; run["map"] = map
        if anchored {
            realms[0]["world"] = run; worlds["anchoredRealms"] = realms
        } else { worlds["activeRun"] = run }
        root["worlds"] = worlds
        return try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys])
    }

    private func currentEncounterState() throws -> GameState {
        var state = GameState.newGame()
        let point = GridPoint(x: 0, y: 0)
        var run = WorldRun(runIndex: 91, book: .init(written: [], essencePaid: 0),
                           mapSeed: 91_001, rng: .init(seed: 91_001),
                           map: .init(width: 1, height: 1,
                                      tiles: [Tile(isRevealed: true)], entry: point),
                           playerPosition: point)
        let enemy = WorldEnemy(id: .init(rawValue: 91_001), creatureID: "paper_moth",
                               position: run.playerPosition)
        run.enemies = [enemy]; state.worlds.activeRun = run
        guard case .started = WorldRules.beginEncounter(triggerID: enemy.id,
            expected: enemy, runsAutomaticTurns: false, in: &state) else {
            throw CocoaError(.coderInvalidValue)
        }
        return state
    }

    private func currentApexEncounterState() throws -> GameState {
        var state = GameState.newGame()
        let generatedID = PersistentPartyMemberID.generated("apex-raw-helper")
        var generated = CompanionState(); generated.persistentID = generatedID
        generated.name = "Aster"
        state.base.roster.append(generated); state.base.activeParty.append(generatedID)
        let point = GridPoint(x: 0, y: 0)
        var run = WorldRun(runIndex: 92, book: .init(written: [], essencePaid: 0),
                           mapSeed: 92_001, rng: .init(seed: 92_001),
                           map: .init(width: 1, height: 1,
                                      tiles: [Tile(isRevealed: true)], entry: point),
                           playerPosition: point)
        let enemy = WorldEnemy(id: .init(rawValue: 92_001), creatureID: "paper_moth",
                               position: point, isApex: true)
        run.enemies = [enemy]; state.worlds.activeRun = run
        guard case .started = WorldRules.beginEncounter(triggerID: enemy.id, expected: enemy,
            runsAutomaticTurns: false, in: &state),
              let encounter = state.worlds.activeRun?.activeEncounter,
              encounter.scalingPreview?.apexActionSlots == 2 else {
            throw CocoaError(.coderInvalidValue)
        }
        return state
    }

    private func currentPressureEncounterState(foeCount: Int = 2) throws -> GameState {
        var state = GameState.newGame()
        for ordinal in 1...3 {
            let id = PersistentPartyMemberID.generated("pressure-raw-\(ordinal)")
            var member = CompanionState(); member.persistentID = id; member.name = "P\(ordinal)"
            state.base.roster.append(member); state.base.activeParty.append(id)
        }
        state.base.binderCharacter.level = 8
        for index in state.base.roster.indices { state.base.roster[index].character.level = 8 }
        let point = GridPoint(x: 0, y: 0), adjacent = GridPoint(x: 1, y: 0)
        var run = WorldRun(runIndex: 93, book: .init(written: [], essencePaid: 0),
                           mapSeed: 93_001, rng: .init(seed: 93_001),
                           map: .init(width: 2, height: 1,
                                      tiles: [Tile(isRevealed: true), Tile(isRevealed: true)], entry: point),
                           playerPosition: point)
        let enemies = Array([WorldEnemy(id: .init(rawValue: 93_001), creatureID: "paper_moth",
                                  position: point, isAwake: true),
                       WorldEnemy(id: .init(rawValue: 93_002), creatureID: "paper_moth",
                                  position: adjacent, isAwake: true)].prefix(foeCount))
        run.enemies = enemies; state.worlds.activeRun = run
        guard case .started = WorldRules.beginEncounter(triggerID: enemies[0].id,
            expected: enemies[0], runsAutomaticTurns: false, in: &state),
              var encounter = state.worlds.activeRun?.activeEncounter,
              encounter.foes.count == foeCount,
              var preview = encounter.scalingPreview else {
            throw CocoaError(.coderInvalidValue)
        }
        // Frozen additive-pressure receipts may lawfully retain two slots even when today's
        // catalogue/tuning would allocate fewer. Build the exact canonical frozen schedule.
        preview.wholePressureSlots = 2
        encounter.scalingPreview = preview
        encounter.turnSlots = CombatRules.turnSlots(order: encounter.order, foes: encounter.foes,
            apexActionSlots: [:], ordinaryPressureSlots: 2)
        encounter.pressureOwners = .init(entries: encounter.turnSlots.compactMap { slot in
            guard case .ordinaryPressureFollowUp(let ordinal) = slot.kind,
                  case .foe(let foeID) = slot.actor else { return nil }
            return .init(ordinal: ordinal, foeID: foeID)
        }.sorted { $0.ordinal < $1.ordinal })
        state.worlds.activeRun?.activeEncounter = encounter
        guard EncounterSnapshotRulesV1.validatesAll(in: state) else {
            throw CocoaError(.coderInvalidValue)
        }
        return state
    }

    private func mutatingActiveEncounter(
        in data: Data, _ mutation: (inout [String: Any]) -> Void
    ) throws -> Data {
        var root = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        var worlds = try XCTUnwrap(root["worlds"] as? [String: Any])
        var run = try XCTUnwrap(worlds["activeRun"] as? [String: Any])
        var encounter = try XCTUnwrap(run["activeEncounter"] as? [String: Any])
        mutation(&encounter); run["activeEncounter"] = encounter
        worlds["activeRun"] = run; root["worlds"] = worlds
        return try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys])
    }

    private func dynamicallyReorderedApexState(staggered: Bool) throws -> GameState {
        var state = try currentApexEncounterState()
        guard var run = state.worlds.activeRun, var encounter = run.activeEncounter,
              let apex = encounter.foes.first, let preview = encounter.scalingPreview else {
            throw CocoaError(.coderInvalidValue)
        }
        if staggered {
            encounter.pendingStaggers[apex.id] = .init(
                foeID: apex.id, applyingRound: encounter.roundNumber,
                sourceActors: [.binder], sourceNodeIDs: [CombatDerivedStatsRules.Node.stagger],
                automatic: true)
            CombatRules.applyPendingStaggers(for: encounter.roundNumber, run: run,
                                              encounter: &encounter)
        } else {
            let owner = try XCTUnwrap(encounter.order.first(where: {
                $0.persistentPartyMemberID != nil
            }))
            let otherActors = encounter.order.filter { $0 != owner && $0 != .foe(apex.id) }
            let canonicalOrder = Array(otherActors.prefix(1)) + [.foe(apex.id), owner]
                + Array(otherActors.dropFirst())
            encounter.order = canonicalOrder
            encounter.turnSlots = CombatRules.turnSlots(
                order: canonicalOrder, foes: encounter.foes,
                apexActionSlots: [apex.id: preview.apexActionSlots], ordinaryPressureSlots: 0)
            encounter.turnIndex = 0
            var owned = encounter.debugV2OwnedNodeIDs ?? [:]
            owned[owner, default: []].insert("combat.offense.swiftness.cascade")
            encounter.debugV2OwnedNodeIDs = owned
            encounter.debugV2Initiative = .init(entries: canonicalOrder.enumerated().map { index, actor in
                .init(actor: actor, baseline: actor == owner ? 90 : 80 - index,
                      components: [], total: actor == owner ? 90 : 80 - index,
                      strikesFirst: false, finalPosition: index + 1)
            })
            encounter.foes[0].currentHP = 1
            _ = CombatRules.applyFoeDamage(foeID: apex.id, amount: 1, sourceActor: owner,
                                            provenance: .direct, run: &run, encounter: &encounter)
        }
        run.activeEncounter = encounter; state.worlds.activeRun = run
        return state
    }

    func testCurrentEncounterIdentityShapeRawRejectionIsBytePreserving() throws {
        let valid = try SaveCodec.encode(currentEncounterState())
        XCTAssertNoThrow(try Migrations.migrateIfNeeded(valid))
        let mutations: [(String, (inout [String: Any]) -> Void)] = [
            ("missing foes", { $0.removeValue(forKey: "foes") }),
            ("empty foes", { $0["foes"] = [] }),
            ("missing names", { $0.removeValue(forKey: "partyNames") }),
            ("missing order", { $0.removeValue(forKey: "order") }),
            ("empty slots", { $0["turnSlots"] = [] }),
            ("missing gear projection", { $0.removeValue(forKey: "gearProjections") })
        ]
        for (name, mutation) in mutations {
            let bytes = try mutatingActiveEncounter(in: valid, mutation)
            let original = bytes
            XCTAssertThrowsError(try Migrations.migrateIfNeeded(bytes), name)
            XCTAssertEqual(bytes, original, name)
        }
    }

    func testCurrentEncounterTurnSlotAuthorityRawRejectionIsBytePreserving() throws {
        let valid = try currentApexEncounterState()
        XCTAssertTrue(EncounterSnapshotRulesV1.validatesAll(in: valid))
        XCTAssertNoThrow(try Migrations.migrateIfNeeded(SaveCodec.encode(valid)))
        let apexID = try XCTUnwrap(valid.worlds.activeRun?.activeEncounter?.foes.first?.id)
        let mutations: [(String, (inout EncounterState) -> Void)] = [
            ("missing follow-up", { $0.turnSlots.removeAll { $0.kind != .primary } }),
            ("party follow-up", { $0.turnSlots.append(.init(actor: .binder,
                kind: .apexFollowUp(2), strengthMultiplier: 0.60, suppressesAfflictions: true)) }),
            ("wrong apex identity", { $0.turnSlots[$0.turnSlots.count - 1].actor =
                .foe(.init(rawValue: 999_992)) }),
            ("wrong ordinal", { $0.turnSlots[$0.turnSlots.count - 1].kind = .apexFollowUp(3) }),
            ("wrong multiplier", { $0.turnSlots[$0.turnSlots.count - 1].strengthMultiplier = 99 }),
            ("wrong suppression", { $0.turnSlots[$0.turnSlots.count - 1].suppressesAfflictions = false }),
            ("follow-up before primary", {
                let followUp = $0.turnSlots.removeLast()
                $0.turnSlots.insert(followUp, at: 0)
            }),
            ("duplicate follow-up", { $0.turnSlots.append(.init(actor: .foe(apexID),
                kind: .apexFollowUp(2), strengthMultiplier: 0.60, suppressesAfflictions: true)) })
        ]
        for (name, mutation) in mutations {
            var invalid = valid
            var encounter = try XCTUnwrap(invalid.worlds.activeRun?.activeEncounter)
            mutation(&encounter)
            invalid.worlds.activeRun?.activeEncounter = encounter
            let bytes = try SaveCodec.encode(invalid)
            let original = bytes
            XCTAssertThrowsError(try Migrations.migrateIfNeeded(bytes), name)
            XCTAssertEqual(bytes, original, name)
        }

        var ordinary = try currentEncounterState()
        let ordinaryID = try XCTUnwrap(ordinary.worlds.activeRun?.activeEncounter?.foes.first?.id)
        ordinary.worlds.activeRun?.activeEncounter?.turnSlots.append(.init(
            actor: .foe(ordinaryID), kind: .apexFollowUp(2),
            strengthMultiplier: 0.60, suppressesAfflictions: true))
        let ordinaryBytes = try SaveCodec.encode(ordinary)
        XCTAssertThrowsError(try Migrations.migrateIfNeeded(ordinaryBytes))

        var pressure = try currentPressureEncounterState()
        var pressureEncounter = try XCTUnwrap(pressure.worlds.activeRun?.activeEncounter)
        let secondOwner = try XCTUnwrap(pressureEncounter.turnSlots.first(where: {
            $0.kind == .ordinaryPressureFollowUp(2)
        })?.actor)
        let firstIndex = try XCTUnwrap(pressureEncounter.turnSlots.firstIndex(where: {
            $0.kind == .ordinaryPressureFollowUp(1)
        }))
        pressureEncounter.turnSlots[firstIndex].actor = secondOwner
        pressure.worlds.activeRun?.activeEncounter = pressureEncounter
        let pressureBytes = try SaveCodec.encode(pressure)
        let pressureOriginal = pressureBytes
        XCTAssertThrowsError(try Migrations.migrateIfNeeded(pressureBytes))
        XCTAssertEqual(pressureBytes, pressureOriginal)
    }

    func testCurrentEncounterLiveCascadeAndStaggerRawRoundTrip() throws {
        for state in [try dynamicallyReorderedApexState(staggered: false),
                      try dynamicallyReorderedApexState(staggered: true)] {
            XCTAssertTrue(EncounterSnapshotRulesV1.validatesAll(in: state))
            let bytes = try SaveCodec.encode(state)
            let migrated = try Migrations.migrateIfNeeded(bytes)
            let resumed = try SaveCodec.decode(migrated)
            XCTAssertEqual(resumed.worlds.activeRun?.activeEncounter?.turnSlots,
                           state.worlds.activeRun?.activeEncounter?.turnSlots)
            XCTAssertEqual(resumed.worlds.activeRun?.activeEncounter?.order,
                           state.worlds.activeRun?.activeEncounter?.order)
            var direct = try SaveCodec.decode(migrated)
            var relaunched = try SaveCodec.decode(migrated)
            CombatRules.runAutomaticTurns(in: &direct)
            CombatRules.runAutomaticTurns(in: &relaunched)
            XCTAssertEqual(relaunched.worlds.activeRun, direct.worlds.activeRun)
        }
    }

    func testSchema20EncounterPressureOwnersMigrateFromExactSlotsAndCurrentRejectsMalformed() throws {
        var legacy = try currentPressureEncounterState(foeCount: 1)
        legacy.schemaVersion = 20
        legacy.worlds.activeRun?.activeEncounter?.pressureOwners = nil
        let migratedBytes = try Migrations.migrateIfNeeded(SaveCodec.encode(legacy))
        let migrated = try SaveCodec.decode(migratedBytes)
        XCTAssertEqual(migrated.schemaVersion, 21)
        let receipt = try XCTUnwrap(migrated.worlds.activeRun?.activeEncounter?.pressureOwners)
        XCTAssertEqual(receipt.entries.map(\.ordinal), [1, 2])
        XCTAssertEqual(Set(receipt.entries.map(\.foeID)).count, 1)
        XCTAssertEqual(receipt.entries.map(\.foeID), migrated.worlds.activeRun?.activeEncounter?
            .turnSlots.compactMap { slot in
                guard case .ordinaryPressureFollowUp = slot.kind else { return nil }
                return slot.actor.foeID
            })
        XCTAssertEqual(try Migrations.migrateIfNeeded(migratedBytes), migratedBytes)

        let current = try SaveCodec.encode(migrated)
        let malformed: [(String, (inout [String: Any]) -> Void)] = [
            ("missing", { $0.removeValue(forKey: "pressureOwners") }),
            ("null", { $0["pressureOwners"] = NSNull() }),
            ("future", { var r = $0["pressureOwners"] as! [String: Any]; r["version"] = 2; $0["pressureOwners"] = r }),
            ("empty", { var r = $0["pressureOwners"] as! [String: Any]; r["entries"] = []; $0["pressureOwners"] = r }),
            ("duplicate ordinal", { var r = $0["pressureOwners"] as! [String: Any]; var e = r["entries"] as! [[String: Any]]; e[1]["ordinal"] = 1; r["entries"] = e; $0["pressureOwners"] = r }),
            ("wrong owner", { var r = $0["pressureOwners"] as! [String: Any]; var e = r["entries"] as! [[String: Any]]; e[0]["foeID"] = 999_999; r["entries"] = e; $0["pressureOwners"] = r })
        ]
        for (name, mutation) in malformed {
            let bytes = try mutatingActiveEncounter(in: current, mutation)
            XCTAssertThrowsError(try Migrations.migrateIfNeeded(bytes), name)
        }
    }

    @MainActor
    private func authoredStarterPromisedGearState() throws -> GameState {
        let store = GameStore(io: .temporary(name: "starter-promised-gear-\(UUID().uuidString)"))
        store.mutate("test: fund authored starter") { $0.base.essence = 1_000 }
        XCTAssertTrue(store.bindAndDepart(
            worldPageInstanceID: WorldPageCatalog.starterInstances[0].id))
        let expectedID = StarterKnownFindPlacementRules.stableInstanceID(
            for: try XCTUnwrap(store.activeRun?.book.worldPageUseReceipt))
        XCTAssertTrue(store.activeRun?.map.tiles.contains(where: {
            guard case .item(let stack) = $0.content else { return false }
            return stack.id == expectedID && stack.gearProfile?.stableInstanceID == expectedID
        }) == true)
        return store.state
    }

    private func mutatingFirstGameplayFacts(
        in data: Data, _ mutation: (inout [String: Any]) -> Void
    ) throws -> Data {
        var root = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        func mutate(_ value: Any) -> (Any, Bool) {
            if var array = value as? [Any] {
                for index in array.indices {
                    let result = mutate(array[index])
                    array[index] = result.0
                    if result.1 { return (array, true) }
                }
                return (array, false)
            }
            guard var object = value as? [String: Any] else { return (value, false) }
            if var profile = object["gearProfile"] as? [String: Any],
               var facts = profile["gameplayFacts"] as? [String: Any] {
                mutation(&facts)
                profile["gameplayFacts"] = facts
                object["gearProfile"] = profile
                return (object, true)
            }
            for key in object.keys.sorted() {
                let result = mutate(object[key] as Any)
                object[key] = result.0
                if result.1 { return (object, true) }
            }
            return (object, false)
        }
        let result = mutate(root)
        root = try XCTUnwrap(result.0 as? [String: Any])
        XCTAssertTrue(result.1)
        return try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys])
    }

    @MainActor
    func testAuthoredStarterPromisedGearOptionalFactsRoundTripAndRelaunch() throws {
        let state = try authoredStarterPromisedGearState()
        let bytes = try SaveCodec.encode(state)
        let root = try XCTUnwrap(JSONSerialization.jsonObject(with: bytes) as? [String: Any])
        var foundFacts: [String: Any]?
        func inspect(_ value: Any) {
            if let array = value as? [Any] { array.forEach(inspect); return }
            guard let object = value as? [String: Any] else { return }
            if let profile = object["gearProfile"] as? [String: Any],
               let facts = profile["gameplayFacts"] as? [String: Any] { foundFacts = facts }
            object.values.forEach(inspect)
        }
        inspect(root)
        let facts = try XCTUnwrap(foundFacts)
        XCTAssertNil(facts["specialRule"])
        XCTAssertNil(facts["toolCapability"])
        XCTAssertNil(facts["initiativeModifier"])
        XCTAssertNil(facts["heatWard"])
        XCTAssertNil(facts["valueModifier"])
        XCTAssertNil(facts["appliedContributionIDs"])
        let decoded = try SaveCodec.decode(bytes)
        let reencoded = try SaveCodec.encode(decoded)
        let redecode = try SaveCodec.decode(reencoded)
        XCTAssertEqual(redecode, decoded)

        let io = SaveFileIO.temporary(name: "starter-promised-relaunch-\(UUID().uuidString)")
        try io.write(reencoded)
        let relaunched = GameStore(io: io)
        XCTAssertEqual(relaunched.state, redecode)
        XCTAssertEqual(try Data(contentsOf: io.saveURL), reencoded)
    }

    @MainActor
    func testCurrentGearGameplayFactShapeRejectsMalformedRawBytesWithoutMutation() throws {
        let valid = try SaveCodec.encode(authoredStarterPromisedGearState())
        let mutations: [(String, (inout [String: Any]) -> Void)] = [
            ("omitted required", { $0.removeValue(forKey: "sourceRevisionDigest") }),
            ("wrong optional type", { $0["specialRule"] = 7 }),
            ("malformed optional payload", { $0["toolCapability"] = ["rank": 1] }),
            ("contradictory identity", { $0["stableGearID"] = ["rawValue": 9_999_991] }),
            ("partial contribution tuple", { $0["initiativeModifier"] = -1 })
        ]
        for (name, mutation) in mutations {
            let bytes = try mutatingFirstGameplayFacts(in: valid, mutation)
            let original = bytes
            XCTAssertThrowsError(try SaveCodec.decode(bytes), name)
            XCTAssertEqual(bytes, original, name)

            let io = SaveFileIO.temporary(name: "invalid-gear-facts-\(name)-\(UUID().uuidString)")
            try io.write(bytes)
            XCTAssertNil(io.load().state, name)
            XCTAssertEqual(try Data(contentsOf: io.saveURL), bytes, name)
        }
    }

    private func schemaNineteenEarthStateWithFrozenHistory() -> GameState {
        var state = GameState.newGame()
        state.schemaVersion = 19
        state.base.collectedWorldPages.append(LegacyDebugVisibilityWorldV19.instance)
        let receipt = WorldPageUseReceipt(
            instanceID: LegacyDebugVisibilityWorldV19.instanceID,
            definition: LegacyDebugVisibilityWorldV19.definition,
            essencePaid: 0)
        var book = BoundBook(written: ["plains"], essencePaid: 0)
        book.worldPageUseReceipt = receipt
        let generated = Worldgen.generate(book: book, seed: 20_019)
        let active = WorldRun(
            runIndex: 1, book: book, mapSeed: 20_019, rng: SeededRNG(seed: 20_019),
            map: generated.map, playerPosition: generated.start)
        var anchored = active
        anchored.runIndex = 2
        state.worlds.activeRun = active
        state.worlds.anchoredRealms = [
            AnchoredRealm(runIndex: 2, name: "Legacy Earth", route: .bornAnchored, world: anchored)
        ]
        state.reality.library.visitedWorlds = [VisitedWorld(
            id: InstanceID(rawValue: 20_019), seed: 20_019, runIndex: 1,
            descriptionSentence: "Frozen legacy world", written: ["plains"],
            inertModifiers: [], readings: [:], travellersPresent: [],
            worldPageUseReceipt: receipt)]
        return state
    }

    func testSchemaNineteenEarthEntitlementMigratesWithoutRewritingFrozenWorldReceipts() throws {
        let legacy = schemaNineteenEarthStateWithFrozenHistory()
        let source = try SaveCodec.encode(legacy)
        let migrated = try Migrations.migrateIfNeeded(source)
        let state = try SaveCodec.decode(migrated)
        XCTAssertEqual(state.schemaVersion, 20)
        XCTAssertEqual(state.base.collectedWorldPages, WorldPageCatalog.starterInstances)
        XCTAssertEqual(state.worlds.activeRun?.book.worldPageUseReceipt,
                       legacy.worlds.activeRun?.book.worldPageUseReceipt)
        XCTAssertEqual(state.worlds.anchoredRealms.first?.world.book.worldPageUseReceipt,
                       legacy.worlds.anchoredRealms.first?.world.book.worldPageUseReceipt)
        XCTAssertEqual(state.reality.library.visitedWorlds.first?.worldPageUseReceipt,
                       legacy.reality.library.visitedWorlds.first?.worldPageUseReceipt)
        XCTAssertEqual(try Migrations.migrateIfNeeded(migrated), migrated)

        var absent = GameState.newGame()
        absent.schemaVersion = 19
        let seedsBefore = absent.worlds.seeds
        let absentMigrated = try Migrations.migrateIfNeeded(SaveCodec.encode(absent))
        let absentState = try SaveCodec.decode(absentMigrated)
        XCTAssertEqual(absentState.schemaVersion, 20)
        XCTAssertEqual(absentState.base.collectedWorldPages, WorldPageCatalog.starterInstances)
        XCTAssertEqual(absentState.worlds.seeds, seedsBefore)
    }

    func testSchemaNineteenEarthAliasDuplicateAndTamperingFailWithoutChangingRawBytes() throws {
        let valid = try SaveCodec.encode(schemaNineteenEarthStateWithFrozenHistory())
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
                definition["title"] = "Not the frozen fixture"
                $0[$0.count - 1]["definition"] = definition
            })
        ]
        for (name, mutation) in mutations {
            var root = try XCTUnwrap(JSONSerialization.jsonObject(with: valid) as? [String: Any])
            var base = try XCTUnwrap(root["base"] as? [String: Any])
            var pages = try XCTUnwrap(base["collectedWorldPages"] as? [[String: Any]])
            mutation(&pages)
            base["collectedWorldPages"] = pages; root["base"] = base
            let bytes = try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys])
            let original = bytes
            XCTAssertThrowsError(try Migrations.migrateIfNeeded(bytes), name)
            XCTAssertEqual(bytes, original, name)
        }
    }

    func testCurrentSchemaRejectsReintroducedEarthEntitlement() throws {
        var state = GameState.newGame()
        state.base.collectedWorldPages.append(LegacyDebugVisibilityWorldV19.instance)
        let bytes = try SaveCodec.encode(state)
        XCTAssertThrowsError(try Migrations.migrateIfNeeded(bytes))
        XCTAssertThrowsError(try SaveCodec.makeDecoder().decode(GameState.self, from: bytes))
    }

    private func currentRosterPlacementState() -> GameState {
        var state = GameState.newGame()
        var keeper = CompanionState()
        keeper.name = "Halloway"
        keeper.traveller = "halloway"
        keeper.persistentID = .traveller("halloway")
        state.base.roster.append(keeper)
        let book = BoundBook(written: [], essencePaid: 0)
        let generated = Worldgen.generate(book: book, seed: 91)
        let run = WorldRun(runIndex: 91, book: book, mapSeed: 91,
                           rng: SeededRNG(seed: 91), map: generated.map,
                           playerPosition: generated.start)
        state.worlds.anchoredRealms = [
            AnchoredRealm(runIndex: 91, name: "Roster validation", route: .bornAnchored,
                          assignedCompanions: [.traveller("halloway")], world: run)
        ]
        GameStore.recalculateAnchorProduction(in: &state)
        return state
    }

    private func activeAnimalState() throws -> GameState {
        var state = currentRosterPlacementState()
        var generatedMember = CompanionState()
        generatedMember.name = "Generated person"
        generatedMember.persistentID = .generated("raw-positive")
        state.base.roster.append(generatedMember)
        let enemyID = InstanceID(rawValue: 90_501)
        let seed: UInt64 = 90_001
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
            animal: animal, displayName: "Stable animal", icon: "questionmark",
            level: 1, provenance: .legacySchema14LevelOne))
        state.reality.animalTrustRecords[trust.key] = trust
        state.reality.tamedAnimals[rawID] = animal
        state.base.tamedAnimalCompanions[id] = .init(
            id: id, originReceipt: receipt, level: 1, experience: 0,
            gambits: [], posting: .activeParty)
        state.base.activeParty.append(.animal(rawID))
        return state
    }

    private func assertQuarantinedSavePreserves(_ bytes: Data, io: SaveFileIO,
                                                file: StaticString = #filePath,
                                                line: UInt = #line) throws {
        let quarantined = try XCTUnwrap(FileManager.default.contentsOfDirectory(
            at: io.directory, includingPropertiesForKeys: nil).first {
                $0.lastPathComponent.hasPrefix(io.fileName + ".corrupt-")
            }, file: file, line: line)
        XCTAssertEqual(try Data(contentsOf: quarantined), bytes, file: file, line: line)
    }

    func testCurrentRosterPlacementCorruptionRejectsRawBytesWithoutMutation() throws {
        let validBytes = try SaveCodec.encode(currentRosterPlacementState())
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
            var root = try XCTUnwrap(JSONSerialization.jsonObject(
                with: validBytes) as? [String: Any])
            try mutation(&root)
            let bytes = try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys])
            let original = bytes
            XCTAssertThrowsError(try SaveCodec.decode(bytes), name)
            XCTAssertEqual(bytes, original, name)
        }
    }

    func testCurrentActiveTamedAnimalStableIdentityRawRoundTrip() throws {
        let state = try activeAnimalState()
        let bytes = try SaveCodec.encode(state)
        let decoded = try SaveCodec.decode(bytes)
        XCTAssertEqual(decoded, state)
        XCTAssertEqual(decoded.base.activeParty.last, state.base.activeParty.last)
        XCTAssertTrue(decoded.validatesAnimalCompanionCombat())
        XCTAssertEqual(try SaveCodec.decode(SaveCodec.encode(decoded)), decoded)
    }

    func testCurioKnowledgeSchemaTwelveMigrationStartsEmptyWithoutBackwardInference() throws {
        var root = try XCTUnwrap(JSONSerialization.jsonObject(
            with: SaveCodec.encode(.newGame())) as? [String: Any])
        root["schemaVersion"] = 12
        var reality = try XCTUnwrap(root["reality"] as? [String: Any])
        reality.removeValue(forKey: "curioFamilyKnowledge")
        reality.removeValue(forKey: "animalTrustRecords")
        reality.removeValue(forKey: "tamedAnimals")
        root["reality"] = reality
        let legacy = try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys])

        let migrated = try SaveCodec.decode(legacy)
        XCTAssertEqual(migrated.schemaVersion, Tuning.saveSchemaVersion)
        XCTAssertTrue(migrated.reality.curioFamilyKnowledge.isEmpty)
        XCTAssertTrue(migrated.reality.animalTrustRecords.isEmpty)
        XCTAssertTrue(migrated.reality.tamedAnimals.isEmpty)
        XCTAssertEqual(try SaveCodec.decode(SaveCodec.encode(migrated)), migrated)
    }

    func testAnimalTrustSchemaThirteenMigrationStartsEmptyAndIsIdempotent() throws {
        var root = try XCTUnwrap(JSONSerialization.jsonObject(
            with: SaveCodec.encode(.newGame())) as? [String: Any])
        root["schemaVersion"] = 13
        var reality = try XCTUnwrap(root["reality"] as? [String: Any])
        reality.removeValue(forKey: "animalTrustRecords")
        reality.removeValue(forKey: "tamedAnimals")
        root["reality"] = reality
        let legacy = try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys])

        let migrated = try SaveCodec.decode(legacy)
        XCTAssertEqual(migrated.schemaVersion, Tuning.saveSchemaVersion)
        XCTAssertTrue(migrated.reality.animalTrustRecords.isEmpty)
        XCTAssertTrue(migrated.reality.tamedAnimals.isEmpty)
        XCTAssertEqual(try SaveCodec.decode(SaveCodec.encode(migrated)), migrated)
    }

    func testCurrentAnimalTrustMalformedRawSavePreservesExactBytes() throws {
        for mutation in ["null", "future", "negative", "extra"] {
            var state = GameState.newGame()
            let record = RealityState.AnimalTrustRecordV1(
                worldSeed: 14, enemyID: .init(rawValue: 7), speciesID: nil,
                creatureID: nil, traits: CreatureTraits(),
                condition: .patientPresence(requiredTurns: 2), progress: 0,
                firstAttendedRunIndex: 1, firstAttendedTurn: 0,
                lastProgressTurn: nil, interactionCount: 1, completed: false)
            state.reality.animalTrustRecords[record.key] = record
            var root = try XCTUnwrap(JSONSerialization.jsonObject(with: SaveCodec.encode(state))
                                      as? [String: Any])
            var reality = try XCTUnwrap(root["reality"] as? [String: Any])
            if mutation == "null" {
                reality["animalTrustRecords"] = NSNull()
            } else {
                var records = try XCTUnwrap(reality["animalTrustRecords"] as? [String: Any])
                var receipt = try XCTUnwrap(records[record.key] as? [String: Any])
                switch mutation {
                case "future": receipt["version"] = 2
                case "negative": receipt["progress"] = -1
                default: receipt["unexpected"] = true
                }
                records[record.key] = receipt
                reality["animalTrustRecords"] = records
            }
            root["reality"] = reality
            let bytes = try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys])
            let io = SaveFileIO.temporary(name: "animal-trust-\(mutation)-\(UUID().uuidString)")
            try io.write(bytes)
            guard case .unrecoverable = io.load() else { return XCTFail("expected \(mutation) failure") }
            try assertQuarantinedSavePreserves(bytes, io: io)
        }
    }

    func testCurrentCurioKnowledgeMalformedRawSavePreservesExactBytes() throws {
        for mutation in ["null", "future", "negative", "wrong-target", "wrong-recognition"] {
            var state = GameState.newGame()
            state.reality.curioFamilyKnowledge["curio_humming_shard"] = .init(
                familyID: "curio_humming_shard", revealedItemID: "salve_lesser",
                observationCount: 1, firstResolutionRunIndex: 0, isRecognized: false)
            var root = try XCTUnwrap(JSONSerialization.jsonObject(with: SaveCodec.encode(state))
                                      as? [String: Any])
            var reality = try XCTUnwrap(root["reality"] as? [String: Any])
            if mutation == "null" {
                reality["curioFamilyKnowledge"] = NSNull()
            } else {
                var knowledge = try XCTUnwrap(reality["curioFamilyKnowledge"] as? [String: Any])
                var receipt = try XCTUnwrap(knowledge["curio_humming_shard"] as? [String: Any])
                switch mutation {
                case "future": receipt["version"] = 2
                case "negative": receipt["observationCount"] = -1
                case "wrong-target": receipt["revealedItemID"] = "cache_key"
                default: receipt["isRecognized"] = true
                }
                knowledge["curio_humming_shard"] = receipt
                reality["curioFamilyKnowledge"] = knowledge
            }
            root["reality"] = reality
            let bytes = try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys])
            let io = SaveFileIO.temporary(name: "curio-knowledge-\(mutation)-\(UUID().uuidString)")
            try io.write(bytes)
            guard case .unrecoverable = io.load() else { return XCTFail("expected \(mutation) failure") }
            try assertQuarantinedSavePreserves(bytes, io: io)
        }
    }

    func testCurrentRecognizedCurioCannotPersistAsUnidentifiedOwnedCopy() throws {
        var state = GameState.newGame()
        state.reality.curioFamilyKnowledge["curio_humming_shard"] = .init(
            familyID: "curio_humming_shard", revealedItemID: "salve_lesser",
            observationCount: 2, firstResolutionRunIndex: 0, isRecognized: true)
        state.base.inventory.stacks = [.init(id: .init(rawValue: 73_001),
            catalogID: "curio_humming_shard", identified: false)]
        let bytes = try SaveCodec.encode(state)
        let io = SaveFileIO.temporary(name: "curio-recognized-unknown-\(UUID().uuidString)")
        try io.write(bytes)
        guard case .unrecoverable = io.load() else { return XCTFail("expected invariant failure") }
        try assertQuarantinedSavePreserves(bytes, io: io)
    }

    func testRecoveredTeachingSchemaElevenMigrationPreservesLegacyRewardAsReadReceipt() throws {
        var state = GameState.newGame()
        state.base.completedResearch.insert("study_starlight")
        state.base.ownedSources.insert("stars")
        state.worlds.outcomeSequence = 1
        XCTAssertTrue(state.worlds.appendExpeditionReview(.init(
            runIndex: 1, outcomeID: 1, kind: .portal, reason: "schema eleven queue",
            turnsTaken: 4, haulKeptFraction: 1)))
        let frozenQueue = state.worlds.expeditionReviewQueue
        var root = try XCTUnwrap(JSONSerialization.jsonObject(with: SaveCodec.encode(state))
                                  as? [String: Any])
        root["schemaVersion"] = 11
        var reality = try XCTUnwrap(root["reality"] as? [String: Any])
        var library = try XCTUnwrap(reality["library"] as? [String: Any])
        library.removeValue(forKey: "recoveredTeachings")
        library.removeValue(forKey: "recoveredTeachingOffers")
        library.removeValue(forKey: "nextRecoveredTeachingSequence")
        reality["library"] = library; root["reality"] = reality
        let legacy = try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys])

        let migrated = try SaveCodec.decode(legacy)
        let record = try XCTUnwrap(migrated.reality.library.recoveredTeachings.first {
            $0.teachingID == "teaching.focus.stars"
        })
        XCTAssertTrue(record.isRead)
        XCTAssertEqual(record.sourcePlacementIdentity, "migration:completed-research")
        XCTAssertTrue(migrated.base.ownedSources.contains("stars"))
        XCTAssertEqual(migrated.worlds.expeditionReviewQueue, frozenQueue)
        XCTAssertEqual(try SaveCodec.decode(SaveCodec.encode(migrated)), migrated)
    }

    func testCurrentRecoveredTeachingNullFailsRawLoadWithoutRewritingBytes() throws {
        var root = try XCTUnwrap(JSONSerialization.jsonObject(
            with: SaveCodec.encode(.newGame())) as? [String: Any])
        var reality = try XCTUnwrap(root["reality"] as? [String: Any])
        var library = try XCTUnwrap(reality["library"] as? [String: Any])
        library["recoveredTeachings"] = NSNull()
        reality["library"] = library; root["reality"] = reality
        let bytes = try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys])
        let io = SaveFileIO.temporary(name: "teaching-null-\(UUID().uuidString)")
        try io.write(bytes)
        guard case .unrecoverable = io.load() else { return XCTFail("expected strict failure") }
        try assertQuarantinedSavePreserves(bytes, io: io)
    }

    func testCurrentRecoveredTeachingExpeditionNullFailsRawLoadWithoutRewritingBytes() throws {
        var state = GameState.newGame()
        state.worlds.activeRun = WorldRun(
            runIndex: 1, book: .init(symbols: [:], randomlyFilled: [], essencePaid: 0),
            mapSeed: 71, rng: .init(seed: 71),
            map: .init(width: 1, height: 1, tiles: [Tile()], entry: .init(x: 0, y: 0)),
            playerPosition: .init(x: 0, y: 0))
        var root = try XCTUnwrap(JSONSerialization.jsonObject(
            with: SaveCodec.encode(state)) as? [String: Any])
        var worlds = try XCTUnwrap(root["worlds"] as? [String: Any])
        var run = try XCTUnwrap(worlds["activeRun"] as? [String: Any])
        run["recoveredTeachingExpedition"] = NSNull()
        worlds["activeRun"] = run; root["worlds"] = worlds
        let bytes = try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys])
        let io = SaveFileIO.temporary(name: "teaching-expedition-null-\(UUID().uuidString)")
        try io.write(bytes)
        guard case .unrecoverable = io.load() else { return XCTFail("expected strict failure") }
        try assertQuarantinedSavePreserves(bytes, io: io)
    }

    func testCurrentRecoveredTeachingCrossFieldMismatchFailsRawLoadWithoutRewritingBytes() throws {
        for mutation in ["missing-state", "not-due"] {
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
            var root = try XCTUnwrap(JSONSerialization.jsonObject(with: SaveCodec.encode(state))
                                      as? [String: Any])
            var worlds = try XCTUnwrap(root["worlds"] as? [String: Any])
            var active = try XCTUnwrap(worlds["activeRun"] as? [String: Any])
            var receipt = try XCTUnwrap(active["recoveredTeachingExpedition"] as? [String: Any])
            var states = try XCTUnwrap(receipt["resultingOfferStates"] as? [[String: Any]])
            if mutation == "missing-state" { states[0]["teachingID"] = "teaching.focus.mist" }
            else { states[0]["isDue"] = false }
            receipt["resultingOfferStates"] = states
            active["recoveredTeachingExpedition"] = receipt; worlds["activeRun"] = active
            root["worlds"] = worlds
            let bytes = try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys])
            let io = SaveFileIO.temporary(name: "teaching-cross-field-\(mutation)-\(UUID().uuidString)")
            try io.write(bytes)
            guard case .unrecoverable = io.load() else { return XCTFail("expected strict failure") }
            try assertQuarantinedSavePreserves(bytes, io: io)
        }
    }

    func testCurrentRecoveredTeachingInvalidNonSelectedOfferFailsRawLoadWithoutRewritingBytes() throws {
        for mutation in ["future-version", "negative-counter"] {
            var state = GameState.newGame()
            var tile = Tile()
            tile.content = .recoveredTeaching("teaching.focus.stars")
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
            var root = try XCTUnwrap(JSONSerialization.jsonObject(with: SaveCodec.encode(state))
                                      as? [String: Any])
            var worlds = try XCTUnwrap(root["worlds"] as? [String: Any])
            var active = try XCTUnwrap(worlds["activeRun"] as? [String: Any])
            var receipt = try XCTUnwrap(active["recoveredTeachingExpedition"] as? [String: Any])
            var states = try XCTUnwrap(receipt["resultingOfferStates"] as? [[String: Any]])
            if mutation == "future-version" { states[1]["version"] = 2 }
            else { states[1]["eligibleWorldsWithoutOffer"] = -1 }
            receipt["resultingOfferStates"] = states
            active["recoveredTeachingExpedition"] = receipt; worlds["activeRun"] = active
            root["worlds"] = worlds
            let bytes = try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys])
            let io = SaveFileIO.temporary(name: "teaching-nonselected-\(mutation)-\(UUID().uuidString)")
            try io.write(bytes)
            guard case .unrecoverable = io.load() else { return XCTFail("expected strict failure") }
            try assertQuarantinedSavePreserves(bytes, io: io)
        }
    }

    func testCurrentRecoveredTeachingReceiptMapMismatchFailsRawLoadWithoutRewritingBytes() throws {
        for mutation in ["out-of-bounds", "wrong-tile", "wrong-identity", "orphan-tile"] {
            var state = GameState.newGame()
            var tile = Tile()
            tile.content = .recoveredTeaching("teaching.focus.stars")
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
            var root = try XCTUnwrap(JSONSerialization.jsonObject(with: SaveCodec.encode(state))
                                      as? [String: Any])
            var worlds = try XCTUnwrap(root["worlds"] as? [String: Any])
            var active = try XCTUnwrap(worlds["activeRun"] as? [String: Any])
            if mutation == "out-of-bounds" {
                var receipt = try XCTUnwrap(active["recoveredTeachingExpedition"] as? [String: Any])
                receipt["placement"] = ["x": 2, "y": 0]
                active["recoveredTeachingExpedition"] = receipt
            } else if mutation == "orphan-tile" {
                active.removeValue(forKey: "recoveredTeachingExpedition")
            } else {
                var map = try XCTUnwrap(active["map"] as? [String: Any])
                var tiles = try XCTUnwrap(map["tiles"] as? [[String: Any]])
                var content = try XCTUnwrap(tiles[0]["content"] as? [String: Any])
                if mutation == "wrong-tile" { content = ["empty": [:]] }
                else { content = ["recoveredTeaching": ["_0": "teaching.focus.mist"]] }
                tiles[0]["content"] = content; map["tiles"] = tiles; active["map"] = map
            }
            worlds["activeRun"] = active; root["worlds"] = worlds
            let bytes = try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys])
            let io = SaveFileIO.temporary(name: "teaching-map-\(mutation)-\(UUID().uuidString)")
            try io.write(bytes)
            guard case .unrecoverable = io.load() else { return XCTFail("expected \(mutation) failure") }
            try assertQuarantinedSavePreserves(bytes, io: io)
        }
    }

    func testCurrentSeamwardNullFailsRawLoadWithoutRewritingBytes() throws {
        var state = GameState.newGame()
        var run = WorldRun(
            runIndex: 1, book: .init(symbols: [:], randomlyFilled: [], essencePaid: 0),
            mapSeed: 1, rng: .init(seed: 1),
            map: .init(width: 1, height: 1,
                       tiles: [Tile(content: .portal(isEntry: true), ground: .soil)],
                       entry: .init(x: 0, y: 0)),
            playerPosition: .init(x: 0, y: 0))
        run.seamwardExpedition = .init(contributors: [
            .init(member: .binder, gearStableInstanceID: .init(rawValue: 70), slot: .armor,
                  definitionID: "seamward", rulesVersion: 1, inkRecipe: nil)
        ], activatedOnTurn: 0)
        state.worlds.activeRun = run
        var root = try XCTUnwrap(JSONSerialization.jsonObject(
            with: SaveCodec.encode(state)) as? [String: Any])
        var worlds = try XCTUnwrap(root["worlds"] as? [String: Any])
        var active = try XCTUnwrap(worlds["activeRun"] as? [String: Any])
        var receipt = try XCTUnwrap(active["seamwardExpedition"] as? [String: Any])
        receipt["activatedOnTurn"] = NSNull()
        active["seamwardExpedition"] = receipt
        worlds["activeRun"] = active
        root["worlds"] = worlds
        let bytes = try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys])
        let io = SaveFileIO.temporary(name: "seamward-null-\(UUID().uuidString)")
        try io.write(bytes)

        guard case .unrecoverable = io.load() else { return XCTFail("expected strict failure") }
        XCTAssertEqual(try Data(contentsOf: io.saveURL), bytes)
    }

    func testChannelworksSchemaEightMigrationAndCurrentReceiptFailClosed() throws {
        var state = GameState.newGame()
        state.base.stations[Stations.channelworks] = .init(isUnlocked: true, tier: 0)
        var root = try XCTUnwrap(JSONSerialization.jsonObject(with: SaveCodec.encode(state))
                                  as? [String: Any])
        root["schemaVersion"] = 8
        var base = try XCTUnwrap(root["base"] as? [String: Any])
        base.removeValue(forKey: "channelworksRestoration")
        base["odaFixtureRestored"] = false
        root["base"] = base
        let legacy = try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys])
        let migrated = try SaveCodec.decode(legacy)
        XCTAssertEqual(migrated.schemaVersion, Tuning.saveSchemaVersion)
        XCTAssertNotNil(migrated.base.channelworksRestoration?.fixtureInstanceID)
        XCTAssertEqual(migrated.base.channelworksRestoration?.fixtureCore,
                       ChannelworksRestorationRules.authoredCore)
        XCTAssertEqual(try SaveCodec.decode(SaveCodec.encode(migrated)), migrated)

        for invalid: Any in [NSNull(), "yes"] {
            base["odaFixtureRestored"] = invalid; root["base"] = base
            let bytes = try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys])
            let original = bytes
            XCTAssertThrowsError(try SaveCodec.decode(bytes))
            XCTAssertEqual(bytes, original)
        }

        var current = try XCTUnwrap(JSONSerialization.jsonObject(with: SaveCodec.encode(migrated))
                                     as? [String: Any])
        var currentBase = try XCTUnwrap(current["base"] as? [String: Any])
        currentBase["channelworksRestoration"] = NSNull(); current["base"] = currentBase
        let nullCurrent = try JSONSerialization.data(withJSONObject: current, options: [.sortedKeys])
        XCTAssertThrowsError(try SaveCodec.decode(nullCurrent))
    }


    func testSchemaFourCombatOpeningMigrationFreezesOwnershipChoiceAndRefundsUnknownDepth() throws {
        let legacy = Data(#"{"schemaVersion":4,"character":{"level":4,"branchDepth":{"kindling":2,"retired":3},"freePoints":1}}"#.utf8)
        let migrated = try Migrations.migrateIfNeeded(legacy)
        let root = try XCTUnwrap(JSONSerialization.jsonObject(with: migrated) as? [String: Any])
        let character = try XCTUnwrap(root["character"] as? [String: Any])
        XCTAssertNil(character["branchDepth"])
        XCTAssertNil(character["freePoints"])
        XCTAssertEqual(character["ownedCombatNodeIDs"] as? [String], [
            "combat.craft.emanation.insulation", "combat.craft.emanation.sparkhand",
        ])
        XCTAssertEqual(character["unspentCombatPoints"] as? Int, 3)
        XCTAssertEqual((character["combatNodeChoices"] as? [String: String])?[
            "combat.craft.emanation.insulation"], "heat")
        XCTAssertEqual(try Migrations.migrateIfNeeded(migrated), migrated)
    }

    func testSchemaFourCombatOpeningMigrationRejectsMalformedLegacyAndCanonicalValues() {
        let fixtures = [
            #"{"schemaVersion":4,"character":{"level":4,"branchDepth":{"force":true}}}"#,
            #"{"schemaVersion":4,"character":{"level":4,"branchDepth":{"force":1.5}}}"#,
            #"{"schemaVersion":4,"character":{"level":4,"ownedCombatNodeIDs":null}}"#,
            #"{"schemaVersion":4,"character":{"level":4,"ownedCombatNodeIDs":[],"combatNodeChoices":null}}"#,
            #"{"schemaVersion":4,"character":{"level":4,"ownedCombatNodeIDs":[],"unspentCombatPoints":-1}}"#,
        ]
        for fixture in fixtures {
            XCTAssertThrowsError(try Migrations.migrateIfNeeded(Data(fixture.utf8)), fixture)
        }
    }

    func testCurrentCombatOwnershipRequiresCanonicalFieldsAndExactImplementedMembership() throws {
        let valid = Data(#"{"schemaVersion":7,"character":{"ownedCombatNodeIDs":[],"combatNodeChoices":{},"unspentCombatPoints":0}}"#.utf8)
        XCTAssertEqual(try Migrations.migrateIfNeeded(valid), valid)
        let fortitude = Data(#"{"schemaVersion":7,"character":{"ownedCombatNodeIDs":["combat.defense.fortitude.thick_hide","combat.defense.fortitude.iron_skin","combat.defense.fortitude.brace","combat.defense.fortitude.constitution","combat.defense.fortitude.endurance","combat.defense.fortitude.ward","combat.defense.fortitude.unyielding","combat.defense.fortitude.immovable"],"combatNodeChoices":{},"unspentCombatPoints":0}}"#.utf8)
        XCTAssertEqual(try Migrations.migrateIfNeeded(fortitude), fortitude)
        let malformed = [
            #"{"schemaVersion":7,"character":{"combatNodeChoices":{},"unspentCombatPoints":0}}"#,
            #"{"schemaVersion":7,"character":{"ownedCombatNodeIDs":[],"unspentCombatPoints":0}}"#,
            #"{"schemaVersion":7,"character":{"ownedCombatNodeIDs":[],"combatNodeChoices":{}}}"#,
            #"{"schemaVersion":7,"character":{"ownedCombatNodeIDs":null,"combatNodeChoices":{},"unspentCombatPoints":0}}"#,
            #"{"schemaVersion":7,"character":{"ownedCombatNodeIDs":["combat.offense.force.heavy_hand","combat.offense.force.heavy_hand"],"combatNodeChoices":{},"unspentCombatPoints":0}}"#,
            #"{"schemaVersion":7,"character":{"ownedCombatNodeIDs":["combat.offense.force.shatter"],"combatNodeChoices":{},"unspentCombatPoints":0}}"#,
            #"{"schemaVersion":7,"character":{"ownedCombatNodeIDs":["unknown"],"combatNodeChoices":{},"unspentCombatPoints":0}}"#,
            #"{"schemaVersion":7,"character":{"ownedCombatNodeIDs":["combat.craft.emanation.insulation"],"combatNodeChoices":{},"unspentCombatPoints":0}}"#,
        ]
        for fixture in malformed {
            let bytes = Data(fixture.utf8)
            let original = bytes
            XCTAssertThrowsError(try Migrations.migrateIfNeeded(bytes), fixture)
            XCTAssertEqual(bytes, original)
        }
    }

    func testElementalRenameTouchesOnlyTypedSkillOwners() throws {
        let legacy = Data(#"{"schemaVersion":4,"note":"elemental_strike","skillID":"elemental_strike","character":{"level":1,"branchDepth":{},"freePoints":0}}"#.utf8)
        let migrated = try Migrations.migrateIfNeeded(legacy)
        let root = try XCTUnwrap(JSONSerialization.jsonObject(with: migrated) as? [String: Any])
        XCTAssertEqual(root["note"] as? String, "elemental_strike")
        XCTAssertEqual(root["skillID"] as? String, "emanation_strike")
    }

    func testB111ASchemaTenReviewMigrationPreservesCompleteCurrentSummaryAndIdentity() throws {
        func summary(_ outcomeID: ExpeditionOutcomeID?) -> RunExitSummary {
            RunExitSummary(runIndex: 17, outcomeID: outcomeID, kind: .defeat,
                           reason: "frozen review", departureState: .breaking,
                           turnsTaken: 19, haulKeptFraction: 0.5,
                           recoveredLines: [.resource(.init(
                            lineID: "ore", id: "ore", quantity: 3,
                            fallbackName: "Ore", fallbackIcon: "cube"))])
        }
        func legacyData(_ receipt: RunExitSummary?) throws -> Data {
            var root = try XCTUnwrap(JSONSerialization.jsonObject(
                with: SaveCodec.encode(GameState.newGame())) as? [String: Any])
            root["schemaVersion"] = 10
            var worlds = try XCTUnwrap(root["worlds"] as? [String: Any])
            worlds.removeValue(forKey: "expeditionReviewQueue")
            worlds["runIndex"] = 17
            worlds["outcomeSequence"] = 0
            if let receipt {
                var legacyReceipt = try XCTUnwrap(JSONSerialization.jsonObject(
                    with: SaveCodec.makeEncoder().encode(receipt)) as? [String: Any])
                legacyReceipt.removeValue(forKey: "custodyReceiptVersion")
                worlds["lastExit"] = legacyReceipt
            }
            root["worlds"] = worlds
            return try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys])
        }

        let empty = try SaveCodec.decode(legacyData(nil))
        XCTAssertTrue(empty.worlds.expeditionReviewQueue.pending.isEmpty)

        let genuine = summary(8)
        let migrated = try SaveCodec.decode(legacyData(genuine))
        XCTAssertEqual(migrated.worlds.outcomeSequence, 8)
        XCTAssertEqual(migrated.worlds.pendingExpeditionReview,
                       .init(reviewID: .outcome(8), summary: genuine))

        let legacy = summary(nil)
        let migratedLegacy = try SaveCodec.decode(legacyData(legacy))
        XCTAssertEqual(migratedLegacy.worlds.outcomeSequence, 0)
        XCTAssertEqual(migratedLegacy.worlds.pendingExpeditionReview,
                       .init(reviewID: .legacy("legacy-run-17"), summary: legacy))
        XCTAssertEqual(try SaveCodec.decode(SaveCodec.encode(migratedLegacy)), migratedLegacy)
        let encodedRoot = try XCTUnwrap(JSONSerialization.jsonObject(
            with: SaveCodec.encode(migratedLegacy)) as? [String: Any])
        let encodedWorlds = try XCTUnwrap(encodedRoot["worlds"] as? [String: Any])
        XCTAssertNil(encodedWorlds["lastExit"], "canonical re-encode has only one queue authority")

        var transitionalRoot = try XCTUnwrap(JSONSerialization.jsonObject(
            with: SaveCodec.encode(migrated)) as? [String: Any])
        var transitionalWorlds = try XCTUnwrap(transitionalRoot["worlds"] as? [String: Any])
        transitionalWorlds["lastExit"] = try JSONSerialization.jsonObject(
            with: SaveCodec.makeEncoder().encode(genuine))
        transitionalRoot["worlds"] = transitionalWorlds
        let transitional = try JSONSerialization.data(
            withJSONObject: transitionalRoot, options: [.sortedKeys])
        XCTAssertThrowsError(try SaveCodec.decode(transitional),
                             "schema 11 has one queue authority and rejects legacy duplication")
    }

    func testSchemaEighteenPromotesEveryExitSummaryToExplicitLegacyCustodyV0() throws {
        var state = GameState.newGame()
        let gear = ItemStack(id: InstanceID(rawValue: 7_181), catalogID: "blade_keen")
        let gearLine = RunExitSummary.ReceiptLine.uniqueItem(.init(
            lineID: "legacy-return-gear", instanceID: gear.id, snapshot: gear, quantity: 1,
            fallbackName: gear.displayName, fallbackIcon: gear.icon,
            recoveredDestination: .stored))
        let first = RunExitSummary(runIndex: 3, outcomeID: 1, kind: .portal,
                                   reason: "home", turnsTaken: 4, haulKeptFraction: 1,
                                   recoveredLines: [gearLine], lostLines: [])
        let second = RunExitSummary(runIndex: 4, outcomeID: 2, kind: .collapse,
                                    reason: "collapse", turnsTaken: 9, haulKeptFraction: 0.5)
        XCTAssertTrue(state.worlds.appendExpeditionReview(first))
        XCTAssertTrue(state.worlds.appendExpeditionReview(second))
        var root = try XCTUnwrap(JSONSerialization.jsonObject(
            with: SaveCodec.encode(state)) as? [String: Any])
        root["schemaVersion"] = 18
        func removeCustodyVersion(_ value: Any) -> Any {
            if var object = value as? [String: Any] {
                object.removeValue(forKey: "custodyReceiptVersion")
                for (key, child) in object { object[key] = removeCustodyVersion(child) }
                return object
            }
            if let array = value as? [Any] { return array.map(removeCustodyVersion) }
            return value
        }
        root = removeCustodyVersion(root) as! [String: Any]
        let source = try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys])
        let migrated = try Migrations.migrateIfNeeded(source)
        let decoded = try SaveCodec.makeDecoder().decode(GameState.self, from: migrated)
        XCTAssertEqual(decoded.schemaVersion, Tuning.saveSchemaVersion)
        XCTAssertEqual(decoded.worlds.expeditionReviewQueue.pending.map {
            $0.summary.custodyReceiptVersion
        }, [0, 0])
        guard case .uniqueItem(let migratedGear) = decoded.worlds.expeditionReviewQueue
            .pending[0].summary.recoveredLines[0] else {
            return XCTFail("legacy physical custody line was not preserved")
        }
        XCTAssertEqual(migratedGear.snapshot, gear)
        XCTAssertEqual(migratedGear.recoveredDestination, .stored)
        XCTAssertEqual(try Migrations.migrateIfNeeded(migrated), migrated)
    }

    func testB111AQueueValidationRejectsMalformedIdentityAndOrdering() throws {
        func stateObject() throws -> [String: Any] {
            var state = GameState.newGame()
            state.worlds.outcomeSequence = 2
            XCTAssertTrue(state.worlds.appendExpeditionReview(.init(
                runIndex: 1, outcomeID: 1, kind: .portal, reason: "one",
                turnsTaken: 2, haulKeptFraction: 1)))
            XCTAssertTrue(state.worlds.appendExpeditionReview(.init(
                runIndex: 2, outcomeID: 2, kind: .defeat, reason: "two",
                turnsTaken: 3, haulKeptFraction: 0.5)))
            return try XCTUnwrap(JSONSerialization.jsonObject(
                with: SaveCodec.encode(state)) as? [String: Any])
        }
        func assertRejected(_ mutate: (inout [String: Any]) throws -> Void,
                            file: StaticString = #filePath, line: UInt = #line) throws {
            var root = try stateObject()
            try mutate(&root)
            let bytes = try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys])
            let original = bytes
            XCTAssertThrowsError(try SaveCodec.decode(bytes), file: file, line: line)
            XCTAssertEqual(bytes, original, file: file, line: line)
        }
        func queue(_ root: inout [String: Any]) throws -> [String: Any] {
            let worlds = try XCTUnwrap(root["worlds"] as? [String: Any])
            return try XCTUnwrap(worlds["expeditionReviewQueue"] as? [String: Any])
        }
        func setQueue(_ value: Any, in root: inout [String: Any]) throws {
            var worlds = try XCTUnwrap(root["worlds"] as? [String: Any])
            worlds["expeditionReviewQueue"] = value
            root["worlds"] = worlds
        }

        try assertRejected { try setQueue(NSNull(), in: &$0) }
        try assertRejected {
            var value = try queue(&$0); value["schemaVersion"] = 2
            try setQueue(value, in: &$0)
        }
        try assertRejected {
            var value = try queue(&$0)
            var pending = try XCTUnwrap(value["pending"] as? [[String: Any]])
            pending.append(pending[0]); value["pending"] = pending
            try setQueue(value, in: &$0)
        }
        try assertRejected {
            var value = try queue(&$0)
            var pending = try XCTUnwrap(value["pending"] as? [[String: Any]])
            var first = pending[0]
            var summary = try XCTUnwrap(first["summary"] as? [String: Any])
            summary["outcomeID"] = 2
            first["summary"] = summary
            pending[0] = first
            value["pending"] = pending
            try setQueue(value, in: &$0)
        }
        try assertRejected {
            var value = try queue(&$0)
            var pending = try XCTUnwrap(value["pending"] as? [[String: Any]])
            pending.swapAt(0, 1); value["pending"] = pending
            try setQueue(value, in: &$0)
        }
        try assertRejected {
            var worlds = try XCTUnwrap($0["worlds"] as? [String: Any])
            worlds["outcomeSequence"] = 1; $0["worlds"] = worlds
        }
        try assertRejected {
            var value = try queue(&$0)
            value["pending"] = []
            value["acknowledged"] = [
                ["kind": "outcome", "outcomeID": 2],
                ["kind": "outcome", "outcomeID": 1],
            ]
            try setQueue(value, in: &$0)
        }
        try assertRejected {
            var value = try queue(&$0)
            var pending = try XCTUnwrap(value["pending"] as? [[String: Any]])
            pending.removeFirst()
            value["pending"] = pending
            value["acknowledged"] = [["kind": "outcome", "outcomeID": 2]]
            try setQueue(value, in: &$0)
        }
    }

    func testB111ASchemaTenOutcomeSequenceMalformedFailsWithoutChangingRawBytes() throws {
        var root = try XCTUnwrap(JSONSerialization.jsonObject(
            with: SaveCodec.encode(GameState.newGame())) as? [String: Any])
        root["schemaVersion"] = 10
        var worlds = try XCTUnwrap(root["worlds"] as? [String: Any])
        worlds.removeValue(forKey: "expeditionReviewQueue")
        for malformed: Any in [NSNull(), -1, 1.5, true, "1", Double.greatestFiniteMagnitude] {
            worlds["outcomeSequence"] = malformed
            root["worlds"] = worlds
            let bytes = try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys])
            let original = bytes
            XCTAssertThrowsError(try SaveCodec.decode(bytes))
            XCTAssertEqual(bytes, original)
        }
    }

    func testSchemaThreeExtractionReceiptMigrationFreezesCatalogueTruthAndFailsUnknown() throws {
        let legacy = Data(#"{"schemaVersion":3,"nested":{"resource":"gold","remainingHarvests":2,"yieldPerHarvest":3}}"#.utf8)
        let migrated = try Migrations.migrateSchemaThreeResourceNodesForTesting(legacy)
        let root = try XCTUnwrap(JSONSerialization.jsonObject(with: migrated) as? [String: Any])
        XCTAssertEqual(root["schemaVersion"] as? Int, 4)
        let node = try XCTUnwrap(root["nested"] as? [String: Any])
        let receipt = try XCTUnwrap(node["extractionRequirement"] as? [String: Any])
        XCTAssertEqual(receipt["rulesVersion"] as? String, "resource-extraction-1")
        XCTAssertEqual(receipt["resourceID"] as? String, "gold")
        XCTAssertEqual(receipt["disposition"] as? String, "mineral_node")
        XCTAssertEqual(receipt["requiredExtractionRank"] as? Int, 2)
        XCTAssertEqual(try Migrations.migrateSchemaThreeResourceNodesForTesting(migrated), migrated)

        let unknown = Data(#"{"schemaVersion":3,"nested":{"resource":"unknown_future","remainingHarvests":1,"yieldPerHarvest":1}}"#.utf8)
        XCTAssertThrowsError(try Migrations.migrateSchemaThreeResourceNodesForTesting(unknown))
    }

    func testCurrentResourceNodeAuthorityAcceptsFrozenCatalogueDriftAndAnchoredRoundTrip() throws {
        let state = resourceNodeAuthorityState()
        let bytes = try SaveCodec.encode(state)
        XCTAssertEqual(try Migrations.migrateIfNeeded(bytes), bytes)
        let decoded = try SaveCodec.decode(bytes)
        guard case .node(let mineral) = try XCTUnwrap(decoded.worlds.activeRun)
            .map[.init(x: 0, y: 0)].content,
              case .node(let flora) = try XCTUnwrap(decoded.worlds.anchoredRealms.first)
                .world.map[.init(x: 0, y: 0)].content else {
            return XCTFail("expected active and anchored nodes")
        }
        XCTAssertEqual(mineral.extractionRequirement?.requiredExtractionRank, 4,
                       "the frozen rank remains authoritative despite current catalogue tuning")
        XCTAssertEqual(ResourceExtractionRules.validatedRequirement(of: mineral),
                       mineral.extractionRequirement)
        XCTAssertEqual(flora.extractionRequirement?.disposition, .floraPrimary)
    }

    func testCurrentResourceNodeAuthorityRejectsMalformedActiveAndAnchoredRawBytes() throws {
        let valid = try SaveCodec.encode(resourceNodeAuthorityState())
        let mutations: [(String, (inout [String: Any]) -> Void)] = [
            ("missing", { $0.removeValue(forKey: "extractionRequirement") }),
            ("null", { $0["extractionRequirement"] = NSNull() }),
            ("future rules", { var value = $0["extractionRequirement"] as! [String: Any]
                value["rulesVersion"] = "resource-extraction-2"
                $0["extractionRequirement"] = value }),
            ("wrong resource", { var value = $0["extractionRequirement"] as! [String: Any]
                value["resourceID"] = "gold"; $0["extractionRequirement"] = value }),
            ("unknown resource", { $0["resource"] = "unknown_future" }),
            ("missing rank", { var value = $0["extractionRequirement"] as! [String: Any]
                value.removeValue(forKey: "requiredExtractionRank"); $0["extractionRequirement"] = value }),
            ("null rank", { var value = $0["extractionRequirement"] as! [String: Any]
                value["requiredExtractionRank"] = NSNull(); $0["extractionRequirement"] = value }),
            ("boolean rank", { var value = $0["extractionRequirement"] as! [String: Any]
                value["requiredExtractionRank"] = true; $0["extractionRequirement"] = value }),
            ("string rank", { var value = $0["extractionRequirement"] as! [String: Any]
                value["requiredExtractionRank"] = "2"; $0["extractionRequirement"] = value }),
            ("fractional rank", { var value = $0["extractionRequirement"] as! [String: Any]
                value["requiredExtractionRank"] = 1.5; $0["extractionRequirement"] = value }),
            ("negative rank", { var value = $0["extractionRequirement"] as! [String: Any]
                value["requiredExtractionRank"] = -1; $0["extractionRequirement"] = value }),
            ("rank five", { var value = $0["extractionRequirement"] as! [String: Any]
                value["requiredExtractionRank"] = 5; $0["extractionRequirement"] = value }),
            ("forbidden disposition", { var value = $0["extractionRequirement"] as! [String: Any]
                value["disposition"] = "direct_pickup"; $0["extractionRequirement"] = value })
        ]
        for (name, mutation) in mutations {
            let bytes = try mutatingResourceNode(in: valid, mutation)
            let original = bytes
            XCTAssertThrowsError(try SaveCodec.decode(bytes), name)
            XCTAssertEqual(bytes, original, name)
        }
        for name in ["missing", "null", "rank on flora"] {
            let bytes = try mutatingResourceNode(in: valid, anchored: true) { node in
                if name == "missing" { node.removeValue(forKey: "extractionRequirement") }
                else if name == "null" { node["extractionRequirement"] = NSNull() }
                else {
                    var value = node["extractionRequirement"] as! [String: Any]
                    value["requiredExtractionRank"] = 1
                    node["extractionRequirement"] = value
                }
            }
            let original = bytes
            XCTAssertThrowsError(try SaveCodec.decode(bytes), name)
            XCTAssertEqual(bytes, original, name)
        }
    }

    func testSchemaOneEssenceMigrationCombinesScalarAndOwnedPhysicalExactlyOnce() throws {
        let legacy = Data(#"""
        {
          "schemaVersion":1,
          "base":{
            "roster":[{"name":"Quill"}],
            "essence":37,
            "inventory":{"slots":1,"stacks":[
              {"id":{"rawValue":41},"catalogID":"essence_crystal","count":2,"identified":true},
              {"id":{"rawValue":42},"catalogID":"salve_lesser","count":1,"identified":true}
            ]},
            "spillover":[{"id":{"rawValue":43},"catalogID":"essence_crystal","count":3,"identified":true}],
            "goldCoins":9,
            "resources":{"amounts":{"essence_raw":7}}
          }
        }
        """#.utf8)

        let migrated = try SaveCodec.decode(legacy)
        XCTAssertEqual(migrated.schemaVersion, Tuning.saveSchemaVersion)
        XCTAssertEqual(migrated.base.essenceCrystalCount, 42)
        XCTAssertEqual(migrated.base.essenceCrystals?.catalogID, Items.essenceCrystal)
        XCTAssertFalse(migrated.base.inventory.stacks.contains { $0.catalogID == Items.essenceCrystal })
        XCTAssertFalse(migrated.base.spillover.contains { $0.catalogID == Items.essenceCrystal })
        XCTAssertEqual(migrated.base.goldCoins, 9)
        XCTAssertEqual(migrated.base.resources[Resources.essenceRaw], 7)
        XCTAssertEqual(migrated.base.inventory.stacks.count, 1,
                       "the crystal wallet must not consume Storehouse capacity")

        let relaunched = try SaveCodec.decode(SaveCodec.encode(migrated))
        XCTAssertEqual(relaunched.base.essenceCrystalCount, 42)
        XCTAssertEqual(relaunched, migrated)
    }

    func testSchemaOneScalarOnlyMigrationAllocatesCrystalBeyondNestedPhysicalIDs() throws {
        let legacy = Data(#"""
        {
          "schemaVersion":1,
          "base":{
            "roster":[{"name":"Quill"}],
            "essence":12,
            "inventory":{"slots":8,"stacks":[
              {"id":{"rawValue":801},"catalogID":"salve_lesser","count":1,"identified":true}
            ]},
            "spillover":[
              {"id":{"rawValue":902},"catalogID":"field_ration","count":1,"identified":true}
            ]
          }
        }
        """#.utf8)

        let migrated = try SaveCodec.decode(legacy)
        let crystalID = try XCTUnwrap(migrated.base.essenceCrystals?.id)
        XCTAssertGreaterThan(crystalID.rawValue, 902)
        XCTAssertEqual(migrated.base.essenceCrystalCount, 12)
        let allIDs = migrated.base.inventory.stacks.map(\.id)
            + migrated.base.spillover.map(\.id) + [crystalID]
        XCTAssertEqual(Set(allIDs).count, allIDs.count)

        let relaunched = try SaveCodec.decode(SaveCodec.encode(migrated))
        XCTAssertEqual(relaunched.base.essenceCrystals?.id, crystalID)
        XCTAssertEqual(relaunched, migrated)
    }

    func testSchemaOneMigrationRejectsEveryMalformedItemStackIDInExistingAndAllocationPaths() {
        let malformedValues = [
            "negative": "-1",
            "fractional": "1.5",
            "boolean": "true",
            "overflow": "18446744073709551616",
            "maximum": "18446744073709551615"
        ]

        for (name, rawValue) in malformedValues {
            let existingCrystal = Data(#"""
            {"schemaVersion":1,"base":{"roster":[{"name":"Quill"}],"essence":4,"essenceCrystals":{
              "id":{"rawValue":\#(rawValue)},"catalogID":"essence_crystal",
              "count":2,"identified":true
            },"inventory":{"slots":8,"stacks":[]}}}
            """#.utf8)
            XCTAssertThrowsError(try SaveCodec.decode(existingCrystal), "existing crystal: \(name)")

            let allocation = Data(#"""
            {"schemaVersion":1,"base":{"roster":[{"name":"Quill"}],"essence":4,"inventory":{"slots":8,"stacks":[{
              "id":{"rawValue":\#(rawValue)},"catalogID":"salve_lesser",
              "count":1,"identified":true
            }]}}}
            """#.utf8)
            XCTAssertThrowsError(try SaveCodec.decode(allocation), "allocation census: \(name)")
        }
    }

    func testSchemaOneMigrationMovesOwnedRunCrystalsWithoutTouchingOffers() throws {
        var legacy = GameState.newGame()
        legacy.schemaVersion = 1
        legacy.base.essenceCrystals = nil
        var run = legacyMaterialRun()
        run.satchelItems.stacks.append(ItemStack(id: .init(rawValue: 510),
                                                  catalogID: Items.essenceCrystal, count: 4))
        run.offeredItems.append(ItemStack(id: .init(rawValue: 511),
                                          catalogID: Items.essenceCrystal, count: 6))
        legacy.worlds.activeRun = run
        var root = try XCTUnwrap(JSONSerialization.jsonObject(
            with: SaveCodec.encode(legacy)) as? [String: Any])
        root["schemaVersion"] = 1
        var base = try XCTUnwrap(root["base"] as? [String: Any])
        base["essence"] = 11
        base["activeParty"] = [0]
        base.removeValue(forKey: "worldMaterialReserve")
        base.removeValue(forKey: "creatureMaterialReserve")
        base["materialReserve"] = ["units": []]
        if var roster = base["roster"] as? [[String: Any]] {
            for index in roster.indices { roster[index].removeValue(forKey: "persistentID") }
            base["roster"] = roster
        }
        root["base"] = base
        if var worlds = root["worlds"] as? [String: Any],
           var activeRun = worlds["activeRun"] as? [String: Any] {
            activeRun.removeValue(forKey: "companionHP")
            activeRun.removeValue(forKey: "healthCaps")
            activeRun.removeValue(forKey: "worldMaterialReserve")
            activeRun.removeValue(forKey: "creatureMaterialReserve")
            activeRun["materialReserve"] = ["units": []]
            worlds["activeRun"] = activeRun
            root["worlds"] = worlds
        }

        let migrated = try SaveCodec.decode(JSONSerialization.data(withJSONObject: root))
        XCTAssertEqual(migrated.base.essenceCrystalCount, 15)
        XCTAssertFalse(try XCTUnwrap(migrated.worlds.activeRun).satchelItems.stacks.contains {
            $0.catalogID == Items.essenceCrystal
        })
        XCTAssertEqual(try XCTUnwrap(migrated.worlds.activeRun).offeredItems.first(where: {
            $0.id == InstanceID(rawValue: 511)
        })?.count, 6, "merchant/world offers are not already-owned wallet stock")
    }

    func testSchemaTwoPartyPositionsMigrateToStableRosterIdentitiesAndRelaunchIdempotently() throws {
        let legacy = Data(#"""
        {"schemaVersion":2,"base":{"roster":[
          {"name":"Quill"},
          {"name":"Same","traveller":"mara"},
          {"name":"Same","traveller":"edren"}
        ],"activeParty":[0,2]}}
        """#.utf8)

        var migrated = try SaveCodec.decode(legacy)
        XCTAssertEqual(migrated.schemaVersion, Tuning.saveSchemaVersion)
        XCTAssertEqual(migrated.base.activeParty, [.founderQuill, .traveller("edren")])
        XCTAssertEqual(migrated.base.roster.map(\.persistentID), [
            .founderQuill, .traveller("mara"), .traveller("edren")
        ])

        migrated.base.roster.swapAt(0, 2)
        XCTAssertEqual(migrated.base.rosterIndex(for: .founderQuill), 2)
        XCTAssertEqual(migrated.base.rosterIndex(for: .traveller("edren")), 0)
        XCTAssertEqual(migrated.base.roster[migrated.base.rosterIndex(for: .traveller("edren"))!].traveller,
                       "edren", "same display names must not participate in identity")

        let relaunched = try SaveCodec.decode(SaveCodec.encode(migrated))
        XCTAssertEqual(relaunched, migrated)
    }

    func testSchemaTwoUnknownPartyPositionFailsAtomically() {
        let legacy = Data(#"""
        {"schemaVersion":2,"base":{"roster":[{"name":"Quill"}],"activeParty":[9]}}
        """#.utf8)
        let original = legacy
        XCTAssertThrowsError(try SaveCodec.decode(legacy))
        XCTAssertEqual(legacy, original, "failed migration must not rewrite source bytes")
    }

    func testSchemaTwoMigrationTransformsEveryNestedDurablePartyOwnerFromOneValidatedRoster() throws {
        let legacy = Data(#"""
        {"schemaVersion":2,
         "base":{"roster":[{"name":"Quill"},{"name":"Mara","traveller":"mara"}],
                 "activeParty":[0,1],"activeCompanion":1},
         "worlds":{"anchoredRealms":[{"assignedCompanions":[1]}],
                   "activeRun":{"book":{"written":[],"essencePaid":0},
                     "companionHP":{"0":12,"1":9},
                     "activeEncounter":{"partyNames":{"0":"Quill","1":"Mara"},
                       "turn":{"actor":{"companion":{"_0":1}}},
                       "action":{"skill":{"ally":{"companion":{"_0":0}}}},
                       "owner":{"member":{"_0":1}},
                       "cooldowns":{"companion-1|quick_step":2}}}}}
        """#.utf8)

        let migrated = try Migrations.migrateIfNeeded(legacy)
        let root = try XCTUnwrap(JSONSerialization.jsonObject(with: migrated) as? [String: Any])
        let base = try XCTUnwrap(root["base"] as? [String: Any])
        XCTAssertEqual(base["activeParty"] as? [String], ["founder:quill", "traveller:mara"])
        XCTAssertEqual(base["activeCompanion"] as? String, "traveller:mara")
        let roster = try XCTUnwrap(base["roster"] as? [[String: Any]])
        XCTAssertEqual(roster.compactMap { $0["persistentID"] as? String },
                       ["founder:quill", "traveller:mara"])

        let worlds = try XCTUnwrap(root["worlds"] as? [String: Any])
        let realms = try XCTUnwrap(worlds["anchoredRealms"] as? [[String: Any]])
        XCTAssertEqual(realms[0]["assignedCompanions"] as? [String], ["traveller:mara"])
        let run = try XCTUnwrap(worlds["activeRun"] as? [String: Any])
        let hp = try XCTUnwrap(run["companionHP"] as? [Any])
        XCTAssertTrue(hp.contains { ($0 as? String) == "founder:quill" })
        XCTAssertTrue(hp.contains { ($0 as? String) == "traveller:mara" })
        let encounter = try XCTUnwrap(run["activeEncounter"] as? [String: Any])
        let names = try XCTUnwrap(encounter["partyNames"] as? [Any])
        XCTAssertTrue(names.contains { ($0 as? String) == "traveller:mara" })
        let turn = try XCTUnwrap(encounter["turn"] as? [String: Any])
        let actor = try XCTUnwrap(turn["actor"] as? [String: Any])
        let companion = try XCTUnwrap(actor["companion"] as? [String: Any])
        XCTAssertEqual(companion["_0"] as? String, "traveller:mara")
        let action = try XCTUnwrap(encounter["action"] as? [String: Any])
        let skill = try XCTUnwrap(action["skill"] as? [String: Any])
        let ally = try XCTUnwrap(skill["ally"] as? [String: Any])
        let founder = try XCTUnwrap(ally["companion"] as? [String: Any])
        XCTAssertEqual(founder["_0"] as? String, "founder:quill")
        let owner = try XCTUnwrap(encounter["owner"] as? [String: Any])
        let member = try XCTUnwrap(owner["member"] as? [String: Any])
        XCTAssertEqual(member["_0"] as? String, "traveller:mara")
        let cooldowns = try XCTUnwrap(encounter["cooldowns"] as? [String: Any])
        XCTAssertEqual(cooldowns["party-traveller:mara|quick_step"] as? Int, 2)
    }

    func testSchemaTwoMigrationRejectsCorruptRosterAndNestedReferencesBeforeWriting() {
        let invalid = [
            #"{"schemaVersion":2,"base":{"roster":[{"name":"Mara","traveller":"mara"}],"activeParty":[0]}}"#,
            #"{"schemaVersion":2,"base":{"roster":[{"name":"Not Quill"}],"activeParty":[0]}}"#,
            #"{"schemaVersion":2,"base":{"roster":[{"name":"Quill"},{"name":"Unknown","traveller":"not_in_catalogue"}],"activeParty":[1]}}"#,
            #"{"schemaVersion":2,"base":{"roster":[{"name":"Quill"},{"name":"Mara","traveller":"mara"},{"name":"Again","traveller":"mara"}],"activeParty":[1]}}"#,
            #"{"schemaVersion":2,"base":{"roster":[{"name":"Quill"},{"name":"Empty","traveller":""}],"activeParty":[1]}}"#,
            #"{"schemaVersion":2,"base":{"roster":[{"name":"Quill"},{"name":"Mara","traveller":"mara"}],"activeParty":[0]},"worlds":{"activeRun":{"activeEncounter":{"turn":{"actor":{"companion":{"_0":7}}}}}}}"#
        ]
        for source in invalid {
            let bytes = Data(source.utf8)
            let original = bytes
            XCTAssertThrowsError(try Migrations.migrateIfNeeded(bytes), source)
            XCTAssertEqual(bytes, original)
        }
    }

    func testSchemaTwoMigrationRejectsPresentMalformedPersistentIDsBeforeWriting() {
        let malformedValues = [
            "number": "7",
            "object": #"{"rawValue":"founder:quill"}"#,
            "array": #"["founder:quill"]"#,
            "boolean": "true",
            "null": "null"
        ]
        for (name, value) in malformedValues {
            let payloads = [
                #"{"schemaVersion":2,"base":{"roster":[{"name":"Quill","persistentID":\#(value)}],"activeParty":[0]}}"#,
                #"{"schemaVersion":2,"base":{"roster":[{"name":"Quill"},{"name":"Mara","traveller":"mara","persistentID":\#(value)}],"activeParty":[1]}}"#
            ]
            for payload in payloads {
                let bytes = Data(payload.utf8)
                let original = bytes
                XCTAssertThrowsError(try Migrations.migrateIfNeeded(bytes), name)
                XCTAssertEqual(bytes, original, "failed \(name) migration must preserve raw bytes")
            }
        }
    }

    func testPhysicalCrystalWalletIsCapacityNeutralAtomicAndRelaunchStable() throws {
        var state = GameState.newGame()
        state.base.inventory = Inventory(slots: 1, stacks: [
            ItemStack(id: .init(rawValue: 700), catalogID: "salve_lesser")
        ])
        state.base.setEssenceCrystalCount(9)
        let fullInventory = state.base.inventory

        XCTAssertFalse(state.base.spendEssenceCrystals(10))
        XCTAssertEqual(state.base.essenceCrystalCount, 9)
        XCTAssertEqual(state.base.inventory, fullInventory)
        XCTAssertTrue(state.base.spendEssenceCrystals(4))
        state.base.addEssenceCrystals(6)
        XCTAssertEqual(state.base.essenceCrystalCount, 11)
        XCTAssertEqual(state.base.inventory, fullInventory)
        XCTAssertTrue(state.base.spillover.isEmpty)

        let relaunched = try SaveCodec.decode(SaveCodec.encode(state))
        XCTAssertEqual(relaunched.base.essenceCrystalCount, 11)
        XCTAssertEqual(relaunched.base.inventory.stacks, fullInventory.stacks)
        XCTAssertEqual(relaunched.base.inventory.slots, relaunched.base.inventoryCapacity,
                       "decode retains the existing derived Storehouse-capacity reconciliation")
        XCTAssertEqual(relaunched.base.essenceCrystals?.catalogID, Items.essenceCrystal)
    }

    func testLegacyMaterialContainersMigrateEveryKindExactlyOnceAndReencodeCanonically() throws {
        var state = GameState.newGame()
        let samples = MaterialFamilyID.allCases.enumerated().map { index, kind in
            CraftMaterialUnitV1(
                kind: kind,
                properties: MaterialProperties(
                    hardness: Double(index + 1), density: Double(index + 11),
                    insulation: Double(index + 21), flexibility: Double(index + 31),
                    lustre: Double(index + 41), reactivity: Double(index + 51)
                ),
                grade: Double(index + 61), source: "legacy-\(kind.rawValue)",
                qualifier: "qualifier-\(index)"
            )
        }
        var run = legacyMaterialRun()

        for (index, sample) in samples.enumerated() {
            var stack = ItemStack(
                id: InstanceID(rawValue: UInt64(50_000 + index)), catalogID: Items.material,
                identified: true, materials: [sample]
            )
            stack.protectedReturnCount = index.isMultiple(of: 2) ? 1 : 0
            switch index % 4 {
            case 0: state.base.inventory.stacks.append(stack)
            case 1: state.base.spillover.append(stack)
            case 2: run.satchelItems.stacks.append(stack)
            default: run.offeredItems.append(stack)
            }
        }
        state.worlds.activeRun = run

        var root = try XCTUnwrap(JSONSerialization.jsonObject(
            with: SaveCodec.encode(state)) as? [String: Any])
        func legacyShape(_ value: Any) throws -> Any {
            if let array = value as? [Any] { return try array.map(legacyShape) }
            guard var object = value as? [String: Any] else { return value }
            if let units = object["materials"] as? [[String: Any]] {
                object["materials"] = try units.map { unit -> [String: Any] in
                    let family = try XCTUnwrap(unit["familyID"] as? String)
                    let index = try XCTUnwrap(MaterialFamilyID.allCases.firstIndex {
                        $0.rawValue == family
                    })
                    return ["kind": family,
                            "properties": try XCTUnwrap(unit["properties"]),
                            "grade": Double(index + 61),
                            "source": "legacy-\(family)",
                            "qualifier": "qualifier-\(index)"]
                }
            }
            for (key, child) in object { object[key] = try legacyShape(child) }
            return object
        }
        root = try XCTUnwrap(legacyShape(root) as? [String: Any])
        root["schemaVersion"] = 6
        var base = try XCTUnwrap(root["base"] as? [String: Any])
        base.removeValue(forKey: "worldMaterialReserve")
        base.removeValue(forKey: "creatureMaterialReserve")
        base["materialReserve"] = ["units": []]
        root["base"] = base
        var worlds = try XCTUnwrap(root["worlds"] as? [String: Any])
        var activeRun = try XCTUnwrap(worlds["activeRun"] as? [String: Any])
        activeRun.removeValue(forKey: "worldMaterialReserve")
        activeRun.removeValue(forKey: "creatureMaterialReserve")
        activeRun["materialReserve"] = ["units": []]
        worlds["activeRun"] = activeRun
        root["worlds"] = worlds
        let legacyData = try JSONSerialization.data(withJSONObject: root)

        let migrated = try SaveCodec.decode(legacyData)
        let migratedRun = try XCTUnwrap(migrated.worlds.activeRun)
        let units = migrated.base.worldMaterialReserve.units + migrated.base.creatureMaterialReserve.units
            + migratedRun.worldMaterialReserve.units + migratedRun.creatureMaterialReserve.units

        XCTAssertEqual(units.count, samples.count)
        XCTAssertEqual(Set(units.map(\.sample.kind)), Set(MaterialFamilyID.allCases))
        XCTAssertTrue(samples.allSatisfy { sample in
            units.filter {
                $0.sample.kind == sample.kind
                    && $0.sample.properties == sample.properties
                    && $0.sample.qualityBand == sample.qualityBand
                    && $0.sample.source == sample.source
                    && $0.sample.qualifier == sample.qualifier
            }.count == 1
        })
        XCTAssertEqual(Set(units.map(\.id)).count, units.count)
        let protectedSamples = samples.enumerated().compactMap {
            $0.offset.isMultiple(of: 2) ? $0.element : nil
        }
        XCTAssertEqual(units.filter(\.protectedReturn).count, protectedSamples.count)
        XCTAssertTrue(protectedSamples.allSatisfy { sample in
            units.contains { $0.protectedReturn && $0.sample.kind == sample.kind }
        })
        XCTAssertFalse(migrated.base.inventory.stacks.contains { $0.catalogID == Items.material })
        XCTAssertFalse(migrated.base.spillover.contains { $0.catalogID == Items.material })
        XCTAssertFalse(migratedRun.satchelItems.stacks.contains { $0.catalogID == Items.material })
        XCTAssertFalse(migratedRun.offeredItems.contains { $0.catalogID == Items.material })

        let canonical = try SaveCodec.encode(migrated)
        let relaunched = try SaveCodec.decode(canonical)
        XCTAssertEqual(relaunched, migrated)
        let relaunchedRun = try XCTUnwrap(relaunched.worlds.activeRun)
        let relaunchedUnits = relaunched.base.worldMaterialReserve.units
            + relaunched.base.creatureMaterialReserve.units
            + relaunchedRun.worldMaterialReserve.units + relaunchedRun.creatureMaterialReserve.units
        XCTAssertEqual(relaunchedUnits.count, units.count)
        XCTAssertEqual(Set(relaunchedUnits.map(\.id)).count, relaunchedUnits.count)
        XCTAssertEqual(Set(relaunchedUnits.map(\.id)), Set(units.map(\.id)))
    }

    func testLegacyPencilAndChainingDecodeToCanonicalResearchAndReencodeCanonically() throws {
        let data = Data(#"{"completedResearch":["pen_pencil","pen_desk"],"hasChainingUnlock":true,"worldMaterialReserve":{"holdings":[]},"creatureMaterialReserve":{"holdings":[]}}"#.utf8)
        let decoded = try JSONDecoder().decode(BaseState.self, from: data)
        XCTAssertEqual(decoded.completedResearch.intersection(["pen_brush", "pen_desk", "pen_chaining"]),
                       ["pen_brush", "pen_desk", "pen_chaining"])
        XCTAssertFalse(decoded.completedResearch.contains("pen_pencil"))
        XCTAssertTrue(decoded.hasChainingUnlock)
        XCTAssertTrue(decoded.capabilities.contains("chaining"))

        let encoded = String(decoding: try JSONEncoder().encode(decoded), as: UTF8.self)
        XCTAssertFalse(encoded.contains("pen_pencil"))
        XCTAssertFalse(encoded.contains("hasChainingUnlock"))
        XCTAssertTrue(encoded.contains("pen_chaining"))
        XCTAssertTrue(encoded.contains("capabilities"))
        let roundTrip = try JSONDecoder().decode(BaseState.self, from: Data(encoded.utf8))
        XCTAssertEqual(roundTrip.completedResearch, decoded.completedResearch)
        XCTAssertEqual(roundTrip.capabilities, decoded.capabilities)
    }

    func testLegacyPenmanshipCompletionsPopulateAndRoundTripTheCapabilitySet() throws {
        let data = Data(#"{"completedResearch":["pen_ink_mixing","pen_compounds","pen_chaining"],"worldMaterialReserve":{"holdings":[]},"creatureMaterialReserve":{"holdings":[]}}"#.utf8)
        let decoded = try JSONDecoder().decode(BaseState.self, from: data)
        XCTAssertEqual(decoded.capabilities.intersection(["inkMixing", "compoundAssembly", "chaining"]),
                       ["inkMixing", "compoundAssembly", "chaining"])

        let relaunched = try JSONDecoder().decode(
            BaseState.self, from: JSONEncoder().encode(decoded))
        XCTAssertEqual(relaunched.capabilities, decoded.capabilities)
    }

    func testEveryCanonicalCompletedCapabilityGrantMigratesWithoutGuessingUnknownIDs() throws {
        let nodes = ContentCatalog.shared.researchNodes.filter {
            $0.grants.contains { $0.kind == .capability }
        }
        let completed = nodes.map(\.id.rawValue) + ["future_unknown_completion"]
        let data = try JSONSerialization.data(withJSONObject: [
            "completedResearch": completed,
            "capabilities": ["legacy_unknown_capability"],
            "worldMaterialReserve": ["holdings": []],
            "creatureMaterialReserve": ["holdings": []]
        ])
        let decoded = try JSONDecoder().decode(BaseState.self, from: data)
        let expected = Set(nodes.flatMap(\.grants).compactMap { grant in
            grant.kind == .capability ? grant.id.map(CapabilityID.init(rawValue:)) : nil
        })
        XCTAssertTrue(expected.isSubset(of: decoded.capabilities))
        XCTAssertTrue(decoded.capabilities.contains("legacy_unknown_capability"))
        XCTAssertTrue(decoded.completedResearch.contains("future_unknown_completion"))

        let relaunched = try JSONDecoder().decode(BaseState.self,
            from: JSONEncoder().encode(decoded))
        XCTAssertEqual(relaunched.completedResearch, decoded.completedResearch)
        XCTAssertEqual(relaunched.capabilities, decoded.capabilities)
    }

    func testBuiltStationMigrationGrantsCompletionAndCapabilityInOneDecode() throws {
        let data = Data(#"{"stations":{"tannery":{"isUnlocked":true,"tier":0},"weaponsmith":{"isUnlocked":true,"tier":0}},"worldMaterialReserve":{"holdings":[]},"creatureMaterialReserve":{"holdings":[]}}"#.utf8)
        let decoded = try JSONDecoder().decode(BaseState.self, from: data)
        XCTAssertTrue(decoded.completedResearch.contains("tannery_wear_root"))
        XCTAssertTrue(decoded.capabilities.contains("tannery_wear"))
        XCTAssertTrue(decoded.completedResearch.contains("weaponsmith_point_root"))
        XCTAssertTrue(decoded.capabilities.contains("weaponsmith_fitted_point"))
    }

    func testLegacyBrushDiaryProgressAliasesEveryPersistedKeyWithoutDuplicates() throws {
        let data = Data(#"{"foundPages":["halloway_lead_pencil","halloway_brush_ferrule","isolde_lead_pencil"],"pagesWaiting":{"halloway_lead_pencil":2,"halloway_brush_ferrule":5},"patiencePage":"isolde_lead_pencil"}"#.utf8)
        let decoded = try JSONDecoder().decode(LibraryState.self, from: data)
        XCTAssertEqual(decoded.foundPages, ["halloway_brush_ferrule", "isolde_brush_hand"])
        XCTAssertEqual(decoded.pagesWaiting["halloway_brush_ferrule"], 5)
        XCTAssertEqual(decoded.patiencePage, "isolde_brush_hand")

        let encoded = String(decoding: try JSONEncoder().encode(decoded), as: UTF8.self)
        XCTAssertFalse(encoded.contains("lead_pencil"))
    }

    func testLegacyBrushDiaryIDsCanonicalizeAcrossPersistedRunReceipts() throws {
        let outcomeData = Data(#"{"runIndex":1,"kind":"waystone","reason":"test","turnsTaken":2,"haulKeptFraction":1,"pages":["halloway_lead_pencil","isolde_lead_pencil"]}"#.utf8)
        let outcome = try JSONDecoder().decode(RunExitSummary.self, from: outcomeData)
        XCTAssertEqual(outcome.pages, ["halloway_brush_ferrule", "isolde_brush_hand"])
        XCTAssertFalse(String(decoding: try JSONEncoder().encode(outcome), as: UTF8.self)
            .contains("lead_pencil"))

        let diagnosticsData = Data(#"{"selectedDiaryPages":["halloway_lead_pencil"],"placedDiaryPages":["isolde_lead_pencil"]}"#.utf8)
        let diagnostics = try JSONDecoder().decode(WorldGenerationDiagnostics.self,
                                                    from: diagnosticsData)
        XCTAssertEqual(diagnostics.selectedDiaryPages, ["halloway_brush_ferrule"])
        XCTAssertEqual(diagnostics.placedDiaryPages, ["isolde_brush_hand"])
        XCTAssertFalse(String(decoding: try JSONEncoder().encode(diagnostics), as: UTF8.self)
            .contains("lead_pencil"))
    }

    func testLegacyRecoveredPagesMigrateInOrderWithoutInventingProvenance() throws {
        let data = Data(#"{"foundPages":["mara_where_0","retired_unknown","mara_where_0"]}"#.utf8)
        let decoded = try JSONDecoder().decode(LibraryState.self, from: data)

        XCTAssertEqual(decoded.recoveredPages.map(\.pageID), ["mara_where_0", "retired_unknown"])
        XCTAssertEqual(decoded.recoveredPages.map(\.discoverySequence), [0, 1])
        XCTAssertTrue(decoded.recoveredPages.allSatisfy {
            $0.foundInOutcomeID == nil && $0.foundInWorldRecordID == nil && $0.foundAtSiteID == nil
        })

        let roundTrip = try JSONDecoder().decode(
            LibraryState.self, from: JSONEncoder().encode(decoded))
        XCTAssertEqual(roundTrip, decoded)
    }

    private final class CountingIO: GamePersistenceIO, @unchecked Sendable {
        let wrapped: SaveFileIO
        private let lock = NSLock()
        private var writeStorage = 0

        init(_ wrapped: SaveFileIO) { self.wrapped = wrapped }
        var saveURL: URL { wrapped.saveURL }
        var saveFileByteCount: Int? { wrapped.saveFileByteCount }
        var diagnosticCampaignReference: String? { wrapped.diagnosticCampaignReference }
        var writes: Int { lock.withLock { writeStorage } }
        func load() -> SaveLoadOutcome { wrapped.load() }
        func write(_ data: Data) throws {
            lock.withLock { writeStorage += 1 }
            try wrapped.write(data)
        }
        func deleteEverything() { wrapped.deleteEverything() }
    }

    private func legacyMaterialRun() -> WorldRun {
        let book = BoundBook(symbols: [:], randomlyFilled: [], essencePaid: 0)
        let generated = Worldgen.generate(book: book, seed: 812)
        return WorldRun(runIndex: 3, book: book, mapSeed: 812,
                        rng: SeededRNG(seed: 812), map: generated.map,
                        playerPosition: generated.start)
    }

    private var io: SaveFileIO!

    override func setUp() {
        super.setUp()
        io = .temporary(name: "persistence-\(UUID().uuidString)")
    }

    override func tearDown() {
        io.deleteEverything()
        super.tearDown()
    }

    func testNewGameWhenNoSaveFileExists() {
        guard case .newGame = io.load() else { return XCTFail("Expected a new game") }
    }

    func testSaveRoundTripsExactly() throws {
        var original = GameState.newGame()
        original.reality.motes = 7
        original.reality.discovery.recordCreature("ink_hound", runIndex: 3)
        original.base.essence = 123
        original.base.resources.add(5, of: Resources.ore)
        original.worlds.runIndex = 4

        try io.write(SaveCodec.encode(original))

        guard let reloaded = io.load().state else { return XCTFail("Expected to load") }
        XCTAssertEqual(reloaded, original, "A save round-trip must be lossless")
    }

    func testAnchoredRealmSurvivesSaveRoundTrip() throws {
        var state = GameState.newGame()
        let book = BoundBook(symbols: [:], randomlyFilled: [], essencePaid: 0)
        let generated = Worldgen.generate(book: book, seed: 73)
        let run = WorldRun(runIndex: 7, book: book, mapSeed: 73, rng: SeededRNG(seed: 73),
                           map: generated.map, playerPosition: generated.start)
        state.base.activeParty = []
        state.worlds.anchoredRealms = [
            AnchoredRealm(runIndex: 7, name: "The Quiet Reach", route: .craftedFrame,
                          sustainObligation: 3, productionContribution: 2,
                          assignedCompanions: [0], world: run)
        ]

        try io.write(SaveCodec.encode(state))
        let reloaded = try XCTUnwrap(io.load().state)

        XCTAssertEqual(reloaded.worlds.anchoredRealms, state.worlds.anchoredRealms)
        XCTAssertEqual(reloaded.worlds.anchoredRealms.first?.projectedShortfall, 1)
    }

    func testSaveFromBeforeAnchoringLoadsWithAnEmptyAtlas() throws {
        let state = GameState.newGame()
        let encoded = try SaveCodec.encode(state)
        var root = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        var worlds = try XCTUnwrap(root["worlds"] as? [String: Any])
        worlds.removeValue(forKey: "anchoredRealms")
        root["worlds"] = worlds
        let legacy = try JSONSerialization.data(withJSONObject: root)

        try io.write(legacy)
        let reloaded = try XCTUnwrap(io.load().state)

        XCTAssertEqual(reloaded.worlds.anchoredRealms, [])
    }

    /// The acceptance criterion: killed mid-encounter, we come back mid-encounter.
    func testMidEncounterStateSurvivesRoundTrip() throws {
        var state = GameState.newGame()
        var rng = SeededRNG(seed: 42)
        let book = BoundBook(symbols: ["terrain": "caverns", "bounty": "rich_ore"], randomlyFilled: ["biome"], essencePaid: 20)
        let world = Worldgen.generate(book: book, seed: 42)
        var run = WorldRun(
            runIndex: 1,
            book: book,
            mapSeed: 42,
            rng: rng,
            map: world.map,
            playerPosition: world.start,
            enemies: world.enemies
        )
        run.stability = 61.5
        run.turnsTaken = 12
        run.satchel.add(3, of: Resources.ore)
        var encounter = EncounterState(
            id: InstanceID(rawValue: rng.next()),
            foes: [FoeState(id: InstanceID(rawValue: 1),
                            creatureID: "ink_hound",
                            stats: CombatStats(displayName: "Ink Hound", icon: "pawprint", maxHP: 16, attack: 4),
                            currentHP: 9)],
            order: [.binder, .companion(0), .foe(InstanceID(rawValue: 1))],
            log: ["You hit Ink Hound for 5."]
        )
        encounter.turnIndex = 1
        encounter.roundNumber = 3
        encounter.debugGodMode = .init(preventedLethalDamageCount: 2)
        run.activeEncounter = encounter
        state.worlds.activeRun = run

        try io.write(SaveCodec.encode(state))
        let reloaded = try XCTUnwrap(io.load().state)

        let restored = try XCTUnwrap(reloaded.worlds.activeRun)
        XCTAssertEqual(restored.activeEncounter?.roundNumber, 3)
        XCTAssertEqual(restored.activeEncounter?.foes.first?.currentHP, 9)
        XCTAssertEqual(restored.activeEncounter?.debugGodMode?.preventedLethalDamageCount, 2)
        XCTAssertEqual(restored.stability, 61.5)
        XCTAssertEqual(restored.book.randomlyFilled, ["biome"])
        XCTAssertEqual(reloaded, state)
    }

    /// The RNG must resume *where it was*, not rewind — otherwise a force-quit is a re-roll.
    func testRNGPositionSurvivesRoundTrip() throws {
        var state = GameState.newGame()
        let world = Worldgen.generate(book: BoundBook(symbols: [:], randomlyFilled: [], essencePaid: 0), seed: 99)
        var run = WorldRun(runIndex: 1,
                           book: BoundBook(symbols: [:], randomlyFilled: [], essencePaid: 0),
                           mapSeed: 99,
                           rng: SeededRNG(seed: 99),
                           map: world.map,
                           playerPosition: world.start)
        for _ in 0..<10 { _ = run.rng.next() }
        let expectedNext = { var copy = run.rng; return copy.next() }()
        state.worlds.activeRun = run

        try io.write(SaveCodec.encode(state))
        var reloaded = try XCTUnwrap(try XCTUnwrap(io.load().state).worlds.activeRun)

        XCTAssertEqual(reloaded.rng.drawCount, 10)
        XCTAssertEqual(reloaded.rng.next(), expectedNext, "Resuming must not rewind the RNG stream")
    }

    func testCorruptSaveIsReadOnlyAndDoesNotSilentlyPromoteBackup() throws {
        var good = GameState.newGame()
        good.base.essence = 555
        try io.write(SaveCodec.encode(good))
        // Second write rolls the first into .backup, then we corrupt the primary.
        try io.write(SaveCodec.encode(good))
        try Data("{ not json".utf8).write(to: io.saveURL)

        let primary = try Data(contentsOf: io.saveURL)
        let backup = try Data(contentsOf: io.backupURL)
        guard case .unrecoverable = io.load() else { return XCTFail("Expected read-only failure") }
        XCTAssertEqual(try Data(contentsOf: io.saveURL), primary)
        XCTAssertEqual(try Data(contentsOf: io.backupURL), backup)
    }

    /// Adding a field to a layer must not cost a player their save.
    func testSaveMissingAWholeLayerStillLoads() throws {
        let partial = """
        { "schemaVersion": 1, "base": { "roster":[{"name":"Quill"}], "essence": 77 } }
        """
        try FileManager.default.createDirectory(at: io.directory, withIntermediateDirectories: true)
        try Data(partial.utf8).write(to: io.saveURL)

        _ = try SaveCodec.decode(Data(partial.utf8))

        let loaded = try XCTUnwrap(io.load().state)
        XCTAssertEqual(loaded.base.essence, 77)
        XCTAssertEqual(loaded.reality.motes, 0, "A missing layer falls back to its new-game value")
    }

    func testPreparedLaunchCommitsReconciliationBeforePublishingState() throws {
        var saved = GameState.newGame()
        saved.meta.launchCount = 4
        saved.meta.mutationCount = 9
        saved.base.essence = 0
        try io.write(SaveCodec.encode(saved))

        let prepared = try GameStore.prepareLaunch(io: io)
        let persisted = try XCTUnwrap(io.load().state)

        XCTAssertEqual(prepared.state.meta.launchCount, 4,
                       "Diagnostics-only launch counting must not force a save rewrite")
        XCTAssertEqual(prepared.state.meta.mutationCount, 10,
                       "All actual launch reconciliation commits as one mutation")
        XCTAssertEqual(persisted, prepared.state,
                       "A published store can never outrun its launch commitment on disk")
        XCTAssertGreaterThanOrEqual(prepared.timings.loadMilliseconds, 0)
        XCTAssertGreaterThanOrEqual(prepared.timings.reconciliationMilliseconds, 0)
        XCTAssertGreaterThanOrEqual(prepared.timings.persistenceMilliseconds, 0)
        XCTAssertGreaterThanOrEqual(prepared.timings.totalMilliseconds,
                                    prepared.timings.loadMilliseconds)
    }

    func testPreparedLaunchReportsRealOrderedWorkPhases() throws {
        final class Recorder: @unchecked Sendable {
            private let lock = NSLock()
            private var storage: [GameStore.PreparationStep] = []
            func append(_ step: GameStore.PreparationStep) {
                lock.lock(); defer { lock.unlock() }
                storage.append(step)
            }
            var values: [GameStore.PreparationStep] {
                lock.lock(); defer { lock.unlock() }
                return storage
            }
        }
        let recorder = Recorder()
        var state = GameState.newGame()
        state.base.essence = 0
        try io.write(SaveCodec.encode(state))

        _ = try GameStore.prepareLaunch(io: io, progress: recorder.append)

        XCTAssertEqual(recorder.values,
                       [.loadingSave, .reconcilingCatalogue, .committingSave, .complete])
        XCTAssertEqual(recorder.values.map(\.accessibilityDescription),
                       ["Reading campaign", "Checking the Atlas", "Securing campaign", "Ready"])
    }

    func testHealthyLaunchPerformsZeroWritesWhileRealReconciliationPersistsOnce() throws {
        final class StepRecorder: @unchecked Sendable {
            private let lock = NSLock()
            private var storage: [GameStore.PreparationStep] = []
            func append(_ value: GameStore.PreparationStep) {
                lock.lock(); defer { lock.unlock() }
                storage.append(value)
            }
            var values: [GameStore.PreparationStep] {
                lock.lock(); defer { lock.unlock() }
                return storage
            }
        }
        try io.write(SaveCodec.encode(GameState.newGame()))
        _ = try GameStore.prepareLaunch(io: io)
        let normalized = try XCTUnwrap(io.load().state)
        let healthyIO = CountingIO(io)
        let healthySteps = StepRecorder()
        let healthy = try GameStore.prepareLaunch(io: healthyIO, progress: healthySteps.append)
        XCTAssertEqual(healthyIO.writes, 0,
                       "A healthy launch must not rewrite and decode the same campaign")
        XCTAssertEqual(healthy.state, normalized)
        XCTAssertEqual(healthySteps.values, [.loadingSave, .reconcilingCatalogue, .complete],
                       "A read-only launch must not claim that it is securing a changed save")

        var stranded = normalized
        stranded.base.essence = 0
        try io.write(SaveCodec.encode(stranded))
        let reconciliationIO = CountingIO(io)
        let reconciliationSteps = StepRecorder()
        let reconciled = try GameStore.prepareLaunch(io: reconciliationIO,
                                                     progress: reconciliationSteps.append)
        XCTAssertEqual(reconciliationIO.writes, 1,
                       "Real launch reconciliation must commit atomically exactly once")
        XCTAssertGreaterThanOrEqual(EconomyRules.spendableEssence(in: reconciled.state),
                                    EconomyRules.minimumBindCost(in: reconciled.state))
        XCTAssertEqual(reconciliationSteps.values,
                       [.loadingSave, .reconcilingCatalogue, .committingSave, .complete])
        XCTAssertEqual(io.load().state, reconciled.state)
    }

    @MainActor
    func testLaunchCoordinatorPublishesOnlyPreparedStateAndWarmReadyDoesNotFlash() async throws {
        final class Announcements: @unchecked Sendable {
            var values: [String] = []
        }
        let announcements = Announcements()
        let prepared = try GameStore.prepareLaunch(io: io)
        let coordinator = AppLaunchCoordinator(announce: { announcements.values.append($0) },
                                               prepare: { _ in prepared })
        XCTAssertNil(coordinator.store)
        coordinator.start()
        try await waitUntil { coordinator.store != nil }
        XCTAssertEqual(coordinator.store?.state, prepared.state)
        XCTAssertEqual(announcements.values, ["The Atlas is open."])

        let warmStore = try XCTUnwrap(coordinator.store)
        let warm = AppLaunchCoordinator(readyStore: warmStore,
                                        announce: { announcements.values.append($0) },
                                        prepare: { _ in prepared })
        warm.start()
        XCTAssertTrue(warm.store === warmStore,
                      "An already-ready warm scene must not swap through the loader")
        XCTAssertEqual(announcements.values, ["The Atlas is open."],
                       "An immediately warm-ready scene must not announce a redundant transition")
    }

    @MainActor
    func testLaunchCoordinatorShowsFailureAndTimeoutWithRetryPath() async throws {
        struct TestFailure: LocalizedError {
            var errorDescription: String? { "A deliberate launch failure." }
        }
        let failure = AppLaunchCoordinator(prepare: { _ in throw TestFailure() })
        failure.start()
        try await waitUntil {
            if case .failed = failure.phase { return true }
            return false
        }
        guard case .failed(let failureState) = failure.phase else { return XCTFail("Expected failure") }
        XCTAssertEqual(failureState.message, "The Atlas could not be opened.")
        XCTAssertEqual(failureState.details, "A deliberate launch failure.")
        XCTAssertTrue(failureState.canRetry)

        let timeoutIO = try XCTUnwrap(io)
        let timeout = AppLaunchCoordinator(timeout: .milliseconds(20), prepare: { _ in
            try await Task.sleep(for: .milliseconds(80))
            return try GameStore.prepareLaunch(io: timeoutIO)
        })
        timeout.start()
        try await waitUntil {
            if case .failed = timeout.phase { return true }
            return false
        }
        guard case .failed(let timeoutState) = timeout.phase else { return XCTFail("Expected timeout") }
        XCTAssertEqual(timeoutState.message, "The Atlas is taking longer than expected.")
        XCTAssertFalse(timeoutState.canRetry)
        timeout.retry()
        try await waitUntil { timeout.store != nil }
        XCTAssertNotNil(timeout.store, "A timed-out preparation finishes safely instead of racing a replacement writer")
    }

    @MainActor
    func testLaunchTimeoutSerializesRetryWriters() async throws {
        actor Probe {
            var calls = 0
            var active = 0
            var maximumActive = 0
            func begin() -> Int {
                calls += 1
                active += 1
                maximumActive = max(maximumActive, active)
                return calls
            }
            func end() { active -= 1 }
            func snapshot() -> (Int, Int) { (calls, maximumActive) }
        }
        struct FirstFailure: LocalizedError { var errorDescription: String? { "first writer failed" } }
        let probe = Probe()
        let prepared = try GameStore.prepareLaunch(io: io)
        let coordinator = AppLaunchCoordinator(timeout: .milliseconds(10), prepare: { _ in
            let call = await probe.begin()
            try? await Task.sleep(for: .milliseconds(50))
            await probe.end()
            if call == 1 { throw FirstFailure() }
            return prepared
        })
        coordinator.start()
        try await waitUntil {
            if case .failed(let state) = coordinator.phase { return !state.canRetry }
            return false
        }
        coordinator.retry()
        let timedOutSnapshot = await probe.snapshot()
        XCTAssertEqual(timedOutSnapshot.0, 1, "Retry remains disabled while the timed-out writer owns the save path")
        try await waitUntil {
            if case .failed(let state) = coordinator.phase { return state.canRetry }
            return false
        }
        coordinator.retry()
        try await waitUntil { coordinator.store != nil }
        let snapshot = await probe.snapshot()
        XCTAssertEqual(snapshot.0, 2)
        XCTAssertEqual(snapshot.1, 1, "Launch writers must never overlap")
    }

    func testFirstFrameClockIncludesElapsedLaunchWork() async throws {
        LaunchClock.begin()
        let before = LaunchClock.elapsedMilliseconds()
        try await Task.sleep(for: .milliseconds(25))
        let after = LaunchClock.elapsedMilliseconds()
        XCTAssertGreaterThanOrEqual(after - before, 20,
                                    "The eager launch epoch must include work before the first frame")
    }

    func testStaticLaunchMarkUsesTheAcceptedPairedPageGeometry() throws {
        let projectRoot = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let storyboard = try String(contentsOf: projectRoot.appendingPathComponent("Support/LaunchScreen.storyboard"),
                                    encoding: .utf8)
        let acceptedRects = [
            "x=\"0\" y=\"4\" width=\"36\" height=\"54\"",
            "x=\"38\" y=\"4\" width=\"36\" height=\"54\"",
            "x=\"4\" y=\"8\" width=\"32\" height=\"46\"",
            "x=\"38\" y=\"8\" width=\"32\" height=\"46\"",
            "x=\"8\" y=\"12\" width=\"28\" height=\"38\"",
            "x=\"38\" y=\"12\" width=\"28\" height=\"38\"",
            "x=\"35\" y=\"0\" width=\"4\" height=\"58\"",
            "x=\"0\" y=\"54\" width=\"32\" height=\"4\"",
            "x=\"42\" y=\"54\" width=\"32\" height=\"4\"",
            "x=\"8\" y=\"46\" width=\"6\" height=\"4\"",
            "x=\"60\" y=\"50\" width=\"6\" height=\"4\""
        ]
        for rect in acceptedRects {
            XCTAssertTrue(storyboard.contains(rect), "Static launch mark drifted from v0.2 rectangle \(rect)")
        }
        XCTAssertTrue(storyboard.contains("id=\"launch-progress-track\""))
        XCTAssertTrue(storyboard.contains("x=\"28\" y=\"270\" width=\"192\" height=\"4\""),
                      "the static handoff no longer reserves the exact in-app progress-bar frame")
    }

    // MARK: - GameStore

    @MainActor
    func testEveryMutationIsPersistedAndCounted() async throws {
        let store = GameStore(io: io)
        let startingCount = store.state.meta.mutationCount

        store.mutate("test mutation") { $0.reality.motes += 3 }
        XCTAssertEqual(store.state.meta.mutationCount, startingCount + 1)
        XCTAssertEqual(store.state.meta.lastAction, "test mutation")
        XCTAssertEqual(store.state.meta.semanticActionTrail.last, "test mutation")

        try await waitForDiskToCatchUp(store)
        let onDisk = try XCTUnwrap(io.load().state)
        XCTAssertEqual(onDisk.reality.motes, 3)
        XCTAssertEqual(onDisk.meta.mutationCount, store.state.meta.mutationCount)
    }

    /// A commitment point must be on disk before the call returns — no debounce window.
    @MainActor
    func testFlushingMutationIsOnDiskImmediately() throws {
        let store = GameStore(io: io)
        store.mutate("commitment point", flush: true) { $0.base.essence = 999 }

        let onDisk = try XCTUnwrap(io.load().state)
        XCTAssertEqual(onDisk.base.essence, 999)
        XCTAssertEqual(onDisk.meta.mutationCount, store.state.meta.mutationCount)
    }

    /// Rapid taps must collapse into few writes but still land the final state.
    @MainActor
    func testRapidMutationsDebounceAndStillLandTheLastValue() async throws {
        let store = GameStore(io: io)
        let writesBefore = store.diagnostics.writeCount

        for index in 1...20 { store.mutate("tap \(index)") { $0.reality.motes = index } }

        try await waitForDiskToCatchUp(store)
        XCTAssertEqual(try XCTUnwrap(io.load().state).reality.motes, 20)
        XCTAssertLessThan(store.diagnostics.writeCount - writesBefore, 20, "Writes should coalesce")
        XCTAssertEqual(store.state.meta.semanticActionTrail.count, SaveMeta.actionTrailLimit)
        XCTAssertEqual(store.state.meta.semanticActionTrail.first, "tap 1")
        XCTAssertEqual(store.state.meta.semanticActionTrail.last, "tap 20")
    }

    func testLegacySaveMetaInfersOneSemanticActionWithoutInventingHistory() throws {
        let data = Data(#"{"mutationCount":4,"lastAction":"returned","launchCount":2}"#.utf8)
        let decoded = try JSONDecoder().decode(SaveMeta.self, from: data)

        XCTAssertEqual(decoded.semanticActionTrail, ["returned"])
        XCTAssertEqual(decoded.lastAction, "returned")
    }

    /// A healthy relaunch is read-only: it must not disturb campaign state just to count itself.
    @MainActor
    func testRelaunchResumesExactly() async throws {
        let first = GameStore(io: io)
        first.mutate("mid-run", flush: true) { state in
            state.base.essence = 42
            state.reality.motes = 2
            state.worlds.runIndex = 3
        }
        let before = first.state

        let second = GameStore(io: io) // simulates a cold launch off the same file
        XCTAssertEqual(second.state.base, before.base)
        XCTAssertEqual(second.state.reality, before.reality)
        XCTAssertEqual(second.state.worlds, before.worlds)
        XCTAssertEqual(second.state.base, before.base)
        XCTAssertEqual(second.state.reality, before.reality)
        XCTAssertEqual(second.state.worlds, before.worlds)
        XCTAssertEqual(second.state.meta.mutationCount, before.meta.mutationCount)
        XCTAssertEqual(second.state.meta.launchCount, before.meta.launchCount)
        XCTAssertEqual(second.state.meta.lastAction, before.meta.lastAction)
    }

    /// The three-layer split has to be real, not aspirational.
    @MainActor
    func testResetBaseKeepsReality() throws {
        let store = GameStore(io: io)
        store.mutate("seed state", flush: true) { state in
            state.reality.motes = 9
            state.reality.discovery.recordCreature("paper_moth", runIndex: 1)
            state.base.essence = 500
            state.base.resources.add(10, of: Resources.ore)
        }

        store.resetBaseKeepingReality()

        XCTAssertEqual(store.state.reality.motes, 9)
        XCTAssertTrue(store.state.reality.discovery.hasEncountered(creature: "paper_moth"))
        XCTAssertEqual(store.state.base.essence, Tuning.Economy.startingEssence)
        XCTAssertEqual(store.state.base.resources[Resources.ore], 0)
        XCTAssertNil(store.state.worlds.activeRun)
    }

    func testFutureSchemaIsRejectedBeforeTolerantDecodeCanRewriteIt() throws {
        let future = Tuning.saveSchemaVersion + 1
        let data = Data("{\"schemaVersion\":\(future),\"base\":{\"essence\":999}}".utf8)
        XCTAssertThrowsError(try SaveCodec.decode(data)) { error in
            XCTAssertEqual(error as? Migrations.FutureSchemaError,
                           .init(found: future, supported: Tuning.saveSchemaVersion))
        }
    }

    func testSavedPageTemplatesRoundTripAndRepairMissingMonotonicCounters() throws {
        var state = GameState.newGame()
        let page = Page(runes: [
            PlacedRune(id: .init(rawValue: 88), content: .compound("plains"), hand: .crude,
                       origin: .init(column: 0, row: 0), shapeID: "crude_block")
        ])
        state.base.savedPageTemplates = [
            .init(id: .init(rawValue: 12), name: "Old road", page: page, creationOrdinal: 12)
        ]
        state.base.nextPageTemplateID = 19
        state.base.nextTemplateMarkID = PageTemplateRules.firstLoadedMarkID + 90

        let roundTrip = try SaveCodec.makeDecoder().decode(
            GameState.self, from: SaveCodec.makeEncoder().encode(state))
        XCTAssertEqual(roundTrip.base.savedPageTemplates, state.base.savedPageTemplates)
        XCTAssertEqual(roundTrip.base.nextPageTemplateID, 19)
        XCTAssertEqual(roundTrip.base.nextTemplateMarkID,
                       PageTemplateRules.firstLoadedMarkID + 90)

        var object = try XCTUnwrap(JSONSerialization.jsonObject(
            with: SaveCodec.makeEncoder().encode(state)) as? [String: Any])
        var base = try XCTUnwrap(object["base"] as? [String: Any])
        base.removeValue(forKey: "nextPageTemplateID")
        base.removeValue(forKey: "nextTemplateMarkID")
        object["base"] = base
        let repaired = try SaveCodec.makeDecoder().decode(
            GameState.self, from: JSONSerialization.data(withJSONObject: object))
        XCTAssertGreaterThan(repaired.base.nextPageTemplateID, 12)
        XCTAssertGreaterThan(repaired.base.nextTemplateMarkID, 88)
        XCTAssertGreaterThanOrEqual(repaired.base.nextTemplateMarkID,
                                    PageTemplateRules.firstLoadedMarkID)
        XCTAssertEqual(repaired.base.savedPageTemplates, state.base.savedPageTemplates)
    }

    func testLegacySaveWithoutTemplateFieldsDecodesToAnEmptyTemplateShelf() throws {
        let state = GameState.newGame()
        var object = try XCTUnwrap(JSONSerialization.jsonObject(
            with: SaveCodec.makeEncoder().encode(state)) as? [String: Any])
        var base = try XCTUnwrap(object["base"] as? [String: Any])
        base.removeValue(forKey: "savedPageTemplates")
        base.removeValue(forKey: "nextPageTemplateID")
        base.removeValue(forKey: "nextTemplateMarkID")
        object["base"] = base

        let decoded = try SaveCodec.makeDecoder().decode(
            GameState.self, from: JSONSerialization.data(withJSONObject: object))
        XCTAssertTrue(decoded.base.savedPageTemplates.isEmpty)
        XCTAssertEqual(decoded.base.nextPageTemplateID, 1)
        XCTAssertGreaterThanOrEqual(decoded.base.nextTemplateMarkID,
                                    PageTemplateRules.firstLoadedMarkID)
    }

    func testCompoundProofAndRecordsRoundTripDeduplicateAndRepairMonotonicIDs() throws {
        var state = GameState.newGame()
        let source = try XCTUnwrap(ContentCatalog.shared.pressureSources.first).id
        state.base.ownedSources.insert(source)
        let atom = CompoundSemanticAtom(Sigil(id: .init(rawValue: 4), source: source,
                                               target: "illumination"))
        let receipt = ProvenStatementReceipt(
            fingerprint: PageRules.statementFingerprint(target: "illumination", atoms: [atom]),
            target: "illumination", atoms: [atom],
            vocabulary: [.target("illumination"), .source(source)], vocabularySchemaVersion: 1,
            firstBoundRunIndex: 2)
        state.base.provenStatementReceipts = [receipt, receipt]
        state.base.personalCompounds = [
            .init(id: .init(rawValue: 41), nickname: "Old light",
                  provenFingerprint: receipt.fingerprint, target: receipt.target,
                  expansion: receipt.atoms, vocabulary: receipt.vocabulary,
                  vocabularySchemaVersion: 1, provenance: "Personal", creationOrdinal: 77)
        ]
        state.base.nextPersonalCompoundID = 2
        state.base.nextPersonalCompoundOrdinal = 3
        let decoded = try SaveCodec.makeDecoder().decode(
            GameState.self, from: SaveCodec.makeEncoder().encode(state))
        XCTAssertEqual(decoded.base.provenStatementReceipts, [receipt])
        XCTAssertEqual(decoded.base.personalCompounds, state.base.personalCompounds)
        XCTAssertGreaterThan(decoded.base.nextPersonalCompoundID, 41)
        XCTAssertGreaterThan(decoded.base.nextPersonalCompoundOrdinal, 77)

        var object = try XCTUnwrap(JSONSerialization.jsonObject(
            with: SaveCodec.makeEncoder().encode(GameState.newGame())) as? [String: Any])
        var base = try XCTUnwrap(object["base"] as? [String: Any])
        for key in ["provenStatementReceipts", "personalCompounds", "nextPersonalCompoundID",
                    "nextPersonalCompoundOrdinal"] { base.removeValue(forKey: key) }
        object["base"] = base
        let legacy = try SaveCodec.makeDecoder().decode(
            GameState.self, from: JSONSerialization.data(withJSONObject: object))
        XCTAssertTrue(legacy.base.provenStatementReceipts.isEmpty)
        XCTAssertTrue(legacy.base.personalCompounds.isEmpty)
        XCTAssertEqual(legacy.base.nextPersonalCompoundID, 1)
        XCTAssertEqual(legacy.base.nextPersonalCompoundOrdinal, 1)
    }

    func testInkRecipesAndSavedMixturesRoundTripWhileLegacyPagesRemainOpenColor() throws {
        var state = GameState.newGame()
        let recipe = InkRecipe(cyan: 20, magenta: 80, yellow: 5, depth: 10)
        state.base.page = Page(runes: [
            PlacedRune(id: .init(rawValue: 71), content: .source("sun"), hand: .plain,
                       origin: .init(column: 0, row: 0), shapeID: "plain_bar",
                       inkRecipe: recipe)
        ])
        state.base.savedInkMixtures = [
            .init(id: .init(rawValue: 8), name: "Dusk", recipe: recipe,
                  isPinned: true, lastUsedOrdinal: 14)
        ]
        state.base.nextInkMixtureID = 20
        state.base.nextFocusInkRecipe = recipe
        state.base.pigmentStock.add(7, of: .cyan)
        state.base.pigmentStock.add(3, of: .depth)
        state.base.preparedInkVials = [
            .init(id: 6, recipe: recipe, remainingApplications: 9)
        ]
        state.base.nextPreparedInkVialID = 12
        let encoded = try SaveCodec.makeEncoder().encode(state)
        let decoded = try SaveCodec.makeDecoder().decode(GameState.self, from: encoded)
        XCTAssertEqual(decoded.base.page.runes.first?.inkRecipe, recipe)
        XCTAssertEqual(decoded.base.savedInkMixtures, state.base.savedInkMixtures)
        XCTAssertEqual(decoded.base.nextInkMixtureID, 20)
        XCTAssertEqual(decoded.base.nextFocusInkRecipe, recipe)
        XCTAssertEqual(decoded.base.pigmentStock, state.base.pigmentStock)
        XCTAssertEqual(decoded.base.preparedInkVials, state.base.preparedInkVials)
        XCTAssertEqual(decoded.base.nextPreparedInkVialID, 12)

        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        var base = try XCTUnwrap(object["base"] as? [String: Any])
        base.removeValue(forKey: "savedInkMixtures")
        base.removeValue(forKey: "nextInkMixtureID")
        base.removeValue(forKey: "nextFocusInkRecipe")
        base.removeValue(forKey: "pigmentStock")
        base.removeValue(forKey: "preparedInkVials")
        base.removeValue(forKey: "nextPreparedInkVialID")
        if var page = base["page"] as? [String: Any],
           var runes = page["runes"] as? [[String: Any]] {
            for index in runes.indices { runes[index].removeValue(forKey: "inkRecipe") }
            page["runes"] = runes
            base["page"] = page
        }
        object["base"] = base
        let legacy = try SaveCodec.makeDecoder().decode(
            GameState.self, from: JSONSerialization.data(withJSONObject: object))
        XCTAssertNil(legacy.base.page.runes.first?.inkRecipe,
                     "missing ink means Ash/open, never explicit black")
        XCTAssertTrue(legacy.base.savedInkMixtures.isEmpty)
        XCTAssertEqual(legacy.base.nextInkMixtureID, 1)
        XCTAssertNil(legacy.base.nextFocusInkRecipe)
        XCTAssertEqual(legacy.base.pigmentStock, PigmentStock())
        XCTAssertTrue(legacy.base.preparedInkVials.isEmpty)
        XCTAssertEqual(legacy.base.nextPreparedInkVialID, 1)
    }

    // MARK: - Helpers

    @MainActor
    private func waitForDiskToCatchUp(_ store: GameStore, timeout: Duration = .seconds(2)) async throws {
        let deadline = ContinuousClock.now + timeout
        while ContinuousClock.now < deadline {
            if store.diagnostics.savedMutationCount == store.state.meta.mutationCount { return }
            try await Task.sleep(for: .milliseconds(10))
        }
        XCTFail("Disk never caught up with memory")
    }

    @MainActor
    private func waitUntil(timeout: Duration = .seconds(1), _ predicate: () -> Bool) async throws {
        let deadline = ContinuousClock.now + timeout
        while ContinuousClock.now < deadline {
            if predicate() { return }
            try await Task.sleep(for: .milliseconds(5))
        }
        XCTFail("Timed out waiting for launch state")
    }
}
