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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var opened: VisitedWorld?
    @State private var comparison: WorldComparisonPair?
    @State private var compareMode = false
    @State private var selected: [InstanceID] = []
    @State private var query = ""
    @State private var filter: WorldHistoryFilter = .all
    @State private var newestFirst = true

    private var allWorlds: [VisitedWorld] {
        store.state.reality.library.visitedWorlds
    }

    private var worlds: [VisitedWorld] {
        let all = allWorlds.filter { world in
            let filterMatch = switch filter {
            case .all: true
            case .kept: world.isKept
            case .chanceLed: world.semanticRequests.isEmpty
            }
            let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
            let searchMatch = trimmed.isEmpty
                || "world \(world.runIndex)".localizedCaseInsensitiveContains(trimmed)
                || world.travellersPresent.compactMap(ContentCatalog.shared.traveller)
                    .contains { $0.name.localizedCaseInsensitiveContains(trimmed) }
            return filterMatch && searchMatch
        }
        return all.sorted { newestFirst ? $0.runIndex > $1.runIndex : $0.runIndex < $1.runIndex }
    }

    private var columns: [GridItem] {
        dynamicTypeSize.isAccessibilitySize
            ? [GridItem(.flexible())]
            : [GridItem(.flexible(), spacing: 12), GridItem(.flexible())]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if allWorlds.isEmpty {
                    ContentUnavailableView("No recorded worlds", systemImage: "clock.arrow.circlepath",
                                           description: Text("Every world you bind is recorded here."))
                        .frame(maxWidth: .infinity, minHeight: 280)
                } else {
                    browseControls
                    Text(readingNote)
                        .font(.caption).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    if worlds.isEmpty {
                        ContentUnavailableView.search(text: query)
                            .frame(maxWidth: .infinity, minHeight: 220)
                    } else {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(worlds) { world in
                                WorldCoverTile(world: world,
                                               selectionOrder: selected.firstIndex(of: world.id).map { $0 + 1 },
                                               compareMode: compareMode,
                                               open: { activate(world) },
                                               toggleKept: { store.keepWorld(world.id, kept: !world.isKept) })
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Worlds you've written")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query, prompt: "World number or known traveller")
        .safeAreaInset(edge: .bottom) {
            if compareMode { comparisonFooter }
        }
        .sheet(item: $opened) { world in
            VisitedWorldSheet(world: world).environmentObject(store)
        }
        .sheet(item: $comparison) { pair in
            WorldComparisonSheet(origin: pair.earlier, partner: pair.later).environmentObject(store)
        }
        .onAppear {
            guard selected.isEmpty, let pair = tutorialComparisonWorlds else { return }
            selected = [pair.0.id, pair.1.id]
        }
        .onChange(of: worlds.map(\.id)) { _, visibleIDs in
            selected.removeAll { !visibleIDs.contains($0) }
        }
    }

    private var browseControls: some View {
        VStack(spacing: 10) {
            Picker("World filter", selection: $filter) {
                ForEach(WorldHistoryFilter.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            HStack {
                Button {
                    newestFirst.toggle()
                } label: {
                    Label(newestFirst ? "Newest" : "Oldest",
                          systemImage: newestFirst ? "arrow.down" : "arrow.up")
                        .frame(minHeight: 44)
                }
                .buttonStyle(.bordered)
                Spacer()
                if compareMode {
                    Button {
                        compareMode = false
                        selected.removeAll()
                    } label: {
                        Label("Done comparing", systemImage: "rectangle.split.2x1")
                            .frame(minHeight: 44)
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button {
                        compareMode = true
                    } label: {
                        Label("Compare", systemImage: "rectangle.split.2x1")
                            .frame(minHeight: 44)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    private var comparisonFooter: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(selected.count) of 2 selected").font(.headline)
                Text(comparisonSelectionDetail).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button("Compare") { openComparison() }
                .buttonStyle(.borderedProminent)
                .frame(minHeight: 44)
                .disabled(selected.count != 2)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(.bar)
    }

    private var selectedWorldNames: String {
        selected.compactMap { id in
            store.state.reality.library.visitedWorlds.first { $0.id == id }.map { "World \($0.runIndex)" }
        }.joined(separator: " + ")
    }

    private var comparisonSelectionDetail: String {
        switch selected.count {
        case 0: "Choose two worlds"
        case 1: "\(selectedWorldNames) · choose one more"
        default: selectedWorldNames
        }
    }

    private func activate(_ world: VisitedWorld) {
        guard compareMode else { opened = world; return }
        if let index = selected.firstIndex(of: world.id) {
            selected.remove(at: index)
        } else if selected.count < 2 {
            selected.append(world.id)
        }
    }

    private func openComparison() {
        guard selected.count == 2 else { return }
        let records = selected.compactMap { id in
            store.state.reality.library.visitedWorlds.first { $0.id == id }
        }.sorted { $0.runIndex < $1.runIndex }
        guard records.count == 2 else { selected.removeAll(); return }
        comparison = WorldComparisonPair(earlier: records[0], later: records[1])
        store.openedWorldComparison()
    }

    private var tutorialComparisonWorlds: (VisitedWorld, VisitedWorld)? {
        guard let pair = store.state.tutorial.comparisonPair,
              let first = store.state.reality.library.visitedWorlds.first(where: { $0.id == pair.originID }),
              let second = store.state.reality.library.visitedWorlds.first(where: { $0.id == pair.partnerID })
        else { return nil }
        return (first, second)
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

}

private enum WorldHistoryFilter: String, CaseIterable, Identifiable {
    case all, kept, chanceLed
    var id: String { rawValue }
    var title: String { switch self { case .all: "All"; case .kept: "Kept"; case .chanceLed: "Chance-led" } }
}

private struct WorldComparisonPair: Identifiable {
    let earlier: VisitedWorld
    let later: VisitedWorld
    var id: String { "\(earlier.id)-\(later.id)" }
}

private struct WorldCoverTile: View {
    let world: VisitedWorld
    let selectionOrder: Int?
    let compareMode: Bool
    let open: () -> Void
    let toggleKept: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: open) {
                VStack(alignment: .leading, spacing: 9) {
                    HStack {
                        FrozenWorldCoverMark(world: world)
                        Spacer()
                    }
                    Text("World \(world.runIndex)").font(.headline)
                    HStack(spacing: 5) {
                        if world.semanticRequests.isEmpty {
                            Label("Chance-led", systemImage: "circle.dotted")
                        } else {
                            ForEach(Array(world.semanticRequests.prefix(2).enumerated()), id: \.offset) { _, request in
                                Text(request.components(separatedBy: " ← ").first ?? request)
                                    .lineLimit(1)
                            }
                            if world.semanticRequests.count > 2 { Text("+\(world.semanticRequests.count - 2)") }
                        }
                    }
                    .font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
                    if !world.travellersPresent.isEmpty {
                        Label("Traveller recorded", systemImage: "figure.wave")
                            .font(.caption2).foregroundStyle(.green)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
                .padding(12)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(selectionOrder == nil ? Color.clear : Color.accentColor, lineWidth: 3)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityHint(compareMode ? "Selects this record for comparison" : "Opens world record")

            if let selectionOrder {
                Text("\(selectionOrder)")
                    .font(.caption.bold()).foregroundStyle(.white)
                    .frame(width: 26, height: 26).background(Color.accentColor, in: Circle())
                    .padding(8).accessibilityHidden(true)
            } else if !compareMode {
                Button(action: toggleKept) {
                    Image(systemName: world.isKept ? "bookmark.fill" : "bookmark")
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel(world.isKept ? "Stop keeping World \(world.runIndex)" : "Keep World \(world.runIndex)")
            }
        }
    }

    private var accessibilityLabel: String {
        var values = ["World \(world.runIndex)", world.isKept ? "Kept" : "Ordinary"]
        values.append(world.semanticRequests.isEmpty ? "Chance-led" : "\(world.semanticRequests.count) authored requests")
        if let selectionOrder { values.append("Selected \(selectionOrder) of 2") }
        return values.joined(separator: ", ")
    }
}

/// Disclosure-neutral placeholder until the persisted world visual receipt has a dedicated,
/// versioned History-cover presentation adapter. It intentionally does not reinterpret that
/// receipt through the current renderer.
private struct FrozenWorldCoverMark: View {
    let world: VisitedWorld
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8).fill(Color(.tertiarySystemFill))
            Image(systemName: world.semanticRequests.isEmpty ? "circle.dotted" : "globe")
                .foregroundStyle(.secondary)
        }
        .frame(width: 48, height: 48)
        .accessibilityHidden(true)
    }
}

struct WorldComparisonSheet: View {
    static let noAuthoredRequestsText = "Nothing was written in this record."

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
        let authoredChanges = changes(for: world, against: other, isLater: isLater)
        return VStack(alignment: .leading, spacing: 10) {
            Text("\(role) · World \(world.runIndex)").font(.headline)
            Text(world.descriptionSentence).font(.caption)
            Divider()
            Text("What you wrote").font(.caption.weight(.semibold))
            if authoredChanges.isEmpty {
                Text(Self.noAuthoredRequestsText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(authoredChanges, id: \.key) { change in
                    Label(change.line, systemImage: change.icon)
                        .font(.caption)
                        .foregroundStyle(change.kind == "Unchanged" ? .secondary : .primary)
                        .accessibilityLabel("\(change.kind): \(change.line)")
                }
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
                                isLater: Bool) -> [(key: String, line: String, kind: String, icon: String)] {
        func keyed(_ lines: [String]) -> [String: String] {
            Dictionary(lines.map { ($0.components(separatedBy: " ← ").first ?? $0, $0) },
                       uniquingKeysWith: { _, new in new })
        }
        let mine = keyed(world.semanticRequests), theirs = keyed(other.semanticRequests)
        let earlier = isLater ? theirs : mine
        let later = isLater ? mine : theirs
        return Set(earlier.keys).union(later.keys).sorted().map { key in
            let line = mine[key] ?? "Not written"
            if earlier[key] == later[key] { return (key, line, "Unchanged", "equal.circle") }
            if earlier[key] == nil { return (key, line, "Added", "plus.circle") }
            if later[key] == nil { return (key, line, "Removed", "minus.circle") }
            return (key, line, "Changed", "arrow.triangle.2.circlepath")
        }
    }

    private func changes(for world: VisitedWorld, against other: VisitedWorld,
                         isLater: Bool) -> [(key: String, line: String, kind: String, icon: String)] {
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
    @State private var confirmingErase = false

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
                        Text("Reference distribution from \(LivingAnalysisRules.sampleCount) deterministic generated samples using the same trait budgets that grew this world's species.")
                    }
                }

                if !world.travellersPresent.isEmpty {
                    Section {
                        ForEach(world.travellersPresent, id: \.self) { id in
                            if let person = ContentCatalog.shared.traveller(id) {
                                HStack(spacing: 10) {
                                    NamedCharacterPixelIdentity(
                                        travellerID: id,
                                        fallbackSystemIcon: "figure.wave",
                                        fallbackColor: .green
                                    )
                                    .frame(width: 28, height: 28)
                                    Text(person.name)
                                    Spacer(minLength: 8)
                                    Text(store.state.reality.library.foundTravellers.contains(id)
                                         ? LibraryPresentation.placementLabel(for: person, in: store.state)
                                         : "Still there")
                                        .foregroundStyle(.secondary)
                                }
                                .frame(minHeight: 44)
                            }
                        }
                    } header: {
                        Text("Who was here")
                    }
                }

            }
            .safeAreaInset(edge: .bottom, spacing: 0) { historyActionBar }
            .navigationTitle("World \(world.runIndex)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
            }
            .alert("Erase World \(world.runIndex)?", isPresented: $confirmingErase) {
                Button("Cancel", role: .cancel) {}
                Button("Erase World \(world.runIndex)", role: .destructive) {
                    store.forgetWorld(world.id)
                    dismiss()
                }
            } message: {
                Text("This removes this world from History. It cannot be undone; other world records will not change.")
            }
        }
    }

    private var historyActionBar: some View {
        PersistentActionBar(message: "Kept worlds are never dropped when the history fills up.") {
            HStack(spacing: 10) {
                Button {
                    store.keepWorld(world.id, kept: !world.isKept)
                    dismiss()
                } label: {
                    Label(world.isKept ? "Stop keeping" : "Keep",
                          systemImage: world.isKept ? "bookmark.slash" : "bookmark")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.bordered)

                Button(role: .destructive) {
                    confirmingErase = true
                } label: {
                    Label("Erase", systemImage: "trash")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.bordered)
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
