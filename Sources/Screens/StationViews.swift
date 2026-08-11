import SwiftUI

struct DistilleryView: View {
    @EnvironmentObject private var store: GameStore
    @State private var selected: [CoreAttunement: String] = [:]
    @State private var causticCatalyst: ResourceID = Resources.toxin

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                StationCard(title: "Crystallise", icon: "diamond.fill") {
                    Text("A stable blank. Quartz is the lattice; essence remains the thing being held.")
                        .font(.caption).foregroundStyle(.secondary)
                    LabeledRow(icon: "drop.fill", label: "Essence", value: "40")
                    LabeledRow(icon: "diamond", label: "Quartz", value: "2")
                    Button("Crystallise essence") { store.crystalliseEssence() }
                        .buttonStyle(.borderedProminent).frame(maxWidth: .infinity, minHeight: 44)
                        .disabled(!DistilleryRules.canCrystallise(in: store.state))
                }
                ForEach(CoreAttunement.allCases, id: \.self) { attunement in
                    attunementCard(attunement)
                }
                ComingLater("Infusion is deliberately held until a named crafted profile has a designed trade-off.")
            }.padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("The Distillery")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder private func attunementCard(_ attunement: CoreAttunement) -> some View {
        let candidates = DistilleryRules.candidates(for: attunement, in: store.state)
        let chosen = candidates.first(where: { $0.id == selected[attunement] }) ?? candidates.first
        let catalyst = attunement == .caustic ? causticCatalyst : DistilleryRules.catalystOptions(for: attunement)[0].0
        StationCard(title: "\(attunement.displayName) core", icon: coreIcon(attunement)) {
            Text(requirement(attunement)).font(.caption).foregroundStyle(.secondary)
            if candidates.isEmpty {
                EmptyNote("No qualifying provenanced world sample.")
            } else {
                Picker("Selected sample", selection: Binding(
                    get: { chosen?.id ?? "" }, set: { selected[attunement] = $0 })) {
                    ForEach(candidates) { candidate in
                        Text("\(candidate.sample.displayName) · \(candidate.sample.source)").tag(candidate.id)
                    }
                }
                if attunement == .caustic {
                    Picker("Catalyst", selection: $causticCatalyst) {
                        Text("2 Toxin").tag(Resources.toxin)
                        Text("1 Ichor").tag(Resources.ichor)
                    }.pickerStyle(.segmented)
                }
                if let chosen {
                    let preview = DistilledCore(attunement: attunement,
                                                potency: DistilleryRules.potency(for: chosen))
                    LabeledRow(icon: "gauge.with.dots.needle.50percent", label: "Potency",
                               value: "\(preview.potency) · \(preview.potencyBand)")
                    Button("Attune \(attunement.displayName) core") {
                        store.attuneCore(attunement, candidate: chosen, catalyst: catalyst)
                    }.buttonStyle(.borderedProminent).frame(maxWidth: .infinity, minHeight: 44)
                        .disabled(!DistilleryRules.canAttune(attunement, candidate: chosen,
                                                            catalyst: catalyst, in: store.state))
                }
            }
        }
    }

    private func requirement(_ value: CoreAttunement) -> String {
        switch value {
        case .heat: "15 essence · 2 Sulfur · reactive 60+, insulating 25+ sample"
        case .caustic: "15 essence · 2 Toxin or 1 Ichor · reactive reagent/toxin/ichor sample"
        case .light: "15 essence · 2 Silver · lustrous 60+, hard 30+ sample"
        }
    }
    private func coreIcon(_ value: CoreAttunement) -> String {
        switch value { case .heat: "flame.circle.fill"; case .caustic: "drop.triangle.fill"; case .light: "sun.max.circle.fill" }
    }
}

struct ChannelworksView: View {
    @EnvironmentObject private var store: GameStore
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                StationCard(title: "Conduit housing", icon: "point.3.connected.trianglepath.dotted") {
                    Text("The first fixture is Oda's own damaged Heat Conduit, restored when this station is raised. Its core is intact and cannot be recovered.")
                        .font(.caption).foregroundStyle(.secondary)
                    Text("Oda consumes one Heat core and transfers its attunement, potency and origin receipt into a contained fixture.")
                        .font(.caption).foregroundStyle(.secondary)
                    Button("Construct Heat Conduit fixture") { store.constructConduitFixture() }
                        .buttonStyle(.borderedProminent).frame(maxWidth: .infinity, minHeight: 44)
                        .disabled(!store.state.base.inventory.stacks.contains { $0.catalogID == Items.heatCore })
                }
                ComingLater("Contact and Projection housings follow after this first Conduit construction path is proven.")
            }.padding(16)
        }.background(Color(.systemGroupedBackground))
            .navigationTitle("The Channelworks").navigationBarTitleDisplayMode(.inline)
    }
}

