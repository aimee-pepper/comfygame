import SwiftUI

/// Everything you know about where people are.
///
/// **It collects, it does not interpret** (decisions-session-7). Passages are assembled in the
/// traveller's own words, side by side, with gaps shown as gaps. It never renders them as a list of
/// conditions, never names a sigil or a target or a value, and never says what *kind* of piece is
/// missing — only how many. The translation from "no shadow anywhere" to a world you can write is
/// the player's work, and doing it is the game.
struct LibraryView: View {
    @EnvironmentObject private var store: GameStore

    private var library: LibraryState { store.state.reality.library }
    private var hints: [HintPage] { LibraryRules.hintPages(in: library) }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                firstReturnWritingCard
                if hints.isEmpty {
                    StationCard(title: "The Library", icon: "books.vertical") {
                        EmptyNote("Nothing yet. Pages turn up in worlds — somebody's diary, scattered.")
                    }
                } else {
                    ForEach(hints, id: \.traveller.id) { hint in
                        hintCard(hint)
                    }
                }
                // **A tab into the history** (Aimee, 6 Aug). The Library collects what other
                // people wrote down; this is what *you* wrote down, which belongs beside it.
                NavigationLink(value: AppRoute.worldHistory) {
                    StationCard(title: "Worlds you've written", icon: "clock.arrow.circlepath") {
                        HStack {
                            Text(library.visitedWorlds.isEmpty
                                 ? "Nothing yet. Every world you bind is recorded."
                                 : "\(library.visitedWorlds.count) recorded — what you wrote, and what it became.")
                                .font(.caption).foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 6)
                            Image(systemName: "chevron.right")
                                .font(.caption2).foregroundStyle(.tertiary)
                        }
                        .frame(minHeight: 30)
                    }
                }
                .buttonStyle(.plain)

                if !library.foundPages.isEmpty { loosePages }
                if !library.foundWritings.isEmpty { worldNotes }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("The Library")
        .navigationBarTitleDisplayMode(.inline)
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

    private func hintCard(_ hint: HintPage) -> some View {
        StationCard(title: hint.traveller.name, icon: hint.isFound ? "person.fill.checkmark" : "person.fill.questionmark") {
            Text(hint.isFound ? "Found. \(hint.traveller.blurb)" : hint.traveller.calling.capitalized)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(Array(hint.passages.enumerated()), id: \.offset) { _, passage in
                if let passage {
                    // Their own words, verbatim. This is what gets matched against a world.
                    //
                    // **Dimmed once you've found them**, even where the diary is unfinished
                    // (Aimee, 6 Aug). The clues are directions to somebody; once they're at your
                    // fire the directions are a keepsake, and reading as live instructions makes a
                    // finished search look unfinished.
                    Text("“\(passage)”")
                        .font(.callout.italic())
                        .foregroundStyle(hint.isFound ? .tertiary : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    // A gap shown as a gap. Not what kind of gap — that would be interpretation.
                    Text("— missing —")
                        .font(.callout)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            if !hint.isFound {
                // A count, and only a count: knowing you have four of six tells you whether to keep
                // hunting or to write what you know and leave the rest to chance.
                Text(hint.isComplete
                     ? "Everything they wrote about where they went."
                     : "\(hint.missingCount) more page\(hint.missingCount == 1 ? "" : "s") somewhere.")
                    .font(.caption)
                    .foregroundStyle(hint.isComplete ? Color.secondary : Color.orange)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    /// Pages that aren't about anyone's location — a rune, a lead, a place worth writing.
    private var loosePages: some View {
        StationCard(title: "Pages — \(library.foundPages.count)", icon: "doc.text") {
            ForEach(library.foundPages, id: \.rawValue) { id in
                if let page = ContentCatalog.shared.diaryPage(id) {
                    DiaryPageProseCard(page: page)
                }
            }
        }
    }

    private var worldNotes: some View {
        StationCard(title: "World notes — \(library.foundWritings.count)", icon: "note.text") {
            ForEach(library.foundWritings) { writing in
                VStack(alignment: .leading, spacing: 2) {
                    Text(writing.family == .fieldNote ? "Field note" : writing.family.rawValue)
                        .font(.caption.weight(.medium))
                    Text("“\(writing.prose)”")
                        .font(.caption.italic())
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 2)
            }
        }
    }
}

struct DiaryPageProseCard: View {
    let page: DiaryPageDef

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(ContentCatalog.shared.traveller(page.diary)?.name ?? page.diary.rawValue)
                    .font(.caption.weight(.medium))
                Spacer()
                Text(page.kind.displayName).font(.caption2).foregroundStyle(.secondary)
            }
            Text(AuthoredTextRendering.attributed("“\(page.prose)”"))
                .font(.caption.italic())
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 2)
    }
}
