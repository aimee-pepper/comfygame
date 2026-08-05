import XCTest
@testable import Bookbinder

/// The interruptibility pillar, tested. Anything that breaks here breaks pillar 2.
final class PersistenceTests: XCTestCase {

    private var io: SaveFileIO!

    override func setUp() {
        super.setUp()
        io = .temporary(name: "persistence-\(UUID().uuidString)")
    }

    override func tearDown() {
        io.deleteEverything()
        super.tearDown()
    }

    func testNewGameWhenNoSaveFileExists() {
        guard case .newGame = io.load() else { return XCTFail("Expected a new game") }
    }

    func testSaveRoundTripsExactly() throws {
        var original = GameState.newGame()
        original.reality.motes = 7
        original.reality.discovery.recordCreature("ink_hound", runIndex: 3)
        original.base.essence = 123
        original.base.resources.add(5, of: Resources.ore)
        original.worlds.runIndex = 4

        try io.write(SaveCodec.encode(original))

        guard let reloaded = io.load().state else { return XCTFail("Expected to load") }
        XCTAssertEqual(reloaded, original, "A save round-trip must be lossless")
    }

    /// The acceptance criterion: killed mid-encounter, we come back mid-encounter.
    func testMidEncounterStateSurvivesRoundTrip() throws {
        var state = GameState.newGame()
        var rng = SeededRNG(seed: 42)
        let book = BoundBook(symbols: ["terrain": "caverns", "bounty": "rich_ore"], randomlyFilled: ["biome"], essencePaid: 20)
        let world = Worldgen.generate(book: book, seed: 42)
        var run = WorldRun(
            runIndex: 1,
            book: book,
            mapSeed: 42,
            rng: rng,
            map: world.map,
            playerPosition: world.start,
            enemies: world.enemies
        )
        run.stability = 61.5
        run.turnsTaken = 12
        run.satchel.add(3, of: Resources.ore)
        run.activeEncounter = EncounterState(
            id: InstanceID(rawValue: rng.next()),
            foes: [FoeState(id: InstanceID(rawValue: 1),
                            creatureID: "ink_hound",
                            stats: CombatStats(displayName: "Ink Hound", icon: "pawprint", maxHP: 16, attack: 4),
                            currentHP: 9)],
            order: [.binder, .companion, .foe(InstanceID(rawValue: 1))],
            turnIndex: 1,
            roundNumber: 3,
            log: ["You hit Ink Hound for 5."]
        )
        state.worlds.activeRun = run

        try io.write(SaveCodec.encode(state))
        let reloaded = try XCTUnwrap(io.load().state)

        let restored = try XCTUnwrap(reloaded.worlds.activeRun)
        XCTAssertEqual(restored.activeEncounter?.roundNumber, 3)
        XCTAssertEqual(restored.activeEncounter?.foes.first?.currentHP, 9)
        XCTAssertEqual(restored.stability, 61.5)
        XCTAssertEqual(restored.book.randomlyFilled, ["biome"])
        XCTAssertEqual(reloaded, state)
    }

    /// The RNG must resume *where it was*, not rewind — otherwise a force-quit is a re-roll.
    func testRNGPositionSurvivesRoundTrip() throws {
        var state = GameState.newGame()
        let world = Worldgen.generate(book: BoundBook(symbols: [:], randomlyFilled: [], essencePaid: 0), seed: 99)
        var run = WorldRun(runIndex: 1,
                           book: BoundBook(symbols: [:], randomlyFilled: [], essencePaid: 0),
                           mapSeed: 99,
                           rng: SeededRNG(seed: 99),
                           map: world.map,
                           playerPosition: world.start)
        for _ in 0..<10 { _ = run.rng.next() }
        let expectedNext = { var copy = run.rng; return copy.next() }()
        state.worlds.activeRun = run

        try io.write(SaveCodec.encode(state))
        var reloaded = try XCTUnwrap(try XCTUnwrap(io.load().state).worlds.activeRun)

        XCTAssertEqual(reloaded.rng.drawCount, 10)
        XCTAssertEqual(reloaded.rng.next(), expectedNext, "Resuming must not rewind the RNG stream")
    }

    func testCorruptSaveFallsBackToBackupAndQuarantinesTheBadFile() throws {
        var good = GameState.newGame()
        good.base.essence = 555
        try io.write(SaveCodec.encode(good))
        // Second write rolls the first into .backup, then we corrupt the primary.
        try io.write(SaveCodec.encode(good))
        try Data("{ not json".utf8).write(to: io.saveURL)

        guard case .recoveredFromBackup(let recovered, _) = io.load() else {
            return XCTFail("Expected recovery from the backup file")
        }
        XCTAssertEqual(recovered.base.essence, 555)

        let quarantined = try FileManager.default
            .contentsOfDirectory(atPath: io.directory.path(percentEncoded: false))
            .filter { $0.contains("corrupt") }
        XCTAssertFalse(quarantined.isEmpty, "A bad save must be moved aside, never deleted")
    }

