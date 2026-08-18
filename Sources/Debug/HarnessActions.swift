import Foundation

#if DEBUG
enum CompoundAssemblyPhoneFixtureError: Error, LocalizedError {
    case missingAuthoredVocabulary
    case invalidFixture

    var errorDescription: String? {
        switch self {
        case .missingAuthoredVocabulary:
            "The authored Sun / Illumination vocabulary is unavailable."
        case .invalidFixture:
            "The Compound Assembly fixture did not produce its required ready and refusal states."
        }
    }
}

struct CompoundAssemblyPhoneFixtureReceipt: Equatable, Sendable {
    var eligibleFingerprint: String
    var ineligibleFingerprint: String
}

@MainActor
final class CompoundAssemblyPhoneFixtureSession: ObservableObject, Identifiable {
    let id = UUID()
    let store: GameStore
    let receipt: CompoundAssemblyPhoneFixtureReceipt

    init() throws {
        let fixture = try GameStore.makeCompoundAssemblyPhoneFixture()
        store = fixture.store
        receipt = fixture.receipt
    }
}

enum EncounterScalingPhoneFixtureKind: String, Identifiable, CaseIterable, Sendable {
    case normal
    case teeming

    var id: String { rawValue }
    var title: String { self == .normal ? "Normal · isolated grazer" : "Teeming · isolated grazer" }
    var detail: String {
        self == .normal
            ? "Automated control: 3 rounds · 7 of 54 HP spent"
            : "Automated control: 2 rounds · 8 of 54 HP spent"
    }
}

enum EncounterScalingPhoneFixtureError: Error, LocalizedError {
    case couldNotWritePage
    case couldNotBind
    case missingRun
    case missingEnemy
    case invalidEncounter

    var errorDescription: String? {
        switch self {
        case .couldNotWritePage: "The fixture could not write its controlled Page."
        case .couldNotBind: "The fixture could not bind its controlled world."
        case .missingRun: "The fixture did not create an expedition."
        case .missingEnemy: "The controlled world did not contain its expected contact."
        case .invalidEncounter: "The controlled contact did not freeze as one level-one foe."
        }
    }
}

enum EncounterScalingProgressionFixtureKind: String, Identifiable, CaseIterable, Sendable {
    case freshSolo
    case experiencedSolo
    case ordinaryTwoPerson
    case experiencedParty
    case ordinaryFivePerson
    case apexParty

    var id: String { rawValue }
    var binderLevel: Int { self == .freshSolo ? 1 : 8 }
    var rootSeed: UInt64 { self == .apexParty ? 909 : 101 }
    var isApex: Bool { self == .apexParty }
    var memberLevels: [Int] {
        switch self {
        case .freshSolo, .experiencedSolo: []
        case .ordinaryTwoPerson: [8]
        case .experiencedParty: [8, 6, 4]
        case .ordinaryFivePerson: [8, 6, 4, 2]
        case .apexParty: [8, 6, 4]
        }
    }
    var title: String {
        switch self {
        case .freshSolo: "Solo · Binder level 1"
        case .experiencedSolo: "Solo · Binder level 8"
        case .ordinaryTwoPerson: "Ordinary · 2 people · levels 8 / 8"
        case .experiencedParty: "Party · levels 8 / 8 / 6 / 4"
        case .ordinaryFivePerson: "Ordinary · 5 people · levels 8 / 8 / 6 / 4 / 2"
        case .apexParty: "Apex · party levels 8 / 8 / 6 / 4"
        }
    }
    var detail: String {
        if isApex { return "One disclosed apex contact · fixed root 909 · frozen member levels" }
        return memberLevels.isEmpty
            ? "One disclosed ordinary contact · no equipment · frozen level \(binderLevel)"
            : "\(memberLevels.count) explicit companion\(memberLevels.count == 1 ? "" : "s") · disclosed ordinary grouping"
    }
}

struct EncounterScalingProgressionReceipt: Equatable, Sendable {
    var kind: EncounterScalingProgressionFixtureKind
    var rootSeed: UInt64
    var mapSeed: UInt64
    var partyLevels: [Int]
    var healthCaps: [Int]
    var anchorLevel: Int
    var partyCount: Int
    var uncappedPartyPowerBudget: Double
    var cappedPartyPowerBudget: Double
    var worldLevel: Int
    var groupingRadius: Int
    var foeIDs: [InstanceID]
    var foeLevels: [Int]
    var foeHP: [Int]
    var foeIsApex: [Bool]
    var hpAllocationByFoeID: [String: Int]
    var wholePressureSlots: Int
    var totalHPAdditionFraction: Double
    var scalingRulesVersion: String

