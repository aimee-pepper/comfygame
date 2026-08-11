import Foundation

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
    var saveSchemaVersion: Int

    static func make(id: SaveSlotID, name: String, state: GameState,
                     createdAt: Date, lastPlayedAt: Date) -> SaveSlotMetadata {
        let location = state.worlds.activeRun == nil ? "Home" : "Expedition"
        let pages = state.reality.library.foundPages.count + state.reality.library.foundWritings.count
        let progression = "\(state.reality.library.foundTravellers.count) met · \(pages) writings"
        return SaveSlotMetadata(id: id, name: name, createdAt: createdAt,
                                lastPlayedAt: lastPlayedAt,
                                binderLevel: state.base.binderCharacter.level,
                                location: location, progression: progression,
                                saveSchemaVersion: state.schemaVersion)
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
