# World arrival image — Asset production packet

**Status:** v0.3 visually and technically accepted as a frozen Asset candidate; native integration remains queued
**Priority:** B1.6a; parallel Asset proof, not native promotion
**Owners:** Game Design owns legitimate facts and reveal hierarchy; Asset owns the isolated deterministic
compositor; Engineering later owns the frozen native adapter/lifecycle
**Updated:** 21 August 2026

This packet narrows `world-arrival-causal-reveal-current.md`. It does not authorize Asset to invent a
second world model, write runtime prose, change Worldgen, or reinterpret the accepted lifecycle splash.

## Player-facing result

After binding succeeds and the world is ready, the player sees one framed, dynamically composed pixel-art
view of that exact world and a concrete two-sentence description. It should feel like the written
page opening into a place, not like a parameter receipt, map screenshot, loading screen or generic landscape
with a different tint.

The reveal answers, in this order:

1. What kind of ground and water relationship did this become?
2. What do its light, air and growth make it feel like?
3. Which visible result came from the player's known writing?
4. What remains for exploration rather than being disclosed here?

## Production boundary

### Build now, in isolated AssetLab

- a pure `world-arrival-v1` compositor with one strict input object;
- a reusable **160×100 logical-pixel scene**, scaled only by nearest neighbour;
- one 368×800 phone composition containing title, scene, concrete description, compact source-page
  thumbnail and one `Enter world` action;
- the three exact starter fixtures below;
- near/far relationship, open-colour/Ash, longest-copy and disclosure fixtures;
- colour, literal grayscale, first-map-continuity and collision evidence;
- deterministic manifest, hashes and tests.

### Do not build in this checkpoint

- native Swift/PBX integration;
- a new world generator or a second pressure resolver;
- entry animation, parallax, particle systems or loading progress;
- static one-off production splash bitmaps for each world;
- site glamour shots, traveller portraits, named creatures, resources or loot;
- return/defeat/collapse art changes—the accepted v0.3 lifecycle treatment remains unchanged;
- the still-open general rule for depicting a legitimately entry-visible site.

## Exact input ownership

The proof input mirrors a future game-owned `WorldArrivalReceipt`. It accepts only sanitized, frozen facts.
AssetLab may make a fixture adapter from the live World Generator bridge, but the compositor itself cannot
read complete Worldgen state or choose what is safe to disclose.

| Field | Type | Visual use | Prohibited use |
|---|---|---|---|
| `receiptID` | stable string | determinism key only | display or lore |
| `worldSeed` | UInt64 string | bounded composition variation | rerolling any identity |
| `sourcePage` | ID, title, 6×6 thumbnail marks | compact provenance beside copy | revealing unknown mark names |
| `dominantGround` | closed ground ID | foreground/midground material family | replacing the exact palette with arbitrary biome art |
| `waterRelationship` | none, pools, channels, shelves, islands | silhouette and depth-band layout | showing a hidden route or portal |
| `materialDescriptor` | exact current world-visual material receipt | palette/texture transform | a second material classifier |
| `illumination` | entry current band plus visible-source class | scene value and sky/light layer | exposing numeric pressure |
| `suspendedAtmosphere` | exact medium/density/motion | accepted Smoke/Ash/Mist/Miasma layer | inferring weather from colour |
| `precipitation` | exact none/rain/snow/mixed plus intensity/motion | accepted precipitation layer | changing terrain or movement rules |
| `flora` | 0–4 visible species render identities, coverage, habits | same silhouette/palette grammar as map | names, metabolism or defence labels |
| `causalVisualFacts` | safe known/opaque mark key, typed `ground/water/flora/resource/light/atmosphere` scope, `none/increased/reduced/reshaped`, result band and same-seed-without-mark band | no image authority; final description is rules-owned | hidden mark semantics, names reconstructed from IDs, authorship inferred from presence, or creation claims for mere increases |
| `entryDisclosure` | only already visible site profile or disclosed apex-location mark | optional v1 extension fixture | any hidden complete-world POI/entity fact |
| `description` | rules-owned final 18–55 word string from `world-arrival-description-grammar-current.md` | body copy only | Asset-authored substitutions |
| `firstMapCropReceipt` | exact disclosed entry crop render inputs | continuity evidence only | revealing cells beyond current sight |

