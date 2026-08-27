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
    let member: PartySlot
    @State private var selectedOption: GameStore.WearableGearOption?

    private var worn: EquippedPiece? { store.worn(slot, by: member) }
    var body: some View {
        ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Worn now").font(.headline)
                    if let worn, let definition = worn.definition {
                        tile(piece: worn, definition: definition, delta: nil, count: 1,
                             location: "Worn", enabled: true)
                    } else {
                        Text("Nothing worn.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .frame(minHeight: 44)
                    }
                    Text("Your \(slot.displayName.lowercased())").font(.headline)
                    let options = candidates
                    if options.isEmpty {
                        Text("You don't own another piece for this slot yet. Sites hold better gear — ruins especially.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(minHeight: 44)
                    }
                    SixAcrossItemGrid(data: options, id: \.id) { option in
                        AnchoredItemDetailButton(item: option, selection: $selectedOption) {
                            ItemIconTile(icon: option.piece.definition?.icon ?? "questionmark",
                                         catalogueID: option.piece.catalogID,
                                         rarity: option.piece.definition?.rarity ?? .common,
                                         quantity: option.count, identified: true,
                                         location: gridLocation(of: option),
                                         accessibilityName: option.piece.displayName,
                                         isEnabled: option.canEquipAtHome)
                                .opacity(isWornByAnotherCharacter(option) ? 0.55 : 1)
                                .overlay {
                                    if isWornByAnotherCharacter(option) {
                                        RoundedRectangle(cornerRadius: 9)
                                            .stroke(style: StrokeStyle(lineWidth: 1.5,
                                                                       dash: [5, 3]))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                        } detail: { selected in
                            GearOptionDetailPane(
                                option: selected, slot: slot, location: location(of: selected),
                                worn: worn,
                                delta: store.gearDelta(wearing: selected.piece, for: member),
                                equip: { store.equip(selected, on: member) })
                        }
                    }

                    if worn != nil {
                        Button("Take it off", role: .destructive) {
                            store.unequip(slot, from: member)
                            dismiss()
                        }
                        .frame(minHeight: 44)
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
            }
            .navigationTitle(slot.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
    }

    /// **Every distinct piece on the shelf, best first, with how many of it you have.**
    ///
    /// Bins are per (piece, upgrade level), so four identical guards are one row saying ×4 and a
    /// reforged one is its own row — which is exactly what makes "give the best to me and the
    /// second best to Quill" a choice you can make (Aimee, 6 Aug). Nothing is filtered out for
    /// being worn by somebody else: if you have four, you can wear four.
    private var candidates: [GameStore.WearableGearOption] {
        store.wearableOptions(in: slot, excluding: member)
            .sorted {
                let lhsWorn = isWornByAnotherCharacter($0)
                let rhsWorn = isWornByAnotherCharacter($1)
                if lhsWorn != rhsWorn { return !lhsWorn }
                return $0.piece.effectivePower > $1.piece.effectivePower
            }
    }

    private func isWornByAnotherCharacter(_ option: GameStore.WearableGearOption) -> Bool {
        if case .worn = option.source { return true }
        return false
    }

    private func location(of option: GameStore.WearableGearOption) -> String {
        switch option.source {
        case .stored: "Stored"
        case .overflow: "Waiting to sort"
        case .worn(let owner): "Worn by \(store.name(of: owner))"
        case .carried: "Carried in world"
        }
    }

    private func gridLocation(of option: GameStore.WearableGearOption) -> ItemGridLocation {
        switch option.source {
        case .stored: .stored
        case .overflow: .waiting
        case .worn: .worn
        case .carried: .carried
        }
    }

    private func tile(piece: EquippedPiece, definition: ItemDef?, delta: Int?, count: Int,
                      location: String, enabled: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                CatalogueItemPixelIdentity(
                    itemID: piece.catalogID,
                    identified: true,
                    fallbackSystemIcon: definition?.icon ?? "questionmark",
                    fallbackColor: definition?.rarity.tint ?? .secondary
                )
                .frame(width: 32, height: 32)
                Spacer()
                Text(location)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(enabled ? Color.secondary : Color.orange)
            }
            VStack(alignment: .leading, spacing: 3) {
                // Rarity reads as the colour of the name — the ladder from the design brief.
                HStack(spacing: 6) {
                    Text(piece.displayName)
                        .font(.callout.weight(.medium))
                        .foregroundStyle(definition?.rarity.tint ?? .primary)
                    // How many of this exact piece you hold, so "the best one to me, the next to
                    // Quill" is a decision you can see rather than guess at.
                    if count > 1 {
                        Text("×\(count)").font(.caption2.monospacedDigit()).foregroundStyle(.secondary)
                    }
                }
                Text(definition.flatMap(damageLine) ?? definition?.blurb ?? "Unknown equipment")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            if let delta {
                ImprovementBadge(delta: delta, slot: slot)
            } else {
                Text("worn").font(.caption2).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
        .padding(12)
        .background(.secondary.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.secondary.opacity(0.18)))
        .contentShape(RoundedRectangle(cornerRadius: 14))
        .opacity(enabled ? 1 : 0.72)
    }

    /// A weapon's corner and reach, because that's the matchup read — a blurb won't tell you
    /// whether this is any use against the plated thing you keep meeting.
    private func damageLine(_ definition: ItemDef) -> String? {
        guard let gear = definition.gear, let damage = gear.damage else { return nil }
        let reach = gear.reach == .close ? "" : " · \(GearPresentationCopy.reach(gear.reach)) reach"
        return "\(GearPresentationCopy.damage(damage))\(reach)"
    }
}

private struct GearOptionDetailPane: View {
    @Environment(\.dismiss) private var dismiss
    let option: GameStore.WearableGearOption
    let slot: GearSlot
    let location: String
    let worn: EquippedPiece?
    let delta: Int
    let equip: () -> Bool

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        ItemIconTile(icon: option.piece.definition?.icon ?? "questionmark",
                                     catalogueID: option.piece.catalogID,
                                     rarity: option.piece.definition?.rarity ?? .common,
                                     quantity: option.count, identified: true,
                                     location: gridLocation,
                                     accessibilityName: option.piece.displayName)
                            .frame(width: 52, height: 52)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(location)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("Power \(power(option.piece))")
                                .font(.callout.monospacedDigit())
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Compared with worn")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        comparisonRow("Worn now", worn?.displayName ?? "Nothing",
                                      power: worn.map(power))
                        comparisonRow("This piece", option.piece.displayName,
                                      power: power(option.piece))
                        ImprovementBadge(delta: delta, slot: slot)
                    }
                    .padding(12)
                    .background(.secondary.opacity(0.10),
                                in: RoundedRectangle(cornerRadius: 12))

                    if let profile = option.piece.gearProfile {
                        Text("\(GearPresentationCopy.quality(profile)) · Reforge \(profile.reforgeRank)/\(SmithRules.maximumReforgeLevel)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let provenance = option.piece.gearProfile?.displayProvenance {
                        Text(provenance)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
            }
            .padding(12)
            Spacer(minLength: 0)

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Button("Equip") {
                    if equip() { dismiss() }
                }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .disabled(!option.canEquipAtHome)
                if !option.canEquipAtHome {
                    Text("Carried gear can be changed after you return home.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
        }
        .frame(minWidth: 280, idealWidth: 320, maxWidth: 340,
               minHeight: 320, idealHeight: 380, maxHeight: 440)
    }

    private func power(_ piece: EquippedPiece) -> String {
        String(format: "%.1f", piece.effectivePower)
    }

    private func comparisonRow(_ label: String, _ name: String, power: String?) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(label).font(.caption)
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 1) {
                Text(name).font(.caption.weight(.medium)).lineLimit(1)
                if let power { Text("Power \(power)").font(.caption2.monospacedDigit()) }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var gridLocation: ItemGridLocation {
        switch option.source {
        case .stored: .stored
        case .overflow: .waiting
        case .worn: .worn
        case .carried: .carried
        }
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
