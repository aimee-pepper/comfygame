import Foundation

/// Everything the player has read, and everyone they've found.
///
/// Lives in the **Reality** layer: pages read and people found are knowledge, and knowledge is
/// never taken back. A collapse can cost you a haul; it can't cost you a page you've already read.
struct LibraryState: Codable, Equatable, Sendable {
    /// Presentation-only acknowledgement ledger for the five physical Library shelves.
    var attention: LibraryAttentionStateV1 = .init()
    /// Canonical first-recovery receipts. `foundPages` remains a compatibility projection while
    /// older saves and callers migrate to these provenance-bearing records.
    var recoveredPages: [RecoveredPageRecord] = []
    /// Pages recovered, in the order found.
    var foundPages: [DiaryPageID] = []
    /// Anonymous notes recovered from worlds. These never affect diary completion or patience.
    var foundWritings: [FoundWritingRecord] = []
    /// Physical teachings recovered from worlds. Recovery and reward application are deliberately
    /// separate: an unread record is permanent knowledge of the object, not ownership of its
    /// lesson yet.
    var recoveredTeachings: [RecoveredTeachingRecord] = []
    /// Independent offer/pity receipts. A counter advances only for an eligible teaching and an
    /// uncollected offer remains due until that exact teaching is recovered.
    var recoveredTeachingOffers: [RecoveredTeachingOfferStateV1] = []
    /// Monotonic, gameplay-owned ordering for recovery/read receipts. Never wall-clock time.
    var nextRecoveredTeachingSequence: UInt64 = 0
    /// Travellers found — you have written the world they were in and gone there.
    var foundTravellers: Set<TravellerID> = []
    /// Travellers you know to look for, whether or not you know where they are.
    var knownTravellers: Set<TravellerID> = []
    /// Singular authored workshop patterns learned from diary pages.
    var knownPatterns: Set<WorkshopPatternID> = []
    /// Authored construction methods learned from diary pages. Unknown legacy IDs are retained.
    var knownSchematics: Set<SchematicID> = []
    /// Saved protection against repeated selected full-signature arrival failures.
    var travellerArrivalNearMisses: [TravellerID: Int] = [:]
    /// How many worlds have been generated since each page became eligible to appear.
    ///
    /// Pages prefer worlds relevant to their author, but nothing may be permanently unreachable
    /// because of how a player happens to write — so once this passes a threshold the page stops
    /// waiting and will surface anywhere.
    var pagesWaiting: [DiaryPageID: Int] = [:]
    /// Only this page accrues the mismatched-world patience fallback. One queue, not twenty-four
    /// independent clocks that all become universally eligible together.
    var patiencePage: DiaryPageID?

