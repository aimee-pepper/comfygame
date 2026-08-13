import CryptoKit
import Foundation

/// Immutable native boundary for AssetLab's replaceable named-character placeholder pack.
///
/// The pack deliberately knows only stable `TravellerID` values and explicit camera profiles.
/// Names, callings, party order and recruitment state cannot influence visual lookup.
extension NativeVisualRuntime {
    enum NamedCharacterProfile: String, Codable, CaseIterable, Sendable {
        case compactCameo
        case mapTopDown
    }

    enum MapFacing: String, Codable, CaseIterable, Sendable {
        case north, east, south, west
    }

    struct NamedCharacterVisualKey: Hashable, Sendable {
        let travellerID: TravellerID
        let profile: NamedCharacterProfile
        let facing: MapFacing?

        static func cameo(_ travellerID: TravellerID) -> Self {
            .init(travellerID: travellerID, profile: .compactCameo, facing: nil)
        }

        static func map(_ travellerID: TravellerID, facing: MapFacing) -> Self {
            .init(travellerID: travellerID, profile: .mapTopDown, facing: facing)
        }
    }

    struct NamedCharacterVisual: Equatable, Sendable {
        let asset: GeneratedPixelAsset
        /// AssetLab evidence over the canonical source rectangle JSON.
        let sourceCommandSHA256: String
    }

    enum NamedCharacterPackError: Error, Equatable {
        case rawManifestHashMismatch
        case canonicalManifestHashMismatch
        case invalidMetadata
        case unsupportedTravellerIDs
        case duplicateKey
        case invalidProfileKey
        case invalidCommand
        case sourceCommandHashMismatch
        case decodedHashMismatch
        case incompleteCoverage
    }

    struct NamedCharacterPlaceholderPack: Sendable {
        static let packID = "named-character-placeholders-v1"
        static let pipelineVersion = "named-character-functional-placeholder-1.0.0"
        static let rawManifestSHA256 = "e3c9b6b68c00e710d8a3ad0cdd9adb190c0de023e44e18944c731de8283a1993"
        static let canonicalManifestSHA256 = "e0bccbfa9a6637c0a0aee9e536e842b555b3b2c2866566db06d98189ce55447b"
        static let sourceCatalogueSHA256 = "bcea43b47970962e808eccce3d78403249418c20b2bc2f0eaab7c9d9816d3ec0"
        static let canvasWidth: UInt8 = 16
        static let canvasHeight: UInt8 = 16

        /// This is pack coverage, not a claim about recruitment or catalogue promotion.
        static let supportedTravellerIDs: Set<TravellerID> = Set([
            "mara", "edren", "sela", "tovin", "halloway", "isolde", "bryn", "orsa",
            "vance", "noll", "talin", "nessa", "corrin", "dagg", "rook", "lys",
            "bracken", "fen", "wren", "kestrel", "maud", "marrick", "sabine",
            "grimmond", "oda", "auber", "ashe", "perren", "nine",
        ])

        private let visualsByKey: [NamedCharacterVisualKey: NamedCharacterVisual]

        init(manifestData: Data) throws {
            guard NativeVisualRuntime.sha256(manifestData) == Self.rawManifestSHA256 else {
                throw NamedCharacterPackError.rawManifestHashMismatch
            }
            let json = try JSONSerialization.jsonObject(with: manifestData)
            guard var root = json as? [String: Any],
                  root.removeValue(forKey: "canonicalManifestSHA256") as? String
                    == Self.canonicalManifestSHA256,
                  NativeVisualRuntime.sha256(Data(try Self.canonicalJSON(root).utf8))
                    == Self.canonicalManifestSHA256 else {
                throw NamedCharacterPackError.canonicalManifestHashMismatch
            }

            let manifest = try JSONDecoder().decode(SourceManifest.self, from: manifestData)
            guard manifest.schemaVersion == 1,
                  manifest.packID == Self.packID,
                  manifest.pipelineVersion == Self.pipelineVersion,
                  manifest.integrationReady,
                  !manifest.finalArt,
                  manifest.sourceCatalogueSHA256 == Self.sourceCatalogueSHA256,
                  manifest.canvas.width == Self.canvasWidth,
                  manifest.canvas.height == Self.canvasHeight else {
                throw NamedCharacterPackError.invalidMetadata
            }
            guard Set(manifest.supportedTravellerIDs.map(TravellerID.init(rawValue:)))
                    == Self.supportedTravellerIDs,
                  manifest.supportedTravellerIDs.count == Self.supportedTravellerIDs.count else {
                throw NamedCharacterPackError.unsupportedTravellerIDs
            }

            var visuals: [NamedCharacterVisualKey: NamedCharacterVisual] = [:]
            for source in manifest.assets {
                guard let profile = NamedCharacterProfile(rawValue: source.key.profile) else {
                    throw NamedCharacterPackError.invalidProfileKey
                }
                let facing = source.key.facing.flatMap(MapFacing.init(rawValue:))
                guard (profile == .compactCameo && source.key.facing == nil)
                        || (profile == .mapTopDown && facing != nil) else {
                    throw NamedCharacterPackError.invalidProfileKey
                }
                let key = NamedCharacterVisualKey(
                    travellerID: TravellerID(rawValue: source.key.travellerID),
                    profile: profile,
                    facing: facing
                )
                guard Self.supportedTravellerIDs.contains(key.travellerID),
                      visuals[key] == nil else {
                    throw NamedCharacterPackError.duplicateKey
                }
                guard source.width == Self.canvasWidth, source.height == Self.canvasHeight else {
                    throw NamedCharacterPackError.invalidMetadata
                }

                let sourceBytes = Data(try Self.canonicalJSON(
                    source.commands.map(\.canonicalObject)).utf8)
                guard NativeVisualRuntime.sha256(sourceBytes) == source.commandSHA256 else {
                    throw NamedCharacterPackError.sourceCommandHashMismatch
                }
                let commands = try source.commands.map { try Self.nativeCommand($0) }
                let rgba = try NativeVisualRuntime.decodedRGBA(
                    width: source.width, height: source.height, commands: commands)
                guard NativeVisualRuntime.sha256(rgba) == source.decodedRGBASHA256 else {
                    throw NamedCharacterPackError.decodedHashMismatch
                }
                let asset = GeneratedPixelAsset(
                    width: source.width,
                    height: source.height,
                    commands: commands,
                    commandSHA256: NativeVisualRuntime.commandSHA256(commands),
                    decodedRGBASHA256: source.decodedRGBASHA256
                )
                try NativeVisualRuntime.validate(asset)
                visuals[key] = .init(asset: asset, sourceCommandSHA256: source.commandSHA256)
            }

            let expected = Set(Self.supportedTravellerIDs.flatMap { id in
                [NamedCharacterVisualKey.cameo(id)]
                    + MapFacing.allCases.map { NamedCharacterVisualKey.map(id, facing: $0) }
            })
            guard Set(visuals.keys) == expected else {
                throw NamedCharacterPackError.incompleteCoverage
            }
            visualsByKey = visuals
        }

