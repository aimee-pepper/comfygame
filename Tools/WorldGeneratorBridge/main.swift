import Foundation

struct Request: Decodable {
    var seed: UInt64
    var symbols: [String]
    var scale: String?
}

struct Cell: Encodable {
    var x: Int
    var y: Int
    var ground: String
    var baseGround: String
    var snow: Bool
    var settledAsh: Bool
    var elevation: Int
    var floraID: UInt64?
    var content: String
    var isRevealed: Bool
}

struct EntryEnvironment: Encodable {
    var illuminationPeak: Double
    var illuminationFloor: Double
    var suspendedMedium: String
    var suspendedDensity: Double
    var precipitation: String
    var precipitationIntensity: Double
    var atmosphereMotion: String
}

struct FloraVisual: Encodable {
    var stableID: String
    var formID: Int
    var stature: Double
    var habit: String
    var resolvedColor: [Int]
    var placements: Int
}

struct Count: Encodable {
    var id: String
    var quantity: Int
}

struct CastCount: Encodable {
    var id: String
    var name: String
    var placements: Int
}

struct ResourceCount: Encodable {
    var id: String
    var placements: Int
    var quantity: Int
}

struct Marker: Encodable {
    var x: Int
    var y: Int
    var kind: String
    var label: String
}

struct Diagnostics: Encodable {
    var terrainGenerationSucceeded: Bool
    var baseMaterialComponents: [Count]
    var visibleGroundComponents: [Count]
    var isolatedGroundCells: Int
    var elevationHistogram: [Count]
    var maximumCardinalElevationDelta: Int
    var surfaceWaterTiles: Int
    var frozenWaterTiles: Int
    var shallowLiquidBodies: Int
    var deepLiquidCores: Int
    var iceFields: Int
    var isolatedDeepViolations: Int
    var snowTiles: Int
    var settledAshTiles: Int
    var resourceHostViolations: [String]
    var resourceHosts: [ResourceHostDiagnostic]
    var initialTurnBudget: Int
    var projectedCollapseTurn: Int
    var rawEssenceObtainable: Int
    var creatureSpeciesCount: Int
    var creatureInstancesPlaced: Int
    var floraSpeciesCount: Int
    var floraInstancesPlaced: Int
    var activeFloraPlaced: Int
    var apexChance: Double
    var apexPlaced: Bool
}

struct ResourceHostDiagnostic: Encodable {
    var name: String
    var internalID: String
    var placementKind: String
    var hostRule: String
    var eligibleHosts: Int
    var reachableEligibleHosts: Int
    var extractionState: String
    var extractionRank: String
    var actualPlacements: Int
    var violations: Int
}

enum BridgeFailure: Error, CustomStringConvertible {
    case terrainGenerationFailed
    var description: String { "Terrain generation failed; no default-soil world was emitted." }
}

struct Snapshot: Encodable {
    var seed: UInt64
    var width: Int
    var height: Int
    var entry: GridPoint
    var cells: [Cell]
    var markers: [Marker]
    var terrain: [Count]
    var resources: [ResourceCount]
    var flora: [Count]
    var mobs: [Count]
    var generatedCast: [CastCount]
    var apexes: [Count]
    var hostileFlora: [Count]
    var pointsOfInterest: [Count]
    var writings: [Count]
    var travellers: [String]
    var diagnostics: Diagnostics
    var worldVisualReceipt: WorldVisualReceipt
    var entryEnvironment: EntryEnvironment
    var floraVisuals: [FloraVisual]
    var splash: String?
}

func label(_ content: TileContent) -> String {
    switch content {
    case .empty: "empty"
    case .node(let node): "resource:\(node.resource.rawValue)"
    case .wildDrop(let resource, let amount): "drop:\(resource.rawValue):\(amount)"
    case .item(let item): "item:\(item.catalogID.rawValue)"
    case .hazard: "hazard"
    case .portal(let isEntry): isEntry ? "portal:entry" : "portal:exit"
    case .lockedCache: "locked-cache"
    case .site(let id): "site:\(id.rawValue)"
    case .diaryPage(let id): "diary:\(id.rawValue)"
    case .foundWriting(let id): "writing:\(id.rawValue)"
    case .traveller(let id): "traveller:\(id.rawValue)"
    }
}

