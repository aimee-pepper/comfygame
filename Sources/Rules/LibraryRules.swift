import Foundation

struct RecoveredTeachingReward: Equatable, Sendable {
    var kind: RecoveredTeachingRewardKind
    var id: String
}

enum RecoveredTeachingBandV1: String, Codable, Sendable {
    case opening, developing, later
}

enum RecoveredTeachingPlacementV1: String, Codable, Sendable {
    case fieldInstruction, localObservation, warningNote, siteRubbing, quietCounterexample
}

struct RecoveredTeachingDefinitionV1: Equatable, Sendable {
    var order: Int
    var id: RecoveredTeachingID
    var band: RecoveredTeachingBandV1
    var reward: RecoveredTeachingReward
    var placement: RecoveredTeachingPlacementV1
    var title: String
    var instructionCopy: String
}

/// Closed machine-readable reward census for Recovered Teaching V1. Titles and frozen prose are
/// carried by the recovery receipt; reward authority never comes from displayed copy.
enum RecoveredTeachingCatalogueV1 {
    static let version = 1
    static let rewards: [RecoveredTeachingID: RecoveredTeachingReward] =
        Dictionary(uniqueKeysWithValues: definitions.map { ($0.id, $0.reward) })

    static func reward(for id: RecoveredTeachingID) -> RecoveredTeachingReward? { rewards[id] }
}

enum RecoveredTeachingReadResult: Equatable, Sendable {
    case committed(RecoveredTeachingID)
    case alreadyRead(RecoveredTeachingID)
    case invalid
}

struct RecoveredTeachingWorldOfferV1: Equatable, Sendable {
    var definition: RecoveredTeachingDefinitionV1?
    var point: GridPoint?
    var offerStates: [RecoveredTeachingOfferStateV1]
}

/// Frozen, typed evidence used by both eligibility and placement for one generated world. It is
/// deliberately derived from the resolved authored-plus-unwritten sigils, never display strings.
struct RecoveredTeachingWorldEvidenceV1: Equatable, Sendable {
    var generatedSourceIDs: Set<PressureSourceID>
    var greatSourceIDs: Set<PressureSourceID>
    var authoredCompositeIDs: Set<SymbolID>
    var eligibleDangerTeachingIDs: Set<RecoveredTeachingID>
    var manifestationPoints: [RecoveredTeachingID: Set<GridPoint>]

    func supports(_ definition: RecoveredTeachingDefinitionV1, state: GameState) -> Bool {
        switch definition.reward.kind {
        case .gambitComponent: return true
        case .capability:
            return ["subject_self", "act_flee", "act_skill"].allSatisfy {
                state.base.ownedGambitComponents.contains(.init(rawValue: $0))
            }
        case .focus:
            return generatedSourceIDs.contains(.init(rawValue: definition.reward.id))
        case .symbol:
            if definition.reward.id == "peace" {
                let danger = ["swarm_rune", "storm", "predation", "blight", "tremor", "miasma_rune"]
                    .filter { state.base.ownedSymbols.contains(.init(rawValue: $0)) }.count
                return danger >= 2 && authoredCompositeIDs.contains("peace")
            }
            return eligibleDangerTeachingIDs.contains(definition.id)
        }
    }
}

enum RecoveredTeachingWorldRulesV1 {
    static let offerChance = 0.45

    static func prepare(state: GameState, book: BoundBook, seed: UInt64,
                        map: WorldMap, enemies: [WorldEnemy]) -> RecoveredTeachingWorldOfferV1 {
        let evidence = evidence(book: book, seed: seed, map: map, enemies: enemies)
        let definitions = RecoveredTeachingCatalogueV1.definitions.filter { definition in
            definition.placement != .siteRubbing && bandIsOpen(definition.band, state: state)
                && !rewardIsKnown(definition.reward, state: state)
                && !state.reality.library.recoveredTeachings.contains(where: {
                    $0.teachingID == definition.id
                })
                && evidence.supports(definition, state: state)
        }
        var states = Dictionary(uniqueKeysWithValues:
            state.reality.library.recoveredTeachingOffers.map { ($0.teachingID, $0) })
        let outcomeIndex = Int(clamping: state.worlds.outcomeSequence) + 1
        var offered: [(definition: RecoveredTeachingDefinitionV1, wasDue: Bool)] = []
        for definition in definitions {
            var receipt = states[definition.id] ?? .init(
                teachingID: definition.id, firstEligibleOutcomeIndex: outcomeIndex)
            let due = receipt.isDue || receipt.eligibleWorldsWithoutOffer >= 2
            var rng = SeededRNG(seed: seed).derived(UInt64(definition.order) ^ 0x5445_4143_48)
            if due || rng.chance(offerChance) {
                offered.append((definition, due))
            } else {
                receipt.eligibleWorldsWithoutOffer += 1
                if receipt.eligibleWorldsWithoutOffer >= 2 { receipt.isDue = true }
            }
            states[definition.id] = receipt
        }
        let selected = offered.sorted {
            let lhs = states[$0.definition.id]!
            let rhs = states[$1.definition.id]!
            if $0.wasDue != $1.wasDue { return $0.wasDue && !$1.wasDue }
            if lhs.firstEligibleOutcomeIndex != rhs.firstEligibleOutcomeIndex {
                return (lhs.firstEligibleOutcomeIndex ?? .max) < (rhs.firstEligibleOutcomeIndex ?? .max)
            }
            return $0.definition.order < $1.definition.order
        }.first?.definition
        for choice in offered {
            if choice.definition.id == selected?.id {
                states[choice.definition.id]?.isDue = true
            } else if !choice.wasDue {
                states[choice.definition.id]?.eligibleWorldsWithoutOffer += 1
                if states[choice.definition.id]!.eligibleWorldsWithoutOffer >= 2 {
                    states[choice.definition.id]?.isDue = true
                }
            }
        }
        let point = selected.flatMap {
            placementPoint(for: $0, manifestations: evidence.manifestationPoints[$0.id] ?? [],
                           in: map, enemies: enemies)
        }
        return .init(definition: point == nil ? nil : selected, point: point,
                     offerStates: states.values.sorted { $0.teachingID.rawValue < $1.teachingID.rawValue })
    }

