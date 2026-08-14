import Foundation

/// The instrument a rune is drawn with.
///
/// **One alphabet, three hands** (`writing-system-rune-spec.md` §2). The glyph is constant; the
/// tool sets the minimum size at which the mark survives. Charcoal cannot render fine detail, so
/// the same rune must be drawn large to stay legible — the size difference is physical, not
/// symbolic, which is why recognition transfers instantly and nothing is ever relearned.
enum Hand: String, Codable, CaseIterable, Sendable, Comparable {
    case crude, plain, refined

    var displayName: String {
        switch self {
        case .crude: "Rough charcoal"
        case .plain: "Brush"
        case .refined: "Fountain pen"
        }
    }

    /// Refinement is literacy, not power: a better hand lets you say the same thing in less space.
    /// It never unlocks a meaning.
    var order: Int { Hand.allCases.firstIndex(of: self) ?? 0 }
    static func < (lhs: Hand, rhs: Hand) -> Bool { lhs.order < rhs.order }
}

/// A footprint: the cells a rune occupies, as offsets from its origin.
struct RuneShapeDef: Codable, Equatable, Identifiable, Sendable {
    var id: String
    var hand: Hand
    /// `[column, row]` offsets. Always includes `[0,0]`.
    var cells: [[Int]]

    var offsets: [PageCell] { cells.map { PageCell(column: $0[0], row: $0[1]) } }

    /// The same footprint turned a quarter turn clockwise, normalised back against its origin.
    ///
    /// Derived rather than authored: a shape and its three rotations are the same glyph held at
    /// different angles, and authoring four copies of each would be four times the work for no
    /// expressive gain. The id carries the angle so a rotated page round-trips through a save.
    func rotated() -> RuneShapeDef {
        let turned = cells.map { [ (height - 1) - $0[1], $0[0] ] }
        let minColumn = turned.map { $0[0] }.min() ?? 0
        let minRow = turned.map { $0[1] }.min() ?? 0
        let normalised = turned.map { [$0[0] - minColumn, $0[1] - minRow] }

        let base = id.split(separator: "@").first.map(String.init) ?? id
        let previous = id.split(separator: "@").last.flatMap { Int($0) } ?? 0
        let angle = (previous + 90) % 360
        return RuneShapeDef(id: angle == 0 ? base : "\(base)@\(angle)",
                            hand: hand,
                            cells: normalised)
    }

    init(id: String, hand: Hand, cells: [[Int]]) {
        self.id = id
        self.hand = hand
        self.cells = cells
    }
    var footprint: Int { cells.count }
    var width: Int { (cells.map { $0[0] }.max() ?? 0) + 1 }
    var height: Int { (cells.map { $0[1] }.max() ?? 0) + 1 }
}

/// A square on the page.
struct PageCell: Codable, Equatable, Hashable, Sendable {
    var column: Int
    var row: Int

    static func + (lhs: PageCell, rhs: PageCell) -> PageCell {
        PageCell(column: lhs.column + rhs.column, row: lhs.row + rhs.row)
    }
}

/// A rune written on the page, at a position.
///
/// **Position is a packing fact, never a meaning.** Nothing about where a rune sits changes the
/// world it describes — the page is a budget, not a syntax — and `PressureTests` proves it by
/// resolving permuted pages and requiring identical readings.
struct PlacedRune: Codable, Equatable, Identifiable, Sendable {
    var id: InstanceID
    var content: MarkContent
    var hand: Hand
    var origin: PageCell
    /// Which authored shape this mark draws as. Stored rather than recomputed so an existing page
    /// keeps its layout even if the shape catalogue is re-authored around it.
    var shapeID: String

    init(id: InstanceID, content: MarkContent, hand: Hand, origin: PageCell, shapeID: String) {
        self.id = id
        self.content = content
        self.hand = hand
        self.origin = origin
        self.shapeID = shapeID
    }

    /// Convenience for the atomic case, which is most of the tests and eventually most of the game.
    init(id: InstanceID, sigil: Sigil, hand: Hand, origin: PageCell, shapeID: String) {
        self.init(id: id, content: .rune(sigil), hand: hand, origin: origin, shapeID: shapeID)
    }

    var shape: RuneShapeDef? { ContentCatalog.shared.runeShape(shapeID) }
    var cells: [PageCell] { (shape?.offsets ?? [PageCell(column: 0, row: 0)]).map { origin + $0 } }

