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
                        LootDecisionCard()
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
                controls(run)
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
        case .cacheOpened(let what): "The lock gives. \(what)"
        case .readPage(let id):
            ContentCatalog.shared.diaryPage(id).map { "A page, in somebody's hand. \"\($0.prose)\"" }
                ?? "A page from someone's diary."
        case .foundTraveller(let id):
            ContentCatalog.shared.traveller(id).map { "\($0.name) is here. \($0.blurb)" }
                ?? "Someone is here."
        case .nightfall: "The light goes. You can see less of this than you could."
        case .daybreak: "It comes back around. You can see again."
        case .foundSite(let site):
            ContentCatalog.shared.site(site).map { "\($0.name). \($0.blurb)" } ?? "Something built."
        case .searchedSite(_, let remaining):
            "Searching. \(remaining) more turn\(remaining == 1 ? "" : "s")."
        case .siteOpened(let site):
            "You've had everything \(ContentCatalog.shared.site(site)?.name.lowercased() ?? "it") has."
        case .learnedSymbol(let symbol):
            "You can write \(ContentCatalog.shared.symbol(symbol)?.name ?? "something new") now."
        case .gainedEssence(let amount): "\(amount) essence, banked."
        case .pickedUpItem(let what): "\(what) You can't tell what it is."
        case .satchelFull(let what): "No room in your satchel — \(what.lowercased()) is waiting on you."
        case .hazardHit(let damage): "The ground turns on you — \(damage) damage."
        case .enemySighted(let name): "A \(name) has noticed you."
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
        case .pickedUp, .harvested, .foundPortal, .pickedUpItem, .searchedSite, .siteOpened: .primary
        case .foundSite, .learnedSymbol, .gainedEssence: .primary
        case .readPage, .foundTraveller: .primary
        case .nightfall, .daybreak: .secondary
        case .cacheOpened: .purple
        case .satchelFull: .orange
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
                if let site = store.searchableHere, let definition = site.definition {
                    ActionButton("Search the \(definition.name.lowercased())",
                                 icon: definition.icon,
                                 detail: site.searchTurnsRemaining == definition.contents.searchTurns
                                     ? "\(definition.contents.searchTurns) turns"
                                     : "\(site.searchTurnsRemaining) turns left",
                                 isProminent: true) {
                        store.searchSite()
                    }
                }
                if store.canPortalHere {
                    ActionButton("Portal home", icon: "arrow.down.left.circle.fill",
                                 detail: "keep everything", isProminent: true) {
                        store.portalHome()
                    }
                }
                if store.isOnLockedCache {
                    let hasKey = store.carriedCacheKey != nil
                    ActionButton(hasKey ? "Open the cache" : "Locked cache",
                                 icon: hasKey ? "key.fill" : "lock.fill",
                                 detail: hasKey ? "spends your key" : "needs a key found elsewhere",
                                 isProminent: hasKey,
                                 isEnabled: hasKey) {
                        store.openCacheHere()
                    }
                }
                if store.harvestableHere == nil && store.searchableHere == nil
                    && !store.canPortalHere && !store.isOnLockedCache {
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
                Text(turnsLeftText)
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
        guard run.decayPerTurn > 0 else { return Tuning.World.indefiniteTurns }
        return Int((run.stability / run.decayPerTurn).rounded(.down))
    }

    /// A world that isn't decaying has no countdown — saying so beats printing the sentinel.
    private var turnsLeftText: String {
        turnsLeft >= Tuning.World.indefiniteTurns ? "steady" : "~\(turnsLeft) turns left"
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

/// The map, seen through a window that follows you.
///
/// **The map no longer has to fit one screen** (decisions-session-13 §3) — only the page does, since
/// you compose on a page and walk through a world. The camera is **clamped follow**: centred on you
/// until you reach an edge, where it stops rather than showing empty space past the border.
private struct MapGrid: View {
    let run: WorldRun
    let onTap: (GridPoint) -> Void

    /// How many tiles across the window is. Small maps show whole; big ones scroll under you.
    private var viewport: Int { min(Tuning.World.viewportTiles, min(run.map.width, run.map.height)) }

    /// Top-left of the window: centred on the player, then clamped to the map.
    private var origin: GridPoint {
        GridPoint(x: clamp(run.playerPosition.x - viewport / 2, run.map.width),
                  y: clamp(run.playerPosition.y - viewport / 2, run.map.height))
    }

    private func clamp(_ value: Int, _ extent: Int) -> Int {
        max(0, min(value, extent - viewport))
    }

    var body: some View {
        GeometryReader { proxy in
            let side = proxy.size.width / CGFloat(viewport)
            VStack(spacing: 0) {
                ForEach(origin.y..<(origin.y + viewport), id: \.self) { y in
                    HStack(spacing: 0) {
                        ForEach(origin.x..<(origin.x + viewport), id: \.self) { x in
                            let point = GridPoint(x: x, y: y)
                            TileView(tile: run.map[point],
                                     enemy: enemy(at: point),
                                     site: site(at: point),
                                     isPlayer: point == run.playerPosition,
                                     side: side)
                                .onTapGesture { onTap(point) }
                        }
                    }
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
    }

    private func enemy(at point: GridPoint) -> WorldEnemy? {
        run.enemies.first { $0.position == point }
    }

    private func site(at point: GridPoint) -> SiteDef? {
        run.sites.first { $0.position == point }?.definition
    }
}

private struct TileView: View {
    let tile: Tile
    let enemy: WorldEnemy?
    /// Resolved by the caller: the tile only stores an instance id, and the grid is the one place
    /// that has the run to look it up in.
    let site: SiteDef?
    let isPlayer: Bool
    let side: CGFloat

    var body: some View {
        ZStack {
            Rectangle()
                .fill(background)
                .overlay(Rectangle().stroke(Palette.mapGrid, lineWidth: 0.5))
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
        if let enemy { return enemy.icon }
        switch tile.content {
        case .empty: return nil
        case .node(let node): return ContentCatalog.shared.resource(node.resource)?.icon ?? "cube"
        case .wildDrop: return "sparkle"
        case .hazard: return "exclamationmark.triangle.fill"
        case .portal(let isEntry): return isEntry ? "arrow.down.left.circle" : "circle.circle"
        case .lockedCache: return "lock.fill"
        case .diaryPage: return "doc.text"
        case .site: return site?.icon ?? "building.columns"
        }
    }

    private var tint: Color {
        if isPlayer { return Palette.mapFloor }
        if enemy != nil { return .red }
        switch tile.content {
        case .hazard: return .orange
        case .portal: return .blue
        case .lockedCache: return .purple
        case .wildDrop: return .teal
        case .diaryPage: return .indigo
        case .site: return site?.category == .hazard ? .orange : .brown
        default: return .primary.opacity(0.7)
        }
    }

    /// The ground under everything. Elevation darkens it, so high country reads as high country.
    private var groundColour: Color {
        let base: Color = switch tile.ground {
        case .stone: Color(red: 0.55, green: 0.55, blue: 0.58)
        case .soil: Color(red: 0.45, green: 0.38, blue: 0.28)
        case .sand: Color(red: 0.80, green: 0.72, blue: 0.52)
        case .ice: Color(red: 0.78, green: 0.87, blue: 0.92)
        case .ash: Color(red: 0.38, green: 0.36, blue: 0.36)
        case .water: Color(red: 0.30, green: 0.52, blue: 0.72)
        case .deepWater: Color(red: 0.16, green: 0.30, blue: 0.52)
        case .rubble: Color(red: 0.50, green: 0.46, blue: 0.42)
        case .growth: Color(red: 0.30, green: 0.48, blue: 0.28)
        case .void: Color(red: 0.10, green: 0.10, blue: 0.12)
        }
        return base.opacity(1 - Double(tile.elevation) * 0.13)
    }

    /// Three clearly distinct states in both schemes — see `Palette` for why these can't be
    /// opacities over `.primary`: the meaning inverts in dark mode.
    private var background: Color {
        if tile.isCrumbled { return Palette.mapVoid }
        // Unseen ground stays fog; seen ground shows what it's made of.
        return tile.isRevealed ? groundColour : Palette.mapFog
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

#Preview {
    WorldView().environmentObject(GameStore(io: .temporary(name: "preview-world")))
}
