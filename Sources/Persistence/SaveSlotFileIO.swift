import CryptoKit
import Foundation

/// The slot directory is the catalogue: every UUID envelope owns its metadata and exact payload in
/// one atomic file. There is no second mutable index that can point at a half-written campaign.
actor SaveSlotFileIO {
    private struct ActiveSelection: Codable, Equatable {
        var slotID: SaveSlotID?
    }

    let rootDirectory: URL
    let slotsDirectory: URL
    let trashDirectory: URL
    let legacySaveURL: URL
    let activeSelectionURL: URL
    /// Persisted selection is not a writer lease: after relaunch the chooser must be free to act.
    private var leasedSlotID: SaveSlotID?
    private var leasedWriter: SaveSlotWriterLease?

    init(directory: URL, legacyFileName: String = "bookbinder-save.json") {
        rootDirectory = directory
        slotsDirectory = directory.appending(path: "bookbinder-slots", directoryHint: .isDirectory)
        trashDirectory = directory.appending(path: "bookbinder-slot-trash", directoryHint: .isDirectory)
        legacySaveURL = directory.appending(path: legacyFileName)
        activeSelectionURL = directory.appending(path: "bookbinder-active-slot.json")
    }

    /// Read-only inspection. It never quarantines, rewrites, adopts or deletes anything.
    func inspect(progress: @Sendable (Int, Int) -> Void = { _, _ in }) -> [SaveSlotDescriptor] {
        let urls = slotFileURLs()
        progress(0, urls.count)
        var descriptors: [SaveSlotDescriptor] = []
        descriptors.reserveCapacity(urls.count)
        for (index, url) in urls.enumerated() {
            descriptors.append(descriptor(at: url))
            progress(index + 1, urls.count)
        }
        return descriptors.sorted { lhs, rhs in
            switch (lhs.metadata?.lastPlayedAt, rhs.metadata?.lastPlayedAt) {
            case let (a?, b?) where a != b: return a > b
            default: return lhs.id.description < rhs.id.description
            }
        }
    }

    /// The one mutating migration entry point. A digest-derived UUID makes every interrupted retry
    /// converge on the same envelope, while the exact legacy bytes remain the owned payload.
    @discardableResult
    func adoptLegacyIfNeeded(now: Date = Date()) throws -> SaveSlotID? {
        let backupURL = rootDirectory.appending(path: "bookbinder-save.json.backup")
        let primary = try? Data(contentsOf: legacySaveURL)
        let backup = try? Data(contentsOf: backupURL)
        guard primary != nil || backup != nil else {
            return nil
        }
        let primaryValid = primary.flatMap { try? decodePayload($0) } != nil
        let backupValid = backup.flatMap { try? decodePayload($0) } != nil
        if !primaryValid, backupValid {
            // Choosing an earlier copy over an existing primary is destructive recovery and must
            // be explicitly confirmed through recoverRawBackup(_:), never during app launch.
            return nil
        }
        // A corrupt primary never masks its last known-good backup. If both are broken, preserve
        // exactly one visible invalid slot (the primary when present) rather than inventing state.
        let payload: Data
        let usedBackup: Bool
        if primaryValid, let primary {
            payload = primary
            usedBackup = false
        } else if backupValid, let backup {
            payload = backup
            usedBackup = true
        } else if let primary {
            payload = primary
            usedBackup = false
        } else {
            payload = backup!
            usedBackup = true
        }
        let id = Self.legacyID(for: payload)
        let destination = slotURL(id)
        let destinationExisted = FileManager.default.fileExists(
            atPath: destination.path(percentEncoded: false))
        if !destinationExisted {
            let metadata: SaveSlotMetadata
            if let state = try? decodePayload(payload) {
                metadata = .make(id: id, name: "Legacy campaign", state: state,
                                 createdAt: state.meta.lastSavedAt ?? now,
                                 lastPlayedAt: state.meta.lastSavedAt ?? now)
            } else {
                metadata = SaveSlotMetadata(id: id, name: "Legacy campaign", createdAt: now,
                                            lastPlayedAt: now, binderLevel: 0,
                                            location: "Needs recovery", progression: "Unreadable save",
                                            saveSchemaVersion: Migrations.probeSchemaVersion(payload) ?? 0)
            }
            try writeEnvelope(SaveSlotEnvelope(metadata: metadata, payload: payload), to: destination)
        }
        if readActiveSelection() == nil, descriptor(at: destination).isValid {
            try writeActiveSelection(id)
        }
        if primaryValid, backupValid, primary == backup {
            // Explicit recovery intentionally preserves the validated .backup byte-for-byte.
            // The digest-owned destination makes repeated launches converge without another copy.
            return id
        }
        if !primaryValid && !backupValid {
            // The visible wrapper is export-only; both original raw sources remain untouched.
            return destinationExisted ? nil : id
        }
        if usedBackup {
            try archiveIfPresent(legacySaveURL, as: "bookbinder-save.json.legacy-corrupt-primary")
            try archiveIfPresent(backupURL, as: "bookbinder-save.json.legacy-adopted")
        } else {
            // Move the non-authoritative backup first. If archiving is interrupted, the chosen
            // primary remains for a retry that deterministically resolves to the same slot ID.
            try archiveIfPresent(backupURL, as: "bookbinder-save.json.legacy-backup-preserved")
            try archiveIfPresent(legacySaveURL, as: "bookbinder-save.json.legacy-adopted")
        }
        return id
    }

    func assessRawRecovery() -> CampaignRecoveryAssessmentV1? {
        let backupURL = rootDirectory.appending(path: "bookbinder-save.json.backup")
        let primary = try? Data(contentsOf: legacySaveURL)
        let backup = try? Data(contentsOf: backupURL)
        guard let source = primary ?? backup else { return nil }
        let sourceHash = Self.sha256(source)
        if let primary, let version = Migrations.probeSchemaVersion(primary),
           version > Tuning.saveSchemaVersion {
            return .init(subject: .rawSave, sourceSHA256: sourceHash, metadata: nil,
                         classification: .futureIncompatible(foundVersion: version,
                                                              supportedVersion: Tuning.saveSchemaVersion))
        }
        if let primary, let state = try? decodePayload(primary) {
            let version = Migrations.probeSchemaVersion(primary) ?? Tuning.saveSchemaVersion
            return .init(subject: .rawSave, sourceSHA256: sourceHash, metadata: nil,
                         classification: .playable(sourceVersion: version,
                                                   migratedVersion: Tuning.saveSchemaVersion,
                                                   hasCompletePendingTransaction:
                                                    Self.hasCompletePendingTransaction(state)))
        }
        guard let backup else {
            return .init(subject: .rawSave, sourceSHA256: sourceHash, metadata: nil,
                         classification: .invalid(.noValidatedRecoverySource))
        }
        guard (try? decodePayload(backup)) != nil else {
            return .init(subject: .rawSave, sourceSHA256: sourceHash, metadata: nil,
                         classification: .invalid(.noValidatedRecoverySource))
        }
        return .init(subject: .rawSave, sourceSHA256: sourceHash, metadata: nil,
                     classification: .recoverableRawBackup(primary: Self.fingerprint(primary ?? Data()),
                                                           backup: Self.fingerprint(backup)))
    }

    func assessSlotRecovery(_ id: SaveSlotID) -> CampaignRecoveryAssessmentV1 {
        let url = slotURL(id)
        guard let bytes = try? Data(contentsOf: url) else {
            return .init(subject: .slot(id), sourceSHA256: "", metadata: nil,
                         classification: .invalid(.unreadablePrimary))
        }
        let hash = Self.sha256(bytes)
        guard let envelope = try? decoder().decode(SaveSlotEnvelope.self, from: bytes) else {
            return .init(subject: .slot(id), sourceSHA256: hash, metadata: nil,
                         classification: .invalid(.noValidatedRecoverySource))
        }
        guard envelope.metadata.id == id else {
            return .init(subject: .slot(id), sourceSHA256: hash, metadata: nil,
                         classification: .invalid(.slotIdentityMismatch))
        }
        if envelope.schemaVersion > SaveSlotEnvelope.schemaVersion {
            return .init(subject: .slot(id), sourceSHA256: hash, metadata: envelope.metadata,
                         classification: .futureIncompatible(foundVersion: envelope.schemaVersion,
                                                              supportedVersion: SaveSlotEnvelope.schemaVersion))
        }
        if let version = Migrations.probeSchemaVersion(envelope.payload),
           version > Tuning.saveSchemaVersion {
            return .init(subject: .slot(id), sourceSHA256: hash, metadata: envelope.metadata,
                         classification: .futureIncompatible(foundVersion: version,
                                                              supportedVersion: Tuning.saveSchemaVersion))
        }
        guard let state = try? decodePayload(envelope.payload) else {
            return .init(subject: .slot(id), sourceSHA256: hash, metadata: envelope.metadata,
                         classification: .invalid(.invalidMigration))
        }
        let version = Migrations.probeSchemaVersion(envelope.payload) ?? Tuning.saveSchemaVersion
        return .init(subject: .slot(id), sourceSHA256: hash, metadata: envelope.metadata,
                     classification: .playable(sourceVersion: version,
                                               migratedVersion: Tuning.saveSchemaVersion,
                                               hasCompletePendingTransaction:
                                                Self.hasCompletePendingTransaction(state)))
    }

    @discardableResult
    func recoverRawBackup(_ assessment: CampaignRecoveryAssessmentV1) throws -> SaveSlotID {
        guard case .rawSave = assessment.subject,
              case .recoverableRawBackup(let expectedPrimary, let expectedBackup) = assessment.classification else {
            throw CampaignRecoveryRefusalV1.noValidatedRecoverySource
        }
        let backupURL = rootDirectory.appending(path: "bookbinder-save.json.backup")
        let primary = try? Data(contentsOf: legacySaveURL)
        let backup = try? Data(contentsOf: backupURL)
        if let primary, let backup, Self.fingerprint(primary) == expectedBackup,
           Self.fingerprint(backup) == expectedBackup,
           (try? decodePayload(primary)) != nil {
            return Self.legacyID(for: primary)
        }
        guard let backup,
              Self.fingerprint(primary ?? Data()) == expectedPrimary,
              Self.fingerprint(backup) == expectedBackup else {
            throw CampaignRecoveryRefusalV1.staleAssessment
        }
        guard (try? decodePayload(backup)) != nil else {
            throw CampaignRecoveryRefusalV1.noValidatedRecoverySource
        }
        let destination = slotURL(expectedBackup.identity)
        if let existing = try? Data(contentsOf: destination) {
            guard let envelope = try? decoder().decode(SaveSlotEnvelope.self, from: existing),
                  envelope.metadata.id == expectedBackup.identity,
                  envelope.payload == backup else {
                throw CampaignRecoveryRefusalV1.destinationCollision
            }
        }
        let archive = rootDirectory.appending(
            path: "bookbinder-save.json.recovery-original-\(expectedPrimary.sha256)")
        if let primary {
            if let existing = try? Data(contentsOf: archive) {
                guard existing == primary else { throw CampaignRecoveryRefusalV1.archiveCollision }
            } else {
                do { try primary.write(to: archive, options: .atomic) }
                catch { throw CampaignRecoveryRefusalV1.writeFailed }
            }
        }
        guard (try? Data(contentsOf: legacySaveURL)) == primary,
              (try? Data(contentsOf: backupURL)) == backup else {
            throw CampaignRecoveryRefusalV1.staleAssessment
        }
        do { try backup.write(to: legacySaveURL, options: .atomic) }
        catch { throw CampaignRecoveryRefusalV1.writeFailed }
        guard let committed = try? Data(contentsOf: legacySaveURL), committed == backup,
              (try? decodePayload(committed)) != nil else {
            if let primary { try? primary.write(to: legacySaveURL, options: .atomic) }
            throw CampaignRecoveryRefusalV1.writeFailed
        }
        return Self.legacyID(for: backup)
    }

    func activeSlotID() -> SaveSlotID? { readActiveSelection() }

    func legacyExportURL() -> URL { legacySaveURL }

    /// Exact envelope export for corrupt/future recovery. Merely returning this URL performs no
    /// decode, quarantine or mutation; callers copy the whole file byte-for-byte.
    func exportURL(for id: SaveSlotID) throws -> URL {
        let url = slotURL(id)
        guard FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) else {
            throw SaveSlotError.slotNotFound(id)
        }
        return url
    }

    @discardableResult
    func acquireWriterLease(for id: SaveSlotID) throws -> SaveSlotLoaded {
        if let held = leasedSlotID, held != id { throw SaveSlotError.writerLeaseAlreadyHeld(held) }
        let loaded = try load(id)
        leasedSlotID = id
        leasedWriter = SaveSlotWriterLease()
        return loaded
    }

    func payloadIOForLeasedSlot() throws -> SaveSlotPayloadIO {
        guard let id = leasedSlotID, let writer = leasedWriter else {
            throw SaveSlotError.slotInvalid(readActiveSelection() ?? SaveSlotID())
        }
        return SaveSlotPayloadIO(saveURL: slotURL(id), slotID: id, lease: writer)
    }

    /// Selected-slot preparation failed or was cancelled before a GameStore took ownership.
    /// Retire the capability without touching either the envelope or persisted selection.
    func releaseWriterLeaseWithoutSaving() {
        leasedWriter?.retire()
        leasedWriter = nil
        leasedSlotID = nil
    }

    /// Return to the campaign chooser after the active GameStore has finished its own pending
    /// queue. This final exact save and lease retirement are serialized; selection remains as the
    /// honest most-recently active campaign hint.
    @discardableResult
    func releaseWriterLease(flushing state: GameState,
                            now: Date = Date()) throws -> SaveSlotLoaded? {
        guard let active = leasedSlotID else { return nil }
        let saved = try save(active, state: state, now: now)
        leasedWriter?.retire()
        leasedWriter = nil
        leasedSlotID = nil
        return saved
    }

    func continueSlot() -> SaveSlotLoaded? {
        if let activeID = readActiveSelection(), let active = try? load(activeID) {
            return active
        }
        for descriptor in inspect() where descriptor.isValid {
            if let loaded = try? load(descriptor.id) { return loaded }
        }
        return nil
    }

    func load(_ id: SaveSlotID) throws -> SaveSlotLoaded {
        let url = slotURL(id)
        guard FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) else {
            throw SaveSlotError.slotNotFound(id)
        }
        let envelope: SaveSlotEnvelope
        do { envelope = try decoder().decode(SaveSlotEnvelope.self, from: Data(contentsOf: url)) }
        catch { throw SaveSlotError.slotInvalid(id) }
        guard envelope.metadata.id == id else { throw SaveSlotError.slotInvalid(id) }
        guard envelope.schemaVersion <= SaveSlotEnvelope.schemaVersion else {
            throw SaveSlotError.futureIncompatible(schemaVersion: envelope.schemaVersion)
        }
        let state = try decodePayload(envelope.payload)
        return SaveSlotLoaded(metadata: envelope.metadata, state: state)
    }

    @discardableResult
    func create(name: String, state: GameState = .newGame(), now: Date = Date(),
                id: SaveSlotID = SaveSlotID(),
                flushingActiveState: GameState? = nil) throws -> SaveSlotLoaded {
        try flushActiveIfRequired(using: flushingActiveState, now: now)
        let url = slotURL(id)
        guard !FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) else {
            throw SaveSlotError.duplicateSlot(id)
        }
        try rejectFuture(state.schemaVersion)
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let metadata = SaveSlotMetadata.make(id: id,
                                             name: cleanName.isEmpty ? "New campaign" : cleanName,
                                             state: state, createdAt: now, lastPlayedAt: now)
        let envelope = SaveSlotEnvelope(metadata: metadata, payload: try SaveCodec.encode(state))
        try writeEnvelope(envelope, to: url)
        try writeActiveSelection(id) // never points to a payload that has not committed
        return SaveSlotLoaded(metadata: metadata, state: state)
    }

    @discardableResult
    func save(_ id: SaveSlotID, state: GameState, now: Date = Date()) throws -> SaveSlotLoaded {
        if leasedSlotID == id, let writer = leasedWriter {
            return try writer.withActiveWriter { try saveUnlocked(id, state: state, now: now) }
        }
        return try saveUnlocked(id, state: state, now: now)
    }

    private func saveUnlocked(_ id: SaveSlotID, state: GameState,
                              now: Date) throws -> SaveSlotLoaded {
        try rejectFuture(state.schemaVersion)
        let prior = try load(id)
        let metadata = SaveSlotMetadata.make(id: id, name: prior.metadata.name, state: state,
                                             createdAt: prior.metadata.createdAt,
                                             lastPlayedAt: now)
        let envelope = SaveSlotEnvelope(metadata: metadata, payload: try SaveCodec.encode(state))
        try writeEnvelope(envelope, to: slotURL(id))
        return SaveSlotLoaded(metadata: metadata, state: state)
    }

    @discardableResult
    func switchTo(_ id: SaveSlotID, flushingActiveState: GameState?,
                  now: Date = Date()) throws -> SaveSlotLoaded {
        let target = try load(id) // validate before changing ownership
        if leasedSlotID != id {
            try flushActiveIfRequired(using: flushingActiveState, now: now)
        }
        let touched = try touch(target, now: now)
        try writeActiveSelection(id)
        return touched
    }

    /// Confirmation is identity + displayed name. The exact envelope is soft-moved only after the
    /// active writer has flushed and the active pointer has been cleared.
    func delete(_ id: SaveSlotID, confirmingName: String, flushingActiveState: GameState?,
                now: Date = Date()) throws {
        guard let target = inspect().first(where: { $0.id == id }) else {
            throw SaveSlotError.slotNotFound(id)
        }
        guard target.displayName == confirmingName else { throw SaveSlotError.confirmationMismatch }
        // A corrupt/future target cannot be decoded merely to delete it. Flush only a separate
        // live campaign; when deleting the leased target, the caller has already finished its
        // GameStore queue and this operation only retires the capability.
        if let leased = leasedSlotID, leased != id {
            try flushActiveIfRequired(using: flushingActiveState, now: now)
        } else if leasedSlotID == id {
            releaseWriterLeaseWithoutSaving()
        }
        if readActiveSelection() == id { try writeActiveSelection(nil) }
        try FileManager.default.createDirectory(at: trashDirectory,
                                                withIntermediateDirectories: true)
        let suffix = ISO8601DateFormatter().string(from: now).replacingOccurrences(of: ":", with: "-")
        let destination = trashDirectory.appending(path: "\(id.description)-\(suffix).slot.json")
        try FileManager.default.moveItem(at: slotURL(id), to: destination)
    }

    private func touch(_ loaded: SaveSlotLoaded, now: Date) throws -> SaveSlotLoaded {
        if leasedSlotID == loaded.metadata.id, let writer = leasedWriter {
            return try writer.withActiveWriter { try touchUnlocked(loaded, now: now) }
        }
        return try touchUnlocked(loaded, now: now)
    }

    private func touchUnlocked(_ loaded: SaveSlotLoaded, now: Date) throws -> SaveSlotLoaded {
        let url = slotURL(loaded.metadata.id)
        var envelope = try decoder().decode(SaveSlotEnvelope.self, from: Data(contentsOf: url))
        envelope.metadata.lastPlayedAt = now
        try writeEnvelope(envelope, to: url)
        return SaveSlotLoaded(metadata: envelope.metadata, state: loaded.state)
    }

    private func flushActiveIfRequired(using state: GameState?, now: Date) throws {
        guard let active = leasedSlotID else { return }
        guard let state else { throw SaveSlotError.activeFlushRequired(active) }
        _ = try save(active, state: state, now: now)
        leasedWriter?.retire()
        leasedSlotID = nil
        leasedWriter = nil
    }

    private func decodePayload(_ payload: Data) throws -> GameState {
        if let version = Migrations.probeSchemaVersion(payload), version > Tuning.saveSchemaVersion {
            throw SaveSlotError.futureIncompatible(schemaVersion: version)
        }
        return try SaveCodec.decode(payload)
    }

    private func rejectFuture(_ version: Int) throws {
        if version > Tuning.saveSchemaVersion {
            throw SaveSlotError.futureIncompatible(schemaVersion: version)
        }
    }

    private func descriptor(at url: URL) -> SaveSlotDescriptor {
        let fileStem = url.deletingPathExtension().deletingPathExtension().lastPathComponent
        let fallbackID = UUID(uuidString: fileStem).map(SaveSlotID.init(rawValue:))
            ?? Self.legacyID(for: Data(fileStem.utf8))
        guard let data = try? Data(contentsOf: url),
              let envelope = try? decoder().decode(SaveSlotEnvelope.self, from: data),
              envelope.metadata.id == fallbackID else {
            return SaveSlotDescriptor(id: fallbackID, metadata: nil,
                                      validity: .corrupt(reason: "Unreadable slot envelope"))
        }
        if envelope.schemaVersion > SaveSlotEnvelope.schemaVersion {
            return SaveSlotDescriptor(id: fallbackID, metadata: envelope.metadata,
                                      validity: .futureIncompatible(
                                        schemaVersion: envelope.schemaVersion))
        }
        if let version = Migrations.probeSchemaVersion(envelope.payload),
           version > Tuning.saveSchemaVersion {
            return SaveSlotDescriptor(id: fallbackID, metadata: envelope.metadata,
                                      validity: .futureIncompatible(schemaVersion: version))
        }
        guard (try? SaveCodec.decode(envelope.payload)) != nil else {
            return SaveSlotDescriptor(id: fallbackID, metadata: envelope.metadata,
                                      validity: .corrupt(reason: "Unreadable campaign payload"))
        }
        return SaveSlotDescriptor(id: fallbackID, metadata: envelope.metadata, validity: .valid)
    }

    private func slotFileURLs() -> [URL] {
        (try? FileManager.default.contentsOfDirectory(at: slotsDirectory,
                                                       includingPropertiesForKeys: nil))?
            .filter {
                $0.lastPathComponent.hasSuffix(".slot.json")
                    && UUID(uuidString: $0.deletingPathExtension()
                        .deletingPathExtension().lastPathComponent) != nil
            } ?? []
    }

    private func slotURL(_ id: SaveSlotID) -> URL {
        slotsDirectory.appending(path: "\(id.description).slot.json")
    }

    private func writeEnvelope(_ envelope: SaveSlotEnvelope, to url: URL) throws {
        try FileManager.default.createDirectory(at: slotsDirectory,
                                                withIntermediateDirectories: true)
        try encoder().encode(envelope).write(to: url, options: .atomic)
    }

    private func readActiveSelection() -> SaveSlotID? {
        guard let data = try? Data(contentsOf: activeSelectionURL),
              let selection = try? decoder().decode(ActiveSelection.self, from: data),
              let id = selection.slotID,
              FileManager.default.fileExists(atPath: slotURL(id).path(percentEncoded: false)) else {
            return nil
        }
        return id
    }

    private func writeActiveSelection(_ id: SaveSlotID?) throws {
        try FileManager.default.createDirectory(at: rootDirectory,
                                                withIntermediateDirectories: true)
        try encoder().encode(ActiveSelection(slotID: id)).write(to: activeSelectionURL,
                                                                 options: .atomic)
    }

    private func archiveIfPresent(_ source: URL, as name: String) throws {
        guard FileManager.default.fileExists(atPath: source.path(percentEncoded: false)) else { return }
        var destination = rootDirectory.appending(path: name)
        if FileManager.default.fileExists(atPath: destination.path(percentEncoded: false)) {
            let digest = Self.legacyID(for: try Data(contentsOf: source)).description.prefix(8)
            destination = rootDirectory.appending(path: "\(name)-\(digest)")
        }
        try FileManager.default.moveItem(at: source, to: destination)
    }

    private func encoder() -> JSONEncoder {
        let value = JSONEncoder()
        value.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        value.dateEncodingStrategy = .iso8601
        return value
    }

    private func decoder() -> JSONDecoder {
        let value = JSONDecoder()
        value.dateDecodingStrategy = .iso8601
        return value
    }

    static func legacyID(for payload: Data) -> SaveSlotID {
        let hex = SHA256.hash(data: payload).prefix(16).map { String(format: "%02x", $0) }.joined()
        let value = "\(hex.prefix(8))-\(hex.dropFirst(8).prefix(4))-5\(hex.dropFirst(13).prefix(3))-a\(hex.dropFirst(17).prefix(3))-\(hex.dropFirst(20).prefix(12))"
        return SaveSlotID(rawValue: UUID(uuidString: value)!)
    }

    private static func sha256(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    private static func fingerprint(_ data: Data) -> CampaignRecoveryFingerprintV1 {
        .init(byteCount: data.count, sha256: sha256(data),
              probedSchemaVersion: Migrations.probeSchemaVersion(data),
              identity: legacyID(for: data))
    }

    private static func hasCompletePendingTransaction(_ state: GameState) -> Bool {
        !state.worlds.expeditionReviewQueue.pending.isEmpty
            || state.worlds.pendingWorldArrivalReceiptID != nil
            || state.worlds.pendingAnchorSettlement
            || state.worlds.pendingAnchorSettlementOutcomeID != nil
            || !state.reality.library.recoveredTeachingOffers.isEmpty
    }
}
