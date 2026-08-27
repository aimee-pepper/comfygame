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

    /// Decision 207: one outcome-wide budget, apportioned without rewarding resource variety.
    func retainedForFailure(fraction: Double, outcomeID: ExpeditionOutcomeID) -> ResourcePool {
        let fraction = min(1, max(0, fraction))
        guard fraction > 0, totalUnits > 0 else { return ResourcePool() }
        let budget = min(totalUnits, Int(ceil(Double(totalUnits) * fraction)))
        struct Share {
            let id: ResourceID
            let amount: Int
            let base: Int
            let remainder: Double
            let tie: UInt64
        }
        let shares = nonZero.map { entry -> Share in
            let exact = Double(entry.amount) * fraction
            return Share(id: entry.id, amount: entry.amount, base: Int(floor(exact)),
                         remainder: exact - floor(exact),
                         tie: failureStableHash("\(outcomeID.rawValue):resource:\(entry.id.rawValue)"))
        }
        var result = ResourcePool(Dictionary(uniqueKeysWithValues: shares.map { ($0.id, $0.base) }))
        var remaining = budget - shares.reduce(0) { $0 + $1.base }
        for share in shares.sorted(by: {
            if $0.remainder != $1.remainder { return $0.remainder > $1.remainder }
            if $0.tie != $1.tie { return $0.tie < $1.tie }
            return $0.id.rawValue < $1.id.rawValue
        }) where remaining > 0 && result[share.id] < share.amount {
            result.add(1, of: share.id)
            remaining -= 1
        }
        return result
    }
}

private func failureStableHash(_ text: String) -> UInt64 {
    var hash: UInt64 = 0xcbf29ce484222325
    for byte in text.utf8 {
        hash ^= UInt64(byte)
        hash = hash &* 0x100000001b3
    }
    return hash
}

/// Rarity ladder — colour-coded in the UI.
enum Rarity: String, Codable, CaseIterable, Sendable, Comparable {
    case common, uncommon, rare, mythic

    var order: Int { Rarity.allCases.firstIndex(of: self) ?? 0 }
    static func < (lhs: Rarity, rhs: Rarity) -> Bool { lhs.order < rhs.order }
}

/// Frozen identity and construction facts shared by stored and equipped physical gear.
///
/// Catalogue definitions remain a fallback for old/found pieces, but once this profile exists the
/// instance no longer changes shape because content data or station rules changed later.
struct GearInstanceProfile: Codable, Equatable, Sendable {
    var version: Int = 2
    var stableInstanceID: InstanceID
    var familyID: String?
    var constructionTier: Int
    var reforgeRank: Int = 0
    var legacyPowerCredit: Int = 0
    var qualityBand: CraftMaterialQualityBand = .standard
    var legacyEffectivePowerCredit: Int = 0
    var slot: GearSlot
    var damage: DamageKind?
    var reach: Reach
    var insulation: Double
    var reactivity: Double
    var consumedSamples: [CraftMaterialUnitV1] = []
    var recipeVersion: Int?
    var specialistProfile: String?
    var displayProvenance: String?
    var authoredUniqueRuleID: String?
    var foundReceipt: FoundGearReceiptV1?

    init(stableInstanceID: InstanceID, definition: ItemDef, legacyUpgradeLevel: Int = 0) {
        let gear = definition.gear!
        let legacySmithPower = gear.tier + max(0, legacyUpgradeLevel)
        self.stableInstanceID = stableInstanceID
        self.constructionTier = min(4, max(1, legacySmithPower))
        self.legacyPowerCredit = max(0, legacySmithPower - 4)
        self.qualityBand = CraftMaterialQualityBand(rawValue: self.constructionTier) ?? .standard
        self.legacyEffectivePowerCredit = self.legacyPowerCredit
        self.slot = gear.slot
        self.damage = gear.damage
        self.reach = gear.reach
        self.insulation = gear.insulation
        self.reactivity = gear.reactivity
        self.authoredUniqueRuleID = gear.breaks?.rawValue
        if let receipt = definition.gearCatalogueDisposition?.foundReceipt {
            self.qualityBand = receipt.qualityBand
            self.constructionTier = receipt.qualityBand.rawValue
            self.foundReceipt = receipt
        }
    }

    var effectivePower: Double {
        Double(qualityBand.rawValue + legacyEffectivePowerCredit)
            + Double(reforgeRank) * Tuning.Smith.powerPerReforgeRank
    }

