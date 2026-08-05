import SwiftUI

/// Compose a book, see what it will cost you and what it will become, then commit.
///
/// Layout follows the one-handed pillar: the slots and preview scroll, and the Bind button is
/// pinned to the bottom of the screen in the thumb zone where it can't scroll away.
struct WritingDeskView: View {
    @EnvironmentObject private var store: GameStore
    @State private var editingSlot: SymbolSlot?

    private var state: GameState { store.state }
    private var projection: BookProjection { store.bookProjection }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    slotGrid
                    PreviewPanel(projection: projection, discovery: state.reality.discovery)
                    if !projection.randomSlots.isEmpty { chanceNote }
                }
                .padding(16)
                .padding(.bottom, 8)
            }
            bindBar
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Writing Desk")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Clear") { store.clearBookDraft() }
                    .disabled(state.base.bookDraft.filledCount == 0)
            }
        }
        .sheet(item: $editingSlot) { slot in
            SymbolPickerView(slot: slot, chosen: state.base.bookDraft[slot]) { picked in
                store.setSymbol(picked, in: slot)
                editingSlot = nil
            }
            .environmentObject(store)
        }
    }

    // MARK: Slots

    private var slotGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            ForEach(projection.slotPlans) { plan in
                Button {
                    editingSlot = plan.slot
                } label: {
                    SlotCard(plan: plan)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var chanceNote: some View {
        Label {
            Text("Empty slots are filled at random when the book is bound. You see the range now; you find out where in it you landed when you arrive.")
        } icon: {
            Image(systemName: "dice")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: Bind

    private var bindBar: some View {
        VStack(spacing: 6) {
            Button {
                store.bindAndDepart()
            } label: {
                HStack {
                    Label("Bind & Depart", systemImage: "book.closed.fill")
                    Spacer()
                    Text(costLabel).monospacedDigit()
                }
                .font(.headline)
                .frame(minHeight: 56)
                .padding(.horizontal, 4)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!store.canBindAndDepart)

            Text(bindFootnote)
                .font(.caption)
                .foregroundStyle(store.canBindAndDepart ? Color.secondary : Color.orange)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(.bar)
    }

    private var costLabel: String {
        let cost = projection.essenceCost
        return cost.isPoint ? "\(cost.lowerBound)" : "\(cost.lowerBound)–\(cost.upperBound)"
    }

    private var bindFootnote: String {
        if !store.canBindAndDepart {
            return "You have \(state.base.essence) essence; this book could cost up to \(projection.maximumCost)."
        }
        if projection.essenceCost.isPoint {
            return "Costs \(projection.essenceCost.lowerBound) essence of your \(state.base.essence)."
        }
        return "You'll be charged what the finished book comes to — at most \(projection.maximumCost)."
    }
}

// MARK: - Slot card

private struct SlotCard: View {
    let plan: BookProjection.SlotPlan

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(plan.slot.displayName.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(plan.chosen == nil ? Color.secondary : Color.accentColor)
                    .frame(width: 26)
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(plan.chosen == nil ? .secondary : .primary)
                    .lineLimit(1)
            }

            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2, reservesSpace: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 92)
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(plan.chosen == nil ? Color.secondary.opacity(0.25) : Color.accentColor.opacity(0.5),
                              style: StrokeStyle(lineWidth: 1.5, dash: plan.chosen == nil ? [4, 3] : []))
        )
    }

    private var icon: String {
        if let chosen = plan.chosen { return chosen.icon }
        return plan.isEmpty ? "nosign" : "dice"
    }

    private var title: String {
        if let chosen = plan.chosen { return chosen.name }
        return plan.isEmpty ? "Nothing to draw on" : "Left to chance"
    }

    private var subtitle: String {
        if let chosen = plan.chosen { return chosen.blurb }
        if plan.isEmpty { return "You own no \(plan.slot.displayName.lowercased()) symbols yet." }
        return "One of \(plan.candidates.count), chosen when you bind."
    }
}

// MARK: - Symbol picker

private struct SymbolPickerView: View {
    @EnvironmentObject private var store: GameStore
    let slot: SymbolSlot
    let chosen: SymbolID?
    let onPick: (SymbolID?) -> Void

    @Environment(\.dismiss) private var dismiss

    private var owned: [SymbolDef] {
        BookRules.candidates(for: slot, ownedSymbols: store.state.base.ownedSymbols)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button { onPick(nil) } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "dice").frame(width: 26)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Leave to chance").font(.body)
                                Text("Filled at random when you bind").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if chosen == nil { Image(systemName: "checkmark").foregroundStyle(.tint) }
                        }
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                Section("Your \(slot.displayName.lowercased()) symbols") {
                    ForEach(owned) { symbol in
                        Button { onPick(symbol.id) } label: {
                            SymbolRow(symbol: symbol, isChosen: symbol.id == chosen)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle(slot.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

private struct SymbolRow: View {
    let symbol: SymbolDef
    let isChosen: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol.icon)
                .font(.body)
                .frame(width: 26)
                .foregroundStyle(.tint)

            VStack(alignment: .leading, spacing: 2) {
                Text(symbol.name).font(.body)
                Text(symbol.blurb).font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 10) {
                    Label("\(symbol.essenceCost)", systemImage: "drop")
                    InstabilityTag(weight: symbol.instabilityWeight)
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.top, 1)
            }

            Spacer(minLength: 8)
            if isChosen { Image(systemName: "checkmark").foregroundStyle(.tint) }
        }
        .frame(minHeight: 44)
        .contentShape(Rectangle())
    }
}

/// Instability is the whole risk/reward dial, so it gets its own read-at-a-glance treatment.
struct InstabilityTag: View {
    let weight: Double

    var body: some View {
        Label(text, systemImage: weight < 0 ? "shield" : "flame")
            .foregroundStyle(color)
    }

    private var text: String {
        if weight == 0 { return "steady" }
        return weight < 0 ? "stabilising \(formatted)" : "unstable +\(formatted)"
    }

    private var formatted: String { String(format: "%.1f", abs(weight)) }

    private var color: Color {
        switch weight {
        case ..<0: .green
        case 0: .secondary
        case 0..<1.5: .orange
        default: .red
        }
    }
}

extension SymbolSlot: Identifiable {
    public var id: String { rawValue }
}

#Preview {
    NavigationStack {
        WritingDeskView().environmentObject(GameStore(io: .temporary(name: "preview-desk")))
    }
}
