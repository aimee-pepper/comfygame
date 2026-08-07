import Foundation

/// One written statement: `[qualifiers] → source → Bind → target`.
///
/// Self-contained by design — a sigil is assembled internally and placed on the page as one unit,
/// and neighbours never interact. That's what makes the page a *budget* rather than a syntax, and
/// it's why resolution can take an unordered set.
struct Sigil: Codable, Equatable, Identifiable, Sendable {
    var id: InstanceID
    /// The cause.
    var source: PressureSourceID
    /// The dial it's explicitly bound to. The source's other contributions still happen — those are
    /// the implicit secondaries.
    var target: PressureTargetID
    /// The Intensity qualifier, scaling everything the source does.
    var intensity: Intensity
    /// Targets this sigil explicitly denies. "A sun that does not warm" is Sun bound to
    /// Illumination with Thermal negated — writable, and deeply unstable.
    var negatedTargets: Set<PressureTargetID>

    /// **How big the thing is** — 0 for unwritten, up through the Scale ladder.
    ///
    /// Scale used to mean world size and nothing else, so *a vast sun* was a plain sun. Aimee:
    /// *"I do think I should be able to make a giant overwhelming sun."* Quite right — for a sun,
    /// extent and magnitude are the same thing. It only splits for subjects with an extent separate
    /// from their amount, which is a small set (`writing-desk-fixes.md` §3).
    var scale: Int = 0
    /// **How many of them there are** — 0 for unwritten, up through the Count ladder.
    ///
    /// Written, read back, and consumed by nothing until now. Aimee: *"I should be able to have a
    /// ton of suns or other things. Count should absolutely do something!"*
    var count: Int = 0

    init(id: InstanceID,
         source: PressureSourceID,
         target: PressureTargetID,
         intensity: Intensity = .moderate,
         negatedTargets: Set<PressureTargetID> = [],
         scale: Int = 0,
         count: Int = 0) {
        self.id = id
        self.source = source
        self.target = target
        self.intensity = intensity
        self.negatedTargets = negatedTargets
        self.scale = scale
        self.count = count
    }

    /// Tolerant, per the policy in `Migrations.swift`.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(InstanceID.self, forKey: .id)
        source = try c.decode(PressureSourceID.self, forKey: .source)
        target = try c.decode(PressureTargetID.self, forKey: .target)
        intensity = try c.decodeIfPresent(Intensity.self, forKey: .intensity) ?? .moderate
        negatedTargets = try c.decodeIfPresent(Set<PressureTargetID>.self, forKey: .negatedTargets) ?? []
        scale = try c.decodeIfPresent(Int.self, forKey: .scale) ?? 0
        count = try c.decodeIfPresent(Int.self, forKey: .count) ?? 0
    }

    /// Plain-language reading, for the preview and the page.
    var displayText: String {
        let catalog = ContentCatalog.shared
        let sourceName = catalog.pressureSource(source)?.name ?? source.rawValue
        let targetName = catalog.pressureTarget(target)?.name ?? target.rawValue
        var text = "\(intensity.displayName) \(sourceName) → \(targetName)"
        if !negatedTargets.isEmpty {
            let denied = negatedTargets
                .compactMap { catalog.pressureTarget($0)?.name }
                .sorted()
                .joined(separator: ", ")
            text += ", not \(denied)"
        }
        return text
    }
}

/// The Intensity qualifier. Scales a source's whole contribution, secondaries included.
enum Intensity: String, Codable, CaseIterable, Sendable {
    case absent, faint, moderate, great, overwhelming

    var multiplier: Double {
        switch self {
        case .absent: 0
        case .faint: 0.4
        case .moderate: 1.0
        case .great: 1.6
        case .overwhelming: 2.2
        }
    }

    var displayName: String { rawValue.capitalized }
}
