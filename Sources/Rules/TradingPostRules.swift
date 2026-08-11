import Foundation

enum TradingPostRules {
    static let essenceSaleUnit = 10
    static let essencePurchaseQuantity = 10
    static let essencePurchasePrice = 8

    private static let bands: [ResourceID: TradingPostTradeBand] = [
        "rubble": .staple, "clay": .staple, "ore": .staple, "salt": .staple,
        "fiber": .staple, "timber": .staple, "pulp": .staple, "resin": .staple,
        "copper": .uncommon, "quartz": .uncommon, "obsidian": .uncommon,
        "sulfur": .uncommon, "toxin": .uncommon, "spore": .uncommon, "reagent": .uncommon,
        "silver": .rare, "mercury": .rare, "ichor": .rare, "rift_glass": .rare,
        "gold": .precious, "adamant": .precious,
        "essence_raw": .nontradeable, "mote": .nontradeable
    ]

    /// Versioned authored transferability table. Missing catalogue IDs are denied, never inferred
    /// from rarity, order or display name. Apex-rule weapons and progression objects are explicit
    /// members of the denied set below.
    private static let transferableItemIDs: Set<ItemID> = [
        "curio_humming_shard", "curio_bound_knot",
        "salve_lesser", "salve", "salve_greater", "draught_clearing", "draught_quenching",
        "antidote_broad", "stonebark_tonic", "venom", "firebrand", "briar_oil", "flashsalt",
        "solvent", "lure", "stillwater", "waystone", "torch", "farsight_draught",
        "blade_chipped", "blade_keen", "ripping_hook", "the_long_grievance",
        "bone_awl", "raking_edge", "blade_binders", "hairsplitter",
        "field_maul", "banded_mace", "anvilfall", "the_settled_argument",
        "long_pick", "warded_spear", "parting_needle", "the_kept_distance",
        "split_board", "banded_buckler", "tower_guard", "the_unarguable",
        "padded_cap", "ridged_helm", "visored_casque", "crown_of_quiet",
        "guard_padded", "guard_banded", "guard_vault", "the_standing_wall",
        "wrapped_hands", "studded_gloves", "gauntlets_of_hold", "the_sure_hands",
        "worn_boots", "shod_boots", "longstriders", "the_unhurried",
        "bent_pick", "balanced_pick", "corebreaker", "the_willing_edge",
        "pressed_leaf", "cold_compass", "someones_ring", "the_first_page"
    ]
    private static let nontransferableItemIDs: Set<ItemID> = [
        "essence_crystal", "heat_core", "caustic_core", "light_core", "conduit_fixture",
        "cache_key", "anchor_frame",
        "two_natured_blade", "long_fang", "ranked_spear", "rimed_edge",
        "living_hook", "quiet_knife", "bloodletter", "warded_haft"
    ]

    static func tradeBand(for resource: ResourceID) -> TradingPostTradeBand? { bands[resource] }

    static func unclassifiedResourceIDs(in catalog: ContentCatalog = .shared) -> [ResourceID] {
        catalog.resources.map(\.id).filter { bands[$0] == nil }.sorted { $0.rawValue < $1.rawValue }
    }

    static func isAuthoredTransferable(_ item: ItemID) -> Bool { transferableItemIDs.contains(item) }

    static func unclassifiedItemIDs(in catalog: ContentCatalog = .shared) -> [ItemID] {
        catalog.items.map(\.id).filter {
            !transferableItemIDs.contains($0) && !nontransferableItemIDs.contains($0)
        }.sorted { $0.rawValue < $1.rawValue }
    }

    static func saleUnitPrice(for stack: ItemStack, catalog: ContentCatalog = .shared) -> Int? {
        guard stack.identified, !stack.isLocked, !stack.isFavorite,
              transferableItemIDs.contains(stack.catalogID),
              let definition = catalog.item(stack.catalogID) else { return nil }
        if definition.gear != nil {
            guard definition.gear?.breaks == nil,
                  stack.gearProfile?.authoredUniqueRuleID == nil,
                  (stack.gearProfile?.legacyPowerCredit ?? 0) == 0 else { return nil }
            return max(4, Int(floor(4 * stack.effectivePower)))
        }
        return switch definition.rarity {
        case .common: 2
        case .uncommon: 5
        case .rare: 10
        case .mythic: 20
        }
    }

