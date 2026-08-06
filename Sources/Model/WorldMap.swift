import Foundation

/// The tile grid of an authored world.
///
/// Stored in the save rather than regenerated on load. Regenerating from (book, seed) would give
/// the same *terrain*, but the map is mutable — tiles get revealed, harvested, crumbled — and
/// replaying every mutation to rebuild it would be a second source of truth waiting to disagree
/// with the first. The seed stays on the run for reproduction and debugging.
struct WorldMap: Codable, Equatable, Sendable {
    var width: Int
    var height: Int
    /// Row-major, `width * height` entries.
    var tiles: [Tile]
    /// Where the player arrived. Always on an edge.
    var entry: GridPoint

    subscript(point: GridPoint) -> Tile {
        get { tiles[index(of: point)] }
        set { tiles[index(of: point)] = newValue }
    }

    func index(of point: GridPoint) -> Int { point.y * width + point.x }

    func contains(_ point: GridPoint) -> Bool {
        point.x >= 0 && point.y >= 0 && point.x < width && point.y < height
    }

    var allPoints: [GridPoint] {
        (0..<height).flatMap { y in (0..<width).map { GridPoint(x: $0, y: y) } }
    }

    /// Four-way adjacency. Movement is orthogonal — no diagonal shortcuts.
    func neighbours(of point: GridPoint) -> [GridPoint] {
        [GridPoint(x: point.x, y: point.y - 1),
         GridPoint(x: point.x + 1, y: point.y),
         GridPoint(x: point.x, y: point.y + 1),
         GridPoint(x: point.x - 1, y: point.y)]
            .filter(contains)
    }

    /// How many rings in from the edge a tile sits. 0 = outermost. Drives inward crumbling.
    func ring(of point: GridPoint) -> Int {
        min(point.x, point.y, width - 1 - point.x, height - 1 - point.y)
    }

    var revealedCount: Int { tiles.count { $0.isRevealed } }
}

/// What the ground under everything is made of.
///
/// Orthogonal to `content`: a resource node sits *on* stone or *in* growth. Deliberately a small
/// set (`generation-spine-spec.md` §2) — enough for the eight targets to write something legible
/// into, not a materials system.
enum GroundType: String, Codable, CaseIterable, Sendable {
    case stone, soil, sand, ice, ash, water, deepWater, rubble, growth, void

    /// Deep water and the void are the only things you can't walk over.
    var isPassable: Bool { self != .deepWater && self != .void }

    /// Growth and broken ground break sightlines. This is what makes ambush terrain real rather
    /// than a word in a description.
    var blocksSight: Bool { self == .growth || self == .rubble }

    var displayName: String {
        switch self {
        case .deepWater: "deep water"
        default: rawValue
        }
    }
}

struct Tile: Codable, Equatable, Sendable {
    var content: TileContent = .empty
    /// What this square is made of.
    var ground: GroundType = .soil
    /// 0–3. Cover and sightlines — high ground sees over low, and broken country hides things.
    var elevation: Int = 0
    /// Fog of war. Revealed tiles stay revealed.
    var isRevealed: Bool = false
    /// Crumbled tiles are impassable, and anything unharvested on them is gone.
    var isCrumbled: Bool = false

    init(content: TileContent = .empty, ground: GroundType = .soil, elevation: Int = 0,
         isRevealed: Bool = false, isCrumbled: Bool = false) {
        self.content = content
        self.ground = ground
        self.elevation = elevation
        self.isRevealed = isRevealed
        self.isCrumbled = isCrumbled
    }

    /// Tolerant: a tile is in every save with a run in it, so adding a field here must not cost
    /// somebody the world they were standing in.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        content = try c.decodeIfPresent(TileContent.self, forKey: .content) ?? .empty
        ground = try c.decodeIfPresent(GroundType.self, forKey: .ground) ?? .soil
        elevation = try c.decodeIfPresent(Int.self, forKey: .elevation) ?? 0
        isRevealed = try c.decodeIfPresent(Bool.self, forKey: .isRevealed) ?? false
        isCrumbled = try c.decodeIfPresent(Bool.self, forKey: .isCrumbled) ?? false
    }

    var isPassable: Bool { !isCrumbled && ground.isPassable }

    /// Whether something standing here can be seen past. Elevation counts: a hill blocks as surely
    /// as a thicket.
    func blocksSight(from elevation: Int) -> Bool {
        ground.blocksSight || self.elevation > elevation
    }
}

enum TileContent: Codable, Equatable, Sendable {
    case empty
    /// A resource node. Harvesting takes a turn per pull.
    case node(ResourceNode)
    /// A single wild drop — picked up just by walking over it. Essence-raw arrives this way.
    case wildDrop(resource: ResourceID, amount: Int)
    /// Spawned at the map edges once stability falls past the hazard threshold.
    case hazard
    /// `isEntry` marks the one you arrived through.
    case portal(isEntry: Bool)
    /// Opens only with a key found in a *different* world. The delayed-payoff seed.
    case lockedCache
    /// A placed site — a ruin, a landmark, a warren. The world's discrete contents, as opposed to
    /// its conditions. Contents live on the `PlacedSite` in the run, keyed by this id.
    case site(InstanceID)
    /// A page torn from someone's diary, lying where it fell.
    case diaryPage(DiaryPageID)
    /// **Somebody, standing there.** Reaching them opens the meeting; recruiting them is what
    /// actually finds them (Aimee, 6 Aug).
    case traveller(TravellerID)

