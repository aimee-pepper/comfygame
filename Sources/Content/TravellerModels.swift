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

    /// **Where their trade already took them**, as free points in combat branches.
    ///
    /// *"A calling gives a starting lean, never a limit"* (`combat-trees-full.md` §6). Halloway the
    /// smith begins in Force because she has swung a hammer for a living; nothing stops you making
    /// her a knife-fighter, and a respec can move even this.
    ///
    /// **Free, not deducted.** A lean is who somebody was before you met them, not what they have
    /// learned since — charging it against the level budget would make an experienced tradesperson
    /// arrive *behind* a stranger, which is backwards.
    var lean: [CombatBranchID: Int] = [:]

    /// **What they say when you walk up to them** (Aimee, 6 Aug).
    ///
    /// Finding somebody used to be a write to the save the instant you arrived in a world matching
    /// their signature — so a forge appeared at the base for a smith the player had never laid eyes
    /// on. *"Finding a traveller should mean actually running across the person as an entity on a
    /// world you find them in"*, and *"there should be a text interaction where you recruit them."*
    ///
    /// So they stand on the map, and this is the scene. Nil for anyone not yet written, who then
    /// joins on a plain acknowledgement rather than in silence.
    var meeting: TravellerMeeting?

    /// **The game does not continue without them.**
    ///
    /// True only for Isolde today (`hands-and-calligrapher-spec.md` §3). A required character is
    /// the one thing that can wedge a save, so `LibraryTests` asserts a much stronger invariant
    /// about them than about anybody else: **every condition must be satisfiable with the symbols
    /// a player starts with**, not merely writable on the page they start with.
    ///
    /// That distinction is the whole bug. Her signature asked for thin air; nothing in the starting
    /// twelve can lower atmosphere below its baseline of 50, so the only route was to leave it
    /// unwritten and hope — a coin flip, not a deduction. And the clue pointed straight at it.
    var isRequired: Bool = false

    var complexity: Int { signature.count }

    /// Whether a world is the one this traveller is in.
    func isFound(in readings: PressureReadings) -> Bool {
        !signature.isEmpty && signature.allSatisfy { $0.condition.holds(in: readings) }
    }

    /// Tolerant, per the policy in `Migrations.swift` — a travellers file written before anybody
    /// could be spoken to still loads.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(TravellerID.self, forKey: .id)
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? id.rawValue
        calling = try c.decodeIfPresent(String.self, forKey: .calling) ?? ""
        blurb = try c.decodeIfPresent(String.self, forKey: .blurb) ?? ""
        icon = try c.decodeIfPresent(String.self, forKey: .icon) ?? "figure.stand"
        signature = try c.decodeIfPresent([SignatureClue].self, forKey: .signature) ?? []
        leansToward = try c.decodeIfPresent([DiaryPageDef.Kind].self, forKey: .leansToward) ?? []
        lean = try c.decodeIfPresent([CombatBranchID: Int].self, forKey: .lean) ?? [:]
        meeting = try c.decodeIfPresent(TravellerMeeting.self, forKey: .meeting)
        isRequired = try c.decodeIfPresent(Bool.self, forKey: .isRequired) ?? false
    }
}

/// The scene when you reach somebody.
///
/// Deliberately small: **an opening, some things you can ask, and a decision.** Nobody is a quest
/// chain. What makes the moment worth having is that you wrote the world they were standing in.
///
/// Everything is prose written by a person, never a system explaining itself — the same rule the
/// diary pages follow.
struct TravellerMeeting: Codable, Equatable, Sendable {
    /// The first thing they say. What you read on walking up.
    var opening: String
    /// Things you can ask before deciding. Asking costs nothing and never runs out — the world
    /// crumbling is the only clock, and it's the same clock as everything else.
    var questions: [Exchange]
    /// What you offer. One line, in your voice.
    var offer: String
    /// What they say on agreeing.
    var accepted: String
    /// What they say if you walk away. They stay where they are — the world will take them, which
    /// is the whole weight of the decision.
    var declined: String

    struct Exchange: Codable, Equatable, Sendable, Identifiable {
        var ask: String
        var reply: String
        var id: String { ask }
    }

    init(opening: String, questions: [Exchange] = [], offer: String,
         accepted: String, declined: String) {
        self.opening = opening
        self.questions = questions
        self.offer = offer
        self.accepted = accepted
        self.declined = declined
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        opening = try c.decodeIfPresent(String.self, forKey: .opening) ?? ""
        questions = try c.decodeIfPresent([Exchange].self, forKey: .questions) ?? []
        offer = try c.decodeIfPresent(String.self, forKey: .offer) ?? "Come back with me."
        accepted = try c.decodeIfPresent(String.self, forKey: .accepted) ?? "All right."
        declined = try c.decodeIfPresent(String.self, forKey: .declined) ?? "I'll be here."
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
