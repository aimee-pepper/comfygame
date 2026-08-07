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

        /// **What this ladder actually changes, and where.**
        ///
        /// Session 14 §4 makes Intensity, Scale and Count the generic workhorses — they may be
        /// *written* anywhere. That is not the same as *doing* something anywhere, and conflating
        /// the two cost a real session: Aimee read Mara's clue correctly, wrote **a giant sun**, and
        /// got a plain one, because Scale sets world size and is read off the Relief cluster alone
        /// (decisions-session-13 §5). The qualifier was offered, accepted and displayed, and did
        /// nothing (6 Aug).
        ///
        /// A qualifier that is inert isn't hidden — hiding it would fight session 14 and teach
        /// nothing. It is **named on the page**, so the mistake is visible where it was made.
        func changesAnything(for target: PressureTargetID) -> Bool {
            switch self {
            case .intensity: true
            case .scale: target == "relief"
            case .count: false          // written, read back, consumed by nothing. Wire it or cut it.
            case .phase, .direction: true
            }
        }

        /// What it *does* do, for the line that says so.
        var job: String {
            switch self {
            case .intensity: "how much of a thing there is"
            case .scale: "world size, and only on Relief"
            case .count: "nothing yet"
            case .phase: "what form the water takes"
            case .direction: "which way it faces"
            }
        }
    }
}
