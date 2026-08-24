import SwiftUI
import UIKit

#if DEBUG
@MainActor enum WorldMapStageMeasurement {
    static var latestFrame: CGRect = .zero
    static var latestMapFrame: CGRect = .zero
    static var latestMapWidth: CGFloat = 0
    static var latestViewportRows: Int = 0
}

private struct WorldMapStageProbe: UIViewRepresentable {
    final class ProbeView: UIView {
        override func layoutSubviews() {
            super.layoutSubviews()
            WorldMapStageMeasurement.latestFrame = convert(bounds, to: nil)
        }
    }
    func makeUIView(context: Context) -> ProbeView { ProbeView(frame: .zero) }
    func updateUIView(_ uiView: ProbeView, context: Context) {}
}

private struct WorldMapViewportProbe: UIViewRepresentable {
    let mapWidth: CGFloat
    let viewportRows: Int
    final class ProbeView: UIView {
        var mapWidth: CGFloat = 0
        var viewportRows: Int = 0
        override func layoutSubviews() {
            super.layoutSubviews()
            guard abs((window?.bounds.width ?? 0) - 368) < 0.5 else { return }
            WorldMapStageMeasurement.latestMapFrame = convert(bounds, to: nil)
            WorldMapStageMeasurement.latestMapWidth = mapWidth
            WorldMapStageMeasurement.latestViewportRows = viewportRows
        }
    }
    func makeUIView(context: Context) -> ProbeView {
        let view = ProbeView(frame: .zero)
        view.mapWidth = mapWidth; view.viewportRows = viewportRows
        return view
    }
    func updateUIView(_ uiView: ProbeView, context: Context) {
        uiView.mapWidth = mapWidth; uiView.viewportRows = viewportRows
    }
}
#endif

enum WorldDurationPresentation {
    static func status(stability: Double, decayPerTurn: Double,
                       collapsedOnTurn: Int?) -> String {
        if collapsedOnTurn != nil || stability <= 0 { return "collapse underway" }
        guard decayPerTurn > 0 else { return "steady" }
        let projectedTurns = ceil(stability / decayPerTurn)
        guard projectedTurns < Double(Tuning.World.countdownCeiling) else { return "steady" }
        return "~\(Int(projectedTurns)) turns until collapse"
    }

    static func diagnostic(stability: Double, decayPerTurn: Double,
                           collapsedOnTurn: Int?) -> (label: String, value: String) {
        if collapsedOnTurn != nil || stability <= 0 {
            let phase = collapsedOnTurn.map { "underway · started turn \($0)" } ?? "underway"
            return ("Collapse status", phase)
        }
        guard decayPerTurn > 0 else { return ("Turns until collapse", "steady") }
        let projectedTurns = ceil(stability / decayPerTurn)
        guard projectedTurns < Double(Tuning.World.countdownCeiling) else {
            return ("Turns until collapse", "steady")
        }
        return ("Turns until collapse", "\(Int(projectedTurns))")
    }
}

enum WorldControlsLayout {
    static let actionCount = 2
    static let actionRows = 1
    static let actionHeight: CGFloat = 44
    static let horizontalPadding: CGFloat = 16
    static let actionSpacing: CGFloat = 6
    static let navigationSpacing: CGFloat = 14

    static func actionFrames(containerWidth: CGFloat) -> [CGRect] {
        let usable = max(0, containerWidth - horizontalPadding * 2 - navigationSpacing)
        let navigationColumnWidth = usable / 2
        let width = max(0, navigationColumnWidth - actionSpacing) / 2
        let start = horizontalPadding + navigationColumnWidth + navigationSpacing
        return [
            CGRect(x: start, y: 0, width: width, height: actionHeight),
            CGRect(x: start + width + actionSpacing, y: 0,
                   width: width, height: actionHeight),
        ]
    }
}

/// A closed two-slot strip prevents action growth from silently adding fixed rows and obscuring
/// the scrollable event/satchel content above the controls.
private struct WorldActionRow: View {
    let interact: () -> AnyView
    let look: () -> AnyView

    var body: some View {
        HStack(spacing: 6) {
            interact().frame(maxWidth: .infinity)
            look().frame(maxWidth: .infinity)
        }
        .frame(height: WorldControlsLayout.actionHeight)
    }
}

enum WorldFieldFeedbackLayout {
    /// Exact build-247 place-information footprint: 30 top + 40 content + 8 bottom.
    /// This is an overlay inside the square map stage and therefore reserves no sibling height.
    static let compactHeight: CGFloat = 78
    static let spacing: CGFloat = 4
    static let contextFraction: CGFloat = 0.25
    static let expandedEventMaximumHeight: CGFloat = 260
    static func paneWidths(total: CGFloat) -> (context: CGFloat, event: CGFloat) {
        let usable = max(0, total - spacing)
        let context = floor(usable * contextFraction)
        return (context, max(0, usable - context))
    }
}

enum WorldControlAction: Hashable, Sendable {
    case move(dx: Int, dy: Int)
    case look(dx: Int, dy: Int)
    case useTile
    case travel(GridPoint)
    case fieldKit
    case armLook
}

enum WorldMapPlanningAction {
    static func action(from origin: GridPoint, to destination: GridPoint) -> WorldControlAction {
        WorldRules.isAdjacent(origin, destination)
            ? .move(dx: destination.x - origin.x, dy: destination.y - origin.y)
            : .travel(destination)
    }

    static func route(from origin: GridPoint, to destination: GridPoint,
                      perform: (WorldControlAction) -> Void) {
        perform(action(from: origin, to: destination))
    }
}

enum WorldControlOutcome: Equatable, Sendable {
    case stepped(finalPosition: GridPoint, turnsSpent: Int)
    case blocked(finalPosition: GridPoint, turnsSpent: Int, reason: String)
    case inspected(GridPoint)
    case usedTile(String)
    case travelEnded(finalPosition: GridPoint, turnsSpent: Int, reachedDestination: Bool)
    case openedFieldKit
    case lookArmed(Bool)
    case expeditionEnded
}

enum WorldControlRefusal: Equatable, Sendable {
    case busy
    case stale
    case disabled(String)
    case rules(String)

    var playerCopy: String {
        switch self {
        case .busy: "Finish the current action first."
        case .stale: "That action is no longer available."
        case .disabled(let reason): reason
        case .rules(let reason): reason
        }
    }
}

enum WorldControlExecution: Equatable, Sendable {
    case completed(WorldControlOutcome)
    case refused(WorldControlRefusal)
}

struct WorldControlSnapshot: Equatable, Sendable {
    let mutationCount: Int
    let runIndex: Int?
    let mapSeed: UInt64?
    let turn: Int?
    let position: GridPoint?

    static func make(from state: GameState) -> Self {
        let run = state.worlds.activeRun
        return Self(mutationCount: state.meta.mutationCount, runIndex: run?.runIndex,
                    mapSeed: run?.mapSeed, turn: run?.turnsTaken,
                    position: run?.playerPosition)
    }
}

@MainActor enum WorldControlRulesExecution {
    static func blockedReason(in store: GameStore, fallback: String) -> String {
        for event in store.recentEvents.reversed() {
            if case .blocked(let reason) = event { return reason }
        }
        return fallback
    }

    static func step(store: GameStore, to destination: GridPoint) -> WorldControlExecution {
        let beforeTurn = store.activeRun?.turnsTaken ?? 0
        store.step(to: destination)
        guard let final = store.activeRun else { return .completed(.expeditionEnded) }
        let spent = final.turnsTaken - beforeTurn
        guard final.playerPosition == destination else {
            return .completed(.blocked(finalPosition: final.playerPosition, turnsSpent: spent,
                reason: blockedReason(in: store, fallback: "You cannot move there.")))
        }
        return .completed(.stepped(finalPosition: final.playerPosition, turnsSpent: spent))
    }

    static func travel(store: GameStore, from origin: GridPoint,
                       to destination: GridPoint) -> WorldControlExecution {
        let beforeTurn = store.activeRun?.turnsTaken ?? 0
        store.travel(to: destination)
        guard let final = store.activeRun else { return .completed(.expeditionEnded) }
        let spent = final.turnsTaken - beforeTurn
        if spent == 0, final.playerPosition == origin {
            return .completed(.blocked(finalPosition: final.playerPosition, turnsSpent: spent,
                reason: blockedReason(in: store, fallback: "No way through.")))
        }
        return .completed(.travelEnded(finalPosition: final.playerPosition, turnsSpent: spent,
            reachedDestination: final.playerPosition == destination))
    }
}

@MainActor final class WorldControlAttemptCoordinator: ObservableObject {
    struct Attempt: Equatable, Sendable {
        let id: UInt64
        let action: WorldControlAction
        let snapshot: WorldControlSnapshot
    }
    enum Lifecycle: Equatable, Sendable {
        case available
        case touchDown(WorldControlAction)
        case accepted(Attempt)
        case inFlight(Attempt)
        case completed(UInt64, WorldControlOutcome)
        case refused(WorldControlAction, UInt64?, WorldControlRefusal)
        case disabled(WorldControlAction, String)
    }
    enum Admission: Equatable, Sendable { case accepted(Attempt), refused(WorldControlRefusal) }
    struct RefusalReceipt: Equatable, Sendable {
        let action: WorldControlAction
        let attemptID: UInt64?
        let reason: WorldControlRefusal
        let activeOwnerID: UInt64?
    }

    @Published private(set) var lifecycle: Lifecycle = .available
    @Published private(set) var latestRefusal: RefusalReceipt?
    private var active: Attempt?
    private var nextID: UInt64 = 1

    func touchDown(_ action: WorldControlAction, disabledReason: String? = nil) {
        guard active == nil else { return }
        if let disabledReason { lifecycle = .disabled(action, disabledReason); return }
        lifecycle = .touchDown(action)
    }

    func cancelTouch(_ action: WorldControlAction) {
        guard active == nil, lifecycle == .touchDown(action) else { return }
        lifecycle = .available
    }

    func accept(_ action: WorldControlAction, snapshot: WorldControlSnapshot,
                disabledReason: String? = nil) -> Admission {
        guard active == nil else {
            let refusedID = nextID
            nextID &+= 1
            latestRefusal = .init(action: action, attemptID: refusedID, reason: .busy,
                                  activeOwnerID: active?.id)
            return .refused(.busy)
        }
        if let disabledReason {
            lifecycle = .disabled(action, disabledReason)
            latestRefusal = .init(action: action, attemptID: nil,
                                  reason: .disabled(disabledReason), activeOwnerID: nil)
            return .refused(.disabled(disabledReason))
        }
        let attempt = Attempt(id: nextID, action: action, snapshot: snapshot)
        nextID &+= 1
        active = attempt
        latestRefusal = nil
        lifecycle = .accepted(attempt)
        return .accepted(attempt)
    }

    @discardableResult
    func begin(_ attempt: Attempt) -> Bool {
        guard active == attempt else { return false }
        lifecycle = .inFlight(attempt)
        return true
    }

    func resolve(_ attempt: Attempt, execution: WorldControlExecution) {
        guard active == attempt else { return }
        active = nil
        if latestRefusal?.reason == .busy, latestRefusal?.activeOwnerID == attempt.id {
            latestRefusal = nil
        }
        switch execution {
        case .completed(let outcome): lifecycle = .completed(attempt.id, outcome)
        case .refused(let reason):
            lifecycle = .refused(attempt.action, attempt.id, reason)
            latestRefusal = .init(action: attempt.action, attemptID: attempt.id, reason: reason,
                                  activeOwnerID: nil)
        }
    }

    @discardableResult
    func execute(_ attempt: Attempt, current: WorldControlSnapshot,
                 operation: () -> WorldControlExecution) -> Bool {
        guard active == attempt else { return false }
        guard current == attempt.snapshot else {
            active = nil
            lifecycle = .refused(attempt.action, attempt.id, .stale)
            latestRefusal = .init(action: attempt.action, attemptID: attempt.id, reason: .stale,
                                  activeOwnerID: nil)
            return false
        }
        resolve(attempt, execution: operation())
        return true
    }

    func statusCopy(for action: WorldControlAction) -> String? {
        switch lifecycle {
        case .inFlight(let attempt) where attempt.action == action: "Working…"
        case .refused(let refusedAction, _, let reason) where refusedAction == action:
            reason.playerCopy
        case .disabled(let disabledAction, let reason) where disabledAction == action: reason
        default:
            if latestRefusal?.action == action { latestRefusal?.reason.playerCopy } else { nil }
        }
    }
}

struct WorldWholeFaceControl<Label: View>: View {
    @ObservedObject var coordinator: WorldControlAttemptCoordinator
    let action: WorldControlAction
    let snapshot: () -> WorldControlSnapshot
    let disabledReason: String?
    let operation: () -> WorldControlExecution
    @ViewBuilder let label: () -> Label

    var body: some View {
        label().frame(maxWidth: .infinity)
                .frame(minWidth: 44, minHeight: 44).contentShape(Rectangle())
                .overlay {
                    if case .touchDown(let pressedAction) = coordinator.lifecycle,
                       pressedAction == action {
                        Rectangle().stroke(PixelUITheme.primaryHighlight, lineWidth: 2)
                    }
                }
                .overlay(alignment: .bottom) {
                    if let status = coordinator.statusCopy(for: action) {
                        Text(status).font(.custom("Tiny5", size: 10))
                            .foregroundStyle(PixelUITheme.text)
                            .padding(.horizontal, 4).padding(.vertical, 2)
                            .background(PixelUITheme.surfaceRaised.opacity(0.94))
                            .allowsHitTesting(false)
                        }
                }
                .overlay {
                    WorldControlHitOwner(action: action, disabledReason: disabledReason,
                        onTouchDown: {
                            coordinator.touchDown(action, disabledReason: disabledReason)
                        }, onCancel: {
                            coordinator.cancelTouch(action)
                        }, onActivate: {
                            guard case .accepted(let attempt) = coordinator.accept(
                                action, snapshot: snapshot(), disabledReason: disabledReason)
                            else { return }
                            Task { @MainActor in
                                await Task.yield()
                                guard coordinator.begin(attempt) else { return }
                                await Task.yield()
                                _ = coordinator.execute(attempt, current: snapshot(), operation: operation)
                            }
                        })
                        .frame(minWidth: 44, minHeight: 44)
                }
    }
}

