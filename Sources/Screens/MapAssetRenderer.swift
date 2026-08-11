import SwiftUI
import UIKit

/// Native, deterministic adapter for AssetLab's frozen lifted-terrain conformance pack.
/// The game supplies facts; this layer turns them into bottom-anchored 16×19 pixel sprites while
/// the map retains its logical 16×16 footprint.
enum MapAssetContract {
    static let manifestSHA256 = "fdfe2744af523628dc7aacac3c5a901d2fbd499a02cdb205a76d21e9f3d3f399"
    static let seedVersion = "bookbinder-terrain-seed-v1"
    /// Placement variation was frozen with map-slice v1.1. The lifted compositor changes pixels,
    /// not the persisted world's neutral feature choice.
    static let seedTuple = "1|1|1|1|world-grade-1.0.0|map-slice-1.1.0|rect-compositor-0.2.0|top-down-map-16px-1.0.0"
    static let rendererTuple = "1|lifted-terrain-adapter-1.0.0|terrain-lifted-1.0.0|world-grade-1.0.0|terrain-16x19-bottom-anchored-1.0.0"
    static let spriteWidth = 16
    static let spriteHeight = 19
    static let logicalSide = 16
    static let maximumElevation = 3

    static func resolvedElevation(for tile: Tile) -> Int {
        guard tile.isRevealed, !tile.isCrumbled,
              ![.water, .deepWater, .chasm, .ice, .growth, .groundcover].contains(tile.ground)
        else { return 0 }
        return min(maximumElevation, max(0, tile.elevation))
    }

    static func southExposure(center: Tile, south: Tile?) -> Int {
        guard let south, south.isRevealed else { return 0 }
        return max(0, resolvedElevation(for: center) - resolvedElevation(for: south))
    }

    static func terrainSeed(mapSeed: UInt64, point: GridPoint) -> UInt32 {
        let input = "\(seedVersion)|\(mapSeed)|\(point.x)|\(point.y)|\(seedTuple)"
        return input.utf8.reduce(UInt32(0x811c9dc5)) { hash, byte in
            (hash ^ UInt32(byte)) &* 0x01000193
        }
    }
}

struct WorldGrade: Equatable, Sendable {
    var red: Int
    var green: Int
    var blue: Int
    var value: Int

    static func from(_ readings: PressureReadings) -> WorldGrade {
        func center(_ x: Double) -> Double { min(1, max(-1, (x - 50) / 50)) }
        func midpoint(_ id: PressureTargetID) -> Double {
            let r = readings[id]
            return (r.peak + r.floor) / 2
        }
        func away(_ x: Double, _ range: ClosedRange<Int>) -> Int {
            let bounded = min(Double(range.upperBound), max(Double(range.lowerBound), x))
            return Int(bounded.rounded(.toNearestOrAwayFromZero))
        }
        let warmth = center(midpoint("thermal"))
        let wetness = center(readings["hydrology"].availableMagnitude)
        let life = center(readings["vitality"].peak)
        let light = center(midpoint("illumination"))
        let mineral = center(readings["substrate"].peak)
        return WorldGrade(red: away(24 * warmth + 8 * mineral, -32...32),
                          green: away(22 * life + 8 * wetness, -32...32),
                          blue: away(20 * wetness - 8 * warmth, -32...32),
                          value: away(16 * light + 4 * mineral, -20...20))
    }
}

struct MapTileArtRequest {
    let tile: Tile
    let point: GridPoint
    let mapSeed: UInt64
    let runIndex: Int
    let adjacency: Int
    let southExposureLevels: Int
    let grade: WorldGrade
    let flora: Flora?
    let explicitSeed: UInt32?
    let explicitFeatureVariant: Int?

    init(tile: Tile, point: GridPoint, mapSeed: UInt64, runIndex: Int = 0, adjacency: Int,
         southExposureLevels: Int = 0, grade: WorldGrade,
         flora: Flora?, explicitSeed: UInt32? = nil) {
        self.tile = tile; self.point = point; self.mapSeed = mapSeed; self.runIndex = runIndex; self.adjacency = adjacency
        self.southExposureLevels = southExposureLevels
        self.grade = grade; self.flora = flora; self.explicitSeed = explicitSeed
        self.explicitFeatureVariant = nil
    }

    init(tile: Tile, point: GridPoint, mapSeed: UInt64, runIndex: Int = 0, adjacency: Int,
         southExposureLevels: Int = 0, grade: WorldGrade,
         flora: Flora?, explicitSeed: UInt32, explicitFeatureVariant: Int) {
        self.tile=tile; self.point=point; self.mapSeed=mapSeed; self.runIndex=runIndex; self.adjacency=adjacency
        self.southExposureLevels=southExposureLevels
        self.grade=grade; self.flora=flora; self.explicitSeed=explicitSeed
        self.explicitFeatureVariant=explicitFeatureVariant
    }

    var seed: UInt32 { explicitSeed ?? MapAssetContract.terrainSeed(mapSeed: mapSeed, point: point) }
    var featureVariant: Int { explicitFeatureVariant ?? Int(seed & 3) }
    var resolvedElevation: Int { MapAssetContract.resolvedElevation(for: tile) }
    var surfaceOffsetY: Int { MapAssetContract.maximumElevation - resolvedElevation }
}

