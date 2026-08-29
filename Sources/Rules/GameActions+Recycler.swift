import Foundation

extension GameStore {
    var recyclerServiceTier: Int {
        // A built tier-0 station is the first usable service tier; its two upgrades map to 2 and 3.
        min(3, max(1, state.base.station(Stations.recycler).tier + 1))
    }

    func recyclerPreviews() -> [RecyclerPreview] {
        guard state.worlds.activeRun == nil,
              state.base.station(Stations.recycler).isUnlocked else { return [] }
        let base = state.base
        let tier = recyclerServiceTier
        let stored = base.inventory.stacks.compactMap {
            if $0.gearProfile?.physicalReceipt != nil {
                return RecyclerRules.previewPhysicalReceipt(
                    location: .stored, stackID: $0.id, in: state)
            }
            return RecyclerRules.preview(location: .stored, stackID: $0.id,
                                         serviceTier: tier, in: base)
        }
        let waiting = base.spillover.compactMap {
            if $0.gearProfile?.physicalReceipt != nil {
                return RecyclerRules.previewPhysicalReceipt(
                    location: .overflow, stackID: $0.id, in: state)
            }
            return RecyclerRules.preview(location: .overflow, stackID: $0.id,
                                         serviceTier: tier, in: base)
        }
        return stored + waiting
    }

    @discardableResult
    func recycle(_ preview: RecyclerPreview) -> RecyclerCommitResult {
        var candidate = state
        let result: RecyclerCommitResult
        if preview.route == .constructionReceipt {
            result = RecyclerRules.commitPhysicalReceipt(preview, in: &candidate)
        } else {
            guard candidate.worlds.activeRun == nil,
                  candidate.base.station(Stations.recycler).isUnlocked else { return .invalid }
            result = RecyclerRules.commit(preview, in: &candidate.base)
        }
        guard result == .committed else { return result }
        mutate("recycle \(preview.stackID.rawValue)", flush: true) { state in
            state = candidate
        }
        return result
    }
}
