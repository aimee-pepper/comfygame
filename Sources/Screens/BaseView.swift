import SwiftUI
import UIKit

private struct PhoneRouteActionKey: EnvironmentKey {
    static let defaultValue: @MainActor @Sendable (AppRoute) -> Void = { _ in }
}

extension EnvironmentValues {
    var phoneRouteAction: @MainActor @Sendable (AppRoute) -> Void {
        get { self[PhoneRouteActionKey.self] }
        set { self[PhoneRouteActionKey.self] = newValue }
    }
}

enum HomeDestinationV1: Equatable, Sendable {
    case route(AppRoute)
    case foundation(StationID)
}

struct HomeDestinationQuoteV1: Equatable, Sendable {
    var destination: HomeDestinationV1
    var stationID: StationID?
    var stationState: StationState?
    var mutationCount: Int
    var hasActiveRun: Bool
}

enum HomeDestinationRulesV1 {
    static func quote(_ destination: HomeDestinationV1,
                      in state: GameState) -> HomeDestinationQuoteV1? {
        guard state.worlds.activeRun == nil else { return nil }
        switch destination {
        case .route(let route):
            let station = ContentCatalog.shared.stations.first { $0.route == route.rawValue }
            if let station {
                let current = state.base.station(station.id)
                guard current.isUnlocked else { return nil }
                return .init(destination: destination, stationID: station.id,
                             stationState: current, mutationCount: state.meta.mutationCount,
                             hasActiveRun: false)
            }
            guard route == .settings || route == .party || route == .writingDesk else { return nil }
            return .init(destination: destination, stationID: nil, stationState: nil,
                         mutationCount: state.meta.mutationCount, hasActiveRun: false)
        case .foundation(let stationID):
            guard let station = ContentCatalog.shared.station(stationID) else { return nil }
            let current = state.base.station(station.id)
            guard !current.isUnlocked else { return nil }
            return .init(destination: destination, stationID: station.id,
                         stationState: current, mutationCount: state.meta.mutationCount,
                         hasActiveRun: false)
        }
    }
}

enum BaseBoardRules {
    static func destinations(from stations: [StationDef]) -> [StationDef] {
        stations.filter {
            $0.route != AppRoute.party.rawValue && $0.route != AppRoute.bestiary.rawValue
        }
    }

    static func knownStations(_ stations: [StationDef], unlocked: Set<StationID>,
                              foundations: Set<StationID>) -> [StationDef] {
        stations.filter { unlocked.contains($0.id) || foundations.contains($0.id) }
    }

    static func availableSections(for _: [StationDef]) -> [StationHomeSection] {
        // District navigation is permanent. A fresh save may know no destination in Make, Study,
        // or Realms yet, but hiding those tabs makes the town itself appear to be missing.
        StationHomeSection.allCases
    }

    static func stations(in section: StationHomeSection, from stations: [StationDef]) -> [StationDef] {
        stations.filter { $0.resolvedBoardPlacement.section == section }
    }

    static func columnCount(isAccessibilitySize: Bool) -> Int { isAccessibilitySize ? 2 : 3 }

    static func districtCaption(section: StationHomeSection, readyCount: Int,
                                foundationCount: Int) -> String {
        if section == .home { return "Home · 5 places ready" }
        if readyCount == 0, foundationCount == 0 { return "\(section.title) · no known places" }
        if foundationCount == 0 {
            return "\(section.title) · \(readyCount) place\(readyCount == 1 ? "" : "s") ready"
        }
        if readyCount == 0 {
            return "\(section.title) · \(foundationCount) foundation\(foundationCount == 1 ? "" : "s")"
        }
        return "\(section.title) · \(readyCount) ready · \(foundationCount) foundation\(foundationCount == 1 ? "" : "s")"
    }

    // Parked later-town helpers. The Band-1 Home adapter does not consume them.
    static let townPageCapacity = 4

    static func townPages(_ stations: [StationDef]) -> [[StationDef]] {
        stride(from: 0, to: stations.count, by: townPageCapacity).map {
            Array(stations[$0..<min($0 + townPageCapacity, stations.count)])
        }
    }