@MainActor enum MapAssetTestSupport {
    static func terrainPixels(ground: GroundType, adjacency: Int = 15, featureVariant: Int = 0,
                              grade: WorldGrade = WorldGrade(red: 0, green: 0, blue: 0, value: 0),
                              elevation: Int = 0, crumbled: Bool = false,
                              cracking: Bool = false, revealed: Bool = true,
                              southExposureLevels: Int = 0,
                              seed: UInt32 = 404) -> [UInt8] {
        var tile = Tile(ground: ground, elevation: elevation, isRevealed: revealed, isCrumbled: crumbled)
        tile.isCracking = cracking
        let request = MapTileArtRequest(tile: tile, point: GridPoint(x: 0, y: 0), mapSeed: 0,
                                        adjacency: adjacency, southExposureLevels: southExposureLevels,
                                        grade: grade, flora: nil,
                                        explicitSeed: seed, explicitFeatureVariant: featureVariant)
        return MapPixelRaster.rawPixels(commands: TerrainPixelGrammar.commands(for: request),
                                        width: MapAssetContract.spriteWidth,
                                        height: MapAssetContract.spriteHeight)
    }

    static func floraPixels(_ flora: Flora) -> [UInt8] {
        MapPixelRaster.rawPixels(commands: FloraPixelGrammar.commands(for: FloraRenderDescriptor(flora)))
    }

    static func floraCacheKey(_ flora: Flora) -> String {
        MapPixelRaster.stableFloraKey(FloraRenderDescriptor(flora))
    }

    static func resourcePixels(_ id: ResourceID, frame: Int? = nil) -> [UInt8] {
        let body = ResourcePixelGrammar.bodyCommands(for: id)
        let sheen = frame.map { ResourcePixelGrammar.sheenCommands(body: body, frame: $0) } ?? []
        return MapPixelRaster.rawPixels(commands: body + sheen)
    }

    static func inventoryResourcePixels(_ id: ResourceID) -> [UInt8] {
        MapPixelRaster.rawPixels(commands: ResourcePixelGrammar.inventoryCommands(for: id))
    }

    static func resourceSheenPhase(mapSeed: UInt64, runIndex: Int, point: GridPoint) -> UInt32 {
        ResourcePixelGrammar.phase(mapSeed: mapSeed, runIndex: runIndex, point: point)
    }

    static func resourceSheenFrame(phase: UInt32, tick: Int) -> Int? {
        ResourcePixelGrammar.frame(phase: phase, tick: tick)
    }
}

/// The accepted Resource v0.6 identity without map substrate or animated sheen.
/// Inventory and merchant grids use this same raster grammar as world nodes.
struct ResourcePixelIdentity: View {
    let id: ResourceID
    let fallbackSystemIcon: String

    var body: some View {
        if let image = MapPixelRaster.resourceIdentityImage(for: id) {
            Image(uiImage: image)
                .resizable()
                .interpolation(.none)
                .antialiased(false)
                .accessibilityHidden(true)
        } else {
            Image(systemName: fallbackSystemIcon)
                .accessibilityHidden(true)
        }
    }
}

struct MapTileArt: View {
    let request: MapTileArtRequest
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if request.resourceID == nil {
            image(tick: 0)
        } else {
            TimelineView(.periodic(from: .now, by: 0.36)) { context in
                image(tick: Int(context.date.timeIntervalSinceReferenceDate / 0.36))
            }
        }
    }

    @ViewBuilder private func image(tick: Int) -> some View {
        if let image = MapPixelRaster.image(for: request, tick: tick, reduceMotion: reduceMotion) {
            Image(uiImage: image).resizable().interpolation(.none).accessibilityHidden(true)
        }
    }
}

private extension MapTileArtRequest {
    var resourceID: ResourceID? {
        switch tile.content {
        case .node(let node) where node.remainingHarvests > 0: node.resource
        case .wildDrop(let resource, let amount) where amount > 0: resource
        default: nil
        }
    }
}

struct PixelCommand: Equatable {
    var x: Int
    var y: Int
    var width: Int
    var height: Int
    var color: RGBA
}

