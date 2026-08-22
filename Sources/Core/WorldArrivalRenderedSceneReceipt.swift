import CryptoKit
import Foundation

/// Platform-neutral frozen output of the accepted rect-v1 compositor. The macOS world-generator
/// bridge can persist and validate this value without linking UIKit.
struct WorldArrivalRenderedSceneReceipt: Codable, Equatable, Sendable {
    static let schemaVersion = 1
    static let canvasWidth = 160
    static let canvasHeight = 100
    static let visualProgramID = "world-arrival-v1"
    static let visualProgramSHA256 = "5352cafa83ad6982aaaceafd24db66b5db002d5b5f1f6ceaf375b7cea738b882"
    static let visualProgramCommit = "9b60e8516f08806d40c38ed2a4307746c13d1c8c"
    static let acceptedManifestSHA256 = "f041c81a41c45ac88dada40b0c173ab63c6e93c2984f232a23be67892df4a65b"

    struct Command: Codable, Equatable, Sendable {
        enum Scope: String, Codable, CaseIterable, Sendable {
            case frame, illumination, ground, water, material, flora
            case suspended, precipitation, entryDisclosure, entryMark
        }
        var op: String; var x: Int; var y: Int; var width: Int; var height: Int
        var rgba: [Int]; var scope: Scope; var sourceOrder: Int

        init(x: Int, y: Int, width: Int, height: Int, rgba: [Int], scope: Scope,
             sourceOrder: Int = -1) {
            op = "rect-v1"; self.x = x; self.y = y; self.width = width; self.height = height
            self.rgba = rgba; self.scope = scope; self.sourceOrder = sourceOrder
        }
        func validates(expectedOrder: Int) -> Bool {
            op == "rect-v1" && sourceOrder == expectedOrder && width > 0 && height > 0
                && x >= 0 && y >= 0 && x + width <= 160 && y + height <= 100
                && rgba.count == 4 && rgba.allSatisfy { (0...255).contains($0) }
        }
    }

    var version: Int; var canvasWidth: Int; var canvasHeight: Int
    var visualProgramID: String; var visualProgramSHA256: String
    var visualProgramCommit: String; var acceptedManifestSHA256: String
    var inputSceneReceiptSHA256: String; var commands: [Command]
    var commandListSHA256: String; var renderedRGBA8SHA256: String

    func validates() -> Bool {
        version == Self.schemaVersion && canvasWidth == Self.canvasWidth
            && canvasHeight == Self.canvasHeight && visualProgramID == Self.visualProgramID
            && visualProgramSHA256 == Self.visualProgramSHA256
            && visualProgramCommit == Self.visualProgramCommit
            && acceptedManifestSHA256 == Self.acceptedManifestSHA256
            && inputSceneReceiptSHA256.count == 64
            && commands.enumerated().allSatisfy { $0.element.validates(expectedOrder: $0.offset) }
            && commandListSHA256 == Self.canonicalSHA256(commands)
            && renderedRGBA8SHA256 == Self.sha256(Self.render(commands))
    }

    static func render(_ commands: [Command]) -> [UInt8] {
        var rgba = [UInt8](repeating: 0, count: canvasWidth * canvasHeight * 4)
        for (index, command) in commands.enumerated() {
            guard command.validates(expectedOrder: index) else { return [] }
            for y in command.y..<(command.y + command.height) {
                for x in command.x..<(command.x + command.width) {
                    let offset = (y * canvasWidth + x) * 4
                    let alpha = Double(command.rgba[3]) / 255, inverse = 1 - alpha
                    rgba[offset] = UInt8((Double(command.rgba[0]) * alpha + Double(rgba[offset]) * inverse).rounded())
                    rgba[offset + 1] = UInt8((Double(command.rgba[1]) * alpha + Double(rgba[offset + 1]) * inverse).rounded())
                    rgba[offset + 2] = UInt8((Double(command.rgba[2]) * alpha + Double(rgba[offset + 2]) * inverse).rounded())
                    rgba[offset + 3] = UInt8((Double(command.rgba[3]) + Double(rgba[offset + 3]) * inverse).rounded())
                }
            }
        }
        return rgba
    }

    static func canonicalSHA256<T: Encodable>(_ value: T) -> String {
        sha256(Array(canonicalJSONData(value)))
    }

    static func canonicalJSONData<T: Encodable>(_ value: T) -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return (try? encoder.encode(value)) ?? Data()
    }
    static func sha256(_ bytes: [UInt8]) -> String {
        SHA256.hash(data: Data(bytes)).map { String(format: "%02x", $0) }.joined()
    }
}
