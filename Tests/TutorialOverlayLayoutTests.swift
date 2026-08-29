import SwiftUI
import UIKit
import XCTest
@testable import Bookbinder

@MainActor
final class TutorialOverlayLayoutTests: XCTestCase {
    func testHoverPromptDoesNotChangeUnderlyingPhoneOrLargeTextSize() {
        for typeSize in [DynamicTypeSize.large, .accessibility3] {
            let absent = measuredSize(promptVisible: false, typeSize: typeSize)
            let present = measuredSize(promptVisible: true, typeSize: typeSize)
            XCTAssertEqual(present.width, absent.width, accuracy: 0.01)
            XCTAssertEqual(present.height, absent.height, accuracy: 0.01,
                           "A tutorial overlay must not participate in primary layout at \(typeSize)")
        }
    }

    func testLibraryFirstReturnPromptIsOutsideItsScrollGeometry() throws {
        let source = try read("Sources/Screens/LibraryView.swift")
        let scrollStart = try XCTUnwrap(source.range(of: "ScrollView {"))
        let scrollEnd = try XCTUnwrap(source.range(of: ".background(Color(.systemGroupedBackground))"))
        let scrollBody = source[scrollStart.lowerBound..<scrollEnd.lowerBound]
        XCTAssertFalse(scrollBody.contains("firstReturnWriting"),
                       "The Library tutorial must never become a scroll child")
        XCTAssertTrue(source.contains(".tutorialHoverOverlay(isPresented: firstReturnPrompt != nil, alignment: .top)"))
        XCTAssertTrue(source.contains("firstReturnWritingOverlay"))
    }

    func testEveryCurrentTutorialPromptUsesOverlayRatherThanInsetOrInlineContent() throws {
        let presentationSites = [
            "Sources/App/RootView.swift",
            "Sources/Screens/BaseView.swift",
            "Sources/Screens/WritingDeskView.swift",
            "Sources/Screens/WorldView.swift",
            "Sources/Screens/LibraryView.swift",
        ]
        for site in presentationSites {
            XCTAssertTrue(try read(site).contains(".tutorialHoverOverlay"), site)
        }

        let writing = try read("Sources/Screens/WritingDeskView.swift")
        let writingOverlay = try XCTUnwrap(writing.range(of: ".tutorialHoverOverlay(isPresented: tutorialLesson != nil)"))
        let bindInset = try XCTUnwrap(writing.range(of: ".safeAreaInset(edge: .bottom, spacing: 0)"))
        XCTAssertLessThan(writing.distance(from: writing.startIndex, to: writingOverlay.lowerBound),
                          writing.distance(from: writing.startIndex, to: bindInset.lowerBound),
                          "Writing overlay must be applied before the bind-bar inset")

        let root = try read("Sources/App/RootView.swift")
        XCTAssertTrue(root.contains("TutorialRules.definition(.returnPersistenceBoundary)"))
        XCTAssertTrue(root.contains(".tutorialHoverOverlay("))

        let base = try read("Sources/Screens/BaseView.swift")
        XCTAssertTrue(base.contains(".tutorialHoverOverlay(isPresented: showsFirstReturnRouteCard"))
        let primaryStart = try XCTUnwrap(base.range(of: "VStack(spacing: 0) {"))
        let pagerStart = try XCTUnwrap(base.range(of: "ZStack(alignment: .top) {",
                                                  range: primaryStart.upperBound..<base.endIndex))
        XCTAssertFalse(base[primaryStart.upperBound..<pagerStart.lowerBound]
            .contains("firstReturnRouteCard"),
            "Base's transient first-return card must not be a primary-stack child")
        let world = try read("Sources/Screens/WorldView.swift")
        XCTAssertTrue(world.contains(".tutorialHoverOverlay("))
        let carried = try XCTUnwrap(world.range(of: "carriedStrip(presentation)"))
        let worldOverlay = try XCTUnwrap(world.range(
            of: ".tutorialHoverOverlay(", range: carried.upperBound..<world.endIndex))
        let controls = try XCTUnwrap(world.range(
            of: "controls(run)", range: worldOverlay.upperBound..<world.endIndex))
        XCTAssertLessThan(world.distance(from: world.startIndex, to: worldOverlay.lowerBound),
                          world.distance(from: world.startIndex, to: controls.lowerBound),
                          "World overlay must belong to the upper presentation block")
    }