    static func bandIsOpen(_ band: RecoveredTeachingBandV1, state: GameState) -> Bool {
        switch band {
        case .opening: state.worlds.outcomeSequence >= 1
        case .developing: state.base.binderCharacter.level >= 4 && state.worlds.outcomeSequence >= 3
        case .later: state.base.binderCharacter.level >= 8 && state.worlds.outcomeSequence >= 8
        }
    }

    private static func rewardIsKnown(_ reward: RecoveredTeachingReward,
                                      state: GameState) -> Bool {
        switch reward.kind {
        case .gambitComponent: state.base.ownedGambitComponents.contains(.init(rawValue: reward.id))
        case .focus: state.base.ownedSources.contains(.init(rawValue: reward.id))
        case .symbol: state.base.ownedSymbols.contains(.init(rawValue: reward.id))
        case .capability: state.base.capabilities.contains(.init(rawValue: reward.id))
        }
    }

    static func evidence(book: BoundBook, seed: UInt64, map: WorldMap,
                         enemies: [WorldEnemy]) -> RecoveredTeachingWorldEvidenceV1 {
        let authored = BookRules.sigils(for: book)
        let generated = authored + PressureRules.rollUnwritten(after: authored, seed: seed)
        let sources = Set(generated.map(\.source))
        let great = Set(generated.filter { $0.intensity == .great || $0.intensity == .overwhelming }
            .map(\.source))
        let cracking = Set(map.allPoints.filter { map[$0].isCracking })
        let enemyPoints = Set(enemies.map(\.position))
        var resourcePointsByIdentity: [String: Set<GridPoint>] = [:]
        for point in map.allPoints {
            guard case .node(let node) = map[point].content else { continue }
            resourcePointsByIdentity[node.resource.rawValue, default: []].insert(point)
        }

        func focusPoints(_ id: String) -> Set<GridPoint> {
            // A local manifestation must carry the exact same stable identity. Generic water,
            // growth, resources and hazards cannot stand in for a named source. Most generated
            // source effects are world-global today and therefore truthfully use the field
            // fallback until the map owns a typed local manifestation.
            resourcePointsByIdentity[id] ?? []
        }

        var manifestations: [RecoveredTeachingID: Set<GridPoint>] = [:]
        for definition in RecoveredTeachingCatalogueV1.definitions where definition.reward.kind == .focus {
            manifestations[definition.id] = focusPoints(definition.reward.id)
        }
        let authoredIDs = Set(book.allSymbolIDs)
        let readings = PressureRules.resolve(generated)
        var eligibleDanger: Set<RecoveredTeachingID> = []
        let swarm = great.contains("swarm") || authoredIDs.contains("swarm_rune")
        if swarm { eligibleDanger.insert("teaching.symbol.swarm_rune") }
        // The current enemy ABI carries no swarm manifestation identity. A Great Swarm remains
        // valid world evidence, but an arbitrary enemy cannot become its warning landmark.
        manifestations["teaching.symbol.swarm_rune"] = []
        let storm = great.contains("wind") && sources.contains("rain")
        if storm || authoredIDs.contains("storm") { eligibleDanger.insert("teaching.symbol.storm") }
        manifestations["teaching.symbol.storm"] = []
        let predatoryEnemyPoints = Set(enemies.filter {
            !$0.isApex && ($0.traits?.armament.total ?? 0) >= Tuning.Life.unarmedThreshold
        }.map(\.position))
        let predatory = readings["vitality"].aspect("trophicDepth") >= Tuning.Life.predationThreshold
            || !predatoryEnemyPoints.isEmpty
        if predatory { eligibleDanger.insert("teaching.symbol.predation") }
        manifestations["teaching.symbol.predation"] = predatoryEnemyPoints
        let blight = great.contains("rot") || authoredIDs.contains("blight")
        if blight { eligibleDanger.insert("teaching.symbol.blight") }
        manifestations["teaching.symbol.blight"] = []
        let tremor = !cracking.isEmpty || authoredIDs.contains("tremor")
        if tremor { eligibleDanger.insert("teaching.symbol.tremor") }
        manifestations["teaching.symbol.tremor"] = tremor ? cracking : []
        let miasma = great.contains("miasma") || authoredIDs.contains("miasma_rune")
        if miasma { eligibleDanger.insert("teaching.symbol.miasma_rune") }
        manifestations["teaching.symbol.miasma_rune"] = []
        if authoredIDs.contains("peace") { eligibleDanger.insert("teaching.symbol.peace") }
        manifestations["teaching.symbol.peace"] = []
        return .init(generatedSourceIDs: sources, greatSourceIDs: great,
                     authoredCompositeIDs: authoredIDs,
                     eligibleDangerTeachingIDs: eligibleDanger,
                     manifestationPoints: manifestations)
    }

    static func placementPoint(for definition: RecoveredTeachingDefinitionV1,
                               manifestations: Set<GridPoint>,
                               in map: WorldMap, enemies: [WorldEnemy]) -> GridPoint? {
        let enemyPoints = Set(enemies.map(\.position))
        let unsafeRoutePoints = Set(map.allPoints.filter { point in
            if enemyPoints.contains(point) { return true }
            switch map[point].content {
            case .hazard, .site, .traveller: return true
            default: return false
            }
        })
        func distances(avoiding forbidden: Set<GridPoint> = []) -> [GridPoint: Int] {
            var result: [GridPoint: Int] = [map.entry: 0], queue = [map.entry], head = 0
            while head < queue.count {
                let point = queue[head]; head += 1
                for next in map.neighbours(of: point) where result[next] == nil && !forbidden.contains(next) {
                    let tile = map[next]
                    guard tile.isPassable, abs(tile.elevation - map[point].elevation) <= 1 else { continue }
                    result[next] = result[point, default: 0] + 1
                    queue.append(next)
                }
            }
            return result
        }
        let routeForbidden: Set<GridPoint>
        switch definition.placement {
        case .fieldInstruction, .localObservation, .quietCounterexample:
            routeForbidden = unsafeRoutePoints
        case .warningNote:
            routeForbidden = unsafeRoutePoints.union(manifestations)
        case .siteRubbing:
            routeForbidden = []
        }
        let routeDistances = distances(avoiding: routeForbidden)
        return map.allPoints.filter { point in
            guard let distance = routeDistances[point],
                  map[point].content == .empty, !enemyPoints.contains(point) else { return false }
            switch definition.placement {
            case .localObservation where !manifestations.isEmpty:
                return manifestations.compactMap { distancesFrom($0, in: map)[point] }.min()
                    .map { (1...4).contains($0) } ?? false
            case .warningNote:
                return manifestations.compactMap { distancesFrom($0, in: map)[point] }.min()
                    .map { (2...4).contains($0) } ?? false
            default:
                return (6...18).contains(distance)
            }
        }.sorted {
            let lhs = routeDistances[$0, default: .max], rhs = routeDistances[$1, default: .max]
            return lhs == rhs ? ($0.y, $0.x) < ($1.y, $1.x) : lhs < rhs
        }.first
    }

