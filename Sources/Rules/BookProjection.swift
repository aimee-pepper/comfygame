import Foundation

/// Everything the Writing Desk shows before the player commits — pillar 5, legibility before
/// commitment.
///
/// Legible about **what you are spending and risking**, which is not the same as explaining the
/// world to you. What a world turns out to be is meant to be discovered by writing and looking
/// (decisions-session-8): the price is exact, the outcome is ranged, and *why* it came out that way
/// is earned through the analysis axis rather than printed here.
///
/// The interesting decision here: **an unfilled slot produces a range, not a guess.** Two locked
/// rules pull against each other — empty slots are random-filled as a *surprise*, and the player
/// must be able to see what they're committing to. A range satisfies both: you always know the
/// bounds you're signing up for, you just don't know where in them you'll land. Fill every slot and
/// every range collapses to an exact number.
///
/// **Cost is the exception, and deliberately so.** A slot left to chance costs a flat cheap rate
/// whatever rolls into it (decisions-log session 2), so the price is fully known while you're still
/// composing. The split that leaves is the honest one: *the price is certain, the world is not.*
///
/// Ranges are computed per-slot rather than by enumerating combinations, which is exact because
/// instability and enemy tier are additive over slots.
struct BookProjection {

    struct SlotPlan: Identifiable {
        var slot: SlotID
        /// The symbol the player put here, or nil if the slot is left to chance.
        var chosen: SymbolDef?
        /// What a random fill could draw from — the *whole* catalog, not just what the player
        /// owns, so a chance slot can surprise you with something you couldn't have written.
        var candidates: [SymbolDef]

        var id: SlotID { slot }
        var isRandom: Bool { chosen == nil }
        /// A slot with nothing to draw from generates nothing at all.
        var isEmpty: Bool { chosen == nil && candidates.isEmpty }
    }

    var slotPlans: [SlotPlan]
    var essenceCost: ClosedRange<Int>
    /// The 0–100 headline. Same units as the numbers printed on the symbols themselves.
    var stabilityScore: ClosedRange<Int>
    var turnsUntilCollapse: ClosedRange<Int>
    var enemyTier: ClosedRange<Int>
    /// How far you'll see. A stable world is often a dark one, and that trade has to be on screen
    /// or the player is only ever shown half of what a symbol does.
    var visionRadius: ClosedRange<Int>
    var mapWidth: Int
    var mapHeight: Int
    /// What the world will be like, in prose. Derived from the same resolution the bind runs.
    var worldDescription: WorldDescription
    /// How much stability the danger-rune cap withheld. Shown on its own line rather than folded
    /// into the headline — the same rule the contradiction escalation term follows.
    var dangerCapShortfall: Int
    /// Expected share of harvests by resource, descending. Expected, not ranged — a pile of ranged
    /// percentages is unreadable, and the mix is the qualitative half of the preview.
    var resourceMix: [(resource: ResourceDef, share: Double)]
    /// **What will live here**, in the terms the preview is allowed to use: how many kinds, and
    /// what they will tend to be like. Read off the readings, never off the seed, so it describes
    /// the world you wrote rather than the one that was rolled.
    ///
    /// This replaced a silhouette list drawn from the old authored spawn table. Once worlds grew
    /// their own animals that list promised three creatures no world could contain — the preview
    /// and the world had quietly stopped agreeing.
    var life: LifeRules.LifeProjection
    /// How many marks are written on the page, and how many of them are actually **saying**
    /// something — a mark only speaks as part of a joined cluster with a target in it.
    ///
    /// The two numbers differ whenever sigils are written but not joined, which is a page that
    /// looks full and describes nothing. Without this the preview showed a complete, plausible
    /// world at full stability built entirely out of the random fill, and there was no way to tell
    /// it wasn't yours.
    var marksWritten: Int = 0
    var marksSpeaking: Int = 0
    /// **The chains you placed**, so the world panel can show cause beside effect (Aimee, 6 Aug).
    var chains: [WrittenChain] = []
    /// **Which subjects you actually wrote about.**
    ///
    /// The panel may only describe what you asked for. Aimee, 6 Aug: *"under life and expected
    /// harvest it shouldn't offer info on what's there if it hasn't been selected by the player and
    /// is left up to chance."* Quite right — a confident sentence about the animals of a world whose
    /// vitality you never touched is the panel inventing a world and reading it back to you.
    var writtenSubjects: Set<PressureTargetID> = []