    /// What this mark says **on its own**. Targets, sources and qualifiers say nothing alone —
    /// they say something once connected, which is `PageRules.sigils(of:)`'s job.
    var sigils: [Sigil] {
        switch content {
        case .target, .source, .qualifier:
            return []
        case .rune(let sigil):
            return [sigil]
        case .compound(let symbolID):
            guard let symbol = ContentCatalog.shared.symbol(symbolID) else { return [] }
            return symbol.expandsTo.enumerated().map { index, component in
                Sigil(id: InstanceID(rawValue: id.rawValue &* 31 &+ UInt64(index)),
                      source: component.source, target: component.target,
                      intensity: component.intensity, negatedTargets: component.negates)
            }
        }
    }

    var symbolID: SymbolID? {
        if case .compound(let id) = content { id } else { nil }
    }

    var targetID: PressureTargetID? {
        if case .target(let id) = content { id } else { nil }
    }

    var sourceID: PressureSourceID? {
        if case .source(let id) = content { id } else { nil }
    }

    var qualifierID: QualifierID? {
        if case .qualifier(let id) = content { id } else { nil }
    }

    /// Whether this mark needs connecting to mean anything.
    var needsConnection: Bool { sourceID != nil || qualifierID != nil }

    var displayName: String {
        switch content {
        case .rune(let sigil): sigil.displayText
        case .compound(let id): ContentCatalog.shared.symbol(id)?.name ?? id.rawValue
        case .target(let id): ContentCatalog.shared.pressureTarget(id)?.name ?? id.rawValue
        case .source(let id): ContentCatalog.shared.pressureSource(id)?.name ?? id.rawValue
        case .qualifier(let id): ContentCatalog.shared.qualifier(id)?.name ?? id.rawValue
        }
    }

    // **There is deliberately no `icon` here.** A mark on the page is drawn as a *glyph* — see
    // `glyphID` and `RuneGlyph` — because a rune is a written word and an SF Symbol of a mountain is
    // a picture of a thing (decisions-session-11 §4). This used to return one per mark and was read
    // by nothing at all, which is what `clause-audit.md` F4 was actually looking at: the writing
    // surface had already moved to glyphs and left the accessor behind.

    /// The identity a glyph is drawn from, so a rune always looks like itself.
    var glyphID: String {
        switch content {
        case .rune(let sigil): sigil.source.rawValue
        case .compound(let id): id.rawValue
        case .target(let id): id.rawValue
        case .source(let id): id.rawValue
        case .qualifier(let id): id.rawValue
        }
    }
}

/// What is actually written in a mark.
///
/// The grammar reads **target first, then connected sources** (decisions-session-14 §1): you write
/// the Illumination sigil and connect sources to it. A qualifier attaches to the source it's
/// connected to.
///
/// A **compound** is one glyph meaning what several runes mean together, at a smaller footprint
/// (rune spec §9). Every v0 symbol is one, which is what lets the page carry the existing
/// vocabulary — and its balance numbers — while the atomic grammar grows alongside it.
enum MarkContent: Codable, Equatable, Sendable {
    /// The dial a cluster is about. The anchor of the composition.
    case target(PressureTargetID)
    /// A cause. Says nothing until it's connected to a target.
    case source(PressureSourceID)
    /// A rung on a ladder, modifying whichever source it's connected to.
    case qualifier(QualifierID)
    /// One glyph meaning several things at once. Self-contained — needs no connections.
    case compound(SymbolID)
    /// A whole statement written as one mark. The pre-session-14 shape, kept so existing pages
    /// still resolve.
    case rune(Sigil)
}

/// One durable written-vocabulary identity for the Library Dictionary.
///
/// The identity carries no player-facing name or effect, so seeing an unknown glyph cannot leak
/// catalogue semantics through the save. Legacy whole-rune marks contribute their source and
/// target identities rather than creating a fifth vocabulary family.
enum LexemeIdentity: Codable, Equatable, Hashable, Sendable {
    case target(PressureTargetID)
    case source(PressureSourceID)
    case qualifier(QualifierID)
    case compound(SymbolID)

