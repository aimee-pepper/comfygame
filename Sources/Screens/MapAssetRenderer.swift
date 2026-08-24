import SwiftUI
import UIKit

/// Lookup-only adapter for the promoted complete exploration-map PNG identities.
/// Geometry and animation frames are authored in the bundles; native code selects keys only.
@MainActor
enum ExplorationMapIdentityPack {
    private struct Manifest: Decodable {
        struct Asset: Decodable { let path: String; let width: Int; let height: Int; let frameCount: Int? }
        let assetsByKey: [String: Asset]
    }

    private struct Pack {
        let root: URL
        let assets: [String: Manifest.Asset]
    }

    private static let packs: [Pack] = [
        "ExplorationMapIdentities-v1", "ExplorationLooseItems-v1", "ExplorationCatalogueObjects-v1",
        "ExplorationLooseEssence-v1"
    ].compactMap { name in
        guard let root = Bundle.main.url(forResource: name, withExtension: nil),
              let data = try? Data(contentsOf: root.appendingPathComponent("manifest.json")),
              let manifest = try? JSONDecoder().decode(Manifest.self, from: data) else { return nil }
        return Pack(root: root, assets: manifest.assetsByKey)
    }
    private static let cache = NSCache<NSString, UIImage>()

    static var allKeys: [String] { packs.flatMap(\.assets.keys).sorted() }

    static func image(key: String) -> UIImage? {
        if let cached = cache.object(forKey: key as NSString) { return cached }
        for pack in packs {
            guard let entry = pack.assets[key], entry.width > 0, entry.height > 0,
                  let image = UIImage(contentsOfFile: pack.root.appendingPathComponent(entry.path).path)
            else { continue }
            cache.setObject(image, forKey: key as NSString)
            return image
        }
        return nil
    }

    static func frameKey(identity: String, state: String = "ordinary", tick: Int,
                         remembered: Bool) -> String? {
        let prefix = "\(identity)/\(state)/frame-"
        let keys = allKeys.filter { $0.hasPrefix(prefix) }
        guard !keys.isEmpty else { return nil }
        return keys[remembered ? 0 : abs(tick) % keys.count]
    }
}

/// Pure key adapter. It never manufactures pixels and returns nil for every unpromoted identity.
@MainActor
enum ExplorationMapIdentityResolver {
    private static let opaqueCurioIDs: Set<ItemID> = [
        "curio_humming_shard", "curio_bound_knot"
    ]

    static func usesRememberedFrame(currentVisibility: WorldRules.TileVisibility,
                                    disclosed: Bool) -> Bool {
        disclosed && currentVisibility != .full
    }

    static func key(tile: Tile, site: SiteDef?, siteLooted: Bool?, hasLooseWorldPage: Bool,
                    tick: Int, disclosed: Bool, remembered: Bool) -> String? {
        guard disclosed else { return nil }
        if hasLooseWorldPage { return "loose_world_page/ordinary/frame-0" }
        switch tile.content {
        case .item(let stack):
            let id = stack.catalogID.rawValue
            guard stack.identified || opaqueCurioIDs.contains(stack.catalogID) else { return nil }
            let candidates = stack.identified
                ? ["catalogue-item/\(id)/identified", "catalogue-item/\(id)"]
                : ["catalogue-item/unknown-curio"]
            return candidates.first { ExplorationMapIdentityPack.image(key: $0) != nil }
        case .hazard:
            return ExplorationMapIdentityPack.frameKey(identity: "hazard", tick: tick,
                                                       remembered: remembered)
        case .portal(let isEntry):
            return ExplorationMapIdentityPack.frameKey(
                identity: isEntry ? "entry_portal" : "exit_portal", tick: tick,
                remembered: remembered)
        case .lockedCache: return "locked_cache/ordinary/frame-0"
        case .diaryPage: return "diary_page/ordinary/frame-0"
        case .foundWriting: return "found_writing/ordinary/frame-0"
        case .wildDrop(let resource, let amount)
            where resource == Resources.essenceRaw && amount > 0:
            return ExplorationMapIdentityPack.frameKey(
                identity: "loose_essence", tick: tick, remembered: remembered)
        case .site:
            guard let site else { return nil }
            let state = site.id.rawValue == "natural_anchor"
                ? "ordinary" : (siteLooted == true ? "looted" : "unlooted")
            return ExplorationMapIdentityPack.frameKey(identity: site.id.rawValue, state: state,
                                                       tick: tick, remembered: remembered)
        default: return nil
        }
    }
}

enum ExplorationMapIdentityLayout {
    static let mapCanvas = CGSize(width: 16, height: 19)
    static let mapPivot = CGPoint(x: 8, y: 18)
    static let minimapCanvas = CGSize(width: 7, height: 7)

    static func mapAssetSize(tileSide: CGFloat) -> CGSize {
        CGSize(width: tileSide, height: tileSide * mapCanvas.height / mapCanvas.width)
    }
}

struct ExplorationMapPixelIdentity: View {
    let key: String
    var body: some View {
        if let image = ExplorationMapIdentityPack.image(key: key) {
            Image(uiImage: image).resizable().interpolation(.none).antialiased(false)
                .accessibilityHidden(true)
        }
    }
}

/// Native adapter contract for the accepted TerrainProductionPack-v1.
/// Gameplay owns facts. The pack owns the reviewed 16×16 semantic terrain layers.
enum MapAssetContract {
    static let manifestSHA256 = TerrainProductionPack.manifestSHA256
    static let seedVersion = "bookbinder-terrain-seed-v1"
    static let animationVersion = "terrain-layers-v2"
    static let seedTuple = "1|1|1|1|world-grade-1.0.0|map-slice-1.1.0|rect-compositor-0.2.0|top-down-map-16px-1.0.0"
    static let rendererTuple = "terrain-production-pack-v1|terrain-layers-v2|native-1"
    static let regionContinuityVersion = "terrain-region-continuity-v1"
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
        return min(3, max(0, resolvedElevation(for: center) - resolvedElevation(for: south)))
    }

    static func terrainSeed(mapSeed: UInt64, point: GridPoint) -> UInt32 {
        let input = "\(seedVersion)|\(mapSeed)|\(point.x)|\(point.y)|\(seedTuple)"
        return input.utf8.reduce(UInt32(0x811c9dc5)) { hash, byte in
            (hash ^ UInt32(byte)) &* 0x01000193
        }
    }

    /// Structural macro orientation belongs to the world, never to an individual tile.
    static func regionFeatureVariant(mapSeed: UInt64) -> Int {
        Int(mapSeed & 3)
    }

    static func edgeContourID(mapSeed: UInt64, point: GridPoint,
                              direction: TerrainProductionPack.Direction) -> Int {
        let other: GridPoint = switch direction {
        case .north: .init(x: point.x, y: point.y - 1)
        case .east: .init(x: point.x + 1, y: point.y)
        case .south: .init(x: point.x, y: point.y + 1)
        case .west: .init(x: point.x - 1, y: point.y)
        }
        let first: GridPoint
        let second: GridPoint
        if point.y < other.y || (point.y == other.y && point.x <= other.x) {
            first = point; second = other
        } else {
            first = other; second = point
        }
        let input = "terrain-edge-v2|\(mapSeed)|\(first.x)|\(first.y)|\(second.x)|\(second.y)"
        let hash = input.utf8.reduce(UInt32(0x811c9dc5)) {
            ($0 ^ UInt32($1)) &* 0x01000193
        }
        return Int(hash & 3)
    }

    static func phaseOffset(mapSeed: UInt64, point: GridPoint) -> Int {
        let input = "terrain-motion-v2|\(mapSeed)|\(point.x)|\(point.y)"
        let hash = input.utf8.reduce(UInt32(0x811c9dc5)) {
            ($0 ^ UInt32($1)) &* 0x01000193
        }
        return Int(hash % 24)
    }

    static func motionBand(_ motion: Int) -> TerrainProductionPack.MotionBand {
        switch min(100, max(0, motion)) {
        case ...40: .calm
        case ...65: .moving
        default: .strong
        }
    }
}

