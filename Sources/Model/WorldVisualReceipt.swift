import Foundation

enum WorldVisualScope: String, Codable, CaseIterable, Hashable, Sendable {
    case material, atmosphere, emitter, floraTendency
}

/// Immutable game-owned facts consumed by the world-grade renderer. The adapter owns creation;
/// rendering and History validate and read this receipt without re-resolving catalogue content.
struct WorldVisualReceipt: Codable, Equatable, Sendable {
    static let currentAdapterVersion = "world-grade-2-bind-adapter-1.0.0"

    var adapterVersion: String
    var request: WorldGrade2V1.Request
    var descriptor: WorldGrade2V1.Descriptor
    var descriptorHash: String
    var selectedSourceByScope: [WorldVisualScope: InstanceID]
    var canonicalReceiptSHA256: String

    private enum CodingKeys: String, CodingKey {
        case adapterVersion, request, descriptor, descriptorHash, selectedSourceByScope
        case canonicalReceiptSHA256
    }
    private struct CanonicalPayload: Encodable {
        var adapterVersion: String
        var request: WorldGrade2V1.Request
        var descriptor: WorldGrade2V1.Descriptor
        var descriptorHash: String
        var selectedSourceByScope: [String: String]
    }

    init(adapterVersion: String = Self.currentAdapterVersion,
         request: WorldGrade2V1.Request,
         descriptor: WorldGrade2V1.Descriptor,
         descriptorHash: String,
         selectedSourceByScope: [WorldVisualScope: InstanceID],
         canonicalReceiptSHA256: String? = nil) throws {
        self.adapterVersion = adapterVersion
        self.request = request
        self.descriptor = descriptor
        self.descriptorHash = descriptorHash
        self.selectedSourceByScope = selectedSourceByScope
        self.canonicalReceiptSHA256 = canonicalReceiptSHA256 ?? ""
        if canonicalReceiptSHA256 == nil {
            self.canonicalReceiptSHA256 = try computedCanonicalReceiptSHA256()
        }
        try validate()
    }

    func validate() throws {
        let computedReceiptHash = try computedCanonicalReceiptSHA256()
        let colorScopes = Set([
            request.resolvedColors.material == nil ? nil : WorldVisualScope.material,
            request.resolvedColors.atmosphere == nil ? nil : WorldVisualScope.atmosphere,
            request.resolvedColors.emitter == nil ? nil : WorldVisualScope.emitter,
            request.resolvedColors.floraTendency == nil ? nil : WorldVisualScope.floraTendency,
        ].compactMap { $0 })
        guard adapterVersion == Self.currentAdapterVersion,
              descriptorHash == descriptor.canonicalDescriptorSHA256,
              Set(selectedSourceByScope.keys) == colorScopes,
              canonicalReceiptSHA256 == computedReceiptHash,
              try WorldGrade2V1.resolve(request) == descriptor else {
            throw WorldGrade2BindAdapter.Error.invalidReceipt
        }
        try WorldGrade2V1.validateDescriptor(descriptor)
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        adapterVersion = try c.decode(String.self, forKey: .adapterVersion)
        request = try c.decode(WorldGrade2V1.Request.self, forKey: .request)
        descriptor = try c.decode(WorldGrade2V1.Descriptor.self, forKey: .descriptor)
        descriptorHash = try c.decode(String.self, forKey: .descriptorHash)
        let selected: [String: InstanceID]
        if let strings = try? c.decode([String: String].self, forKey: .selectedSourceByScope) {
            selected = try strings.mapValues { value in
                guard let raw = UInt64(value) else {
                    throw WorldGrade2BindAdapter.Error.invalidReceipt
                }
                return InstanceID(rawValue: raw)
            }
        } else {
            selected = try c.decode([String: InstanceID].self, forKey: .selectedSourceByScope)
        }
        selectedSourceByScope = try Dictionary(uniqueKeysWithValues: selected.map { key, value in
            guard let scope = WorldVisualScope(rawValue: key) else {
                throw WorldGrade2BindAdapter.Error.invalidReceipt
            }
            return (scope, value)
        })
        canonicalReceiptSHA256 = try c.decode(String.self, forKey: .canonicalReceiptSHA256)
        try validate()
    }

    func encode(to encoder: Encoder) throws {
        try validate()
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(adapterVersion, forKey: .adapterVersion)
        try c.encode(request, forKey: .request)
        try c.encode(descriptor, forKey: .descriptor)
        try c.encode(descriptorHash, forKey: .descriptorHash)
        try c.encode(Dictionary(uniqueKeysWithValues: selectedSourceByScope.map {
            ($0.key.rawValue, String($0.value.rawValue))
        }), forKey: .selectedSourceByScope)
        try c.encode(canonicalReceiptSHA256, forKey: .canonicalReceiptSHA256)
    }