    static let townPlotPositions: [CGPoint] = [
        CGPoint(x: 0.24, y: 0.49), CGPoint(x: 0.75, y: 0.42),
        CGPoint(x: 0.25, y: 0.72), CGPoint(x: 0.75, y: 0.70)
    ]

    static func townBuildingAsset(for stationID: StationID) -> String? {
        TownBuildingVisualRegistry.assetName(for: stationID)
    }

    /// The district backdrop is aspect-filled, so its normalized plot coordinates must be mapped
    /// through the same scaled-and-cropped rectangle instead of the containing SwiftUI frame.
    static func townAspectFillFrame(imageSize: CGSize, containerSize: CGSize) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0,
              containerSize.width > 0, containerSize.height > 0 else { return .zero }
        let scale = max(containerSize.width / imageSize.width,
                        containerSize.height / imageSize.height)
        let rendered = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        return CGRect(x: (containerSize.width - rendered.width) / 2,
                      y: (containerSize.height - rendered.height) / 2,
                      width: rendered.width, height: rendered.height)
    }

    static func townPlotPoint(_ normalized: CGPoint, imageSize: CGSize,
                              containerSize: CGSize) -> CGPoint {
        let frame = townAspectFillFrame(imageSize: imageSize, containerSize: containerSize)
        return CGPoint(x: frame.minX + frame.width * normalized.x,
                       y: frame.minY + frame.height * normalized.y)
    }

}

@MainActor private enum TownVisualResource {
    static func image(named name: String) -> UIImage? {
        guard let path = Bundle.main.path(forResource: name, ofType: "png") else { return nil }
        return UIImage(contentsOfFile: path)
    }
}

