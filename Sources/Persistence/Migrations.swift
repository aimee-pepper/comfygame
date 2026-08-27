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
            return data
        }

        var working = data
        for from in version..<Tuning.saveSchemaVersion {
            working = try step(working, from: from)
        }
        try validateCurrentChannelworksRestoration(in: working)
        return working
    }

    /// Reads just `schemaVersion` without committing to the rest of the shape.
    static func probeSchemaVersion(_ data: Data) -> Int? {
        struct Probe: Decodable { var schemaVersion: Int? }
        return (try? JSONDecoder().decode(Probe.self, from: data))?.schemaVersion
    }

    private static func step(_ data: Data, from version: Int) throws -> Data {
        switch version {
        case 1: return try migrate1to2(data)
        case 2: return try migrate2to3(data)
        case 3: return try migrate3to4(data)
        case 4: return try migrate4to5(data)
        case 5: return try migrate5to6(data)
        case 6: return try migrate6to7(data)
        case 7: return try migrate7to8(data)
        case 8: return try migrate8to9(data)
        default:
            // No migration registered. Tolerant decoding is the fallback; if the save is genuinely
            // incompatible, `SaveFileIO.load()` quarantines it rather than losing it.
            return data
        }
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
    private static func migrate5to6(_ data: Data) throws -> Data {
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
        root["schemaVersion"] = 6
        return try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys])
    }

    /// Freezes the deterministic creature-material projection onto ecology-aware species only.
    private static func migrate4to5(_ data: Data) throws -> Data {
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
        root["schemaVersion"] = 5
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
