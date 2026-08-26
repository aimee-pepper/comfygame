import CryptoKit
import Foundation

struct WorldArrivalReceiptID: RawRepresentable, Codable, Equatable, Hashable, Sendable {
    var rawValue: String
    init(rawValue: String) { self.rawValue = rawValue }
}

/// Pending arrival ownership is intentionally disabled until the accepted native B1.6a root and
/// its single centralized world-action gate are integrated. Receipt persistence is independently
/// live now; placeholder receipt fields must never become player-facing presentation.
enum WorldArrivalPresentationAuthority {
    static let isNativePresentationEnabled = true
}

/// Complete, disclosure-safe input for the World Splash. This is deliberately separate from the
/// accepted v2 compositor receipt: old receipts remain byte-stable while new binds freeze the
/// generated world's visible terrain, water, relief, deposits and every placed flora identity.
struct WorldSplashReceiptV3: Codable, Equatable, Sendable {
    static let schemaVersion = "world-splash-v3"
    static let regionColumns = 4
    static let regionRows = 3
    /// One generated source occupies one tile. The richest legal source is a concentrated
    /// substrate node: 5 successful hits × 7 units. Raw drops and flora nodes are lower.
    static let maximumObtainableQuantityPerSource = 35
    /// Collision-free opportunity slots in the canonical 320×360 proof scene (8pt inset,
    /// two logical pixels per slot). Persisted receipts exceeding this fail closed.
    // Canonical 320×360 proof scene: the inset 296×336 interior owns a
    // collision-free 2×2 opportunity ledger (148×168 slots).
    static let maximumResourceOpportunityMarks = 24_864

    enum CoverageBand: String, Codable, CaseIterable, Sendable {
        case none, trace, sparse, present, abundant, dominant
    }
    enum WaterTopology: String, Codable, CaseIterable, Sendable {
        case standing, flowing, pool, lake, channel, shelf, island, broken
    }
    enum ReliefShape: String, Codable, CaseIterable, Sendable { case flat }
    struct Share: Codable, Equatable, Sendable {
        var id: String
        var exactCount: Int
        var band: CoverageBand
    }
    struct Region: Codable, Equatable, Sendable {
        var column: Int
        var row: Int
        var groundShares: [Share]
        var waterShares: [Share]
        var elevationShares: [Share]
        var depositShares: [Share]
        var floraShares: [Share]
    }
    struct GroundCensus: Codable, Equatable, Sendable {
        var ground: GroundType
        var exactCount: Int
        var coverage: CoverageBand
    }
    /// The exact immutable subset of WorldGrade2 needed to reproduce material-owned map palettes.
    /// Flora is intentionally absent: zero-placement species cannot leak into the Splash receipt.
    struct MaterialPresentationDescriptor: Codable, Equatable, Sendable {
        var versions: WorldGrade2V1.Versions
        var material: WorldGrade2V1.Material
        var atmosphere: WorldGrade2V1.Atmosphere
        var resolvedMaterialColor: WorldGrade2V1.ResolvedColor?
        var resolvedAtmosphereColor: WorldGrade2V1.ResolvedColor?
        var canonicalPresentationSHA256: String

        func resolvedDescriptor() throws -> WorldGrade2V1.Descriptor {
            try WorldGrade2V1.resolve(.init(
                versions: versions, material: material, atmosphere: atmosphere,
                flora: .init(coveragePercent: 0, paletteRichness: 0, cast: []),
                resolvedColors: .init(material: resolvedMaterialColor,
                                      atmosphere: resolvedAtmosphereColor)))
        }

        func validates() -> Bool {
            var copy = self
            copy.canonicalPresentationSHA256 = ""
            guard canonicalPresentationSHA256 == (try? WorldGrade2V1.canonicalSHA256(copy)),
                  (try? resolvedDescriptor()) != nil else { return false }
            return true
        }

        static func make(from descriptor: WorldGrade2V1.Descriptor) -> Self? {
            var result = Self(
                versions: descriptor.versions, material: descriptor.material,
                atmosphere: descriptor.atmosphere,
                resolvedMaterialColor: descriptor.resolvedColors.material,
                resolvedAtmosphereColor: descriptor.resolvedColors.atmosphere,
                canonicalPresentationSHA256: "")
            result.canonicalPresentationSHA256 = (try? WorldGrade2V1.canonicalSHA256(result)) ?? ""
            return result.validates() ? result : nil
        }
    }
    struct TerrainProfile: Codable, Equatable, Sendable {
        var width: Int
        var height: Int
        var nonChasmTileCount: Int
        var grounds: [GroundCensus]
        var dominantDryGround: GroundType
        var secondaryVisibleGrounds: [GroundType]
        var materialPresentation: MaterialPresentationDescriptor
        var regions: [Region]
    }
    struct WaterProfile: Codable, Equatable, Sendable {
        var shallowCount: Int
        var deepCount: Int
        var frozenCount: Int
        var standingOwnedCount: Int
        var flowingOwnedCount: Int
        var standingDeepCount: Int
        var flowingDeepCount: Int
        var standingBodySizes: [Int]
        var flowingChannelSizes: [Int]
        var finalConnectedBodyCount: Int
        var dryComponentCount: Int
        var nonChasmComponentCount: Int
        var enclosedDryComponentCount: Int
        var coverage: CoverageBand
        var dominantTopology: WaterTopology?
        var topologyFlags: [WaterTopology]
    }
    struct ReliefProfile: Codable, Equatable, Sendable {
        var elevationCounts: [Int]
        var maximumElevation: Int
        var southContactCounts: [Int]
        var elevatedComponentSizes: [Int]
        var shapeFlags: [ReliefShape]
    }
    struct FloraSpecies: Codable, Equatable, Sendable {
        var stableID: String
        var renderIdentity: WorldGrade2V1.FloraSpecies
        var placedTileCount: Int
        var coverage: CoverageBand
        var habit: String
        var eligibleGrounds: [GroundType]
        var regionShares: [CoverageBand]
    }
    struct FloraProfile: Codable, Equatable, Sendable {
        var placedIdentityCount: Int
        var occupiedTileCount: Int
        var aggregateCoverage: CoverageBand
        var species: [FloraSpecies]
    }
    struct DepositProfile: Codable, Equatable, Sendable {
        var snowCount: Int
        var snowCoverage: CoverageBand
        var settledAshCount: Int
        var settledAshCoverage: CoverageBand
    }
    struct EnvironmentProfile: Codable, Equatable, Sendable {
        var illuminationBand: String
        var illuminationSourceClass: String
        var suspendedMedium: String
        var suspendedDensity: String
        var suspendedMotion: String
        var precipitationMedium: String
        var precipitationIntensity: String
        var precipitationMotion: String
    }
    struct ExplorationOpportunityRow: Codable, Equatable, Sendable {
        var stableID: String
        var sourceCount: Int
        var obtainableQuantity: Int
        var causalMarkIDs: [InstanceID]
    }
    /// Coordinate-free reasons to explore. Sites disclose presence only; rare/precious resource
    /// families retain exact obtainable-source counts. InstanceIDs, contents and positions do not.
    struct ExplorationOpportunityProfile: Codable, Equatable, Sendable {
        var hasGeneratedSiteOpportunity: Bool
        var resources: [ExplorationOpportunityRow]
    }
    struct EntryMark: Codable, Equatable, Sendable {
        var markID: InstanceID
        var rendererAssetKey: String
        var hand: Hand
        var origin: PageCell
        var shapeID: String
        var cells: [PageCell]
        var inkRecipe: InkRecipe?
    }

    var version: String
    var receiptID: WorldArrivalReceiptID
    var worldSeed: UInt64
    var worldVisualReceiptSHA256: String
    var sourcePagePhysicalReceipt: WorldArrivalReceipt.SourcePage
    var descriptionGrammarVersion: String
    var finalDescription: String
    var terrain: TerrainProfile
    var water: WaterProfile
    var relief: ReliefProfile
    var deposits: DepositProfile
    var flora: FloraProfile
    var explorationOpportunities: ExplorationOpportunityProfile
    var environment: EnvironmentProfile
    var causalVisualFacts: [WorldArrivalReceipt.CausalVisualFact]
    var entryMark: EntryMark?
    var firstMapCropReceipt: WorldArrivalReceipt.FirstMapCrop
    var canonicalReceiptSHA256: String

