import SwiftUI

/// Top-level routing.
///
/// Being inside a world is a *state*, not a navigation destination: if a run is active, that's the
/// screen you're on, full stop. Which means a force-quit mid-run can't strand you in the wrong
/// place — the save decides where you are, not a navigation stack we'd have to restore.
struct RootView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        if store.activeEncounter != nil {
            EncounterView()
        } else if store.state.worlds.isInRun {
            WorldView()
        } else {
            NavigationStack {
                BaseView()
                    .navigationDestination(for: AppRoute.self) { route in
                        destination(for: route)
                    }
            }
        }
    }

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .writingDesk: WritingDeskView()
        case .storehouse: StorehouseView()
        case .workshop: WorkshopView()
        case .party: PartyView()
        case .essenceSpring: EssenceSpringView()
        case .constellation: ConstellationView()
        case .library: LibraryView()
        case .blacksmith: BlacksmithView()
        case .settings: SettingsView()
        case .harness: HarnessView()
        // Reached as state, not as a pushed destination.
        case .base, .world, .encounter: BaseView()
        }
    }
}

#Preview {
    RootView()
        .environmentObject(GameStore(io: .temporary(name: "preview-root")))
}
