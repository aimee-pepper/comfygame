import Foundation

/// What a page contradicts, and what that costs.
///
/// The load-bearing rule, from `docs/contradiction-danger-spec.md` §1: **contradiction fires only
/// from the catalogue.** There is deliberately no path in this file from `opposedMagnitude` to a
/// penalty, and `ContradictionTests` asserts that no amount of honest opposition produces one.
enum ContradictionRules {

    /// Every named contradiction present in a page, in catalogue order.
    static func fired(in sigils: [Sigil], readings: PressureReadings) -> [ContradictionDef] {
        ContentCatalog.shared.contradictions.filter { $0.fires(sigils: sigils, readings: readings) }
    }

    static func fired(in sigils: [Sigil]) -> [ContradictionDef] {
        fired(in: sigils, readings: PressureRules.resolve(sigils))
    }

    /// What the contradictions cost, in the Stability headline's own units.
    ///
    /// Additive base plus a small, *disclosed* superlinear term (§3). Purely additive under-sells a
    /// world at war with itself in several ways; purely multiplicative makes the third contradiction
    /// do five times the work of the first, invisibly — and players who can't reason about marginal
    /// cost simply learn never to stack, which kills the interesting writing.
    ///
    /// The escalation term is returned separately because the spec requires it to be shown as its
    /// own line. Hidden superlinearity is the failure mode.
    static func penalty(for contradictions: [ContradictionDef]) -> (base: Int, escalation: Int) {
        let base = contradictions.reduce(0) { $0 + $1.instability }
        return (base, escalation(count: contradictions.count))
    }

    /// Zero for one contradiction; small and rising from two.
    static func escalation(count: Int) -> Int {
        guard count >= 2 else { return 0 }
        return (count - 1) * Tuning.Contradiction.escalationPerAdditional
    }

    /// The whole cost, for callers that don't need the two terms apart.
    static func totalPenalty(for contradictions: [ContradictionDef]) -> Int {
        let parts = penalty(for: contradictions)
        return parts.base + parts.escalation
    }
}