    private static func distancesFrom(_ start: GridPoint, in map: WorldMap) -> [GridPoint: Int] {
        guard map.contains(start) else { return [:] }
        var result = [start: 0], queue = [start], head = 0
        while head < queue.count {
            let point = queue[head]; head += 1
            for next in map.neighbours(of: point) where result[next] == nil {
                guard map[next].isPassable,
                      abs(map[next].elevation - map[point].elevation) <= 1 else { continue }
                result[next] = result[point, default: 0] + 1
                queue.append(next)
            }
        }
        return result
    }
}

extension GameStore {
    /// Applies a recovered lesson exactly once. The frozen record must agree with the immutable V1
    /// reward census; stale or fabricated presentation data cannot grant a different entitlement.
    @discardableResult
    func readRecoveredTeaching(_ id: RecoveredTeachingID) -> RecoveredTeachingReadResult {
        guard let index = state.reality.library.recoveredTeachings.firstIndex(
            where: { $0.teachingID == id }),
              let authority = RecoveredTeachingCatalogueV1.reward(for: id) else { return .invalid }
        let record = state.reality.library.recoveredTeachings[index]
        guard record.validates(), record.rewardKind == authority.kind,
              record.rewardID == authority.id else { return .invalid }
        guard !record.isRead else { return .alreadyRead(id) }

        mutate("read recovered teaching", flush: true) { state in
            guard let current = state.reality.library.recoveredTeachings.firstIndex(
                where: { $0.teachingID == id }),
                  state.reality.library.recoveredTeachings[current].readAt == nil else { return }
            switch authority.kind {
            case .gambitComponent:
                state.base.ownedGambitComponents.insert(.init(rawValue: authority.id))
            case .focus:
                state.base.ownedSources.insert(.init(rawValue: authority.id))
            case .symbol:
                state.base.ownedSymbols.insert(.init(rawValue: authority.id))
            case .capability:
                state.base.capabilities.insert(.init(rawValue: authority.id))
                if authority.id == "automate_self" { state.base.hasAutomateSelfUnlock = true }
            }
            state.reality.library.recoveredTeachings[current].readAt =
                state.reality.library.nextRecoveredTeachingSequence
            state.reality.library.nextRecoveredTeachingSequence += 1
        }
        return .committed(id)
    }
}

enum LibraryShelfID: String, Codable, CaseIterable, Sendable {
    case diaries, bestiary, dictionary, fieldNotes, worldHistory
}

enum LibraryHabitatFamily: String, Codable, CaseIterable, Sendable {
    case land, shore, water, air

    init(_ habitat: CreatureHabitat) {
        self = switch habitat {
        case .terrestrial: .land
        case .shore: .shore
        case .aquatic: .water
        case .aerial: .air
        }
    }
}

enum LibraryObjectID: Hashable, Sendable {
    case diary(TravellerID)
    case bestiary(habitat: LibraryHabitatFamily, volume: Int)
    case dictionary(volume: Int)
    case fieldNotes(volume: Int)
    case worldHistory(volume: Int)
}

enum LibraryObjectForm: String, Equatable, Sendable {
    case loosePage = "loose-page"
    case stitchedFolio = "stitched-folio"
    case softbound
    case hardcover
    case fullHardcoverWithSlips = "full-hardcover-with-slips"
}

struct LibraryShelfObjectPresentation: Equatable, Sendable {
    var id: LibraryObjectID
    var form: LibraryObjectForm
    var entryCount: Int
    var contentIDs: [LibraryAttentionContentID]
}

struct LibraryShelfPresentation: Equatable, Sendable {
    var id: LibraryShelfID
    var route: AppRoute
    var entryCount: Int
    var objects: [LibraryShelfObjectPresentation]
    var uncheckedCount: Int

    /// Collection roots may check only content that the root itself truthfully renders. Diary
    /// pages are behind an author route, so the diary grid never checks them on its own.
    static func contentIDsRenderedByCollectionRoot(_ shelfID: LibraryShelfID,
                                                   in state: GameState)
        -> Set<LibraryAttentionContentID> {
        shelfID == .diaries ? [] : contentIDs(for: shelfID, in: state)
    }

    static func make(in state: GameState) -> [Self] {
        let current = currentContentIDs(in: state)
        let checked = state.reality.library.attention.checkedContentIDs
        func shelf(_ id: LibraryShelfID, route: AppRoute,
                   objects: [LibraryShelfObjectPresentation]) -> Self {
            let ids = Set(objects.flatMap(\.contentIDs))
            return .init(id: id, route: route, entryCount: ids.count, objects: objects,
                         uncheckedCount: ids.subtracting(checked).count)
        }
        return [
            shelf(.diaries, route: .library, objects: diaryObjects(in: state)),
            shelf(.bestiary, route: .bestiary, objects: bestiaryObjects(in: state)),
            shelf(.dictionary, route: .library, objects: dictionaryObjects(in: state)),
            shelf(.fieldNotes, route: .library, objects: fieldNoteObjects(in: state)),
            shelf(.worldHistory, route: .worldHistory, objects: historyObjects(in: state)),
        ].map { value in
            var result = value
            // Legacy/unclassified content remains truthful in the count without inventing art.
            result.entryCount = current.filter { content in
                switch (result.id, content) {
                case (.diaries, .diaryPage(_)), (.bestiary, .bestiarySpecies(_)),
                     (.dictionary, .dictionaryCompound(_)), (.fieldNotes, .foundWriting(_)),
                     (.fieldNotes, .recoveredTeaching(_)),
                     (.worldHistory, .visitedWorld(_)): true
                default: false
                }
            }.count
            result.uncheckedCount = current.filter { !checked.contains($0) }.filter { content in
                switch (result.id, content) {
                case (.diaries, .diaryPage(_)), (.bestiary, .bestiarySpecies(_)),
                     (.dictionary, .dictionaryCompound(_)), (.fieldNotes, .foundWriting(_)),
                     (.fieldNotes, .recoveredTeaching(_)),
                     (.worldHistory, .visitedWorld(_)): true
                default: false
                }
            }.count
            return result
        }
    }

