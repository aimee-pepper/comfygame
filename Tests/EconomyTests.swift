import XCTest
@testable import Bookbinder

/// Spending: refining, upgrades, identification, the key→cache payoff, and Constellation nodes.
@MainActor
final class EconomyTests: XCTestCase {

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

    private func upgrade(_ id: UpgradeID) throws -> UpgradeDef {
        try XCTUnwrap(ContentCatalog.shared.upgrade(id))
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

    // MARK: Upgrades

    func testBuyingAnUpgradeSpendsBothCurrenciesAndApplies() throws {
        let store = richStore()
        let shelving = try upgrade("storehouse_expansion")
        let cost = try XCTUnwrap(store.nextCost(of: shelving))
        let essenceBefore = store.state.base.essence
        let oreBefore = store.state.base.resources[Resources.ore]
        let slotsBefore = store.state.base.inventory.slots

        XCTAssertTrue(store.buy(shelving))

        XCTAssertEqual(store.state.base.essence, essenceBefore - cost.essence)
        XCTAssertEqual(store.state.base.resources[Resources.ore], oreBefore - (cost.resources[Resources.ore] ?? 0))
        XCTAssertEqual(store.rank(of: shelving), 1)
        XCTAssertEqual(store.state.base.inventory.slots,
                       slotsBefore + Tuning.Economy.inventorySlotsPerStorehouseTier,
                       "Capacity has to follow the tier, not drift from it")
    }

    /// Rank is derived from the state the upgrade changes, so it can't disagree with reality.
    func testRankIsDerivedNotStored() throws {
        let store = richStore()
        let satchel = try upgrade("satchel_expansion")
        store.buy(satchel)
        XCTAssertEqual(store.rank(of: satchel), 1)

        // Change the underlying state directly; the rank must follow it.
        store.mutate("meddle") { $0.base.satchelTier = 2 }
        XCTAssertEqual(store.rank(of: satchel), 2)
    }

    func testUpgradesStopAtTheirMaxRank() throws {
        let store = richStore()
        let gambitSlot = try upgrade("gambit_slot")
        XCTAssertTrue(store.buy(gambitSlot))
        XCTAssertNil(store.nextCost(of: gambitSlot), "One rank means one purchase")
        XCTAssertFalse(store.buy(gambitSlot))
        XCTAssertEqual(store.rank(of: gambitSlot), gambitSlot.maxRank)
    }

    func testCannotBuyWhatYouCannotAfford() throws {
        let store = GameStore(io: .temporary(name: "poor-\(UUID().uuidString)"))
        store.mutate("broke") { $0.base.essence = 0 }
        let shelving = try upgrade("storehouse_expansion")

        XCTAssertFalse(store.canBuy(shelving))
        XCTAssertFalse(store.buy(shelving))
        XCTAssertFalse(store.shortfall(for: shelving).isEmpty, "The UI has to be able to say what's missing")
        XCTAssertEqual(store.rank(of: shelving), 0)
    }

    func testBuyingAGambitSlotWidensTheCompanionsRules() throws {
        let store = richStore()
        let before = store.activeGambitSlots
        store.buy(try upgrade("gambit_slot"))
        XCTAssertEqual(store.activeGambitSlots, before + 1)
    }

    /// Two sources of slots, in two layers — and only one of them survives a reset. That's the
    /// whole point of having both.
    func testWorkshopSlotsAreLostInAResetAndConstellationSlotsAreNot() throws {
        let store = richStore()
        store.buy(try upgrade("gambit_slot"))
        let node = try XCTUnwrap(ContentCatalog.shared.constellationNode(ConstellationNodes.extraGambitSlot))
        store.buy(node)
        XCTAssertEqual(store.activeGambitSlots, Tuning.Encounter.startingGambitSlots + 2)

        store.resetBaseKeepingReality()

        XCTAssertEqual(store.activeGambitSlots, Tuning.Encounter.startingGambitSlots + 1,
                       "The Workshop slot goes, the Constellation slot stays")
    }

    func testResearchingASymbolGrantsIt() throws {
        let store = richStore()
        let symbol = try XCTUnwrap(ContentCatalog.shared.symbols.first { $0.acquisition == .research })
        XCTAssertFalse(store.state.base.ownedSymbols.contains(symbol.id))

        XCTAssertTrue(store.research(symbol))
        XCTAssertTrue(store.state.base.ownedSymbols.contains(symbol.id))
        XCTAssertFalse(store.research(symbol), "…and only once")
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
        let piecesBefore = store.state.base.ownedGambitPieces.count
        let motesBefore = store.state.reality.motes
        let reward = try XCTUnwrap(store.openCacheHere())

        XCTAssertNil(store.carriedCacheKey, "The key is spent")
        XCTAssertFalse(store.isOnLockedCache, "The cache is opened, not reopenable")

        // Guaranteed Rare+: a new symbol, a new rule, or motes. Never nothing.
        switch reward {
        case .symbol: XCTAssertEqual(store.state.base.ownedSymbols.count, symbolsBefore + 1)
        case .gambitPiece: XCTAssertEqual(store.state.base.ownedGambitPieces.count, piecesBefore + 1)
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
        state.base.ownedGambitPieces = ContentCatalog.shared.gambitPieces.map(\.id)
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
        store.buy(try upgrade("automate_self"))
        XCTAssertTrue(store.state.base.hasAutomateSelfUnlock)

        store.mutate("write your own hand") { $0.base.binderGambits = ["foe_any_attack"] }
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
        store.mutate("rules written but not unlocked") { $0.base.binderGambits = ["foe_any_attack"] }
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
