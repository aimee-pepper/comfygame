import Foundation

enum TradingPostRules {
    struct MaterialSalePreview: Equatable, Sendable {
        var revision: UInt64
        var selections: [CraftMaterialSelection]
        var unitPrices: [Int]
        var goldTotal: Int
    }

    static let essenceSaleUnit = 10
    static let essencePurchaseQuantity = 10
    static let essencePurchasePrice = 8

    static func tradeBand(for resource: ResourceID,
                          in catalog: ContentCatalog = .shared) -> TradingPostTradeBand? {
        catalog.resource(resource)?.tradeBand
    }

    static func isAuthoredTransferable(_ item: ItemID,
                                       in catalog: ContentCatalog = .shared) -> Bool {
        catalog.item(item)?.tradingPostDisposition == .sellable
    }

    static func saleUnitPrice(for stack: ItemStack, catalog: ContentCatalog = .shared) -> Int? {
        guard stack.identified, !stack.isLocked, !stack.isFavorite,
              isAuthoredTransferable(stack.catalogID, in: catalog),
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
    static func refresh(after outcomeID: ExpeditionOutcomeID, campaignSeed: UInt64,
                        in base: inout BaseState, catalog: ContentCatalog = .shared) -> Bool {
        guard base.tradingPost.expeditionOutcomeID != outcomeID else { return false }
        var post = base.tradingPost
        if post.campaignSeed == nil { post.campaignSeed = campaignSeed }
        post.refreshSequence &+= 1
        var rng = SeededRNG(seed: post.campaignSeed ?? campaignSeed)
            .derived(post.refreshSequence ^ 0x5452_4144_4550_4F53)

        let available = Set(catalog.resources.map(\.id))
        let staples = catalog.resources.compactMap {
            $0.tradeBand == .staple && available.contains($0.id) ? $0.id : nil
        }
            .sorted { $0.rawValue < $1.rawValue }
        let uncommon = catalog.resources.compactMap {
            $0.tradeBand == .uncommon && available.contains($0.id) ? $0.id : nil
        }
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
            guard let price = tradeBand(for: id, in: catalog)?.buyPrice else { return }
            lines.append(TradingPostStockLine(id: post.nextStockLineID, kind: .resource(id),
                                              remainingQuantity: quantity, unitPrice: price))
            post.nextStockLineID &+= 1
        }
        for id in chosen(staples, count: rng.int(in: 3...5)) { append(id, quantity: rng.int(in: 3...8)) }
        for id in chosen(uncommon, count: rng.int(in: 0...2)) { append(id, quantity: rng.int(in: 1...3)) }

        var nextItemID = base.nextItemID()
        func mint(_ catalogID: ItemID, count: Int = 1) -> [ItemStack] {
            (0..<count).map { _ in
                defer { nextItemID &+= 1 }
                return ItemStack(id: InstanceID(rawValue: nextItemID), catalogID: catalogID)
            }
        }
        func append(kind: TradingPostStockLine.Kind, quantity: Int, unitPrice: Int,
                    units: [ItemStack], materialUnits: [CraftMaterialUnitV1] = []) {
            lines.append(.init(id: post.nextStockLineID, kind: kind,
                               remainingQuantity: quantity, unitPrice: unitPrice,
                               frozenUnits: units, frozenMaterialUnits: materialUnits))
            post.nextStockLineID &+= 1
        }

        let physicalKinds = MaterialFamilyID.allCases.filter { CraftMaterialDomain.forFamily($0) == .creature }
        for kind in chosenMaterialKinds(physicalKinds, count: rng.int(in: 0...2), rng: &rng) {
            let pair = merchantPropertyPair(for: kind)
            var properties = MaterialProperties()
            properties[pair.0] = Double(rng.int(in: 30...39))
            properties[pair.1] = Double(rng.int(in: 15...29))
            for property in MaterialProperty.allCases where property != pair.0 && property != pair.1 {
                properties[property] = Double(rng.int(in: 0...14))
            }
            let sample = CraftMaterialUnitFactory.merchant(kind: kind, properties: properties)
                .withStableID(.init(rawValue: "trading-post-\(nextItemID)"))
            guard let salePrice = materialSaleUnitPrice(for: sample) else { continue }
            append(kind: .material(sample), quantity: 1,
                   unitPrice: salePrice + 1,
                   units: [], materialUnits: [sample])
        }

        let knownConsumables = base.knownConsumableRecipes.compactMap { id -> ItemDef? in
            guard let item = catalog.item(id), item.kind == .consumable,
                  item.rarity == .common || item.rarity == .uncommon else { return nil }
            return item
        }.sorted { $0.id.rawValue < $1.id.rawValue }
        for item in chosenItems(knownConsumables, count: rng.int(in: 0...2), rng: &rng) {
            let quantity = rng.int(in: 1...2)
            let units = mint(item.id, count: quantity)
            let price = (saleUnitPrice(for: units[0], catalog: catalog) ?? 0) * 3
            append(kind: .item(item.id), quantity: quantity, unitPrice: price,
                   units: units)
        }

        let ownsWeapon = ownsCampaignWeapon(base)
        let equipment = catalog.items.filter { item in
            guard let gear = item.gear else { return false }
            return gear.tier == 1 && gear.breaks == nil
                && item.tradingPostDisposition == .sellable
                && (ownsWeapon || gear.slot == .weapon)
        }.sorted { $0.id.rawValue < $1.id.rawValue }
        if let item = chosenItems(equipment, count: 1, rng: &rng).first {
            let units = mint(item.id)
            let price = (saleUnitPrice(for: units[0], catalog: catalog) ?? 0) * 3
            append(kind: .item(item.id), quantity: 1, unitPrice: price, units: units)
        }

        post.stock = lines
        post.essenceBundlesRemaining = rng.chance(0.35) ? rng.int(in: 1...3) : 0
        post.expeditionOutcomeID = outcomeID
        post.inventoryRevision &+= 1
        base.tradingPost = post
        return true
    }

