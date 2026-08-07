import Foundation

/// A discrete, placed thing with contents and an interaction — as opposed to a *pressure*, which is
/// a continuous condition that merely biases what spawns (`docs/sites-system.md` §1).
///
/// Sites are the mechanism that lets authored content appear in a procedural world without breaking
/// either half: a diary page isn't a random drop, it's in a ruin, in a world whose conditions the
/// player wrote. Which is why the conditions are **ranges rather than exact matches** — a whole
/// family of worlds can produce a given site, so sites are hunted by understanding conditions
/// rather than by memorising a recipe.
///
/// Rarity is emergent, not tagged: a site needing three simultaneous uncommon conditions is rare
/// because that world is *hard to write*, which is the same rule that governs named places.
struct SiteDef: Codable, Equatable, Identifiable, Sendable {
    var id: SiteID
    var name: String
    var icon: String
    var blurb: String
    var category: SiteCategory
    /// Every one of these must hold for the site to be eligible at all.
    var conditions: [PressureCondition]
    /// How many **named** contradictions the page must contain before this site can appear.
    ///
    /// Hazard sites are *produced by* contradiction rather than contributing to it, which gives
    /// contradiction a walkable consequence instead of only a number. It counts catalogue entries,
    /// never opposed magnitude: a sunny snowy world is honest worldbuilding and must never tear
    /// (`contradiction-danger-spec.md` §1).
    var minimumNamedContradictions: Int?
    /// Relative likelihood once the conditions hold.
    var weight: Double
    /// Most sites are unique; a few (hazards especially) come in numbers.
    var maximumPerWorld: Int
    /// Sites that cannot co-occur with this one. Checked both ways, so the relation only needs
    /// stating once.
    var excludes: [SiteID]
    var placement: SitePlacement
    /// What's inside, and what it takes to get it.
    var contents: SiteContents
    /// Some sites are dangerous to have written. Same units as the Stability headline.
    var stabilityDelta: Int

    /// Whether this site's conditions all hold in a given world.
    ///
    /// `contradictions` are the *named* ones the page fired — see `minimumNamedContradictions`.
    func isEligible(in readings: PressureReadings, contradictions: [ContradictionDef] = []) -> Bool {
        if let minimumNamedContradictions, contradictions.count < minimumNamedContradictions {
            return false
        }
        return conditions.allSatisfy { $0.holds(in: readings) }
    }
}

enum SiteCategory: String, Codable, CaseIterable, Sendable {
    /// From the shattering. The primary clue vector.
    case recentRuin
    /// From the people who came before, who anchored worlds and practiced the Art. Where rune
    /// knowledge lives — so it isn't a shop.
    case oldRuin
    /// Condition-triggered formations worth *visiting* rather than merely harvesting. Where
    /// concentrated value lives, and where the dispersion axis pays off.
    case landmark
    /// Hives, warrens, colonies. Placed like a site, populated by the creature system.
    case living
    /// Rifts and unstable ground — the places a contradictory world tears. These are *produced by*
    /// contradiction rather than contributing to it, which gives contradiction a walkable
    /// consequence instead of only a number.
    case hazard

    var displayName: String {
        switch self {
        case .recentRuin: "Recent ruin"
        case .oldRuin: "Old ruin"
        case .landmark: "Landmark"
        case .living: "Living site"
        case .hazard: "Hazard"
        }
    }
}

/// One threshold a world must clear.
///
/// Deliberately a *range* test rather than an exact match — see the note on `SiteDef`. Shared with
/// the contradiction catalogue, which asks the same kind of question of a world.
struct PressureCondition: Codable, Equatable, Sendable {
    var target: PressureTargetID
    /// Which number on the target this reads. Defaults to the headline magnitude.
    var measure: Measure
    /// For `.aspect`, `.form` and `.tag`, which one.
    var key: String?
    var minimum: Double?
    var maximum: Double?

    enum Measure: String, Codable, Sendable {
        case peak, floor, range, available, opposed, aspect, form, tag
    }

    func holds(in readings: PressureReadings) -> Bool {
        let reading = readings[target]
        let value: Double
        switch measure {
        case .peak: value = reading.peak
        case .floor: value = reading.floor
        case .range: value = reading.range
        case .available: value = reading.availableMagnitude
        case .opposed: value = reading.opposedMagnitude
        case .aspect: value = reading.aspect(key ?? "")
        case .form: value = reading.share(of: key ?? "") * 100
        case .tag:
            // A tag is present or it isn't; `minimum` above zero means "must be present", and a
            // `maximum` of zero means "must be absent".
            let present = reading.has(key ?? "")
            if let minimum, minimum > 0 { return present }
            if let maximum, maximum <= 0 { return !present }
            return present
        }
        if let minimum, value < minimum { return false }
        if let maximum, value > maximum { return false }
        return true
    }