    /// Whether the panel can say anything about what lives here.
    var canDescribeLife: Bool { writtenSubjects.contains("vitality") }

    /// Whether the page, as it stands, contributes nothing at all to the world.
    var saysNothing: Bool { marksSpeaking == 0 }
    /// Marks are written, and none of them are joined into anything that speaks.
    var isWrittenButSilent: Bool { marksWritten > 0 && marksSpeaking == 0 }

    /// True when every slot is chosen, so nothing is left to chance and every range is a point.
    var isFullySpecified: Bool { slotPlans.allSatisfy { !$0.isRandom } }
    /// Slots that will actually be filled by chance — a slot with nothing to draw from doesn't
    /// count, and isn't charged for.
    var randomSlots: [SlotID] { slotPlans.filter { $0.isRandom && !$0.isEmpty }.map(\.slot) }
    /// What this book will cost, exactly. Known before committing — see the note above.
    var cost: Int { essenceCost.lowerBound }
    /// How much of the cost is the flat charge for slots left to chance.
    var randomSlotCost: Int { randomSlots.count * Tuning.Book.randomSlotCostEssence }

    // MARK: - Computation

    /// `seed` is the one the next bind will use, peeked rather than consumed. Nothing reads it
    /// yet — it's threaded through so that whatever the answer to Q19 turns out to be, the
    /// projection can be *exact* about it rather than hedging with a range.
    /// Project what's written on the page.
    ///
    /// Every mark is chosen, so nothing here is ranged by *composition* — the only uncertainty
    /// left is what the world decides about the targets you said nothing about, which is rolled
    /// from the seed and folded into the description rather than into the numbers.
    /// - Parameter revealRolled: true once the world has been **visited or anchored**, at which
    ///   point it has no secrets left and its rolled values may be shown in full
    ///   (decisions-session-11 §1). Otherwise the panel is bound by the absolute rule: it may
    ///   reveal nothing the player did not directly place.
    static func project(page: Page,
                        seed: UInt64 = 0,
                        analysisTier: Int = Tuning.Analysis.startingTier,
                        revealRolled: Bool = false) -> BookProjection {
        let book = BookRules.resolveBook(page: page)
        let written = book.allSymbolIDs
        let sigils = BookRules.sigils(for: book)
        // **Written only**, unless the world has already been seen. Resolving with the unwritten
        // targets filled would describe the world's own surprises back to the player before they'd
        // paid for them.
        let readings = revealRolled
            ? PressureRules.resolve(sigils, fillingUnwrittenWith: seed)
            : PressureRules.resolve(sigils)
        let contradictions = ContradictionRules.fired(in: sigils, readings: readings)

        // Greed from abundance, contradiction from opposed magnitude — instability's two origins,
        // and until now only the second of them reached the headline for a page written in sigils.
        let score = BookRules.stabilityScore(
            delta: BookRules.stabilityDelta(
                of: book,
                sigils: sigils,
                contradictionPenalty: ContradictionRules.totalPenalty(for: contradictions)))
        // **Stability is a range, because the world is** (Aimee, 6 Aug: *"why is the world page
        // showing a concrete value for stability rather than the possible range that can occur with
        // roll changes for the undefined values?"*).
        //
        // The score above counts only what you wrote — correctly, since the panel must not reveal
        // rolled content. But **every unwritten subject is rolled at bind**, and a rolled focus can
        // carry its own stability delta, add greed if something valuable lands, or fire a
        // contradiction against what you wrote. Six of eight subjects unwritten is normal, and the
        // number shown could be off by a lot.
        //
        // The design has been careful about this everywhere else: **the price is certain, the world
        // is not.** Cost is a point because page space is physical and known. Stability isn't, and
        // showing it as one was a lie of precision.
        //
        // It also makes a real decision legible for the first time: **writing more subjects narrows
        // the band.** That's the value of specificity, as a number.
        let rolled = rolledStabilitySpread(sigils: sigils, page: page, book: book, seed: seed)
        let worst = min(score, rolled.lowerBound)
        let best = max(score, rolled.upperBound)
        let turnsWorst = BookRules.turnsAvailable(stabilityScore: worst)
        let turnsBest = BookRules.turnsAvailable(stabilityScore: best)
        let tier = BookRules.enemyTier(symbolIDs: written)
        let sight = WorldRules.visionRadius(for: book)
        let cost = book.essencePaid

        let plans = written.enumerated().compactMap { index, id -> SlotPlan? in
            guard let symbol = ContentCatalog.shared.symbol(id) else { return nil }
            return SlotPlan(slot: SlotID(rawValue: "mark-\(index)"), chosen: symbol, candidates: [])
        }

        return BookProjection(
            slotPlans: plans,
            essenceCost: cost...cost,
            stabilityScore: worst...best,
            turnsUntilCollapse: turnsWorst...turnsBest,
            enemyTier: tier...tier,
            visionRadius: sight...sight,
            mapWidth: book.scale.gridSide,
            mapHeight: book.scale.gridSide,
            worldDescription: DescriptionRules.describe(
                readings,
                contradictions: contradictions,
                analysisTier: analysisTier,
                about: revealRolled ? nil : DescriptionRules.targetsTouched(by: sigils)
            ),
            dangerCapShortfall: BookRules.dangerCapShortfall(symbolIDs: written),
            resourceMix: expectedResourceMix(in: readings),
            life: LifeRules.projection(for: readings),
            marksWritten: page.runes.count,
            marksSpeaking: PageRules.sigils(of: page).count,
            chains: PageRules.chains(on: page),
            writtenSubjects: Set(sigils.map(\.target))
        )
    }

