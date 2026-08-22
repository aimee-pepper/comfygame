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
        enum ContributionKind: String, Codable, Sendable { case none, increased, reduced, reshaped }
        var markID: InstanceID
        var visibleScope: String
        var contributionKind: ContributionKind
        var resultBand: String
        var withoutAuthoredBand: String
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
}

enum WorldArrivalReceiptFactory {
    static func make(runIndex: Int, generationSeed: UInt64,
                     source: WritingDeskReviewModel,
                     book: BoundBook, map: WorldMap, flora: [Flora],
                     visualReceipt: WorldVisualReceipt) -> WorldArrivalReceipt {
        let counts = Dictionary(grouping: map.tiles.map(\.ground), by: { $0 }).mapValues(\.count)
        let dominant = counts.max {
            ($0.value, $0.key.rawValue) < ($1.value, $1.key.rawValue)
        }?.key ?? .soil
        let waterCount = (counts[.water] ?? 0) + (counts[.deepWater] ?? 0)
        let waterRelationship: String
        if waterCount == 0 { waterRelationship = "none" }
        else if waterCount * 5 < map.tiles.count { waterRelationship = "pools" }
        else if waterCount * 2 < map.tiles.count { waterRelationship = "channels" }
        else { waterRelationship = "shelves" }

        let light = BookRules.readings(for: book, seed: generationSeed)["illumination"]
        let lightBand: String = light.peak < 10 ? "trueDark" : light.peak < 35 ? "dim"
            : light.peak < 70 ? "ordinary" : light.peak < 90 ? "bright" : "blazing"
        let sourceClass = light.floor > 5 ? "constant" : "cyclic"
        let atmosphere = visualReceipt.descriptor.atmosphere
        let suspended = atmosphere.medium == "none" ? nil : WorldArrivalReceipt.Atmosphere(
            medium: atmosphere.medium, density: atmosphere.density, motion: "calm")

        let descriptorByID = Dictionary(uniqueKeysWithValues:
            visualReceipt.descriptor.flora.cast.map { ($0.speciesID, $0) })
        let floraSummaries = flora.prefix(4).compactMap { plant -> WorldArrivalReceipt.FloraSummary? in
            let stableID = "flora-\(plant.id.rawValue)"
            guard let descriptor = descriptorByID[stableID] else { return nil }
            let placements = map.tiles.count { $0.flora == plant.id }
            let coverage = placements * 20 < map.tiles.count ? "sparse"
                : placements * 5 < map.tiles.count ? "present" : "abundant"
            return .init(stableID: stableID, formID: descriptor.formID, coverage: coverage,
                         habit: plant.traits.habit.rawValue,
                         resolvedColor: descriptor.resolvedColor.srgb)
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
        let crop = firstCrop(map: map, flora: flora)
        let description = description(dominant: dominant, water: waterRelationship,
                                      lightBand: lightBand, atmosphere: suspended)
        let canonical = "\(Self.schemaIdentity)|\(runIndex)|\(generationSeed)|\(sourceIdentity(source.sourceKey))|\(visualReceipt.canonicalReceiptSHA256)"
        let id = SHA256.hash(data: Data(canonical.utf8)).map { String(format: "%02x", $0) }.joined()
        let receiptID = WorldArrivalReceiptID(rawValue: id)
        let scenePayload = scenePayload(
            receiptID: receiptID, generationSeed: generationSeed, source: source,
            dominant: dominant, waterRelationship: waterRelationship,
            visualReceipt: visualReceipt, lightBand: lightBand, sourceClass: sourceClass,
            atmosphere: atmosphere, flora: floraSummaries, crop: crop,
            description: description)
        return .init(version: WorldArrivalReceipt.schemaVersion,
                     id: receiptID, runIndex: runIndex, generationSeed: generationSeed,
                     sourcePagePhysicalReceipt: physical,
                     visualReceiptID: visualReceipt.canonicalReceiptSHA256,
                     visualSchemaVersion: visualReceipt.adapterVersion,
                     dominantGround: dominant, waterRelationship: waterRelationship,
                     materialDescriptor: visualReceipt.descriptor.material,
                     illumination: .init(peak: light.peak, floor: light.floor,
                                         band: lightBand, sourceClass: sourceClass),
                     suspendedAtmosphere: suspended, precipitation: nil,
                     flora: floraSummaries, causalVisualFacts: [], entryDisclosure: nil,
                     firstMapCropReceipt: crop,
                     proseVersion: WorldArrivalReceipt.descriptionGrammarVersion,
                     finalDescription: description,
                     compositorVersion: WorldArrivalReceipt.sceneCompositorVersion,
                     sceneReceipt: WorldArrivalSceneReceipt(payload: scenePayload))
    }

    private static let schemaIdentity = "world-arrival-receipt-v1"

    private static func scenePayload(
        receiptID: WorldArrivalReceiptID, generationSeed: UInt64,
        source: WritingDeskReviewModel, dominant: GroundType, waterRelationship: String,
        visualReceipt: WorldVisualReceipt, lightBand: String, sourceClass: String,
        atmosphere: WorldGrade2V1.Atmosphere,
        flora: [WorldArrivalReceipt.FloraSummary],
        crop: WorldArrivalReceipt.FirstMapCrop, description: String
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
            causalVisualFacts: [], entryDisclosure: nil, description: description,
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

    static func firstCrop(map: WorldMap, flora: [Flora]) -> WorldArrivalReceipt.FirstMapCrop {
        let ids = Set(flora.map(\.id))
        let cells = (-4...4).flatMap { dy in (-4...4).map { dx -> WorldArrivalReceipt.MapCell in
            let point = GridPoint(x: map.entry.x + dx, y: map.entry.y + dy)
            guard map.contains(point) else {
                return .init(point: point, ground: nil, elevation: nil,
                             floraStableID: nil, visibility: "hidden")
            }
            let tile = map[point]
            guard tile.isRevealed else {
                return .init(point: point, ground: nil, elevation: nil,
                             floraStableID: nil, visibility: "hidden")
            }
            let floraID = tile.flora.flatMap { ids.contains($0) ? "flora-\($0.rawValue)" : nil }
            return .init(point: point, ground: tile.ground, elevation: tile.elevation,
                         floraStableID: floraID,
                         visibility: tile.isRevealed ? "full" : "hidden")
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
