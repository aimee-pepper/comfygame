import CryptoKit
import SwiftUI
import UIKit
import XCTest
@testable import Bookbinder

/// Worldgen determinism, movement, decay, and the rules that end a run.
final class WorldTests: XCTestCase {
    @MainActor
    private func controlSnapshot(mutation: Int = 1, turn: Int = 0,
                                 position: GridPoint = .init(x: 1, y: 1)) -> WorldControlSnapshot {
        .init(mutationCount: mutation, runIndex: 1, mapSeed: 99,
              turn: turn, position: position)
    }

    @MainActor private func descendants(_ view: UIView) -> [UIView] {
        [view] + view.subviews.flatMap(descendants)
    }

    private func comparableStateBytes(_ state: GameState) throws -> Data {
        var copy = state
        copy.meta.lastSavedAt = nil
        return try SaveCodec.encode(copy)
    }

    @MainActor
    func testCR01MountedWholeFaceCenterAndCornersActivateOneControl() throws {
        let coordinator = WorldControlAttemptCoordinator()
        let snapshot = controlSnapshot()
        var activations = 0
        let controller = UIHostingController(rootView: WorldWholeFaceControl(
            coordinator: coordinator, action: .fieldKit, snapshot: { snapshot },
            disabledReason: nil, operation: {
                activations += 1
                return .completed(.openedFieldKit)
            }, label: { Rectangle().fill(Color.blue) }).frame(width: 120, height: 60))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 120, height: 60))
        window.rootViewController = controller; window.makeKeyAndVisible()
        controller.view.frame = window.bounds; controller.view.layoutIfNeeded()
        let button = try XCTUnwrap(descendants(controller.view).compactMap { $0 as? UIButton }.first)
        XCTAssertEqual(button.bounds, controller.view.bounds,
                       "the hit owner must be the complete visible control face")
        let points = [CGPoint(x: button.bounds.midX, y: button.bounds.midY),
                      CGPoint(x: 2, y: 2),
                      CGPoint(x: button.bounds.maxX - 2, y: 2),
                      CGPoint(x: 2, y: button.bounds.maxY - 2),
                      CGPoint(x: button.bounds.maxX - 2, y: button.bounds.maxY - 2)]
        for (index, point) in points.enumerated() {
            XCTAssertTrue(button.point(inside: point, with: nil))
            button.sendActions(for: .touchDown)
            if index == 0 {
                RunLoop.main.run(until: Date().addingTimeInterval(0.03))
                let pressed = UIGraphicsImageRenderer(size: window.bounds.size).image { _ in
                    controller.view.drawHierarchy(in: controller.view.bounds,
                                                  afterScreenUpdates: true)
                }
                let attachment = XCTAttachment(image: pressed)
                attachment.name = "WORLD-07-whole-face-pressed"
                attachment.lifetime = .keepAlways; add(attachment)
            }
            button.sendActions(for: .touchUpInside)
            let completionDeadline = Date().addingTimeInterval(1)
            while Date() < completionDeadline {
                if case .completed = coordinator.lifecycle { break }
                RunLoop.main.run(until: Date().addingTimeInterval(0.002))
            }
            guard case .completed = coordinator.lifecycle else {
                XCTFail("each deliberate repeat must wait for the authoritative completion")
                return
            }
        }
        XCTAssertEqual(activations, 5)
        window.isHidden = true
    }

    @MainActor
    func testCR02TouchDownAcknowledgesWithoutMutation() {
        let coordinator = WorldControlAttemptCoordinator()
        let snapshot = controlSnapshot()
        coordinator.touchDown(.useTile)
        XCTAssertEqual(coordinator.lifecycle, .touchDown(.useTile))
        XCTAssertEqual(snapshot, controlSnapshot())
    }

    @MainActor
    func testCR02MountedTouchCancellationClearsPressWithoutAttemptOrMutation() throws {
        let coordinator = WorldControlAttemptCoordinator()
        let store = GameStore(io: .temporary(name: "control-touch-\(UUID().uuidString)"))
        store.mutate("test control touch") { $0 = startedRun(book([:]), seed: 1221) }
        let snapshot = WorldControlSnapshot.make(from: store.state)
        let before = try SaveCodec.encode(store.state)
        let beforeTurn = store.activeRun?.turnsTaken
        var executions = 0
        let controller = UIHostingController(rootView: WorldWholeFaceControl(
            coordinator: coordinator, action: .useTile, snapshot: { snapshot },
            disabledReason: nil, operation: {
                executions += 1
                return .completed(.usedTile("Used"))
            }, label: { Text("Use Tile") }).frame(width: 100, height: 44))
        let window = UIWindow(frame: .init(x: 0, y: 0, width: 100, height: 44))
        window.rootViewController = controller; window.makeKeyAndVisible()
        controller.view.frame = window.bounds
        controller.view.layoutIfNeeded()
        let button = try XCTUnwrap(descendants(controller.view)
            .compactMap { $0 as? WorldControlHitOwner.ControlButton }.first)
        button.sendActions(for: .touchDown)
        XCTAssertEqual(coordinator.lifecycle, .touchDown(.useTile))
        button.sendActions(for: .touchDragExit)
        XCTAssertEqual(coordinator.lifecycle, .available)
        XCTAssertEqual(executions, 0)
        XCTAssertEqual(try SaveCodec.encode(store.state), before)
        XCTAssertEqual(store.activeRun?.turnsTaken, beforeTurn)
        XCTAssertEqual(coordinator.latestRefusal, nil)
        window.isHidden = true
    }

    @MainActor
    func testCR03AcceptedActionCompletesWithTypedOutcome() throws {
        let coordinator = WorldControlAttemptCoordinator(); let snapshot = controlSnapshot()
        guard case .accepted(let attempt) = coordinator.accept(.fieldKit, snapshot: snapshot) else {
            return XCTFail("expected accepted attempt")
        }
        XCTAssertTrue(coordinator.begin(attempt))
        XCTAssertTrue(coordinator.execute(attempt, current: snapshot) {
            .completed(.openedFieldKit)
        })
        XCTAssertEqual(coordinator.lifecycle, .completed(attempt.id, .openedFieldKit))
    }

    @MainActor
    func testCR04AcceptedAndInFlightOwnershipRefusesDuplicateWithNewID() throws {
        let coordinator = WorldControlAttemptCoordinator(); let snapshot = controlSnapshot()
        guard case .accepted(let first) = coordinator.accept(.useTile, snapshot: snapshot) else {
            return XCTFail("expected first attempt")
        }
        XCTAssertTrue(coordinator.begin(first))
        guard case .refused(.busy) = coordinator.accept(.useTile, snapshot: snapshot) else {
            return XCTFail("expected busy refusal")
        }
        guard let refusal = coordinator.latestRefusal else {
            return XCTFail("expected identified busy refusal")
        }
        XCTAssertEqual(coordinator.lifecycle, .inFlight(first))
        XCTAssertEqual(refusal.action, .useTile)
        XCTAssertEqual(refusal.reason, .busy)
        XCTAssertNotEqual(refusal.attemptID, first.id)
        XCTAssertTrue(coordinator.execute(first, current: snapshot) { .completed(.usedTile("Used")) })
    }

    @MainActor
    func testCR04BusyOwnershipPrecedesPeerDisabledState() throws {
        let coordinator = WorldControlAttemptCoordinator(); let snapshot = controlSnapshot()
        guard case .accepted(let first) = coordinator.accept(.travel(.init(x: 4, y: 4)),
            snapshot: snapshot) else { return XCTFail("first") }
        XCTAssertTrue(coordinator.begin(first))
        XCTAssertEqual(coordinator.accept(.useTile, snapshot: snapshot,
                                           disabledReason: "There is nothing to use here."),
                       .refused(.busy))
        XCTAssertEqual(coordinator.lifecycle, .inFlight(first))
        XCTAssertEqual(coordinator.latestRefusal?.action, .useTile)
        XCTAssertEqual(coordinator.latestRefusal?.reason, .busy)
    }

    @MainActor
    func testCR05TenTapsProduceOneMutationAndNoQueue() throws {
        let store = GameStore(io: .temporary(name: "control-ten-taps-\(UUID().uuidString)"))
        store.mutate("test mounted rapid step") { $0 = startedRun(book([:]), seed: 1205) }
        let before = try XCTUnwrap(store.activeRun)
        let beforeMutation = store.state.meta.mutationCount
        let target = try XCTUnwrap(before.map.neighbours(of: before.playerPosition)
            .first { WorldRules.canEnter($0, in: before.map) })
        let action = WorldControlAction.move(dx: target.x - before.playerPosition.x,
                                             dy: target.y - before.playerPosition.y)
        let coordinator = WorldControlAttemptCoordinator()
        let controller = UIHostingController(rootView: WorldWholeFaceControl(
            coordinator: coordinator, action: action,
            snapshot: { WorldControlSnapshot.make(from: store.state) },
            disabledReason: nil,
            operation: { WorldControlRulesExecution.step(store: store, to: target) },
            label: { Text("Step") }).frame(width: 80, height: 44))
        let window = UIWindow(frame: .init(x: 0, y: 0, width: 80, height: 44))
        window.rootViewController = controller; window.makeKeyAndVisible()
        controller.view.frame = window.bounds; controller.view.layoutIfNeeded()
        let button = try XCTUnwrap(descendants(controller.view)
            .compactMap { $0 as? WorldControlHitOwner.ControlButton }.first)
        for _ in 0..<10 { button.sendActions(for: .touchDown); button.sendActions(for: .touchUpInside) }
        let deadline = Date().addingTimeInterval(2)
        while Date() < deadline {
            if case .completed = coordinator.lifecycle { break }
            RunLoop.main.run(until: Date().addingTimeInterval(0.01))
        }
        guard case .completed = coordinator.lifecycle else {
            return XCTFail("the admitted mounted attempt did not settle")
        }
        XCTAssertEqual(store.activeRun?.playerPosition, target)
        guard case .completed(_, .stepped(_, let spent)) = coordinator.lifecycle else {
            return XCTFail("the mounted step must retain its exact rules-owned outcome")
        }
        XCTAssertGreaterThan(spent, 0)
        XCTAssertEqual(store.activeRun?.turnsTaken, before.turnsTaken + spent)
        XCTAssertEqual(store.state.meta.mutationCount, beforeMutation + 1)
        let settled = try SaveCodec.encode(store.state)
        RunLoop.main.run(until: Date().addingTimeInterval(0.15))
        XCTAssertEqual(try SaveCodec.encode(store.state), settled, "busy taps must not replay later")
        window.isHidden = true
    }

    @MainActor
    func testCR06StaleStateRefusesBeforeOperation() throws {
        let store = GameStore(io: .temporary(name: "control-stale-\(UUID().uuidString)"))
        store.mutate("test stale baseline") { $0 = startedRun(book([:]), seed: 1206) }
        let run = try XCTUnwrap(store.activeRun)
        let target = try XCTUnwrap(run.map.neighbours(of: run.playerPosition)
            .first { WorldRules.canEnter($0, in: run.map) })
        let coordinator = WorldControlAttemptCoordinator()
        let snapshot = WorldControlSnapshot.make(from: store.state)
        guard case .accepted(let attempt) = coordinator.accept(.useTile, snapshot: snapshot)
        else { return XCTFail("expected attempt") }
        XCTAssertTrue(coordinator.begin(attempt))
        store.mutate("external stale interference") { $0.meta.semanticActionTrail.append("external") }
        let frozen = try SaveCodec.encode(store.state)
        let frozenTurn = store.activeRun?.turnsTaken
        var called = false
        XCTAssertFalse(coordinator.execute(attempt, current: .make(from: store.state)) {
            called = true
            return WorldControlRulesExecution.step(store: store, to: target)
        })
        XCTAssertFalse(called)
        XCTAssertEqual(coordinator.lifecycle, .refused(.useTile, attempt.id, .stale))
        XCTAssertEqual(try SaveCodec.encode(store.state), frozen)
        XCTAssertEqual(store.activeRun?.turnsTaken, frozenTurn)
    }

    @MainActor
    func testCR07KnownDisabledControlReportsExactReason() throws {
        let store = GameStore(io: .temporary(name: "disabled-use-tile-\(UUID().uuidString)"))
        store.mutate("test disabled use tile") { state in
            state = startedRun(book([:]), seed: 1207)
            guard let run = state.worlds.activeRun,
                  let clear = run.map.allPoints.first(where: {
                      WorldRules.canEnter($0, in: run.map) && run.map[$0].content == .empty
                          && run.map[$0].flora == nil
                  }) else { return }
            state.worlds.activeRun?.playerPosition = clear
        }
        let controller = UIHostingController(rootView:
            WorldView().environmentObject(store).frame(width: 368, height: 800))
        let window = UIWindow(frame: .init(x: 0, y: 0, width: 368, height: 800))
        window.rootViewController = controller; window.makeKeyAndVisible()
        controller.view.frame = window.bounds; controller.view.layoutIfNeeded()
        let button = try XCTUnwrap(descendants(controller.view)
            .compactMap { $0 as? WorldControlHitOwner.ControlButton }
            .first { $0.worldAction == .useTile })
        XCTAssertEqual(button.worldDisabledReason, "There is nothing to use here.")
        let before = try SaveCodec.encode(store.state)
        let turn = store.activeRun?.turnsTaken
        button.sendActions(for: .touchDown); button.sendActions(for: .touchUpInside)
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        XCTAssertEqual(try SaveCodec.encode(store.state), before)
        XCTAssertEqual(store.activeRun?.turnsTaken, turn)
        let disabled = UIGraphicsImageRenderer(size: window.bounds.size).image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
        let attachment = XCTAttachment(image: disabled)
        attachment.name = "WORLD-06-disabled-use-tile-no-popup-368x800"
        attachment.lifetime = .keepAlways; add(attachment)
        window.isHidden = true
    }

    @MainActor
    func testBuild252ExistingActiveRunRelaunchMountsBoundedWorldActionTypes() throws {
        let original = startedRun(book([:]), seed: 252)
        let persisted = try SaveCodec.encode(original)
        let decoded = try SaveCodec.decode(persisted)
        let relaunched = GameStore(io: .temporary(
            name: "build-252-active-run-launch-\(UUID().uuidString)"))
        relaunched.mutate("test load persisted active-run shape") { $0 = decoded }
        XCTAssertNotNil(relaunched.activeRun)
        XCTAssertNil(relaunched.state.worlds.pendingWorldArrivalReceipt)
        let loadedPosition = relaunched.activeRun?.playerPosition
        let loadedMap = relaunched.activeRun?.map
        let loadedTurn = relaunched.activeRun?.turnsTaken

        let controller = UIHostingController(rootView:
            WorldView().environmentObject(relaunched).frame(width: 368, height: 800))
        let window = UIWindow(frame: .init(x: 0, y: 0, width: 368, height: 800))
        window.rootViewController = controller; window.makeKeyAndVisible()
        controller.view.frame = window.bounds; controller.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.08))

        let actions = descendants(controller.view)
            .compactMap { ($0 as? WorldControlHitOwner.ControlButton)?.worldAction }
        XCTAssertTrue(actions.contains(.useTile))
        XCTAssertTrue(actions.contains(.armLook))
        XCTAssertEqual(relaunched.activeRun?.playerPosition, loadedPosition)
        XCTAssertEqual(relaunched.activeRun?.map, loadedMap)
        XCTAssertEqual(relaunched.activeRun?.turnsTaken, loadedTurn,
                       "materializing World controls must not spend a turn")
        window.isHidden = true

        let source = try String(contentsOf: URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .appending(path: "Sources/Screens/WorldView.swift"), encoding: .utf8)
        XCTAssertTrue(source.contains("private struct WorldActionRow: View"))
        XCTAssertFalse(source.contains("private struct WorldActionRow<"),
                       "the device stack-overflowing generic action-row type must stay erased")
    }

    @MainActor
    func testCR08RepeatAfterCompletionCreatesNextAttempt() throws {
        let coordinator = WorldControlAttemptCoordinator(); let snapshot = controlSnapshot()
        guard case .accepted(let first) = coordinator.accept(.fieldKit, snapshot: snapshot) else {
            return XCTFail("first")
        }
        XCTAssertTrue(coordinator.begin(first)); XCTAssertTrue(coordinator.execute(first,
            current: snapshot) { .completed(.openedFieldKit) })
        guard case .accepted(let second) = coordinator.accept(.fieldKit, snapshot: snapshot) else {
            return XCTFail("second")
        }
        XCTAssertGreaterThan(second.id, first.id)
    }

    @MainActor
    func testCR09DPadAttemptOwnsExactlyOneStepOutcome() throws {
        let store = GameStore(io: .temporary(name: "control-step-\(UUID().uuidString)"))
        store.mutate("test real step") { $0 = startedRun(book([:]), seed: 1209) }
        let before = try XCTUnwrap(store.activeRun)
        let target = try XCTUnwrap(before.map.neighbours(of: before.playerPosition)
            .first { WorldRules.canEnter($0, in: before.map) })
        let action = WorldControlAction.move(dx: target.x - before.playerPosition.x,
                                             dy: target.y - before.playerPosition.y)
        let coordinator = WorldControlAttemptCoordinator()
        let snapshot = WorldControlSnapshot.make(from: store.state)
        guard case .accepted(let attempt) = coordinator.accept(action, snapshot: snapshot)
        else { return XCTFail("move") }
        XCTAssertTrue(coordinator.begin(attempt))
        XCTAssertTrue(coordinator.execute(attempt, current: snapshot) {
            WorldControlRulesExecution.step(store: store, to: target)
        })
        XCTAssertEqual(store.activeRun?.playerPosition, target)
        XCTAssertEqual(store.activeRun?.turnsTaken, before.turnsTaken + 1)
        XCTAssertEqual(coordinator.lifecycle,
                       .completed(attempt.id, .stepped(finalPosition: target, turnsSpent: 1)))
    }

    @MainActor
    func testCR10TravelBDoesNotReplaceInFlightTravelA() throws {
        let store = GameStore(io: .temporary(name: "control-travel-\(UUID().uuidString)"))
        let initial = startedRun(book([:]), seed: 1210)
        store.mutate("test travel parity setup") { $0 = initial }
        let before = try XCTUnwrap(store.activeRun)
        let origin = before.playerPosition
        let a = try XCTUnwrap(before.map.allPoints.last(where: {
            $0 != origin && WorldRules.canEnter($0, in: before.map)
                && WorldRules.path(from: origin, to: $0, in: before.map).count > 2
        }))
        let b = before.map.allPoints.first(where: { $0 != a }) ?? origin
        let direct = GameStore(io: .temporary(name: "control-travel-direct-\(UUID().uuidString)"))
        direct.mutate("test travel parity setup") { $0 = initial }
        let directResult = WorldControlRulesExecution.travel(store: direct, from: origin, to: a)
        let coordinator = WorldControlAttemptCoordinator()
        let snapshot = WorldControlSnapshot.make(from: store.state)
        guard case .accepted(let first) = coordinator.accept(.travel(a), snapshot: snapshot) else {
            return XCTFail("travel A")
        }
        XCTAssertTrue(coordinator.begin(first))
        XCTAssertEqual(coordinator.accept(.travel(b), snapshot: snapshot), .refused(.busy))
        XCTAssertEqual(coordinator.lifecycle, .inFlight(first))
        XCTAssertEqual(coordinator.statusCopy(for: .travel(a)), "Working…")
        XCTAssertEqual(coordinator.statusCopy(for: .travel(b)),
                       WorldControlRefusal.busy.playerCopy)
        XCTAssertTrue(coordinator.execute(first, current: snapshot) {
            WorldControlRulesExecution.travel(store: store, from: origin, to: a)
        })
        let final = try XCTUnwrap(store.activeRun)
        guard case .completed(_, let outcome) = coordinator.lifecycle else {
            return XCTFail("travel A must own the completed result")
        }
        guard case .completed(let directOutcome) = directResult else {
            return XCTFail("direct A transaction must complete")
        }
        XCTAssertEqual(outcome, directOutcome)
        XCTAssertEqual(outcome, .travelEnded(finalPosition: final.playerPosition,
            turnsSpent: final.turnsTaken - before.turnsTaken,
            reachedDestination: final.playerPosition == a))
        XCTAssertEqual(try comparableStateBytes(store.state), try comparableStateBytes(direct.state))
        XCTAssertEqual(store.recentEvents, direct.recentEvents)
        XCTAssertNil(coordinator.statusCopy(for: .travel(a)))
        XCTAssertNil(coordinator.statusCopy(for: .travel(b)))
        XCTAssertNil(coordinator.latestRefusal)
    }

    @MainActor
    func testCR11MapCellRemainsGeometryOwnedException() {
        let origin = GridPoint(x: 2, y: 2)
        XCTAssertEqual(WorldMapPlanningAction.action(from: origin, to: .init(x: 3, y: 2)),
                       .move(dx: 1, dy: 0))
        XCTAssertEqual(WorldMapPlanningAction.action(from: origin, to: .init(x: 8, y: 7)),
                       .travel(.init(x: 8, y: 7)))
        var routed: [WorldControlAction] = []
        WorldMapPlanningAction.route(from: origin, to: .init(x: 8, y: 7)) { routed.append($0) }
        XCTAssertEqual(routed, [.travel(.init(x: 8, y: 7))])
        let source = try? String(contentsOfFile: #filePath.replacingOccurrences(
            of: "/Tests/WorldTests.swift", with: "/Sources/Screens/WorldView.swift"))
        XCTAssertTrue(source?.contains(".onTapGesture { onTap(point) }") == true)
        XCTAssertTrue(source?.contains("WorldMapPlanningAction.route(from: run.playerPosition, to: point)") == true)
        let mapGrid = source?.components(separatedBy: "private struct MapGrid: View").last ?? ""
        XCTAssertFalse(mapGrid.components(separatedBy: "struct WorldTileVisibilityPresentation").first?
            .contains("WorldWholeFaceControl") == true,
            "16px map cells remain the explicit geometry-owned planning exception")
    }

    @MainActor
    func testCR12CoordinatorLifecycleIsNonpersistent() throws {
        let initial = startedRun(book([:]), seed: 991)
        let direct = GameStore(io: .temporary(name: "control-direct-\(UUID().uuidString)"))
        let coordinated = GameStore(io: .temporary(name: "control-coordinated-\(UUID().uuidString)"))
        direct.mutate("test control parity setup") { $0 = initial }
        coordinated.mutate("test control parity setup") { $0 = initial }
        let run = try XCTUnwrap(initial.worlds.activeRun)
        let target = try XCTUnwrap(run.map.neighbours(of: run.playerPosition)
            .first { WorldRules.canEnter($0, in: run.map) })
        direct.step(to: target)
        let coordinator = WorldControlAttemptCoordinator()
        let snapshot = WorldControlSnapshot.make(from: coordinated.state)
        guard case .accepted(let attempt) = coordinator.accept(
            .move(dx: target.x - run.playerPosition.x, dy: target.y - run.playerPosition.y),
            snapshot: snapshot) else { return XCTFail("attempt") }
        XCTAssertTrue(coordinator.begin(attempt))
        XCTAssertTrue(coordinator.execute(attempt, current: snapshot) {
            WorldControlRulesExecution.step(store: coordinated, to: target)
        })
        XCTAssertEqual(try comparableStateBytes(coordinated.state), try comparableStateBytes(direct.state),
                       "coordinator lifecycle must not persist or alter the rules transaction")
    }

    @MainActor
    func testCR12CommittedBlockedStepKeepsDirectPathParityWithoutTurn() throws {
        let initial = startedRun(book([:]), seed: 992)
        let run = try XCTUnwrap(initial.worlds.activeRun)
        let blocked = GridPoint(x: -1, y: run.playerPosition.y)
        let direct = GameStore(io: .temporary(name: "blocked-direct-\(UUID().uuidString)"))
        let coordinated = GameStore(io: .temporary(name: "blocked-control-\(UUID().uuidString)"))
        direct.mutate("test blocked parity setup") { $0 = initial }
        coordinated.mutate("test blocked parity setup") { $0 = initial }
        direct.step(to: blocked)
        let result = WorldControlRulesExecution.step(store: coordinated, to: blocked)
        guard case .completed(.blocked(let final, let turns, let reason)) = result else {
            return XCTFail("rules-owned blocked attempt must be a committed completion")
        }
        XCTAssertEqual(final, run.playerPosition)
        XCTAssertEqual(turns, 0)
        XCTAssertFalse(reason.isEmpty)
        XCTAssertEqual(coordinated.activeRun?.turnsTaken, run.turnsTaken)
        XCTAssertEqual(try comparableStateBytes(coordinated.state), try comparableStateBytes(direct.state))
        XCTAssertEqual(coordinated.recentEvents, direct.recentEvents)
    }

    @MainActor
    func testWorldFieldFeedbackNewestFirstExpiryAndIdentityDismissal() throws {
        let store = GameStore(io: .temporary(name: "field-feedback-newest-\(UUID().uuidString)"))
        store.mutate("test: start field feedback") { $0 = startedRun(book([:]), seed: 901) }
        let first = try XCTUnwrap(store.beginWorldFieldAttempt(.step))
        let duplicateEvents: [WorldRules.Event] = [.blocked("Still blocked."), .blocked("Still blocked.")]
        store.submitWorldFieldEvents(duplicateEvents, for: first, now: 100)
        store.submitWorldFieldEvents(duplicateEvents, for: first, now: 200)
        XCTAssertEqual(store.worldFieldEventQueue.count, 1, "batchID is the only dedupe key")
        XCTAssertEqual(store.worldFieldEventQueue[0].orderedEvents, duplicateEvents)
        XCTAssertEqual(store.worldFieldEventQueue[0].orderedNarrations.count, 2)

        let second = try XCTUnwrap(store.beginWorldFieldAttempt(.step))
        store.submitWorldFieldEvents([.blocked("Still blocked.")], for: second, now: 300)
        let third = try XCTUnwrap(store.beginWorldFieldAttempt(.step))
        store.submitWorldFieldEvents([.blocked("Third batch.")], for: third, now: 400)
        XCTAssertEqual(store.worldFieldEventQueue.map(\.orderedNarrations), [
            ["Third batch."],
        ], "the newest interaction is immediate and preempted receipts retire")
        let frozenState = try SaveCodec.encode(store.state)
        let frozenContext = store.worldFieldContext
        let newestID = try XCTUnwrap(store.currentWorldFieldEventBatch?.batchID)
        store.expireWorldFieldFeedback(ifCurrent: newestID, now: 2_000_000_399)
        XCTAssertEqual(store.currentWorldFieldEventBatch?.batchID, newestID)
        store.expireWorldFieldFeedback(ifCurrent: newestID, now: 2_000_000_400)
        XCTAssertNil(store.currentWorldFieldEventBatch,
                     "an older preempted receipt cannot resurface with a fresh lifetime")
        store.dismissWorldFieldFeedback(expectedBatchID: newestID, now: 5_000_000_000)
        XCTAssertNil(store.currentWorldFieldEventBatch)
        XCTAssertEqual(try SaveCodec.encode(store.state), frozenState)
        XCTAssertEqual(store.worldFieldContext, frozenContext)
    }

    func testWORLD03Through05FeedbackTimingGradientAndContextOverlapTruth() {
        XCTAssertEqual(WorldFieldFeedbackLayout.eventHoldNanoseconds, 1_700_000_000)
        XCTAssertEqual(WorldFieldFeedbackLayout.eventFadeNanoseconds, 300_000_000)
        XCTAssertEqual(WorldFieldFeedbackLayout.eventOpacity(elapsedNanoseconds: 0), 1)
        XCTAssertEqual(WorldFieldFeedbackLayout.eventOpacity(
            elapsedNanoseconds: 1_700_000_000), 1)
        XCTAssertEqual(WorldFieldFeedbackLayout.eventOpacity(
            elapsedNanoseconds: 1_850_000_000), 0.5, accuracy: 0.001)
        XCTAssertEqual(WorldFieldFeedbackLayout.eventOpacity(
            elapsedNanoseconds: 2_000_000_000), 0)
        XCTAssertTrue(WorldFieldFeedbackLayout.contextOverlapsPlayer(
            player: .init(x: 0, y: 19), mapWidth: 20, mapHeight: 20,
            viewportColumns: 11, viewportRows: 14, mapHeightPoints: 466.67))
        XCTAssertFalse(WorldFieldFeedbackLayout.contextOverlapsPlayer(
            player: .init(x: 10, y: 10), mapWidth: 20, mapHeight: 20,
            viewportColumns: 11, viewportRows: 14, mapHeightPoints: 466.67))
    }

    @MainActor
    func testWorldFieldFeedbackCanonicalAssociatedValuesCannotCollide() throws {
        let store = GameStore(io: .temporary(name: "field-feedback-hash-\(UUID().uuidString)"))
        store.mutate("test: start field feedback") { $0 = startedRun(book([:]), seed: 902) }
        let first = try XCTUnwrap(store.beginWorldFieldAttempt(.interact))
        store.submitWorldFieldEvents(
            [.readFoundWriting(FoundWritingID(rawValue: "a:b"), "c;d")], for: first, now: 1)
        let firstBatchID = try XCTUnwrap(store.worldFieldEventQueue.first?.batchID)
        let second = try XCTUnwrap(store.beginWorldFieldAttempt(.interact))
        store.submitWorldFieldEvents(
            [.readFoundWriting(FoundWritingID(rawValue: "a"), "b:c;d")], for: second, now: 2)
        XCTAssertEqual(store.worldFieldEventQueue.count, 1)
        XCTAssertNotEqual(firstBatchID, store.worldFieldEventQueue[0].batchID)
    }
    @MainActor
    func testWorldFieldFeedbackMountedConsumerChangesPhoneRenderWithoutGameplayMutation() throws {
        let store = GameStore(io: .temporary(name: "field-feedback-render-\(UUID().uuidString)"))
        store.mutate("test: mounted feedback") { $0 = startedRun(book([:]), seed: 903) }
        let controller = UIHostingController(rootView:
            WorldView().environmentObject(store).frame(width: 368, height: 800))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 368, height: 800))
        window.rootViewController = controller; window.makeKeyAndVisible()
        controller.view.frame = window.bounds; controller.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.08))
        let mapFrameBefore = WorldMapStageMeasurement.latestFrame
        XCTAssertEqual(mapFrameBefore.width, 368, accuracy: 0.5)
        XCTAssertEqual(mapFrameBefore.height, 475, accuracy: 0.5,
                       "the compact feedback remains inside the expanded measured map stage")
        XCTAssertEqual(WorldFieldFeedbackLayout.compactHeight, 78)
        XCTAssertEqual(WorldFieldFeedbackLayout.paneWidths(total: 368).context, 91)
        XCTAssertEqual(WorldFieldFeedbackLayout.paneWidths(total: 368).event, 273)
        func image() -> UIImage {
            UIGraphicsImageRenderer(size: window.bounds.size).image { _ in
                controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
            }
        }
        let before = image()
        let frozen = try SaveCodec.encode(store.state)
        let attempt = try XCTUnwrap(store.beginWorldFieldAttempt(.step))
        store.submitWorldFieldEvents([
            .blocked("First complete narration."), .hazardHit(damage: 2),
            .poisonWorking(damage: 1),
        ], for: attempt, now: 10)
        RunLoop.main.run(until: Date().addingTimeInterval(0.08))
        controller.view.layoutIfNeeded()
        let mapFrameAfter = WorldMapStageMeasurement.latestFrame
        let after = image()
        XCTAssertNotEqual(before.pngData(), after.pngData(),
                          "the mounted consumer must visibly react to its queue")
        XCTAssertEqual(try SaveCodec.encode(store.state), frozen)
        XCTAssertEqual(mapFrameAfter.size, mapFrameBefore.size,
                       "enqueueing feedback must not steal a point from the map")
        XCTAssertEqual(store.currentWorldFieldEventBatch?.orderedNarrations.count, 3)
        let beforeAttachment = XCTAttachment(image: before)
        beforeAttachment.name = "world-field-feedback-map-height-before-368x800"
        beforeAttachment.lifetime = .keepAlways; add(beforeAttachment)
        let attachment = XCTAttachment(image: after)
        attachment.name = "world-field-feedback-three-lines-368x800"
        attachment.lifetime = .keepAlways; add(attachment)
        controller.overrideUserInterfaceStyle = .dark
        controller.view.setNeedsLayout(); controller.view.layoutIfNeeded()
        let darkEvent = image()
        let darkAttachment = XCTAttachment(image: darkEvent)
        darkAttachment.name = "WORLD-01-05-dark-event-368x800"
        darkAttachment.lifetime = .keepAlways; add(darkAttachment)
        store.clearWorldFieldFeedback()
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        let darkEmpty = image()
        XCTAssertNotEqual(darkEvent.pngData(), darkEmpty.pngData())
        let emptyAttachment = XCTAttachment(image: darkEmpty)
        emptyAttachment.name = "WORLD-02-dark-empty-event-absent-368x800"
        emptyAttachment.lifetime = .keepAlways; add(emptyAttachment)
        window.isHidden = true
    }

    @MainActor
    func testExpandedWorldFieldBatchKeepsEveryNarrationReachableWithoutExtendingLifetime() throws {
        let store = GameStore(io: .temporary(name: "field-feedback-expanded-\(UUID().uuidString)"))
        store.mutate("test: expanded feedback") { $0 = startedRun(book([:]), seed: 906) }
        let frozen = try SaveCodec.encode(store.state)
        let attempt = try XCTUnwrap(store.beginWorldFieldAttempt(.step))
        store.submitWorldFieldEvents([
            .blocked("First complete narration."), .hazardHit(damage: 2),
            .poisonWorking(damage: 1),
        ], for: attempt, now: 10)
        let batch = try XCTUnwrap(store.currentWorldFieldEventBatch)
        let controller = UIHostingController(rootView:
            WorldFieldFeedbackRow(initiallyExpandedBatchID: batch.batchID)
                .environmentObject(store).frame(width: 368, height: 300))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 368, height: 300))
        window.rootViewController = controller; window.makeKeyAndVisible()
        controller.view.frame = window.bounds; controller.view.layoutIfNeeded()
        XCTAssertEqual(store.currentWorldFieldEventBatch?.orderedNarrations, batch.orderedNarrations)
        XCTAssertEqual(try SaveCodec.encode(store.state), frozen)
        let image = UIGraphicsImageRenderer(size: window.bounds.size).image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
        let attachment = XCTAttachment(image: image)
        attachment.name = "world-field-feedback-expanded-three-lines"
        attachment.lifetime = .keepAlways; add(attachment)
        store.expireWorldFieldFeedback(ifCurrent: batch.batchID, now: 2_000_000_010)
        XCTAssertNil(store.currentWorldFieldEventBatch,
                     "expanded presentation must not extend the event's 1.7s hold + 0.3s fade")
        window.isHidden = true
    }

    @MainActor
    func testWorldFieldFeedbackIsTransientAcrossColdRelaunch() throws {
        let io = SaveFileIO.temporary(name: "field-feedback-relaunch-\(UUID().uuidString)")
        let first = GameStore(io: io)
        first.mutate("test: persisted run", flush: true) { $0 = startedRun(book([:]), seed: 904) }
        let attempt = try XCTUnwrap(first.beginWorldFieldAttempt(.step))
        first.submitWorldFieldEvents([.blocked("Visible now.")], for: attempt, now: 1)
        XCTAssertFalse(first.worldFieldEventQueue.isEmpty)
        let expectedContext = WorldFieldContextReceiptV1.make(from: first.state)
        let relaunched = GameStore(io: io)
        XCTAssertTrue(relaunched.worldFieldEventQueue.isEmpty)
        XCTAssertEqual(relaunched.worldFieldContext, expectedContext)
    }

    @MainActor
    func testSuccessfulBindPublishesInitialContextAndRefusalPreservesIt() throws {
        let success = GameStore(io: .temporary(
            name: "field-feedback-bind-success-\(UUID().uuidString)"))
        success.mutate("test: bind balance") {
            $0.base.page = Page()
            $0.base.essence = 28
        }
        XCTAssertTrue(success.bindAndDepart())
        let run = try XCTUnwrap(success.activeRun)
        let context = try XCTUnwrap(success.worldFieldContext)
        XCTAssertEqual(context.position, run.playerPosition)
        XCTAssertEqual(context.inputStateHash,
                       WorldFieldContextReceiptV1.make(from: success.state)?.inputStateHash)

        let refusal = GameStore(io: .temporary(
            name: "field-feedback-bind-refusal-\(UUID().uuidString)"))
        refusal.mutate("test: insufficient bind balance") { $0.base.essence = 0 }
        refusal.refreshWorldFieldContext()
        let beforeState = try SaveCodec.encode(refusal.state)
        let beforeContext = refusal.worldFieldContext
        XCTAssertFalse(refusal.bindAndDepart())
        XCTAssertEqual(try SaveCodec.encode(refusal.state), beforeState)
        XCTAssertEqual(refusal.worldFieldContext, beforeContext)
    }

    @MainActor
    func testLoosePageMutationRefreshesContextAndRefusalDoesNot() throws {
        let definition = try XCTUnwrap(WorldPageCatalog.definition("wild_storm_coast"))
        let point = GridPoint(x: 1, y: 1)
        let page = WorldPageInstance(
            id: InstanceID(rawValue: 991), definition: definition,
            fieldProvenance: .init(originRunIndex: 3, originWorldSeed: 44,
                                   generationSeed: 55, position: point))
        var run = wildPageRun(seed: 44); run.playerPosition = point
        run.map[point].isRevealed = true
        run.offeredWorldPages = [page]; run.satchelItems.slots = 2
        let store = GameStore(io: .temporary(name: "field-feedback-page-\(UUID().uuidString)"))
        store.mutate("test: offer page") { $0.worlds.activeRun = run }
        store.refreshWorldFieldContext()
        let offered = try XCTUnwrap(store.worldFieldContext)
        XCTAssertEqual(offered.interaction, .takePage)
        let quote = try XCTUnwrap(store.offeredWorldPageQuote(page.id))
        guard case .taken = store.takeOfferedWorldPage(quote) else { return XCTFail("take failed") }
        let taken = try XCTUnwrap(store.worldFieldContext)
        XCTAssertNotEqual(taken.inputStateHash, offered.inputStateHash)
        XCTAssertNotEqual(taken.interaction, .takePage)
        let frozen = taken
        XCTAssertEqual(store.takeOfferedWorldPage(quote), .stale)
        XCTAssertEqual(store.worldFieldContext, frozen)
    }

    @MainActor
    func testEncounterAndReturnAcceptTransientFeedbackOwnership() throws {
        let encounterStore = GameStore(io: .temporary(
            name: "field-feedback-encounter-\(UUID().uuidString)"))
        var encounterState = startedRun(book(["terrain": "plains"]), seed: 62)
        var encounterRun = try XCTUnwrap(encounterState.worlds.activeRun)
        let target = try XCTUnwrap(encounterRun.map.neighbours(of: encounterRun.playerPosition)
            .first { WorldRules.canEnter($0, in: encounterRun.map) })
        encounterRun.enemies = [WorldEnemy(id: InstanceID(rawValue: 7),
            creatureID: "ink_hound", position: target, isAwake: true)]
        encounterState.worlds.activeRun = encounterRun
        encounterStore.mutate("test: encounter ownership") { $0 = encounterState }
        let queued = try XCTUnwrap(encounterStore.beginWorldFieldAttempt(.interact))
        encounterStore.submitWorldFieldEvents([.blocked("Old feedback.")], for: queued, now: 1)
        encounterStore.step(to: target)
        XCTAssertNotNil(encounterStore.activeRun?.activeEncounter)
        XCTAssertTrue(encounterStore.worldFieldEventQueue.isEmpty)

        let returnStore = GameStore(io: .temporary(
            name: "field-feedback-return-\(UUID().uuidString)"))
        returnStore.mutate("test: return ownership") {
            $0 = startedRun(book(["terrain": "plains"]), seed: 63)
        }
        let returnAttempt = try XCTUnwrap(returnStore.beginWorldFieldAttempt(.interact))
        returnStore.submitWorldFieldEvents([.blocked("Old feedback.")], for: returnAttempt, now: 1)
        returnStore.mutate("stand on the return portal") { state in
            guard let entry = state.worlds.activeRun?.map.entry else { return }
            state.worlds.activeRun?.playerPosition = entry
        }
        XCTAssertTrue(returnStore.canPortalHere)
        returnStore.portalHome()
        XCTAssertNil(returnStore.activeRun)
        XCTAssertTrue(returnStore.worldFieldEventQueue.isEmpty)
    }

    @MainActor
    func testWorldTravelRendersAtApprovedOrdinaryPhoneSize() throws {
        let store = GameStore(io: .temporary(name: "world-render-\(UUID().uuidString)"))
        let state = startedRun(book(["terrain": "plains"]), seed: 101)
        store.mutate("test: world render") { saved in
            saved = state
            if var run = saved.worlds.activeRun {
                let center = GridPoint(x: run.map.width / 2, y: run.map.height / 2)
                run.playerPosition = center
                for point in run.map.allPoints {
                    run.map[point].isRevealed = true
                }
                saved.worlds.activeRun = run
            }
            for lesson in TutorialLessonID.allCases {
                saved.tutorial.complete(lesson, fact: "visual_fixture")
            }
        }
        for scheme in [ColorScheme.light, .dark] {
            let controller = UIHostingController(rootView:
                WorldView().environmentObject(store)
                    .environment(\.colorScheme, scheme)
                    .environment(\.dynamicTypeSize, .large)
                    .frame(width: 368, height: 800)
            )
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 368, height: 800))
            window.rootViewController = controller
            window.makeKeyAndVisible()
            controller.view.frame = window.bounds
            controller.view.layoutIfNeeded()
            RunLoop.main.run(until: Date().addingTimeInterval(0.08))
            let image = UIGraphicsImageRenderer(size: window.bounds.size).image { _ in
                controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
            }
            window.isHidden = true
            XCTAssertEqual(image.size, CGSize(width: 368, height: 800))
            let attachment = XCTAttachment(image: image)
            attachment.name = "world-travel-\(scheme == .light ? "light" : "dark")"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }

    @MainActor
    func testWORLDAssetEvidenceUsesActualContextAndControlOwnersWithoutTutorial() throws {
        func makeStore(overPlayer: Bool, interactable: Bool) throws -> GameStore {
            let store = GameStore(io: .temporary(
                name: "world-asset-evidence-\(overPlayer)-\(interactable)-\(UUID().uuidString)"))
            store.mutate("test: unobscured World asset evidence") { saved in
                saved = startedRun(book(["terrain": "plains"]), seed: 12_071)
                guard var run = saved.worlds.activeRun else { return }
                let point = overPlayer
                    ? GridPoint(x: 0, y: run.map.height - 1)
                    : GridPoint(x: run.map.width / 2, y: run.map.height / 2)
                run.playerPosition = point
                run.enemies = []
                for mapPoint in run.map.allPoints {
                    run.map[mapPoint].isRevealed = true
                    run.map[mapPoint].isCrumbled = false
                    run.map[mapPoint].isCracking = false
                    run.map[mapPoint].elevation = 0
                }
                run.map[point].flora = nil
                run.map[point].content = interactable
                    ? .node(ResourceNode(resource: Resources.ore, remainingHarvests: 2,
                                         yieldPerHarvest: 1, secondaryResource: nil,
                                         secondaryYieldPerHarvest: 0))
                    : .empty
                if !interactable {
                    for neighbour in run.map.neighbours(of: point) {
                        run.map[neighbour].content = .empty
                    }
                }
                saved.worlds.activeRun = run
                for lesson in TutorialLessonID.allCases {
                    saved.tutorial.complete(lesson, fact: "world_asset_evidence")
                }
            }
            return store
        }

        func mountedEvidence(store: GameStore, scheme: ColorScheme,
                             name: String, contextOverPlayer: Bool,
                             pressUseTile: Bool = false) throws {
            let frozen = try SaveCodec.encode(store.state)
            let controller = UIHostingController(rootView:
                WorldView().environmentObject(store)
                    .environment(\.colorScheme, scheme).frame(width: 368, height: 800))
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 368, height: 800))
            window.rootViewController = controller; window.makeKeyAndVisible()
            controller.view.frame = window.bounds; controller.view.layoutIfNeeded()
            RunLoop.main.run(until: Date().addingTimeInterval(0.08))
            XCTAssertEqual(WorldMapStageMeasurement.latestFrame.size,
                           CGSize(width: 368, height: 475))
            let contextSocket = CGRect(
                x: WorldMapStageMeasurement.latestMapFrame.minX,
                y: WorldMapStageMeasurement.latestMapFrame.maxY
                    - WorldFieldFeedbackLayout.compactHeight,
                width: WorldFieldFeedbackLayout.paneWidths(total: 368).context,
                height: WorldFieldFeedbackLayout.compactHeight)
            XCTAssertEqual(contextSocket.minX, 0, accuracy: 0.75,
                           "the empty-event context remains in its established left socket")
            XCTAssertEqual(contextSocket.width, 91, accuracy: 0.5)
            XCTAssertEqual(contextSocket.height, 78, accuracy: 0.5)
            let run = try XCTUnwrap(store.activeRun)
            XCTAssertEqual(WorldFieldFeedbackLayout.contextOverlapsPlayer(
                player: run.playerPosition, mapWidth: run.map.width, mapHeight: run.map.height,
                viewportColumns: 11, viewportRows: 14,
                mapHeightPoints: WorldMapStageMeasurement.latestMapFrame.height), contextOverPlayer)
            let useTile = try XCTUnwrap(descendants(controller.view)
                .compactMap { $0 as? WorldControlHitOwner.ControlButton }
                .first { $0.worldAction == .useTile })
            let controlFrame = useTile.convert(useTile.bounds, to: nil)
            XCTAssertGreaterThan(controlFrame.width, 70)
            XCTAssertEqual(controlFrame.height, WorldControlsLayout.actionHeight, accuracy: 0.5)
            if pressUseTile {
                XCTAssertNil(useTile.worldDisabledReason)
                useTile.sendActions(for: .touchDown)
                RunLoop.main.run(until: Date().addingTimeInterval(0.04))
            } else {
                XCTAssertEqual(useTile.worldDisabledReason, "There is nothing to use here.")
            }
            let image = UIGraphicsImageRenderer(size: window.bounds.size).image { _ in
                controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
            }
            let attachment = XCTAttachment(image: image)
            attachment.name = name
            attachment.lifetime = .keepAlways; add(attachment)
            if pressUseTile { useTile.sendActions(for: .touchDragExit) }
            XCTAssertEqual(try SaveCodec.encode(store.state), frozen)
            window.isHidden = true
        }

        for scheme in [ColorScheme.light, .dark] {
            let suffix = scheme == .light ? "light" : "dark"
            let ordinary = try makeStore(overPlayer: false, interactable: false)
            let ordinaryRun = try XCTUnwrap(ordinary.activeRun)
            XCTAssertFalse(WorldFieldFeedbackLayout.contextOverlapsPlayer(
                player: ordinaryRun.playerPosition,
                mapWidth: ordinaryRun.map.width, mapHeight: ordinaryRun.map.height,
                viewportColumns: 11, viewportRows: 14, mapHeightPoints: 466.67))
            try mountedEvidence(store: ordinary, scheme: scheme,
                name: "WORLD-context-50-disabled-no-tutorial-\(suffix)-368x800",
                contextOverPlayer: false)

            let overlapping = try makeStore(overPlayer: true, interactable: false)
            let overlappingRun = try XCTUnwrap(overlapping.activeRun)
            XCTAssertTrue(WorldFieldFeedbackLayout.contextOverlapsPlayer(
                player: overlappingRun.playerPosition,
                mapWidth: overlappingRun.map.width, mapHeight: overlappingRun.map.height,
                viewportColumns: 11, viewportRows: 14, mapHeightPoints: 466.67))
            try mountedEvidence(store: overlapping, scheme: scheme,
                name: "WORLD-context-25-over-player-disabled-no-tutorial-\(suffix)-368x800",
                contextOverPlayer: true)
        }

        let pressed = try makeStore(overPlayer: false, interactable: true)
        try mountedEvidence(store: pressed, scheme: .light,
            name: "WORLD-real-use-tile-pressed-no-tutorial-light-368x800",
            contextOverPlayer: false, pressUseTile: true)
    }

    @MainActor
    func testExplorationMapFinalArtNative368Evidence() throws {
        let store = GameStore(io: .temporary(name: "exploration-art-\(UUID().uuidString)"))
        for lesson in TutorialLessonID.allCases {
            store.completeTutorial(lesson, fact: "visual_fixture")
        }
        XCTAssertTrue(store.bindAndDepart(
            worldPageInstanceID: WorldPageCatalog.earthlikeTestInstance.id),
            "evidence must exercise a real bound world with its production terrain receipt")
        store.mutate("test: exploration final art") { saved in
            guard var run = saved.worlds.activeRun else { return }
            let center = GridPoint(x: run.map.width / 2, y: run.map.height / 2)
            run.playerPosition = center
            run.tuning.baseVisionRadius = max(run.map.width, run.map.height)
            for point in run.map.allPoints {
                run.map[point].isRevealed = true
                run.map[point].elevation = 0
            }
            let nearby = run.map.allPoints.filter {
                $0 != center && abs($0.x - center.x) <= 5 && abs($0.y - center.y) <= 5
            }.sorted { ($0.y, $0.x) < ($1.y, $1.x) }
            let fixed: [TileContent] = [
                .hazard, .portal(isEntry: true), .portal(isEntry: false), .lockedCache,
                .diaryPage("evidence-page"), .foundWriting("evidence-writing"),
                .item(ItemStack(id: InstanceID(rawValue: 80_001), catalogID: "field_maul")),
                .item(ItemStack(id: InstanceID(rawValue: 80_002), catalogID: "salve")),
                .wildDrop(resource: Resources.essenceRaw, amount: 2),
            ]
            for (point, content) in zip(nearby, fixed) { run.map[point].content = content }
            run.sites = []
            for (index, pair) in zip(ContentCatalog.shared.sites.indices,
                                     zip(ContentCatalog.shared.sites, nearby.dropFirst(fixed.count))) {
                let (site, point) = pair
                let instance = InstanceID(rawValue: UInt64(90_000 + index))
                run.sites.append(PlacedSite(id: instance, siteID: site.id, position: point,
                                            isLooted: index.isMultiple(of: 2),
                                            searchTurnsRemaining: 0))
                run.map[point].content = .site(instance)
            }
            saved.worlds.activeRun = run
        }
        var rendered: [UIImage] = []
        for scheme in [ColorScheme.light, .dark] {
            let controller = UIHostingController(rootView: WorldView().environmentObject(store)
                .environment(\.colorScheme, scheme).frame(width: 368, height: 800))
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 368, height: 800))
            window.rootViewController = controller; window.makeKeyAndVisible()
            controller.view.frame = window.bounds; controller.view.layoutIfNeeded()
            RunLoop.main.run(until: Date().addingTimeInterval(0.1))
            let image = UIGraphicsImageRenderer(size: window.bounds.size).image { _ in
                controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
            }
            window.isHidden = true
            XCTAssertEqual(image.size, CGSize(width: 368, height: 800))
            rendered.append(image)
            let attachment = XCTAttachment(image: image)
            attachment.name = "exploration-map-final-art-\(scheme == .light ? "light" : "dark")-368x800"
            attachment.lifetime = .keepAlways; add(attachment)
        }
        let grayscale = try XCTUnwrap(literalGrayscale(rendered[1]))
        let attachment = XCTAttachment(image: grayscale)
        attachment.name = "exploration-map-final-art-grayscale-368x800"
        attachment.lifetime = .keepAlways; add(attachment)
    }

    @MainActor
    func testLooseRawEssenceMountedNative368EvidenceIsGameplayInert() throws {
        UserDefaults.standard.set(false, forKey: "debug.simpleMapRenderer")
        let store = GameStore(io: .temporary(name: "loose-essence-art-\(UUID().uuidString)"))
        for lesson in TutorialLessonID.allCases {
            store.completeTutorial(lesson, fact: "loose_essence_visual_fixture")
        }
        XCTAssertTrue(store.bindAndDepart(
            worldPageInstanceID: WorldPageCatalog.earthlikeTestInstance.id))
        let arrivalID = try XCTUnwrap(store.state.worlds.pendingWorldArrivalReceiptID)
        XCTAssertTrue(store.enterPendingWorld(arrivalReceiptID: arrivalID))
        store.mutate("test mounted Loose Raw Essence", flush: true) { state in
            guard var run = state.worlds.activeRun else { return }
            let center = GridPoint(x: run.map.width / 2, y: run.map.height / 2)
            run.playerPosition = center
            run.tuning.baseVisionRadius = max(run.map.width, run.map.height)
            run.enemies = []
            for point in run.map.allPoints {
                run.map[point].elevation = 0
                run.map[point].isRevealed = true
                run.map[point].isCrumbled = false
                run.map[point].isCracking = false
                run.map[point].flora = nil
                run.map[point].content = .empty
            }
            run.map[GridPoint(x: center.x, y: center.y - 1)].content =
                .wildDrop(resource: Resources.essenceRaw, amount: 2)
            state.worlds.activeRun = run
        }
        let mountedRun = try XCTUnwrap(store.activeRun)
        let mountedCenter = GridPoint(x: mountedRun.map.width / 2, y: mountedRun.map.height / 2)
        XCTAssertEqual(mountedRun.playerPosition, mountedCenter)
        XCTAssertEqual(mountedRun.map[GridPoint(x: mountedCenter.x, y: mountedCenter.y - 1)].content,
                       .wildDrop(resource: Resources.essenceRaw, amount: 2))
        let savedBytes = try SaveCodec.encode(store.state)

        var images: [UIImage] = []
        for scheme in [ColorScheme.light, .dark] {
            let controller = UIHostingController(rootView: WorldView().environmentObject(store)
                .environment(\.colorScheme, scheme).frame(width: 368, height: 800))
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 368, height: 800))
            window.rootViewController = controller; window.makeKeyAndVisible()
            controller.view.frame = window.bounds; controller.view.layoutIfNeeded()
            RunLoop.main.run(until: Date().addingTimeInterval(0.08))
            let image = UIGraphicsImageRenderer(size: window.bounds.size).image { _ in
                controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
            }
            window.isHidden = true
            XCTAssertEqual(WorldMapStageMeasurement.latestFrame.size,
                           CGSize(width: 368, height: 475))
            XCTAssertEqual(try SaveCodec.encode(store.state), savedBytes)
            images.append(image)
            let attachment = XCTAttachment(image: image)
            attachment.name = "loose-raw-essence-\(scheme == .light ? "light" : "dark")-368x800"
            attachment.lifetime = .keepAlways; add(attachment)
        }
        let attachment = XCTAttachment(image: try XCTUnwrap(literalGrayscale(images[1])))
        attachment.name = "loose-raw-essence-grayscale-368x800"
        attachment.lifetime = .keepAlways; add(attachment)
    }

    private let owned = Set(ContentCatalog.shared.starterSymbolIDs)

    private func book(_ symbols: [SlotID: SymbolID]) -> BoundBook {
        BoundBook(symbols: symbols, randomlyFilled: [], essencePaid: 0)
    }

    private func wildPageRun(seed: UInt64) -> WorldRun {
        WorldRun(runIndex: 3, book: book([:]), mapSeed: seed,
                 rng: SeededRNG(seed: seed),
                 map: WorldMap(width: 2, height: 2,
                               tiles: Array(repeating: Tile(), count: 4),
                               entry: GridPoint(x: 0, y: 0)),
                 playerPosition: GridPoint(x: 0, y: 0))
    }

    // MARK: Worldgen

    func testB213aHabitatComponentsUseRepairedStartTopologyAndStableRowMajorIDs() throws {
        let width = 7, height = 5
        var map = WorldMap(width: width, height: height,
                           tiles: Array(repeating: Tile(ground: .chasm), count: width * height),
                           entry: GridPoint(x: 0, y: 2))
        for x in 0...2 { map[GridPoint(x: x, y: 2)] = Tile(ground: .soil) }
        map[GridPoint(x: 3, y: 2)] = Tile(ground: .water)
        for x in 4...6 { map[GridPoint(x: x, y: 2)] = Tile(ground: .deepWater) }
        map[GridPoint(x: 5, y: 0)] = Tile(ground: .deepWater)
        map[GridPoint(x: 6, y: 0)] = Tile(ground: .deepWater)
        map[GridPoint(x: 0, y: 4)] = Tile(ground: .water) // one-tile puddle: unavailable

        let availability = CreatureHabitatAvailability.resolve(
            in: map, from: GridPoint(x: 0, y: 2))
        XCTAssertEqual(availability.components(for: .terrestrial).count, 1)
        let terrestrial = try XCTUnwrap(availability.components(for: .terrestrial).first)
        XCTAssertEqual(terrestrial.id, map.index(of: GridPoint(x: 0, y: 2)))
        XCTAssertEqual(terrestrial.tiles, (0...2).map { GridPoint(x: $0, y: 2) })
        XCTAssertEqual(availability.components(for: .shore).count, 1)
        let shore = try XCTUnwrap(availability.components(for: .shore).first)
        XCTAssertEqual(shore.tiles, [GridPoint(x: 2, y: 2), GridPoint(x: 3, y: 2)])
        XCTAssertTrue(shore.contactEligible)
        let aquatic = availability.components(for: .aquatic)
        XCTAssertEqual(aquatic.map(\.id), [map.index(of: GridPoint(x: 5, y: 0)),
                                            map.index(of: GridPoint(x: 3, y: 2))])
        XCTAssertFalse(aquatic[0].contactEligible)
        XCTAssertTrue(aquatic[1].contactEligible)
        XCTAssertFalse(aquatic.flatMap(\.tiles).contains(GridPoint(x: 0, y: 4)))
        XCTAssertEqual(availability.components(for: .aerial).first?.tiles,
                       (0...3).map { GridPoint(x: $0, y: 2) })
    }

    func testB213aEcologyStreamDoesNotPerturbLegacyGameplayCast() {
        let seed: UInt64 = 0xB2_13_A
        let readings = BookRules.readings(for: book(["biome": "verdant"]), seed: seed)
        let map = WorldMap(width: 5, height: 5,
                           tiles: Array(repeating: Tile(ground: .soil), count: 25),
                           entry: GridPoint(x: 0, y: 2))
        let habitats = CreatureHabitatAvailability.resolve(in: map,
                                                            from: GridPoint(x: 2, y: 2))
        let legacy = LifeRules.cast(for: readings, seed: seed)
        let ecological = LifeRules.cast(for: readings, seed: seed, habitats: habitats)
        XCTAssertEqual(ecological.map(\.id), legacy.map(\.id))
        XCTAssertEqual(ecological.map(\.traits), legacy.map(\.traits))
        XCTAssertEqual(ecological.map(\.worldSeed), legacy.map(\.worldSeed))
        XCTAssertTrue(ecological.allSatisfy { $0.habitat != nil })
    }

    func testB213aGeneratedOrdinaryEnemiesPersistOnlyOnTheirFrozenLegalComponents() throws {
        for seed in (1...18).map({ UInt64($0) * 65_537 }) {
            let generated = Worldgen.generate(
                book: book(["biome": "verdant", "bounty": "teeming_life"]), seed: seed)
            let guardianPoints = Set(generated.sites.filter {
                $0.definition?.contents.guardian != nil
            }.map(\.position))
            let ordinary = generated.enemies.filter {
                !$0.isSessile && !$0.isApex && !guardianPoints.contains($0.position)
            }
            for enemy in ordinary {
                let receipt = try XCTUnwrap(enemy.habitatPlacement)
                XCTAssertTrue(receipt.isValid)
                XCTAssertTrue(receipt.legalTiles.contains(enemy.position))
                XCTAssertEqual(generated.cast.first { $0.id == enemy.speciesID }?.habitat,
                               receipt.habitat)
                switch receipt.habitat {
                case .terrestrial:
                    XCTAssertNotEqual(generated.map[enemy.position].ground, .water)
                    XCTAssertNotEqual(generated.map[enemy.position].ground, .deepWater)
                case .shore:
                    XCTAssertTrue(receipt.legalTiles.contains(enemy.position))
                case .aquatic:
                    XCTAssertTrue([.water, .deepWater].contains(
                        generated.map[enemy.position].ground))
                case .aerial:
                    XCTAssertNotEqual(generated.map[enemy.position].ground, .deepWater)
                    XCTAssertNotEqual(generated.map[enemy.position].ground, .chasm)
                }
            }
            let requiredContact = min(ordinary.count,
                                      max(ordinary.isEmpty ? 0 : 1,
                                          Int(ceil(Double(ordinary.count) * 0.65))))
            XCTAssertGreaterThanOrEqual(ordinary.count {
                $0.habitatPlacement?.contactEligible == true
            }, requiredContact)
        }
    }

    func testB213aHabitatIdentityAndPlacementRoundTripWhileLegacyDecodeStaysNil() throws {
        let tiles = [GridPoint(x: 1, y: 1), GridPoint(x: 2, y: 1)]
        let receipt = CreatureHabitatPlacementReceiptV1(
            habitat: .terrestrial, componentID: 6, legalTiles: tiles, contactEligible: true)
        let species = Species(id: InstanceID(rawValue: 91), traits: CreatureTraits(),
                              worldSeed: 44, habitat: .terrestrial)
        let enemy = WorldEnemy(id: InstanceID(rawValue: 92), speciesID: species.id,
                               traits: species.traits, position: tiles[0],
                               habitatPlacement: receipt)
        XCTAssertEqual(try SaveCodec.makeDecoder().decode(
            Species.self, from: JSONEncoder().encode(species)), species)
        XCTAssertEqual(try SaveCodec.makeDecoder().decode(
            WorldEnemy.self, from: JSONEncoder().encode(enemy)), enemy)

        let legacySpecies = try SaveCodec.makeDecoder().decode(Species.self, from: Data(
            "{\"id\":{\"rawValue\":1},\"traits\":{},\"worldSeed\":2}".utf8))
        let legacyEnemy = try SaveCodec.makeDecoder().decode(WorldEnemy.self, from: Data(
            "{\"id\":{\"rawValue\":3},\"position\":{\"x\":0,\"y\":0}}".utf8))
        XCTAssertNil(legacySpecies.habitat)
        XCTAssertNil(legacyEnemy.habitatPlacement)
    }

    func testB213aRosterSwapPreservesFrozenHabitatComponent() throws {
        let tiles = [GridPoint(x: 1, y: 1), GridPoint(x: 2, y: 1)]
        let receipt = CreatureHabitatPlacementReceiptV1(
            habitat: .terrestrial, componentID: 6, legalTiles: tiles,
            contactEligible: true)
        let day = Species(id: InstanceID(rawValue: 101), traits: CreatureTraits(),
                          worldSeed: 44, habitat: .terrestrial)
        var nightTraits = CreatureTraits()
        nightTraits.sensory = Sensory.allocation(
            vision: 3, mechano: 60, chemo: 30, thermo: 7)
        let night = Species(id: InstanceID(rawValue: 102), traits: nightTraits,
                            worldSeed: 44, habitat: .terrestrial)
        var run = WorldRun(runIndex: 1, book: book([:]), mapSeed: 44,
                           rng: SeededRNG(seed: 44),
                           map: WorldMap(width: 4, height: 4,
                                         tiles: Array(repeating: Tile(), count: 16),
                                         entry: GridPoint(x: 0, y: 0)),
                           playerPosition: GridPoint(x: 0, y: 0),
                           enemies: [WorldEnemy(id: InstanceID(rawValue: 103),
                                                speciesID: day.id, traits: day.traits,
                                                position: tiles[0],
                                                habitatPlacement: receipt)],
                           cast: [day, night])

        WorldRules.swapRoster(in: &run, toNight: true)

        XCTAssertEqual(run.enemies[0].speciesID, night.id)
        XCTAssertEqual(run.enemies[0].position, tiles[0])
        XCTAssertEqual(run.enemies[0].habitatPlacement, receipt)
    }

    func testB213aPursuitCannotLeaveTheFrozenHabitatComponent() {
        let origin = GridPoint(x: 1, y: 1)
        let receipt = CreatureHabitatPlacementReceiptV1(
            habitat: .terrestrial, componentID: 1,
            legalTiles: [GridPoint(x: 1, y: 0), origin], contactEligible: true)
        let species = Species(id: InstanceID(rawValue: 111), traits: CreatureTraits(),
                              worldSeed: 55, habitat: .terrestrial)
        let enemy = WorldEnemy(id: InstanceID(rawValue: 112), speciesID: species.id,
                               traits: species.traits, position: origin,
                               habitatPlacement: receipt, isAwake: true)
        let map = WorldMap(width: 5, height: 4,
                           tiles: Array(repeating: Tile(ground: .soil), count: 20),
                           entry: GridPoint(x: 0, y: 0))
        let run = WorldRun(runIndex: 1, book: book([:]), mapSeed: 55,
                           rng: SeededRNG(seed: 55), map: map,
                           playerPosition: GridPoint(x: 3, y: 1), enemies: [enemy],
                           cast: [species])
        var state = GameState.newGame()
        state.worlds.activeRun = run

        _ = WorldRules.advanceTurn(in: &state)

        XCTAssertEqual(state.worlds.activeRun?.enemies[0].position, origin)
        XCTAssertEqual(state.worlds.activeRun?.enemies[0].habitatPlacement, receipt)
    }

    func testWildWorldPageSelectionIsDeterministicOrderIndependentAndPityGuaranteed() throws {
        let context = WildWorldPageSelectionRules.Context(
            resolvedExpeditions: 5, drought: 5, ownedCopies: [:],
            worldContextTags: ["hydrology", "atmosphere"], suppressesRandomPage: false)
        let first = try XCTUnwrap(WildWorldPageSelectionRules.select(seed: 991, context: context))
        let second = try XCTUnwrap(WildWorldPageSelectionRules.select(
            seed: 991, context: context,
            definitions: Array(WorldPageCatalog.repeatableDefinitions.reversed())))
        XCTAssertEqual(first, second)
        XCTAssertNotEqual(first.instanceID.rawValue, 0)
        XCTAssertEqual(first.definition.id, WorldPageCatalog.definition(first.definition.id)?.id)

        var collision = context
        collision.occupiedInstanceIDs = [first.instanceID]
        let advanced = try XCTUnwrap(WildWorldPageSelectionRules.select(seed: 991,
                                                                         context: collision))
        XCTAssertNotEqual(advanced.instanceID, first.instanceID)
        XCTAssertEqual(advanced.definition, first.definition,
                       "identity collision handling must not reroll authored content")
    }

    func testWildWorldPageSelectionHonoursPacingCopyLimitAndSuppression() {
        let base = WildWorldPageSelectionRules.Context(
            resolvedExpeditions: 1, drought: 5, ownedCopies: [:], worldContextTags: [],
            suppressesRandomPage: false)
        let early = WildWorldPageSelectionRules.select(seed: 4, context: base)
        XCTAssertNotNil(early)
        XCTAssertEqual(early?.definition.minimumResolvedExpeditions, 1)

        var capped = base
        capped.ownedCopies = Dictionary(uniqueKeysWithValues:
            WorldPageCatalog.repeatableDefinitions.map { ($0.id, 2) })
        XCTAssertNil(WildWorldPageSelectionRules.select(seed: 4, context: capped))

        var suppressed = base
        suppressed.suppressesRandomPage = true
        XCTAssertNil(WildWorldPageSelectionRules.select(seed: 4, context: suppressed))

        var opening = base
        opening.resolvedExpeditions = 0
        XCTAssertNil(WildWorldPageSelectionRules.select(seed: 4, context: opening))
    }

    func testWildWorldPageContextWeightingDoesNotEliminateBaselineCandidates() {
        let context = WildWorldPageSelectionRules.Context(
            resolvedExpeditions: 5, drought: 5, ownedCopies: [:],
            worldContextTags: ["hydrology"], suppressesRandomPage: false)
        let selected = (0..<512).compactMap {
            WildWorldPageSelectionRules.select(seed: UInt64($0), context: context)?.definition
        }
        XCTAssertEqual(selected.count, 512)
        XCTAssertTrue(selected.contains { $0.contextTags.contains("hydrology") })
        XCTAssertTrue(selected.contains { !$0.contextTags.contains("hydrology") },
                      "3x context weighting must not make other repeatables unreachable")
    }

    func testWildPagePlacementIsDeterministicReachableAndNeverDisplacesWriting() throws {
        let selection = try XCTUnwrap(WildWorldPageSelectionRules.select(
            seed: 991,
            context: .init(resolvedExpeditions: 5, drought: 5, ownedCopies: [:],
                           worldContextTags: ["hydrology"], suppressesRandomPage: false)))
        var map = WorldMap(width: 4, height: 3,
                           tiles: Array(repeating: Tile(), count: 12),
                           entry: GridPoint(x: 0, y: 1))
        map[map.entry].content = .portal(isEntry: true)
        let writing = GridPoint(x: 1, y: 1)
        map[writing].content = .foundWriting("guaranteed")
        map[GridPoint(x: 2, y: 0)].ground = .chasm
        map[GridPoint(x: 2, y: 1)].ground = .chasm
        map[GridPoint(x: 2, y: 2)].ground = .chasm

        let first = try XCTUnwrap(WildWorldPagePlacementRules.place(
            selection, originRunIndex: 6, originWorldSeed: 991, in: map))
        let second = WildWorldPagePlacementRules.place(
            selection, originRunIndex: 6, originWorldSeed: 991, in: map)
        XCTAssertEqual(first, second)
        XCTAssertNotEqual(first.fieldProvenance?.position, map.entry)
        XCTAssertNotEqual(first.fieldProvenance?.position, writing)
        XCTAssertLessThan(first.fieldProvenance?.position.x ?? 99, 2,
                          "the host must be in the start-connected region")
        XCTAssertEqual(map[writing].content, .foundWriting("guaranteed"))
    }

    func testWildPagePlacementFailsClosedWhenNoReachableEmptyHostExists() throws {
        let selection = try XCTUnwrap(WildWorldPageSelectionRules.select(
            seed: 992,
            context: .init(resolvedExpeditions: 5, drought: 5, ownedCopies: [:],
                           worldContextTags: [], suppressesRandomPage: false)))
        var map = WorldMap(width: 1, height: 1, tiles: [Tile()], entry: GridPoint(x: 0, y: 0))
        map[map.entry].content = .portal(isEntry: true)
        XCTAssertNil(WildWorldPagePlacementRules.place(
            selection, originRunIndex: 6, originWorldSeed: 992, in: map))
    }

    func testWorldgenReservesWildPageAfterGuaranteedWritingBeforeOptionalContent() throws {
        let selection = try XCTUnwrap(WildWorldPageSelectionRules.select(
            seed: 1_404,
            context: .init(resolvedExpeditions: 5, drought: 5, ownedCopies: [:],
                           worldContextTags: [], suppressesRandomPage: false)))
        let generated = Worldgen.generate(
            book: book([:]), seed: 1_404, wildPageSelection: selection,
            wildPageOriginRunIndex: 6)
        let page = try XCTUnwrap(generated.wildPage)
        let point = try XCTUnwrap(page.fieldProvenance?.position)
        XCTAssertTrue(generated.diagnostics.writingWasGuaranteed)
        XCTAssertFalse(generated.pages.isEmpty && generated.writings.isEmpty)
        XCTAssertEqual(generated.map[point].content, .empty,
                       "later optional placement must preserve the reserved overlay host")
        XCTAssertEqual(page.fieldProvenance?.originRunIndex, 6)
        XCTAssertEqual(page.fieldProvenance?.originWorldSeed, 1_404)
    }

    func testStarterPagesPlaceExactDisclosedTierOneFindSafelyNearEntry() throws {
        for instance in WorldPageCatalog.starterInstances {
            let book = BookRules.resolveBook(worldPage: instance)
            let first = Worldgen.generate(book: book, seed: instance.definition.seed)
            let second = Worldgen.generate(book: book, seed: instance.definition.seed)
            let finds = first.map.allPoints.compactMap { point -> (GridPoint, ItemStack)? in
                guard case .item(let stack) = first.map[point].content else { return nil }
                return (point, stack)
            }
            XCTAssertEqual(finds.count, 1)
            let find = try XCTUnwrap(finds.first)
            XCTAssertEqual(find.1.catalogID, instance.definition.knownFind)
            XCTAssertEqual(find.1.id, StarterKnownFindPlacementRules.stableInstanceID(
                for: try XCTUnwrap(book.worldPageUseReceipt)))
            XCTAssertEqual(first.map[find.0], second.map[find.0])
            XCTAssertTrue(first.map[find.0].isRevealed)
            XCTAssertTrue(first.map[find.0].isPassable)
            XCTAssertEqual(first.map[find.0].ground.movementCost, 1)
            var distance: [GridPoint: Int] = [first.start: 0]
            var queue = [first.start]
            while !queue.isEmpty, distance[find.0] == nil {
                let point = queue.removeFirst()
                for next in first.map.neighbours(of: point)
                where distance[next] == nil && first.map[next].isPassable {
                    distance[next] = distance[point, default: 0] + 1
                    queue.append(next)
                }
            }
            XCTAssertTrue((1...2).contains(try XCTUnwrap(distance[find.0])))
        }
    }

    func testArrivalCausalSummaryUsesProductionStagesThroughExactResourceBoundary() throws {
        let cases: [(BoundBook, UInt64)] = [
            (BookRules.resolveBook(worldPage: try XCTUnwrap(
                WorldPageCatalog.starterInstances.first)),
             try XCTUnwrap(WorldPageCatalog.starterInstances.first).definition.seed),
            (book(["terrain": "plains", "bounty": "teeming_life"]), 8_675_309)
        ]
        for (composition, seed) in cases {
            let produced = Worldgen.generate(book: composition, seed: seed)
            let resolved = Worldgen.travellerCausalityReadings(
                authoredSigils: BookRules.sigils(for: composition), seed: seed)
            let summary = Worldgen.arrivalCausalSummary(
                book: composition, seed: seed,
                terrain: .init(readings: resolved.actual,
                               resolvedSigils: resolved.actualSigils),
                library: .init(), tuning: .defaults,
                isFreshFirstExpedition: false,
                wildPageSelection: nil, wildPageOriginRunIndex: nil)

            XCTAssertEqual(summary.flora, produced.flora, "flora stage drifted for seed \(seed)")
            XCTAssertEqual(summary.map.entry, produced.map.entry, "entry stage drifted for seed \(seed)")
            XCTAssertEqual(summary.map.tiles.map(\.ground), produced.map.tiles.map(\.ground),
                           "terrain stage drifted for seed \(seed)")
            XCTAssertEqual(summary.map.tiles.map(\.baseGround), produced.map.tiles.map(\.baseGround),
                           "base terrain stage drifted for seed \(seed)")
            XCTAssertEqual(summary.map.tiles.map(\.surfaceDeposits), produced.map.tiles.map(\.surfaceDeposits),
                           "surface deposit stage drifted for seed \(seed)")
            XCTAssertEqual(summary.map.tiles.map(\.elevation), produced.map.tiles.map(\.elevation),
                           "elevation stage drifted for seed \(seed)")
            XCTAssertEqual(summary.map.tiles.map(\.flora), produced.map.tiles.map(\.flora),
                           "flora placement drifted for seed \(seed)")
            XCTAssertEqual(resourceBoundary(in: summary.map), resourceBoundary(in: produced.map),
                           "resource stages drifted for seed \(seed)")
        }
    }

    private func resourceBoundary(in map: WorldMap) -> [String] {
        map.tiles.enumerated().compactMap { index, tile in
            switch tile.content {
            case .node(let node):
                return "\(index)|node|\(node.resource.rawValue)|\(node.remainingHarvests)|\(node.generatedHarvests.map(String.init) ?? "-")|\(node.yieldPerHarvest)|\(node.secondaryResource?.rawValue ?? "-")|\(node.secondaryYieldPerHarvest)"
            case .wildDrop(let resource, let amount):
                return "\(index)|drop|\(resource.rawValue)|\(amount)"
            default:
                return nil
            }
        }
    }

    func testKnownFindPickupIsAtomicAndLeavesExactItemWhenSatchelIsFull() throws {
        let destination = GridPoint(x: 1, y: 0)
        let promised = ItemStack(id: InstanceID(rawValue: 4_444), catalogID: "field_maul")
        var map = WorldMap(width: 2, height: 1,
                           tiles: [Tile(content: .portal(isEntry: true), isRevealed: true),
                                   Tile(content: .item(promised), isRevealed: true)],
                           entry: GridPoint(x: 0, y: 0))
        var fullRun = WorldRun(runIndex: 1, book: book([:]), mapSeed: 1,
                               rng: SeededRNG(seed: 1), map: map,
                               playerPosition: map.entry,
                               satchelItems: Inventory(slots: 1, stacks: [
                                ItemStack(id: InstanceID(rawValue: 9), catalogID: "bone_awl")
                               ]))
        var fullState = GameState.newGame()
        fullState.worlds.activeRun = fullRun

        let refusal = WorldRules.step(to: destination, in: &fullState)
        XCTAssertTrue(refusal.contains { if case .satchelFull = $0 { true } else { false } })
        XCTAssertEqual(fullState.worlds.activeRun?.map[destination].content, .item(promised))
        XCTAssertEqual(fullState.worlds.activeRun?.satchelItems.stacks.count, 1)

        map[destination].content = .item(promised)
        fullRun = WorldRun(runIndex: 1, book: book([:]), mapSeed: 1,
                           rng: SeededRNG(seed: 1), map: map,
                           playerPosition: map.entry, satchelItems: Inventory(slots: 1))
        var openState = GameState.newGame()
        openState.worlds.activeRun = fullRun
        let pickup = WorldRules.step(to: destination, in: &openState)
        XCTAssertTrue(pickup.contains { if case .pickedUpItem = $0 { true } else { false } })
        XCTAssertEqual(openState.worlds.activeRun?.map[destination].content, .empty)
        XCTAssertEqual(openState.worlds.activeRun?.satchelItems.stacks, [promised])
    }

    func testWorldRunKeepsPagesSeparateWhileChargingSharedSatchelSlots() throws {
        let definition = try XCTUnwrap(WorldPageCatalog.definition("wild_moss_and_mist"))
        let page = WorldPageInstance(id: InstanceID(rawValue: 700), definition: definition,
                                     fieldProvenance: .init(originRunIndex: 2,
                                                            originWorldSeed: 20,
                                                            generationSeed: 30,
                                                            position: GridPoint(x: 1, y: 1)))
        var run = WorldRun(runIndex: 2, book: book([:]), mapSeed: 20,
                           rng: SeededRNG(seed: 20),
                           map: WorldMap(width: 2, height: 2,
                                         tiles: Array(repeating: Tile(), count: 4),
                                         entry: GridPoint(x: 0, y: 0)),
                           playerPosition: GridPoint(x: 0, y: 0),
                           satchelItems: Inventory(slots: 2), carriedWorldPages: [page])
        XCTAssertEqual(run.occupiedSatchelSlots, 1)
        XCTAssertEqual(run.freeSatchelSlots, 1)
        run.offeredWorldPages = [WorldPageInstance(id: InstanceID(rawValue: 701),
                                                   definition: definition)]
        XCTAssertEqual(run.freeSatchelSlots, 1, "offered pages do not occupy the satchel")

        let restored = try SaveCodec.makeDecoder().decode(
            WorldRun.self, from: SaveCodec.makeEncoder().encode(run))
        XCTAssertEqual(restored.carriedWorldPages, [page])
        XCTAssertEqual(restored.offeredWorldPages.map(\.id), [InstanceID(rawValue: 701)])
        XCTAssertTrue(restored.anchoredSnapshot.carriedWorldPages.isEmpty)
        XCTAssertTrue(restored.anchoredSnapshot.offeredWorldPages.isEmpty)
    }

    func testLegacyWorldStateAndRunDecodeWithNoWildPagePayload() throws {
        var worldsObject = try XCTUnwrap(JSONSerialization.jsonObject(
            with: SaveCodec.makeEncoder().encode(
                WorldsState(activeRun: nil, runIndex: 3,
                            seeds: SeedSequence(rootSeed: 9)))) as? [String: Any])
        worldsObject.removeValue(forKey: "randomWorldPageDrought")
        worldsObject.removeValue(forKey: "worldPageBankedOutcomeIDs")
        let worlds = try SaveCodec.makeDecoder().decode(
            WorldsState.self, from: JSONSerialization.data(withJSONObject: worldsObject))
        XCTAssertEqual(worlds.randomWorldPageDrought, 0)
        XCTAssertEqual(worlds.worldPageBankedOutcomeIDs, [])
    }

    func testWildPageInspectAndTakeRevalidateExactPhysicalInstanceAtomically() throws {
        let definition = try XCTUnwrap(WorldPageCatalog.definition("wild_moss_and_mist"))
        let position = GridPoint(x: 1, y: 1)
        let page = WorldPageInstance(
            id: InstanceID(rawValue: 880), definition: definition,
            fieldProvenance: .init(originRunIndex: 3, originWorldSeed: 44, generationSeed: 55,
                                   position: position))
        var run = wildPageRun(seed: 44)
        run.playerPosition = position
        run.map[position].isRevealed = true
        run.offeredWorldPages = [page]

        let quote = try XCTUnwrap(WildWorldPageFieldRules.quote(page.id, in: run))
        XCTAssertEqual(WildWorldPageFieldRules.inspect(quote, in: &run),
                       .inspected(WorldPageInstance(id: page.id, definition: definition,
                                                    inspected: true,
                                                    fieldProvenance: page.fieldProvenance)))
        let staleUninspectedQuote = quote
        let beforeStale = run
        XCTAssertEqual(WildWorldPageFieldRules.take(staleUninspectedQuote, in: &run), .stale)
        XCTAssertEqual(run, beforeStale)

        let fresh = try XCTUnwrap(WildWorldPageFieldRules.quote(page.id, in: run))
        guard case .taken(let taken) = WildWorldPageFieldRules.take(fresh, in: &run) else {
            return XCTFail("expected exact page to be taken")
        }
        XCTAssertTrue(taken.inspected)
        XCTAssertEqual(run.carriedWorldPages, [taken])
        XCTAssertTrue(run.offeredWorldPages.isEmpty)
    }

    func testWildPageTakeRefusesFullSatchelWrongTileAndDuplicateWithoutMutation() throws {
        let definition = try XCTUnwrap(WorldPageCatalog.definition("wild_storm_coast"))
        let position = GridPoint(x: 1, y: 1)
        let page = WorldPageInstance(
            id: InstanceID(rawValue: 881), definition: definition,
            fieldProvenance: .init(originRunIndex: 3, originWorldSeed: 44, generationSeed: 55,
                                   position: position))
        var run = wildPageRun(seed: 44)
        run.playerPosition = position
        run.map[position].isRevealed = true
        run.offeredWorldPages = [page]
        let quote = try XCTUnwrap(WildWorldPageFieldRules.quote(page.id, in: run))

        run.playerPosition = GridPoint(x: 0, y: 0)
        XCTAssertNil(WildWorldPageFieldRules.quote(page.id, in: run))
        run.playerPosition = position
        run.satchelItems.slots = 0
        let full = run
        XCTAssertEqual(WildWorldPageFieldRules.take(quote, in: &run), .satchelFull)
        XCTAssertEqual(run, full)

        run.satchelItems.slots = 1
        run.carriedWorldPages = [page]
        let duplicate = run
        XCTAssertEqual(WildWorldPageFieldRules.take(quote, in: &run), .duplicateIdentity)
        XCTAssertEqual(run, duplicate)
    }

    func testWildPageFullSatchelSwapRevalidatesExactOccupantWithoutLoss() throws {
        let definition = try XCTUnwrap(WorldPageCatalog.definition("wild_storm_coast"))
        let point = GridPoint(x: 1, y: 1)
        let offered = WorldPageInstance(
            id: InstanceID(rawValue: 890), definition: definition, inspected: true,
            fieldProvenance: .init(originRunIndex: 3, originWorldSeed: 44,
                                   generationSeed: 55, position: point))
        var run = wildPageRun(seed: 44)
        run.playerPosition = point
        run.map[point].isRevealed = true
        run.offeredWorldPages = [offered]
        run.satchelItems.slots = 1
        let stack = ItemStack(id: InstanceID(rawValue: 891), catalogID: "salve", count: 2)
        _ = run.satchelItems.add(stack)
        let quote = try XCTUnwrap(WildWorldPageFieldRules.quote(offered.id, in: run))

        let staleBefore = run
        XCTAssertEqual(WildWorldPageFieldRules.swap(
            quote, discarding: .itemStack(InstanceID(rawValue: 999)), in: &run), .stale)
        XCTAssertEqual(run, staleBefore)

        XCTAssertEqual(WildWorldPageFieldRules.swap(
            quote, discarding: .itemStack(stack.id), in: &run),
            .swapped(offered, discarded: .itemStack(stack)))
        XCTAssertEqual(run.carriedWorldPages, [offered])
        XCTAssertTrue(run.offeredWorldPages.isEmpty)
        XCTAssertTrue(run.satchelItems.stacks.isEmpty)
        XCTAssertEqual(run.occupiedSatchelSlots, 1)
    }

    @MainActor
    func testStoreInspectionTeachesOnlyAfterExactVisibleQuoteCommits() throws {
        let definition = try XCTUnwrap(WorldPageCatalog.definition("wild_gilded_caverns"))
        let position = GridPoint(x: 1, y: 1)
        let page = WorldPageInstance(
            id: InstanceID(rawValue: 882), definition: definition,
            fieldProvenance: .init(originRunIndex: 3, originWorldSeed: 45,
                                   generationSeed: 56, position: position))
        var run = wildPageRun(seed: 45)
        run.playerPosition = position
        run.map[position].isRevealed = true
        run.offeredWorldPages = [page]
        let store = GameStore(io: .temporary(name: "wild-page-field-\(UUID().uuidString)"))
        store.mutate("install wild page fixture") { $0.worlds.activeRun = run }

        let quote = try XCTUnwrap(store.offeredWorldPageQuote(page.id))
        XCTAssertEqual(store.state.reality.encounteredLexemes, [])
        guard case .inspected = store.inspectOfferedWorldPage(quote) else {
            return XCTFail("expected inspection")
        }
        XCTAssertEqual(store.state.reality.encounteredLexemes,
                       definition.page.encounteredLexemes)

        let afterInspectionRun = store.state.worlds.activeRun
        let afterInspectionLexemes = store.state.reality.encounteredLexemes
        XCTAssertEqual(store.takeOfferedWorldPage(quote), .stale)
        XCTAssertEqual(store.state.worlds.activeRun, afterInspectionRun)
        XCTAssertEqual(store.state.reality.encounteredLexemes, afterInspectionLexemes)
        let fresh = try XCTUnwrap(store.offeredWorldPageQuote(page.id))
        guard case .taken(let taken) = store.takeOfferedWorldPage(fresh) else {
            return XCTFail("expected exact take")
        }
        XCTAssertEqual(store.state.worlds.activeRun?.carriedWorldPages, [taken])
    }

    func testWildPagesShareOneFailureBudgetWithItemsAndBankIdempotently() throws {
        let firstDefinition = try XCTUnwrap(WorldPageCatalog.definition("wild_moss_and_mist"))
        let secondDefinition = try XCTUnwrap(WorldPageCatalog.definition("wild_storm_coast"))
        var run = wildPageRun(seed: 71)
        run.runIndex = 4
        run.carriedWorldPages = [
            WorldPageInstance(id: InstanceID(rawValue: 901), definition: firstDefinition),
            WorldPageInstance(id: InstanceID(rawValue: 902), definition: secondDefinition)
        ]
        _ = run.satchelItems.add(ItemStack(id: InstanceID(rawValue: 903),
                                           catalogID: "salve", count: 2))
        var state = GameState.newGame()
        state.worlds.randomWorldPageDrought = 4
        let beforeStarterCount = state.base.collectedWorldPages.count

        let first = GameStore.bankHaul(of: run, outcomeID: 71, into: &state, fraction: 0.5)
        let keptItemUnits = first.items.reduce(0) { $0 + $1.count }
        XCTAssertEqual(keptItemUnits + first.keptWorldPages.count, 2,
                       "ceil(4 × 0.5) is one outcome-wide object budget")
        XCTAssertEqual(first.keptWorldPages.count + first.lostWorldPages.count, 2)
        XCTAssertEqual(state.base.collectedWorldPages.count,
                       beforeStarterCount + first.keptWorldPages.count)
        XCTAssertEqual(state.worlds.randomWorldPageDrought,
                       first.keptWorldPages.isEmpty ? 5 : 0)

        let afterFirst = state
        let replay = GameStore.bankHaul(of: run, outcomeID: 71, into: &state, fraction: 0.5)
        XCTAssertEqual(replay.keptWorldPages, first.keptWorldPages)
        XCTAssertEqual(replay.lostWorldPages, first.lostWorldPages)
        XCTAssertEqual(state.base.collectedWorldPages, afterFirst.base.collectedWorldPages)
        XCTAssertEqual(state.worlds.randomWorldPageDrought,
                       afterFirst.worlds.randomWorldPageDrought)
        XCTAssertEqual(state.worlds.worldPageBankedOutcomeIDs, [71])

        let receipt = GameStore.makeReturnReceipt(
            run: run, outcomeID: 71, kind: .collapse, reason: "fixture", fraction: 0.5,
            banked: first, autoRefinedRaw: 0, autoRefinedEssence: 0, springYield: 0,
            state: state)
        let restored = try SaveCodec.makeDecoder().decode(
            RunExitSummary.self, from: SaveCodec.makeEncoder().encode(receipt))
        XCTAssertEqual(restored.keptWorldPages, first.keptWorldPages)
        XCTAssertEqual(restored.lostWorldPages, first.lostWorldPages)
    }

    func testProtectedWildPageIsKeptOutsideZeroFailureBudget() throws {
        var definition = try XCTUnwrap(WorldPageCatalog.definition("wild_mote_understone"))
        definition.disposition = .uniqueProtected
        var run = wildPageRun(seed: 72)
        run.runIndex = 4
        let page = WorldPageInstance(id: InstanceID(rawValue: 904), definition: definition)
        run.carriedWorldPages = [page]
        var state = GameState.newGame()
        let banked = GameStore.bankHaul(of: run, outcomeID: 72, into: &state, fraction: 0)
        XCTAssertEqual(banked.keptWorldPages, [page])
        XCTAssertTrue(banked.lostWorldPages.isEmpty)
    }

    func testSameSeedRegeneratesTheSameWorld() {
        let composition = book(["terrain": "caverns", "biome": "ashen", "bounty": "rich_ore", "quirk": "gilded_veins"])
        let first = Worldgen.generate(book: composition, seed: 8_675_309)
        let second = Worldgen.generate(book: composition, seed: 8_675_309)

        XCTAssertEqual(first.map, second.map)
        XCTAssertEqual(first.enemies, second.enemies)
        XCTAssertEqual(first.start, second.start)
    }

    func testDifferentSeedsGiveDifferentWorlds() {
        let composition = book(["terrain": "plains"])
        XCTAssertNotEqual(Worldgen.generate(book: composition, seed: 1).map,
                          Worldgen.generate(book: composition, seed: 2).map)
    }

    func testNativeMapTerrainSeedUsesFrozenPayloadAndFNV1a() {
        XCTAssertEqual(MapAssetContract.terrainSeed(mapSeed: 0, point: GridPoint(x: 0, y: 0)), 1_940_317_494)
        XCTAssertEqual(MapAssetContract.terrainSeed(mapSeed: 0, point: GridPoint(x: 0, y: 0)) & 3, 2)
        XCTAssertEqual(MapAssetContract.terrainSeed(mapSeed: .max, point: GridPoint(x: 10, y: 10)), 3_919_347_185)
        XCTAssertEqual(MapAssetContract.terrainSeed(mapSeed: .max, point: GridPoint(x: 10, y: 10)) & 3, 1)
    }

    func testNativeMapWorldGradeMatchesCrossLanguageVectors() {
        func readings(thermal: Double, water: Double, life: Double, light: Double, mineral: Double) -> PressureReadings {
            func reading(_ id: PressureTargetID, _ value: Double) -> PressureReading {
                PressureReading(target: id, peak: value, demand: value, floor: value,
                                opposedMagnitude: 0, aspects: [:], forms: [:], tags: [])
            }
            return PressureReadings(readings: [
                "thermal": reading("thermal", thermal), "hydrology": reading("hydrology", water),
                "vitality": reading("vitality", life), "illumination": reading("illumination", light),
                "substrate": reading("substrate", mineral)
            ])
        }
        XCTAssertEqual(WorldGrade.from(readings(thermal: 50, water: 50, life: 50, light: 50, mineral: 50)),
                       WorldGrade(red: 0, green: 0, blue: 0, value: 0))
        XCTAssertEqual(WorldGrade.from(readings(thermal: 90, water: 20, life: 25, light: 80, mineral: 75)),
                       WorldGrade(red: 23, green: -16, blue: -18, value: 12))
        XCTAssertEqual(WorldGrade.from(readings(thermal: 10, water: 90, life: 85, light: 20, mineral: 30)),
                       WorldGrade(red: -22, green: 22, blue: 22, value: -11))
    }

    func testNativeMapPinsCorrectedCanonicalManifest() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let data = try Data(contentsOf: root.appendingPathComponent(
            "AssetLab/integration/terrain-production-pack-v1/runtime/manifest.json"))
        let manifestSHA256 = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        XCTAssertEqual(manifestSHA256, MapAssetContract.manifestSHA256)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(json["canonicalBodySHA256"] as? String, TerrainProductionPack.bodySHA256)
        XCTAssertEqual(json["assetAggregateSHA256"] as? String,
                       TerrainProductionPack.assetAggregateSHA256)
        let runtime = try XCTUnwrap(json["runtimeContract"] as? [String: Any])
        XCTAssertEqual(runtime["tile"] as? [Int],
                       [MapAssetContract.logicalSide, MapAssetContract.logicalSide])
    }

    @MainActor
    func testNativeFloraAdapterMatchesPublishedLiveVectorsAndKeysNormalizedTraits() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let data = try Data(contentsOf: root.appendingPathComponent("AssetLab/integration/map-slice-v1/manifest.json"))
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let contract = try XCTUnwrap(json["liveInputContract"] as? [String: Any])
        let vectors = try XCTUnwrap(contract["floraFixtureVectors"] as? [[String: Any]])

        func flora(from vector: [String: Any]) throws -> Flora {
            let swift = try XCTUnwrap(vector["swift"] as? [String: Any])
            let idObject = try XCTUnwrap(swift["id"] as? [String: Any])
            let id = UInt64(try XCTUnwrap(idObject["rawValue"] as? String))!
            let seed = UInt64(try XCTUnwrap(swift["worldSeed"] as? String))!
            let source = try XCTUnwrap(swift["traits"] as? [String: Any])
            let tissue = try XCTUnwrap(source["tissue"] as? [String: Any])
            let colour = try XCTUnwrap(source["coloration"] as? [String: Any])
            let finish = try XCTUnwrap(source["finish"] as? [String: Any])
            var traits = FloraTraits()
            traits.stature = try XCTUnwrap(source["stature"] as? Double)
            traits.tissue.woody = try XCTUnwrap(tissue["woody"] as? Double)
            traits.tissue.fibrous = try XCTUnwrap(tissue["fibrous"] as? Double)
            traits.tissue.fleshy = try XCTUnwrap(tissue["fleshy"] as? Double)
            traits.defence = try XCTUnwrap(source["defence"] as? Double)
            traits.defenceType = try XCTUnwrap(DefenceType(rawValue: try XCTUnwrap(source["defenceType"] as? String)))
            traits.habit = try XCTUnwrap(Habit(rawValue: try XCTUnwrap(source["habit"] as? String)))
            traits.coloration.cyan = try XCTUnwrap(colour["cyan"] as? Double)
            traits.coloration.magenta = try XCTUnwrap(colour["magenta"] as? Double)
            traits.coloration.yellow = try XCTUnwrap(colour["yellow"] as? Double)
            traits.coloration.depth = try XCTUnwrap(colour["depth"] as? Double)
            traits.coloration.patterning = try XCTUnwrap(colour["patterning"] as? Double)
            traits.finish.opacity = try XCTUnwrap(finish["opacity"] as? Double)
            traits.finish.shine = try XCTUnwrap(finish["shine"] as? Double)
            traits.finish.schiller = try XCTUnwrap(finish["schiller"] as? Double)
            traits.metabolism = try XCTUnwrap(Metabolism(rawValue: try XCTUnwrap(source["metabolism"] as? String)))
            return Flora(id: InstanceID(rawValue: id), traits: traits, worldSeed: seed)
        }

        XCTAssertEqual(vectors.count, 2)
        for vector in vectors {
            let flora = try flora(from: vector)
            let pixels = MapAssetTestSupport.floraPixels(flora)
            let actual = SHA256.hash(data: Data(pixels)).map { String(format: "%02x", $0) }.joined()
            XCTAssertEqual(actual, vector["pixelSha256"] as? String)
        }

        let original = try flora(from: vectors[0])
        var changedTraits = original.traits
        changedTraits.coloration.cyan += 10
        let changed = Flora(id: original.id, traits: changedTraits, worldSeed: original.worldSeed)
        XCTAssertNotEqual(MapAssetTestSupport.floraCacheKey(original), MapAssetTestSupport.floraCacheKey(changed))
        XCTAssertNotEqual(MapAssetTestSupport.floraPixels(original), MapAssetTestSupport.floraPixels(changed))
    }

    @MainActor
    func testNativeLiftedTerrainRasterMatchesAcceptedOpaqueSidewallProfile() {
        // The AssetLab lifted-terrain-v1 pack predates the accepted native correction that gives
        // every elevated tile an opaque logical footprint and shades its actual column sidewall.
        // Pin the resulting native raster here; the structural sidewall/opacity assertions live in
        // TerrainTransitionRenderingTests and must remain green alongside these exact identities.
        let expected = [
            "4feb61edf9dc59743ee4f211bcd4a1872de9d1b2d3ceaf3b6a7af1e2e74b8abc",
            "ed41707efc3839891bc772a910758bdf342cccfe8624c5e0f87d0824c845f661"
        ]
        let vectors: [(GroundType, Int, UInt32, Int, WorldGrade, Int, Int, Bool)] = [
            (.soil, 15, 82_734_192, 2, WorldGrade(red: 14, green: 3, blue: -12, value: -4), 2, 1, false),
            (.stone, 6, 305_419_896, 3, WorldGrade(red: -22, green: 22, blue: 22, value: -11), 3, 3, true)
        ]
        XCTAssertEqual(expected.count, vectors.count)
        for (expectedHash, vector) in zip(expected, vectors) {
            let pixels = MapAssetTestSupport.terrainPixels(ground: vector.0, adjacency: vector.1,
                                                           featureVariant: vector.3, grade: vector.4,
                                                           elevation: vector.5, cracking: vector.7,
                                                           southExposureLevels: vector.6, seed: vector.2)
            let actual = SHA256.hash(data: Data(pixels)).map { String(format: "%02x", $0) }.joined()
            XCTAssertEqual(actual, expectedHash, vector.0.rawValue)
        }
    }

    @MainActor
    func testLiftedTerrainForcesZeroAndNeverBuildsWallsAgainstFogOrBoundary() {
        for ground in [GroundType.water, .deepWater, .chasm, .ice, .growth, .groundcover] {
            var tile = Tile(ground: ground, elevation: 3, isRevealed: true)
            XCTAssertEqual(MapAssetContract.resolvedElevation(for: tile), 0)
            tile.isRevealed = false
            XCTAssertEqual(MapAssetContract.resolvedElevation(for: tile), 0)
        }
        var raised = Tile(ground: .soil, elevation: 3, isRevealed: true)
        XCTAssertEqual(MapAssetContract.resolvedElevation(for: raised), 3)
        raised.isCrumbled = true
        XCTAssertEqual(MapAssetContract.resolvedElevation(for: raised), 0)

        let raisedSurface = Tile(ground: .soil, elevation: 3, isRevealed: true)
        XCTAssertEqual(MapAssetContract.southExposure(center: raisedSurface, south: nil), 0)
        XCTAssertEqual(MapAssetContract.southExposure(
            center: raisedSurface, south: Tile(ground: .soil, elevation: 0, isRevealed: false)), 0)
        XCTAssertEqual(MapAssetContract.southExposure(
            center: raisedSurface, south: Tile(ground: .soil, elevation: 1, isRevealed: true)), 2)
    }

    func testEveryMinimapPOIFamilyIsFogGated() {
        let cases: [(TileContent, MinimapDisclosure.Marker)] = [
            (.portal(isEntry: true), .portal), (.diaryPage("page"), .page),
            (.foundWriting("note"), .page), (.site(InstanceID(rawValue: 1)), .site),
            (.node(ResourceNode(resource: "ore", remainingHarvests: 1, yieldPerHarvest: 1)), .resource),
            (.wildDrop(resource: "essence_raw", amount: 1), .resource),
            (.item(ItemStack(id: InstanceID(rawValue: 44), catalogID: "field_maul")), .item),
            (.traveller("mara"), .traveller),
            (.lockedCache, .cache), (.hazard, .hazard)
        ]
        for (content, expected) in cases {
            XCTAssertNil(MinimapDisclosure.marker(for: Tile(content: content, isRevealed: false), enemy: nil))
            let siteLooted: Bool? = expected == .site ? false : nil
            XCTAssertEqual(MinimapDisclosure.marker(
                for: Tile(content: content, isRevealed: true), enemy: nil,
                siteLooted: siteLooted), expected)
        }
        let ordinary = WorldEnemy(id: InstanceID(rawValue: 2), position: GridPoint(x: 0, y: 0))
        let apex = WorldEnemy(id: InstanceID(rawValue: 3), position: GridPoint(x: 0, y: 0), isApex: true)
        XCTAssertNil(MinimapDisclosure.marker(for: Tile(isRevealed: false), enemy: ordinary))
        XCTAssertNil(MinimapDisclosure.marker(for: Tile(isRevealed: false), enemy: apex))
        XCTAssertEqual(MinimapDisclosure.marker(for: Tile(isRevealed: true), enemy: ordinary), .encounter)
        XCTAssertEqual(MinimapDisclosure.marker(for: Tile(isRevealed: true), enemy: apex), .apex)
        let siteTile = Tile(content: .site(InstanceID(rawValue: 1)), isRevealed: true)
        XCTAssertEqual(MinimapDisclosure.marker(for: siteTile, enemy: nil,
                                                siteLooted: false), .site)
        XCTAssertNil(MinimapDisclosure.marker(for: siteTile, enemy: nil, siteLooted: true),
                     "without an approved depleted minimap identity, the active marker disappears")
        XCTAssertNil(MinimapDisclosure.marker(for: siteTile, enemy: nil, siteLooted: nil),
                     "missing or mismatched site state must fail closed")
    }

    @MainActor
    func testExplorationMapPromotionExhaustivelyLoadsOnlyApprovedKeysAndFrames() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent()
        let receiptURL = root.appendingPathComponent(
            "AssetLab/integration/exploration-map-final-art-promotion-v1/promotion-receipt.json")
        let json = try XCTUnwrap(try JSONSerialization.jsonObject(with: Data(contentsOf: receiptURL))
            as? [String: Any])
        XCTAssertEqual(json["status"] as? String, "aimee-approved-for-native-integration")
        XCTAssertEqual(json["integrationReady"] as? Bool, true)
        let packs = try XCTUnwrap(json["packs"] as? [String: [String: Any]])
        let approved = packs.values.flatMap { $0["approvedStableKeys"] as? [String] ?? [] }.sorted()
        XCTAssertEqual(approved.count, 154)
        let looseEssenceKeys = (0..<4).map { "loose_essence/ordinary/frame-\($0)" }
        let allApproved = (approved + looseEssenceKeys).sorted()
        XCTAssertEqual(MapAssetTestSupport.explorationMapAssetKeys, allApproved)

        for key in allApproved {
            let image = try XCTUnwrap(MapAssetTestSupport.explorationMapImage(key), key)
            let expected = key.hasPrefix("minimap/") ? CGSize(width: 7, height: 7)
                : CGSize(width: 16, height: 19)
            XCTAssertEqual(image.size, expected, key)
        }
        for blocked in ["traveller", "creature", "apex", "binder/", "quill"] {
            XCTAssertFalse(approved.contains { $0.localizedCaseInsensitiveContains(blocked) }, blocked)
        }

        XCTAssertEqual(MapAssetTestSupport.explorationMapFrameKey(
            identity: "entry_portal", tick: 0, remembered: false),
                       "entry_portal/ordinary/frame-0")
        XCTAssertEqual(MapAssetTestSupport.explorationMapFrameKey(
            identity: "entry_portal", tick: 1, remembered: false),
                       "entry_portal/ordinary/frame-1")
        XCTAssertEqual(MapAssetTestSupport.explorationMapFrameKey(
            identity: "entry_portal", tick: 23, remembered: true),
                       "entry_portal/ordinary/frame-0")
        XCTAssertNil(MapAssetTestSupport.explorationMapFrameKey(
            identity: "named_traveller", tick: 0, remembered: false))
        XCTAssertNil(MapAssetTestSupport.explorationMapImage("unapproved/missing"))

        let tileSide: CGFloat = 16
        let assetSize = ExplorationMapIdentityLayout.mapAssetSize(tileSide: tileSide)
        let bottomAligned = CGRect(x: 0, y: tileSide - assetSize.height,
                                   width: assetSize.width, height: assetSize.height)
        XCTAssertEqual(assetSize, CGSize(width: 16, height: 19))
        XCTAssertEqual(bottomAligned.maxY, tileSide, "authored bottom pivot owns tile baseline")
        XCTAssertEqual(bottomAligned.minY, -3, "three authored overhang rows remain above tile")
        XCTAssertEqual(ExplorationMapIdentityLayout.mapPivot, CGPoint(x: 8, y: 18))
    }

    @MainActor
    func testLooseRawEssenceUsesOnlyApprovedPositiveWildDropFramesAndDisclosure() throws {
        let keys = (0..<4).map { "loose_essence/ordinary/frame-\($0)" }
        for key in keys {
            XCTAssertEqual(try XCTUnwrap(MapAssetTestSupport.explorationMapImage(key)).size,
                           CGSize(width: 16, height: 19))
        }

        func key(resource: ResourceID = Resources.essenceRaw, amount: Int = 1,
                 tick: Int = 0, disclosed: Bool = true,
                 remembered: Bool = false) -> String? {
            MapAssetTestSupport.explorationMapKey(
                tile: Tile(content: .wildDrop(resource: resource, amount: amount),
                           isRevealed: disclosed),
                tick: tick, disclosed: disclosed, remembered: remembered)
        }
        XCTAssertEqual((0..<8).compactMap { key(tick: $0) },
                       [keys[0], keys[1], keys[2], keys[3],
                        keys[0], keys[1], keys[2], keys[3]])
        XCTAssertEqual(key(amount: 99, tick: 3), keys[3],
                       "positive amount affects eligibility only, never the temporal frame")
        XCTAssertEqual(key(tick: 3, remembered: true), keys[0])
        XCTAssertNil(key(disclosed: false))
        XCTAssertNil(key(amount: 0))
        XCTAssertNil(key(amount: -1))
        XCTAssertNil(key(resource: Resources.ore))
        XCTAssertNil(MapAssetTestSupport.explorationMapKey(
            tile: Tile(content: .node(ResourceNode(resource: Resources.essenceRaw,
                                                    remainingHarvests: 1,
                                                    yieldPerHarvest: 1)),
                       isRevealed: true)))
        XCTAssertFalse(MapAssetTestSupport.explorationMapKey(
            tile: Tile(content: .item(ItemStack(id: InstanceID(rawValue: 77),
                                                catalogID: "essence_crystal")),
                       isRevealed: true))?.hasPrefix("loose_essence/") == true,
                       "Essence Crystal retains its own catalogue identity")
    }

    @MainActor
    func testLooseRawEssenceMountsInNormalTileConsumerAndOnlyOwnsApprovedBounds() throws {
        let canvas = CGSize(width: 48, height: 54)
        func render(_ content: TileContent, visibility: WorldRules.TileVisibility = .full,
                    revealed: Bool = true, disclosed: Bool = true) -> UIImage {
            let view = ZStack {
                Color.clear
                MapAssetTestSupport.mountedStationaryIdentity(
                    content: content, visibility: visibility, revealed: revealed,
                    disclosed: disclosed, presentationTick: 2)
            }
            .frame(width: canvas.width, height: canvas.height)
            let controller = UIHostingController(rootView: view)
            let window = UIWindow(frame: CGRect(origin: .zero, size: canvas))
            window.rootViewController = controller; window.makeKeyAndVisible()
            controller.view.frame = window.bounds; controller.view.layoutIfNeeded()
            let format = UIGraphicsImageRendererFormat(); format.scale = 1
            let image = UIGraphicsImageRenderer(size: canvas, format: format).image { _ in
                controller.view.drawHierarchy(in: controller.view.bounds,
                                              afterScreenUpdates: true)
            }
            window.isHidden = true
            return image
        }
        func rgba(_ image: UIImage) throws -> Data {
            let cgImage = try XCTUnwrap(image.cgImage)
            var bytes = [UInt8](repeating: 0, count: cgImage.width * cgImage.height * 4)
            let context = try XCTUnwrap(CGContext(
                data: &bytes, width: cgImage.width, height: cgImage.height,
                bitsPerComponent: 8, bytesPerRow: cgImage.width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
            context.draw(cgImage, in: CGRect(x: 0, y: 0,
                                             width: cgImage.width, height: cgImage.height))
            return Data(bytes)
        }
        func changes(_ lhs: UIImage, _ rhs: UIImage) throws -> Set<Int> {
            let a = try rgba(lhs), b = try rgba(rhs)
            XCTAssertEqual(a.count, b.count)
            var result: Set<Int> = []
            for offset in stride(from: 0, to: min(a.count, b.count), by: 4) {
                if a[offset] != b[offset] || a[offset + 1] != b[offset + 1]
                    || a[offset + 2] != b[offset + 2] || a[offset + 3] != b[offset + 3] {
                    result.insert(offset / 4)
                }
            }
            return result
        }

        let empty = render(.empty)
        let essence = render(.wildDrop(resource: Resources.essenceRaw, amount: 1))
        let owned = try changes(essence, empty)
        XCTAssertFalse(owned.isEmpty, "normal renderer must mount the approved essence image")
        let xs = owned.map { $0 % Int(canvas.width) }
        let ys = owned.map { $0 / Int(canvas.width) }
        let actualBounds = CGRect(x: xs.min() ?? 0, y: ys.min() ?? 0,
                                  width: (xs.max() ?? 0) - (xs.min() ?? 0) + 1,
                                  height: (ys.max() ?? 0) - (ys.min() ?? 0) + 1)
        let approvedBounds = CGRect(x: 8, y: 16, width: 32, height: 38)
        XCTAssertEqual(approvedBounds.maxY, canvas.height,
                       "the authored bottom pivot owns the mounted tile baseline")
        XCTAssertTrue(owned.allSatisfy { index in
            approvedBounds.contains(CGPoint(x: index % Int(canvas.width),
                                            y: index / Int(canvas.width)))
        }, "only the scaled 16×19 bottom-pivot asset bounds may change: \(actualBounds)")

        for excluded in [
            TileContent.wildDrop(resource: Resources.essenceRaw, amount: 0),
            .wildDrop(resource: Resources.essenceRaw, amount: -1),
            .wildDrop(resource: Resources.ore, amount: 1)
        ] {
            XCTAssertEqual(try rgba(render(excluded)), try rgba(empty))
        }
        let undisclosed = render(.wildDrop(resource: Resources.essenceRaw, amount: 1),
                                 visibility: .hidden, revealed: false, disclosed: false)
        let undisclosedEmpty = render(.empty, visibility: .hidden,
                                      revealed: false, disclosed: false)
        XCTAssertEqual(try rgba(undisclosed), try rgba(undisclosedEmpty))
    }

    @MainActor
    func testExplorationMinimapUsesExactlySevenCategoryOnlyIdentities() throws {
        let expected = ["minimap/cache/ordinary", "minimap/hazard/ordinary", "minimap/item",
                        "minimap/page/ordinary", "minimap/portal/ordinary",
                        "minimap/resource/ordinary", "minimap/site/ordinary"]
        XCTAssertEqual(MapAssetTestSupport.explorationMapAssetKeys.filter {
            $0.hasPrefix("minimap/")
        }, expected)
        for key in expected {
            XCTAssertNotNil(MapAssetTestSupport.explorationMapImage(key))
        }
        let minimapCellSide = CGFloat(96) / 11
        XCTAssertEqual(ExplorationMapIdentityLayout.minimapCanvas, CGSize(width: 7, height: 7))
        XCTAssertLessThanOrEqual(ExplorationMapIdentityLayout.minimapCanvas.width, minimapCellSide)
    }

    @MainActor
    func testExplorationMapResolverPreservesVisibilityIdentityAndPersistedSiteState() throws {
        XCTAssertNil(MapAssetTestSupport.explorationMapKey(
            tile: Tile(content: .hazard, isRevealed: false), tick: 2, disclosed: false))
        XCTAssertEqual(MapAssetTestSupport.explorationMapKey(
            tile: Tile(content: .hazard, isRevealed: true), tick: 2),
                       "hazard/ordinary/frame-2")
        XCTAssertEqual(MapAssetTestSupport.explorationMapKey(
            tile: Tile(content: .hazard, isRevealed: true), tick: 2, remembered: true),
                       "hazard/ordinary/frame-0")
        XCTAssertFalse(MapAssetTestSupport.stationaryIdentityUsesRememberedFrame(
            currentVisibility: .full, disclosed: true))
        XCTAssertTrue(MapAssetTestSupport.stationaryIdentityUsesRememberedFrame(
            currentVisibility: .fringe, disclosed: true))
        XCTAssertTrue(MapAssetTestSupport.stationaryIdentityUsesRememberedFrame(
            currentVisibility: .hidden, disclosed: true))
        XCTAssertFalse(MapAssetTestSupport.stationaryIdentityUsesRememberedFrame(
            currentVisibility: .fringe, disclosed: false))
        XCTAssertFalse(MapAssetTestSupport.stationaryIdentityUsesRememberedFrame(
            currentVisibility: .hidden, disclosed: false))
        for visibility: WorldRules.TileVisibility in [.fringe, .hidden] {
            let remembered = MapAssetTestSupport.stationaryIdentityUsesRememberedFrame(
                currentVisibility: visibility, disclosed: true)
            XCTAssertEqual(MapAssetTestSupport.explorationMapKey(
                tile: Tile(content: .hazard, isRevealed: true), tick: 2,
                disclosed: true, remembered: remembered), "hazard/ordinary/frame-0")
            XCTAssertNil(MapAssetTestSupport.explorationMapKey(
                tile: Tile(content: .hazard, isRevealed: false), tick: 2,
                disclosed: false, remembered: false))
        }
        XCTAssertEqual(MapAssetTestSupport.explorationMapKey(
            tile: Tile(), hasLooseWorldPage: true), "loose_world_page/ordinary/frame-0")

        XCTAssertEqual(ContentCatalog.shared.sites.count, 9)
        for (offset, site) in ContentCatalog.shared.sites.enumerated() {
            let tile = Tile(content: .site(InstanceID(rawValue: UInt64(offset + 1))),
                            isRevealed: true)
            if site.providesNaturalAnchor {
                XCTAssertEqual(MapAssetTestSupport.explorationMapKey(
                    tile: tile, site: site, siteLooted: true, tick: 2),
                               "natural_anchor/ordinary/frame-2")
            } else {
                XCTAssertNotNil(MapAssetTestSupport.explorationMapKey(
                    tile: tile, site: site, siteLooted: false, tick: 0))
                XCTAssertNotNil(MapAssetTestSupport.explorationMapKey(
                    tile: tile, site: site, siteLooted: true, tick: 0))
                XCTAssertTrue(MapAssetTestSupport.explorationMapKey(
                    tile: tile, site: site, siteLooted: false, tick: 0)?.contains("/unlooted/") == true)
                XCTAssertTrue(MapAssetTestSupport.explorationMapKey(
                    tile: tile, site: site, siteLooted: true, tick: 0)?.contains("/looted/") == true)
            }
        }
    }

    @MainActor
    func testWORLD10DepletedSiteArtRemainsMountedUnderPlayer() throws {
        let site = try XCTUnwrap(ContentCatalog.shared.sites.first { !$0.providesNaturalAnchor })
        let content = TileContent.site(InstanceID(rawValue: 7_001))
        func render(siteLooted: Bool?) -> UIImage {
            let controller = UIHostingController(rootView:
                MapAssetTestSupport.mountedStationaryIdentity(
                    content: content, tileSide: 48, inset: 12,
                    site: site, siteLooted: siteLooted, isPlayer: true))
            let size = CGSize(width: 72, height: 81)
            controller.view.frame = CGRect(origin: .zero, size: size)
            controller.view.backgroundColor = .clear
            controller.view.layoutIfNeeded()
            return UIGraphicsImageRenderer(size: size).image { _ in
                controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
            }
        }
        let depleted = render(siteLooted: true)
        let activeSuppressedByPlayer = render(siteLooted: false)
        XCTAssertNotEqual(depleted.pngData(), activeSuppressedByPlayer.pngData(),
                          "depleted site art must remain visible beneath the occupied player tile")
        let attachment = XCTAttachment(image: depleted)
        attachment.name = "WORLD-10-depleted-site-under-player"
        attachment.lifetime = .keepAlways; add(attachment)
    }

    @MainActor
    func testExplorationMapResolverCoversEveryCatalogueObjectAndOpaqueUnknownIdentity() {
        XCTAssertEqual(ContentCatalog.shared.items.count, 103)
        for (offset, item) in ContentCatalog.shared.items.enumerated() {
            let stack = ItemStack(id: InstanceID(rawValue: UInt64(10_000 + offset)),
                                  catalogID: item.id, identified: true)
            let key = MapAssetTestSupport.explorationMapKey(
                tile: Tile(content: .item(stack), isRevealed: true))
            if item.id == Items.seamlight {
                XCTAssertNil(key, "Seamlight art remains Asset-owned and unpromoted")
                continue
            }
            XCTAssertNotNil(key, item.id.rawValue)
            XCTAssertTrue(key?.contains(item.id.rawValue) == true, item.id.rawValue)
        }
        for id: ItemID in ["curio_humming_shard", "curio_bound_knot"] {
            let hiddenCurio = ItemStack(id: InstanceID(rawValue: 99), catalogID: id,
                                        identified: false)
            XCTAssertEqual(MapAssetTestSupport.explorationMapKey(
                tile: Tile(content: .item(hiddenCurio), isRevealed: true)),
                           "catalogue-item/unknown-curio")
        }
        for id: ItemID in ["field_maul", "salve", "legacy_unknown_item"] {
            let unauthorized = ItemStack(id: InstanceID(rawValue: 100), catalogID: id,
                                         identified: false)
            XCTAssertNil(MapAssetTestSupport.explorationMapKey(
                tile: Tile(content: .item(unauthorized), isRevealed: true)), id.rawValue)
        }
        XCTAssertNil(MapAssetTestSupport.explorationMapKey(
            tile: Tile(content: .traveller("mara"), isRevealed: true)))
    }

    @MainActor
    func testLR01CommittedHarvestCoalescesExactIdentityAndAmountBeforePresentation() throws {
        let batch = WorldFieldEventBatchV1(
            batchID: "mining-a", worldRunID: "1:2", attemptID: 4,
            sourceAction: .harvest, turnBefore: 8, turnAfter: 9,
            orderedEvents: [
                .harvested(Resources.ore, amount: 2, exhausted: false),
                .harvested(Resources.fiber, amount: 1, exhausted: false),
                .harvested(Resources.ore, amount: 3, exhausted: true),
                .harvested(Resources.ore, amount: 0, exhausted: true),
            ], orderedNarrations: ["Harvested."], createdAtMonotonicTime: 10)
        let group = WorldMiningFeedbackGroupV1(
            batchID: batch.batchID, worldRunID: batch.worldRunID,
            sourcePoint: GridPoint(x: 4, y: 5),
            subjects: [
                .init(resourceID: Resources.ore, amount: 5),
            ], startedAtMonotonicTime: 10)
        let presentation = try XCTUnwrap(ResourceMiningFeedbackV1.make(from: group))
        XCTAssertEqual(presentation.batchID, "mining-a")
        XCTAssertEqual(presentation.subjects, [
            .init(resourceID: Resources.ore, amount: 5),
        ])
    }

    @MainActor
    func testLR02MotionIsExactLinear450MillisecondsAndOnePointFiveTiles() {
        let tile = CGRect(x: 120, y: 180, width: 32, height: 32)
        let map = CGRect(x: 0, y: 0, width: 368, height: 368)
        let at0 = ResourceMiningFeedbackV1.center(
            sourceTile: tile, mapViewport: map, contentHeight: 28, elapsedMilliseconds: 0)
        let at180 = ResourceMiningFeedbackV1.center(
            sourceTile: tile, mapViewport: map, contentHeight: 28, elapsedMilliseconds: 180)
        let at450 = ResourceMiningFeedbackV1.center(
            sourceTile: tile, mapViewport: map, contentHeight: 28, elapsedMilliseconds: 450)
        XCTAssertEqual(at0, CGPoint(x: tile.midX, y: tile.minY - 14),
                       "feedback starts immediately above the player/source tile")
        XCTAssertEqual(at180.x, at0.x)
        XCTAssertEqual(at450.x, at0.x)
        XCTAssertEqual(at0.y - at180.y, 19.2, accuracy: 0.001)
        XCTAssertEqual(at0.y - at450.y, 48, accuracy: 0.001)
        XCTAssertEqual(ResourceMiningFeedbackV1.durationMilliseconds, 450)
    }

    func testLR03OpacityIsFullThrough180ThenFadesToZeroAt450() {
        XCTAssertEqual(ResourceMiningFeedbackV1.opacity(elapsedMilliseconds: 0), 1)
        XCTAssertEqual(ResourceMiningFeedbackV1.opacity(elapsedMilliseconds: 180), 1)
        XCTAssertEqual(ResourceMiningFeedbackV1.opacity(elapsedMilliseconds: 315), 0.5, accuracy: 0.001)
        XCTAssertEqual(ResourceMiningFeedbackV1.opacity(elapsedMilliseconds: 450), 0)
    }

    @MainActor
    func testLR04TopEdgeClampsCompleteFeedbackWithoutReverseOrSideMotion() {
        let tile = CGRect(x: 44, y: 8, width: 32, height: 32)
        let map = CGRect(x: 0, y: 0, width: 368, height: 368)
        let end = ResourceMiningFeedbackV1.center(
            sourceTile: tile, mapViewport: map, contentHeight: 28, elapsedMilliseconds: 450)
        XCTAssertEqual(end.x, tile.midX)
        XCTAssertEqual(end.y, 14)
        XCTAssertGreaterThanOrEqual(end.y - 14, map.minY)
        XCTAssertLessThanOrEqual(end.y, tile.midY)

        let ordinaryLabelX = ResourceMiningFeedbackV1.quantityLabelCenterX(
            iconCenterX: 184, iconWidth: 16, labelWidth: 30, mapViewport: map)
        XCTAssertEqual(ordinaryLabelX, 210,
                       "ordinary ×N sits beside an icon that remains source-centered")
        let edgeIconX: CGFloat = 360
        let edgeLabelX = ResourceMiningFeedbackV1.quantityLabelCenterX(
            iconCenterX: edgeIconX, iconWidth: 16, labelWidth: 30, mapViewport: map)
        XCTAssertEqual(edgeIconX, 360, "right-edge icon never moves horizontally")
        XCTAssertEqual(edgeLabelX, 334)
        XCTAssertGreaterThanOrEqual(edgeLabelX - 15, map.minX)
        XCTAssertLessThanOrEqual(edgeLabelX + 15, map.maxX,
                                 "complete ×N label remains inside the map viewport")

        let presentation = ResourceMiningFeedbackV1(
            batchID: "layout-evidence",
            subjects: [.init(resourceID: Resources.timber, amount: 3)])
        let phoneSize = CGSize(width: 368, height: 800)
        let evidenceMap = CGRect(x: 0, y: 216, width: 368, height: 368)
        func attachEvidence(_ name: String, source: CGRect, elapsed: Double) {
            let root = ZStack {
                Color.black
                Rectangle().fill(Color(red: 0.25, green: 0.31, blue: 0.27))
                    .frame(width: evidenceMap.width, height: evidenceMap.height)
                    .position(x: evidenceMap.midX, y: evidenceMap.midY)
                ResourceMiningFeedbackFrame(
                    presentation: presentation, sourceTile: source,
                    mapViewport: evidenceMap, elapsedMilliseconds: elapsed)
            }
            .frame(width: phoneSize.width, height: phoneSize.height)
            let controller = UIHostingController(rootView: root)
            let window = UIWindow(frame: CGRect(origin: .zero, size: phoneSize))
            window.rootViewController = controller; window.makeKeyAndVisible()
            controller.view.frame = window.bounds; controller.view.layoutIfNeeded()
            RunLoop.main.run(until: Date().addingTimeInterval(0.01))
            let image = UIGraphicsImageRenderer(size: phoneSize).image { _ in
                controller.view.drawHierarchy(in: controller.view.bounds,
                                              afterScreenUpdates: true)
            }
            window.isHidden = true
            let attachment = XCTAttachment(image: image)
            attachment.name = name
            attachment.lifetime = .keepAlways; add(attachment)
        }
        let ordinarySource = CGRect(x: 168, y: 384, width: 32, height: 32)
        let edgeSource = CGRect(x: 336, y: 216, width: 32, height: 32)
        for (suffix, elapsed) in [("start", 0.0), ("180ms", 180.0), ("end", 450.0)] {
            attachEvidence("resource-mining-ordinary-\(suffix)-368x800",
                           source: ordinarySource, elapsed: elapsed)
            attachEvidence("resource-mining-right-top-edge-\(suffix)-368x800",
                           source: edgeSource, elapsed: elapsed)
        }
        let pulseStart = DispatchTime.now().uptimeNanoseconds - 90_000_000
        let pulseGroup = WorldMiningFeedbackGroupV1(
            batchID: "pulse-evidence", worldRunID: "1:1",
            sourcePoint: GridPoint(x: 0, y: 0),
            subjects: [.init(resourceID: Resources.timber, amount: 3)],
            startedAtMonotonicTime: pulseStart)
        let pulseRoot = VStack {
            Spacer()
            HStack(spacing: 3) {
                ResourceFieldMarkerIdentity(id: Resources.timber, fallbackSystemIcon: "")
                    .frame(width: 8, height: 8)
                Text("3").font(.footnote.monospacedDigit())
            }
            .padding(8)
            .modifier(ResourceMiningCounterPulse(
                resourceID: Resources.timber, presentations: [pulseGroup]))
            .padding(24)
        }
        .frame(width: phoneSize.width, height: phoneSize.height)
        .background(PixelUITheme.surfaceInset)
        let pulseController = UIHostingController(rootView: pulseRoot)
        let pulseWindow = UIWindow(frame: CGRect(origin: .zero, size: phoneSize))
        pulseWindow.rootViewController = pulseController; pulseWindow.makeKeyAndVisible()
        pulseController.view.frame = pulseWindow.bounds; pulseController.view.layoutIfNeeded()
        let pulseImage = UIGraphicsImageRenderer(size: phoneSize).image { _ in
            pulseController.view.drawHierarchy(in: pulseController.view.bounds,
                                               afterScreenUpdates: true)
        }
        pulseWindow.isHidden = true
        let pulseAttachment = XCTAttachment(image: pulseImage)
        pulseAttachment.name = "resource-mining-independent-stationary-counter-pulse-368x800"
        pulseAttachment.lifetime = .keepAlways; add(pulseAttachment)
    }

    @MainActor
    func testLR05SessionDedupesRejectsWrongRunAndCannotReplayAfterRelaunch() {
        let io = SaveFileIO.temporary(name: "mining-session-\(UUID().uuidString)")
        let store = GameStore(io: io)
        store.mutate("test mining run", flush: true) { state in
            state.worlds.activeRun = self.wildPageRun(seed: 2)
        }
        func batch(_ id: String, resource: ResourceID, runID: String = "3:2")
            -> WorldFieldEventBatchV1 {
            .init(batchID: id, worldRunID: runID, attemptID: 1, sourceAction: .harvest,
                  turnBefore: 0, turnAfter: 1,
                  orderedEvents: [.harvested(resource, amount: 2, exhausted: false)],
                  orderedNarrations: ["Harvested."], createdAtMonotonicTime: 1)
        }
        let first = batch("first", resource: Resources.ore)
        store.claimWorldMiningFeedback(for: first, now: 10)
        XCTAssertEqual(store.worldMiningFeedbackPresentations.map(\.batchID), ["first"])
        store.claimWorldMiningFeedback(for: first, now: 20)
        XCTAssertEqual(store.worldMiningFeedbackPresentations.first?.startedAtMonotonicTime, 10,
                       "remount/reclaim cannot restart a claimed batch")
        store.finishWorldMiningFeedback(expectedBatchID: "first")
        store.claimWorldMiningFeedback(for: first, now: 30)
        XCTAssertTrue(store.worldMiningFeedbackPresentations.isEmpty, "a completed batch never replays")
        store.claimWorldMiningFeedback(for: batch("wrong", resource: Resources.ore,
                                                  runID: "99:99"), now: 40)
        XCTAssertTrue(store.worldMiningFeedbackPresentations.isEmpty)
        store.claimWorldMiningFeedback(for: batch("missing", resource: "future_resource"), now: 50)
        XCTAssertTrue(store.worldMiningFeedbackPresentations.isEmpty, "missing-only visual group fails closed")
        store.claimWorldMiningFeedback(for: batch("valid-next", resource: Resources.fiber), now: 60)
        XCTAssertEqual(store.worldMiningFeedbackPresentations.map(\.batchID), ["valid-next"])
        store.clearWorldFieldFeedback()
        XCTAssertTrue(store.worldMiningFeedbackPresentations.isEmpty)
        let relaunched = GameStore(io: io)
        XCTAssertTrue(relaunched.worldMiningFeedbackPresentations.isEmpty,
                      "transient animation never survives relaunch")
    }

    @MainActor
    func testLR06IndependentTransactionsCoexistWithoutFIFOOrStagger() {
        let store = GameStore(io: .temporary(name: "mining-independent-\(UUID().uuidString)"))
        store.mutate("test mining independent", flush: true) { state in
            state.worlds.activeRun = self.wildPageRun(seed: 2)
        }
        func batch(_ id: String, action: WorldFieldEventBatchV1.SourceAction,
                   resource: ResourceID = Resources.ore) -> WorldFieldEventBatchV1 {
            .init(batchID: id, worldRunID: "3:2", attemptID: UInt64(id.utf8.count),
                  sourceAction: action, turnBefore: 0, turnAfter: 1,
                  orderedEvents: action == .harvest
                    ? [.harvested(resource, amount: 1, exhausted: false)]
                    : [.blocked("Older narration")],
                  orderedNarrations: ["Narration"], createdAtMonotonicTime: 1)
        }
        let older = batch("older", action: .step)
        let a = batch("A", action: .harvest)
        let b = batch("B", action: .harvest, resource: Resources.fiber)
        store.enqueueWorldFieldBatch(older, now: 10)
        XCTAssertTrue(store.worldMiningFeedbackPresentations.isEmpty)
        store.enqueueWorldFieldBatch(a, now: 20)
        store.enqueueWorldFieldBatch(b, now: 30)
        store.enqueueWorldFieldBatch(a, now: 40)
        XCTAssertEqual(store.currentWorldFieldEventBatch?.batchID, "B",
                       "the newest committed interaction must be visible immediately")
        XCTAssertEqual(store.worldFieldEventQueue.map(\.batchID), ["B"])
        XCTAssertEqual(store.worldMiningFeedbackPresentations.map(\.batchID), ["A", "B"])
        XCTAssertEqual(store.worldMiningFeedbackPresentations.map(\.startedAtMonotonicTime), [20, 30])
        store.finishWorldMiningFeedback(expectedBatchID: "A")
        XCTAssertEqual(store.worldMiningFeedbackPresentations.map(\.batchID), ["B"])
        store.finishWorldMiningFeedback(expectedBatchID: "B")
        XCTAssertTrue(store.worldMiningFeedbackPresentations.isEmpty)
        store.clearWorldFieldFeedback()
        XCTAssertTrue(store.worldMiningFeedbackPresentations.isEmpty)
    }

    @MainActor
    func testLR07MultiKindAnimationFailsClosedWithoutChangingCommittedRewards() {
        let store = GameStore(io: .temporary(name: "mining-multikind-\(UUID().uuidString)"))
        store.mutate("test mining multikind", flush: true) { $0.worlds.activeRun = self.wildPageRun(seed: 2) }
        let batch = WorldFieldEventBatchV1(
            batchID: "multi", worldRunID: "3:2", attemptID: 1, sourceAction: .harvest,
            turnBefore: 0, turnAfter: 1,
            orderedEvents: [.harvested(Resources.ore, amount: 2, exhausted: false),
                            .harvested(Resources.fiber, amount: 1, exhausted: false)],
            orderedNarrations: ["Harvested."], createdAtMonotonicTime: 1)
        let bytes = try? SaveCodec.encode(store.state)
        store.claimWorldMiningFeedback(for: batch, now: 2)
        XCTAssertTrue(store.worldMiningFeedbackPresentations.isEmpty)
        XCTAssertEqual(try? SaveCodec.encode(store.state), bytes)
    }

    @MainActor
    func testLR08RefusedZeroAndWrongActionProduceNoPresentationOrMutation() throws {
        let store = GameStore(io: .temporary(name: "mining-refused-\(UUID().uuidString)"))
        store.mutate("test mining refused", flush: true) { $0.worlds.activeRun = self.wildPageRun(seed: 2) }
        let before = try SaveCodec.encode(store.state)
        for (id, action, events) in [
            ("blocked", WorldFieldEventBatchV1.SourceAction.harvest, [WorldRules.Event.blocked("No yield")]),
            ("zero", .harvest, [.harvested(Resources.ore, amount: 0, exhausted: true)]),
            ("step", .step, [.harvested(Resources.ore, amount: 2, exhausted: false)]),
        ] {
            store.claimWorldMiningFeedback(for: .init(
                batchID: id, worldRunID: "3:2", attemptID: 1, sourceAction: action,
                turnBefore: 0, turnAfter: 0, orderedEvents: events,
                orderedNarrations: [], createdAtMonotonicTime: 1))
        }
        XCTAssertTrue(store.worldMiningFeedbackPresentations.isEmpty)
        XCTAssertEqual(try SaveCodec.encode(store.state), before)
    }

    func testLR09CounterPulseIsIndependentAndNeverMovesTheLocalFeedback() {
        XCTAssertEqual(ResourceMiningFeedbackV1.counterPulseOpacity(elapsedMilliseconds: 0), 0)
        XCTAssertEqual(ResourceMiningFeedbackV1.counterPulseOpacity(elapsedMilliseconds: 90), 1)
        XCTAssertEqual(ResourceMiningFeedbackV1.counterPulseOpacity(elapsedMilliseconds: 180), 0)
    }

    func testLR10SourceContainsNoCounterFlightTrajectoryOrLegacyTiming() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let renderer = try String(contentsOf: root.appending(path: "Sources/Screens/MapAssetRenderer.swift"))
        XCTAssertFalse(renderer.contains("quadratic(from:"))
        XCTAssertFalse(renderer.contains("destination:"))
        XCTAssertFalse(renderer.contains(" / 760"))
        XCTAssertFalse(renderer.contains("* 130"))
        XCTAssertFalse(renderer.contains("scaleEffect(2 -"))
        XCTAssertTrue(renderer.contains("durationMilliseconds: Double = 450"))
    }

    @MainActor
    func testLR11AcceptedHarvestCommitsBeforeMountedLocalRiseAndPreservesWorldLayout() throws {
        MiningFeedbackLayoutMeasurement.latestBatchID = nil
        MiningFeedbackLayoutMeasurement.latestSourceTile = nil
        MiningFeedbackLayoutMeasurement.latestMapViewport = nil
        let store = GameStore(io: .temporary(name: "mining-mounted-\(UUID().uuidString)"))
        for lesson in TutorialLessonID.allCases {
            store.completeTutorial(lesson, fact: "mining_local_rise_visual_fixture")
        }
        XCTAssertTrue(store.bindAndDepart(
            worldPageInstanceID: WorldPageCatalog.earthlikeTestInstance.id))
        let arrivalID = try XCTUnwrap(store.state.worlds.pendingWorldArrivalReceiptID)
        XCTAssertTrue(store.enterPendingWorld(arrivalReceiptID: arrivalID))
        store.mutate("test mounted mining", flush: true) { state in
            guard let point = state.worlds.activeRun?.playerPosition else { return }
            state.worlds.activeRun?.map[point].content = .node(ResourceNode(
                resource: Resources.timber, remainingHarvests: 1, yieldPerHarvest: 3,
                secondaryResource: nil, secondaryYieldPerHarvest: 0))
        }
        let controller = UIHostingController(rootView: WorldView().environmentObject(store)
            .frame(width: 368, height: 800))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 368, height: 800))
        window.rootViewController = controller; window.makeKeyAndVisible()
        controller.view.frame = window.bounds; controller.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.04))
        store.harvest()
        XCTAssertEqual(store.activeRun?.satchel[Resources.timber], 3)
        XCTAssertEqual(store.activeRun?.turnsTaken, 1)
        XCTAssertEqual(store.worldMiningFeedbackPresentations.first?.subjects, [
            .init(resourceID: Resources.timber, amount: 3)
        ], "the counter is committed before frame one")
        let miningBatchID = try XCTUnwrap(store.worldMiningFeedbackPresentations.first?.batchID)
        let before = try SaveCodec.encode(store.state)
        RunLoop.main.run(until: Date().addingTimeInterval(0.12))
        XCTAssertEqual(store.worldMiningFeedbackPresentations.first?.batchID, miningBatchID,
                       "the local presentation remains independently owned during its 450 ms lifetime")
        XCTAssertEqual(MiningFeedbackLayoutMeasurement.latestBatchID, miningBatchID,
                       "the mounted consumer must resolve the exact production source anchor")
        let mountedSource = try XCTUnwrap(MiningFeedbackLayoutMeasurement.latestSourceTile)
        let mountedViewport = try XCTUnwrap(MiningFeedbackLayoutMeasurement.latestMapViewport)
        XCTAssertGreaterThanOrEqual(mountedSource.minX, mountedViewport.minX - 0.01)
        XCTAssertGreaterThanOrEqual(mountedSource.minY, mountedViewport.minY - 0.01)
        XCTAssertLessThanOrEqual(mountedSource.maxX, mountedViewport.maxX + 0.01)
        XCTAssertLessThanOrEqual(mountedSource.maxY, mountedViewport.maxY + 0.01,
                                 "the source tile must resolve inside the rendered map viewport")
        XCTAssertEqual(mountedSource.width, mountedViewport.width / 11, accuracy: 0.1,
                       "the production source owns exactly one camera tile")
        let startCenter = ResourceMiningFeedbackV1.center(
            sourceTile: mountedSource, mapViewport: mountedViewport,
            contentHeight: 28, elapsedMilliseconds: 0)
        let endCenter = ResourceMiningFeedbackV1.center(
            sourceTile: mountedSource, mapViewport: mountedViewport,
            contentHeight: 28, elapsedMilliseconds: 450)
        XCTAssertEqual(startCenter.y + 14, mountedSource.minY, accuracy: 0.1,
                       "frame one begins immediately above the player/source tile")
        XCTAssertEqual(startCenter.y - endCenter.y, mountedSource.height * 1.5, accuracy: 0.1,
                       "the production path rises exactly one and a half tile heights")
        XCTAssertEqual(WorldMapStageMeasurement.latestFrame.width, 368, accuracy: 0.5)
        XCTAssertEqual(WorldMapStageMeasurement.latestFrame.height, 475, accuracy: 0.5,
                       "mining overlay cannot alter the measured Explore map geometry")
        XCTAssertEqual(try SaveCodec.encode(store.state), before,
                       "the local presentation is hit-test transparent and gameplay inert")
        window.isHidden = true
    }

    @MainActor
    func testWORLDMiningEvidenceUsesActualWorldPlayerAndProductionOverlay() throws {
        func capture(elapsedMilliseconds target: Double, scheme: ColorScheme,
                     suffix: String) throws {
            MiningFeedbackLayoutMeasurement.latestBatchID = nil
            MiningFeedbackLayoutMeasurement.latestSourceTile = nil
            MiningFeedbackLayoutMeasurement.latestMapViewport = nil
            let store = GameStore(io: .temporary(
                name: "world-mining-evidence-\(suffix)-\(UUID().uuidString)"))
            for lesson in TutorialLessonID.allCases {
                store.completeTutorial(lesson, fact: "world_mining_asset_evidence")
            }
            XCTAssertTrue(store.bindAndDepart(
                worldPageInstanceID: WorldPageCatalog.earthlikeTestInstance.id))
            let arrivalID = try XCTUnwrap(store.state.worlds.pendingWorldArrivalReceiptID)
            XCTAssertTrue(store.enterPendingWorld(arrivalReceiptID: arrivalID))
            store.mutate("test: actual production mining evidence", flush: true) { state in
                guard let point = state.worlds.activeRun?.playerPosition else { return }
                state.worlds.activeRun?.enemies = []
                state.worlds.activeRun?.map[point].isRevealed = true
                state.worlds.activeRun?.map[point].flora = nil
                state.worlds.activeRun?.map[point].content = .node(ResourceNode(
                    resource: Resources.timber, remainingHarvests: 2, yieldPerHarvest: 3,
                    secondaryResource: nil, secondaryYieldPerHarvest: 0))
            }
            let controller = UIHostingController(rootView:
                WorldView().environmentObject(store)
                    .environment(\.colorScheme, scheme).frame(width: 368, height: 800))
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 368, height: 800))
            window.rootViewController = controller; window.makeKeyAndVisible()
            controller.view.frame = window.bounds; controller.view.layoutIfNeeded()
            RunLoop.main.run(until: Date().addingTimeInterval(0.12))
            store.harvest()
            let startedAt = try XCTUnwrap(
                store.worldMiningFeedbackPresentations.first?.startedAtMonotonicTime)
            let frozen = try SaveCodec.encode(store.state)
            while MiningFeedbackLayoutMeasurement.latestSourceTile == nil {
                controller.view.layoutIfNeeded()
                RunLoop.main.run(until: Date().addingTimeInterval(0.002))
            }
            while Double(DispatchTime.now().uptimeNanoseconds &- startedAt) / 1_000_000 < target {
                RunLoop.main.run(until: Date().addingTimeInterval(0.003))
            }
            XCTAssertNotNil(store.worldMiningFeedbackPresentations.first,
                            "the requested capture must precede the 450ms removal")
            controller.view.layoutIfNeeded()
            let source = try XCTUnwrap(MiningFeedbackLayoutMeasurement.latestSourceTile)
            let viewport = try XCTUnwrap(MiningFeedbackLayoutMeasurement.latestMapViewport)
            let start = ResourceMiningFeedbackV1.center(
                sourceTile: source, mapViewport: viewport,
                contentHeight: 28, elapsedMilliseconds: 0)
            let end = ResourceMiningFeedbackV1.center(
                sourceTile: source, mapViewport: viewport,
                contentHeight: 28, elapsedMilliseconds: 450)
            XCTAssertEqual(start.y + 14, source.minY, accuracy: 0.1)
            XCTAssertEqual(start.y - end.y, source.height * 1.5, accuracy: 0.1)
            let image = UIGraphicsImageRenderer(size: window.bounds.size).image { _ in
                controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
            }
            let attachment = XCTAttachment(image: image)
            attachment.name = "WORLD-production-mining-\(suffix)-player-source-visible-368x800"
            attachment.lifetime = .keepAlways; add(attachment)
            XCTAssertEqual(try SaveCodec.encode(store.state), frozen)
            window.isHidden = true
        }

        try capture(elapsedMilliseconds: 0, scheme: .light, suffix: "start-light")
        try capture(elapsedMilliseconds: 225, scheme: .light, suffix: "mid-225ms-light")
        try capture(elapsedMilliseconds: 405, scheme: .light, suffix: "near-end-405ms-light")
        try capture(elapsedMilliseconds: 225, scheme: .dark, suffix: "mid-225ms-dark")
    }

    @MainActor
    func testLR12OwnershipExitCancelsPresentationWithoutGameplayOrSaveMutation() throws {
        let store = GameStore(io: .temporary(name: "mining-cancel-\(UUID().uuidString)"))
        store.mutate("test mining cancel", flush: true) { $0.worlds.activeRun = self.wildPageRun(seed: 2) }
        let batch = WorldFieldEventBatchV1(
            batchID: "cancel", worldRunID: "3:2", attemptID: 1, sourceAction: .harvest,
            turnBefore: 0, turnAfter: 1,
            orderedEvents: [.harvested(Resources.ore, amount: 2, exhausted: false)],
            orderedNarrations: ["Harvested."], createdAtMonotonicTime: 1)
        store.claimWorldMiningFeedback(for: batch, now: 2)
        let before = try SaveCodec.encode(store.state)
        store.clearWorldFieldFeedback()
        XCTAssertTrue(store.worldMiningFeedbackPresentations.isEmpty)
        XCTAssertEqual(try SaveCodec.encode(store.state), before)
    }

    @MainActor
    func testTravellerAdjacentSpeechUsesExactReceiptAndCommittedMovementSession() throws {
        XCTAssertEqual(TravellerAdjacentSpeechV1Registry.textByTravellerID.count, 29)
        XCTAssertEqual(TravellerAdjacentSpeechV1Registry.textByTravellerID["mara"],
                       "\"Don't move. You're the first fixed point I've had in a long while.\"")
        let io = SaveFileIO.temporary(name: "traveller-speech-\(UUID().uuidString)")
        let store = GameStore(io: io)
        var fixture = startedRun(book([:]), seed: 7_701)
        var run = try XCTUnwrap(fixture.worlds.activeRun)
        for index in run.map.tiles.indices {
            run.map.tiles[index].ground = .soil
            run.map.tiles[index].isRevealed = true
            run.map.tiles[index].content = .empty
        }
        let before = GridPoint(x: 5, y: 6), after = GridPoint(x: 5, y: 5)
        let north = GridPoint(x: 5, y: 4), east = GridPoint(x: 6, y: 5)
        run.playerPosition = before
        run.map[north].content = .traveller("mara")
        run.map[east].content = .traveller("tovin")
        fixture.worlds.activeRun = run
        store.mutate("test traveller speech", flush: true) { $0 = fixture }
        store.step(to: after)
        XCTAssertEqual(store.activeRun?.playerPosition, after)
        XCTAssertEqual(store.worldTravellerSpeech?.travellerID, "mara")
        XCTAssertEqual(store.worldTravellerSpeechQueue.map { $0.travellerID }, ["tovin"],
                       "new adjacency is queued North then East")
        let gameplay = try SaveCodec.encode(store.state)
        store.finishWorldTravellerSpeech(expectedTravellerID: "mara")
        XCTAssertEqual(store.worldTravellerSpeech?.travellerID, "tovin")
        XCTAssertEqual(try SaveCodec.encode(store.state), gameplay)
        store.finishWorldTravellerSpeech(expectedTravellerID: "mara")
        XCTAssertEqual(store.worldTravellerSpeech?.travellerID, "tovin",
                       "stale expiry cannot advance a successor")

        store.mutate("prepare refused traveller speech actions", flush: true) { state in
            state.worlds.activeRun?.map[GridPoint(x: 5, y: 6)].ground = .deepWater
            state.worlds.activeRun?.map[GridPoint(x: 8, y: 8)].ground = .deepWater
        }
        let refusedBytes = try SaveCodec.encode(store.state)
        let refusedTurn = store.activeRun?.turnsTaken
        let currentBeforeRefusal = store.worldTravellerSpeech
        let queueBeforeRefusal = store.worldTravellerSpeechQueue

        store.step(to: GridPoint(x: 5, y: 6))
        XCTAssertEqual(store.worldTravellerSpeech, currentBeforeRefusal)
        XCTAssertEqual(store.worldTravellerSpeechQueue, queueBeforeRefusal)
        XCTAssertEqual(store.activeRun?.turnsTaken, refusedTurn)
        XCTAssertEqual(try SaveCodec.encode(store.state), refusedBytes,
                       "a real Deep Water refusal cannot consume speech or mutate saved play")

        store.travel(to: GridPoint(x: 8, y: 8))
        XCTAssertEqual(store.worldTravellerSpeech, currentBeforeRefusal)
        XCTAssertEqual(store.worldTravellerSpeechQueue, queueBeforeRefusal)
        XCTAssertEqual(store.activeRun?.turnsTaken, refusedTurn)
        XCTAssertEqual(try SaveCodec.encode(store.state), refusedBytes,
                       "a real no-path travel cannot consume speech or mutate saved play")

        store.travel(to: after)
        XCTAssertEqual(store.worldTravellerSpeech, currentBeforeRefusal)
        XCTAssertEqual(store.worldTravellerSpeechQueue, queueBeforeRefusal)
        XCTAssertEqual(try SaveCodec.encode(store.state), refusedBytes,
                       "a shared no-op action seam cannot consume speech")

        store.step(to: GridPoint(x: 4, y: 5))
        XCTAssertNil(store.worldTravellerSpeech)
        XCTAssertTrue(store.worldTravellerSpeechQueue.isEmpty)
        XCTAssertEqual(store.activeRun?.turnsTaken, (refusedTurn ?? 0) + 1,
                       "one accepted World action clears presentation after committing")
        store.step(to: after)
        XCTAssertNil(store.worldTravellerSpeech,
                     "accepted movement back beside already-shown travellers cannot repeat them")
        let relaunched = GameStore(io: io)
        XCTAssertNil(relaunched.worldTravellerSpeech)
        XCTAssertTrue(relaunched.worldTravellerSpeechQueue.isEmpty)
    }

    @MainActor
    func testTravellerAdjacentSpeechFailsClosedForDisclosureEncounterAndRetainedAdjacency() throws {
        let store = GameStore(io: .temporary(name: "traveller-speech-closed-\(UUID().uuidString)"))
        var fixture = startedRun(book([:]), seed: 7_702)
        var run = try XCTUnwrap(fixture.worlds.activeRun)
        for index in run.map.tiles.indices {
            run.map.tiles[index].ground = .soil
            run.map.tiles[index].isRevealed = true
            run.map.tiles[index].content = .empty
        }
        let before = GridPoint(x: 5, y: 6), after = GridPoint(x: 5, y: 5)
        let north = GridPoint(x: 5, y: 4)
        run.playerPosition = after
        run.map[north].content = .traveller("mara")
        fixture.worlds.activeRun = run
        store.mutate("test traveller disclosure", flush: true) { $0 = fixture }
        store.presentTravellerSpeechAfterMovement(from: before, sourceAction: .step)
        XCTAssertEqual(store.worldTravellerSpeech?.travellerID, "mara")
        store.clearWorldTravellerSpeechSession()
        store.mutate("hide traveller") { state in
            state.worlds.activeRun?.map[north].isRevealed = false
        }
        store.presentTravellerSpeechAfterMovement(from: before, sourceAction: .step)
        XCTAssertNil(store.worldTravellerSpeech)
        store.mutate("reveal traveller") { state in
            state.worlds.activeRun?.map[north].isRevealed = true
            state.worlds.activeRun?.map[north].isCrumbled = true
        }
        store.presentTravellerSpeechAfterMovement(from: before, sourceAction: .step)
        XCTAssertNil(store.worldTravellerSpeech, "crumbled traveller tiles fail closed")
        store.mutate("restore traveller tile") { state in
            state.worlds.activeRun?.map[north].isCrumbled = false
        }
        store.presentTravellerSpeechAfterMovement(from: GridPoint(x: 5, y: 3),
                                                   sourceAction: .travel)
        XCTAssertNil(store.worldTravellerSpeech,
                     "retained adjacency is not newly created by the presented movement")

        store.clearWorldTravellerSpeechSession()
        store.mutate("four speech directions") { state in
            state.worlds.activeRun?.map[GridPoint(x: 5, y: 4)].content = .traveller("mara")
            state.worlds.activeRun?.map[GridPoint(x: 6, y: 5)].content = .traveller("tovin")
            state.worlds.activeRun?.map[GridPoint(x: 5, y: 6)].content = .traveller("oda")
            state.worlds.activeRun?.map[GridPoint(x: 4, y: 5)].content = .traveller("noll")
        }
        store.presentTravellerSpeechAfterMovement(from: GridPoint(x: 5, y: 8),
                                                   sourceAction: .step)
        XCTAssertNil(store.worldTravellerSpeech,
                     "a step candidate must be exactly one cardinal move")
        store.presentTravellerSpeechAfterMovement(from: GridPoint(x: 5, y: 8),
                                                   sourceAction: .travel)
        XCTAssertEqual(store.worldTravellerSpeech?.travellerID, "mara")
        XCTAssertEqual(store.worldTravellerSpeechQueue.map { $0.travellerID },
                       ["tovin", "oda", "noll"], "ordering is North, East, South, West")
    }

    @MainActor
    func testTravellerAdjacentSpeechUsesActualAutoTravelFinalPositionOnly() throws {
        let store = GameStore(io: .temporary(name: "traveller-speech-travel-\(UUID().uuidString)"))
        var fixture = startedRun(book([:]), seed: 7_704)
        var run = try XCTUnwrap(fixture.worlds.activeRun)
        for index in run.map.tiles.indices {
            run.map.tiles[index].ground = .soil
            run.map.tiles[index].baseGround = .soil
            run.map.tiles[index].isRevealed = true
            run.map.tiles[index].isCrumbled = false
            run.map.tiles[index].content = .empty
        }
        run.playerPosition = GridPoint(x: 5, y: 8)
        run.enemies = []
        run.map[GridPoint(x: 5, y: 4)].content = .traveller("oda")
        fixture.worlds.activeRun = run
        store.mutate("test traveller auto travel", flush: true) { $0 = fixture }
        store.travel(to: GridPoint(x: 5, y: 5))
        XCTAssertEqual(store.activeRun?.playerPosition, GridPoint(x: 5, y: 5))
        XCTAssertEqual(store.worldTravellerSpeech?.travellerID, "oda")
        XCTAssertEqual(store.worldTravellerSpeech?.point, GridPoint(x: 5, y: 4))
    }

    @MainActor
    func testTravellerBubblePlacementAndMountedWorldRemainInMapAndGameplayInert() throws {
        let top = TravellerSpeechBubblePlacement.resolve(
            anchor: CGPoint(x: 18, y: 40), stageSize: CGSize(width: 368, height: 368))
        let bottom = TravellerSpeechBubblePlacement.resolve(
            anchor: CGPoint(x: 350, y: 350), stageSize: CGSize(width: 368, height: 368))
        for placement in [top, bottom] {
            XCTAssertGreaterThanOrEqual(placement.center.x - placement.width / 2, 8)
            XCTAssertLessThanOrEqual(placement.center.x + placement.width / 2, 360)
            XCTAssertGreaterThanOrEqual(placement.center.y - placement.height / 2, 8)
            XCTAssertLessThanOrEqual(placement.center.y + placement.height / 2, 360)
            XCTAssertGreaterThanOrEqual(placement.tailX, 12)
            XCTAssertLessThanOrEqual(placement.tailX, placement.width - 12)
        }
        XCTAssertFalse(top.isAboveTraveller); XCTAssertTrue(bottom.isAboveTraveller)

        let store = GameStore(io: .temporary(name: "traveller-speech-mounted-\(UUID().uuidString)"))
        var fixture = startedRun(book([:]), seed: 7_703)
        var run = try XCTUnwrap(fixture.worlds.activeRun)
        for index in run.map.tiles.indices {
            run.map.tiles[index].ground = .soil
            run.map.tiles[index].isRevealed = true
            run.map.tiles[index].content = .empty
        }
        let before = GridPoint(x: 5, y: 6), after = GridPoint(x: 5, y: 5)
        run.playerPosition = before
        run.map[GridPoint(x: 5, y: 4)].content = .traveller("mara")
        fixture.worlds.activeRun = run
        for lesson in TutorialLessonID.allCases {
            fixture.tutorial.complete(lesson, fact: "traveller_speech_visual_fixture")
        }
        store.mutate("test mounted traveller speech", flush: true) { $0 = fixture }
        store.step(to: after)
        XCTAssertEqual(store.worldTravellerSpeech?.travellerID, "mara")
        let controller = UIHostingController(rootView:
            WorldView().environmentObject(store).frame(width: 368, height: 800))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 368, height: 800))
        window.rootViewController = controller; window.makeKeyAndVisible()
        controller.view.frame = window.bounds; controller.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.04))
        let frozen = try SaveCodec.encode(store.state)
        RunLoop.main.run(until: Date().addingTimeInterval(0.20))
        controller.view.layoutIfNeeded()
        XCTAssertEqual(store.worldTravellerSpeech?.travellerID, "mara")
        XCTAssertEqual(WorldMapStageMeasurement.latestFrame.width, 368, accuracy: 0.5)
        XCTAssertEqual(WorldMapStageMeasurement.latestFrame.height, 475, accuracy: 0.5)
        XCTAssertEqual(try SaveCodec.encode(store.state), frozen)
        let image = UIGraphicsImageRenderer(size: window.bounds.size).image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
        window.isHidden = true
        let attachment = XCTAttachment(image: image)
        attachment.name = "traveller-adjacent-speech-368x800"
        attachment.lifetime = .keepAlways; add(attachment)
    }

    func testMinimapTerrainStyleIsOpaqueNonblackAndIndependentOfRememberedContent() {
        for appearance in MinimapTerrainStyle.Appearance.allCases {
            var classes = Set<String>()
            for ground in GroundType.allCases {
                let hiddenA = MinimapTerrainStyle.resolve(
                    tile: Tile(content: .hazard, ground: ground, isRevealed: false),
                    appearance: appearance)
                let hiddenB = MinimapTerrainStyle.resolve(
                    tile: Tile(content: .lockedCache, ground: ground, isRevealed: false),
                    appearance: appearance)
                XCTAssertEqual(hiddenA, hiddenB, "hidden facts must not alter minimap output")
                XCTAssertEqual(hiddenA.terrainClass, .hidden)
                XCTAssertEqual(hiddenA.fill, .init(red: 0, green: 0, blue: 0, alpha: 255))

                let empty = MinimapTerrainStyle.resolve(
                    tile: Tile(content: .empty, ground: ground, isRevealed: true),
                    appearance: appearance)
                let occupied = MinimapTerrainStyle.resolve(
                    tile: Tile(content: .hazard, ground: ground, isRevealed: true),
                    appearance: appearance)
                XCTAssertEqual(empty, occupied,
                               "terrain fill must not encode a disclosed POI's identity")
                XCTAssertEqual(empty.fill.alpha, 255)
                XCTAssertGreaterThan(empty.fill.luminance, 20,
                                     "remembered \(ground.rawValue) must remain visibly nonblack")
                classes.insert(String(describing: empty.terrainClass))
            }
            XCTAssertEqual(classes.count, 8, "all semantic ground families must remain represented")

            var crumbled = Tile(ground: .soil, isRevealed: true, isCrumbled: true)
            crumbled.content = .hazard
            let void = MinimapTerrainStyle.resolve(tile: crumbled, appearance: appearance)
            XCTAssertEqual(void.terrainClass, .crumbled)
            XCTAssertEqual(void.fill.alpha, 255)
            XCTAssertGreaterThan(void.fill.luminance, 20)
            XCTAssertNotEqual(void, MinimapTerrainStyle.resolve(
                tile: Tile(ground: .soil, isRevealed: true), appearance: appearance))
        }
    }

    func testMinimapFringeHiddenMutationAndRelaunchRemainDisclosureSafe() throws {
        let player = GridPoint(x: 1, y: 1)
        let fringe = GridPoint(x: 3, y: 1)
        var map = WorldMap(width: 5, height: 3,
                           tiles: Array(repeating: Tile(ground: .soil), count: 15), entry: player)
        map[player].isRevealed = true
        let profile = WorldRules.VisibilityProfile(
            illumination: 100, fullRadius: 1, fringeWidth: 2, fringeOpacity: 0.5,
            atmosphericBlurPoints: 0, obscurantDensity: 0)
        XCTAssertEqual(WorldRules.visibility(of: fringe, from: player, in: map, profile: profile),
                       .fringe)
        XCTAssertFalse(map[fringe].isRevealed)

        let before = MinimapTerrainStyle.resolve(tile: map[fringe], appearance: .dark)
        map[fringe].ground = .deepWater
        map[fringe].content = .hazard
        map[fringe].isCrumbled = true
        let after = MinimapTerrainStyle.resolve(tile: map[fringe], appearance: .dark)
        XCTAssertEqual(before, after)
        XCTAssertEqual(after.terrainClass, .hidden)
        XCTAssertNil(MinimapDisclosure.marker(for: map[fringe], enemy: nil))

        map[GridPoint(x: 0, y: 0)] = Tile(content: .hazard, ground: .growth, isRevealed: true)
        let run = WorldRun(runIndex: 1, book: book([:]), mapSeed: 44, rng: SeededRNG(seed: 44),
                           map: map, playerPosition: player)
        let data = try SaveCodec.makeEncoder().encode(run)
        let restored = try SaveCodec.makeDecoder().decode(WorldRun.self, from: data)
        XCTAssertEqual(try SaveCodec.makeEncoder().encode(restored), data)
        for appearance in MinimapTerrainStyle.Appearance.allCases {
            XCTAssertEqual(
                run.map.allPoints.map { MinimapTerrainStyle.resolve(
                    tile: run.map[$0], appearance: appearance) },
                restored.map.allPoints.map { MinimapTerrainStyle.resolve(
                    tile: restored.map[$0], appearance: appearance) })
        }
        XCTAssertEqual(MinimapDisclosure.marker(at: GridPoint(x: 0, y: 0), in: restored), .hazard)
        XCTAssertNil(MinimapDisclosure.marker(at: fringe, in: restored))
    }

    @MainActor
    func testMinimapOpaqueTerrainNativePhoneEvidence() throws {
        let run = minimapEvidenceRun()
        let darkCrop = minimapImage(run: run, scheme: .dark, size: CGSize(width: 96, height: 96))
        let lightCrop = minimapImage(run: run, scheme: .light, size: CGSize(width: 96, height: 96))
        let darkPhone = minimapPhoneEvidence(run: run, scheme: .dark)
        let lightPhone = minimapPhoneEvidence(run: run, scheme: .light)
        let grayscale = try XCTUnwrap(literalGrayscale(darkPhone))
        let enlarged = nearestNeighbor(darkCrop, size: CGSize(width: 384, height: 384))
        XCTAssertEqual(darkCrop.pngData(), minimapImage(
            run: run, scheme: .dark, size: CGSize(width: 96, height: 96)).pngData(),
                       "identical minimap facts must redraw byte-identically")
        XCTAssertEqual(darkPhone.size, CGSize(width: 368, height: 800))
        XCTAssertEqual(lightPhone.size, CGSize(width: 368, height: 800))
        XCTAssertEqual(grayscale.size, CGSize(width: 368, height: 800))
        XCTAssertEqual(enlarged.size, CGSize(width: 384, height: 384))
        for (name, image) in [
            ("minimap-opaque-terrain-dark-368x800", darkPhone),
            ("minimap-opaque-terrain-grayscale-368x800", grayscale),
            ("minimap-opaque-terrain-light-368x800", lightPhone),
            ("minimap-opaque-terrain-native-96x96", darkCrop),
            ("minimap-opaque-terrain-light-native-96x96", lightCrop),
            ("minimap-opaque-terrain-400-percent", enlarged),
        ] {
            let attachment = XCTAttachment(image: image)
            attachment.name = name
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }

    func testMinimapDoesNotLeakSleepingCrypsisOnRevealedTerrain() {
        let player = GridPoint(x: 1, y: 1)
        let distant = GridPoint(x: 5, y: 1)
        let adjacent = GridPoint(x: 2, y: 1)
        var map = WorldMap(width: 7, height: 3,
                           tiles: Array(repeating: Tile(ground: .soil, isRevealed: true), count: 21),
                           entry: player)
        map[player].content = .portal(isEntry: true)
        var tuning = DebugTuningProfile.defaults
        tuning.baseVisionRadius = 1
        var traits = CreatureTraits()
        traits.defence = .crypsis
        var subject = WorldEnemy(id: InstanceID(rawValue: 77), traits: traits, position: distant)
        let unrelated = WorldEnemy(id: InstanceID(rawValue: 88), position: GridPoint(x: 6, y: 2))

        func run(enemies: [WorldEnemy]) -> WorldRun {
            WorldRun(runIndex: 1, book: book([:]), mapSeed: 1, rng: SeededRNG(seed: 1),
                     map: map, playerPosition: player, enemies: enemies, tuning: tuning)
        }
        func assertMarker(_ expected: MinimapDisclosure.Marker?, subject: WorldEnemy,
                          file: StaticString = #filePath, line: UInt = #line) {
            for enemies in [[subject, unrelated], [unrelated, subject]] {
                XCTAssertEqual(MinimapDisclosure.marker(at: subject.position, in: run(enemies: enemies)),
                               expected, "enemy order must not alter disclosure", file: file, line: line)
            }
        }

        assertMarker(nil, subject: subject)
        XCTAssertEqual(subject.awareness, .unaware)
        subject.isAwake = true
        assertMarker(nil, subject: subject)
        subject.position = adjacent
        assertMarker(.encounter, subject: subject)
    }

    /// Acceptance criterion: two books with different symbols must produce visibly different worlds.
    func testGreedyBooksProduceDenserMoreDangerousWorlds() {
        // Averaged over seeds — any single world can be an outlier.
        var calmNodes = 0, greedyNodes = 0, calmEnemies = 0, greedyEnemies = 0
        // **Same terrain and biome on both sides**, so only the greed dials differ — the bounty and
        // the quirk. Population answers to vitality now (Aimee, 6 Aug), so a pairing that also
        // swapped verdant for ashen would be measuring how *alive* the two worlds are rather than
        // how greedy, and an ash-choked world genuinely should hold less.
        let calm = book(["terrain": "plains", "biome": "verdant", "bounty": "sparse_ore", "quirk": "dim_sky"])
        let greedy = book(["terrain": "plains", "biome": "verdant", "bounty": "rich_ore", "quirk": "gilded_veins"])

        for seed in (1...25).map({ UInt64($0) &* 1_000_003 }) {
            let a = Worldgen.generate(book: calm, seed: seed)
            let b = Worldgen.generate(book: greedy, seed: seed)
            calmNodes += a.map.tiles.count { if case .node = $0.content { true } else { false } }
            greedyNodes += b.map.tiles.count { if case .node = $0.content { true } else { false } }
            calmEnemies += a.enemies.count
            greedyEnemies += b.enemies.count
        }

        XCTAssertGreaterThan(greedyNodes, calmNodes, "A greedier book must put more on the ground")
        XCTAssertGreaterThan(greedyEnemies, calmEnemies, "…and more in the way")
    }

    func testEveryWorldHasAnEntryAndAtLeastOneOtherPortal() {
        for seed in (1...30).map({ UInt64($0) &* 65_537 }) {
            let world = Worldgen.generate(book: book(["terrain": "plains"]), seed: seed)
            XCTAssertNotEqual(world.start, world.map.entry)
            XCTAssertEqual(world.map[world.start].content, .empty)
            XCTAssertEqual(world.map[world.map.entry].content, .portal(isEntry: true))
            XCTAssertTrue(TerrainRules.reachable(from: world.start, in: world.map)
                .contains(world.map.entry))
            let portals = world.map.tiles.count { $0.content.isPortal }
            XCTAssertGreaterThanOrEqual(portals, 2, "Brief requires at least one exit besides the entry")
        }
    }

    func testNothingIsPlacedOnTopOfAnythingElse() {
        let world = Worldgen.generate(book: book(["bounty": "teeming_life"]), seed: 4242)
        var seen = Set<GridPoint>()
        for point in world.map.allPoints where world.map[point].content != .empty {
            XCTAssertTrue(seen.insert(point).inserted)
        }
        // A guardian stands *on* its site — the fight is the price of the search, not a separate
        // mechanic (`sites-system.md`). Everything else stands on open ground.
        let guarded = Set(world.sites.filter { $0.definition?.contents.guardian != nil }.map(\.position))
        for enemy in world.enemies where !guarded.contains(enemy.position) {
            XCTAssertEqual(world.map[enemy.position].content, .empty, "Enemies stand on open ground")
        }
    }

    func testYouDoNotArriveNextToAnEnemy() {
        for seed in (1...30).map({ UInt64($0) &* 2_654_435_761 }) {
            let world = Worldgen.generate(book: book(["biome": "ashen"]), seed: seed)
            for enemy in world.enemies {
                XCTAssertGreaterThanOrEqual(
                    enemy.position.chebyshevDistance(to: world.start),
                    Tuning.World.enemyFreeRadiusAroundEntry,
                    "No ambush the moment you arrive (seed \(seed), enemy \(enemy.position), "
                        + "start \(world.start), apex \(enemy.isApex), sessile \(enemy.isSessile), "
                        + "guardian \(world.sites.contains { $0.position == enemy.position }))"
                )
            }
        }
    }

    /// Dim Sky's paired tradeoff: a longer-lived world costs you a ring of sight.
    func testDimSkyReducesVision() {
        let plain = book(["terrain": "plains"])
        let dim = book(["terrain": "plains", "quirk": "dim_sky"])
        XCTAssertLessThan(WorldRules.visionRadius(for: dim, seed: 0),
                          WorldRules.visionRadius(for: plain, seed: 0))
        XCTAssertGreaterThanOrEqual(WorldRules.visionRadius(for: dim, seed: 0),
                                    Tuning.World.minimumVisionRadius)

        // Measure the two radii on deliberately open ground. A generated fixture makes this claim
        // depend on whichever chance-filled focuses happen to exist in the content catalogue: a
        // ridge or thicket beside the entry can hide both outer rings and make the counts equal.
        let centre = GridPoint(x: 5, y: 5)
        let openMap = WorldMap(width: 11, height: 11,
                               tiles: Array(repeating: Tile(), count: 121), entry: centre)
        func revealed(radius: Int) -> Int {
            var map = openMap
            WorldRules.reveal(around: centre, in: &map, radius: radius)
            return map.revealedCount
        }
        XCTAssertLessThan(revealed(radius: WorldRules.visionRadius(for: dim, seed: 0)),
                          revealed(radius: WorldRules.visionRadius(for: plain, seed: 0)),
                          "You arrive seeing less of a dim world")
    }

    func testExpeditionTuningChangesProjectionAndIsSnapshottedOnTheRun() throws {
        let composition = book(["terrain": "plains"])
        var tuning = DebugTuningProfile.defaults
        tuning.stabilityDurationMultiplier = 2
        tuning.collapseRecoveryFraction = 1
        tuning.baseVisionRadius = Tuning.World.baseVisionRadius + 2
        tuning.slowGroundExtraTurns = 3
        tuning.activeFloraFrequencyMultiplier = 0
        tuning.floraHazardSeverityMultiplier = 2

        let ordinary = BookProjection.project(page: Page(), seed: 991)
        let tuned = BookProjection.project(page: Page(), seed: 991, tuning: tuning)
        XCTAssertEqual(tuned.turnsUntilCollapse.lowerBound,
                       ordinary.turnsUntilCollapse.lowerBound * 2)
        XCTAssertGreaterThan(tuned.visionRadius.lowerBound, ordinary.visionRadius.lowerBound)

        let generated = Worldgen.generate(book: composition, seed: 991, tuning: tuning)
        let run = WorldRun(runIndex: 1, book: composition, mapSeed: 991,
                           rng: SeededRNG(seed: 991), map: generated.map,
                           playerPosition: generated.start, tuning: tuning)
        let baseline = WorldRun(runIndex: 1, book: composition, mapSeed: 991,
                                rng: SeededRNG(seed: 991), map: generated.map,
                                playerPosition: generated.start)
        XCTAssertEqual(run.decayPerTurn, baseline.decayPerTurn / 2, accuracy: 0.000_001)
        XCTAssertGreaterThan(WorldRules.visionRadius(in: run), WorldRules.visionRadius(in: baseline))

        let data = try SaveCodec.makeEncoder().encode(run)
        XCTAssertEqual(try SaveCodec.makeDecoder().decode(WorldRun.self, from: data).tuning, tuning)
    }

    func testSlowGroundDebugCostUsesTheRunSnapshot() {
        XCTAssertEqual(WorldRules.movementCost(.growth, slowGroundExtraTurns: 0), 1)
        XCTAssertEqual(WorldRules.movementCost(.mud, slowGroundExtraTurns: 3), 4)
        XCTAssertEqual(WorldRules.movementCost(.stone, slowGroundExtraTurns: 3), 1)
    }

    func testZeroApexMultiplierActuallyMeansNone() {
        var tuning = DebugTuningProfile.defaults
        tuning.apexChanceMultiplier = 0
        let greedy = book(["terrain": "caverns", "biome": "verdant",
                           "bounty": "rich_ore", "quirk": "gilded_veins"])
        for seed in UInt64(1)...40 {
            XCTAssertFalse(Worldgen.generate(book: greedy, seed: seed, tuning: tuning)
                .enemies.contains(where: \.isApex))
        }
    }

    func testGenerationDiagnosticsAreDeterministicAndSurviveMutableMapChanges() throws {
        var tuning = DebugTuningProfile.defaults
        tuning.additionalPageChance = 1
        let composition = book(["terrain": "plains", "biome": "verdant"])
        let first = Worldgen.generate(book: composition, seed: 20_260_809, tuning: tuning)
        let again = Worldgen.generate(book: composition, seed: 20_260_809, tuning: tuning)

        XCTAssertEqual(first.diagnostics, again.diagnostics)
        XCTAssertEqual(first.diagnostics.placedDiaryPages, first.pages)
        XCTAssertEqual(first.diagnostics.placedOtherWritings, first.writings.map(\.id))
        XCTAssertEqual(first.diagnostics.rawEssenceDropsPlaced,
                       first.map.tiles.count {
                           if case .wildDrop(let resource, _) = $0.content {
                               return resource == Resources.essenceRaw
                           }
                           return false
                       })

        var run = WorldRun(runIndex: 1, book: composition, mapSeed: 20_260_809,
                           rng: SeededRNG(seed: 20_260_809), map: first.map,
                           playerPosition: first.start,
                           generationDiagnostics: first.diagnostics, tuning: tuning)
        if let page = run.map.allPoints.first(where: {
            if case .diaryPage = run.map[$0].content { return true }
            return false
        }) {
            run.map[page].content = .empty
        }
        XCTAssertEqual(run.generationDiagnostics.placedDiaryPages,
                       first.diagnostics.placedDiaryPages,
                       "Initial placement is a snapshot, not a scan of collectible tiles")

        let data = try SaveCodec.makeEncoder().encode(run)
        XCTAssertEqual(try SaveCodec.makeDecoder().decode(WorldRun.self, from: data)
            .generationDiagnostics, first.diagnostics)
    }

    func testNewWorldStartsOnReservedSafeInteriorGroundWithReachableEdgeReturnPortal() throws {
        let compositions = [
            book(["terrain": "plains"]),
            book(["terrain": "caverns", "biome": "verdant"]),
            book(["terrain": "islands", "quirk": "dim_sky"]),
            book(["terrain": "caverns", "biome": "frostbound",
                  "bounty": "sparse_ore", "quirk": "dim_sky"]),
        ]
        for (compositionIndex, composition) in compositions.enumerated() {
            for seed in UInt64(1)...12 {
                let generated = Worldgen.generate(
                    book: composition,
                    seed: seed &+ UInt64(compositionIndex * 10_000))
                let start = generated.start
                let returnPortal = generated.map.entry
                let startTile = generated.map[start]
                let receipt = try XCTUnwrap(generated.diagnostics.playableEntry)

                XCTAssertTrue(generated.diagnostics.terrainGenerationSucceeded)
                XCTAssertTrue(receipt.isAccepted)
                XCTAssertEqual(receipt.version, 2)
                XCTAssertEqual(receipt.playerStart, start)
                XCTAssertEqual(receipt.returnPortal, returnPortal)
                XCTAssertNotEqual(start, returnPortal)
                XCTAssertGreaterThanOrEqual(generated.map.ring(of: start), 1)
                XCTAssertEqual(generated.map.ring(of: returnPortal), 0)
                XCTAssertTrue(startTile.isPassable)
                XCTAssertEqual(startTile.content, .empty)
                XCTAssertNil(startTile.flora)
                XCTAssertEqual(startTile.ground.movementCost, 1)
                XCTAssertTrue(startTile.isRevealed)
                XCTAssertTrue(generated.map.neighbours(of: start).contains { neighbour in
                    let tile = generated.map[neighbour]
                    return tile.isPassable && tile.ground.movementCost == 1
                        && abs(tile.elevation - startTile.elevation) <= 1
                })
                guard case .portal(isEntry: true) = generated.map[returnPortal].content else {
                    return XCTFail("the retained edge coordinate must be the return portal")
                }
                XCTAssertTrue(TerrainRules.reachable(from: start, in: generated.map)
                    .contains(returnPortal))
                XCTAssertFalse(generated.enemies.contains { $0.position == start })
                XCTAssertFalse(generated.sites.contains { $0.position == start })
                XCTAssertNotEqual(generated.wildPage?.fieldProvenance?.position, start)
            }
        }
    }

    func testSafeInteriorStartUsesItsOwnDeterministicSeedStream() throws {
        let generated = Worldgen.generate(book: book(["terrain": "plains"]), seed: 84_201)
        let component = TerrainRules.reachable(from: generated.map.entry, in: generated.map)
        let first = Worldgen.safeInteriorStartForTesting(
            in: generated.map, component: component, seed: 84_201)
        var unrelatedLayout = SeededRNG(seed: 84_201).derived(0x1A70)
        let layoutBefore = unrelatedLayout.next()
        _ = Worldgen.safeInteriorStartForTesting(
            in: generated.map, component: component, seed: 84_201)
        let layoutAfter = unrelatedLayout.next()
        var expectedLayout = SeededRNG(seed: 84_201).derived(0x1A70)
        XCTAssertEqual(layoutBefore, expectedLayout.next())
        XCTAssertEqual(layoutAfter, expectedLayout.next(),
                       "start selection must not consume the layout stream")
        XCTAssertEqual(first, Worldgen.safeInteriorStartForTesting(
            in: generated.map, component: component, seed: 84_201))
    }

    func testLegacyDecodedRunKeepsItsExactSavedPositionAndMap() throws {
        let composition = book(["terrain": "plains"])
        let generated = Worldgen.generate(book: composition, seed: 770_271)
        var run = WorldRun(runIndex: 7, book: composition, mapSeed: 770_271,
                           rng: SeededRNG(seed: 770_271), map: generated.map,
                           playerPosition: generated.map.entry,
                           generationDiagnostics: generated.diagnostics)
        run.generationDiagnostics.playableEntry = nil
        let mapBytes = try SaveCodec.makeEncoder().encode(run.map)
        let decoded = try SaveCodec.makeDecoder().decode(
            WorldRun.self, from: SaveCodec.makeEncoder().encode(run))
        XCTAssertEqual(decoded.playerPosition, generated.map.entry)
        XCTAssertEqual(try SaveCodec.makeEncoder().encode(decoded.map), mapBytes)
        XCTAssertNil(decoded.generationDiagnostics.playableEntry)
    }

    func testLegacyPlayableEntryReceiptDecodesWithoutInventingNewStartFacts() throws {
        let generated = Worldgen.generate(book: book(["terrain": "plains"]), seed: 770_272)
        let receipt = try XCTUnwrap(generated.diagnostics.playableEntry)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(
            with: SaveCodec.makeEncoder().encode(receipt)) as? [String: Any])
        object["version"] = 1
        object.removeValue(forKey: "playerStart")
        object.removeValue(forKey: "returnPortal")
        object.removeValue(forKey: "startIsSafeInterior")
        object.removeValue(forKey: "returnPortalReachable")
        let legacy = try SaveCodec.makeDecoder().decode(
            PlayableEntryReceipt.self,
            from: JSONSerialization.data(withJSONObject: object, options: [.sortedKeys]))
        XCTAssertEqual(legacy.version, 1)
        XCTAssertNil(legacy.playerStart)
        XCTAssertNil(legacy.returnPortal)
        XCTAssertFalse(legacy.startIsSafeInterior)
        XCTAssertFalse(legacy.returnPortalReachable)
        XCTAssertTrue(legacy.isAccepted,
                      "the v2 receipt must not retroactively invalidate a playable legacy run")
    }

    func testRawEssenceRecommendedProfileIsTheDefaultAndLegacyRemainsComparable() throws {
        XCTAssertEqual(DebugTuningProfile.defaults.rawEssenceProfile, .recommended)
        XCTAssertEqual(DebugTuningProfile.RawEssenceProfile.recommended.dropRange, 5...7)
        XCTAssertEqual(DebugTuningProfile.RawEssenceProfile.recommended.amountRange, 2...3)
        XCTAssertEqual(DebugTuningProfile.RawEssenceProfile.legacy.dropRange, 2...4)
        XCTAssertEqual(DebugTuningProfile.RawEssenceProfile.legacy.amountRange, 1...2)

        let composition = book(["terrain": "plains"])
        for seed in UInt64(1)...20 {
            let recommended = Worldgen.generate(book: composition, seed: seed,
                                                tuning: .defaults).diagnostics
            XCTAssertTrue((5...7).contains(recommended.rawEssenceDropsPlaced))
            XCTAssertGreaterThanOrEqual(recommended.rawEssenceObtainable,
                                        recommended.rawEssenceDropsPlaced * 2)
            XCTAssertLessThanOrEqual(recommended.rawEssenceObtainable,
                                     recommended.rawEssenceDropsPlaced * 3)

            var legacyTuning = DebugTuningProfile.defaults
            legacyTuning.rawEssenceProfile = .legacy
            let legacy = Worldgen.generate(book: composition, seed: seed,
                                           tuning: legacyTuning).diagnostics
            XCTAssertTrue((2...4).contains(legacy.rawEssenceDropsPlaced))
            XCTAssertGreaterThanOrEqual(legacy.rawEssenceObtainable, legacy.rawEssenceDropsPlaced)
            XCTAssertLessThanOrEqual(legacy.rawEssenceObtainable, legacy.rawEssenceDropsPlaced * 2)
        }
    }

    func testRawEssenceProfileAndIndependentMultipliersAreSnapshottedDeterministically() {
        let composition = book(["terrain": "plains"])
        var tuning = DebugTuningProfile.defaults
        tuning.rawEssenceProfile = .lean
        tuning.rawEssenceFrequencyMultiplier = 0.5
        tuning.rawEssenceYieldMultiplier = 2
        let first = Worldgen.generate(book: composition, seed: 81_919, tuning: tuning)
        let again = Worldgen.generate(book: composition, seed: 81_919, tuning: tuning)
        XCTAssertEqual(first.diagnostics, again.diagnostics)
        XCTAssertTrue((2...3).contains(first.diagnostics.rawEssenceDropsPlaced))
        XCTAssertGreaterThanOrEqual(first.diagnostics.rawEssenceObtainable,
                                    first.diagnostics.rawEssenceDropsPlaced * 4)
        let run = WorldRun(runIndex: 1, book: composition, mapSeed: 81_919,
                           rng: SeededRNG(seed: 81_919), map: first.map,
                           playerPosition: first.start, generationDiagnostics: first.diagnostics,
                           tuning: tuning)
        XCTAssertEqual(run.tuning, tuning)
    }

    func testOpeningEnvelopeRelocatesRatherThanDeletesOnlyOnFreshFirstExpedition() throws {
        let composition = book(["terrain": "plains", "biome": "teeming_life"])
        var clear = DebugTuningProfile.defaults
        clear.creatureDensityMultiplier = 3
        clear.baseVisionRadius = 6
        clear.openingEncounterEnvelope = .clearApproach

        let seed = try XCTUnwrap((UInt64(1)...500).first { candidate in
            let world = Worldgen.generate(book: composition, seed: candidate, tuning: clear,
                                          isFreshFirstExpedition: false)
            return world.enemies.count { enemy in
                world.map[enemy.position].isRevealed && !enemy.isSessile && !enemy.isApex
                    && !world.sites.map(\.position).contains(enemy.position)
            } >= 2
        })
        let natural = Worldgen.generate(book: composition, seed: seed, tuning: clear,
                                        isFreshFirstExpedition: false)
        let protectedPositions = Set(natural.sites.map(\.position))
        let protectedEnemies = natural.enemies.filter {
            $0.isSessile || $0.isApex || protectedPositions.contains($0.position)
        }

        let cleared = Worldgen.generate(book: composition, seed: seed, tuning: clear,
                                        isFreshFirstExpedition: true)
        XCTAssertEqual(cleared.enemies.count, natural.enemies.count)
        XCTAssertEqual(cleared.enemies.filter { $0.isSessile || $0.isApex
            || protectedPositions.contains($0.position) }, protectedEnemies)
        XCTAssertFalse(cleared.enemies.contains {
            cleared.map[$0.position].isRevealed && !$0.isSessile && !$0.isApex
                && !protectedPositions.contains($0.position)
        })
        XCTAssertTrue(cleared.diagnostics.openingEnvelopeApplied)
        XCTAssertGreaterThan(cleared.diagnostics.openingEnemiesRelocated, 0)

        let ignored = Worldgen.generate(book: composition, seed: seed, tuning: clear,
                                        isFreshFirstExpedition: false)
        XCTAssertEqual(ignored.enemies, natural.enemies)
        XCTAssertFalse(ignored.diagnostics.openingEnvelopeApplied)

        var gentle = clear
        gentle.openingEncounterEnvelope = .gentle
        let softened = Worldgen.generate(book: composition, seed: seed, tuning: gentle,
                                         isFreshFirstExpedition: true)
        XCTAssertLessThanOrEqual(softened.enemies.count {
            softened.map[$0.position].isRevealed && !$0.isSessile && !$0.isApex
                && !protectedPositions.contains($0.position)
        }, 1)
        XCTAssertEqual(softened.enemies.count, natural.enemies.count)
    }

    func testMapIsWidthOwnedAndNeverShrinksForBottomChrome() {
        XCTAssertEqual(WorldMapLayout.backdropRGB, [23, 23, 26],
                       "transparent lifted-sprite pixels reveal fog, never a white card seam")
        let phone = WorldMapLayout.maximumSide(containerWidth: 368, viewportHeight: 260,
                                                viewportTiles: 11, displayScale: 3)
        XCTAssertEqual(phone, 1100.0 / 3.0, accuracy: 0.001)
        XCTAssertEqual((phone * 3).truncatingRemainder(dividingBy: 11), 0, accuracy: 0.001,
                       "The bottom border lands after a complete device-pixel cell")

        let underlyingWithTutorial = WorldMapLayout.maximumSide(containerWidth: 368,
                                                                 viewportHeight: 260,
                                                                 viewportTiles: 11,
                                                                 displayScale: 3)
        XCTAssertEqual(phone, underlyingWithTutorial,
                       "Tutorial presentation is an overlay and cannot alter map/control geometry")

        let ordinary = WorldMapLayout.maximumSide(containerWidth: 368, viewportHeight: 500,
                                                   viewportTiles: 11, displayScale: 3)
        XCTAssertEqual(ordinary, phone, accuracy: 0.001,
                       "Extra vertical room cannot change a width-owned map")

        let cramped = WorldMapLayout.maximumSide(containerWidth: 320, viewportHeight: 100,
                                                  viewportTiles: 11, displayScale: 3)
        XCTAssertEqual(cramped, 319, accuracy: 0.001)
        XCTAssertGreaterThan(cramped, 310,
                             "Bottom panels may require scrolling but may never miniaturize the map")
        XCTAssertEqual((cramped * 3).truncatingRemainder(dividingBy: 11), 0, accuracy: 0.001)

        XCTAssertEqual(WorldMapLayout.viewportRows(mapWidth: phone, availableHeight: 260,
                                                   viewportColumns: 11, mapRows: 30), 7)
        XCTAssertEqual(WorldMapLayout.viewportRows(mapWidth: phone, availableHeight: 500,
                                                   viewportColumns: 11, mapRows: 30), 15)
        XCTAssertEqual(WorldMapLayout.viewportRows(mapWidth: phone, availableHeight: 500,
                                                   viewportColumns: 11, mapRows: 9), 9)
        let rows = WorldMapLayout.viewportRows(mapWidth: phone, availableHeight: 500,
                                               viewportColumns: 11, mapRows: 30)
        XCTAssertLessThanOrEqual(phone / 11 * CGFloat(rows), 500,
                               "Only complete rows that fit may be admitted to the viewport")
    }

    func testWorldCameraNeverResizesTilesToFitVisibility() {
        let ordinary = WorldRules.visibilityProfile(illumination: 100, baseRadius: 7)
        XCTAssertEqual(ordinary.fullRadius, 7)
        XCTAssertEqual(ordinary.fringeWidth, 2)
        XCTAssertEqual(WorldMapLayout.viewportColumns(
            mapColumns: 30, cameraColumns: 11), 11,
            "A large sight field must not zoom the camera out or shrink its tiles")

        let darkness = WorldRules.visibilityProfile(illumination: 0, baseRadius: 7)
        XCTAssertLessThan(darkness.fullRadius, ordinary.fullRadius)
        XCTAssertEqual(WorldMapLayout.viewportColumns(
            mapColumns: 30, cameraColumns: 11), 11,
            "Lighting changes must not alter the established phone framing")
        XCTAssertEqual(WorldMapLayout.viewportColumns(
            mapColumns: 9, cameraColumns: 11), 9,
            "Only a genuinely smaller map may reduce the camera column count")
        XCTAssertEqual(WorldMapLayout.viewportRows(
            mapWidth: 367, availableHeight: 2_000,
            viewportColumns: 11, mapRows: 30), 30,
            "Measured safe height admits every complete row without changing tile width")
    }

    @MainActor
    func testExploreConsumesSafeRemainderAsCompleteRowsAtUnchangedTileWidth() throws {
        let store = GameStore(io: .temporary(name: "explore-safe-space-\(UUID().uuidString)"))
        store.mutate("test explore safe space") {
            $0.worlds.activeRun = WorldRun(
                runIndex: 3, book: self.book([:]), mapSeed: 264,
                rng: SeededRNG(seed: 264),
                map: WorldMap(width: 30, height: 30,
                              tiles: Array(repeating: Tile(), count: 900),
                              entry: GridPoint(x: 15, y: 15)),
                playerPosition: GridPoint(x: 15, y: 15))
        }
        WorldMapStageMeasurement.latestFrame = .zero
        WorldMapStageMeasurement.latestMapFrame = .zero
        WorldMapStageMeasurement.latestMapWidth = 0
        WorldMapStageMeasurement.latestViewportRows = 0
        let frozenState = try SaveCodec.encode(store.state)
        let controller = UIHostingController(rootView: WorldView().environmentObject(store))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 368, height: 800))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.additionalSafeAreaInsets = UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0)
        controller.view.frame = window.bounds
        controller.view.setNeedsLayout(); controller.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.08))

        let stage = WorldMapStageMeasurement.latestFrame
        let map = WorldMapStageMeasurement.latestMapFrame
        let safe = controller.view.safeAreaInsets
        XCTAssertGreaterThanOrEqual(safe.top, 59)
        XCTAssertGreaterThanOrEqual(safe.bottom, 34)
        XCTAssertGreaterThanOrEqual(stage.minY, safe.top - 0.5)
        XCTAssertLessThanOrEqual(stage.maxY, 800 - safe.bottom + 0.5)
        XCTAssertEqual(WorldMapStageMeasurement.latestMapWidth, 1100.0 / 3.0, accuracy: 0.5,
                       "safe height cannot change the established eleven-column tile width")
        let tile = WorldMapStageMeasurement.latestMapWidth / 11
        let rows = WorldMapStageMeasurement.latestViewportRows
        XCTAssertEqual(map.height, tile * CGFloat(rows), accuracy: 0.5)
        XCTAssertLessThanOrEqual(map.height, stage.height + 0.5)
        if rows < (store.activeRun?.map.height ?? 0) {
            XCTAssertLessThan(stage.height - map.height, tile + 0.5,
                              "no additional complete row may fit in the measured safe remainder")
        }
        XCTAssertEqual(try SaveCodec.encode(store.state), frozenState,
                       "safe-space measurement and rendering cannot mutate gameplay or persistence")

        let image = UIGraphicsImageRenderer(size: window.bounds.size).image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
        let attachment = XCTAttachment(image: image)
        attachment.name = "explore-safe-space-complete-rows-368x800"
        attachment.lifetime = .keepAlways; add(attachment)
        window.isHidden = true
    }

    func testWorldControlsHaveExactlyTwoActionsInOneNonOverlappingBottomDock() throws {
        XCTAssertEqual(WorldControlsLayout.actionCount, 2)
        XCTAssertEqual(WorldControlsLayout.actionRows, 1,
                       "Use Tile and Look must remain side by side, never stacked")
        XCTAssertEqual(WorldControlsLayout.actionHeight, 44)

        let frames = WorldControlsLayout.actionFrames(containerWidth: 368)
        XCTAssertEqual(frames.count, 2)
        XCTAssertGreaterThanOrEqual(frames[0].width, 44)
        XCTAssertGreaterThanOrEqual(frames[1].width, 44)
        XCTAssertEqual(frames[0].height, 44)
        XCTAssertEqual(frames[1].height, 44)
        XCTAssertEqual(frames[0].minX, 191, accuracy: 0.01)
        XCTAssertGreaterThan(frames[0].width, 70)
        XCTAssertLessThanOrEqual(frames[0].maxX, frames[1].minX)
        XCTAssertEqual(frames[1].maxX, 352, accuracy: 0.01)

        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf: root.appending(path: "Sources/Screens/WorldView.swift"),
                                encoding: .utf8)
        XCTAssertFalse(source.contains(".safeAreaInset(edge: .bottom"),
                       "The bottom dock must reserve an ordinary sibling frame, never composite over the map")
        let geometry = try XCTUnwrap(source.range(of: "GeometryReader { viewport in"))
        let satchel = try XCTUnwrap(source.range(of: "satchel(run)",
                                                 range: geometry.upperBound..<source.endIndex))
        let controls = try XCTUnwrap(source.range(of: "controls(run)",
                                                  range: satchel.upperBound..<source.endIndex))
        XCTAssertLessThan(geometry.lowerBound, satchel.lowerBound)
        XCTAssertLessThan(satchel.lowerBound, controls.lowerBound,
                          "Map, Field Kit, and navigation are ordered siblings in one layout")
        XCTAssertTrue(source.contains("MapGrid("))
        XCTAssertFalse(source.contains("MapGrid(") && source.contains("eventLog.padding(8)"))
        XCTAssertTrue(source.contains("WorldFieldFeedbackRow(contextOverlapsPlayer:"),
                      "The approved compact place/event receipt remains inside the map stage")
        XCTAssertTrue(source.contains("if disabledReason == nil, let status = coordinator.statusCopy"),
                      "typed Working/busy/stale feedback remains mounted for non-disabled controls")
        XCTAssertTrue(source.contains("availableHeight: viewport.size.height"),
                      "The square stage must admit all eleven square rows without a false gap")
        XCTAssertFalse(source.contains("return \"Forest track\""),
                       "Place copy must derive from the live tile rather than a static fixture")
        XCTAssertTrue(source.contains("ground.displayName.capitalized"))
        XCTAssertTrue(source.contains("PixelUITheme.edgeDark.opacity(0.75)"))
        XCTAssertTrue(source.contains("PixelUITheme.edgeDark.opacity(0.25)"),
                      "Event copy must use the approved 75%-to-25% opacity gradient")
        XCTAssertTrue(source.contains(".font(.custom(\"Tiny5\", size: 10))"),
                      "The live place context must remain readable on an ordinary phone")
        XCTAssertTrue(source.contains(".font(.custom(\"Jersey 10\", size: 20))"))
        XCTAssertFalse(source.contains(".font(.custom(\"Tiny5\", size: 6))"))
        XCTAssertFalse(source.contains(".font(.custom(\"Tiny5\", size: 7))"),
                       "No World chrome may fall below the readable compact-text floor")
        XCTAssertTrue(source.contains(".overlay(Rectangle().stroke(PixelUITheme.edge, lineWidth: 2))"),
                      "The transparent information panel still needs a visible hard boundary")
        let minimapSource = try String(contentsOf: root.appending(path: "Sources/Screens/MinimapView.swift"),
                                       encoding: .utf8)
        XCTAssertTrue(minimapSource.contains("Rectangle().stroke(PixelUITheme.edge, lineWidth: 2)"),
                      "The minimap needs the approved visible hard border")
        XCTAssertFalse(source.contains(".aspectRatio(1, contentMode: .fit)"),
                       "Explore must use measured safe remainder instead of forcing a square stage")
        XCTAssertTrue(source.contains("PixelUITheme.edgeDark.ignoresSafeArea()"))
        XCTAssertTrue(source.contains("Text(\"Explore\")"))
        XCTAssertTrue(source.contains("Text(\"STABILITY\")"))
        XCTAssertTrue(source.contains("Text(\"COLLAPSE\")"))
        XCTAssertTrue(source.contains("Text(placeEyebrow)"))
        XCTAssertTrue(source.contains("Text(placeTitle)"))
        XCTAssertTrue(source.contains(".allowsHitTesting(false)"))
        XCTAssertTrue(source.contains("HStack(alignment: .center, spacing: WorldControlsLayout.navigationSpacing)"))
        XCTAssertTrue(source.contains("VStack(spacing: 12)"),
                      "The actions need deliberate separation from the minimap")
        XCTAssertTrue(source.contains(".frame(width: 96, height: 96)"))
        XCTAssertTrue(source.contains("action: .useTile"))
        XCTAssertTrue(source.contains("action: .armLook"))
        XCTAssertTrue(source.contains("Text(\"Use Tile\")"))
        XCTAssertTrue(source.contains("WorldWholeFaceControl("))
        XCTAssertTrue(source.contains(".accessibilityIdentifier(\"world.interact\")"))
        XCTAssertTrue(source.contains(".accessibilityIdentifier(\"world.look\")"))
        XCTAssertTrue(source.contains(".accessibilityIdentifier(\"world.action-row\")"))
        XCTAssertTrue(source.contains(".padding(.vertical, 8)"),
                      "The control pair must be vertically centered inside symmetric padding")
        XCTAssertTrue(source.contains("Rectangle().fill(PixelUITheme.edge).frame(height: 2)"))
        XCTAssertTrue(source.contains(".background(PixelUITheme.surfaceInset)"))
        XCTAssertTrue(source.contains("canInteract ? PixelUITheme.primary : PixelUITheme.neutral"),
                      "An exhausted node must leave a visibly grey, disabled Use Tile control")
        XCTAssertTrue(source.contains(".font(.custom(\"Tiny5\", size: 10))"))
        XCTAssertFalse(source.contains(".clipShape(RoundedRectangle(cornerRadius: 10))"),
                       "The approved World map has hard square viewport edges")
        XCTAssertTrue(source.contains(".clipped()"),
                      "No map pixels may escape the square viewport or render beneath the Field Kit border")
    }

    func testFieldKitIsACompactTwoTrayInventoryInsteadOfAFullWidthList() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf: root.appending(path: "Sources/Screens/WorldView.swift"),
                                encoding: .utf8)
        let start = try XCTUnwrap(source.range(of: "private struct FieldKitSheet"))
        let fieldKit = String(source[start.lowerBound...])

        XCTAssertTrue(fieldKit.contains("Picker(\"Field Kit section\""))
        XCTAssertTrue(fieldKit.contains("case instruments = \"Instruments\""))
        XCTAssertTrue(fieldKit.contains("case supplies = \"Supplies\""))
        XCTAssertTrue(fieldKit.contains("SixAcrossItemGrid(data: store.carriedConsumables"))
        XCTAssertTrue(fieldKit.contains("AnchoredItemDetailButton(item: stack"))
        XCTAssertTrue(fieldKit.contains(".presentationDetents([.medium, .large])"))
        XCTAssertFalse(fieldKit.contains("List {"),
                       "Field Kit browsing is a compact tray; only selected-item detail may become prose")
    }

    // MARK: Fog and movement

    func testFogRevealsAroundThePlayerAndStaysRevealed() {
        var state = startedRun(book(["terrain": "plains"]), seed: 31)
        let run = state.worlds.activeRun!
        let start = run.playerPosition
        XCTAssertTrue(run.map[start].isRevealed)

        let step = run.map.neighbours(of: start).first { WorldRules.canEnter($0, in: run.map) }!
        _ = WorldRules.step(to: step, in: &state)
        let after = state.worlds.activeRun!

        XCTAssertTrue(after.map[start].isRevealed, "Revealed tiles stay revealed")
        XCTAssertTrue(after.map[step].isRevealed)
        XCTAssertEqual(after.playerPosition, step)
    }

    func testAStepIsExactlyOneTurn() {
        var state = startedRun(book(["terrain": "plains"]), seed: 12)
        let before = state.worlds.activeRun!
        let step = before.map.neighbours(of: before.playerPosition).first {
            WorldRules.canEnter($0, in: before.map) && before.map[$0].ground.movementCost == 1
        }!

        _ = WorldRules.step(to: step, in: &state)
        let after = state.worlds.activeRun!

        XCTAssertEqual(after.turnsTaken, before.turnsTaken + 1)
        XCTAssertEqual(after.stability, before.stability - before.decayPerTurn, accuracy: 0.0001)
    }

    func testResolvedStabilitySurvivesRelaunchAndMigratesOldRunsDeterministically() throws {
        let run = try XCTUnwrap(startedRun(book([:]), seed: 91).worlds.activeRun)
        let encoded = try JSONEncoder().encode(run)
        let resumed = try JSONDecoder().decode(WorldRun.self, from: encoded)
        XCTAssertEqual(resumed.resolvedStabilityScore, run.resolvedStabilityScore)
        XCTAssertEqual(resumed.decayPerTurn, run.decayPerTurn)

        var legacy = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        legacy.removeValue(forKey: "resolvedStabilityScore")
        let migrated = try JSONDecoder().decode(
            WorldRun.self, from: JSONSerialization.data(withJSONObject: legacy))
        XCTAssertEqual(migrated.resolvedStabilityScore,
                       BookRules.resolvedStabilityScore(of: run.book, seed: run.mapSeed))
    }

    func testTallGrowthAndMudEachCostTwoTurns() {
        for ground in [GroundType.growth, .mud] {
            var state = startedRun(book(["terrain": "plains"]), seed: 120)
            let before = state.worlds.activeRun!
            let step = before.map.neighbours(of: before.playerPosition)
                .first { WorldRules.canEnter($0, in: before.map) }!
            state.worlds.activeRun?.map[step].ground = ground

            let events = WorldRules.step(to: step, in: &state)

            XCTAssertEqual(state.worlds.activeRun?.turnsTaken, before.turnsTaken + 2)
            XCTAssertTrue(events.contains(.enteredSlowGround(ground.displayName)))
        }
    }

    func testPathfindingPrefersAQuickerRouteAroundSlowGround() {
        var map = WorldMap(width: 5, height: 3,
                           tiles: Array(repeating: Tile(), count: 15),
                           entry: GridPoint(x: 0, y: 1))
        let start = GridPoint(x: 0, y: 1)
        let destination = GridPoint(x: 4, y: 1)
        for x in 1...3 { map[GridPoint(x: x, y: 1)].ground = .growth }

        let route = WorldRules.path(from: start, to: destination, in: map)

        XCTAssertFalse(route.dropLast().contains { map[$0].ground == .growth },
                       "the route chose fewer squares even though they cost more turns")
        XCTAssertEqual(route.last, destination)

        let freeSlowRoute = WorldRules.path(from: start, to: destination, in: map,
                                            slowGroundExtraTurns: 0)
        XCTAssertTrue(freeSlowRoute.dropLast().contains { map[$0].ground == .growth },
                      "path weights ignored the zero-extra-turn run snapshot")
    }

    func testNonAdjacentStepsAreRefused() {
        var state = startedRun(book(["terrain": "plains"]), seed: 13)
        let run = state.worlds.activeRun!
        let far = run.map.allPoints.first { $0.manhattanDistance(to: run.playerPosition) > 3 }!

        let events = WorldRules.step(to: far, in: &state)
        XCTAssertEqual(state.worlds.activeRun?.playerPosition, run.playerPosition)
        XCTAssertEqual(state.worlds.activeRun?.turnsTaken, 0, "A refused move must not burn a turn")
        XCTAssertTrue(events.contains { if case .blocked = $0 { true } else { false } })
    }

    func testPathfindingReachesAndRoutesAroundCrumbledGround() {
        var state = startedRun(book(["terrain": "plains"]), seed: 14)
        var run = state.worlds.activeRun!
        let start = run.playerPosition
        let target = run.map.allPoints.last { $0 != start && WorldRules.canEnter($0, in: run.map) }!

        let route = WorldRules.path(from: start, to: target, in: run.map)
        XCTAssertFalse(route.isEmpty)
        XCTAssertEqual(route.last, target)
        for (index, point) in route.enumerated() {
            let previous = index == 0 ? start : route[index - 1]
            XCTAssertTrue(WorldRules.isAdjacent(previous, point), "Every path step must be one tile")
        }

        // Wall off a neighbour and confirm the route never crosses crumbled ground.
        for neighbour in run.map.neighbours(of: start).dropLast() {
            run.map[neighbour].isCrumbled = true
        }
        state.worlds.activeRun = run
        let detour = WorldRules.path(from: start, to: target, in: run.map)
        for point in detour {
            XCTAssertFalse(run.map[point].isCrumbled)
        }
    }

    // MARK: Harvesting

    func testMineralDepositLifeIsDeterministicBoundedAndMonotonic() {
        var sawStrictIncrease = false
        var observed: Set<Int> = []
        for seed in UInt64(1)...200 {
            for ordinal in 0..<8 {
                let first = Worldgen.mineralDepositHarvests(
                    abundance: 4, substratePeak: 35, dispersion: 70,
                    seed: seed, placementOrdinal: ordinal)
                let replay = Worldgen.mineralDepositHarvests(
                    abundance: 4, substratePeak: 35, dispersion: 70,
                    seed: seed, placementOrdinal: ordinal)
                let richer = Worldgen.mineralDepositHarvests(
                    abundance: 10, substratePeak: 100, dispersion: 0,
                    seed: seed, placementOrdinal: ordinal)
                XCTAssertEqual(first, replay)
                XCTAssertTrue((1...5).contains(first))
                XCTAssertGreaterThanOrEqual(richer, first,
                    "raising every probability input must never shorten the same deposit roll")
                sawStrictIncrease = sawStrictIncrease || richer > first
                observed.insert(first)
                observed.insert(richer)
            }
        }
        XCTAssertTrue(sawStrictIncrease)
        XCTAssertEqual(observed, Set(1...5), "the deterministic corpus must exercise every legal life")
    }

    func testMineralDepositLifeUsesAnIndependentPlacementOrdinalStream() {
        var observedNodeStream = SeededRNG(seed: 84_202).derived(0x2D0DE)
        var expectedNodeStream = SeededRNG(seed: 84_202).derived(0x2D0DE)
        XCTAssertEqual(observedNodeStream.next(), expectedNodeStream.next())
        for ordinal in 0..<40 {
            _ = Worldgen.mineralDepositHarvests(
                abundance: 8, substratePeak: 75, dispersion: 20,
                seed: 84_202, placementOrdinal: ordinal)
        }
        XCTAssertEqual(observedNodeStream.next(), expectedNodeStream.next(),
                       "deposit life must not consume the established node stream")
    }

    func testGeneratedMineralsOwnTotalLifeWhileFloraKeepsLegacyHarvestRange() throws {
        var sawMineral = false
        var sawFlora = false
        for seed in UInt64(1)...80 where !sawMineral || !sawFlora {
            let generated = Worldgen.generate(
                book: book(["bounty": "teeming_life", "terrain": "plains"]), seed: seed)
            for tile in generated.map.tiles {
                guard case .node(let node) = tile.content else { continue }
                if FloraRules.isFloraResource(node.resource) {
                    sawFlora = true
                    XCTAssertNil(node.generatedHarvests)
                    XCTAssertTrue(Tuning.World.harvestTurnsRange.contains(node.remainingHarvests))
                } else {
                    sawMineral = true
                    let total = try XCTUnwrap(node.generatedHarvests)
                    XCTAssertTrue((1...5).contains(total))
                    XCTAssertEqual(node.remainingHarvests, total)
                }
            }
        }
        XCTAssertTrue(sawMineral)
        XCTAssertTrue(sawFlora)
    }

    func testGeneratedMineralTotalPersistsSeparatelyAndPerHitYieldStaysExact() throws {
        var state = startedRun(book(["bounty": "rich_ore"]), seed: 272)
        var run = try XCTUnwrap(state.worlds.activeRun)
        run.map[run.playerPosition].content = .node(ResourceNode(
            resource: Resources.ore, remainingHarvests: 3, generatedHarvests: 5,
            yieldPerHarvest: 7))
        state.worlds.activeRun = run

        let events = WorldRules.harvest(in: &state)
        let after = try XCTUnwrap(state.worlds.activeRun)
        guard case .node(let node) = after.map[after.playerPosition].content else {
            return XCTFail("a deposit with two hits left must remain on its tile")
        }
        XCTAssertEqual(node.remainingHarvests, 2)
        XCTAssertEqual(node.generatedHarvests, 5)
        XCTAssertEqual(after.satchel[Resources.ore], 7)
        XCTAssertTrue(events.contains(.harvested(Resources.ore, amount: 7, exhausted: false)))
        XCTAssertEqual(after.turnsTaken, run.turnsTaken + 1)

        let resumed = try SaveCodec.decode(SaveCodec.encode(state))
        let resumedRun = try XCTUnwrap(resumed.worlds.activeRun)
        guard case .node(let resumedNode) = resumedRun.map[resumedRun.playerPosition].content else {
            return XCTFail("the partly mined deposit must survive relaunch")
        }
        XCTAssertEqual(resumedNode.remainingHarvests, 2)
        XCTAssertEqual(resumedNode.generatedHarvests, 5)
        XCTAssertEqual(resumedRun.satchel[Resources.ore], 7)
    }

    func testLegacyResourceNodeDecodesWithNilGeneratedLifeAndKeepsLegacyBehavior() throws {
        let bytes = try XCTUnwrap(
            #"{"resource":"ore","remainingHarvests":2,"yieldPerHarvest":3}"#.data(using: .utf8))
        var legacy = try SaveCodec.makeDecoder().decode(ResourceNode.self, from: bytes)
        XCTAssertNil(legacy.generatedHarvests)
        XCTAssertNil(legacy.extractionRequirement)
        XCTAssertEqual(legacy.remainingHarvests, 2)
        legacy.extractionRequirement = ResourceExtractionRules.requirementReceipt(for: legacy.resource)

        var state = startedRun(book([:]), seed: 273)
        var run = try XCTUnwrap(state.worlds.activeRun)
        run.map[run.playerPosition].content = .node(legacy)
        state.worlds.activeRun = run
        _ = WorldRules.harvest(in: &state)
        guard case .node(let remaining) = try XCTUnwrap(state.worlds.activeRun)
            .map[run.playerPosition].content else {
            return XCTFail("legacy two-hit node must retain its established first-hit behavior")
        }
        XCTAssertNil(remaining.generatedHarvests)
        XCTAssertEqual(remaining.remainingHarvests, 1)
        XCTAssertEqual(state.worlds.activeRun?.satchel[Resources.ore], 3)
    }

    func testWorldSplashFiveHitSourceCeilingIsThirtyFive() {
        XCTAssertEqual(WorldSplashReceiptV3.maximumObtainableQuantityPerSource, 35)
    }

    func testHarvestingFillsTheSatchelAndExhaustsTheNode() throws {
        var state = startedRun(book(["bounty": "teeming_life"]), seed: 99)
        var run = state.worlds.activeRun!
        // Put a known node under the player rather than hunting the map for one.
        run.map[run.playerPosition].content = .node(ResourceNode(resource: Resources.fiber,
                                                                 remainingHarvests: 2,
                                                                 yieldPerHarvest: 3))
        state.worlds.activeRun = run

        _ = WorldRules.harvest(in: &state)
        XCTAssertEqual(state.worlds.activeRun?.satchel[Resources.fiber], 3)
        XCTAssertEqual(state.worlds.activeRun?.turnsTaken, 1, "A pull costs a turn")
        XCTAssertTrue(state.reality.discovery.hasEncountered(resource: Resources.fiber),
                      "Harvesting logs the resource for the preview's silhouettes")

        _ = WorldRules.harvest(in: &state)
        XCTAssertEqual(state.worlds.activeRun?.satchel[Resources.fiber], 6)
        guard case .node(let exhausted) = state.worlds.activeRun?
            .map[state.worlds.activeRun!.playerPosition].content else {
            return XCTFail("worked-out ground must retain its frozen node receipt")
        }
        XCTAssertTrue(exhausted.isExhausted)
    }

    func testFloraHarvestCommitsPrimaryAndExactSecondaryResinAtomically() throws {
        var state = startedRun(book(["bounty": "teeming_life"]), seed: 99)
        var run = try XCTUnwrap(state.worlds.activeRun)
        run.map[run.playerPosition].content = .node(ResourceNode(
            resource: Resources.timber, remainingHarvests: 1, yieldPerHarvest: 3,
            secondaryResource: Resources.resin, secondaryYieldPerHarvest: 1))
        state.worlds.activeRun = run

        let events = WorldRules.harvest(in: &state)
        XCTAssertEqual(state.worlds.activeRun?.satchel[Resources.timber], 3)
        XCTAssertEqual(state.worlds.activeRun?.satchel[Resources.resin], 1)
        XCTAssertTrue(state.reality.discovery.hasEncountered(resource: Resources.timber))
        XCTAssertTrue(state.reality.discovery.hasEncountered(resource: Resources.resin))
        XCTAssertEqual(events.filter {
            if case .harvested = $0 { return true }; return false
        }.count, 2)
    }

    func testResourceExtractionCatalogueOwnsExactDispositionAndRank() throws {
        let expected: [ResourceID: Int] = [
            "rubble": 0, "clay": 0, Resources.ore: 0,
            "salt": 0, Resources.sulfur: 0, "copper": 1,
            Resources.quartz: 1, "obsidian": 1, Resources.silver: 2,
            "gold": 2, "mercury": 3, "rift_glass": 3,
            "adamant": 4,
        ]
        for resource in ContentCatalog.shared.resources {
            if let rank = expected[resource.id] {
                XCTAssertEqual(resource.extractionDisposition, .mineralNode, resource.id.rawValue)
                XCTAssertEqual(resource.requiredExtractionRank, rank, resource.id.rawValue)
            } else {
                XCTAssertNotEqual(resource.extractionDisposition, .mineralNode, resource.id.rawValue)
                XCTAssertNil(resource.requiredExtractionRank, resource.id.rawValue)
            }
        }
        XCTAssertEqual(Set(expected.keys), Set(ContentCatalog.shared.resources
            .filter { $0.extractionDisposition == .mineralNode }.map(\.id)))
    }

    func testResourceExtractionGeometryIsCardinalPassabilityOnly() throws {
        let state = startedRun(book(["terrain": "plains"]), seed: 31_201)
        var map = try XCTUnwrap(state.worlds.activeRun).map
        let center = GridPoint(x: map.width / 2, y: map.height / 2)
        map[center] = Tile(content: .node(ResourceNode(
            resource: Resources.ore, remainingHarvests: 1, yieldPerHarvest: 1)),
            ground: .deepWater, isRevealed: false)
        for point in map.neighbours(of: center) {
            map[point].ground = .soil
            map[point].isCrumbled = false
        }
        let blocked = map.neighbours(of: center)[0]
        map[blocked].isCrumbled = true
        let positions = ResourceExtractionRules.legalInteractionPositions(nodePoint: center, map: map)
        XCTAssertFalse(positions.contains(center), "an impassable host is worked from beside it")
        XCTAssertFalse(positions.contains(blocked))
        XCTAssertEqual(positions, positions.sorted { map.index(of: $0) < map.index(of: $1) })
        XCTAssertTrue(positions.allSatisfy { abs($0.x - center.x) + abs($0.y - center.y) == 1 })

        let baseline = positions
        guard case .node(var exhausted) = map[center].content else {
            return XCTFail("fixture must retain its node")
        }
        exhausted.remainingHarvests = 0
        map[center].content = .node(exhausted)
        map[center].isRevealed = true
        XCTAssertEqual(ResourceExtractionRules.legalInteractionPositions(nodePoint: center, map: map),
                       baseline, "geometry cannot depend on node life or disclosure")
    }

    func testFrozenExtractionReceiptSurvivesLaterCatalogueRankTuning() throws {
        var state = startedRun(book(["terrain": "plains"]), seed: 31_205)
        let point = try XCTUnwrap(state.worlds.activeRun).playerPosition
        var node = ResourceNode(resource: Resources.ore, remainingHarvests: 1, yieldPerHarvest: 2)
        node.extractionRequirement = .init(resourceID: Resources.ore,
                                           disposition: .mineralNode,
                                           requiredExtractionRank: 4)
        state.worlds.activeRun?.map[point].isRevealed = true
        state.worlds.activeRun?.map[point].content = .node(node)

        let relaunched = try SaveCodec.decode(SaveCodec.encode(state))
        guard case .node(let frozen) = try XCTUnwrap(relaunched.worlds.activeRun).map[point].content else {
            return XCTFail("frozen node must relaunch")
        }
        XCTAssertEqual(ResourceExtractionRules.validatedRequirement(of: frozen)?.requiredExtractionRank, 4)
        guard case .refused(.underEquipped(let required, let current, _)) =
                ResourceExtractionRules.evaluate(in: relaunched) else {
            return XCTFail("the frozen rank, not today's catalogue rank, must own play")
        }
        XCTAssertEqual(required, 4)
        XCTAssertEqual(current, 0)
    }

    func testResourceExtractionSharedTargetSkipsExhaustedUnderPartyForLiveAdjacent() throws {
        var state = startedRun(book(["terrain": "plains"]), seed: 31_206)
        var run = try XCTUnwrap(state.worlds.activeRun)
        let player = run.playerPosition
        let adjacent = try XCTUnwrap(run.map.neighbours(of: player)
            .sorted { run.map.index(of: $0) < run.map.index(of: $1) }.first)
        for point in [player, adjacent] {
            run.map[point].ground = .soil
            run.map[point].isCrumbled = false
            run.map[point].isRevealed = true
        }
        run.map[player].content = .node(ResourceNode(
            resource: "clay", remainingHarvests: 0, yieldPerHarvest: 1))
        run.map[adjacent].content = .node(ResourceNode(
            resource: Resources.ore, remainingHarvests: 1, yieldPerHarvest: 2))
        state.worlds.activeRun = run

        XCTAssertEqual(ResourceExtractionRules.selectedDisclosedNode(in: state)?.0, adjacent)
        guard case .available(let quote) = ResourceExtractionRules.evaluate(in: state) else {
            return XCTFail("the shared live adjacent target must be available")
        }
        XCTAssertEqual(quote.nodePoint, adjacent)
        let context = try XCTUnwrap(WorldFieldContextReceiptV1.make(from: state))
        XCTAssertEqual(context.contentSummary, .node(name: "Iron Ore"))
        XCTAssertEqual(context.interaction, .harvest)
        XCTAssertEqual(context.interactionState, .available)
    }

    @MainActor
    func testMountedUnderEquippedUseTileReturnsTypedRefusalWithoutMutation() throws {
        let store = GameStore(io: .temporary(name: "under-equipped-mounted-\(UUID().uuidString)"))
        store.mutate("test under-equipped mounted") { state in
            state = startedRun(book(["terrain": "plains"]), seed: 31_207)
            let point = state.worlds.activeRun!.playerPosition
            state.worlds.activeRun?.map[point].isRevealed = true
            state.worlds.activeRun?.map[point].content = .node(ResourceNode(
                resource: "adamant", remainingHarvests: 2, yieldPerHarvest: 5))
        }
        let controller = UIHostingController(rootView:
            WorldView().environmentObject(store).frame(width: 368, height: 800))
        let window = UIWindow(frame: .init(x: 0, y: 0, width: 368, height: 800))
        window.rootViewController = controller; window.makeKeyAndVisible()
        controller.view.frame = window.bounds; controller.view.layoutIfNeeded()
        let button = try XCTUnwrap(descendants(controller.view)
            .compactMap { $0 as? WorldControlHitOwner.ControlButton }
            .first { $0.worldAction == .useTile })
        XCTAssertNil(button.worldDisabledReason,
                     "under-equipped extraction must remain actionable for its typed refusal")
        let before = try SaveCodec.encode(store.state)
        let beforeTurn = store.activeRun?.turnsTaken
        button.sendActions(for: .touchDown); button.sendActions(for: .touchUpInside)
        let deadline = Date().addingTimeInterval(1)
        while store.worldFieldEventQueue.isEmpty && Date() < deadline {
            RunLoop.main.run(until: Date().addingTimeInterval(0.005))
        }
        XCTAssertEqual(store.worldFieldEventQueue.last?.orderedNarrations,
                       ["Adamant needs Extraction 4. Your party has Extraction 0."])
        XCTAssertEqual(try SaveCodec.encode(store.state), before)
        XCTAssertEqual(store.activeRun?.turnsTaken, beforeTurn)
        guard case .node(let unchanged) = try XCTUnwrap(store.activeRun)
            .map[store.activeRun!.playerPosition].content else {
            return XCTFail("refusal must preserve the node")
        }
        XCTAssertEqual(unchanged.remainingHarvests, 2)
        window.isHidden = true
    }

    func testResourceExtractionSelectsUnderPartyThenAdjacentRowMajorAndBindsTarget() throws {
        var state = startedRun(book(["terrain": "plains"]), seed: 31_202)
        var run = try XCTUnwrap(state.worlds.activeRun)
        let player = run.playerPosition
        let adjacent = run.map.neighbours(of: player)
            .sorted { run.map.index(of: $0) < run.map.index(of: $1) }
        let first = try XCTUnwrap(adjacent.first)
        let last = try XCTUnwrap(adjacent.last)
        for point in [player, first, last] {
            run.map[point].ground = .soil
            run.map[point].isRevealed = true
        }
        run.map[first].content = .node(ResourceNode(
            resource: "clay", remainingHarvests: 1, yieldPerHarvest: 1))
        run.map[last].content = .node(ResourceNode(
            resource: "rubble", remainingHarvests: 1, yieldPerHarvest: 1))
        state.worlds.activeRun = run
        guard case .available(let adjacentQuote) = ResourceExtractionRules.evaluate(in: state) else {
            return XCTFail("rank-zero adjacent mineral should be available")
        }
        XCTAssertEqual(adjacentQuote.nodePoint, first)

        state.worlds.activeRun?.map[player].content = .node(ResourceNode(
            resource: Resources.ore, remainingHarvests: 1, yieldPerHarvest: 2))
        guard case .available(let underQuote) = ResourceExtractionRules.evaluate(in: state) else {
            return XCTFail("under-party mineral should win")
        }
        XCTAssertEqual(underQuote.nodePoint, player)
        state.worlds.activeRun?.map[player].content = .empty
        let before = state
        let refused = ResourceExtractionRules.commit(underQuote, in: &state)
        XCTAssertEqual(refused.result, .refused(.noDisclosedNode))
        XCTAssertEqual(state, before)
    }

    func testResourceExtractionRankUsesOnlyBestWornTravellingFieldPick() throws {
        var state = startedRun(book(["terrain": "plains"]), seed: 31_203)
        var run = try XCTUnwrap(state.worlds.activeRun)
        let point = run.playerPosition
        run.map[point].isRevealed = true
        run.map[point].content = .node(ResourceNode(
            resource: "adamant", remainingHarvests: 1, yieldPerHarvest: 5))
        state.worlds.activeRun = run

        state.base.inventory.stacks = [ItemStack(
            id: InstanceID(rawValue: 91), catalogID: "the_willing_edge")]
        guard case .refused(.underEquipped(let required, let current, _)) =
                ResourceExtractionRules.evaluate(in: state) else {
            return XCTFail("stored tools cannot qualify")
        }
        XCTAssertEqual(required, 4); XCTAssertEqual(current, 0)
        state.base.binderEquipped[.tool] = EquippedPiece(catalogID: "the_willing_edge")
        guard case .available(let quote) = ResourceExtractionRules.evaluate(in: state) else {
            return XCTFail("worn exact rank-four pick should qualify")
        }
        XCTAssertEqual(quote.currentPartyExtractionRank, 4)
        let reserveBefore = state.base.worldMaterialReserve
        let outcome = ResourceExtractionRules.commit(quote, in: &state)
        guard case .committed(let success) = outcome.result else {
            return XCTFail("qualified extraction should commit")
        }
        XCTAssertEqual(success.primaryAmount, 5)
        XCTAssertEqual(state.worlds.activeRun?.satchel["adamant"], 5)
        XCTAssertEqual(state.base.worldMaterialReserve, reserveBefore)
        XCTAssertEqual(success.turnsSpent, 1)
        guard case .node(let exhausted) = state.worlds.activeRun?.map[point].content else {
            return XCTFail("exhausted receipt must remain")
        }
        XCTAssertTrue(exhausted.isExhausted)
    }

    func testResourceExtractionStaleToolRefusesWithoutMutation() throws {
        var state = startedRun(book(["terrain": "plains"]), seed: 31_204)
        let point = try XCTUnwrap(state.worlds.activeRun).playerPosition
        state.worlds.activeRun?.map[point].isRevealed = true
        state.worlds.activeRun?.map[point].content = .node(ResourceNode(
            resource: Resources.quartz, remainingHarvests: 2, yieldPerHarvest: 3))
        state.base.binderEquipped[.tool] = EquippedPiece(catalogID: "bent_pick")
        guard case .available(let quote) = ResourceExtractionRules.evaluate(in: state) else {
            return XCTFail("rank-one pick should qualify")
        }
        state.base.binderEquipped[.tool] = nil
        let before = state
        let outcome = ResourceExtractionRules.commit(quote, in: &state)
        XCTAssertEqual(outcome.result, .refused(.stale))
        XCTAssertEqual(state, before)
    }

    func testWayfarersTableImprovesOrganicHarvestAndPacking() throws {
        var state = startedRun(book(["bounty": "teeming_life"]), seed: 99)
        let ordinaryCapacity = state.base.satchelCapacity
        state.base.stations[Stations.wayfarersTable] = StationState(isUnlocked: true, tier: 0)
        XCTAssertEqual(state.base.satchelCapacity,
                       ordinaryCapacity + Tuning.Economy.fieldcraftSatchelBonus)

        var run = try XCTUnwrap(state.worlds.activeRun)
        run.map[run.playerPosition].content = .node(ResourceNode(resource: Resources.fiber,
                                                                 remainingHarvests: 1,
                                                                 yieldPerHarvest: 3))
        state.worlds.activeRun = run
        _ = WorldRules.harvest(in: &state)
        XCTAssertEqual(state.worlds.activeRun?.satchel[Resources.fiber],
                       3 + Tuning.Economy.fieldcraftOrganicYieldBonus)
    }

    func testWildDropsArePickedUpByWalkingOverThem() {
        var state = startedRun(book(["terrain": "plains"]), seed: 21)
        var run = state.worlds.activeRun!
        let target = run.map.neighbours(of: run.playerPosition).first { WorldRules.canEnter($0, in: run.map) }!
        run.map[target].content = .wildDrop(resource: Resources.essenceRaw, amount: 2)
        state.worlds.activeRun = run

        _ = WorldRules.step(to: target, in: &state)
        XCTAssertEqual(state.worlds.activeRun?.satchel[Resources.essenceRaw], 2)
        XCTAssertEqual(state.worlds.activeRun?.map[target].content, .empty, "A wild drop is taken, not left")
    }

    func testDiaryPageExperienceIsPaidOnlyForANewlyReadPage() throws {
        let page = try XCTUnwrap(ContentCatalog.shared.diaryPages.first)

        func stateWithPage(alreadyKnown: Bool) -> (GameState, GridPoint) {
            var state = startedRun(book(["terrain": "plains"]), seed: 2_026_081_011)
            var run = state.worlds.activeRun!
            run.enemies = []
            let target = run.map.neighbours(of: run.playerPosition)
                .first { WorldRules.canEnter($0, in: run.map) }!
            run.map[target].content = .diaryPage(page.id)
            state.worlds.activeRun = run
            if alreadyKnown { state.reality.library.foundPages.append(page.id) }
            return (state, target)
        }

        var (fresh, freshTarget) = stateWithPage(alreadyKnown: false)
        let freshXP = fresh.base.binderCharacter.experience
        _ = WorldRules.step(to: freshTarget, in: &fresh)
        XCTAssertEqual(fresh.base.binderCharacter.experience - freshXP,
                       Tuning.Character.experienceForPage)
        XCTAssertEqual(fresh.worlds.activeRun?.experienceBreakdown.pages,
                       Tuning.Character.experienceForPage)

        var (known, knownTarget) = stateWithPage(alreadyKnown: true)
        let knownXP = known.base.binderCharacter.experience
        _ = WorldRules.step(to: knownTarget, in: &known)
        XCTAssertEqual(known.base.binderCharacter.experience, knownXP,
                       "a stale duplicate page tile must not pay discovery XP again")
        XCTAssertEqual(known.worlds.activeRun?.experienceBreakdown.pages, 0)
        XCTAssertEqual(known.worlds.activeRun?.map[knownTarget].content, .empty)
    }

    func testRecoveredTeachingDuplicateClearsWithoutExperienceOrFirstRecoveryFeedback() throws {
        let definition = try XCTUnwrap(RecoveredTeachingCatalogueV1.definitions.first)
        func fixture(alreadyRecorded: Bool) -> (GameState, GridPoint) {
            var state = startedRun(book(["terrain": "plains"]), seed: 2_026_082_701)
            var run = state.worlds.activeRun!
            run.enemies = []
            let target = run.map.neighbours(of: run.playerPosition)
                .first { WorldRules.canEnter($0, in: run.map) }!
            run.map[target].content = .recoveredTeaching(definition.id)
            run.recoveredTeachingExpedition = .init(
                offeredTeachingID: definition.id, placement: target,
                resultingOfferStates: [.init(teachingID: definition.id, isDue: true)],
                resolvedAtOutcomeID: nil)
            state.worlds.activeRun = run
            if alreadyRecorded {
                _ = state.reality.library.recordTeaching(.init(
                    teachingID: definition.id, catalogueVersion: 1,
                    rewardKind: definition.reward.kind, rewardID: definition.reward.id,
                    recoveredAtOutcomeID: nil, worldSeed: run.mapSeed,
                    sourcePlacementIdentity: "world:\(run.mapSeed):\(target.x),\(target.y)",
                    recoveredAt: 0, readAt: nil, frozenTitle: definition.title,
                    frozenInstructionCopy: definition.instructionCopy))
            }
            return (state, target)
        }

        var (fresh, freshTarget) = fixture(alreadyRecorded: false)
        let freshXP = fresh.base.binderCharacter.experience
        let freshEvents = WorldRules.step(to: freshTarget, in: &fresh)
        XCTAssertEqual(fresh.base.binderCharacter.experience - freshXP,
                       Tuning.Character.experienceForPage)
        XCTAssertTrue(freshEvents.contains { if case .recoveredTeaching = $0 { true } else { false } })

        var (stale, staleTarget) = fixture(alreadyRecorded: true)
        let staleXP = stale.base.binderCharacter.experience
        let staleEvents = WorldRules.step(to: staleTarget, in: &stale)
        XCTAssertEqual(stale.base.binderCharacter.experience, staleXP)
        XCTAssertFalse(staleEvents.contains { if case .recoveredTeaching = $0 { true } else { false } })
        XCTAssertEqual(stale.worlds.activeRun?.map[staleTarget].content, .empty)
        XCTAssertEqual(stale.reality.library.recoveredTeachings.count, 1)
    }

    func testRecoveredTeachingCollectionRequiresExactFrozenReceiptAndPlacement() throws {
        let definition = try XCTUnwrap(RecoveredTeachingCatalogueV1.definitions.first)
        var state = startedRun(book(["terrain": "plains"]), seed: 2_026_082_702)
        var run = try XCTUnwrap(state.worlds.activeRun)
        run.enemies = []
        let target = try XCTUnwrap(run.map.neighbours(of: run.playerPosition)
            .first { WorldRules.canEnter($0, in: run.map) })
        run.map[target].content = .recoveredTeaching(definition.id)
        run.recoveredTeachingExpedition = .init(
            offeredTeachingID: "teaching.focus.stars", placement: target,
            resultingOfferStates: [.init(teachingID: "teaching.focus.stars", isDue: true)],
            resolvedAtOutcomeID: nil)
        state.worlds.activeRun = run
        let beforeLibrary = state.reality.library
        let beforeXP = state.base.binderCharacter.experience

        let events = WorldRules.step(to: target, in: &state)

        XCTAssertFalse(events.contains { if case .recoveredTeaching = $0 { true } else { false } })
        XCTAssertEqual(state.reality.library, beforeLibrary)
        XCTAssertEqual(state.base.binderCharacter.experience, beforeXP)
        XCTAssertEqual(state.worlds.activeRun?.map[target].content,
                       .recoveredTeaching(definition.id))

        var duplicate = startedRun(book(["terrain": "plains"]), seed: 2_026_082_703)
        var duplicateRun = try XCTUnwrap(duplicate.worlds.activeRun)
        duplicateRun.enemies = []
        let duplicateTarget = try XCTUnwrap(duplicateRun.map.neighbours(
            of: duplicateRun.playerPosition).first { WorldRules.canEnter($0, in: duplicateRun.map) })
        let second = try XCTUnwrap(duplicateRun.map.allPoints.first {
            $0 != duplicateTarget && duplicateRun.map[$0].content == .empty
        })
        duplicateRun.map[duplicateTarget].content = .recoveredTeaching(definition.id)
        duplicateRun.map[second].content = .recoveredTeaching(definition.id)
        duplicateRun.recoveredTeachingExpedition = .init(
            offeredTeachingID: definition.id, placement: duplicateTarget,
            resultingOfferStates: [.init(teachingID: definition.id, isDue: true)],
            resolvedAtOutcomeID: nil)
        duplicate.worlds.activeRun = duplicateRun
        _ = WorldRules.step(to: duplicateTarget, in: &duplicate)
        XCTAssertTrue(duplicate.reality.library.recoveredTeachings.isEmpty)
        XCTAssertEqual(duplicate.worlds.activeRun?.map[duplicateTarget].content,
                       .recoveredTeaching(definition.id))
    }

    func testExperienceBreakdownIsTolerantAndFrozenIntoARecap() throws {
        var run = try XCTUnwrap(startedRun(book([:]), seed: 741).worlds.activeRun)
        run.experienceBreakdown = RunExperienceBreakdown(combat: 36, species: 14,
                                                         sites: 20, pages: 25, travellers: 0)
        let encodedRun = try SaveCodec.makeEncoder().encode(run)
        XCTAssertEqual(try SaveCodec.makeDecoder().decode(WorldRun.self, from: encodedRun)
            .experienceBreakdown.total, 95)

        var legacy = try XCTUnwrap(JSONSerialization.jsonObject(with: encodedRun) as? [String: Any])
        legacy.removeValue(forKey: "experienceBreakdown")
        let legacyData = try JSONSerialization.data(withJSONObject: legacy)
        XCTAssertEqual(try SaveCodec.makeDecoder().decode(WorldRun.self, from: legacyData)
            .experienceBreakdown, RunExperienceBreakdown())

        let summary = RunExitSummary(runIndex: 1, kind: .portal, reason: "Home", turnsTaken: 4,
                                     haulKeptFraction: 1,
                                     experienceBreakdown: run.experienceBreakdown)
        let resumed = try SaveCodec.makeDecoder().decode(
            RunExitSummary.self, from: SaveCodec.makeEncoder().encode(summary))
        XCTAssertEqual(resumed.experienceBreakdown, run.experienceBreakdown)
    }

    // MARK: The world turning against you

    func testHazardsOnlyAppearOnceStabilityFalls() {
        var state = startedRun(book(["terrain": "plains"]), seed: 55)
        func hazardCount() -> Int { state.worlds.activeRun?.map.tiles.count { $0.content == .hazard } ?? 0 }

        // Well above the threshold: nothing changes.
        for _ in 0..<3 { _ = WorldRules.advanceTurn(in: &state) }
        XCTAssertEqual(hazardCount(), 0)

        // Drop below it and the edges start turning.
        state.worlds.activeRun?.stability = Tuning.World.hazardThreshold - 1
        for _ in 0..<6 { _ = WorldRules.advanceTurn(in: &state) }
        XCTAssertGreaterThan(hazardCount(), 0, "Past the threshold, hazards spawn at the edges")
    }

    func testCrumblingWarnsTheOutsideRingBeforeItFalls() {
        var state = startedRun(book(["terrain": "plains"]), seed: 56)
        state.worlds.activeRun?.stability = Tuning.World.crumbleThreshold - 1
        state.worlds.activeRun?.playerPosition = GridPoint(x: 7, y: 7) // middle of the map

        _ = WorldRules.advanceTurn(in: &state)
        let run = state.worlds.activeRun!

        let cracking = run.map.allPoints.filter { run.map[$0].isCracking }
        XCTAssertFalse(cracking.isEmpty)
        XCTAssertTrue(run.map.allPoints.allSatisfy { !run.map[$0].isCrumbled },
                      "a tile vanished on the same turn its warning appeared")
        for point in cracking {
            XCTAssertEqual(run.map.ring(of: point), 0, "Crumbling starts at the outermost ring")
        }
    }

    func testThePlayersTileGetsAFullWarningTurnBeforeItFalls() {
        var state = startedRun(book(["terrain": "plains"]), seed: 561)
        state.worlds.activeRun?.stability = 0
        state.worlds.activeRun?.collapsedOnTurn = 0
        guard let player = state.worlds.activeRun?.playerPosition else { return XCTFail("no player") }
        // Leave only the player's block, forcing it to be the next target.
        for point in state.worlds.activeRun!.map.allPoints where point != player {
            state.worlds.activeRun?.map[point].isCrumbled = true
        }

        var events = WorldRules.advanceTurn(in: &state)
        XCTAssertTrue(state.worlds.activeRun?.map[player].isCracking == true)
        XCTAssertFalse(state.worlds.activeRun?.map[player].isCrumbled == true)
        XCTAssertFalse(events.contains(.floorGaveWay))

        events = WorldRules.advanceTurn(in: &state)
        XCTAssertTrue(events.contains(.floorGaveWay))
    }

    func testCrackWarningsDoNotHalveSteadyStateCollapseSpeed() {
        var state = startedRun(book(["terrain": "plains"]), seed: 562)
        state.worlds.activeRun?.stability = 0
        state.worlds.activeRun?.collapsedOnTurn = 0

        _ = WorldRules.advanceTurn(in: &state) // primes the warning pipeline
        guard let primed = state.worlds.activeRun else { return XCTFail("run ended while priming") }
        let expected = WorldRules.crumbleRate(in: primed)
        let before = primed.map.allPoints.count { primed.map[$0].isCrumbled }
        _ = WorldRules.advanceTurn(in: &state)
        guard let afterRun = state.worlds.activeRun else { return XCTFail("run ended too early") }
        let after = afterRun.map.allPoints.count { afterRun.map[$0].isCrumbled }
        XCTAssertEqual(after - before, expected)
        XCTAssertGreaterThan(afterRun.map.allPoints.count { afterRun.map[$0].isCracking }, 0,
                             "collapse removed the warned wave but failed to warn the next one")
    }

    /// The meter emptying is announced — and **does not end the run**. You are still standing in a
    /// world that has begun to come apart, which is the whole of the decision it creates.
    func testCollapseIsAnnouncedAtZeroStabilityAndDoesNotEndTheRun() {
        let composition = book(["terrain": "plains"])
        var state = startedRun(composition, seed: 57)
        // Exactly one turn's worth left, whatever this book's rate happens to be — pinning a
        // literal here would break every time the stability scale is retuned.
        state.worlds.activeRun?.stability = BookRules.decayPerTurn(for: composition)

        let events = WorldRules.advanceTurn(in: &state)
        XCTAssertTrue(events.contains(.collapsed))
        XCTAssertFalse(events.contains(.floorGaveWay),
                       "an empty meter threw the player out of a world that was still there")
        XCTAssertNotNil(state.worlds.activeRun, "the run ended on a number rather than on the floor")
    }

    /// **You are only forced out when the block you're standing on goes.**
    func testYouAreOnlyThrownOutWhenTheFloorUnderYouGoes() {
        var state = startedRun(book(["terrain": "plains"]), seed: 57)
        state.worlds.activeRun?.stability = 0
        state.worlds.activeRun?.collapsedOnTurn = 0

        // Crumble until it reaches the player, which it now can.
        var events: [WorldRules.Event] = []
        for _ in 0..<400 where !events.contains(.floorGaveWay) {
            events = WorldRules.advanceTurn(in: &state)
            guard state.worlds.activeRun != nil else { break }
        }
        XCTAssertTrue(events.contains(.floorGaveWay),
                      "a world crumbled away entirely and never reached the player standing in it")
    }

    /// A collapsed world genuinely runs out rather than nibbling its edges forever.
    func testACollapsedWorldSpeedsUpTheLongerYouStay() {
        var state = startedRun(book(["terrain": "plains"]), seed: 57)
        state.worlds.activeRun?.stability = 0
        state.worlds.activeRun?.collapsedOnTurn = 0
        state.worlds.activeRun?.turnsTaken = 0
        let atOnce = WorldRules.crumbleRate(in: state.worlds.activeRun!)

        state.worlds.activeRun?.turnsTaken = 30
        XCTAssertGreaterThan(WorldRules.crumbleRate(in: state.worlds.activeRun!), atOnce)
    }

    /// **A spared portal is no use behind a wall.** Entry portals sit on the map edge, which is the
    /// first ring to crumble — so sparing the portal tile while eating everything around it left
    /// the player looking at an intact way out they couldn't reach, waiting to be thrown out. Which
    /// is exactly what sparing them was meant to prevent.
    func testAPortalStaysReachableForAsLongAsThePlayerIsStanding() {
        for seed in [UInt64(3), 57, 909] {
            var state = startedRun(book(["terrain": "plains"]), seed: seed)
            state.worlds.activeRun?.stability = 0
            state.worlds.activeRun?.collapsedOnTurn = 0
            // **Standing away from the way out**, which is the whole case. The run starts *on* the
            // entry portal, so a test that leaves the player there proves nothing at all.
            if let run = state.worlds.activeRun {
                let middle = run.map.allPoints
                    .filter { WorldRules.canEnter($0, in: run.map) && !run.map[$0].content.isPortal }
                    .max { run.map.ring(of: $0) < run.map.ring(of: $1) }
                if let middle { state.worlds.activeRun?.playerPosition = middle }
            }
            XCTAssertFalse(state.worlds.activeRun?.map[state.worlds.activeRun!.playerPosition]
                .content.isPortal ?? true, "the player has to start away from a portal")

            for _ in 0..<200 {
                let events = WorldRules.advanceTurn(in: &state)
                guard let run = state.worlds.activeRun, !events.contains(.floorGaveWay) else { break }
                XCTAssertTrue(
                    WorldRules.canReachAPortal(from: run.playerPosition, in: run.map),
                    "seed \(seed): the player was marooned with a portal standing and their own floor intact")
            }
        }
    }

    /// The way out is the last thing to go, or "reach a portal in time" becomes "wait to be thrown
    /// out", which is no decision at all.
    func testPortalsAreTheLastThingToCrumble() {
        var state = startedRun(book(["terrain": "plains"]), seed: 57)
        state.worlds.activeRun?.stability = 0
        state.worlds.activeRun?.collapsedOnTurn = 0

        for _ in 0..<60 {
            _ = WorldRules.advanceTurn(in: &state)
            guard let run = state.worlds.activeRun else { break }
            let portalsGone = run.map.allPoints.contains {
                run.map[$0].isCrumbled && run.map[$0].content.isPortal
            }
            let floorLeft = run.map.allPoints.contains {
                !run.map[$0].isCrumbled && !run.map[$0].content.isPortal
            }
            XCTAssertFalse(portalsGone && floorLeft, "a portal went while there was still floor")
        }
    }

    // MARK: Enemies

    func testEnemiesSleepUntilYouAreCloseThenWalkAtYou() {
        var state = startedRun(book(["terrain": "plains"]), seed: 61)
        var run = state.worlds.activeRun!
        run.enemies = []
        run.playerPosition = GridPoint(x: 7, y: 7)
        let sleeper = GridPoint(x: 7, y: 12) // far away
        run.enemies = [WorldEnemy(id: InstanceID(rawValue: 1), creatureID: "paper_moth", position: sleeper)]
        state.worlds.activeRun = run

        _ = WorldRules.advanceTurn(in: &state)
        XCTAssertEqual(state.worlds.activeRun?.enemies.first?.position, sleeper, "Inert until you come close")
        XCTAssertFalse(state.worlds.activeRun?.enemies.first?.isAwake ?? true)

        // Detection and contact are separate: the discovery turn wakes it in place, then a later
        // world turn lets the already-pursuing creature close the distance.
        state.worlds.activeRun?.enemies[0].position = GridPoint(x: 7, y: 9)
        _ = WorldRules.advanceTurn(in: &state)
        XCTAssertTrue(state.worlds.activeRun!.enemies[0].isAwake)
        XCTAssertEqual(state.worlds.activeRun!.enemies[0].position, GridPoint(x: 7, y: 9))

        _ = WorldRules.advanceTurn(in: &state)
        XCTAssertLessThan(state.worlds.activeRun!.enemies[0].position
            .chebyshevDistance(to: GridPoint(x: 7, y: 7)), 2)
    }

    func testQuietStepCreatesOnePersistedAlertTurnRatherThanAnInvisibleRoll() throws {
        var state = startedRun(book(["terrain": "plains"]), seed: 6_101)
        state.base.binderCharacter.level = 3
        state.base.binderCharacter.ownedCombatNodeIDs.formUnion(legacyCombatNodes(["shadow": 1]))
        var run = try XCTUnwrap(state.worlds.activeRun)
        run.enemies = []
        run.playerPosition = GridPoint(x: 7, y: 7)
        let position = GridPoint(x: 7, y: 9)
        run.map[position].isRevealed = true
        run.enemies = [WorldEnemy(id: InstanceID(rawValue: 61), creatureID: "paper_moth",
                                  position: position)]
        state.worlds.activeRun = run

        let first = WorldRules.advanceTurn(in: &state)
        let alerted = try XCTUnwrap(state.worlds.activeRun?.enemies.first)
        if case .alert(_, let reason) = alerted.awareness { XCTAssertEqual(reason, .quietStep) }
        else { XCTFail("Quiet Step did not create an alert state") }
        XCTAssertTrue(alerted.quietStepHesitationUsed)
        XCTAssertEqual(alerted.position, position)
        XCTAssertTrue(first.contains { if case .enemyAlerted = $0 { true } else { false } })

        var cryptic = alerted
        var crypticTraits = CreatureTraits()
        crypticTraits.defence = .crypsis
        cryptic.traits = crypticTraits
        XCTAssertTrue(WorldRules.isVisible(cryptic, in: try XCTUnwrap(state.worlds.activeRun)),
                      "The earned alert warned about a creature the map still hid")

        _ = WorldRules.advanceTurn(in: &state)
        XCTAssertTrue(state.worlds.activeRun?.enemies.first?.isAwake == true)

        let data = try JSONEncoder().encode(state.worlds.activeRun?.enemies.first)
        let resumed = try JSONDecoder().decode(WorldEnemy.self, from: data)
        XCTAssertTrue(resumed.isAwake)
        XCTAssertTrue(resumed.quietStepHesitationUsed)
    }

    func testScentMaskIsChemoOnlyNonstackingAndPersistsForTwelveAdvances() throws {
        var state = startedRun(book(["terrain": "plains"]), seed: 6_102)
        state.base.binderCharacter.level = 3
        state.base.binderCharacter.ownedCombatNodeIDs.formUnion(legacyCombatNodes(["shadow": 1]))
        var run = try XCTUnwrap(state.worlds.activeRun)
        run.playerPosition = .init(x: 7, y: 7)
        let position = GridPoint(x: 7, y: 9)
        run.map[position].isRevealed = true
        var traits = CreatureTraits()
        traits.sensory.vision = 0
        traits.sensory.mechano = 0
        traits.sensory.thermo = 0
        traits.sensory.chemo = 100
        run.enemies = [WorldEnemy(id: .init(rawValue: 62), traits: traits, position: position)]
        run.satchelItems = Inventory(slots: 2, stacks: [
            ItemStack(id: .init(rawValue: 620), catalogID: Items.scentMask)
        ])
        state.worlds.activeRun = run

        _ = WorldRules.useItem(.init(rawValue: 620), on: .binder, in: &state)
        var enemy = try XCTUnwrap(state.worlds.activeRun?.enemies.first)
        if case .alert(_, let reason) = enemy.awareness { XCTAssertEqual(reason, .maskedScent) }
        else { XCTFail("Scent Mask did not supply the chemo-only alert") }
        XCTAssertFalse(enemy.quietStepHesitationUsed,
                       "Mask must be evaluated before and preserve Quiet Step")
        XCTAssertEqual(state.worlds.activeRun?.scentMaskTurnsRemaining, 11)

        let encoded = try JSONEncoder().encode(state.worlds.activeRun)
        let resumed = try JSONDecoder().decode(WorldRun.self, from: encoded)
        XCTAssertEqual(resumed.scentMask, state.worlds.activeRun?.scentMask)

        for _ in 0..<11 { _ = WorldRules.advanceTurn(in: &state) }
        XCTAssertNil(state.worlds.activeRun?.scentMask)
        enemy = try XCTUnwrap(state.worlds.activeRun?.enemies.first)
        XCTAssertFalse(enemy.maskedScentContact)
    }

    func testScentMaskDoesNotAffectOtherSensesAdjacencyFloraOrApex() throws {
        func awareness(sensory: (vision: Double, mechano: Double, chemo: Double, thermo: Double),
                       distance: Int = 2, sessile: Bool = false, apex: Bool = false)
            throws -> WorldEnemy.Awareness {
            var state = startedRun(book(["terrain": "plains"]), seed: 6_103)
            var run = try XCTUnwrap(state.worlds.activeRun)
            run.playerPosition = .init(x: 7, y: 7)
            var traits = CreatureTraits()
            traits.sensory.vision = sensory.vision
            traits.sensory.mechano = sensory.mechano
            traits.sensory.chemo = sensory.chemo
            traits.sensory.thermo = sensory.thermo
            run.enemies = [WorldEnemy(id: .init(rawValue: 63), traits: traits,
                position: .init(x: 7, y: 7 + distance), isSessile: sessile, isApex: apex)]
            run.scentMask = .init(sourceItemInstanceID: .init(rawValue: 630), startTurn: 0,
                                  expiresAfterTurn: 12)
            state.worlds.activeRun = run
            _ = WorldRules.advanceTurn(in: &state)
            return try XCTUnwrap(state.worlds.activeRun?.enemies.first?.awareness)
        }

        XCTAssertEqual(try awareness(sensory: (100, 0, 0, 0)), .pursuing)
        XCTAssertEqual(try awareness(sensory: (0, 100, 0, 0)), .pursuing)
        XCTAssertEqual(try awareness(sensory: (0, 0, 100, 0), distance: 1), .pursuing)
        XCTAssertNotEqual(try awareness(sensory: (0, 0, 100, 0), sessile: true),
                          .alert(turn: 1, reason: .maskedScent))
        XCTAssertEqual(try awareness(sensory: (0, 0, 100, 0), apex: true), .unaware)
    }

    func testEncounterOpeningFreezesApproachMutualContactAndAmbushFromPreActionDisclosure() throws {
        func opening(disclosed: Bool, approached: Bool, apex: Bool = false) throws -> EncounterState.OpeningResolution {
            var state = startedRun(book(["terrain": "plains"]), seed: apex ? 8_103 : 8_101)
            var run = try XCTUnwrap(state.worlds.activeRun)
            let enemy = WorldEnemy(id: InstanceID(rawValue: apex ? 8103 : 8101),
                                   creatureID: "paper_moth", position: run.playerPosition,
                                   isApex: apex)
            run.enemies = [enemy]
            state.worlds.activeRun = run
            let snapshot = WorldRules.PreContactSnapshot(
                disclosedEnemyIDs: disclosed ? [enemy.id] : [],
                approachedEnemyID: approached ? enemy.id : nil
            )
            WorldRules.beginEncounter(triggeredBy: enemy, preContact: snapshot,
                                      runsAutomaticTurns: false, in: &state)
            return try XCTUnwrap(state.worlds.activeRun?.activeEncounter?.opening)
        }

        XCTAssertEqual(try opening(disclosed: true, approached: true).resolved, .partyApproach)
        XCTAssertEqual(try opening(disclosed: true, approached: false).resolved, .mutualContact)
        let ambush = try opening(disclosed: false, approached: false)
        XCTAssertEqual(ambush.initial, .creatureAmbush)
        XCTAssertEqual(ambush.resolved, .creatureAmbush)
        XCTAssertFalse(ambush.pendingFoeActions.isEmpty)
        XCTAssertEqual(try opening(disclosed: false, approached: false, apex: true).resolved,
                       .partyApproach, "an apex never gains an ordinary creature ambush")
    }

    func testRealStepUsesThePresentationBeforeMovementAndReveal() throws {
        var state = startedRun(book(["terrain": "plains"]), seed: 8_105)
        var run = try XCTUnwrap(state.worlds.activeRun)
        let destination = try XCTUnwrap(run.map.neighbours(of: run.playerPosition)
            .first { WorldRules.canEnter($0, in: run.map) })
        run.map[destination].isRevealed = true
        let enemy = WorldEnemy(id: InstanceID(rawValue: 8105), creatureID: "paper_moth",
                               position: destination)
        run.enemies = [enemy]
        state.worlds.activeRun = run

        _ = WorldRules.step(to: destination, in: &state)

        let opening = try XCTUnwrap(state.worlds.activeRun?.activeEncounter?.opening)
        XCTAssertTrue(opening.preContactDisclosed)
        XCTAssertEqual(opening.initial, .mutualContact)
        XCTAssertEqual(opening.resolved, .mutualContact)
    }

    func testApexAdjacencyIsSafeAndOnlyOccupiedTileEntryStartsCombat() throws {
        var state = GameState.newGame()
        let start = GridPoint(x: 0, y: 0)
        let destination = GridPoint(x: 1, y: 0)
        let apexPoint = GridPoint(x: 2, y: 0)
        let map = WorldMap(width: 3, height: 1,
                           tiles: [Tile(isRevealed: true), Tile(isRevealed: true),
                                   Tile(isRevealed: true)], entry: start)
        let composition = book(["terrain": "plains"])
        let apex = WorldEnemy(id: InstanceID(rawValue: 8106), creatureID: "paper_moth",
                              position: apexPoint, isApex: true)
        state.worlds.activeRun = WorldRun(runIndex: 1, book: composition, mapSeed: 8_106,
                                          rng: SeededRNG(seed: 8_106), map: map,
                                          playerPosition: start, enemies: [apex])

        _ = WorldRules.step(to: destination, in: &state)

        XCTAssertEqual(state.worlds.activeRun?.playerPosition, destination)
        XCTAssertNil(state.worlds.activeRun?.activeEncounter)
        XCTAssertTrue(WorldRules.automaticTravelMustStop(
            before: apexPoint, in: try XCTUnwrap(state.worlds.activeRun)))

        let beforeLook = try XCTUnwrap(state.worlds.activeRun)
        _ = WorldRules.inspect(apexPoint, in: beforeLook)
        XCTAssertEqual(state.worlds.activeRun, beforeLook, "Look must be byte-state neutral")
        _ = WorldRules.advanceTurn(in: &state)
        XCTAssertNil(state.worlds.activeRun?.activeEncounter,
                     "waiting beside an apex must not manufacture contact")

        _ = WorldRules.step(to: apexPoint, in: &state)
        XCTAssertEqual(state.worlds.activeRun?.activeEncounter?.opening?.resolved, .partyApproach)
    }

    func testActiveFloraAdjacencyIsSafeAndOnlyOccupiedTileEntryStartsCombat() throws {
        var state = GameState.newGame()
        let start = GridPoint(x: 0, y: 0), beside = GridPoint(x: 1, y: 0)
        let occupied = GridPoint(x: 2, y: 0)
        let map = WorldMap(width: 3, height: 1,
                           tiles: Array(repeating: Tile(isRevealed: true), count: 3), entry: start)
        let flora = WorldEnemy(id: InstanceID(rawValue: 8107), creatureID: "paper_moth",
                               position: occupied, isSessile: true)
        state.worlds.activeRun = WorldRun(runIndex: 1, book: book(["terrain": "plains"]),
                                          mapSeed: 8_107, rng: SeededRNG(seed: 8_107), map: map,
                                          playerPosition: start, enemies: [flora])

        _ = WorldRules.step(to: beside, in: &state)
        XCTAssertNil(state.worlds.activeRun?.activeEncounter)
        _ = WorldRules.advanceTurn(in: &state)
        XCTAssertNil(state.worlds.activeRun?.activeEncounter)
        _ = WorldRules.step(to: occupied, in: &state)
        XCTAssertEqual(state.worlds.activeRun?.activeEncounter?.opening?.resolved, .partyApproach)
    }

    func testEnteringOrdinaryAdjacencyWakesWithoutFabricatingContact() throws {
        var state = GameState.newGame()
        let start = GridPoint(x: 0, y: 0), beside = GridPoint(x: 1, y: 0)
        let occupied = GridPoint(x: 2, y: 0)
        let map = WorldMap(width: 3, height: 1,
                           tiles: Array(repeating: Tile(isRevealed: true), count: 3), entry: start)
        let enemy = WorldEnemy(id: InstanceID(rawValue: 8108), creatureID: "paper_moth",
                               position: occupied)
        state.worlds.activeRun = WorldRun(runIndex: 1, book: book(["terrain": "plains"]),
                                          mapSeed: 8_108, rng: SeededRNG(seed: 8_108), map: map,
                                          playerPosition: start, enemies: [enemy])

        _ = WorldRules.step(to: beside, in: &state)
        XCTAssertNil(state.worlds.activeRun?.activeEncounter)
        XCTAssertEqual(state.worlds.activeRun?.enemies.first?.position, occupied)
        XCTAssertTrue(state.worlds.activeRun?.enemies.first?.isAwake == true)
    }

    func testCreatureAmbushOpeningActionsRunBeforeOrdinaryInitiativeAndPersist() throws {
        var state = startedRun(book(["terrain": "plains"]), seed: 8_111)
        var run = try XCTUnwrap(state.worlds.activeRun)
        let enemy = WorldEnemy(id: InstanceID(rawValue: 8111), creatureID: "paper_moth",
                               position: run.playerPosition)
        let second = WorldEnemy(id: InstanceID(rawValue: 8112), creatureID: "paper_moth",
                                position: run.playerPosition, isAwake: true)
        run.enemies = [enemy, second]
        state.worlds.activeRun = run
        WorldRules.beginEncounter(triggeredBy: enemy,
                                  preContact: .init(disclosedEnemyIDs: [], approachedEnemyID: nil),
                                  runsAutomaticTurns: false, in: &state)
        let frozen = try XCTUnwrap(state.worlds.activeRun?.activeEncounter)
        let relativeFoeOrder = frozen.order.compactMap(\.foeID)
        XCTAssertEqual(frozen.opening?.pendingFoeActions, relativeFoeOrder)
        XCTAssertEqual(relativeFoeOrder.count, 2)

        let resumed = try SaveCodec.makeDecoder().decode(
            EncounterState.self, from: SaveCodec.makeEncoder().encode(frozen))
        XCTAssertEqual(resumed.opening, frozen.opening)

        let logCount = frozen.log.count
        let ordinaryTurnIndex = frozen.turnIndex
        CombatRules.runAutomaticTurns(in: &state)
        let after = try XCTUnwrap(state.worlds.activeRun?.activeEncounter)
        XCTAssertTrue(after.opening?.pendingFoeActions.isEmpty == true)
        XCTAssertGreaterThanOrEqual(after.log.count, logCount + 2,
                                    "each living foe did not resolve one opening action")
        XCTAssertEqual(after.turnIndex, ordinaryTurnIndex,
                       "an opening action incorrectly consumed the foe's ordinary initiative slot")
    }

    func testWatchfulSuppressesActionsWithoutReclassifyingAmbush() throws {
        var state = startedRun(book(["terrain": "plains"]), seed: 8_121)
        state.base.binderCharacter.ownedCombatNodeIDs.formUnion(legacyCombatNodes(["protection": 2]))
        var run = try XCTUnwrap(state.worlds.activeRun)
        let enemy = WorldEnemy(id: InstanceID(rawValue: 8121), creatureID: "paper_moth",
                               position: run.playerPosition)
        run.enemies = [enemy]
        state.worlds.activeRun = run
        WorldRules.beginEncounter(triggeredBy: enemy,
                                  preContact: .init(disclosedEnemyIDs: [], approachedEnemyID: nil),
                                  runsAutomaticTurns: false, in: &state)

        let opening = try XCTUnwrap(state.worlds.activeRun?.activeEncounter?.opening)
        XCTAssertEqual(opening.resolved, .creatureAmbush)
        XCTAssertTrue(opening.watchfulSuppressedOpening)
        XCTAssertTrue(opening.pendingFoeActions.isEmpty)
    }

    func testSlipperyRollIsSavedAndUnseenAndAmbushReadTheFrozenOpening() throws {
        var preventedState: GameState?
        for seed in UInt64(8_130)...8_194 {
            var state = startedRun(book(["terrain": "plains"]), seed: seed)
            state.base.binderCharacter.ownedCombatNodeIDs.formUnion(legacyCombatNodes(["evasion": 4]))
            var run = try XCTUnwrap(state.worlds.activeRun)
            let enemy = WorldEnemy(id: InstanceID(rawValue: seed), creatureID: "paper_moth",
                                   position: run.playerPosition)
            run.enemies = [enemy]
            state.worlds.activeRun = run
            WorldRules.beginEncounter(triggeredBy: enemy,
                                      preContact: .init(disclosedEnemyIDs: [], approachedEnemyID: nil),
                                      runsAutomaticTurns: false, in: &state)
            if state.worlds.activeRun?.activeEncounter?.opening?.slipperyPrevented == true {
                preventedState = state
                break
            }
        }
        let slippery = try XCTUnwrap(preventedState)
        let slipperyOpening = try XCTUnwrap(slippery.worlds.activeRun?.activeEncounter?.opening)
        XCTAssertEqual(slipperyOpening.initial, .creatureAmbush)
        XCTAssertEqual(slipperyOpening.resolved, .mutualContact)
        XCTAssertNotNil(slipperyOpening.slipperyRoll)
        XCTAssertTrue(slipperyOpening.pendingFoeActions.isEmpty)

        var unseen = startedRun(book(["terrain": "plains"]), seed: 8_195)
        unseen.base.binderCharacter.ownedCombatNodeIDs.formUnion(legacyCombatNodes(["shadow": 8]))
        var run = try XCTUnwrap(unseen.worlds.activeRun)
        let enemy = WorldEnemy(id: InstanceID(rawValue: 8195), creatureID: "paper_moth",
                               position: run.playerPosition)
        run.enemies = [enemy]
        unseen.worlds.activeRun = run
        WorldRules.beginEncounter(triggeredBy: enemy,
                                  preContact: .init(disclosedEnemyIDs: [], approachedEnemyID: nil),
                                  runsAutomaticTurns: false, in: &unseen)
        let encounter = try XCTUnwrap(unseen.worlds.activeRun?.activeEncounter)
        XCTAssertEqual(encounter.opening?.resolved, .creatureAmbush)
        XCTAssertEqual(encounter.concealed[.binder], 1)
        let ambushSkill = try XCTUnwrap(ContentCatalog.shared.skill("ambush"))
        XCTAssertFalse(CombatRules.isReady(ambushSkill, for: .binder, in: encounter))

        var approach = unseen
        approach.worlds.activeRun?.activeEncounter = nil
        WorldRules.beginEncounter(triggeredBy: enemy,
                                  preContact: .init(disclosedEnemyIDs: [enemy.id],
                                                    approachedEnemyID: enemy.id),
                                  runsAutomaticTurns: false, in: &approach)
        let approached = try XCTUnwrap(approach.worlds.activeRun?.activeEncounter)
        XCTAssertTrue(CombatRules.isReady(ambushSkill, for: .binder, in: approached))
        var legacyEncounter = approached
        legacyEncounter.opening = nil
        legacyEncounter.roundNumber = 5
        XCTAssertFalse(CombatRules.isReady(ambushSkill, for: .binder, in: legacyEncounter),
                       "a legacy mid-fight save gained a new free opening attack")
        var scriptedAllows = approached
        scriptedAllows.opening?.resolved = .scripted(scriptID: "test.opening", overridesWatchful: true,
                                                      allowsPartyOpeningAttack: true)
        XCTAssertTrue(CombatRules.isReady(ambushSkill, for: .binder, in: scriptedAllows))
        var scriptedForbids = approached
        scriptedForbids.opening?.resolved = .scripted(scriptID: "test.opening", overridesWatchful: false,
                                                      allowsPartyOpeningAttack: false)
        XCTAssertFalse(CombatRules.isReady(ambushSkill, for: .binder, in: scriptedForbids),
                       "scripted Ambush policy was inferred from Watchful policy")
        let turnIndex = approached.turnIndex
        CombatRules.perform(.skill(ambushSkill.id, foe: enemy.id), by: .binder, in: &approach)
        let afterAmbush = try XCTUnwrap(approach.worlds.activeRun?.activeEncounter)
        XCTAssertTrue(afterAmbush.openingAttackConsumed.contains(.binder))
        XCTAssertFalse(afterAmbush.completedFirstActions.contains(.binder))
        XCTAssertEqual(afterAmbush.turnIndex, turnIndex, "Ambush consumed the actor's ordinary turn")
        let frozenAfterUse = afterAmbush
        CombatRules.perform(.skill(ambushSkill.id, foe: enemy.id), by: .binder, in: &approach)
        XCTAssertEqual(approach.worlds.activeRun?.activeEncounter, frozenAfterUse,
                       "a repeated or stale Ambush tap mutated the encounter")

        var quickenFirst = unseen
        quickenFirst.base.binderCharacter.ownedCombatNodeIDs.formUnion(legacyCombatNodes(["swiftness": 3]))
        quickenFirst.base.binderCharacter.ownedCombatNodeIDs.formUnion(legacyCombatNodes(["shadow": 5]))
        quickenFirst.worlds.activeRun?.activeEncounter = nil
        WorldRules.beginEncounter(triggeredBy: enemy,
                                  preContact: .init(disclosedEnemyIDs: [enemy.id],
                                                    approachedEnemyID: enemy.id),
                                  runsAutomaticTurns: false, in: &quickenFirst)
        CombatRules.perform(.skill("quicken"), by: .binder, in: &quickenFirst)
        let afterQuicken = try XCTUnwrap(quickenFirst.worlds.activeRun?.activeEncounter)
        XCTAssertFalse(afterQuicken.completedFirstActions.contains(.binder),
                       "Quicken was incorrectly recorded as a normal-cost first action")
        XCTAssertTrue(afterQuicken.openingAttackConsumed.contains(.binder),
                      "choosing Quicken did not close the separate Ambush opportunity")
        XCTAssertFalse(CombatRules.isReady(ambushSkill, for: .binder, in: afterQuicken),
                       "Quicken left Ambush available on its borrowed action")

        var partial = try XCTUnwrap(JSONSerialization.jsonObject(
            with: JSONEncoder().encode(approached)) as? [String: Any])
        var openingObject = try XCTUnwrap(partial["opening"] as? [String: Any])
        openingObject.removeValue(forKey: "pendingFoeActions")
        openingObject.removeValue(forKey: "slipperyPrevented")
        openingObject.removeValue(forKey: "watchfulSuppressedOpening")
        partial["opening"] = openingObject
        let tolerant = try JSONDecoder().decode(
            EncounterState.self, from: JSONSerialization.data(withJSONObject: partial))
        XCTAssertEqual(tolerant.opening?.pendingFoeActions, [])
        XCTAssertEqual(tolerant.opening?.slipperyPrevented, false)
        XCTAssertEqual(tolerant.opening?.watchfulSuppressedOpening, false)
    }

    func testUnseenExcludesOnlyItsOwnerFromOpeningTargetsThroughFirstOrdinaryRound() throws {
        var state = startedRun(book(["terrain": "plains"]), seed: 8_201)
        state.base.binderCharacter.ownedCombatNodeIDs.formUnion(legacyCombatNodes(["shadow": 8]))
        var companion = CompanionState()
        companion.name = "Quill"
        state.base.roster = [companion]
        state.base.activeParty = [0]
        var run = try XCTUnwrap(state.worlds.activeRun)
        run.companionHP[0] = companion.maxHP
        let enemy = WorldEnemy(id: InstanceID(rawValue: 8201), creatureID: "paper_moth",
                               position: run.playerPosition)
        run.enemies = [enemy]
        state.worlds.activeRun = run
        WorldRules.beginEncounter(triggeredBy: enemy,
                                  preContact: .init(disclosedEnemyIDs: [], approachedEnemyID: nil),
                                  runsAutomaticTurns: false, in: &state)

        let binderHP = try XCTUnwrap(state.worlds.activeRun?.binderHP)
        CombatRules.runAutomaticTurns(in: &state)
        let afterOpening = try XCTUnwrap(state.worlds.activeRun?.activeEncounter)
        XCTAssertEqual(state.worlds.activeRun?.binderHP, binderHP,
                       "Unseen's owner was a legal foe-opening target")
        XCTAssertTrue(afterOpening.log.suffix(2).contains { $0.contains("Quill") },
                      "the visible companion was not used as the legal opening target")
        XCTAssertEqual(afterOpening.concealed[.binder], 1)

        var safety = 0
        while state.worlds.activeRun?.activeEncounter?.roundNumber == 1, safety < 8 {
            CombatRules.advanceTurn(in: &state)
            safety += 1
        }
        XCTAssertNil(state.worlds.activeRun?.activeEncounter?.concealed[.binder],
                     "Unseen lasted beyond the end of the first ordinary round")

        var allUnseen = startedRun(book(["terrain": "plains"]), seed: 8_202)
        allUnseen.base.binderCharacter.ownedCombatNodeIDs.formUnion(legacyCombatNodes(["shadow": 8]))
        var hiddenCompanion = CompanionState()
        hiddenCompanion.name = "Quill"
        hiddenCompanion.character.ownedCombatNodeIDs.formUnion(legacyCombatNodes(["shadow": 8]))
        allUnseen.base.roster = [hiddenCompanion]
        allUnseen.base.activeParty = [0]
        var allHiddenRun = try XCTUnwrap(allUnseen.worlds.activeRun)
        allHiddenRun.companionHP[0] = hiddenCompanion.maxHP
        let secondEnemy = WorldEnemy(id: InstanceID(rawValue: 8202), creatureID: "paper_moth",
                                     position: allHiddenRun.playerPosition)
        allHiddenRun.enemies = [secondEnemy]
        allUnseen.worlds.activeRun = allHiddenRun
        WorldRules.beginEncounter(triggeredBy: secondEnemy,
                                  preContact: .init(disclosedEnemyIDs: [], approachedEnemyID: nil),
                                  runsAutomaticTurns: false, in: &allUnseen)
        let beforeAllHidden = try XCTUnwrap(allUnseen.worlds.activeRun?.activeEncounter?.log.count)
        CombatRules.runAutomaticTurns(in: &allUnseen)
        let afterAllHidden = try XCTUnwrap(allUnseen.worlds.activeRun?.activeEncounter)
        XCTAssertTrue(afterAllHidden.opening?.pendingFoeActions.isEmpty == true)
        XCTAssertGreaterThan(afterAllHidden.log.count, beforeAllHidden,
                             "an all-concealed party incorrectly erased every legal target")
    }

    func testUnseenExcludesItsOwnerFromMultiAndAreaOpeningDelivery() throws {
        for (offset, delivery) in [Delivery.multi, .area].enumerated() {
            var state = startedRun(book(["terrain": "plains"]), seed: 8_210 + UInt64(offset))
            state.base.binderCharacter.ownedCombatNodeIDs.formUnion(legacyCombatNodes(["shadow": 8]))
            var companion = CompanionState()
            companion.name = "Quill"
            state.base.roster = [companion]
            state.base.activeParty = [0]
            var run = try XCTUnwrap(state.worlds.activeRun)
            run.companionHP[0] = companion.maxHP
            let enemy = WorldEnemy(id: InstanceID(rawValue: 8210 + UInt64(offset)),
                                   creatureID: "paper_moth", position: run.playerPosition)
            run.enemies = [enemy]
            state.worlds.activeRun = run
            WorldRules.beginEncounter(triggeredBy: enemy,
                                      preContact: .init(disclosedEnemyIDs: [], approachedEnemyID: nil),
                                      runsAutomaticTurns: false, in: &state)
            state.worlds.activeRun?.activeEncounter?.foes[0].stats.delivery = delivery
            state.worlds.activeRun?.activeEncounter?.foes[0].stats.attack = 20
            let binderHP = try XCTUnwrap(state.worlds.activeRun?.binderHP)
            let companionHP = try XCTUnwrap(state.worlds.activeRun?.companionHP[0])

            CombatRules.runAutomaticTurns(in: &state)

            XCTAssertEqual(state.worlds.activeRun?.binderHP, binderHP,
                           "\(delivery) bypassed opening target legality")
            XCTAssertLessThan(try XCTUnwrap(state.worlds.activeRun?.companionHP[0]), companionHP)
        }
    }

    func testOldEnemyAwakeFlagMigratesToSingleAwarenessAuthority() throws {
        let awake = WorldEnemy(id: InstanceID(rawValue: 71), creatureID: "paper_moth",
                               position: GridPoint(x: 1, y: 1), isAwake: true)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(awake)) as? [String: Any])
        object.removeValue(forKey: "awareness")
        let migrated = try JSONDecoder().decode(WorldEnemy.self,
            from: JSONSerialization.data(withJSONObject: object))
        XCTAssertEqual(migrated.awareness, .pursuing)
        migrated.isAwake ? XCTAssertTrue(true) : XCTFail("Legacy awake state was lost")

        var sleepingObject = object
        sleepingObject["isAwake"] = false
        let sleeping = try JSONDecoder().decode(WorldEnemy.self,
            from: JSONSerialization.data(withJSONObject: sleepingObject))
        XCTAssertEqual(sleeping.awareness, .unaware)
    }

    func testFieldRadiusSkillsArePartyScopedNonstackingAndHomeDoesNotHelp() {
        var state = GameState.newGame()
        state.base.binderCharacter.level = 5
        state.base.binderCharacter.ownedCombatNodeIDs.formUnion(legacyCombatNodes(["shadow": 2]))
        XCTAssertEqual(WorldRules.fieldConcealment(in: state).radiusReduction, 1)

        var traveller = CompanionState()
        traveller.character.level = 10
        traveller.character.ownedCombatNodeIDs.formUnion(legacyCombatNodes(["shadow": 7]))
        state.base.roster = [traveller, traveller]
        state.base.activeParty = [0]
        XCTAssertEqual(WorldRules.fieldConcealment(in: state).radiusReduction, 2)
        state.base.activeParty = []
        XCTAssertEqual(WorldRules.fieldConcealment(in: state).radiusReduction, 1,
                       "A skilled person left at Home affected the travelling party")
    }

    func testWalkingIntoAnEnemyOpensAnEncounterAndLogsTheCreature() {
        var state = startedRun(book(["terrain": "plains"]), seed: 62)
        var run = state.worlds.activeRun!
        let target = run.map.neighbours(of: run.playerPosition).first { WorldRules.canEnter($0, in: run.map) }!
        run.enemies = [WorldEnemy(id: InstanceID(rawValue: 7), creatureID: "ink_hound", position: target, isAwake: true)]
        state.worlds.activeRun = run

        let events = WorldRules.step(to: target, in: &state)
        XCTAssertTrue(events.contains(.encounterBegan))
        XCTAssertNotNil(state.worlds.activeRun?.activeEncounter)
        XCTAssertEqual(state.worlds.activeRun?.activeEncounter?.foes.first?.creatureID, "ink_hound")
        XCTAssertTrue(state.reality.discovery.hasEncountered(creature: "ink_hound"))
    }

    func testEncounterHabitatMismatchRejectsWholeGroupWithoutDiscoveryOrCommencement() throws {
        var state = startedRun(book(["terrain": "plains"]), seed: 6_213)
        var run = try XCTUnwrap(state.worlds.activeRun)
        let destination = try XCTUnwrap(run.map.neighbours(of: run.playerPosition)
            .first { WorldRules.canEnter($0, in: run.map) })
        let otherLegalTile = try XCTUnwrap(run.map.neighbours(of: destination).first)
        run.map[destination].isRevealed = true
        run.map[otherLegalTile].isRevealed = true
        let first = WorldEnemy(
            id: .init(rawValue: 62_130), creatureID: "paper_moth", position: destination,
            habitatPlacement: .init(habitat: .terrestrial, componentID: 1,
                                    legalTiles: [destination, otherLegalTile],
                                    contactEligible: true), isAwake: true)
        let conflicting = WorldEnemy(
            id: .init(rawValue: 62_131), creatureID: "ink_hound", position: destination,
            habitatPlacement: .init(habitat: .aerial, componentID: 2,
                                    legalTiles: [destination, otherLegalTile],
                                    contactEligible: true), isAwake: true)
        run.enemies = [first, conflicting]
        state.worlds.activeRun = run
        XCTAssertTrue(state.reality.discovery.recordSpecies(
            conflicting.identityKey, habitat: .shore, runIndex: 0))
        let discoveryBefore = state.reality.discovery

        let events = WorldRules.step(to: destination, in: &state)

        XCTAssertFalse(events.contains(.encounterBegan))
        XCTAssertNil(state.worlds.activeRun?.activeEncounter)
        XCTAssertEqual(state.reality.discovery, discoveryBefore,
                       "An earlier valid group member was staged before a later mismatch refused")
        XCTAssertFalse(state.reality.discovery.hasEncountered(species: first.identityKey))
    }

    // MARK: Banking

    @MainActor
    func testPlayableEntryRefusalLeavesTheEntireCampaignByteIdentical() throws {
        let store = GameStore(io: .temporary(name: "entry-refusal-\(UUID().uuidString)"))
        store.mutate("prepare nontrivial refusal state") { state in
            state.base.essence = 1_000
            if let salve = ContentCatalog.shared.item("salve") {
                state.base.inventory.add(ItemStack(id: InstanceID(rawValue: 7_701),
                                                   catalogID: salve.id, count: 1))
                state.base.preparationLoadout = [
                    .init(itemID: salve.id, desiredCount: 1, order: 0)
                ]
                state.base.preparationLoadoutNeedsReview = false
            }
        }
        XCTAssertTrue(store.bindAndDepart())
        if let id = store.state.worlds.pendingWorldArrivalReceiptID {
            XCTAssertTrue(store.enterPendingWorld(arrivalReceiptID: id))
        }
        store.mutate("stand on the return portal") { state in
            guard let entry = state.worlds.activeRun?.map.entry else { return }
            state.worlds.activeRun?.playerPosition = entry
        }
        store.portalHome()
        XCTAssertFalse(store.state.reality.library.visitedWorlds.isEmpty)
        store.write("plains")
        let heldPage = try XCTUnwrap(WorldPageCatalog.starterInstances.first)
        store.mutate("hold a consumable World Page") {
            $0.base.collectedWorldPages = [heldPage]
        }
        let pageBefore = store.state.base.page
        let essenceBefore = store.state.base.essence
        let seedBefore = store.state.worlds.seeds
        let historyBefore = store.state.reality.library
        let fieldKitBefore = store.state.base.inventory
        let before = try SaveCodec.encode(store.state)
        let didBind = store.bindAndDepart(
            worldPageInstanceID: heldPage.id,
            openColorResolver: { scope, sigil, seed in
                try WorldGrade2BindAdapter.openColor(
                    scope: scope, selectedSigilID: sigil.id, mapSeed: seed)
            },
            forcePlayableEntryRefusalForTesting: true)
        XCTAssertFalse(didBind)
        XCTAssertEqual(try SaveCodec.encode(store.state), before)
        XCTAssertEqual(store.state.base.page, pageBefore)
        XCTAssertEqual(store.state.base.essence, essenceBefore)
        XCTAssertEqual(store.state.worlds.seeds, seedBefore)
        XCTAssertEqual(store.state.reality.library, historyBefore)
        XCTAssertEqual(store.state.base.inventory, fieldKitBefore)
        XCTAssertEqual(store.state.base.collectedWorldPages, [heldPage])
        XCTAssertNil(store.state.worlds.activeRun)
    }

    @MainActor
    func testAcceptedPlayableEntryRunRelaunchesByteIdentically() throws {
        let io = SaveFileIO.temporary(name: "entry-relaunch-\(UUID().uuidString)")
        defer { io.deleteEverything() }
        let first = GameStore(io: io)
        first.write("plains")
        XCTAssertTrue(first.bindAndDepart())
        if let id = first.state.worlds.pendingWorldArrivalReceiptID {
            XCTAssertTrue(first.enterPendingWorld(arrivalReceiptID: id))
        }
        XCTAssertEqual(first.state.worlds.activeRun?.generationDiagnostics.playableEntry?.isAccepted,
                       true)
        first.flushNow()
        let before = try XCTUnwrap(first.state.worlds.activeRun)
        let mapBytes = try SaveCodec.makeEncoder().encode(before.map)
        let diagnosticsBytes = try SaveCodec.makeEncoder().encode(before.generationDiagnostics)
        let history = first.state.reality.library.visitedWorlds
        let second = GameStore(io: io)
        let after = try XCTUnwrap(second.state.worlds.activeRun)
        XCTAssertEqual(after, before)
        XCTAssertEqual(try SaveCodec.makeEncoder().encode(after.map), mapBytes)
        XCTAssertEqual(try SaveCodec.makeEncoder().encode(after.generationDiagnostics), diagnosticsBytes)
        XCTAssertEqual(after.worldArrivalReceipt, before.worldArrivalReceipt)
        XCTAssertEqual(second.state.reality.library.visitedWorlds, history)
        XCTAssertEqual(second.state.worlds.activeRun, first.state.worlds.activeRun)
    }

    @MainActor
    func testInvalidAnchoredSnapshotRefusesBeforeFieldKitMutationAndRemainsStored() throws {
        let io = SaveFileIO.temporary(name: "invalid-anchor-\(UUID().uuidString)")
        defer { io.deleteEverything() }
        let store = GameStore(io: io)
        store.mutate("prepare anchorage") { state in
            state.base.stations[Stations.anchorage] = StationState(isUnlocked: true, tier: 0)
            state.base.essence = 1_000
            state.worlds.seeds = SeedSequence(rootSeed: 1)
        }
        XCTAssertTrue(store.bindAndDepart(bornAnchored: true))
        if let id = store.state.worlds.pendingWorldArrivalReceiptID {
            XCTAssertTrue(store.enterPendingWorld(arrivalReceiptID: id))
        }
        let realmID = try XCTUnwrap(store.state.worlds.anchoredRealms.first?.id)
        store.mutate("make anchored snapshot invalid") { state in
            state.worlds.activeRun = nil
            state.worlds.anchoredRealms[0].world.generationDiagnostics.playableEntry = nil
            for point in state.worlds.anchoredRealms[0].world.map.allPoints
                where state.worlds.anchoredRealms[0].world.map[point].content.isPortal {
                state.worlds.anchoredRealms[0].world.map[point].content = .empty
            }
        }
        let before = try XCTUnwrap(store.state.worlds.anchoredRealms.first)
        XCTAssertFalse(store.revisitAnchoredRealm(realmID))
        XCTAssertEqual(store.state.worlds.anchoredRealms.first, before)
        XCTAssertNil(store.state.worlds.activeRun)
        XCTAssertEqual(store.state.worlds.anchoredRealms.first?.id, realmID)
        store.flushNow()
        let relaunched = GameStore(io: io)
        XCTAssertFalse(relaunched.revisitAnchoredRealm(realmID))
        XCTAssertEqual(relaunched.state.worlds.anchoredRealms.first, before)
        XCTAssertEqual(relaunched.state.worlds.anchoredRealms.first?.id, realmID)
    }

    @MainActor
    func testLegacyAnchoredSnapshotWithoutReceiptRemainsRevisitableWhenPortalReachable() throws {
        let store = GameStore(io: .temporary(name: "legacy-anchor-\(UUID().uuidString)"))
        store.mutate("prepare anchorage") { state in
            state.base.stations[Stations.anchorage] = StationState(isUnlocked: true, tier: 0)
            state.base.essence = 1_000
            state.worlds.seeds = SeedSequence(rootSeed: 1)
        }
        XCTAssertTrue(store.bindAndDepart(bornAnchored: true))
        if let id = store.state.worlds.pendingWorldArrivalReceiptID {
            XCTAssertTrue(store.enterPendingWorld(arrivalReceiptID: id))
        }
        let realmID = try XCTUnwrap(store.state.worlds.anchoredRealms.first?.id)
        store.mutate("make anchored snapshot legacy") { state in
            state.worlds.activeRun = nil
            state.worlds.anchoredRealms[0].world.generationDiagnostics.playableEntry = nil
        }
        XCTAssertTrue(store.revisitAnchoredRealm(realmID))
        XCTAssertEqual(store.state.worlds.activeRun?.runIndex,
                       store.state.worlds.anchoredRealms.first?.runIndex)
    }

    @MainActor
    func testPortalHomeKeepsEverything() {
        let store = GameStore(io: .temporary(name: "portal-\(UUID().uuidString)"))
        store.write("plains")
        store.bindAndDepart()
        if let id = store.state.worlds.pendingWorldArrivalReceiptID {
            XCTAssertTrue(store.enterPendingWorld(arrivalReceiptID: id))
        }
        store.mutate("stock the satchel") { $0.worlds.activeRun?.satchel.add(9, of: Resources.ore) }
        store.mutate("stand on the return portal") { state in
            guard let entry = state.worlds.activeRun?.map.entry else { return }
            state.worlds.activeRun?.playerPosition = entry
        }

        XCTAssertTrue(store.canPortalHere)
        store.portalHome()

        XCTAssertNil(store.state.worlds.activeRun)
        XCTAssertEqual(store.state.base.resources[Resources.ore], 9, "Portalling out keeps the lot")
        XCTAssertEqual(store.state.reality.lifetime.runsBankedViaPortal, 1)
    }

    @MainActor
    func testReportedIsolatedEntryPortalOffersOrdinaryPortalHomeOnly() {
        let store = GameStore(io: .temporary(name: "isolated-entry-portal-\(UUID().uuidString)"))
        store.write("plains")
        XCTAssertTrue(store.bindAndDepart())
        if let id = store.state.worlds.pendingWorldArrivalReceiptID {
            XCTAssertTrue(store.enterPendingWorld(arrivalReceiptID: id))
        }
        store.mutate("reproduce older isolated entry frame") { state in
            guard var run = state.worlds.activeRun else { return }
            let entry = run.map.entry
            run.playerPosition = entry
            run.generationDiagnostics.playableEntry = nil
            for neighbour in run.map.neighbours(of: entry) {
                run.map[neighbour].ground = .deepWater
                run.map[neighbour].baseGround = .deepWater
            }
            run.satchel.add(4, of: Resources.ore)
            state.worlds.activeRun = run
        }
        let turns = store.state.worlds.activeRun?.turnsTaken
        XCTAssertTrue(store.canPortalHere)
        XCTAssertFalse(store.canLeaveMalformedOlderWorld)
        store.portalHome()
        XCTAssertNil(store.state.worlds.activeRun)
        XCTAssertEqual(store.state.base.resources[Resources.ore], 4)
        XCTAssertEqual(store.state.worlds.lastExit?.kind, .portal)
        XCTAssertEqual(store.state.worlds.lastExit?.haulKeptFraction, 1)
        XCTAssertEqual(store.state.worlds.lastExit?.turnsTaken, turns)
    }

    @MainActor
    func testLegacyLeaveIsOnlyAvailableWithoutAReachablePortalAndKeepsFullHaul() throws {
        let io = SaveFileIO.temporary(name: "legacy-leave-\(UUID().uuidString)")
        defer { io.deleteEverything() }
        let store = GameStore(io: io)
        store.mutate("avoid recovery subsidy") { $0.base.essence = 1_000 }
        store.write("plains")
        store.bindAndDepart()
        if let id = store.state.worlds.pendingWorldArrivalReceiptID {
            XCTAssertTrue(store.enterPendingWorld(arrivalReceiptID: id))
        }
        store.mutate("make malformed legacy run") { state in
            guard var run = state.worlds.activeRun else { return }
            run.generationDiagnostics.playableEntry = nil
            for point in run.map.allPoints where run.map[point].content.isPortal {
                run.map[point].content = .empty
            }
            run.satchel.add(9, of: Resources.ore)
            state.worlds.activeRun = run
        }
        XCTAssertNil(store.state.worlds.activeRun?.generationDiagnostics.playableEntry)
        XCTAssertNil(store.state.worlds.activeRun?.collapsedOnTurn)
        XCTAssertNil(store.state.worlds.activeRun?.activeEncounter)
        XCTAssertFalse(store.state.worlds.activeRun!.map.allPoints.contains {
            store.state.worlds.activeRun!.map[$0].content.isPortal
        })
        XCTAssertFalse(WorldRules.canReachAPortal(
            from: store.state.worlds.activeRun!.playerPosition,
            in: store.state.worlds.activeRun!.map))
        XCTAssertTrue(store.canLeaveMalformedOlderWorld)
        let trappedRun = try XCTUnwrap(store.state.worlds.activeRun)
        let arrivalReceipt = trappedRun.worldArrivalReceipt
        let historyRecord = try XCTUnwrap(store.state.reality.library.visitedWorlds.last)
        XCTAssertEqual(historyRecord.worldArrivalReceipt, arrivalReceipt)
        let campaignSeed = store.state.worlds.seeds
        let essence = store.state.base.essence
        store.flushNow()
        let cancelledMapBytes = try SaveCodec.makeEncoder().encode(trappedRun.map)
        let relaunched = GameStore(io: io)
        XCTAssertEqual(relaunched.state.worlds.activeRun, trappedRun,
                       "cancelling recovery and relaunching must not repaint or reroll")
        XCTAssertEqual(try SaveCodec.makeEncoder().encode(try XCTUnwrap(
            relaunched.state.worlds.activeRun).map), cancelledMapBytes,
                       "the persisted terrain grid must remain byte-identical")
        XCTAssertEqual(relaunched.state.worlds.activeRun?.map, trappedRun.map)
        XCTAssertEqual(relaunched.state.worlds.activeRun?.worldArrivalReceipt, arrivalReceipt)
        XCTAssertEqual(relaunched.state.reality.library.visitedWorlds.last, historyRecord)
        XCTAssertEqual(relaunched.state.worlds.seeds, campaignSeed)
        XCTAssertEqual(relaunched.state.base.essence, essence)
        XCTAssertTrue(relaunched.canLeaveMalformedOlderWorld)
        relaunched.leaveMalformedOlderWorld()
        XCTAssertNil(relaunched.state.worlds.activeRun)
        XCTAssertEqual(relaunched.state.base.resources[Resources.ore], 9)
        XCTAssertEqual(relaunched.state.worlds.lastExit?.kind, .abandon)
        XCTAssertEqual(relaunched.state.worlds.lastExit?.haulKeptFraction, 1)
        XCTAssertEqual(relaunched.state.worlds.lastExit?.essenceEconomy.bindCostPaid,
                       trappedRun.book.essencePaid)
        let economy = try XCTUnwrap(relaunched.state.worlds.lastExit?.essenceEconomy)
        XCTAssertEqual(economy.antiLockSubsidy, 0, "recovery must not receive a special subsidy")
        XCTAssertEqual(relaunched.state.base.essence,
                       essence + economy.automaticallyRefinedEssence + economy.springYield,
                       "only the ordinary full-return settlement may change Essence")
        XCTAssertEqual(relaunched.state.worlds.seeds, campaignSeed, "recovery must not reroll a world")
        XCTAssertEqual(relaunched.state.reality.library.visitedWorlds.last, historyRecord)
    }

    @MainActor
    func testLegacyLeaveIsSuppressedForReachablePortalAndCurrentCollapse() {
        let store = GameStore(io: .temporary(name: "legacy-leave-negative-\(UUID().uuidString)"))
        store.write("plains")
        store.bindAndDepart()
        if let id = store.state.worlds.pendingWorldArrivalReceiptID {
            XCTAssertTrue(store.enterPendingWorld(arrivalReceiptID: id))
        }
        store.mutate("mark legacy at the return portal") { state in
            state.worlds.activeRun?.generationDiagnostics.playableEntry = nil
            guard let entry = state.worlds.activeRun?.map.entry else { return }
            state.worlds.activeRun?.playerPosition = entry
        }
        XCTAssertTrue(store.canPortalHere)
        XCTAssertFalse(store.canLeaveMalformedOlderWorld)

        store.mutate("collapse without portal") { state in
            guard var run = state.worlds.activeRun else { return }
            for point in run.map.allPoints where run.map[point].content.isPortal {
                run.map[point].content = .empty
            }
            run.collapsedOnTurn = run.turnsTaken
            state.worlds.activeRun = run
        }
        XCTAssertFalse(store.canLeaveMalformedOlderWorld)
    }

    @MainActor
    func testCollapseKeepsOnlyAFractionAndBanksMotesToReality() {
        let store = GameStore(io: .temporary(name: "collapse-\(UUID().uuidString)"))
        store.write("plains")
        store.bindAndDepart()
        if let id = store.state.worlds.pendingWorldArrivalReceiptID {
            XCTAssertTrue(store.enterPendingWorld(arrivalReceiptID: id))
        }
        store.mutate("stock the satchel") { state in
            state.worlds.activeRun?.satchel.add(10, of: Resources.ore)
            state.worlds.activeRun?.satchel.add(4, of: Resources.mote)
        }

        store.endRunWithPartialHaul(reason: "collapse")

        XCTAssertNil(store.state.worlds.activeRun)
        XCTAssertEqual(store.state.base.resources[Resources.ore],
                       Int(10 * Tuning.World.collapseHaulKeptFraction))
        XCTAssertEqual(store.state.reality.motes, Int(4 * Tuning.World.collapseHaulKeptFraction),
                       "Motes bank to Reality, not Base")
        XCTAssertEqual(store.state.reality.lifetime.runsLostToCollapse, 1)
        XCTAssertEqual(store.state.worlds.lastExit?.kind, .collapse)
        XCTAssertEqual(store.state.worlds.lastExit?.lostResources.reduce(0) { $0 + $1.count }, 7,
                       "the recap should list the five ore and two motes that did not return")
    }

    @MainActor
    func testCollapseUsesTheRecoveryFractionFrozenIntoTheRun() {
        let store = GameStore(io: .temporary(name: "collapse-tuning-\(UUID().uuidString)"))
        store.write("plains")
        store.bindAndDepart()
        if let id = store.state.worlds.pendingWorldArrivalReceiptID {
            XCTAssertTrue(store.enterPendingWorld(arrivalReceiptID: id))
        }
        store.mutate("tune this fixture") { state in
            state.worlds.activeRun?.tuning.collapseRecoveryFraction = 1
            state.worlds.activeRun?.satchel.add(10, of: Resources.ore)
        }

        store.endRunWithPartialHaul(reason: "collapse")

        XCTAssertEqual(store.state.base.resources[Resources.ore], 10)
        XCTAssertEqual(store.state.worlds.lastExit?.haulKeptFraction, 1)
        XCTAssertTrue(store.state.worlds.lastExit?.lostResources.isEmpty == true)
    }

    @MainActor
    func testDefeatIsNotCountedAsCollapse() {
        let store = GameStore(io: .temporary(name: "defeat-outcome-\(UUID().uuidString)"))
        store.write("plains")
        store.bindAndDepart()
        if let id = store.state.worlds.pendingWorldArrivalReceiptID {
            XCTAssertTrue(store.enterPendingWorld(arrivalReceiptID: id))
        }

        store.endRunWithPartialHaul(reason: "You were carried home.", kind: .defeat)

        XCTAssertEqual(store.state.worlds.lastExit?.kind, .defeat)
        XCTAssertEqual(store.state.reality.lifetime.runsLostToCollapse, 0)
    }

    func testPartialHaulAlwaysReturnsUnusedStartingItems() {
        var state = GameState.newGame()
        state.base.inventory.stacks = []
        var run = WorldRun(runIndex: 1, book: book([:]), mapSeed: 1, rng: SeededRNG(seed: 1),
                           map: WorldMap(width: 1, height: 1, tiles: [Tile()],
                                         entry: GridPoint(x: 0, y: 0)),
                           playerPosition: GridPoint(x: 0, y: 0))
        var salves = ItemStack(id: InstanceID(rawValue: 10), catalogID: "salve", count: 2)
        salves.protectedReturnCount = 2
        run.satchelItems = Inventory(slots: 4, stacks: [salves])
        var rng = SeededRNG(seed: 3)

        GameStore.bankHaul(of: run, into: &state, fraction: 0, rng: &rng)

        XCTAssertEqual(state.base.inventory.stacks.first { $0.catalogID == "salve" }?.count, 2)
        XCTAssertEqual(state.base.inventory.stacks.first?.protectedReturnCount, 0)
    }

    func testConsumedStartingItemsDoNotDuplicateOnPartialReturn() {
        var state = GameState.newGame()
        state.base.inventory.stacks = []
        var run = WorldRun(runIndex: 1, book: book([:]), mapSeed: 1, rng: SeededRNG(seed: 1),
                           map: WorldMap(width: 1, height: 1, tiles: [Tile()],
                                         entry: GridPoint(x: 0, y: 0)),
                           playerPosition: GridPoint(x: 0, y: 0))
        var salves = ItemStack(id: InstanceID(rawValue: 10), catalogID: "salve", count: 2)
        salves.protectedReturnCount = 2
        _ = salves.removing(1)
        run.satchelItems = Inventory(slots: 4, stacks: [salves])
        var rng = SeededRNG(seed: 3)

        GameStore.bankHaul(of: run, into: &state, fraction: 0, rng: &rng)

        XCTAssertEqual(state.base.inventory.stacks.first { $0.catalogID == "salve" }?.count, 1)
    }

    func testNewLootMergedIntoStartingStackRemainsAtRisk() {
        var state = GameState.newGame()
        state.base.inventory.stacks = []
        var run = WorldRun(runIndex: 1, book: book([:]), mapSeed: 1, rng: SeededRNG(seed: 1),
                           map: WorldMap(width: 1, height: 1, tiles: [Tile()],
                                         entry: GridPoint(x: 0, y: 0)),
                           playerPosition: GridPoint(x: 0, y: 0))
        var salves = ItemStack(id: InstanceID(rawValue: 10), catalogID: "salve", count: 2)
        salves.protectedReturnCount = 2
        run.satchelItems = Inventory(slots: 4, stacks: [salves])
        _ = run.satchelItems.add(ItemStack(id: InstanceID(rawValue: 11), catalogID: "salve", count: 2))
        var rng = SeededRNG(seed: 3)

        let banked = GameStore.bankHaul(of: run, into: &state, fraction: 0, rng: &rng)

        XCTAssertEqual(state.base.inventory.stacks.first { $0.catalogID == "salve" }?.count, 2,
                       "the packed pair returns, while the acquired pair is exposed to loss")
        XCTAssertEqual(banked.lostItems.first { $0.name == "Salve" }?.count, 2)
    }

    /// The pillar, at world scale: a kill mid-run resumes on the same tile of the same map.
    @MainActor
    func testTheWholeMapSurvivesAForceQuit() throws {
        let defaults = UserDefaults.standard
        let priorTuning = defaults.data(forKey: DebugTuningProfile.storageKey)
        defaults.removeObject(forKey: DebugTuningProfile.storageKey)
        defer {
            if let priorTuning {
                defaults.set(priorTuning, forKey: DebugTuningProfile.storageKey)
            } else {
                defaults.removeObject(forKey: DebugTuningProfile.storageKey)
            }
        }
        let io = SaveFileIO.temporary(name: "world-kill-\(UUID().uuidString)")
        defer { io.deleteEverything() }

        let first = GameStore(io: io)
        // Every slot filled. This test is about the map surviving a kill, and a book left partly
        // to chance can roll itself a world that collapses inside these five steps — which fails
        // it for a reason that has nothing to do with persistence.
        first.write("caverns")
        first.write("frostbound")
        first.write("sparse_ore")
        first.write("dim_sky")
        XCTAssertTrue(first.bindAndDepart(), first.bindError ?? "binding failed")
        if let id = first.state.worlds.pendingWorldArrivalReceiptID {
            XCTAssertTrue(first.enterPendingWorld(arrivalReceiptID: id))
        }
        // Wander a bit so fog, position and RNG have all moved off their initial values.
        for _ in 0..<5 {
            guard let run = first.state.worlds.activeRun else { break }
            guard let step = run.map.neighbours(of: run.playerPosition)
                .first(where: { WorldRules.canEnter($0, in: run.map) }) else { break }
            first.step(to: step)
        }
        first.flushNow()
        let before = try XCTUnwrap(first.state.worlds.activeRun)

        let second = GameStore(io: io) // cold launch
        let after = try XCTUnwrap(second.state.worlds.activeRun)

        XCTAssertEqual(after.map, before.map)
        XCTAssertEqual(after.playerPosition, before.playerPosition)
        XCTAssertEqual(after.enemies, before.enemies)
        XCTAssertEqual(after.turnsTaken, before.turnsTaken)
        XCTAssertEqual(after.rng, before.rng)
    }

    /// Pillar 2, stated as a test: nothing advances unless the player acts.
    @MainActor
    func testNothingHappensWithoutAPlayerAction() async throws {
        let store = GameStore(io: .temporary(name: "idle-\(UUID().uuidString)"))
        store.write("gilded_veins") // fastest-decaying symbol we have
        store.bindAndDepart()
        let before = try XCTUnwrap(store.state.worlds.activeRun)

        try await Task.sleep(for: .milliseconds(300))

        let after = try XCTUnwrap(store.state.worlds.activeRun)
        XCTAssertEqual(after.stability, before.stability, "Time passing must not decay a world")
        XCTAssertEqual(after.turnsTaken, before.turnsTaken)
        XCTAssertEqual(after.enemies, before.enemies)
    }

    // MARK: Helpers

    func testAnimalAttendPatientPresenceAndJoinPreserveExactIndividual() throws {
        var state = startedRun(book(["terrain": "plains"]), seed: 14_001)
        state.reality.library.foundTravellers.insert("sabine")
        state.base.stations[Stations.menagerie] = .init(isUnlocked: true, tier: 0)
        var run = try XCTUnwrap(state.worlds.activeRun)
        run.playerPosition = .init(x: 7, y: 7)
        var traits = CreatureTraits()
        traits.sensory.vision = 0; traits.sensory.mechano = 0
        traits.sensory.chemo = 0; traits.sensory.thermo = 0
        let animal = WorldEnemy(id: .init(rawValue: 14_001), speciesID: .init(rawValue: 14_002),
                                traits: traits, position: .init(x: 7, y: 9))
        run.enemies = [animal]
        state.worlds.activeRun = run

        let first = WorldRules.attend(animal.id, in: &state)
        let key = RealityState.AnimalTrustRecordV1.key(
            worldSeed: 14_001, enemyID: animal.id)
        let attended = try XCTUnwrap(state.reality.animalTrustRecords[key])
        XCTAssertEqual(attended.condition, .patientPresence(requiredTurns: 2))
        XCTAssertEqual(attended.progress, 1)
        XCTAssertTrue(first.contains { if case .animalAttended = $0 { true } else { false } })

        let second = WorldRules.advanceTurn(in: &state)
        XCTAssertTrue(state.reality.animalTrustRecords[key]?.completed == true)
        XCTAssertTrue(second.contains { if case .animalTrustCompleted = $0 { true } else { false } })

        let joined = WorldRules.joinAnimal(animal.id, in: &state)
        let tamedID = "tamed:14001:14001"
        let tamed = try XCTUnwrap(state.reality.tamedAnimals[tamedID])
        XCTAssertEqual(tamed.traits, traits)
        XCTAssertEqual(tamed.speciesID, animal.speciesID)
        XCTAssertFalse(state.worlds.activeRun?.enemies.contains(where: { $0.id == animal.id }) ?? true)
        XCTAssertTrue(joined.contains { if case .animalJoined = $0 { true } else { false } })
        XCTAssertEqual(try SaveCodec.decode(SaveCodec.encode(state)), state)
    }

    func testAnimalAttendRefusalsAreAtomicAndRadiusOneStillHasDistanceTwoSolution() throws {
        var state = startedRun(book(["terrain": "plains"]), seed: 14_011)
        state.reality.library.foundTravellers.insert("sabine")
        state.base.stations[Stations.menagerie] = .init(isUnlocked: true, tier: 0)
        var run = try XCTUnwrap(state.worlds.activeRun)
        run.playerPosition = .init(x: 7, y: 7)
        var traits = CreatureTraits()
        traits.sensory.vision = 0; traits.sensory.mechano = 0
        traits.sensory.chemo = 0; traits.sensory.thermo = 0
        let animal = WorldEnemy(id: .init(rawValue: 14_011), traits: traits,
                                position: .init(x: 7, y: 9))
        run.enemies = [animal]
        run.animalsAttackedThisExpedition.insert(animal.id)
        state.worlds.activeRun = run
        let before = state

        let refused = WorldRules.attend(animal.id, in: &state)
        XCTAssertEqual(state, before)
        XCTAssertTrue(refused.contains { if case .blocked(let copy) = $0 {
            copy == WorldRules.AttendRefusal.attackedThisExpedition.copy
        } else { false } })

        state.worlds.activeRun?.animalsAttackedThisExpedition.remove(animal.id)
        _ = WorldRules.attend(animal.id, in: &state)
        let key = RealityState.AnimalTrustRecordV1.key(worldSeed: 14_011, enemyID: animal.id)
        XCTAssertEqual(state.reality.animalTrustRecords[key]?.progress, 1,
                       "the disclosed distance-two floor must work for a radius-one animal")

        state.worlds.activeRun?.playerPosition = .init(x: 7, y: 8)
        _ = WorldRules.advanceTurn(in: &state)
        XCTAssertEqual(state.reality.animalTrustRecords[key]?.progress, 0,
                       "crowding the exact animal resets only its incomplete patience")
        XCTAssertNil(state.reality.animalTrustRecords[key]?.lastProgressTurn)
    }

    func testAnimalUsefulOfferingDefaultsWeakestAndConsumesExactSelectedUnit() throws {
        var state = startedRun(book(["terrain": "plains"]), seed: 14_021)
        state.reality.library.foundTravellers.insert("sabine")
        state.base.stations[Stations.menagerie] = .init(isUnlocked: true, tier: 0)
        var run = try XCTUnwrap(state.worlds.activeRun)
        run.playerPosition = .init(x: 7, y: 7)
        let animal = WorldEnemy(id: .init(rawValue: 14_021), traits: CreatureTraits(),
                                position: .init(x: 7, y: 9))
        run.enemies = [animal]
        let weak = CraftMaterialUnitV1(
            stableUnitID: .init(rawValue: "animal-offer-weak"), domain: .world,
            familyID: .fibre, qualityBand: .standard,
            properties: .init(flexibility: 61),
            sourceReceipt: .worldHarvest(receiptID: "animal-offer-weak"))
        let strong = CraftMaterialUnitV1(
            stableUnitID: .init(rawValue: "animal-offer-strong"), domain: .world,
            familyID: .fibre, qualityBand: .fine,
            properties: .init(flexibility: 88),
            sourceReceipt: .worldHarvest(receiptID: "animal-offer-strong"))
        run.worldMaterialReserve = .init(units: [
            .init(unit: strong), .init(unit: weak)
        ])
        state.worlds.activeRun = run

        _ = WorldRules.attend(animal.id, in: &state)
        let choices = WorldRules.qualifyingOfferings(to: animal.id, in: state)
        XCTAssertEqual(choices.map(\.unitID), [weak.stableUnitID, strong.stableUnitID])
        let completed = WorldRules.offer(try XCTUnwrap(choices.first), to: animal.id, in: &state)
        XCTAssertTrue(completed.contains { if case .animalTrustCompleted = $0 { true } else { false } })
        XCTAssertEqual(state.worlds.activeRun?.worldMaterialReserve.units.map(\.id),
                       [strong.stableUnitID])
    }

    func testPlayerInitiatedAnimalContactMarksExactBodyAndResetsPatienceAtomically() throws {
        var state = startedRun(book(["terrain": "plains"]), seed: 14_031)
        var run = try XCTUnwrap(state.worlds.activeRun)
        let animal = WorldEnemy(id: .init(rawValue: 14_031), traits: CreatureTraits(),
                                creatureID: "paper_moth", position: run.playerPosition)
        run.enemies = [animal]
        let key = RealityState.AnimalTrustRecordV1.key(
            worldSeed: run.mapSeed, enemyID: animal.id)
        state.reality.animalTrustRecords[key] = .init(
            worldSeed: run.mapSeed, enemyID: animal.id, speciesID: nil,
            creatureID: animal.creatureID, traits: CreatureTraits(),
            condition: .patientPresence(requiredTurns: 2), progress: 1,
            firstAttendedRunIndex: run.runIndex, firstAttendedTurn: 0,
            lastProgressTurn: 1, interactionCount: 1, completed: false)
        state.worlds.activeRun = run
        let snapshot = WorldRules.PreContactSnapshot(
            disclosedEnemyIDs: [animal.id], approachedEnemyID: nil,
            playerContactEnemyID: animal.id)

        XCTAssertTrue(WorldRules.beginEncounter(triggeredBy: animal, preContact: snapshot,
                                                runsAutomaticTurns: false, in: &state))
        XCTAssertTrue(state.worlds.activeRun?.animalsAttackedThisExpedition.contains(animal.id) == true)
        XCTAssertEqual(state.reality.animalTrustRecords[key]?.progress, 0)
        XCTAssertNil(state.reality.animalTrustRecords[key]?.lastProgressTurn)
        XCTAssertEqual(try SaveCodec.decode(SaveCodec.encode(state)), state)
    }

    private func startedRun(_ composition: BoundBook, seed: UInt64) -> GameState {
        var state = GameState.newGame()
        let world = Worldgen.generate(book: composition, seed: seed)
        state.worlds.runIndex = 1
        state.worlds.activeRun = WorldRun(
            runIndex: 1,
            book: composition,
            mapSeed: seed,
            rng: SeededRNG(seed: seed).derived(0xA11CE),
            map: world.map,
            playerPosition: world.start,
            enemies: world.enemies
        )
        return state
    }

    /// **Stability is a range, because the world is** (Aimee, 6 Aug).
    ///
    /// The headline counted only what you wrote, which is right — the panel must not reveal rolled
    /// content. But every unwritten subject is rolled at bind, and a rolled focus carries its own
    /// stability delta, its own greed, and its own capacity to contradict what you wrote. Six of
    /// eight unwritten is normal, so the number shown could be off by a lot.
    ///
    /// The design is careful about this everywhere else: **the price is certain, the world is not.**
    func testStabilityIsRangedWhileTheWorldIsUnwritten() {
        var page = Page()
        page.runes = [
            PlacedRune(id: InstanceID(rawValue: 1), content: .target("illumination"),
                       hand: .crude, origin: PageCell(column: 0, row: 0), shapeID: "crude_block"),
            PlacedRune(id: InstanceID(rawValue: 2), content: .source("sun"),
                       hand: .crude, origin: PageCell(column: 2, row: 0), shapeID: "crude_block"),
        ]
        page.links = [MarkLink(InstanceID(rawValue: 1), InstanceID(rawValue: 2))]

        let sparse = BookProjection.project(page: page, seed: 99)
        XCTAssertLessThan(sparse.stabilityScore.lowerBound, sparse.stabilityScore.upperBound,
                          "one subject written of eight and stability is shown as a certainty")
        XCTAssertLessThanOrEqual(sparse.turnsUntilCollapse.lowerBound,
                                 sparse.turnsUntilCollapse.upperBound)
    }

    /// Write every subject and there is nothing left to roll — so the band closes to a point, and
    /// the promise "the price is certain, the world is not" becomes "and you can make it certain".
    func testAFullyWrittenPageIsCertain() {
        var page = Page()
        var next: UInt64 = 1
        let pairs: [(PressureTargetID, PressureSourceID)] = [
            ("illumination", "sun"), ("thermal", "magma"), ("hydrology", "sea"),
            ("substrate", "granite"), ("relief", "granite"), ("vitality", "root"),
            ("atmosphere", "wind"), ("cycle", "moon"),
        ]
        for (index, pair) in pairs.enumerated() {
            page.runes.append(PlacedRune(id: InstanceID(rawValue: next), content: .target(pair.0),
                                         hand: .crude, origin: PageCell(column: 0, row: index),
                                         shapeID: "refined_dot"))
            let target = next
            next += 1
            page.runes.append(PlacedRune(id: InstanceID(rawValue: next), content: .source(pair.1),
                                         hand: .crude, origin: PageCell(column: 1, row: index),
                                         shapeID: "refined_dot"))
            page.links.insert(MarkLink(InstanceID(rawValue: target), InstanceID(rawValue: next)))
            next += 1
        }
        XCTAssertTrue(BookProjection.project(page: page, seed: 7).stabilityScore.isPoint,
                      "nothing left unwritten and the world is still uncertain")
    }

    /// **And writing more narrows the band** — which makes the value of specificity a number for
    /// the first time.
    func testWritingMoreSubjectsNarrowsTheStabilityBand() {
        func band(_ subjects: [(PressureTargetID, PressureSourceID)]) -> Int {
            var page = Page()
            var next: UInt64 = 1
            for (index, pair) in subjects.enumerated() {
                page.runes.append(PlacedRune(id: InstanceID(rawValue: next), content: .target(pair.0),
                                             hand: .crude,
                                             origin: PageCell(column: 0, row: index * 2),
                                             shapeID: "refined_dot"))
                let target = next
                next += 1
                page.runes.append(PlacedRune(id: InstanceID(rawValue: next), content: .source(pair.1),
                                             hand: .crude,
                                             origin: PageCell(column: 1, row: index * 2),
                                             shapeID: "refined_dot"))
                page.links.insert(MarkLink(InstanceID(rawValue: target), InstanceID(rawValue: next)))
                next += 1
            }
            let projection = BookProjection.project(page: page, seed: 4242)
            return projection.stabilityScore.upperBound - projection.stabilityScore.lowerBound
        }

        let one = band([("illumination", "sun")])
        let many = band([("illumination", "sun"), ("thermal", "magma"), ("hydrology", "sea"),
                         ("substrate", "granite"), ("relief", "granite"), ("vitality", "root"),
                         ("atmosphere", "wind"), ("cycle", "moon")])
        XCTAssertLessThan(many, one,
                          "writing every subject left as much uncertainty as writing one")
    }

    func testReportWhatEachFocusCostsNow() {
        let cases: [(PressureSourceID, PressureTargetID)] = [
            ("sun","illumination"), ("gold","substrate"), ("magma","illumination"),
            ("root","vitality"), ("crystal","illumination"), ("sea","hydrology"),
            ("granite","substrate"), ("ice","hydrology"), ("wind","atmosphere"),
            ("salt","vitality"), ("granite","relief"),
        ]
        print("WHAT A FOCUS COSTS (was: sun −25, gold −18, wind +16)")
        for (source, target) in cases {
            let cost = BookRules.greedDelta(for: [Sigil(id: InstanceID(rawValue: 1),
                                                        source: source, target: target)])
            print(String(format: "  %-10s on %-13s %+d", (source.rawValue as NSString).utf8String!,
                         (target.rawValue as NSString).utf8String!, cost))
        }
    }

    func testReportWhatARealBookCostsNow() {
        let books: [(String, [SlotID: SymbolID])] = [
            ("plains · verdant · sparse ore · dim sky",
             ["terrain": "plains", "biome": "verdant", "bounty": "sparse_ore", "quirk": "dim_sky"]),
            ("plains · verdant · rich ore · gilded",
             ["terrain": "plains", "biome": "verdant", "bounty": "rich_ore", "quirk": "gilded_veins"]),
            ("caverns · ashen · rich ore · gilded",
             ["terrain": "caverns", "biome": "ashen", "bounty": "rich_ore", "quirk": "gilded_veins"]),
        ]
        print("WHAT A BOOK SCORES — authored deltas vs emergent greed")
        for (label, symbols) in books {
            let bound = book(symbols)
            let authored = BookRules.dangerTradeDelta(symbolIDs: bound.allSymbolIDs)
            let greed = BookRules.greedDelta(for: BookRules.sigils(for: bound))
            print(String(format: "  %-42s authored %+4d   greed %+4d   score %3d",
                         (label as NSString).utf8String!, authored, greed,
                         BookRules.stabilityScore(delta: authored + greed)))
        }
    }

    /// **A sun is not an outrage** (Aimee, 7 Aug: *"the sun as a focus SHOULD NOT DESTABILIZE SO
    /// MUCH MORE THAN EVERYTHING ELSE WHEN IT IS THE MOST STANDARD SOURCE OF ILLUMINATION IN ANY
    /// WORLD"*).
    ///
    /// Greed was charged against each subject's *baseline*, and four of eight baselines are zero —
    /// so "ordinary" meant pitch dark, and any light at all read as an extravagant demand. A sun
    /// cost −25: more than a vein of gold, and more than half of Rich Ore, whose whole identity is
    /// greed. The meter was teaching that light is reckless and darkness is safe, which is exactly
    /// backwards from the fiction.
    func testASunCostsLessThanAVeinOfGold() {
        func cost(_ source: PressureSourceID, _ target: PressureTargetID) -> Int {
            BookRules.greedDelta(for: [Sigil(id: InstanceID(rawValue: 1),
                                             source: source, target: target)])
        }
        let sun = cost("sun", "illumination")
        let gold = cost("gold", "substrate")
        XCTAssertGreaterThan(sun, gold, "a sunny world is greedier than a gold-veined one")
        XCTAssertGreaterThan(sun, -10, "a plain sun is still being charged like a demand")
    }

    /// **A world resists being asked for more; it does not resist being asked for less.**
    ///
    /// So a barren world is a gift and a teeming one scales — which is the half Aimee described:
    /// *"a barren world increases stability since it's worse than the norm, and a verdant lush
    /// world slowly scales up destabilization."*
    func testAskingForLessThanOrdinaryCalmsAWorld() {
        let teeming = BookRules.greedDelta(for: [
            Sigil(id: InstanceID(rawValue: 1), source: "bloom", target: "vitality", intensity: .great),
            Sigil(id: InstanceID(rawValue: 2), source: "root", target: "vitality", intensity: .great),
        ])
        let barren = BookRules.greedDelta(for: [
            Sigil(id: InstanceID(rawValue: 1), source: "salt", target: "vitality", intensity: .great),
        ])
        XCTAssertLessThan(teeming, 0, "a lush world costs nothing to hold open")
        XCTAssertGreaterThan(barren, 0, "a dead world isn't easier to hold than a living one")
    }

    /// **Wealth is charged heavily; strangeness lightly.** Deviation alone would bill a mountainous
    /// world like a gold-veined one, which is the other half of the fault — greed was supposed to
    /// mean *you asked the world for wealth*, and it meant *you asked the world for anything*.
    func testWealthCostsMoreThanMereStrangeness() {
        func cost(_ source: PressureSourceID, _ target: PressureTargetID) -> Int {
            BookRules.greedDelta(for: [Sigil(id: InstanceID(rawValue: 1), source: source,
                                             target: target, intensity: .great)])
        }
        XCTAssertLessThan(cost("gold", "substrate"), cost("granite", "relief"),
                          "a mountain is billed like a gold seam")
    }

    @MainActor
    func testNaturalAnchorIsAVisibleCheaperRouteToTheSameDurableRealm() throws {
        let blank = book([:])
        var found: (seed: UInt64, map: WorldMap, sites: [PlacedSite], anchor: PlacedSite)?
        for seed in UInt64(1)...200 {
            let world = Worldgen.generate(book: blank, seed: seed)
            if let anchor = world.sites.first(where: { $0.definition?.providesNaturalAnchor == true }) {
                found = (seed, world.map, world.sites, anchor)
                break
            }
        }
        let seeded = try XCTUnwrap(found)
        let store = GameStore(io: .temporary(name: "natural-anchor-\(UUID().uuidString)"))
        store.mutate("stand at an anchor point") { state in
            state.base.stations[Stations.anchorage] = StationState(isUnlocked: true, tier: 0)
            state.base.essence = 100
            state.worlds.runIndex = 1
            state.worlds.activeRun = WorldRun(runIndex: 1, book: blank, mapSeed: seeded.seed,
                                               rng: SeededRNG(seed: seeded.seed), map: seeded.map,
                                               playerPosition: seeded.anchor.position,
                                               sites: seeded.sites)
        }

        XCTAssertNotNil(store.naturalAnchorHere)
        store.refreshWorldFieldContext()
        let beforeContext = try XCTUnwrap(store.worldFieldContext)
        let cost = store.naturalAnchorCost
        XCTAssertEqual(cost, 25, "a blank book's 100-essence born premium makes a 25-essence seam")
        XCTAssertTrue(store.anchorAtNaturalPoint())
        XCTAssertEqual(store.state.base.essence, 100 - cost)
        XCTAssertEqual(store.state.worlds.anchoredRealms.first?.route, .naturalPoint)
        XCTAssertEqual(store.state.worlds.anchoredRealms.first?.world.map, seeded.map)
        let anchoredContext = try XCTUnwrap(store.worldFieldContext)
        XCTAssertNotEqual(anchoredContext.inputStateHash, beforeContext.inputStateHash)
        XCTAssertEqual(anchoredContext.interactionState,
                       .unavailable(reason: "This world is already anchored."))
        XCTAssertFalse(store.anchorAtNaturalPoint(), "one realm cannot be paid for twice")
        XCTAssertEqual(store.worldFieldContext, anchoredContext)
    }

    @MainActor
    func testAnchorFrameOnlyConsumesOnValidOrdinaryGroundAndChargesNoEssence() throws {
        let blank = book([:])
        let generated = Worldgen.generate(book: blank, seed: 404)
        let clear = try XCTUnwrap(generated.map.allPoints.first {
            generated.map[$0].content == .empty && !generated.map[$0].isCrumbled
        })
        var run = WorldRun(runIndex: 1, book: blank, mapSeed: 404, rng: SeededRNG(seed: 404),
                           map: generated.map, playerPosition: generated.map.entry)
        XCTAssertTrue(run.satchelItems.add(ItemStack(id: InstanceID(rawValue: 77),
                                                     catalogID: Items.anchorFrame)))
        let store = GameStore(io: .temporary(name: "anchor-frame-\(UUID().uuidString)"))
        store.mutate("carry frame") { state in
            state.base.stations[Stations.anchorage] = StationState(isUnlocked: true, tier: 0)
            state.base.essence = 63
            state.worlds.activeRun = run
        }

        XCTAssertFalse(store.placeAnchorFrame(), "a portal is not a valid placement tile")
        XCTAssertNotNil(store.carriedAnchorFrame, "an invalid attempt must not consume the frame")
        store.mutate("step onto clear ground") { $0.worlds.activeRun?.playerPosition = clear }
        store.refreshWorldFieldContext()
        let beforeContext = try XCTUnwrap(store.worldFieldContext)

        XCTAssertTrue(store.placeAnchorFrame())
        XCTAssertNil(store.carriedAnchorFrame)
        XCTAssertEqual(store.state.base.essence, 63, "the crafted frame has no second essence cost")
        XCTAssertEqual(store.state.worlds.anchoredRealms.first?.route, .craftedFrame)
        XCTAssertNotEqual(store.worldFieldContext?.inputStateHash, beforeContext.inputStateHash)
    }

    @MainActor
    func testAnchorFrameVisibleRequirementsDeriveFromRecipeNeeds() {
        XCTAssertEqual(AnchorFrameRules.groupedNeeds, [
            .init(property: .hardness, minimum: 65, count: 2),
            .init(property: .density, minimum: 65, count: 2),
            .init(property: .flexibility, minimum: 55, count: 1),
            .init(property: .reactivity, minimum: 65, count: 1),
        ])
        XCTAssertEqual(AnchorFrameRules.groupedNeeds.reduce(0) { $0 + $1.count },
                       AnchorFrameRules.needs.count)
    }

    @MainActor
    func testAnchorFrameRecipeUsesSixDistinctWeakestQualifyingSamples() throws {
        func sample(hardness: Double = 0, density: Double = 0,
                    flexibility: Double = 0, reactivity: Double = 0) -> CraftMaterialUnitV1 {
            CraftMaterialUnitV1(kind: .chitin,
                           properties: MaterialProperties(hardness: hardness, density: density,
                                                          flexibility: flexibility, reactivity: reactivity),
                           grade: max(hardness, density, flexibility, reactivity), source: "test world")
        }
        let store = GameStore(io: .temporary(name: "frame-recipe-\(UUID().uuidString)"))
        store.mutate("stock Anchorage") { state in
            state.base.stations[Stations.anchorage] = StationState(isUnlocked: true, tier: 0)
            state.base.essence = 100
            let samples = [sample(hardness: 65), sample(hardness: 66),
                           sample(density: 65), sample(density: 66),
                           sample(flexibility: 55), sample(reactivity: 65),
                           sample(hardness: 100, density: 100, flexibility: 100, reactivity: 100)]
            state.base.worldMaterialReserve = WorldMaterialReserve(units: samples.enumerated().map { index, sample in
                CraftMaterialHoldingV1(id: .init(rawValue: "anchor-frame-\(index)"), sample: sample)
            })
        }

        XCTAssertTrue(store.craftAnchorFrame())
        XCTAssertEqual(store.state.base.essence, 40)
        XCTAssertEqual(store.state.base.worldMaterialReserve.units.map(\.sample.qualityBand), [.peerless],
                       "weakest qualifying stock should be consumed first")
        XCTAssertEqual(store.state.base.inventory.stacks.first(where: { $0.catalogID == Items.anchorFrame })?.count, 1)
    }

    @MainActor
    func testSustainSettlementSpendsOnlyChosenEssenceAndDormancyNeverDeletes() {
        let blank = book([:])
        let generated = Worldgen.generate(book: blank, seed: 9)
        let run = WorldRun(runIndex: 1, book: blank, mapSeed: 9, rng: SeededRNG(seed: 9),
                           map: generated.map, playerPosition: generated.start)
        let store = GameStore(io: .temporary(name: "sustain-\(UUID().uuidString)"))
        store.mutate("prepare settlement") { state in
            state.base.essence = 40
            state.worlds.anchoredRealms = [
                AnchoredRealm(runIndex: 1, name: "First", route: .bornAnchored, world: run),
                AnchoredRealm(runIndex: 2, name: "Chosen", route: .naturalPoint,
                              sustainObligation: 10, world: run),
                AnchoredRealm(runIndex: 3, name: "Resting", route: .craftedFrame,
                              sustainObligation: 20, assignedCompanions: [0], world: run),
            ]
            state.worlds.pendingAnchorSettlement = true
        }

        XCTAssertFalse(store.settleAnchoredRealms(decisions: [:]),
                       "an untouched settlement must never rest every realm")
        XCTAssertEqual(store.state.base.essence, 40)
        XCTAssertFalse(store.state.worlds.anchoredRealms[2].isDormant)

        XCTAssertTrue(store.settleAnchoredRealms(decisions: [
            2: .sustain,
            3: .letRest,
        ]))
        XCTAssertEqual(store.state.base.essence, 30)
        XCTAssertFalse(store.state.worlds.anchoredRealms[1].isDormant)
        XCTAssertTrue(store.state.worlds.anchoredRealms[2].isDormant)
        XCTAssertTrue(store.state.worlds.anchoredRealms[2].assignedCompanions.isEmpty)
        XCTAssertEqual(store.state.worlds.anchoredRealms.count, 3, "dormancy must never delete a realm")
        XCTAssertTrue(store.reactivateAnchoredRealm(3))
        XCTAssertFalse(store.state.worlds.anchoredRealms[2].isDormant)
    }

    @MainActor
    func testRealmAssignmentIsExclusiveAndProductionIsVisible() {
        let blank = book([:])
        let generated = Worldgen.generate(book: blank, seed: 12)
        let run = WorldRun(runIndex: 1, book: blank, mapSeed: 12, rng: SeededRNG(seed: 12),
                           map: generated.map, playerPosition: generated.start)
        let store = GameStore(io: .temporary(name: "realm-assignment-\(UUID().uuidString)"))
        store.mutate("prepare realms") { state in
            state.worlds.anchoredRealms = [
                AnchoredRealm(runIndex: 1, name: "One", route: .bornAnchored, world: run),
                AnchoredRealm(runIndex: 2, name: "Two", route: .naturalPoint, world: run),
            ]
        }

        XCTAssertTrue(store.assignCompanion(0, toAnchoredRealm: 1))
        XCTAssertFalse(store.state.base.activeParty.contains(0))
        XCTAssertEqual(store.state.worlds.anchoredRealms[0].productionContribution,
                       Tuning.Anchoring.worldworkBaseContribution + store.state.base.roster[0].worldwork)
        XCTAssertTrue(store.assignCompanion(0, toAnchoredRealm: 2))
        XCTAssertTrue(store.state.worlds.anchoredRealms[0].assignedCompanions.isEmpty)
        XCTAssertEqual(store.state.worlds.anchoredRealms[0].productionContribution, 0)
        XCTAssertEqual(store.state.worlds.anchoredRealms[1].assignedCompanions, [0])
    }

    @MainActor
    func testTakingRealmWorkerIsAtomicAndReturningSendsThemHome() throws {
        let blank = book([:])
        let generated = Worldgen.generate(book: blank, seed: 13)
        let run = WorldRun(runIndex: 1, book: blank, mapSeed: 13, rng: SeededRNG(seed: 13),
                           map: generated.map, playerPosition: generated.start)
        let store = GameStore(io: .temporary(name: "realm-party-transfer-\(UUID().uuidString)"))
        store.mutate("prepare worker") { state in
            var worker = CompanionState()
            worker.name = "Worker"
            worker.worldwork = 2
            state.base.roster = [CompanionState(), worker]
            state.base.activeParty = [0]
            state.worlds.anchoredRealms = [
                AnchoredRealm(runIndex: 1, name: "Moss Archive", route: .bornAnchored,
                              sustainObligation: 10, assignedCompanions: [1], world: run),
            ]
            GameStore.recalculateAnchorProduction(in: &state)
        }

        let preview = try XCTUnwrap(store.partyTransferPreview(for: 1))
        XCTAssertEqual(preview.source, .anchoredRealm(id: 1, name: "Moss Archive"))
        XCTAssertEqual(preview.realmProductionBefore, 3)
        XCTAssertEqual(preview.realmProductionAfter, 0)
        XCTAssertEqual(preview.realmShortfallBefore, 7)
        XCTAssertEqual(preview.realmShortfallAfter, 10)

        XCTAssertFalse(store.setComing(1, true, expected: .home), "stale source must not transfer")
        XCTAssertEqual(store.state.worlds.anchoredRealms[0].assignedCompanions, [1])
        XCTAssertEqual(store.setComing(preview), .committed)
        XCTAssertEqual(store.state.base.activeParty, [0, 1])
        XCTAssertTrue(store.state.worlds.anchoredRealms[0].assignedCompanions.isEmpty)
        XCTAssertEqual(store.state.worlds.anchoredRealms[0].productionContribution, 0)

        XCTAssertTrue(store.setComing(1, false, expected: .activeParty))
        XCTAssertEqual(store.placement(of: 1), .home)
        XCTAssertFalse(store.state.base.activeParty.contains(1))
        XCTAssertTrue(store.state.worlds.anchoredRealms[0].assignedCompanions.isEmpty,
                      "returning Home must not restore the old realm posting")
    }

    @MainActor
    func testPartyTransferRefusesWhenDisplayedRealmImpactGoesStale() throws {
        let blank = book([:])
        let generated = Worldgen.generate(book: blank, seed: 13)
        let run = WorldRun(runIndex: 1, book: blank, mapSeed: 13, rng: SeededRNG(seed: 13),
                           map: generated.map, playerPosition: generated.start)
        let store = GameStore(io: .temporary(name: "stale-party-impact-\(UUID().uuidString)"))
        store.mutate("prepare realm worker") { state in
            var worker = CompanionState()
            worker.name = "Worker"
            worker.worldwork = 2
            state.base.roster = [CompanionState(), worker]
            state.base.activeParty = [0]
            state.worlds.anchoredRealms = [
                AnchoredRealm(runIndex: 1, name: "Moss Archive", route: .bornAnchored,
                              sustainObligation: 10, assignedCompanions: [1],
                              world: run)
            ]
            GameStore.recalculateAnchorProduction(in: &state)
        }
        let quote = try XCTUnwrap(store.partyTransferPreview(for: 1))
        store.mutate("change contribution behind confirmation") { state in
            state.base.roster[1].worldwork = 6
            GameStore.recalculateAnchorProduction(in: &state)
        }

        guard case .refused = store.setComing(quote) else {
            return XCTFail("A stale production quote moved the worker")
        }
        XCTAssertEqual(store.placement(of: 1), .anchoredRealm(id: 1, name: "Moss Archive"))
        XCTAssertFalse(store.state.base.activeParty.contains(1))
    }

    @MainActor
    func testTakingHomeKeeperPreviewsAndSuspendsStationBenefit() throws {
        let store = GameStore(io: .temporary(name: "keeper-party-transfer-\(UUID().uuidString)"))
        store.mutate("prepare keeper") { state in
            var keeper = CompanionState()
            keeper.name = "Halloway"
            keeper.traveller = "halloway"
            state.base.roster = [CompanionState(), keeper]
            state.base.activeParty = [0]
            state.base.stations[Stations.blacksmith] = StationState(isUnlocked: true, tier: 0)
        }
        let blacksmith = try XCTUnwrap(ContentCatalog.shared.stations.first { $0.id == Stations.blacksmith })
        XCTAssertTrue(StationStaffingRules.keeperIsHome(for: blacksmith, in: store.state))

        let preview = try XCTUnwrap(store.partyTransferPreview(for: 1))
        XCTAssertEqual(preview.source, .home)
        XCTAssertEqual(preview.stationNames, ["Blacksmith"])
        XCTAssertTrue(store.setComing(1, true, expected: .home))
        XCTAssertFalse(StationStaffingRules.keeperIsHome(for: blacksmith, in: store.state))
    }

    func testLegacyContradictoryPersonPlacementsReconcileDeterministically() throws {
        let blank = book([:])
        let generated = Worldgen.generate(book: blank, seed: 14)
        let run = WorldRun(runIndex: 1, book: blank, mapSeed: 14, rng: SeededRNG(seed: 14),
                           map: generated.map, playerPosition: generated.start)
        var state = GameState.newGame()
        state.base.roster = [CompanionState(), CompanionState(), CompanionState()]
        state.base.activeParty = [1, 1, 99]
        state.worlds.anchoredRealms = [
            AnchoredRealm(runIndex: 2, name: "Later", route: .naturalPoint,
                          assignedCompanions: [0, 1, 2, 2], world: run),
            AnchoredRealm(runIndex: 1, name: "Earlier", route: .bornAnchored,
                          assignedCompanions: [0, 2], world: run),
            AnchoredRealm(runIndex: 3, name: "Dormant", route: .craftedFrame, isDormant: true,
                          assignedCompanions: [0], world: run),
        ]

        let decoded = try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(state))
        XCTAssertEqual(decoded.base.activeParty, [1], "party wins and duplicates/invalid IDs are removed")
        XCTAssertTrue(decoded.worlds.anchoredRealms[0].assignedCompanions.isEmpty)
        XCTAssertEqual(decoded.worlds.anchoredRealms[1].assignedCompanions, [0, 2],
                       "lowest stable realm ID wins a contradictory posting")
        XCTAssertTrue(decoded.worlds.anchoredRealms[2].assignedCompanions.isEmpty)
        XCTAssertEqual(decoded.worlds.anchoredRealms[1].productionContribution, 4)
    }

    private func minimapEvidenceRun() -> WorldRun {
        let grounds = GroundType.allCases
        var tiles = (0..<16).map { index in
            Tile(ground: grounds[index % grounds.count], isRevealed: true)
        }
        tiles[0] = Tile(content: .hazard, ground: .growth, isRevealed: false)
        tiles[1] = Tile(ground: .soil, isRevealed: true, isCrumbled: true)
        tiles[2].content = .hazard
        tiles[3].content = .site(InstanceID(rawValue: 600))
        tiles[4].content = .portal(isEntry: true)
        let map = WorldMap(width: 4, height: 4, tiles: tiles, entry: GridPoint(x: 0, y: 1))
        return WorldRun(runIndex: 1, book: book([:]), mapSeed: 600,
                        rng: SeededRNG(seed: 600), map: map,
                        playerPosition: GridPoint(x: 0, y: 1))
    }

    @MainActor
    private func minimapImage(run: WorldRun, scheme: ColorScheme, size: CGSize) -> UIImage {
        let controller = UIHostingController(rootView:
            MinimapView(run: run).environment(\.colorScheme, scheme)
                .frame(width: size.width, height: size.height))
        let window = UIWindow(frame: CGRect(origin: .zero, size: size))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.frame = window.bounds
        controller.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        let format = UIGraphicsImageRendererFormat(); format.scale = 1
        let image = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
        window.isHidden = true
        return image
    }

    @MainActor
    private func minimapPhoneEvidence(run: WorldRun, scheme: ColorScheme) -> UIImage {
        let view = ZStack {
            (scheme == .dark ? Color(red: 0.05, green: 0.09, blue: 0.09) : Color(white: 0.92))
            VStack(alignment: .leading, spacing: 18) {
                Text("Minimap terrain memory")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                MinimapView(run: run).frame(width: 320, height: 320)
                Text("Hidden · remembered terrain · crumbled · disclosed markers")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                Spacer()
            }
            .foregroundStyle(scheme == .dark ? Color.white : Color.black)
            .padding(.top, 70)
        }
        .environment(\.colorScheme, scheme)
        .frame(width: 368, height: 800)
        let controller = UIHostingController(rootView: view)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 368, height: 800))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.frame = window.bounds
        controller.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        let format = UIGraphicsImageRendererFormat(); format.scale = 1
        let image = UIGraphicsImageRenderer(size: window.bounds.size, format: format).image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
        window.isHidden = true
        return image
    }

    private func nearestNeighbor(_ source: UIImage, size: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat(); format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { output in
            output.cgContext.interpolationQuality = .none
            source.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    private func literalGrayscale(_ source: UIImage) -> UIImage? {
        guard let cgImage = source.cgImage else { return nil }
        let width = cgImage.width, height = cgImage.height
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        guard let context = CGContext(data: &bytes, width: width, height: height,
                                      bitsPerComponent: 8, bytesPerRow: width * 4,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return nil
        }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        for index in stride(from: 0, to: bytes.count, by: 4) {
            let value = UInt8((Int(bytes[index]) * 54 + Int(bytes[index + 1]) * 183
                               + Int(bytes[index + 2]) * 19) / 256)
            bytes[index] = value; bytes[index + 1] = value; bytes[index + 2] = value
        }
        guard let result = context.makeImage() else { return nil }
        return UIImage(cgImage: result)
    }
}