/// The hub. Routes to station subscreens and out into a world.
///
/// The station list is **rendered from `ContentCatalog.stations`**, not hardcoded — v1+ adds a
/// blacksmith, a tavern, a distillery, and each of those should be a JSON entry plus a screen,
/// never a new button welded into this file.
struct BaseView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.phoneRouteAction) private var navigate
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var routeCardHidden = false
    @State private var selectedSection: StationHomeSection = .home
    @State private var townPageBySection: [StationHomeSection: Int] = [:]
    @State private var foundationStation: StationDef?
    @StateObject private var phoneAdmission = PhoneControlAdmissionV1()

    private var state: GameState { store.state }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                contextRow
                ZStack(alignment: .top) {
                    districtPager(containerSize: geometry.size)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    VStack(spacing: 3) {
                        sectionPicker
                        Text(districtCaption)
                            .font(.custom("Tiny5", size: 8))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(PixelUITheme.edgeDark.opacity(0.82))
                            .accessibilityIdentifier("base-district-caption")
                    }
                    .padding(.horizontal, 6)
                    .padding(.top, 6)
                }
            }
        }
        .background(PixelUITheme.screen.ignoresSafeArea())
        .navigationTitle("Village")
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            departure
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(PixelUITheme.screen)
                .overlay(alignment: .top) {
                    Rectangle().fill(PixelUITheme.edge).frame(height: 2)
                }
        }
        .onAppear { routeCardHidden = false }
        .onChange(of: availableSections) { _, sections in
            if !sections.contains(selectedSection) { selectedSection = .home }
        }
        .sheet(item: $foundationStation) { station in
            StationFoundationSheet(station: station)
                .environmentObject(store)
        }
        .tutorialHoverOverlay(isPresented: showsFirstReturnRouteCard, alignment: .top) {
            firstReturnRouteCard
        }
    }

    // MARK: Purse

    private var contextRow: some View {
        let settingsQuote = HomeDestinationRulesV1.quote(.route(.settings), in: state)
        return HStack(spacing: 12) {
            Text("Village")
                .font(.custom("Jersey 10", size: 26))
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 4)
            HStack(spacing: 5) {
                CompactCurrency(icon: "drop.fill", label: "Essence",
                                value: state.base.essenceCrystalCount, tint: .teal)
                Text("·").foregroundStyle(PixelUITheme.muted)
                CompactCurrency(icon: "star.fill", label: "Motes",
                                value: state.reality.motes, tint: .purple)
                Button {
                    admitRoute(.settings, quote: settingsQuote)
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 9, weight: .bold))
                        .frame(width: 24, height: 28)
                }
                .buttonStyle(.plain)
                .fullFacePressFeedback("village.route.settings", admission: phoneAdmission)
                .contentShape(Rectangle())
                .accessibilityLabel("Settings and save games")
            }
            .padding(.leading, 8)
            .padding(.trailing, 4)
            .frame(height: 32)
            .background(PixelUITheme.surfaceRaised)
            .overlay(Rectangle().stroke(PixelUITheme.edge, lineWidth: 1))
        }
        .frame(height: 62)
        .padding(.horizontal, 12)
        .foregroundStyle(PixelUITheme.text)
        .background(PixelUITheme.headerB)
        .overlay { PixelPaperGrid().allowsHitTesting(false) }
        .overlay(alignment: .bottom) {
            Rectangle().fill(PixelUITheme.edge).frame(height: 2)
        }
        .accessibilityIdentifier("base-context-row")
    }

    @ViewBuilder private var firstReturnRouteCard: some View {
        if !routeCardHidden,
           let context = state.tutorial.firstReturnContext,
           state.tutorial[.returnPersistenceBoundary].status == .completed,
           state.tutorial[.baseFirstResultRoute].status != .completed {
            let route = TutorialRules.destination(for: context.route)
            let routeQuote = HomeDestinationRulesV1.quote(.route(route), in: state)
            VStack(alignment: .leading, spacing: 10) {
                Text("Follow what returned").font(.headline)
                Text(TutorialRules.routeCopy(context, in: state)).font(.subheadline)
                HStack {
                    Button("Not now") {
                        store.deferTutorial(.baseFirstResultRoute)
                        routeCardHidden = true
                    }
                    .accessibilityIdentifier("base-first-return-not-now")
                    Spacer()
                    Button {
                        if let station = ContentCatalog.shared.stations.first(where: {
                            $0.route == route.rawValue
                        }) {
                            selectedSection = station.resolvedBoardPlacement.section
                        }
                        admitRoute(route, quote: routeQuote)
                    } label: {
                        Text("Open \(destinationName(context.route))")
                    }
                    .accessibilityIdentifier("base-first-return-open")
                    .buttonStyle(.borderedProminent)
                    .fullFacePressFeedback("village.route.\(route.rawValue)",
                                           admission: phoneAdmission)
                }
            }
            .padding(14)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(.tint.opacity(0.35)))
            .accessibilityIdentifier("base-first-return-route-card")
        }
    }

    private var showsFirstReturnRouteCard: Bool {
        !routeCardHidden
            && state.tutorial.firstReturnContext != nil
            && state.tutorial[.returnPersistenceBoundary].status == .completed
            && state.tutorial[.baseFirstResultRoute].status != .completed
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
        HStack(spacing: 3) {
            ForEach(availableSections, id: \.self) { section in
                Button {
                    admitLocalChange(noChange: section == selectedSection) {
                        selectedSection = section
                    }
                } label: {
                    Text(section.title)
                        .font(.custom("Tiny5", size: 10))
                        .foregroundStyle(section == selectedSection
                                         ? PixelUITheme.edgeDark : PixelUITheme.text)
                        .frame(maxWidth: .infinity, minHeight: 42)
                        .background(section == selectedSection
                                    ? PixelUITheme.primaryHighlight : PixelUITheme.surfaceRaised)
                        .overlay {
                            Rectangle().stroke(section == selectedSection
                                               ? PixelUITheme.edgeDark : PixelUITheme.edge,
                                               lineWidth: 2)
                        }
                        .background {
                            Rectangle()
                                .fill(PixelUITheme.shadow.opacity(0.55))
                                .offset(x: 2, y: 2)
                        }
                }
                .buttonStyle(.plain)
                .fullFacePressFeedback("village.tab.\(section.rawValue)",
                                       admission: phoneAdmission)
                .accessibilityAddTraits(section == selectedSection ? .isSelected : [])
            }
        }
        .padding(5)
        .background(PixelUITheme.edgeDark.opacity(0.84))
        .accessibilityIdentifier("base-section-picker")
    }

    private var districtCaption: String {
        let destinations = stations(in: selectedSection)
        let readyCount = destinations.filter { state.base.station($0.id).isUnlocked }.count
        return BaseBoardRules.districtCaption(
            section: selectedSection,
            readyCount: readyCount,
            foundationCount: destinations.count - readyCount)
    }

    private func districtPager(containerSize: CGSize) -> some View {
        TabView(selection: $selectedSection) {
            ForEach(availableSections, id: \.self) { section in
                districtBoard(section: section, containerSize: containerSize)
                    .tag(section)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .accessibilityIdentifier("base-district-pager")
    }

    @ViewBuilder
    private func districtBoard(section: StationHomeSection, containerSize: CGSize) -> some View {
        Group {
            if section == .home,
               let scene = StartingTownHomeResource.scene() {
                StartingTownHomeScene(scene: scene,
                                      destinationQuotes: homeRouteQuotes,
                                      admission: phoneAdmission,
                                      openedRoute: admitRoute)
            } else if section != .home,
                      TownVisualResource.image(named: "town-empty-v1") != nil {
                townDistrictBoard(section: section, containerSize: containerSize)
            } else {
                legacyStationGrid(section: section)
            }
        }
        .accessibilityIdentifier("base-station-board-\(section.rawValue)")
    }

    private func townDistrictBoard(section: StationHomeSection, containerSize: CGSize) -> some View {
        let destinations = stations(in: section)
        let populatedPages = BaseBoardRules.townPages(destinations)
        let pages = populatedPages.isEmpty ? [[]] : populatedPages
        let selectedPage = min(townPageBySection[section, default: 0], pages.count - 1)
        let visibleStations = pages[selectedPage]
        let routeQuotes: [AppRoute: HomeDestinationQuoteV1] = Dictionary(
            uniqueKeysWithValues: visibleStations.compactMap { station in
                guard let route = AppRoute(rawValue: station.route),
                      let quote = HomeDestinationRulesV1.quote(.route(route), in: state)
                else { return nil }
                return (route, quote)
            })
        let foundationQuotes: [StationID: HomeDestinationQuoteV1] = Dictionary(
            uniqueKeysWithValues: visibleStations.compactMap { station in
                HomeDestinationRulesV1.quote(.foundation(station.id), in: state)
                    .map { (station.id, $0) }
            })
        return VStack(spacing: 0) {
            TownDistrictScene(
                section: section,
                stations: visibleStations,
                stationState: { state.base.station($0) },
                routeQuotes: routeQuotes,
                foundationQuotes: foundationQuotes,
                admission: phoneAdmission,
                openFoundation: admitFoundation,
                openedRoute: admitRoute
            )
            if pages.count > 1 {
                HStack(spacing: 12) {
                    Button("Previous") {
                        admitLocalChange(noChange: selectedPage == 0) {
                            townPageBySection[section] = max(0, selectedPage - 1)
                        }
                    }
                    .disabled(selectedPage == 0)
                    Spacer()
                    Text("\(selectedPage + 1) of \(pages.count)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Next") {
                        admitLocalChange(noChange: selectedPage == pages.count - 1) {
                            townPageBySection[section] = min(pages.count - 1, selectedPage + 1)
                        }
                    }
                    .disabled(selectedPage == pages.count - 1)
                }
                .frame(minHeight: 44)
                .padding(.horizontal, 12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("base-town-scene-\(section.rawValue)")
    }

    private func legacyStationGrid(section: StationHomeSection) -> some View {
        let destinations = stations(in: section)
        return Group {
            if destinations.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Label("No known destinations", systemImage: "signpost.right")
                        .font(.headline)
                    Text("No places are known in \(section.title) yet.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color(.secondarySystemGroupedBackground),
                            in: RoundedRectangle(cornerRadius: 14))
            } else {
                LazyVGrid(columns: stationColumns, spacing: 12) {
                    ForEach(destinations) { station in stationDestination(station) }
                }
            }
        }
    }

    @ViewBuilder private func stationDestination(_ station: StationDef) -> some View {
        if state.base.station(station.id).isUnlocked {
            let route = AppRoute(rawValue: station.route) ?? .base
            let quote = HomeDestinationRulesV1.quote(.route(route), in: state)
            Button {
                admitRoute(route, quote: quote)
            } label: {
                StationTile(station: station, tier: state.base.station(station.id).tier,
                            isFoundation: false)
            }
            .buttonStyle(.plain)
            .fullFacePressFeedback("village.route.\(route.rawValue)", admission: phoneAdmission)
        } else {
            let quote = HomeDestinationRulesV1.quote(.foundation(station.id), in: state)
            Button { admitFoundation(station, quote: quote) } label: {
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
        .accessibilityIdentifier("base-departure")
    }

    @ViewBuilder private var baseActionButtons: some View {
        let partyQuote = HomeDestinationRulesV1.quote(.route(.party), in: state)
        let writingQuote = HomeDestinationRulesV1.quote(.route(.writingDesk), in: state)
        Button {
            admitRoute(.party, quote: partyQuote)
        } label: {
            Label("Party", systemImage: "person.2.fill")
                .font(.custom("Jersey 10", size: 16))
                .foregroundStyle(PixelUITheme.text)
                .frame(minWidth: dynamicTypeSize.isAccessibilitySize ? 0 : 92,
                       maxWidth: dynamicTypeSize.isAccessibilitySize ? .infinity : nil)
                .frame(minHeight: 44)
                .background(PixelUITheme.surfaceRaised)
                .overlay {
                    Rectangle().stroke(PixelUITheme.edge, lineWidth: 2)
                }
                .background {
                    Rectangle().fill(PixelUITheme.shadow.opacity(0.55)).offset(x: 2, y: 2)
                }
        }
        .buttonStyle(.plain)
        .fullFacePressFeedback("village.route.party", admission: phoneAdmission)
        .accessibilityHint("Manage party members, gear and gambits")

        Button {
            admitRoute(.writingDesk, quote: writingQuote)
        } label: {
            Label("Bind & Depart", systemImage: "arrow.up.forward.circle.fill")
                .font(.custom("Tiny5", size: 12))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .background(PixelUITheme.primary)
                .overlay(Rectangle().stroke(PixelUITheme.edgeDark, lineWidth: 2))
                .background {
                    Rectangle().fill(PixelUITheme.shadow.opacity(0.55)).offset(x: 2, y: 2)
                }
        }
        .buttonStyle(.plain)
        .fullFacePressFeedback("village.route.writingDesk", admission: phoneAdmission)
        .accessibilityHint(departureHint)
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
        let written = marks == 1 ? "One Sigil speaking" : "\(marks) Sigils speaking"
        if rolled == 0 {
            return "\(written), and nothing left to chance. Waiting at the desk."
        }
        return "\(written); \(rolled) subject\(rolled == 1 ? "" : "s") still to roll."
    }

    private var homeRouteQuotes: [AppRoute: HomeDestinationQuoteV1] {
        Dictionary(uniqueKeysWithValues: StartingTownHomeRules.homeRoutes.compactMap { route in
            HomeDestinationRulesV1.quote(.route(route), in: state).map { (route, $0) }
        })
    }

    private func admitRoute(_ route: AppRoute, quote: HomeDestinationQuoteV1?) {
        guard let quote else {
            phoneAdmission.touchDown(disabledReason: "That destination is unavailable.")
            return
        }
        _ = phoneAdmission.release(controlID: "village.route.\(route.rawValue)") {
            guard HomeDestinationRulesV1.quote(.route(route), in: store.state) == quote else {
                return .failure(.stale)
            }
            navigate(route)
            return .success(.navigationAccepted(route))
        }
    }

    private func admitFoundation(_ station: StationDef, quote: HomeDestinationQuoteV1?) {
        guard let quote else {
            phoneAdmission.touchDown(disabledReason: "That foundation is unavailable.")
            return
        }
        _ = phoneAdmission.release(controlID: "village.foundation.\(station.id)") {
            guard HomeDestinationRulesV1.quote(.foundation(station.id), in: store.state) == quote
            else { return .failure(.stale) }
            foundationStation = station
            return .success(.navigationAccepted(.base))
        }
    }

    private func admitLocalChange(noChange: Bool, action: @escaping @MainActor () -> Void) {
        _ = phoneAdmission.release {
            guard !noChange else { return .success(.noChange) }
            action()
            return .success(.committed)
        }
    }
}

// MARK: - Pieces

private struct TownDistrictScene: View {
    let section: StationHomeSection
    let stations: [StationDef]
    let stationState: (StationID) -> StationState
    let routeQuotes: [AppRoute: HomeDestinationQuoteV1]
    let foundationQuotes: [StationID: HomeDestinationQuoteV1]
    let admission: PhoneControlAdmissionV1
    let openFoundation: (StationDef, HomeDestinationQuoteV1?) -> Void
    let openedRoute: (AppRoute, HomeDestinationQuoteV1?) -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let backdrop = TownVisualResource.image(named: "town-empty-v1") {
                    let renderedFrame = BaseBoardRules.townAspectFillFrame(
                        imageSize: backdrop.size, containerSize: geometry.size)
                    Image(uiImage: backdrop)
                    .resizable()
                    .interpolation(.none)
                    .frame(width: renderedFrame.width, height: renderedFrame.height)
                    .position(x: renderedFrame.midX, y: renderedFrame.midY)
                    .allowsHitTesting(false)
                }

                LinearGradient(colors: [.black.opacity(0.04), .clear, .black.opacity(0.16)],
                               startPoint: .top, endPoint: .bottom)
                    .allowsHitTesting(false)

                ForEach(Array(stations.enumerated()), id: \.element.id) { index, station in
                    let position = BaseBoardRules.townPlotPositions[index]
                    let backdropSize = TownVisualResource.image(named: "town-empty-v1")?.size
                        ?? geometry.size
                    let renderedPoint = BaseBoardRules.townPlotPoint(
                        position, imageSize: backdropSize, containerSize: geometry.size)
                    TownStationPlot(station: station,
                                    stationState: stationState(station.id),
                                    routeQuote: AppRoute(rawValue: station.route)
                                        .flatMap { routeQuotes[$0] },
                                    foundationQuote: foundationQuotes[station.id],
                                    admission: admission,
                                    openFoundation: {
                                        openFoundation(station, foundationQuotes[station.id])
                                    },
                                    openedRoute: openedRoute)
                        .frame(width: min(132, geometry.size.width * 0.38), height: 132)
                        .position(renderedPoint)
                }

                if stations.isEmpty {
                    VStack(spacing: 6) {
                        Label("No known destinations", systemImage: "signpost.right")
                            .font(.headline)
                        Text("No places are known in \(section.title) yet.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                    .padding(20)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
        }
        .clipped()
    }
}

private struct TownStationPlot: View {
    let station: StationDef
    let stationState: StationState
    let routeQuote: HomeDestinationQuoteV1?
    let foundationQuote: HomeDestinationQuoteV1?
    let admission: PhoneControlAdmissionV1
    let openFoundation: () -> Void
    let openedRoute: (AppRoute, HomeDestinationQuoteV1?) -> Void

    var body: some View {
        Group {
            if stationState.isUnlocked {
                let route = AppRoute(rawValue: station.route) ?? .base
                Button {
                    openedRoute(route, routeQuote)
                } label: {
                    content(isFoundation: false)
                }
                .accessibilityIdentifier("base-town-\(route.rawValue)")
                .fullFacePressFeedback("village.route.\(route.rawValue)", admission: admission)
            } else {
                Button(action: openFoundation) { content(isFoundation: true) }
                    .fullFacePressFeedback("village.foundation.\(station.id)", admission: admission)
            }
        }
        .buttonStyle(.plain)
    }

    private func content(isFoundation: Bool) -> some View {
        VStack(spacing: 2) {
            ZStack(alignment: .bottomTrailing) {
                if !isFoundation,
                   let asset = BaseBoardRules.townBuildingAsset(for: station.id),
                   let image = TownVisualResource.image(named: asset) {
                    Image(uiImage: image)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                } else if isFoundation {
                    Image(systemName: "hammer.fill")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .frame(width: 48, height: 48)
                        .background(.thickMaterial, in: Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.8), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3])))
                        .shadow(color: .black.opacity(0.28), radius: 3, y: 2)
                } else {
                    Image(systemName: station.icon)
                        .font(.title2.weight(.medium))
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 58, height: 58)
                        .background(.thickMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.75)))
                        .shadow(color: .black.opacity(0.28), radius: 3, y: 2)
                }
            }
            .frame(height: 94)

            HStack(spacing: 4) {
                Text(station.name)
                    .lineLimit(1)
                if isFoundation {
                    Text("Build").foregroundStyle(.secondary)
                } else if stationState.tier > 0 {
                    Text("T\(stationState.tier)").foregroundStyle(.secondary)
                }
            }
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.78), in: RoundedRectangle(cornerRadius: 5, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .stroke(Color(red: 0.91, green: 0.84, blue: 0.68).opacity(0.92), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.45), radius: 2, y: 1)
        }
        .contentShape(Rectangle())
    }
}

