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

    /// Drop one of every wearable thing into the Storehouse, so the equipping UI can be seen
    /// without first walking to a ruin.
    func harnessGrantGear() {
        mutate("harness: gear", flush: true) { state in
            for item in ContentCatalog.shared.items where item.gear != nil {
                guard !state.base.inventory.stacks.contains(where: { $0.catalogID == item.id }) else { continue }
                state.base.inventory.slots = max(state.base.inventory.slots,
                                                 state.base.inventory.stacks.count + 1)
                state.base.inventory.add(ItemStack(id: InstanceID(rawValue: UInt64(abs(item.id.rawValue.hashValue))),
                                                   catalogID: item.id))
            }
        }
    }

    func harnessGainMote() {
        mutate("found a mote", flush: true) { $0.reality.motes += 1 }
    }
}
