import SwiftUI

/// What the world will be, shown *before* you pay for it — pillar 5.
///
/// Every number here comes from `BookRules`, the same functions the bind itself runs, so the
/// preview cannot drift from what you actually get. Where a slot is left to chance, the number
/// becomes a range rather than a guess — except the price, which is exact either way.
/// The split is deliberate: **the price is certain, the world is not.**
struct PreviewPanel: View {
    let projection: BookProjection
    /// Drives the silhouette treatment: creatures you've never met show as a question mark.
    let discovery: DiscoveryLog

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            // Prose first, numbers after: what the world *is* should be the thing you read, and
            // it's the half a hint page can be matched against.
            if !projection.worldDescription.isEmpty {
                WorldDescriptionPanel(
                    description: projection.worldDescription,
                    contradictionEscalation: ContradictionRules.escalation(
                        count: projection.worldDescription.contradictions.count),
                    chains: projection.chains
                )
                .padding(-10)
            }
            stabilityBlock
            if projection.worldDescription.analysisTier >= Tuning.Analysis.attributionTier {
                stabilityBreakdown
            }
            if projection.dangerCapShortfall > 0, projection.worldDescription.showsAttribution {
                Text("Danger runes can only buy so much time: −\(projection.dangerCapShortfall) of what they offer.")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if projection.saysNothing {
                // **This world would be entirely chance.** The panel is otherwise indistinguishable
                // from a real projection — full stability, a plausible description, a harvest mix —
                // because every unwritten target is random-filled. Saying so is the difference
                // between a preview and a lie.
                Label(projection.isWrittenButSilent
                        ? "Nothing on the page is joined, so none of it counts. This world is all chance."
                        : "Nothing written yet. This world would be all chance.",
                      systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Divider()
            }
            Divider()
            statsRow
            if let clockBand = projection.clockBand {
                Label("World clock: \(clockBand)", systemImage: "clock.arrow.circlepath")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Divider()
            harvestSection
            lifeSection
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    private var header: some View {
        HStack {
            Label("Projection", systemImage: "eye")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
            // **Ranges come from the subjects you didn't write about**, which are rolled at bind.
            // This counted *slots* left to chance, and slots stopped existing when the page grid
            // replaced them — so it read "fully specified" over a book with one word on it.
            if !projection.isFullySpecified {
                let rolled = projection.unwrittenSubjects.count
                Text("ranges — \(rolled) subject\(rolled == 1 ? "" : "s") to chance")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: Stability

    private var stabilityBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text("Stability")
                    .font(.subheadline.weight(.semibold))
                Text(scoreText)
                    .font(.title3.monospacedDigit().weight(.bold))
                    .foregroundStyle(scoreColor)
                Spacer()
                Text(holdText)
                    .font(.caption)
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

    private var stabilityBreakdown: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Why stability moved")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            breakdownRow("What you asked of the world", projection.greedStabilityDelta)
            breakdownRow("Contradictions", -projection.contradictionPenalty)
            breakdownRow("World size", projection.sizeStabilityDelta)
            breakdownRow("Danger accepted", projection.dangerStabilityDelta)
        }
        .padding(10)
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
        .accessibilityIdentifier("projection.stability-breakdown")
    }

    private func breakdownRow(_ label: String, _ value: Int) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value > 0 ? "+\(value)" : "\(value)")
                .monospacedDigit()
                .foregroundStyle(value < 0 ? Color.red : (value > 0 ? Color.green : Color.secondary))
        }
        .font(.caption)
    }

    private var scoreText: String {
        let range = projection.stabilityScore
        return range.isPoint ? "\(range.lowerBound)" : "\(range.lowerBound)–\(range.upperBound)"
    }

    private var holdText: String {
        let turns = projection.turnsUntilCollapse
        // `indefiniteTurns` is a sentinel, not a count. Printing it gave the player "holds ~9999
        // turns", which reads as a bug rather than as a world that will outlast them.
        if turns.lowerBound >= Tuning.World.countdownCeiling { return "holds indefinitely" }
        if turns.upperBound >= Tuning.World.indefiniteTurns {
            return "holds ~\(turns.lowerBound) turns, perhaps indefinitely"
        }
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
            StatCell(label: "Sight", value: sightText, icon: "eye")
            StatCell(label: "Danger", value: tierText, icon: "exclamationmark.triangle")
            StatCell(label: "Cost", value: costText, icon: "drop")
        }
    }

