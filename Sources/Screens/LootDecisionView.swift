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
    @State private var confirmingLeave = false

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
                            guard case .allowed(let quote) = store.lootSwapQuote(
                                offered: offered, dropping: selected
                            ) else {
                                return .refused("The satchel changed. Review the current items and try again.")
                            }
                            return store.takeOffered(quote)
                        } onCommitted: { selectedCarried = nil }
                    }
                }

                Button(role: .destructive) {
                    confirmingLeave = true
                } label: {
                    Label("Leave it behind", systemImage: "xmark")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.bordered)
                .confirmationDialog(
                    "Leave \(offered.displayName) behind?",
                    isPresented: $confirmingLeave,
                    titleVisibility: .visible
                ) {
                    Button("Leave \(offered.displayName)", role: .destructive) {
                        store.leaveOffered(offered)
                    }
                    Button("Keep deciding", role: .cancel) {}
                } message: {
                    Text("You cannot recover it after leaving this decision.")
                }

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
    let swap: () -> CurrentStateCommitResult
    let onCommitted: () -> Void
    @State private var refusal: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(alignment: .top, spacing: 10) {
                        swapSummary(carried, role: "Drop", location: .carried)
                        Image(systemName: "arrow.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                            .frame(width: 18, height: 52)
                        swapSummary(offered, role: "Take", location: .offered)
                    }
                }
                Section("Known facts") {
                    HStack(alignment: .top, spacing: 12) {
                        knownFacts(carried, role: "Drop", location: .carried)
                        Divider()
                        knownFacts(offered, role: "Take", location: .offered)
                    }
                }
                if let refusal {
                    Section { Text(refusal).foregroundStyle(.red) }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button(role: .destructive) {
                    switch swap() {
                    case .committed:
                        onCommitted()
                        dismiss()
                    case .refused(let message):
                        refusal = message
                    }
                } label: {
                    Text("Drop this and take \(offered.displayName)")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.bar)
            }
            .navigationTitle(carried.identified ? carried.displayName : "Unknown item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
    }

    private func swapSummary(_ stack: ItemStack,
                             role: String,
                             location: ItemGridLocation) -> some View {
        HStack(spacing: 8) {
            ItemIconTile(icon: stack.icon, catalogueID: stack.catalogID,
                         rarity: stack.rarity,
                         quantity: stack.count, identified: stack.identified,
                         location: location,
                         accessibilityName: stack.displayName)
                .frame(width: 52, height: 52)
            VStack(alignment: .leading, spacing: 2) {
                Text(role)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(role == "Drop" ? Color.red : Color.green)
                Text(stack.displayName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(stack.rarity.tint)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func knownFacts(_ stack: ItemStack,
                            role: String,
                            location: ItemGridLocation) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(role)
                .font(.caption.weight(.bold))
                .foregroundStyle(role == "Drop" ? Color.red : Color.green)
            Text("\(location.displayName) · \(stack.count)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
            if !stack.detail.isEmpty {
                Text(stack.detail)
                    .font(.caption)
            }
            if let blurb = ContentCatalog.shared.item(stack.catalogID)?.blurb,
               !blurb.isEmpty {
                Text(blurb)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
