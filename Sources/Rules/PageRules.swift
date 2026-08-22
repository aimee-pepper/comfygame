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

    /// The shape a mark draws as, given what it is.
    ///
    /// **A target sigil is always a single square**, in every hand (Aimee, 5 Aug). It's the anchor
    /// of a cluster rather than a statement in its own right, and charging four cells for saying
    /// *which dial you mean* would tax you for writing at all — you'd be paying to open your mouth.
    /// The hands still compress everything else, which is where the progression lives.
    static func shape(for content: MarkContent, hand: Hand) -> RuneShapeDef? {
        switch content {
        case .target(let id):
            return shape(forGlyph: id.rawValue, hand: .refined)
        case .source(let id):
            return shape(forGlyph: id.rawValue, hand: hand)
        case .qualifier(let id):
            return shape(forGlyph: id.rawValue, hand: hand)
        case .compound(let id):
            return ContentCatalog.shared.symbol(id).flatMap { shape(forCompound: $0, hand: hand) }
        case .rune(let sigil):
            return shape(for: sigil.source, hand: hand)
        }
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
            shape = self.shape(forGlyph: id.rawValue, hand: .refined)
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

// MARK: - Personal compound authority

extension PageRules {
    enum CompoundEligibilityIssue: String, Codable, Equatable, Sendable {
        case incomplete = "A compound needs one complete target-and-source statement."
        case multipleTargets = "A compound can have exactly one target."
        case tooFewAtoms = "A compound needs at least two atomic Sigils."
        case tooManyAtoms = "A compound can contain at most five atomic Sigils."
        case nestedCompound = "A personal compound cannot contain another compound."
        case unknownAtom = "Every atomic Sigil must be known before this statement can be formalized."
    }

    struct CompoundStatementAssessment: Equatable, Sendable {
        var markIDs: Set<InstanceID>
        var receipt: ProvenStatementReceipt?
        var issue: CompoundEligibilityIssue?
        var isEligible: Bool { receipt != nil && issue == nil }
    }

    static func compoundStatementAssessments(on page: Page, knownBy base: BaseState,
                                             boundRunIndex: Int) -> [CompoundStatementAssessment] {
        clusters(on: page).map { group in
            let ids = Set(group.map(\.id))
            if group.contains(where: { $0.personalCompound != nil || $0.symbolID != nil }) {
                return .init(markIDs: ids, receipt: nil, issue: .nestedCompound)
            }
            guard group.allSatisfy({ mark in
                switch mark.content {
                case .target, .source, .qualifier: true
                case .compound, .rune: false
                }
            }) else {
                return .init(markIDs: ids, receipt: nil, issue: .nestedCompound)
            }
            let targets = group.compactMap(\.targetID)
            guard targets.count <= 1 else {
                return .init(markIDs: ids, receipt: nil, issue: .multipleTargets)
            }
            guard let target = targets.first, group.contains(where: { $0.sourceID != nil }) else {
                return .init(markIDs: ids, receipt: nil, issue: .incomplete)
            }
            let vocabulary = group.compactMap { mark -> LexemeIdentity? in
                if let id = mark.targetID { return .target(id) }
                if let id = mark.sourceID { return .source(id) }
                if let id = mark.qualifierID { return .qualifier(id) }
                return nil
            }
            guard vocabulary.count >= 2 else {
                return .init(markIDs: ids, receipt: nil, issue: .tooFewAtoms)
            }
            guard vocabulary.count <= Tuning.Page.personalCompoundMaximumAtoms else {
                return .init(markIDs: ids, receipt: nil, issue: .tooManyAtoms)
            }
            let writableQualifiers = Set(writableQualifiers().map(\.id))
            let known = vocabulary.allSatisfy { identity in
                switch identity {
                case .target(let id): ContentCatalog.shared.pressureTarget(id) != nil
                case .source(let id):
                    base.ownedSources.contains(id) && ContentCatalog.shared.pressureSource(id) != nil
                case .qualifier(let id):
                    writableQualifiers.contains(id) && ContentCatalog.shared.qualifier(id) != nil
                case .compound: false
                }
            }
            guard known else {
                return .init(markIDs: ids, receipt: nil, issue: .unknownAtom)
            }
            let groupSigils = clusterSigils(of: Page(width: page.width, height: page.height,
                                                       runes: group,
                                                       links: page.links.filter {
                                                           ids.contains($0.a) && ids.contains($0.b)
                                                       }))
            guard !groupSigils.isEmpty, groupSigils.allSatisfy({ $0.target == target }) else {
                return .init(markIDs: ids, receipt: nil, issue: .incomplete)
            }
            let atoms = normalizedAtoms(groupSigils)
            let normalizedVocabulary = vocabulary.sorted(by: lexemeLessThan)
            let receipt = ProvenStatementReceipt(
                fingerprint: statementFingerprint(target: target, atoms: atoms),
                target: target, atoms: atoms, vocabulary: normalizedVocabulary,
                vocabularySchemaVersion: ProvenStatementReceipt.currentVocabularySchemaVersion,
                firstBoundRunIndex: boundRunIndex)
            return .init(markIDs: ids, receipt: receipt, issue: nil)
        }
    }

    static func normalizedAtoms(_ sigils: [Sigil]) -> [CompoundSemanticAtom] {
        sigils.map(CompoundSemanticAtom.init).sorted { atomKey($0) < atomKey($1) }
    }

    static func statementFingerprint(target: PressureTargetID,
                                     atoms: [CompoundSemanticAtom]) -> String {
        let body = normalizedAtoms(atoms.enumerated().map { $0.element.sigil(id: .init(rawValue: UInt64($0.offset))) })
            .map(atomKey).joined(separator: "|")
        return "statement-v1:\(target.rawValue):\(body)"
    }

    static func personalCompoundFootprint(_ record: PersonalCompoundRecord, hand: Hand) -> Int {
        let footprints = record.vocabulary.compactMap { identity -> Int? in
            switch identity {
            case .target(let id): shape(for: .target(id), hand: hand)?.footprint
            case .source(let id): shape(for: .source(id), hand: hand)?.footprint
            case .qualifier(let id): shape(for: .qualifier(id), hand: hand)?.footprint
            case .compound: nil
            }
        }
        return compoundFootprint(ofParts: footprints)
    }

    static func shape(forPersonalCompound record: PersonalCompoundRecord,
                      hand: Hand) -> RuneShapeDef? {
        let wanted = personalCompoundFootprint(record, hand: hand)
        return ContentCatalog.shared.runeShapes(in: hand).min {
            (abs($0.footprint - wanted), $0.id) < (abs($1.footprint - wanted), $1.id)
        }
    }

    static func place(_ record: PersonalCompoundRecord, hand: Hand, at origin: PageCell,
                      on page: Page) -> Page? {
        guard let shape = shape(forPersonalCompound: record, hand: hand),
              let first = record.expansion.first,
              canPlace(shape: shape, at: origin, on: page) else { return nil }
        let markID = InstanceID(rawValue: nextMarkID(on: page))
        let snapshot = PersonalCompoundMarkSnapshot(
            id: record.id, nickname: record.nickname, expansion: record.expansion,
            provenFingerprint: record.provenFingerprint, provenance: record.provenance)
        var result = page
        result.runes.append(PlacedRune(id: markID, content: .rune(first.sigil(id: markID)),
                                       hand: hand, origin: origin, shapeID: shape.id,
                                       personalCompound: snapshot))
        return result
    }

    static func isEffectEquivalent(_ record: PersonalCompoundRecord,
                                   to receipt: ProvenStatementReceipt) -> Bool {
        record.target == receipt.target && record.expansion == receipt.atoms
            && statementFingerprint(target: record.target, atoms: record.expansion) == receipt.fingerprint
    }

    private static func atomKey(_ atom: CompoundSemanticAtom) -> String {
        let negated = atom.negatedTargets.map(\.rawValue).sorted().joined(separator: ",")
        return [atom.source.rawValue, atom.target.rawValue, atom.intensity.rawValue,
                String(atom.scale), String(atom.count), negated].joined(separator: ":")
    }

    private static func lexemeLessThan(_ lhs: LexemeIdentity, _ rhs: LexemeIdentity) -> Bool {
        (lhs.categoryOrder, lhs.glyphID) < (rhs.categoryOrder, rhs.glyphID)
    }
}

// MARK: - Clusters, connections and reading the page

extension PageRules {

    enum ConnectionIssue: Equatable {
        case unavailable, notAdjacent, completeStatement, multipleTargets, incompatibleFocus
        case chainingRequired, modifierMustAttachToFocus, modifierAlreadyAttached
        case duplicateModifierLadder, incompatibleModifier

        var message: String {
            switch self {
            case .unavailable: "Those Sigils cannot be joined."
            case .notAdjacent: "Move the Sigils next to each other before joining them."
            case .completeStatement: "That Sigil is already a complete statement."
            case .multipleTargets: "A statement can have exactly one subject."
            case .incompatibleFocus: "That focus cannot be written on this subject."
            case .chainingRequired: "Learn Chaining before joining more than one focus."
            case .modifierMustAttachToFocus: "A modifier must join directly to one focus."
            case .modifierAlreadyAttached: "That modifier is already attached to a focus."
            case .duplicateModifierLadder: "A focus can use only one rung from each modifier ladder."
            case .incompatibleModifier: "That modifier cannot be used with this subject."
            }
        }
    }

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

    static func connectionIssue(_ a: InstanceID, _ b: InstanceID, on page: Page,
                                chainingUnlocked: Bool = false) -> ConnectionIssue? {
        guard a != b, !page.links.contains(MarkLink(a, b)),
              let first = page.runes.first(where: { $0.id == a }),
              let second = page.runes.first(where: { $0.id == b })
        else { return .unavailable }
        guard areAdjacent(first, second) else { return .notAdjacent }
        guard first.sourceID != nil || first.targetID != nil || first.qualifierID != nil,
              second.sourceID != nil || second.targetID != nil || second.qualifierID != nil
        else { return .completeStatement }

        var proposed = page
        proposed.links.insert(MarkLink(a, b))
        let group = cluster(containing: a, on: proposed)
        let targets = group.compactMap(\.targetID)
        let focuses = group.filter { $0.sourceID != nil }
        let modifiers = group.filter { $0.qualifierID != nil }

        guard targets.count <= 1 else { return .multipleTargets }
        if focuses.count > 1 && !chainingUnlocked { return .chainingRequired }
        if let target = targets.first {
            guard focuses.allSatisfy({ mark in
                mark.sourceID.flatMap(ContentCatalog.shared.pressureSource)?.canAttach(to: target) == true
            }) else { return .incompatibleFocus }
        }

        for modifierMark in modifiers {
            let neighbours = proposed.links.compactMap { $0.other(than: modifierMark.id) }
                .compactMap { id in proposed.runes.first { $0.id == id } }
            guard neighbours.count == 1, let focus = neighbours.first, focus.sourceID != nil else {
                return page.links.contains(where: { $0.a == modifierMark.id || $0.b == modifierMark.id })
                    ? .modifierAlreadyAttached : .modifierMustAttachToFocus
            }
            guard let qualifierID = modifierMark.qualifierID,
                  let qualifier = ContentCatalog.shared.qualifier(qualifierID)
            else { return .unavailable }
            if let target = targets.first, !qualifier.applies(to: target) { return .incompatibleModifier }
            let attached = qualifiers(on: focus.id, page: proposed)
            if attached.filter({ $0.ladder == qualifier.ladder }).count > 1 {
                return .duplicateModifierLadder
            }
        }
        return nil
    }

    static func canConnect(_ a: InstanceID, _ b: InstanceID, on page: Page,
                           chainingUnlocked: Bool = false) -> Bool {
        connectionIssue(a, b, on: page, chainingUnlocked: chainingUnlocked) == nil
    }

    static func connect(_ a: InstanceID, _ b: InstanceID, on page: Page,
                        chainingUnlocked: Bool = false) -> Page? {
        guard canConnect(a, b, on: page, chainingUnlocked: chainingUnlocked) else { return nil }
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
        clusterSigils(of: page) + compoundSigils(of: page)
    }

    /// The self-contained marks — compounds and whole-statement runes — which say what they say
    /// wherever they sit, joined to anything or not.
    static func compoundSigils(of page: Page) -> [Sigil] {
        page.runes.sorted { $0.id.rawValue < $1.id.rawValue }.flatMap(\.sigils)
    }

    /// **Only what the target-and-source clusters say.** Kept separate from the compounds because
    /// the two vocabularies price stability differently: a compound prints its own number and that
    /// number is the whole of its contribution (session 5, locked), while a cluster prints nothing
    /// and is charged for the abundance it asks for.
    static func clusterSigils(of page: Page) -> [Sigil] {
        var result: [Sigil] = []
        for group in clusters(on: page) {

            // **The target sigil is mandatory** (Aimee, 5 Aug). It's the anchor of the cluster,
            // and a cluster without one says nothing at all — sources with nothing to push on are
            // words with no sentence around them.
            guard let target = group.compactMap(\.targetID).min(by: { $0.rawValue < $1.rawValue })
            else { continue }

            for mark in group.sorted(by: { $0.id.rawValue < $1.id.rawValue }) {
                guard let source = mark.sourceID else { continue }
                let modifiers = qualifiers(on: mark.id, page: page)
                result.append(Sigil(id: mark.id,
                                    source: source,
                                    target: target,
                                    intensity: intensity(qualifying: mark, on: page),
                                    // Stored one above the rung, because step 0 is a real rung
                                    // (*minute*, *single*) and 0 has to mean "nothing written".
                                    scale: modifiers.first { $0.ladder == .scale }.map { $0.step + 1 } ?? 0,
                                    count: modifiers.first { $0.ladder == .count }.map { $0.step + 1 } ?? 0))
            }
        }
        return result
    }

    /// The intensity a source is written at, from whichever Intensity qualifier is joined to it.
    ///
    /// **Intensity is the ladder that means "how much"**, and it's the only one the resolver reads.
    ///
    /// Scale means *world size* and is read off the Relief cluster alone; it is now marked
    /// relief-only in the data so it can't be written anywhere it would do nothing. That trap cost
    /// a real session: Aimee read Mara's clue correctly, wrote *a giant sun*, and got a plain one,
    /// because "giant" reads as scale in English and needs to be intensity here (6 Aug).
    ///
    /// **Count is still consumed by nothing** and is the next one to either wire or hide.
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

    /// **What one mark is**, in a phrase — for the box under the page.
    ///
    /// Aimee: *"clicking on a sigil should tell you its name in the little dynamic text box."* It
    /// matters more than it sounds: the glyphs are abstract placeholders now and will be abstract
    /// *by design* once the real hand artwork lands. A player has to be able to ask what one is.
    static func reading(of mark: PlacedRune, on page: Page) -> String? {
        let modifiers = qualifiers(on: mark.id, page: page).map(\.name)
        switch mark.content {
        case .target(let id):
            let subject = ContentCatalog.shared.pressureTarget(id)?.name ?? id.rawValue
            let focuses = cluster(containing: mark.id, on: page)
                .compactMap(\.sourceID)
                .compactMap { ContentCatalog.shared.pressureSource($0)?.name }
            return focuses.isEmpty
                ? "A subject, with nothing focused on it yet."
                : "\(subject), focused on \(focuses.joined(separator: " and "))."
        case .source(let id):
            let focus = ContentCatalog.shared.pressureSource(id)?.name ?? id.rawValue
            let subject = cluster(containing: mark.id, on: page)
                .compactMap(\.targetID).first
                .flatMap { ContentCatalog.shared.pressureTarget($0)?.name }
            let described = (modifiers + [focus]).joined(separator: " ")
            return subject.map { "\(described), on \($0)." } ?? "\(described) — joined to no subject."
        case .qualifier(let id):
            // **Not the name again** — the row above already says it. This line is for what the
            // modifier is *for*.
            // Just the job. The name above already says which ladder it's a rung of — *Countless*
            // is plainly Count — and the strip has room for one clause, not two.
            let modifier = ContentCatalog.shared.qualifier(id)
            return modifier.map { $0.ladder.job.capitalisedSentence + "." }
        case .compound(let id):
            return ContentCatalog.shared.symbol(id)?.blurb
        case .rune(let sigil):
            return sigil.displayText
        }
    }

    /// **What you actually wrote**, one line per joined cluster, in the page's own vocabulary.
    ///
    /// Aimee, 6 Aug: *"the 'The World' page should list the sigil chains you've placed on the
    /// page."* The description panel says what the world is *like* and deliberately never names a
    /// sigil — it's the deduction surface, matched against a diary passage. But that left the
    /// player with an oracle and no readout of their own writing, so a wrong deduction taught
    /// nothing: you wrote *a giant sun*, the world came out dim, and there was no way to see that
    /// "giant" was a Scale rung doing nothing.
    ///
    /// This is the readout. *Illumination ← great Sun* — the level at which *vast* versus *great*
    /// is visible.
    static func chains(on page: Page) -> [WrittenChain] {
        let allSigils = clusterSigils(of: page)
        let resolvedSigils = Dictionary(uniqueKeysWithValues: allSigils.map { ($0.id, $0) })
        let totalGreed = BookRules.greedDelta(for: allSigils)
        return clusters(on: page).compactMap { group -> WrittenChain? in
            guard let targetID = group.compactMap(\.targetID).first,
                  let target = ContentCatalog.shared.pressureTarget(targetID)
            else { return nil }

            let parts: [WrittenChain.Part] = group.compactMap { mark in
                guard let sourceID = mark.sourceID,
                      let source = ContentCatalog.shared.pressureSource(sourceID)
                else { return nil }
                let rungs = qualifiers(on: mark.id, page: page)
                let effects: [WrittenChain.Effect] = resolvedSigils[mark.id].map { sigil in
                    source.contributions.compactMap { contribution -> WrittenChain.Effect? in
                        guard let affected = ContentCatalog.shared.pressureTarget(contribution.target) else {
                            return nil
                        }
                        let amplitude = sigil.intensity.multiplier
                            * PressureRules.scaleMultiplier(sigil, target: affected)
                            * PressureRules.countMultiplier(sigil)
                        return WrittenChain.Effect(targetID: affected.id,
                                                   target: affected.name,
                                                   peak: contribution.peak * amplitude,
                                                   floor: contribution.floor * amplitude,
                                                   hasFloor: affected.dualValued,
                                                   isPrimary: contribution.target == targetID)
                    }
                } ?? []
                return WrittenChain.Part(
                    source: source.name,
                    qualifiers: rungs.map { rung in
                        WrittenChain.Rung(name: rung.name,
                                          isInert: !rung.ladder.changesAnything(for: targetID)
                                              || !rung.applies(to: targetID))
                    },
                    negates: [], effects: effects,
                    stabilityDelta: resolvedSigils[mark.id].map { sigil in
                        totalGreed - BookRules.greedDelta(for: allSigils.filter { $0.id != sigil.id })
                    } ?? 0
                )
            }
            guard !parts.isEmpty else { return nil }
            return WrittenChain(target: target.name, parts: parts)
        }
        .sorted { $0.target < $1.target }
    }

    /// **Qualifiers written where they say nothing**, with the cluster they're in.
    ///
    /// The page already warns about marks that aren't joined into anything — a page that looks full
    /// and describes nothing. This is the same trap one level down: a mark that *is* joined, in a
    /// cluster that resolves, carrying a rung that changes nothing about that target. *Vast* on a
    /// Sun is the case that cost a session.
    static func inertQualifiers(on page: Page) -> [(qualifier: QualifierDef, target: PressureTargetDef)] {
        var found: [(QualifierDef, PressureTargetDef)] = []
        for group in clusters(on: page) {
            guard let targetID = group.compactMap(\.targetID).first,
                  let target = ContentCatalog.shared.pressureTarget(targetID)
            else { continue }
            for mark in group {
                // Inert two ways: a *ladder* that does nothing to this subject, or a **narrow**
                // modifier written outside the subjects it was authored for. Phase says what form
                // water takes and nothing whatever about light.
                guard let id = mark.qualifierID,
                      let qualifier = ContentCatalog.shared.qualifier(id),
                      !qualifier.ladder.changesAnything(for: targetID)
                        || !qualifier.applies(to: targetID)
                else { continue }
                found.append((qualifier, target))
            }
        }
        return found
    }

    /// The Scale rung a source is written at, if any.
    ///
    /// Scale was already in the vocabulary and already placeable — it just wasn't being read.
    /// Nothing new is needed for world size; this is the reading.
    static func scale(qualifying mark: PlacedRune, on page: Page) -> QualifierDef? {
        qualifiers(on: mark.id, page: page).first { $0.ladder == .scale }
    }

    /// How much world a page asks for.
    ///
    /// **Scale attached to the source that shapes the land** (decisions-session-13 §5). Written
    /// nowhere, the world is ordinary; written on the Relief cluster's source, it's whatever you
    /// said. Size costs page cells like any other sigil *and* costs stability, which is what makes
    /// a vast world a greed-shaped decision rather than a free upgrade.
    static func worldScale(of page: Page) -> WorldScale {
        for group in clusters(on: page) {
            guard group.contains(where: { $0.targetID == "relief" }) else { continue }
            for mark in group where mark.sourceID != nil {
                if let rung = scale(qualifying: mark, on: page) {
                    return WorldScale(rung: rung.id) ?? .ordinary
                }
            }
        }
        return .ordinary
    }

    /// Qualifiers joined to a mark, whatever ladder they're on.
    static func qualifiers(on mark: InstanceID, page: Page) -> [QualifierDef] {
        page.links
            .compactMap { $0.other(than: mark) }
            .compactMap { id in page.runes.first { $0.id == id } }
            .compactMap(\.qualifierID)
            .compactMap { ContentCatalog.shared.qualifier($0) }
            .sorted { ($0.ladder.rawValue, $0.step, $0.id.rawValue) <
                ($1.ladder.rawValue, $1.step, $1.id.rawValue) }
    }

    /// Vocabulary offered for new writing. Dormant ladders remain in the catalogue so old saves
    /// decode, but cannot create more inert statements.
    static func writableQualifiers(for target: PressureTargetID? = nil) -> [QualifierDef] {
        ContentCatalog.shared.qualifiers.filter { qualifier in
            qualifier.ladder != .phase && target.map { qualifier.applies(to: $0) } != false
        }
    }

    /// Diagnostics for tolerant legacy pages. Old saves are not rewritten merely because today's
    /// editor would refuse their graph; they remain readable and say where they are ambiguous.
    static func grammarWarnings(on page: Page, chainingUnlocked: Bool) -> [String] {
        var warnings: Set<String> = []
        for group in clusters(on: page) {
            let targets = group.compactMap(\.targetID)
            let focuses = group.filter { $0.sourceID != nil }
            if targets.count > 1 { warnings.insert("A joined statement has more than one subject.") }
            if focuses.count > 1 && !chainingUnlocked {
                warnings.insert("A joined statement uses multiple focuses without Chaining.")
            }
            if let target = targets.sorted(by: { $0.rawValue < $1.rawValue }).first,
               focuses.contains(where: { mark in
                   mark.sourceID.flatMap(ContentCatalog.shared.pressureSource)?.canAttach(to: target) != true
               }) {
                warnings.insert("A focus is incompatible with its joined subject.")
            }
            for modifier in group.filter({ $0.qualifierID != nil }) {
                let neighbours = page.links.compactMap { $0.other(than: modifier.id) }
                    .compactMap { id in page.runes.first { $0.id == id } }
                if neighbours.count != 1 || neighbours.first?.sourceID == nil {
                    warnings.insert("A modifier is not attached directly to exactly one focus.")
                }
            }
            for focus in focuses {
                let rungs = qualifiers(on: focus.id, page: page)
                if Dictionary(grouping: rungs, by: \.ladder).values.contains(where: { $0.count > 1 }) {
                    warnings.insert("A focus has more than one rung from the same modifier ladder.")
                }
            }
        }
        return warnings.sorted()
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


/// One joined cluster, as a line you can read back: *Illumination ← great Sun*.
///
/// The description panel is prose on purpose (it's what a diary passage gets matched against). This
/// is the other half — **what you wrote**, so cause and effect sit on one screen and a wrong
/// deduction can be traced (Aimee, 6 Aug).
struct WrittenChain: Equatable, Identifiable, Sendable {
    var target: String
    var parts: [Part]

    var id: String { target }

    struct Part: Equatable, Sendable {
        var source: String
        var qualifiers: [Rung]
        /// Targets this source explicitly denies — "a sun that does not warm".
        var negates: [String]
        var effects: [Effect] = []
        /// This focus's marginal contribution to the page's greed term, in headline units.
        var stabilityDelta: Int = 0

        /// *great Sun*, or *vast Sun* with the vast marked as saying nothing.
        var phrase: String {
            (qualifiers.map(\.name) + [source]).joined(separator: " ")
        }
    }

    struct Effect: Equatable, Sendable {
        var targetID: PressureTargetID
        var target: String
        var peak: Double
        var floor: Double
        var hasFloor: Bool
        var isPrimary: Bool

        var text: String {
            hasFloor ? "\(Self.signed(peak)) / \(Self.signed(floor))" : Self.signed(peak)
        }

        private static func signed(_ value: Double) -> String {
            let number = Int(value.rounded())
            return number > 0 ? "+\(number)" : "\(number)"
        }
    }

    struct Rung: Equatable, Sendable {
        var name: String
        /// Written here, and changing nothing here. The whole reason this readout exists.
        var isInert: Bool
    }

    var hasInertModifier: Bool { parts.contains { $0.qualifiers.contains { $0.isInert } } }

    /// Keep the authored page link visible, but disclose numeric consequences only for subjects
    /// the player has learned to measure in the field. In particular, an undiscovered secondary
    /// must disappear completely rather than leaving an "unknown effect" breadcrumb.
    func disclosingEffects(measured subjects: Set<PressureTargetID>) -> WrittenChain {
        var disclosed = self
        disclosed.parts = parts.map { part in
            var part = part
            part.effects = part.effects.filter { subjects.contains($0.targetID) }
            return part
        }
        return disclosed
    }
}
