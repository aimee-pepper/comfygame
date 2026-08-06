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
/// One slot's worth of things: **a bin, not a single object.**
///
/// `count` existed from the start and **nothing ever incremented it** — every pickup made a new
/// stack in a new slot, so two identical hides ate two of your eight slots (session 16 §1).
///
/// **Ordinary items merge by catalogue id and identified state.** Two unidentified curios of the
/// same kind are one stack; identifying one separates it, which is right, because you now know
/// something about it that you don't know about the other.
///
/// **Materials merge by KIND, not by exact source.** Every hide goes in the hide bin whatever its
/// grade or whichever animal it came off. Keeping a *pale hide* from a groper apart from a *shaggy
/// hide* from a browser is truthful but unusable — a world with six species produces a dozen
/// variants and slot pressure explodes. Binning by kind makes slot pressure proportional to the
/// number of material *kinds*, which is a manageable number, and **loses nothing**: every sample
/// keeps its own grade, source and name inside the bin.
struct ItemStack: Codable, Equatable, Identifiable, Sendable {
    var id: InstanceID
    var catalogID: ItemID
    var count: Int = 1
    var identified: Bool = true
    /// **How far this piece has been reforged** at the Blacksmith. Gear only.
    ///
    /// Per instance, not per catalogue entry — the point of upgrading over replacing is that *this*
    /// blade, the one you've carried, grows with you (materials-crafting-spec §7). Which also means
    /// two otherwise identical blades at different levels are different objects and can't share a
    /// bin.
    var upgradeLevel: Int = 0
    /// Every material sample in this bin, in the order they were taken. Empty for ordinary items.
    ///
    /// The bin is the slot; these are what's in it. Crafting picks from among them, so a recipe can
    /// be satisfied cheaply or generously, and "the finest pelt you've recovered" stays a question
    /// with an answer.
    var materials: [MaterialSample] = []

    init(id: InstanceID, catalogID: ItemID, count: Int = 1, identified: Bool = true,
         material: MaterialSample? = nil) {
        self.id = id
        self.catalogID = catalogID
        self.identified = identified
        self.materials = material.map { Array(repeating: $0, count: max(1, count)) } ?? []
        self.count = materials.isEmpty ? count : materials.count
    }

    init(id: InstanceID, catalogID: ItemID, identified: Bool = true, materials: [MaterialSample]) {
        self.id = id
        self.catalogID = catalogID
        self.identified = identified
        self.materials = materials
        self.count = materials.count
    }

    /// Keys include the **retired singular `material`**, so a save written before binning still
    /// loads: it held one sample and a count, and becomes a bin holding that many of it.
    private enum StoredKeys: String, CodingKey {
        case id, catalogID, count, identified, materials, material, upgradeLevel
    }