    var hasImmutableConstructionReceipt: Bool {
        recipeVersion != nil && !consumedSamples.isEmpty
    }

    var legacyLabel: String? {
        legacyPowerCredit > 0 ? "Legacy masterwork +\(legacyPowerCredit)" : nil
    }

    var protectivePower: Double {
        let offset: Double = switch specialistProfile {
        case "armoury_balanced_laminate_v1": -0.5
        case "armoury_insulated_layer_v1": -1.0
        default: 0
        }
        return max(0, effectivePower + offset)
    }
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
    /// Player-authored sale safeguards. Missing fields on old saves are deliberately false.
    var isFavorite: Bool = false
    var isLocked: Bool = false
    /// **How far this piece has been reforged** at the Blacksmith. Gear only.
    ///
    /// Per instance, not per catalogue entry — the point of upgrading over replacing is that *this*
    /// blade, the one you've carried, grows with you (materials-crafting-spec §7). Which also means
    /// two otherwise identical blades at different levels are different objects and can't share a
    /// bin.
    var upgradeLevel: Int = 0
    /// Encounters won while carrying a Living Hook. Separate from smithing work and capped at 2.
    var wildGrowth: Int = 0
    /// New physical-gear schema. Nil only for non-gear and transitional in-memory fixtures.
    var gearProfile: GearInstanceProfile? = nil
    /// Every material sample in this bin, in the order they were taken. Empty for ordinary items.
    ///
    /// The bin is the slot; these are what's in it. Crafting picks from among them, so a recipe can
    /// be satisfied cheaply or generously, and "the finest pelt you've recovered" stays a question
    /// with an answer.
    var materials: [CraftMaterialUnitV1] = []
    /// Quantity in this bin that crossed the expedition threshold from Home and must return unless
    /// actually consumed. New pickups merging into the bin do not increase it.
    var protectedReturnCount: Int = 0
    /// Distillery-made identity. Nil for found and ordinary crafted items; present on blank and
    /// attuned cores so saves retain what was consumed and unlike cores never merge.
    var distilledCore: DistilledCore?

    init(id: InstanceID, catalogID: ItemID, count: Int = 1, identified: Bool = true,
         material: CraftMaterialUnitV1? = nil, distilledCore: DistilledCore? = nil) {
        self.id = id
        self.catalogID = catalogID
        self.identified = identified
        self.materials = material.map { Array(repeating: $0, count: max(1, count)) } ?? []
        self.distilledCore = distilledCore
        self.count = materials.isEmpty ? count : materials.count
        if let definition = ContentCatalog.shared.item(catalogID), definition.gear != nil {
            self.gearProfile = GearInstanceProfile(stableInstanceID: id, definition: definition)
        }
    }

    init(id: InstanceID, catalogID: ItemID, identified: Bool = true, materials: [CraftMaterialUnitV1]) {
        self.id = id
        self.catalogID = catalogID
        self.identified = identified
        self.materials = materials
        self.count = materials.count
    }

    /// Keys include the **retired singular `material`**, so a save written before binning still
    /// loads: it held one sample and a count, and becomes a bin holding that many of it.
    private enum StoredKeys: String, CodingKey {
        case id, catalogID, count, identified, materials, material, upgradeLevel, wildGrowth
        case distilledCore, protectedReturnCount, gearProfile, isFavorite, isLocked
    }

