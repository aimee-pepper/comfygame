import Foundation

/// Someone scattered by the sundering, and where they ended up.
///
/// **A traveller is not "N worlds away" — a traveller is at a condition signature**
/// (decisions-session-7). What varies between an early traveller and a late one is not distance
/// but how hard their signature is to *write*: "any sunny world" is one condition a starting
/// vocabulary can manage; a late traveller needs rare runes and page space you don't have yet.
///
/// So search difficulty scales off the writing system, and finding someone is always the same act —
/// write the world they are in.
struct TravellerDef: Codable, Equatable, Identifiable, Sendable {
    var id: TravellerID
    var name: String
    /// Who they were. Leans what their diary tends to contain.
    var calling: String
    var blurb: String
    var icon: String
    /// Where they are. **Every condition must hold** for the world to be the one they're in.
    ///
    /// Complexity *is* difficulty: one condition means one page says it all, six means assembling
    /// the description across six.
    var signature: [SignatureClue]

    /// Pages of their diary lean toward what they knew — an archaeologist's toward ruins and
    /// research leads, a wanderer's toward places and people. A soft preference, so chasing a
    /// particular person's diary can be motivated by what they knew.
    var leansToward: [DiaryPageDef.Kind]

    var complexity: Int { signature.count }

    /// Whether a world is the one this traveller is in.
    func isFound(in readings: PressureReadings) -> Bool {
        !signature.isEmpty && signature.allSatisfy { $0.condition.holds(in: readings) }
    }
}

/// One piece of a traveller's location, and the sentence their diary describes it with.
///
/// The passage is what the player actually reads and matches against a world description. It is
/// deliberately prose and never a condition: *"no shadow anywhere"*, not *"illumination floor > 60"*.
struct SignatureClue: Codable, Equatable, Sendable {
    var condition: PressureCondition
    /// The traveller's own words. Shown verbatim on the hint page.
    var passage: String
}

/// A page torn out of somebody's diary.
///
/// **Everything found is somebody's diary** — there is no separate class of scholar's notes or
/// workshop records. That's what makes finishing the diary of a person you already found coherent:
/// you have them, and their diary is still scattered and still paying into four other systems.
///
/// **One page, one unlock.** Never two.
struct DiaryPageDef: Codable, Equatable, Identifiable, Sendable {
    var id: DiaryPageID
    /// Whose diary this is torn from.
    var diary: TravellerID
    var kind: Kind
    /// The prose on the page. Always a person writing, never a system explaining.
    var prose: String

    /// `locationClue`: whose location, and which piece of it.
    var about: TravellerID?
    var clueIndex: Int?
    /// `symbol`: taught outright.
    var teaches: SymbolID?
    /// `researchLead`: partial progress toward a node, never the finished thing.
    var researchNode: ResearchNodeID?
    /// `ruin`: a site whose existence this page reveals.
    var site: SiteID?

    /// A page prefers to surface in a world its author would have had reason to be in. Soft — the
    /// placement rules fall back to anywhere rather than let anything become unreachable.
    var prefersConditions: [PressureCondition]

    enum Kind: String, Codable, CaseIterable, Sendable {
        /// A piece of a traveller's location description.
        case locationClue
        /// That another traveller exists at all, and is worth looking for.
        case whereabouts
        /// A specific world worth writing.
        case worldWorthWriting
        /// A ruin's existence.
        case ruin
        /// A symbol, taught outright.
        case symbol
        /// A head start on a research node — partial progress, not the finished thing.
        case researchLead

        var displayName: String {
            switch self {
            case .locationClue: "Where someone is"
            case .whereabouts: "Word of someone"
            case .worldWorthWriting: "A world worth writing"
            case .ruin: "Somewhere built"
            case .symbol: "A rune"
            case .researchLead: "A line of study"
            }
        }
    }
}
