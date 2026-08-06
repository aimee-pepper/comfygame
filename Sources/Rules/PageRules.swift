import Foundation

/// Fitting runes onto the page.
///
/// The page is a **packing puzzle over a budget**, and it stays one throughout: refinement shrinks
/// the shapes but never removes the allocation decision (`writing-system-rune-spec.md` §2). Early
/// pages fight you on both fronts — awkward shapes *and* not enough room. Late pages leave the pure
/// question of what earns its cells.
///
/// Nothing here may consult position to decide meaning. Placement is geometry; resolution is
/// `PressureRules`, and the two never meet.
enum PageRules {

    /// The shape a rune draws as in a given hand.
    ///
    /// Picked deterministically from the hand's authored shapes by the rune's identity, so the same
    /// rune always draws the same way without anyone hand-authoring a shape for all 149 runes in
    /// all three hands. Which shape a rune gets is arbitrary but *stable*, which is what matters:
    /// the player learns "Sun is the awkward one".
    static func shape(for source: PressureSourceID, hand: Hand) -> RuneShapeDef? {
        shape(forGlyph: source.rawValue, hand: hand)
    }

    /// The shape any glyph draws as, keyed by its identity.
    ///
    /// One rule for targets, sources and qualifiers alike: which authored footprint a rune gets is
    /// arbitrary but *stable*, which is what matters — the player learns that Sun is the awkward one.
    static func shape(forGlyph id: String, hand: Hand) -> RuneShapeDef? {
        let candidates = ContentCatalog.shared.runeShapes(in: hand)
        guard !candidates.isEmpty else { return nil }
        return candidates[abs(stableHash(id)) % candidates.count]
    }