private enum TerrainPixelGrammar {
    static func commands(for request: MapTileArtRequest) -> [PixelCommand] {
        let tile = request.tile
        let palette = palette(for: tile.ground).map { $0.graded(request.grade) }
        if !tile.isRevealed {
            return [rect(0, MapAssetContract.maximumElevation, 16, 16, 0x17171a)]
        }
        if tile.isCrumbled {
            return [rect(0, 3, 16, 16, 0x09090c), rect(0, 3, 4, 2, palette[0]),
                    rect(12, 17, 4, 2, palette[2])]
        }
        var random = Mulberry32(seed: request.seed ^ UInt32(request.adjacency) ^ UInt32(request.featureVariant &* 0x9e37))
        var result = [rect(0, 0, 16, 16, palette[1])]
        for _ in 0..<14 {
            let width = [.water, .deepWater, .ice].contains(tile.ground) ? 2 : 1
            result.append(rect(Int(random.next() * 16), Int(random.next() * 16), width, 1,
                               random.next() > 0.5 ? palette[0] : palette[2]))
        }
        texture(tile.ground, palette, into: &result)
        feature(tile.ground, request.featureVariant, palette, into: &result)
        if [.water, .deepWater, .ice, .chasm].contains(tile.ground) {
            let edge = edgeColour(tile.ground).graded(request.grade)
            if request.adjacency & 1 == 0 { result.append(rect(0, 0, 16, 2, edge)) }
            if request.adjacency & 2 == 0 { result.append(rect(14, 0, 2, 16, edge)) }
            if request.adjacency & 4 == 0 { result.append(rect(0, 14, 16, 2, edge)) }
            if request.adjacency & 8 == 0 { result.append(rect(0, 0, 2, 16, edge)) }
        }
        if tile.isCracking {
            result += line(7, 1, 9, 7, 0x171116) + line(9, 7, 5, 14, 0x171116)
                + line(8, 1, 10, 7, 0xf0a84e) + line(10, 7, 6, 14, 0xf0a84e)
        }
        let elevation = MapAssetContract.resolvedElevation(for: tile)
        let offset = MapAssetContract.maximumElevation - elevation
        result = fit(result, width: 16, height: 16, padding: 0).map {
            PixelCommand(x: $0.x, y: $0.y + offset, width: $0.width, height: $0.height,
                         color: $0.color)
        }
        let exposure = min(elevation, max(0, request.southExposureLevels))
        if exposure > 0 {
            let wallY = offset + 16
            result.append(rect(0, wallY, 16, exposure, palette[0]))
            result.append(rect(0, wallY, 16, 1, palette[1]))
            if exposure == 3 { result.append(rect(0, wallY + 2, 16, 1, palette[0])) }
        }
        return result
    }

    private static func palette(for ground: GroundType) -> [RGB] {
        switch ground {
        case .stone: [0x34383b, 0x5b6264, 0x879092]
        case .soil: [0x493827, 0x684b31, 0x88633e]
        case .sand: [0x80683d, 0xb99a58, 0xdbc37c]
        case .ice: [0x7895a6, 0xabc7d2, 0xe3f1ef]
        case .ash: [0x29292b, 0x49474a, 0x777276]
        case .water: [0x17384d, 0x245c73, 0x3b8190]
        case .deepWater: [0x091e31, 0x12344e, 0x245571]
        case .rubble: [0x3c3732, 0x625951, 0x91877d]
        case .mud: [0x2d2118, 0x4f3926, 0x765536]
        case .growth: [0x19361f, 0x31552f, 0x5f7b45]
        case .chasm: [0x05060a, 0x0d1018, 0x292c3c]
        case .groundcover: [0x3c542d, 0x657b3d, 0x92a85c]
        }
    }

    private static func edgeColour(_ ground: GroundType) -> RGB {
        switch ground { case .water: 0x8fc4cc; case .deepWater: 0x2e6681; case .ice: 0xd9eef2; default: 0x55566a }
    }

    private static func texture(_ ground: GroundType, _ p: [RGB], into c: inout [PixelCommand]) {
        switch ground {
        case .stone: c += line(1, 5, 6, 7, p[0]) + line(10, 1, 8, 5, p[2])
        case .sand: c += line(1, 5, 7, 4, p[2]) + line(9, 11, 15, 10, p[0])
        case .ice: c += line(3, 13, 8, 4, p[2]) + line(8, 4, 12, 2, p[2])
        case .ash: for x in stride(from: 1, to: 16, by: 4) { c.append(rect(x, 12 - x % 5, 2, 1, p[0])) }
        case .rubble: for (x, y) in [(1,2),(9,1),(5,9),(12,11)] { c += [rect(x,y,3,2,p[2]), rect(x+1,y+2,2,1,p[0])] }
        case .mud: c += [rect(2,4,5,2,p[0]),rect(9,10,5,2,p[0]),rect(4,5,2,1,p[2]),rect(11,11,2,1,p[2])]
        case .growth: for x in stride(from: 1, to: 16, by: 3) { c += line(x,15,x+(x%2 == 1 ? 2 : -1),4+x%4,p[2]) }
        case .groundcover: for x in stride(from: 1, to: 16, by: 3) { c += [rect(x,9+x%3,2,2,p[2]),rect(x+1,12,1,3,p[0])] }
        case .chasm: c += [rect(3,3,10,10,p[0]),rect(6,1,4,14,0x020205)]
        default: break
        }
    }

