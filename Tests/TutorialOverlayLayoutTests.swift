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
        XCTAssertFalse(writing.contains(".safeAreaInset(edge: .bottom)"))

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