    /// **Every world you've been to, and what you wrote to get it** (Aimee, 6 Aug).
    ///
    /// The answer key, and it's a good one because it's **delayed**. Nothing here explains your
    /// mistake at the moment you make it — that would break "explanation is earned". It records the
    /// evidence, and what you can read of it grows with your analysis tier. The world where Mara
    /// wasn't becomes, later, the world where you can finally see that Atmosphere rolled ash and
    /// ate your sunlight.
    ///
    /// Which also makes the analysis instruments worth far more: they don't only help with the next
    /// world, they unlock every world you've already written.
    var visitedWorlds: [VisitedWorld] = []

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if c.contains(.attention) {
            attention = try c.decode(LibraryAttentionStateV1.self, forKey: .attention)
            guard attention.validates() else { throw DecodingError.dataCorruptedError(
                forKey: .attention, in: c, debugDescription: "Invalid Library attention receipt") }
        } else { attention = .init() }
        let decodedRecords = try c.decodeIfPresent([RecoveredPageRecord].self,
                                                   forKey: .recoveredPages) ?? []
        let decodedPages = try c.decodeIfPresent([DiaryPageID].self, forKey: .foundPages) ?? []
        let canonicalPages = decodedPages.reduce(into: [DiaryPageID]()) { result, page in
            let canonical = page.canonicalLegacyID
            if !result.contains(where: { $0 == canonical }) { result.append(canonical) }
        }
        if decodedRecords.isEmpty {
            recoveredPages = canonicalPages.enumerated().map {
                RecoveredPageRecord(pageID: $0.element, discoverySequence: $0.offset)
            }
        } else {
            recoveredPages = decodedRecords.sorted {
                $0.discoverySequence < $1.discoverySequence
            }.reduce(into: [RecoveredPageRecord]()) { result, record in
                var canonical = record
                canonical.pageID = record.pageID.canonicalLegacyID
                guard !result.contains(where: { $0.pageID == canonical.pageID }) else { return }
                result.append(canonical)
            }
            for page in canonicalPages where !recoveredPages.contains(where: { $0.pageID == page }) {
                recoveredPages.append(RecoveredPageRecord(
                    pageID: page, discoverySequence: recoveredPages.count))
            }
            recoveredPages = recoveredPages.enumerated().map { offset, record in
                var canonical = record
                canonical.discoverySequence = offset
                return canonical
            }
        }
        foundPages = recoveredPages.map(\.pageID)
        foundWritings = try c.decodeIfPresent([FoundWritingRecord].self, forKey: .foundWritings) ?? []
        recoveredTeachings = try c.decodeIfPresent(
            [RecoveredTeachingRecord].self, forKey: .recoveredTeachings) ?? []
        recoveredTeachingOffers = try c.decodeIfPresent(
            [RecoveredTeachingOfferStateV1].self, forKey: .recoveredTeachingOffers) ?? []
        nextRecoveredTeachingSequence = try c.decodeIfPresent(
            UInt64.self, forKey: .nextRecoveredTeachingSequence) ?? 0
        guard RecoveredTeachingPersistence.validates(
            records: recoveredTeachings, offers: recoveredTeachingOffers,
            nextSequence: nextRecoveredTeachingSequence) else {
            throw DecodingError.dataCorruptedError(
                forKey: .recoveredTeachings, in: c,
                debugDescription: "Invalid recovered-teaching receipts")
        }
        foundTravellers = try c.decodeIfPresent(Set<TravellerID>.self, forKey: .foundTravellers) ?? []
        knownTravellers = try c.decodeIfPresent(Set<TravellerID>.self, forKey: .knownTravellers) ?? []
        // WorkshopPatternID has the same single-string wire representation as the historical
        // Set<String>. Unknown saved IDs remain intact: content validation prevents authoring new
        // dangling rewards, but migration must never erase knowledge from an older build.
        knownPatterns = try c.decodeIfPresent(Set<WorkshopPatternID>.self,
                                              forKey: .knownPatterns) ?? []
        knownSchematics = try c.decodeIfPresent(Set<SchematicID>.self,
                                                forKey: .knownSchematics) ?? []
        travellerArrivalNearMisses = (try c.decodeIfPresent([TravellerID: Int].self,
            forKey: .travellerArrivalNearMisses) ?? [:]).mapValues { max(0, $0) }
        let decodedWaiting = try c.decodeIfPresent([DiaryPageID: Int].self, forKey: .pagesWaiting) ?? [:]
        pagesWaiting = decodedWaiting.reduce(into: [:]) { result, entry in
            let canonical = entry.key.canonicalLegacyID
            result[canonical] = max(result[canonical] ?? 0, entry.value)
        }
        let decodedPatience = try c.decodeIfPresent(DiaryPageID.self, forKey: .patiencePage)
        patiencePage = decodedPatience.map(\.canonicalLegacyID)
        visitedWorlds = try c.decodeIfPresent([VisitedWorld].self, forKey: .visitedWorlds) ?? []
    }

    func hasFound(_ page: DiaryPageID) -> Bool {
        recoveredPages.contains { $0.pageID == page }
            || foundPages.contains(where: { $0 == page })
    }

    mutating func recordPage(_ page: DiaryPageID, worldRecordID: InstanceID?, siteID: SiteID?) {
        guard !hasFound(page) else { return }
        recoveredPages.append(RecoveredPageRecord(
            pageID: page, discoverySequence: recoveredPages.count,
            foundInWorldRecordID: worldRecordID, foundAtSiteID: siteID))
        foundPages = recoveredPages.map(\.pageID)
    }

    /// Inserts the immutable physical recovery receipt before its world object is removed.
    @discardableResult
    mutating func recordTeaching(_ candidate: RecoveredTeachingRecord) -> RecoveredTeachingRecordResult {
        if recoveredTeachings.contains(where: { $0.teachingID == candidate.teachingID }) {
            recoveredTeachingOffers.removeAll { $0.teachingID == candidate.teachingID }
            return .alreadyRecorded
        }
        guard candidate.validates(), candidate.readAt == nil,
              candidate.recoveredAt == nextRecoveredTeachingSequence else { return .refused }
        recoveredTeachings.append(candidate)
        recoveredTeachingOffers.removeAll { $0.teachingID == candidate.teachingID }
        nextRecoveredTeachingSequence += 1
        return .inserted
    }

    mutating func attachOutcome(_ outcomeID: ExpeditionOutcomeID, toWorld worldID: InstanceID) {
        for index in recoveredPages.indices
        where recoveredPages[index].foundInWorldRecordID == worldID
            && recoveredPages[index].foundInOutcomeID == nil {
            recoveredPages[index].foundInOutcomeID = outcomeID
        }
        for index in recoveredTeachings.indices
        where recoveredTeachings[index].worldSeed == worldID.rawValue
            && recoveredTeachings[index].recoveredAtOutcomeID == nil {
            recoveredTeachings[index].recoveredAtOutcomeID = outcomeID
        }
    }

    mutating func applyTravellerArrival(_ receipt: TravellerArrivalReceipt) {
        guard let id = receipt.selectedTraveller else { return }
        switch receipt.outcome {
        case .confidenceFailed:
            travellerArrivalNearMisses[id, default: 0] += 1
        case .placed:
            travellerArrivalNearMisses[id] = nil
        case .noEligibleMatch, .placementFailed:
            break
        }
    }

    /// Adds a world to the history, dropping the oldest **unkept** ones past the cap.
    ///
    /// Capped because the save is rewritten after every action and an unbounded list of every world
    /// ever written would grow without limit. Kept worlds are never dropped — that's what keeping
    /// one is for.
    mutating func record(world: VisitedWorld) {
        visitedWorlds.append(world)
        var overflow = visitedWorlds.count - Tuning.Library.worldsRemembered
        guard overflow > 0 else { return }
        visitedWorlds.removeAll { candidate in
            guard overflow > 0, !candidate.isKept else { return false }
            overflow -= 1
            return true
        }
    }

    /// The pieces of a traveller's location the player has actually read.
    func knownClueIndices(for traveller: TravellerID) -> Set<Int> {
        Set(foundPages
            .compactMap { ContentCatalog.shared.diaryPage($0) }
            .filter { $0.kind == .locationClue && $0.about == traveller }
            .compactMap(\.clueIndex))
    }
}

