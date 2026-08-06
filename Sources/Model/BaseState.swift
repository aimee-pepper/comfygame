import Foundation

/// Layer 2 — Home Base. Persists between runs; a future reset wipes this and keeps `RealityState`.
struct BaseState: Codable, Equatable, Sendable {
    /// Refined common currency: binds books, identifies items, buys upgrades.
    var essence: Int = Tuning.Economy.startingEssence
    /// Raw stockpiles hauled home (Ore, Fiber, Essence-raw…). Motes live in Reality.
    var resources: ResourcePool = ResourcePool()
    var inventory: Inventory = Inventory(slots: Tuning.Economy.startingInventorySlots)
    /// Loot that came home to a full Storehouse.
    ///
    /// **Banking never discards** (Q10, session-5 audit). Anything that doesn't fit waits here
    /// until the player sorts it, at home, with full information — which is the right place for
    /// that decision, unlike the satchel one, which belongs in the world. Auto-converting to
    /// essence would quietly price a rare drop at scrap value, so it doesn't.
    var spillover: [ItemStack] = []

    /// Owned catalog entries. Definitions are data; the save stores only which ones are owned.
    var ownedSymbols: Set<SymbolID> = []

    /// The parts you can build rules out of. Learned from the research tree, or found in the wild.
    var ownedGambitComponents: Set<GambitComponentID> = []

    /// Research nodes completed. The tree's state, and the only place it's recorded.
    var completedResearch: Set<ResearchNodeID> = []

    /// Per-station progression, keyed by the data-driven station catalog. The Base screen renders
    /// `ContentCatalog.stations` filtered by `isUnlocked`, so adding a v1+ building (blacksmith,
    /// tavern, distillery) is a JSON edit, not a new hardcoded button.
    var stations: [StationID: StationState] = [:]

    /// The book currently being composed at the Writing Desk. Survives a force-quit mid-compose.
    var bookDraft: BookDraft = BookDraft()
    /// The page being written. **This is the composition surface** — the slot draft above is the
    /// old taxonomy, kept only so a save written before the page existed still loads.
    ///
    /// The page is a **fixed** grid — it never grows. Progression is learning to write smaller on
    /// it, through finer hands and learned compounds. Essence remains the per-bind consumable.
    var page: Page = Page()
    /// Which hands the player owns. Everyone starts with charcoal, and better instruments let you
    /// say the same things in less space — never new things.
    var ownedHands: Set<Hand> = [.crude]

    /// Lifts the one-primary-per-target restriction across every target at once.
    ///
    /// A single unlock for now (session 11 §3); per-target chaining runes stay possible later if
    /// one blunt switch proves too coarse.
    var hasChainingUnlock: Bool = false

    /// The finest hand available. Marks are written in it by default.
    var bestHand: Hand { ownedHands.max() ?? .crude }

    /// The companion's gambit list. Edited on the Party screen, out of combat only.
    var companion: CompanionState = CompanionState()

    /// **What the Binder is wearing** (Aimee, 5 Aug).
    ///
    /// Its own slots, separate from Quill's. The Binder is half the party and the brief says power
    /// comes from gear — an attack that was a `Tuning` constant while the companion had a sword
    /// meant the damage-type matchup never reached the player's own turns, which is the whole point
    /// of giving weapons a type at all.
    var binderEquipped: [GearSlot: EquippedPiece] = [:]

    /// Purchased at the Workshop. Until then the Binder is manual every turn.
    ///
    /// Automating yourself is *earned* — a locked design decision, and the reason this is a
    /// purchase rather than a setting.
    var hasAutomateSelfUnlock: Bool = false

    /// The Binder's own rule list. Only consulted once `hasAutomateSelfUnlock` is true.
    var binderGambits: [GambitRule] = []

    /// Upgrades bought for the satchel — the bag you carry *into* a world.
    ///
    /// Deliberately independent of the Storehouse (decisions-log session 2): carry limit forces
    /// "keep it or leave it" in-world, storage limit forces "hoard or refine" at home. Two
    /// pressures, two upgrade paths.
    var satchelTier: Int = 0

    /// Gambit slots bought at the Workshop. The Constellation grants more on top, and those
    /// survive a reset while these don't — which is the whole point of the two layers.
    var purchasedGambitSlots: Int = 0

    static func newGame() -> BaseState {
        var state = BaseState()
        state.ownedSymbols = Set(ContentCatalog.shared.starterSymbolIDs)
        state.ownedGambitComponents = Set(GambitStarter.components)
        state.stations = ContentCatalog.shared.stations.reduce(into: [:]) { result, station in
            result[station.id] = StationState(isUnlocked: station.unlockedAtStart, tier: station.startingTier)
        }
        state.companion.gambits = GambitStarter.rules
        state.syncInventoryCapacity()
        return state
    }

    // MARK: Derived

    /// A station's state, falling back to **what the catalog says** rather than to locked.
    ///
    /// A station added to `stations.json` after a save was written isn't in that save's dictionary,
    /// and defaulting to locked meant it could never appear — the Library was invisible on any save
    /// made before it existed. Content added later should show up, not stay hidden forever.
    func station(_ id: StationID) -> StationState {
        stations[id] ?? StationState(
            isUnlocked: ContentCatalog.shared.station(id)?.unlockedAtStart ?? false,
            tier: ContentCatalog.shared.station(id)?.startingTier ?? 0)
    }

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
    /// A fresh id for something entering the storehouse. Monotonic over what's already there, so a
    /// piece coming off somebody can't collide with one already on the shelf.
    /// What one of them is wearing in a slot. **Both carry their own** (Aimee, 5 Aug).
    func worn(_ slot: GearSlot, by member: PartyMember) -> EquippedPiece? {
        switch member {
        case .binder: binderEquipped[slot]
        case .companion: companion.equipped[slot]
        }
    }

