import SwiftUI

@main
struct BookbinderApp: App {
    @StateObject private var store: GameStore
    @StateObject private var settings = AppSettings()
    @Environment(\.scenePhase) private var scenePhase

    init() {
#if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--debug-world") {
            let visualStore = GameStore(io: .temporary(name: "visual-world"))
            visualStore.resetEverything()
            _ = visualStore.bindAndDepart()
            _store = StateObject(wrappedValue: visualStore)
            return
        }
#endif
        _store = StateObject(wrappedValue: GameStore.live())
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(settings)
                // nil follows the phone; light/dark override it.
                .preferredColorScheme(settings.theme.colorScheme)
        }
        .onChange(of: scenePhase) { _, phase in
            // Leaving .active is the last reliable moment before iOS may suspend or kill us.
            // Write synchronously here rather than trusting the debounce to land.
            if phase != .active { store.flushNow() }
        }
    }
}
