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

    /// **Everybody who has come home with you.**
    ///
    /// Recruiting used to write a name into the Library and do nothing else — no roster, no gear,
    /// no presence. Aimee found somebody, lost a run, and had *"no idea what happened to her"*
    /// (6 Aug). She was kept, in Reality, where nothing can take her; there was simply nothing to
    /// show for it, which is indistinguishable from losing her.
    ///
    /// Quill is index 0 and always there. Everyone else arrives by being talked into it.
    var roster: [CompanionState] = [CompanionState()]

    /// Which of them is standing beside you. **[PLACEHOLDER]** — a party of five fights together
    /// (Aimee, 6 Aug) and that's the next piece; today one of them comes along.
    var activeCompanion: Int = 0

    /// Who's fighting beside you, as one value. Kept as a property so the hundred places that read
    /// `base.companion` don't all have to learn about the roster at once.
    var companion: CompanionState {
        get { roster.indices.contains(activeCompanion) ? roster[activeCompanion] : CompanionState() }
        set {
            if roster.isEmpty { roster = [newValue] }
            else if roster.indices.contains(activeCompanion) { roster[activeCompanion] = newValue }
            else { roster[0] = newValue }
        }
    }

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

    /// **Who the Binder is.** Half the party, and it had no more of a character sheet than a
    /// constant — the same gap session 17 §1 names for the companion.
    var binderCharacter: CharacterState = CharacterState(rank: .front)

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

    /// Whether there's room for another person. **Up to five** (Aimee, 6 Aug).
    var canRecruit: Bool { roster.count < Tuning.Party.maximumSize }

    /// Give somebody a place at the fire. Idempotent, and silent if there's no room.
    @discardableResult
    mutating func seat(_ id: TravellerID) -> Bool {
        guard let person = ContentCatalog.shared.traveller(id) else { return false }
        guard !roster.contains(where: { $0.traveller == id }) else { return false }
        guard canRecruit else { return false }
        var joined = CompanionState()
        joined.name = person.name
        joined.traveller = id
        joined.calling = person.calling
        joined.icon = person.icon
        joined.gambits = GambitStarter.rules
        roster.append(joined)
        return true
    }

    /// **Everybody you've found has to be somewhere you can see them.**
    ///
    /// Aimee, 7 Aug: *"I have FOUND TRAVELERS. that is NOT the issue. the FOUND travelers not
    /// appearing at the firepit is the issue."*
    ///
    /// The roster is newer than the search loop. Anyone recruited before it existed was written into
    /// `library.foundTravellers` and nowhere else — and because worldgen refuses to place a traveller
    /// who has already been found, they could never be met again either. Found, gone, and no way
    /// back: the Firepit was telling the truth about an empty roster, and the truth was the bug.
    ///
    /// So the Library is the record of who you found, and the roster is reconciled against it rather
    /// than trusted to have been kept in step. Runs at launch, and it is idempotent, so it also
    /// heals any future divergence instead of letting one compound.
    @discardableResult
    mutating func seatEveryoneFound(in library: LibraryState) -> [TravellerID] {
        var seated: [TravellerID] = []
        // Catalogue order, so which four get seats is stable rather than dependent on set ordering.
        for person in ContentCatalog.shared.travellers where library.foundTravellers.contains(person.id) {
            if seat(person.id) { seated.append(person.id) }
        }
        return seated
    }

    /// Somebody's character sheet. **Both of them have one** (session 17 §1).
    func character(_ member: PartyMember) -> CharacterState {
        switch member {
        case .binder: binderCharacter
        case .companion: companion.character
        }
    }

    mutating func withCharacter(_ member: PartyMember, _ change: (inout CharacterState) -> Void) {
        switch member {
        case .binder: change(&binderCharacter)
        case .companion: change(&companion.character)
        }
    }

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

    /// A fresh id for something entering the storehouse. Monotonic over what's already there, so a
    /// piece coming off somebody can't collide with one already on the shelf.
    func nextItemID() -> UInt64 {
        (inventory.stacks.map(\.id.rawValue).max() ?? 0) + 1
    }

    /// `Inventory.slots` is the stored capacity (the run satchel has its own), so it has to be
    /// re-synced whenever a Storehouse tier changes. One formula, one assignment — call this
    /// after any station upgrade rather than computing capacity in two places.
    mutating func syncInventoryCapacity() {
        inventory.slots = inventoryCapacity
    }

    init() {}

    /// Explicit because `companion` is no longer stored — it's a window onto the roster — and the
    /// decoder still has to be able to read it out of a save written before the roster existed.
    private enum CodingKeys: String, CodingKey {
        case essence, resources, inventory, spillover, ownedSymbols, ownedGambitComponents
        case completedResearch, stations, bookDraft, page, ownedHands, hasChainingUnlock
        case roster, activeCompanion, binderEquipped, hasAutomateSelfUnlock, satchelTier
        case purchasedGambitSlots, binderGambits, binderCharacter
        case companion
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(essence, forKey: .essence)
        try c.encode(resources, forKey: .resources)
        try c.encode(inventory, forKey: .inventory)
        try c.encode(spillover, forKey: .spillover)
        try c.encode(ownedSymbols, forKey: .ownedSymbols)
        try c.encode(ownedGambitComponents, forKey: .ownedGambitComponents)
        try c.encode(completedResearch, forKey: .completedResearch)
        try c.encode(stations, forKey: .stations)
        try c.encode(bookDraft, forKey: .bookDraft)
        try c.encode(page, forKey: .page)
        try c.encode(ownedHands, forKey: .ownedHands)
        try c.encode(hasChainingUnlock, forKey: .hasChainingUnlock)
        try c.encode(roster, forKey: .roster)
        try c.encode(activeCompanion, forKey: .activeCompanion)
        try c.encode(binderEquipped, forKey: .binderEquipped)
        try c.encode(hasAutomateSelfUnlock, forKey: .hasAutomateSelfUnlock)
        try c.encode(satchelTier, forKey: .satchelTier)
        try c.encode(purchasedGambitSlots, forKey: .purchasedGambitSlots)
        try c.encode(binderGambits, forKey: .binderGambits)
        try c.encode(binderCharacter, forKey: .binderCharacter)
    }

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
        // A save written before the roster existed holds exactly one companion; she becomes the
        // roster, and keeps everything she had.
        roster = try container.decodeIfPresent([CompanionState].self, forKey: .roster)
            ?? [try container.decodeIfPresent(CompanionState.self, forKey: .companion) ?? CompanionState()]
        if roster.isEmpty { roster = [CompanionState()] }
        activeCompanion = try container.decodeIfPresent(Int.self, forKey: .activeCompanion) ?? 0
        binderEquipped = try container.decodeIfPresent([GearSlot: EquippedPiece].self, forKey: .binderEquipped) ?? [:]
        hasAutomateSelfUnlock = try container.decodeIfPresent(Bool.self, forKey: .hasAutomateSelfUnlock) ?? false
        satchelTier = try container.decodeIfPresent(Int.self, forKey: .satchelTier) ?? 0
        purchasedGambitSlots = try container.decodeIfPresent(Int.self, forKey: .purchasedGambitSlots) ?? 0
        binderGambits = try container.decodeIfPresent([GambitRule].self, forKey: .binderGambits) ?? []
        binderCharacter = try container.decodeIfPresent(CharacterState.self, forKey: .binderCharacter)
            ?? CharacterState(rank: .front)
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
    static let scriptorium: StationID = "scriptorium"
    static let firepit: StationID = "firepit"
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
/// **Somebody in the party**, as opposed to somebody in a fight.
///
/// `PartyMember` is the combat vocabulary and knows about exactly two people. This is who *exists*
/// — the Binder, and everybody at the fire — which is what the Party screen is a list of.
enum PartySlot: Hashable, Identifiable, Sendable {
    case binder
    case member(Int)

