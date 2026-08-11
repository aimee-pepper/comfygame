import Foundation

enum WorldGrade2BindAdapter {
    enum Error: Swift.Error, Equatable {
        case invalidReceipt
        case invalidExplicitColor
        case unsupportedExplicitColor
        case ambiguousExplicitColor(WorldVisualScope)
        case nonFiniteDerivation
        case missingOpenColorAuthority(WorldVisualScope)
    }

    /// Injectable seam for deterministic fixtures. Production uses the frozen salts, derivation
    /// chain, raw-draw order and modulo mapping implemented by `openColor` below.
    typealias OpenColorResolver = (_ scope: WorldVisualScope, _ sigil: Sigil,
                                   _ mapSeed: UInt64) throws -> WorldGrade2V1.ResolvedColor
    typealias ExplicitInkResolver = (_ sigil: Sigil) throws -> VerifiedExplicitInkColor?

    struct VerifiedExplicitInkColor: Equatable {
        let recipeCanonicalSHA256: String
        let conversionVersion: String
        fileprivate let regeneratedColor: WorldGrade2V1.ResolvedColor

        fileprivate init(recipeCanonicalSHA256: String, conversionVersion: String,
                         regeneratedColor: WorldGrade2V1.ResolvedColor) {
            self.recipeCanonicalSHA256 = recipeCanonicalSHA256
            self.conversionVersion = conversionVersion
            self.regeneratedColor = regeneratedColor
        }
    }

#if DEBUG
    /// Test seam only. Production has no explicit-color constructor until the persisted InkRecipe
    /// model and its registered conversion resolver land.
    static func fixtureVerifiedExplicitInk(recipeCanonicalSHA256: String,
                                            conversionVersion: String,
                                            regeneratedColor: WorldGrade2V1.ResolvedColor) throws
        -> VerifiedExplicitInkColor {
        guard recipeCanonicalSHA256.range(of: "^[0-9a-f]{64}$", options: .regularExpression) != nil,
              !conversionVersion.isEmpty else { throw Error.invalidExplicitColor }
        try validateExplicit(regeneratedColor)
        return VerifiedExplicitInkColor(recipeCanonicalSHA256: recipeCanonicalSHA256,
                                        conversionVersion: conversionVersion,
                                        regeneratedColor: regeneratedColor)
    }
#endif

    struct OpenColorSample: Equatable {
        var derivedSeed: UInt64
        var hue: Int
        var saturation: Int
        var lightness: Int
        var rawDrawCount: Int
        var color: WorldGrade2V1.ResolvedColor
    }

    private struct Candidate {
        var scope: WorldVisualScope
        var sigil: Sigil
        var amplitude: Double
        var explicitColor: WorldGrade2V1.ResolvedColor?
    }

    static func makeReceipt(book: BoundBook, mapSeed: UInt64, map: WorldMap, flora: [Flora],
                            explicitInkResolver: ExplicitInkResolver = { _ in nil }) throws
        -> WorldVisualReceipt {
        try makeReceipt(book: book, mapSeed: mapSeed, map: map, flora: flora,
                        explicitInkResolver: explicitInkResolver,
                        openColorResolver: { scope, sigil, seed in
                            try openColor(scope: scope, selectedSigilID: sigil.id,
                                          mapSeed: seed)
                        })
    }

    static func openColor(scope: WorldVisualScope, selectedSigilID: InstanceID,
                          mapSeed: UInt64) throws -> WorldGrade2V1.ResolvedColor {
        try openColorSample(scope: scope, selectedSigilID: selectedSigilID,
                            mapSeed: mapSeed).color
    }

