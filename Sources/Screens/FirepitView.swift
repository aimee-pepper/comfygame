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

    private var roster: [CompanionState] { store.state.base.roster }
    private var activeIndex: Int { store.state.base.activeCompanion }
    /// Everybody who isn't currently walking out with you — the point of the screen.
    private var waiting: [(index: Int, member: CompanionState)] {
        roster.enumerated().filter { $0.offset != activeIndex }.map { ($0.offset, $0.element) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                StationCard(title: "Who's coming", icon: "figure.walk") {
                    if roster.indices.contains(activeIndex) {
                        row(roster[activeIndex], index: activeIndex)
                    } else {
                        EmptyNote("Nobody.")
                    }
                }

                StationCard(title: "Around the fire — \(waiting.count)", icon: "flame.fill") {
                    if waiting.isEmpty {
                        EmptyNote("Nobody else, yet. People are out in the worlds: read a diary, write the world it describes, and walk up to whoever is standing in it.")
                    } else {
                        ForEach(waiting, id: \.index) { entry in
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
            if index == activeIndex {
                Text("with you")
                    .font(.caption2.weight(.medium)).foregroundStyle(.green)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(Color.green.opacity(0.14), in: Capsule())
            } else {
                Button("Take them") { store.setActiveCompanion(index) }
                    .font(.caption2.weight(.medium))
                    .buttonStyle(.bordered)
            }
        }
        .frame(minHeight: 44)
    }
}