    var id: String {
        switch self {
        case .binder: "binder"
        case .member(let index): "member-\(index)"
        }
    }

    /// How this maps onto a fight today: the Binder is the Binder, and whoever came along is the
    /// companion. **[PLACEHOLDER]** until five fight together.
    func combatant(activeCompanion: Int) -> PartyMember? {
        switch self {
        case .binder: .binder
        case .member(let index): index == activeCompanion ? .companion : nil
        }
    }
}

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
    /// Who they were out in the worlds. Nil for Quill, who was always here.
    var traveller: TravellerID?
    /// What they were before the sundering, in their own words — *a smith*, *a surveyor*.
    var calling: String = ""
    var icon: String = "person.fill"
    /// Only the *maximum* lives here. Current HP is run-scoped (`WorldRun.companionHP`) because
    /// the brief says HP persists during a run and returning home fully heals — so a base-side
    /// current-HP field would be a second source of truth that is always full.
    var maxHP: Int = Tuning.Encounter.companionMaxHP
    /// **Who they are** (session 17 §1) — stats, level, and where they stand.
    var character: CharacterState = CharacterState(rank: .front)
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
        traveller = try container.decodeIfPresent(TravellerID.self, forKey: .traveller)
        calling = try container.decodeIfPresent(String.self, forKey: .calling) ?? ""
        icon = try container.decodeIfPresent(String.self, forKey: .icon) ?? "person.fill"
        maxHP = try container.decodeIfPresent(Int.self, forKey: .maxHP) ?? Tuning.Encounter.companionMaxHP
        gambits = (try? container.decodeIfPresent([GambitRule].self, forKey: .gambits)) ?? GambitStarter.rules
        equipped = try container.decodeIfPresent([GearSlot: EquippedPiece].self, forKey: .equipped) ?? [:]
        character = try container.decodeIfPresent(CharacterState.self, forKey: .character)
            ?? CharacterState(rank: .front)
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
