import Foundation

// The pressure model's content shapes. Everything here is data: adding a target or a source is a
// JSON edit, which is what lets the remaining seven targets land without touching the rules.

/// One of the world's dials. Every sigil binds to exactly one.
struct PressureTargetDef: Codable, Equatable, Identifiable, Sendable {
    var id: PressureTargetID
    var name: String
    var icon: String
    var blurb: String
    /// True for Illumination and Thermal only. Those two resolve to a peak *and* a floor, because
    /// dim and dark are different pressures and one number can't say both.
    var dualValued: Bool
    var highLabel: String
    var lowLabel: String
    var order: Int
}

/// A concrete cause. Sources contribute to several targets at once — the ones you didn't bind are
/// implicit secondaries, and they're what make the system causal rather than a set of sliders.
struct PressureSourceDef: Codable, Equatable, Identifiable, Sendable {
    var id: PressureSourceID
    var name: String
    var icon: String
    var blurb: String
    var contributions: [PressureContribution]

    func contribution(to target: PressureTargetID) -> PressureContribution? {
        contributions.first { $0.target == target }
    }

    /// Which targets this source touches at all — the explicit bind must be one of them.
    var targets: [PressureTargetID] { contributions.map(\.target) }
}

/// What a source does to one target.
struct PressureContribution: Codable, Equatable, Sendable {
    var target: PressureTargetID
    /// *How* it contributes, and it differs per target: illumination's cyclic sources lift only the
    /// peak, constant ones lift peak and floor, occluding ones push both down. Each target has its
    /// own character axis — they are not copy-paste.
    var character: String
    var peak: Double
    var floor: Double
    var tags: [String]

    init(target: PressureTargetID, character: String, peak: Double, floor: Double = 0, tags: [String] = []) {
        self.target = target
        self.character = character
        self.peak = peak
        self.floor = floor
        self.tags = tags
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        target = try container.decode(PressureTargetID.self, forKey: .target)
        character = try container.decodeIfPresent(String.self, forKey: .character) ?? "neutral"
        peak = try container.decodeIfPresent(Double.self, forKey: .peak) ?? 0
        floor = try container.decodeIfPresent(Double.self, forKey: .floor) ?? 0
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
    }
}