    /// Plain-language reading, for the preview and for debugging a site that won't appear.
    var displayText: String {
        let name = ContentCatalog.shared.pressureTarget(target)?.name ?? target.rawValue
        let subject = switch measure {
        case .peak: "\(name) peak"
        case .floor: "\(name) floor"
        case .range: "\(name) swing"
        case .available: "usable \(name)"
        case .opposed: "contradicted \(name)"
        case .aspect: "\(name) \(key ?? "")"
        case .form: "\(name) as \(key ?? "")"
        case .tag: "\(name) \(key ?? "")"
        }
        if measure == .tag {
            return (maximum ?? 1) <= 0 ? "no \(subject)" : subject
        }
        switch (minimum, maximum) {
        case let (min?, max?): return "\(subject) \(Int(min))–\(Int(max))"
        case let (min?, nil): return "\(subject) over \(Int(min))"
        case let (nil, max?): return "\(subject) under \(Int(max))"
        default: return subject
        }
    }
}

/// Where on the map a site may sit. Placement is part of what a site *is* — a wellspring at the
/// entrance and a wellspring across the map are different objects to the player.
struct SitePlacement: Codable, Equatable, Sendable {
    var rule: Rule
    /// Kept at least this far from where the player arrives, so a site is something you go and find.
    var minimumDistanceFromEntry: Int

    enum Rule: String, Codable, Sendable {
        case anywhere
        /// On the outermost ring. Also the first thing a crumbling world eats.
        case edge
        /// Away from the edges, so it survives a while.
        case interior
    }
}

/// What a site holds. All of it optional — a landmark may be pure scenery-with-yield, while an old
/// ruin may be nothing but knowledge.
struct SiteContents: Codable, Equatable, Sendable {
    /// Resources granted on first search, keyed by resource.
    var yields: [ResourceID: Int]
    /// Items placed inside.
    var items: [ItemID]
    /// Symbols the site can teach outright. This is where rune knowledge lives instead of a shop.
    var teaches: [SymbolID]
    /// **Focuses the site can teach** — the words themselves, as opposed to a compound of them.
    /// The vocabulary is a progression, and finding a word carved on a wall is the best of the
    /// three ways into it.
    var teachesFocuses: [PressureSourceID] = []
    /// Essence granted outright. `docs/sites-system.md` says "research points", but research
    /// costs *essence* in the shipped economy and inventing a parallel currency is a design call —
    /// so this grants essence and the question is logged. See questions-for-design Q17.
    var essence: Int
    /// How many turns searching it costs. Sites are worth walking to *and* worth standing still for.
    var searchTurns: Int
    /// A creature standing guard, if any. Placed by the site, statted by the creature system.
    var guardian: CreatureID?

    var isEmpty: Bool {
        yields.isEmpty && items.isEmpty && teaches.isEmpty && teachesFocuses.isEmpty && essence == 0
    }

    init(yields: [ResourceID: Int] = [:], items: [ItemID] = [], teaches: [SymbolID] = [],
         teachesFocuses: [PressureSourceID] = [], essence: Int = 0, searchTurns: Int = 1,
         guardian: CreatureID? = nil) {
        self.yields = yields
        self.items = items
        self.teaches = teaches
        self.teachesFocuses = teachesFocuses
        self.essence = essence
        self.searchTurns = searchTurns
        self.guardian = guardian
    }

    /// Tolerant, per the policy in `Migrations.swift`. **A property with a default is not optional
    /// to synthesised decoding** — adding `teachesFocuses` with `= []` and nothing else would have
    /// made every site in `sites.json` fail to decode, which is exactly how a defaulted field once
    /// took the entire content catalogue down.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        yields = try c.decodeIfPresent([ResourceID: Int].self, forKey: .yields) ?? [:]
        items = try c.decodeIfPresent([ItemID].self, forKey: .items) ?? []
        teaches = try c.decodeIfPresent([SymbolID].self, forKey: .teaches) ?? []
        teachesFocuses = try c.decodeIfPresent([PressureSourceID].self, forKey: .teachesFocuses) ?? []
        essence = try c.decodeIfPresent(Int.self, forKey: .essence) ?? 0
        searchTurns = try c.decodeIfPresent(Int.self, forKey: .searchTurns) ?? 1
        guardian = try c.decodeIfPresent(CreatureID.self, forKey: .guardian)
    }
}

/// A site actually placed in a world, with its own looted state.
///
/// Looted-ness lives on the instance rather than the definition because the Q12 named-places ruling
/// needs it there: in an anchored world a ruin you emptied stays empty, while ordinary resources
/// replenish.
struct PlacedSite: Codable, Equatable, Identifiable, Sendable {
    var id: InstanceID
    var siteID: SiteID
    var position: GridPoint
    var isLooted: Bool = false
    /// Turns of searching still owed before it opens.
    var searchTurnsRemaining: Int

    var definition: SiteDef? { ContentCatalog.shared.site(siteID) }
}
