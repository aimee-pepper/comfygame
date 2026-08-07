import SwiftUI

/// The Workshop's research.
///
/// **Everything buyable in the game lives here**, gated behind a themed branch and its
/// prerequisites — there is no flat shopping list anywhere. A branch is a subject you're getting
/// better at; its nodes are the steps, and locked ones stay visible because seeing what you can't
/// have yet is most of what makes a tree feel like a tree.
///
/// The list of branches is a list; each one **opens onto its own screen**. Expanding four trees
/// inside a scrolling card gave every one of them a fifth of the screen to draw itself in, and the
/// trees were laid out sideways to cope — so reading a branch meant scrolling horizontally.
/// The branches taught at one building.
///
/// **Every building owns the branch about it** (Q40, answered 6 Aug). The split: everything you
/// work out yourself lives at the Workshop; everything you learn from a person lives with that
/// person's building. Which is what makes finding a smith mean something — she arrives with what
/// she knows, rather than you buying it from a menu that existed before you met her.
struct ResearchTree: View {
    /// Nil for the Workshop, which teaches everything nobody else does.
    var station: StationID?

    var body: some View {
        VStack(spacing: 10) {
            ForEach(ContentCatalog.shared.branchesInOrder.filter { $0.station == station }) { branch in
                ResearchBranchRow(branch: branch)
            }
        }
    }
}

private struct ResearchBranchRow: View {
    @EnvironmentObject private var store: GameStore
    let branch: ResearchBranchDef

    var body: some View {
        let progress = store.progress(in: branch)
        let available = store.availableCount(in: branch)

        NavigationLink {
            ResearchBranchScreen(branch: branch).environmentObject(store)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: branch.icon).font(.title3).frame(width: 26).foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 1) {
                    Text(branch.name).font(.headline).foregroundStyle(.primary)
                    Text(branch.blurb)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(progress.done)/\(progress.total)")
                        .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                    // What's ready to buy right now, so a branch worth opening says so from here.
                    if available > 0 {
                        Text("\(available) ready")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color.accentColor)
                    }
                }
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold)).foregroundStyle(.tertiary)
            }
            .frame(minHeight: 44)
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
            .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}
