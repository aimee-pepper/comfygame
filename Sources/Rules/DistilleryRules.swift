import Foundation

/// Auber's finite essence work. Bulk stock and provenance-bearing samples intentionally remain
/// separate inputs: aggregate resources must never pretend to have world properties or an origin.
enum DistilleryRules {
    static let blankEssence = 40
    static let blankQuartz = 2
    static let attuneEssence = 15

    struct Candidate: Equatable, Identifiable, Sendable {
        var binID: InstanceID
        var sampleIndex: Int
        var sample: MaterialSample
        var relevantProperty: Double
        var id: String { "\(binID.rawValue)-\(sampleIndex)" }
    }

    static func candidates(for attunement: CoreAttunement, in state: GameState) -> [Candidate] {
        state.base.inventory.stacks.flatMap { bin in
            bin.materials.enumerated().compactMap { index, sample in
                let relevant: Double
                switch attunement {
                case .heat:
                    guard sample.properties.reactivity >= 60, sample.properties.insulation >= 25 else { return nil }
                    relevant = sample.properties.reactivity
                case .caustic:
                    guard [.reagent, .toxin, .ichor].contains(sample.kind), sample.properties.reactivity >= 60 else { return nil }
                    relevant = sample.properties.reactivity
                case .light:
                    guard sample.properties.lustre >= 60, sample.properties.hardness >= 30 else { return nil }
                    relevant = sample.properties.lustre
                }
                return Candidate(binID: bin.id, sampleIndex: index, sample: sample,
                                 relevantProperty: relevant)
            }
        }.sorted { ($0.sample.grade, $0.relevantProperty) < ($1.sample.grade, $1.relevantProperty) }
    }

    static func catalystOptions(for attunement: CoreAttunement) -> [(ResourceID, Int)] {
        switch attunement {
        case .heat: [(Resources.sulfur, 2)]
        case .caustic: [(Resources.toxin, 2), (Resources.ichor, 1)]
        case .light: [(Resources.silver, 2)]
        }
    }

    static func potency(for candidate: Candidate) -> Int {
        Int((candidate.sample.grade * 0.7 + candidate.relevantProperty * 0.3).rounded())
    }

    static func canCrystallise(in state: GameState) -> Bool {
        guard state.base.station(Stations.distillery).isUnlocked,
              state.base.essence >= blankEssence,
              state.base.resources[Resources.quartz] >= blankQuartz else { return false }
        return canStore(output(catalogID: Items.essenceCrystal,
                               core: DistilledCore(attunement: nil, potency: 0,
                                                   catalystCount: 0)), in: state)
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
        guard state.base.station(Stations.distillery).isUnlocked,
              state.base.essence >= attuneEssence,
              candidates(for: attunement, in: state).contains(candidate),
              let required = catalystOptions(for: attunement).first(where: { $0.0 == catalyst }),
              state.base.resources[catalyst] >= required.1,
              state.base.inventory.stacks.contains(where: { $0.catalogID == Items.essenceCrystal && $0.count > 0 })
        else { return false }
        let core = provenance(for: attunement, candidate: candidate, catalyst: required)
        return canStore(output(catalogID: item(for: attunement), core: core), in: state,
                        replacingOneBlank: true, consuming: candidate)
    }

    @discardableResult
    static func attune(_ attunement: CoreAttunement, candidate: Candidate,
                       catalyst: ResourceID, in state: inout GameState) -> Bool {
        guard canAttune(attunement, candidate: candidate, catalyst: catalyst, in: state),
              let required = catalystOptions(for: attunement).first(where: { $0.0 == catalyst }) else { return false }
        let core = provenance(for: attunement, candidate: candidate, catalyst: required)
        guard removeOne(catalogID: Items.essenceCrystal, from: &state.base.inventory),
              remove(candidate: candidate, from: &state.base.inventory) else { return false }
        state.base.essence -= attuneEssence
        state.base.resources.spend(required.1, of: catalyst)
        return state.base.inventory.add(output(catalogID: item(for: attunement), core: core, in: state))
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
        if let consuming { guard remove(candidate: consuming, from: &inventory) else { return false } }
        return inventory.add(stack)
    }

    @discardableResult private static func removeOne(catalogID: ItemID, from inventory: inout Inventory) -> Bool {
        guard let index = inventory.stacks.firstIndex(where: { $0.catalogID == catalogID && $0.count > 0 }) else { return false }
        inventory.stacks[index].count -= 1
        if inventory.stacks[index].count == 0 { inventory.stacks.remove(at: index) }
        return true
    }

    @discardableResult private static func remove(candidate: Candidate, from inventory: inout Inventory) -> Bool {
        guard let bin = inventory.stacks.firstIndex(where: { $0.id == candidate.binID }),
              inventory.stacks[bin].materials.indices.contains(candidate.sampleIndex),
              inventory.stacks[bin].materials[candidate.sampleIndex] == candidate.sample else { return false }
        inventory.stacks[bin].materials.remove(at: candidate.sampleIndex)
        inventory.stacks[bin].count = inventory.stacks[bin].materials.count
        if inventory.stacks[bin].count == 0 { inventory.stacks.remove(at: bin) }
        return true
    }
}