    /// Tolerant decoding, per the policy in `Migrations.swift`.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: StoredKeys.self)
        id = try c.decode(InstanceID.self, forKey: .id)
        catalogID = try c.decode(ItemID.self, forKey: .catalogID)
        count = try c.decodeIfPresent(Int.self, forKey: .count) ?? 1
        identified = try c.decodeIfPresent(Bool.self, forKey: .identified) ?? true
        upgradeLevel = try c.decodeIfPresent(Int.self, forKey: .upgradeLevel) ?? 0
        if let many = try c.decodeIfPresent([MaterialSample].self, forKey: .materials) {
            materials = many
        } else if let one = try c.decodeIfPresent(MaterialSample.self, forKey: .material) {
            materials = Array(repeating: one, count: max(1, count))
        } else {
            materials = []
        }
        if !materials.isEmpty { count = materials.count }
    }

    /// The single sample a bin is *about*, for anything that just needs to know what kind it is.
    var material: MaterialSample? { materials.first }

    /// What two stacks must agree on to be the same bin.
    enum BinKey: Hashable, Sendable {
        case material(MaterialKind)
        case item(ItemID, identified: Bool, upgradeLevel: Int)
    }

    var binKey: BinKey {
        if let kind = materials.first?.kind { return .material(kind) }
        // Upgrade level is part of what a piece *is*: a blade you've reforged twice is not
        // interchangeable with one fresh off the ground.
        return .item(catalogID, identified: identified, upgradeLevel: upgradeLevel)
    }

    /// The best example in the bin — what makes "12 hides · finest superb" possible.
    var finest: MaterialSample? { materials.max { $0.grade < $1.grade } }

    /// Takes everything from another bin of the same kind.
    mutating func absorb(_ other: ItemStack) {
        materials.append(contentsOf: other.materials)
        count = materials.isEmpty ? count + other.count : materials.count
    }

    /// Splits `amount` off this bin, taking the **worst** samples first — what you'd hand over or
    /// lose is what you'd miss least.
    mutating func removing(_ amount: Int) -> ItemStack? {
        guard amount > 0 else { return nil }
        if materials.isEmpty {
            let taken = min(amount, count)
            count -= taken
            return ItemStack(id: id, catalogID: catalogID, count: taken, identified: identified)
        }
        let ordered = materials.sorted { $0.grade < $1.grade }
        let taken = Array(ordered.prefix(amount))
        let kept = Array(ordered.dropFirst(amount))
        materials = kept
        count = kept.count
        return taken.isEmpty ? nil : ItemStack(id: id, catalogID: catalogID,
                                               identified: identified, materials: taken)
    }

    var isEmpty: Bool { materials.isEmpty ? count <= 0 : materials.isEmpty }

    /// The stats this piece actually fights at: what it was found as, plus what you've put into it.
    var effectiveTier: Int {
        (ContentCatalog.shared.item(catalogID)?.gear?.tier ?? 0) + upgradeLevel
    }

    /// What to call it. **Materials name themselves** — there is no catalogue entry to ask, because
    /// what this is came off the animal it was cut from. Everything else asks the catalogue, and an
    /// unidentified curio gives its teaser name.
    ///
    /// A material bin is named for its **kind**, not for any one sample in it: a bin holding a
    /// crude hide and a superb one is a hide bin. Which ones are in it is what opening it is for.
    var displayName: String {
        if let kind = materials.first?.kind {
            return count > 1 ? kind.pluralName.capitalisedSentence : kind.displayName
        }
        guard let item = ContentCatalog.shared.item(catalogID) else { return catalogID.rawValue }
        let base = identified ? item.name : (item.unidentifiedName ?? "Something odd")
        return upgradeLevel > 0 ? "\(base) +\(upgradeLevel)" : base
    }

    var icon: String {
        if let kind = materials.first?.kind { return kind.icon }
        return identified ? (ContentCatalog.shared.item(catalogID)?.icon ?? "questionmark")
                          : "questionmark.diamond"
    }

    /// The right-hand column of a list row.
    ///
    /// **For a material bin this is the best thing in it**, because "12 hides" tells you how much
    /// room it takes and nothing about whether it's worth anything, and the grade is the reason to
    /// have gone anywhere. Session 16 §1 leaves this open; the more useful of the two is built and
    /// flagged in questions-for-design.
    var detail: String {
        let tally = count > 1 ? "×\(count)" : ""
        guard let finest else {
            guard let material else { return tally }
            let quality = material.properties.dominant
            guard quality.value > Tuning.Materials.notableProperty else { return tally }
            return tally.isEmpty ? quality.name : "\(quality.name)  \(tally)"
        }
        let best = finest.gradeWord.map { "finest \($0)" } ?? finest.properties.dominant.name
        return tally.isEmpty ? best : "\(best)  \(tally)"
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

    /// **Merges into an existing bin where there is one**, and only takes a slot otherwise.
    ///
    /// Returns false (and changes nothing) when there's no bin to join and no slot free — callers
    /// must surface that to the player rather than silently dropping loot.
    @discardableResult
    mutating func add(_ stack: ItemStack) -> Bool {
        if let index = stacks.firstIndex(where: { $0.binKey == stack.binKey }) {
            stacks[index].absorb(stack)
            return true
        }
        guard !isFull else { return false }
        stacks.append(stack)
        return true
    }

    mutating func remove(_ id: InstanceID) {
        stacks.removeAll { $0.id == id }
    }

    /// Random loss on collapse. Deterministic given the run's RNG, so a force-quit during the
    /// collapse animation resumes to the same outcome.
    ///
    /// Counted in **things, not bins**. Once materials bin by kind a single slot can hold a dozen
    /// hides, and dropping half your *slots* would have taken all twelve or none of them — the
    /// collapse rule is meant to cost you half of what you're carrying.
    func randomlyKeeping(fraction: Double, rng: inout SeededRNG) -> Inventory {
        var kept: [ItemStack] = []
        for stack in stacks {
            let keepCount = Int((Double(stack.count) * fraction).rounded(.down))
            guard keepCount > 0 else { continue }
            var remaining = stack
            // Take the losses off the bottom: what a collapse costs you is what you'd miss least.
            _ = remaining.removing(stack.count - keepCount)
            if !remaining.isEmpty { kept.append(remaining) }
        }
        return Inventory(slots: slots, stacks: kept)
    }
}

