import CryptoKit
import Foundation

/// Route-lazy access to the frozen WritingDeskProductionPack-v1.
///
/// Construction performs no file I/O. `open()` is called by the Writing Desk route, validates the
/// closed manifest, and indexes metadata only. PNG bytes are read and hashed only when requested.
final class WritingDeskProductionPack: @unchecked Sendable {
    static let identity = "WritingDeskProductionPack-v1"
    static let bodySHA256 = "3a9a3f1f854e20b981c26fa98da36bb4219661623cebfee895e4f743b7a62fa6"
    static let manifestSHA256 = "0257bb94d0e180dfa40008f7143a89e75dec49263e4d08e9249eadfe6f232f96"

    enum PackError: Error, Equatable {
        case unavailable
        case invalidManifest
        case unsupportedVersion
        case unknownAuthoredMark(String)
        case personalCompoundUsesCompatibilityRoute
        case illegalToolInkCombination
        case invalidLink
        case missingAsset(String)
        case corruptAsset(String)
        case invalidAuthoredRotation(String)
    }

    enum MarkRoute: Equatable {
        case authored(key: String)
        case compatibilityPersonalCompound
    }

    enum Orientation: String, Equatable { case horizontal, vertical }
    struct Point: Equatable { var x: Int; var y: Int }
    struct Size: Equatable { var width: Int; var height: Int }
    struct Rect: Equatable { var x: Int; var y: Int; var width: Int; var height: Int }
    struct BlankPageSpec: Equatable {
        var asset: Asset; var writingArea: Rect; var socketColumns: Int
        var socketRows: Int; var socketSize: Size
    }
    struct CardSpec: Equatable { var asset: Asset; var thumbnailSocket: Rect; var sourceSize: Size; var destinationSize: Size }
    struct ToolStripSpec: Equatable { var assets: MarkAssets; var runtimeTextReserve: Rect; var inkWellSocket: Rect }
    struct PopoverBodySpec: Equatable { var asset: Asset; var rows: Int; var stretchInsets: Rect }
    struct LinkPlacement: Equatable {
        var key: String
        var orientation: Orientation
        var topLeft: Point
        var width: Int
        var height: Int
        var asset: Asset
    }
    struct Asset: Equatable {
        var file: String
        var sha256: String
        var width: Int
        var height: Int
    }
    struct MarkAssets: Equatable { var rgba: Asset; var tintMask: Asset; var fixedMask: Asset }

    private let rootURL: URL
    private let read: @Sendable (URL) throws -> Data
    private var manifest: [String: Any]?
    private var marks: [String: [String: Any]] = [:]
    private var links: [String: [String: Any]] = [:]
    private var overlays: [String: [String: Any]] = [:]
    private var vocabularyTiles: [String: [String: Any]] = [:]
    private var parts: [String: Any] = [:]
    private var toolStrips: [String: [String: Any]] = [:]
    private var assetsByHash: [String: Asset] = [:]
    private var cachedAssetData: [String: Data] = [:]
    private let lock = NSLock()

    init(rootURL: URL, read: @escaping @Sendable (URL) throws -> Data = { try Data(contentsOf: $0) }) {
        self.rootURL = rootURL
        self.read = read
    }

    /// Locates the single preserved runtime folder only when the Writing Desk route asks for it.
    static func bundled(in bundle: Bundle = .main) throws -> WritingDeskProductionPack {
        guard let manifest = bundle.url(forResource: "manifest", withExtension: "json",
                                        subdirectory: "runtime")
        else { throw PackError.unavailable }
        return .init(rootURL: manifest.deletingLastPathComponent())
    }

