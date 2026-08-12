import Foundation

enum RosterPlacement: Equatable, Sendable {
    case home
    case activeParty
    case anchoredRealm(id: Int, name: String)
}

struct PartyTransferPreview: Identifiable, Equatable, Sendable {
    let index: Int
    let name: String
    let source: RosterPlacement
    let stationNames: [String]
    let realmProductionBefore: Int?
    let realmProductionAfter: Int?
    let realmShortfallBefore: Int?
    let realmShortfallAfter: Int?

    var id: Int { index }
}

enum RosterPlacementRules {
    static func placement(of index: Int, in state: GameState) -> RosterPlacement {
        if state.base.activeParty.contains(index) { return .activeParty }
        if let realm = state.worlds.anchoredRealms.first(where: {
            !$0.isDormant && $0.assignedCompanions.contains(index)
        }) {
            return .anchoredRealm(id: realm.id, name: realm.name)
        }
        return .home
    }

    static func contribution(of index: Int, in state: GameState) -> Int {
        guard state.base.roster.indices.contains(index) else { return 0 }
        let person = state.base.roster[index]
        return Tuning.Anchoring.worldworkBaseContribution + person.worldwork
            + max(0, person.character.level - 1) / Tuning.Anchoring.levelsPerWorldworkBonus
    }

    static func recalculateRealmProduction(in state: inout GameState) {
        for index in state.worlds.anchoredRealms.indices {
            state.worlds.anchoredRealms[index].productionContribution = state.worlds
                .anchoredRealms[index].assignedCompanions.reduce(0) { total, companion in
                    total + contribution(of: companion, in: state)
                }
        }
    }

    /// Repairs the old independent index arrays once at decode. Party wins; otherwise the earliest
    /// active realm keeps the worker. Invalid, dormant and duplicate references return Home.
    static func reconcileLegacyProjections(in state: inout GameState) -> Bool {
        var changed = false
        var seenParty = Set<Int>()
        let party = state.base.activeParty.filter { index in
            let valid = state.base.roster.indices.contains(index)
                && seenParty.insert(index).inserted
                && seenParty.count <= Tuning.Party.maximumSize - 1
            if !valid { changed = true }
            return valid
        }
        if party != state.base.activeParty {
            state.base.activeParty = party
            changed = true
        }

        var claimed = Set(party)
        for realmIndex in state.worlds.anchoredRealms.indices.sorted(by: {
            state.worlds.anchoredRealms[$0].id < state.worlds.anchoredRealms[$1].id
        }) {
            let realm = state.worlds.anchoredRealms[realmIndex]
            var local = Set<Int>()
            let repaired = realm.assignedCompanions.filter { companion in
                let keep = !realm.isDormant
                    && state.base.roster.indices.contains(companion)
                    && !claimed.contains(companion)
                    && local.insert(companion).inserted
                if keep { claimed.insert(companion) }
                else { changed = true }
                return keep
            }
            if repaired != realm.assignedCompanions {
                state.worlds.anchoredRealms[realmIndex].assignedCompanions = repaired
            }
        }
        recalculateRealmProduction(in: &state)
        return changed
    }
}

/// Spending actions: the Workshop, the Storehouse, the Constellation, and opening a cache.
extension GameStore {
    @discardableResult func crystalliseEssence() -> Bool {
        guard DistilleryRules.canCrystallise(in: state) else { return false }
        var made = false
        mutate("crystallise essence", flush: true) { made = DistilleryRules.crystallise(in: &$0) }
        return made
    }

    @discardableResult func attuneCore(_ attunement: CoreAttunement,
                                       candidate: DistilleryRules.Candidate,
                                       catalyst: ResourceID) -> Bool {
        guard DistilleryRules.canAttune(attunement, candidate: candidate, catalyst: catalyst, in: state) else { return false }
        var made = false
        mutate("attune \(attunement.rawValue) core", flush: true) {
            made = DistilleryRules.attune(attunement, candidate: candidate, catalyst: catalyst, in: &$0)
        }
        return made
    }

    @discardableResult func constructConduitFixture() -> Bool {
        var made = false
        mutate("construct conduit fixture", flush: true) { made = DistilleryRules.constructConduit(in: &$0) }
        return made
    }

    @discardableResult
    func craftAnchorFrame() -> Bool {
        guard AnchorFrameRules.canCraft(in: state) else { return false }
        var crafted = false
        mutate("craft Anchor Frame", flush: true) { crafted = AnchorFrameRules.craft(in: &$0) }
        return crafted
    }


    // MARK: - Workshop

    /// Raw essence → essence. The join between what worlds give you and what the base spends.
    @discardableResult
    func refineEssence(rawUnits: Int) -> Bool {
        let available = state.base.resources[Resources.essenceRaw]
        let amount = min(max(0, rawUnits), available)
        guard amount > 0 else { return false }

        mutate("refine \(amount) raw essence", flush: true) { state in
            state.base.resources.spend(amount, of: Resources.essenceRaw)
            state.base.essence += EconomyRules.refine(rawUnits: amount)
        }
        return true
    }

    func refineAllEssence() {
        refineEssence(rawUnits: state.base.resources[Resources.essenceRaw])
    }

