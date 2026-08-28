import CryptoKit
import Foundation

enum TradingPostPhysicalGearLocationV1: Codable, Equatable, Sendable {
    case storehouse(stackID: InstanceID)
    case waiting(stackID: InstanceID)
    case merchant(lineID: UInt64, stackID: InstanceID)
}

struct TradingPostPhysicalGearSaleQuoteV1: Codable, Equatable, Sendable {
    var version: Int = 1
    var stationID: StationID = Stations.tradingPost
    var tradingRevision: UInt64
    var ownershipRevision: UInt64
    var source: TradingPostPhysicalGearLocationV1
    var snapshot: PhysicalGearSnapshotV1
    var unitPrice: Int
    var goldCredit: Int
    var quoteSHA256: String

    mutating func seal() { quoteSHA256 = canonicalDigest() ?? "" }
    func validatesDigest() -> Bool { quoteSHA256 == canonicalDigest() }
    private func canonicalDigest() -> String? {
        var copy = self; copy.quoteSHA256 = ""
        guard let data = try? SaveCodec.makeEncoder().encode(copy) else { return nil }
        return SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}

struct TradingPostPhysicalGearPurchaseQuoteV1: Codable, Equatable, Sendable {
    var version: Int = 1
    var stationID: StationID = Stations.tradingPost
    var tradingRevision: UInt64
    var ownershipRevision: UInt64
    var lineID: UInt64
    var reservedSnapshot: PhysicalGearSnapshotV1
    var frozenUnitPrice: Int
    var goldDebit: Int
    var destination: PhysicalGearConstructionDestinationV1
    var quoteSHA256: String

    mutating func seal() { quoteSHA256 = canonicalDigest() ?? "" }
    func validatesDigest() -> Bool { quoteSHA256 == canonicalDigest() }
    private func canonicalDigest() -> String? {
        var copy = self; copy.quoteSHA256 = ""
        guard let data = try? SaveCodec.makeEncoder().encode(copy) else { return nil }
        return SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}

enum TradingPostPhysicalGearRefusalV1: Codable, Equatable, Sendable {
    case stationUnavailable, notAtHome, encounterActive, sourceMissing, sourceMoved
    case notPhysicalGear, unidentified, favorite, locked, protectedReturn, tradingProtected
    case singularOrApex, legacyMasterwork, invalidReceipt, invalidPersistedState
    case merchantLineMissing, merchantUnitMissing, insufficientGold, duplicateIdentity
    case staleTradingRevision, staleOwnershipRevision, staleQuote, revisionExhausted

    var playerCopy: String? {
        switch self {
        case .stationUnavailable: "Build the Trading Post first."
        case .notAtHome, .encounterActive: "Gear can be traded after you return home."
        case .unidentified: "Identify this piece before selling it."
        case .favorite: "Remove the favorite mark before selling this piece."
        case .locked: "Unlock this piece before selling it."
        case .protectedReturn, .tradingProtected, .singularOrApex:
            "The Trading Post will not buy this piece."
        case .legacyMasterwork:
            "Gear with power carried forward from an older save stays protected until you rebuild it."
        case .insufficientGold: "You do not have enough Gold."
        case .sourceMoved, .staleTradingRevision, .staleOwnershipRevision, .staleQuote:
            "The gear or offer changed. Review it and try again."
        case .sourceMissing: "Those goods are no longer available in that quantity."
        case .notPhysicalGear, .invalidReceipt, .invalidPersistedState, .merchantLineMissing,
             .merchantUnitMissing, .duplicateIdentity, .revisionExhausted: nil
        }
    }
}

enum TradingPostPhysicalGearSaleEvaluationV1: Equatable, Sendable {
    case allowed(TradingPostPhysicalGearSaleQuoteV1)
    case refused(TradingPostPhysicalGearRefusalV1)
}

enum TradingPostPhysicalGearPurchaseEvaluationV1: Equatable, Sendable {
    case allowed(TradingPostPhysicalGearPurchaseQuoteV1)
    case refused(TradingPostPhysicalGearRefusalV1)
}

enum TradingPostPhysicalGearCommitResultV1: Equatable, Sendable {
    case committed
    case refused(TradingPostPhysicalGearRefusalV1)
}

/// Home-layer Trading Post state. A missing value in an old save decodes to this empty,
/// awaiting-first-expedition snapshot; opening the station never rolls stock.
struct TradingPostState: Codable, Equatable, Sendable {
    static let schemaVersion = 1

    var stockSchemaVersion: Int = Self.schemaVersion
    var refreshSequence: UInt64 = 0
    var expeditionOutcomeID: ExpeditionOutcomeID?
    var campaignSeed: UInt64?
    var stock: [TradingPostStockLine] = []
    var essenceBundlesRemaining: Int = 0
    var nextStockLineID: UInt64 = 1
    /// Incremented by every committed trade or refresh. Transaction previews bind to this value.
    var inventoryRevision: UInt64 = 0

    init() {}

