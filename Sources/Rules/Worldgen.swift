import Foundation

/// Turns (book, seed) into a tile grid.
///
/// Every roll comes off a stream derived from the world's seed with a fixed salt per pass, so
/// generation is reproducible and — importantly — *stable under change*: adding a new pass later
/// doesn't shift the terrain an existing seed produces, because each pass has its own stream.
///
/// The run's live `rng` is deliberately untouched here. Worldgen must not consume from the stream
/// that in-run rolls draw from, or a resume would need to know how much generation had eaten.
enum Worldgen {

    private enum Salt {
        static let layout: UInt64 = 0x1A70
        static let nodes: UInt64 = 0x2D0DE
        static let enemies: UInt64 = 0x3F0E
        static let features: UInt64 = 0x4CAC
        static let sites: UInt64 = 0x5175
    }

    static func generate(book: BoundBook, seed: UInt64)
        -> (map: WorldMap, enemies: [WorldEnemy], sites: [PlacedSite], start: GridPoint) {
        let width = Tuning.World.gridWidth
        let height = Tuning.World.gridHeight
        var map = WorldMap(
            width: width,
            height: height,
            tiles: Array(repeating: Tile(), count: width * height),
            entry: GridPoint(x: 0, y: 0)
        )

        let root = SeededRNG(seed: seed)
        var layoutRNG = root.derived(Salt.layout)
        var nodeRNG = root.derived(Salt.nodes)
        var enemyRNG = root.derived(Salt.enemies)
        var featureRNG = root.derived(Salt.features)
        var siteRNG = root.derived(Salt.sites)

        // 1. Where you arrive: a portal on the edge. It works as an exit too, so retreating the
        //    way you came is always possible — it just costs you the turns to walk back.
        //    (Whether that's too forgiving is Q6 in questions-for-aimee.md.)
        let entry = randomEdgePoint(in: map, rng: &layoutRNG)
        map.entry = entry
        map[entry].content = .portal(isEntry: true)

        // 2. At least one more portal, placed away from the entry so it's worth finding.
        var occupied: Set<GridPoint> = [entry]
        let exitCount = layoutRNG.int(in: Tuning.World.exitPortalCountRange)
        for _ in 0..<exitCount {
            guard let point = randomFreePoint(in: map, avoiding: occupied, minimumDistanceFrom: entry,
                                              distance: Tuning.World.minimumExitPortalDistance, rng: &layoutRNG)
            else { continue }
            map[point].content = .portal(isEntry: false)
            occupied.insert(point)
        }

        // 3. Resource nodes. Count and richness both come from the book — a bounty-heavy book is
        //    visibly denser on the grid, not just better per pull.
        let yieldTable = BookRules.yieldTable(for: book)
        let nodeCount = nodeCount(for: book, rng: &nodeRNG)
        for _ in 0..<nodeCount {
            guard let point = randomFreePoint(in: map, avoiding: occupied, rng: &nodeRNG),
                  let resource = nodeRNG.pickWeighted(yieldTable)
            else { continue }
            map[point].content = .node(ResourceNode(
                resource: resource,
                remainingHarvests: nodeRNG.int(in: Tuning.World.harvestTurnsRange),
                yieldPerHarvest: nodeRNG.int(in: Tuning.World.nodeYieldRange)
            ))
            occupied.insert(point)
        }

        // 4. Wild drops — single pickups you get just by walking over them. Raw essence arrives
        //    this way (Aimee's stated design), so it's a reason to wander off your path.
        let wildCount = featureRNG.int(in: Tuning.World.wildDropCountRange)
        for _ in 0..<wildCount {
            guard let point = randomFreePoint(in: map, avoiding: occupied, rng: &featureRNG) else { continue }
            map[point].content = .wildDrop(resource: Resources.essenceRaw,
                                           amount: featureRNG.int(in: Tuning.World.wildDropAmountRange))
            occupied.insert(point)
        }

        // 5. A locked cache, sometimes. It can only be opened with a key found in a *different*
        //    world — the whole point is that you see it long before you can have it.
        if featureRNG.chance(Tuning.World.lockedCacheChance),
           let point = randomFreePoint(in: map, avoiding: occupied, rng: &featureRNG) {
            map[point].content = .lockedCache
            occupied.insert(point)
        }

        // 6. Sites — the discrete placed things. Eligibility is read off the world's *pressures*
        //    rather than off its symbols, so a site is found by writing a kind of place rather than
        //    by writing a specific recipe (docs/sites-system.md §2).
        let sigils = BookRules.sigils(for: book)
        let readings = BookRules.readings(for: book, seed: seed)
        let sites = SiteRules.place(in: map,
                                    readings: readings,
                                    contradictions: ContradictionRules.fired(in: sigils, readings: readings),
                                    avoiding: occupied, rng: &siteRNG)
        var guardians: [WorldEnemy] = []
        for site in sites {
            map[site.position].content = .site(site.id)
            occupied.insert(site.position)
            // A guarded site is placed by the site system and statted by the creature system. The
            // guardian stands *on* the site, so the fight is the price of the search rather than a
            // separate mechanic.
            if let creature = site.definition?.contents.guardian {
                guardians.append(WorldEnemy(id: InstanceID(rawValue: siteRNG.next()),
                                            creatureID: creature, position: site.position))
            }
        }

        // 7. Enemies, drawn from the book's enemy table.
        let enemyTable = BookRules.enemyTable(for: book)
        let enemyCount = enemyCount(for: book, rng: &enemyRNG)
        var enemies: [WorldEnemy] = guardians
        for _ in 0..<enemyCount {
            guard let creature = enemyRNG.pickWeighted(enemyTable),
                  let point = randomFreePoint(in: map, avoiding: occupied,
                                              minimumDistanceFrom: entry,
                                              distance: Tuning.World.enemyFreeRadiusAroundEntry,
                                              rng: &enemyRNG)
            else { continue }
            enemies.append(WorldEnemy(id: InstanceID(rawValue: enemyRNG.next()),
                                      creatureID: creature.id,
                                      position: point))
            occupied.insert(point)
        }

        WorldRules.reveal(around: entry, in: &map, radius: WorldRules.visionRadius(for: book))
        return (map, enemies, sites, entry)
    }

