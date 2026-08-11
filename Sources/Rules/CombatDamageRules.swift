import Foundation

/// Pure arithmetic shared by combat previews and a landed legacy strike.
///
/// Accuracy, RNG, statuses, receipts, retaliation, and mutation deliberately live outside this
/// type. Callers resolve their roll first, then pass that exact integer here.
enum CombatDamageRules {
    struct Context: Equatable, Sendable {
        var damageKind: DamageKind?
        var covering: Covering
        var wildRule: WildRule?
        var standingBack: Bool
        var reach: Reach
        var armour: Int
        var ignoresArmour: Bool

        init(damageKind: DamageKind?, covering: Covering = Covering(),
             wildRule: WildRule? = nil, standingBack: Bool = false,
             reach: Reach = .close, armour: Int = 0, ignoresArmour: Bool = false) {
            self.damageKind = damageKind
            self.covering = covering
            self.wildRule = wildRule
            self.standingBack = standingBack
            self.reach = reach
            self.armour = armour
            self.ignoresArmour = ignoresArmour
        }
    }

    struct Result: Equatable, Sendable {
        let rolledPower: Int
        let matchup: Double
        let rankMultiplier: Double
        let rawDamage: Int
        let armourIgnored: Double
        let effectiveArmour: Int
        let finalDamage: Int
    }

    struct Preview: Equatable, Sendable {
        let lower: Result
        let upper: Result
    }

    static func resolve(rolledPower: Int, in context: Context) -> Result {
        let matchup = context.damageKind.map {
            effectiveness(of: $0, against: context.covering, breaking: context.wildRule)
        } ?? 1
        let rankMultiplier = context.standingBack && context.reach != .far
            ? 1 - Tuning.Encounter.backRankMeleePenalty
            : 1
        let raw = Int((Double(rolledPower) * matchup * rankMultiplier).rounded())
        let ignored = context.ignoresArmour
            ? 1
            : (context.damageKind == .pierce ? Tuning.Encounter.pierceArmourIgnored : 0)
        let effectiveArmour = Int((Double(context.armour) * (1 - ignored)).rounded())
        return Result(
            rolledPower: rolledPower,
            matchup: matchup,
            rankMultiplier: rankMultiplier,
            rawDamage: raw,
            armourIgnored: ignored,
            effectiveArmour: effectiveArmour,
            finalDamage: max(Tuning.Encounter.minimumDamage, raw - effectiveArmour)
        )
    }

    static func preview(rolledPower range: ClosedRange<Int>, in context: Context) -> Preview {
        Preview(lower: resolve(rolledPower: range.lowerBound, in: context),
                upper: resolve(rolledPower: range.upperBound, in: context))
    }

    static func effectiveness(of kind: DamageKind, against covering: Covering,
                              breaking rule: WildRule? = nil) -> Double {
        guard rule == .twoNatured else { return effectiveness(of: kind, against: covering) }
        return DamageKind.allCases.map { effectiveness(of: $0, against: covering) }.max()
            ?? effectiveness(of: kind, against: covering)
    }

    static func effectiveness(of kind: DamageKind, against covering: Covering) -> Double {
        let hard = covering.armourValue / Tuning.Pressure.scaleMaximum
        let padded = covering.insulation / Tuning.Pressure.scaleMaximum
        let tuning = Tuning.Encounter.self
        let multiplier: Double = switch kind {
        case .pierce, .crush:
            1 + hard * tuning.matchupBonus - padded * tuning.matchupPenalty
        case .rend:
            1 + padded * tuning.matchupBonus - hard * tuning.matchupPenalty
        }
        return max(tuning.minimumMatchup, multiplier)
    }
}