    /// Generates at most once for one durable expedition outcome. The caller supplies a stable
    /// campaign seed; this stream is isolated from worldgen and combat RNG.
    @discardableResult
    static func refresh(after outcomeID: UInt64, campaignSeed: UInt64,
                        in base: inout BaseState, catalog: ContentCatalog = .shared) -> Bool {
        guard base.tradingPost.expeditionOutcomeID != outcomeID else { return false }
        var post = base.tradingPost
        if post.campaignSeed == nil { post.campaignSeed = campaignSeed }
        post.refreshSequence &+= 1
        var rng = SeededRNG(seed: post.campaignSeed ?? campaignSeed)
            .derived(post.refreshSequence ^ 0x5452_4144_4550_4F53)

        let available = Set(catalog.resources.map(\.id))
        let staples = bands.compactMap { $0.value == .staple && available.contains($0.key) ? $0.key : nil }
            .sorted { $0.rawValue < $1.rawValue }
        let uncommon = bands.compactMap { $0.value == .uncommon && available.contains($0.key) ? $0.key : nil }
            .sorted { $0.rawValue < $1.rawValue }

        var lines: [TradingPostStockLine] = []
        func chosen(_ source: [ResourceID], count: Int) -> [ResourceID] {
            var remaining = source
            var result: [ResourceID] = []
            for _ in 0..<min(count, remaining.count) {
                let index = rng.int(in: 0...(remaining.count - 1))
                result.append(remaining.remove(at: index))
            }
            return result
        }
        func append(_ id: ResourceID, quantity: Int) {
            guard let price = bands[id]?.buyPrice else { return }
            lines.append(TradingPostStockLine(id: post.nextStockLineID, kind: .resource(id),
                                              remainingQuantity: quantity, unitPrice: price))
            post.nextStockLineID &+= 1
        }
        for id in chosen(staples, count: rng.int(in: 3...5)) { append(id, quantity: rng.int(in: 3...8)) }
        for id in chosen(uncommon, count: rng.int(in: 0...2)) { append(id, quantity: rng.int(in: 1...3)) }

        post.stock = lines
        post.essenceBundlesRemaining = rng.chance(0.35) ? rng.int(in: 1...3) : 0
        post.expeditionOutcomeID = outcomeID
        post.inventoryRevision &+= 1
        base.tradingPost = post
        return true
    }

