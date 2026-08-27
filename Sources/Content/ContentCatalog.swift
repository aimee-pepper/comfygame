import Foundation

/// Loads and cross-validates the JSON catalogs in `Sources/Content/Data/`.
///
/// Content is data, never logic (CLAUDE.md). Gameplay code asks the catalog for definitions and
/// never hardcodes a symbol's numbers. `validate()` runs at load and in the test suite, so a
/// dangling ID in JSON fails immediately and loudly rather than silently spawning nothing.
struct ContentCatalog: Sendable {
    let symbols: [SymbolDef]
    let creatures: [CreatureDef]
    let resources: [ResourceDef]
    let items: [ItemDef]
    let skills: [SkillDef]
    let pressureTargets: [PressureTargetDef]
    let pressureSources: [PressureSourceDef]
    let researchBranches: [ResearchBranchDef]
    let researchNodes: [ResearchNodeDef]
    let gambitComponents: [GambitComponentDef]
    let stations: [StationDef]
    let constellationNodes: [ConstellationNodeDef]
    let sites: [SiteDef]
    let contradictions: [ContradictionDef]
    let descriptionClauses: [DescriptionClauseDef]
    let combatTrees: [CombatTreeDef]
    /// Generated from the machine-readable v2 authority plus the existing authored node content.
    /// Kept alongside the live v1 trees until the lossless ownership/consumer migration is green.
    let combatGraph: CombatGraphCatalogue
    let runeShapes: [RuneShapeDef]
    let qualifiers: [QualifierDef]
    let travellers: [TravellerDef]
    let diaryPages: [DiaryPageDef]

    /// Loaded once at first use. Content is read-only after load, so this is safe to share.
    static let shared: ContentCatalog = {
        do {
            let catalog = try ContentCatalog.load()
            try catalog.validate()
            return catalog
        } catch {
            // Content ships inside the app bundle: a failure here is a build/authoring mistake,
            // not a runtime condition a player can hit. Fail loudly during development.
            fatalError("Content catalog failed to load: \(error)")
        }
    }()

    // MARK: - Lookup

    private var symbolIndex: [SymbolID: SymbolDef] { Dictionary(uniqueKeysWithValues: symbols.map { ($0.id, $0) }) }

    func symbol(_ id: SymbolID) -> SymbolDef? { symbols.first { $0.id == id } }
    func creature(_ id: CreatureID) -> CreatureDef? { creatures.first { $0.id == id } }
    func resource(_ id: ResourceID) -> ResourceDef? { resources.first { $0.id == id } }
    func item(_ id: ItemID) -> ItemDef? { items.first { $0.id == id } }
    func skill(_ id: SkillID) -> SkillDef? { skills.first { $0.id == id } }
    /// **Everything this member can do**, in a stable order. One each used to be the whole game.
    func skills(ownedBy owner: SkillDef.Owner) -> [SkillDef] { skills.filter { $0.owner == owner } }
    func skill(ownedBy owner: SkillDef.Owner) -> SkillDef? { skills.first { $0.owner == owner } }
    func pressureTarget(_ id: PressureTargetID) -> PressureTargetDef? { pressureTargets.first { $0.id == id } }
    func pressureSource(_ id: PressureSourceID) -> PressureSourceDef? { pressureSources.first { $0.id == id } }
    var pressureTargetsInOrder: [PressureTargetDef] { pressureTargets.sorted { $0.order < $1.order } }

    func researchBranch(_ id: ResearchBranchID) -> ResearchBranchDef? { researchBranches.first { $0.id == id } }
    func researchNode(_ id: ResearchNodeID) -> ResearchNodeDef? { researchNodes.first { $0.id == id } }
    func constructionBundledResearch(for station: StationID) -> ResearchNodeDef? {
        researchNodes.first { $0.constructionBundledWith == station }
    }
    func capabilityGrants(for completed: Set<ResearchNodeID>) -> Set<CapabilityID> {
        Set(researchNodes.lazy
            .filter { completed.contains($0.id) }
            .flatMap(\.grants)
            .filter { $0.kind == .capability }
            .compactMap { $0.id.map(CapabilityID.init(rawValue:)) })
    }
    func gambitComponent(_ id: GambitComponentID) -> GambitComponentDef? { gambitComponents.first { $0.id == id } }

    var branchesInOrder: [ResearchBranchDef] { researchBranches.sorted { $0.order < $1.order } }
    func nodes(in branch: ResearchBranchID) -> [ResearchNodeDef] { researchNodes.filter { $0.branch == branch } }
    func components(_ kind: GambitComponentDef.Kind) -> [GambitComponentDef] {
        gambitComponents.filter { $0.kind == kind }
    }
    func station(_ id: StationID) -> StationDef? { stations.first { $0.id == id } }
    func site(_ id: SiteID) -> SiteDef? { sites.first { $0.id == id } }
    /// The nine, flattened. A branch is the unit everything else deals in — a class is which three
    /// of these you finished.
    var combatBranches: [CombatBranchDef] { combatTrees.flatMap(\.branches) }
    func combatBranch(_ id: CombatBranchID) -> CombatBranchDef? { combatBranches.first { $0.id == id } }
    func contradiction(_ id: ContradictionID) -> ContradictionDef? { contradictions.first { $0.id == id } }
    /// A shape by id, deriving rotations on demand.
    ///
    /// `crude_ell@90` isn't authored anywhere — it's the authored `crude_ell` turned a quarter
    /// turn. Resolving it here means a rotated cluster survives a save without four copies of every
    /// footprint existing in the data.
    func runeShape(_ id: String) -> RuneShapeDef? {
        if let exact = runeShapes.first(where: { $0.id == id }) { return exact }
        let parts = id.split(separator: "@")
        guard parts.count == 2, let angle = Int(parts[1]),
              var shape = runeShapes.first(where: { $0.id == String(parts[0]) })
        else { return nil }
        for _ in 0..<((angle / 90) % 4) { shape = shape.rotated() }
        return shape
    }

    func rotatedShape(of shape: RuneShapeDef) -> RuneShapeDef? { shape.rotated() }

    func qualifier(_ id: QualifierID) -> QualifierDef? { qualifiers.first { $0.id == id } }
    func qualifiers(on ladder: QualifierDef.Ladder) -> [QualifierDef] {
        qualifiers.filter { $0.ladder == ladder }.sorted { $0.step < $1.step }
    }
    var qualifierLaddersInUse: [QualifierDef.Ladder] {
        QualifierDef.Ladder.allCases.filter { !qualifiers(on: $0).isEmpty }
    }
    func traveller(_ id: TravellerID) -> TravellerDef? { travellers.first { $0.id == id } }
    var travellersInAuthoredOrder: [TravellerDef] {
        travellers.sorted {
            let lhs = $0.authoredOrder ?? Int.max
            let rhs = $1.authoredOrder ?? Int.max
            return lhs == rhs ? $0.id.rawValue < $1.id.rawValue : lhs < rhs
        }
    }
    func diaryPage(_ id: DiaryPageID) -> DiaryPageDef? { diaryPages.first { $0.id == id } }
    func diary(of traveller: TravellerID) -> [DiaryPageDef] { diaryPages.filter { $0.diary == traveller } }
    func runeShapes(in hand: Hand) -> [RuneShapeDef] {
        runeShapes.filter { $0.hand == hand }.sorted { $0.id < $1.id }
    }
    func constellationNode(_ id: ConstellationNodeID) -> ConstellationNodeDef? {
        constellationNodes.first { $0.id == id }
    }