    private enum CodingKeys: String, CodingKey {
        case stockSchemaVersion, refreshSequence, expeditionOutcomeID, campaignSeed, stock
        case essenceBundlesRemaining, nextStockLineID, inventoryRevision
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        stockSchemaVersion = try c.decodeIfPresent(Int.self, forKey: .stockSchemaVersion) ?? Self.schemaVersion
        refreshSequence = try c.decodeIfPresent(UInt64.self, forKey: .refreshSequence) ?? 0
        expeditionOutcomeID = try c.decodeIfPresent(ExpeditionOutcomeID.self, forKey: .expeditionOutcomeID)
        campaignSeed = try c.decodeIfPresent(UInt64.self, forKey: .campaignSeed)
        stock = try c.decodeIfPresent([TradingPostStockLine].self, forKey: .stock) ?? []
        essenceBundlesRemaining = max(0, try c.decodeIfPresent(Int.self,
                                                               forKey: .essenceBundlesRemaining) ?? 0)
        nextStockLineID = max(1, try c.decodeIfPresent(UInt64.self, forKey: .nextStockLineID) ?? 1)
        inventoryRevision = try c.decodeIfPresent(UInt64.self, forKey: .inventoryRevision) ?? 0
    }
}

struct TradingPostStockLine: Codable, Equatable, Identifiable, Sendable {
    enum Kind: Codable, Equatable, Sendable {
        case resource(ResourceID)
        case item(ItemID)
        case material(CraftMaterialUnitV1)
    }

    var id: UInt64
    var kind: Kind
    var remainingQuantity: Int
    var unitPrice: Int
    /// Exact persisted objects supplied by this line, one entry per purchasable unit. Old resource
    /// shelves decode empty; item/material shelves without this receipt remain safely unbuyable.
    var frozenUnits: [ItemStack] = []
    var frozenMaterialUnits: [CraftMaterialUnitV1] = []

    private enum CodingKeys: String, CodingKey {
        case id, kind, remainingQuantity, unitPrice, frozenUnits, frozenMaterialUnits
    }

    init(id: UInt64, kind: Kind, remainingQuantity: Int, unitPrice: Int,
         frozenUnits: [ItemStack] = [], frozenMaterialUnits: [CraftMaterialUnitV1] = []) {
        self.id = id
        self.kind = kind
        self.remainingQuantity = remainingQuantity
        self.unitPrice = unitPrice
        self.frozenUnits = frozenUnits
        self.frozenMaterialUnits = frozenMaterialUnits
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UInt64.self, forKey: .id)
        kind = try c.decode(Kind.self, forKey: .kind)
        remainingQuantity = try c.decode(Int.self, forKey: .remainingQuantity)
        unitPrice = try c.decode(Int.self, forKey: .unitPrice)
        frozenUnits = try c.decodeIfPresent([ItemStack].self, forKey: .frozenUnits) ?? []
        frozenMaterialUnits = try c.decodeIfPresent([CraftMaterialUnitV1].self,
                                                     forKey: .frozenMaterialUnits) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(kind, forKey: .kind)
        try c.encode(remainingQuantity, forKey: .remainingQuantity)
        try c.encode(unitPrice, forKey: .unitPrice)
        try c.encode(frozenUnits, forKey: .frozenUnits)
        try c.encode(frozenMaterialUnits, forKey: .frozenMaterialUnits)
    }
}

enum TradingPostTradeBand: String, Codable, CaseIterable, Sendable {
    case staple, uncommon, rare, precious, nontradeable

    var sellPrice: Int? {
        switch self {
        case .staple: 1
        case .uncommon: 2
        case .rare: 5
        case .precious: 12
        case .nontradeable: nil
        }
    }

    var buyPrice: Int? {
        switch self {
        case .staple: 3
        case .uncommon: 6
        case .rare, .precious, .nontradeable: nil
        }
    }
}

struct TradingPostSalePreview: Equatable, Sendable {
    struct ResourceLine: Equatable, Sendable {
        var id: ResourceID
        var quantity: Int
        var unitPrice: Int
    }

    struct ItemLine: Equatable, Sendable {
        var location: TradingPostItemLocation
        var stackID: InstanceID
        var quantity: Int
        var unitPrice: Int
        /// Exact frozen object at preview time; commit rejects any changed identity, protection,
        /// provenance, price input or quantity rather than selling a replacement by accident.
        var snapshot: ItemStack
    }

    var revision: UInt64
    var resources: [ResourceLine]
    var items: [ItemLine] = []
    var essenceQuantity: Int
    var goldTotal: Int
}

enum TradingPostItemLocation: String, Codable, Equatable, Sendable {
    case stored
    case overflow
}

struct TradingPostItemSaleRequest: Equatable, Sendable {
    var location: TradingPostItemLocation
    var stackID: InstanceID
    var quantity: Int
}

struct TradingPostPurchasePreview: Equatable, Sendable {
    enum Kind: Equatable, Sendable {
        case stock(lineID: UInt64, kind: TradingPostStockLine.Kind)
        case essence
    }

    var revision: UInt64
    var kind: Kind
    var quantity: Int
    var goldCost: Int
    var frozenUnits: [ItemStack] = []
    var frozenMaterialUnits: [CraftMaterialUnitV1] = []
}

enum TradingPostCommitResult: Equatable, Sendable {
    case committed
    case stale
    case invalid
    case unaffordable
}
