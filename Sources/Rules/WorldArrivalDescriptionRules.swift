import Foundation

enum WorldArrivalDescriptionRules {
    enum Error: Swift.Error, Equatable {
        case malformedTerrain, malformedFlora, malformedEnvironment
        case unknownGround, unknownScope, unknownContribution, missingKnownLabel, missingPageOrder, overlong
    }

    struct TerrainSummary: Equatable {
        var wetTileCount: Int
        var deepWaterTileCount: Int
        var nonChasmTileCount: Int
    }

    struct EnvironmentSummary: Equatable {
        var illuminationBand: String
        var suspendedMedium: String
        var suspendedDensity: String
        var precipitation: String
        var precipitationIntensity: String
        var floraCoverageBand: String
        var floraHabit: String
    }

    static func describe(_ receipt: WorldArrivalSceneReceipt.Payload,
                         terrain: TerrainSummary,
                         environment: EnvironmentSummary) throws -> String {
        let ground = try groundToken(receipt.dominantGround)
        let water = try waterBand(terrain)
        try validate(environment)
        let scoped = try receipt.causalVisualFacts.map { fact -> WorldArrivalSceneReceipt.CausalVisualFact in
            guard ["none", "increased", "reduced", "reshaped"].contains(fact.contributionKind) else {
                throw Error.unknownContribution
            }
            guard ["ground", "water", "flora", "light", "atmosphere"].contains(fact.visibleScope) else {
                throw Error.unknownScope
            }
            return fact
        }
        let eligible = try scoped.filter {
            guard $0.contributionKind != "none" else { return false }
            guard $0.markDisplayName?.isEmpty == false else { return false }
            guard $0.sourcePageOrder != nil else {
                throw Error.missingPageOrder
            }
            return true
        }.sorted {
            if $0.sourcePageOrder != $1.sourcePageOrder {
                return ($0.sourcePageOrder ?? 0) < ($1.sourcePageOrder ?? 0)
            }
            return scopeOrder($0.visibleScope) < scopeOrder($1.visibleScope)
        }
        let structural = eligible.first {
            $0.contributionKind == "reshaped"
                && ($0.visibleScope == "ground" || $0.visibleScope == "water")
                && ["plains", "archipelago", "caverns"].contains($0.markID)
        }
        let first = firstSentence(ground: ground, water: water, structuralMark: structural?.markID)
        var selected = Array(eligible.prefix(2))
        var second = try secondSentence(receipt, environment: environment, selected: selected)
        var result = "\(first) \(second)"
        if wordCount(result) > 55, selected.count == 2 {
            selected.removeLast()
            second = try secondSentence(receipt, environment: environment, selected: selected)
            result = "\(first) \(second)"
        }
        if wordCount(result) > 55 {
            second = environmentalSentence(environment)
            result = "\(first) \(second)"
        }
        if wordCount(result) < 18 {
            second = second.dropLast() + ", while the ground beyond the entry remains open to exploration."
            result = "\(first) \(second)"
        }
        guard wordCount(result) <= 55 else { throw Error.overlong }
        return result
    }

    private enum WaterBand: Equatable {
        case dry, scatteredPools(hasDeepWater: Bool), wetHollows, mixedDepth, waterDominant
    }

    private static func waterBand(_ summary: TerrainSummary) throws -> WaterBand {
        guard summary.nonChasmTileCount > 0,
              summary.wetTileCount >= 0,
              summary.deepWaterTileCount >= 0,
              summary.deepWaterTileCount <= summary.wetTileCount else {
            throw Error.malformedTerrain
        }
        guard summary.wetTileCount > 0 else { return .dry }
        let wetShare = Double(summary.wetTileCount) / Double(summary.nonChasmTileCount)
        let deepShare = Double(summary.deepWaterTileCount) / Double(summary.wetTileCount)
        if wetShare <= 0.08 { return .scatteredPools(hasDeepWater: summary.deepWaterTileCount > 0) }
        if wetShare <= 0.35 { return deepShare < 0.25 ? .wetHollows : .mixedDepth }
        return .waterDominant
    }