func counts(_ values: [String]) -> [Count] {
    Dictionary(grouping: values, by: { $0 }).map { Count(id: $0.key, quantity: $0.value.count) }
        .sorted { ($0.id, $0.quantity) < ($1.id, $1.quantity) }
}

let input = FileHandle.standardInput.readDataToEndOfFile()
let request = try JSONDecoder().decode(Request.self, from: input)
let scale = request.scale.flatMap(WorldScale.init(rawValue:)) ?? .ordinary
let book = BoundBook(written: request.symbols.map(SymbolID.init), scale: scale, essencePaid: 0)
let generated = Worldgen.generate(book: book, seed: request.seed)
let cells = generated.map.allPoints.map { point in
    let tile = generated.map[point]
    return Cell(x: point.x, y: point.y, ground: tile.ground.rawValue,
                baseGround: tile.baseGround.rawValue,
                snow: tile.surfaceDeposits.snow,
                settledAsh: tile.surfaceDeposits.settledAsh,
                elevation: tile.elevation, floraID: tile.flora?.rawValue,
                content: label(tile.content), isRevealed: tile.isRevealed)
}
var resourceTotals: [String: (placements: Int, quantity: Int)] = [:]
for point in generated.map.allPoints {
    switch generated.map[point].content {
    case .node(let node):
        let id = node.resource.rawValue
        resourceTotals[id, default: (0, 0)].placements += 1
        resourceTotals[id, default: (0, 0)].quantity += node.remainingHarvests * node.yieldPerHarvest
        if let secondary = node.secondaryResource {
            let secondaryID = secondary.rawValue
            resourceTotals[secondaryID, default: (0, 0)].placements += 1
            resourceTotals[secondaryID, default: (0, 0)].quantity +=
                node.remainingHarvests * node.secondaryYieldPerHarvest
        }
    case .wildDrop(let resource, let amount):
        let id = resource.rawValue
        resourceTotals[id, default: (0, 0)].placements += 1
        resourceTotals[id, default: (0, 0)].quantity += amount
    default: break
    }
}
let resources = resourceTotals.map {
    ResourceCount(id: $0.key, placements: $0.value.placements, quantity: $0.value.quantity)
}.sorted { $0.id < $1.id }
let floraNamesByID = Dictionary(uniqueKeysWithValues: generated.flora.map { ($0.id, $0.displayName) })
let floraNames = generated.map.tiles.compactMap { $0.flora }.compactMap { floraNamesByID[$0] }
let speciesNamesByID = Dictionary(uniqueKeysWithValues: generated.cast.map { ($0.id, $0.displayName) })
let ordinaryMobNames = generated.enemies.compactMap { enemy -> String? in
    if enemy.isApex || enemy.isSessile { return nil }
    if let speciesID = enemy.speciesID, let name = speciesNamesByID[speciesID] { return name }
    return "Creature"
}
let placementCountBySpecies = Dictionary(grouping: generated.enemies.filter { !$0.isApex && !$0.isSessile }
    .compactMap(\.speciesID), by: { $0 }).mapValues(\.count)