    static func currentContentIDs(in state: GameState) -> Set<LibraryAttentionContentID> {
        var result = Set((state.reality.library.recoveredPages.map(\.pageID)
            + state.reality.library.foundPages).map(LibraryAttentionContentID.diaryPage))
        result.formUnion(state.reality.discovery.species.compactMap { key, record in
            record.firstSeenRunIndex == nil ? nil : .bestiarySpecies(key)
        })
        let encountered = state.reality.encounteredLexemes
        result.formUnion(ContentCatalog.shared.symbols.compactMap { symbol in
            (encountered.contains(.compound(symbol.id)) || state.base.ownedSymbols.contains(symbol.id))
                ? .dictionaryCompound(symbol.id) : nil
        })
        result.formUnion(state.reality.library.foundWritings.map { .foundWriting($0.id) })
        result.formUnion(state.reality.library.recoveredTeachings.map {
            .recoveredTeaching($0.teachingID)
        })
        result.formUnion(state.reality.library.visitedWorlds.map { .visitedWorld($0.id) })
        return result
    }

    static func contentIDs(for shelf: LibraryShelfID,
                           in state: GameState) -> Set<LibraryAttentionContentID> {
        currentContentIDs(in: state).filter { content in
            switch (shelf, content) {
            case (.diaries, .diaryPage(_)), (.bestiary, .bestiarySpecies(_)),
                 (.dictionary, .dictionaryCompound(_)), (.fieldNotes, .foundWriting(_)),
                 (.fieldNotes, .recoveredTeaching(_)),
                 (.worldHistory, .visitedWorld(_)): true
            default: false
            }
        }
    }

    private static func diaryObjects(in state: GameState) -> [LibraryShelfObjectPresentation] {
        var seen = Set<DiaryPageID>()
        let pageIDs = (state.reality.library.recoveredPages.map(\.pageID)
            + state.reality.library.foundPages).filter { seen.insert($0).inserted }
        let pages = pageIDs.compactMap { id -> (TravellerID, LibraryAttentionContentID)? in
            guard let definition = ContentCatalog.shared.diaryPage(id) else { return nil }
            return (definition.diary, .diaryPage(id))
        }
        return ContentCatalog.shared.travellersInAuthoredOrder.compactMap { traveller in
            let ids = pages.filter { $0.0 == traveller.id }.map(\.1)
            guard !ids.isEmpty else { return nil }
            let form: LibraryObjectForm = switch ids.count {
            case 1: .loosePage
            case 2...3: .stitchedFolio
            case 4...6: .softbound
            case 7...9: .hardcover
            default: .fullHardcoverWithSlips
            }
            return .init(id: .diary(traveller.id), form: form,
                         entryCount: ids.count, contentIDs: ids)
        }
    }

    private static func bestiaryObjects(in state: GameState) -> [LibraryShelfObjectPresentation] {
        LibraryHabitatFamily.allCases.flatMap { habitat -> [LibraryShelfObjectPresentation] in
            let ids = state.reality.discovery.speciesHabitatByIdentity
                .filter { LibraryHabitatFamily($0.value) == habitat
                    && state.reality.discovery.species[$0.key]?.firstSeenRunIndex != nil }
                .map(\.key).sorted()
            return ids.chunkedLibrary(every: 8).enumerated().map { index, group in
                let form: LibraryObjectForm = switch group.count {
                case 1...2: .stitchedFolio
                case 3...5: .softbound
                default: .fullHardcoverWithSlips
                }
                return LibraryShelfObjectPresentation(
                    id: .bestiary(habitat: habitat, volume: index + 1), form: form,
                    entryCount: group.count,
                    contentIDs: group.map(LibraryAttentionContentID.bestiarySpecies))
            }
        }
    }

    private static func dictionaryObjects(in state: GameState) -> [LibraryShelfObjectPresentation] {
        let encountered = state.reality.encounteredLexemes
        return ContentCatalog.shared.symbols.chunkedLibrary(every: 7).enumerated().compactMap { index, group in
            let ids = group.filter { encountered.contains(.compound($0.id))
                || state.base.ownedSymbols.contains($0.id) }.map { LibraryAttentionContentID.dictionaryCompound($0.id) }
            guard !ids.isEmpty else { return nil }
            let form: LibraryObjectForm = ids.count <= 2 ? .stitchedFolio
                : (ids.count <= 5 ? .softbound : .hardcover)
            return .init(id: .dictionary(volume: index + 1), form: form,
                         entryCount: ids.count, contentIDs: ids)
        }
    }

    private static func fieldNoteObjects(in state: GameState) -> [LibraryShelfObjectPresentation] {
        var seen = Set<FoundWritingID>()
        let writingIDs = state.reality.library.foundWritings.compactMap {
            seen.insert($0.id).inserted ? LibraryAttentionContentID.foundWriting($0.id) : nil
        }
        let teachingIDs = state.reality.library.recoveredTeachings.map {
            LibraryAttentionContentID.recoveredTeaching($0.teachingID)
        }
        return (writingIDs + teachingIDs).chunkedLibrary(every: 8).enumerated().map { index, group in
            let form: LibraryObjectForm = group.count <= 2 ? .stitchedFolio
                : (group.count <= 5 ? .softbound : .fullHardcoverWithSlips)
            return .init(id: .fieldNotes(volume: index + 1), form: form,
                         entryCount: group.count, contentIDs: group)
        }
    }