Missing optional facts omit their **visual layer**, but the version-2 serialized ABI is normalized rather
than left to a host language's optional encoding. `entryDisclosure` is always present as its typed object or
explicit `null`. Full/fringe/remembered crop cells carry the exact terrain keys; `floraStableID` is `null`
when that visibility cannot disclose flora. Hidden cells carry exactly `x`, `y`, `visibility` and no ground,
elevation or flora keys. The frozen canonical hash covers that exact shape. `dominantGround` is always the
rules-owned dominant dry ground (never water, deep water or chasm). Unknown enum values, wrong key sets and
extra fields fail visibly in the lab; no fallback may produce plausible scenery. Title and description never
seed scene geometry.

The future native adapter must derive the input once, at successful bind, and persist it. The Asset proof
does not become that adapter merely because its fixture JSON has the same shape.

## Native promotion seam

The accepted `world-arrival-kit.js` compositor is the frozen visual reference, not an iOS runtime dependency
and not permission for a fresh Swift interpretation. Native promotion uses one mechanically conformant
command adapter and freezes its result before the successful bind mutates campaign state.

Asset first exports a versioned conformance corpus from the accepted compositor. It contains canonical
sanitized scene receipts plus the exact ordered output of `arrivalSceneCommands` for:

- every accepted starter, near/far, scope counterfactual, disclosure and 55-word fixture;
- every closed dominant-ground, water-relationship, illumination, suspended-medium/density,
  precipitation/intensity, flora-count/habit and entry-disclosure boundary at least once; and
- a deterministic multi-seed matrix large enough to exercise every seeded placement branch and maximum
  command count.

The corpus command ABI is closed `rect-v1` only: integer `x`, `y`, `width`, `height`; exact 8-bit RGBA;
closed scope; and source-order index. Bitmap stamps are expanded by the accepted Asset compositor into those
run-length rectangles before comparison. Every command must be in the 160×100 scene, positive-sized and
ordered; unknown ops/scopes, floats, extra keys and out-of-bounds pixels fail closed.

Engineering may then make a line-for-line native adapter from the accepted command compositor, pinned to the
exact Asset source and latest manifest hashes. Acceptance requires byte-equal canonical command JSON for the
entire corpus and exact pixel hashes for the frozen proof scenes; approximate visual similarity is not a
pass. Game rules, receipt banding, disclosure, prose and phone layout remain outside that port.

Before atomic Bind & Depart, the adapter produces and validates one `WorldArrivalRenderedSceneReceipt` v1:

- `canvasWidth: 160`, `canvasHeight: 100`;
- the canonical SHA-256 of the input `WorldArrivalSceneReceipt`;
- `visualProgramID: world-arrival-v1` and the exact accepted compositor/manifest hashes;
- the complete ordered `rect-v1` command list;
- its canonical command-list SHA-256 and exact rendered RGBA SHA-256.

That rendered receipt is stored with the active run and immutable History arrival receipt. The reveal screen
renders only the frozen command list at integer nearest-neighbour scale; it never re-reads Worldgen or
reclassifies the scene. A later art program may replace the current implementation for new binds without
retaining old generation code, because older worlds retain their already-sanitized draw commands. Commands
contain no interaction or complete-map facts.

Presentation authority remains disabled until the adapter, persisted rendered receipt, reachable reveal
root and one centralized pending-arrival action gate land together. Current short-lived saves were created
while presentation was disabled: migration may materialize a rendered receipt from a valid v2 scene receipt
before enabling the gate, but a missing/invalid scene receipt cannot synthesize a plausible splash or strand
the run. Generator/adapter/hash failure still happens before seed spend, page consumption, Field Kit movement
or History mutation. Player-facing title, two-sentence description, source-page thumbnail, `Enter world`
button and hit targets remain native game UI; proof phone PNGs are never bundled as runtime scenes.

## Fixed visual grammar

### Frame and camera

- Preserve the accepted v0.3 **framed page/tableau** fiction and its 160×100 scene footprint.
- This is an illustrative fixed shallow-depth view with foreground, middle distance and far/air bands. It is
  not another navigable camera and cannot imply literal entity coordinates.
- The explorable map remains straight top-down. Palette, terrain edge language, flora identity, atmosphere
  and recognizable site identity must match it; perspective arrangement may not contradict it.
- Keep at least 8 logical pixels of calm interior space along every frame edge. No important silhouette may
  be cropped by the frame at any receipt-valid density.

### Layer order

Render in this exact order:

1. book/page frame from accepted lifecycle splash grammar;
2. far value/illumination field;
3. dominant ground and water mass relationship;
4. genuine relief/material accents, never false sidewalls caused by colour change;
5. characteristic flora using the same frozen species identities as the map;
6. typed atmosphere/precipitation presentation when the receipt actually contains it;
7. optional legitimate disclosed-site or location-only apex layer;
8. entry transition mark from accepted v0.3 lifecycle grammar.

