import Foundation

/// Save-schema migrations.
///
/// v0 is pre-release and the schema will churn, but a player's save should still survive a
/// rebuild wherever it reasonably can. Two lines of defence:
///  1. Every layer struct decodes tolerantly (`decodeIfPresent` + defaults), so *adding* a field
///     never breaks an old save.
///  2. This file, for changes tolerant decoding can't absorb — renames, restructures, unit changes.
///
/// To add one: bump `Tuning.saveSchemaVersion`, add a `case` to `step(_:from:)`, and a test in
/// `MigrationTests` that loads a fixture of the old shape.
enum Migrations {

    struct FutureSchemaError: Error, Equatable, CustomStringConvertible {
        let found: Int
        let supported: Int
        var description: String {
            "This campaign was saved by a newer Bookbinder build. Update Bookbinder to open it."
        }
    }

    static func migrateIfNeeded(_ data: Data) throws -> Data {
        let version = probeSchemaVersion(data) ?? Tuning.saveSchemaVersion
        guard version <= Tuning.saveSchemaVersion else {
            throw FutureSchemaError(found: version, supported: Tuning.saveSchemaVersion)
        }
        guard version < Tuning.saveSchemaVersion else {
            try validateCurrentChannelworksRestoration(in: data)
            try validateCurrentCombatOpening(in: data)
            try validateCurrentLibraryAttention(in: data)
            try validateCurrentExpeditionReviewQueue(in: data)
            try validateCurrentRecoveredTeachings(in: data)
            try validateCurrentCurioKnowledge(in: data)
            try validateCurrentAnimalTrust(in: data)
            try validateCurrentAnimalCompanionCombat(in: data)
            try validateCurrentPhysicalGearReceipts(in: data)
            try validateCurrentPhysicalGearOwnership(in: data)
            try validateCurrentRunExitCustody(in: data)
            try validateCurrentDebugVisibilityWorldIsolation(in: data)
            try validateCurrentEncounterSnapshots(in: data)
            try validateCurrentResourceNodeAuthority(in: data)
            return data
        }

        var working = data
        for from in version..<Tuning.saveSchemaVersion {
            working = try step(working, from: from)
        }
        try validateCurrentChannelworksRestoration(in: working)
        try validateCurrentCombatOpening(in: working)
        try validateCurrentLibraryAttention(in: working)
        try validateCurrentExpeditionReviewQueue(in: working)
        try validateCurrentRecoveredTeachings(in: working)
        try validateCurrentCurioKnowledge(in: working)
        try validateCurrentAnimalTrust(in: working)
        try validateCurrentAnimalCompanionCombat(in: working)
        try validateCurrentPhysicalGearReceipts(in: working)
        try validateCurrentPhysicalGearOwnership(in: working)
        try validateCurrentRunExitCustody(in: working)
        try validateCurrentDebugVisibilityWorldIsolation(in: working)
        try validateCurrentEncounterSnapshots(in: working)
        try validateCurrentResourceNodeAuthority(in: working)
        return working
    }

    /// Reads just `schemaVersion` without committing to the rest of the shape.
    static func probeSchemaVersion(_ data: Data) -> Int? {
        struct Probe: Decodable { var schemaVersion: Int? }
        return (try? JSONDecoder().decode(Probe.self, from: data))?.schemaVersion
    }