    var glyphID: String {
        switch self {
        case .target(let id): id.rawValue
        case .source(let id): id.rawValue
        case .qualifier(let id): id.rawValue
        case .compound(let id): id.rawValue
        }
    }

    var categoryOrder: Int {
        switch self {
        case .target: 0
        case .source: 1
        case .qualifier: 2
        case .compound: 3
        }
    }
}

extension MarkContent {
    var encounteredLexemes: Set<LexemeIdentity> {
        switch self {
        case .target(let id): [.target(id)]
        case .source(let id): [.source(id)]
        case .qualifier(let id): [.qualifier(id)]
        case .compound(let id): [.compound(id)]
        case .rune(let sigil): [.source(sigil.source), .target(sigil.target)]
        }
    }
}

extension Page {
    var encounteredLexemes: Set<LexemeIdentity> {
        runes.reduce(into: Set<LexemeIdentity>()) { result, rune in
            result.formUnion(rune.content.encounteredLexemes)
        }
    }
}

/// A declared connection between two adjacent marks.
///
/// **Adjacency constrains; the connector declares intent** (session 14 §2). Adjacency alone can't
/// do the job — the page is small, so on a full page nearly everything touches everything, and
/// everything would join to everything. A connector alone can't either, because you could then link
/// across the page and relative position would stop meaning anything.
///
/// **No page space is spent on a link.** It's a relationship, not an object — which matters a great
/// deal on a page that holds about seven crude sigils.
struct MarkLink: Codable, Equatable, Hashable, Sendable {
    var a: InstanceID
    var b: InstanceID

    /// Stored smallest-first so a link is the same link whichever way it was drawn.
    init(_ first: InstanceID, _ second: InstanceID) {
        if first.rawValue <= second.rawValue { a = first; b = second }
        else { a = second; b = first }
    }

    func involves(_ id: InstanceID) -> Bool { a == id || b == id }
    func other(than id: InstanceID) -> InstanceID? { a == id ? b : (b == id ? a : nil) }
}

/// The page. One page, your whole life.
///
/// **It never grows** (decisions-session-10 §1). An earlier version of the rune spec said the page
/// expanded through permanent unlocks; that was Claude's invention and it contradicts the actual
/// design, because it competes with the thing that *is* the progression — learning to write
/// smaller. Finer instruments shrink footprints and learned compounds compress meaning, and that
/// ladder is dramatic without the grid ever changing: at 6×6, charcoal fits about seven sigils and
/// a fountain pen fits thirty-six.
///
/// Size is also a **UI constraint rather than a dial**: the whole page has to be visible while
/// composing, which on a portrait iPhone caps it around seven or eight cells across.
///
/// `width` and `height` are stored rather than read from `Tuning` so that an existing save keeps
/// the page it was written on if the dimensions are ever re-tuned.
struct Page: Codable, Equatable, Sendable {
    var width: Int
    var height: Int
    var runes: [PlacedRune]
    /// Declared connections. A cluster is a connected component of this graph.
    var links: Set<MarkLink> = []

    init(width: Int = Tuning.Page.startingWidth,
         height: Int = Tuning.Page.startingHeight,
         runes: [PlacedRune] = [],
         links: Set<MarkLink> = []) {
        self.width = width
        self.height = height
        self.runes = runes
        self.links = links
    }

    /// Tolerant, per the policy in `Migrations.swift`. Caught by the save-tolerance tripwire
    /// before it shipped, which is what that test is for.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        width = try c.decodeIfPresent(Int.self, forKey: .width) ?? Tuning.Page.startingWidth
        height = try c.decodeIfPresent(Int.self, forKey: .height) ?? Tuning.Page.startingHeight
        runes = try c.decodeIfPresent([PlacedRune].self, forKey: .runes) ?? []
        links = try c.decodeIfPresent(Set<MarkLink>.self, forKey: .links) ?? []
    }

    var capacity: Int { width * height }
    var usedCells: Int { runes.reduce(0) { $0 + $1.cells.count } }
    var freeCells: Int { capacity - usedCells }

    var occupied: Set<PageCell> { Set(runes.flatMap(\.cells)) }

    func contains(_ cell: PageCell) -> Bool {
        cell.column >= 0 && cell.row >= 0 && cell.column < width && cell.row < height
    }

    /// The sigils this page says, in a stable order.
    ///
    /// Sorted by id rather than by position, so resolution cannot accidentally come to depend on
    /// layout. Reading order is not meaning.
    /// Everything this page says.
    ///
    /// Self-contained marks say what they say; connected clusters are read target-first. Sorted by
    /// identity rather than by position, because **absolute position carries no meaning** — only
    /// which sigils touch which does (session 14 §3).
    var sigils: [Sigil] { PageRules.sigils(of: self) }

    /// The compounds written here, in the order they were placed. This is the v0 vocabulary, and
    /// every existing rule — stability, yields, spawn tables — still reads it.
    var symbolIDs: [SymbolID] { runes.compactMap(\.symbolID) }

    func rune(at cell: PageCell) -> PlacedRune? {
        runes.first { $0.cells.contains(cell) }
    }
}

