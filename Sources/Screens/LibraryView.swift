import SwiftUI

#if DEBUG
@MainActor enum P2SafeSpaceMeasurement {
    static var isArmed = false
    static var libraryPickerFrame: CGRect = .zero
    static var libraryScrollFrame: CGRect = .zero
    static var libraryContentFrame: CGRect = .zero
    static var partyScrollFrame: CGRect = .zero
    static var partyContentFrame: CGRect = .zero
    static var historyScrollFrame: CGRect = .zero
    static var historyContentFrame: CGRect = .zero
    static var historyFooterFrame: CGRect = .zero
    static var librarySemanticFrames: [String: CGRect] = [:]
    static var librarySemanticIDs: [String: String] = [:]

    static func reset() {
        libraryPickerFrame = .zero
        libraryScrollFrame = .zero
        libraryContentFrame = .zero
        partyScrollFrame = .zero
        partyContentFrame = .zero
        historyScrollFrame = .zero
        historyContentFrame = .zero
        historyFooterFrame = .zero
        librarySemanticFrames = [:]
        librarySemanticIDs = [:]
    }
}

struct P2SafeSpaceProbe: View {
    enum Region {
        case libraryPicker, libraryScroll, libraryContent
        case partyScroll, partyContent
        case historyScroll, historyContent, historyFooter
    }
    let region: Region

    var body: some View {
        GeometryReader { proxy in
            let frame = proxy.frame(in: .global)
            Color.clear
                .onAppear { record(frame) }
                .onChange(of: frame) { _, value in record(value) }
        }
    }

    private func record(_ frame: CGRect) {
        guard P2SafeSpaceMeasurement.isArmed else { return }
        switch region {
        case .libraryPicker: P2SafeSpaceMeasurement.libraryPickerFrame = frame
        case .libraryScroll: P2SafeSpaceMeasurement.libraryScrollFrame = frame
        case .libraryContent: P2SafeSpaceMeasurement.libraryContentFrame = frame
        case .partyScroll: P2SafeSpaceMeasurement.partyScrollFrame = frame
        case .partyContent: P2SafeSpaceMeasurement.partyContentFrame = frame
        case .historyScroll: P2SafeSpaceMeasurement.historyScrollFrame = frame
        case .historyContent: P2SafeSpaceMeasurement.historyContentFrame = frame
        case .historyFooter: P2SafeSpaceMeasurement.historyFooterFrame = frame
        }
    }
}

struct P2LibrarySemanticProbe: View {
    let slot: String
    let identity: String

    var body: some View {
        GeometryReader { proxy in
            let frame = proxy.frame(in: .global)
            Color.clear
                .onAppear { record(frame) }
                .onChange(of: frame) { _, value in record(value) }
        }
        .allowsHitTesting(false)
    }

    private func record(_ frame: CGRect) {
        guard P2SafeSpaceMeasurement.isArmed else { return }
        P2SafeSpaceMeasurement.librarySemanticFrames[slot] = frame
        P2SafeSpaceMeasurement.librarySemanticIDs[slot] = identity
    }
}
#endif

enum LibraryPresentation {
    static func placementLabel(for traveller: TravellerDef, in state: GameState) -> String {
        guard state.reality.library.foundTravellers.contains(traveller.id) else {
            return traveller.calling.capitalized
        }
        guard let index = state.base.roster.firstIndex(where: { $0.traveller == traveller.id }) else {
            return "Recruited"
        }
        switch RosterPlacementRules.placement(of: index, in: state) {
        case .home: return "At Home"
        case .activeParty: return "With you"
        case .anchoredRealm(_, let name): return "At \(name)"
        }
    }

    static func diaries(in library: LibraryState) -> [TravellerDef] {
        let recoveredAuthors = Set(library.foundPages.compactMap {
            ContentCatalog.shared.diaryPage($0)?.diary
        })
        return ContentCatalog.shared.travellersInAuthoredOrder.filter { recoveredAuthors.contains($0.id) }
    }

