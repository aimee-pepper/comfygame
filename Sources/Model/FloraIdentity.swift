import Foundation

/// Naming a plant from what it turned out to be.
///
/// **Identity is derived, same as creatures** (`flora-system-spec.md` §4): authored regions are
/// ranges over trait space, a species that sits inside one takes its name, and **anything else gets a
/// composed descriptive name** rather than being forced into the nearest role. *A waxy sprawling
/// crust* reads better than calling it a mat, and free sampling guarantees these will happen.
enum FloraIdentity {

    /// What a vector was recognised as, and how confidently.
    struct Match: Equatable, Sendable {
        var region: FloraRegion?
        /// 0–1 fit against the best region, whether or not it cleared the threshold.
        var score: Double
        var name: String
        /// Stable key, for anything that wants to count kinds of plant.
        var key: String
        /// The adjective, kept separately so harvested material can inherit it: fibre off a
        /// *thorned bramble* is *thorned fibre*, the same inheritance creature loot has.
        var qualifier: String?

        var isComposed: Bool { region == nil }
    }

    // MARK: Matching

    /// `[qualifier] [kind]`. The kind is the region; the qualifier is what sets this one apart
    /// **from the rest of its world**, so two brambles are different things.
    static func match(_ traits: FloraTraits,
                      in context: Context = .none,
                      avoiding taken: Set<String> = []) -> Match {
        var best: (region: FloraRegion, score: Double)?
        for region in FloraRegion.allCases {
            let score = region.fit(traits)
            if score > (best?.score ?? -1) { best = (region, score) }
        }

        let qualifier = Self.qualifier(for: traits, in: context, avoiding: taken)

        if let best, best.score >= Tuning.Flora.identityMatchThreshold {
            let kind = best.region.displayName
            let name = qualifier.map { "\($0) \(kind)" } ?? kind
            return Match(region: best.region, score: best.score, name: name,
                         key: best.region.rawValue, qualifier: qualifier)
        }
        // Nothing has a word for this one, so describe it. Still qualified — the fallback must
        // never be a bare "plant".
        let composed = composedName(for: traits)
        let leading = composed.split(separator: " ").dropLast().first.map(String.init)
        return Match(region: nil, score: best?.score ?? 0, name: composed,
                     key: CreatureIdentity.slug(composed), qualifier: leading ?? qualifier)
    }

    static func name(for traits: FloraTraits, in context: Context = .none) -> String {
        match(traits, in: context).name
    }

    /// Names a whole cast at once, so **no two of a world's plants end up called the same thing**.
    /// The same collision rule the animals get: insist rather than number.
    static func names(for cast: [Flora]) -> [InstanceID: Match] {
        let context = Context(of: cast.map(\.traits))
        var takenWords: Set<String> = []
        var takenNames: Set<String> = []
        var named: [InstanceID: Match] = [:]

        for flora in cast.sorted(by: { $0.id.rawValue < $1.id.rawValue }) {
            var match = match(flora.traits, in: context, avoiding: takenWords)
            if takenNames.contains(match.name),
               let forced = qualifier(for: flora.traits, in: context,
                                      avoiding: takenWords, insisting: true) {
                match.qualifier = forced
                match.name = match.region.map { "\(forced) \($0.displayName)" }
                    ?? "\(forced) \(match.name)"
            }
            if let qualifier = match.qualifier { takenWords.insert(qualifier) }
            takenNames.insert(match.name)
            named[flora.id] = match
        }
        return named
    }

    // MARK: Distinctiveness

    /// A direction a plant can be unusual in, for its own world.
    enum Axis: String, CaseIterable, Sendable {
        case stature, woody, fibrous, fleshy, defence, depth, lustre

        func value(of t: FloraTraits) -> Double {
            switch self {
            case .stature: t.stature
            case .woody: t.tissue.woody
            case .fibrous: t.tissue.fibrous
            case .fleshy: t.tissue.fleshy
            case .defence: t.defence
            case .depth: t.coloration.depth
            case .lustre: t.finish.lustre
            }
        }

        /// Words for being *below* the world's average, mildest first.
        var low: [String] {
            switch self {
            case .stature: ["low", "creeping", "prostrate"]
            case .woody: ["soft", "pithy"]
            case .fibrous: ["brittle"]
            case .fleshy: ["dry", "papery"]
            case .defence: ["open", "defenceless"]
            case .depth: ["pale", "bleached"]
            case .lustre: ["dull"]
            }
        }

