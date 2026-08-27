import SwiftUI

#if DEBUG
@MainActor enum P3SafeSpaceMeasurement {
    static var isArmed = false
    static var frames: [String: CGRect] = [:]
    static var identities: [String: String] = [:]
    static func reset() { frames = [:]; identities = [:] }
}

struct P3SafeSpaceProbe: View {
    let key: String
    let identity: String?
    init(_ key: String, identity: String? = nil) { self.key = key; self.identity = identity }
    var body: some View {
        GeometryReader { proxy in
            let frame = proxy.frame(in: .global)
            Color.clear.onAppear { record(frame) }.onChange(of: frame) { _, value in record(value) }
        }.allowsHitTesting(false)
    }
    private func record(_ frame: CGRect) {
        guard P3SafeSpaceMeasurement.isArmed else { return }
        P3SafeSpaceMeasurement.frames[key] = frame
        if let identity { P3SafeSpaceMeasurement.identities[key] = identity }
    }
}
#endif

enum TradingPostPresentation {
    static let proprietorID: TravellerID = "vance"

    static func resourceName(_ id: ResourceID,
                             catalogue: ContentCatalog = .shared) -> String {
        catalogue.resource(id)?.name ?? "Unknown resource"
    }

    static func itemName(_ id: ItemID,
                         catalogue: ContentCatalog = .shared) -> String {
        catalogue.item(id)?.name ?? "Unknown item"
    }
}

