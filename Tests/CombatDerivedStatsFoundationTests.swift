import XCTest
@testable import Bookbinder

/// Dormant combat-v2 arithmetic only. These tests intentionally do not claim that production
/// preview, encounter creation, or committed actions consume this path yet.
final class CombatDerivedStatsFoundationTests: XCTestCase {
    private typealias Rules = CombatDerivedStatsRules

    private func node(_ path: String) -> CombatNodeID { CombatNodeID(rawValue: "combat." + path) }

    private func input(nodes: Set<CombatNodeID> = [],
                       choices: [CombatNodeID: StableChoiceID] = [:],
                       kind: DamageKind? = .crush,
                       rank: Rank = .front,
                       gearInitiative: Int = 0,
                       formation: [Rules.FormationMember] = []) -> Rules.Input {
        .init(actorIdentity: "binder", stats: CharacterStats(), rank: rank, isConscious: true,
              baseAttack: 10, baseMaximumHP: 20, baseInitiative: 8,
              weaponDamageKind: kind, gearInitiativeModifier: gearInitiative,
              equipmentArmour: 5, ownedNodeIDs: nodes, choices: choices,
              formation: formation)
    }

    func testLegacyAdapterMapsDepthWithoutPersistingOrActivatingV2() throws {
        var character = CharacterState()
        character.branchDepth = ["force": 2, "evasion": 1]
        let graph = ContentCatalog.shared.combatGraph
        let owned = Rules.legacyOwnedNodes(for: character, catalogue: graph)
        XCTAssertEqual(owned, CombatGraphRules.migratedLegacyNodes(
            branchDepth: character.branchDepth, catalogue: graph))

        let encoded = try JSONEncoder().encode(character)
        XCTAssertFalse(String(decoding: encoded, as: UTF8.self).contains("ownedCombatNodes"))
        XCTAssertEqual(CombatTreeRules.loadout(for: character),
                       CombatTreeRules.loadout(for: try JSONDecoder().decode(CharacterState.self,
                                                                             from: encoded)))
    }

    func testPhysicalRootsApplyOnlyToMatchingDamageKinds() {
        let heavy = node("offense.force.heavy_hand")
        let keen = node("offense.precision.keen_eye")
        XCTAssertEqual(Rules.derive(input(nodes: [heavy], kind: .crush)).matchingPhysicalDamageBonus, 2)
        XCTAssertEqual(Rules.derive(input(nodes: [heavy], kind: .rend)).matchingPhysicalDamageBonus, 0)
        XCTAssertEqual(Rules.derive(input(nodes: [keen], kind: .pierce)).matchingPhysicalDamageBonus, 2)
        XCTAssertEqual(Rules.derive(input(nodes: [keen], kind: .crush)).matchingPhysicalDamageBonus, 0)
    }

    func testInitiativeReliefRoundsTowardZeroAndMomentumUsesRelievedPenalty() {
        let quick = node("offense.swiftness.quick_step")
        let lightFrame = node("defense.evasion.light_frame")
        let lightTouch = node("offense.swiftness.light_touch")
        let momentum = node("offense.force.momentum")
        let result = Rules.derive(input(nodes: [quick, lightFrame, lightTouch, momentum],
                                        gearInitiative: -9))
        XCTAssertEqual(result.unencumberedInitiative, 15)
        XCTAssertEqual(result.effectiveGearInitiativePenalty, 4)
        XCTAssertEqual(result.initiative, 11)
        XCTAssertEqual(result.momentumDamageBonus, 1)

        XCTAssertEqual(Rules.derive(input(nodes: [momentum], gearInitiative: -30)).momentumDamageBonus, 4)
        XCTAssertEqual(Rules.derive(input(nodes: [lightTouch], gearInitiative: 3)).initiative, 11,
                       "Light Touch must preserve positive equipment initiative")
    }

    func testPersonalDurabilityAndEvasionAreExplicit() {
        let thick = node("defense.fortitude.thick_hide")
        let iron = node("defense.fortitude.iron_skin")
        let bulwark = node("defense.protection.bulwark")
        let footwork = node("defense.evasion.footwork")
        let result = Rules.derive(input(nodes: [thick, iron, bulwark, footwork]))
        XCTAssertEqual(result.maximumHP, 26)
        XCTAssertEqual(result.armour, 8)
        XCTAssertEqual(result.evasionBonus, 0.06)
    }

    func testFormationBonusesAreStrongestOnceConsciousAndRankScoped() {
        let bulwark = node("defense.protection.bulwark")
        let shieldwall = node("defense.protection.shieldwall")
        let members: [Rules.FormationMember] = [
            .init(identity: "a", rank: .front, isConscious: true, ownedNodeIDs: [bulwark]),
            .init(identity: "b", rank: .front, isConscious: true, ownedNodeIDs: [bulwark, shieldwall]),
            .init(identity: "c", rank: .front, isConscious: false, ownedNodeIDs: [shieldwall]),
            .init(identity: "d", rank: .back, isConscious: true, ownedNodeIDs: [bulwark])
        ]
        XCTAssertEqual(Rules.derive(input(formation: members)).armour, 9) // base 5 +2 +2
        XCTAssertEqual(Rules.derive(input(rank: .back, formation: members)).armour, 7) // same-rank d only

        let reordered = [members[3], members[1], members[0], members[2]]
        XCTAssertEqual(Rules.derive(input(formation: members)),
                       Rules.derive(input(formation: reordered)))
        XCTAssertEqual(Rules.derive(input(nodes: [shieldwall])).armour, 7,
                       "a conscious front-rank owner benefits without requiring itself in formation")
    }

    func testEmanationChoiceAttunementAndImmovableAreTyped() {
        let insulation = node("craft.emanation.insulation")
        let attunement = node("craft.emanation.attunement")
        let immovable = node("defense.fortitude.immovable")
        let result = Rules.derive(input(nodes: [insulation, attunement, immovable],
                                        choices: [insulation: "caustic"]))
        XCTAssertEqual(result.insulationChoice, .caustic)
        XCTAssertEqual(result.matchingEmanationReduction, 0.35)
        XCTAssertEqual(result.attunementDamageBonus, 3)
        XCTAssertTrue(result.armourAppliesToAllHarms)
        XCTAssertEqual(result.contributorsByField["emanationResistance"], [insulation])

        let missingChoice = Rules.derive(input(nodes: [insulation]))
        XCTAssertNil(missingChoice.insulationChoice)
        XCTAssertEqual(missingChoice.matchingEmanationReduction, 0)
    }

    func testIdenticalFrozenInputProducesIdenticalDormantDerivation() {
        let frozen = input(nodes: [node("offense.swiftness.quick_step"),
                                   node("defense.fortitude.thick_hide")],
                           gearInitiative: -2)
        XCTAssertEqual(Rules.derive(frozen), Rules.derive(frozen))
    }
}
