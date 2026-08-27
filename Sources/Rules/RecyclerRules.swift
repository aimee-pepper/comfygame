import Foundation

enum RecyclerRules {
    enum Ineligibility: String, CaseIterable, Hashable, Sendable {
        case stacked, unidentified, favorite, locked, equipped, notGear, unique, apex
        case narrative, channelworks, legacyCredit, noRecoveryProfile

        var explanation: String {
            switch self {
            case .stacked: "Separate this stack before dismantling one piece."
            case .unidentified: "Identify it before deciding what should be recovered."
            case .favorite: "Favorite pieces are protected. Remove Favorite first."
            case .locked: "Locked pieces are protected. Unlock it first."
            case .equipped: "Worn gear must be taken off before dismantling."
            case .notGear: "The Recycler accepts eligible gear, not other belongings."
            case .unique: "One-of-a-kind gear cannot be dismantled."
            case .apex: "Apex gear cannot be dismantled."
            case .narrative: "Story items remain intact."
            case .channelworks: "This belongs at Channelworks and cannot be dismantled here."
            case .legacyCredit: "Gear with power carried forward from an older save stays protected until you rebuild it at the Armoury."
            case .noRecoveryProfile: "This piece has no recorded construction stock or standard salvage."
            }
        }
    }

    enum SalvageOutput: Equatable, Sendable {
        case resource(ResourceID)
        case reclaimedHide
    }

    struct SalvageProfile: Equatable, Sendable {
        var id: String
        var sequence: [SalvageOutput]
    }

    private static let forgedEdge = SalvageProfile(
        id: "forged_edge_v1", sequence: [.resource("ore"), .resource("timber"), .resource("ore")])
    private static let headedTool = SalvageProfile(
        id: "headed_tool_v1", sequence: [.resource("ore"), .resource("timber"), .resource("ore")])
    private static let longHaft = SalvageProfile(
        id: "long_haft_v1", sequence: [.resource("timber"), .resource("ore"), .resource("fiber")])
    private static let board = SalvageProfile(
        id: "board_guard_v1", sequence: [.resource("timber"), .resource("ore"), .resource("fiber")])
    private static let rigidProtection = SalvageProfile(
        id: "rigid_protection_v1", sequence: [.resource("ore"), .resource("fiber"), .resource("ore")])
    private static let paddedProtection = SalvageProfile(
        id: "padded_protection_v1", sequence: [.resource("fiber"), .reclaimedHide, .resource("fiber")])
    private static let boots = SalvageProfile(
        id: "boots_v1", sequence: [.resource("fiber"), .reclaimedHide, .resource("timber")])
    private static let keepsake = SalvageProfile(
        id: "keepsake_v1", sequence: [.resource("pulp"), .resource("fiber"), .resource("quartz")])

    private static let profilesByID: [String: SalvageProfile] = Dictionary(uniqueKeysWithValues: [
        forgedEdge, headedTool, longHaft, board, rigidProtection, paddedProtection, boots, keepsake
    ].map { ($0.id, $0) })

    private static func salvageProfile(for item: ItemDef) -> SalvageProfile? {
        guard item.recyclerDisposition == .recyclable, let id = item.salvageProfileID else { return nil }
        return profilesByID[id]
    }

    static func unprofiledOrdinaryGearIDs(in catalog: ContentCatalog = .shared) -> [ItemID] {
        catalog.items.filter { item in
            item.gear != nil && item.gear?.breaks == nil && salvageProfile(for: item) == nil
        }.map(\.id).sorted { $0.rawValue < $1.rawValue }
    }

    static func invalidCatalogueItemIDs(in catalog: ContentCatalog = .shared) -> [ItemID] {
        catalog.items.filter { !hasValidCatalogueDisposition($0) }
            .map(\.id).sorted { $0.rawValue < $1.rawValue }
    }

    static func hasValidCatalogueDisposition(_ item: ItemDef) -> Bool {
        switch item.recyclerDisposition {
        case .recyclable:
            return item.gear != nil && item.gear?.breaks == nil && salvageProfile(for: item) != nil
        case .protected:
            return item.salvageProfileID == nil
        case .notGear:
            return item.gear == nil && item.salvageProfileID == nil
        }
    }

    static func efficiency(serviceTier: Int) -> Double {
        switch min(3, max(1, serviceTier)) {
        case 1: 0.40
        case 2: 0.55
        default: 0.70
        }
    }

    static func recoveryCapacity(receiptCount: Int, serviceTier: Int) -> Int {
        guard receiptCount >= 2 else { return 0 }
        return max(1, Int(floor(Double(receiptCount) * efficiency(serviceTier: serviceTier))))
    }

    /// Immutable construction-receipt order owns the initial recovery defaults.
    static func defaultReceiptSelection(for samples: [CraftMaterialUnitV1], capacity: Int) -> [Int] {
        Array(samples.indices.prefix(max(0, capacity)))
    }

