import Foundation

/// Painting the ground from what a world is.
///
/// The prerequisite the generation spine names first (`generation-spine-spec.md` §2): until tiles
/// had a ground type, **Relief had nothing to write to** and every "openness sets ambush versus
/// pursuit" rule was unimplementable. It could reach creature sight and nothing else.
///
/// Which target writes what, per the spec:
/// - **Relief** authors openness and elevation variance — long sightlines and cursorial ground, or
///   dense obstruction and chokepoints.
/// - **Substrate** decides what's underfoot: composition picks stone, sand, soil or rubble, and
///   volatile ground adds ash.
/// - **Hydrology** paints water, with dispersion deciding one lake or many ponds.
/// - **Thermal** overrides: freezing turns water to ice, and extreme heat turns soil to sand.
/// - **Vitality** lays growth over passable ground — which is the cover that makes ambush work.
enum TerrainRules {

    /// - Parameter asWritten: the same world resolved **without the chance fill**. Only chasms read
    ///   it, and they read it as a floor: writing a hole has to make a hole, or the word means
    ///   nothing, and a rolled vein of magma would otherwise quietly fill in what you asked for.
    ///   Chance can still add holes to a page that said nothing about the ground — that's the
    ///   surprise under-specification is for.
    static func paint(_ map: inout WorldMap, readings: PressureReadings,
                      asWritten: PressureReadings? = nil, rng: inout SeededRNG) {
        let substrate = readings["substrate"]
        let water = readings["hydrology"]
        let thermal = readings["thermal"]
        let relief = readings["relief"]
        let life = readings["vitality"]

        let openness = relief.aspect("openness")
        let verticality = relief.aspect("verticality")
        let freezing = thermal.floor < Tuning.Pressure.freezingFloor
        let scorching = thermal.peak > Tuning.Pressure.evaporatingPeak

        // Substrate composition, as weights over what the ground can be.
        var ground: [(value: GroundType, weight: Double)] = [
            (.stone, substrate.share(of: "hard") * 100 + 10),
            (.sand, substrate.share(of: "ductile") * 60 + (scorching ? 40 : 5)),
            (.soil, scorching ? 5 : 40),
            (.rubble, substrate.share(of: "volatile") * 70 + (100 - openness) * 0.2),
            (.ash, substrate.share(of: "volatile") * 50)
        ].filter { $0.weight > 0 }
        if ground.isEmpty { ground = [(.soil, 1)] }

        for point in map.allPoints {
            map[point].ground = rng.pickWeighted(ground) ?? .soil
            // Broken country is high country. Openness flattens it back out.
            let ruggedness = (verticality / 100) * (1 - openness / 200)
            map[point].elevation = rng.chance(ruggedness) ? rng.int(in: 1...3) : 0
        }

        let holes = max(chasmCoverage(in: readings),
                        asWritten.map { chasmCoverage(in: $0) } ?? 0)
        paintChasms(&map, coverage: holes, rng: &rng)
        paintWater(&map, water: water, freezing: freezing, rng: &rng)
        paintGrowth(&map, life: life, rng: &rng)
    }

    // MARK: Chasms — Substrate's word for less

    /// **How much of this world is hole.**
    ///
    /// Gated on the `broken-ground` tag rather than on substrate being low, because those are two
    /// different worlds: Silt is poor ground and Chasm is *absent* ground, and both read as a small
    /// number. Only the word that means holes puts holes in the map.
    ///
    /// Scaled by the **demand** rather than the reading, because the reading bottoms out at zero and
    /// "there is no rock here" and "there is catastrophically no rock here" are the same 0. The
    /// demand is the only record of how hard the page asked, which is what decides how riven a world
    /// gets. **[PLACEHOLDER]** numbers.
    static func chasmCoverage(in readings: PressureReadings) -> Double {
        let substrate = readings["substrate"]
        guard substrate.has("broken-ground") else { return 0 }
        let ordinary = ContentCatalog.shared.pressureTarget("substrate")?.baseline
            ?? Tuning.Pressure.scaleMaximum / 2
        let missing = max(0, ordinary - substrate.demand)
        let full = ordinary * Tuning.Terrain.chasmFullDeficitMultiple
        guard full > 0 else { return 0 }
        return min(Tuning.Terrain.chasmCoverageCeiling,
                   missing / full * Tuning.Terrain.chasmCoverageCeiling)
    }

    /// **So full of empty holes that the only way out is the way you came in** (Aimee, 7 Aug).
    ///
    /// The one world that gets no exit portal. It is not a trap — the entry has always worked as an
    /// exit, and retreating the way you came has always been possible — but it costs you the whole
    /// walk back, and you have to want the world that badly.
    ///
    /// **Read off what was written, never off the chance fill.** Losing the way out is a price for
    /// something you deliberately asked for; having it taken by a rolled focus you never wrote would
    /// be an ambush, and the brief's *every world has an exit* rule exists to prevent exactly that.
    /// So chance may put holes in a world, and may not close the door behind you.
    static func isRiven(asWritten readings: PressureReadings) -> Bool {
        chasmCoverage(in: readings) >= Tuning.Terrain.rivenChasmCoverage
    }