    private static func feature(_ ground: GroundType, _ variant: Int, _ p: [RGB], into c: inout [PixelCommand]) {
        guard variant > 0 else { return }
        let patterns: [[(Int,Int,Int,Int)]] = switch ground {
        case .stone: [[(2,3,5,1),(9,10,5,1)],[(2,2,1,5),(8,1,1,7),(13,8,1,6)],[(3,3,3,2),(10,9,2,3)]]
        case .soil: [[(2,3,2,1),(11,8,2,1)],[(3,1,1,8),(10,6,1,9)],[(1,4,13,1),(2,10,12,1)]]
        case .sand: [[(1,4,6,1),(8,10,7,1)],[(3,3,9,2),(6,9,8,2)],[(2,2,2,1),(11,5,2,1),(6,12,2,1)]]
        case .ice: [[(2,2,1,5),(3,6,5,1)],[(3,4,3,2),(10,9,2,2)],[(1,3,12,1),(4,9,11,1)]]
        case .ash: [[(1,5,7,2),(9,10,6,2)],[(3,3,2,2),(11,8,2,2)],[(2,2,12,2),(5,9,9,2)]]
        case .water: [[(1,4,7,1),(8,11,7,1)],[(3,3,3,1),(10,8,3,1)],[(2,2,1,5),(13,9,1,5)]]
        case .deepWater: [[(0,5,12,1),(5,11,11,1)],[(4,4,7,4)],[(2,3,4,1),(10,10,4,1)]]
        case .rubble: [[(2,2,4,3),(10,9,4,3)],[(1,4,6,4),(9,2,5,5)],[(3,3,2,1),(7,8,3,2),(12,12,2,1)]]
        case .mud: [[(2,3,6,3),(9,10,5,3)],[(3,3,2,4),(10,8,2,5)],[(1,5,14,1),(3,11,11,1)]]
        case .growth: [[(2,2,1,11),(7,4,1,10),(12,1,1,12)],[(2,4,4,3),(9,9,5,3)],[(1,3,13,2),(3,9,12,2)]]
        case .chasm: [[(1,2,5,2),(10,11,5,2)],[(2,1,2,6),(12,8,2,7)],[(1,4,14,1),(4,11,11,1)]]
        case .groundcover: [[(2,3,3,2),(10,8,3,2)],[(3,4,1,1),(8,7,1,1),(12,3,1,1)],[(1,5,14,2),(4,11,10,2)]]
        }
        for (x,y,w,h) in patterns[variant-1] { c.append(rect(x, y, w, h, variant == 2 ? p[2] : p[0])) }
    }

}

/// Exact native port of AssetLab Resource v0.6's static identity bodies and sheen v1.1.
/// Material accents are intentionally not world-graded: terrain owns atmosphere; these pixels own
/// the promise that copper still looks like copper and gold still looks like gold.
private enum ResourcePixelGrammar {
    private enum Tone: Hashable { case dark, body, light, accent }
    private struct Part { let x,y,w,h: Int; let tone: Tone }
    private static let stone: [Tone: RGB] = [.dark: 0x36383b, .body: 0x686d70, .light: 0xaeb3b1]
    private static let flora: [Tone: RGB] = [.dark: 0x263c28, .body: 0x53704c, .light: 0x92a963]
    private static let unstable: [Tone: RGB] = [.dark: 0x25222d, .body: 0x514b60, .light: 0x8d819e]
    private static let floraIDs: Set<ResourceID> = ["fiber","timber","pulp","toxin","spore","reagent"]
    private static let accents: [ResourceID: RGB] = [
        "rubble":0x8b8175,"clay":0xb87350,"ore":0x9b5b3c,"copper":0xb86f4b,
        "silver":0xd8d9d4,"gold":0xe1ad43,"quartz":0xd9cae3,"obsidian":0x352c43,
        "salt":0xeee8db,"sulfur":0xdbcf43,"mercury":0xcbd4d5,"adamant":0x63aaa5,
        "resin":0xd39442,"ichor":0x87506f,"rift_glass":0x82c2c7,"essence_raw":0x8c82ca
    ]

    static func bodyCommands(for id: ResourceID) -> [PixelCommand] {
        if id == "mote" { return [] }
        if id == "essence_raw" {
            return [rect(5,8,6,4,0x171614), rect(6,6,4,5,0x83b86b), rect(9,5,2,2,0xf4ead7)]
        }
        let palette = id == "rift_glass" ? unstable : (floraIDs.contains(id) ? flora : stone)
        let accent = accents[id] ?? palette[.light]!
        return parts(for: id).map { part in
            let colour = part.tone == .accent ? accent : palette[part.tone]!
            return rect(part.x, part.y, part.w, part.h, colour)
        }
    }

    static func inventoryCommands(for id: ResourceID) -> [PixelCommand] {
        switch id.rawValue {
        case "essence_raw":
            return [rect(6,2,4,5,0xeee5d5), rect(4,6,8,8,0x8c82ca), rect(7,4,2,3,0xc6bff0)]
        case "mote":
            return [rect(3,3,10,10,0xd5a84f), rect(5,5,6,6,0x171614), rect(7,2,2,12,0xeee5d5)]
        default:
            return bodyCommands(for: id)
        }
    }

    static func phase(mapSeed: UInt64, runIndex: Int, point: GridPoint) -> UInt32 {
        let payload = "resource-sheen-1.1.0|\(mapSeed)|\(runIndex)|\(point.x)|\(point.y)"
        return payload.utf8.reduce(UInt32(0x811c9dc5)) { ($0 ^ UInt32($1)) &* 0x01000193 }
    }

    static func frame(phase: UInt32, tick: Int) -> Int? {
        let cycle = (Int(phase % 8) + tick % 8) % 8
        return cycle >= 2 && cycle < 6 ? cycle - 2 : nil
    }

    static func sheenCommands(body: [PixelCommand], frame: Int) -> [PixelCommand] {
        guard !body.isEmpty, (0..<4).contains(frame) else { return [] }
        var occupied = Set<GridPoint>()
        for command in body {
            for y in command.y..<(command.y + command.height) where (0..<16).contains(y) {
                for x in command.x..<(command.x + command.width) where (0..<16).contains(x) {
                    occupied.insert(GridPoint(x: x, y: y))
                }
            }
        }
        let pixels = occupied.sorted { $0.y == $1.y ? $0.x < $1.x : $0.y < $1.y }
        guard !pixels.isEmpty else { return [] }
        let sweep = pixels.filter { ($0.x + $0.y - frame * 3 + 32) % 7 == 0 }.prefix(4)
        let selected = sweep.isEmpty ? [pixels[(frame * 5) % pixels.count]] : Array(sweep)
        return selected.map { rect($0.x, $0.y, 1, 1, 0xfff4cf) }
    }

