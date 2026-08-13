import Foundation

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
        case material(MaterialSample)
    }

    var id: UInt64
    var kind: Kind
    var remainingQuantity: Int
    var unitPrice: Int
    /// Exact persisted objects supplied by this line, one entry per purchasable unit. Old resource
    /// shelves decode empty; item/material shelves without this receipt remain safely unbuyable.
    var frozenUnits: [ItemStack] = []

    private enum CodingKeys: String, CodingKey {
        case id, kind, remainingQuantity, unitPrice, frozenUnits
    }

    init(id: UInt64, kind: Kind, remainingQuantity: Int, unitPrice: Int,
         frozenUnits: [ItemStack] = []) {
        self.id = id
        self.kind = kind
        self.remainingQuantity = remainingQuantity
        self.unitPrice = unitPrice
        self.frozenUnits = frozenUnits
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UInt64.self, forKey: .id)
        kind = try c.decode(Kind.self, forKey: .kind)
        remainingQuantity = try c.decode(Int.self, forKey: .remainingQuantity)
        unitPrice = try c.decode(Int.self, forKey: .unitPrice)
        frozenUnits = try c.decodeIfPresent([ItemStack].self, forKey: .frozenUnits) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(kind, forKey: .kind)
        try c.encode(remainingQuantity, forKey: .remainingQuantity)
        try c.encode(unitPrice, forKey: .unitPrice)
        try c.encode(frozenUnits, forKey: .frozenUnits)
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
}

enum TradingPostCommitResult: Equatable, Sendable {
    case committed
    case stale
    case invalid
    case unaffordable
}