    /// Tolerant decoding, per the policy in `Migrations.swift`.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: StoredKeys.self)
        id = try c.decode(InstanceID.self, forKey: .id)
        catalogID = try c.decode(ItemID.self, forKey: .catalogID)
        count = try c.decodeIfPresent(Int.self, forKey: .count) ?? 1
        identified = try c.decodeIfPresent(Bool.self, forKey: .identified) ?? true
        isFavorite = try c.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        isLocked = try c.decodeIfPresent(Bool.self, forKey: .isLocked) ?? false
        upgradeLevel = try c.decodeIfPresent(Int.self, forKey: .upgradeLevel) ?? 0
        wildGrowth = try c.decodeIfPresent(Int.self, forKey: .wildGrowth) ?? 0
        gearProfile = try c.decodeIfPresent(GearInstanceProfile.self, forKey: .gearProfile)
        distilledCore = try c.decodeIfPresent(DistilledCore.self, forKey: .distilledCore)
        protectedReturnCount = min(count, max(0, try c.decodeIfPresent(Int.self,
                                                    forKey: .protectedReturnCount) ?? 0))
        if let many = try c.decodeIfPresent([CraftMaterialUnitV1].self, forKey: .materials) {
            materials = many
        } else if let one = try c.decodeIfPresent(CraftMaterialUnitV1.self, forKey: .material) {
            materials = Array(repeating: one, count: max(1, count))
        } else {
            materials = []
        }
        if !materials.isEmpty { count = materials.count }
        if let definition = ContentCatalog.shared.item(catalogID), let gear = definition.gear {
            guard let profile = gearProfile, profile.version == 2,
                  profile.stableInstanceID == id, profile.slot == gear.slot,
                  profile.authoredUniqueRuleID == gear.breaks?.rawValue,
                  profile.foundReceipt == (profile.hasImmutableConstructionReceipt
                    ? nil : definition.gearCatalogueDisposition?.foundReceipt),
                  profile.legacyEffectivePowerCredit >= 0,
                  (0...3).contains(profile.reforgeRank) else {
                throw CocoaError(.coderInvalidValue)
            }
        } else if gearProfile != nil {
            throw CocoaError(.coderInvalidValue)
        }
    }

    /// The single sample a bin is *about*, for anything that just needs to know what kind it is.
    var material: CraftMaterialUnitV1? { materials.first }

    /// What two stacks must agree on to be the same bin.
    enum BinKey: Hashable, Sendable {
        case material(MaterialFamilyID)
        case distilledCore(ItemID, DistilledCore)
        case distilledFixture(InstanceID)
        case item(ItemID, identified: Bool, upgradeLevel: Int, wildGrowth: Int,
                  isFavorite: Bool, isLocked: Bool)
        case gear(InstanceID)
    }

    var binKey: BinKey {
        if let kind = materials.first?.kind { return .material(kind) }
        if catalogID == Items.conduitFixture, distilledCore != nil {
            return .distilledFixture(id)
        }
        if let distilledCore { return .distilledCore(catalogID, distilledCore) }
        if let gearProfile { return .gear(gearProfile.stableInstanceID) }
        // Upgrade level is part of what a piece *is*: a blade you've reforged twice is not
        // interchangeable with one fresh off the ground.
        return .item(catalogID, identified: identified, upgradeLevel: upgradeLevel,
                     wildGrowth: wildGrowth, isFavorite: isFavorite, isLocked: isLocked)
    }

    var finest: CraftMaterialUnitV1? { materials.max { $0.qualityBand.rawValue < $1.qualityBand.rawValue } }

    /// Takes everything from another bin of the same kind.
    mutating func absorb(_ other: ItemStack) {
        materials.append(contentsOf: other.materials)
        count = materials.isEmpty ? count + other.count : materials.count
        protectedReturnCount = min(count, protectedReturnCount + other.protectedReturnCount)
    }

    /// Splits `amount` off this bin, taking the **worst** samples first — what you'd hand over or
    /// lose is what you'd miss least.
    mutating func removing(_ amount: Int) -> ItemStack? {
        guard amount > 0 else { return nil }
        if materials.isEmpty {
            let taken = min(amount, count)
            let protectedTaken = min(taken, protectedReturnCount)
            count -= taken
            protectedReturnCount -= protectedTaken
            var result = ItemStack(id: id, catalogID: catalogID, count: taken, identified: identified,
                                   distilledCore: distilledCore)
            result.upgradeLevel = upgradeLevel
            result.wildGrowth = wildGrowth
            result.gearProfile = gearProfile
            result.protectedReturnCount = protectedTaken
            result.isFavorite = isFavorite
            result.isLocked = isLocked
            return result
        }
        let ordered = materials.sorted { $0.stableUnitID < $1.stableUnitID }
        let taken = Array(ordered.prefix(amount))
        let kept = Array(ordered.dropFirst(amount))
        materials = kept
        count = kept.count
        return taken.isEmpty ? nil : ItemStack(id: id, catalogID: catalogID,
                                               identified: identified, materials: taken)
    }

    var isEmpty: Bool { materials.isEmpty ? count <= 0 : materials.isEmpty }

    /// Separates supplies guaranteed home from haul exposed to partial-retention RNG.
    func partitionedForReturn() -> (protected: ItemStack?, atRisk: ItemStack?) {
        let safeCount = min(count, max(0, protectedReturnCount))
        var safe: ItemStack?
        var risk: ItemStack?
        if safeCount > 0 {
            var copy = self
            if !copy.materials.isEmpty {
                copy.materials = Array(copy.materials.prefix(safeCount))
            }
            copy.count = safeCount
            copy.protectedReturnCount = 0
            safe = copy
        }
        let riskCount = count - safeCount
        if riskCount > 0 {
            var copy = self
            copy.count = riskCount
            copy.protectedReturnCount = 0
            if !copy.materials.isEmpty { copy.materials = Array(copy.materials.suffix(riskCount)) }
            risk = copy
        }
        return (safe, risk)
    }

    /// The stats this piece actually fights at: what it was found as, plus what you've put into it.
    var constructionTier: Int {
        gearProfile?.constructionTier ?? (ContentCatalog.shared.item(catalogID)?.gear?.tier ?? 0)
    }

    var effectivePower: Double {
        (gearProfile?.effectivePower
         ?? Double((ContentCatalog.shared.item(catalogID)?.gear?.tier ?? 0) + upgradeLevel))
            + Double(wildGrowth)
    }

    /// Compatibility display boundary for older callers. Combat uses `effectivePower` directly.
    var effectiveTier: Int {
        Int(effectivePower.rounded())
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
        let catalogBase = identified ? item.name : (item.unidentifiedName ?? "Something odd")
        let base = gearProfile?.displayProvenance ?? catalogBase
        if let profile = gearProfile {
            let suffix = profile.reforgeRank > 0
                ? " · Reforged \(profile.reforgeRank)/\(Tuning.Smith.maximumReforgeRank)" : ""
            return "\(base) · \(GearPresentationCopy.quality(profile))\(suffix)"
        }
        let bonus = upgradeLevel + wildGrowth
        return bonus > 0 ? "\(base) +\(bonus)" : base
    }

    var icon: String {
        if let kind = materials.first?.kind { return kind.icon }
        return identified ? (ContentCatalog.shared.item(catalogID)?.icon ?? "questionmark")
                          : "questionmark.diamond"
    }

    /// The right-hand column of a list row.
    ///
    /// **For a material bin this is the best thing in it**, because "12 hides" tells you how much
    /// room it takes and nothing about whether it's worth anything, and quality is the reason to
    /// have gone anywhere. Session 16 §1 leaves this open; the more useful of the two is built and
    /// flagged in questions-for-design.
    var detail: String {
        let tally = count > 1 ? "×\(count)" : ""
        if let core = distilledCore {
            let identity = core.attunement == nil ? "blank · Distillery" : "\(core.potencyBand) · \(core.sampleSource ?? "world sample")"
            return tally.isEmpty ? identity : "\(identity)  \(tally)"
        }
        guard let finest else {
            guard let material else { return tally }
            let quality = material.properties.dominant
            guard quality.value > Tuning.Materials.notableProperty else { return tally }
            return tally.isEmpty ? quality.name : "\(quality.name)  \(tally)"
        }
        let best = finest.qualityBand.displayName
        return tally.isEmpty ? best : "\(best)  \(tally)"
    }
}