        /// …and above it.
        var high: [String] {
            switch self {
            case .stature: ["tall", "towering"]
            case .woody: ["woody", "ironbarked"]
            case .fibrous: ["stringy", "cabled"]
            case .fleshy: ["swollen", "gorged"]
            case .defence: ["thorned", "barbed", "savage"]
            case .depth: ["dark", "sable"]
            case .lustre: ["waxy", "glassy"]
            }
        }
    }

    /// What a world's flora is like on average, so one of them can be measured against it.
    struct Context: Equatable, Sendable {
        var mean: [Axis: Double]

        /// The unremarkable middle, for anything named with no population to compare against.
        static let none = Context(mean: Dictionary(uniqueKeysWithValues:
            Axis.allCases.map { ($0, Tuning.Pressure.scaleMaximum / 2) }))

        init(mean: [Axis: Double]) { self.mean = mean }

        init(of population: [FloraTraits]) {
            guard !population.isEmpty else { self = .none; return }
            mean = Dictionary(uniqueKeysWithValues: Axis.allCases.map { axis in
                (axis, population.reduce(0) { $0 + axis.value(of: $1) } / Double(population.count))
            })
        }
    }

    static func distinctions(of traits: FloraTraits, in context: Context,
                             minimumDeviation: Double? = nil) -> [(axis: Axis, word: String)] {
        let bar = minimumDeviation ?? Tuning.Naming.minimumDeviation
        var scored: [(axis: Axis, word: String, magnitude: Double)] = []
        for axis in Axis.allCases {
            let deviation = axis.value(of: traits) - (context.mean[axis] ?? 50)
            let magnitude = abs(deviation)
            guard magnitude >= bar else { continue }
            let band: [String] = deviation < 0 ? axis.low : axis.high
            guard !band.isEmpty else { continue }
            let step = min(band.count - 1, Int(magnitude / Tuning.Naming.deviationPerWord))
            scored.append((axis, band[step], magnitude))
        }
        scored.sort {
            $0.magnitude != $1.magnitude
                ? $0.magnitude > $1.magnitude
                : $0.axis.rawValue < $1.axis.rawValue
        }
        return scored.map { (axis: $0.axis, word: $0.word) }
    }

    static func qualifier(for traits: FloraTraits, in context: Context,
                          avoiding taken: Set<String> = [],
                          insisting: Bool = false) -> String? {
        let options = distinctions(of: traits, in: context)
        if let free = options.first(where: { !taken.contains($0.word) }) { return free.word }
        guard insisting else { return options.first?.word }
        let anyDifference = distinctions(of: traits, in: context, minimumDeviation: 0)
        return anyDifference.first { !taken.contains($0.word) }?.word ?? options.first?.word
    }

    // MARK: Composed names

    /// `[height] [up to two distinguishing traits] [noun]` — plain words for a plant nobody has a
    /// word for. The noun says how it makes its living, since that is the strangest thing about
    /// anything growing in a lightless world.
    static func composedName(for traits: FloraTraits) -> String {
        var words: [String] = []
        if let height = heightWord(traits.stature) { words.append(height) }
        words.append(contentsOf: distinguishingWords(traits).prefix(2).map(\.word))
        words.append(noun(for: traits))
        return words.joined(separator: " ")
    }

    private static func heightWord(_ stature: Double) -> String? {
        switch stature {
        case ..<12: "flat"
        case 12..<30: "low"
        case 30..<62: nil          // ordinary needs no word
        case 62..<82: "tall"
        default: "towering"
        }
    }

    private static func distinguishingWords(_ t: FloraTraits) -> [(word: String, weight: Double)] {
        var scored: [(word: String, weight: Double)] = []
        func note(_ word: String, _ weight: Double) {
            if weight > 0 { scored.append((word, weight)) }
        }

        if t.isDefended {
            switch t.defenceType {
            case .physical: note("thorned", (t.defence - 30) / 100 * 1.2)
            case .chemical: note("acrid", (t.defence - 30) / 100 * 1.2)
            case .active: note("restless", (t.defence - 30) / 100 * 1.6)
            }
        }
        switch t.tissue.dominant {
        case .woody: note("woody", (t.tissue.total - 45) / 100)
        case .fibrous: note("stringy", (t.tissue.total - 45) / 100)
        case .fleshy: note("swollen", (t.tissue.total - 45) / 100)
        }
        note("waxy", (t.finish.lustre - 40) / 100)
        note("pale", (24 - t.coloration.depth) / 100)
        note("dark", (t.coloration.depth - 82) / 100)
        note("sprawling", t.habit == .spreading ? 0.3 : 0)
        note("lone", t.habit == .solitary ? 0.28 : 0)

        return scored.sorted { $0.weight > $1.weight }
    }

