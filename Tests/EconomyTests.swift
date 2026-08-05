import XCTest
@testable import Bookbinder

/// Spending: refining, upgrades, identification, the key→cache payoff, and Constellation nodes.
@MainActor
final class EconomyTests: XCTestCase {

    /// The simplest legal rule, for tests that just need the Binder to do *something*.
    private static let attackAnything = GambitRule(id: InstanceID(rawValue: 99),
                                                   subject: "subject_foe_any",
                                                   action: "act_attack")

    private func richStore() -> GameStore {
        let store = GameStore(io: .temporary(name: "economy-\(UUID().uuidString)"))
        store.mutate("stock up for testing") { state in
            state.base.essence = 500
            state.base.resources.add(200, of: Resources.ore)
            state.base.resources.add(200, of: Resources.fiber)
            state.reality.motes = 50
        }
        return store
    }

    private func node(_ id: ResearchNodeID) throws -> ResearchNodeDef {
        try XCTUnwrap(ContentCatalog.shared.researchNode(id))
    }

    /// Complete a node and everything it depends on, so a test can start from a given point in the
    /// tree without hand-listing the path.
    private func researchThrough(_ id: ResearchNodeID, in store: GameStore) throws {
        let target = try node(id)
        for required in target.requires { try researchThrough(required, in: store) }
        XCTAssertTrue(store.research(target), "Couldn't research \(id)")
    }

    // MARK: Refining

    /// Before this existed, ore and fibre had nowhere to go and raw essence did nothing. Refining
    /// is the join between harvesting and spending.
    func testRefiningTurnsRawEssenceIntoEssence() {
        let store = GameStore(io: .temporary(name: "refine-\(UUID().uuidString)"))
        store.mutate("haul") { $0.base.resources.add(6, of: Resources.essenceRaw) }
        let before = store.state.base.essence

        store.refineAllEssence()

        XCTAssertEqual(store.state.base.resources[Resources.essenceRaw], 0)
        XCTAssertEqual(store.state.base.essence, before + 6 * Tuning.Economy.essencePerRawEssence)
    }

    func testRefiningNothingDoesNothing() {
        let store = GameStore(io: .temporary(name: "refine-none-\(UUID().uuidString)"))
        let before = store.state.base.essence
        XCTAssertFalse(store.refineEssence(rawUnits: 5), "You can't refine what you don't have")
        XCTAssertEqual(store.state.base.essence, before)
    }

    // MARK: Research

    func testResearchingANodeSpendsBothCurrenciesAndGrantsItsEffect() throws {
        let store = richStore()
        let shelving = try node("shelving_one")
        let essenceBefore = store.state.base.essence
        let oreBefore = store.state.base.resources[Resources.ore]
        let slotsBefore = store.state.base.inventory.slots

        XCTAssertTrue(store.research(shelving))

        XCTAssertEqual(store.state.base.essence, essenceBefore - shelving.cost.essence)
        XCTAssertEqual(store.state.base.resources[Resources.ore],
                       oreBefore - (shelving.cost.resources[Resources.ore] ?? 0))
        XCTAssertTrue(store.isComplete(shelving))
        XCTAssertEqual(store.state.base.inventory.slots,
                       slotsBefore + Tuning.Economy.inventorySlotsPerStorehouseTier,
                       "Capacity has to follow the tier, not drift from it")
    }

    /// The whole point of a tree rather than a list: you can't buy the end before the beginning.
    func testANodeIsLockedUntilItsPrerequisitesAreDone() throws {
        let store = richStore()
        let deeper = try node("shelving_two")

        XCTAssertFalse(store.isAvailable(deeper))
        XCTAssertFalse(store.research(deeper))
        XCTAssertFalse(store.missingPrerequisites(for: deeper).isEmpty,
                       "The UI has to be able to say what's blocking")

        try researchThrough("shelving_one", in: store)
        XCTAssertTrue(store.isAvailable(deeper))
        XCTAssertTrue(store.research(deeper))
    }

    func testANodeIsOnlyEverResearchedOnce() throws {
        let store = richStore()
        let node = try node("reason_about_self")
        XCTAssertTrue(store.research(node))
        XCTAssertFalse(store.isAvailable(node))
        XCTAssertFalse(store.research(node))
    }

    func testCannotResearchWhatYouCannotAfford() throws {
        let store = GameStore(io: .temporary(name: "poor-\(UUID().uuidString)"))
        store.mutate("broke") { $0.base.essence = 0 }
        let shelving = try node("shelving_one")

        XCTAssertFalse(store.canResearch(shelving))
        XCTAssertFalse(store.research(shelving))
        XCTAssertFalse(store.shortfall(for: shelving).isEmpty)
        XCTAssertFalse(store.isComplete(shelving))
    }

    /// Research grants *components*, not finished rules. Learning one threshold widens everything
    /// you can already say — that's why it's a grammar and not a shop.
    func testResearchGrantsComponentsThatWidenTheGrammar() throws {
        let store = richStore()
        XCTAssertFalse(store.state.base.ownedGambitComponents.contains("thr_30"))

        try researchThrough("notice_thirty", in: store)

        XCTAssertTrue(store.state.base.ownedGambitComponents.contains("thr_30"))
        XCTAssertTrue(store.ownedComponents(.threshold).contains { $0.id == "thr_30" },
                      "The new word is immediately available to the rule builder")
    }

