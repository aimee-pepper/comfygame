import SwiftUI

/// What the world is *like*, in prose, updating as you write.
///
/// This is the panel `decisions-session-6` (Q18) and `contradiction-danger-spec.md` §6 both ask
/// for, and it does two jobs at once:
///
/// 1. **It's the deduction surface.** A Library hint page says *"no shadow anywhere"*; this says
///    *"Blazing overhead, and nowhere to be out of it."* The player matches description to
///    description. That's why it never renders a condition list and never names a sigil or a value
///    — reading it has to be the same act as reading a diary page.
/// 2. **It explains the instability — but only once you can read that far.** The red/green
///    underlining and the named contradictions are **tier 4** on the analysis axis
///    (decisions-session-8), not a starting feature. Early on the panel describes and nothing more.
///
/// That split is the point. Working out what your own writing did to a world *is* the game, so
/// explanation is earned rather than front-loaded — while the description half, which is what a
/// clue gets matched against, works from the very first book.
struct WorldDescriptionPanel: View {
    let description: WorldDescription
    /// The disclosed superlinear stacking term (§3). Shown separately because hidden
    /// superlinearity is the failure mode — a player who can't see it can't reason about it.
    var contradictionEscalation: Int = 0
    /// **What you wrote to get this**, one line per joined cluster.
    ///
    /// The prose above is the deduction surface and never names a sigil, which is right — but on
    /// its own it made the panel an oracle. A wrong deduction taught nothing: you wrote *a giant
    /// sun*, the world came out dim, and there was nowhere to see that "giant" was a Scale rung
    /// doing nothing at all (Aimee, 6 Aug). Cause and effect belong on one screen.
    var chains: [WrittenChain] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("The world you are writing", systemImage: "text.alignleft")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(sentence)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityLabel(description.sentence)

            if !chains.isEmpty { written }

            if description.hasUnreadableWrongness {
                // Something is wrong and you can't yet tell what. Deliberately unattributed.
                Text("Something about this world does not sit right.")
                    .font(.callout.italic())
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !description.namedContradictions.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(description.namedContradictions) { contradiction in
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption2)
                                .foregroundStyle(.red)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(contradiction.name)
                                    .font(.callout.weight(.medium))
                                    .foregroundStyle(.red)
                                Text(contradiction.blurb)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    if contradictionEscalation > 0 {
                        Text("More than one at once, and they compound: a further −\(contradictionEscalation).")
                            .font(.caption)
                            .foregroundStyle(.red.opacity(0.9))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    /// One attributed string, so the sentence wraps as prose rather than as a stack of chips —
    /// the underline is a mark *on the writing*, not a badge beside it.
    /// The chains, as read-back lines. Deliberately plain — this is a readout, not a second
    /// description, and it has to look like the page rather than like prose.
    private var written: some View {
        VStack(alignment: .leading, spacing: 4) {
            Divider()
            Text("What you wrote")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            ForEach(chains) { chain in
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(chain.target)
                        .font(.caption.weight(.medium))
                    Image(systemName: "arrow.left")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    // An inert rung is struck through where it sits, so the mistake is visible in
                    // the phrase rather than in a note underneath it.
                    Text(phrase(for: chain))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func phrase(for chain: WrittenChain) -> AttributedString {
        var line = AttributedString()
        for (index, part) in chain.parts.enumerated() {
            if index > 0 { line += AttributedString(" · ") }
            for rung in part.qualifiers {
                var word = AttributedString(rung.name + " ")
                if rung.isInert {
                    word.strikethroughStyle = .single
                    word.foregroundColor = .orange
                }
                line += word
            }
            line += AttributedString(part.source)
        }
        return line
    }

    private var sentence: AttributedString {
        var result = AttributedString()
        for (index, clause) in description.clauses.enumerated() {
            var run = AttributedString(clause.text)
            if description.showsAttribution, let colour = underline(for: clause.polarity) {
                run.underlineStyle = Text.LineStyle(pattern: .solid, color: colour)
            }
            if index > 0 { result += AttributedString(" ") }
            result += run
        }
        return result
    }

    /// Neutral clauses are left unmarked on purpose: underlining everything would say nothing.
    private func underline(for polarity: DescriptionClauseDef.Polarity) -> Color? {
        switch polarity {
        case .destabilising: .red
        case .stabilising: .green
        case .neutral: nil
        }
    }
}

#Preview {
    let page = [
        Sigil(id: InstanceID(rawValue: 1), source: "sun", target: "illumination",
              intensity: .great, negatedTargets: ["thermal"]),
        Sigil(id: InstanceID(rawValue: 2), source: "glacier", target: "hydrology", intensity: .great),
        Sigil(id: InstanceID(rawValue: 3), source: "gold", target: "substrate", intensity: .great)
    ]
    let description = DescriptionRules.describe(page: page)
    return ScrollView {
        WorldDescriptionPanel(
            description: description,
            contradictionEscalation: ContradictionRules.escalation(count: description.contradictions.count)
        )
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