struct ReliquaryView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                StationCard(title: "Field interpretation", icon: "building.columns.fill") {
                    LabeledRow(icon: "map", label: "Site locations", value: "revealed on arrival")
                    LabeledRow(icon: "shippingbox", label: "Recovered resources",
                               value: "+\(Tuning.Economy.reliquarySiteYieldBonus) each")
                    Text("Edren marks where a world shows signs of habitation. Reaching and searching each place is still fieldwork.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }.padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("The Reliquary")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct WayfarersTableView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                StationCard(title: "Packed for the route", icon: "map.fill") {
                    LabeledRow(icon: "backpack.fill", label: "Satchel capacity",
                               value: "\(store.state.base.satchelCapacity) slots")
                    LabeledRow(icon: "leaf.fill", label: "Organic harvests",
                               value: "+\(Tuning.Economy.fieldcraftOrganicYieldBonus) each")
                    Text("Sela leaves routes, provisions and field notes here for whoever goes next. The table is useful precisely because nobody has to remain behind it.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }.padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("The Wayfarer's Table")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AnchorageView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                StationCard(title: "Anchor Frame", icon: "square.on.square.intersection.dashed") {
                    Text("A carried binding for a world with no usable Atlas Seam. Six different pieces of world-made stock are consumed.")
                        .font(.caption).foregroundStyle(.secondary)
                    LabeledRow(icon: "diamond", label: "Hardness 65+", value: "2 distinct")
                    LabeledRow(icon: "circle.fill", label: "Density 65+", value: "2 distinct")
                    LabeledRow(icon: "wave.3.right", label: "Flexibility 55+", value: "1")
                    LabeledRow(icon: "bolt", label: "Reactivity 65+", value: "1")
                    LabeledRow(icon: "drop.fill", label: "Essence", value: "60")
                    let missing = AnchorFrameRules.shortfall(in: store.state)
                    if !missing.isEmpty {
                        Text("Still needed: \(missing.joined(separator: " · "))")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Button {
                        store.craftAnchorFrame()
                    } label: {
                        Label("Craft Anchor Frame", systemImage: "hammer.fill")
                            .frame(maxWidth: .infinity).frame(minHeight: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!AnchorFrameRules.canCraft(in: store.state))
                }
                if store.state.worlds.anchoredRealms.isEmpty {
                    StationCard(title: "The Atlas waits", icon: "book.closed.fill") {
                        Text("No worlds have been rebound yet. A realm anchored before or during an expedition will remain here after you return.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    ForEach(store.state.worlds.anchoredRealms) { realm in
                        StationCard(title: realm.name,
                                    icon: realm.isDormant ? "moon.zzz.fill" : "globe.americas.fill") {
                            LabeledRow(icon: "link", label: "State",
                                       value: realm.isDormant ? "Dormant" : "Active")
                            LabeledRow(icon: "clock.arrow.circlepath", label: "Anchored by",
                                       value: realm.route.displayName)
                            LabeledRow(icon: "scalemass", label: "Sustain",
                                       value: realm.projectedShortfall == 0
                                       ? "covered" : "short by \(realm.projectedShortfall)")
                            LabeledRow(icon: "person.2", label: "Assigned companions",
                                       value: "\(realm.assignedCompanions.count)")
                            ForEach(realm.assignedCompanions, id: \.self) { index in
                                if store.state.base.roster.indices.contains(index) {
                                    let worker = store.state.base.roster[index]
                                    let contribution = Tuning.Anchoring.worldworkBaseContribution
                                        + worker.worldwork
                                        + max(0, worker.character.level - 1)
                                            / Tuning.Anchoring.levelsPerWorldworkBonus
                                    HStack {
                                        Text(store.state.base.roster[index].name)
                                        Spacer()
                                        Text("Worldwork \(worker.worldwork) · +\(contribution)")
                                            .foregroundStyle(.secondary)
                                        Button("Return") { store.unassignCompanion(index, fromAnchoredRealm: realm.id) }
                                    }
                                    .font(.caption)
                                }
                            }
                            if !realm.isDormant && !store.state.base.roster.isEmpty {
                                Menu {
                                    ForEach(store.state.base.roster.indices, id: \.self) { index in
                                        Button(store.state.base.roster[index].name) {
                                            store.assignCompanion(index, toAnchoredRealm: realm.id)
                                        }
                                    }
                                } label: {
                                    Label("Assign companion", systemImage: "person.badge.plus")
                                        .frame(maxWidth: .infinity).frame(minHeight: 44)
                                }
                                Text("Assignment moves them out of the active party. Current realm work has no injury or permanent-loss risk.")
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                            Button {
                                store.revisitAnchoredRealm(realm.id)
                            } label: {
                                Label("Revisit realm", systemImage: "arrow.up.forward.circle.fill")
                                    .frame(maxWidth: .infinity)
                                    .frame(minHeight: 44)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(realm.isDormant)
                            if realm.isDormant {
                                let cost = max(Tuning.Anchoring.minimumReactivationCost,
                                               realm.projectedShortfall)
                                Button {
                                    store.reactivateAnchoredRealm(realm.id)
                                } label: {
                                    Label("Reactivate · \(cost) essence", systemImage: "sunrise.fill")
                                        .frame(maxWidth: .infinity).frame(minHeight: 44)
                                }
                                .buttonStyle(.bordered)
                                .disabled(store.state.base.essence < cost)
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("The Anchorage")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension AnchorRoute {
    var displayName: String {
        switch self {
        case .bornAnchored: "at binding"
        case .naturalPoint: "natural anchor"
        case .craftedFrame: "Anchor Frame"
        }
    }
}

// The remaining stations. Each one is reachable, saved, and shows the real state it owns; the
// *spending* half of each (identify, purchase, gambit editing, node buying) belongs to milestones
// 4–5 and is marked as such on screen rather than being silently absent.

/// What came home to a full Storehouse and is waiting to be sorted.
///
/// Banking never discards (Q10). The decision lands *here*, at home, with everything visible —
/// as opposed to the satchel decision, which belongs in the world while the walls are closing in.
private struct SpilloverCard: View {
    @EnvironmentObject private var store: GameStore
    @State private var opened: ItemStack?

    var body: some View {
        StationCard(title: "Waiting to be sorted — \(store.spillover.count)", icon: "tray.full") {
            Text("Your Storehouse was full when this came home. Nothing was thrown away.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            SixAcrossItemGrid(data: store.spillover, id: \.id) { stack in
                Button { opened = stack } label: {
                    ItemIconTile(icon: stack.icon, rarity: stack.rarity,
                                 quantity: stack.count, identified: stack.identified,
                                 location: .waiting,
                                 accessibilityName: stack.displayName)
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(item: $opened) { spilled in
            SpilloverDetailSheet(spilled: spilled).environmentObject(store)
        }
    }
}

private struct SpilloverDetailSheet: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss
    @State private var isMakingRoom = false
    let spilled: ItemStack

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 16) {
                        ItemIconTile(icon: spilled.icon, rarity: spilled.rarity,
                                     quantity: spilled.count, identified: spilled.identified,
                                     location: .waiting,
                                     accessibilityName: spilled.displayName)
                            .frame(width: 58, height: 58)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(spilled.displayName).font(.headline).foregroundStyle(spilled.rarity.tint)
                            Text("Waiting to sort").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                Section("Details") {
                    LabeledContent("Quantity", value: "\(spilled.count)")
                    LabeledContent("Location", value: ItemGridLocation.waiting.displayName)
                    if !spilled.detail.isEmpty { Text(spilled.detail) }
                }
                Section {
                    if store.state.base.inventory.isFull {
                        Button("Make room") { isMakingRoom = true }
                    } else {
                        Button("Store it") {
                            store.storeSpilled(spilled)
                            dismiss()
                        }
                    }
                    Button("Throw away", role: .destructive) {
                        store.discardSpilled(spilled)
                        dismiss()
                    }
                }
            }
            .navigationTitle(spilled.identified ? spilled.displayName : "Unknown item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
            }
            .sheet(isPresented: $isMakingRoom) {
                SwapSheet(spilled: spilled).environmentObject(store)
            }
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
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Making room for").font(.headline)
                    HStack(spacing: 12) {
                        ItemIconTile(icon: spilled.icon, rarity: spilled.rarity,
                                     quantity: spilled.count, identified: spilled.identified,
                                     location: .waiting,
                                     accessibilityName: spilled.displayName)
                            .frame(width: 52, height: 52)
                        Text(spilled.displayName).font(.callout.weight(.medium))
                    }
                    Text("Choose what returns to the waiting pile").font(.headline)
                    SixAcrossItemGrid(data: store.state.base.inventory.stacks, id: \.id) { stored in
                        Button {
                            store.swapSpilled(spilled, for: stored)
                            dismiss()
                        } label: {
                            ItemIconTile(icon: stored.icon, rarity: stored.rarity,
                                         quantity: stored.count, identified: stored.identified,
                                         location: .stored,
                                         accessibilityName: stored.displayName)
                        }
                        .buttonStyle(.plain)
                    }
                    Text("Whatever you replace goes back to the waiting pile. Nothing is thrown away here.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .padding(16)
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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var opened: ItemStack?
    @State private var tab: StorehouseTab = .items

    private var base: BaseState { store.state.base }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Picker("Storehouse section", selection: $tab) {
                    ForEach(StorehouseTab.allCases) { section in
                        Text(section == .waiting && !store.spillover.isEmpty
                             ? "Waiting \(store.spillover.count)"
                             : section.title)
                            .tag(section)
                    }
                }
                .pickerStyle(.segmented)
                .frame(minHeight: 44)

                switch tab {
                case .stockpiles:
                    if base.resources.isEmpty {
                        EmptyNote("Nothing hauled home yet.")
                    } else {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(base.resources.nonZero, id: \.id) { entry in
                                let resource = ContentCatalog.shared.resource(entry.id)
                                stockTile(icon: resource?.icon ?? "cube",
                                          name: resource?.name ?? entry.id.rawValue,
                                          amount: entry.amount)
                            }
                        }
                        if base.resources[Resources.essenceRaw] > 0 {
                            // Raw essence looks like currency and isn't. Say so here rather than
                            // letting someone stare at a full storehouse and an unaffordable book.
                            Text("Raw essence can't be written with — refine it at the Workshop first.")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                case .items:
                    HStack {
                        Label("Items", systemImage: "archivebox").font(.headline)
                        Spacer()
                        Text("\(base.inventory.stacks.count) of \(base.inventory.slots)")
                            .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                    }
                    if base.inventory.stacks.isEmpty {
                        EmptyNote("Eight slots, all empty. Items come from worlds.")
                    } else {
                        SixAcrossItemGrid(data: base.inventory.stacks, id: \.id) { stack in
                            Button { opened = stack } label: {
                                ItemIconTile(icon: stack.icon, rarity: stack.rarity,
                                             quantity: stack.count, identified: stack.identified,
                                             location: .stored,
                                             accessibilityName: stack.displayName)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    if !store.unidentifiedStacks.isEmpty { IdentifyCard() }
                case .waiting:
                    if store.spillover.isEmpty {
                        EmptyNote("Nothing is waiting to be sorted.")
                    } else {
                        SpilloverCard()
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .sheet(item: $opened) { stack in
            StorehouseItemSheet(stack: stack).environmentObject(store)
        }
        .navigationTitle("Storehouse")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var columns: [GridItem] {
        dynamicTypeSize.isAccessibilitySize
            ? [GridItem(.flexible())]
            : [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    }

    private func stockTile(icon: String, name: String, amount: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon).font(.title2).foregroundStyle(.tint)
            Text(name).font(.callout.weight(.medium))
            Text("\(amount)").font(.title3.monospacedDigit().weight(.semibold))
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }

}

private struct StorehouseItemSheet: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss
    let stack: ItemStack

    var body: some View {
        if !stack.materials.isEmpty {
            MaterialBinSheet(bin: stack).environmentObject(store)
        } else {
            NavigationStack {
                List {
                    Section {
                        HStack(spacing: 16) {
                            ItemIconTile(icon: stack.icon, rarity: stack.rarity,
                                         quantity: stack.count, identified: stack.identified,
                                         location: .stored, accessibilityName: stack.displayName)
                                .frame(width: 58, height: 58)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(stack.displayName).font(.headline).foregroundStyle(stack.rarity.tint)
                                Text(stack.rarity.displayName).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    Section("Details") {
                        LabeledContent("Quantity", value: "\(stack.count)")
                        LabeledContent("Location", value: ItemGridLocation.stored.displayName)
                        if !stack.detail.isEmpty { Text(stack.detail) }
                        if let profile = stack.gearProfile {
                            LabeledContent("Tier", value: "\(profile.constructionTier)")
                            LabeledContent("Reforge", value: "\(profile.reforgeRank) of 3")
                            if let provenance = profile.displayProvenance {
                                LabeledContent("Provenance", value: provenance)
                            }
                        } else if let blurb = ContentCatalog.shared.item(stack.catalogID)?.blurb,
                                  !blurb.isEmpty {
                            Text(blurb)
                        }
                    }
                }
                .navigationTitle(stack.identified ? stack.displayName : "Unknown item")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
                }
            }
        }
    }
}

private enum StorehouseTab: String, CaseIterable, Identifiable {
    case items, stockpiles, waiting
    var id: String { rawValue }
    var title: String {
        switch self { case .items: "Items"; case .stockpiles: "Resources"; case .waiting: "Waiting" }
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
                                 value: "\(store.state.reality.instruments.count) owned · \(store.state.reality.observations.count) calibrated")
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

                StationCard(title: "Pack for the next world", icon: "backpack.fill") {
                    Text("Choose which instruments cross the threshold with you. The selection is frozen for the whole trip.")
                        .font(.caption).foregroundStyle(.secondary)
                    if store.state.reality.instruments.isEmpty {
                        Text("Build an instrument below to begin a field kit.")
                            .font(.caption).foregroundStyle(.tertiary)
                    } else {
                        ForEach(ContentCatalog.shared.pressureTargetsInOrder.filter {
                            store.state.reality.instruments.contains($0.id)
                        }) { target in
                            Toggle(isOn: Binding(
                                get: { store.selectedInstrumentLoadout.contains(target.id) },
                                set: { store.setInstrument(target.id, carried: $0) }
                            )) {
                                Label(target.name, systemImage: target.icon)
                            }
                            .accessibilityIdentifier("field-kit.toggle.\(target.id.rawValue)")
                        }
                    }
                }

                if !store.state.reality.instruments.isEmpty {
                    StationCard(title: "Improve the instruments", icon: "wrench.and.screwdriver.fill") {
                        Text("Mara can rebuild an instrument around any material whose properties suit the work. She uses the least exceptional qualifying pieces first.")
                            .font(.caption).foregroundStyle(.secondary)

                        ForEach(ContentCatalog.shared.pressureTargetsInOrder.filter {
                            store.state.reality.instruments.contains($0.id)
                        }) { target in
                            InstrumentUpgradeRow(target: target)
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

private struct InstrumentUpgradeRow: View {
    @EnvironmentObject private var store: GameStore
    let target: PressureTargetDef

    private var precision: RealityState.InstrumentPrecision {
        store.state.reality.instrumentPrecision(for: target.id)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(instrumentName, systemImage: target.icon)
                    .font(.callout.weight(.medium))
                Spacer()
                Text(precision.displayName).font(.caption).foregroundStyle(.secondary)
            }
            if let recipe = InstrumentCraftingRules.recipe(for: target.id, in: store.state) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Next: \(recipe.output.displayName) · \(recipe.summary)")
                        Text("\(recipe.essence) essence")
                    }
                    .font(.caption2).foregroundStyle(.secondary)
                    Spacer(minLength: 8)
                    Button("Improve") { store.improveInstrument(target.id) }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .disabled(!store.instrumentCraftingReadiness(for: target.id).isReady)
                        .accessibilityIdentifier("instrument.improve.\(target.id.rawValue)")
                }
                if let shortageText { Text(shortageText).font(.caption2).foregroundStyle(.tertiary) }
            } else {
                Text("As precise as Mara can make it.")
                    .font(.caption2).foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }

    private var instrumentName: String {
        ContentCatalog.shared.researchNodes.first { node in
            node.grants.contains { $0.kind == .instrument && $0.id == target.id.rawValue }
        }?.name ?? target.name
    }

    private var shortageText: String? {
        switch store.instrumentCraftingReadiness(for: target.id) {
        case .needsMaterials(let have, let need): "Qualifying stock: \(have) of \(need)"
        case .needsEssence(let have, let need): "Essence: \(have) of \(need)"
        default: nil
        }
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
