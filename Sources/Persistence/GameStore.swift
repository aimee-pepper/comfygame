import Foundation
import SwiftUI
import OSLog

/// The single owner of game state, and the only thing that writes the save.
///
/// The interruptibility pillar in one rule: **every state change goes through `mutate`**, and
/// `mutate` always schedules a write. No view or system may hold its own copy of game state or
/// poke at the save file. If you find yourself wanting to mutate without saving, the answer is a
/// `mutate` call, not a back door.
///
/// Write policy:
///  - Ordinary mutations debounce by `Tuning.saveDebounceMilliseconds` (≤100ms, per the brief) so
///    a rapid tap sequence doesn't write ten times.
///  - Commitment points (`flush: true`) and any scene-phase change write synchronously, before
///    iOS can suspend us. That's what makes "force-quit at ANY moment" true rather than
///    "force-quit at most moments".
///  - Writes go through one serial queue, so they land in the order they were made.
@MainActor
final class GameStore: ObservableObject {
    struct PreparedLaunch: Sendable {
        var state: GameState
        var loadOutcome: String
        var saveFileByteCount: Int?
        var timings: LaunchTimings
    }

    struct LaunchTimings: Equatable, Sendable {
        var loadMilliseconds: Double
        var reconciliationMilliseconds: Double
        var persistenceMilliseconds: Double
        var totalMilliseconds: Double
    }
    @Published private(set) var state: GameState
    @Published private(set) var diagnostics: SaveDiagnostics

    /// What just happened in the world, for the World screen to narrate.
    ///
    /// Deliberately *not* in the save: a resumed run should show you where you are, not replay how
    /// you got there. Losing this to a force-quit costs nothing.
    @Published var recentEvents: [WorldRules.Event] = []

    private let io: SaveFileIO
    private let writeQueue = DispatchQueue(label: "com.aimeepepper.bookbinder.save", qos: .userInitiated)
    private var debounceTask: Task<Void, Never>?

    // MARK: - Construction

    /// Loads synchronously at launch: the app must never render a frame of state it might have
    /// to replace a moment later. The file is a few KB.
    convenience init(io: SaveFileIO) {
        do {
            self.init(io: io, prepared: try Self.prepareLaunch(io: io))
        } catch {
            let state = GameState.newGame()
            self.init(io: io, prepared: PreparedLaunch(
                state: state, loadOutcome: "launch failed: \(error.localizedDescription)",
                saveFileByteCount: io.saveFileByteCount,
                timings: .init(loadMilliseconds: 0, reconciliationMilliseconds: 0,
                               persistenceMilliseconds: 0, totalMilliseconds: 0)
            ))
            diagnostics.lastError = error.localizedDescription
        }
    }

    init(io: SaveFileIO, prepared: PreparedLaunch) {
        self.io = io
        self.state = prepared.state
        self.diagnostics = SaveDiagnostics(
            loadOutcome: prepared.loadOutcome,
            savedMutationCount: prepared.state.meta.mutationCount,
            saveURL: io.saveURL
        )
        self.diagnostics.saveFileByteCount = prepared.saveFileByteCount
    }

    /// All disk, decoding, catalogue reconciliation and the launch commitment can run before the
    /// main actor owns a store. The first SwiftUI frame therefore never waits behind file I/O.
    nonisolated static func prepareLaunch(io: SaveFileIO) throws -> PreparedLaunch {
        let totalStart = DispatchTime.now().uptimeNanoseconds
        let loadStart = totalStart
        let outcome = io.load()
        var state = outcome.state ?? GameState.newGame()
        let loadedAt = DispatchTime.now().uptimeNanoseconds

        state.meta.launchCount += 1
        state.base.seatEveryoneFound(in: state.reality.library)
        state.base.learnEveryStarterWord()
        state.meta.mutationCount += 1
        state.meta.lastAction = "launch"
        state.meta.lastSavedAt = Date()

        if state.worlds.activeRun == nil {
            let floor = EconomyRules.minimumBindCost(in: state)
            if EconomyRules.spendableEssence(in: state) < floor {
                state.base.essence += max(0, floor - EconomyRules.spendableEssence(in: state))
                state.meta.mutationCount += 1
                state.meta.lastAction = "the spring provides"
                state.meta.lastSavedAt = Date()
            }
        }
        let reconciledAt = DispatchTime.now().uptimeNanoseconds

        do {
            let committedData = try SaveCodec.encode(state)
            try io.write(committedData)
            // Publish the same normalized representation a future process will decode.
            // Several tolerant save fields intentionally omit default dictionary entries.
            state = try SaveCodec.decode(committedData)
        }
        catch {
            Logger.persistence.error("Launch commitment failed: \(String(describing: error))")
            throw error
        }
        let persistedAt = DispatchTime.now().uptimeNanoseconds
        func milliseconds(_ start: UInt64, _ end: UInt64) -> Double {
            Double(end - start) / 1_000_000
        }
        return PreparedLaunch(
            state: state,
            loadOutcome: outcome.description,
            saveFileByteCount: io.saveFileByteCount,
            timings: .init(loadMilliseconds: milliseconds(loadStart, loadedAt),
                           reconciliationMilliseconds: milliseconds(loadedAt, reconciledAt),
                           persistenceMilliseconds: milliseconds(reconciledAt, persistedAt),
                           totalMilliseconds: milliseconds(totalStart, persistedAt))
        )
    }