    /// FNV-1a. Swift's `hashValue` is salted per process, which would redraw every page on relaunch.
    private static func stableHash(_ text: String) -> Int {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in text.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001b3
        }
        return Int(truncatingIfNeeded: hash)
    }

    // MARK: Placement

    /// Whether a shape fits at an origin: on the page, and not overlapping anything already written.
    static func canPlace(shape: RuneShapeDef, at origin: PageCell, on page: Page,
                         ignoring excluded: InstanceID? = nil) -> Bool {
        let taken = Set(page.runes.filter { $0.id != excluded }.flatMap(\.cells))
        return shape.offsets.allSatisfy { offset in
            let cell = origin + offset
            return page.contains(cell) && !taken.contains(cell)
        }
    }

    /// The shape a **compound** draws as: the closest authored shape to its computed footprint,
    /// so a compound really is smaller than spelling it out but still takes a real, awkward space.
    static func shape(forCompound symbol: SymbolDef, hand: Hand) -> RuneShapeDef? {
        let candidates = ContentCatalog.shared.runeShapes(in: hand)
        guard !candidates.isEmpty else { return nil }
        let wanted = footprint(of: symbol, hand: hand)
        // Nearest footprint, ties broken by id so the same compound always draws the same way.
        return candidates.min { lhs, rhs in
            (abs(lhs.footprint - wanted), lhs.id) < (abs(rhs.footprint - wanted), rhs.id)
        }
    }

    /// Writes a compound onto the page, or refuses because it doesn't fit.
    static func place(_ symbol: SymbolDef, hand: Hand, at origin: PageCell, on page: Page) -> Page? {
        guard let shape = shape(forCompound: symbol, hand: hand),
              canPlace(shape: shape, at: origin, on: page)
        else { return nil }
        var result = page
        result.runes.append(PlacedRune(id: InstanceID(rawValue: nextMarkID(on: page)),
                                       content: .compound(symbol.id),
                                       hand: hand, origin: origin, shapeID: shape.id))
        return result
    }

    static func placeAnywhere(_ symbol: SymbolDef, hand: Hand, on page: Page) -> Page? {
        guard let shape = shape(forCompound: symbol, hand: hand),
              let origin = validOrigins(for: shape, on: page).first
        else { return nil }
        return place(symbol, hand: hand, at: origin, on: page)
    }

    /// Identity for a newly written mark. Monotonic within a page, so placement order is stable
    /// and a save round-trips to the same page.
    private static func nextMarkID(on page: Page) -> UInt64 {
        (page.runes.map(\.id.rawValue).max() ?? 0) + 1
    }

    /// Writes a rune, or refuses. Returns nil when it doesn't fit, so callers can't half-place.
    static func place(_ sigil: Sigil, hand: Hand, at origin: PageCell, on page: Page) -> Page? {
        guard let shape = shape(for: sigil.source, hand: hand),
              canPlace(shape: shape, at: origin, on: page)
        else { return nil }

        var result = page
        result.runes.append(PlacedRune(id: sigil.id, sigil: sigil, hand: hand,
                                       origin: origin, shapeID: shape.id))
        return result
    }

    /// Every origin a shape could legally sit at, reading order. Drives "where can this go?"
    /// highlighting, and the auto-placer below.
    static func validOrigins(for shape: RuneShapeDef, on page: Page,
                             ignoring excluded: InstanceID? = nil) -> [PageCell] {
        (0..<page.height).flatMap { row in
            (0..<page.width).compactMap { column -> PageCell? in
                let origin = PageCell(column: column, row: row)
                return canPlace(shape: shape, at: origin, on: page, ignoring: excluded) ? origin : nil
            }
        }
    }

    /// Drops a rune into the first place it fits.
    ///
    /// Convenience, not a solver: the packing decision is the player's, and this exists so a rune
    /// can be added without the spatial UI existing yet — and so tests can build pages cheaply.
    static func placeAnywhere(_ sigil: Sigil, hand: Hand, on page: Page) -> Page? {
        guard let shape = shape(for: sigil.source, hand: hand),
              let origin = validOrigins(for: shape, on: page).first
        else { return nil }
        return place(sigil, hand: hand, at: origin, on: page)
    }

    /// Lift a mark and put it down somewhere else.
    ///
    /// Arranging is not a one-shot commitment (decisions-session-10 §3) — you can shuffle the page
    /// as much as you like before binding. Refused rather than nudged if the new spot doesn't fit,
    /// because where a mark goes is the player's decision.
    static func move(_ id: InstanceID, to origin: PageCell, on page: Page) -> Page? {
        guard let existing = page.runes.first(where: { $0.id == id }),
              let shape = existing.shape,
              canPlace(shape: shape, at: origin, on: page, ignoring: id)
        else { return nil }

        var result = page
        guard let index = result.runes.firstIndex(where: { $0.id == id }) else { return nil }
        result.runes[index].origin = origin
        return result
    }

    static func remove(_ id: InstanceID, from page: Page) -> Page {
        var result = page
        result.runes.removeAll { $0.id == id }
        return result
    }

    /// Redraws a rune in a different hand, keeping its position if the new shape still fits.
    ///
    /// A better hand should never cost you a page you'd already laid out, so a refined redraw that
    /// won't sit at the old origin is relocated rather than refused.
    static func redraw(_ id: InstanceID, in hand: Hand, on page: Page) -> Page? {
        guard let existing = page.runes.first(where: { $0.id == id }) else { return nil }
        let shape: RuneShapeDef?
        switch existing.content {
        case .rune(let sigil):
            shape = self.shape(for: sigil.source, hand: hand)
        case .compound(let symbolID):
            shape = ContentCatalog.shared.symbol(symbolID).flatMap { self.shape(forCompound: $0, hand: hand) }
        case .target(let id):
            shape = self.shape(forGlyph: id.rawValue, hand: hand)
        case .source(let id):
            shape = self.shape(for: id, hand: hand)
        case .qualifier(let id):
            shape = self.shape(forGlyph: id.rawValue, hand: hand)
        }
        guard let shape else { return nil }

        let without = remove(id, from: page)
        let origin = canPlace(shape: shape, at: existing.origin, on: without)
            ? existing.origin
            : validOrigins(for: shape, on: without).first
        guard let origin else { return nil }

        var result = without
        result.runes.append(PlacedRune(id: id, content: existing.content, hand: hand,
                                       origin: origin, shapeID: shape.id))
        return result
    }

    // MARK: Exclusivity

    /// Whether a symbol may be written, given what's already on the page.
    ///
    /// **One primary per pressure target** (decisions-session-11 §3). You cannot write two things
    /// that both decide what the ground is; you write one, then modify it. Chaining lifts the
    /// restriction — a world with two kinds of land in it is an earned capability rather than
    /// something you could always do.
    static func exclusivityConflict(writing symbol: SymbolDef, on page: Page,
                                    chainingUnlocked: Bool) -> SymbolDef? {
        guard !chainingUnlocked, symbol.isPrimary, let target = symbol.primaryTarget else { return nil }
        return page.symbolIDs
            .compactMap { ContentCatalog.shared.symbol($0) }
            .first { $0.isPrimary && $0.primaryTarget == target }
    }

    // MARK: Compounds

    /// What a compound costs to write: less than its parts, never free.
    ///
    /// `ceil(sum × 0.6)` — the spec's proposed rate. Compounds are the unlimited compression the
    /// hands stop short of, and this is why learning one is always worth it while never being a
    /// substitute for page space.
    static func compoundFootprint(ofParts footprints: [Int]) -> Int {
        let sum = footprints.reduce(0, +)
        guard sum > 0 else { return 0 }
        return max(1, Int((Double(sum) * Tuning.Page.compoundFootprintRate).rounded(.up)))
    }

    /// The footprint of a catalogue compound — a v0 symbol — in a given hand.
    static func footprint(of symbol: SymbolDef, hand: Hand) -> Int {
        let parts = symbol.expandsTo.compactMap { shape(for: $0.source, hand: hand)?.footprint }
        return compoundFootprint(ofParts: parts)
    }
}

