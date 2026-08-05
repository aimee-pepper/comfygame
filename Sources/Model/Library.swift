import Foundation

/// Everything the player has read, and everyone they've found.
///
/// Lives in the **Reality** layer: pages read and people found are knowledge, and knowledge is
/// never taken back. A collapse can cost you a haul; it can't cost you a page you've already read.
struct LibraryState: Codable, Equatable, Sendable {
    /// Pages recovered, in the order found.
    var foundPages: [DiaryPageID] = []
    /// Travellers found — you have written the world they were in and gone there.
    var foundTravellers: Set<TravellerID> = []
    /// Travellers you know to look for, whether or not you know where they are.
    var knownTravellers: Set<TravellerID> = []
    /// How many worlds have been generated since each page became eligible to appear.
    ///
    /// Pages prefer worlds relevant to their author, but nothing may be permanently unreachable
    /// because of how a player happens to write — so once this passes a threshold the page stops
    /// waiting and will surface anywhere.
    var pagesWaiting: [DiaryPageID: Int] = [:]

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        foundPages = try c.decodeIfPresent([DiaryPageID].self, forKey: .foundPages) ?? []
        foundTravellers = try c.decodeIfPresent(Set<TravellerID>.self, forKey: .foundTravellers) ?? []
        knownTravellers = try c.decodeIfPresent(Set<TravellerID>.self, forKey: .knownTravellers) ?? []
        pagesWaiting = try c.decodeIfPresent([DiaryPageID: Int].self, forKey: .pagesWaiting) ?? [:]
    }

    func hasFound(_ page: DiaryPageID) -> Bool { foundPages.contains(page) }

    /// The pieces of a traveller's location the player has actually read.
    func knownClueIndices(for traveller: TravellerID) -> Set<Int> {
        Set(foundPages
            .compactMap { ContentCatalog.shared.diaryPage($0) }
            .filter { $0.kind == .locationClue && $0.about == traveller }
            .compactMap(\.clueIndex))
    }
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
