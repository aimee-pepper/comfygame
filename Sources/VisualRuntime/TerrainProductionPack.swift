import CoreFoundation
import CryptoKit
import Foundation
import ImageIO

/// Strict native consumer for the immutable TerrainProductionPack-v1 runtime folder.
///
/// The pack owns reviewed semantic masks and pressure-recolorable palettes. Gameplay continues to
/// own terrain facts, visibility, elevation, deposits, and the shared presentation tick.
final class TerrainProductionPack: @unchecked Sendable {
    static let identity = "TerrainProductionPack-v1"
    static let manifestSHA256 = "332cfc692758564e01ed7c134334c9f46c76156388e6dccc9722c7cdcad3e20f"
    static let bodySHA256 = "ecb748ba46582bd432e7eba7cfc5494fd8ea8badcf3a8652d24c7a533d8e8336"
    static let assetAggregateSHA256 = "8fb84f80a3eb82c84c0baa285800cad51fc1107c93ec748a23c1f0f6eb489272"
    static let acceptedVisualCommit = "5bac76a9"
    static let acceptedVisualBodySHA256 = "2a541033b71b638f1803e5a9477a0197c38f38d96ff199a4864d49bf551608dd"
    static let acceptedVisualManifestSHA256 = "5e70b17c91c8601ed895455364f2cd8a51e010e2cb2201f09dc2c02c826f3892"
    static let acceptedProductionAggregateSHA256 = "90da0b9ed6092b591bcad83fbda68b0563de9c2ba37127911772c41418657a54"

    enum PackError: Error, Equatable {
        case unavailable
        case invalidManifest
        case unsupportedVersion
        case invalidRequest
        case unknownDescriptor(String)
        case missingAsset(String)
        case corruptAsset(String)
        case invalidSemanticMask(String)
    }

    enum Ground: String, CaseIterable, Sendable {
        case stone, soil, sand, ice, ash, water, deepWater, rubble, mud, growth, chasm, groundcover

        init(_ ground: GroundType) {
            self = Ground(rawValue: ground.rawValue)!
        }
    }

    enum Direction: String, CaseIterable, Sendable { case north, east, south, west }
    enum Visibility: String, CaseIterable, Sendable { case full, fringe, remembered }
    enum MotionBand: String, CaseIterable, Sendable { case calm, moving, strong }

    enum Neighbor: Equatable, Sendable {
        case same
        case unknown
        case ground(Ground)

        fileprivate init?(rawValue: String) {
            if rawValue == "same" { self = .same }
            else if rawValue == "unknown" { self = .unknown }
            else if let ground = Ground(rawValue: rawValue) { self = .ground(ground) }
            else { return nil }
        }

        var rawValue: String {
            switch self {
            case .same: "same"
            case .unknown: "unknown"
            case .ground(let ground): ground.rawValue
            }
        }
    }

    struct Cardinal<Value: Equatable & Sendable>: Equatable, Sendable {
        var north: Value
        var east: Value
        var south: Value
        var west: Value

        subscript(_ direction: Direction) -> Value {
            get {
                switch direction {
                case .north: north
                case .east: east
                case .south: south
                case .west: west
                }
            }
            set {
                switch direction {
                case .north: north = newValue
                case .east: east = newValue
                case .south: south = newValue
                case .west: west = newValue
                }
            }
        }
    }

    struct SurfaceDeposits: Equatable, Sendable {
        var snow: Bool
        var settledAsh: Bool

        static let none = SurfaceDeposits(snow: false, settledAsh: false)
    }

    struct Request: Equatable, Sendable {
        static let schemaVersion = "terrain-layers-v2"

        var ground: Ground
        var point: GridPoint
        var visualSeed: UInt64
        var worldGradeDescriptorHash: String
        var featureVariant: Int
        var cardinalNeighbors: Cardinal<Neighbor>
        var edgeContourIDs: Cardinal<Int>
        var elevation: Int
        var isCrumbled: Bool
        var isCracking: Bool
        var visibility: Visibility
        var motionBand: MotionBand
        var phaseOffset: Int
        var presentationTick: Int
        var reduceMotion: Bool
        var surfaceDeposits: SurfaceDeposits

        init(ground: Ground, point: GridPoint, visualSeed: UInt64,
             worldGradeDescriptorHash: String, featureVariant: Int,
             cardinalNeighbors: Cardinal<Neighbor>, edgeContourIDs: Cardinal<Int>, elevation: Int,
             isCrumbled: Bool, isCracking: Bool, visibility: Visibility, motionBand: MotionBand,
             phaseOffset: Int, presentationTick: Int, reduceMotion: Bool,
             surfaceDeposits: SurfaceDeposits) throws {
            guard !worldGradeDescriptorHash.isEmpty,
                  (0...3).contains(featureVariant), (0...3).contains(elevation),
                  (0...23).contains(phaseOffset), presentationTick >= 0,
                  Direction.allCases.allSatisfy({ (0...3).contains(edgeContourIDs[$0]) })
            else { throw PackError.invalidRequest }
            self.ground = ground; self.point = point; self.visualSeed = visualSeed
            self.worldGradeDescriptorHash = worldGradeDescriptorHash
            self.featureVariant = featureVariant; self.cardinalNeighbors = cardinalNeighbors
            self.edgeContourIDs = edgeContourIDs; self.elevation = elevation
            self.isCrumbled = isCrumbled; self.isCracking = isCracking
            self.visibility = visibility; self.motionBand = motionBand
            self.phaseOffset = phaseOffset; self.presentationTick = presentationTick
            self.reduceMotion = reduceMotion; self.surfaceDeposits = surfaceDeposits
        }

