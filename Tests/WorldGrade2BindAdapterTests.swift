import Foundation
import XCTest
@testable import Bookbinder

final class WorldGrade2BindAdapterTests: XCTestCase {
    private let seed: UInt64 = 4_242

    private var fixtureResolver: WorldGrade2BindAdapter.OpenColorResolver {
        { scope, sigil, mapSeed in
            let salt = UInt64(WorldVisualScope.allCases.firstIndex(of: scope) ?? 0) * 37
            let value = mapSeed &+ sigil.id.rawValue &+ salt
            return .init(srgb: [Int(value % 256), Int(value / 3 % 256), Int(value / 7 % 256)],
                         resolutionVersion: "resolved-color-1.0.0",
                         provenance: "bindRandom")
        }
    }

    private func sigil(_ id: UInt64, _ source: PressureSourceID, _ target: PressureTargetID,
                       intensity: Intensity = .moderate, scale: Int = 0, count: Int = 0,
                       negated: Set<PressureTargetID> = []) -> Sigil {
        Sigil(id: InstanceID(rawValue: id), source: source, target: target,
              intensity: intensity, negatedTargets: negated, scale: scale, count: count)
    }

    private func book(_ sigils: [Sigil]) -> BoundBook {
        BoundBook(written: [], composition: sigils, essencePaid: 0)
    }

    private func map(floraID: InstanceID? = nil) -> WorldMap {
        WorldMap(width: 2, height: 2,
                 tiles: [Tile(ground: .soil, flora: floraID), Tile(ground: .stone),
                         Tile(ground: .chasm), Tile(ground: .growth, flora: floraID)],
                 entry: GridPoint(x: 0, y: 0))
    }

    private func receipt(_ sigils: [Sigil], flora: [Flora] = [],
                         explicit: [InstanceID: WorldGrade2V1.ResolvedColor] = [:]) throws
        -> WorldVisualReceipt {
        let verified = try explicit.mapValues { color in
            try WorldGrade2BindAdapter.fixtureVerifiedExplicitInk(
                recipeCanonicalSHA256: String(repeating: "a", count: 64),
                conversionVersion: "ink-cmyk-1.0.0", regeneratedColor: color)
        }
        return try WorldGrade2BindAdapter.makeReceipt(book: book(sigils), mapSeed: seed,
                                               map: map(floraID: flora.first?.id), flora: flora,
                                               explicitInkResolver: { verified[$0.id] },
                                               openColorResolver: fixtureResolver)
    }

    func testEqualFactsProduceByteIdenticalValidatedReceipts() throws {
        let marks = [sigil(10, "granite", "substrate"), sigil(11, "sun", "illumination")]
        let first = try receipt(marks), second = try receipt(marks)
        XCTAssertEqual(first, second)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        XCTAssertEqual(try encoder.encode(first), try encoder.encode(second))
        XCTAssertNoThrow(try JSONDecoder().decode(WorldVisualReceipt.self,
                                                   from: JSONEncoder().encode(first)))
    }

    func testFrozenOpenColorStreamsUseExactlyFourRawDrawsAndPublishedBytes() throws {
        let vectors: [(WorldVisualScope, Int, Int, Int, [Int])] = [
            (.material, 127, 38, 61, [118, 193, 127]),
            (.atmosphere, 321, 32, 49, [165, 85, 137]),
            (.emitter, 4, 68, 80, [239, 174, 169]),
            (.floraTendency, 257, 77, 48, [82, 28, 217]),
        ]
        for (scope, hue, saturation, lightness, bytes) in vectors {
            let sample = try WorldGrade2BindAdapter.openColorSample(
                scope: scope, selectedSigilID: InstanceID(rawValue: 10), mapSeed: seed)
            XCTAssertEqual(sample.hue, hue, scope.rawValue)
            XCTAssertEqual(sample.saturation, saturation, scope.rawValue)
            XCTAssertEqual(sample.lightness, lightness, scope.rawValue)
            XCTAssertEqual(sample.rawDrawCount, 4, scope.rawValue)
            XCTAssertEqual(sample.color.srgb, bytes, scope.rawValue)
            XCTAssertEqual(sample.color.provenance, "bindRandom")
        }
    }

