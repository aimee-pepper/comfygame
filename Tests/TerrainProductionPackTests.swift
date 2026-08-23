import CryptoKit
import UIKit
import XCTest
@testable import Bookbinder

@MainActor final class TerrainProductionPackTests: XCTestCase {
    func testNativeRegionContinuityMatchesEveryAcceptedAdapterCase() throws {
        let data = try Data(contentsOf: regionContinuityCorpusURL)
        let root = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(root["schemaVersion"] as? String, "terrain-region-continuity-v1")
        XCTAssertEqual(root["hidden"] as? String, "no-request")
        let cases = try XCTUnwrap(root["cases"] as? [[String: Any]])
        XCTAssertEqual(cases.count, 121)
        let pack = MapAssetTestSupport.productionPack()

        for fixture in cases {
            let id = try XCTUnwrap(fixture["id"] as? String)
            let raw = try XCTUnwrap(fixture["request"] as? [String: Any])
            let point = try XCTUnwrap(raw["point"] as? [String: Int])
            let neighbors = try XCTUnwrap(raw["cardinalNeighbors"] as? [String: String])
            let contours = try XCTUnwrap(raw["edgeContourIDs"] as? [String: Int])
            let ground = try XCTUnwrap(GroundType(rawValue: try XCTUnwrap(raw["ground"] as? String)))
            let visibility = try XCTUnwrap(TerrainProductionPack.Visibility(
                rawValue: try XCTUnwrap(raw["visibility"] as? String)))
            func neighbor(_ direction: String) throws -> TerrainProductionPack.Neighbor {
                let value = try XCTUnwrap(neighbors[direction])
                if value == "same" { return .same }
                if value == "unknown" { return .unknown }
                let typed = try XCTUnwrap(GroundType(rawValue: value))
                return .ground(.init(typed))
            }
            let request = try MapAssetTestSupport.productionRequest(
                ground: ground,
                point: .init(x: try XCTUnwrap(point["x"]), y: try XCTUnwrap(point["y"])),
                visualSeed: UInt64(try XCTUnwrap(raw["visualSeed"] as? Int)),
                featureVariant: try XCTUnwrap(raw["featureVariant"] as? Int),
                cardinalNeighbors: .init(
                    north: try neighbor("north"), east: try neighbor("east"),
                    south: try neighbor("south"), west: try neighbor("west")),
                edgeContourIDs: .init(
                    north: try XCTUnwrap(contours["north"]),
                    east: try XCTUnwrap(contours["east"]),
                    south: try XCTUnwrap(contours["south"]),
                    west: try XCTUnwrap(contours["west"])),
                visibility: visibility, reduceMotion: true)
            XCTAssertEqual(sha256(try pack.regionContinuityBaseRoles(for: request)),
                           fixture["baseRoleSHA256"] as? String, id)
            XCTAssertEqual(sha256(TerrainProductionPack.materialBoundaryMask(request)),
                           fixture["materialBoundarySHA256"] as? String, id)
            XCTAssertEqual(sha256(try pack.regionContinuityConformanceRGBA(for: request)),
                           fixture["rgbaSHA256"] as? String, id)
            let accent = try XCTUnwrap(fixture["accent"] as? [String: Int])
            XCTAssertEqual(TerrainProductionPack.smallAccentPoint(
                point: request.point, visualSeed: request.visualSeed),
                GridPoint(x: try XCTUnwrap(accent["x"]), y: try XCTUnwrap(accent["y"])), id)
        }
    }

    func testRegionBoundaryHasOneOwnerAndNoFogDisclosure() throws {
        let grounds = TerrainProductionPack.Ground.allCases
        for (lowerIndex, lower) in grounds.enumerated() {
            for higher in grounds.dropFirst(lowerIndex + 1) {
                let owner = try MapAssetTestSupport.productionRequest(
                    ground: GroundType(rawValue: lower.rawValue)!,
                    cardinalNeighbors: .init(north: .unknown, east: .ground(higher),
                                             south: .same, west: .unknown))
                let nonOwner = try MapAssetTestSupport.productionRequest(
                    ground: GroundType(rawValue: higher.rawValue)!,
                    cardinalNeighbors: .init(north: .unknown, east: .unknown,
                                             south: .same, west: .ground(lower)))
                XCTAssertTrue(TerrainProductionPack.materialBoundaryMask(owner).contains { $0 > 0 })
                XCTAssertFalse(TerrainProductionPack.materialBoundaryMask(nonOwner).contains { $0 > 0 })
                for hiddenTreatment in [TerrainProductionPack.Visibility.fringe, .remembered] {
                    var obscured = owner
                    obscured.visibility = hiddenTreatment
                    XCTAssertFalse(TerrainProductionPack.materialBoundaryMask(obscured)
                        .contains { $0 > 0 })
                }
            }
        }
    }

