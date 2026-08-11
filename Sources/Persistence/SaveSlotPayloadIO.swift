import Foundation
import CryptoKit

final class SaveSlotWriterLease: @unchecked Sendable {
    private let lock = NSLock()
    private var active = true

    func withActiveWriter<T>(_ body: () throws -> T) throws -> T {
        lock.lock()
        defer { lock.unlock() }
        guard active else { throw SaveSlotPayloadError.retiredWriter }
        return try body()
    }

    func retire() {
        lock.lock()
        active = false
        lock.unlock()
    }
}

enum SaveSlotPayloadError: Error, Equatable {
    case retiredWriter
    case wrongSlot
    case corruptEnvelope
    case futureIncompatible(schemaVersion: Int)
}

/// Synchronous GameStore adapter for one leased slot. Every autosave replaces the self-contained
/// envelope itself; it never creates a shadow raw save or a second metadata catalogue.
struct SaveSlotPayloadIO: GamePersistenceIO {
    let saveURL: URL
    let slotID: SaveSlotID
    let lease: SaveSlotWriterLease

    var diagnosticCampaignReference: String? {
        let digest = SHA256.hash(data: Data(slotID.description.utf8))
        return digest.prefix(6).map { String(format: "%02x", $0) }.joined()
    }

    var saveFileByteCount: Int? {
        try? FileManager.default.attributesOfItem(atPath: saveURL.path(percentEncoded: false))[.size] as? Int
    }

    func load() -> SaveLoadOutcome {
        do {
            let envelope = try readEnvelope()
            return .loaded(try decode(envelope.payload))
        } catch let error as SaveSlotPayloadError {
            return .unrecoverable(reason: String(describing: error))
        } catch {
            return .unrecoverable(reason: "corrupt slot payload")
        }
    }

    func write(_ data: Data) throws {
        try lease.withActiveWriter {
            var envelope = try readEnvelope()
            let state = try decode(data)
            envelope.payload = data
            envelope.metadata = .make(id: slotID, name: envelope.metadata.name, state: state,
                                      createdAt: envelope.metadata.createdAt,
                                      lastPlayedAt: state.meta.lastSavedAt ?? Date())
            try Self.encoder().encode(envelope).write(to: saveURL, options: .atomic)
        }
    }

    /// GameStore's DEBUG reset immediately writes a fresh state. Keeping the owned envelope in
    /// place lets that write preserve slot identity/name instead of deleting the campaign itself.
    func deleteEverything() {}

    private func readEnvelope() throws -> SaveSlotEnvelope {
        guard let envelope = try? Self.decoder().decode(
            SaveSlotEnvelope.self, from: Data(contentsOf: saveURL)),
              envelope.metadata.id == slotID else { throw SaveSlotPayloadError.corruptEnvelope }
        guard envelope.schemaVersion <= SaveSlotEnvelope.schemaVersion else {
            throw SaveSlotPayloadError.futureIncompatible(schemaVersion: envelope.schemaVersion)
        }
        return envelope
    }

    private func decode(_ data: Data) throws -> GameState {
        if let version = Migrations.probeSchemaVersion(data), version > Tuning.saveSchemaVersion {
            throw SaveSlotPayloadError.futureIncompatible(schemaVersion: version)
        }
        return try SaveCodec.decode(data)
    }

    private static func encoder() -> JSONEncoder {
        let value = JSONEncoder()
        value.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        value.dateEncodingStrategy = .iso8601
        return value
    }

    private static func decoder() -> JSONDecoder {
        let value = JSONDecoder()
        value.dateDecodingStrategy = .iso8601
        return value
    }
}