    var starterSymbolIDs: [SymbolID] { symbols.filter { $0.acquisition == .starter }.map(\.id) }
    var starterSourceIDs: [PressureSourceID] {
        pressureSources.filter { $0.acquisition == .starter }.map(\.id)
    }
    var stationsInOrder: [StationDef] {
        Self.boardOrderedStations(stations)
    }

    static func boardOrderedStations(_ stations: [StationDef]) -> [StationDef] {
        stations.sorted {
            let lhs = $0.resolvedBoardPlacement
            let rhs = $1.resolvedBoardPlacement
            if lhs.section.rank != rhs.section.rank { return lhs.section.rank < rhs.section.rank }
            if lhs.order != rhs.order { return lhs.order < rhs.order }
            return $0.id.rawValue < $1.id.rawValue
        }
    }

    /// Description groups that aren't named after a pressure target. Empty for now — every group
    /// is a target — but the panel is expected to grow clauses about a world's *character*
    /// (ambush versus pursuit, and the like), which isn't a target.
    static let describableGroups: Set<String> = []

    // MARK: - Loading

    enum ContentError: Error, CustomStringConvertible {
        case missingFile(String)
        case decodeFailed(String, underlying: Error)
        case danglingReference(String)
        case duplicateID(String)
        case undisclosedProvisionalContent(String)

        var description: String {
            switch self {
            case .missingFile(let name): "Missing content file \(name).json in the app bundle"
            case .decodeFailed(let name, let underlying): "Failed to decode \(name).json — \(underlying)"
            case .danglingReference(let detail): "Dangling content reference — \(detail)"
            case .duplicateID(let detail): "Duplicate content id — \(detail)"
            case .undisclosedProvisionalContent(let detail):
                "Undisclosed provisional content — \(detail)"
            }
        }
    }

    /// Machine-readable promotion boundary for catalogues whose historical note still calls some
    /// content placeholder. Every field is classified deterministically: named player-facing copy
    /// keys use `playerFacingCopy`, every numeric leaf uses `numericValues`, and all remaining
    /// identity/schema/mechanics fields use `defaultDisposition`.
    struct AuthorityMetadata: Decodable, Equatable, Sendable {
        enum Disposition: String, Decodable, Sendable {
            case settled, playtestTuning, provisionalCopy, legacyDecodeOnly
        }

        let schemaVersion: Int
        let defaultDisposition: Disposition
        let numericValues: Disposition
        let playerFacingCopy: Disposition

        private static let playerFacingCopyKeys: Set<String> = [
            "name", "title", "label", "blurb", "prose", "passage", "description",
            "descriptionSentence", "headline", "prompt", "question", "reply", "summary"
        ]

        func disposition(forFieldNamed key: String, value: Any) -> Disposition {
            if Self.playerFacingCopyKeys.contains(key) { return playerFacingCopy }
            if let number = value as? NSNumber,
               CFGetTypeID(number) != CFBooleanGetTypeID() { return numericValues }
            return defaultDisposition
        }

        func validate(file: String) throws {
            guard schemaVersion == 1,
                  defaultDisposition == .settled,
                  numericValues == .playtestTuning,
                  playerFacingCopy == .provisionalCopy else {
                throw ContentError.undisclosedProvisionalContent(
                    "\(file).json must classify mechanics, numeric tuning, and player-facing copy"
                )
            }
        }
    }

    static let provisionalAuthorityFileNames: [String] = [
        "combat_trees", "constellation", "contradictions", "creatures", "descriptions",
        "gambit_components", "items", "pressure_sources", "pressure_targets",
        "research", "resources", "rune_shapes", "sites", "skills", "stations", "symbols",
        "travellers"
    ]

    static func load(bundle: Bundle = .contentBundle) throws -> ContentCatalog {
        try validateBundledAuthorityMetadata(bundle: bundle)
        return ContentCatalog(
            symbols: try loadFile("symbols", key: "symbols", bundle: bundle),
            creatures: try loadFile("creatures", key: "creatures", bundle: bundle),
            resources: try loadFile("resources", key: "resources", bundle: bundle),
            items: try loadFile("items", key: "items", bundle: bundle),
            skills: try loadFile("skills", key: "skills", bundle: bundle),
            pressureTargets: try loadFile("pressure_targets", key: "targets", bundle: bundle),
            pressureSources: try loadFile("pressure_sources", key: "sources", bundle: bundle),
            researchBranches: try loadFile("research", key: "branches", bundle: bundle),
            researchNodes: try loadFile("research", key: "nodes", bundle: bundle),
            gambitComponents: try loadFile("gambit_components", key: "components", bundle: bundle),
            stations: try loadFile("stations", key: "stations", bundle: bundle),
            constellationNodes: try loadFile("constellation", key: "nodes", bundle: bundle),
            sites: try loadFile("sites", key: "sites", bundle: bundle),
            contradictions: try loadFile("contradictions", key: "contradictions", bundle: bundle),
            descriptionClauses: try loadFile("descriptions", key: "clauses", bundle: bundle),
            combatTrees: try loadFile("combat_trees", key: "trees", bundle: bundle),
            combatGraph: try loadObject("combat_tree_v2", bundle: bundle),
            runeShapes: try loadFile("rune_shapes", key: "shapes", bundle: bundle),
            qualifiers: try loadFile("qualifiers", key: "qualifiers", bundle: bundle),
            travellers: try loadPromotedTravellers(bundle: bundle),
            diaryPages: try loadFile("travellers", key: "pages", bundle: bundle)
        )
    }

    /// Decision 279 promotes Design's generated authored meetings into the live catalogue. Keeping
    /// the prose in one generated corpus means release play and the DEBUG Atlas review the exact
    /// same text instead of maintaining a hand-copied JSON shadow.
    private static func loadPromotedTravellers(bundle: Bundle) throws -> [TravellerDef] {
        var travellers: [TravellerDef] = try loadFile("travellers", key: "travellers", bundle: bundle)
        guard AuthoredMeetingCorpus.decodingError == nil else {
            throw ContentError.decodeFailed(
                "authored meeting corpus",
                underlying: ContentError.danglingReference(AuthoredMeetingCorpus.decodingError ?? "unknown error")
            )
        }
        let authored = AuthoredMeetingCorpus.meetings
        let authoredIDs = authored.map(\.travellerID)
        guard authored.count == 23, Set(authoredIDs).count == authored.count else {
            throw ContentError.duplicateID("authored meeting corpus must contain 23 unique traveller IDs")
        }
        let replaceableLiveIDs: Set<TravellerID> = ["noll", "auber"]
        for source in authored {
            let id = TravellerID(rawValue: source.travellerID)
            guard let index = travellers.firstIndex(where: { $0.id == id }) else {
                throw ContentError.danglingReference("authored meeting traveller \(source.travellerID)")
            }
            if travellers[index].meeting != nil, !replaceableLiveIDs.contains(id) {
                throw ContentError.duplicateID("authored meeting unexpectedly replaces live \(source.travellerID)")
            }
            travellers[index].meeting = TravellerMeeting(
                opening: source.opening,
                questions: source.exchanges.map {
                    TravellerMeeting.Exchange(id: $0.id, ask: $0.ask, reply: $0.reply)
                },
                offer: source.offer,
                accepted: source.accepted,
                declined: source.declined
            )
        }
        return travellers
    }

