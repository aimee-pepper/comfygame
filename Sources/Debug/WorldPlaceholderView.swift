import SwiftUI

/// Stand-in for the World screen until milestone 3 builds the tile grid.
///
/// It's the real run state — real book, real seed, real decay, real encounters — with buttons
/// where the map will be. Being in a run is a state rather than a navigation destination, so this
/// is what the app shows on launch if you force-quit mid-run.
struct WorldPlaceholderView: View {
    @EnvironmentObject private var store: GameStore

    private var run: WorldRun? { store.state.worlds.activeRun }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let run {
                    ScrollView {
                        VStack(spacing: 16) {
                            stabilityCard(run)
                            bookCard(run)
                            satchelCard(run)
                            if let encounter = run.activeEncounter {
                                encounterCard(run, encounter)
                            }
                            ComingLater("The 14×14 tile grid, fog of war, movement and harvesting arrive in milestone 3; the real encounter screen in milestone 4.")
                        }
                        .padding(16)
                    }
                    actionBar(run)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("World #\(run?.runIndex ?? 0)")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: Cards

    private func stabilityCard(_ run: WorldRun) -> some View {
        StationCard(title: "Stability", icon: "waveform.path.ecg") {
            HStack(alignment: .firstTextBaseline) {
                Text("\(Int(run.stability.rounded()))")
                    .font(.largeTitle.weight(.bold).monospacedDigit())
                    .foregroundStyle(color(for: run.stabilityBand))
                Text(bandText(run.stabilityBand))
                    .font(.subheadline)
                    .foregroundStyle(color(for: run.stabilityBand))
                Spacer()
                Text("turn \(run.turnsTaken)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.tertiarySystemFill))
                    Capsule()
                        .fill(color(for: run.stabilityBand))
                        .frame(width: proxy.size.width * (run.stability / Tuning.World.startingStability))
                }
            }
            .frame(height: 10)
            LabeledRow(icon: "arrow.down.right", label: "Decay per turn",
                       value: String(format: "%.1f", BookRules.decayPerTurn(for: run.book)))
            LabeledRow(icon: "hourglass", label: "Turns left",
                       value: "~\(Int((run.stability / BookRules.decayPerTurn(for: run.book)).rounded(.down)))")
        }
    }

    private func bookCard(_ run: WorldRun) -> some View {
        StationCard(title: "Bound from", icon: "book.closed") {
            ForEach(SymbolSlot.allCases, id: \.self) { slot in
                if let id = run.book.symbols[slot], let symbol = ContentCatalog.shared.symbol(id) {
                    LabeledRow(icon: symbol.icon,
                               label: symbol.name,
                               value: run.book.randomlyFilled.contains(slot) ? "by chance" : slot.displayName)
                }
            }
            LabeledRow(icon: "number", label: "Seed", value: String(run.mapSeed, radix: 16, uppercase: true))
        }
    }

    private func satchelCard(_ run: WorldRun) -> some View {
        StationCard(title: "Satchel — unbanked", icon: "bag") {
            if run.satchel.isEmpty {
                EmptyNote("Empty. Nothing to lose yet.")
            } else {
                ForEach(run.satchel.nonZero, id: \.id) { entry in
                    let resource = ContentCatalog.shared.resource(entry.id)
                    LabeledRow(icon: resource?.icon ?? "cube",
                               label: resource?.name ?? entry.id.rawValue,
                               value: "\(entry.amount)")
                }
            }
            LabeledRow(icon: "heart.fill", label: "Binder",
                       value: "\(run.binderHP) / \(Tuning.Encounter.binderMaxHP)")
        }
    }

    private func encounterCard(_ run: WorldRun, _ encounter: EncounterState) -> some View {
        StationCard(title: "In an encounter — round \(encounter.roundNumber)", icon: "burst.fill") {
            ForEach(encounter.foes) { foe in
                let creature = ContentCatalog.shared.creature(foe.creatureID)
                LabeledRow(icon: creature?.icon ?? "questionmark",
                           label: creature?.name ?? foe.creatureID.rawValue,
                           value: "\(foe.currentHP) / \(foe.maxHP)",
                           isDimmed: foe.currentHP == 0)
            }
            if let last = encounter.log.last {
                Text(last).font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    // MARK: Actions — thumb zone

    @ViewBuilder
    private func actionBar(_ run: WorldRun) -> some View {
        VStack(spacing: 8) {
            if run.activeEncounter != nil {
                WorldButton("Fight one round", icon: "burst.fill", isProminent: true) {
                    store.harnessEncounterRound()
                }
            } else {
                HStack(spacing: 8) {
                    WorldButton("Step", icon: "figure.walk") { store.harnessTakeWorldTurn() }
                    WorldButton("Harvest", icon: "cube.fill") { store.harnessHarvest() }
                    WorldButton("Bump", icon: "burst.fill") { store.harnessEnterEncounter() }
                }
                WorldButton("Portal home — keep everything", icon: "arrow.down.left.circle.fill", isProminent: true) {
                    store.harnessPortalHome()
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(.bar)
    }

    private func color(for band: StabilityBand) -> Color {
        switch band {
        case .stable: .green
        case .hazardous: .yellow
        case .crumbling: .orange
        case .collapsed: .red
        }
    }

    private func bandText(_ band: StabilityBand) -> String {
        switch band {
        case .stable: "holding"
        case .hazardous: "hazards forming"
        case .crumbling: "crumbling inward"
        case .collapsed: "collapsing"
        }
    }
}

private struct WorldButton: View {
    let title: String
    let icon: String
    var isProminent: Bool = false
    let action: () -> Void

    init(_ title: String, icon: String, isProminent: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isProminent = isProminent
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.callout.weight(.medium))
                .frame(maxWidth: .infinity)
                .frame(minHeight: isProminent ? 52 : 44)
        }
        .buttonStyle(isProminent ? AnyButtonStyle(.borderedProminent) : AnyButtonStyle(.bordered))
    }
}

/// Tiny eraser so one view can pick between two concrete button styles.
private struct AnyButtonStyle: PrimitiveButtonStyle {
    private let makeBody: (Configuration) -> AnyView

    init<S: PrimitiveButtonStyle>(_ style: S) {
        makeBody = { configuration in AnyView(style.makeBody(configuration: configuration)) }
    }

    func makeBody(configuration: Configuration) -> some View {
        makeBody(configuration)
    }
}

#Preview {
    WorldPlaceholderView()
        .environmentObject(GameStore(io: .temporary(name: "preview-world")))
}
