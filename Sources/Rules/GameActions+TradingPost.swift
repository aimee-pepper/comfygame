import Foundation

extension GameStore {
    func commitTradingPostPhysicalGearSale(
        _ quote: TradingPostPhysicalGearSaleQuoteV1
    ) -> TradingPostPhysicalGearCommitResultV1 {
        var result: TradingPostPhysicalGearCommitResultV1 = .refused(.staleQuote)
        mutateIf("trading post physical gear sale", flush: true) { state in
            result = TradingPostRules.commitPhysicalGearSale(quote, in: &state)
            return result == .committed
        }
        return result
    }

    func commitTradingPostPhysicalGearPurchase(
        _ quote: TradingPostPhysicalGearPurchaseQuoteV1
    ) -> TradingPostPhysicalGearCommitResultV1 {
        var result: TradingPostPhysicalGearCommitResultV1 = .refused(.staleQuote)
        mutateIf("trading post physical gear purchase", flush: true) { state in
            result = TradingPostRules.commitPhysicalGearPurchase(quote, in: &state)
            return result == .committed
        }
        return result
    }

    /// Consumes the campaign-wide receipt inside the atomic return mutation, so each resolved
    /// expedition advances stock exactly once, including anchored revisits.
    nonisolated static func refreshTradingPost(after run: WorldRun, outcomeID: ExpeditionOutcomeID,
                                               in state: inout GameState) {
        TradingPostRules.refresh(after: outcomeID, campaignSeed: run.mapSeed, in: &state.base)
    }

    @discardableResult
    func buyFromTradingPost(lineID: UInt64, quantity: Int,
                            expectedRevision: UInt64) -> TradingPostCommitResult {
        var result: TradingPostCommitResult = .invalid
        mutate("trading post purchase", flush: true) { state in
            guard state.base.tradingPost.inventoryRevision == expectedRevision else {
                result = .stale
                return
            }
            guard let preview = TradingPostRules.previewPurchase(
                lineID: lineID, quantity: quantity, in: state.base
            ) else {
                result = .unaffordable
                return
            }
            result = TradingPostRules.commit(preview, in: &state.base)
        }
        return result
    }

    @discardableResult
    func buyEssenceFromTradingPost(bundles: Int,
                                   expectedRevision: UInt64) -> TradingPostCommitResult {
        var result: TradingPostCommitResult = .invalid
        mutate("trading post essence purchase", flush: true) { state in
            guard state.base.tradingPost.inventoryRevision == expectedRevision else {
                result = .stale
                return
            }
            guard let preview = TradingPostRules.previewEssencePurchase(bundles: bundles, in: state.base) else {
                result = .unaffordable
                return
            }
            result = TradingPostRules.commit(preview, in: &state.base)
        }
        return result
    }

    @discardableResult
    func sellAtTradingPost(resources: [ResourceID: Int],
                           items: [TradingPostItemSaleRequest] = [], essence: Int = 0,
                           expectedRevision: UInt64) -> TradingPostCommitResult {
        var result: TradingPostCommitResult = .invalid
        mutate("trading post sale", flush: true) { state in
            guard state.base.tradingPost.inventoryRevision == expectedRevision else {
                result = .stale
                return
            }
            guard let preview = TradingPostRules.previewSale(
                resources: resources, items: items, essence: essence, in: state.base
            ) else { return }
            result = TradingPostRules.commit(preview, in: &state.base)
        }
        return result
    }
}