    /// **The base never strands you.**
    ///
    /// Essence only enters the game by coming home from a world — the Spring's trickle, or raw
    /// essence hauled back and refined. So a player who spends their last essence on a book and
    /// returns empty-handed has no way to write another one, and the game is simply over with no
    /// message saying so. That's a dead end, and it breaks the pillar that every session has to
    /// advance *something*.
    ///
    /// So when you're home and can't afford even the cheapest possible book — counting the raw
    /// essence you could still refine — the Spring makes up the difference. It is the one thing in
    /// the game that gives you something for nothing, and it exists precisely so that nothing else
    /// has to.
    func ensureDepartureIsPossible() {
        guard state.worlds.activeRun == nil else { return }
        let floor = EconomyRules.minimumBindCost(in: state)
        guard EconomyRules.spendableEssence(in: state) < floor else { return }

        mutate("the spring provides", flush: true) { state in
            let shortfall = floor - EconomyRules.spendableEssence(in: state)
            let subsidy = max(0, shortfall)
            state.base.essence += subsidy
            let runway = EconomyRules.spendableEssence(in: state)
            state.worlds.lastExit?.essenceEconomy.antiLockSubsidy += subsidy
            state.worlds.lastExit?.essenceEconomy.netRunway = runway
        }
    }

    /// True when the only thing standing between the player and a world is a trip to the Refinery.
    var needsToRefine: Bool {
        state.base.essence < EconomyRules.minimumBindCost(in: state)
            && state.base.resources[Resources.essenceRaw] > 0
    }

    // MARK: Research

    func isComplete(_ node: ResearchNodeDef) -> Bool { EconomyRules.isComplete(node, in: state) }
    func isSuppliedByKeeper(_ node: ResearchNodeDef) -> Bool {
        !isComplete(node) && EconomyRules.stationTierAlreadySupplied(by: node, in: state)
    }
    func isAvailable(_ node: ResearchNodeDef) -> Bool { EconomyRules.isAvailable(node, in: state) }
    func missingPrerequisites(for node: ResearchNodeDef) -> [String] {
        EconomyRules.missingPrerequisites(node, in: state)
    }
    func paidCost(for node: ResearchNodeDef) -> UpgradeCost { EconomyRules.paidCost(for: node, in: state) }
    func shortfall(for node: ResearchNodeDef) -> [String] {
        EconomyRules.shortfall(paidCost(for: node), in: state)
    }

    func canResearch(_ node: ResearchNodeDef) -> Bool {
        EconomyRules.isAvailable(node, in: state) && EconomyRules.canAfford(paidCost(for: node), in: state)
    }

    /// Complete a research node. Everything buyable in the game goes through here — there is no
    /// flat shopping list, only branches with prerequisites.
    @discardableResult
    func research(_ node: ResearchNodeDef) -> Bool {
        guard canResearch(node) else { return false }
        mutate("research \(node.id.rawValue)", flush: true) { state in
            EconomyRules.pay(EconomyRules.paidCost(for: node, in: state), in: &state)
            EconomyRules.complete(node, in: &state)
        }
        return true
    }

    /// How far along a branch is, for the Workshop's summary line.
    func progress(in branch: ResearchBranchDef) -> (done: Int, total: Int) {
        let nodes = ContentCatalog.shared.nodes(in: branch.id)
        return (nodes.count { isComplete($0) || isSuppliedByKeeper($0) }, nodes.count)
    }

    /// How many nodes in a branch you could buy **right now** — so the branch list can say which
    /// ones are worth opening without you having to open all of them to find out.
    func availableCount(in branch: ResearchBranchDef) -> Int {
        ContentCatalog.shared.nodes(in: branch.id).count {
            !isComplete($0) && isAvailable($0) && shortfall(for: $0).isEmpty
        }
    }

    func instrumentCraftingReadiness(for target: PressureTargetID) -> InstrumentCraftingRules.Readiness {
        InstrumentCraftingRules.readiness(for: target, in: state)
    }

    @discardableResult
    func improveInstrument(_ target: PressureTargetID) -> Bool {
        guard instrumentCraftingReadiness(for: target).isReady else { return false }
        var made = false
        mutate("improve instrument \(target.rawValue)", flush: true) { state in
            made = InstrumentCraftingRules.craftUpgrade(for: target, in: &state)
        }
        return made
    }

    func discoverConsumableRecipes() {
        let inferred = Set(ConsumableCraftingRules.recipes.filter {
            ConsumableCraftingRules.canInfer($0, in: state)
        }.map(\.output))
        let new = inferred.subtracting(state.base.knownConsumableRecipes)
        guard !new.isEmpty else { return }
        mutate("infer apothecary recipes", flush: true) {
            $0.base.knownConsumableRecipes.formUnion(new)
        }
    }

    @discardableResult
    func craftConsumable(_ recipe: ConsumableCraftingRules.Recipe) -> Bool {
        guard ConsumableCraftingRules.shortfall(recipe, in: state).isEmpty else { return false }
        var crafted = false
        mutate("prepare \(recipe.output.rawValue)", flush: true) {
            crafted = ConsumableCraftingRules.craft(recipe, in: &$0)
        }
        return crafted
    }