    private static func chosenItems<T>(_ source: [T], count: Int,
                                       rng: inout SeededRNG) -> [T] {
        var remaining = source
        var result: [T] = []
        for _ in 0..<min(count, remaining.count) {
            result.append(remaining.remove(at: rng.int(in: 0...(remaining.count - 1))))
        }
        return result
    }

    private static func chosenMaterialKinds(_ source: [MaterialFamilyID], count: Int,
                                            rng: inout SeededRNG) -> [MaterialFamilyID] {
        chosenItems(source, count: count, rng: &rng)
    }

    private static func merchantPropertyPair(for kind: MaterialFamilyID) -> (MaterialProperty, MaterialProperty) {
        switch kind {
        case .plate, .chitin, .scale, .shell, .bone, .tusk, .horn: (.hardness, .density)
        case .fang, .claw: (.hardness, .reactivity)
        case .quill, .feather, .fin: (.flexibility, .hardness)
        case .pelt, .down: (.insulation, .flexibility)
        case .hide: (.flexibility, .hardness)
        case .timber: (.density, .hardness)
        case .fibre: (.flexibility, .insulation)
        case .pulp: (.flexibility, .reactivity)
        case .ichor, .oil, .venom, .toxin, .reagent: (.reactivity, .density)
        }
    }

    private static func ownsCampaignWeapon(_ base: BaseState) -> Bool {
        let stored = base.inventory.stacks + base.spillover
        if stored.contains(where: { ContentCatalog.shared.item($0.catalogID)?.gear?.slot == .weapon }) {
            return true
        }
        if base.binderEquipped[.weapon] != nil { return true }
        return base.roster.contains { $0.equipped[.weapon] != nil }
    }

    static func previewSale(resources requested: [ResourceID: Int],
                            items itemRequests: [TradingPostItemSaleRequest] = [], essence: Int = 0,
                            in base: BaseState) -> TradingPostSalePreview? {
        guard essence >= 0, essence % essenceSaleUnit == 0,
              base.essenceCrystalCount >= essence else { return nil }
        var lines: [TradingPostSalePreview.ResourceLine] = []
        var total = essence / essenceSaleUnit
        for (id, quantity) in requested.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            guard quantity > 0, base.resources[id] >= quantity,
                  let price = tradeBand(for: id)?.sellPrice else { return nil }
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
        guard base.spendEssenceCrystals(preview.essenceQuantity) else { return .invalid }
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
        switch line.kind {
        case .resource: break
        case .item:
            guard line.frozenUnits.count >= quantity else { return nil }
        case .material:
            guard line.frozenMaterialUnits.count >= quantity else { return nil }
        }
        let cost = quantity * line.unitPrice
        guard base.goldCoins >= cost else { return nil }
        return .init(revision: base.tradingPost.inventoryRevision, kind: .stock(lineID: lineID, kind: line.kind),
                     quantity: quantity, goldCost: cost,
                     frozenUnits: Array(line.frozenUnits.prefix(quantity)),
                     frozenMaterialUnits: Array(line.frozenMaterialUnits.prefix(quantity)))
    }

    static func materialSaleUnitPrice(for sample: CraftMaterialUnitV1) -> Int? {
        guard let base = materialFamilyBaseValue(sample.familyID),
              let pair = commercialCapabilities(for: sample.familyID),
              sample.properties.values.allSatisfy({ $0.isFinite && (0...100).contains($0) })
        else { return nil }
        let capabilityCount = [sample.properties[pair.0], sample.properties[pair.1]]
            .filter { $0 >= 60 }.count
        return base + capabilityCount
    }

    private static func materialFamilyBaseValue(_ kind: MaterialFamilyID) -> Int? {
        switch kind {
        case .hide, .down, .feather, .fin, .bone: 1
        case .pelt, .scale, .quill, .fang, .claw, .oil: 2
        case .plate, .chitin, .shell, .tusk, .horn, .venom: 3
        case .ichor: 4
        case .timber, .fibre, .pulp, .toxin, .reagent: nil
        }
    }