    static func previewSale(resources requested: [ResourceID: Int],
                            items itemRequests: [TradingPostItemSaleRequest] = [], essence: Int = 0,
                            in base: BaseState) -> TradingPostSalePreview? {
        guard essence >= 0, essence % essenceSaleUnit == 0, base.essence >= essence else { return nil }
        var lines: [TradingPostSalePreview.ResourceLine] = []
        var total = essence / essenceSaleUnit
        for (id, quantity) in requested.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            guard quantity > 0, base.resources[id] >= quantity,
                  let price = bands[id]?.sellPrice else { return nil }
            lines.append(.init(id: id, quantity: quantity, unitPrice: price))
            total += quantity * price
        }
        var itemLines: [TradingPostSalePreview.ItemLine] = []
        var seen = Set<String>()
        for request in itemRequests.sorted(by: {
            if $0.location != $1.location { return $0.location.rawValue < $1.location.rawValue }
            return $0.stackID.rawValue < $1.stackID.rawValue
        }) {
            let key = "\(request.location.rawValue)-\(request.stackID.rawValue)"
            guard seen.insert(key).inserted, request.quantity > 0,
                  let stack = stack(request.stackID, at: request.location, in: base),
                  stack.count >= request.quantity,
                  let price = saleUnitPrice(for: stack) else { return nil }
            if stack.gearProfile != nil && request.quantity != 1 { return nil }
            itemLines.append(.init(location: request.location, stackID: request.stackID,
                                   quantity: request.quantity, unitPrice: price, snapshot: stack))
            total += request.quantity * price
        }
        guard total > 0 else { return nil }
        return TradingPostSalePreview(revision: base.tradingPost.inventoryRevision,
                                      resources: lines, items: itemLines,
                                      essenceQuantity: essence, goldTotal: total)
    }

    static func commit(_ preview: TradingPostSalePreview, in base: inout BaseState) -> TradingPostCommitResult {
        guard preview.revision == base.tradingPost.inventoryRevision else { return .stale }
        let itemRequests = preview.items.map {
            TradingPostItemSaleRequest(location: $0.location, stackID: $0.stackID, quantity: $0.quantity)
        }
        guard let current = previewSale(resources: Dictionary(uniqueKeysWithValues:
            preview.resources.map { ($0.id, $0.quantity) }), items: itemRequests,
                                  essence: preview.essenceQuantity, in: base),
              current == preview else { return .invalid }
        var inventory = base.inventory
        var overflow = base.spillover
        for line in preview.items {
            switch line.location {
            case .stored:
                guard remove(line.quantity, stackID: line.stackID, from: &inventory) else { return .invalid }
            case .overflow:
                guard remove(line.quantity, stackID: line.stackID, from: &overflow) else { return .invalid }
            }
        }
        for line in preview.resources {
            guard base.resources.spend(line.quantity, of: line.id) else { return .invalid }
        }
        base.inventory = inventory
        base.spillover = overflow
        base.essence -= preview.essenceQuantity
        base.goldCoins += preview.goldTotal
        base.tradingPost.inventoryRevision &+= 1
        return .committed
    }

    private static func stack(_ id: InstanceID, at location: TradingPostItemLocation,
                              in base: BaseState) -> ItemStack? {
        switch location {
        case .stored: base.inventory.stacks.first { $0.id == id }
        case .overflow: base.spillover.first { $0.id == id }
        }
    }

    private static func remove(_ quantity: Int, stackID: InstanceID, from inventory: inout Inventory) -> Bool {
        guard let index = inventory.stacks.firstIndex(where: { $0.id == stackID }),
              inventory.stacks[index].count >= quantity else { return false }
        _ = inventory.stacks[index].removing(quantity)
        if inventory.stacks[index].isEmpty { inventory.stacks.remove(at: index) }
        return true
    }

    private static func remove(_ quantity: Int, stackID: InstanceID, from stacks: inout [ItemStack]) -> Bool {
        guard let index = stacks.firstIndex(where: { $0.id == stackID }),
              stacks[index].count >= quantity else { return false }
        _ = stacks[index].removing(quantity)
        if stacks[index].isEmpty { stacks.remove(at: index) }
        return true
    }

    static func previewPurchase(lineID: UInt64, quantity: Int,
                                in base: BaseState) -> TradingPostPurchasePreview? {
        guard quantity > 0, let line = base.tradingPost.stock.first(where: { $0.id == lineID }),
              line.remainingQuantity >= quantity else { return nil }
        let cost = quantity * line.unitPrice
        guard base.goldCoins >= cost else { return nil }
        return .init(revision: base.tradingPost.inventoryRevision, kind: .stock(lineID: lineID, kind: line.kind),
                     quantity: quantity, goldCost: cost)
    }

    static func previewEssencePurchase(bundles: Int, in base: BaseState) -> TradingPostPurchasePreview? {
        guard bundles > 0, base.tradingPost.essenceBundlesRemaining >= bundles else { return nil }
        let cost = bundles * essencePurchasePrice
        guard base.goldCoins >= cost else { return nil }
        return .init(revision: base.tradingPost.inventoryRevision, kind: .essence,
                     quantity: bundles, goldCost: cost)
    }

    static func commit(_ preview: TradingPostPurchasePreview,
                       in base: inout BaseState) -> TradingPostCommitResult {
        guard preview.revision == base.tradingPost.inventoryRevision else { return .stale }
        guard base.goldCoins >= preview.goldCost else { return .unaffordable }
        switch preview.kind {
        case .stock(let lineID, let kind):
            guard let index = base.tradingPost.stock.firstIndex(where: { $0.id == lineID }),
                  base.tradingPost.stock[index].kind == kind,
                  base.tradingPost.stock[index].remainingQuantity >= preview.quantity,
                  preview.goldCost == base.tradingPost.stock[index].unitPrice * preview.quantity
            else { return .invalid }
            switch kind {
            case .resource(let id): base.resources.add(preview.quantity, of: id)
            case .item, .material: return .invalid // enabled when capacity-aware item purchasing lands
            }
            base.tradingPost.stock[index].remainingQuantity -= preview.quantity
        case .essence:
            guard base.tradingPost.essenceBundlesRemaining >= preview.quantity,
                  preview.goldCost == preview.quantity * essencePurchasePrice else { return .invalid }
            base.tradingPost.essenceBundlesRemaining -= preview.quantity
            base.essence += preview.quantity * essencePurchaseQuantity
        }
        base.goldCoins -= preview.goldCost
        base.tradingPost.inventoryRevision &+= 1
        return .committed
    }
}
