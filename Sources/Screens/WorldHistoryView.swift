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
    @State private var comparing = false

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
                    if comparisonWorlds != nil {
                        Button {
                            comparing = true
                            store.openedWorldComparison()
                        } label: {
                            Label(comparisonTitle, systemImage: "rectangle.split.2x1")
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }
                        .buttonStyle(.borderedProminent)
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
        .sheet(isPresented: $comparing) {
            if let pair = comparisonWorlds {
                WorldComparisonSheet(origin: pair.0, partner: pair.1).environmentObject(store)
            }
        }
    }

    private var comparisonWorlds: (VisitedWorld, VisitedWorld)? {
        guard let pair = store.state.tutorial.comparisonPair,
              let first = store.state.reality.library.visitedWorlds.first(where: { $0.id == pair.originID }),
              let second = store.state.reality.library.visitedWorlds.first(where: { $0.id == pair.partnerID })
        else { return nil }
        return (first, second)
    }

    private var comparisonTitle: String {
        store.state.tutorial.comparisonPair?.isOneChangeExercise == true
            ? "Read the two records together" : "Compare these pages"
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
            "You can trace the effects you have learned to measure, including what the world decided for itself."
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

struct WorldComparisonSheet: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss
    let origin: VisitedWorld
    let partner: VisitedWorld

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    Text("Unwritten subjects and other chance may differ between worlds.")
                        .font(.callout).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .top, spacing: 10) {
                            column(origin, other: partner, role: "Earlier", isLater: false)
                            column(partner, other: origin, role: "Later", isLater: true)
                        }
                        VStack(spacing: 10) {
                            column(origin, other: partner, role: "Earlier", isLater: false)
                            column(partner, other: origin, role: "Later", isLater: true)
                        }
                    }
                }.padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("World comparison")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
        }
    }

    private func column(_ world: VisitedWorld, other: VisitedWorld, role: String,
                        isLater: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(role) · World \(world.runIndex)").font(.headline)
            Text(world.descriptionSentence).font(.caption)
            Divider()
            Text("What you wrote").font(.caption.weight(.semibold))
            ForEach(changes(for: world, against: other, isLater: isLater), id: \.line) { change in
                Label(change.line, systemImage: change.icon)
                    .font(.caption)
                    .foregroundStyle(change.kind == "Unchanged" ? .secondary : .primary)
                    .accessibilityLabel("\(change.kind): \(change.line)")
            }
            if store.state.reality.analysisTier >= Tuning.Analysis.targetsTier {
                Divider()
                Text("Measured").font(.caption.weight(.semibold))
                ForEach(measured(world), id: \.name) { entry in
                    VStack(alignment: .leading, spacing: 1) {
                        Text(entry.name).font(.caption2).foregroundStyle(.secondary)
                        Text(entry.value).font(.caption.monospacedDigit())
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(10).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    static func labelledChanges(for world: VisitedWorld, against other: VisitedWorld,
                                isLater: Bool) -> [(line: String, kind: String, icon: String)] {
        func keyed(_ lines: [String]) -> [String: String] {
            Dictionary(lines.map { ($0.components(separatedBy: " ← ").first ?? $0, $0) },
                       uniquingKeysWith: { _, new in new })
        }
        let mine = keyed(world.semanticRequests), theirs = keyed(other.semanticRequests)
        return mine.keys.sorted().map { key in
            let line = mine[key]!
            if theirs[key] == line { return (line, "Unchanged", "equal.circle") }
            if theirs[key] == nil {
                return isLater ? (line, "Added", "plus.circle") : (line, "Removed", "minus.circle")
            }
            return (line, "Replaced", "arrow.triangle.2.circlepath")
        }
    }

    private func changes(for world: VisitedWorld, against other: VisitedWorld,
                         isLater: Bool) -> [(line: String, kind: String, icon: String)] {
        Self.labelledChanges(for: world, against: other, isLater: isLater)
    }

    private func measured(_ world: VisitedWorld) -> [(name: String, value: String)] {
        ContentCatalog.shared.pressureTargetsInOrder.compactMap { target in
            guard store.state.reality.measures(target.id),
                  let snapshot = world.readings[target.id.rawValue] else { return nil }
            let precision = store.state.reality.observations[target.id]?.bestPrecision ?? .crude
            return (target.name, WorldDescription.Reading.text(peak: snapshot.peak, floor: snapshot.floor,
                                                               hasFloor: target.dualValued,
                                                               precision: precision))
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
                    if !world.inertModifiers.isEmpty {
                        Text("Said nothing: \(world.inertModifiers.joined(separator: ", ")).")
                            .foregroundStyle(.orange)
                    }
                }

                if tier >= Tuning.Analysis.targetsTier && !readings.isEmpty {
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
                        EmptyNote(tier < Tuning.Analysis.targetsTier
                            ? "The numbers underneath are here, and you can't read them yet. Improve the page lens at the Scriptorium."
                            : "You never measured these subjects in the field. Survey a world to calibrate the lens.")
                            .frame(minHeight: 44)
                    } header: {
                        Text("What it came out as")
                    }
                }

                if tier >= Tuning.Analysis.sigilAttributionTier,
                   !focusAttributions.isEmpty {
                    Section {
                        ForEach(Array(focusAttributions.enumerated()), id: \.offset) { _, line in
                            Text(line).font(.caption.monospacedDigit())
                        }
                    } header: {
                        Text("What each focus did")
                    } footer: {
                        Text("Secondary effects are consequences of a focus beyond the subject it was joined to.")
                    }
                }

                if tier >= Tuning.Analysis.targetsTier,
                   store.state.reality.measures("cycle"),
                   let clock = world.clockAnalysis {
                    Section {
                        LabeledRow(icon: "clock.arrow.circlepath", label: "Clock", value: clock.band)
                        LabeledRow(icon: "metronome", label: "Base cycle",
                                   value: clock.isStopped ? "no transition" : "\(clock.basePeriod) turns")
                    } header: {
                        Text("World clock")
                    } footer: {
                        Text("Irregular worlds vary around the base cycle without reversing time.")
                    }
                }

                if tier >= Tuning.Analysis.livingTier,
                   let analysis = world.livingAnalysis, !analysis.isEmpty {
                    Section {
                        LivingAnalysisView(analysis: analysis)
                    } header: {
                        Text("Living analysis")
                    } footer: {
                        Text("Likely distributions, derived from the same trait budgets that grew this world's species.")
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
            guard store.state.reality.measures(target.id) else { return nil }
            guard let snapshot = world.readings[target.id.rawValue] else { return nil }
            let precision = store.state.reality.observations[target.id]?.bestPrecision ?? .crude
            let value = WorldDescription.Reading.text(peak: snapshot.peak, floor: snapshot.floor,
                                                      hasFloor: target.dualValued,
                                                      precision: precision)
            return (target.name, value, snapshot.wasWritten)
        }
    }

    private var focusAttributions: [String] {
        let measured = store.state.reality.calibratedSubjects
        if !world.focusEffects.isEmpty {
            return world.focusEffects
                .filter { measured.contains($0.targetID) }
                .map(\.line)
        }

        // Older saves only have display strings. Recover the affected subject from the exact
        // authored name after the arrow; ambiguous/unrecognised lines stay hidden rather than
        // bypassing calibration.
        return world.focusAttributions.filter { line in
            ContentCatalog.shared.pressureTargetsInOrder.contains { target in
                measured.contains(target.id) && line.contains("→ \(target.name) ")
            }
        }
    }
}
