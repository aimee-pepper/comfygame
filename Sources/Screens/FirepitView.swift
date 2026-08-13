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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var pendingTransfer: PartyTransferPreview?
    @State private var transferRefusal: String?

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
    private var columns: [GridItem] {
        dynamicTypeSize.isAccessibilitySize
            ? [GridItem(.flexible())]
            : [GridItem(.flexible(), spacing: 10), GridItem(.flexible())]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                communitySection("Coming with you", icon: "figure.walk", entries: coming,
                                 empty: "Nobody but you.")
                if seatsLeft > 0 {
                    Text(seatsLeft == 1 ? "Room for one more." : "Room for \(seatsLeft) more.")
                        .font(.caption).foregroundStyle(.secondary)
                } else if !home.isEmpty {
                    Text("Party full · send someone Home before taking another traveller.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                communitySection("At Home", icon: "flame.fill", entries: home,
                                 empty: "Nobody else, yet. Recovered writing can lead you to people in other worlds.")

                if !posted.isEmpty {
                    communitySection("Posted in realms", icon: "map.fill", entries: posted,
                                     empty: "Nobody is posted away from Home.")
                }

                if !store.state.base.canRecruit {
                    ComingLater("The fire is full — five is as many as you can keep.")
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("The Firepit")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $pendingTransfer) { preview in
            PartyTransferConfirmationSheet(preview: preview,
                                           message: transferMessage(preview)) {
                store.setComing(preview)
            }
        }
        .overlay(alignment: .bottom) {
            if let transferRefusal {
                HStack(spacing: 10) {
                    Text(transferRefusal).font(.callout).frame(maxWidth: .infinity, alignment: .leading)
                    Button("Dismiss") { self.transferRefusal = nil }
                }
                .padding(14)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                .padding(16)
                .accessibilityElement(children: .contain)
            }
        }
    }

    @ViewBuilder
    private func communitySection(_ title: String, icon: String,
                                  entries: [(index: Int, member: CompanionState)],
                                  empty: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("\(title) · \(entries.count)", systemImage: icon)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            if entries.isEmpty {
                Text(empty)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color(.secondarySystemGroupedBackground),
                                in: RoundedRectangle(cornerRadius: 14))
            } else {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(entries, id: \.index) { entry in
                        memberTile(entry.member, index: entry.index)
                    }
                }
            }
        }
    }

    /// Location and departure choice only; detailed character management remains on Party.
    private func memberTile(_ member: CompanionState, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                NamedCharacterPixelIdentity(
                    travellerID: member.traveller,
                    fallbackSystemIcon: member.icon,
                    fallbackColor: .orange
                )
                .frame(width: 36, height: 36)
                Spacer()
                Image(systemName: store.isComing(index) ? "figure.walk.circle.fill" : "house.circle")
                    .foregroundStyle(.secondary)
                    .accessibilityLabel(store.isComing(index) ? "Coming with you" : "At Home")
            }
            Text(member.name)
                .font(.callout.weight(.semibold))
                .lineLimit(1)
            Text(member.calling.isEmpty
                 ? "Level \(member.character.level)"
                 : "\(member.calling.capitalisedSentence) · level \(member.character.level)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            Spacer(minLength: 0)
            if store.isComing(index) {
                Button("Send Home") {
                    if case .refused(let message) = store.setComingHome(index) {
                        transferRefusal = message
                    }
                }
                    .font(.caption.weight(.semibold))
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity, minHeight: 44)
            } else {
                Button("Take them") { pendingTransfer = store.partyTransferPreview(for: index) }
                    .font(.caption.weight(.semibold))
                    .buttonStyle(.borderedProminent)
                    .disabled(seatsLeft == 0)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: dynamicTypeSize.isAccessibilitySize ? 164 : 176,
               alignment: .topLeading)
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .contain)
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

private struct PartyTransferConfirmationSheet: View {
    @Environment(\.dismiss) private var dismiss
    let preview: PartyTransferPreview
    let message: String
    let commit: () -> CurrentStateCommitResult
    @State private var refusal: String?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text(message)
                    .font(.callout)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let refusal {
                    Text(refusal)
                        .font(.callout)
                        .foregroundStyle(.red)
                        .accessibilityIdentifier("firepit.transfer-refusal")
                }
                Spacer(minLength: 0)
                Button("Take with you") {
                    switch commit() {
                    case .committed: dismiss()
                    case .refused(let message): refusal = message
                    }
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity, minHeight: 44)
            }
            .padding(16)
            .navigationTitle("Take \(preview.name) with you?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