    static func validateBundledAuthorityMetadata(bundle: Bundle = .contentBundle) throws {
        for name in provisionalAuthorityFileNames {
            guard let url = bundle.url(forResource: name, withExtension: "json") else {
                throw ContentError.missingFile(name)
            }
            do {
                let object = try JSONSerialization.jsonObject(with: Data(contentsOf: url))
                guard let root = object as? [String: Any] else {
                    throw ContentError.decodeFailed(name, underlying: ContentError.missingFile("root"))
                }
                try validateAuthorityIfProvisional(root, file: name)
            } catch let error as ContentError {
                throw error
            } catch {
                throw ContentError.decodeFailed(name, underlying: error)
            }
        }

    }

    private static func validateAuthorityIfProvisional(_ root: [String: Any],
                                                        file name: String) throws {
        guard let note = root["_note"] as? String,
              note.localizedCaseInsensitiveContains("placeholder") else { return }
        guard let raw = root["_authority"] else {
            throw ContentError.undisclosedProvisionalContent(
                "\(name).json needs an _authority field-disposition declaration"
            )
        }
        let data = try JSONSerialization.data(withJSONObject: raw)
        let metadata = try JSONDecoder().decode(AuthorityMetadata.self, from: data)
        try metadata.validate(file: name)
    }

    /// Each file is `{ "_note": "...", "<key>": [ ... ] }` — the note carries the PLACEHOLDER
    /// warning inside the data, since JSON has no comments.
    private static func loadFile<T: Decodable>(_ name: String, key: String, bundle: Bundle) throws -> [T] {
        guard let url = bundle.url(forResource: name, withExtension: "json") else {
            throw ContentError.missingFile(name)
        }
        do {
            let data = try Data(contentsOf: url)
            guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let rawEntries = object[key] else {
                throw ContentError.decodeFailed(name, underlying: ContentError.missingFile(key))
            }
            try validateAuthorityIfProvisional(object, file: name)
            let entriesData = try JSONSerialization.data(withJSONObject: rawEntries)
            return try JSONDecoder().decode([T].self, from: entriesData)
        } catch let error as ContentError {
            throw error
        } catch {
            throw ContentError.decodeFailed(name, underlying: error)
        }
    }

    private static func loadObject<T: Decodable>(_ name: String, bundle: Bundle) throws -> T {
        guard let url = bundle.url(forResource: name, withExtension: "json") else {
            throw ContentError.missingFile(name)
        }
        do {
            return try JSONDecoder().decode(T.self, from: Data(contentsOf: url))
        } catch {
            throw ContentError.decodeFailed(name, underlying: error)
        }
    }

    // MARK: - Validation

