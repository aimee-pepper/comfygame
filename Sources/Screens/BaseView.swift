import SwiftUI

enum BaseBoardRules {
    static func destinations(from stations: [StationDef]) -> [StationDef] {
        stations.filter { $0.route != AppRoute.party.rawValue }
    }

    static func knownStations(_ stations: [StationDef], unlocked: Set<StationID>,
                              foundations: Set<StationID>) -> [StationDef] {
        stations.filter { unlocked.contains($0.id) || foundations.contains($0.id) }
    }

    static func availableSections(for stations: [StationDef]) -> [StationHomeSection] {
        StationHomeSection.allCases.filter { section in
            section == .home || stations.contains { $0.resolvedBoardPlacement.section == section }
        }
    }

    static func stations(in section: StationHomeSection, from stations: [StationDef]) -> [StationDef] {
        stations.filter { $0.resolvedBoardPlacement.section == section }
    }

    static func columnCount(isAccessibilitySize: Bool) -> Int { isAccessibilitySize ? 2 : 3 }
}

/// The hub. Routes to station subscreens and out into a world.
///
/// The station list is **rendered from `ContentCatalog.stations`**, not hardcoded — v1+ adds a
/// blacksmith, a tavern, a distillery, and each of those should be a JSON entry plus a screen,
/// never a new button welded into this file.
struct BaseView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var routeCardHidden = false
    @State private var selectedSection: StationHomeSection = .home
    @State private var foundationStation: StationDef?

    private var state: GameState { store.state }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 12) {
                    contextRow
                    firstReturnRouteCard
                    sectionPicker
                    stationBoard(containerSize: geometry.size)
                }
                .padding(12)
                .padding(.bottom, 12)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Base")
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            departure
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.bar)
        }
        .onAppear { routeCardHidden = false }
        .onChange(of: availableSections) { _, sections in
            if !sections.contains(selectedSection) { selectedSection = .home }
        }
        .sheet(item: $foundationStation) { station in
            StationFoundationSheet(station: station)
                .environmentObject(store)
        }
    }

    // MARK: Purse

    private var contextRow: some View {
        HStack(spacing: 12) {
            Text("Base")
                .font(.title2.weight(.bold))
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 4)
            CompactCurrency(icon: "drop.fill", label: "Essence",
                            value: state.base.essence, tint: .teal)
            CompactCurrency(icon: "star.fill", label: "Motes",
                            value: state.reality.motes, tint: .purple)
            NavigationLink(value: AppRoute.settings) {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            .accessibilityLabel("Settings and save games")
        }
        .frame(minHeight: 44)
    }

    @ViewBuilder private var firstReturnRouteCard: some View {
        if !routeCardHidden,
           let context = state.tutorial.firstReturnContext,
           state.tutorial[.returnPersistenceBoundary].status == .completed,
           state.tutorial[.baseFirstResultRoute].status != .completed {
            let route = TutorialRules.destination(for: context.route)
            VStack(alignment: .leading, spacing: 10) {
                Text("Follow what returned").font(.headline)
                Text(TutorialRules.routeCopy(context, in: state)).font(.subheadline)
                HStack {
                    Button("Not now") {
                        store.deferTutorial(.baseFirstResultRoute)
                        routeCardHidden = true
                    }
                    Spacer()
                    NavigationLink(value: route) {
                        Text("Open \(destinationName(context.route))")
                    }
                    .buttonStyle(.borderedProminent)
                    .simultaneousGesture(TapGesture().onEnded {
                        if let station = ContentCatalog.shared.stations.first(where: { $0.route == route.rawValue }) {
                            selectedSection = station.resolvedBoardPlacement.section
                        }
                        store.openedFirstReturnDestination(route)
                    })
                }
            }
            .padding(14)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(.tint.opacity(0.35)))
        }
    }

    private func destinationName(_ route: FirstReturnTutorialContext.Route) -> String {
        switch route {
        case .library: "Library"
        case .storehouse: "Storehouse"
        case .workshop: "Workshop"
        case .essenceSpring: "Essence Spring"
        case .firepit: "Firepit"
        case .writingDesk: "Writing Desk"
        }
    }

    // MARK: Stations

    private var sectionPicker: some View {
        Picker("Base district", selection: $selectedSection) {
            ForEach(availableSections, id: \.self) { section in
                Text(section.title).tag(section)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityIdentifier("base-section-picker")
    }

    private func stationBoard(containerSize: CGSize) -> some View {
        Group {
            if selectedSection == .home,
               let scene = StartingTownHomeResource.scene(),
               let sceneHeight = StartingTownHomeRules.sceneHeight(containerSize: containerSize) {
                StartingTownHomeScene(scene: scene,
                                      openedRoute: { store.openedFirstReturnDestination($0) })
                    .frame(height: sceneHeight)
            } else {
                legacyStationGrid
            }
        }
        .accessibilityIdentifier("base-station-board-\(selectedSection.rawValue)")
    }

    private var legacyStationGrid: some View {
        LazyVGrid(columns: stationColumns, spacing: 12) {
            ForEach(stations(in: selectedSection)) { station in stationDestination(station) }
        }
    }

    @ViewBuilder private func stationDestination(_ station: StationDef) -> some View {
        if state.base.station(station.id).isUnlocked {
            let route = AppRoute(rawValue: station.route) ?? .base
            NavigationLink(value: route) {
                StationTile(station: station, tier: state.base.station(station.id).tier,
                            isFoundation: false)
            }
            .buttonStyle(.plain)
            .simultaneousGesture(TapGesture().onEnded { store.openedFirstReturnDestination(route) })
        } else {
            Button { foundationStation = station } label: {
                StationTile(station: station, tier: 0, isFoundation: true)
            }
            .buttonStyle(.plain)
        }
    }

    private var stationColumns: [GridItem] {
        let count = BaseBoardRules.columnCount(isAccessibilitySize: dynamicTypeSize.isAccessibilitySize)
        return Array(repeating: GridItem(.flexible(), spacing: 10), count: count)
    }

    private var knownStations: [StationDef] {
        let foundations = Set(store.buildableStations.map(\.id))
        let unlocked = Set(ContentCatalog.shared.stationsInOrder.compactMap {
            state.base.station($0.id).isUnlocked ? $0.id : nil
        })
        let known = BaseBoardRules.knownStations(ContentCatalog.shared.stationsInOrder,
                                                 unlocked: unlocked, foundations: foundations)
        return BaseBoardRules.destinations(from: known)
    }

    private var availableSections: [StationHomeSection] {
        BaseBoardRules.availableSections(for: knownStations)
    }

    private func stations(in section: StationHomeSection) -> [StationDef] {
        BaseBoardRules.stations(in: section, from: knownStations)
    }

    // MARK: Departure

    private var departure: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: 8) { baseActionButtons }
            } else {
                HStack(spacing: 10) { baseActionButtons }
            }
        }
        .padding(.top, 2)
    }

    @ViewBuilder private var baseActionButtons: some View {
        NavigationLink(value: AppRoute.party) {
            Label("Party", systemImage: "person.2.fill")
                .font(.subheadline.weight(.semibold))
                .frame(minWidth: dynamicTypeSize.isAccessibilitySize ? 0 : 96,
                       maxWidth: dynamicTypeSize.isAccessibilitySize ? .infinity : nil)
                .frame(minHeight: 48)
        }
        .buttonStyle(.bordered)
        .accessibilityHint("Manage party members, gear and gambits")

        NavigationLink(value: AppRoute.writingDesk) {
            Label("Bind & Depart", systemImage: "arrow.up.forward.circle.fill")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .frame(minHeight: 48)
        }
        .buttonStyle(.borderedProminent)
        .accessibilityHint(departureHint)
        .simultaneousGesture(TapGesture().onEnded {
            store.openedFirstReturnDestination(.writingDesk)
        })
    }

    /// **Counted in marks and subjects**, because that is what a page is made of.
    ///
    /// It used to count slots — filled against total — and the page grid replaced slots two systems
    /// ago. On a page every "slot" carried a mark, so this always said *"N of N chosen"* however
    /// much of the world you had actually written about.
    private var departureHint: String {
        let projection = store.bookProjection
        let marks = projection.marksSpeaking
        let rolled = projection.unwrittenSubjects.count
        if marks == 0 {
            return "Nothing written — the world will be entirely what it decides."
        }
        let written = marks == 1 ? "One mark speaking" : "\(marks) marks speaking"
        if rolled == 0 {
            return "\(written), and nothing left to chance. Waiting at the desk."
        }
        return "\(written); \(rolled) subject\(rolled == 1 ? "" : "s") still to roll."
    }
}

