import SwiftUI

enum LibraryPresentation {
    static func people(in library: LibraryState) -> [TravellerDef] {
        let recoveredAuthors = Set(library.foundPages.compactMap {
            ContentCatalog.shared.diaryPage($0)?.diary
        })
        let visible = library.knownTravellers
            .union(library.foundTravellers)
            .union(recoveredAuthors)
        return ContentCatalog.shared.travellersInAuthoredOrder.filter { visible.contains($0.id) }
    }

    static func pages(by traveller: TravellerID, in library: LibraryState) -> [DiaryPageDef] {
        library.foundPages.compactMap(ContentCatalog.shared.diaryPage).filter { $0.diary == traveller }
    }

    static func notes(of family: FoundWritingRecord.Family,
                      in library: LibraryState) -> [FoundWritingRecord] {
        library.foundWritings.filter { $0.family == family }
    }

    static func recoveredNoteFamilies(in library: LibraryState) -> [FoundWritingRecord.Family] {
        FoundWritingRecord.Family.allCases.filter { !notes(of: $0, in: library).isEmpty }
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

private enum LibraryTab: String, CaseIterable, Identifiable {
    case people = "People"
    case notes = "World Notes"
    case history = "History"
    var id: String { rawValue }
}

/// The recovered-writing collection: people, anonymous world notes, and the player's own worlds.
/// Each record has one top-level home. A diary page never appears once as a clue and again in a
/// generic page pile.
struct LibraryView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var tab: LibraryTab = .people

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
                    firstReturnWritingCard
                    switch tab {
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
    }

    @ViewBuilder private var firstReturnWritingCard: some View {
        if let context = store.state.tutorial.firstReturnContext,
           context.route == .library,
           store.state.tutorial[.libraryFirstWriting].status != .completed {
            if let copy = TutorialRules.libraryCopy(context, in: store.state) {
                StationCard(title: "What this writing carries", icon: "doc.text.magnifyingglass") {
                    Text(copy).font(.callout)
                }
                .onAppear { store.displayedFirstReturnWriting() }
            } else {
                StationCard(title: "Recovered writing", icon: "doc.questionmark") {
                    Text("The record selected by an older return is not present in this save. The Library will not guess what kind of writing it was.")
                        .font(.callout).foregroundStyle(.secondary)
                }
            }
        }
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
        let pages = LibraryPresentation.pages(by: traveller.id, in: library)
        let hint = LibraryRules.hintPage(for: traveller, library: library)
        return LibraryTile(icon: traveller.icon, title: traveller.name,
                           subtitle: hint.isFound ? "At Home" : traveller.calling.capitalized,
                           count: pages.isEmpty ? nil : "\(pages.count) recovered",
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
    let title: String
    let subtitle: String
    let count: String?
    let accent: Color
    let wide: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 30, weight: .medium))
                .foregroundStyle(accent)
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
    private var pages: [DiaryPageDef] { LibraryPresentation.pages(by: traveller.id, in: library) }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                StationCard(title: traveller.name, icon: traveller.icon) {
                    Text(hint.isFound ? "At Home · \(traveller.blurb)" : traveller.calling.capitalized)
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

                StationCard(title: "Recovered diary — \(pages.count)", icon: "book.pages") {
                    if pages.isEmpty {
                        EmptyNote("No pages from this diary recovered yet.")
                    } else {
                        ForEach(pages) { DiaryPageProseCard(page: $0) }
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(traveller.name)
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