    func testRegionBoundaryIsAdditiveToAcceptedSpecialEdgeGrammar() throws {
        let pack = MapAssetTestSupport.productionPack()
        let priority: [TerrainProductionPack.Ground: Int] = [
            .chasm: 0, .deepWater: 1, .water: 2, .stone: 3, .ice: 3, .rubble: 3,
            .soil: 4, .sand: 4, .ash: 4, .mud: 4, .groundcover: 5, .growth: 6,
        ]
        func legacySource(_ request: TerrainProductionPack.Request, x: Int, y: Int) -> GridPoint {
            let blockX = request.point.x / 4, blockY = request.point.y / 4
            let macroX = request.point.x % 4, macroY = request.point.y % 4
            let flipX = (blockX + request.featureVariant) % 2 == 1
            let flipY = (blockY + (request.featureVariant >> 1)) % 2 == 1
            return .init(x: flipX ? 63 - (macroX * 16 + x) : macroX * 16 + x,
                         y: flipY ? 63 - (macroY * 16 + y) : macroY * 16 + y)
        }
        func expectedRoles(_ request: TerrainProductionPack.Request) throws -> [Int8] {
            let base = try pack.regionContinuityRoleMapForTesting(request.ground)
            var expected = [Int8](repeating: 0, count: 256)
            for y in 0..<16 { for x in 0..<16 {
                let source = TerrainProductionPack.regionContinuousMacroSourceCoordinate(
                    point: request.point, x: x, y: y, featureVariant: request.featureVariant)
                expected[y * 16 + x] = base[source.y * 64 + source.x]
            }}
            for direction in TerrainProductionPack.Direction.allCases {
                guard case .ground(let neighbor) = request.cardinalNeighbors[direction],
                      neighbor != request.ground else { continue }
                let depth = request.ground == .deepWater && neighbor == .water
                let owns = request.ground == .groundcover && neighbor == .growth
                    || priority[neighbor, default: 0] > priority[request.ground, default: 0]
                guard depth || owns else { continue }
                let neighborMap = try pack.regionContinuityRoleMapForTesting(neighbor)
                let mask = try pack.regionContinuityEdgeMaskForTesting(
                    direction: direction, contour: request.edgeContourIDs[direction])
                for y in 0..<16 { for x in 0..<16 where mask[y * 16 + x] {
                    let index = y * 16 + x
                    let source = TerrainProductionPack.regionContinuousMacroSourceCoordinate(
                        point: request.point, x: x, y: y,
                        featureVariant: request.featureVariant)
                    let neighborRole = neighborMap[source.y * 64 + source.x]
                    expected[index] = depth ? max(3, expected[index]) : neighborRole
                }}
            }
            return expected
        }
        let pairs: [(GroundType, TerrainProductionPack.Ground)] = [
            (.deepWater, .water), (.groundcover, .growth), (.stone, .soil),
        ]
        for (ground, neighbor) in pairs {
            let request = try MapAssetTestSupport.productionRequest(
                ground: ground, point: .init(x: 2, y: 3), featureVariant: 1,
                cardinalNeighbors: .init(north: .same, east: .ground(neighbor),
                                         south: .same, west: .unknown))
            let installed = try pack.rgba(for: request)
            let acceptedSeam = try pack.regionContinuityAcceptedRGBA(for: request)
            XCTAssertEqual(acceptedSeam, installed, "\(ground.rawValue)/\(neighbor.rawValue)")
            var sameMaterial = request
            sameMaterial.cardinalNeighbors = .init(
                north: .same, east: .same, south: .same, west: .unknown)
            XCTAssertNotEqual(installed, try pack.rgba(for: sameMaterial),
                              "accepted edge grammar must be exercised for "
                                + "\(ground.rawValue)/\(neighbor.rawValue)")

            XCTAssertEqual(try pack.regionContinuousRolesForTesting(for: request),
                           try expectedRoles(request),
                           "independent corrected-coordinate role oracle failed for "
                            + "\(ground.rawValue)/\(neighbor.rawValue)")
            let final = try pack.regionContinuousRGBA(for: request)
            let preBoundary = try pack.regionContinuityPreBoundaryRGBAForTesting(for: request)
            let boundary = TerrainProductionPack.materialBoundaryMask(request)
            for index in boundary.indices where boundary[index] == 0 {
                let offset = index * 4
                XCTAssertEqual(Array(final[offset..<(offset + 4)]),
                               Array(preBoundary[offset..<(offset + 4)]),
                               "material boundary escaped its mask at \(index)")
            }
            for index in boundary.indices {
                let offset = index * 4
                guard Array(preBoundary[offset..<(offset + 4)])
                        != Array(installed[offset..<(offset + 4)]) else { continue }
                let x = index % 16, y = index / 16
                XCTAssertNotEqual(
                    TerrainProductionPack.regionContinuousMacroSourceCoordinate(
                        point: request.point, x: x, y: y,
                        featureVariant: request.featureVariant),
                    legacySource(request, x: x, y: y),
                    "non-boundary semantic difference was not caused by sampler coordinates")
            }
        }

        let orderingCases = [
            try MapAssetTestSupport.productionRequest(
                ground: .water, point: .init(x: 2, y: 3), featureVariant: 1,
                cardinalNeighbors: .init(north: .same, east: .ground(.deepWater),
                                         south: .same, west: .same),
                motionBand: .moving, phaseOffset: 3, presentationTick: 11),
            try MapAssetTestSupport.productionRequest(
                ground: .soil, point: .init(x: 2, y: 3), featureVariant: 1,
                cardinalNeighbors: .init(north: .same, east: .ground(.growth),
                                         south: .same, west: .same),
                reduceMotion: true, snow: true, settledAsh: true),
        ]
        let boundaryColors: Set<[UInt8]> = [[37, 43, 42, 255], [173, 164, 126, 255]]
        for request in orderingCases {
            let before = try pack.regionContinuityPreBoundaryRGBAForTesting(for: request)
            let after = try pack.regionContinuousRGBA(for: request)
            let mask = TerrainProductionPack.materialBoundaryMask(request)
            XCTAssertTrue(mask.contains { $0 > 0 })
            for index in mask.indices {
                let offset = index * 4, pixel = Array(after[offset..<(offset + 4)])
                if mask[index] == 0 {
                    XCTAssertEqual(pixel, Array(before[offset..<(offset + 4)]))
                } else {
                    XCTAssertTrue(boundaryColors.contains(pixel),
                                  "boundary did not compose after motion/deposits")
                }
            }
            var fringe = request; fringe.visibility = .fringe
            XCTAssertFalse(TerrainProductionPack.materialBoundaryMask(fringe).contains { $0 > 0 })
            XCTAssertEqual(try pack.regionContinuousRGBA(for: fringe),
                           try pack.regionContinuityPreBoundaryRGBAForTesting(for: fringe))
        }
    }

    func testRegionFeatureVariantIsWorldStableAndSharedContoursAreComplementary() {
        let variant = MapAssetContract.regionFeatureVariant(mapSeed: 9041)
        XCTAssertEqual(variant, MapAssetContract.regionFeatureVariant(mapSeed: 9041))
        XCTAssertTrue((0...3).contains(variant))
        let point = GridPoint(x: 7, y: 9)
        XCTAssertEqual(MapAssetContract.edgeContourID(mapSeed: 9041, point: point, direction: .east),
                       MapAssetContract.edgeContourID(
                        mapSeed: 9041, point: .init(x: 8, y: 9), direction: .west))
    }

