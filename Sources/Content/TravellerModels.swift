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
    enum CampaignPhase: String, Codable, CaseIterable, Sendable {
        case opening
        case earlyMid = "early-mid"
        case startOfMid
        case mid
        case midLate = "mid-late"
        case late
        case endgame

        var displayName: String {
            switch self {
            case .opening: "Opening"
            case .earlyMid: "Early–mid"
            case .startOfMid: "Start of midgame"
            case .mid: "Midgame"
            case .midLate: "Mid–late"
            case .late: "Late"
            case .endgame: "Endgame"
            }
        }
    }

    var id: TravellerID
    var name: String
    /// Who they were. Leans what their diary tends to contain.
    var calling: String
    var blurb: String
    var icon: String
    /// Stable campaign sequencing. JSON array order is an authoring convenience, never progression.
    var authoredOrder: Int?
    var campaignPhase: CampaignPhase?
    /// Hidden immutable story cluster used only after a complete signature match.
    var storyArrivalBand: Int?
    /// Visible fit for maintaining an anchored realm, 0–3. Everyone may still do the work.
    var worldwork: Int = 1
    /// Where they are. **Every condition must hold** for the world to be the one they're in.
    ///
    /// Complexity *is* difficulty: one condition means one page says it all, six means assembling
    /// the description across six.
    var signature: [SignatureClue]

    /// Pages of their diary lean toward what they knew — an archaeologist's toward ruins and
    /// research leads, a wanderer's toward places and people. A soft preference, so chasing a
    /// particular person's diary can be motivated by what they knew.
    var leansToward: [DiaryPageDef.Kind]

    /// Stable authored bonus practice owned on recruitment. It never consumes standard points.
    var combatGraphVersion: Int
    var combatNodePlan: [CombatNodeID]

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
        authoredOrder = try c.decodeIfPresent(Int.self, forKey: .authoredOrder)
        campaignPhase = try c.decodeIfPresent(CampaignPhase.self, forKey: .campaignPhase)
        storyArrivalBand = try c.decodeIfPresent(Int.self, forKey: .storyArrivalBand)
        worldwork = min(3, max(0, try c.decodeIfPresent(Int.self, forKey: .worldwork) ?? 1))
        signature = try c.decodeIfPresent([SignatureClue].self, forKey: .signature) ?? []
        leansToward = try c.decodeIfPresent([DiaryPageDef.Kind].self, forKey: .leansToward) ?? []
        combatGraphVersion = try c.decode(Int.self, forKey: .combatGraphVersion)
        combatNodePlan = try c.decode([CombatNodeID].self, forKey: .combatNodePlan)
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
        var id: String
        var ask: String
        var reply: String

        init(id: String, ask: String, reply: String) {
            self.id = id; self.ask = ask; self.reply = reply
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            ask = try c.decode(String.self, forKey: .ask)
            reply = try c.decode(String.self, forKey: .reply)
            // Tolerates old external fixtures. Bundled content validation requires explicit IDs.
            id = try c.decodeIfPresent(String.self, forKey: .id) ?? "legacy.\(ask)"
        }
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
    /// `focus`: a word for the pressure grammar, taught outright.
    var teachesFocus: PressureSourceID?
    /// `gambit`: one phrase in the combat rule grammar, taught outright.
    var teachesGambit: GambitComponentID?
    /// A complete, singular authored workshop pattern. This is not research progress.
    var teachesPattern: WorkshopPatternID?
    /// A durable authored construction method. Learning it grants knowledge, never its output.
    var teachesSchematic: SchematicID?
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
        /// A personal account with no mechanical unlock.
        case account
        /// An authored change of mind or interpretive turn, with no mechanical unlock.
        case turn
        /// A ruin's existence.
        case ruin
        /// A symbol, taught outright.
        case symbol
        /// A focus, taught outright.
        case focus
        /// A gambit phrase, taught outright.
        case gambit
        /// A singular authored workshop pattern, taught outright.
        case pattern
        /// A singular authored construction method, taught outright.
        case schematic
        /// A head start on a research node — partial progress, not the finished thing.
        case researchLead

        var displayName: String {
            switch self {
            case .locationClue: "Where someone is"
            case .whereabouts: "Word of someone"
            case .worldWorthWriting: "A world worth writing"
            case .account: "An account"
            case .turn: "A turn"
            case .ruin: "Somewhere built"
            case .symbol: "A Sigil"
            case .focus: "A focus"
            case .gambit: "A gambit phrase"
            case .pattern, .schematic: "A Schematic"
            case .researchLead: "A line of study"
            }
        }
    }
}

/// Central identity authority for authored workshop patterns. A diary page names an ID; this
/// registry decides whether that ID is a real, independently consumable workshop method.
enum WorkshopPatternRegistry {
    struct Definition: Equatable, Sendable {
        var id: WorkshopPatternID
        var name: String
    }

    static let definitions: [Definition] = [
        Definition(id: "maud_fitting_pattern", name: "Fitted Polearm Schematic")
    ]

    static func definition(_ id: WorkshopPatternID) -> Definition? {
        definitions.first { $0.id == id }
    }

    static func displayName(_ id: WorkshopPatternID) -> String? {
        definition(id)?.name
    }

    static func validate(_ definitions: [Definition]) throws {
        var seen: Set<WorkshopPatternID> = []
        for definition in definitions {
            guard !definition.id.rawValue.isEmpty, !definition.name.isEmpty else {
                throw ContentCatalog.ContentError.danglingReference("unnamed workshop pattern")
            }
            guard seen.insert(definition.id).inserted else {
                throw ContentCatalog.ContentError.duplicateID(
                    "workshop pattern '\(definition.id.rawValue)'")
            }
        }
    }
}

/// Central identity authority for construction knowledge learned from authored writing.
enum SchematicRegistry {
    struct Definition: Equatable, Sendable {
        var id: SchematicID
        var name: String
    }

    static let definitions: [Definition] = [
        Definition(id: "pointed_blade", name: "Pointed Blade"),
        Definition(id: "emanation_housing", name: "Emanation housing")
    ]

    static func definition(_ id: SchematicID) -> Definition? {
        definitions.first { $0.id == id }
    }

    static func validate(_ definitions: [Definition]) throws {
        var seen: Set<SchematicID> = []
        for definition in definitions {
            guard !definition.id.rawValue.isEmpty, !definition.name.isEmpty else {
                throw ContentCatalog.ContentError.danglingReference("unnamed schematic")
            }
            guard seen.insert(definition.id).inserted else {
                throw ContentCatalog.ContentError.duplicateID(
                    "schematic '\(definition.id.rawValue)'")
            }
        }
    }
}

enum SchematicPresentation {
    static func learnedEvent(pattern id: WorkshopPatternID) -> String {
        WorkshopPatternRegistry.displayName(id)
            .map { "A Schematic you didn't have: \($0)." }
            ?? "A Schematic you didn't have."
    }

    static func learnedEvent(schematic id: SchematicID) -> String {
        SchematicRegistry.definition(id)
            .map { "A Schematic you didn't have: \($0.name)." }
            ?? "A Schematic you didn't have."
    }
}
