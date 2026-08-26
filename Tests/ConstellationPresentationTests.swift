import XCTest
@testable import Bookbinder

@MainActor
final class ConstellationPresentationTests: XCTestCase {
    func testFirstSliceHasOneTruthfullyDescribedLiveNode() throws {
        let nodes = ContentCatalog.shared.constellationNodes
        XCTAssertEqual(nodes.count, 1)
        let node = try XCTUnwrap(nodes.first)
        XCTAssertEqual(node.id, ConstellationNodes.extraGambitSlot)
        XCTAssertEqual(node.name, "The Long Instruction")
        XCTAssertEqual(node.blurb,
                       "Adds one Gambit rule slot to every current and future person in this campaign.")
    }

    func testPresentationStateDistinguishesShortfallAffordableAndBought() {
        XCTAssertEqual(ConstellationNodePresentationState.resolve(
            rank: 0, maxRank: 1, cost: 3, motes: 1), .shortfall(missing: 2))
        XCTAssertEqual(ConstellationNodePresentationState.resolve(
            rank: 0, maxRank: 1, cost: 3, motes: 3), .affordable)
        XCTAssertEqual(ConstellationNodePresentationState.resolve(
            rank: 1, maxRank: 1, cost: nil, motes: 0), .bought)
    }

    func testPurchaseActionRemainsOutsideScrollableRealityDetails() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(
            contentsOf: root.appending(path: "Sources/Screens/SpendingViews.swift"),
            encoding: .utf8
        )

        XCTAssertTrue(source.contains(".safeAreaInset(edge: .bottom, spacing: 0)"))
        XCTAssertTrue(source.contains("if let cost"))
        XCTAssertTrue(source.contains("PersistentActionBar(message: state.label, messageTint: state.tint)"))
        XCTAssertTrue(source.contains("Button(\"Fix in place · \\(cost)"))
        XCTAssertTrue(source.contains("cost == 1 ? \"Mote\" : \"Motes\""))
        XCTAssertTrue(source.contains("Fix \\(node.name) in place?"))
        XCTAssertTrue(source.contains("Button(\"Spend \\(cost) Motes\")"))
        XCTAssertTrue(source.contains("This permanently changes Reality for the current campaign."))
        XCTAssertTrue(source.contains("if store.buy(node)"))
        XCTAssertTrue(source.contains("Constellation not changed"))
        XCTAssertTrue(source.contains("Your Motes or this node's rank changed."))
        XCTAssertFalse(source.contains("Button(\"Spend \\(cost) Motes\") { _ = store.buy(node) }"))
        XCTAssertFalse(source.contains("Button(\"Fix in place\") { _ = store.buy(node) }"))
    }

    func testInsufficientAndDuplicatePurchasesAreAtomic() throws {
        let store = GameStore(io: .temporary(name: "constellation-atomic-\(UUID().uuidString)"))
        let node = try XCTUnwrap(ContentCatalog.shared.constellationNodes.first)
        let original = store.state
        XCTAssertFalse(store.buy(node))
        XCTAssertEqual(store.state, original)

        store.mutate("grant motes") { $0.reality.motes = 10 }
        XCTAssertTrue(store.buy(node))
        let bought = store.state
        XCTAssertFalse(store.buy(node))
        XCTAssertEqual(store.state, bought)
    }

    func testLongInstructionAppliesToCurrentAndFuturePeopleAndPersists() throws {
        let io = SaveFileIO.temporary(name: "constellation-persist-\(UUID().uuidString)")
        let store = GameStore(io: io)
        let node = try XCTUnwrap(ContentCatalog.shared.constellationNodes.first)
        let binderBefore = store.activeGambitSlots(for: .binder)
        store.mutate("grant motes", flush: true) { $0.reality.motes = 10 }
        XCTAssertTrue(store.buy(node))
        XCTAssertEqual(store.activeGambitSlots(for: .binder), binderBefore + 1)

        let future = try XCTUnwrap(ContentCatalog.shared.travellers.first {
            person in !store.state.base.roster.contains { $0.traveller == person.id }
        })
        store.mutate("meet future person", flush: true) { state in
            XCTAssertTrue(state.base.seat(future.id))
        }
        let index = try XCTUnwrap(store.state.base.roster.firstIndex { $0.traveller == future.id })
        let memberID = try XCTUnwrap(store.state.base.persistentID(forRosterIndex: index))
        let expected = store.activeGambitSlots(for: .companion(memberID))

        let relaunched = GameStore(io: io)
        XCTAssertEqual(relaunched.state.reality.rank(of: node.id), 1)
        XCTAssertEqual(relaunched.activeGambitSlots(for: .binder), binderBefore + 1)
        XCTAssertEqual(relaunched.activeGambitSlots(for: .companion(memberID)), expected)
    }
}
