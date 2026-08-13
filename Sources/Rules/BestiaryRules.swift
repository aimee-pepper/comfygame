import Foundation

/// **How remarkable an animal is**, measured two ways.
///
/// Session 3 §4a: *"This is where computed-rarity percentiles live (**personal + global, both
/// shown**)."* Only the personal half existed, and it was never displayed anywhere — the bestiary
/// had no screen at all, so identity regions, specimens, traits and qualifiers were recorded into a
/// save nobody could read.
///
/// **The two halves do different jobs, which is why the spec asked for both.** Personal carries the
/// early game: *the finest pelt you've recovered* means something when you've seen four. Global is
/// what keeps a late find objectively meaningful once you've seen hundreds and your own
/// distribution has drifted up — without it, "rare" quietly stops meaning anything the longer you
/// play, which is precisely the failure two percentiles exist to prevent.
enum BestiaryRules {

    /// What a specimen can be ranked by. Each is a number you can point at on the animal.
    enum Measure: String, CaseIterable, Identifiable, Sendable {
        case size, covering, armament, ornament, bone

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .size: "Size"
            case .covering: "Covering"
            case .armament: "Armament"
            case .ornament: "Ornament"
            case .bone: "Build"
            }
        }

        /// The superlative a top-percentile specimen earns, in the game's own voice.
        var superlative: String {
            switch self {
            case .size: "largest"
            case .covering: "best covered"
            case .armament: "best armed"
            case .ornament: "finest"
            case .bone: "heaviest built"
            }
        }

        func value(of traits: CreatureTraits) -> Double {
            switch self {
            case .size: traits.size
            case .covering: traits.covering.armourValue
            case .armament: traits.armament.total
            case .ornament: traits.ornament
            case .bone: traits.boneDensity
            }
        }
    }

    // MARK: The global distribution

    /// **What nature produces**, sampled from the generator itself rather than authored.
    ///
    /// Deliberately not a hand-written table: the creature system derives everything from world
    /// readings, so the only honest reference is what the readings actually make. Sampling it means
    /// the scale re-calibrates itself the day somebody adds a focus or moves a life cap — the same
    /// property that made emergent stability worth having.
    ///
    /// Computed once and held in memory. It's a pure function of content, so it belongs to the
    /// build rather than to the save, and recomputing it per lookup would sample a thousand worlds
    /// to draw one row.
    private static let reference: [Measure: [Double]] = buildReference()

    private static func buildReference() -> [Measure: [Double]] {
        var samples: [Measure: [Double]] = [:]
        for seed in UInt64(1)...Tuning.Discovery.globalSampleWorlds {
            let readings = PressureRules.resolve([], fillingUnwrittenWith: seed)
            for species in LifeRules.cast(for: readings, seed: seed) {
                for measure in Measure.allCases {
                    samples[measure, default: []].append(measure.value(of: species.traits))
                }
            }
        }
        return samples.mapValues { $0.sorted() }
    }

    /// Where this animal sits against **everything the worlds can grow**, 0–1.
    ///
    /// Across all species rather than within its own kind, on purpose: the global claim is *"this is
    /// a big animal"*, not *"this is a big one of these"* — the second question is what the personal
    /// percentile already answers, and asking it twice would be one number printed twice.
    static func globalPercentile(of traits: CreatureTraits, by measure: Measure) -> Double {
        let population = reference[measure] ?? []
        guard population.count > 1 else { return 1 }
        let value = measure.value(of: traits)
        // Binary search: the reference is sorted and this runs per row of the bestiary.
        var low = 0, high = population.count
        while low < high {
            let mid = (low + high) / 2
            if population[mid] < value { low = mid + 1 } else { high = mid }
        }
        return min(1, max(0, Double(low) / Double(population.count - 1)))
    }

    /// Where it sits against the ones **you** have met of its kind.
    static func personalPercentile(of specimen: SpecimenRecord, by measure: Measure,
                                   in discovery: DiscoveryLog) -> Double {
        discovery.percentile(of: specimen) { measure.value(of: $0.traits) }
    }

    /// How many of its kind that percentile was measured against. **Shown beside it**, because a
    /// percentile over two animals is not the same claim as one over forty, and a bare "top 5%" that
    /// silently means "the better of the two I've seen" is the kind of number that teaches a player
    /// to distrust every other number on the screen.
    static func peerCount(of specimen: SpecimenRecord, in discovery: DiscoveryLog) -> Int {
        discovery.specimens(of: specimen.identityKey).count
    }

    // MARK: What the bestiary shows

    /// One kind of animal you've met, with the specimens you've kept of it.
    struct Entry: Identifiable, Sendable {
        var id: String { identityKey }
        var identityKey: String
        var name: String
        var icon: String
        var firstSeenRunIndex: Int?
        var timesEncountered: Int
        var specimens: [SpecimenRecord]
        var apexSightings: Int
        var isApexSpecies: Bool { apexSightings > 0 }

        /// A factual, stable featured record. There is no single cross-trait "best" measure.
        var latest: SpecimenRecord? { specimens.last }
        /// Decode/source compatibility for older UI revisions; do not present this as a superlative.
        var finest: SpecimenRecord? { latest }
    }

    /// Everything you've met, best-known first.
    static func entries(in discovery: DiscoveryLog) -> [Entry] {
        discovery.species
            .filter { $0.value.firstSeenRunIndex != nil }
            .map { key, record in
                let specimens = discovery.specimens(of: key)
                let traits = specimens.last?.traits
                return Entry(
                    identityKey: key,
                    name: traits.map { CreatureIdentity.name(for: $0) } ?? key.replacingOccurrences(of: "-", with: " "),
                    icon: traits.map(icon(for:)) ?? "pawprint",
                    firstSeenRunIndex: record.firstSeenRunIndex,
                    timesEncountered: record.timesEncountered,
                    specimens: specimens,
                    apexSightings: discovery.apexSightings(of: key).count
                )
            }
            .sorted { $0.name < $1.name }
    }

    /// **[PLACEHOLDER]** — a shape, from what the animal is, until there's art.
    static func icon(for traits: CreatureTraits) -> String {
        if traits.emanation != nil { return "sparkles" }
        if traits.isToxic { return "exclamationmark.triangle.fill" }
        if traits.armament.reach == .far { return "arrow.up.forward" }
        if traits.covering.armourValue > 50 { return "shield.fill" }
        if traits.size > 60 { return "tortoise.fill" }
        if traits.build < 35 { return "hare.fill" }
        return "pawprint.fill"
    }

    /// How a percentile should read in a sentence. Nil when it isn't worth remarking on — most
    /// animals are ordinary and saying so about each of them is noise.
    static func remark(personal: Double, peers: Int, global: Double, measure: Measure) -> String? {
        if peers > 1, personal >= Tuning.Discovery.remarkablePercentile {
            return "the \(measure.superlative) of \(peers) you've seen"
        }
        if global >= Tuning.Discovery.remarkablePercentile {
            return "\(measure.superlative) as they come"
        }
        return nil
    }
}
