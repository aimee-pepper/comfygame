import SwiftUI

/// The tier-5 lens readout shared by the Desk and World History.
struct LivingAnalysisView: View {
    let analysis: LivingAnalysis

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Generated estimate · \(LivingAnalysisRules.sampleCount) deterministic samples")
                .font(.caption)
                .foregroundStyle(.secondary)
            group("Creature traits", icon: "pawprint.fill", lines: analysis.creatureTraits)
            group("Sampled ecological roles", icon: "point.3.connected.trianglepath.dotted",
                  lines: analysis.ecologicalRoles)
            group("Flora traits", icon: "leaf.fill", lines: analysis.floraTraits)
        }
        .accessibilityIdentifier("living-analysis")
    }

    @ViewBuilder
    private func group(_ title: String, icon: String, lines: [String]) -> some View {
        if !lines.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Label(title, systemImage: icon)
                    .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                ForEach(lines, id: \.self) { line in
                    Text(line).font(.caption.monospacedDigit())
                }
            }
        }
    }
}