    func testRealWritingOwnerKeepsFramesAndTutorialAboveBindRailThroughAccessibility5() throws {
        for typeSize in supportedTypeSizes {
            let absent = try writingOwnerReceipt(lesson: nil, typeSize: typeSize)
            for lesson in [TutorialLessonID.writingPageRequest, .writingPageSpace, .writingPreview] {
                let present = try writingOwnerReceipt(lesson: lesson, typeSize: typeSize)
                assertFrameParity(absent.frames, present.frames,
                                  context: "Writing \(lesson) \(typeSize)")
                XCTAssertGreaterThan(present.card.width, 0)
                XCTAssertLessThanOrEqual(present.card.width, 344.5)
                XCTAssertLessThanOrEqual(present.card.maxY, present.frames["rail"]!.minY - 7.5,
                                         "Writing tutorial overlaps bind rail at \(typeSize)")
                XCTAssertFalse(present.card.intersects(present.frames["capsule"]!))
                XCTAssertNotNil(present.bindHit, "Bind & Depart must remain hittable at \(typeSize)")
            }
        }
    }

    func testRealWorldOwnerKeepsFramesAndTutorialAboveControlsThroughAccessibility5() throws {
        for typeSize in supportedTypeSizes {
            let absent = try worldOwnerReceipt(lesson: nil, typeSize: typeSize)
            for lesson in [TutorialLessonID.worldNavigation, .worldStability,
                           .worldInteraction, .worldReturn] {
                let present = try worldOwnerReceipt(lesson: lesson, typeSize: typeSize)
                assertFrameParity(absent.frames, present.frames,
                                  context: "World \(lesson) \(typeSize)")
                XCTAssertGreaterThan(present.card.width, 0)
                XCTAssertLessThanOrEqual(present.card.width, 344.5)
                let controls = try XCTUnwrap(present.frames["controls"])
                XCTAssertLessThanOrEqual(present.card.maxY, controls.minY - 7.5,
                                         "World tutorial overlaps controls at \(typeSize)")
                for id in ["direction.0", "direction.1", "direction.2", "direction.3",
                           "minimap", "interact", "look"] {
                    let frame = try XCTUnwrap(present.frames[id], "Missing \(id) at \(typeSize)")
                    XCTAssertFalse(present.card.intersects(frame), "Tutorial overlaps \(id) at \(typeSize)")
                    XCTAssertNotNil(present.controlHits[id], "\(id) must remain hittable at \(typeSize)")
                }
            }
        }
    }

    @MainActor
    func testBasePromptDoesNotMoveContextSectionMapOrDepartureAtPhoneAndAccessibilityText() {
        for typeSize in [DynamicTypeSize.large, .accessibility3] {
            let absent = baseFrames(promptVisible: false, typeSize: typeSize)
            let present = baseFrames(promptVisible: true, typeSize: typeSize)
            XCTAssertEqual(present.underlying, absent.underlying, "Underlying Base geometry moved at \(typeSize)")
            XCTAssertNotNil(present.card)
            XCTAssertNil(absent.card)
            XCTAssertGreaterThan(present.card?.width ?? 0, 44)
            XCTAssertGreaterThan(present.card?.height ?? 0, 44)
        }
    }

