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
            case .notGear: "The Recycler accepts eligible gear, not ordinary holdings."
            case .unique: "Singular authored gear cannot be dismantled."
            case .apex: "Apex gear keeps its rule and cannot be dismantled."
            case .narrative: "Narrative objects remain intact."
            case .channelworks: "Channelworks objects use their own receipt and cannot be dismantled here."
            case .legacyCredit: "Legacy masterwork credit is protected from irreversible loss."
            case .noRecoveryProfile: "No honest recovery profile or construction receipt exists for this piece."
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

    /// Explicit item-level authorship. Runtime never guesses a recipe from the slot.
    private static let salvageProfiles: [ItemID: SalvageProfile] = {
        var result: [ItemID: SalvageProfile] = [:]
        func assign(_ ids: [ItemID], _ profile: SalvageProfile) {
            for id in ids { result[id] = profile }
        }
        assign(["blade_chipped", "blade_keen", "ripping_hook", "the_long_grievance",
                "bone_awl", "raking_edge", "blade_binders", "hairsplitter",
                "field_maul", "banded_mace", "anvilfall", "the_settled_argument"], forgedEdge)
        assign(["long_pick", "warded_spear", "parting_needle", "the_kept_distance"], longHaft)
        assign(["split_board", "banded_buckler", "tower_guard", "the_unarguable"], board)
        assign(["ridged_helm", "visored_casque", "crown_of_quiet",
                "guard_banded", "guard_vault", "the_standing_wall",
                "studded_gloves", "gauntlets_of_hold", "the_sure_hands"], rigidProtection)
        assign(["padded_cap", "guard_padded", "wrapped_hands"], paddedProtection)
        assign(["worn_boots", "shod_boots", "longstriders", "the_unhurried"], boots)
        assign(["bent_pick", "balanced_pick", "corebreaker", "the_willing_edge"], headedTool)
        assign(["pressed_leaf", "cold_compass", "someones_ring", "the_first_page"], keepsake)
        return result
    }()

    static func unprofiledOrdinaryGearIDs(in catalog: ContentCatalog = .shared) -> [ItemID] {
        catalog.items.filter { item in
            item.gear != nil && item.gear?.breaks == nil && salvageProfiles[item.id] == nil
        }.map(\.id).sorted { $0.rawValue < $1.rawValue }
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

    /// Highest grade first is the honest default available in the current receipt. Recipes do not
    /// yet persist which input satisfied their primary requirement, so this does not fabricate it.
    static func defaultReceiptSelection(for samples: [MaterialSample], capacity: Int) -> [Int] {
        samples.indices.sorted {
            if samples[$0].grade != samples[$1].grade { return samples[$0].grade > samples[$1].grade }
            return $0 < $1
        }.prefix(max(0, capacity)).map { $0 }
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

        guard let profile = salvageProfiles[stack.catalogID] else { return nil }
        let outputCount = switch stack.constructionTier {
        case ...2: 1
        case 3: 2
        default: 3
        }
        var resources = ResourcePool()
        var samples: [MaterialSample] = []
        for output in profile.sequence.prefix(outputCount) {
            switch output {
            case .resource(let id): resources.add(1, of: id)
            case .reclaimedHide: samples.append(reclaimedHide(forConstructionTier: stack.constructionTier))
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
        return salvageProfiles[stack.catalogID] == nil ? .noRecoveryProfile : nil
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
        guard remove(preview.stackID, at: preview.location, in: &candidate) else { return .invalid }
        candidate.resources.add(contentsOf: preview.returnedResources)
        // A material bin has exactly one kind. Return each receipt entry through ordinary Storehouse
        // binning so a plate and a fibre never become one malformed heterogeneous stack.
        for sample in preview.returnedSamples {
            candidate.store(ItemStack(id: InstanceID(rawValue: candidate.nextItemID()),
                                      catalogID: Items.material, identified: true,
                                      materials: [sample]))
        }
        candidate.recycler.inventoryRevision &+= 1
        base = candidate
        return .committed
    }

    private static func reclaimedHide(forConstructionTier tier: Int) -> MaterialSample {
        let grade = min(80, Double(min(4, max(1, tier))) * 20)
        return MaterialSample(kind: .hide,
                              properties: MaterialProperties(hardness: 15, density: 25,
                                                             insulation: 58, flexibility: 58,
                                                             lustre: 10, reactivity: 5),
                              grade: grade, source: "Recycler reclamation", qualifier: "reclaimed")
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