    private static func groundToken(_ ground: GroundType) throws -> String {
        switch ground {
        case .stone: "stone"
        case .soil: "earthen ground"
        case .sand: "sandy ground"
        case .ice: "ice"
        case .ash: "ash-covered ground"
        case .rubble: "broken stone"
        case .mud: "muddy ground"
        case .growth: "tall growth"
        case .groundcover: "low ground cover"
        case .water, .deepWater, .chasm: throw Error.unknownGround
        }
    }

    private static func firstSentence(ground: String, water: WaterBand,
                                      structuralMark: String?) -> String {
        if structuralMark == "plains" {
            return "Broad \(ground) \(ending(water, kind: "plains"))"
        }
        if structuralMark == "archipelago" {
            return "\(capitalized(ground)) shelves \(ending(water, kind: "archipelago"))"
        }
        if structuralMark == "caverns" {
            return "\(capitalized(ground)) closes around \(ending(water, kind: "caverns"))"
        }
        switch water {
        case .dry: return "\(capitalized(ground)) stretches across the visible ground."
        case .scatteredPools(let hasDeep):
            return "\(capitalized(ground)) runs between \(scatteredWater(hasDeep))."
        case .wetHollows: return "\(capitalized(ground)) borders a series of wet hollows."
        case .mixedDepth: return "\(capitalized(ground)) breaks around shallow and deep water."
        case .waterDominant: return "Patches of \(ground) rise among shallow and deep water."
        }
    }

    private static func ending(_ water: WaterBand, kind: String) -> String {
        switch (kind, water) {
        case ("plains", .dry): "stretches into the distance."
        case ("plains", .scatteredPools(let hasDeep)): "runs between \(scatteredWater(hasDeep))."
        case ("plains", .wetHollows): "runs around wet hollows."
        case ("plains", .mixedDepth): "runs between shallow and deep water."
        case ("plains", .waterDominant): "forms a few broad islands."
        case ("archipelago", .dry): "break across the visible ground."
        case ("archipelago", .scatteredPools(let hasDeep)): "break around \(scatteredWater(hasDeep))."
        case ("archipelago", .wetHollows): "break around wet hollows."
        case ("archipelago", .mixedDepth): "break a wide run of shallow and deep water."
        case ("archipelago", .waterDominant): "rise as islands from shallow and deep water."
        case ("caverns", .dry): "narrow paths."
        case ("caverns", .scatteredPools(let hasDeep)): "narrow paths and \(scatteredWater(hasDeep))."
        case ("caverns", .wetHollows), ("caverns", .mixedDepth): "narrow paths and wet hollows."
        case ("caverns", .waterDominant): "forms chambers above shallow and deep water."
        default: "stretches across the visible ground."
        }
    }

    private static func scatteredWater(_ hasDeepWater: Bool) -> String {
        hasDeepWater ? "scattered pools of shallow and deep water" : "shallow pools"
    }

    private static func secondSentence(_ receipt: WorldArrivalSceneReceipt.Payload,
                                       environment: EnvironmentSummary,
                                       selected: [WorldArrivalSceneReceipt.CausalVisualFact]) throws -> String {
        guard !selected.isEmpty else { return environmentalSentence(environment) }
        let clauses = try selected.map { fact -> String in
            "Your \(try knownDisplayName(fact)) mark \(try verb(fact, environment: environment))"
        }
        if clauses.count == 2 {
            return "\(clauses[0]), while your \(try knownDisplayName(selected[1])) mark \(try verb(selected[1], environment: environment))."
        }
        let fragment = pairedEnvironmentalFragment(environment, dominantGround: receipt.dominantGround)
        return fragment.map { "\(clauses[0]), while \($0)." } ?? "\(clauses[0])."
    }

