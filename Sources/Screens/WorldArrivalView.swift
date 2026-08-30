import SwiftUI

#if DEBUG
@MainActor enum WorldDestinationPreparationMeasurement {
    static var startedKeys: [WorldDestinationPreparationCoordinator.Key] = []
    static var readyKeys: [WorldDestinationPreparationCoordinator.Key] = []
    static var failedKeys: [WorldDestinationPreparationCoordinator.Key] = []
    static func reset() { startedKeys = []; readyKeys = []; failedKeys = [] }
}
#endif

@MainActor final class WorldDestinationPreparationCoordinator: ObservableObject {
    struct Key: Equatable {
        let receiptID: WorldArrivalReceiptID
        let runIndex: Int
        let mapSeed: UInt64
        let contentFingerprintSHA256: String

        init(receiptID: WorldArrivalReceiptID, runIndex: Int, mapSeed: UInt64,
             contentFingerprintSHA256: String = "") {
            self.receiptID = receiptID
            self.runIndex = runIndex
            self.mapSeed = mapSeed
            self.contentFingerprintSHA256 = contentFingerprintSHA256
        }
    }
    enum Phase: Equatable {
        case presenting(Key), preparingDestination(Key), readyToEnter(Key)
        case transitioning(Key), preparationFailed(Key)
    }
    enum Event: Equatable {
        case presented(Key), destinationPreparationStarted(Key)
        case destinationReady(Key), destinationPreparationFailed(Key)
        case transitionStarted(Key), transitionCompleted(Key)
        case transitionRefused(Key)
    }

    @Published private(set) var phase: Phase
    @Published private(set) var events: [Event]
    private(set) var startedPreparationCount = 0
    private var generation: UInt64 = 0
    private var preparationTask: Task<Bool, Never>?

    init(key: Key) {
        phase = .presenting(key)
        events = [.presented(key)]
    }

    func prepare(key: Key, retry: Bool,
                 operation: @escaping @MainActor () async -> Bool) async -> Bool {
        if phase == .readyToEnter(key) { return true }
        if phase == .preparationFailed(key), !retry { return false }
        if phase == .preparingDestination(key), let preparationTask {
            return await preparationTask.value
        }

        cancel()
        generation &+= 1
        let ownedGeneration = generation
        startedPreparationCount += 1
        phase = .preparingDestination(key)
        events.append(.destinationPreparationStarted(key))
#if DEBUG
        WorldDestinationPreparationMeasurement.startedKeys.append(key)
#endif
        let task = Task { @MainActor in await operation() }
        preparationTask = task
        let succeeded = await task.value
        guard generation == ownedGeneration else { return false }
        preparationTask = nil
        phase = succeeded ? .readyToEnter(key) : .preparationFailed(key)
        events.append(succeeded ? .destinationReady(key) : .destinationPreparationFailed(key))
#if DEBUG
        if succeeded {
            WorldDestinationPreparationMeasurement.readyKeys.append(key)
        } else {
            WorldDestinationPreparationMeasurement.failedKeys.append(key)
        }
#endif
        return succeeded
    }

    func beginTransition(key: Key) -> Bool {
        guard phase == .readyToEnter(key) else { return false }
        phase = .transitioning(key)
        events.append(.transitionStarted(key))
        return true
    }

    func completeWorldSplashTransition(
        receiptID: WorldArrivalReceiptID, runIndex: Int, mapSeed: UInt64,
        contentFingerprintSHA256: String = "",
        destinationStillReady: () -> Bool, commit: () -> Bool
    ) -> Bool {
        let key = Key(receiptID: receiptID, runIndex: runIndex, mapSeed: mapSeed,
                      contentFingerprintSHA256: contentFingerprintSHA256)
        guard phase == .transitioning(key), destinationStillReady(), commit() else {
            events.append(.transitionRefused(key))
            return false
        }
        events.append(.transitionCompleted(key))
        return true
    }

    func cancel(key: Key? = nil) {
        if let key {
            guard phase == .preparingDestination(key) || phase == .readyToEnter(key)
                    || phase == .preparationFailed(key) || phase == .transitioning(key)
                    || phase == .presenting(key)
            else { return }
        }
        generation &+= 1
        preparationTask?.cancel()
        preparationTask = nil
        if let key { phase = .presenting(key) }
    }
}

struct WorldArrivalLayout: Equatable {
    static let enterHeight: CGFloat = 58
    static let enterBottomInset: CGFloat = 14
    let sideInset: CGFloat
    let sceneWidth: CGFloat