    func testWorldContinuousMacroSamplerUsesOnlyTheAuthoredInterior() {
        func sourceX(_ logicalX: Int, variant: Int) -> Int {
            let point = GridPoint(x: Int(floor(Double(logicalX) / 16.0)), y: 0)
            let local = ((logicalX % 16) + 16) % 16
            return TerrainProductionPack.regionContinuousMacroSourceCoordinate(
                point: point, x: local, y: 0, featureVariant: variant).x
        }

        for variant in 0...3 {
            let samples = (-256...256).map { sourceX($0, variant: variant) }
            XCTAssertTrue(samples.allSatisfy { (0...62).contains($0) })
            XCTAssertFalse(samples.contains(63), "outer guard column became map content")
            for pair in zip(samples, samples.dropFirst()) {
                XCTAssertEqual(abs(pair.1 - pair.0), 1,
                               "adjacent world pixels must advance exactly one source pixel")
            }
        }

        XCTAssertEqual((60...65).map { sourceX($0, variant: 0) }, [60, 61, 62, 61, 60, 59])
        XCTAssertEqual(sourceX(63, variant: 0), 61)
        XCTAssertEqual(sourceX(64, variant: 0), 60)
    }

    func testDenseSameMaterialWaterAndSoilNeverSampleGuardRowsOrAddBoundaries() throws {
        for ground in [GroundType.water, .soil] {
            var firstRender: [[UInt8]] = []
            for y in 0..<9 { for x in 0..<9 {
                let point = GridPoint(x: x, y: y)
                for py in 0..<16 { for px in 0..<16 {
                    let source = TerrainProductionPack.regionContinuousMacroSourceCoordinate(
                        point: point, x: px, y: py, featureVariant: 1)
                    XCTAssertTrue((0...62).contains(source.x), "\(ground.rawValue) x guard")
                    XCTAssertTrue((0...62).contains(source.y), "\(ground.rawValue) y guard")
                }}
                let request = try MapAssetTestSupport.productionRequest(
                    ground: ground, point: point, visualSeed: 9041, featureVariant: 1,
                    cardinalNeighbors: .init(
                        north: .same, east: .same, south: .same, west: .same),
                    reduceMotion: true)
                XCTAssertFalse(TerrainProductionPack.materialBoundaryMask(request).contains { $0 > 0 })
                firstRender.append(try MapAssetTestSupport.productionPack()
                    .regionContinuousRGBA(for: request))
            }}
            var secondRender: [[UInt8]] = []
            for y in 0..<9 { for x in 0..<9 {
                let request = try MapAssetTestSupport.productionRequest(
                    ground: ground, point: .init(x: x, y: y), visualSeed: 9041,
                    featureVariant: 1, cardinalNeighbors: .init(
                        north: .same, east: .same, south: .same, west: .same),
                    reduceMotion: true)
                secondRender.append(try MapAssetTestSupport.productionPack()
                    .regionContinuousRGBA(for: request))
            }}
            XCTAssertEqual(firstRender, secondRender, "\(ground.rawValue) redraw drifted")
        }
    }

    func testWorldContinuousMacroSamplerIsSeedCoordinateAndPhaseDeterministic() {
        for seed in [UInt64(0), 1, 9041, .max] {
            let variant = MapAssetContract.regionFeatureVariant(mapSeed: seed)
            for point in [GridPoint(x: -7, y: -5), .init(x: 0, y: 0), .init(x: 17, y: 23)] {
                let first = TerrainProductionPack.regionContinuousMacroSourceCoordinate(
                    point: point, x: 9, y: 12, featureVariant: variant)
                let second = TerrainProductionPack.regionContinuousMacroSourceCoordinate(
                    point: point, x: 9, y: 12, featureVariant: variant)
                XCTAssertEqual(first, second)
                XCTAssertTrue((0...62).contains(first.x))
                XCTAssertTrue((0...62).contains(first.y))
            }
        }
        let origin = TerrainProductionPack.regionContinuousMacroSourceCoordinate(
            point: .init(x: 0, y: 0), x: 0, y: 0, featureVariant: 0)
        let xPhase = TerrainProductionPack.regionContinuousMacroSourceCoordinate(
            point: .init(x: 0, y: 0), x: 0, y: 0, featureVariant: 1)
        let yPhase = TerrainProductionPack.regionContinuousMacroSourceCoordinate(
            point: .init(x: 0, y: 0), x: 0, y: 0, featureVariant: 2)
        XCTAssertEqual(origin, .init(x: 0, y: 0))
        XCTAssertEqual(xPhase, .init(x: 16, y: 0))
        XCTAssertEqual(yPhase, .init(x: 0, y: 16))
    }