    // MARK: - Storehouse

    var unidentifiedStacks: [ItemStack] { state.base.inventory.stacks.filter { !$0.identified } }

    var canAffordIdentify: Bool { state.base.essence >= Tuning.Economy.identifyCostEssence }

    /// Find out what a curio actually is. The small version of the per-component identification
    /// the writing system will want later.
    @discardableResult
    func identify(_ stack: ItemStack) -> ItemDef? {
        guard canAffordIdentify, let revealed = EconomyRules.identification(of: stack) else { return nil }
        mutate("identify \(stack.catalogID.rawValue)", flush: true) { state in
            state.base.essence -= Tuning.Economy.identifyCostEssence
            guard let index = state.base.inventory.stacks.firstIndex(where: { $0.id == stack.id }) else { return }
            // **One at a time.** Unidentified curios of the same kind share a bin, and you paid to
            // learn about *one* of them — splitting it out is what keeps the price honest, and the
            // rest stay a mystery worth another five essence.
            guard var identified = state.base.inventory.stacks[index].removing(1) else { return }
            identified.catalogID = revealed.id
            identified.identified = true
            if state.base.inventory.stacks[index].isEmpty {
                state.base.inventory.stacks.remove(at: index)
            }
            _ = state.base.inventory.add(identified)
        }
        return revealed
    }

    // MARK: - Constellation

    func moteCost(of node: ConstellationNodeDef) -> Int? { EconomyRules.moteCost(of: node, in: state) }

    func canBuy(_ node: ConstellationNodeDef) -> Bool {
        guard let cost = moteCost(of: node) else { return false }
        return state.reality.motes >= cost
    }

    /// Constellation nodes are the Reality layer's only spend. The effect belongs to the campaign's
    /// Reality state rather than one building or one current party member.
    @discardableResult
    func buy(_ node: ConstellationNodeDef) -> Bool {
        guard let quotedCost = moteCost(of: node), state.reality.motes >= quotedCost else {
            return false
        }
        var bought = false
        mutate("constellation: \(node.id.rawValue)", flush: true) { state in
            guard let cost = EconomyRules.moteCost(of: node, in: state),
                  state.reality.motes >= cost else { return }
            state.reality.motes -= cost
            state.reality.constellation[node.id, default: 0] += 1
            bought = true
        }
        return bought
    }

    // MARK: - Locked caches

    /// The delayed payoff: a key found in one world, carried home, identified, and spent on a lock
    /// standing in a different world entirely.
    ///
    /// The "different world" part enforces itself — a curio can only be identified at the
    /// Storehouse, and by the time you're home the world it came from is gone.
    @discardableResult
    func openCacheHere() -> EconomyRules.CacheReward? {
        guard isOnLockedCache, let key = carriedCacheKey, activeEncounter == nil else { return nil }

        var reward: EconomyRules.CacheReward?
        var bonusName: String?
        mutate("open locked cache", flush: true) { state in
            guard var run = state.worlds.activeRun else { return }
            let rolled = EconomyRules.rollCacheReward(in: state, rng: &run.rng)
            let readings = BookRules.readings(for: run.book, seed: run.mapSeed)
            if let id = ApexRules.cacheBonus(for: readings, rng: &run.rng) {
                    let stack = ItemStack(id: InstanceID(rawValue: run.rng.next()), catalogID: id)
                    bonusName = ContentCatalog.shared.item(id)?.name ?? "Something you couldn't make"
                    if !run.satchelItems.add(stack) { run.offeredItems.append(stack) }
            }
            run.map[run.playerPosition].content = .empty
            state.worlds.activeRun = run

            EconomyRules.grant(rolled, in: &state)
            state.base.inventory.remove(key.id) // the key is spent
            reward = rolled
        }
        if let reward {
            let bonus = bonusName.map { " A wild weapon was tucked beside it: \($0)." } ?? ""
            recentEvents = [.cacheOpened(EconomyRules.describe(reward) + bonus)]
        }
        return reward
    }

    // MARK: - Spillover

    /// Loot waiting on a decision because the Storehouse was full when it came home.
    var spillover: [ItemStack] { state.base.spillover }

    /// Move a spilled stack into the Storehouse proper. Refused rather than silently swapped when
    /// there's still no room — the player has to make space first.
    @discardableResult
    func storeSpilled(_ stack: ItemStack) -> Bool {
        guard !state.base.inventory.isFull,
              state.base.spillover.contains(where: { $0.id == stack.id })
        else { return false }
        mutate("store spilled item", flush: true) { state in
            guard state.base.inventory.add(stack) else { return }
            state.base.spillover.removeAll { $0.id == stack.id }
        }
        return true
    }

    /// Throw a spilled stack away. Deliberate, explicit, and the *only* way loot leaves the game
    /// once it's been banked — nothing may discard on the player's behalf (Q10).
    func discardSpilled(_ stack: ItemStack) {
        mutate("discard spilled item", flush: true) { state in
            state.base.spillover.removeAll { $0.id == stack.id }
        }
    }

