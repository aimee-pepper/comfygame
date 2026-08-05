import Foundation

/// Crude stand-ins for the real loop, used by the milestone-1 force-quit harness.
///
/// These are **not gameplay**. They exist so every commitment point in the loop — bind, world
/// turn, harvest, enter encounter, encounter round, bank, collapse — can be reached and then
/// killed, proving the save survives at each. Milestones 2–5 replace each one with the real
/// system; this file should shrink to nothing and be deleted.
///
/// They are still written against the real state model and the real content catalog, so what the
/// kill-test proves is the actual save shape, not a toy.
extension GameStore {

    // MARK: Bind & depart (milestone 2 replaces this)

    var canBindAndDepart: Bool {
        state.worlds.activeRun == nil && state.base.essence >= projectedBindCost
    }

    /// Cost of binding the current draft, including the symbols that would be random-filled.
    /// Uses `peekNextSeed()` so showing the player a cost does not burn a seed — the same seed is
    /// then consumed for real at bind time, so the preview and the world always agree.
    var projectedBindCost: Int {
        let book = resolvedBook(seed: state.worlds.seeds.peekNextSeed())
        return bindCost(of: book)
    }

    @discardableResult
    func harnessBindAndDepart() -> Bool {
        guard canBindAndDepart else { return false }

        mutate("bind book & depart", flush: true) { state in
            let seed = state.worlds.seeds.nextSeed()
            var book = GameStore.resolveBook(
                draft: state.base.bookDraft,
                ownedSymbols: state.base.ownedSymbols,
                seed: seed
            )
            book.essencePaid = GameStore.cost(of: book)

            state.base.essence -= book.essencePaid
            state.worlds.runIndex += 1
            state.reality.lifetime.runsStarted += 1
            state.worlds.activeRun = WorldRun(
                runIndex: state.worlds.runIndex,
                book: book,
                mapSeed: seed,
                rng: SeededRNG(seed: seed).derived(0xA11CE),
                // The satchel carries what the Storehouse can hold. Whether that's the right rule
                // is Q6 in docs/questions-for-design.md.
                satchelItems: Inventory(slots: state.base.inventory.slots)
            )
        }
        return true
    }

    // MARK: World turns (milestone 3 replaces this)

    func harnessTakeWorldTurn() {
        guard state.worlds.activeRun != nil else { return }
        mutate("world turn") { state in
            guard var run = state.worlds.activeRun else { return }
            run.turnsTaken += 1
            // Decay advances on a PLAYER TURN — never on wall-clock time (pillar 2).
            run.stability = max(0, run.stability - GameStore.decayPerTurn(for: run.book))
            state.reality.lifetime.worldTurnsTaken += 1
            state.worlds.activeRun = run
        }
        if let run = state.worlds.activeRun, run.stabilityBand == .collapsed {
            harnessCollapse()
        }
    }

    func harnessHarvest() {
        guard state.worlds.activeRun != nil else { return }
        mutate("harvest", flush: true) { state in
            guard var run = state.worlds.activeRun else { return }
            let table = GameStore.yieldTable(for: run.book)
            if let resource = run.rng.pickWeighted(table) {
                let amount = run.rng.int(in: 1...3)
                run.satchel.add(amount, of: resource)
                state.reality.discovery.recordResource(resource, runIndex: run.runIndex)
            }
            run.turnsTaken += 1
            run.stability = max(0, run.stability - GameStore.decayPerTurn(for: run.book))
            state.reality.lifetime.worldTurnsTaken += 1
            state.worlds.activeRun = run
        }
    }

    // MARK: Encounters (milestone 4 replaces this)

    func harnessEnterEncounter() {
        guard let run = state.worlds.activeRun, run.activeEncounter == nil else { return }
        mutate("enter encounter", flush: true) { state in
            guard var run = state.worlds.activeRun else { return }
            let table = GameStore.enemyTable(for: run.book)
            let foeCount = run.rng.int(in: 1...Tuning.Encounter.maxFoes)
            var foes: [FoeState] = []
            for _ in 0..<foeCount {
                guard let creature = run.rng.pickWeighted(table) else { continue }
                foes.append(FoeState(
                    id: InstanceID(rawValue: run.rng.next()),
                    creatureID: creature.id,
                    currentHP: creature.maxHP,
                    maxHP: creature.maxHP
                ))
                // The encounter-flag registry: this is what flips a silhouette into a real icon
                // in the pre-bind preview.
                state.reality.discovery.recordCreature(creature.id, runIndex: run.runIndex)
            }
            run.activeEncounter = EncounterState(
                id: InstanceID(rawValue: run.rng.next()),
                foes: foes,
                log: ["Something notices you."]
            )
            state.worlds.activeRun = run
        }
    }

