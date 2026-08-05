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

    static func migrateIfNeeded(_ data: Data) throws -> Data {
        let version = probeSchemaVersion(data) ?? Tuning.saveSchemaVersion
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
        // case 1: return try migrate1to2(data)
        default:
            // No migration registered. Tolerant decoding is the fallback; if the save is genuinely
            // incompatible, `SaveFileIO.load()` quarantines it rather than losing it.
            return data
        }
    }
}