enum CoreAttunement: String, Codable, CaseIterable, Hashable, Sendable {
    case heat, caustic, light
    var displayName: String { rawValue.capitalisedSentence }
}

/// Immutable receipt for a Distillery output. Values used for stacking are deliberately display
/// provenance, not an instance pointer: equivalent work may share a bin and remains legible.
struct DistilledCore: Codable, Equatable, Hashable, Sendable {
    var attunement: CoreAttunement?
    var potency: Int
    var sampleKind: String? = nil
    var sampleSource: String? = nil
    var sampleQualifier: String? = nil
    var catalystID: ResourceID? = nil
    var catalystCount: Int = 0
    var recipeVersion: Int = 1
    var stationID: StationID = "distillery"

    var potencyBand: String {
        switch potency { case ..<40: "faint"; case 40..<65: "clear"; case 65..<85: "strong"; default: "brilliant" }
    }
}

enum ChannelworksRestorationEntitlementID: String, Codable, Sendable {
    case odaDamagedHeatConduitV1 = "oda-damaged-heat-conduit-v1"
}

struct ChannelworksRestorationReceiptV1: Codable, Equatable, Sendable {
    static let version = 1
    var version: Int = Self.version
    var entitlementID: ChannelworksRestorationEntitlementID = .odaDamagedHeatConduitV1
    var restorerID: TravellerID = "oda"
    var stationID: StationID = Stations.channelworks
    var fixtureCatalogueID: ItemID = Items.conduitFixture
    var fixtureInstanceID: InstanceID?
    var fixtureCore: DistilledCore = ChannelworksRestorationRules.authoredCore