    var phoneSummaryLines: [String] {
        let party = partyLevels.map(String.init).joined(separator: " / ")
        let foes = zip(zip(foeLevels, foeHP), foeIsApex).map {
            "\($0.1 ? "Apex " : "")L\($0.0.0) · \($0.0.1) HP"
        }
            .joined(separator: ", ")
        let allocation = hpAllocationByFoeID.values.reduce(0, +)
        let pressure = String(format: "%.3f", locale: Locale(identifier: "en_US_POSIX"),
                              cappedPartyPowerBudget)
        return [
            "Party levels \(party)",
            "Pressure \(pressure) · radius \(groupingRadius)",
            "Foe \(foes)",
            "Allocation +\(allocation) HP · \(wholePressureSlots) pressure slot\(wholePressureSlots == 1 ? "" : "s")"
        ]
    }
}

@MainActor
final class EncounterScalingPhoneFixtureSession: ObservableObject, Identifiable {
    let id = UUID()
    let kind: EncounterScalingPhoneFixtureKind
    let store: GameStore

    init(kind: EncounterScalingPhoneFixtureKind) throws {
        self.kind = kind
        store = try GameStore.makeEncounterScalingPhoneFixture(kind: kind)
    }
}

@MainActor
final class EncounterScalingProgressionFixtureSession: ObservableObject, Identifiable {
    let id = UUID()
    let kind: EncounterScalingProgressionFixtureKind
    let store: GameStore
    let receipt: EncounterScalingProgressionReceipt

    init(kind: EncounterScalingProgressionFixtureKind) throws {
        self.kind = kind
        let fixture = try GameStore.makeEncounterScalingProgressionFixture(
            kind: kind, rootSeed: kind.rootSeed)
        guard let frozen = GameStore.progressionReceipt(
            kind: kind, rootSeed: kind.rootSeed, from: fixture)
        else { throw EncounterScalingPhoneFixtureError.invalidEncounter }
        store = fixture
        receipt = frozen
    }
}

extension GameStore {
    /// A disposable campaign for phone acceptance. Direct mutation constructs only the deliberate
    /// starting fixture; formalize, rename and delete remain production quoted transactions.
    static func makeCompoundAssemblyPhoneFixture() throws -> (
        store: GameStore, receipt: CompoundAssemblyPhoneFixtureReceipt
    ) {
        let target: PressureTargetID = "illumination"
        let source: PressureSourceID = "sun"
        guard ContentCatalog.shared.pressureTarget(target) != nil,
              ContentCatalog.shared.pressureSource(source) != nil else {
            throw CompoundAssemblyPhoneFixtureError.missingAuthoredVocabulary
        }
        let eligibleAtom = CompoundSemanticAtom(Sigil(
            id: .init(rawValue: 0xCA00_0001), source: source, target: target))
        let eligible = ProvenStatementReceipt(
            fingerprint: PageRules.statementFingerprint(target: target, atoms: [eligibleAtom]),
            target: target, atoms: [eligibleAtom],
            vocabulary: [.target(target), .source(source)],
            vocabularySchemaVersion: ProvenStatementReceipt.currentVocabularySchemaVersion,
            firstBoundRunIndex: 1)

        let unknownSource: PressureSourceID = "compound_phone_unknown_source"
        let ineligibleAtom = CompoundSemanticAtom(Sigil(
            id: .init(rawValue: 0xCA00_0002), source: unknownSource, target: target))
        let ineligible = ProvenStatementReceipt(
            fingerprint: PageRules.statementFingerprint(target: target, atoms: [ineligibleAtom]),
            target: target, atoms: [ineligibleAtom],
            vocabulary: [.target(target), .source(unknownSource)],
            vocabularySchemaVersion: ProvenStatementReceipt.currentVocabularySchemaVersion,
            firstBoundRunIndex: 1)

        let store = GameStore(io: .temporary(
            name: "phone-compound-assembly-\(UUID().uuidString)"))
        store.mutate("stage compound assembly phone acceptance", flush: true) { state in
            state.worlds.activeRun = nil
            state.base.completedResearch.insert("pen_compounds")
            state.base.ownedSources.insert(source)
            state.base.provenStatementReceipts = [eligible, ineligible]
            state.base.personalCompounds = []
            state.base.nextPersonalCompoundID = 1
            state.base.nextPersonalCompoundOrdinal = 1
            state.base.essence = Tuning.Page.personalCompoundFormalizeEssence
            state.base.resources = ResourcePool([
                Resources.pulp: Tuning.Page.personalCompoundFormalizePulp
            ])
        }
        guard case .ready = store.previewCompoundFormalization(
            fingerprint: eligible.fingerprint, nickname: "Sunward shorthand"),
              store.previewCompoundFormalization(
                fingerprint: ineligible.fingerprint, nickname: "Must refuse")
                == .refused(.ineligible(.unknownAtom)) else {
            throw CompoundAssemblyPhoneFixtureError.invalidFixture
        }
        return (store, .init(eligibleFingerprint: eligible.fingerprint,
                             ineligibleFingerprint: ineligible.fingerprint))
    }