/// Stable identity for one player-authored reusable page Template.
///
/// Names and array positions are presentation; every destructive or replacing action targets this
/// identity so a stale popover can never mutate a different Template.
struct PageTemplateID: RawRepresentable, Codable, Equatable, Hashable, Comparable, Sendable {
    var rawValue: UInt64
    init(rawValue: UInt64) { self.rawValue = rawValue }
    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

struct SavedPageTemplate: Codable, Equatable, Identifiable, Sendable {
    var id: PageTemplateID
    var name: String
    var page: Page
    var creationOrdinal: UInt64
}

enum PageTemplateRules {
    static let capacity = 20
    static let maximumNameLength = 40
    static let firstLoadedMarkID: UInt64 = 0x5450_0000_0000_0001

    static func normalizedName(_ proposed: String) -> String {
        let trimmed = proposed.trimmingCharacters(in: .whitespacesAndNewlines)
        let chosen = trimmed.isEmpty ? "Untitled page" : trimmed
        return String(chosen.prefix(maximumNameLength))
    }

    /// Copies a frozen Template into a fresh draft identity namespace. Mark order, geometry and
    /// topology stay exact; only identities change.
    static func remap(_ page: Page, nextID: inout UInt64) -> Page? {
        let originalIDs = page.runes.map(\.id)
        guard Set(originalIDs).count == originalIDs.count else { return nil }
        let endpoints = Set(originalIDs)
        guard page.links.allSatisfy({ $0.a != $0.b && endpoints.contains($0.a) && endpoints.contains($0.b) })
        else { return nil }

        var mapping: [InstanceID: InstanceID] = [:]
        for id in originalIDs {
            mapping[id] = InstanceID(rawValue: nextID)
            nextID &+= 1
        }
        var runes = page.runes
        for index in runes.indices {
            guard let replacement = mapping[runes[index].id] else { return nil }
            runes[index].id = replacement
            if case .rune(var sigil) = runes[index].content {
                sigil.id = InstanceID(rawValue: nextID)
                nextID &+= 1
                runes[index].content = .rune(sigil)
            }
        }
        let links = Set(page.links.compactMap { link -> MarkLink? in
            guard let a = mapping[link.a], let b = mapping[link.b] else { return nil }
            return MarkLink(a, b)
        })
        guard links.count == page.links.count else { return nil }
        return Page(width: page.width, height: page.height, runes: runes, links: links)
    }

    /// Template identity is composition, not the disposable instance IDs assigned on each load.
    /// Canonical remapping lets the UI and actions recognize an already-loaded page without
    /// weakening malformed-link validation.
    static func structurallyEquivalent(_ lhs: Page, _ rhs: Page) -> Bool {
        var lhsID: UInt64 = 1
        var rhsID: UInt64 = 1
        guard let canonicalLHS = remap(lhs, nextID: &lhsID),
              let canonicalRHS = remap(rhs, nextID: &rhsID)
        else { return false }
        return canonicalLHS == canonicalRHS
    }
}

/// Stable authored identity for a physical, pre-inscribed World Page.
struct WorldPageDefinitionID: StringIdentifier {
    var rawValue: String
    init(rawValue: String) { self.rawValue = rawValue }
}

/// The immutable authored facts shared by every copy of a World Page definition.
///
/// Only the three opening pages belong to this registry. Repeatable field pages, templates and
/// unknown-glyph presentation are separate contracts and must not leak into the starter grant.
struct WorldPageDefinition: Codable, Equatable, Identifiable, Sendable {
    enum Disposition: String, Codable, Sendable { case starterUnique }