    func validates() -> Bool {
        var registeredResourcesByCausalMark: [InstanceID: Set<ResourceID>] = [:]
        for fact in causalVisualFacts
        where fact.scope == .resource && fact.contributionKind == .increased {
            guard let semanticKey = fact.semanticKey,
                  let symbol = ContentCatalog.shared.symbol(.init(rawValue: semanticKey))
            else { continue }
            registeredResourcesByCausalMark[fact.candidateMarkID, default: []]
                .formUnion(symbol.yieldModifiers.keys)
        }
        guard version == Self.schemaVersion,
              !receiptID.rawValue.isEmpty,
              !worldVisualReceiptSHA256.isEmpty,
              (1...128).contains(sourcePagePhysicalReceipt.width),
              (1...128).contains(sourcePagePhysicalReceipt.height),
              (1...128).contains(terrain.width), (1...128).contains(terrain.height),
              terrain.width == terrain.height,
              WorldScale.allCases.map(\.gridSide).contains(terrain.width),
              terrain.grounds.map(\.ground) == GroundType.allCases else { return false }
        let multiplied = terrain.width.multipliedReportingOverflow(by: terrain.height)
        guard !multiplied.overflow, multiplied.partialValue > 0 else { return false }
        let tileCount = multiplied.partialValue
        var totalResourceMarks = 0
        for row in explorationOpportunities.resources {
            let rowMarks = row.sourceCount.addingReportingOverflow(row.obtainableQuantity)
            guard !rowMarks.overflow else { return false }
            let total = totalResourceMarks.addingReportingOverflow(rowMarks.partialValue)
            guard !total.overflow else { return false }
            totalResourceMarks = total.partialValue
        }
        guard totalResourceMarks <= Self.maximumResourceOpportunityMarks else { return false }
        guard relief.elevationCounts.count == 4,
              relief.southContactCounts.count == 3,
              terrain.regions.count == Self.regionColumns * Self.regionRows else { return false }
        let groundCounts = Dictionary(uniqueKeysWithValues:
            terrain.grounds.map { ($0.ground, $0.exactCount) })
        guard [water.shallowCount, water.deepCount, water.frozenCount,
               water.standingOwnedCount, water.flowingOwnedCount,
               water.standingDeepCount, water.flowingDeepCount,
               water.finalConnectedBodyCount, water.dryComponentCount,
               water.nonChasmComponentCount, water.enclosedDryComponentCount]
            .allSatisfy({ (0...tileCount).contains($0) }),
              water.standingBodySizes.count <= tileCount,
              water.flowingChannelSizes.count <= tileCount,
              water.standingBodySizes.allSatisfy({ (1...tileCount).contains($0) }),
              water.flowingChannelSizes.allSatisfy({ (1...tileCount).contains($0) }) else { return false }
        var expectedWaterFlags: [WaterTopology] = []
        if water.standingOwnedCount > 0 {
            expectedWaterFlags.append(.standing)
            if water.standingBodySizes.contains(where: { $0 < 9 }) { expectedWaterFlags.append(.pool) }
            if water.standingBodySizes.contains(where: { $0 >= 9 }) { expectedWaterFlags.append(.lake) }
            if water.standingDeepCount > 0 { expectedWaterFlags.append(.shelf) }
        }
        if water.flowingOwnedCount > 0 { expectedWaterFlags += [.flowing, .channel] }
        if water.enclosedDryComponentCount > 0 { expectedWaterFlags.append(.island) }
        if water.dryComponentCount > water.nonChasmComponentCount { expectedWaterFlags.append(.broken) }
        let dryOrder: [GroundType] = [.stone, .soil, .sand, .ice, .ash, .rubble, .mud, .growth, .groundcover]
        let canonicalDry = dryOrder.filter { groundCounts[$0, default: 0] > 0 }.sorted { left, right in
            let leftCount = groundCounts[left, default: 0], rightCount = groundCounts[right, default: 0]
            return leftCount == rightCount
                ? dryOrder.firstIndex(of: left)! < dryOrder.firstIndex(of: right)!
                : leftCount > rightCount
        }
        let firstPhysicalMark = sourcePagePhysicalReceipt.marks.first
        let entryValid = entryMark.map { mark in
            guard !mark.rendererAssetKey.isEmpty, !mark.shapeID.isEmpty, !mark.cells.isEmpty,
                  Set(mark.cells).count == mark.cells.count,
                  (0..<sourcePagePhysicalReceipt.width).contains(mark.origin.column),
                  (0..<sourcePagePhysicalReceipt.height).contains(mark.origin.row),
                  mark == firstPhysicalMark.map({ EntryMark(markID: $0.id,
                      rendererAssetKey: $0.rendererAssetKey, hand: $0.hand, origin: $0.origin,
                      shapeID: $0.shapeID, cells: $0.cells, inkRecipe: $0.inkRecipe) }) else { return false }
            return mark.cells.allSatisfy { cell in
                cell.column >= 0 && cell.row >= 0
                    && cell.column < sourcePagePhysicalReceipt.width
                    && cell.row < sourcePagePhysicalReceipt.height
            }
        } ?? (firstPhysicalMark == nil)
        let crop = firstMapCropReceipt
        let cropPoints = crop.cells.map(\.point)
        let cropXs = Set(cropPoints.map(\.x)), cropYs = Set(cropPoints.map(\.y))
        let floraIDs = Set(flora.species.map(\.stableID))
        let cropValid = crop.width == 9 && crop.height == 9 && crop.cells.count == 81
            && Set(cropPoints).count == 81 && cropXs.count == 9 && cropYs.count == 9
            && cropXs.max().map({ $0 - (cropXs.min() ?? $0) == 8 }) == true
            && cropYs.max().map({ $0 - (cropYs.min() ?? $0) == 8 }) == true
            && crop.cells.allSatisfy { cell in
                guard ["full", "fringe", "remembered", "hidden"].contains(cell.visibility)
                else { return false }
                if cell.visibility == "hidden" {
                    return cell.ground == nil && cell.elevation == nil && cell.floraStableID == nil
                }
                guard let ground = cell.ground, let elevation = cell.elevation,
                      groundCounts[ground, default: 0] > 0,
                      (0...3).contains(elevation), relief.elevationCounts[elevation] > 0
                else { return false }
                guard cell.visibility == "full" || cell.floraStableID == nil else { return false }
                return cell.floraStableID.map { floraIDs.contains($0) } ?? true
            }
        let canonicalRegions = terrain.regions.enumerated().allSatisfy { index, region in
            region.column == index % Self.regionColumns && region.row == index / Self.regionColumns
        }
        guard
              terrain.grounds.allSatisfy({ (0...tileCount).contains($0.exactCount) }),
              terrain.grounds.allSatisfy({ $0.coverage == Self.coverageBand($0.exactCount, of: tileCount) }),
              terrain.grounds.reduce(0, { $0 + $1.exactCount }) == tileCount,
              terrain.nonChasmTileCount == tileCount - groundCounts[.chasm, default: 0],
              terrain.dominantDryGround == canonicalDry.first,
              terrain.secondaryVisibleGrounds == Array(canonicalDry.dropFirst()),
              terrain.materialPresentation.validates(),
              cropValid,
              canonicalRegions,
              Set(terrain.regions.map { "\($0.column),\($0.row)" }).count == terrain.regions.count,
              terrain.regions.allSatisfy({ region in
                  guard (0..<Self.regionColumns).contains(region.column),
                        (0..<Self.regionRows).contains(region.row) else { return false }
                  let regionTotal = Self.regionCellCount(column: region.column, row: region.row,
                                                         width: terrain.width, height: terrain.height)
                  let allShares = region.groundShares + region.waterShares + region.elevationShares
                    + region.depositShares + region.floraShares
                  return
                    allShares.allSatisfy({ (0...regionTotal).contains($0.exactCount)
                        && $0.band == Self.coverageBand($0.exactCount, of: regionTotal) })
                    && (0..<Self.regionRows).contains(region.row)
                    && region.groundShares.map(\.id) == GroundType.allCases.map(\.rawValue)
                    && region.groundShares.reduce(0, { $0 + $1.exactCount }) == regionTotal
                    && region.waterShares.map(\.id) == ["shallow", "deep", "frozen"]
                    && region.waterShares.map(\.exactCount) == [
                        region.groundShares.first(where: { $0.id == GroundType.water.rawValue })?.exactCount ?? -1,
                        region.groundShares.first(where: { $0.id == GroundType.deepWater.rawValue })?.exactCount ?? -1,
                        region.groundShares.first(where: { $0.id == GroundType.ice.rawValue })?.exactCount ?? -1]
                    && region.elevationShares.map(\.id) == ["0", "1", "2", "3"]
                    && region.elevationShares.reduce(0, { $0 + $1.exactCount }) == regionTotal
                    && region.depositShares.map(\.id) == ["snow", "settledAsh"]
                    && region.depositShares.allSatisfy({ $0.exactCount <= regionTotal })
                    && region.floraShares.map(\.id) == flora.species.map(\.stableID)
                    && region.floraShares.reduce(0, { $0 + $1.exactCount }) <= regionTotal
              }),
              GroundType.allCases.enumerated().allSatisfy({ index, ground in
                  terrain.regions.reduce(0) { $0 + $1.groundShares[index].exactCount }
                    == groundCounts[ground, default: 0]
              }),
              (0...3).allSatisfy({ level in
                  terrain.regions.reduce(0) { $0 + $1.elevationShares[level].exactCount }
                    == relief.elevationCounts[level]
              }),
              terrain.regions.reduce(0, { $0 + $1.depositShares[0].exactCount }) == deposits.snowCount,
              terrain.regions.reduce(0, { $0 + $1.depositShares[1].exactCount }) == deposits.settledAshCount,
              relief.elevationCounts.count == 4,
              relief.elevationCounts.allSatisfy({ (0...tileCount).contains($0) }),
              relief.elevationCounts.reduce(0, +) == tileCount,
              relief.maximumElevation == (relief.elevationCounts.lastIndex(where: { $0 > 0 }) ?? 0),
              relief.southContactCounts.count == 3,
              relief.southContactCounts.allSatisfy({ (0...tileCount).contains($0) }),
              relief.elevatedComponentSizes.count <= tileCount,
              relief.elevatedComponentSizes.allSatisfy({ (1...tileCount).contains($0) }),
              relief.elevatedComponentSizes == relief.elevatedComponentSizes.sorted(),
              relief.elevatedComponentSizes.reduce(0, +) == relief.elevationCounts.dropFirst().reduce(0, +),
              relief.shapeFlags == (relief.maximumElevation == 0 ? [.flat] : []),
              water.shallowCount >= 0, water.deepCount >= 0, water.frozenCount >= 0,
              water.shallowCount == groundCounts[.water, default: 0],
              water.deepCount == groundCounts[.deepWater, default: 0],
              water.frozenCount == groundCounts[.ice, default: 0],
              water.standingOwnedCount + water.flowingOwnedCount == water.shallowCount + water.deepCount,
              water.standingDeepCount + water.flowingDeepCount == water.deepCount,
              water.standingBodySizes == water.standingBodySizes.sorted(),
              water.flowingChannelSizes == water.flowingChannelSizes.sorted(),
              water.standingBodySizes.reduce(0, +) == water.standingOwnedCount,
              water.flowingChannelSizes.reduce(0, +) == water.flowingOwnedCount,
              water.enclosedDryComponentCount <= water.dryComponentCount,
              water.coverage == Self.coverageBand(water.shallowCount + water.deepCount + water.frozenCount,
                                                  of: tileCount),
              water.topologyFlags == expectedWaterFlags,
              water.topologyFlags.contains(.standing) || water.topologyFlags.contains(.flowing)
                ? (water.dominantTopology == .standing || water.dominantTopology == .flowing)
                    && water.dominantTopology == (water.standingOwnedCount >= water.flowingOwnedCount
                        ? .standing : .flowing)
                : water.dominantTopology == nil,
              deposits.snowCount >= 0, deposits.settledAshCount >= 0,
              deposits.snowCount <= tileCount, deposits.settledAshCount <= tileCount,
              deposits.snowCoverage == Self.coverageBand(deposits.snowCount, of: tileCount),
              deposits.settledAshCoverage == Self.coverageBand(deposits.settledAshCount, of: tileCount),
              explorationOpportunities.resources == explorationOpportunities.resources.sorted(by: {
                $0.stableID < $1.stableID
              }),
              Set(explorationOpportunities.resources.map(\.stableID)).count
                == explorationOpportunities.resources.count,
              explorationOpportunities.resources.allSatisfy({ row in
                let resourceID = ResourceID(rawValue: row.stableID)
                let maximumQuantity = row.sourceCount.multipliedReportingOverflow(
                    by: Self.maximumObtainableQuantityPerSource)
                return !maximumQuantity.overflow && !row.stableID.isEmpty
                    && (1...tileCount).contains(row.sourceCount)
                    && (1...maximumQuantity.partialValue).contains(row.obtainableQuantity)
                    && row.causalMarkIDs == row.causalMarkIDs.sorted { $0.rawValue < $1.rawValue }
                    && Set(row.causalMarkIDs).count == row.causalMarkIDs.count
                    && row.causalMarkIDs.allSatisfy {
                        registeredResourcesByCausalMark[$0]?.contains(resourceID) == true
                    }
                    && ContentCatalog.shared.resource(resourceID).map {
                        $0.tradeBand == .rare || $0.tradeBand == .precious
                            || !row.causalMarkIDs.isEmpty
                    } == true
              }),
              flora.species.count <= tileCount,
              flora.species.allSatisfy({ (1...terrain.nonChasmTileCount).contains($0.placedTileCount) }),
              flora.species.allSatisfy({ species in
                  let color = species.renderIdentity.resolvedColor
                  let suffix = String(species.stableID.dropFirst("flora-".count))
                  let canonicalInstanceID = species.stableID.hasPrefix("flora-")
                    && UInt64(suffix).map(String.init) == suffix
                  return species.stableID == species.renderIdentity.speciesID
                    && canonicalInstanceID
                    && (0...3).contains(species.renderIdentity.formID)
                    && species.renderIdentity.stature.isFinite
                    && (0...100).contains(species.renderIdentity.stature)
                    && color.srgb.count == 3 && color.srgb.allSatisfy({ (0...255).contains($0) })
                    && color.resolutionVersion == "resolved-color-1.0.0"
                    && ["authoredMix", "bindRandom"].contains(color.provenance)
                    && Habit.allCases.map(\.rawValue).contains(species.habit)
                    && species.eligibleGrounds == GroundType.allCases.filter {
                        $0.isPassable && $0 != .water && !$0.isOvergrown
                    }
              }),
              flora.occupiedTileCount == flora.species.reduce(0, { $0 + $1.placedTileCount }),
              flora.occupiedTileCount <= terrain.nonChasmTileCount,
              flora.placedIdentityCount == flora.species.count,
              flora.aggregateCoverage == Self.coverageBand(flora.occupiedTileCount,
                                                           of: terrain.nonChasmTileCount),
              flora.species.allSatisfy({ $0.placedTileCount > 0
                  && $0.coverage == Self.coverageBand($0.placedTileCount, of: terrain.nonChasmTileCount)
                  && $0.regionShares.count == terrain.regions.count }),
              flora.species.enumerated().allSatisfy({ speciesIndex, species in
                  let shares = terrain.regions.map { $0.floraShares[speciesIndex] }
                  return shares.reduce(0, { $0 + $1.exactCount }) == species.placedTileCount
                    && shares.map(\.band) == species.regionShares
              }),
              Set(flora.species.map(\.stableID)).count == flora.species.count,
              ["none", "smoke", "airborneAsh", "mist", "miasma"].contains(environment.suspendedMedium),
              ["trueDark", "dim", "ordinary", "bright", "blazing"].contains(environment.illuminationBand),
              ["sourceless", "constant", "cyclic"].contains(environment.illuminationSourceClass),
              ["none", "trace", "light", "heavy", "dense"].contains(environment.suspendedDensity),
              ["calm", "moving", "strong"].contains(environment.suspendedMotion),
              ["none", "rain", "snow", "mixedRainSnow"].contains(environment.precipitationMedium),
              ["none", "trace", "light", "heavy", "dense"].contains(environment.precipitationIntensity),
              ["calm", "moving", "strong"].contains(environment.precipitationMotion),
              (environment.suspendedMedium == "none") == (environment.suspendedDensity == "none"),
              (environment.precipitationMedium == "none") == (environment.precipitationIntensity == "none"),
              entryValid,
              flora.species == flora.species.sorted(by: {
                  $0.placedTileCount == $1.placedTileCount
                    ? $0.stableID < $1.stableID : $0.placedTileCount > $1.placedTileCount
              }),
              canonicalReceiptSHA256 == computedCanonicalSHA256() else { return false }
        return true
    }

