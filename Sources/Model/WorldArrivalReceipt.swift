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
    static let isNativePresentationEnabled = false
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
    var counterfactualPassCount: Int?
    var counterfactualElapsedMilliseconds: Double?
    var entryDisclosure: String?
    var firstMapCropReceipt: FirstMapCrop
    var proseVersion: String
    var finalDescription: String
    var compositorVersion: String
    /// Nil only for the short-lived pre-scene schema; never synthesized during decode.
    var sceneReceipt: WorldArrivalSceneReceipt?
}

enum WorldArrivalReceiptFactory {
    enum Error: Swift.Error, Equatable { case noDryGround }

    static func make(runIndex: Int, generationSeed: UInt64,
                     source: WritingDeskReviewModel,
                     sourcePage: Page, book: BoundBook, map: WorldMap, flora: [Flora],
                     visualReceipt: WorldVisualReceipt,
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
        let lightBand: String = light.peak < 10 ? "trueDark" : light.peak < 35 ? "dim"
            : light.peak < 70 ? "ordinary" : light.peak < 90 ? "bright" : "blazing"
        let sourceClass = illuminationSourceClass(light: light, cycle: cycle)
        let atmosphere = visualReceipt.descriptor.atmosphere
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

        let started = Date()
        let actualAuthored = BookRules.sigils(for: book)
        let actualReadings = BookRules.readings(for: book, seed: generationSeed)
        let actualSummary = Worldgen.ArrivalCausalSummary(map: map, flora: flora)
        var summaryCache: [String: Worldgen.ArrivalCausalSummary] = [:]
        var counterfactualPassCount = 0
        var causalFacts: [WorldArrivalReceipt.CausalVisualFact] = []
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
                    book: removedBook, seed: generationSeed, readings: intervention.readings,
                    library: library, tuning: tuning,
                    isFreshFirstExpedition: isFreshFirstExpedition,
                    wildPageSelection: wildPageSelection,
                    wildPageOriginRunIndex: wildPageOriginRunIndex)
                summaryCache[fingerprint] = summary
                counterfactualPassCount += 1
            }
            causalFacts.append(contentsOf: WorldArrivalCausalCandidateRules.summaryFacts(
                candidate: candidate, actual: actualSummary, withoutCandidate: summary,
                actualReadings: actualReadings, withoutReadings: intervention.readings))
        }
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
        let crop = firstCrop(map: map, flora: flora, profile: visibilityProfile)
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
        return .init(version: WorldArrivalReceipt.schemaVersion,
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
                     counterfactualPassCount: counterfactualPassCount,
                     counterfactualElapsedMilliseconds: Date().timeIntervalSince(started) * 1_000,
                     entryDisclosure: nil,
                     firstMapCropReceipt: crop,
                     proseVersion: WorldArrivalReceipt.descriptionGrammarVersion,
                     finalDescription: description,
                     compositorVersion: WorldArrivalReceipt.sceneCompositorVersion,
                     sceneReceipt: WorldArrivalSceneReceipt(payload: scenePayload))
    }

    private static let schemaIdentity = "world-arrival-receipt-v1"

    static func illuminationSourceClass(light: PressureReading, cycle: PressureReading) -> String {
        if light.has("sourceless") { return "sourceless" }
        return cycle.peak > Tuning.DayNight.stoppedMaximumPeak
            && light.range > Tuning.Pressure.wideRangeThreshold ? "cyclic" : "constant"
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
        if density < 0.12 { return "trace" }
        if density < 0.35 { return "light" }
        if density < 0.7 { return "heavy" }
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
                          profile: WorldRules.VisibilityProfile) -> WorldArrivalReceipt.FirstMapCrop {
        let ids = Set(flora.map(\.id))
        let cells = (-4...4).flatMap { dy in (-4...4).map { dx -> WorldArrivalReceipt.MapCell in
            let point = GridPoint(x: map.entry.x + dx, y: map.entry.y + dy)
            guard map.contains(point) else {
                return .init(point: point, ground: nil, elevation: nil,
                             floraStableID: nil, visibility: "hidden")
            }
            let tile = map[point]
            let current = WorldRules.visibility(of: point, from: map.entry, in: map, profile: profile)
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
