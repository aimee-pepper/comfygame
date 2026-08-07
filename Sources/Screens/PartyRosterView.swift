import SwiftUI

/// Who's in the party, at a glance.
///
/// Aimee, 6 Aug: *"it's really chaotic to have the gear and gambits for everyone all on one page.
/// I should be able to see a view of the characters in the party with thumbnail and brief stats and
/// then on clicking them see the equip and gambit tab pages for them on an individual character
/// page. I should be able to swipe to other characters."*
///
/// She's right, and it gets worse rather than better: one page held two people's eight gear slots
/// and two rule lists, and the party is heading for five.
struct PartyRosterView: View {
    @EnvironmentObject private var store: GameStore
    @State private var opened: PartySlot?

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                StationCard(title: "Satchel", icon: "bag") {
                    LabeledRow(icon: "square.grid.2x2", label: "Carried into a world",
                               value: "\(store.state.base.satchelCapacity) slots")
                    LabeledRow(icon: "house", label: "Stored at home",
                               value: "\(store.state.base.inventory.slots) slots")
                }

                ForEach(store.partySlots) { slot in
                    Button { opened = slot } label: { card(slot) }
                        .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Party")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $opened) { slot in
            CharacterPager(start: slot).environmentObject(store)
        }
    }

    /// Thumbnail and brief stats. Enough to choose who to open, and nothing more.
    private func card(_ slot: PartySlot) -> some View {
        let character = store.character(of: slot)
        let isComing = slot.combatant(activeCompanion: store.state.base.activeCompanion) != nil
        return StationCard(title: store.name(of: slot), icon: icon(slot)) {
            HStack(spacing: 14) {
                statChip("Level", "\(character.level)")
                statChip("Health", "\(health(slot))")
                statChip("Rank", character.rank.displayName)
                Spacer(minLength: 0)
                if isComing {
                    Text("with you")
                        .font(.caption2.weight(.medium)).foregroundStyle(.green)
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(Color.green.opacity(0.14), in: Capsule())
                }
                Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.tertiary)
            }
            .frame(minHeight: 30)

            // The five stats, small — the "brief stats" half of the ask.
            HStack(spacing: 10) {
                ForEach(Stat.allCases, id: \.self) { stat in
                    VStack(spacing: 1) {
                        Image(systemName: stat.icon).font(.caption2).foregroundStyle(.secondary)
                        Text("\(character.stats[stat])").font(.caption.monospacedDigit())
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            // A nudge if something better is sitting unworn, so you know which card to open.
            if GearSlot.allCases.contains(where: { store.hasUpgradeAvailable(for: $0, slot: slot) }) {
                Text("Something better is on the shelf.")
                    .font(.caption2).foregroundStyle(.green)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func statChip(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value).font(.callout.monospacedDigit().weight(.medium))
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
    }

    private func icon(_ slot: PartySlot) -> String {
        switch slot {
        case .binder: "figure.stand"
        case .member(let index): store.state.base.roster.indices.contains(index)
            ? store.state.base.roster[index].icon : "person.fill"
        }
    }

    private func health(_ slot: PartySlot) -> Int {
        switch slot {
        case .binder:
            CharacterRules.maximumHealth(store.state.base.binderCharacter,
                                         base: Tuning.Encounter.binderMaxHP)
        case .member(let index):
            store.state.base.roster.indices.contains(index)
                ? CharacterRules.maximumHealth(store.state.base.roster[index].character,
                                               base: store.state.base.roster[index].maxHP)
                : 0
        }
    }
}

/// One person's own page — **and you can swipe to the next one** (Aimee, 6 Aug).
private struct CharacterPager: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss
    @State private var slot: PartySlot

    init(start: PartySlot) { _slot = State(initialValue: start) }

    var body: some View {
        NavigationStack {
            TabView(selection: $slot) {
                ForEach(store.partySlots) { member in
                    CharacterPage(slot: member).tag(member)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: store.partySlots.count > 1 ? .always : .never))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .navigationTitle(store.name(of: slot))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
            }
        }
    }
}

/// Stats, gear and rules for one person, on tabs — so a page is about one thing at a time.
private struct CharacterPage: View {
    @EnvironmentObject private var store: GameStore
    let slot: PartySlot

    private enum Tab: String, CaseIterable, Identifiable {
        case gear = "Gear"
        case rules = "Rules"
        var id: String { rawValue }
    }
    @State private var tab: Tab = .gear

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                statsCard

                Picker("", selection: $tab) {
                    ForEach(Tab.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .frame(minHeight: 44)

                switch tab {
                case .gear:
                    StationCard(title: "Worn", icon: "shield.lefthalf.filled") {
                        ForEach(GearSlot.allCases, id: \.self) { gearSlot in
                            GearSlotRow(gearSlot: gearSlot, slot: slot)
                        }
                    }
                case .rules:
                    rulesCard
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
    }

    private var statsCard: some View {
        let character = store.character(of: slot)
        return StationCard(title: "Level \(character.level)", icon: "chart.bar") {
            // Progress toward the next one — a level you can see coming is worth more than a
            // number that jumps.
            ProgressView(value: Double(max(0, character.experienceIntoThisLevel)),
                         total: Double(character.experienceThisLevelCosts))
                .tint(.accentColor)
            Text("\(max(0, character.experienceIntoThisLevel)) of \(character.experienceThisLevelCosts) toward the next.")
                .font(.caption2).foregroundStyle(.secondary)

            ForEach(Stat.allCases, id: \.self) { stat in
                VStack(alignment: .leading, spacing: 1) {
                    LabeledRow(icon: stat.icon, label: stat.displayName,
                               value: "\(character.stats[stat])")
                    Text(stat.job)
                        .font(.caption2).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // **Where they stand**, with the rest of the character rather than in the room they're
            // standing in. Set here and never mid-fight, the same rule gambits follow.
            Divider()
            Text("Where they stand")
                .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            Picker("", selection: Binding(get: { character.rank },
                                          set: { store.setRank($0, of: slot) })) {
                ForEach(Rank.allCases, id: \.self) { Text($0.displayName).tag($0) }
            }
            .pickerStyle(.segmented)
            .frame(minHeight: 44)
            Text(character.rank.blurb)
                .font(.caption2).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var rulesCard: some View {
        switch slot.combatant(activeCompanion: store.state.base.activeCompanion) {
        case .companion:
            GambitEditorView(owner: .companion)
        case .binder:
            if store.state.base.hasAutomateSelfUnlock {
                GambitEditorView(owner: .binder)
            } else {
                ComingLater("Writing your own hand is studied under Instruction at the Workshop. Until then you act for yourself every turn.")
            }
        case .none:
            ComingLater("\(store.name(of: slot)) keeps the fire in for now. Their rules matter once all five of you fight together.")
        }
    }
}

/// One equipment slot, for whoever's page you're on.
private struct GearSlotRow: View {
    @EnvironmentObject private var store: GameStore
    @State private var isChoosing = false
    let gearSlot: GearSlot
    let slot: PartySlot

    private var piece: EquippedPiece? { store.worn(gearSlot, by: slot) }

    var body: some View {
        Button { isChoosing = true } label: {
            HStack(spacing: 10) {
                Image(systemName: piece?.definition?.icon ?? gearSlot.icon)
                    .foregroundStyle(piece?.definition?.rarity.tint ?? Color.secondary)
                    .frame(width: 22)
                VStack(alignment: .leading, spacing: 0) {
                    Text(piece?.displayName ?? gearSlot.displayName)
                        .foregroundStyle(piece?.definition?.rarity.tint ?? Color.secondary)
                    if let piece, let definition = piece.definition {
                        Text("\(definition.rarity.rawValue) · tier \(piece.effectiveTier)")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if store.hasUpgradeAvailable(for: gearSlot, slot: slot) {
                    Text("something better")
                        .font(.caption2.weight(.medium)).foregroundStyle(.green)
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(Color.green.opacity(0.14), in: Capsule())
                }
                Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.tertiary)
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $isChoosing) {
            GearView(slot: gearSlot, member: slot).environmentObject(store)
        }
    }
}
