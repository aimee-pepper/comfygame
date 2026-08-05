import SwiftUI

/// The world: stability at the top, the grid in the middle, your hands at the bottom.
///
/// Ergonomics note. A 14×14 grid can't give every tile a 44pt target on a 402pt-wide phone — that
/// would need a 616pt screen. So the grid is a *map*, not a control surface: tapping a tile is the
/// planning gesture (walk there), while the primary one-handed control is the D-pad in the thumb
/// zone, which the brief offers for exactly this reason. Every button is ≥44pt.
struct WorldView: View {
    @EnvironmentObject private var store: GameStore

    private var run: WorldRun? { store.state.worlds.activeRun }

    var body: some View {
        VStack(spacing: 0) {
            if let run {
                StabilityHeader(run: run)
                ScrollView {
                    VStack(spacing: 12) {
                        MapGrid(run: run) { point in
                            tapped(point, in: run)
                        }
                        eventLog
                        satchel(run)
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                }
                if let encounter = run.activeEncounter {
                    EncounterBar(run: run, encounter: encounter)
                } else {
                    controls(run)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
    }

    /// Tap an adjacent tile to step; tap anywhere else to walk there turn by turn.
    private func tapped(_ point: GridPoint, in run: WorldRun) {
        if WorldRules.isAdjacent(run.playerPosition, point) {
            store.step(to: point)
        } else {
            store.travel(to: point)
        }
    }

    // MARK: Narration

    /// Only the events worth saying out loud. Several — moving, the encounter opening — are better
    /// shown than narrated, so the log stays quiet rather than rendering an empty box.
    private var narratedEvents: [(line: String, colour: Color)] {
        store.recentEvents.compactMap { event in
            narrate(event).map { (line: $0, colour: colour(for: event)) }
        }
    }

    @ViewBuilder
    private var eventLog: some View {
        let lines = narratedEvents
        if !lines.isEmpty {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(Array(lines.enumerated()), id: \.offset) { _, entry in
                    Text(entry.line)
                        .font(.caption)
                        .foregroundStyle(entry.colour)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
        }
    }

    private func narrate(_ event: WorldRules.Event) -> String? {
        switch event {
        case .moved: nil // the map already says where you are
        case .blocked(let why): why
        case .pickedUp(let resource, let amount):
            "Picked up \(amount) \(ContentCatalog.shared.resource(resource)?.name.lowercased() ?? "something")."
        case .harvested(let resource, let amount, let exhausted):
            "Harvested \(amount) \(ContentCatalog.shared.resource(resource)?.name.lowercased() ?? "something")."
                + (exhausted ? " The node is spent." : "")
        case .foundPortal: "A way out."
        case .foundCache: "A cache, locked. The key is somewhere else."
        case .hazardHit(let damage): "The ground turns on you — \(damage) damage."
        case .enemySighted(let creature):
            "\(ContentCatalog.shared.creature(creature)?.name ?? "Something") has noticed you."
        case .encounterBegan: nil // the encounter bar takes over
        case .crossedThreshold(let band):
            switch band {
            case .stable: nil
            case .hazardous: "The edges are starting to go."
            case .crumbling: "The world is crumbling inward."
            case .collapsed: "It's over."
            }
        case .tilesCrumbled(let count): count > 0 ? "\(count) tiles gone." : nil
        case .lostToCrumbling(let count):
            count == 1 ? "Something you hadn't taken went with it." : "\(count) things you hadn't taken went with it."
        case .collapsed: "The world collapses."
        case .ejected(let reason): reason
        }
    }

    private func colour(for event: WorldRules.Event) -> Color {
        switch event {
        case .pickedUp, .harvested, .foundPortal: .primary
        case .hazardHit, .collapsed, .ejected, .lostToCrumbling: .red
        case .enemySighted, .crossedThreshold, .blocked: .orange
        default: .secondary
        }
    }

    // MARK: Satchel

    private func satchel(_ run: WorldRun) -> some View {
        HStack(spacing: 14) {
            Label("\(run.binderHP)", systemImage: "heart.fill")
                .foregroundStyle(run.binderHP <= Tuning.Encounter.binderMaxHP / 3 ? .red : .primary)
            if run.satchel.isEmpty {
                Text("satchel empty").foregroundStyle(.secondary)
            } else {
                ForEach(run.satchel.nonZero, id: \.id) { entry in
                    Label("\(entry.amount)", systemImage: ContentCatalog.shared.resource(entry.id)?.icon ?? "cube")
                }
            }
            Spacer()
            Text("turn \(run.turnsTaken)").foregroundStyle(.secondary)
        }
        .font(.footnote.monospacedDigit())
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: Controls — thumb zone

    private func controls(_ run: WorldRun) -> some View {
        HStack(alignment: .bottom, spacing: 14) {
            DirectionPad { direction in
                store.step(to: GridPoint(x: run.playerPosition.x + direction.dx,
                                         y: run.playerPosition.y + direction.dy))
            }

            VStack(spacing: 8) {
                if let node = store.harvestableHere {
                    ActionButton("Harvest \(ContentCatalog.shared.resource(node.resource)?.name ?? "")",
                                 icon: "cube.fill",
                                 detail: "\(node.remainingHarvests) left",
                                 isProminent: true) {
                        store.harvest()
                    }
                }
                if store.canPortalHere {
                    ActionButton("Portal home", icon: "arrow.down.left.circle.fill",
                                 detail: "keep everything", isProminent: true) {
                        store.portalHome()
                    }
                }
                if store.isOnLockedCache {
                    ActionButton("Locked cache", icon: "lock.fill",
                                 detail: store.carriedCacheKey == nil ? "needs a key from elsewhere" : "you have a key",
                                 isEnabled: false) {}
                }
                if store.harvestableHere == nil && !store.canPortalHere && !store.isOnLockedCache {
                    Text(hint(for: run))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(minHeight: 44)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .background(.bar)
    }

    private func hint(for run: WorldRun) -> String {
        switch run.stabilityBand {
        case .stable: "Tap a tile to walk there."
        case .hazardous: "Hazards are forming at the edges."
        case .crumbling: "The world is falling in. Find a portal."
        case .collapsed: "Gone."
        }
    }
}

// MARK: - Header

private struct StabilityHeader: View {
    let run: WorldRun

    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(Int(run.stability.rounded()))")
                    .font(.title2.weight(.bold).monospacedDigit())
                    .foregroundStyle(colour)
                Text(bandText)
                    .font(.footnote)
                    .foregroundStyle(colour)
                Spacer()
                Text("~\(turnsLeft) turns left")
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.tertiarySystemFill))
                    Capsule().fill(colour)
                        .frame(width: proxy.size.width * (run.stability / Tuning.World.startingStability))
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private var turnsLeft: Int {
        Int((run.stability / BookRules.decayPerTurn(for: run.book)).rounded(.down))
    }

    private var bandText: String {
        switch run.stabilityBand {
        case .stable: "holding"
        case .hazardous: "hazards at the edges"
        case .crumbling: "crumbling inward"
        case .collapsed: "collapsing"
        }
    }

    private var colour: Color {
        switch run.stabilityBand {
        case .stable: .green
        case .hazardous: .yellow
        case .crumbling: .orange
        case .collapsed: .red
        }
    }
}

// MARK: - Grid

private struct MapGrid: View {
    let run: WorldRun
    let onTap: (GridPoint) -> Void

    var body: some View {
        GeometryReader { proxy in
            let side = proxy.size.width / CGFloat(run.map.width)
            VStack(spacing: 0) {
                ForEach(0..<run.map.height, id: \.self) { y in
                    HStack(spacing: 0) {
                        ForEach(0..<run.map.width, id: \.self) { x in
                            let point = GridPoint(x: x, y: y)
                            TileView(tile: run.map[point],
                                     enemy: enemy(at: point),
                                     isPlayer: point == run.playerPosition,
                                     side: side)
                                .onTapGesture { onTap(point) }
                        }
                    }
                }
            }
        }
        .aspectRatio(CGFloat(run.map.width) / CGFloat(run.map.height), contentMode: .fit)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
    }

    private func enemy(at point: GridPoint) -> WorldEnemy? {
        run.enemies.first { $0.position == point }
    }
}

private struct TileView: View {
    let tile: Tile
    let enemy: WorldEnemy?
    let isPlayer: Bool
    let side: CGFloat

    var body: some View {
        ZStack {
            Rectangle()
                .fill(background)
                .overlay(Rectangle().stroke(Color(.systemBackground).opacity(0.6), lineWidth: 0.5))
            // The player gets a filled disc behind them: at 27pt a bare glyph disappears into the
            // grid, and "where am I" has to be answerable at a glance.
            if isPlayer {
                Circle()
                    .fill(Color.accentColor)
                    .padding(side * 0.14)
            }
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: side * (isPlayer ? 0.46 : 0.54), weight: isPlayer ? .bold : .regular))
                    .foregroundStyle(tint)
            }
        }
        .frame(width: side, height: side)
        .contentShape(Rectangle())
    }

    private var symbol: String? {
        if isPlayer { return "figure.stand" }
        guard tile.isRevealed, !tile.isCrumbled else { return nil }
        if let enemy { return ContentCatalog.shared.creature(enemy.creatureID)?.icon ?? "questionmark" }
        switch tile.content {
        case .empty: return nil
        case .node(let node): return ContentCatalog.shared.resource(node.resource)?.icon ?? "cube"
        case .wildDrop: return "sparkle"
        case .hazard: return "exclamationmark.triangle.fill"
        case .portal(let isEntry): return isEntry ? "arrow.down.left.circle" : "circle.circle"
        case .lockedCache: return "lock.fill"
        }
    }

    private var tint: Color {
        if isPlayer { return Color(.systemBackground) }
        if enemy != nil { return .red }
        switch tile.content {
        case .hazard: return .orange
        case .portal: return .blue
        case .lockedCache: return .purple
        case .wildDrop: return .teal
        default: return .primary.opacity(0.7)
        }
    }

    /// Three clearly distinct states, in both light and dark: floor you've seen, fog you haven't,
    /// and holes where the world has already gone.
    private var background: Color {
        if tile.isCrumbled { return .primary.opacity(0.55) }
        if !tile.isRevealed { return .primary.opacity(0.16) }
        return Color(.systemBackground)
    }
}

// MARK: - Controls

private enum Direction: CaseIterable {
    case up, right, down, left

    var dx: Int { switch self { case .left: -1; case .right: 1; default: 0 } }
    var dy: Int { switch self { case .up: -1; case .down: 1; default: 0 } }
    var icon: String {
        switch self {
        case .up: "chevron.up"
        case .right: "chevron.right"
        case .down: "chevron.down"
        case .left: "chevron.left"
        }
    }
}

/// The one-handed movement control. Optional in the brief; here it's the primary one, because a
/// 14×14 grid of 27pt tiles can't be.
private struct DirectionPad: View {
    let onStep: (Direction) -> Void

    var body: some View {
        VStack(spacing: 4) {
            padButton(.up)
            HStack(spacing: 4) {
                padButton(.left)
                Color.clear.frame(width: 46, height: 46)
                padButton(.right)
            }
            padButton(.down)
        }
    }

    private func padButton(_ direction: Direction) -> some View {
        Button { onStep(direction) } label: {
            Image(systemName: direction.icon)
                .font(.headline)
                .frame(width: 46, height: 46) // ≥44pt
        }
        .buttonStyle(.bordered)
        .accessibilityLabel(String(describing: direction))
    }
}

private struct ActionButton: View {
    let title: String
    let icon: String
    var detail: String?
    var isProminent: Bool = false
    var isEnabled: Bool = true
    let action: () -> Void

    init(_ title: String, icon: String, detail: String? = nil,
         isProminent: Bool = false, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.detail = detail
        self.isProminent = isProminent
        self.isEnabled = isEnabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).font(.callout.weight(.medium)).lineLimit(1).minimumScaleFactor(0.75)
                    if let detail {
                        Text(detail).font(.caption2).foregroundStyle(.secondary)
                            .lineLimit(1).minimumScaleFactor(0.75)
                    }
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 48)
            .padding(.horizontal, 10)
        }
        .buttonStyle(.bordered)
        .tint(isProminent ? .accentColor : .secondary)
        .disabled(!isEnabled)
    }
}

/// Placeholder combat bar. Milestone 4 replaces this with the real encounter screen.
private struct EncounterBar: View {
    @EnvironmentObject private var store: GameStore
    let run: WorldRun
    let encounter: EncounterState

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                ForEach(encounter.foes) { foe in
                    VStack(spacing: 2) {
                        Image(systemName: ContentCatalog.shared.creature(foe.creatureID)?.icon ?? "questionmark")
                            .foregroundStyle(foe.currentHP > 0 ? .red : .secondary)
                        Text("\(foe.currentHP)/\(foe.maxHP)").font(.caption2.monospacedDigit())
                    }
                    .frame(minWidth: 44, minHeight: 44)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text("round \(encounter.roundNumber)")
                        .font(.caption.monospacedDigit())
                    if let last = encounter.log.last {
                        Text(last).font(.caption2).lineLimit(1)
                    }
                }
                .foregroundStyle(.secondary)
            }
            Button {
                store.harnessEncounterRound()
            } label: {
                Label("Fight one round", systemImage: "burst.fill")
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 48)
            }
            .buttonStyle(.borderedProminent)
            Text("Placeholder combat — the real encounter screen is milestone 4.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.bar)
    }
}

#Preview {
    WorldView().environmentObject(GameStore(io: .temporary(name: "preview-world")))
}