private struct TownHotspotSign: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color.black.opacity(0.78), in: RoundedRectangle(cornerRadius: 5, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .stroke(Color(red: 0.91, green: 0.84, blue: 0.68).opacity(0.92), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.45), radius: 2, y: 1)
    }
}

private struct CompactCurrency: View {
    let icon: String
    let label: String
    let value: Int
    let tint: Color

    var body: some View {
        Label {
            Text("\(value) \(label)")
                .font(.custom("Tiny5", size: 8))
        } icon: {
            Image(systemName: icon)
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(tint)
        }
        .labelStyle(.titleAndIcon)
        .accessibilityLabel("\(value) \(label)")
    }
}

private struct PixelPaperGrid: View {
    var body: some View {
        Canvas { context, size in
            var path = Path()
            for x in stride(from: CGFloat.zero, through: size.width, by: 8) {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
            }
            for y in stride(from: CGFloat.zero, through: size.height, by: 8) {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
            }
            context.stroke(path, with: .color(PixelUITheme.edge.opacity(0.08)), lineWidth: 0.5)
        }
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
                let affordability = runway.affordability
                VStack(alignment: .leading, spacing: 5) {
                    LabeledContent("Essence available now", value: "\(affordability.essenceAvailableNow)")
                    if affordability.includesRefining {
                        LabeledContent("Essence after refining", value: "\(affordability.essenceAfterRefining)")
                    }
                    LabeledContent(affordability.afterActionLabel,
                                   value: "\(affordability.essenceAfterAction)")
                    if let basisLabel = affordability.basisLabel,
                       let basisCost = affordability.basisCost,
                       let count = affordability.formattedWorldCount {
                        LabeledContent(basisLabel,
                                       value: basisCost.formatted(.number.precision(.fractionLength(0...1))))
                        LabeledContent(affordability.worldCountLabel, value: count)
                    } else {
                        Text(affordability.noBasisCopy)
                    }
                    if let warning = affordability.warningCopy {
                        Label(warning, systemImage: "exclamationmark.triangle")
                            .foregroundStyle((affordability.worldsAffordable ?? 2) < 1 ? .red : .orange)
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
            parts.append("\(amount) \(StationCataloguePresentation.resourceName(id).lowercased())")
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