    func validate() throws {
        try WorkshopPatternRegistry.validate(WorkshopPatternRegistry.definitions)
        try SchematicRegistry.validate(SchematicRegistry.definitions)
        try requireUniqueIDs(symbols.map(\.id.rawValue), label: "symbol")
        try requireUniqueIDs(creatures.map(\.id.rawValue), label: "creature")
        try requireUniqueIDs(resources.map(\.id.rawValue), label: "resource")
        try requireUniqueIDs(items.map(\.id.rawValue), label: "item")
        try validateGearCatalogueDisposition()
        try requireUniqueIDs(skills.map(\.id.rawValue), label: "skill")
        try requireUniqueIDs(pressureTargets.map(\.id.rawValue), label: "pressure target")
        try requireUniqueIDs(pressureSources.map(\.id.rawValue), label: "pressure source")
        try requireUniqueIDs(researchBranches.map(\.id.rawValue), label: "research branch")
        try requireUniqueIDs(researchNodes.map(\.id.rawValue), label: "research node")
        try requireUniqueIDs(gambitComponents.map(\.id.rawValue), label: "gambit component")
        try requireUniqueIDs(stations.map(\.id.rawValue), label: "station")
        for station in stations where station.homeSection == nil || station.sectionOrder == nil {
            throw ContentError.danglingReference(
                "station '\(station.id)' relies on legacy Base-board placement")
        }
        let stationBoardPositions = stations.compactMap { station -> String? in
            guard let section = station.homeSection, let order = station.sectionOrder else { return nil }
            return "\(section.rawValue):\(order)"
        }
        try requireUniqueIDs(stationBoardPositions, label: "station board position")
        try requireUniqueIDs(constellationNodes.map(\.id.rawValue), label: "constellation node")
        try requireUniqueIDs(sites.map(\.id.rawValue), label: "site")
        try requireUniqueIDs(contradictions.map(\.id.rawValue), label: "contradiction")
        try requireUniqueIDs(descriptionClauses.map(\.id), label: "description clause")
        try requireUniqueIDs(runeShapes.map(\.id), label: "rune shape")
        try requireUniqueIDs(qualifiers.map(\.id.rawValue), label: "qualifier")
        try requireUniqueIDs(travellers.map(\.id.rawValue), label: "traveller")
        try requireUniqueIDs(diaryPages.map(\.id.rawValue), label: "diary page")
        try validateCombatGraph()

        for traveller in travellers {
            guard let meeting = traveller.meeting else { continue }
            let ids = meeting.questions.map(\.id)
            guard ids.allSatisfy({ !$0.isEmpty && !$0.hasPrefix("legacy.") }) else {
                throw ContentError.danglingReference("traveller '\(traveller.id)' has a meeting exchange without an explicit id")
            }
            try requireUniqueIDs(ids, label: "meeting exchange for \(traveller.id.rawValue)")
        }



        // A hand with no shapes is a hand nothing can be written in.
        for hand in Hand.allCases where runeShapes(in: hand).isEmpty {
            throw ContentError.danglingReference("no rune shape authored for the \(hand.rawValue) hand")
        }
        for shape in runeShapes {
            guard shape.cells.allSatisfy({ $0.count == 2 && $0[0] >= 0 && $0[1] >= 0 }) else {
                throw ContentError.danglingReference("shape '\(shape.id)' has a malformed cell")
            }
            // Snug against its bounding box, rather than required to cover [0,0] — a plus-shape
            // legitimately leaves its own corner empty, and placement only needs the offsets to
            // start at zero so `origin + offset` lands where the player tapped.
            guard shape.cells.map({ $0[0] }).min() == 0, shape.cells.map({ $0[1] }).min() == 0 else {
                throw ContentError.danglingReference("shape '\(shape.id)' isn't flush with its origin")
            }
            guard Set(shape.cells.map { [$0[0], $0[1]] }).count == shape.cells.count else {
                throw ContentError.danglingReference("shape '\(shape.id)' lists a cell twice")
            }
        }

        let resourceIDs = Set(resources.map(\.id))
        let creatureIDs = Set(creatures.map(\.id))
        let itemIDs = Set(items.map(\.id))

        for resource in resources {
            switch resource.extractionDisposition {
            case .mineralNode:
                guard let rank = resource.requiredExtractionRank, (0...4).contains(rank) else {
                    throw ContentError.danglingReference(
                        "mineral resource '\(resource.id)' needs Extraction rank 0...4")
                }
            case .floraPrimary, .floraSecondary, .directPickup, .realityAward,
                 .creatureMaterialOnly:
                guard resource.requiredExtractionRank == nil else {
                    throw ContentError.danglingReference(
                        "non-mineral resource '\(resource.id)' cannot require Extraction")
                }
            }
        }

        // Every locked live station must name a reachable keeper and an authored, payable cost.
        // Otherwise it can have a route and screen while remaining impossible to build in play.
        let stationOwnerIDs = Set(travellers.map(\.id))
        for station in stations where !station.unlockedAtStart {
            guard let owner = station.builtBy, stationOwnerIDs.contains(owner) else {
                throw ContentError.danglingReference(
                    "locked station '\(station.id)' has no live keeper")
            }
            guard let cost = station.buildCost else {
                throw ContentError.danglingReference(
                    "locked station '\(station.id)' has no build cost")
            }
            guard cost.essence >= 0, cost.resources.values.allSatisfy({ $0 >= 0 }) else {
                throw ContentError.danglingReference(
                    "locked station '\(station.id)' has a negative build cost")
            }
            guard cost.essence > 0 || cost.resources.values.contains(where: { $0 > 0 }) else {
                throw ContentError.danglingReference(
                    "locked station '\(station.id)' has an empty build cost")
            }
            for id in cost.resources.keys where !resourceIDs.contains(id) {
                throw ContentError.danglingReference(
                    "station '\(station.id)' costs unknown resource '\(id)'")
            }
        }

        // Apothecary recipes are native rules rather than JSON, so validate their stable IDs at
        // the same catalogue boundary instead of allowing a misspelling to become unobtainable.
        for recipe in ConsumableCraftingRules.recipes {
            guard itemIDs.contains(recipe.output) else {
                throw ContentError.danglingReference(
                    "apothecary recipe produces unknown item '\(recipe.output)'")
            }
            for id in recipe.resources.keys where !resourceIDs.contains(id) {
                throw ContentError.danglingReference(
                    "apothecary recipe '\(recipe.output)' uses unknown resource '\(id)'")
            }
        }

        // A source that points at a target nobody defined would silently contribute nothing.
        let targetIDs = Set(pressureTargets.map(\.id))
        for source in pressureSources {
            guard !source.contributions.isEmpty else {
                throw ContentError.danglingReference("pressure source '\(source.id)' does nothing")
            }
            for contribution in source.contributions where !targetIDs.contains(contribution.target) {
                throw ContentError.danglingReference(
                    "pressure source '\(source.id)' pushes on unknown target '\(contribution.target)'")
            }
        }
        // Only Illumination and Thermal carry a floor; a floor anywhere else would be read and
        // then thrown away, which is worse than not writing it.
        for source in pressureSources {
            for contribution in source.contributions where contribution.floor != 0 {
                guard pressureTarget(contribution.target)?.dualValued == true else {
                    throw ContentError.danglingReference(
                        "'\(source.id)' sets a floor on single-valued target '\(contribution.target)'")
                }
            }
        }

        // The research tree has to be a real, reachable DAG: no dangling prerequisites, no
        // orphaned branches, and no node that grants something that doesn't exist.
        let branchIDs = Set(researchBranches.map(\.id))
        let nodeIDs = Set(researchNodes.map(\.id))
        let componentIDs = Set(gambitComponents.map(\.id))
        let symbolIDs = Set(symbols.map(\.id))

        // Talin's authored grammar is deliberately narrower than the generic HP grammar. Validate
        // the stable selector and exact absolute marks together so content cannot silently turn it
        // into a percentage comparison while the editor still calls it armour.
        guard gambitComponent(FoeArmourGambit.subject)?.selector == "foe.armourAbove" else {
            throw ContentError.danglingReference("Talin's armour subject is missing its selector")
        }
        for (id, mark) in FoeArmourGambit.marks {
            guard let component = gambitComponent(id), component.kind == .threshold,
                  component.value == Double(mark),
                  component.name == "Armour threshold \(mark)" else {
                throw ContentError.danglingReference("Armour threshold \(mark) [Internal ID: \(id)] does not match its authored threshold value")
            }
        }

        for node in researchNodes {
            guard node.needsLifetimeRawRefined >= 0 else {
                throw ContentError.danglingReference(
                    "research node '\(node.id)' has negative refining practice")
            }
            guard branchIDs.contains(node.branch) else {
                throw ContentError.danglingReference("research node '\(node.id)' is in unknown branch '\(node.branch)'")
            }
            for required in node.requires where !nodeIDs.contains(required) {
                throw ContentError.danglingReference("research node '\(node.id)' requires unknown node '\(required)'")
            }
            if node.requires.contains(node.id) {
                throw ContentError.danglingReference("research node '\(node.id)' requires itself")
            }
            for id in node.cost.resources.keys where !resourceIDs.contains(id) {
                throw ContentError.danglingReference("research node '\(node.id)' costs unknown resource '\(id)'")
            }
            guard !node.grants.isEmpty else {
                throw ContentError.danglingReference("research node '\(node.id)' grants nothing")
            }
            if let stationID = node.constructionBundledWith {
                guard station(stationID) != nil,
                      researchBranch(node.branch)?.station == stationID,
                      node.grants.count == 1,
                      node.grants.first?.kind == .capability,
                      node.grants.first?.id != nil else {
                    throw ContentError.danglingReference(
                        "construction-bundled node '\(node.id)' must grant one capability at its station")
                }
            }
            for grant in node.grants {
                switch grant.kind {
                case .gambitComponent:
                    guard let id = grant.id, componentIDs.contains(GambitComponentID(rawValue: id)) else {
                        throw ContentError.danglingReference("node '\(node.id)' grants unknown component '\(grant.id ?? "nil")'")
                    }
                case .symbol:
                    guard let id = grant.id, symbolIDs.contains(SymbolID(rawValue: id)) else {
                        throw ContentError.danglingReference("node '\(node.id)' grants unknown symbol '\(grant.id ?? "nil")'")
                    }
                case .instrument:
                    // An instrument reads exactly one subject, and a subject nobody defined is an
                    // instrument that measures nothing.
                    guard let id = grant.id, targetIDs.contains(PressureTargetID(rawValue: id)) else {
                        throw ContentError.danglingReference("node '\(node.id)' measures unknown subject '\(grant.id ?? "nil")'")
                    }
                case .focus:
                    guard let id = grant.id,
                          pressureSource(PressureSourceID(rawValue: id)) != nil else {
                        throw ContentError.danglingReference("node '\(node.id)' grants unknown focus '\(grant.id ?? "nil")'")
                    }
                case .effect:
                    guard grant.effect != nil else {
                        throw ContentError.danglingReference("node '\(node.id)' grants an effect with no effect named")
                    }
                    if grant.effect == .stationTier {
                        guard let id = grant.id, station(StationID(rawValue: id)) != nil,
                              let tier = grant.tier, tier > 0 else {
                            throw ContentError.danglingReference("node '\(node.id)' upgrades unknown station '\(grant.id ?? "nil")'")
                        }
                    }
                case .capability:
                    guard let id = grant.id, !id.isEmpty else {
                        throw ContentError.danglingReference("node '\(node.id)' grants an unnamed capability")
                    }
                }
            }
        }
        let bundledStations = researchNodes.compactMap(\.constructionBundledWith)
        guard Set(bundledStations).count == bundledStations.count else {
            throw ContentError.duplicateID("construction-bundled station")
        }
        for branch in researchBranches where nodes(in: branch.id).isEmpty {
            throw ContentError.danglingReference("research branch '\(branch.id)' has no nodes")
        }

        for symbol in symbols {
            for id in symbol.yieldModifiers.keys where !resourceIDs.contains(id) {
                throw ContentError.danglingReference("symbol '\(symbol.id)' yields unknown resource '\(id)'")
            }
            for id in symbol.enemyTableModifiers.keys where !creatureIDs.contains(id) {
                throw ContentError.danglingReference("symbol '\(symbol.id)' references unknown creature '\(id)'")
            }
            // A symbol that expands to nothing would generate a world with no pressures at all,
            // which reads as a bug rather than as a quiet world.
            guard !symbol.expandsTo.isEmpty else {
                throw ContentError.danglingReference("symbol '\(symbol.id)' expands to no components")
            }
            for component in symbol.expandsTo {
                guard let source = pressureSource(component.source) else {
                    throw ContentError.danglingReference(
                        "symbol '\(symbol.id)' expands to unknown source '\(component.source)'")
                }
                guard targetIDs.contains(component.target) else {
                    throw ContentError.danglingReference(
                        "symbol '\(symbol.id)' binds to unknown target '\(component.target)'")
                }
                // Binding a source to a target it has no opinion about writes a statement the
                // world can't act on — almost always a typo in one of the two IDs.
                guard source.contribution(to: component.target) != nil else {
                    throw ContentError.danglingReference(
                        "symbol '\(symbol.id)' binds '\(component.source)' to '\(component.target)', which it doesn't affect")
                }
            }
        }

        // Groups are allowed to say nothing — a world whose air is unremarkable should not be made
        // to announce that, and "Ordinary atmosphere." in every description would flatten the prose
        // the panel exists to produce. What *is* checked is that a clause can fire at all.
        for clause in descriptionClauses {
            guard !clause.text.isEmpty else {
                throw ContentError.danglingReference("description clause '\(clause.id)' says nothing")
            }
            guard ContentCatalog.describableGroups.contains(clause.group) || pressureTargets.contains(where: { $0.id.rawValue == clause.group }) else {
                throw ContentError.danglingReference(
                    "description clause '\(clause.id)' is in unknown group '\(clause.group)'")
            }
            for condition in clause.conditions where !targetIDs.contains(condition.target) {
                throw ContentError.danglingReference(
                    "description clause '\(clause.id)' reads unknown target '\(condition.target)'")
            }
        }

        // A contradiction that can't fire is worse than a missing one: it reads as authored
        // content and silently never appears.
        let sourceIDs = Set(pressureSources.map(\.id))
        for entry in contradictions {
            switch entry.kind {
            case .negation:
                guard let source = entry.source, sourceIDs.contains(source) else {
                    throw ContentError.danglingReference(
                        "contradiction '\(entry.id)' denies unknown source '\(entry.source?.rawValue ?? "nil")'")
                }
                guard let target = entry.negatedTarget, targetIDs.contains(target) else {
                    throw ContentError.danglingReference(
                        "contradiction '\(entry.id)' negates unknown target '\(entry.negatedTarget?.rawValue ?? "nil")'")
                }
                // Denying something a source never did isn't a contradiction, it's a no-op.
                guard pressureSource(source)?.contribution(to: target) != nil else {
                    throw ContentError.danglingReference(
                        "contradiction '\(entry.id)' denies '\(target)' of '\(source)', which it doesn't affect")
                }
            case .assertion:
                guard let required = entry.requiresWrittenSource, sourceIDs.contains(required) else {
                    throw ContentError.danglingReference(
                        "contradiction '\(entry.id)' requires unknown source '\(entry.requiresWrittenSource?.rawValue ?? "nil")'")
                }
                guard !entry.conditions.isEmpty else {
                    throw ContentError.danglingReference(
                        "assertion '\(entry.id)' has no conditions, so it would fire on every world")
                }
                for condition in entry.conditions where !targetIDs.contains(condition.target) {
                    throw ContentError.danglingReference(
                        "contradiction '\(entry.id)' reads unknown target '\(condition.target)'")
                }
            }
            guard entry.instability > 0 else {
                throw ContentError.danglingReference("contradiction '\(entry.id)' costs nothing")
            }
        }

        // Sites reach into nearly every other catalog, so they're the easiest place for a typo to
        // hide: a dangling ID here would silently place a site that gives nothing.
        let siteIDs = Set(sites.map(\.id))
        for site in sites {
            for condition in site.conditions {
                guard targetIDs.contains(condition.target) else {
                    throw ContentError.danglingReference(
                        "site '\(site.id)' reads unknown pressure target '\(condition.target)'")
                }
                switch condition.measure {
                case .aspect, .form, .tag:
                    guard let key = condition.key, !key.isEmpty else {
                        throw ContentError.danglingReference(
                            "site '\(site.id)' reads \(condition.measure) on '\(condition.target)' without naming which")
                    }
                    if condition.measure == .form,
                       let target = pressureTarget(condition.target), !target.forms.contains(key) {
                        throw ContentError.danglingReference(
                            "site '\(site.id)' reads unknown form '\(key)' on '\(condition.target)'")
                    }
                    if condition.measure == .aspect,
                       let target = pressureTarget(condition.target),
                       !target.aspects.contains(where: { $0.id == key }) {
                        throw ContentError.danglingReference(
                            "site '\(site.id)' reads unknown aspect '\(key)' on '\(condition.target)'")
                    }
                default:
                    break
                }
            }
            for id in site.excludes where !siteIDs.contains(id) {
                throw ContentError.danglingReference("site '\(site.id)' excludes unknown site '\(id)'")
            }
            for id in site.contents.yields.keys where !resourceIDs.contains(id) {
                throw ContentError.danglingReference("site '\(site.id)' yields unknown resource '\(id)'")
            }
            for id in site.contents.items where !itemIDs.contains(id) {
                throw ContentError.danglingReference("site '\(site.id)' holds unknown item '\(id)'")
            }
            for id in site.contents.teaches where !symbolIDs.contains(id) {
                throw ContentError.danglingReference("site '\(site.id)' teaches unknown symbol '\(id)'")
            }
            if let guardian = site.contents.guardian, !creatureIDs.contains(guardian) {
                throw ContentError.danglingReference("site '\(site.id)' is guarded by unknown creature '\(guardian)'")
            }
            guard !site.contents.isEmpty || site.providesNaturalAnchor else {
                throw ContentError.danglingReference("site '\(site.id)' contains nothing worth walking to")
            }
        }

        for item in items {
            if let target = item.identifiesInto, !itemIDs.contains(target) {
                throw ContentError.danglingReference("item '\(item.id)' identifies into unknown item '\(target)'")
            }
        }

        // Gameplay code refers to a handful of well-known IDs; make sure the data still has them.
        let requiredStations: [StationID] = [
            Stations.writingDesk, Stations.storehouse, Stations.workshop,
            Stations.party, Stations.essenceSpring, Stations.constellation,
        ]
        for id in requiredStations where station(id) == nil {
            throw ContentError.danglingReference("stations.json is missing required station '\(id)'")
        }
        // Only nodes gameplay actually names. Two were cut on 7 Aug for granting values nothing
        // read (`fossil-audit.md` §1–2), and this list is exactly where a fossil hides: it made
        // their absence a build failure rather than a cleanup.
        let requiredNodes = [ConstellationNodes.extraGambitSlot]
        for id in requiredNodes where constellationNode(id) == nil {
            throw ContentError.danglingReference("constellation.json is missing required node '\(id)'")
        }
        for id in [Resources.ore, Resources.fiber, Resources.essenceRaw, Resources.mote] where resource(id) == nil {
            throw ContentError.danglingReference("resources.json is missing required resource '\(id)'")
        }
        // Each party member needs exactly one Skill, or the action bar has a dead button on it.
        for owner in [SkillDef.Owner.binder, .companion] where skill(ownedBy: owner) == nil {
            throw ContentError.danglingReference("skills.json has no skill for the \(owner.rawValue)")
        }

        for qualifier in qualifiers {
            for target in qualifier.onlyFor where !targetIDs.contains(target) {
                throw ContentError.danglingReference(
                    "qualifier '\(qualifier.id)' is restricted to unknown target '\(target)'")
            }
        }

        // A traveller with no signature is nowhere; a page that unlocks nothing is not a page.
        let travellerIDs = Set(travellers.map(\.id))
        let authoredOrders = travellers.compactMap(\.authoredOrder)
        guard authoredOrders.count == travellers.count,
              Set(authoredOrders).count == authoredOrders.count,
              authoredOrders.allSatisfy({ $0 > 0 }) else {
            throw ContentError.danglingReference(
                "every traveller needs a unique positive authoredOrder")
        }
        for traveller in travellers {
            guard traveller.campaignPhase != nil else {
                throw ContentError.danglingReference(
                    "traveller '\(traveller.id)' has no campaignPhase")
            }
            guard let band = traveller.storyArrivalBand, band >= 0 else {
                throw ContentError.danglingReference(
                    "traveller '\(traveller.id)' has no valid storyArrivalBand")
            }
            guard !traveller.signature.isEmpty else {
                throw ContentError.danglingReference("traveller '\(traveller.id)' is nowhere at all")
            }
            for clue in traveller.signature {
                guard targetIDs.contains(clue.condition.target) else {
                    throw ContentError.danglingReference(
                        "traveller '\(traveller.id)' sits on unknown target '\(clue.condition.target)'")
                }
                guard !clue.passage.isEmpty else {
                    throw ContentError.danglingReference("traveller '\(traveller.id)' has a wordless clue")
                }
                // Passages are read and matched by a person. A value in one turns the search into
                // arithmetic — see the same rule on description clauses.
                guard !clue.passage.contains(where: \.isNumber) else {
                    throw ContentError.danglingReference(
                        "traveller '\(traveller.id)' names a number in a passage: \(clue.passage)")
                }
            }
        }
        for page in diaryPages {
            guard travellerIDs.contains(page.diary) else {
                throw ContentError.danglingReference("page '\(page.id)' is torn from an unknown diary")
            }
            guard !page.prose.isEmpty else {
                throw ContentError.danglingReference("page '\(page.id)' is blank")
            }
            let rewardCount = [
                page.about != nil,
                page.teaches != nil,
                page.teachesFocus != nil,
                page.teachesGambit != nil,
                page.teachesPattern != nil,
                page.teachesSchematic != nil,
                page.researchNode != nil,
                page.site != nil,
            ].filter { $0 }.count
            let expectedRewardCount = (page.kind == .worldWorthWriting || page.kind == .account
                                       || page.kind == .turn) ? 0 : 1
            guard rewardCount == expectedRewardCount else {
                throw ContentError.danglingReference(
                    "page '\(page.id)' grants \(rewardCount) things; expected \(expectedRewardCount)")
            }
            guard page.kind == .locationClue || page.clueIndex == nil else {
                throw ContentError.danglingReference("page '\(page.id)' has a clue index but is not a location clue")
            }
            switch page.kind {
            case .locationClue:
                guard let about = page.about, let index = page.clueIndex,
                      let subject = traveller(about), subject.signature.indices.contains(index) else {
                    throw ContentError.danglingReference("page '\(page.id)' points at no one's location")
                }
            case .whereabouts:
                guard let about = page.about, travellerIDs.contains(about) else {
                    throw ContentError.danglingReference("page '\(page.id)' speaks of no one")
                }
            case .symbol:
                guard let id = page.teaches, symbolIDs.contains(id) else {
                    throw ContentError.danglingReference("page '\(page.id)' teaches an unknown rune")
                }
            case .focus:
                guard let id = page.teachesFocus, sourceIDs.contains(id) else {
                    throw ContentError.danglingReference("page '\(page.id)' teaches an unknown focus")
                }
            case .gambit:
                guard let id = page.teachesGambit, componentIDs.contains(id) else {
                    throw ContentError.danglingReference("page '\(page.id)' teaches an unknown gambit phrase")
                }
            case .pattern:
                guard let id = page.teachesPattern,
                      WorkshopPatternRegistry.definition(id) != nil else {
                    throw ContentError.danglingReference("page '\(page.id)' teaches an unknown pattern")
                }
            case .schematic:
                guard let id = page.teachesSchematic,
                      SchematicRegistry.definition(id) != nil else {
                    throw ContentError.danglingReference("page '\(page.id)' teaches an unknown schematic")
                }
            case .researchLead:
                guard let id = page.researchNode, nodeIDs.contains(id) else {
                    throw ContentError.danglingReference("page '\(page.id)' leads to unknown study")
                }
            case .ruin:
                guard let id = page.site, siteIDs.contains(id) else {
                    throw ContentError.danglingReference("page '\(page.id)' names an unknown ruin")
                }
            case .worldWorthWriting, .account, .turn:
                break
            }
        }
    }

