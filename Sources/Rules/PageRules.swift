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
        let candidates = ContentCatalog.shared.runeShapes(in: hand)
        guard !candidates.isEmpty else { return nil }
        let index = abs(stableHash(source.rawValue)) % candidates.count
        return candidates[index]
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