    func testResearchCanGrantASymbol() throws {
        let store = richStore()
        XCTAssertFalse(store.state.base.ownedSymbols.contains("verdigris_bloom"))
        try researchThrough("study_growth", in: store)
        XCTAssertTrue(store.state.base.ownedSymbols.contains("verdigris_bloom"))
    }

    func testResearchingASlotWidensTheRuleList() throws {
        let store = richStore()
        let before = store.activeGambitSlots
        try researchThrough("longer_instruction", in: store)
        XCTAssertEqual(store.activeGambitSlots, before + 1)
    }

    /// Two sources of slots, in two layers — and only one survives a reset. That's the whole point
    /// of having both.
    func testResearchedSlotsAreLostInAResetAndConstellationSlotsAreNot() throws {
        let store = richStore()
        try researchThrough("longer_instruction", in: store)
        let node = try XCTUnwrap(ContentCatalog.shared.constellationNode(ConstellationNodes.extraGambitSlot))
        store.buy(node)
        XCTAssertEqual(store.activeGambitSlots, Tuning.Encounter.startingGambitSlots + 2)

        store.resetBaseKeepingReality()

        XCTAssertEqual(store.activeGambitSlots, Tuning.Encounter.startingGambitSlots + 1,
                       "The researched slot goes, the Constellation slot stays")
    }

    /// A reset should hand back the whole tree, not leave you owning its fruits.
    func testResettingTheBaseClearsResearch() throws {
        let store = richStore()
        try researchThrough("shelving_one", in: store)
        XCTAssertFalse(store.state.base.completedResearch.isEmpty)

        store.resetBaseKeepingReality()
        XCTAssertTrue(store.state.base.completedResearch.isEmpty)
        XCTAssertEqual(store.state.base.inventory.slots, Tuning.Economy.startingInventorySlots)
    }

    // MARK: Identifying

    func testIdentifyingACurioRevealsWhatItIs() throws {
        let store = richStore()
        let curio = try XCTUnwrap(ContentCatalog.shared.items.first { $0.kind == .curio })
        let stack = ItemStack(id: InstanceID(rawValue: 1), catalogID: curio.id, count: 1, identified: false)
        store.mutate("found something") { $0.base.inventory.add(stack) }

        let essenceBefore = store.state.base.essence
        let revealed = try XCTUnwrap(store.identify(stack))

        XCTAssertEqual(store.state.base.essence, essenceBefore - Tuning.Economy.identifyCostEssence)
        XCTAssertEqual(revealed.id, curio.identifiesInto)
        XCTAssertTrue(store.unidentifiedStacks.isEmpty)
        XCTAssertEqual(store.state.base.inventory.stacks.first?.catalogID, curio.identifiesInto)
    }

    func testIdentifyingIsRefusedWithoutTheFee() throws {
        let store = GameStore(io: .temporary(name: "identify-poor-\(UUID().uuidString)"))
        let curio = try XCTUnwrap(ContentCatalog.shared.items.first { $0.kind == .curio })
        let stack = ItemStack(id: InstanceID(rawValue: 1), catalogID: curio.id, count: 1, identified: false)
        store.mutate("found something, spent everything") { state in
            state.base.inventory.add(stack)
            state.base.essence = 0
        }

        XCTAssertNil(store.identify(stack))
        XCTAssertEqual(store.unidentifiedStacks.count, 1)
    }

    // MARK: The delayed payoff

    /// The moment the whole itemization spine exists for: a key found in one world, carried home,
    /// identified, and spent on a lock standing in a different world entirely.
    func testAKeyFromOneWorldOpensACacheInAnother() throws {
        let store = richStore()

        // World A: a curio drops. Identify it at home — and it's a key.
        let knot = try XCTUnwrap(ContentCatalog.shared.items.first {
            $0.kind == .curio && ContentCatalog.shared.item($0.identifiesInto ?? "")?.kind == .key
        })
        let stack = ItemStack(id: InstanceID(rawValue: 7), catalogID: knot.id, count: 1, identified: false)
        store.mutate("hauled home from world A") { $0.base.inventory.add(stack) }
        let key = try XCTUnwrap(store.identify(stack))
        XCTAssertEqual(key.kind, .key)

        // World B: stand on a cache.
        store.setSymbol("plains", in: "terrain")
        store.bindAndDepart()
        store.mutate("stand on a cache") { state in
            guard var run = state.worlds.activeRun else { return }
            run.map[run.playerPosition].content = .lockedCache
            state.worlds.activeRun = run
        }

        XCTAssertTrue(store.isOnLockedCache)
        XCTAssertNotNil(store.carriedCacheKey, "The key came from a different world entirely")

        let symbolsBefore = store.state.base.ownedSymbols.count
        let componentsBefore = store.state.base.ownedGambitComponents.count
        let motesBefore = store.state.reality.motes
        let reward = try XCTUnwrap(store.openCacheHere())

        XCTAssertNil(store.carriedCacheKey, "The key is spent")
        XCTAssertFalse(store.isOnLockedCache, "The cache is opened, not reopenable")

        // Guaranteed Rare+: a new symbol, a new rule, or motes. Never nothing.
        switch reward {
        case .symbol: XCTAssertEqual(store.state.base.ownedSymbols.count, symbolsBefore + 1)
        case .gambitComponent: XCTAssertEqual(store.state.base.ownedGambitComponents.count, componentsBefore + 1)
        case .motes(let amount):
            XCTAssertGreaterThan(amount, 0)
            XCTAssertEqual(store.state.reality.motes, motesBefore + amount)
        }
    }

