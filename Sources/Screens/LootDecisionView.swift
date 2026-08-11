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
    @State private var selectedCarried: ItemStack?

    var body: some View {
        if let offered = store.pendingLoot.first {
            VStack(alignment: .leading, spacing: 10) {
                Label("No room in your satchel", systemImage: "bag.badge.questionmark")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.orange)

                HStack(spacing: 10) {
                    ItemIconTile(icon: offered.icon, catalogueID: offered.catalogID,
                                 rarity: offered.rarity,
                                 quantity: offered.count, identified: offered.identified,
                                 location: .offered, accessibilityName: offered.displayName)
                        .frame(width: 52, height: 52)
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

                let carriedItems = store.state.worlds.activeRun?.satchelItems.stacks ?? []
                SixAcrossItemGrid(data: carriedItems, id: \.id) { carried in
                    AnchoredItemDetailButton(item: carried, selection: $selectedCarried) {
                        ItemIconTile(icon: carried.icon, catalogueID: carried.catalogID,
                                     rarity: carried.rarity,
                                     quantity: carried.count, identified: carried.identified,
                                     location: .carried,
                                     accessibilityName: carried.displayName)
                    } detail: { selected in
                        LootSwapDetailSheet(carried: selected, offered: offered) {
                            store.takeOffered(offered, dropping: selected)
                            selectedCarried = nil
                        }
                    }
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
            .padding(.horizontal, 8)
            .padding(.vertical, 14)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.orange.opacity(0.5), lineWidth: 1.5))
        }
    }
}

private struct LootSwapDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let carried: ItemStack
    let offered: ItemStack
    let swap: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 16) {
                        ItemIconTile(icon: carried.icon, catalogueID: carried.catalogID,
                                     rarity: carried.rarity,
                                     quantity: carried.count, identified: carried.identified,
                                     location: .carried,
                                     accessibilityName: carried.displayName)
                            .frame(width: 58, height: 58)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(carried.displayName).font(.headline).foregroundStyle(carried.rarity.tint)
                            Text("Carried in world").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                Section("Details") {
                    LabeledContent("Quantity", value: "\(carried.count)")
                    LabeledContent("Location", value: ItemGridLocation.carried.displayName)
                    if !carried.detail.isEmpty { Text(carried.detail) }
                    if let blurb = ContentCatalog.shared.item(carried.catalogID)?.blurb, !blurb.isEmpty {
                        Text(blurb)
                    }
                }
                Section {
                    Button(role: .destructive) {
                        swap()
                        dismiss()
                    } label: {
                        Text("Drop this and take \(offered.displayName)")
                    }
                }
            }
            .navigationTitle(carried.identified ? carried.displayName : "Unknown item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
    }
}
