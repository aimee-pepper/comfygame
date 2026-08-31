import Foundation
import OSLog
import CryptoKit

struct PersistenceAuthorityV1: Equatable, Sendable {
    enum Owner: Equatable, Sendable { case raw, slot(SaveSlotID, generation: UInt64) }
    let owner: Owner
    let primarySHA256: String?
    let primaryByteCount: Int
    let payloadSHA256: String?
}

struct PersistenceCommitReceiptV1: Equatable, Sendable {
    let owner: PersistenceAuthorityV1.Owner
    let payloadSHA256: String
    let payloadByteCount: Int
    let envelopeSHA256: String?
    let envelopeByteCount: Int?
}

enum PersistenceCommitRefusalV1: Error, Equatable, Sendable {
    case staleAuthority, retiredWriter, wrongSlot, corruptAuthority, futureAuthority
    case writeFailed, ambiguousReadback
}

enum PersistenceCASResultV1: Equatable, Sendable {
    case committed(PersistenceCommitReceiptV1)
    case recoveredDurable(PersistenceCommitReceiptV1)
    case alreadyCommitted(PersistenceCommitReceiptV1)
    case refused(PersistenceCommitRefusalV1)
}

enum PersistenceDigestV1 {
    static func sha256(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}

/// Deterministic failure seams for persistence tests. Production uses `.none`.
struct SaveFileCASFaultsV1: Sendable {
    var failBeforePrimaryReplacement = false
    var failPrimaryRestore = false
    var failBackupRestore = false

    static let none = Self()
}

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
    func persistenceAuthority() throws -> PersistenceAuthorityV1
    func compareAndSwap(expected: PersistenceAuthorityV1, candidate: Data) -> PersistenceCASResultV1
    func load() -> SaveLoadOutcome
    func deleteEverything()
    var diagnosticCampaignReference: String? { get }
}

extension GamePersistenceIO {
    var diagnosticCampaignReference: String? { nil }

    func persistenceAuthority() throws -> PersistenceAuthorityV1 {
        let data = try? Data(contentsOf: saveURL)
        return .init(owner: .raw, primarySHA256: data.map(PersistenceDigestV1.sha256),
                     primaryByteCount: data?.count ?? 0,
                     payloadSHA256: data.map(PersistenceDigestV1.sha256))
    }

    func compareAndSwap(expected: PersistenceAuthorityV1,
                        candidate: Data) -> PersistenceCASResultV1 {
        do {
            guard try persistenceAuthority() == expected else { return .refused(.staleAuthority) }
            let candidateSHA = PersistenceDigestV1.sha256(candidate)
            if expected.payloadSHA256 == candidateSHA,
               expected.primaryByteCount == candidate.count {
                return .alreadyCommitted(.init(owner: expected.owner,
                    payloadSHA256: candidateSHA, payloadByteCount: candidate.count,
                    envelopeSHA256: nil, envelopeByteCount: nil))
            }
            try write(candidate)
            guard let landed = try? Data(contentsOf: saveURL), landed == candidate else {
                return .refused(.ambiguousReadback)
            }
            return .committed(.init(owner: expected.owner, payloadSHA256: candidateSHA,
                payloadByteCount: candidate.count, envelopeSHA256: nil, envelopeByteCount: nil))
        } catch {
            if let landed = try? Data(contentsOf: saveURL), landed == candidate {
                return .recoveredDurable(.init(owner: expected.owner,
                    payloadSHA256: PersistenceDigestV1.sha256(candidate),
                    payloadByteCount: candidate.count, envelopeSHA256: nil,
                    envelopeByteCount: nil))
            }
            return .refused(.writeFailed)
        }
    }
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
    let casFaults: SaveFileCASFaultsV1

    init(directory: URL, fileName: String = "bookbinder-save.json",
         casFaults: SaveFileCASFaultsV1 = .none) {
        self.directory = directory
        self.fileName = fileName
        self.casFaults = casFaults
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

    func persistenceAuthority() throws -> PersistenceAuthorityV1 {
        let primary = try? Data(contentsOf: saveURL)
        return .init(owner: .raw,
                     primarySHA256: primary.map(PersistenceDigestV1.sha256),
                     primaryByteCount: primary?.count ?? 0,
                     payloadSHA256: primary.map(PersistenceDigestV1.sha256))
    }

    func compareAndSwap(expected: PersistenceAuthorityV1,
                        candidate: Data) -> PersistenceCASResultV1 {
        guard expected.owner == .raw else { return .refused(.staleAuthority) }
        let priorPrimary = try? Data(contentsOf: saveURL)
        let priorBackup = try? Data(contentsOf: backupURL)
        let actual = PersistenceAuthorityV1(
            owner: .raw, primarySHA256: priorPrimary.map(PersistenceDigestV1.sha256),
            primaryByteCount: priorPrimary?.count ?? 0,
            payloadSHA256: priorPrimary.map(PersistenceDigestV1.sha256))
        guard actual == expected else { return .refused(.staleAuthority) }
        let receipt = PersistenceCommitReceiptV1(
            owner: .raw, payloadSHA256: PersistenceDigestV1.sha256(candidate),
            payloadByteCount: candidate.count, envelopeSHA256: nil, envelopeByteCount: nil)
        if priorPrimary == candidate { return .alreadyCommitted(receipt) }
        do {
            try FileManager.default.createDirectory(at: directory,
                                                    withIntermediateDirectories: true)
            if let priorPrimary {
                try priorPrimary.write(to: backupURL, options: .atomic)
            } else if FileManager.default.fileExists(atPath: backupURL.path(percentEncoded: false)) {
                try FileManager.default.removeItem(at: backupURL)
            }
            if casFaults.failBeforePrimaryReplacement { throw CocoaError(.fileWriteUnknown) }
            try candidate.write(to: saveURL,
                options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
            guard (try? Data(contentsOf: saveURL)) == candidate else {
                throw CocoaError(.fileReadCorruptFile)
            }
            return .committed(receipt)
        } catch {
            if (try? Data(contentsOf: saveURL)) == candidate {
                return .recoveredDurable(receipt)
            }
            if !casFaults.failPrimaryRestore { try? restore(priorPrimary, at: saveURL) }
            if !casFaults.failBackupRestore { try? restore(priorBackup, at: backupURL) }
            let restoredPrimary = try? Data(contentsOf: saveURL)
            let restoredBackup = try? Data(contentsOf: backupURL)
            guard restoredPrimary == priorPrimary, restoredBackup == priorBackup else {
                return .refused(.ambiguousReadback)
            }
            return .refused(.writeFailed)
        }
    }

    private func restore(_ data: Data?, at url: URL) throws {
        if let data { try data.write(to: url, options: .atomic) }
        else if FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) {
            try FileManager.default.removeItem(at: url)
        }
    }

    // MARK: - Loading

    typealias LoadOutcome = SaveLoadOutcome

    func load() -> LoadOutcome {
        guard saveFileExists else { return .newGame }

        do {
            return .loaded(try SaveCodec.decode(Data(contentsOf: saveURL)))
        } catch {
            Logger.persistence.error("Primary save unreadable: \(String(describing: error))")
            return .unrecoverable(reason: shortReason(error))
        }
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