struct RecoveredTeachingID: StringIdentifier {
    var rawValue: String
    init(rawValue: String) { self.rawValue = rawValue }
}

enum RecoveredTeachingRewardKind: String, Codable, Sendable {
    case gambitComponent, focus, symbol, capability
}

enum RecoveredTeachingRecordResult: Equatable, Sendable {
    case inserted
    case alreadyRecorded
    case refused
}

struct RecoveredTeachingRecord: Codable, Equatable, Identifiable, Sendable {
    static let catalogueVersion = 1

    var teachingID: RecoveredTeachingID
    var catalogueVersion: Int
    var rewardKind: RecoveredTeachingRewardKind
    var rewardID: String
    var recoveredAtOutcomeID: ExpeditionOutcomeID?
    var worldSeed: UInt64?
    var sourcePlacementIdentity: String
    var recoveredAt: UInt64
    var readAt: UInt64?
    var frozenTitle: String
    var frozenInstructionCopy: String

    var id: RecoveredTeachingID { teachingID }
    var isRead: Bool { readAt != nil }

    func validates() -> Bool {
        catalogueVersion == Self.catalogueVersion && !rewardID.isEmpty
            && !sourcePlacementIdentity.isEmpty && !frozenTitle.isEmpty
            && !frozenInstructionCopy.isEmpty && (readAt == nil || readAt! >= recoveredAt)
    }
}

struct RecoveredTeachingOfferStateV1: Codable, Equatable, Identifiable, Sendable {
    static let version = 1
    var version: Int = Self.version
    var teachingID: RecoveredTeachingID
    var eligibleWorldsWithoutOffer: Int = 0
    var firstEligibleOutcomeIndex: Int?
    var isDue: Bool = false