    private func validateGearCatalogueDisposition() throws {
        let gear = items.filter { $0.kind == .gear }
        let exactPartition: [GearCatalogueClassification: Set<ItemID>] = [
            .ordinaryFound: [
                "blade_chipped", "blade_keen", "ripping_hook", "the_long_grievance",
                "bone_awl", "raking_edge", "blade_binders", "hairsplitter",
                "field_maul", "banded_mace", "anvilfall", "the_settled_argument",
                "long_pick", "warded_spear", "parting_needle", "the_kept_distance",
                "split_board", "banded_buckler", "tower_guard", "the_unarguable",
                "padded_cap", "ridged_helm", "visored_casque", "crown_of_quiet",
                "guard_padded", "guard_banded", "guard_vault", "the_standing_wall",
                "wrapped_hands", "studded_gloves", "gauntlets_of_hold", "the_sure_hands",
                "worn_boots", "shod_boots", "longstriders", "the_unhurried",
                "bent_pick", "balanced_pick", "corebreaker", "the_willing_edge",
                "pressed_leaf", "cold_compass", "someones_ring", "the_first_page",
            ],
            .wildApexOnly: [
                "two_natured_blade", "long_fang", "ranked_spear", "rimed_edge",
                "living_hook", "quiet_knife", "bloodletter", "warded_haft",
            ],
            .componentAuthoredFound: [
                "rubble_sling", "ironwork_blade", "copper_buckler", "silvered_helm",
                "golden_keepsake", "quartz_point", "obsidian_edge", "adamant_cuirass",
                "woven_sling", "timber_longbow", "resinbound_boots", "riftglass_rapier",
            ],
            .decodeOnly: [
                "fired_clay_guard", "saltward_pendant", "sulfurous_maul", "mercurial_gloves",
                "pressed_pulp_cap", "toxin_edge", "sporeward_coat", "reagent_field_pick",
                "ichor_hook", "raw_essence_pendant", "mote_compass",
            ],
        ]
        for (classification, expected) in exactPartition {
            let actual = Set(gear.filter { $0.gearCatalogueDisposition?.classification == classification }.map(\.id))
            guard actual == expected else {
                throw ContentError.danglingReference("gear catalogue exact partition mismatch for \(classification.rawValue)")
            }
        }
        guard gear.count == 75 else {
            throw ContentError.danglingReference("gear catalogue must contain exactly 75 entries")
        }
        guard items.filter({ $0.kind != .gear }).allSatisfy({ $0.gearCatalogueDisposition == nil }) else {
            throw ContentError.danglingReference("non-gear carries gear catalogue disposition")
        }
        var counts: [GearCatalogueClassification: Int] = [:]
        let allowedWorldFamilies: Set<String> = [
            "ore", "copper", "silver", "gold", "quartz", "obsidian", "adamant", "clay",
            "timber", "fiber", "resin", "rift_glass", "rubble"
        ]
        let allowedCreatureFamilies = Set(MaterialFamilyID.allCases.filter(\.isAnimalWorldResource).map(\.rawValue))
        for item in gear {
            guard item.gear != nil, let disposition = item.gearCatalogueDisposition,
                  disposition.version == 1 else {
                throw ContentError.danglingReference("gear '\(item.id)' lacks disposition v1")
            }
            counts[disposition.classification, default: 0] += 1
            let expectsTerritory = disposition.classification == .ordinaryFound
                || (disposition.classification == .componentAuthoredFound
                    && item.id != ItemID(rawValue: "riftglass_rapier"))
            guard disposition.territoryFindEligible == expectsTerritory else {
                throw ContentError.danglingReference("gear '\(item.id)' has wrong territory eligibility")
            }
            switch disposition.classification {
            case .ordinaryFound, .wildApexOnly, .decodeOnly:
                guard disposition.foundReceipt == nil else {
                    throw ContentError.danglingReference("gear '\(item.id)' has an unauthorized found receipt")
                }
            case .componentAuthoredFound:
                guard let receipt = disposition.foundReceipt, receipt.version == 1,
                      !receipt.components.isEmpty else {
                    throw ContentError.danglingReference("gear '\(item.id)' lacks its authored found receipt")
                }
                let sockets = receipt.components.map(\.socket)
                guard sockets.allSatisfy({ !$0.isEmpty }), Set(sockets).count == sockets.count else {
                    throw ContentError.danglingReference("gear '\(item.id)' has invalid found sockets")
                }
                for component in receipt.components {
                    let valid = component.domain == .world
                        ? allowedWorldFamilies.contains(component.familyID)
                        : allowedCreatureFamilies.contains(component.familyID)
                    guard valid else {
                        throw ContentError.danglingReference("gear '\(item.id)' has an unknown found family")
                    }
                }
                switch receipt.mode {
                case .schematic:
                    guard receipt.schematicID != nil, receipt.fixedIdentity == nil else {
                        throw ContentError.danglingReference("gear '\(item.id)' has an invalid schematic receipt")
                    }
                case .fixedFound, .fixedSpecial:
                    guard receipt.schematicID == nil, !(receipt.fixedIdentity ?? "").isEmpty else {
                        throw ContentError.danglingReference("gear '\(item.id)' has an invalid fixed receipt")
                    }
                }
            }
        }
        guard counts[.ordinaryFound] == 44, counts[.wildApexOnly] == 8,
              counts[.componentAuthoredFound] == 12, counts[.decodeOnly] == 11 else {
            throw ContentError.danglingReference("gear catalogue partition must be 44/8/12/11")
        }
    }


