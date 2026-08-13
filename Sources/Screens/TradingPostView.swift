import SwiftUI

/// The first Trading Post slice deliberately speaks the same compact visual language as owned
/// gear and loot: six identities across, with names, prices and actions behind a tap.
struct TradingPostView: View {
    @EnvironmentObject private var store: GameStore
    @State private var tab: TradingPostTab = .buy
    @State private var opened: TradingPostListing?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                wallet
                Picker("Trading Post section", selection: $tab) {
                    ForEach(TradingPostTab.allCases) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .frame(minHeight: 44)

                if listings.isEmpty {
                    EmptyNote(emptyMessage)
                } else {
                    SixAcrossItemGrid(data: listings, id: \.id) { listing in
                        AnchoredItemDetailButton(item: listing, selection: $opened) {
                            listingTile(listing)
                        } detail: { selected in
                            TradingPostListingSheet(listing: selected).environmentObject(store)
                        }
                    }
                }

                Text(tab == .buy
                     ? "Stock changes after an expedition resolves, never while you browse."
                     : "Only identified, transferable goods appear. Favorites, locked pieces, singular gear and unknown curios stay protected.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Trading Post")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder private func listingTile(_ listing: TradingPostListing) -> some View {
        if let resourceID = listing.action.resourceID {
            ResourceIconTile(resourceID: resourceID, icon: listing.icon,
                             quantity: listing.displayQuantity,
                             accessibilityName: listing.name)
        } else {
            ItemIconTile(icon: listing.icon, catalogueID: listing.catalogueItemID,
                         rarity: listing.rarity,
                         quantity: listing.displayQuantity, identified: true,
                         location: listing.location, accessibilityName: listing.name)
        }
    }

    private var wallet: some View {
        HStack(spacing: 12) {
            Label("\(store.state.base.goldCoins)", systemImage: "circle.hexagongrid.fill")
                .accessibilityLabel("Gold coins, \(store.state.base.goldCoins)")
            Divider().frame(height: 22)
            Label("\(store.state.base.essence)", systemImage: "drop.fill")
                .accessibilityLabel("Essence, \(store.state.base.essence)")
            Spacer()
        }
        .font(.headline.monospacedDigit())
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    private var listings: [TradingPostListing] {
        switch tab {
        case .buy: buyListings
        case .sell: sellListings
        }
    }

    private var buyListings: [TradingPostListing] {
        let base = store.state.base
        var result = base.tradingPost.stock.compactMap { line -> TradingPostListing? in
            guard line.remainingQuantity > 0 else { return nil }
            switch line.kind {
            case .resource(let id):
                let definition = ContentCatalog.shared.resource(id)
                let band = TradingPostRules.tradeBand(for: id) ?? .staple
                return TradingPostListing(id: "stock-\(line.id)", name: definition?.name ?? id.rawValue,
                                          icon: definition?.icon ?? "cube.fill", rarity: band.rarity,
                                          displayQuantity: line.remainingQuantity, maximumQuantity: line.remainingQuantity,
                                          unitQuantity: 1, unitPrice: line.unitPrice, location: .offered,
                                          revision: base.tradingPost.inventoryRevision,
                                          stack: nil,
                                          action: .buyStock(lineID: line.id, kind: line.kind))
            case .item(let id):
                let definition = ContentCatalog.shared.item(id)
                return TradingPostListing(id: "stock-\(line.id)", name: definition?.name ?? id.rawValue,
                                          icon: definition?.icon ?? "shippingbox.fill",
                                          rarity: definition?.rarity ?? .common,
                                          displayQuantity: line.remainingQuantity, maximumQuantity: line.remainingQuantity,
                                          unitQuantity: 1, unitPrice: line.unitPrice, location: .offered,
                                          revision: base.tradingPost.inventoryRevision,
                                          stack: nil,
                                          action: .unavailable,
                                          authoredCatalogueItemID: id)
            case .material(let sample):
                return TradingPostListing(id: "stock-\(line.id)", name: sample.displayName,
                                          icon: "hexagon.fill", rarity: sample.rarity,
                                          displayQuantity: line.remainingQuantity, maximumQuantity: line.remainingQuantity,
                                          unitQuantity: 1, unitPrice: line.unitPrice, location: .offered,
                                          revision: base.tradingPost.inventoryRevision,
                                          stack: nil,
                                          action: .unavailable)
            }
        }
        if base.tradingPost.essenceBundlesRemaining > 0 {
            result.append(TradingPostListing(id: "stock-essence", name: "Refined Essence",
                                             icon: "drop.fill", rarity: .uncommon,
                                             displayQuantity: base.tradingPost.essenceBundlesRemaining,
                                             maximumQuantity: base.tradingPost.essenceBundlesRemaining,
                                             unitQuantity: TradingPostRules.essencePurchaseQuantity,
                                             unitPrice: TradingPostRules.essencePurchasePrice,
                                             location: .offered,
                                             revision: base.tradingPost.inventoryRevision,
                                             stack: nil,
                                             action: .buyEssence))
        }
        return result
    }

    private var sellListings: [TradingPostListing] {
        let base = store.state.base
        let storedItems = sellableItems(base.inventory.stacks, at: .stored)
        let waitingItems = sellableItems(base.spillover, at: .overflow)
        var result = storedItems + waitingItems
        result += base.resources.nonZero.compactMap { entry -> TradingPostListing? in
            guard let band = TradingPostRules.tradeBand(for: entry.id),
                  let price = band.sellPrice else { return nil }
            let definition = ContentCatalog.shared.resource(entry.id)
            return TradingPostListing(id: "sell-\(entry.id.rawValue)",
                                      name: definition?.name ?? entry.id.rawValue,
                                      icon: definition?.icon ?? "cube.fill", rarity: band.rarity,
                                      displayQuantity: entry.amount, maximumQuantity: entry.amount,
                                      unitQuantity: 1, unitPrice: price, location: .stored,
                                      revision: base.tradingPost.inventoryRevision,
                                      stack: nil,
                                      action: .sellResource(entry.id))
        }
        let essenceBundles = base.essence / TradingPostRules.essenceSaleUnit
        if essenceBundles > 0 {
            result.append(TradingPostListing(id: "sell-essence", name: "Refined Essence",
                                             icon: "drop.fill", rarity: .uncommon,
                                             displayQuantity: essenceBundles * TradingPostRules.essenceSaleUnit,
                                             maximumQuantity: essenceBundles,
                                             unitQuantity: TradingPostRules.essenceSaleUnit,
                                             unitPrice: 1, location: .stored,
                                             revision: base.tradingPost.inventoryRevision,
                                             stack: nil,
                                             action: .sellEssence))
        }
        return result
    }

    private func sellableItems(_ stacks: [ItemStack], at location: TradingPostItemLocation)
        -> [TradingPostListing] {
        stacks.compactMap { stack in
            guard let price = TradingPostRules.saleUnitPrice(for: stack) else { return nil }
            let gridLocation: ItemGridLocation = location == .stored ? .stored : .waiting
            let maximum = stack.gearProfile == nil ? stack.count : 1
            return TradingPostListing(id: "sell-\(location.rawValue)-\(stack.id.rawValue)",
                                      name: stack.displayName, icon: stack.icon, rarity: stack.rarity,
                                      displayQuantity: stack.count, maximumQuantity: maximum,
                                      unitQuantity: 1, unitPrice: price, location: gridLocation,
                                      revision: store.state.base.tradingPost.inventoryRevision,
                                      stack: stack,
                                      action: .sellItem(location: location, stackID: stack.id))
        }
    }

    private var emptyMessage: String {
        if tab == .buy && store.state.base.tradingPost.expeditionOutcomeID == nil {
            return "The shelves are waiting for your next expedition to resolve."
        }
        return tab == .buy ? "The shelves are empty until the next expedition." : "Nothing here is currently transferable."
    }
}

private struct TradingPostListingSheet: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss
    let listing: TradingPostListing
    @State private var quantity = 1
    @State private var failure: TradingPostCommitResult?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 16) {
                        Group {
                            if let resourceID = listing.action.resourceID {
                                ResourceIconTile(resourceID: resourceID, icon: listing.icon,
                                                 quantity: listing.displayQuantity,
                                                 accessibilityName: listing.name)
                            } else {
                                ItemIconTile(icon: listing.icon,
                                             catalogueID: listing.catalogueItemID,
                                             rarity: listing.rarity,
                                             quantity: listing.displayQuantity, identified: true,
                                             location: listing.location, accessibilityName: listing.name)
                            }
                        }
                        .frame(width: 58, height: 58)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(listing.name).font(.headline).foregroundStyle(listing.rarity.tint)
                            Text(listing.action.isPurchase ? "For sale" : "From your stores")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                Section("Trade") {
                    LabeledContent("Location", value: listing.location.displayName)
                    Stepper(value: $quantity, in: 1...listing.maximumQuantity) {
                        LabeledContent("Quantity", value: "\(quantity * listing.unitQuantity)")
                    }
                    LabeledContent("Price", value: priceLabel)
                    if listing.unitQuantity > 1 {
                        Text("Each trade unit contains \(listing.unitQuantity) Essence.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    if let failure {
                        Text(failure.message)
                            .font(.caption).foregroundStyle(.red)
                            .accessibilityIdentifier("trading-post.failure")
                    }
                }
                if let stack = listing.stack {
                    Section("Details") {
                        if let profile = stack.gearProfile {
                            LabeledContent("Power", value: profile.effectivePower.formatted(.number.precision(.fractionLength(0...1))))
                            LabeledContent("Construction tier", value: "\(profile.constructionTier)")
                            LabeledContent("Reforge", value: "\(profile.reforgeRank) of \(SmithRules.maximumReforgeLevel)")
                            if let provenance = profile.displayProvenance {
                                LabeledContent("Provenance", value: provenance)
                            }
                        } else if let definition = ContentCatalog.shared.item(stack.catalogID),
                                  !definition.blurb.isEmpty {
                            Text(definition.blurb)
                        }
                    }
                }
                Section {
                    Button(actionTitle) { commit() }
                        .disabled(!listing.action.isAvailable || cannotAfford)
                        .frame(minHeight: 44)
                } footer: {
                    if !listing.action.isAvailable {
                        Text("This stock is visible, but its capacity-safe purchase path is not available yet.")
                    } else if cannotAfford {
                        Text("You need \(totalPrice - store.state.base.goldCoins) more gold.")
                    } else {
                        Text("The exact stock and price will be checked again before anything changes.")
                    }
                }
            }
            .navigationTitle(listing.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
    }

    private var totalPrice: Int { quantity * listing.unitPrice }
    private var cannotAfford: Bool { listing.action.isPurchase && store.state.base.goldCoins < totalPrice }
    private var priceLabel: String {
        listing.action.isPurchase ? "\(totalPrice) gold" : "+\(totalPrice) gold"
    }
    private var actionTitle: String {
        listing.action.isPurchase ? "Buy for \(totalPrice) gold" : "Sell for \(totalPrice) gold"
    }

    private func commit() {
        let result: TradingPostCommitResult
        switch listing.action {
        case .buyStock(let lineID, _):
            result = store.buyFromTradingPost(lineID: lineID, quantity: quantity,
                                              expectedRevision: listing.revision)
        case .buyEssence:
            result = store.buyEssenceFromTradingPost(bundles: quantity,
                                                     expectedRevision: listing.revision)
        case .sellResource(let id):
            result = store.sellAtTradingPost(resources: [id: quantity], essence: 0,
                                             expectedRevision: listing.revision)
        case .sellEssence:
            result = store.sellAtTradingPost(resources: [:],
                                             essence: quantity * listing.unitQuantity,
                                             expectedRevision: listing.revision)
        case .sellItem(let location, let stackID):
            result = store.sellAtTradingPost(
                resources: [:],
                items: [TradingPostItemSaleRequest(location: location, stackID: stackID,
                                                   quantity: quantity)],
                essence: 0,
                expectedRevision: listing.revision)
        case .unavailable:
            result = .invalid
        }
        if result == .committed { dismiss() } else { failure = result }
    }
}

private enum TradingPostTab: String, CaseIterable, Identifiable {
    case buy, sell
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

private struct TradingPostListing: Identifiable {
    enum Action {
        case buyStock(lineID: UInt64, kind: TradingPostStockLine.Kind)
        case buyEssence
        case sellResource(ResourceID)
        case sellEssence
        case sellItem(location: TradingPostItemLocation, stackID: InstanceID)
        case unavailable

