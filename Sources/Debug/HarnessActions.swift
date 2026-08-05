import Foundation

/// Crude stand-ins for the parts of the loop that don't exist yet.
///
/// These are **not gameplay**. They exist so every commitment point can be reached and then killed,
/// proving the save survives at each. Milestones 3–4 replace them with the real world map and
/// encounter systems; this file should shrink to nothing and be deleted.
///
/// They call the same `BookRules` the shipping preview and bind flow call, so what the kill-test
/// proves is the actual save shape and the actual rules, not a toy.
///
/// Milestone 2 update: binding is real now and lives in `Rules/GameActions.swift`.
extension GameStore {

    // MARK: World turns (milestone 3 replaces this)

    func harnessTakeWorldTurn() {
        guard state.worlds.activeRun != nil else { return }
        mutate("world turn") { state in
            guard var run = state.worlds.activeRun else { return }
            run.turnsTaken += 1
            // Decay advances on a PLAYER TURN — never on wall-clock time (pillar 2).
            run.stability = max(0, run.stability - BookRules.decayPerTurn(for: run.book))
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
            if let resource = run.rng.pickWeighted(BookRules.yieldTable(for: run.book)) {
                let amount = run.rng.int(in: Tuning.World.harvestTurnsRange)
                run.satchel.add(amount, of: resource)
                state.reality.discovery.recordResource(resource, runIndex: run.runIndex)
            }
            run.turnsTaken += 1
            run.stability = max(0, run.stability - BookRules.decayPerTurn(for: run.book))
            state.reality.lifetime.worldTurnsTaken += 1
            state.worlds.activeRun = run
        }
    }

    // MARK: Encounters (milestone 4 replaces this)

    func harnessEnterEncounter() {
        guard let run = state.worlds.activeRun, run.activeEncounter == nil else { return }
        mutate("enter encounter", flush: true) { state in
            guard var run = state.worlds.activeRun else { return }
            let table = BookRules.enemyTable(for: run.book)
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
                // The encounter-flag registry: this is what turns a silhouette into a real icon in
                // the Writing Desk's preview.
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

    // MARK: - Shared

    /// Banking respects the layer split: motes are Reality, everything else is Base.
    nonisolated static func bank(_ satchel: ResourcePool, into state: inout GameState, fraction: Double) {
        for (id, amount) in satchel.scaled(by: fraction).nonZero {
            if ContentCatalog.shared.resource(id)?.isRealityCurrency == true {
                state.reality.motes += amount
            } else {
                state.base.resources.add(amount, of: id)
            }
        }
    }
}
