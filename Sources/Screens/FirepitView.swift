import SwiftUI

struct FirepitPlacementPresentation: Equatable {
    let icon: String
    let label: String

    init(_ placement: RosterPlacement) {
        switch placement {
        case .activeParty:
            icon = "figure.walk.circle.fill"
            label = "Coming with you"
        case .home:
            icon = "house.circle"
            label = "At Home"
        case .anchoredRealm(_, let name):
            icon = "map.circle.fill"
            label = "Posted at \(name)"
        }
    }
}

enum FirepitLayoutRules {
    static func ordinaryColumnCount(entryCount: Int) -> Int {
        entryCount <= 1 ? 1 : 2
    }
}

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
    private var coming: [(id: PersistentPartyMemberID, member: CompanionState)] {
        roster.enumerated().compactMap { index, member in
            guard let id = store.state.base.persistentID(forRosterIndex: index), store.isComing(id) else { return nil }
            return (id, member)
        }
    }
    private var home: [(id: PersistentPartyMemberID, member: CompanionState)] {
        roster.enumerated().compactMap { index, member in
            guard let id = store.state.base.persistentID(forRosterIndex: index), store.placement(of: id) == .home else { return nil }
            return (id, member)
        }
    }
    private var posted: [(id: PersistentPartyMemberID, member: CompanionState)] {
        roster.enumerated().compactMap { index, member in
            guard let id = store.state.base.persistentID(forRosterIndex: index),
                  case .anchoredRealm = store.placement(of: id) else { return nil }
            return (id, member)
        }
    }
    /// You count as one of the five, so four is as many as can come with you.
    private var seatsLeft: Int {
        max(0, Tuning.Party.maximumSize - 1 - store.state.base.activeParty.count)
    }
    private func columns(entryCount: Int) -> [GridItem] {
        let count = dynamicTypeSize.isAccessibilitySize
            ? 1
            : FirepitLayoutRules.ordinaryColumnCount(entryCount: entryCount)
        return Array(repeating: GridItem(.flexible(), spacing: 10), count: count)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                communitySection("Coming with you", icon: "figure.walk", entries: coming,
                                 empty: "Nobody but you.")
                if seatsLeft > 0 {
                    Text(seatsLeft == 1 ? "Room for one more." : "Room for \(seatsLeft) more.")
                        .font(.caption).foregroundStyle(.secondary)
                } else if !home.isEmpty || !posted.isEmpty {
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
                switch store.commitRosterPlacement(preview) {
                case .committed: return .committed
                case .refused(let refusal): return .refused(refusal.copy)
                }
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
                                  entries: [(id: PersistentPartyMemberID, member: CompanionState)],
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
            } else if let entry = entries.first, entries.count == 1 {
                singleMemberRow(entry.member, id: entry.id)
            } else {
                LazyVGrid(columns: columns(entryCount: entries.count), spacing: 10) {
                    ForEach(entries, id: \.id) { entry in
                        memberTile(entry.member, id: entry.id)
                    }
                }
            }
        }
    }

    private func singleMemberRow(_ member: CompanionState, id: PersistentPartyMemberID) -> some View {
        let placement = FirepitPlacementPresentation(store.placement(of: id))
        return HStack(spacing: 12) {
            NamedCharacterPixelIdentity(
                travellerID: member.traveller,
                fallbackSystemIcon: member.icon,
                fallbackColor: .orange
            )
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 3) {
                Text(member.name)
                    .font(.callout.weight(.semibold))
                    .lineLimit(1)
                Text(member.calling.isEmpty
                     ? "Level \(member.character.level)"
                     : "\(member.calling.capitalisedSentence) · level \(member.character.level)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Label(placement.label, systemImage: placement.icon)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 4)
            transferButton(id: id)
                .frame(minWidth: 96)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 14))
    }

    /// Location and departure choice only; detailed character management remains on Party.
    private func memberTile(_ member: CompanionState, id: PersistentPartyMemberID) -> some View {
        let placement = FirepitPlacementPresentation(store.placement(of: id))
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                NamedCharacterPixelIdentity(
                    travellerID: member.traveller,
                    fallbackSystemIcon: member.icon,
                    fallbackColor: .orange
                )
                .frame(width: 36, height: 36)
                Spacer()
                Image(systemName: placement.icon)
                    .foregroundStyle(.secondary)
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
            Label(placement.label, systemImage: placement.icon)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Spacer(minLength: 0)
            transferButton(id: id)
                .frame(maxWidth: .infinity)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: dynamicTypeSize.isAccessibilitySize ? 164 : 176,
               alignment: .topLeading)
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private func transferButton(id: PersistentPartyMemberID) -> some View {
        if store.isComing(id) {
            Button("Send Home") {
                switch store.rosterPlacementQuote(for: id, destination: .home) {
                case .success(let quote):
                    if case .refused(let refusal) = store.commitRosterPlacement(quote) {
                        transferRefusal = refusal.copy
                    }
                case .failure(let refusal): transferRefusal = refusal.copy
                }
            }
            .font(.caption.weight(.semibold))
            .buttonStyle(.bordered)
            .frame(minHeight: 44)
        } else {
            Button("Take them") {
                switch store.rosterPlacementQuote(for: id, destination: .activeParty) {
                case .success(let quote): pendingTransfer = quote
                case .failure(let refusal): transferRefusal = refusal.copy
                }
            }
                .font(.caption.weight(.semibold))
                .buttonStyle(.borderedProminent)
                .disabled(seatsLeft == 0)
                .frame(minHeight: 44)
        }
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
