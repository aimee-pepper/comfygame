import Foundation

/// Spending: refining, buying, identifying, and what a cache pays out.
///
/// One principle runs through it — **a rank is never stored twice.** Every upgrade maps to exactly
/// one piece of existing state (a station tier, a satchel tier, a gear tier), and its current rank
/// is read back out of that state. There is no ledger of purchases to drift out of sync with what
/// the player actually has.
enum EconomyRules {

    // MARK: Refining

    struct RefinementReceipt: Equatable, Sendable {
        var rawSpent: Int
        var essenceGained: Int
        var rate: Int
    }

    static let secondPassNode: ResearchNodeID = "essence_second_pass"
    static let continuousSettlingNode: ResearchNodeID = "essence_continuous_settling"
    static var secondPassPracticeRequired: Int {
        ContentCatalog.shared.researchNode(secondPassNode)?.needsLifetimeRawRefined ?? 50
    }

    /// Legacy/opening projection retained for callers without campaign state.
    static func refine(rawUnits: Int) -> Int {
        max(0, rawUnits) * Tuning.Economy.essencePerRawEssence
    }

    static func refinementRate(in state: GameState) -> Int {
        state.base.completedResearch.contains(secondPassNode)
            ? Tuning.Economy.secondPassEssencePerRawEssence
            : Tuning.Economy.essencePerRawEssence
    }

    static func refine(rawUnits: Int, in state: GameState) -> Int {
        max(0, rawUnits) * refinementRate(in: state)
    }

    /// One rules-owned transaction used by manual and outcome-driven conversion.
    @discardableResult
    static func commitRefinement(rawUnits: Int, in state: inout GameState) -> RefinementReceipt? {
        let available = state.base.resources[Resources.essenceRaw]
        guard rawUnits > 0, rawUnits <= available else { return nil }
        let amount = rawUnits
        let rate = refinementRate(in: state)
        let gained = amount * rate
        state.base.resources.spend(amount, of: Resources.essenceRaw)
        state.base.essence += gained
        state.base.lifetimeRawEssenceRefined += amount
        return RefinementReceipt(rawSpent: amount, essenceGained: gained, rate: rate)
    }

    /// Processes only the Raw retained by this outcome; older stored Raw is never swept in.
    @discardableResult
    static func commitContinuousSettling(rawUnits: Int, outcomeID: ExpeditionOutcomeID,
                                         in state: inout GameState) -> RefinementReceipt? {
        guard state.base.completedResearch.contains(continuousSettlingNode),
              state.base.autoRefineReturnedRawEssence,
              state.base.station(Stations.essenceSpring).tier >= 1,
              state.base.lastAutoRefinedOutcomeID != outcomeID else { return nil }
        guard rawUnits >= 0, rawUnits <= state.base.resources[Resources.essenceRaw] else { return nil }
        state.base.lastAutoRefinedOutcomeID = outcomeID
        guard rawUnits > 0 else { return nil }
        return commitRefinement(rawUnits: rawUnits, in: &state)
    }

    /// **The cheapest book that can possibly be written: an empty page.**
    ///
    /// Nothing may ever cost less than this, which makes it the floor the base has to keep you
    /// above — see `GameStore.ensureDepartureIsPossible`.
    ///
    /// It used to price *the old slot taxonomy* — one flat chance-charge per slot you owned
    /// anything for — which stopped being what a book costs the moment the page grid replaced
    /// slots. The floor the base guaranteed you was the price of a book nobody can write, and it
    /// happened to be higher than the real one, so the guard was generous by accident rather than
    /// by design. A blank page costs the base rate and no ink, because there are no marks on it.
    static func minimumBindCost(in state: GameState) -> Int {
        BookRules.bindCost(chosenSymbolIDs: [], randomSlots: 0)
    }

    /// Everything the player could turn into essence right now without leaving the base.
    static func spendableEssence(in state: GameState) -> Int {
        state.base.essence + refine(rawUnits: state.base.resources[Resources.essenceRaw], in: state)
    }

    // MARK: Research

    /// Whether a node's prerequisites are all met. Locked nodes are shown, not hidden — seeing what
    /// you can't have yet is most of what makes a tree feel like a tree.
    static func isAvailable(_ node: ResearchNodeDef, in state: GameState) -> Bool {
        !isComplete(node, in: state)
            && !stationTierAlreadySupplied(by: node, in: state)
            && node.requires.allSatisfy { prerequisiteSatisfied($0, in: state) }
            && buildingAllows(node, in: state) == nil
            && kitAllows(node, in: state) == nil
            && practiceAllows(node, in: state) == nil
    }

