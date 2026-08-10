import SwiftUI
import OSLog
import UIKit

@main
struct BookbinderApp: App {
    @StateObject private var launch = AppLaunchCoordinator()
    @StateObject private var settings = AppSettings()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Force the launch epoch before SwiftUI constructs the first view. Keeping this
        // eager makes the first-frame measurement include coordinator and loading work.
        LaunchClock.begin()
#if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--debug-world") {
            let visualStore = GameStore(io: .temporary(name: "visual-world"))
            visualStore.resetEverything()
            _ = visualStore.bindAndDepart()
            _launch = StateObject(wrappedValue: AppLaunchCoordinator(readyStore: visualStore))
            return
        }
#endif
    }

    var body: some Scene {
        WindowGroup {
            LaunchRootView(coordinator: launch)
                .environmentObject(settings)
                // nil follows the phone; light/dark override it.
                .preferredColorScheme(settings.theme.colorScheme)
        }
        .onChange(of: scenePhase) { _, phase in
            // Leaving .active is the last reliable moment before iOS may suspend or kill us.
            // Write synchronously here rather than trusting the debounce to land.
            if phase != .active { launch.store?.flushNow() }
        }
    }
}

@MainActor
final class AppLaunchCoordinator: ObservableObject {
    struct Failure: Equatable {
        var message: String
        var details: String
        var canRetry: Bool
    }

    enum Phase { case idle, loading, ready(GameStore), failed(Failure) }
    @Published private(set) var phase: Phase
    private var task: Task<Void, Never>?
    private var timeoutTask: Task<Void, Never>?
    private let prepare: @Sendable () async throws -> GameStore.PreparedLaunch
    private let timeout: Duration
    private var attempt = UUID()
    private var didLogFirstFrame = false
    private var firstFrameMilliseconds: Double?

    var store: GameStore? {
        if case .ready(let store) = phase { store } else { nil }
    }

    init(readyStore: GameStore? = nil,
         timeout: Duration = .seconds(12),
         prepare: @escaping @Sendable () async throws -> GameStore.PreparedLaunch = {
#if DEBUG
             if ProcessInfo.processInfo.arguments.contains("--debug-launch-delay") {
                 try await Task.sleep(for: .seconds(8))
             }
#endif
             return try await Task.detached(priority: .userInitiated) {
                 try GameStore.prepareLaunch(io: .documents)
             }.value
         }) {
        self.phase = readyStore.map(Phase.ready) ?? .idle
        self.timeout = timeout
        self.prepare = prepare
    }

    func start() {
        guard case .idle = phase else { return }
        phase = .loading
        let thisAttempt = UUID()
        attempt = thisAttempt
        let timeout = timeout
        timeoutTask = Task { [weak self] in
            try? await Task.sleep(for: timeout)
            guard !Task.isCancelled, let self, self.attempt == thisAttempt,
                  case .loading = self.phase else { return }
            self.phase = .failed(Failure(
                message: "The Atlas is taking longer than expected.",
                details: "Launch preparation exceeded \(timeout). The current save operation is being allowed to finish safely before retry is available.",
                canRetry: false
            ))
        }
        task = Task {
            do {
                let prepared = try await self.prepare()
                guard self.attempt == thisAttempt else { return }
                self.timeoutTask?.cancel()
                let store = GameStore(io: .documents, prepared: prepared)
                phase = .ready(store)
                task = nil
#if DEBUG
                let firstFrame = self.firstFrameMilliseconds ?? -1
                let evidence = "launch ready firstFrame=\(firstFrame.formatted(.number.precision(.fractionLength(1))))ms total=\(prepared.timings.totalMilliseconds.formatted(.number.precision(.fractionLength(1))))ms load=\(prepared.timings.loadMilliseconds.formatted(.number.precision(.fractionLength(1))))ms reconcile=\(prepared.timings.reconciliationMilliseconds.formatted(.number.precision(.fractionLength(1))))ms persist=\(prepared.timings.persistenceMilliseconds.formatted(.number.precision(.fractionLength(1))))ms"
                Logger.launch.notice("\(evidence, privacy: .public)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    Logger.launch.notice("launch evidence \(evidence, privacy: .public)")
                }
#endif
            } catch {
                guard self.attempt == thisAttempt else { return }
                self.timeoutTask?.cancel()
                task = nil
                phase = .failed(Failure(
                    message: "The Atlas could not be opened.",
                    details: error.localizedDescription,
                    canRetry: true
                ))
            }
        }
    }

