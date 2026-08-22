import Foundation
import UIKit

/// Mechanical Swift port of the accepted Asset compositor. It produces only the closed rect-v1
/// command ABI; title, prose, rules and disclosure classification remain outside this adapter.
enum WorldArrivalNativeRenderer {
    enum Error: Swift.Error, Equatable {
        case invalidSceneReceipt, invalidCommand, invalidRenderedReceipt
    }

    private struct Color: Equatable {
        var values: [Int]
        init(_ hex: String) {
            let raw = String(hex.dropFirst())
            if raw.count == 3 {
                values = raw.map { Int(String(repeating: String($0), count: 2), radix: 16)! } + [255]
            } else {
                values = stride(from: 0, to: raw.count, by: 2).map { index in
                    let start = raw.index(raw.startIndex, offsetBy: index)
                    let end = raw.index(start, offsetBy: 2)
                    return Int(raw[start..<end], radix: 16)!
                }
                if values.count == 3 { values.append(255) }
            }
        }
        init(rgb: [Int]) { values = rgb + [255] }
    }

    private struct DraftCommand {
        var x: Int; var y: Int; var width: Int; var height: Int
        var color: Color; var scope: WorldArrivalRenderedSceneReceipt.Command.Scope
    }

    private static let rockPart = ["..aaa...", ".abbbba.", "abccccba", "abccbbba", ".abbbba.", "..aaa..."]
    private static let succulentPart = ["...a...", "a..a..a", ".aaba..", "..aba..", ".acbca.", "..ccc.."]
    private static let poolPart = ["....aaaaaa....", "..aabbbbbbaa..", ".abccccccccba.", "abccccccccccba", ".abccccccccba.", "..aabbbbbbaa..", "....aaaaaa...."]
    private static let shelfPart = ["...aaaaaaaa....", ".aabbbbbbbbaa..", "abccccccccccba.", "abcccccccccccba", ".abccccccccccba", "..aabbbbbbbbba", "....aaaaaaaaa."]
    private static let dunePart = ["........................aaaa..", "....................aaaabbba..", "..............aaaaaabbbbbbbba.", "........aaaaaabbbbbbbbbbbbbba.", "..aaaaaabbbbbbbbbbbbbbbbbbbbba", "aabbbbbbbbbbbbbbbbbbbbbbbbbbbb"]
    private static let palettes: [GroundType: [Color]] = [
        .stone: [Color("#474a4d"), Color("#777b78"), Color("#a9aaa0")],
        .soil: [Color("#49392b"), Color("#7f6041"), Color("#b38c5e")],
        .sand: [Color("#67543a"), Color("#ad8c57"), Color("#d2b879")],
        .ice: [Color("#46636d"), Color("#7ca2a8"), Color("#c4dad7")],
        .ash: [Color("#403a3e"), Color("#73686a"), Color("#b39b90")],
        .rubble: [Color("#4b4541"), Color("#756b61"), Color("#a79a88")],
        .mud: [Color("#3f352b"), Color("#67513b"), Color("#917450")],
        .growth: [Color("#284b31"), Color("#47764b"), Color("#73a35d")],
        .groundcover: [Color("#324c31"), Color("#58734a"), Color("#87a466")],
    ]
    private static let water = [Color("#173849"), Color("#2d6378"), Color("#5b94a2")]

    static func makeRenderedReceipt(
        scene: WorldArrivalSceneReceipt
    ) throws -> WorldArrivalRenderedSceneReceipt {
        guard scene.validatesCanonicalHash(), scene.validatesSchema() else { throw Error.invalidSceneReceipt }
        let commands = try commands(for: scene.payload)
        let commandHash = WorldArrivalRenderedSceneReceipt.canonicalSHA256(commands)
        let rgba = WorldArrivalRenderedSceneReceipt.render(commands)
        let receipt = WorldArrivalRenderedSceneReceipt(
            version: WorldArrivalRenderedSceneReceipt.schemaVersion,
            canvasWidth: WorldArrivalRenderedSceneReceipt.canvasWidth,
            canvasHeight: WorldArrivalRenderedSceneReceipt.canvasHeight,
            visualProgramID: WorldArrivalRenderedSceneReceipt.visualProgramID,
            visualProgramSHA256: WorldArrivalRenderedSceneReceipt.visualProgramSHA256,
            visualProgramCommit: WorldArrivalRenderedSceneReceipt.visualProgramCommit,
            acceptedManifestSHA256: WorldArrivalRenderedSceneReceipt.acceptedManifestSHA256,
            inputSceneReceiptSHA256: scene.canonicalSHA256,
            commands: commands, commandListSHA256: commandHash,
            renderedRGBA8SHA256: WorldArrivalRenderedSceneReceipt.sha256(rgba))
        guard receipt.validates() else { throw Error.invalidRenderedReceipt }
        return receipt
    }