let generatedCast = generated.cast.map { species in
    CastCount(id: species.id.description, name: species.displayName,
              placements: placementCountBySpecies[species.id, default: 0])
}.sorted { ($0.name, $0.id) < ($1.name, $1.id) }
let apexes = counts(generated.enemies.filter(\.isApex).map { _ in "Apex" })
let hostileFlora = counts(generated.enemies.filter { $0.isSessile && !$0.isApex }.map { enemy in
    enemy.speciesID.flatMap { speciesNamesByID[$0] } ?? "Hostile flora"
})
let poi = cells.compactMap { cell -> String? in
    switch cell.content {
    case let value where value.hasPrefix("portal:"): return value
    case let value where value.hasPrefix("site:"): return "site"
    case "locked-cache": return "locked cache"
    case "hazard": return "hazard"
    default: return nil
    }
}
let writings = cells.compactMap { cell -> String? in
    if cell.content.hasPrefix("diary:") { return "diary page" }
    if cell.content.hasPrefix("writing:") { return "world note" }
    return nil
}
let markers = generated.enemies.map { enemy in
    Marker(x: enemy.position.x, y: enemy.position.y,
           kind: enemy.isApex ? "apex" : (enemy.isSessile ? "hostile-flora" : "mob"),
           label: enemy.isApex ? "Apex" : (enemy.speciesID.flatMap { speciesNamesByID[$0] } ?? "Creature"))
}
let d = generated.diagnostics
guard d.terrainGenerationSucceeded else { throw BridgeFailure.terrainGenerationFailed }
var remaining = Set(generated.map.allPoints)
var groundComponentCounts: [String: Int] = [:]
while let start = remaining.sorted(by: { ($0.y, $0.x) < ($1.y, $1.x) }).first {
    let ground = generated.map[start].baseGround.rawValue
    var queue = [start]
    remaining.remove(start)
    while let point = queue.popLast() {
        for next in generated.map.neighbours(of: point)
        where remaining.contains(next) && generated.map[next].baseGround.rawValue == ground {
            remaining.remove(next); queue.append(next)
        }
    }
    groundComponentCounts[ground, default: 0] += 1
}
let baseMaterialComponents = groundComponentCounts.map { Count(id: $0.key, quantity: $0.value) }
    .sorted { $0.id < $1.id }
var visibleRemaining = Set(generated.map.allPoints)
var visibleComponentCounts: [String: Int] = [:]
while let start = visibleRemaining.sorted(by: { ($0.y, $0.x) < ($1.y, $1.x) }).first {
    let ground = generated.map[start].ground.rawValue
    var queue = [start]
    visibleRemaining.remove(start)
    while let point = queue.popLast() {
        for next in generated.map.neighbours(of: point)
        where visibleRemaining.contains(next) && generated.map[next].ground.rawValue == ground {
            visibleRemaining.remove(next); queue.append(next)
        }
    }
    visibleComponentCounts[ground, default: 0] += 1
}
let visibleGroundComponents = visibleComponentCounts.map { Count(id: $0.key, quantity: $0.value) }
    .sorted { $0.id < $1.id }