        var isPurchase: Bool {
            switch self { case .buyStock, .buyEssence: true; default: false }
        }
        var isAvailable: Bool {
            if case .unavailable = self { return false }
            return true
        }

        var resourceID: ResourceID? {
            switch self {
            case .buyStock(_, let kind):
                if case .resource(let id) = kind { return id }
                return nil
            case .sellResource(let id): return id
            default: return nil
            }
        }
    }

    let id: String
    let name: String
    let icon: String
    let rarity: Rarity
    let displayQuantity: Int
    let maximumQuantity: Int
    let unitQuantity: Int
    let unitPrice: Int
    let location: ItemGridLocation
    let revision: UInt64
    let stack: ItemStack?
    let action: Action
    var authoredCatalogueItemID: ItemID? = nil

    var catalogueItemID: ItemID? { authoredCatalogueItemID ?? stack?.catalogID }
}

private extension TradingPostTradeBand {
    var rarity: Rarity {
        switch self {
        case .staple, .nontradeable: .common
        case .uncommon: .uncommon
        case .rare: .rare
        case .precious: .mythic
        }
    }
}

private extension TradingPostCommitResult {
    var message: String {
        switch self {
        case .committed: "Trade complete."
        case .stale: "The stock changed. Close this detail and choose again."
        case .invalid: "Those goods are no longer available in that quantity."
        case .unaffordable: "You no longer have enough gold."
        }
    }
}
