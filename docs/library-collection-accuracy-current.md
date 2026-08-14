# Library collection accuracy — current correction brief

**Status:** implemented and integrated at `7a798a6` / `de2b71b`; 916-test shared checkpoint green;
explicit current-phone acceptance remains.  
**Owner:** Game Design owns author/subject semantics; Engineering owns integration; Aimee owns phone
acceptance and final page/character art.  
**Raised by:** Aimee's 10 Aug 2026 device playtest: “The page section of the library doesn't seem
accurate.”

## Audit finding

The underlying recovered-page set is authoritative: `LibraryState.foundPages` stores stable page IDs,
and current presentation tests require every recovered page to appear exactly once. The confusing
part is the collection model, not evidence yet of missing save data.

The current People tab groups pages by **diary author**. Some location and relationship pages are
written by one traveller but describe another. A player looking for everything known about Isolde,
for example, can reasonably interpret an Isolde tile as “pages about Isolde,” while the screen means
“pages written by Isolde.” The tile says only “N recovered,” so this distinction is concealed. That
can make a mechanically complete collection look inaccurate.

The detail screen then mixes two different bodies of evidence:

- **Where they went** gathers signature passages about the selected traveller, regardless of author.
- **Recovered diary** contains only pages authored by the selected traveller, regardless of subject.

Both are valid views, but they must not share an unlabeled count or imply they are the same set.

### Live implementation audit — 11 Aug 2026

`LibraryView` currently has only **People / World Notes / History**. `LibraryPresentation.people`
makes a person visible when they are known, found, **or merely the author of a recovered page**, and
the tile count comes from `pages(by:)`, which filters on `page.diary`. The People tile therefore
still says a bare `N recovered` for pages **written by** that person. It does not count pages whose
`about` field names them.

Opening that tile then combines `LibraryRules.hintPage` — location evidence **about** the traveller —
with `Recovered diary`, which is writing **by** the traveller. This confirms the reported inaccuracy
is present in the current native screen; it is not merely an older documentation concern.

The same screen still renders every diary page as full-width prose inside a `StationCard`. That also
conflicts with the settled compact collection grammar and makes a larger 5–10-page diary
unnecessarily scroll-heavy. The correction should add the missing Diaries index and page tiles as
one coherent checkpoint rather than relabeling the current People count and leaving the underlying
navigation ambiguous.

## Settled presentation model

The Library has two complementary indexes over one stable recovered-page set:

1. **Diaries — written by:** one book per author, containing every recovered page whose `diary`
   field names that author.
2. **People — known about:** one dossier per known traveller, containing recovered location and
   relationship evidence whose `about` field names that traveller, plus their assembled whereabouts
   passage.

A page may be reachable through both indexes, but it remains one recovered object. Counts always
name their basis: **“4 pages written”** and **“3 clues about them,”** never bare “4 recovered.” History,
World Notes and learned vocabulary remain separate collections.

This is an intentional exception to the earlier “one top-level home” UI shortcut. That shortcut
prevented duplicate cards but erased a useful cross-reference. The data must still deduplicate by
stable page ID; the Library may provide multiple routes to the same record just as a real catalogue
does.

## Screen shape

- Top tabs: **Diaries / People / World Notes / History**.
- Diaries and People use compact square identity tiles rather than full-width rows.
- A diary tile shows author portrait/mark, name and `N pages written`.
- A person tile shows identity, current status and `N clues about them`; it does not use pages written
  by them as progress toward finding them.
- Selecting a tile opens a page grid. Page tiles use a visible page-kind glyph and a short first-line
  fragment; full prose and teaching/research consequences open on tap.
- Learned Focus, gambit, pattern or research rewards receive a small redundant corner badge. The
  page's prose remains primary and the badge never exposes unrecovered information.
- Unknown authors/subjects are not manufactured as silhouettes merely because their catalogue entry
  exists. Visibility derives only from recovered writing, a world encounter or recruitment.

## Accuracy rules

1. Every `foundPages` ID resolves to live authored content or appears in an explicit **Older record**
   recovery group; silent omission is forbidden.
2. Diary counts equal recovered pages grouped by `diary`.
3. Person clue counts equal recovered pages grouped by `about`, not by `diary`.
4. A page with both fields may appear through both routes but opens the same stable page ID.
5. Pages with no `about` value never inflate a person's clue progress.
6. Location signature progress counts only the correct unique `clueIndex` for that person; duplicate
   or relationship pages do not fill a missing signature piece.
7. Recruitment changes status to At Home but does not invent unread pages or complete page counts.
8. Sorting is deterministic: authored traveller order for people/diaries, recovered sequence within
   a book unless the player explicitly selects another sort.

## Acceptance proof

- Seed a recovered page written by Tovin about Isolde. It appears in Tovin's Diary and Isolde's
  People dossier, with one stable ID and no doubled global count.
- Seed one Isolde page that is not about Isolde. Her diary count rises; her dossier clue count does
  not.
- Seed two pages for the same signature index. The dossier shows both records but only one assembled
  clue position.
- Recruit a person with an incomplete dossier. At Home appears while missing clues remain visibly
  missing.
- Decode an older save containing an unknown page ID. The Library shows an Older record tile instead
  of dropping it.
- At 368×800 and large text, the four tabs, square collection grid and tapped detail remain reachable;
  VoiceOver announces author/subject basis, page kind, reward state and position in the collection.

## Scheduling and current evidence

This did not interrupt the Recycler/world-control checkpoint. The correction shipped inside the
integrated `de2b71b` collection/field slice and its shared 916/916 test checkpoint; it is not a new
implementation request. The remaining gate is explicit phone confirmation that current campaign
pages/counts make sense at ordinary size, including a cross-author page and Older record if available.

## Implementation candidate — 11 Aug 2026

The native Library now exposes **Diaries / People / World Notes / History**. Diary tiles and counts
use the author axis; People tiles and clue grids use the subject axis; cross-diary pages remain one
stable recovered ID. Both detail collections use compact page tiles rather than rendering 5–10 full
passages in a long card. Unknown recovered IDs appear in an explicit Older records group instead of
being dropped by `compactMap`.

The implementation was committed first as `7a798a6`, then included in the broader `de2b71b` shared
checkpoint. Focused axis/deduplication tests and the 916-test product run passed. Later installed
builds include those commits; acceptance remains `readyToTest`, not design or code incomplete.