    private enum CodingKeys: String, CodingKey, CaseIterable {
        case version, entitlementID, restorerID, stationID, fixtureCatalogueID
        case fixtureInstanceID, fixtureCore
    }

    init(fixtureInstanceID: InstanceID?) { self.fixtureInstanceID = fixtureInstanceID }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        guard Set(c.allKeys) == Set(CodingKeys.allCases) else { throw CocoaError(.coderInvalidValue) }
        version = try c.decode(Int.self, forKey: .version)
        entitlementID = try c.decode(ChannelworksRestorationEntitlementID.self,
                                     forKey: .entitlementID)
        restorerID = try c.decode(TravellerID.self, forKey: .restorerID)
        stationID = try c.decode(StationID.self, forKey: .stationID)
        fixtureCatalogueID = try c.decode(ItemID.self, forKey: .fixtureCatalogueID)
        fixtureInstanceID = try c.decodeIfPresent(InstanceID.self, forKey: .fixtureInstanceID)
        fixtureCore = try c.decode(DistilledCore.self, forKey: .fixtureCore)
        guard validates() else { throw CocoaError(.coderInvalidValue) }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(version, forKey: .version)
        try c.encode(entitlementID, forKey: .entitlementID)
        try c.encode(restorerID, forKey: .restorerID)
        try c.encode(stationID, forKey: .stationID)
        try c.encode(fixtureCatalogueID, forKey: .fixtureCatalogueID)
        if let fixtureInstanceID { try c.encode(fixtureInstanceID, forKey: .fixtureInstanceID) }
        else { try c.encodeNil(forKey: .fixtureInstanceID) }
        try c.encode(fixtureCore, forKey: .fixtureCore)
    }

    func validates() -> Bool {
        version == Self.version
            && entitlementID == .odaDamagedHeatConduitV1
            && restorerID == "oda" && stationID == Stations.channelworks
            && fixtureCatalogueID == Items.conduitFixture
            && (fixtureInstanceID?.rawValue ?? 1) > 0
            && fixtureCore == ChannelworksRestorationRules.authoredCore
    }
}

/// Slot-limited item storage. Slot count grows with Storehouse tiers.
struct Inventory: Codable, Equatable, Sendable {
    struct FailurePartition: Equatable, Sendable {
        var kept: Inventory
        var lost: Inventory
        var keptAdditionalUnitKeys: Set<String> = []
    }
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

    /// Decision 207: select from one exposed-unit pool, never one budget per stack.
    func partitionedForFailure(fraction: Double,
                               outcomeID: ExpeditionOutcomeID,
                               additionalUnitKeys: [String] = []) -> FailurePartition {
        let fraction = min(1, max(0, fraction))
        let uniqueAdditionalKeys = Set(additionalUnitKeys)
        let total = stacks.reduce(0) { $0 + max(0, $1.count) } + uniqueAdditionalKeys.count
        let budget = fraction > 0 ? min(total, Int(ceil(Double(total) * fraction))) : 0
        struct Unit {
            let stack: ItemStack?
            let additionalKey: String?
            let tie: UInt64
            let fallback: String
        }
        var units: [Unit] = []
        let canonicalSamples = stacks.flatMap { stack in
            stack.materials.map {
                (sample: $0, content: failureCanonicalMaterial($0), stack: stack)
            }
        }.sorted { $0.content < $1.content }
        var duplicateOrdinals: [String: Int] = [:]
        for entry in canonicalSamples {
            let ordinal = duplicateOrdinals[entry.content, default: 0]
            duplicateOrdinals[entry.content] = ordinal + 1
            let unit = ItemStack(id: entry.stack.id, catalogID: entry.stack.catalogID,
                                 identified: entry.stack.identified, materials: [entry.sample])
            let key = "\(outcomeID.rawValue):material:\(entry.content):duplicate:\(ordinal)"
            units.append(.init(stack: unit, additionalKey: nil,
                               tie: failureStableHash(key), fallback: key))
        }
        for stack in stacks where stack.materials.isEmpty {
                for index in 0..<max(0, stack.count) {
                    var unit = ItemStack(id: stack.id, catalogID: stack.catalogID,
                                         count: 1, identified: stack.identified,
                                         distilledCore: stack.distilledCore)
                    unit.upgradeLevel = stack.upgradeLevel
                    unit.wildGrowth = stack.wildGrowth
                    unit.gearProfile = stack.gearProfile
                    unit.isFavorite = stack.isFavorite
                    unit.isLocked = stack.isLocked
                    let key = "\(outcomeID.rawValue):item:\(stack.catalogID.rawValue):\(stack.id.rawValue):unit:\(index)"
                    units.append(.init(stack: unit, additionalKey: nil,
                                       tie: failureStableHash(key), fallback: key))
                }
        }
        for additionalKey in uniqueAdditionalKeys.sorted() {
            let key = "\(outcomeID.rawValue):additional:\(additionalKey)"
            units.append(.init(stack: nil, additionalKey: additionalKey,
                               tie: failureStableHash(key), fallback: key))
        }
        let ordered = units.sorted {
            if $0.tie != $1.tie { return $0.tie < $1.tie }
            return $0.fallback < $1.fallback
        }
        var kept = Inventory(slots: slots)
        var lost = Inventory(slots: slots)
        var keptAdditional: Set<String> = []
        for (index, unit) in ordered.enumerated() {
            if let stack = unit.stack {
                _ = index < budget ? kept.add(stack) : lost.add(stack)
            } else if index < budget, let key = unit.additionalKey {
                keptAdditional.insert(key)
            }
        }
        return .init(kept: kept, lost: lost,
                     keptAdditionalUnitKeys: keptAdditional)
    }
}

