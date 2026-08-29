import SwiftUI

#if DEBUG
@MainActor enum TutorialHoverOverlayMeasurement {
    static var ownerFrame: CGRect = .zero
    static var cardFrame: CGRect = .zero
    static func reset() { ownerFrame = .zero; cardFrame = .zero }
}

private struct TutorialHoverFrameProbe: UIViewRepresentable {
    enum Kind { case owner, card }
    let kind: Kind
    final class ProbeView: UIView {
        var kind: Kind = .owner
        override func layoutSubviews() {
            super.layoutSubviews()
            let frame = convert(bounds, to: nil)
            switch kind {
            case .owner: TutorialHoverOverlayMeasurement.ownerFrame = frame
            case .card: TutorialHoverOverlayMeasurement.cardFrame = frame
            }
        }
    }
    func makeUIView(context: Context) -> ProbeView {
        let view = ProbeView(frame: .zero); view.kind = kind; return view
    }
    func updateUIView(_ uiView: ProbeView, context: Context) { uiView.kind = kind }
}
#endif

/// Tutorial help is transient chrome, never page content. `overlay` receives the primary view's
/// resolved size and cannot feed the card's size back into that proposal, so showing a lesson does
/// not resize maps, pages, grids, scroll content, or fixed controls.
extension View {
    func tutorialHoverOverlay<Overlay: View>(isPresented: Bool,
                                             alignment: Alignment = .bottom,
                                             @ViewBuilder overlay: () -> Overlay) -> some View {
        self.overlay(alignment: alignment) {
            if isPresented {
                TutorialHoverOverlayContainer(alignment: alignment, content: overlay())
            }
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
                ViewThatFits(in: .vertical) {
                    // Keep an ordinary prompt's hit region to the card itself. A permanently
                    // full-height ScrollView used to sit invisibly above the whole screen and
                    // swallow controls outside the card — including Bind & Depart.
                    content
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity)
#if DEBUG
                        .background(TutorialHoverFrameProbe(kind: .card))
#endif

                    // Only oversized accessibility content becomes internally scrollable.
                    ScrollView {
                        content
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity)
                    }
                    .scrollBounceBehavior(.basedOnSize)
#if DEBUG
                    .background(TutorialHoverFrameProbe(kind: .card))
#endif
                }
                .frame(maxWidth: .infinity, maxHeight: maximumHeight, alignment: alignment)
                .padding(.horizontal, 12)
                .padding(.top, proxy.safeAreaInsets.top + 8)
                .padding(.bottom, proxy.safeAreaInsets.bottom + 8)
            }
#if DEBUG
            .background(TutorialHoverFrameProbe(kind: .owner))
#endif
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
        .accessibilityIdentifier("tutorial.card")
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