    var id: RecoveredTeachingID { teachingID }

    func validates() -> Bool {
        version == Self.version && eligibleWorldsWithoutOffer >= 0
            && (firstEligibleOutcomeIndex == nil || firstEligibleOutcomeIndex! >= 0)
    }
}

/// Frozen offer/pity result for one newly generated world. It is applied only when that
/// expedition resolves; anchored revisits retain the resolved outcome and cannot advance pity.
struct RecoveredTeachingExpeditionReceiptV1: Codable, Equatable, Sendable {
    var version: Int = 1
    var offeredTeachingID: RecoveredTeachingID?
    var placement: GridPoint?
    var resultingOfferStates: [RecoveredTeachingOfferStateV1]
    var resolvedAtOutcomeID: ExpeditionOutcomeID?

    func validates() -> Bool {
        guard version == 1,
              Set(resultingOfferStates.map(\.teachingID)).count == resultingOfferStates.count,
              resultingOfferStates.allSatisfy({
                  $0.validates() && RecoveredTeachingCatalogueV1.reward(for: $0.teachingID) != nil
              })
        else { return false }
        switch (offeredTeachingID, placement) {
        case (nil, nil): break
        case (.some(let id), .some(let point)):
            guard RecoveredTeachingCatalogueV1.reward(for: id) != nil,
                  point.x >= 0, point.y >= 0,
                  let selected = resultingOfferStates.first(where: { $0.teachingID == id }),
                  selected.validates(), selected.isDue else { return false }
        default: return false
        }
        return true
    }

    /// Current-schema receipt/map agreement. An outstanding offer owns exactly one matching map
    /// object. Once collected, that object is empty only when Reality carries the exact recovery
    /// receipt for this world and placement. No other recovered-teaching tile may coexist.
    func validates(map: WorldMap, worldSeed: UInt64,
                   recovered: [RecoveredTeachingRecord]) -> Bool {
        guard validates() else { return false }
        let teachingTiles = map.allPoints.compactMap { point -> (GridPoint, RecoveredTeachingID)? in
            guard case .recoveredTeaching(let id) = map[point].content else { return nil }
            return (point, id)
        }
        guard let offeredTeachingID, let placement else { return teachingTiles.isEmpty }
        guard map.contains(placement), teachingTiles.allSatisfy({
            $0.0 == placement && $0.1 == offeredTeachingID
        }) else { return false }
        if case .recoveredTeaching(let tileID) = map[placement].content {
            return tileID == offeredTeachingID && teachingTiles.count == 1
        }
        guard map[placement].content == .empty else { return false }
        let expectedSource = "world:\(worldSeed):\(placement.x),\(placement.y)"
        return recovered.contains {
            $0.teachingID == offeredTeachingID && $0.worldSeed == worldSeed
                && $0.sourcePlacementIdentity == expectedSource && $0.validates()
        }
    }
}

enum RecoveredTeachingPersistence {
    static func validates(records: [RecoveredTeachingRecord],
                          offers: [RecoveredTeachingOfferStateV1],
                          nextSequence: UInt64) -> Bool {
        let recordIDs = records.map(\.teachingID)
        let offerIDs = offers.map(\.teachingID)
        guard Set(recordIDs).count == recordIDs.count,
              Set(offerIDs).count == offerIDs.count,
              records.allSatisfy({ $0.validates() }),
              records.allSatisfy({ record in
                  RecoveredTeachingCatalogueV1.reward(for: record.teachingID).map {
                      $0.kind == record.rewardKind && $0.id == record.rewardID
                  } == true
              }),
              offers.allSatisfy({ $0.validates()
                  && RecoveredTeachingCatalogueV1.reward(for: $0.teachingID) != nil }) else {
            return false
        }
        let sequences = records.flatMap { [$0.recoveredAt, $0.readAt].compactMap { $0 } }
        return Set(sequences).count == sequences.count
            && sequences.allSatisfy { $0 < nextSequence }
    }
}

