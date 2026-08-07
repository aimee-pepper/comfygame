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

    static func paint(_ map: inout WorldMap, readings: PressureReadings, rng: inout SeededRNG) {
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

        paintWater(&map, water: water, freezing: freezing, rng: &rng)
        paintGrowth(&map, life: life, rng: &rng)
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