    private static func verb(_ fact: WorldArrivalSceneReceipt.CausalVisualFact,
                             environment: EnvironmentSummary) throws -> String {
        let key = "\(fact.markID)|\(fact.visibleScope)|\(fact.contributionKind)"
        switch key {
        case "plains|ground|reshaped": return "opened the terrain"
        case "verdant|flora|increased": return "spread low growth farther along the few wet and stony edges"
        case "archipelago|water|reshaped": return "divided the route"
        case "caverns|ground|reshaped": return "shaped the enclosure"
        case "common_ore|ground|increased": return "made ore more plentiful"
        default: break
        }
        switch (fact.visibleScope, fact.contributionKind) {
        case ("ground", "reshaped"): return "reshaped the ground"
        case ("ground", "increased"): return "made that ground more prevalent"
        case ("ground", "reduced"): return "made that ground less prevalent"
        case ("water", "reshaped"): return "reshaped the water"
        case ("water", "increased"): return "made water more prevalent"
        case ("water", "reduced"): return "made water less prevalent"
        case ("flora", "reshaped"): return "reshaped \(try floraPhrase(environment))"
        case ("flora", "increased"): return "spread \(try floraPhrase(environment)) farther"
        case ("flora", "reduced"): return "left less \(try floraPhrase(environment))"
        case ("light", "reshaped"): return "changed the light"
        case ("light", "increased"): return "strengthened the light"
        case ("light", "reduced"): return "subdued the light"
        case ("atmosphere", "reshaped"): return "changed the air"
        case ("atmosphere", "increased"): return "strengthened that condition in the air"
        case ("atmosphere", "reduced"): return "weakened that condition in the air"
        default: throw Error.unknownContribution
        }
    }

    private static func floraPhrase(_ environment: EnvironmentSummary) throws -> String {
        switch (environment.floraCoverageBand, environment.floraHabit) {
        case ("sparse", _): return "sparse growth"
        case ("present", "solitary"): return "scattered growth"
        case ("present", "clustered"): return "clustered growth"
        case ("present", "spreading"): return "spreading growth"
        case ("present", _): return "growth across the open ground"
        case ("abundant", "solitary"): return "growth across most open ground"
        case ("abundant", "clustered"): return "dense clustered growth"
        case ("abundant", "spreading"): return "dense spreading growth"
        case ("abundant", _): return "dense growth"
        default: throw Error.malformedFlora
        }
    }

    private static func environmentalSentence(_ environment: EnvironmentSummary) -> String {
        if environment.suspendedDensity == "heavy" || environment.suspendedDensity == "dense" {
            switch environment.suspendedMedium {
            case "smoke": return "Smoke hangs thickly across the farther ground."
            case "airborneAsh": return "Airborne ash forms heavy banks across the farther ground."
            case "mist": return "Mist gathers in broad banks beyond the entry."
            case "miasma": return "Miasma lies heavily over the farther ground."
            default: break
            }
        }
        if environment.precipitationIntensity == "heavy" {
            switch environment.precipitation {
            case "rain": return "Heavy rain crosses the open ground."
            case "snow": return "Heavy snow crosses the open ground."
            case "mixedRainSnow": return "Rain and snow cross the open ground together."
            default: break
            }
        }
        switch environment.illuminationBand {
        case "trueDark": return "Only the ground nearest the entry is clearly visible."
        case "blazing": return "Hard light reaches every open surface."
        default: break
        }
        if environment.suspendedDensity == "trace" || environment.suspendedDensity == "light" {
            switch environment.suspendedMedium {
            case "smoke": return "Thin smoke drifts through the open ground."
            case "airborneAsh": return "A light fall of ash moves through the air."
            case "mist": return "Light mist gathers in the lower ground."
            case "miasma": return "A thin miasma hangs over the lower ground."
            default: break
            }
        }
        if environment.precipitationIntensity == "trace" || environment.precipitationIntensity == "light" {
            switch environment.precipitation {
            case "rain": return "Light rain crosses the open ground."
            case "snow": return "Light snow crosses the open ground."
            case "mixedRainSnow": return "Light rain and snow cross the open ground together."
            default: break
            }
        }
        if environment.illuminationBand == "dim" { return "Dim light leaves the farther ground subdued." }
        if environment.illuminationBand == "bright" { return "Clear light separates the open surfaces." }
        switch (environment.floraCoverageBand, environment.floraHabit) {
        case ("abundant", "spreading"): return "Growth spreads across most open ground."
        case ("abundant", "clustered"): return "Dense growth gathers in broad clusters."
        case ("abundant", _): return "Growth occupies most open ground."
        case ("present", "spreading"): return "Growth spreads through the open ground."
        case ("present", "clustered"): return "Growth gathers in distinct clusters."
        case ("present", _): return "Growth is established across the open ground."
        case ("sparse", _): return "Sparse growth holds to a few open patches."
        default: break
        }
        return "No single visible condition dominates the farther ground, which remains open to exploration."
    }

