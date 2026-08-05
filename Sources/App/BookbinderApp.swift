import SwiftUI

@main
struct BookbinderApp: App {
    @StateObject private var store = GameStore.live()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
        }
        .onChange(of: scenePhase) { _, phase in
            // Leaving .active is the last reliable moment before iOS may suspend or kill us.
            // Write synchronously here rather than trusting the debounce to land.
            if phase != .active { store.flushNow() }
        }
    }
}
