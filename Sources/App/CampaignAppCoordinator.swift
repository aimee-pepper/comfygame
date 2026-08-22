import Foundation
import OSLog
import SwiftUI

/// Owns campaign selection separately from an active GameStore. No slot is opened or rewritten
/// merely to draw the chooser; a writer lease begins only after an explicit Continue/Load/New tap.
@MainActor
final class CampaignAppCoordinator: ObservableObject {
    enum LoadingPhase: Equatable, Sendable {
        case adoptingLegacy
        case inspectingCampaigns(completed: Int, total: Int)
        case selectingCampaign
        case acquiringWriter
        case preparing(GameStore.PreparationStep)
        case ready

        var progress: LaunchProgressState {
            switch self {
            case .inspectingCampaigns(let completed, let total) where total > 0:
                .measured(completed: completed, total: total)
            case .ready, .preparing(.complete):
                .complete
            default:
                .activity
            }
        }

        /// Orders callbacks within one operation without pretending that unlike operations are
        /// equal-sized pieces of a percentage.
        var sequence: Int {
            switch self {
            case .adoptingLegacy: 0
            case .inspectingCampaigns: 1
            case .selectingCampaign: 0
            case .acquiringWriter: 1
            case .preparing(let step): 2 + step.rawValue
            case .ready: 6
            }
        }

        var accessibilityDescription: String {
            switch self {
            case .adoptingLegacy: "Checking existing campaigns"
            case .inspectingCampaigns(let completed, let total):
                if total <= 0 { "Reading campaign shelf" }
                else if completed <= 0 { "Reading 0 of \(total) campaigns" }
                else { "Read \(min(completed, total)) of \(total) campaigns" }
            case .selectingCampaign: "Opening selected campaign"
            case .acquiringWriter: "Securing selected campaign"
            case .preparing(let step): step.accessibilityDescription
            case .ready: "Ready"
            }
        }
    }

    enum Phase {
        case idle
        case loading
        case choosing([SaveSlotDescriptor])
        case opening
        case playing(GameStore)
        case failed(String)
    }

    @Published private(set) var phase: Phase
    @Published private(set) var loadingPhase: LoadingPhase = .adoptingLegacy
    @Published var exportFile: CampaignExportFile?

    private let slots: SaveSlotFileIO
    private var task: Task<Void, Never>?
    private var generation = UUID()
    private var didLogFirstFrame = false
    private let minimumInitialDisplay: Duration
    private let prepare: @Sendable (
        any GamePersistenceIO,
        @escaping @Sendable (GameStore.PreparationStep) -> Void
    ) async throws -> GameStore.PreparedLaunch

    var store: GameStore? {
        if case .playing(let store) = phase { return store }
        return nil
    }

    init(directory: URL = FileManager.default.urls(for: .documentDirectory,
                                                    in: .userDomainMask)[0],
         readyStore: GameStore? = nil,
         minimumInitialDisplay: Duration = .seconds(1),
         prepare: @escaping @Sendable (
             any GamePersistenceIO,
             @escaping @Sendable (GameStore.PreparationStep) -> Void
         ) async throws -> GameStore.PreparedLaunch = { io, progress in
             try await Task.detached(priority: .userInitiated) {
                 try GameStore.prepareLaunch(io: io, progress: progress)
             }.value
         }) {
        slots = SaveSlotFileIO(directory: directory)
        phase = readyStore.map(Phase.playing) ?? .idle
        self.minimumInitialDisplay = minimumInitialDisplay
        self.prepare = prepare
    }

    func start() {
        guard case .idle = phase, task == nil else { return }
        loadingPhase = .adoptingLegacy
        phase = .loading
        logPhase(.adoptingLegacy)
        let token = UUID(); generation = token
        task = Task { [weak self] in
            guard let self else { return }
            do {
                let clock = ContinuousClock()
                let earliestChooser = clock.now.advanced(by: minimumInitialDisplay)
                let startedAt = DispatchTime.now().uptimeNanoseconds
                _ = try await slots.adoptLegacyIfNeeded()
                let adoptedAt = DispatchTime.now().uptimeNanoseconds
                guard generation == token else { return }
                publish(.inspectingCampaigns(completed: 0, total: 0), for: token)
                let (updates, continuation) = AsyncStream<(Int, Int)>.makeStream()
                let progressTask = Task { [weak self] in
                    for await (completed, total) in updates {
                        self?.publish(.inspectingCampaigns(completed: completed, total: total),
                                      for: token)
                    }
                }
                let descriptors = await slots.inspect { completed, total in
                    continuation.yield((completed, total))
                }
                continuation.finish()
                await progressTask.value
                let inspectedAt = DispatchTime.now().uptimeNanoseconds
                publish(.ready, for: token)
                let remaining = clock.now.duration(to: earliestChooser)
                if remaining > .zero { try await Task.sleep(for: remaining) }
                guard generation == token else { return }
                phase = .choosing(descriptors)
#if DEBUG
                let adoption = Double(adoptedAt - startedAt) / 1_000_000
                let inspection = Double(inspectedAt - adoptedAt) / 1_000_000
                Logger.launch.notice(
                    "campaign shelf ready elapsed=\(LaunchClock.elapsedMilliseconds(), format: .fixed(precision: 1))ms adopt=\(adoption, format: .fixed(precision: 1))ms inspect=\(inspection, format: .fixed(precision: 1))ms total=\(adoption + inspection, format: .fixed(precision: 1))ms slots=\(descriptors.count)"
                )
#endif
            } catch {
                guard generation == token else { return }
                phase = .failed("Campaigns could not be inspected: \(error.localizedDescription)")
            }
            task = nil
        }
    }