    /// Swap a spilled stack for one already stored, when the Storehouse is full and the player
    /// would rather keep the new thing.
    func swapSpilled(_ spilled: ItemStack, for stored: ItemStack) {
        mutate("swap spilled item", flush: true) { state in
            guard state.base.spillover.contains(where: { $0.id == spilled.id }),
                  state.base.inventory.stacks.contains(where: { $0.id == stored.id })
            else { return }
            state.base.inventory.remove(stored.id)
            guard state.base.inventory.add(spilled) else {
                // Couldn't place it after all — put the old one back rather than losing both.
                state.base.inventory.add(stored)
                return
            }
            state.base.spillover.removeAll { $0.id == spilled.id }
            state.base.spillover.append(stored)
        }
    }

    // MARK: - Gear

    struct WearableGearOption: Identifiable, Equatable {
        enum Source: Equatable {
            case stored(InstanceID)
            case overflow(InstanceID)
            case worn(PartySlot)
            case carried(InstanceID)
        }

        let piece: EquippedPiece
        let source: Source
        let count: Int

        var id: String {
            switch source {
            case .stored(let id): "stored-\(id.rawValue)"
            case .overflow(let id): "overflow-\(id.rawValue)"
            case .worn(let owner): "worn-\(owner.id)-\(piece.gearProfile?.stableInstanceID.rawValue ?? 0)"
            case .carried(let id): "carried-\(id.rawValue)"
            }
        }

        var canEquipAtHome: Bool {
            if case .carried = source { return false }
            return true
        }
    }

    /// Every compatible piece the player owns, wherever it currently is. Physical instance data
    /// is authoritative: a catalogue rebalance must not change an existing blade into another slot.
    func wearableOptions(in slot: GearSlot, excluding wearer: PartySlot? = nil) -> [WearableGearOption] {
        let stored = state.base.inventory.stacks.compactMap { stack -> WearableGearOption? in
            guard (stack.gearProfile?.slot ?? ContentCatalog.shared.item(stack.catalogID)?.gear?.slot) == slot else { return nil }
            return WearableGearOption(piece: EquippedPiece(stack), source: .stored(stack.id), count: stack.count)
        }
        let overflow = state.base.spillover.compactMap { stack -> WearableGearOption? in
            guard (stack.gearProfile?.slot ?? ContentCatalog.shared.item(stack.catalogID)?.gear?.slot) == slot else { return nil }
            return WearableGearOption(piece: EquippedPiece(stack), source: .overflow(stack.id), count: stack.count)
        }
        let owners: [PartySlot] = [.binder] + state.base.roster.indices.map(PartySlot.member)
        let worn = owners.compactMap { owner -> WearableGearOption? in
            guard owner != wearer, let piece = self.worn(slot, by: owner), piece.frozenSlot == slot else { return nil }
            return WearableGearOption(piece: piece, source: .worn(owner), count: 1)
        }
        let carried = (state.worlds.activeRun?.satchelItems.stacks ?? []).compactMap { stack -> WearableGearOption? in
            guard (stack.gearProfile?.slot ?? ContentCatalog.shared.item(stack.catalogID)?.gear?.slot) == slot else { return nil }
            return WearableGearOption(piece: EquippedPiece(stack), source: .carried(stack.id), count: stack.count)
        }
        return stored + overflow + worn + carried
    }

    /// Compatibility boundary for older callers that specifically mean the Storehouse shelf.
    func wearable(in slot: GearSlot) -> [ItemStack] {
        state.base.inventory.stacks.filter {
            ($0.gearProfile?.slot ?? ContentCatalog.shared.item($0.catalogID)?.gear?.slot) == slot
        }
    }

    /// What wearing this would change, in the units the fight actually uses.
    ///
    /// A tier number only answers "is this better?" if you already know the formula. This answers
    /// it directly: **+4 damage**, or **−2 protection**, or no change at all.
    /// The same question about a piece you don't hold — "what would one of these be worth?"
    func gearDelta(wearing definition: ItemDef, for member: PartyMember) -> Int {
        delta(power: Double(definition.gear?.tier ?? 0), slot: definition.gear?.slot, for: member)
    }

    private func delta(power: Double, slot: GearSlot?, for member: PartyMember) -> Int {
        guard let slot else { return 0 }
        let wornPower = worn(slot, by: member)?.effectivePower ?? 0
        let step = slot == .weapon
            ? Tuning.Encounter.attackPerWeaponTier
            : Tuning.Encounter.defencePerArmorTier
        return Int(((power - wornPower) * Double(step)).rounded())
    }

    /// Whether anything in the Storehouse would be an upgrade — drives the nudge on the Party card
    /// so a better blade doesn't sit in a list going unnoticed.
    func hasUpgradeAvailable(for slot: GearSlot, member: PartyMember) -> Bool {
        wearable(in: slot).contains { gearDelta(wearing: $0, for: member) > 0 }
    }

    // MARK: - The world history

    /// Keep a world so a clear-out never drops it, or stop keeping it. Curated rather than
    /// infinite, which is what Aimee asked for.
    func keepWorld(_ id: InstanceID, kept: Bool) {
        mutate("keep world \(id.rawValue)", flush: true) { state in
            guard let index = state.reality.library.visitedWorlds.firstIndex(where: { $0.id == id })
            else { return }
            state.reality.library.visitedWorlds[index].isKept = kept
        }
    }

