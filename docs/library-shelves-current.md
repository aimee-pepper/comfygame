# Library shelves and growing collection — current

**Status:** Game Design implementation authority for the Library's root spatial surface and collection-growth
presentation. It relocates Bestiary navigation inside the Library without changing Bestiary persistence,
species knowledge or diary-page rules.
**Priority:** after the first-world causal presentation baseline and before adding more full-width Library
lists or late archival systems.
**Owners:** Game Design owns shelf taxonomy and growth receipts; Asset Design owns the bookcase/shelf/book grammar;
Engineering owns routes, derived fill stages and existing collection consumers; Aimee owns final visual
acceptance.
**Updated:** 21 August 2026

## Player outcome

The Library is a place the player recognizes and watches fill, not a tab strip leading to five long lists.
The Binder House cutaway shows the wider Library area. Opening that hotspot moves to a close-up of **one
large bookcase or, only if native target geometry requires it, two adjoining bookcases**. The case fills most
of the destination viewport and its physical shelves are the five category controls. Do not repeat the whole
room, add navigable furniture or turn the destination into a miniature interior scene. Loose paper becomes
folders, pamphlets and increasingly substantial books as the underlying collections grow.

The art reflects real saved knowledge only. It never fabricates books, species, pages or world history to
make the room look fuller.

## Root shelves

The opening Library contains exactly five shelf destinations:

| Shelf | Existing content it opens | Primary growing object |
|---|---|---|
| **Diaries** | traveller diaries/pages and clues | one developing book per encountered traveller |
| **Bestiary** | generated species and legitimately learned creature records | field folios grouped by habitat, opening to species tiles |
| **Dictionary** | encountered and known runes/compound vocabulary | indexed rune folio/lexicon |
| **Field Notes** | truthful generated local notes recovered from worlds | notebooks grouped by world |
| **World History** | visited/bound world records and immutable receipts | atlas/history volumes |

Do not retain Bestiary as a separate Binder-House hotspot or top-level Base category. Bestiary remains in the
Reality/persistent knowledge layer internally; this is a navigation and presentation change only.

Constellation remains a separate House destination because it is an active progression/build surface, not a
book collection. Writing Desk Pages/Templates remain at the Writing Desk, not moved into Library merely
because they are paper.

## Ordinary-phone composition

At 368×800, all five shelf identities fit in the initial Library viewport without scrolling required solely
to discover a category. Recommended composition is one close-up case with two wide shelves above a
three-shelf lower cabinet. Two adjoining cases are the only alternate, and only when that produces
materially better 44×44 shelf targets.

Each shelf hotspot includes:

- its recognizable object cluster/silhouette;
- short shelf name on a physical label/brass card;
- compact real count or progress marker;
- truthful attention glow only when new unchecked content exists;
- a minimum 44×44 tap target included in the shelf geometry.

Do not render five modern full-width navigation cards over a decorative bookcase. Labels support the object;
they are not the whole interface.

## Derived shelf growth

Growth stage is derived from the underlying collection count; it is never separately purchased or saved.
For a collection with count `n`, use:

| Count | Stage | Visual form |
|---:|---:|---|
| 0 | 0 | empty labelled space or closed silhouette; no fabricated title |
| 1 | 1 | one folded paper/loose card |
| 2–3 | 2 | clipped or stitched folio |
| 4–6 | 3 | thin softbound volume |
| 7–9 | 4 | substantial hardcover |
| 10+ | 5 | full hardcover with additional slips/bookmarks; never thicker indefinitely |

For collections whose natural maximum is below ten, normalize these thresholds against the authored maximum
while preserving the same five nonempty visual stages. The adapter supplies both current count and authored
maximum; Asset code does not guess maximum from array length.

### Diary shelf

Every encountered traveller has one stable diary position ordered by authored campaign order. An
undiscovered traveller has no named spine or silhouette. For one traveller, recovered page count drives the
stages above: first page is folded paper; later pages become a folio, softbound book and hardcover volume.
Longer late-game diaries may reach the full stage without changing earlier travellers' thresholds.

The shelf may show several developing books simultaneously. Tapping the Diaries shelf opens the existing
six-across traveller-diary collection; tapping a traveller opens their exact page sequence. Missing pages are
honest blanks within an encountered diary, not invented teaser prose.