    func open(_ rawID: UUID) { open(SaveSlotID(rawValue: rawID), creatingName: nil) }

    func createCampaign() {
        guard case .choosing(let descriptors) = phase else { return }
        let occupied = Set(descriptors.compactMap { $0.metadata?.name })
        var number = descriptors.count + 1
        while occupied.contains("Campaign \(number)") { number += 1 }
        open(nil, creatingName: "Campaign \(number)")
    }

    func delete(_ rawID: UUID) {
        guard case .choosing(let descriptors) = phase,
              let descriptor = descriptors.first(where: { $0.id.rawValue == rawID }),
              task == nil else { return }
        let name = descriptor.metadata?.name ?? "Damaged campaign \(descriptor.id.description.prefix(8))"
        let token = UUID(); generation = token
        task = Task { [weak self] in
            guard let self else { return }
            do {
                try await slots.delete(descriptor.id, confirmingName: name,
                                       flushingActiveState: nil)
                guard generation == token else { return }
                phase = .choosing(await slots.inspect())
            } catch {
                guard generation == token else { return }
                phase = .failed("“\(name)” could not be deleted: \(error.localizedDescription)")
            }
            task = nil
        }
    }

    func export(_ rawID: UUID) {
        guard task == nil else { return }
        let id = SaveSlotID(rawValue: rawID)
        task = Task { [weak self] in
            guard let self else { return }
            do { exportFile = CampaignExportFile(url: try await slots.exportURL(for: id)) }
            catch { phase = .failed("That campaign could not be exported: \(error.localizedDescription)") }
            task = nil
        }
    }

    func retryCatalogue() {
        guard task == nil else { return }
        phase = .idle
        start()
    }

    /// Flushes the active autosave, retires its write capability, then returns to the chooser.
    func returnToCampaigns() {
        guard case .playing(let store) = phase, task == nil else { return }
        store.flushNow()
        let finalState = store.state
        loadingPhase = .inspectingCampaigns(completed: 0, total: 0)
        phase = .loading
        let token = UUID(); generation = token
        task = Task { [weak self] in
            guard let self else { return }
            do {
                _ = try await slots.releaseWriterLease(flushing: finalState)
                guard generation == token else { return }
                phase = .choosing(await slots.inspect())
            } catch {
                guard generation == token else { return }
                phase = .failed("The active campaign could not be closed safely: \(error.localizedDescription)")
            }
            task = nil
        }
    }

    private func open(_ id: SaveSlotID?, creatingName: String?) {
        guard case .choosing = phase, task == nil else { return }
        loadingPhase = .selectingCampaign
        phase = .opening
        logPhase(.selectingCampaign)
        let openingStartedAt = DispatchTime.now().uptimeNanoseconds
        let token = UUID(); generation = token
        task = Task { [weak self] in
            guard let self else { return }
            do {
                let selected: SaveSlotID
                if let id {
                    _ = try await slots.switchTo(id, flushingActiveState: nil)
                    selected = id
                } else {
                    selected = try await slots.create(name: creatingName ?? "New campaign").metadata.id
                }
                guard generation == token else { return }
                publish(.acquiringWriter, for: token)
                _ = try await slots.acquireWriterLease(for: selected)
                let io = try await slots.payloadIOForLeasedSlot()
                let (steps, continuation) = AsyncStream<GameStore.PreparationStep>.makeStream()
                let progressTask = Task { [weak self] in
                    for await step in steps {
                        self?.publish(.preparing(step), for: token)
                    }
                }
                let prepared: GameStore.PreparedLaunch
                do {
                    prepared = try await prepare(io) { continuation.yield($0) }
                    continuation.finish()
                    await progressTask.value
                } catch {
                    continuation.finish()
                    await progressTask.value
                    throw error
                }
                guard generation == token else {
                    await slots.releaseWriterLeaseWithoutSaving()
                    return
                }
                publish(.preparing(.complete), for: token)
                phase = .playing(GameStore(io: io, prepared: prepared))
#if DEBUG
                Logger.launch.notice(
                    "campaign open elapsed=\(LaunchClock.elapsedMilliseconds(), format: .fixed(precision: 1))ms operation=\(Self.milliseconds(since: openingStartedAt), format: .fixed(precision: 1))ms prepare=\(prepared.timings.totalMilliseconds, format: .fixed(precision: 1))ms load=\(prepared.timings.loadMilliseconds, format: .fixed(precision: 1))ms reconcile=\(prepared.timings.reconciliationMilliseconds, format: .fixed(precision: 1))ms persist=\(prepared.timings.persistenceMilliseconds, format: .fixed(precision: 1))ms"
                )
#endif
            } catch {
                await slots.releaseWriterLeaseWithoutSaving()
                guard generation == token else { return }
                phase = .failed("That campaign could not be opened: \(error.localizedDescription)")
            }
            task = nil
        }
    }

