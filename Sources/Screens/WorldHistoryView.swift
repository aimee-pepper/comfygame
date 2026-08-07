import SwiftUI

/// Every world you've written and stood in — what you wrote, and what it became.
///
/// **This is the answer key, and it's delayed on purpose** (Aimee, 6 Aug). Nothing here explains a
/// mistake at the moment you make it; that would break the rule that explanation is earned. It
/// records the evidence and lets you come back once you've learned to read it. The world where Mara
/// wasn't becomes, later, the world where you can finally see that Atmosphere rolled ash and ate
/// your sunlight.
///
/// So what a row shows **grows with your analysis tier**, and that makes the instruments worth far
/// more than they look: they don't only help with the next world, they unlock every world you have
/// already written.
struct WorldHistoryView: View {
    @EnvironmentObject private var store: GameStore
    @State private var opened: VisitedWorld?

    private var worlds: [VisitedWorld] {
        store.state.reality.library.visitedWorlds.reversed()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if worlds.isEmpty {
                    StationCard(title: "Nowhere yet", icon: "clock.arrow.circlepath") {
                        EmptyNote("Every world you bind is recorded here — what you wrote, and what it turned out to be.")
                    }
                } else {
                    StationCard(title: "What it becomes", icon: "eye") {
                        Text(readingNote)
                            .font(.caption).foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    ForEach(worlds) { world in
                        Button { opened = world } label: { row(world) }
                            .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Worlds you've written")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $opened) { world in
            VisitedWorldSheet(world: world).environmentObject(store)
        }
    }

    /// Says what this screen can currently tell you, so the instruments have a visible reason to
    /// exist rather than being a number on a card somewhere.
    private var readingNote: String {
        switch store.state.reality.analysisTier {
        case ..<Tuning.Analysis.targetsTier:
            "You can read back what you wrote and what each world felt like. Better instruments will show you the numbers underneath, and which of them you never wrote at all."
        case ..<Tuning.Analysis.sigilAttributionTier:
            "You can read the numbers now. Attribution — which of your marks did what — comes later."
        default:
            "You can read all of it, including what the world decided for itself while you weren't looking."
        }
    }

    private func row(_ world: VisitedWorld) -> some View {
        StationCard(title: "World \(world.runIndex)",
                    icon: world.isKept ? "bookmark.fill" : "globe") {
            Text(world.descriptionSentence)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(Array(world.written.enumerated()), id: \.offset) { _, line in
                Text(line)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 8) {
                // **Who was standing in it** — the thing you were looking for, whether or not you
                // reached them. This is what makes the history a search tool and not a scrapbook.
                ForEach(world.travellersPresent, id: \.self) { id in
                    if let person = ContentCatalog.shared.traveller(id) {
                        Label(person.name, systemImage: "figure.wave")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.tertiary)
            }
            .frame(minHeight: 24)
        }
    }
}

/// One world, in as much detail as you can currently read.
private struct VisitedWorldSheet: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss
    let world: VisitedWorld

    private var tier: Int { store.state.reality.analysisTier }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(world.descriptionSentence)
                        .font(.callout)
                        .fixedSize(horizontal: false, vertical: true)
                } header: {
                    Text("What it was like")
                }

                Section {
                    if world.written.isEmpty {
                        EmptyNote("Nothing. This world was entirely chance.")
                    }
                    ForEach(Array(world.written.enumerated()), id: \.offset) { _, line in
                        Text(line).font(.callout)
                    }
                } header: {
                    Text("What you wrote")
                } footer: {
                    // **The one thing worth surfacing at any tier**, because it's a mistake in the
                    // writing rather than a fact about the world — you don't need an instrument to
                    // be told a word you wrote did nothing.
                    if !world.inertRungs.isEmpty {
                        Text("Said nothing: \(world.inertRungs.joined(separator: ", ")).")
                            .foregroundStyle(.orange)
                    }
                }

                if tier >= Tuning.Analysis.targetsTier {
                    Section {
                        ForEach(readings, id: \.name) { entry in
                            LabeledRow(icon: entry.wasWritten ? "pencil" : "dice",
                                       label: entry.name,
                                       value: entry.value,
                                       tint: entry.wasWritten ? nil : .orange)
                        }
                    } header: {
                        Text("What it came out as")
                    } footer: {
                        // The answer to "what rolled over me", which is the question a failed
                        // deduction actually has.
                        Text("A die means the world decided that one for itself — you wrote nothing about it.")
                    }
                } else {
                    Section {
                        EmptyNote("The numbers underneath are here, and you can't read them yet. Better instruments are studied at the Workshop.")
                            .frame(minHeight: 44)
                    } header: {
                        Text("What it came out as")
                    }
                }

                if !world.travellersPresent.isEmpty {
                    Section {
                        ForEach(world.travellersPresent, id: \.self) { id in
                            if let person = ContentCatalog.shared.traveller(id) {
                                LabeledRow(icon: "figure.wave", label: person.name,
                                           value: store.state.reality.library.foundTravellers.contains(id)
                                               ? "with you" : "still there",
                                           tint: .green)
                            }
                        }
                    } header: {
                        Text("Who was here")
                    }
                }

                Section {
                    Button {
                        store.keepWorld(world.id, kept: !world.isKept)
                        dismiss()
                    } label: {
                        Label(world.isKept ? "Stop keeping this" : "Keep this one",
                              systemImage: world.isKept ? "bookmark.slash" : "bookmark")
                            .frame(minHeight: 44)
                    }
                    Button(role: .destructive) {
                        store.forgetWorld(world.id)
                        dismiss()
                    } label: {
                        Label("Erase it", systemImage: "trash").frame(minHeight: 44)
                    }
                } footer: {
                    Text("Kept worlds are never dropped when the history fills up.")
                }
            }
            .navigationTitle("World \(world.runIndex)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
            }
        }
    }

    private var readings: [(name: String, value: String, wasWritten: Bool)] {
        ContentCatalog.shared.pressureTargetsInOrder.compactMap { target in
            guard let snapshot = world.readings[target.id.rawValue] else { return nil }
            let value = snapshot.peak == snapshot.floor
                ? "\(Int(snapshot.peak))"
                : "\(Int(snapshot.floor))–\(Int(snapshot.peak))"
            return (target.name, value, snapshot.wasWritten)
        }
    }
}