/// The first Trading Post slice deliberately speaks the same compact visual language as owned
/// gear and loot: six identities across, with names, prices and actions behind a tap.
struct TradingPostView: View {
    @EnvironmentObject private var store: GameStore
    @State private var tab: TradingPostTab = .buy
    @State private var opened: TradingPostListing?
    @State private var openedMaterial: TradingPostMaterialListing?

#if DEBUG
    init(debugTab: String = "buy") {
        _tab = State(initialValue: debugTab == "sell" ? .sell : .buy)
    }
#endif

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                proprietorHeader
                wallet
                Picker("Trading Post section", selection: $tab) {
                    ForEach(TradingPostTab.allCases) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .frame(minHeight: 44)

                if tab == .sell && !materialGroups.isEmpty {
                    materialReserve
                }

                if listings.isEmpty && (tab != .sell || materialGroups.isEmpty) {
                    EmptyNote(emptyMessage)
#if DEBUG
                        .background { P3SafeSpaceProbe("trading.main.empty", identity: tab.rawValue) }
#endif
                } else {
                    SixAcrossItemGrid(data: listings, id: \.id) { listing in
                        AnchoredItemDetailButton(item: listing, selection: $opened) {
                            listingTile(listing)
                        } detail: { selected in
                            TradingPostListingSheet(listing: selected).environmentObject(store)
                        }
#if DEBUG
                        .background {
                            if listing.id == listings.first?.id {
                                P3SafeSpaceProbe("trading.main.first", identity: listing.id)
                            }
                            if listing.id == listings.last?.id {
                                P3SafeSpaceProbe("trading.main.last", identity: listing.id)
                            }
                        }
#endif
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
#if DEBUG
        .background { P3SafeSpaceProbe("trading.main.scroll") }
#endif
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Trading Post")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var materialGroups: [(kind: MaterialFamilyID, selections: [CraftMaterialSelection])] {
        MaterialFamilyID.allCases.compactMap { kind in
            let selections = store.state.base.craftMaterialSelections {
                $0.kind == kind && TradingPostRules.materialSaleUnitPrice(for: $0) != nil
            }
            return selections.isEmpty ? nil : (kind, selections)
        }
    }

    private var materialReserve: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Resources").font(.headline)
            ForEach(materialGroups, id: \.kind) { group in
                DisclosureGroup("\(group.kind.displayName) · \(group.selections.count)") {
                    VStack(spacing: 8) {
                        ForEach(group.selections, id: \.unitID) { selection in
                            let unitPrice = TradingPostRules.materialSaleUnitPrice(for: selection.sample)!
                            let listing = TradingPostMaterialListing(
                                selection: selection,
                                revision: store.state.base.tradingPost.inventoryRevision,
                                unitPrice: unitPrice
                            )
                            AnchoredItemDetailButton(item: listing, selection: $openedMaterial) {
                                HStack(spacing: 10) {
                                    CraftMaterialUnitPixelIdentity(kind: selection.sample.kind,
                                                                fallbackColor: selection.sample.rarity.tint)
                                        .frame(width: 32, height: 32)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(selection.sample.displayName).font(.subheadline)
                                        Text(selection.sample.source.isEmpty ? "Source unknown" : selection.sample.source)
                                            .font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text("+\(unitPrice) gold")
                                        .font(.subheadline.monospacedDigit())
                                }
                                .frame(minHeight: 44)
                            } detail: { selected in
                                TradingPostMaterialSaleSheet(listing: selected).environmentObject(store)
                            }
                        }
                    }
                    .padding(.top, 6)
                }
            }
            Text("Materials are reserve-backed Resources and never use Storehouse slots.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    private var proprietorHeader: some View {
        let person = ContentCatalog.shared.traveller(TradingPostPresentation.proprietorID)
        return HStack(spacing: 12) {
            NamedCharacterPixelIdentity(
                travellerID: person?.id,
                fallbackSystemIcon: person?.icon ?? "shippingbox.fill",
                fallbackColor: .orange
            )
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 2) {
                Text(person?.name ?? "Trading Post")
                    .font(.headline)
                Text(person?.calling ?? "Merchant")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
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
                         location: listing.location, accessibilityName: listing.name,
                         gearQualityBand: listing.stack?.gearProfile?.qualityBand)
        }
    }

    private var wallet: some View {
        HStack(spacing: 12) {
            Label("\(store.state.base.goldCoins)", systemImage: "circle.hexagongrid.fill")
                .accessibilityLabel("Gold coins, \(store.state.base.goldCoins)")
            Divider().frame(height: 22)
            Label("\(store.state.base.essenceCrystalCount)", systemImage: "drop.fill")
                .accessibilityLabel("Essence, \(store.state.base.essenceCrystalCount)")
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
                return TradingPostListing(id: "stock-\(line.id)",
                                          name: TradingPostPresentation.resourceName(id),
                                          icon: definition?.icon ?? "cube.fill", rarity: band.rarity,
                                          displayQuantity: line.remainingQuantity, maximumQuantity: line.remainingQuantity,
                                          unitQuantity: 1, unitPrice: line.unitPrice, location: .offered,
                                          revision: base.tradingPost.inventoryRevision,
                                          stack: nil,
                                          action: .buyStock(lineID: line.id, kind: line.kind))
            case .item(let id):
                let definition = ContentCatalog.shared.item(id)
                let frozenUnit = line.frozenUnits.first
                return TradingPostListing(id: "stock-\(line.id)",
                                          name: TradingPostPresentation.itemName(id),
                                          icon: definition?.icon ?? "shippingbox.fill",
                                          rarity: definition?.rarity ?? .common,
                                          displayQuantity: line.remainingQuantity, maximumQuantity: line.remainingQuantity,
                                          unitQuantity: 1, unitPrice: line.unitPrice, location: .offered,
                                          revision: base.tradingPost.inventoryRevision,
                                          stack: frozenUnit,
                                          action: .unavailablePurchase,
                                          authoredCatalogueItemID: id)
            case .material(let sample):
                return TradingPostListing(id: "stock-\(line.id)", name: sample.displayName,
                                          icon: "hexagon.fill", rarity: sample.rarity,
                                          displayQuantity: line.remainingQuantity, maximumQuantity: line.remainingQuantity,
                                          unitQuantity: 1, unitPrice: line.unitPrice, location: .offered,
                                          revision: base.tradingPost.inventoryRevision,
                                          stack: nil,
                                          action: .unavailablePurchase)
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
                                      name: TradingPostPresentation.resourceName(entry.id),
                                      icon: definition?.icon ?? "cube.fill", rarity: band.rarity,
                                      displayQuantity: entry.amount, maximumQuantity: entry.amount,
                                      unitQuantity: 1, unitPrice: price, location: .stored,
                                      revision: base.tradingPost.inventoryRevision,
                                      stack: nil,
                                      action: .sellResource(entry.id))
        }
        let essenceBundles = base.essenceCrystalCount / TradingPostRules.essenceSaleUnit
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

private struct TradingPostMaterialListing: Identifiable {
    let selection: CraftMaterialSelection
    let revision: UInt64
    let unitPrice: Int
    var id: CraftMaterialUnitID { selection.unitID }

    var preview: TradingPostRules.MaterialSalePreview {
        .init(revision: revision, selections: [selection], unitPrices: [unitPrice], goldTotal: unitPrice)
    }
}

private struct TradingPostMaterialSaleSheet: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss
    let listing: TradingPostMaterialListing
    @State private var failure: TradingPostCommitResult?

#if DEBUG
    init(listing: TradingPostMaterialListing, debugFailure: TradingPostCommitResult? = nil) {
        self.listing = listing
        _failure = State(initialValue: debugFailure)
    }
#endif

    var body: some View {
        NavigationStack {
            List {
                Section("Exact resource unit") {
                    LabeledContent("Kind", value: listing.selection.sample.kind.displayName)
                    LabeledContent("Quality", value: listing.selection.sample.qualityBand.displayName)
                    LabeledContent("Source", value: listing.selection.sample.source.isEmpty ? "Unknown" : listing.selection.sample.source)
                    LabeledContent("Qualifier", value: listing.selection.sample.qualifier ?? "None")
                    LabeledContent("Value", value: "+\(price) gold")
#if DEBUG
                        .background { P3SafeSpaceProbe("trading.material.final", identity: listing.id.rawValue) }
#endif
                    if let failure {
                        Text(failure.message).font(.caption).foregroundStyle(.red)
                            .accessibilityIdentifier("trading-post.material-failure")
#if DEBUG
                            .background { P3SafeSpaceProbe("trading.material.final", identity: failure.message) }
#endif
                    }
                }
            }
#if DEBUG
            .background { P3SafeSpaceProbe("trading.material.list") }
#endif
            .safeAreaInset(edge: .bottom, spacing: 0) {
                PersistentActionBar(message: "This exact reserve unit is checked again before anything changes.",
                                    messageTint: failure == nil ? .secondary : .red) {
                    Button("Sell for \(price) gold") { commit() }
                        .buttonStyle(.borderedProminent).controlSize(.large)
                        .frame(maxWidth: .infinity)
                }
#if DEBUG
                .background { P3SafeSpaceProbe("trading.material.action") }
#endif
            }
            .navigationTitle(listing.selection.sample.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
    }

    private var price: Int { listing.unitPrice }

    private func commit() {
        var result: TradingPostCommitResult = .invalid
        store.mutate("trading post material sale", flush: true) { state in
            result = TradingPostRules.commit(listing.preview, in: &state.base)
        }
        if result == .committed { dismiss() } else { failure = result }
    }
}

private struct TradingPostListingSheet: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss
    let listing: TradingPostListing
    @State private var quantity = 1
    @State private var failure: TradingPostCommitResult?

#if DEBUG
    init(listing: TradingPostListing, debugQuantity: Int = 1, debugFailure: Bool = false) {
        self.listing = listing
        _quantity = State(initialValue: debugQuantity)
        _failure = State(initialValue: debugFailure ? .stale : nil)
    }
#endif

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
                                             location: listing.location, accessibilityName: listing.name,
                                             gearQualityBand: listing.stack?.gearProfile?.qualityBand)
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
#if DEBUG
                        .background { P3SafeSpaceProbe("trading.listing.final", identity: listing.id) }
#endif
                    if listing.unitQuantity > 1 {
                        Text("Each trade unit contains \(listing.unitQuantity) Essence.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    if let failure {
                        Text(failure.message)
                            .font(.caption).foregroundStyle(.red)
                            .accessibilityIdentifier("trading-post.failure")
#if DEBUG
                            .background { P3SafeSpaceProbe("trading.listing.final", identity: failure.message) }
#endif
                    }
                }
                if let stack = listing.stack {
                    Section("Details") {
                        if let profile = stack.gearProfile {
                            LabeledContent("Quality", value: GearPresentationCopy.quality(profile))
                            LabeledContent("Power", value: profile.effectivePower.formatted(.number.precision(.fractionLength(0...1))))
                            LabeledContent("Reforge", value: "\(profile.reforgeRank) of \(SmithRules.maximumReforgeLevel)")
#if DEBUG
                                .background {
                                    P3SafeSpaceProbe("trading.listing.final",
                                                     identity: stack.catalogID.rawValue)
                                }
#endif
                            if let provenance = profile.displayProvenance {
                                LabeledContent("History", value: provenance)
                            }
                        } else if let definition = ContentCatalog.shared.item(stack.catalogID),
                                  !definition.blurb.isEmpty {
                            Text(definition.blurb)
#if DEBUG
                                .background {
                                    P3SafeSpaceProbe("trading.listing.final",
                                                     identity: stack.catalogID.rawValue)
                                }
#endif
                        }
                    }
                }
            }
#if DEBUG
            .background { P3SafeSpaceProbe("trading.listing.list") }
#endif
            .safeAreaInset(edge: .bottom, spacing: 0) { tradeActionBar }
            .navigationTitle(listing.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
    }

