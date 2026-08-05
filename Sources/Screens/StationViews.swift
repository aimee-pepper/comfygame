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
                            LabeledRow(icon: item?.icon ?? "questionmark",
                                       label: stack.identified
                                           ? (item?.name ?? stack.catalogID.rawValue)
                                           : (item?.unidentifiedName ?? "Something unidentified"),
                                       value: stack.count > 1 ? "×\(stack.count)" : "")
                        }
                    }
                }

                ComingLater("Identifying curios, and the key that opens a cache in another world, arrive in milestone 5.")
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
                CurrencyChip(icon: "drop.fill", label: "Essence", value: "\(store.state.base.essence)", tint: .teal)

                StationCard(title: "Researchable symbols", icon: "sparkle.magnifyingglass") {
                    ForEach(ContentCatalog.shared.symbols.filter { $0.acquisition == .research }) { symbol in
                        LabeledRow(icon: symbol.icon,
                                   label: symbol.name,
                                   value: "\(symbol.essenceCost) essence",
                                   isDimmed: !store.state.base.ownedSymbols.contains(symbol.id))
                    }
                }

                StationCard(title: "Purchasable gambit pieces", icon: "list.number") {
                    ForEach(ContentCatalog.shared.gambitPieces.filter { $0.acquisition == .research }) { piece in
                        LabeledRow(icon: piece.icon,
                                   label: piece.name,
                                   value: "\(piece.essenceCost) essence",
                                   isDimmed: !store.state.base.ownedGambitPieces.contains(piece.id))
                    }
                }

                ComingLater("Buying these — plus Storehouse tiers, companion gear and the \"automate self\" unlock — arrives in milestone 5.")
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

                StationCard(title: "Gambits — \(companion.gambits.count) of \(gambitSlots) slots", icon: "list.number") {
                    if companion.gambits.isEmpty {
                        EmptyNote("No rules set — the companion will do nothing.")
                    } else {
                        ForEach(Array(companion.gambits.enumerated()), id: \.offset) { index, id in
                            let piece = ContentCatalog.shared.gambitPiece(id)
                            LabeledRow(icon: piece?.icon ?? "questionmark",
                                       label: piece?.name ?? id.rawValue,
                                       value: "\(index + 1)")
                        }
                    }
                }

                ComingLater("Reordering rules by drag — the thing that visibly changes how the companion fights — arrives in milestone 4, alongside encounters.")
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Party")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var gambitSlots: Int {
        Tuning.Encounter.startingGambitSlots + store.state.reality.bonusGambitSlots
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
                    let rank = store.state.reality.rank(of: node.id)
                    StationCard(title: node.name, icon: node.icon) {
                        Text(node.blurb).font(.callout).foregroundStyle(.secondary)
                        LabeledRow(icon: "chart.bar", label: "Rank", value: "\(rank) of \(node.maxRank)")
                        LabeledRow(icon: "star", label: "Cost", value: "\(node.moteCostPerRank.first ?? 0) motes",
                                   isDimmed: rank >= node.maxRank)
                    }
                }

                ComingLater("These survive everything, including a future base reset. Spending motes on them arrives in milestone 5.")
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