    /// Erase one, deliberately. The only way a world leaves the history other than aging out.
    func forgetWorld(_ id: InstanceID) {
        mutate("forget world \(id.rawValue)", flush: true) { state in
            state.reality.library.visitedWorlds.removeAll { $0.id == id }
            TutorialRules.reconcileComparisonPair(in: &state)
        }
    }

    // MARK: - Gear, per person in the roster

    /// **Everybody in the party, in one list** — the Binder first, then everyone at the fire.
    ///
    /// A slot rather than a `PartyMember`, because `PartyMember` is the *combat* vocabulary and
    /// only two people fight today. This is who exists.
    /// **Who is actually in the party** — you, and whoever is walking out with you.
    ///
    /// Aimee, 7 Aug: *"the party menu shows all available companions which is not how it should
    /// function. It should be the active party members."* It was listing the whole fire, which made
    /// the Party screen a second roster and left no screen answering "who am I taking".
    ///
    /// Choosing is the Firepit's job; this is the sheet for the people you chose.
    /// **All of them.** This filtered on `activeCompanion` — which is only the *first* of the
    /// party — so taking three people at the fire showed one on the Party screen and left the other
    /// two with no way to be given gear. Written before the party could hold more than one person,
    /// and it quietly outlived that.
    var partySlots: [PartySlot] { state.base.partyMembers }

    /// Everybody at the fire, in or out. The Firepit's list.
    var everyoneAtTheFire: [PartySlot] {
        state.base.roster.indices.map(PartySlot.member)
    }

    func name(of slot: PartySlot) -> String {
        switch slot {
        case .binder: "You"
        case .member(let index): state.base.roster.indices.contains(index)
            ? state.base.roster[index].name : "—"
        }
    }

    func character(of slot: PartySlot) -> CharacterState {
        switch slot {
        case .binder: state.base.binderCharacter
        case .member(let index): state.base.roster.indices.contains(index)
            ? state.base.roster[index].character : CharacterState()
        }
    }

    func worn(_ gearSlot: GearSlot, by slot: PartySlot) -> EquippedPiece? {
        switch slot {
        case .binder: state.base.binderEquipped[gearSlot]
        case .member(let index): state.base.roster.indices.contains(index)
            ? state.base.roster[index].equipped[gearSlot] : nil
        }
    }

    /// What wearing this would change, for whoever you're looking at.
    func gearDelta(wearing stack: ItemStack, for slot: PartySlot) -> Int {
        gearDelta(wearing: EquippedPiece(stack), for: slot)
    }

    func gearDelta(wearing piece: EquippedPiece, for slot: PartySlot) -> Int {
        guard let gearSlot = piece.frozenSlot else { return 0 }
        let wornPower = worn(gearSlot, by: slot)?.effectivePower ?? 0
        let step = gearSlot == .weapon
            ? Tuning.Encounter.attackPerWeaponTier
            : Tuning.Encounter.defencePerArmorTier
        return Int(((piece.effectivePower - wornPower) * Double(step)).rounded())
    }

    func hasUpgradeAvailable(for gearSlot: GearSlot, slot: PartySlot) -> Bool {
        wearableOptions(in: gearSlot, excluding: slot)
            // The nudge means an unused upgrade is waiting, not that another party member owns
            // something stronger. Worn gear remains visible in the picker for an intentional
            // transfer, but it must not make somebody else's equipment page look unfinished.
            .filter {
                switch $0.source {
                case .stored, .overflow: true
                case .worn, .carried: false
                }
            }
            .contains { gearDelta(wearing: $0.piece, for: slot) > 0 }
    }

    /// Put something on somebody. Takes the piece out of the bin, puts back what it replaces —
    /// the same rule as before, now aimed at anybody in the party.
    func equip(_ stack: ItemStack, on slot: PartySlot) {
        guard let gearSlot = stack.gearProfile?.slot ?? ContentCatalog.shared.item(stack.catalogID)?.gear?.slot else { return }
        mutate("equip \(stack.catalogID.rawValue)", flush: true) { state in
            guard let index = state.base.inventory.stacks.firstIndex(where: { $0.id == stack.id }),
                  let taken = state.base.inventory.stacks[index].removing(1)
            else { return }
            if state.base.inventory.stacks[index].isEmpty {
                state.base.inventory.stacks.remove(at: index)
            }
            let previous = Self.swapIn(EquippedPiece(taken), gearSlot, slot, in: &state)
            if let previous {
                state.base.store(previous.asStack(id: InstanceID(rawValue: state.base.nextItemID())))
            }
        }
    }

