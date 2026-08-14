import Foundation

/// Auber's finite essence work. Bulk stock and provenance-bearing samples intentionally remain
/// separate inputs: aggregate resources must never pretend to have world properties or an origin.
enum DistilleryRules {
    static let blankEssence = 40
    static let blankQuartz = 2
    static let attuneEssence = 15

    struct AttunementRequirement: Sendable {
        let essence: Int
        let catalysts: [(resource: ResourceID, amount: Int)]
        let allowedKinds: Set<MaterialKind>?
        let minimumReactivity: Double?
        let minimumInsulation: Double?
        let minimumLustre: Double?
        let minimumHardness: Double?

        func accepts(_ sample: MaterialSample) -> Bool {
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
        var binID: InstanceID
        var sampleIndex: Int
        var sample: MaterialSample
        var relevantProperty: Double
        var reserveSelection: MaterialReserveSelection? = nil
        var id: String { reserveSelection?.unitID.rawValue ?? "\(binID.rawValue)-\(sampleIndex)" }
    }

    enum AttunementReadiness: Equatable, Sendable {
        case ready
        case stationLocked
        case needsEssence(have: Int, need: Int)
        case sampleUnavailable
        case unsupportedCatalyst
        case needsCatalyst(resource: ResourceID, have: Int, need: Int)
        case needsBlankCrystal
        case needsRoom
    }

    enum CrystallisationReadiness: Equatable, Sendable {
        case ready
        case stationLocked
        case needsEssence(have: Int, need: Int)
        case needsQuartz(have: Int, need: Int)
        case needsRoom
    }

    static func candidates(for attunement: CoreAttunement, in state: GameState) -> [Candidate] {
        let requirement = requirement(for: attunement)
        let reserve = state.base.materialReserve.selections { requirement.accepts($0) }.map { quote in
            let relevant = attunement == .light ? quote.sample.properties.lustre
                                                : quote.sample.properties.reactivity
            return Candidate(binID: .init(rawValue: 0), sampleIndex: 0, sample: quote.sample,
                             relevantProperty: relevant, reserveSelection: quote)
        }
        return reserve.sorted { ($0.sample.grade, $0.relevantProperty, $0.id)
            < ($1.sample.grade, $1.relevantProperty, $1.id) }
    }

    static func catalystOptions(for attunement: CoreAttunement) -> [(ResourceID, Int)] {
        requirement(for: attunement).catalysts.map { ($0.resource, $0.amount) }
    }

    static func potency(for candidate: Candidate) -> Int {
        Int((candidate.sample.grade * 0.7 + candidate.relevantProperty * 0.3).rounded())
    }

    static func canCrystallise(in state: GameState) -> Bool {
        crystallisationReadiness(in: state) == .ready
    }

    static func crystallisationReadiness(in state: GameState) -> CrystallisationReadiness {
        guard state.base.station(Stations.distillery).isUnlocked else { return .stationLocked }
        guard state.base.essence >= blankEssence else {
            return .needsEssence(have: state.base.essence, need: blankEssence)
        }
        let quartz = state.base.resources[Resources.quartz]
        guard quartz >= blankQuartz else {
            return .needsQuartz(have: quartz, need: blankQuartz)
        }
        guard canStore(output(catalogID: Items.essenceCrystal,
                              core: DistilledCore(attunement: nil, potency: 0,
                                                  catalystCount: 0)), in: state) else {
            return .needsRoom
        }
        return .ready
    }

    @discardableResult
    static func crystallise(in state: inout GameState) -> Bool {
        guard canCrystallise(in: state) else { return false }
        state.base.essence -= blankEssence
        state.base.resources.spend(blankQuartz, of: Resources.quartz)
        return state.base.inventory.add(output(catalogID: Items.essenceCrystal,
                                               core: DistilledCore(attunement: nil, potency: 0,
                                                                   catalystCount: 0), in: state))
    }

    static func canAttune(_ attunement: CoreAttunement, candidate: Candidate,
                          catalyst: ResourceID, in state: GameState) -> Bool {
        readiness(attunement, candidate: candidate, catalyst: catalyst, in: state) == .ready
    }

    static func readiness(_ attunement: CoreAttunement, candidate: Candidate,
                          catalyst: ResourceID, in state: GameState) -> AttunementReadiness {
        let requirement = requirement(for: attunement)
        guard state.base.station(Stations.distillery).isUnlocked else { return .stationLocked }
        guard state.base.essence >= requirement.essence else {
            return .needsEssence(have: state.base.essence, need: requirement.essence)
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
        guard state.base.inventory.stacks.contains(where: {
            $0.catalogID == Items.essenceCrystal && $0.count > 0
        }) else { return .needsBlankCrystal }
        let core = provenance(for: attunement, candidate: candidate,
                              catalyst: (required.resource, required.amount))
        guard canStore(output(catalogID: item(for: attunement), core: core), in: state,
                       replacingOneBlank: true, consuming: candidate) else { return .needsRoom }
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
        guard removeOne(catalogID: Items.essenceCrystal, from: &staged.base.inventory),
              remove(candidate: candidate, from: &staged.base),
              staged.base.inventory.add(output(catalogID: item(for: attunement), core: core,
                                               in: staged)) else { return false }
        staged.base.essence -= requirement.essence
        staged.base.resources.spend(required.amount, of: catalyst)
        state = staged
        return true
    }

    /// First Channelworks consumer: construction transfers the core receipt onto the fixture.
    @discardableResult
    static func constructConduit(in state: inout GameState) -> Bool {
        guard state.base.station(Stations.channelworks).isUnlocked,
              let stack = state.base.inventory.stacks.first(where: { $0.catalogID == Items.heatCore }),
              let core = stack.distilledCore else { return false }
        let fixture = output(catalogID: Items.conduitFixture, core: core, in: state)
        var preview = state.base.inventory
        guard removeOne(catalogID: Items.heatCore, from: &preview), preview.add(fixture) else { return false }
        guard removeOne(catalogID: Items.heatCore, from: &state.base.inventory) else { return false }
        return state.base.inventory.add(fixture)
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
        return base.materialReserve.consume([reserve]) != nil
    }
}