    private static func coverageBand(_ count: Int, of total: Int) -> CoverageBand {
        guard count > 0, total > 0 else { return .none }
        let ratio = Double(count) / Double(total)
        if ratio < 0.03 { return .trace }
        if ratio < 0.10 { return .sparse }
        if ratio < 0.25 { return .present }
        if ratio < 0.50 { return .abundant }
        return .dominant
    }

    private static func regionCellCount(column: Int, row: Int, width: Int, height: Int) -> Int {
        let columns = (0..<width).count { min(regionColumns - 1, $0 * regionColumns / width) == column }
        let rows = (0..<height).count { min(regionRows - 1, $0 * regionRows / height) == row }
        return columns * rows
    }

    mutating func seal() { canonicalReceiptSHA256 = computedCanonicalSHA256() }

    private func computedCanonicalSHA256() -> String {
        var copy = self
        copy.canonicalReceiptSHA256 = ""
        return (try? WorldGrade2V1.canonicalSHA256(copy)) ?? ""
    }
}

/// Versioned, immutable input for the accepted arrival compositor. The nested payload deliberately
/// mirrors the Asset contract while v2 removes all hidden-cell terrain payloads. Native rendering
/// may consume only this object after presentation authority is enabled; it must not re-band the
/// richer rules receipt at display time.
struct WorldArrivalSceneReceipt: Codable, Equatable, Sendable {
    static let schemaVersion = 2

    struct SourcePage: Codable, Equatable, Sendable {
        struct Mark: Codable, Equatable, Sendable {
            var x: Int
            var y: Int
            /// Cell offsets relative to x/y, matching the compositor contract.
            var cells: [[Int]]
        }
        var id: String
        var title: String
        var marks: [Mark]
    }
    struct MaterialDescriptor: Codable, Equatable, Sendable {
        var identity: String
        var paletteFamilyID: String
        var transform: WorldGrade2V1.Transform
        var resolvedColor: [Int]?

