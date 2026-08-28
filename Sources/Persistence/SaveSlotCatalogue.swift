import Foundation

struct CampaignRecoveryFingerprintV1: Equatable, Sendable {
    var byteCount: Int
    var sha256: String
    var probedSchemaVersion: Int?
    var identity: SaveSlotID
}

enum CampaignRecoverySubjectV1: Equatable, Sendable {
    case rawSave
    case slot(SaveSlotID)
}

enum CampaignRecoveryRefusalV1: Error, Equatable, Sendable {
    case unreadablePrimary, unreadableBackup, noValidatedRecoverySource
    case futureEnvelope(found: Int, supported: Int)
    case futurePayload(found: Int, supported: Int)
    case slotIdentityMismatch, invalidMigration, invalidReceipt, staleAssessment
    case destinationCollision, archiveCollision, writeFailed

    var playerCopy: String {
        switch self {
        case .futureEnvelope, .futurePayload:
            "This campaign was made by a newer version of Bookbinder. Update the app to open it."
        case .slotIdentityMismatch:
            "The recovery copy belongs to a different campaign. Nothing was changed."
        case .staleAssessment:
            "The campaign changed while recovery was being prepared. Nothing was changed. Inspect it again."
        case .writeFailed, .archiveCollision, .destinationCollision:
            "Recovery did not finish. The original campaign is still preserved."
        default:
            "This campaign cannot be recovered automatically. Export the unchanged save for recovery."
        }
    }
}

enum CampaignRecoveryClassificationV1: Equatable, Sendable {
    case playable(sourceVersion: Int, migratedVersion: Int, hasCompletePendingTransaction: Bool)
    case recoverableRawBackup(primary: CampaignRecoveryFingerprintV1,
                              backup: CampaignRecoveryFingerprintV1)
    case invalid(CampaignRecoveryRefusalV1)
    case futureIncompatible(foundVersion: Int, supportedVersion: Int)
}

struct CampaignRecoveryAssessmentV1: Equatable, Sendable {
    var subject: CampaignRecoverySubjectV1
    var sourceSHA256: String
    var metadata: SaveSlotMetadata?
    var classification: CampaignRecoveryClassificationV1
}

struct SaveSlotID: RawRepresentable, Codable, Hashable, Sendable, CustomStringConvertible {
    var rawValue: UUID

    init(rawValue: UUID) { self.rawValue = rawValue }
    init() { rawValue = UUID() }

    var description: String { rawValue.uuidString.lowercased() }
}

struct SaveSlotMetadata: Codable, Equatable, Sendable {
    var id: SaveSlotID
    var name: String
    var createdAt: Date
    var lastPlayedAt: Date
    var binderLevel: Int
    var location: String
    var progression: String
    /// Presentation-only shelf fullness for the campaign card. It is derived from durable facts;
    /// no game rule reads it and old envelopes tolerate its absence.
    var progressBookCount: Int? = nil
    var saveSchemaVersion: Int

    static func make(id: SaveSlotID, name: String, state: GameState,
                     createdAt: Date, lastPlayedAt: Date) -> SaveSlotMetadata {
        let location = state.worlds.activeRun == nil ? "Home" : "Expedition"
        let pages = state.reality.library.foundPages.count + state.reality.library.foundWritings.count
        let progression = "\(state.reality.library.foundTravellers.count) met · \(pages) writings"
        let progressBookCount = CampaignShelfProgress.bookCount(for: state)
        return SaveSlotMetadata(id: id, name: name, createdAt: createdAt,
                                lastPlayedAt: lastPlayedAt,
                                binderLevel: state.base.binderCharacter.level,
                                location: location, progression: progression,
                                progressBookCount: progressBookCount,
                                saveSchemaVersion: state.schemaVersion)
    }
}

enum CampaignShelfProgress {
    static let minimumBooks = 2
    static let maximumBooks = 12

    static func bookCount(for state: GameState) -> Int {
        let library = state.reality.library
        let writings = library.foundPages.count + library.foundWritings.count
        let builtPlaces = state.base.stations.values.count(where: \.isUnlocked)
        let score = max(0, state.base.binderCharacter.level - 1) * 2
            + library.foundTravellers.count * 3
            + writings
            + state.base.completedResearch.count
            + builtPlaces
            + state.reality.lifetime.runsStarted / 2
        return min(maximumBooks, minimumBooks + score / 6)
    }
}

struct SaveSlotEnvelope: Codable, Equatable, Sendable {
    static let schemaVersion = 1
    var schemaVersion: Int = Self.schemaVersion
    var metadata: SaveSlotMetadata
    /// Exact ordinary save bytes. Legacy adoption deliberately stores these without re-encoding.
    var payload: Data
}

enum SaveSlotValidity: Equatable, Sendable {
    case valid
    case corrupt(reason: String)
    case futureIncompatible(schemaVersion: Int)
}

struct SaveSlotDescriptor: Equatable, Sendable, Identifiable {
    var id: SaveSlotID
    var metadata: SaveSlotMetadata?
    var validity: SaveSlotValidity

    var isValid: Bool { validity == .valid }
    var displayName: String {
        metadata?.name ?? "Damaged campaign \(id.description.prefix(8))"
    }
}

struct SaveSlotLoaded: Equatable, Sendable {
    var metadata: SaveSlotMetadata
    var state: GameState
}

enum SaveSlotError: Error, Equatable, Sendable {
    case slotNotFound(SaveSlotID)
    case slotInvalid(SaveSlotID)
    case futureIncompatible(schemaVersion: Int)
    case activeFlushRequired(SaveSlotID)
    case writerLeaseAlreadyHeld(SaveSlotID)
    case confirmationMismatch
    case duplicateSlot(SaveSlotID)
}