    private func publish(_ next: LoadingPhase, for token: UUID) {
        guard generation == token else { return }
        // Detached persistence callbacks can arrive after the completion continuation. Never let
        // a late callback move the visible bar backwards or overwrite a newer operation.
        guard next.sequence >= loadingPhase.sequence else { return }
        loadingPhase = next
        logPhase(next)
    }

    func noteFirstMeaningfulFrame() {
        guard !didLogFirstFrame else { return }
        didLogFirstFrame = true
#if DEBUG
        DispatchQueue.main.async {
            Logger.launch.notice(
                "campaign first meaningful frame=\(LaunchClock.elapsedMilliseconds(), format: .fixed(precision: 1))ms"
            )
        }
#endif
    }

    private func logPhase(_ phase: LoadingPhase) {
#if DEBUG
        Logger.launch.notice(
            "campaign phase=\(phase.accessibilityDescription, privacy: .public) progress=\(String(describing: phase.progress), privacy: .public) elapsed=\(LaunchClock.elapsedMilliseconds(), format: .fixed(precision: 1))ms"
        )
#endif
    }

    nonisolated private static func milliseconds(since start: UInt64) -> Double {
        let now = DispatchTime.now().uptimeNanoseconds
        return Double(now >= start ? now - start : 0) / 1_000_000
    }
}

struct CampaignExportFile: Identifiable {
    let url: URL
    var id: URL { url }
}

struct CampaignAppRootView: View {
    @ObservedObject var coordinator: CampaignAppCoordinator

    var body: some View {
        Group {
            switch coordinator.phase {
            case .idle, .loading, .opening:
                LaunchSurface(progress: coordinator.loadingPhase.progress,
                              progressDescription: coordinator.loadingPhase.accessibilityDescription)
                    .onAppear {
                        coordinator.noteFirstMeaningfulFrame()
                        // Commit the branded SwiftUI surface before campaign file work begins.
                        // `start()` is idempotent, so repeated appearances remain safe.
                        DispatchQueue.main.async { coordinator.start() }
                    }
            case .choosing(let descriptors):
                CampaignStartView(
                    presentation: CampaignStartPresentation(
                        slots: descriptors.map(CampaignSlotSummary.init(descriptor:))),
                    onContinue: coordinator.open,
                    onNewGame: coordinator.createCampaign,
                    onLoad: coordinator.open,
                    onDelete: coordinator.delete,
                    onExport: coordinator.export
                )
            case .playing(let store):
                RootView()
                    .environmentObject(store)
                    .environmentObject(coordinator)
            case .failed(let message):
                VStack(spacing: 16) {
                    Text("Bookbinder could not finish loading.").font(.title2.bold())
                    Text(message).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    Button("Try again", action: coordinator.retryCatalogue)
                        .buttonStyle(.borderedProminent)
                }
                .padding(24)
            }
        }
        .sheet(item: $coordinator.exportFile) { file in
            NavigationStack {
                VStack(spacing: 18) {
                    Text("Campaign recovery file").font(.headline)
                    Text("Share this unchanged file for recovery. Exporting does not alter the campaign.")
                        .foregroundStyle(.secondary).multilineTextAlignment(.center)
                    ShareLink(item: file.url) { Label("Share campaign", systemImage: "square.and.arrow.up") }
                        .buttonStyle(.borderedProminent)
                }
                .padding(24)
                .toolbar { ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { coordinator.exportFile = nil }
                } }
            }
            .presentationDetents([.medium])
        }
    }
}