struct WorldGrade: Equatable, Sendable {
    var red: Int
    var green: Int
    var blue: Int
    var value: Int

    static let neutral = WorldGrade(red: 0, green: 0, blue: 0, value: 0)

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
    let cardinalNeighbors: TerrainProductionPack.Cardinal<TerrainProductionPack.Neighbor>
    let edgeContourIDs: TerrainProductionPack.Cardinal<Int>
    let contactShadeDepths: TerrainProductionPack.Cardinal<Int>
    /// Authored wall depth derived only from a disclosed south neighbour. Hidden/equal/out-of-map
    /// exposure remains zero and never reaches the wall pack.
    let southWallDepth: Int
    let wallWestContinuation: Bool
    let wallEastContinuation: Bool
    let visibility: TerrainProductionPack.Visibility
    let surfaceDeposits: TerrainProductionPack.SurfaceDeposits
    let flora: Flora?
    let worldGrade2Descriptor: WorldGrade2V1.Descriptor?
    let atmosphereMotion: Int
    let presentationTick: Int
    let explicitSeed: UInt32?
    let explicitFeatureVariant: Int?

    init(tile: Tile, point: GridPoint, mapSeed: UInt64, runIndex: Int = 0,
         cardinalNeighbors: TerrainProductionPack.Cardinal<TerrainProductionPack.Neighbor>,
         edgeContourIDs: TerrainProductionPack.Cardinal<Int>,
         contactShadeDepths: TerrainProductionPack.Cardinal<Int>,
         southWallDepth: Int = 0,
         wallWestContinuation: Bool = false,
         wallEastContinuation: Bool = false,
         visibility: TerrainProductionPack.Visibility,
         surfaceDeposits: TerrainProductionPack.SurfaceDeposits = .none,
         grade: WorldGrade = .neutral,
         flora: Flora?, worldGrade2Descriptor: WorldGrade2V1.Descriptor? = nil,
         atmosphereMotion: Int = 0, presentationTick: Int = 0,
         explicitSeed: UInt32? = nil, explicitFeatureVariant: Int? = nil) {
        self.tile = tile; self.point = point; self.mapSeed = mapSeed; self.runIndex = runIndex
        self.cardinalNeighbors = cardinalNeighbors; self.edgeContourIDs = edgeContourIDs
        self.contactShadeDepths = contactShadeDepths; self.visibility = visibility
        self.southWallDepth = min(3, max(0, southWallDepth))
        self.wallWestContinuation = wallWestContinuation
        self.wallEastContinuation = wallEastContinuation
        self.surfaceDeposits = surfaceDeposits; self.grade = grade; self.flora = flora
        self.worldGrade2Descriptor = worldGrade2Descriptor
        self.atmosphereMotion = min(100, max(0, atmosphereMotion))
        self.presentationTick = max(0, presentationTick) % 24
        self.explicitSeed = explicitSeed; self.explicitFeatureVariant = explicitFeatureVariant
    }

    /// Compatibility initializer for the pre-pack renderer and its frozen regression fixtures.
    /// Runtime v2 requests use the typed cardinal initializer above.
    init(tile: Tile, point: GridPoint, mapSeed: UInt64, runIndex: Int = 0,
         adjacency: Int, southExposureLevels: Int = 0, grade: WorldGrade,
         flora: Flora?, worldGrade2Descriptor: WorldGrade2V1.Descriptor? = nil,
         atmosphereMotion: Int = 0, explicitSeed: UInt32? = nil,
         explicitFeatureVariant: Int? = nil) {
        func neighbor(_ bit: Int) -> TerrainProductionPack.Neighbor {
            adjacency & bit == 0 ? .unknown : .same
        }
        self.init(
            tile: tile, point: point, mapSeed: mapSeed, runIndex: runIndex,
            cardinalNeighbors: .init(north: neighbor(1), east: neighbor(2),
                                     south: neighbor(4), west: neighbor(8)),
            edgeContourIDs: .init(north: 0, east: 1, south: 2, west: 3),
            contactShadeDepths: .init(north: 0, east: 0, south: 0, west: 0),
            southWallDepth: southExposureLevels, visibility: .full, grade: grade,
            flora: flora, worldGrade2Descriptor: worldGrade2Descriptor,
            atmosphereMotion: atmosphereMotion, explicitSeed: explicitSeed,
            explicitFeatureVariant: explicitFeatureVariant)
    }

    var seed: UInt32 { explicitSeed ?? MapAssetContract.terrainSeed(mapSeed: mapSeed, point: point) }
    var featureVariant: Int { explicitFeatureVariant ?? Int(seed & 3) }
    var resolvedElevation: Int { MapAssetContract.resolvedElevation(for: tile) }
    var surfaceOffsetY: Int { MapAssetContract.maximumElevation - resolvedElevation }
    var adjacency: Int {
        let directions: [(TerrainProductionPack.Direction, Int)] = [
            (.north, 1), (.east, 2), (.south, 4), (.west, 8),
        ]
        return directions.reduce(0) { value, pair in
            value | (cardinalNeighbors[pair.0] == .same ? pair.1 : 0)
        }
    }
    var southExposureLevels: Int { southWallDepth }
    fileprivate let grade: WorldGrade

    func terrainRequest(reduceMotion: Bool) throws -> TerrainProductionPack.Request {
        guard tile.isRevealed, let descriptor = worldGrade2Descriptor else {
            throw TerrainProductionPack.PackError.invalidRequest
        }
        return try TerrainProductionPack.Request(
            ground: .init(tile.ground), point: point, visualSeed: UInt64(seed),
            worldGradeDescriptorHash: descriptor.canonicalDescriptorSHA256,
            featureVariant: explicitFeatureVariant
                ?? MapAssetContract.regionFeatureVariant(mapSeed: mapSeed),
            cardinalNeighbors: cardinalNeighbors,
            edgeContourIDs: edgeContourIDs, elevation: resolvedElevation,
            isCrumbled: tile.isCrumbled, isCracking: tile.isCracking, visibility: visibility,
            motionBand: MapAssetContract.motionBand(atmosphereMotion),
            phaseOffset: MapAssetContract.phaseOffset(mapSeed: mapSeed, point: point),
            presentationTick: presentationTick, reduceMotion: reduceMotion,
            surfaceDeposits: surfaceDeposits)
    }
}

@MainActor enum MapAssetTestSupport {
    private static let fixtureHash = "659e59c58822d20b5ddb7ed6303d15746d666444692bcc52ab21c37e200a5c09"
    private static let pack: TerrainProductionPack = {
        let source = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
        return TerrainProductionPack(rootURL: source.appendingPathComponent(
            "AssetLab/integration/terrain-production-pack-v1/runtime", isDirectory: true))
    }()

    static func productionPack() -> TerrainProductionPack { pack }

    static var explorationMapAssetKeys: [String] { ExplorationMapIdentityPack.allKeys }

    static func explorationMapImage(_ key: String) -> UIImage? {
        ExplorationMapIdentityPack.image(key: key)
    }

    static func explorationMapFrameKey(identity: String, state: String = "ordinary",
                                       tick: Int, remembered: Bool) -> String? {
        ExplorationMapIdentityPack.frameKey(identity: identity, state: state, tick: tick,
                                            remembered: remembered)
    }

