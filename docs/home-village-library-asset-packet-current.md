# Binder House, village districts and Library — active AssetLab packet

**Status:** Active Asset Design assignment from the Game Design/Orchestration Lead. Trading Post v0.3, the
five opening Built/Tier-0 identities, Trading Post/Firepit state continuity, and Binder House v0.1 are accepted
Game-Design candidates. The only current art checkpoint is the close-up Library; later building families
remain held. AssetLab only; no native game, Xcode, gameplay schema, roadmap priority or Simulator lifecycle
changes.
**Repository status checked before dispatch:** shared tree reconciled against current status immediately
before the 21 August assignment; encounter scaling remains the sole Engineering source primary.
**Player outcome:** Home and Library become recognizable places instead of categories/lists while every
hotspot continues to mean only its already-settled destination.
**Updated:** 21 August 2026

## Required authorities, in order

Asset Design must read and apply these exact current authorities before editing:

1. `village-progression-and-asset-matrix-current.md` — exact destination kinds, districts, building
   tiers, per-asset functional referents, dimensions, camera, materials and review order;
2. `home-house-and-village-current.md` — spatial topology, district membership and attention semantics;
3. `library-shelves-current.md` — five shelves, derived collection stages and disclosure;
4. `workshop-constellation-role-audit-current.md` — Workshop removal and Constellation progression;
5. `asset-questions-decisions.md` — camera, ownership and established AssetLab constraints;
6. `asset-system-proposal.md` authored-place v0.4 final disposition — accepted station silhouettes;
7. `asset-production-output-contract-current.md` — reusable pixel products, quality and Chrome-review gate;
8. `AssetLab/artifacts/place-identity-adaptation-proof-v0.4.png` — functional collision reference only,
   not the final aesthetic bar;
9. approved UI style snapshot
   `AssetLab/reviews/approved-styles/75c4fe58789b8cb16b6587d439a87e5ec5cbed58f211cb8ebc1b0df0416da5a2.css`.

If an older document conflicts, these current design/decision authorities win. Report the conflict; do
not blend both versions.

The current rejected House/Library v0.1 working files remain technical infrastructure only. Resume art
from the **Style gate** in `village-progression-and-asset-matrix-current.md`; do not continue the interrupted
whole-batch bitmap candidate or infer missing details from it.

## Completed checkpoint 1 — Trading Post Tier-0 style gate

Produce one finished label-free `trading_post.built` sprite before drawing any other building, district,
House room or Library shelf. This is an aesthetic gate, not a request for another complete prototype.

- **Product:** one 96×80 logical-pixel transparent RGBA building sprite using the shared village camera,
  plus a 400% nearest-neighbour crop, literal grayscale crop and one Commerce Row placement at 368×800.
- **Identity:** a small timber merchant frontage with open counter, cloth awning, hanging balance, ledger,
  tagged shelves/crates and a secured coin drawer. Goods may vary, but the scale/ledger/counter must make
  Vance's buy/sell/appraisal role readable without words.
- **Continuity anchors reserved for later tiers:** the original counter, balance and primary awning must
  remain in Tier 1 and Tier 2. Do not draw those later tiers in this checkpoint.
- **Materials/light:** dark walnut structure, warmer worn counter, muted ochre/cream awning, cool slate
  shadows, restrained brass highlights and one warm task-light cluster. Use deliberate clusters, texture,
  wear and shadow; no broad flat placeholder rectangles.
- **Forbidden readings:** resource-conversion booth, bank, tavern, general house, treasure room, caravan map,
  supermarket or auction house. Do not use exchange arrows, a giant coin, text label or UI icon to carry the
  identity.
- **Source requirement:** direct production bitmap/pixel source with deterministic export metadata. HTML/CSS
  may frame review but may not depict the building. Preserve the existing technical exporter only where it
  can carry this actual art without raster alteration.
- **Technical evidence:** assert exact 96×80 dimensions, binary alpha only (`0` or `255`), nonempty transparent
  margins, nearest-neighbour-only scaling, a deliberate bounded palette (target no more than 64 opaque RGB
  colors unless Game Design accepts a specific exception), stable source/export hash and exact
  crop/placement identity. The source of truth is the 96×80 logical grid or an exact integer-multiple grid,
  never an antialiased high-resolution render sampled down. These gates prove transport only; the label-free
  visual review decides whether the sprite passes.