Atmosphere may cross several terrain bands but cannot erase the ground/water read. Flora is subordinate to
the dominant place silhouette and never becomes a decorative border.

### Relative diversity

Visual difference must be proportional to receipt difference:

- same material/water/light/air/flora facts with a different title remain close visual relatives;
- changing only flora changes only flora-owned pixels plus their legitimate occlusion;
- changing only atmosphere changes only atmosphere/value-owned pixels;
- opposed ground/water structure changes the main silhouette;
- undefined/open authored colour remains full bind-random colour, not Ash-black or generic beige;
- a repeated receipt is byte-identical.

Do not enforce “two worlds must look different.” Similar worlds should look similar.

## Phone composition

At 368×800 ordinary size, use this hierarchy rather than a list of receipt facts:

1. compact navigation/status-safe top inset;
2. world title, no larger than two ordinary text lines;
3. 320×200 nearest-neighbour presentation of the 160×100 scene;
4. concrete 18–55 word description in a bounded two-to-five-line region;
5. compact source-page thumbnail and `Written from …` provenance;
6. one fixed-bottom `Enter world` action.

No terrain counts, pressure numbers, resource totals, rune parameter rows or debug labels appear in the
player proof. The longest valid description must fit without scrolling. The scene is the first read; title
and provenance are supporting information.

## Exact starter fixtures

All three use `ordinary` scale and current authority from `world-pages-authority.json`. Their live terrain,
flora, encounter, writing, Essence, collapse and reachability receipts are checked by
`node Scripts/validate_starter_world_receipts.mjs`.

### `starter_open_meadow` — displayed as **Open Flats**

- seed 67; known authored marks `Plains + Verdant`;
- dominant structure: broad sand/soil flats with a few shallow pools and little stone;
- flora: low pithy-succulent identity, 21 placements; no active/hostile flora;
- description (rules-owned fixture):
  `Broad sandy ground runs between shallow pools. Your Plains mark opened the terrain, while your Verdant
  mark spread low growth farther along the few wet and stony edges.`

### `starter_rainwashed_shore` — **Rainwashed Shore**

- seed 26; known authored mark `Archipelago`;
- dominant structure: stone shelves/islands separated by shallow and deep water;
- flora: dull-fungal-bloom identity, 21 placements; no active/hostile flora;
- description (rules-owned fixture):
  `Stone shelves break a wide run of shallow and deep water. Your Archipelago mark divided the route,
  while only the ground nearest the entry remained clearly visible.`

### `starter_stone_hollow` — **Stone Hollow**

- seed 23; known authored marks `Caverns + Ore`;
- dominant structure: enclosed stone, narrow soil paths and wet hollows;
- flora: pithy-succulent identity, 19 placements; no active/hostile flora;
- description (rules-owned fixture):
  `Stone closes around narrow paths and wet hollows. Your Caverns mark shaped the enclosure, while your Ore
  mark made ore more plentiful.`

Sites, portals, traveller candidates, ordinary creature identities and exact resource positions are absent
from all three entry pictures unless a separate sanitized `entryDisclosure` field legitimately supplies
one. Complete bridge state is not permission to render it.

## Required comparison fixtures

1. the three starter receipts, each beside its exact first visible map crop;
2. a near pair differing in only one low-magnitude visual fact;
3. a far pair differing in main ground/water structure and air/light;
4. an Ash world with no authored colour proving Ash does not turn the whole scene black;
5. one hidden-site A/B: changing the hidden site in complete source state produces identical accepted input
   and pixels;
6. one explicitly labelled **open extension** with a legitimately entry-visible site profile; never include
   it in the promotable v1 set;
7. unknown-mark A/B: hidden mark identity cannot enter the accepted request or alter text;
8. longest 55-word description at 368×800, using the exact Design/rules-owned synthetic receipt and
   string in `world-arrival-description-grammar-current.md`; no temporary or Asset-authored replacement;
9. all above in literal grayscale.

## Automated gates

- strict schema: required fields, closed enums, no extras;
- deterministic bytes for every fixture, copied object and different JSON key order;
- no input mutation;
- exact 160×100 logical scene, binary alpha where transparency is allowed, bounded reviewed palette;
- nearest-neighbour scaling only;
- no clipping; all phone controls and copy remain in bounds;
- same receipt → same commands/pixels;
- title-only change → identical scene pixels;
- hidden site/resource/traveller/apex/unknown-mark changes → identical accepted input and pixels;
- single-scope mutation changes only that scope's permitted layer mask;
- three starters use exact current seeds and pass the live starter receipt validator;
- first-map crop and tableau share material, water, flora identity, light and atmosphere classes;
- no prohibited riddle/aphorism tokens in supplied description fixtures;
- no static starter image is declared a production source; production is the shell/parts/compositor.

