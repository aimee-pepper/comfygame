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
        guard version < Tuning.saveSchemaVersion else { return data }

        var working = data
        for from in version..<Tuning.saveSchemaVersion {
            working = try step(working, from: from)
        }
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
        default:
            // No migration registered. Tolerant decoding is the fallback; if the save is genuinely
            // incompatible, `SaveFileIO.load()` quarantines it rather than losing it.
            return data
        }
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