    /// One crude round. Every round flushes: mid-encounter is exactly where a resume must be exact.
    func harnessEncounterRound() {
        guard state.worlds.activeRun?.activeEncounter != nil else { return }
        mutate("encounter round", flush: true) { state in
            guard var run = state.worlds.activeRun, var encounter = run.activeEncounter else { return }

            let damage = run.rng.int(in: 3...7) // PLACEHOLDER — real combat maths is milestone 4
            if let index = encounter.foes.firstIndex(where: { $0.currentHP > 0 }) {
                encounter.foes[index].currentHP = max(0, encounter.foes[index].currentHP - damage)
                let name = ContentCatalog.shared.creature(encounter.foes[index].creatureID)?.name ?? "?"
                encounter.log.append("You hit \(name) for \(damage).")
            }

            for foe in encounter.foes where foe.currentHP > 0 {
                let hit = ContentCatalog.shared.creature(foe.creatureID)?.attack ?? 1
                run.binderHP = max(0, run.binderHP - hit)
            }

            encounter.roundNumber += 1
            if encounter.isResolved {
                encounter.log.append("Nothing left standing.")
                state.reality.lifetime.encountersWon += 1
                run.activeEncounter = nil
            } else {
                run.activeEncounter = encounter
            }
            state.worlds.activeRun = run
        }
    }

    // MARK: Banking (milestone 3 replaces this)

    /// Portal exit: keep 100% of the haul.
    func harnessPortalHome() {
        guard state.worlds.activeRun != nil else { return }
        mutate("portal home (bank 100%)", flush: true) { state in
            guard let run = state.worlds.activeRun else { return }
            GameStore.bank(run.satchel, into: &state, fraction: 1.0)
            state.base.inventory.stacks.append(contentsOf: run.satchelItems.stacks)
            state.reality.lifetime.runsBankedViaPortal += 1
            GameStore.creditEssenceSpring(&state)
            state.worlds.activeRun = nil
        }
    }

    /// Caught in collapse: keep a fraction, randomly selected.
    func harnessCollapse() {
        guard state.worlds.activeRun != nil else { return }
        mutate("collapse (partial bank)", flush: true) { state in
            guard var run = state.worlds.activeRun else { return }
            let fraction = Tuning.World.collapseHaulKeptFraction
            GameStore.bank(run.satchel, into: &state, fraction: fraction)
            // Item loss is rolled off the run's own RNG, so a kill during the collapse resumes to
            // the same outcome rather than re-rolling in the player's favour.
            let kept = run.satchelItems.randomlyKeeping(fraction: fraction, rng: &run.rng)
            state.base.inventory.stacks.append(contentsOf: kept.stacks)
            state.reality.lifetime.runsLostToCollapse += 1
            GameStore.creditEssenceSpring(&state)
            state.worlds.activeRun = nil
        }
    }

    // MARK: Reality layer

    func harnessGainMote() {
        mutate("found a mote", flush: true) { $0.reality.motes += 1 }
    }

    // MARK: - Shared helpers (these encode rules milestone 2–4 will reuse)

    private func resolvedBook(seed: UInt64) -> BoundBook {
        GameStore.resolveBook(draft: state.base.bookDraft, ownedSymbols: state.base.ownedSymbols, seed: seed)
    }

    private func bindCost(of book: BoundBook) -> Int { GameStore.cost(of: book) }

