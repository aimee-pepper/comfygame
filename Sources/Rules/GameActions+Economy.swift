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

    func rank(of upgrade: UpgradeDef) -> Int { EconomyRules.rank(of: upgrade, in: state) }
    func nextCost(of upgrade: UpgradeDef) -> UpgradeCost? { EconomyRules.nextCost(of: upgrade, in: state) }

    func canBuy(_ upgrade: UpgradeDef) -> Bool {
        guard let cost = nextCost(of: upgrade) else { return false }
        return EconomyRules.canAfford(cost, in: state)
    }

    func shortfall(for upgrade: UpgradeDef) -> [String] {
        guard let cost = nextCost(of: upgrade) else { return [] }
        return EconomyRules.shortfall(cost, in: state)
    }

    @discardableResult
    func buy(_ upgrade: UpgradeDef) -> Bool {
        guard let cost = nextCost(of: upgrade), EconomyRules.canAfford(cost, in: state) else { return false }
        mutate("buy \(upgrade.id.rawValue)", flush: true) { state in
            EconomyRules.pay(cost, in: &state)
            EconomyRules.apply(upgrade, in: &state)
        }
        return true
    }

    /// Research a symbol you don't own yet.
    @discardableResult
    func research(_ symbol: SymbolDef) -> Bool {
        guard !state.base.ownedSymbols.contains(symbol.id), state.base.essence >= symbol.essenceCost
        else { return false }
        mutate("research \(symbol.id.rawValue)", flush: true) { state in
            state.base.essence -= symbol.essenceCost
            state.base.ownedSymbols.insert(symbol.id)
        }
        return true
    }

    /// Buy a gambit piece you don't own yet. Owning it is separate from slotting it — the Party
    /// screen decides which rules are actually running.
    @discardableResult
    func buy(_ piece: GambitPieceDef) -> Bool {
        guard !state.base.ownedGambitPieces.contains(piece.id), state.base.essence >= piece.essenceCost
        else { return false }
        mutate("buy \(piece.id.rawValue)", flush: true) { state in
            state.base.essence -= piece.essenceCost
            state.base.ownedGambitPieces.append(piece.id)
        }
        return true
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
