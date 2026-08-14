import Foundation

/// Pure, dormant foundation for the first combat-v2 consumer slice.
///
/// Nothing in production combat calls this yet. Preview, encounter creation and committed combat
/// must be moved to this path together; activating only one consumer would create split arithmetic.
enum CombatDerivedStatsRules {
    struct AttackBonusComponent: Codable, Equatable, Sendable {
        var nodeID: CombatNodeID
        var amount: Int
    }

    /// Additions made before matchup, rank and armour. This is deliberately not called `attack`:
    /// weapon/base power remains owned by combat, and callers add this total exactly once.
    struct PreMatchupAttackBonus: Codable, Equatable, Sendable {
        var components: [AttackBonusComponent]
        var total: Int { components.reduce(0) { $0 + $1.amount } }
    }

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

    struct ArmourComponent: Codable, Equatable, Sendable {
        var nodeID: CombatNodeID
        var source: Combatant
        var amount: Double
    }

    struct ArmourBreakdown: Codable, Equatable, Sendable {
        var receiver: Combatant
        var equipment: Double
        var components: [ArmourComponent]
        var totalBeforeIgnore: Double
        var armourIgnored: Double
        var effectiveArmour: Int
    }

    struct IncomingDamageResult: Codable, Equatable, Sendable {
        var raw: Int
        var rank: Rank
        var breakdown: ArmourBreakdown
        var finalDamage: Int
    }

    struct FoeArmourComponent: Codable, Equatable, Sendable {
        var nodeID: CombatNodeID
        var amount: Int
    }
    struct FoeArmourBreakdown: Codable, Equatable, Sendable {
        var base: Int
        var components: [FoeArmourComponent]
        var beforeIgnore: Int
        var ignoredFraction: Double
        var effective: Int
    }

    static func foeArmour(base: Int, erosion: Int,
                          ignoredFraction: Double = 0) -> FoeArmourBreakdown {
        let safeBase = max(0, base)
        let appliedErosion = min(safeBase, max(0, erosion))
        let beforeIgnore = safeBase - appliedErosion
        let ignored = min(1, max(0, ignoredFraction))
        let components = appliedErosion > 0
            ? [FoeArmourComponent(nodeID: Node.corrode, amount: -appliedErosion)] : []
        return .init(base: safeBase, components: components, beforeIgnore: beforeIgnore,
                     ignoredFraction: ignored,
                     effective: Int((Double(beforeIgnore) * (1 - ignored)).rounded()))
    }

    struct ResistanceComponent: Codable, Equatable, Sendable {
        enum Source: String, Codable, Equatable, Sendable { case wornInsulation, ward, insulation }
        var source: Source
        var nodeID: CombatNodeID?
        var multiplier: Double
    }

    struct EmanationDamageResult: Codable, Equatable, Sendable {
        var receiver: Combatant
        var element: EmanationKind
        var raw: Double
        var components: [ResistanceComponent]
        var combinedMultiplier: Double
        var roundedDamage: Int
        var finalDamage: Int
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
        var preMatchupAttackBonus: PreMatchupAttackBonus
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

    enum Node {
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
        static let feint: CombatNodeID = "combat.defense.evasion.feint"
        static let untouchable: CombatNodeID = "combat.defense.evasion.untouchable"
        static let ghost: CombatNodeID = "combat.defense.evasion.ghost"
        static let lightFrame: CombatNodeID = "combat.defense.evasion.light_frame"
        static let insulation: CombatNodeID = "combat.craft.emanation.insulation"
        static let attunement: CombatNodeID = "combat.craft.emanation.attunement"
        static let stagger: CombatNodeID = "combat.offense.force.stagger"
        /// Producer identity only. Breaking Blow is not activated by the Stagger checkpoint.
        static let breakingBlow: CombatNodeID = "combat.offense.force.breaking_blow"
        static let followThrough: CombatNodeID = "combat.offense.force.follow_through"
        static let bracingStance: CombatNodeID = "combat.offense.force.bracing_stance"
        static let weakPoint: CombatNodeID = "combat.offense.precision.weak_point"
        static let exploit: CombatNodeID = "combat.offense.precision.exploit"
        static let steadyHand: CombatNodeID = "combat.offense.precision.steady_hand"
        static let flense: CombatNodeID = "combat.craft.venom.flense"
        static let virulence: CombatNodeID = "combat.craft.venom.virulence"
        static let corrode: CombatNodeID = "combat.craft.venom.corrode"
        static let blight: CombatNodeID = "combat.craft.venom.blight"
        static let constitution: CombatNodeID = "combat.defense.fortitude.constitution"
        static let endurance: CombatNodeID = "combat.defense.fortitude.endurance"
        static let unyielding: CombatNodeID = "combat.defense.fortitude.unyielding"
        static let brace: CombatNodeID = "combat.defense.fortitude.brace"
        static let ward: CombatNodeID = "combat.defense.fortitude.ward"
        static let snuff: CombatNodeID = "combat.craft.emanation.snuff"
    }