        fileprivate init(json: [String: Any]) throws {
            try Self.exactKeys(json, ["schemaVersion", "ground", "point", "visualSeed",
                "worldGradeDescriptorHash", "featureVariant", "cardinalNeighbors", "edgeContourIDs",
                "elevation", "isCrumbled", "isCracking", "visibility", "motionBand", "phaseOffset",
                "presentationTick", "reduceMotion", "surfaceDeposits"])
            guard json["schemaVersion"] as? String == Self.schemaVersion,
                  let groundRaw = json["ground"] as? String, let ground = Ground(rawValue: groundRaw),
                  let point = json["point"] as? [String: Any],
                  let x = Self.integer(point["x"]), let y = Self.integer(point["y"]),
                  let seed = Self.unsignedInteger(json["visualSeed"]),
                  let descriptorHash = json["worldGradeDescriptorHash"] as? String,
                  let featureVariant = Self.integer(json["featureVariant"]),
                  let neighborObject = json["cardinalNeighbors"] as? [String: Any],
                  let contourObject = json["edgeContourIDs"] as? [String: Any],
                  let elevation = Self.integer(json["elevation"]),
                  let isCrumbled = json["isCrumbled"] as? Bool,
                  let isCracking = json["isCracking"] as? Bool,
                  let visibilityRaw = json["visibility"] as? String,
                  let visibility = Visibility(rawValue: visibilityRaw),
                  let motionRaw = json["motionBand"] as? String,
                  let motionBand = MotionBand(rawValue: motionRaw),
                  let phaseOffset = Self.integer(json["phaseOffset"]),
                  let presentationTick = Self.integer(json["presentationTick"]),
                  let reduceMotion = json["reduceMotion"] as? Bool,
                  let deposits = json["surfaceDeposits"] as? [String: Any],
                  let snow = deposits["snow"] as? Bool,
                  let settledAsh = deposits["settledAsh"] as? Bool
            else { throw PackError.invalidRequest }
            try Self.exactKeys(point, ["x", "y"])
            try Self.exactKeys(neighborObject, Direction.allCases.map(\.rawValue))
            try Self.exactKeys(contourObject, Direction.allCases.map(\.rawValue))
            try Self.exactKeys(deposits, ["snow", "settledAsh"])
            func neighbor(_ direction: Direction) throws -> Neighbor {
                guard let raw = neighborObject[direction.rawValue] as? String,
                      let value = Neighbor(rawValue: raw) else { throw PackError.invalidRequest }
                return value
            }
            func contour(_ direction: Direction) throws -> Int {
                guard let value = Self.integer(contourObject[direction.rawValue]) else {
                    throw PackError.invalidRequest
                }
                return value
            }
            try self.init(
                ground: ground, point: GridPoint(x: x, y: y), visualSeed: seed,
                worldGradeDescriptorHash: descriptorHash, featureVariant: featureVariant,
                cardinalNeighbors: .init(north: try neighbor(.north), east: try neighbor(.east),
                                            south: try neighbor(.south), west: try neighbor(.west)),
                edgeContourIDs: .init(north: try contour(.north), east: try contour(.east),
                                      south: try contour(.south), west: try contour(.west)),
                elevation: elevation, isCrumbled: isCrumbled, isCracking: isCracking,
                visibility: visibility, motionBand: motionBand, phaseOffset: phaseOffset,
                presentationTick: presentationTick, reduceMotion: reduceMotion,
                surfaceDeposits: .init(snow: snow, settledAsh: settledAsh))
        }

        private static func exactKeys(_ object: [String: Any], _ expected: [String]) throws {
            guard Set(object.keys) == Set(expected) else { throw PackError.invalidRequest }
        }

        private static func integer(_ value: Any?) -> Int? {
            guard let number = value as? NSNumber,
                  CFGetTypeID(number) != CFBooleanGetTypeID() else { return nil }
            let double = number.doubleValue
            guard double.isFinite, double.rounded(.towardZero) == double,
                  abs(double) <= 9_007_199_254_740_991,
                  double >= Double(Int.min), double <= Double(Int.max) else { return nil }
            return Int(double)
        }

        private static func unsignedInteger(_ value: Any?) -> UInt64? {
            guard let integer = integer(value), integer >= 0 else { return nil }
            return UInt64(integer)
        }
    }

    struct ConformanceCase: Sendable {
        var id: String
        var request: Request
        var roleSHA256: String
        var motionSHA256: String
        var rgbaSHA256: String
    }

    private struct Asset: Equatable {
        var path: String
        var sha256: String
        var width: Int
        var height: Int
        var kind: String
    }

    private struct PaletteRow {
        var fixtureID: String
        var roles: [String: [RGBA]]
    }

    private struct OpenState {
        var assets: [String: Asset]
        var assetData: [String: Data]
        var roleMaps: [String: [Int8]]
        var motionMasks: [String: [Bool]]
        var edgeMasks: [String: [Bool]]
        var palettes: [String: PaletteRow]
        var cases: [ConformanceCase]
    }

    private let rootURL: URL
    private let read: @Sendable (URL) throws -> Data
    private let lock = NSLock()
    private var state: OpenState?

