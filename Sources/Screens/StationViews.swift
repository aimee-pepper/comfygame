import SwiftUI

// The remaining stations. Each one is reachable, saved, and shows the real state it owns; the
// *spending* half of each (identify, purchase, gambit editing, node buying) belongs to milestones
// 4–5 and is marked as such on screen rather than being silently absent.

/// What came home to a full Storehouse and is waiting to be sorted.
///
/// Banking never discards (Q10). The decision lands *here*, at home, with everything visible —
/// as opposed to the satchel decision, which belongs in the world while the walls are closing in.
private struct SpilloverCard: View {
    @EnvironmentObject private var store: GameStore
    @State private var swapping: ItemStack?

    var body: some View {
        StationCard(title: "Waiting to be sorted — \(store.spillover.count)", icon: "tray.full") {
            Text("Your Storehouse was full when this came home. Nothing was thrown away.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(store.spillover) { stack in
                VStack(alignment: .leading, spacing: 8) {
                    LabeledRow(icon: stack.icon,
                               label: stack.displayName,
                               value: stack.detail,
                               tint: stack.rarity.tint)
                    HStack(spacing: 8) {
                        if store.state.base.inventory.isFull {
                            Button("Make room") { swapping = stack }
                                .buttonStyle(.borderedProminent)
                                .frame(minHeight: 44)
                        } else {
                            Button("Store it") { store.storeSpilled(stack) }
                                .buttonStyle(.borderedProminent)
                                .frame(minHeight: 44)
                        }
                        Button("Throw away", role: .destructive) { store.discardSpilled(stack) }
                            .frame(minHeight: 44)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .sheet(item: $swapping) { spilled in
            SwapSheet(spilled: spilled)
        }
    }
}

/// Full Storehouse: pick what the new thing replaces. The thing it replaces goes back to the
/// spillover rather than being destroyed — still nothing lost without being asked.
private struct SwapSheet: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss
    let spilled: ItemStack

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledRow(icon: spilled.icon, label: spilled.displayName,
                               value: "", tint: spilled.rarity.tint)
                } header: {
                    Text("Making room for")
                }
                Section {
                    ForEach(store.state.base.inventory.stacks) { stored in
                        Button {
                            store.swapSpilled(spilled, for: stored)
                            dismiss()
                        } label: {
                            LabeledRow(icon: stored.icon, label: stored.displayName,
                                       value: stored.detail,
                                       tint: stored.rarity.tint)
                        }
                        .frame(minHeight: 44)
                    }
                } header: {
                    Text("Replaces")
                } footer: {
                    Text("Whatever you replace goes back to the waiting pile. Nothing is thrown away here.")
                }
            }
            .navigationTitle("Make room")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

/// Storehouse — inventory and identification. Identify flow is milestone 5.
struct StorehouseView: View {
    @EnvironmentObject private var store: GameStore
    @State private var opened: ItemStack?

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
                        if base.resources[Resources.essenceRaw] > 0 {
                            // Raw essence looks like currency and isn't. Say so here rather than
                            // letting someone stare at a full storehouse and an unaffordable book.
                            Text("Raw essence can't be written with — refine it at the Workshop first.")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }

                StationCard(title: "Inventory — \(base.inventory.stacks.count) of \(base.inventory.slots)", icon: "archivebox") {
                    if base.inventory.stacks.isEmpty {
                        EmptyNote("Eight slots, all empty. Items come from worlds.")
                    } else {
                        ForEach(base.inventory.stacks) { stack in
                            // Rarity reads as the colour of the name (design brief's colour-coded
                            // ladder), so a Mythic is obvious at a glance in a long list.
                            //
                            // **A material bin opens.** All the hides share one slot, and what's
                            // actually in it — the grades, the animals they came off — is the thing
                            // worth having; a row saying "12 hides" would have hidden it.
                            if stack.materials.count > 1 {
                                Button { opened = stack } label: {
                                    HStack(spacing: 0) {
                                        LabeledRow(icon: stack.icon, label: stack.displayName,
                                                   value: stack.detail, tint: stack.rarity.tint)
                                        Image(systemName: "chevron.right")
                                            .font(.caption2.weight(.semibold))
                                            .foregroundStyle(.tertiary)
                                    }
                                    .frame(minHeight: 44)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            } else {
                                LabeledRow(icon: stack.icon,
                                           label: stack.displayName,
                                           value: stack.detail,
                                           tint: stack.rarity.tint)
                            }
                        }
                    }
                }

                if !store.spillover.isEmpty {
                    SpilloverCard()
                }

                if !store.unidentifiedStacks.isEmpty {
                    IdentifyCard()
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .sheet(item: $opened) { bin in
            MaterialBinSheet(bin: bin).environmentObject(store)
        }
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
                HStack(spacing: 12) {
                    CurrencyChip(icon: "drop.fill", label: "Essence", value: "\(store.state.base.essence)", tint: .teal)
                    CurrencyChip(icon: "cube", label: "Ore", value: "\(store.state.base.resources[Resources.ore])")
                    CurrencyChip(icon: "scribble", label: "Fiber", value: "\(store.state.base.resources[Resources.fiber])")
                }

                RefineryCard()

                ResearchTree()

                // **The Workshop is where you get better at writing, and nothing else** (Q40).
                // Anything a person teaches went with that person's building.
                ForEach(ContentCatalog.shared.branchesInOrder.filter { $0.station != nil }) { branch in
                    if let id = branch.station, let elsewhere = ContentCatalog.shared.station(id) {
                        ComingLater("\(branch.name) is taught at \(elsewhere.name), not here.")
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Workshop")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// The Scriptorium — where the hands are learned.
///
/// Its own building because `hands-and-calligrapher-spec.md` makes it one, and its own *gate*
/// because Aimee decided so: *"the player MUST meet the calligrapher to progress. it's core to the
/// game."* That's a deliberate exception to Q40's rule that a building's first rungs stay reachable
/// — the rule protects capacity, and the hands aren't a convenience the game withholds. They are
/// what the game is about.
struct ScriptoriumView: View {
    @EnvironmentObject private var store: GameStore

    private var tier: Int { store.state.base.station(Stations.scriptorium).tier }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    CurrencyChip(icon: "drop.fill", label: "Essence",
                                 value: "\(store.state.base.essence)", tint: .teal)
                    CurrencyChip(icon: "pencil", label: "Hand",
                                 value: store.state.base.bestHand.displayName)
                }

                StationCard(title: "The Art", icon: "pencil.and.outline") {
                    Text("A finer hand doesn't let you say new things. It lets you say the same things in less room — and a page is the only thing in this game that never gets bigger.")
                        .font(.caption).foregroundStyle(.secondary)
                    LabeledRow(icon: "chart.bar", label: "Tier", value: "\(tier)")
                }

                ResearchTree(station: Stations.scriptorium)
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("The Scriptorium")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// **Mara's Survey Post** (`crafting-spec.md` PART TWO).
///
/// The field half of the analysis axis: one instrument per subject, each raising what you can read
/// about *that* subject out in a world you are standing in. It is also the reason Mara exists —
/// she was a surveyor who unlocked nothing.
///
/// The rule that makes the pair good: **field readings are the currency prediction is bought with.**
/// The page lens at Isolde's is gated on how many of these you own, so it grows subject by subject
/// as the kit does rather than arriving in one jump.
struct SurveyPostView: View {
    @EnvironmentObject private var store: GameStore

    private var measured: [PressureTargetDef] {
        ContentCatalog.shared.pressureTargetsInOrder
            .filter { store.state.reality.measures($0.id) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    CurrencyChip(icon: "drop.fill", label: "Essence",
                                 value: "\(store.state.base.essence)", tint: .teal)
                    CurrencyChip(icon: "ruler", label: "Instruments",
                                 value: "\(store.state.reality.instruments.count) of \(ContentCatalog.shared.pressureTargets.count)")
                }

                StationCard(title: "What you can measure", icon: "ruler.fill") {
                    Text("An instrument reads one subject, in the world you're standing in. What you measure out there is what the lens at the Scriptorium will show you before you write.")
                        .font(.caption).foregroundStyle(.secondary)
                    if measured.isEmpty {
                        Text("Nothing yet. You are reading the world by eye.")
                            .font(.caption).foregroundStyle(.tertiary)
                    } else {
                        ForEach(measured) { target in
                            LabeledRow(icon: target.icon, label: target.name, value: "measured")
                        }
                    }
                }

                ResearchTree(station: Stations.surveyPost)
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("The Survey Post")
        .navigationBarTitleDisplayMode(.inline)
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
                    ConstellationNodeCard(node: node)
                }

                Label {
                    Text("These survive everything, including a future reset. Nothing else you buy does.")
                } icon: {
                    Image(systemName: "infinity")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
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

                // **Changing your mind, for a price** (Aimee, 7 Aug: *"people should be able to be
                // respec'd at the spring in town"*). Everybody at the fire, not just who's coming —
                // the point of rethinking somebody is often that you're about to take them.
                StationCard(title: "Unlearning", icon: "arrow.uturn.backward.circle") {
                    Text("The Spring takes back what somebody learned, and they can spend it again. It costs, so it isn't a free retry.")
                        .font(.caption2).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    ForEach([PartyMember.binder] + store.state.base.roster.indices.map(PartyMember.member)) { member in
                        let cost = store.respecCost(for: member)
                        HStack(spacing: 8) {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(store.name(of: member)).font(.callout)
                                Text(cost == 0
                                     ? "nothing spent yet"
                                     : "\(CombatTreeRules.spentPoints(store.character(of: member))) points learned")
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 6)
                            Button(cost == 0 ? "—" : "\(cost) essence") { store.respec(member) }
                                .font(.caption2.weight(.medium))
                                .buttonStyle(.bordered)
                                .disabled(!store.canRespec(member))
                        }
                        .frame(minHeight: 44)
                    }
                }

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
    /// Colours the label. Used for the rarity ladder — an item's rarity IS the colour of its name.
    var tint: Color?

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.footnote).frame(width: 20)
                .foregroundStyle(tint ?? Color.accentColor)
            Text(label).font(.callout).foregroundStyle(tint ?? Color.primary)
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

/// What's actually in a material bin.
///
/// Binning by kind is what keeps eight slots usable (session 16 §1), and it only works because
/// nothing is lost by it: every sample keeps its own grade, its own name and the animal it came
/// off. This is where you look at them — and sort them, because "which is my best pelt" is the
/// question a hoard exists to answer.
struct MaterialBinSheet: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss
    let bin: ItemStack

    enum Order: String, CaseIterable, Identifiable {
        case grade = "Grade"
        case source = "Where from"
        case order = "Order found"
        var id: String { rawValue }
    }
    @State private var order: Order = .grade

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(Array(sorted.enumerated()), id: \.offset) { _, sample in
                        HStack(spacing: 10) {
                            Image(systemName: sample.kind.icon)
                                .font(.footnote).frame(width: 20)
                                .foregroundStyle(sample.rarity.tint)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(sample.displayName)
                                    .font(.callout)
                                    .foregroundStyle(sample.rarity.tint)
                                if !sample.source.isEmpty {
                                    Text("off a \(sample.source)")
                                        .font(.caption2).foregroundStyle(.secondary)
                                }
                            }
                            Spacer(minLength: 8)
                            VStack(alignment: .trailing, spacing: 1) {
                                Text("\(Int(sample.grade))")
                                    .font(.callout.monospacedDigit())
                                Text(sample.properties.dominant.name)
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                        .frame(minHeight: 44)
                    }
                } header: {
                    Picker("Sort", selection: $order) {
                        ForEach(Order.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .textCase(nil)
                    .padding(.bottom, 4)
                } footer: {
                    Text("All \(bin.count) share one slot. Every one keeps its own grade and the animal it came off.")
                }
            }
            .navigationTitle(bin.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
            }
        }
    }

    private var sorted: [MaterialSample] {
        switch order {
        case .grade: bin.materials.sorted { $0.grade > $1.grade }
        case .source: bin.materials.sorted { ($0.source, $0.grade) < ($1.source, $1.grade) }
        case .order: bin.materials
        }
    }
}