    static func live() -> GameStore { GameStore(io: .documents) }

    // MARK: - Mutation

    /// The one way to change game state.
    ///
    /// - Parameters:
    ///   - label: short description, stored in the save. A resumed game can then say what the
    ///     player was last doing — and the kill-test can prove which action survived.
    ///   - flush: `true` for commitment points (binding a book, entering/resolving an encounter,
    ///     banking a haul) where losing even the debounce window would be a real loss.
    func mutate(_ label: String, flush: Bool = false, _ body: (inout GameState) -> Void) {
        body(&state)
        state.meta.mutationCount += 1
        state.meta.lastAction = label
        state.meta.lastSavedAt = Date() // diagnostics only — no gameplay rule may read this

        if flush {
            flushNow()
        } else {
            scheduleSave()
        }
    }

    /// Cancels any pending debounce and writes now, blocking until the bytes are handed to the
    /// filesystem. Called on every scene-phase change out of `.active`.
    func flushNow() {
        debounceTask?.cancel()
        debounceTask = nil
        performWrite(synchronously: true)
    }

    private func scheduleSave() {
        diagnostics.hasPendingWrite = true
        debounceTask?.cancel()
        debounceTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(Tuning.saveDebounceMilliseconds))
            guard !Task.isCancelled, let self else { return }
            self.performWrite(synchronously: false)
        }
    }

    private func performWrite(synchronously: Bool) {
        let snapshot = state
        let data: Data
        do {
            data = try SaveCodec.encode(snapshot)
        } catch {
            diagnostics.lastError = "encode failed: \(error)"
            Logger.persistence.error("Encode failed: \(String(describing: error))")
            return
        }

        let io = self.io
        if synchronously {
            let result = writeQueue.sync { Result { try io.write(data) } }
            recordWriteResult(result, mutationCount: snapshot.meta.mutationCount)
        } else {
            writeQueue.async { [weak self] in
                let result = Result { try io.write(data) }
                Task { @MainActor [weak self] in
                    self?.recordWriteResult(result, mutationCount: snapshot.meta.mutationCount)
                }
            }
        }
    }

    private func recordWriteResult(_ result: Result<Void, Error>, mutationCount: Int) {
        switch result {
        case .success:
            // Guard against an out-of-order report from a slower earlier write.
            diagnostics.savedMutationCount = max(diagnostics.savedMutationCount, mutationCount)
            diagnostics.writeCount += 1
            diagnostics.lastError = nil
        case .failure(let error):
            diagnostics.lastError = "write failed: \(error)"
            Logger.persistence.error("Write failed: \(String(describing: error))")
        }
        diagnostics.hasPendingWrite = state.meta.mutationCount > diagnostics.savedMutationCount
        diagnostics.saveFileByteCount = io.saveFileByteCount
    }

    // MARK: - Whole-save operations

    /// Wipes everything and starts over. Harness/debug only — there is no player-facing new game
    /// in v0.
    func resetEverything() {
        debounceTask?.cancel()
        io.deleteEverything()
        state = GameState.newGame()
        diagnostics = SaveDiagnostics(loadOutcome: "reset", savedMutationCount: 0, saveURL: io.saveURL)
        mutate("reset save", flush: true) { _ in }
    }

    /// The future "reset base, keep reality" operation, proven possible from milestone 1.
    ///
    /// It exists to keep the three-layer separation honest: if this ever stops compiling as three
    /// lines, the layers have leaked into each other. WHAT triggers it and what the payoff is are
    /// open design questions (open-questions.md Q-C) — this is the mechanism only, not the rule.
    func resetBaseKeepingReality() {
        mutate("reset base, keep reality", flush: true) { state in
            state.base = BaseState.newGame()
            state.worlds = WorldsState.newGame(seeds: &state.worlds.seeds)
        }
    }
}

/// Everything the harness needs to show that persistence is behaving.
struct SaveDiagnostics {
    var loadOutcome: String
    /// `meta.mutationCount` as of the last successful write. When this equals the in-memory
    /// count, the disk is fully caught up.
    var savedMutationCount: Int
    var saveURL: URL
    var saveFileByteCount: Int?
    var hasPendingWrite: Bool = false
    var writeCount: Int = 0
    var lastError: String?
}