        private enum CodingKeys: String, CodingKey {
            case identity, paletteFamilyID, transform, resolvedColor
        }
        func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode(identity, forKey: .identity)
            try c.encode(paletteFamilyID, forKey: .paletteFamilyID)
            try c.encode(transform, forKey: .transform)
            try c.encode(resolvedColor, forKey: .resolvedColor)
        }
    }
    struct Illumination: Codable, Equatable, Sendable {
        var band: String
        var sourceClass: String
    }
    struct SuspendedAtmosphere: Codable, Equatable, Sendable {
        var medium: String
        var density: String
        var motion: String
    }
    struct Precipitation: Codable, Equatable, Sendable {
        var medium: String
        var intensity: String
        var motion: String
    }
    struct Flora: Codable, Equatable, Sendable {
        var stableID: String
        var formID: Int
        var coverage: String
        var habit: String
        var color: [Int]
    }
    struct CausalVisualFact: Codable, Equatable, Sendable {
        var markID: String
        var visibleScope: String
        var contributionKind: String
        var resultBand: String
        var withoutAuthoredBand: String
    }
    struct EntryDisclosure: Codable, Equatable, Sendable {
        var siteProfile: String
        var status: String
    }
    struct CropCell: Codable, Equatable, Sendable {
        var x: Int
        var y: Int
        var ground: GroundType?
        var elevation: Int?
        var floraStableID: String?
        var visibility: String

        private enum CodingKeys: String, CodingKey {
            case x, y, ground, elevation, floraStableID, visibility
        }
        func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode(x, forKey: .x)
            try c.encode(y, forKey: .y)
            try c.encode(visibility, forKey: .visibility)
            guard visibility != "hidden" else { return }
            try c.encode(ground, forKey: .ground)
            try c.encode(elevation, forKey: .elevation)
            try c.encode(floraStableID, forKey: .floraStableID)
        }
    }
    struct FirstMapCrop: Codable, Equatable, Sendable {
        var width: Int
        var height: Int
        var cells: [CropCell]
    }
    struct Payload: Codable, Equatable, Sendable {
        var receiptID: String
        var worldSeed: String
        var sourcePage: SourcePage
        var dominantGround: GroundType
        var waterRelationship: String
        var materialDescriptor: MaterialDescriptor
        var illumination: Illumination
        var suspendedAtmosphere: SuspendedAtmosphere
        var precipitation: Precipitation
        var flora: [Flora]
        var causalVisualFacts: [CausalVisualFact]
        var entryDisclosure: EntryDisclosure?
        var description: String
        var firstMapCropReceipt: FirstMapCrop

        private enum CodingKeys: String, CodingKey {
            case receiptID, worldSeed, sourcePage, dominantGround, waterRelationship
            case materialDescriptor, illumination, suspendedAtmosphere, precipitation, flora
            case causalVisualFacts, entryDisclosure, description, firstMapCropReceipt
        }
        func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode(receiptID, forKey: .receiptID)
            try c.encode(worldSeed, forKey: .worldSeed)
            try c.encode(sourcePage, forKey: .sourcePage)
            try c.encode(dominantGround, forKey: .dominantGround)
            try c.encode(waterRelationship, forKey: .waterRelationship)
            try c.encode(materialDescriptor, forKey: .materialDescriptor)
            try c.encode(illumination, forKey: .illumination)
            try c.encode(suspendedAtmosphere, forKey: .suspendedAtmosphere)
            try c.encode(precipitation, forKey: .precipitation)
            try c.encode(flora, forKey: .flora)
            try c.encode(causalVisualFacts, forKey: .causalVisualFacts)
            try c.encode(entryDisclosure, forKey: .entryDisclosure)
            try c.encode(description, forKey: .description)
            try c.encode(firstMapCropReceipt, forKey: .firstMapCropReceipt)
        }
    }

    var version: Int
    var payload: Payload
    var canonicalSHA256: String

    init(payload: Payload) {
        self.version = Self.schemaVersion
        self.payload = payload
        self.canonicalSHA256 = Self.canonicalHash(version: Self.schemaVersion, payload: payload)
    }

    func validatesCanonicalHash() -> Bool {
        version == Self.schemaVersion
            && canonicalSHA256 == Self.canonicalHash(version: version, payload: payload)
    }

    func validatesSchema() -> Bool {
        // Persistence and the bundled corpus decode into this closed typed value before eligibility.
        // Swift's decoder may discard an unknown JSON member, but no discarded member can reach
        // copy, command generation, hashing, or replay; eligibility is recomputed exclusively from
        // this validated value and its canonical typed hash.
        let p = payload
        let words = p.description.split(whereSeparator: \Character.isWhitespace).count
        let pageValid = !p.sourcePage.id.isEmpty
            && p.sourcePage.marks.allSatisfy { mark in
                (0...5).contains(mark.x) && (0...5).contains(mark.y) && !mark.cells.isEmpty
                    && mark.cells.allSatisfy { $0.count == 2
                        && (0...5).contains(mark.x + $0[0]) && (0...5).contains(mark.y + $0[1]) }
            }
        let material = p.materialDescriptor
        let materialValid = !material.identity.isEmpty && !material.paletteFamilyID.isEmpty
            && material.transform.hue.isFinite && material.transform.saturation.isFinite
            && material.transform.value.isFinite
            && (material.resolvedColor == nil || Self.validRGB(material.resolvedColor!))
        let floraValid = p.flora.count <= 4 && p.flora.allSatisfy {
            !$0.stableID.isEmpty && ["sparse","present","abundant"].contains($0.coverage)
                && ["solitary","clustered","spreading","mixed"].contains($0.habit)
                && Self.validRGB($0.color)
        }
        let factsValid = p.causalVisualFacts.allSatisfy {
            return !$0.markID.isEmpty && ["ground","water","flora","resource","light","atmosphere"].contains($0.visibleScope)
                && ["none","increased","reduced","reshaped"].contains($0.contributionKind)
                && !$0.resultBand.isEmpty && !$0.withoutAuthoredBand.isEmpty
                && ($0.visibleScope != "resource" || (["absent","present"].contains($0.resultBand)
                    && ["absent","present"].contains($0.withoutAuthoredBand)))
        }
        let crop = p.firstMapCropReceipt
        let cropValid = crop.width == 9 && crop.height == 9 && crop.cells.count == 81
            && Set(crop.cells.map { "\($0.x),\($0.y)" }).count == 81
            && crop.cells.allSatisfy { cell in
                guard (0..<9).contains(cell.x), (0..<9).contains(cell.y),
                      ["full","fringe","remembered","hidden"].contains(cell.visibility) else { return false }
                if cell.visibility == "hidden" {
                    return cell.ground == nil && cell.elevation == nil && cell.floraStableID == nil
                }
                return cell.ground != nil && cell.elevation != nil
                    && (cell.floraStableID == nil || cell.visibility == "full")
            }
        return !p.receiptID.isEmpty && UInt64(p.worldSeed) != nil && pageValid && materialValid
            && ["stone","soil","sand","ice","ash","rubble","mud","growth","groundcover"].contains(p.dominantGround.rawValue)
            && ["none","pools","channels","shelves","islands"].contains(p.waterRelationship)
            && ["trueDark","dim","ordinary","bright","blazing"].contains(p.illumination.band)
            && ["sourceless","cyclic","constant"].contains(p.illumination.sourceClass)
            && ["none","smoke","airborneAsh","mist","miasma"].contains(p.suspendedAtmosphere.medium)
            && ["none","trace","light","heavy","dense"].contains(p.suspendedAtmosphere.density)
            && ["calm","moving","strong"].contains(p.suspendedAtmosphere.motion)
            && (p.suspendedAtmosphere.medium == "none") == (p.suspendedAtmosphere.density == "none")
            && ["none","rain","snow","mixedRainSnow"].contains(p.precipitation.medium)
            && ["none","trace","light","heavy"].contains(p.precipitation.intensity)
            && ["calm","moving","strong"].contains(p.precipitation.motion)
            && (p.precipitation.medium == "none") == (p.precipitation.intensity == "none")
            && floraValid && factsValid
            && (p.entryDisclosure == nil || (!p.entryDisclosure!.siteProfile.isEmpty
                && p.entryDisclosure!.status == "entryVisible"))
            && words >= 18 && words <= 55
            && p.description.filter { ".!?".contains($0) }.count == 2 && cropValid
    }

    private static func validRGB(_ value: [Int]) -> Bool {
        value.count == 3 && value.allSatisfy { (0...255).contains($0) }
    }

    private struct Canonical: Encodable { var version: Int; var payload: Payload }
    private static func canonicalHash(version: Int, payload: Payload) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        guard let data = try? encoder.encode(Canonical(version: version, payload: payload)) else {
            preconditionFailure("World arrival scene receipt must remain canonically encodable")
        }
        return SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}

/// Immutable, disclosure-safe evidence for one newly bound world's arrival presentation.
/// Rendering and History consume this value; neither is allowed to reconstruct it from the run.
struct WorldArrivalReceipt: Codable, Equatable, Sendable {
    static let schemaVersion = 1
    static let descriptionGrammarVersion = "world-arrival-description-v1"
    static let sceneCompositorVersion = "world-arrival-compositor-v1"

    struct SourcePage: Codable, Equatable, Sendable {
        struct Mark: Codable, Equatable, Sendable {
            var id: InstanceID
            /// Opaque visual lookup only; never legal for copy, sorting, or accessibility.
            var rendererAssetKey: String
            var hand: Hand
            var origin: PageCell
            var shapeID: String
            var cells: [PageCell]
            var inkRecipe: InkRecipe?
            var isReadable: Bool
            var visibleLabel: String
        }
        struct Link: Codable, Equatable, Sendable {
            var firstMarkID: InstanceID
            var secondMarkID: InstanceID
        }
        var title: String
        var width: Int
        var height: Int
        var marks: [Mark]
        var links: [Link]
    }

    struct Illumination: Codable, Equatable, Sendable {
        var peak: Double
        var floor: Double
        var band: String
        var sourceClass: String
    }
    struct Atmosphere: Codable, Equatable, Sendable {
        var medium: String
        var density: Double
        var motion: String
    }
    struct Precipitation: Codable, Equatable, Sendable {
        var medium: String
        var intensity: Double
        var motion: String
    }
    struct FloraSummary: Codable, Equatable, Sendable {
        var stableID: String
        var formID: Int
        var coverage: String
        var habit: String
        var resolvedColor: [Int]
    }
    struct CausalVisualFact: Codable, Equatable, Sendable {
        enum Scope: String, Codable, CaseIterable, Sendable {
            case ground, water, flora, resource, light, atmosphere
        }
        enum ContributionKind: String, Codable, Sendable { case none, increased, reduced, reshaped }
        var candidateMarkID: InstanceID
        var semanticKey: String?
        var markDisplayName: String?
        var sourcePageOrder: Int
        var scope: Scope
        var contributionKind: ContributionKind
        var resultBand: String
        var withoutAuthoredBand: String
    }
    struct TerrainSummary: Codable, Equatable, Sendable {
        var countByGroundID: [GroundType: Int]
        var dominantDryGroundID: GroundType
        var wetTileCount: Int
        var deepWaterTileCount: Int
        var nonChasmTileCount: Int
    }
    struct EnvironmentSummary: Codable, Equatable, Sendable {
        var illuminationBand: String
        var suspendedMedium: String
        var suspendedDensity: String
        var precipitation: String
        var precipitationIntensity: String
        var floraCoverageBand: String
        var floraHabit: String
    }
    struct MapCell: Codable, Equatable, Sendable {
        var point: GridPoint
        /// Hidden cells carry no terrain request. Nil is part of the persisted disclosure boundary,
        /// not a visual mask applied after decoding real terrain.
        var ground: GroundType?
        var elevation: Int?
        var floraStableID: String?
        var visibility: String
    }
    struct FirstMapCrop: Codable, Equatable, Sendable {
        var width: Int
        var height: Int
        var cells: [MapCell]
    }

    var version: Int
    var id: WorldArrivalReceiptID
    var runIndex: Int
    var generationSeed: UInt64
    var sourcePagePhysicalReceipt: SourcePage
    var visualReceiptID: String
    var visualSchemaVersion: String
    /// Optional only for receipts decoded from the brief pre-E2 schema.
    var terrainSummary: TerrainSummary?
    /// Aggregate map-owned grammar state; never inferred from the first flora species.
    var environmentSummary: EnvironmentSummary?
    var dominantGround: GroundType
    var waterRelationship: String
    var materialDescriptor: WorldGrade2V1.Material
    var illumination: Illumination
    var suspendedAtmosphere: Atmosphere?
    var precipitation: Precipitation?
    var flora: [FloraSummary]
    var causalVisualFacts: [CausalVisualFact]
    var entryDisclosure: String?
    var firstMapCropReceipt: FirstMapCrop
    var proseVersion: String
    var finalDescription: String
    var compositorVersion: String
    /// Nil only for the short-lived pre-scene schema; never synthesized during decode.
    var sceneReceipt: WorldArrivalSceneReceipt?
    /// Nil for legacy/pre-B1.6a worlds. New binds freeze the exact validated rect-v1 replay.
    var renderedSceneReceipt: WorldArrivalRenderedSceneReceipt? = nil
    /// Nil for legacy v1/v2 arrivals. New binds persist the comprehensive disclosure-safe input.
    var worldSplashReceiptV3: WorldSplashReceiptV3? = nil