    static func project(draft: BookDraft,
                        ownedSymbols: Set<SymbolID>,
                        seed: UInt64 = 0,
                        analysisTier: Int = Tuning.Analysis.startingTier) -> BookProjection {
        let plans = ContentCatalog.shared.slotIDsInOrder.map { slot in
            SlotPlan(
                slot: slot,
                chosen: draft[slot].flatMap { ContentCatalog.shared.symbol($0) },
                candidates: BookRules.candidates(for: slot, ownedSymbols: ownedSymbols)
            )
        }

        // Additive quantities: summing per-slot extremes gives the exact overall extremes.
        var tierLow = Tuning.World.baseEnemyTier, tierHigh = Tuning.World.baseEnemyTier
        var sightLow = Tuning.World.baseVisionRadius, sightHigh = Tuning.World.baseVisionRadius

        for plan in plans {
            let options = plan.chosen.map { [$0] } ?? plan.candidates
            guard !options.isEmpty else { continue }
            // Danger runes carry their tier shift on the profile rather than on `enemyTierDelta`,
            // and the preview has to cover both or it promises a range the world doesn't honour.
            let tiers = options.map { $0.enemyTierDelta + ($0.danger?.tierDelta ?? 0) }
            tierLow += tiers.min() ?? 0
            tierHigh += tiers.max() ?? 0
            sightLow += options.map(\.visionDelta).min() ?? 0
            sightHigh += options.map(\.visionDelta).max() ?? 0
        }

        // **Stability is not additive any more**, so it can't be summed slot by slot like the rest.
        // Greed is measured off resolved abundance, and two ore symbols pushing the same subject
        // stack with diminishing returns — so the chosen symbols are resolved *together*, exactly as
        // the bind will resolve them, and only the slots left to chance widen the band.
        //
        // A fully specified draft therefore matches its bound book to the point, which is what the
        // legibility pillar asks for: the preview cannot promise a number the world won't honour.
        let chosenBook = BoundBook(
            symbols: plans.reduce(into: [SlotID: SymbolID]()) { if let c = $1.chosen { $0[$1.slot] = c.id } },
            randomlyFilled: [],
            essencePaid: 0)
        let settled = BookRules.stabilityDelta(
            of: chosenBook,
            sigils: BookRules.sigils(for: chosenBook),
            contradictionPenalty: BookRules.contradictionPenalty(of: chosenBook))

        var stabilityLow = settled, stabilityHigh = settled
        for plan in plans where plan.chosen == nil && !plan.candidates.isEmpty {
            let deltas = plan.candidates.map { BookRules.stabilityDelta(ofSymbolAlone: $0.id) }
            stabilityLow += deltas.min() ?? 0
            stabilityHigh += deltas.max() ?? 0
        }

        let scoreLow = BookRules.stabilityScore(delta: stabilityLow)
        let scoreHigh = BookRules.stabilityScore(delta: stabilityHigh)
        let turnsLow = BookRules.turnsAvailable(stabilityScore: scoreLow)
        let turnsHigh = BookRules.turnsAvailable(stabilityScore: scoreHigh)
        let sightFloor = max(Tuning.World.minimumVisionRadius, sightLow)
        let sightCeiling = max(sightFloor, sightHigh)

        // Exact, not ranged: you pay for what you chose, plus a flat rate per slot left to chance.
        let cost = BookRules.bindCost(
            chosenSymbolIDs: plans.compactMap { $0.chosen?.id },
            randomSlots: plans.count { $0.isRandom && !$0.isEmpty }
        )

        // Described from what's *written*, with the seed filling the rest — so the panel talks
        // about the world you'll actually get, chance-filled slots included.
        let book = BookRules.resolveBook(draft: draft, ownedSymbols: ownedSymbols, seed: seed)
        let sigils = BookRules.sigils(for: book)
        let readings = PressureRules.resolve(sigils, fillingUnwrittenWith: seed)

        return BookProjection(
            slotPlans: plans,
            essenceCost: cost...cost,
            stabilityScore: scoreLow...max(scoreLow, scoreHigh),
            turnsUntilCollapse: turnsLow...max(turnsLow, turnsHigh),
            enemyTier: max(1, tierLow)...max(1, max(tierLow, tierHigh)),
            visionRadius: sightFloor...sightCeiling,
            mapWidth: Tuning.World.gridWidth,
            mapHeight: Tuning.World.gridHeight,
            worldDescription: DescriptionRules.describe(
                readings,
                contradictions: ContradictionRules.fired(in: sigils, readings: readings),
                analysisTier: analysisTier
            ),
            dangerCapShortfall: BookRules.dangerCapShortfall(symbolIDs: book.allSymbolIDs),
            resourceMix: expectedResourceMix(in: readings),
            life: LifeRules.projection(for: readings)
        )
    }