    func testNativeRegionContinuityPhoneEvidence() throws {
        let actual = try actualRendererEvidence()
        let visibility = try actualVisibilityEvidence()
        let wall = try actualWallEvidence()
        let actualGray = try XCTUnwrap(Self.literalGrayscale(actual))
        let visibilityGray = try XCTUnwrap(Self.literalGrayscale(visibility))
        let wallGray = try XCTUnwrap(Self.literalGrayscale(wall))
        XCTAssertEqual(actual.pngData(), try actualRendererEvidence().pngData(),
                       "same native inputs must redraw byte-identically")
        for image in [actual, visibility, wall, actualGray, visibilityGray, wallGray] {
            XCTAssertEqual(image.size, CGSize(width: 368, height: 800))
        }
        for (name, image) in [
            ("terrain-region-continuity-actual-renderer-368x800", actual),
            ("terrain-region-continuity-actual-renderer-grayscale-368x800", actualGray),
            ("terrain-region-continuity-visibility-368x800", visibility),
            ("terrain-region-continuity-visibility-grayscale-368x800", visibilityGray),
            ("terrain-region-continuity-wall-layer-order-368x800", wall),
            ("terrain-region-continuity-wall-layer-order-grayscale-368x800", wallGray),
        ] {
            let attachment = XCTAttachment(image: image)
            attachment.name = name
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }

    func testSameMaterialMacroSamplerPhoneEvidence() throws {
        let evidence = try sameMaterialMacroSamplerEvidence()
        let grayscale = try XCTUnwrap(Self.literalGrayscale(evidence))
        XCTAssertEqual(evidence.size, CGSize(width: 368, height: 800))
        XCTAssertEqual(grayscale.size, CGSize(width: 368, height: 800))
        for (name, image) in [
            ("same-material-macro-sampler-368x800", evidence),
            ("same-material-macro-sampler-grayscale-368x800", grayscale),
        ] {
            let attachment = XCTAttachment(image: image)
            attachment.name = name
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }

    func testStrictPackOpensAndMatchesEveryAcceptedRGBAFixture() throws {
        let pack = MapAssetTestSupport.productionPack()
        try pack.open()
        let cases = try pack.conformanceCases
        XCTAssertEqual(cases.count, 149)
        for fixture in cases {
            let rgba = try pack.rgba(for: fixture.request)
            XCTAssertEqual(sha256(rgba), fixture.rgbaSHA256, fixture.id)
        }
    }

    func testAllTwelveGroundsAreRenderableAndOpaque() throws {
        XCTAssertEqual(TerrainProductionPack.Ground.allCases.map(\.rawValue), [
            "stone", "soil", "sand", "ice", "ash", "water", "deepWater", "rubble",
            "mud", "growth", "chasm", "groundcover",
        ])
        for ground in GroundType.allCases {
            let request = try MapAssetTestSupport.productionRequest(ground: ground)
            let pixels = try MapAssetTestSupport.productionPixels(request)
            XCTAssertEqual(pixels.count, 16 * 16 * 4, ground.rawValue)
            XCTAssertTrue(stride(from: 3, to: pixels.count, by: 4)
                .allSatisfy { pixels[$0] == 255 }, ground.rawValue)
        }
    }

    func testDepositsAreIndependentBoundedAndExcludedFromWater() throws {
        let none = try MapAssetTestSupport.productionPixels(
            MapAssetTestSupport.productionRequest(
                ground: .stone, point: .init(x: 2, y: 3), featureVariant: 1))
        let snow = try MapAssetTestSupport.productionPixels(
            MapAssetTestSupport.productionRequest(
                ground: .stone, point: .init(x: 2, y: 3), featureVariant: 1, snow: true))
        let ash = try MapAssetTestSupport.productionPixels(
            MapAssetTestSupport.productionRequest(
                ground: .stone, point: .init(x: 2, y: 3), featureVariant: 1,
                settledAsh: true))
        let both = try MapAssetTestSupport.productionPixels(
            MapAssetTestSupport.productionRequest(
                ground: .stone, point: .init(x: 2, y: 3), featureVariant: 1,
                snow: true, settledAsh: true))
        XCTAssertNotEqual(none, snow)
        XCTAssertNotEqual(none, ash)
        XCTAssertNotEqual(snow, both)
        XCTAssertNotEqual(ash, both)

        let changedPixels = stride(from: 0, to: both.count, by: 4).filter { index in
            Array(both[index..<(index + 4)]) != Array(none[index..<(index + 4)])
        }.count
        XCTAssertLessThanOrEqual(changedPixels, 179)

        let water = try MapAssetTestSupport.productionPixels(
            MapAssetTestSupport.productionRequest(ground: .water))
        let coveredWater = try MapAssetTestSupport.productionPixels(
            MapAssetTestSupport.productionRequest(
                ground: .water, snow: true, settledAsh: true))
        XCTAssertEqual(water, coveredWater)
    }

    func testStrictLoaderFailsClosedForChangedManifestOrAssetBytes() throws {
        let root = runtimeRoot
        let manifestChanged = TerrainProductionPack(rootURL: root) { url in
            var data = try Data(contentsOf: url)
            if url.lastPathComponent == "manifest.json" { data.append(0x20) }
            return data
        }
        XCTAssertThrowsError(try manifestChanged.open()) {
            XCTAssertEqual($0 as? TerrainProductionPack.PackError, .invalidManifest)
        }

        let assetChanged = TerrainProductionPack(rootURL: root) { url in
            var data = try Data(contentsOf: url)
            if url.pathExtension == "png", !data.isEmpty { data[data.startIndex] ^= 0xff }
            return data
        }
        XCTAssertThrowsError(try assetChanged.open()) {
            guard case .corruptAsset = $0 as? TerrainProductionPack.PackError else {
                return XCTFail("Unexpected error: \($0)")
            }
        }
    }

    func testAuthoredSouthWallPackPinsManifestAndEveryStableRoute() throws {
        let pack = TerrainSouthWallPack(rootURL: southWallRuntimeRoot)
        try pack.open()
        let descriptor = try identicalDescriptor()
        let grounds: [TerrainProductionPack.Ground] = [
            .stone, .soil, .sand, .ash, .rubble, .mud,
        ]
        for ground in grounds { for depth in 1...3 {
            for west in [false, true] { for east in [false, true] { for variant in 0...3 {
                let request = try TerrainSouthWallPack.Request(
                    ground: ground, depth: depth, westContinuation: west,
                    eastContinuation: east, featureVariant: variant)
                let rgba = try pack.rgba(for: request, descriptor: descriptor)
                XCTAssertEqual(rgba.count, 16 * 3 * 4)
                XCTAssertTrue(stride(from: 3, to: rgba.count, by: 4).contains {
                    rgba[$0] == 255
                })
            }}}
        }}
        let span = try pack.rgba(
            for: TerrainSouthWallPack.Request(
                ground: .stone, depth: 3, westContinuation: true,
                eastContinuation: true, featureVariant: 0),
            descriptor: descriptor)
        XCTAssertEqual(sha256(span),
                       "0308d6397bdc95ccf0215d953d70bdb1419424e24f0e85c03efe302176ce5bb7")
    }

    func testBuiltAppContainsBothRuntimePacksAtTheirExactNames() throws {
        let terrain = try TerrainProductionPack.bundled()
        try terrain.open()
        let walls = try TerrainSouthWallPack.bundled()
        try walls.open()
        XCTAssertTrue(FileManager.default.isReadableFile(atPath: Bundle.main.bundleURL
            .appendingPathComponent("TerrainProductionPack-v1/manifest.json").path))
        XCTAssertTrue(FileManager.default.isReadableFile(atPath: Bundle.main.bundleURL
            .appendingPathComponent("TerrainSouthWallPack-v1/manifest.json").path))
    }

    func testSouthWallPackFailsClosedForManifestAssetAndIllegalGround() throws {
        let changedManifest = TerrainSouthWallPack(rootURL: southWallRuntimeRoot) { url in
            var data = try Data(contentsOf: url)
            if url.lastPathComponent == "manifest.json" { data.append(0x20) }
            return data
        }
        XCTAssertThrowsError(try changedManifest.open()) {
            XCTAssertEqual($0 as? TerrainSouthWallPack.WallError, .invalidManifest)
        }
        XCTAssertThrowsError(try TerrainSouthWallPack.Request(
            ground: .water, depth: 1, westContinuation: false,
            eastContinuation: false, featureVariant: 0))

        let descriptor = try identicalDescriptor()
        let changedAsset = TerrainSouthWallPack(rootURL: southWallRuntimeRoot) { url in
            var data = try Data(contentsOf: url)
            if url.pathExtension == "png", !data.isEmpty { data[data.startIndex] ^= 0xff }
            return data
        }
        let request = try TerrainSouthWallPack.Request(
            ground: .soil, depth: 2, westContinuation: false,
            eastContinuation: true, featureVariant: 1)
        XCTAssertThrowsError(try changedAsset.rgba(for: request, descriptor: descriptor)) {
            guard case .corruptAsset = $0 as? TerrainSouthWallPack.WallError else {
                return XCTFail("Unexpected error: \($0)")
            }
        }
    }

    private var runtimeRoot: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("RuntimePacks/TerrainProductionPack-v1", isDirectory: true)
    }

    private var southWallRuntimeRoot: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("RuntimePacks/TerrainSouthWallPack-v1", isDirectory: true)
    }

