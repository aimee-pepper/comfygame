import SwiftUI

#if DEBUG
@MainActor enum CampaignStartLayoutMeasurement {
    static var headerFrame: CGRect = .zero
    static var shelfFrame: CGRect = .zero
    static var actionFrame: CGRect = .zero
}

private struct CampaignStartLayoutProbe: UIViewRepresentable {
    enum Region { case header, shelf, actions }
    let region: Region

    final class ProbeView: UIView {
        var region: Region = .header
        override func layoutSubviews() {
            super.layoutSubviews()
            guard abs((window?.bounds.width ?? 0) - 368) < 0.5 else { return }
            let frame = convert(bounds, to: nil)
            switch region {
            case .header: CampaignStartLayoutMeasurement.headerFrame = frame
            case .shelf: CampaignStartLayoutMeasurement.shelfFrame = frame
            case .actions: CampaignStartLayoutMeasurement.actionFrame = frame
            }
        }
    }

    func makeUIView(context: Context) -> ProbeView {
        let view = ProbeView(frame: .zero); view.region = region; return view
    }
    func updateUIView(_ uiView: ProbeView, context: Context) { uiView.region = region }
}
#endif

enum CampaignSlotHealth: Equatable, Sendable {
    case valid
    case corrupt(message: String)
    case futureIncompatible(message: String)

    var canLoad: Bool {
        if case .valid = self { true } else { false }
    }

    var label: String {
        switch self {
        case .valid: "Ready"
        case .corrupt: "Needs recovery"
        case .futureIncompatible: "From a newer version"
        }
    }

    var recoveryMessage: String? {
        switch self {
        case .valid: nil
        case .corrupt(let message), .futureIncompatible(let message): message
        }
    }

    var detailsActionLabel: String {
        switch self {
        case .valid: "More"
        case .corrupt: "Recovery details"
        case .futureIncompatible: "Why this save cannot open"
        }
    }
}

/// Lightweight catalogue metadata for the post-loading campaign chooser. The persistence layer
/// will construct these values later; this screen never opens or mutates a save directly.
struct CampaignSlotSummary: Identifiable, Equatable, Sendable {
    let id: UUID
    let name: String
    let lastPlayed: Date
    let binderLevel: Int
    let location: String
    let progression: String
    let progressBookCount: Int
    let health: CampaignSlotHealth
    let debugVersion: String?
    let hasKnownMetadata: Bool

    var deletionDiscriminator: String {
        guard hasKnownMetadata else { return health.label }
        return "\(location) · \(lastPlayed.formatted(date: .abbreviated, time: .omitted))"
    }

    init(descriptor: SaveSlotDescriptor) {
        let metadata = descriptor.metadata
        id = descriptor.id.rawValue
        if let authoredName = metadata?.name {
            name = authoredName
        } else {
            switch descriptor.validity {
            case .futureIncompatible: name = "Campaign from a newer version"
            case .valid, .corrupt: name = "Campaign needing recovery"
            }
        }
        lastPlayed = metadata?.lastPlayedAt ?? .distantPast
        binderLevel = metadata?.binderLevel ?? 0
        location = metadata?.location ?? "Unavailable"
        progression = metadata?.progression ?? "Campaign metadata could not be read"
        progressBookCount = metadata.map {
            min(CampaignShelfProgress.maximumBooks,
                max(CampaignShelfProgress.minimumBooks,
                    $0.progressBookCount ?? CampaignShelfProgress.minimumBooks + max(0, $0.binderLevel - 1) / 2))
        } ?? 0
        hasKnownMetadata = metadata != nil
        switch descriptor.validity {
        case .valid:
            health = .valid
        case .corrupt(let reason):
            health = .corrupt(message: reason)
        case .futureIncompatible(let schemaVersion):
            health = .futureIncompatible(
                message: "This save was created by a newer version of Bookbinder. Update the app to open it."
            )
        }
        #if DEBUG
        debugVersion = metadata.map { "Internal save version \($0.saveSchemaVersion)" }
        #else
        debugVersion = nil
        #endif
    }