    /// Equip from an explicit ownership location. Stale sources are a complete no-op, and a piece
    /// worn by somebody else moves directly rather than briefly pretending to fit on a full shelf.
    @discardableResult
    func equip(_ option: WearableGearOption, on target: PartySlot) -> Bool {
        guard option.canEquipAtHome, let gearSlot = option.piece.frozenSlot,
              Self.isValid(target, in: state)
        else { return false }

        // Resolve and validate the exact physical source before opening the mutation. In
        // particular, an old "Worn by Quill" tile must not move whatever Quill put on afterward.
        switch option.source {
        case .stored(let id):
            guard let stack = state.base.inventory.stacks.first(where: { $0.id == id }),
                  Self.samePhysicalPiece(stack, option.piece),
                  (stack.gearProfile?.slot ?? ContentCatalog.shared.item(stack.catalogID)?.gear?.slot) == gearSlot
            else { return false }
        case .overflow(let id):
            guard let stack = state.base.spillover.first(where: { $0.id == id }),
                  Self.samePhysicalPiece(stack, option.piece),
                  (stack.gearProfile?.slot ?? ContentCatalog.shared.item(stack.catalogID)?.gear?.slot) == gearSlot
            else { return false }
        case .worn(let source):
            guard source != target, Self.isValid(source, in: state),
                  worn(gearSlot, by: source) == option.piece
            else { return false }
        case .carried:
            return false
        }

        mutate("equip owned \(option.piece.catalogID.rawValue)", flush: true) { state in
            switch option.source {
            case .stored(let id):
                guard let index = state.base.inventory.stacks.firstIndex(where: { $0.id == id }),
                      (state.base.inventory.stacks[index].gearProfile?.slot
                       ?? ContentCatalog.shared.item(state.base.inventory.stacks[index].catalogID)?.gear?.slot) == gearSlot,
                      let taken = state.base.inventory.stacks[index].removing(1)
                else { return }
                if state.base.inventory.stacks[index].isEmpty { state.base.inventory.stacks.remove(at: index) }
                if let previous = Self.swapIn(EquippedPiece(taken), gearSlot, target, in: &state) {
                    state.base.store(previous.asStack(id: InstanceID(rawValue: state.base.nextItemID())))
                }
            case .overflow(let id):
                guard let index = state.base.spillover.firstIndex(where: { $0.id == id }),
                      (state.base.spillover[index].gearProfile?.slot
                       ?? ContentCatalog.shared.item(state.base.spillover[index].catalogID)?.gear?.slot) == gearSlot,
                      let taken = state.base.spillover[index].removing(1)
                else { return }
                if state.base.spillover[index].isEmpty { state.base.spillover.remove(at: index) }
                if let previous = Self.swapIn(EquippedPiece(taken), gearSlot, target, in: &state) {
                    state.base.store(previous.asStack(id: InstanceID(rawValue: state.base.nextItemID())))
                }
            case .worn(let source):
                guard source != target,
                      let moving = Self.swapIn(nil, gearSlot, source, in: &state),
                      moving.frozenSlot == gearSlot
                else { return }
                let previous = Self.swapIn(moving, gearSlot, target, in: &state)
                _ = Self.swapIn(previous, gearSlot, source, in: &state)
            case .carried:
                return
            }
        }
        return true
    }

    private static func isValid(_ slot: PartySlot, in state: GameState) -> Bool {
        switch slot {
        case .binder: true
        case .member(let index): state.base.roster.indices.contains(index)
        }
    }

    private static func samePhysicalPiece(_ stack: ItemStack, _ piece: EquippedPiece) -> Bool {
        guard stack.catalogID == piece.catalogID else { return false }
        if let expected = piece.gearProfile?.stableInstanceID {
            return stack.gearProfile?.stableInstanceID == expected
        }
        return stack.upgradeLevel == piece.upgradeLevel && stack.wildGrowth == piece.wildGrowth
    }

    func unequip(_ gearSlot: GearSlot, from slot: PartySlot) {
        mutate("unequip \(gearSlot.rawValue)", flush: true) { state in
            if let removed = Self.swapIn(nil, gearSlot, slot, in: &state) {
                state.base.store(removed.asStack(id: InstanceID(rawValue: state.base.nextItemID())))
            }
        }
    }

    /// Writes a piece into a slot and hands back whatever was there.
    private static func swapIn(_ piece: EquippedPiece?, _ gearSlot: GearSlot,
                               _ slot: PartySlot, in state: inout GameState) -> EquippedPiece? {
        switch slot {
        case .binder:
            let previous = state.base.binderEquipped[gearSlot]
            state.base.binderEquipped[gearSlot] = piece
            return previous
        case .member(let index):
            guard state.base.roster.indices.contains(index) else { return nil }
            let previous = state.base.roster[index].equipped[gearSlot]
            state.base.roster[index].equipped[gearSlot] = piece
            return previous
        }
    }

    /// Somebody's rule list, and where it's written back to.
    func gambits(of slot: PartySlot) -> [GambitRule] {
        switch slot {
        case .binder: state.base.binderGambits
        case .member(let index): state.base.roster.indices.contains(index)
            ? state.base.roster[index].gambits : []
        }
    }

    // MARK: - The party

    func placement(of index: Int) -> RosterPlacement {
        RosterPlacementRules.placement(of: index, in: state)
    }

