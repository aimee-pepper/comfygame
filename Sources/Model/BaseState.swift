import Foundation

/// Layer 2 — Home Base. Persists between runs; a future reset wipes this and keeps `RealityState`.
struct BaseState: Codable, Equatable, Sendable {
    /// Refined common currency: binds books, identifies items, buys upgrades.
    var essence: Int = Tuning.Economy.startingEssence
    /// Raw stockpiles hauled home (Ore, Fiber, Essence-raw…). Motes live in Reality.
    var resources: ResourcePool = ResourcePool()
    var inventory: Inventory = Inventory(slots: Tuning.Economy.startingInventorySlots)

    /// Owned catalog entries. Definitions are data; the save stores only which ones are owned.
    var ownedSymbols: Set<SymbolID> = []
    var ownedGambitPieces: [GambitPieceID] = []

    /// Per-station progression, keyed by the data-driven station catalog. The Base screen renders
    /// `ContentCatalog.stations` filtered by `isUnlocked`, so adding a v1+ building (blacksmith,
    /// tavern, distillery) is a JSON edit, not a new hardcoded button.
    var stations: [StationID: StationState] = [:]

    /// The book currently being composed at the Writing Desk. Survives a force-quit mid-compose.
    var bookDraft: BookDraft = BookDraft()

    /// The companion's gambit list. Edited on the Party screen, out of combat only.
    var companion: CompanionState = CompanionState()

    /// Purchased at the Workshop. Until then the Binder is manual every turn.
    var hasAutomateSelfUnlock: Bool = false

    /// Upgrades bought for the satchel — the bag you carry *into* a world.
    ///
    /// Deliberately independent of the Storehouse (decisions-log session 2): carry limit forces
    /// "keep it or leave it" in-world, storage limit forces "hoard or refine" at home. Two
    /// pressures, two upgrade paths.
    var satchelTier: Int = 0

    static func newGame() -> BaseState {
        var state = BaseState()
        state.ownedSymbols = Set(ContentCatalog.shared.starterSymbolIDs)
        state.ownedGambitPieces = ContentCatalog.shared.starterGambitPieceIDs
        state.stations = ContentCatalog.shared.stations.reduce(into: [:]) { result, station in
            result[station.id] = StationState(isUnlocked: station.unlockedAtStart, tier: station.startingTier)
        }
        state.companion.gambits = Array(state.ownedGambitPieces.prefix(Tuning.Encounter.startingGambitSlots))
        state.syncInventoryCapacity()
        return state
    }

    // MARK: Derived

    func station(_ id: StationID) -> StationState { stations[id] ?? StationState(isUnlocked: false, tier: 0) }

    /// What the inventory *should* hold given current upgrades. `tier` counts upgrades purchased,
    /// so tier 0 is the un-upgraded Storehouse and grants no bonus.
    var inventoryCapacity: Int {
        Tuning.Economy.startingInventorySlots
            + station(Stations.storehouse).tier * Tuning.Economy.inventorySlotsPerStorehouseTier
    }

    /// How much you can carry into a world. Always smaller than home storage — that gap is the
    /// point of it.
    var satchelCapacity: Int {
        Tuning.Economy.startingSatchelSlots + satchelTier * Tuning.Economy.satchelSlotsPerTier
    }

    /// `Inventory.slots` is the stored capacity (the run satchel has its own), so it has to be
    /// re-synced whenever a Storehouse tier changes. One formula, one assignment — call this
    /// after any station upgrade rather than computing capacity in two places.
    mutating func syncInventoryCapacity() {
        inventory.slots = inventoryCapacity
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        essence = try container.decodeIfPresent(Int.self, forKey: .essence) ?? Tuning.Economy.startingEssence
        resources = try container.decodeIfPresent(ResourcePool.self, forKey: .resources) ?? ResourcePool()
        inventory = try container.decodeIfPresent(Inventory.self, forKey: .inventory)
            ?? Inventory(slots: Tuning.Economy.startingInventorySlots)
        ownedSymbols = try container.decodeIfPresent(Set<SymbolID>.self, forKey: .ownedSymbols) ?? []
        ownedGambitPieces = try container.decodeIfPresent([GambitPieceID].self, forKey: .ownedGambitPieces) ?? []
        stations = try container.decodeIfPresent([StationID: StationState].self, forKey: .stations) ?? [:]
        bookDraft = try container.decodeIfPresent(BookDraft.self, forKey: .bookDraft) ?? BookDraft()
        companion = try container.decodeIfPresent(CompanionState.self, forKey: .companion) ?? CompanionState()
        hasAutomateSelfUnlock = try container.decodeIfPresent(Bool.self, forKey: .hasAutomateSelfUnlock) ?? false
        satchelTier = try container.decodeIfPresent(Int.self, forKey: .satchelTier) ?? 0
    }
}

/// Well-known station IDs. Definitions live in `Content/Data/stations.json`.
enum Stations {
    static let writingDesk: StationID = "writing_desk"
    static let storehouse: StationID = "storehouse"
    static let workshop: StationID = "workshop"
    static let party: StationID = "party"
    static let essenceSpring: StationID = "essence_spring"
    static let constellation: StationID = "constellation"
}

struct StationState: Codable, Equatable, Sendable {
    var isUnlocked: Bool
    /// 0 = built but un-upgraded. Storehouse tiers 1–3 are the v0 example.
    var tier: Int
}

/// A book being composed. Empty slots are *not* an error — they are random-filled at generation
/// (the Mystcraft rule: under-specification is a surprise).
///
/// Keyed by `SlotID`, so the shape of a book comes from `slots.json`, not from this type.
struct BookDraft: Codable, Equatable, Sendable {
    var slots: [SlotID: SymbolID] = [:]

    subscript(slot: SlotID) -> SymbolID? {
        get { slots[slot] }
        set { slots[slot] = newValue }
    }

    var filledCount: Int { slots.count }
    func isEmpty(_ slot: SlotID) -> Bool { slots[slot] == nil }

    /// Drops anything the catalog no longer knows about.
    ///
    /// Matters because the slot taxonomy is being replaced (decisions-log, session 2): after that
    /// rewrite, a saved draft can reference slots or symbols that no longer exist. Silently
    /// ignoring them would leave the player with a book they can see but not explain.
    mutating func prune(using catalog: ContentCatalog = .shared) {
        let validSlots = Set(catalog.slots.map(\.id))
        slots = slots.filter { slot, symbol in
            validSlots.contains(slot) && catalog.symbol(symbol)?.slot == slot
        }
    }
}

/// The one companion in v0. Party expands in v1+, so this is a struct that can become an array
/// element without reshaping the save.
struct CompanionState: Codable, Equatable, Sendable {
    var name: String = "Quill" // PLACEHOLDER name
    /// Only the *maximum* lives here. Current HP is run-scoped (`WorldRun.companionHP`) because
    /// the brief says HP persists during a run and returning home fully heals — so a base-side
    /// current-HP field would be a second source of truth that is always full.
    var maxHP: Int = Tuning.Encounter.companionMaxHP
    /// Ordered gambit list — evaluated top-down, first match fires (FF12 execution model).
    var gambits: [GambitPieceID] = []
    var weaponTier: Int = 0
    var armorTier: Int = 0
}