struct WorldControlHitOwner: UIViewRepresentable {
    let action: WorldControlAction
    let disabledReason: String?
    let onTouchDown: @MainActor () -> Void
    let onCancel: @MainActor () -> Void
    let onActivate: @MainActor () -> Void

    final class ControlButton: UIButton {
        var worldAction: WorldControlAction?
        var worldDisabledReason: String?
    }

    @MainActor final class Coordinator: NSObject {
        var onTouchDown: @MainActor () -> Void = {}
        var onCancel: @MainActor () -> Void = {}
        var onActivate: @MainActor () -> Void = {}
        @objc func touchedDown() { onTouchDown() }
        @objc func cancelled() { onCancel() }
        @objc func activated() { onActivate() }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }
    func makeUIView(context: Context) -> ControlButton {
        let button = ControlButton(type: .custom)
        button.backgroundColor = .clear
        button.addTarget(context.coordinator, action: #selector(Coordinator.touchedDown),
                         for: .touchDown)
        button.addTarget(context.coordinator, action: #selector(Coordinator.activated),
                         for: .touchUpInside)
        button.addTarget(context.coordinator, action: #selector(Coordinator.cancelled),
                         for: [.touchCancel, .touchUpOutside, .touchDragExit])
        return button
    }
    func updateUIView(_ uiView: ControlButton, context: Context) {
        uiView.worldAction = action
        uiView.worldDisabledReason = disabledReason
        context.coordinator.onTouchDown = onTouchDown
        context.coordinator.onCancel = onCancel
        context.coordinator.onActivate = onActivate
    }
}

struct WorldFieldFeedbackRow: View {
    private enum Expansion: Hashable { case context, events(String) }
    private struct ExpiryTask: Hashable { let batchID: String?; let isHeld: Bool }
    @EnvironmentObject private var store: GameStore
    @State private var expansion: Expansion?

    init(initiallyExpandedBatchID: String? = nil) {
        _expansion = State(initialValue: initiallyExpandedBatchID.map(Expansion.events))
    }

    var body: some View {
        GeometryReader { proxy in
            let widths = WorldFieldFeedbackLayout.paneWidths(total: proxy.size.width)
            ZStack(alignment: .bottomTrailing) {
                HStack(alignment: .top, spacing: WorldFieldFeedbackLayout.spacing) {
                    contextPane.frame(width: widths.context)
                        .frame(maxHeight: .infinity, alignment: .topLeading)
                    compactEventPane.frame(width: widths.event)
                        .frame(maxHeight: .infinity, alignment: .topLeading)
                }
                if expansion == .context, let context = store.worldFieldContext {
                    expandedContextPane(context)
                        .frame(width: proxy.size.width)
                        .frame(maxHeight: WorldFieldFeedbackLayout.expandedEventMaximumHeight)
                        .offset(y: -WorldFieldFeedbackLayout.compactHeight)
                        .zIndex(3)
                } else if let batch = store.currentWorldFieldEventBatch,
                          expansion == .events(batch.batchID) {
                    expandedEventPane(batch).frame(width: widths.event)
                        .frame(maxHeight: WorldFieldFeedbackLayout.expandedEventMaximumHeight)
                        .offset(y: -WorldFieldFeedbackLayout.compactHeight)
                        .zIndex(3)
                }
            }
        }
        .frame(height: WorldFieldFeedbackLayout.compactHeight)
        .background(PixelUITheme.surfaceInset.opacity(0.82))
        .task(id: ExpiryTask(batchID: store.currentWorldFieldEventBatch?.batchID,
                             isHeld: expansion != nil)) {
            guard expansion == nil else { return }
            guard let batchID = store.currentWorldFieldEventBatch?.batchID else { return }
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            guard !Task.isCancelled else { return }
            store.expireWorldFieldFeedback(ifCurrent: batchID)
        }
    }

    @ViewBuilder private var contextPane: some View {
        if let context = store.worldFieldContext {
            Button { expansion = .context } label: {
                VStack(alignment: .leading, spacing: 1) {
                    Text("AT THIS PLACE")
                        .font(.custom("Tiny5", size: 10)).foregroundStyle(PixelUITheme.muted)
                    Text(context.groundName)
                        .font(.custom("Jersey 10", size: 20)).foregroundStyle(PixelUITheme.text)
                        .lineLimit(1)
                    Text(contextLine(context))
                        .font(.custom("Tiny5", size: 10)).foregroundStyle(PixelUITheme.muted)
                        .lineLimit(2)
                }
                .padding(7)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(PixelUITheme.edgeDark.opacity(0.76))
            .overlay(Rectangle().stroke(PixelUITheme.edge, lineWidth: 2))
        } else {
            Color.clear
        }
    }

    @ViewBuilder private var compactEventPane: some View {
        if let batch = store.currentWorldFieldEventBatch {
            VStack(alignment: .leading, spacing: 2) {
                Text(batch.orderedNarrations[0])
                    .font(.system(size: 16)).foregroundStyle(PixelUITheme.text)
                    .lineLimit(2).frame(maxWidth: .infinity, alignment: .leading)
                HStack(spacing: 6) {
                    if batch.orderedNarrations.count > 1 {
                        Button("Read all \(batch.orderedNarrations.count)") {
                            expansion = .events(batch.batchID)
                        }
                        .frame(maxWidth: .infinity, minHeight: 28)
                        .contentShape(Rectangle())
                        .background(PixelUITheme.surfaceRaised.opacity(0.9))
                    }
                    Button("Dismiss") {
                        expansion = nil
                        store.dismissWorldFieldFeedback(expectedBatchID: batch.batchID)
                    }
                    .frame(maxWidth: .infinity, minHeight: 28)
                    .contentShape(Rectangle())
                    .background(PixelUITheme.surfaceRaised.opacity(0.9))
                }
                .font(.custom("Tiny5", size: 13))
                .buttonStyle(.plain)
            }
            .padding(7)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(PixelUITheme.edgeDark.opacity(0.72))
            .overlay(Rectangle().stroke(PixelUITheme.edge, lineWidth: 2))
        } else {
            Color.clear.overlay(Rectangle().stroke(PixelUITheme.edge.opacity(0.35), lineWidth: 1))
        }
    }

    private func expandedContextPane(_ context: WorldFieldContextReceiptV1) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("AT THIS PLACE · \(context.groundName)")
                .font(.custom("Jersey 10", size: 22)).foregroundStyle(PixelUITheme.text)
            Text(contextLine(context))
                .font(.system(size: 16)).foregroundStyle(PixelUITheme.text)
                .fixedSize(horizontal: false, vertical: true)
            Text(interactionLine(context))
                .font(.custom("Tiny5", size: 15)).foregroundStyle(PixelUITheme.muted)
                .fixedSize(horizontal: false, vertical: true)
            Button("Close") { expansion = nil }
                .font(.custom("Tiny5", size: 15))
                .frame(maxWidth: .infinity, minHeight: 40)
                .contentShape(Rectangle())
                .background(PixelUITheme.surfaceRaised.opacity(0.94))
        }
        .padding(10)
        .background(PixelUITheme.edgeDark.opacity(0.96))
        .overlay(Rectangle().stroke(PixelUITheme.edge, lineWidth: 2))
    }

    private func expandedEventPane(_ batch: WorldFieldEventBatchV1) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(batch.orderedNarrations.enumerated()), id: \.offset) { index, line in
                        Text(index == 0 ? line : "NEXT · \(line)")
                            .font(index == 0 ? .system(size: 17) : .custom("Tiny5", size: 15))
                            .foregroundStyle(index == 0 ? PixelUITheme.text : PixelUITheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            HStack {
                Button("Close") { expansion = nil }
                    .frame(maxWidth: .infinity, minHeight: 40).contentShape(Rectangle())
                Spacer()
                Button("Dismiss") {
                    expansion = nil
                    store.dismissWorldFieldFeedback(expectedBatchID: batch.batchID)
                }
                .frame(maxWidth: .infinity, minHeight: 40).contentShape(Rectangle())
            }
            .font(.custom("Tiny5", size: 15)).buttonStyle(.plain)
        }
        .padding(10)
        .background(PixelUITheme.edgeDark.opacity(0.96))
        .overlay(Rectangle().stroke(PixelUITheme.edge, lineWidth: 2))
    }

    private func contextLine(_ context: WorldFieldContextReceiptV1) -> String {
        var parts: [String] = []
        if context.elevation > 0 { parts.append("Elevation \(context.elevation)") }
        if context.surfaceDeposits.snow { parts.append("Snow") }
        if context.surfaceDeposits.settledAsh { parts.append("Settled Ash") }
        if context.stabilitySurfaceState == "cracking" { parts.append("Cracking") }
        if let flora = context.floraDisplayName { parts.append(flora) }
        switch context.contentSummary {
        case .none: break
        case .node(let name), .item(let name), .site(let name), .traveller(let name): parts.append(name)
        case .genericHazard: parts.append("Hazard")
        case .portal: parts.append("Portal")
        case .lockedCache: parts.append("Locked cache")
        case .writing: parts.append("Loose page")
        }
        return parts.isEmpty ? "Open ground" : parts.joined(separator: " · ")
    }

    private func interactionLine(_ context: WorldFieldContextReceiptV1) -> String {
        if case .unavailable(let reason) = context.interactionState { return reason }
        return switch context.interaction {
        case .none: "Nothing to use here"
        case .harvest: "Harvest"
        case .searchSite: "Search site"
        case .enterPortal: "Portal home"
        case .openCache: "Open cache"
        case .takePage: "Take page"
        case .survey: "Survey"
        case .useAnchor: "Use Atlas Seam"
        case .placeAnchor: "Place Anchor Frame"
        }
    }
}

/// The world: stability at the top, the grid in the middle, your hands at the bottom.
///
/// Ergonomics note. A 14×14 grid can't give every tile a 44pt target on a 402pt-wide phone — that
/// would need a 616pt screen. So the grid is a *map*, not a control surface: tapping a tile is the
/// planning gesture (walk there), while the primary one-handed control is the D-pad in the thumb
/// zone, which the brief offers for exactly this reason. Every button is ≥44pt.
struct WorldView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.displayScale) private var displayScale
    /// Everything that crossed the threshold and can be consulted or used outside combat.
    @State private var isShowingFieldKit = false
    @State private var isConfirmingAtlasSeam = false
    @State private var isConfirmingAnchorFrame = false
    @State private var isLookArmed = false
    @State private var inspection: InspectionPresentation?
    @State private var fieldPageMessage: String?
    @State private var pendingWorldPageSwap: WildWorldPageFieldRules.Quote?
    @State private var tutorialLesson: TutorialLessonID?
    @State private var dismissedTutorials: Set<TutorialLessonID> = []
    @StateObject private var controlCoordinator = WorldControlAttemptCoordinator()
#if DEBUG
    @State private var isShowingDiagnostics = false
#endif

    private var run: WorldRun? { store.state.worlds.activeRun }

    var body: some View {
        AnyView(VStack(spacing: 0) {
            if let run {
                StabilityHeader(run: run)
                PartyHealthStrip(run: run, state: store.state)
                VStack(spacing: 0) {
                    VStack(spacing: 0) {
                        GeometryReader { viewport in
                        let visibilityProfile = WorldRules.visibilityProfile(
                            in: run, party: WorldRules.sightBonus(in: store.state))
                        let viewportColumns = WorldMapLayout.viewportColumns(
                            mapColumns: run.map.width,
                            cameraColumns: Tuning.World.viewportTiles)
                        let mapWidth = WorldMapLayout.maximumSide(
                            containerWidth: viewport.size.width,
                            viewportHeight: viewport.size.height,
                            viewportTiles: viewportColumns,
                            displayScale: displayScale)
                        let viewportRows = WorldMapLayout.viewportRows(
                            mapWidth: mapWidth,
                            availableHeight: viewport.size.height,
                            viewportColumns: viewportColumns,
                            mapRows: run.map.height)
                        VStack(spacing: 0) {
                            MapGrid(
                                run: run,
                                maximumWidth: mapWidth,
                                viewportColumns: viewportColumns,
                                viewportRows: viewportRows,
                                visibilityProfile: visibilityProfile,
                                travellerSpeech: store.worldTravellerSpeech,
                                onTravellerSpeechFinished: { travellerID in
                                    store.finishWorldTravellerSpeech(
                                        expectedTravellerID: travellerID)
                                }
                            ) { point in
                                tapped(point, in: run)
                            }
                            .id("world-map-\(viewportColumns)x\(viewportRows)-\(mapWidth)")
                            .overlay(alignment: .bottom) {
                                WorldFieldFeedbackRow().environmentObject(store)
                            }
                        }
                        .overlay(alignment: .top) {
                            LootDecisionCard()
                                .padding(12)
                        }
                        }
                        .background {
#if DEBUG
                            WorldMapStageProbe()
#endif
                        }
                        .clipped()
                        satchel(run)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                    }

                    controls(run)
                }
                .background(PixelUITheme.surfaceInset)
                .overlay(alignment: .top) {
                    Rectangle().fill(PixelUITheme.edge).frame(height: 2)
                }
                .zIndex(2)
            }
        })
        .modifier(WorldMiningFeedbackPresentationModifier(store: store))
        .background(PixelUITheme.edgeDark.ignoresSafeArea())
#if DEBUG
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { isShowingDiagnostics = true } label: { Image(systemName: "stethoscope") }
                    .accessibilityLabel("World diagnostics")
            }
        }
        .sheet(isPresented: $isShowingDiagnostics) {
            if let run { WorldDiagnosticsView(run: run, concealment: WorldRules.fieldConcealment(in: store.state)) }
        }