    private static func p(_ x:Int,_ y:Int,_ w:Int,_ h:Int,_ tone:Tone)->Part { Part(x:x,y:y,w:w,h:h,tone:tone) }
    private static func parts(for id: ResourceID) -> [Part] {
        switch id.rawValue {
        case "rubble": [p(1,10,5,4,.dark),p(5,7,5,7,.body),p(10,9,5,5,.dark),p(3,6,3,3,.light),p(10,5,3,4,.accent)]
        case "clay": [p(2,10,12,4,.dark),p(3,8,10,4,.accent),p(5,6,7,3,.body),p(7,5,4,2,.light)]
        case "ore": [p(2,8,4,6,.dark),p(5,5,7,9,.body),p(11,7,3,7,.dark),p(4,6,3,2,.accent),p(8,8,3,3,.accent),p(10,5,2,2,.light)]
        case "copper": [p(3,3,3,11,.accent),p(6,5,5,3,.accent),p(9,3,3,4,.body),p(6,10,6,3,.accent),p(11,9,3,5,.light),p(2,12,5,2,.dark)]
        case "silver": [p(2,5,3,3,.light),p(4,7,8,2,.accent),p(9,4,2,4,.light),p(11,7,3,5,.accent),p(6,9,2,5,.light),p(3,12,4,2,.body)]
        case "gold": [p(2,10,5,4,.accent),p(7,8,4,5,.light),p(11,11,4,3,.accent),p(5,5,4,3,.accent),p(9,5,3,2,.light)]
        case "quartz": [p(3,9,4,5,.body),p(6,3,4,11,.accent),p(10,7,4,7,.body),p(7,2,2,3,.light),p(11,6,2,3,.light)]
        case "obsidian": [p(2,10,4,4,.dark),p(5,5,3,9,.accent),p(8,2,3,12,.dark),p(11,7,3,7,.accent),p(8,3,1,7,.light)]
        case "salt": [p(2,9,5,5,.accent),p(6,4,5,5,.light),p(10,9,4,5,.body),p(3,10,2,2,.light),p(7,5,2,2,.body),p(11,10,2,2,.light)]
        case "sulfur": [p(2,11,12,3,.body),p(3,7,4,4,.accent),p(7,5,4,6,.light),p(11,8,3,3,.accent),p(8,3,2,3,.accent)]
        case "mercury": [p(1,10,14,4,.dark),p(2,9,11,4,.accent),p(5,7,7,4,.accent),p(10,6,3,3,.light),p(3,11,3,2,.body),p(13,8,2,2,.light)]
        case "adamant": [p(4,3,8,2,.accent),p(2,5,12,7,.body),p(4,12,8,2,.dark),p(4,6,2,5,.accent),p(10,6,2,5,.accent),p(6,5,4,2,.light),p(6,10,4,2,.dark)]
        case "fiber": [p(3,3,2,11,.light),p(6,2,2,12,.body),p(9,3,2,11,.light),p(12,4,2,10,.body),p(2,8,13,2,.accent)]
        case "timber": [p(1,6,12,7,.dark),p(2,7,11,5,.body),p(12,7,3,5,.accent),p(13,8,1,3,.light),p(4,8,2,2,.accent),p(7,8,2,2,.dark)]
        case "pulp": [p(2,10,12,3,.body),p(3,7,11,3,.light),p(4,4,9,3,.accent),p(11,3,3,2,.light),p(2,12,3,2,.dark)]
        case "resin": [p(7,2,3,3,.light),p(6,4,5,6,.accent),p(4,9,9,4,.body),p(6,12,5,2,.dark),p(8,5,1,3,.light)]
        case "toxin": [p(5,5,7,7,.body),p(7,3,3,3,.accent),p(3,7,3,3,.dark),p(11,7,3,3,.dark),p(7,8,3,3,.light),p(8,12,2,2,.accent)]
        case "spore": [p(2,10,4,4,.body),p(6,5,3,3,.light),p(11,9,4,4,.accent),p(9,3,2,2,.body),p(5,12,2,2,.light),p(12,5,2,2,.light)]
        case "reagent": [p(3,11,11,3,.dark),p(7,4,2,8,.body),p(3,6,5,3,.light),p(8,7,5,3,.accent),p(10,3,3,4,.light),p(5,10,3,3,.accent)]
        case "ichor": [p(1,11,14,3,.dark),p(3,8,9,4,.accent),p(10,6,3,4,.body),p(5,5,2,4,.accent),p(11,4,2,3,.light)]
        case "rift_glass": [p(2,6,4,8,.accent),p(4,3,3,9,.light),p(10,3,4,11,.accent),p(8,10,3,4,.dark),p(11,4,1,6,.light)]
        default: []
        }
    }
}