    func testMapSeedOneSigilOneCrossLanguageGoldenVectors() throws {
        let vectors: [(WorldVisualScope, UInt64, Int, Int, Int, [Int])] = [
            (.material, 13_687_280_610_363_741_021, 237, 72, 39, [28, 35, 171]),
            (.atmosphere, 13_593_753_515_414_985_611, 105, 9, 55, [135, 151, 130]),
            (.emitter, 14_092_530_940_132_275_359, 218, 54, 81, [180, 200, 233]),
            (.floraTendency, 16_000_765_205_411_828_928, 314, 8, 43, [118, 101, 114]),
        ]
        for (scope, derivedSeed, hue, saturation, lightness, srgb) in vectors {
            let sample = try WorldGrade2BindAdapter.openColorSample(
                scope: scope, selectedSigilID: InstanceID(rawValue: 1), mapSeed: 1)
            XCTAssertEqual(sample.derivedSeed, derivedSeed, scope.rawValue)
            XCTAssertEqual([sample.hue, sample.saturation, sample.lightness],
                           [hue, saturation, lightness], scope.rawValue)
            XCTAssertEqual(sample.color.srgb, srgb, scope.rawValue)
            XCTAssertEqual(sample.rawDrawCount, 4, scope.rawValue)
        }
    }

    func testDefaultReceiptUsesFrozenLiveResolver() throws {
        let marks = [sigil(10, "granite", "substrate"), sigil(11, "sun", "illumination")]
        let live = try WorldGrade2BindAdapter.makeReceipt(
            book: book(marks), mapSeed: seed, map: map(), flora: [])
        let injected = try WorldGrade2BindAdapter.makeReceipt(
            book: book(marks), mapSeed: seed, map: map(), flora: [],
            explicitInkResolver: { _ in nil },
            openColorResolver: { scope, sigil, mapSeed in
                try WorldGrade2BindAdapter.openColor(scope: scope,
                                                     selectedSigilID: sigil.id,
                                                     mapSeed: mapSeed)
            })
        XCTAssertEqual(live, injected)
    }

    func testOpenColorCorpusRetainsAllBandsAndBroadHueCoverage() throws {
        var achromatic = 0, muted = 0, vivid = 0
        var hueBuckets = Set<Int>()
        for mapSeed in UInt64(0)..<UInt64(1_000) {
            let sample = try WorldGrade2BindAdapter.openColorSample(
                scope: .material, selectedSigilID: InstanceID(rawValue: 77), mapSeed: mapSeed)
            hueBuckets.insert(sample.hue / 30)
            if sample.saturation <= 12 { achromatic += 1 }
            else if sample.saturation <= 55 { muted += 1 }
            else { vivid += 1 }
        }
        XCTAssertGreaterThan(achromatic, 120)
        XCTAssertGreaterThan(muted, 350)
        XCTAssertGreaterThan(vivid, 200)
        XCTAssertEqual(hueBuckets.count, 12)
    }

    func testScopeSelectionUsesAmplitudeThenStableIDAndExplicitOutranksOpen() throws {
        let low = sigil(20, "granite", "relief", intensity: .faint)
        let high = sigil(30, "granite", "relief", intensity: .great)
        XCTAssertEqual(try receipt([low, high]).selectedSourceByScope[.material], high.id)

        let authored = WorldGrade2V1.ResolvedColor(
            srgb: [0, 0, 0], resolutionVersion: "resolved-color-1.0.0",
            provenance: "authoredMix")
        let explicit = try receipt([low, high], explicit: [low.id: authored])
        XCTAssertEqual(explicit.selectedSourceByScope[.material], low.id)
        XCTAssertEqual(explicit.request.resolvedColors.material?.srgb, [0, 0, 0])
    }