    /// Stability is often bought with sight — showing one without the other tells half the story.
    private var sightText: String {
        let sight = projection.visionRadius
        return sight.isPoint ? "\(sight.lowerBound) tiles" : "\(sight.lowerBound)–\(sight.upperBound)"
    }

    private var tierText: String {
        let tier = projection.enemyTier
        return tier.isPoint ? "tier \(tier.lowerBound)" : "tier \(tier.lowerBound)–\(tier.upperBound)"
    }

    /// Always exact, even when everything else on this panel is a range — a slot left to chance
    /// costs a flat rate whatever rolls into it.
    private var costText: String { "\(projection.cost)" }

    // MARK: Mixes

    private struct MixEntry: Identifiable {
        var id: String
        var name: String
        var icon: String
        var share: Double
        /// Unknown entries render as a silhouette — you have to meet it to learn what it is.
        var isKnown: Bool
    }

    /// **Only what you asked for.**
    ///
    /// A resource is driven by a subject and gated on conditions; if you wrote nothing about those
    /// subjects, the world decides and the panel has no business estimating it (Aimee, 6 Aug). What
    /// remains is an honest estimate for the pressures you actually wrote.
    private var resourceEntries: [MixEntry] {
        projection.resourceMix
            .filter { entry in
                let subjects = Set([entry.resource.drivenBy].compactMap { $0 }
                                   + entry.resource.requires.map(\.target))
                return subjects.isEmpty || !subjects.isDisjoint(with: projection.writtenSubjects)
            }
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

    /// **What will live here**, in words rather than as a bar chart of silhouettes.
    ///
    /// A world's animals are grown from its pressures, so there is no roster to list — and a list
    /// of percentages against "Unknown" told the player nothing anyway. This says how many kinds of
    /// thing the world will hold and what they will tend to be like, which is a claim the preview is
    /// allowed to make because it comes off what was *written*, not off the seed.
    /// Says what you'd get from what you wrote, or says plainly that you wrote nothing about it.
    @ViewBuilder
    private var harvestSection: some View {
        if resourceEntries.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text("Expected harvest")
                    .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                Text("You haven't written anything that decides what's here. Whatever the world has, it chose.")
                    .font(.callout).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            mixSection(title: "Expected harvest", entries: resourceEntries)
        }
    }

    @ViewBuilder
    private var lifeSection: some View {
        if !projection.canDescribeLife {
            VStack(alignment: .leading, spacing: 4) {
                Text("Life")
                    .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                Text("You've said nothing about what lives here, so it isn't yours to know yet.")
                    .font(.callout).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            writtenLifeSection
        }
    }

    private var writtenLifeSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Life")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            // **What grows comes first, because everything else stands on it.** A world that can
            // make no living at all holds no herbivores and therefore no predators, and reading
            // "nothing grows here" above "nothing lives here" is the causal order the flora system
            // put into the world (`flora-system-spec.md` §7).
            Text(projection.flora.sentence)
                .font(.footnote)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(projection.life.sentence)
                .font(.footnote)
                .frame(maxWidth: .infinity, alignment: .leading)
            if projection.worldDescription.analysisTier >= Tuning.Analysis.livingTier,
               !projection.livingAnalysis.isEmpty {
                Divider().padding(.vertical, 3)
                LivingAnalysisView(analysis: projection.livingAnalysis)
            }
        }
    }

    @ViewBuilder
    private func mixSection(title: String, entries: [MixEntry]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
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
        VStack(spacing: 2) {
            Image(systemName: icon).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.footnote.weight(.medium).monospacedDigit())
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
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .frame(width: 20)
                .foregroundStyle(isKnown ? Color.primary : Color.secondary.opacity(0.5))

            Text(name)
                .font(.caption)
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
    // **Written on a page**, like everything else. This was the last thing in the codebase holding
    // the old slot-and-draft path alive — a SwiftUI preview building a two-slot book nobody could
    // write (`fossil-audit.md` §5). Its one genuinely good idea, modelling what unwritten subjects
    // could do to the stability band, moved to the page path before the rest of it went.
    let page = ["caverns", "rich_ore"].reduce(into: Page()) { page, id in
        guard let symbol = ContentCatalog.shared.symbol(SymbolID(rawValue: id)),
              let placed = PageRules.placeAnywhere(symbol, hand: .refined, on: page)
        else { return }
        page = placed
    }
    return ScrollView {
        PreviewPanel(
            projection: BookProjection.project(page: page, seed: 20_260_805),
            discovery: DiscoveryLog(creatures: ["paper_moth": DiscoveryRecord(firstSeenRunIndex: 1, timesEncountered: 2)])
        )
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