let isolatedGroundCells = generated.map.allPoints.count { point in
    !generated.map.neighbours(of: point).contains {
        generated.map[$0].baseGround == generated.map[point].baseGround
    }
}
let elevationHistogram = counts(generated.map.tiles.map { String($0.elevation) })
let maximumCardinalElevationDelta = generated.map.allPoints.flatMap { point in
    generated.map.neighbours(of: point).map {
        abs(generated.map[point].elevation - generated.map[$0].elevation)
    }
}.max() ?? 0
let resourceHostViolations = generated.map.allPoints.compactMap { point -> String? in
    guard case .node(let node) = generated.map[point].content,
          !Worldgen.resourceHostAllows(node.resource, at: point, in: generated.map) else { return nil }
    let name = ContentCatalog.shared.resource(node.resource)?.name ?? "Unknown resource"
    return "\(name) [Internal ID: \(node.resource.rawValue)]"
}.sorted()
func components(in points: Set<GridPoint>) -> [Set<GridPoint>] {
    var remaining = points, result: [Set<GridPoint>] = []
    while let start = remaining.sorted(by: { ($0.y, $0.x) < ($1.y, $1.x) }).first {
        var body: Set<GridPoint> = [start], queue = [start]
        remaining.remove(start)
        while let point = queue.popLast() {
            for next in generated.map.neighbours(of: point) where remaining.remove(next) != nil {
                body.insert(next); queue.append(next)
            }
        }
        result.append(body)
    }
    return result
}
let liquid = Set(generated.map.allPoints.filter {
    generated.map[$0].baseGround == .water || generated.map[$0].baseGround == .deepWater
})
let liquidBodies = components(in: liquid)
let deepLiquidCores = liquidBodies.reduce(0) { count, body in
    count + components(in: Set(body.filter { generated.map[$0].baseGround == .deepWater })).count
}
let isolatedDeepViolations = liquidBodies.reduce(0) { count, body in
    let deep = Set(body.filter { generated.map[$0].baseGround == .deepWater })
    let isolated = deep.count { point in !generated.map.neighbours(of: point).contains(where: body.contains) }
    return count + isolated
}
let reachable = TerrainRules.reachable(from: generated.map.entry, in: generated.map)
let generatedFloraByID = Dictionary(uniqueKeysWithValues: generated.flora.map { ($0.id, $0) })
let authorityData = try Data(contentsOf: URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("docs/world-terrain-resource-host-authority.json"))
let authority = try JSONSerialization.jsonObject(with: authorityData) as! [String: Any]
let hostRows = authority["resourceHosts"] as! [[String: Any]]
let resourceHosts = hostRows.map { row -> ResourceHostDiagnostic in
    let id = ResourceID(rawValue: row["resourceID"] as! String)
    let kind = row["placementKind"] as! String
    let eligible: Set<GridPoint>
    switch kind {
    case "mineralNode":
        eligible = Set(generated.map.allPoints.filter {
            generated.map[$0].isPassable && Worldgen.resourceHostAllows(id, at: $0, in: generated.map)
        })
    case "floraPrimary":
        eligible = Set(generated.map.allPoints.filter { point in
            generated.map[point].flora.flatMap { generatedFloraByID[$0] }.map {
                FloraRules.yield(of: $0.traits) == id
            } ?? false
        })
    case "floraSecondary":
        eligible = Set(generated.map.allPoints.filter { point in
            generated.map[point].flora.flatMap { generatedFloraByID[$0] }.map {
                FloraRules.yieldsSecondaryResin($0.traits)
            } ?? false
        })
    case "directPickup":
        eligible = Set(generated.map.allPoints.filter {
            reachable.contains($0) && generated.map[$0].isPassable
                && generated.map[$0].content == .empty
        })
    default: eligible = []
    }
    let placementLabel: String = switch kind {
    case "mineralNode": "Mineral deposit"
    case "floraPrimary": "Primary flora yield"
    case "floraSecondary": "Secondary flora yield"
    case "creatureMaterialOnly": "Creature material only"
    case "directPickup": "Direct world pickup"
    case "realityAwardOnly": "Existing cache or Mythic award only"
    default: "Unknown placement"
    }
    let rawHostRule = (row["floraRule"] as? String) ?? (row["hostRule"] as? String)
    let hostRule: String = switch rawHostRule {
    case "fibrousOrShortWoody": "Fibrous or short woody flora"
    case "tallWoody": "Tall woody flora"
    case "fleshy": "Fleshy flora"
    case "defendedPhotosyntheticWoody": "Defended photosynthetic woody flora"
    case "chemicalDefence": "Flora with chemical defences"
    case "fungalMetabolism": "Fungal flora"
    case "chemosyntheticMetabolism": "Chemosynthetic flora"
    case "reachablePassableEmpty": "Reachable, passable, empty ground"
    case "existingCacheAndMythicAwards": "Existing cache and Mythic award paths"
    case nil where (row["clauses"] as? [[String: Any]])?.isEmpty == false: "Exact terrain-host clauses"
    default: "No terrain host"
    }
    let actual = resourceTotals[id.rawValue]?.placements ?? 0
    let violationCount = generated.map.allPoints.reduce(0) { count, point in
        guard case .node(let node) = generated.map[point].content else { return count }
        if kind == "floraSecondary", node.secondaryResource == id {
            return count + (eligible.contains(point) && node.secondaryYieldPerHarvest == 1 ? 0 : 1)
        }
        guard node.resource == id else { return count }
        if kind == "mineralNode" || kind == "floraPrimary" {
            return count + (eligible.contains(point) ? 0 : 1)
        }
        return count + 1
    }
    return .init(name: ContentCatalog.shared.resource(id)?.name ?? "Unknown resource",
                 internalID: id.rawValue, placementKind: placementLabel, hostRule: hostRule,
                 eligibleHosts: eligible.count, reachableEligibleHosts: eligible.intersection(reachable).count,
                 extractionState: "Current harvest rules", extractionRank: "No rank gate is live",
                 actualPlacements: actual, violations: violationCount)
}.sorted { ($0.name, $0.internalID) < ($1.name, $1.internalID) }
let visualReceipt = try WorldGrade2BindAdapter.makeReceipt(
    book: book, mapSeed: request.seed, map: generated.map, flora: generated.flora)