    private static func historyObjects(in state: GameState) -> [LibraryShelfObjectPresentation] {
        state.reality.library.visitedWorlds.map(\.id).chunkedLibrary(every: 8).enumerated().map { index, group in
            let form: LibraryObjectForm = group.count <= 2 ? .stitchedFolio
                : (group.count <= 5 ? .softbound : .fullHardcoverWithSlips)
            return .init(id: .worldHistory(volume: index + 1), form: form,
                         entryCount: group.count, contentIDs: group.map(LibraryAttentionContentID.visitedWorld))
        }
    }
}

extension GameStore {
    /// A route may acknowledge only the exact underlying identities it actually rendered.
    func checkLibraryContent(_ rendered: Set<LibraryAttentionContentID>) {
        let unchecked = rendered.subtracting(state.reality.library.attention.checkedContentIDs)
        guard !unchecked.isEmpty else { return }
        mutate("check rendered Library content") { state in
            state.reality.library.attention.checkedContentIDs.formUnion(unchecked)
        }
    }
}

private extension Array {
    func chunkedLibrary(every size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map { Array(self[$0..<Swift.min($0 + size, count)]) }
    }
}

enum PlayerSigilCopy {
    static let singular = "Sigil"
    static let plural = "Sigils"

    static func count(_ count: Int) -> String {
        "\(count) \(count == 1 ? singular : plural)"
    }
}

/// Finding people, and finding the pages that say where they are.
///
/// The two are deliberately independent. **Pages are a guide, never a gate**: a traveller is simply
/// *at* a signature, so a player who writes the right world — deliberately or by luck — finds them
/// without ever having read a page. A lucky early clue leading to a late-game character is fine and
/// is not prevented anywhere in here.
enum LibraryRules {

    enum DictionaryCategory: Int, CaseIterable, Identifiable, Sendable {
        case subjects, sources, qualifiers, compounds

        var id: Int { rawValue }
        var displayName: String {
            switch self {
            case .subjects: "Subjects"
            case .sources: "Sources"
            case .qualifiers: "Qualifiers"
            case .compounds: "Compounds"
            }
        }
    }

    struct DictionaryEntry: Identifiable, Equatable, Sendable {
        var identity: LexemeIdentity
        var category: DictionaryCategory
        var isKnown: Bool
        var name: String?
        var explanation: String?

        var id: LexemeIdentity { identity }
        var glyphID: String { identity.glyphID }
        var displayName: String { isKnown ? (name ?? "Unknown Sigil") : "??" }
        var accessibilityName: String { isKnown ? (name ?? "Unknown Sigil") : "Unknown Sigil" }
    }

    /// Projects the Dictionary from durable sightings plus the canonical authorities that license
    /// writing. It never stores or infers a second knowledge flag.
    static func dictionaryEntries(reality: RealityState, base: BaseState,
                                  catalog: ContentCatalog = .shared) -> [DictionaryEntry] {
        let writableQualifiers = PageRules.writableQualifiers()
        var visible = reality.encounteredLexemes
        visible.formUnion(catalog.pressureTargets.map { .target($0.id) })
        visible.formUnion(writableQualifiers.map { .qualifier($0.id) })
        visible.formUnion(base.ownedSources.map(LexemeIdentity.source))
        visible.formUnion(base.ownedSymbols.map(LexemeIdentity.compound))

        let targetOrder = Dictionary(uniqueKeysWithValues:
            catalog.pressureTargetsInOrder.enumerated().map { ($0.element.id, $0.offset) })
        let sourceOrder = Dictionary(uniqueKeysWithValues:
            catalog.pressureSources.enumerated().map { ($0.element.id, $0.offset) })
        let qualifierOrder = Dictionary(uniqueKeysWithValues:
            writableQualifiers.enumerated().map { ($0.element.id, $0.offset) })
        let compoundOrder = Dictionary(uniqueKeysWithValues:
            catalog.symbols.enumerated().map { ($0.element.id, $0.offset) })

        func entry(_ identity: LexemeIdentity) -> DictionaryEntry {
            switch identity {
            case .target(let id):
                let definition = catalog.pressureTarget(id)
                return .init(identity: identity, category: .subjects,
                             isKnown: definition != nil, name: definition?.name,
                             explanation: definition?.blurb)
            case .source(let id):
                let definition = catalog.pressureSource(id)
                let known = base.ownedSources.contains(id) && definition != nil
                return .init(identity: identity, category: .sources, isKnown: known,
                             name: known ? definition?.name : nil,
                             explanation: known ? definition?.blurb : nil)
            case .qualifier(let id):
                let definition = catalog.qualifier(id)
                let known = writableQualifiers.contains { $0.id == id } && definition != nil
                return .init(identity: identity, category: .qualifiers, isKnown: known,
                             name: known ? definition?.name : nil,
                             explanation: known ? definition.map {
                                 "Changes \($0.ladder.job)."
                             } : nil)
            case .compound(let id):
                let definition = catalog.symbol(id)
                let known = base.ownedSymbols.contains(id) && definition != nil
                return .init(identity: identity, category: .compounds, isKnown: known,
                             name: known ? definition?.name : nil,
                             explanation: known ? definition?.blurb : nil)
            }
        }

        func authoredOrder(_ identity: LexemeIdentity) -> Int {
            switch identity {
            case .target(let id): targetOrder[id] ?? Int.max
            case .source(let id): sourceOrder[id] ?? Int.max
            case .qualifier(let id): qualifierOrder[id] ?? Int.max
            case .compound(let id): compoundOrder[id] ?? Int.max
            }
        }
        return visible.map(entry).sorted {
            if $0.category.rawValue != $1.category.rawValue {
                return $0.category.rawValue < $1.category.rawValue
            }
            let lhsOrder = authoredOrder($0.identity)
            let rhsOrder = authoredOrder($1.identity)
            if lhsOrder != rhsOrder { return lhsOrder < rhsOrder }
            return $0.glyphID < $1.glyphID
        }
    }

    // MARK: Finding people

    /// Everyone whose signature this world satisfies.
    static func travellersPresent(in readings: PressureReadings) -> [TravellerDef] {
        ContentCatalog.shared.travellersInAuthoredOrder.filter { $0.isFound(in: readings) }
    }