    init(rootURL: URL, read: @escaping @Sendable (URL) throws -> Data = { try Data(contentsOf: $0) }) {
        self.rootURL = rootURL
        self.read = read
    }

    static func bundled(in bundle: Bundle = .main) throws -> TerrainProductionPack {
        let root = bundle.bundleURL.appendingPathComponent(Self.identity, isDirectory: true)
        guard FileManager.default.isReadableFile(
            atPath: root.appendingPathComponent("manifest.json").path) else {
            throw PackError.unavailable
        }
        return TerrainProductionPack(rootURL: root)
    }

    func open() throws {
        lock.lock(); defer { lock.unlock() }
        if state != nil { return }
        let manifestData: Data
        do { manifestData = try read(rootURL.appendingPathComponent("manifest.json")) }
        catch { throw PackError.unavailable }
        guard Self.sha256(manifestData) == Self.manifestSHA256,
              let root = try JSONSerialization.jsonObject(with: manifestData) as? [String: Any]
        else { throw PackError.invalidManifest }
        try Self.validateRoot(root)
        let assets = try Self.assets(root["assets"])
        var bytesByHash: [String: Data] = [:]
        for asset in assets.values where bytesByHash[asset.sha256] == nil {
            let data: Data
            do { data = try read(rootURL.appendingPathComponent(asset.path)) }
            catch { throw PackError.missingAsset(asset.path) }
            guard Self.sha256(data) == asset.sha256 else { throw PackError.corruptAsset(asset.path) }
            bytesByHash[asset.sha256] = data
        }
        let palettes = try Self.palettes(root["pressurePalettes"])
        let cases = try Self.cases(root["cases"])
        let roleMaps = try Self.roleMaps(assets: assets, data: bytesByHash)
        let motionMasks = try Self.motionMasks(assets: assets, data: bytesByHash)
        let edgeMasks = try Self.edgeMasks(assets: assets, data: bytesByHash)
        state = OpenState(assets: assets, assetData: bytesByHash, roleMaps: roleMaps,
                          motionMasks: motionMasks, edgeMasks: edgeMasks,
                          palettes: palettes, cases: cases)
    }

    var conformanceCases: [ConformanceCase] {
        get throws {
            try open()
            lock.lock(); defer { lock.unlock() }
            return state?.cases ?? []
        }
    }

    /// Renders only pack-owned layers. Cracking, crumbled truth, and genuine-height contact shade
    /// remain external by contract and are composed by `MapAssetRenderer` afterward.
    func rgba(for request: Request, descriptor: WorldGrade2V1.Descriptor? = nil) throws -> [UInt8] {
        try open()
        lock.lock(); defer { lock.unlock() }
        guard let state else { throw PackError.unavailable }
        let palette = try Self.palette(for: request, descriptor: descriptor, rows: state.palettes)
        let roles = try Self.composeRoles(request, roleMaps: state.roleMaps, edgeMasks: state.edgeMasks)
        var rgba = Self.recolor(roles, palette: try Self.groundPalette(request.ground.rawValue, in: palette))

        let step = Self.motionStep(ground: request.ground, band: request.motionBand)
        if request.visibility == .full, !request.reduceMotion, step > 0 {
            let phase = (request.phaseOffset + (request.presentationTick % 24) / step
                         + request.featureVariant) % 4
            let key = "accepted/motion/\(request.ground.rawValue)-phase-\(phase)-16x16.png"
            guard let mask = state.motionMasks[key] else { throw PackError.missingAsset(key) }
            let highlight = try Self.groundPalette(request.ground.rawValue, in: palette)[4]
            for index in mask.indices where mask[index] { rgba.replace(at: index, with: highlight) }
        }

        if ![Ground.water, .deepWater, .chasm].contains(request.ground) {
            guard let snowRoles = state.roleMaps["snow"] else {
                throw PackError.invalidSemanticMask("snow")
            }
            var occupied = [Bool](repeating: false, count: 256)
            var count = 0
            let limit = 179
            func apply(_ enabled: Bool, variantOffset: Int, paletteKey: String) throws {
                guard enabled else { return }
                let colors = try Self.groundPalette(paletteKey, in: palette)
                for y in 0..<16 { for x in 0..<16 {
                    let index = y * 16 + x
                    let role = Self.macroRole(snowRoles, point: request.point, x: x, y: y,
                                              featureVariant: request.featureVariant + variantOffset)
                    guard role >= 0, !occupied[index], count < limit else { continue }
                    rgba.replace(at: index, with: colors[Int(role)])
                    occupied[index] = true; count += 1
                }}
            }
            try apply(request.surfaceDeposits.snow, variantOffset: 0, paletteKey: "snow")
            try apply(request.surfaceDeposits.settledAsh, variantOffset: 1, paletteKey: "coverAsh")
        }
        return rgba
    }

    static func resolvedGroundPalette(_ ground: Ground,
                                      descriptor: WorldGrade2V1.Descriptor) throws -> [RGBA] {
        try WorldGrade2V1.validateDescriptor(descriptor)
        guard let colors = baseRoleColors[ground.rawValue] else {
            throw PackError.invalidRequest
        }
        return try colors.map {
            try RGBA(hex: WorldGrade2V1.color($0, descriptor: descriptor,
                                             scope: .material, groundType: ground.rawValue))
        }
    }

