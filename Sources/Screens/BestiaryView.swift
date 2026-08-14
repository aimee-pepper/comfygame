import SwiftUI

/// **What you've met.**
///
/// The bestiary has been recorded since session 3 and never had a screen: species, specimens, trait
/// vectors, derived identities and a personal percentile all went into the save and none of it could
/// be looked at. The Library holds *people*; this holds everything else out there.
///
/// Session 3 §4a asks for **personal and global percentiles, both shown**, and the pair is the whole
/// point — personal carries the early game (*the largest of four you've seen*) and global is what
/// keeps a late find meaningful once your own distribution has drifted (*largest as they come*).
struct BestiaryView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var opened: BestiaryRules.Entry?

    private var entries: [BestiaryRules.Entry] {
        BestiaryRules.entries(in: store.state.reality.discovery)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if entries.isEmpty {
                    StationCard(title: "Nothing yet", icon: "pawprint") {
                        EmptyNote("Everything you meet out there is written up here — what it was, and how the one you met compared.")
                    }
                } else {
                    HStack {
                        Label("Kinds met", systemImage: "pawprint.fill").font(.headline)
                        Spacer()
                        Text("\(entries.count)").font(.headline.monospacedDigit()).foregroundStyle(.secondary)
                    }
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(entries) { entry in
                            Button { opened = entry } label: { tile(entry) }
                                .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("The Bestiary")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $opened) { entry in
            EntrySheet(entry: entry).environmentObject(store)
        }
    }

    private var columns: [GridItem] {
        dynamicTypeSize.isAccessibilitySize
            ? [GridItem(.flexible())]
            : [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    }

    private func tile(_ entry: BestiaryRules.Entry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            CreaturePixelIdentity(traits: entry.latest?.traits,
                                  fallbackSystemIcon: entry.icon)
                .foregroundStyle(.tint)
                .frame(width: 40, height: 40)
            VStack(alignment: .leading, spacing: 1) {
                Text(entry.name.capitalisedSentence).font(.callout.weight(.medium))
                if entry.isApexSpecies {
                    Label("Apex encountered", systemImage: "crown.fill")
                        .font(.caption2.weight(.semibold)).foregroundStyle(.orange)
                }
                Text(entry.timesEncountered == 1
                     ? "met once"
                     : "met \(entry.timesEncountered) times · \(entry.specimens.count) recorded")
                    .font(.caption2).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption2).foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 160, alignment: .topLeading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
        .contentShape(RoundedRectangle(cornerRadius: 14))
    }
}

/// One kind, and the individuals recorded when it was encountered.
private struct EntrySheet: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss
    let entry: BestiaryRules.Entry

    private var discovery: DiscoveryLog { store.state.reality.discovery }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    if entry.isApexSpecies {
                        StationCard(title: "Apex sightings — \(entry.apexSightings)", icon: "crown.fill") {
                            Text("You have met a version of this species that its world could not afford.")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    if let latest = entry.latest {
                        StationCard(title: "Latest record", icon: "star.fill") {
                            measures(of: latest)
                        }
                    }

                    StationCard(title: "Encounter records — \(entry.specimens.count)", icon: "list.bullet") {
                        if entry.specimens.isEmpty {
                            EmptyNote("You have met this kind, but no individual measurements were recorded.")
                        }
                        ForEach(Array(entry.specimens.enumerated().reversed()), id: \.offset) { item in
                            HStack {
                                CreaturePixelIdentity(traits: item.element.traits,
                                                      fallbackSystemIcon: "pawprint")
                                    .frame(width: 40, height: 40)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(CreatureIdentity.name(for: item.element.traits).capitalisedSentence)
                                        .font(.caption)
                                    Text("World \(item.element.runIndex)")
                                        .font(.caption2).foregroundStyle(.secondary)
                                }
                            }
                            .frame(minHeight: 32)
                        }
                    }
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(entry.name.capitalisedSentence)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
        }
    }

    /// **Both percentiles, side by side**, which is what session 3 asked for and why one of them
    /// alone would be misleading in opposite directions at opposite ends of the game.
    @ViewBuilder
    private func measures(of specimen: SpecimenRecord) -> some View {
        let peers = BestiaryRules.peerCount(of: specimen, in: discovery)
        ForEach(BestiaryRules.Measure.allCases) { measure in
            let personal = BestiaryRules.personalPercentile(of: specimen, by: measure, in: discovery)
            let global = BestiaryRules.globalPercentile(of: specimen.traits, by: measure)
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(measure.displayName).font(.caption.weight(.medium))
                    Spacer(minLength: 6)
                    if let remark = BestiaryRules.remark(personal: personal, peers: peers,
                                                         global: global, measure: measure) {
                        Text(remark).font(.caption2).foregroundStyle(.orange)
                    }
                }
                HStack(spacing: 12) {
                    bar("of \(peers) seen", personal, enabled: peers > 1)
                    bar("in generated reference sample", global, enabled: true)
                }
            }
            .frame(minHeight: 44)
        }
    }

    private func bar(_ label: String, _ value: Double, enabled: Bool) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.tertiarySystemFill))
                    Capsule()
                        .fill(enabled ? Color.accentColor : Color.secondary.opacity(0.4))
                        .frame(width: max(2, proxy.size.width * (enabled ? value : 0)))
                }
            }
            .frame(height: 5)
            Text(enabled ? "\(Int(value * 100))% \(label)" : "only one seen")
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
