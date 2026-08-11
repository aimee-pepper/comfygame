import XCTest
@testable import Bookbinder

final class CombatActionOwnershipTests: XCTestCase {
    func testStartingIdentityTechniquesDoNotFollowGenericCompanionStatus() {
        var state = GameState.newGame()
        var ordinary = CompanionState()
        ordinary.name = "Ordinary"
        ordinary.traveller = "mara"
        var generated = CompanionState()
        generated.name = "Generated"
        generated.traveller = nil
        var ashe = CompanionState()
        ashe.name = "Ashe"
        ashe.traveller = "ashe"
        state.base.roster.append(contentsOf: [ordinary, generated, ashe])

        XCTAssertEqual(CombatActionOwnershipRules.innateSkillIDs(for: .binder, in: state),
                       ["unbind", "sight"])
        XCTAssertEqual(CombatActionOwnershipRules.innateSkillIDs(for: .companion(0), in: state),
                       ["mend", "read"])
        XCTAssertEqual(CombatActionOwnershipRules.innateSkillIDs(for: .companion(1), in: state), [])
        XCTAssertEqual(CombatActionOwnershipRules.innateSkillIDs(for: .companion(2), in: state), [],
                       "nil traveller is not a second Quill")
        XCTAssertEqual(CombatActionOwnershipRules.innateSkillIDs(for: .companion(3), in: state),
                       ["ground"])
    }

    func testGraphSkillsUnionWithIdentityButRoutRemainsDecodeOnly() {
        var state = GameState.newGame()
        state.base.binderCharacter.branchDepth["force"] = 3
        let graph = CombatTreeRules.loadout(for: state.base.binderCharacter).skills
        let available = CombatActionOwnershipRules.availableSkillIDs(for: .binder, in: state)

        XCTAssertTrue(graph.isSubset(of: available))
        XCTAssertTrue(available.isSuperset(of: ["unbind", "sight"]))
        XCTAssertFalse(available.contains("mend"))
        XCTAssertFalse(available.contains("read"))
        XCTAssertFalse(available.contains("rout"))
        XCTAssertNotNil(ContentCatalog.shared.skill("rout"),
                        "legacy Rout remains available to tolerant decoders")
    }

    func testCatalogueOwnerIsNotRuntimeAuthority() {
        var state = GameState.newGame()
        var ordinary = CompanionState()
        ordinary.traveller = "mara"
        state.base.roster.append(ordinary)
        XCTAssertEqual(ContentCatalog.shared.skill("mend")?.owner, .companion)
        XCTAssertFalse(CombatActionOwnershipRules.availableSkillIDs(for: .companion(1), in: state)
            .contains("mend"))
    }

    @MainActor
    func testStoreSkillConsumersReadExactActorPaletteRatherThanLegacyOwner() {
        let store = GameStore(io: .temporary(name: "ownership-\(UUID().uuidString)"))
        XCTAssertEqual(Set(CombatRules.skills(for: .binder, in: store.state).map(\.id)),
                       ["unbind", "sight"])
        XCTAssertEqual(Set(CombatRules.skills(for: .companion(0), in: store.state).map(\.id)),
                       ["mend", "read"])
    }
}