    private static func validateRoot(_ root: [String: Any]) throws {
        let exact = ["schemaVersion", "integrationReady", "status", "acceptedVisual",
                     "runtimeContract", "pressurePalettes", "assets", "cases",
                     "assetAggregateSHA256", "canonicalBodySHA256"]
        guard Set(root.keys) == Set(exact),
              root["schemaVersion"] as? String == "terrain-production-pack-v1",
              root["integrationReady"] as? Bool == false,
              root["status"] as? String == "mechanical-pack-review",
              root["canonicalBodySHA256"] as? String == bodySHA256,
              root["assetAggregateSHA256"] as? String == assetAggregateSHA256,
              let accepted = root["acceptedVisual"] as? [String: Any],
              Set(accepted.keys) == Set(["commit", "bodySHA256", "manifestSHA256",
                                        "productionAggregateSHA256"]),
              accepted["commit"] as? String == acceptedVisualCommit,
              accepted["bodySHA256"] as? String == acceptedVisualBodySHA256,
              accepted["manifestSHA256"] as? String == acceptedVisualManifestSHA256,
              accepted["productionAggregateSHA256"] as? String == acceptedProductionAggregateSHA256,
              let contract = root["runtimeContract"] as? [String: Any]
        else { throw PackError.invalidManifest }
        let contractKeys = ["requestSchemaVersion", "tile", "macro", "grounds", "semanticRoles",
                            "edgeDirections", "edgeContourIDs", "visibility", "hidden", "motionBands",
                            "phaseOffset", "elevation", "layerOrder", "surfaceDeposits",
                            "externalLayers", "unknownKeys", "placeholderFallback"]
        guard Set(contract.keys) == Set(contractKeys),
              contract["requestSchemaVersion"] as? String == Request.schemaVersion,
              contract["tile"] as? [Int] == [16, 16], contract["macro"] as? [Int] == [64, 64],
              contract["grounds"] as? [String] == Ground.allCases.map(\.rawValue),
              contract["semanticRoles"] as? [String] == semanticRoles,
              contract["edgeDirections"] as? [String] == Direction.allCases.map(\.rawValue),
              contract["edgeContourIDs"] as? [Int] == [0, 1, 2, 3],
              contract["visibility"] as? [String] == Visibility.allCases.map(\.rawValue),
              contract["hidden"] as? String == "no-request",
              contract["motionBands"] as? [String] == MotionBand.allCases.map(\.rawValue),
              contract["phaseOffset"] as? [Int] == [0, 23],
              contract["elevation"] as? [Int] == [0, 3],
              contract["layerOrder"] as? [String] == layerOrder,
              contract["externalLayers"] as? [String] == ["cracking", "crumbled",
                                                               "genuineElevationContactShade"],
              contract["unknownKeys"] as? String == "failClosed",
              contract["placeholderFallback"] as? Bool == false,
              let deposits = contract["surfaceDeposits"] as? [String: Any],
              Set(deposits.keys) == Set(["keys", "independent", "order"]),
              deposits["keys"] as? [String] == ["snow", "settledAsh"],
              deposits["independent"] as? Bool == true,
              deposits["order"] as? [String] == ["snow", "settledAsh"]
        else { throw PackError.unsupportedVersion }
    }

    private static func assets(_ value: Any?) throws -> [String: Asset] {
        guard let rows = value as? [String: [String: Any]] else { throw PackError.invalidManifest }
        var expected = Set<String>()
        for ground in Ground.allCases {
            expected.insert("accepted/macro/\(ground.rawValue)-semantic-64x64.png")
        }
        expected.insert("accepted/macro/snow-cover-semantic-64x64.png")
        for ground in Ground.allCases.map(\.rawValue) + ["snow"] {
            for role in semanticRoles { expected.insert("accepted/roles/\(ground)-\(role)-mask-64x64.png") }
        }
        for ground in ["water", "deepWater", "groundcover", "growth"] {
            for phase in 0..<4 { expected.insert("accepted/motion/\(ground)-phase-\(phase)-16x16.png") }
        }
        for direction in Direction.allCases {
            for contour in 0..<4 { expected.insert("edge/\(direction.rawValue)/\(contour)") }
        }
        guard Set(rows.keys) == expected, rows.count == 110 else { throw PackError.invalidManifest }
        var result: [String: Asset] = [:]
        for (key, row) in rows {
            guard Set(row.keys) == Set(["path", "sha256", "width", "height", "kind"]),
                  let path = row["path"] as? String, let hash = row["sha256"] as? String,
                  let width = row["width"] as? Int, let height = row["height"] as? Int,
                  let kind = row["kind"] as? String,
                  hash.range(of: "^[0-9a-f]{64}$", options: .regularExpression) != nil,
                  path == "assets/\(hash).png", !path.contains(".."),
                  ["macro", "roles", "motion", "edgeMask"].contains(kind),
                  ((kind == "macro" || kind == "roles")
                    ? (width == 64 && height == 64)
                    : (width == 16 && height == 16))
            else { throw PackError.invalidManifest }
            result[key] = Asset(path: path, sha256: hash, width: width, height: height, kind: kind)
        }
        let aggregate = result.sorted(by: { $0.key < $1.key })
            .map { "\($0.key):\($0.value.sha256)" }.joined(separator: "\n")
        guard sha256(Data(aggregate.utf8)) == assetAggregateSHA256 else {
            throw PackError.invalidManifest
        }
        return result
    }