    static func constitutionTicks(authored: Int, endless: Bool, ownsNode: Bool) -> Int {
        guard ownsNode, !endless else { return authored }
        return max(1, (max(0, authored) + 1) / 2)
    }

    static func enduranceDamage(_ value: Int, currentHP: Int, maximumHP: Int,
                                eventMinimum: Int, ownsNode: Bool) -> Int {
        guard value > 0, ownsNode, currentHP > 0,
              currentHP * 2 <= max(1, maximumHP) else { return value }
        return max(eventMinimum, Int((Double(value) * 0.75).rounded(.down)))
    }

    static func survivalDamage(_ value: Int, currentHP: Int, maximumHP: Int,
                               eventMinimum: Int, ownsEndurance: Bool,
                               braceApplies: Bool) -> Int {
        guard value > 0 else { return value }
        let enduranceApplies = ownsEndurance && currentHP > 0
            && currentHP * 2 <= max(1, maximumHP)
        var multiplier = 1.0
        if enduranceApplies { multiplier *= 0.75 }
        if braceApplies { multiplier *= 0.65 }
        guard multiplier < 1 else { return value }
        return max(eventMinimum, Int((Double(value) * multiplier).rounded(.down)))
    }

    struct DirectHitSnapshot: Equatable, Sendable {
        var targetArmour: Int
        var coveringDensity: Double?
        var actorHeldRank: Bool
        var targetHasAffliction: Bool
    }

    static func conditionalDirectHitComponents(
        ownedNodeIDs: Set<CombatNodeID>, snapshot: DirectHitSnapshot
    ) -> [EncounterState.DirectHitComponent] {
        var result: [EncounterState.DirectHitComponent] = []
        if ownedNodeIDs.contains(Node.followThrough), snapshot.targetArmour >= 8 {
            result.append(.init(nodeID: Node.followThrough, amount: 3))
        }
        if ownedNodeIDs.contains(Node.bracingStance), snapshot.actorHeldRank {
            result.append(.init(nodeID: Node.bracingStance, amount: 3))
        }
        if ownedNodeIDs.contains(Node.weakPoint), (snapshot.coveringDensity ?? -Double.infinity) >= 50 {
            result.append(.init(nodeID: Node.weakPoint, amount: 3))
        }
        if ownedNodeIDs.contains(Node.exploit), snapshot.targetHasAffliction {
            result.append(.init(nodeID: Node.exploit, amount: 4))
        }
        return result.sorted { $0.nodeID.rawValue < $1.nodeID.rawValue }
    }

    static func preMatchupAttackBonus(ownedNodeIDs: Set<CombatNodeID>,
                                      weaponDamageKind: DamageKind?,
                                      momentum: Int = 0) -> PreMatchupAttackBonus {
        var components: [AttackBonusComponent] = []
        if ownedNodeIDs.contains(Node.heavyHand), weaponDamageKind == .crush {
            components.append(.init(nodeID: Node.heavyHand, amount: 2))
        }
        if ownedNodeIDs.contains(Node.keenEye), weaponDamageKind == .pierce {
            components.append(.init(nodeID: Node.keenEye, amount: 2))
        }
        if momentum > 0, ownedNodeIDs.contains(Node.momentum) {
            components.append(.init(nodeID: Node.momentum, amount: momentum))
        }
        return .init(components: components.sorted { $0.nodeID.rawValue < $1.nodeID.rawValue })
    }