    /// Opens the metadata on demand. It deliberately does not enumerate or decode PNG files.
    func open() throws {
        lock.lock(); defer { lock.unlock() }
        if manifest != nil { return }
        let data: Data
        do { data = try read(rootURL.appendingPathComponent("manifest.json")) }
        catch { throw PackError.unavailable }
        guard Self.sha256(data) == Self.manifestSHA256 else { throw PackError.invalidManifest }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              Set(json.keys) == Set(["schemaVersion", "identity", "integrationReady", "acceptedSources",
                                    "sourceSemantics", "authoredLexemeScope", "tintRoles", "lookups",
                                    "parts", "legalToolInkCombinations", "linkContract", "rotationContract", "coverage",
                                    "failClosed", "excluded", "evidence", "assets", "canonicalBodySHA256"]),
              json["schemaVersion"] as? Int == 1,
              json["identity"] as? String == Self.identity,
              json["canonicalBodySHA256"] as? String == Self.bodySHA256,
              json["integrationReady"] as? Bool == false,
              let coverage = json["coverage"] as? [String: Any],
              coverage["lexemes"] as? Int == 108,
              coverage["rotations"] as? Int == 4,
              coverage["markLookups"] as? Int == 1296,
              coverage["tileLookups"] as? Int == 1296,
              coverage["distinctOverlayLookups"] as? Int == 312,
              coverage["linkLookups"] as? Int == 6,
              let lookups = json["lookups"] as? [String: Any],
              let rotation = json["rotationContract"] as? [String: Any],
              rotation["angles"] as? [Int] == [0, 90, 180, 270],
              rotation["key"] as? String == "mark/<kind>/<stableID>/<hand>/<angle>",
              rotation["invalidAnglesFailClosed"] as? Bool == true,
              let failClosed = json["failClosed"] as? [String: Any],
              failClosed["invalidRotationAngle"] as? Bool == true,
              let marks = lookups["marks"] as? [String: [String: Any]], marks.count == 1296,
              let overlays = lookups["overlays"] as? [String: [String: Any]], overlays.count == 312,
              let links = lookups["links"] as? [String: [String: Any]], links.count == 6,
              let vocabularyTiles = lookups["vocabularyTiles"] as? [String: [String: Any]], vocabularyTiles.count == 1296,
              let parts = json["parts"] as? [String: Any],
              let toolStrips = parts["toolStrips"] as? [String: [String: Any]],
              Set(toolStrips.keys) == Set(Self.legalToolStripKeys),
              let assetRows = json["assets"] as? [[String: Any]], assetRows.count == 4459
        else { throw PackError.invalidManifest }
        var assetIndex: [String: Asset] = [:]
        for row in assetRows {
            guard let file = row["file"] as? String, let hash = row["sha256"] as? String,
                  let width = row["width"] as? Int, let height = row["height"] as? Int,
                  file == "assets/\(hash).png", assetIndex[hash] == nil,
                  hash.range(of: "^[0-9a-f]{64}$", options: .regularExpression) != nil,
                  width > 0, height > 0 else { throw PackError.invalidManifest }
            assetIndex[hash] = .init(file: file, sha256: hash, width: width, height: height)
        }
        self.marks = marks; self.overlays = overlays; self.links = links
        self.vocabularyTiles = vocabularyTiles; self.parts = parts; self.toolStrips = toolStrips
        assetsByHash = assetIndex; manifest = json
    }

    func route(for mark: WritingDeskVisibleMark) throws -> MarkRoute {
        try open()
        if mark.visualRoute == .personalCompoundCompatibility {
            return .compatibilityPersonalCompound
        }
        let angle = try Self.rotationAngle(in: mark.shapeID)
        let hand = Self.packHand(mark.hand)
        guard case let .authored(kind) = mark.visualRoute else {
            throw PackError.unknownAuthoredMark(mark.rendererAssetKey)
        }
        let key = "mark/\(kind.rawValue)/\(mark.rendererAssetKey)/\(hand)/\(angle)"
        guard let row = marks[key],
              row["shapeID"] as? String == mark.shapeID,
              Self.cells(row["cells"]) == (mark.cells.map {
                  Point(x: $0.column - mark.origin.column, y: $0.row - mark.origin.row)
              })
        else { throw PackError.unknownAuthoredMark(mark.rendererAssetKey) }
        return .authored(key: key)
    }