    struct TravellerSelection: Equatable {
        var eligible: [TravellerID]
        var selected: TravellerID?
        var exclusions: [TravellerGenerationExclusion]
        var evidence: [TravellerID: TravellerEvidence]
    }

    struct TravellerEvidence: Equatable {
        var recoveredClues: Int
        var causallyAuthoredConditions: Int
        var causallyAuthoredKnownConditions: Int
        var evidenceScore: Double
    }

    static func causalConditionIndices(for traveller: TravellerDef,
                                       actual: PressureReadings,
                                       withoutAuthoredPressure: PressureReadings) -> Set<Int> {
        Set(traveller.signature.indices.filter {
            traveller.signature[$0].condition.holds(in: actual)
                && !traveller.signature[$0].condition.holds(in: withoutAuthoredPressure)
        })
    }

    /// Freezes the single traveller this newly bound world may contain. Location knowledge may
    /// deliberately reach ahead; name/relationship knowledge never does because only exact
    /// recovered location clues enter `knownClueIndices`.
    static func selectTravellerForNewWorld(
        from signatureMatches: [TravellerDef],
        library: LibraryState,
        blindDiscoveryWindow: Int,
        causalConditionIndices: [TravellerID: Set<Int>] = [:],
        clueWeight: Double = 1,
        authoredWeight: Double = 2
    ) -> TravellerSelection {
        let window = min(6, max(1, blindDiscoveryWindow))
        let recruitedCount = library.foundTravellers.count
        let matches = signatureMatches.filter { !library.foundTravellers.contains($0.id) }
        let knownIndices = Dictionary(uniqueKeysWithValues: matches.map {
            ($0.id, library.knownClueIndices(for: $0.id)
                .intersection(Set($0.signature.indices)))
        })
        let eligibleDefs = matches.filter { traveller in
            if !(knownIndices[traveller.id] ?? []).isEmpty { return true }
            if traveller.campaignPhase == .opening { return true }
            let order = traveller.authoredOrder ?? Int.max
            return recruitedCount >= max(3, order - window)
        }
        let evidence = Dictionary(uniqueKeysWithValues: eligibleDefs.map { traveller in
            let known = knownIndices[traveller.id] ?? []
            let causal = causalConditionIndices[traveller.id] ?? []
            let knownCausal = known.intersection(causal).count
            return (traveller.id, TravellerEvidence(
                recoveredClues: known.count,
                causallyAuthoredConditions: causal.count,
                causallyAuthoredKnownConditions: knownCausal,
                evidenceScore: Double(known.count) * max(0, clueWeight)
                    + Double(knownCausal) * max(0, authoredWeight)))
        })
        let earliestBand = eligibleDefs.compactMap(\.storyArrivalBand).min()
        let sameBand = eligibleDefs.filter { $0.storyArrivalBand == earliestBand }
        let ranked = sameBand.sorted { lhs, rhs in
            let lhsEvidence = evidence[lhs.id]?.evidenceScore ?? 0
            let rhsEvidence = evidence[rhs.id]?.evidenceScore ?? 0
            if lhsEvidence != rhsEvidence { return lhsEvidence > rhsEvidence }
            let lhsOrder = lhs.authoredOrder ?? Int.max
            let rhsOrder = rhs.authoredOrder ?? Int.max
            if lhsOrder != rhsOrder { return lhsOrder < rhsOrder }
            return lhs.id.rawValue < rhs.id.rawValue
        }
        let selected = ranked.first?.id
        let eligibleIDs = eligibleDefs.sorted {
            let lhsOrder = $0.authoredOrder ?? Int.max
            let rhsOrder = $1.authoredOrder ?? Int.max
            return lhsOrder == rhsOrder ? $0.id.rawValue < $1.id.rawValue : lhsOrder < rhsOrder
        }.map(\.id)
        let eligibleSet = Set(eligibleIDs)
        let exclusions = matches.compactMap { traveller -> TravellerGenerationExclusion? in
            guard traveller.id != selected else { return nil }
            let reason: TravellerGenerationExclusion.Reason
            if !eligibleSet.contains(traveller.id) {
                reason = .phaseLocked
            } else if traveller.storyArrivalBand != earliestBand {
                reason = .laterStoryBand
            } else {
                reason = .lowerSameBandEvidence
            }
            return TravellerGenerationExclusion(traveller: traveller.id, reason: reason)
        }
        return TravellerSelection(eligible: eligibleIDs, selected: selected,
                                  exclusions: exclusions, evidence: evidence)
    }

    static func travellerArrivalChance(causallyAuthoredConditions: Int,
                                       totalConditions: Int,
                                       priorNearMisses: Int,
                                       floor: Double = 0.25,
                                       nearMissIncrement: Double = 0.25) -> Double {
        guard totalConditions > 0 else { return 0 }
        let causal = min(totalConditions, max(0, causallyAuthoredConditions))
        if causal == totalConditions || priorNearMisses >= 2 { return 1 }
        let boundedFloor = min(1, max(0, floor))
        let fraction = Double(causal) / Double(totalConditions)
        let base = boundedFloor + (1 - boundedFloor) * fraction
        return min(1, base + Double(max(0, priorNearMisses)) * max(0, nearMissIncrement))
    }

    // MARK: Finding pages

    struct PageSelectionBucket: Equatable {
        var key: String
        var pageIDs: [DiaryPageID]
        var weight: Double
    }

    static func pageSelectionBuckets(_ pages: [DiaryPageDef],
                                     readings: PressureReadings) -> [PageSelectionBucket] {
        let grouped = Dictionary(grouping: pages) { page -> String in
            if page.kind == .locationClue, let about = page.about {
                return "location:\(about.rawValue)"
            }
            return "diary:\(page.diary.rawValue)"
        }
        return grouped.keys.sorted().compactMap { key in
            guard let bucketPages = grouped[key], !bucketPages.isEmpty else { return nil }
            let total = bucketPages.reduce(0.0) { $0 + contextualPageWeight($1, in: readings) }
            return PageSelectionBucket(
                key: key,
                pageIDs: bucketPages.map(\.id).sorted { $0.rawValue < $1.rawValue },
                weight: total / Double(bucketPages.count))
        }
    }

