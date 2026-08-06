import SwiftUI

/// Rarity is shown the way the brief asks for it: **in the colour of the item's name.**
extension Rarity {
    var tint: Color {
        switch self {
        case .common: .primary
        case .uncommon: .green
        case .rare: .blue
        case .mythic: .purple
        }
    }

    var displayName: String { rawValue.capitalized }
}

extension ItemStack {
    /// The colour to show it in. An unidentified curio still has a rarity of its own — you can tell
    /// it's *interesting* before you can tell what it is. A material's rarity is its grade, so a
    /// superb plate reads as valuable at a glance.
    var rarity: Rarity {
        material?.rarity ?? ContentCatalog.shared.item(catalogID)?.rarity ?? .common
    }
}

/// What happens when loot won't fit: **you choose.**
///
/// The satchel is deliberately smaller than home storage so that "keep it or leave it" is a real
/// decision in the world (decisions-log session 4). Making that decision *for* the player — silently
/// dropping the loot, or silently discarding the oldest thing — is the one thing this must not do.
///
/// The offer lives on the run, so a force-quit while you're deciding resumes with the decision
/// still open.
struct LootDecisionCard: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        if let offered = store.pendingLoot.first {
            VStack(alignment: .leading, spacing: 10) {
                Label("No room in your satchel", systemImage: "bag.badge.questionmark")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.orange)

                HStack(spacing: 10) {
                    Image(systemName: offered.icon).frame(width: 22).foregroundStyle(offered.rarity.tint)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(offered.displayName)
                            .font(.callout.weight(.medium))
                            .foregroundStyle(offered.rarity.tint)
                        Text(ContentCatalog.shared.item(offered.catalogID)?.blurb ?? "")
                            .font(.caption).foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }

                Text("Drop something to take it, or leave it behind.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(store.state.worlds.activeRun?.satchelItems.stacks ?? []) { carried in
                    Button {
                        store.takeOffered(offered, dropping: carried)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.left.arrow.right").font(.caption).foregroundStyle(.secondary)
                            Text("Drop \(carried.displayName)")
                                .font(.callout)
                                .foregroundStyle(carried.rarity.tint)
                            Spacer(minLength: 0)
                        }
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.bordered)
                }

                Button(role: .destructive) {
                    store.leaveOffered(offered)
                } label: {
                    Label("Leave it behind", systemImage: "xmark")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.bordered)

                if store.pendingLoot.count > 1 {
                    Text("\(store.pendingLoot.count - 1) more waiting.")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.orange.opacity(0.5), lineWidth: 1.5))
        }
    }
}