    init(id: UUID, name: String, lastPlayed: Date, binderLevel: Int, location: String,
         progression: String, progressBookCount: Int = CampaignShelfProgress.minimumBooks,
         health: CampaignSlotHealth, debugVersion: String?,
         hasKnownMetadata: Bool = true) {
        self.id = id; self.name = name; self.lastPlayed = lastPlayed
        self.binderLevel = binderLevel; self.location = location
        self.progression = progression; self.progressBookCount = progressBookCount
        self.health = health; self.debugVersion = debugVersion
        self.hasKnownMetadata = hasKnownMetadata
    }
}

struct CampaignStartPresentation: Equatable, Sendable {
    let slots: [CampaignSlotSummary]

    init(slots: [CampaignSlotSummary]) {
        self.slots = slots.sorted {
            if $0.lastPlayed != $1.lastPlayed { return $0.lastPlayed > $1.lastPlayed }
            return $0.id.uuidString < $1.id.uuidString
        }
    }

    var continueSlot: CampaignSlotSummary? {
        slots.first(where: { $0.health.canLoad })
    }

    var isEmpty: Bool { slots.isEmpty }

    static func deletionTitle(for slot: CampaignSlotSummary) -> String {
        "Delete “\(slot.name)” — \(slot.deletionDiscriminator)?"
    }
}

enum CampaignStartLayoutPolicy {
    static let ordinarySlotColumnCount = 1
    static let ordinarySlotCardMinimumHeight: CGFloat = 112
    static let ordinaryBottomRailHeight: CGFloat = 84

    static func ordinaryShelfHeight(availableHeight: CGFloat, headerHeight: CGFloat = 62,
                                    bottomRailHeight: CGFloat = ordinaryBottomRailHeight,
                                    verticalPadding: CGFloat = 20,
                                    selectedCampaignHeight: CGFloat = 64) -> CGFloat {
        max(0, availableHeight - headerHeight - bottomRailHeight
            - verticalPadding - selectedCampaignHeight)
    }

    static func primaryActionLabelHeight(dynamicTypeSize: DynamicTypeSize) -> CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 88 : 52
    }

    static func usesSingleColumn(dynamicTypeSize: DynamicTypeSize) -> Bool {
        dynamicTypeSize.isAccessibilitySize
    }

    /// A fresh installation has only New Game, so it owns the whole action row. Once a campaign
    /// can continue, the two equally weighted actions share that same row.
    static func ordinaryPrimaryActionColumnCount(hasContinue: Bool) -> Int {
        hasContinue ? 2 : 1
    }

    static func ordinarySlotRowCount(slotCount: Int) -> Int {
        slotCount
    }
}

private enum CampaignShelfPalette {
    static let page = PixelUITheme.screen
    static let pageHighlight = PixelUITheme.surface
    static let ink = PixelUITheme.text
    static let muted = PixelUITheme.muted
    static let shelf = PixelUITheme.woodDark
    static let shelfWood = PixelUITheme.wood
    static let shelfHighlight = PixelUITheme.woodHighlight

    static func cover(for id: UUID) -> Color {
        let index = withUnsafeBytes(of: id.uuid) { Int($0[0]) % 3 }
        return [
            PixelUITheme.coverOchre,
            PixelUITheme.coverTeal,
            PixelUITheme.coverMauve
        ][index]
    }
}