    /// Sole DEBUG-route factory used at real encounter entry. Unsupported IDs are ignored; an
    /// enabled empty selection deliberately returns a zero-component v2 receipt rather than nil.
    static func debugBinderAttackReceipt(enabled: Bool, selectedNodeIDs: Set<CombatNodeID>,
                                         ordinaryWeaponKind: DamageKind?)
        -> EncounterState.DebugV2BinderAttackReceipt? {
        guard enabled else { return nil }
        let supported = selectedNodeIDs.intersection([Node.heavyHand, Node.keenEye])
        return .init(
            ordinaryWeaponKind: ordinaryWeaponKind,
            crushBonus: preMatchupAttackBonus(ownedNodeIDs: supported, weaponDamageKind: .crush),
            pierceBonus: preMatchupAttackBonus(ownedNodeIDs: supported, weaponDamageKind: .pierce))
    }

    /// Pure DEBUG-route initiative snapshot. Only actors actually entering the encounter receive
    /// entries, so an absent/unconscious party member cannot lend an aura to somebody else.
    static func debugInitiativeReceipt(enabled: Bool, party: [Combatant], foes: [FoeState],
                                       binderNodeIDs: Set<CombatNodeID>,
                                       companionNodeIDs: [Int: Set<CombatNodeID>])
        -> EncounterState.DebugV2InitiativeReceipt? {
        guard enabled else { return nil }
        let supported: Set<CombatNodeID> = [Node.quickStep, Node.lightFrame]
        var entries = party.map { actor -> EncounterState.DebugV2InitiativeReceipt.Entry in
            let owned: Set<CombatNodeID>
            switch actor {
            case .binder: owned = binderNodeIDs.intersection(supported)
            case .companion(let index):
                owned = (companionNodeIDs[index] ?? []).intersection(supported)
            case .foe: owned = []
            }
            var components: [EncounterState.DebugV2InitiativeReceipt.Component] = []
            if owned.contains(Node.quickStep) { components.append(.init(nodeID: Node.quickStep, amount: 4)) }
            if owned.contains(Node.lightFrame) { components.append(.init(nodeID: Node.lightFrame, amount: 3)) }
            components.sort { $0.nodeID.rawValue < $1.nodeID.rawValue }
            let baseline = actor == .binder ? Tuning.Encounter.binderInitiative
                                            : Tuning.Encounter.companionInitiative
            return .init(actor: actor, baseline: baseline, components: components,
                         total: baseline + components.reduce(0) { $0 + $1.amount },
                         strikesFirst: false, finalPosition: nil)
        }
        entries += foes.map { foe in
            let slow = foe.stats.damageKind == .crush ? Tuning.Encounter.crushInitiativePenalty : 0
            let baseline = foe.stats.initiative - slow
            return .init(actor: .foe(foe.id), baseline: baseline, components: [], total: baseline,
                         strikesFirst: foe.stats.strikesFirst, finalPosition: nil)
        }
        return .init(entries: entries)
    }

    /// Frozen at contact so neither Base-stat edits nor DEBUG ownership changes can rewrite an
    /// active encounter's personal miss chance.
    static func debugEvasionReceipt(enabled: Bool, party: [Combatant], in state: GameState,
                                    binderNodeIDs: Set<CombatNodeID>,
                                    companionNodeIDs: [Int: Set<CombatNodeID>])
        -> EncounterState.DebugV2EvasionReceipt? {
        guard enabled else { return nil }
        let entries = party.compactMap { actor -> EncounterState.DebugV2EvasionReceipt.Entry? in
            guard let stats = CombatRules.stats(of: actor, in: state) else { return nil }
            let owned: Set<CombatNodeID> = switch actor {
            case .binder: binderNodeIDs
            case .companion(let index): companionNodeIDs[index] ?? []
            case .foe: []
            }
            let components: [EncounterState.DebugV2EvasionReceipt.Component] =
                owned.contains(Node.footwork) ? [.init(nodeID: Node.footwork, amount: 0.06)] : []
            return .init(actor: actor, characterEvasion: CharacterRules.evasion(stats),
                         components: components,
                         ownsFeint: owned.contains(Node.feint),
                         ownsUntouchable: owned.contains(Node.untouchable))
        }
        return .init(entries: entries)
    }