    static func openColorSample(scope: WorldVisualScope, selectedSigilID: InstanceID,
                                mapSeed: UInt64) throws -> OpenColorSample {
        let scopeSalt: UInt64
        let lightnessBounds: ClosedRange<Int>
        switch scope {
        case .material:
            scopeSalt = 0x4D41_5445_5249_414C; lightnessBounds = 35...65
        case .atmosphere:
            scopeSalt = 0x4154_4D4F_5350_4852; lightnessBounds = 45...75
        case .emitter:
            scopeSalt = 0x454D_4954_5445_5221; lightnessBounds = 65...85
        case .floraTendency:
            scopeSalt = 0x464C_4F52_4154_4E44; lightnessBounds = 35...65
        }
        let scoped = SeededRNG(seed: mapSeed).derived(scopeSalt)
        var colorRNG = scoped.derived(selectedSigilID.rawValue)
        let hue = Int(colorRNG.next() % 360)
        let band = Int(colorRNG.next() % 100)
        let saturationBounds: ClosedRange<Int> = band < 20 ? 0...12
            : (band < 70 ? 25...55 : 60...85)
        let saturation = saturationBounds.lowerBound
            + Int(colorRNG.next() % UInt64(saturationBounds.count))
        let lightness = lightnessBounds.lowerBound
            + Int(colorRNG.next() % UInt64(lightnessBounds.count))
        let srgb = try WorldGrade2V1.resolvedSRGB(
            hue: Double(hue), saturationPercent: Double(saturation),
            lightnessPercent: Double(lightness))
        return OpenColorSample(
            derivedSeed: colorRNG.seed, hue: hue, saturation: saturation, lightness: lightness,
            rawDrawCount: colorRNG.drawCount,
            color: .init(srgb: srgb, resolutionVersion: "resolved-color-1.0.0",
                         provenance: "bindRandom"))
    }

    static func makeReceipt(book: BoundBook, mapSeed: UInt64, map: WorldMap, flora: [Flora],
                            explicitInkResolver: ExplicitInkResolver = { _ in nil },
                            openColorResolver: OpenColorResolver) throws -> WorldVisualReceipt {
        let authored = BookRules.sigils(for: book)
        let sigils = authored + PressureRules.rollUnwritten(after: authored, seed: mapSeed)
        let readings = BookRules.readings(for: book, seed: mapSeed)
        var explicitColorsBySigilID: [InstanceID: WorldGrade2V1.ResolvedColor] = [:]
        for sigil in sigils {
            if let verified = try explicitInkResolver(sigil) {
                try validateExplicit(verified.regeneratedColor)
                explicitColorsBySigilID[sigil.id] = verified.regeneratedColor
            }
        }
        let candidates = try candidates(in: sigils, explicit: explicitColorsBySigilID)
        guard Set(explicitColorsBySigilID.keys).isSubset(of: Set(candidates.map(\.sigil.id))) else {
            throw Error.unsupportedExplicitColor
        }
        var selected: [WorldVisualScope: Candidate] = [:]
        for scope in WorldVisualScope.allCases {
            selected[scope] = try select(scope, from: candidates)
        }
        var colors: [WorldVisualScope: WorldGrade2V1.ResolvedColor] = [:]
        for (scope, candidate) in selected {
            let color = try candidate.explicitColor
                ?? openColorResolver(scope, candidate.sigil, mapSeed)
            try validateResolved(color, expectedProvenance: candidate.explicitColor == nil
                                 ? "bindRandom" : "authoredMix")
            colors[scope] = color
        }

        let material = try material(readings: readings,
                                    graniteSelected: selected[.material] != nil)
        let atmosphere = try atmosphere(sigils: sigils,
                                        smokeSelected: selected[.atmosphere] != nil)
        let floraRequest = try floraRequest(map: map, flora: flora,
                                           tendency: colors[.floraTendency])
        let request = WorldGrade2V1.Request(
            material: material,
            atmosphere: atmosphere,
            flora: floraRequest,
            resolvedColors: .init(
                material: selected[.material] == nil ? nil : colors[.material],
                atmosphere: selected[.atmosphere] == nil ? nil : colors[.atmosphere],
                emitter: selected[.emitter] == nil ? nil : colors[.emitter],
                floraTendency: selected[.floraTendency] == nil ? nil : colors[.floraTendency]))
        let descriptor = try WorldGrade2V1.resolve(request)
        return try WorldVisualReceipt(
            request: request, descriptor: descriptor,
            descriptorHash: descriptor.canonicalDescriptorSHA256,
            selectedSourceByScope: selected.mapValues(\.sigil.id))
    }

