import Foundation

/// Finding people, and finding the pages that say where they are.
///
/// The two are deliberately independent. **Pages are a guide, never a gate**: a traveller is simply
/// *at* a signature, so a player who writes the right world — deliberately or by luck — finds them
/// without ever having read a page. A lucky early clue leading to a late-game character is fine and
/// is not prevented anywhere in here.
enum LibraryRules {

    // MARK: Finding people

    /// Everyone whose signature this world satisfies.
    static func travellersPresent(in readings: PressureReadings) -> [TravellerDef] {
        ContentCatalog.shared.travellersInAuthoredOrder.filter { $0.isFound(in: readings) }
    }

    // MARK: Finding pages

    /// Which pages could surface in a given world.
    ///
    /// A page prefers a world its author would have had reason to be in. That preference is soft:
    /// once a page has waited longer than the threshold it will surface anywhere, because nothing
    /// may become permanently unreachable through how a player happens to write.
    static func eligiblePages(in readings: PressureReadings, library: LibraryState,
                              patienceInWorlds: Int = Tuning.Library.patienceInWorlds) -> [DiaryPageDef] {
        ContentCatalog.shared.diaryPages.filter { page in
            guard !library.hasFound(page.id) else { return false }
            if page.prefersConditions.isEmpty { return true }
            if page.prefersConditions.allSatisfy({ $0.holds(in: readings) }) { return true }
            return library.patiencePage == page.id
                && (library.pagesWaiting[page.id] ?? 0) >= patienceInWorlds
        }
    }

    /// Choose the pages a world will contain. Deterministic in the run's seed.
    static func placePages(in readings: PressureReadings, library: LibraryState,
                           additionalPageChance: Double = Tuning.Library.additionalPageChance,
                           patienceInWorlds: Int = Tuning.Library.patienceInWorlds,
                           rng: inout SeededRNG) -> [DiaryPageID] {
        let candidates = eligiblePages(in: readings, library: library,
                                       patienceInWorlds: patienceInWorlds)
            .sorted { $0.id.rawValue < $1.id.rawValue }
        guard !candidates.isEmpty else { return [] }

        let count = min(candidates.count, 1 + (rng.chance(additionalPageChance) ? 1 : 0))
        var pool = candidates
        var chosen: [DiaryPageID] = []

        // Once the nominated page reaches the fallback, the promise is paid immediately rather
        // than merely adding it to a large lottery where it could keep losing.
        if let nominee = library.patiencePage,
           (library.pagesWaiting[nominee] ?? 0) >= patienceInWorlds,
           pool.contains(where: { $0.id == nominee }) {
            chosen.append(nominee)
            pool.removeAll { $0.id == nominee }
        }
        for _ in 0..<count {
            guard chosen.count < count, !pool.isEmpty else { break }
            // Weighted toward pages whose author would have been here — a soft lean, not a filter.
            let weights = pool.map { page -> (value: DiaryPageDef, weight: Double) in
                let athome = !page.prefersConditions.isEmpty
                    && page.prefersConditions.allSatisfy { $0.holds(in: readings) }
                return (page, athome ? Tuning.Library.atHomeWeight : 1)
            }
            guard let picked = rng.pickWeighted(weights) else { break }
            chosen.append(picked.id)
            pool.removeAll { $0.id == picked.id }
        }
        return chosen
    }

    /// Advance exactly one mismatched-placement clock after generating a world.
    static func advancePatience(after placed: [DiaryPageID], library: inout LibraryState) {
        let found = Set(library.foundPages)
        if let nominee = library.patiencePage,
           !found.contains(nominee), !placed.contains(nominee) {
            library.pagesWaiting = [nominee: (library.pagesWaiting[nominee] ?? 0) + 1]
            return
        }

        let next = ContentCatalog.shared.diaryPages
            .map(\.id)
            .first { !found.contains($0) && !placed.contains($0) }
        library.patiencePage = next
        library.pagesWaiting = next.map { [$0: 0] } ?? [:]
    }

    // MARK: The Library

    /// What is known about where one traveller is.
    static func hintPage(for traveller: TravellerDef, library: LibraryState) -> HintPage {
        let known = library.knownClueIndices(for: traveller.id)
        return HintPage(
            traveller: traveller,
            passages: traveller.signature.indices.map { known.contains($0) ? traveller.signature[$0].passage : nil },
            isFound: library.foundTravellers.contains(traveller.id)
        )
    }

    /// Every diary the player has any reason to care about, hardest-known first.
    ///
    /// A traveller you've never heard of doesn't appear at all — the Library is what you know, not
    /// a checklist of what exists.
    /// Snapshot a world at the moment you enter it: what you wrote, and what it became.
    ///
    /// Taken here rather than at the Writing Desk because **the readings must include what rolled
    /// against you** — the unwritten targets the world decided for itself. That's the half a player
    /// can't see at the time and most wants to read later.
    static func record(book: BoundBook, page: Page, seed: UInt64, runIndex: Int,
                       travellers: [TravellerID]) -> VisitedWorld {
        let sigils = BookRules.sigils(for: book)
        let written = Set(sigils.map(\.target))
        let readings = BookRules.readings(for: book, seed: seed)
        let chains = PageRules.chains(on: page)

        var record = VisitedWorld(
            id: InstanceID(rawValue: seed),
            seed: seed,
            runIndex: runIndex,
            descriptionSentence: DescriptionRules.describe(readings, contradictions: [],
                                                           analysisTier: Tuning.Analysis.startingTier).sentence,
            written: chains.map { chain in
                "\(chain.target) ← " + chain.parts.map(\.phrase).joined(separator: " · ")
            },
            inertModifiers: chains.flatMap { chain in
                chain.parts.flatMap(\.qualifiers).filter(\.isInert).map { "\($0.name) on \(chain.target)" }
            },
            readings: Dictionary(uniqueKeysWithValues: readings.inOrder.map { reading in
                (reading.target.rawValue,
                 VisitedWorld.ReadingSnapshot(peak: reading.peak, floor: reading.floor,
                                              wasWritten: written.contains(reading.target),
                                              tags: reading.tags.sorted()))
            }),
            travellersPresent: travellers,
            focusAttributions: chains.flatMap { chain in
                chain.parts.flatMap { part in
                    part.effects.map { effect in
                        "\(part.source) → \(effect.target) \(effect.text)"
                            + (effect.isPrimary ? "" : " · secondary")
                    }
                }
            },
            focusEffects: chains.flatMap { chain in
                chain.parts.flatMap { part in
                    part.effects.map { effect in
                        RecordedFocusEffect(source: part.source,
                                            targetID: effect.targetID,
                                            target: effect.target,
                                            text: effect.text,
                                            isPrimary: effect.isPrimary)
                    }
                }
            },
            semanticRequests: TutorialRules.semanticRequests(on: page)
        )
        record.livingAnalysis = LivingAnalysisRules.analyze(readings)
        let clock = WorldClock(book: book, seed: seed)
        record.clockAnalysis = ClockAnalysis(band: clock.bandName,
                                             basePeriod: clock.basePeriod,
                                             regularity: clock.regularity,
                                             amplitude: clock.amplitude,
                                             isStopped: clock.isStopped)
        return record
    }

    static func hintPages(in library: LibraryState) -> [HintPage] {
        ContentCatalog.shared.travellersInAuthoredOrder
            .filter { library.knownTravellers.contains($0.id) || library.foundTravellers.contains($0.id) }
            .map { hintPage(for: $0, library: library) }
            .sorted { ($0.isFound ? 1 : 0, $0.traveller.name) < ($1.isFound ? 1 : 0, $1.traveller.name) }
    }
}
