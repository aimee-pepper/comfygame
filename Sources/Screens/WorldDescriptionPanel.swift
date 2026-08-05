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
/// 2. **It explains the instability.** Clauses arising from destabilising conditions are underlined
///    red, stabilising ones green, so *why* a world is fragile is legible in the same sentence that
///    says what it's like. Mystcraft's real failure was that you couldn't tell why; this is the fix.
///
/// Contradictions get their own named lines rather than being folded into a number.
struct WorldDescriptionPanel: View {
    let description: WorldDescription
    /// The disclosed superlinear stacking term (§3). Shown separately because hidden
    /// superlinearity is the failure mode — a player who can't see it can't reason about it.
    var contradictionEscalation: Int = 0

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

            if !description.contradictions.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(description.contradictions) { contradiction in
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
    private var sentence: AttributedString {
        var result = AttributedString()
        for (index, clause) in description.clauses.enumerated() {
            var run = AttributedString(clause.text)
            if let colour = underline(for: clause.polarity) {
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