    /// Holes, grown outward from a few mouths rather than sprinkled. A chasm is a thing the ground
    /// did once, in a place, not a uniform porosity.
    private static func paintChasms(_ map: inout WorldMap, coverage: Double, rng: inout SeededRNG) {
        guard coverage > 0.01 else { return }
        let target = Int(Double(map.tiles.count) * coverage)
        let mouths = max(1, Int((coverage * Tuning.Terrain.chasmMouthsAtFullCoverage).rounded()))
        let perMouth = max(1, target / mouths)

        for _ in 0..<mouths {
            guard var head = rng.pick(map.allPoints) else { continue }
            for _ in 0..<perMouth {
                guard map.contains(head) else { break }
                map[head].ground = .chasm
                map[head].elevation = 0
                head = rng.pick(map.neighbours(of: head)) ?? head
            }
        }
    }

    // MARK: Reachability

    /// Every square you can actually walk to from where you arrive.
    static func reachable(from start: GridPoint, in map: WorldMap) -> Set<GridPoint> {
        guard map.contains(start) else { return [] }
        var seen: Set<GridPoint> = [start]
        var frontier = [start]
        while let point = frontier.popLast() {
            for next in map.neighbours(of: point) where map[next].isPassable && !seen.contains(next) {
                seen.insert(next)
                frontier.append(next)
            }
        }
        return seen
    }

    /// **Pathing must still be possible** (Aimee, 7 Aug), so holes are filled back in until it is.
    ///
    /// Carving from several mouths at once can cut a world into islands, and a world you arrive in
    /// one corner of is not the world the book described. This bridges the gaps: chasm squares along
    /// the edge of what you can reach are filled until most of the solid ground is walkable-to.
    ///
    /// It cannot always finish — a pocket walled off by deep water has no chasm to fill — so the
    /// generator also refuses to *place* anything outside the reachable region. Between the two,
    /// nothing a world contains is ever somewhere you can't get to.
    @discardableResult
    static func openTheWay(from start: GridPoint, in map: inout WorldMap,
                           rng: inout SeededRNG) -> Set<GridPoint> {
        var walkable = reachable(from: start, in: map)
        // Bounded rather than while-true: a world of islands in deep water would otherwise spin.
        for _ in 0..<Tuning.Terrain.maximumChasmBridges {
            let solid = map.allPoints.count { map[$0].isPassable }
            guard solid > 0,
                  Double(walkable.count) / Double(solid) < Tuning.Terrain.reachableGroundFraction
            else { break }
            // A hole on the edge of what we can reach, with solid ground stranded on its far side.
            var bridges: [GridPoint] = []
            for point in walkable {
                for hole in map.neighbours(of: point) where map[hole].ground == .chasm {
                    let strands = map.neighbours(of: hole).contains {
                        map[$0].isPassable && !walkable.contains($0)
                    }
                    if strands { bridges.append(hole) }
                }
            }
            bridges.sort { $0.y == $1.y ? $0.x < $1.x : $0.y < $1.y }
            guard let bridge = rng.pick(bridges) else { break }
            map[bridge].ground = .stone
            walkable = reachable(from: start, in: map)
        }
        return walkable
    }

    /// Water, in whatever form the heat allows.
    ///
    /// Dispersion is the difference between one lake and many ponds — the concentrated↔pervasive
    /// axis reaching the map rather than only the description.
    private static func paintWater(_ map: inout WorldMap, water: PressureReading,
                                   freezing: Bool, rng: inout SeededRNG) {
        // **How much water there is, not how much of it is usable.** `availableMagnitude` excludes
        // frozen and airborne water because that's what *life* can drink — but a glacier is still
        // very much on the map. Painting from it meant a fully frozen world had no water tiles at
        // all: write Sea and Glacier together and you got bare rock (6 Aug).
        let coverage = water.peak / 100 * Tuning.Terrain.maximumWaterCoverage
        guard coverage > 0.01 else { return }

        let wet: GroundType = freezing || water.share(of: "frozen") > 0.5 ? .ice : .water
        let deep: GroundType = wet == .ice ? .ice : .deepWater
        let target = Int(Double(map.tiles.count) * coverage)

        // Concentrated water pools into a few big bodies; pervasive water is scattered everywhere.
        let dispersion = water.aspect("dispersion") / 100
        let bodies = max(1, Int((1 + dispersion * Tuning.Terrain.pondsAtFullDispersion).rounded()))
        let perBody = max(1, target / bodies)

        for _ in 0..<bodies {
            guard var head = rng.pick(map.allPoints) else { continue }
            for step in 0..<perBody {
                guard map.contains(head) else { break }
                // The middle of a body is deep; its edges aren't.
                map[head].ground = step < perBody / 3 ? deep : wet
                map[head].elevation = 0
                head = rng.pick(map.neighbours(of: head)) ?? head
            }
        }
    }

    /// Growth over ground that can carry it. Cover, and therefore ambush.
    private static func paintGrowth(_ map: inout WorldMap, life: PressureReading, rng: inout SeededRNG) {
        let density = life.peak / 100 * Tuning.Terrain.maximumGrowthCoverage
        guard density > 0.01 else { return }
        for point in map.allPoints where map[point].ground.isPassable && map[point].ground != .water {
            if rng.chance(density) { map[point].ground = .growth }
        }
    }

    /// Somewhere solid to arrive. Being spawned in deep water is not a world, it's a bug.
    static func firmGround(near point: GridPoint, in map: WorldMap) -> GridPoint {
        if map[point].isPassable { return point }
        return map.allPoints
            .filter { map[$0].isPassable }
            .min { $0.chebyshevDistance(to: point) < $1.chebyshevDistance(to: point) } ?? point
    }
}