    func toolStrip(hand: Hand, usesMixedInk: Bool) throws -> String {
        try open()
        let key = "tool-strip/\(Self.packHand(hand))/\(usesMixedInk ? "mixed" : "ash")"
        guard toolStrips[key] != nil else { throw PackError.illegalToolInkCombination }
        return key
    }

    func markAssets(for key: String) throws -> MarkAssets {
        try open()
        guard let row = marks[key], let roles = row["roles"] as? [String: Any],
              let rgba = asset(from: roles["rgba"]),
              let tint = asset(from: roles["tintMask"]),
              let fixed = asset(from: roles["fixedMask"]),
              rgba.width == tint.width, rgba.height == tint.height,
              rgba.width == fixed.width, rgba.height == fixed.height else { throw PackError.invalidManifest }
        return .init(rgba: rgba, tintMask: tint, fixedMask: fixed)
    }

    func overlayAsset(shapeID: String, state: String) throws -> Asset {
        try open()
        guard let row = overlays["state/\(shapeID)/\(state)"], let value = asset(from: row["asset"])
        else { throw PackError.invalidManifest }
        return value
    }

    func vocabularyAsset(kind: String, id: String, hand: Hand, state: String) throws -> Asset {
        try open()
        let key = "tile/\(kind)/\(id)/\(Self.packHand(hand))/\(state)"
        guard let row = vocabularyTiles[key], let value = asset(from: row["asset"])
        else { throw PackError.unknownAuthoredMark(id) }
        return value
    }

    func cardAsset(kind: String, state: String) throws -> Asset {
        try open()
        guard let cards = parts["cards"] as? [String: [String: Any]],
              let row = cards["card/\(kind)/\(state)"], let value = asset(from: row["asset"])
        else { throw PackError.invalidManifest }
        return value
    }

    func blankPageSpec() throws -> BlankPageSpec {
        try open()
        guard let row = parts["blankPage"] as? [String: Any], let value = asset(from: row["asset"]),
              let area = rect(row["writingArea"]), let socket = row["socket"] as? [String: Any],
              socket["columns"] as? Int == 6, socket["rows"] as? Int == 6,
              socket["width"] as? Int == 27, socket["height"] as? Int == 27,
              area == .init(x: 5, y: 5, width: 162, height: 162), value.width == 172, value.height == 172
        else { throw PackError.invalidManifest }
        return .init(asset: value, writingArea: area, socketColumns: 6, socketRows: 6,
                     socketSize: .init(width: 27, height: 27))
    }

    func unreadMarkerAsset() throws -> Asset {
        try open()
        guard let row = parts["unreadMarker"] as? [String: Any], let value = asset(from: row["asset"])
        else { throw PackError.invalidManifest }
        return value
    }

    func toolAsset(hand: Hand) throws -> Asset {
        try open()
        guard let tools = parts["tools"] as? [String: [String: Any]],
              let row = tools[Self.packHand(hand)], let value = asset(from: row["asset"])
        else { throw PackError.invalidManifest }
        return value
    }

    func cardSpec(kind: String, state: String) throws -> CardSpec {
        try open()
        guard let cards = parts["cards"] as? [String: [String: Any]], let row = cards["card/\(kind)/\(state)"],
              let value = asset(from: row["asset"]), let socket = rect(row["thumbnailSocket"]),
              let map = row["thumbnailMapping"] as? [String: Any], map["filter"] as? String == "nearest",
              let sw = map["sourceWidth"] as? Int, let sh = map["sourceHeight"] as? Int,
              let dw = map["destinationWidth"] as? Int, let dh = map["destinationHeight"] as? Int,
              socket == .init(x: 6, y: 7, width: 62, height: 62), sw == 172, sh == 172, dw == 62, dh == 62
        else { throw PackError.invalidManifest }
        return .init(asset: value, thumbnailSocket: socket, sourceSize: .init(width: sw, height: sh),
                     destinationSize: .init(width: dw, height: dh))
    }