    static func debugResistanceReceipt(
        enabled: Bool, party: [Combatant],
        binderNodeIDs: Set<CombatNodeID>,
        binderChoices: [CombatNodeID: StableChoiceID],
        companionNodeIDs: [Int: Set<CombatNodeID>],
        companionChoices: [Int: [CombatNodeID: StableChoiceID]]
    ) -> EncounterState.DebugV2ResistanceReceipt? {
        guard enabled else { return nil }
        let entries = party.map { actor -> EncounterState.DebugV2ResistanceReceipt.Entry in
            let owned: Set<CombatNodeID>
            let choices: [CombatNodeID: StableChoiceID]
            switch actor {
            case .binder:
                owned = binderNodeIDs
                choices = binderChoices
            case .companion(let index):
                owned = companionNodeIDs[index] ?? []
                choices = companionChoices[index] ?? [:]
            case .foe:
                owned = []
                choices = [:]
            }
            let choice = owned.contains(Node.insulation)
                ? choices[Node.insulation].flatMap { EmanationKind(rawValue: $0.rawValue) }
                : nil
            return .init(actor: actor, insulationChoice: choice)
        }
        return .init(entries: entries)
    }

    /// One rounding point for continuous emanation multipliers. Afflictions never call this path.
    static func emanationDamage(
        raw: Double, element: EmanationKind, receiver: Combatant,
        receipt: EncounterState.DebugV2ResistanceReceipt,
        wornInsulationMultiplier: Double = 1,
        wardMultiplier: Double = 1,
        minimumDamage: Int = Tuning.Encounter.minimumDamage
    ) -> EmanationDamageResult {
        var components: [ResistanceComponent] = []
        if wornInsulationMultiplier < 1 {
            components.append(.init(source: .wornInsulation, nodeID: nil,
                                    multiplier: max(0, wornInsulationMultiplier)))
        }
        if wardMultiplier < 1 {
            components.append(.init(source: .ward, nodeID: nil,
                                    multiplier: max(0, wardMultiplier)))
        }
        let matchingInsulation = receipt.entry(for: receiver)?.insulationChoice == element
        if matchingInsulation {
            components.append(.init(source: .insulation, nodeID: Node.insulation, multiplier: 0.65))
        }
        let combined = components.reduce(1.0) { $0 * $1.multiplier }
        let reduced = max(0, raw) * combined
        // An enabled-empty v2 harness must be byte/outcome-equivalent to legacy. The new
        // floor-once contract begins only when matching Insulation is a real contributor.
        let rounded = matchingInsulation ? Int(floor(reduced)) : Int(reduced.rounded())
        return .init(receiver: receiver, element: element, raw: raw, components: components,
                     combinedMultiplier: combined, roundedDamage: rounded,
                     finalDamage: max(minimumDamage, rounded))
    }

    static func incomingDamage(raw: Int, receiver: Combatant,
                               receipt: EncounterState.DebugV2ArmourReceipt,
                               ranks: [Combatant: Rank], conscious: Set<Combatant>,
                               armourIgnored: Double) -> IncomingDamageResult {
        incomingDamage(raw: raw, receiver: receiver, receipt: receipt, ranks: ranks,
                       conscious: conscious, armourIgnored: armourIgnored,
                       appliesBackRankProtection: true)
    }

