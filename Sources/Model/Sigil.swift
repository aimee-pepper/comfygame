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

    init(id: InstanceID,
         source: PressureSourceID,
         target: PressureTargetID,
         intensity: Intensity = .moderate,
         negatedTargets: Set<PressureTargetID> = []) {
        self.id = id
        self.source = source
        self.target = target
        self.intensity = intensity
        self.negatedTargets = negatedTargets
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
