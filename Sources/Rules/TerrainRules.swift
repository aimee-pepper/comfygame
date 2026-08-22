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
/// - **Vitality**, through the **flora** it grows, lays cover over passable ground — which is what
///   makes ambush work. Vitality doesn't paint it directly any more: *plants* do, and which plants
///   decides whether the cover hides anything.
enum TerrainRules {

    private static func stablePoints<S: Sequence>(_ points: S) -> [GridPoint]
    where S.Element == GridPoint {
        Array(points).sorted { lhs, rhs in
            lhs.y == rhs.y ? lhs.x < rhs.x : lhs.y < rhs.y
        }
    }

    struct FlowingChannelDiagnostics: Equatable {
        let source: GridPoint
        let outlet: GridPoint
        let route: [GridPoint]
        let allocatedTiles: Int
        let joinedExistingChannel: Bool
        let tiles: [GridPoint]
    }

    struct HydrologyDiagnostics: Equatable {
        let succeeded: Bool
        let allocated: [Int]
        let standingTiles: Int
        let flowingTiles: Int
        let frozenTiles: Int
        let channels: [FlowingChannelDiagnostics]
        let standingBodies: [[GridPoint]]
    }

    struct ReachabilityDiagnostics: Equatable {
        let reachable: Set<GridPoint>
        let softenedDeepWater: Int
        let filledChasm: Int
        let reachableFraction: Double
        let succeeded: Bool
    }

    static func hydrologyStageForTesting(
        width: Int, height: Int, elevations: [Int]? = nil,
        water: PressureReading, freezing: Bool, seed: UInt64
    ) -> WorldMap {
        var map = WorldMap(width: width, height: height,
                           tiles: Array(repeating: Tile(), count: width * height),
                           entry: .init(x: 0, y: 0))
        if let elevations {
            precondition(elevations.count == map.tiles.count)
            for index in elevations.indices { map.tiles[index].elevation = elevations[index] }
        }
        var rng = SeededRNG(seed: seed)
        _ = paintWater(&map, water: water, freezing: freezing, rng: &rng)
        return map
    }

    static func hydrologyStageWithDiagnosticsForTesting(
        width: Int, height: Int, elevations: [Int]? = nil,
        water: PressureReading, freezing: Bool, seed: UInt64
    ) -> (map: WorldMap, diagnostics: HydrologyDiagnostics) {
        var map = WorldMap(width: width, height: height,
                           tiles: Array(repeating: Tile(), count: width * height),
                           entry: .init(x: 0, y: 0))
        if let elevations {
            precondition(elevations.count == map.tiles.count)
            for index in elevations.indices { map.tiles[index].elevation = elevations[index] }
        }
        var rng = SeededRNG(seed: seed)
        let diagnostics = paintWater(&map, water: water, freezing: freezing, rng: &rng)
        return (map, diagnostics)
    }

    static func flowingStageForTesting(
        width: Int, height: Int, elevations: [Int], quota: Int,
        dispersion: Double, peak: Double, standingOutlets: Set<GridPoint> = [], seed: UInt64
    ) -> (map: WorldMap, diagnostics: [FlowingChannelDiagnostics]) {
        precondition(elevations.count == width * height)
        var map = WorldMap(width: width, height: height,
                           tiles: Array(repeating: Tile(), count: width * height),
                           entry: .init(x: 0, y: 0))
        for index in elevations.indices { map.tiles[index].elevation = elevations[index] }
        var occupied = standingOutlets
        for point in standingOutlets {
            map[point].ground = .water
            map[point].baseGround = .water
        }
        var rng = SeededRNG(seed: seed)
        let diagnostics = paintFlowingWater(
            &map, quota: quota, dispersion: dispersion, peak: peak,
            outlets: standingOutlets, occupied: &occupied, rng: &rng)
        return (map, diagnostics)
    }

    /// - Parameter asWritten: the same world resolved **without the chance fill**. Only chasms read
    ///   it, and they read it as a floor: writing a hole has to make a hole, or the word means
    ///   nothing, and a rolled vein of magma would otherwise quietly fill in what you asked for.
    ///   Chance can still add holes to a page that said nothing about the ground — that's the
    ///   surprise under-specification is for.
    /// - Parameter flora: what grows here. **Painting has to run with or after the ground** (spec
    ///   §5), because it converts passable ground to growth and needs to know what's passable.
    @discardableResult
    static func paint(_ map: inout WorldMap, readings: PressureReadings,
                      asWritten: PressureReadings? = nil, flora: [Flora] = [],
                      resolvedSigils: [Sigil] = [], visualSeed: UInt64 = 0,
                      rng: inout SeededRNG) -> Bool {
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

        guard paintConnectedSubstrate(&map, weightedGround: ground,
                                      dispersion: substrate.aspect("dispersion"), rng: &rng) != nil
        else { return false }
        // Broken country is high country. Openness flattens it back out. Elevation is grown from
        // a bounded set of peaks so it describes slopes, rather than unrelated per-cell dice.
        let ruggedness = (verticality / 100) * (1 - openness / 200)
        paintCoherentElevation(&map, ruggedness: ruggedness, verticality: verticality,
                               openness: openness, rng: &rng)

        let holes = max(chasmCoverage(in: readings),
                        asWritten.map { chasmCoverage(in: $0) } ?? 0)
        paintChasms(&map, coverage: holes, rng: &rng)
        guard paintWater(&map, water: water, freezing: freezing, rng: &rng).succeeded
        else { return false }
        relaxCardinalElevation(&map)
        paintMud(&map, freezing: freezing)
        paintGrowth(&map, life: life, flora: flora, rng: &rng)
        paintSurfaceDeposits(&map, sigils: resolvedSigils, visualSeed: visualSeed)
        return true
    }

    private static let substrateTieOrder: [GroundType] = [.stone, .soil, .sand, .rubble, .ash]

    /// Chasm and hydrology overlays may lower a tile after the authored relief pass. Reconcile only
    /// those resulting cliffs so the final persisted map retains the cardinal elevation contract.
    private static func relaxCardinalElevation(_ map: inout WorldMap) {
        var changed = true
        while changed {
            changed = false
            for point in stablePoints(map.allPoints) {
                let allowed = (map.neighbours(of: point).map { map[$0].elevation }.min() ?? 0) + 1
                if map[point].elevation > allowed {
                    map[point].elevation = max(0, allowed)
                    changed = true
                }
            }
        }
    }