- **Stop condition:** send the lossless crop and phone placement to Game Design. Do not create Recycler,
  opening-five, House, Library, upgrade tiers, goldens or native integration before this sprite is accepted.

## Ownership and file boundary

Asset Lead owns only:

- a new isolated AssetLab proof page and its new AssetLab source/fixture/test/export files;
- reuse or extension of existing `place-kit.js` output through public, non-stale APIs;
- PNG/JSON review artifacts generated from the new proof;
- concise review/status additions to the Asset docs it already owns.

Asset Lead does **not** edit:

- `Sources/`, `Tests/` outside AssetLab, `Bookbinder.xcodeproj`, PBX files or native assets;
- playability-roadmap status/order;
- station/traveller/research/gameplay definitions;
- existing approved-golden hashes merely to make new work pass;
- Simulator windows or phone builds.

Preferred new surface names:

- `AssetLab/home-village-library.html`;
- `AssetLab/src/home-village-library-app.js`;
- `AssetLab/src/home-village-library-kit.js`;
- `AssetLab/tests/home-village-library.test.js`;
- a dedicated export script and versioned artifacts.

Do not overload `places.html` into a phone UI or rewrite `ui-gallery.html`.

## Established visual system: reuse, do not reinterpret

### Camera

- Binder House, Library interior and village buildings use the settled **2D side-view/cutaway** family.
- Generated world top-down rules do not apply to these screens.
- No isometric free-roam, walking avatar, 3D perspective, overhead town map or draggable camera.

### Phone shell and style

- Review at exact ordinary phone size **368×800**.
- Reuse the frozen approved UI font, palette, border, control and spacing tokens from the approved stylesheet.
- Pixel art uses integer coordinates, nearest-neighbour scaling and no accidental antialiasing.
- The full destination composition fits the region between existing safe/header/back and bottom navigation;
  no essential destination requires scrolling merely to be discovered.
- Labels are short physical room/shelf/building signs supporting silhouettes. Do not turn the composition
  into large text cards or full-width menu rows.

### Existing place silhouettes

Reuse the accepted authored-place v0.4 identities. Do not redesign or replace them:

- Trading Post awning/open counter;
- Recycler sorting machinery/profile;
- Storehouse broad storage bays;
- Blacksmith forge/chimney stack;
- Firepit hearth/community identity;
- every later existing station silhouette when it appears in a density fixture.

Palette and environmental adaptation may change within the existing grammar. A station's whole-mass
silhouette, major negative space and functional fixture remain stable. The retired universal damaged state
must not return: the village will never be damaged.

The functional silhouettes are a semantic starting point, not permission to reuse tiny placeholder props.
Buildings must be beautiful, material-rich production pixel art recognizable without their sign. For this
proof, use a coherent 184-pixel logical scene width at 2× display; station façades normally require at least
64×48 logical pixels and roughly 112–144 displayed width. House and Library are scene sprites/layer kits
occupying most of the logical canvas. Large flat fields, labelled box diagrams, coloured rectangles standing
in for books and 48×32 station icons fail visual acceptance even if their manifests/tests are green.

Export exact native-size composites plus 400% nearest-neighbour crops of every current building, House
interior and Library growth family. The ordinary Chrome HTTP route and standalone lossless contact sheet are
both required. No candidate becomes integration-ready before Game Design/Aimee accepts the actual art.

## Exact navigation topology

The **Binder House and yard** is the root. It is never drawn as a tile on another village screen.

Three root arrows are fixed:

- left edge: **Commerce Row**;
- right edge: **Makers' Row**;
- bottom/down: **The Commons**.

Every district screen has one obvious **Home** return to the Binder House. Device Back has the same meaning.
Do not add a fourth district, House/Village tabs, Home/Make/Study/Realms categories, a route graph or a
Wayfarer's-Table departure hub.

### District membership for this proof

Use only settled opening/reachable membership:

- Commerce Row: Trading Post, then Recycler;
- Makers' Row: Blacksmith;
- The Commons: Storehouse and Firepit.

Later station density may be represented in a separate noninteractive stress fixture using the existing 18
silhouettes, but it may not choose final district membership for stations not assigned above. Asset Design
does not solve future zoning by guesswork.

Unknown future buildings are absent, not locked silhouettes, empty named lots or blurred spoilers.

## Current checkpoint 5 — close-up Library root

Build the Library now from the settled contents below. The Trading Post, opening-five, state-continuity and
Binder House gates are already accepted; this release does not authorize later buildings.

