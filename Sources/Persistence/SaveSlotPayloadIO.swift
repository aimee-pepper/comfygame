import Foundation
import CryptoKit

final class SaveSlotWriterLease: @unchecked Sendable {
    private let lock = NSLock()
    private var active = true
    private var latestGeneration: UInt64 = 0

    func withActiveWriter<T>(_ body: () throws -> T) throws -> T {
        lock.lock()
        defer { lock.unlock() }
        guard active else { throw SaveSlotPayloadError.retiredWriter }
        return try body()
    }

    func issueGeneration<T>(_ body: (UInt64) throws -> T) throws -> T {
        lock.lock()
        defer { lock.unlock() }
        guard active else { throw SaveSlotPayloadError.retiredWriter }
        latestGeneration &+= 1
        return try body(latestGeneration)
    }

    func withActiveWriter<T>(generation: UInt64, _ body: () throws -> T) throws -> T {
        lock.lock()
        defer { lock.unlock() }
        guard active else { throw SaveSlotPayloadError.retiredWriter }
        guard generation == latestGeneration else { throw SaveSlotPayloadError.staleWriter }
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
    case staleWriter
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
        try lease.issueGeneration { _ in
            var envelope = try readEnvelope()
            let state = try decode(data)
            envelope.payload = data
            envelope.metadata = .make(id: slotID, name: envelope.metadata.name, state: state,
                                      createdAt: envelope.metadata.createdAt,
                                      lastPlayedAt: state.meta.lastSavedAt ?? Date())
            try Self.encoder().encode(envelope).write(to: saveURL, options: .atomic)
        }
    }

    func persistenceAuthority() throws -> PersistenceAuthorityV1 {
        try lease.issueGeneration { generation in
            let envelopeData = try Data(contentsOf: saveURL)
            let envelope = try readEnvelope(envelopeData)
            return .init(
                owner: .slot(slotID, generation: generation),
                primarySHA256: PersistenceDigestV1.sha256(envelopeData),
                primaryByteCount: envelopeData.count,
                payloadSHA256: PersistenceDigestV1.sha256(envelope.payload))
        }
    }

    func compareAndSwap(expected: PersistenceAuthorityV1,
                        candidate: Data) -> PersistenceCASResultV1 {
        guard case .slot(let expectedSlot, let generation) = expected.owner,
              expectedSlot == slotID else { return .refused(.wrongSlot) }
        do {
            return try lease.withActiveWriter(generation: generation) {
                let priorBytes = try Data(contentsOf: saveURL)
                let envelope = try readEnvelope(priorBytes)
                guard PersistenceDigestV1.sha256(priorBytes) == expected.primarySHA256,
                      priorBytes.count == expected.primaryByteCount,
                      PersistenceDigestV1.sha256(envelope.payload) == expected.payloadSHA256
                else { return .refused(.staleAuthority) }
                let state = try decode(candidate)
                let payloadSHA = PersistenceDigestV1.sha256(candidate)
                if envelope.payload == candidate {
                    return .alreadyCommitted(.init(
                        owner: expected.owner, payloadSHA256: payloadSHA,
                        payloadByteCount: candidate.count,
                        envelopeSHA256: PersistenceDigestV1.sha256(priorBytes),
                        envelopeByteCount: priorBytes.count))
                }
                var replacement = envelope
                replacement.payload = candidate
                replacement.metadata = .make(
                    id: slotID, name: envelope.metadata.name, state: state,
                    createdAt: envelope.metadata.createdAt,
                    lastPlayedAt: state.meta.lastSavedAt ?? envelope.metadata.lastPlayedAt)
                let replacementBytes = try Self.encoder().encode(replacement)
                let receipt = PersistenceCommitReceiptV1(
                    owner: expected.owner, payloadSHA256: payloadSHA,
                    payloadByteCount: candidate.count,
                    envelopeSHA256: PersistenceDigestV1.sha256(replacementBytes),
                    envelopeByteCount: replacementBytes.count)
                do {
                    try replacementBytes.write(to: saveURL, options: .atomic)
                    let readback = try Data(contentsOf: saveURL)
                    guard readback == replacementBytes,
                          try readEnvelope(readback).payload == candidate else {
                        return .refused(.ambiguousReadback)
                    }
                    return .committed(receipt)
                } catch {
                    if let readback = try? Data(contentsOf: saveURL),
                       readback == replacementBytes {
                        return .recoveredDurable(receipt)
                    }
                    return .refused(.writeFailed)
                }
            }
        } catch let error as SaveSlotPayloadError {
            switch error {
            case .retiredWriter: return .refused(.retiredWriter)
            case .staleWriter: return .refused(.staleAuthority)
            case .wrongSlot: return .refused(.wrongSlot)
            case .futureIncompatible: return .refused(.futureAuthority)
            case .corruptEnvelope: return .refused(.corruptAuthority)
            }
        } catch {
            return .refused(.corruptAuthority)
        }
    }

    /// GameStore's DEBUG reset immediately writes a fresh state. Keeping the owned envelope in
    /// place lets that write preserve slot identity/name instead of deleting the campaign itself.
    func deleteEverything() {}

    private func readEnvelope() throws -> SaveSlotEnvelope {
        try readEnvelope(Data(contentsOf: saveURL))
    }

    private func readEnvelope(_ data: Data) throws -> SaveSlotEnvelope {
        guard let envelope = try? Self.decoder().decode(
            SaveSlotEnvelope.self, from: data),
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