enum LibraryAttentionContentID: Codable, Equatable, Hashable, Sendable {
    case diaryPage(DiaryPageID)
    case bestiarySpecies(String)
    case dictionaryCompound(SymbolID)
    case foundWriting(FoundWritingID)
    case recoveredTeaching(RecoveredTeachingID)
    case visitedWorld(InstanceID)
}

struct LibraryAttentionStateV1: Codable, Equatable, Sendable {
    static let version = 1
    var version: Int = Self.version
    var checkedContentIDs: Set<LibraryAttentionContentID> = []

    func validates() -> Bool { version == Self.version }
}

/// Transitional source compatibility while rules and presentation move to WorkshopPatternID.
/// Persistence and ownership are typed now; these overloads prevent parallel string conversion
/// logic from spreading through every existing consumer in the same checkpoint.
extension Set where Element == WorkshopPatternID {
    func contains(_ rawValue: String) -> Bool {
        contains(WorkshopPatternID(rawValue: rawValue))
    }

    @discardableResult
    mutating func insert(_ rawValue: String) -> (inserted: Bool, memberAfterInsert: Element) {
        insert(WorkshopPatternID(rawValue: rawValue))
    }

    @discardableResult
    mutating func remove(_ rawValue: String) -> Element? {
        remove(WorkshopPatternID(rawValue: rawValue))
    }
}

struct RecoveredPageRecord: Codable, Equatable, Sendable {
    var pageID: DiaryPageID
    var discoverySequence: Int
    var foundInOutcomeID: ExpeditionOutcomeID?
    var foundInWorldRecordID: InstanceID?
    var foundAtSiteID: SiteID?

    init(pageID: DiaryPageID, discoverySequence: Int,
         foundInOutcomeID: ExpeditionOutcomeID? = nil,
         foundInWorldRecordID: InstanceID? = nil, foundAtSiteID: SiteID? = nil) {
        self.pageID = pageID
        self.discoverySequence = discoverySequence
        self.foundInOutcomeID = foundInOutcomeID
        self.foundInWorldRecordID = foundInWorldRecordID
        self.foundAtSiteID = foundAtSiteID
    }
}

struct LibraryCatalogueFilter: Equatable, Sendable {
    var kinds: Set<DiaryPageDef.Kind> = []
    var writers: Set<TravellerID> = []
    var subjects: Set<TravellerID> = []
    var teachingNames: Set<String> = []
    var worldRecordIDs: Set<InstanceID> = []
}

struct LibraryCatalogueEntry: Equatable, Sendable {
    var recovery: RecoveredPageRecord
    var page: DiaryPageDef?
    var writerName: String?
    var subjectName: String?
    var teachingName: String?
    var references: [LibraryPageReference]

    var isOlderRecord: Bool { page == nil }
}

struct LibraryPageReference: Equatable, Sendable {
    enum Kind: String, Sendable { case diary, subject, place, teaching, recoveryWorld }
    enum Target: Equatable, Sendable {
        case traveller(TravellerID), site(SiteID), teaching(String), world(InstanceID)
    }
    var kind: Kind
    var label: String
    var target: Target
}

struct FoundWritingRecord: Codable, Equatable, Identifiable, Sendable {
    enum Family: String, Codable, CaseIterable, Sendable {
        case fieldNote, routeMark, siteFragment, workingScrap
    }
    var id: FoundWritingID
    var family: Family
    var prose: String
    var position: GridPoint
    /// Structured truth behind a generated Field note. Optional so every existing save and every
    /// authored non-Field writing remains valid without reconstruction.
    var templateID: String? = nil
    var fieldFact: FieldNoteFact? = nil
    var originWorldSeed: UInt64? = nil

    private enum CodingKeys: String, CodingKey {
        case id, family, prose, position, templateID, fieldFact, originWorldSeed
    }

