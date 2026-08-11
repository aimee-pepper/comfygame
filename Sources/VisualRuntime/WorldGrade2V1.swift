import CryptoKit
import CoreFoundation
import Foundation

enum WorldGrade2V1 {
    static let canonicalManifestSHA256 = "e601d2f77a15d545fd2d893dbb2e41891518cba2900c3f6d66890d56294824c1"
    static let rawManifestSHA256 = "da7d79fb949f043453cfcffdecbf50eac44ac00a0bad307c7b879270d8f91a41"
    static let requestSchemaSHA256 = "a5693b65d9a9abc6f63d3581f27d84968e8ecad9b613094fa6a3f7b4795f65ac"
    static let descriptorSchemaSHA256 = "a34f63e50aee7346ed304c1a666209e6ef706e252b557a23cd5cd4cbaeb565b3"
    static let conformanceVectorsSHA256 = "b10c92e4232e6fb01c75d3d6ba07b4fef2d883c0b6d735afd538c1001d7218f2"

    struct Versions: Codable, Equatable, Sendable {
        var contractVersion = 1
        var resolverVersion = "world-grade-2-resolver-1.0.0"
        var paletteCatalogueVersion = "world-grade-2-palette-1.0.0"
        var rendererVersion = "world-grade-2-renderer-1.0.0"
        var lightLayerVersion = "current-visibility-separate-1.0.0"