## Visual review gates

Game Design must be able to answer yes, without reading debug labels:

1. Do the three starter scenes read as flat living ground, broken wet shelves and enclosed stone?
2. Does each feel continuous with its first map crop rather than like unrelated cover art?
3. Is the shallow-depth illustration obviously a page tableau, not a second gameplay camera?
4. Do light, air and flora materially change the place without obscuring navigable terrain identity?
5. Does grayscale preserve the three main silhouettes and atmosphere density?
6. Is the image attractive and detailed at native phone scale rather than only at 400%?
7. Is all undiscovered information genuinely absent rather than merely visually subtle?

Passing tests alone does not authorize promotion. Asset stops after consolidated visual evidence and waits
for Game Design/Aimee review. Native integration remains a later Engineering checkpoint.

## v0.1 visual disposition — 21 August 2026

**Receipt, disclosure, determinism and compositor structure pass; the scene art does not.** Retain the
strict sanitized receipt, 160×100 layer compositor, causal facts, exact starter strings, 55-word fixture,
near/far counterfactuals, Ash/open-colour behavior, disclosure exclusions and first-map continuity gates.
Do not promote or checkpoint the current visual candidate.

The three phone tableaux still read as stacked horizontal rectangles, square slabs, flat water bands and
one- or two-pixel flora specks. They differ mainly by palette and block arrangement rather than reading as
flat living ground, broken wet shelves and enclosed stone. This fails visual gates 1, 3, 4 and 6 even though
the automated gates pass.

Correct the same checkpoint with production-ready logical pixel-art parts or bitmaps, not more web-shape
geometry:

- Open Flats needs an irregular long sandy plain, organic shallow-pool banks, wet/dry edge pixels, a few
  stony interruptions and readable low succulent clusters concentrated at wet or stony margins.
- Rainwashed Shore needs broken stone-shelf contours, shallow water crossing ledges, deep channels and
  sparse growth rooted at shelf edges; rectangular floating platforms are prohibited.
- Stone Hollow needs an enclosed rock/cave volume, narrow soil approach and wet depressions that cannot be
  mistaken for Shore recoloured. Exact ore positions remain undisclosed.
- ground and water boundaries use irregular material silhouettes and texture rather than long unbroken
  horizontal bars; flora reads as plant crowns or patches at exact 2× phone scale rather than dots;
- the entry mark belongs to the scene material rather than resembling a pasted UI square; and
- the source-page thumbnail depicts the actual disclosed bound-mark layout, preserving unknown-mark
  redaction, rather than a generic near-blank card.

The flora-only near pair must still change only flora, but that change must be visible without labels. The
far pair must remain immediately distinct in literal grayscale. Asset must show the individual native and
400% pixel parts plus the three exact 368×800 starter phones before re-review. No native integration or
next Asset checkpoint is released.

## v0.2 visual disposition — 21 August 2026

The organic pool banks, broken shelves, rock clusters, succulent crowns, actual bound-page mark footprint
and distinct Stone Hollow enclosure materially correct the v0.1 placeholder grammar. Open Flats,
Rainwashed Shore and Stone Hollow now have different landform identities in colour and literal grayscale,
and the flora-only counterfactual remains both scope-exact and visible. Retain those parts and every existing
receipt, disclosure, determinism, causal-fact and 55-word gate.

Visual acceptance remains held for exactly two contained corrections:

1. The upper third to half of every 160×100 tableau is still a nearly uniform dark rectangle. It makes the
   image read as a narrow terrain strip below empty void rather than a generated world shot. Fill that space
   with receipt-valid, environment-specific distant material, atmosphere or enclosing-rock silhouettes.
   Preserve the shallow-depth page-tableau fiction and 8-pixel calm edge; do not introduce a literal second
   navigable camera, hidden entities or concealed content.
2. The entry rune still reads as a solid square UI plaque. Render the disclosed rune footprint directly into
   the ground, shelf or path material with no solid square background. Use restrained outline/value contrast
   so the surrounding material remains visible through the mark's negative space.

No other scene family, rule, UI or future Asset checkpoint is opened by this disposition. Asset stops after
the corrected exact phone/grayscale evidence. Technical acceptance also waits for Engineering to remove the
duplicate traveller-meeting promotion and for the ordinary live bridge/full regression to run green; the
fixture-only bypass is iteration support and never promotable evidence.