    /// Which pages could surface in a given world.
    ///
    /// A page prefers a world its author would have had reason to be in. That preference is soft:
    /// once a page has waited longer than the threshold it will surface anywhere, because nothing
    /// may become permanently unreachable through how a player happens to write.
    static func eligiblePages(in readings: PressureReadings, library: LibraryState,
                              patienceInWorlds: Int = Tuning.Library.patienceInWorlds) -> [DiaryPageDef] {
        ContentCatalog.shared.diaryPages.filter { page in
            guard !library.hasFound(page.id) else { return false }
            if page.prefersConditions.isEmpty { return true }
            if page.prefersConditions.allSatisfy({ $0.holds(in: readings) }) { return true }
            return library.patiencePage == page.id
                && (library.pagesWaiting[page.id] ?? 0) >= patienceInWorlds
        }
    }

    /// Choose the pages a world will contain. Deterministic in the run's seed.
    static func placePages(in readings: PressureReadings, library: LibraryState,
                           additionalPageChance: Double = Tuning.Library.additionalPageChance,
                           patienceInWorlds: Int = Tuning.Library.patienceInWorlds,
                           rng: inout SeededRNG) -> [DiaryPageID] {
        let candidates = eligiblePages(in: readings, library: library,
                                       patienceInWorlds: patienceInWorlds)
            .sorted { $0.id.rawValue < $1.id.rawValue }
        guard !candidates.isEmpty else { return [] }

        let count = min(candidates.count, 1 + (rng.chance(additionalPageChance) ? 1 : 0))
        var pool = candidates
        var chosen: [DiaryPageID] = []

        // Once the nominated page reaches the fallback, the promise is paid immediately rather
        // than merely adding it to a large lottery where it could keep losing.
        if let nominee = library.patiencePage,
           (library.pagesWaiting[nominee] ?? 0) >= patienceInWorlds,
           pool.contains(where: { $0.id == nominee }) {
            chosen.append(nominee)
            pool.removeAll { $0.id == nominee }
        }
        for _ in 0..<count {
            guard chosen.count < count, !pool.isEmpty else { break }
            // Location clues compete as one bucket per person; every other page competes as one
            // bucket per diary. Averaging contextual page weights prevents a ten-page diary from
            // receiving ten times the aggregate chance of a one-page diary.
            let grouped = Dictionary(grouping: pool) { page -> String in
                page.kind == .locationClue && page.about != nil
                    ? "location:\(page.about!.rawValue)" : "diary:\(page.diary.rawValue)"
            }
            let buckets = pageSelectionBuckets(pool, readings: readings).map {
                (value: $0.key, weight: $0.weight)
            }
            guard let bucket = rng.pickWeighted(buckets), let bucketPages = grouped[bucket] else { break }
            let pageWeights = bucketPages.sorted { $0.id.rawValue < $1.id.rawValue }.map {
                (value: $0, weight: contextualPageWeight($0, in: readings))
            }
            guard let picked = rng.pickWeighted(pageWeights) else { break }
            chosen.append(picked.id)
            pool.removeAll { $0.id == picked.id }
        }
        return chosen
    }

    private static func contextualPageWeight(_ page: DiaryPageDef,
                                             in readings: PressureReadings) -> Double {
        let atHome = !page.prefersConditions.isEmpty
            && page.prefersConditions.allSatisfy { $0.holds(in: readings) }
        return atHome ? Tuning.Library.atHomeWeight : 1
    }

    /// Advance exactly one mismatched-placement clock after generating a world.
    static func advancePatience(after placed: [DiaryPageID], library: inout LibraryState) {
        let found = Set(library.foundPages)
        if let nominee = library.patiencePage,
           !found.contains(nominee), !placed.contains(nominee) {
            library.pagesWaiting = [nominee: (library.pagesWaiting[nominee] ?? 0) + 1]
            return
        }

        let next = ContentCatalog.shared.diaryPages
            .map(\.id)
            .first { !found.contains($0) && !placed.contains($0) }
        library.patiencePage = next
        library.pagesWaiting = next.map { [$0: 0] } ?? [:]
    }

    // MARK: The Library

    static func catalogueEntries(in library: LibraryState, search: String = "",
                                 filter: LibraryCatalogueFilter = .init(),
                                 catalog: ContentCatalog = .shared) -> [LibraryCatalogueEntry] {
        guard library.foundTravellers.contains("lys") else { return [] }
        let needle = search.trimmingCharacters(in: .whitespacesAndNewlines)

        var result: [LibraryCatalogueEntry] = []
        for recovery in library.recoveredPages.sorted(by: {
            $0.discoverySequence < $1.discoverySequence
        }) {
            guard let page = catalog.diaryPage(recovery.pageID) else {
                let entry = LibraryCatalogueEntry(recovery: recovery, page: nil,
                                                  writerName: nil, subjectName: nil,
                                                  teachingName: nil, references: [])
                if needle.isEmpty && filter.kinds.isEmpty && filter.writers.isEmpty
                    && filter.subjects.isEmpty && filter.teachingNames.isEmpty
                    && filter.worldRecordIDs.isEmpty { result.append(entry) }
                continue
            }
            let writer = catalog.traveller(page.diary)?.name
            let subject = page.about.flatMap { catalog.traveller($0)?.name }
            let teaching = teachingName(for: page, catalog: catalog)
            guard filter.kinds.isEmpty || filter.kinds.contains(page.kind),
                  filter.writers.isEmpty || filter.writers.contains(page.diary),
                  filter.subjects.isEmpty || page.about.map(filter.subjects.contains) == true,
                  filter.teachingNames.isEmpty || teaching.map(filter.teachingNames.contains) == true,
                  filter.worldRecordIDs.isEmpty
                    || recovery.foundInWorldRecordID.map(filter.worldRecordIDs.contains) == true
            else { continue }

            var visible = [page.kind.displayName, page.prose]
            if let writer { visible.append(writer) }
            if let subject { visible.append(subject) }
            if let teaching { visible.append(teaching) }
            if let worldID = recovery.foundInWorldRecordID,
               let world = library.visitedWorlds.first(where: { $0.id == worldID }) {
                visible.append("World \(world.runIndex)")
            }
            guard needle.isEmpty || visible.contains(where: {
                $0.localizedCaseInsensitiveContains(needle)
            }) else { continue }

            result.append(LibraryCatalogueEntry(
                recovery: recovery, page: page, writerName: writer, subjectName: subject,
                teachingName: teaching, references: references(for: page, recovery: recovery,
                                                               library: library, catalog: catalog)))
        }
        return result
    }

