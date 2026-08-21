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

## Runtime-composable shelf growth

The Library is assembled from reusable paper, folio, cover, spine, slip and label sprites. Empty, early and
developed are **test inputs**, not authoritative baked shelf images. The saved game owns only real knowledge;
a pure presentation adapter emits stable collection/object IDs and counts, and the renderer deterministically
composes the bookcase every time. Adding one record changes only its owning object or adds its one new volume.
It never swaps the whole Library to a separately painted state.

Every individual developing object uses this base grammar:

| Count | Stage | Visual form |
|---:|---:|---|
| 0 | 0 | absent object; the category's fixed physical label and empty shelf remain |
| 1 | 1 | one folded paper/loose card |
| 2–3 | 2 | clipped or stitched folio |
| 4–6 | 3 | thin softbound volume |
| 7–9 | 4 | substantial hardcover |
| 10+ | 5 | full hardcover with additional slips/bookmarks; never thicker indefinitely |

Do not normalize these bands differently per diary. A longer late-game diary can remain a developed book for
longer without making an earlier diary inflate faster. Reusable variants may change spine width, height,
binding, hue, wear, bands and small geometric motifs, but every choice is seeded by the stable object ID and
remains readable in grayscale. Colour never discloses identity or meaning by itself.

### Diary shelf

Every legitimately encountered traveller with at least one recovered page has one stable diary object ordered
by authored campaign order. An undiscovered or zero-page traveller has no named spine or silhouette. That
traveller's own recovered-page count alone drives loose page → folio → softbound → hardcover → full hardcover.
Collecting another page grows the same object; encountering another diary adds another independently seeded
book. When one row no longer fits, deterministic overflow uses a second tight row/stack inside the Diaries
region; it never drops an owned diary or adds an undiscovered filler spine.

Tapping the Diaries shelf opens the existing six-across traveller-diary collection; tapping a traveller opens
their exact page sequence. Missing pages are honest blanks within an encountered diary, not invented teaser
prose.

### Bestiary shelf

Bestiary is a real multi-volume set divided into **Land, Shore, Water and Air** families. A habitat family is
absent at zero legitimately known species. It adds one physical volume for every started group of eight
species; within the current volume, 1–2 entries use a thin form, 3–5 a medium form and 6–8 a full form. Volume
number and habitat are physical spine marks and remain distinguishable without colour. Deep-water-only
sightings may enter Water after legitimate visibility; their inaccessible state does not block recording the
sighting.

Species remain silhouette-led tiles. Encountering, fighting, defeating and analyzing remain distinct facts;
the shelf does not turn a sighting into a specimen or expose undiscovered material yields.

### Dictionary shelf

Dictionary is exactly three possible indexed volumes for the current 21-rune catalogue. Volume I owns runes
1–7 in canonical rune order, Volume II owns 8–14, and Volume III owns 15–21. A volume appears when its first
rune is encountered; its current thickness uses 1–2 / 3–5 / 6–7 encountered-entry bands. Known meanings
decide readable entry text, not whether the physical entry exists. Unknown encountered runes use a `??`
slip/mark and never reveal meaning through shelf title, order, colour, motif or accessibility copy.

### Field Notes shelf

Field Notes adds one worn numbered notebook for each started group of eight distinct saved notes. The current
last notebook thickens at 1–2 / 3–5 / 6–8 entries. Opening groups notes by world thumbnail/identity before
individual note text. This surface consumes the structured truthful note receipt; it does not regenerate
prose and does not display the old generic “firmer way” sentence.

### World History shelf

World History adds one numbered atlas volume for each started group of eight immutable visited-world records.
The current last atlas thickens at 1–2 / 3–5 / 6–8 records. Opening leads with visual world
objects/thumbnails and concrete receipts, not a full-width prose ledger. Anchored Realm management remains
elsewhere; History records it but does not become its control panel.

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

1. One empty 184×260 logical bookcase shell with all five fixed shelf hotspots/labels and no fabricated
   contents.
2. Reusable loose/folded page, stitched folio, softbound, hardcover, full-hardcover-with-slips and varied
   spine/volume sprites at native and 400%; stable IDs control variants.
3. A deterministic compositor/manifest with bounded shelf sockets. Empty, early and developed 368×800 proofs
   are rendered from input records rather than stored state bitmaps.
4. Per-traveller Diary fixtures proving one page-count change mutates only that diary and one new traveller
   adds exactly one independently seeded object.
5. Bestiary habitat-volume boundaries 8→9 and Dictionary boundary 7→8, including a Water volume with shallow
   and deep-water sightings without implying both are reachable combat.
6. Independent shelf attention and checked states in colour and grayscale/value.
7. Collision/disclosure overlay proving targets, labels, owned objects and empty undiscovered space remain
   distinct.

Asset Design may not add a sixth shelf, research tree, fabricated book title, undiscovered traveller/species
or new knowledge type to balance the composition.

## Engineering checkpoints

1. Add one pure `LibraryShelfPresentation` adapter deriving stable shelf and collection-object IDs, canonical
   order, exact counts/volume numbers, form stage, attention count and enabled route from current state.
2. Move the Bestiary route under Library while preserving its stable destination, deep links and Back state.
3. Implement per-traveller Diary growth from recovered-page counts; no separate visual-stage persistence.
4. Add shelf-level unchecked-content receipts using the shared attention-event semantics.
5. Integrate the empty bookcase shell, reusable collection sprites and deterministic compositor behind a
   reversible DEBUG route; do not package empty/early/developed as three state images.
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
