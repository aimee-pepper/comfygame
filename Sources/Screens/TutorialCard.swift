import SwiftUI

/// Tutorial help is transient chrome, never page content. `overlay` receives the primary view's
/// resolved size and cannot feed the card's size back into that proposal, so showing a lesson does
/// not resize maps, pages, grids, scroll content, or fixed controls.
extension View {
    func tutorialHoverOverlay<Overlay: View>(alignment: Alignment = .bottom,
                                             @ViewBuilder overlay: () -> Overlay) -> some View {
        self.overlay(alignment: alignment) {
            TutorialHoverOverlayContainer(alignment: alignment, content: overlay())
        }
    }
}

enum TutorialHoverOverlayMetrics {
    static func maximumCardHeight(containerHeight: CGFloat, safeAreaTop: CGFloat,
                                  safeAreaBottom: CGFloat) -> CGFloat {
        max(44, containerHeight - safeAreaTop - safeAreaBottom - 16)
    }
}

private struct TutorialHoverOverlayContainer<Content: View>: View {
    let alignment: Alignment
    let content: Content

    var body: some View {
        GeometryReader { proxy in
            let maximumHeight = TutorialHoverOverlayMetrics.maximumCardHeight(
                containerHeight: proxy.size.height,
                safeAreaTop: proxy.safeAreaInsets.top,
                safeAreaBottom: proxy.safeAreaInsets.bottom
            )
            ZStack(alignment: alignment) {
                Color.clear.allowsHitTesting(false)
                ScrollView {
                    content
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity)
                }
                .scrollBounceBehavior(.basedOnSize)
                .frame(maxWidth: .infinity, maxHeight: maximumHeight, alignment: alignment)
                .padding(.horizontal, 12)
                .padding(.top, proxy.safeAreaInsets.top + 8)
                .padding(.bottom, proxy.safeAreaInsets.bottom + 8)
            }
        }
    }
}

struct TutorialCard: View {
    let lesson: TutorialLessonDefinition
    let gotIt: () -> Void
    let notNow: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(lesson.title).font(.headline)
                .accessibilityIdentifier("tutorial.title")
            Text(lesson.body).font(.subheadline)
            Text(lesson.anchorLabel)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tint)
            HStack {
                Button("Not now", action: notNow)
                    .accessibilityIdentifier("tutorial.not-now")
                Spacer()
                Button("Got it", action: gotIt)
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("tutorial.got-it")
            }
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.tint.opacity(0.35)))
        .shadow(radius: 8, y: 3)
        .accessibilityElement(children: .contain)
    }
}

struct FieldNotesView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        List {
            ForEach(TutorialLessonDefinition.Group.allCases, id: \.self) { group in
                Section(group.rawValue) {
                    ForEach(Array(TutorialRules.definitions.filter { $0.group == group }.enumerated()),
                            id: \.offset) { _, lesson in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(lesson.title).font(.headline)
                            Text(lesson.body).font(.subheadline).foregroundStyle(.secondary)
                            Button("Replay on its screen") { store.replayTutorial(lesson.id) }
                                .font(.caption)
                        }
                        .padding(.vertical, 4)
                    }
                    if group == .worlds {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Reading the minimap").font(.headline)
                            Text("The minimap remembers revealed ground, known routes and landmarks. Empty fog does not tell you what is hidden there.")
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Field Notes")
        .navigationBarTitleDisplayMode(.inline)
    }
}
