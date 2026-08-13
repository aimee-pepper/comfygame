import SwiftUI

enum WorldControlsLayout {
    static let actionCount = 2
    static let actionRows = 1
    static let actionHeight: CGFloat = 48
}

/// A closed two-slot strip prevents action growth from silently adding fixed rows and obscuring
/// the scrollable event/satchel content above the controls.
private struct WorldActionRow<Interact: View, Look: View>: View {
    @ViewBuilder let interact: () -> Interact
    @ViewBuilder let look: () -> Look

    var body: some View {
        HStack(spacing: 6) {
            interact().frame(maxWidth: .infinity)
            look().frame(maxWidth: .infinity)
        }
        .frame(height: WorldControlsLayout.actionHeight)
    }
}

/// The world: stability at the top, the grid in the middle, your hands at the bottom.
///
/// Ergonomics note. A 14×14 grid can't give every tile a 44pt target on a 402pt-wide phone — that
/// would need a 616pt screen. So the grid is a *map*, not a control surface: tapping a tile is the
/// planning gesture (walk there), while the primary one-handed control is the D-pad in the thumb
/// zone, which the brief offers for exactly this reason. Every button is ≥44pt.
struct WorldView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.displayScale) private var displayScale
    /// Everything that crossed the threshold and can be consulted or used outside combat.
    @State private var isShowingFieldKit = false
    @State private var isConfirmingAtlasSeam = false
    @State private var isConfirmingAnchorFrame = false
    @State private var isLookArmed = false
    @State private var inspection: InspectionPresentation?
    @State private var tutorialLesson: TutorialLessonID?
    @State private var dismissedTutorials: Set<TutorialLessonID> = []
#if DEBUG
    @State private var isShowingDiagnostics = false
#endif

    private var run: WorldRun? { store.state.worlds.activeRun }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                if let run {
                    StabilityHeader(run: run)
                    PartyHealthStrip(run: run, state: store.state)
                    GeometryReader { viewport in
                        ScrollView {
                            VStack(spacing: 12) {
                                LootDecisionCard()
                                MapGrid(
                                    run: run,
                                    maximumSide: WorldMapLayout.maximumSide(
                                        containerWidth: viewport.size.width,
                                        viewportHeight: viewport.size.height,
                                        viewportTiles: min(Tuning.World.viewportTiles,
                                                           min(run.map.width, run.map.height)),
                                        displayScale: displayScale
                                    )
                                ) { point in
                                    tapped(point, in: run)
                                }
                                eventLog
                                satchel(run)
                            }
                            .padding(.horizontal, 12)
                            .padding(.top, 8)
                            .padding(.bottom, 12)
                        }
                    }
                    controls(run)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
#if DEBUG
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { isShowingDiagnostics = true } label: { Image(systemName: "stethoscope") }
                    .accessibilityLabel("World diagnostics")
            }
        }
        .sheet(isPresented: $isShowingDiagnostics) {
            if let run { WorldDiagnosticsView(run: run, concealment: WorldRules.fieldConcealment(in: store.state)) }
        }
