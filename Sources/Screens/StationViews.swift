import SwiftUI

enum StationCataloguePresentation {
    static func resourceName(_ id: ResourceID,
                             catalogue: ContentCatalog = .shared) -> String {
        catalogue.resource(id)?.name ?? "Unknown resource"
    }
}

struct DistilleryView: View {
    @EnvironmentObject private var store: GameStore
    @State private var selected: [CoreAttunement: String] = [:]
    @State private var causticCatalyst: ResourceID = Resources.toxin
    @State private var actionFailure: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                StationCard(title: "Crystallise", icon: "diamond.fill") {
                    let readiness = DistilleryRules.crystallisationReadiness(in: store.state)
                    Text("A stable blank. Quartz is the lattice; essence remains the thing being held.")
                        .font(.caption).foregroundStyle(.secondary)
                    LabeledRow(icon: "drop.fill", label: "Essence",
                               value: "\(DistilleryRules.blankEssence)")
                    LabeledRow(icon: "diamond", label: "Quartz",
                               value: "\(DistilleryRules.blankQuartz)")
                    Label(crystallisationReadinessText(readiness),
                          systemImage: readiness == .ready
                              ? "checkmark.circle.fill" : "exclamationmark.circle")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(readiness == .ready ? Color.green : Color.orange)
                    Button("Crystallise essence") {
                        if store.crystalliseEssence() {
                            actionFailure = nil
                        } else {
                            actionFailure = "The Essence, Quartz, or Storehouse space changed. Review the crystallisation requirements and try again."
                        }
                    }
                        .buttonStyle(.borderedProminent).frame(maxWidth: .infinity, minHeight: 44)
                        .disabled(readiness != .ready)
                }
                ForEach(CoreAttunement.allCases, id: \.self) { attunement in
                    attunementCard(attunement)
                }
            }.padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("The Distillery")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Distillery action not completed", isPresented: Binding(
            get: { actionFailure != nil },
            set: { if !$0 { actionFailure = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(actionFailure ?? "The Distillery action could not be completed.")
        }
    }

    private func crystallisationReadinessText(
        _ readiness: DistilleryRules.CrystallisationReadiness
    ) -> String {
        switch readiness {
        case .ready: "Ready to crystallise"
        case .stationLocked: "Distillery unavailable"
        case .needsEssence(let have, let need): "Needs \(need) Essence · \(have) held"
        case .needsQuartz(let have, let need): "Needs \(need) Quartz · \(have) held"
        case .needsRoom: "Needs room in the Storehouse"
        }
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
                        ForEach(DistilleryRules.requirement(for: attunement).catalysts,
                                id: \.resource) { option in
                            let name = StationCataloguePresentation.resourceName(option.resource)
                            Text("\(option.amount) \(name)").tag(option.resource)
                        }
                    }.pickerStyle(.segmented)
                }
                if let chosen {
                    let preview = DistilledCore(attunement: attunement,
                                                potency: DistilleryRules.potency(for: chosen))
                    let readiness = DistilleryRules.readiness(
                        attunement, candidate: chosen, catalyst: catalyst, in: store.state
                    )
                    LabeledRow(icon: "gauge.with.dots.needle.50percent", label: "Potency",
                               value: "\(preview.potency) · \(preview.potencyBand)")
                    Label(readinessText(readiness), systemImage: readiness == .ready
                          ? "checkmark.circle.fill" : "exclamationmark.circle")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(readiness == .ready ? Color.green : Color.orange)
                    Button("Attune \(attunement.displayName) core") {
                        if store.attuneCore(attunement, candidate: chosen, catalyst: catalyst) {
                            actionFailure = nil
                        } else {
                            actionFailure = "The selected sample, catalyst, blank crystal, Essence, or Storehouse space changed. Review this core's requirements and try again."
                        }
                    }.buttonStyle(.borderedProminent).frame(maxWidth: .infinity, minHeight: 44)
                        .disabled(readiness != .ready)
                }
            }
        }
    }

    private func readinessText(_ readiness: DistilleryRules.AttunementReadiness) -> String {
        switch readiness {
        case .ready: "Ready to attune"
        case .stationLocked: "Distillery unavailable"
        case .needsEssence(let have, let need): "Needs \(need) Essence · \(have) held"
        case .sampleUnavailable: "Selected sample is no longer available"
        case .unsupportedCatalyst: "Selected catalyst is not valid for this core"
        case .needsCatalyst(let resource, let have, let need):
            "Needs \(need) \(StationCataloguePresentation.resourceName(resource)) · \(have) held"
        case .needsBlankCrystal: "Needs one blank Essence Crystal"
        case .needsRoom: "Needs room in the Storehouse"
        }
    }

    private func requirement(_ value: CoreAttunement) -> String {
        let rule = DistilleryRules.requirement(for: value)
        let catalyst = rule.catalysts.map { option in
            let name = StationCataloguePresentation.resourceName(option.resource)
            return "\(option.amount) \(name)"
        }.joined(separator: " or ")
        var sample: [String] = []
        if let kinds = rule.allowedKinds {
            sample.append(kinds.sorted { $0.rawValue < $1.rawValue }
                .map(\.displayName).joined(separator: "/"))
        }
        if let minimum = rule.minimumReactivity { sample.append("reactive \(Int(minimum))+") }
        if let minimum = rule.minimumInsulation { sample.append("insulating \(Int(minimum))+") }
        if let minimum = rule.minimumLustre { sample.append("lustrous \(Int(minimum))+") }
        if let minimum = rule.minimumHardness { sample.append("hard \(Int(minimum))+") }
        return (["\(rule.essence) essence", catalyst] + sample).joined(separator: " · ") + " sample"
    }
    private func coreIcon(_ value: CoreAttunement) -> String {
        switch value { case .heat: "flame.circle.fill"; case .caustic: "drop.triangle.fill"; case .light: "sun.max.circle.fill" }
    }
}

