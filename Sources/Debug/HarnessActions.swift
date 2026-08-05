import Foundation

/// What's left of the stand-ins.
///
/// Milestone 2 made binding real (`Rules/GameActions.swift`); milestone 3 made the world real
/// (`Rules/WorldRules.swift`). All that's left here is a placeholder combat round and a debug
/// mote, both of which milestone 4 and 5 take over. This file should end up deleted.
extension GameStore {

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
            if encounter.isResolved { encounter.log.append("Nothing left standing.") }
            run.activeEncounter = encounter
            state.worlds.activeRun = run

            // Takes the defeated off the grid; without it the same fight re-triggers next turn.
            WorldRules.concludeEncounter(in: &state)

            // No death state in v0 — running out of health ends the run with a partial haul.
            if state.worlds.activeRun?.binderHP ?? 1 <= 0 {
                state.worlds.activeRun?.activeEncounter = nil
            }
        }
        if state.worlds.activeRun?.binderHP ?? 1 <= 0 {
            endRunWithPartialHaul(reason: "You can't go on.")
        }
    }

    // MARK: Reality layer

    func harnessGainMote() {
        mutate("found a mote", flush: true) { $0.reality.motes += 1 }
    }
}