fileprivate struct FloraRenderDescriptor: Codable, Equatable {
    let logicalID: String
    let speciesSeed: UInt32
    let stature, tissueAmount, woody, fibrous, fleshy, defence: Int
    let defenceType: DefenceType
    let habit: Habit
    let cyan, magenta, yellow, colorDepth, patterning, opacity, shine, schiller: Int
    let metabolism: Metabolism

    init(_ flora: Flora) {
        func percent(_ value: Double) -> Int {
            min(100, max(0, Int(value.rounded(.toNearestOrAwayFromZero))))
        }
        func allocation(_ values: [Int]) -> [Int] {
            let total = values.reduce(0, +)
            let divisor = max(1, total)
            let first = Int((Double(values[0]) / Double(divisor) * 100).rounded(.toNearestOrAwayFromZero))
            let second = Int((Double(values[1]) / Double(divisor) * 100).rounded(.toNearestOrAwayFromZero))
            return [first, second, 100 - first - second]
        }
        let t = flora.traits
        let tissue = allocation([percent(t.tissue.woody), percent(t.tissue.fibrous), percent(t.tissue.fleshy)])
        let colour = allocation([percent(t.coloration.cyan), percent(t.coloration.magenta), percent(t.coloration.yellow)])
        logicalID = "flora-\(flora.id.rawValue)"
        speciesSeed = UInt32(truncatingIfNeeded: flora.worldSeed ^ flora.id.rawValue)
        stature = percent(t.stature)
        tissueAmount = percent(t.tissue.woody + t.tissue.fibrous + t.tissue.fleshy)
        woody = tissue[0]; fibrous = tissue[1]; fleshy = tissue[2]
        defence = percent(t.defence); defenceType = t.defenceType; habit = t.habit
        cyan = colour[0]; magenta = colour[1]; yellow = colour[2]
        colorDepth = percent(t.coloration.depth); patterning = percent(t.coloration.patterning)
        opacity = percent(t.finish.opacity); shine = percent(t.finish.shine); schiller = percent(t.finish.schiller)
        metabolism = t.metabolism
    }
}

private enum FloraPixelGrammar {
    static func commands(for t: FloraRenderDescriptor) -> [PixelCommand] {
        var random = Mulberry32(seed: t.speciesSeed ^ 0x7102)
        let total = max(1, t.cyan + t.magenta + t.yellow)
        let hue = ((Double(t.cyan) / Double(total)) * 185 + (Double(t.magenta) / Double(total)) * 322
                   + (Double(t.yellow) / Double(total)) * 74).truncatingRemainder(dividingBy: 360)
        let saturation = 28 + Double(t.colorDepth) * 0.48
        let alpha = 28 + Double(t.opacity) * 0.72
        let outline = hsl(hue, 32, 10, 100)
        let shadow = hsl(hue + 12, saturation, 25, alpha)
        let body = hsl(hue, saturation, 43, alpha)
        let light = hsl(hue + Double(t.schiller) * 0.7, min(100, saturation + 12),
                        min(86, 58 + Double(t.shine) * 0.22), min(100, alpha + 10))
        let warning = hsl(t.defenceType == .chemical ? 52 : t.defenceType == .active ? 338 : 24, 78, 58, 100)
        let radius = 2 + Int((Double(t.stature + t.tissueAmount) / 45).rounded())
        let centres = t.habit == .spreading ? [(5,6),(9,5),(7,10),(11,9)] : t.habit == .clustered ? [(6,6),(10,7),(7,10)] : [(8,8)]
        var result: [PixelCommand] = []
        for (index, centre) in centres.enumerated() {
            let size = max(2, radius - index % 2), x = centre.0 - size / 2, y = centre.1 - size / 2
            result += [rect(x-1,y,size+2,size,outline),rect(x,y-1,size,size+2,shadow),rect(x,y,size,size,body)]
            if t.woody >= t.fibrous && t.woody >= t.fleshy {
                result.append(rect(centre.0,centre.1,2,2,outline))
                for (dx,dy) in [(-2,0),(2,0),(0,-2),(0,2)] { result.append(rect(centre.0+dx,centre.1+dy,2,2,body)) }
            }
            if t.fibrous > t.woody && t.fibrous >= t.fleshy {
                for (dx,dy) in [(-3,0),(3,0),(0,-3),(0,3),(-2,-2),(2,2)] {
                    result += line(centre.0, centre.1, centre.0+dx, centre.1+dy, light)
                }
            }
            if t.fleshy > t.woody && t.fleshy > t.fibrous { for (dx,dy) in [(-2,-1),(1,-2),(2,1),(-1,2)] { result.append(rect(centre.0+dx,centre.1+dy,2,2,light)) } }
            if t.metabolism == .fungal { result.append(rect(centre.0-1,centre.1-1,3,2,light)) }
            if t.metabolism == .chemosynthetic { result.append(rect(centre.0+(index%2),centre.1-(index%2),1,1,light)) }
        }
        if t.patterning > 30 {
            for _ in 0..<Int((Double(t.patterning)/22).rounded()) {
                result.append(rect(4+Int(random.next()*8),4+Int(random.next()*8),1,1,light))
            }
        }
        if t.defence > 55, t.defenceType == .physical { for (x,y) in [(3,8),(8,3),(13,8),(8,13)] { result.append(rect(x,y,1,2,warning)) } }
        return fit(result, width: 16, height: 16, padding: 1)
    }

    private static func hsl(_ hue: Double, _ saturation: Double, _ lightness: Double, _ alpha: Double) -> RGBA {
        RGBA.hsl(hue: hue.rounded(), saturation: saturation.rounded(), lightness: lightness.rounded(), alpha: alpha.rounded())
    }
}