// MARK: - Clusters, connections and reading the page

extension PageRules {

    /// Whether two marks are close enough to be joined.
    ///
    /// **Adjacency constrains, the connector declares intent** (session 14 §2). Two things touching
    /// are only joined if you say so — this is only the first half of the test.
    static func areAdjacent(_ first: PlacedRune, _ second: PlacedRune) -> Bool {
        let theirs = Set(second.cells)
        return first.cells.contains { cell in
            [PageCell(column: cell.column + 1, row: cell.row),
             PageCell(column: cell.column - 1, row: cell.row),
             PageCell(column: cell.column, row: cell.row + 1),
             PageCell(column: cell.column, row: cell.row - 1)].contains(where: theirs.contains)
        }
    }

    static func canConnect(_ a: InstanceID, _ b: InstanceID, on page: Page) -> Bool {
        guard a != b, !page.links.contains(MarkLink(a, b)),
              let first = page.runes.first(where: { $0.id == a }),
              let second = page.runes.first(where: { $0.id == b })
        else { return false }
        return areAdjacent(first, second)
    }

    static func connect(_ a: InstanceID, _ b: InstanceID, on page: Page) -> Page? {
        guard canConnect(a, b, on: page) else { return nil }
        var result = page
        result.links.insert(MarkLink(a, b))
        return result
    }

    static func disconnect(_ a: InstanceID, _ b: InstanceID, on page: Page) -> Page {
        var result = page
        result.links.remove(MarkLink(a, b))
        return result
    }

    /// The marks joined to this one, directly or through others.
    ///
    /// **A cluster is one object**: it moves and rotates whole, so its links can never break by
    /// accident — preserving the shape preserves every connection inside it.
    static func cluster(containing id: InstanceID, on page: Page) -> [PlacedRune] {
        var seen: Set<InstanceID> = [id]
        var queue = [id]
        while let next = queue.popLast() {
            for link in page.links {
                guard let other = link.other(than: next), !seen.contains(other) else { continue }
                seen.insert(other)
                queue.append(other)
            }
        }
        return page.runes.filter { seen.contains($0.id) }
    }

    /// Every cluster on the page, each as its member marks. Singletons count as clusters of one.
    static func clusters(on page: Page) -> [[PlacedRune]] {
        var remaining = Set(page.runes.map(\.id))
        var result: [[PlacedRune]] = []
        for rune in page.runes.sorted(by: { $0.id.rawValue < $1.id.rawValue }) {
            guard remaining.contains(rune.id) else { continue }
            let group = cluster(containing: rune.id, on: page)
            group.forEach { remaining.remove($0.id) }
            result.append(group)
        }
        return result
    }

    // MARK: Reading

    /// What the page says, read cluster by cluster.
    ///
    /// A cluster is read **target first**: whichever target sigil anchors it, every source connected
    /// into it pushes on that target. A qualifier modifies the source it is joined to. Sources with
    /// no target say nothing — they're a word with no sentence around them.
    ///
    /// Sorted by identity, never by position: **absolute position carries no meaning**, only the
    /// adjacency graph does (session 14 §3).
    static func sigils(of page: Page) -> [Sigil] {
        var result: [Sigil] = []
        for group in clusters(on: page) {
            // Self-contained marks — compounds and whole-statement runes — say what they say.
            result += group.sorted { $0.id.rawValue < $1.id.rawValue }.flatMap(\.sigils)

            guard let target = group.compactMap(\.targetID).min(by: { $0.rawValue < $1.rawValue })
            else { continue }

            for mark in group.sorted(by: { $0.id.rawValue < $1.id.rawValue }) {
                guard let source = mark.sourceID else { continue }
                result.append(Sigil(id: mark.id,
                                    source: source,
                                    target: target,
                                    intensity: intensity(qualifying: mark, on: page)))
            }
        }
        return result
    }

