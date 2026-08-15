import Foundation

/// **A class is where you spent.**
///
/// Nine branches shared by everybody, three trees of three, eight nodes deep
/// (`docs/combat-trees-full.md`). Nobody is assigned a class: a rogue is Swiftness, Evasion and
/// Shadow; a knight is Force, Fortitude and Emanation. Neither was authored — both fall out of the
/// same nine branches, and there are twenty-seven such combinations.
///
/// **Max level falls out of the shape** (Aimee): *"they need to reach the end of each tree on any
/// one branch per tree."* Three complete branches is 24 points, one point a level, so the cap is
/// level 25 — and a finished companion has three branches at full depth and six they never touched,
/// which is why builds stay distinct forever with no convergence point.
enum CombatTreeRules {

    // MARK: What you have to spend

    /// Points earned. One a level, and the first level is free rather than paid.
    static func totalPoints(atLevel level: Int) -> Int {
        max(0, min(level, Tuning.Character.maximumLevel) - 1) * Tuning.Character.treePointsPerLevel
    }

    static func spentPoints(_ character: CharacterState) -> Int {
        character.ownedCombatNodeIDs?.count ?? character.branchDepth.values.reduce(0, +)
    }

    static func unspentPoints(_ character: CharacterState) -> Int {
        max(0, totalPoints(atLevel: character.level) + character.freePoints - spentPoints(character))
    }

    // MARK: Spending

    /// How far into a branch somebody has bought.
    static func depth(of branch: CombatBranchID, in character: CharacterState) -> Int {
        character.branchDepth[branch] ?? 0
    }

    /// The next node in a branch, or nil at the capstone.
    static func nextNode(in branch: CombatBranchDef, for character: CharacterState) -> CombatNodeDef? {
        let bought = depth(of: branch.id, in: character)
        return bought < branch.nodes.count ? branch.nodes[bought] : nil
    }

    /// **Bought in order, one point each.** Depth comes from nodes getting stronger rather than
    /// costlier — easier to reason about on a phone, and it keeps the decision "which three" rather
    /// than "can I afford the next one".
    static func canBuyNext(in branch: CombatBranchDef, for character: CharacterState) -> Bool {
        nextNode(in: branch, for: character) != nil && unspentPoints(character) > 0
    }

    @discardableResult
    static func buyNext(in branch: CombatBranchDef, for character: inout CharacterState) -> CombatNodeDef? {
        guard canBuyNext(in: branch, for: character),
              let node = nextNode(in: branch, for: character) else { return nil }
        character.branchDepth[branch.id, default: 0] += 1
        return node
    }

    /// **Unspending.** Aimee, 7 Aug: *"people should be able to be respec'd at the spring in town."*
    ///
    /// All of it at once rather than node by node: the decision the trees exist to make is *which
    /// three branches*, and refunding one point at a time would turn that into a fiddle. It costs
    /// essence, so changing your mind is a real cost and not a free retry — but it is always
    /// available, because a misspent point before anybody knows what a branch does is a harsh thing
    /// to make permanent.
    static func respecCost(for character: CharacterState) -> Int {
        let spent = spentPoints(character)
        guard spent > 0 else { return 0 }
        return Tuning.Character.respecBaseCost + spent * Tuning.Character.respecCostPerPoint
    }

    static func forget(_ character: inout CharacterState) {
        character.branchDepth = [:]
        character.ownedCombatNodeIDs = []
        character.combatNodeChoices = [:]
    }

    /// **Partial investment is legal.** The cap is on total points, so spreading across nine
    /// branches gives you nine shallow ones rather than three deep — a worse choice, never an
    /// illegal one. The commitment is the interesting part.
    static func completedBranches(_ character: CharacterState) -> [CombatBranchDef] {
        ContentCatalog.shared.combatBranches.filter {
            depth(of: $0.id, in: character) >= $0.nodes.count
        }
    }

    /// What the player would call this build. Emergent — nothing here is authored per companion.
    static func className(for character: CharacterState) -> String? {
        let finished = Set(completedBranches(character).map(\.id.rawValue))
        guard finished.count >= 3 else { return nil }
        for (name, branches) in Tuning.Character.emergentClasses where branches.isSubset(of: finished) {
            return name
        }
        return "Adept"
    }

    // MARK: What it all adds up to

    /// Every node somebody has actually bought.
    static func boughtNodes(_ character: CharacterState) -> [CombatNodeDef] {
        ContentCatalog.shared.combatBranches.flatMap { branch in
            branch.nodes.prefix(depth(of: branch.id, in: character))
        }
    }

    /// **The one place a spent point becomes a number the fight reads.**
    ///
    /// Assembled rather than scattered so that adding a node is a JSON edit and adding an *effect
    /// kind* is one case here — and so `CombatTreeTests` can assert every kind in the catalogue is
    /// read, which is the Constellation fossil guard applied to seventy-two nodes.
    struct Loadout: Equatable, Sendable {
        var damageByKind: [DamageKind: Int] = [:]
        var damageVersusArmour: (above: Double, amount: Int) = (0, 0)
        var damageVersusCovering: (above: Double, amount: Int) = (0, 0)
        var damageVersusAfflicted = 0
        var damageIfHeldRank = 0
        var damagePerMissingInitiative = 0.0
        var damageFromConcealment = 0
        var staggerChance = 0.0
        var critChance = 0.0
        var splashFraction = 0.0
        var butcheryYield = 0.0
        var killingStrokeThreshold = 0.0