    static func enterFrame(height: CGFloat) -> ClosedRange<CGFloat> {
        (height - enterBottomInset - enterHeight)...(height - enterBottomInset)
    }

    static func metrics(width: CGFloat) -> Self {
        let inset: CGFloat = width >= 368 ? 24 : 12
        let sceneWidth = min(320, width - inset * 2)
        return .init(sideInset: inset, sceneWidth: sceneWidth)
    }
}

struct WorldArrivalView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.displayScale) private var displayScale
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var destinationPreparation: WorldDestinationPreparationCoordinator
    let presentation: WorldSplashNativePresentationV1

    init(presentation: WorldSplashNativePresentationV1) {
        self.presentation = presentation
        let identity = presentation.identity
        _destinationPreparation = StateObject(wrappedValue:
            WorldDestinationPreparationCoordinator(key: .init(
                receiptID: identity.receiptID, runIndex: identity.runIndex,
                mapSeed: identity.mapSeed,
                contentFingerprintSHA256: identity.contentFingerprintSHA256)))
    }

    init(receipt: WorldArrivalReceipt) {
        guard let presentation = WorldSplashNativePresentationV1.make(receipt: receipt) else {
            preconditionFailure("WorldArrivalView requires a validated native Splash projection")
        }
        self.init(presentation: presentation)
    }

    private var preparationKey: WorldDestinationPreparationCoordinator.Key? {
        guard let run = store.activeRun,
              store.state.worlds.pendingWorldSplashPresentation == presentation else { return nil }
        return .init(receiptID: presentation.identity.receiptID,
                     runIndex: run.runIndex, mapSeed: run.mapSeed,
                     contentFingerprintSHA256: presentation.identity.contentFingerprintSHA256)
    }

    @MainActor private func prepareDestination(containerSize: CGSize, retry: Bool) async -> Bool {
        guard let key = preparationKey, let run = store.activeRun else { return false }
        let state = store.state
        let request = WorldDestinationPreloader.request(
            run: run, state: state, containerSize: containerSize,
            displayScale: displayScale,
            presentationTick: TerrainPresentationClock.shared.tick,
            reduceMotion: reduceMotion)
        return await destinationPreparation.prepare(key: key, retry: retry) {
            await WorldDestinationPreloader.prepare(request: request)
        }
    }

    private func sceneImage(size: CGSize) -> UIImage? {
        switch presentation.contentKind {
        case .comprehensiveV3(let splash, _):
            WorldArrivalNativeRenderer.placeholderImage(for: splash, size: size)
        case .validatedV2(_, let rendered): WorldArrivalNativeRenderer.image(for: rendered)
        }
    }
    private var disclosedMarkLabels: [String] {
        presentation.sourcePage.marks.map {
            $0.isReadable && !$0.visibleLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? $0.visibleLabel : "??"
        }
    }

    var body: some View {
        GeometryReader { proxy in
            let metrics = WorldArrivalLayout.metrics(width: proxy.size.width)
            let mountedHeight = proxy.size.height - proxy.safeAreaInsets.top
                - proxy.safeAreaInsets.bottom
            let decisionHeight = max(200, mountedHeight - WorldArrivalLayout.enterHeight
                - WorldArrivalLayout.enterBottomInset - proxy.frame(in: .global).minY)
            VStack(spacing: 0) {
                ScrollView {
                    arrivalContent(sceneWidth: metrics.sceneWidth)
                        .padding(.horizontal, metrics.sideInset)
                        .padding(.top, 18)
                        .padding(.bottom, 18)
                }
                .frame(maxWidth: .infinity)
                .frame(height: decisionHeight)

                if case .preparationFailed = destinationPreparation.phase {
                    Text("World preparation failed. Try Enter World again.")
                        .foregroundStyle(PixelUITheme.text)
                        .padding(.horizontal, metrics.sideInset)
                        .padding(.bottom, 8)
                }

                Button("Enter World") {
                    Task { @MainActor in
                        guard await prepareDestination(containerSize: proxy.size, retry: true),
                              let key = preparationKey,
                              destinationPreparation.beginTransition(key: key) else { return }
                        _ = completeWorldSplashTransition(
                            receiptID: key.receiptID, runIndex: key.runIndex,
                            mapSeed: key.mapSeed,
                            contentFingerprintSHA256: key.contentFingerprintSHA256)
                    }
                }
                .font(.custom("Tiny5", size: 15, relativeTo: .headline))
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .frame(height: WorldArrivalLayout.enterHeight)
                .background(PixelUITheme.primary)
                .overlay(Rectangle().stroke(PixelUITheme.edgeDark, lineWidth: 3))
                .buttonStyle(.plain)
                .accessibilityIdentifier("world-arrival.enter")
                .padding(.horizontal, metrics.sideInset)
                .padding(.bottom, WorldArrivalLayout.enterBottomInset)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(PixelUITheme.screen.ignoresSafeArea())
            .task(id: presentation.identity.contentFingerprintSHA256) {
                _ = await prepareDestination(containerSize: proxy.size, retry: false)
            }
        }
#if DEBUG
        .preference(key: DebugBugReporterSuppressedPreferenceKey.self, value: true)
#endif
        .onDisappear {
            guard store.state.worlds.pendingWorldArrivalReceiptID == presentation.identity.receiptID,
                  let key = preparationKey else { return }
            destinationPreparation.cancel(key: key)
        }
    }

    @MainActor private func completeWorldSplashTransition(
        receiptID: WorldArrivalReceiptID, runIndex: Int, mapSeed: UInt64,
        contentFingerprintSHA256: String
    ) -> Bool {
        destinationPreparation.completeWorldSplashTransition(
            receiptID: receiptID, runIndex: runIndex, mapSeed: mapSeed,
            contentFingerprintSHA256: contentFingerprintSHA256,
            destinationStillReady: {
                store.state.worlds.pendingWorldSplashPresentation?.identity
                    == presentation.identity
                    && destinationPreparation.phase == .transitioning(.init(
                        receiptID: receiptID, runIndex: runIndex, mapSeed: mapSeed,
                        contentFingerprintSHA256: contentFingerprintSHA256))
            }, commit: {
                store.enterPendingWorld(presentation: presentation)
            })
    }

    @ViewBuilder
    private func arrivalContent(sceneWidth: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 14) {
                    Text(presentation.title)
                        .font(.custom("Tiny5", size: 25, relativeTo: .title))
                        .foregroundStyle(PixelUITheme.text)
                        .fixedSize(horizontal: false, vertical: true)

                    Group {
                        let targetSize = CGSize(width: max(320, sceneWidth), height: 360)
                        if let sceneImage = sceneImage(size: targetSize) {
                            Image(uiImage: sceneImage)
                                .resizable()
                                .interpolation(.none)
                                .frame(width: sceneWidth, height: 360)
                        } else { EmptyView() }
                    }
                    .frame(width: sceneWidth, height: 360)
                    .overlay(Rectangle().stroke(PixelUITheme.edgeDark, lineWidth: 3))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Generated view of \(presentation.sourcePage.title)")

                    Text(presentation.finalDescription)
                        .font(.custom("Tiny5", size: 13, relativeTo: .body))
                        .foregroundStyle(PixelUITheme.text)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 12) {
                        WorldArrivalPageThumbnail(page: presentation.sourcePage)
                            .frame(width: 54, height: 54)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("WRITTEN FROM")
                                .font(.custom("Tiny5", size: 9, relativeTo: .caption2))
                                .foregroundStyle(PixelUITheme.muted)
                            Text(presentation.sourcePage.title)
                                .font(.custom("Tiny5", size: 12, relativeTo: .callout))
                                .foregroundStyle(PixelUITheme.text)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(disclosedMarkLabels.joined(separator: " · "))
                                .font(.custom("Tiny5", size: 10, relativeTo: .caption))
                                .foregroundStyle(PixelUITheme.muted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Written from \(presentation.sourcePage.title). \(disclosedMarkLabels.joined(separator: ", "))")
        }
    }
}

private struct WorldArrivalPageThumbnail: View {
    let page: WorldArrivalReceipt.SourcePage

    var body: some View {
        Canvas { context, size in
            let cell = floor(min(size.width / CGFloat(max(1, page.width)),
                                 size.height / CGFloat(max(1, page.height))))
            let insetX = floor((size.width - cell * CGFloat(page.width)) / 2)
            let insetY = floor((size.height - cell * CGFloat(page.height)) / 2)
            context.fill(Path(CGRect(origin: .zero, size: size)),
                         with: .color(PixelUITheme.surfaceInset))
            for mark in page.marks {
                let color = mark.isReadable ? PixelUITheme.text : PixelUITheme.muted
                for occupied in mark.cells {
                    let rect = CGRect(x: insetX + CGFloat(occupied.column) * cell,
                                      y: insetY + CGFloat(occupied.row) * cell,
                                      width: max(1, cell - 1), height: max(1, cell - 1))
                    context.fill(Path(rect), with: .color(color))
                }
            }
        }
        .overlay(Rectangle().stroke(PixelUITheme.edgeDark, lineWidth: 2))
        .accessibilityHidden(true)
    }
}