    fileprivate enum CodingKeys: String, CodingKey {
        case version, id, runIndex, generationSeed, sourcePagePhysicalReceipt, visualReceiptID
        case visualSchemaVersion, terrainSummary, environmentSummary, dominantGround
        case waterRelationship, materialDescriptor, illumination, suspendedAtmosphere
        case precipitation, flora, causalVisualFacts, entryDisclosure, firstMapCropReceipt
        case proseVersion, finalDescription, compositorVersion, sceneReceipt, renderedSceneReceipt
        case worldSplashReceiptV3
    }

    var isNativePresentationEligible: Bool {
        guard let sceneReceipt, sceneReceipt.validatesCanonicalHash(), sceneReceipt.validatesSchema(),
              let renderedSceneReceipt, renderedSceneReceipt.validates() else { return false }
        return renderedSceneReceipt.inputSceneReceiptSHA256 == sceneReceipt.canonicalSHA256
            && finalDescription == sceneReceipt.payload.description
    }
}

extension WorldArrivalReceipt {
    /// v3 is an optional presentation receipt. A malformed future/partial v3 value must not
    /// quarantine a playable v1/v2 run; it closes to the legacy text-first Splash instead.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        version = try c.decode(Int.self, forKey: .version)
        id = try c.decode(WorldArrivalReceiptID.self, forKey: .id)
        runIndex = try c.decode(Int.self, forKey: .runIndex)
        generationSeed = try c.decode(UInt64.self, forKey: .generationSeed)
        sourcePagePhysicalReceipt = try c.decode(SourcePage.self, forKey: .sourcePagePhysicalReceipt)
        visualReceiptID = try c.decode(String.self, forKey: .visualReceiptID)
        visualSchemaVersion = try c.decode(String.self, forKey: .visualSchemaVersion)
        terrainSummary = try c.decodeIfPresent(TerrainSummary.self, forKey: .terrainSummary)
        environmentSummary = try c.decodeIfPresent(EnvironmentSummary.self, forKey: .environmentSummary)
        dominantGround = try c.decode(GroundType.self, forKey: .dominantGround)
        waterRelationship = try c.decode(String.self, forKey: .waterRelationship)
        materialDescriptor = try c.decode(WorldGrade2V1.Material.self, forKey: .materialDescriptor)
        illumination = try c.decode(Illumination.self, forKey: .illumination)
        suspendedAtmosphere = try c.decodeIfPresent(Atmosphere.self, forKey: .suspendedAtmosphere)
        precipitation = try c.decodeIfPresent(Precipitation.self, forKey: .precipitation)
        flora = try c.decode([FloraSummary].self, forKey: .flora)
        causalVisualFacts = try c.decode([CausalVisualFact].self, forKey: .causalVisualFacts)
        entryDisclosure = try c.decodeIfPresent(String.self, forKey: .entryDisclosure)
        firstMapCropReceipt = try c.decode(FirstMapCrop.self, forKey: .firstMapCropReceipt)
        proseVersion = try c.decode(String.self, forKey: .proseVersion)
        finalDescription = try c.decode(String.self, forKey: .finalDescription)
        compositorVersion = try c.decode(String.self, forKey: .compositorVersion)
        sceneReceipt = try c.decodeIfPresent(WorldArrivalSceneReceipt.self, forKey: .sceneReceipt)
        renderedSceneReceipt = try c.decodeIfPresent(
            WorldArrivalRenderedSceneReceipt.self, forKey: .renderedSceneReceipt)
        if let decoded = try? c.decodeIfPresent(WorldSplashReceiptV3.self,
                                                forKey: .worldSplashReceiptV3),
           decoded.validates(),
           decoded.receiptID == id,
           decoded.worldSeed == generationSeed,
           decoded.worldVisualReceiptSHA256 == visualReceiptID,
           decoded.sourcePagePhysicalReceipt == sourcePagePhysicalReceipt,
           decoded.descriptionGrammarVersion == proseVersion,
           decoded.finalDescription == finalDescription,
           decoded.causalVisualFacts == causalVisualFacts,
           decoded.firstMapCropReceipt == firstMapCropReceipt {
            worldSplashReceiptV3 = decoded
        } else {
            worldSplashReceiptV3 = nil
        }
    }
}

#if !WORLD_GENERATOR_BRIDGE
enum WorldArrivalReceiptFactory {
    enum Error: Swift.Error, Equatable { case noDryGround }