// MARK: - Pieces

private struct CompactCurrency: View {
    let icon: String
    let label: String
    let value: Int
    let tint: Color

    var body: some View {
        Label {
            Text(value, format: .number)
                .font(.subheadline.weight(.semibold).monospacedDigit())
        } icon: {
            Image(systemName: icon).foregroundStyle(tint)
        }
        .labelStyle(.titleAndIcon)
        .accessibilityLabel("\(value) \(label)")
    }
}

private struct StationTile: View {
    let station: StationDef
    let tier: Int
    let isFoundation: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Image(systemName: station.icon)
                .font(.title2)
                .frame(width: 34, height: 30)
                .foregroundStyle(isFoundation ? Color.secondary : Color.accentColor)

            Text(station.name)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)
            Spacer(minLength: 0)
            HStack {
                if isFoundation {
                    Text("Build")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color(.tertiarySystemFill), in: Capsule())
                } else if tier > 0 {
                    Text("Tier \(tier)")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.tertiarySystemFill), in: Capsule())
                }
                Spacer()
                if isFoundation {
                    Image(systemName: "hammer")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 108, maxHeight: 116, alignment: .topLeading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(isFoundation ? Color.secondary.opacity(0.55) : Color.clear,
                        style: StrokeStyle(lineWidth: 1.5, dash: isFoundation ? [5, 3] : []))
        }
        .contentShape(RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(station.resolvedBoardPlacement.section.title), \(station.name), \(isFoundation ? "foundation, Build" : (tier > 0 ? "built, Tier \(tier), Open" : "built, Open"))")
    }
}