    /// Shared armour authority for direct emanation when Immovable expands armour's scope.
    /// Formation still reads current encounter ranks, but emanation never gains the physical
    /// back-rank raw-damage reduction.
    static func emanationArmourDamage(raw: Int, receiver: Combatant,
                                      receipt: EncounterState.DebugV2ArmourReceipt,
                                      ranks: [Combatant: Rank], conscious: Set<Combatant>)
        -> IncomingDamageResult {
        incomingDamage(raw: raw, receiver: receiver, receipt: receipt, ranks: ranks,
                       conscious: conscious, armourIgnored: 0,
                       appliesBackRankProtection: false)
    }

    private static func incomingDamage(raw: Int, receiver: Combatant,
                                       receipt: EncounterState.DebugV2ArmourReceipt,
                                       ranks: [Combatant: Rank], conscious: Set<Combatant>,
                                       armourIgnored: Double,
                                       appliesBackRankProtection: Bool) -> IncomingDamageResult {
        let receiverEntry = receipt.entry(for: receiver) ?? .init(
            actor: receiver, equipmentProtectivePower: 0, sturdiness: 1,
            ownedNodeIDs: [], entryRank: .front)
        func rank(of entry: EncounterState.DebugV2ArmourReceipt.Entry) -> Rank {
            ranks[entry.actor] ?? entry.entryRank
        }
        let receiverRank = rank(of: receiverEntry)
        var components: [ArmourComponent] = []
        func add(_ node: CombatNodeID, source: Combatant, amount: Double) {
            components.append(.init(nodeID: node, source: source, amount: amount))
        }
        if receiverEntry.ownedNodeIDs.contains(Node.ironSkin) {
            add(Node.ironSkin, source: receiver, amount: 2)
        }
        if conscious.contains(receiver), receiverEntry.ownedNodeIDs.contains(Node.bulwark) {
            add(Node.bulwark, source: receiver, amount: 1)
        }
        if let ally = receipt.entries
            .filter({ $0.actor != receiver && conscious.contains($0.actor)
                && rank(of: $0) == receiverRank && $0.ownedNodeIDs.contains(Node.bulwark) })
            .sorted(by: { $0.actor.storageKey < $1.actor.storageKey }).first {
            add(Node.bulwark, source: ally.actor, amount: 2)
        }
        if receiverRank == .front,
           let owner = receipt.entries
            .filter({ conscious.contains($0.actor) && rank(of: $0) == .front
                && $0.ownedNodeIDs.contains(Node.shieldwall) })
            .sorted(by: { $0.actor.storageKey < $1.actor.storageKey }).first {
            add(Node.shieldwall, source: owner.actor, amount: 2)
        }
        components.sort {
            if $0.nodeID != $1.nodeID { return $0.nodeID.rawValue < $1.nodeID.rawValue }
            return $0.source.storageKey < $1.source.storageKey
        }
        let equipment = receiverEntry.equipmentProtectivePower
            * Double(Tuning.Encounter.defencePerArmorTier) * receiverEntry.sturdiness
        let total = equipment + components.reduce(0) { $0 + $1.amount }
        let ignored = min(1, max(0, armourIgnored))
        let effective = Int((total * (1 - ignored)).rounded())
        var incoming = Double(raw)
        if appliesBackRankProtection, receiverRank == .back {
            incoming *= 1 - Tuning.Encounter.backRankProtection
        }
        let final = max(Tuning.Encounter.minimumDamage, Int(incoming.rounded()) - effective)
        return .init(raw: raw, rank: receiverRank,
                     breakdown: .init(receiver: receiver, equipment: equipment,
                                      components: components, totalBeforeIgnore: total,
                                      armourIgnored: ignored, effectiveArmour: effective),
                     finalDamage: final)
    }

    static func derive(_ input: Input) -> Output {
        let owned = input.ownedNodeIDs
        var provenance: [String: Set<CombatNodeID>] = [:]
        func note(_ field: String, _ node: CombatNodeID) {
            provenance[field, default: []].insert(node)
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
        let attackBonus = preMatchupAttackBonus(ownedNodeIDs: owned,
                                                weaponDamageKind: input.weaponDamageKind,
                                                momentum: momentum)
        for component in attackBonus.components { note("preMatchupAttackBonus", component.nodeID) }

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
            preMatchupAttackBonus: attackBonus,
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
