import SwiftUI

// The pieces that spend things: refining, upgrades, research, identification, Constellation nodes.
// Split out of StationViews so the station screens stay a readable table of contents.

/// Raw essence → essence. The join between what worlds give you and what the base runs on.
struct RefineryCard: View {
    @EnvironmentObject private var store: GameStore
    @State private var selectedRaw = 1

    private var raw: Int { store.state.base.resources[Resources.essenceRaw] }
    private var selected: Int { min(max(1, selectedRaw), max(1, raw)) }
    private var rate: Int { EconomyRules.refinementRate(in: store.state) }

    var body: some View {
        StationCard(title: "Refinery", icon: "flask") {
            LabeledRow(icon: "drop", label: "Raw essence held", value: "\(raw)")
            LabeledRow(icon: "arrow.right", label: "Active rate", value: "1 Raw → \(rate) Essence")

            Stepper(value: $selectedRaw, in: 1...max(1, raw)) {
                LabeledContent("Selected", value: raw == 0 ? "—" : "\(selected) Raw → \(selected * rate) Essence")
            }
            .frame(minHeight: 44)
            .disabled(raw == 0)

            HStack(spacing: 10) {
                Button {
                    if store.refineEssence(rawUnits: selected) {
                        selectedRaw = min(selectedRaw, max(1, raw))
                    }
                } label: {
                    RefineryActionLabel(
                        title: raw > 0 ? "Refine selected" : "Nothing to refine",
                        result: raw > 0 ? "\(selected * rate) Essence" : "—"
                    )
                }
                .buttonStyle(.borderedProminent)
                .disabled(raw == 0)

                Button { store.refineAllEssence() } label: {
                    RefineryActionLabel(title: "Refine all", result: "\(raw * rate) Essence")
                }
                .buttonStyle(.bordered)
                .disabled(raw == 0)
            }

            Text("The preview is exact. Only a confirmed conversion increases refining practice.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .onChange(of: raw) { _, value in selectedRaw = min(selectedRaw, max(1, value)) }
    }
}

private struct RefineryActionLabel: View {
    let title: String
    let result: String

    var body: some View {
        VStack(spacing: 1) {
            Text(title).font(.callout.weight(.semibold)).lineLimit(1)
            Text(result).font(.caption2).monospacedDigit().opacity(0.82)
        }
        .frame(maxWidth: .infinity, minHeight: 44)
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
                    CatalogueItemPixelIdentity(
                        itemID: stack.catalogID,
                        identified: stack.identified,
                        fallbackSystemIcon: stack.icon,
                        fallbackColor: stack.rarity.tint
                    )
                    .frame(width: 32, height: 32)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(stack.displayName).font(.callout).foregroundStyle(stack.rarity.tint)
                        Text(curio?.blurb ?? "").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 8)
                    Button {
                        revealed = store.identify(stack)
                    } label: {
                        Label {
                            Text("Identify · \(Tuning.Economy.identifyCostEssence)")
                                .monospacedDigit()
                        } icon: {
                            Image(systemName: "drop.fill")
                        }
                            .font(.caption.weight(.semibold))
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
        .alert("It's a \(revealed?.name ?? "") — \(revealed?.rarity.displayName ?? "")",
               isPresented: .constant(revealed != nil)) {
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

enum ConstellationNodePresentationState: Equatable, Sendable {
    case affordable
    case shortfall(missing: Int)
    case bought

    static func resolve(rank: Int, maxRank: Int, cost: Int?, motes: Int) -> Self {
        guard rank < maxRank, let cost else { return .bought }
        return motes >= cost ? .affordable : .shortfall(missing: cost - motes)
    }

    var label: String {
        switch self {
        case .affordable: "Ready to fix in place"
        case .shortfall(let missing): "Needs \(missing) more \(missing == 1 ? "Mote" : "Motes")"
        case .bought: "Fixed in place"
        }
    }
}

/// Anchored detail for the one live Reality purchase. It deliberately remains a local detail rather
/// than pretending the current one-node catalogue is a graph or full-width progression list.
struct ConstellationNodeDetail: View {
    @EnvironmentObject private var store: GameStore
    let node: ConstellationNodeDef
    @State private var confirmingPurchase = false
    @State private var purchaseFailure: String?

    var body: some View {
        let rank = store.state.reality.rank(of: node.id)
        let cost = store.moteCost(of: node)
        let state = ConstellationNodePresentationState.resolve(
            rank: rank, maxRank: node.maxRank, cost: cost, motes: store.state.reality.motes)

        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Label(node.name, systemImage: node.icon).font(.headline)
                Text(node.blurb).font(.callout)
                LabeledContent("Rank", value: "\(rank)/\(node.maxRank)")
                if let cost {
                    LabeledContent("Cost", value: "\(cost) Motes")
                }
                if cost == nil {
                    Label(state.label, systemImage: state.icon)
                        .font(.caption.weight(.semibold)).foregroundStyle(state.tint)
                }
                Divider()
                Text("The Constellation changes Reality itself, rather than one building or one person.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .padding(16)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if cost != nil {
                PersistentActionBar(message: state.label, messageTint: state.tint) {
                    Button("Fix in place") { confirmingPurchase = true }
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .buttonStyle(.borderedProminent)
                        .tint(.purple)
                        .disabled(!store.canBuy(node))
                }
            }
        }
        .confirmationDialog(
            "Fix \(node.name) in place?",
            isPresented: $confirmingPurchase,
            titleVisibility: .visible
        ) {
            if let cost {
                Button("Spend \(cost) Motes") {
                    if store.buy(node) {
                        purchaseFailure = nil
                    } else {
                        purchaseFailure = "Your Motes or this node's rank changed. Review the current cost before trying again."
                    }
                }
            }
            Button("Not yet", role: .cancel) {}
        } message: {
            Text("This permanently changes Reality for the current campaign.")
        }
        .alert("Constellation not changed", isPresented: Binding(
            get: { purchaseFailure != nil },
            set: { if !$0 { purchaseFailure = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(purchaseFailure ?? "The permanent purchase could not be completed.")
        }
        .frame(minWidth: 270)
    }
}

private extension ConstellationNodePresentationState {
    var icon: String {
        switch self {
        case .affordable: "checkmark.circle"
        case .shortfall: "circle.dashed"
        case .bought: "checkmark.seal.fill"
        }
    }

    var tint: Color {
        switch self {
        case .affordable, .bought: .purple
        case .shortfall: .secondary
        }
    }
}