    private func validateCombatGraph() throws {
        guard combatGraph.schemaVersion == 2, combatGraph.graphVersion == 2 else {
            throw ContentError.danglingReference(
                "unsupported combat graph schema \(combatGraph.schemaVersion)/\(combatGraph.graphVersion)")
        }
        guard combatGraph.trees.count == 3,
              combatGraph.disciplines.count == 9,
              combatGraph.nodes.count == 72 else {
            throw ContentError.danglingReference(
                "combat graph must contain 3 trees, 9 disciplines and 72 nodes")
        }
        try requireUniqueIDs(combatGraph.nodes.map(\.id.rawValue), label: "combat node")
        let nodeIDs = Set(combatGraph.nodes.map(\.id))
        let skillIDs = Set(skills.map(\.id))
        // These schema-2 identities intentionally replace decode-only legacy actions. Their
        // typed consumers land with combat-v2 activation; the graph must not keep serializing the
        // misleading legacy IDs merely because the old action catalogue still contains them.
        let pendingV2SkillIDs: Set<SkillID> = ["blur", "emanation_strike", "quench"]
        guard combatGraph.authoritySHA256.count == 64,
              combatGraph.effectCopySHA256.count == 64,
              combatGraph.effectCopySourceMarkdownSHA256.count == 64 else {
            throw ContentError.danglingReference("combat graph source hashes are missing or malformed")
        }
        guard combatGraph.nodes.filter({ $0.techniqueID != nil }).count == 20,
              combatGraph.nodes.filter({ $0.techniqueID == nil }).count == 52 else {
            throw ContentError.danglingReference("combat graph must contain 20 techniques and 52 passive nodes")
        }
        let legacyBranches = Dictionary(uniqueKeysWithValues: combatBranches.map { ($0.id, $0) })

        for tree in combatGraph.trees {
            guard tree.disciplines.count == 3,
                  tree.disciplines.allSatisfy({ $0.nodes.count == 8 }) else {
                throw ContentError.danglingReference(
                    "combat tree '\(tree.id)' must contain three eight-node disciplines")
            }
            let disciplineIDs = Set(tree.disciplines.map(\.id))
            let disciplineIndex = Dictionary(uniqueKeysWithValues:
                tree.disciplines.enumerated().map { ($0.element.id, $0.offset) })
            for discipline in tree.disciplines {
                guard let former = legacyBranches[discipline.legacyBranchID] else {
                    throw ContentError.danglingReference(
                        "combat discipline '\(discipline.id)' maps unknown legacy branch '\(discipline.legacyBranchID)'")
                }
                for node in discipline.nodes {
                    guard node.id.rawValue.hasPrefix("combat.\(tree.id.rawValue).\(discipline.id.rawValue)."),
                          node.formerIndex >= 1, node.formerIndex <= former.nodes.count,
                          node.depth >= 1, node.depth <= 5 else {
                        throw ContentError.danglingReference("combat node '\(node.id)' has invalid placement")
                    }
                    let formerNode = former.nodes[node.formerIndex - 1]
                    guard node.name == formerNode.name, node.legacyEffect == formerNode.effect,
                          node.legacyTechniqueID == formerNode.grantsSkill else {
                        throw ContentError.danglingReference(
                            "generated combat node '\(node.id)' is stale against authored node content")
                    }
                    if let skill = node.legacyTechniqueID, !skillIDs.contains(skill) {
                        throw ContentError.danglingReference(
                            "combat node '\(node.id)' grants unknown technique '\(skill)'")
                    }
                    if let skill = node.techniqueID,
                       !skillIDs.contains(skill), !pendingV2SkillIDs.contains(skill) {
                        throw ContentError.danglingReference(
                            "combat node '\(node.id)' grants unknown v2 technique '\(skill)'")
                    }
                    guard !node.effectCopy.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                        throw ContentError.danglingReference(
                            "combat node '\(node.id)' has no canonical Effect copy")
                    }
                    for parent in node.ordinaryParentAlternatives where !nodeIDs.contains(parent) {
                        throw ContentError.danglingReference(
                            "combat node '\(node.id)' names unknown parent '\(parent)'")
                    }
                    for parent in node.hybridAlternativeParents {
                        guard let parentTree = combatGraph.tree(containing: parent), parentTree.id == tree.id,
                              let parentDiscipline = combatGraph.discipline(containing: parent),
                              disciplineIDs.contains(parentDiscipline.id), parentDiscipline.id != discipline.id,
                              let lhs = disciplineIndex[discipline.id],
                              let rhs = disciplineIndex[parentDiscipline.id], abs(lhs - rhs) == 1 else {
                            throw ContentError.danglingReference(
                                "combat node '\(node.id)' has invalid hybrid parent '\(parent)'")
                        }
                    }
                    for parentID in node.ordinaryParentAlternatives {
                        guard let parent = combatGraph.node(parentID), parent.depth <= node.depth else {
                            throw ContentError.danglingReference(
                                "combat node '\(node.id)' has a non-forward parent '\(parentID)'")
                        }
                    }
                }
            }
            guard !combatGraphHasCycle(in: tree) else {
                throw ContentError.danglingReference("combat tree '\(tree.id)' contains a prerequisite cycle")
            }
        }
    }

    private func combatGraphHasCycle(in tree: CombatGraphTreeDef) -> Bool {
        let nodes = tree.disciplines.flatMap(\.nodes)
        let parents = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0.ordinaryParentAlternatives) })
        var visiting: Set<CombatNodeID> = []
        var visited: Set<CombatNodeID> = []
        func visit(_ id: CombatNodeID) -> Bool {
            if visiting.contains(id) { return true }
            if visited.contains(id) { return false }
            visiting.insert(id)
            for parent in parents[id, default: []] where visit(parent) { return true }
            visiting.remove(id)
            visited.insert(id)
            return false
        }
        return nodes.contains { visit($0.id) }
    }

    private func requireUniqueIDs(_ ids: [String], label: String) throws {
        var seen = Set<String>()
        for id in ids where !seen.insert(id).inserted {
            throw ContentError.duplicateID("\(label) '\(id)' appears twice")
        }
    }
}

