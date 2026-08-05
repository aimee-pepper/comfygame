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
    /// - Parameter about: which targets may be spoken of. `nil` describes everything, which is what
    ///   you want for a world you're standing in. The **desk** passes only the targets the page
    ///   actually touches: a target nobody wrote about is going to be rolled at bind, so describing
    ///   it would either spoil the surprise or — worse — describe it wrongly, promising "ordinary
    ///   daylight" for a world that hasn't decided yet.
    ///
    ///   Secondaries count as written. If you wrote Sun and the world comes out hot, the panel says
    ///   so; that's exactly how the implicit effects are meant to be discovered rather than printed
    ///   on the rune (decisions-session-8 §2).
    static func describe(_ readings: PressureReadings,
                         contradictions: [ContradictionDef] = [],
                         analysisTier: Int = Tuning.Analysis.startingTier,
                         about targets: Set<PressureTargetID>? = nil) -> WorldDescription {
        let speakable = targets.map { Set($0.map(\.rawValue)) }
        let matching = ContentCatalog.shared.descriptionClauses.filter { clause in
            (speakable?.contains(clause.group) ?? true) && clause.holds(in: readings)
        }
        let byGroup = Dictionary(grouping: matching, by: \.group)

        // Say everything there is to say. One clause per group already bounds this at the number
        // of pressure targets, and Aimee's call (5 Aug) is that a description running the full
        // length reads fine — a world that is remarkable in eight ways should say eight things.
        let clauses = groupOrder.compactMap { group in
            byGroup[group]?.max { lhs, rhs in
                (lhs.priority, lhs.id) < (rhs.priority, rhs.id)
            }
        }
        return WorldDescription(clauses: clauses, contradictions: contradictions,
                                analysisTier: analysisTier)
    }

    /// Describes what a page says, contradictions included.
    static func describe(page sigils: [Sigil], seed: UInt64? = nil,
                         analysisTier: Int = Tuning.Analysis.startingTier) -> WorldDescription {
        let readings = seed.map { PressureRules.resolve(sigils, fillingUnwrittenWith: $0) }
            ?? PressureRules.resolve(sigils)
        return describe(readings,
                        contradictions: ContradictionRules.fired(in: sigils, readings: readings),
                        analysisTier: analysisTier)
    }

    /// Group order follows the targets, with each group named for the target it describes.
    /// Every target a page touches, secondaries included — what the desk is entitled to describe.
    static func targetsTouched(by sigils: [Sigil]) -> Set<PressureTargetID> {
        Set(sigils.flatMap { ContentCatalog.shared.pressureSource($0.source)?.targets ?? [] })
    }

    static var groupOrder: [String] {
        ContentCatalog.shared.pressureTargetsInOrder.map(\.id.rawValue)
    }
}