    /// **How far a roll could move the headline**, sampled across seeds.
    ///
    /// Sampled rather than derived: what an unwritten subject rolls is a whole sigil with its own
    /// deltas and its own capacity to contradict what you wrote, and there's no closed form for
    /// that. Twenty seeds is enough to find the shape of the band without being expensive — this
    /// runs on every keystroke at the Writing Desk.
    private static func rolledStabilitySpread(sigils: [Sigil], page: Page, book: BoundBook,
                                              seed: UInt64) -> ClosedRange<Int> {
        var lowest = Int.max, highest = Int.min
        for sample in 0..<Tuning.Book.stabilitySamples {
            let seeded = seed &+ UInt64(sample) &* 0x9E3779B97F4A7C15
            let filled = sigils + PressureRules.rollUnwritten(after: sigils, seed: seeded)
            let readings = PressureRules.resolve(filled)
            let fired = ContradictionRules.fired(in: filled, readings: readings)
            let score = BookRules.stabilityScore(
                delta: BookRules.stabilityDelta(
                    of: book,
                    sigils: filled,
                    contradictionPenalty: ContradictionRules.totalPenalty(for: fired)))
            lowest = min(lowest, score)
            highest = max(highest, score)
        }
        guard lowest <= highest else { return 0...0 }
        return lowest...highest
    }

    /// **What this world will actually pay**, off the same readings the bind will use.
    ///
    /// It used to give every resource in the catalogue the same flat weight and then adjust by the
    /// legacy per-symbol `yieldModifiers`, which almost nothing sets. With four resources that read
    /// as "a bit of everything"; with twenty-one it promised **Adamant, Gold and Mercury at 5% each
    /// on a lightless world with no substrate written** — a preview that couldn't come true.
    ///
    /// The world's own pressures decide this everywhere else (`audit-what-pressures-actually-do.md`
    /// §4.1) — node placement since that audit, kill drops as of today. This was the last caller
    /// still describing a world it wasn't generating.
    private static func expectedResourceMix(
        in readings: PressureReadings
    ) -> [(resource: ResourceDef, share: Double)] {
        BookRules.shares(BookRules.yieldTable(from: readings))
            .compactMap { entry in
                ContentCatalog.shared.resource(entry.value).map { (resource: $0, share: entry.share) }
            }
            .sorted { $0.share > $1.share }
    }

}

extension ClosedRange where Bound: Equatable {
    /// A range whose ends match is really just a number — the UI reads this to drop the "–".
    var isPoint: Bool { lowerBound == upperBound }
}