    func testTiedDifferentExplicitColorsRejectBeforeProducingReceipt() throws {
        let a = sigil(1, "sun", "illumination"), b = sigil(2, "sun", "illumination")
        let red = WorldGrade2V1.ResolvedColor(srgb: [255, 0, 0],
            resolutionVersion: "resolved-color-1.0.0", provenance: "authoredMix")
        let blue = WorldGrade2V1.ResolvedColor(srgb: [0, 0, 255],
            resolutionVersion: "resolved-color-1.0.0", provenance: "authoredMix")
        XCTAssertThrowsError(try receipt([a, b], explicit: [a.id: red, b.id: blue])) {
            XCTAssertEqual($0 as? WorldGrade2BindAdapter.Error,
                           .ambiguousExplicitColor(.emitter))
        }
    }

    func testNoFaintModerateGreatSmokeProduceNoneAndOrderedDensity() throws {
        let levels: [Intensity] = [.absent, .faint, .moderate, .great]
        let atmospheres = try levels.map {
            try receipt([sigil(1, "smoke", "illumination", intensity: $0)]).request.atmosphere
        }
        XCTAssertEqual(atmospheres[0], .init(medium: "none", density: 0,
                                             paletteFamilyID: "clear"))
        XCTAssertEqual(atmospheres.dropFirst().map(\.medium), ["smoke", "smoke", "smoke"])
        XCTAssertEqual(atmospheres.dropFirst().map(\.density),
                       atmospheres.dropFirst().map(\.density).sorted())
    }

    func testAtmosphereReceiptResolvesAuthoredCausesWithoutGenerationRNG() throws {
        let marks = [
            sigil(40, "smoke", "illumination", intensity: .moderate),
            sigil(10, "ash", "substrate", intensity: .moderate),
            sigil(30, "rain", "hydrology", intensity: .moderate),
            sigil(20, "snow", "hydrology", intensity: .great),
        ]
        let visual = try receipt(marks)
        let first = WorldGrade2BindAdapter.makeAtmospherePresentationReceipt(
            book: book(marks), mapSeed: seed, visualReceipt: visual)
        let second = WorldGrade2BindAdapter.makeAtmospherePresentationReceipt(
            book: book(marks), mapSeed: seed, visualReceipt: visual)

        XCTAssertEqual(first, second)
        XCTAssertTrue(first.validates())
        XCTAssertEqual(first.suspendedMedium, .airborneAsh)
        XCTAssertEqual(first.suspendedSourceIDs, [InstanceID(rawValue: 10)])
        XCTAssertEqual(first.precipitation, .mixedRainSnow)
        XCTAssertEqual(first.precipitationSourceIDs,
                       [InstanceID(rawValue: 20), InstanceID(rawValue: 30)])
        XCTAssertEqual(first.schemaVersion, "world-atmosphere-presentation-1")
        XCTAssertEqual(first.resolverVersion, "world-atmosphere-resolver-1.0.0")
    }

    func testAtmosphereReceiptDoesNotInventWeatherFromUnwrittenReadings() throws {
        let marks = [sigil(1, "wind", "atmosphere", intensity: .great)]
        let visual = try receipt(marks)
        let result = WorldGrade2BindAdapter.makeAtmospherePresentationReceipt(
            book: book(marks), mapSeed: seed, visualReceipt: visual)
        XCTAssertEqual(result.suspendedMedium, .none)
        XCTAssertEqual(result.suspendedDensity, 0)
        XCTAssertEqual(result.precipitation, .none)
        XCTAssertEqual(result.precipitationDensity, 0)
        XCTAssertEqual(result.motionBand, .strong)
    }

    func testAtmosphereDensityBandsUseExactIntegerBoundaries() {
        let cases = [(0, false, "none"), (10, true, "trace"), (24, true, "trace"),
                     (25, true, "light"), (49, true, "light"),
                     (50, true, "heavy"), (74, true, "heavy"),
                     (75, true, "dense"), (100, true, "dense")]
        for (density, present, expected) in cases {
            XCTAssertEqual(WorldAtmospherePresentationReceiptV1.densityBand(
                density, present: present), expected, "density \(density)")
        }
    }