    static func explorationMapKey(tile: Tile, site: SiteDef? = nil, siteLooted: Bool? = nil,
                                  hasLooseWorldPage: Bool = false, tick: Int = 0,
                                  disclosed: Bool = true, remembered: Bool = false) -> String? {
        ExplorationMapIdentityResolver.key(tile: tile, site: site, siteLooted: siteLooted,
                                           hasLooseWorldPage: hasLooseWorldPage, tick: tick,
                                           disclosed: disclosed, remembered: remembered)
    }

    static func stationaryIdentityUsesRememberedFrame(
        currentVisibility: WorldRules.TileVisibility, disclosed: Bool
    ) -> Bool {
        ExplorationMapIdentityResolver.usesRememberedFrame(
            currentVisibility: currentVisibility, disclosed: disclosed)
    }

    static func productionRequest(
        ground: GroundType, point: GridPoint = .init(x: 0, y: 0), visualSeed: UInt64 = 404,
        descriptorHash: String = fixtureHash, featureVariant: Int = 0,
        cardinalNeighbors: TerrainProductionPack.Cardinal<TerrainProductionPack.Neighbor>? = nil,
        edgeContourIDs: TerrainProductionPack.Cardinal<Int> = .init(
            north: 0, east: 1, south: 2, west: 3), elevation: Int = 0,
        crumbled: Bool = false, cracking: Bool = false,
        visibility: TerrainProductionPack.Visibility = .full,
        motionBand: TerrainProductionPack.MotionBand = .calm,
        phaseOffset: Int = 0, presentationTick: Int = 0, reduceMotion: Bool = false,
        snow: Bool = false, settledAsh: Bool = false
    ) throws -> TerrainProductionPack.Request {
        try TerrainProductionPack.Request(
            ground: .init(ground), point: point, visualSeed: visualSeed,
            worldGradeDescriptorHash: descriptorHash, featureVariant: featureVariant,
            cardinalNeighbors: cardinalNeighbors ?? .init(
                north: .same, east: .same, south: .same, west: .same),
            edgeContourIDs: edgeContourIDs, elevation: elevation,
            isCrumbled: crumbled, isCracking: cracking, visibility: visibility,
            motionBand: motionBand, phaseOffset: phaseOffset,
            presentationTick: presentationTick, reduceMotion: reduceMotion,
            surfaceDeposits: .init(snow: snow, settledAsh: settledAsh))
    }

    static func productionPixels(_ request: TerrainProductionPack.Request,
                                 descriptor: WorldGrade2V1.Descriptor? = nil) throws -> [UInt8] {
        try pack.rgba(for: request, descriptor: descriptor)
    }

    static func nativeRenderedImage(_ request: MapTileArtRequest) -> UIImage? {
        MapPixelRaster.image(for: request, reduceMotion: true)
    }

    static func terrainPixels(ground: GroundType, adjacency: Int = 15, featureVariant: Int = 0,
                              grade: WorldGrade = WorldGrade(red: 0, green: 0, blue: 0, value: 0),
                              elevation: Int = 0, crumbled: Bool = false,
                              cracking: Bool = false, revealed: Bool = true,
                              southExposureLevels: Int = 0,
                              seed: UInt32 = 404) -> [UInt8] {
        var tile = Tile(ground: ground, elevation: elevation, isRevealed: revealed,
                        isCrumbled: crumbled)
        tile.isCracking = cracking
        let request = MapTileArtRequest(
            tile: tile, point: GridPoint(x: 0, y: 0), mapSeed: 0,
            adjacency: adjacency, southExposureLevels: southExposureLevels,
            grade: grade, flora: nil, explicitSeed: seed,
            explicitFeatureVariant: featureVariant)
        return MapPixelRaster.rawPixels(commands: TerrainPixelGrammar.commands(for: request),
                                        width: MapAssetContract.spriteWidth,
                                        height: MapAssetContract.spriteHeight)
    }

    static func renderedTerrainPixels(ground: GroundType, adjacency: Int = 15,
                                      elevation: Int = 0,
                                      southExposureLevels: Int = 0,
                                      seed: UInt32 = 404) throws -> [UInt8] {
        let tile = Tile(ground: ground, elevation: elevation, isRevealed: true)
        let request = MapTileArtRequest(
            tile: tile, point: GridPoint(x: 0, y: 0), mapSeed: 0,
            adjacency: adjacency, southExposureLevels: southExposureLevels,
            grade: .neutral, flora: nil, explicitSeed: seed, explicitFeatureVariant: 0)
        return MapPixelRaster.rawPixels(
            commands: try MapPixelRaster.legacyTerrainCommandsForTests(request),
            width: MapAssetContract.spriteWidth, height: MapAssetContract.spriteHeight)
    }

    static func floraPixels(_ flora: Flora) -> [UInt8] {
        MapPixelRaster.rawPixels(commands: FloraPixelGrammar.commands(for: FloraRenderDescriptor(flora)))
    }

    static func floraCacheKey(_ flora: Flora) -> String {
        MapPixelRaster.stableFloraKey(FloraRenderDescriptor(flora))
    }

    static func descriptorCacheIdentity(_ descriptor: WorldGrade2V1.Descriptor) throws -> String {
        try WorldGrade2V1.validatedCacheIdentity(descriptor)
    }

    static func gradedTerrainPixels(ground: GroundType, descriptor: WorldGrade2V1.Descriptor,
                                    adjacency: Int = 15, featureVariant: Int = 0,
                                    revealed: Bool = true) throws -> [UInt8] {
        guard revealed else { return [UInt8](repeating: 0, count: 16 * 19 * 4) }
        let request = try productionRequest(
            ground: ground, visualSeed: 404,
            descriptorHash: descriptor.canonicalDescriptorSHA256,
            featureVariant: featureVariant, cardinalNeighbors: legacyNeighbors(adjacency))
        let rgba = try pack.rgba(for: request, descriptor: descriptor)
        return liftedPixels(rgba, elevation: 0, wallDepth: 0)
    }

    static func gradedFloraPixels(_ flora: Flora,
                                  descriptor: WorldGrade2V1.Descriptor) throws -> [UInt8] {
        try MapPixelRaster.rawPixels(commands: MapPixelRaster.floraCommands(
            FloraRenderDescriptor(flora), descriptor: descriptor))
    }

    /// Returns the composed tile and the resource-only overlay in the same lifted coordinates.
    /// Tests use the overlay's nontransparent pixels to prove world grading never recolors a
    /// resource identity while still exercising the real terrain-first composition order.
    static func gradedResourceComposition(_ id: ResourceID,
                                          descriptor: WorldGrade2V1.Descriptor) throws
        -> (composed: [UInt8], resourceOverlay: [UInt8]) {
        var tile = Tile(ground: .stone, isRevealed: true)
        tile.content = .wildDrop(resource: id, amount: 1)
        let request = try productionRequest(
            ground: .stone, descriptorHash: descriptor.canonicalDescriptorSHA256)
        let resource = ResourceSpriteV1PixelGrammar.commands(for: id, profile: .map).map {
            PixelCommand(x: $0.x, y: $0.y + MapAssetContract.maximumElevation,
                         width: $0.width, height: $0.height, color: $0.color)
        }
        var terrainRGBA = try pack.rgba(for: request, descriptor: descriptor)
        MapPixelRaster.applyExternalTerrainTruth(
            tileGround: tile.ground, isCrumbled: false, isCracking: false,
            contactShadeDepths: .init(north: 0, east: 0, south: 0, west: 0),
            to: &terrainRGBA)
        let terrain = MapPixelRaster.pixelCommands(terrainRGBA).map {
            PixelCommand(x: $0.x, y: $0.y + MapAssetContract.maximumElevation,
                         width: $0.width, height: $0.height, color: $0.color)
        }
        return (MapPixelRaster.rawPixels(commands: terrain + resource,
                                         width: MapAssetContract.spriteWidth,
                                         height: MapAssetContract.spriteHeight),
                MapPixelRaster.rawPixels(commands: resource,
                                         width: MapAssetContract.spriteWidth,
                                         height: MapAssetContract.spriteHeight))
    }

