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
        case .crude: "Charcoal"
        case .plain: "Pencil"
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

    /// What this mark says. A compound says several things at once — that's what makes it a
    /// compound rather than an abbreviation.
    var sigils: [Sigil] {
        switch content {
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

    var displayName: String {
        switch content {
        case .rune(let sigil): sigil.displayText
        case .compound(let id): ContentCatalog.shared.symbol(id)?.name ?? id.rawValue
        }
    }

    var icon: String {
        switch content {
        case .rune: "circle.hexagongrid"
        case .compound(let id): ContentCatalog.shared.symbol(id)?.icon ?? "questionmark"
        }
    }
}

/// What is actually written in a mark.
///
/// A **compound** is one glyph meaning what several runes mean together, at a smaller footprint
/// (rune spec §9). Every v0 symbol is one, which is what lets the page carry the existing
/// vocabulary without any of its numbers being re-tuned.
enum MarkContent: Codable, Equatable, Sendable {
    case rune(Sigil)
    case compound(SymbolID)
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

    init(width: Int = Tuning.Page.startingWidth,
         height: Int = Tuning.Page.startingHeight,
         runes: [PlacedRune] = []) {
        self.width = width
        self.height = height
        self.runes = runes
    }

    /// Tolerant, per the policy in `Migrations.swift`. Caught by the save-tolerance tripwire
    /// before it shipped, which is what that test is for.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        width = try c.decodeIfPresent(Int.self, forKey: .width) ?? Tuning.Page.startingWidth
        height = try c.decodeIfPresent(Int.self, forKey: .height) ?? Tuning.Page.startingHeight
        runes = try c.decodeIfPresent([PlacedRune].self, forKey: .runes) ?? []
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
    var sigils: [Sigil] { runes.sorted { $0.id.rawValue < $1.id.rawValue }.flatMap(\.sigils) }

    /// The compounds written here, in the order they were placed. This is the v0 vocabulary, and
    /// every existing rule — stability, yields, spawn tables — still reads it.
    var symbolIDs: [SymbolID] { runes.compactMap(\.symbolID) }

    func rune(at cell: PageCell) -> PlacedRune? {
        runes.first { $0.cells.contains(cell) }
    }
}