    private var regionContinuityCorpusURL: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent(
                "AssetLab/artifacts/terrain-region-continuity-v1/native-adapter-conformance.json")
    }

    private func phoneEvidence(grayscale: Bool) throws -> UIImage {
        let pack = MapAssetTestSupport.productionPack()
        let wallPack = TerrainSouthWallPack(rootURL: southWallRuntimeRoot)
        let wallRGBA = try wallPack.rgba(for: .init(
            ground: .rubble, depth: 3, westContinuation: true,
            eastContinuation: true, featureVariant: 1), descriptor: identicalDescriptor())
        let wallImage = try XCTUnwrap(Self.image(rgba: wallRGBA, width: 16, height: 3,
                                                  grayscale: grayscale))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: 368, height: 800), format: format)
            .image { renderer in
                let context = renderer.cgContext
                UIColor(red: 0.055, green: 0.085, blue: 0.084, alpha: 1).setFill()
                context.fill(CGRect(x: 0, y: 0, width: 368, height: 800))
                func label(_ value: String, x: CGFloat, y: CGFloat, size: CGFloat = 13) {
                    (value as NSString).draw(at: CGPoint(x: x, y: y), withAttributes: [
                        .font: UIFont.monospacedSystemFont(ofSize: size, weight: .semibold),
                        .foregroundColor: UIColor(white: 0.9, alpha: 1),
                    ])
                }
                func ground(_ x: Int, _ y: Int) -> GroundType {
                    if (x - 2) * (x - 2) + (y - 2) * (y - 2) <= 1 { return .deepWater }
                    if (x - 2) * (x - 2) + (y - 2) * (y - 2) <= 5 { return .water }
                    if x == 0 || y == 4 { return .growth }
                    return (x + y).isMultiple(of: 4) ? .rubble : .soil
                }
                func neighbors(_ x: Int, _ y: Int) -> TerrainProductionPack.Cardinal<TerrainProductionPack.Neighbor> {
                    let here = ground(x, y)
                    func at(_ xx: Int, _ yy: Int) -> TerrainProductionPack.Neighbor {
                        guard (0..<5).contains(xx), (0..<5).contains(yy) else { return .unknown }
                        let other = ground(xx, yy)
                        return other == here ? .same : .ground(.init(other))
                    }
                    return .init(north: at(x, y - 1), east: at(x + 1, y),
                                 south: at(x, y + 1), west: at(x - 1, y))
                }
                func drawGrid(origin: CGPoint, scale: CGFloat, scattered: Bool) throws {
                    for y in 0..<5 { for x in 0..<5 {
                        let point = GridPoint(x: x, y: y)
                        let variant = scattered ? Int(MapAssetContract.terrainSeed(
                            mapSeed: 9041, point: point) & 3) : 1
                        let request = try MainActor.assumeIsolated {
                            try MapAssetTestSupport.productionRequest(
                            ground: ground(x, y), point: point, visualSeed: 9041,
                            featureVariant: variant, cardinalNeighbors: neighbors(x, y),
                            edgeContourIDs: .init(
                                north: MapAssetContract.edgeContourID(mapSeed: 9041, point: point,
                                                                      direction: .north),
                                east: MapAssetContract.edgeContourID(mapSeed: 9041, point: point,
                                                                     direction: .east),
                                south: MapAssetContract.edgeContourID(mapSeed: 9041, point: point,
                                                                      direction: .south),
                                west: MapAssetContract.edgeContourID(mapSeed: 9041, point: point,
                                                                     direction: .west)),
                            reduceMotion: true)
                        }
                        let rgba = try pack.regionContinuousRGBA(for: request)
                        let renderedImage = MainActor.assumeIsolated {
                            Self.image(rgba: rgba, grayscale: grayscale)
                        }
                        guard let image = renderedImage else {
                            XCTFail("Native RGBA could not form an image"); return
                        }
                        context.interpolationQuality = .none
                        image.draw(in: CGRect(x: origin.x + CGFloat(x) * 16 * scale,
                                              y: origin.y + CGFloat(y) * 16 * scale,
                                              width: 16 * scale, height: 16 * scale))
                    }}
                }
                label("NATIVE TERRAIN CONTINUITY", x: 14, y: 16, size: 18)
                label("CURRENT TILE SCATTER", x: 12, y: 54, size: 10)
                label("CORRECTED WORLD MACRO", x: 194, y: 54, size: 10)
                try? drawGrid(origin: CGPoint(x: 12, y: 76), scale: 2, scattered: true)
                try? drawGrid(origin: CGPoint(x: 194, y: 76), scale: 2, scattered: false)
                label("5×5 MIXED POOL + MATERIAL BOUNDARY", x: 14, y: 254)
                try? drawGrid(origin: CGPoint(x: 64, y: 278), scale: 3, scattered: false)
                label("SHALLOW / DEEP POOL · MIXED BOUNDARY", x: 14, y: 532)
                label("SOUTH WALL REMAINS EXTERNAL + AUTHORED", x: 14, y: 562)
                context.interpolationQuality = .none
                for index in 0..<5 {
                    wallImage.draw(in: CGRect(x: 64 + index * 48, y: 600,
                                              width: 48, height: 9))
                }
                label("FULL: contour visible", x: 14, y: 684, size: 12)
                label("FRINGE / REMEMBERED: contour request empty", x: 14, y: 712, size: 12)
                label("HIDDEN: no terrain request", x: 14, y: 740, size: 12)
            }
    }

    private func actualRendererEvidence() throws -> UIImage {
        func uniform(_ ground: GroundType) -> [[GroundType]] {
            Array(repeating: Array(repeating: ground, count: 5), count: 5)
        }
        let pool: [[GroundType]] = (0..<7).map { y in (0..<7).map { x in
            let distance = (x - 3) * (x - 3) + (y - 3) * (y - 3)
            if distance <= 2 { return .deepWater }
            if distance <= 10 { return .water }
            return (x + y).isMultiple(of: 4) ? .stone : .soil
        }}
        let corridor: [[GroundType]] = (0..<7).map { y in (0..<7).map { x in
            let oneWide = x == 1 && y <= 4 || y == 4 && (1...3).contains(x)
            let twoWide = (4...5).contains(x) && y >= 2 || (4...6).contains(x) && (2...3).contains(y)
            return oneWide || twoWide ? .growth : .stone
        }}
        let equalHeight: [[GroundType]] = (0..<5).map { y in (0..<5).map { x in
            x < 2 ? .soil : y < 2 ? .rubble : .stone
        }}
        let panels: [(String, UIImage)] = [
            ("ALL STONE 5×5", try nativeGridImage(uniform(.stone))),
            ("ALL WATER 5×5", try nativeGridImage(uniform(.water))),
            ("CORRIDORS 1/2 TILE", try nativeGridImage(corridor)),
            ("SHALLOW/DEEP POOL 7×7", try nativeGridImage(pool)),
            ("EQUAL-HEIGHT BOUNDARY", try nativeGridImage(equalHeight)),
        ]
        let format = UIGraphicsImageRendererFormat(); format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: 368, height: 800), format: format)
            .image { output in
                UIColor(red: 0.055, green: 0.085, blue: 0.084, alpha: 1).setFill()
                output.cgContext.fill(CGRect(x: 0, y: 0, width: 368, height: 800))
                func text(_ value: String, _ x: CGFloat, _ y: CGFloat, _ size: CGFloat = 10) {
                    (value as NSString).draw(at: .init(x: x, y: y), withAttributes: [
                        .font: UIFont.monospacedSystemFont(ofSize: size, weight: .semibold),
                        .foregroundColor: UIColor(white: 0.9, alpha: 1),
                    ])
                }
                text("ACTUAL MAPASSETRENDERER OUTPUT", 12, 14, 16)
                for (index, panel) in panels.enumerated() {
                    let column = index % 2, row = index / 2
                    let x = CGFloat(12 + column * 178), y = CGFloat(52 + row * 236)
                    text(panel.0, x, y)
                    output.cgContext.interpolationQuality = .none
                    let scale = min(160 / panel.1.size.width, 190 / panel.1.size.height)
                    panel.1.draw(in: CGRect(x: x, y: y + 20,
                                            width: panel.1.size.width * scale,
                                            height: panel.1.size.height * scale))
                }
            }
    }

    private func sameMaterialMacroSamplerEvidence() throws -> UIImage {
        let water = try nativeGridImage(
            Array(repeating: Array(repeating: GroundType.water, count: 9), count: 9))
        let soil = try nativeGridImage(
            Array(repeating: Array(repeating: GroundType.soil, count: 9), count: 9))
        let format = UIGraphicsImageRendererFormat(); format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: 368, height: 800), format: format)
            .image { output in
                UIColor(red: 0.055, green: 0.085, blue: 0.084, alpha: 1).setFill()
                output.cgContext.fill(CGRect(x: 0, y: 0, width: 368, height: 800))
                func text(_ value: String, _ y: CGFloat, _ size: CGFloat = 11) {
                    (value as NSString).draw(at: .init(x: 14, y: y), withAttributes: [
                        .font: UIFont.monospacedSystemFont(ofSize: size, weight: .semibold),
                        .foregroundColor: UIColor(white: 0.9, alpha: 1),
                    ])
                }
                text("SAME-MATERIAL MACRO SAMPLER", 16, 17)
                text("WATER · 9×9 · ACTUAL MAPASSETRENDERER", 54)
                output.cgContext.interpolationQuality = .none
                water.draw(in: CGRect(x: 40, y: 80, width: 288, height: 294))
                text("SOIL · 9×9 · ACTUAL MAPASSETRENDERER", 412)
                soil.draw(in: CGRect(x: 40, y: 438, width: 288, height: 294))
                text("NO MATERIAL CONTACTS · NO ELEVATION WALLS", 760, 10)
            }
    }

    private func actualVisibilityEvidence() throws -> UIImage {
        let grounds: [[GroundType]] = (0..<5).map { y in (0..<5).map { x in
            x < 2 ? .stone : y < 3 ? .growth : .soil
        }}
        let full = try nativeGridImage(grounds, visibility: .full)
        let profile = WorldRules.visibilityProfile(illumination: 50)
        let brightness = WorldTileVisibilityPresentation.fringeOpacity(
            profile: profile, remembered: false)
        let fringe = try XCTUnwrap(Self.visibilityTreated(
            try nativeGridImage(grounds, visibility: .fringe), brightness: brightness))
        let remembered = try XCTUnwrap(Self.visibilityTreated(
            try nativeGridImage(grounds, visibility: .remembered), brightness: brightness))
        let hidden = try XCTUnwrap(Self.image(
            rgba: WorldTileVisibilityPresentation.opaqueFogPixels(), width: 16, height: 19,
            grayscale: false))
        for state in [TerrainProductionPack.Visibility.fringe, .remembered] {
            let request = try MapAssetTestSupport.productionRequest(
                ground: .stone, cardinalNeighbors: .init(
                    north: .ground(.growth), east: .same, south: .same, west: .unknown),
                visibility: state)
            XCTAssertFalse(TerrainProductionPack.materialBoundaryMask(request).contains { $0 > 0 })
        }
        let format = UIGraphicsImageRendererFormat(); format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: 368, height: 800), format: format)
            .image { output in
                UIColor(red: 0.055, green: 0.085, blue: 0.084, alpha: 1).setFill()
                output.cgContext.fill(CGRect(x: 0, y: 0, width: 368, height: 800))
                func text(_ value: String, _ x: CGFloat, _ y: CGFloat, _ size: CGFloat = 11) {
                    (value as NSString).draw(at: .init(x: x, y: y), withAttributes: [
                        .font: UIFont.monospacedSystemFont(ofSize: size, weight: .semibold),
                        .foregroundColor: UIColor(white: 0.9, alpha: 1),
                    ])
                }
                text("WORLD VISIBILITY OWNS DISCLOSURE", 12, 14, 16)
                let rows: [(String, UIImage)] = [
                    ("FULL · MATERIAL BOUNDARY PRESENT", full),
                    ("FRINGE · NO NEW MATERIAL BOUNDARY", fringe),
                    ("REMEMBERED · NO NEW MATERIAL BOUNDARY", remembered),
                    ("HIDDEN · WORLD OWNER MAKES NO TERRAIN REQUEST", hidden),
                ]
                for (index, row) in rows.enumerated() {
                    let y = CGFloat(54 + index * 178)
                    text(row.0, 14, y)
                    output.cgContext.interpolationQuality = .none
                    row.1.draw(in: CGRect(x: 104, y: y + 20, width: 160, height: 118))
                }
            }
    }

    private func nativeGridImage(_ grounds: [[GroundType]],
                                 visibility: TerrainProductionPack.Visibility = .full) throws
        -> UIImage {
        let descriptor = try identicalDescriptor()
        let height = grounds.count, width = try XCTUnwrap(grounds.first?.count)
        XCTAssertTrue(grounds.allSatisfy { $0.count == width })
        let format = UIGraphicsImageRendererFormat(); format.scale = 1
        return UIGraphicsImageRenderer(
            size: CGSize(width: width * 16, height: height * 16 + 3), format: format
        ).image { output in
            UIColor.black.setFill()
            output.cgContext.fill(CGRect(x: 0, y: 0, width: width * 16,
                                         height: height * 16 + 3))
            output.cgContext.interpolationQuality = .none
            for y in 0..<height { for x in 0..<width {
                let point = GridPoint(x: x, y: y), here = grounds[y][x]
                func neighbour(_ xx: Int, _ yy: Int) -> TerrainProductionPack.Neighbor {
                    guard (0..<width).contains(xx), (0..<height).contains(yy) else {
                        return .unknown
                    }
                    let other = grounds[yy][xx]
                    return other == here ? .same : .ground(.init(other))
                }
                let tile = Tile(ground: here, elevation: 0, isRevealed: true)
                let request = MapTileArtRequest(
                    tile: tile, point: point, mapSeed: 9041,
                    cardinalNeighbors: .init(
                        north: neighbour(x, y - 1), east: neighbour(x + 1, y),
                        south: neighbour(x, y + 1), west: neighbour(x - 1, y)),
                    edgeContourIDs: .init(
                        north: MapAssetContract.edgeContourID(mapSeed: 9041, point: point,
                                                              direction: .north),
                        east: MapAssetContract.edgeContourID(mapSeed: 9041, point: point,
                                                             direction: .east),
                        south: MapAssetContract.edgeContourID(mapSeed: 9041, point: point,
                                                              direction: .south),
                        west: MapAssetContract.edgeContourID(mapSeed: 9041, point: point,
                                                             direction: .west)),
                    contactShadeDepths: .init(north: 0, east: 0, south: 0, west: 0),
                    visibility: visibility, grade: .neutral, flora: nil,
                    worldGrade2Descriptor: descriptor)
                if let tileImage = MapAssetTestSupport.nativeRenderedImage(request) {
                    tileImage.draw(at: CGPoint(x: x * 16, y: y * 16))
                } else {
                    XCTFail("MapAssetRenderer failed at \(point)")
                }
            }}
        }
    }

    private func actualWallEvidence() throws -> UIImage {
        let descriptor = try identicalDescriptor()
        var images: [UIImage] = []
        for x in 0..<5 {
            var tile = Tile(ground: .rubble, elevation: 3, isRevealed: true)
            if x == 2 {
                tile.content = .wildDrop(resource: ResourceID(rawValue: "ore"), amount: 1)
            }
            let point = GridPoint(x: x, y: 1)
            let request = MapTileArtRequest(
                tile: tile, point: point, mapSeed: 9041,
                cardinalNeighbors: .init(
                    north: .unknown, east: x == 4 ? .unknown : .same,
                    south: .ground(.soil), west: x == 0 ? .unknown : .same),
                edgeContourIDs: .init(
                    north: MapAssetContract.edgeContourID(mapSeed: 9041, point: point,
                                                          direction: .north),
                    east: MapAssetContract.edgeContourID(mapSeed: 9041, point: point,
                                                         direction: .east),
                    south: MapAssetContract.edgeContourID(mapSeed: 9041, point: point,
                                                          direction: .south),
                    west: MapAssetContract.edgeContourID(mapSeed: 9041, point: point,
                                                         direction: .west)),
                contactShadeDepths: .init(north: 0, east: 0, south: 0, west: 0),
                southWallDepth: 3, wallWestContinuation: x > 0,
                wallEastContinuation: x < 4, visibility: .full,
                grade: .neutral, flora: nil, worldGrade2Descriptor: descriptor)
            images.append(try XCTUnwrap(MapAssetTestSupport.nativeRenderedImage(request)))
        }
        let format = UIGraphicsImageRendererFormat(); format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: 368, height: 800), format: format)
            .image { output in
                UIColor(red: 0.055, green: 0.085, blue: 0.084, alpha: 1).setFill()
                output.cgContext.fill(CGRect(x: 0, y: 0, width: 368, height: 800))
                func text(_ value: String, _ y: CGFloat, _ size: CGFloat = 13) {
                    (value as NSString).draw(at: .init(x: 14, y: y), withAttributes: [
                        .font: UIFont.monospacedSystemFont(ofSize: size, weight: .semibold),
                        .foregroundColor: UIColor(white: 0.9, alpha: 1),
                    ])
                }
                text("ACTUAL SOUTH-WALL LAYER ORDER", 18, 18)
                text("5 adjacent elevation-3 tops over disclosed elevation 0", 56, 10)
                output.cgContext.interpolationQuality = .none
                for (x, image) in images.enumerated() {
                    image.draw(in: CGRect(x: 24 + x * 64, y: 112, width: 64, height: 76))
                }
                UIColor(red: 0.95, green: 0.78, blue: 0.30, alpha: 1).setStroke()
                output.cgContext.setLineWidth(3)
                output.cgContext.stroke(CGRect(x: 24 + 2 * 64, y: 112,
                                               width: 64, height: 64))
                text("terrain boundary → authored wall → ore → selection", 224, 11)
                text("span/span/span with endpoint caps; no 16px wall seams", 254, 11)
                text("CONTACT SHADE REMAINS SUPPLEMENTAL", 310, 12)
            }
    }

    private static func image(rgba: [UInt8], width: Int = 16, height: Int = 16,
                              grayscale: Bool) -> UIImage? {
        var bytes = rgba
        if grayscale {
            for index in stride(from: 0, to: bytes.count, by: 4) {
                let value = UInt8((Int(bytes[index]) * 54 + Int(bytes[index + 1]) * 183
                                   + Int(bytes[index + 2]) * 19) / 256)
                bytes[index] = value; bytes[index + 1] = value; bytes[index + 2] = value
            }
        }
        guard let provider = CGDataProvider(data: Data(bytes) as CFData),
              let image = CGImage(width: width, height: height, bitsPerComponent: 8,
                                  bitsPerPixel: 32, bytesPerRow: width * 4,
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGBitmapInfo(rawValue:
                                    CGImageAlphaInfo.last.rawValue),
                                  provider: provider, decode: nil,
                                  shouldInterpolate: false, intent: .defaultIntent) else { return nil }
        return UIImage(cgImage: image)
    }

    private static func literalGrayscale(_ source: UIImage) -> UIImage? {
        guard let cgImage = source.cgImage else { return nil }
        let width = cgImage.width, height = cgImage.height
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        guard let context = CGContext(data: &bytes, width: width, height: height,
                                      bitsPerComponent: 8, bytesPerRow: width * 4,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return nil
        }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        for index in stride(from: 0, to: bytes.count, by: 4) {
            let value = UInt8((Int(bytes[index]) * 54 + Int(bytes[index + 1]) * 183
                               + Int(bytes[index + 2]) * 19) / 256)
            bytes[index] = value; bytes[index + 1] = value; bytes[index + 2] = value
        }
        guard let result = context.makeImage() else { return nil }
        return UIImage(cgImage: result)
    }

    private static func visibilityTreated(_ source: UIImage, brightness: Double) -> UIImage? {
        let format = UIGraphicsImageRendererFormat(); format.scale = 1
        return UIGraphicsImageRenderer(size: source.size, format: format).image { output in
            source.draw(at: .zero)
            output.cgContext.setBlendMode(.multiply)
            UIColor(white: brightness, alpha: 1).setFill()
            output.cgContext.fill(CGRect(origin: .zero, size: source.size))
        }
    }

    private func identicalDescriptor() throws -> WorldGrade2V1.Descriptor {
        let green = WorldGrade2V1.ResolvedColor(
            srgb: [62, 122, 86], resolutionVersion: "resolved-color-1.0.0",
            provenance: "bindRandom")
        return try WorldGrade2V1.resolve(.init(
            material: .init(identity: "mixedMineral", paletteFamilyID: "paleNeutral",
                            transform: .init(hue: 0, saturation: 1, value: 0)),
            atmosphere: .init(medium: "none", density: 0, paletteFamilyID: "clear"),
            flora: .init(coveragePercent: 40, paletteRichness: 50,
                         cast: [.init(speciesID: "flora-a", formID: 0, stature: 35,
                                      resolvedColor: green)]),
            resolvedColors: .init()))
    }

    private func sha256(_ bytes: [UInt8]) -> String {
        SHA256.hash(data: Data(bytes)).map { String(format: "%02x", $0) }.joined()
    }
}