    /// A disposable phone-play fixture. It uses the same production world generation, scaling,
    /// combat actions and bug-report receipt as a campaign, but its temporary persistence URL can
    /// never read or overwrite a campaign slot.
    static func makeEncounterScalingPhoneFixture(
        kind: EncounterScalingPhoneFixtureKind,
        rootSeed: UInt64 = 101
    ) throws -> GameStore {
        let store = GameStore(io: .temporary(
            name: "phone-scaling-\(kind.rawValue)-\(rootSeed)-\(UUID().uuidString)"))
        store.mutate("freeze phone scaling fixture") { state in
            state.worlds.seeds = SeedSequence(rootSeed: rootSeed)
            state.base.binderCharacter = CharacterState(rank: .front)
            state.base.binderEquipped = [:]
            var quill = CompanionState()
            quill.maxHP = Tuning.Encounter.companionMaxHP
            quill.character = CharacterState(rank: .front)
            quill.gambits = GambitStarter.rules
            quill.equipped = [:]
            state.base.roster = [quill]
            state.base.activeParty = [0]
        }
        guard store.write("plains") else {
            throw EncounterScalingPhoneFixtureError.couldNotWritePage
        }
        if kind == .teeming, !store.write("teeming_life") {
            throw EncounterScalingPhoneFixtureError.couldNotWritePage
        }
        guard store.bindAndDepart() else {
            throw EncounterScalingPhoneFixtureError.couldNotBind
        }
        guard store.activeRun != nil else { throw EncounterScalingPhoneFixtureError.missingRun }

        store.mutate("stage disclosed isolated phone contact", flush: true) { state in
            guard var run = state.worlds.activeRun, !run.enemies.isEmpty else { return }
            run.tuning = .defaults
            run.binderHP = Tuning.Encounter.binderMaxHP
            run.companionHP = [0: Tuning.Encounter.companionMaxHP]
            run.healthCaps = [
                RunHealthCapEntry(member: .binder,
                                  ordinaryMaximum: Tuning.Encounter.binderMaxHP, components: []),
                RunHealthCapEntry(member: .member(0),
                                  ordinaryMaximum: Tuning.Encounter.companionMaxHP, components: [])
            ]
            run.rng = SeededRNG(seed: run.mapSeed).derived(0xA11CE)
            for point in run.map.allPoints { run.map[point].isRevealed = true }
            for index in run.enemies.indices { run.enemies[index].isAwake = true }
            let trigger = run.enemies.min {
                let lhs = abs($0.position.x - run.playerPosition.x)
                    + abs($0.position.y - run.playerPosition.y)
                let rhs = abs($1.position.x - run.playerPosition.x)
                    + abs($1.position.y - run.playerPosition.y)
                return lhs == rhs ? $0.id.rawValue < $1.id.rawValue : lhs < rhs
            }
            guard let trigger else { return }
            state.worlds.activeRun = run
            WorldRules.beginEncounter(triggeredBy: trigger, runsAutomaticTurns: false, in: &state)
            CombatRules.runAutomaticTurns(in: &state)
        }

        guard let encounter = store.activeEncounter,
              encounter.foes.count == 1,
              encounter.foes[0].level == 1,
              encounter.foes[0].identityKey == "grazer",
              encounter.scalingPreview?.partyCount == 2,
              encounter.scalingPreview?.cappedPartyPowerBudget == 1.5
        else { throw EncounterScalingPhoneFixtureError.invalidEncounter }
        return store
    }