struct CampaignStartView: View {
    let presentation: CampaignStartPresentation
    let onContinue: (UUID) -> Void
    let onNewGame: () -> Void
    let onLoad: (UUID) -> Void
    let onDelete: (UUID) -> Void
    let onExport: (UUID) -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var deletionCandidate: CampaignSlotSummary?
    @State private var focusedSlot: CampaignSlotSummary?

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                ScrollView { campaignContents(compactSlots: false).padding(16) }
            } else {
                ordinaryCampaignSurface
            }
        }
        .background(CampaignShelfPalette.page)
        .sheet(item: $focusedSlot) { slot in
            CampaignSlotDetail(
                slot: slot,
                onLoad: { focusedSlot = nil; onLoad(slot.id) },
                onExport: { onExport(slot.id) },
                onDelete: { focusedSlot = nil; deletionCandidate = slot }
            )
            .presentationDetents([.medium, .large])
        }
        .alert(deletionCandidate.map(CampaignStartPresentation.deletionTitle) ?? "Delete campaign?",
               isPresented: deletionIsPresented,
               presenting: deletionCandidate) { slot in
            Button("Cancel", role: .cancel) { deletionCandidate = nil }
            Button("Delete “\(slot.name)”", role: .destructive) {
                onDelete(slot.id)
                deletionCandidate = nil
            }
        } message: { slot in
            Text("Only this campaign will be removed. Other campaigns will not be changed.")
        }
    }

    private var ordinaryCampaignSurface: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                Text("Campaigns")
                    .font(.custom("Jersey 10", size: 23))
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Text("\(presentation.slots.count) campaign \(presentation.slots.count == 1 ? "book" : "books")")
                    .font(.custom("Tiny5", size: 8))
                    .foregroundStyle(CampaignShelfPalette.muted)
                    .lineLimit(1)
                    .frame(width: 97, height: 24)
                    .background { Rectangle().fill(CampaignShelfPalette.pageHighlight) }
                    .overlay(Rectangle().stroke(PixelUITheme.edge, lineWidth: 1))
            }
            .frame(height: 62)
            .padding(.leading, 21)
            .padding(.trailing, 14)
            .background {
                LinearGradient(colors: [PixelUITheme.headerB, PixelUITheme.screen],
                               startPoint: .leading, endPoint: .trailing)
            }
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(PixelUITheme.edge)
                    .frame(width: 5)
                    .padding(.leading, 8)
                    .padding(.vertical, 8)
            }
            .overlay(alignment: .bottom) {
                VStack(spacing: 2) {
                    Rectangle().fill(PixelUITheme.edge).frame(height: 2)
                    Rectangle().fill(PixelUITheme.edge.opacity(0.45)).frame(height: 1)
                }
            }
#if DEBUG
            .background(CampaignStartLayoutProbe(region: .header))
