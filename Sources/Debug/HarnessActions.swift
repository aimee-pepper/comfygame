import Foundation

/// The last of the stand-ins.
///
/// Milestone 2 made binding real, milestone 3 the world, milestone 4 combat. All that's left is a
/// debug way to grant a mote, until milestone 5 gives motes real sources (locked caches, Mythic
/// drops, first clears). Then this file goes.
extension GameStore {
    func harnessGainMote() {
        mutate("found a mote", flush: true) { $0.reality.motes += 1 }
    }
}