    private static func pairedEnvironmentalFragment(_ environment: EnvironmentSummary,
                                                    dominantGround: GroundType) -> String? {
        if environment.suspendedDensity == "heavy" || environment.suspendedDensity == "dense" {
            switch environment.suspendedMedium {
            case "smoke": return "thick smoke hung across the farther ground"
            case "airborneAsh": return "airborne ash formed heavy banks across the farther ground"
            case "mist": return "mist gathered in broad banks beyond the entry"
            case "miasma": return "miasma lay heavily over the farther ground"
            default: break
            }
        }
        if environment.precipitationIntensity == "heavy" {
            switch environment.precipitation {
            case "rain": return "heavy rain crossed the open ground"
            case "snow": return "heavy snow crossed the open ground"
            case "mixedRainSnow": return "rain and snow crossed the open ground together"
            default: break
            }
        }
        if environment.illuminationBand == "trueDark" {
            return "only the ground nearest the entry remained clearly visible"
        }
        if environment.illuminationBand == "blazing" {
            return "hard light reached every open surface"
        }
        if environment.suspendedDensity == "trace" || environment.suspendedDensity == "light" {
            switch environment.suspendedMedium {
            case "smoke": return "thin smoke drifted through the open ground"
            case "airborneAsh": return "a light fall of ash moved through the air"
            case "mist": return "light mist gathered in the lower ground"
            case "miasma": return "a thin miasma hung over the lower ground"
            default: break
            }
        }
        if environment.precipitationIntensity == "trace" || environment.precipitationIntensity == "light" {
            switch environment.precipitation {
            case "rain": return "light rain crossed the open ground"
            case "snow": return "light snow crossed the open ground"
            case "mixedRainSnow": return "light rain and snow crossed the open ground together"
            default: break
            }
        }
        if environment.illuminationBand == "dim" { return "dim light left the farther ground subdued" }
        if environment.illuminationBand == "bright" { return "clear light separated the open surfaces" }
        switch (environment.floraCoverageBand, environment.floraHabit) {
        case ("abundant", "spreading"): return "growth spread across most open ground"
        case ("abundant", "clustered"): return "dense growth gathered in broad clusters"
        case ("abundant", _): return "growth occupied most open ground"
        case ("present", "spreading"): return "growth spread through the open ground"
        case ("present", "clustered"): return "growth gathered in distinct clusters"
        case ("present", _): return "growth established itself across the open ground"
        case ("sparse", _) where dominantGround == .stone:
            return "sparse growth settled on the open stone"
        case ("sparse", _): return "sparse growth settled across a few open patches"
        default: return nil
        }
    }

    private static func knownDisplayName(_ fact: WorldArrivalSceneReceipt.CausalVisualFact) throws -> String {
        guard let label = fact.markDisplayName, !label.isEmpty else { throw Error.missingKnownLabel }
        return label
    }
    private static func scopeOrder(_ scope: String) -> Int {
        ["ground", "water", "flora", "light", "atmosphere"].firstIndex(of: scope) ?? .max
    }
    private static func validate(_ environment: EnvironmentSummary) throws {
        guard ["trueDark", "dim", "ordinary", "bright", "blazing"].contains(environment.illuminationBand),
              ["none", "smoke", "airborneAsh", "mist", "miasma"].contains(environment.suspendedMedium),
              ["none", "trace", "light", "heavy", "dense"].contains(environment.suspendedDensity),
              ["none", "rain", "snow", "mixedRainSnow"].contains(environment.precipitation),
              ["none", "trace", "light", "heavy"].contains(environment.precipitationIntensity),
              ["none", "sparse", "present", "abundant"].contains(environment.floraCoverageBand),
              ["solitary", "clustered", "spreading", "mixed"].contains(environment.floraHabit) else {
            throw Error.malformedEnvironment
        }
    }
    private static func capitalized(_ value: String) -> String {
        guard let first = value.first else { return value }
        return first.uppercased() + value.dropFirst()
    }
    private static func wordCount(_ value: String) -> Int { value.split(whereSeparator: \.isWhitespace).count }
}
