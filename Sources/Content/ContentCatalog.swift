import Foundation

/// Loads and cross-validates the JSON catalogs in `Sources/Content/Data/`.
///
/// Content is data, never logic (CLAUDE.md). Gameplay code asks the catalog for definitions and
/// never hardcodes a symbol's numbers. `validate()` runs at load and in the test suite, so a
/// dangling ID in JSON fails immediately and loudly rather than silently spawning nothing.
struct ContentCatalog: Sendable {
    /// The kinds of slot a book has. Content-defined; nothing assumes a count.
    let slots: [SlotDef]
    let symbols: [SymbolDef]
    let creatures: [CreatureDef]
    let resources: [ResourceDef]
    let items: [ItemDef]
    let skills: [SkillDef]
    let researchBranches: [ResearchBranchDef]
    let researchNodes: [ResearchNodeDef]
    let gambitComponents: [GambitComponentDef]
    let stations: [StationDef]
    let constellationNodes: [ConstellationNodeDef]

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

    func slot(_ id: SlotID) -> SlotDef? { slots.first { $0.id == id } }
    func symbol(_ id: SymbolID) -> SymbolDef? { symbols.first { $0.id == id } }
    func creature(_ id: CreatureID) -> CreatureDef? { creatures.first { $0.id == id } }
    func resource(_ id: ResourceID) -> ResourceDef? { resources.first { $0.id == id } }
    func item(_ id: ItemID) -> ItemDef? { items.first { $0.id == id } }
    func skill(_ id: SkillID) -> SkillDef? { skills.first { $0.id == id } }
    func skill(ownedBy owner: SkillDef.Owner) -> SkillDef? { skills.first { $0.owner == owner } }
    func researchBranch(_ id: ResearchBranchID) -> ResearchBranchDef? { researchBranches.first { $0.id == id } }
    func researchNode(_ id: ResearchNodeID) -> ResearchNodeDef? { researchNodes.first { $0.id == id } }
    func gambitComponent(_ id: GambitComponentID) -> GambitComponentDef? { gambitComponents.first { $0.id == id } }

    var branchesInOrder: [ResearchBranchDef] { researchBranches.sorted { $0.order < $1.order } }
    func nodes(in branch: ResearchBranchID) -> [ResearchNodeDef] { researchNodes.filter { $0.branch == branch } }
    func components(_ kind: GambitComponentDef.Kind) -> [GambitComponentDef] {
        gambitComponents.filter { $0.kind == kind }
    }
    func station(_ id: StationID) -> StationDef? { stations.first { $0.id == id } }
    func constellationNode(_ id: ConstellationNodeID) -> ConstellationNodeDef? {
        constellationNodes.first { $0.id == id }
    }

    func symbols(in slot: SlotID) -> [SymbolDef] { symbols.filter { $0.slot == slot } }

    /// The canonical slot order. **The only correct way to iterate a book's slots** — there is no
    /// `allCases` to reach for, by design.
    var slotsInOrder: [SlotDef] { slots.sorted { $0.order < $1.order } }
    var slotIDsInOrder: [SlotID] { slotsInOrder.map(\.id) }

    var starterSymbolIDs: [SymbolID] { symbols.filter { $0.acquisition == .starter }.map(\.id) }
    var stationsInOrder: [StationDef] { stations.sorted { $0.sortOrder < $1.sortOrder } }

    // MARK: - Loading

    enum ContentError: Error, CustomStringConvertible {
        case missingFile(String)
        case decodeFailed(String, underlying: Error)
        case danglingReference(String)
        case duplicateID(String)

        var description: String {
            switch self {
            case .missingFile(let name): "Missing content file \(name).json in the app bundle"
            case .decodeFailed(let name, let underlying): "Failed to decode \(name).json — \(underlying)"
            case .danglingReference(let detail): "Dangling content reference — \(detail)"
            case .duplicateID(let detail): "Duplicate content id — \(detail)"
            }
        }
    }

