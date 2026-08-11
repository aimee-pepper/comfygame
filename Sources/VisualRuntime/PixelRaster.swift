import CryptoKit
import Foundation

extension NativeVisualRuntime {
    enum ValidationError: Swift.Error, Equatable {
        case invalidCanvas
        case emptyRectangle(Int)
        case rectangleOutOfBounds(Int)
        case malformedSHA256(String)
        case commandHashMismatch
        case decodedHashMismatch
        case inconsistentCanvas
        case duplicateKey(GeneratedVisualKey)
        case duplicateUnsupportedID(String)
        case assetAlsoUnsupported(String)
        case incompleteCoverage([String])
        case unexpectedCoverage([String])
        case invalidManifestMetadata
    }

    struct GeneratedPixelAsset: Codable, Equatable, Sendable {
        var width: UInt8
        var height: UInt8
        var commands: [PixelCommand]
        var commandSHA256: String
        var decodedRGBASHA256: String
    }

    static func sha256(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    static func commandSHA256(_ commands: [PixelCommand]) -> String {
        sha256(normalizedCommandBytes(commands))
    }

    /// Deterministic straight-RGBA raster. The buffer begins transparent and later rectangles
    /// overwrite earlier ones, matching the normalized command order used as evidence.
    static func decodedRGBA(width: UInt8, height: UInt8,
                            commands: [PixelCommand]) throws -> Data {
        guard width > 0, height > 0 else { throw ValidationError.invalidCanvas }
        var bytes = [UInt8](repeating: 0, count: Int(width) * Int(height) * 4)
        for (index, command) in commands.enumerated() {
            guard command.width > 0, command.height > 0 else {
                throw ValidationError.emptyRectangle(index)
            }
            let x0 = Int(command.x), y0 = Int(command.y)
            let x1 = x0 + Int(command.width), y1 = y0 + Int(command.height)
            guard x1 <= Int(width), y1 <= Int(height) else {
                throw ValidationError.rectangleOutOfBounds(index)
            }
            let rgba = [UInt8(truncatingIfNeeded: command.rgba >> 24),
                        UInt8(truncatingIfNeeded: command.rgba >> 16),
                        UInt8(truncatingIfNeeded: command.rgba >> 8),
                        UInt8(truncatingIfNeeded: command.rgba)]
            for y in y0..<y1 {
                for x in x0..<x1 {
                    let offset = (y * Int(width) + x) * 4
                    bytes.replaceSubrange(offset..<(offset + 4), with: rgba)
                }
            }
        }
        return Data(bytes)
    }

    static func validate(_ asset: GeneratedPixelAsset) throws {
        try validateSHA(asset.commandSHA256)
        try validateSHA(asset.decodedRGBASHA256)
        let pixels = try decodedRGBA(width: asset.width, height: asset.height,
                                     commands: asset.commands)
        guard commandSHA256(asset.commands) == asset.commandSHA256 else {
            throw ValidationError.commandHashMismatch
        }
        guard sha256(pixels) == asset.decodedRGBASHA256 else {
            throw ValidationError.decodedHashMismatch
        }
    }

    private static func validateSHA(_ value: String) throws {
        guard value.range(of: "^[0-9a-f]{64}$", options: .regularExpression) != nil else {
            throw ValidationError.malformedSHA256(value)
        }
    }
}
