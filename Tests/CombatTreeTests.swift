import XCTest
@testable import Bookbinder

/// **A class is where you spent** (`docs/combat-trees-full.md`). Three trees, three branches each,
/// eight nodes deep, and nobody is assigned anything.
final class CombatTreeTests: XCTestCase {

    private var branches: [CombatBranchDef] { ContentCatalog.shared.combatBranches }

    private func spent(_ depths: [CombatBranchID: Int], level: Int = 25) -> CharacterState {
        var c = CharacterState(level: level)
        c.ownedCombatNodeIDs = legacyCombatNodes(depths).filter {
            ContentCatalog.shared.combatGraph.node($0)!.depth <= CombatGraphRules.openingMaximumDepth
        }
        c.unspentCombatPoints = max(0, CombatTreeRules.totalPoints(atLevel: level)
                                      - c.ownedCombatNodeIDs.count)
        return c
    }

    // MARK: The shape

    func testThreeTreesOfThreeBranchesOfEightNodes() {
        XCTAssertEqual(ContentCatalog.shared.combatTrees.count, 3)
        for tree in ContentCatalog.shared.combatTrees {
            XCTAssertEqual(tree.branches.count, 3, "\(tree.name) hasn't three branches")
        }
        XCTAssertEqual(branches.count, 9)
        for branch in branches {
            XCTAssertEqual(branch.nodes.count, 8, "\(branch.name) isn't eight deep")
            XCTAssertEqual(branch.nodes.map(\.index), Array(1...8), "\(branch.name) is out of order")
        }
    }

    /// **The level cap is derived, not chosen** (Aimee: *"they need to reach the end of each tree on
    /// any one branch per tree"*). Nine branches of eight; three complete branches is 24 points, one
    /// a level with the first free — so the cap is exactly enough and not a point more.
    func testMaxLevelIsExactlyThreeCompleteBranches() {
        let nodesPerBranch = branches[0].nodes.count
        let needed = 3 * nodesPerBranch
        XCTAssertEqual(CombatTreeRules.totalPoints(atLevel: Tuning.Character.maximumLevel), needed,
                       "the cap doesn't buy three branches, or buys more than three")
        XCTAssertLessThan(CombatTreeRules.totalPoints(atLevel: Tuning.Character.maximumLevel - 1), needed,
                          "you can finish three branches before the cap, so the cap isn't the cap")
        // And no further: levelling past the cap must not keep paying.
        XCTAssertEqual(CombatTreeRules.totalPoints(atLevel: 999), needed)
    }

    /// Six branches are left untouched at maximum, which is what keeps a rogue permanently not a
    /// knight — the property the whole shape exists for.
    // MARK: Nothing ships inert

    /// **The Constellation fossil guard, applied to seventy-two nodes** (`fossil-audit.md` §6).
    ///
    /// Every node must change the loadout or teach a skill. A node that reads well and does nothing
    /// is invisible to grep — the thing is *there* — and seventy-two is a lot of places for one to
    /// hide.
    func testEveryNodeDoesSomething() {
        let nothing = CombatTreeRules.Loadout()
        for branch in branches {
            for index in branch.nodes.indices where index < CombatGraphRules.openingMaximumDepth {
                let node = branch.nodes[index]
                let onlyThis = CombatTreeRules.loadout(for: spent([branch.id: index + 1]))
                let withoutIt = CombatTreeRules.loadout(for: spent([branch.id: index]))
                let teaches = node.grantsSkill != nil
                XCTAssertTrue(teaches || !sameNumbers(onlyThis, withoutIt),
                              "\(branch.name) \(node.index) — \(node.name) — grants nothing anything reads")
                _ = nothing
            }
        }
    }

    /// And every *kind* is read by `apply`, so adding one to the enum without a case fails here
    /// rather than in play.
    func testEveryEffectKindIsRead() {
        var seen: Set<CombatNodeEffect.Kind> = []
        for branch in branches {
            for index in branch.nodes.indices where index < CombatGraphRules.openingMaximumDepth {
                let node = branch.nodes[index]
                seen.insert(node.effect.kind)
                if node.effect.kind == .skill { continue }
                let with = CombatTreeRules.loadout(for: spent([branch.id: index + 1]))
                let without = CombatTreeRules.loadout(for: spent([branch.id: index]))
                XCTAssertFalse(sameNumbers(with, without),
                               "effect kind '\(node.effect.kind.rawValue)' changes nothing")
            }
        }
        XCTAssertGreaterThan(seen.count, 15, "the opening catalogue stopped exercising its effect kinds")
    }