    static func resourcePixels(_ id: ResourceID, frame: Int? = nil) -> [UInt8] {
        let body = ResourcePixelGrammar.bodyCommands(for: id)
        let sheen = frame.map { ResourcePixelGrammar.sheenCommands(body: body, frame: $0) } ?? []
        return MapPixelRaster.rawPixels(commands: body + sheen)
    }

    static func inventoryResourcePixels(_ id: ResourceID) -> [UInt8] {
        MapPixelRaster.rawPixels(commands: ResourcePixelGrammar.inventoryCommands(for: id))
    }

    static func productionMapResourcePixels(_ id: ResourceID) -> [UInt8] {
        MapPixelRaster.rawPixels(commands: ResourceSpriteV1PixelGrammar.commands(for: id, profile: .map))
    }

    static func productionInventoryResourcePixels(_ id: ResourceID) -> [UInt8] {
        guard let asset = ResourceSpriteV1Registry.asset(for: id, profile: .inventory) else { return [] }
        return MapPixelRaster.rawPixels(
            commands: ResourceSpriteV1PixelGrammar.commands(for: id, profile: .inventory),
            width: asset.width, height: asset.height)
    }

    static func productionFieldResourcePixels(_ id: ResourceID) -> [UInt8] {
        guard let asset = ResourceSpriteV1Registry.asset(for: id, profile: .field) else { return [] }
        return MapPixelRaster.rawPixels(
            commands: ResourceSpriteV1PixelGrammar.commands(for: id, profile: .field),
            width: asset.width, height: asset.height)
    }

    static func resourceSheenPhase(mapSeed: UInt64, runIndex: Int, point: GridPoint) -> UInt32 {
        ResourcePixelGrammar.phase(mapSeed: mapSeed, runIndex: runIndex, point: point)
    }

    static func resourceSheenFrame(phase: UInt32, tick: Int) -> Int? {
        ResourcePixelGrammar.frame(phase: phase, tick: tick)
    }

    static func animatedTerrainPixels(ground: GroundType, tick: Int, mapSeed: UInt64 = 71,
                                      point: GridPoint = .init(x: 3, y: 4),
                                      atmosphereMotion: Int = 0) -> [UInt8] {
        let request = try! productionRequest(
            ground: ground, point: point,
            visualSeed: UInt64(MapAssetContract.terrainSeed(mapSeed: mapSeed, point: point)),
            featureVariant: 0, motionBand: MapAssetContract.motionBand(atmosphereMotion),
            phaseOffset: MapAssetContract.phaseOffset(mapSeed: mapSeed, point: point),
            presentationTick: tick)
        return try! pack.rgba(for: request)
    }

    static func terrainAnimationFrame(ground: GroundType, tick: Int, mapSeed: UInt64 = 71,
                                      point: GridPoint = .init(x: 3, y: 4),
                                      atmosphereMotion: Int = 0) -> Int? {
        let packGround = TerrainProductionPack.Ground(ground)
        guard [.water, .deepWater, .groundcover, .growth].contains(packGround),
              !(packGround == .groundcover || packGround == .growth)
                || atmosphereMotion > 40 else { return nil }
        let step: Int
        switch (packGround, MapAssetContract.motionBand(atmosphereMotion)) {
        case (.water, .calm): step = 4
        case (.water, .moving): step = 2
        case (.water, .strong): step = 1
        case (.deepWater, .calm): step = 6
        case (.deepWater, .moving): step = 3
        case (.deepWater, .strong): step = 2
        case (.groundcover, .moving), (.growth, .moving): step = 4
        case (.groundcover, .strong), (.growth, .strong): step = 2
        default: return nil
        }
        return (MapAssetContract.phaseOffset(mapSeed: mapSeed, point: point)
                + (tick % 24) / step) % 4
    }

    private static func legacyNeighbors(_ adjacency: Int)
        -> TerrainProductionPack.Cardinal<TerrainProductionPack.Neighbor> {
        .init(north: adjacency & 1 == 0 ? .unknown : .same,
              east: adjacency & 2 == 0 ? .unknown : .same,
              south: adjacency & 4 == 0 ? .unknown : .same,
              west: adjacency & 8 == 0 ? .unknown : .same)
    }

    private static func liftedPixels(_ rgba: [UInt8], elevation: Int,
                                     wallDepth: Int) -> [UInt8] {
        let offset = MapAssetContract.maximumElevation - min(3, max(0, elevation))
        let top = MapPixelRaster.pixelCommands(rgba).map {
            PixelCommand(x: $0.x, y: $0.y + offset,
                         width: $0.width, height: $0.height, color: $0.color)
        }
        let wall = MapPixelRaster.externalSouthWallCommands(
            topSurfaceRGBA: rgba, surfaceOffsetY: offset, depth: wallDepth)
        return MapPixelRaster.rawPixels(commands: top + wall,
                                        width: MapAssetContract.spriteWidth,
                                        height: MapAssetContract.spriteHeight)
    }
}

/// The collected-object profile from the exact-ID Resource v1 pack.
/// World nodes and compact field markers deliberately use their own top-down and 8px profiles.
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

/// The independently authored 8px collection marker. It is not a scaled Storehouse object or a
/// terrain node, so the compact World haul stays legible without changing either larger identity.
struct ResourceFieldMarkerIdentity: View {
    let id: ResourceID
    let fallbackSystemIcon: String