    func popoverBody(rows: Int) throws -> PopoverBodySpec {
        try open()
        guard [2, 3, 4].contains(rows), let popovers = parts["popovers"] as? [String: Any],
              let bodies = popovers["bodies"] as? [String: [String: Any]], let row = bodies[String(rows)],
              let value = asset(from: row["asset"]), let raw = row["stretchInsets"] as? [String: Any],
              let top = raw["top"] as? Int, let left = raw["left"] as? Int,
              let bottom = raw["bottom"] as? Int, let right = raw["right"] as? Int
        else { throw PackError.invalidManifest }
        return .init(asset: value, rows: rows,
                     stretchInsets: .init(x: left, y: top, width: right, height: bottom))
    }

    func popoverPointer(variant: String) throws -> Asset {
        try open()
        guard let popovers = parts["popovers"] as? [String: Any],
              let pointers = popovers["pointers"] as? [String: [String: Any]], pointers.count == 4,
              let row = pointers[variant], let value = asset(from: row["asset"])
        else { throw PackError.invalidManifest }
        return value
    }

    func toolStripAssets(hand: Hand, usesMixedInk: Bool) throws -> MarkAssets {
        let key = try toolStrip(hand: hand, usesMixedInk: usesMixedInk)
        guard let roles = toolStrips[key]?["roles"] as? [String: Any],
              let rgba = asset(from: roles["rgba"]), let tint = asset(from: roles["tintMask"]),
              let fixed = asset(from: roles["fixedMask"]) else { throw PackError.invalidManifest }
        return .init(rgba: rgba, tintMask: tint, fixedMask: fixed)
    }

    func toolStripSpec(hand: Hand, usesMixedInk: Bool) throws -> ToolStripSpec {
        let key = try toolStrip(hand: hand, usesMixedInk: usesMixedInk)
        guard let row = toolStrips[key], let text = rect(row["runtimeTextReserve"]),
              let well = rect(row["inkWellSocket"]) else { throw PackError.invalidManifest }
        return .init(assets: try toolStripAssets(hand: hand, usesMixedInk: usesMixedInk),
                     runtimeTextReserve: text, inkWellSocket: well)
    }

    func link(between first: WritingDeskVisibleMark, and second: WritingDeskVisibleMark) throws -> LinkPlacement {
        try open()
        var candidates: [(Point, Orientation)] = []
        for a in first.cells {
            for b in second.cells {
                let dx = b.column - a.column
                let dy = b.row - a.row
                if abs(dx) + abs(dy) == 1 {
                    let orientation: Orientation = dx == 0 ? .vertical : .horizontal
                    candidates.append((Point(x: a.column + b.column + 1,
                                             y: a.row + b.row + 1), orientation))
                }
            }
        }
        candidates.sort { lhs, rhs in
            lhs.0.y != rhs.0.y ? lhs.0.y < rhs.0.y :
            lhs.0.x != rhs.0.x ? lhs.0.x < rhs.0.x :
            lhs.1 == .horizontal && rhs.1 == .vertical
        }
        guard let selected = candidates.first else { throw PackError.invalidLink }
        let hand = Self.packHand(first.hand.order <= second.hand.order ? first.hand : second.hand)
        let key = "link/\(hand)/\(selected.1.rawValue)"
        guard let row = links[key], let dimensions = row["dimensions"] as? [String: Any],
              let width = dimensions["width"] as? Int, let height = dimensions["height"] as? Int,
              (selected.1 == .horizontal ? (width == 28 && height == 5) : (width == 5 && height == 28))
        else { throw PackError.invalidLink }
        let sharedX = selected.0.x * 27 / 2 + 5
        let sharedY = selected.0.y * 27 / 2 + 5
        let topLeft = selected.1 == .horizontal
            ? Point(x: sharedX - 14, y: sharedY - 2)
            : Point(x: sharedX - 2, y: sharedY - 14)
        guard let value = asset(from: row["asset"]) else { throw PackError.invalidLink }
        return .init(key: key, orientation: selected.1, topLeft: topLeft,
                     width: width, height: height, asset: value)
    }