    func testAccessibility3PromptIsSafeAreaBoundedAndInternallyScrollable() {
        let lesson = TutorialLessonDefinition(id: .writingPageRequest, group: .writing,
                                              title: "A long but reachable lesson",
                                              body: String(repeating: "Large Text must remain readable and reachable. ", count: 120),
                                              anchorLabel: "Page grid")
        let root = Color.blue
            .frame(width: 390, height: 800)
            .tutorialHoverOverlay(isPresented: true) {
                TutorialCard(lesson: lesson, gotIt: {}, notNow: {})
            }
            .environment(\.dynamicTypeSize, .accessibility3)
        let host = UIHostingController(rootView: root)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 800))
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        host.view.layoutIfNeeded()
        RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        host.view.layoutIfNeeded()

        let scrollViews = descendants(of: host.view).compactMap { $0 as? UIScrollView }
        let bounded = scrollViews.first { $0.contentSize.height > $0.bounds.height + 1 }
        XCTAssertNotNil(bounded, "An oversized Accessibility3 tutorial must scroll internally")
        XCTAssertLessThanOrEqual(bounded?.frame.maxY ?? .infinity, 800.01)
        XCTAssertEqual(TutorialHoverOverlayMetrics.maximumCardHeight(
            containerHeight: 800, safeAreaTop: 59, safeAreaBottom: 34), 691)
    }

    func testTutorialCardKeepsNamedTitleAndBothDismissalActions() throws {
        let source = try read("Sources/Screens/TutorialCard.swift")
        XCTAssertTrue(source.contains("tutorial.title"))
        XCTAssertTrue(source.contains("tutorial.not-now"))
        XCTAssertTrue(source.contains("tutorial.got-it"))
        XCTAssertTrue(source.contains("ScrollView"))
        XCTAssertTrue(source.contains(".scrollBounceBehavior(.basedOnSize)"))
    }

    func testDismissedPromptLeavesNoInvisibleScrollViewAboveGameplay() {
        let lesson = TutorialLessonDefinition(id: .writingPageRequest, group: .writing,
                                              title: "Hidden", body: "Hidden",
                                              anchorLabel: "Hidden")
        let root = Color.blue
            .frame(width: 390, height: 800)
            .tutorialHoverOverlay(isPresented: false) {
                TutorialCard(lesson: lesson, gotIt: {}, notNow: {})
            }
        let host = UIHostingController(rootView: root)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 800))
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        host.view.layoutIfNeeded()

        XCTAssertTrue(descendants(of: host.view).compactMap { $0 as? UIScrollView }.isEmpty,
                      "A dismissed tutorial must leave no invisible scroll view intercepting taps")
    }

    func testReturningFromAWorldClearsHomeNavigationWithoutBreakingAuditLaunch() {
        let pushed: [AppRoute] = [.writingDesk]
        XCTAssertEqual(RootNavigationRules.homePath(afterRunTransitionFrom: true, to: false,
                                                     current: pushed), [])
        XCTAssertEqual(RootNavigationRules.homePath(afterRunTransitionFrom: false, to: true,
                                                     current: pushed), pushed)
        XCTAssertEqual(RootNavigationRules.homePath(afterRunTransitionFrom: false, to: false,
                                                     current: pushed), pushed)
    }

    private func measuredSize(promptVisible: Bool, typeSize: DynamicTypeSize) -> CGSize {
        let lesson = TutorialLessonDefinition(id: .writingPageRequest, group: .writing,
                                              title: "A deliberately long prompt title",
                                              body: String(repeating: "Readable wrapping copy. ", count: 14),
                                              anchorLabel: "Page grid")
        let root = VStack(spacing: 0) {
            Color.blue.frame(width: 320, height: 420)
        }
        .tutorialHoverOverlay(isPresented: promptVisible) {
            if promptVisible { TutorialCard(lesson: lesson, gotIt: {}, notNow: {}) }
        }
        .environment(\.dynamicTypeSize, typeSize)
        let host = UIHostingController(rootView: root)
        return host.sizeThatFits(in: CGSize(width: 390, height: 800))
    }

    private var supportedTypeSizes: [DynamicTypeSize] {
        [.xSmall, .small, .medium, .large, .xLarge, .xxLarge, .xxxLarge,
         .accessibility1, .accessibility2, .accessibility3, .accessibility4, .accessibility5]
    }

    private struct OwnerReceipt {
        var frames: [String: CGRect]
        var card: CGRect
        var bindHit: UIView?
        var controlHits: [String: UIView] = [:]
    }

    @MainActor
    private func writingOwnerReceipt(lesson: TutorialLessonID?, typeSize: DynamicTypeSize) throws
        -> OwnerReceipt {
        let store = GameStore(io: .temporary(name: "writing-owner-\(UUID().uuidString)"))
        for id in TutorialLessonID.allCases { store.completeTutorial(id, fact: "overlay_fixture") }
        store.beginWritingDeskSession()
        XCTAssertTrue(store.write(.target("illumination"), glyph: "illumination",
                                  at: .init(column: 0, row: 0)))
        XCTAssertTrue(store.write(.source("sun"), glyph: "sun",
                                  at: .init(column: 3, row: 3)))
        var frames: [String: CGRect] = [:]
        TutorialHoverOverlayMeasurement.reset()
        let host = UIHostingController(rootView:
            WritingDeskView(debugInitialPane: "The world", debugTutorialLesson: lesson,
                            debugBindRailFrameProbe: { frames[$0] = $1 })
                .environmentObject(store)
                .environment(\.dynamicTypeSize, typeSize))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 368, height: 800))
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        host.additionalSafeAreaInsets = .init(top: 59, left: 0, bottom: 34, right: 0)
        host.view.frame = window.bounds
        host.view.setNeedsLayout(); host.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.08))
        host.view.layoutIfNeeded()
        for id in ["writing.header", "writing.pane-tabs", "writing.causal-review"] {
            if let view = descendants(of: host.view).first(where: { $0.accessibilityIdentifier == id }) {
                frames[id] = view.convert(view.bounds, to: nil)
            }
        }
        let capsule = try XCTUnwrap(frames["capsule"])
        return .init(frames: frames, card: TutorialHoverOverlayMeasurement.cardFrame,
                     bindHit: host.view.hitTest(capsule.center, with: nil))
    }

    @MainActor
    private func worldOwnerReceipt(lesson: TutorialLessonID?, typeSize: DynamicTypeSize) throws
        -> OwnerReceipt {
        let store = GameStore(io: .temporary(name: "world-owner-\(UUID().uuidString)"))
        store.mutate("world overlay fixture") { state in
            state.worlds.activeRun = WorldRun(
                runIndex: 1, book: BoundBook(symbols: [:], randomlyFilled: [], essencePaid: 0),
                mapSeed: 818, rng: SeededRNG(seed: 818),
                map: WorldMap(width: 30, height: 30,
                              tiles: Array(repeating: Tile(), count: 900),
                              entry: .init(x: 15, y: 15)),
                playerPosition: .init(x: 15, y: 15))
        }
        for id in TutorialLessonID.allCases { store.completeTutorial(id, fact: "overlay_fixture") }
        WorldMapStageMeasurement.layoutReceipt = WorldScreenLayoutReceipt()
        TutorialHoverOverlayMeasurement.reset()
        let host = UIHostingController(rootView:
            WorldView(debugTutorialLesson: lesson)
                .environmentObject(store)
                .environment(\.dynamicTypeSize, typeSize))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 368, height: 800))
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        host.additionalSafeAreaInsets = .init(top: 59, left: 0, bottom: 34, right: 0)
        host.view.frame = window.bounds
        host.view.setNeedsLayout(); host.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.08))
        host.view.layoutIfNeeded()
        let receipt = WorldMapStageMeasurement.layoutReceipt
        var frames: [String: CGRect] = [
            "status": receipt.statusFrame, "mapViewport": receipt.mapViewportFrame,
            "mapRendered": receipt.mapRenderedFrame, "carried": receipt.carriedStripFrame,
            "controls": receipt.controlsFrame, "directionPad": receipt.directionPadFrame,
            "minimap": receipt.minimapFrame, "interact": receipt.useTileFrame,
            "look": receipt.lookFrame, "safeContent": receipt.safeContentFrame,
        ]
        for index in receipt.directionButtonFrames.indices {
            frames["direction.\(index)"] = receipt.directionButtonFrames[index]
        }
        var hits: [String: UIView] = [:]
        for id in ["direction.0", "direction.1", "direction.2", "direction.3",
                   "minimap", "interact", "look"] {
            if let frame = frames[id] { hits[id] = host.view.hitTest(frame.center, with: nil) }
        }
        return .init(frames: frames, card: TutorialHoverOverlayMeasurement.cardFrame,
                     bindHit: nil, controlHits: hits)
    }

    private func assertFrameParity(_ lhs: [String: CGRect], _ rhs: [String: CGRect],
                                   context: String, file: StaticString = #filePath,
                                   line: UInt = #line) {
        XCTAssertEqual(Set(lhs.keys), Set(rhs.keys), context, file: file, line: line)
        for key in lhs.keys {
            guard let a = lhs[key], let b = rhs[key] else { continue }
            XCTAssertEqual(a.minX, b.minX, accuracy: 0.5, "\(context) \(key) minX", file: file, line: line)
            XCTAssertEqual(a.minY, b.minY, accuracy: 0.5, "\(context) \(key) minY", file: file, line: line)
            XCTAssertEqual(a.width, b.width, accuracy: 0.5, "\(context) \(key) width", file: file, line: line)
            XCTAssertEqual(a.height, b.height, accuracy: 0.5, "\(context) \(key) height", file: file, line: line)
        }
    }

    @MainActor
    private func baseFrames(promptVisible: Bool, typeSize: DynamicTypeSize)
        -> (underlying: [String: CGRect], card: CGRect?) {
        let store = GameStore(io: .temporary(name: "base-overlay-\(UUID().uuidString)"))
        if promptVisible {
            store.mutate("fixture: present Base route prompt") { state in
                state.tutorial.firstReturnContext = .init(
                    runIndex: 1, route: .writingDesk, reason: .ordinaryReturn, writingID: nil)
                state.tutorial.complete(.returnPersistenceBoundary, fact: "fixture_return")
            }
        }
        let host = UIHostingController(rootView: BaseView()
            .environmentObject(store)
            .environment(\.dynamicTypeSize, typeSize))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        host.view.frame = window.bounds
        host.view.setNeedsLayout()
        host.view.layoutIfNeeded()
        RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        host.view.layoutIfNeeded()

        let ids = ["base-context-row", "base-section-picker", "base-district-pager", "base-departure"]
        let frames = Dictionary(uniqueKeysWithValues: ids.compactMap { id in
            descendants(of: host.view).first(where: { $0.accessibilityIdentifier == id })
                .map { (id, $0.convert($0.bounds, to: host.view)) }
        })
        XCTAssertEqual(frames.count, ids.count)
        let card = descendants(of: host.view)
            .first(where: { $0.accessibilityIdentifier == "base-first-return-route-card" })
            .map { $0.convert($0.bounds, to: host.view) }
        if promptVisible {
            XCTAssertNotNil(descendants(of: host.view)
                .first(where: { $0.accessibilityIdentifier == "base-first-return-open" }))
        }
        return (frames, card)
    }

    private func read(_ relativePath: String) throws -> String {
        try String(contentsOf: projectRoot.appending(path: relativePath), encoding: .utf8)
    }

    private func descendants(of view: UIView) -> [UIView] {
        [view] + view.subviews.flatMap(descendants)
    }

    private var projectRoot: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
    }
}

private extension CGRect {
    var center: CGPoint { CGPoint(x: midX, y: midY) }
}