    // MARK: Counts

    /// Richer books put more nodes on the ground. Scales off the book's yield multipliers so a new
    /// bounty symbol automatically affects density without touching this function.
    static func nodeCount(for book: BoundBook, rng: inout SeededRNG) -> Int {
        let generosity = book.allSymbolIDs.reduce(1.0) { total, id in
            guard let symbol = ContentCatalog.shared.symbol(id), !symbol.yieldModifiers.isEmpty else { return total }
            let average = symbol.yieldModifiers.values.reduce(0, +) / Double(symbol.yieldModifiers.count)
            return total * average
        }
        let base = Double(rng.int(in: Tuning.World.baseNodeCountRange))
        return max(1, Int((base * generosity).rounded()))
    }

    /// More dangerous books put more enemies on the ground, on top of the nastier spawn table.
    static func enemyCount(for book: BoundBook, rng: inout SeededRNG) -> Int {
        let tier = BookRules.enemyTier(of: book)
        let base = rng.int(in: Tuning.World.baseEnemyCountRange)
        return max(1, base + (tier - Tuning.World.baseEnemyTier) * Tuning.World.enemiesPerDangerTier)
    }

    // MARK: Placement

    private static func randomEdgePoint(in map: WorldMap, rng: inout SeededRNG) -> GridPoint {
        let edges = map.allPoints.filter { map.ring(of: $0) == 0 }
        return rng.pick(edges) ?? GridPoint(x: 0, y: 0)
    }

    /// A point with nothing on it yet, optionally kept clear of somewhere.
    private static func randomFreePoint(in map: WorldMap,
                                        avoiding occupied: Set<GridPoint>,
                                        minimumDistanceFrom origin: GridPoint? = nil,
                                        distance: Int = 0,
                                        rng: inout SeededRNG) -> GridPoint? {
        var candidates = map.allPoints.filter { point in
            !occupied.contains(point) && map[point].content == .empty
        }
        if let origin, distance > 0 {
            let far = candidates.filter { $0.chebyshevDistance(to: origin) >= distance }
            // Fall back to the unfiltered set rather than placing nothing at all — on a small or
            // crowded map the distance constraint can be unsatisfiable.
            if !far.isEmpty { candidates = far }
        }
        return rng.pick(candidates)
    }
}