    var id: WorldPageDefinitionID
    var title: String
    var disposition: Disposition
    var provenance: String
    var page: Page
    var copiedCost: Int
    var worldPageCost: Int
    var seed: UInt64
    var promise: String
}

/// One physical page in the campaign folio. Definition identity is not instance identity: the
/// latter is what an eventual bind transaction must quote, revalidate and consume exactly once.
struct WorldPageInstance: Codable, Equatable, Identifiable, Sendable {
    var id: InstanceID
    var definition: WorldPageDefinition
}

/// Frozen proof of the exact physical page used to create a world.
///
/// History retains the complete authored snapshot instead of looking the definition up again, so
/// later catalogue edits cannot rewrite what the player spent or what that departed world said.
struct WorldPageUseReceipt: Codable, Equatable, Sendable {
    var instanceID: InstanceID
    var definition: WorldPageDefinition
    var essencePaid: Int
}

enum WorldPageCatalog {
    // BEGIN GENERATED STARTER WORLD PAGES — Scripts/generate_world_pages.py
    static let authoritySHA256 = "04f73e3cb93850ec1f449d9f302c4ca276ac1091631ed81322458d8b8142c534"
    static let openMeadowID: WorldPageDefinitionID = "starter_open_meadow"
    static let rainwashedShoreID: WorldPageDefinitionID = "starter_rainwashed_shore"
    static let stoneHollowID: WorldPageDefinitionID = "starter_stone_hollow"

    /// Reserved, explicit physical identities. They do not depend on inventory insertion order or
    /// the general item allocator and therefore remain byte-stable across relaunch and migration.
    static let starterInstances: [WorldPageInstance] = zip(
        [InstanceID(rawValue: 0x5750_0000_0000_0001),
         InstanceID(rawValue: 0x5750_0000_0000_0002),
         InstanceID(rawValue: 0x5750_0000_0000_0003)],
        starterDefinitions
    ).map { WorldPageInstance(id: $0.0, definition: $0.1) }

    static let starterDefinitions: [WorldPageDefinition] = [
        definition(id: openMeadowID, title: "Open Meadow",
                   provenance: "A clean practice page, already written in rough charcoal.",
                   marks: [("plains", 1, "crude_smear", 0, 0),
                           ("verdant", 2, "crude_smear", 3, 3)],
                   copiedCost: 21, worldPageCost: 14, seed: 2,
                   promise: "Open, living, modestly resourced and safe enough to learn the opening loop."),
        definition(id: rainwashedShoreID, title: "Rainwashed Shore",
                   provenance: "A clean practice page with one broad charcoal mark.",
                   marks: [("archipelago", 1, "crude_smear", 1, 2)],
                   copiedCost: 18, worldPageCost: 14, seed: 26,
                   promise: "A readable water-and-relief contrast without an opening lethality spike."),
        definition(id: stoneHollowID, title: "Stone Hollow",
                   provenance: "A clean practice page with charcoal rubbed into the grain.",
                   marks: [("caverns", 1, "crude_smear", 0, 1),
                           ("common_ore", 2, "crude_block", 4, 3)],
                   copiedCost: 22, worldPageCost: 16, seed: 23,
                   promise: "Stone, enclosure and ordinary ore within the accepted level-one envelope.")
    ]
    // END GENERATED STARTER WORLD PAGES

    static func definition(_ id: WorldPageDefinitionID) -> WorldPageDefinition? {
        starterDefinitions.first { $0.id == id }
    }

    private static func definition(
        id: WorldPageDefinitionID, title: String, provenance: String,
        marks: [(String, UInt64, String, Int, Int)], copiedCost: Int, worldPageCost: Int,
        seed: UInt64, promise: String
    ) -> WorldPageDefinition {
        let page = Page(runes: marks.map { symbol, markID, shapeID, column, row in
            PlacedRune(id: InstanceID(rawValue: markID), content: .compound(SymbolID(rawValue: symbol)),
                       hand: .crude, origin: PageCell(column: column, row: row), shapeID: shapeID)
        })
        return WorldPageDefinition(id: id, title: title, disposition: .starterUnique,
                                   provenance: provenance, page: page, copiedCost: copiedCost,
                                   worldPageCost: worldPageCost, seed: seed, promise: promise)
    }
}
