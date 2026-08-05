import SwiftUI

/// Compose a book, see what it will cost you and what it will become, then commit.
///
/// Layout follows the one-handed pillar: the slots and preview scroll, and the Bind button is
/// pinned to the bottom of the screen in the thumb zone where it can't scroll away.
struct WritingDeskView: View {
    @EnvironmentObject private var store: GameStore
    @State private var editingSlot: SlotID?
    /// The mark the next tap on the page will write.
    @State private var pending: SymbolID?

    private var state: GameState { store.state }
    private var projection: BookProjection { store.bookProjection }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    PageGridView(pending: pending)
                    palette
                    PreviewPanel(projection: projection, discovery: state.reality.discovery)
                    if state.base.page.runes.isEmpty { blankPageNote }
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
                Button("Clear") { store.clearPage() }
                    .disabled(state.base.page.runes.isEmpty)
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

    // MARK: The palette

    /// What you know how to write. Selecting one arms the page; tapping a cell places it.
    ///
    /// Deliberately shows the footprint: what a mark *costs in space* is the decision the page
    /// exists to create, and it changes with the hand you're writing in.
    private var palette: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What you can write")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 8)], spacing: 8) {
                ForEach(ownedSymbols) { symbol in
                    let fits = store.canWrite(symbol.id)
                    Button {
                        pending = (pending == symbol.id) ? nil : symbol.id
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: symbol.icon)
                            VStack(alignment: .leading, spacing: 0) {
                                Text(symbol.name).font(.caption.weight(.medium)).lineLimit(1)
                                Text("\(store.footprint(of: symbol.id)) cells")
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 0)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(minHeight: 44)
                        .padding(.horizontal, 8)
                    }
                    .buttonStyle(.bordered)
                    .tint(pending == symbol.id ? .accentColor : .secondary)
                    .opacity(fits ? 1 : 0.45)
                    .disabled(!fits)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var ownedSymbols: [SymbolDef] {
        ContentCatalog.shared.symbols
            .filter { state.base.ownedSymbols.contains($0.id) }
            .sorted { $0.name < $1.name }
    }

    private var blankPageNote: some View {
        Text("A blank page still binds. Everything you don't say, the world decides for itself.")
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Slots — the old taxonomy, no longer the composition surface

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
            Text("Empty slots are filled at random when the book is bound, and cost a flat \(Tuning.Book.randomSlotCostEssence) each however they roll. You know the price now; you find out what you bought when you arrive.")
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

    private var costLabel: String { "\(projection.cost)" }

    private var bindFootnote: String {
        if !store.canBindAndDepart {
            if store.needsToRefine {
                let raw = state.base.resources[Resources.essenceRaw]
                return "You have \(state.base.essence) essence and \(raw) raw. Refine it at the Workshop — raw essence can't be written with."
            }
            return "You have \(state.base.essence) essence; this book costs \(projection.cost). Leave slots to chance to write something cheaper."
        }
        let count = projection.randomSlots.count
        if count > 0 {
            return "Costs \(projection.cost) of your \(state.base.essence) — including \(count) slot\(count == 1 ? "" : "s") left to chance at \(Tuning.Book.randomSlotCostEssence) each."
        }
        return "Costs \(projection.cost) essence of your \(state.base.essence)."
    }
}

// MARK: - Slot card

private struct SlotCard: View {
    let plan: BookProjection.SlotPlan

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(slotName.uppercased())
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

    private var slotName: String {
        ContentCatalog.shared.slot(plan.slot)?.name ?? plan.slot.rawValue
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
        if plan.isEmpty { return "Nothing could fill this." }
        return "Any of \(plan.candidates.count) — including things you can't write yet."
    }
}

// MARK: - Symbol picker

private struct SymbolPickerView: View {
    @EnvironmentObject private var store: GameStore
    let slot: SlotID
    let chosen: SymbolID?
    let onPick: (SymbolID?) -> Void

    @Environment(\.dismiss) private var dismiss

    private var owned: [SymbolDef] {
        BookRules.writable(in: slot, ownedSymbols: store.state.base.ownedSymbols)
    }

    private var slotName: String {
        ContentCatalog.shared.slot(slot)?.name ?? slot.rawValue
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

                Section("Your \(slotName.lowercased()) symbols") {
                    ForEach(owned) { symbol in
                        Button { onPick(symbol.id) } label: {
                            SymbolRow(symbol: symbol, isChosen: symbol.id == chosen)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle(slotName)
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
                    StabilityTag(delta: symbol.stabilityDelta)
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

/// Stability is the whole risk/reward dial, and this prints it **in the same units as the
/// headline** — pick this symbol and the Stability number moves by exactly this much. Anything
/// else turns composing a book into guesswork.
struct StabilityTag: View {
    let delta: Int

    var body: some View {
        Label(text, systemImage: delta > 0 ? "shield" : (delta == 0 ? "equal" : "flame"))
            .foregroundStyle(color)
    }

    private var text: String {
        switch delta {
        case 0: "no cost"
        case 1...: "+\(delta) stability"
        default: "\(delta) stability" // already carries its minus sign
        }
    }

    private var color: Color {
        switch delta {
        case 1...: .green
        case 0: .secondary
        case (-20)...(-1): .orange
        default: .red
        }
    }
}

#Preview {
    NavigationStack {
        WritingDeskView().environmentObject(GameStore(io: .temporary(name: "preview-desk")))
    }
}