    func testGraniteAndSunRemainInTheirOwnColorScopes() throws {
        let result = try receipt([sigil(1, "granite", "substrate"),
                                  sigil(2, "sun", "illumination")])
        XCTAssertEqual(result.request.material.identity, "granite")
        XCTAssertNotNil(result.request.resolvedColors.material)
        XCTAssertNotNil(result.request.resolvedColors.emitter)
        XCTAssertNil(result.request.resolvedColors.atmosphere)
        XCTAssertEqual(result.selectedSourceByScope[.material], InstanceID(rawValue: 1))
        XCTAssertEqual(result.selectedSourceByScope[.emitter], InstanceID(rawValue: 2))
    }

    func testFloraIDsFormsCoverageRichnessAndColorsAreFrozen() throws {
        var woody = FloraTraits()
        woody.stature = 73
        woody.tissue.woody = 80; woody.tissue.fleshy = 10; woody.tissue.fibrous = 10
        woody.coloration.cyan = 80; woody.coloration.magenta = 10
        woody.coloration.yellow = 10; woody.coloration.depth = 60
        let plant = Flora(id: InstanceID(rawValue: 7), traits: woody, worldSeed: seed)
        let result = try receipt([sigil(4, "bloom", "vitality")], flora: [plant])
        XCTAssertEqual(result.request.flora.coveragePercent, 66.667)
        XCTAssertEqual(result.request.flora.paletteRichness, 70)
        XCTAssertEqual(result.request.flora.cast.map(\.speciesID), ["flora-7"])
        XCTAssertEqual(result.request.flora.cast.first?.formID, 0)
        XCTAssertEqual(result.request.flora.cast.first?.stature, 73)
        XCTAssertEqual(result.request.flora.cast.first?.resolvedColor.srgb.count, 3)
        XCTAssertNotNil(result.request.resolvedColors.floraTendency)
    }

    func testEmptyFloraCastAndZeroCoverageValidate() throws {
        let result = try receipt([sigil(1, "granite", "substrate")])
        XCTAssertEqual(result.request.flora.coveragePercent, 0)
        XCTAssertEqual(result.request.flora.paletteRichness, 0)
        XCTAssertTrue(result.request.flora.cast.isEmpty)
    }

    func testGeneratedButUnplacedFloraIsExcludedFromRealizedCast() throws {
        let plant = Flora(id: InstanceID(rawValue: 90), traits: FloraTraits(), worldSeed: seed)
        let result = try WorldGrade2BindAdapter.makeReceipt(
            book: book([sigil(1, "granite", "substrate")]), mapSeed: seed,
            map: map(floraID: nil), flora: [plant])
        XCTAssertEqual(result.request.flora.coveragePercent, 0)
        XCTAssertEqual(result.request.flora.paletteRichness, 0)
        XCTAssertTrue(result.request.flora.cast.isEmpty)
    }

    func testFloraPresentOnlyOnChasmIsNotARealizedSpecies() throws {
        let plant = Flora(id: InstanceID(rawValue: 91), traits: FloraTraits(), worldSeed: seed)
        let chasmOnly = WorldMap(
            width: 2, height: 1,
            tiles: [Tile(ground: .soil), Tile(ground: .chasm, flora: plant.id)],
            entry: GridPoint(x: 0, y: 0))
        let result = try WorldGrade2BindAdapter.makeReceipt(
            book: book([sigil(1, "granite", "substrate")]), mapSeed: seed,
            map: chasmOnly, flora: [plant])
        XCTAssertTrue(result.request.flora.cast.isEmpty)
        XCTAssertEqual(result.request.flora.coveragePercent, 0)
        XCTAssertEqual(result.request.flora.paletteRichness, 0)
    }