private struct Mulberry32 {
    var state: UInt32
    init(seed: UInt32) { state = seed == 0 ? 0x6d2b79f5 : seed }
    mutating func next() -> Double {
        state &+= 0x6d2b79f5
        var t = state
        t = (t ^ (t >> 15)) &* (t | 1)
        t ^= t &+ ((t ^ (t >> 7)) &* (t | 61))
        return Double((t ^ (t >> 14))) / 4_294_967_296
    }
}

struct RGBA: Equatable {
    var red: UInt8
    var green: UInt8
    var blue: UInt8
    var alpha: UInt8

    init(_ rgb: RGB, alpha: UInt8 = 255) {
        red = UInt8(rgb.red); green = UInt8(rgb.green); blue = UInt8(rgb.blue); self.alpha = alpha
    }

    static func hsl(hue: Double, saturation: Double, lightness: Double, alpha: Double) -> RGBA {
        let h = ((hue.truncatingRemainder(dividingBy: 360)) + 360).truncatingRemainder(dividingBy: 360) / 360
        let s = min(1, max(0, saturation / 100)), l = min(1, max(0, lightness / 100))
        func channel(_ n: Double) -> Double {
            let k = (n + h * 12).truncatingRemainder(dividingBy: 12)
            let a = s * min(l, 1-l)
            return l - a * max(-1, min(k-3, min(9-k, 1)))
        }
        return RGBA(red: UInt8((channel(0)*255).rounded()),
                    green: UInt8((channel(8)*255).rounded()),
                    blue: UInt8((channel(4)*255).rounded()),
                    alpha: UInt8((min(100,max(0,alpha))/100*255).rounded()))
    }

    init(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) {
        self.red = red; self.green = green; self.blue = blue; self.alpha = alpha
    }
}

@MainActor private enum MapPixelRaster {
    static let cache = NSCache<NSString, UIImage>()

    static func resourceIdentityImage(for id: ResourceID) -> UIImage? {
        let key = "resource-static-v0.6-\(id.rawValue)" as NSString
        if let cached = cache.object(forKey: key) { return cached }
        let commands = ResourcePixelGrammar.inventoryCommands(for: id)
        guard !commands.isEmpty, let image = raster(commands: commands, width: 16, height: 16) else {
            return nil
        }
        cache.setObject(image, forKey: key)
        return image
    }

    static func image(for request: MapTileArtRequest, tick: Int = 0, reduceMotion: Bool = false) -> UIImage? {
        let descriptor = request.flora.map(FloraRenderDescriptor.init)
        let floraKey = descriptor.map(stableFloraKey) ?? "none"
        let phase = request.resourceID.map { _ in
            ResourcePixelGrammar.phase(mapSeed: request.mapSeed, runIndex: request.runIndex, point: request.point)
        }
        let sheenFrame = reduceMotion ? phase.map { _ in 0 } : phase.flatMap { ResourcePixelGrammar.frame(phase: $0, tick: tick) }
        let resourceKey = request.resourceID.map { "\($0.rawValue)-\(sheenFrame.map(String.init) ?? "rest")" } ?? "none"
        let key = "\(MapAssetContract.rendererTuple)-\(request.seed)-\(request.tile.ground.rawValue)-\(request.adjacency)-\(request.southExposureLevels)-\(request.tile.isRevealed)-\(request.tile.isCrumbled)-\(request.tile.isCracking)-\(request.tile.elevation)-\(request.grade.red),\(request.grade.green),\(request.grade.blue),\(request.grade.value)-\(floraKey)-\(resourceKey)" as NSString
        if let cached = cache.object(forKey: key) { return cached }
        var commands = TerrainPixelGrammar.commands(for: request)
        if request.tile.isRevealed, !request.tile.isCrumbled, let descriptor {
            commands += FloraPixelGrammar.commands(for: descriptor).map {
                PixelCommand(x: $0.x, y: $0.y + request.surfaceOffsetY,
                             width: $0.width, height: $0.height, color: $0.color)
            }
        }
        if request.tile.isRevealed, !request.tile.isCrumbled, let resource = request.resourceID {
            let body = ResourcePixelGrammar.bodyCommands(for: resource)
            let shifted = body.map { PixelCommand(x: $0.x, y: $0.y + request.surfaceOffsetY,
                                                   width: $0.width, height: $0.height, color: $0.color) }
            commands += shifted
            if let sheenFrame {
                commands += ResourcePixelGrammar.sheenCommands(body: body, frame: sheenFrame).map {
                    PixelCommand(x: $0.x, y: $0.y + request.surfaceOffsetY,
                                 width: $0.width, height: $0.height, color: $0.color)
                }
            }
        }
        guard let image = raster(commands: commands, width: MapAssetContract.spriteWidth,
                                 height: MapAssetContract.spriteHeight) else { return nil }
        cache.setObject(image, forKey: key)
        return image
    }