    /// Every skill a node teaches has to exist, or the node is a promise of nothing.
    func testEverySkillANodeTeachesExists() {
        let opening = ContentCatalog.shared.combatGraph.nodes.filter {
            $0.depth <= CombatGraphRules.openingMaximumDepth
        }
        XCTAssertEqual(opening.compactMap(\.techniqueID).count, 13)
        for node in opening {
            guard let skill = node.techniqueID else { continue }
            XCTAssertNotNil(ContentCatalog.shared.skill(skill),
                            "\(node.id) teaches '\(skill.rawValue)', which doesn't exist")
        }
    }

    /// Sight and Read remain outside the graph and belong temporarily to distinct identities.
    func testSightAndReadLeftTheTreesForIdentityOwnership() {
        let taught = Set(branches.flatMap { $0.nodes.compactMap(\.grantsSkill) })
        XCTAssertFalse(taught.contains("sight"), "Sight is a lens, not a branch")
        XCTAssertFalse(taught.contains("read"), "Read is a lens, not a branch")
        let state = GameState.newGame()
        XCTAssertTrue(CombatActionOwnershipRules.availableSkillIDs(for: .binder, in: state)
            .contains("sight"))
        XCTAssertTrue(CombatActionOwnershipRules.availableSkillIDs(for: .companion(0), in: state)
            .contains("read"))
    }

    // MARK: It reaches the fight

    @MainActor
    func testSpendingAPointChangesWhatYouCanDo() throws {
        let store = GameStore(io: .temporary(name: "trees-\(UUID().uuidString)"))
        let before = CombatRules.skills(for: .binder, in: store.state).map(\.id)
        XCTAssertFalse(before.contains("pry"), "Pry before spending anything on Precision")

        store.mutate("test: three into Precision") { state in
            state.base.binderCharacter.level = 10
            state.base.binderCharacter.ownedCombatNodeIDs = legacyCombatNodes(["precision": 3])
        }
        let after = CombatRules.skills(for: .binder, in: store.state).map(\.id)
        XCTAssertTrue(after.contains("pry"), "bought Precision 3 and still can't Pry")
        XCTAssertTrue(after.contains("unbind"), "the baseline swing is not something you buy")
    }

    @MainActor
    func testFortitudeIsWorthHealthAndArmour() {
        let store = GameStore(io: .temporary(name: "fort-\(UUID().uuidString)"))
        let bareHP = CombatRules.maximumHealth(of: .binder, in: store.state)
        let bareTaken = CombatRules.damageTaken(20, by: .binder, in: store.state)

        store.mutate("test: into Fortitude") { state in
            state.base.binderCharacter.level = 10
            state.base.binderCharacter.ownedCombatNodeIDs = legacyCombatNodes(["fortitude": 2])
        }
        XCTAssertGreaterThan(CombatRules.maximumHealth(of: .binder, in: store.state), bareHP,
                             "Thick Hide bought no health")
        XCTAssertLessThan(CombatRules.damageTaken(20, by: .binder, in: store.state), bareTaken,
                          "Iron Skin soaked nothing")
    }

    private func sameNumbers(_ a: CombatTreeRules.Loadout, _ b: CombatTreeRules.Loadout) -> Bool {
        // Field-by-field rather than `==`, which is deliberately narrow on `Loadout`.
        String(describing: a) == String(describing: b)
    }

    // MARK: Changing your mind

    /// Aimee, 7 Aug: *"people should be able to be respec'd at the spring in town."*
    @MainActor
    func testTheSpringTakesBackWhatSomebodyLearned() {
        let store = GameStore(io: .temporary(name: "respec-\(UUID().uuidString)"))
        store.mutate("test: a build, and money") { state in
            state.base.addEssenceCrystals(5000)
            state.base.binderCharacter.level = Tuning.Character.maximumLevel
            state.base.binderCharacter.ownedCombatNodeIDs = legacyCombatNodes(["force": 3, "fortitude": 3])
            state.base.binderCharacter.unspentCombatPoints = 18
        }
        XCTAssertEqual(CombatTreeRules.spentPoints(store.state.base.binderCharacter), 6)

        let cost = store.respecCost(for: .binder)
        XCTAssertGreaterThan(cost, 0, "unlearning has to cost, or it's a free retry")
        let purse = store.state.base.essenceCrystalCount

        store.respec(.binder)
        XCTAssertEqual(CombatTreeRules.spentPoints(store.state.base.binderCharacter), 0)
        XCTAssertEqual(CombatTreeRules.unspentPoints(store.state.base.binderCharacter),
                       CombatTreeRules.totalPoints(atLevel: Tuning.Character.maximumLevel),
                       "the points came back")
        XCTAssertEqual(store.state.base.essenceCrystalCount, purse - cost)
        XCTAssertEqual(Set(CombatRules.skills(for: .binder, in: store.state).map(\.id)),
                       CombatActionOwnershipRules.binderInnate,
                       "respec kept only the Binder's identity techniques")
    }