    private var tradeActionBar: some View {
        PersistentActionBar(message: actionFootnote,
                            messageTint: actionFootnoteIsFailure ? .red : .secondary) {
            Button { commit() } label: {
                Text(actionTitle).frame(maxWidth: .infinity)
            }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!listing.action.isAvailable || cannotAfford)
        }
#if DEBUG
        .background { P3SafeSpaceProbe("trading.listing.action", identity: actionTitle) }
#endif
    }

    private var actionFootnote: String {
        if !listing.action.isAvailable {
            return "You can inspect this stock, but Vance cannot sell it yet."
        }
        if cannotAfford {
            return "You need \(totalPrice - store.state.base.goldCoins) more gold."
        }
        return "Stock and price are checked again before anything changes."
    }

    private var actionFootnoteIsFailure: Bool {
        !listing.action.isAvailable || cannotAfford
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
        case .unavailablePurchase:
            result = .invalid
        }
        if result == .committed { dismiss() } else { failure = result }
    }
}

#if DEBUG
struct P3TradingListingDebugHost: View {
    enum Mode: Equatable { case affordable, unaffordable, unavailable, stored, waiting, quantity, stale }
    let mode: Mode
    private var listing: TradingPostListing {
        let purchase = mode == .affordable || mode == .unaffordable || mode == .quantity || mode == .stale
        let location: ItemGridLocation = mode == .waiting ? .waiting : (mode == .stored ? .stored : .offered)
        let stack = (mode == .stored || mode == .waiting)
            ? ItemStack(id: InstanceID(rawValue: mode == .stored ? 910 : 911),
                        catalogID: "blade_chipped") : nil
        return TradingPostListing(
            id: "p3-\(String(describing: mode))", name: "P3 exact listing", icon: "shippingbox",
            rarity: .common, displayQuantity: mode == .quantity ? 123 : 1,
            maximumQuantity: mode == .quantity ? 123 : 1, unitQuantity: 1,
            unitPrice: mode == .unaffordable ? 10_000 : 1, location: location,
            revision: 0, stack: stack,
            action: mode == .unavailable ? .unavailablePurchase
                : (purchase ? .buyEssence : .sellEssence))
    }
    var body: some View {
        TradingPostListingSheet(listing: listing,
                                debugQuantity: mode == .quantity ? 123 : 1,
                                debugFailure: mode == .stale)
    }
}

struct P3TradingMaterialDebugHost: View {
    @EnvironmentObject private var store: GameStore
    let failure: TradingPostCommitResult?
    var body: some View {
        if let selection = store.state.base.craftMaterialSelections().first(where: {
            TradingPostRules.materialSaleUnitPrice(for: $0.sample) != nil
        }), let unitPrice = TradingPostRules.materialSaleUnitPrice(for: selection.sample) {
            TradingPostMaterialSaleSheet(listing: .init(
                selection: selection,
                revision: store.state.base.tradingPost.inventoryRevision,
                unitPrice: unitPrice),
                debugFailure: failure)
        }
    }
}
#endif

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
        case unavailablePurchase

        var isPurchase: Bool {
            switch self {
            case .buyStock, .buyEssence, .unavailablePurchase: true
            default: false
            }
        }
        var isAvailable: Bool {
            if case .unavailablePurchase = self { return false }
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