    static func make(runIndex: Int, generationSeed: UInt64,
                     source: WritingDeskReviewModel,
                     sourcePage: Page, book: BoundBook, map: WorldMap, flora: [Flora],
                     sites: [PlacedSite] = [],
                     generationDiagnostics: WorldGenerationDiagnostics,
                     visualReceipt: WorldVisualReceipt,
                     atmospherePresentationReceipt: WorldAtmospherePresentationReceiptV1,
                     visibilityProfile: WorldRules.VisibilityProfile,
                     library: LibraryState, tuning: DebugTuningProfile,
                     isFreshFirstExpedition: Bool,
                     wildPageSelection: WildWorldPageSelectionRules.Selection?,
                     wildPageOriginRunIndex: Int?) throws -> WorldArrivalReceipt {
        let dominant = try dominantDryGround(in: map)
        let counts = Dictionary(grouping: map.tiles.map(\.ground), by: { $0 }).mapValues(\.count)
        let wetTileCount = (counts[.water] ?? 0) + (counts[.deepWater] ?? 0)
        let deepWaterTileCount = counts[.deepWater] ?? 0
        let nonChasmTileCount = map.tiles.count - (counts[.chasm] ?? 0)
        let terrainSummary = WorldArrivalReceipt.TerrainSummary(
            countByGroundID: counts, dominantDryGroundID: dominant,
            wetTileCount: wetTileCount, deepWaterTileCount: deepWaterTileCount,
            nonChasmTileCount: nonChasmTileCount)
        let waterRelationship = try waterRelationship(for: terrainSummary)

        let readings = BookRules.readings(for: book, seed: generationSeed)
        let light = readings["illumination"]
        let cycle = readings["cycle"]
        let lightBand = illuminationBand(light)
        let sourceClass = illuminationSourceClass(light: light, cycle: cycle)
        let atmosphere = visualReceipt.descriptor.atmosphere
        let resolvedMotion = Int(readings["atmosphere"].aspect("motion")
            .rounded(.toNearestOrAwayFromZero))
        let motionBand = resolvedMotion <= 40 ? "calm" : resolvedMotion <= 65 ? "moving" : "strong"
        let suspended = atmosphere.medium == "none" ? nil : WorldArrivalReceipt.Atmosphere(
            medium: atmosphere.medium, density: atmosphere.density, motion: "calm")

        let descriptorByID = Dictionary(uniqueKeysWithValues:
            visualReceipt.descriptor.flora.cast.map { ($0.speciesID, $0) })
        let floraSummaries = flora.prefix(4).compactMap { plant -> WorldArrivalReceipt.FloraSummary? in
            let stableID = "flora-\(plant.id.rawValue)"
            guard let descriptor = descriptorByID[stableID] else { return nil }
            let placements = map.tiles.count { $0.flora == plant.id }
            let coverage = placements * 100 < nonChasmTileCount * 8 ? "sparse"
                : placements * 100 < nonChasmTileCount * 22 ? "present" : "abundant"
            return .init(stableID: stableID, formID: descriptor.formID, coverage: coverage,
                         habit: plant.traits.habit.rawValue,
                         resolvedColor: descriptor.resolvedColor.srgb)
        }
        let placedFloraTiles = map.tiles.count { $0.flora != nil }
        let aggregateCoverage = placedFloraTiles == 0 ? "none"
            : placedFloraTiles * 100 < nonChasmTileCount * 8 ? "sparse"
            : placedFloraTiles * 100 < nonChasmTileCount * 22 ? "present" : "abundant"
        let habits = Set(flora.compactMap { plant in
            map.tiles.contains(where: { $0.flora == plant.id }) ? plant.traits.habit.rawValue : nil
        })
        let aggregateHabit = habits.isEmpty ? "none" : habits.count == 1 ? habits.first! : "mixed"
        let environmentSummary = WorldArrivalReceipt.EnvironmentSummary(
            illuminationBand: lightBand,
            suspendedMedium: atmosphere.medium,
            suspendedDensity: densityBand(atmosphere.density, medium: atmosphere.medium),
            precipitation: "none", precipitationIntensity: "none",
            floraCoverageBand: aggregateCoverage, floraHabit: aggregateHabit)

#if DEBUG
        let counterfactualStarted = Date()
#endif
        let actualAuthored = BookRules.sigils(for: book)
        let actualReadings = BookRules.readings(for: book, seed: generationSeed)
        let actualSummary = Worldgen.ArrivalCausalSummary(map: map, flora: flora)
        var summaryCache: [String: Worldgen.ArrivalCausalSummary] = [:]
        var counterfactualPassCount = 0
        var causalFacts: [WorldArrivalReceipt.CausalVisualFact] = []
        var causalResourceOwners: [ResourceID: Set<InstanceID>] = [:]
        for candidate in WorldArrivalCausalCandidateRules.candidates(page: sourcePage, review: source) {
            guard let removedPage = WorldArrivalCausalCandidateRules.removing(candidate, from: sourcePage),
                  let fingerprint = WritingDeskReviewModelFactory.canonicalHash(removedPage) else {
                throw Error.noDryGround
            }
            var removedBook = BookRules.resolveBook(page: removedPage)
            removedBook.worldPageUseReceipt = book.worldPageUseReceipt
            let remainingAuthored = BookRules.sigils(for: removedBook)
            let intervention = PressureRules.causalIntervention(
                actualAuthored: actualAuthored, remainingAuthored: remainingAuthored,
                seed: generationSeed)
            let summary: Worldgen.ArrivalCausalSummary
            if let cached = summaryCache[fingerprint] {
                summary = cached
            } else {
                summary = Worldgen.arrivalCausalSummary(
                    book: removedBook, seed: generationSeed,
                    terrain: .init(readings: intervention.readings,
                                   resolvedSigils: intervention.counterfactualSigils),
                    library: library, tuning: tuning,
                    isFreshFirstExpedition: isFreshFirstExpedition,
                    wildPageSelection: wildPageSelection,
                    wildPageOriginRunIndex: wildPageOriginRunIndex)
                summaryCache[fingerprint] = summary
                counterfactualPassCount += 1
            }
            let counterfactualAtmosphere = try WorldGrade2BindAdapter.atmosphereDescriptor(
                sigils: intervention.counterfactualSigils)
            for resourceID in candidate.registeredResourceFamilies
            where candidate.registeredScopes.contains(.resource)
                && WorldArrivalCausalCandidateRules.resourceQuantity(resourceID, in: actualSummary.map)
                    > WorldArrivalCausalCandidateRules.resourceQuantity(resourceID, in: summary.map) {
                causalResourceOwners[resourceID, default: []].insert(candidate.markID)
            }
            causalFacts.append(contentsOf: try WorldArrivalCausalCandidateRules.summaryFacts(
                candidate: candidate, actual: actualSummary, withoutCandidate: summary,
                actualReadings: actualReadings, withoutReadings: intervention.readings,
                actualAtmosphere: visualReceipt.descriptor.atmosphere,
                withoutAtmosphere: counterfactualAtmosphere))
        }
#if DEBUG
        let elapsed = Date().timeIntervalSince(counterfactualStarted) * 1_000
        let elapsedText = String(format: "%.2f", elapsed)
        print("World arrival causal diagnostics: \(counterfactualPassCount) summary passes in \(elapsedText) ms")
#endif
        let physical = WorldArrivalReceipt.SourcePage(
            title: source.title, width: source.pageThumbnail.width, height: source.pageThumbnail.height,
            marks: source.pageThumbnail.marks.map {
                .init(id: $0.id, rendererAssetKey: $0.rendererAssetKey, hand: $0.hand,
                      origin: $0.origin, shapeID: $0.shapeID, cells: $0.cells,
                      inkRecipe: $0.inkRecipe, isReadable: $0.isReadable,
                      visibleLabel: $0.displayName)
            },
            links: source.pageThumbnail.links.map {
                .init(firstMarkID: $0.firstMarkID, secondMarkID: $0.secondMarkID)
            })
        let crop = firstCrop(
            map: map, flora: flora, profile: visibilityProfile,
            center: generationDiagnostics.playableEntry?.playerStart ?? map.entry)
        let grammarInput = WorldArrivalDescriptionRules.Input(
            dominantDryGround: dominant,
            terrain: .init(wetTileCount: wetTileCount, deepWaterTileCount: deepWaterTileCount,
                           nonChasmTileCount: nonChasmTileCount),
            environment: .init(
                illuminationBand: environmentSummary.illuminationBand,
                suspendedMedium: environmentSummary.suspendedMedium,
                suspendedDensity: environmentSummary.suspendedDensity,
                precipitation: environmentSummary.precipitation,
                precipitationIntensity: environmentSummary.precipitationIntensity,
                floraCoverageBand: environmentSummary.floraCoverageBand,
                floraHabit: environmentSummary.floraHabit),
            causalFacts: causalFacts)
        let description = try WorldArrivalDescriptionRules.describe(grammarInput)
        let canonical = "\(Self.schemaIdentity)|\(runIndex)|\(generationSeed)|\(sourceIdentity(source.sourceKey))|\(visualReceipt.canonicalReceiptSHA256)"
        let id = SHA256.hash(data: Data(canonical.utf8)).map { String(format: "%02x", $0) }.joined()
        let receiptID = WorldArrivalReceiptID(rawValue: id)
        let scenePayload = scenePayload(
            receiptID: receiptID, generationSeed: generationSeed, source: source,
            dominant: dominant, waterRelationship: waterRelationship,
            visualReceipt: visualReceipt, lightBand: lightBand, sourceClass: sourceClass,
            atmosphere: atmosphere, flora: floraSummaries, crop: crop,
            causalFacts: causalFacts, description: description)
        let sceneReceipt = WorldArrivalSceneReceipt(payload: scenePayload)
        var result = WorldArrivalReceipt(version: WorldArrivalReceipt.schemaVersion,
                     id: receiptID, runIndex: runIndex, generationSeed: generationSeed,
                     sourcePagePhysicalReceipt: physical,
                     visualReceiptID: visualReceipt.canonicalReceiptSHA256,
                     visualSchemaVersion: visualReceipt.adapterVersion,
                     terrainSummary: terrainSummary,
                     environmentSummary: environmentSummary,
                     dominantGround: dominant, waterRelationship: waterRelationship,
                     materialDescriptor: visualReceipt.descriptor.material,
                     illumination: .init(peak: light.peak, floor: light.floor,
                                         band: lightBand, sourceClass: sourceClass),
                     suspendedAtmosphere: suspended, precipitation: nil,
                     flora: floraSummaries, causalVisualFacts: causalFacts,
                     entryDisclosure: nil,
                     firstMapCropReceipt: crop,
                     proseVersion: WorldArrivalReceipt.descriptionGrammarVersion,
                     finalDescription: description,
                     compositorVersion: WorldArrivalReceipt.sceneCompositorVersion,
                     sceneReceipt: sceneReceipt, renderedSceneReceipt: nil)
        result.worldSplashReceiptV3 = makeSplashV3(
            receiptID: receiptID, generationSeed: generationSeed, sourcePage: physical,
            visualReceipt: visualReceipt, map: map, flora: flora, sites: sites,
            hydrologyTopology: generationDiagnostics.hydrologyTopology,
            environment: environmentSummary, illuminationSourceClass: sourceClass,
            motionBand: motionBand,
            atmospherePresentationReceipt: atmospherePresentationReceipt,
            causalFacts: causalFacts,
            causalResourceOwners: causalResourceOwners.mapValues {
                $0.sorted { $0.rawValue < $1.rawValue }
            }, crop: crop,
            description: description)
        guard result.worldSplashReceiptV3?.validates() == true else { throw Error.noDryGround }
        return result
    }

