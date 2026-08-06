import Foundation

/// A qualifier: a step on a ladder, written as its own sigil and attached to a source by connecting
/// to it.
///
/// **A qualifier earns its place only if no generic ladder covers it** (decisions-session-14 §4).
/// *Bright* is cut — a great sun **is** a bright sun. But *big* is three different ideas and must
/// not collapse into one word: a big sun is intense, a big sea is extensive, a big swarm is
/// numerous. Merging them would make "a small but blinding light" or "a vast shallow sea"
/// unwriteable, and those are exactly the compositions the system exists for.
struct QualifierDef: Codable, Equatable, Identifiable, Sendable {
    var id: QualifierID
    /// Which ladder this is a rung of.
    var ladder: Ladder
    var name: String
    /// Position on the ladder, low to high.
    var step: Int
    var icon: String
    /// Target-specific qualifiers survive only where no generic ladder can say it. Empty = generic.
    var onlyFor: [PressureTargetID]

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(QualifierID.self, forKey: .id)
        ladder = try c.decode(Ladder.self, forKey: .ladder)
        name = try c.decode(String.self, forKey: .name)
        step = try c.decode(Int.self, forKey: .step)
        icon = try c.decode(String.self, forKey: .icon)
        onlyFor = try c.decodeIfPresent([PressureTargetID].self, forKey: .onlyFor) ?? []
    }

    /// The three generic workhorses apply across all eight targets; the rest are narrow by design.
    var isGeneric: Bool { onlyFor.isEmpty }

    func applies(to target: PressureTargetID) -> Bool {
        isGeneric || onlyFor.contains(target)
    }

    enum Ladder: String, Codable, CaseIterable, Sendable {
        case intensity, scale, count, phase, direction

        var displayName: String { rawValue.capitalized }
    }
}