    private static func palettes(_ value: Any?) throws -> [String: PaletteRow] {
        guard let object = value as? [String: Any],
              Set(object.keys) == Set(["authority", "selection", "rows"]),
              object["authority"] as? String == "world-grade-2-v1",
              object["selection"] as? String == "worldGradeDescriptorHash-only",
              let rows = object["rows"] as? [String: [String: Any]], rows.count == 3
        else { throw PackError.invalidManifest }
        let roleKeys = Set(Ground.allCases.map(\.rawValue) + ["snow", "coverAsh"])
        var result: [String: PaletteRow] = [:]
        for (hash, row) in rows {
            guard hash.range(of: "^[0-9a-f]{64}$", options: .regularExpression) != nil,
                  Set(row.keys) == Set(["fixtureID", "roles"]),
                  let fixtureID = row["fixtureID"] as? String,
                  ["identical-a", "opposed-warm", "opposed-cool"].contains(fixtureID),
                  let roleObject = row["roles"] as? [String: [String]],
                  Set(roleObject.keys) == roleKeys else { throw PackError.invalidManifest }
            var roles: [String: [RGBA]] = [:]
            for (ground, colors) in roleObject {
                guard colors.count == 5 else { throw PackError.invalidManifest }
                roles[ground] = try colors.map(RGBA.init(hex:))
            }
            result[hash] = PaletteRow(fixtureID: fixtureID, roles: roles)
        }
        return result
    }

    private static func cases(_ value: Any?) throws -> [ConformanceCase] {
        guard let rows = value as? [[String: Any]], rows.count == 149 else {
            throw PackError.invalidManifest
        }
        let hashPattern = "^[0-9a-f]{64}$"
        var identifiers = Set<String>(), result: [ConformanceCase] = []
        for row in rows {
            guard Set(row.keys) == Set(["id", "request", "orderedLayers", "externalLayers",
                                       "roleSHA256", "motionSHA256", "rgbaSHA256"]),
                  let id = row["id"] as? String, !id.isEmpty, identifiers.insert(id).inserted,
                  let requestObject = row["request"] as? [String: Any],
                  row["orderedLayers"] as? [String] == layerOrder,
                  let external = row["externalLayers"] as? [String: Any],
                  Set(external.keys) == Set(["cracking", "crumbled", "genuineElevationContactShade"]),
                  external["genuineElevationContactShade"] as? String == "external-not-owned",
                  let role = row["roleSHA256"] as? String,
                  let motion = row["motionSHA256"] as? String,
                  let rgba = row["rgbaSHA256"] as? String,
                  role.range(of: hashPattern, options: .regularExpression) != nil,
                  motion.range(of: hashPattern, options: .regularExpression) != nil,
                  rgba.range(of: hashPattern, options: .regularExpression) != nil
            else { throw PackError.invalidManifest }
            let request = try Request(json: requestObject)
            guard external["cracking"] as? Bool == request.isCracking,
                  external["crumbled"] as? Bool == request.isCrumbled else {
                throw PackError.invalidManifest
            }
            result.append(.init(id: id, request: request, roleSHA256: role,
                                motionSHA256: motion, rgbaSHA256: rgba))
        }
        return result
    }

    private static func roleMaps(assets: [String: Asset], data: [String: Data]) throws -> [String: [Int8]] {
        var result: [String: [Int8]] = [:]
        for ground in Ground.allCases.map(\.rawValue) + ["snow"] {
            var map = [Int8](repeating: -1, count: 64 * 64)
            for (role, roleName) in semanticRoles.enumerated() {
                let key = "accepted/roles/\(ground)-\(roleName)-mask-64x64.png"
                guard let asset = assets[key], let bytes = data[asset.sha256] else {
                    throw PackError.missingAsset(key)
                }
                let mask = try alphaMask(bytes, width: 64, height: 64, key: key)
                for index in mask.indices where mask[index] {
                    guard map[index] == -1 else { throw PackError.invalidSemanticMask(key) }
                    map[index] = Int8(role)
                }
            }
            if ground == "snow" {
                guard map.contains(where: { $0 == -1 }), map.contains(where: { $0 >= 2 }) else {
                    throw PackError.invalidSemanticMask(ground)
                }
            } else if map.contains(-1) {
                throw PackError.invalidSemanticMask(ground)
            }
            result[ground] = map
        }
        return result
    }

    private static func motionMasks(assets: [String: Asset], data: [String: Data]) throws -> [String: [Bool]] {
        var result: [String: [Bool]] = [:]
        for ground in ["water", "deepWater", "groundcover", "growth"] {
            for phase in 0..<4 {
                let key = "accepted/motion/\(ground)-phase-\(phase)-16x16.png"
                guard let asset = assets[key], let bytes = data[asset.sha256] else {
                    throw PackError.missingAsset(key)
                }
                let decoded = try alphaMask(bytes, width: 16, height: 16, key: key)
                // CGImage drawing uses Quartz's lower-left image space for these transparent
                // overlays. Normalize motion assets to the pack's top-left logical raster.
                result[key] = (0..<16).flatMap { y in
                    Array(decoded[((15 - y) * 16)..<((16 - y) * 16)])
                }
            }
        }
        return result
    }

    private static func edgeMasks(assets: [String: Asset], data: [String: Data]) throws -> [String: [Bool]] {
        var result: [String: [Bool]] = [:]
        for direction in Direction.allCases { for contour in 0..<4 {
            let key = "edge/\(direction.rawValue)/\(contour)"
            guard let asset = assets[key], let bytes = data[asset.sha256] else {
                throw PackError.missingAsset(key)
            }
            result[key] = try alphaMask(bytes, width: 16, height: 16, key: key)
        }}
        return result
    }

