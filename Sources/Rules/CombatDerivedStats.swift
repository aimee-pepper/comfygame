import Foundation

/// Pure, dormant foundation for the first combat-v2 consumer slice.
///
/// Nothing in production combat calls this yet. Preview, encounter creation and committed combat
/// must be moved to this path together; activating only one consumer would create split arithmetic.
enum CombatDerivedStatsRules {
    /// Compatibility adapter only. It does not persist ownership and does not activate v2.
    static func legacyOwnedNodes(for character: CharacterState,
                                 catalogue: CombatGraphCatalogue) -> Set<CombatNodeID> {
        CombatGraphRules.migratedLegacyNodes(branchDepth: character.branchDepth,
                                             catalogue: catalogue)
    }

    struct FormationMember: Equatable, Sendable {
        var identity: String
        var rank: Rank
        var isConscious: Bool
        var ownedNodeIDs: Set<CombatNodeID>
    }

    struct Input: Equatable, Sendable {
        var actorIdentity: String
        var stats: CharacterStats
        var rank: Rank
        var isConscious: Bool
        var baseAttack: Int
        var baseMaximumHP: Int
        var baseInitiative: Int
        var weaponDamageKind: DamageKind?
        /// The exact equipment contribution. Positive initiative is preserved; Light Touch halves
        /// only a negative value.
        var gearInitiativeModifier: Int
        /// Equipment armour after ordinary gear/sturdiness calculation.
        var equipmentArmour: Int
        var ownedNodeIDs: Set<CombatNodeID>
        var choices: [CombatNodeID: StableChoiceID]
        var formation: [FormationMember]
    }

    struct Output: Equatable, Sendable {
        var attack: Int
        var matchingPhysicalDamageBonus: Int
        var momentumDamageBonus: Int
        var maximumHP: Int
        var initiative: Int
        var unencumberedInitiative: Int
        var effectiveGearInitiativePenalty: Int
        var armour: Int
        var evasionBonus: Double
        var insulationChoice: EmanationKind?
        var matchingEmanationReduction: Double
        var attunementDamageBonus: Int
        var armourAppliesToAllHarms: Bool
        /// Stable-node provenance for DEBUG comparison; sorted for deterministic output.
        var contributorsByField: [String: [CombatNodeID]]
    }

    private enum Node {
        static let heavyHand: CombatNodeID = "combat.offense.force.heavy_hand"
        static let momentum: CombatNodeID = "combat.offense.force.momentum"
        static let keenEye: CombatNodeID = "combat.offense.precision.keen_eye"
        static let quickStep: CombatNodeID = "combat.offense.swiftness.quick_step"
        static let lightTouch: CombatNodeID = "combat.offense.swiftness.light_touch"
        static let thickHide: CombatNodeID = "combat.defense.fortitude.thick_hide"
        static let ironSkin: CombatNodeID = "combat.defense.fortitude.iron_skin"
        static let immovable: CombatNodeID = "combat.defense.fortitude.immovable"
        static let bulwark: CombatNodeID = "combat.defense.protection.bulwark"
        static let shieldwall: CombatNodeID = "combat.defense.protection.shieldwall"
        static let footwork: CombatNodeID = "combat.defense.evasion.footwork"
        static let lightFrame: CombatNodeID = "combat.defense.evasion.light_frame"
        static let insulation: CombatNodeID = "combat.craft.emanation.insulation"
        static let attunement: CombatNodeID = "combat.craft.emanation.attunement"
    }

    static func derive(_ input: Input) -> Output {
        let owned = input.ownedNodeIDs
        var provenance: [String: Set<CombatNodeID>] = [:]
        func note(_ field: String, _ node: CombatNodeID) {
            provenance[field, default: []].insert(node)
        }

        var physical = 0
        if owned.contains(Node.heavyHand), input.weaponDamageKind == .crush {
            physical += 2; note("attack", Node.heavyHand)
        }
        if owned.contains(Node.keenEye), input.weaponDamageKind == .pierce {
            physical += 2; note("attack", Node.keenEye)
        }

        var initiativeNodes = 0
        if owned.contains(Node.quickStep) { initiativeNodes += 4; note("initiative", Node.quickStep) }
        if owned.contains(Node.lightFrame) { initiativeNodes += 3; note("initiative", Node.lightFrame) }
        let unencumbered = input.baseInitiative + initiativeNodes
        var gearModifier = input.gearInitiativeModifier
        if owned.contains(Node.lightTouch), gearModifier < 0 {
            gearModifier /= 2 // Swift integer division rounds toward zero.
            note("initiative", Node.lightTouch)
        }
        let penalty = max(0, -gearModifier)
        var momentum = 0
        if owned.contains(Node.momentum), penalty > 0 {
            momentum = min(4, Int(floor(Double(penalty) * 0.4)))
            if momentum > 0 { note("attack", Node.momentum) }
        }

        var hp = input.baseMaximumHP
        if owned.contains(Node.thickHide) { hp += 6; note("maximumHP", Node.thickHide) }

        var armour = input.equipmentArmour
        if owned.contains(Node.ironSkin) { armour += 2; note("armour", Node.ironSkin) }
        if owned.contains(Node.bulwark), input.isConscious {
            armour += 1; note("armour", Node.bulwark)
        }
        let consciousOthers = input.formation.filter {
            $0.identity != input.actorIdentity && $0.isConscious && $0.rank == input.rank
        }
        if consciousOthers.contains(where: { $0.ownedNodeIDs.contains(Node.bulwark) }) {
            armour += 2; note("armour", Node.bulwark)
        }
        let actorProvidesShieldwall = input.isConscious && input.rank == .front
            && owned.contains(Node.shieldwall)
        let allyProvidesShieldwall = input.formation.contains(where: {
               $0.isConscious && $0.rank == .front && $0.ownedNodeIDs.contains(Node.shieldwall)
           })
        if input.rank == .front, actorProvidesShieldwall || allyProvidesShieldwall {
            armour += 2; note("armour", Node.shieldwall)
        }

        let evasion = owned.contains(Node.footwork) ? 0.06 : 0
        if evasion > 0 { note("evasion", Node.footwork) }

        let insulation: EmanationKind? = if owned.contains(Node.insulation),
           let raw = input.choices[Node.insulation]?.rawValue {
            EmanationKind(rawValue: raw)
        } else { nil }
        if insulation != nil { note("emanationResistance", Node.insulation) }

        let attunement = owned.contains(Node.attunement) ? 3 : 0
        if attunement > 0 { note("emanationAttack", Node.attunement) }
        let universalArmour = owned.contains(Node.immovable)
        if universalArmour { note("armourScope", Node.immovable) }

        return Output(
            attack: input.baseAttack + physical + momentum,
            matchingPhysicalDamageBonus: physical,
            momentumDamageBonus: momentum,
            maximumHP: hp,
            initiative: unencumbered + gearModifier,
            unencumberedInitiative: unencumbered,
            effectiveGearInitiativePenalty: penalty,
            armour: armour,
            evasionBonus: evasion,
            insulationChoice: insulation,
            matchingEmanationReduction: insulation == nil ? 0 : 0.35,
            attunementDamageBonus: attunement,
            armourAppliesToAllHarms: universalArmour,
            contributorsByField: provenance.mapValues { $0.sorted { $0.rawValue < $1.rawValue } }
        )
    }
}