    static func makeSplashV3(
        receiptID: WorldArrivalReceiptID, generationSeed: UInt64,
        sourcePage: WorldArrivalReceipt.SourcePage, visualReceipt: WorldVisualReceipt,
        map: WorldMap, flora: [Flora], sites: [PlacedSite] = [],
        hydrologyTopology: WorldHydrologyTopologyObservation?,
        environment: WorldArrivalReceipt.EnvironmentSummary,
        illuminationSourceClass: String, motionBand: String,
        atmospherePresentationReceipt: WorldAtmospherePresentationReceiptV1? = nil,
        causalFacts: [WorldArrivalReceipt.CausalVisualFact],
        causalResourceOwners: [ResourceID: [InstanceID]] = [:],
        crop: WorldArrivalReceipt.FirstMapCrop,
        description: String
    ) -> WorldSplashReceiptV3? {
        guard let materialPresentation = WorldSplashReceiptV3.MaterialPresentationDescriptor.make(
            from: visualReceipt.descriptor) else { return nil }
        let tileCount = max(1, map.tiles.count)
        let nonChasm = map.tiles.count { $0.ground != .chasm }
        let counts = GroundType.allCases.map { ground in
            let count = map.tiles.count { $0.ground == ground }
            return WorldSplashReceiptV3.GroundCensus(
                ground: ground, exactCount: count, coverage: splashBand(count, of: tileCount))
        }
        let dryOrder: [GroundType] = [.stone, .soil, .sand, .ice, .ash, .rubble, .mud, .growth, .groundcover]
        let orderedDry = dryOrder.sorted { leftGround, rightGround in
            let left = counts.first { $0.ground == leftGround }?.exactCount ?? 0
            let right = counts.first { $0.ground == rightGround }?.exactCount ?? 0
            return left == right
                ? dryOrder.firstIndex(of: leftGround)! < dryOrder.firstIndex(of: rightGround)!
                : left > right
        }
        // Avoid Dictionary order in the persisted receipt. Regions and every share are closed and sorted.
        let regionPoints: [[GridPoint]] = (0..<(WorldSplashReceiptV3.regionRows * WorldSplashReceiptV3.regionColumns)).map { region in
            let column = region % WorldSplashReceiptV3.regionColumns
            let row = region / WorldSplashReceiptV3.regionColumns
            return map.allPoints.filter {
                min(WorldSplashReceiptV3.regionColumns - 1, $0.x * WorldSplashReceiptV3.regionColumns / map.width) == column
                    && min(WorldSplashReceiptV3.regionRows - 1, $0.y * WorldSplashReceiptV3.regionRows / map.height) == row
            }
        }
        let descriptorByID = Dictionary(uniqueKeysWithValues: visualReceipt.descriptor.flora.cast.map { ($0.speciesID, $0) })
        let floraByID = Dictionary(uniqueKeysWithValues: flora.map { ($0.id, $0) })
        let placedIDs = Set(map.tiles.compactMap(\.flora))
        let species = placedIDs.compactMap { id -> WorldSplashReceiptV3.FloraSpecies? in
            let stableID = "flora-\(id.rawValue)"
            guard let plant = floraByID[id], let descriptor = descriptorByID[stableID] else { return nil }
            let placed = map.tiles.count { $0.flora == id }
            // This is the closed TerrainRules.paintGrowth host predicate, not a census of where
            // this particular seeded patch happened to land.
            let eligible = GroundType.allCases.filter {
                $0.isPassable && $0 != .water && !$0.isOvergrown
            }
            return .init(stableID: stableID, renderIdentity: descriptor,
                         placedTileCount: placed, coverage: splashBand(placed, of: nonChasm),
                         habit: plant.traits.habit.rawValue, eligibleGrounds: eligible,
                         regionShares: regionPoints.map { points in
                             splashBand(points.count { map[$0].flora == id }, of: max(1, points.count))
                         })
        }.sorted { $0.placedTileCount == $1.placedTileCount
            ? $0.stableID < $1.stableID : $0.placedTileCount > $1.placedTileCount }
        let regions = regionPoints.enumerated().map { index, points in
            let total = max(1, points.count)
            func shares(_ pairs: [(String, (Tile) -> Bool)]) -> [WorldSplashReceiptV3.Share] {
                pairs.map { id, owns in
                    let exactCount = points.count { owns(map[$0]) }
                    return .init(id: id, exactCount: exactCount,
                                 band: splashBand(exactCount, of: total))
                }
            }
            return WorldSplashReceiptV3.Region(
                column: index % WorldSplashReceiptV3.regionColumns,
                row: index / WorldSplashReceiptV3.regionColumns,
                groundShares: shares(GroundType.allCases.map { ground in (ground.rawValue, { $0.ground == ground }) }),
                waterShares: shares([("shallow", { $0.ground == .water }), ("deep", { $0.ground == .deepWater }), ("frozen", { $0.ground == .ice })]),
                elevationShares: shares((0...3).map { elevation in (String(elevation), { $0.elevation == elevation }) }),
                depositShares: shares([("snow", { $0.surfaceDeposits.snow }), ("settledAsh", { $0.surfaceDeposits.settledAsh })]),
                floraShares: species.map { item in
                    let exactCount = points.count { point in
                        map[point].flora.map { "flora-\($0.rawValue)" } == item.stableID
                    }
                    return .init(id: item.stableID, exactCount: exactCount,
                                 band: splashBand(exactCount, of: total))
                })
        }
        guard let hydrologyTopology,
              let waterProfile = splashWaterProfile(map: map, observation: hydrologyTopology)
        else { return nil }
        let elevationCounts = (0...3).map { level in map.tiles.count { $0.elevation == level } }
        let contacts = (1...3).map { depth in
            map.allPoints.count { point in
                let south = GridPoint(x: point.x, y: point.y + 1)
                return map.contains(south) && map[point].elevation - map[south].elevation == depth
            }
        }
        let maxElevation = map.tiles.map(\.elevation).max() ?? 0
        let elevatedComponents = splashComponents(
            points: Set(map.allPoints.filter { map[$0].elevation > 0 }), map: map)
            .map(\.count).sorted()
        let snow = map.tiles.count { $0.surfaceDeposits.snow }
        let ash = map.tiles.count { $0.surfaceDeposits.settledAsh }
        let placedSites = sites.filter { site in
            guard map.contains(site.position), case .site(let instanceID) = map[site.position].content
            else { return false }
            return instanceID == site.id
        }
        var resourceSources: [ResourceID: Int] = [:]
        var resourceQuantities: [ResourceID: Int] = [:]
        for tile in map.tiles {
            var amounts: [ResourceID: Int] = [:]
            switch tile.content {
            case .node(let node) where node.remainingHarvests > 0:
                if node.yieldPerHarvest > 0 {
                    amounts[node.resource] = node.remainingHarvests * node.yieldPerHarvest
                }
                if let secondary = node.secondaryResource,
                   node.secondaryYieldPerHarvest > 0, amounts[secondary] == nil {
                    amounts[secondary] = node.remainingHarvests * node.secondaryYieldPerHarvest
                }
            case .wildDrop(let resource, let amount) where amount > 0:
                amounts[resource] = amount
            default: break
            }
            for (family, amount) in amounts {
                resourceSources[family, default: 0] += 1
                resourceQuantities[family, default: 0] += amount
            }
        }
        let resourceRows: [WorldSplashReceiptV3.ExplorationOpportunityRow] =
            resourceSources.compactMap { element in
            let (resourceID, sourceCount) = element
            let marks = causalResourceOwners[resourceID] ?? []
            guard let definition = ContentCatalog.shared.resource(resourceID),
                  definition.tradeBand == .rare || definition.tradeBand == .precious
                    || !marks.isEmpty
            else { return nil }
            return WorldSplashReceiptV3.ExplorationOpportunityRow(
                stableID: resourceID.rawValue, sourceCount: sourceCount,
                obtainableQuantity: resourceQuantities[resourceID] ?? 0, causalMarkIDs: marks)
        }.sorted { $0.stableID < $1.stableID }
        var receipt = WorldSplashReceiptV3(
            version: WorldSplashReceiptV3.schemaVersion, receiptID: receiptID,
            worldSeed: generationSeed, worldVisualReceiptSHA256: visualReceipt.canonicalReceiptSHA256,
            sourcePagePhysicalReceipt: sourcePage,
            descriptionGrammarVersion: WorldArrivalReceipt.descriptionGrammarVersion,
            finalDescription: description,
            terrain: .init(width: map.width, height: map.height, nonChasmTileCount: nonChasm,
                           grounds: counts, dominantDryGround: orderedDry.first ?? .soil,
                           secondaryVisibleGrounds: Array(orderedDry.dropFirst().filter { ground in
                               counts.first(where: { $0.ground == ground })?.exactCount ?? 0 > 0
                           }), materialPresentation: materialPresentation, regions: regions),
            water: waterProfile,
            relief: .init(elevationCounts: elevationCounts, maximumElevation: maxElevation,
                          southContactCounts: contacts,
                          elevatedComponentSizes: elevatedComponents,
                          shapeFlags: maxElevation == 0 ? [.flat] : []),
            deposits: .init(snowCount: snow, snowCoverage: splashBand(snow, of: tileCount),
                            settledAshCount: ash, settledAshCoverage: splashBand(ash, of: tileCount)),
            flora: .init(placedIdentityCount: placedIDs.count,
                         occupiedTileCount: species.reduce(0) { $0 + $1.placedTileCount },
                         aggregateCoverage: splashBand(species.reduce(0) { $0 + $1.placedTileCount }, of: nonChasm),
                         species: species),
            explorationOpportunities: .init(
                hasGeneratedSiteOpportunity: !placedSites.isEmpty, resources: resourceRows),
            environment: .init(illuminationBand: environment.illuminationBand,
                               illuminationSourceClass: illuminationSourceClass,
                               suspendedMedium: atmospherePresentationReceipt?.suspendedMedium.rawValue
                                ?? environment.suspendedMedium,
                               suspendedDensity: atmospherePresentationReceipt.map {
                                   WorldAtmospherePresentationReceiptV1.densityBand(
                                    $0.suspendedDensity, present: $0.suspendedMedium != .none)
                               } ?? environment.suspendedDensity,
                               suspendedMotion: atmospherePresentationReceipt?.motionBand.rawValue
                                ?? motionBand,
                               precipitationMedium: atmospherePresentationReceipt?.precipitation.rawValue
                                ?? environment.precipitation,
                               precipitationIntensity: atmospherePresentationReceipt.map {
                                   WorldAtmospherePresentationReceiptV1.densityBand(
                                    $0.precipitationDensity, present: $0.precipitation != .none)
                               } ?? environment.precipitationIntensity,
                               precipitationMotion: atmospherePresentationReceipt?.motionBand.rawValue
                                ?? motionBand),
            causalVisualFacts: causalFacts,
            entryMark: sourcePage.marks.first.map {
                .init(markID: $0.id, rendererAssetKey: $0.rendererAssetKey, hand: $0.hand,
                      origin: $0.origin,
                      shapeID: $0.shapeID, cells: $0.cells, inkRecipe: $0.inkRecipe)
            },
            firstMapCropReceipt: crop,
            canonicalReceiptSHA256: "")
        receipt.seal()
        return receipt
    }

    private static func splashBand(_ count: Int, of total: Int) -> WorldSplashReceiptV3.CoverageBand {
        guard count > 0, total > 0 else { return .none }
        let percent = count * 100 / total
        if percent < 3 { return .trace }
        if percent < 10 { return .sparse }
        if percent < 25 { return .present }
        if percent < 50 { return .abundant }
        return .dominant
    }

    static func splashWaterProfile(
        map: WorldMap, observation: WorldHydrologyTopologyObservation
    ) -> WorldSplashReceiptV3.WaterProfile? {
        let shallow = map.tiles.count { $0.ground == .water }
        let deep = map.tiles.count { $0.ground == .deepWater }
        let frozen = map.tiles.count { $0.ground == .ice }
        guard observation.standingTiles + observation.flowingTiles == shallow + deep,
              observation.frozenTiles == frozen,
              observation.standingDeepTiles + observation.flowingDeepTiles == deep,
              observation.standingBodySizes.reduce(0, +) == observation.standingTiles,
              observation.flowingChannelSizes.reduce(0, +) == observation.flowingTiles,
              observation.frozenBodySizes.reduce(0, +) == observation.frozenTiles,
              [observation.standingRegionCounts, observation.flowingRegionCounts,
               observation.frozenRegionCounts].allSatisfy({
                   $0.count == WorldSplashReceiptV3.regionColumns * WorldSplashReceiptV3.regionRows
               }),
              observation.standingRegionCounts.reduce(0, +) == observation.standingTiles,
              observation.flowingRegionCounts.reduce(0, +) == observation.flowingTiles,
              observation.frozenRegionCounts.reduce(0, +) == observation.frozenTiles else { return nil }
        var topology: [WorldSplashReceiptV3.WaterTopology] = []
        if observation.standingTiles > 0 {
            topology.append(.standing)
            if observation.standingBodySizes.contains(where: { $0 < 9 }) { topology.append(.pool) }
            if observation.standingBodySizes.contains(where: { $0 >= 9 }) { topology.append(.lake) }
            if observation.standingDeepTiles > 0 { topology.append(.shelf) }
        }
        if observation.flowingTiles > 0 { topology += [.flowing, .channel] }
        let wet = Set(map.allPoints.filter { [.water, .deepWater, .ice].contains(map[$0].ground) })
        let wetComponents = splashComponents(points: wet, map: map)
        let dryComponents = splashComponents(points: Set(map.allPoints.filter {
            map[$0].ground != .chasm && !wet.contains($0)
        }), map: map)
        let nonChasmComponents = splashComponents(points: Set(map.allPoints.filter {
            map[$0].ground != .chasm
        }), map: map)
        let enclosedDryCount = dryComponents.count(where: { component in
            !component.contains(where: { $0.x == 0 || $0.y == 0
                || $0.x == map.width - 1 || $0.y == map.height - 1 })
                && component.allSatisfy { point in
                    map.neighbours(of: point).allSatisfy { component.contains($0) || wet.contains($0) }
                }
        })
        if enclosedDryCount > 0 { topology.append(.island) }
        if dryComponents.count > nonChasmComponents.count { topology.append(.broken) }
        let dominant: WorldSplashReceiptV3.WaterTopology? =
            observation.standingTiles == 0 && observation.flowingTiles == 0 ? nil
            : observation.standingTiles >= observation.flowingTiles ? .standing : .flowing
        return .init(shallowCount: shallow, deepCount: deep, frozenCount: frozen,
                     standingOwnedCount: observation.standingTiles,
                     flowingOwnedCount: observation.flowingTiles,
                     standingDeepCount: observation.standingDeepTiles,
                     flowingDeepCount: observation.flowingDeepTiles,
                     standingBodySizes: observation.standingBodySizes.sorted(),
                     flowingChannelSizes: observation.flowingChannelSizes.sorted(),
                     finalConnectedBodyCount: wetComponents.count,
                     dryComponentCount: dryComponents.count,
                     nonChasmComponentCount: nonChasmComponents.count,
                     enclosedDryComponentCount: enclosedDryCount,
                     coverage: splashBand(shallow + deep + frozen, of: map.tiles.count),
                     dominantTopology: dominant, topologyFlags: topology)
    }