    static func preview(location: TradingPostItemLocation, stackID: InstanceID,
                        serviceTier: Int, selectedReceiptIndices: [Int]? = nil,
                        in base: BaseState) -> RecyclerPreview? {
        let tier = min(3, max(1, serviceTier))
        guard let stack = stack(stackID, at: location, in: base),
              ineligibility(of: stack) == nil,
              let definition = ContentCatalog.shared.item(stack.catalogID), definition.gear != nil else { return nil }

        let receipt = stack.gearProfile?.consumedSamples ?? []
        if !receipt.isEmpty {
            let capacity = recoveryCapacity(receiptCount: receipt.count, serviceTier: tier)
            let selected = selectedReceiptIndices
                ?? defaultReceiptSelection(for: receipt, capacity: capacity)
            guard selected.count <= capacity, Set(selected).count == selected.count,
                  selected.allSatisfy(receipt.indices.contains) else { return nil }
            return RecyclerPreview(revision: base.recycler.inventoryRevision,
                                   location: location, stackID: stackID, snapshot: stack,
                                   serviceTier: tier, route: .constructionReceipt,
                                   selectedReceiptIndices: selected.sorted(), recoveryCapacity: capacity,
                                   returnedSamples: selected.sorted().map { receipt[$0] },
                                   returnedResources: ResourcePool())
        }

        guard let definition = ContentCatalog.shared.item(stack.catalogID),
              let profile = salvageProfile(for: definition) else { return nil }
        let outputCount = switch stack.constructionTier {
        case ...2: 1
        case 3: 2
        default: 3
        }
        var resources = ResourcePool()
        var samples: [CraftMaterialUnitV1] = []
        for output in profile.sequence.prefix(outputCount) {
            switch output {
            case .resource(let id): resources.add(1, of: id)
            case .reclaimedHide: resources.add(1, of: Resources.fiber)
            }
        }
        return RecyclerPreview(revision: base.recycler.inventoryRevision,
                               location: location, stackID: stackID, snapshot: stack,
                               serviceTier: tier, route: .authoredSalvage(profileID: profile.id),
                               selectedReceiptIndices: [], recoveryCapacity: 0,
                               returnedSamples: samples, returnedResources: resources)
    }

    static func ineligibility(of stack: ItemStack) -> Ineligibility? {
        if stack.count != 1 { return .stacked }
        if !stack.identified { return .unidentified }
        if stack.isFavorite { return .favorite }
        if stack.isLocked { return .locked }
        if stack.catalogID == Items.conduitFixture { return .channelworks }
        guard let definition = ContentCatalog.shared.item(stack.catalogID), definition.gear != nil
        else { return .notGear }
        if definition.gear?.breaks != nil { return .apex }
        if let unique = stack.gearProfile?.authoredUniqueRuleID {
            return unique.contains("narrative") ? .narrative : .unique
        }
        if (stack.gearProfile?.legacyPowerCredit ?? 0) > 0 { return .legacyCredit }
        if !(stack.gearProfile?.consumedSamples.isEmpty ?? true) { return nil }
        return salvageProfile(for: definition) == nil ? .noRecoveryProfile : nil
    }

    static func ineligibility(ofEquipped piece: EquippedPiece) -> Ineligibility { .equipped }

    static func commit(_ preview: RecyclerPreview, in base: inout BaseState) -> RecyclerCommitResult {
        guard preview.revision == base.recycler.inventoryRevision else { return .stale }
        let selection: [Int]? = preview.route == .constructionReceipt
            ? preview.selectedReceiptIndices : nil
        guard let current = self.preview(location: preview.location, stackID: preview.stackID,
                                         serviceTier: preview.serviceTier,
                                         selectedReceiptIndices: selection, in: base),
              current == preview else { return .invalid }

        var candidate = base
        let returnedUnits = preview.returnedSamples.enumerated().map { ordinal, sample in
            let id = CraftMaterialUnitID(rawValue: "recycler-\(preview.stackID.rawValue)-\(ordinal)")
            return CraftMaterialHoldingV1(unit: sample.withStableID(id), protectedReturn: false)
        }
        let existingReserveIDs = Set(candidate.craftMaterialSelections().map(\.unitID))
        guard returnedUnits.allSatisfy({ !existingReserveIDs.contains($0.id) }) else {
            return .invalid
        }
        guard remove(preview.stackID, at: preview.location, in: &candidate) else { return .invalid }
        candidate.resources.add(contentsOf: preview.returnedResources)
        for unit in returnedUnits {
            if unit.unit.domain == .world { _ = candidate.worldMaterialReserve.add(unit) }
            else { _ = candidate.creatureMaterialReserve.add(unit) }
        }
        candidate.recycler.inventoryRevision &+= 1
        base = candidate
        return .committed
    }

    private static func stack(_ id: InstanceID, at location: TradingPostItemLocation,
                              in base: BaseState) -> ItemStack? {
        switch location {
        case .stored: base.inventory.stacks.first { $0.id == id }
        case .overflow: base.spillover.first { $0.id == id }
        }
    }

    private static func remove(_ id: InstanceID, at location: TradingPostItemLocation,
                               in base: inout BaseState) -> Bool {
        switch location {
        case .stored:
            guard let index = base.inventory.stacks.firstIndex(where: { $0.id == id }) else { return false }
            base.inventory.stacks.remove(at: index)
        case .overflow:
            guard let index = base.spillover.firstIndex(where: { $0.id == id }) else { return false }
            base.spillover.remove(at: index)
        }
        return true
    }
}