#endif

            VStack(spacing: 10) {
                CampaignArchiveShelf {
                    if presentation.slots.isEmpty {
                        emptyShelf
                    } else {
                        VStack(spacing: 8) {
                            ForEach(presentation.slots) { slot in
                                CampaignSlotCard(
                                    slot: slot,
                                    compact: true,
                                    isContinueSlot: slot.id == presentation.continueSlot?.id,
                                    onLoad: { onLoad(slot.id) },
                                    onDetails: { focusedSlot = slot })
                            }
                        }
                    }
                }
                .frame(maxHeight: .infinity)
#if DEBUG
                .background(CampaignStartLayoutProbe(region: .shelf))
#endif

                if let slot = presentation.continueSlot {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 8) {
                            Text("Selected campaign")
                                .font(.custom("Tiny5", size: 9))
                                .textCase(.uppercase)
                            Text(slot.name)
                                .font(.custom("Jersey 10", size: 15))
                                .lineLimit(1)
                            Spacer(minLength: 0)
                        }
                        if presentation.slots.contains(where: { !$0.health.canLoad }) {
                            Text("Older test books open Details; they never load or overwrite.")
                                .font(.custom("Tiny5", size: 9))
                                .textCase(.uppercase)
                                .foregroundStyle(CampaignShelfPalette.muted)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                    }
                    .padding(.horizontal, 10)
                    .frame(minHeight: 54)
                    .background {
                        Rectangle().fill(PixelUITheme.shadow.opacity(0.45)).offset(x: 3, y: 3)
                        Rectangle().fill(PixelUITheme.surface)
                    }
                    .overlay(Rectangle().stroke(PixelUITheme.edge, lineWidth: 2))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            primaryActions
                .padding(.horizontal, 14)
                .padding(.top, 10)
                .padding(.bottom, 20)
                .frame(height: CampaignStartLayoutPolicy.ordinaryBottomRailHeight)
                .background { Rectangle().fill(PixelUITheme.surfaceRaised) }
                .overlay(alignment: .top) {
                    Rectangle().fill(PixelUITheme.edge).frame(height: 2)
                }
#if DEBUG
                .background(CampaignStartLayoutProbe(region: .actions))
#endif
        }
        .foregroundStyle(CampaignShelfPalette.ink)
        .background(CampaignPaperBackground().ignoresSafeArea())
    }

    private var emptyShelf: some View {
        VStack(spacing: 7) {
            Text("▥").font(.system(size: 48, weight: .bold, design: .monospaced))
            Text("Your shelf is waiting").font(.custom("Jersey 10", size: 20))
            Text("Begin a campaign. Each new game keeps its own progress.")
                .font(.callout)
                .foregroundStyle(CampaignShelfPalette.muted)
        }
        .frame(maxWidth: .infinity, minHeight: 360)
    }

    private func campaignContents(compactSlots: Bool) -> some View {
        LazyVStack(alignment: .leading, spacing: compactSlots ? 14 : 20) {
            title
            primaryActions

            if !presentation.slots.isEmpty {
                Text("Load Game")
                    .font(.title2.bold())
                    .accessibilityAddTraits(.isHeader)

                Group {
                    if compactSlots {
                        CampaignShelf {
                            LazyVGrid(columns: slotColumns, spacing: 9) {
                                ForEach(presentation.slots) { slot in
                                    CampaignSlotCard(slot: slot,
                                                     compact: true,
                                                     onLoad: { onLoad(slot.id) },
                                                     onDetails: { focusedSlot = slot })
                                }
                            }
                        }
                    } else {
                        LazyVGrid(columns: slotColumns, spacing: 10) {
                            ForEach(presentation.slots) { slot in
                                CampaignSlotCard(slot: slot,
                                                 compact: false,
                                                 onLoad: { onLoad(slot.id) },
                                                 onDetails: { focusedSlot = slot })
                            }
                        }
                    }
                }
            }
        }
    }

    private var title: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Campaigns").font(.largeTitle.bold())
            Text(presentation.isEmpty
                 ? "Begin a campaign. Each new game keeps its own progress."
                 : "Choose a campaign to continue.")
                .foregroundStyle(CampaignShelfPalette.muted)
        }
    }

    private var primaryActions: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: 10) { primaryActionButtons }
            } else {
                LazyVGrid(columns: ordinaryPrimaryActionColumns, spacing: 10) {
                    primaryActionButtons
                }
            }
        }
    }

    private var ordinaryPrimaryActionColumns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: 10),
            count: CampaignStartLayoutPolicy.ordinaryPrimaryActionColumnCount(
                hasContinue: presentation.continueSlot != nil
            )
        )
    }

    @ViewBuilder private var primaryActionButtons: some View {
            CampaignStartPrimaryAction(title: "New Game",
                                       subtitle: "",
                                       icon: "plus.rectangle.on.folder",
                                       emphasized: presentation.isEmpty,
                                       identifier: "campaign.primary.new",
                                       action: onNewGame)

            if let slot = presentation.continueSlot {
                CampaignStartPrimaryAction(title: "Continue \(slot.name)", subtitle: "",
                                           icon: "book.pages.fill", emphasized: true,
                                           identifier: "campaign.primary.continue") {
                    onContinue(slot.id)
                }
                .accessibilityHint("Opens the most recently played available campaign")
            }
    }

    private var slotColumns: [GridItem] {
        if CampaignStartLayoutPolicy.usesSingleColumn(dynamicTypeSize: dynamicTypeSize) {
            [GridItem(.flexible())]
        } else {
            Array(repeating: GridItem(.flexible(), spacing: 10),
                  count: CampaignStartLayoutPolicy.ordinarySlotColumnCount)
        }
    }

    private var deletionIsPresented: Binding<Bool> {
        Binding(get: { deletionCandidate != nil }, set: { presented in
            if !presented { deletionCandidate = nil }
        })
    }
}

struct CampaignStartPrimaryAction: View {
    let title: String
    let subtitle: String
    let icon: String
    let emphasized: Bool
    let identifier: String
    let action: () -> Void

    var body: some View {
        button
            .buttonStyle(.plain)
            .foregroundStyle(emphasized ? Color.white : CampaignShelfPalette.ink)
            .background {
                Rectangle().fill(CampaignShelfPalette.shelf.opacity(0.45)).offset(x: 3, y: 3)
                Rectangle().fill(emphasized ? PixelUITheme.primary : CampaignShelfPalette.pageHighlight)
            }
            .overlay {
                Rectangle()
                    .stroke(emphasized ? PixelUITheme.primaryHighlight : CampaignShelfPalette.shelf,
                            lineWidth: 2)
                    .allowsHitTesting(false)
            }
        .frame(maxWidth: .infinity)
    }