        var maxHP = 0
        var armour = 0
        var allyArmour = 0
        var frontRankArmour = 0
        var evasion = 0.0
        var evasionAfterAttacking = 0.0
        var evasionPerCleanRound = 0.0
        var initiative = 0
        var initiativeOnKill = 0
        var gearInitiativeRelief = 0.0
        var healOnKill = 0
        var partyHealOnKill = 0
        var statusResistance = 0.0
        var statusDuration = 0
        var damageReductionWhenHurt = 0.0
        var shareBackRankDamage = 0.0
        var ambushResistance = 0.0
        var partyAmbushResistance = 0.0

        var poisonOnHit = 0
        var burnOnHit = 0
        var poisonReducesArmour = 0
        var elementalDamage = 0
        var elementalChain = 0.0
        var elementResistance = 0.0
        var consumablePotency = 0.0
        var coatingCostRelief = 0.0
        var encounterChance = 0.0
        var sightedAtRange = 0
        var partySightedAtRange = 0

        var survivesOnce = false
        var freeFlee = false
        var breaksArmourOutright = false
        var armourAppliesToEverything = false
        var doubleTurnOnce = false
        var firstAttackAlwaysMisses = false
        var guardsTheBackRank = false
        var poisonSpreads = false
        var beginsConcealed = false
        var carriesAnEmanation = false

        var skills: Set<SkillID> = []

        /// **The equality the tests lean on** — a tuple pair isn't `Equatable` for free.
        static func == (a: Loadout, b: Loadout) -> Bool {
            a.damageByKind == b.damageByKind
                && a.damageVersusArmour == b.damageVersusArmour
                && a.damageVersusCovering == b.damageVersusCovering
                && a.skills == b.skills && a.maxHP == b.maxHP && a.armour == b.armour
        }
    }

    static func loadout(for character: CharacterState) -> Loadout {
        var out = Loadout()
        for node in boughtNodes(character) {
            if let skill = node.grantsSkill { out.skills.insert(skill) }
            apply(node.effect, to: &out)
        }
        return out
    }

    /// Every kind in `CombatNodeEffect.Kind` must appear here. `CombatTreeTests` asserts it by
    /// buying each node in isolation and requiring the loadout to differ from an empty one — so a
    /// node that reads well and does nothing fails the build rather than the playtest.
    private static func apply(_ effect: CombatNodeEffect, to out: inout Loadout) {
        let amount = Int(effect.amount.rounded())
        switch effect.kind {
        case .skill: break   // the node's whole effect is what it teaches

        case .damageOfKind:
            if let kind = effect.damageKind { out.damageByKind[kind, default: 0] += amount }
        case .damageVersusArmour:
            out.damageVersusArmour = (effect.above, out.damageVersusArmour.amount + amount)
        case .damageVersusCovering:
            out.damageVersusCovering = (effect.above, out.damageVersusCovering.amount + amount)
        case .damageVersusAfflicted: out.damageVersusAfflicted += amount
        case .damageIfHeldRank: out.damageIfHeldRank += amount
        case .damagePerMissingInitiative: out.damagePerMissingInitiative += effect.amount
        case .damageFromConcealment: out.damageFromConcealment += amount
        case .staggerChance: out.staggerChance += effect.chance
        case .critChance: out.critChance += effect.chance
        case .splashDamage: out.splashFraction += effect.fraction
        case .butcheryYield: out.butcheryYield += effect.amount
        case .capstoneKillingStroke: out.killingStrokeThreshold = effect.threshold

        case .maxHP: out.maxHP += amount
        case .armour: out.armour += amount
        case .allyArmour: out.allyArmour += amount
        case .frontRankArmour: out.frontRankArmour += amount
        case .evasion: out.evasion += effect.amount
        case .evasionAfterAttacking: out.evasionAfterAttacking += effect.amount
        case .evasionPerCleanRound: out.evasionPerCleanRound += effect.amount
        case .initiative: out.initiative += amount
        case .initiativeOnKill: out.initiativeOnKill += amount
        case .gearInitiativeRelief: out.gearInitiativeRelief += effect.amount
        case .healOnKill: out.healOnKill += amount
        case .partyHealOnKill: out.partyHealOnKill += amount
        case .statusResistance: out.statusResistance += effect.amount
        case .statusDuration: out.statusDuration += amount
        case .damageReductionWhenHurt: out.damageReductionWhenHurt += effect.amount
        case .shareBackRankDamage: out.shareBackRankDamage += effect.fraction
        case .ambushResistance: out.ambushResistance += effect.amount
        case .partyAmbushResistance: out.partyAmbushResistance += effect.amount

        case .poisonOnHit: out.poisonOnHit += amount
        case .burnOnHit: out.burnOnHit += amount
        case .poisonReducesArmour: out.poisonReducesArmour += amount
        case .elementalDamage: out.elementalDamage += amount
        case .elementalChain: out.elementalChain += effect.fraction
        case .elementResistance: out.elementResistance += effect.amount
        case .consumablePotency: out.consumablePotency += effect.amount
        case .coatingCostRelief: out.coatingCostRelief += effect.amount
        case .encounterChance: out.encounterChance += effect.amount
        case .sightedAtRange: out.sightedAtRange += amount
        case .partySightedAtRange: out.partySightedAtRange += amount

        case .surviveOnce: out.survivesOnce = true
        case .freeFlee: out.freeFlee = true
        case .capstoneBreakingBlow: out.breaksArmourOutright = true
        case .capstoneImmovable: out.armourAppliesToEverything = true
        case .capstoneBlur: out.doubleTurnOnce = true
        case .capstoneGhost: out.firstAttackAlwaysMisses = true
        case .capstoneGuardian: out.guardsTheBackRank = true
        case .capstoneBlight: out.poisonSpreads = true
        case .capstoneUnseen: out.beginsConcealed = true
        case .capstoneEmanant: out.carriesAnEmanation = true
        }
    }
}
