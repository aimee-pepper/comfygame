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
