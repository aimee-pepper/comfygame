import Combine
import Foundation
import XCTest
@testable import Bookbinder

@MainActor
final class CampaignLaunchProgressTests: XCTestCase {
    private actor AttemptCounter {
        var value = 0
        func next() -> Int { value += 1; return value }
    }

    func testInitialInspectionPublishesHonestProgressBeforeChooser() async throws {
        let directory = temporaryDirectory("initial")
        let coordinator = CampaignAppCoordinator(directory: directory, minimumInitialDisplay: .zero)
        var observed: [CampaignAppCoordinator.LoadingPhase] = []
        let observation = coordinator.$loadingPhase.sink { observed.append($0) }

        coordinator.start()
        try await waitUntil { if case .choosing = coordinator.phase { true } else { false } }
        _ = observation

        XCTAssertTrue(observed.contains(.adoptingLegacy))
        XCTAssertTrue(observed.contains(.inspectingCampaigns))
        XCTAssertEqual(coordinator.loadingPhase.accessibilityDescription, "Reading campaign shelf")
    }

    func testOpeningPublishesEveryOrderedPreparationStepAndLiveDescriptions() async throws {
        let directory = temporaryDirectory("opening")
        let slot = try await SaveSlotFileIO(directory: directory).create(name: "Progress")
        let prepared = fixturePrepared()
        let coordinator = CampaignAppCoordinator(directory: directory, minimumInitialDisplay: .zero, prepare: { _, progress in
            progress(.loadingSave)
            progress(.reconcilingCatalogue)
            progress(.committingSave)
            progress(.complete)
            return prepared
        })
        coordinator.start()
        try await waitUntil { if case .choosing = coordinator.phase { true } else { false } }

        var observed: [CampaignAppCoordinator.LoadingPhase] = []
        let observation = coordinator.$loadingPhase.sink { observed.append($0) }
        coordinator.open(slot.metadata.id.rawValue)
        try await waitUntil { coordinator.store != nil }
        _ = observation

        XCTAssertEqual(consecutiveUnique(observed), [
            .inspectingCampaigns, .selectingCampaign, .acquiringWriter,
            .preparing(.loadingSave), .preparing(.reconcilingCatalogue),
            .preparing(.committingSave), .preparing(.complete)
        ])
        XCTAssertEqual(coordinator.loadingPhase.completedFraction, 1)
        XCTAssertEqual(coordinator.loadingPhase.accessibilityDescription, "Ready")
    }

    func testLateAndReorderedCallbacksCannotRegressCompletedOrNewGeneration() async throws {
        let directory = temporaryDirectory("stale")
        let slot = try await SaveSlotFileIO(directory: directory).create(name: "Stale")
        let prepared = fixturePrepared()
        let coordinator = CampaignAppCoordinator(directory: directory, minimumInitialDisplay: .zero, prepare: { _, progress in
            progress(.loadingSave)
            progress(.complete)
            progress(.reconcilingCatalogue) // deliberately out of order
            Task {
                try? await Task.sleep(for: .milliseconds(40))
                progress(.committingSave) // deliberately after completion/return
            }
            return prepared
        })
        coordinator.start()
        try await waitUntil { if case .choosing = coordinator.phase { true } else { false } }
        coordinator.open(slot.metadata.id.rawValue)
        try await waitUntil { coordinator.store != nil }
        XCTAssertEqual(coordinator.loadingPhase, .preparing(.complete))

        coordinator.returnToCampaigns()
        try await waitUntil { if case .choosing = coordinator.phase { true } else { false } }
        try await Task.sleep(for: .milliseconds(70))
        XCTAssertEqual(coordinator.loadingPhase, .inspectingCampaigns,
                       "A callback from an older generation must not overwrite the chooser")
    }

    func testOpeningFailureCanRetryWithoutPublishingTheFailedAttempt() async throws {
        struct ExpectedFailure: Error {}
        let directory = temporaryDirectory("retry")
        let slot = try await SaveSlotFileIO(directory: directory).create(name: "Retry")
        let attempts = AttemptCounter()
        let prepared = fixturePrepared()
        let coordinator = CampaignAppCoordinator(directory: directory, minimumInitialDisplay: .zero, prepare: { _, progress in
            let attempt = await attempts.next()
            progress(.loadingSave)
            if attempt == 1 { throw ExpectedFailure() }
            progress(.reconcilingCatalogue)
            progress(.committingSave)
            progress(.complete)
            return prepared
        })
        coordinator.start()
        try await waitUntil { if case .choosing = coordinator.phase { true } else { false } }
        coordinator.open(slot.metadata.id.rawValue)
        try await waitUntil { if case .failed = coordinator.phase { true } else { false } }

        coordinator.retryCatalogue()
        try await waitUntil { if case .choosing = coordinator.phase { true } else { false } }
        coordinator.open(slot.metadata.id.rawValue)
        try await waitUntil { coordinator.store != nil }
        XCTAssertEqual(coordinator.loadingPhase, .preparing(.complete))
    }