        init() {}
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            contractVersion = try c.decodeIfPresent(Int.self, forKey: .contractVersion) ?? 0
            resolverVersion = try c.decodeIfPresent(String.self, forKey: .resolverVersion) ?? ""
            paletteCatalogueVersion = try c.decodeIfPresent(String.self, forKey: .paletteCatalogueVersion) ?? ""
            rendererVersion = try c.decodeIfPresent(String.self, forKey: .rendererVersion) ?? ""
            lightLayerVersion = try c.decodeIfPresent(String.self, forKey: .lightLayerVersion) ?? ""
        }
    }

    static let versions = Versions()

    struct Transform: Codable, Equatable, Sendable {
        var hue = 0.0
        var saturation = 1.0
        var value = 0.0
        init(hue: Double = 0, saturation: Double = 1, value: Double = 0) {
            self.hue = hue; self.saturation = saturation; self.value = value
        }
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            hue = try c.decodeIfPresent(Double.self, forKey: .hue) ?? .nan
            saturation = try c.decodeIfPresent(Double.self, forKey: .saturation) ?? .nan
            value = try c.decodeIfPresent(Double.self, forKey: .value) ?? .nan
        }
    }

    struct ResolvedColor: Codable, Equatable, Sendable {
        var srgb: [Int]
        var resolutionVersion: String
        var provenance: String
        init(srgb: [Int] = [], resolutionVersion: String = "", provenance: String = "") {
            self.srgb = srgb; self.resolutionVersion = resolutionVersion; self.provenance = provenance
        }
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            srgb = try c.decodeIfPresent([Int].self, forKey: .srgb) ?? []
            resolutionVersion = try c.decodeIfPresent(String.self, forKey: .resolutionVersion) ?? ""
            provenance = try c.decodeIfPresent(String.self, forKey: .provenance) ?? ""
        }
    }

    struct Material: Codable, Equatable, Sendable {
        var identity: String
        var paletteFamilyID: String
        var transform: Transform
        init(identity: String = "", paletteFamilyID: String = "",
             transform: Transform = Transform()) {
            self.identity = identity; self.paletteFamilyID = paletteFamilyID; self.transform = transform
        }
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            identity = try c.decodeIfPresent(String.self, forKey: .identity) ?? ""
            paletteFamilyID = try c.decodeIfPresent(String.self, forKey: .paletteFamilyID) ?? ""
            transform = try c.decodeIfPresent(Transform.self, forKey: .transform) ?? Transform(hue: .nan)
        }
    }

    struct Atmosphere: Codable, Equatable, Sendable {
        var medium: String
        var density: Double
        var paletteFamilyID: String
        init(medium: String = "", density: Double = .nan, paletteFamilyID: String = "") {
            self.medium = medium; self.density = density; self.paletteFamilyID = paletteFamilyID
        }
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            medium = try c.decodeIfPresent(String.self, forKey: .medium) ?? ""
            density = try c.decodeIfPresent(Double.self, forKey: .density) ?? .nan
            paletteFamilyID = try c.decodeIfPresent(String.self, forKey: .paletteFamilyID) ?? ""
        }
    }

    struct FloraSpecies: Codable, Equatable, Sendable {
        var speciesID: String
        var formID: Int
        var stature: Double
        var resolvedColor: ResolvedColor
        init(speciesID: String = "", formID: Int = -1, stature: Double = .nan,
             resolvedColor: ResolvedColor = ResolvedColor()) {
            self.speciesID = speciesID; self.formID = formID; self.stature = stature
            self.resolvedColor = resolvedColor
        }
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            speciesID = try c.decodeIfPresent(String.self, forKey: .speciesID) ?? ""
            formID = try c.decodeIfPresent(Int.self, forKey: .formID) ?? -1
            stature = try c.decodeIfPresent(Double.self, forKey: .stature) ?? .nan
            resolvedColor = try c.decodeIfPresent(ResolvedColor.self, forKey: .resolvedColor) ?? ResolvedColor()
        }
    }

    struct FloraRequest: Codable, Equatable, Sendable {
        var coveragePercent: Double
        var paletteRichness: Double
        var cast: [FloraSpecies]
        init(coveragePercent: Double = .nan, paletteRichness: Double = .nan,
             cast: [FloraSpecies] = []) {
            self.coveragePercent = coveragePercent; self.paletteRichness = paletteRichness; self.cast = cast
        }
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            coveragePercent = try c.decodeIfPresent(Double.self, forKey: .coveragePercent) ?? .nan
            paletteRichness = try c.decodeIfPresent(Double.self, forKey: .paletteRichness) ?? .nan
            cast = try c.decodeIfPresent([FloraSpecies].self, forKey: .cast) ?? []
        }
    }

    struct RequestColors: Codable, Equatable, Sendable {
        var material: ResolvedColor?
        var atmosphere: ResolvedColor?
        var emitter: ResolvedColor?
        var floraTendency: ResolvedColor?
        init(material: ResolvedColor? = nil, atmosphere: ResolvedColor? = nil,
             emitter: ResolvedColor? = nil, floraTendency: ResolvedColor? = nil) {
            self.material = material; self.atmosphere = atmosphere
            self.emitter = emitter; self.floraTendency = floraTendency
        }
        func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode(material, forKey: .material)
            try c.encode(atmosphere, forKey: .atmosphere)
            try c.encode(emitter, forKey: .emitter)
            try c.encode(floraTendency, forKey: .floraTendency)
        }
    }

    struct Request: Codable, Equatable, Sendable {
        var versions: Versions
        var material: Material
        var atmosphere: Atmosphere
        var flora: FloraRequest
        var resolvedColors: RequestColors
        init(versions: Versions = WorldGrade2V1.versions, material: Material = Material(),
             atmosphere: Atmosphere = Atmosphere(), flora: FloraRequest = FloraRequest(),
             resolvedColors: RequestColors = RequestColors()) {
            self.versions = versions; self.material = material; self.atmosphere = atmosphere
            self.flora = flora; self.resolvedColors = resolvedColors
        }
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            if let decoded = try c.decodeIfPresent(Versions.self, forKey: .versions) {
                versions = decoded
            } else {
                var missing = Versions()
                missing.contractVersion = 0
                versions = missing
            }
            material = try c.decodeIfPresent(Material.self, forKey: .material) ?? Material()
            atmosphere = try c.decodeIfPresent(Atmosphere.self, forKey: .atmosphere) ?? Atmosphere()
            flora = try c.decodeIfPresent(FloraRequest.self, forKey: .flora) ?? FloraRequest()
            resolvedColors = try c.decodeIfPresent(RequestColors.self, forKey: .resolvedColors) ?? RequestColors()
        }
    }

    struct FloraDescriptor: Codable, Equatable, Sendable {
        var coveragePercent: Double
        var paletteRichness: Double
        var richness: Double
        var cast: [FloraSpecies]
        init(coveragePercent: Double = .nan, paletteRichness: Double = .nan,
             richness: Double = .nan, cast: [FloraSpecies] = []) {
            self.coveragePercent = coveragePercent; self.paletteRichness = paletteRichness
            self.richness = richness; self.cast = cast
        }
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            coveragePercent = try c.decodeIfPresent(Double.self, forKey: .coveragePercent) ?? .nan
            paletteRichness = try c.decodeIfPresent(Double.self, forKey: .paletteRichness) ?? .nan
            richness = try c.decodeIfPresent(Double.self, forKey: .richness) ?? .nan
            cast = try c.decodeIfPresent([FloraSpecies].self, forKey: .cast) ?? []
        }
    }
    struct DescriptorColors: Codable, Equatable, Sendable {
        var material: ResolvedColor?
        var atmosphere: ResolvedColor?
        var emitter: ResolvedColor?
        init(material: ResolvedColor? = nil, atmosphere: ResolvedColor? = nil,
             emitter: ResolvedColor? = nil) {
            self.material = material; self.atmosphere = atmosphere; self.emitter = emitter
        }
        func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode(material, forKey: .material)
            try c.encode(atmosphere, forKey: .atmosphere)
            try c.encode(emitter, forKey: .emitter)
        }
    }
    struct Descriptor: Codable, Equatable, Sendable {
        var versions: Versions
        var material: Material
        var atmosphere: Atmosphere
        var flora: FloraDescriptor
        var resolvedColors: DescriptorColors
        var canonicalDescriptorSHA256: String
        init(versions: Versions = Versions(), material: Material = Material(),
             atmosphere: Atmosphere = Atmosphere(), flora: FloraDescriptor = FloraDescriptor(),
             resolvedColors: DescriptorColors = DescriptorColors(),
             canonicalDescriptorSHA256: String = "") {
            self.versions = versions; self.material = material; self.atmosphere = atmosphere
            self.flora = flora; self.resolvedColors = resolvedColors
            self.canonicalDescriptorSHA256 = canonicalDescriptorSHA256
        }
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            versions = try c.decodeIfPresent(Versions.self, forKey: .versions) ?? Versions()
            material = try c.decodeIfPresent(Material.self, forKey: .material) ?? Material()
            atmosphere = try c.decodeIfPresent(Atmosphere.self, forKey: .atmosphere) ?? Atmosphere()
            flora = try c.decodeIfPresent(FloraDescriptor.self, forKey: .flora) ?? FloraDescriptor()
            resolvedColors = try c.decodeIfPresent(DescriptorColors.self, forKey: .resolvedColors)
                ?? DescriptorColors()
            canonicalDescriptorSHA256 = try c.decodeIfPresent(String.self,
                forKey: .canonicalDescriptorSHA256) ?? ""
        }
    }

    enum ContractError: Error, Equatable, Sendable {
        case invalidFields(String)
        case versionMismatch
        case unknownMaterialFact
        case invalidValue(String)
        case unknownAtmosphereFact
        case invalidClearAtmosphere
        case invalidSmokeFamily
        case invalidFloraCast
        case invalidFloraSpecies
        case duplicateFloraSpecies
        case floraCastCoverageMismatch
        case invalidColor(String)
        case clearAtmosphereCannotOwnColor
        case unknownGroundOwnership
        case unknownFloraSpeciesColor
        case invalidHexColor
        case invalidFogRequest
    }

    private struct PaletteTransform { var hue: Double; var saturation: Double; var value: Double }
    private static let materialFamilies: [String: PaletteTransform] = [
        "warmMineral": .init(hue: 18, saturation: 1.28, value: 2),
        "coolMineral": .init(hue: -28, saturation: 1.18, value: -3),
        "warmEarth": .init(hue: 30, saturation: 1.22, value: 1),
        "coolEarth": .init(hue: -34, saturation: 1.2, value: -2),
        "paleNeutral": .init(hue: 8, saturation: 0.82, value: 8),
        "darkNeutral": .init(hue: 0, saturation: 0.9, value: -7),
    ]
    private static let atmosphereFamilies: [String: PaletteTransform] = [
        "clear": .init(hue: 0, saturation: 1, value: 0),
        "neutralSmoke": .init(hue: 8, saturation: 0.8, value: -10),
        "coolSmoke": .init(hue: -10, saturation: 0.86, value: -8),
    ]
    static let groundOwnership: [String: String] = [
        "stone": "material+atmosphere", "soil": "material+atmosphere",
        "sand": "material+atmosphere", "ash": "material+atmosphere",
        "rubble": "material+atmosphere", "mud": "material+atmosphere",
        "chasm": "void+atmosphere", "water": "hydrology+atmosphere",
        "deepWater": "hydrology+atmosphere", "ice": "hydrology+atmosphere",
        "growth": "ecology+atmosphere", "groundcover": "ecology+atmosphere",
    ]

    static func resolve(_ request: Request) throws -> Descriptor {
        guard request.versions == versions else { throw ContractError.versionMismatch }
        guard ["granite", "mixedMineral", "mixedEarth"].contains(request.material.identity),
              materialFamilies[request.material.paletteFamilyID] != nil else {
            throw ContractError.unknownMaterialFact
        }
        try bounded(request.material.transform.hue, -64, 64, "material-hue")
        try bounded(request.material.transform.saturation, 0.7, 1.6, "material-saturation")
        try bounded(request.material.transform.value, -20, 20, "material-value")
        guard ["none", "smoke"].contains(request.atmosphere.medium),
              atmosphereFamilies[request.atmosphere.paletteFamilyID] != nil else {
            throw ContractError.unknownAtmosphereFact
        }
        if request.atmosphere.medium == "none",
           request.atmosphere.density != 0 || request.atmosphere.paletteFamilyID != "clear" {
            throw ContractError.invalidClearAtmosphere
        }
        if request.atmosphere.medium == "smoke",
           !request.atmosphere.paletteFamilyID.hasSuffix("Smoke") {
            throw ContractError.invalidSmokeFamily
        }
        try bounded(request.atmosphere.density, 0, 100, "atmosphere-density")
        try bounded(request.flora.coveragePercent, 0, 100, "flora-coverage")
        try bounded(request.flora.paletteRichness, 0, 100, "flora-richness")
        guard request.flora.cast.count <= 4 else { throw ContractError.invalidFloraCast }
        var speciesIDs = Set<String>()
        for species in request.flora.cast {
            guard validSpeciesID(species.speciesID), (0...3).contains(species.formID) else {
                throw ContractError.invalidFloraSpecies
            }
            try bounded(species.stature, 0, 100, "flora-stature")
            try validate(species.resolvedColor, label: "flora-species-color")
            guard speciesIDs.insert(species.speciesID).inserted else {
                throw ContractError.duplicateFloraSpecies
            }
        }
        guard request.flora.cast.isEmpty == (request.flora.coveragePercent == 0) else {
            throw ContractError.floraCastCoverageMismatch
        }
        for (label, color) in [("material", request.resolvedColors.material),
                               ("atmosphere", request.resolvedColors.atmosphere),
                               ("emitter", request.resolvedColors.emitter),
                               ("floraTendency", request.resolvedColors.floraTendency)] {
            if let color { try validate(color, label: label) }
        }
        if request.atmosphere.medium == "none", request.resolvedColors.atmosphere != nil {
            throw ContractError.clearAtmosphereCannotOwnColor
        }
        let richness = ((0.7 + 0.6 * request.flora.paletteRichness / 100) * 1000).rounded() / 1000
        var descriptor = Descriptor(
            versions: versions, material: request.material, atmosphere: request.atmosphere,
            flora: FloraDescriptor(coveragePercent: request.flora.coveragePercent,
                                   paletteRichness: request.flora.paletteRichness,
                                   richness: richness, cast: request.flora.cast),
            resolvedColors: DescriptorColors(material: request.resolvedColors.material,
                                             atmosphere: request.resolvedColors.atmosphere,
                                             emitter: request.resolvedColors.emitter),
            canonicalDescriptorSHA256: "")
        descriptor.canonicalDescriptorSHA256 = try canonicalDescriptorSHA256(descriptor)
        return descriptor
    }

    static func resolveJSON(_ data: Data) throws -> Descriptor {
        let object = try JSONSerialization.jsonObject(with: data)
        try validateExactShape(object)
        return try resolve(JSONDecoder().decode(Request.self, from: data))
    }

    static func canonicalSHA256<T: Encodable>(_ value: T) throws -> String {
        let object = try JSONSerialization.jsonObject(with: JSONEncoder().encode(value))
        return sha256(Data(try canonicalJSON(object).utf8))
    }

    static func canonicalDescriptorSHA256(_ descriptor: Descriptor) throws -> String {
        var object = try castObject(JSONSerialization.jsonObject(with: JSONEncoder().encode(descriptor)))
        object.removeValue(forKey: "canonicalDescriptorSHA256")
        return sha256(Data(try canonicalJSON(object).utf8))
    }

    enum ColorScope: String, Sendable { case material, atmosphere, emitter, flora }
    static func color(_ hex: String, descriptor: Descriptor, scope: ColorScope = .material,
                      includeEmitter: Bool = false, groundType: String? = nil,
                      speciesID: String? = nil) throws -> String {
        if scope == .material, groundOwnership[groundType ?? ""] == nil {
            throw ContractError.unknownGroundOwnership
        }
        guard let family = materialFamilies[descriptor.material.paletteFamilyID],
              let air = atmosphereFamilies[descriptor.atmosphere.paletteFamilyID] else {
            throw ContractError.unknownMaterialFact
        }
        let materialGround = scope == .material
            && (groundOwnership[groundType ?? ""]?.hasPrefix("material") == true)
        let graniteEligible = descriptor.material.identity == "granite"
            && ["stone", "rubble"].contains(groundType ?? "")
        var hsl = try rgbToHSL(hexToRGB(hex))
        let density = descriptor.atmosphere.density / 100
        hsl.h = positiveModulo(hsl.h + (materialGround
            ? descriptor.material.transform.hue + family.hue : 0) + air.hue * density, 360)
        hsl.s = clamp(hsl.s * (materialGround
            ? descriptor.material.transform.saturation * family.saturation : 1)
            * (1 + (air.saturation - 1) * density)
            * (scope == .flora ? descriptor.flora.richness : 1), 0, 0.92)
        hsl.l = clamp(hsl.l + ((materialGround
            ? descriptor.material.transform.value + family.value : 0) + air.value * density) / 100,
            0.12, 0.9)
        let floraSpecies = scope == .flora
            ? descriptor.flora.cast.first(where: { $0.speciesID == speciesID }) : nil
        if scope == .flora, floraSpecies == nil { throw ContractError.unknownFloraSpeciesColor }
        var rgb = hslToRGB(hsl)
        let scoped: [Int]? = if scope == .flora { floraSpecies?.resolvedColor.srgb }
            else if scope == .material && !graniteEligible { nil }
            else { descriptorColor(scope, descriptor)?.srgb }
        if let scoped { rgb = mix(rgb, scoped.map(Double.init), 0.38 - (scope == .flora ? 0.06 : 0)) }
        if let atmosphere = descriptor.resolvedColors.atmosphere?.srgb,
           descriptor.atmosphere.medium != "none" {
            rgb = mix(rgb, atmosphere.map(Double.init), 0.2 * density)
        }
        if includeEmitter, let emitter = descriptor.resolvedColors.emitter?.srgb {
            rgb = mix(rgb, emitter.map(Double.init), 0.13)
        }
        return rgbToHex(rgb)
    }

    struct RectangleCommand: Codable, Equatable, Sendable {
        var op: String; var x: Int; var y: Int; var w: Int; var h: Int; var color: String
    }
    struct GeometryCommand: Codable, Equatable, Sendable {
        var op: String; var x: Int; var y: Int; var w: Int; var h: Int
    }
    static func recolor(_ commands: [RectangleCommand], descriptor: Descriptor,
                        scope: ColorScope = .material, includeEmitter: Bool = false,
                        groundType: String? = nil, speciesID: String? = nil) throws -> [RectangleCommand] {
        try commands.map { command in
            guard command.color.hasPrefix("#") else { return command }
            var result = command
            result.color = try color(command.color, descriptor: descriptor, scope: scope,
                                     includeEmitter: includeEmitter, groundType: groundType,
                                     speciesID: speciesID)
            return result
        }
    }
    static func geometry(_ commands: [RectangleCommand]) -> [GeometryCommand] {
        commands.map { .init(op: $0.op, x: $0.x, y: $0.y, w: $0.w, h: $0.h) }
    }
    static func fogRGBA(revealed: Bool, width: Int, height: Int) throws -> [UInt8]? {
        guard width >= 1, height >= 1 else { throw ContractError.invalidFogRequest }
        return revealed ? nil : Array(repeating: 0, count: width * height * 4)
    }

    private static func descriptorColor(_ scope: ColorScope,
                                        _ descriptor: Descriptor) -> ResolvedColor? {
        switch scope {
        case .material: descriptor.resolvedColors.material
        case .atmosphere: descriptor.resolvedColors.atmosphere
        case .emitter: descriptor.resolvedColors.emitter
        case .flora: nil
        }
    }
    private static func validate(_ color: ResolvedColor, label: String) throws {
        let version = try? NSRegularExpression(pattern: "^resolved-color-[1-9][0-9]*\\.[0-9]+\\.[0-9]+$")
        let range = NSRange(color.resolutionVersion.startIndex..., in: color.resolutionVersion)
        guard color.srgb.count == 3, color.srgb.allSatisfy({ (0...255).contains($0) }),
              version?.firstMatch(in: color.resolutionVersion, range: range) != nil,
              ["authoredMix", "bindRandom"].contains(color.provenance) else {
            throw ContractError.invalidColor(label)
        }
    }
    private static func bounded(_ value: Double, _ min: Double, _ max: Double,
                                _ label: String) throws {
        guard value.isFinite, value >= min, value <= max else {
            throw ContractError.invalidValue(label)
        }
    }
    private static func validSpeciesID(_ value: String) -> Bool {
        value.range(of: "^[a-z][a-z0-9_-]{0,31}$", options: .regularExpression) != nil
    }
    private static func clamp(_ n: Double, _ min: Double = 0, _ max: Double = 255) -> Double {
        Swift.max(min, Swift.min(max, n))
    }
    private static func positiveModulo(_ value: Double, _ divisor: Double) -> Double {
        let result = value.truncatingRemainder(dividingBy: divisor)
        return result < 0 ? result + divisor : result
    }
    private static func hexToRGB(_ hex: String) throws -> [Double] {
        guard hex.range(of: "^#[0-9a-fA-F]{6}$", options: .regularExpression) != nil else {
            throw ContractError.invalidHexColor
        }
        return [1, 3, 5].map { Double(Int(hex.dropFirst($0).prefix(2), radix: 16)!) }
    }
    private static func rgbToHex(_ rgb: [Double]) -> String {
        "#" + rgb.map { String(format: "%02x", Int(floor(clamp($0) + 0.5))) }.joined()
    }
    private struct HSL { var h: Double; var s: Double; var l: Double }
    private static func rgbToHSL(_ rgb: [Double]) -> HSL {
        let r = rgb[0] / 255, g = rgb[1] / 255, b = rgb[2] / 255
        let maximum = Swift.max(r, Swift.max(g, b)), minimum = Swift.min(r, Swift.min(g, b))
        let l = (maximum + minimum) / 2, d = maximum - minimum
        guard d != 0 else { return HSL(h: 0, s: 0, l: l) }
        let s = d / (1 - abs(2 * l - 1))
        let h: Double
        if maximum == r { h = 60 * ((g - b) / d).truncatingRemainder(dividingBy: 6) }
        else if maximum == g { h = 60 * ((b - r) / d + 2) }
        else { h = 60 * ((r - g) / d + 4) }
        return HSL(h: positiveModulo(h, 360), s: s, l: l)
    }
    private static func hslToRGB(_ hsl: HSL) -> [Double] {
        let chroma = (1 - abs(2 * hsl.l - 1)) * hsl.s
        let x = chroma * (1 - abs((hsl.h / 60).truncatingRemainder(dividingBy: 2) - 1))
        let m = hsl.l - chroma / 2
        let value: [Double]
        if hsl.h < 60 { value = [chroma, x, 0] }
        else if hsl.h < 120 { value = [x, chroma, 0] }
        else if hsl.h < 180 { value = [0, chroma, x] }
        else if hsl.h < 240 { value = [0, x, chroma] }
        else if hsl.h < 300 { value = [x, 0, chroma] }
        else { value = [chroma, 0, x] }
        return value.map { ($0 + m) * 255 }
    }
    private static func mix(_ a: [Double], _ b: [Double], _ t: Double) -> [Double] {
        zip(a, b).map { pair in pair.0 * (1 - t) + pair.1 * t }
    }

    private static func validateExactShape(_ value: Any) throws {
        let root = try castObject(value)
        try exact(root, ["versions", "material", "atmosphere", "flora", "resolvedColors"], "request")
        try exact(try object(root, "versions"), ["contractVersion", "resolverVersion", "paletteCatalogueVersion", "rendererVersion", "lightLayerVersion"], "versions")
        let material = try object(root, "material")
        try exact(material, ["identity", "paletteFamilyID", "transform"], "material")
        try exact(try object(material, "transform"), ["hue", "saturation", "value"], "material-transform")
        try exact(try object(root, "atmosphere"), ["medium", "density", "paletteFamilyID"], "atmosphere")
        let flora = try object(root, "flora")
        try exact(flora, ["coveragePercent", "paletteRichness", "cast"], "flora")
        guard let cast = flora["cast"] as? [Any] else { throw ContractError.invalidFields("flora-cast") }
        for entry in cast {
            let species = try castObject(entry)
            try exact(species, ["speciesID", "formID", "stature", "resolvedColor"], "flora-species")
            try exact(try object(species, "resolvedColor"), ["srgb", "resolutionVersion", "provenance"], "flora-color")
        }
        let colors = try object(root, "resolvedColors")
        try exact(colors, ["material", "atmosphere", "emitter", "floraTendency"], "colors")
        for key in colors.keys where !(colors[key] is NSNull) {
            try exact(try object(colors, key), ["srgb", "resolutionVersion", "provenance"], "\(key)-color")
        }
    }
    private static func exact(_ value: [String: Any], _ keys: Set<String>,
                              _ label: String) throws {
        guard Set(value.keys) == keys else { throw ContractError.invalidFields(label) }
    }
    private static func object(_ value: [String: Any], _ key: String) throws -> [String: Any] {
        try castObject(value[key] as Any)
    }
    private static func castObject(_ value: Any) throws -> [String: Any] {
        guard let value = value as? [String: Any] else { throw ContractError.invalidFields("object") }
        return value
    }
    private static func canonicalJSON(_ value: Any) throws -> String {
        if value is NSNull { return "null" }
        if let string = value as? String {
            return String(decoding: try JSONEncoder().encode(string), as: UTF8.self)
        }
        if let array = value as? [Any] {
            return "[" + (try array.map(canonicalJSON)).joined(separator: ",") + "]"
        }
        if let object = value as? [String: Any] {
            return "{" + (try object.keys.sorted().map { key in
                let encodedKey = String(decoding: try JSONEncoder().encode(key), as: UTF8.self)
                return encodedKey + ":" + (try canonicalJSON(object[key] as Any))
            }).joined(separator: ",") + "}"
        }
        if let number = value as? NSNumber {
            if CFGetTypeID(number) == CFBooleanGetTypeID() { return number.boolValue ? "true" : "false" }
            return ecmaNumber(number.doubleValue)
        }
        throw ContractError.invalidValue("canonical-json")
    }
    private static func ecmaNumber(_ value: Double) -> String {
        guard value.isFinite, value != 0 else { return value == 0 ? "0" : "null" }
        if value.rounded(.towardZero) == value, abs(value) < 1e21 {
            return String(format: "%.0f", value)
        }
        var text = String(value).replacingOccurrences(of: "E", with: "e")
        if let range = text.range(of: "e") {
            let mantissa = String(text[..<range.lowerBound])
            var exponent = String(text[range.upperBound...])
            let sign = exponent.first == "-" ? "-" : (exponent.first == "+" ? "+" : "+")
            if exponent.first == "-" || exponent.first == "+" { exponent.removeFirst() }
            while exponent.first == "0" { exponent.removeFirst() }
            text = mantissa + "e" + sign + (exponent.isEmpty ? "0" : exponent)
        }
        return text
    }
    private static func sha256(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}