#endif
        // **Standing on somebody opens the scene.** Driven off the map rather than off an event, so
        // a force-quit mid-conversation resumes with the conversation still open — you are still
        // standing there, and they are still waiting (pillar 2).
        .sheet(item: Binding(get: { store.travellerHere }, set: { _ in })) { traveller in
            TravellerMeetingView(traveller: traveller).environmentObject(store)
        }
        .sheet(isPresented: $isShowingFieldKit) {
            FieldKitSheet().environmentObject(store)
        }
        .alert("Bind this world at the Atlas Seam?", isPresented: $isConfirmingAtlasSeam) {
            Button("Cancel", role: .cancel) {}
            Button("Anchor for \(store.naturalAnchorCost) essence") {
                store.anchorAtNaturalPoint()
            }
        } message: {
            Text("The realm will remain in Tovin's Anchorage and can be revisited after this expedition ends.")
        }
        .alert("Place the Anchor Frame here?", isPresented: $isConfirmingAnchorFrame) {
            Button("Cancel", role: .cancel) {}
            Button("Place frame") { store.placeAnchorFrame() }
        } message: {
            Text("The frame will be consumed and this realm will remain in the Anchorage. No additional essence is charged.")
        }
        .alert(item: $inspection) { result in
            Alert(title: Text(result.value.heading), message: Text(result.value.details.joined(separator: " · ")),
                  dismissButton: .default(Text("Done")))
        }
        .overlay(alignment: .bottom) {
            if let id = tutorialLesson, let lesson = TutorialRules.definition(id), !tutorialSuppressed {
                TutorialCard(lesson: lesson,
                             gotIt: { dismissedTutorials.insert(id); tutorialLesson = nil },
                             notNow: {
                                 dismissedTutorials.insert(id)
                                 store.deferTutorial(id)
                                 tutorialLesson = nil
                             })
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                    .transition(.opacity)
            }
        }
        .onAppear { presentNextWorldLesson() }
        .onChange(of: run?.playerPosition) { old, new in
            guard old != new else { return }
            if store.state.tutorial[.worldNavigation].status != .completed {
                present(.worldNavigation)
                store.completeTutorial(.worldNavigation, fact: "first_movement")
            }
            presentNextWorldLesson()
        }
        .onChange(of: run?.turnsTaken) { old, new in
            guard let old, let new, new > old else { return }
            if store.state.tutorial[.worldStability].status != .completed {
                present(.worldStability)
                store.completeTutorial(.worldStability, fact: "post_turn_meter_seen")
            }
        }
    }

    /// Tap an adjacent tile to step; tap anywhere else to walk there turn by turn.
    private func tapped(_ point: GridPoint, in run: WorldRun) {
        isLookArmed = false
        if WorldRules.isAdjacent(run.playerPosition, point) {
            store.step(to: point)
        } else {
            store.travel(to: point)
        }
    }

    // MARK: Narration

    /// Only the events worth saying out loud. Several — moving, the encounter opening — are better
    /// shown than narrated, so the log stays quiet rather than rendering an empty box.
    private var narratedEvents: [(line: String, colour: Color)] {
        store.recentEvents.compactMap { event in
            narrate(event).map { (line: $0, colour: colour(for: event)) }
        }
    }

    @ViewBuilder
    private var eventLog: some View {
        let lines = narratedEvents
        if !lines.isEmpty {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(Array(lines.enumerated()), id: \.offset) { _, entry in
                    Text(entry.line)
                        .font(.caption)
                        .foregroundStyle(entry.colour)
                        // Wraps rather than demanding a line's worth of width. Same hazard the
                        // haul row had: inside a scrolling `VStack`, a child that wants to be wide
                        // makes every sibling wide, and the map is the sibling that suffers.
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
        }
    }

    private func narrate(_ event: WorldRules.Event) -> String? {
        switch event {
        case .moved: nil // the map already says where you are
        case .enteredSlowGround(let ground): "Crossing \(ground) took an extra turn."
        case .blocked(let why): why
        case .pickedUp(let resource, let amount):
            "Picked up \(amount) \(ContentCatalog.shared.resource(resource)?.name.lowercased() ?? "something")."
        case .harvested(let resource, let amount, let exhausted):
            "Harvested \(amount) \(ContentCatalog.shared.resource(resource)?.name.lowercased() ?? "something")."
                + (exhausted ? " The node is spent." : "")
        case .foundPortal: "A way out."
        case .foundCache: "A cache, locked. The key is somewhere else."
        case .cacheOpened(let what): "The lock gives. \(what)"
        case .readPage(let id):
            ContentCatalog.shared.diaryPage(id).map { "A page, in somebody's hand. \"\($0.prose)\"" }
                ?? "A page from someone's diary."
        case .readFoundWriting(_, let prose): "A weathered field note. \"\(prose)\""
        case .foundTraveller(let id):
            ContentCatalog.shared.traveller(id).map { "\($0.name) is coming with you." }
                ?? "They're coming with you."
        case .usedItem(let what, let member):
            "\(what). \(member == .binder ? "You feel" : "They feel") better."
        case .surveyed(let readings):
            "Surveyed: " + readings.map { "\($0.name) \($0.text)" }.joined(separator: ", ") + "."
        case .metTraveller(let id):
            ContentCatalog.shared.traveller(id).map { "\($0.name), \($0.calling). \($0.blurb)" }
                ?? "Someone is here."
        case .nightfall: "The light goes. You can see less of this than you could."
        case .daybreak: "It comes back around. You can see again."
        case .foundSite(let site):
            ContentCatalog.shared.site(site).map { "\($0.name). \($0.blurb)" } ?? "Something built."
        case .searchedSite(_, let remaining):
            "Searching. \(remaining) more turn\(remaining == 1 ? "" : "s")."
        case .siteOpened(let site):
            "You've had everything \(ContentCatalog.shared.site(site)?.name.lowercased() ?? "it") has."
        case .learnedSymbol(let symbol):
            "You can write \(ContentCatalog.shared.symbol(symbol)?.name ?? "something new") now."
        case .learnedFocus(let focus):
            "A word you didn't have: \(ContentCatalog.shared.pressureSource(focus)?.name ?? "something new")."
        case .learnedGambit(let component):
            "A gambit phrase you didn't have: \(ContentCatalog.shared.gambitComponent(component)?.name ?? "something new")."
        case .learnedPattern: "A workshop pattern you didn't have."
        case .gainedEssence(let amount): "\(amount) essence, banked."
        case .pickedUpItem(let what): "\(what) You can't tell what it is."
        case .satchelFull(let what): "No room in your satchel — \(what.lowercased()) is waiting on you."
        case .hazardHit(let damage): "The ground turns on you — \(damage) damage."
        case .scratchedByGrowth(let name, let damage, let lingers):
            lingers
                ? "You push through the \(name). \(damage) damage, and it's still working."
                : "The \(name) tears at you — \(damage) damage."
        case .poisonWorking(let damage): "Whatever that was is still in you — \(damage) damage."
        case .enemySighted(let name): "A \(name) has noticed you."
        case .enemyAlerted(let name): "A \(name) pauses, alert to your movement."
        case .encounterBegan: nil // the encounter bar takes over
        case .crossedThreshold(let band):
            switch band {
            case .stable: nil
            case .hazardous: "The edges are starting to go."
            case .crumbling: "The world is crumbling inward."
            case .collapsed: "The world is coming apart. Get to a portal while there's floor."
            }
        case .tilesCrumbled(let count): count > 0 ? "\(count) tiles gone." : nil
        case .lostToCrumbling(let count):
            count == 1 ? "Something you hadn't taken went with it." : "\(count) things you hadn't taken went with it."
        case .collapsed: "The world is coming apart. Get to a portal."
        case .floorGaveWay: "The ground goes out from under you."
        case .ejected(let reason): reason
        }
    }

    private func colour(for event: WorldRules.Event) -> Color {
        switch event {
        case .pickedUp, .harvested, .foundPortal, .pickedUpItem, .searchedSite, .siteOpened: .primary
        case .foundSite, .learnedSymbol, .learnedFocus, .learnedGambit, .learnedPattern, .gainedEssence: .primary
        case .readPage, .foundTraveller, .metTraveller: .primary
        case .usedItem, .surveyed: .green
        case .enteredSlowGround: .orange
        case .nightfall, .daybreak: .secondary
        case .cacheOpened: .purple
        case .satchelFull: .orange
        case .hazardHit, .collapsed, .floorGaveWay, .ejected, .lostToCrumbling: .red
        case .scratchedByGrowth, .poisonWorking: .red
        case .enemySighted, .enemyAlerted, .crossedThreshold, .blocked: .orange
        default: .secondary
        }
    }

    // MARK: Satchel

    /// What you're carrying, and how long you've been at it.
    ///
    /// **The haul scrolls sideways.** With four resources in the game this was a fixed row; with
    /// twenty-three, carrying enough variety made the row wider than the phone — and because a
    /// `VStack` takes the width of its widest child, the *map* grew to match and walked off the
    /// edge of the screen (Aimee, 6 Aug). Health and the turn count stay pinned outside the scroll,
    /// because those two are what you actually check.
    private func satchel(_ run: WorldRun) -> some View {
        HStack(spacing: 12) {
            if run.satchel.isEmpty {
                Text("satchel empty").foregroundStyle(.secondary)
                Spacer(minLength: 0)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(run.satchel.nonZero, id: \.id) { entry in
                            Label("\(entry.amount)",
                                  systemImage: ContentCatalog.shared.resource(entry.id)?.icon ?? "cube")
                            .fixedSize()
                        }
                    }
                    .padding(.trailing, 4)
                }
                // Never lets its content dictate the row's width — the whole point of the fix.
                .frame(maxWidth: .infinity)
            }

            Button { isShowingFieldKit = true } label: {
                    Label("Field Kit", systemImage: "backpack.fill")
                        .labelStyle(.titleAndIcon)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.teal)
            .fixedSize()
            .accessibilityIdentifier("world.field-kit")
            Text("turn \(run.turnsTaken)").foregroundStyle(.secondary).fixedSize()
        }
        .font(.footnote.monospacedDigit())
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: Controls — thumb zone

    private func controls(_ run: WorldRun) -> some View {
        HStack(alignment: .bottom, spacing: 14) {
            DirectionPad(isLooking: isLookArmed) { direction in
                let point = GridPoint(x: run.playerPosition.x + direction.dx,
                                      y: run.playerPosition.y + direction.dy)
                if isLookArmed {
                    inspection = InspectionPresentation(value: WorldRules.inspect(point, in: run))
                    isLookArmed = false
                } else {
                    store.step(to: point)
                }
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 6) {
                // The map belongs beside the movement tool, using the space above the portal/action
                // column. Putting it under the arrows needlessly made the fixed controls taller and
                // was a regression from the settled phone layout.
                MinimapView(run: run)
                    .frame(maxWidth: .infinity, alignment: .center)
                // One invariant action row. Adding a world action must never create another fixed
                // control row and steal the event/satchel viewport above it.
                WorldActionRow {
                    ActionButton("Interact", icon: "hand.tap.fill",
                                 isProminent: canInteract,
                                 isEnabled: canInteract) {
                        performInteraction()
                    }
                    .accessibilityValue(interactionDetail(in: run))
                    .accessibilityIdentifier("world.interact")

                } look: {
                    Button {
                        isLookArmed.toggle()
                    } label: {
                        Label(isLookArmed ? "Cancel" : "Look",
                              systemImage: isLookArmed ? "eye.fill" : "eye")
                            .font(.callout.weight(.medium))
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, minHeight: 48)
                    }
                    .buttonStyle(.bordered)
                    .overlay {
                        if isLookArmed {
                            RoundedRectangle(cornerRadius: 8).stroke(.primary, lineWidth: 2)
                        }
                    }
                    .accessibilityLabel(isLookArmed ? "Cancel Look" : "Look")
                    .accessibilityHint(isLookArmed
                        ? "Look mode armed. Choose one direction."
                        : "Inspect one adjacent tile without moving or spending a turn.")
                    .accessibilityIdentifier("world.look")
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("world.action-row")
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .background(.bar)
    }

    private var canInteract: Bool {
        store.harvestableHere != nil || store.searchableHere != nil || store.canPortalHere
            || (store.isOnLockedCache && store.carriedCacheKey != nil)
            || store.canUseNaturalAnchor || store.canPlaceAnchorFrame || store.canSurvey
    }

    private func interactionDetail(in run: WorldRun) -> String {
        if let node = store.harvestableHere {
            return "Harvest \(ContentCatalog.shared.resource(node.resource)?.name ?? "resource") · \(node.remainingHarvests) left"
        }
        if let site = store.searchableHere, let definition = site.definition {
            return "Search \(definition.name) · \(site.searchTurnsRemaining) turns left"
        }
        if store.canPortalHere { return "Portal home · keep everything" }
        if store.isOnLockedCache {
            return store.carriedCacheKey == nil ? "Locked cache · needs a key" : "Open cache · spends your key"
        }
        if store.canUseNaturalAnchor { return "Use Atlas Seam · \(store.naturalAnchorCost) essence" }
        if store.canPlaceAnchorFrame { return "Place Anchor Frame here" }
        if store.canSurvey { return "Survey · \(run.carriedInstruments.count) instruments · 1 turn" }
        if store.naturalAnchorHere != nil {
            return "Atlas Seam · needs Anchorage and \(store.naturalAnchorCost) essence"
        }
        if store.carriedAnchorFrame != nil { return "Anchor Frame · needs clear ordinary ground" }
        return hint(for: run)
    }

    private func performInteraction() {
        if store.harvestableHere != nil {
            completeInteraction(); store.harvest()
        } else if store.searchableHere != nil {
            completeInteraction(); store.searchSite()
        } else if store.canPortalHere {
            store.completeTutorial(.worldReturn, fact: "first_expedition_outcome")
            store.portalHome()
        } else if store.isOnLockedCache, store.carriedCacheKey != nil {
            completeInteraction(); store.openCacheHere()
        } else if store.canUseNaturalAnchor {
            completeInteraction(); isConfirmingAtlasSeam = true
        } else if store.canPlaceAnchorFrame {
            completeInteraction(); isConfirmingAnchorFrame = true
        } else if store.canSurvey {
            completeInteraction(); store.survey()
        }
    }

    private func hint(for run: WorldRun) -> String {
        switch run.stabilityBand {
        case .stable: "Tap a tile to walk there."
        case .hazardous: "Hazards are forming at the edges."
        case .crumbling: "The world is falling in. Find a portal."
        case .collapsed: "Gone."
        }
    }

    private var tutorialSuppressed: Bool {
        guard let run else { return true }
        return run.activeEncounter != nil || !run.offeredItems.isEmpty
    }

    private var hasActionHere: Bool {
        store.canSurvey || store.harvestableHere != nil || store.searchableHere != nil
            || store.naturalAnchorHere != nil || store.canPlaceAnchorFrame || store.canPortalHere
            || store.isOnLockedCache
    }

    private func present(_ id: TutorialLessonID) {
        guard tutorialLesson == nil, !tutorialSuppressed,
              !dismissedTutorials.contains(id),
              store.state.tutorial[id].status != .completed else { return }
        store.tutorialEligible(id)
        tutorialLesson = id
    }

    private func presentNextWorldLesson() {
        guard tutorialLesson == nil, !tutorialSuppressed, let run else { return }
        if store.state.tutorial[.worldNavigation].status != .completed {
            present(.worldNavigation)
        } else if run.turnsTaken > 0 && store.state.tutorial[.worldStability].status != .completed {
            present(.worldStability)
        } else if hasActionHere && store.state.tutorial[.worldInteraction].status != .completed {
            present(.worldInteraction)
        } else if store.canPortalHere && store.state.tutorial[.worldReturn].status != .completed {
            present(.worldReturn)
        }
    }

    private func completeInteraction() {
        store.completeTutorial(.worldInteraction, fact: "first_valid_world_action")
        if tutorialLesson == .worldInteraction { tutorialLesson = nil }
    }
}

#if DEBUG
private struct WorldDiagnosticsView: View {
    @Environment(\.dismiss) private var dismiss
    let run: WorldRun
    let concealment: WorldRules.FieldConcealment

    private var nodes: [ResourceID: Int] {
        run.map.tiles.reduce(into: [:]) { result, tile in
            if case .node(let node) = tile.content {
                result[node.resource, default: 0] += node.remainingHarvests * node.yieldPerHarvest
            }
        }
    }
    var body: some View {
        NavigationStack {
            List {
                Section("Identity") {
                    LabeledRow(icon: "number", label: "Seed", value: "\(run.mapSeed)")
                    LabeledRow(icon: "clock", label: "Turn", value: "\(run.turnsTaken)")
                }
                Section("Writing") {
                    let report = run.generationDiagnostics
                    LabeledRow(icon: "checkmark.seal", label: "Guaranteed", value: report.writingWasGuaranteed ? "yes" : "no")
                    LabeledRow(icon: "book.pages", label: "Diary selected / placed",
                               value: "\(report.selectedDiaryPages.count) / \(report.placedDiaryPages.count)")
                    LabeledRow(icon: "note.text", label: "Other selected / placed",
                               value: "\(report.selectedOtherWritingCount) / \(report.placedOtherWritings.count)")
                    LabeledRow(icon: "dice", label: "Second-writing roll",
                               value: report.secondWritingRollSucceeded ? "succeeded" : "missed")
                    LabeledRow(icon: "percent", label: "Diary mix snapshot",
                               value: run.tuning.diaryWritingShare.formatted(.percent.precision(.fractionLength(0))))
                    LabeledRow(icon: "hourglass", label: "Patience floor", value: "\(run.tuning.diaryPatienceWorlds) worlds")
                }
                Section("Population") {
                    let report = run.generationDiagnostics
                    LabeledRow(icon: "hare", label: "Creature species", value: "\(report.creatureSpeciesCount)")
                    LabeledRow(icon: "pawprint", label: "Creature instances placed", value: "\(report.creatureInstancesPlaced)")
                    LabeledRow(icon: "crown", label: "Apex roll / result",
                               value: "\(report.apexChance.formatted(.percent.precision(.fractionLength(1)))) · \(report.apexRollSucceeded ? "hit" : "miss") · \(report.apexPlaced ? "placed" : "none")")
                    LabeledRow(icon: "leaf", label: "Flora species / instances",
                               value: "\(report.floraSpeciesCount) / \(report.floraInstancesPlaced)")
                    LabeledRow(icon: "burst", label: "Active flora placed", value: "\(report.activeFloraPlaced)")
                }
                Section("Field awareness") {
                    LabeledRow(icon: "figure.walk", label: "Quiet Step / radius reduction",
                               value: "\(concealment.quietStep ? "yes" : "no") / -\(concealment.radiusReduction)")
                    ForEach(run.enemies) { enemy in
                        let state: String = switch enemy.awareness {
                        case .unaware: "unaware"
                        case .pursuing: "pursuing"
                        case .alert(_, let reason): "alert · \(reason.rawValue)"
                        }
                        LabeledRow(icon: enemy.isApex ? "crown" : "eye",
                                   label: run.name(of: enemy),
                                   value: "\(state) · base r\(WorldRules.detectionRadius(of: enemy, in: run)) · quiet used \(enemy.quietStepHesitationUsed ? "yes" : "no")")
                    }
                }
                Section("World duration") {
                    LabeledRow(icon: "gauge", label: "Stability score", value: "\(run.effectiveStabilityScore)")
                    LabeledRow(icon: "timer", label: "Turns remaining",
                               value: "\(max(0, Int(ceil(run.stability / max(0.01, run.decayPerTurn)))))")
                    LabeledRow(icon: "flag.checkered", label: "Initial budget / projected collapse",
                               value: "\(run.generationDiagnostics.initialTurnBudget) / turn \(run.generationDiagnostics.projectedCollapseTurn)")
                    LabeledRow(icon: "shippingbox", label: "Collapse recovery",
                               value: run.tuning.collapseRecoveryFraction.formatted(.percent.precision(.fractionLength(0))))
                }
                Section("Placed resources") {
                    let report = run.generationDiagnostics
                    LabeledRow(icon: "drop.fill", label: "Raw Essence eligible / attempted / placed",
                               value: "\(report.rawEssenceEligibleTiles) / \(report.rawEssencePlacementAttempts) / \(report.rawEssenceDropsPlaced)")
                    LabeledRow(icon: "drop", label: "Raw Essence obtainable",
                               value: "\(report.rawEssenceObtainable)")
                    if nodes.isEmpty { Text("None") }
                    ForEach(nodes.keys.sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { id in
                        LabeledRow(icon: ContentCatalog.shared.resource(id)?.icon ?? "cube",
                                   label: ContentCatalog.shared.resource(id)?.name ?? id.rawValue,
                                   value: "\(nodes[id] ?? 0)")
                    }
                }
                Section("Traveller placement") {
                    let report = run.generationDiagnostics
                    LabeledRow(icon: "person.3", label: "Candidates / matches / eligible / placed",
                               value: "\(report.travellerCandidates.count) / \(report.travellerSignatureMatches.count) / \(report.travellerEligibleMatches.count) / \(report.travellersPlaced.count)")
                    let arrival = report.travellerArrival
                    if let selected = arrival.selectedTraveller {
                        LabeledRow(icon: "person.crop.circle.badge.questionmark",
                                   label: "Selected / band / order",
                                   value: "\(selected.rawValue) / \(arrival.storyArrivalBand.map(String.init) ?? "—") / \(arrival.authoredOrder.map(String.init) ?? "—")")
                        LabeledRow(icon: "text.book.closed", label: "Clues / causal known / causal all / accidental",
                                   value: "\(arrival.recoveredLocationClues) / \(arrival.causallyAuthoredKnownConditions) / \(arrival.causallyAuthoredConditions) / \(arrival.accidentalSatisfiedConditions)")
                        LabeledRow(icon: "dice", label: "Evidence / prior misses / chance / roll",
                                   value: "\(arrival.evidenceScore.formatted(.number.precision(.fractionLength(2)))) / \(arrival.priorNearMisses) / \(arrival.arrivalChance.formatted(.percent.precision(.fractionLength(1)))) / \(arrival.arrivalRoll?.formatted(.number.precision(.fractionLength(4))) ?? "—")")
                    }
                    LabeledRow(icon: "checkmark.seal", label: "Arrival outcome",
                               value: arrival.outcome.rawValue)
                    if report.travellersPlaced.isEmpty { Text("No travellers placed") }
                    ForEach(report.travellersPlaced, id: \.self) { id in
                        Text(ContentCatalog.shared.traveller(id)?.name ?? id.rawValue)
                    }
                }
                if let preview = run.activeEncounter?.scalingPreview {
                    Section("Encounter scaling") {
                        LabeledRow(icon: "number", label: "Scaling rules",
                                   value: preview.scalingRulesVersion ?? "historical-upper-median")
                        if let ledger = preview.partyPowerLedger {
                            LabeledRow(icon: "person.3", label: "Anchor / party power",
                                       value: "L\(ledger.anchorLevel) · \(ledger.uncappedBudget.formatted(.number.precision(.fractionLength(3)))) → \(ledger.cappedBudget.formatted(.number.precision(.fractionLength(3))))")
                            ForEach(Array(ledger.contributions.enumerated()), id: \.offset) { _, entry in
                                LabeledRow(icon: entry.identity == "binder" ? "person.fill" : "person",
                                           label: entry.identity,
                                           value: "L\(entry.level) · ratio \(entry.rawLevelRatio.formatted(.number.precision(.fractionLength(3)))) · +\(entry.contribution.formatted(.number.precision(.fractionLength(3))))")
                            }
                        } else {
                            LabeledRow(icon: "person.3", label: "Historical party levels / upper median",
                                       value: "\(preview.partyLevels.map(String.init).joined(separator: ", ")) / \(preview.upperMedian)")
                        }
                        LabeledRow(icon: "pawprint", label: "Visible foe IDs",
                                   value: preview.foeIDs.map { String($0.rawValue) }.joined(separator: ", "))
                        LabeledRow(icon: "circle.grid.cross", label: "Grouping radius / reasons",
                                   value: "\(preview.groupingRadius) · " + preview.inclusionReasons.keys.sorted().compactMap { foeID in
                                       preview.inclusionReasons[foeID].map { reason in "\(foeID): \(reason)" }
                                   }.joined(separator: "; "))
                        if let excluded = preview.exclusionReasons, !excluded.isEmpty {
                            LabeledRow(icon: "nosign", label: "Excluded map foes",
                                       value: excluded.keys.sorted().compactMap { foeID in
                                           excluded[foeID].map { "\(foeID): \($0)" }
                                       }.joined(separator: "; "))
                        }
                        LabeledRow(icon: "chart.bar", label: "Stability / greed level-equivalents",
                                   value: "\(preview.stabilityLevelContribution.formatted(.number.precision(.fractionLength(2)))) / \(preview.greedLevelContribution.formatted(.number.precision(.fractionLength(2))))")
                        if preview.scalingRulesVersion == EncounterScalingRules.additivePartyPowerRulesVersion {
                            LabeledRow(icon: "scalemass", label: "Real foes / shortfall",
                                       value: "\(preview.realFoeCount ?? preview.visibleFoeCount) / \((preview.shortfall ?? 0).formatted(.number.precision(.fractionLength(3))))")
                            LabeledRow(icon: "arrow.turn.down.right", label: "Pressure slots / HP fraction",
                                       value: "\(preview.wholePressureSlots ?? 0) / \((preview.totalHPAdditionFraction ?? 0).formatted(.percent.precision(.fractionLength(1))))")
                            let allocations = preview.hpAllocationByFoeID ?? [:]
                            LabeledRow(icon: "heart", label: "HP allocation",
                                       value: allocations.isEmpty ? "none" : allocations.keys.sorted().map {
                                           "\($0): +\(allocations[$0, default: 0])"
                                       }.joined(separator: "; "))
                            let slots = run.activeEncounter?.turnSlots.compactMap { slot -> String? in
                                switch slot.kind {
                                case .ordinaryPressureFollowUp(let ordinal):
                                    return "\(slot.actor): lighter \(ordinal) @ \(slot.strengthMultiplier.formatted(.percent))"
                                case .apexFollowUp(let ordinal):
                                    return "\(slot.actor): apex \(ordinal) @ \(slot.strengthMultiplier.formatted(.percent))"
                                case .primary: return nil
                                }
                            } ?? []
                            LabeledRow(icon: "list.number", label: "Saved follow-up slots",
                                       value: slots.isEmpty ? "none" : slots.joined(separator: "; "))
                        } else {
                            LabeledRow(icon: "scalemass", label: "Historical budget / visible / adjustment",
                                       value: "\(preview.ordinaryBudget.formatted(.number.precision(.fractionLength(2)))) / \(preview.visibleFoeCount) / +\(preview.totalOrdinaryLevelAdjustment)")
                            LabeledRow(icon: "dice", label: "Historical remainder roll / step",
                                       value: "\(preview.remainderRoll) / +\(preview.remainderUpgrade)")
                        }
                        LabeledRow(icon: "crown", label: "Apex floor · HP · offence · actions",
                                   value: "L\(preview.apexLevelFloor) · \(preview.apexHPMultiplier.formatted(.number.precision(.fractionLength(2))))× · \(preview.apexOffenceMultiplier.formatted(.number.precision(.fractionLength(2))))× · \(preview.apexActionSlots)")
                        ForEach(preview.finalFoes, id: \.id) { foe in
                            LabeledRow(icon: foe.isApex ? "crown.fill" : "pawprint.fill",
                                       label: "Foe \(foe.id.rawValue) final",
                                       value: "L\(foe.level) · HP \(foe.maxHP) · ATK \(foe.attack) · ARM \(foe.armour)")
                        }
                        Text("Projected opening damage and neutral rounds-to-defeat: pending simulation model.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                Section("Test Setup") {
                    let report = run.generationDiagnostics
                    LabeledRow(icon: "wrench.and.screwdriver", label: "Opening envelope requested",
                               value: report.openingEnvelopeRequested.displayName)
                    LabeledRow(icon: "arrow.triangle.swap", label: "Opening envelope result",
                               value: report.openingEnvelopeRequested == .natural ? "natural — no change"
                                   : report.openingEnvelopeApplied
                                       ? "applied · \(report.openingEnemiesRelocated) relocated"
                                       : "ignored — not a fresh first expedition")
                }
                Section("Tuning snapshot") {
                    Text(tuningSnapshot)
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                }
            }
            .navigationTitle("World diagnostics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
        }
    }

    private var tuningSnapshot: String {
        let t = run.tuning
        return "rawProfile=\(t.rawEssenceProfile.rawValue) rawFrequency=\(t.rawEssenceFrequencyMultiplier) rawYield=\(t.rawEssenceYieldMultiplier) nodeDensity=\(t.resourceNodeDensityMultiplier) creatureDensity=\(t.creatureDensityMultiplier) diaryShare=\(t.diaryWritingShare) secondWriting=\(t.additionalPageChance) patience=\(t.diaryPatienceWorlds) travellerWindow=\(t.blindDiscoveryWindow) travellerClueWeight=\(t.travellerClueEvidenceWeight) travellerAuthoredWeight=\(t.travellerAuthoredEvidenceWeight) travellerArrivalFloor=\(t.travellerArrivalChanceFloor) travellerNearMissIncrement=\(t.travellerArrivalNearMissIncrement) stabilityDuration=\(t.stabilityDurationMultiplier) collapseRecovery=\(t.collapseRecoveryFraction) apex=\(t.apexChanceMultiplier) encounterScaling=\(t.encounterScalingProfile.rawValue) vision=\(t.baseVisionRadius) slowExtra=\(t.slowGroundExtraTurns) activeFlora=\(t.activeFloraFrequencyMultiplier) floraSeverity=\(t.floraHazardSeverityMultiplier) opening=\(t.openingEncounterEnvelope.rawValue)"
    }
}
#endif

private struct PartyHealthStrip: View {
    let run: WorldRun
    let state: GameState

    var body: some View {
        HStack(spacing: 14) {
            health("You", icon: "person.fill", current: run.binderHP,
                   maximum: CombatRules.health(of: .binder, in: run).max)
            ForEach(state.base.activeParty, id: \.self) { index in
                let member = state.base.roster[index]
                health(member.name, icon: member.icon,
                       current: CombatRules.health(of: .companion(index), in: run).current,
                       maximum: CombatRules.health(of: .companion(index), in: run).max)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .background(.bar)
    }

    private func health(_ name: String, icon: String, current: Int, maximum: Int) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(name).lineLimit(1)
                    Spacer(minLength: 4)
                    Text("\(current)/\(maximum)").monospacedDigit()
                }
                .font(.caption2)
                GeometryReader { proxy in
                    Capsule()
                        .fill(Color(.tertiarySystemFill))
                        .overlay(alignment: .leading) {
                            Capsule()
                                .fill(current <= maximum / 3 ? Color.red : Color.green)
                                .frame(width: proxy.size.width * min(1, max(0, Double(current) / Double(maximum))))
                        }
                }
                .frame(height: 5)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(name) health \(current) of \(maximum)")
    }
}

// MARK: - Header

private struct StabilityHeader: View {
    let run: WorldRun

    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(Int(run.stability.rounded()))")
                    .font(.title2.weight(.bold).monospacedDigit())
                    .foregroundStyle(colour)
                Text(bandText)
                    .font(.footnote)
                    .foregroundStyle(colour)
                Spacer()
                Text(turnsLeftText)
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.tertiarySystemFill))
                    Capsule().fill(colour)
                        .frame(width: proxy.size.width * (run.stability / Tuning.World.startingStability))
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private var turnsLeft: Int {
        guard run.decayPerTurn > 0 else { return Tuning.World.indefiniteTurns }
        return Int((run.stability / run.decayPerTurn).rounded(.down))
    }

    /// A world that isn't decaying has no countdown — saying so beats printing the sentinel.
    ///
    /// Measured against a *practical* ceiling rather than the sentinel itself: a world decaying by
    /// a hundredth of a point a turn lasts ten thousand turns, which is not a countdown, and thirty
    /// turns in it prints "~9969 turns left" and reads as a bug. The preview already says "holds
    /// indefinitely" about the same world; these two must agree.
    private var turnsLeftText: String {
        turnsLeft >= Tuning.World.countdownCeiling ? "steady" : "~\(turnsLeft) turns left"
    }

    private var bandText: String {
        switch run.stabilityBand {
        case .stable: "holding"
        case .hazardous: "hazards at the edges"
        case .crumbling: "crumbling inward"
        case .collapsed: "collapsing"
        }
    }

    private var colour: Color {
        switch run.stabilityBand {
        case .stable: .green
        case .hazardous: .yellow
        case .crumbling: .orange
        case .collapsed: .red
        }
    }
}

// MARK: - Grid

enum WorldMapLayout {
    /// Transparent pixels in a lifted 16×19 sprite reveal this game-owned field, never the
    /// system/card background. It is the same non-informative dark used by accepted fog art.
    static let backdropRGB: [UInt8] = [23, 23, 26]

    /// Fits a complete square inside the region left by the fixed controls, then aligns every cell
    /// to whole device pixels. A scroll viewport may contain narration below the map, but it never
    /// acts as a crop window through a fractional final row.
    static func maximumSide(containerWidth: CGFloat, viewportHeight: CGFloat,
                            viewportTiles: Int, displayScale: CGFloat) -> CGFloat {
        let widthBound = max(0, containerWidth - 24)
        let heightBound = max(0, viewportHeight - 16)
        let tiles = CGFloat(max(1, viewportTiles))
        let scale = max(1, displayScale)
        let cellPixels = floor(min(widthBound, heightBound) * scale / tiles)
        return max(tiles, cellPixels) * tiles / scale
    }
}

/// The map, seen through a window that follows you.
///
/// **The map no longer has to fit one screen** (decisions-session-13 §3) — only the page does, since
/// you compose on a page and walk through a world. The camera is **clamped follow**: centred on you
/// until you reach an edge, where it stops rather than showing empty space past the border.
private struct MapGrid: View {
    let run: WorldRun
    let maximumSide: CGFloat
    let onTap: (GridPoint) -> Void
#if DEBUG
    @AppStorage("debug.simpleMapRenderer") private var useSimpleRenderer = false
#endif

    /// How many tiles across the window is. Small maps show whole; big ones scroll under you.
    private var viewport: Int { min(Tuning.World.viewportTiles, min(run.map.width, run.map.height)) }

    /// Top-left of the window: centred on the player, then clamped to the map.
    private var origin: GridPoint {
        GridPoint(x: clamp(run.playerPosition.x - viewport / 2, run.map.width),
                  y: clamp(run.playerPosition.y - viewport / 2, run.map.height))
    }

    private func clamp(_ value: Int, _ extent: Int) -> Int {
        max(0, min(value, extent - viewport))
    }

    var body: some View {
        GeometryReader { proxy in
            let side = proxy.size.width / CGFloat(viewport)
            let grade = WorldGrade.from(BookRules.readings(for: run.book, seed: run.mapSeed))
            VStack(spacing: 0) {
                ForEach(origin.y..<(origin.y + viewport), id: \.self) { y in
                    HStack(spacing: 0) {
                        ForEach(origin.x..<(origin.x + viewport), id: \.self) { x in
                            let point = GridPoint(x: x, y: y)
                            TileView(tile: run.map[point],
                                     artRequest: artRequest(at: point, grade: grade),
                                     enemy: enemy(at: point),
                                     site: site(at: point),
                                     isPlayer: point == run.playerPosition,
                                     side: side,
                                     useSimpleRenderer: simpleRenderer)
                                .onTapGesture { onTap(point) }
                        }
                    }
                    .zIndex(Double(y))
                }
            }
        }
        .frame(width: maximumSide, height: maximumSide)
        .frame(maxWidth: .infinity)
        .background(
            Color(red: Double(WorldMapLayout.backdropRGB[0]) / 255,
                  green: Double(WorldMapLayout.backdropRGB[1]) / 255,
                  blue: Double(WorldMapLayout.backdropRGB[2]) / 255),
            in: RoundedRectangle(cornerRadius: 10)
        )
    }

    private var simpleRenderer: Bool {
#if DEBUG
        useSimpleRenderer
#else
        false
#endif
    }

    private func artRequest(at point: GridPoint, grade: WorldGrade) -> MapTileArtRequest {
        let tile = run.map[point]
        var adjacency = 0
        for (bit, neighbour) in [(1, GridPoint(x: point.x, y: point.y-1)),
                                 (2, GridPoint(x: point.x+1, y: point.y)),
                                 (4, GridPoint(x: point.x, y: point.y+1)),
                                 (8, GridPoint(x: point.x-1, y: point.y))] {
            if run.map.contains(neighbour), run.map[neighbour].ground == tile.ground { adjacency |= bit }
        }
        let flora = tile.flora.flatMap { id in run.flora.first { $0.id == id } }
        let south = GridPoint(x: point.x, y: point.y + 1)
        // Concealed neighbours and the map boundary never fabricate a visible side wall.
        let southExposure = MapAssetContract.southExposure(
            center: tile, south: run.map.contains(south) ? run.map[south] : nil)
        return MapTileArtRequest(tile: tile, point: point, mapSeed: run.mapSeed, runIndex: run.runIndex,
                                 adjacency: adjacency,
                                 southExposureLevels: southExposure,
                                 grade: grade,
                                 flora: flora,
                                 worldGrade2Descriptor: run.worldVisualReceipt?.descriptor)
    }


    /// Cryptic creatures don't show until they're on you — see `WorldRules.isVisible`.
    private func enemy(at point: GridPoint) -> WorldEnemy? {
        run.enemies.first { $0.position == point && WorldRules.isVisible($0, in: run) }
    }

    private func site(at point: GridPoint) -> SiteDef? {
        run.sites.first { $0.position == point }?.definition
    }
}

private struct TileView: View {
    let tile: Tile
    let artRequest: MapTileArtRequest
    let enemy: WorldEnemy?
    /// Resolved by the caller: the tile only stores an instance id, and the grid is the one place
    /// that has the run to look it up in.
    let site: SiteDef?
    let isPlayer: Bool
    let side: CGFloat
    let useSimpleRenderer: Bool

    var body: some View {
        ZStack(alignment: .top) {
            if useSimpleRenderer {
                Rectangle().fill(background)
                if tile.isRevealed && tile.isCracking && !tile.isCrumbled {
                    SimpleCrackShape()
                        .stroke(Color.orange.opacity(0.95),
                                style: StrokeStyle(lineWidth: max(1, side * 0.07),
                                                   lineCap: .round, lineJoin: .round))
                        .padding(side * 0.12)
                }
            } else {
                MapTileArt(request: artRequest)
                    .frame(width: side,
                           height: side * CGFloat(MapAssetContract.spriteHeight)
                               / CGFloat(MapAssetContract.logicalSide))
                    .offset(y: -side * CGFloat(MapAssetContract.maximumElevation)
                            / CGFloat(MapAssetContract.logicalSide))
            }
            ZStack {
                // The player gets a filled disc behind them: at 27pt a bare glyph disappears into
                // the grid, and "where am I" has to be answerable at a glance.
                if isPlayer {
                    Circle()
                        .fill(Color.accentColor)
                        .padding(side * 0.14)
                }
                if let enemy, case .alert = enemy.awareness {
                    Circle()
                        .stroke(Color.orange, style: StrokeStyle(lineWidth: max(2, side * 0.08), dash: [3, 2]))
                        .padding(side * 0.08)
                }
                if let symbol {
                    Image(systemName: symbol)
                        .font(.system(size: side * (isPlayer ? 0.46 : 0.54), weight: isPlayer ? .bold : .regular))
                        .foregroundStyle(tint)
                }
            }
            .frame(width: side, height: side)
            .offset(y: surfaceLift)

            // Alert punctuation is a floating UI badge, not something painted on the ground.
            if let enemy, case .alert = enemy.awareness {
                Image(systemName: "exclamationmark")
                    .font(.system(size: side * 0.28, weight: .black))
                    .foregroundStyle(.orange)
                    .offset(x: side * 0.30, y: -side * 0.30)
            }
        }
        .frame(width: side, height: side)
        .contentShape(Rectangle())
    }

    private var surfaceLift: CGFloat {
        guard !useSimpleRenderer else { return 0 }
        return -side * CGFloat(artRequest.resolvedElevation) / CGFloat(MapAssetContract.logicalSide)
    }

    private var symbol: String? {
        if isPlayer { return "figure.stand" }
        guard tile.isRevealed, !tile.isCrumbled else { return nil }
        if let enemy { return enemy.icon }
        switch tile.content {
        case .empty: return nil
        case .node(let node): return useSimpleRenderer ? (ContentCatalog.shared.resource(node.resource)?.icon ?? "cube") : nil
        case .wildDrop: return useSimpleRenderer ? "sparkle" : nil
        case .hazard: return "exclamationmark.triangle.fill"
        case .portal(let isEntry): return isEntry ? "arrow.down.left.circle" : "circle.circle"
        case .lockedCache: return "lock.fill"
        case .diaryPage: return "doc.text"
        case .foundWriting: return "note.text"
        case .site: return site?.icon ?? "building.columns"
        // A person reads as a person, in their own colour — see `tint`.
        case .traveller(let id): return ContentCatalog.shared.traveller(id)?.icon ?? "figure.wave"
        }
    }

    private var tint: Color {
        if isPlayer { return Palette.mapFloor }
        if enemy != nil { return .red }
        switch tile.content {
        case .hazard: return .orange
        case .portal: return .blue
        case .lockedCache: return .purple
        case .wildDrop: return .teal
        case .diaryPage: return .indigo
        case .foundWriting: return .cyan
        case .site: return site?.category == .hazard ? .orange : .brown
        // Green, and nothing else on the map is green. A person standing in a world you wrote is
        // the single most interesting thing on the grid and has to look like it.
        case .traveller: return .green
        default: return .primary.opacity(0.7)
        }
    }

    /// The ground under everything. Elevation darkens it, so high country reads as high country.
    private var groundColour: Color {
        let base: Color = switch tile.ground {
        case .stone: Color(red: 0.55, green: 0.55, blue: 0.58)
        case .soil: Color(red: 0.45, green: 0.38, blue: 0.28)
        case .sand: Color(red: 0.80, green: 0.72, blue: 0.52)
        case .ice: Color(red: 0.78, green: 0.87, blue: 0.92)
        case .ash: Color(red: 0.38, green: 0.36, blue: 0.36)
        case .water: Color(red: 0.30, green: 0.52, blue: 0.72)
        case .deepWater: Color(red: 0.16, green: 0.30, blue: 0.52)
        case .rubble: Color(red: 0.50, green: 0.46, blue: 0.42)
        case .mud: Color(red: 0.31, green: 0.25, blue: 0.18)
        case .growth: Color(red: 0.30, green: 0.48, blue: 0.28)
        // Lighter and yellower than a thicket — you can see over it, and it should look like you
        // can. The difference has to be legible at a glance or the sightline rule is a surprise.
        case .groundcover: Color(red: 0.47, green: 0.58, blue: 0.34)
        case .chasm: Color(red: 0.06, green: 0.06, blue: 0.09)
        }
        return base.opacity(1 - Double(tile.elevation) * 0.13)
    }

    /// Three clearly distinct states in both schemes — see `Palette` for why these can't be
    /// opacities over `.primary`: the meaning inverts in dark mode.
    private var background: Color {
        if tile.isCrumbled { return Palette.mapVoid }
        // Unseen ground stays fog; seen ground shows what it's made of.
        return tile.isRevealed ? groundColour : Palette.mapFog
    }
}

/// DEBUG fallback only. The native renderer uses the frozen 16px crack command grammar.
private struct SimpleCrackShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX * 0.9, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX * 1.12, y: rect.height * 0.32))
        path.addLine(to: CGPoint(x: rect.midX * 0.78, y: rect.height * 0.56))
        path.addLine(to: CGPoint(x: rect.midX * 1.05, y: rect.maxY))
        path.move(to: CGPoint(x: rect.midX * 0.78, y: rect.height * 0.56))
        path.addLine(to: CGPoint(x: rect.width * 0.18, y: rect.height * 0.72))
        path.move(to: CGPoint(x: rect.midX * 1.12, y: rect.height * 0.32))
        path.addLine(to: CGPoint(x: rect.width * 0.82, y: rect.height * 0.18))
        return path
    }
}