    /// **Whether you have measured enough to be worth predicting with** (`crafting-spec.md` PART TWO).
    ///
    /// The page lens is bought with field readings: each tier of it asks for more instruments than
    /// the last, so prediction is earned by having gone out and taken the measurements rather than
    /// by paying for it at home. Returns the reason it's blocked, or nil.
    static func kitAllows(_ node: ResearchNodeDef, in state: GameState) -> String? {
        let measured = state.reality.observations.count
        guard node.needsInstruments > measured else { return nil }
        let short = node.needsInstruments - measured
        return "\(short) more field reading\(short == 1 ? "" : "s") to grind it against"
    }

    static func practiceAllows(_ node: ResearchNodeDef, in state: GameState) -> String? {
        let missing = max(0, node.needsLifetimeRawRefined - state.base.lifetimeRawEssenceRefined)
        return missing == 0 ? nil : "refine \(missing) more Raw Essence first"
    }

    /// **Whether the building that teaches this is built, and built far enough** (Q40).
    ///
    /// Returns the reason it's blocked, or nil if it isn't — because a greyed-out row that doesn't
    /// say *"the Scriptorium isn't built"* is indistinguishable from a bug.
    ///
    /// A branch's first `freeRungs` nodes stay reachable without the building, so finding somebody
    /// accelerates rather than unblocks. Penmanship sets that to **zero**, deliberately: the hands
    /// are what the game is about, and meeting the Calligrapher is a story beat that happens to be
    /// a gate (`hands-and-calligrapher-spec.md` §3).
    static func buildingAllows(_ node: ResearchNodeDef, in state: GameState) -> String? {
        guard let branch = ContentCatalog.shared.researchBranch(node.branch),
              let stationID = branch.station,
              let station = ContentCatalog.shared.station(stationID)
        else { return nil }

        let depth = depthOf(node)
        if depth < branch.freeRungs, node.needsStationTier == 0 { return nil }

        let built = state.base.station(stationID)
        guard built.isUnlocked else {
            // Named by the person rather than the building where there is one — you're looking for
            // somebody, not shopping for premises.
            let who = station.builtBy.flatMap { ContentCatalog.shared.traveller($0)?.name }
            return who.map { "\($0) hasn't been found" } ?? "the \(station.name) isn't built"
        }
        if StationStaffingRules.effectiveTier(for: station, in: state) < node.needsStationTier {
            return "the \(station.name) needs upgrading"
        }
        return nil
    }

    /// How far down its branch a node sits, counted through `requires`. Cheap because branches are
    /// tens of nodes, not thousands.
    static func depthOf(_ node: ResearchNodeDef, seen: Set<ResearchNodeID> = []) -> Int {
        guard !node.requires.isEmpty, !seen.contains(node.id) else { return 0 }
        var visited = seen
        visited.insert(node.id)
        return 1 + (node.requires
            .compactMap { ContentCatalog.shared.researchNode($0) }
            .map { depthOf($0, seen: visited) }
            .max() ?? 0)
    }

    static func isComplete(_ node: ResearchNodeDef, in state: GameState) -> Bool {
        state.base.completedResearch.contains(node.id)
    }

    /// The prerequisites still missing, by name, so the UI can say what's blocking rather than just
    /// greying a row out.
    static func missingPrerequisites(_ node: ResearchNodeDef, in state: GameState) -> [String] {
        var missing = node.requires
            .filter { !prerequisiteSatisfied($0, in: state) }
            .compactMap { ContentCatalog.shared.researchNode($0)?.name }
        if let blocked = buildingAllows(node, in: state) { missing.append(blocked) }
        if let unmeasured = kitAllows(node, in: state) { missing.append(unmeasured) }
        if let practice = practiceAllows(node, in: state) { missing.append(practice) }
        return missing
    }

    static func prerequisiteSatisfied(_ id: ResearchNodeID, in state: GameState) -> Bool {
        if state.base.completedResearch.contains(id) { return true }
        guard let node = ContentCatalog.shared.researchNode(id) else { return false }
        return stationTierAlreadySupplied(by: node, in: state)
    }

    static func stationTierAlreadySupplied(by node: ResearchNodeDef, in state: GameState) -> Bool {
        guard let grant = node.grants.first(where: { $0.effect == .stationTier }),
              let id = grant.id, let target = grant.tier,
              let station = ContentCatalog.shared.station(StationID(rawValue: id)) else { return false }
        return StationStaffingRules.effectiveTier(for: station, in: state) >= target
    }

