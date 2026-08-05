import Foundation

/// Spending: refining, buying, identifying, and what a cache pays out.
///
/// One principle runs through it — **a rank is never stored twice.** Every upgrade maps to exactly
/// one piece of existing state (a station tier, a satchel tier, a gear tier), and its current rank
/// is read back out of that state. There is no ledger of purchases to drift out of sync with what
/// the player actually has.
enum EconomyRules {

    // MARK: Refining

    /// Raw essence is what worlds give you; essence is what the base runs on. The Workshop is where
    /// one becomes the other (design brief), and it's the join between harvesting and spending.
    static func refine(rawUnits: Int) -> Int {
        max(0, rawUnits) * Tuning.Economy.essencePerRawEssence
    }

    // MARK: Research

    /// Whether a node's prerequisites are all met. Locked nodes are shown, not hidden — seeing what
    /// you can't have yet is most of what makes a tree feel like a tree.
    static func isAvailable(_ node: ResearchNodeDef, in state: GameState) -> Bool {
        !isComplete(node, in: state) && node.requires.allSatisfy { state.base.completedResearch.contains($0) }
    }

    static func isComplete(_ node: ResearchNodeDef, in state: GameState) -> Bool {
        state.base.completedResearch.contains(node.id)
    }

    /// The prerequisites still missing, by name, so the UI can say what's blocking rather than just
    /// greying a row out.
    static func missingPrerequisites(_ node: ResearchNodeDef, in state: GameState) -> [String] {
        node.requires
            .filter { !state.base.completedResearch.contains($0) }
            .compactMap { ContentCatalog.shared.researchNode($0)?.name }
    }

    static func canAfford(_ cost: UpgradeCost, in state: GameState) -> Bool {
        guard state.base.essence >= cost.essence else { return false }
        return cost.resources.allSatisfy { state.base.resources[$0.key] >= $0.value }
    }

    /// What you're short of, for the UI to say so plainly instead of just greying a button out.
    static func shortfall(_ cost: UpgradeCost, in state: GameState) -> [String] {
        var missing: [String] = []
        if state.base.essence < cost.essence {
            missing.append("\(cost.essence - state.base.essence) essence")
        }
        for (id, amount) in cost.resources.sorted(by: { $0.key.rawValue < $1.key.rawValue })
        where state.base.resources[id] < amount {
            let name = ContentCatalog.shared.resource(id)?.name.lowercased() ?? id.rawValue
            missing.append("\(amount - state.base.resources[id]) \(name)")
        }
        return missing
    }

    static func pay(_ cost: UpgradeCost, in state: inout GameState) {
        state.base.essence -= cost.essence
        for (id, amount) in cost.resources {
            state.base.resources.spend(amount, of: id)
        }
    }

    /// Completes a node and hands over everything it grants. Assumes it's been paid for.
    static func complete(_ node: ResearchNodeDef, in state: inout GameState) {
        state.base.completedResearch.insert(node.id)
        for grant in node.grants { apply(grant, in: &state) }
    }

    static func apply(_ grant: ResearchGrant, in state: inout GameState) {
        switch grant.kind {
        case .gambitComponent:
            if let id = grant.id { state.base.ownedGambitComponents.insert(GambitComponentID(rawValue: id)) }

        case .symbol:
            if let id = grant.id { state.base.ownedSymbols.insert(SymbolID(rawValue: id)) }

        case .effect:
            guard let effect = grant.effect else { return }
            switch effect {
            case .storehouseTier:
                bumpStation(Stations.storehouse, in: &state)
                // Capacity is stored on the inventory, so it has to follow the tier.
                state.base.syncInventoryCapacity()
            case .satchelTier:
                state.base.satchelTier += 1
            case .gambitSlot:
                state.base.purchasedGambitSlots += 1
            case .essenceSpringTier:
                bumpStation(Stations.essenceSpring, in: &state)
            case .automateSelf:
                state.base.hasAutomateSelfUnlock = true
            case .companionWeapon:
                state.base.companion.weaponTier += 1
            case .companionArmor:
                state.base.companion.armorTier += 1
            }
        }
    }

    private static func bumpStation(_ id: StationID, in state: inout GameState) {
        var station = state.base.station(id)
        station.tier += 1
        state.base.stations[id] = station
    }

    // MARK: Identifying

    /// What a curio turns out to be. `nil` for anything already known.
    static func identification(of stack: ItemStack) -> ItemDef? {
        guard !stack.identified,
              let curio = ContentCatalog.shared.item(stack.catalogID),
              let target = curio.identifiesInto
        else { return nil }
        return ContentCatalog.shared.item(target)
    }

    // MARK: Locked caches

    /// What opening a cache pays out. Guaranteed Rare+ (design brief): a symbol you don't own, a
    /// gambit piece you don't own, or motes.
    ///
    /// Falls through to motes when there's nothing new to give, so a cache is never a dud — the
    /// whole point of the cache is that it was worth carrying a key across worlds for.
    enum CacheReward: Equatable {
        case symbol(SymbolID)
        case gambitComponent(GambitComponentID)
        case motes(Int)
    }

    static func rollCacheReward(in state: GameState, rng: inout SeededRNG) -> CacheReward {
        let unownedSymbols = ContentCatalog.shared.symbols
            .filter { !state.base.ownedSymbols.contains($0.id) }
            .map(\.id)
            .sorted { $0.rawValue < $1.rawValue }
        // Vocabulary found rather than studied — the wild route into the research tree.
        let unownedComponents = ContentCatalog.shared.gambitComponents
            .filter { !state.base.ownedGambitComponents.contains($0.id) }
            .map(\.id)
            .sorted { $0.rawValue < $1.rawValue }

        var options: [(value: CacheReward, weight: Double)] = [
            (.motes(rng.int(in: Tuning.Economy.cacheMoteRange)), Tuning.Economy.cacheMoteWeight)
        ]
        if let symbol = rng.pick(unownedSymbols) {
            options.append((.symbol(symbol), Tuning.Economy.cacheSymbolWeight))
        }
        if let component = rng.pick(unownedComponents) {
            options.append((.gambitComponent(component), Tuning.Economy.cacheGambitWeight))
        }
        return rng.pickWeighted(options) ?? .motes(Tuning.Economy.cacheMoteRange.lowerBound)
    }

    static func grant(_ reward: CacheReward, in state: inout GameState) {
        switch reward {
        case .symbol(let id): state.base.ownedSymbols.insert(id)
        case .gambitComponent(let id): state.base.ownedGambitComponents.insert(id)
        case .motes(let amount): state.reality.motes += amount
        }
    }

    static func describe(_ reward: CacheReward) -> String {
        switch reward {
        case .symbol(let id):
            "A symbol you've never written: \(ContentCatalog.shared.symbol(id)?.name ?? id.rawValue)."
        case .gambitComponent(let id):
            "A word you didn't have: \(ContentCatalog.shared.gambitComponent(id)?.name ?? id.rawValue)."
        case .motes(let amount):
            amount == 1 ? "A single mote." : "\(amount) motes."
        }
    }

    // MARK: Constellation

    static func moteCost(of node: ConstellationNodeDef, in state: GameState) -> Int? {
        let rank = state.reality.rank(of: node.id)
        guard rank < node.maxRank, rank < node.moteCostPerRank.count else { return nil }
        return node.moteCostPerRank[rank]
    }
}