private func failureCanonicalMaterial(_ sample: CraftMaterialUnitV1) -> String {
    let properties = sample.properties
    let qualifier = sample.qualifier ?? ""
    return [
        sample.kind.rawValue,
        String(properties.hardness.bitPattern, radix: 16),
        String(properties.density.bitPattern, radix: 16),
        String(properties.insulation.bitPattern, radix: 16),
        String(properties.flexibility.bitPattern, radix: 16),
        String(properties.lustre.bitPattern, radix: 16),
        String(properties.reactivity.bitPattern, radix: 16),
        String(sample.qualityBand.rawValue),
        "\(sample.source.utf8.count):\(sample.source)",
        "\(qualifier.utf8.count):\(qualifier)"
    ].joined(separator: "|")
}

/// A piece actually on somebody.
///
/// Not just a catalogue id: **upgrade level is per instance** (materials-crafting-spec §7), and the
/// whole point of reforging over replacing is that the blade you've carried is the one that grows.
/// Storing only the id would have quietly reset every piece the moment it was equipped.
struct EquippedPiece: Codable, Equatable, Sendable, ExpressibleByStringLiteral {
    var catalogID: ItemID
    var upgradeLevel: Int = 0
    var wildGrowth: Int = 0
    var gearProfile: GearInstanceProfile?
    var isFavorite: Bool = false
    var isLocked: Bool = false

    private enum StoredKeys: String, CodingKey {
        case catalogID, upgradeLevel, wildGrowth, gearProfile, isFavorite, isLocked
    }

    init(stringLiteral value: String) {
        self.catalogID = ItemID(rawValue: value)
        self.upgradeLevel = 0
        self.wildGrowth = 0
        self.gearProfile = nil
        self.isFavorite = false
        self.isLocked = false
    }

    init(catalogID: ItemID, upgradeLevel: Int = 0, wildGrowth: Int = 0) {
        self.catalogID = catalogID
        self.upgradeLevel = upgradeLevel
        self.wildGrowth = wildGrowth
        self.gearProfile = nil
        self.isFavorite = false
        self.isLocked = false
    }

    init(_ stack: ItemStack) {
        self.catalogID = stack.catalogID
        self.upgradeLevel = stack.upgradeLevel
        self.wildGrowth = stack.wildGrowth
        self.gearProfile = stack.gearProfile
        self.isFavorite = stack.isFavorite
        self.isLocked = stack.isLocked
    }