    func testWarmReadySkipsLoadingAndRootConsumesPublishedProgress() throws {
        let io = SaveFileIO.temporary(name: "campaign-launch-warm-\(UUID().uuidString)")
        let store = GameStore(io: io, prepared: fixturePrepared())
        let coordinator = CampaignAppCoordinator(readyStore: store)
        coordinator.start()
        XCTAssertTrue(coordinator.store === store)

        let source = try String(contentsOf: projectRoot
            .appending(path: "Sources/App/CampaignAppCoordinator.swift"), encoding: .utf8)
        XCTAssertTrue(source.contains("progressFraction: coordinator.loadingPhase.completedFraction"))
        XCTAssertTrue(source.contains("progressDescription: coordinator.loadingPhase.accessibilityDescription"))
        let launchSurface = try String(contentsOf: projectRoot
            .appending(path: "Sources/App/BookbinderApp.swift"), encoding: .utf8)
        XCTAssertTrue(launchSurface.contains(".accessibilityValue(progressDescription)"),
                      "VoiceOver must name the live campaign-loading phase")
        XCTAssertTrue(source.contains("coordinator.noteFirstMeaningfulFrame()"),
                      "The production campaign root must timestamp its actual first frame")
        XCTAssertTrue(source.contains("campaign phase="),
                      "Every published production phase must carry elapsed-time evidence")
    }

    func testInitialSplashRemainsPerceptibleAfterFastInspection() async throws {
        let directory = temporaryDirectory("minimum-display")
        let clock = ContinuousClock()
        let started = clock.now
        let coordinator = CampaignAppCoordinator(
            directory: directory,
            minimumInitialDisplay: .milliseconds(120)
        )

        coordinator.start()
        try await Task.sleep(for: .milliseconds(60))
        if case .choosing = coordinator.phase {
            XCTFail("Fast inspection must not make the branded launch surface flicker away")
        }
        try await waitUntil { if case .choosing = coordinator.phase { true } else { false } }
        XCTAssertGreaterThanOrEqual(started.duration(to: clock.now), .milliseconds(110))
    }

    func testLaunchProgressUsesAReservedFixedRegionInsteadOfSystemIntrinsicLayout() throws {
        let source = try String(contentsOf: projectRoot
            .appending(path: "Sources/App/BookbinderApp.swift"), encoding: .utf8)
        let loadingSurface = try XCTUnwrap(source.range(of: "private var loadingSurface"))
        let failureSurface = try XCTUnwrap(source.range(of: "private func failureSurface"))
        let section = String(source[loadingSurface.lowerBound..<failureSurface.lowerBound])

        XCTAssertTrue(section.contains("LaunchProgressTrack(fraction: progressFraction)"))
        XCTAssertTrue(section.contains(".frame(width: 192, height: 4)"),
                      "The live progress region must match the launch storyboard from frame one")
        XCTAssertFalse(section.contains("ProgressView("),
                       "System progress styling must not introduce different intrinsic geometry")
        XCTAssertTrue(source.contains("geometry.size.width * min(1, max(0, fraction))"),
                      "Progress may change only the fill width inside the reserved region")
    }

    private func fixturePrepared() -> GameStore.PreparedLaunch {
        .init(state: .newGame(), loadOutcome: "fixture", saveFileByteCount: nil,
              timings: .init(loadMilliseconds: 1, reconciliationMilliseconds: 2,
                             persistenceMilliseconds: 3, totalMilliseconds: 6))
    }

    private func temporaryDirectory(_ label: String) -> URL {
        FileManager.default.temporaryDirectory
            .appending(path: "campaign-launch-\(label)-\(UUID().uuidString)", directoryHint: .isDirectory)
    }

    private func consecutiveUnique<T: Equatable>(_ values: [T]) -> [T] {
        values.reduce(into: []) { result, value in
            if result.last != value { result.append(value) }
        }
    }

    private var projectRoot: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
    }

    private func waitUntil(timeout: Duration = .seconds(2),
                           _ condition: @escaping @MainActor () -> Bool) async throws {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: timeout)
        while !condition() {
            if clock.now >= deadline { XCTFail("Timed out waiting for launch state"); return }
            try await Task.sleep(for: .milliseconds(5))
        }
    }
}