    /// Current saves must carry the identity-bearing encounter graph explicitly. Tolerant
    /// `EncounterState` defaults remain available only while an older schema is being migrated.
    private static func validateCurrentEncounterSnapshots(in data: Data) throws {
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw CocoaError(.coderInvalidValue)
        }
        guard let rawWorlds = root["worlds"] else { return }
        guard let worlds = rawWorlds as? [String: Any] else {
            throw CocoaError(.coderInvalidValue)
        }
        var runValues: [Any] = []
        if let active = worlds["activeRun"], !(active is NSNull) { runValues.append(active) }
        if let realms = worlds["anchoredRealms"] as? [[String: Any]] {
            runValues.append(contentsOf: realms.compactMap { $0["world"] })
        }
        for value in runValues {
            guard let run = value as? [String: Any] else { throw CocoaError(.coderInvalidValue) }
            guard let rawEncounter = run["activeEncounter"], !(rawEncounter is NSNull) else { continue }
            guard let encounter = rawEncounter as? [String: Any],
                  let foes = encounter["foes"] as? [Any], !foes.isEmpty,
                  encounter.keys.contains("partyNames"), !(encounter["partyNames"] is NSNull),
                  let order = encounter["order"] as? [Any], !order.isEmpty,
                  let slots = encounter["turnSlots"] as? [Any], !slots.isEmpty,
                  encounter.keys.contains("pressureOwners"),
                  !(encounter["pressureOwners"] is NSNull),
                  encounter.keys.contains("animalParticipants"),
                  !(encounter["animalParticipants"] is NSNull),
                  encounter.keys.contains("gearProjections"),
                  !(encounter["gearProjections"] is NSNull) else {
                throw CocoaError(.coderInvalidValue)
            }
        }
        let state = try SaveCodec.makeDecoder().decode(GameState.self, from: data)
        guard EncounterSnapshotRulesV1.validatesAll(in: state) else {
            throw CocoaError(.coderInvalidValue)
        }
    }

    private static func exactInt(_ value: Any?) throws -> Int {
        guard let number = value as? NSNumber,
              CFGetTypeID(number) != CFBooleanGetTypeID(),
              let parsed = Int(number.stringValue),
              Double(parsed) == number.doubleValue else {
            throw CocoaError(.coderInvalidValue)
        }
        return parsed
    }

    /// Current worlds must carry the extraction authority frozen by schema 3 -> 4. `ResourceNode`
    /// keeps tolerant optional decoding for isolated legacy values, but a live current world may
    /// never reach gameplay without the exact closed receipt.
    private static func validateCurrentResourceNodeAuthority(in data: Data) throws {
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let worlds = root["worlds"] as? [String: Any] else {
            throw CocoaError(.coderInvalidValue)
        }

        var runs: [[String: Any]] = []
        if let active = worlds["activeRun"], !(active is NSNull) {
            guard let run = active as? [String: Any] else { throw CocoaError(.coderInvalidValue) }
            runs.append(run)
        }
        if let rawRealms = worlds["anchoredRealms"] {
            guard let realms = rawRealms as? [[String: Any]] else {
                throw CocoaError(.coderInvalidValue)
            }
            for realm in realms {
                guard let run = realm["world"] as? [String: Any] else {
                    throw CocoaError(.coderInvalidValue)
                }
                runs.append(run)
            }
        }

        for run in runs {
            guard let map = run["map"] as? [String: Any],
                  let tiles = map["tiles"] as? [[String: Any]] else {
                throw CocoaError(.coderInvalidValue)
            }
            for tile in tiles {
                guard let content = tile["content"] as? [String: Any] else { continue }
                guard let rawNode = content["node"] else { continue }
                guard content.count == 1,
                      let associated = rawNode as? [String: Any],
                      associated.count == 1,
                      let node = associated["_0"] as? [String: Any],
                      let resourceRaw = node["resource"] as? String,
                      ContentCatalog.shared.resource(ResourceID(rawValue: resourceRaw)) != nil,
                      let rawReceipt = node["extractionRequirement"], !(rawReceipt is NSNull),
                      let receipt = rawReceipt as? [String: Any],
                      receipt["rulesVersion"] as? String
                        == ResourceExtractionRequirementReceiptV1.currentRulesVersion,
                      receipt["resourceID"] as? String == resourceRaw,
                      let dispositionRaw = receipt["disposition"] as? String,
                      let disposition = ResourceExtractionDisposition(rawValue: dispositionRaw) else {
                    throw CocoaError(.coderInvalidValue)
                }

                switch disposition {
                case .mineralNode:
                    guard Set(receipt.keys) == Set([
                        "rulesVersion", "resourceID", "disposition", "requiredExtractionRank"
                    ]),
                    let rank = try? exactInt(receipt["requiredExtractionRank"]),
                    (0...4).contains(rank) else {
                        throw CocoaError(.coderInvalidValue)
                    }
                case .floraPrimary:
                    guard Set(receipt.keys) == Set([
                        "rulesVersion", "resourceID", "disposition"
                    ]) else {
                        throw CocoaError(.coderInvalidValue)
                    }
                case .floraSecondary, .directPickup, .realityAward, .creatureMaterialOnly:
                    throw CocoaError(.coderInvalidValue)
                }
            }
        }
    }

    private static func validateCurrentCombatOpening(in data: Data) throws {
        let root = try JSONSerialization.jsonObject(with: data)
        let graph = ContentCatalog.shared.combatGraph
        let implemented = CombatGraphRules.implementedNodeIDs(in: graph)

        func integer(_ value: Any) throws -> Int {
            guard let number = value as? NSNumber,
                  CFGetTypeID(number) != CFBooleanGetTypeID(),
                  let parsed = Int(number.stringValue),
                  Double(parsed) == number.doubleValue, parsed >= 0 else {
                throw CocoaError(.coderInvalidValue)
            }
            return parsed
        }
        func validateCharacter(_ object: [String: Any]) throws {
            guard object["branchDepth"] == nil, object["freePoints"] == nil,
                  let rawOwned = object["ownedCombatNodeIDs"] as? [Any],
                  let rawChoices = object["combatNodeChoices"] as? [String: Any],
                  let rawPoints = object["unspentCombatPoints"] else {
                throw CocoaError(.coderInvalidValue)
            }
            var owned: Set<CombatNodeID> = []
            for raw in rawOwned {
                guard let string = raw as? String, !string.isEmpty else {
                    throw CocoaError(.coderInvalidValue)
                }
                let id = CombatNodeID(rawValue: string)
                guard implemented.contains(id), owned.insert(id).inserted else {
                    throw CocoaError(.coderInvalidValue)
                }
            }
            _ = try integer(rawPoints)
            var choices: [CombatNodeID: StableChoiceID] = [:]
            for (rawNode, rawChoice) in rawChoices {
                let nodeID = CombatNodeID(rawValue: rawNode)
                guard owned.contains(nodeID), let choiceString = rawChoice as? String,
                      let node = graph.node(nodeID), !node.purchaseChoices.isEmpty else {
                    throw CocoaError(.coderInvalidValue)
                }
                let choice = StableChoiceID(rawValue: choiceString)
                guard node.purchaseChoices.contains(choice), choices[nodeID] == nil else {
                    throw CocoaError(.coderInvalidValue)
                }
                choices[nodeID] = choice
            }
            for id in owned {
                guard let node = graph.node(id),
                      node.purchaseChoices.isEmpty || choices[id] != nil else {
                    throw CocoaError(.coderInvalidValue)
                }
            }
        }
        func walk(_ value: Any) throws {
            if let array = value as? [Any] {
                for child in array { try walk(child) }
                return
            }
            guard let object = value as? [String: Any] else { return }
            let isCharacter = object["ownedCombatNodeIDs"] != nil
                || object["combatNodeChoices"] != nil || object["unspentCombatPoints"] != nil
                || object["branchDepth"] != nil || object["freePoints"] != nil
            if isCharacter { try validateCharacter(object) }
            for child in object.values { try walk(child) }
        }
        try walk(root)
    }

    private static func step(_ data: Data, from version: Int) throws -> Data {
        switch version {
        case 1: return try migrate1to2(data)
        case 2: return try migrate2to3(data)
        case 3: return try migrate3to4(data)
        case 4: return try migrate4to5(data)
        case 5: return try migrate5to6(data)
        case 6: return try migrate6to7CreatureRewards(migrate6to7(data))
        case 7: return try migrate7to8(data)
        case 8: return try migrate8to9(data)
        case 9: return try migrate9to10(data)
        case 10: return try migrate10to11(data)
        case 11: return try migrate11to12(data)
        case 12: return try migrate12to13(data)
        case 13: return try migrate13to14(data)
        case 14: return try migrate14to15(data)
        case 15: return try migrate15to16(data)
        case 16: return try migrate16to17(data)
        case 17: return try migrate17to18(data)
        case 18: return try migrate18to19(data)
        case 19: return try migrate19to20(data)
        case 20: return try migrate20to21(data)
        default:
            // No migration registered. Tolerant decoding is the fallback; if the save is genuinely
            // incompatible, `SaveFileIO.load()` quarantines it rather than losing it.
            return data
        }
    }

    private static func migrate20to21(_ data: Data) throws -> Data {
        var state = try SaveCodec.makeDecoder().decode(GameState.self, from: data)
        guard state.schemaVersion == 20 else { throw CocoaError(.coderInvalidValue) }

        func install(in run: inout WorldRun) throws {
            guard var encounter = run.activeEncounter else { return }
            let expectedCount = encounter.scalingPreview?.wholePressureSlots ?? 0
            let rawPressure = encounter.turnSlots.filter {
                if case .ordinaryPressureFollowUp = $0.kind { return true }
                return false
            }
            guard rawPressure.count == expectedCount else { throw CocoaError(.coderInvalidValue) }
            let entries = try rawPressure.map { slot
                -> EncounterState.EncounterPressureOwnerReceiptV1.Entry in
                guard case .ordinaryPressureFollowUp(let ordinal) = slot.kind,
                      case .foe(let foeID) = slot.actor,
                      slot.strengthMultiplier == 0.55, slot.suppressesAfflictions,
                      encounter.foes.contains(where: { $0.id == foeID && !$0.isApex })
                else { throw CocoaError(.coderInvalidValue) }
                return .init(ordinal: ordinal, foeID: foeID)
            }.sorted { $0.ordinal < $1.ordinal }
            guard Set(entries.map(\.ordinal)).count == entries.count,
                  entries.map(\.ordinal) == Array(1..<(expectedCount + 1)) else {
                throw CocoaError(.coderInvalidValue)
            }
            encounter.pressureOwners = .init(entries: entries)
            run.activeEncounter = encounter
        }

        if var run = state.worlds.activeRun {
            try install(in: &run)
            state.worlds.activeRun = run
        }
        for index in state.worlds.anchoredRealms.indices {
            try install(in: &state.worlds.anchoredRealms[index].world)
        }
        state.schemaVersion = 21
        guard EncounterSnapshotRulesV1.validatesAll(in: state) else {
            throw CocoaError(.coderInvalidValue)
        }
        return try SaveCodec.encode(state)
    }

    private static func migrate19to20(_ data: Data) throws -> Data {
        guard var root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              try exactInt(root["schemaVersion"]) == 19,
              var base = root["base"] as? [String: Any],
              var pages = base["collectedWorldPages"] as? [Any] else {
            throw CocoaError(.coderInvalidValue)
        }
        var legacyIndices: [Int] = []
        for (index, value) in pages.enumerated() {
            guard let object = value as? [String: Any] else {
                throw CocoaError(.coderInvalidValue)
            }
            let reservedID = (try? exactInt(object["id"]))
                == Int(LegacyDebugVisibilityWorldV19.instanceID.rawValue)
            let definitionID = (object["definition"] as? [String: Any])?["id"] as? String
            let earthDefinition = definitionID == LegacyDebugVisibilityWorldV19.definitionID.rawValue
            guard reservedID || earthDefinition else { continue }
            let encoded = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
            let instance = try SaveCodec.makeDecoder().decode(WorldPageInstance.self, from: encoded)
            guard instance == LegacyDebugVisibilityWorldV19.instance else {
                throw CocoaError(.coderInvalidValue)
            }
            legacyIndices.append(index)
        }
        guard legacyIndices.count <= 1 else { throw CocoaError(.coderInvalidValue) }
        if let index = legacyIndices.first { pages.remove(at: index) }
        base["collectedWorldPages"] = pages
        root["base"] = base
        root["schemaVersion"] = 20
        return try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys])
    }

    private static func validateCurrentDebugVisibilityWorldIsolation(in data: Data) throws {
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let base = root["base"] as? [String: Any],
              let pages = base["collectedWorldPages"] as? [Any] else {
            throw CocoaError(.coderInvalidValue)
        }
        for value in pages {
            guard let object = value as? [String: Any] else {
                throw CocoaError(.coderInvalidValue)
            }
            if (try? exactInt(object["id"]))
                    == Int(LegacyDebugVisibilityWorldV19.instanceID.rawValue) {
                throw CocoaError(.coderInvalidValue)
            }
            if (object["definition"] as? [String: Any])?["id"] as? String
                    == LegacyDebugVisibilityWorldV19.definitionID.rawValue {
                throw CocoaError(.coderInvalidValue)
            }
        }
    }

    private static func migrate18to19(_ data: Data) throws -> Data {
        guard var root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              try exactInt(root["schemaVersion"]) == 18 else {
            throw CocoaError(.coderInvalidValue)
        }
        func migrate(_ value: Any) throws -> Any {
            if var object = value as? [String: Any] {
                let isSummary = object["runIndex"] != nil && object["haulKeptFraction"] != nil
                    && object["recoveredLines"] != nil && object["lostLines"] != nil
                if isSummary {
                    guard object["custodyReceiptVersion"] == nil else {
                        throw CocoaError(.coderInvalidValue)
                    }
                    object["custodyReceiptVersion"] = RunExitSummary.legacyCustodyReceiptVersion
                }
                for (key, child) in object { object[key] = try migrate(child) }
                return object
            }
            if let array = value as? [Any] { return try array.map(migrate) }
            return value
        }
        root = try migrate(root) as! [String: Any]
        root["schemaVersion"] = 19
        return try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys])
    }

    private static func validateCurrentRunExitCustody(in data: Data) throws {
        let root = try JSONSerialization.jsonObject(with: data)
        func walk(_ value: Any) throws {
            if let array = value as? [Any] {
                for child in array { try walk(child) }
                return
            }
            guard let object = value as? [String: Any] else { return }
            let isSummary = object["runIndex"] != nil && object["haulKeptFraction"] != nil
                && object["recoveredLines"] != nil && object["lostLines"] != nil
            if isSummary {
                let version = try exactInt(object["custodyReceiptVersion"])
                guard version == RunExitSummary.legacyCustodyReceiptVersion
                        || version == RunExitSummary.custodyReceiptVersionV1 else {
                    throw CocoaError(.coderInvalidValue)
                }
            }
            for child in object.values { try walk(child) }
        }
        try walk(root)
    }

    private static func migrate16to17(_ data: Data) throws -> Data {
        guard var root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              var base = root["base"] as? [String: Any],
              base["physicalGearOwnershipRevision"] == nil else {
            throw CocoaError(.coderInvalidValue)
        }
        base["physicalGearOwnershipRevision"] = 0
        root["base"] = base
        root["schemaVersion"] = 17
        return try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys])
    }

    private static func migrate17to18(_ data: Data) throws -> Data {
        guard var root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              try exactInt(root["schemaVersion"]) == 17 else {
            throw CocoaError(.coderInvalidValue)
        }
        func decode<T: Decodable>(_ type: T.Type, _ value: Any) throws -> T {
            try SaveCodec.makeDecoder().decode(type, from: JSONSerialization.data(
                withJSONObject: value, options: [.sortedKeys]))
        }
        func encoded<T: Encodable>(_ value: T) throws -> Any {
            try JSONSerialization.jsonObject(with: SaveCodec.makeEncoder().encode(value))
        }
        func migrateProfile(_ raw: [String: Any], catalogID: ItemID) throws -> [String: Any] {
            var profile = raw
            guard try exactInt(profile["version"]) == 3,
                  profile["gameplayFacts"] == nil,
                  let definition = ContentCatalog.shared.item(catalogID),
                  let gear = definition.gear else { throw CocoaError(.coderInvalidValue) }
            let stableID = try decode(InstanceID.self, profile["stableInstanceID"] as Any)
            let slot = try decode(GearSlot.self, profile["slot"] as Any)
            var band = try decode(CraftMaterialQualityBand.self, profile["qualityBand"] as Any)
            let tier = try exactInt(profile["constructionTier"])
            let damage: DamageKind? = profile["damage"] is NSNull ? nil
                : try decode(DamageKind.self, profile["damage"] as Any)
            let reach = try decode(Reach.self, profile["reach"] as Any)
            guard let insulation = (profile["insulation"] as? NSNumber)?.doubleValue,
                  let reactivity = (profile["reactivity"] as? NSNumber)?.doubleValue,
                  insulation.isFinite, reactivity.isFinite else { throw CocoaError(.coderInvalidValue) }
            let specialist = profile["specialistProfile"] is NSNull
                ? nil : profile["specialistProfile"] as? String
            let protectiveOffset: Double = switch specialist {
            case "armoury_rigid_shell": 0.5
            case "armoury_insulated_layer": -0.5
            case "armoury_balanced_laminate": 0
            case "armoury_balanced_laminate_v1": -0.5
            case "armoury_insulated_layer_v1": -1
            default: 0
            }
            let special = gear.breaks.flatMap { WildRule(rawValue: $0.rawValue) }.map {
                WildGearGameplayRuleV1(rule: $0, innateStatus: gear.statusKind,
                                       wardsAgainst: gear.wardsAgainst)
            }
            let legacyRank: Int? = switch catalogID.rawValue {
            case "bent_pick": 1
            case "balanced_pick": 2
            case "corebreaker": 3
            case "the_willing_edge": 4
            default: nil
            }
            let family = profile["familyID"] is NSNull ? nil : profile["familyID"] as? String
            let toolRank = family == PhysicalGearCraftingRules.fieldPick.id
                ? min(4, max(0, tier)) : legacyRank
            var receipt: PhysicalGearReceiptV1? = profile["physicalReceipt"] is NSNull ? nil
                : try decode(PhysicalGearReceiptV1.self, profile["physicalReceipt"] as Any)
            if var imported = receipt, imported.revisions.count == 1,
               case .legacyImported(_, _, let recipeVersion) = imported.revisions[0].authority,
               recipeVersion == 1 {
                let ranks = imported.revisions[0].components.map { $0.unit.qualityBand.rawValue }
                guard let primary = ranks.first else { throw CocoaError(.coderInvalidValue) }
                let secondary = ranks.count == 1 ? Double(primary)
                    : Double(ranks.dropFirst().reduce(0, +)) / Double(ranks.count - 1)
                let rank = Int((0.7 * Double(primary) + 0.3 * secondary).rounded())
                guard let reconstructed = CraftMaterialQualityBand(rawValue: rank) else {
                    throw CocoaError(.coderInvalidValue)
                }
                band = reconstructed
                profile["qualityBand"] = try encoded(reconstructed)
                imported.revisions[0].resultingQualityBand = reconstructed
                receipt = imported
            }
            let ordinal = receipt?.revisions.last?.ordinal ?? -1
            let digest: String
            if let latest = receipt?.revisions.last,
               let value = GearInstanceProfile.revisionDigest(latest) { digest = value }
            else { digest = GearInstanceProfile.sha256(
                "legacy-gear-gameplay-v1:\(stableID.rawValue):\(catalogID.rawValue)") }
            let facts = GearGameplayFactsV1(
                stableGearID: stableID, sourceRevisionOrdinal: ordinal,
                sourceRevisionDigest: digest, slot: slot, qualityBand: band,
                constructionTier: tier, powerOffset: 0,
                protectivePowerOffset: protectiveOffset, damageKind: damage,
                reach: reach, insulation: insulation, reactivity: reactivity,
                specialRule: special,
                toolCapability: toolRank.map { .init(
                    capabilityID: "extraction", rank: $0,
                    authorityID: GearToolCapabilityV1.extractionAuthorityID,
                    authorityVersion: 1) })
            if receipt != nil {
                receipt!.revisions[receipt!.revisions.count - 1].gameplayFacts = facts
                profile["physicalReceipt"] = try encoded(receipt!)
            }
            profile["gameplayFacts"] = try encoded(facts)
            profile["version"] = 4
            return profile
        }
        func walk(_ value: Any) throws -> Any {
            if let array = value as? [Any] { return try array.map(walk) }
            guard var object = value as? [String: Any] else { return value }
            if let rawProfile = object["gearProfile"] as? [String: Any],
               let rawCatalog = object["catalogID"] {
                object["gearProfile"] = try migrateProfile(
                    rawProfile, catalogID: decode(ItemID.self, rawCatalog))
            }
            for (key, child) in object where key != "gearProfile" {
                object[key] = try walk(child)
            }
            return object
        }
        root = try walk(root) as! [String: Any]
        root["schemaVersion"] = 18
        let provisional = try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys])
        var state = try SaveCodec.makeDecoder().decode(GameState.self, from: provisional)
        func freeze(_ encounter: inout EncounterState) throws {
            var projections: [Combatant: GearLoadoutProjectionV1] = [:]
            for actor in Set(encounter.order + encounter.turnSlots.map(\.actor)) {
                if actor.foeID != nil || encounter.animalParticipants?[actor] != nil { continue }
                let owner: PartyMember
                switch actor {
                case .binder: owner = .binder
                case .companion(let id): owner = .member(id)
                case .foe: continue
                }
                guard case .projected(let projection) =
                        GearGameplayProjectionRulesV1.project(owner: owner, in: state.base)
                else { throw CocoaError(.coderInvalidValue) }
                projections[actor] = projection
            }
            encounter.gearProjections = projections
        }
        if var run = state.worlds.activeRun, var encounter = run.activeEncounter {
            try freeze(&encounter)
            run.activeEncounter = encounter
            state.worlds.activeRun = run
        }
        for index in state.worlds.anchoredRealms.indices {
            guard var encounter = state.worlds.anchoredRealms[index].world.activeEncounter else { continue }
            try freeze(&encounter)
            state.worlds.anchoredRealms[index].world.activeEncounter = encounter
        }
        return try SaveCodec.makeEncoder().encode(state)
    }

    private static func validateCurrentPhysicalGearOwnership(in data: Data) throws {
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let base = root["base"] as? [String: Any],
              let value = base["physicalGearOwnershipRevision"] as? NSNumber,
              CFGetTypeID(value) != CFBooleanGetTypeID(),
              UInt64(value.stringValue) != nil,
              !value.stringValue.hasPrefix("-") else { throw CocoaError(.coderInvalidValue) }
        let state = try SaveCodec.makeDecoder().decode(GameState.self, from: data)
        func validates(_ encounter: EncounterState) -> Bool {
            guard let projections = encounter.gearProjections else { return false }
            let humans = Set((encounter.order + encounter.turnSlots.map(\.actor)).filter {
                $0.foeID == nil && encounter.animalParticipants?[$0] == nil
            })
            return Set(projections.keys) == humans && projections.allSatisfy { actor, loadout in
                loadout.owner.combatant == actor && loadout.validates()
            }
        }
        let encounters = [state.worlds.activeRun?.activeEncounter]
            + state.worlds.anchoredRealms.map { $0.world.activeEncounter }
        guard state.validatesPhysicalGearReceipts(),
              encounters.compactMap({ $0 }).allSatisfy(validates) else {
            throw CocoaError(.coderInvalidValue)
        }
    }

    private static func migrate15to16(_ data: Data) throws -> Data {
        guard var root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              try exactInt(root["schemaVersion"]) == 15 else {
            throw CocoaError(.coderInvalidValue)
        }
        func decode<T: Decodable>(_ type: T.Type, _ value: Any) throws -> T {
            try SaveCodec.makeDecoder().decode(type, from: JSONSerialization.data(
                withJSONObject: value, options: [.sortedKeys]))
        }
        func migrate(_ value: Any) throws -> Any {
            if let array = value as? [Any] { return try array.map(migrate) }
            guard var object = value as? [String: Any] else { return value }
            if try object["version"].map(exactInt) == 2,
               object["stableInstanceID"] != nil, object["constructionTier"] != nil,
               object["slot"] != nil {
                guard let rawSamples = object["consumedSamples"] as? [Any] else {
                    throw CocoaError(.coderInvalidValue)
                }
                let stableID = try decode(InstanceID.self, object["stableInstanceID"] as Any)
                let band = try decode(CraftMaterialQualityBand.self,
                                      object["qualityBand"] as Any)
                let tier = try exactInt(object["constructionTier"])
                let family = object["familyID"] is NSNull ? nil : object["familyID"] as? String
                let specialist = object["specialistProfile"] is NSNull
                    ? nil : object["specialistProfile"] as? String
                let recipe: Int? = if let value = object["recipeVersion"] {
                    value is NSNull ? nil : try exactInt(value)
                } else { nil }
                if rawSamples.isEmpty {
                    guard recipe == nil else { throw CocoaError(.coderInvalidValue) }
                    object["physicalReceipt"] = NSNull()
                } else {
                    guard recipe != nil else { throw CocoaError(.coderInvalidValue) }
                    let units = try rawSamples.map { try decode(CraftMaterialUnitV1.self, $0) }
                    let receipt = PhysicalGearReceiptV1(
                        gearInstanceID: stableID,
                        revisions: [.init(
                            ordinal: 0,
                            authority: .legacyImported(familyID: family,
                                                       specialistProfile: specialist,
                                                       recipeVersion: recipe),
                            components: units.enumerated().map {
                                .init(ordinal: $0.offset, role: .legacyOrdinal($0.offset),
                                      unit: $0.element)
                            }, resultingQualityBand: band,
                            resultingConstructionTier: tier)])
                    object["physicalReceipt"] = try JSONSerialization.jsonObject(
                        with: SaveCodec.makeEncoder().encode(receipt))
                }
                object.removeValue(forKey: "consumedSamples")
                object.removeValue(forKey: "recipeVersion")
                object["version"] = 3
                for key in ["familyID", "damage", "specialistProfile", "displayProvenance",
                            "authoredUniqueRuleID", "foundReceipt", "inscription"]
                    where object[key] == nil { object[key] = NSNull() }
                return object
            }
            if try object["version"].map(exactInt) == 3,
               object["stableInstanceID"] != nil, object["constructionTier"] != nil,
               object["slot"] != nil {
                guard object.keys.contains("physicalReceipt"),
                      object["consumedSamples"] == nil, object["recipeVersion"] == nil else {
                    throw CocoaError(.coderInvalidValue)
                }
                return object
            }
            for (key, child) in object { object[key] = try migrate(child) }
            return object
        }
        root = try migrate(root) as! [String: Any]
        root["schemaVersion"] = 16
        let migrated = try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys])
        try validateCurrentPhysicalGearReceipts(in: migrated)
        return migrated
    }

    private static func validateCurrentPhysicalGearReceipts(in data: Data) throws {
        let root = try JSONSerialization.jsonObject(with: data)
        let profileKeys: Set<String> = ["version", "stableInstanceID", "familyID",
            "constructionTier", "reforgeRank", "legacyPowerCredit", "qualityBand",
            "legacyEffectivePowerCredit", "slot", "damage", "reach", "insulation",
            "reactivity", "physicalReceipt", "specialistProfile", "displayProvenance",
            "authoredUniqueRuleID", "foundReceipt", "inscription", "gameplayFacts"]
        let gameplayFactKeys: Set<String> = ["version", "stableGearID",
            "sourceRevisionOrdinal", "sourceRevisionDigest", "slot", "qualityBand",
            "constructionTier", "powerOffset", "protectivePowerOffset", "damageKind", "reach",
            "insulation", "reactivity", "specialRule", "toolCapability"]
        let componentEffectFactKeys = gameplayFactKeys.union([
            "initiativeModifier", "heatWard", "valueModifier", "appliedContributionIDs"
        ])
        func validateGameplayFacts(_ value: Any) throws {
            let nullableFactKeys: Set<String> = ["damageKind", "specialRule", "toolCapability"]
            let contributionKeys: Set<String> = [
                "initiativeModifier", "heatWard", "valueModifier", "appliedContributionIDs"
            ]
            let requiredKeys = gameplayFactKeys.subtracting(nullableFactKeys)
            guard let facts = value as? [String: Any] else {
                throw CocoaError(.coderInvalidValue)
            }
            let keys = Set(facts.keys)
            guard requiredKeys.isSubset(of: keys), keys.isSubset(of: componentEffectFactKeys),
                  keys.intersection(contributionKeys).isEmpty
                    || contributionKeys.isSubset(of: keys),
                  nullableFactKeys.allSatisfy({ facts[$0].map { !($0 is NSNull) } ?? true }),
                  try exactInt(facts["version"]) == 1,
                  let digest = facts["sourceRevisionDigest"] as? String,
                  digest.count == 64,
                  digest.allSatisfy({ $0.isHexDigit && !$0.isUppercase }) else {
                throw CocoaError(.coderInvalidValue)
            }
            if contributionKeys.isSubset(of: keys) {
                guard let initiative = try? exactInt(facts["initiativeModifier"]),
                      (-1...0).contains(initiative),
                      let ward = try? exactInt(facts["heatWard"]),
                      [0, 5, 10, 15].contains(ward),
                      let value = facts["valueModifier"] as? NSNumber,
                      [0.0, 0.10, 0.20, 0.30].contains(value.doubleValue),
                      let ids = facts["appliedContributionIDs"] as? [String],
                      ids == Array(Set(ids)).sorted(),
                      Set(ids).isSubset(of: ["forceful", "heavy", "insulated", "keen"])
                else { throw CocoaError(.coderInvalidValue) }
            }
        }
        func validateReceipt(_ value: Any) throws {
            if value is NSNull { return }
            guard let receipt = value as? [String: Any],
                  Set(receipt.keys) == ["version", "gearInstanceID", "revisions"],
                  let revisions = receipt["revisions"] as? [[String: Any]], !revisions.isEmpty
            else { throw CocoaError(.coderInvalidValue) }
            for revision in revisions {
                let baseRevisionKeys: Set<String> = ["ordinal", "authority", "components",
                    "resultingQualityBand", "resultingConstructionTier"]
                guard Set(revision.keys) == baseRevisionKeys
                        || Set(revision.keys) == baseRevisionKeys.union(["gameplayFacts"]),
                      let authority = revision["authority"] as? [String: Any],
                      authority.count == 1,
                      let components = revision["components"] as? [[String: Any]],
                      !components.isEmpty else { throw CocoaError(.coderInvalidValue) }
                if let facts = revision["gameplayFacts"] {
                    try validateGameplayFacts(facts)
                }
                switch authority.first! {
                case ("construction", let payload), ("rebuild", let payload):
                    guard let object = payload as? [String: Any],
                          Set(object.keys) == ["stationID", authority.keys.first == "construction"
                            ? "schematicID" : "profileID", "rulesVersion"] else {
                        throw CocoaError(.coderInvalidValue)
                    }
                case ("legacyImported", let payload):
                    guard let object = payload as? [String: Any],
                          Set(object.keys) == ["familyID", "specialistProfile", "recipeVersion"]
                    else { throw CocoaError(.coderInvalidValue) }
                default: throw CocoaError(.coderInvalidValue)
                }
                for component in components {
                    guard Set(component.keys) == ["ordinal", "role", "unit"],
                          let role = component["role"] as? [String: Any], role.count == 1,
                          let payload = role.values.first as? [String: Any],
                          Set(payload.keys) == ["_0"] else { throw CocoaError(.coderInvalidValue) }
                }
            }
        }
        func inspect(_ value: Any) throws {
            if let array = value as? [Any] { try array.forEach(inspect); return }
            guard let object = value as? [String: Any] else { return }
            if let profile = object["gearProfile"] as? [String: Any] {
                guard Set(profile.keys) == profileKeys,
                      try exactInt(profile["version"]) == 4,
                      profile["gameplayFacts"] is [String: Any] else {
                    throw CocoaError(.coderInvalidValue)
                }
                try validateGameplayFacts(profile["gameplayFacts"] as Any)
                try validateReceipt(profile["physicalReceipt"] as Any)
            }
            try object.values.forEach(inspect)
        }
        try inspect(root)
        let decoded = try SaveCodec.makeDecoder().decode(GameState.self, from: data)
        guard decoded.validatesPhysicalGearReceipts() else { throw CocoaError(.coderInvalidValue) }
    }

    private static func migrate14to15(_ data: Data) throws -> Data {
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let base = root["base"] as? [String: Any],
              !base.keys.contains("tamedAnimalCompanions") else {
            throw CocoaError(.coderInvalidValue)
        }
        var state = try SaveCodec.makeDecoder().decode(GameState.self, from: data)
        guard state.schemaVersion == 14, state.base.tamedAnimalCompanions.isEmpty else {
            throw CocoaError(.coderInvalidValue)
        }
        for (rawID, animal) in state.reality.tamedAnimals.sorted(by: { $0.key < $1.key }) {
            let displayName = CreatureIdentity.name(for: animal.traits, in: .none)
            guard let receipt = AnimalCompanionCombatRules.originReceipt(
                animal: animal, displayName: displayName, icon: "questionmark",
                level: 1, provenance: .legacySchema14LevelOne) else {
                throw CocoaError(.coderInvalidValue)
            }
            let id = TamedAnimalID(rawValue: rawID)
            state.base.tamedAnimalCompanions[id] = .init(
                id: id, originReceipt: receipt, level: 1,
                experience: CharacterRules.experienceForLevel(1), gambits: [], posting: .menagerie)
        }
        state.schemaVersion = 15
        guard state.validatesAnimalCompanionCombat() else { throw CocoaError(.coderInvalidValue) }
        return try SaveCodec.makeEncoder().encode(state)
    }

    private static func validateCurrentAnimalCompanionCombat(in data: Data) throws {
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let base = root["base"] as? [String: Any],
              let raw = base["tamedAnimalCompanions"] as? [String: Any] else {
            throw CocoaError(.coderInvalidValue)
        }
        let stateKeys: Set<String> = ["version", "id", "originReceipt", "level", "experience",
                                      "gambits", "posting"]
        let receiptKeys: Set<String> = ["version", "derivationRulesVersion", "animalID",
            "frozenDisplayName", "levelOneStats", "reach", "startingLevel", "startingExperience",
            "instinctiveActionID", "dominantTechnique", "sourceProvenance"]
        for (key, value) in raw {
            guard let object = value as? [String: Any], Set(object.keys) == stateKeys,
                  object["id"] as? String == key,
                  let receipt = object["originReceipt"] as? [String: Any],
                  Set(receipt.keys) == receiptKeys,
                  receipt["animalID"] as? String == key else {
                throw CocoaError(.coderInvalidValue)
            }
        }
        let decoded = try SaveCodec.makeDecoder().decode(GameState.self, from: data)
        guard decoded.validatesAnimalCompanionCombat() else { throw CocoaError(.coderInvalidValue) }
    }

    private static func migrate13to14(_ data: Data) throws -> Data {
        guard var root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              var reality = root["reality"] as? [String: Any],
              !reality.keys.contains("animalTrustRecords"),
              !reality.keys.contains("tamedAnimals") else {
            throw CocoaError(.coderInvalidValue)
        }
        // Older migration fixtures are produced from the newest encoder and may therefore carry
        // a future empty field. Strip only that impossible-empty future shape before schema 14 is
        // constructed; a real schema-14 payload must still omit the field at 14→15.
        if var base = root["base"] as? [String: Any],
           let future = base["tamedAnimalCompanions"] {
            guard let empty = future as? [String: Any], empty.isEmpty else {
                throw CocoaError(.coderInvalidValue)
            }
            base.removeValue(forKey: "tamedAnimalCompanions")
            root["base"] = base
        }
        reality["animalTrustRecords"] = [:]
        reality["tamedAnimals"] = [:]
        root["reality"] = reality
        root["schemaVersion"] = 14
        return try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys])
    }

    private static func validateCurrentAnimalTrust(in data: Data) throws {
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let reality = root["reality"] as? [String: Any],
              let trust = reality["animalTrustRecords"] as? [String: Any],
              let tamed = reality["tamedAnimals"] as? [String: Any] else {
            throw CocoaError(.coderInvalidValue)
        }
        let trustRequired: Set<String> = ["version", "worldSeed", "enemyID", "traits",
            "condition", "progress", "firstAttendedRunIndex", "firstAttendedTurn",
            "interactionCount", "completed"]
        let trustAllowed = trustRequired.union(["speciesID", "creatureID", "lastProgressTurn"])
        for value in trust.values {
            guard let receipt = value as? [String: Any],
                  trustRequired.isSubset(of: Set(receipt.keys)),
                  Set(receipt.keys).isSubset(of: trustAllowed) else {
                throw CocoaError(.coderInvalidValue)
            }
        }
        let tamedRequired: Set<String> = ["version", "id", "originWorldSeed",
            "originEnemyID", "traits", "trustCondition", "joinedRunIndex", "joinedTurn"]
        let tamedAllowed = tamedRequired.union(["speciesID", "creatureID"])
        for value in tamed.values {
            guard let receipt = value as? [String: Any],
                  tamedRequired.isSubset(of: Set(receipt.keys)),
                  Set(receipt.keys).isSubset(of: tamedAllowed) else {
                throw CocoaError(.coderInvalidValue)
            }
        }
        let decoded = try SaveCodec.makeDecoder().decode(GameState.self, from: data)
        guard decoded.reality.animalTrustRecords.allSatisfy({ $0.value.validates(key: $0.key) }),
              decoded.reality.tamedAnimals.allSatisfy({ $0.value.validates(key: $0.key) }) else {
            throw CocoaError(.coderInvalidValue)
        }
    }

    private static func migrate12to13(_ data: Data) throws -> Data {
        guard var root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              var reality = root["reality"] as? [String: Any],
              !reality.keys.contains("curioFamilyKnowledge") else {
            throw CocoaError(.coderInvalidValue)
        }
        reality["curioFamilyKnowledge"] = [:]
        root["reality"] = reality
        root["schemaVersion"] = 13
        return try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys])
    }

    private static func validateCurrentCurioKnowledge(in data: Data) throws {
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let reality = root["reality"] as? [String: Any],
              let raw = reality["curioFamilyKnowledge"] as? [String: Any] else {
            throw CocoaError(.coderInvalidValue)
        }
        let exact = Set(["version", "familyID", "revealedItemID", "observationCount",
                         "firstResolutionRunIndex", "isRecognized"])
        for (family, value) in raw {
            guard let receipt = value as? [String: Any], Set(receipt.keys) == exact,
                  receipt["familyID"] as? String == family else {
                throw CocoaError(.coderInvalidValue)
            }
        }
        let decoded = try SaveCodec.makeDecoder().decode(GameState.self, from: data)
        guard decoded.reality.curioFamilyKnowledge.allSatisfy({
            $0.value.validates(key: $0.key)
        }) else { throw CocoaError(.coderInvalidValue) }
    }

    /// Replaces the overwrite-prone return receipt with a strict FIFO review queue while retaining
    /// the complete current RunExitSummary JSON unchanged.
    private static func migrate10to11(_ data: Data) throws -> Data {
        guard var root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw CocoaError(.coderInvalidValue)
        }
        let hasWorlds = root.keys.contains("worlds")
        guard !hasWorlds || root["worlds"] is [String: Any] else {
            throw CocoaError(.coderInvalidValue)
        }
        var worlds = root["worlds"] as? [String: Any] ?? [:]
        let outcomeSequence: UInt64
        if worlds.keys.contains("outcomeSequence") {
            guard let parsed = strictUInt64Number(worlds["outcomeSequence"]) else {
                throw CocoaError(.coderInvalidValue)
            }
            outcomeSequence = parsed
        } else {
            outcomeSequence = 0
            worlds["outcomeSequence"] = 0
        }

        guard !worlds.keys.contains("expeditionReviewQueue") else {
            throw CocoaError(.coderInvalidValue)
        }
        let legacySummary = worlds["lastExit"] is NSNull ? nil : worlds["lastExit"]
        var pending: [[String: Any]] = []
        if let legacySummary {
            guard let summary = legacySummary as? [String: Any],
                  let runIndex = strictNonnegativeInteger(summary["runIndex"]) else {
                throw CocoaError(.coderInvalidValue)
            }
            let reviewID: [String: Any]
            if let rawOutcome = summary["outcomeID"] {
                guard !(rawOutcome is NSNull),
                      let outcomeID = strictUInt64RawValue(rawOutcome) else {
                    throw CocoaError(.coderInvalidValue)
                }
                reviewID = ["kind": "outcome", "outcomeID": outcomeID]
                worlds["outcomeSequence"] = max(outcomeSequence, outcomeID)
            } else {
                reviewID = ["kind": "legacy", "legacyKey": "legacy-run-\(runIndex)"]
            }
            pending = [["reviewID": reviewID, "summary": summary]]
        }
        worlds["expeditionReviewQueue"] = [
            "schemaVersion": ExpeditionReviewQueueV1.schemaVersion,
            "pending": pending,
            "acknowledged": [],
        ]
        worlds.removeValue(forKey: "lastExit")
        root["worlds"] = worlds
        root["schemaVersion"] = 11
        let migrated = try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys])
        try validateCurrentExpeditionReviewQueue(in: migrated)
        _ = try SaveCodec.makeDecoder().decode(GameState.self, from: migrated)
        return migrated
    }

    private static func validateCurrentExpeditionReviewQueue(in data: Data) throws {
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let worlds = root["worlds"] as? [String: Any],
              !worlds.keys.contains("lastExit"),
              let sequence = strictUInt64Number(worlds["outcomeSequence"]),
              let queue = worlds["expeditionReviewQueue"] as? [String: Any],
              Set(queue.keys) == Set(["schemaVersion", "pending", "acknowledged"]) else {
            throw CocoaError(.coderInvalidValue)
        }
        guard let pending = queue["pending"] as? [[String: Any]],
              let acknowledged = queue["acknowledged"] as? [[String: Any]] else {
            throw CocoaError(.coderInvalidValue)
        }
        func validateIdentityShape(_ identity: [String: Any]) throws {
            guard let kind = identity["kind"] as? String else {
                throw CocoaError(.coderInvalidValue)
            }
            switch kind {
            case "outcome":
                guard Set(identity.keys) == Set(["kind", "outcomeID"]),
                      let raw = identity["outcomeID"],
                      strictUInt64RawValue(raw) != nil else {
                    throw CocoaError(.coderInvalidValue)
                }
            case "legacy":
                guard Set(identity.keys) == Set(["kind", "legacyKey"]),
                      let key = identity["legacyKey"] as? String, !key.isEmpty else {
                    throw CocoaError(.coderInvalidValue)
                }
            default:
                throw CocoaError(.coderInvalidValue)
            }
        }
        for review in pending {
            guard Set(review.keys) == Set(["reviewID", "summary"]),
                  let identity = review["reviewID"] as? [String: Any],
                  review["summary"] is [String: Any] else {
                throw CocoaError(.coderInvalidValue)
            }
            try validateIdentityShape(identity)
        }
        for identity in acknowledged { try validateIdentityShape(identity) }
        let queueData = try JSONSerialization.data(withJSONObject: queue, options: [.sortedKeys])
        let decoded = try SaveCodec.makeDecoder().decode(ExpeditionReviewQueueV1.self,
                                                          from: queueData)
        try decoded.validate(outcomeSequence: sequence)
    }

    private static func strictNonnegativeInteger(_ value: Any?) -> Int? {
        guard let number = value as? NSNumber,
              CFGetTypeID(number) != CFBooleanGetTypeID(),
              let result = Int(number.stringValue), result >= 0,
              Double(result) == number.doubleValue else { return nil }
        return result
    }

    private static func strictUInt64Number(_ value: Any?) -> UInt64? {
        guard let number = value as? NSNumber,
              CFGetTypeID(number) != CFBooleanGetTypeID(),
              let result = UInt64(number.stringValue),
              Double(result) == number.doubleValue else { return nil }
        return result
    }

    private static func strictUInt64RawValue(_ value: Any) -> UInt64? {
        if let scalar = strictUInt64Number(value) { return scalar }
        guard let object = value as? [String: Any], object.count == 1 else { return nil }
        return strictUInt64Number(object["rawValue"])
    }

    private static func migrate11to12(_ data: Data) throws -> Data {
        guard var root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              var reality = root["reality"] as? [String: Any],
              var library = reality["library"] as? [String: Any] else {
            throw CocoaError(.coderInvalidValue)
        }
        library["recoveredTeachings"] = []
        library["recoveredTeachingOffers"] = []
        library["nextRecoveredTeachingSequence"] = 0
        reality["library"] = library
        root["reality"] = reality
        root["schemaVersion"] = 12
        let staged = try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys])
        var state = try SaveCodec.makeDecoder().decode(GameState.self, from: staged)
        let removedBranches: Set<ResearchBranchID> = ["instruction", "hand", "lexicon", "bargain"]
        let completed = ContentCatalog.shared.researchNodes
            .filter { removedBranches.contains($0.branch) && state.base.completedResearch.contains($0.id) }
            .flatMap(\.grants)
        for grant in completed {
            let reward: RecoveredTeachingReward?
            switch grant.kind {
            case .gambitComponent:
                reward = grant.id.map { .init(kind: .gambitComponent, id: $0) }
            case .symbol:
                reward = grant.id.map { .init(kind: .symbol, id: $0) }
            case .focus:
                reward = grant.id.map { .init(kind: .focus, id: $0) }
            case .effect where grant.effect == .automateSelf:
                reward = .init(kind: .capability, id: "automate_self")
            default:
                reward = nil // Legacy Gambit-slot credits and unrelated grants remain as stored.
            }
            guard let reward,
                  let definition = RecoveredTeachingCatalogueV1.definitions.first(where: {
                      $0.reward == reward
                  }),
                  !state.reality.library.recoveredTeachings.contains(where: {
                      $0.teachingID == definition.id
                  }) else { continue }
            let recoveredAt = state.reality.library.nextRecoveredTeachingSequence
            state.reality.library.nextRecoveredTeachingSequence += 1
            let readAt = state.reality.library.nextRecoveredTeachingSequence
            state.reality.library.nextRecoveredTeachingSequence += 1
            state.reality.library.recoveredTeachings.append(.init(
                teachingID: definition.id, catalogueVersion: 1,
                rewardKind: reward.kind, rewardID: reward.id,
                recoveredAtOutcomeID: nil, worldSeed: nil,
                sourcePlacementIdentity: "migration:completed-research",
                recoveredAt: recoveredAt, readAt: readAt,
                frozenTitle: definition.title,
                frozenInstructionCopy: definition.instructionCopy))
            state.reality.library.attention.checkedContentIDs.insert(
                .recoveredTeaching(definition.id))
        }
        let encoded = try SaveCodec.makeEncoder().encode(state)
        guard var root = try JSONSerialization.jsonObject(with: encoded) as? [String: Any],
              var reality = root["reality"] as? [String: Any] else {
            throw CocoaError(.coderInvalidValue)
        }
        // The current model already knows schema-13 fields. Keep the schema-12 intermediate
        // truthful so the next migration remains the sole owner of introducing Curio knowledge.
        reality.removeValue(forKey: "curioFamilyKnowledge")
        root["reality"] = reality
        root["schemaVersion"] = 12
        return try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys])
    }

    private static func validateCurrentRecoveredTeachings(in data: Data) throws {
        let root = try JSONSerialization.jsonObject(with: data)
        guard let object = root as? [String: Any],
              let reality = object["reality"] as? [String: Any],
              let library = reality["library"] as? [String: Any] else {
            throw CocoaError(.coderInvalidValue)
        }
        for key in ["recoveredTeachings", "recoveredTeachingOffers"] {
            guard let value = library[key], !(value is NSNull), value is [Any] else {
                throw CocoaError(.coderInvalidValue)
            }
        }
        guard let rawSequence = library["nextRecoveredTeachingSequence"] as? NSNumber,
              CFGetTypeID(rawSequence) != CFBooleanGetTypeID(),
              rawSequence.doubleValue >= 0,
              rawSequence.doubleValue.rounded() == rawSequence.doubleValue else {
            throw CocoaError(.coderInvalidValue)
        }
        let recordRequired: Set<String> = [
            "teachingID", "catalogueVersion", "rewardKind", "rewardID",
            "sourcePlacementIdentity", "recoveredAt", "frozenTitle", "frozenInstructionCopy",
        ]
        let recordAllowed = recordRequired.union([
            "recoveredAtOutcomeID", "worldSeed", "readAt",
        ])
        var seenRecords = Set<String>()
        for raw in library["recoveredTeachings"] as! [Any] {
            guard let receipt = raw as? [String: Any],
                  recordRequired.isSubset(of: Set(receipt.keys)),
                  Set(receipt.keys).isSubset(of: recordAllowed),
                  !receipt.values.contains(where: { $0 is NSNull }),
                  let teachingID = receipt["teachingID"] as? String,
                  let rewardKind = receipt["rewardKind"] as? String,
                  let rewardID = receipt["rewardID"] as? String,
                  seenRecords.insert(teachingID).inserted,
                  let authority = RecoveredTeachingCatalogueV1.reward(
                    for: .init(rawValue: teachingID)),
                  authority.kind.rawValue == rewardKind, authority.id == rewardID else {
                throw CocoaError(.coderInvalidValue)
            }
        }
        let offerRequired: Set<String> = [
            "version", "teachingID", "eligibleWorldsWithoutOffer", "isDue",
        ]
        let offerAllowed = offerRequired.union(["firstEligibleOutcomeIndex"])
        var seenOffers = Set<String>()
        for raw in library["recoveredTeachingOffers"] as! [Any] {
            guard let receipt = raw as? [String: Any],
                  offerRequired.isSubset(of: Set(receipt.keys)),
                  Set(receipt.keys).isSubset(of: offerAllowed),
                  !receipt.values.contains(where: { $0 is NSNull }),
                  let teachingID = receipt["teachingID"] as? String,
                  RecoveredTeachingCatalogueV1.reward(for: .init(rawValue: teachingID)) != nil,
                  seenOffers.insert(teachingID).inserted else {
                throw CocoaError(.coderInvalidValue)
            }
        }
    }

    private static func migrate9to10(_ data: Data) throws -> Data {
        guard var root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw CocoaError(.coderInvalidValue)
        }
        root["schemaVersion"] = 10
        let staged = try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys])
        var state = try SaveCodec.makeDecoder().decode(GameState.self, from: staged)
        state.schemaVersion = 10
        state.reality.library.attention = LibraryAttentionStateV1(
            checkedContentIDs: LibraryShelfPresentation.currentContentIDs(in: state))
        // Re-encoding with current models would otherwise leak schema-11/12 fields backward into
        // the intermediate schema-10 bytes and make the next strict migration reject its own
        // input. Preserve the legacy single return receipt explicitly, then strip only fields
        // whose owning migration has not run yet.
        var encoded = try JSONSerialization.jsonObject(
            with: SaveCodec.makeEncoder().encode(state)) as! [String: Any]
        var worlds = encoded["worlds"] as! [String: Any]
        worlds.removeValue(forKey: "expeditionReviewQueue")
        if let summary = state.worlds.lastExit {
            worlds["lastExit"] = try JSONSerialization.jsonObject(
                with: SaveCodec.makeEncoder().encode(summary))
        }
        encoded["worlds"] = worlds
        var encodedReality = encoded["reality"] as! [String: Any]
        var encodedLibrary = encodedReality["library"] as! [String: Any]
        encodedLibrary.removeValue(forKey: "recoveredTeachings")
        encodedLibrary.removeValue(forKey: "recoveredTeachingOffers")
        encodedLibrary.removeValue(forKey: "nextRecoveredTeachingSequence")
        encodedReality["library"] = encodedLibrary
        encoded["reality"] = encodedReality
        return try JSONSerialization.data(withJSONObject: encoded, options: [.sortedKeys])
    }

    private static func validateCurrentLibraryAttention(in data: Data) throws {
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let reality = root["reality"] as? [String: Any],
              let library = reality["library"] as? [String: Any],
              let attention = library["attention"] as? [String: Any],
              Set(attention.keys) == Set(["version", "checkedContentIDs"]),
              let version = attention["version"] as? NSNumber,
              CFGetTypeID(version) != CFBooleanGetTypeID(), version.intValue == 1,
              let rawIDs = attention["checkedContentIDs"] as? [Any] else {
            throw CocoaError(.coderInvalidValue)
        }
        let ids = try rawIDs.map { raw -> LibraryAttentionContentID in
            let encoded = try JSONSerialization.data(withJSONObject: raw)
            return try SaveCodec.makeDecoder().decode(LibraryAttentionContentID.self, from: encoded)
        }
        guard Set(ids).count == ids.count else { throw CocoaError(.coderInvalidValue) }
    }

    private static func migrate8to9(_ data: Data) throws -> Data {
        guard var root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              var base = root["base"] as? [String: Any],
              let stations = base["stations"] as? [String: Any] else {
            throw CocoaError(.coderInvalidValue)
        }
        let unlocked = ((stations[Stations.channelworks.rawValue] as? [String: Any])?["isUnlocked"]
                        as? Bool) == true
        let hasLegacy = base.keys.contains("odaFixtureRestored")
        let legacy: Bool?
        if hasLegacy {
            guard !(base["odaFixtureRestored"] is NSNull),
                  let value = base["odaFixtureRestored"] as? Bool else {
                throw CocoaError(.coderInvalidValue)
            }
            legacy = value
        } else { legacy = nil }
        if !unlocked {
            guard legacy != true else { throw CocoaError(.coderInvalidValue) }
            base.removeValue(forKey: "odaFixtureRestored")
            base.removeValue(forKey: "channelworksRestoration")
            root["base"] = base; root["schemaVersion"] = 9
            return try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys])
        }

        func stacks(_ value: Any?) -> [[String: Any]] { value as? [[String: Any]] ?? [] }
        let inventory = base["inventory"] as? [String: Any]
        let stored = stacks(inventory?["stacks"])
        let waiting = stacks(base["spillover"])
        var liveStacks = stored + waiting
        if let worlds = root["worlds"] as? [String: Any] {
            func appendRun(_ run: [String: Any]?) {
                guard let run else { return }
                if let satchel = run["satchelItems"] as? [String: Any] {
                    liveStacks += stacks(satchel["stacks"])
                }
                liveStacks += stacks(run["offeredItems"])
            }
            appendRun(worlds["activeRun"] as? [String: Any])
            for realm in worlds["anchoredRealms"] as? [[String: Any]] ?? [] {
                appendRun(realm["world"] as? [String: Any])
            }
        }
        let candidates = liveStacks.compactMap { object -> UInt64? in
            guard object["catalogID"] as? String == Items.conduitFixture.rawValue,
                  let coreObject = object["distilledCore"],
                  let coreData = try? JSONSerialization.data(withJSONObject: coreObject),
                  let core = try? SaveCodec.makeDecoder().decode(DistilledCore.self, from: coreData),
                  core == ChannelworksRestorationRules.authoredCore,
                  let raw = (object["id"] as? [String: Any])?["rawValue"] as? NSNumber,
                  raw.uint64Value > 0 else { return nil }
            return raw.uint64Value
        }
        var fixtureID = candidates.min().map(InstanceID.init(rawValue:))
        if fixtureID == nil && legacy != true {
            func maximumID(_ value: Any) -> UInt64 {
                if let array = value as? [Any] { return array.map(maximumID).max() ?? 0 }
                guard let object = value as? [String: Any] else { return 0 }
                let own = ((object["id"] as? [String: Any])?["rawValue"] as? NSNumber)?.uint64Value ?? 0
                return max(own, object.values.map(maximumID).max() ?? 0)
            }
            let maximum = maximumID(root)
            guard maximum < UInt64.max else { throw CocoaError(.coderInvalidValue) }
            let id = InstanceID(rawValue: maximum + 1)
            let fixture = ItemStack(id: id, catalogID: Items.conduitFixture,
                                    distilledCore: ChannelworksRestorationRules.authoredCore)
            let fixtureObject = try JSONSerialization.jsonObject(with: SaveCodec.makeEncoder().encode(fixture))
            var mutableInventory = inventory ?? [:]
            var mutableStored = stored
            let slots = mutableInventory["slots"] as? Int ?? Tuning.Economy.startingInventorySlots
            if mutableStored.count < slots {
                mutableStored.append(fixtureObject as! [String: Any])
                mutableInventory["stacks"] = mutableStored; base["inventory"] = mutableInventory
            } else {
                var mutableWaiting = waiting; mutableWaiting.append(fixtureObject as! [String: Any])
                base["spillover"] = mutableWaiting
            }
            fixtureID = id
        }
        let receipt = ChannelworksRestorationReceiptV1(fixtureInstanceID: fixtureID)
        base["channelworksRestoration"] = try JSONSerialization.jsonObject(
            with: SaveCodec.makeEncoder().encode(receipt))
        base.removeValue(forKey: "odaFixtureRestored")
        root["base"] = base; root["schemaVersion"] = 9
        return try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys])
    }

    private static func validateCurrentChannelworksRestoration(in data: Data) throws {
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let base = root["base"] as? [String: Any],
              let stations = base["stations"] as? [String: Any] else {
            throw CocoaError(.coderInvalidValue)
        }
        guard !base.keys.contains("odaFixtureRestored") else { throw CocoaError(.coderInvalidValue) }
        let unlocked = ((stations[Stations.channelworks.rawValue] as? [String: Any])?["isUnlocked"]
                        as? Bool) == true
        let present = base.keys.contains("channelworksRestoration")
        guard unlocked == present else { throw CocoaError(.coderInvalidValue) }
        guard present else { return }
        guard let value = base["channelworksRestoration"], !(value is NSNull),
              let object = value as? [String: Any],
              Set(object.keys) == Set(["version", "entitlementID", "restorerID", "stationID",
                                       "fixtureCatalogueID", "fixtureInstanceID", "fixtureCore"]),
              let receipt = try? SaveCodec.makeDecoder().decode(
                ChannelworksRestorationReceiptV1.self,
                from: JSONSerialization.data(withJSONObject: object)), receipt.validates() else {
            throw CocoaError(.coderInvalidValue)
        }
    }

    private static func migrate7to8(_ data: Data) throws -> Data {
        guard var root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw CocoaError(.coderInvalidValue)
        }
        let authoredBands: [String: Int] = [
            "rubble_sling": 1, "ironwork_blade": 2, "copper_buckler": 2,
            "silvered_helm": 3, "golden_keepsake": 3, "quartz_point": 2,
            "obsidian_edge": 3, "adamant_cuirass": 4, "woven_sling": 1,
            "timber_longbow": 1, "resinbound_boots": 1, "riftglass_rapier": 4,
        ]
        func exactInt(_ value: Any?) throws -> Int {
            guard let number = value as? NSNumber,
                  CFGetTypeID(number) != CFBooleanGetTypeID(),
                  !CFNumberIsFloatType(number),
                  number.doubleValue.isFinite,
                  number.doubleValue.rounded(.towardZero) == number.doubleValue,
                  number.doubleValue >= Double(Int.min),
                  number.doubleValue <= Double(Int.max) else {
                throw CocoaError(.coderInvalidValue)
            }
            return number.intValue
        }
        func migrate(_ value: Any) throws -> Any {
            if let array = value as? [Any] { return try array.map(migrate) }
            guard var object = value as? [String: Any] else { return value }
            for (key, child) in object { object[key] = try migrate(child) }
            if let catalogID = object["catalogID"] as? String,
               let definition = ContentCatalog.shared.item(ItemID(rawValue: catalogID)),
               definition.gear != nil {
                if object["gearProfile"] == nil {
                    guard let rawID = (object["id"] as? [String: Any])?["rawValue"] as? NSNumber,
                          CFGetTypeID(rawID) != CFBooleanGetTypeID(), rawID.uint64Value > 0,
                          Double(rawID.uint64Value) == rawID.doubleValue else {
                        throw CocoaError(.coderInvalidValue)
                    }
                    let upgrade: Int
                    if object.keys.contains("upgradeLevel") {
                        guard !(object["upgradeLevel"] is NSNull) else {
                            throw CocoaError(.coderInvalidValue)
                        }
                        upgrade = try exactInt(object["upgradeLevel"])
                    } else {
                        upgrade = 0
                    }
                    guard upgrade >= 0 else { throw CocoaError(.coderInvalidValue) }
                    let synthesized = GearInstanceProfile(
                        stableInstanceID: .init(rawValue: rawID.uint64Value),
                        definition: definition, legacyUpgradeLevel: upgrade)
                    object["gearProfile"] = try JSONSerialization.jsonObject(
                        with: SaveCodec.makeEncoder().encode(synthesized))
                    return object
                }
                guard var profile = object["gearProfile"] as? [String: Any] else {
                    throw CocoaError(.coderInvalidValue)
                }
                let version = try exactInt(profile["version"])
                let tier = try exactInt(profile["constructionTier"])
                let credit = try exactInt(profile["legacyPowerCredit"])
                guard version == 1, (1...4).contains(tier), credit >= 0 else {
                    throw CocoaError(.coderInvalidValue)
                }
                if profile.keys.contains("reforgeRank") {
                    guard !(profile["reforgeRank"] is NSNull),
                          (0...3).contains(try exactInt(profile["reforgeRank"])) else {
                        throw CocoaError(.coderInvalidValue)
                    }
                }
                guard !profile.keys.contains("foundReceipt") else {
                    throw CocoaError(.coderInvalidValue)
                }
                let hasRecipe = profile.keys.contains("recipeVersion")
                let hasSamples = profile.keys.contains("consumedSamples")
                let samples: [Any]
                if hasSamples {
                    guard !(profile["consumedSamples"] is NSNull),
                          let decoded = profile["consumedSamples"] as? [Any] else {
                        throw CocoaError(.coderInvalidValue)
                    }
                    samples = decoded
                } else {
                    samples = []
                }
                var constructed = false
                if hasRecipe {
                    guard !(profile["recipeVersion"] is NSNull),
                          try exactInt(profile["recipeVersion"]) >= 0,
                          hasSamples, !samples.isEmpty else {
                        throw CocoaError(.coderInvalidValue)
                    }
                    constructed = true
                } else if !samples.isEmpty {
                    throw CocoaError(.coderInvalidValue)
                }
                let band = constructed ? tier : (authoredBands[catalogID] ?? tier)
                guard (1...4).contains(band), tier + credit >= band else {
                    throw CocoaError(.coderInvalidValue)
                }
                profile["version"] = 2
                profile["qualityBand"] = band
                profile["legacyEffectivePowerCredit"] = tier + credit - band
                if !constructed, let receipt = definition.gearCatalogueDisposition?.foundReceipt {
                    profile["foundReceipt"] = try JSONSerialization.jsonObject(
                        with: SaveCodec.makeEncoder().encode(receipt))
                }
                object["gearProfile"] = profile
            } else if object["gearProfile"] != nil {
                throw CocoaError(.coderInvalidValue)
            }
            return object
        }
        root = try migrate(root) as! [String: Any]
        root["schemaVersion"] = 8
        return try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys])
    }

    /// Replaces the mixed continuous-grade material graph with two exact domain reserves and
    /// immutable six-band units before any schema-7 model is constructed.
    private static func migrate6to7(_ data: Data) throws -> Data {
        guard var root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw CocoaError(.coderInvalidValue)
        }
        let creatureFamilies: Set<String> = [
            "plate", "quill", "pelt", "down", "hide", "chitin", "feather", "fin",
            "scale", "oil", "shell", "horn", "venom", "fang", "tusk", "claw", "bone", "ichor",
        ]
        let worldFamilies: Set<String> = ["timber", "fibre", "pulp", "toxin", "reagent"]

        func integerGrade(_ value: Any?) throws -> Double {
            guard let number = value as? NSNumber,
                  CFGetTypeID(number) != CFBooleanGetTypeID(), number.doubleValue.isFinite,
                  (0...100).contains(number.doubleValue) else { throw CocoaError(.coderInvalidValue) }
            return number.doubleValue
        }
        func stableHash(_ text: String) -> UInt64 {
            var hash: UInt64 = 0xcbf29ce484222325
            for byte in text.utf8 { hash ^= UInt64(byte); hash = hash &* 0x100000001b3 }
            return hash
        }
        func rawInstanceID(_ value: Any?) throws -> String {
            guard let value else { return "none" }
            if let object = value as? [String: Any] {
                if let string = object["rawValue"] as? String, !string.isEmpty { return string }
                if let number = object["rawValue"] as? NSNumber,
                   CFGetTypeID(number) != CFBooleanGetTypeID(), number.doubleValue.rounded() == number.doubleValue,
                   number.doubleValue >= 0 { return number.stringValue }
            }
            throw CocoaError(.coderInvalidValue)
        }
        func unitJSON(sample: [String: Any], location: String, identity: String) throws -> Any {
            let allowed = Set(["kind", "properties", "grade", "source", "qualifier"])
            guard Set(sample.keys).isSubset(of: allowed),
                  let familyRaw = sample["kind"] as? String,
                  let family = MaterialFamilyID(rawValue: familyRaw),
                  let propertiesValue = sample["properties"],
                  let source = sample["source"] as? String else { throw CocoaError(.coderInvalidValue) }
            let domain: CraftMaterialDomain
            if creatureFamilies.contains(familyRaw) { domain = .creature }
            else if worldFamilies.contains(familyRaw) { domain = .world }
            else { throw CocoaError(.coderInvalidValue) }
            let grade = try integerGrade(sample["grade"])
            let properties = try SaveCodec.makeDecoder().decode(
                MaterialProperties.self,
                from: JSONSerialization.data(withJSONObject: propertiesValue))
            guard properties.values.allSatisfy({ $0.isFinite && (0...100).contains($0) }) else {
                throw CocoaError(.coderInvalidValue)
            }
            let qualifier: String?
            if sample.keys.contains("qualifier") {
                if sample["qualifier"] is NSNull { qualifier = nil }
                else if let value = sample["qualifier"] as? String { qualifier = value }
                else { throw CocoaError(.coderInvalidValue) }
            } else { qualifier = nil }
            let id = CraftMaterialUnitID(rawValue:
                "legacy-\(String(stableHash("\(location)|\(identity)|\(familyRaw)|\(grade.bitPattern)"), radix: 16))")
            let unit = CraftMaterialUnitV1(
                stableUnitID: id, domain: domain, familyID: family,
                qualityBand: try .init(legacyGrade: grade), properties: properties,
                sourceReceipt: .legacy(.init(originalKind: family, frozenSource: source,
                    qualifier: qualifier, migrationLocation: location, originalIdentity: identity)))
            return try JSONSerialization.jsonObject(with: SaveCodec.makeEncoder().encode(unit))
        }
        func migrateReserve(_ value: Any?, location: String) throws
            -> (world: [[String: Any]], creature: [[String: Any]]) {
            guard let object = value as? [String: Any],
                  Set(object.keys) == ["units"], let units = object["units"] as? [[String: Any]] else {
                if value == nil { return ([], []) }
                throw CocoaError(.coderInvalidValue)
            }
            var world: [[String: Any]] = [], creature: [[String: Any]] = []
            var ids = Set<String>()
            for (ordinal, holding) in units.enumerated() {
                guard Set(holding.keys).isSubset(of: ["id", "sample", "protectedReturn"]),
                      let sample = holding["sample"] as? [String: Any] else {
                    throw CocoaError(.coderInvalidValue)
                }
                let oldID = try rawInstanceID(holding["id"])
                guard ids.insert(oldID).inserted else { throw CocoaError(.coderInvalidValue) }
                guard var unit = try unitJSON(sample: sample, location: location,
                                              identity: "reserve:\(oldID):\(ordinal)") as? [String: Any]
                else { throw CocoaError(.coderInvalidValue) }
                unit["stableUnitID"] = holding["id"]
                let migrated: [String: Any] = [
                    "unit": unit,
                    "protectedReturn": holding["protectedReturn"] as? Bool ?? false,
                ]
                if unit["domain"] as? String == CraftMaterialDomain.world.rawValue { world.append(migrated) }
                else { creature.append(migrated) }
            }
            return (world, creature)
        }
        func migrateOwner(_ value: Any, location: String) throws -> Any {
            guard var owner = value as? [String: Any] else { throw CocoaError(.coderInvalidValue) }
            guard owner["worldMaterialReserve"] == nil, owner["creatureMaterialReserve"] == nil else {
                throw CocoaError(.coderInvalidValue)
            }
            var split = try migrateReserve(owner.removeValue(forKey: "materialReserve"), location: location)

            func migrateStack(_ value: [String: Any], stackLocation: String,
                              liveHolding: Bool) throws -> (stack: [String: Any]?, world: [[String: Any]], creature: [[String: Any]]) {
                var stack = value
                let stackID = try rawInstanceID(stack["id"])
                var samples: [[String: Any]] = []
                if stack.keys.contains("materials") {
                    guard let values = stack.removeValue(forKey: "materials") as? [[String: Any]] else {
                        throw CocoaError(.coderInvalidValue)
                    }
                    samples = values
                } else if stack.keys.contains("material") {
                    guard let value = stack.removeValue(forKey: "material") as? [String: Any] else {
                        throw CocoaError(.coderInvalidValue)
                    }
                    guard let count = stack["count"] as? NSNumber,
                          CFGetTypeID(count) != CFBooleanGetTypeID(), count.intValue > 0,
                          Double(count.intValue) == count.doubleValue else { throw CocoaError(.coderInvalidValue) }
                    samples = Array(repeating: value, count: count.intValue)
                }
                var world: [[String: Any]] = [], creature: [[String: Any]] = []
                if !samples.isEmpty {
                    guard liveHolding else { throw CocoaError(.coderInvalidValue) }
                    if let count = stack["count"] as? NSNumber,
                       (CFGetTypeID(count) == CFBooleanGetTypeID() || count.intValue != samples.count) {
                        throw CocoaError(.coderInvalidValue)
                    }
                    let protected = (stack["protectedReturnCount"] as? NSNumber)?.intValue ?? 0
                    guard protected >= 0, protected <= samples.count else { throw CocoaError(.coderInvalidValue) }
                    for (ordinal, sample) in samples.enumerated() {
                        guard let unit = try unitJSON(sample: sample, location: stackLocation,
                            identity: "stack:\(stackID):\(ordinal)") as? [String: Any] else {
                            throw CocoaError(.coderInvalidValue)
                        }
                        let holding: [String: Any] = ["unit": unit, "protectedReturn": ordinal < protected]
                        if unit["domain"] as? String == CraftMaterialDomain.world.rawValue { world.append(holding) }
                        else { creature.append(holding) }
                    }
                    return (nil, world, creature)
                }
                if var profile = stack["gearProfile"] as? [String: Any],
                   let consumed = profile["consumedSamples"] as? [[String: Any]] {
                    profile["consumedSamples"] = try consumed.enumerated().map { ordinal, sample in
                        try unitJSON(sample: sample, location: stackLocation,
                                     identity: "gear:\(stackID):\(ordinal)")
                    }
                    stack["gearProfile"] = profile
                }
                return (stack, world, creature)
            }

            func migrateInventory(_ value: Any, inventoryLocation: String) throws
                -> (inventory: [String: Any], world: [[String: Any]], creature: [[String: Any]]) {
                guard var inventory = value as? [String: Any],
                      let stacks = inventory["stacks"] as? [[String: Any]] else {
                    throw CocoaError(.coderInvalidValue)
                }
                var kept: [[String: Any]] = [], world: [[String: Any]] = [], creature: [[String: Any]] = []
                for (ordinal, stack) in stacks.enumerated() {
                    let migrated = try migrateStack(stack,
                        stackLocation: "\(inventoryLocation).stacks[\(ordinal)]", liveHolding: true)
                    if let stack = migrated.stack { kept.append(stack) }
                    world += migrated.world; creature += migrated.creature
                }
                inventory["stacks"] = kept
                return (inventory, world, creature)
            }

            func migrateEquippedPiece(_ value: Any, pieceLocation: String) throws -> Any {
                guard var piece = value as? [String: Any] else { return value }
                if var profile = piece["gearProfile"] as? [String: Any],
                   let samples = profile["consumedSamples"] as? [[String: Any]] {
                    profile["consumedSamples"] = try samples.enumerated().map { ordinal, sample in
                        try unitJSON(sample: sample, location: pieceLocation,
                                     identity: "consumed:\(ordinal)")
                    }
                    piece["gearProfile"] = profile
                }
                return piece
            }

            if let equipped = owner["binderEquipped"] as? [String: Any] {
                owner["binderEquipped"] = try equipped.mapValues {
                    try migrateEquippedPiece($0, pieceLocation: "\(location).binderEquipped")
                }
            }
            if let roster = owner["roster"] as? [[String: Any]] {
                owner["roster"] = try roster.enumerated().map { memberIndex, value in
                    var member = value
                    if let equipped = member["equipped"] as? [String: Any] {
                        member["equipped"] = try equipped.mapValues {
                            try migrateEquippedPiece(
                                $0, pieceLocation: "\(location).roster[\(memberIndex)].equipped")
                        }
                    }
                    return member
                }
            }

            if let inventoryValue = owner["inventory"] {
                let migrated = try migrateInventory(inventoryValue, inventoryLocation: "\(location).inventory")
                owner["inventory"] = migrated.inventory
                split.world += migrated.world; split.creature += migrated.creature
            }
            if let inventoryValue = owner["satchelItems"] {
                let migrated = try migrateInventory(inventoryValue, inventoryLocation: "\(location).satchelItems")
                owner["satchelItems"] = migrated.inventory
                split.world += migrated.world; split.creature += migrated.creature
            }
            if let spillover = owner["spillover"] as? [[String: Any]] {
                var kept: [[String: Any]] = []
                for (ordinal, stack) in spillover.enumerated() {
                    let migrated = try migrateStack(stack,
                        stackLocation: "\(location).spillover[\(ordinal)]", liveHolding: true)
                    if let stack = migrated.stack { kept.append(stack) }
                    split.world += migrated.world; split.creature += migrated.creature
                }
                owner["spillover"] = kept
            }
            if let offered = owner["offeredItems"] as? [[String: Any]] {
                var kept: [[String: Any]] = []
                for (ordinal, stack) in offered.enumerated() {
                    let migrated = try migrateStack(stack,
                        stackLocation: "\(location).offeredItems[\(ordinal)]", liveHolding: true)
                    if let stack = migrated.stack { kept.append(stack) }
                    split.world += migrated.world; split.creature += migrated.creature
                }
                owner["offeredItems"] = kept
            }
            if var map = owner["map"] as? [String: Any],
               let tiles = map["tiles"] as? [[String: Any]] {
                map["tiles"] = try tiles.enumerated().map { tileIndex, value in
                    var tile = value
                    if var content = tile["content"] as? [String: Any],
                       var tagged = content["item"] as? [String: Any],
                       let stack = tagged["_0"] as? [String: Any] {
                        let migrated = try migrateStack(
                            stack, stackLocation: "\(location).map.tiles[\(tileIndex)].content.item",
                            liveHolding: true)
                        split.world += migrated.world
                        split.creature += migrated.creature
                        if let stack = migrated.stack {
                            tagged["_0"] = stack
                            content["item"] = tagged
                            tile["content"] = content
                        } else {
                            tile.removeValue(forKey: "content")
                        }
                    }
                    return tile
                }
                owner["map"] = map
            }
            if var tradingPost = owner["tradingPost"] as? [String: Any],
               let stock = tradingPost["stock"] as? [[String: Any]] {
                tradingPost["stock"] = try stock.enumerated().map { lineIndex, value in
                    var line = value
                    guard line["frozenMaterialUnits"] == nil else {
                        throw CocoaError(.coderInvalidValue)
                    }
                    let frozen = line["frozenUnits"] as? [[String: Any]] ?? []
                    var kept: [[String: Any]] = []
                    var materialUnits: [[String: Any]] = []
                    for (unitIndex, stack) in frozen.enumerated() {
                        let migrated = try migrateStack(
                            stack,
                            stackLocation: "\(location).tradingPost.stock[\(lineIndex)].frozenUnits[\(unitIndex)]",
                            liveHolding: true)
                        if let stack = migrated.stack { kept.append(stack) }
                        materialUnits += (migrated.world + migrated.creature).compactMap {
                            $0["unit"] as? [String: Any]
                        }
                    }
                    guard materialUnits.isEmpty || kept.isEmpty else {
                        throw CocoaError(.coderInvalidValue)
                    }
                    line["frozenUnits"] = kept
                    line["frozenMaterialUnits"] = materialUnits
                    return line
                }
                owner["tradingPost"] = tradingPost
            }
            owner["worldMaterialReserve"] = ["holdings": split.world]
            owner["creatureMaterialReserve"] = ["holdings": split.creature]
            return owner
        }
        if var base = root["base"] as? [String: Any] {
            guard let migratedBase = try migrateOwner(base, location: "base") as? [String: Any] else {
                throw CocoaError(.coderInvalidValue)
            }
            base = migratedBase
            root["base"] = base
        } else if root.keys.contains("base") {
            throw CocoaError(.coderInvalidValue)
        }
        if var worlds = root["worlds"] as? [String: Any] {
            if let active = worlds["activeRun"], !(active is NSNull) {
                worlds["activeRun"] = try migrateOwner(active, location: "worlds.activeRun")
            }
            if let realms = worlds["anchoredRealms"] as? [[String: Any]] {
                worlds["anchoredRealms"] = try realms.enumerated().map { index, value in
                    var realm = value
                    if let world = realm["world"] {
                        realm["world"] = try migrateOwner(
                            world, location: "worlds.anchoredRealms[\(index)].world")
                    }
                    return realm
                }
            }
            if var summary = worlds["lastExit"] as? [String: Any] {
                for key in ["recoveredLines", "lostLines"] {
                    if let lines = summary[key] as? [[String: Any]] {
                        summary[key] = try lines.enumerated().map { lineIndex, value in
                            var line = value
                            if var tagged = line["materialSample"] as? [String: Any],
                               var payload = tagged["_0"] as? [String: Any],
                               let sample = payload["sample"] as? [String: Any] {
                                payload["sample"] = try unitJSON(
                                    sample: sample,
                                    location: "worlds.lastExit.\(key)[\(lineIndex)]",
                                    identity: "receipt")
                                tagged["_0"] = payload
                                line["materialSample"] = tagged
                            }
                            return line
                        }
                    }
                }
                worlds["lastExit"] = summary
            } else if worlds.keys.contains("lastExit"), !(worlds["lastExit"] is NSNull) {
                throw CocoaError(.coderInvalidValue)
            }
            root["worlds"] = worlds
        }
        root["schemaVersion"] = 7
        return try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys])
    }

    /// Freezes source danger and explicit once-only creature reward resolution across every run.
    private static func migrate6to7CreatureRewards(_ data: Data) throws -> Data {
        guard var root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw CocoaError(.coderInvalidValue)
        }
        func json<T: Encodable>(_ value: T) throws -> Any {
            try JSONSerialization.jsonObject(with: SaveCodec.makeEncoder().encode(value))
        }
        func migrateRun(_ value: Any) throws -> Any {
            guard var run = value as? [String: Any], let bookValue = run["book"] else {
                throw CocoaError(.coderInvalidValue)
            }
            if run.keys.contains("sourceDangerReceipt") {
                guard !(run["sourceDangerReceipt"] is NSNull) else { throw CocoaError(.coderInvalidValue) }
                _ = try SaveCodec.makeDecoder().decode(
                    WorldSourceDangerReceiptV1.self,
                    from: JSONSerialization.data(withJSONObject: run["sourceDangerReceipt"] as Any))
            } else {
                let book = try SaveCodec.makeDecoder().decode(
                    BoundBook.self, from: JSONSerialization.data(withJSONObject: bookValue))
                run["sourceDangerReceipt"] = try json(WorldSourceDangerReceiptV1.freeze(book: book))
            }
            if let encounterValue = run["activeEncounter"], !(encounterValue is NSNull) {
                guard var encounter = encounterValue as? [String: Any] else {
                    throw CocoaError(.coderInvalidValue)
                }
                let resolution: CreatureMaterialRewardResolutionV1
                if encounter.keys.contains("creatureMaterialRewardResolution") {
                    guard !(encounter["creatureMaterialRewardResolution"] is NSNull) else {
                        throw CocoaError(.coderInvalidValue)
                    }
                    resolution = try SaveCodec.makeDecoder().decode(
                        CreatureMaterialRewardResolutionV1.self,
                        from: JSONSerialization.data(
                            withJSONObject: encounter["creatureMaterialRewardResolution"] as Any))
                } else {
                    resolution =
                        encounter["outcome"] == nil || encounter["outcome"] is NSNull
                        ? .pending : .legacyResolved
                    encounter["creatureMaterialRewardResolution"] = try json(resolution)
                }
                if case .pending = resolution {
                    let enemies = try SaveCodec.makeDecoder().decode(
                        [WorldEnemy].self,
                        from: JSONSerialization.data(withJSONObject: run["enemies"] ?? []))
                    var foes = try SaveCodec.makeDecoder().decode(
                        [FoeState].self,
                        from: JSONSerialization.data(withJSONObject: encounter["foes"] ?? []))
                    guard Set(enemies.map(\.id)).count == enemies.count,
                          Set(foes.map(\.id)).count == foes.count else {
                        throw CocoaError(.coderInvalidValue)
                    }
                    for index in foes.indices {
                        if foes[index].creatureID != nil {
                            guard foes[index].speciesID == nil else { throw CocoaError(.coderInvalidValue) }
                            continue
                        }
                        guard foes[index].traits != nil else {
                            guard foes[index].speciesID == nil else { throw CocoaError(.coderInvalidValue) }
                            continue
                        }
                        guard let enemy = enemies.first(where: { $0.id == foes[index].id }) else {
                            throw CocoaError(.coderInvalidValue)
                        }
                        if enemy.floraID != nil {
                            guard foes[index].speciesID == nil else { throw CocoaError(.coderInvalidValue) }
                            continue
                        }
                        guard let expectedSpeciesID = enemy.speciesID else {
                            throw CocoaError(.coderInvalidValue)
                        }
                        if let presentSpeciesID = foes[index].speciesID {
                            guard presentSpeciesID == expectedSpeciesID else {
                                throw CocoaError(.coderInvalidValue)
                            }
                        } else {
                            foes[index].speciesID = expectedSpeciesID
                        }
                    }
                    encounter["foes"] = try json(foes)
                }
                run["activeEncounter"] = encounter
            }
            return run
        }
        if var worlds = root["worlds"] as? [String: Any] {
            if let active = worlds["activeRun"], !(active is NSNull) {
                worlds["activeRun"] = try migrateRun(active)
            }
            if let realms = worlds["anchoredRealms"] as? [[String: Any]] {
                worlds["anchoredRealms"] = try realms.map { value in
                    var realm = value
                    if let world = realm["world"] { realm["world"] = try migrateRun(world) }
                    return realm
                }
            }
            root["worlds"] = worlds
        }
        root["schemaVersion"] = 7
        return try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys])
    }

    /// Promotes stable combat-graph ownership, typed choices and durable unspent points.
    private static func migrate4to5(_ data: Data) throws -> Data {
        guard var root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw CocoaError(.coderInvalidValue)
        }
        func integer(_ value: Any) throws -> Int {
            guard let number = value as? NSNumber,
                  CFGetTypeID(number) != CFBooleanGetTypeID(),
                  let parsed = Int(number.stringValue),
                  Double(parsed) == number.doubleValue,
                  parsed >= 0 else { throw CocoaError(.coderInvalidValue) }
            return parsed
        }
        let graph = ContentCatalog.shared.combatGraph
        let insulation = CombatNodeID(rawValue: "combat.craft.emanation.insulation")

        func migrateCharacter(_ input: [String: Any]) throws -> [String: Any] {
            var object = input
            let level = try object["level"].map(integer) ?? 1
            let free = try object["freePoints"].map(integer) ?? 0
            var owned: Set<String> = []
            if let encoded = object["ownedCombatNodeIDs"] {
                guard !(encoded is NSNull), let values = encoded as? [Any] else {
                    throw CocoaError(.coderInvalidValue)
                }
                for value in values {
                    guard let id = value as? String, !id.isEmpty,
                          let node = graph.node(CombatNodeID(rawValue: id)),
                          node.depth <= CombatGraphRules.openingMaximumDepth,
                          owned.insert(id).inserted else {
                        throw CocoaError(.coderInvalidValue)
                    }
                }
            } else {
                let depths = object["branchDepth"] as? [String: Any] ?? [:]
                var claimed = 0
                for (legacyID, rawDepth) in depths {
                    let depth = try integer(rawDepth)
                    claimed += depth
                    guard let discipline = graph.disciplines.first(where: {
                        $0.legacyBranchID.rawValue == legacyID
                    }) else { continue }
                    owned.formUnion(discipline.nodes.prefix(min(depth, discipline.nodes.count))
                        .map { $0.id.rawValue })
                }
                let standard = CombatTreeRules.totalPoints(atLevel: level)
                object["unspentCombatPoints"] = max(standard + free, claimed) - owned.count
            }
            if object["unspentCombatPoints"] == nil {
                object["unspentCombatPoints"] = max(
                    0, CombatTreeRules.totalPoints(atLevel: level) + free - owned.count)
            } else {
                _ = try integer(object["unspentCombatPoints"] as Any)
            }
            let decodedChoices: [String: Any]
            if let encoded = object["combatNodeChoices"] {
                guard !(encoded is NSNull), let decoded = encoded as? [String: Any] else {
                    throw CocoaError(.coderInvalidValue)
                }
                decodedChoices = decoded
            } else {
                decodedChoices = [:]
            }
            var choices = decodedChoices
            for (node, value) in choices {
                guard owned.contains(node), let choice = value as? String,
                      graph.node(CombatNodeID(rawValue: node))?.purchaseChoices
                        .contains(StableChoiceID(rawValue: choice)) == true else {
                    throw CocoaError(.coderInvalidValue)
                }
            }
            if owned.contains(insulation.rawValue), choices[insulation.rawValue] == nil {
                choices[insulation.rawValue] = "heat"
            }
            object["ownedCombatNodeIDs"] = owned.sorted()
            object["combatNodeChoices"] = choices
            object.removeValue(forKey: "branchDepth")
            object.removeValue(forKey: "freePoints")
            return object
        }

        let typedSkillKeys: Set<String> = ["skillID", "techniqueID", "grantsSkill", "selectedSkill"]
        func migrate(_ value: Any) throws -> Any {
            if let array = value as? [Any] { return try array.map(migrate) }
            guard var object = value as? [String: Any] else { return value }
            let isCharacter = object["level"] != nil
                && (object["branchDepth"] != nil || object["ownedCombatNodeIDs"] != nil
                    || object["unspentCombatPoints"] != nil)
            if isCharacter { object = try migrateCharacter(object) }
            for (key, child) in object {
                if typedSkillKeys.contains(key), let string = child as? String,
                   string == "elemental_strike" {
                    object[key] = "emanation_strike"
                } else if key == "skill", var payload = child as? [String: Any],
                          let string = payload["_0"] as? String,
                          string == "elemental_strike" {
                    payload["_0"] = "emanation_strike"
                    object[key] = payload
                } else {
                    object[key] = try migrate(child)
                }
            }
            if var cooldowns = object["cooldowns"] as? [String: Any] {
                for key in cooldowns.keys where key.hasSuffix("|elemental_strike") {
                    let replacement = String(key.dropLast("elemental_strike".count)) + "emanation_strike"
                    guard cooldowns[replacement] == nil else { throw CocoaError(.coderInvalidValue) }
                    cooldowns[replacement] = cooldowns.removeValue(forKey: key)
                }
                object["cooldowns"] = cooldowns
            }
            return object
        }
        guard var migrated = try migrate(root) as? [String: Any] else {
            throw CocoaError(.coderInvalidValue)
        }
        migrated["schemaVersion"] = 5
        root = migrated
        return try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys])
    }

    /// Freezes the deterministic creature-material projection onto ecology-aware species only.
    private static func migrate5to6(_ data: Data) throws -> Data {
        guard var root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw CocoaError(.coderInvalidValue)
        }

        func migratedSpecies(_ value: Any) throws -> Any {
            guard var object = value as? [String: Any] else { throw CocoaError(.coderInvalidValue) }
            let hasHabitat = object["habitat"] != nil && !(object["habitat"] is NSNull)
            let hasProjection = object.keys.contains("materialProjection")
            if hasProjection {
                guard hasHabitat, !(object["materialProjection"] is NSNull) else {
                    throw CocoaError(.coderInvalidValue)
                }
                _ = try SaveCodec.makeDecoder().decode(
                    CreatureMaterialProjectionReceiptV1.self,
                    from: JSONSerialization.data(withJSONObject: object["materialProjection"] as Any))
                return object
            }
            guard hasHabitat else { return object }
            let species = try SaveCodec.makeDecoder().decode(
                Species.self, from: JSONSerialization.data(withJSONObject: object))
            guard case .frozen(let receipt) = CreatureMaterialProjectionRules.freeze(
                traits: species.traits, habitat: species.habitat) else {
                throw CocoaError(.coderInvalidValue)
            }
            object["materialProjection"] = try JSONSerialization.jsonObject(
                with: SaveCodec.makeEncoder().encode(receipt))
            return object
        }

        func migrateCast(in runValue: Any) throws -> Any {
            guard var run = runValue as? [String: Any] else { throw CocoaError(.coderInvalidValue) }
            if let cast = run["cast"] as? [Any] { run["cast"] = try cast.map(migratedSpecies) }
            return run
        }

        if var worlds = root["worlds"] as? [String: Any] {
            if let active = worlds["activeRun"], !(active is NSNull) {
                worlds["activeRun"] = try migrateCast(in: active)
            }
            if let realms = worlds["anchoredRealms"] as? [[String: Any]] {
                worlds["anchoredRealms"] = try realms.map { realmValue in
                    var realm = realmValue
                    if let world = realm["world"] { realm["world"] = try migrateCast(in: world) }
                    return realm
                }
            }
            root["worlds"] = worlds
        }
        root["schemaVersion"] = 6
        return try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys])
    }

    /// Freezes the catalogue-owned extraction classification onto every persisted world node.
    /// The complete graph is validated and transformed before a new save value is decoded.
    private static func migrate3to4(_ data: Data) throws -> Data {
        guard var root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw CocoaError(.coderInvalidValue)
        }
        func migrate(_ value: Any) throws -> Any {
            if let array = value as? [Any] { return try array.map(migrate) }
            guard var object = value as? [String: Any] else { return value }
            if let resourceRaw = object["resource"] as? String,
               object["remainingHarvests"] != nil,
               object["yieldPerHarvest"] != nil {
                let resourceID = ResourceID(rawValue: resourceRaw)
                guard let resource = ContentCatalog.shared.resource(resourceID) else {
                    throw CocoaError(.coderInvalidValue)
                }
                var receipt: [String: Any] = [
                    "rulesVersion": ResourceExtractionRequirementReceiptV1.currentRulesVersion,
                    "resourceID": resourceRaw,
                    "disposition": resource.extractionDisposition.rawValue,
                ]
                if let rank = resource.requiredExtractionRank { receipt["requiredExtractionRank"] = rank }
                object["extractionRequirement"] = receipt
            }
            for (key, child) in object { object[key] = try migrate(child) }
            return object
        }
        guard var migrated = try migrate(root) as? [String: Any] else {
            throw CocoaError(.coderInvalidValue)
        }
        migrated["schemaVersion"] = 4
        root = migrated
        return try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys])
    }

