import SwiftUI

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
    let receipt: WorldArrivalReceipt

    private var rendered: WorldArrivalRenderedSceneReceipt? { receipt.renderedSceneReceipt }
    private func sceneImage(size: CGSize) -> UIImage? {
        if let splash = receipt.worldSplashReceiptV3,
           let image = WorldArrivalNativeRenderer.placeholderImage(for: splash, size: size) { return image }
        return rendered.flatMap(WorldArrivalNativeRenderer.image(for:))
    }
    private var disclosedMarkLabels: [String] {
        receipt.sourcePagePhysicalReceipt.marks.map {
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

                Button("Enter World") {
                    _ = store.enterPendingWorld(arrivalReceiptID: receipt.id)
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
        }
        .preference(key: DebugBugReporterSuppressedPreferenceKey.self, value: true)
    }

    @ViewBuilder
    private func arrivalContent(sceneWidth: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 14) {
                    Text(receipt.sourcePagePhysicalReceipt.title)
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
                    .accessibilityLabel("Generated view of \(receipt.sourcePagePhysicalReceipt.title)")

                    Text(receipt.finalDescription)
                        .font(.custom("Tiny5", size: 13, relativeTo: .body))
                        .foregroundStyle(PixelUITheme.text)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 12) {
                        WorldArrivalPageThumbnail(page: receipt.sourcePagePhysicalReceipt)
                            .frame(width: 54, height: 54)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("WRITTEN FROM")
                                .font(.custom("Tiny5", size: 9, relativeTo: .caption2))
                                .foregroundStyle(PixelUITheme.muted)
                            Text(receipt.sourcePagePhysicalReceipt.title)
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
                    .accessibilityLabel("Written from \(receipt.sourcePagePhysicalReceipt.title). \(disclosedMarkLabels.joined(separator: ", "))")
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
