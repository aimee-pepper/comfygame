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

    func testAnchoredRealmSurvivesSaveRoundTrip() throws {
        var state = GameState.newGame()
        let book = BoundBook(symbols: [:], randomlyFilled: [], essencePaid: 0)
        let generated = Worldgen.generate(book: book, seed: 73)
        let run = WorldRun(runIndex: 7, book: book, mapSeed: 73, rng: SeededRNG(seed: 73),
                           map: generated.map, playerPosition: generated.start)
        state.worlds.anchoredRealms = [
            AnchoredRealm(runIndex: 7, name: "The Quiet Reach", route: .craftedFrame,
                          sustainObligation: 3, productionContribution: 1,
                          assignedCompanions: [0], world: run)
        ]

        try io.write(SaveCodec.encode(state))
        let reloaded = try XCTUnwrap(io.load().state)

        XCTAssertEqual(reloaded.worlds.anchoredRealms, state.worlds.anchoredRealms)
        XCTAssertEqual(reloaded.worlds.anchoredRealms.first?.projectedShortfall, 2)
    }

    func testSaveFromBeforeAnchoringLoadsWithAnEmptyAtlas() throws {
        let state = GameState.newGame()
        let encoded = try SaveCodec.encode(state)
        var root = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        var worlds = try XCTUnwrap(root["worlds"] as? [String: Any])
        worlds.removeValue(forKey: "anchoredRealms")
        root["worlds"] = worlds
        let legacy = try JSONSerialization.data(withJSONObject: root)

        try io.write(legacy)
        let reloaded = try XCTUnwrap(io.load().state)

        XCTAssertEqual(reloaded.worlds.anchoredRealms, [])
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
        var encounter = EncounterState(
            id: InstanceID(rawValue: rng.next()),
            foes: [FoeState(id: InstanceID(rawValue: 1),
                            creatureID: "ink_hound",
                            stats: CombatStats(displayName: "Ink Hound", icon: "pawprint", maxHP: 16, attack: 4),
                            currentHP: 9)],
            order: [.binder, .companion(0), .foe(InstanceID(rawValue: 1))],
            log: ["You hit Ink Hound for 5."]
        )
        encounter.turnIndex = 1
        encounter.roundNumber = 3
        run.activeEncounter = encounter
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

    func testPreparedLaunchCommitsReconciliationBeforePublishingState() throws {
        var saved = GameState.newGame()
        saved.meta.launchCount = 4
        saved.meta.mutationCount = 9
        saved.base.essence = 0
        try io.write(SaveCodec.encode(saved))

        let prepared = try GameStore.prepareLaunch(io: io)
        let persisted = try XCTUnwrap(io.load().state)

        XCTAssertEqual(prepared.state.meta.launchCount, 5)
        XCTAssertEqual(prepared.state.meta.mutationCount, 11,
                       "Launch and the anti-stranding Spring are two honest commitments")
        XCTAssertEqual(persisted, prepared.state,
                       "A published store can never outrun its launch commitment on disk")
        XCTAssertGreaterThanOrEqual(prepared.timings.loadMilliseconds, 0)
        XCTAssertGreaterThanOrEqual(prepared.timings.reconciliationMilliseconds, 0)
        XCTAssertGreaterThanOrEqual(prepared.timings.persistenceMilliseconds, 0)
        XCTAssertGreaterThanOrEqual(prepared.timings.totalMilliseconds,
                                    prepared.timings.loadMilliseconds)
    }

    @MainActor
    func testLaunchCoordinatorPublishesOnlyPreparedStateAndWarmReadyDoesNotFlash() async throws {
        final class Announcements: @unchecked Sendable {
            var values: [String] = []
        }
        let announcements = Announcements()
        let prepared = try GameStore.prepareLaunch(io: io)
        let coordinator = AppLaunchCoordinator(announce: { announcements.values.append($0) },
                                               prepare: { prepared })
        XCTAssertNil(coordinator.store)
        coordinator.start()
        try await waitUntil { coordinator.store != nil }
        XCTAssertEqual(coordinator.store?.state, prepared.state)
        XCTAssertEqual(announcements.values, ["The Atlas is open."])

        let warmStore = try XCTUnwrap(coordinator.store)
        let warm = AppLaunchCoordinator(readyStore: warmStore,
                                        announce: { announcements.values.append($0) },
                                        prepare: { prepared })
        warm.start()
        XCTAssertTrue(warm.store === warmStore,
                      "An already-ready warm scene must not swap through the loader")
        XCTAssertEqual(announcements.values, ["The Atlas is open."],
                       "An immediately warm-ready scene must not announce a redundant transition")
    }

    @MainActor
    func testLaunchCoordinatorShowsFailureAndTimeoutWithRetryPath() async throws {
        struct TestFailure: LocalizedError {
            var errorDescription: String? { "A deliberate launch failure." }
        }
        let failure = AppLaunchCoordinator(prepare: { throw TestFailure() })
        failure.start()
        try await waitUntil {
            if case .failed = failure.phase { return true }
            return false
        }
        guard case .failed(let failureState) = failure.phase else { return XCTFail("Expected failure") }
        XCTAssertEqual(failureState.message, "The Atlas could not be opened.")
        XCTAssertEqual(failureState.details, "A deliberate launch failure.")
        XCTAssertTrue(failureState.canRetry)

        let timeoutIO = try XCTUnwrap(io)
        let timeout = AppLaunchCoordinator(timeout: .milliseconds(20), prepare: {
            try await Task.sleep(for: .milliseconds(80))
            return try GameStore.prepareLaunch(io: timeoutIO)
        })
        timeout.start()
        try await waitUntil {
            if case .failed = timeout.phase { return true }
            return false
        }
        guard case .failed(let timeoutState) = timeout.phase else { return XCTFail("Expected timeout") }
        XCTAssertEqual(timeoutState.message, "The Atlas is taking longer than expected.")
        XCTAssertFalse(timeoutState.canRetry)
        timeout.retry()
        try await waitUntil { timeout.store != nil }
        XCTAssertNotNil(timeout.store, "A timed-out preparation finishes safely instead of racing a replacement writer")
    }

    @MainActor
    func testLaunchTimeoutSerializesRetryWriters() async throws {
        actor Probe {
            var calls = 0
            var active = 0
            var maximumActive = 0
            func begin() -> Int {
                calls += 1
                active += 1
                maximumActive = max(maximumActive, active)
                return calls
            }
            func end() { active -= 1 }
            func snapshot() -> (Int, Int) { (calls, maximumActive) }
        }
        struct FirstFailure: LocalizedError { var errorDescription: String? { "first writer failed" } }
        let probe = Probe()
        let prepared = try GameStore.prepareLaunch(io: io)
        let coordinator = AppLaunchCoordinator(timeout: .milliseconds(10), prepare: {
            let call = await probe.begin()
            try? await Task.sleep(for: .milliseconds(50))
            await probe.end()
            if call == 1 { throw FirstFailure() }
            return prepared
        })
        coordinator.start()
        try await waitUntil {
            if case .failed(let state) = coordinator.phase { return !state.canRetry }
            return false
        }
        coordinator.retry()
        let timedOutSnapshot = await probe.snapshot()
        XCTAssertEqual(timedOutSnapshot.0, 1, "Retry remains disabled while the timed-out writer owns the save path")
        try await waitUntil {
            if case .failed(let state) = coordinator.phase { return state.canRetry }
            return false
        }
        coordinator.retry()
        try await waitUntil { coordinator.store != nil }
        let snapshot = await probe.snapshot()
        XCTAssertEqual(snapshot.0, 2)
        XCTAssertEqual(snapshot.1, 1, "Launch writers must never overlap")
    }

    func testFirstFrameClockIncludesElapsedLaunchWork() async throws {
        LaunchClock.begin()
        let before = LaunchClock.elapsedMilliseconds()
        try await Task.sleep(for: .milliseconds(25))
        let after = LaunchClock.elapsedMilliseconds()
        XCTAssertGreaterThanOrEqual(after - before, 20,
                                    "The eager launch epoch must include work before the first frame")
    }

    func testStaticLaunchMarkUsesTheAcceptedPairedPageGeometry() throws {
        let projectRoot = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let storyboard = try String(contentsOf: projectRoot.appendingPathComponent("Support/LaunchScreen.storyboard"),
                                    encoding: .utf8)
        let acceptedRects = [
            "x=\"0\" y=\"4\" width=\"36\" height=\"54\"",
            "x=\"38\" y=\"4\" width=\"36\" height=\"54\"",
            "x=\"4\" y=\"8\" width=\"32\" height=\"46\"",
            "x=\"38\" y=\"8\" width=\"32\" height=\"46\"",
            "x=\"8\" y=\"12\" width=\"28\" height=\"38\"",
            "x=\"38\" y=\"12\" width=\"28\" height=\"38\"",
            "x=\"35\" y=\"0\" width=\"4\" height=\"58\"",
            "x=\"0\" y=\"54\" width=\"32\" height=\"4\"",
            "x=\"42\" y=\"54\" width=\"32\" height=\"4\"",
            "x=\"8\" y=\"46\" width=\"6\" height=\"4\"",
            "x=\"60\" y=\"50\" width=\"6\" height=\"4\""
        ]
        for rect in acceptedRects {
            XCTAssertTrue(storyboard.contains(rect), "Static launch mark drifted from v0.2 rectangle \(rect)")
        }
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

    func testFutureSchemaIsRejectedBeforeTolerantDecodeCanRewriteIt() throws {
        let future = Tuning.saveSchemaVersion + 1
        let data = Data("{\"schemaVersion\":\(future),\"base\":{\"essence\":999}}".utf8)
        XCTAssertThrowsError(try SaveCodec.decode(data)) { error in
            XCTAssertEqual(error as? Migrations.FutureSchemaError,
                           .init(found: future, supported: Tuning.saveSchemaVersion))
        }
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

    @MainActor
    private func waitUntil(timeout: Duration = .seconds(1), _ predicate: () -> Bool) async throws {
        let deadline = ContinuousClock.now + timeout
        while ContinuousClock.now < deadline {
            if predicate() { return }
            try await Task.sleep(for: .milliseconds(5))
        }
        XCTFail("Timed out waiting for launch state")
    }
}