    private static func alphaMask(_ data: Data, width: Int, height: Int, key: String) throws -> [Bool] {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil),
              image.width == width, image.height == height,
              let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
            throw PackError.corruptAsset(key)
        }
        var rgba = [UInt8](repeating: 0, count: width * height * 4)
        let drew = rgba.withUnsafeMutableBytes { buffer -> Bool in
            guard let base = buffer.baseAddress,
                  let context = CGContext(data: base, width: width, height: height,
                                          bitsPerComponent: 8, bytesPerRow: width * 4,
                                          space: colorSpace,
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                                            | CGBitmapInfo.byteOrder32Big.rawValue) else { return false }
            context.interpolationQuality = .none
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard drew else { throw PackError.corruptAsset(key) }
        return stride(from: 3, to: rgba.count, by: 4).map { rgba[$0] > 0 }
    }

    private static func composeRoles(_ request: Request, roleMaps: [String: [Int8]],
                                     edgeMasks: [String: [Bool]]) throws -> [Int8] {
        guard let base = roleMaps[request.ground.rawValue] else {
            throw PackError.invalidSemanticMask(request.ground.rawValue)
        }
        var result = [Int8](repeating: 0, count: 256)
        for y in 0..<16 { for x in 0..<16 {
            result[y * 16 + x] = macroRole(base, point: request.point, x: x, y: y,
                                           featureVariant: request.featureVariant)
        }}
        for direction in Direction.allCases {
            guard case .ground(let neighbor) = request.cardinalNeighbors[direction],
                  neighbor != request.ground,
                  let neighborRoles = roleMaps[neighbor.rawValue] else { continue }
            let depthContour = request.ground == .deepWater && neighbor == .water
            let accepts = (request.ground == .groundcover && neighbor == .growth)
                || priority[neighbor, default: 0] > priority[request.ground, default: 0]
            guard depthContour || accepts else { continue }
            let key = "edge/\(direction.rawValue)/\(request.edgeContourIDs[direction])"
            guard let mask = edgeMasks[key] else { throw PackError.missingAsset(key) }
            for y in 0..<16 { for x in 0..<16 {
                let index = y * 16 + x
                guard mask[index] else { continue }
                let role = macroRole(neighborRoles, point: request.point, x: x, y: y,
                                     featureVariant: request.featureVariant)
                result[index] = depthContour ? max(3, result[index]) : role
            }}
        }
        return result
    }

    private static func macroRole(_ map: [Int8], point: GridPoint, x: Int, y: Int,
                                  featureVariant: Int) -> Int8 {
        let blockX = floorDivision(point.x, 4), blockY = floorDivision(point.y, 4)
        let macroX = positiveModulo(point.x, 4), macroY = positiveModulo(point.y, 4)
        let flipX = positiveModulo(blockX + featureVariant, 2) == 1
        let flipY = positiveModulo(blockY + (featureVariant >> 1), 2) == 1
        let sourceX = flipX ? 63 - (macroX * 16 + x) : macroX * 16 + x
        let sourceY = flipY ? 63 - (macroY * 16 + y) : macroY * 16 + y
        return map[sourceY * 64 + sourceX]
    }

    private static func palette(for request: Request, descriptor: WorldGrade2V1.Descriptor?,
                                rows: [String: PaletteRow]) throws -> [String: [RGBA]] {
        if let descriptor {
            try WorldGrade2V1.validateDescriptor(descriptor)
            guard descriptor.canonicalDescriptorSHA256 == request.worldGradeDescriptorHash else {
                throw PackError.unknownDescriptor(request.worldGradeDescriptorHash)
            }
            var result: [String: [RGBA]] = [:]
            for (ground, colors) in baseRoleColors {
                let owner = ground == "snow" ? "ice" : ground == "coverAsh" ? "ash" : ground
                result[ground] = try colors.map {
                    try RGBA(hex: WorldGrade2V1.color($0, descriptor: descriptor,
                                                     scope: .material, groundType: owner))
                }
            }
            return result
        }
        guard let row = rows[request.worldGradeDescriptorHash] else {
            throw PackError.unknownDescriptor(request.worldGradeDescriptorHash)
        }
        return row.roles
    }

    private static func groundPalette(_ ground: String, in palette: [String: [RGBA]]) throws -> [RGBA] {
        guard let colors = palette[ground], colors.count == 5 else { throw PackError.invalidManifest }
        return colors
    }

    private static func recolor(_ roles: [Int8], palette: [RGBA]) -> [UInt8] {
        var result = [UInt8](repeating: 0, count: roles.count * 4)
        for (index, role) in roles.enumerated() { result.replace(at: index, with: palette[Int(role)]) }
        return result
    }

    private static func motionStep(ground: Ground, band: MotionBand) -> Int {
        switch ground {
        case .water:
            switch band { case .calm: 4; case .moving: 2; case .strong: 1 }
        case .deepWater:
            switch band { case .calm: 6; case .moving: 3; case .strong: 2 }
        case .groundcover, .growth:
            switch band { case .calm: 0; case .moving: 4; case .strong: 2 }
        default: 0
        }
    }

    private static func floorDivision(_ value: Int, _ divisor: Int) -> Int {
        value >= 0 ? value / divisor : -((-value + divisor - 1) / divisor)
    }

    private static func positiveModulo(_ value: Int, _ divisor: Int) -> Int {
        let remainder = value % divisor
        return remainder >= 0 ? remainder : remainder + divisor
    }

    private static func sha256(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    private static let semanticRoles = ["deepShadow", "bodyDark", "body", "bodyLight", "highlight"]
    private static let layerOrder = ["baseMacro", "cardinalEdges", "motion", "snowDeposit", "ashDeposit"]
    private static let priority: [Ground: Int] = [
        .chasm: 0, .deepWater: 1, .water: 2, .stone: 3, .ice: 3, .rubble: 3,
        .soil: 4, .sand: 4, .ash: 4, .mud: 4, .groundcover: 5, .growth: 6,
    ]
    private static let baseRoleColors: [String: [String]] = [
        "stone": ["#282e30", "#495153", "#6d7674", "#929a94", "#c0c4b8"],
        "soil": ["#36261e", "#573a28", "#795337", "#a0764d", "#c7a475"],
        "sand": ["#5c482d", "#80653d", "#aa8954", "#ceb174", "#ead49b"],
        "ice": ["#496675", "#688896", "#91aeb7", "#bed0d1", "#edf3eb"],
        "ash": ["#202125", "#3e3e42", "#666368", "#918b8c", "#bbb4b0"],
        "coverAsh": ["#16171a", "#292a2d", "#3f3f43", "#59575b", "#747176"],
        "water": ["#10333f", "#1b5260", "#30747c", "#58a0a0", "#91c8bd"],
        "deepWater": ["#071d2b", "#0e3345", "#194e5e", "#2b6b76", "#55939a"],
        "rubble": ["#292725", "#4b4742", "#6f6861", "#968d82", "#c0b5a7"],
        "mud": ["#241a15", "#443026", "#654a38", "#8b6b50", "#b09170"],
        "groundcover": ["#263423", "#3d512e", "#5b703d", "#80904f", "#a9b46c"],
        "growth": ["#12271c", "#203d27", "#345c32", "#568043", "#86a65b"],
        "chasm": ["#02040a", "#0a0e18", "#171d29", "#303746", "#555d68"],
        "snow": ["#88979c", "#aab7b7", "#cbd4cf", "#e4e9df", "#fffdf0"],
    ]
}

