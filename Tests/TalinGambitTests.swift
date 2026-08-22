import XCTest
@testable import Bookbinder

@MainActor
final class TalinGambitTests: XCTestCase {
    private func fight(mark: GambitComponentID = "armour_mark_1") -> GameStore {
        let store = GameStore(io: .temporary(name: "talin-armour-\(UUID().uuidString)"))
        let rule = GambitRule(id: InstanceID(rawValue: 700),
                              subject: FoeArmourGambit.subject,
                              threshold: mark,
                              action: "act_attack")
        store.write("plains")
        store.bindAndDepart()
        store.mutate("stage Talin fixture") { state in
            state.base.ownedGambitComponents.formUnion([
                FoeArmourGambit.subject, mark, "act_attack"
            ])
            state.base.companion.gambits = [rule]
            guard var run = state.worlds.activeRun else { return }
            let enemies = (0..<3).map { index in
                WorldEnemy(id: InstanceID(rawValue: UInt64(index + 1)),
                           creatureID: "paper_moth", position: run.playerPosition, isAwake: true)
            }
            run.enemies = enemies
            state.worlds.activeRun = run
            WorldRules.beginEncounter(triggeredBy: enemies[0], in: &state)
        }
        return store
    }

    private func setArmour(_ values: [Int], in store: GameStore) {
        store.mutate("set live armour") { state in
            guard var run = state.worlds.activeRun, var encounter = run.activeEncounter else { return }
            for index in values.indices where encounter.foes.indices.contains(index) {
                encounter.foes[index].stats.armour = values[index]
            }
            run.activeEncounter = encounter
            state.worlds.activeRun = run
        }
    }

    private func attackedIndex(in store: GameStore) -> Int? {
        guard case .attack(let id)? = GambitEngine.decide(in: store.state)?.action else { return nil }
        return store.activeEncounter?.foes.firstIndex { $0.id == id }
    }

    func testStrictMarksUseFirstLivingFoeAboveCurrentArmour() {
        for (mark, values, expected) in [
            ("armour_mark_1", [0, 1, 2], 2),
            ("armour_mark_3", [3, 4, 6], 1),
            ("armour_mark_5", [5, 6, 7], 1)
        ] as [(GambitComponentID, [Int], Int)] {
            let store = fight(mark: mark)
            setArmour(values, in: store)
            XCTAssertEqual(attackedIndex(in: store), expected, "\(mark) must be strict and ordered")
        }
    }

    func testEvaluationReadsLiveArmourAndWrongGrammarFailsClosed() {
        let store = fight()
        setArmour([2, 0, 0], in: store)
        XCTAssertEqual(attackedIndex(in: store), 0)
        setArmour([1, 2, 0], in: store)
        XCTAssertEqual(attackedIndex(in: store), 1)

        store.mutate("inject generic HP threshold") { state in
            state.base.ownedGambitComponents.insert("thr_50")
            state.base.companion.gambits[0].threshold = "thr_50"
        }
        XCTAssertNil(GambitEngine.decide(in: store.state))
        store.mutate("inject forbidden property") { state in
            state.base.ownedGambitComponents.formUnion(["armour_mark_1", "prop_hp"])
            state.base.companion.gambits[0].threshold = "armour_mark_1"
            state.base.companion.gambits[0].property = "prop_hp"
        }
        XCTAssertNil(GambitEngine.decide(in: store.state))
    }

    func testRuleRoundTripsWithOnlySubjectMarkAndIndependentAction() throws {
        let rule = GambitRule(id: InstanceID(rawValue: 701),
                              subject: FoeArmourGambit.subject,
                              threshold: "armour_mark_3", action: "act_flee")
        let decoded = try JSONDecoder().decode(GambitRule.self, from: JSONEncoder().encode(rule))
        XCTAssertEqual(decoded, rule)
        XCTAssertNil(decoded.property)
        XCTAssertNil(decoded.comparator)
        XCTAssertEqual(decoded.displayText, "Foe · Armour threshold 3 → Flee")
    }

    func testArmourThresholdPresentationPreservesDistinctValuesAndFailsWithoutInventingOne() {
        let one = GambitRule(id: 701, subject: FoeArmourGambit.subject,
                             threshold: "armour_mark_1", action: "act_attack")
        let five = GambitRule(id: 702, subject: FoeArmourGambit.subject,
                              threshold: "armour_mark_5", action: "act_attack")
        let invalid = GambitRule(id: 703, subject: FoeArmourGambit.subject,
                                 threshold: nil, action: "act_attack")
        XCTAssertEqual(one.displayText, "Foe · Armour threshold 1 → Attack")
        XCTAssertEqual(five.displayText, "Foe · Armour threshold 5 → Attack")
        XCTAssertEqual(invalid.displayText, "Foe · armour threshold → Attack")
    }

    func testReadingTalinTeachingAtomicallyGrantsUsableSubjectAndFirstMarkOnce() {
        var state = GameState.newGame()
        let events = WorldRules.readPage("talin_teach_armour", in: &state)
        XCTAssertEqual(events, [.readPage("talin_teach_armour"),
                                .learnedGambit(FoeArmourGambit.subject)])
        XCTAssertTrue(state.base.ownedGambitComponents.contains(FoeArmourGambit.subject))
        XCTAssertTrue(state.base.ownedGambitComponents.contains("armour_mark_1"))
        let snapshot = state
        XCTAssertEqual(WorldRules.readPage("talin_teach_armour", in: &state), [])
        XCTAssertEqual(state, snapshot)
    }

    func testCatalogueShipsExactTalinSubjectAndMarks() {
        let catalog = ContentCatalog.shared
        XCTAssertEqual(catalog.diaryPage("talin_teach_armour")?.teachesGambit,
                       FoeArmourGambit.subject)
        XCTAssertEqual(catalog.gambitComponent(FoeArmourGambit.subject)?.selector,
                       "foe.armourAbove")
        XCTAssertEqual(Set(FoeArmourGambit.marks.values), Set([1, 3, 5]))
    }
}