    static func canAfford(_ cost: UpgradeCost, in state: GameState) -> Bool {
        guard state.base.essence >= cost.essence else { return false }
        return cost.resources.allSatisfy { state.base.resources[$0.key] >= $0.value }
    }

    static func paidCost(for node: ResearchNodeDef, in state: GameState) -> UpgradeCost {
        guard let branch = ContentCatalog.shared.researchBranch(node.branch),
              let stationID = branch.station,
              let station = ContentCatalog.shared.station(stationID)
        else { return node.cost }
        return UpgradeCost(
            essence: StationStaffingRules.discounted(node.cost.essence, at: station, in: state),
            resources: node.cost.resources.mapValues {
                StationStaffingRules.discounted($0, at: station, in: state)
            })
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

        case .focus:
            if let id = grant.id { state.base.ownedSources.insert(PressureSourceID(rawValue: id)) }

        case .instrument:
            // **Reality, like the lens it feeds.** What an instrument buys you is the ability to
            // read one subject, and a reading is knowledge.
            if let id = grant.id {
                let target = PressureTargetID(rawValue: id)
                state.reality.instruments.insert(target)
                state.reality.instrumentPrecisions[target] = .crude
                // A newly made tool is useful immediately; the player can leave it home later.
                state.base.instrumentLoadout.insert(target)
            }

        case .capability:
            // The completed research node is the durable capability flag. Do not mirror it into
            // another save field that could drift out of sync.
            break

        case .effect:
            guard let effect = grant.effect else { return }
            switch effect {
            case .storehouseTier:
                bumpStation(Stations.storehouse, in: &state)
                // Capacity is stored on the inventory, so it has to follow the tier.
                state.base.syncInventoryCapacity()
            case .analysisTier:
                // **Reality, not Base.** A reading is knowledge, and knowledge is never taken back —
                // the same reason visited seeds and the Library live there.
                state.reality.analysisTier = min(Tuning.Analysis.livingTier,
                                                 state.reality.analysisTier + 1)
            case .satchelTier:
                state.base.satchelTier += 1
            case .gambitSlot:
                state.base.purchasedGambitSlots += 1
            case .essenceSpringTier:
                bumpStation(Stations.essenceSpring, in: &state)
            case .scriptoriumTier:
                bumpStation(Stations.scriptorium, in: &state)
            case .stationTier:
                if let id = grant.id, let target = grant.tier {
                    let stationID = StationID(rawValue: id)
                    var station = state.base.station(stationID)
                    station.tier = max(station.tier, target)
                    state.base.stations[stationID] = station
                }
            case .automateSelf:
                state.base.hasAutomateSelfUnlock = true
            case .companionWeapon, .companionArmor:
                // Retired: party modification through research was never how this works
                // (decisions-session-12 §3). Kept as a case so old saves still decode.
                break
            case .chaining:
                state.base.hasChainingUnlock = true
            case .finerHand:
                // Next hand up, in order. Owning a finer one never removes the coarser.
                if let next = Hand.allCases.first(where: { !state.base.ownedHands.contains($0) }) {
                    state.base.ownedHands.insert(next)
                }
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
        /// **A word for the page.** The repeatable route into the vocabulary — sites teach specific
        /// focuses and the Workshop sells a few, but neither is enough on its own to guarantee that
        /// every word in the catalogue can eventually be had, and a word you can never learn is
        /// worse than one you were given.
        case focus(PressureSourceID)
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

        let unownedFocuses = ContentCatalog.shared.pressureSources
            .filter { $0.acquisition == .worldDrop && !state.base.ownedSources.contains($0.id) }
            .map(\.id)
            .sorted { $0.rawValue < $1.rawValue }

        var options: [(value: CacheReward, weight: Double)] = [
            (.motes(rng.int(in: Tuning.Economy.cacheMoteRange)), Tuning.Economy.cacheMoteWeight)
        ]
        if let focus = rng.pick(unownedFocuses) {
            options.append((.focus(focus), Tuning.Economy.cacheFocusWeight))
        }
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
        case .focus(let id): state.base.ownedSources.insert(id)
        case .gambitComponent(let id): state.base.ownedGambitComponents.insert(id)
        case .motes(let amount): state.reality.motes += amount
        }
    }

    static func describe(_ reward: CacheReward) -> String {
        switch reward {
        case .symbol(let id):
            "A symbol you've never written: \(ContentCatalog.shared.symbol(id)?.name ?? id.rawValue)."
        case .focus(let id):
            "A word you didn't have: \(ContentCatalog.shared.pressureSource(id)?.name ?? id.rawValue)."
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