    static func people(in library: LibraryState) -> [TravellerDef] {
        let recoveredAuthors = Set(library.foundPages.compactMap {
            ContentCatalog.shared.diaryPage($0)?.diary
        })
        let recoveredSubjects = Set(library.foundPages.compactMap {
            ContentCatalog.shared.diaryPage($0)?.about
        })
        let visible = library.knownTravellers
            .union(library.foundTravellers)
            .union(recoveredAuthors)
            .union(recoveredSubjects)
        return ContentCatalog.shared.travellersInAuthoredOrder.filter { visible.contains($0.id) }
    }

    static func pages(by traveller: TravellerID, in library: LibraryState) -> [DiaryPageDef] {
        library.foundPages.compactMap(ContentCatalog.shared.diaryPage).filter { $0.diary == traveller }
    }

    static func pages(about traveller: TravellerID, in library: LibraryState) -> [DiaryPageDef] {
        library.foundPages.compactMap(ContentCatalog.shared.diaryPage).filter { $0.about == traveller }
    }

    static func notes(of family: FoundWritingRecord.Family,
                      in library: LibraryState) -> [FoundWritingRecord] {
        library.foundWritings.filter { $0.family == family }
    }

    static func recoveredNoteFamilies(in library: LibraryState) -> [FoundWritingRecord.Family] {
        FoundWritingRecord.Family.allCases.filter { !notes(of: $0, in: library).isEmpty }
    }

    static func olderRecordIDs(in library: LibraryState) -> [DiaryPageID] {
        library.foundPages.filter { ContentCatalog.shared.diaryPage($0) == nil }
    }

    static func rewardName(for page: DiaryPageDef) -> String? {
        if let id = page.teachesSchematic { return SchematicRegistry.definition(id)?.name }
        if let id = page.teachesPattern { return WorkshopPatternRegistry.definition(id)?.name }
        if page.teaches != nil || page.teachesFocus != nil || page.teachesGambit != nil
            || page.researchNode != nil { return page.kind.displayName }
        return nil
    }
}

extension FoundWritingRecord.Family {
    var displayName: String {
        switch self {
        case .fieldNote: "Field notes"
        case .routeMark: "Route sketches"
        case .siteFragment: "Site fragments"
        case .workingScrap: "Working scraps"
        }
    }

    var icon: String {
        switch self {
        case .fieldNote: "text.page"
        case .routeMark: "map"
        case .siteFragment: "building.columns"
        case .workingScrap: "scribble.variable"
        }
    }
}

private extension DiaryPageDef.Kind {
    var icon: String {
        switch self {
        case .locationClue: "map"
        case .whereabouts: "person.crop.circle.badge.questionmark"
        case .worldWorthWriting: "globe"
        case .account: "quote.bubble"
        case .turn: "arrow.triangle.turn.up.right.diamond"
        case .ruin: "building.columns"
        case .symbol: "scribble.variable"
        case .focus: "scope"
        case .gambit: "point.3.connected.trianglepath.dotted"
        case .pattern: "wrench.and.screwdriver"
        case .schematic: "scroll"
        case .researchLead: "lightbulb"
        }
    }
}

private enum LibraryTab: String, CaseIterable, Identifiable {
    case diaries = "Diaries"
    case people = "People"
    case dictionary = "Dictionary"
    case notes = "World Notes"
    case history = "History"
    var id: String { rawValue }

    var tabLabel: String {
        switch self {
        case .diaries: "Diaries"
        case .people: "People"
        case .dictionary: "Dictionary"
        case .notes: "Notes"
        case .history: "History"
        }
    }
}

/// The recovered-writing collection. Diaries index pages by author; People indexes the same stable
/// records by subject. A cross-reference never duplicates the recovered object or its global count.
struct LibraryView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var tab: LibraryTab = .diaries
    @State private var showsShelfRoot = true
    @State private var firstReturnPrompt: FirstReturnTutorialContext?

