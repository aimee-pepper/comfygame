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
    /// **What will grow here**, on the same terms and for the same reason. Read first in the panel,
    /// because a world's animals stand on its plants: no viable metabolism means no producers, and
    /// no producers means nothing above them either (`flora-system-spec.md` §7).
    var flora: FloraRules.FloraProjection = FloraRules.FloraProjection(kindCount: 0, metabolism: nil, notes: [])
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

    /// **The subjects this page says nothing about**, which are the ones that will be rolled.
    ///
    /// This is the page's answer to a question the old slot taxonomy used to ask: what is left to
    /// chance. It was `slotPlans.allSatisfy { !$0.isRandom }` — and on a page every plan carries a
    /// mark, so the preview said "fully specified" about a book with one word on it and seven
    /// subjects still to roll. Uncertainty moved from slots to subjects and the readout didn't.
    var unwrittenSubjects: [PressureTargetID] {
        ContentCatalog.shared.pressureTargetsInOrder
            .map(\.id)
            .filter { !writtenSubjects.contains($0) }
    }
    /// True when the page speaks to every subject, so nothing is rolled and every range is a point.
    var isFullySpecified: Bool { unwrittenSubjects.isEmpty }
    /// What this book will cost, exactly. Known before committing — see the note above.
    var cost: Int { essenceCost.lowerBound }

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

        return BookProjection(
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
            flora: FloraRules.projection(for: readings),
            marksWritten: page.runes.count,
            marksSpeaking: PageRules.sigils(of: page).count,
            chains: PageRules.chains(on: page),
            writtenSubjects: Set(sigils.map(\.target))
        )
    }

    /// **How far a roll could move the headline** — the *worst and best cases*, not a sample of them.
    ///
    /// **This was sampled, and sampling is not a bound.** Twenty seeds found the shape of the band
    /// and missed its tails: a page with one mark on it was shown `3–100` and could resolve to `0`,
    /// which is the legibility pillar broken — *the preview may not promise a number the world
    /// won't honour*. The old slot path got this right by taking the extremes of what each empty
    /// slot could hold, and `fossil-audit.md` §5 warned that it held "the only correct
    /// stability-range logic in the codebase". It was right. This is that logic, on the page.
    ///
    /// For each silent subject, the calmest and the greediest thing that could land on it is found
    /// **in isolation** — that ranking is a property of the vocabulary, not of this page — and then
    /// the two extreme worlds are resolved *whole*, so diminishing returns and contradiction are
    /// priced exactly as the bind will price them. Two resolutions instead of twenty, and it runs
    /// on every keystroke at the desk.
    private static func rolledStabilitySpread(sigils: [Sigil], page: Page, book: BoundBook,
                                              seed: UInt64) -> ClosedRange<Int> {
        var calmest: [Sigil] = [], greediest: [Sigil] = []
        var identifier: UInt64 = 0

        let written = Set(sigils.flatMap { sigil in
            ContentCatalog.shared.pressureSource(sigil.source)?.targets ?? []
        })
        for target in ContentCatalog.shared.pressureTargetsInOrder where !written.contains(target.id) {
            let pool = ContentCatalog.shared.pressureSources
                .filter { $0.contribution(to: target.id) != nil }
                .sorted { $0.id.rawValue < $1.id.rawValue }
            guard !pool.isEmpty else { continue }

            // Every intensity a roll can produce, since a great sun and a faint one are not the
            // same ask — `rollUnwritten` picks both the source and how loudly it speaks.
            let intensities = Intensity.allCases.filter { $0 != .absent }
            var best: (Sigil, Int)?, worst: (Sigil, Int)?
            for source in pool {
                for intensity in intensities {
                    identifier += 1
                    let candidate = Sigil(id: InstanceID(rawValue: identifier),
                                          source: source.id, target: target.id, intensity: intensity)
                    let delta = BookRules.stabilityDelta(of: book, sigils: [candidate],
                                                         contradictionPenalty: 0)
                    if best == nil || delta > best!.1 { best = (candidate, delta) }
                    if worst == nil || delta < worst!.1 { worst = (candidate, delta) }
                }
            }
            if let best { calmest.append(best.0) }
            if let worst { greediest.append(worst.0) }
        }
        guard !calmest.isEmpty else {
            let settled = BookRules.stabilityScore(of: book)
            return settled...settled
        }

        // …and then price each extreme world whole, because stability is not additive.
        func score(_ rolled: [Sigil]) -> Int {
            let filled = sigils + rolled
            let readings = PressureRules.resolve(filled)
            let fired = ContradictionRules.fired(in: filled, readings: readings)
            return BookRules.stabilityScore(
                delta: BookRules.stabilityDelta(
                    of: book,
                    sigils: filled,
                    contradictionPenalty: ContradictionRules.totalPenalty(for: fired)))
        }
        let low = score(greediest), high = score(calmest)
        return min(low, high)...max(low, high)
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
