# Traveller clue distribution — current balance audit

**Status:** implementation recommendation downstream of traveller targeting  
**Date:** 11 August 2026  
**Scope:** which unrecovered diary page becomes the world's diary writing; not the one-writing floor,
prose, traveller eligibility or Seek semantics

## Current evidence

The live corpus contains **238** diary pages, including **138 location clues**. World generation
guarantees one writing, gives it a 70% diary share, and has a 10% chance of a second writing. Under
the current first/second-writing logic, a world has a diary page about 73% of the time and otherwise
has field writing; this respects the settled “at least one kind of writing per world” rule.

The problem is not the overall diary rate. `LibraryRules.placePages` currently weights **individual
pages**. A traveller with ten signature conditions owns ten location pages while an opening person
may own one. Before contextual weighting, the longer late book therefore contributes roughly ten
times as many lottery entries. Aimee explicitly approved longer late books, but page count was never
intended to make their owners proportionally more common in early campaigns.

The existing one-page patience nominee is sound: only one mismatched page reaches universal
eligibility at a time, so the old eight-world fallback cannot release a simultaneous flood. Preserve
that exact-page guarantee.

## Recommendation — choose a subject bucket, then a page

For ordinary diary selection:

1. Partition eligible unrecovered pages into stable **discovery buckets**.
   - A location clue uses its `about` traveller as the bucket.
   - Every other diary page uses its `diary` author as the bucket.
2. Calculate the authored contextual weight for each page exactly as today, but normalize the
   bucket's combined weight by its eligible page count. Longer books therefore offer more possible
   pages after their person is selected, not more chances for that person to be selected.
3. Select one bucket deterministically from those normalized weights.
4. Select one page inside it, retaining the existing at-home preference and stable-ID tie behavior.
5. If the exact patience nominee is due, place it first exactly as today and bypass the ordinary
   bucket lottery for that world.

This is not strict equal-frequency distribution. A world that genuinely resembles a person's
authored context should still lean toward their pages, and the blind opening sequence may later add
an explicit relevance multiplier. Normalization removes only the accidental multiplier caused by
having more pages in the book.

## Relationship to Seek

The recommended writing-screen Seek selector requires at least one recovered exact location clue.
This audit does not guarantee every person a clue on a schedule and does not reveal an unknown
roster. It ensures only that:

- a ten-condition late person does not dominate the clue lottery merely by having ten entries;
- several different known leads can emerge over a long campaign;
- seeking somebody never manufactures another page or changes diary probability; and
- world-context preference plus the one-at-a-time patience fallback remain meaningful.

If Seek is not approved, normalized clue distribution is still correct: longer authored books should
not independently alter whose evidence is common.

## DEBUG evidence

Add a non-player-facing distribution receipt over seeded generated worlds:

- diary versus other-writing totals;
- location versus non-location diary totals;
- selected discovery bucket and exact page;
- contextual weight, normalized bucket weight and patience override;
- page counts per traveller alongside selection counts.

Expose no hidden person, condition or weight in Release UI.

## Acceptance

1. Every generated world contains at least one successfully placed writing when a valid writing tile
   exists; the current diary/other-writing split and optional second writing remain unchanged.
2. Synthetic one-page and ten-page travellers with identical context receive equal aggregate bucket
   weight, while all ten late pages remain individually reachable.
3. A genuinely at-home bucket remains more likely than an otherwise equal mismatched bucket.
4. A due patience nominee is placed immediately, advances only its one clock and does not make every
   waiting page eligible.
5. Catalogue/page array shuffles, relaunch and identical seeds preserve the selected stable page ID.
6. Found pages never re-enter; exhausted buckets disappear without redistributing hidden roster
   metadata into player-facing UI.
7. A seeded early/mid/late campaign report shows page-count-per-book is not itself predictive of
   aggregate subject selection after contextual facts are controlled.
