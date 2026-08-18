import SwiftUI

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
        case .futureIncompatible: "Compatibility details"
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
                message: "Save schema \(schemaVersion) needs a newer Bookbinder build."
            )
        }
        #if DEBUG
        debugVersion = metadata.map { "save schema \($0.saveSchemaVersion)" }
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
    static let ordinarySlotColumnCount = 2
    static let ordinarySlotCardMinimumHeight: CGFloat = 84

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
        guard slotCount > 0 else { return 0 }
        return Int(ceil(Double(slotCount) / Double(ordinarySlotColumnCount)))
    }
}

private enum CampaignShelfPalette {
    static let page = Color(red: 0.92, green: 0.86, blue: 0.72)
    static let pageHighlight = Color(red: 0.98, green: 0.93, blue: 0.82)
    static let ink = Color(red: 0.16, green: 0.12, blue: 0.09)
    static let shelf = Color(red: 0.34, green: 0.22, blue: 0.14)
    static let shelfHighlight = Color(red: 0.57, green: 0.39, blue: 0.23)

    static func cover(for id: UUID) -> Color {
        let index = withUnsafeBytes(of: id.uuid) { Int($0[0]) % 4 }
        return [
            Color(red: 0.68, green: 0.48, blue: 0.28),
            Color(red: 0.36, green: 0.51, blue: 0.49),
            Color(red: 0.54, green: 0.36, blue: 0.43),
            Color(red: 0.42, green: 0.45, blue: 0.31)
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
                campaignContents(compactSlots: true)
                    .padding(16)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
                .foregroundStyle(.secondary)
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
            if let slot = presentation.continueSlot {
                CampaignStartPrimaryAction(title: "Continue", subtitle: slot.name,
                                           icon: "book.pages.fill", emphasized: true,
                                           identifier: "campaign.primary.continue") {
                    onContinue(slot.id)
                }
                .accessibilityHint("Opens the most recently played available campaign")
            }

            CampaignStartPrimaryAction(title: "New Game",
                                       subtitle: "Create a separate campaign",
                                       icon: "plus.rectangle.on.folder",
                                       emphasized: presentation.isEmpty,
                                       identifier: "campaign.primary.new",
                                       action: onNewGame)
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
            .background(emphasized ? Color.accentColor : CampaignShelfPalette.pageHighlight)
            .overlay {
                Rectangle()
                    .stroke(emphasized ? Color.accentColor : CampaignShelfPalette.shelf, lineWidth: 2)
                    .allowsHitTesting(false)
            }
            .shadow(color: CampaignShelfPalette.shelf.opacity(0.45), radius: 0, x: 3, y: 3)
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

struct CampaignStartActionLabel: View {
    let title: String
    let subtitle: String
    let icon: String
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.body.weight(.semibold))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.callout.weight(.semibold))
                Text(subtitle).font(.caption).lineLimit(2)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity,
               minHeight: CampaignStartLayoutPolicy.primaryActionLabelHeight(
                   dynamicTypeSize: dynamicTypeSize
               ),
               maxHeight: CampaignStartLayoutPolicy.primaryActionLabelHeight(
                   dynamicTypeSize: dynamicTypeSize
               ),
               alignment: .leading)
        .contentShape(Rectangle())
    }
}

private struct CampaignSlotCard: View {
    let slot: CampaignSlotSummary
    let compact: Bool
    let onLoad: () -> Void
    let onDetails: () -> Void

    var body: some View {
        if compact { compactBody } else { expandedBody }
    }

    private var compactBody: some View {
        Button(action: slot.health.canLoad ? onLoad : onDetails) {
            VStack(alignment: .leading, spacing: 3) {
                CampaignBookplateMotif(id: slot.id, bookCount: slot.progressBookCount)
                    .frame(height: 20)
                    .accessibilityHidden(true)

                HStack(spacing: 4) {
                    Text(slot.name)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Image(systemName: slot.health.canLoad
                          ? "checkmark.circle" : "exclamationmark.triangle")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(slot.health.canLoad ? Color.secondary : Color.orange)
                        .accessibilityLabel(slot.health.label)
                }

                if slot.hasKnownMetadata {
                    HStack(spacing: 5) {
                        Label("Level \(slot.binderLevel)", systemImage: "figure.stand")
                        Text("·")
                        Text(slot.lastPlayed.formatted(date: .abbreviated, time: .shortened))
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(
                        "Level \(slot.binderLevel), last played \(slot.lastPlayed.formatted(date: .abbreviated, time: .shortened))"
                    )
                }
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity,
                   minHeight: CampaignStartLayoutPolicy.ordinarySlotCardMinimumHeight,
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
        .background(CampaignShelfPalette.cover(for: slot.id))
        .overlay(alignment: .leading) {
            Rectangle().fill(CampaignShelfPalette.pageHighlight.opacity(0.72)).frame(width: 5)
        }
        .overlay(Rectangle().stroke(CampaignShelfPalette.shelf, lineWidth: 2))
        .shadow(color: CampaignShelfPalette.shelf.opacity(0.48), radius: 0, x: 3, y: 3)
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
                .foregroundStyle(slot.health.canLoad ? Color.secondary : Color.orange)

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
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder private var metadata: some View {
        Label("Level \(slot.binderLevel)", systemImage: "figure.stand")
        Label(slot.location, systemImage: "location")
        Text(slot.progression)
        Text(slot.lastPlayed.formatted(date: .abbreviated, time: .shortened))
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
                            .foregroundStyle(.secondary)
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

    private var marks: [Bool] {
        withUnsafeBytes(of: id.uuid) { bytes in
            (0..<max(0, bookCount)).map { index in
                (bytes[index % bytes.count] & UInt8(1 << (index % 4))) != 0
            }
        }
    }

    var body: some View {
        HStack(spacing: 3) {
            ForEach(marks.indices, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(marks[index] ? Color.primary.opacity(0.68) : Color.primary.opacity(0.2))
                    .frame(width: index.isMultiple(of: 3) ? 5 : 3,
                           height: marks[index] ? 28 : 18)
            }
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .bottom) { Rectangle().fill(Color.primary.opacity(0.5)).frame(height: 2) }
    }
}
