import Foundation

/// Recycler-local persistence. Station construction/tier remains in `BaseState.stations`; this
/// revision binds destructive previews without inventing provenance or a second inventory owner.
struct RecyclerState: Codable, Equatable, Sendable {
    static let schemaVersion = 1
    var schemaVersion: Int = Self.schemaVersion
    var inventoryRevision: UInt64 = 0

    init() {}

    private enum CodingKeys: String, CodingKey { case schemaVersion, inventoryRevision }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try c.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? Self.schemaVersion
        inventoryRevision = try c.decodeIfPresent(UInt64.self, forKey: .inventoryRevision) ?? 0
    }
}

enum RecyclerRecoveryRoute: Equatable, Sendable {
    case constructionReceipt
    case authoredSalvage(profileID: String)
}

struct RecyclerPreview: Equatable, Sendable {
    var revision: UInt64
    var location: TradingPostItemLocation
    var stackID: InstanceID
    var snapshot: ItemStack
    var serviceTier: Int
    var route: RecyclerRecoveryRoute
    /// Receipt indices, not copies chosen by value: duplicate-looking samples remain distinct work.
    var selectedReceiptIndices: [Int]
    var recoveryCapacity: Int
    var returnedSamples: [CraftMaterialUnitV1]
    var returnedResources: ResourcePool
}

enum RecyclerCommitResult: Equatable, Sendable {
    case committed
    case stale
    case invalid
}