    /// Deterministic progression vectors beside (and deliberately not replacing) the accepted
    /// level-one Normal/Teeming pair. Every value is frozen through production departure and
    /// encounter-entry rules; no gameplay RNG is consumed to manufacture a comparison result.
    static func makeEncounterScalingProgressionFixture(
        kind: EncounterScalingProgressionFixtureKind,
        rootSeed: UInt64 = 101
    ) throws -> GameStore {
        let store = GameStore(io: .temporary(
            name: "phone-scaling-progression-\(kind.rawValue)-\(rootSeed)-\(UUID().uuidString)"))
        store.mutate("freeze progression scaling fixture") { state in
            state.worlds.seeds = SeedSequence(rootSeed: rootSeed)
            state.base.binderCharacter = CharacterState(level: kind.binderLevel, rank: .front)
            state.base.binderEquipped = [:]
            state.base.roster = kind.memberLevels.enumerated().map { index, level in
                var member = CompanionState()
                member.name = "Fixture \(index + 1)"
                member.maxHP = Tuning.Encounter.companionMaxHP
                member.character = CharacterState(level: level, rank: .front)
                member.gambits = GambitStarter.rules
                member.equipped = [:]
                return member
            }
            state.base.activeParty = Array(kind.memberLevels.indices)
        }
        guard store.write("plains") else {
            throw EncounterScalingPhoneFixtureError.couldNotWritePage
        }
        guard store.bindAndDepart() else {
            throw EncounterScalingPhoneFixtureError.couldNotBind
        }
        store.mutate("stage disclosed progression contact", flush: true) { state in
            guard var run = state.worlds.activeRun, !run.enemies.isEmpty else { return }
            run.tuning = .defaults
            for point in run.map.allPoints { run.map[point].isRevealed = true }
            for index in run.enemies.indices { run.enemies[index].isAwake = true }
            let trigger = run.enemies.min {
                let lhs = abs($0.position.x - run.playerPosition.x)
                    + abs($0.position.y - run.playerPosition.y)
                let rhs = abs($1.position.x - run.playerPosition.x)
                    + abs($1.position.y - run.playerPosition.y)
                return lhs == rhs ? $0.id.rawValue < $1.id.rawValue : lhs < rhs
            }
            guard let trigger else { return }
            if kind.isApex,
               let triggerIndex = run.enemies.firstIndex(where: { $0.id == trigger.id }) {
                run.enemies[triggerIndex].isApex = true
            }
            state.worlds.activeRun = run
            let stagedTrigger = kind.isApex
                ? run.enemies.first(where: { $0.id == trigger.id }) ?? trigger
                : trigger
            WorldRules.beginEncounter(triggeredBy: stagedTrigger,
                                      runsAutomaticTurns: false, in: &state)
        }
        guard progressionReceipt(kind: kind, rootSeed: rootSeed, from: store) != nil else {
            throw EncounterScalingPhoneFixtureError.invalidEncounter
        }
        return store
    }

    static func progressionReceipt(
        kind: EncounterScalingProgressionFixtureKind,
        rootSeed: UInt64,
        from store: GameStore
    ) -> EncounterScalingProgressionReceipt? {
        guard let run = store.activeRun, let encounter = run.activeEncounter,
              let preview = encounter.scalingPreview,
              let anchor = preview.anchorLevel,
              let uncapped = preview.uncappedPartyPowerBudget,
              let capped = preview.cappedPartyPowerBudget,
              let worldLevel = preview.worldLevel,
              let allocation = preview.hpAllocationByFoeID,
              let slots = preview.wholePressureSlots,
              let hpFraction = preview.totalHPAdditionFraction,
              let version = preview.scalingRulesVersion,
              let healthCaps = run.healthCaps
        else { return nil }
        return .init(
            kind: kind, rootSeed: rootSeed, mapSeed: run.mapSeed,
            partyLevels: preview.partyLevels,
            healthCaps: healthCaps.map(\.maximum), anchorLevel: anchor,
            partyCount: preview.partyCount,
            uncappedPartyPowerBudget: uncapped, cappedPartyPowerBudget: capped,
            worldLevel: worldLevel, groupingRadius: preview.groupingRadius,
            foeIDs: preview.foeIDs, foeLevels: encounter.foes.map(\.level),
            foeHP: encounter.foes.map(\.stats.maxHP),
            foeIsApex: encounter.foes.map(\.isApex), hpAllocationByFoeID: allocation,
            wholePressureSlots: slots, totalHPAdditionFraction: hpFraction,
            scalingRulesVersion: version)
    }
}
#endif