    struct SubstrateDiagnostics: Equatable {
        let quotas: [GroundType: Int]
        let componentSizes: [GroundType: [Int]]
        let components: [GroundType: [[GridPoint]]]
        let retryCount: Int
    }

    static func substrateStageForTesting(
        width: Int, height: Int, weights: [(GroundType, Double)],
        dispersion: Double, seed: UInt64
    ) -> (map: WorldMap, diagnostics: SubstrateDiagnostics) {
        var map = WorldMap(width: width, height: height,
                           tiles: Array(repeating: Tile(), count: width * height),
                           entry: .init(x: 0, y: 0))
        var rng = SeededRNG(seed: seed)
        let diagnostics = paintConnectedSubstrate(
            &map, weightedGround: weights.map { (value: $0.0, weight: $0.1) },
            dispersion: dispersion, rng: &rng)
        return (map, diagnostics!)
    }

    static func substrateSucceededForTesting(
        width: Int, height: Int, weights: [(GroundType, Double)],
        dispersion: Double, seed: UInt64
    ) -> Bool {
        substrateStageIfPossibleForTesting(
            width: width, height: height, weights: weights,
            dispersion: dispersion, seed: seed) != nil
    }

    static func substrateStageIfPossibleForTesting(
        width: Int, height: Int, weights: [(GroundType, Double)],
        dispersion: Double, seed: UInt64
    ) -> (map: WorldMap, diagnostics: SubstrateDiagnostics)? {
        var map = WorldMap(width: width, height: height,
                           tiles: Array(repeating: Tile(), count: width * height),
                           entry: .init(x: 0, y: 0))
        var rng = SeededRNG(seed: seed)
        guard let diagnostics = paintConnectedSubstrate(
            &map, weightedGround: weights.map { (value: $0.0, weight: $0.1) },
            dispersion: dispersion, rng: &rng) else { return nil }
        return (map, diagnostics)
    }

    private struct SubstrateRegion {
        let material: GroundType
        let quota: Int
        var points: Set<GridPoint>
    }

    /// Exact largest-remainder quotas and simultaneous region growth from deterministic farthest
    /// seeds. Every tie that is not frozen by material order consumes the terrain stream.
    @discardableResult
    private static func paintConnectedSubstrate(
        _ map: inout WorldMap,
        weightedGround: [(value: GroundType, weight: Double)],
        dispersion: Double,
        rng: inout SeededRNG
    ) -> SubstrateDiagnostics? {
        let total = weightedGround.reduce(0) { $0 + $1.weight }
        guard total > 0, !map.allPoints.isEmpty else { return nil }
        let count = map.allPoints.count
        let weights = Dictionary(uniqueKeysWithValues: weightedGround.map { ($0.value, $0.weight) })
        var quotas = substrateTieOrder.map { material -> (GroundType, Int, Double) in
            let exact = Double(count) * (weights[material] ?? 0) / total
            let floor = Int(exact.rounded(.down))
            return (material, floor, exact - Double(floor))
        }
        var remainder = count - quotas.reduce(0) { $0 + $1.1 }
        for index in quotas.indices.sorted(by: { quotas[$0].2 == quotas[$1].2
            ? $0 < $1 : quotas[$0].2 > quotas[$1].2 })
        where remainder > 0 {
            quotas[index].1 += 1
            remainder -= 1
        }
        let minimumQuota = 4
        // Higher quota wins; the frozen material order wins an exact tie.
        let dominantIndex = quotas.indices.sorted {
            quotas[$0].1 == quotas[$1].1 ? $0 < $1 : quotas[$0].1 > quotas[$1].1
        }.first ?? 0
        for index in quotas.indices where index != dominantIndex && quotas[index].1 < minimumQuota {
            quotas[dominantIndex].1 += quotas[index].1
            quotas[index].1 = 0
        }
        let frozenQuotas = Dictionary(uniqueKeysWithValues: quotas.map { ($0.0, $0.1) })
        let desiredRegions = min(5, 1 + Int(max(0, min(100, dispersion)) / 25))
        let attemptRoot = rng.next()
        var retries = 0
        for reduction in 0..<desiredRegions {
            let regionCounts = Dictionary(uniqueKeysWithValues: quotas.compactMap { material, quota, _ in
                quota > 0 ? (material, min(max(1, desiredRegions - reduction), max(1, quota / 8))) : nil
            })
            // Equal five-material live maps have named reproducible traps once topology reduces to
            // one region per material. Give only that least-constrained final topology the accepted
            // bounded retry budget; multi-region shapes retain the smaller shared budget.
            let attemptsForReduction = reduction == desiredRegions - 1
                ? 32 : max(1, 30 / desiredRegions)
            for attempt in 0..<attemptsForReduction {
                var attemptRNG = SeededRNG(seed: attemptRoot)
                    .derived(UInt64(reduction * attemptsForReduction + attempt + 1))
                if let painted = substrateAttempt(map: map, quotas: frozenQuotas,
                                                   regionCounts: regionCounts, rng: &attemptRNG) {
                    map = painted
                    let components = materialComponents(in: painted)
                    return .init(quotas: frozenQuotas,
                                 componentSizes: components.mapValues { $0.map(\.count).sorted() },
                                 components: components,
                                 retryCount: retries)
                }
                retries += 1
            }
        }
        return nil
    }

