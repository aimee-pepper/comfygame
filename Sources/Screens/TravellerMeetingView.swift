import SwiftUI

/// Meeting somebody in a world you wrote for them.
///
/// **This is the payoff of the entire search loop**, and until today it didn't exist: arriving in a
/// world matching a signature marked the person found in the save, silently, and a building
/// appeared at the base for somebody the player had never laid eyes on. Aimee, 6 Aug: *"finding a
/// traveller should mean actually running across the person as an entity on a world you find them
/// in"*, and *"there should be a text interaction where you recruit them."*
///
/// So it's a scene. Small on purpose — an opening, some things you can ask, and a decision. Nobody
/// here is a quest chain; what gives the moment its weight is that you *wrote the world they were
/// standing in*, and that the floor is coming apart while you talk.
struct TravellerMeetingView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss
    let traveller: TravellerDef

    /// Which questions have been asked, so their answers stay on screen. Local to the sheet: a
    /// conversation you walked away from is one you can have again.
    @State private var asked: Set<String> = []

    private var meeting: TravellerMeeting? { traveller.meeting }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    who

                    if let meeting {
                        said(meeting.opening)

                        ForEach(meeting.questions) { exchange in
                            if asked.contains(exchange.id) {
                                youSaid(exchange.ask)
                                said(exchange.reply)
                            }
                        }

                        // Everything left to ask. Asking is free and doesn't take a turn — the
                        // world's own clock is the only pressure here, and it's enough.
                        let remaining = meeting.questions.filter { !asked.contains($0.id) }
                        if !remaining.isEmpty {
                            VStack(spacing: 8) {
                                ForEach(remaining) { exchange in
                                    Button {
                                        withAnimation { _ = asked.insert(exchange.id) }
                                    } label: {
                                        Text(exchange.ask)
                                            .font(.callout)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .frame(minHeight: 44)
                                            .padding(.horizontal, 12)
                                            .background(Color(.tertiarySystemFill),
                                                        in: RoundedRectangle(cornerRadius: 10))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    } else {
                        said(traveller.blurb)
                    }
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .safeAreaInset(edge: .bottom) { decision }
            .navigationTitle(traveller.name)
            .navigationBarTitleDisplayMode(.inline)
        }
        .interactiveDismissDisabled()
    }

    private var who: some View {
        HStack(spacing: 12) {
            Image(systemName: traveller.icon)
                .font(.title2)
                .foregroundStyle(.green)
                .frame(width: 34)
            VStack(alignment: .leading, spacing: 2) {
                Text(traveller.name).font(.headline)
                Text(traveller.calling).font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
    }

    /// Their words. Given the page's own indent so a conversation reads as one.
    private func said(_ text: String) -> some View {
        Text(text)
            .font(.callout)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(12)
            .background(Color(.secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 12))
    }

    private func youSaid(_ text: String) -> some View {
        Text(text)
            .font(.callout.italic())
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// **Yes or not yet.** Declining isn't punished and isn't final while the world holds — but the
    /// world is coming apart, so "I'll come back" is a bet rather than a plan.
    private var decision: some View {
        VStack(spacing: 8) {
            Button {
                store.recruit(traveller.id)
                dismiss()
            } label: {
                Text(meeting?.offer ?? "Come back with me.")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 52)
            }
            .buttonStyle(.borderedProminent)

            Button("Leave them") { dismiss() }
                .font(.callout)
                .frame(minHeight: 44)

            if let declined = meeting?.declined {
                Text(declined)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .background(.bar)
    }
}