    init(id: FoundWritingID, family: Family, prose: String, position: GridPoint,
         templateID: String? = nil, fieldFact: FieldNoteFact? = nil,
         originWorldSeed: UInt64? = nil) {
        self.id = id
        self.family = family
        self.prose = prose
        self.position = position
        self.templateID = templateID
        self.fieldFact = fieldFact
        self.originWorldSeed = originWorldSeed
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(FoundWritingID.self, forKey: .id)
        family = try c.decode(Family.self, forKey: .family)
        prose = try c.decode(String.self, forKey: .prose)
        position = try c.decode(GridPoint.self, forKey: .position)
        templateID = try c.decodeIfPresent(String.self, forKey: .templateID)
        // A future fact case must not make the recovered prose unreadable in an older build.
        fieldFact = try? c.decodeIfPresent(FieldNoteFact.self, forKey: .fieldFact)
        originWorldSeed = try c.decodeIfPresent(UInt64.self, forKey: .originWorldSeed)
    }
}

/// Only qualitative tokens printed by a Field-note template. This deliberately cannot carry a
/// hidden entity, resource table, species identity, pressure reading or numeric threshold.
struct FieldNoteTokens: Codable, Equatable, Sendable {
    var groundA: String? = nil
    var groundB: String? = nil
    var direction: String? = nil
    var relation: String? = nil
    var quality: String? = nil
}

enum FieldNoteFact: Codable, Equatable, Sendable {
    case terrain(FieldNoteTokens)
    case lightAir(FieldNoteTokens)
    case growth(FieldNoteTokens)
    case water(FieldNoteTokens)
}

/// The Library's page for one diary: everything known about where its author is.
///
/// **It collects, it does not interpret.** The passages are assembled side by side and gaps are
/// shown as gaps. It never renders them as a condition list and never names a sigil, a target or a
/// value — the player does the translation, and doing it is the game.
///
/// It shows **how many** pieces are missing, because knowing you have four of six tells you whether
/// to keep hunting or to gamble. It does not show what *kind* of piece is missing; that would be
/// interpretation.
struct HintPage: Equatable, Sendable {
    var traveller: TravellerDef
    /// One entry per piece of the signature, in order. `nil` where the page hasn't been found.
    var passages: [String?]
    var isFound: Bool

    var knownCount: Int { passages.compactMap { $0 }.count }
    var missingCount: Int { passages.count - knownCount }
    var isComplete: Bool { missingCount == 0 }

    /// Enough to write toward, even with gaps: what you don't know, you leave to chance.
    var canBeAttempted: Bool { knownCount > 0 }
}


/// One world you wrote and stood in.
///
/// Holds **what you wrote** and **what it became**, so the two can be read side by side later with
/// better instruments than you had at the time. Kept deliberately small: the chains as text and the
/// readings as numbers, not the map — a map is a thing you were in, not a thing you can learn from.
struct VisitedWorld: Codable, Equatable, Identifiable, Sendable {

    var id: InstanceID
    /// The world's own seed. Its identity, and what would let it be written again.
    var seed: UInt64
    /// Which run this was, so the list reads in the order you lived it.
    var runIndex: Int
    /// The prose you were shown at the time.
    var descriptionSentence: String
    /// The chains you placed, flattened to text — *Illumination ← Vast Sun*.
    var written: [String]
    /// Normalized target chains used for semantic comparison. Old records fall back to `written`.
    var semanticRequests: [String]
    /// Exact Essence paid when this authored world was bound. Legacy History records omit it;
    /// runway estimates must exclude those records rather than repricing old writing with today's rules.
    var bindEssencePaid: Int?
    /// **A modifier written where it changed nothing.** The thing you most want to find later.
    ///
    /// Called `inertRungs` until 6 Aug — *rung* was a spec coinage nobody had ever defined for the
    /// player, and it was one field away from surfacing on screen (`jargon-audit.md`). The rule
    /// now: a word invented in a spec is either defined in the interface or renamed before it
    /// reaches it.
    var inertModifiers: [String]
    /// Every target's peak and floor, for when you can read that far.
    var readings: [String: ReadingSnapshot]
    /// Tier-3 cause-and-effect lines captured while the page's focus structure is available.
    /// Retained for tolerant decoding of saves written before attributions carried target IDs.
    var focusAttributions: [String] = []
    /// Structured attributions allow History to apply the player's *current* calibration gate:
    /// returning with a new instrument can reveal an old world's secondary without saving it in
    /// already-disclosed prose.
    var focusEffects: [RecordedFocusEffect] = []
    /// Captured while the complete pressure readings still exist; old records simply lack it.
    var livingAnalysis: LivingAnalysis?
    /// Resolved after arrival, retained independently of the simulation object so History can
    /// explain the world's clock as the player's Cycle instrument becomes readable.
    var clockAnalysis: ClockAnalysis?
    /// Frozen visual authority captured with the world. Legacy History records omit it and remain
    /// on world-grade 1; History never re-resolves current catalogue facts into a newer receipt.
    var worldVisualReceipt: WorldVisualReceipt?
    var atmospherePresentationReceipt: WorldAtmospherePresentationReceiptV1
    /// Exact immutable arrival receipt shown for this binding. Legacy History omits it.
    var worldArrivalReceipt: WorldArrivalReceipt?
    /// Frozen physical-page provenance. Legacy and ordinarily written worlds omit it.
    var worldPageUseReceipt: WorldPageUseReceipt?
    /// Who was standing in it, whether or not you reached them.
    var travellersPresent: [TravellerID]
    /// **Kept on purpose.** The list is curated rather than infinite (Aimee, 6 Aug) — a kept world
    /// survives a clear-out.
    var isKept: Bool = false

