import SwiftUI

/// Choosing what to wear, and being told whether it's better.
///
/// Gear is **found, never researched** (decisions-session-12), so this is a picker over what you've
/// hauled home — and the thing it most has to answer is the question you actually have standing in
/// front of it: *is this an improvement?* A tier number doesn't answer that unless you already know
/// the formula, so every option states the difference it would make in the units the fight uses.
struct GearView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss
    let slot: GearSlot
    let member: PartyMember

    private var worn: ItemDef? {
        store.worn(slot, by: member).flatMap { ContentCatalog.shared.item($0) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if let worn {
                        row(for: nil, definition: worn, isWorn: true)
                    } else {
                        Text("Nothing worn.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .frame(minHeight: 44)
                    }
                } header: {
                    Text("Worn")
                }

                Section {
                    let options = candidates
                    if options.isEmpty {
                        Text("Nothing else to wear. Sites hold the better pieces — ruins especially.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(minHeight: 44)
                    }
                    ForEach(options, id: \.stack.id) { option in
                        Button {
                            store.equip(option.stack, on: member)
                            dismiss()
                        } label: {
                            row(for: option.stack, definition: option.definition, isWorn: false)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("In the storehouse")
                }

                if worn != nil {
                    Section {
                        Button("Take it off", role: .destructive) {
                            store.unequip(slot, from: member)
                            dismiss()
                        }
                        .frame(minHeight: 44)
                    }
                }
            }
            .navigationTitle(slot.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    /// Everything wearable in this slot, best first — so the thing you probably want is at the top
    /// rather than wherever it happened to land in the satchel.
    private var candidates: [(stack: ItemStack, definition: ItemDef)] {
        store.wearable(in: slot)
            .filter { $0.catalogID != worn?.id }
            .compactMap { stack in
                ContentCatalog.shared.item(stack.catalogID).map { (stack, $0) }
            }
            .sorted { ($0.definition.gear?.tier ?? 0) > ($1.definition.gear?.tier ?? 0) }
    }

    private func row(for stack: ItemStack?, definition: ItemDef, isWorn: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: definition.icon)
                .foregroundStyle(definition.rarity.tint)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 1) {
                // Rarity reads as the colour of the name — the ladder from the design brief.
                Text(definition.name)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(definition.rarity.tint)
                Text(definition.blurb)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 6)
            if isWorn {
                Text("worn")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                ImprovementBadge(delta: store.gearDelta(wearing: definition, for: member), slot: slot)
            }
        }
        .frame(minHeight: 44)
        .contentShape(Rectangle())
    }
}

/// Says, in one chip, whether putting this on is a good idea.
struct ImprovementBadge: View {
    let delta: Int
    let slot: GearSlot

    private var unit: String { slot == .weapon ? "damage" : "protection" }

    var body: some View {
        if delta > 0 {
            label("+\(delta) \(unit)", .green)
        } else if delta < 0 {
            label("\(delta) \(unit)", .red)
        } else {
            label("no change", .secondary)
        }
    }

    private func label(_ text: String, _ tint: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.medium))
            .foregroundStyle(tint)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(tint.opacity(0.14), in: Capsule())
    }
}
