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

struct Tile: Codable, Equatable, Sendable {
    var content: TileContent = .empty
    /// Fog of war. Revealed tiles stay revealed.
    var isRevealed: Bool = false
    /// Crumbled tiles are impassable, and anything unharvested on them is gone.
    var isCrumbled: Bool = false

    var isPassable: Bool { !isCrumbled }
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

    var isPortal: Bool { if case .portal = self { true } else { false } }

    /// Whether losing this tile to crumbling costs the player something.
    var isLoseable: Bool {
        switch self {
        case .node, .wildDrop, .lockedCache, .site: true
        case .empty, .hazard, .portal: false
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
struct WorldEnemy: Codable, Equatable, Identifiable, Sendable {
    var id: InstanceID
    var creatureID: CreatureID
    var position: GridPoint
    /// Woken by the player entering its aggro radius. Never goes back to sleep.
    var isAwake: Bool = false
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
