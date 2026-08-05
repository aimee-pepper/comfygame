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
            state.base.inventory.stacks[index].catalogID = revealed.id
            state.base.inventory.stacks[index].identified = true
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
}