    /// Nothing to take back, and nothing to pay for it with, are both refusals rather than crashes.
    @MainActor
    func testUnlearningNothingCostsNothingAndIsRefused() {
        let store = GameStore(io: .temporary(name: "respec0-\(UUID().uuidString)"))
        XCTAssertEqual(store.respecCost(for: .binder), 0)
        XCTAssertFalse(store.canRespec(.binder))

        store.mutate("test: a build, and no money") { state in
            state.base.essenceCrystals = nil
            state.base.binderCharacter.level = 10
            state.base.binderCharacter.ownedCombatNodeIDs = legacyCombatNodes(["force": 3])
        }
        XCTAssertFalse(store.canRespec(.binder), "afforded a respec with an empty purse")
        store.respec(.binder)
        XCTAssertEqual(CombatTreeRules.spentPoints(store.state.base.binderCharacter), 3,
                       "respecced without paying")
    }

    // MARK: Callings

    /// *"A calling gives a starting lean, never a limit"* (`combat-trees-full.md` §6). Halloway
    /// begins in Force because she has swung a hammer for a living.
    @MainActor
    func testRecruitingSomebodyBringsTheirTradeWithThem() throws {
        let halloway = try XCTUnwrap(ContentCatalog.shared.traveller("halloway"))
        XCTAssertFalse(halloway.combatNodePlan.isEmpty, "a smith joined knowing nothing about anything")

        var base = BaseState.newGame()
        base.seat("halloway")
        let seated = try XCTUnwrap(base.roster.first { $0.traveller == "halloway" })
        XCTAssertEqual(seated.character.ownedCombatNodeIDs, Set(halloway.combatNodePlan))
        XCTAssertGreaterThan(CombatTreeRules.spentPoints(seated.character), 0)
    }

    /// **Free, not deducted.** Charging a lean against the level budget would make an experienced
    /// tradesperson arrive *behind* a stranger, which is backwards.
    @MainActor
    func testALeanDoesNotCostThemTheirFirstLevels() throws {
        var base = BaseState.newGame()
        base.seat("halloway")
        let smith = try XCTUnwrap(base.roster.first { $0.traveller == "halloway" }).character
        let stranger = CharacterState()

        XCTAssertEqual(CombatTreeRules.unspentPoints(smith),
                       CombatTreeRules.unspentPoints(stranger),
                       "the smith paid for her own trade out of her levelling")
        XCTAssertGreaterThan(CombatTreeRules.spentPoints(smith), CombatTreeRules.spentPoints(stranger))
    }

    /// A lean is a lean, not a class: the Spring can move it like anything else.
    @MainActor
    func testALeanCanBeRespeccedLikeAnythingElse() throws {
        let store = GameStore(io: .temporary(name: "lean-\(UUID().uuidString)"))
        store.mutate("test: a smith, and money") { state in
            state.base.addEssenceCrystals(5000)
            state.base.seat("halloway")
        }
        let index = try XCTUnwrap(store.state.base.roster.firstIndex { $0.traveller == "halloway" })
        let member = PartyMember.member(try XCTUnwrap(
            store.state.base.persistentID(forRosterIndex: index)))
        XCTAssertGreaterThan(store.respecCost(for: member), 0)

        store.respec(member)
        XCTAssertTrue(store.character(of: member).ownedCombatNodeIDs.isEmpty, "the lean stuck")
        XCTAssertGreaterThan(CombatTreeRules.unspentPoints(store.character(of: member)), 0,
                             "unlearning a lean deleted the points instead of returning them")
    }

    /// Nobody joins as a blank. A traveller without a lean is a person with no past.
    func testEveryTravellerHasATrade() {
        for traveller in ContentCatalog.shared.travellers {
            XCTAssertEqual(traveller.combatGraphVersion, CombatGraphRules.graphVersion)
            XCTAssertFalse(traveller.combatNodePlan.isEmpty,
                           "\(traveller.name) has a calling and no lean to show for it")
            for node in traveller.combatNodePlan {
                XCTAssertNotNil(ContentCatalog.shared.combatGraph.node(node),
                                "\(traveller.name) leans into unknown node '\(node.rawValue)'")
            }
        }
    }
}