    private static func commercialCapabilities(for kind: MaterialFamilyID) -> (MaterialProperty, MaterialProperty)? {
        switch kind {
        case .hide: (.flexibility, .hardness)
        case .down: (.insulation, .flexibility)
        case .feather: (.flexibility, .lustre)
        case .fin: (.flexibility, .insulation)
        case .bone: (.density, .hardness)
        case .pelt: (.insulation, .flexibility)
        case .scale, .quill, .claw: (.hardness, .flexibility)
        case .fang: (.hardness, .reactivity)
        case .oil: (.insulation, .reactivity)
        case .plate, .chitin, .shell: (.hardness, .density)
        case .tusk, .horn: (.density, .hardness)
        case .venom, .ichor: (.reactivity, .lustre)
        case .timber, .fibre, .pulp, .toxin, .reagent: nil
        }
    }

    /// Quotes only the exact reserve units the player selected. There is intentionally no
    /// "best" or automatic material selection: provenance and capabilities are part of the choice.
    static func previewMaterialSale(_ selections: [CraftMaterialSelection],
                                    in base: BaseState) -> MaterialSalePreview? {
        guard !selections.isEmpty,
              Set(selections.map(\.unitID)).count == selections.count else { return nil }
        let current = Dictionary(uniqueKeysWithValues: base.craftMaterialSelections().map { ($0.unitID, $0.unit) })
        guard selections.allSatisfy({ current[$0.unitID] == $0.unit }) else { return nil }
        let prices = selections.compactMap { materialSaleUnitPrice(for: $0.sample) }
        guard prices.count == selections.count else { return nil }
        return MaterialSalePreview(revision: base.tradingPost.inventoryRevision,
                                   selections: selections, unitPrices: prices,
                                   goldTotal: prices.reduce(0, +))
    }

    static func commit(_ preview: MaterialSalePreview,
                       in base: inout BaseState) -> TradingPostCommitResult {
        guard preview.revision == base.tradingPost.inventoryRevision else { return .stale }
        guard let fresh = previewMaterialSale(preview.selections, in: base), fresh == preview
        else { return .invalid }

        var candidate = base
        guard candidate.consumeCraftMaterials(preview.selections) != nil else { return .invalid }
        var nextItemID = candidate.nextItemID()
        for selection in preview.selections {
            let lineID = candidate.tradingPost.nextStockLineID
            guard let salePrice = materialSaleUnitPrice(for: selection.sample) else { return .invalid }
            let repurchasePrice = salePrice + 1
            candidate.tradingPost.stock.append(TradingPostStockLine(
                id: lineID, kind: .material(selection.sample), remainingQuantity: 1,
                unitPrice: repurchasePrice, frozenMaterialUnits: [selection.sample]))
            candidate.tradingPost.nextStockLineID &+= 1
            nextItemID &+= 1
        }
        candidate.goldCoins += preview.goldTotal
        candidate.tradingPost.inventoryRevision &+= 1
        base = candidate
        return .committed
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
                  preview.goldCost == base.tradingPost.stock[index].unitPrice * preview.quantity,
                  preview.frozenUnits == Array(base.tradingPost.stock[index].frozenUnits.prefix(preview.quantity)),
                  preview.frozenMaterialUnits == Array(base.tradingPost.stock[index].frozenMaterialUnits.prefix(preview.quantity))
            else { return .invalid }
            switch kind {
            case .resource(let id): base.resources.add(preview.quantity, of: id)
            case .item:
                guard preview.frozenUnits.count == preview.quantity else { return .invalid }
                for unit in preview.frozenUnits { base.store(unit) }
                base.tradingPost.stock[index].frozenUnits.removeFirst(preview.quantity)
            case .material:
                guard preview.frozenMaterialUnits.count == preview.quantity else { return .invalid }
                let exactUnits = preview.frozenMaterialUnits.map {
                    CraftMaterialHoldingV1(unit: $0, protectedReturn: false)
                }
                guard Set(exactUnits.map(\.id)).count == exactUnits.count else { return .invalid }
                let existingReserveIDs = Set(base.craftMaterialSelections().map(\.unitID))
                guard exactUnits.allSatisfy({ !existingReserveIDs.contains($0.id) }) else {
                    return .invalid
                }
                for unit in exactUnits {
                    if unit.unit.domain == .world { _ = base.worldMaterialReserve.add(unit) }
                    else { _ = base.creatureMaterialReserve.add(unit) }
                }
                base.tradingPost.stock[index].frozenMaterialUnits.removeFirst(preview.quantity)
            }
            base.tradingPost.stock[index].remainingQuantity -= preview.quantity
        case .essence:
            guard base.tradingPost.essenceBundlesRemaining >= preview.quantity,
                  preview.goldCost == preview.quantity * essencePurchasePrice else { return .invalid }
            base.tradingPost.essenceBundlesRemaining -= preview.quantity
            base.addEssenceCrystals(preview.quantity * essencePurchaseQuantity)
        }
        base.goldCoins -= preview.goldCost
        base.tradingPost.inventoryRevision &+= 1
        return .committed
    }
}