#if DEBUG
    /// Narrow executable seam for the historical schema-3 node fixture. Full legacy campaign
    /// fixtures continue through `migrateIfNeeded`; this keeps the original owned synthesis step
    /// independently provable without manufacturing unrelated schema-3 gameplay fields.
    static func migrateSchemaThreeResourceNodesForTesting(_ data: Data) throws -> Data {
        try migrate3to4(data)
    }
#endif

    /// Makes the existing physical `essence_crystal` item the sole durable Essence authority.
    /// Historical scalar spend is not replayed: the balance present at migration time is simply
    /// combined 1:1 with crystals the player still owns.
    private static func migrate1to2(_ data: Data) throws -> Data {
        guard var root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return data
        }

        func encodedRawValue(_ value: Any?) throws -> UInt64? {
            guard let value else { return nil }
            guard let encoded = value as? [String: Any],
                  let number = encoded["rawValue"] as? NSNumber,
                  CFGetTypeID(number) != CFBooleanGetTypeID(),
                  let rawValue = UInt64(number.stringValue),
                  rawValue < UInt64.max else {
                throw CocoaError(.coderInvalidValue)
            }
            return rawValue
        }
        func maximumEncodedRawValue(in value: Any) throws -> UInt64? {
            if let object = value as? [String: Any] {
                let own = object["catalogID"] is String
                    ? try encodedRawValue(object["id"]) : nil
                return try object.values.reduce(own) { maximum, child in
                    guard let candidate = try maximumEncodedRawValue(in: child) else {
                        return maximum
                    }
                    return Swift.max(maximum ?? candidate, candidate)
                }
            }
            if let array = value as? [Any] {
                return try array.reduce(nil as UInt64?) { maximum, child in
                    guard let candidate = try maximumEncodedRawValue(in: child) else {
                        return maximum
                    }
                    return Swift.max(maximum ?? candidate, candidate)
                }
            }
            return nil
        }
        let highestExistingPhysicalID = try maximumEncodedRawValue(in: root) ?? 0
        var base = root["base"] as? [String: Any] ?? [:]
        let scalar = max(0, base["essence"] as? Int ?? 0)
        var inventory = base["inventory"] as? [String: Any] ?? [:]
        if inventory["slots"] == nil { inventory["slots"] = Tuning.Economy.startingInventorySlots }
        var stored = inventory["stacks"] as? [[String: Any]] ?? []
        var spillover = base["spillover"] as? [[String: Any]] ?? []

        var worlds = root["worlds"] as? [String: Any] ?? [:]
        var activeRun = worlds["activeRun"] as? [String: Any]
        var satchel = activeRun?["satchelItems"] as? [String: Any]
        var carried = satchel?["stacks"] as? [[String: Any]] ?? []

        func crystalCount(_ stacks: [[String: Any]]) -> Int {
            stacks.reduce(0) { total, stack in
                guard stack["catalogID"] as? String == "essence_crystal" else { return total }
                return total + max(0, stack["count"] as? Int ?? 1)
            }
        }
        let wallet = base["essenceCrystals"] as? [String: Any]
        let walletCount = wallet?["catalogID"] as? String == "essence_crystal"
            ? max(0, wallet?["count"] as? Int ?? 1) : 0
        let physical = walletCount + crystalCount(stored) + crystalCount(spillover) + crystalCount(carried)
        let existingID = (wallet?["catalogID"] as? String == "essence_crystal" ? wallet?["id"] : nil)
            ?? (stored + spillover + carried).first(where: {
            $0["catalogID"] as? String == "essence_crystal"
        })?["id"]

        stored.removeAll { $0["catalogID"] as? String == "essence_crystal" }
        spillover.removeAll { $0["catalogID"] as? String == "essence_crystal" }
        carried.removeAll { $0["catalogID"] as? String == "essence_crystal" }
        let total = scalar + physical
        if total > 0 {
            let walletID: [String: Any]
            if let rawValue = try encodedRawValue(existingID) {
                walletID = ["rawValue": NSNumber(value: rawValue)]
            } else {
                guard highestExistingPhysicalID < UInt64.max else {
                    throw CocoaError(.coderInvalidValue)
                }
                walletID = ["rawValue": NSNumber(value: highestExistingPhysicalID + 1)]
            }
            base["essenceCrystals"] = [
                "id": walletID,
                "catalogID": "essence_crystal", "count": total, "identified": true
            ]
        } else {
            base.removeValue(forKey: "essenceCrystals")
        }

        inventory["stacks"] = stored
        base["inventory"] = inventory
        base["spillover"] = spillover
        base["essence"] = 0
        root["base"] = base
        if activeRun != nil {
            satchel?["stacks"] = carried
            activeRun?["satchelItems"] = satchel
            worlds["activeRun"] = activeRun
            root["worlds"] = worlds
        }
        root["schemaVersion"] = 2
        return try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys])
    }

    /// Replaces every durable roster-position owner with the stable identity already present in
    /// the saved roster. The whole JSON graph is transformed before decoding, so an invalid actor
    /// fails without partially constructing or rewriting a campaign or slot payload.
    private static func migrate2to3(_ data: Data) throws -> Data {
        guard var root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw CocoaError(.coderInvalidValue)
        }
        var base = root["base"] as? [String: Any] ?? [:]
        var roster = base["roster"] as? [[String: Any]]
            ?? (base["companion"] as? [String: Any]).map { [$0] }
            ?? []

        func travellerRawValue(_ value: Any?) -> String? {
            if let string = value as? String { return string.isEmpty ? nil : string }
            guard let object = value as? [String: Any],
                  let string = object["rawValue"] as? String, !string.isEmpty else { return nil }
            return string
        }
        // Validate the complete roster before transforming a single durable reference. A v2
        // position is meaningful only relative to this exact canonical identity table.
        guard !roster.isEmpty,
              travellerRawValue(roster[0]["traveller"]) == nil,
              roster[0]["name"] as? String == "Quill" else {
            throw CocoaError(.coderInvalidValue)
        }
        var rosterIDs: Set<String> = ["founder:quill"]
        for index in roster.indices.dropFirst() {
            guard let rawTraveller = travellerRawValue(roster[index]["traveller"]),
                  ContentCatalog.shared.traveller(TravellerID(rawValue: rawTraveller)) != nil else {
                throw CocoaError(.coderInvalidValue)
            }
            let id = "traveller:\(rawTraveller)"
            guard rosterIDs.insert(id).inserted else { throw CocoaError(.coderInvalidValue) }
            if let encoded = roster[index]["persistentID"] {
                guard let encoded = encoded as? String, encoded == id else {
                    throw CocoaError(.coderInvalidValue)
                }
            }
        }
        if let encodedFounder = roster[0]["persistentID"] {
            guard let encodedFounder = encodedFounder as? String,
                  encodedFounder == "founder:quill" else {
                throw CocoaError(.coderInvalidValue)
            }
        }
        func identity(for value: Any) throws -> String {
            guard let number = value as? NSNumber,
                  CFGetTypeID(number) != CFBooleanGetTypeID(),
                  let index = Int(number.stringValue), index >= 0, index < roster.count else {
                throw CocoaError(.coderInvalidValue)
            }
            if index == 0 { return "founder:quill" }
            guard let traveller = travellerRawValue(roster[index]["traveller"]) else {
                throw CocoaError(.coderInvalidValue)
            }
            return "traveller:\(traveller)"
        }

        // Freeze member identity onto the roster itself. That makes its array order presentation
        // only after this migration rather than a hidden durable lookup authority.
        for index in roster.indices {
            roster[index]["persistentID"] = try identity(for: NSNumber(value: index))
        }
        base["roster"] = roster
        base.removeValue(forKey: "companion")
        root["base"] = base
        func migratedActorPayload(_ value: Any) throws -> Any {
            guard var payload = value as? [String: Any], let legacy = payload["_0"] else {
                throw CocoaError(.coderInvalidValue)
            }
            payload["_0"] = try identity(for: legacy)
            return payload
        }
        func migrate(_ value: Any, key: String? = nil) throws -> Any {
            if let array = value as? [Any] {
                if key == "activeParty" || key == "assignedCompanions" {
                    return try array.map(identity(for:))
                }
                return try array.map { try migrate($0) }
            }
            guard let object = value as? [String: Any] else {
                if key == "activeCompanion" { return try identity(for: value) }
                return value
            }

            if key == "partyNames" || key == "companionHP" {
                var encoded: [Any] = []
                for legacyKey in object.keys.sorted(by: { (Int($0) ?? 0) < (Int($1) ?? 0) }) {
                    guard let index = Int(legacyKey) else { throw CocoaError(.coderInvalidValue) }
                    encoded.append(try identity(for: NSNumber(value: index)))
                    encoded.append(try migrate(object[legacyKey] as Any))
                }
                return encoded
            }

            var result: [String: Any] = [:]
            for (childKey, child) in object {
                if childKey == "companion" || childKey == "member" {
                    if let payload = child as? [String: Any], payload["_0"] != nil {
                        result[childKey] = try migratedActorPayload(payload)
                    } else {
                        result[childKey] = try migrate(child, key: childKey)
                    }
                } else if childKey == "cooldowns", let cooldowns = child as? [String: Any] {
                    var migratedCooldowns: [String: Any] = [:]
                    for (cooldownKey, count) in cooldowns {
                        if cooldownKey.hasPrefix("companion-"),
                           let separator = cooldownKey.firstIndex(of: "|") {
                            let indexText = cooldownKey[cooldownKey.index(cooldownKey.startIndex,
                                                                          offsetBy: "companion-".count)..<separator]
                            guard let index = Int(indexText) else { throw CocoaError(.coderInvalidValue) }
                            let id = try identity(for: NSNumber(value: index))
                            migratedCooldowns["party-\(id)\(cooldownKey[separator...])"] = count
                        } else {
                            migratedCooldowns[cooldownKey] = count
                        }
                    }
                    result[childKey] = migratedCooldowns
                } else {
                    result[childKey] = try migrate(child, key: childKey)
                }
            }
            return result
        }

        root = try migrate(root) as! [String: Any]
        root["schemaVersion"] = 3
        return try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys])
    }
}
