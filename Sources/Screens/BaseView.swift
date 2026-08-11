import SwiftUI

/// The hub. Routes to station subscreens and out into a world.
///
/// The station list is **rendered from `ContentCatalog.stations`**, not hardcoded — v1+ adds a
/// blacksmith, a tavern, a distillery, and each of those should be a JSON entry plus a screen,
/// never a new button welded into this file.
struct BaseView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var routeCardHidden = false

    private var state: GameState { store.state }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                purse
                firstReturnRouteCard
                stations
                buildingSites
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Base")
        .navigationBarTitleDisplayMode(.large)
        .safeAreaInset(edge: .bottom) {
            departure
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.bar)
        }
        .onAppear { routeCardHidden = false }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: AppRoute.settings) {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("Settings")
            }
            ToolbarItem(placement: .topBarTrailing) {
                // Development-only entry to the milestone-1 persistence harness.
                NavigationLink(value: AppRoute.harness) {
                    Image(systemName: "wrench.and.screwdriver")
                }
                .accessibilityLabel("Persistence harness")
            }
        }
    }

    // MARK: Purse

    private var purse: some View {
        HStack(spacing: 12) {
            CurrencyChip(icon: "drop.fill", label: "Essence", value: "\(state.base.essence)", tint: .teal)
            CurrencyChip(icon: "star.fill", label: "Motes", value: "\(state.reality.motes)", tint: .purple)
        }
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
        case .firepit: "Firepit"
        case .writingDesk: "Writing Desk"
        }
    }

    // MARK: Stations

    private var stations: some View {
        LazyVGrid(columns: stationColumns, spacing: 12) {
            ForEach(unlockedStations) { station in
                let route = AppRoute(rawValue: station.route) ?? .base
                NavigationLink(value: route) {
                    StationTile(station: station, tier: state.base.station(station.id).tier)
                }
                .buttonStyle(.plain)
                .simultaneousGesture(TapGesture().onEnded {
                    store.openedFirstReturnDestination(route)
                })
            }
        }
    }

    private var stationColumns: [GridItem] {
        dynamicTypeSize.isAccessibilitySize
            ? [GridItem(.flexible())]
            : [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    }

    // MARK: Building sites

    /// **What you could raise, now that you've met somebody who'd run it** (Aimee, 6 Aug).
    ///
    /// Sits under the stations rather than in a shop, because that's what it is: a patch of ground
    /// with a person standing on it waiting for you to find the iron.
    @ViewBuilder
    private var buildingSites: some View {
        if !store.buildableStations.isEmpty {
            VStack(spacing: 10) {
                ForEach(store.buildableStations) { station in
                    BuildingSiteCard(station: station)
                }
            }
        }
    }

    private var unlockedStations: [StationDef] {
        ContentCatalog.shared.stationsInOrder.filter { state.base.station($0.id).isUnlocked }
    }

    // MARK: Departure

    private var departure: some View {
        VStack(spacing: 8) {
            NavigationLink(value: AppRoute.writingDesk) {
                Label("Bind & Depart", systemImage: "arrow.up.forward.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 56) // primary action, thumb zone, well over 44pt
            }
            .buttonStyle(.borderedProminent)
            .simultaneousGesture(TapGesture().onEnded {
                store.openedFirstReturnDestination(.writingDesk)
            })

            Text(departureHint)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(.top, 4)
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

private struct StationTile: View {
    let station: StationDef
    let tier: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: station.icon)
                .font(.title)
                .frame(width: 40, height: 40)
                .foregroundStyle(.tint)

            VStack(alignment: .leading, spacing: 2) {
                Text(station.name).font(.headline)
                Text(station.blurb)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            HStack {
                if tier > 0 {
                    Text("Tier \(tier)")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.tertiarySystemFill), in: Capsule())
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 156, alignment: .topLeading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
        .contentShape(RoundedRectangle(cornerRadius: 14))
    }
}

/// A building that could exist, and doesn't yet.
///
/// The card carries the *person's* line rather than a shop blurb, because meeting them is what
/// unlocked it — "Halloway will raise a forge here, if you can find the stone and the iron for it."
private struct BuildingSiteCard: View {
    @EnvironmentObject private var store: GameStore
    let station: StationDef

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: station.icon)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(width: 30)
                VStack(alignment: .leading, spacing: 2) {
                    Text(station.name).font(.headline)
                    if let person = station.builtBy.flatMap({ ContentCatalog.shared.traveller($0) }) {
                        Text("\(person.name), \(person.calling)")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 0)
                Text("not built")
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
                Text(describe(cost))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            let missing = store.shortfall(for: station)
            if missing.isEmpty {
                Button { store.build(station) } label: {
                    Label("Build it", systemImage: "hammer")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
            } else {
                // Says what's short rather than greying out a button and leaving you to work it
                // out — the same promise the research tree makes.
                Text("Still need \(missing.joined(separator: ", ")).")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(minHeight: 44)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
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
