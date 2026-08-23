import Foundation
import UIKit

/// Mechanical Swift port of the accepted Asset compositor. It produces only the closed rect-v1
/// command ABI; title, prose, rules and disclosure classification remain outside this adapter.
enum WorldArrivalNativeRenderer {
    static func resourceOpportunitySlotCapacity(for size: CGSize) -> Int {
        let sceneWidth = max(0, Int(size.width - 24))
        let sceneHeight = max(0, Int(size.height - 24))
        return max(1, sceneWidth / 2) * max(1, sceneHeight / 2)
    }
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

    struct SplashCommand: Codable, Equatable, Sendable {
        enum Scope: String, Codable, CaseIterable, Sendable {
            case terrainMass, waterStructure, relief, surfaceDeposit, floraIdentity
            case floraDistribution, siteOpportunity, resourceOpportunity, illumination, suspendedAtmosphere
            case precipitation, entryMark
        }
        var scope: Scope
        var semanticID: String
        var regionColumn: Int?
        var regionRow: Int?
        var band: String?
        var values: [String]
    }

    static func splashCommands(for receipt: WorldSplashReceiptV3) -> [SplashCommand]? {
        guard receipt.validates(),
              let descriptor = try? receipt.terrain.materialPresentation.resolvedDescriptor()
        else { return nil }
        var result: [SplashCommand] = []
        let palettes = TerrainProductionPack.Ground.allCases.compactMap { ground -> String? in
            guard let colors = try? TerrainProductionPack.resolvedGroundPalette(
                ground, descriptor: descriptor) else { return nil }
            return ground.rawValue + "=" + colors.map { color in
                "\(color.red),\(color.green),\(color.blue),\(color.alpha)"
            }.joined(separator: "/")
        }
        guard palettes.count == TerrainProductionPack.Ground.allCases.count else { return nil }
        result.append(.init(scope: .terrainMass, semanticID: "material-presentation",
            regionColumn: nil, regionRow: nil,
            band: receipt.terrain.materialPresentation.canonicalPresentationSHA256,
            values: ["size=\(receipt.terrain.width)x\(receipt.terrain.height)",
                     "nonChasm=\(receipt.terrain.nonChasmTileCount)",
                     "dominant=\(receipt.terrain.dominantDryGround.rawValue)",
                     "secondary=\(receipt.terrain.secondaryVisibleGrounds.map(\.rawValue).joined(separator: ","))"]
                + receipt.terrain.grounds.map {
                    "\($0.ground.rawValue)=\($0.exactCount):\($0.coverage.rawValue)"
                } + palettes))
        let regions = receipt.terrain.regions.sorted(by: { ($0.row, $0.column) < ($1.row, $1.column) })
        for region in regions {
            result.append(.init(scope: .terrainMass, semanticID: "region",
                regionColumn: region.column, regionRow: region.row, band: nil,
                values: region.groundShares.map { "\($0.id)=\($0.exactCount):\($0.band.rawValue)" }))
        }
        for region in regions {
            result.append(.init(scope: .waterStructure, semanticID: "region",
                regionColumn: region.column, regionRow: region.row, band: nil,
                values: region.waterShares.map { "\($0.id)=\($0.exactCount):\($0.band.rawValue)" }))
        }
        result.append(.init(scope: .waterStructure, semanticID: "topology", regionColumn: nil,
            regionRow: nil, band: receipt.water.coverage.rawValue,
            values: ["shallow=\(receipt.water.shallowCount)",
                     "deep=\(receipt.water.deepCount)",
                     "frozen=\(receipt.water.frozenCount)",
                     "standing=\(receipt.water.standingOwnedCount)",
                     "flowing=\(receipt.water.flowingOwnedCount)",
                     "standingDeep=\(receipt.water.standingDeepCount)",
                     "flowingDeep=\(receipt.water.flowingDeepCount)",
                     "standingBodies=\(receipt.water.standingBodySizes.map(String.init).joined(separator: ","))",
                     "flowingChannels=\(receipt.water.flowingChannelSizes.map(String.init).joined(separator: ","))",
                     "finalBodies=\(receipt.water.finalConnectedBodyCount)",
                     "dryComponents=\(receipt.water.dryComponentCount)",
                     "nonChasmComponents=\(receipt.water.nonChasmComponentCount)",
                     "enclosedDry=\(receipt.water.enclosedDryComponentCount)",
                     "bodies=\(receipt.water.finalConnectedBodyCount)",
                     "dominant=\(receipt.water.dominantTopology?.rawValue ?? "none")"]
                + receipt.water.topologyFlags.map(\.rawValue)))
        for region in regions {
            result.append(.init(scope: .relief, semanticID: "region",
                regionColumn: region.column, regionRow: region.row, band: nil,
                values: region.elevationShares.map { "\($0.id)=\($0.exactCount):\($0.band.rawValue)" }))
        }
        result.append(.init(scope: .relief, semanticID: "shape", regionColumn: nil,
            regionRow: nil, band: String(receipt.relief.maximumElevation),
            values: receipt.relief.elevationCounts.enumerated().map { "e\($0.offset)=\($0.element)" }
                + ["elevated-components=\(receipt.relief.elevatedComponentSizes.map(String.init).joined(separator: ","))"]
                + receipt.relief.shapeFlags.map(\.rawValue)
                + receipt.relief.southContactCounts.map(String.init)))
        result.append(.init(scope: .surfaceDeposit, semanticID: "census",
            regionColumn: nil, regionRow: nil, band: nil,
            values: ["snow=\(receipt.deposits.snowCount):\(receipt.deposits.snowCoverage.rawValue)",
                     "settledAsh=\(receipt.deposits.settledAshCount):\(receipt.deposits.settledAshCoverage.rawValue)"]))
        for region in regions {
            result.append(.init(scope: .surfaceDeposit, semanticID: "region",
                regionColumn: region.column, regionRow: region.row, band: nil,
                values: region.depositShares.map { "\($0.id)=\($0.exactCount):\($0.band.rawValue)" }))
        }
        for species in receipt.flora.species {
            result.append(.init(scope: .floraIdentity, semanticID: species.stableID,
                regionColumn: nil, regionRow: nil, band: species.coverage.rawValue,
                values: [species.renderIdentity.speciesID,
                         String(species.renderIdentity.formID),
                         String(species.renderIdentity.stature),
                         species.renderIdentity.resolvedColor.resolutionVersion,
                         species.renderIdentity.resolvedColor.provenance]
                    + species.renderIdentity.resolvedColor.srgb.map(String.init)))
            result.append(.init(scope: .floraDistribution, semanticID: species.stableID,
                regionColumn: nil, regionRow: nil, band: species.habit,
                values: ["placed=\(species.placedTileCount)",
                         "coverage=\(species.coverage.rawValue)",
                         "eligible=\(species.eligibleGrounds.map(\.rawValue).joined(separator: ","))"]
                    + receipt.terrain.regions.enumerated().map { index, region in
                        let exact = region.floraShares.first { $0.id == species.stableID }?.exactCount ?? 0
                        let band = index < species.regionShares.count
                            ? species.regionShares[index].rawValue : "none"
                        return "r\(index)=\(exact):\(band)"
                    }))
        }
        if receipt.explorationOpportunities.hasGeneratedSiteOpportunity {
            result.append(.init(scope: .siteOpportunity, semanticID: "generated-site-present",
                regionColumn: nil, regionRow: nil, band: nil, values: []))
        }
        for resource in receipt.explorationOpportunities.resources {
            result.append(.init(scope: .resourceOpportunity, semanticID: resource.stableID,
                regionColumn: nil, regionRow: nil, band: nil,
                values: ["sources=\(resource.sourceCount)",
                         "quantity=\(resource.obtainableQuantity)",
                         "owners=\(resource.causalMarkIDs.map { String($0.rawValue) }.joined(separator: ","))"]))
        }
        result.append(.init(scope: .illumination, semanticID: receipt.environment.illuminationBand,
            regionColumn: nil, regionRow: nil, band: receipt.environment.illuminationSourceClass, values: []))
        result.append(.init(scope: .suspendedAtmosphere, semanticID: receipt.environment.suspendedMedium,
            regionColumn: nil, regionRow: nil, band: receipt.environment.suspendedDensity,
            values: [receipt.environment.suspendedMotion]))
        result.append(.init(scope: .precipitation, semanticID: receipt.environment.precipitationMedium,
            regionColumn: nil, regionRow: nil, band: receipt.environment.precipitationIntensity,
            values: [receipt.environment.precipitationMotion]))
        if let mark = receipt.entryMark {
            let minColumn = mark.cells.map(\.column).min() ?? 0
            let minRow = mark.cells.map(\.row).min() ?? 0
            let ink = mark.inkRecipe.map {
                [String($0.cyan), String($0.magenta), String($0.yellow), String($0.depth),
                 $0.conversionVersion] + $0.resolvedSRGB.map(String.init)
            } ?? ["open"]
            result.append(.init(scope: .entryMark, semanticID: String(mark.markID.rawValue),
                regionColumn: nil, regionRow: nil, band: mark.hand.rawValue,
                values: [mark.rendererAssetKey, mark.shapeID,
                         "origin=\(mark.origin.column),\(mark.origin.row)"]
                    + ink + mark.cells.map { "\($0.column - minColumn),\($0.row - minRow)" }))
        }
        return result
    }