// MARK: - Controls

private enum Direction: CaseIterable {
    case up, right, down, left

    var dx: Int { switch self { case .left: -1; case .right: 1; default: 0 } }
    var dy: Int { switch self { case .up: -1; case .down: 1; default: 0 } }
    var icon: String {
        switch self {
        case .up: "chevron.up"
        case .right: "chevron.right"
        case .down: "chevron.down"
        case .left: "chevron.left"
        }
    }
}

/// The one-handed movement control. Optional in the brief; here it's the primary one, because a
/// 14×14 grid of 27pt tiles can't be.
private struct DirectionPad: View {
    var isLooking = false
    let onStep: (Direction) -> Void

    var body: some View {
        VStack(spacing: 4) {
            padButton(.up)
            HStack(spacing: 4) {
                padButton(.left)
                Color.clear.frame(width: 46, height: 46)
                padButton(.right)
            }
            padButton(.down)
        }
    }

    private func padButton(_ direction: Direction) -> some View {
        Button { onStep(direction) } label: {
            Image(systemName: direction.icon)
                .font(.headline)
                .frame(width: 46, height: 46) // ≥44pt
        }
        .buttonStyle(.bordered)
        .accessibilityLabel("\(isLooking ? "Look" : "Move") \(direction.accessibilityName)")
    }
}