    private static func candidates(in sigils: [Sigil],
                                   explicit: [InstanceID: WorldGrade2V1.ResolvedColor]) throws -> [Candidate] {
        let ownership: [(WorldVisualScope, PressureSourceID, PressureTargetID)] = [
            (.material, "granite", "substrate"), (.atmosphere, "smoke", "atmosphere"),
            (.emitter, "sun", "illumination"), (.floraTendency, "bloom", "vitality")
        ]
        return try sigils.compactMap { sigil in
            guard let owned = ownership.first(where: { $0.1 == sigil.source }),
                  !sigil.negatedTargets.contains(owned.2),
                  let target = ContentCatalog.shared.pressureTarget(owned.2),
                  let contribution = ContentCatalog.shared.pressureSource(sigil.source)?
                    .contribution(to: owned.2), contribution.peak != 0 || contribution.floor != 0
            else { return nil }
            let amplitude = sigil.intensity.multiplier
                * PressureRules.scaleMultiplier(sigil, target: target)
                * PressureRules.countMultiplier(sigil)
            guard amplitude.isFinite else { throw Error.nonFiniteDerivation }
            guard amplitude > 0 else { return nil }
            return Candidate(scope: owned.0, sigil: sigil, amplitude: amplitude,
                             explicitColor: explicit[sigil.id])
        }
    }

    private static func select(_ scope: WorldVisualScope,
                               from candidates: [Candidate]) throws -> Candidate? {
        var scoped = candidates.filter { $0.scope == scope }
        if scoped.contains(where: { $0.explicitColor != nil }) {
            scoped = scoped.filter { $0.explicitColor != nil }
        }
        guard let maximum = scoped.map(\.amplitude).max() else { return nil }
        let tied = scoped.filter { abs($0.amplitude - maximum) < 0.000_000_001 }
        let authored = Set(tied.compactMap { candidate in
            candidate.explicitColor?.srgb.map(String.init).joined(separator: ",")
        })
        if authored.count > 1 { throw Error.ambiguousExplicitColor(scope) }
        return tied.min { $0.sigil.id.rawValue < $1.sigil.id.rawValue }
    }

    private static func material(readings: PressureReadings,
                                 graniteSelected: Bool) throws -> WorldGrade2V1.Material {
        let substrate = readings["substrate"], thermal = readings["thermal"]
        let hard = substrate.share(of: "hard"), ductile = substrate.share(of: "ductile")
        let volatile = substrate.share(of: "volatile")
        let identity = graniteSelected ? "granite"
            : (hard + volatile >= 0.55 ? "mixedMineral" : "mixedEarth")
        let thermalCentre = (thermal.peak + thermal.floor) / 2
        let palette: String
        if identity == "granite" { palette = "paleNeutral" }
        else if identity == "mixedMineral" {
            palette = thermalCentre <= 40 ? "coolMineral"
                : (thermalCentre >= 60 ? "warmMineral" : "paleNeutral")
        } else { palette = thermalCentre < 45 ? "coolEarth" : "warmEarth" }
        let t = (thermalCentre - 50) / 50
        let w = (readings["hydrology"].availableMagnitude - 50) / 50
        let hue = clamp((24 * t + 10 * (volatile - ductile)).rounded(), -32, 32)
        let saturation = clamp(1 + 0.18 * ((substrate.peak - 50) / 50)
                               + 0.12 * volatile - 0.08 * max(w, 0), 0.8, 1.3)
        let value = clamp((-8 * w + 4 * (ductile - hard)).rounded(), -12, 12)
        guard [hue, saturation, value].allSatisfy(\.isFinite) else {
            throw Error.nonFiniteDerivation
        }
        return .init(identity: identity, paletteFamilyID: palette,
                     transform: .init(hue: hue, saturation: saturation, value: value))
    }

    private static func atmosphere(sigils: [Sigil], smokeSelected: Bool) throws
        -> WorldGrade2V1.Atmosphere {
        guard smokeSelected else { return .init(medium: "none", density: 0, paletteFamilyID: "clear") }
        guard let target = ContentCatalog.shared.pressureTarget("atmosphere") else {
            throw Error.nonFiniteDerivation
        }
        let contributions = sigils.compactMap { sigil -> Double? in
            guard sigil.source == "smoke",
                  !sigil.negatedTargets.contains("atmosphere"), sigil.intensity != .absent else {
                return nil
            }
            return 18 * sigil.intensity.multiplier
                * PressureRules.scaleMultiplier(sigil, target: target)
                * PressureRules.countMultiplier(sigil)
        }
        let combined = PressureRules.diminished(contributions)
        guard combined.isFinite else { throw Error.nonFiniteDerivation }
        let density = clamp((combined / 50 * 100).rounded(), 10, 100)
        return .init(medium: "smoke", density: density, paletteFamilyID: "neutralSmoke")
    }

