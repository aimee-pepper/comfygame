import Foundation
import CryptoKit

#if DEBUG
enum Band2PhoneFixtureError: Error, LocalizedError {
    case missingVocabulary
    case missingCollectedPage
    case persistenceMismatch
    case couldNotStageTemplate

    var errorDescription: String? {
        switch self {
        case .missingVocabulary: "The authored Rune Dictionary vocabulary is unavailable."
        case .missingCollectedPage: "No collected World Page is available for inspection."
        case .persistenceMismatch: "The disposable fixture did not survive its relaunch check."
        case .couldNotStageTemplate: "The production Template actions could not stage the fixture."
        }
    }
}

struct Band2DictionaryPhoneFixtureReceipt: Equatable, Sendable {
    var collectedPageID: InstanceID
    var sightingsBeforeInspection: Set<LexemeIdentity>
    var expectedInspectionSightings: Set<LexemeIdentity>
    var knownCount: Int
    var unknownCount: Int

    var phoneSummaryLines: [String] {
        [
            "Relaunched disposable save · no campaign slot",
            "\(knownCount) known · \(unknownCount) unknown typed entries",
            "Collected Page #\(String(format: "%016llx", collectedPageID.rawValue))",
            "Opening adds \(expectedInspectionSightings.subtracting(sightingsBeforeInspection).count) exact sighting(s)"
        ]
    }
}

struct Band2TemplatesPhoneFixtureReceipt: Equatable, Sendable {
    var stableTemplateIDs: [PageTemplateID]
    var templateCount: Int
    var capacity: Int
    var currentDraftMarkCount: Int

    var phoneSummaryLines: [String] {
        let ids = stableTemplateIDs.prefix(3).map { "T\($0.rawValue)" }.joined(separator: " · ")
        return [
            "Relaunched disposable save · no campaign slot",
            "\(templateCount) of \(capacity) Templates · \(currentDraftMarkCount)-mark dirty draft",
            "Stable IDs \(ids)\(stableTemplateIDs.count > 3 ? " …" : "")",
            "Use the cards to load, rename, overwrite and delete"
        ]
    }
}

@MainActor
final class Band2DictionaryPhoneFixtureSession: ObservableObject, Identifiable {
    let id = UUID()
    let store: GameStore
    let receipt: Band2DictionaryPhoneFixtureReceipt

    init() throws {
        let fixture = try GameStore.makeBand2DictionaryPhoneFixture()
        store = fixture.store
        receipt = fixture.receipt
    }
}

@MainActor
final class Band2TemplatesPhoneFixtureSession: ObservableObject, Identifiable {
    let id = UUID()
    let store: GameStore
    let receipt: Band2TemplatesPhoneFixtureReceipt

    init() throws {
        let fixture = try GameStore.makeBand2TemplatesPhoneFixture()
        store = fixture.store
        receipt = fixture.receipt
    }
}

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

enum StarterWorldPagePhoneFixtureError: Error, LocalizedError {
    case missingPage
    case couldNotBind
    case missingRun
    case missingReceipt
    case missingPromisedFind
    case unsafePromisedFind

    var errorDescription: String? {
        switch self {
        case .missingPage: "The authored starter World Page is unavailable."
        case .couldNotBind: "The disposable campaign could not bind that starter World Page."
        case .missingRun: "The starter World Page did not create an expedition."
        case .missingReceipt: "The expedition did not freeze the exact starter-page receipt."
        case .missingPromisedFind: "The promised starter weapon was not placed exactly once."
        case .unsafePromisedFind:
            "The promised weapon is not revealed and reachable in one or two ordinary steps."
        }
    }
}

struct StarterWorldPagePhoneFixtureReceipt: Equatable, Sendable {
    var pageDefinitionID: WorldPageDefinitionID
    var pageInstanceID: InstanceID
    var pageTitle: String
    var mapSeed: UInt64
    var itemID: ItemID
    var itemInstanceID: InstanceID
    var placement: GridPoint
    var safePathToRevealedFind: [GridPoint]
    var essencePaid: Int