    func assetData(sha256: String) throws -> Data {
        try open()
        lock.lock()
        if let cached = cachedAssetData[sha256] { lock.unlock(); return cached }
        guard let asset = assetsByHash[sha256] else { lock.unlock(); throw PackError.missingAsset(sha256) }
        lock.unlock()
        let data: Data
        do { data = try read(rootURL.appendingPathComponent(asset.file)) }
        catch { throw PackError.missingAsset(sha256) }
        let actual = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        guard actual == sha256, Self.pngDimensions(data) == Point(x: asset.width, y: asset.height)
        else { throw PackError.corruptAsset(sha256) }
        lock.lock(); cachedAssetData[sha256] = data; lock.unlock()
        return data
    }

    /// Applies mixed ink to tint-owned pixels only. `fixedMask` is intentionally not accepted:
    /// it is pack-validation metadata, never a compositing layer.
    static func resolveTint(baseRGBA: [UInt8], tintMaskRGBA: [UInt8], inkRGBA: [UInt8]?) throws -> [UInt8] {
        guard baseRGBA.count == tintMaskRGBA.count, baseRGBA.count.isMultiple(of: 4),
              inkRGBA == nil || inkRGBA?.count == 4 else { throw PackError.invalidManifest }
        guard let inkRGBA else { return baseRGBA }
        var result = baseRGBA
        for offset in stride(from: 0, to: result.count, by: 4) where tintMaskRGBA[offset + 3] > 0 {
            result.replaceSubrange(offset..<(offset + 4), with: inkRGBA)
        }
        return result
    }

    static let legalToolStripKeys = ["tool-strip/charcoal/ash", "tool-strip/brush/ash",
                                     "tool-strip/brush/mixed", "tool-strip/fountain/ash",
                                     "tool-strip/fountain/mixed"]
    private static func packHand(_ hand: Hand) -> String {
        switch hand { case .crude: "charcoal"; case .plain: "brush"; case .refined: "fountain" }
    }
    private static func rotationAngle(in shapeID: String) throws -> Int {
        let pieces = shapeID.split(separator: "@", omittingEmptySubsequences: false)
        if pieces.count == 1, !pieces[0].isEmpty { return 0 }
        guard pieces.count == 2, !pieces[0].isEmpty,
              let angle = Int(pieces[1]), [90, 180, 270].contains(angle)
        else { throw PackError.invalidAuthoredRotation(shapeID) }
        return angle
    }
    private static func cells(_ value: Any?) -> [Point]? {
        guard let rows = value as? [[Int]] else { return nil }
        return rows.compactMap { $0.count == 2 ? Point(x: $0[0], y: $0[1]) : nil }
    }
    private func asset(from value: Any?) -> Asset? {
        guard let row = value as? [String: Any], let hash = row["sha256"] as? String,
              let indexed = assetsByHash[hash], row["file"] as? String == indexed.file,
              row["width"] as? Int == indexed.width, row["height"] as? Int == indexed.height
        else { return nil }
        return indexed
    }
    private func rect(_ value: Any?) -> Rect? {
        guard let row = value as? [String: Any], let x = row["x"] as? Int,
              let y = row["y"] as? Int, let width = row["width"] as? Int,
              let height = row["height"] as? Int else { return nil }
        return .init(x: x, y: y, width: width, height: height)
    }
    private static func sha256(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
    private static func pngDimensions(_ data: Data) -> Point? {
        guard data.count >= 24, Array(data.prefix(8)) == [137,80,78,71,13,10,26,10] else { return nil }
        func value(_ offset: Int) -> Int { data[offset..<offset+4].reduce(0) { ($0 << 8) | Int($1) } }
        return Point(x: value(16), y: value(20))
    }
}
