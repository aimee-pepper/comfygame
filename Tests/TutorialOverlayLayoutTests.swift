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
        XCTAssertTrue(source.contains(".tutorialHoverOverlay(alignment: .top)"))
        XCTAssertTrue(source.contains("firstReturnWritingOverlay"))
    }

    func testEveryCurrentTutorialPromptUsesOverlayRatherThanInsetOrInlineContent() throws {
        let writing = try read("Sources/Screens/WritingDeskView.swift")
        XCTAssertTrue(writing.contains(".tutorialHoverOverlay"))
        XCTAssertFalse(writing.contains(".safeAreaInset(edge: .bottom)"))

        let root = try read("Sources/App/RootView.swift")
        XCTAssertTrue(root.contains("TutorialRules.definition(.returnPersistenceBoundary)"))
        XCTAssertTrue(root.contains(".tutorialHoverOverlay(alignment: .top)"))

        let base = try read("Sources/Screens/BaseView.swift")
        XCTAssertTrue(base.contains(".overlay(alignment: .top)"))
        let world = try read("Sources/Screens/WorldView.swift")
        XCTAssertTrue(world.contains(".overlay(alignment: .bottom)"))
    }

    func testAccessibility3PromptIsSafeAreaBoundedAndInternallyScrollable() {
        let lesson = TutorialLessonDefinition(id: .writingPageRequest, group: .writing,
                                              title: "A long but reachable lesson",
                                              body: String(repeating: "Large Text must remain readable and reachable. ", count: 120),
                                              anchorLabel: "Page grid")
        let root = Color.blue
            .frame(width: 390, height: 800)
            .tutorialHoverOverlay {
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

    private func measuredSize(promptVisible: Bool, typeSize: DynamicTypeSize) -> CGSize {
        let lesson = TutorialLessonDefinition(id: .writingPageRequest, group: .writing,
                                              title: "A deliberately long prompt title",
                                              body: String(repeating: "Readable wrapping copy. ", count: 14),
                                              anchorLabel: "Page grid")
        let root = VStack(spacing: 0) {
            Color.blue.frame(width: 320, height: 420)
        }
        .tutorialHoverOverlay {
            if promptVisible { TutorialCard(lesson: lesson, gotIt: {}, notNow: {}) }
        }
        .environment(\.dynamicTypeSize, typeSize)
        let host = UIHostingController(rootView: root)
        return host.sizeThatFits(in: CGSize(width: 390, height: 800))
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
