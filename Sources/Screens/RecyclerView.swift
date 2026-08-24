import SwiftUI

enum RecyclerPresentation {
    static let proprietorID: TravellerID = "noll"

    static func resourceName(_ id: ResourceID,
                             catalogue: ContentCatalog = .shared) -> String {
        catalogue.resource(id)?.name ?? "Unknown resource"
    }

    static func recoveredResourceSummary(_ entries: [(id: ResourceID, amount: Int)],
                                         catalogue: ContentCatalog = .shared) -> String {
        entries.map { entry in
            "\(resourceName(entry.id, catalogue: catalogue)) ×\(entry.amount)"
        }.joined(separator: " · ")
    }
}

struct RecyclerView: View {
    @EnvironmentObject private var store: GameStore
    @State private var selected: RecyclerPreview?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                proprietorHeader

                Text("Select one eligible piece to see exactly what Noll can recover. Nothing is dismantled until you confirm.")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                if previews.isEmpty {
                    recyclerEmptyState
#if DEBUG
                        .background { P3SafeSpaceProbe("recycler.main.empty", identity: "no-eligible-gear") }
#endif
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
#if DEBUG
                        .background {
                            if preview.stackID == previews.first?.stackID {
                                P3SafeSpaceProbe("recycler.main.first",
                                                 identity: String(preview.stackID.rawValue))
                            }
                            if preview.stackID == previews.last?.stackID {
                                P3SafeSpaceProbe("recycler.main.last",
                                                 identity: String(preview.stackID.rawValue))
                            }
                        }
#endif
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
#if DEBUG
                    .background {
                        P3SafeSpaceProbe("recycler.main.protected",
                            identity: ineligibilityCounts.map(\.reason.rawValue).joined(separator: ","))
                    }
#endif
                }
            }
            .padding(16)
        }
#if DEBUG
        .background { P3SafeSpaceProbe("recycler.main.scroll") }
#endif
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Recycler")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selected) { preview in
            RecyclerPreviewSheet(preview: preview)
                .environmentObject(store)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private var previews: [RecyclerPreview] { store.recyclerPreviews() }

    private var proprietorHeader: some View {
        let person = ContentCatalog.shared.traveller(RecyclerPresentation.proprietorID)
        return HStack(spacing: 12) {
            NamedCharacterPixelIdentity(
                travellerID: person?.id,
                fallbackSystemIcon: person?.icon ?? "arrow.3.trianglepath",
                fallbackColor: .orange
            )
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 2) {
                Text(person?.name ?? "Recycler")
                    .font(.headline)
                Text(person?.calling ?? "Salvager")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var recyclerEmptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("No gear to dismantle", systemImage: "shippingbox")
                .font(.headline)

            Text("Store or recover an eligible standard piece of gear, then return here to preview what Noll can salvage.")
                .font(.callout)

            Divider()

            Label("Favorites, locked pieces, one-of-a-kind gear, and gear without recorded construction stock or standard salvage stay protected.",
                  systemImage: "lock.shield")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.secondary.opacity(0.18), lineWidth: 1)
        }
    }

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

#if DEBUG
    init(preview: RecyclerPreview, debugFailure: RecyclerCommitResult? = nil) {
        self.preview = preview
        _failure = State(initialValue: debugFailure)
    }
#endif

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 12) {
                        ItemIconTile(icon: preview.snapshot.icon,
                                     catalogueID: preview.snapshot.catalogID,
                                     rarity: preview.snapshot.rarity,
                                     quantity: 1,
                                     identified: preview.snapshot.identified,
                                     location: preview.location == .stored ? .stored : .waiting,
                                     accessibilityName: preview.snapshot.displayName)
                            .frame(width: 52, height: 52)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(preview.snapshot.displayName).font(.headline)
                            Text(preview.location == .stored ? "Stored" : "Waiting")
                                .font(.caption).foregroundStyle(.secondary)
                            Text(routeName).font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                    }
                }
                Section("Recovered") {
                    if !preview.returnedResources.nonZero.isEmpty {
                        Text(RecyclerPresentation.recoveredResourceSummary(
                            preview.returnedResources.nonZero
                        ))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                        SixAcrossItemGrid(data: preview.returnedResources.nonZero, id: \.id) { entry in
                            let definition = ContentCatalog.shared.resource(entry.id)
                            ResourceIconTile(resourceID: entry.id,
                                             icon: definition?.icon ?? "shippingbox",
                                             quantity: entry.amount,
                                             accessibilityName: RecyclerPresentation.resourceName(entry.id))
                        }
                        .padding(.vertical, 4)
#if DEBUG
                        .background {
                            if preview.returnedSamples.isEmpty,
                               let last = preview.returnedResources.nonZero.last {
                                P3SafeSpaceProbe("recycler.preview.final", identity: last.id.rawValue)
                            }
                        }
#endif
                    }
#if DEBUG
                    ForEach(Array(preview.returnedSamples.enumerated()), id: \.offset) { index, sample in
                        LabeledContent(sample.displayName, value: sample.grade.formatted(.number.precision(.fractionLength(0))))
                            .background {
                                if index == preview.returnedSamples.indices.last {
                                    P3SafeSpaceProbe("recycler.preview.final", identity: sample.displayName)
                                }
                            }
                    }
#else
                    ForEach(Array(preview.returnedSamples.enumerated()), id: \.offset) { _, sample in
                        LabeledContent(sample.displayName, value: sample.grade.formatted(.number.precision(.fractionLength(0))))
                    }
#endif
                    if preview.returnedResources.nonZero.isEmpty && preview.returnedSamples.isEmpty {
                        Text("No recoverable output.").foregroundStyle(.secondary)
#if DEBUG
                            .background { P3SafeSpaceProbe("recycler.preview.final", identity: "no-output") }
#endif
                    }
                }
            }
#if DEBUG
            .background { P3SafeSpaceProbe("recycler.preview.list") }
#endif
            .safeAreaInset(edge: .bottom, spacing: 0) { dismantleActionBar }
            .navigationTitle("Recovery preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
    }

    private var dismantleActionBar: some View {
        PersistentActionBar(
            message: failure.map(message(for:))
                ?? "The selected piece is consumed only after recovery succeeds.",
            messageTint: failure == nil ? .secondary : .red
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
            .disabled(failure != nil)
        }
#if DEBUG
        .background {
            P3SafeSpaceProbe("recycler.preview.action",
                             identity: failure.map(message(for:)) ?? "ready")
        }
#endif
    }

    private var routeName: String {
        switch preview.route {
        case .constructionReceipt: "Returns recorded construction stock"
        case .authoredSalvage: "Returns standard salvage"
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

#if DEBUG
struct P3RecyclerPreviewDebugHost: View {
    let preview: RecyclerPreview
    let failure: RecyclerCommitResult?
    var body: some View { RecyclerPreviewSheet(preview: preview, debugFailure: failure) }
}
#endif

extension RecyclerPreview: Identifiable {
    var id: String { "\(location.rawValue)-\(stackID.rawValue)-\(revision)" }
}
