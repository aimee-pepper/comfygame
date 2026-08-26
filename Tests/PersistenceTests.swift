import XCTest
@testable import Bookbinder

/// The interruptibility pillar, tested. Anything that breaks here breaks pillar 2.
final class PersistenceTests: XCTestCase {

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
        if var roster = base["roster"] as? [[String: Any]] {
            for index in roster.indices { roster[index].removeValue(forKey: "persistentID") }
            base["roster"] = roster
        }
        root["base"] = base
        if var worlds = root["worlds"] as? [String: Any],
           var activeRun = worlds["activeRun"] as? [String: Any] {
            activeRun.removeValue(forKey: "companionHP")
            activeRun.removeValue(forKey: "healthCaps")
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
                   "activeRun":{"companionHP":{"0":12,"1":9},
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
        let samples = MaterialKind.allCases.enumerated().map { index, kind in
            MaterialSample(
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
        var base = try XCTUnwrap(root["base"] as? [String: Any])
        base.removeValue(forKey: "materialReserve")
        root["base"] = base
        var worlds = try XCTUnwrap(root["worlds"] as? [String: Any])
        var activeRun = try XCTUnwrap(worlds["activeRun"] as? [String: Any])
        activeRun.removeValue(forKey: "materialReserve")
        worlds["activeRun"] = activeRun
        root["worlds"] = worlds
        let legacyData = try JSONSerialization.data(withJSONObject: root)

        let migrated = try SaveCodec.decode(legacyData)
        let migratedRun = try XCTUnwrap(migrated.worlds.activeRun)
        let units = migrated.base.materialReserve.units + migratedRun.materialReserve.units

        XCTAssertEqual(units.count, samples.count)
        XCTAssertEqual(Set(units.map(\.sample.kind)), Set(MaterialKind.allCases))
        XCTAssertTrue(samples.allSatisfy { sample in
            units.filter { $0.sample == sample }.count == 1
        })
        XCTAssertEqual(Set(units.map(\.id)).count, units.count)
        let protectedSamples = samples.enumerated().compactMap {
            $0.offset.isMultiple(of: 2) ? $0.element : nil
        }
        XCTAssertEqual(units.filter(\.protectedReturn).count, protectedSamples.count)
        XCTAssertTrue(protectedSamples.allSatisfy { sample in
            units.contains { $0.protectedReturn && $0.sample == sample }
        })
        XCTAssertFalse(migrated.base.inventory.stacks.contains { $0.catalogID == Items.material })
        XCTAssertFalse(migrated.base.spillover.contains { $0.catalogID == Items.material })
        XCTAssertFalse(migratedRun.satchelItems.stacks.contains { $0.catalogID == Items.material })
        XCTAssertFalse(migratedRun.offeredItems.contains { $0.catalogID == Items.material })

        let canonical = try SaveCodec.encode(migrated)
        let relaunched = try SaveCodec.decode(canonical)
        XCTAssertEqual(relaunched, migrated)
        let relaunchedRun = try XCTUnwrap(relaunched.worlds.activeRun)
        let relaunchedUnits = relaunched.base.materialReserve.units
            + relaunchedRun.materialReserve.units
        XCTAssertEqual(relaunchedUnits.count, units.count)
        XCTAssertEqual(Set(relaunchedUnits.map(\.id)).count, relaunchedUnits.count)
        XCTAssertEqual(Set(relaunchedUnits.map(\.id)), Set(units.map(\.id)))
    }

    func testLegacyPencilAndChainingDecodeToCanonicalResearchAndReencodeCanonically() throws {
        let data = Data(#"{"completedResearch":["pen_pencil","pen_desk"],"hasChainingUnlock":true}"#.utf8)
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
        let data = Data(#"{"completedResearch":["pen_ink_mixing","pen_compounds","pen_chaining"]}"#.utf8)
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
            "capabilities": ["legacy_unknown_capability"]
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
        let data = Data(#"{"stations":{"tannery":{"isUnlocked":true,"tier":0},"weaponsmith":{"isUnlocked":true,"tier":0}}}"#.utf8)
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

    func testCorruptSaveFallsBackToBackupAndQuarantinesTheBadFile() throws {
        var good = GameState.newGame()
        good.base.essence = 555
        try io.write(SaveCodec.encode(good))
        // Second write rolls the first into .backup, then we corrupt the primary.
        try io.write(SaveCodec.encode(good))
        try Data("{ not json".utf8).write(to: io.saveURL)

        guard case .recoveredFromBackup(let recovered, _) = io.load() else {
            return XCTFail("Expected recovery from the backup file")
        }
        XCTAssertEqual(recovered.base.essence, 555)

        let quarantined = try FileManager.default
            .contentsOfDirectory(atPath: io.directory.path(percentEncoded: false))
            .filter { $0.contains("corrupt") }
        XCTAssertFalse(quarantined.isEmpty, "A bad save must be moved aside, never deleted")
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