### Composition

The root is a **close-up of one large bookcase**, or at most two adjoining bookcases if one case cannot
provide honest native tap geometry, with exactly five physical shelf destinations. The broader Library area
appears only in the Binder House cutaway. Do not draw a second full room, floor plan or navigable interior for
the Library destination.

1. **Diaries**;
2. **Bestiary**;
3. **Dictionary**;
4. **Field Notes**;
5. **World History**.

Recommended fixed layout for the first proof:

- one full-width upper Diaries shelf, because it eventually holds many traveller volumes;
- middle pair: Bestiary and Dictionary;
- lower pair: Field Notes and World History.

All five identities, labels, counts and 44×44-or-larger ownership regions are visible in the initial 368×800
viewport. If this composition fails native readability, Asset Lead may submit exactly one alternate fixed
five-shelf arrangement; it may not add scrolling, tabs or a sixth category.

### Derived growth states

Use the exact real-count stages:

| Count | Form |
|---:|---|
| 0 | empty labelled space; no fabricated book/title |
| 1 | folded page or loose card |
| 2–3 | stitched/clipped folio |
| 4–6 | thin softbound volume |
| 7–9 | substantial hardcover |
| 10+ | full hardcover with restrained slips/bookmarks |

For an individual Diary, the traveller's own recovered pages drive the form. Total pages from other people
cannot thicken it. Undiscovered travellers have no name/spine. Late diaries may reach full form without
changing earlier thresholds.

### Required Library fixtures

1. **Empty opening:** all shelf labels visible; no fake collection contents.
2. **Early:** one traveller folded page; one known creature; two encountered runes including one `??`; one
   Field Note; one World History record.
3. **Developed:** at least five traveller diaries at different page-count stages; populated Land/Water
   Bestiary folios; developed Dictionary/Notes/History.
4. **Attention:** new Diary and Bestiary content create one restrained warm-gold shelf rim/count; entering
   the room alone does not show a checked state.
5. **Grayscale/value:** every shelf and growth form remains distinguishable without hue.
6. **Disclosure:** unknown rune remains `??`; undiscovered person/species does not appear; deep-water sighting
   may appear under Water but carries no combat/harvest implication.

The Library does not contain a separate top-level Bestiary hotspot elsewhere. Constellation is not one of the
five shelves.

## Future reference — opening village districts (after the style gate)

Create three separate fixed side-view phone screens using the accepted station silhouettes.

### Commerce Row

- Trading Post occupies the first stable position.
- Recycler occupies the second.
- Each uses its functional silhouette and a façade/near-entrance pictogram plus short station name.
- Empty future space is ordinary street/environment, not labelled placeholders.

### Makers' Row

- Blacksmith is the only required opening/reachable fixture.
- Preserve forge/chimney ownership at phone scale.
- Do not invent Workshop as a second maker or place unreached Bowyer/Armoury/Weaponsmith buildings merely to
  fill space.

### The Commons

- Storehouse and Firepit are visible, distinct community buildings.
- Storehouse is outside the Binder House and reads as town-supplying storage.
- Firepit reads as hearth/gathering place, not a shop or damaged camp.

### Required district states

For each current building, prove only states it may actually own:

- absent/unknown (nothing leaks);
- known buildable foundation/plot and truthful sign;
- built;
- improved where current station data permits;
- built/improved plus independent attention rim.

No damaged, ruined, defended, repaired or rebuilt state. Attention is an overlay on the current physical
state, never a construction state.

### Future density stress

Separately show all accepted station silhouettes at the smallest size the district grammar might eventually
need. This is a readability/density test only. It must answer:

- can four visible buildings plus signs remain distinct at 368 width without becoming cards?;
- if not, recommend fixed adjacent district blocks rather than inventing final membership or free panning;
- which established silhouettes collide in colour and grayscale at that size?

Do not implement a carousel, scrolling town or final multi-block map in this packet. Report the evidence to
Game Design for a later zoning decision.

## Completed checkpoint 4 — Binder House/yard shell

The accepted functional visual shell contains only these settled interactive anchors:

- Writing Desk;
- Library;
- Party planning area;
- yard Essence Spring;
- the three district arrows.

Workshop is removed. Constellation retains its existing route while the six-star expansion remains under
`workshop-constellation-role-audit-current.md` review. Therefore:

- do not label or wire Workshop as a hotspot;
- reserve one removable Constellation chart hotspot, but do not depict unaccepted stars or costs;
- a neutral workbench may exist as ordinary house dressing;
- a neutral star chart/window may exist as ordinary dressing;
- their presence cannot imply a missing action, currency wallet or future tree;
- keep their decorative layers removable without redoing the house silhouette.

### House composition

- Fixed side-view dollhouse/cutaway with the player-facing exterior wall removed.
- Visible yard attached to the same composition; Essence Spring is a basin/source outside, never a sink.
- Writing and Library zones are distinct even if adjacent.
- Party area reads as a practical shared planning/gathering table, not the rejected Wayfarer's route graph.
- House contains no Storehouse, Firepit, Trading Post, Recycler, Blacksmith or recruit station.
- Art and hotspot rectangles share one normalized coordinate fixture and the same `scaledToFit` transform.
- No cropped `scaledToFill`, off-screen hotspot or scroll required to discover a room/arrow.

### House fixtures

1. fresh opening with the four settled anchors;
2. developed collections/tools reflected as restrained truthful dressing only;
3. Library attention and Essence Spring attention independently shown;
4. all three arrows selected in turn;
5. grayscale/value and collision overlays;
6. Workshop dressing and the removable Constellation chart layer separately removed to prove they are not
   structural dependencies.

Do not finalize the Constellation graph contents until Game Design records Aimee's six-star choice. Workshop
is already absent from the manifest.

## Shared attention grammar

One restrained warm-gold rim/low-amplitude glow applies only to an exact unchecked event:

- construction completed;
- a contribution/recipe/action newly available;
- merchant stock refreshed;
- an item/recovery waiting;
- new Library content on the exact shelf.

It is not red danger, not a permanent affordable-action marker and not a whole-screen flash. Asset fixtures
show ordinary and attention states; they do not invent receipt-clearing logic.

## Interaction and disclosure requirements

- Every destination target is at least 44×44 and pairwise non-overlapping.
- Labels do not clip or depend on truncated internal IDs.
- Focus/selected/attention are distinct in shape/value.
- Unknown buildings, books, people and species are literally absent.
- A shelf/building never exposes internal status enums, resource counts or unlocks not supplied by its
  fixture.
- No mockup control implies a mechanic not named here.
- No tutorial overlay or tutorial copy.
- No quality-colour frames or crafting-component visuals in this packet.

## Tests and evidence

Asset Lead must provide:

1. deterministic fixture validation with stable IDs and integer rectangles;
2. pairwise hit-rectangle collision assertions for every screen state;
3. exact 368×800 color PNG for Library empty/early/developed and each district;
4. exact 368×800 grayscale PNG for developed Library, three districts and House shell;
5. collision/ownership overlay PNGs;
6. count→growth-stage unit tests for `0/1/2/4/7/10`;
7. absence tests for unknown traveller/species/building content;
8. test proving Workshop is absent and the provisional Constellation chart routes only to the preserved
   current surface without implying new stars;
9. test proving no station damage state is requested/rendered;
10. existing complete AssetLab test/regression report with intentional new fixtures isolated from prior
    goldens.

Do not promote new goldens before Game Design reviews the exported lossless PNGs. Existing place v0.4
goldens remain unchanged.

## Review order and stop conditions

Trading Post v0.3 and the Recycler/Blacksmith/Storehouse/Firepit Built/Tier-0 opening identity set are
Game-Design accepted candidates. Trading Post and Firepit foundation/built/improved/mastered continuity rows,
independent warm-gold attention overlays, and Binder House v0.1 are also accepted candidates. Current work is
the close-up Library only. After that review, later buildings proceed in campaign order. Do not batch those
future milestones merely because their specifications are present in this file.

Stop immediately and report rather than inventing:

- a Workshop destination or any unaccepted Constellation purchase;
- later station district membership;
- a new mechanic/control;
- a sixth Library shelf;
- final quality/rarity visuals;
- native implementation details.

## Engineering handoff later

This packet deliberately produces no native code. After Game Design accepts a proof and Aimee settles the
Constellation expansion, a separate Engineering packet will specify:

- stable screen/destination adapters;
- exact hotspot manifest loading and aspect-fit transform;
- route migration/Back restoration;
- shelf count/attention receipts;
- native asset packaging and parity tests.

Asset Design may document its exported manifest but may not define game-state schemas or route behavior.
