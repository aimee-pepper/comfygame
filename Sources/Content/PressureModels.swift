import Foundation

// The pressure model's content shapes. Everything here is data: adding a target, an aspect or a
// source is a JSON edit, which is what lets the remaining targets land without touching the rules.

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
    /// Where the target sits with nothing written about it. Thermal starts temperate (50) rather
    /// than frozen, so every interesting climate is *authored* rather than escaped from.
    var baseline: Double
    /// Extra scalars this target carries that aren't its magnitude — Hydrology's dispersion and
    /// salinity, Atmosphere's motion and clarity. Same 0–100 scale, same machinery.
    var aspects: [PressureAspectDef]
    /// The buckets a contribution can name — Hydrology's standing/flowing/frozen/airborne. A
    /// proportion, not a magnitude: a world can be equally wet as ice or as rain and they are
    /// completely different places.
    var forms: [String]
    var order: Int

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(PressureTargetID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        icon = try container.decode(String.self, forKey: .icon)
        blurb = try container.decode(String.self, forKey: .blurb)
        dualValued = try container.decodeIfPresent(Bool.self, forKey: .dualValued) ?? false
        highLabel = try container.decodeIfPresent(String.self, forKey: .highLabel) ?? "high"
        lowLabel = try container.decodeIfPresent(String.self, forKey: .lowLabel) ?? "low"
        baseline = try container.decodeIfPresent(Double.self, forKey: .baseline) ?? 0
        aspects = try container.decodeIfPresent([PressureAspectDef].self, forKey: .aspects) ?? []
        forms = try container.decodeIfPresent([String].self, forKey: .forms) ?? []
        order = try container.decodeIfPresent(Int.self, forKey: .order) ?? 0
    }
}

/// A named scalar a target carries alongside its magnitude.
struct PressureAspectDef: Codable, Equatable, Identifiable, Sendable {
    var id: String
    var name: String
    var lowLabel: String
    var highLabel: String
    var baseline: Double
}

/// A concrete cause. Sources contribute to several targets at once — the ones you didn't bind are
/// implicit secondaries, and they're what make the system causal rather than a set of sliders.
struct PressureSourceDef: Codable, Equatable, Identifiable, Sendable {
    var id: PressureSourceID
    var name: String
    var icon: String
    var blurb: String
    var contributions: [PressureContribution]
    /// **The one target this may be bound to.** Everything else it does still happens, as an
    /// implicit secondary — you simply can't *write* rain to make light. The rune spec says each
    /// source attaches to a target without saying which; this is that mapping.
    var attachesTo: PressureTargetID?

    func contribution(to target: PressureTargetID) -> PressureContribution? {
        contributions.first { $0.target == target }
    }

    /// Which targets this source touches at all — the explicit bind must be one of them.
    var targets: [PressureTargetID] { contributions.map(\.target) }
}

/// What a source does to one target.
struct PressureContribution: Codable, Equatable, Sendable {
    var target: PressureTargetID
    /// *How* it contributes, and it differs per target: Illumination's characters describe *when* a
    /// source acts, Thermal's describe whether it adds, holds or removes, Hydrology's describe what
    /// form the water takes. Each target needs its own axis — they are not copy-paste.
    var character: String
    var peak: Double
    var floor: Double
    /// Deltas on the target's auxiliary scalars, by aspect id.
    var aspects: [String: Double]
    /// Which of the target's form buckets this contribution fills, if any.
    var form: String?
    var tags: [String]

    init(target: PressureTargetID, character: String, peak: Double, floor: Double = 0,
         aspects: [String: Double] = [:], form: String? = nil, tags: [String] = []) {
        self.target = target
        self.character = character
        self.peak = peak
        self.floor = floor
        self.aspects = aspects
        self.form = form
        self.tags = tags
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        target = try container.decode(PressureTargetID.self, forKey: .target)
        character = try container.decodeIfPresent(String.self, forKey: .character) ?? "neutral"
        peak = try container.decodeIfPresent(Double.self, forKey: .peak) ?? 0
        floor = try container.decodeIfPresent(Double.self, forKey: .floor) ?? 0
        aspects = try container.decodeIfPresent([String: Double].self, forKey: .aspects) ?? [:]
        form = try container.decodeIfPresent(String.self, forKey: .form)
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
    }
}