    var phoneSummaryLines: [String] {
        let pageIdentity = String(format: "%016llx", pageInstanceID.rawValue)
        let itemIdentity = String(format: "%016llx", itemInstanceID.rawValue)
        let route = safePathToRevealedFind.map { "(\($0.x),\($0.y))" }.joined(separator: " → ")
        return [
            "Page \(pageDefinitionID.rawValue) · #\(pageIdentity)",
            "Seed \(mapSeed) · paid \(essencePaid) Essence",
            "Promised \(itemID.rawValue) · #\(itemIdentity)",
            "Revealed find · safe route \(route) · \(safePathToRevealedFind.count - 1) step\(safePathToRevealedFind.count == 2 ? "" : "s")"
        ]
    }
}

@MainActor
final class StarterWorldPagePhoneFixtureSession: ObservableObject, Identifiable {
    let id = UUID()
    let store: GameStore
    let receipt: StarterWorldPagePhoneFixtureReceipt

    init(definitionID: WorldPageDefinitionID) throws {
        let fixture = try GameStore.makeStarterWorldPagePhoneFixture(definitionID: definitionID)
        store = fixture.store
        receipt = fixture.receipt
    }
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

enum EncounterScalingProgressionFixtureKind: String, Identifiable, CaseIterable, Codable, Sendable {
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