    var body: some View {
        if let image = MapPixelRaster.resourceIdentityImage(for: id, profile: .field) {
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

struct ResourceMiningFeedbackV1: Equatable {
    struct Subject: Equatable, Identifiable {
        let resourceID: ResourceID
        let amount: Int
        var id: ResourceID { resourceID }
    }

    let batchID: String
    let subjects: [Subject]

    @MainActor static func make(from group: WorldMiningFeedbackGroupV1) -> Self? {
        let subjects = group.subjects.compactMap { row -> Subject? in
            guard row.amount > 0,
                  ResourceSpriteV1Registry.asset(for: row.resourceID, profile: .field) != nil
            else { return nil }
            return Subject(resourceID: row.resourceID, amount: row.amount)
        }
        guard !subjects.isEmpty else { return nil }
        return Self(batchID: group.batchID, subjects: subjects)
    }

    static let durationMilliseconds: Double = 450
    static let fullOpacityMilliseconds: Double = 180

    static func progress(elapsedMilliseconds: Double) -> CGFloat {
        min(1, max(0, CGFloat(elapsedMilliseconds / durationMilliseconds)))
    }

    static func opacity(elapsedMilliseconds: Double) -> CGFloat {
        guard elapsedMilliseconds > fullOpacityMilliseconds else { return 1 }
        return min(1, max(0, CGFloat(
            1 - (elapsedMilliseconds - fullOpacityMilliseconds)
                / (durationMilliseconds - fullOpacityMilliseconds))))
    }

    static func riseDistance(tileHeight: CGFloat, sourceCenterY: CGFloat,
                             mapMinY: CGFloat, contentHeight: CGFloat) -> CGFloat {
        max(0, min(tileHeight * 1.5,
                   sourceCenterY - mapMinY - contentHeight / 2))
    }

    static func center(sourceTile: CGRect, mapViewport: CGRect,
                       contentHeight: CGFloat, elapsedMilliseconds: Double) -> CGPoint {
        let rise = riseDistance(tileHeight: sourceTile.height,
                                sourceCenterY: sourceTile.midY,
                                mapMinY: mapViewport.minY,
                                contentHeight: contentHeight)
        return CGPoint(x: sourceTile.midX,
                       y: sourceTile.midY - rise * progress(
                        elapsedMilliseconds: elapsedMilliseconds))
    }

    static func quantityLabelCenterX(iconCenterX: CGFloat, iconWidth: CGFloat,
                                     labelWidth: CGFloat, mapViewport: CGRect,
                                     gap: CGFloat = 3) -> CGFloat {
        let right = iconCenterX + iconWidth / 2 + gap + labelWidth / 2
        if right + labelWidth / 2 <= mapViewport.maxX { return right }
        let left = iconCenterX - iconWidth / 2 - gap - labelWidth / 2
        return max(mapViewport.minX + labelWidth / 2,
                   min(mapViewport.maxX - labelWidth / 2, left))
    }

    static func counterPulseOpacity(elapsedMilliseconds: Double) -> CGFloat {
        guard elapsedMilliseconds >= 0, elapsedMilliseconds < fullOpacityMilliseconds else { return 0 }
        let normalized = CGFloat(elapsedMilliseconds / fullOpacityMilliseconds)
        return 1 - abs(normalized * 2 - 1)
    }
}

private struct ResourceMiningSubjectLayout: Layout {
    let iconCenter: CGPoint
    let mapViewport: CGRect

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews,
                      cache: inout ()) -> CGSize {
        proposal.replacingUnspecifiedDimensions(
            by: CGSize(width: mapViewport.maxX, height: mapViewport.maxY))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize,
                       subviews: Subviews, cache: inout ()) {
        guard let icon = subviews.first else { return }
        let iconSize = icon.sizeThatFits(.unspecified)
        icon.place(at: iconCenter, anchor: .center,
                   proposal: ProposedViewSize(iconSize))
        guard subviews.count > 1 else { return }
        let label = subviews[1]
        let labelSize = label.sizeThatFits(.unspecified)
        let labelX = ResourceMiningFeedbackV1.quantityLabelCenterX(
            iconCenterX: iconCenter.x, iconWidth: iconSize.width,
            labelWidth: labelSize.width, mapViewport: mapViewport)
        label.place(at: CGPoint(x: labelX, y: iconCenter.y), anchor: .center,
                    proposal: ProposedViewSize(labelSize))
    }
}

@MainActor
struct ResourceMiningFeedbackFrame: View {
    let presentation: ResourceMiningFeedbackV1
    let sourceTile: CGRect
    let mapViewport: CGRect
    let elapsedMilliseconds: Double

    private static let contentHeight: CGFloat = 28

    var body: some View {
        let center = ResourceMiningFeedbackV1.center(
            sourceTile: sourceTile, mapViewport: mapViewport,
            contentHeight: Self.contentHeight, elapsedMilliseconds: elapsedMilliseconds)
        GeometryReader { geometry in
            ZStack {
              ForEach(presentation.subjects) { subject in
                  ResourceMiningSubjectLayout(iconCenter: center, mapViewport: mapViewport) {
                      ResourceFieldMarkerIdentity(id: subject.resourceID, fallbackSystemIcon: "")
                          .frame(width: 16, height: 16)
                      if subject.amount > 1 {
                          Text("×\(subject.amount)")
                              .font(.custom("Tiny5", size: 13))
                              .foregroundStyle(PixelUITheme.textOnEdgeDark)
                              .padding(.horizontal, 3)
                              .background(PixelUITheme.edgeDark.opacity(0.9))
                      }
                  }
                  .frame(width: geometry.size.width, height: geometry.size.height)
                  .opacity(ResourceMiningFeedbackV1.opacity(
                    elapsedMilliseconds: elapsedMilliseconds))
              }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .allowsHitTesting(false)
    }
}

@MainActor
struct ResourceMiningFeedbackOverlay: View {
    let presentation: ResourceMiningFeedbackV1
    let sourceTile: CGRect
    let mapViewport: CGRect
    let startedAtMonotonicTime: UInt64
    let onFinished: () -> Void

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { _ in
            let now = DispatchTime.now().uptimeNanoseconds
            let elapsed = Double(now &- min(now, startedAtMonotonicTime)) / 1_000_000
            ResourceMiningFeedbackFrame(
                presentation: presentation, sourceTile: sourceTile,
                mapViewport: mapViewport, elapsedMilliseconds: elapsed)
        }
        .allowsHitTesting(false)
        .task(id: presentation.batchID) {
            let now = DispatchTime.now().uptimeNanoseconds
            let elapsed = Double(now &- min(now, startedAtMonotonicTime)) / 1_000_000
            let remaining = max(0, ResourceMiningFeedbackV1.durationMilliseconds - elapsed)
            try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000))
            guard !Task.isCancelled else { return }
            onFinished()
        }
    }

}

struct ResourceMiningCounterPulse: ViewModifier {
    let resourceID: ResourceID
    let presentations: [WorldMiningFeedbackGroupV1]

    func body(content: Content) -> some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { _ in
            let now = DispatchTime.now().uptimeNanoseconds
            let opacity = presentations.reduce(CGFloat.zero) { result, group in
                guard group.subjects.contains(where: { $0.resourceID == resourceID }) else {
                    return result
                }
                let elapsed = Double(now &- min(now, group.startedAtMonotonicTime)) / 1_000_000
                return max(result, ResourceMiningFeedbackV1.counterPulseOpacity(
                    elapsedMilliseconds: elapsed))
            }
            content.overlay {
                Rectangle()
                    .stroke(PixelUITheme.primaryHighlight, lineWidth: 2)
                    .opacity(opacity)
            }
        }
    }
}

struct MiningAnchorReceipt {
    var mapViewport: Anchor<CGRect>?
    var sourceUnitFrames: [GridPoint: CGRect] = [:]
}

struct MiningAnchorReceiptKey: PreferenceKey {
    static let defaultValue = MiningAnchorReceipt()
    static func reduce(value: inout MiningAnchorReceipt,
                       nextValue: () -> MiningAnchorReceipt) {
        let next = nextValue()
        value.mapViewport = value.mapViewport ?? next.mapViewport
        value.sourceUnitFrames.merge(next.sourceUnitFrames,
                                     uniquingKeysWith: { first, _ in first })
    }
}

#if DEBUG
@MainActor enum MiningFeedbackLayoutMeasurement {
    static var latestBatchID: String?
    static var latestSourceTile: CGRect?
    static var latestMapViewport: CGRect?
}
#endif

@MainActor
struct WorldMiningFeedbackPresentationModifier: ViewModifier {
    @ObservedObject var store: GameStore