## v0.3 visual disposition — 21 August 2026

**Accepted as the frozen-ready visual candidate.** Game Design inspected the exact 368×800 colour and
literal-grayscale starter matrices for manifest
`2066ba1009ee22d74af495f75753e8c8075ded8fe297cb5ce38335554fd1e6b4`, frozen in Asset commit
`8ae1e88`. Open Flats now reads as
staggered sandy distance and open living ground, Rainwashed Shore as layered broken wet shelves, and Stone
Hollow as an enclosed rock volume. Their silhouettes remain distinct without labels and preserve relative
similarity where receipt facts overlap.

Environment-specific distant material now occupies the former empty upper field without adding a literal
second gameplay camera, entity, POI or hidden fact. The first disclosed rune is rendered as restrained
material strokes directly in the ground, shelf or path; no solid plaque remains. The page thumbnail retains
the actual disclosed bound-mark layout, and the accepted v0.2 organic pool, shelf, rock and succulent parts
remain intact.

Freeze these exact bytes. The post-repair verification used an isolated clean `7e3ddc0` baseline plus only
the frozen Asset boundary and permitted bridge seam. The ordinary live bridge, ordinary exporter, focused
test and full Asset regression all passed without `--use-existing-fixtures`; regenerated fixtures and the
complete artifact tree were byte-identical to the frozen candidate, and the manifest remained unchanged.
This accepts the Asset candidate, checkpointed exactly as Asset commit `8ae1e88`. No native packaging, PBX
edit or golden promotion begins here; native integration remains a later Engineering checkpoint.

### Causal resource-scope correction — accepted 21 August 2026

The accepted scene ABI now recognizes the closed causal scopes `ground`, `water`, `flora`, `resource`,
`light` and `atmosphere`. Stone Hollow's Ore fact is correctly typed as
`resource/increased/present/present`; its exact description remains “made ore more plentiful.” Resource
result bands are disclosure-neutral `absent|present` values. They have no scene-command authority: changing
any valid resource before/after pair draws no deposit, icon or other pixels.

This is a contract correction with **zero visual change**, frozen in exact Asset commit
`a95b44f70ed7995812f7960b4f1248ceb2d8da1c`. The corrected manifest file SHA-256 is
`03d21961eec0eca3cf9374d3a2320f988b75b3ba20f7568b19d272c6ed25f991`; all 62 accepted PNGs remain
byte-identical under aggregate receipt
`e14c8e9622ffdfeb3a1ffeecd1e540632f7ca27c8704cd874313c32fc2f5f283`. The checkpoint remains
`integrationReady:false`; it authorizes no native, PBX, golden or subsequent Asset milestone work.

### Rainwashed Shore true-dark receipt reconciliation — accepted 21 August 2026

E2's executable production receipt proves Rainwashed Shore is `trueDark`. Its exact Sentence 2 therefore
ends “while only the ground nearest the entry remained clearly visible,” superseding the older sparse-growth
pair in newly bound worlds. Game Design inspected the corrected 368×800 colour and literal-grayscale phone;
the complete copy wraps to three lines without clipping.

Freeze exact Asset commit `72b840d3e1de2b8c32aebfc0e876d61c69448a92`, manifest-file SHA-256
`f041c81a41c45ac88dada40b0c173ab63c6e93c2984f232a23be67892df4a65b`, starter fixture SHA-256
`9ef496e9ce2143fb953c68a1a11278f8e3878d9b291d6bb7a560c74a60bf8cb0`, and visible-site fixture SHA-256
`1957bb456b21499df2686d6579842c4f1b142be3fc2409065fae500d5ad80c8f`. All 38 production scene, reusable-
part and first-map-crop PNGs remain byte-identical under aggregate
`4eb1076eb8d4640a5467d3343167f55eed3b1c74ca2cefec5727cb5b5bda9184`; only text-bearing evidence changed.
`integrationReady` remains false and no scene/art/camera/disclosure authority changed.

## Explicit supersessions

- “Open Meadow, seed 2” is retired for new starter grants; use stable ID `starter_open_meadow`, displayed
  title Open Flats, seed 67.
- The accepted lifecycle v0.3 renderer is a transition/continuity grammar, not sufficient proof that dynamic
  world identity is solved. This checkpoint adds the actual world-fact compositor without replacing v0.3.
- The old broad phrase “a site or distant creature” does not authorize concealed content. Current entry
  disclosure in `world-arrival-causal-reveal-current.md` wins.
