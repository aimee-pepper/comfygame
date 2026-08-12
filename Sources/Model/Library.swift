import Foundation

/// Everything the player has read, and everyone they've found.
///
/// Lives in the **Reality** layer: pages read and people found are knowledge, and knowledge is
/// never taken back. A collapse can cost you a haul; it can't cost you a page you've already read.
struct LibraryState: Codable, Equatable, Sendable {
    /// Pages recovered, in the order found.
    var foundPages: [DiaryPageID] = []
    /// Anonymous notes recovered from worlds. These never affect diary completion or patience.
    var foundWritings: [FoundWritingRecord] = []
    /// Travellers found — you have written the world they were in and gone there.
    var foundTravellers: Set<TravellerID> = []
    /// Travellers you know to look for, whether or not you know where they are.
    var knownTravellers: Set<TravellerID> = []
    /// Singular authored workshop patterns learned from diary pages.
    var knownPatterns: Set<String> = []
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
        foundPages = try c.decodeIfPresent([DiaryPageID].self, forKey: .foundPages) ?? []
        foundWritings = try c.decodeIfPresent([FoundWritingRecord].self, forKey: .foundWritings) ?? []
        foundTravellers = try c.decodeIfPresent(Set<TravellerID>.self, forKey: .foundTravellers) ?? []
        knownTravellers = try c.decodeIfPresent(Set<TravellerID>.self, forKey: .knownTravellers) ?? []
        knownPatterns = try c.decodeIfPresent(Set<String>.self, forKey: .knownPatterns) ?? []
        travellerArrivalNearMisses = (try c.decodeIfPresent([TravellerID: Int].self,
            forKey: .travellerArrivalNearMisses) ?? [:]).mapValues { max(0, $0) }
        pagesWaiting = try c.decodeIfPresent([DiaryPageID: Int].self, forKey: .pagesWaiting) ?? [:]
        patiencePage = try c.decodeIfPresent(DiaryPageID.self, forKey: .patiencePage)
        visitedWorlds = try c.decodeIfPresent([VisitedWorld].self, forKey: .visitedWorlds) ?? []
    }

    func hasFound(_ page: DiaryPageID) -> Bool { foundPages.contains(page) }

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

struct FoundWritingRecord: Codable, Equatable, Identifiable, Sendable {
    enum Family: String, Codable, CaseIterable, Sendable {
        case fieldNote, routeMark, siteFragment, workingScrap
    }
    var id: FoundWritingID
    var family: Family
    var prose: String
    var position: GridPoint
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
         worldVisualReceipt: WorldVisualReceipt? = nil) {
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
    }

    /// Includes the retired `inertRungs`, so a history written before the rename still reads.
    private enum CodingKeys: String, CodingKey {
        case id, seed, runIndex, descriptionSentence, written, semanticRequests, bindEssencePaid, inertModifiers, readings
        case travellersPresent, isKept, focusAttributions, focusEffects, livingAnalysis, clockAnalysis
        case worldVisualReceipt
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
