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
    /// - Parameter measuring: the subjects the player owns a field instrument for. The lens shows
    ///   numbers for these and for nothing else, however finely it is ground.
    static func describe(_ readings: PressureReadings,
                         contradictions: [ContradictionDef] = [],
                         analysisTier: Int = Tuning.Analysis.startingTier,
                         measuring instruments: Set<PressureTargetID> = [],
                         about targets: Set<PressureTargetID>? = nil,
                         derivedPolarity: [String: DescriptionClauseDef.Polarity] = [:],
                         precision: [PressureTargetID: RealityState.InstrumentPrecision] = [:]) -> WorldDescription {
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
        // **What you have measured, at a lens that can show it.** Both halves are required: an
        // instrument with no lens gives you a reading you can't put on a page, and a lens with no
        // instruments has nothing to show — which is exactly the dependency the pair is built on.
        let readable: [WorldDescription.Reading] = analysisTier >= Tuning.Analysis.targetsTier
            ? ContentCatalog.shared.pressureTargetsInOrder
                .filter { instruments.contains($0.id) }
                .map { target in
                    let reading = readings[target.id]
                    return WorldDescription.Reading(target: target.id, name: target.name,
                                                    icon: target.icon, peak: reading.peak,
                                                    floor: reading.floor,
                                                    hasFloor: target.dualValued,
                                                    precision: precision[target.id] ?? .fine)
                }
            : []

        return WorldDescription(clauses: clauses, contradictions: contradictions,
                                analysisTier: analysisTier, measured: readable,
                                derivedPolarity: derivedPolarity)
    }

    /// Describes what a page says, contradictions included.
    static func describe(page sigils: [Sigil], seed: UInt64? = nil,
                         analysisTier: Int = Tuning.Analysis.startingTier,
                         measuring instruments: Set<PressureTargetID> = []) -> WorldDescription {
        let readings = seed.map { PressureRules.resolve(sigils, fillingUnwrittenWith: $0) }
            ?? PressureRules.resolve(sigils)
        return describe(readings,
                        contradictions: ContradictionRules.fired(in: sigils, readings: readings),
                        analysisTier: analysisTier,
                        measuring: instruments,
                        derivedPolarity: stabilityPolarity(for: sigils))
    }

    /// Mark a subject from the stability change caused by the focuses explicitly bound to it.
    /// This is contextual and marginal, so stacking is accounted for; no prose label decides it.
    static func stabilityPolarity(for sigils: [Sigil]) -> [String: DescriptionClauseDef.Polarity] {
        let total = BookRules.greedDelta(for: sigils)
        let targets = Set(sigils.map(\.target))
        return Dictionary(uniqueKeysWithValues: targets.compactMap { target in
            let without = BookRules.greedDelta(for: sigils.filter { $0.target != target })
            let delta = total - without
            guard delta != 0 else { return nil }
            return (target.rawValue, delta < 0 ? .destabilising : .stabilising)
        })
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
