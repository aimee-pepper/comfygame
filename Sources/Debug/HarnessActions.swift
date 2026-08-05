import Foundation

/// The last of the stand-ins.
///
/// Milestone 2 made binding real, milestone 3 the world, milestone 4 combat. All that's left is a
/// debug way to grant a mote, until milestone 5 gives motes real sources (locked caches, Mythic
/// drops, first clears). Then this file goes.
extension GameStore {
    /// Step the analysis axis, so the later description panels can be seen before instruments —
    /// the thing that actually raises it — exist. Wraps back to tier 1.
    func harnessCycleAnalysisTier() {
        mutate("harness: analysis tier", flush: true) { state in
            let next = state.reality.analysisTier + 1
            state.reality.analysisTier = next > Tuning.Analysis.livingTier ? Tuning.Analysis.startingTier : next
        }
    }

    func harnessGainMote() {
        mutate("found a mote", flush: true) { $0.reality.motes += 1 }
    }
}
