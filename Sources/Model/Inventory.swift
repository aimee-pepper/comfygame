import Foundation

/// Stackable resources (Ore, Fiber, Essence-raw, Motes). Do not consume inventory slots.
struct ResourcePool: Codable, Equatable, Sendable {
    private(set) var amounts: [ResourceID: Int] = [:]

    init(_ amounts: [ResourceID: Int] = [:]) {
        self.amounts = amounts.filter { $0.value != 0 }
    }

    subscript(id: ResourceID) -> Int { amounts[id] ?? 0 }

    var isEmpty: Bool { amounts.values.allSatisfy { $0 == 0 } }
    var totalUnits: Int { amounts.values.reduce(0, +) }
    var nonZero: [(id: ResourceID, amount: Int)] {
        amounts.filter { $0.value != 0 }
            .map { (id: $0.key, amount: $0.value) }
            .sorted { $0.id.rawValue < $1.id.rawValue }
    }

    mutating func add(_ amount: Int, of id: ResourceID) {
        let new = self[id] + amount
        if new == 0 { amounts[id] = nil } else { amounts[id] = new }
    }

    mutating func add(contentsOf other: ResourcePool) {
        for (id, amount) in other.amounts { add(amount, of: id) }
    }

    /// Removes `amount` if affordable. Returns false and changes nothing if not.
    @discardableResult
    mutating func spend(_ amount: Int, of id: ResourceID) -> Bool {
        guard amount >= 0, self[id] >= amount else { return false }
        add(-amount, of: id)
        return true
    }

    /// Keeps a fraction of every stack, rounding down — the collapse-banking rule
    /// (`Tuning.World.collapseHaulKeptFraction`). The *which items are lost* half of that rule
    /// is random selection over slot items; see `Inventory.randomlyKeeping`.
    func scaled(by fraction: Double) -> ResourcePool {
        ResourcePool(amounts.mapValues { Int((Double($0) * fraction).rounded(.down)) })
    }
}

/// Rarity ladder — colour-coded in the UI.
enum Rarity: String, Codable, CaseIterable, Sendable, Comparable {
    case common, uncommon, rare, mythic

    var order: Int { Rarity.allCases.firstIndex(of: self) ?? 0 }
    static func < (lhs: Rarity, rhs: Rarity) -> Bool { lhs.order < rhs.order }
}

/// One slot-consuming item instance. `catalogID` points at `Content/Data/items.json`.
///
/// Unidentified items are the delayed-payoff seed: a curio drops as `identified == false` with a
/// teaser name, and identifying it at the Storehouse swaps in its real catalog entry.
struct ItemStack: Codable, Equatable, Identifiable, Sendable {
    var id: InstanceID
    var catalogID: ItemID
    var count: Int = 1
    var identified: Bool = true

    init(id: InstanceID, catalogID: ItemID, count: Int = 1, identified: Bool = true) {
        self.id = id
        self.catalogID = catalogID
        self.count = count
        self.identified = identified
    }
}

/// Slot-limited item storage. Slot count grows with Storehouse tiers.
struct Inventory: Codable, Equatable, Sendable {
    var slots: Int
    var stacks: [ItemStack] = []

    init(slots: Int, stacks: [ItemStack] = []) {
        self.slots = slots
        self.stacks = stacks
    }

    var isFull: Bool { stacks.count >= slots }
    var freeSlots: Int { max(0, slots - stacks.count) }

    /// Returns false (and changes nothing) when full — callers must surface that to the player
    /// rather than silently dropping loot.
    @discardableResult
    mutating func add(_ stack: ItemStack) -> Bool {
        guard !isFull else { return false }
        stacks.append(stack)
        return true
    }

    mutating func remove(_ id: InstanceID) {
        stacks.removeAll { $0.id == id }
    }

    /// Random half-loss on collapse. Deterministic given the run's RNG, so a force-quit during
    /// the collapse animation resumes to the same outcome.
    func randomlyKeeping(fraction: Double, rng: inout SeededRNG) -> Inventory {
        let keepCount = Int((Double(stacks.count) * fraction).rounded(.down))
        var pool = stacks
        var kept: [ItemStack] = []
        while kept.count < keepCount, !pool.isEmpty {
            kept.append(pool.remove(at: rng.int(in: 0...(pool.count - 1))))
        }
        return Inventory(slots: slots, stacks: kept)
    }
}
