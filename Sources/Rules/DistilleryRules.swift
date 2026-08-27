import Foundation

enum ChannelworksRestoredFixtureLocation: Equatable {
    case stored
    case waitingToSort
    case awayOrNoLongerOwned
    case legacyIdentityUnknown
}

struct ChannelworksConduitBuildQuoteV1: Equatable {
    var stationID: StationID
    var inputHeatCoreInstanceID: InstanceID
    var inputSnapshot: ItemStack
    var outputSnapshot: ItemStack
}

enum ChannelworksConduitBuildRefusal: Equatable {
    case channelworksUnavailable, heatCoreUnavailable, invalidHeatCoreReceipt, storageUnavailable, staleQuote
}
enum ChannelworksConduitBuildEvaluation: Equatable {
    case allowed(ChannelworksConduitBuildQuoteV1)
    case refused(ChannelworksConduitBuildRefusal)
}
enum ChannelworksConduitBuildResult: Equatable {
    case committed(ItemStack)
    case refused(ChannelworksConduitBuildRefusal)
}

enum ChannelworksRestorationRules {
    static let authoredCore = DistilledCore(
        attunement: .heat, potency: 40, sampleKind: "authored fixture",
        sampleSource: "Oda's damaged conduit",
        sampleQualifier: "intact, non-recoverable core", catalystID: nil,
        catalystCount: 0, recipeVersion: 0, stationID: Stations.channelworks)

    static func isAuthoredFixture(_ stack: ItemStack) -> Bool {
        stack.catalogID == Items.conduitFixture && stack.distilledCore == authoredCore
    }

    static func nextPhysicalID(in state: GameState) -> InstanceID? {
        let base = state.base
        var values = base.inventory.stacks.map(\.id.rawValue)
        values += base.spillover.map(\.id.rawValue)
        if let essence = base.essenceCrystals?.id.rawValue { values.append(essence) }
        values += base.binderEquipped.values.compactMap {
            $0.gearProfile?.stableInstanceID.rawValue
        }
        values += base.roster.flatMap { member in
            member.equipped.values.compactMap { $0.gearProfile?.stableInstanceID.rawValue }
        }
        values += base.tradingPost.stock.flatMap(\.frozenUnits).map(\.id.rawValue)
        if let historical = base.channelworksRestoration?.fixtureInstanceID?.rawValue,
           !values.contains(historical) {
            values.append(historical)
        }
        let runs = [state.worlds.activeRun].compactMap { $0 }
            + state.worlds.anchoredRealms.map(\.world)
        for run in runs {
            values += run.satchelItems.stacks.map(\.id.rawValue)
            values += run.offeredItems.map(\.id.rawValue)
        }
        let maximum = values.max() ?? 0
        guard !values.contains(0), Set(values).count == values.count,
              maximum < UInt64.max else {
            return nil
        }
        return .init(rawValue: maximum + 1)
    }

    static func location(in base: BaseState) -> ChannelworksRestoredFixtureLocation? {
        guard let receipt = base.channelworksRestoration else { return nil }
        guard let id = receipt.fixtureInstanceID else { return .legacyIdentityUnknown }
        if base.inventory.stacks.contains(where: { $0.id == id }) { return .stored }
        if base.spillover.contains(where: { $0.id == id }) { return .waitingToSort }
        return .awayOrNoLongerOwned
    }

    static func evaluate(in state: GameState) -> ChannelworksConduitBuildEvaluation {
        guard state.base.station(Stations.channelworks).isUnlocked else {
            return .refused(.channelworksUnavailable)
        }
        let heat = state.base.inventory.stacks
            .filter { $0.catalogID == Items.heatCore }
            .sorted { $0.id.rawValue < $1.id.rawValue }
        guard !heat.isEmpty else { return .refused(.heatCoreUnavailable) }
        guard let input = heat.first(where: { validPlayerHeatCore($0.distilledCore) }) else {
            return .refused(.invalidHeatCoreReceipt)
        }
        guard let outputID = nextPhysicalID(in: state) else {
            return .refused(.storageUnavailable)
        }
        var inventory = state.base.inventory
        guard removeOne(id: input.id, from: &inventory) else { return .refused(.staleQuote) }
        let output = ItemStack(id: outputID,
                               catalogID: Items.conduitFixture, distilledCore: input.distilledCore)
        guard inventory.add(output) else { return .refused(.storageUnavailable) }
        return .allowed(.init(stationID: Stations.channelworks,
                              inputHeatCoreInstanceID: input.id, inputSnapshot: input,
                              outputSnapshot: output))
    }

    static func hasValidHeatCore(in state: GameState) -> Bool {
        state.base.inventory.stacks.contains {
            $0.catalogID == Items.heatCore && validPlayerHeatCore($0.distilledCore)
        }
    }