#endif
        // **Standing on somebody opens the scene.** Driven off the map rather than off an event, so
        // a force-quit mid-conversation resumes with the conversation still open — you are still
        // standing there, and they are still waiting (pillar 2).
        .sheet(item: Binding(get: { store.travellerHere }, set: { _ in })) { traveller in
            TravellerMeetingView(traveller: traveller).environmentObject(store)
        }
        .sheet(isPresented: $isShowingFieldKit) {
            FieldKitSheet().environmentObject(store)
        }
        .alert("Bind this world at the Atlas Seam?", isPresented: $isConfirmingAtlasSeam) {
            Button("Cancel", role: .cancel) {}
            Button("Anchor for \(store.naturalAnchorCost) essence") {
                store.anchorAtNaturalPoint()
            }
        } message: {
            Text("The realm will remain in Tovin's Anchorage and can be revisited after this expedition ends.")
        }
        .alert("Place the Anchor Frame here?", isPresented: $isConfirmingAnchorFrame) {
            Button("Cancel", role: .cancel) {}
            Button("Place frame") { store.placeAnchorFrame() }
        } message: {
            Text("The frame will be consumed and this realm will remain in the Anchorage. No additional essence is charged.")
        }
        .alert(item: $inspection) { result in
            Alert(title: Text(result.value.heading), message: Text(result.value.details.joined(separator: " · ")),
                  dismissButton: .default(Text("Done")))
        }
        .alert("Loose page", isPresented: Binding(
            get: { fieldPageMessage != nil }, set: { if !$0 { fieldPageMessage = nil } }
        )) {
            Button("Done") { fieldPageMessage = nil }
        } message: {
            Text(fieldPageMessage ?? "")
        }
        .confirmationDialog(
            "Keep this page?",
            isPresented: Binding(get: { pendingWorldPageSwap != nil },
                                 set: { if !$0 { pendingWorldPageSwap = nil } }),
            titleVisibility: .visible
        ) {
            if let run, let quote = pendingWorldPageSwap {
                ForEach(run.satchelItems.stacks, id: \.id) { stack in
                    Button("Leave \(stack.displayName) ×\(stack.count)") {
                        completeWorldPageSwap(quote, discarding: .itemStack(stack.id))
                    }
                }
                ForEach(run.carriedWorldPages, id: \.id) { page in
                    Button("Leave \(page.inspected ? page.definition.title : "Unknown page")") {
                        completeWorldPageSwap(quote, discarding: .worldPage(page.id))
                    }
                }
            }
            Button("Keep what I have", role: .cancel) { pendingWorldPageSwap = nil }
        } message: {
            Text("Your satchel is full. Choose the exact slot to leave behind, or keep what you have.")
        }
        .tutorialHoverOverlay(
            isPresented: tutorialLesson != nil && !tutorialSuppressed,
            alignment: .bottom
        ) {
            if let id = tutorialLesson, let lesson = TutorialRules.definition(id) {
                TutorialCard(lesson: lesson,
                             gotIt: { dismissedTutorials.insert(id); tutorialLesson = nil },
                             notNow: {
                                 dismissedTutorials.insert(id)
                                 store.deferTutorial(id)
                                 tutorialLesson = nil
                             })
                    .transition(.opacity)
            }
        }
        .onAppear { presentNextWorldLesson() }
        .onChange(of: run?.playerPosition) { old, new in
            guard old != new else { return }
            if store.state.tutorial[.worldNavigation].status != .completed {
                present(.worldNavigation)
                store.completeTutorial(.worldNavigation, fact: "first_movement")
            }
            presentNextWorldLesson()
        }
        .onChange(of: run?.turnsTaken) { old, new in
            guard let old, let new, new > old else { return }
            if store.state.tutorial[.worldStability].status != .completed {
                present(.worldStability)
                store.completeTutorial(.worldStability, fact: "post_turn_meter_seen")
            }
        }
    }

    /// Tap an adjacent tile to step; tap anywhere else to walk there turn by turn.
    private func tapped(_ point: GridPoint, in run: WorldRun) {
        isLookArmed = false
        var routedAction: WorldControlAction?
        WorldMapPlanningAction.route(from: run.playerPosition, to: point) { routedAction = $0 }
        guard let planningAction = routedAction else { return }
        if case .move = planningAction {
            performControl(planningAction) {
                WorldControlRulesExecution.step(store: store, to: point)
            }
        } else {
            performControl(planningAction) {
                WorldControlRulesExecution.travel(store: store, from: run.playerPosition, to: point)
            }
        }
    }

    // Event copy is single-sourced by WorldFieldNarration and consumed by WorldFieldFeedbackRow.
    // MARK: Satchel

    private func placeInformation(_ run: WorldRun) -> some View {
        HStack(spacing: 10) {
            Text(placeIcon)
                .font(.custom("Jersey 10", size: 24))
                .frame(width: 40, height: 40)
                .foregroundStyle(PixelUITheme.text)
                .background(PixelUITheme.surfaceRaised.opacity(0.92))
                .overlay(Rectangle().stroke(PixelUITheme.edge, lineWidth: 2))

            VStack(alignment: .leading, spacing: 1) {
                Text(placeEyebrow)
                    .font(.custom("Tiny5", size: 10))
                    .foregroundStyle(PixelUITheme.muted)
                Text(placeTitle)
                    .font(.custom("Jersey 10", size: 20))
                    .foregroundStyle(PixelUITheme.text)
                    .lineLimit(1)
                Text(interactionDetail(in: run))
                    .font(.custom("Tiny5", size: 10))
                    .foregroundStyle(PixelUITheme.muted)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.top, 30)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [.clear, PixelUITheme.surfaceInset.opacity(0.96)],
                           startPoint: .top, endPoint: .bottom)
        )
        .overlay(Rectangle().stroke(PixelUITheme.edge, lineWidth: 2))
        .allowsHitTesting(false)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("At this place. \(placeTitle). \(interactionDetail(in: run))")
    }

    private var placeEyebrow: String {
        isLookArmed ? "LOOK · NO TURN SPENT" : "AT THIS PLACE · VISIBLE"
    }

    private var placeIcon: String {
        if store.harvestableHere != nil { return "⌁" }
        if store.searchableHere != nil { return "⌂" }
        if store.canPortalHere { return "◇" }
        if store.isOnLockedCache { return "▣" }
        if store.offeredWorldPageHere != nil { return "▦" }
        if store.canUseNaturalAnchor || store.canPlaceAnchorFrame { return "◆" }
        if isLookArmed { return "◎" }
        return "·"
    }

    private var placeTitle: String {
        if let node = store.harvestableHere {
            return ContentCatalog.shared.resource(node.resource)?.name ?? "Resource"
        }
        if let site = store.searchableHere { return site.definition?.name ?? "Site" }
        if store.canPortalHere { return "Atlas Seam" }
        if store.isOnLockedCache { return "Locked cache" }
        if let page = store.offeredWorldPageHere {
            return page.inspected ? page.definition.title : "Unknown World Page"
        }
        if store.canUseNaturalAnchor { return "Natural Atlas Seam" }
        if store.canPlaceAnchorFrame { return "Anchor point" }
        if isLookArmed { return "Adjacent ground" }
        guard let run else { return "Unknown ground" }
        return run.map[run.playerPosition].ground.displayName.capitalized
    }

    /// What you're carrying, and how long you've been at it.
    ///
    /// **The haul scrolls sideways.** With four resources in the game this was a fixed row; with
    /// twenty-three, carrying enough variety made the row wider than the phone — and because a
    /// `VStack` takes the width of its widest child, the *map* grew to match and walked off the
    /// edge of the screen (Aimee, 6 Aug). Health and the turn count stay pinned outside the scroll,
    /// because those two are what you actually check.
    private func satchel(_ run: WorldRun) -> some View {
        HStack(spacing: 12) {
            if run.satchel.isEmpty {
                Text("satchel empty")
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(run.satchel.nonZero, id: \.id) { entry in
                            HStack(spacing: 3) {
                                ResourceFieldMarkerIdentity(
                                    id: entry.id,
                                    fallbackSystemIcon: ContentCatalog.shared.resource(entry.id)?.icon ?? "cube"
                                )
                                .frame(width: 8, height: 8)
                                Text("\(entry.amount)")
                            }
                            .fixedSize()
                            .modifier(ResourceMiningCounterPulse(
                                resourceID: entry.id,
                                presentations: store.worldMiningFeedbackPresentations))
                        }
                    }
                    .padding(.trailing, 4)
                }
                .frame(maxWidth: .infinity)
            }
            WorldWholeFaceControl(
                coordinator: controlCoordinator, action: .fieldKit,
                snapshot: controlSnapshot, disabledReason: nil,
                operation: {
                    store.clearWorldTravellerSpeechPresentation()
                    isShowingFieldKit = true
                    return .completed(.openedFieldKit)
                }) {
                Label("Field Kit", systemImage: "backpack.fill")
                    .labelStyle(.titleAndIcon)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .foregroundStyle(.teal)
            .fixedSize()
            .accessibilityIdentifier("world.field-kit")
            Text("turn \(run.turnsTaken)")
                .foregroundStyle(.secondary)
                .fixedSize()
        }
        .font(.footnote.monospacedDigit())
        .padding(.horizontal, 8)
        .frame(minHeight: 44)
        .frame(maxWidth: .infinity)
        .foregroundStyle(PixelUITheme.text)
        .background(PixelUITheme.surfaceInset)
        .overlay(Rectangle().stroke(PixelUITheme.edge, lineWidth: 2))
    }

    // MARK: Controls — thumb zone

    private func controls(_ run: WorldRun) -> some View {
        HStack(alignment: .center, spacing: WorldControlsLayout.navigationSpacing) {
            DirectionPad(isLooking: isLookArmed, coordinator: controlCoordinator,
                         snapshot: controlSnapshot) { direction in
                let point = GridPoint(x: run.playerPosition.x + direction.dx,
                                      y: run.playerPosition.y + direction.dy)
                if isLookArmed {
                    store.clearWorldTravellerSpeechPresentation()
                    inspection = InspectionPresentation(value: WorldRules.inspect(
                        point, in: run, base: store.state.base))
                    isLookArmed = false
                    return .completed(.inspected(point))
                } else {
                    return WorldControlRulesExecution.step(store: store, to: point)
                }
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 12) {
                MinimapView(run: run)
                    .frame(width: 96, height: 96)
                    .fixedSize()
                    .frame(maxWidth: .infinity)

                WorldActionRow {
                    AnyView(WorldWholeFaceControl(
                        coordinator: controlCoordinator, action: .useTile,
                        snapshot: controlSnapshot,
                        disabledReason: canInteract ? nil : useTileUnavailableReason,
                        operation: performInteraction) {
                        Text("Use Tile")
                            .font(.custom("Tiny5", size: 10))
                            .lineLimit(1).minimumScaleFactor(0.85)
                            .frame(maxWidth: .infinity,
                                   minHeight: WorldControlsLayout.actionHeight)
                            .foregroundStyle(canInteract ? PixelUITheme.screen : PixelUITheme.muted)
                            .background(canInteract ? PixelUITheme.primary : PixelUITheme.neutral)
                            .overlay(Rectangle().stroke(PixelUITheme.edgeDark, lineWidth: 2))
                    }
                    .accessibilityValue(interactionDetail(in: run))
                    .accessibilityIdentifier("world.interact"))
                } look: {
                    AnyView(WorldWholeFaceControl(
                        coordinator: controlCoordinator, action: .armLook,
                        snapshot: controlSnapshot, disabledReason: nil,
                        operation: {
                            store.clearWorldTravellerSpeechPresentation()
                            isLookArmed.toggle()
                            return .completed(.lookArmed(isLookArmed))
                        }) {
                        Text(isLookArmed ? "Cancel" : "Look")
                            .font(.custom("Tiny5", size: 10))
                            .lineLimit(1).minimumScaleFactor(0.85)
                            .frame(maxWidth: .infinity,
                                   minHeight: WorldControlsLayout.actionHeight)
                            .foregroundStyle(PixelUITheme.text)
                            .background(isLookArmed ? PixelUITheme.primaryHighlight : PixelUITheme.neutral)
                            .overlay {
                                Rectangle().stroke(isLookArmed ? PixelUITheme.primary : PixelUITheme.edgeDark,
                                                   lineWidth: 2)
                        }
                    }
                    .accessibilityLabel(isLookArmed ? "Cancel Look" : "Look")
                    .accessibilityHint(isLookArmed
                        ? "Look mode armed. Choose one direction."
                        : "Inspect one adjacent tile without moving or spending a turn.")
                    .accessibilityIdentifier("world.look"))
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("world.action-row")
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, WorldControlsLayout.horizontalPadding)
        .padding(.vertical, 8)
        .background(PixelUITheme.surfaceInset)
    }

    private func controlSnapshot() -> WorldControlSnapshot {
        WorldControlSnapshot.make(from: store.state)
    }

    private func performControl(_ action: WorldControlAction,
                                operation: @escaping () -> WorldControlExecution) {
        guard case .accepted(let attempt) = controlCoordinator.accept(
            action, snapshot: controlSnapshot()) else { return }
        Task { @MainActor in
            await Task.yield()
            guard controlCoordinator.begin(attempt) else { return }
            await Task.yield()
            _ = controlCoordinator.execute(attempt, current: controlSnapshot(), operation: operation)
        }
    }

    private var canInteract: Bool {
        store.harvestableHere != nil || store.searchableHere != nil || store.canPortalHere
            || store.canLeaveMalformedOlderWorld
            || (store.isOnLockedCache && store.carriedCacheKey != nil)
            || store.canUseNaturalAnchor || store.canPlaceAnchorFrame || store.canSurvey
            || store.offeredWorldPageHere != nil
    }

    private var useTileUnavailableReason: String { "There is nothing to use here." }

    private func interactionDetail(in run: WorldRun) -> String {
        if let node = store.harvestableHere {
            return "Harvest \(ContentCatalog.shared.resource(node.resource)?.name ?? "resource") · \(node.remainingHarvests) left"
        }
        if let page = store.offeredWorldPageHere {
            return page.inspected ? "Take \(page.definition.title) · 1 satchel slot"
                                  : "Take loose page · 1 satchel slot · no turn"
        }
        if let site = store.searchableHere, let definition = site.definition {
            return "Search \(definition.name) · \(site.searchTurnsRemaining) turns left"
        }
        if store.canPortalHere { return "Portal home · keep everything" }
        if store.canLeaveMalformedOlderWorld { return "Leave this world · keep everything · no turn" }
        if store.isOnLockedCache {
            return store.carriedCacheKey == nil ? "Locked cache · needs a key" : "Open cache · spends your key"
        }
        if store.canUseNaturalAnchor { return "Use Atlas Seam · \(store.naturalAnchorCost) essence" }
        if store.canPlaceAnchorFrame { return "Place Anchor Frame here" }
        if store.canSurvey { return "Survey · \(run.carriedInstruments.count) instruments · 1 turn" }
        if store.naturalAnchorHere != nil {
            return "Atlas Seam · needs Anchorage and \(store.naturalAnchorCost) essence"
        }
        if store.carriedAnchorFrame != nil { return "Anchor Frame · needs clear open ground" }
        return hint(for: run)
    }

    private func performInteraction() -> WorldControlExecution {
        store.clearWorldTravellerSpeechPresentation()
        if let page = store.offeredWorldPageHere,
           let quote = store.offeredWorldPageQuote(page.id) {
            switch store.takeOfferedWorldPage(quote) {
            case .taken:
                return .completed(.usedTile("Took World Page"))
            case .satchelFull:
                pendingWorldPageSwap = quote
                return .completed(.usedTile("Choose a satchel slot"))
            case .stale, .notHere, .duplicateIdentity:
                fieldPageMessage = "That page is no longer available here."
                return .refused(.stale)
            case .inspected, .swapped:
                return .refused(.rules("That page action is no longer current."))
            }
        } else if store.harvestableHere != nil {
            completeInteraction(); store.harvest()
            return .completed(.usedTile("Harvested"))
        } else if store.searchableHere != nil {
            completeInteraction(); store.searchSite()
            return .completed(.usedTile("Searched site"))
        } else if store.canPortalHere {
            store.completeTutorial(.worldReturn, fact: "first_expedition_outcome")
            store.portalHome()
            return .completed(.usedTile("Returned Home"))
        } else if store.canLeaveMalformedOlderWorld {
            store.leaveMalformedOlderWorld()
            return .completed(.usedTile("Left older world"))
        } else if store.isOnLockedCache, store.carriedCacheKey != nil {
            completeInteraction(); store.openCacheHere()
            return .completed(.usedTile("Opened cache"))
        } else if store.canUseNaturalAnchor {
            completeInteraction(); isConfirmingAtlasSeam = true
            return .completed(.usedTile("Opened anchor confirmation"))
        } else if store.canPlaceAnchorFrame {
            completeInteraction(); isConfirmingAnchorFrame = true
            return .completed(.usedTile("Opened frame confirmation"))
        } else if store.canSurvey {
            completeInteraction(); store.survey()
            return .completed(.usedTile("Surveyed"))
        }
        return .refused(.disabled(useTileUnavailableReason))
    }

    private func completeWorldPageSwap(
        _ quote: WildWorldPageFieldRules.Quote,
        discarding occupant: WildWorldPageFieldRules.SlotOccupant
    ) {
        pendingWorldPageSwap = nil
        switch store.swapOfferedWorldPage(quote, discarding: occupant) {
        case .swapped: break
        case .stale, .notHere, .duplicateIdentity, .satchelFull:
            fieldPageMessage = "That choice is no longer current. Nothing was changed."
        case .inspected, .taken: break
        }
    }

    private func hint(for run: WorldRun) -> String {
        switch run.stabilityBand {
        case .stable: "Tap a tile to walk there."
        case .hazardous: "Hazards are forming at the edges."
        case .crumbling: "The world is falling in. Find a portal."
        case .collapsed: "Gone."
        }
    }

    private var tutorialSuppressed: Bool {
        guard let run else { return true }
        return run.activeEncounter != nil || !run.offeredItems.isEmpty
    }

    private var hasActionHere: Bool {
        store.canSurvey || store.harvestableHere != nil || store.searchableHere != nil
            || store.naturalAnchorHere != nil || store.canPlaceAnchorFrame || store.canPortalHere
            || store.isOnLockedCache || store.offeredWorldPageHere != nil
    }

    private func present(_ id: TutorialLessonID) {
        guard tutorialLesson == nil, !tutorialSuppressed,
              !dismissedTutorials.contains(id),
              store.state.tutorial[id].status != .completed else { return }
        store.tutorialEligible(id)
        tutorialLesson = id
    }

    private func presentNextWorldLesson() {
        guard tutorialLesson == nil, !tutorialSuppressed, let run else { return }
        if store.state.tutorial[.worldNavigation].status != .completed {
            present(.worldNavigation)
        } else if run.turnsTaken > 0 && store.state.tutorial[.worldStability].status != .completed {
            present(.worldStability)
        } else if hasActionHere && store.state.tutorial[.worldInteraction].status != .completed {
            present(.worldInteraction)
        } else if store.canPortalHere && store.state.tutorial[.worldReturn].status != .completed {
            present(.worldReturn)
        }
    }

    private func completeInteraction() {
        store.completeTutorial(.worldInteraction, fact: "first_valid_world_action")
        if tutorialLesson == .worldInteraction { tutorialLesson = nil }
    }
}

#if DEBUG
private struct WorldDiagnosticsView: View {
    @Environment(\.dismiss) private var dismiss
    let run: WorldRun
    let concealment: WorldRules.FieldConcealment

    private var nodes: [ResourceID: Int] {
        run.map.tiles.reduce(into: [:]) { result, tile in
            if case .node(let node) = tile.content {
                result[node.resource, default: 0] += node.remainingHarvests * node.yieldPerHarvest
                if let secondary = node.secondaryResource {
                    result[secondary, default: 0] += node.remainingHarvests * node.secondaryYieldPerHarvest
                }
            }
        }
    }
    var body: some View {
        NavigationStack {
            List {
                Section("Identity") {
                    LabeledRow(icon: "number", label: "Seed", value: "\(run.mapSeed)")
                    LabeledRow(icon: "clock", label: "Turn", value: "\(run.turnsTaken)")
                }
                Section("Writing") {
                    let report = run.generationDiagnostics
                    LabeledRow(icon: "checkmark.seal", label: "Guaranteed", value: report.writingWasGuaranteed ? "yes" : "no")
                    LabeledRow(icon: "book.pages", label: "Diary selected / placed",
                               value: "\(report.selectedDiaryPages.count) / \(report.placedDiaryPages.count)")
                    LabeledRow(icon: "note.text", label: "Other selected / placed",
                               value: "\(report.selectedOtherWritingCount) / \(report.placedOtherWritings.count)")
                    LabeledRow(icon: "dice", label: "Second-writing roll",
                               value: report.secondWritingRollSucceeded ? "succeeded" : "missed")
                    LabeledRow(icon: "percent", label: "Diary mix snapshot",
                               value: run.tuning.diaryWritingShare.formatted(.percent.precision(.fractionLength(0))))
                    LabeledRow(icon: "hourglass", label: "Patience floor", value: "\(run.tuning.diaryPatienceWorlds) worlds")
                }
                Section("Population") {
                    let report = run.generationDiagnostics
                    LabeledRow(icon: "hare", label: "Creature species", value: "\(report.creatureSpeciesCount)")
                    LabeledRow(icon: "pawprint", label: "Creature instances placed", value: "\(report.creatureInstancesPlaced)")
                    LabeledRow(icon: "crown", label: "Apex roll / result",
                               value: "\(report.apexChance.formatted(.percent.precision(.fractionLength(1)))) · \(report.apexRollSucceeded ? "hit" : "miss") · \(report.apexPlaced ? "placed" : "none")")
                    LabeledRow(icon: "leaf", label: "Flora species / instances",
                               value: "\(report.floraSpeciesCount) / \(report.floraInstancesPlaced)")
                    LabeledRow(icon: "burst", label: "Active flora placed", value: "\(report.activeFloraPlaced)")
                }
                Section("Field awareness") {
                    LabeledRow(icon: "figure.walk", label: "Quiet Step / radius reduction",
                               value: "\(concealment.quietStep ? "yes" : "no") / -\(concealment.radiusReduction)")
                    let alertReason: (WorldEnemy.Awareness.Reason) -> String = { reason in
                        switch reason {
                        case .quietStep: "Quiet Step noticed"
                        case .maskedScent: "masked scent noticed"
                        case .disturbance: "disturbance noticed"
                        }
                    }
                    ForEach(run.enemies) { enemy in
                        let state: String = switch enemy.awareness {
                        case .unaware: "unaware"
                        case .pursuing: "pursuing"
                        case .alert(_, let reason): "alert · \(alertReason(reason))"
                        }
                        LabeledRow(icon: enemy.isApex ? "crown" : "eye",
                                   label: run.name(of: enemy),
                                   value: "\(state) · normal detection radius \(WorldRules.detectionRadius(of: enemy, in: run)) · Quiet Step hesitation used \(enemy.quietStepHesitationUsed ? "yes" : "no")")
                    }
                }
                Section("World duration") {
                    let duration = WorldDurationPresentation.diagnostic(
                        stability: run.stability, decayPerTurn: run.decayPerTurn,
                        collapsedOnTurn: run.collapsedOnTurn)
                    LabeledRow(icon: "gauge", label: "Stability score", value: "\(run.effectiveStabilityScore)")
                    LabeledRow(icon: "timer", label: duration.label, value: duration.value)
                    LabeledRow(icon: "flag.checkered", label: "Initial budget / projected collapse",
                               value: "\(run.generationDiagnostics.initialTurnBudget) / turn \(run.generationDiagnostics.projectedCollapseTurn)")
                    LabeledRow(icon: "shippingbox", label: "Collapse recovery",
                               value: run.tuning.collapseRecoveryFraction.formatted(.percent.precision(.fractionLength(0))))
                }
                Section("Placed resources") {
                    let report = run.generationDiagnostics
                    LabeledRow(icon: "drop.fill", label: "Raw Essence eligible / attempted / placed",
                               value: "\(report.rawEssenceEligibleTiles) / \(report.rawEssencePlacementAttempts) / \(report.rawEssenceDropsPlaced)")
                    LabeledRow(icon: "drop", label: "Raw Essence obtainable",
                               value: "\(report.rawEssenceObtainable)")
                    if nodes.isEmpty { Text("None") }
                    ForEach(nodes.keys.sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { id in
                        LabeledRow(icon: ContentCatalog.shared.resource(id)?.icon ?? "cube",
                                   label: ContentCatalog.shared.resource(id)?.name ?? "Unknown resource",
                                   value: "\(nodes[id] ?? 0)")
                    }
                }
                Section("Traveller placement") {
                    let report = run.generationDiagnostics
                    LabeledRow(icon: "person.3", label: "Candidates / matches / eligible / placed",
                               value: "\(report.travellerCandidates.count) / \(report.travellerSignatureMatches.count) / \(report.travellerEligibleMatches.count) / \(report.travellersPlaced.count)")
                    let arrival = report.travellerArrival
                    if let selected = arrival.selectedTraveller {
                        let selectedName = ContentCatalog.shared.traveller(selected)?.name ?? "Unknown traveller"
                        LabeledRow(icon: "person.crop.circle.badge.questionmark",
                                   label: "Selected traveller / band / order",
                                   value: "\(selectedName) [Internal ID: \(selected.rawValue)] / \(arrival.storyArrivalBand.map(String.init) ?? "—") / \(arrival.authoredOrder.map(String.init) ?? "—")")
                        LabeledRow(icon: "text.book.closed", label: "Recovered clues / known matching clues / all matching clues / unplanned matches",
                                   value: "\(arrival.recoveredLocationClues) / \(arrival.causallyAuthoredKnownConditions) / \(arrival.causallyAuthoredConditions) / \(arrival.accidentalSatisfiedConditions)")
                        LabeledRow(icon: "dice", label: "Evidence / prior misses / chance / roll",
                                   value: "\(arrival.evidenceScore.formatted(.number.precision(.fractionLength(2)))) / \(arrival.priorNearMisses) / \(arrival.arrivalChance.formatted(.percent.precision(.fractionLength(1)))) / \(arrival.arrivalRoll?.formatted(.number.precision(.fractionLength(4))) ?? "—")")
                    }
                    let arrivalOutcome: String = switch arrival.outcome {
                    case .noEligibleMatch: "No eligible traveller"
                    case .confidenceFailed: "Evidence was not strong enough"
                    case .placementFailed: "No valid placement"
                    case .placed: "Traveller placed"
                    }
                    LabeledRow(icon: "checkmark.seal", label: "Arrival outcome",
                               value: arrivalOutcome)
                    if report.travellersPlaced.isEmpty { Text("No travellers placed") }
                    ForEach(report.travellersPlaced, id: \.self) { id in
                        Text("\(ContentCatalog.shared.traveller(id)?.name ?? "Unknown traveller") [Internal ID: \(id.rawValue)]")
                    }
                }
                if let preview = run.activeEncounter?.scalingPreview {
                    Section("Encounter scaling") {
                        LabeledRow(icon: "number", label: "Scaling rules",
                                   value: preview.scalingRulesVersion ?? "Older rules · upper-median scaling")
                        if let ledger = preview.partyPowerLedger {
                            LabeledRow(icon: "person.3", label: "Anchor / party power",
                                       value: "L\(ledger.anchorLevel) · \(ledger.uncappedBudget.formatted(.number.precision(.fractionLength(3)))) → \(ledger.cappedBudget.formatted(.number.precision(.fractionLength(3))))")
                            ForEach(Array(ledger.contributions.enumerated()), id: \.offset) { _, entry in
                                LabeledRow(icon: entry.identity == "binder" ? "person.fill" : "person",
                                           label: entry.identity,
                                           value: "L\(entry.level) · ratio \(entry.rawLevelRatio.formatted(.number.precision(.fractionLength(3)))) · +\(entry.contribution.formatted(.number.precision(.fractionLength(3))))")
                            }
                        } else {
                            LabeledRow(icon: "person.3", label: "Historical party levels / upper median",
                                       value: "\(preview.partyLevels.map(String.init).joined(separator: ", ")) / \(preview.upperMedian)")
                        }
                        let foeLabel: (InstanceID) -> String = { id in
                            let name = run.enemies.first(where: { $0.id == id }).map { run.name(of: $0) }
                                ?? "Unknown creature"
                            return "\(name) [Internal ID: \(id.rawValue)]"
                        }
                        LabeledRow(icon: "pawprint", label: "Visible foes",
                                   value: preview.foeIDs.map(foeLabel).joined(separator: ", "))
                        LabeledRow(icon: "circle.grid.cross", label: "Grouping radius / inclusion reasons",
                                   value: "\(preview.groupingRadius) · " + preview.inclusionReasons.keys.sorted().compactMap { foeID in
                                       guard let raw = UInt64(foeID) else { return nil }
                                       return preview.inclusionReasons[foeID].map { reason in "\(foeLabel(InstanceID(rawValue: raw))): \(reason)" }
                                   }.joined(separator: "; "))
                        if let excluded = preview.exclusionReasons, !excluded.isEmpty {
                            LabeledRow(icon: "nosign", label: "Excluded map foes",
                                       value: excluded.keys.sorted().compactMap { foeID in
                                           guard let raw = UInt64(foeID) else { return nil }
                                           return excluded[foeID].map { "\(foeLabel(InstanceID(rawValue: raw))): \($0)" }
                                       }.joined(separator: "; "))
                        }
                        LabeledRow(icon: "chart.bar", label: "Stability / greed level-equivalents",
                                   value: "\(preview.stabilityLevelContribution.formatted(.number.precision(.fractionLength(2)))) / \(preview.greedLevelContribution.formatted(.number.precision(.fractionLength(2))))")
                        if preview.scalingRulesVersion == EncounterScalingRules.additivePartyPowerRulesVersion {
                            LabeledRow(icon: "scalemass", label: "Real foes / shortfall",
                                       value: "\(preview.realFoeCount ?? preview.visibleFoeCount) / \((preview.shortfall ?? 0).formatted(.number.precision(.fractionLength(3))))")
                            LabeledRow(icon: "arrow.turn.down.right", label: "Pressure slots / HP fraction",
                                       value: "\(preview.wholePressureSlots ?? 0) / \((preview.totalHPAdditionFraction ?? 0).formatted(.percent.precision(.fractionLength(1))))")
                            let allocations = preview.hpAllocationByFoeID ?? [:]
                            LabeledRow(icon: "heart", label: "HP allocation",
                                       value: allocations.isEmpty ? "none" : allocations.keys.sorted().map {
                                           "\($0): +\(allocations[$0, default: 0])"
                                       }.joined(separator: "; "))
                            let slots = run.activeEncounter?.turnSlots.compactMap { slot -> String? in
                                switch slot.kind {
                                case .ordinaryPressureFollowUp(let ordinal):
                                    return "\(slot.actor): lighter \(ordinal) @ \(slot.strengthMultiplier.formatted(.percent))"
                                case .apexFollowUp(let ordinal):
                                    return "\(slot.actor): apex \(ordinal) @ \(slot.strengthMultiplier.formatted(.percent))"
                                case .primary: return nil
                                }
                            } ?? []
                            LabeledRow(icon: "list.number", label: "Saved follow-up slots",
                                       value: slots.isEmpty ? "none" : slots.joined(separator: "; "))
                        } else {
                            LabeledRow(icon: "scalemass", label: "Historical budget / visible / adjustment",
                                       value: "\(preview.ordinaryBudget.formatted(.number.precision(.fractionLength(2)))) / \(preview.visibleFoeCount) / +\(preview.totalOrdinaryLevelAdjustment)")
                            LabeledRow(icon: "dice", label: "Historical remainder roll / step",
                                       value: "\(preview.remainderRoll) / +\(preview.remainderUpgrade)")
                        }
                        LabeledRow(icon: "crown", label: "Apex floor · HP · offence · actions",
                                   value: "L\(preview.apexLevelFloor) · \(preview.apexHPMultiplier.formatted(.number.precision(.fractionLength(2))))× · \(preview.apexOffenceMultiplier.formatted(.number.precision(.fractionLength(2))))× · \(preview.apexActionSlots)")
                        ForEach(preview.finalFoes, id: \.id) { foe in
                            LabeledRow(icon: foe.isApex ? "crown.fill" : "pawprint.fill",
                                       label: "\(foeLabel(foe.id)) · final",
                                       value: "L\(foe.level) · HP \(foe.maxHP) · ATK \(foe.attack) · ARM \(foe.armour)")
                        }
                        Text("Projected opening damage and neutral rounds-to-defeat: pending simulation model.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                Section("Test Setup") {
                    let report = run.generationDiagnostics
                    LabeledRow(icon: "wrench.and.screwdriver", label: "Opening envelope requested",
                               value: report.openingEnvelopeRequested.displayName)
                    LabeledRow(icon: "arrow.triangle.swap", label: "Opening envelope result",
                               value: report.openingEnvelopeRequested == .natural ? "natural — no change"
                                   : report.openingEnvelopeApplied
                                       ? "applied · \(report.openingEnemiesRelocated) relocated"
                                       : "ignored — not a fresh first expedition")
                }
                Section("Tuning snapshot") {
                    Text(tuningSnapshot)
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                }
            }
            .navigationTitle("World diagnostics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
        }
    }

    private var tuningSnapshot: String {
        let t = run.tuning
        return [
            "Raw Essence preset: \(t.rawEssenceProfile.displayName)",
            "Raw Essence frequency: \(t.rawEssenceFrequencyMultiplier)",
            "Raw Essence yield: \(t.rawEssenceYieldMultiplier)",
            "Resource-deposit density: \(t.resourceNodeDensityMultiplier)",
            "Creature density: \(t.creatureDensityMultiplier)",
            "Diary writing share: \(t.diaryWritingShare)",
            "Additional writing chance: \(t.additionalPageChance)",
            "Diary patience: \(t.diaryPatienceWorlds) worlds",
            "Traveller arrival window: \(t.blindDiscoveryWindow)",
            "Traveller clue weight: \(t.travellerClueEvidenceWeight)",
            "Traveller authored-writing weight: \(t.travellerAuthoredEvidenceWeight)",
            "Traveller arrival floor: \(t.travellerArrivalChanceFloor)",
            "Traveller near-miss increase: \(t.travellerArrivalNearMissIncrement)",
            "World duration: \(t.stabilityDurationMultiplier)×",
            "Collapse recovery: \(t.collapseRecoveryFraction)",
            "Apex chance: \(t.apexChanceMultiplier)×",
            "Encounter scaling: \(t.encounterScalingProfile.displayName)",
            "Starting vision radius: \(t.baseVisionRadius)",
            "Slow-ground extra turns: \(t.slowGroundExtraTurns)",
            "Active-flora frequency: \(t.activeFloraFrequencyMultiplier)",
            "Flora hazard severity: \(t.floraHazardSeverityMultiplier)",
            "Opening encounter: \(t.openingEncounterEnvelope.displayName)"
        ].joined(separator: "\n")
    }
}
#endif

private struct PartyHealthStrip: View {
    let run: WorldRun
    let state: GameState

    var body: some View {
        HStack(spacing: 4) {
            health("Binder", current: run.binderHP,
                   maximum: CombatRules.health(of: .binder, in: run).max)
            ForEach(state.base.activeParty, id: \.self) { index in
                let member = state.base.roster[index]
                health(member.name,
                       current: CombatRules.health(of: .companion(index), in: run).current,
                       maximum: CombatRules.health(of: .companion(index), in: run).max)
            }
        }
        .padding(.horizontal, 8)
        .frame(height: 39)
        .foregroundStyle(PixelUITheme.text)
        .background(PixelUITheme.surface)
        .overlay(alignment: .bottom) { Rectangle().fill(PixelUITheme.edge).frame(height: 2) }
    }

    private func health(_ name: String, current: Int, maximum: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 3) {
                Text(name).lineLimit(1)
                Spacer(minLength: 2)
                Text("\(current)/\(maximum)").monospacedDigit()
            }
            .font(.custom("Tiny5", size: 10))
            GeometryReader { proxy in
                Rectangle()
                    .fill(PixelUITheme.edgeDark)
                    .overlay(alignment: .leading) {
                        Rectangle()
                            .fill(current <= maximum / 3 ? Color.red : Color.green)
                            .frame(width: proxy.size.width * min(1, max(0, Double(current) / Double(maximum))))
                    }
                    .overlay(Rectangle().stroke(PixelUITheme.edge, lineWidth: 1))
            }
            .frame(height: 5)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(name) health \(current) of \(maximum)")
    }

}

// MARK: - Header

private struct StabilityHeader: View {
    let run: WorldRun

    var body: some View {
        HStack(spacing: 10) {
            Rectangle()
                .fill(PixelUITheme.clasp)
                .frame(width: 5, height: 34)
            Text("Explore")
                .font(.custom("Jersey 10", size: 25))
                .foregroundStyle(PixelUITheme.text)
            Spacer(minLength: 4)
            VStack(alignment: .leading, spacing: 1) {
                Text("STABILITY")
                    .font(.custom("Tiny5", size: 9))
                    .foregroundStyle(PixelUITheme.muted)
                Text("\(Int(run.stability.rounded()))%")
                    .font(.custom("Tiny5", size: 11))
                    .foregroundStyle(colour)
            }
            GeometryReader { proxy in
                Rectangle()
                    .fill(PixelUITheme.edgeDark)
                    .overlay(alignment: .leading) {
                        Rectangle().fill(colour)
                            .frame(width: proxy.size.width * min(1, max(0,
                                run.stability / Tuning.World.startingStability)))
                    }
                    .overlay(Rectangle().stroke(PixelUITheme.edge, lineWidth: 1))
            }
            .frame(width: 78, height: 6)
            VStack(alignment: .trailing, spacing: 1) {
                Text("COLLAPSE")
                    .font(.custom("Tiny5", size: 9))
                    .foregroundStyle(PixelUITheme.muted)
                Text(turnsLeftText)
                    .font(.custom("Tiny5", size: 10))
                    .foregroundStyle(PixelUITheme.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                }
        }
        .padding(.horizontal, 8)
        .frame(height: 62)
        .background(PixelUITheme.headerB)
        .overlay(alignment: .bottom) { Rectangle().fill(PixelUITheme.edge).frame(height: 2) }
    }

    private var turnsLeftText: String {
        WorldDurationPresentation.status(stability: run.stability,
                                         decayPerTurn: run.decayPerTurn,
                                         collapsedOnTurn: run.collapsedOnTurn)
    }

    private var bandText: String {
        switch run.stabilityBand {
        case .stable: "holding"
        case .hazardous: "hazards at the edges"
        case .crumbling: "crumbling inward"
        case .collapsed: "collapsing"
        }
    }

    private var colour: Color {
        switch run.stabilityBand {
        case .stable: .green
        case .hazardous: .yellow
        case .crumbling: .orange
        case .collapsed: .red
        }
    }
}

// MARK: - Grid

enum WorldMapLayout {
    /// Transparent pixels in a lifted 16×19 sprite reveal this game-owned field, never the
    /// system/card background. It is the same non-informative dark used by accepted fog art.
    static let backdropRGB: [UInt8] = [23, 23, 26]

    /// Camera scale is stable and independent of sight. Visibility may extend beyond the camera;
    /// changing illumination or party sight must never resize tiles or expose the whole map.
    static func viewportColumns(mapColumns: Int, cameraColumns: Int) -> Int {
        min(max(1, mapColumns), max(1, cameraColumns))
    }

    /// The map is width-owned. Secondary chrome may make the page scroll, but it must never make
    /// the map smaller. Every cell still lands on whole device pixels.
    static func maximumSide(containerWidth: CGFloat, viewportHeight: CGFloat,
                            viewportTiles: Int, displayScale: CGFloat) -> CGFloat {
        let widthBound = max(0, containerWidth)
        _ = viewportHeight
        let tiles = CGFloat(max(1, viewportTiles))
        let scale = max(1, displayScale)
        let cellPixels = floor(widthBound * scale / tiles)
        return max(tiles, cellPixels) * tiles / scale
    }

    /// Admit only complete rows that fit, capped to the stable camera span. Extra vertical room
    /// belongs to surrounding UI; it must never zoom the camera out to reveal the whole map.
    static func viewportRows(mapWidth: CGFloat, availableHeight: CGFloat,
                             viewportColumns: Int, mapRows: Int) -> Int {
        let columns = max(1, viewportColumns)
        let tileSide = mapWidth / CGFloat(columns)
        let completeRowsThatFit = Int(floor(max(0, availableHeight) / max(1, tileSide)))
        return min(max(1, mapRows), max(1, completeRowsThatFit))
    }
}

/// The map, seen through a window that follows you.
///
/// **The map no longer has to fit one screen** (decisions-session-13 §3) — only the page does, since
/// you compose on a page and walk through a world. The camera is **clamped follow**: centred on you
/// until you reach an edge, where it stops rather than showing empty space past the border.
@MainActor private final class TerrainPresentationClock: ObservableObject {
    static let shared = TerrainPresentationClock()
    @Published private(set) var tick = 0
    private var isRunning = false

    func runWhileActive() async {
        guard !isRunning else { return }
        isRunning = true
        defer { isRunning = false }
        while !Task.isCancelled {
            do { try await Task.sleep(nanoseconds: 250_000_000) }
            catch { return }
            guard !Task.isCancelled else { return }
            tick = (tick + 1) % 24
        }
    }
}

struct TravellerSpeechBubblePlacement: Equatable {
    let center: CGPoint
    let width: CGFloat
    let height: CGFloat
    let isAboveTraveller: Bool
    let tailX: CGFloat

    static func resolve(anchor: CGPoint, stageSize: CGSize) -> Self {
        let width = min(284, max(0, stageSize.width - 16))
        let height = min(120, max(0, stageSize.height - 16))
        let above = anchor.y - height - 12 >= 8
        let centerY = above ? anchor.y - 8 - height / 2
            : min(stageSize.height - 8 - height / 2, anchor.y + 8 + height / 2)
        let centerX = min(stageSize.width - 8 - width / 2,
                          max(8 + width / 2, anchor.x))
        let left = centerX - width / 2
        return Self(center: CGPoint(x: centerX, y: centerY), width: width, height: height,
                    isAboveTraveller: above,
                    tailX: min(width - 12, max(12, anchor.x - left)))
    }
}

private struct TravellerAdjacentSpeechBubbleView: View {
    let speech: WorldTravellerSpeechBubbleV1
    let placement: TravellerSpeechBubblePlacement
    let onFinished: () -> Void
    @State private var isSettled = false
    @State private var isVisible = false

    var body: some View {
        ZStack(alignment: placement.isAboveTraveller ? .bottomLeading : .topLeading) {
            Text(speech.text)
                .font(.system(size: 17))
                .lineSpacing(4)
                .foregroundStyle(PixelUITheme.textOnEdgeDark)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(PixelUITheme.edgeDark.opacity(0.94))
                .overlay(Rectangle().stroke(PixelUITheme.edge, lineWidth: 2))
                .padding(.vertical, 6)
            Rectangle()
                .fill(PixelUITheme.edgeDark.opacity(0.94))
                .frame(width: 12, height: 12)
                .rotationEffect(.degrees(45))
                .offset(x: placement.tailX - 6,
                        y: placement.isAboveTraveller ? 0 : 0)
        }
        .offset(y: isSettled ? 0 : 6)
        .opacity(isVisible ? 1 : 0)
        .animation(.easeOut(duration: isVisible ? 0.18 : 0.16), value: isVisible)
        .allowsHitTesting(false)
        .task(id: speech.travellerID) {
            isVisible = true
            isSettled = true
            do { try await Task.sleep(nanoseconds: 180_000_000) }
            catch { return }
            guard !Task.isCancelled else { return }
            do { try await Task.sleep(nanoseconds: 4_800_000_000) }
            catch { return }
            guard !Task.isCancelled else { return }
            isVisible = false
            do { try await Task.sleep(nanoseconds: 160_000_000) }
            catch { return }
            guard !Task.isCancelled else { return }
            onFinished()
        }
    }
}

private struct MapGrid: View {
    let run: WorldRun
    let maximumWidth: CGFloat
    let viewportColumns: Int
    let viewportRows: Int
    let visibilityProfile: WorldRules.VisibilityProfile
    let travellerSpeech: WorldTravellerSpeechBubbleV1?
    let onTravellerSpeechFinished: (TravellerID) -> Void
    let onTap: (GridPoint) -> Void
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var terrainClock = TerrainPresentationClock.shared
#if DEBUG
    @AppStorage("debug.simpleMapRenderer") private var useSimpleRenderer = false
#endif

    /// Top-left of the window: centred on the player, then clamped to the map.
    private var origin: GridPoint {
        GridPoint(x: clamp(run.playerPosition.x - viewportColumns / 2,
                           extent: run.map.width, viewport: viewportColumns),
                  y: clamp(run.playerPosition.y - viewportRows / 2,
                           extent: run.map.height, viewport: viewportRows))
    }

    private func clamp(_ value: Int, extent: Int, viewport: Int) -> Int {
        max(0, min(value, extent - viewport))
    }

    var body: some View {
        GeometryReader { proxy in
            let side = proxy.size.width / CGFloat(viewportColumns)
            let readings = BookRules.readings(for: run.book, seed: run.mapSeed)
            let grade = WorldGrade.from(readings)
            let atmosphereMotion = Int(readings["atmosphere"].aspect("motion")
                .rounded(.toNearestOrAwayFromZero))
            ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                ForEach(origin.y..<(origin.y + viewportRows), id: \.self) { y in
                    HStack(spacing: 0) {
                        ForEach(origin.x..<(origin.x + viewportColumns), id: \.self) { x in
                            let point = GridPoint(x: x, y: y)
                            let currentVisibility = WorldRules.visibility(
                                of: point, from: run.playerPosition,
                                in: run.map, profile: visibilityProfile)
                            let wasExplored = run.map[point].isRevealed
                            let visibility = WorldRules.terrainVisibility(
                                current: currentVisibility, wasRevealed: wasExplored)
                            let isRememberedTerrain = currentVisibility == .hidden
                                && visibility == .fringe
                            let unexploredFringeGradient = UnexploredFringeGradient.resolve(
                                tile: point, player: run.playerPosition,
                                visibility: currentVisibility, wasExplored: wasExplored,
                                profile: visibilityProfile)
                            let showsStationaryContents = currentVisibility == .full || wasExplored
                            let usesRememberedStationaryIdentity =
                                ExplorationMapIdentityResolver.usesRememberedFrame(
                                    currentVisibility: currentVisibility,
                                    disclosed: showsStationaryContents)
                            let displayTile = displayTile(at: point, visibility: visibility)
                            let presentation = WorldTileVisibilityPresentation.resolve(
                                run: run, point: point, tile: displayTile, visibility: visibility,
                                profile: visibilityProfile, grade: grade,
                                atmosphereMotion: atmosphereMotion,
                                presentationTick: terrainClock.tick,
                                isRememberedTerrain: isRememberedTerrain,
                                showsStationaryContents: showsStationaryContents)
                            TileView(tile: displayTile,
                                     point: point,
                                     visibility: visibility,
                                     isRememberedTerrain: isRememberedTerrain,
                                     usesRememberedStationaryIdentity:
                                        usesRememberedStationaryIdentity,
                                     unexploredFringeGradient: unexploredFringeGradient,
                                     showsStationaryContents: showsStationaryContents,
                                     visibilityProfile: visibilityProfile,
                                     artRequest: presentation.artRequest,
                                     fogBoundaryEdges: presentation.fogBoundaryEdges,
                                     enemy: enemy(at: point, visibility: currentVisibility),
                                     site: showsStationaryContents ? site(at: point) : nil,
									 siteLooted: showsStationaryContents ? placedSite(at: point)?.isLooted : nil,
                                     hasLooseWorldPage: showsStationaryContents
                                        && run.offeredWorldPages.contains {
                                            $0.fieldProvenance?.position == point
                                        },
                                     isPlayer: point == run.playerPosition,
                                     side: side,
									 presentationTick: terrainClock.tick,
                                     useSimpleRenderer: simpleRenderer)
                                .onTapGesture { onTap(point) }
                        }
                    }
                    .zIndex(Double(y))
                }
            }
            if let speech = travellerSpeech,
               speech.worldRunID == "\(run.runIndex):\(run.mapSeed)" {
                let anchor = CGPoint(
                    x: (CGFloat(speech.point.x - origin.x) + 0.5) * side,
                    y: (CGFloat(speech.point.y - origin.y) + 0.5) * side)
                let placement = TravellerSpeechBubblePlacement.resolve(
                    anchor: anchor, stageSize: proxy.size)
                TravellerAdjacentSpeechBubbleView(
                    speech: speech, placement: placement,
                    onFinished: { onTravellerSpeechFinished(speech.travellerID) })
                    .frame(width: placement.width, height: placement.height)
                    .position(x: placement.center.x, y: placement.center.y)
                    .transition(.opacity)
                    .zIndex(10_000)
            }
            }
#if DEBUG
            .background(WorldMapViewportProbe(
                mapWidth: maximumWidth, viewportRows: viewportRows)
                .frame(width: proxy.size.width, height: proxy.size.height))
#endif
        }
        .frame(width: maximumWidth,
               height: maximumWidth / CGFloat(viewportColumns) * CGFloat(viewportRows))
        .frame(maxWidth: .infinity)
        .background(
            Color(red: Double(WorldMapLayout.backdropRGB[0]) / 255,
                  green: Double(WorldMapLayout.backdropRGB[1]) / 255,
                  blue: Double(WorldMapLayout.backdropRGB[2]) / 255)
        )
        .clipped()
        .anchorPreference(key: MiningAnchorReceiptKey.self, value: .bounds) {
            MiningAnchorReceipt(mapViewport: $0,
                                sourceUnitFrames: miningSourceUnitFrames)
        }
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            await terrainClock.runWhileActive()
        }
    }

    private var simpleRenderer: Bool {
#if DEBUG
        useSimpleRenderer
#else
        false
#endif
    }

    /// Exact logical tile frames inside the rendered, edge-clamped MapGrid viewport. The root
    /// resolves these normalized frames through the map's own bounds anchor, so mining feedback
    /// never guesses a screen coordinate or depends on a sibling toolbar layout.
    private var miningSourceUnitFrames: [GridPoint: CGRect] {
        var result: [GridPoint: CGRect] = [:]
        let width = CGFloat(viewportColumns)
        let height = CGFloat(viewportRows)
        for y in origin.y..<(origin.y + viewportRows) {
            for x in origin.x..<(origin.x + viewportColumns) {
                let point = GridPoint(x: x, y: y)
                result[point] = CGRect(
                    x: CGFloat(x - origin.x) / width,
                    y: CGFloat(y - origin.y) / height,
                    width: 1 / width, height: 1 / height)
            }
        }
        return result
    }

    private func displayTile(at point: GridPoint,
                             visibility: WorldRules.TileVisibility) -> Tile {
        var tile = run.map[point]
        switch visibility {
        case .full:
            tile.isRevealed = true
        case .fringe:
            tile.isRevealed = true
            if !run.map[point].isRevealed {
                tile.content = .empty
                tile.flora = nil
            }
            tile.isCracking = false
        case .hidden:
            tile.isRevealed = false
            tile.content = .empty
            tile.flora = nil
            tile.isCracking = false
        }
        return tile
    }


    /// Cryptic creatures don't show until they're on you — see `WorldRules.isVisible`.
    private func enemy(at point: GridPoint,
                       visibility: WorldRules.TileVisibility) -> WorldEnemy? {
        guard visibility == .full else { return nil }
        return run.enemies.first {
            $0.position == point && WorldRules.isVisible($0, in: run)
        }
    }

    private func site(at point: GridPoint) -> SiteDef? {
        run.sites.first { $0.position == point }?.definition
    }

    private func placedSite(at point: GridPoint) -> PlacedSite? {
        run.sites.first { $0.position == point }
    }
}

struct FogBoundaryEdges: OptionSet, Equatable {
    let rawValue: Int
    static let north = Self(rawValue: 1)
    static let east = Self(rawValue: 2)
    static let south = Self(rawValue: 4)
    static let west = Self(rawValue: 8)
}

struct WorldTileVisibilityPresentation {
    let artRequest: MapTileArtRequest?
    let fogBoundaryEdges: FogBoundaryEdges

    static func resolve(run: WorldRun, point: GridPoint, tile: Tile,
                        visibility: WorldRules.TileVisibility,
                        profile: WorldRules.VisibilityProfile,
                        grade: WorldGrade,
                        atmosphereMotion: Int = 0,
                        presentationTick: Int = 0,
                        isRememberedTerrain: Bool = false,
                        showsStationaryContents: Bool = false) -> Self {
        guard visibility != .hidden else {
            return Self(artRequest: nil, fogBoundaryEdges: [])
        }

        let neighbours: [(direction: TerrainProductionPack.Direction,
                          edge: FogBoundaryEdges, point: GridPoint)] = [
            (.north, .north, GridPoint(x: point.x, y: point.y - 1)),
            (.east, .east, GridPoint(x: point.x + 1, y: point.y)),
            (.south, .south, GridPoint(x: point.x, y: point.y + 1)),
            (.west, .west, GridPoint(x: point.x - 1, y: point.y)),
        ]
        var cardinal = TerrainProductionPack.Cardinal<TerrainProductionPack.Neighbor>(
            north: .unknown, east: .unknown, south: .unknown, west: .unknown)
        var contours = TerrainProductionPack.Cardinal<Int>(north: 0, east: 0, south: 0, west: 0)
        var shades = TerrainProductionPack.Cardinal<Int>(north: 0, east: 0, south: 0, west: 0)
        var southWallDepth = 0
        var fogBoundaryEdges: FogBoundaryEdges = []

        for neighbour in neighbours {
            contours[neighbour.direction] = MapAssetContract.edgeContourID(
                mapSeed: run.mapSeed, point: point, direction: neighbour.direction)
            guard run.map.contains(neighbour.point) else {
                fogBoundaryEdges.insert(neighbour.edge)
                continue
            }
            let currentNeighbourVisibility = WorldRules.visibility(
                of: neighbour.point, from: run.playerPosition,
                in: run.map, profile: profile)
            let neighbourVisibility = WorldRules.terrainVisibility(
                current: currentNeighbourVisibility,
                wasRevealed: run.map[neighbour.point].isRevealed)
            guard neighbourVisibility != .hidden else {
                // Unknown means no boundary layer and, critically, no hidden fact read.
                fogBoundaryEdges.insert(neighbour.edge)
                continue
            }
            let visibleTile = run.map[neighbour.point]
            cardinal[neighbour.direction] = visibleTile.ground == tile.ground
                ? .same : .ground(.init(visibleTile.ground))
            let centreElevation = MapAssetContract.resolvedElevation(for: tile)
            let neighbourElevation = MapAssetContract.resolvedElevation(for: visibleTile)
            shades[neighbour.direction] = min(2, max(0, neighbourElevation - centreElevation))
            if neighbour.direction == .south {
                southWallDepth = min(3, max(0, centreElevation - neighbourElevation))
            }
        }

        func disclosedWallDepth(at higherPoint: GridPoint) -> Int? {
            let lowerPoint = GridPoint(x: higherPoint.x, y: higherPoint.y + 1)
            guard run.map.contains(higherPoint), run.map.contains(lowerPoint) else { return nil }
            func disclosed(_ candidate: GridPoint) -> Bool {
                let current = WorldRules.visibility(
                    of: candidate, from: run.playerPosition, in: run.map, profile: profile)
                return WorldRules.terrainVisibility(
                    current: current, wasRevealed: run.map[candidate].isRevealed) != .hidden
            }
            guard disclosed(higherPoint), disclosed(lowerPoint) else { return nil }
            let higher = run.map[higherPoint], lower = run.map[lowerPoint]
            return min(3, max(0, MapAssetContract.resolvedElevation(for: higher)
                               - MapAssetContract.resolvedElevation(for: lower)))
        }

        func continuesWall(dx: Int) -> Bool {
            guard southWallDepth > 0 else { return false }
            let adjacent = GridPoint(x: point.x + dx, y: point.y)
            guard run.map.contains(adjacent), run.map[adjacent].ground == tile.ground,
                  MapAssetContract.resolvedElevation(for: run.map[adjacent])
                    == MapAssetContract.resolvedElevation(for: tile),
                  let depth = disclosedWallDepth(at: adjacent) else { return false }
            return depth > 0
        }

        let flora = showsStationaryContents
            ? tile.flora.flatMap { id in run.flora.first { $0.id == id } }
            : nil
        let packVisibility: TerrainProductionPack.Visibility = if visibility == .full {
            .full
        } else if isRememberedTerrain {
            .remembered
        } else {
            .fringe
        }
        let request = MapTileArtRequest(
            tile: tile, point: point, mapSeed: run.mapSeed, runIndex: run.runIndex,
            cardinalNeighbors: cardinal, edgeContourIDs: contours,
            contactShadeDepths: shades, southWallDepth: southWallDepth,
            wallWestContinuation: continuesWall(dx: -1),
            wallEastContinuation: continuesWall(dx: 1),
            visibility: packVisibility,
            surfaceDeposits: .init(
                snow: tile.surfaceDeposits.snow,
                settledAsh: tile.surfaceDeposits.settledAsh),
            grade: grade,
            flora: flora,
            worldGrade2Descriptor: run.worldVisualReceipt?.descriptor,
            atmosphereMotion: atmosphereMotion, presentationTick: presentationTick)
        return Self(artRequest: request, fogBoundaryEdges: fogBoundaryEdges)
    }

    static func opaqueFogPixels() -> [UInt8] {
        Array(repeating: [UInt8(0), 0, 0, 255],
              count: MapAssetContract.spriteWidth * MapAssetContract.spriteHeight)
            .flatMap { $0 }
    }

    static func fringeOpacity(profile: WorldRules.VisibilityProfile,
                              remembered: Bool) -> Double {
        _ = remembered
        // Distance cannot make terrain brighter. Current fringe and remembered terrain share the
        // same atmosphere-resolved brightness, preventing a dark ring followed by a brighter map.
        return profile.fringeOpacity
    }

}

struct UnexploredFringeGradient: Equatable {
    let startX: Double
    let startY: Double
    let endX: Double
    let endY: Double
    let startOpacity: Double
    let endOpacity: Double

    static func resolve(tile: GridPoint, player: GridPoint,
                        visibility: WorldRules.TileVisibility, wasExplored: Bool,
                        profile: WorldRules.VisibilityProfile) -> Self? {
        guard visibility == .fringe, !wasExplored, profile.fringeWidth > 0 else { return nil }
        let dx = Double(tile.x - player.x)
        let dy = Double(tile.y - player.y)
        let distance = sqrt(dx * dx + dy * dy)
        guard distance > 0 else { return nil }

        let unitX = dx / distance
        let unitY = dy / distance
        let innerBoundary = Double(profile.fullRadius) + 0.5
        let width = Double(profile.fringeWidth)
        let startOpacity = min(1, max(0, (distance - 0.5 - innerBoundary) / width))
        let endOpacity = min(1, max(0, (distance + 0.5 - innerBoundary) / width))
        return Self(startX: 0.5 - unitX * 0.5,
                    startY: 0.5 - unitY * 0.5,
                    endX: 0.5 + unitX * 0.5,
                    endY: 0.5 + unitY * 0.5,
                    startOpacity: startOpacity,
                    endOpacity: endOpacity)
    }
}

private struct TileView: View {
    let tile: Tile
    let point: GridPoint
    let visibility: WorldRules.TileVisibility
    let isRememberedTerrain: Bool
    let usesRememberedStationaryIdentity: Bool
    let unexploredFringeGradient: UnexploredFringeGradient?
    let showsStationaryContents: Bool
    let visibilityProfile: WorldRules.VisibilityProfile
    let artRequest: MapTileArtRequest?
    let fogBoundaryEdges: FogBoundaryEdges
    let enemy: WorldEnemy?
    /// Resolved by the caller: the tile only stores an instance id, and the grid is the one place
    /// that has the run to look it up in.
    let site: SiteDef?
	let siteLooted: Bool?
    let hasLooseWorldPage: Bool
    let isPlayer: Bool
    let side: CGFloat
	let presentationTick: Int
    let useSimpleRenderer: Bool

    var body: some View {
        ZStack(alignment: .top) {
            if visibility == .hidden {
                Rectangle().fill(Color.black)
            } else if useSimpleRenderer {
                terrainLayer
            } else if artRequest != nil {
                terrainLayer
            }
            if let gradient = unexploredFringeGradient {
                Rectangle().fill(
                    LinearGradient(
                        colors: [.black.opacity(gradient.startOpacity),
                                 .black.opacity(gradient.endOpacity)],
                        startPoint: UnitPoint(x: gradient.startX, y: gradient.startY),
                        endPoint: UnitPoint(x: gradient.endX, y: gradient.endY)
                    )
                )
                .allowsHitTesting(false)
            }
            ZStack {
                // The player gets a filled disc behind them: at 27pt a bare glyph disappears into
                // the grid, and "where am I" has to be answerable at a glance.
                if isPlayer {
                    Circle()
                        .fill(Color.accentColor)
                        .padding(side * 0.14)
                }
                if let enemy, case .alert = enemy.awareness {
                    Circle()
                        .stroke(Color.orange, style: StrokeStyle(lineWidth: max(2, side * 0.08), dash: [3, 2]))
                        .padding(side * 0.08)
                }
                if case .traveller(let travellerID) = tile.content,
                   visibility == .full, tile.isRevealed, !tile.isCrumbled {
                    let traveller = ContentCatalog.shared.traveller(travellerID)
                    NamedCharacterMapPixelIdentity(
                        travellerID: travellerID,
                        facing: .south,
                        fallbackSystemIcon: traveller?.icon ?? "figure.wave",
                        fallbackColor: .green
                    )
                    .frame(width: side * 0.72, height: side * 0.72)
                } else if let assetKey,
                          let image = ExplorationMapIdentityPack.image(key: assetKey) {
					let assetSize = ExplorationMapIdentityLayout.mapAssetSize(tileSide: side)
					Image(uiImage: image).resizable().interpolation(.none).antialiased(false)
						.frame(width: assetSize.width, height: assetSize.height)
						.frame(width: side, height: side, alignment: .bottom)
                } else if let symbol {
					Image(systemName: symbol)
						.font(.system(size: side * (isPlayer ? 0.46 : 0.54), weight: isPlayer ? .bold : .regular))
						.foregroundStyle(tint)
                }
            }
            .frame(width: side, height: side)
            .offset(y: surfaceLift)

            // Alert punctuation is a floating UI badge, not something painted on the ground.
            if let enemy, case .alert = enemy.awareness {
                Image(systemName: "exclamationmark")
                    .font(.system(size: side * 0.28, weight: .black))
                    .foregroundStyle(.orange)
                    .offset(x: side * 0.30, y: -side * 0.30)
            }
        }
        // Dim only pixels that actually exist. A black rectangle here would also fill the lifted
        // sprite's transparent padding, producing false bands on remembered terrain.
        .colorMultiply(visibility == .fringe ? fringeBrightness : .white)
        .frame(width: side, height: side)
        .contentShape(Rectangle())
    }

    private var fringeBrightness: Color {
        let value = WorldTileVisibilityPresentation.fringeOpacity(
            profile: visibilityProfile, remembered: isRememberedTerrain)
        return Color(red: value, green: value, blue: value)
    }

    @ViewBuilder private var terrainLayer: some View {
        Group {
            if useSimpleRenderer {
                ZStack {
                    Rectangle().fill(background)
                    if tile.isRevealed && tile.isCracking && !tile.isCrumbled {
                        SimpleCrackShape()
                            .stroke(Color.orange.opacity(0.95),
                                    style: StrokeStyle(lineWidth: max(1, side * 0.07),
                                                       lineCap: .round, lineJoin: .round))
                            .padding(side * 0.12)
                    }
                }
            } else if let artRequest {
                MapTileArt(request: artRequest)
                    .frame(width: side,
                           height: side * CGFloat(MapAssetContract.spriteHeight)
                               / CGFloat(MapAssetContract.logicalSide))
                    .offset(y: -side * CGFloat(MapAssetContract.maximumElevation)
                            / CGFloat(MapAssetContract.logicalSide))
            }
        }
        .blur(radius: visibility == .full
              ? 0 : CGFloat(visibilityProfile.atmosphericBlurPoints))
    }

    private var surfaceLift: CGFloat {
        guard !useSimpleRenderer, let artRequest else { return 0 }
        return -side * CGFloat(artRequest.resolvedElevation)
            / CGFloat(MapAssetContract.logicalSide)
    }

    private var symbol: String? {
        if isPlayer { return "figure.stand" }
        guard showsStationaryContents, tile.isRevealed, !tile.isCrumbled else { return nil }
        if let enemy { return enemy.icon }
        if hasLooseWorldPage { return "doc.text.fill" }
        switch tile.content {
        case .empty: return nil
        case .item(let stack): return ContentCatalog.shared.item(stack.catalogID)?.icon ?? "shippingbox.fill"
        case .node(let node): return useSimpleRenderer ? (ContentCatalog.shared.resource(node.resource)?.icon ?? "cube") : nil
        case .wildDrop: return useSimpleRenderer ? "sparkle" : nil
        case .hazard: return "exclamationmark.triangle.fill"
        case .portal(let isEntry): return isEntry ? "arrow.down.left.circle" : "circle.circle"
        case .lockedCache: return "lock.fill"
        case .diaryPage: return "doc.text"
        case .foundWriting: return "note.text"
        case .site: return site?.icon ?? "building.columns"
        // Named travellers are rendered by exact persisted identity in `body`.
        case .traveller: return nil
        }
    }

	private var assetKey: String? {
		guard !isPlayer, enemy == nil, showsStationaryContents else { return nil }
		return ExplorationMapIdentityResolver.key(
			tile: tile, site: site, siteLooted: siteLooted,
			hasLooseWorldPage: hasLooseWorldPage, tick: presentationTick,
			disclosed: showsStationaryContents,
			remembered: usesRememberedStationaryIdentity)
	}

    private var tint: Color {
        if isPlayer { return Palette.mapFloor }
        if enemy != nil { return .red }
        if hasLooseWorldPage { return .indigo }
        switch tile.content {
        case .item: return .yellow
        case .hazard: return .orange
        case .portal: return .blue
        case .lockedCache: return .purple
        case .wildDrop: return .teal
        case .diaryPage: return .indigo
        case .foundWriting: return .cyan
        case .site: return site?.category == .hazard ? .orange : .brown
        // Green, and nothing else on the map is green. A person standing in a world you wrote is
        // the single most interesting thing on the grid and has to look like it.
        case .traveller: return .green
        default: return .primary.opacity(0.7)
        }
    }

    /// The ground under everything. Elevation darkens it, so high country reads as high country.
    private var groundColour: Color {
        let base: Color = switch tile.ground {
        case .stone: Color(red: 0.55, green: 0.55, blue: 0.58)
        case .soil: Color(red: 0.45, green: 0.38, blue: 0.28)
        case .sand: Color(red: 0.80, green: 0.72, blue: 0.52)
        case .ice: Color(red: 0.78, green: 0.87, blue: 0.92)
        case .ash: Color(red: 0.38, green: 0.36, blue: 0.36)
        case .water: Color(red: 0.30, green: 0.52, blue: 0.72)
        case .deepWater: Color(red: 0.16, green: 0.30, blue: 0.52)
        case .rubble: Color(red: 0.50, green: 0.46, blue: 0.42)
        case .mud: Color(red: 0.31, green: 0.25, blue: 0.18)
        case .growth: Color(red: 0.30, green: 0.48, blue: 0.28)
        // Lighter and yellower than a thicket — you can see over it, and it should look like you
        // can. The difference has to be legible at a glance or the sightline rule is a surprise.
        case .groundcover: Color(red: 0.47, green: 0.58, blue: 0.34)
        case .chasm: Color(red: 0.06, green: 0.06, blue: 0.09)
        }
        return base.opacity(1 - Double(tile.elevation) * 0.13)
    }

    /// Three clearly distinct states in both schemes — see `Palette` for why these can't be
    /// opacities over `.primary`: the meaning inverts in dark mode.
    private var background: Color {
        if tile.isCrumbled { return Palette.mapVoid }
        // Unseen ground stays fog; seen ground shows what it's made of.
        return tile.isRevealed ? groundColour : Palette.mapFog
    }
}

#if DEBUG
@MainActor extension MapAssetTestSupport {
    /// Mounts the production content branch with the normal renderer. The outer inset preserves
    /// the approved 16×19 bottom-pivot overhang around its 16×16 tile surface.
    static func mountedStationaryIdentity(
        content: TileContent,
        visibility: WorldRules.TileVisibility = .full,
        revealed: Bool = true,
        disclosed: Bool = true,
        presentationTick: Int = 0,
        tileSide: CGFloat = 32,
        inset: CGFloat = 8
    ) -> AnyView {
        let tile = Tile(content: content, ground: .soil, isRevealed: revealed)
        return AnyView(
            TileView(
                tile: tile, point: GridPoint(x: 0, y: 0), visibility: visibility,
                isRememberedTerrain: visibility != .full,
                usesRememberedStationaryIdentity: visibility != .full,
                unexploredFringeGradient: nil,
                showsStationaryContents: disclosed,
                visibilityProfile: WorldRules.visibilityProfile(
                    illumination: 100, baseRadius: 1),
                artRequest: nil, fogBoundaryEdges: [], enemy: nil,
                site: nil, siteLooted: nil, hasLooseWorldPage: false,
                isPlayer: false, side: tileSide,
                presentationTick: presentationTick, useSimpleRenderer: false)
                .frame(width: tileSide, height: tileSide)
                .frame(width: tileSide + inset * 2,
                       height: tileSide * 19 / 16 + inset * 2,
                       alignment: .center)
        )
    }
}
#endif

/// DEBUG fallback only. The native renderer uses the frozen 16px crack command grammar.
private struct SimpleCrackShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX * 0.9, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX * 1.12, y: rect.height * 0.32))
        path.addLine(to: CGPoint(x: rect.midX * 0.78, y: rect.height * 0.56))
        path.addLine(to: CGPoint(x: rect.midX * 1.05, y: rect.maxY))
        path.move(to: CGPoint(x: rect.midX * 0.78, y: rect.height * 0.56))
        path.addLine(to: CGPoint(x: rect.width * 0.18, y: rect.height * 0.72))
        path.move(to: CGPoint(x: rect.midX * 1.12, y: rect.height * 0.32))
        path.addLine(to: CGPoint(x: rect.width * 0.82, y: rect.height * 0.18))
        return path
    }
}

