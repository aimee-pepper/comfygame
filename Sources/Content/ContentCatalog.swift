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
    let gambitPieces: [GambitPieceDef]
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
    func gambitPiece(_ id: GambitPieceID) -> GambitPieceDef? { gambitPieces.first { $0.id == id } }
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
    var starterGambitPieceIDs: [GambitPieceID] { gambitPieces.filter { $0.acquisition == .starter }.map(\.id) }
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
            gambitPieces: try loadFile("gambit_pieces", key: "gambitPieces", bundle: bundle),
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

    /// Lets `_note` (a string) and the payload array coexist in one JSON object.
    private enum ContentFileValue<T: Decodable>: Decodable {
        case note(String)
        case entries([T])

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let text = try? container.decode(String.self) {
                self = .note(text)
            } else {
                self = .entries(try container.decode([T].self))
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
        try requireUniqueIDs(gambitPieces.map(\.id.rawValue), label: "gambit piece")
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
