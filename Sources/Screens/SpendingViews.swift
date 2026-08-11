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
                    Image(systemName: stack.icon).frame(width: 22).foregroundStyle(stack.rarity.tint)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(stack.displayName).font(.callout).foregroundStyle(stack.rarity.tint)
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
                Label(state.label, systemImage: state.icon)
                    .font(.caption.weight(.semibold)).foregroundStyle(state.tint)
                if cost != nil {
                    Button("Fix in place") { _ = store.buy(node) }
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .buttonStyle(.borderedProminent)
                        .tint(.purple)
                        .disabled(!store.canBuy(node))
                }
                Divider()
                Text("The Constellation changes Reality itself, rather than one building or one person.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .padding(16)
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