    private var button: some View {
        Button(action: action) {
            CampaignStartActionLabel(title: title, subtitle: subtitle, icon: icon)
        }
        .accessibilityIdentifier(identifier)
    }
}

private struct CampaignShelf<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            Rectangle().fill(CampaignShelfPalette.shelfHighlight).frame(height: 7)
            content.padding(9)
            Rectangle().fill(CampaignShelfPalette.shelf).frame(height: 11)
        }
        .background(CampaignShelfPalette.shelf.opacity(0.16))
        .overlay(Rectangle().stroke(CampaignShelfPalette.shelf, lineWidth: 2))
        .shadow(color: CampaignShelfPalette.shelf.opacity(0.42), radius: 0, x: 3, y: 4)
    }
}

private struct CampaignArchiveShelf<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        ZStack(alignment: .topLeading) {
            HStack(spacing: 0) {
                ForEach(0..<18, id: \.self) { index in
                    Rectangle()
                        .fill(index.isMultiple(of: 3)
                              ? CampaignShelfPalette.shelfHighlight
                              : CampaignShelfPalette.shelfWood)
                }
            }
            Text("ARCHIVE SHELF")
                .font(.custom("Tiny5", size: 8))
                .tracking(2)
                .foregroundStyle(PixelUITheme.shelfInscription)
                .padding(.leading, 12)
                .padding(.top, 6)

            ScrollView {
                content.padding(.horizontal, 12).padding(.vertical, 4)
            }
            .scrollIndicators(.hidden)
            .contentMargins(.top, 24, for: .scrollContent)
            .contentMargins(.bottom, 18, for: .scrollContent)
        }
        .overlay(alignment: .top) { Rectangle().fill(CampaignShelfPalette.shelfHighlight).frame(height: 4) }
        .overlay(alignment: .bottom) { Rectangle().fill(CampaignShelfPalette.shelf).frame(height: 9) }
        .overlay(Rectangle().stroke(CampaignShelfPalette.shelf, lineWidth: 3))
        .background {
            Rectangle().fill(PixelUITheme.shadow.opacity(0.65)).offset(x: 5, y: 5)
        }
        .accessibilityIdentifier("campaign.archive-shelf")
    }
}

private struct CampaignPaperBackground: View {
    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(PixelUITheme.screen))
            var grid = Path()
            stride(from: CGFloat(0), through: size.width, by: 8).forEach { x in
                grid.move(to: CGPoint(x: x, y: 0)); grid.addLine(to: CGPoint(x: x, y: size.height))
            }
            stride(from: CGFloat(0), through: size.height, by: 8).forEach { y in
                grid.move(to: CGPoint(x: 0, y: y)); grid.addLine(to: CGPoint(x: size.width, y: y))
            }
            context.stroke(grid, with: .color(PixelUITheme.edge.opacity(0.08)), lineWidth: 0.5)
        }
        .allowsHitTesting(false)
    }
}

struct CampaignStartActionLabel: View {
    let title: String
    let subtitle: String
    let icon: String
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Text(title)
            .font(.custom("Tiny5", size: 11))
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity,
               minHeight: CampaignStartLayoutPolicy.primaryActionLabelHeight(
                   dynamicTypeSize: dynamicTypeSize
               ),
               maxHeight: CampaignStartLayoutPolicy.primaryActionLabelHeight(
                   dynamicTypeSize: dynamicTypeSize
               ),
               alignment: .center)
        .contentShape(Rectangle())
        .clipShape(.rect(cornerRadii: RectangleCornerRadii(topLeading: 4, bottomLeading: 4,
                                                            bottomTrailing: 4, topTrailing: 4)))
    }
}

private struct CampaignSlotCard: View {
    let slot: CampaignSlotSummary
    let compact: Bool
    var isContinueSlot = false
    let onLoad: () -> Void
    let onDetails: () -> Void

