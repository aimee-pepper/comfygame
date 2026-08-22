# World arrival image — Asset production packet

**Status:** implementation-ready Asset brief once the Open Flats starter correction is integrated on main
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
| `authoredKnownScopes` | known mark IDs and legitimately caused visible scope IDs | one restrained causal clause | hidden mark semantics |
| `entryDisclosure` | only already visible site profile or disclosed apex-location mark | optional v1 extension fixture | any hidden complete-world POI/entity fact |
| `description` | rules-owned final 18–55 word string from `world-arrival-description-grammar-current.md` | body copy only | Asset-authored substitutions |
| `firstMapCropReceipt` | exact disclosed entry crop render inputs | continuity evidence only | revealing cells beyond current sight |

Missing optional fields omit their layer. Unknown enum values and extra fields fail visibly in the lab; no
fallback may produce plausible scenery. Title and description never seed scene geometry.

The future native adapter must derive the input once, at successful bind, and persist it. The Asset proof
does not become that adapter merely because its fixture JSON has the same shape.

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
  mark gathered low growth along the few wet and stony edges.`

### `starter_rainwashed_shore` — **Rainwashed Shore**

- seed 26; known authored mark `Archipelago`;
- dominant structure: stone shelves/islands separated by shallow and deep water;
- flora: dull-fungal-bloom identity, 21 placements; no active/hostile flora;
- description (rules-owned fixture):
  `Stone shelves break a wide run of shallow and deep water. Your Archipelago mark divided the route,
  while sparse growth settled on the open stone.`

### `starter_stone_hollow` — **Stone Hollow**

- seed 23; known authored marks `Caverns + Ore`;
- dominant structure: enclosed stone, narrow soil paths and wet hollows;
- flora: pithy-succulent identity, 19 placements; no active/hostile flora;
- description (rules-owned fixture):
  `Stone closes around narrow paths and wet hollows. Your Caverns mark shaped the enclosure, while your Ore
  mark drew ore through it.`

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
8. longest 55-word description at 368×800;
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

## Explicit supersessions

- “Open Meadow, seed 2” is retired for new starter grants; use stable ID `starter_open_meadow`, displayed
  title Open Flats, seed 67.
- The accepted lifecycle v0.3 renderer is a transition/continuity grammar, not sufficient proof that dynamic
  world identity is solved. This checkpoint adds the actual world-fact compositor without replacing v0.3.
- The old broad phrase “a site or distant creature” does not authorize concealed content. Current entry
  disclosure in `world-arrival-causal-reveal-current.md` wins.