private extension Direction {
    var accessibilityName: String {
        switch self { case .up: "north"; case .right: "east"; case .down: "south"; case .left: "west" }
    }
}

private struct InspectionPresentation: Identifiable {
    let id = UUID()
    let value: WorldRules.TileInspection
}

private struct ActionButton: View {
    let title: String
    let icon: String
    var detail: String?
    var isProminent: Bool = false
    var isEnabled: Bool = true
    let action: () -> Void

    init(_ title: String, icon: String, detail: String? = nil,
         isProminent: Bool = false, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.detail = detail
        self.isProminent = isProminent
        self.isEnabled = isEnabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).font(.callout.weight(.medium)).lineLimit(1).minimumScaleFactor(0.75)
                    if let detail {
                        Text(detail).font(.caption2).foregroundStyle(.secondary)
                            .lineLimit(1).minimumScaleFactor(0.75)
                    }
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 48)
            .padding(.horizontal, 10)
        }
        .buttonStyle(.bordered)
        .tint(isProminent ? .accentColor : .secondary)
        .disabled(!isEnabled)
    }
}

#Preview {
    WorldView().environmentObject(GameStore(io: .temporary(name: "preview-world")))
}


/// A truthful inventory of what crossed the threshold. Instruments are fixed for the trip;
/// consumables can be used here, outside combat, for one world turn.
private struct FieldKitSheet: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    let instruments = ContentCatalog.shared.pressureTargetsInOrder.filter {
                        store.activeRun?.carriedInstruments.contains($0.id) == true
                    }
                    if instruments.isEmpty {
                        Text("No instruments packed for this trip.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(instruments) { target in
                            LabeledRow(icon: target.icon, label: target.name, value: "carried")
                        }
                    }
                } header: {
                    Text("Instruments")
                } footer: {
                    Text("Choose next trip's instruments at Mara's Survey Post.")
                }

                if store.carriedConsumables.isEmpty {
                    Section("Consumables") {
                        Text("No usable items carried.").foregroundStyle(.secondary)
                    }
                }
                ForEach(store.carriedConsumables) { stack in
                    Section {
                        if ContentCatalog.shared.item(stack.catalogID)?.consumable?.effect == .heal {
                            ForEach(store.partyMembers) { member in
                                Button {
                                    store.useItemInWorld(stack, on: member)
                                    dismiss()
                                } label: {
                                    LabeledRow(icon: "heart.fill",
                                               label: store.name(of: member),
                                               value: health(of: member))
                                    .frame(minHeight: 44)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        } else if ContentCatalog.shared.item(stack.catalogID)?.consumable?.effect == .identifyCurio {
                            if store.carriedUnidentifiedCurios.isEmpty {
                                Text("No unidentified curios carried.")
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(store.carriedUnidentifiedCurios) { curio in
                                    Button {
                                        store.useSolventInWorld(stack, on: curio)
                                        dismiss()
                                    } label: {
                                        LabeledRow(icon: curio.icon, label: curio.displayName,
                                                   value: "identify")
                                            .frame(minHeight: 44)
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        } else {
                            Button {
                                store.useItemInWorld(stack, on: .binder)
                                dismiss()
                            } label: {
                                HStack(spacing: 10) {
                                    CatalogueItemPixelIdentity(
                                        itemID: stack.catalogID,
                                        identified: stack.identified,
                                        fallbackSystemIcon: ContentCatalog.shared.item(stack.catalogID)?.icon ?? "sparkles",
                                        fallbackColor: ContentCatalog.shared.item(stack.catalogID)?.rarity.tint ?? .secondary
                                    )
                                    .frame(width: 32, height: 32)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Use now")
                                        Text(fieldEffectDetail(stack.catalogID))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                }
                                .frame(minHeight: 44)
                                .contentShape(Rectangle())
                                .accessibilityElement(children: .combine)
                            }
                            .buttonStyle(.plain)
                        }
                    } header: {
                        HStack(spacing: 8) {
                            CatalogueItemPixelIdentity(
                                itemID: stack.catalogID,
                                identified: stack.identified,
                                fallbackSystemIcon: ContentCatalog.shared.item(stack.catalogID)?.icon ?? "sparkles",
                                fallbackColor: ContentCatalog.shared.item(stack.catalogID)?.rarity.tint ?? .secondary
                            )
                            .frame(width: 28, height: 28)
                            Text("\(stack.displayName)\(stack.count > 1 ? " ×\(stack.count)" : "")")
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
            .navigationTitle("Field Kit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Back") { dismiss() } }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func health(of member: PartyMember) -> String {
        guard let run = store.state.worlds.activeRun else { return "" }
        let hp = CombatRules.health(of: member.combatant, in: run)
        return "\(hp.current) / \(hp.max)"
    }

    private func fieldEffectDetail(_ id: ItemID) -> String {
        switch ContentCatalog.shared.item(id)?.consumable?.effect {
        case .restoreStability: "restore stability"
        case .returnHome: "return with full haul"
        case .lightWorld: "raise vision"
        case .farsight: "reveal nearest site"
        case .lureCreature: "draw nearest creature"
        case .identifyCurio: "identify one curio"
        default: ""
        }
    }
}