    func body(content: Content) -> some View {
        content.overlayPreferenceValue(MiningAnchorReceiptKey.self) { anchors in
            GeometryReader { proxy in
                ZStack {
                    ForEach(store.worldMiningFeedbackPresentations, id: \.batchID) { group in
                      if let presentation = ResourceMiningFeedbackV1.make(from: group),
                         let viewportAnchor = anchors.mapViewport,
                         let sourceUnitFrame = anchors.sourceUnitFrames[group.sourcePoint] {
                        let viewport = proxy[viewportAnchor]
                        let source = CGRect(
                            x: viewport.minX + sourceUnitFrame.minX * viewport.width,
                            y: viewport.minY + sourceUnitFrame.minY * viewport.height,
                            width: sourceUnitFrame.width * viewport.width,
                            height: sourceUnitFrame.height * viewport.height)
                        ResourceMiningFeedbackOverlay(
                            presentation: presentation,
                            sourceTile: source,
                            mapViewport: viewport,
                            startedAtMonotonicTime: group.startedAtMonotonicTime,
                            onFinished: {
                                store.finishWorldMiningFeedback(expectedBatchID: group.batchID)
                            }
                        )
#if DEBUG
                        .onAppear {
                            MiningFeedbackLayoutMeasurement.latestBatchID = group.batchID
                            MiningFeedbackLayoutMeasurement.latestSourceTile = source
                            MiningFeedbackLayoutMeasurement.latestMapViewport = viewport
                        }
#endif
                      } else {
                        Color.clear.task(id: group.batchID) {
                            // Missing geometry owns no fallback coordinate and draws nothing. Keep
                            // the transient receipt alive for its ordinary local lifetime so an
                            // initial empty SwiftUI preference pass cannot consume it before map
                            // layout publishes the source tile; genuinely missing geometry simply
                            // remains invisible and expires normally.
                            let now = DispatchTime.now().uptimeNanoseconds
                            let elapsed = Double(now &- min(now, group.startedAtMonotonicTime)) / 1_000_000
                            let remaining = max(0, ResourceMiningFeedbackV1.durationMilliseconds - elapsed)
                            try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000))
                            guard !Task.isCancelled else { return }
                            store.finishWorldMiningFeedback(expectedBatchID: group.batchID)
                        }
                      }
                    }
                }
            }
        }
    }
}