/// A piece actually on somebody.
///
/// Not just a catalogue id: **upgrade level is per instance** (materials-crafting-spec §7), and the
/// whole point of reforging over replacing is that the blade you've carried is the one that grows.
/// Storing only the id would have quietly reset every piece the moment it was equipped.
struct EquippedPiece: Codable, Equatable, Sendable, ExpressibleByStringLiteral {
    var catalogID: ItemID
    var upgradeLevel: Int = 0

    private enum StoredKeys: String, CodingKey { case catalogID, upgradeLevel }

    init(stringLiteral value: String) {
        self.catalogID = ItemID(rawValue: value)
        self.upgradeLevel = 0
    }

    init(catalogID: ItemID, upgradeLevel: Int = 0) {
        self.catalogID = catalogID
        self.upgradeLevel = upgradeLevel
    }

    init(_ stack: ItemStack) {
        self.catalogID = stack.catalogID
        self.upgradeLevel = stack.upgradeLevel
    }

    /// **Writes itself as a bare id when there's nothing else to say.**
    ///
    /// An untouched piece is exactly what it always was, and a save reading `"weapon": "blade_keen"`
    /// stays hand-editable and legible — which is worth keeping. Only a reforged piece needs the
    /// object form, and only then does it stop being readable by an older build.
    func encode(to encoder: Encoder) throws {
        guard upgradeLevel != 0 else {
            var single = encoder.singleValueContainer()
            try single.encode(catalogID)
            return
        }
        var c = encoder.container(keyedBy: StoredKeys.self)
        try c.encode(catalogID, forKey: .catalogID)
        try c.encode(upgradeLevel, forKey: .upgradeLevel)
    }

    /// Accepts the **bare item id** this used to be, so a save from before pieces could be
    /// upgraded still arrives wearing what it was wearing.
    init(from decoder: Decoder) throws {
        if let id = try? decoder.singleValueContainer().decode(ItemID.self) {
            catalogID = id
            upgradeLevel = 0
            return
        }
        let c = try decoder.container(keyedBy: StoredKeys.self)
        catalogID = try c.decode(ItemID.self, forKey: .catalogID)
        upgradeLevel = try c.decodeIfPresent(Int.self, forKey: .upgradeLevel) ?? 0
    }

    var definition: ItemDef? { ContentCatalog.shared.item(catalogID) }
    var gear: GearDef? { definition?.gear }
    /// What it actually fights at: found tier plus what you've put into it.
    var effectiveTier: Int { (gear?.tier ?? 0) + upgradeLevel }
    var displayName: String {
        let base = definition?.name ?? catalogID.rawValue
        return upgradeLevel > 0 ? "\(base) +\(upgradeLevel)" : base
    }

    /// Back into a carryable stack, keeping the work you put into it.
    func asStack(id: InstanceID) -> ItemStack {
        var stack = ItemStack(id: id, catalogID: catalogID)
        stack.upgradeLevel = upgradeLevel
        return stack
    }
}
