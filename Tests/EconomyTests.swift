import XCTest
@testable import Bookbinder

/// Spending: refining, upgrades, identification, the key→cache payoff, and Constellation nodes.
@MainActor
final class EconomyTests: XCTestCase {
    func testLootDecisionConfirmsTheExactItemBeforeLeavingItBehind() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(
            contentsOf: root.appending(path: "Sources/Screens/LootDecisionView.swift"),
            encoding: .utf8
        )

        XCTAssertTrue(source.contains("Leave \\(offered.displayName) behind?"))
        XCTAssertTrue(source.contains("You cannot recover it after leaving this decision."))
        XCTAssertTrue(source.contains("Button(\"Leave \\(offered.displayName)\", role: .destructive)"))
        XCTAssertFalse(source.contains("Button(role: .destructive) {\n                    store.leaveOffered(offered)"))
    }


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

    func testAdvancedCapacityRequiresTheMatchingTanneryCapability() throws {
        let store = richStore()
        store.mutate("build tannery and finish early capacity") { state in
            state.base.stations[Stations.tannery] = StationState(isUnlocked: true, tier: 0)
            state.base.completedResearch.formUnion([
                "shelving_one", "shelving_two", "shelving_three",
                "satchel_one", "satchel_two"
            ])
        }
        let shelving = try node("shelving_four")
        let satchel = try node("satchel_three")
        XCTAssertFalse(store.isAvailable(shelving))
        XCTAssertFalse(store.isAvailable(satchel))
        XCTAssertTrue(store.research(try node("tannery_keep_root")))
        XCTAssertTrue(store.isAvailable(shelving))
        XCTAssertTrue(store.research(try node("tannery_carry_root")))
        XCTAssertTrue(store.isAvailable(satchel))
    }

    func testLegacyPurchasedCapacityRemainsCompleteWithoutNewTanneryPrerequisite() throws {
        let store = richStore()
        store.mutate("legacy capacity") { state in
            state.base.completedResearch.insert("satchel_three")
            state.base.satchelTier = 3
        }
        let node = try node("satchel_three")
        XCTAssertTrue(store.isComplete(node))
        XCTAssertEqual(store.state.base.satchelTier, 3)
        XCTAssertFalse(store.isAvailable(node))
    }

    func testBowyerResearchRaisesStoredStationTierOncePerRung() throws {
        let store = richStore()
        store.mutate("build and stock bowyer") { state in
            state.base.stations[Stations.bowyer] = StationState(isUnlocked: true, tier: 0)
            state.base.resources.add(100, of: "timber")
            state.base.resources.add(100, of: "resin")
        }
        XCTAssertTrue(store.research(try node("bowyer_broaden")))
        XCTAssertEqual(store.state.base.station(Stations.bowyer).tier, 1)
        XCTAssertFalse(store.research(try node("bowyer_broaden")))
        XCTAssertEqual(store.state.base.station(Stations.bowyer).tier, 1)
        XCTAssertTrue(store.research(try node("bowyer_masterwork")))
        XCTAssertEqual(store.state.base.station(Stations.bowyer).tier, 2)
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
        let before = store.activeGambitSlots(for: .binder)
        try researchThrough("longer_instruction", in: store)
        XCTAssertEqual(store.activeGambitSlots(for: .binder), before + 1)
    }

    /// Two sources of slots, in two layers — and only one survives a reset. That's the whole point
    /// of having both.
    func testResearchedSlotsAreLostInAResetAndConstellationSlotsAreNot() throws {
        let store = richStore()
        try researchThrough("longer_instruction", in: store)
        let node = try XCTUnwrap(ContentCatalog.shared.constellationNode(ConstellationNodes.extraGambitSlot))
        store.buy(node)
        XCTAssertEqual(store.activeGambitSlots(for: .binder), Tuning.Encounter.startingGambitSlots + 2)

        store.resetBaseKeepingReality()

        XCTAssertEqual(store.activeGambitSlots(for: .binder), Tuning.Encounter.startingGambitSlots + 1,
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
        store.write("plains")
        store.bindAndDepart()
        store.mutate("stand on a cache") { state in
            guard var run = state.worlds.activeRun else { return }
            run.map[run.playerPosition].content = .lockedCache
            state.worlds.activeRun = run
        }

        XCTAssertTrue(store.isOnLockedCache)
        XCTAssertNotNil(store.carriedCacheKey, "The key came from a different world entirely")

        let symbolsBefore = store.state.base.ownedSymbols.count
        let sourcesBefore = store.state.base.ownedSources.count
        let componentsBefore = store.state.base.ownedGambitComponents.count
        let motesBefore = store.state.reality.motes
        let reward = try XCTUnwrap(store.openCacheHere())

        XCTAssertNil(store.carriedCacheKey, "The key is spent")
        XCTAssertFalse(store.isOnLockedCache, "The cache is opened, not reopenable")

        // Guaranteed Rare+: a word, a symbol, a new rule, or motes. Never nothing.
        switch reward {
        case .focus: XCTAssertEqual(store.state.base.ownedSources.count, sourcesBefore + 1)
        case .symbol: XCTAssertEqual(store.state.base.ownedSymbols.count, symbolsBefore + 1)
        case .gambitComponent: XCTAssertEqual(store.state.base.ownedGambitComponents.count, componentsBefore + 1)
        case .motes(let amount):
            XCTAssertGreaterThan(amount, 0)
            XCTAssertEqual(store.state.reality.motes, motesBefore + amount)
        }
    }

    func testACacheWithoutAKeyStaysShut() throws {
        let store = richStore()
        store.write("plains")
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
        state.base.ownedSources = Set(ContentCatalog.shared.pressureSources.map(\.id))
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

    // MARK: The satchel decision

    func testGambitWriteActionPrecedesThePotentiallyLongPriorityList() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(
            contentsOf: root.appending(path: "Sources/Screens/GambitEditorView.swift"),
            encoding: .utf8
        )

        let action = try XCTUnwrap(source.range(of: "Label(\"Write a rule\""))
        let priorityList = try XCTUnwrap(source.range(of: "List {"))
        XCTAssertLessThan(action.lowerBound, priorityList.lowerBound)
        XCTAssertEqual(source.components(separatedBy: "Label(\"Write a rule\"").count - 1, 1)
    }

    func testGambitSwipeDeletionConfirmsStableRuleIdentityBeforeMutation() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(
            contentsOf: root.appending(path: "Sources/Screens/GambitEditorView.swift"),
            encoding: .utf8
        )

        XCTAssertTrue(source.contains("pendingDeletionID = rule.id"))
        XCTAssertTrue(source.contains("firstIndex(where: { $0.id == pendingDeletionID })"))
        XCTAssertTrue(source.contains("Button(\"Cancel\", role: .cancel)"))
        XCTAssertTrue(source.contains("Button(\"Delete rule\", role: .destructive)"))
        XCTAssertTrue(source.contains("pendingDeletion?.rule.displayText"))
        XCTAssertEqual(source.components(separatedBy: "store.removeGambit(at:").count - 1, 1,
                       "a rule should be removed only by the confirmed stable-ID path")
        XCTAssertTrue(source.contains("Button(\"Any — no condition\")"))
        XCTAssertFalse(source.contains("Button(\"Any — no condition\", role: .destructive)"),
                       "a valid optional-condition choice should not be styled as destructive")
    }

    func testLootSwapKeepsTheExactDecisionActionOutsideScrollableItemFacts() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let source = try String(
            contentsOf: root.appending(path: "Sources/Screens/LootDecisionView.swift"),
            encoding: .utf8
        )

        XCTAssertTrue(source.contains(".safeAreaInset(edge: .bottom)"))
        XCTAssertTrue(source.contains("Drop this and take \\(offered.displayName)"))
        XCTAssertTrue(source.contains("swapSummary(carried, role: \"Drop\", location: .carried)"))
        XCTAssertTrue(source.contains("swapSummary(offered, role: \"Take\", location: .offered)"))
        XCTAssertTrue(source.contains("Image(systemName: \"arrow.right\")"))
        XCTAssertTrue(source.contains(".frame(maxWidth: .infinity, minHeight: 44)"))
        XCTAssertTrue(source.contains("case .refused(let message):\n                        refusal = message"))
    }

    /// A full satchel must hand the player a choice, not make one for them. Silently dropping the
    /// loot, or silently discarding what you were carrying, both empty out the reason the satchel is
    /// smaller than home storage in the first place.
    func testLootThatDoesNotFitBecomesADecision() throws {
        let store = richStore()
        store.write("plains")
        store.bindAndDepart()

        let curio = try XCTUnwrap(ContentCatalog.shared.items.first { $0.kind == .curio })
        store.mutate("fill the satchel and offer one more") { state in
            guard var run = state.worlds.activeRun else { return }
            run.satchelItems = Inventory(slots: 1, stacks: [
                ItemStack(id: InstanceID(rawValue: 1), catalogID: curio.id, count: 1, identified: false)
            ])
            run.offeredItems = [ItemStack(id: InstanceID(rawValue: 2), catalogID: curio.id,
                                          count: 1, identified: false)]
            state.worlds.activeRun = run
        }

        XCTAssertEqual(store.pendingLoot.count, 1, "The decision is pending, not resolved")

        let offered = try XCTUnwrap(store.pendingLoot.first)
        let carried = try XCTUnwrap(store.state.worlds.activeRun?.satchelItems.stacks.first)
        guard case .allowed(let quote) = store.lootSwapQuote(offered: offered, dropping: carried) else {
            return XCTFail("A valid exact swap did not quote")
        }
        XCTAssertEqual(store.takeOffered(quote), .committed)

        let run = try XCTUnwrap(store.state.worlds.activeRun)
        XCTAssertTrue(run.offeredItems.isEmpty)
        XCTAssertEqual(run.satchelItems.stacks.map(\.id), [offered.id], "You swapped, not stacked")
    }

    func testStaleLootSwapQuoteRefusesWithoutDeletingEitherItem() throws {
        let store = richStore()
        store.write("plains")
        store.bindAndDepart()
        let curio = try XCTUnwrap(ContentCatalog.shared.items.first { $0.kind == .curio })
        let carried = ItemStack(id: InstanceID(rawValue: 11), catalogID: curio.id)
        let offered = ItemStack(id: InstanceID(rawValue: 12), catalogID: curio.id)
        store.mutate("prepare quoted swap") { state in
            state.worlds.activeRun?.satchelItems = Inventory(slots: 1, stacks: [carried])
            state.worlds.activeRun?.offeredItems = [offered]
        }
        guard case .allowed(let quote) = store.lootSwapQuote(offered: offered, dropping: carried) else {
            return XCTFail("The initial swap did not quote")
        }
        store.mutate("change carried stack behind sheet") { state in
            state.worlds.activeRun?.satchelItems.stacks[0].count = 2
        }

        guard case .refused = store.takeOffered(quote) else {
            return XCTFail("A stale exact quote committed")
        }
        XCTAssertEqual(store.pendingLoot, [offered])
        XCTAssertEqual(store.state.worlds.activeRun?.satchelItems.stacks.first?.count, 2)
    }

    func testLootSwapQuoteRefusesWhenRemovalWouldStillLeaveNoCapacity() throws {
        let store = richStore()
        store.write("plains")
        store.bindAndDepart()
        let curio = try XCTUnwrap(ContentCatalog.shared.items.first { $0.kind == .curio })
        let carried = ItemStack(id: InstanceID(rawValue: 21), catalogID: curio.id)
        let offered = ItemStack(id: InstanceID(rawValue: 22), catalogID: curio.id)
        store.mutate("prepare impossible zero-slot swap") { state in
            state.worlds.activeRun?.satchelItems = Inventory(slots: 0, stacks: [carried])
            state.worlds.activeRun?.offeredItems = [offered]
        }

        guard case .refused = store.lootSwapQuote(offered: offered, dropping: carried) else {
            return XCTFail("A swap whose add would fail was quoted as allowed")
        }
        XCTAssertEqual(store.pendingLoot, [offered])
        XCTAssertEqual(store.state.worlds.activeRun?.satchelItems.stacks, [carried])
    }

    func testCapacityMutationAfterLootQuoteRefusesWithNoLoss() throws {
        let store = richStore()
        store.write("plains")
        store.bindAndDepart()
        let curio = try XCTUnwrap(ContentCatalog.shared.items.first { $0.kind == .curio })
        let carried = ItemStack(id: InstanceID(rawValue: 31), catalogID: curio.id)
        let offered = ItemStack(id: InstanceID(rawValue: 32), catalogID: curio.id)
        store.mutate("prepare capacity quote") { state in
            state.worlds.activeRun?.satchelItems = Inventory(slots: 1, stacks: [carried])
            state.worlds.activeRun?.offeredItems = [offered]
        }
        guard case .allowed(let quote) = store.lootSwapQuote(offered: offered, dropping: carried) else {
            return XCTFail("The initial capacity-safe swap did not quote")
        }
        store.mutate("remove capacity behind open detail") { state in
            state.worlds.activeRun?.satchelItems.slots = 0
        }

        guard case .refused = store.takeOffered(quote) else {
            return XCTFail("A quote committed after its add capacity disappeared")
        }
        let run = try XCTUnwrap(store.state.worlds.activeRun)
        XCTAssertEqual(run.offeredItems, [offered], "refusal must preserve offered loot")
        XCTAssertEqual(run.satchelItems.stacks, [carried], "refusal must preserve carried loot")
        XCTAssertEqual(run.offeredItems.count + run.satchelItems.stacks.count, 2,
                       "a failed atomic swap must neither lose nor duplicate an item")
    }

    func testLootCanBeLeftBehind() throws {
        let store = richStore()
        store.write("plains")
        store.bindAndDepart()
        let curio = try XCTUnwrap(ContentCatalog.shared.items.first { $0.kind == .curio })
        store.mutate("offer something") { state in
            state.worlds.activeRun?.offeredItems = [
                ItemStack(id: InstanceID(rawValue: 3), catalogID: curio.id, count: 1, identified: false)
            ]
        }

        store.leaveOffered(try XCTUnwrap(store.pendingLoot.first))
        XCTAssertTrue(store.pendingLoot.isEmpty)
        XCTAssertTrue(store.state.worlds.activeRun?.satchelItems.stacks.isEmpty ?? false)
    }

    /// A decision you're in the middle of has to survive a force-quit like anything else.
    func testAPendingLootDecisionSurvivesRelaunch() throws {
        let io = SaveFileIO.temporary(name: "offer-\(UUID().uuidString)")
        defer { io.deleteEverything() }

        let first = GameStore(io: io)
        first.write("plains")
        first.bindAndDepart()
        let curio = try XCTUnwrap(ContentCatalog.shared.items.first { $0.kind == .curio })
        first.mutate("offer something", flush: true) { state in
            state.worlds.activeRun?.offeredItems = [
                ItemStack(id: InstanceID(rawValue: 4), catalogID: curio.id, count: 1, identified: false)
            ]
        }

        let second = GameStore(io: io)
        XCTAssertEqual(second.pendingLoot.count, 1, "The choice is still open on relaunch")
    }

    // MARK: Never stranded

    /// The failstate Aimee hit on device: essence only enters the game by coming home from a
    /// world, so spending your last on a book and returning empty-handed left you at the desk with
    /// nothing to write and no way to earn any. The game was simply over, silently.
    func testTheBaseNeverStrandsYou() {
        let store = GameStore(io: .temporary(name: "stranded-\(UUID().uuidString)"))
        store.mutate("spend everything") { state in
            state.base.essence = 0
            state.base.resources = ResourcePool()
        }

        store.ensureDepartureIsPossible()

        XCTAssertTrue(store.canBindAndDepart, "There must always be a way back out into a world")
        XCTAssertGreaterThanOrEqual(store.state.base.essence,
                                    EconomyRules.minimumBindCost(in: store.state))
    }

    /// Raw essence you could still refine counts — the Spring shouldn't hand out charity to
    /// somebody who simply hasn't walked to the Workshop yet.
    func testTheSpringDoesNotPayForWhatYouAlreadyHave() {
        let store = GameStore(io: .temporary(name: "hasraw-\(UUID().uuidString)"))
        store.mutate("plenty of raw, no refined") { state in
            state.base.essence = 0
            state.base.resources = ResourcePool()
            state.base.resources.add(50, of: Resources.essenceRaw)
        }

        store.ensureDepartureIsPossible()

        XCTAssertEqual(store.state.base.essence, 0, "You can refine your way out of this yourself")
        XCTAssertTrue(store.needsToRefine, "…and the game has to say so")
    }

    /// A stranded save left by an earlier build recovers itself rather than needing a wipe.
    func testAStrandedSaveRecoversOnLaunch() throws {
        let io = SaveFileIO.temporary(name: "recover-\(UUID().uuidString)")
        defer { io.deleteEverything() }

        let first = GameStore(io: io)
        first.mutate("strand it", flush: true) { state in
            state.base.essence = 0
            state.base.resources = ResourcePool()
        }

        let second = GameStore(io: io)
        XCTAssertTrue(second.canBindAndDepart, "Reopening the app has to get you unstuck")
    }

    /// Coming home broke still leaves you able to leave again.
    func testReturningWithNothingStillLetsYouDepartAgain() {
        let store = GameStore(io: .temporary(name: "broke-return-\(UUID().uuidString)"))
        store.write("plains")
        store.bindAndDepart()
        store.mutate("spend it all while away") { $0.base.essence = 0 }

        store.portalHome()

        // The guarantee is that *something* is always writable, not that your current draft is.
        // A fancier book than you can afford is a legible problem with a stated fix; nothing at
        // all to write is a dead end.
        store.clearPage()
        XCTAssertTrue(store.canBindAndDepart, "There must always be a cheapest book you can write")
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
        store.write("plains")
        store.bindAndDepart()
        store.mutate("stage a fight") { state in
            guard var run = state.worlds.activeRun else { return }
            run.enemies = [WorldEnemy(id: InstanceID(rawValue: 1), creatureID: "ink_hound",
                                      position: run.playerPosition, isAwake: true)]
            state.worlds.activeRun = run
            WorldRules.beginEncounter(triggeredBy: run.enemies[0], in: &state)
        }

        // The fight now opens on its own — automatic turns start with the encounter rather than
        // waiting for a tap — so the proof is that the Binder acted without being asked.
        let encounter = try XCTUnwrap(store.activeEncounter)
        XCTAssertTrue(encounter.log.contains { $0.hasPrefix("You:") },
                      "The Binder now has rules of its own to follow, and nobody tapped anything")
        XCTAssertFalse(CombatRules.needsPlayerInput(store.state),
                       "…and the fight no longer waits on you")
    }

    func testWithoutTheUnlockTheBinderIsAlwaysManual() throws {
        let store = richStore()
        store.mutate("rules written but not unlocked") { $0.base.binderGambits = [Self.attackAnything] }
        store.write("plains")
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

    /// **Nothing may grant a value nothing reads** (`fossil-audit.md` §6).
    ///
    /// The Fifth Mark sold *"+1 symbol slot in every book you bind"* for three motes. Books stopped
    /// having symbol slots when the page grid replaced them — and `bonusBookSlots` was never read
    /// by anything even before that. It was dead on arrival and survived the system it belonged to.
    ///
    /// This is the cheap guard the audit asked for: a Constellation node whose effect nothing
    /// consumes is a fossil by definition, and the research tree already has the equivalent check.
    func testEveryConstellationNodeActuallyDoesSomething() throws {
        let sources = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()      // Tests/
            .deletingLastPathComponent()      // repo root
            .appendingPathComponent("Sources")
        var code = ""
        if let walker = FileManager.default.enumerator(at: sources,
                                                       includingPropertiesForKeys: nil) {
            for case let file as URL in walker where file.pathExtension == "swift" {
                code += (try? String(contentsOf: file, encoding: .utf8)) ?? ""
            }
        }
        XCTAssertFalse(code.isEmpty, "couldn't read the source to check against")

        // **The check is on what a node grants, not on the node.** Every node is mentioned
        // somewhere — its own constant, the catalogue, the screen that draws it. What tells you
        // it's a fossil is that the *value* it produces is read by nobody.
        //
        // `RealityState` exposes one accessor per purchasable effect; each has to be consumed
        // outside the file that declares it, or the purchase buys nothing.
        let realityFile = sources.appendingPathComponent("Model/RealityState.swift")
        let reality = (try? String(contentsOf: realityFile, encoding: .utf8)) ?? ""
        let accessors = reality
            .components(separatedBy: "\n")
            .filter { $0.contains("rank(of: ConstellationNodes") }
            .compactMap { line -> String? in
                guard let name = line.components(separatedBy: "var ").last?
                    .components(separatedBy: ":").first else { return nil }
                return name.trimmingCharacters(in: .whitespaces)
            }
        XCTAssertFalse(accessors.isEmpty, "no constellation effects found to check")

        let elsewhere = code.replacingOccurrences(of: reality, with: "")
        for accessor in accessors {
            XCTAssertTrue(elsewhere.contains(accessor),
                          "\(accessor) is bought with motes and read by nothing — a fossil")
        }
    }

    // MARK: Every progression axis has a door

    /// **The fault `clause-audit.md` F2 found**, expressed so it can't come back: all five analysis
    /// tiers were implemented, tiers 3 and 4 did real work, and `analysisTier` was written by a save
    /// decoder and the debug harness and by nothing a player could reach. Finished work nobody could
    /// see.
    @MainActor
    func testAnalysisCanActuallyBeRaisedInPlay() throws {
        let store = GameStore(io: .temporary(name: "analysis-\(UUID().uuidString)"))
        XCTAssertEqual(store.state.reality.analysisTier, Tuning.Analysis.startingTier)

        let instruments = ContentCatalog.shared.researchNodes.filter {
            $0.grants.contains { $0.effect == .analysisTier }
        }
        XCTAssertFalse(instruments.isEmpty, "nothing in the game raises how well you can read a world")

        var state = store.state
        for node in instruments { EconomyRules.apply(node.grants[0], in: &state) }
        XCTAssertEqual(state.reality.analysisTier, Tuning.Analysis.livingTier,
                       "the instruments don't reach the top tier, so two of them are still unreachable")
    }

    /// And the tiers that do the most work have to be among the ones you can get to.
    @MainActor
    func testTheTiersThatDoWorkAreReachable() {
        let reachable = ContentCatalog.shared.researchNodes
            .filter { $0.grants.contains { $0.effect == .analysisTier } }.count
            + Tuning.Analysis.startingTier
        XCTAssertGreaterThanOrEqual(reachable, Tuning.Analysis.attributionTier,
                                    "the red/green attribution tier is still finished work nobody can see")
    }

    /// **Knowledge is never taken back.** Analysis lives in Reality, like visited seeds and the
    /// Library, so a future base reset can't cost you an instrument you ground yourself.
    @MainActor
    func testAnInstrumentSurvivesABaseReset() {
        let store = GameStore(io: .temporary(name: "analysis-reset-\(UUID().uuidString)"))
        store.mutate("test: an instrument") { $0.reality.analysisTier = Tuning.Analysis.attributionTier }
        store.resetBaseKeepingReality()
        XCTAssertEqual(store.state.reality.analysisTier, Tuning.Analysis.attributionTier,
                       "a base reset took back something that was learned")
    }
}
