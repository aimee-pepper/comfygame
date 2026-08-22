import Foundation

enum WorldArrivalDescriptionRules {
    enum Error: Swift.Error, Equatable {
        case malformedTerrain, malformedFlora, malformedEnvironment
        case unknownGround, unknownScope, unknownContribution, unregisteredResource
        case missingKnownLabel, missingPageOrder, overlong
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

    struct Input: Equatable {
        var dominantDryGround: GroundType
        var terrain: TerrainSummary
        var environment: EnvironmentSummary
        var causalFacts: [WorldArrivalReceipt.CausalVisualFact]
    }

    static func describe(_ input: Input) throws -> String {
        let ground = try groundToken(input.dominantDryGround)
        let water = try waterBand(input.terrain)
        try validate(input.environment)
        let ordered = try input.causalFacts.filter {
            guard $0.contributionKind != .none else { return false }
            guard $0.markDisplayName?.isEmpty == false else { return false }
            if $0.scope == .resource, !hasRegisteredResourceFamily($0.semanticKey) {
                throw Error.unregisteredResource
            }
            return true
        }.sorted {
            if $0.sourcePageOrder != $1.sourcePageOrder {
                return $0.sourcePageOrder < $1.sourcePageOrder
            }
            return scopeOrder($0.scope) < scopeOrder($1.scope)
        }
        var namedMarks: Set<InstanceID> = []
        let eligible = ordered.filter { namedMarks.insert($0.candidateMarkID).inserted }
        let structural = eligible.first {
            $0.contributionKind == .reshaped
                && ($0.scope == .ground || $0.scope == .water)
                && ["plains", "archipelago", "caverns"].contains($0.semanticKey)
        }
        let first = firstSentence(ground: ground, water: water,
                                  structuralMark: structural?.semanticKey)
        var selected = Array(eligible.prefix(2))
        var second = try secondSentence(dominantGround: input.dominantDryGround,
                                        environment: input.environment, selected: selected)
        var result = "\(first) \(second)"
        if wordCount(result) > 55, selected.count == 2 {
            selected.removeLast()
            second = try secondSentence(dominantGround: input.dominantDryGround,
                                        environment: input.environment, selected: selected)
            result = "\(first) \(second)"
        }
        if wordCount(result) > 55 {
            second = environmentalSentence(input.environment)
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

    private static func secondSentence(dominantGround: GroundType,
                                       environment: EnvironmentSummary,
                                       selected: [WorldArrivalReceipt.CausalVisualFact]) throws -> String {
        guard !selected.isEmpty else { return environmentalSentence(environment) }
        let clauses = try selected.map { fact -> String in
            "Your \(try knownDisplayName(fact)) mark \(try verb(fact, environment: environment))"
        }
        if clauses.count == 2 {
            return "\(clauses[0]), while your \(try knownDisplayName(selected[1])) mark \(try verb(selected[1], environment: environment))."
        }
        let fragment = pairedEnvironmentalFragment(environment, dominantGround: dominantGround)
        return fragment.map { "\(clauses[0]), while \($0)." } ?? "\(clauses[0])."
    }

    private static func verb(_ fact: WorldArrivalReceipt.CausalVisualFact,
                             environment: EnvironmentSummary) throws -> String {
        let key = "\(fact.semanticKey ?? "")|\(fact.scope.rawValue)|\(fact.contributionKind.rawValue)"
        switch key {
        case "plains|ground|reshaped": return "opened the terrain"
        case "verdant|flora|increased": return "spread low growth farther along the few wet and stony edges"
        case "archipelago|water|reshaped": return "divided the route"
        case "caverns|ground|reshaped": return "shaped the enclosure"
        case "common_ore|resource|increased": return "made ore more plentiful"
        default: break
        }
        switch (fact.scope, fact.contributionKind) {
        case (.ground, .reshaped): return "reshaped the ground"
        case (.ground, .increased): return "made that ground more prevalent"
        case (.ground, .reduced): return "made that ground less prevalent"
        case (.water, .reshaped): return "reshaped the water"
        case (.water, .increased): return "made water more prevalent"
        case (.water, .reduced): return "made water less prevalent"
        case (.flora, .reshaped): return "reshaped \(try floraPhrase(environment))"
        case (.flora, .increased): return "spread \(try floraPhrase(environment)) farther"
        case (.flora, .reduced): return "left less \(try floraPhrase(environment))"
        case (.resource, .reshaped): return "changed the material deposits"
        case (.resource, .increased): return "made those deposits more plentiful"
        case (.resource, .reduced): return "made those deposits scarcer"
        case (.light, .reshaped): return "changed the light"
        case (.light, .increased): return "strengthened the light"
        case (.light, .reduced): return "subdued the light"
        case (.atmosphere, .reshaped): return "changed the air"
        case (.atmosphere, .increased): return "strengthened that condition in the air"
        case (.atmosphere, .reduced): return "weakened that condition in the air"
        case (_, .none): throw Error.unknownContribution
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

    private static func knownDisplayName(_ fact: WorldArrivalReceipt.CausalVisualFact) throws -> String {
        guard let label = fact.markDisplayName, !label.isEmpty else { throw Error.missingKnownLabel }
        return label
    }
    private static func scopeOrder(_ scope: WorldArrivalReceipt.CausalVisualFact.Scope) -> Int {
        WorldArrivalReceipt.CausalVisualFact.Scope.allCases.firstIndex(of: scope) ?? .max
    }
    private static func hasRegisteredResourceFamily(_ semanticKey: String?) -> Bool {
        guard let semanticKey,
              let symbol = ContentCatalog.shared.symbol(SymbolID(rawValue: semanticKey)) else { return false }
        return symbol.yieldModifiers.keys.contains { id in
            id != Resources.essenceRaw && ContentCatalog.shared.resource(id)?.isRealityCurrency == false
        }
    }
    private static func validate(_ environment: EnvironmentSummary) throws {
        guard ["trueDark", "dim", "ordinary", "bright", "blazing"].contains(environment.illuminationBand),
              ["none", "smoke", "airborneAsh", "mist", "miasma"].contains(environment.suspendedMedium),
              ["none", "trace", "light", "heavy", "dense"].contains(environment.suspendedDensity),
              ["none", "rain", "snow", "mixedRainSnow"].contains(environment.precipitation),
              ["none", "trace", "light", "heavy"].contains(environment.precipitationIntensity),
              ["none", "sparse", "present", "abundant"].contains(environment.floraCoverageBand),
              ["none", "solitary", "clustered", "spreading", "mixed"].contains(environment.floraHabit),
              (environment.suspendedMedium == "none") == (environment.suspendedDensity == "none"),
              (environment.precipitation == "none") == (environment.precipitationIntensity == "none"),
              (environment.floraCoverageBand == "none") == (environment.floraHabit == "none") else {
            throw Error.malformedEnvironment
        }
    }
    private static func capitalized(_ value: String) -> String {
        guard let first = value.first else { return value }
        return first.uppercased() + value.dropFirst()
    }
    private static func wordCount(_ value: String) -> Int { value.split(whereSeparator: \.isWhitespace).count }
}

/// Exact bind-time speaking candidates. This owns candidate identity and complete-mark removal;
/// it does not classify generated counterfactual differences.
enum WorldArrivalCausalCandidateRules {
    struct Candidate: Equatable {
        var markID: InstanceID
        var semanticKey: String?
        var displayLabel: String
        var sourcePageOrder: Int
        var registeredResourceFamilies: [ResourceID]
    }

    static func candidates(page: Page, review: WritingDeskReviewModel) -> [Candidate] {
        candidates(page: page, visibleMarks: review.visibleMarks)
    }

    static func candidates(page: Page, visibleMarks: [WritingDeskVisibleMark]) -> [Candidate] {
        let visible = Dictionary(uniqueKeysWithValues: visibleMarks.map { ($0.id, $0) })
        let liveSourceIDs = Set(PageRules.clusterSigils(of: page).map(\.id))
        return page.runes.enumerated().compactMap { order, mark in
            guard let display = visible[mark.id], display.isReadable,
                  display.displayName != "??", !display.displayName.isEmpty else { return nil }
            let isCandidate: Bool
            if mark.personalCompound != nil {
                isCandidate = !mark.sigils.isEmpty
            } else {
                switch mark.content {
                case .compound, .rune:
                    isCandidate = !mark.sigils.isEmpty
                case .source:
                    isCandidate = liveSourceIDs.contains(mark.id)
                case .target, .qualifier:
                    isCandidate = false
                }
            }
            guard isCandidate else { return nil }
            let families: [ResourceID]
            if let symbolID = mark.symbolID,
               let symbol = ContentCatalog.shared.symbol(symbolID) {
                families = symbol.yieldModifiers.keys.filter { id in
                    guard id != Resources.essenceRaw,
                          let resource = ContentCatalog.shared.resource(id) else { return false }
                    return !resource.isRealityCurrency
                }.sorted { $0.rawValue < $1.rawValue }
            } else {
                families = []
            }
            let semanticKey = mark.personalCompound == nil ? mark.glyphID : nil
            return .init(markID: mark.id, semanticKey: semanticKey,
                         displayLabel: display.displayName, sourcePageOrder: order,
                         registeredResourceFamilies: families)
        }
    }

    static func removing(_ candidate: Candidate, from page: Page) -> Page? {
        guard page.runes.contains(where: { $0.id == candidate.markID }) else { return nil }
        var result = page
        result.runes.removeAll { $0.id == candidate.markID }
        result.links = result.links.filter {
            $0.a != candidate.markID && $0.b != candidate.markID
        }
        return result
    }

    static func resourceQuantity(_ family: ResourceID, in map: WorldMap) -> Int {
        map.tiles.reduce(into: 0) { total, tile in
            switch tile.content {
            case .node(let node) where node.resource == family:
                total += max(0, node.remainingHarvests) * max(0, node.yieldPerHarvest)
            case .wildDrop(let resource, let amount) where resource == family:
                total += max(0, amount)
            default:
                break
            }
        }
    }

    static func resourceFacts(candidate: Candidate, actual: WorldMap,
                              withoutCandidate: WorldMap)
        -> [WorldArrivalReceipt.CausalVisualFact] {
        candidate.registeredResourceFamilies.compactMap { family in
            let actualQuantity = resourceQuantity(family, in: actual)
            let withoutQuantity = resourceQuantity(family, in: withoutCandidate)
            guard actualQuantity != withoutQuantity else { return nil }
            let contribution = actualQuantity > withoutQuantity ? "increased" : "reduced"
            return .init(candidateMarkID: candidate.markID,
                         semanticKey: candidate.semanticKey,
                         markDisplayName: candidate.displayLabel,
                         sourcePageOrder: candidate.sourcePageOrder,
                         scope: .resource,
                         contributionKind: contribution == "increased" ? .increased : .reduced,
                         resultBand: actualQuantity == 0 ? "absent" : "present",
                         withoutAuthoredBand: withoutQuantity == 0 ? "absent" : "present")
        }
    }

    static func summaryFacts(candidate: Candidate,
                             actual: Worldgen.ArrivalCausalSummary,
                             withoutCandidate: Worldgen.ArrivalCausalSummary,
                             actualReadings: PressureReadings,
                             withoutReadings: PressureReadings)
        -> [WorldArrivalReceipt.CausalVisualFact] {
        var facts: [WorldArrivalReceipt.CausalVisualFact] = []
        func fact(_ scope: WorldArrivalReceipt.CausalVisualFact.Scope,
                  _ kind: WorldArrivalReceipt.CausalVisualFact.ContributionKind,
                  _ result: String, _ without: String) -> WorldArrivalReceipt.CausalVisualFact {
            .init(candidateMarkID: candidate.markID, semanticKey: candidate.semanticKey,
                  markDisplayName: candidate.displayLabel,
                  sourcePageOrder: candidate.sourcePageOrder, scope: scope,
                  contributionKind: kind, resultBand: result,
                  withoutAuthoredBand: without)
        }
        let actualGround = groundCounts(actual.map)
        let withoutGround = groundCounts(withoutCandidate.map)
        if actualGround != withoutGround {
            facts.append(fact(.ground, .reshaped, groundBand(actualGround),
                              groundBand(withoutGround)))
        }
        let actualWater = waterCounts(actual.map)
        let withoutWater = waterCounts(withoutCandidate.map)
        if actualWater.wet != withoutWater.wet || actualWater.deep != withoutWater.deep {
            facts.append(fact(.water, .reshaped,
                              "wet:\(actualWater.wet);deep:\(actualWater.deep)",
                              "wet:\(withoutWater.wet);deep:\(withoutWater.deep)"))
        }
        let actualFlora = actual.map.tiles.count { $0.flora != nil }
        let withoutFlora = withoutCandidate.map.tiles.count { $0.flora != nil }
        if actualFlora != withoutFlora {
            facts.append(fact(.flora, actualFlora > withoutFlora ? .increased : .reduced,
                              "tiles:\(actualFlora)", "tiles:\(withoutFlora)"))
        }
        facts.append(contentsOf: resourceFacts(candidate: candidate, actual: actual.map,
                                               withoutCandidate: withoutCandidate.map))
        let actualLight = actualReadings["illumination"]
        let withoutLight = withoutReadings["illumination"]
        if actualLight != withoutLight {
            let kind: WorldArrivalReceipt.CausalVisualFact.ContributionKind
            if actualLight.peak >= withoutLight.peak && actualLight.floor >= withoutLight.floor {
                kind = .increased
            } else if actualLight.peak <= withoutLight.peak && actualLight.floor <= withoutLight.floor {
                kind = .reduced
            } else { kind = .reshaped }
            facts.append(fact(.light, kind,
                              "peak:\(actualLight.peak);floor:\(actualLight.floor)",
                              "peak:\(withoutLight.peak);floor:\(withoutLight.floor)"))
        }
        return facts
    }

    private static func groundCounts(_ map: WorldMap) -> [GroundType: Int] {
        Dictionary(grouping: map.tiles.map(\.ground), by: { $0 }).mapValues(\.count)
    }
    private static func groundBand(_ counts: [GroundType: Int]) -> String {
        counts.sorted { $0.key.rawValue < $1.key.rawValue }
            .map { "\($0.key.rawValue):\($0.value)" }.joined(separator: ",")
    }
    private static func waterCounts(_ map: WorldMap) -> (wet: Int, deep: Int) {
        let counts = groundCounts(map)
        return ((counts[.water] ?? 0) + (counts[.deepWater] ?? 0), counts[.deepWater] ?? 0)
    }
}