    fileprivate static func stableFloraKey(_ flora: FloraRenderDescriptor) -> String {
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]
        let data = (try? encoder.encode(flora)) ?? Data()
        let hash = data.reduce(UInt32(0x811c9dc5)) { ($0 ^ UInt32($1)) &* 0x01000193 }
        return "\(flora.logicalID)-\(flora.speciesSeed)-\(hash)"
    }

    static func raster(commands: [PixelCommand], width: Int, height: Int) -> UIImage? {
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        for command in commands {
            let x0 = max(0, command.x), y0 = max(0, command.y)
            let x1 = min(width, command.x + command.width)
            let y1 = min(height, command.y + command.height)
            guard x0 < x1, y0 < y1 else { continue }
            for y in y0..<y1 { for x in x0..<x1 { blend(command.color, into: &bytes, at: (y*width+x)*4) } }
        }
        let data = Data(bytes)
        guard let provider = CGDataProvider(data: data as CFData),
              let cg = CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32,
                               bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                               bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                               provider: provider, decode: nil, shouldInterpolate: false,
                               intent: .defaultIntent) else { return nil }
        return UIImage(cgImage: cg, scale: 1, orientation: .up)
    }

    /// AssetLab's conformance hash buffer stores the last rectangle's straight RGBA bytes.
    /// This is deliberately separate from on-screen source-over composition.
    static func rawPixels(commands: [PixelCommand], width: Int = 16, height: Int = 16) -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        for command in commands {
            for y in max(0,command.y)..<min(height,command.y+command.height) {
                for x in max(0,command.x)..<min(width,command.x+command.width) {
                    let i=(y*width+x)*4
                    bytes[i]=command.color.red; bytes[i+1]=command.color.green
                    bytes[i+2]=command.color.blue; bytes[i+3]=command.color.alpha
                }
            }
        }
        return bytes
    }

    private static func blend(_ source: RGBA, into bytes: inout [UInt8], at i: Int) {
        let sa = Int(source.alpha), inverse = 255-sa, da = Int(bytes[i+3])
        bytes[i] = UInt8(min(255, (Int(source.red)*sa + Int(bytes[i])*inverse + 127) / 255))
        bytes[i+1] = UInt8(min(255, (Int(source.green)*sa + Int(bytes[i+1])*inverse + 127) / 255))
        bytes[i+2] = UInt8(min(255, (Int(source.blue)*sa + Int(bytes[i+2])*inverse + 127) / 255))
        bytes[i+3] = UInt8(min(255, sa + (da*inverse + 127)/255))
    }
}

struct RGB: ExpressibleByIntegerLiteral, Equatable {
    var red: Int; var green: Int; var blue: Int
    init(integerLiteral value: Int) { self.init(value) }
    init(_ value: Int) { red = value >> 16 & 255; green = value >> 8 & 255; blue = value & 255 }
    func graded(_ grade: WorldGrade) -> RGB {
        var result = self
        result.red = min(255, max(0, red + grade.red + grade.value))
        result.green = min(255, max(0, green + grade.green + grade.value))
        result.blue = min(255, max(0, blue + grade.blue + grade.value))
        return result
    }
}

private func rect(_ x: Int, _ y: Int, _ width: Int, _ height: Int, _ rgb: Int) -> PixelCommand { rect(x,y,width,height,RGB(rgb)) }
private func rect(_ x: Int, _ y: Int, _ width: Int, _ height: Int, _ rgb: RGB) -> PixelCommand { rect(x,y,width,height,RGBA(rgb)) }
private func rect(_ x: Int, _ y: Int, _ width: Int, _ height: Int, _ color: RGBA) -> PixelCommand {
    PixelCommand(x: x, y: y, width: max(1,width), height: max(1,height), color: color)
}

private func line(_ x0: Int, _ y0: Int, _ x1: Int, _ y1: Int, _ rgb: Int) -> [PixelCommand] { line(x0,y0,x1,y1,RGB(rgb)) }
private func line(_ startX: Int, _ startY: Int, _ endX: Int, _ endY: Int, _ rgb: RGB) -> [PixelCommand] {
    line(startX, startY, endX, endY, RGBA(rgb))
}
private func line(_ startX: Int, _ startY: Int, _ endX: Int, _ endY: Int, _ color: RGBA) -> [PixelCommand] {
    var x = startX, y = startY, result: [PixelCommand] = []
    let dx = abs(endX-x), sx = x < endX ? 1 : -1, dy = -abs(endY-y), sy = y < endY ? 1 : -1
    var error = dx + dy
    while true {
        result.append(rect(x,y,1,1,color)); if x == endX && y == endY { break }
        let twice = 2 * error
        if twice >= dy { error += dy; x += sx }; if twice <= dx { error += dx; y += sy }
    }
    return result
}

private func fit(_ commands: [PixelCommand], width: Int, height: Int, padding: Int) -> [PixelCommand] {
    guard let minX = commands.map(\.x).min(), let minY = commands.map(\.y).min(),
          let maxX = commands.map({ $0.x + $0.width }).max(), let maxY = commands.map({ $0.y + $0.height }).max() else { return commands }
    if maxX-minX > width-padding*2 || maxY-minY > height-padding*2 {
        return commands.map { var c=$0; c.x=max(padding,min(width-padding-c.width,c.x)); c.y=max(padding,min(height-padding-c.height,c.y)); return c }
    }
    let dx = minX < padding ? padding-minX : maxX > width-padding ? width-padding-maxX : 0
    let dy = minY < padding ? padding-minY : maxY > height-padding ? height-padding-maxY : 0
    return commands.map { var c=$0; c.x += dx; c.y += dy; return c }
}