    /// Puts something on the shelf, or into the waiting pile if there's genuinely no room.
    ///
    /// **Nothing may be discarded on the player's behalf** (Q10). Plain `inventory.add` returns
    /// false when the storehouse is full, and every caller that ignored that return was one bad
    /// day from erasing a mythic blade.
    mutating func store(_ stack: ItemStack) {
        if !inventory.add(stack) { spillover.append(stack) }
    }

    func nextItemID() -> UInt64 {
        (inventory.stacks.map(\.id.rawValue).max() ?? 0) + 1
    }

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
        ownedGambitComponents = try container.decodeIfPresent(Set<GambitComponentID>.self,
                                                              forKey: .ownedGambitComponents)
            ?? Set(GambitStarter.components)
        completedResearch = try container.decodeIfPresent(Set<ResearchNodeID>.self, forKey: .completedResearch) ?? []
        stations = try container.decodeIfPresent([StationID: StationState].self, forKey: .stations) ?? [:]
        bookDraft = try container.decodeIfPresent(BookDraft.self, forKey: .bookDraft) ?? BookDraft()
        page = try container.decodeIfPresent(Page.self, forKey: .page) ?? Page()
        ownedHands = try container.decodeIfPresent(Set<Hand>.self, forKey: .ownedHands) ?? [.crude]
        hasChainingUnlock = try container.decodeIfPresent(Bool.self, forKey: .hasChainingUnlock) ?? false
        companion = try container.decodeIfPresent(CompanionState.self, forKey: .companion) ?? CompanionState()
        binderEquipped = try container.decodeIfPresent([GearSlot: EquippedPiece].self, forKey: .binderEquipped) ?? [:]
        hasAutomateSelfUnlock = try container.decodeIfPresent(Bool.self, forKey: .hasAutomateSelfUnlock) ?? false
        satchelTier = try container.decodeIfPresent(Int.self, forKey: .satchelTier) ?? 0
        purchasedGambitSlots = try container.decodeIfPresent(Int.self, forKey: .purchasedGambitSlots) ?? 0
        binderGambits = try container.decodeIfPresent([GambitRule].self, forKey: .binderGambits) ?? []
        spillover = try container.decodeIfPresent([ItemStack].self, forKey: .spillover) ?? []

        // **Capacity is derived, not remembered.**
        //
        // `Inventory.slots` is stored, so a save written when the storehouse held eight kept
        // holding eight forever — raising the number in `Tuning` did nothing for anybody who had
        // already played. Recomputing it here means a rebalance reaches existing saves, which is
        // the whole reason the numbers live in one file. It can only ever grow the storehouse:
        // `syncInventoryCapacity` doesn't touch what's in it.
        syncInventoryCapacity()
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
    static let library: StationID = "library"
    static let blacksmith: StationID = "blacksmith"
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

/// Who's wearing it. The party is two in v0 and both of them carry their own gear.
enum PartyMember: String, CaseIterable, Identifiable, Sendable {
    case binder, companion

    var id: String { rawValue }
    var combatant: Combatant { self == .binder ? .binder : .companion }
    /// What to call them on screen. The companion has a name of its own; you are you.
    var displayName: String { self == .binder ? "You" : "Companion" }
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
    var gambits: [GambitRule] = []
    /// What Quill is wearing. **Tiers come from gear now, not from research** — you find a sword,
    /// or later you find a smith (decisions-session-12 §3–4).
    var equipped: [GearSlot: EquippedPiece] = [:]

    /// Derived from what's worn. Nothing stores a tier any more, so nothing can drift from it.
    var weaponTier: Int { tier(of: .weapon) }
    var armorTier: Int { tier(of: .armor) }

    private func tier(of slot: GearSlot) -> Int { equipped[slot]?.effectiveTier ?? 0 }

    init() {}

    /// Tolerant, like the layers above it — a rule list whose *shape* changed (as it did when
    /// gambits became composed rather than canned) should cost you your rules, not your save.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Quill"
        maxHP = try container.decodeIfPresent(Int.self, forKey: .maxHP) ?? Tuning.Encounter.companionMaxHP
        gambits = (try? container.decodeIfPresent([GambitRule].self, forKey: .gambits)) ?? GambitStarter.rules
        equipped = try container.decodeIfPresent([GearSlot: EquippedPiece].self, forKey: .equipped) ?? [:]
    }
}

/// What a new Binder starts able to say.
///
/// Two rules out of six components — enough to be useful, little enough that the first thing you
/// research visibly widens what you can write.
enum GambitStarter {
    static let components: [GambitComponentID] = [
        "subject_foe_any", "subject_ally_any",
        "prop_hp", "cmp_below", "thr_50",
        "act_attack", "act_heal",
    ]

    static var rules: [GambitRule] {
        [
            GambitRule(id: InstanceID(rawValue: 1),
                       subject: "subject_ally_any",
                       property: "prop_hp",
                       comparator: "cmp_below",
                       threshold: "thr_50",
                       action: "act_heal"),
            GambitRule(id: InstanceID(rawValue: 2),
                       subject: "subject_foe_any",
                       action: "act_attack"),
        ]
    }
}
