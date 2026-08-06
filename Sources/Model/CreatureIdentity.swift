import Foundation

/// Naming an animal from what it turned out to be.
///
/// **Stored: the trait vector. Derived at read time: the name** (creature-system-spec §6). Authored
/// **identity regions** are ranges over trait space; a species that sits inside one takes its name,
/// and **anything else gets a composed descriptive name** rather than being forced into the nearest
/// role. *A huge blind armoured thing* reads better than calling it a Tank, and free sampling
/// guarantees these will happen — they're the animals players remember.
///
/// This is also the creature half of the name generator: a composed name is a pure function of the
/// vector, so it is **stable per species** and an anchored world's animals keep their names.
enum CreatureIdentity {

    /// What a vector was recognised as, and how confidently.
    struct Match: Equatable, Sendable {
        /// The region it landed in, or `nil` when nothing fitted and the name was composed.
        var region: IdentityRegion?
        /// 0–1 fit against the best region, whether or not it cleared the threshold.
        var score: Double
        /// What to call it.
        var name: String
        /// Stable key for the bestiary. Region id where matched, slugified name where composed.
        var key: String

        var isComposed: Bool { region == nil }
    }

    // MARK: Matching

    static func match(_ traits: CreatureTraits) -> Match {
        var best: (region: IdentityRegion, score: Double)?
        for region in IdentityRegion.allCases {
            let score = region.fit(traits)
            if score > (best?.score ?? -1) { best = (region, score) }
        }

        if let best, best.score >= Tuning.Life.identityMatchThreshold {
            return Match(region: best.region, score: best.score,
                         name: best.region.displayName, key: best.region.rawValue)
        }
        let composed = composedName(for: traits)
        return Match(region: nil, score: best?.score ?? 0, name: composed, key: slug(composed))
    }

    static func name(for traits: CreatureTraits) -> String { match(traits).name }

    /// Out after dark. Derived from what it senses with rather than authored: a thing that hunts by
    /// touch has no reason to keep daytime hours, and neither has a thing that carries its own light.
    static func isNocturnal(_ traits: CreatureTraits) -> Bool {
        traits.sensory.vision < Tuning.Life.nocturnalVisionCeiling || traits.emanation != nil
    }

    /// How formidable, 1–5. **What the world spent on it**, so a world that grows monstrous things
    /// pays out for monstrous things without anyone authoring a tier.
    static func tier(of traits: CreatureTraits) -> Int {
        max(1, min(5, 1 + Int(traits.appetite / Tuning.Life.appetitePerTier)))
    }

    // MARK: Composed names

    /// `[size] [up to two distinguishing traits] [noun]` — plain words for an animal nobody has a
    /// word for. Deliberately not evocative-by-template: the strangeness should come from the
    /// creature, not from the adjective list.
    static func composedName(for traits: CreatureTraits) -> String {
        var words: [String] = []
        if let size = sizeWord(traits.size) { words.append(size) }
        // Chosen by how striking each trait is, then **reordered into English**: condition before
        // surface before shape before weapon. "A huge blind armoured walker" and "a huge armoured
        // blind walker" pick the same two facts; only one of them reads like a sentence.
        let chosen = distinguishingWords(traits).prefix(2)
            .sorted { $0.order.rawValue < $1.order.rawValue }
        words.append(contentsOf: chosen.map(\.word))
        words.append(noun(for: traits))
        return words.joined(separator: " ")
    }

    /// Where a word sits in an English adjective run.
    private enum WordOrder: Int {
        case condition, surface, shape, weapon
    }

    private static func sizeWord(_ size: Double) -> String? {
        switch size {
        case ..<12: "minute"
        case 12..<28: "small"
        case 28..<62: nil          // ordinary needs no word
        case 62..<80: "large"
        case 80..<92: "huge"
        default: "vast"
        }
    }