    /// The intensity a source is written at, from whichever Intensity qualifier is joined to it.
    ///
    /// Only Intensity reaches the resolver today — Scale and Count are written and read back, but
    /// nothing downstream consumes them yet. Noted rather than faked.
    static func intensity(qualifying mark: PlacedRune, on page: Page) -> Intensity {
        let attached = page.links
            .compactMap { $0.other(than: mark.id) }
            .compactMap { id in page.runes.first { $0.id == id } }
            .compactMap(\.qualifierID)
            .compactMap { ContentCatalog.shared.qualifier($0) }
            .first { $0.ladder == .intensity }

        switch attached?.id.rawValue {
        case "faint": return .faint
        case "great": return .great
        case "overwhelming": return .overwhelming
        default: return .moderate
        }
    }

    /// Qualifiers joined to a mark, whatever ladder they're on.
    static func qualifiers(on mark: InstanceID, page: Page) -> [QualifierDef] {
        page.links
            .compactMap { $0.other(than: mark) }
            .compactMap { id in page.runes.first { $0.id == id } }
            .compactMap(\.qualifierID)
            .compactMap { ContentCatalog.shared.qualifier($0) }
    }

    // MARK: Moving and rotating a cluster

    /// Shift a whole cluster. It moves as one object, so nothing inside it can come apart.
    static func move(cluster id: InstanceID, by delta: PageCell, on page: Page) -> Page? {
        let group = cluster(containing: id, on: page)
        let moving = Set(group.map(\.id))
        let others = Set(page.runes.filter { !moving.contains($0.id) }.flatMap(\.cells))

        var moved: [InstanceID: PageCell] = [:]
        for mark in group {
            let origin = PageCell(column: mark.origin.column + delta.column,
                                  row: mark.origin.row + delta.row)
            let cells = (mark.shape?.offsets ?? [PageCell(column: 0, row: 0)]).map { origin + $0 }
            guard cells.allSatisfy({ page.contains($0) && !others.contains($0) }) else { return nil }
            moved[mark.id] = origin
        }

        var result = page
        for index in result.runes.indices {
            if let origin = moved[result.runes[index].id] { result.runes[index].origin = origin }
        }
        return result
    }

    /// Turn a cluster a quarter turn clockwise about its own bounding box.
    ///
    /// **This is where the packing gameplay actually lives** (session 14 §2): an L-shaped cluster of
    /// four sigils has to fit somewhere as an L. Rotating single runes was never the interesting
    /// version of that.
    static func rotate(cluster id: InstanceID, on page: Page) -> Page? {
        let group = cluster(containing: id, on: page)
        guard group.count > 0 else { return nil }

        let occupied = group.flatMap(\.cells)
        let minColumn = occupied.map(\.column).min() ?? 0
        let minRow = occupied.map(\.row).min() ?? 0
        let maxRow = occupied.map(\.row).max() ?? 0
        let height = maxRow - minRow + 1

        // (c, r) → (minColumn + height - 1 - (r - minRow), minRow + (c - minColumn))
        func turned(_ cell: PageCell) -> PageCell {
            PageCell(column: minColumn + (height - 1) - (cell.row - minRow),
                     row: minRow + (cell.column - minColumn))
        }

        let moving = Set(group.map(\.id))
        let others = Set(page.runes.filter { !moving.contains($0.id) }.flatMap(\.cells))

        var placements: [InstanceID: (PageCell, RuneShapeDef)] = [:]
        var claimed: Set<PageCell> = []
        for mark in group {
            guard let shape = mark.shape else { return nil }
            let cells = mark.cells.map(turned)
            let origin = PageCell(column: cells.map(\.column).min() ?? 0,
                                  row: cells.map(\.row).min() ?? 0)
            // The mark's own footprint has to exist in the rotated orientation too.
            guard let rotatedShape = ContentCatalog.shared.rotatedShape(of: shape) else { return nil }
            let placed = rotatedShape.offsets.map { origin + $0 }
            guard placed.allSatisfy({ page.contains($0) && !others.contains($0) }),
                  placed.allSatisfy({ claimed.insert($0).inserted })
            else { return nil }
            placements[mark.id] = (origin, rotatedShape)
        }

        var result = page
        for index in result.runes.indices {
            guard let (origin, shape) = placements[result.runes[index].id] else { continue }
            result.runes[index].origin = origin
            result.runes[index].shapeID = shape.id
        }
        return result
    }
}
