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

    // MARK: Upgrades

    /// How many times this upgrade has been bought, derived from the state it changes.
    static func rank(of upgrade: UpgradeDef, in state: GameState) -> Int {
        switch upgrade.effect {
        case .storehouseTier: state.base.station(Stations.storehouse).tier
        case .satchelTier: state.base.satchelTier
        case .gambitSlot: state.base.purchasedGambitSlots
        case .essenceSpringTier: state.base.station(Stations.essenceSpring).tier
        case .automateSelf: state.base.hasAutomateSelfUnlock ? 1 : 0
        case .companionWeapon: state.base.companion.weaponTier
        case .companionArmor: state.base.companion.armorTier
        }
    }

    /// What the next rank costs, or `nil` if it's fully bought.
    static func nextCost(of upgrade: UpgradeDef, in state: GameState) -> UpgradeCost? {
        let current = rank(of: upgrade, in: state)
        guard current < upgrade.ranks.count else { return nil }
        return upgrade.ranks[current]
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

    /// Applies one rank of an upgrade. Assumes it's been paid for.
    static func apply(_ upgrade: UpgradeDef, in state: inout GameState) {
        switch upgrade.effect {
        case .storehouseTier:
            var station = state.base.station(Stations.storehouse)
            station.tier += 1
            state.base.stations[Stations.storehouse] = station
            // Capacity is stored on the inventory, so it has to be re-synced when the tier moves.
            state.base.syncInventoryCapacity()

        case .satchelTier:
            state.base.satchelTier += 1

        case .gambitSlot:
            state.base.purchasedGambitSlots += 1

        case .essenceSpringTier:
            var station = state.base.station(Stations.essenceSpring)
            station.tier += 1
            state.base.stations[Stations.essenceSpring] = station

        case .automateSelf:
            state.base.hasAutomateSelfUnlock = true

        case .companionWeapon:
            state.base.companion.weaponTier += 1

        case .companionArmor:
            state.base.companion.armorTier += 1
        }
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
        case gambitPiece(GambitPieceID)
        case motes(Int)
    }

    static func rollCacheReward(in state: GameState, rng: inout SeededRNG) -> CacheReward {
        let unownedSymbols = ContentCatalog.shared.symbols
            .filter { !state.base.ownedSymbols.contains($0.id) }
            .map(\.id)
            .sorted { $0.rawValue < $1.rawValue }
        let unownedPieces = ContentCatalog.shared.gambitPieces
            .filter { !state.base.ownedGambitPieces.contains($0.id) }
            .map(\.id)
            .sorted { $0.rawValue < $1.rawValue }

        var options: [(value: CacheReward, weight: Double)] = [
            (.motes(rng.int(in: Tuning.Economy.cacheMoteRange)), Tuning.Economy.cacheMoteWeight)
        ]
        if let symbol = rng.pick(unownedSymbols) {
            options.append((.symbol(symbol), Tuning.Economy.cacheSymbolWeight))
        }
        if let piece = rng.pick(unownedPieces) {
            options.append((.gambitPiece(piece), Tuning.Economy.cacheGambitWeight))
        }
        return rng.pickWeighted(options) ?? .motes(Tuning.Economy.cacheMoteRange.lowerBound)
    }

    static func grant(_ reward: CacheReward, in state: inout GameState) {
        switch reward {
        case .symbol(let id): state.base.ownedSymbols.insert(id)
        case .gambitPiece(let id):
            if !state.base.ownedGambitPieces.contains(id) { state.base.ownedGambitPieces.append(id) }
        case .motes(let amount): state.reality.motes += amount
        }
    }

    static func describe(_ reward: CacheReward) -> String {
        switch reward {
        case .symbol(let id):
            "A symbol you've never written: \(ContentCatalog.shared.symbol(id)?.name ?? id.rawValue)."
        case .gambitPiece(let id):
            "A rule you didn't have: \(ContentCatalog.shared.gambitPiece(id)?.name ?? id.rawValue)."
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