    /// Ranked by how far each trait departs from unremarkable, so the two words a creature gets are
    /// the two things you'd actually notice about it.
    private static func distinguishingWords(_ t: CreatureTraits)
        -> [(word: String, weight: Double, order: WordOrder)] {
        var scored: [(word: String, weight: Double, order: WordOrder)] = []
        func note(_ word: String, _ weight: Double, _ order: WordOrder) {
            if weight > 0 { scored.append((word, weight, order)) }
        }

        note("blind", (Tuning.Life.blindVisionCeiling - t.sensory.vision) / 100 * 1.4, .condition)
        if let emanation = t.emanation {
            switch emanation.dominant {
            case .light: note("glowing", emanation.strength / 100 * 1.3, .condition)
            case .heat: note("smouldering", emanation.strength / 100 * 1.3, .condition)
            case .caustic: note("seeping", emanation.strength / 100 * 1.3, .condition)
            }
        }
        if t.isToxic { note("warning-coloured", 0.6, .condition) }

        note(t.finish.schiller > t.finish.shine ? "iridescent" : "glossy",
             (t.finish.lustre - 40) / 100, .surface)
        note("armoured", (t.covering.armourValue - 45) / 100 * 1.2, .surface)
        note("shaggy", (t.covering.insulation - 45) / 100 * (t.covering.hardness < 40 ? 1.1 : 0), .surface)
        note("bare", (Tuning.Life.baselineCoverage - 5 - t.covering.coverage) / 100, .surface)
        note("plumed", (t.ornament - 45) / 100, .surface)
        note("pallid", (24 - t.coloration.depth) / 100, .surface)
        note("dark", (t.coloration.depth - 82) / 100, .surface)

        note("hulking", (t.build - 78) / 100, .shape)
        note("sinuous", (26 - t.build) / 100, .shape)
        note("long-limbed", t.armament.reach == .far ? 0.35 : 0, .shape)
        note("many-limbed", Double(t.appendages.count - 5) / 10, .shape)
        note("limbless", t.appendages.count == 0 && t.appendages.type != .none ? 0.5 : 0, .shape)

        if !t.armament.isUnarmed {
            let weight = (t.armament.total - 60) / 200
            switch t.armament.dominant {
            case .pierce: note("fanged", weight, .weapon)
            case .crush: note("tusked", weight, .weapon)
            case .rend: note("clawed", weight, .weapon)
            }
        }

        return scored.sorted { $0.weight > $1.weight }
    }

    /// The last word. Says how it gets about, since that's the thing you learn first about an
    /// animal you have no name for.
    private static func noun(for t: CreatureTraits) -> String {
        switch t.appendages.type {
        case .finned: return t.build < 35 ? "eel" : "swimmer"
        case .membrane: return "glider"
        case .feathered: return "flier"
        case .none: return t.build < 35 ? "coil" : "shape"
        case .limbed:
            if t.appendages.count >= 6 { return "scuttler" }
            if t.build < 30 { return "creeper" }
            if t.size > 70 { return "walker" }
            return "thing"
        }
    }

    static func slug(_ name: String) -> String {
        name.lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "-", with: "_")
    }
}

/// Authored regions of trait space. **[PLACEHOLDER]** boundaries — creature-system-spec §6 ships
/// eight starters and flags in §10 that whether they read well is the thing to watch.
enum IdentityRegion: String, Codable, CaseIterable, Equatable, Sendable {
    case ambusher, pursuer, tank, grazer, swarmer, apex, drifter, sentinel

    var displayName: String { rawValue }

    /// 0–1. The mean fit across the region's criteria — every criterion has to be roughly satisfied,
    /// so one strong match can't drag an otherwise wrong creature into a name.
    func fit(_ t: CreatureTraits) -> Double {
        let scores = criteria(t)
        guard !scores.isEmpty else { return 0 }
        return scores.reduce(0, +) / Double(scores.count)
    }

    private func criteria(_ t: CreatureTraits) -> [Double] {
        switch self {
        case .ambusher:
            return [band(t.build, 30...70),
                    t.armament.reach == .close ? 1 : 0,
                    t.armament.dominant == .pierce && !t.armament.isUnarmed ? 1 : 0,
                    t.defence == .crypsis ? 1 : 0.2]
        case .pursuer:
            return [band(t.build, 40...72),
                    band(t.size, 35...70),
                    t.armament.reach == .mid ? 1 : 0.2,
                    t.appendages.type == .limbed ? 1 : 0.3,
                    t.armament.isUnarmed ? 0 : 1]
        case .tank:
            return [band(t.size, 62...100),
                    band(t.covering.hardness, 62...100),
                    band(t.covering.coverage, 60...100),
                    band(t.armament.total, 0...55)]
        case .grazer:
            return [t.armament.isUnarmed ? 1 : 0,
                    band(t.covering.coverage, 30...75),
                    band(t.size, 40...85)]
        case .swarmer:
            return [band(t.size, 0...22),
                    band(t.armament.total, 0...60),
                    t.armament.delivery == .multi || t.armament.delivery == .area ? 1 : 0.4]
        case .apex:
            return [band(t.size, 65...100),
                    band(t.armament.total, 110...300),
                    band(t.build, 40...75)]
        case .drifter:
            return [band(t.boneDensity, 0...28),
                    t.appendages.type == .finned || t.appendages.type == .membrane ? 1 : 0,
                    band(t.build, 0...36)]
        case .sentinel:
            return [band(t.size, 35...72),
                    band(t.covering.hardness, 58...100),
                    t.armament.reach == .far ? 1 : 0]
        }
    }

    /// 1 inside the range, tapering to 0 a tolerance beyond either end. A hard in/out test makes
    /// every boundary a cliff, and the whole point of a threshold is that near misses fall through
    /// to a composed name rather than snapping to the nearest role.
    private func band(_ value: Double, _ range: ClosedRange<Double>) -> Double {
        if range.contains(value) { return 1 }
        let distance = value < range.lowerBound ? range.lowerBound - value : value - range.upperBound
        return max(0, 1 - distance / Tuning.Life.identityBandTolerance)
    }
}