    static func commands(
        for receipt: WorldArrivalSceneReceipt.Payload
    ) throws -> [WorldArrivalRenderedSceneReceipt.Command] {
        guard WorldArrivalSceneReceipt(payload: receipt).validatesSchema() else { throw Error.invalidSceneReceipt }
        guard let p = palettes[receipt.dominantGround] else { throw Error.invalidSceneReceipt }
        var draft: [DraftCommand] = [
            rect(2, 2, 156, 96, "#d8bd82", .frame),
            rect(6, 6, 148, 88, "#171614", .frame),
            rect(10, 10, 140, 80, "#253b49", .frame),
        ]
        let seed = stableHash(receipt.receiptID + receipt.worldSeed)
        let far: String = switch receipt.illumination.band {
        case "trueDark": "#181a20"; case "dim": "#303746"; case "ordinary": "#71838b"
        case "bright": "#9fb5b5"; default: "#d5c9a4"
        }
        draft.append(rect(10, 10, 140, 34, far, .illumination))
        if ["shelves", "islands"].contains(receipt.waterRelationship) {
            for (index, row) in [[10,34,31,10],[41,31,37,13],[78,35,29,9],[107,30,43,14]].enumerated() {
                draft.append(rect(row[0], row[1], row[2], row[3], index.isMultiple(of: 2) ? "#234b5a" : "#173849", .water))
            }
            for (index, row) in [[13,27,1],[48,21,1],[83,26,1],[113,19,1]].enumerated() {
                draft += bitmap(row[0], row[1], shelfPart,
                                ["a": p[0], "b": index.isMultiple(of: 2) ? p[0] : p[1], "c": p[1]], .ground, row[2])
            }
            for row in [[18,38,18],[70,34,23],[119,36,17]] { draft.append(rect(row[0], row[1], row[2], 1, water[2], .water)) }
        } else if receipt.dominantGround == .stone {
            for row in [[12,12,2],[35,18,2],[58,11,2],[103,14,2],[129,19,2]] {
                draft += bitmap(row[0], row[1], rockPart,
                                ["a": Color("#303234"), "b": p[0], "c": p[1]], .ground, row[2])
            }
            for row in [[19,35,19],[61,30,14],[111,34,24]] { draft.append(rect(row[0], row[1], row[2], 2, p[0], .ground)) }
        } else {
            draft += bitmap(11, 25, dunePart, ["a": p[0], "b": p[1]], .ground, 2)
            draft += bitmap(80, 20, dunePart, ["a": p[0], "b": p[1]], .ground, 2)
            for row in [[17,38,18],[58,34,13],[108,37,26]] { draft.append(rect(row[0], row[1], row[2], 1, p[2], .material)) }
        }
        if ["shelves", "islands"].contains(receipt.waterRelationship) {
            draft.append(rect(10, 42, 140, 48, water[0], .ground))
            draft.append(rect(10, 50, 140, 40, water[1], .water))
            for row in [[13,47,2],[65,42,2],[108,51,2],[33,72,2],[93,76,1]] {
                draft += bitmap(row[0], row[1], shelfPart, ["a": p[0], "b": p[1], "c": p[2]], .ground, row[2])
            }
            for row in [[12,63,22],[54,57,17],[99,70,24],[120,44,18]] {
                draft.append(rect(row[0], row[1], row[2], 1, water[2], .water))
                draft.append(rect(row[0] + 4, row[1] + 3, max(3, row[2] - 9), 1, "#9bc0c4", .water))
            }
            for row in [[17,53],[58,69],[102,57],[132,78]] { draft += bitmap(row[0], row[1], rockPart, ["a": p[0], "b": p[1], "c": p[2]], .material) }
        } else {
            draft.append(rect(10, 42, 140, 48, p[1], .ground))
            for index in 0..<34 {
                let x = 13 + jsModulo(seed, add: index * 41, modulus: 134)
                let y = 45 + jsModulo(seed >> 5, add: index * 23, modulus: 42)
                let width = 1 + Int((seed >> UInt32((index % 8) + 1)) & 3)
                draft.append(rect(x, y, width, 1, index % 3 == 0 ? p[0] : p[2], .material))
            }
            if receipt.waterRelationship == "pools" {
                for row in [[20,63,2],[86,70,2],[123,53,1]] { draft += bitmap(row[0], row[1], poolPart, ["a": p[0], "b": water[2], "c": water[1]], .water, row[2]) }
            }
            if receipt.waterRelationship == "channels" {
                for row in [[18,55,2],[63,64,2],[105,49,2]] { draft += bitmap(row[0], row[1], poolPart, ["a": p[0], "b": water[2], "c": water[1]], .water, row[2]) }
                for row in [[43,61,28],[89,69,25]] {
                    draft.append(rect(row[0], row[1], row[2], 2, water[1], .water))
                    draft.append(rect(row[0] + 3, row[1], row[2] - 7, 1, water[2], .water))
                }
            }
            if receipt.dominantGround == .stone {
                draft.append(rect(10, 10, 140, 17, "#303234", .ground))
                for row in [[11,17,3],[34,12,2],[52,18,2],[110,15,3],[132,21,2],[12,39,2],[135,43,2],[14,68,2],[136,70,2]] {
                    draft += bitmap(row[0], row[1], rockPart, ["a": Color("#303234"), "b": p[0], "c": p[1]], .ground, row[2])
                }
                let soil = palettes[.soil]!
                for y in 53..<90 {
                    let depth = y - 53, half = 5 + Int(floor(Double(depth) * 0.42))
                    let jitter = Int((seed >> UInt32((y - 53) % 16)) & 3) - 1
                    draft.append(rect(80 - half + jitter, y, half * 2, 1, y % 5 == 0 ? soil[2] : soil[1], .ground))
                }
                for row in [[15,55],[31,76],[117,59],[137,78],[102,42]] { draft += bitmap(row[0], row[1], rockPart, ["a": p[0], "b": p[1], "c": p[2]], .material) }
            } else {
                for row in [[17,48],[49,75],[111,62],[136,43]] { draft += bitmap(row[0], row[1], rockPart, ["a": p[0], "b": p[1], "c": p[2]], .material) }
            }
        }
        for index in 0..<26 {
            let x = 14 + jsModulo(seed, add: index * 37, modulus: 132)
            let y = 46 + jsModulo(seed >> 4, add: index * 23, modulus: 40)
            draft.append(rect(x, y, index % 5 == 0 ? 2 : 1, 1, index % 3 == 0 ? p[2] : p[0], .material))
        }
        for (speciesIndex, flora) in receipt.flora.enumerated() {
            _ = speciesIndex
            let count = flora.coverage == "abundant" ? 12 : flora.coverage == "present" ? 8 : 4
            let color = Color(rgb: flora.color), base = stableHash(flora.stableID)
            for index in 0..<count {
                let x = 16 + jsModulo(base, add: index * 29, modulus: 128)
                let y = 60 + jsModulo(base >> 5, add: index * 17, modulus: 25)
                let height = 3 + flora.formID % 4
                draft += bitmap(x - 3, y - height - 2, succulentPart,
                                ["a": color, "b": p[2], "c": p[0]], .flora)
            }
        }
        if receipt.suspendedAtmosphere.medium != "none" {
            let colors = ["smoke":"#817a70", "airborneAsh":"#a0a2a3", "mist":"#aebfc0", "miasma":"#947f98"]
            let counts = ["trace":5, "light":9, "heavy":15, "dense":22]
            let color = colors[receipt.suspendedAtmosphere.medium]!, count = counts[receipt.suspendedAtmosphere.density]!
            for index in 0..<count {
                let x = 14 + jsModulo(seed, add: index * 31, modulus: 132)
                let y = 20 + jsModulo(seed >> 7, add: index * 19, modulus: 58)
                draft.append(rect(x, y, index % 3 == 0 ? 4 : 2, index % 4 == 0 ? 2 : 1, color, .suspended))
            }
        }
        if receipt.precipitation.medium != "none" {
            let color = receipt.precipitation.medium == "rain" ? "#83b3c2" : receipt.precipitation.medium == "snow" ? "#dce3dd" : "#bdced1"
            let counts = ["trace":8, "light":14, "heavy":24]
            for index in 0..<counts[receipt.precipitation.intensity]! {
                let x = 14 + jsModulo(seed, add: index * 43, modulus: 132)
                let y = 16 + jsModulo(seed >> 8, add: index * 17, modulus: 68)
                draft.append(rect(x, y, 1, receipt.precipitation.medium == "snow" ? 1 : 3, color, .precipitation))
            }
        }
        if receipt.entryDisclosure != nil {
            draft += bitmap(124, 53, ["..aaa..", ".abbba.", "abcccba", "abcccba", ".abbba.", "..aaa.."],
                            ["a": Color("#6c5540"), "b": Color("#d0a66d"), "c": Color("#efe0b9")], .entryDisclosure, 2)
        }
        if let entryRune = receipt.sourcePage.marks.first {
            for cell in entryRune.cells {
                let dx = cell[0], dy = cell[1], x = 77 + dx * 2, y = 77 + dy * 2
                draft.append(rect(x, y, 2, 1, p[0], .entryMark))
                draft.append(rect(x + (dy % 2), y - 1, 1, 1, p[2], .entryMark))
            }
        }
        return try draft.enumerated().map { index, command in
            let result = WorldArrivalRenderedSceneReceipt.Command(
                x: command.x, y: command.y, width: command.width, height: command.height,
                rgba: command.color.values, scope: command.scope, sourceOrder: index)
            guard result.validates(expectedOrder: index) else { throw Error.invalidCommand }
            return result
        }
    }