struct MapTileArt: View {
    let request: MapTileArtRequest
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if let image = MapPixelRaster.image(for: request, reduceMotion: reduceMotion) {
            Image(uiImage: image).resizable().interpolation(.none).accessibilityHidden(true)
        } else {
            Color.black.accessibilityHidden(true)
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
    static func commands(for request: MapTileArtRequest,
                         animationFrame: Int? = nil) -> [PixelCommand] {
        let tile = request.tile
        let grade = request.worldGrade2Descriptor == nil ? request.grade : .neutral
        let palette = palette(for: tile.ground).map { $0.graded(grade) }
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
        TerrainAnimationGrammar.overlay(
            ground: tile.ground, frame: animationFrame, palette: palette, into: &result)
        // Every terrain family is an autotiled area. Cardinal neighbours of the exact same ground
        // suppress this tile's corresponding perimeter; exposed sides and their overlapping corner
        // squares form the familiar 3×3 centre/edge/corner grammar already used by water.
        // The ordinary palette is already world-graded. Only the four authored special edge
        // colours still need grading here; grading the fallback again made exposed stone/soil/etc.
        // diverge from the accepted AssetLab raster whenever the world grade was non-neutral.
        let edge = edgeColour(tile.ground, palette: palette, grade: grade)
        if request.adjacency & 1 == 0 { result.append(rect(0, 0, 16, 2, edge)) }
        if request.adjacency & 2 == 0 { result.append(rect(14, 0, 2, 16, edge)) }
        if request.adjacency & 4 == 0 { result.append(rect(0, 14, 16, 2, edge)) }
        if request.adjacency & 8 == 0 { result.append(rect(0, 0, 2, 16, edge)) }
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
        // Every lifted sprite owns a complete opaque logical footprint. The southern row is drawn
        // later and naturally occludes any face it stands in front of; relying on transparent gaps
        // here leaks the map's black backdrop whenever visibility suppresses that neighbour.
        let exposure = elevation
        if exposure > 0 {
            let wallY = offset + 16
            result.append(rect(0, wallY, 16, exposure, palette[1]))
            result.append(rect(0, wallY, 16, 1, palette[1]))
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

    private static func edgeColour(_ ground: GroundType, palette: [RGB], grade: WorldGrade) -> RGB {
        switch ground {
        case .water: RGB(0x8fc4cc).graded(grade)
        case .deepWater: RGB(0x2e6681).graded(grade)
        case .ice: RGB(0xd9eef2).graded(grade)
        case .chasm: RGB(0x55566a).graded(grade)
        default: palette[0]
        }
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

/// Small, discrete animation vocabulary for terrain. Every phase is derived from immutable map
/// identity, so visible tiles do not pulse in lockstep and rendering never consumes gameplay RNG.
private enum TerrainAnimationGrammar {
    static func isAnimated(_ request: MapTileArtRequest) -> Bool {
        switch request.tile.ground {
        case .water, .deepWater, .ice: true
        case .groundcover: request.atmosphereMotion > 50
        default: false
        }
    }

    static func frame(for request: MapTileArtRequest, tick: Int) -> Int? {
        let offset = Int(phase(mapSeed: request.mapSeed, point: request.point) % 32)
        switch request.tile.ground {
        case .water, .deepWater:
            return (tick + offset) % 4
        case .ice:
            let step = (tick + offset) % 32
            return step < 3 ? step : nil
        case .groundcover where request.atmosphereMotion > 50:
            let quiet = max(6, 18 - request.atmosphereMotion / 8)
            let step = (tick + offset) % quiet
            return step < 3 ? step : nil
        default:
            return nil
        }
    }

    static func overlay(ground: GroundType, frame: Int?, palette: [RGB],
                        into commands: inout [PixelCommand]) {
        guard let frame else { return }
        switch ground {
        case .water, .deepWater:
            let x = (frame * 4 + 1) % 13
            commands += [rect(x, 4, 4, 1, palette[2]),
                         rect((x + 7) % 13, 11, 3, 1, palette[0])]
        case .ice:
            let centre = frame == 0 ? (11, 4) : frame == 1 ? (10, 4) : (11, 3)
            commands += [rect(centre.0, centre.1, 1, 1, palette[2]),
                         rect(centre.0 - 1, centre.1 + 1, 3, 1, palette[2])]
        case .groundcover:
            let lean = frame - 1
            for x in stride(from: 2, to: 15, by: 4) {
                commands += line(x, 14, x + lean, 10 - (x % 3), palette[2])
            }
        default:
            break
        }
    }

    private static func phase(mapSeed: UInt64, point: GridPoint) -> UInt32 {
        let payload = "\(MapAssetContract.animationVersion)|\(mapSeed)|\(point.x)|\(point.y)"
        return payload.utf8.reduce(UInt32(0x811c9dc5)) {
            ($0 ^ UInt32($1)) &* 0x01000193
        }
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

/// Exact decoded pixels from the immutable three-profile Resource Sprite v1 registry.
///
/// Map and inventory deliberately consume different authored profiles. Turning opaque pixels into
/// one-pixel commands lets the existing terrain-first compositor and clipped sheen retain their
/// established ordering without scaling or recoloring either identity.
private enum ResourceSpriteV1PixelGrammar {
    static func commands(for id: ResourceID, profile: ResourceSpriteV1Profile) -> [PixelCommand] {
        guard let asset = ResourceSpriteV1Registry.asset(for: id, profile: profile) else { return [] }
        let pixels = asset.rgbaPixels
        guard pixels.count == asset.width * asset.height * 4 else { return [] }
        var commands: [PixelCommand] = []
        commands.reserveCapacity(asset.width * asset.height / 2)
        for y in 0..<asset.height {
            for x in 0..<asset.width {
                let index = (y * asset.width + x) * 4
                let alpha = pixels[index + 3]
                guard alpha > 0 else { continue }
                commands.append(PixelCommand(
                    x: x, y: y, width: 1, height: 1,
                    color: RGBA(red: pixels[index], green: pixels[index + 1],
                                blue: pixels[index + 2], alpha: alpha)))
            }
        }
        return commands
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

    init(hex: String) throws {
        guard hex.range(of: "^#[0-9a-fA-F]{6}$", options: .regularExpression) != nil else {
            throw WorldGrade2V1.ContractError.invalidHexColor
        }
        red = UInt8(hex.dropFirst(1).prefix(2), radix: 16)!
        green = UInt8(hex.dropFirst(3).prefix(2), radix: 16)!
        blue = UInt8(hex.dropFirst(5).prefix(2), radix: 16)!
        alpha = 255
    }

    fileprivate var hex: String {
        String(format: "#%02x%02x%02x", red, green, blue)
    }
}

@MainActor private enum MapPixelRaster {
    static let cache = NSCache<NSString, UIImage>()
    static let terrainPack: TerrainProductionPack? = {
        guard let pack = try? TerrainProductionPack.bundled() else { return nil }
        do { try pack.open(); return pack } catch { return nil }
    }()
    static let southWallPack: TerrainSouthWallPack? = {
        guard let pack = try? TerrainSouthWallPack.bundled() else { return nil }
        do { try pack.open(); return pack } catch { return nil }
    }()

    static func resourceIdentityImage(for id: ResourceID,
                                      profile: ResourceSpriteV1Profile = .inventory) -> UIImage? {
        let key = "\(ResourceSpriteV1Registry.packID)-\(profile.rawValue)-\(id.rawValue)" as NSString
        if let cached = cache.object(forKey: key) { return cached }
        guard let asset = ResourceSpriteV1Registry.asset(for: id, profile: profile) else {
            return nil
        }
        let commands = ResourceSpriteV1PixelGrammar.commands(for: id, profile: profile)
        guard !commands.isEmpty,
              let image = raster(commands: commands, width: asset.width, height: asset.height) else {
            return nil
        }
        cache.setObject(image, forKey: key)
        return image
    }

    static func image(for request: MapTileArtRequest, reduceMotion: Bool = false) -> UIImage? {
        let descriptor = request.flora.map(FloraRenderDescriptor.init)
        let floraKey = descriptor.map(stableFloraKey) ?? "none"
        guard let grade2 = request.worldGrade2Descriptor,
              let grade2Key = try? WorldGrade2V1.validatedCacheIdentity(grade2) else { return nil }
        let phase = request.resourceID.map { _ in
            ResourcePixelGrammar.phase(mapSeed: request.mapSeed, runIndex: request.runIndex, point: request.point)
        }
        let sheenFrame = reduceMotion ? nil : phase.flatMap {
            ResourcePixelGrammar.frame(phase: $0, tick: request.presentationTick)
        }
        let resourceKey = request.resourceID.map {
            "\(ResourceSpriteV1Registry.packID)-\($0.rawValue)-\(sheenFrame.map(String.init) ?? "rest")"
        } ?? "none"
        let neighbors = TerrainProductionPack.Direction.allCases.map {
            request.cardinalNeighbors[$0].rawValue
        }.joined(separator: ",")
        let contours = TerrainProductionPack.Direction.allCases.map {
            String(request.edgeContourIDs[$0])
        }.joined(separator: ",")
        let shades = TerrainProductionPack.Direction.allCases.map {
            String(request.contactShadeDepths[$0])
        }.joined(separator: ",")
        let motionTick = reduceMotion || request.visibility != .full ? 0 : request.presentationTick
        let key = "\(MapAssetContract.rendererTuple)-\(grade2Key)-\(request.seed)-\(request.point.x),\(request.point.y)-\(request.tile.ground.rawValue)-\(neighbors)-\(contours)-\(shades)-wall-\(request.southWallDepth)-\(request.wallWestContinuation)-\(request.wallEastContinuation)-\(request.visibility.rawValue)-\(request.tile.isRevealed)-\(request.tile.isCrumbled)-\(request.tile.isCracking)-\(request.tile.elevation)-\(request.surfaceDeposits.snow)-\(request.surfaceDeposits.settledAsh)-\(request.atmosphereMotion)-\(motionTick)-\(reduceMotion)-\(floraKey)-\(resourceKey)" as NSString
        if let cached = cache.object(forKey: key) { return cached }
        guard var commands = try? terrainCommands(for: request, reduceMotion: reduceMotion) else {
            return nil
        }
        if request.tile.isRevealed, !request.tile.isCrumbled, let descriptor {
            guard let floraCommands = try? floraCommands(
                descriptor, descriptor: request.worldGrade2Descriptor) else { return nil }
            commands += floraCommands.map {
                PixelCommand(x: $0.x, y: $0.y + request.surfaceOffsetY,
                             width: $0.width, height: $0.height, color: $0.color)
            }
        }
        if request.tile.isRevealed, !request.tile.isCrumbled, let resource = request.resourceID {
            let body = ResourceSpriteV1PixelGrammar.commands(for: resource, profile: .map)
            commands += body.map {
                PixelCommand(x: $0.x, y: $0.y + request.surfaceOffsetY,
                             width: $0.width, height: $0.height, color: $0.color)
            }
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

    fileprivate static func terrainCommands(for request: MapTileArtRequest,
                                             reduceMotion: Bool = false) throws -> [PixelCommand] {
        guard let terrainPack, let descriptor = request.worldGrade2Descriptor else {
            return try legacyTerrainCommands(for: request)
        }
        let rgbaFromPack: [UInt8]
        do {
            let packRequest = try request.terrainRequest(reduceMotion: reduceMotion)
            rgbaFromPack = try terrainPack.regionContinuousRGBA(for: packRequest,
                                                                 descriptor: descriptor)
        } catch {
            // The production pack is presentation, never gameplay authority. A missing or corrupt
            // visual resource must retain the last functional terrain/wall renderer rather than
            // turning known traversable tiles into black, invisible hit targets.
            return try legacyTerrainCommands(for: request)
        }
        var rgba = rgbaFromPack
        applyExternalTerrainTruth(
            tileGround: request.tile.ground, isCrumbled: request.tile.isCrumbled,
            isCracking: request.tile.isCracking,
            contactShadeDepths: request.contactShadeDepths, to: &rgba)
        let top = pixelCommands(rgba).map {
            PixelCommand(x: $0.x, y: $0.y + request.surfaceOffsetY,
                         width: $0.width, height: $0.height, color: $0.color)
        }
        return top + southWallCommands(for: request, descriptor: descriptor,
                                       fallbackTopSurfaceRGBA: rgba)
    }

    fileprivate static func legacyTerrainCommandsForTests(_ request: MapTileArtRequest) throws
        -> [PixelCommand] {
        try legacyTerrainCommands(for: request)
    }

    private static func legacyTerrainCommands(for request: MapTileArtRequest) throws
        -> [PixelCommand] {
        let commands = TerrainPixelGrammar.commands(for: request)
        let recolored: [PixelCommand]
        if request.tile.isRevealed, let descriptor = request.worldGrade2Descriptor {
            try WorldGrade2V1.validateDescriptor(descriptor)
            recolored = try recolor(commands, descriptor: descriptor, scope: .material,
                                    groundType: request.tile.ground.rawValue)
        } else {
            recolored = commands
        }
        let wallY = request.surfaceOffsetY + MapAssetContract.logicalSide
        return recolored.map { command in
            guard command.y >= wallY else { return command }
            var shaded = command
            shaded.color.red = UInt8(Int(shaded.color.red) * 3 / 4)
            shaded.color.green = UInt8(Int(shaded.color.green) * 3 / 4)
            shaded.color.blue = UInt8(Int(shaded.color.blue) * 3 / 4)
            return shaded
        }
    }

    fileprivate static func pixelCommands(_ rgba: [UInt8]) -> [PixelCommand] {
        guard rgba.count == 16 * 16 * 4 else { return [] }
        return (0..<(16 * 16)).map { index in
            let offset = index * 4
            return PixelCommand(x: index % 16, y: index / 16, width: 1, height: 1,
                                color: RGBA(red: rgba[offset], green: rgba[offset + 1],
                                            blue: rgba[offset + 2], alpha: rgba[offset + 3]))
        }
    }

    private static func southWallCommands(
        for request: MapTileArtRequest, descriptor: WorldGrade2V1.Descriptor,
        fallbackTopSurfaceRGBA: [UInt8]
    ) -> [PixelCommand] {
        guard request.southWallDepth > 0 else { return [] }
        if let southWallPack,
           let ground = TerrainProductionPack.Ground(rawValue: request.tile.ground.rawValue),
           let wallRequest = try? TerrainSouthWallPack.Request(
                ground: ground, depth: request.southWallDepth,
                westContinuation: request.wallWestContinuation,
                eastContinuation: request.wallEastContinuation,
                featureVariant: request.featureVariant),
           let rgba = try? southWallPack.rgba(for: wallRequest, descriptor: descriptor) {
            return pixelCommands(width: 16, height: 3, rgba: rgba).map {
                PixelCommand(x: $0.x, y: $0.y + request.surfaceOffsetY + 16,
                             width: $0.width, height: $0.height, color: $0.color)
            }
        }
        // Preserve the proven functional cue if the authored companion pack is unavailable or
        // corrupt. A visual pack failure may never downgrade real height to contact shade alone.
        return externalSouthWallCommands(
            topSurfaceRGBA: fallbackTopSurfaceRGBA, surfaceOffsetY: request.surfaceOffsetY,
            depth: request.southWallDepth)
    }

    private static func pixelCommands(width: Int, height: Int, rgba: [UInt8]) -> [PixelCommand] {
        guard rgba.count == width * height * 4 else { return [] }
        return (0..<(width * height)).compactMap { index in
            let offset = index * 4
            guard rgba[offset + 3] > 0 else { return nil }
            return PixelCommand(x: index % width, y: index / width, width: 1, height: 1,
                                color: RGBA(red: rgba[offset], green: rgba[offset + 1],
                                            blue: rgba[offset + 2], alpha: rgba[offset + 3]))
        }
    }

    /// Functional fallback if the separately authored wall pack is absent or corrupt.
    fileprivate static func externalSouthWallCommands(
        topSurfaceRGBA: [UInt8], surfaceOffsetY: Int, depth: Int
    ) -> [PixelCommand] {
        guard topSurfaceRGBA.count == 16 * 16 * 4 else { return [] }
        let boundedDepth = min(3, max(0, depth))
        guard boundedDepth > 0 else { return [] }
        var result: [PixelCommand] = []
        for row in 0..<boundedDepth { for x in 0..<16 {
            let source = (15 * 16 + x) * 4
            let color = RGBA(
                red: UInt8(Int(topSurfaceRGBA[source]) * 3 / 4),
                green: UInt8(Int(topSurfaceRGBA[source + 1]) * 3 / 4),
                blue: UInt8(Int(topSurfaceRGBA[source + 2]) * 3 / 4), alpha: 255)
            result.append(PixelCommand(x: x, y: surfaceOffsetY + 16 + row,
                                       width: 1, height: 1, color: color))
        }}
        return result
    }

    fileprivate static func applyExternalTerrainTruth(
        tileGround: GroundType, isCrumbled: Bool, isCracking: Bool,
        contactShadeDepths: TerrainProductionPack.Cardinal<Int>, to rgba: inout [UInt8]
    ) {
        guard rgba.count == 16 * 16 * 4 else { return }
        if isCrumbled {
            let accepted = rgba
            for index in 0..<(16 * 16) { write(0x09, 0x09, 0x0c, at: index, to: &rgba) }
            for y in 0..<2 { for x in 0..<4 { copy(index: y * 16 + x, from: accepted, to: &rgba) } }
            for y in 14..<16 { for x in 12..<16 { copy(index: y * 16 + x, from: accepted, to: &rgba) } }
        } else if isCracking {
            let dark = line(7, 1, 9, 7, 0x171116) + line(9, 7, 5, 14, 0x171116)
            let glow = line(8, 1, 10, 7, 0xf0a84e) + line(10, 7, 6, 14, 0xf0a84e)
            for command in dark + glow {
                for y in max(0, command.y)..<min(16, command.y + command.height) {
                    for x in max(0, command.x)..<min(16, command.x + command.width) {
                        let c = command.color
                        write(c.red, c.green, c.blue, at: y * 16 + x, to: &rgba)
                    }
                }
            }
        }
        for direction in TerrainProductionPack.Direction.allCases {
            let depth = min(2, max(0, contactShadeDepths[direction]))
            guard depth > 0 else { continue }
            for y in 0..<16 { for x in 0..<16 {
                let touches = switch direction {
                case .north: y < depth
                case .east: x >= 16 - depth
                case .south: y >= 16 - depth
                case .west: x < depth
                }
                guard touches else { continue }
                let offset = (y * 16 + x) * 4
                rgba[offset] = UInt8(Int(rgba[offset]) * 3 / 4)
                rgba[offset + 1] = UInt8(Int(rgba[offset + 1]) * 3 / 4)
                rgba[offset + 2] = UInt8(Int(rgba[offset + 2]) * 3 / 4)
            }}
        }
    }

    private static func write(_ red: UInt8, _ green: UInt8, _ blue: UInt8,
                              at index: Int, to rgba: inout [UInt8]) {
        let offset = index * 4
        rgba[offset] = red; rgba[offset + 1] = green; rgba[offset + 2] = blue
        rgba[offset + 3] = 255
    }

    private static func copy(index: Int, from source: [UInt8], to target: inout [UInt8]) {
        let offset = index * 4
        target[offset] = source[offset]; target[offset + 1] = source[offset + 1]
        target[offset + 2] = source[offset + 2]; target[offset + 3] = source[offset + 3]
    }

    fileprivate static func floraCommands(_ flora: FloraRenderDescriptor,
                                           descriptor: WorldGrade2V1.Descriptor?) throws -> [PixelCommand] {
        let commands = FloraPixelGrammar.commands(for: flora)
        guard let descriptor else { return commands }
        try WorldGrade2V1.validateDescriptor(descriptor)
        guard descriptor.flora.cast.contains(where: { $0.speciesID == flora.logicalID }) else {
            throw WorldGrade2V1.ContractError.unknownFloraSpeciesColor
        }
        return try recolor(commands, descriptor: descriptor, scope: .flora,
                           speciesID: flora.logicalID)
    }

    private static func recolor(_ commands: [PixelCommand],
                                descriptor: WorldGrade2V1.Descriptor,
                                scope: WorldGrade2V1.ColorScope,
                                groundType: String? = nil,
                                speciesID: String? = nil) throws -> [PixelCommand] {
        let portable = commands.map {
            WorldGrade2V1.RectangleCommand(op: "rect", x: $0.x, y: $0.y,
                                           w: $0.width, h: $0.height,
                                           color: $0.color.hex)
        }
        let graded = try WorldGrade2V1.recolor(portable, descriptor: descriptor, scope: scope,
                                               groundType: groundType, speciesID: speciesID)
        return try zip(graded, commands).map { pair in
            let (graded, original) = pair
            var color = try RGBA(hex: graded.color)
            color.alpha = original.color.alpha
            return PixelCommand(x: graded.x, y: graded.y, width: graded.w, height: graded.h,
                                color: color)
        }
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
