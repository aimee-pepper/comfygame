import Foundation
import OSLog

enum SaveLoadOutcome {
    case newGame
    case loaded(GameState)
    case recoveredFromBackup(GameState, reason: String)
    case unrecoverable(reason: String)

    var state: GameState? {
        switch self {
        case .loaded(let state), .recoveredFromBackup(let state, _): state
        case .newGame, .unrecoverable: nil
        }
    }

    var description: String {
        switch self {
        case .newGame: "new game (no save file)"
        case .loaded: "loaded"
        case .recoveredFromBackup(_, let reason): "recovered from backup (\(reason))"
        case .unrecoverable(let reason): "unrecoverable (\(reason))"
        }
    }
}

protocol GamePersistenceIO: Sendable {
    var saveURL: URL { get }
    var saveFileByteCount: Int? { get }
    func write(_ data: Data) throws
    func load() -> SaveLoadOutcome
    func deleteEverything()
}

// Preserve concise call sites after GameStore began accepting any persistence adapter.
// Constraining the protocol extension to SaveFileIO keeps `.documents` and `.temporary(...)`
// unambiguous while slot-backed stores continue to inject their own adapter explicitly.
extension GamePersistenceIO where Self == SaveFileIO {
    static var documents: SaveFileIO { SaveFileIO.documents }
    static func temporary(name: String = UUID().uuidString) -> SaveFileIO {
        SaveFileIO.temporary(name: name)
    }
}

/// Reads and writes the single save file.
///
/// Brief: one `Codable` game-state JSON in Documents, atomic writes, no SwiftData/CoreData in v0.
/// The extra piece beyond "write a file" is surviving a kill *during* a write: `Data.write(.atomic)`
/// writes to a sibling temp file and renames, so the save is never half-written, and the previous
/// good save is kept alongside as a backup for the case where a save is unreadable for any other
/// reason (schema mistake, disk trouble).
struct SaveFileIO: GamePersistenceIO {
    let directory: URL
    let fileName: String

    init(directory: URL, fileName: String = "bookbinder-save.json") {
        self.directory = directory
        self.fileName = fileName
    }

    /// The real location: `Documents/`. Exposed over USB via `UIFileSharingEnabled` so a save can
    /// be pulled off the phone for inspection.
    static var documents: SaveFileIO {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return SaveFileIO(directory: url)
    }

    /// Throwaway location for tests and SwiftUI previews.
    static func temporary(name: String = UUID().uuidString) -> SaveFileIO {
        let url = FileManager.default.temporaryDirectory.appending(path: "bookbinder-tests/\(name)", directoryHint: .isDirectory)
        return SaveFileIO(directory: url)
    }

    var saveURL: URL { directory.appending(path: fileName) }
    var backupURL: URL { directory.appending(path: fileName + ".backup") }

    var saveFileByteCount: Int? {
        try? FileManager.default.attributesOfItem(atPath: saveURL.path(percentEncoded: false))[.size] as? Int
    }

    var saveFileExists: Bool { FileManager.default.fileExists(atPath: saveURL.path(percentEncoded: false)) }

    // MARK: - Writing

    func write(_ data: Data) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        // Roll the current good save to .backup before replacing it. Best-effort: a failure here
        // must not stop the actual save.
        if saveFileExists {
            try? FileManager.default.removeItem(at: backupURL)
            try? FileManager.default.copyItem(at: saveURL, to: backupURL)
        }

        // .atomic == write temp + rename. A kill mid-write leaves the old file intact.
        // File protection: readable after first unlock, so a save can land while the phone is
        // locked in a pocket (a `.complete` class would fail exactly then).
        try data.write(to: saveURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }

    // MARK: - Loading

    typealias LoadOutcome = SaveLoadOutcome

    func load() -> LoadOutcome {
        guard saveFileExists else { return .newGame }

        do {
            return .loaded(try SaveCodec.decode(Data(contentsOf: saveURL)))
        } catch {
            Logger.persistence.error("Primary save unreadable: \(String(describing: error))")

            if FileManager.default.fileExists(atPath: backupURL.path(percentEncoded: false)) {
                do {
                    let state = try SaveCodec.decode(Data(contentsOf: backupURL))
                    quarantine(saveURL)
                    return .recoveredFromBackup(state, reason: shortReason(error))
                } catch {
                    Logger.persistence.error("Backup save also unreadable: \(String(describing: error))")
                }
            }

            quarantine(saveURL)
            quarantine(backupURL)
            return .unrecoverable(reason: shortReason(error))
        }
    }

    /// Never delete a player's save, even a broken one — move it aside so it can be recovered by
    /// hand or mailed to us.
    private func quarantine(_ url: URL) {
        guard FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) else { return }
        let stamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let destination = directory.appending(path: "\(url.lastPathComponent).corrupt-\(stamp)")
        try? FileManager.default.moveItem(at: url, to: destination)
        Logger.persistence.error("Quarantined \(url.lastPathComponent) → \(destination.lastPathComponent)")
    }

    private func shortReason(_ error: Error) -> String {
        if let decoding = error as? DecodingError {
            switch decoding {
            case .keyNotFound(let key, _): return "missing key '\(key.stringValue)'"
            case .typeMismatch(_, let context): return "type mismatch at \(context.codingPath.map(\.stringValue).joined(separator: "."))"
            case .valueNotFound(_, let context): return "null at \(context.codingPath.map(\.stringValue).joined(separator: "."))"
            case .dataCorrupted: return "corrupt JSON"
            @unknown default: return "decode failed"
            }
        }
        return String(describing: type(of: error))
    }

    /// Removes the save entirely — only for the harness's explicit "wipe save" action and tests.
    func deleteEverything() {
        for url in [saveURL, backupURL] {
            try? FileManager.default.removeItem(at: url)
        }
    }
}

/// One place that decides how the save is encoded, so tests and the app can never disagree.
enum SaveCodec {
    static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        // Readable + stable ordering: saves diff cleanly while we iterate on the schema, and the
        // file is small enough (single-digit KB) that prettiness costs nothing.
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    static func encode(_ state: GameState) throws -> Data {
        try makeEncoder().encode(state)
    }

    static func decode(_ data: Data) throws -> GameState {
        let migrated = try Migrations.migrateIfNeeded(data)
        return try makeDecoder().decode(GameState.self, from: migrated)
    }
}

extension Logger {
    static let persistence = Logger(subsystem: "com.aimeepepper.bookbinder", category: "persistence")
}