    func retry() {
        guard task == nil else { return }
        timeoutTask?.cancel()
        phase = .idle
        start()
    }

    func noteFirstMeaningfulFrame() {
        guard !didLogFirstFrame else { return }
        didLogFirstFrame = true
#if DEBUG
        DispatchQueue.main.async {
            let now = DispatchTime.now().uptimeNanoseconds
            let elapsed = LaunchClock.elapsedMilliseconds(at: now)
            self.firstFrameMilliseconds = elapsed
            Logger.launch.notice("first meaningful frame=\(elapsed, format: .fixed(precision: 1))ms")
        }
#endif
    }
}

enum LaunchClock {
    static let startedAt = DispatchTime.now().uptimeNanoseconds
    static func begin() { _ = startedAt }
    static func elapsedMilliseconds(at now: UInt64 = DispatchTime.now().uptimeNanoseconds) -> Double {
        Double(now >= startedAt ? now - startedAt : 0) / 1_000_000
    }
}

private struct LaunchRootView: View {
    @ObservedObject var coordinator: AppLaunchCoordinator

    var body: some View {
        Group {
            switch coordinator.phase {
            case .idle, .loading:
                LaunchSurface()
                    .task { coordinator.start() }
                    .onAppear { coordinator.noteFirstMeaningfulFrame() }
            case .ready(let store):
                RootView().environmentObject(store)
            case .failed(let failure):
                LaunchSurface(failure: failure, retry: coordinator.retry)
            }
        }
    }
}

private struct LaunchSurface: View {
    var failure: AppLaunchCoordinator.Failure?
    var retry: (() -> Void)?

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 18) {
                Rectangle().fill(.secondary).frame(height: 2)
                Spacer(minLength: 0)
                BookbindingMark()
                    .accessibilityHidden(true)
                Text("Bookbinder").font(.system(size: 30, weight: .semibold, design: .serif))
                if let failure {
                    Text(failure.message).multilineTextAlignment(.center).foregroundStyle(.secondary)
                    if failure.canRetry {
                        Button("Try again") { retry?() }.buttonStyle(.borderedProminent)
                    } else {
                        Text("Finishing safely…").font(.caption).foregroundStyle(.secondary)
                    }
                    Button("Copy diagnostics") {
                        UIPasteboard.general.string = failure.details
                    }
                    .buttonStyle(.borderless)
                    .accessibilityHint("Copies technical launch details for support.")
                } else {
                    Text("Opening the Atlas…").foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Rectangle().fill(.secondary).frame(height: 2)
            }
            .padding(18)
            .frame(width: 248, height: 340)
            .background(Color(.secondarySystemBackground))
            .overlay(Rectangle().stroke(.brown.opacity(0.75), lineWidth: 2))
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .accessibilityElement(children: failure == nil ? .combine : .contain)
        .accessibilityLabel(failure == nil ? "Bookbinder. Opening the Atlas." : "Bookbinder. \(failure!.message)")
    }
}

private struct BookbindingMark: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack(alignment: .topLeading) {
            piece(0, 4, 36, 54, edge)
            piece(38, 4, 36, 54, edge)
            piece(4, 8, 32, 46, ink)
            piece(38, 8, 32, 46, ink)
            piece(8, 12, 28, 38, page)
            piece(38, 12, 28, 38, page)
            piece(35, 0, 4, 58, muted)
            piece(0, 54, 32, 4, edge)
            piece(42, 54, 32, 4, edge)
            piece(8, 46, 6, 4, ink)
            piece(60, 50, 6, 4, ink)
        }
        .frame(width: 74, height: 58)
    }

    private var edge: Color { color(colorScheme == .dark ? 0xD8BD82 : 0x8A693A) }
    private var ink: Color { color(colorScheme == .dark ? 0xEEE8DC : 0x211D19) }
    private var page: Color { color(colorScheme == .dark ? 0x2B2721 : 0xFFFAF0) }
    private var muted: Color { color(colorScheme == .dark ? 0xAAA092 : 0x665F56) }

    private func color(_ rgb: Int) -> Color {
        Color(red: Double((rgb >> 16) & 0xff) / 255,
              green: Double((rgb >> 8) & 0xff) / 255,
              blue: Double(rgb & 0xff) / 255)
    }

    private func piece(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat, _ color: Color) -> some View {
        color.frame(width: width, height: height).offset(x: x, y: y)
    }
}

extension Logger {
    static let launch = Logger(subsystem: "com.aimeepepper.bookbinder", category: "launch")
}