        var count: Int { visualsByKey.count }

        func visual(for key: NamedCharacterVisualKey) -> NamedCharacterVisual? {
            visualsByKey[key]
        }

        func cameo(for travellerID: TravellerID) -> NamedCharacterVisual? {
            visual(for: .cameo(travellerID))
        }

        func mapSprite(for travellerID: TravellerID, facing: MapFacing) -> NamedCharacterVisual? {
            visual(for: .map(travellerID, facing: facing))
        }

        private static func nativeCommand(_ command: SourceCommand) throws -> PixelCommand {
            guard command.op == "rect", command.x >= 0, command.y >= 0,
                  command.w > 0, command.h > 0,
                  command.x + command.w <= Int(canvasWidth),
                  command.y + command.h <= Int(canvasHeight),
                  command.color.range(of: "^#[0-9a-fA-F]{6}$", options: .regularExpression) != nil,
                  let rgb = UInt32(command.color.dropFirst(), radix: 16),
                  let x = UInt8(exactly: command.x), let y = UInt8(exactly: command.y),
                  let width = UInt8(exactly: command.w), let height = UInt8(exactly: command.h)
            else { throw NamedCharacterPackError.invalidCommand }
            return .init(x: x, y: y, width: width, height: height,
                         rgba: (rgb << 8) | 0xff)
        }

        /// AssetLab canonical JSON: lexicographic object keys, no whitespace, array order retained.
        private static func canonicalJSON(_ value: Any) throws -> String {
            if let dictionary = value as? [String: Any] {
                return "{" + (try dictionary.keys.sorted().map { key in
                    let keyData = try JSONSerialization.data(withJSONObject: key,
                                                              options: [.fragmentsAllowed,
                                                                        .withoutEscapingSlashes])
                    return String(decoding: keyData, as: UTF8.self)
                        + ":" + (try canonicalJSON(dictionary[key]!))
                }).joined(separator: ",") + "}"
            }
            if let array = value as? [Any] {
                return "[" + (try array.map(canonicalJSON)).joined(separator: ",") + "]"
            }
            let data = try JSONSerialization.data(withJSONObject: value,
                                                   options: [.fragmentsAllowed,
                                                             .withoutEscapingSlashes])
            return String(decoding: data, as: UTF8.self)
        }
    }

    private struct SourceManifest: Decodable {
        let schemaVersion: Int
        let packID: String
        let pipelineVersion: String
        let integrationReady: Bool
        let finalArt: Bool
        let sourceCatalogueSHA256: String
        let canvas: Canvas
        let supportedTravellerIDs: [String]
        let assets: [SourceAsset]

        struct Canvas: Decodable { let width: UInt8; let height: UInt8 }
    }

    private struct SourceAsset: Decodable {
        let key: SourceKey
        let width: UInt8
        let height: UInt8
        let commands: [SourceCommand]
        let commandSHA256: String
        let decodedRGBASHA256: String
    }

    private struct SourceKey: Decodable {
        let travellerID: String
        let profile: String
        let facing: String?
    }

    private struct SourceCommand: Codable {
        let op: String
        let x: Int
        let y: Int
        let w: Int
        let h: Int
        let color: String

        var canonicalObject: [String: Any] {
            ["op": op, "x": x, "y": y, "w": w, "h": h, "color": color]
        }
    }
}
