import XCTest
@testable import Bookbinder

/// **A class is where you spent** (`docs/combat-trees-full.md`). Three trees, three branches each,
/// eight nodes deep, and nobody is assigned anything.
final class CombatTreeTests: XCTestCase {

    private var branches: [CombatBranchDef] { ContentCatalog.shared.combatBranches }

    private func spent(_ depths: [CombatBranchID: Int], level: Int = 25) -> CharacterState {
        var c = CharacterState()
        c.level = level
        c.branchDepth = depths
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
    func testAFinishedCompanionHasThreeBranchesAndSixTheyNeverTouched() throws {
        var character = CharacterState()
        character.level = Tuning.Character.maximumLevel
        for id: CombatBranchID in ["swiftness", "evasion", "shadow"] {
            let branch = try XCTUnwrap(ContentCatalog.shared.combatBranch(id))
            for _ in branch.nodes.indices { CombatTreeRules.buyNext(in: branch, for: &character) }
        }
        XCTAssertEqual(CombatTreeRules.unspentPoints(character), 0, "a finished build has nothing left")
        XCTAssertEqual(CombatTreeRules.completedBranches(character).count, 3)
        XCTAssertEqual(CombatTreeRules.className(for: character), "Rogue", "Aimee's own example")

        // A fourth branch is unaffordable, whatever else you do.
        let force = try XCTUnwrap(ContentCatalog.shared.combatBranch("force"))
        XCTAssertFalse(CombatTreeRules.canBuyNext(in: force, for: character))
    }

    // MARK: Spending

    func testNodesAreBoughtInOrderAndCostOneEach() throws {
        let branch = try XCTUnwrap(ContentCatalog.shared.combatBranch("force"))
        var character = spent([:])

        for expected in branch.nodes {
            let bought = CombatTreeRules.buyNext(in: branch, for: &character)
            XCTAssertEqual(bought?.index, expected.index, "bought out of order")
        }
        XCTAssertNil(CombatTreeRules.buyNext(in: branch, for: &character), "bought past the capstone")
        XCTAssertEqual(CombatTreeRules.spentPoints(character), branch.nodes.count)
    }

    func testYouCannotSpendPointsYouHaveNotEarned() throws {
        let branch = try XCTUnwrap(ContentCatalog.shared.combatBranch("force"))
        var fresh = spent([:], level: 1)
        XCTAssertEqual(CombatTreeRules.totalPoints(atLevel: 1), 0, "level one is the first, not a paid one")
        XCTAssertFalse(CombatTreeRules.canBuyNext(in: branch, for: fresh))
        XCTAssertNil(CombatTreeRules.buyNext(in: branch, for: &fresh))
    }

    /// **Partial investment is legal** — spreading gives you unfinished branches rather than an
    /// illegal state. A worse choice, never a refused one.
    func testSpreadingAcrossNineBranchesIsAllowedAndSimplyWorse() {
        var character = spent([:])
        for branch in branches {
            for _ in 0..<2 { CombatTreeRules.buyNext(in: branch, for: &character) }
        }
        XCTAssertEqual(CombatTreeRules.spentPoints(character), 18)
        XCTAssertTrue(CombatTreeRules.completedBranches(character).isEmpty)
        XCTAssertNil(CombatTreeRules.className(for: character), "nine shallow branches is not a class")
    }

    // MARK: Nothing ships inert

    /// **The Constellation fossil guard, applied to seventy-two nodes** (`fossil-audit.md` §6).
    ///
    /// Every node must change the loadout or teach a skill. A node that reads well and does nothing
    /// is invisible to grep — the thing is *there* — and seventy-two is a lot of places for one to
    /// hide.
    func testEveryNodeDoesSomething() {
        let nothing = CombatTreeRules.Loadout()
        for branch in branches {
            for index in branch.nodes.indices {
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
            for index in branch.nodes.indices {
                let node = branch.nodes[index]
                seen.insert(node.effect.kind)
                if node.effect.kind == .skill { continue }
                let with = CombatTreeRules.loadout(for: spent([branch.id: index + 1]))
                let without = CombatTreeRules.loadout(for: spent([branch.id: index]))
                XCTAssertFalse(sameNumbers(with, without),
                               "effect kind '\(node.effect.kind.rawValue)' changes nothing")
            }
        }
        XCTAssertGreaterThan(seen.count, 40, "the catalogue stopped exercising most of the kinds")
    }

    /// Every skill a node teaches has to exist, or the node is a promise of nothing.
    func testEverySkillANodeTeachesExists() {
        for branch in branches {
            for node in branch.nodes {
                guard let skill = node.grantsSkill else { continue }
                XCTAssertNotNil(ContentCatalog.shared.skill(skill),
                                "\(branch.name) \(node.index) teaches '\(skill.rawValue)', which doesn't exist")
            }
        }
    }

    /// **Sight and Read are deliberately not in the trees** (Aimee, 7 Aug): they're knowledge rather
    /// than fighting, and belong to an instrument. They must still be *usable*, though — a skill
    /// that leaves the trees and has nowhere else to live is a skill nobody can ever use again.
    func testSightAndReadLeftTheTreesWithoutBecomingUnreachable() {
        let taught = Set(branches.flatMap { $0.nodes.compactMap(\.grantsSkill) })
        XCTAssertFalse(taught.contains("sight"), "Sight is a lens, not a branch")
        XCTAssertFalse(taught.contains("read"), "Read is a lens, not a branch")
        XCTAssertTrue(Tuning.TreeSkills.baseline.contains("sight"))
        XCTAssertTrue(Tuning.TreeSkills.baseline.contains("read"))
    }

    // MARK: It reaches the fight

    @MainActor
    func testSpendingAPointChangesWhatYouCanDo() throws {
        let store = GameStore(io: .temporary(name: "trees-\(UUID().uuidString)"))
        let before = CombatRules.skills(for: .binder, in: store.state).map(\.id)
        XCTAssertFalse(before.contains("pry"), "Pry before spending anything on Precision")

        store.mutate("test: three into Precision") { state in
            state.base.binderCharacter.level = 10
            state.base.binderCharacter.branchDepth["precision"] = 3
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
            state.base.binderCharacter.branchDepth["fortitude"] = 2
        }
        XCTAssertGreaterThan(CombatRules.maximumHealth(of: .binder, in: store.state), bareHP,
                             "Thick Hide bought no health")
        XCTAssertLessThan(CombatRules.damageTaken(20, by: .binder, in: store.state), bareTaken,
                          "Iron Skin soaked nothing")
    }

    /// A capstone should be near-absolute, which is what a capstone is for.
    @MainActor
    func testImmovableMakesArmourWorkAgainstPiercing() {
        let store = GameStore(io: .temporary(name: "immov-\(UUID().uuidString)"))
        store.mutate("test: armoured") { state in
            state.base.binderCharacter.level = Tuning.Character.maximumLevel
            state.base.binderCharacter.branchDepth["fortitude"] = 7
        }
        let pierced = CombatRules.damageTaken(30, by: .binder, in: store.state, armourIgnored: 1)

        store.mutate("test: the capstone") { $0.base.binderCharacter.branchDepth["fortitude"] = 8 }
        let withCapstone = CombatRules.damageTaken(30, by: .binder, in: store.state, armourIgnored: 1)
        XCTAssertLessThan(withCapstone, pierced, "Immovable let a piercing blow through anyway")
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
            state.base.essence = 5000
            state.base.binderCharacter.level = Tuning.Character.maximumLevel
            state.base.binderCharacter.branchDepth = ["force": 8, "fortitude": 4]
        }
        XCTAssertEqual(CombatTreeRules.spentPoints(store.state.base.binderCharacter), 12)
        XCTAssertTrue(store.state.base.binderCharacter.branchDepth["force"] == 8)

        let cost = store.respecCost(for: .binder)
        XCTAssertGreaterThan(cost, 0, "unlearning has to cost, or it's a free retry")
        let purse = store.state.base.essence

        store.respec(.binder)
        XCTAssertEqual(CombatTreeRules.spentPoints(store.state.base.binderCharacter), 0)
        XCTAssertEqual(CombatTreeRules.unspentPoints(store.state.base.binderCharacter),
                       CombatTreeRules.totalPoints(atLevel: Tuning.Character.maximumLevel),
                       "the points came back")
        XCTAssertEqual(store.state.base.essence, purse - cost)
        XCTAssertTrue(CombatRules.skills(for: .binder, in: store.state).allSatisfy {
            Tuning.TreeSkills.baseline.contains($0.id.rawValue)
        }, "unlearned the branch and kept the skills")
    }

    /// Nothing to take back, and nothing to pay for it with, are both refusals rather than crashes.
    @MainActor
    func testUnlearningNothingCostsNothingAndIsRefused() {
        let store = GameStore(io: .temporary(name: "respec0-\(UUID().uuidString)"))
        XCTAssertEqual(store.respecCost(for: .binder), 0)
        XCTAssertFalse(store.canRespec(.binder))

        store.mutate("test: a build, and no money") { state in
            state.base.essence = 0
            state.base.binderCharacter.level = 10
            state.base.binderCharacter.branchDepth = ["force": 5]
        }
        XCTAssertFalse(store.canRespec(.binder), "afforded a respec with an empty purse")
        store.respec(.binder)
        XCTAssertEqual(CombatTreeRules.spentPoints(store.state.base.binderCharacter), 5,
                       "respecced without paying")
    }
}
