import Foundation

/// One sentence the world-description panel can say about a world.
///
/// The panel is the only place the pressure model becomes visible to the player, and it's the
/// surface a Library hint page is matched against — the clue says *a vault under cold stone*, the
/// desk says *frozen over, enclosed, hard stone underfoot*, and the player does the join. So the
/// wording here is gameplay, not flavour: it must describe **what the world is like**, never list
/// conditions and never name a sigil, target or value (`contradiction-danger-spec.md` §6).
struct DescriptionClauseDef: Codable, Equatable, Identifiable, Sendable {
    var id: String
    /// Which part of the world this talks about. One clause per group survives, so the panel says
    /// several things about several subjects rather than six things about the weather.
    var group: String
    var text: String
    var polarity: Polarity
    /// Highest priority wins within a group. A clause at priority 1 with no conditions is the
    /// group's fallback, so every group always has something to say.
    var priority: Int
    var conditions: [PressureCondition]

    /// Whether the clause is true of a world.
    func holds(in readings: PressureReadings) -> Bool {
        conditions.allSatisfy { $0.holds(in: readings) }
    }

    /// Drives the red/green underline, so the description doubles as the instability explanation —
    /// you read *why* a world is fragile in the same sentence that tells you what it's like.
    ///
    /// **PLACEHOLDER: authored, and it shouldn't stay that way.** Polarity is a property of what
    /// made the world, and right now it's hand-declared per clause. When instability becomes
    /// derived (decisions-session-6, Q19 option 4) this should fall out of the same profiling
    /// rather than being asserted here.
    enum Polarity: String, Codable, Sendable {
        case stabilising, destabilising, neutral
    }
}

/// What the panel shows: prose about the world, plus any contradictions named outright.
struct WorldDescription: Equatable, Sendable {
    var clauses: [DescriptionClauseDef]
    /// Named explicitly, never folded into a number. Mystcraft's real failure was that you couldn't
    /// tell *why* a world was unstable; this is the fix.
    var contradictions: [ContradictionDef]

    var sentence: String { clauses.map(\.text).joined(separator: " ") }
    var isEmpty: Bool { clauses.isEmpty && contradictions.isEmpty }
}
