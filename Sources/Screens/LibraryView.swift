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
                if hints.isEmpty {
                    StationCard(title: "The Library", icon: "books.vertical") {
                        EmptyNote("Nothing yet. Pages turn up in worlds — somebody's diary, scattered.")
                    }
                } else {
                    ForEach(hints, id: \.traveller.id) { hint in
                        hintCard(hint)
                    }
                }
                if !library.foundPages.isEmpty { loosePages }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("The Library")
        .navigationBarTitleDisplayMode(.inline)
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
                    Text("“\(passage)”")
                        .font(.callout.italic())
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
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(ContentCatalog.shared.traveller(page.diary)?.name ?? page.diary.rawValue)
                                .font(.caption.weight(.medium))
                            Spacer()
                            Text(page.kind.displayName)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Text("“\(page.prose)”")
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
}
