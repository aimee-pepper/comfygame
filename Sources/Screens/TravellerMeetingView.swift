import SwiftUI

enum AuthoredTextRendering {
    static func attributed(_ source: String) -> AttributedString {
        (try? AttributedString(
            markdown: source,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )) ?? AttributedString(source)
    }
}

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

    @State private var conversation = TravellerMeetingConversation()
    @State private var blockedReason: String?

    private var meeting: TravellerMeeting? { traveller.meeting }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    who

                    if let meeting {
                        said(meeting.opening)

                        ForEach(conversation.orderedExchangeIDs, id: \.self) { id in
                            if let exchange = meeting.questions.first(where: { $0.id == id }) {
                                youSaid(exchange.ask)
                                said(exchange.reply)
                            }
                        }

                        if let terminal = conversation.terminal {
                            said(terminal == .accepted ? meeting.accepted : meeting.declined)
                        }

                        // Everything left to ask. Asking is free and doesn't take a turn — the
                        // world's own clock is the only pressure here, and it's enough.
                        let remaining = meeting.questions.filter { !conversation.orderedExchangeIDs.contains($0.id) }
                        if conversation.terminal == nil, !remaining.isEmpty {
                            VStack(spacing: 8) {
                                ForEach(remaining) { exchange in
                                    Button {
                                        withAnimation { conversation.ask(exchange.id) }
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
            NamedCharacterPixelIdentity(
                travellerID: traveller.id,
                fallbackSystemIcon: traveller.icon,
                fallbackColor: .green
            )
            .frame(width: 34, height: 34)
            VStack(alignment: .leading, spacing: 2) {
                Text(traveller.name).font(.headline)
                Text(traveller.calling).font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
    }

    /// Their words. Given the page's own indent so a conversation reads as one.
    private func said(_ text: String) -> some View {
        Text(AuthoredTextRendering.attributed(text))
            .font(.callout)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(12)
            .background(Color(.secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 12))
    }

    private func youSaid(_ text: String) -> some View {
        Text(AuthoredTextRendering.attributed(text))
            .font(.callout.italic())
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// **Yes or not yet.** Declining isn't punished and isn't final while the world holds — but the
    /// world is coming apart, so "I'll come back" is a bet rather than a plan.
    private var decision: some View {
        PersistentActionBar(
            message: decisionMessage,
            messageTint: blockedReason == nil ? .secondary : .red
        ) {
            if conversation.terminal == nil {
                HStack(spacing: 10) {
                    Button("Not now") {
                        blockedReason = nil
                        withAnimation { conversation.decline() }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)

                Button {
                    store.recruit(traveller.id)
                    if store.state.reality.library.foundTravellers.contains(traveller.id) {
                        blockedReason = nil
                        withAnimation { conversation.accept() }
                    } else {
                        blockedReason = store.recentEvents.reversed().compactMap {
                            if case .blocked(let reason) = $0 { reason } else { nil }
                        }.first ?? "They cannot come with you yet."
                    }
                } label: {
                    Text("Invite them")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                }
            } else {
                Button(conversation.terminal == .declined ? "Leave" : "Continue") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var decisionMessage: String {
        if let blockedReason { return blockedReason }
        if conversation.terminal == nil {
            return meeting?.offer ?? "Come back with me."
        }
        return conversation.terminal == .declined
            ? "You can still leave before the world closes."
            : "They are ready to return with you."
    }
}

struct TravellerMeetingConversation: Equatable {
    enum Terminal: Equatable { case accepted, declined }
    private(set) var orderedExchangeIDs: [String] = []
    private(set) var terminal: Terminal?

    mutating func ask(_ id: String) {
        guard terminal == nil, !orderedExchangeIDs.contains(id) else { return }
        orderedExchangeIDs.append(id)
    }

    mutating func accept() { guard terminal == nil else { return }; terminal = .accepted }
    mutating func decline() { guard terminal == nil else { return }; terminal = .declined }
}

struct AuthoredDialogueLine: View {
    let text: String
    var isPlayer = false

    var body: some View {
        Text(AuthoredTextRendering.attributed(text))
            .font(isPlayer ? .callout.italic() : .callout)
            .foregroundStyle(isPlayer ? .secondary : .primary)
            .frame(maxWidth: .infinity, alignment: isPlayer ? .trailing : .leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(isPlayer ? 0 : 12)
            .background(isPlayer ? Color.clear : Color(.secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 12))
    }
}
