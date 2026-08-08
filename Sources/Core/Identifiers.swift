import Foundation

/// String-backed typed IDs for everything that lives in a content catalog.
///
/// All content (symbols, creatures, resources, gambit pieces, stations, items) is *data*, not
/// code — see CLAUDE.md. IDs are therefore plain strings that must match the `id` field in the
/// JSON under `Sources/Content/Data/`. `ContentCatalog.validate()` proves the cross-references
/// at launch and in tests, so a typo fails loudly instead of silently vanishing at runtime.
protocol StringIdentifier: Hashable, Codable, Sendable, RawRepresentable, CodingKeyRepresentable,
                           ExpressibleByStringLiteral, CustomStringConvertible
where RawValue == String, StringLiteralType == String {
    init(rawValue: String)
}

extension StringIdentifier {
    public init(stringLiteral value: String) { self.init(rawValue: value) }
    public var description: String { rawValue }

    // CodingKeyRepresentable makes `[SomeID: Value]` encode as a JSON *object* rather than the
    // flat alternating-element array Swift uses by default. Keeps saves human-readable.
    public var codingKey: CodingKey { StringCodingKey(rawValue) }
    public init?<T: CodingKey>(codingKey: T) { self.init(rawValue: codingKey.stringValue) }
}

struct StringCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int? { nil }
    init(_ value: String) { stringValue = value }
    init?(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { nil }
}

struct SymbolID: StringIdentifier {
    var rawValue: String
    init(rawValue: String) { self.rawValue = rawValue }
}

/// A slot in a book.
///
/// Deliberately *not* an enum. The Terrain/Biome/Bounty/Quirk taxonomy is a placeholder and is
/// being replaced by environmental-pressure sigils (decisions-log, session 2), so slot count and
/// slot types are content, not code. Nothing anywhere may assume how many slots a book has.
struct SlotID: StringIdentifier, Identifiable {
    var rawValue: String
    init(rawValue: String) { self.rawValue = rawValue }
    var id: String { rawValue }
}

struct CreatureID: StringIdentifier {
    var rawValue: String
    init(rawValue: String) { self.rawValue = rawValue }
}

/// Stackable resources (Ore, Fiber, Essence-raw, Motes) — do not consume inventory slots.
struct ResourceID: StringIdentifier {
    var rawValue: String
    init(rawValue: String) { self.rawValue = rawValue }
}

/// Slot-consuming items (gear, consumables, curios, keys).
struct ItemID: StringIdentifier {
    var rawValue: String
    init(rawValue: String) { self.rawValue = rawValue }
}

struct PressureTargetID: StringIdentifier {
    var rawValue: String
    init(rawValue: String) { self.rawValue = rawValue }
}

struct PressureSourceID: StringIdentifier {
    var rawValue: String
    init(rawValue: String) { self.rawValue = rawValue }
}

/// One rung of a qualifier ladder — Great, Vast, Countless.
struct QualifierID: StringIdentifier {
    var rawValue: String
    init(rawValue: String) { self.rawValue = rawValue }
}

/// Someone scattered by the sundering. Found by writing the world they're in.
struct TravellerID: StringIdentifier {
    var rawValue: String
    init(rawValue: String) { self.rawValue = rawValue }
}

/// One page torn from somebody's diary.
struct DiaryPageID: StringIdentifier {
    var rawValue: String
    init(rawValue: String) { self.rawValue = rawValue }
}

/// A named entry in the contradiction catalogue. Contradiction is authored, never computed.
struct ContradictionID: StringIdentifier {
    var rawValue: String
    init(rawValue: String) { self.rawValue = rawValue }
}

/// A discrete placed thing — a ruin, a landmark, a hive. Distinct from a pressure, which is a
/// condition rather than an object.
struct SiteID: StringIdentifier {
    var rawValue: String
    init(rawValue: String) { self.rawValue = rawValue }
}

struct ResearchBranchID: StringIdentifier {
    var rawValue: String
    init(rawValue: String) { self.rawValue = rawValue }
}

struct ResearchNodeID: StringIdentifier {
    var rawValue: String
    init(rawValue: String) { self.rawValue = rawValue }
}

struct GambitComponentID: StringIdentifier, Identifiable {
    var rawValue: String
    init(rawValue: String) { self.rawValue = rawValue }
    var id: String { rawValue }
}

/// A combat tree — Offense, Defense, Craft.
struct CombatTreeID: StringIdentifier {
    var rawValue: String
    init(rawValue: String) { self.rawValue = rawValue }
}

/// One of the nine branches. **A class is which three of these you finished.**
struct CombatBranchID: StringIdentifier {
    var rawValue: String
    init(rawValue: String) { self.rawValue = rawValue }
}

struct SkillID: StringIdentifier {
    var rawValue: String
    init(rawValue: String) { self.rawValue = rawValue }
}

/// Base stations are a data-driven list, not hardcoded buttons — the base grows in v1+.
struct StationID: StringIdentifier {
    var rawValue: String
    init(rawValue: String) { self.rawValue = rawValue }
}

struct ConstellationNodeID: StringIdentifier {
    var rawValue: String
    init(rawValue: String) { self.rawValue = rawValue }
}

/// Instance identity for things that exist per-run or per-item-copy rather than per-catalog-entry.
struct InstanceID: Hashable, Codable, Sendable, CustomStringConvertible {
    var rawValue: UInt64
    init(rawValue: UInt64) { self.rawValue = rawValue }
    var description: String { String(rawValue) }
}
