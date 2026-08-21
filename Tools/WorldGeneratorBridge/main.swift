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
    var elevation: Int
    var floraID: UInt64?
    var content: String
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
                elevation: tile.elevation, floraID: tile.flora?.rawValue,
                content: label(tile.content))
}
var resourceTotals: [String: (placements: Int, quantity: Int)] = [:]
for point in generated.map.allPoints {
    switch generated.map[point].content {
    case .node(let node):
        let id = node.resource.rawValue
        resourceTotals[id, default: (0, 0)].placements += 1
        resourceTotals[id, default: (0, 0)].quantity += node.remainingHarvests * node.yieldPerHarvest
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
let snapshot = Snapshot(
    seed: request.seed, width: generated.map.width, height: generated.map.height,
    entry: generated.map.entry, cells: cells, markers: markers,
    terrain: counts(cells.map(\.ground)), resources: resources,
    flora: counts(floraNames), mobs: counts(ordinaryMobNames), generatedCast: generatedCast,
    apexes: apexes, hostileFlora: hostileFlora, pointsOfInterest: counts(poi),
    writings: counts(writings), travellers: generated.travellers.map(\.rawValue).sorted(),
    diagnostics: Diagnostics(initialTurnBudget: d.initialTurnBudget,
                             projectedCollapseTurn: d.projectedCollapseTurn,
                             rawEssenceObtainable: d.rawEssenceObtainable,
                             creatureSpeciesCount: d.creatureSpeciesCount,
                             creatureInstancesPlaced: d.creatureInstancesPlaced,
                             floraSpeciesCount: d.floraSpeciesCount,
                             floraInstancesPlaced: d.floraInstancesPlaced,
                             activeFloraPlaced: d.activeFloraPlaced,
                             apexChance: d.apexChance, apexPlaced: d.apexPlaced),
    splash: nil
)
let encoder = JSONEncoder()
encoder.outputFormatting = [.sortedKeys]
FileHandle.standardOutput.write(try encoder.encode(snapshot))