    /// Canonical identity for the exact rules-owned fixture presented during phone acceptance.
    /// Every collection is ordered so the persisted verdict cannot silently follow a changed
    /// encounter, party vector or scaling implementation.
    var acceptanceIdentity: String {
        let levels = partyLevels.map(String.init).joined(separator: ",")
        let caps = healthCaps.map(String.init).joined(separator: ",")
        let foeIdentity = foeIDs.map { String($0.rawValue) }.joined(separator: ",")
        let foeLevelIdentity = foeLevels.map(String.init).joined(separator: ",")
        let foeHPIdentity = foeHP.map(String.init).joined(separator: ",")
        let apexIdentity = foeIsApex.map { $0 ? "1" : "0" }.joined(separator: ",")
        let allocation = hpAllocationByFoeID.keys.sorted().map {
            "\($0):\(hpAllocationByFoeID[$0] ?? 0)"
        }.joined(separator: ",")
        let uncapped = String(uncappedPartyPowerBudget.bitPattern, radix: 16)
        let capped = String(cappedPartyPowerBudget.bitPattern, radix: 16)
        let fraction = String(totalHPAdditionFraction.bitPattern, radix: 16)
        let canonical = [
            scalingRulesVersion, kind.rawValue, String(rootSeed), String(mapSeed), levels, caps,
            String(anchorLevel), String(partyCount), uncapped, capped, String(worldLevel),
            String(groupingRadius), foeIdentity, foeLevelIdentity, foeHPIdentity, apexIdentity,
            allocation, String(wholePressureSlots), fraction
        ].joined(separator: "|")
        return SHA256.hash(data: Data(canonical.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }

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

enum EncounterScalingAcceptanceVerdict: String, CaseIterable, Codable, Sendable {
    case balanced
    case overwhelmingButFair
    case unfair

    var title: String {
        switch self {
        case .balanced: "Balanced"
        case .overwhelmingButFair: "Overwhelming but fair"
        case .unfair: "Unfair"
        }
    }
}

struct EncounterScalingAcceptanceRecord: Codable, Equatable, Sendable {
    var scenario: EncounterScalingProgressionFixtureKind
    var verdict: EncounterScalingAcceptanceVerdict
    var receiptIdentity: String
}

@MainActor
final class EncounterScalingAcceptanceRecorder: ObservableObject {
    static let preferencesKey = "debug.encounter-scaling.acceptance.v1"

    @Published private(set) var records: [EncounterScalingProgressionFixtureKind:
        EncounterScalingAcceptanceRecord]
    private let preferences: UserDefaults

    init(preferences: UserDefaults = .standard) {
        self.preferences = preferences
        guard let data = preferences.data(forKey: Self.preferencesKey),
              let decoded = try? JSONDecoder().decode(
                [EncounterScalingProgressionFixtureKind: EncounterScalingAcceptanceRecord].self,
                from: data)
        else {
            records = [:]
            return
        }
        records = decoded.filter { $0.key == $0.value.scenario }
    }

    var completionCount: Int { records.count }

    func record(_ verdict: EncounterScalingAcceptanceVerdict,
                for receipt: EncounterScalingProgressionReceipt) {
        records[receipt.kind] = EncounterScalingAcceptanceRecord(
            scenario: receipt.kind,
            verdict: verdict,
            receiptIdentity: receipt.acceptanceIdentity)
        persist()
    }

    func clear() {
        records = [:]
        preferences.removeObject(forKey: Self.preferencesKey)
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(records) else { return }
        preferences.set(data, forKey: Self.preferencesKey)
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
    /// Seeds typed sightings, commits them to a UUID-scoped temporary save, then constructs the
    /// store shown on phone by loading those bytes again. Save-slot adapters are never involved.
    static func makeBand2DictionaryPhoneFixture() throws -> (
        store: GameStore, receipt: Band2DictionaryPhoneFixtureReceipt
    ) {
        let catalog = ContentCatalog.shared
        guard let collected = WorldPageCatalog.starterInstances.first else {
            throw Band2PhoneFixtureError.missingCollectedPage
        }
        let pageSightings = collected.definition.page.encounteredLexemes
        guard let knownTarget = catalog.pressureTargetsInOrder.map(\.id).first(where: {
                  !pageSightings.contains(.target($0))
              }),
              let knownSource = catalog.pressureSources.map(\.id).first(where: {
                  !pageSightings.contains(.source($0))
              }),
              let knownQualifier = PageRules.writableQualifiers().map(\.id).first(where: {
                  !pageSightings.contains(.qualifier($0))
              }),
              let knownCompound = catalog.symbols.map(\.id).first(where: {
                  !pageSightings.contains(.compound($0))
              }) else {
            throw Band2PhoneFixtureError.missingVocabulary
        }
        let stagedSightings: Set<LexemeIdentity> = [
            .target(knownTarget), .target("debug_retired_target"),
            .source(knownSource), .source("debug_retired_source"),
            .qualifier(knownQualifier), .qualifier("debug_retired_qualifier"),
            .compound(knownCompound), .compound("debug_retired_compound")
        ]
        let io = SaveFileIO.temporary(name: "phone-band2-dictionary-\(UUID().uuidString)")
        io.deleteEverything()
        let staging = GameStore(io: io)
        staging.mutate("stage Band 2 Dictionary acceptance", flush: true) { state in
            state.worlds.activeRun = nil
            state.base.ownedSources.insert(knownSource)
            state.base.ownedSymbols.insert(knownCompound)
            state.base.collectedWorldPages = [collected]
            state.reality.encounteredLexemes = stagedSightings
        }
        let expectedState = staging.state
        let relaunched = GameStore(io: io)
        guard relaunched.state.reality.encounteredLexemes
                == expectedState.reality.encounteredLexemes,
              relaunched.state.base.ownedSources == expectedState.base.ownedSources,
              relaunched.state.base.ownedSymbols == expectedState.base.ownedSymbols,
              relaunched.state.base.collectedWorldPages == expectedState.base.collectedWorldPages,
              let page = relaunched.state.base.collectedWorldPages.first else {
            throw Band2PhoneFixtureError.persistenceMismatch
        }
        let entries = LibraryRules.dictionaryEntries(
            reality: relaunched.state.reality, base: relaunched.state.base)
        return (relaunched, .init(
            collectedPageID: page.id,
            sightingsBeforeInspection: relaunched.state.reality.encounteredLexemes,
            expectedInspectionSightings: page.definition.page.encounteredLexemes,
            knownCount: entries.filter(\.isKnown).count,
            unknownCount: entries.filter { !$0.isKnown }.count
        ))
    }

    /// Uses production writing and Template actions to build a nearly-full shelf, persists it, and
    /// returns only the relaunched store. Phone interaction then crosses the unchanged Desk UI and
    /// the same save/load/rename/overwrite/delete actions as a campaign.
    static func makeBand2TemplatesPhoneFixture() throws -> (
        store: GameStore, receipt: Band2TemplatesPhoneFixtureReceipt
    ) {
        let io = SaveFileIO.temporary(name: "phone-band2-templates-\(UUID().uuidString)")
        io.deleteEverything()
        let staging = GameStore(io: io)
        guard staging.write("plains") else { throw Band2PhoneFixtureError.couldNotStageTemplate }
        for index in 1..<PageTemplateRules.capacity {
            guard case .saved = staging.savePageTemplate(named: "Fixture \(index)") else {
                throw Band2PhoneFixtureError.couldNotStageTemplate
            }
        }
        staging.clearPage()
        guard staging.write("frostbound") else {
            throw Band2PhoneFixtureError.couldNotStageTemplate
        }
        staging.flushNow()
        let expectedState = staging.state
        let relaunched = GameStore(io: io)
        guard relaunched.state.base.page == expectedState.base.page,
              relaunched.state.base.savedPageTemplates == expectedState.base.savedPageTemplates,
              relaunched.state.base.nextPageTemplateID == expectedState.base.nextPageTemplateID,
              relaunched.state.base.nextTemplateMarkID == expectedState.base.nextTemplateMarkID else {
            throw Band2PhoneFixtureError.persistenceMismatch
        }
        let templates = relaunched.state.base.savedPageTemplates.sorted {
            $0.creationOrdinal < $1.creationOrdinal
        }
        return (relaunched, .init(
            stableTemplateIDs: templates.map(\.id),
            templateCount: templates.count,
            capacity: PageTemplateRules.capacity,
            currentDraftMarkCount: relaunched.state.base.page.runes.count
        ))
    }

    /// Disposable ordinary-phone proof for the shipped starter catalogue. The fixture crosses the
    /// production bind transaction and generator exactly once; only its persistence destination is
    /// replaced with a UUID-named temporary store that cannot address a campaign slot.
    static func makeStarterWorldPagePhoneFixture(
        definitionID: WorldPageDefinitionID
    ) throws -> (store: GameStore, receipt: StarterWorldPagePhoneFixtureReceipt) {
        guard let instance = WorldPageCatalog.starterInstances.first(where: {
            $0.definition.id == definitionID
        }) else { throw StarterWorldPagePhoneFixtureError.missingPage }
        let store = GameStore(io: .temporary(
            name: "phone-starter-world-page-\(definitionID.rawValue)-\(UUID().uuidString)"))
        guard store.bindAndDepart(worldPageInstanceID: instance.id) else {
            throw StarterWorldPagePhoneFixtureError.couldNotBind
        }
        guard let run = store.activeRun else {
            throw StarterWorldPagePhoneFixtureError.missingRun
        }
        guard let pageReceipt = run.book.worldPageUseReceipt,
              pageReceipt.instanceID == instance.id,
              pageReceipt.definition == instance.definition,
              pageReceipt.essencePaid == instance.definition.worldPageCost else {
            throw StarterWorldPagePhoneFixtureError.missingReceipt
        }
        let finds = run.map.allPoints.compactMap { point -> (GridPoint, ItemStack)? in
            guard case .item(let stack) = run.map[point].content,
                  stack.catalogID == instance.definition.knownFind else { return nil }
            return (point, stack)
        }
        guard finds.count == 1, let find = finds.first,
              let itemID = instance.definition.knownFind,
              find.1.id == StarterKnownFindPlacementRules.stableInstanceID(for: pageReceipt)
        else { throw StarterWorldPagePhoneFixtureError.missingPromisedFind }
        guard run.map[find.0].isRevealed,
              let path = safeStarterPath(in: run, destination: find.0) else {
            throw StarterWorldPagePhoneFixtureError.unsafePromisedFind
        }
        return (store, .init(
            pageDefinitionID: instance.definition.id,
            pageInstanceID: instance.id,
            pageTitle: instance.definition.title,
            mapSeed: run.mapSeed,
            itemID: itemID,
            itemInstanceID: find.1.id,
            placement: find.0,
            safePathToRevealedFind: path,
            essencePaid: pageReceipt.essencePaid
        ))
    }

    private static func safeStarterPath(
        in run: WorldRun, destination: GridPoint
    ) -> [GridPoint]? {
        var paths: [GridPoint: [GridPoint]] = [run.playerPosition: [run.playerPosition]]
        var queue = [run.playerPosition]
        while !queue.isEmpty {
            let point = queue.removeFirst()
            guard let path = paths[point], path.count <= 3 else { continue }
            if point == destination { return path }
            for next in run.map.neighbours(of: point) where paths[next] == nil {
                let tile = run.map[next]
                guard tile.isPassable, tile.ground.movementCost == 1,
                      abs(tile.elevation - run.map[point].elevation) <= 1 else { continue }
                paths[next] = path + [next]
                queue.append(next)
            }
        }
        return nil
    }

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
            state.base.capabilities.insert("compoundAssembly")
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