// MARK: - Controls

private enum Direction: CaseIterable {
    case up, right, down, left

    var dx: Int { switch self { case .left: -1; case .right: 1; default: 0 } }
    var dy: Int { switch self { case .up: -1; case .down: 1; default: 0 } }
    var icon: String {
        switch self {
        case .up: "chevron.up"
        case .right: "chevron.right"
        case .down: "chevron.down"
        case .left: "chevron.left"
        }
    }
}

/// The one-handed movement control. Optional in the brief; here it's the primary one, because a
/// 14×14 grid of 27pt tiles can't be.
private struct DirectionPad: View {
    var isLooking = false
    @ObservedObject var coordinator: WorldControlAttemptCoordinator
    let snapshot: () -> WorldControlSnapshot
    let onStep: (Direction) -> WorldControlExecution

    var body: some View {
        VStack(spacing: 4) {
            padButton(.up)
            HStack(spacing: 4) {
                padButton(.left)
                Color.clear.frame(width: 46, height: 46)
                padButton(.right)
            }
            padButton(.down)
        }
    }

    private func padButton(_ direction: Direction) -> some View {
        let action: WorldControlAction = isLooking
            ? .look(dx: direction.dx, dy: direction.dy)
            : .move(dx: direction.dx, dy: direction.dy)
        return WorldWholeFaceControl(
            coordinator: coordinator, action: action, snapshot: snapshot,
            disabledReason: nil, operation: { onStep(direction) }) {
            Image(systemName: direction.icon)
                .font(.headline)
                .frame(width: 46, height: 46) // ≥44pt
                .foregroundStyle(PixelUITheme.text)
                .background(PixelUITheme.neutral)
                .overlay(Rectangle().stroke(PixelUITheme.edgeDark, lineWidth: 2))
        }
        .accessibilityLabel("\(isLooking ? "Look" : "Move") \(direction.accessibilityName)")
    }
}

