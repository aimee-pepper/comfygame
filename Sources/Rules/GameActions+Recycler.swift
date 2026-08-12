import Foundation

extension GameStore {
    var recyclerServiceTier: Int {
        // A built tier-0 station is the first usable service tier; its two upgrades map to 2 and 3.
        min(3, max(1, state.base.station(Stations.recycler).tier + 1))
    }

    func recyclerPreviews() -> [RecyclerPreview] {
        let base = state.base
        let tier = recyclerServiceTier
        let stored = base.inventory.stacks.compactMap {
            RecyclerRules.preview(location: .stored, stackID: $0.id, serviceTier: tier, in: base)
        }
        let waiting = base.spillover.compactMap {
            RecyclerRules.preview(location: .overflow, stackID: $0.id, serviceTier: tier, in: base)
        }
        return stored + waiting
    }

    @discardableResult
    func recycle(_ preview: RecyclerPreview) -> RecyclerCommitResult {
        var candidate = state.base
        let result = RecyclerRules.commit(preview, in: &candidate)
        guard result == .committed else { return result }
        mutate("recycle \(preview.stackID.rawValue)", flush: true) { state in
            state.base = candidate
        }
        return result
    }
}