    static func image(for receipt: WorldArrivalRenderedSceneReceipt) -> UIImage? {
        guard receipt.validates() else { return nil }
        let bytes = WorldArrivalRenderedSceneReceipt.render(receipt.commands)
        guard bytes.count == 160 * 100 * 4,
              let provider = CGDataProvider(data: Data(bytes) as CFData),
              let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let cgImage = CGImage(width: 160, height: 100, bitsPerComponent: 8,
                                    bitsPerPixel: 32, bytesPerRow: 160 * 4,
                                    space: colorSpace,
                                    bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
                                    provider: provider, decode: nil, shouldInterpolate: false,
                                    intent: .defaultIntent) else { return nil }
        return UIImage(cgImage: cgImage, scale: 1, orientation: .up)
    }

    private static func rect(_ x: Int, _ y: Int, _ width: Int, _ height: Int,
                             _ hex: String,
                             _ scope: WorldArrivalRenderedSceneReceipt.Command.Scope) -> DraftCommand {
        DraftCommand(x: x, y: y, width: width, height: height, color: Color(hex), scope: scope)
    }
    private static func rect(_ x: Int, _ y: Int, _ width: Int, _ height: Int,
                             _ color: Color,
                             _ scope: WorldArrivalRenderedSceneReceipt.Command.Scope) -> DraftCommand {
        DraftCommand(x: x, y: y, width: width, height: height, color: color, scope: scope)
    }
    private static func bitmap(_ x: Int, _ y: Int, _ rows: [String],
                               _ colors: [Character: Color],
                               _ scope: WorldArrivalRenderedSceneReceipt.Command.Scope,
                               _ scale: Int = 1) -> [DraftCommand] {
        var commands: [DraftCommand] = []
        for (rowIndex, row) in rows.enumerated() {
            let chars = Array(row); var start = 0
            while start < chars.count {
                let key = chars[start]; var end = start + 1
                while end < chars.count && chars[end] == key { end += 1 }
                if key != ".", let color = colors[key] {
                    commands.append(rect(x + start * scale, y + rowIndex * scale,
                                         (end - start) * scale, scale, color, scope))
                }
                start = end
            }
        }
        return commands
    }
    private static func stableHash(_ value: String) -> UInt32 {
        value.unicodeScalars.reduce(UInt32(2_166_136_261)) {
            ($0 ^ UInt32($1.value)) &* 16_777_619
        }
    }

    static func jsModulo(_ seed: UInt32, add: Int, modulus: Int) -> Int {
        Int((UInt64(seed) + UInt64(add)) % UInt64(modulus))
    }
}
