import SwiftUI

/// What the world will be, shown *before* you pay for it — pillar 5.
///
/// Every number here comes from `BookRules`, the same functions the bind itself runs, so the
/// preview cannot drift from what you actually get. Where a slot is left to chance, the number
/// becomes a range rather than a guess.
struct PreviewPanel: View {
    let projection: BookProjection
    /// Drives the silhouette treatment: creatures you've never met show as a question mark.
    let discovery: DiscoveryLog

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            stabilityBlock
            Divider()
            statsRow
            Divider()
            mixSection(title: "Expected harvest", entries: resourceEntries)
            mixSection(title: "Expected inhabitants", entries: creatureEntries)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    private var header: some View {
        HStack {
            Label("Projection", systemImage: "eye")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
            if !projection.isFullySpecified {
                Text("ranges — \(projection.randomSlots.count) slot\(projection.randomSlots.count == 1 ? "" : "s") to chance")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: Stability

    private var stabilityBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text("Stability")
                    .font(.title3.weight(.semibold))
                Text(scoreText)
                    .font(.title3.monospacedDigit().weight(.bold))
                    .foregroundStyle(scoreColor)
                Spacer()
                Text(holdText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Bar shows the range: a solid fill to the worst case, a faded extension to the best.
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.tertiarySystemFill))
                    Capsule()
                        .fill(scoreColor.opacity(0.3))
                        .frame(width: proxy.size.width * fraction(projection.stabilityScore.upperBound))
                    Capsule()
                        .fill(scoreColor)
                        .frame(width: proxy.size.width * fraction(projection.stabilityScore.lowerBound))
                }
            }
            .frame(height: 10)
        }
    }

    private func fraction(_ score: Int) -> Double { Double(score) / 100.0 }

    private var scoreText: String {
        let range = projection.stabilityScore
        return range.isPoint ? "\(range.lowerBound)" : "\(range.lowerBound)–\(range.upperBound)"
    }

    private var holdText: String {
        let turns = projection.turnsUntilCollapse
        return turns.isPoint
            ? "holds ~\(turns.lowerBound) turns"
            : "holds ~\(turns.lowerBound)–\(turns.upperBound) turns"
    }

    private var scoreColor: Color {
        switch projection.stabilityScore.lowerBound {
        case 75...: .green
        case 50..<75: .yellow
        case 25..<50: .orange
        default: .red
        }
    }

    // MARK: Stats

    private var statsRow: some View {
        HStack(alignment: .top, spacing: 0) {
            StatCell(label: "Map", value: "\(projection.mapWidth)×\(projection.mapHeight)", icon: "square.grid.3x3")
            StatCell(label: "Danger", value: tierText, icon: "exclamationmark.triangle")
            StatCell(label: "Cost", value: costText, icon: "drop")
        }
    }

    private var tierText: String {
        let tier = projection.enemyTier
        return tier.isPoint ? "tier \(tier.lowerBound)" : "tier \(tier.lowerBound)–\(tier.upperBound)"
    }

    private var costText: String {
        let cost = projection.essenceCost
        return cost.isPoint ? "\(cost.lowerBound)" : "\(cost.lowerBound)–\(cost.upperBound)"
    }

    // MARK: Mixes

    private struct MixEntry: Identifiable {
        var id: String
        var name: String
        var icon: String
        var share: Double
        /// Unknown entries render as a silhouette — you have to meet it to learn what it is.
        var isKnown: Bool
    }

    private var resourceEntries: [MixEntry] {
        projection.resourceMix
            .filter { $0.share > 0.001 }
            .map { entry in
                // Resources are named on sight, so anything in the mix is legible immediately.
                MixEntry(id: entry.resource.id.rawValue,
                         name: entry.resource.name,
                         icon: entry.resource.icon,
                         share: entry.share,
                         isKnown: true)
            }
    }

    private var creatureEntries: [MixEntry] {
        projection.creatureMix
            .filter { $0.share > 0.001 }
            .map { entry in
                let known = discovery.hasEncountered(creature: entry.creature.id)
                return MixEntry(id: entry.creature.id.rawValue,
                                name: known ? entry.creature.name : "Unknown",
                                icon: known ? entry.creature.icon : "questionmark",
                                share: entry.share,
                                isKnown: known)
            }
    }

    @ViewBuilder
    private func mixSection(title: String, entries: [MixEntry]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            if entries.isEmpty {
                Text("Nothing — this book describes an empty place.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(entries) { entry in
                    MixBar(name: entry.name,
                           icon: entry.icon,
                           share: entry.share,
                           isKnown: entry.isKnown)
                }
            }
        }
    }
}

private struct StatCell: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: icon).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.subheadline.weight(.medium).monospacedDigit())
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct MixBar: View {
    let name: String
    let icon: String
    let share: Double
    let isKnown: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.footnote)
                .frame(width: 20)
                .foregroundStyle(isKnown ? Color.primary : Color.secondary.opacity(0.5))

            Text(name)
                .font(.footnote)
                .foregroundStyle(isKnown ? .primary : .secondary)
                .frame(width: 96, alignment: .leading)
                .lineLimit(1)

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.tertiarySystemFill))
                    Capsule()
                        .fill(isKnown ? Color.accentColor : Color.secondary.opacity(0.4))
                        .frame(width: max(2, proxy.size.width * share))
                }
            }
            .frame(height: 7)

            Text("\(Int((share * 100).rounded()))%")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 34, alignment: .trailing)
        }
        .frame(minHeight: 22)
    }
}

#Preview {
    ScrollView {
        PreviewPanel(
            projection: BookProjection.project(
                draft: BookDraft(slots: [.terrain: "caverns", .bounty: "rich_ore"]),
                ownedSymbols: Set(ContentCatalog.shared.starterSymbolIDs)
            ),
            discovery: DiscoveryLog(creatures: ["paper_moth": DiscoveryRecord(firstSeenRunIndex: 1, timesEncountered: 2)])
        )
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