    /// **Writes itself as a bare id when there's nothing else to say.**
    ///
    /// An untouched piece is exactly what it always was, and a save reading `"weapon": "blade_keen"`
    /// stays hand-editable and legible — which is worth keeping. Only a reforged piece needs the
    /// object form, and only then does it stop being readable by an older build.
    func encode(to encoder: Encoder) throws {
        guard upgradeLevel != 0 || wildGrowth != 0 || gearProfile != nil || isFavorite || isLocked else {
            var single = encoder.singleValueContainer()
            try single.encode(catalogID)
            return
        }
        var c = encoder.container(keyedBy: StoredKeys.self)
        try c.encode(catalogID, forKey: .catalogID)
        try c.encode(upgradeLevel, forKey: .upgradeLevel)
        try c.encode(wildGrowth, forKey: .wildGrowth)
        try c.encodeIfPresent(gearProfile, forKey: .gearProfile)
        try c.encode(isFavorite, forKey: .isFavorite)
        try c.encode(isLocked, forKey: .isLocked)
    }

    /// Accepts the **bare item id** this used to be, so a save from before pieces could be
    /// upgraded still arrives wearing what it was wearing.
    init(from decoder: Decoder) throws {
        if let id = try? decoder.singleValueContainer().decode(ItemID.self) {
            catalogID = id
            upgradeLevel = 0
            wildGrowth = 0
            gearProfile = nil
            isFavorite = false
            isLocked = false
            return
        }
        let c = try decoder.container(keyedBy: StoredKeys.self)
        catalogID = try c.decode(ItemID.self, forKey: .catalogID)
        upgradeLevel = try c.decodeIfPresent(Int.self, forKey: .upgradeLevel) ?? 0
        wildGrowth = try c.decodeIfPresent(Int.self, forKey: .wildGrowth) ?? 0
        gearProfile = try c.decodeIfPresent(GearInstanceProfile.self, forKey: .gearProfile)
        isFavorite = try c.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        isLocked = try c.decodeIfPresent(Bool.self, forKey: .isLocked) ?? false
        if gearProfile == nil, let definition = ContentCatalog.shared.item(catalogID), definition.gear != nil {
            // BaseState assigns a collision-free stable id after every equipped slot is decoded.
            gearProfile = GearInstanceProfile(stableInstanceID: InstanceID(rawValue: 0),
                                              definition: definition,
                                              legacyUpgradeLevel: upgradeLevel)
        }
    }

    var definition: ItemDef? { ContentCatalog.shared.item(catalogID) }
    var gear: GearDef? { definition?.gear }
    /// What it actually fights at: found tier plus what you've put into it.
    var constructionTier: Int { gearProfile?.constructionTier ?? (gear?.tier ?? 0) }
    var effectivePower: Double {
        (gearProfile?.effectivePower ?? Double((gear?.tier ?? 0) + upgradeLevel)) + Double(wildGrowth)
    }
    var effectiveTier: Int { Int(effectivePower.rounded()) }
    var frozenSlot: GearSlot? { gearProfile?.slot ?? gear?.slot }
    var frozenDamage: DamageKind? { gearProfile?.damage ?? gear?.damage }
    var frozenReach: Reach { gearProfile?.reach ?? gear?.reach ?? .close }
    var frozenInsulation: Double { gearProfile?.insulation ?? gear?.insulation ?? 0 }
    var frozenReactivity: Double { gearProfile?.reactivity ?? gear?.reactivity ?? 0 }
    var displayName: String {
        let base = gearProfile?.displayProvenance ?? definition?.name ?? catalogID.rawValue
        if let profile = gearProfile {
            let suffix = profile.reforgeRank > 0
                ? " · Reforged \(profile.reforgeRank)/\(Tuning.Smith.maximumReforgeRank)" : ""
            return "\(base) · \(GearPresentationCopy.quality(profile))\(suffix)"
        }
        let bonus = upgradeLevel + wildGrowth
        return bonus > 0 ? "\(base) +\(bonus)" : base
    }

    /// Back into a carryable stack, keeping the work you put into it.
    func asStack(id: InstanceID) -> ItemStack {
        let stableID = gearProfile?.stableInstanceID.rawValue == 0
            ? id : (gearProfile?.stableInstanceID ?? id)
        var stack = ItemStack(id: stableID, catalogID: catalogID)
        stack.upgradeLevel = upgradeLevel
        stack.wildGrowth = wildGrowth
        if let gearProfile {
            var kept = gearProfile
            if kept.stableInstanceID.rawValue == 0 { kept.stableInstanceID = stableID }
            stack.gearProfile = kept
        }
        stack.isFavorite = isFavorite
        stack.isLocked = isLocked
        return stack
    }
}
