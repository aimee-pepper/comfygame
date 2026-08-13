import SwiftUI

struct RecyclerView: View {
    @EnvironmentObject private var store: GameStore
    @State private var selected: RecyclerPreview?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Select one eligible piece to see exactly what Noll can recover. Nothing is dismantled until you confirm.")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                if previews.isEmpty {
                    EmptyNote("No eligible ordinary gear is stored or waiting. Favorites, locked pieces, unique work and unrecorded provenance stay protected.")
                } else {
                    SixAcrossItemGrid(data: previews, id: \.stackID) { preview in
                        Button { selected = preview } label: {
                            ItemIconTile(icon: preview.snapshot.icon,
                                         catalogueID: preview.snapshot.catalogID,
                                         rarity: preview.snapshot.rarity,
                                         quantity: 1,
                                         identified: preview.snapshot.identified,
                                         location: preview.location == .stored ? .stored : .waiting,
                                         accessibilityName: preview.snapshot.displayName)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if !ineligibilityCounts.isEmpty {
                    DisclosureGroup("Why other holdings are protected") {
                        ForEach(ineligibilityCounts, id: \.reason.rawValue) { row in
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(row.count) · \(row.reason.explanation)")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 3)
                        }
                    }
                    .font(.callout)
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Recycler")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selected) { preview in
            RecyclerPreviewSheet(preview: preview).environmentObject(store)
        }
    }

    private var previews: [RecyclerPreview] { store.recyclerPreviews() }

    private var ineligibilityCounts: [(reason: RecyclerRules.Ineligibility, count: Int)] {
        var counts: [RecyclerRules.Ineligibility: Int] = [:]
        for stack in store.state.base.inventory.stacks + store.state.base.spillover {
            if let reason = RecyclerRules.ineligibility(of: stack) { counts[reason, default: 0] += 1 }
        }
        counts[.equipped, default: 0] += store.state.base.binderEquipped.count
        counts[.equipped, default: 0] += store.state.base.roster.reduce(0) { $0 + $1.equipped.count }
        return counts.filter { $0.value > 0 }
            .map { (reason: $0.key, count: $0.value) }
            .sorted { $0.reason.rawValue < $1.reason.rawValue }
    }
}

private struct RecyclerPreviewSheet: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss
    let preview: RecyclerPreview
    @State private var failure: RecyclerCommitResult?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent("Piece", value: preview.snapshot.displayName)
                    LabeledContent("Location", value: preview.location == .stored ? "Stored" : "Waiting")
                    LabeledContent("Recovery route", value: routeName)
                }
                Section("Recovered") {
                    ForEach(preview.returnedResources.nonZero, id: \.id) { entry in
                        LabeledContent(ContentCatalog.shared.resource(entry.id)?.name ?? entry.id.rawValue,
                                       value: "\(entry.amount)")
                    }
                    ForEach(Array(preview.returnedSamples.enumerated()), id: \.offset) { _, sample in
                        LabeledContent(sample.displayName, value: sample.grade.formatted(.number.precision(.fractionLength(0))))
                    }
                    if preview.returnedResources.nonZero.isEmpty && preview.returnedSamples.isEmpty {
                        Text("No recoverable output.").foregroundStyle(.secondary)
                    }
                }
                if let failure {
                    Section { Text(message(for: failure)).foregroundStyle(.red) }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) { dismantleActionBar }
            .navigationTitle("Recovery preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
    }

    private var dismantleActionBar: some View {
        PersistentActionBar(
            message: "The selected piece is consumed only by a successful atomic recovery."
        ) {
            Button(role: .destructive) {
                let result = store.recycle(preview)
                if result == .committed { dismiss() } else { failure = result }
            } label: {
                Text("Dismantle this piece").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.red)
        }
    }

    private var routeName: String {
        switch preview.route {
        case .constructionReceipt: "Recorded construction receipt"
        case .authoredSalvage: "Authored salvage profile"
        }
    }

    private func message(for result: RecyclerCommitResult) -> String {
        switch result {
        case .committed: "Recovered."
        case .stale: "Your stores changed. Close this preview and select the piece again."
        case .invalid: "This piece is no longer eligible for recovery."
        }
    }
}

extension RecyclerPreview: Identifiable {
    var id: String { "\(location.rawValue)-\(stackID.rawValue)-\(revision)" }
}
