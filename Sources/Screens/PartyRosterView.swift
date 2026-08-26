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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var opened: PartySlot?

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                satchelSummary

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(store.partySlots) { slot in
                        Button { opened = slot } label: { card(slot) }
                            .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
#if DEBUG
            .background { P2SafeSpaceProbe(region: .partyContent) }
#endif
        }
#if DEBUG
        .background { P2SafeSpaceProbe(region: .partyScroll) }
#endif
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Party")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $opened) { slot in
            CharacterPager(start: slot).environmentObject(store)
        }
    }

    private var columns: [GridItem] {
        dynamicTypeSize.isAccessibilitySize
            ? [GridItem(.flexible())]
            : Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
    }

    private var satchelSummary: some View {
        HStack(spacing: 10) {
            Image(systemName: "bag")
                .foregroundStyle(.tint)
                .frame(width: 32, height: 32)
                .background(Color.accentColor.opacity(0.14), in: RoundedRectangle(cornerRadius: 8))
            Text("Field Kit").font(.callout.weight(.semibold))
            Spacer(minLength: 4)
            Text("\(plannedFieldKitBins) of \(store.state.base.satchelCapacity) planned · \(store.state.base.inventory.slots) Storehouse bins")
                .font(.caption).foregroundStyle(.secondary)
                .lineLimit(1).minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }

    private var plannedFieldKitBins: Int {
        store.fieldKitEntries.filter { $0.desiredCount > 0 }.count
    }

    /// Thumbnail and brief stats. Enough to choose who to open, and nothing more.
    private func card(_ slot: PartySlot) -> some View {
        let character = store.character(of: slot)
        let isComing = store.state.base.partyMembers.contains(slot)
        let upgrade = GearSlot.allCases.contains { store.hasUpgradeAvailable(for: $0, slot: slot) }
        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                NamedCharacterPixelIdentity(
                    travellerID: travellerID(slot),
                    fallbackSystemIcon: icon(slot),
                    fallbackColor: .accentColor
                )
                    .frame(width: 34, height: 34)
                Spacer()
                if isComing {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption).foregroundStyle(.green)
                        .accessibilityLabel("With you")
                }
            }
            Text(store.name(of: slot)).font(.callout.weight(.semibold)).lineLimit(1)
            Text("Lv \(character.level) · Max HP \(health(slot))")
                .font(.caption.monospacedDigit()).foregroundStyle(.secondary).lineLimit(1)
            Text("Rank · \(character.rank.displayName)")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            // A nudge if something better is sitting unworn, so you know which card to open.
            if upgrade {
                Label("Upgrade", systemImage: "sparkles")
                    .font(.caption2.weight(.medium)).foregroundStyle(.green).lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: dynamicTypeSize.isAccessibilitySize ? 150 : 124,
               alignment: .topLeading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
        .contentShape(RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(store.name(of: slot)). Level \(character.level). Maximum health \(health(slot)). Rank \(character.rank.displayName).\(isComing ? " With you." : "")\(upgrade ? " Upgrade available." : "")")
    }

    private func icon(_ slot: PartySlot) -> String {
        switch slot {
        case .binder: "figure.stand"
        case .member(let id): store.state.base.rosterIndex(for: id)
            .map { store.state.base.roster[$0].icon } ?? "person.fill"
        }
    }

    /// Binder and Quill/generated companions intentionally return nil and keep their SF fallback.
    /// A recruited named traveller resolves only through the stable ID already stored on roster.
    private func travellerID(_ slot: PartySlot) -> TravellerID? {
        guard case .member(let id) = slot,
              let index = store.state.base.rosterIndex(for: id) else { return nil }
        return store.state.base.roster[index].traveller
    }

    private func health(_ slot: PartySlot) -> Int {
        switch slot {
        case .binder:
            CharacterRules.maximumHealth(store.state.base.binderCharacter,
                                         base: Tuning.Encounter.binderMaxHP)
        case .member(let id):
            store.state.base.rosterIndex(for: id)
                .map { CharacterRules.maximumHealth(store.state.base.roster[$0].character,
                                               base: store.state.base.roster[$0].maxHP)
                } ?? 0
        }
    }
}

/// One person's own page — **and you can swipe to the next one** (Aimee, 6 Aug).
private struct CharacterPager: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss
    @State private var slot: PartySlot
    @State private var tab: CharacterPageTab = .gear

    init(start: PartySlot) { _slot = State(initialValue: start) }

    var body: some View {
        NavigationStack {
            TabView(selection: $slot) {
                ForEach(store.partySlots) { member in
                    CharacterPage(slot: member, tab: $tab).tag(member)
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

private enum CharacterPageTab: String, CaseIterable, Identifiable {
    case gear = "Gear"
    case training = "Training"
    case stats = "Stats"
    case gambits = "Gambits"
    var id: String { rawValue }
}

/// Stats, gear and rules for one person, on tabs — so a page is about one thing at a time.
private struct CharacterPage: View {
    @EnvironmentObject private var store: GameStore
    let slot: PartySlot
    @Binding var tab: CharacterPageTab

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Picker("", selection: $tab) {
                    ForEach(CharacterPageTab.allCases) { Text($0.rawValue).tag($0) }
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
                case .training:
                    // **Where you spent, which is what a class is.** Its own tab rather than a
                    // section, because nine branches of eight nodes is a screen, not a card.
                    CombatTreeView(member: slot).environmentObject(store)
                        .frame(minHeight: 520)
                case .stats:
                    statsCard
                case .gambits:
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
        switch slot.combatant {
        case .companion(let index):
            GambitEditorView(owner: .companion(index))
        case .binder:
            if store.state.base.hasAutomateSelfUnlock {
                GambitEditorView(owner: .binder)
            } else {
                ComingLater("Writing your own hand is studied under Instruction at the Workshop. Until then you act for yourself every turn.")
            }
        case .foe:
            EmptyView()
        }
    }
}

/// One equipment slot, for whoever's page you're on.
private struct GearSlotRow: View {
    @EnvironmentObject private var store: GameStore
    let gearSlot: GearSlot
    let slot: PartySlot

    private var piece: EquippedPiece? { store.worn(gearSlot, by: slot) }

    var body: some View {
        NavigationLink {
            GearView(slot: gearSlot, member: slot)
                .environmentObject(store)
        } label: {
            HStack(spacing: 10) {
                if let piece {
                    CatalogueItemPixelIdentity(
                        itemID: piece.catalogID,
                        identified: true,
                        fallbackSystemIcon: piece.definition?.icon ?? gearSlot.icon,
                        fallbackColor: piece.definition?.rarity.tint ?? .secondary
                    )
                    .frame(width: 28, height: 28)
                } else {
                    Image(systemName: gearSlot.icon)
                        .foregroundStyle(.secondary)
                        .frame(width: 28)
                }
                VStack(alignment: .leading, spacing: 0) {
                    Text(piece?.displayName ?? gearSlot.displayName)
                        .foregroundStyle(piece?.definition?.rarity.tint ?? Color.secondary)
                    if let piece, let definition = piece.definition {
                        Text("\(GearPresentationCopy.rarity(definition.rarity)) · tier \(piece.effectiveTier)")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if store.hasUpgradeAvailable(for: gearSlot, slot: slot) {
                    Text("Upgrade available")
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
    }
}