/// Well-known resource IDs. Definitions live in `Content/Data/resources.json`.
enum Resources {
    static let ore: ResourceID = "ore"
    static let essenceRaw: ResourceID = "essence_raw"
    static let mote: ResourceID = "mote"

    // **What grows.** Named here because `FloraRules` decides which of them a given plant yields,
    // and that mapping is logic rather than content — the tissue triangle picks the corner.
    static let fiber: ResourceID = "fiber"
    static let timber: ResourceID = "timber"
    static let pulp: ResourceID = "pulp"
    static let resin: ResourceID = "resin"
    static let toxin: ResourceID = "toxin"
    static let spore: ResourceID = "spore"
    static let reagent: ResourceID = "reagent"
    static let quartz: ResourceID = "quartz"
    static let sulfur: ResourceID = "sulfur"
    static let silver: ResourceID = "silver"
    static let ichor: ResourceID = "ichor"
}

enum Items {
    static let anchorFrame: ItemID = "anchor_frame"
    static let essenceCrystal: ItemID = "essence_crystal"
    static let heatCore: ItemID = "heat_core"
    static let causticCore: ItemID = "caustic_core"
    static let lightCore: ItemID = "light_core"
    static let conduitFixture: ItemID = "conduit_fixture"
    static let scentMask: ItemID = "scent_mask"
    /// **Reserved, and deliberately not in `items.json`.** A material is not an authored item: what
    /// it is and what it's good for came off the animal it was cut from, and travels on the stack
    /// as a `CraftMaterialUnitV1`. This id exists only so a material can share the slot machinery.
    static let material: ItemID = "material"
}

extension Bundle {
    /// Content ships in the app bundle. Unit tests are hosted by the app, so `Bundle.main`
    /// resolves there too; the class-based lookup is the fallback for any non-hosted context.
    static var contentBundle: Bundle {
        if Bundle.main.url(forResource: "symbols", withExtension: "json") != nil { return .main }
        return Bundle(for: ContentBundleMarker.self)
    }
}

/// Anchor for `Bundle(for:)`. Has no behaviour.
final class ContentBundleMarker {}