    static func load(bundle: Bundle = .contentBundle) throws -> ContentCatalog {
        ContentCatalog(
            slots: try loadFile("slots", key: "slots", bundle: bundle),
            symbols: try loadFile("symbols", key: "symbols", bundle: bundle),
            creatures: try loadFile("creatures", key: "creatures", bundle: bundle),
            resources: try loadFile("resources", key: "resources", bundle: bundle),
            items: try loadFile("items", key: "items", bundle: bundle),
            skills: try loadFile("skills", key: "skills", bundle: bundle),
            researchBranches: try loadFile("research", key: "branches", bundle: bundle),
            researchNodes: try loadFile("research", key: "nodes", bundle: bundle),
            gambitComponents: try loadFile("gambit_components", key: "components", bundle: bundle),
            stations: try loadFile("stations", key: "stations", bundle: bundle),
            constellationNodes: try loadFile("constellation", key: "nodes", bundle: bundle)
        )
    }

    /// Each file is `{ "_note": "...", "<key>": [ ... ] }` — the note carries the PLACEHOLDER
    /// warning inside the data, since JSON has no comments.
    private static func loadFile<T: Decodable>(_ name: String, key: String, bundle: Bundle) throws -> [T] {
        guard let url = bundle.url(forResource: name, withExtension: "json") else {
            throw ContentError.missingFile(name)
        }
        do {
            let data = try Data(contentsOf: url)
            let wrapper = try JSONDecoder().decode([String: ContentFileValue<T>].self, from: data)
            guard case .entries(let entries)? = wrapper[key] else {
                throw ContentError.decodeFailed(name, underlying: ContentError.missingFile(key))
            }
            return entries
        } catch let error as ContentError {
            throw error
        } catch {
            throw ContentError.decodeFailed(name, underlying: error)
        }
    }

    /// Lets one JSON object hold several things at once: the `_note`, the collection being asked
    /// for, and other collections of entirely different shapes. `research.json` carries both
    /// branches and nodes, so a key that doesn't decode as `T` is skipped rather than fatal.
    private enum ContentFileValue<T: Decodable>: Decodable {
        case note(String)
        case entries([T])
        case somethingElse

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let text = try? container.decode(String.self) {
                self = .note(text)
            } else if let entries = try? container.decode([T].self) {
                self = .entries(entries)
            } else {
                self = .somethingElse
            }
        }
    }

    // MARK: - Validation

    func validate() throws {
        try requireUniqueIDs(slots.map(\.id.rawValue), label: "slot")
        try requireUniqueIDs(symbols.map(\.id.rawValue), label: "symbol")
        try requireUniqueIDs(creatures.map(\.id.rawValue), label: "creature")
        try requireUniqueIDs(resources.map(\.id.rawValue), label: "resource")
        try requireUniqueIDs(items.map(\.id.rawValue), label: "item")
        try requireUniqueIDs(skills.map(\.id.rawValue), label: "skill")
        try requireUniqueIDs(researchBranches.map(\.id.rawValue), label: "research branch")
        try requireUniqueIDs(researchNodes.map(\.id.rawValue), label: "research node")
        try requireUniqueIDs(gambitComponents.map(\.id.rawValue), label: "gambit component")
        try requireUniqueIDs(stations.map(\.id.rawValue), label: "station")
        try requireUniqueIDs(constellationNodes.map(\.id.rawValue), label: "constellation node")

        let resourceIDs = Set(resources.map(\.id))
        let creatureIDs = Set(creatures.map(\.id))
        let itemIDs = Set(items.map(\.id))

        let slotIDs = Set(slots.map(\.id))
        for symbol in symbols where !slotIDs.contains(symbol.slot) {
            throw ContentError.danglingReference("symbol '\(symbol.id)' sits in unknown slot '\(symbol.slot)'")
        }
        guard !slots.isEmpty else {
            throw ContentError.danglingReference("slots.json defines no slots — books would have nowhere to put a symbol")
        }

        // The research tree has to be a real, reachable DAG: no dangling prerequisites, no
        // orphaned branches, and no node that grants something that doesn't exist.
        let branchIDs = Set(researchBranches.map(\.id))
        let nodeIDs = Set(researchNodes.map(\.id))
        let componentIDs = Set(gambitComponents.map(\.id))
        let symbolIDs = Set(symbols.map(\.id))

        for node in researchNodes {
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
                case .effect:
                    guard grant.effect != nil else {
                        throw ContentError.danglingReference("node '\(node.id)' grants an effect with no effect named")
                    }
                }
            }
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
        let requiredNodes = [
            ConstellationNodes.extraSymbolSlot, ConstellationNodes.extraGambitSlot, ConstellationNodes.essenceHead,
        ]
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
    static let fiber: ResourceID = "fiber"
    static let essenceRaw: ResourceID = "essence_raw"
    static let mote: ResourceID = "mote"
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