/// The last of the stand-ins.
///
/// Milestone 2 made binding real, milestone 3 the world, milestone 4 combat. All that's left is a
/// debug way to grant a mote, until milestone 5 gives motes real sources (locked caches, Mythic
/// drops, first clears). Then this file goes.
extension GameStore {
    /// Step the analysis axis, so the later description panels can be seen before instruments —
    /// the thing that actually raises it — exist. Wraps back to tier 1.
    func harnessCycleAnalysisTier() {
        mutate("harness: analysis tier", flush: true) { state in
            let next = state.reality.analysisTier + 1
            state.reality.analysisTier = next > Tuning.Analysis.livingTier ? Tuning.Analysis.startingTier : next
        }
    }

    /// Drop one of every wearable thing into the Storehouse, so the equipping UI can be seen
    /// without first walking to a ruin.
    func harnessGrantGear() {
        mutate("harness: gear", flush: true) { state in
            for item in ContentCatalog.shared.items where item.gear != nil {
                guard !state.base.inventory.stacks.contains(where: { $0.catalogID == item.id }) else { continue }
                state.base.inventory.slots = max(state.base.inventory.slots,
                                                 state.base.inventory.stacks.count + 1)
                state.base.inventory.add(ItemStack(id: InstanceID(rawValue: UInt64(abs(item.id.rawValue.hashValue))),
                                                   catalogID: item.id))
            }
        }
    }

    func harnessGainMote() {
        mutate("found a mote", flush: true) { $0.reality.motes += 1 }
    }

    /// A reproducible visual state for the Survey Post's crafting rows. Debug-only stock, kept out
    /// of production progression so interactive checks do not require finding Mara and butchering
    /// several unusually lustrous creatures first.
    func harnessPrepareInstrumentCrafting() {
        mutate("harness: instrument crafting", flush: true) { state in
            state.base.stations[Stations.surveyPost] = StationState(isUnlocked: true, tier: 1)
            state.base.essence = max(state.base.essence, 100)
            let target: PressureTargetID = "illumination"
            state.reality.instruments.insert(target)
            state.reality.instrumentPrecisions[target] = .crude
            state.base.instrumentLoadout.insert(target)
            let samples = (0..<5).map { index in
                MaterialSample(kind: .chitin,
                               properties: MaterialProperties(lustre: 45 + Double(index) * 10),
                               grade: 45 + Double(index) * 10,
                               source: "harness specimen")
            }
            state.base.inventory.slots = max(state.base.inventory.slots,
                                             state.base.inventory.stacks.count + 1)
            _ = state.base.inventory.add(ItemStack(
                id: InstanceID(rawValue: state.base.nextItemID()),
                catalogID: Items.material,
                materials: samples))
        }
    }

    func harnessPrepareApothecary() {
        mutate("harness: apothecary", flush: true) { state in
            state.base.stations[Stations.apothecary] = StationState(isUnlocked: true, tier: 0)
            state.base.essence = max(state.base.essence, 500)
            state.reality.motes = max(state.reality.motes, 3)
            for resource in ContentCatalog.shared.resources where resource.id != Resources.mote {
                state.base.resources.add(10, of: resource.id)
            }
            let samples = MaterialProperty.allCases.flatMap { property in
                (0..<3).map { index -> MaterialSample in
                    var properties = MaterialProperties()
                    properties[property] = 80 + Double(index)
                    return MaterialSample(kind: .reagent, properties: properties,
                                          grade: 80 + Double(index), source: "harness specimen")
                }
            }
            state.base.inventory.slots = max(state.base.inventory.slots,
                                             state.base.inventory.stacks.count + 1)
            _ = state.base.inventory.add(ItemStack(id: InstanceID(rawValue: state.base.nextItemID()),
                                                   catalogID: Items.material, materials: samples))
            state.base.knownConsumableRecipes = Set(ConsumableCraftingRules.recipes.map(\.output))
        }
    }
}
