import SwiftUI

// The pieces that spend things: refining, upgrades, research, identification, Constellation nodes.
// Split out of StationViews so the station screens stay a readable table of contents.

/// Raw essence → essence. The join between what worlds give you and what the base runs on.
struct RefineryCard: View {
    @EnvironmentObject private var store: GameStore

    private var raw: Int { store.state.base.resources[Resources.essenceRaw] }

    var body: some View {
        StationCard(title: "Refinery", icon: "flask") {
            LabeledRow(icon: "drop", label: "Raw essence held", value: "\(raw)")
            LabeledRow(icon: "arrow.right", label: "Refines into",
                       value: "\(EconomyRules.refine(rawUnits: raw)) essence")

            Button {
                store.refineAllEssence()
            } label: {
                Label(raw > 0 ? "Refine all" : "Nothing to refine", systemImage: "flame")
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
            }
            .buttonStyle(.bordered)
            .disabled(raw == 0)

            Text("Worlds give you raw essence. The base runs on refined. This is where one becomes the other.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

/// One Workshop upgrade, showing what it costs and — when you can't afford it — what you're short of.
struct UpgradeRow: View {
    @EnvironmentObject private var store: GameStore
    let upgrade: UpgradeDef

    var body: some View {
        let rank = store.rank(of: upgrade)
        let cost = store.nextCost(of: upgrade)
        let missing = store.shortfall(for: upgrade)

        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Image(systemName: upgrade.icon).frame(width: 22).foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 1) {
                    Text(upgrade.name).font(.callout.weight(.medium))
                    Text(upgrade.blurb).font(.caption).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                Text(rank >= upgrade.maxRank ? "max" : "\(rank)/\(upgrade.maxRank)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            if let cost {
                Button {
                    store.buy(upgrade)
                } label: {
                    HStack {
                        Text(costText(cost)).font(.footnote.monospacedDigit())
                        Spacer()
                        Text(missing.isEmpty ? "Buy" : "Need \(missing.joined(separator: ", "))")
                            .font(.footnote.weight(.semibold))
                    }
                    .frame(minHeight: 44)
                    .padding(.horizontal, 10)
                }
                .buttonStyle(.bordered)
                .tint(missing.isEmpty ? .accentColor : .secondary)
                .disabled(!missing.isEmpty)
            }
        }
        .padding(.vertical, 4)
    }

    private func costText(_ cost: UpgradeCost) -> String {
        var parts: [String] = []
        if cost.essence > 0 { parts.append("\(cost.essence) essence") }
        for (id, amount) in cost.resources.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            parts.append("\(amount) \(ContentCatalog.shared.resource(id)?.name.lowercased() ?? id.rawValue)")
        }
        return parts.joined(separator: " · ")
    }
}

/// A one-off purchase: a researched symbol, or a gambit piece.
struct PurchaseRow: View {
    let icon: String
    let name: String
    let detail: String
    let cost: String
    let isOwned: Bool
    let canBuy: Bool
    let action: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon).frame(width: 22).foregroundStyle(isOwned ? Color.secondary : Color.accentColor)
            VStack(alignment: .leading, spacing: 1) {
                Text(name).font(.callout)
                Text(detail).font(.caption).foregroundStyle(.secondary).lineLimit(2)
            }
            Spacer(minLength: 8)
            if isOwned {
                Text("owned").font(.caption).foregroundStyle(.secondary)
            } else {
                Button(action: action) {
                    Text(cost).font(.caption.weight(.semibold)).monospacedDigit()
                        .frame(minHeight: 44)
                        .padding(.horizontal, 10)
                }
                .buttonStyle(.bordered)
                .disabled(!canBuy)
            }
        }
        .frame(minHeight: 44)
        .opacity(isOwned ? 0.55 : 1)
    }
}

/// Identify curios at the Storehouse.
///
/// The small rehearsal for the writing system's per-component compound identification: you paid to
/// find out what a thing you were already carrying actually is.
struct IdentifyCard: View {
    @EnvironmentObject private var store: GameStore
    @State private var revealed: ItemDef?

    var body: some View {
        StationCard(title: "Unidentified", icon: "questionmark.diamond") {
            ForEach(store.unidentifiedStacks) { stack in
                let curio = ContentCatalog.shared.item(stack.catalogID)
                HStack(spacing: 10) {
                    Image(systemName: "questionmark.diamond").frame(width: 22).foregroundStyle(.tint)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(curio?.unidentifiedName ?? "Something odd").font(.callout)
                        Text(curio?.blurb ?? "").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 8)
                    Button {
                        revealed = store.identify(stack)
                    } label: {
                        Text("\(Tuning.Economy.identifyCostEssence)")
                            .font(.caption.weight(.semibold)).monospacedDigit()
                            .frame(minHeight: 44)
                            .padding(.horizontal, 12)
                    }
                    .buttonStyle(.bordered)
                    .disabled(!store.canAffordIdentify)
                }
                .frame(minHeight: 44)
            }

            Text(store.canAffordIdentify
                 ? "Identifying costs \(Tuning.Economy.identifyCostEssence) essence."
                 : "Not enough essence to identify anything.")
                .font(.caption)
                .foregroundStyle(store.canAffordIdentify ? Color.secondary : Color.orange)
        }
        .alert("It's a \(revealed?.name ?? "")", isPresented: .constant(revealed != nil)) {
            Button("Oh") { revealed = nil }
        } message: {
            Text(revealedMessage)
        }
    }

    private var revealedMessage: String {
        guard let revealed else { return "" }
        return revealed.kind == .key
            ? "\(revealed.blurb)\n\nCarry it. Somewhere out there is a lock it fits."
            : revealed.blurb
    }
}

/// A Constellation node — the Reality layer's only spend.
struct ConstellationNodeCard: View {
    @EnvironmentObject private var store: GameStore
    let node: ConstellationNodeDef

    var body: some View {
        let rank = store.state.reality.rank(of: node.id)
        let cost = store.moteCost(of: node)

        StationCard(title: node.name, icon: node.icon) {
            Text(node.blurb).font(.callout).foregroundStyle(.secondary)
            LabeledRow(icon: "chart.bar", label: "Rank", value: "\(rank) of \(node.maxRank)")

            if let cost {
                Button {
                    store.buy(node)
                } label: {
                    HStack {
                        Label("\(cost) motes", systemImage: "star.fill")
                        Spacer()
                        Text(store.canBuy(node) ? "Fix it in place" : "Not enough motes")
                            .font(.footnote.weight(.semibold))
                    }
                    .frame(minHeight: 44)
                    .padding(.horizontal, 10)
                }
                .buttonStyle(.bordered)
                .tint(store.canBuy(node) ? .purple : .secondary)
                .disabled(!store.canBuy(node))
            } else {
                Text("Bought. Permanently.").font(.caption).foregroundStyle(.purple)
            }
        }
    }
}
