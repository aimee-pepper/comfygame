import SwiftUI

// The remaining stations. Each one is reachable, saved, and shows the real state it owns; the
// *spending* half of each (identify, purchase, gambit editing, node buying) belongs to milestones
// 4–5 and is marked as such on screen rather than being silently absent.

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
                    }
                }

                StationCard(title: "Inventory — \(base.inventory.stacks.count) of \(base.inventory.slots)", icon: "archivebox") {
                    if base.inventory.stacks.isEmpty {
                        EmptyNote("Eight slots, all empty. Items come from worlds.")
                    } else {
                        ForEach(base.inventory.stacks) { stack in
                            let item = ContentCatalog.shared.item(stack.catalogID)
                            LabeledRow(icon: stack.identified ? (item?.icon ?? "questionmark") : "questionmark.diamond",
                                       label: stack.identified
                                           ? (item?.name ?? stack.catalogID.rawValue)
                                           : (item?.unidentifiedName ?? "Something unidentified"),
                                       value: stack.count > 1 ? "×\(stack.count)" : "")
                        }
                    }
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
                    LabeledRow(icon: "hammer.fill", label: "Weapon", value: "tier \(companion.weaponTier)")
                    LabeledRow(icon: "shield.fill", label: "Armor", value: "tier \(companion.armorTier)")
                }

                GambitEditor(owner: .companion)

                if store.state.base.hasAutomateSelfUnlock {
                    GambitEditor(owner: .binder)
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

/// The gambit editor. Drag to reorder; order is the whole game.
///
/// Lives here and nowhere else — gambit editing is out-of-combat only, a locked decision. The
/// editor is disabled outright mid-fight rather than merely hidden, so there's no route to it.
private struct GambitEditor: View {
    @EnvironmentObject private var store: GameStore
    @State private var isWriting = false
    let owner: Combatant

    private var gambits: [GambitRule] { store.gambits(for: owner) }
    private var slots: Int { store.activeGambitSlots }
    private var ownerName: String { owner == .binder ? "Your own rules" : "Quill's rules" }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("\(ownerName) — \(min(gambits.count, slots)) of \(slots) slots", systemImage: "list.number")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            Text("Checked top to bottom. The first rule that fits is the one that fires — so the order is the strategy.")
                .font(.caption)
                .foregroundStyle(.secondary)

            if gambits.isEmpty {
                EmptyNote(owner == .binder
                          ? "No rules written — you'll keep acting for yourself."
                          : "No rules written — Quill will stand there.")
            } else {
                // A real List, so drag-to-reorder is the system gesture rather than an imitation.
                List {
                    ForEach(Array(gambits.enumerated()), id: \.element.id) { index, rule in
                        GambitRow(index: index, rule: rule, isActive: index < slots)
                    }
                    .onMove { store.moveGambit(from: $0, to: $1, for: owner) }
                    .onDelete { store.removeGambit(at: $0, for: owner) }
                }
                .listStyle(.plain)
                .environment(\.editMode, .constant(.active))
                .frame(height: CGFloat(gambits.count) * 62 + 8)
                .scrollDisabled(true)
                .disabled(!store.canEditGambits)
            }

            Button { isWriting = true } label: {
                Label("Write a rule", systemImage: "plus.circle")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.bordered)
            .disabled(!store.canEditGambits)

            if gambits.count > slots {
                Text("Rules past slot \(slots) are written but idle. More slots come from Instruction research and the Constellation.")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
        .sheet(isPresented: $isWriting) {
            RuleBuilderView(owner: owner).environmentObject(store)
        }
    }
}

private struct GambitRow: View {
    let index: Int
    let rule: GambitRule
    let isActive: Bool

    var body: some View {
        HStack(spacing: 10) {
            Text("\(index + 1)")
                .font(.caption.monospacedDigit().weight(.bold))
                .foregroundStyle(.secondary)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 1) {
                Text(rule.displayText).font(.callout)
                if !isActive {
                    Text("no slot for this yet").font(.caption2).foregroundStyle(.orange)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(minHeight: 44)
        .opacity(isActive ? 1 : 0.5)
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

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.footnote).frame(width: 20).foregroundStyle(.tint)
            Text(label).font(.callout)
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
