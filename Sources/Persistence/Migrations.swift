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
        default:
            // No migration registered. Tolerant decoding is the fallback; if the save is genuinely
            // incompatible, `SaveFileIO.load()` quarantines it rather than losing it.
            return data
        }
    }

    /// Makes the existing physical `essence_crystal` item the sole durable Essence authority.
    /// Historical scalar spend is not replayed: the balance present at migration time is simply
    /// combined 1:1 with crystals the player still owns.
    private static func migrate1to2(_ data: Data) throws -> Data {
        guard var root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return data
        }
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
            let usedIDs = (stored + spillover + carried).compactMap { $0["id"] as? Int }
            base["essenceCrystals"] = [
                "id": existingID ?? ["rawValue": (usedIDs.max() ?? 0) + 1],
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
}
