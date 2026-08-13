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
    /// Trading uses a dedicated wallet; `gold` remains the Gold Ore resource ID.
    var goldCoins: Int = 0
    /// Persisted stock snapshot. Empty until the first post-migration expedition outcome.
    var tradingPost: TradingPostState = TradingPostState()
    var recycler: RecyclerState = RecyclerState()
    /// Exact committed practice. Legacy saves start at zero; holdings are not historical proof.
    var lifetimeRawEssenceRefined: Int = 0
    var autoRefineReturnedRawEssence: Bool = false
    /// Makes Continuous settling idempotent across relaunch and repeated outcome consumers.
    var lastAutoRefinedOutcomeID: ExpeditionOutcomeID?

    /// Owned catalog entries. Definitions are data; the save stores only which ones are owned.
    var ownedSymbols: Set<SymbolID> = []

    /// **The words you can actually write.**
    ///
    /// Rune spec principle 2 is *"every **discovered** rune stays writable forever"*, and discovery
    /// was the half that never existed: the palette listed the entire catalogue, so a new player
    /// had all forty-two focuses on their first page. The page's central tension — depth against
    /// breadth, what earns its cells — arrived complete on turn one, and nothing found out in a
    /// world could ever be a word you didn't have.
    var ownedSources: Set<PressureSourceID> = []

    /// The parts you can build rules out of. Learned from the research tree, or found in the wild.
    var ownedGambitComponents: Set<GambitComponentID> = []

    /// Research nodes completed. The tree's state, and the only place it's recorded.
    var completedResearch: Set<ResearchNodeID> = []
    /// Recipes inferred from stock once the Apothecary exists. Once understood, never forgotten.
    var knownConsumableRecipes: Set<ItemID> = []

    /// Instruments selected at the Survey Post for the next departure. This is a Base-layer
    /// packing choice; the instruments themselves and the knowledge they produce remain Reality.
    var instrumentLoadout: Set<PressureTargetID> = []
    /// Distinguishes an intentional empty kit from a save made before loadouts existed.
    var hasConfiguredInstrumentLoadout = false

    /// Per-station progression, keyed by the data-driven station catalog. The Base screen renders
    /// `ContentCatalog.stations` filtered by `isUnlocked`, so adding a v1+ building (blacksmith,
    /// tavern, distillery) is a JSON edit, not a new hardcoded button.
    var stations: [StationID: StationState] = [:]

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

    /// **Who is walking out with you**, as roster indices, in the order they'll stand.
    ///
    /// Aimee asked for this repeatedly and I kept deferring it: *"I still can only add one person
    /// to my party from the fire pit."* It was one index, so the fire could only ever hand you one
    /// person however many you had found.
    var activeParty: [Int] = [0]

    /// The first of them. Kept only for the handful of places that genuinely mean "the one in
    /// front" — everything about *the party* reads `activeParty`.
    var activeCompanion: Int { activeParty.first ?? 0 }

    /// Everybody in the fight, you included, in turn-order-agnostic order.
    var partyMembers: [PartyMember] {
        [.binder] + activeParty.filter { roster.indices.contains($0) }.map(PartyMember.member)
    }

    /// How many more can come. The Binder is one of the five.
    var canTakeAnother: Bool { activeParty.count < Tuning.Party.maximumSize - 1 }

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
        state.ownedSources = Set(ContentCatalog.shared.starterSourceIDs)
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
            + (station(Stations.wayfarersTable).isUnlocked ? Tuning.Economy.fieldcraftSatchelBonus : 0)
    }

    /// Named travellers all have a durable place at Home. Five limits the active combat party,
    /// including the Binder; it is not a lifetime roster cap.
    var canRecruit: Bool { true }

    /// Give somebody a place at Home. Idempotent; active-party capacity is managed separately.
    @discardableResult
    mutating func seat(_ id: TravellerID) -> Bool {
        guard let person = ContentCatalog.shared.traveller(id) else { return false }
        guard !roster.contains(where: { $0.traveller == id }) else { return false }
        var joined = CompanionState()
        joined.name = person.name
        joined.traveller = id
        joined.calling = person.calling
        joined.worldwork = person.worldwork
        joined.icon = person.icon
        joined.gambits = GambitStarter.rules
        // **What their trade already taught them.** Free rather than deducted: a lean is who they
        // were before you met them, and charging it would make a smith arrive behind a stranger.
        joined.character.branchDepth = person.lean
        joined.character.freePoints = person.lean.values.reduce(0, +)
        roster.append(joined)
        return true
    }

    /// **Whatever the game currently calls a starting word, you have it.**
    ///
    /// The same shape as `seatEveryoneFound` and for the same reason: which focuses are starters is
    /// content, it will be re-cut during balancing, and a save written against an older list must
    /// not end up unable to say something the game considers basic. Grows the vocabulary only —
    /// nothing is ever taken back, which is the rune spec's own promise.
    mutating func learnEveryStarterWord() {
        ownedSources.formUnion(ContentCatalog.shared.starterSourceIDs)
        ownedSymbols.formUnion(ContentCatalog.shared.starterSymbolIDs)
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
        for person in ContentCatalog.shared.travellersInAuthoredOrder where library.foundTravellers.contains(person.id) {
            if seat(person.id) { seated.append(person.id) }
        }
        return seated
    }

    /// Somebody's character sheet. **Everybody has one** (session 17 §1).
    func character(_ member: PartyMember) -> CharacterState {
        switch member {
        case .binder: binderCharacter
        case .member(let index):
            roster.indices.contains(index) ? roster[index].character : CharacterState(rank: .front)
        }
    }

    mutating func withCharacter(_ member: PartyMember, _ change: (inout CharacterState) -> Void) {
        switch member {
        case .binder: change(&binderCharacter)
        case .member(let index):
            guard roster.indices.contains(index) else { return }
            change(&roster[index].character)
        }
    }

    /// What one of them is wearing in a slot. **Everybody carries their own** (Aimee, 5 Aug).
    func worn(_ slot: GearSlot, by member: PartyMember) -> EquippedPiece? {
        switch member {
        case .binder: binderEquipped[slot]
        case .member(let index):
            roster.indices.contains(index) ? roster[index].equipped[slot] : nil
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
        let stored = inventory.stacks.map(\.id.rawValue) + spillover.map(\.id.rawValue)
        let worn = Array(binderEquipped.values).compactMap { $0.gearProfile?.stableInstanceID.rawValue }
            + roster.flatMap { $0.equipped.values.compactMap { $0.gearProfile?.stableInstanceID.rawValue } }
        let merchant = tradingPost.stock.flatMap(\.frozenUnits).map(\.id.rawValue)
        return ((stored + worn + merchant).max() ?? 0) + 1
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
        case essence, resources, inventory, spillover, goldCoins, tradingPost, recycler
        case lifetimeRawEssenceRefined, autoRefineReturnedRawEssence, lastAutoRefinedOutcomeID
        case ownedSymbols, ownedGambitComponents
        case completedResearch, knownConsumableRecipes, stations, page, ownedHands, hasChainingUnlock, instrumentLoadout
        case hasConfiguredInstrumentLoadout
        case ownedSources
        case roster, activeCompanion, activeParty, binderEquipped, hasAutomateSelfUnlock, satchelTier
        case purchasedGambitSlots, binderGambits, binderCharacter
        case companion
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(essence, forKey: .essence)
        try c.encode(resources, forKey: .resources)
        try c.encode(inventory, forKey: .inventory)
        try c.encode(spillover, forKey: .spillover)
        try c.encode(goldCoins, forKey: .goldCoins)
        try c.encode(tradingPost, forKey: .tradingPost)
        try c.encode(recycler, forKey: .recycler)
        try c.encode(lifetimeRawEssenceRefined, forKey: .lifetimeRawEssenceRefined)
        try c.encode(autoRefineReturnedRawEssence, forKey: .autoRefineReturnedRawEssence)
        try c.encodeIfPresent(lastAutoRefinedOutcomeID, forKey: .lastAutoRefinedOutcomeID)
        try c.encode(ownedSymbols, forKey: .ownedSymbols)
        try c.encode(ownedSources, forKey: .ownedSources)
        try c.encode(ownedGambitComponents, forKey: .ownedGambitComponents)
        try c.encode(completedResearch, forKey: .completedResearch)
        try c.encode(instrumentLoadout, forKey: .instrumentLoadout)
        try c.encode(hasConfiguredInstrumentLoadout, forKey: .hasConfiguredInstrumentLoadout)
        try c.encode(stations, forKey: .stations)
        try c.encode(page, forKey: .page)
        try c.encode(ownedHands, forKey: .ownedHands)
        try c.encode(hasChainingUnlock, forKey: .hasChainingUnlock)
        try c.encode(roster, forKey: .roster)
        try c.encode(activeParty, forKey: .activeParty)
        try c.encode(binderEquipped, forKey: .binderEquipped)
        try c.encode(hasAutomateSelfUnlock, forKey: .hasAutomateSelfUnlock)
        try c.encode(satchelTier, forKey: .satchelTier)
        try c.encode(purchasedGambitSlots, forKey: .purchasedGambitSlots)
        try c.encode(knownConsumableRecipes, forKey: .knownConsumableRecipes)
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
        ownedSources = try container.decodeIfPresent(Set<PressureSourceID>.self, forKey: .ownedSources) ?? []
        ownedGambitComponents = try container.decodeIfPresent(Set<GambitComponentID>.self,
                                                              forKey: .ownedGambitComponents)
            ?? Set(GambitStarter.components)
        completedResearch = try container.decodeIfPresent(Set<ResearchNodeID>.self, forKey: .completedResearch) ?? []
        lifetimeRawEssenceRefined = try container.decodeIfPresent(Int.self,
                                                                   forKey: .lifetimeRawEssenceRefined) ?? 0
        autoRefineReturnedRawEssence = try container.decodeIfPresent(Bool.self,
                                                                      forKey: .autoRefineReturnedRawEssence) ?? false
        lastAutoRefinedOutcomeID = try container.decodeIfPresent(ExpeditionOutcomeID.self,
                                                                  forKey: .lastAutoRefinedOutcomeID)
        knownConsumableRecipes = try container.decodeIfPresent(Set<ItemID>.self,
                                                                forKey: .knownConsumableRecipes) ?? []
        instrumentLoadout = try container.decodeIfPresent(Set<PressureTargetID>.self,
                                                          forKey: .instrumentLoadout) ?? []
        hasConfiguredInstrumentLoadout = try container.decodeIfPresent(Bool.self,
                                                                        forKey: .hasConfiguredInstrumentLoadout) ?? false
        stations = try container.decodeIfPresent([StationID: StationState].self, forKey: .stations) ?? [:]
        // Migration for saves from the brief window where a built Tannery existed before its
        // immediate Wear capability. Idempotent and free: the player already paid for the room.
        if stations[Stations.tannery]?.isUnlocked == true {
            completedResearch.insert("tannery_wear_root")
        }
        if stations[Stations.weaponsmith]?.isUnlocked == true {
            completedResearch.insert("weaponsmith_point_root")
        }
        // A paid Apothecary must never reopen empty. This reconciles saves from before its
        // first-use guarantee without granting stock or changing the station's tier.
        if stations[Stations.apothecary]?.isUnlocked == true {
            knownConsumableRecipes.insert("salve_lesser")
        }
        page = try container.decodeIfPresent(Page.self, forKey: .page) ?? Page()
        ownedHands = try container.decodeIfPresent(Set<Hand>.self, forKey: .ownedHands) ?? [.crude]
        hasChainingUnlock = try container.decodeIfPresent(Bool.self, forKey: .hasChainingUnlock) ?? false
        // A save written before the roster existed holds exactly one companion; she becomes the
        // roster, and keeps everything she had.
        roster = try container.decodeIfPresent([CompanionState].self, forKey: .roster)
            ?? [try container.decodeIfPresent(CompanionState.self, forKey: .companion) ?? CompanionState()]
        if roster.isEmpty { roster = [CompanionState()] }
        // A save from when only one person could come brings that one person with it.
        if let savedParty = try container.decodeIfPresent([Int].self, forKey: .activeParty) {
            // Empty is a deliberate Binder-only party. Only a genuinely absent legacy field
            // inherits the old single active companion.
            activeParty = savedParty.filter { $0 >= 0 }
        } else {
            activeParty = [try container.decodeIfPresent(Int.self, forKey: .activeCompanion) ?? 0]
        }
        binderEquipped = try container.decodeIfPresent([GearSlot: EquippedPiece].self, forKey: .binderEquipped) ?? [:]
        hasAutomateSelfUnlock = try container.decodeIfPresent(Bool.self, forKey: .hasAutomateSelfUnlock) ?? false
        satchelTier = try container.decodeIfPresent(Int.self, forKey: .satchelTier) ?? 0
        purchasedGambitSlots = try container.decodeIfPresent(Int.self, forKey: .purchasedGambitSlots) ?? 0
        binderGambits = try container.decodeIfPresent([GambitRule].self, forKey: .binderGambits) ?? []
        binderCharacter = try container.decodeIfPresent(CharacterState.self, forKey: .binderCharacter)
            ?? CharacterState(rank: .front)
        spillover = try container.decodeIfPresent([ItemStack].self, forKey: .spillover) ?? []
        goldCoins = max(0, try container.decodeIfPresent(Int.self, forKey: .goldCoins) ?? 0)
        tradingPost = try container.decodeIfPresent(TradingPostState.self, forKey: .tradingPost)
            ?? TradingPostState()
        recycler = try container.decodeIfPresent(RecyclerState.self, forKey: .recycler)
            ?? RecyclerState()

        migrateEquippedGearProfiles()

        // **Capacity is derived, not remembered.**
        //
        // `Inventory.slots` is stored, so a save written when the storehouse held eight kept
        // holding eight forever — raising the number in `Tuning` did nothing for anybody who had
        // already played. Recomputing it here means a rebalance reaches existing saves, which is
        // the whole reason the numbers live in one file. It can only ever grow the storehouse:
        // `syncInventoryCapacity` doesn't touch what's in it.
        syncInventoryCapacity()
    }

    /// Equipped legacy saves had no instance id. Assign one once, after every storage location has
    /// decoded, and freeze the catalogue combat shape into the shared profile. Subsequent
    /// equip/unequip cycles preserve this id rather than minting a new history for the same piece.
    private mutating func migrateEquippedGearProfiles() {
        var used = Set(inventory.stacks.map(\.id.rawValue) + spillover.map(\.id.rawValue))
        for profile in inventory.stacks.compactMap(\.gearProfile) { used.insert(profile.stableInstanceID.rawValue) }
        for profile in spillover.compactMap(\.gearProfile) { used.insert(profile.stableInstanceID.rawValue) }
        var next = (used.max() ?? 0) + 1

        // A very old save could hold several identical pieces in one stack. Physical gear now has
        // per-instance history, so expand that legacy quantity losslessly before assigning worn
        // IDs. The first copy keeps its old identity; each additional copy gets a durable fresh one.
        func splitLegacyGear(_ stacks: [ItemStack]) -> [ItemStack] {
            var expanded: [ItemStack] = []
            for stack in stacks {
                guard stack.gearProfile != nil, stack.count > 1 else {
                    expanded.append(stack)
                    continue
                }
                for copyIndex in 0..<stack.count {
                    var copy = stack
                    copy.count = 1
                    copy.protectedReturnCount = min(copy.protectedReturnCount, 1)
                    if copyIndex > 0 {
                        while used.contains(next) { next += 1 }
                        copy.id = InstanceID(rawValue: next)
                        copy.gearProfile?.stableInstanceID = copy.id
                        used.insert(next)
                        next += 1
                    }
                    expanded.append(copy)
                }
            }
            return expanded
        }

        inventory.stacks = splitLegacyGear(inventory.stacks)
        spillover = splitLegacyGear(spillover)

        func migrated(_ piece: EquippedPiece) -> EquippedPiece {
            var result = piece
            guard let definition = ContentCatalog.shared.item(piece.catalogID), definition.gear != nil
            else { return result }
            if result.gearProfile == nil {
                result.gearProfile = GearInstanceProfile(stableInstanceID: InstanceID(rawValue: next),
                                                         definition: definition,
                                                         legacyUpgradeLevel: piece.upgradeLevel)
                used.insert(next)
                next += 1
            } else if result.gearProfile?.stableInstanceID.rawValue == 0 {
                while used.contains(next) { next += 1 }
                result.gearProfile?.stableInstanceID = InstanceID(rawValue: next)
                used.insert(next)
                next += 1
            }
            return result
        }

        for slot in Array(binderEquipped.keys) {
            if let piece = binderEquipped[slot] { binderEquipped[slot] = migrated(piece) }
        }
        for index in roster.indices {
            for slot in Array(roster[index].equipped.keys) {
                if let piece = roster[index].equipped[slot] {
                    roster[index].equipped[slot] = migrated(piece)
                }
            }
        }
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
    static let tradingPost: StationID = "trading_post"
    static let recycler: StationID = "recycler"
    static let tannery: StationID = "tannery"
    static let bowyer: StationID = "bowyer"
    static let armoury: StationID = "armoury"
    static let weaponsmith: StationID = "weaponsmith"
    static let scriptorium: StationID = "scriptorium"
    static let firepit: StationID = "firepit"
    static let surveyPost: StationID = "survey_post"
    static let apothecary: StationID = "apothecary"
    static let reliquary: StationID = "reliquary"
    static let wayfarersTable: StationID = "wayfarers_table"
    static let anchorage: StationID = "anchorage"
    static let distillery: StationID = "distillery"
    static let channelworks: StationID = "channelworks"
}

struct StationState: Codable, Equatable, Sendable {
    var isUnlocked: Bool
    /// 0 = built but un-upgraded. Storehouse tiers 1–3 are the v0 example.
    var tier: Int
}

/// Who's wearing it. The party is two in v0 and both of them carry their own gear.
/// **Somebody in the party**, as opposed to somebody in a fight.
///
/// `PartyMember` is the combat vocabulary and knows about exactly two people. This is who *exists*
/// — the Binder, and everybody at the fire — which is what the Party screen is a list of.
/// **Somebody in the party** — the Binder, or one of the people at the fire.
///
/// `PartySlot` and `PartyMember` were two names for this, and the split is what let the party of
/// five stall: one of them knew about a roster and the other knew about a fight, so nothing could
/// talk about the same person on both sides of the door. They're one type now, and `PartySlot`
/// survives as a spelling of it.
enum PartyMember: Hashable, Identifiable, Sendable, Codable {
    case binder
    case member(Int)

    var id: String {
        switch self {
        case .binder: "binder"
        case .member(let index): "member-\(index)"
        }
    }

    /// Which of the roster this is, if it isn't you.
    var rosterIndex: Int? { if case .member(let index) = self { index } else { nil } }

    /// Who this is inside a fight.
    var combatant: Combatant {
        switch self {
        case .binder: .binder
        case .member(let index): .companion(index)
        }
    }

    /// What to call them when there's no roster to hand. Everyone else has a name of their own.
    var displayName: String {
        switch self {
        case .binder: "You"
        case .member: "Companion"
        }
    }
}

typealias PartySlot = PartyMember

/// The one companion in v0. Party expands in v1+, so this is a struct that can become an array
/// element without reshaping the save.
struct CompanionState: Codable, Equatable, Sendable {
    var name: String = "Quill" // PLACEHOLDER name
    /// Who they were out in the worlds. Nil for Quill, who was always here.
    var traveller: TravellerID?
    /// What they were before the sundering, in their own words — *a smith*, *a surveyor*.
    var calling: String = ""
    var icon: String = "person.fill"
    /// Visible anchored-realm aptitude. Old and generated companions default to ordinary (1).
    var worldwork: Int = 1
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
        worldwork = min(3, max(0, try container.decodeIfPresent(Int.self, forKey: .worldwork) ?? 1))
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
