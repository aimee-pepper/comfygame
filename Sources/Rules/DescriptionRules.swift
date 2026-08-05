import Foundation

/// Turns a resolved world into the sentence the Writing Desk shows.
///
/// Pure, like the rest of `Rules/`: the panel updates continuously as symbols are placed, and it
/// must describe the same world the bind will produce.
enum DescriptionRules {

    /// The best clause for each group, in the pressure targets' own order.
    ///
    /// Ordering by target rather than by priority is deliberate — the sentence should read the same
    /// way every time (light, then heat, then water, then ground…), so a player learns where to
    /// look. A description whose clauses shuffled by strength would be much harder to compare
    /// against a hint page.
    static func describe(_ readings: PressureReadings,
                         contradictions: [ContradictionDef] = []) -> WorldDescription {
        let matching = ContentCatalog.shared.descriptionClauses.filter { $0.holds(in: readings) }
        let byGroup = Dictionary(grouping: matching, by: \.group)

        // Say everything there is to say. One clause per group already bounds this at the number
        // of pressure targets, and Aimee's call (5 Aug) is that a description running the full
        // length reads fine — a world that is remarkable in eight ways should say eight things.
        let clauses = groupOrder.compactMap { group in
            byGroup[group]?.max { lhs, rhs in
                (lhs.priority, lhs.id) < (rhs.priority, rhs.id)
            }
        }
        return WorldDescription(clauses: clauses, contradictions: contradictions)
    }

    /// Describes what a page says, contradictions included.
    static func describe(page sigils: [Sigil], seed: UInt64? = nil) -> WorldDescription {
        let readings = seed.map { PressureRules.resolve(sigils, fillingUnwrittenWith: $0) }
            ?? PressureRules.resolve(sigils)
        return describe(readings, contradictions: ContradictionRules.fired(in: sigils, readings: readings))
    }

    /// Group order follows the targets, with each group named for the target it describes.
    static var groupOrder: [String] {
        ContentCatalog.shared.pressureTargetsInOrder.map(\.id.rawValue)
    }
}