    /// The last word. **How it eats**, because that is what you learn first about a plant in a
    /// world that has no sun.
    private static func noun(for t: FloraTraits) -> String {
        switch t.metabolism {
        case .chemosynthetic: return t.stature < 25 ? "crust" : "chimney-growth"
        case .fungal: return t.stature < 25 ? "mould" : "fungus"
        case .photosynthetic:
            if t.stature > 70 { return "tree" }
            if t.stature > 35 { return "shrub" }
            return t.tissue.dominant == .fleshy ? "cushion" : "turf"
        }
    }
}

/// Authored regions of flora trait space. **[PLACEHOLDER]** boundaries — the seven the spec names
/// (`flora-system-spec.md` §4), and §9.2 flags that whether a cast is worth having at all is the
/// thing to watch.
enum FloraRegion: String, Codable, CaseIterable, Equatable, Sendable {
    case bramble, canopyTree, succulent, mat, fungalBloom, reed, crust

    var displayName: String {
        switch self {
        case .canopyTree: "canopy tree"
        case .fungalBloom: "fungal bloom"
        default: rawValue
        }
    }

    /// 0–1. The mean fit across the region's criteria, so one strong match can't drag an otherwise
    /// wrong plant into a name.
    func fit(_ t: FloraTraits) -> Double {
        let scores = criteria(t)
        guard !scores.isEmpty else { return 0 }
        return scores.reduce(0, +) / Double(scores.count)
    }

    private func criteria(_ t: FloraTraits) -> [Double] {
        switch self {
        case .bramble:
            return [band(t.stature, 25...60),
                    band(t.defence, 45...100),
                    t.defenceType == .physical ? 1 : 0.2,
                    t.tissue.dominant == .fibrous || t.tissue.dominant == .woody ? 1 : 0.3]
        // **A tree and a succulent are photosynthetic by definition.** Scoring the wrong metabolism
        // as a near-miss rather than a disqualification let a chemosynthetic crust be named a
        // succulent on the strength of being short and fleshy, which is the one thing the
        // metabolism axis must never let happen.
        case .canopyTree:
            return [band(t.stature, 70...100),
                    t.tissue.dominant == .woody ? 1 : 0,
                    band(t.tissue.total, 45...100),
                    t.metabolism == .photosynthetic ? 1 : 0]
        case .succulent:
            return [band(t.stature, 0...40),
                    t.tissue.dominant == .fleshy ? 1 : 0,
                    band(t.tissue.total, 35...100),
                    t.metabolism == .photosynthetic ? 1 : 0]
        case .mat:
            return [band(t.stature, 0...18),
                    band(t.defence, 0...35),
                    t.habit == .spreading ? 1 : 0.3]
        case .fungalBloom:
            return [t.metabolism == .fungal ? 1 : 0,
                    band(t.stature, 10...55),
                    t.tissue.dominant == .fleshy ? 1 : 0.4]
        case .reed:
            return [band(t.stature, 45...80),
                    t.tissue.dominant == .fibrous ? 1 : 0,
                    band(t.defence, 0...30),
                    t.habit == .clustered ? 1 : 0.4,
                    t.metabolism == .photosynthetic ? 1 : 0]
        case .crust:
            return [t.metabolism == .chemosynthetic ? 1 : 0.1,
                    band(t.stature, 0...15),
                    band(t.tissue.total, 0...40)]
        }
    }

    /// 1 inside the range, tapering to 0 a tolerance beyond either end — near misses fall through
    /// to a composed name rather than snapping to the nearest role.
    private func band(_ value: Double, _ range: ClosedRange<Double>) -> Double {
        if range.contains(value) { return 1 }
        let distance = value < range.lowerBound ? range.lowerBound - value : value - range.upperBound
        return max(0, 1 - distance / Tuning.Flora.identityBandTolerance)
    }
}