    private static func splashComponents(points: Set<GridPoint>, map: WorldMap) -> [Set<GridPoint>] {
        var unseen = points
        var result: [Set<GridPoint>] = []
        while let start = unseen.min(by: { ($0.y, $0.x) < ($1.y, $1.x) }) {
            var component: Set<GridPoint> = [start]
            var queue = [start]
            unseen.remove(start)
            while !queue.isEmpty {
                let point = queue.removeFirst()
                for next in map.neighbours(of: point).filter(unseen.contains) {
                    unseen.remove(next); component.insert(next); queue.append(next)
                }
            }
            result.append(component)
        }
        return result
    }

    private static let schemaIdentity = "world-arrival-receipt-v1"

    static func illuminationSourceClass(light: PressureReading, cycle: PressureReading) -> String {
        if light.has("sourceless") { return "sourceless" }
        return cycle.peak > Tuning.DayNight.stoppedMaximumPeak
            && light.range > Tuning.Pressure.wideRangeThreshold ? "cyclic" : "constant"
    }

    static func illuminationBand(_ light: PressureReading) -> String {
        light.peak < 10 ? "trueDark" : light.peak < 35 ? "dim"
            : light.peak < 70 ? "ordinary" : light.peak < 90 ? "bright" : "blazing"
    }

    static func dominantDryGround(in map: WorldMap) throws -> GroundType {
        let counts = Dictionary(grouping: map.tiles.map(\.ground), by: { $0 }).mapValues(\.count)
        let dryOrder: [GroundType] = [
            .stone, .soil, .sand, .ice, .ash, .rubble, .mud, .growth, .groundcover
        ]
        guard let dominant = dryOrder.enumerated().max(by: { lhs, rhs in
            let left = counts[lhs.element] ?? 0
            let right = counts[rhs.element] ?? 0
            return left == right ? lhs.offset > rhs.offset : left < right
        }).flatMap({ (counts[$0.element] ?? 0) > 0 ? $0.element : nil }) else {
            throw Error.noDryGround
        }
        return dominant
    }

    private static func waterRelationship(
        for summary: WorldArrivalReceipt.TerrainSummary
    ) throws -> String {
        guard summary.nonChasmTileCount > 0,
              summary.deepWaterTileCount <= summary.wetTileCount else {
            throw Error.noDryGround
        }
        guard summary.wetTileCount > 0 else { return "none" }
        let wetShare = Double(summary.wetTileCount) / Double(summary.nonChasmTileCount)
        let deepShare = Double(summary.deepWaterTileCount) / Double(summary.wetTileCount)
        if wetShare <= 0.08 { return "pools" }
        if wetShare <= 0.35 { return deepShare < 0.25 ? "channels" : "shelves" }
        return "islands"
    }

    private static func scenePayload(
        receiptID: WorldArrivalReceiptID, generationSeed: UInt64,
        source: WritingDeskReviewModel, dominant: GroundType, waterRelationship: String,
        visualReceipt: WorldVisualReceipt, lightBand: String, sourceClass: String,
        atmosphere: WorldGrade2V1.Atmosphere,
        flora: [WorldArrivalReceipt.FloraSummary],
        crop: WorldArrivalReceipt.FirstMapCrop,
        causalFacts: [WorldArrivalReceipt.CausalVisualFact], description: String
    ) -> WorldArrivalSceneReceipt.Payload {
        let sourceID: String
        switch source.sourceKey {
        case .draft(let revision): sourceID = "draft-\(revision)"
        case .collected(_, let definitionID, _): sourceID = definitionID.rawValue
        }
        let density = densityBand(atmosphere.density, medium: atmosphere.medium)
        let page = WorldArrivalSceneReceipt.SourcePage(
            id: sourceID, title: source.title,
            marks: source.pageThumbnail.marks.map { mark in
                .init(x: mark.origin.column, y: mark.origin.row,
                      cells: mark.cells.map {
                          [$0.column - mark.origin.column, $0.row - mark.origin.row]
                      })
            })
        let material = visualReceipt.descriptor.material
        let sceneCrop = WorldArrivalSceneReceipt.FirstMapCrop(
            width: crop.width, height: crop.height,
            cells: crop.cells.enumerated().map { index, cell in
                .init(x: index % crop.width, y: index / crop.width,
                      ground: cell.ground, elevation: cell.elevation,
                      floraStableID: cell.floraStableID, visibility: cell.visibility)
            })
        return .init(
            receiptID: receiptID.rawValue, worldSeed: String(generationSeed), sourcePage: page,
            dominantGround: dominant, waterRelationship: waterRelationship,
            materialDescriptor: .init(
                identity: material.identity, paletteFamilyID: material.paletteFamilyID,
                transform: material.transform,
                resolvedColor: visualReceipt.descriptor.resolvedColors.material?.srgb),
            illumination: .init(band: lightBand, sourceClass: sourceClass),
            suspendedAtmosphere: .init(medium: atmosphere.medium, density: density, motion: "calm"),
            precipitation: .init(medium: "none", intensity: "none", motion: "calm"),
            flora: flora.map {
                .init(stableID: $0.stableID, formID: $0.formID, coverage: $0.coverage,
                      habit: $0.habit, color: $0.resolvedColor)
            },
            causalVisualFacts: causalFacts.filter { $0.markDisplayName?.isEmpty == false }.map {
                .init(markID: $0.semanticKey ?? "candidate-\($0.candidateMarkID.rawValue)",
                      visibleScope: $0.scope.rawValue,
                      contributionKind: $0.contributionKind.rawValue,
                      resultBand: $0.resultBand,
                      withoutAuthoredBand: $0.withoutAuthoredBand)
            }, entryDisclosure: nil, description: description,
            firstMapCropReceipt: sceneCrop)
    }

    private static func densityBand(_ density: Double, medium: String) -> String {
        guard medium != "none", density > 0 else { return "none" }
        if density < 25 { return "trace" }
        if density < 50 { return "light" }
        if density < 75 { return "heavy" }
        return "dense"
    }

    private static func sourceIdentity(_ source: WritingDeskSourceKey) -> String {
        switch source {
        case .draft(let revision): return "draft|\(revision)"
        case let .collected(instanceID, definitionID, canonicalDefinitionHash):
            return "collected|\(instanceID.rawValue)|\(definitionID.rawValue)|\(canonicalDefinitionHash)"
        }
    }

    static func firstCrop(map: WorldMap, flora: [Flora],
                          profile: WorldRules.VisibilityProfile,
                          center: GridPoint? = nil) -> WorldArrivalReceipt.FirstMapCrop {
        let center = center ?? map.entry
        let ids = Set(flora.map(\.id))
        let cells = (-4...4).flatMap { dy in (-4...4).map { dx -> WorldArrivalReceipt.MapCell in
            let point = GridPoint(x: center.x + dx, y: center.y + dy)
            guard map.contains(point) else {
                return .init(point: point, ground: nil, elevation: nil,
                             floraStableID: nil, visibility: "hidden")
            }
            let tile = map[point]
            let current = WorldRules.visibility(of: point, from: center, in: map, profile: profile)
            let terrain = WorldRules.terrainVisibility(current: current, wasRevealed: tile.isRevealed)
            guard terrain != .hidden else {
                return .init(point: point, ground: nil, elevation: nil,
                             floraStableID: nil, visibility: "hidden")
            }
            let visibility: String
            if current == .full { visibility = "full" }
            else if current == .fringe { visibility = "fringe" }
            else { visibility = "remembered" }
            let floraID = current == .full
                ? tile.flora.flatMap { ids.contains($0) ? "flora-\($0.rawValue)" : nil }
                : nil
            return .init(point: point, ground: tile.ground, elevation: tile.elevation,
                         floraStableID: floraID,
                         visibility: visibility)
        }}
        return .init(width: 9, height: 9, cells: cells)
    }

    private static func description(dominant: GroundType, water: String, lightBand: String,
                                    atmosphere: WorldArrivalReceipt.Atmosphere?) -> String {
        let waterClause = water == "none" ? "around the entry" : "between \(water) of water"
        let first = "\(dominant.displayName.capitalized) ground spreads \(waterClause) beneath \(lightBand) light."
        let second = atmosphere.map {
            "\($0.medium.capitalized) hangs through the air while the nearby terrain remains plainly visible."
        } ?? "Clear air leaves the nearby terrain and its water structure plainly exposed."
        return "\(first) \(second)"
    }
}
#endif