    func testFloraOnValidAndChasmTilesCountsOnlyTheValidTile() throws {
        let plant = Flora(id: InstanceID(rawValue: 92), traits: FloraTraits(), worldSeed: seed)
        let mixed = WorldMap(
            width: 3, height: 1,
            tiles: [Tile(ground: .soil, flora: plant.id), Tile(ground: .stone),
                    Tile(ground: .chasm, flora: plant.id)],
            entry: GridPoint(x: 0, y: 0))
        let result = try WorldGrade2BindAdapter.makeReceipt(
            book: book([sigil(1, "granite", "substrate")]), mapSeed: seed,
            map: mixed, flora: [plant])
        XCTAssertEqual(result.request.flora.cast.map(\.speciesID), ["flora-92"])
        XCTAssertEqual(result.request.flora.coveragePercent, 50)
    }

    func testPartiallyRealizedCastIncludesOnlyPlacedSpeciesWithoutMutatingSource() throws {
        let placed = Flora(id: InstanceID(rawValue: 4), traits: FloraTraits(), worldSeed: seed)
        let absent = Flora(id: InstanceID(rawValue: 8), traits: FloraTraits(), worldSeed: seed)
        let source = [placed, absent]
        let result = try WorldGrade2BindAdapter.makeReceipt(
            book: book([sigil(1, "granite", "substrate")]), mapSeed: seed,
            map: map(floraID: placed.id), flora: source)
        XCTAssertEqual(result.request.flora.cast.map(\.speciesID), ["flora-4"])
        XCTAssertEqual(source.map(\.id), [placed.id, absent.id])
    }

    func testUnsupportedOrMalformedExplicitColorRejects() throws {
        let unsupported = sigil(1, "rain", "hydrology")
        let color = WorldGrade2V1.ResolvedColor(srgb: [1, 2, 3],
            resolutionVersion: "resolved-color-1.0.0", provenance: "authoredMix")
        XCTAssertThrowsError(try receipt([unsupported], explicit: [unsupported.id: color]))
        var malformed = color; malformed.provenance = "bindRandom"
        XCTAssertThrowsError(try receipt([sigil(2, "sun", "illumination")],
                                         explicit: [InstanceID(rawValue: 2): malformed]))
    }

    func testReceiptRejectsTamperedHashAndDescriptor() throws {
        let valid = try receipt([sigil(1, "granite", "substrate")])
        XCTAssertThrowsError(try WorldVisualReceipt(
            request: valid.request, descriptor: valid.descriptor,
            descriptorHash: String(repeating: "0", count: 64),
            selectedSourceByScope: valid.selectedSourceByScope))
        var future = valid.descriptor
        future.versions.rendererVersion = "future"
        XCTAssertThrowsError(try WorldVisualReceipt(
            request: valid.request, descriptor: future,
            descriptorHash: future.canonicalDescriptorSHA256,
            selectedSourceByScope: valid.selectedSourceByScope))
    }

    func testCanonicalReceiptHashIgnoresDictionaryInsertionOrderAndRejectsTampering() throws {
        let valid = try receipt([sigil(1, "granite", "substrate"),
                                 sigil(2, "sun", "illumination")])
        var reversed: [WorldVisualScope: InstanceID] = [:]
        reversed[.emitter] = try XCTUnwrap(valid.selectedSourceByScope[.emitter])
        reversed[.material] = try XCTUnwrap(valid.selectedSourceByScope[.material])
        let rebuilt = try WorldVisualReceipt(
            request: valid.request, descriptor: valid.descriptor,
            descriptorHash: valid.descriptorHash, selectedSourceByScope: reversed)
        XCTAssertEqual(rebuilt.canonicalReceiptSHA256, valid.canonicalReceiptSHA256)

        var object = try XCTUnwrap(JSONSerialization.jsonObject(
            with: JSONEncoder().encode(valid)) as? [String: Any])
        object["canonicalReceiptSHA256"] = String(repeating: "0", count: 64)
        XCTAssertThrowsError(try JSONDecoder().decode(
            WorldVisualReceipt.self, from: JSONSerialization.data(withJSONObject: object)))
    }
}