private extension Array where Element == UInt8 {
    mutating func replace(at pixel: Int, with color: RGBA) {
        let offset = pixel * 4
        self[offset] = color.red; self[offset + 1] = color.green
        self[offset + 2] = color.blue; self[offset + 3] = color.alpha
    }
}

/// Strict consumer for the accepted, authored south-facing elevation-wall family.
/// It owns pixels only. Gameplay supplies the already-disclosed exposure and continuation facts.
final class TerrainSouthWallPack: @unchecked Sendable {
    static let identity = "TerrainSouthWallPack-v1"
    static let manifestSHA256 = "ee635278fe03b04304b46e47673596723df58827819e79580c40cc697d5fd9bb"
    static let bodySHA256 = "cd6309daa96792abb036821d761927ca19f396a7ccea48da81f54fddb6a82f20"

    enum Join: String, CaseIterable, Sendable { case span, leftCap, rightCap, isolated }
    enum WallError: Error, Equatable {
        case unavailable, invalidManifest, invalidRequest, missingAsset(String), corruptAsset(String)
    }

    struct Request: Equatable, Sendable {
        let ground: TerrainProductionPack.Ground
        let depth: Int
        let westContinuation: Bool
        let eastContinuation: Bool
        let featureVariant: Int

        var join: Join {
            westContinuation ? (eastContinuation ? .span : .rightCap)
                : (eastContinuation ? .leftCap : .isolated)
        }

        init(ground: TerrainProductionPack.Ground, depth: Int,
             westContinuation: Bool, eastContinuation: Bool, featureVariant: Int) throws {
            guard Self.legalGrounds.contains(ground), (1...3).contains(depth),
                  (0...3).contains(featureVariant) else { throw WallError.invalidRequest }
            self.ground = ground; self.depth = depth
            self.westContinuation = westContinuation; self.eastContinuation = eastContinuation
            self.featureVariant = featureVariant
        }

        fileprivate static let legalGrounds: Set<TerrainProductionPack.Ground> = [
            .stone, .soil, .sand, .ash, .rubble, .mud,
        ]
    }

    private struct Asset {
        let path: String
        let hash: String
    }

    private let rootURL: URL
    private let read: @Sendable (URL) throws -> Data
    private let lock = NSLock()
    private var assets: [String: Asset]?

    init(rootURL: URL, read: @escaping @Sendable (URL) throws -> Data = {
        try Data(contentsOf: $0)
    }) {
        self.rootURL = rootURL; self.read = read
    }

    static func bundled(in bundle: Bundle = .main) throws -> TerrainSouthWallPack {
        let root = bundle.bundleURL.appendingPathComponent(identity, isDirectory: true)
        guard FileManager.default.isReadableFile(
            atPath: root.appendingPathComponent("manifest.json").path) else {
            throw WallError.unavailable
        }
        return TerrainSouthWallPack(rootURL: root)
    }