    struct ReadingSnapshot: Codable, Equatable, Sendable {
        var peak: Double
        var floor: Double
        /// Whether the page said anything at all about this target, or the world decided for you.
        /// **The single most useful thing in the whole record** — it's the answer to "what rolled
        /// over me".
        var wasWritten: Bool
        var tags: [String]

        init(peak: Double, floor: Double, wasWritten: Bool, tags: [String]) {
            self.peak = peak
            self.floor = floor
            self.wasWritten = wasWritten
            self.tags = tags
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            peak = try c.decodeIfPresent(Double.self, forKey: .peak) ?? 0
            floor = try c.decodeIfPresent(Double.self, forKey: .floor) ?? 0
            wasWritten = try c.decodeIfPresent(Bool.self, forKey: .wasWritten) ?? false
            tags = try c.decodeIfPresent([String].self, forKey: .tags) ?? []
        }
    }

    init(id: InstanceID, seed: UInt64, runIndex: Int, descriptionSentence: String,
         written: [String], inertModifiers: [String], readings: [String: ReadingSnapshot],
         travellersPresent: [TravellerID], isKept: Bool = false,
         focusAttributions: [String] = [], focusEffects: [RecordedFocusEffect] = [],
         semanticRequests: [String]? = nil,
         bindEssencePaid: Int? = nil,
         worldVisualReceipt: WorldVisualReceipt? = nil,
         atmospherePresentationReceipt: WorldAtmospherePresentationReceiptV1? = nil,
         worldArrivalReceipt: WorldArrivalReceipt? = nil,
         worldPageUseReceipt: WorldPageUseReceipt? = nil) {
        self.id = id
        self.seed = seed
        self.runIndex = runIndex
        self.descriptionSentence = descriptionSentence
        self.written = written
        self.semanticRequests = semanticRequests ?? written
        self.bindEssencePaid = bindEssencePaid
        self.inertModifiers = inertModifiers
        self.readings = readings
        self.travellersPresent = travellersPresent
        self.isKept = isKept
        self.focusAttributions = focusAttributions
        self.focusEffects = focusEffects
        self.livingAnalysis = nil
        self.clockAnalysis = nil
        self.worldVisualReceipt = worldVisualReceipt
        self.atmospherePresentationReceipt = atmospherePresentationReceipt
            ?? .migratingLegacy(worldVisualReceipt, seed: seed)
        self.worldArrivalReceipt = worldArrivalReceipt
        self.worldPageUseReceipt = worldPageUseReceipt
    }