### Bestiary shelf

Bestiary root growth uses number of legitimately encountered species. Inside it, habitat folios—Land, Shore,
Water and Air—appear only when at least one known species belongs there. Deep-water-only sightings may enter
Water after legitimate visibility; their inaccessible state does not block recording the sighting.

Species remain silhouette-led tiles. Encountering, fighting, defeating and analyzing remain distinct facts;
the shelf does not turn a sighting into a specimen or expose undiscovered material yields.

### Dictionary shelf

Growth uses number of encountered rune identities, while known meanings determine how many indexed entries
are readable. Unknown encountered runes may contribute visible loose tracings marked `??`; they never reveal
meaning through shelf title, order, colour or accessibility copy.

### Field Notes shelf

Growth uses distinct saved Field Notes. Opening groups notes by world thumbnail/identity before individual
note text. This surface consumes the structured truthful note receipt; it does not regenerate prose and does
not display the old generic “firmer way” sentence.

### World History shelf

Growth uses immutable visited-world records. Opening leads with visual world objects/thumbnails and concrete
receipts, not a full-width prose ledger. Anchored Realm management remains elsewhere; History records it but
does not become its control panel.

## New-content attention

Each shelf receives one monotonic unchecked-content receipt keyed to the underlying new record/page/species.
The shelf glows with the same restrained warm-gold attention grammar as village buildings. Opening the shelf
and rendering the newly added objects marks those receipts checked; merely entering the Library does not.

Diary attention may clear only for the exact diary whose new page was rendered. Several new records create
one shelf glow plus a compact count, not one flashing badge per book.

## Detail screens

Inside a shelf, use the six-across icon/object grammar where the content is a collection. Tapping a book,
species, rune, note or world opens anchored/on-screen detail when the information is compact; a genuine
multi-page diary or full world record may use its dedicated reading surface. Returning restores shelf and
scroll/focus position.

The Library root never falls back to a top tab bar as its primary navigation. Search/filter belongs inside a
populated shelf, not over the room before a shelf is chosen.

## Asset Design packet

1. Ordinary 368×800 Library root with all five shelf hotspots, labels and counts.
2. Empty, early and developed variants driven by one exact collection receipt set.
3. One traveller diary shown at folded page, stitched folio, softbound, hardcover and full-volume stages.
4. Bestiary Water folio with shallow and deep-water sightings, without implying both are reachable combat.
5. One shelf attention state and checked state in color and grayscale/value.
6. Collision overlay proving all shelf targets and labels remain distinct.

Asset Design may not add a sixth shelf, research tree, fabricated book title, undiscovered traveller/species
or new knowledge type to balance the composition.

## Engineering checkpoints

1. Add one pure `LibraryShelfPresentation` adapter deriving stable shelf ID, real count, authored maximum,
   growth stage, attention count and enabled route from current state.
2. Move the Bestiary route under Library while preserving its stable destination, deep links and Back state.
3. Implement per-traveller Diary growth from recovered-page counts; no separate visual-stage persistence.
4. Add shelf-level unchecked-content receipts using the shared attention-event semantics.
5. Integrate the functional close-up bookcase asset behind a reversible DEBUG route, then promote after phone proof.
6. Convert shelf collection children to the settled icon/object grammar without rewriting their domain rules.

## Acceptance

1. All five shelf destinations are recognizable and reachable in the initial ordinary-phone viewport.
2. Empty/1/2/4/7/10-count fixtures produce exactly the specified stages without fabricated knowledge.
3. Every current traveller's diary stage derives from their own page count, not total Library pages.
4. Bestiary is reachable only through Library/root deep links and retains every existing record across
   migration/relaunch.
5. Unknown runes and undiscovered creatures/travellers leak no identity or meaning through art/copy/order.
6. Attention survives relaunch and clears only after exact new content renders.
7. Back returns to the same shelf/character/world focus; no unnecessary root list/tab replacement appears.

## Explicit exclusions

- no library walking avatar;
- no book-arranging minigame;
- no shelf capacity or knowledge loss;
- no Lys implementation merely to unlock the root room;
- no fabricated flavour books used as navigation;
- no tutorial pass.