    func partyTransferPreview(for index: Int) -> PartyTransferPreview? {
        guard state.base.roster.indices.contains(index) else { return nil }
        let source = placement(of: index)
        let person = state.base.roster[index]
        let stations = ContentCatalog.shared.stationsInOrder.filter {
            $0.builtBy == person.traveller && state.base.station($0.id).isUnlocked
        }.map(\.name)
        var before: Int?
        var after: Int?
        var shortfallBefore: Int?
        var shortfallAfter: Int?
        if case .anchoredRealm(let id, _) = source,
           let realm = state.worlds.anchoredRealms.first(where: { $0.id == id }) {
            before = realm.productionContribution
            after = max(0, realm.productionContribution - RosterPlacementRules.contribution(of: index, in: state))
            shortfallBefore = realm.projectedShortfall
            shortfallAfter = max(0, realm.sustainObligation - (after ?? 0))
        }
        return PartyTransferPreview(index: index, name: person.name, source: source,
                                    stationNames: stations, realmProductionBefore: before,
                                    realmProductionAfter: after, realmShortfallBefore: shortfallBefore,
                                    realmShortfallAfter: shortfallAfter)
    }

    /// **Who comes with you.** One atomic transfer: taking removes every realm posting; returning
    /// always means Home. Expected placement rejects a stale confirmation instead of moving the
    /// wrong projection.
    @discardableResult
    func setComing(_ index: Int, _ coming: Bool, expected: RosterPlacement? = nil) -> Bool {
        guard state.base.roster.indices.contains(index),
              expected == nil || placement(of: index) == expected else { return false }
        if coming {
            guard !state.base.activeParty.contains(index), state.base.canTakeAnother else { return false }
        } else {
            guard state.base.activeParty.contains(index) else { return false }
        }
        let name = state.base.roster[index].name
        var committed = false
        mutate(coming ? "take \(name)" : "leave \(name)", flush: true) {
            guard expected == nil || RosterPlacementRules.placement(of: index, in: $0) == expected else { return }
            if coming {
                guard !$0.base.activeParty.contains(index), $0.base.canTakeAnother else { return }
                for realmIndex in $0.worlds.anchoredRealms.indices {
                    $0.worlds.anchoredRealms[realmIndex].assignedCompanions.removeAll { $0 == index }
                }
                $0.base.activeParty.append(index)
            } else {
                guard $0.base.activeParty.contains(index) else { return }
                $0.base.activeParty.removeAll { $0 == index }
                for realmIndex in $0.worlds.anchoredRealms.indices {
                    $0.worlds.anchoredRealms[realmIndex].assignedCompanions.removeAll { $0 == index }
                }
            }
            RosterPlacementRules.recalculateRealmProduction(in: &$0)
            committed = true
        }
        return committed
    }

    func isComing(_ index: Int) -> Bool { state.base.activeParty.contains(index) }

    /// What unlearning everything would cost this person, and whether you can afford it.
    func respecCost(for member: PartyMember) -> Int {
        CombatTreeRules.respecCost(for: state.base.character(member))
    }

    func canRespec(_ member: PartyMember) -> Bool {
        let cost = respecCost(for: member)
        return activeEncounter == nil && cost > 0 && state.base.essence >= cost
    }

    /// **The Spring takes it back.** Every point returns and can be spent again.
    func respec(_ member: PartyMember) {
        guard canRespec(member) else { return }
        let cost = respecCost(for: member)
        mutate("respec \(name(of: member))", flush: true) { state in
            state.base.essence -= cost
            state.base.withCharacter(member) { CombatTreeRules.forget(&$0) }
        }
    }

    /// **Spend a point.** Bought in order within a branch, one at a time, and never mid-fight —
    /// the same rule gambits follow, and for the same reason: a build is a decision you make about
    /// the next fight, not during this one.
    func spendPoint(in branch: CombatBranchID, for member: PartyMember) {
        guard activeEncounter == nil,
              let definition = ContentCatalog.shared.combatBranch(branch) else { return }
        mutate("learn in \(definition.name)", flush: true) { state in
            state.base.withCharacter(member) {
                CombatTreeRules.buyNext(in: definition, for: &$0)
            }
        }
    }

    /// Everybody who is walking out with you, you included.
    var partyMembers: [PartyMember] { state.base.partyMembers }

    /// Front or back. **Set on the character's own page**, never mid-fight — the same rule gambits
    /// follow, and the same place everything else about them lives.
    func setRank(_ rank: Rank, of slot: PartySlot) {
        guard activeEncounter == nil else { return }
        mutate("rank", flush: true) { state in
            switch slot {
            case .binder:
                state.base.binderCharacter.rank = rank
            case .member(let index):
                guard state.base.roster.indices.contains(index) else { return }
                state.base.roster[index].character.rank = rank
            }
        }
    }

    // MARK: - Building sites

    /// **Buildings you could raise, because you've met the person who'd run them** (Aimee, 6 Aug).
    ///
    /// A forge isn't bought off a list — it's a smith you found out in a world and brought home.
    /// Which hangs the crafting buildings off the search loop that already exists: write a world
    /// matching Halloway's signature, meet Halloway, and the building site appears here.
    var buildableStations: [StationDef] {
        ContentCatalog.shared.stationsInOrder.filter { station in
            guard !state.base.station(station.id).isUnlocked, let person = station.builtBy
            else { return false }
            return state.reality.library.foundTravellers.contains(person)
        }
    }