private extension Direction {
    var accessibilityName: String {
        switch self { case .up: "north"; case .right: "east"; case .down: "south"; case .left: "west" }
    }
}

private struct InspectionPresentation: Identifiable {
    let id = UUID()
    let value: WorldRules.TileInspection
}

private struct ActionButton: View {
    let title: String
    let icon: String
    var detail: String?
    var isProminent: Bool = false
    var isEnabled: Bool = true
    let action: () -> Void

    init(_ title: String, icon: String, detail: String? = nil,
         isProminent: Bool = false, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.detail = detail
        self.isProminent = isProminent
        self.isEnabled = isEnabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                VStack(alignment: .leading, spacing: 0) {
                    Text(title).font(.caption.weight(.semibold)).lineLimit(1)
                    if let detail {
                        Text(detail).font(.caption2).foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: WorldControlsLayout.actionHeight)
            .padding(.horizontal, 6)
            .contentShape(Rectangle())
        }
        .frame(maxWidth: .infinity, minHeight: WorldControlsLayout.actionHeight)
        .buttonStyle(.bordered)
        .tint(isProminent ? .accentColor : .secondary)
        .disabled(!isEnabled)
    }
}

#Preview {
    WorldView().environmentObject(GameStore(io: .temporary(name: "preview-world")))
}


