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
        ContentCatalog.shared.travellers.filter { $0.isFound(in: readings) }
    }

    // MARK: Finding pages

    /// Which pages could surface in a given world.
    ///
    /// A page prefers a world its author would have had reason to be in. That preference is soft:
    /// once a page has waited longer than the threshold it will surface anywhere, because nothing
    /// may become permanently unreachable through how a player happens to write.
    static func eligiblePages(in readings: PressureReadings, library: LibraryState) -> [DiaryPageDef] {
        ContentCatalog.shared.diaryPages.filter { page in
            guard !library.hasFound(page.id) else { return false }
            if page.prefersConditions.isEmpty { return true }
            if page.prefersConditions.allSatisfy({ $0.holds(in: readings) }) { return true }
            return (library.pagesWaiting[page.id] ?? 0) >= Tuning.Library.patienceInWorlds
        }
    }

    /// Choose the pages a world will contain. Deterministic in the run's seed.
    static func placePages(in readings: PressureReadings, library: LibraryState,
                           rng: inout SeededRNG) -> [DiaryPageID] {
        let candidates = eligiblePages(in: readings, library: library)
            .sorted { $0.id.rawValue < $1.id.rawValue }
        guard !candidates.isEmpty else { return [] }

        let count = min(candidates.count, rng.int(in: Tuning.Library.pagesPerWorldRange))
        var pool = candidates
        var chosen: [DiaryPageID] = []
        for _ in 0..<count {
            guard !pool.isEmpty else { break }
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
    static func hintPages(in library: LibraryState) -> [HintPage] {
        ContentCatalog.shared.travellers
            .filter { library.knownTravellers.contains($0.id) || library.foundTravellers.contains($0.id) }
            .map { hintPage(for: $0, library: library) }
            .sorted { ($0.isFound ? 1 : 0, $0.traveller.name) < ($1.isFound ? 1 : 0, $1.traveller.name) }
    }
}