    private static func substrateAttempt(
        map: WorldMap, quotas: [GroundType: Int], regionCounts: [GroundType: Int],
        rng: inout SeededRNG
    ) -> WorldMap? {
        var regions: [SubstrateRegion] = []
        var seeds: [GridPoint] = []
        for material in substrateTieOrder where quotas[material, default: 0] > 0 {
            let quota = quotas[material, default: 0]
            let count = regionCounts[material, default: 1]
            let base = quota / count, extra = quota % count
            for regionIndex in 0..<count {
                let candidates = map.allPoints.filter { !seeds.contains($0) }
                let distances = candidates.map { candidate in
                    seeds.map { abs(candidate.x - $0.x) + abs(candidate.y - $0.y) }.min() ?? Int.max
                }
                let farthest = distances.max() ?? 0
                guard let seed = rng.pick(stablePoints(zip(candidates, distances).compactMap {
                    $0.1 == farthest ? $0.0 : nil
                })) else { return nil }
                seeds.append(seed)
                regions.append(.init(material: material,
                                     quota: base + (regionIndex < extra ? 1 : 0), points: [seed]))
            }
        }
        var owner: [GridPoint: Int] = [:]
        for index in regions.indices { owner[regions[index].points.first!] = index }
        while owner.count < map.tiles.count {
            var advanced = false
            let unfinished = regions.indices.filter {
                regions[$0].points.count < regions[$0].quota
            }.sorted { lhs, rhs in
                let lhsFrontier = Set(regions[lhs].points.flatMap { map.neighbours(of: $0) })
                    .count { owner[$0] == nil }
                let rhsFrontier = Set(regions[rhs].points.flatMap { map.neighbours(of: $0) })
                    .count { owner[$0] == nil }
                if lhsFrontier != rhsFrontier { return lhsFrontier < rhsFrontier }
                let lhsRemaining = regions[lhs].quota - regions[lhs].points.count
                let rhsRemaining = regions[rhs].quota - regions[rhs].points.count
                return lhsRemaining == rhsRemaining ? lhs < rhs : lhsRemaining > rhsRemaining
            }
            for index in unfinished where regions[index].points.count < regions[index].quota {
                let frontier = Set(regions[index].points.flatMap { map.neighbours(of: $0) })
                    .filter { owner[$0] == nil }
                let scored = stablePoints(frontier).map { point -> (GridPoint, Int) in
                    let cardinal = map.neighbours(of: point).count {
                        owner[$0].map { regions[$0].material } == regions[index].material
                    }
                    let diagonal = diagonalNeighbours(of: point, in: map).count {
                        owner[$0].map { regions[$0].material } == regions[index].material
                    }
                    return (point, cardinal * 8 + diagonal * 2)
                }
                let scores = Array(Set(scored.map(\.1))).sorted(by: >)
                var accepted: GridPoint?
                for score in scores where accepted == nil {
                    var tied = stablePoints(scored.compactMap { $0.1 == score ? $0.0 : nil })
                    while !tied.isEmpty, accepted == nil {
                        let candidate = tied.remove(at: rng.int(in: 0...(tied.count - 1)))
                        owner[candidate] = index
                        regions[index].points.insert(candidate)
                        if unfinishedRegionsHaveCapacity(regions, owner: owner, in: map) {
                            accepted = candidate
                        } else {
                            regions[index].points.remove(candidate)
                            owner.removeValue(forKey: candidate)
                        }
                    }
                }
                guard accepted != nil else { return nil }
                advanced = true
            }
            if !advanced { return nil }
        }
        var result = map
        for point in map.allPoints {
            guard let region = owner[point] else { return nil }
            result[point].ground = regions[region].material
            result[point].baseGround = regions[region].material
        }
        let sizes = materialComponentSizes(in: result)
        guard substrateTieOrder.allSatisfy({ material in
            result.allPoints.count { result[$0].baseGround == material } == quotas[material, default: 0]
                && sizes[material, default: []].count <= regionCounts[material, default: 0]
                && sizes[material, default: []].allSatisfy { $0 > 1 }
        }) else { return nil }
        return result
    }

    private static func unfinishedRegionsHaveCapacity(
        _ regions: [SubstrateRegion], owner: [GridPoint: Int], in map: WorldMap
    ) -> Bool {
        var unowned = Set(map.allPoints.filter { owner[$0] == nil })
        var componentByPoint: [GridPoint: Int] = [:]
        var componentSizes: [Int] = []
        while let start = stablePoints(unowned).first {
            let componentIndex = componentSizes.count
            var size = 0, frontier = [start]
            unowned.remove(start)
            while let point = frontier.popLast() {
                componentByPoint[point] = componentIndex
                size += 1
                for next in map.neighbours(of: point) where unowned.remove(next) != nil {
                    frontier.append(next)
                }
            }
            componentSizes.append(size)
        }
        for componentIndex in componentSizes.indices {
            let componentPoints = componentByPoint.compactMap {
                $0.value == componentIndex ? $0.key : nil
            }
            let adjacentRegions = Set(componentPoints.flatMap { map.neighbours(of: $0) }
                .compactMap { owner[$0] }
                .filter { regions[$0].points.count < regions[$0].quota })
            guard !adjacentRegions.isEmpty else { return false }
            if adjacentRegions.count == 1, let region = adjacentRegions.first {
                let remaining = regions[region].quota - regions[region].points.count
                if componentSizes[componentIndex] > remaining { return false }
            }
        }
        for index in regions.indices where regions[index].points.count < regions[index].quota {
            let adjacentComponents = Set(regions[index].points.flatMap { map.neighbours(of: $0) }
                .compactMap { componentByPoint[$0] })
            let capacity = regions[index].points.count
                + adjacentComponents.reduce(0) { $0 + componentSizes[$1] }
            if capacity < regions[index].quota { return false }
        }
        return true
    }

    private static func materialComponentSizes(in map: WorldMap) -> [GroundType: [Int]] {
        materialComponents(in: map).mapValues { $0.map(\.count).sorted() }
    }

    private static func materialComponents(in map: WorldMap) -> [GroundType: [[GridPoint]]] {
        var remaining = Set(map.allPoints)
        var result: [GroundType: [[GridPoint]]] = [:]
        while let start = stablePoints(remaining).first {
            let material = map[start].baseGround
            var seen: Set<GridPoint> = [start], frontier = [start]
            remaining.remove(start)
            while let point = frontier.popLast() {
                for next in map.neighbours(of: point)
                where remaining.contains(next) && map[next].baseGround == material {
                    remaining.remove(next); seen.insert(next); frontier.append(next)
                }
            }
            result[material, default: []].append(stablePoints(seen))
        }
        return result.mapValues { components in
            components.sorted { lhs, rhs in
                if lhs.count != rhs.count { return lhs.count < rhs.count }
                let a = stablePoints(lhs).first!, b = stablePoints(rhs).first!
                return (a.y, a.x) < (b.y, b.x)
            }
        }
    }

