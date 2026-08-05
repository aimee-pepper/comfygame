import SwiftUI

/// Milestone 1 boots straight into the persistence harness — there are no game screens yet.
/// Milestone 2 replaces this with the Base hub, and the harness moves behind a debug entry.
struct RootView: View {
    var body: some View {
        HarnessView()
    }
}

#Preview {
    RootView()
        .environmentObject(GameStore(io: .temporary(name: "preview")))
}