struct ChannelworksView: View {
    @EnvironmentObject private var store: GameStore
    @State private var constructionFailure: String?

    private var hasHeatCore: Bool {
        store.state.base.inventory.stacks.contains { $0.catalogID == Items.heatCore }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                StationCard(title: "Conduit housing", icon: "point.3.connected.trianglepath.dotted") {
                    Label("Oda's restored conduit", systemImage: "checkmark.seal.fill")
                        .font(.subheadline.weight(.semibold)).foregroundStyle(.green)
                    Text(store.odaRestoredConduitLocation.map { "The restored fixture is \($0)." }
                         ?? "The restoration is complete. The original fixture is no longer in known Home storage.")
                        .font(.caption).foregroundStyle(.secondary)
                    Text("Build another conduit by consuming one player-made Heat core and transferring its attunement, potency and origin receipt into a contained fixture.")
                        .font(.caption).foregroundStyle(.secondary)

                    Label(hasHeatCore ? "Heat core ready" : "Requires one Heat core",
                          systemImage: hasHeatCore ? "checkmark.circle.fill" : "exclamationmark.circle")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(hasHeatCore ? Color.green : Color.orange)

                    Button("Build another conduit") {
                        if store.constructConduitFixture() {
                            constructionFailure = nil
                        } else {
                            constructionFailure = "The Heat core or Storehouse space changed. Review the fixture requirements and try again."
                        }
                    }
                        .buttonStyle(.borderedProminent).frame(maxWidth: .infinity, minHeight: 44)
                        .disabled(!hasHeatCore)
                    if !hasHeatCore {
                        Text("Auber's Distillery makes the Heat cores used for additional conduits.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }.padding(16)
        }.background(Color(.systemGroupedBackground))
            .navigationTitle("The Channelworks").navigationBarTitleDisplayMode(.inline)
            .alert("Fixture not constructed", isPresented: Binding(
                get: { constructionFailure != nil },
                set: { if !$0 { constructionFailure = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(constructionFailure ?? "The fixture could not be constructed.")
            }
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
    @State private var actionFailure: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                StationCard(title: "Anchor Frame", icon: "square.on.square.intersection.dashed") {
                    Text("A carried binding for a world with no usable Atlas Seam. Six different pieces of world-made stock are consumed.")
                        .font(.caption).foregroundStyle(.secondary)
                    ForEach(AnchorFrameRules.groupedNeeds) { need in
                        LabeledRow(icon: need.property.icon,
                                   label: "\(need.property.stockWord.capitalisedSentence) \(Int(need.minimum))+",
                                   value: need.count == 1 ? "1" : "\(need.count) distinct")
                    }
                    LabeledRow(icon: "drop.fill", label: "Essence",
                               value: "\(AnchorFrameRules.essenceCost)")
                    let missing = AnchorFrameRules.shortfall(in: store.state)
                    if !missing.isEmpty {
                        Text("Still needed: \(missing.joined(separator: " · "))")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Button {
                        if store.craftAnchorFrame() {
                            actionFailure = nil
                        } else {
                            actionFailure = "The stock, Essence, or Storehouse space changed. Review the Anchor Frame requirements and try again."
                        }
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
                                    HStack(spacing: 8) {
                                        NamedCharacterPixelIdentity(
                                            travellerID: worker.traveller,
                                            fallbackSystemIcon: worker.icon,
                                            fallbackColor: .secondary
                                        )
                                        .frame(width: 24, height: 24)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(worker.name)
                                                .font(.callout.weight(.medium))
                                            Text("Worldwork \(worker.worldwork) · +\(contribution)")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Button("Return Home") {
                                            store.unassignCompanion(index, fromAnchoredRealm: realm.id)
                                        }
                                            .font(.caption.weight(.semibold))
                                            .buttonStyle(.bordered)
                                            .frame(minHeight: 44)
                                    }
                                    .frame(minHeight: 44)
                                }
                            }
                            if !realm.isDormant && !store.state.base.roster.isEmpty {
                                Menu {
                                    ForEach(store.state.base.roster.indices, id: \.self) { index in
                                        Button(store.state.base.roster[index].name) {
                                            if store.assignCompanion(index, toAnchoredRealm: realm.id) {
                                                actionFailure = nil
                                            } else {
                                                actionFailure = "That traveller or realm changed. Review the current assignments and try again."
                                            }
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
                                if store.revisitAnchoredRealm(realm.id) {
                                    actionFailure = nil
                                } else {
                                    actionFailure = "The realm cannot be revisited now. Check that no expedition is active and the realm is not dormant."
                                }
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
                                let missingEssence = max(0, cost - store.state.base.essence)
                                Button {
                                    if store.reactivateAnchoredRealm(realm.id) {
                                        actionFailure = nil
                                    } else {
                                        actionFailure = "The realm state or available Essence changed. Review it and try again."
                                    }
                                } label: {
                                    Label("Reactivate · \(cost) essence", systemImage: "sunrise.fill")
                                        .frame(maxWidth: .infinity).frame(minHeight: 44)
                                }
                                .buttonStyle(.bordered)
                                .disabled(store.state.base.essence < cost)
                                if missingEssence > 0 {
                                    Text("Needs \(missingEssence) more Essence to reactivate.")
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                }
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
        .alert("Anchorage action not completed", isPresented: Binding(
            get: { actionFailure != nil },
            set: { if !$0 { actionFailure = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(actionFailure ?? "The Anchorage changed before the action completed.")
        }
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
                AnchoredItemDetailButton(item: stack, selection: $opened) {
                    ItemIconTile(icon: stack.icon, catalogueID: stack.catalogID,
                                 rarity: stack.rarity,
                                 quantity: stack.count, identified: stack.identified,
                                 location: .waiting,
                                 accessibilityName: stack.displayName)
                } detail: { spilled in
                    SpilloverDetailSheet(spilled: spilled).environmentObject(store)
                }
            }
        }
    }
}

private struct SpilloverDetailSheet: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss
    @State private var isMakingRoom = false
    @State private var isConfirmingDiscard = false
    @State private var refusal: String?
    let spilled: ItemStack

    private var currentSpilled: ItemStack? {
        store.spillover.first { $0.id == spilled.id }
    }
    private var displaySpilled: ItemStack { currentSpilled ?? spilled }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 16) {
                        ItemIconTile(icon: displaySpilled.icon, catalogueID: displaySpilled.catalogID,
                                     rarity: displaySpilled.rarity,
                                     quantity: displaySpilled.count, identified: displaySpilled.identified,
                                     location: .waiting,
                                     accessibilityName: displaySpilled.displayName)
                            .frame(width: 58, height: 58)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(displaySpilled.displayName).font(.headline).foregroundStyle(displaySpilled.rarity.tint)
                            Text(currentSpilled == nil ? "No longer waiting" : "Waiting to sort")
                                .font(.caption).foregroundStyle(currentSpilled == nil ? .red : .secondary)
                        }
                    }
                }
                Section("Details") {
                    LabeledContent("Quantity", value: "\(displaySpilled.count)")
                    LabeledContent("Location", value: currentSpilled == nil
                                   ? "No longer waiting" : ItemGridLocation.waiting.displayName)
                    if !displaySpilled.detail.isEmpty { Text(displaySpilled.detail) }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) { sortingActionBar }
            .navigationTitle(spilled.identified ? spilled.displayName : "Unknown item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
            }
            .sheet(isPresented: $isMakingRoom) {
                SwapSheet(spilled: spilled).environmentObject(store)
            }
            .confirmationDialog(
                "Throw away \(displaySpilled.displayName)?",
                isPresented: $isConfirmingDiscard,
                titleVisibility: .visible
            ) {
                Button("Throw away \(displaySpilled.displayName)", role: .destructive,
                       action: discard)
                Button("Keep it waiting", role: .cancel) {}
            } message: {
                Text("This permanently removes the item from the waiting pile.")
            }
        }
    }

    private var sortingActionBar: some View {
        PersistentActionBar(message: refusal ?? "Nothing changes until one of these actions succeeds.",
                            messageTint: refusal == nil ? .secondary : .red) {
            HStack(spacing: 10) {
                Button(role: .destructive) {
                    isConfirmingDiscard = true
                } label: {
                    Text("Throw away").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)

                if store.state.base.inventory.isFull {
                    Button { isMakingRoom = true } label: {
                        Text("Make room").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button(action: storeCurrentItem) {
                        Text("Store it").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .controlSize(.large)
            .disabled(currentSpilled == nil)
        }
    }

    private func storeCurrentItem() {
        guard let currentSpilled,
              case .allowed(let quote) = store.storeSpilledQuote(currentSpilled)
        else {
            refusal = "The waiting pile or Storehouse changed. Review it and try again."
            return
        }
        switch store.storeSpilled(quote) {
        case .committed: dismiss()
        case .refused(let message): refusal = message
        }
    }

    private func discard() {
        guard let currentSpilled,
              case .allowed(let quote) = store.discardSpilledQuote(currentSpilled)
        else {
            refusal = "The waiting pile changed. Review it and try again."
            return
        }
        switch store.discardSpilled(quote) {
        case .committed: dismiss()
        case .refused(let message): refusal = message
        }
    }
}

/// Full Storehouse: pick what the new thing replaces. The thing it replaces goes back to the
/// spillover rather than being destroyed — still nothing lost without being asked.
private struct SwapSheet: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss
    let spilled: ItemStack
    @State private var opened: ItemStack?

    private var currentSpilled: ItemStack? {
        store.spillover.first { $0.id == spilled.id }
    }
    private var displaySpilled: ItemStack { currentSpilled ?? spilled }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Making room for").font(.headline)
                    HStack(spacing: 12) {
                        ItemIconTile(icon: displaySpilled.icon, catalogueID: displaySpilled.catalogID,
                                     rarity: displaySpilled.rarity,
                                     quantity: displaySpilled.count, identified: displaySpilled.identified,
                                     location: .waiting,
                                     accessibilityName: displaySpilled.displayName)
                            .frame(width: 52, height: 52)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(displaySpilled.displayName).font(.callout.weight(.medium))
                            if currentSpilled == nil {
                                Text("No longer waiting").font(.caption).foregroundStyle(.red)
                            } else {
                                Text("Quantity \(displaySpilled.count)")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    Text("Choose what returns to the waiting pile").font(.headline)
                    SixAcrossItemGrid(data: store.state.base.inventory.stacks, id: \.id) { stored in
                        AnchoredItemDetailButton(item: stored, selection: $opened) {
                            ItemIconTile(icon: stored.icon, catalogueID: stored.catalogID,
                                         rarity: stored.rarity,
                                         quantity: stored.count, identified: stored.identified,
                                         location: .stored,
                                         accessibilityName: stored.displayName)
                        } detail: { selected in
                            SwapStoredDetail(stored: selected, spilled: spilled) {
                                guard case .allowed(let quote) = store.swapSpilledQuote(
                                    spilled, for: selected
                                ) else {
                                    return .refused("The waiting pile or Storehouse changed. Review it and try again.")
                                }
                                return store.swapSpilled(quote)
                            } onCommitted: {
                                opened = nil
                                dismiss()
                            }
                        }
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

private struct SwapStoredDetail: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss
    let stored: ItemStack
    let spilled: ItemStack
    let confirm: () -> CurrentStateCommitResult
    let onCommitted: () -> Void
    @State private var refusal: String?

    private var currentStored: ItemStack? {
        store.state.base.inventory.stacks.first { $0.id == stored.id }
    }
    private var displayStored: ItemStack { currentStored ?? stored }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 16) {
                        ItemIconTile(icon: displayStored.icon, catalogueID: displayStored.catalogID,
                                     rarity: displayStored.rarity,
                                     quantity: displayStored.count, identified: displayStored.identified,
                                     location: .stored, accessibilityName: displayStored.displayName)
                            .frame(width: 58, height: 58)
                        Text(displayStored.displayName).font(.headline).foregroundStyle(displayStored.rarity.tint)
                    }
                }
                Section("Details") {
                    LabeledContent("Quantity", value: "\(displayStored.count)")
                    LabeledContent("Location", value: currentStored == nil
                                   ? "No longer stored" : ItemGridLocation.stored.displayName)
                    if !displayStored.detail.isEmpty { Text(displayStored.detail) }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) { swapActionBar }
            .navigationTitle(stored.identified ? stored.displayName : "Unknown item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
    }

    private var swapActionBar: some View {
        PersistentActionBar(message: refusal ?? "Nothing is discarded. This piece returns to the waiting pile.",
                            messageTint: refusal == nil ? .secondary : .red) {
            Button(action: commitSwap) {
                Text("Move this to waiting and store \(spilled.displayName)")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(currentStored == nil)
        }
    }

    private func commitSwap() {
        switch confirm() {
        case .committed:
            onCommitted()
            dismiss()
        case .refused(let message): refusal = message
        }
    }
}

/// Storehouse — inventory and identification. Identify flow is milestone 5.
struct StorehouseView: View {
    @EnvironmentObject private var store: GameStore
    @State private var opened: ItemStack?
    @State private var openedResource: StorehouseResourceEntry?
    @State private var openedPacked: ItemStack?
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
                    if base.resources.isEmpty && base.materialReserve.isEmpty {
                        EmptyNote("Nothing hauled home yet.")
                    } else {
                        SixAcrossItemGrid(data: resourceEntries, id: \.id) { entry in
                            AnchoredItemDetailButton(item: entry, selection: $openedResource) {
                                ResourceIconTile(resourceID: entry.id, icon: entry.icon, quantity: entry.amount,
                                                 accessibilityName: entry.name)
                            } detail: { selected in
                                StorehouseResourceDetail(entry: selected).environmentObject(store)
                            }
                        }
                        if base.resources[Resources.essenceRaw] > 0 {
                            // Raw essence looks like currency and isn't. Say so here rather than
                            // letting someone stare at a full storehouse and an unaffordable book.
                            Text("Raw essence can't be written with — refine it at the Essence Spring first.")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    if !reserveMaterialBins.isEmpty {
                        Text("Materials").font(.headline).frame(maxWidth: .infinity, alignment: .leading)
                        SixAcrossItemGrid(data: reserveMaterialBins, id: \.id) { bin in
                            AnchoredItemDetailButton(item: bin, selection: $opened) {
                                ItemIconTile(icon: bin.icon, catalogueID: bin.catalogID,
                                             materialKind: bin.material?.kind,
                                             rarity: bin.rarity, quantity: bin.count,
                                             identified: bin.identified, location: .stored,
                                             accessibilityName: bin.displayName)
                            } detail: { selected in
                                MaterialReserveSheet(kind: selected.material!.kind)
                                    .environmentObject(store)
                            }
                        }
                    }
                case .items:
                    HStack {
                        Label("Items", systemImage: "archivebox").font(.headline)
                        Spacer()
                        Text("\(base.inventory.stacks.count) of \(base.inventory.slots)")
                            .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                    }
                    if itemStacks.isEmpty {
                        EmptyNote("Eight slots, all empty. Items come from worlds.")
                    } else {
                        if !store.unidentifiedStacks.isEmpty { IdentifyCard() }
                        SixAcrossItemGrid(data: itemStacks, id: \.id) { stack in
                            AnchoredItemDetailButton(item: stack, selection: $opened) {
                                ItemIconTile(icon: stack.icon, catalogueID: stack.catalogID,
                                             rarity: stack.rarity,
                                             quantity: stack.count, identified: stack.identified,
                                             location: .stored,
                                             accessibilityName: stack.displayName)
                            } detail: { selected in
                                StorehouseItemSheet(stack: selected).environmentObject(store)
                            }
                        }
                    }
                case .satchel:
                    HStack {
                        Label("Field Kit", systemImage: "backpack").font(.headline)
                        Spacer()
                        Text("\(store.fieldKitEntries.filter { $0.desiredCount > 0 }.count) of \(base.satchelCapacity)")
                            .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                    }
                    Text("Choose desired quantities at Home. Exact available stock moves only when departure commits.")
                        .font(.caption).foregroundStyle(.secondary)
                    if base.preparationLoadoutNeedsReview {
                        Text("Suggested—review before departure")
                            .font(.caption.weight(.semibold)).foregroundStyle(.orange)
                        Button("Confirm suggested Field Kit") { _ = store.confirmSuggestedFieldKit() }
                    }
                    if store.fieldKitEntries.isEmpty {
                        EmptyNote("No supplies selected.")
                    } else {
                        SixAcrossItemGrid(data: store.fieldKitEntries, id: \.id) { entry in
                            let definition = ContentCatalog.shared.item(entry.itemID)
                            let planned = ItemStack(
                                id: InstanceID(rawValue: UInt64.max - UInt64(max(0, entry.order))),
                                catalogID: entry.itemID, count: entry.desiredCount, identified: true)
                            AnchoredItemDetailButton(item: planned, selection: $openedPacked) {
                                ItemIconTile(icon: definition?.icon ?? "questionmark",
                                             catalogueID: entry.itemID,
                                             rarity: definition?.rarity ?? .common,
                                             quantity: entry.desiredCount,
                                             identified: true, location: .stored,
                                             accessibilityName: definition?.name ?? "Planned supply")
                            } detail: { selected in
                                HomeSatchelItemSheet(stack: selected).environmentObject(store)
                            }
                        }
                    }
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
        .navigationTitle("Storehouse")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var resourceEntries: [StorehouseResourceEntry] {
        base.resources.nonZero.map { entry in
            let definition = ContentCatalog.shared.resource(entry.id)
            return StorehouseResourceEntry(id: entry.id,
                                           name: definition?.name ?? "Unknown resource",
                                           icon: definition?.icon ?? "cube",
                                           amount: entry.amount)
        }
    }

    private var reserveMaterialBins: [ItemStack] {
        Dictionary(grouping: base.materialReserve.units, by: { $0.sample.kind })
            .map { kind, units in
                let ordinal = MaterialKind.allCases.firstIndex(of: kind) ?? 0
                return ItemStack(id: .init(rawValue: UInt64.max - 1_000 - UInt64(ordinal)),
                                 catalogID: Items.material,
                                 materials: units.sorted { $0.id < $1.id }.map(\.sample))
            }
            .sorted { $0.material!.kind.rawValue < $1.material!.kind.rawValue }
    }
    private var itemStacks: [ItemStack] { base.inventory.stacks.filter(\.materials.isEmpty) }
}

private struct MaterialReserveSheet: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss
    let kind: MaterialKind

    private var current: [MaterialReserveUnit] {
        store.state.base.materialReserve.units(of: kind).sorted { $0.id < $1.id }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Reserve") {
                    LabeledContent("Quantity", value: "\(current.count)")
                    LabeledContent("Location", value: "Resources")
                }
                Section("Exact samples") {
                    if current.isEmpty {
                        Text("No longer stored").foregroundStyle(.secondary)
                    } else {
                        ForEach(current) { unit in
                            VStack(alignment: .leading, spacing: 3) {
                                Text(unit.sample.displayName).font(.headline)
                                Text(unit.sample.source.isEmpty ? "Unknown source" : unit.sample.source)
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle(kind.pluralName.capitalisedSentence)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
        }
    }
}

private struct StorehouseResourceEntry: Identifiable {
    let id: ResourceID
    let name: String
    let icon: String
    let amount: Int
}

private struct StorehouseResourceDetail: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss
    let entry: StorehouseResourceEntry

    private var currentAmount: Int { store.state.base.resources[entry.id] }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 16) {
                        ResourceIconTile(resourceID: entry.id, icon: entry.icon, quantity: currentAmount,
                                         accessibilityName: entry.name)
                            .frame(width: 58, height: 58)
                        Text(entry.name).font(.headline)
                    }
                }
                Section("Details") {
                    LabeledContent("Quantity", value: "\(currentAmount)")
                    LabeledContent("Location", value: currentAmount > 0 ? "Storehouse" : "No longer stored")
                    if entry.id == Resources.essenceRaw {
                        Text("Refine raw essence at the Essence Spring before writing with it.")
                    }
                }
            }
            .navigationTitle(entry.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
            }
        }
    }
}

private struct StorehouseItemSheet: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss
    let stack: ItemStack
    @State private var transferRefusal: String?

    private var currentStack: ItemStack? {
        store.state.base.inventory.stacks.first { $0.id == stack.id }
    }

    private var displayedStack: ItemStack { currentStack ?? stack }

    var body: some View {
        if !displayedStack.materials.isEmpty {
            MaterialBinSheet(bin: displayedStack).environmentObject(store)
        } else {
            NavigationStack {
                List {
                    Section {
                        HStack(spacing: 16) {
                            ItemIconTile(icon: displayedStack.icon, catalogueID: displayedStack.catalogID,
                                         rarity: displayedStack.rarity,
                                         quantity: displayedStack.count, identified: displayedStack.identified,
                                         location: .stored, accessibilityName: displayedStack.displayName)
                                .frame(width: 58, height: 58)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(displayedStack.displayName).font(.headline).foregroundStyle(displayedStack.rarity.tint)
                                Text(displayedStack.rarity.displayName).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    Section("Details") {
                        LabeledContent("Quantity", value: "\(displayedStack.count)")
                        LabeledContent("Location", value: currentStack == nil
                                       ? "No longer stored" : ItemGridLocation.stored.displayName)
                        if !displayedStack.detail.isEmpty { Text(displayedStack.detail) }
                        if let profile = displayedStack.gearProfile {
                            LabeledContent("Tier", value: "\(profile.constructionTier)")
                            LabeledContent("Reforge", value: "\(profile.reforgeRank) of \(SmithRules.maximumReforgeLevel)")
                            if let provenance = profile.displayProvenance {
                                LabeledContent("Provenance", value: provenance)
                            }
                        } else if let blurb = ContentCatalog.shared.item(displayedStack.catalogID)?.blurb,
                                  !blurb.isEmpty {
                            Text(blurb)
                        }
                    }
                    if currentStack != nil, displayedStack.identified,
                       GameStore.isFieldKitEligible(displayedStack.catalogID) {
                        Section("Next expedition") {
                            Button("Add one to plan") {
                                let desired = store.fieldKitDesiredCount(for: displayedStack.catalogID)
                                if case .refused(let reason) = store.setFieldKitDesiredCount(
                                    itemID: displayedStack.catalogID, desiredCount: desired + 1) {
                                    transferRefusal = reason
                                }
                            }
                        }
                    }
                }
                .navigationTitle(displayedStack.identified ? displayedStack.displayName : "Unknown item")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
                }
                .alert("Transfer not completed", isPresented: Binding(
                    get: { transferRefusal != nil }, set: { if !$0 { transferRefusal = nil } })) {
                    Button("OK") { transferRefusal = nil }
                } message: { Text(transferRefusal ?? "Review the current Storehouse and Field Kit.") }
            }
        }
    }
}

private struct HomeSatchelItemSheet: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss
    let stack: ItemStack
    @State private var transferRefusal: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                ItemIconTile(icon: stack.icon, catalogueID: stack.catalogID, rarity: stack.rarity,
                             quantity: stack.count, identified: stack.identified, location: .carried,
                             accessibilityName: stack.displayName)
                    .frame(width: 64, height: 64)
                Text(stack.displayName).font(.headline)
                Text("Wanted \(store.fieldKitDesiredCount(for: stack.catalogID)) · available \(store.fieldKitOwnedCount(for: stack.catalogID))")
                    .font(.caption).foregroundStyle(.secondary)
                Button("Increase desired quantity") {
                    let desired = store.fieldKitDesiredCount(for: stack.catalogID)
                    if case .refused(let reason) = store.setFieldKitDesiredCount(
                        itemID: stack.catalogID, desiredCount: desired + 1) {
                        transferRefusal = reason
                    }
                }
                Button("Reduce desired quantity") {
                    let desired = store.fieldKitDesiredCount(for: stack.catalogID)
                    switch store.setFieldKitDesiredCount(itemID: stack.catalogID,
                                                         desiredCount: max(0, desired - 1)) {
                    case .committed: dismiss()
                    case .refused(let reason): transferRefusal = reason
                    }
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity, minHeight: 44)
                Spacer()
            }
            .padding(16)
            .navigationTitle("Planned supply")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
            .alert("Transfer not completed", isPresented: Binding(
                get: { transferRefusal != nil }, set: { if !$0 { transferRefusal = nil } })) {
                Button("OK") { transferRefusal = nil }
            } message: { Text(transferRefusal ?? "Review the current Storehouse and Field Kit.") }
        }
    }
}

private enum StorehouseTab: String, CaseIterable, Identifiable {
    case items, stockpiles, satchel, waiting
    var id: String { rawValue }
    var title: String {
        switch self {
        case .items: "Items"
        case .stockpiles: "Resources"
        case .satchel: "Field Kit"
        case .waiting: "Waiting"
        }
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

                ResearchTree()
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
    @State private var upgradeFailure: String?
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
                    Button("Improve") {
                        if store.improveInstrument(target.id) {
                            upgradeFailure = nil
                        } else {
                            upgradeFailure = "The qualifying stock or Essence changed. Review this instrument's requirements and try again."
                        }
                    }
                        .buttonStyle(.borderedProminent)
                        .frame(minWidth: 72, minHeight: 44)
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
        .alert("Instrument not improved", isPresented: Binding(
            get: { upgradeFailure != nil },
            set: { if !$0 { upgradeFailure = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(upgradeFailure ?? "The instrument could not be improved.")
        }
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
    @State private var selectedNode: ConstellationNodeDef?

    var body: some View {
        VStack(spacing: 24) {
            CurrencyChip(icon: "star.fill", label: "Motes",
                         value: "\(store.state.reality.motes)", tint: .purple)
                .accessibilitySortPriority(3)

            Spacer(minLength: 24)
            HStack(spacing: 28) {
                ForEach(ContentCatalog.shared.constellationNodes) { node in
                    AnchoredItemDetailButton(item: node, selection: $selectedNode) {
                        ConstellationStar(node: node)
                    } detail: { node in
                        ConstellationNodeDetail(node: node).environmentObject(store)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .accessibilitySortPriority(2)
            Spacer(minLength: 24)

            Text("The Constellation changes Reality itself, rather than one building or one person.")
                .font(.callout).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .accessibilitySortPriority(1)
            Spacer()
        }
        .padding(16)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Constellation")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ConstellationStar: View {
    @EnvironmentObject private var store: GameStore
    let node: ConstellationNodeDef

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle().fill(fill)
                Circle().strokeBorder(.purple, style: stroke)
                Image(systemName: starIcon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(foreground)
            }
            .frame(width: 64, height: 64)
            Text(node.name).font(.subheadline.weight(.semibold)).multilineTextAlignment(.center)
            Text(state.label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(minWidth: 150, minHeight: 112)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(node.name), \(state.label), rank \(rank) of \(node.maxRank)")
        .accessibilityHint("Shows effect, cost and purchase action")
    }

    private var rank: Int { store.state.reality.rank(of: node.id) }
    private var state: ConstellationNodePresentationState {
        ConstellationNodePresentationState.resolve(
            rank: rank, maxRank: node.maxRank, cost: store.moteCost(of: node),
            motes: store.state.reality.motes)
    }
    private var fill: Color {
        switch state {
        case .affordable: .purple.opacity(0.18)
        case .shortfall: Color(.secondarySystemGroupedBackground)
        case .bought: .purple
        }
    }
    private var stroke: StrokeStyle {
        switch state {
        case .shortfall: StrokeStyle(lineWidth: 2, dash: [5, 4])
        case .affordable, .bought: StrokeStyle(lineWidth: 2)
        }
    }
    private var starIcon: String { state == .bought ? "checkmark.star.fill" : "star.fill" }
    private var foreground: Color { state == .bought ? .white : .purple }
}

/// Essence Spring — the trickle credited on each return from a run.
struct EssenceSpringView: View {
    @EnvironmentObject private var store: GameStore
    @State private var tab: EssenceSpringTab = .refine
    @State private var pendingUnlearning: PartyMember?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    CurrencyChip(icon: "drop.fill", label: "Essence",
                                 value: "\(store.state.base.essence)", tint: .teal)
                    CurrencyChip(icon: "arrow.down.circle", label: "Return",
                                 value: "+\(store.essenceSpringYield)")
                    CurrencyChip(icon: "chart.bar", label: "Tier",
                                 value: "\(store.state.base.station(Stations.essenceSpring).tier)")
                }

                Picker("Spring section", selection: $tab) {
                    ForEach(EssenceSpringTab.allCases) { item in Text(item.title).tag(item) }
                }
                .pickerStyle(.segmented)
                .frame(minHeight: 44)

                switch tab {
                case .refine:
                    RefineryCard()
                    refiningPractice
                case .study:
                    ResearchTree(station: Stations.essenceSpring)
                case .unlearn:
                    unlearning
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Essence Spring")
        .navigationBarTitleDisplayMode(.inline)
        .alert(unlearningTitle, isPresented: Binding(
            get: { pendingUnlearning != nil },
            set: { if !$0 { pendingUnlearning = nil } }
        )) {
            Button("Cancel", role: .cancel) { pendingUnlearning = nil }
            Button("Unlearn", role: .destructive) {
                guard let member = pendingUnlearning else { return }
                pendingUnlearning = nil
                store.respec(member)
            }
        } message: {
            Text(unlearningMessage)
        }
    }

    private var unlearningTitle: String {
        guard let member = pendingUnlearning else { return "Unlearn techniques?" }
        return "Unlearn \(store.name(of: member))'s techniques?"
    }

    private var unlearningMessage: String {
        guard let member = pendingUnlearning else { return "" }
        let points = CombatTreeRules.spentPoints(store.character(of: member))
        let cost = store.respecCost(for: member)
        return "This returns \(points) learned points and costs \(cost) essence."
    }

    private var refiningPractice: some View {
        StationCard(title: "Refining practice", icon: "arrow.triangle.2.circlepath") {
            let practiced = store.state.base.lifetimeRawEssenceRefined
            LabeledRow(icon: "drop", label: "Lifetime Raw refined", value: "\(practiced)")
            LabeledRow(icon: "arrow.right", label: "Current conversion",
                       value: "1 Raw → \(EconomyRules.refinementRate(in: store.state)) Essence")
            if !store.state.base.completedResearch.contains(EconomyRules.secondPassNode) {
                let remaining = max(0, EconomyRules.secondPassPracticeRequired - practiced)
                Text(remaining == 0 ? "Second pass practice complete."
                     : "Refine \(remaining) more Raw Essence to qualify for Second pass.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            if store.state.base.completedResearch.contains(EconomyRules.continuousSettlingNode) {
                Toggle("Auto-refine newly returned Raw", isOn: Binding(
                    get: { store.state.base.autoRefineReturnedRawEssence },
                    set: { store.setAutoRefineReturnedRawEssence($0) }
                ))
                .frame(minHeight: 44)
            }
        }
    }

    private var unlearning: some View {
        StationCard(title: "Unlearning", icon: "arrow.uturn.backward.circle") {
            Text("Reclaim somebody's spent points for an Essence cost.")
                .font(.caption2).foregroundStyle(.secondary)
            ForEach([PartyMember.binder] + store.state.base.roster.indices.map(PartyMember.member)) { member in
                let cost = store.respecCost(for: member)
                HStack(spacing: 8) {
                    if let index = member.rosterIndex,
                       store.state.base.roster.indices.contains(index) {
                        let person = store.state.base.roster[index]
                        NamedCharacterPixelIdentity(
                            travellerID: person.traveller,
                            fallbackSystemIcon: person.icon,
                            fallbackColor: .secondary
                        )
                        .frame(width: 24, height: 24)
                    } else {
                        Image(systemName: "figure.stand")
                            .foregroundStyle(.secondary)
                            .frame(width: 24, height: 24)
                            .accessibilityHidden(true)
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text(store.name(of: member)).font(.callout)
                        Text(cost == 0 ? "nothing spent yet"
                             : "\(CombatTreeRules.spentPoints(store.character(of: member))) points learned")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 6)
                    Button(cost == 0 ? "Nothing to unlearn" : "Unlearn · \(cost)") {
                        pendingUnlearning = member
                    }
                        .font(.caption2.weight(.medium))
                        .buttonStyle(.bordered)
                        .disabled(!store.canRespec(member))
                }
                .frame(minHeight: 44)
            }
        }
    }
}

enum EssenceSpringTab: String, CaseIterable, Identifiable, Sendable {
    case refine, study, unlearn
    var id: String { rawValue }
    var title: String {
        switch self {
        case .refine: "Refine"
        case .study: "Study"
        case .unlearn: "Unlearn"
        }
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

    private var currentBin: ItemStack? {
        store.state.base.inventory.stacks.first { $0.id == bin.id }
    }

    private var displayedBin: ItemStack { currentBin ?? bin }

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
                            MaterialSamplePixelIdentity(kind: sample.kind,
                                                        fallbackColor: sample.rarity.tint)
                                .frame(width: 28, height: 28)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(sample.displayName)
                                    .font(.callout)
                                    .foregroundStyle(sample.rarity.tint)
                                if !sample.source.isEmpty {
                                    Text("From \(sample.source)")
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
                    Text(currentBin == nil
                         ? "This material bin is no longer in the Storehouse."
                         : "All \(displayedBin.count) share one slot. Every one keeps its own grade and the animal it came off.")
                }
            }
            .navigationTitle(displayedBin.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
            }
        }
    }

    private var sorted: [MaterialSample] {
        let materials = currentBin?.materials ?? []
        return switch order {
        case .grade: materials.sorted { $0.grade > $1.grade }
        case .source: materials.sorted { ($0.source, $0.grade) < ($1.source, $1.grade) }
        case .order: materials
        }
    }
}