    /// Functional v3 proof renderer. It deliberately uses primitive semantic blocks rather than
    /// pretending to be final Asset art, but every owned receipt scope visibly affects the scene.
    static func placeholderImage(for receipt: WorldSplashReceiptV3,
                                 size: CGSize = CGSize(width: 320, height: 200)) -> UIImage? {
        guard splashCommands(for: receipt) != nil,
              let descriptor = try? receipt.terrain.materialPresentation.resolvedDescriptor()
        else { return nil }
        let groundPalettes = Dictionary(uniqueKeysWithValues: GroundType.allCases.compactMap {
            ground -> (GroundType, [UIColor])? in
            guard let packGround = TerrainProductionPack.Ground(rawValue: ground.rawValue),
                  let palette = try? TerrainProductionPack.resolvedGroundPalette(
                    packGround, descriptor: descriptor), palette.count == 5 else { return nil }
            return (ground, palette.map { color in UIColor(red: CGFloat(color.red) / 255,
                                    green: CGFloat(color.green) / 255,
                                    blue: CGFloat(color.blue) / 255,
                                    alpha: CGFloat(color.alpha) / 255) })
        })
        guard groundPalettes.count == GroundType.allCases.count else { return nil }
        let groundColors = groundPalettes.mapValues { $0[2] }
        let depositPalettePairs: [(TerrainProductionPack.SurfaceDeposit, [UIColor])] =
            TerrainProductionPack.SurfaceDeposit.allCases.compactMap { deposit in
                guard let palette = try? TerrainProductionPack.resolvedSurfaceDepositPalette(
                    deposit, descriptor: descriptor), palette.count == 5 else { return nil }
                return (deposit, palette.map { color in UIColor(red: CGFloat(color.red) / 255,
                    green: CGFloat(color.green) / 255, blue: CGFloat(color.blue) / 255,
                    alpha: CGFloat(color.alpha) / 255) })
            }
        let depositPalettes = Dictionary(uniqueKeysWithValues: depositPalettePairs)
        guard depositPalettes.count == TerrainProductionPack.SurfaceDeposit.allCases.count else { return nil }
        guard size.width >= 320, size.height >= 200 else { return nil }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: size, format: format).image { renderer in
            drawPlaceholder(receipt, groundColors: groundColors,
                            groundPalettes: groundPalettes,
                            depositPalettes: depositPalettes,
                            in: renderer.cgContext, size: size)
        }
    }

    private static func drawPlaceholder(_ receipt: WorldSplashReceiptV3,
                                        groundColors: [GroundType: UIColor],
                                        groundPalettes: [GroundType: [UIColor]],
                                        depositPalettes: [TerrainProductionPack.SurfaceDeposit: [UIColor]],
                                        in context: CGContext, size: CGSize) {
        context.interpolationQuality = .none
        context.setFillColor(UIColor(red: 0.04, green: 0.07, blue: 0.08, alpha: 1).cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        let scene = CGRect(x: 8, y: 8, width: size.width - 16, height: size.height - 16)
        context.setFillColor(UIColor(red: 0.10, green: 0.15, blue: 0.17, alpha: 1).cgColor)
        context.fill(scene)
        context.saveGState()
        context.clip(to: scene)
        let cellWidth = scene.width / CGFloat(WorldSplashReceiptV3.regionColumns)
        let cellHeight = scene.height / CGFloat(WorldSplashReceiptV3.regionRows)
        for layer in SplashLayer.allCases {
            for region in receipt.terrain.regions {
                let rect = CGRect(x: scene.minX + CGFloat(region.column) * cellWidth,
                                  y: scene.minY + CGFloat(region.row) * cellHeight,
                                  width: cellWidth + 0.5, height: cellHeight + 0.5)
                drawPlaceholderRegion(region, layer: layer, receipt: receipt,
                                      groundColors: groundColors, groundPalettes: groundPalettes,
                                      depositPalettes: depositPalettes,
                                      in: context, rect: rect)
            }
            if layer == .water {
                drawWaterTopology(receipt, palettes: groundPalettes, in: context, scene: scene)
            }
            if layer == .relief { drawReliefTopology(receipt, in: context, scene: scene) }
        }
        drawEnvironmentAndEntry(receipt, groundPalettes: groundPalettes, in: context, scene: scene)
        drawExplorationOpportunities(receipt, groundPalettes: groundPalettes,
                                     in: context, scene: scene)
        context.restoreGState()
        context.setStrokeColor(UIColor(red: 0.85, green: 0.73, blue: 0.48, alpha: 1).cgColor)
        context.setLineWidth(4)
        context.stroke(scene)
    }

    private enum SplashLayer: CaseIterable { case terrain, water, relief, deposit, flora }

    private static func drawExplorationOpportunities(
        _ receipt: WorldSplashReceiptV3,
        groundPalettes: [GroundType: [UIColor]],
        in context: CGContext,
        scene: CGRect
    ) {
        let palette = groundPalettes[receipt.terrain.dominantDryGround] ?? []
        let siteColor = palette.indices.contains(1) ? palette[1] : .darkGray
        let resourceColor = palette.indices.contains(4) ? palette[4] : .lightGray
        if receipt.explorationOpportunities.hasGeneratedSiteOpportunity {
            let x = scene.minX + 22
            let y = scene.maxY - 24
            context.setFillColor(siteColor.cgColor)
            context.fill(CGRect(x: x - 4, y: y - 4, width: 9, height: 9))
            context.setFillColor(resourceColor.cgColor)
            context.fill(CGRect(x: x - 1, y: y - 7, width: 3, height: 15))
        }
        var resourcePixelCursor = 0
        let resourceColumns = max(1, Int(scene.width - 8) / 2)
        let resourceSlots = resourceOpportunitySlotCapacity(
            for: CGSize(width: scene.width + 16, height: scene.height + 16))
        guard receipt.explorationOpportunities.resources.reduce(0, {
            $0 + $1.sourceCount + $1.obtainableQuantity
        }) <= resourceSlots else { return }
        for resource in receipt.explorationOpportunities.resources {
            let identity = stableOpportunityHash(resource.stableID)
            let markCount = resource.sourceCount + resource.obtainableQuantity
            for index in 0..<markCount {
                let slot = resourcePixelCursor + index
                let x = scene.minX + 4 + CGFloat((slot % resourceColumns) * 2)
                let y = scene.maxY - 6 - CGFloat((slot / resourceColumns) * 2)
                context.setFillColor(resourceColor.cgColor)
                switch identity % 4 {
                case 0:
                    context.fill(CGRect(x: x, y: y, width: 2, height: 1))
                case 1:
                    context.fill(CGRect(x: x, y: y, width: 1, height: 2))
                case 2:
                    context.fill(CGRect(x: x, y: y, width: 1, height: 1))
                    context.fill(CGRect(x: x + 1, y: y + 1, width: 1, height: 1))
                default:
                    context.fill(CGRect(x: x + 1, y: y, width: 1, height: 1))
                    context.fill(CGRect(x: x, y: y + 1, width: 1, height: 1))
                }
            }
            resourcePixelCursor += markCount
        }
    }

    private static func stableOpportunityHash(_ value: String) -> UInt64 {
        value.utf8.reduce(UInt64(1_469_598_103_934_665_603)) {
            ($0 ^ UInt64($1)) &* 1_099_511_628_211
        }
    }

    private static func drawWaterTopology(_ receipt: WorldSplashReceiptV3,
                                          palettes: [GroundType: [UIColor]],
                                          in context: CGContext, scene: CGRect) {
        let flags = Set(receipt.water.topologyFlags)
        if flags.contains(.standing) {
            context.setFillColor((palettes[.water]?[2] ?? .clear).withAlphaComponent(0.72).cgColor)
            if flags.contains(.lake) {
                context.fillEllipse(in: .init(x: scene.midX - 58, y: scene.midY - 28,
                                              width: 116, height: 56))
            }
            if flags.contains(.pool) {
                let poolX = flags.contains(.lake) ? scene.midX + 66 : scene.midX - 31
                context.fillEllipse(in: .init(x: poolX, y: scene.midY + 24,
                                              width: 62, height: 30))
            }
        }
        if flags.contains(.flowing) || flags.contains(.channel) {
            context.setStrokeColor((palettes[.water]?[3] ?? .clear).cgColor)
            context.setLineWidth(5); context.move(to: .init(x: scene.minX + 18, y: scene.midY - 42))
            context.addCurve(to: .init(x: scene.maxX - 18, y: scene.midY + 38),
                control1: .init(x: scene.midX - 45, y: scene.midY + 12),
                control2: .init(x: scene.midX + 28, y: scene.midY - 18)); context.strokePath()
        }
        if flags.contains(.shelf) {
            context.setStrokeColor((palettes[.deepWater]?[1] ?? .clear).cgColor)
            context.setLineWidth(8); context.strokeEllipse(in: .init(
                x: scene.midX - 42, y: scene.midY - 19, width: 84, height: 38))
        }
        if flags.contains(.island) {
            context.setFillColor((palettes[receipt.terrain.dominantDryGround]?[2] ?? .clear).cgColor)
            context.fillEllipse(in: .init(x: scene.midX - 20, y: scene.midY - 13, width: 40, height: 26))
        }
        if flags.contains(.broken) {
            context.setStrokeColor((palettes[.deepWater]?[1] ?? .clear).cgColor)
            context.setLineWidth(3)
            for offset in [-52, 0, 52] {
                context.strokeEllipse(in: .init(x: scene.midX + CGFloat(offset) - 14,
                    y: scene.maxY - 38, width: 28, height: 14))
            }
        }
        if receipt.water.frozenCount > 0 {
            context.setStrokeColor((palettes[.ice]?[3] ?? .clear).cgColor)
            context.setLineWidth(2)
            for offset in stride(from: -54, through: 54, by: 18) {
                context.move(to: .init(x: scene.midX + CGFloat(offset), y: scene.minY + 16))
                context.addLine(to: .init(x: scene.midX + CGFloat(offset + 10), y: scene.minY + 34))
            }
            context.strokePath()
        }
    }

    private static func drawReliefTopology(_ receipt: WorldSplashReceiptV3,
                                           in context: CGContext, scene: CGRect) {
        for (index, count) in receipt.relief.southContactCounts.enumerated() where count > 0 {
            let depth = index + 1
            context.setStrokeColor(UIColor(white: 0.08, alpha: 0.16 + CGFloat(depth) * 0.08).cgColor)
            context.setLineWidth(CGFloat(depth * 2))
            let inset = CGFloat(16 + index * 12)
            context.move(to: .init(x: scene.minX + inset, y: scene.maxY - inset))
            context.addLine(to: .init(x: scene.maxX - inset, y: scene.minY + inset))
            context.strokePath()
        }
    }

    private static func drawEnvironmentAndEntry(_ receipt: WorldSplashReceiptV3,
                                                groundPalettes: [GroundType: [UIColor]],
                                                in context: CGContext, scene: CGRect) {
        let lightAlpha: CGFloat = switch receipt.environment.illuminationBand {
        case "trueDark": 0.42; case "dim": 0.24; case "bright": -0.08
        case "blazing": -0.16; default: 0
        }
        if lightAlpha > 0 {
            context.setFillColor(UIColor.black.withAlphaComponent(lightAlpha).cgColor); context.fill(scene)
        } else if lightAlpha < 0 {
            context.setFillColor(UIColor.white.withAlphaComponent(-lightAlpha).cgColor); context.fill(scene)
        }
        // The frozen source class owns presentation structure independently of brightness.
        if receipt.environment.illuminationSourceClass == "cyclic" {
            context.setFillColor(UIColor.white.withAlphaComponent(0.035).cgColor)
            for x in stride(from: scene.minX, to: scene.maxX, by: 28) {
                context.fill(.init(x: x, y: scene.minY, width: 8, height: scene.height))
            }
        } else if receipt.environment.illuminationSourceClass == "sourceless" {
            context.setStrokeColor(UIColor.black.withAlphaComponent(0.08).cgColor)
            context.setLineWidth(8); context.stroke(scene.insetBy(dx: 4, dy: 4))
        }
        if receipt.environment.suspendedMedium != "none" {
            let densityCounts = ["trace": 5, "light": 9, "heavy": 15, "dense": 22]
            let count = densityCounts[receipt.environment.suspendedDensity, default: 5]
            let color: UIColor = switch receipt.environment.suspendedMedium {
            case "smoke": UIColor(white: 0.58, alpha: 0.22)
            case "airborneAsh": UIColor(red: 0.42, green: 0.35, blue: 0.34, alpha: 0.24)
            case "mist": UIColor(red: 0.72, green: 0.82, blue: 0.84, alpha: 0.18)
            default: UIColor(red: 0.48, green: 0.66, blue: 0.48, alpha: 0.22)
            }
            let motion = receipt.environment.suspendedMotion == "strong" ? 13
                : receipt.environment.suspendedMotion == "moving" ? 7 : 0
            context.setFillColor(color.cgColor)
            for index in 0..<count {
                context.fillEllipse(in: .init(
                    x: scene.minX + CGFloat((index * 37 + motion) % max(1, Int(scene.width - 28))),
                    y: scene.minY + CGFloat((index * 23 + motion * 2) % max(1, Int(scene.height - 12))),
                    width: receipt.environment.suspendedMedium == "mist" ? 38 : 20,
                    height: receipt.environment.suspendedMedium == "airborneAsh" ? 4 : 10))
            }
        }
        if receipt.environment.precipitationMedium != "none" {
            let intensityCounts = ["trace": 8, "light": 14, "heavy": 22, "dense": 30]
            let count = intensityCounts[receipt.environment.precipitationIntensity, default: 8]
            let slant: CGFloat = receipt.environment.precipitationMotion == "strong" ? -6
                : receipt.environment.precipitationMotion == "moving" ? -3 : 0
            for index in 0..<count {
                let x = scene.minX + CGFloat((index * 19) % max(1, Int(scene.width)))
                let y = scene.minY + CGFloat((index * 31) % max(1, Int(scene.height)))
                let snow = receipt.environment.precipitationMedium == "snow"
                    || (receipt.environment.precipitationMedium == "mixedRainSnow" && index.isMultiple(of: 2))
                if snow {
                    context.setFillColor(UIColor(white: 0.94, alpha: 0.78).cgColor)
                    // Snow owns the same frozen motion channel as rain. Keep its
                    // flakes discrete, but move their deterministic fall track so
                    // calm, moving, and strong cannot collapse to one raster.
                    context.fillEllipse(in: .init(
                        x: x + slant,
                        y: y + abs(slant) * CGFloat((index % 3) + 1),
                        width: 4,
                        height: 4))
                } else {
                    context.setStrokeColor(UIColor(white: 0.82, alpha: 0.68).cgColor)
                    context.setLineWidth(2); context.move(to: .init(x: x, y: y))
                    context.addLine(to: .init(x: x + slant, y: y + 9)); context.strokePath()
                }
            }
        }
        if let mark = receipt.entryMark {
            let inkColor: UIColor
            if let rgb = mark.inkRecipe?.resolvedSRGB {
                inkColor = UIColor(red: CGFloat(rgb[0]) / 255, green: CGFloat(rgb[1]) / 255,
                                   blue: CGFloat(rgb[2]) / 255, alpha: 0.92)
            } else {
                inkColor = (groundPalettes[receipt.terrain.dominantDryGround]?[1] ?? .darkGray)
                    .withAlphaComponent(0.82)
            }
            context.setFillColor(inkColor.cgColor)
            let minX = mark.cells.map(\.column).min() ?? 0, minY = mark.cells.map(\.row).min() ?? 0
            let maxX = mark.cells.map(\.column).max() ?? minX, maxY = mark.cells.map(\.row).max() ?? minY
            let extent = mark.hand == .crude ? 5 : mark.hand == .plain ? 4 : 3
            let originX = scene.midX - CGFloat((maxX - minX + 1) * extent) / 2
            let originY = scene.midY - CGFloat((maxY - minY + 1) * extent) / 2
            for cell in mark.cells { context.fill(.init(
                x: originX + CGFloat((cell.column - minX) * extent),
                y: originY + CGFloat((cell.row - minY) * extent),
                width: CGFloat(extent), height: CGFloat(extent))) }
        }
    }

    private static func drawPlaceholderRegion(_ region: WorldSplashReceiptV3.Region,
                                              layer: SplashLayer,
                                              receipt: WorldSplashReceiptV3,
                                              groundColors: [GroundType: UIColor],
                                              groundPalettes: [GroundType: [UIColor]],
                                              depositPalettes: [TerrainProductionPack.SurfaceDeposit: [UIColor]],
                                              in context: CGContext, rect: CGRect) {
        switch layer {
        case .terrain:
            let represented = region.groundShares.compactMap { share -> (GroundType, Int)? in
                guard share.band != .none, let ground = GroundType(rawValue: share.id) else { return nil }
                return (ground, max(1, share.exactCount))
            }
            let total = max(1, represented.reduce(0) { $0 + $1.1 })
            var cursor = rect.minX
            for (index, representedGround) in represented.enumerated() {
                let width = index == represented.count - 1 ? rect.maxX - cursor
                    : rect.width * CGFloat(representedGround.1) / CGFloat(total)
                context.setFillColor((groundColors[representedGround.0] ?? .black).cgColor)
                context.fill(CGRect(x: cursor, y: rect.minY, width: max(1, width), height: rect.height))
                cursor += width
            }
            if represented.isEmpty {
                context.setFillColor((groundColors[receipt.terrain.dominantDryGround] ?? .black).cgColor)
                context.fill(rect)
            }
        case .water:
            let colors: [String: UIColor] = [
                "shallow": groundColors[.water] ?? .clear,
                "deep": groundColors[.deepWater] ?? .clear,
                "frozen": groundColors[.ice] ?? .clear
            ]
            let represented = region.waterShares.filter { $0.band != .none }
            let exactWater = represented.reduce(0) { $0 + $1.exactCount }
            let regionTotal = max(1, region.groundShares.reduce(0) { $0 + $1.exactCount })
            let waterHeight = exactWater == 0 ? 0
                : max(1, rect.height * CGFloat(exactWater) / CGFloat(regionTotal))
            let waterMinY = rect.maxY - waterHeight
            let total = max(1, exactWater)
            var cursor = rect.maxY
            for (index, share) in represented.enumerated() {
                let weight = max(1, share.exactCount)
                let height = index == represented.count - 1 ? cursor - waterMinY
                    : waterHeight * CGFloat(weight) / CGFloat(total)
                context.setFillColor((colors[share.id] ?? .clear).cgColor)
                context.fill(CGRect(x: rect.minX, y: cursor - max(1, height),
                                    width: rect.width, height: max(1, height)))
                cursor -= height
            }
        case .relief:
            let represented = region.elevationShares.enumerated().filter { $0.offset > 0 && $0.element.band != .none }
            let total = max(1, region.elevationShares.reduce(0) { $0 + $1.exactCount })
            let zeroCount = region.elevationShares.first?.exactCount ?? 0
            var cursor = rect.minX + rect.width * CGFloat(zeroCount) / CGFloat(total)
            for entry in represented {
                let level = entry.offset
                let weight = max(1, entry.element.exactCount)
                let width = rect.width * CGFloat(weight) / CGFloat(total)
                context.setFillColor(UIColor.black.withAlphaComponent(0.12 * CGFloat(level)).cgColor)
                context.fill(CGRect(x: cursor, y: rect.maxY - CGFloat(level * 3),
                                    width: max(1, width), height: CGFloat(level * 3)))
                cursor += width
            }
        case .deposit:
            for (depositIndex, deposit) in region.depositShares.enumerated() where deposit.band != .none {
                    let semantic: TerrainProductionPack.SurfaceDeposit = deposit.id == "snow"
                        ? .snow : .settledAsh
                    let depositColor = (depositPalettes[semantic]?[3] ?? .clear).withAlphaComponent(0.82)
                    context.setFillColor(depositColor.cgColor)
                    let count = max(1, splashWeight(deposit.band))
                    for index in 0..<count {
                        let x = rect.minX + 8 + CGFloat((index * 19 + depositIndex * 11 + region.column * 7) % max(1, Int(rect.width - 16)))
                        let y = rect.minY + 7 + CGFloat((index * 13 + region.row * 9) % max(1, Int(rect.height - 14)))
                        context.fill(CGRect(x: x, y: y, width: 5, height: 3))
                    }
            }
        case .flora:
            var ownershipCursor = 0
            for (speciesIndex, species) in receipt.flora.species.enumerated() {
                    let regionIndex = region.row * WorldSplashReceiptV3.regionColumns + region.column
                    let share = region.floraShares[speciesIndex]
                    guard share.exactCount > 0 else { continue }
                    let rgb = species.renderIdentity.resolvedColor.srgb
                    guard rgb.count == 3 else { continue }
                    let color = UIColor(red: CGFloat(rgb[0]) / 255,
                                                 green: CGFloat(rgb[1]) / 255,
                                                 blue: CGFloat(rgb[2]) / 255, alpha: 0.96)
                    context.setFillColor(color.cgColor)
                    let count = share.exactCount
                    for index in 0..<count {
                        let spread = species.habit == "spreading" || species.habit == "mixed"
                        let cluster = species.habit == "clustered"
                        let xOffset = cluster ? (index % 4) * 4
                            : index * (spread ? 31 : 17)
                        let yOffset = cluster ? ((index / 4) % 4) * 4
                            : index * (spread ? 19 : 11)
                        let x = rect.minX + 5 + CGFloat((xOffset + speciesIndex * 23 + region.row * 5) % max(1, Int(rect.width - 10)))
                        let y = rect.minY + 8 + CGFloat((yOffset + speciesIndex * 7 + region.column * 13) % max(1, Int(rect.height - 16)))
                        drawFloraGlyph(formID: species.renderIdentity.formID,
                                       stature: species.renderIdentity.stature,
                                       at: CGPoint(x: x, y: y), color: color, in: context)
                        // Every exact placed member owns one collision-free regional pixel. The
                        // larger glyph carries form/stature/habit; this ledger prevents distinct
                        // exact counts from collapsing through glyph overlap.
                        let slot = ownershipCursor + index
                        let ownershipX = rect.minX + CGFloat(slot % max(1, Int(rect.width)))
                        let ownershipY = rect.maxY - 1 - CGFloat(slot / max(1, Int(rect.width)))
                        context.fill(CGRect(x: ownershipX, y: ownershipY, width: 1, height: 1))
                    }
                    ownershipCursor += count
                    _ = regionIndex
            }
        }
    }

    private static func drawFloraGlyph(formID: Int, stature: Double, at point: CGPoint,
                                       color: UIColor, in context: CGContext) {
        let extent = CGFloat(3 + min(5, max(0, Int(stature / 20))))
        context.setFillColor(color.cgColor)
        switch formID {
        case 0:
            context.fill(CGRect(x: point.x, y: point.y - extent, width: extent, height: extent))
        case 1:
            context.fill(CGRect(x: point.x + extent / 2, y: point.y - extent * 1.5,
                                width: 2, height: extent * 1.5))
            context.fillEllipse(in: CGRect(x: point.x, y: point.y - extent * 1.7,
                                           width: extent + 2, height: extent))
        case 2:
            context.fill(CGRect(x: point.x + extent / 2, y: point.y - extent,
                                width: 2, height: extent * 1.4))
            context.fill(CGRect(x: point.x, y: point.y - extent / 2,
                                width: extent + 2, height: 2))
        default:
            context.move(to: CGPoint(x: point.x + extent / 2, y: point.y - extent))
            context.addLine(to: CGPoint(x: point.x + extent, y: point.y - extent / 2))
            context.addLine(to: CGPoint(x: point.x + extent / 2, y: point.y))
            context.addLine(to: CGPoint(x: point.x, y: point.y - extent / 2))
            context.closePath(); context.fillPath()
        }
    }

    private static func splashWeight(_ band: WorldSplashReceiptV3.CoverageBand) -> Int {
        WorldSplashReceiptV3.CoverageBand.allCases.firstIndex(of: band) ?? 0
    }

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