    var isPortal: Bool { if case .portal = self { true } else { false } }

    /// Whether losing this tile to crumbling costs the player something.
    var isLoseable: Bool {
        switch self {
        case .node, .wildDrop, .lockedCache, .site, .diaryPage: true
        // A person is not loot, and losing them to the floor is the point of the timer rather
        // than a cost to be tallied.
        case .empty, .hazard, .portal, .traveller: false
        }
    }
}

/// A harvestable node. Yield and pull count are rolled at worldgen from the book's bounty symbols.
struct ResourceNode: Codable, Equatable, Sendable {
    var resource: ResourceID
    var remainingHarvests: Int
    var yieldPerHarvest: Int

    var isExhausted: Bool { remainingHarvests <= 0 }
}

/// An enemy standing on the grid. Inert until the player comes close, then it walks at you.
///
/// **Carries its own trait vector, not a pointer into a catalogue.** One of the run's cast, plus the
/// jitter that makes this particular animal itself — rolled once at placement and kept, so a resume
/// finds the same creature even if the sampling rules change underneath it.
struct WorldEnemy: Codable, Equatable, Identifiable, Sendable {
    var id: InstanceID
    /// Which of the run's cast this is one of.
    var speciesID: InstanceID?
    /// This animal. `nil` only in worlds bound before the cast existed.
    var traits: CreatureTraits?
    /// An authored creature. **Legacy** — kept so a run in progress when the cast landed still
    /// resolves rather than emptying its map of everything the player was walking toward.
    var creatureID: CreatureID?
    var position: GridPoint
    /// Woken by the player entering its aggro radius. Never goes back to sleep.
    var isAwake: Bool = false

    init(id: InstanceID, speciesID: InstanceID? = nil, traits: CreatureTraits? = nil,
         creatureID: CreatureID? = nil, position: GridPoint, isAwake: Bool = false) {
        self.id = id
        self.speciesID = speciesID
        self.traits = traits
        self.creatureID = creatureID
        self.position = position
        self.isAwake = isAwake
    }

    /// Tolerant decoding, per the policy in `Migrations.swift`.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(InstanceID.self, forKey: .id)
        speciesID = try c.decodeIfPresent(InstanceID.self, forKey: .speciesID)
        traits = try c.decodeIfPresent(CreatureTraits.self, forKey: .traits)
        creatureID = try c.decodeIfPresent(CreatureID.self, forKey: .creatureID)
        position = try c.decode(GridPoint.self, forKey: .position)
        isAwake = try c.decodeIfPresent(Bool.self, forKey: .isAwake) ?? false
    }

    // MARK: What it is

    /// What to call it. Read off the traits where there are any, off the old catalogue otherwise.
    ///
    /// Pass the run's cast where you have it: a name says what sets this one apart **from its own
    /// world**, so "armoured" is only worth saying where not everything is.
    func displayName(in context: Naming.Context = .none) -> String {
        if let traits { return CreatureIdentity.name(for: traits, in: context) }
        return creatureID.flatMap { ContentCatalog.shared.creature($0)?.name } ?? "Something"
    }

    var displayName: String { displayName() }

    /// The bestiary key. Species are entries; this enemy is a specimen under one.
    var identityKey: String {
        if let traits { return CreatureIdentity.match(traits).key }
        return creatureID?.rawValue ?? "unknown"
    }

    /// **[PLACEHOLDER]** — session 11 §4 wants glyphs rather than app icons, and that applies here
    /// as much as to the runes. Until then, how it gets about is the most legible thing about it.
    var icon: String {
        guard let traits else {
            return creatureID.flatMap { ContentCatalog.shared.creature($0)?.icon } ?? "questionmark"
        }
        if traits.emanation != nil { return "light.beacon.max" }
        switch traits.appendages.type {
        case .finned: return "fish"
        case .membrane, .feathered: return "bird"
        case .none: return "circle.hexagongrid"
        case .limbed:
            if traits.appendages.count >= 6 { return "ant" }
            if traits.covering.armourValue > 55 { return "tortoise" }
            if traits.build > 70 { return "pawprint" }
            return "lizard"
        }
    }
}

extension GridPoint {
    /// Chebyshev distance — "within N tiles" including diagonals, for sight and aggro radius.
    func chebyshevDistance(to other: GridPoint) -> Int {
        max(abs(x - other.x), abs(y - other.y))
    }

    func manhattanDistance(to other: GridPoint) -> Int {
        abs(x - other.x) + abs(y - other.y)
    }

    var isOrigin: Bool { x == 0 && y == 0 }
}