let illumination = BookRules.readings(for: book, seed: request.seed)["illumination"]
let floraDescriptorByID = Dictionary(uniqueKeysWithValues:
    visualReceipt.descriptor.flora.cast.map { ($0.speciesID, $0) })
let floraVisuals = generated.flora.compactMap { flora -> FloraVisual? in
    let key = "flora-\(flora.id.rawValue)"
    guard let descriptor = floraDescriptorByID[key] else { return nil }
    return FloraVisual(stableID: key, formID: descriptor.formID,
                       stature: descriptor.stature, habit: flora.traits.habit.rawValue,
                       resolvedColor: descriptor.resolvedColor.srgb,
                       placements: generated.map.tiles.count { $0.flora == flora.id })
}.sorted { $0.stableID < $1.stableID }
let snapshot = Snapshot(
    seed: request.seed, width: generated.map.width, height: generated.map.height,
    entry: generated.map.entry, cells: cells, markers: markers,
    terrain: counts(cells.map(\.ground)), resources: resources,
    flora: counts(floraNames), mobs: counts(ordinaryMobNames), generatedCast: generatedCast,
    apexes: apexes, hostileFlora: hostileFlora, pointsOfInterest: counts(poi),
    writings: counts(writings), travellers: generated.travellers.map(\.rawValue).sorted(),
    diagnostics: Diagnostics(terrainGenerationSucceeded: d.terrainGenerationSucceeded,
                             baseMaterialComponents: baseMaterialComponents,
                             visibleGroundComponents: visibleGroundComponents,
                             isolatedGroundCells: isolatedGroundCells,
                             elevationHistogram: elevationHistogram,
                             maximumCardinalElevationDelta: maximumCardinalElevationDelta,
                             surfaceWaterTiles: generated.map.tiles.count {
                                $0.baseGround == .water || $0.baseGround == .deepWater },
                             frozenWaterTiles: generated.map.tiles.count { $0.baseGround == .ice },
                             shallowLiquidBodies: liquidBodies.count,
                             deepLiquidCores: deepLiquidCores,
                             iceFields: components(in: Set(generated.map.allPoints.filter {
                                generated.map[$0].baseGround == .ice })).count,
                             isolatedDeepViolations: isolatedDeepViolations,
                             snowTiles: generated.map.tiles.count { $0.surfaceDeposits.snow },
                             settledAshTiles: generated.map.tiles.count { $0.surfaceDeposits.settledAsh },
                             resourceHostViolations: resourceHostViolations,
                             resourceHosts: resourceHosts,
                             initialTurnBudget: d.initialTurnBudget,
                             projectedCollapseTurn: d.projectedCollapseTurn,
                             rawEssenceObtainable: d.rawEssenceObtainable,
                             creatureSpeciesCount: d.creatureSpeciesCount,
                             creatureInstancesPlaced: d.creatureInstancesPlaced,
                             floraSpeciesCount: d.floraSpeciesCount,
                             floraInstancesPlaced: d.floraInstancesPlaced,
                             activeFloraPlaced: d.activeFloraPlaced,
                             apexChance: d.apexChance, apexPlaced: d.apexPlaced),
    worldVisualReceipt: visualReceipt,
    entryEnvironment: EntryEnvironment(
        illuminationPeak: illumination.peak, illuminationFloor: illumination.floor,
        suspendedMedium: visualReceipt.descriptor.atmosphere.medium,
        suspendedDensity: visualReceipt.descriptor.atmosphere.density,
        precipitation: "none", precipitationIntensity: 0, atmosphereMotion: "calm"),
    floraVisuals: floraVisuals,
    splash: nil
)
let encoder = JSONEncoder()
encoder.outputFormatting = [.sortedKeys]
FileHandle.standardOutput.write(try encoder.encode(snapshot))
