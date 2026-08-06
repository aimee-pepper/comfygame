import Foundation

/// Naming a generated thing after the thing it turned out to be.
///
/// `[qualifier] [kind]` — *ashen bulwark*, *blind courser* (name-generation-spec §1). The **kind** is
/// the identity class, small and authored; the **qualifier** comes from the trait that most sets
/// this one apart, and is what makes two bulwarks different things.
///
/// **Descriptive rather than invented on purpose.** *Krellith* carries no information; read *blind
/// courser* and you already know it's fast and hunts without eyes. A clue that mentions one is then
/// useful before you've ever met it.
///
/// **Distinctiveness is measured against the world's own cast, not against everything** (§2). On a
/// world where everything is armoured, "armoured" says nothing — what's distinctive there might be
/// that this one is small. So the same trait vector can be named differently in two worlds, which is
/// correct: distinctiveness is relative.
///
/// **[PLACEHOLDER] vocabulary.** The word lists are voice rather than mechanism, and the spec asks
/// (§8.5) whether they're Aimee's to write. Logged in questions-for-design; the mechanism won't
/// change if every word below is replaced.
enum Naming {

    /// A measurable direction a creature can be unusual in.
    enum Axis: String, CaseIterable, Sendable {
        case size, build, hardness, length, coverage, bone, armament, reach
        case depth, patterning, ornament, vision, nonVisual, emanation

        func value(of t: CreatureTraits) -> Double {
            switch self {
            case .size: t.size
            case .build: t.build
            case .hardness: t.covering.hardness
            case .length: t.covering.length
            case .coverage: t.covering.coverage
            case .bone: t.boneDensity
            case .armament: t.armament.total
            case .reach: switch t.armament.reach { case .close: 10; case .mid: 50; case .far: 90 }
            case .depth: t.coloration.depth
            case .patterning: t.coloration.patterning
            case .ornament: t.ornament
            case .vision: t.sensory.vision
            case .nonVisual: t.sensory.nonVisual
            case .emanation: t.emanation?.strength ?? 0
            }
        }

        /// Words for being *below* the world's average on this axis, mildest first.
        var low: [String] {
            switch self {
            case .size: ["lesser", "slight", "dwarf"]
            case .build: ["lithe", "slender", "serpentine"]
            case .hardness: ["soft", "yielding"]
            case .length: ["cropped", "shorn"]
            case .coverage: ["bare", "naked"]
            case .bone: ["light", "hollow"]
            case .armament: ["meek", "unarmed"]
            case .reach: ["short-limbed", "stub-limbed"]
            case .depth: ["pale", "ashen", "bleached"]
            case .patterning: ["plain", "drab"]
            case .ornament: []
            case .vision: ["dim-eyed", "blind"]
            case .nonVisual: []
            case .emanation: []
            }
        }

        /// Words for being *above* it, mildest first.
        var high: [String] {
            switch self {
            case .size: ["great", "vast", "monstrous"]
            case .build: ["heavy", "hulking"]
            case .hardness: ["scaled", "carapaced", "ironbound"]
            case .length: ["shaggy", "mantled"]
            case .coverage: ["clad", "plated"]
            case .bone: ["dense", "leaden"]
            case .armament: ["fanged", "barbed", "savage"]
            case .reach: ["long-limbed", "reaching"]
            case .depth: ["dusk", "sable"]
            case .patterning: ["banded", "gaudy"]
            case .ornament: ["plumed", "crowned", "gilded"]
            case .vision: ["keen", "wide-eyed"]
            case .nonVisual: ["whiskered", "questing"]
            case .emanation: ["glimmering", "burning"]
            }
        }
    }

    /// What a population is like on average, so a member of it can be measured against it.
    struct Context: Equatable, Sendable {
        var mean: [Axis: Double]

        /// The unremarkable middle, for anything named with no population to compare against —
        /// a specimen in the bestiary long after its world is gone.
        static let none = Context(mean: Dictionary(uniqueKeysWithValues:
            Axis.allCases.map { ($0, Tuning.Pressure.scaleMaximum / 2) }))

        init(mean: [Axis: Double]) { self.mean = mean }

        init(of population: [CreatureTraits]) {
            guard !population.isEmpty else { self = .none; return }
            mean = Dictionary(uniqueKeysWithValues: Axis.allCases.map { axis in
                (axis, population.reduce(0) { $0 + axis.value(of: $1) } / Double(population.count))
            })
        }
    }

    /// The axes this creature departs from its world on, most striking first.
    ///
    /// Skips any axis with no word for the direction it went — a creature that is *less* ornamented
    /// than average is not remarkable for it, because ornament's absence is the default.
    static func distinctions(of traits: CreatureTraits, in context: Context,
                             minimumDeviation: Double? = nil) -> [(axis: Axis, word: String)] {
        let bar = minimumDeviation ?? Tuning.Naming.minimumDeviation
        var scored: [(axis: Axis, word: String, magnitude: Double)] = []
        for axis in Axis.allCases {
            let deviation = axis.value(of: traits) - (context.mean[axis] ?? 50)
            let magnitude = abs(deviation)
            guard magnitude >= bar else { continue }
            let band: [String] = deviation < 0 ? axis.low : axis.high
            guard !band.isEmpty else { continue }
            // Further out earns a stronger word.
            let step = min(band.count - 1, Int(magnitude / Tuning.Naming.deviationPerWord))
            scored.append((axis, band[step], magnitude))
        }
        // Ties break on the axis's own name so a result never depends on iteration order.
        scored.sort {
            $0.magnitude != $1.magnitude
                ? $0.magnitude > $1.magnitude
                : $0.axis.rawValue < $1.axis.rawValue
        }
        return scored.map { (axis: $0.axis, word: $0.word) }
    }

    /// The single word this thing goes by, or nil when it is thoroughly ordinary for its world.
    ///
    /// **Never number them** (§3). A world with two shaggy browsers gets a shaggy browser and a
    /// pale browser, by taking the second one's next-most-distinctive trait — and if it is so
    /// nearly identical that nothing clears the bar, the bar comes down rather than the two of them
    /// ending up sharing a name. "Browser 2" is a spreadsheet.
    /// `insisting` is for the collision case: come down off the bar until *something* separates
    /// this one from the animal it would otherwise share a name with.
    static func qualifier(for traits: CreatureTraits, in context: Context,
                          avoiding taken: Set<String> = [],
                          insisting: Bool = false) -> String? {
        let options = distinctions(of: traits, in: context)
        if let free = options.first(where: { !taken.contains($0.word) }) { return free.word }
        guard insisting else { return options.first?.word }

        let anyDifference = distinctions(of: traits, in: context, minimumDeviation: 0)
        return anyDifference.first { !taken.contains($0.word) }?.word ?? options.first?.word
    }
}