/// A building that could exist, and doesn't yet.
///
/// The card carries the *person's* line rather than a shop blurb, because meeting them is what
/// unlocked it — "Halloway will raise a forge here, if you can find the stone and the iron for it."
private struct StationFoundationSheet: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss
    @State private var buildFailure: String?
    let station: StationDef

    var body: some View {
        NavigationStack {
            Form {
                Section {
            HStack(spacing: 12) {
                Image(systemName: station.icon)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(width: 30)
                VStack(alignment: .leading, spacing: 2) {
                    Text(station.name).font(.headline)
                    if let travellerID = station.builtBy,
                       let person = ContentCatalog.shared.traveller(travellerID) {
                        HStack(spacing: 6) {
                            NamedCharacterPixelIdentity(
                                travellerID: travellerID,
                                fallbackSystemIcon: person.icon,
                                fallbackColor: .secondary
                            )
                            .frame(width: 22, height: 22)
                            Text("\(person.name), \(person.calling)")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                Spacer(minLength: 0)
                Text("Foundation")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(Color(.tertiarySystemFill), in: Capsule())
            }

            Text(station.buildBlurb ?? station.blurb)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let cost = station.buildCost {
                LabeledContent("Build cost", value: describe(cost))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)

                let runway = StationRunwayRules.preview(for: station, in: store.state)
                VStack(alignment: .leading, spacing: 5) {
                    LabeledContent("Spendable Essence now", value: "\(runway.spendableNow)")
                    LabeledContent("After construction", value: "\(runway.spendableAfter)")
                    if runway.refinableRawEssence > 0 {
                        Text("Includes \(runway.refinableRawEssence) Essence currently refinable from Raw Essence.")
                    }
                    if let median = runway.recentMedianBindCost,
                       let remaining = runway.authoredBindsRemaining {
                        LabeledContent("Recent median authored bind", value: median.formatted(.number.precision(.fractionLength(0...1))))
                        LabeledContent("Estimated runway at that median",
                                       value: "≈ \(remaining.formatted(.number.precision(.fractionLength(1)))) binds")
                    } else {
                        Text("A runway estimate appears after an authored world has been bound and recorded.")
                    }
                    switch runway.warning {
                    case .low:
                        Label("Low writing runway", systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                    case .belowOne:
                        Label("This leaves less Essence than your recent authored bind cost.", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    case nil:
                        EmptyView()
                    }
                }
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
            }

                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) { foundationActionBar }
            .navigationTitle(station.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .alert("Station not built", isPresented: Binding(
                get: { buildFailure != nil },
                set: { if !$0 { buildFailure = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(buildFailure ?? "The station could not be built.")
            }
        }
    }

    private var foundationActionBar: some View {
        let missing = store.shortfall(for: station)
        return PersistentActionBar(
            message: missing.isEmpty
                ? "Builder, materials, Essence, and space are checked again before construction."
                : "Still need \(missing.joined(separator: ", ")).",
            messageTint: missing.isEmpty ? .secondary : .orange
        ) {
            Button {
                if store.build(station) {
                    buildFailure = nil
                    dismiss()
                } else {
                    buildFailure = "The builder, materials, Essence, or available space changed. Review the foundation requirements and try again."
                }
            } label: {
                Label("Build it", systemImage: "hammer")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!missing.isEmpty)
        }
    }

    private func describe(_ cost: UpgradeCost) -> String {
        var parts: [String] = []
        if cost.essence > 0 { parts.append("\(cost.essence) essence") }
        for (id, amount) in cost.resources.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            parts.append("\(amount) \(ContentCatalog.shared.resource(id)?.name.lowercased() ?? id.rawValue)")
        }
        return parts.isEmpty ? "free" : parts.joined(separator: " · ")
    }
}

struct CurrencyChip: View {
    let icon: String
    let label: String
    let value: String
    var tint: Color = .accentColor

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon).foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 0) {
                Text(value).font(.headline.monospacedDigit())
                Text(label).font(.caption2).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 52)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    NavigationStack {
        BaseView().environmentObject(GameStore(io: .temporary(name: "preview-base")))
    }
}