    var body: some View {
        if compact { compactBody } else { expandedBody }
    }

    private var compactBody: some View {
        Button(action: slot.health.canLoad ? onLoad : onDetails) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .bottom, spacing: 7) {
                    CampaignBookplateMotif(id: slot.id, bookCount: slot.progressBookCount)
                        .frame(height: 34)
                        .accessibilityHidden(true)
                    Spacer(minLength: 0)
                    CampaignSlotStatusBadge(slot: slot)
                }
                .padding(.bottom, 4)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(CampaignShelfPalette.shelf.opacity(0.65)).frame(height: 1)
                }

                Text(slot.name)
                    .font(.custom("Jersey 10", size: 16))
                    .lineLimit(1)
                    .padding(.top, 4)

                if slot.hasKnownMetadata {
                    HStack(spacing: 4) {
                        Text("Level \(slot.binderLevel)")
                        Spacer(minLength: 4)
                        Text(slot.location)
                    }
                    .font(.custom("Tiny5", size: 9))
                    .lineLimit(1)

                    HStack(spacing: 4) {
                        Text(CampaignShelfProgress.volumeLabel(for: slot.progressBookCount))
                        Spacer(minLength: 4)
                        Text(slot.lastPlayed.formatted(date: .abbreviated, time: .shortened))
                    }
                    .font(.custom("Tiny5", size: 9))
                    .foregroundStyle(CampaignShelfPalette.muted)
                    .lineLimit(1)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(
                        "Level \(slot.binderLevel), \(slot.location), \(CampaignShelfProgress.volumeLabel(for: slot.progressBookCount)), last played \(slot.lastPlayed.formatted(date: .abbreviated, time: .shortened))"
                    )
                }

            }
            .padding(.leading, 10)
            .padding(.trailing, 36)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity,
                   minHeight: CampaignStartLayoutPolicy.ordinarySlotCardMinimumHeight,
                   maxHeight: CampaignStartLayoutPolicy.ordinarySlotCardMinimumHeight,
                   alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("campaign.slot.\(slot.id.uuidString).\(slot.health.canLoad ? "load" : "details")")
        .accessibilityHint(slot.health.canLoad
                           ? "Double tap to load. Touch and hold for details."
                           : "Opens recovery details.")
        .accessibilityAction(named: "Details", onDetails)
        .contextMenu {
            Button("Details", systemImage: "info.circle", action: onDetails)
        }
        .foregroundStyle(CampaignShelfPalette.ink)
        .background {
            Rectangle().fill(PixelUITheme.shadow.opacity(0.7)).offset(x: 4, y: 5)
            Rectangle().fill(CampaignShelfPalette.cover(for: slot.id))
        }
        .overlay {
            Rectangle().inset(by: 5).stroke(CampaignShelfPalette.shelf.opacity(0.55), lineWidth: 1)
                .allowsHitTesting(false)
        }
        .overlay(alignment: .bottomTrailing) {
            Text(isContinueSlot ? "◆" : slot.health.canLoad ? "◇" : "×")
                .font(.custom("Tiny5", size: 12))
                .foregroundStyle(CampaignShelfPalette.shelf)
                .frame(width: 23, height: 23)
                .background(PixelUITheme.clasp)
                .overlay(Rectangle().stroke(CampaignShelfPalette.shelf, lineWidth: 2))
                .padding(7)
        }
        .overlay(Rectangle().stroke(CampaignShelfPalette.shelf, lineWidth: 3))
        .overlay {
            if isContinueSlot {
                Rectangle().stroke(PixelUITheme.clasp, lineWidth: 3).padding(-3)
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var expandedBody: some View {
        VStack(alignment: .leading, spacing: 10) {
            CampaignBookplateMotif(id: slot.id, bookCount: slot.progressBookCount)
                .frame(height: 42)
                .accessibilityHidden(true)

            Text(slot.name).font(.headline).lineLimit(2)
            Label(slot.health.label,
                  systemImage: slot.health.canLoad ? "checkmark.circle" : "exclamationmark.triangle")
                .font(.caption.weight(.semibold))
                .foregroundStyle(slot.health.canLoad ? CampaignShelfPalette.muted : PixelUITheme.danger)

            if slot.hasKnownMetadata {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) { metadata }
                    VStack(alignment: .leading, spacing: 4) { metadata }
                }
            }

            HStack(spacing: 8) {
                if slot.health.canLoad {
                    Button("Load", action: onLoad)
                        .buttonStyle(.borderedProminent)
                        .frame(minHeight: 44)
                }
                Spacer(minLength: 4)
                Button(slot.health.detailsActionLabel, action: onDetails)
                    .buttonStyle(.bordered)
                    .frame(minHeight: 44)
            }
            .controlSize(.regular)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PixelUITheme.surfaceRaised, in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder private var metadata: some View {
        Label("Level \(slot.binderLevel)", systemImage: "figure.stand")
        Label(slot.location, systemImage: "location")
        Text(slot.progression)
        Text(slot.lastPlayed.formatted(date: .abbreviated, time: .shortened))
    }
}

private struct CampaignSlotStatusBadge: View {
    let slot: CampaignSlotSummary

    var body: some View {
        Text(slot.health.label.uppercased())
            .font(.custom("Tiny5", size: 8))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .foregroundStyle(slot.health.canLoad
                             ? CampaignShelfPalette.ink.opacity(0.74) : PixelUITheme.danger)
            .padding(.horizontal, 5)
            .padding(.vertical, 3)
            .background(CampaignShelfPalette.pageHighlight)
            .overlay(Rectangle().stroke(CampaignShelfPalette.shelf.opacity(0.55), lineWidth: 1))
    }
}

private struct CampaignSlotDetail: View {
    let slot: CampaignSlotSummary
    let onLoad: () -> Void
    let onExport: () -> Void
    let onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    CampaignBookplateMotif(id: slot.id, bookCount: slot.progressBookCount)
                        .frame(height: 58)
                        .accessibilityHidden(true)
                    Text(slot.name).font(.title2.bold())
                    if slot.hasKnownMetadata {
                        Label("Level \(slot.binderLevel)", systemImage: "figure.stand")
                        Label(slot.location, systemImage: "location")
                        Text(slot.progression)
                        Text("Last played \(slot.lastPlayed.formatted(date: .abbreviated, time: .shortened))")
                            .foregroundStyle(CampaignShelfPalette.muted)
                    }
                    if let message = slot.health.recoveryMessage {
                        Label(message, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                    }
                }

                Section("Actions") {
                    if slot.health.canLoad { Button("Load campaign", action: onLoad) }
                    Button("Export unchanged recovery file", action: onExport)
                    Button("Delete this campaign", role: .destructive, action: onDelete)
                }

                #if DEBUG
                if let version = slot.debugVersion {
                    Section("Technical details") {
                        Text(version).font(.caption.monospaced())
                        Text(slot.id.uuidString).font(.caption2.monospaced())
                    }
                }
                #endif
            }
            .navigationTitle("Campaign details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismiss() }
            } }
        }
    }
}

private struct CampaignBookplateMotif: View {
    let id: UUID
    let bookCount: Int

    var body: some View {
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(0..<max(0, bookCount), id: \.self) { index in
                ZStack(alignment: .bottom) {
                    Rectangle()
                        .fill(volumeColor(index))
                        .overlay(alignment: .leading) {
                            Rectangle().fill(Color.white.opacity(0.28)).frame(width: 2)
                        }
                        .overlay(Rectangle().stroke(CampaignShelfPalette.shelf, lineWidth: 2))
                    Text("\(index + 1)")
                        .font(.custom("Tiny5", size: 6))
                        .foregroundStyle(CampaignShelfPalette.shelf)
                        .padding(.bottom, 2)
                }
                .frame(width: 12, height: CGFloat([24, 28, 32][index % 3]))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
    }

    private func volumeColor(_ index: Int) -> Color {
        switch index % 3 {
        case 0: PixelUITheme.neutralHighlight
        case 1: PixelUITheme.danger.opacity(0.78)
        default: PixelUITheme.primary.opacity(0.78)
        }
    }
}

extension CampaignShelfProgress {
    static func volumeLabel(for count: Int) -> String {
        "\(count) \(count == 1 ? "volume" : "volumes")"
    }
}