    func testACacheWithoutAKeyStaysShut() throws {
        let store = richStore()
        store.setSymbol("plains", in: "terrain")
        store.bindAndDepart()
        store.mutate("stand on a cache") { state in
            guard var run = state.worlds.activeRun else { return }
            run.map[run.playerPosition].content = .lockedCache
            state.worlds.activeRun = run
        }

        XCTAssertNil(store.carriedCacheKey)
        XCTAssertNil(store.openCacheHere())
        XCTAssertTrue(store.isOnLockedCache, "It's still there, still shut")
    }

    /// A cache is never a dud — it falls back to motes when there's nothing new left to give.
    func testACacheAlwaysPaysSomething() {
        var state = GameState.newGame()
        state.base.ownedSymbols = Set(ContentCatalog.shared.symbols.map(\.id))
        state.base.ownedGambitComponents = Set(ContentCatalog.shared.gambitComponents.map(\.id))
        var rng = SeededRNG(seed: 4242)

        for _ in 0..<20 {
            let reward = EconomyRules.rollCacheReward(in: state, rng: &rng)
            guard case .motes(let amount) = reward else {
                return XCTFail("With everything owned, the only thing left to give is motes")
            }
            XCTAssertGreaterThan(amount, 0)
        }
    }

    // MARK: Constellation

    func testBuyingAConstellationNodeSpendsMotesAndSticks() throws {
        let store = richStore()
        let node = try XCTUnwrap(ContentCatalog.shared.constellationNodes.first)
        let cost = try XCTUnwrap(store.moteCost(of: node))
        let before = store.state.reality.motes

        XCTAssertTrue(store.buy(node))
        XCTAssertEqual(store.state.reality.motes, before - cost)
        XCTAssertEqual(store.state.reality.rank(of: node.id), 1)

        store.resetBaseKeepingReality()
        XCTAssertEqual(store.state.reality.rank(of: node.id), 1, "The Reality layer never gives it back")
    }

    func testConstellationNodesCannotBeBoughtPastTheirMaxRank() throws {
        let store = richStore()
        let node = try XCTUnwrap(ContentCatalog.shared.constellationNodes.first)
        for _ in 0..<(node.maxRank + 2) { store.buy(node) }
        XCTAssertEqual(store.state.reality.rank(of: node.id), node.maxRank)
        XCTAssertNil(store.moteCost(of: node))
    }

    // MARK: Automate self

    /// The unlock has to actually do something: your own rules, followed without you.
    func testAutomateSelfHandsTheBinderOverToItsOwnRules() throws {
        let store = richStore()
        try researchThrough("automate_self", in: store)
        XCTAssertTrue(store.state.base.hasAutomateSelfUnlock)

        store.mutate("write your own hand") { $0.base.binderGambits = [Self.attackAnything] }
        store.setSymbol("plains", in: "terrain")
        store.bindAndDepart()
        store.mutate("stage a fight") { state in
            guard var run = state.worlds.activeRun else { return }
            run.enemies = [WorldEnemy(id: InstanceID(rawValue: 1), creatureID: "ink_hound",
                                      position: run.playerPosition, isAwake: true)]
            state.worlds.activeRun = run
            WorldRules.beginEncounter(triggeredBy: run.enemies[0], in: &state)
        }

        XCTAssertNotNil(GambitEngine.decide(for: .binder, in: store.state),
                        "The Binder now has rules of its own to follow")
        XCTAssertFalse(CombatRules.needsPlayerInput(store.state),
                       "…and the fight no longer waits on you")
    }

    func testWithoutTheUnlockTheBinderIsAlwaysManual() throws {
        let store = richStore()
        store.mutate("rules written but not unlocked") { $0.base.binderGambits = [Self.attackAnything] }
        store.setSymbol("plains", in: "terrain")
        store.bindAndDepart()
        store.mutate("stage a fight") { state in
            guard var run = state.worlds.activeRun else { return }
            run.enemies = [WorldEnemy(id: InstanceID(rawValue: 1), creatureID: "ink_hound",
                                      position: run.playerPosition, isAwake: true)]
            state.worlds.activeRun = run
            WorldRules.beginEncounter(triggeredBy: run.enemies[0], in: &state)
        }

        XCTAssertNil(GambitEngine.decide(for: .binder, in: store.state))
        XCTAssertTrue(CombatRules.needsPlayerInput(store.state), "Automating yourself is earned")
    }
}
