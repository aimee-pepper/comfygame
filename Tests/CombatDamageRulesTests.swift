import XCTest
@testable import Bookbinder

final class CombatDamageRulesTests: XCTestCase {
    private let coverings = [
        Covering(),
        Covering(hardness: 95, length: 5, coverage: 95),
        Covering(hardness: 5, length: 95, coverage: 95),
        Covering(hardness: 60, length: 60, coverage: 50),
    ]

    func testExactResolutionMatchesLegacyFormulaExhaustively() {
        let kinds: [DamageKind?] = [nil] + DamageKind.allCases.map(Optional.some)
        let rules: [WildRule?] = [nil] + WildRule.allCases.map(Optional.some)

        for rolledPower in [0, 1, 7, 19, 40] {
            for kind in kinds {
                for covering in coverings {
                    for rule in rules {
                        for standingBack in [false, true] {
                            for reach in Reach.allCases {
                                for armour in [0, 1, 9, 50] {
                                    for ignoresArmour in [false, true] {
                                        let context = CombatDamageRules.Context(
                                            damageKind: kind,
                                            covering: covering,
                                            wildRule: rule,
                                            standingBack: standingBack,
                                            reach: reach,
                                            armour: armour,
                                            ignoresArmour: ignoresArmour
                                        )
                                        let actual = CombatDamageRules.resolve(
                                            rolledPower: rolledPower, in: context)
                                        let expected = legacyFormula(rolledPower: rolledPower,
                                                                     context: context)
                                        XCTAssertEqual(actual, expected, failure(context, rolledPower))
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    func testPreviewEndpointsAreExactResolutionsAndNondecreasing() {
        for kind in ([nil] + DamageKind.allCases.map(Optional.some)) {
            for covering in coverings {
                let context = CombatDamageRules.Context(
                    damageKind: kind,
                    covering: covering,
                    wildRule: .twoNatured,
                    standingBack: true,
                    reach: .mid,
                    armour: 11
                )
                let preview = CombatDamageRules.preview(rolledPower: 3...31, in: context)
                XCTAssertEqual(preview.lower,
                               CombatDamageRules.resolve(rolledPower: 3, in: context))
                XCTAssertEqual(preview.upper,
                               CombatDamageRules.resolve(rolledPower: 31, in: context))
                XCTAssertLessThanOrEqual(preview.lower.finalDamage, preview.upper.finalDamage)
                XCTAssertLessThanOrEqual(preview.lower.rawDamage, preview.upper.rawDamage)
            }
        }
    }

    func testNilKindHasNeutralMatchupAndNoPierceIgnore() {
        let result = CombatDamageRules.resolve(
            rolledPower: 20,
            in: .init(damageKind: nil,
                      covering: Covering(hardness: 100, length: 0, coverage: 100),
                      armour: 10)
        )
        XCTAssertEqual(result.matchup, 1)
        XCTAssertEqual(result.armourIgnored, 0)
        XCTAssertEqual(result.rawDamage, 20)
        XCTAssertEqual(result.finalDamage, 10)
    }

    func testExplicitArmourIgnoreOverridesPiercePartialIgnore() {
        let context = CombatDamageRules.Context(
            damageKind: .pierce,
            covering: Covering(hardness: 100, length: 0, coverage: 100),
            armour: 30,
            ignoresArmour: true
        )
        let result = CombatDamageRules.resolve(rolledPower: 10, in: context)
        XCTAssertEqual(result.armourIgnored, 1)
        XCTAssertEqual(result.effectiveArmour, 0)
        XCTAssertEqual(result.finalDamage, result.rawDamage)
    }

    func testOnlyFarReachEscapesBackRankPenalty() {
        let close = CombatDamageRules.resolve(
            rolledPower: 20,
            in: .init(damageKind: nil, standingBack: true, reach: .close))
        let mid = CombatDamageRules.resolve(
            rolledPower: 20,
            in: .init(damageKind: nil, standingBack: true, reach: .mid))
        let far = CombatDamageRules.resolve(
            rolledPower: 20,
            in: .init(damageKind: nil, standingBack: true, reach: .far))
        XCTAssertEqual(close, mid)
        XCTAssertLessThan(close.rawDamage, far.rawDamage)
        XCTAssertEqual(far.rankMultiplier, 1)
    }

    private func legacyFormula(rolledPower: Int,
                               context: CombatDamageRules.Context) -> CombatDamageRules.Result {
        let matchup = context.damageKind.map {
            legacyEffectiveness(of: $0, against: context.covering, breaking: context.wildRule)
        } ?? 1
        let rankMultiplier = context.standingBack && context.reach != .far
            ? 1 - Tuning.Encounter.backRankMeleePenalty
            : 1
        let raw = Int((Double(rolledPower) * matchup * rankMultiplier).rounded())
        let ignored = context.ignoresArmour
            ? 1.0
            : (context.damageKind == .pierce ? Tuning.Encounter.pierceArmourIgnored : 0)
        let effectiveArmour = Int((Double(context.armour) * (1 - ignored)).rounded())
        return .init(rolledPower: rolledPower,
                     matchup: matchup,
                     rankMultiplier: rankMultiplier,
                     isCritical: false,
                     rawDamage: raw,
                     armourIgnored: ignored,
                     effectiveArmour: effectiveArmour,
                     finalDamage: max(Tuning.Encounter.minimumDamage, raw - effectiveArmour))
    }

    func testSteadyHandCriticalRoundsOnceAfterMatchupAndBeforeArmour() {
        let covering = Covering(hardness: 50, length: 0, coverage: 100)
        let ordinary = CombatDamageRules.resolve(
            rolledPower: 9,
            in: .init(damageKind: .crush, covering: covering, armour: 4))
        let critical = CombatDamageRules.resolve(
            rolledPower: 9,
            in: .init(damageKind: .crush, covering: covering, armour: 4, isCritical: true))
        XCTAssertEqual(critical.rawDamage, Int((Double(ordinary.rawDamage) * 1.5).rounded()))
        XCTAssertEqual(critical.effectiveArmour, ordinary.effectiveArmour)
        XCTAssertEqual(critical.finalDamage, max(Tuning.Encounter.minimumDamage,
                                                  critical.rawDamage - ordinary.effectiveArmour))
        XCTAssertTrue(critical.isCritical)
    }

    private func legacyEffectiveness(of kind: DamageKind, against covering: Covering,
                                     breaking rule: WildRule?) -> Double {
        if rule == .twoNatured {
            return DamageKind.allCases.map { legacyEffectiveness(of: $0, against: covering) }.max()!
        }
        return legacyEffectiveness(of: kind, against: covering)
    }

    private func legacyEffectiveness(of kind: DamageKind, against covering: Covering) -> Double {
        let hard = covering.armourValue / Tuning.Pressure.scaleMaximum
        let padded = covering.insulation / Tuning.Pressure.scaleMaximum
        let value: Double = switch kind {
        case .pierce, .crush:
            1 + hard * Tuning.Encounter.matchupBonus - padded * Tuning.Encounter.matchupPenalty
        case .rend:
            1 + padded * Tuning.Encounter.matchupBonus - hard * Tuning.Encounter.matchupPenalty
        }
        return max(Tuning.Encounter.minimumMatchup, value)
    }

    private func failure(_ context: CombatDamageRules.Context, _ power: Int) -> String {
        "power=\(power), kind=\(String(describing: context.damageKind)), rule=\(String(describing: context.wildRule)), back=\(context.standingBack), reach=\(context.reach), armour=\(context.armour), ignore=\(context.ignoresArmour)"
    }
}
