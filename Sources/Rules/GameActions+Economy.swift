import Foundation

/// Spending actions: the Workshop, the Storehouse, the Constellation, and opening a cache.
extension GameStore {

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
            state.base.essence += max(0, shortfall)
        }
    }

    /// True when the only thing standing between the player and a world is a trip to the Refinery.
    var needsToRefine: Bool {
        state.base.essence < EconomyRules.minimumBindCost(in: state)
            && state.base.resources[Resources.essenceRaw] > 0
    }

    // MARK: Research

    func isComplete(_ node: ResearchNodeDef) -> Bool { EconomyRules.isComplete(node, in: state) }
    func isAvailable(_ node: ResearchNodeDef) -> Bool { EconomyRules.isAvailable(node, in: state) }
    func missingPrerequisites(for node: ResearchNodeDef) -> [String] {
        EconomyRules.missingPrerequisites(node, in: state)
    }
    func shortfall(for node: ResearchNodeDef) -> [String] { EconomyRules.shortfall(node.cost, in: state) }

    func canResearch(_ node: ResearchNodeDef) -> Bool {
        EconomyRules.isAvailable(node, in: state) && EconomyRules.canAfford(node.cost, in: state)
    }

    /// Complete a research node. Everything buyable in the game goes through here — there is no
    /// flat shopping list, only branches with prerequisites.
    @discardableResult
    func research(_ node: ResearchNodeDef) -> Bool {
        guard canResearch(node) else { return false }
        mutate("research \(node.id.rawValue)", flush: true) { state in
            EconomyRules.pay(node.cost, in: &state)
            EconomyRules.complete(node, in: &state)
        }
        return true
    }

    /// How far along a branch is, for the Workshop's summary line.
    func progress(in branch: ResearchBranchDef) -> (done: Int, total: Int) {
        let nodes = ContentCatalog.shared.nodes(in: branch.id)
        return (nodes.count { isComplete($0) }, nodes.count)
    }

    /// How many nodes in a branch you could buy **right now** — so the branch list can say which
    /// ones are worth opening without you having to open all of them to find out.
    func availableCount(in branch: ResearchBranchDef) -> Int {
        ContentCatalog.shared.nodes(in: branch.id).count {
            !isComplete($0) && isAvailable($0) && shortfall(for: $0).isEmpty
        }
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

    /// Constellation nodes are the Reality layer's only spend — permanent, and the one thing a
    /// future base reset won't take back.
    @discardableResult
    func buy(_ node: ConstellationNodeDef) -> Bool {
        guard let cost = moteCost(of: node), state.reality.motes >= cost else { return false }
        mutate("constellation: \(node.id.rawValue)", flush: true) { state in
            state.reality.motes -= cost
            state.reality.constellation[node.id, default: 0] += 1
        }
        return true
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
        mutate("open locked cache", flush: true) { state in
            guard var run = state.worlds.activeRun else { return }
            let rolled = EconomyRules.rollCacheReward(in: state, rng: &run.rng)
            run.map[run.playerPosition].content = .empty
            state.worlds.activeRun = run

            EconomyRules.grant(rolled, in: &state)
            state.base.inventory.remove(key.id) // the key is spent
            reward = rolled
        }
        if let reward {
            recentEvents = [.cacheOpened(EconomyRules.describe(reward))]
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

    /// What's in the Storehouse that could be worn in a given slot.
    func wearable(in slot: GearSlot) -> [ItemStack] {
        state.base.inventory.stacks.filter {
            ContentCatalog.shared.item($0.catalogID)?.gear?.slot == slot
        }
    }

    /// What wearing this would change, in the units the fight actually uses.
    ///
    /// A tier number only answers "is this better?" if you already know the formula. This answers
    /// it directly: **+4 damage**, or **−2 protection**, or no change at all.
    func gearDelta(wearing candidate: ItemDef) -> Int {
        guard let gear = candidate.gear else { return 0 }
        let wornTier = state.base.companion.equipped[gear.slot]
            .flatMap { ContentCatalog.shared.item($0)?.gear?.tier } ?? 0
        let step = gear.slot == .weapon
            ? Tuning.Encounter.attackPerWeaponTier
            : Tuning.Encounter.defencePerArmorTier
        return (gear.tier - wornTier) * step
    }

    /// Whether anything in the Storehouse would be an upgrade — drives the nudge on the Party card
    /// so a better blade doesn't sit in a list going unnoticed.
    func hasUpgradeAvailable(for slot: GearSlot) -> Bool {
        wearable(in: slot).contains { stack in
            guard let item = ContentCatalog.shared.item(stack.catalogID) else { return false }
            return gearDelta(wearing: item) > 0
        }
    }

    /// Put something on. The piece it replaces goes back to the Storehouse rather than vanishing.
    func equip(_ stack: ItemStack) {
        guard let slot = ContentCatalog.shared.item(stack.catalogID)?.gear?.slot else { return }
        mutate("equip \(stack.catalogID.rawValue)", flush: true) { state in
            state.base.companion.equipped[slot] = stack.catalogID
        }
    }

    func unequip(_ slot: GearSlot) {
        mutate("unequip \(slot.rawValue)", flush: true) { state in
            state.base.companion.equipped[slot] = nil
        }
    }
}