    /// Empty slots are random-filled at generation — under-specification is a surprise, not an
    /// error (the Mystcraft rule, locked in decisions-log).
    nonisolated static func resolveBook(draft: BookDraft, ownedSymbols: Set<SymbolID>, seed: UInt64) -> BoundBook {
        var rng = SeededRNG(seed: seed).derived(0xB00C)
        var symbols: [SymbolSlot: SymbolID] = [:]
        var randomlyFilled: Set<SymbolSlot> = []

        for slot in SymbolSlot.allCases {
            if let chosen = draft[slot] {
                symbols[slot] = chosen
            } else {
                // Random fill draws only from symbols the player actually owns.
                let candidates = ContentCatalog.shared.symbols(in: slot)
                    .filter { ownedSymbols.contains($0.id) }
                    .map(\.id)
                    .sorted { $0.rawValue < $1.rawValue } // stable order ⇒ same seed, same fill
                if let pick = rng.pick(candidates) {
                    symbols[slot] = pick
                    randomlyFilled.insert(slot)
                }
            }
        }
        return BoundBook(symbols: symbols, randomlyFilled: randomlyFilled, essencePaid: 0)
    }

    nonisolated static func cost(of book: BoundBook) -> Int {
        let symbolCost = book.allSymbolIDs.reduce(0) { total, id in
            total + (ContentCatalog.shared.symbol(id)?.essenceCost ?? 0)
        }
        return Tuning.Book.baseBindCostEssence
            + Int((Double(symbolCost) * Tuning.Book.symbolCostMultiplier).rounded())
    }

    /// Stability lost per player turn. Richer, greedier books burn faster — the legibility pillar
    /// means this number is shown before binding, never discovered afterwards.
    nonisolated static func decayPerTurn(for book: BoundBook) -> Double {
        let instability = book.allSymbolIDs.reduce(0.0) { total, id in
            total + (ContentCatalog.shared.symbol(id)?.instabilityWeight ?? 0)
        }
        return max(0.1, Tuning.World.baseStabilityDecayPerTurn + instability) // PLACEHOLDER curve
    }

    nonisolated static func yieldTable(for book: BoundBook) -> [(value: ResourceID, weight: Double)] {
        var weights: [ResourceID: Double] = [:]
        for resource in ContentCatalog.shared.resources where !resource.isRealityCurrency {
            weights[resource.id] = 1.0 // PLACEHOLDER base weight
        }
        for id in book.allSymbolIDs {
            guard let symbol = ContentCatalog.shared.symbol(id) else { continue }
            for (resource, multiplier) in symbol.yieldModifiers {
                weights[resource] = (weights[resource] ?? 0) * multiplier
            }
        }
        return weights.map { (value: $0.key, weight: $0.value) }.sorted { $0.value.rawValue < $1.value.rawValue }
    }

    nonisolated static func enemyTable(for book: BoundBook) -> [(value: CreatureDef, weight: Double)] {
        var weights: [CreatureID: Double] = [:]
        for creature in ContentCatalog.shared.creatures {
            weights[creature.id] = creature.spawnWeight
        }
        for id in book.allSymbolIDs {
            guard let symbol = ContentCatalog.shared.symbol(id) else { continue }
            for (creature, delta) in symbol.enemyTableModifiers {
                weights[creature] = (weights[creature] ?? 0) + delta
            }
        }
        return ContentCatalog.shared.creatures.map { (value: $0, weight: weights[$0.id] ?? 0) }
    }

    /// Banking respects the layer split: motes are Reality, everything else is Base.
    nonisolated private static func bank(_ satchel: ResourcePool, into state: inout GameState, fraction: Double) {
        let kept = satchel.scaled(by: fraction)
        for (id, amount) in kept.nonZero {
            if ContentCatalog.shared.resource(id)?.isRealityCurrency == true {
                state.reality.motes += amount
            } else {
                state.base.resources.add(amount, of: id)
            }
        }
    }

    /// Credited on return from a run — an in-session event, never a wall-clock trickle (pillar 2).
    /// Tier 1 of the Spring is built into the base, so tier 0 (un-upgraded) still trickles.
    nonisolated private static func creditEssenceSpring(_ state: inout GameState) {
        let station = state.base.station(Stations.essenceSpring)
        guard station.isUnlocked else { return }
        let index = min(station.tier, Tuning.Economy.essenceSpringPerReturn.count - 1)
        state.base.essence += Tuning.Economy.essenceSpringPerReturn[index]
    }
}