    /// Buildings whose person is still out there. Not shown as sites — you don't know they're
    /// possible yet — but the Library lists who you're missing.
    func canAfford(_ station: StationDef) -> Bool {
        guard let cost = station.buildCost else { return true }
        return EconomyRules.canAfford(cost, in: state)
    }

    func shortfall(for station: StationDef) -> [String] {
        guard let cost = station.buildCost else { return [] }
        return EconomyRules.shortfall(cost, in: state)
    }

    /// Raise the building. One-way, and cheap to describe: it costs what it says and then it's there.
    @discardableResult
    func build(_ station: StationDef) -> Bool {
        guard buildableStations.contains(where: { $0.id == station.id }), canAfford(station)
        else { return false }
        let runway = StationRunwayRules.preview(for: station, in: state)
        mutate("build \(station.id.rawValue) [\(runway.telemetryLabel)]", flush: true) { state in
            if let cost = station.buildCost { EconomyRules.pay(cost, in: &state) }
            state.base.stations[station.id] = StationState(isUnlocked: true,
                                                           tier: station.startingTier)
            if station.id == Stations.tannery {
                // A completed building must have an immediate verb. Wear is Corrin's free root;
                // the later fit, Carry and Keep capabilities remain authored research choices.
                state.base.completedResearch.insert(PhysicalGearCraftingRules.tanneryWearRoot)
            }
            if station.id == Stations.weaponsmith {
                state.base.completedResearch.insert(PhysicalGearCraftingRules.weaponsmithPointRoot)
            }
            if station.id == Stations.channelworks {
                let restored = DistilledCore(attunement: .heat, potency: 40,
                                             sampleKind: "authored fixture",
                                             sampleSource: "Oda's damaged conduit",
                                             sampleQualifier: "intact, non-recoverable core",
                                             catalystID: nil, catalystCount: 0,
                                             recipeVersion: 0, stationID: Stations.channelworks)
                state.base.store(ItemStack(id: InstanceID(rawValue: state.base.nextItemID()),
                                           catalogID: Items.conduitFixture,
                                           distilledCore: restored))
            }
        }
        return true
    }

    // MARK: - The Blacksmith

    /// How much stock is on the shelf at all, for the header — a hoard's worth in one number.
    var materialSampleCount: Int {
        state.base.inventory.stacks.reduce(0) { $0 + $1.materials.count }
    }

    func physicalGearReadiness(_ recipe: PhysicalGearCraftingRules.Recipe)
        -> PhysicalGearCraftingRules.Readiness {
        PhysicalGearCraftingRules.readiness(recipe, in: state)
    }

    @discardableResult
    func craftPhysicalGear(_ preview: PhysicalGearCraftingRules.Preview) -> Bool {
        var output: ItemStack?
        mutate("craft \(preview.recipe.id)", flush: true) { state in
            output = PhysicalGearCraftingRules.craft(preview, in: &state)
        }
        return output != nil
    }

    @discardableResult
    func rebuildArmoury(_ preview: ArmouryRules.Preview, allowLegacyLoss: Bool) -> Bool {
        var succeeded = false
        mutate("armoury rebuild \(preview.target.id)", flush: true) { state in
            succeeded = ArmouryRules.rebuild(preview, allowLegacyLoss: allowLegacyLoss, in: &state)
        }
        return succeeded
    }

    /// **Everything the smith could work on**, worn pieces included.
    ///
    /// A piece being on somebody is the *most* likely reason to want it reforged, so equipped gear
    /// is listed alongside stored gear rather than having to be taken off first. Worn pieces are
    /// presented as the single-instance stacks they'd be if you took them off, which is exactly
    /// what `reforge` puts back.
    var reforgeable: [ReforgeTarget] {
        var targets: [ReforgeTarget] = []
        for member in ([.binder] + state.base.roster.indices.map(PartyMember.member)) {
            for slot in GearSlot.allCases {
                if let piece = state.base.worn(slot, by: member) {
                    targets.append(.worn(slot: slot, member: member, piece: piece))
                }
            }
        }
        targets += state.base.inventory.stacks
            .filter { ContentCatalog.shared.item($0.catalogID)?.gear != nil }
            .map { ReforgeTarget.stored($0) }
        targets += state.base.spillover
            .filter { ContentCatalog.shared.item($0.catalogID)?.gear != nil }
            .map { ReforgeTarget.overflow($0) }
        return targets.sorted { $0.effectiveTier > $1.effectiveTier }
    }

    func readiness(of target: ReforgeTarget) -> SmithRules.Readiness {
        SmithRules.readiness(for: target.catalogID, at: target.upgradeLevel, in: state)
    }

    /// Spend stock and essence to push a piece one tier further.
    @discardableResult
    func reforge(_ target: ReforgeTarget) -> Bool {
        var succeeded = false
        mutate("reforge \(target.catalogID.rawValue)", flush: true) { state in
            switch target {
            case .stored(let stack):
                succeeded = SmithRules.reforge(stored: stack, in: &state) != nil
            case .overflow(let stack):
                succeeded = SmithRules.reforge(overflow: stack, in: &state) != nil
            case .worn(let slot, let member, _):
                succeeded = SmithRules.reforge(worn: slot, on: member, in: &state)
            }
        }
        return succeeded
    }

}