    /// Includes the retired `inertRungs`, so a history written before the rename still reads.
    private enum CodingKeys: String, CodingKey {
        case id, seed, runIndex, descriptionSentence, written, semanticRequests, bindEssencePaid, inertModifiers, readings
        case travellersPresent, isKept, focusAttributions, focusEffects, livingAnalysis, clockAnalysis
        case worldVisualReceipt, atmospherePresentationReceipt, worldArrivalReceipt, worldPageUseReceipt
        case inertRungs
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(seed, forKey: .seed)
        try c.encode(runIndex, forKey: .runIndex)
        try c.encode(descriptionSentence, forKey: .descriptionSentence)
        try c.encode(written, forKey: .written)
        try c.encode(semanticRequests, forKey: .semanticRequests)
        try c.encodeIfPresent(bindEssencePaid, forKey: .bindEssencePaid)
        try c.encode(inertModifiers, forKey: .inertModifiers)
        try c.encode(readings, forKey: .readings)
        try c.encode(focusAttributions, forKey: .focusAttributions)
        try c.encode(focusEffects, forKey: .focusEffects)
        try c.encodeIfPresent(livingAnalysis, forKey: .livingAnalysis)
        try c.encodeIfPresent(clockAnalysis, forKey: .clockAnalysis)
        try c.encodeIfPresent(worldVisualReceipt, forKey: .worldVisualReceipt)
        try c.encode(atmospherePresentationReceipt, forKey: .atmospherePresentationReceipt)
        try c.encodeIfPresent(worldArrivalReceipt, forKey: .worldArrivalReceipt)
        try c.encodeIfPresent(worldPageUseReceipt, forKey: .worldPageUseReceipt)
        try c.encode(travellersPresent, forKey: .travellersPresent)
        try c.encode(isKept, forKey: .isKept)
    }

    /// Tolerant, per the policy in `Migrations.swift`.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(InstanceID.self, forKey: .id)
        seed = try c.decodeIfPresent(UInt64.self, forKey: .seed) ?? 0
        runIndex = try c.decodeIfPresent(Int.self, forKey: .runIndex) ?? 0
        descriptionSentence = try c.decodeIfPresent(String.self, forKey: .descriptionSentence) ?? ""
        written = try c.decodeIfPresent([String].self, forKey: .written) ?? []
        semanticRequests = try c.decodeIfPresent([String].self, forKey: .semanticRequests) ?? written
        bindEssencePaid = try c.decodeIfPresent(Int.self, forKey: .bindEssencePaid).map { max(0, $0) }
        inertModifiers = try c.decodeIfPresent([String].self, forKey: .inertModifiers)
            ?? c.decodeIfPresent([String].self, forKey: .inertRungs) ?? []
        readings = try c.decodeIfPresent([String: ReadingSnapshot].self, forKey: .readings) ?? [:]
        focusAttributions = try c.decodeIfPresent([String].self, forKey: .focusAttributions) ?? []
        focusEffects = try c.decodeIfPresent([RecordedFocusEffect].self, forKey: .focusEffects) ?? []
        livingAnalysis = try c.decodeIfPresent(LivingAnalysis.self, forKey: .livingAnalysis)
        clockAnalysis = try c.decodeIfPresent(ClockAnalysis.self, forKey: .clockAnalysis)
        worldVisualReceipt = try c.decodeIfPresent(WorldVisualReceipt.self,
                                                    forKey: .worldVisualReceipt)
        if c.contains(.atmospherePresentationReceipt) {
            atmospherePresentationReceipt = (try? c.decode(
                WorldAtmospherePresentationReceiptV1.self,
                forKey: .atmospherePresentationReceipt)).flatMap { $0.validates() ? $0 : nil }
                ?? .clear(seed: seed)
        } else {
            atmospherePresentationReceipt = .migratingLegacy(worldVisualReceipt, seed: seed)
        }
        worldArrivalReceipt = try c.decodeIfPresent(WorldArrivalReceipt.self,
                                                     forKey: .worldArrivalReceipt)
        worldPageUseReceipt = try c.decodeIfPresent(WorldPageUseReceipt.self,
                                                     forKey: .worldPageUseReceipt)
        travellersPresent = try c.decodeIfPresent([TravellerID].self, forKey: .travellersPresent) ?? []
        isKept = try c.decodeIfPresent(Bool.self, forKey: .isKept) ?? false
    }
}

struct ClockAnalysis: Codable, Equatable, Sendable {
    var band: String
    var basePeriod: Int
    var regularity: Double
    var amplitude: Double
    var isStopped: Bool
}

struct RecordedFocusEffect: Codable, Equatable, Sendable {
    var source: String
    var targetID: PressureTargetID
    var target: String
    var text: String
    var isPrimary: Bool

    var line: String {
        "\(source) → \(target) \(text)" + (isPrimary ? "" : " · secondary")
    }
}