    func open() throws {
        lock.lock(); defer { lock.unlock() }
        if assets != nil { return }
        let data: Data
        do { data = try read(rootURL.appendingPathComponent("manifest.json")) }
        catch { throw WallError.unavailable }
        guard Self.sha256(data) == Self.manifestSHA256,
              let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              Set(root.keys) == Set(["schemaVersion", "integrationReady", "status", "profile",
                                     "acceptedTerrainPins", "reference", "assets", "cases",
                                     "assetAggregateSHA256", "canonicalBodySHA256"]),
              root["schemaVersion"] as? String == "terrain-south-wall-pack-v1",
              root["integrationReady"] as? Bool == false,
              root["canonicalBodySHA256"] as? String == Self.bodySHA256,
              let profile = root["profile"] as? [String: Any],
              profile["width"] as? Int == 16, profile["height"] as? Int == 19,
              profile["depths"] as? [Int] == [1, 2, 3],
              profile["joins"] as? [String] == Join.allCases.map(\.rawValue),
              profile["grounds"] as? [String] == Request.legalGrounds
                .map(\.rawValue).sorted(by: Self.groundOrder),
              profile["roles"] as? [String] == Self.roles,
              profile["equalElevation"] as? String == "no-wall",
              profile["hiddenOrOutOfMap"] as? String == "no-wall",
              let socket = profile["wallSocket"] as? [String: Any],
              socket["x"] as? Int == 0, socket["y"] as? Int == 16,
              socket["width"] as? Int == 16, socket["height"] as? Int == 3,
              let rows = root["assets"] as? [String: [String: Any]], rows.count == 288
        else { throw WallError.invalidManifest }

        var parsed: [String: Asset] = [:]
        for ground in ["stone", "soil", "sand", "ash", "rubble", "mud"] {
            for depth in 1...3 { for join in Join.allCases { for variant in 0...3 {
                let key = "mask/\(ground)/d\(depth)/\(join.rawValue)/v\(variant)"
                guard let row = rows[key],
                      Set(row.keys) == Set(["path", "sha256", "width", "height", "kind"]),
                      let path = row["path"] as? String, let hash = row["sha256"] as? String,
                      row["width"] as? Int == 16, row["height"] as? Int == 3,
                      row["kind"] as? String == "semanticRoleIndex",
                      path == "assets/\(hash).png", !path.contains(".."),
                      hash.range(of: "^[0-9a-f]{64}$", options: .regularExpression) != nil
                else { throw WallError.invalidManifest }
                parsed[key] = Asset(path: path, hash: hash)
            }}}
        }
        guard parsed.count == 288 else { throw WallError.invalidManifest }
        assets = parsed
    }

    func rgba(for request: Request, descriptor: WorldGrade2V1.Descriptor) throws -> [UInt8] {
        try open()
        let asset: Asset
        lock.lock()
        let key = "mask/\(request.ground.rawValue)/d\(request.depth)/\(request.join.rawValue)/v\(request.featureVariant)"
        guard let found = assets?[key] else { lock.unlock(); throw WallError.missingAsset(key) }
        asset = found
        lock.unlock()
        let data: Data
        do { data = try read(rootURL.appendingPathComponent(asset.path)) }
        catch { throw WallError.missingAsset(key) }
        guard Self.sha256(data) == asset.hash else { throw WallError.corruptAsset(key) }
        let roles = try Self.roleIndices(data, key: key)
        let palette = try TerrainProductionPack.resolvedGroundPalette(request.ground,
                                                                       descriptor: descriptor)
        var rgba = [UInt8](repeating: 0, count: 16 * 3 * 4)
        for (index, role) in roles.enumerated() where role >= 0 {
            rgba.replace(at: index, with: palette[Int(role)])
        }
        return rgba
    }

    private static func roleIndices(_ data: Data, key: String) throws -> [Int8] {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil),
              image.width == 16, image.height == 3,
              let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
            throw WallError.corruptAsset(key)
        }
        var rgba = [UInt8](repeating: 0, count: 16 * 3 * 4)
        let drew = rgba.withUnsafeMutableBytes { buffer -> Bool in
            guard let base = buffer.baseAddress,
                  let context = CGContext(data: base, width: 16, height: 3,
                                          bitsPerComponent: 8, bytesPerRow: 64,
                                          space: colorSpace,
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                                            | CGBitmapInfo.byteOrder32Big.rawValue) else { return false }
            context.interpolationQuality = .none
            context.draw(image, in: CGRect(x: 0, y: 0, width: 16, height: 3))
            return true
        }
        guard drew else { throw WallError.corruptAsset(key) }
        let roleByByte: [UInt8: Int8] = [32: 0, 80: 1, 128: 2, 176: 3, 224: 4]
        return try (0..<48).map { index in
            let offset = index * 4
            guard rgba[offset + 3] == 0 || rgba[offset + 3] == 255,
                  rgba[offset + 3] == 0 || (rgba[offset] == rgba[offset + 1]
                    && rgba[offset] == rgba[offset + 2]),
                  rgba[offset + 3] == 0 || roleByByte[rgba[offset]] != nil else {
                throw WallError.corruptAsset(key)
            }
            return rgba[offset + 3] == 0 ? -1 : roleByByte[rgba[offset]]!
        }
    }

    private static func groundOrder(_ lhs: String, _ rhs: String) -> Bool {
        let order = ["stone", "soil", "sand", "ash", "rubble", "mud"]
        return order.firstIndex(of: lhs)! < order.firstIndex(of: rhs)!
    }
    private static func sha256(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
    private static let roles = ["deepShadow", "bodyDark", "body", "bodyLight", "highlight"]
}