    private func computedCanonicalReceiptSHA256() throws -> String {
        try WorldGrade2V1.canonicalSHA256(CanonicalPayload(
            adapterVersion: adapterVersion, request: request, descriptor: descriptor,
            descriptorHash: descriptorHash,
            selectedSourceByScope: selectedSourceByScope.reduce(into: [String: String]()) {
                $0[$1.key.rawValue] = String($1.value.rawValue)
            }))
    }
}

/// Frozen, rules-owned atmosphere truth for one bound world. Presentation consumers read this
/// value; they never reinterpret the page, pressure catalogue, or mutable world readings.
struct WorldAtmospherePresentationReceiptV1: Codable, Equatable, Sendable {
    static let schemaVersion = "world-atmosphere-presentation-1"
    static let resolverVersion = "world-atmosphere-resolver-1.0.0"

    enum SuspendedMedium: String, Codable, CaseIterable, Sendable {
        case none, smoke, airborneAsh, mist, miasma
    }
    enum Precipitation: String, Codable, CaseIterable, Sendable {
        case none, rain, snow, mixedRainSnow
    }
    enum MotionBand: String, Codable, CaseIterable, Sendable { case calm, moving, strong }
    enum Direction: String, Codable, CaseIterable, Sendable {
        case north, northEast, east, southEast, south, southWest, west, northWest
    }
    struct MediumPalette: Codable, Equatable, Sendable {
        var familyID: String
        var authoredColor: WorldGrade2V1.ResolvedColor?
    }

    var schemaVersion: String
    var suspendedMedium: SuspendedMedium
    var suspendedDensity: Int
    var suspendedSourceIDs: [InstanceID]
    var precipitation: Precipitation
    var precipitationDensity: Int
    var precipitationSourceIDs: [InstanceID]
    var motionBand: MotionBand
    var presentationDirection: Direction
    var mediumPalette: MediumPalette
    var phaseSeed: UInt64
    var resolverVersion: String

    static func clear(seed: UInt64) -> Self {
        let presentation = SeededRNG(seed: seed).derived(0x4154_4D4F_5350_4852)
        return .init(
            schemaVersion: schemaVersion, suspendedMedium: .none, suspendedDensity: 0,
            suspendedSourceIDs: [], precipitation: .none, precipitationDensity: 0,
            precipitationSourceIDs: [], motionBand: .calm,
            presentationDirection: Direction.allCases[Int(presentation.seed % 8)],
            mediumPalette: .init(familyID: "clear", authoredColor: nil),
            phaseSeed: presentation.derived(0x5048_4153_455F_5631).seed,
            resolverVersion: resolverVersion)
    }

    func validates() -> Bool {
        schemaVersion == Self.schemaVersion && resolverVersion == Self.resolverVersion
            && (0...100).contains(suspendedDensity)
            && (0...100).contains(precipitationDensity)
            && (suspendedMedium == .none) == (suspendedDensity == 0)
            && (precipitation == .none) == (precipitationDensity == 0)
            && suspendedSourceIDs == suspendedSourceIDs.sorted(by: { $0.rawValue < $1.rawValue })
            && precipitationSourceIDs == precipitationSourceIDs.sorted(by: { $0.rawValue < $1.rawValue })
            && Set(suspendedSourceIDs).count == suspendedSourceIDs.count
            && Set(precipitationSourceIDs).count == precipitationSourceIDs.count
            && !mediumPalette.familyID.isEmpty
    }

    static func densityBand(_ density: Int, present: Bool) -> String {
        guard present, density > 0 else { return "none" }
        if density < 25 { return "trace" }
        if density < 50 { return "light" }
        if density < 75 { return "heavy" }
        return "dense"
    }

    /// A missing field means a legacy world. Only its already-frozen, valid smoke receipt may be
    /// carried forward; other legacy worlds close to clear rather than rereading their book.
    static func migratingLegacy(_ visual: WorldVisualReceipt?, seed: UInt64) -> Self {
        var receipt = clear(seed: seed)
        guard let visual, (try? visual.validate()) != nil,
              visual.request.atmosphere.medium == "smoke",
              (10...100).contains(visual.request.atmosphere.density) else { return receipt }
        receipt.suspendedMedium = .smoke
        receipt.suspendedDensity = Int(visual.request.atmosphere.density.rounded())
        receipt.mediumPalette = .init(
            familyID: visual.request.atmosphere.paletteFamilyID,
            authoredColor: visual.request.resolvedColors.atmosphere)
        if let source = visual.selectedSourceByScope[.atmosphere] {
            receipt.suspendedSourceIDs = [source]
        }
        return receipt
    }
}