    static func commit(_ quote: ChannelworksConduitBuildQuoteV1,
                       in state: inout GameState) -> ChannelworksConduitBuildResult {
        let canonical: ChannelworksConduitBuildQuoteV1
        switch evaluate(in: state) {
        case .allowed(let current): canonical = current
        case .refused(let refusal): return .refused(refusal)
        }
        guard quote == canonical else { return .refused(.staleQuote) }
        var staged = state
        guard removeOne(id: canonical.inputHeatCoreInstanceID, from: &staged.base.inventory),
              staged.base.inventory.add(canonical.outputSnapshot) else {
            return .refused(.storageUnavailable)
        }
        state = staged
        return .committed(canonical.outputSnapshot)
    }

    private static func validPlayerHeatCore(_ core: DistilledCore?) -> Bool {
        guard let core else { return false }
        return core.attunement == .heat && core.recipeVersion == 1
            && core.stationID == Stations.distillery
            && core.potency >= 0
            && !(core.sampleKind?.isEmpty ?? true)
            && !(core.sampleSource?.isEmpty ?? true)
            && core.catalystID != nil && core.catalystCount > 0
    }

    @discardableResult private static func removeOne(id: InstanceID,
                                                      from inventory: inout Inventory) -> Bool {
        guard let index = inventory.stacks.firstIndex(where: { $0.id == id && $0.count > 0 }) else {
            return false
        }
        inventory.stacks[index].count -= 1
        if inventory.stacks[index].count == 0 { inventory.stacks.remove(at: index) }
        return true
    }
}

/// Auber's finite essence work. Bulk stock and provenance-bearing samples intentionally remain
/// separate inputs: aggregate resources must never pretend to have world properties or an origin.
enum DistilleryRules {
    /// The former blank-manufacture step spent scalar Essence to manufacture this same currency
    /// item. Attunement now spends the corrected complete physical-crystal cost directly.
    static let attuneEssence = 16

    struct AttunementRequirement: Sendable {
        let essence: Int
        let catalysts: [(resource: ResourceID, amount: Int)]
        let allowedKinds: Set<MaterialFamilyID>?
        let minimumReactivity: Double?
        let minimumInsulation: Double?
        let minimumLustre: Double?
        let minimumHardness: Double?

        func accepts(_ sample: CraftMaterialUnitV1) -> Bool {
            if let allowedKinds, !allowedKinds.contains(sample.kind) { return false }
            if let minimumReactivity, sample.properties.reactivity < minimumReactivity { return false }
            if let minimumInsulation, sample.properties.insulation < minimumInsulation { return false }
            if let minimumLustre, sample.properties.lustre < minimumLustre { return false }
            if let minimumHardness, sample.properties.hardness < minimumHardness { return false }
            return true
        }
    }

    static func requirement(for attunement: CoreAttunement) -> AttunementRequirement {
        switch attunement {
        case .heat:
            AttunementRequirement(essence: attuneEssence,
                catalysts: [(Resources.sulfur, 2)], allowedKinds: nil,
                minimumReactivity: 60, minimumInsulation: 25,
                minimumLustre: nil, minimumHardness: nil)
        case .caustic:
            AttunementRequirement(essence: attuneEssence,
                catalysts: [(Resources.toxin, 2), (Resources.ichor, 1)],
                allowedKinds: [.reagent, .toxin, .ichor], minimumReactivity: 60,
                minimumInsulation: nil, minimumLustre: nil, minimumHardness: nil)
        case .light:
            AttunementRequirement(essence: attuneEssence,
                catalysts: [(Resources.silver, 2)], allowedKinds: nil,
                minimumReactivity: nil, minimumInsulation: nil,
                minimumLustre: 60, minimumHardness: 30)
        }
    }

    struct Candidate: Equatable, Identifiable, Sendable {
        var attunement: CoreAttunement
        var binID: InstanceID
        var sampleIndex: Int
        var sample: CraftMaterialUnitV1
        var relevantProperty: Double
        var reserveSelection: CraftMaterialSelection? = nil
        var id: String { reserveSelection?.unitID.rawValue ?? "\(binID.rawValue)-\(sampleIndex)" }
    }

    enum AttunementReadiness: Equatable, Sendable {
        case ready
        case stationLocked
        case needsEssence(have: Int, need: Int)
        case sampleUnavailable
        case unsupportedCatalyst
        case needsCatalyst(resource: ResourceID, have: Int, need: Int)
        case needsRoom
    }

    static func candidates(for attunement: CoreAttunement, in state: GameState) -> [Candidate] {
        let requirement = requirement(for: attunement)
        let reserve = state.base.craftMaterialSelections { requirement.accepts($0) }.map { quote in
            let relevant = attunement == .light ? quote.sample.properties.lustre
                                                : quote.sample.properties.reactivity
            return Candidate(attunement: attunement, binID: .init(rawValue: 0), sampleIndex: 0, sample: quote.sample,
                             relevantProperty: relevant, reserveSelection: quote)
        }
        return reserve.sorted { (potency(for: $0), $0.id) < (potency(for: $1), $1.id) }
    }

