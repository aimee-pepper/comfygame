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
        static let pages: UInt64 = 0x9A6E
    }

    static func generate(book: BoundBook, seed: UInt64, library: LibraryState = LibraryState())
        -> (map: WorldMap, enemies: [WorldEnemy], sites: [PlacedSite],
            pages: [DiaryPageID], travellers: [TravellerID], cast: [Species], start: GridPoint) {
        // **Size is written, not fixed** (session 13 §5). The book carries the Scale it was
        // written at, so the same book always makes the same size of world.
        let width = book.scale.gridSide
        let height = book.scale.gridSide
        var map = WorldMap(
            width: width,
            height: height,
            tiles: Array(repeating: Tile(), count: width * height),
            entry: GridPoint(x: 0, y: 0)
        )

        let root = SeededRNG(seed: seed)
        var terrainRNG = root.derived(0x7E44)
        var layoutRNG = root.derived(Salt.layout)
        var nodeRNG = root.derived(Salt.nodes)
        var enemyRNG = root.derived(Salt.enemies)
        var featureRNG = root.derived(Salt.features)
        var siteRNG = root.derived(Salt.sites)
        var pageRNG = root.derived(Salt.pages)

        // Everything below reads the world's *pressures*. What a world is made of and what lives
        // in it now come from the eight targets rather than from flat per-symbol tables.
        let sigils = BookRules.sigils(for: book)
        let readings = PressureRules.resolve(sigils, fillingUnwrittenWith: seed)

        // 0. The ground itself, before anything is placed on it. Relief, Substrate, Hydrology,
        //    Thermal and Vitality all write here — this is the surface the pressure model was
        //    missing, and without it Relief had nothing to say.
        TerrainRules.paint(&map, readings: readings, rng: &terrainRNG)

        // 1. Where you arrive: a portal on the edge. It works as an exit too, so retreating the
        //    way you came is always possible — it just costs you the turns to walk back.
        //    (Whether that's too forgiving is Q6 in questions-for-aimee.md.)
        let entry = TerrainRules.firmGround(near: randomEdgePoint(in: map, rng: &layoutRNG), in: map)
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
        let yieldTable = BookRules.yieldTable(from: readings)
        let nodeCount = nodeCount(for: readings, rng: &nodeRNG)
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

        // 6. Hazard tiles the *book* asked for, as opposed to the ones a collapsing world grows
        //    later. Storm and Tremor buy their stability with these.
        let danger = BookRules.dangerProfile(for: book)
        for _ in 0..<danger.hazardTiles {
            guard let point = randomFreePoint(in: map, avoiding: occupied,
                                              minimumDistanceFrom: entry,
                                              distance: Tuning.World.enemyFreeRadiusAroundEntry,
                                              rng: &featureRNG)
            else { break }
            map[point].content = .hazard
            occupied.insert(point)
        }

        // 7. Sites — the discrete placed things. Eligibility is read off the world's *pressures*
        //    rather than off its symbols, so a site is found by writing a kind of place rather than
        //    by writing a specific recipe (docs/sites-system.md §2).
        let sites = SiteRules.place(in: map,
                                    readings: readings,
                                    contradictions: ContradictionRules.fired(in: sigils, readings: readings),
                                    avoiding: occupied, rng: &siteRNG)
        // 7a. **The cast** — the species this world settled on, before anything is placed. Drawn
        //     from the readings and the seed, so the same world always holds the same animals.
        let cast = LifeRules.cast(for: readings, seed: seed)

        var guardians: [WorldEnemy] = []
        for site in sites {
            map[site.position].content = .site(site.id)
            occupied.insert(site.position)
            // A guarded site is placed by the site system and statted by the creature system. The
            // guardian stands *on* the site, so the fight is the price of the search rather than a
            // separate mechanic.
            //
            // **Guarded by something local.** A world's most formidable animal is what has moved
            // into its ruins — an authored guardian would be a creature from nowhere, in a world
            // that grew everything else it holds.
            if site.definition?.contents.guardian != nil {
                let guardian = cast.max { $0.traits.appetite < $1.traits.appetite } ?? cast.first
                if let guardian {
                    guardians.append(spawn(guardian, at: site.position, rng: &siteRNG))
                }
            }
        }

        // 8. Diary pages. Scattered where their author would have been, unless they've waited
        //    long enough that they'll turn up anywhere — nothing may become unreachable.
        let pages = LibraryRules.placePages(in: readings, library: library, rng: &pageRNG)
        var placedPages: [DiaryPageID] = []
        for page in pages {
            guard let point = randomFreePoint(in: map, avoiding: occupied, rng: &pageRNG) else { break }
            map[point].content = .diaryPage(page)
            occupied.insert(point)
            placedPages.append(page)
        }

        // 9. Whoever this world's conditions describe is simply *here*.
        let travellers = LibraryRules.travellersPresent(in: readings).map(\.id)

        // 10. Enemies, drawn from the world's own cast. It's daytime when you arrive, so it's the
        //     day roster you meet; the night roster swaps in when the world turns.
        let dayRoster = roster(from: cast, nocturnal: false)
        let enemyCount = enemyCount(for: book, readings: readings, rng: &enemyRNG)
        var enemies: [WorldEnemy] = guardians
        for _ in 0..<enemyCount {
            guard let species = enemyRNG.pickWeighted(dayRoster),
                  let point = randomFreePoint(in: map, avoiding: occupied,
                                              minimumDistanceFrom: entry,
                                              distance: Tuning.World.enemyFreeRadiusAroundEntry,
                                              rng: &enemyRNG)
            else { continue }
            enemies.append(spawn(species, at: point, rng: &enemyRNG))
            occupied.insert(point)
        }

        WorldRules.reveal(around: entry, in: &map, radius: WorldRules.visionRadius(for: book))
        return (map, enemies, sites, placedPages, travellers, cast, entry)
    }

    // MARK: The roster

    /// One animal of a species, standing somewhere. Its own jitter is rolled here and kept, so a
    /// resume finds the same creature rather than re-rolling it.
    static func spawn(_ species: Species, at point: GridPoint, rng: inout SeededRNG) -> WorldEnemy {
        WorldEnemy(id: InstanceID(rawValue: rng.next()),
                   speciesID: species.id,
                   traits: LifeRules.spawn(of: species, rng: &rng),
                   position: point)
    }

    /// Who's out, and how common each of them is.
    ///
    /// **Cheap animals are numerous and expensive ones are rare** — the pyramid falls out of the
    /// same appetite number the budget is spent against, rather than being an authored spawn weight.
    /// Falls back to the whole cast where a world has nobody on the roster it asked for, because an
    /// empty world at nightfall is worse than a world whose animals keep odd hours.
    static func roster(from cast: [Species], nocturnal: Bool) -> [(value: Species, weight: Double)] {
        let onDuty = cast.filter { $0.isNocturnal == nocturnal }
        let pool = onDuty.isEmpty ? cast : onDuty
        guard let dearest = pool.map({ $0.traits.appetite }).max(), dearest > 0 else {
            return pool.map { (value: $0, weight: 1) }
        }
        return pool.map { (value: $0, weight: max(0.15, 1.15 - $0.traits.appetite / dearest)) }
    }

    // MARK: Counts

    /// Richer books put more nodes on the ground. Scales off the book's yield multipliers so a new
    /// bounty symbol automatically affects density without touching this function.
    /// How much is lying about, from how much the world actually holds.
    ///
    /// Dispersion decides whether it's spread thin or gathered into fewer, richer places — which is
    /// what makes the concentrated↔pervasive axis worth writing.
    static func nodeCount(for readings: PressureReadings, rng: inout SeededRNG) -> Int {
        let substrate = readings["substrate"]
        let vitality = readings["vitality"]
        let richness = (substrate.peak + vitality.peak) / Tuning.Pressure.scaleMaximum
        let dispersion = substrate.aspect("dispersion") / Tuning.Pressure.scaleMaximum

        let base = Double(rng.int(in: Tuning.World.baseNodeCountRange))
        // Pervasive: more nodes, each ordinary. Concentrated: fewer, and worth finding.
        let spread = 0.6 + dispersion * 0.8
        return max(1, Int((base * (0.4 + richness) * spread).rounded()))
    }

    /// More dangerous books put more enemies on the ground, on top of the nastier spawn table.
    static func enemyCount(for book: BoundBook, readings: PressureReadings, rng: inout SeededRNG) -> Int {
        let tier = BookRules.enemyTier(of: book)
        let base = rng.int(in: Tuning.World.baseEnemyCountRange)
        let scaled = base + (tier - Tuning.World.baseEnemyTier) * Tuning.World.enemiesPerDangerTier
        // Swarm multiplies the count and drops the tier; Predation does the reverse. Applied after
        // the tier term so the two really do pull against each other rather than one winning.
        // A world can only feed so much. Vitality is what pays for the roster.
        let productivity = max(0.25, readings["vitality"].peak / Tuning.Pressure.scaleMaximum)
        let multiplied = Double(scaled) * BookRules.dangerProfile(for: book).spawnMultiplier * (0.5 + productivity)
        return max(1, Int(multiplied.rounded()))
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
            // Nothing is placed where nobody can stand.
            !occupied.contains(point) && map[point].content == .empty && map[point].isPassable
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