    private static func floraRequest(map: WorldMap, flora: [Flora],
                                     tendency: WorldGrade2V1.ResolvedColor?) throws
        -> WorldGrade2V1.FloraRequest {
        let placedIDs = Set(map.tiles.compactMap { tile in
            tile.ground == .chasm ? nil : tile.flora
        })
        let realizedFlora = flora.filter { placedIDs.contains($0.id) }
        guard realizedFlora.count <= 4 else { throw Error.nonFiniteDerivation }
        let ids = Set(realizedFlora.map(\.id))
        let denominator = map.tiles.count { $0.ground != .chasm }
        let numerator = map.tiles.count { tile in
            tile.ground != .chasm && tile.flora.map(ids.contains) == true
        }
        let coverage = denominator == 0 ? 0
            : rounded3(Double(numerator) / Double(denominator) * 100)
        var richness: [Double] = []
        let cast = try realizedFlora.sorted { $0.id.rawValue < $1.id.rawValue }.map { plant in
            let cmy = normalizedCMY(plant.traits.coloration)
            richness.append((cmy.max() ?? 0) - (cmy.min() ?? 0))
            let form: Int = if plant.traits.metabolism == .fungal { 3 } else {
                switch plant.traits.tissue.dominant {
                case .woody: 0
                case .fleshy: 1
                case .fibrous: 2
                }
            }
            var rgb = try speciesRGB(cmy: cmy, depth: plant.traits.coloration.depth)
            if let tendency {
                rgb = zip(rgb, tendency.srgb).map {
                    Int((Double($0.0) * 0.8 + Double($0.1) * 0.2).rounded())
                }
            }
            return WorldGrade2V1.FloraSpecies(
                speciesID: "flora-\(plant.id.rawValue)", formID: form,
                stature: clamp(plant.traits.stature, 0, 100),
                resolvedColor: .init(srgb: rgb, resolutionVersion: "resolved-color-1.0.0",
                                     provenance: tendency?.provenance == "authoredMix"
                                        ? "authoredMix" : "bindRandom"))
        }
        let paletteRichness = richness.isEmpty ? 0 : rounded3(richness.reduce(0, +)
                                                               / Double(richness.count))
        return .init(coveragePercent: coverage, paletteRichness: paletteRichness, cast: cast)
    }

    private static func normalizedCMY(_ color: Coloration) -> [Double] {
        let raw = [color.cyan, color.magenta, color.yellow].map { clamp($0, 0, 100) }
        let total = raw.reduce(0, +)
        return total > 0 ? raw.map { $0 / total * 100 } : [0, 0, 0]
    }

    private static func speciesRGB(cmy: [Double], depth: Double) throws -> [Int] {
        let total = cmy.reduce(0, +)
        guard total > 0 else {
            let channel = Int((0.43 * 255).rounded())
            return [channel, channel, channel]
        }
        let hue = ((cmy[0] / total) * 185 + (cmy[1] / total) * 322
                   + (cmy[2] / total) * 74).truncatingRemainder(dividingBy: 360)
        return try WorldGrade2V1.resolvedSRGB(
            hue: hue,
            saturationPercent: clamp(28 + clamp(depth, 0, 100) * 0.48, 0, 92),
            lightnessPercent: 43)
    }

    private static func validateExplicit(_ color: WorldGrade2V1.ResolvedColor) throws {
        try validateResolved(color, expectedProvenance: "authoredMix")
    }

    private static func validateResolved(_ color: WorldGrade2V1.ResolvedColor,
                                         expectedProvenance: String) throws {
        guard color.srgb.count == 3, color.srgb.allSatisfy({ (0...255).contains($0) }),
              color.resolutionVersion == "resolved-color-1.0.0",
              color.provenance == expectedProvenance else { throw Error.invalidExplicitColor }
    }

    private static func clamp(_ value: Double, _ lower: Double, _ upper: Double) -> Double {
        min(upper, max(lower, value))
    }
    private static func rounded3(_ value: Double) -> Double { (value * 1000).rounded() / 1000 }
}