/// A truthful inventory of what crossed the threshold. Instruments are fixed for the trip;
/// consumables can be used here, outside combat, for one world turn.
private struct FieldKitSheet: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss
    @State private var section: FieldKitSection = .instruments
    @State private var selectedSupply: ItemStack?

    private enum FieldKitSection: String, CaseIterable, Identifiable {
        case instruments = "Instruments"
        case supplies = "Supplies"
        var id: Self { self }
    }

    private var instruments: [PressureTargetDef] {
        ContentCatalog.shared.pressureTargetsInOrder.filter {
            store.activeRun?.carriedInstruments.contains($0.id) == true
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Field Kit section", selection: $section) {
                    ForEach(FieldKitSection.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                Divider()

                ScrollView {
                    Group {
                        switch section {
                        case .instruments: instrumentTray
                        case .supplies: supplyTray
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Field Kit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Back") { dismiss() } }
            }
        }
        .presentationDetents([.medium, .large])
    }

    @ViewBuilder private var instrumentTray: some View {
        if instruments.isEmpty {
            ContentUnavailableView("No instruments packed", systemImage: "gauge.with.dots.needle.33percent",
                                   description: Text("Choose next trip's instruments at Mara's Survey Post."))
                .frame(maxWidth: .infinity, minHeight: 180)
        } else {
            LazyVGrid(columns: instrumentColumns, spacing: 10) {
                ForEach(instruments) { target in
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: target.icon)
                            .font(.title2)
                            .foregroundStyle(.tint)
                            .frame(width: 36, height: 36)
                        Text(target.name)
                            .font(.caption.weight(.semibold))
                            .lineLimit(2)
                        Text("Carried")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
                    .padding(10)
                    .background(.secondary.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(target.name), instrument, carried")
                }
            }
            Text("Choose next trip's instruments at Mara's Survey Post.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)
        }
    }

    @ViewBuilder private var supplyTray: some View {
        if store.carriedConsumables.isEmpty {
            ContentUnavailableView("No supplies carried", systemImage: "shippingbox",
                                   description: Text("Prepare the next Field Kit at home."))
                .frame(maxWidth: .infinity, minHeight: 180)
        } else {
            SixAcrossItemGrid(data: store.carriedConsumables, id: \.id) { stack in
                AnchoredItemDetailButton(item: stack, selection: $selectedSupply) {
                    ItemIconTile(
                        icon: ContentCatalog.shared.item(stack.catalogID)?.icon ?? "sparkles",
                        catalogueID: stack.catalogID,
                        rarity: ContentCatalog.shared.item(stack.catalogID)?.rarity ?? .common,
                        quantity: stack.count,
                        identified: stack.identified,
                        location: .carried,
                        accessibilityName: stack.displayName
                    )
                } detail: { selected in
                    supplyDetail(selected)
                }
            }
            Text("Select a supply to inspect its effect and choose a target.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 6)
        }
    }

    @ViewBuilder private func supplyDetail(_ stack: ItemStack) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                CatalogueItemPixelIdentity(
                    itemID: stack.catalogID,
                    identified: stack.identified,
                    fallbackSystemIcon: ContentCatalog.shared.item(stack.catalogID)?.icon ?? "sparkles",
                    fallbackColor: ContentCatalog.shared.item(stack.catalogID)?.rarity.tint ?? .secondary
                )
                .frame(width: 40, height: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text(stack.displayName).font(.headline)
                    Text("Carried ×\(stack.count)").font(.caption).foregroundStyle(.secondary)
                }
            }

            Text(fieldEffectDetail(stack.catalogID))
                .font(.callout)
                .foregroundStyle(.secondary)

            if stack.catalogID == Items.scentMask, let run = store.activeRun {
                Text(run.isScentMasked
                     ? "Masked scent · \(run.scentMaskTurnsRemaining) turns remain"
                     : "Ready · masks scent for 12 turns")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(run.isScentMasked ? Color.orange : Color.green)
                    .accessibilityIdentifier("field-kit.scent-mask.status")
            }

            Divider()

            if ContentCatalog.shared.item(stack.catalogID)?.consumable?.effect == .heal {
                Text("Use on").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                ForEach(store.partyMembers) { member in
                    Button {
                        store.useItemInWorld(stack, on: member)
                        dismiss()
                    } label: {
                        LabeledRow(icon: "heart.fill", label: store.name(of: member),
                                   value: health(of: member))
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.bordered)
                }
            } else if ContentCatalog.shared.item(stack.catalogID)?.consumable?.effect == .identifyCurio {
                if store.carriedUnidentifiedCurios.isEmpty {
                    Text("No unidentified curios carried.").foregroundStyle(.secondary)
                } else {
                    Text("Identify").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                    ForEach(store.carriedUnidentifiedCurios) { curio in
                        Button {
                            store.useSolventInWorld(stack, on: curio)
                            dismiss()
                        } label: {
                            LabeledRow(icon: curio.icon, label: curio.displayName, value: "identify")
                                .frame(minHeight: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.bordered)
                    }
                }
            } else if stack.catalogID == Items.scentMask,
                      let run = store.activeRun, run.isScentMasked {
                Button("Already masked · \(run.scentMaskTurnsRemaining) turns remain") {}
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .disabled(true)
                    .accessibilityIdentifier("field-kit.scent-mask.use")
            } else {
                Button(stack.catalogID == Items.scentMask ? "Apply Scent Mask" : "Use now") {
                    store.useItemInWorld(stack, on: .binder)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity, minHeight: 44)
                .accessibilityIdentifier(stack.catalogID == Items.scentMask
                                         ? "field-kit.scent-mask.use" : "field-kit.supply.use")
            }
        }
        .padding(14)
        .frame(minWidth: 280, idealWidth: 320, maxWidth: 340, alignment: .topLeading)
    }

    private var instrumentColumns: [GridItem] {
        [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10),
         GridItem(.flexible())]
    }

    private func health(of member: PartyMember) -> String {
        guard let run = store.state.worlds.activeRun else { return "" }
        let hp = CombatRules.health(of: member.combatant, in: run)
        return "\(hp.current) / \(hp.max)"
    }

    private func fieldEffectDetail(_ id: ItemID) -> String {
        switch ContentCatalog.shared.item(id)?.consumable?.effect {
        case .heal: "Restore health to one party member."
        case .restoreStability: "Restore Stability."
        case .returnHome: "Return home with the full haul."
        case .lightWorld: "Raise the party's vision."
        case .farsight: "Reveal the nearest site."
        case .lureCreature: "Draw the nearest creature closer."
        case .identifyCurio: "Identify one carried curio."
        case .maskScent: "Animals relying only on scent hesitate for one action. Other senses and close contact still detect you. It does not hide creatures or affect apexes."
        default: ""
        }
    }
}