    /// Adding a field to a layer must not cost a player their save.
    func testSaveMissingAWholeLayerStillLoads() throws {
        let partial = """
        { "schemaVersion": 1, "base": { "essence": 77 } }
        """
        try FileManager.default.createDirectory(at: io.directory, withIntermediateDirectories: true)
        try Data(partial.utf8).write(to: io.saveURL)

        let loaded = try XCTUnwrap(io.load().state)
        XCTAssertEqual(loaded.base.essence, 77)
        XCTAssertEqual(loaded.reality.motes, 0, "A missing layer falls back to its new-game value")
    }

    // MARK: - GameStore

    @MainActor
    func testEveryMutationIsPersistedAndCounted() async throws {
        let store = GameStore(io: io)
        let startingCount = store.state.meta.mutationCount

        store.mutate("test mutation") { $0.reality.motes += 3 }
        XCTAssertEqual(store.state.meta.mutationCount, startingCount + 1)
        XCTAssertEqual(store.state.meta.lastAction, "test mutation")

        try await waitForDiskToCatchUp(store)
        let onDisk = try XCTUnwrap(io.load().state)
        XCTAssertEqual(onDisk.reality.motes, 3)
        XCTAssertEqual(onDisk.meta.mutationCount, store.state.meta.mutationCount)
    }

    /// A commitment point must be on disk before the call returns — no debounce window.
    @MainActor
    func testFlushingMutationIsOnDiskImmediately() throws {
        let store = GameStore(io: io)
        store.mutate("commitment point", flush: true) { $0.base.essence = 999 }

        let onDisk = try XCTUnwrap(io.load().state)
        XCTAssertEqual(onDisk.base.essence, 999)
        XCTAssertEqual(onDisk.meta.mutationCount, store.state.meta.mutationCount)
    }

    /// Rapid taps must collapse into few writes but still land the final state.
    @MainActor
    func testRapidMutationsDebounceAndStillLandTheLastValue() async throws {
        let store = GameStore(io: io)
        let writesBefore = store.diagnostics.writeCount

        for index in 1...20 { store.mutate("tap \(index)") { $0.reality.motes = index } }

        try await waitForDiskToCatchUp(store)
        XCTAssertEqual(try XCTUnwrap(io.load().state).reality.motes, 20)
        XCTAssertLessThan(store.diagnostics.writeCount - writesBefore, 20, "Writes should coalesce")
    }

    /// Relaunching must not disturb anything except the launch counter.
    @MainActor
    func testRelaunchResumesExactly() async throws {
        let first = GameStore(io: io)
        first.mutate("mid-run", flush: true) { state in
            state.base.essence = 42
            state.reality.motes = 2
            state.worlds.runIndex = 3
        }
        let before = first.state

        let second = GameStore(io: io) // simulates a cold launch off the same file
        XCTAssertEqual(second.state.base, before.base)
        XCTAssertEqual(second.state.reality, before.reality)
        XCTAssertEqual(second.state.worlds, before.worlds)
        XCTAssertEqual(second.state.meta.launchCount, before.meta.launchCount + 1)
    }

    /// The three-layer split has to be real, not aspirational.
    @MainActor
    func testResetBaseKeepsReality() throws {
        let store = GameStore(io: io)
        store.mutate("seed state", flush: true) { state in
            state.reality.motes = 9
            state.reality.discovery.recordCreature("paper_moth", runIndex: 1)
            state.base.essence = 500
            state.base.resources.add(10, of: Resources.ore)
        }

        store.resetBaseKeepingReality()

        XCTAssertEqual(store.state.reality.motes, 9)
        XCTAssertTrue(store.state.reality.discovery.hasEncountered(creature: "paper_moth"))
        XCTAssertEqual(store.state.base.essence, Tuning.Economy.startingEssence)
        XCTAssertEqual(store.state.base.resources[Resources.ore], 0)
        XCTAssertNil(store.state.worlds.activeRun)
    }

    // MARK: - Helpers

    @MainActor
    private func waitForDiskToCatchUp(_ store: GameStore, timeout: Duration = .seconds(2)) async throws {
        let deadline = ContinuousClock.now + timeout
        while ContinuousClock.now < deadline {
            if store.diagnostics.savedMutationCount == store.state.meta.mutationCount { return }
            try await Task.sleep(for: .milliseconds(10))
        }
        XCTFail("Disk never caught up with memory")
    }
}
