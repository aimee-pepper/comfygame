import SwiftUI

// The remaining stations. Each one is reachable, saved, and shows the real state it owns; the
// *spending* half of each (identify, purchase, gambit editing, node buying) belongs to milestones
// 4–5 and is marked as such on screen rather than being silently absent.

/// What came home to a full Storehouse and is waiting to be sorted.
///
/// Banking never discards (Q10). The decision lands *here*, at home, with everything visible —
/// as opposed to the satchel decision, which belongs in the world while the walls are closing in.
private struct SpilloverCard: View {
    @EnvironmentObject private var store: GameStore
    @State private var swapping: ItemStack?

    var body: some View {
        StationCard(title: "Waiting to be sorted — \(store.spillover.count)", icon: "tray.full") {
            Text("Your Storehouse was full when this came home. Nothing was thrown away.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(store.spillover) { stack in
                VStack(alignment: .leading, spacing: 8) {
                    LabeledRow(icon: stack.icon,
                               label: stack.displayName,
                               value: stack.detail,
                               tint: stack.rarity.tint)
                    HStack(spacing: 8) {
                        if store.state.base.inventory.isFull {
                            Button("Make room") { swapping = stack }
                                .buttonStyle(.borderedProminent)
                                .frame(minHeight: 44)
                        } else {
                            Button("Store it") { store.storeSpilled(stack) }
                                .buttonStyle(.borderedProminent)
                                .frame(minHeight: 44)
                        }
                        Button("Throw away", role: .destructive) { store.discardSpilled(stack) }
                            .frame(minHeight: 44)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .sheet(item: $swapping) { spilled in
            SwapSheet(spilled: spilled)
        }
    }
}

/// Full Storehouse: pick what the new thing replaces. The thing it replaces goes back to the
/// spillover rather than being destroyed — still nothing lost without being asked.
private struct SwapSheet: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss
    let spilled: ItemStack

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledRow(icon: spilled.icon, label: spilled.displayName,
                               value: "", tint: spilled.rarity.tint)
                } header: {
                    Text("Making room for")
                }
                Section {
                    ForEach(store.state.base.inventory.stacks) { stored in
                        Button {
                            store.swapSpilled(spilled, for: stored)
                            dismiss()
                        } label: {
                            LabeledRow(icon: stored.icon, label: stored.displayName,
                                       value: stored.detail,
                                       tint: stored.rarity.tint)
                        }
                        .frame(minHeight: 44)
                    }
                } header: {
                    Text("Replaces")
                } footer: {
                    Text("Whatever you replace goes back to the waiting pile. Nothing is thrown away here.")
                }
            }
            .navigationTitle("Make room")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

/// Storehouse — inventory and identification. Identify flow is milestone 5.
struct StorehouseView: View {
    @EnvironmentObject private var store: GameStore

    private var base: BaseState { store.state.base }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                StationCard(title: "Stockpiles", icon: "shippingbox") {
                    if base.resources.isEmpty {
                        EmptyNote("Nothing hauled home yet.")
                    } else {
                        ForEach(base.resources.nonZero, id: \.id) { entry in
                            let resource = ContentCatalog.shared.resource(entry.id)
                            LabeledRow(icon: resource?.icon ?? "cube",
                                       label: resource?.name ?? entry.id.rawValue,
                                       value: "\(entry.amount)")
                        }
                        if base.resources[Resources.essenceRaw] > 0 {
                            // Raw essence looks like currency and isn't. Say so here rather than
                            // letting someone stare at a full storehouse and an unaffordable book.
                            Text("Raw essence can't be written with — refine it at the Workshop first.")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }

                StationCard(title: "Inventory — \(base.inventory.stacks.count) of \(base.inventory.slots)", icon: "archivebox") {
                    if base.inventory.stacks.isEmpty {
                        EmptyNote("Eight slots, all empty. Items come from worlds.")
                    } else {
                        ForEach(base.inventory.stacks) { stack in
                            // Rarity reads as the colour of the name (design brief's colour-coded
                            // ladder), so a Mythic is obvious at a glance in a long list.
                            LabeledRow(icon: stack.icon,
                                       label: stack.displayName,
                                       value: stack.detail,
                                       tint: stack.rarity.tint)
                        }
                    }
                }

                if !store.spillover.isEmpty {
                    SpilloverCard()
                }

                if !store.unidentifiedStacks.isEmpty {
                    IdentifyCard()
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Storehouse")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Workshop — spending. Purchases are milestone 5.
struct WorkshopView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    CurrencyChip(icon: "drop.fill", label: "Essence", value: "\(store.state.base.essence)", tint: .teal)
                    CurrencyChip(icon: "cube", label: "Ore", value: "\(store.state.base.resources[Resources.ore])")
                    CurrencyChip(icon: "scribble", label: "Fiber", value: "\(store.state.base.resources[Resources.fiber])")
                }

                RefineryCard()

                ResearchTree()
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Workshop")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// One equipment slot on the Party screen: what's worn, and whether something better is waiting.
private struct GearSlotRow: View {
    @EnvironmentObject private var store: GameStore
    @State private var isChoosing = false
    let slot: GearSlot

    private var worn: ItemDef? {
        store.state.base.companion.equipped[slot].flatMap { ContentCatalog.shared.item($0) }
    }

    var body: some View {
        Button { isChoosing = true } label: {
            HStack(spacing: 10) {
                Image(systemName: worn?.icon ?? slot.icon)
                    .foregroundStyle(worn?.rarity.tint ?? Color.secondary)
                    .frame(width: 22)
                VStack(alignment: .leading, spacing: 0) {
                    Text(worn?.name ?? slot.displayName)
                        .foregroundStyle(worn == nil ? Color.secondary : worn!.rarity.tint)
                    if let worn, let tier = worn.gear?.tier {
                        Text("tier \(tier)").font(.caption2).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                // The nudge: a better piece sitting unworn in the Storehouse should not be
                // something you have to go looking for.
                if store.hasUpgradeAvailable(for: slot) {
                    Text("something better")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.green)
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(Color.green.opacity(0.14), in: Capsule())
                }
                Image(systemName: "chevron.right")
                    .font(.caption2).foregroundStyle(.tertiary)
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $isChoosing) {
            GearView(slot: slot).environmentObject(store)
        }
    }
}

/// Party — companion, gear and (from milestone 4) the gambit editor.
/// Gambit editing happens *only* here, never inside an encounter. Locked decision.
struct PartyView: View {
    @EnvironmentObject private var store: GameStore

    private var companion: CompanionState { store.state.base.companion }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                StationCard(title: "Satchel", icon: "bag") {
                    LabeledRow(icon: "square.grid.2x2", label: "Carried into a world",
                               value: "\(store.state.base.satchelCapacity) slots")
                    LabeledRow(icon: "house", label: "Stored at home",
                               value: "\(store.state.base.inventory.slots) slots")
                    Text("Your satchel is smaller than your storehouse on purpose — what you can carry back is its own decision.")
                        .font(.caption).foregroundStyle(.secondary)
                }

                StationCard(title: companion.name, icon: "person.fill") {
                    LabeledRow(icon: "heart.fill", label: "Health", value: "\(companion.maxHP)")
                    ForEach(GearSlot.allCases, id: \.self) { slot in
                        GearSlotRow(slot: slot)
                    }
                }

                GambitEditorView(owner: .companion)

                if store.state.base.hasAutomateSelfUnlock {
                    GambitEditorView(owner: .binder)
                } else {
                    ComingLater("Writing your own hand is studied under Instruction at the Workshop. Until then you act for yourself every turn.")
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Party")
        .navigationBarTitleDisplayMode(.inline)
    }

}


/// Constellation — the Reality layer's only screen. Buying nodes is milestone 5.
struct ConstellationView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                CurrencyChip(icon: "star.fill", label: "Motes", value: "\(store.state.reality.motes)", tint: .purple)

                ForEach(ContentCatalog.shared.constellationNodes) { node in
                    ConstellationNodeCard(node: node)
                }

                Label {
                    Text("These survive everything, including a future reset. Nothing else you buy does.")
                } icon: {
                    Image(systemName: "infinity")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Constellation")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Essence Spring — the trickle credited on each return from a run.
struct EssenceSpringView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                StationCard(title: "The Spring", icon: "drop.circle") {
                    LabeledRow(icon: "arrow.down.circle", label: "Yield per return home",
                               value: "\(store.essenceSpringYield) essence")
                    LabeledRow(icon: "chart.bar", label: "Tier",
                               value: "\(store.state.base.station(Stations.essenceSpring).tier)")
                }

                Label {
                    Text("The Spring fills when you come home — never while the app is closed. Nothing in this game moves without you.")
                } icon: {
                    Image(systemName: "moon.zzz")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))

                ComingLater("The tier 2 upgrade is bought at the Workshop in milestone 5.")
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Essence Spring")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Shared pieces

struct StationCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}

struct LabeledRow: View {
    let icon: String
    let label: String
    var value: String = ""
    var isDimmed: Bool = false
    /// Colours the label. Used for the rarity ladder — an item's rarity IS the colour of its name.
    var tint: Color?

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.footnote).frame(width: 20)
                .foregroundStyle(tint ?? Color.accentColor)
            Text(label).font(.callout).foregroundStyle(tint ?? Color.primary)
            Spacer(minLength: 8)
            Text(value).font(.callout.monospacedDigit()).foregroundStyle(.secondary)
        }
        .frame(minHeight: 30)
        .opacity(isDimmed ? 0.45 : 1)
    }
}

struct EmptyNote: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text).font(.callout).foregroundStyle(.secondary)
    }
}

/// Honest placeholder: says what's missing and when it lands, instead of a dead button.
struct ComingLater: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Label { Text(text) } icon: { Image(systemName: "hammer") }
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 12))
    }
}