    private static func diagonalNeighbours(of point: GridPoint, in map: WorldMap) -> [GridPoint] {
        stablePoints([
            GridPoint(x: point.x - 1, y: point.y - 1),
            GridPoint(x: point.x + 1, y: point.y - 1),
            GridPoint(x: point.x - 1, y: point.y + 1),
            GridPoint(x: point.x + 1, y: point.y + 1),
        ].filter(map.contains))
    }

    private static func paintCoherentElevation(
        _ map: inout WorldMap, ruggedness: Double, verticality: Double, openness: Double,
        rng: inout SeededRNG
    ) {
        for point in map.allPoints { map[point].elevation = 0 }
        let elevatedQuota = min(map.tiles.count, max(0, Int((Double(map.tiles.count) * ruggedness).rounded())))
        guard elevatedQuota > 0 else { return }
        let maximumHeight = verticality <= 33 ? 1 : (verticality <= 66 ? 2 : 3)
        let peakCount = min(4, elevatedQuota, 1 + Int((100 - max(0, min(100, openness))) / 34))
        var peaks: [GridPoint] = []
        for _ in 0..<peakCount {
            let candidates = map.allPoints.filter { !peaks.contains($0) }
            let distance = candidates.map { candidate in
                peaks.map { abs(candidate.x - $0.x) + abs(candidate.y - $0.y) }.min() ?? Int.max
            }
            let farthest = distance.max() ?? 0
            guard let point = rng.pick(stablePoints(zip(candidates, distance).compactMap {
                $0.1 == farthest ? $0.0 : nil
            })) else { continue }
            peaks.append(point)
            map[point].elevation = maximumHeight
        }
        var elevated = Set(peaks)
        while elevated.count < elevatedQuota {
            let frontier = Set(elevated.flatMap { map.neighbours(of: $0) }).subtracting(elevated)
            guard !frontier.isEmpty else { break }
            let scored = stablePoints(frontier).map { point -> (GridPoint, Int) in
                let height = map.neighbours(of: point).map { map[$0].elevation }.max() ?? 1
                return (point, max(1, height - 1))
            }
            let best = scored.map(\.1).max() ?? 1
            guard let chosen = rng.pick(stablePoints(scored.compactMap {
                $0.1 == best ? $0.0 : nil
            })) else { break }
            map[chosen].elevation = best
            elevated.insert(chosen)
        }
        var changed = true
        while changed {
            changed = false
            for point in stablePoints(elevated) {
                let allowed = (map.neighbours(of: point).map { map[$0].elevation }.min() ?? 0) + 1
                if map[point].elevation > allowed {
                    map[point].elevation = max(1, allowed)
                    changed = true
                }
            }
        }
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
                map[head].baseGround = .chasm
                map[head].elevation = 0
                head = rng.pick(map.neighbours(of: head)) ?? head
            }
        }
    }

    // MARK: Reachability

    /// Every square you can actually walk to from where you arrive.
    static func reachable(from start: GridPoint, in map: WorldMap) -> Set<GridPoint> {
        guard map.contains(start), map[start].isPassable else { return [] }
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

    /// A world begins in its largest walkable land-and-shallow-water region. The old nearest-firm
    /// lookup could select a two-tile pocket beside an edge sample while almost the whole map sat
    /// behind Deep Water. Candidate ordering is canonical before the seeded tie break.
    static func entryPoint(in map: WorldMap, near preferred: GridPoint,
                           rng: inout SeededRNG) -> GridPoint? {
        var unseen = Set(map.allPoints.filter { map[$0].isPassable })
        var components: [[GridPoint]] = []
        while let seed = stablePoints(unseen).first {
            let component = reachable(from: seed, in: map)
            components.append(stablePoints(component))
            unseen.subtract(component)
        }
        guard let largestSize = components.map(\.count).max() else { return nil }
        let largest = components.filter { $0.count == largestSize }
            .sorted {
                let lhs = stablePoints($0).first!, rhs = stablePoints($1).first!
                return (lhs.y, lhs.x) < (rhs.y, rhs.x)
            }
        guard let component = rng.pick(largest) else { return nil }
        let edge = component.filter {
            $0.x == 0 || $0.y == 0 || $0.x == map.width - 1 || $0.y == map.height - 1
        }
        let edgePreferred: [GridPoint]
        if !edge.isEmpty {
            edgePreferred = edge
        } else {
            let nearestEdge = component.map {
                [$0.x, $0.y, map.width - 1 - $0.x, map.height - 1 - $0.y].min()!
            }.min()!
            edgePreferred = component.filter {
                [$0.x, $0.y, map.width - 1 - $0.x, map.height - 1 - $0.y].min()!
                    == nearestEdge
            }
        }
        let firm = edgePreferred.filter { map[$0].baseGround != .water }
        let candidates = firm.isEmpty ? edgePreferred : firm
        let nearest = candidates.map { $0.chebyshevDistance(to: preferred) }.min()!
        return rng.pick(stablePoints(candidates.filter {
            $0.chebyshevDistance(to: preferred) == nearest
        }))
    }

    static func prepareEntry(at point: GridPoint, in map: inout WorldMap) {
        map[point].flora = nil
        if map[point].ground.isOvergrown {
            map[point].ground = map[point].baseGround
        }
    }

    /// **Pathing must still be possible** (Aimee, 7 Aug), so holes are filled back in until it is.
    ///
    /// Carving from several mouths at once can cut a world into islands, and a world you arrive in
    /// one corner of is not the world the book described. This bridges the gaps: chasm squares along
    /// the edge of what you can reach are filled until most of the solid ground is walkable-to.
    ///
    /// Deep Water remains a real basin/core, but the minimum blocking cells on a route to another
    /// walkable component may be softened to shallow Water. This preserves bodies while preventing
    /// a generated two-tile start pocket. Content is placed only after this repair.
    @discardableResult
    static func openTheWay(from start: GridPoint, in map: inout WorldMap,
                           rng: inout SeededRNG) -> Set<GridPoint> {
        openTheWayWithDiagnostics(from: start, in: &map, rng: &rng).reachable
    }

    @discardableResult
    static func openTheWayWithDiagnostics(from start: GridPoint, in map: inout WorldMap,
                                          rng: inout SeededRNG) -> ReachabilityDiagnostics {
        _ = rng // The signature preserves the isolated terrain substream boundary.
        var walkable = reachable(from: start, in: map)
        var softenedDeepWater = 0
        var filledChasm = 0
        // Bounded by the map: every successful pass softens at least one blocking tile or joins a
        // passable component, so this cannot loop indefinitely.
        for _ in 0..<map.tiles.count {
            let solid = map.allPoints.count { map[$0].isPassable }
            guard solid > 0,
                  Double(walkable.count) / Double(solid) < Tuning.Terrain.reachableGroundFraction
            else { break }
            guard let route = minimumBlockingRoute(from: walkable, in: map) else { break }
            for bridge in route where !map[bridge].isPassable {
                map[bridge].flora = nil
                if map[bridge].baseGround == .deepWater {
                    map[bridge].ground = .water
                    map[bridge].baseGround = .water
                    softenedDeepWater += 1
                } else {
                    map[bridge].ground = .stone
                    map[bridge].baseGround = .stone
                    map[bridge].surfaceDeposits = .init()
                    filledChasm += 1
                }
            }
            walkable = reachable(from: start, in: map)
        }
        let passable = map.allPoints.count { map[$0].isPassable }
        let fraction = passable == 0 ? 0 : Double(walkable.count) / Double(passable)
        return .init(reachable: walkable, softenedDeepWater: softenedDeepWater,
                     filledChasm: filledChasm, reachableFraction: fraction,
                     succeeded: fraction >= Tuning.Terrain.reachableGroundFraction)
    }

    private static func minimumBlockingRoute(from reached: Set<GridPoint>,
                                             in map: WorldMap) -> [GridPoint]? {
        var unseen = Set(map.allPoints.filter { map[$0].isPassable && !reached.contains($0) })
        var stranded: [[GridPoint]] = []
        while let seed = stablePoints(unseen).first {
            let component = reachable(from: seed, in: map).subtracting(reached)
            stranded.append(stablePoints(component))
            unseen.subtract(component)
        }
        guard let largestSize = stranded.map(\.count).max() else { return nil }
        let targets = Set(stranded.filter { $0.count == largestSize }.sorted {
            let lhs = $0.first!, rhs = $1.first!
            return (lhs.y, lhs.x) < (rhs.y, rhs.x)
        }.first!)
        struct Cost: Comparable {
            let blockers: Int
            let length: Int
            static func < (lhs: Cost, rhs: Cost) -> Bool {
                (lhs.blockers, lhs.length) < (rhs.blockers, rhs.length)
            }
        }
        var distance: [GridPoint: Cost] = [:]
        var previous: [GridPoint: GridPoint] = [:]
        var frontier = stablePoints(reached)
        for point in frontier { distance[point] = .init(blockers: 0, length: 0) }
        while !frontier.isEmpty {
            frontier.sort {
                let maximum = Cost(blockers: .max, length: .max)
                let ld = distance[$0, default: maximum], rd = distance[$1, default: maximum]
                return ld == rd ? ($0.y, $0.x) < ($1.y, $1.x) : ld < rd
            }
            let point = frontier.removeFirst()
            if targets.contains(point) {
                var route = [point]
                var cursor = point
                while let parent = previous[cursor] {
                    route.append(parent)
                    cursor = parent
                }
                return route.reversed()
            }
            for next in stablePoints(map.neighbours(of: point)) {
                let current = distance[point]!
                let candidate = Cost(blockers: current.blockers + (map[next].isPassable ? 0 : 1),
                                     length: current.length + 1)
                let maximum = Cost(blockers: .max, length: .max)
                if candidate < distance[next, default: maximum] {
                    distance[next] = candidate
                    previous[next] = point
                    frontier.append(next)
                }
            }
        }
        return nil
    }

    /// Water, in whatever form the heat allows.
    ///
    /// Dispersion is the difference between one lake and many ponds — the concentrated↔pervasive
    /// axis reaching the map rather than only the description.
    @discardableResult
    private static func paintWater(_ map: inout WorldMap, water: PressureReading,
                                   freezing: Bool, rng: inout SeededRNG) -> HydrologyDiagnostics {
        // **How much water there is, not how much of it is usable.** `availableMagnitude` excludes
        // frozen and airborne water because that's what *life* can drink — but a glacier is still
        // very much on the map. Painting from it meant a fully frozen world had no water tiles at
        // all: write Sea and Glacier together and you got bare rock (6 Aug).
        let forms: [(String, Double)] = [
            ("standing", water.share(of: "standing")),
            ("flowing", water.share(of: "flowing")),
            ("frozen", water.share(of: "frozen")),
        ]
        let surfaceShare = forms.reduce(0) { $0 + max(0, $1.1) }
        guard surfaceShare > 0 else { return .init(succeeded: true, allocated: [0, 0, 0], standingTiles: 0,
            flowingTiles: 0, frozenTiles: 0, channels: [], standingBodies: []) }
        let target = min(map.tiles.count, max(0, Int((Double(map.tiles.count)
            * water.peak / 100 * Tuning.Terrain.maximumWaterCoverage * surfaceShare).rounded())))
        guard target > 0 else { return .init(succeeded: true, allocated: [0, 0, 0], standingTiles: 0,
            flowingTiles: 0, frozenTiles: 0, channels: [], standingBodies: []) }
        let quotas = largestRemainder(total: target, weights: forms.map(\.1))
        var occupied: Set<GridPoint> = []
        let standing = paintStandingWater(&map, quota: quotas[0], dispersion: water.aspect("dispersion"),
                                          ground: .water, occupied: &occupied, rng: &rng)
        let channels = paintFlowingWater(&map, quota: quotas[1], dispersion: water.aspect("dispersion"), peak: water.peak,
                                         outlets: standing.tiles, occupied: &occupied, rng: &rng)
        let flowingTiles = channels.reduce(0) { $0 + $1.allocatedTiles }
        let standingTiles = standing.tiles.count
        let frozen = paintStandingWater(&map, quota: quotas[2], dispersion: water.aspect("dispersion"),
                                        ground: .ice, occupied: &occupied, rng: &rng)
        if freezing {
            for point in stablePoints(occupied)
            where map[point].baseGround == .water || map[point].baseGround == .deepWater {
                map[point].ground = .ice
                map[point].baseGround = .ice
            }
        }
        let succeeded = standing.tiles.count == quotas[0]
            && flowingTiles == quotas[1]
            && frozen.tiles.count == quotas[2]
            && occupied.count == target
        return .init(succeeded: succeeded, allocated: quotas, standingTiles: standingTiles,
                     flowingTiles: flowingTiles, frozenTiles: frozen.tiles.count, channels: channels,
                     standingBodies: standing.bodies)
    }

    private static func largestRemainder(total: Int, weights: [Double]) -> [Int] {
        let sum = weights.reduce(0) { $0 + max(0, $1) }
        guard sum > 0 else { return Array(repeating: 0, count: weights.count) }
        let exact = weights.map { Double(total) * max(0, $0) / sum }
        var result = exact.map { Int($0.rounded(.down)) }
        var left = total - result.reduce(0, +)
        for index in result.indices.sorted(by: { exact[$0] - Double(result[$0]) == exact[$1] - Double(result[$1])
            ? $0 < $1 : exact[$0] - Double(result[$0]) > exact[$1] - Double(result[$1]) }) where left > 0 {
            result[index] += 1; left -= 1
        }
        return result
    }

    private struct StandingPaint {
        let tiles: Set<GridPoint>
        let bodies: [[GridPoint]]
    }

    private static func paintStandingWater(
        _ map: inout WorldMap, quota: Int, dispersion: Double, ground: GroundType,
        occupied: inout Set<GridPoint>, rng: inout SeededRNG
    ) -> StandingPaint {
        guard quota > 0 else { return .init(tiles: [], bodies: []) }
        let requestedBodies = min(7, max(1, quota / 8),
            1 + Int((max(0, min(100, dispersion)) / 100 * 6).rounded()))
        let root = rng.next()
        for bodyCount in stride(from: requestedBodies, through: 1, by: -1) {
            let bodyQuotas = largestRemainder(
                total: quota, weights: Array(repeating: 1, count: bodyCount))
            for attempt in 0..<16 {
                var attemptRNG = SeededRNG(seed: root).derived(UInt64(bodyCount * 100 + attempt))
                var planned: [Set<GridPoint>] = []
                var blocked = occupied
                var failed = false
                for bodyQuota in bodyQuotas where bodyQuota > 0 {
                    let candidates = Set(map.allPoints).subtracting(blocked)
                    let hosts = cardinalComponents(in: candidates, map: map)
                        .filter { $0.count >= bodyQuota }
                        .sorted {
                            if $0.count != $1.count { return $0.count > $1.count }
                            let lhs = stablePoints($0).first!, rhs = stablePoints($1).first!
                            return (lhs.y, lhs.x) < (rhs.y, rhs.x)
                        }
                    guard let host = hosts.first else { failed = true; break }
                    let lowest = host.map { map[$0].elevation }.min() ?? 0
                    guard let seed = attemptRNG.pick(stablePoints(host.filter {
                        map[$0].elevation == lowest
                    })) else { failed = true; break }
                    var body: Set<GridPoint> = [seed]
                    while body.count < bodyQuota {
                        let frontier = Set(body.flatMap { map.neighbours(of: $0) })
                            .intersection(host).subtracting(body)
                        guard !frontier.isEmpty else { failed = true; break }
                        let minimum = frontier.map { map[$0].elevation }.min() ?? 0
                        guard let next = attemptRNG.pick(stablePoints(frontier.filter {
                            map[$0].elevation == minimum
                        })) else { failed = true; break }
                        body.insert(next)
                    }
                    if failed { break }
                    planned.append(body)
                    blocked.formUnion(body)
                    blocked.formUnion(body.flatMap { map.neighbours(of: $0) })
                }
                guard !failed, planned.reduce(0, { $0 + $1.count }) == quota else { continue }

                var result: Set<GridPoint> = []
                for body in planned {
                    for point in body {
                        map[point].ground = ground
                        map[point].baseGround = ground
                        map[point].elevation = 0
                    }
                    if ground == .water, body.count >= 9 {
                        let deepQuota = body.count / 3
                        let centres = body.map { point in
                            (point, map.neighbours(of: point).filter(body.contains).count)
                        }
                        let best = centres.map(\.1).max() ?? 0
                        if let centre = attemptRNG.pick(stablePoints(centres.compactMap {
                            $0.1 == best ? $0.0 : nil
                        })) {
                            var deep: Set<GridPoint> = [centre]
                            while deep.count < deepQuota {
                                let frontier = Set(deep.flatMap { map.neighbours(of: $0) })
                                    .intersection(body).subtracting(deep)
                                guard let next = attemptRNG.pick(stablePoints(frontier)) else { break }
                                deep.insert(next)
                            }
                            for point in deep {
                                map[point].ground = .deepWater
                                map[point].baseGround = .deepWater
                            }
                        }
                    }
                    result.formUnion(body)
                }
                occupied.formUnion(result)
                return .init(tiles: result, bodies: planned.map(stablePoints))
            }
        }
        return .init(tiles: [], bodies: [])
    }

    private static func cardinalComponents(in points: Set<GridPoint>, map: WorldMap) -> [Set<GridPoint>] {
        var remaining = points
        var result: [Set<GridPoint>] = []
        while let start = stablePoints(remaining).first {
            var component: Set<GridPoint> = [start], queue = [start]
            remaining.remove(start)
            while let point = queue.popLast() {
                for next in map.neighbours(of: point) where remaining.remove(next) != nil {
                    component.insert(next); queue.append(next)
                }
            }
            result.append(component)
        }
        return result
    }

    @discardableResult
    private static func paintFlowingWater(
        _ map: inout WorldMap, quota: Int, dispersion: Double, peak: Double,
        outlets: Set<GridPoint>, occupied: inout Set<GridPoint>, rng: inout SeededRNG
    ) -> [FlowingChannelDiagnostics] {
        guard quota > 0 else { return [] }
        let channelCount = min(4, quota, 1 + Int(max(0, min(100, dispersion)) / 34))
        let channelQuotas = largestRemainder(total: quota, weights: Array(repeating: 1, count: channelCount))
        var channels: Set<GridPoint> = []
        var diagnostics: [FlowingChannelDiagnostics] = []
        for channelQuota in channelQuotas where channelQuota > 0 {
            let dry = stablePoints(map.allPoints.filter { !occupied.contains($0) })
            let sortedHeights = dry.map { map[$0].elevation }.sorted()
            let quartile = sortedHeights[max(0, sortedHeights.count * 3 / 4 - 1)]
            let highSources = stablePoints(dry.filter { map[$0].elevation >= quartile })
            let interiorSources = highSources.filter {
                $0.x > 0 && $0.y > 0 && $0.x < map.width - 1 && $0.y < map.height - 1
            }
            func routesFor(_ sources: [GridPoint]) -> [[GridPoint]] {
                var result: [[GridPoint]] = []
                for source in sources {
                let validOutlet: (GridPoint) -> Bool = { point in
                    if map.neighbours(of: point).contains(where: outlets.contains) { return true }
                    if map.neighbours(of: point).contains(where: channels.contains) { return true }
                    let boundary = point.x == 0 || point.y == 0
                        || point.x == map.width - 1 || point.y == map.height - 1
                    return boundary && map[point].elevation <= map[source].elevation
                }
                if let route = nonUphillPath(from: source, isOutlet: validOutlet,
                                             excluding: occupied.subtracting(outlets), in: map,
                                             maximumLength: channelQuota), route.count <= channelQuota {
                        result.append(route)
                    }
                }
                return result
            }
            var routes = routesFor(interiorSources)
            if routes.isEmpty { routes = routesFor(highSources) }
            let scoredRoutes = routes.map { route -> (route: [GridPoint], score: Int) in
                let directions = zip(route, route.dropFirst()).map {
                    GridPoint(x: $1.x - $0.x, y: $1.y - $0.y)
                }
                let turns = zip(directions, directions.dropFirst()).count { $0 != $1 }
                let joins = route.last.map { endpoint in
                    map.neighbours(of: endpoint).contains(where: channels.contains) ? 1 : 0
                } ?? 0
                // A join offsets one mild turn; route length is handled only after this score.
                return (route, turns - joins)
            }
            let longest = scoredRoutes.map { $0.route.count }.max()
            let longRoutes = scoredRoutes.filter { $0.route.count == longest }
            let bestScore = longRoutes.map(\.score).min()
            let bestRoutes = longRoutes.filter { $0.score == bestScore }.map(\.route)
                .sorted(by: stablePathOrder)
            guard let routed = rng.pick(bestRoutes) else {
#if DEBUG
                print("[terrain topology] Flowing allocation could not reach a lower boundary or Standing outlet")
#endif
                continue
            }
            let source = routed[0]
            var channel = Set(routed)
            // If the outlet path is shorter than its allocation, grow connected bank-following
            // cells so the exact surface quota is retained without disconnected drops.
            while channel.count < channelQuota {
                let frontier = Set(channel.flatMap { map.neighbours(of: $0) }).subtracting(occupied).subtracting(channel)
                let scored = stablePoints(frontier).compactMap { point -> (GridPoint, Int, Int)? in
                    let attached = map.neighbours(of: point).filter(channel.contains)
                    guard let highestParent = attached.map({ map[$0].elevation }).max(),
                          map[point].elevation <= highestParent else { return nil }
                    let narrowPenalty = abs(attached.count - 1)
                    let span = abs(point.x - source.x) + abs(point.y - source.y)
                    return (point, narrowPenalty, span)
                }
                let narrowest = scored.map(\.1).min()
                let narrow = scored.filter { $0.1 == narrowest }
                let farthest = narrow.map(\.2).max()
                guard let next = rng.pick(stablePoints(scored.compactMap {
                    $0.1 == narrowest && $0.2 == farthest ? $0.0 : nil
                })) else { break }
                channel.insert(next)
            }
            let joinedExistingChannel = map.neighbours(of: routed.last!)
                .contains(where: channels.contains)
            for point in channel { map[point].ground = .water; map[point].baseGround = .water }
            if peak >= 70, channel.count >= 16 {
                let deepQuota = max(1, channel.count / 4)
                var deep: Set<GridPoint> = [source]
                while deep.count < deepQuota {
                    let frontier = Set(deep.flatMap { map.neighbours(of: $0) }).intersection(channel).subtracting(deep)
                    guard let next = rng.pick(stablePoints(frontier)) else { break }
                    deep.insert(next)
                }
                for point in deep { map[point].ground = .deepWater; map[point].baseGround = .deepWater }
            }
            occupied.formUnion(channel); channels.formUnion(channel)
            diagnostics.append(.init(source: source, outlet: routed.last!, route: routed,
                                     allocatedTiles: channel.count,
                                     joinedExistingChannel: joinedExistingChannel,
                                     tiles: stablePoints(channel)))
        }
        return diagnostics
    }

    private static func stablePathOrder(_ lhs: [GridPoint], _ rhs: [GridPoint]) -> Bool {
        if lhs.count != rhs.count { return lhs.count < rhs.count }
        for (a, b) in zip(lhs, rhs) where a != b {
            return a.y == b.y ? a.x < b.x : a.y < b.y
        }
        return false
    }

    private static func nonUphillPath(
        from source: GridPoint, isOutlet: (GridPoint) -> Bool,
        excluding: Set<GridPoint>, in map: WorldMap, maximumLength: Int
    ) -> [GridPoint]? {
        var queue = [source], previous: [GridPoint: GridPoint] = [:], seen: Set<GridPoint> = [source]
        var outlet: GridPoint?
        while !queue.isEmpty {
            let point = queue.removeFirst()
            var depth = 1
            var cursor = point
            while cursor != source, let parent = previous[cursor] {
                depth += 1
                cursor = parent
            }
            if point != source, isOutlet(point) { outlet = point; break }
            if depth >= maximumLength { continue }
            let next = map.neighbours(of: point)
                .filter { !excluding.contains($0) && !seen.contains($0)
                    && map[$0].elevation <= map[point].elevation }
                .sorted { a, b in
                    map[a].elevation == map[b].elevation
                        ? (a.y == b.y ? a.x < b.x : a.y < b.y)
                        : map[a].elevation < map[b].elevation
                }
            for candidate in next { seen.insert(candidate); previous[candidate] = point; queue.append(candidate) }
        }
        guard var cursor = outlet else { return nil }
        var path = [cursor]
        while cursor != source, let parent = previous[cursor] { cursor = parent; path.append(cursor) }
        return path.reversed()
    }

    /// A narrow, legible marsh edge where liquid water meets soil. Frozen hydrology makes ice,
    /// never mud; growth may later cover some of this, but only with an actual plant.
    private static func paintMud(_ map: inout WorldMap, freezing: Bool) {
        guard !freezing else { return }
        let wet = Set(map.allPoints.filter { map[$0].ground == .water || map[$0].ground == .deepWater })
        guard !wet.isEmpty else { return }
        let muddy = map.allPoints.filter { point in
            map[point].ground == .soil && map.neighbours(of: point).contains(where: wet.contains)
        }
        for point in muddy {
            map[point].ground = .mud
            map[point].baseGround = .mud
        }
    }

    // MARK: Growth — what the plants put on the ground

    /// **The piece the terrain system was missing** (`flora-system-spec.md` §5).
    ///
    /// `growth` was a ground type with **nothing producing it**: it was scattered per-tile straight
    /// off Vitality, so cover was a uniform porosity that had nothing to do with what grew here. Now
    /// the world's flora paints it, and three things follow that could not before:
    ///
    ///  - **Habit decides patterning.** *Spreading* makes large connected swathes, *clustered* makes
    ///    thickets with gaps, *solitary* makes scattered single tiles.
    ///  - **Stature decides whether it hides anything.** Groundcover doesn't break a sightline;
    ///    canopy does.
    ///  - **Every growth tile knows which plant is on it**, which is what lets the harvest, the
    ///    hazard and the description all read the same thing.
    ///
    /// The consequence worth naming: **openness as written by Relief is now modified by flora.** A
    /// world can be topographically open and still be a maze because it is overgrown, and that
    /// combination is a genuinely distinct place from either alone.
    private static func paintGrowth(_ map: inout WorldMap, life: PressureReading,
                                    flora: [Flora], rng: inout SeededRNG) {
        guard !flora.isEmpty else { return }
        let ground = map.allPoints.filter { map[$0].ground.isPassable && map[$0].ground != .water }
        guard !ground.isEmpty else { return }

        // Cover density is productivity, shaded by how tall the growth is: a canopy takes more of
        // the ground than a mat of the same abundance does.
        let productivity = life.peak / Tuning.Pressure.scaleMaximum
        let meanStature = flora.reduce(0) { $0 + $1.traits.stature } / Double(flora.count)
        let shading = Tuning.Terrain.coverageAtGroundLevel
            + Tuning.Terrain.coveragePerStature * (meanStature / Tuning.Pressure.scaleMaximum)
        let density = min(1, productivity * Tuning.Flora.maximumCoverage * shading)
        var budget = Int(Double(ground.count) * density)
        guard budget > 0 else { return }

        // Each kind takes its turn, so a world of four plants isn't three-quarters one of them.
        // Stable order so the same seed paints the same world.
        let kinds = flora.sorted { $0.id.rawValue < $1.id.rawValue }
        var index = 0
        while budget > 0 {
            let plant = kinds[index % kinds.count]
            index += 1
            // A patch, grown outward from one tile. How far it runs is the habit.
            guard var head = rng.pick(ground) else { return }
            let cover: GroundType = plant.traits.blocksSight ? .growth : .groundcover
            for _ in 0..<plant.traits.habit.patchLength {
                guard budget > 0 else { break }
                guard map.contains(head), map[head].ground.isPassable, map[head].ground != .water,
                      !map[head].ground.isOvergrown
                else {
                    head = rng.pick(map.neighbours(of: head)) ?? head
                    continue
                }
                map[head].ground = cover
                map[head].flora = plant.id
                budget -= 1
                head = rng.pick(map.neighbours(of: head)) ?? head
            }
            // A world with more budget than open ground would otherwise spin here.
            if index > kinds.count * Tuning.Terrain.maximumGrowthPatches { return }
        }
    }

    private static func paintSurfaceDeposits(
        _ map: inout WorldMap, sigils: [Sigil], visualSeed: UInt64
    ) {
        let eligible = stablePoints(map.allPoints.filter {
            ![.water, .deepWater, .chasm].contains(map[$0].baseGround)
        })
        let definitions: [(source: String, snow: Bool, salt: UInt64)] = [
            ("snow", true, 0x534E4F57),
            ("ash", false, 0x415348),
        ]
        for definition in definitions {
            let amplitude = sigils.filter { $0.source.rawValue == definition.source }
                .reduce(0) { $0 + PressureRules.resolvedSurfaceCoverageAmplitude($1) }
            let coverage = min(1, max(0, amplitude * Tuning.Terrain.surfaceDepositCoveragePerAmplitude))
            let target = min(eligible.count, Int((Double(eligible.count) * coverage).rounded()))
            var contributorRNG = SeededRNG(seed: visualSeed).derived(definition.salt)
            guard target > 0, let seed = contributorRNG.pick(eligible) else { continue }
            var patch: Set<GridPoint> = [seed]
            while patch.count < target {
                let frontier = Set(patch.flatMap { map.neighbours(of: $0) })
                    .intersection(eligible).subtracting(patch)
                if let point = contributorRNG.pick(stablePoints(frontier)) {
                    patch.insert(point)
                    continue
                }
                let remaining = eligible.filter { !patch.contains($0) }
                let distances = remaining.map { candidate in
                    patch.map { abs(candidate.x - $0.x) + abs(candidate.y - $0.y) }.min() ?? 0
                }
                let farthest = distances.max() ?? 0
                guard let next = contributorRNG.pick(stablePoints(zip(remaining, distances)
                    .compactMap { $0.1 == farthest ? $0.0 : nil })) else { break }
                patch.insert(next)
            }
            for point in stablePoints(patch) {
                if definition.snow { map[point].surfaceDeposits.snow = true }
                else { map[point].surfaceDeposits.settledAsh = true }
            }
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
