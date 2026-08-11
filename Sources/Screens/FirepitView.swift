import SwiftUI

/// Where the people you've brought home are, and who you can take with you.
///
/// **It is not a second Party screen.** The Party screen is where somebody's gear, rules and stats
/// live; this is the room they're standing in. Aimee, 7 Aug: *"there are STILL NO AVAILABLE
/// COMPANIONS around the firepit. It just shows a MASSIVE panel for the party member you ALREADY
/// HAVE and a front/back row selector for some reason?"* — she was right on both counts. It was
/// duplicating the roster in a bigger form, and rank belongs with the character, not with the room.
///
/// **The one building that isn't found first.** Every other station comes from meeting somebody
/// who'd run it, but you need somewhere to put the first person before anyone can build anything,
/// so the firepit is simply here from the start. It becomes the Tavern when the Keeper turns up —
/// the firepit holds *your* people, the tavern brings you other people's.
struct FirepitView: View {
    @EnvironmentObject private var store: GameStore
    @State private var pendingTransfer: PartyTransferPreview?

    private var roster: [CompanionState] { store.state.base.roster }
    private var coming: [(index: Int, member: CompanionState)] {
        roster.enumerated().filter { store.isComing($0.offset) }.map { ($0.offset, $0.element) }
    }
    private var home: [(index: Int, member: CompanionState)] {
        roster.enumerated().filter { store.placement(of: $0.offset) == .home }
            .map { ($0.offset, $0.element) }
    }
    private var posted: [(index: Int, member: CompanionState)] {
        roster.enumerated().filter {
            if case .anchoredRealm = store.placement(of: $0.offset) { return true }
            return false
        }.map { ($0.offset, $0.element) }
    }
    /// You count as one of the five, so four is as many as can come with you.
    private var seatsLeft: Int {
        max(0, Tuning.Party.maximumSize - 1 - store.state.base.activeParty.count)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                StationCard(title: "Who's coming — you and \(coming.count)", icon: "figure.walk") {
                    if coming.isEmpty {
                        EmptyNote("Nobody but you.")
                    } else {
                        ForEach(coming, id: \.index) { entry in
                            row(entry.member, index: entry.index)
                        }
                    }
                    if seatsLeft > 0 {
                        Text(seatsLeft == 1 ? "Room for one more." : "Room for \(seatsLeft) more.")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                }

                StationCard(title: "Around the fire — \(home.count)", icon: "flame.fill") {
                    if home.isEmpty {
                        EmptyNote("Nobody else, yet. People are out in the worlds: read a diary, write the world it describes, and walk up to whoever is standing in it.")
                    } else {
                        ForEach(home, id: \.index) { entry in
                            row(entry.member, index: entry.index)
                        }
                    }
                }

                if !posted.isEmpty {
                    StationCard(title: "Posted in realms — \(posted.count)", icon: "map.fill") {
                        ForEach(posted, id: \.index) { entry in
                            row(entry.member, index: entry.index)
                        }
                    }
                }

                if !store.state.base.canRecruit {
                    ComingLater("The fire is full — five is as many as you can keep.")
                }

                ComingLater("A tavern would bring other people's travellers through, to be asked for directions. Somebody has to keep it, and you haven't met them yet.")
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("The Firepit")
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $pendingTransfer) { preview in
            Alert(
                title: Text("Take \(preview.name) with you?"),
                message: Text(transferMessage(preview)),
                primaryButton: .default(Text("Take with you")) {
                    _ = store.setComing(preview.index, true, expected: preview.source)
                },
                secondaryButton: .cancel()
            )
        }
    }

    /// One person, in one line. Their sheet is on the Party screen; this is just who they are and
    /// whether they're coming.
    private func row(_ member: CompanionState, index: Int) -> some View {
        HStack(spacing: 10) {
            Image(systemName: member.icon)
                .foregroundStyle(.orange)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 1) {
                Text(member.name).font(.callout.weight(.medium))
                Text(member.calling.isEmpty
                     ? "Level \(member.character.level)"
                     : "\(member.calling.capitalisedSentence) · level \(member.character.level)")
                    .font(.caption2).foregroundStyle(.secondary)
            }
            Spacer(minLength: 6)
            if store.isComing(index) {
                Button("Send Home") { _ = store.setComing(index, false, expected: .activeParty) }
                    .font(.caption2.weight(.medium))
                    .buttonStyle(.bordered)
            } else {
                Button("Take them") { pendingTransfer = store.partyTransferPreview(for: index) }
                    .font(.caption2.weight(.medium))
                    .buttonStyle(.borderedProminent)
                    .disabled(seatsLeft == 0)
            }
        }
        .frame(minHeight: 44)
    }

    private func transferMessage(_ preview: PartyTransferPreview) -> String {
        var lines: [String] = []
        switch preview.source {
        case .home:
            if !preview.stationNames.isEmpty {
                lines.append("Home benefits pause at \(preview.stationNames.joined(separator: ", ")).")
            } else {
                lines.append("They will leave Home and join the active party.")
            }
        case .activeParty:
            lines.append("They are already in the active party.")
        case .anchoredRealm(_, let name):
            if let before = preview.realmProductionBefore, let after = preview.realmProductionAfter,
               let shortfallBefore = preview.realmShortfallBefore,
               let shortfallAfter = preview.realmShortfallAfter {
                lines.append("\(name) production: \(before) → \(after).")
                lines.append("Sustain shortfall: \(shortfallBefore) → \(shortfallAfter) Essence.")
            }
            lines.append("Their realm posting ends when you confirm.")
        }
        lines.append("Returning them later sends them Home; it will not restore an old posting.")
        return lines.joined(separator: "\n")
    }
}