#if DEBUG
    init(debugTabIndex: Int = 0, debugShowsShelfRoot: Bool = true) {
        let tabs = LibraryTab.allCases
        _tab = State(initialValue: tabs.indices.contains(debugTabIndex) ? tabs[debugTabIndex] : .diaries)
        _showsShelfRoot = State(initialValue: debugShowsShelfRoot)
    }
#endif

    private var library: LibraryState { store.state.reality.library }
    private var columns: [GridItem] {
        dynamicTypeSize.isAccessibilitySize
            ? [GridItem(.flexible())]
            : [GridItem(.flexible(), spacing: 12), GridItem(.flexible())]
    }

    var body: some View {
        Group {
            if showsShelfRoot { shelfRoot }
            else { existingCollection }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(showsShelfRoot ? "The Library" : selectedShelfTitle)
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier(showsShelfRoot ? "library.shelves" : "library.\(tab.id.lowercased())")
        .tutorialHoverOverlay(isPresented: firstReturnPrompt != nil, alignment: .top) {
            firstReturnWritingOverlay
        }
        .onAppear { prepareFirstReturnWritingPrompt() }
    }

    private var existingCollection: some View {
        VStack(spacing: 0) {
            HStack {
                Button { showsShelfRoot = true } label: {
                    Label("Shelves", systemImage: "chevron.left")
                        .frame(minHeight: 44)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            Picker("Library collection", selection: $tab) {
                ForEach(LibraryTab.allCases) {
                    Text($0.tabLabel).tag($0).accessibilityLabel($0.tabLabel)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
#if DEBUG
            .background { P2SafeSpaceProbe(region: .libraryPicker) }
#endif

            ScrollView {
                VStack(spacing: 16) {
                    switch tab {
                    case .diaries: diariesGrid
                    case .people: peopleGrid
                    case .dictionary: dictionaryGrid
                    case .notes: notesGrid
                    case .history: historyPane
                    }
                }
                .padding(16)
                .padding(.top, 2)
#if DEBUG
                .background { P2SafeSpaceProbe(region: .libraryContent) }
#endif
            }
#if DEBUG
            .background { P2SafeSpaceProbe(region: .libraryScroll) }
#endif
        }
        .onAppear { checkSelectedShelfAfterRender() }
        .onChange(of: tab) { _, _ in checkSelectedShelfAfterRender() }
    }

    private var selectedShelfTitle: String {
        switch tab {
        case .diaries, .people: "Diaries"
        case .dictionary: "Dictionary"
        case .notes: "Field Notes"
        case .history: "World History"
        }
    }

    private var shelfRoot: some View {
        let shelves = LibraryShelfPresentation.make(in: store.state)
        return ScrollView {
            VStack(spacing: 10) {
                ForEach(shelves, id: \.id) { shelf in
                    shelfDestination(shelf)
                }
            }
            .padding(16)
        }
    }

    @ViewBuilder private func shelfDestination(_ shelf: LibraryShelfPresentation) -> some View {
        let label = shelfLabel(shelf)
        if shelf.id == .bestiary || shelf.id == .worldHistory {
            NavigationLink(value: shelf.route) {
                shelfRow(label: label, shelf: shelf)
            }
            .buttonStyle(.plain)
        } else {
            Button {
                tab = switch shelf.id {
                case .diaries: .diaries
                case .dictionary: .dictionary
                case .fieldNotes: .notes
                case .bestiary: .diaries
                case .worldHistory: .history
                }
                showsShelfRoot = false
            } label: { shelfRow(label: label, shelf: shelf) }
            .buttonStyle(.plain)
        }
    }

    private func shelfRow(label: String, shelf: LibraryShelfPresentation) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "books.vertical")
                .frame(width: 32, height: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.headline)
                Text("\(shelf.entryCount) entr\(shelf.entryCount == 1 ? "y" : "ies")")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if shelf.uncheckedCount > 0 {
                Text("\(shelf.uncheckedCount) new")
                    .font(.caption.weight(.semibold))
                    .accessibilityLabel("\(shelf.uncheckedCount) unchecked")
            }
            Image(systemName: "chevron.right")
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, minHeight: 64)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("library.shelf.\(shelf.id.rawValue)")
    }

    private func shelfLabel(_ shelf: LibraryShelfPresentation) -> String {
        switch shelf.id {
        case .diaries: "Diaries"
        case .bestiary: "Bestiary"
        case .dictionary: "Dictionary"
        case .fieldNotes: "Field Notes"
        case .worldHistory: "World History"
        }
    }

    private func checkSelectedShelfAfterRender() {
        let shelfID: LibraryShelfID
        switch tab {
        case .diaries, .people: shelfID = .diaries
        case .dictionary: shelfID = .dictionary
        case .notes: shelfID = .fieldNotes
        case .history: shelfID = .worldHistory
        }
        guard let shelf = LibraryShelfPresentation.make(in: store.state).first(where: {
            $0.id == shelfID
        }) else { return }
        store.checkLibraryContent(LibraryShelfPresentation.contentIDsRenderedByCollectionRoot(
            shelf.id, in: store.state))
    }

    @ViewBuilder private var diariesGrid: some View {
        let authors = LibraryPresentation.diaries(in: library)
        let olderRecords = LibraryPresentation.olderRecordIDs(in: library)
        if authors.isEmpty && olderRecords.isEmpty {
            EmptyCollection(icon: "book.pages",
                            text: "Recovered pages will gather here by their writer.")
        } else {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(authors) { traveller in
                    let pages = LibraryPresentation.pages(by: traveller.id, in: library)
                    NavigationLink {
                        LibraryDiaryView(traveller: traveller, pages: pages)
                    } label: {
                        LibraryTile(icon: traveller.icon, travellerID: traveller.id,
                                    title: traveller.name,
                                    subtitle: "Written by \(traveller.name)",
                                    count: "\(pages.count) page\(pages.count == 1 ? "" : "s") written",
                                    accent: .brown,
                                    wide: dynamicTypeSize.isAccessibilitySize)
                    }
                    .buttonStyle(.plain)
#if DEBUG
                    .background {
                        if traveller.id == authors.first?.id {
                            P2LibrarySemanticProbe(slot: "diaries.first",
                                                   identity: traveller.id.rawValue)
                        }
                        if traveller.id == authors.last?.id {
                            P2LibrarySemanticProbe(slot: "diaries.last",
                                                   identity: traveller.id.rawValue)
                        }
                    }
#endif
                }
                if !olderRecords.isEmpty {
                    NavigationLink {
                        OlderLibraryRecordsView(ids: olderRecords)
                    } label: {
                        LibraryTile(icon: "archivebox", title: "Older records",
                                    subtitle: "Found in an older version",
                                    count: "\(olderRecords.count) record\(olderRecords.count == 1 ? "" : "s")",
                                    accent: .gray,
                                    wide: dynamicTypeSize.isAccessibilitySize)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder private var firstReturnWritingOverlay: some View {
        if let context = firstReturnPrompt {
            if let copy = TutorialRules.libraryCopy(context, in: store.state) {
                tutorialNotice(title: "What this writing carries", icon: "doc.text.magnifyingglass") {
                    Text(copy).font(.callout)
                }
            } else {
                tutorialNotice(title: "Recovered writing", icon: "doc.questionmark") {
                    Text("The record selected by an older return is not present in this save. The Library will not guess what kind of writing it was.")
                        .font(.callout).foregroundStyle(.secondary)
                }
            }
        }
    }

    private func prepareFirstReturnWritingPrompt() {
        guard firstReturnPrompt == nil,
              let context = store.state.tutorial.firstReturnContext,
              context.route == .library,
              store.state.tutorial[.libraryFirstWriting].status != .completed else { return }
        firstReturnPrompt = context
        // Completion records that the exact recovered text was displayed. Keeping a local copy
        // lets the hovering card remain readable until dismissed without re-entering scroll layout.
        if TutorialRules.libraryCopy(context, in: store.state) != nil {
            store.displayedFirstReturnWriting(context)
        }
    }

    private func tutorialNotice<Content: View>(title: String, icon: String,
                                                @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon).font(.headline)
            content()
            HStack {
                Spacer()
                Button("Got it") { firstReturnPrompt = nil }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.tint.opacity(0.35)))
        .shadow(radius: 8, y: 3)
    }

    @ViewBuilder private var peopleGrid: some View {
        let people = LibraryPresentation.people(in: library)
        if people.isEmpty {
            EmptyCollection(icon: "person.crop.square",
                            text: "Nobody's writing yet. Recovered pages introduce their authors.")
        } else {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(people) { traveller in
                    NavigationLink {
                        LibraryTravellerView(traveller: traveller).environmentObject(store)
                    } label: {
                        personTile(traveller)
                    }
                    .buttonStyle(.plain)
#if DEBUG
                    .background {
                        if traveller.id == people.first?.id {
                            P2LibrarySemanticProbe(slot: "people.first",
                                                   identity: traveller.id.rawValue)
                        }
                        if traveller.id == people.last?.id {
                            P2LibrarySemanticProbe(slot: "people.last",
                                                   identity: traveller.id.rawValue)
                        }
                    }
#endif
                }
            }
        }
    }

    private func personTile(_ traveller: TravellerDef) -> some View {
        let clues = LibraryPresentation.pages(about: traveller.id, in: library)
        let hint = LibraryRules.hintPage(for: traveller, library: library)
        return LibraryTile(icon: traveller.icon, travellerID: traveller.id,
                           title: traveller.name,
                           subtitle: LibraryPresentation.placementLabel(for: traveller, in: store.state),
                           count: clues.isEmpty ? nil : "\(clues.count) clue\(clues.count == 1 ? "" : "s") about them",
                           accent: hint.isFound ? .green : .accentColor,
                           wide: dynamicTypeSize.isAccessibilitySize)
    }

    @ViewBuilder private var dictionaryGrid: some View {
        let entries = LibraryRules.dictionaryEntries(
            reality: store.state.reality, base: store.state.base)
        if entries.isEmpty {
            EmptyCollection(icon: "character.book.closed",
                            text: "Sigils you can write or have inspected will gather here.")
        } else {
            VStack(alignment: .leading, spacing: 18) {
                ForEach(LibraryRules.DictionaryCategory.allCases) { category in
                    let group = entries.filter { $0.category == category }
                    if !group.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(category.displayName).font(.headline)
                            LazyVGrid(
                                columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 6),
                                spacing: 8
                            ) {
                                ForEach(group) { entry in
                                    DictionaryGlyphCell(entry: entry)
#if DEBUG
                                        .background {
                                            if entry.id == entries.first?.id {
                                                P2LibrarySemanticProbe(
                                                    slot: "dictionary.first",
                                                    identity: entry.glyphID)
                                            }
                                            if entry.id == entries.last?.id {
                                                P2LibrarySemanticProbe(
                                                    slot: "dictionary.last",
                                                    identity: entry.glyphID)
                                            }
                                        }
#endif
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder private var notesGrid: some View {
        let families = LibraryPresentation.recoveredNoteFamilies(in: library)
        let teachings = library.recoveredTeachings
        if families.isEmpty && teachings.isEmpty {
            EmptyCollection(icon: "note.text",
                            text: "No anonymous world notes recovered yet.")
        } else {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(teachings) { teaching in
                    NavigationLink {
                        RecoveredTeachingDetailView(teachingID: teaching.teachingID)
                            .environmentObject(store)
                    } label: {
                        LibraryTile(icon: "text.book.closed", title: teaching.frozenTitle,
                                    subtitle: teaching.isRead ? "Teaching read" : "Unread teaching",
                                    count: nil, accent: teaching.isRead ? .indigo : .orange,
                                    wide: dynamicTypeSize.isAccessibilitySize)
                    }
                    .buttonStyle(.plain)
                }
                ForEach(families, id: \.self) { family in
                    NavigationLink {
                        LibraryWorldNotesView(family: family).environmentObject(store)
                    } label: {
                        LibraryTile(icon: family.icon, title: family.displayName,
                                    subtitle: notePurpose(family),
                                    count: "\(LibraryPresentation.notes(of: family, in: library).count) recovered",
                                    accent: .indigo,
                                    wide: dynamicTypeSize.isAccessibilitySize)
                    }
                    .buttonStyle(.plain)
#if DEBUG
                    .background {
                        if family == families.first {
                            P2LibrarySemanticProbe(slot: "notes.first",
                                                   identity: family.rawValue)
                        }
                        if family == families.last {
                            P2LibrarySemanticProbe(slot: "notes.last",
                                                   identity: family.rawValue)
                        }
                    }
#endif
                }
            }
        }
    }

    private func notePurpose(_ family: FoundWritingRecord.Family) -> String {
        switch family {
        case .fieldNote: "Relations observed"
        case .routeMark: "Ways through worlds"
        case .siteFragment: "Places remembered"
        case .workingScrap: "Work left unfinished"
        }
    }

    private var historyPane: some View {
        let recent = Array(library.visitedWorlds.reversed().prefix(5))
        return VStack(spacing: 12) {
            NavigationLink(value: AppRoute.worldHistory) {
                LibraryTile(icon: "rectangle.split.2x1", title: "Open full history",
                            subtitle: "Read, keep and compare records",
                            count: library.visitedWorlds.isEmpty ? nil : "\(library.visitedWorlds.count) worlds",
                            accent: .teal, wide: true)
            }
            .buttonStyle(.plain)

            if library.visitedWorlds.isEmpty {
                EmptyCollection(icon: "clock.arrow.circlepath",
                                text: "Every world you bind will be recorded here.")
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Most recent").font(.headline)
                    ForEach(recent) { world in
                        HStack(spacing: 10) {
                            Image(systemName: world.isKept ? "bookmark.fill" : "globe")
                                .foregroundStyle(.teal).frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("World \(world.runIndex)").font(.callout.weight(.semibold))
                                Text(world.descriptionSentence)
                                    .font(.caption).foregroundStyle(.secondary).lineLimit(2)
                            }
                            Spacer(minLength: 0)
                        }
                        .frame(minHeight: 52)
#if DEBUG
                        .background {
                            if world.id == recent.first?.id {
                                P2LibrarySemanticProbe(slot: "history.first",
                                                       identity: String(world.id.rawValue))
                            }
                            if world.id == recent.last?.id {
                                P2LibrarySemanticProbe(slot: "history.last",
                                                       identity: String(world.id.rawValue))
                            }
                        }
#endif
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

private struct RecoveredTeachingDetailView: View {
    @EnvironmentObject private var store: GameStore
    let teachingID: RecoveredTeachingID

    private var record: RecoveredTeachingRecord? {
        store.state.reality.library.recoveredTeachings.first { $0.teachingID == teachingID }
    }

    var body: some View {
        ScrollView {
            if let record {
                VStack(alignment: .leading, spacing: 12) {
                    Text(record.frozenTitle).font(.title2.weight(.semibold))
                    Text(record.frozenInstructionCopy).font(.body)
                    Text(record.isRead ? "Teaching learned" : "Teaching unavailable")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
            }
        }
        .navigationTitle("Recovered teaching")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            _ = store.readRecoveredTeaching(teachingID)
            store.checkLibraryContent([.recoveredTeaching(teachingID)])
        }
    }
}

private struct DictionaryGlyphCell: View {
    let entry: LibraryRules.DictionaryEntry
    @State private var showsDetail = false

    var body: some View {
        Button { showsDetail = true } label: {
            VStack(spacing: 3) {
                RuneGlyph(id: entry.glyphID, lineWidth: 1.6)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                Text(entry.displayName)
                    .font(.system(size: 9, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(4)
            .aspectRatio(1, contentMode: .fit)
            .background(Color(.secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 9))
            .overlay(RoundedRectangle(cornerRadius: 9).stroke(.secondary.opacity(0.25)))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(entry.accessibilityName)
        .accessibilityHint("Shows Dictionary details")
        .popover(isPresented: $showsDetail, arrowEdge: .top) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    RuneGlyph(id: entry.glyphID)
                        .frame(width: 44, height: 44)
                    Text(entry.isKnown ? (entry.name ?? "Unknown Sigil") : "Unknown Sigil")
                        .font(.headline)
                }
                if entry.isKnown, let explanation = entry.explanation {
                    Text(explanation).font(.callout)
                } else {
                    Text("Its meaning has not been identified.")
                        .font(.callout).foregroundStyle(.secondary)
                }
            }
            .padding(16)
            .frame(idealWidth: 260)
            .presentationCompactAdaptation(.popover)
        }
    }
}

private struct LibraryTile: View {
    let icon: String
    var travellerID: TravellerID? = nil
    let title: String
    let subtitle: String
    let count: String?
    let accent: Color
    let wide: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            NamedCharacterPixelIdentity(
                travellerID: travellerID,
                fallbackSystemIcon: icon,
                fallbackColor: accent
            )
                .frame(width: 48, height: 48)
                .background(accent.opacity(0.14), in: RoundedRectangle(cornerRadius: 12))
            Spacer(minLength: 0)
            Text(title).font(.headline).foregroundStyle(.primary).lineLimit(2)
            Text(subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(2)
            if let count {
                Text(count).font(.caption2.weight(.semibold)).foregroundStyle(accent)
            }
        }
        .frame(maxWidth: .infinity, minHeight: wide ? 118 : 150, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 16))
        .overlay(alignment: .topTrailing) {
            Image(systemName: "chevron.right")
                .font(.caption.bold()).foregroundStyle(.tertiary).padding(14)
        }
        .contentShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }
}

private struct EmptyCollection: View {
    let icon: String
    let text: String

    var body: some View {
        ContentUnavailableView("Nothing here yet", systemImage: icon, description: Text(text))
            .frame(maxWidth: .infinity, minHeight: 220)
    }
}

private struct LibraryTravellerView: View {
    @EnvironmentObject private var store: GameStore
    let traveller: TravellerDef

    private var library: LibraryState { store.state.reality.library }
    private var hint: HintPage { LibraryRules.hintPage(for: traveller, library: library) }
    private var clues: [DiaryPageDef] { LibraryPresentation.pages(about: traveller.id, in: library) }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                StationCard(title: traveller.name, icon: traveller.icon) {
                    HStack(alignment: .top, spacing: 12) {
                        NamedCharacterPixelIdentity(
                            travellerID: traveller.id,
                            fallbackSystemIcon: traveller.icon,
                            fallbackColor: .secondary
                        )
                        .frame(width: 52, height: 52)
                        .background(Color.secondary.opacity(0.12),
                                    in: RoundedRectangle(cornerRadius: 12))

                        Text(hint.isFound
                             ? "\(LibraryPresentation.placementLabel(for: traveller, in: store.state)) · \(traveller.blurb)"
                             : traveller.calling.capitalized)
                            .font(.callout).foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .accessibilityElement(children: .combine)
                }

                if !hint.passages.isEmpty {
                    StationCard(title: "Where they went", icon: "map") {
                        ForEach(Array(hint.passages.enumerated()), id: \.offset) { _, passage in
                            Text(passage.map { "“\($0)”" } ?? "— missing —")
                                .font(.callout.italic())
                                .foregroundStyle(passage == nil || hint.isFound ? .tertiary : .primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        if !hint.isFound {
                            Text(hint.isComplete
                                 ? "Everything they wrote about where they went."
                                 : "\(hint.missingCount) more page\(hint.missingCount == 1 ? "" : "s") somewhere.")
                                .font(.caption)
                                .foregroundStyle(hint.isComplete ? Color.secondary : Color.orange)
                        }
                    }
                }

                PageCollection(title: "Clues about them", pages: clues,
                               empty: "No recovered pages are about this person yet.")
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(traveller.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct LibraryDiaryView: View {
    @EnvironmentObject private var store: GameStore
    let traveller: TravellerDef
    let pages: [DiaryPageDef]

    var body: some View {
        ScrollView {
            PageCollection(title: "\(pages.count) page\(pages.count == 1 ? "" : "s") written",
                           pages: pages,
                           empty: "No pages from this diary recovered yet.",
                           onPageRendered: { page in
                               store.checkLibraryContent([.diaryPage(page.id)])
                           })
                .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(traveller.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct OlderLibraryRecordsView: View {
    let ids: [DiaryPageID]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("These Pages remain in your Library, but their writing is not available in this version. Their saved identities are kept in case a later update restores them.")
                    .font(.callout).foregroundStyle(.secondary)
                ForEach(ids, id: \.self) { id in
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Page from an older save")
                            Text("Internal ID: \(id.rawValue)").font(.caption2).foregroundStyle(.secondary)
                        }
                    } icon: { Image(systemName: "doc.questionmark") }
                        .font(.caption)
                        .accessibilityElement(children: .combine)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color(.secondarySystemGroupedBackground),
                                    in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Older records")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct PageCollection: View {
    let title: String
    let pages: [DiaryPageDef]
    let empty: String
    var onPageRendered: ((DiaryPageDef) -> Void)? = nil

    private let columns = [GridItem(.adaptive(minimum: 132), spacing: 10)]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline)
            if pages.isEmpty {
                EmptyNote(empty)
            } else {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(pages) { page in
                        NavigationLink {
                            DiaryPageDetailView(page: page)
                        } label: {
                            DiaryPageTile(page: page)
                                .onAppear { onPageRendered?(page) }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct DiaryPageTile: View {
    let page: DiaryPageDef

    private var hasReward: Bool {
        LibraryPresentation.rewardName(for: page) != nil
    }

    private var fragment: String {
        let sentence = page.prose.split(separator: ".", maxSplits: 1).first.map(String.init) ?? page.prose
        return sentence + (sentence == page.prose ? "" : ".")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Image(systemName: page.kind.icon)
                    .font(.title3)
                    .frame(width: 32, height: 32)
                    .background(Color.indigo.opacity(0.14), in: RoundedRectangle(cornerRadius: 8))
                Spacer(minLength: 4)
                if hasReward {
                    Image(systemName: "sparkles")
                        .font(.caption.bold())
                        .foregroundStyle(.orange)
                        .accessibilityLabel("Carries a teaching or lead")
                }
            }
            Text(page.kind.displayName).font(.caption.weight(.semibold))
            Text(fragment).font(.caption).foregroundStyle(.secondary).lineLimit(3)
            if let reward = LibraryPresentation.rewardName(for: page) {
                Text(reward).font(.caption2.weight(.semibold)).foregroundStyle(.orange)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 132, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
        .contentShape(RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(page.kind.displayName). \(fragment)\(hasReward ? ". Carries a teaching or lead." : "")")
    }
}

private struct DiaryPageDetailView: View {
    let page: DiaryPageDef

    var body: some View {
        ScrollView {
            DiaryPageProseCard(page: page)
                .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(page.kind.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct LibraryWorldNotesView: View {
    @EnvironmentObject private var store: GameStore
    let family: FoundWritingRecord.Family

    private var notes: [FoundWritingRecord] {
        LibraryPresentation.notes(of: family, in: store.state.reality.library)
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(notes) { note in
                    Text("“\(note.prose)”")
                        .font(.callout.italic())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(Color(.secondarySystemGroupedBackground),
                                    in: RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(family.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DiaryPageProseCard: View {
    let page: DiaryPageDef

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(page.kind.displayName).font(.caption.weight(.medium))
                Spacer()
                Image(systemName: "doc.text").font(.caption2).foregroundStyle(.secondary)
            }
            Text(AuthoredTextRendering.attributed("“\(page.prose)”"))
                .font(.caption.italic()).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if let reward = LibraryPresentation.rewardName(for: page) {
                Label(reward, systemImage: "sparkles")
                    .font(.caption.weight(.semibold)).foregroundStyle(.orange)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }
}
