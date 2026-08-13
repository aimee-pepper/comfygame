import SwiftUI

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
}

extension FoundWritingRecord.Family {
    var displayName: String {
        switch self {
        case .fieldNote: "Field notes"
        case .routeMark: "Route marks"
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
        case .researchLead: "lightbulb"
        }
    }
}

private enum LibraryTab: String, CaseIterable, Identifiable {
    case diaries = "Diaries"
    case people = "People"
    case notes = "World Notes"
    case history = "History"
    var id: String { rawValue }
}

/// The recovered-writing collection. Diaries index pages by author; People indexes the same stable
/// records by subject. A cross-reference never duplicates the recovered object or its global count.
struct LibraryView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var tab: LibraryTab = .diaries
    @State private var firstReturnPrompt: FirstReturnTutorialContext?

    private var library: LibraryState { store.state.reality.library }
    private var columns: [GridItem] {
        dynamicTypeSize.isAccessibilitySize
            ? [GridItem(.flexible())]
            : [GridItem(.flexible(), spacing: 12), GridItem(.flexible())]
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Library collection", selection: $tab) {
                ForEach(LibraryTab.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            ScrollView {
                VStack(spacing: 16) {
                    switch tab {
                    case .diaries: diariesGrid
                    case .people: peopleGrid
                    case .notes: notesGrid
                    case .history: historyPane
                    }
                }
                .padding(16)
                .padding(.top, 2)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("The Library")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("library.\(tab.id.lowercased())")
        .tutorialHoverOverlay(alignment: .top) {
            firstReturnWritingOverlay
        }
        .onAppear { prepareFirstReturnWritingPrompt() }
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
                }
                if !olderRecords.isEmpty {
                    NavigationLink {
                        OlderLibraryRecordsView(ids: olderRecords)
                    } label: {
                        LibraryTile(icon: "archivebox", title: "Older records",
                                    subtitle: "Recovered by an earlier catalogue",
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
        store.displayedFirstReturnWriting()
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

    @ViewBuilder private var notesGrid: some View {
        let families = LibraryPresentation.recoveredNoteFamilies(in: library)
        if families.isEmpty {
            EmptyCollection(icon: "note.text",
                            text: "No anonymous world notes recovered yet.")
        } else {
            LazyVGrid(columns: columns, spacing: 12) {
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
        VStack(spacing: 12) {
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
                    ForEach(library.visitedWorlds.reversed().prefix(5)) { world in
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
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
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
                    Text(hint.isFound
                         ? "\(LibraryPresentation.placementLabel(for: traveller, in: store.state)) · \(traveller.blurb)"
                         : traveller.calling.capitalized)
                        .font(.callout).foregroundStyle(.secondary)
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
    let traveller: TravellerDef
    let pages: [DiaryPageDef]

    var body: some View {
        ScrollView {
            PageCollection(title: "\(pages.count) page\(pages.count == 1 ? "" : "s") written",
                           pages: pages,
                           empty: "No pages from this diary recovered yet.")
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
                Text("These pages remain recovered, but their authored text is not present in the current catalogue. Their IDs are retained so a later migration can restore them.")
                    .font(.callout).foregroundStyle(.secondary)
                ForEach(ids, id: \.self) { id in
                    Label(id.rawValue, systemImage: "doc.questionmark")
                        .font(.caption)
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
        page.teaches != nil || page.teachesFocus != nil || page.teachesGambit != nil
            || page.teachesPattern != nil || page.researchNode != nil
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
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }
}