    static func references(for page: DiaryPageDef, recovery: RecoveredPageRecord,
                           library: LibraryState,
                           catalog: ContentCatalog = .shared) -> [LibraryPageReference] {
        var result: [LibraryPageReference] = []
        let writer = catalog.traveller(page.diary)?.name ?? "Unresolved person"
        result.append(.init(kind: .diary, label: writer, target: .traveller(page.diary)))
        if let about = page.about {
            result.append(.init(kind: .subject,
                                label: catalog.traveller(about)?.name ?? "Unresolved person",
                                target: .traveller(about)))
        }
        if let site = page.site {
            result.append(.init(kind: .place,
                                label: catalog.site(site)?.name ?? "Unresolved place",
                                target: .site(site)))
        }
        if let teaching = teachingName(for: page, catalog: catalog) {
            result.append(.init(kind: .teaching, label: teaching, target: .teaching(teaching)))
        }
        if let world = recovery.foundInWorldRecordID {
            let label = library.visitedWorlds.first(where: { $0.id == world })
                .map { "World \($0.runIndex)" } ?? "Record no longer kept"
            result.append(.init(kind: .recoveryWorld, label: label, target: .world(world)))
        }
        return result
    }

    private static func teachingName(for page: DiaryPageDef,
                                     catalog: ContentCatalog) -> String? {
        if let id = page.teaches { return catalog.symbol(id)?.name }
        if let id = page.teachesFocus { return catalog.pressureSource(id)?.name }
        if let id = page.teachesGambit { return catalog.gambitComponent(id)?.name }
        if let id = page.teachesPattern {
            return WorkshopPatternRegistry.definition(id)?.name
        }
        if let id = page.researchNode { return catalog.researchNode(id)?.name }
        return nil
    }

    /// What is known about where one traveller is.
    static func hintPage(for traveller: TravellerDef, library: LibraryState) -> HintPage {
        let known = library.knownClueIndices(for: traveller.id)
        return HintPage(
            traveller: traveller,
            passages: traveller.signature.indices.map { known.contains($0) ? traveller.signature[$0].passage : nil },
            isFound: library.foundTravellers.contains(traveller.id)
        )
    }

    /// Every diary the player has any reason to care about, hardest-known first.
    ///
    /// A traveller you've never heard of doesn't appear at all — the Library is what you know, not
    /// a checklist of what exists.
    /// Snapshot a world at the moment you enter it: what you wrote, and what it became.
    ///
    /// Taken here rather than at the Writing Desk because **the readings must include what rolled
    /// against you** — the unwritten targets the world decided for itself. That's the half a player
    /// can't see at the time and most wants to read later.
    static func record(book: BoundBook, page: Page, seed: UInt64, runIndex: Int,
                       travellers: [TravellerID],
                       worldVisualReceipt: WorldVisualReceipt? = nil,
                       atmospherePresentationReceipt: WorldAtmospherePresentationReceiptV1? = nil,
                       worldArrivalReceipt: WorldArrivalReceipt? = nil) -> VisitedWorld {
        let sigils = BookRules.sigils(for: book)
        let written = Set(sigils.map(\.target))
        let readings = BookRules.readings(for: book, seed: seed)
        let chains = PageRules.chains(on: page)

        var record = VisitedWorld(
            id: InstanceID(rawValue: seed),
            seed: seed,
            runIndex: runIndex,
            descriptionSentence: DescriptionRules.describe(readings, contradictions: [],
                                                           analysisTier: Tuning.Analysis.startingTier).sentence,
            written: chains.map { chain in
                "\(chain.target) ← " + chain.parts.map(\.phrase).joined(separator: " · ")
            },
            inertModifiers: chains.flatMap { chain in
                chain.parts.flatMap(\.qualifiers).filter(\.isInert).map { "\($0.name) on \(chain.target)" }
            },
            readings: Dictionary(uniqueKeysWithValues: readings.inOrder.map { reading in
                (reading.target.rawValue,
                 VisitedWorld.ReadingSnapshot(peak: reading.peak, floor: reading.floor,
                                              wasWritten: written.contains(reading.target),
                                              tags: reading.tags.sorted()))
            }),
            travellersPresent: travellers,
            focusAttributions: chains.flatMap { chain in
                chain.parts.flatMap { part in
                    part.effects.map { effect in
                        "\(part.source) → \(effect.target) \(effect.text)"
                            + (effect.isPrimary ? "" : " · secondary")
                    }
                }
            },
            focusEffects: chains.flatMap { chain in
                chain.parts.flatMap { part in
                    part.effects.map { effect in
                        RecordedFocusEffect(source: part.source,
                                            targetID: effect.targetID,
                                            target: effect.target,
                                            text: effect.text,
                                            isPrimary: effect.isPrimary)
                    }
                }
            },
            semanticRequests: TutorialRules.semanticRequests(on: page),
            bindEssencePaid: book.essencePaid,
            worldVisualReceipt: worldVisualReceipt,
            atmospherePresentationReceipt: atmospherePresentationReceipt,
            worldArrivalReceipt: worldArrivalReceipt,
            worldPageUseReceipt: book.worldPageUseReceipt
        )
        record.livingAnalysis = LivingAnalysisRules.analyze(readings)
        let clock = WorldClock(book: book, seed: seed)
        record.clockAnalysis = ClockAnalysis(band: clock.bandName,
                                             basePeriod: clock.basePeriod,
                                             regularity: clock.regularity,
                                             amplitude: clock.amplitude,
                                             isStopped: clock.isStopped)
        return record
    }

    static func hintPages(in library: LibraryState) -> [HintPage] {
        ContentCatalog.shared.travellersInAuthoredOrder
            .filter { library.knownTravellers.contains($0.id) || library.foundTravellers.contains($0.id) }
            .map { hintPage(for: $0, library: library) }
            .sorted { ($0.isFound ? 1 : 0, $0.traveller.name) < ($1.isFound ? 1 : 0, $1.traveller.name) }
    }
}
