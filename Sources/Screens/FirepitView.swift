import SwiftUI

/// Where the people you brought home are.
///
/// **The one building that isn't found first** (Aimee, 6 Aug). Every other station comes from
/// meeting somebody who'd run it — but you need somewhere to put the first person before anyone can
/// build anything, so the firepit is simply here, from the start, built by nobody.
///
/// It exists because recruiting somebody used to be two writes to the Library and nothing else.
/// Aimee found a companion, lost a run, and had *"no idea what happened to her."* She had never
/// been lost — `foundTravellers` lives in Reality and nothing takes it — but there was nowhere she
/// visibly *was*, which feels exactly the same as losing her.
struct FirepitView: View {
    @EnvironmentObject private var store: GameStore

    private var roster: [CompanionState] { store.state.base.roster }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                StationCard(title: "Around the fire", icon: "flame.fill") {
                    Text(roster.count == 1
                         ? "Just the two of you, so far. People are found out in the worlds — write the one somebody is standing in, and walk up to them."
                         : "\(roster.count) of you, and room for \(Tuning.Party.maximumSize - roster.count) more.")
                        .font(.caption).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                ForEach(Array(roster.enumerated()), id: \.offset) { index, member in
                    personCard(member, index: index)
                }

                ComingLater("All five of you will fight together. For now one comes along, and the rest keep the fire in.")
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("The Firepit")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func personCard(_ member: CompanionState, index: Int) -> some View {
        let isActive = index == store.state.base.activeCompanion
        return StationCard(title: member.name, icon: member.icon) {
            if !member.calling.isEmpty {
                Text(member.calling.capitalisedSentence)
                    .font(.caption).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            LabeledRow(icon: "chart.bar", label: "Level", value: "\(member.character.level)")
            LabeledRow(icon: "heart.fill", label: "Health", value: "\(member.maxHP)")
            LabeledRow(icon: member.character.rank == .front ? "shield.lefthalf.filled" : "figure.stand",
                       label: member.character.rank.displayName,
                       value: member.character.rank.blurb)

            // Ranks, changed here rather than mid-fight — the same rule gambits follow.
            Picker("Where they stand", selection: Binding(
                get: { member.character.rank },
                set: { store.setRank($0, forMemberAt: index) }
            )) {
                ForEach(Rank.allCases, id: \.self) { Text($0.displayName).tag($0) }
            }
            .pickerStyle(.segmented)
            .frame(minHeight: 44)

            if isActive {
                Text("Coming with you.")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.green)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(minHeight: 44)
            } else {
                Button("Take them instead") { store.setActiveCompanion(index) }
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .buttonStyle(.bordered)
            }
        }
    }
}