    static func catalystOptions(for attunement: CoreAttunement) -> [(ResourceID, Int)] {
        requirement(for: attunement).catalysts.map { ($0.resource, $0.amount) }
    }

    static func potency(for candidate: Candidate) -> Int {
        let properties = candidate.sample.properties
        return switch candidate.attunement {
        case .heat: Int((0.65 * properties.reactivity + 0.35 * properties.insulation).rounded())
        case .caustic: Int(properties.reactivity.rounded())
        case .light: Int((0.65 * properties.lustre + 0.35 * properties.hardness).rounded())
        }
    }

    static func canAttune(_ attunement: CoreAttunement, candidate: Candidate,
                          catalyst: ResourceID, in state: GameState) -> Bool {
        readiness(attunement, candidate: candidate, catalyst: catalyst, in: state) == .ready
    }

    static func readiness(_ attunement: CoreAttunement, candidate: Candidate,
                          catalyst: ResourceID, in state: GameState) -> AttunementReadiness {
        let requirement = requirement(for: attunement)
        guard state.base.station(Stations.distillery).isUnlocked else { return .stationLocked }
        guard state.base.essenceCrystalCount >= requirement.essence else {
            return .needsEssence(have: state.base.essenceCrystalCount, need: requirement.essence)
        }
        guard candidates(for: attunement, in: state).contains(candidate) else {
            return .sampleUnavailable
        }
        guard let required = requirement.catalysts.first(where: { $0.resource == catalyst }) else {
            return .unsupportedCatalyst
        }
        let catalystHeld = state.base.resources[catalyst]
        guard catalystHeld >= required.amount else {
            return .needsCatalyst(resource: catalyst, have: catalystHeld, need: required.amount)
        }
        let core = provenance(for: attunement, candidate: candidate,
                              catalyst: (required.resource, required.amount))
        guard canStore(output(catalogID: item(for: attunement), core: core), in: state,
                       consuming: candidate) else { return .needsRoom }
        return .ready
    }

    @discardableResult
    static func attune(_ attunement: CoreAttunement, candidate: Candidate,
                       catalyst: ResourceID, in state: inout GameState) -> Bool {
        let requirement = requirement(for: attunement)
        guard canAttune(attunement, candidate: candidate, catalyst: catalyst, in: state),
              let required = requirement.catalysts.first(where: { $0.resource == catalyst }) else { return false }
        var staged = state
        let catalystReceipt = (required.resource, required.amount)
        let core = provenance(for: attunement, candidate: candidate, catalyst: catalystReceipt)
        guard staged.base.spendEssenceCrystals(requirement.essence),
              remove(candidate: candidate, from: &staged.base),
              staged.base.inventory.add(output(catalogID: item(for: attunement), core: core,
                                               in: staged)) else { return false }
        staged.base.resources.spend(required.amount, of: catalyst)
        state = staged
        return true
    }

    private static func item(for attunement: CoreAttunement) -> ItemID {
        switch attunement { case .heat: Items.heatCore; case .caustic: Items.causticCore; case .light: Items.lightCore }
    }

    private static func provenance(for attunement: CoreAttunement, candidate: Candidate,
                                   catalyst: (ResourceID, Int)) -> DistilledCore {
        DistilledCore(attunement: attunement, potency: potency(for: candidate),
                      sampleKind: candidate.sample.kind.rawValue, sampleSource: candidate.sample.source,
                      sampleQualifier: candidate.sample.qualifier, catalystID: catalyst.0,
                      catalystCount: catalyst.1)
    }

    private static func output(catalogID: ItemID, core: DistilledCore,
                               in state: GameState? = nil) -> ItemStack {
        ItemStack(id: InstanceID(rawValue: state?.base.nextItemID() ?? 0), catalogID: catalogID,
                  distilledCore: core)
    }

    private static func canStore(_ stack: ItemStack, in state: GameState,
                                 replacingOneBlank: Bool = false, consuming: Candidate? = nil) -> Bool {
        var inventory = state.base.inventory
        if replacingOneBlank { guard removeOne(catalogID: Items.essenceCrystal, from: &inventory) else { return false } }
        if let consuming, consuming.reserveSelection == nil { return false }
        return inventory.add(stack)
    }

    @discardableResult private static func removeOne(catalogID: ItemID, from inventory: inout Inventory) -> Bool {
        guard let index = inventory.stacks.firstIndex(where: { $0.catalogID == catalogID && $0.count > 0 }) else { return false }
        inventory.stacks[index].count -= 1
        if inventory.stacks[index].count == 0 { inventory.stacks.remove(at: index) }
        return true
    }

    @discardableResult private static func remove(candidate: Candidate, from base: inout BaseState) -> Bool {
        guard let reserve = candidate.reserveSelection else { return false }
        return base.consumeCraftMaterials([reserve]) != nil
    }
}
