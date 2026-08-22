# Terrain layering and motion — Asset production packet

**Status:** complete v0.2 visual pack and TerrainProductionPack v1 accepted; native integration active; final wall/cliff asset addition required
**Priority:** B1.7b; explicit Aimee-authorized Asset exception to the generic system-first hold
**Owners:** Game Design owns terrain meaning, disclosure and motion limits; Asset owns the isolated logical
pixel kit and compositor proof; Engineering later owns the native receipt adapter, cache and shared clock
**Updated:** 22 August 2026

## Current disposition — 22 August 2026

Aimee's direct requirement is a **properly generated, attractive dynamic pixel-art terrain system**, not a
top-surface reskin and not permission to discard the current genuine-height cue. The v0.1 checkpoint remains
authoritative for its closed request, shared-edge ownership, visibility, palette, motion and
no-**false**-sidewall contracts. Its visual
terrain-family sources are a technical prototype, not final terrain art: the current implementation builds
material texture from hash-scattered pixels and small procedural line/rectangle formulas, and its phone proof
still reads as procedural speckle rather than deliberately drawn organic terrain.

Therefore:

- Asset must not mechanically repackage the v0.1 family pixels as `TerrainProductionPack v1`;
- Asset first produces a v0.2 visual style gate from new, deliberately authored logical pixel-art parts,
  using generated composition references only as declared non-production input;
- that gate proves dynamic assembly and nonrepetition for Stone, Soil, Water/Deep Water and
  Groundcover/Growth before the remaining six ground families are expanded;
- all accepted v0.1 mechanical, disclosure and motion invariants below remain mandatory; and
- Engineering does not replace the native renderer until Game Design/Aimee accepts the v0.2 style, Asset
  expands it to all twelve grounds and freezes the native-consumable production pack.

The first v0.2 submission at canonical body
`3e100e72eda90be4c16ac1bd8aeb5ab4c0db214b9d000d3b162760112d0b921f` is **rejected**. Direct phone,
400% and source review found six flat 16-pixel material fills decorated by repeated small
clod/ripple/crown stamps, visibly stair-stepped contacts and three hard-coded `current`/`near`/`far` palette
tables. That remains a cleaner placeholder grammar, not complete production pixel art and not dynamic
world-pressure recoloring. Its hashes and green tests do not authorize reuse or promotion.

The rebuilt v0.2 style gate at canonical body
`bf06e7c0fc8e60c9d5529482f631fff05b420473c9011b253fe81c3643656588` and manifest
`6f50d6e65f4fc1d360892244b3227fc5fa35fc4a3644363e7a310f2d02ec360b` is **accepted as the visual
direction only** after direct inspection of the 64×64 macro source sheet, semantic role masks, three live
`WorldGrade2V1` recolors, phone/grayscale maps, turning shore and T/cross contacts. Its six shown families
now read as deliberately authored, connected top-down pixel-art surfaces and retain identical form geometry
across pressure palettes. This is not acceptance of a six-family terrain product, runtime pack or native
integration. `integrationReady` remains false until the same final-grade grammar covers Sand, Ice, Ash,
Rubble, Mud and Chasm plus the separate Snow/Ash cover and the consolidated twelve-ground review passes.

The corrected gate must use genuine top-down pixel-art source sheets/parts intended for production, not
ASCII-like stamp masks on solid squares. It must separate shape from colour through frozen semantic palette
roles and demonstrate the same source/mask bytes recolored by three exact live `WorldVisualReceipt`
descriptors. Any bounded first review may show only the six critical families, but every shown sprite must be
final-grade and reusable; after style acceptance the same system expands to all twelve live grounds and the
separate Snow/Ash surface-cover overlay before native integration.

The representative style gate is a review checkpoint, not permission to ship only six ground families.
Completion still means one coherent dynamic system covering all twelve live grounds in the actual phone map.

That complete v0.2 top-surface system is now visually accepted at canonical body
`2a541033b71b638f1803e5a9477a0197c38f38d96ff199a4864d49bf551608dd`, manifest-file SHA
`5e70b17c91c8601ed895455364f2cd8a51e010e2cb2201f09dc2c02c826f3892` and production aggregate
`90da0b9ed6092b591bcad83fbda68b0563de9c2ba37127911772c41418657a54`. It covers all twelve grounds
plus independent Snow and settled-Ash surface deposits. The complete visual pack is preserved at accepted
Asset commit `5bac76a9`; TerrainProductionPack v1 is accepted and preserved at Asset commit `84e6db50`, but
its manifest remains `integrationReady:false` and it is not native or integrated on the current shared line.

Those acceptances cover the new top surfaces, contours, deposits and motion. They do **not** prove a
functional replacement for the existing native south-facing wall/cliff presentation. The current
`southExposureLevels`/`southExposure` cue remains in the initial native integration until a final authored,
terrain-consistent wall/cliff family covers genuinely exposed levels 1, 2 and 3 and proves equal-or-better
readability and function on the 368×800 physical phone. Asset must add that bounded family without
regenerating or restyling the accepted top-surface system.

## Player result

The explorable map remains a straight top-down, tile-addressable world, but it should no longer read first as
a spreadsheet of individually filled squares. Ground materials meet through irregular top-surface contours;
real southern elevation drops retain a compact wall/cliff read; water, rock, loose ground and growth have an
obvious physical order; and a few surfaces move gently enough to make the world feel present without
changing, hiding or predicting a single rule.

The player must still be able to identify, before color:

1. deep water and chasm as different impassable surfaces;
2. ordinary shallow water as traversable;
3. Mud and tall Growth as two-turn entry for different visible reasons;
4. Rubble and tall Growth as sight-blocking for different visible reasons;
5. Groundcover as permeable low growth rather than tall Growth; and
6. actual cracking, crumbling, route, selection, content and adjacent-consequence cues above the material art.

This checkpoint changes presentation only. It cannot alter `GroundType`, placement, passability, movement
cost, line of sight, elevation, world generation, palette resolution, content, current visibility, saved
memory, pathfinding, turns or encounter behavior.

## Absolute camera and format rules

- Every explorable-map terrain source keeps a **straight top-down footprint**. No horizon, isometric x-offset,
  perspective convergence or shallow tableau camera is permitted. The sole vertical-face exception is the
  compact south-facing wall/cliff required by a genuinely exposed elevation delta; it remains subordinate to
  the translated top surface and never turns the map into a side view.
- One logical game/hit tile and its complete top plane remain exactly **16×16 logical RGBA pixels** before
  integer nearest-neighbour scaling. Genuine height keeps the existing `terrain-lifted-1.0.0` 16×19
  bottom-anchored composition profile, pivot `(8,18)`, one riser pixel per exposed level and an unchanged
  16×16 hit footprint; a versioned successor is required before any dimension or pivot changes.
- Production sources are exact bounded-palette logical pixel bitmaps or reviewed binary masks. HTML, CSS,
  SVG, antialiased canvas paths and procedurally drawn rectangles may present evidence but are not production
  art.
- Generated or painted composition references are `productionSource:false`. Asset must deliberately author
  the final logical pixels and publish their exact hashes.
- Each top plane paints every one of its own visible pixels. Material contours never leave transparent cracks
  between tiles or draw outside their 16×16 ownership rectangles. Only the height profile may use its
  declared transparent top overflow and south-face rows; that overflow does not change logical ownership.
- The accepted `world-grade-2` descriptor, frozen from authored and generated world pressures at bind, is the
  sole recoloring authority. Terrain assets expose semantic roles such as deep shadow, body dark, body,
  body light, highlight and family accent only where a family genuinely needs them; the renderer resolves
  those roles through `WorldGrade2V1` and the exact `WorldVisualReceipt`.
- Asset may never substitute named mock palettes such as `current`, `near` or `far` for that receipt. Evidence
  uses exact receipt-backed palette descriptors and proves that recoloring changes RGB only—not alpha,
  collision, form, edge ownership, visibility or gameplay identity.

## The material stack

The shorthand **water below rock below dirt below grass** means compositing priority, not hidden geology.
The renderer must never claim that every Soil tile has Stone beneath it or invent an unseen substrate.

Back-to-front top-surface ownership is:

1. opaque map backdrop and Chasm void;
2. deep and shallow water surfaces;
3. hard solid surfaces: Stone, Ice and the stable bed beneath Rubble's visible fragments;
4. loose surfaces: Soil, Sand, Ash and Mud;
5. low and tall growth terrain bodies;
6. static material detail and the permitted motion overlay;
7. the genuinely exposed south-facing elevation wall/cliff owned by the higher terrain;
8. supplemental elevation contact shade from the separate accepted atmosphere contract;
9. cracking/crumbled truth, route and stationary visible flora/resource decoration;
10. atmosphere, precipitation, actors, content and field-feedback layers in their already-settled order.

Priority resolves a boundary's visual overlap; it does not change either tile's ground identity. A higher
layer may intrude at most two pixels into the lower-priority tile's side of a shared contour, using its own
**top-surface** colors. A material boundary at equal elevation may never add a dark vertical strip or exposed
sidewall. This material-overlap rule does not suppress the separate genuine-height wall/cliff layer.

## Exact ground-family grammar

| Ground | Required first read | Static top-surface form | Motion in v1 | Prohibited implication |
|---|---|---|---|---|
| Stone | ordinary hard ground | joined plates, fine irregular seams, sparse chips | none | Ore, richness or raised blocks |
| Soil | ordinary worked/earthen ground | small clods, shallow value pockets, soft broken edge | none | Mud slow, furrows or a guaranteed crop |
| Sand | ordinary loose ground | low ripples and granular pockets with an irregular dry edge | none | quicksand, wind hazard or treasure |
| Ice | solid passable surface | continuous hard sheet, restrained cracks trapped inside the surface | none in the first native v2 integration | shallow/deep water or slipperiness not owned by rules |
| Ash | ordinary passable deposit | soft uneven drifts and sparse flecks | none | Smoke, heat, toxicity or black global tint |
| Water | traversable shallow water | continuous surface, visible bank/bed relationship and short ripple accents | continuous restrained ripple | hidden surcharge, route strip or deep water |
| Deep water | impassable depth | continuous darker body with a depth contour on the deep side | slower restrained ripple | Chasm or traversable water |
| Rubble | clear but sight-blocking broken ground | irregular overlapping chunks with gaps that retain ground ownership | none | Mud slow or an impassable wall |
| Mud | slow but sight-clear soft ground | depressed pools, drag ridges and broad soft patches below content | none | deep water, poison or sight blocking |
| Growth | slow and sight-blocking tall terrain | dense overlapping top-down blades/crowns whose envelope owns the cause | wind-driven one-pixel flex | a placed flora species, damage or impassability |
| Groundcover | ordinary low permeable growth | low rosettes/mats with open ground visible between clusters | wind-driven one-pixel flex | tall Growth, hidden content or slow movement |
| Chasm | impassable missing ground | opaque near-black absence with a hard irregular rim on the ground side | none | deep water, a dark material or a walkable depression |

Placed flora retain their accepted stable species identity and overhead camera. The Growth and Groundcover
rows above describe the rule-bearing **terrain body**, not generated flora specimens. This checkpoint does
not animate placed neutral, active or hostile flora.

## Shared edge contract

### Edge identity

Each cardinal boundary is one undirected world edge with one game-supplied `edgeContourID` in `0...3`.
It is derived deterministically from the frozen visual seed and canonical world-edge coordinate, never from
render order or a new RNG draw. Both adjacent tile requests receive the same ID.

The four contour patterns must be deliberately authored and complementary. They may bend one or two pixels
inside either tile but must:

- meet exactly at the tile boundary;
- leave no transparent or backdrop-colored seam;
- avoid a universal straight grid line;
- remain stable across redraw, save/load and animation frame; and
- remain identical when only an undisclosed remote tile changes.

### Adjacency ownership

Asset receives only four cardinal neighbor facts legitimately available for the tile's display state. Each
fact is `same`, an exact disclosed `GroundType`, or `unknown`. Hidden neighbors are always `unknown`; they
cannot influence edge shape, shade, material, phase or cache identity. A hidden tile constructs no terrain
request at all.

Rules for important pairs are closed:

- same exact ground joins continuously with no seam;
- Water beside Deep Water remains one water body; use a depth contour only on the Deep Water side and never
  insert a shoreline between them;
- Growth beside Groundcover uses a height/density boundary, not a Soil or path strip;
- Stone beside Rubble retains a continuous hard-material relationship while the Rubble tile alone owns its
  loose occluding chunks;
- Chasm owns absence; the adjacent ground tile owns the hard rim;
- every other unequal pair uses the material stack and complementary contour without a generic tan corridor.

Diagonal neighbors do not enter the v1 request. Corner rounding comes from the two incident cardinal
contours and their shared contour IDs. Asset cannot sample complete map state to improve a corner.

## Elevation, required south cliffs and false-sidewall prohibition

Material boundaries and height are independent.

- Equal-elevation neighbors produce **no** contact shadow, wall or vertical face regardless of color,
  palette, material, water depth or edge contour.
- A genuinely exposed southern drop retains a south-facing wall/cliff whose height is the exact safe
  `southExposureLevels` value, 1, 2 or 3. The higher tile owns the face; its authored material and
  `WorldGrade2V1` roles own the color. No generic dirt, timber, universal dark band or repeated stake may
  substitute for terrain-consistent wall pixels.
- The already-accepted contact shade may ground the wall/cliff on the **lower tile**, but it is supplemental
  only. Shade alone is not functionally equivalent to the wall/cliff and cannot replace its elevation read.
- Terrain animation cannot move, widen or recolor the elevation shade.
- The world map stays top-down: only the exact south-facing exposed delta receives a compact face. No
  equal-height face, north/east/west false extrusion, horizon or unearned cliff is authorized.
- A hidden or otherwise undisclosed south neighbor resolves `southExposureLevels` to zero and contributes no
  ground, palette or elevation fact. A map boundary likewise exposes zero in this contract. Asset never
  samples the hidden neighbor to improve the face.
- The existing native `southExposure` presentation remains active through the initial top-surface integration.
  It may be removed only after a final authored replacement has proved equal-or-better elevation readability,
  route/occupant function and unclipped composition in an exact old/new 368×800 physical-phone comparison.

## Frozen render request

The Asset proof accepts exactly one closed request per currently constructed tile:

| Field | Type | Owner and use |
|---|---|---|
| `schemaVersion` | literal `terrain-layers-v2` | v2 adds only the two rules-owned surface-deposit flags; fail closed on another version |
| `ground` | exact 12-value `GroundType` | game rules; chooses reviewed terrain family |
| `point` | integer x/y | edge and phase identity only; never display |
| `visualSeed` | unsigned frozen value | deterministic detail, contour and phase offsets; no gameplay RNG |
| `worldGradeDescriptorHash` | accepted stable hash | selects the already-resolved palette receipt |
| `featureVariant` | `0...3` | frozen static detail variant |
| `cardinalNeighbors` | N/E/S/W safe fact | exact disclosed neighbor or `unknown` |
| `edgeContourIDs` | N/E/S/W `0...3` | canonical shared edge identity |
| `elevation` | `0...3` | game-owned resolved centre elevation; supplied for external height/contact-shade composition and never inferred from pixels |
| `isCrumbled` | Boolean | game-owned missing/unsafe state; static override |
| `isCracking` | Boolean | game-owned overlay selection; never inferred from texture |
| `visibility` | `full`, `fringe`, `remembered` | hidden has no request |
| `motionBand` | `calm`, `moving`, `strong` | accepted Atmosphere-derived presentation band |
| `phaseOffset` | `0...23` | frozen from seed, point and terrain family |
| `presentationTick` | nonnegative integer | shared UI clock input; never persisted or used by rules |
| `reduceMotion` | Boolean | current presentation policy, not campaign state |
| `surfaceDeposits` | exact `{ snow: Boolean, settledAsh: Boolean }` | independent frozen presentation receipts; neither changes base ground or mechanics |

No pressure numbers, passability booleans, resource/site/entity facts or prose enter Asset. Asset does not
infer a mechanic from pixels; the game continues to own labels, Look text, hit testing and pathing.

`terrain-layers-v2` remains byte/schema-stable and does not silently absorb southern-neighbor elevation. The
separate existing lifted-height companion retains its required game-owned `southExposureLevels: 0 | 1 | 2 |
3` fact under `lifted-terrain-adapter-1.0.0`/`terrain-lifted-1.0.0` (or an explicitly versioned successor for
the final authored assets). Game code derives it as
`max(0, resolvedCentreElevation - resolvedSouthElevation)` only when the southern neighbor is legitimately
disclosed. Hidden, unknown, crumbled, forced-flat and map-boundary cases supply `0`; the value cannot exceed
the resolved centre elevation. Asset consumes the closed delta and never receives or infers hidden geometry.

## Restrained motion contract

### One shared clock

Native integration eventually uses one map-level presentation clock at **4 ticks per second**. There is no
timer per tile. The clock pauses when the World screen is inactive and does not reset on movement, touch,
modal presentation or turn change. The renderer consumes `presentationTick mod 24`, producing a six-second
master loop with per-tile phase offsets.

At a given receipt and tick, output pixels are deterministic. The tick is never saved, never affects the
world seed, and never enters combat, movement, visibility or generated content.

### Surface budgets

| Surface | Calm | Moving | Strong | Per-frame change budget |
|---|---|---|---|---|
| Water | one frame step per 4 ticks | per 2 ticks | per tick | at most 12 pixels; bank and shallow/deep contour fixed |
| Deep Water | one step per 6 ticks | per 3 ticks | per 2 ticks | at most 8 pixels; depth body/contour fixed |
| Groundcover | representative static flex | one step per 4 ticks | per 2 ticks | at most 6 pixels; occupied envelope fixed |
| Growth | representative static flex | one step per 4 ticks | per 2 ticks | at most 8 pixels; blocking envelope fixed |

Water motion changes short internal ripple/highlight pixels only. It cannot change the shoreline, depth
contour, route read or a tile's apparent passability. Adjacent water tiles use their shared edge identity
and phase offsets so a ripple crossing a boundary does not pop or reverse at the seam.

Groundcover and Growth flex within one pixel of a fixed top-down cluster. Their density, height silhouette,
far edge and visible content aperture remain fixed. Strong motion changes cadence, not pixel count or
mechanical severity.

Ice remains static in the first native v2 integration. A later phone-reviewed polish slice may test the
previously proposed sparse three-pixel hard-surface glint, but it is not part of this production-pack or
native-integration gate. Stone, Soil, Sand, Ice, Ash, Rubble, Mud and Chasm are static in v2. Clear air does
not invent dust; Rain does not create puddles; Mud does not bubble. Atmosphere/precipitation presentation does not
invent transient Snow or Ash accumulation. Two independent rules-owned frozen surface-deposit receipts,
`snow` and `settledAsh`, may select the reviewed shared accumulation geometry while preserving the underlying ground
and mechanics. Either may be absent or present, and both may coexist when both exact sources resolve. Snow
resolves white roles; settled Ash resolves grey/charcoal roles. Their combined opaque coverage leaves the
underlying material legible. Neither is the transient precipitation nor suspended-air layer, and settled Ash
is distinct from base `GroundType.ash`.

### Static, memory and accessibility behavior

- Reduce Motion, static screenshots and deterministic goldens use one seed-derived representative phase.
- Fringe terrain uses that static representative phase under the accepted fringe opacity/blur; it does not
  animate.
- Remembered terrain uses its frozen last-seen identity and one static representative phase. It is not a
  live remote view.
- Hidden tiles are opaque black, construct no request and cannot affect a visible neighbor's contour.
- Motion is decorative and hidden from accessibility labels. Labels continue to come from game rules.
- Route, player, selection, Look/Use and warning overlays never animate with the terrain.

## Production asset kit

Asset must deliver reusable logical sources rather than state screenshots:

1. twelve 16×16 terrain-family top-surface kits with four reviewed static detail variants each, built from
   genuine production-intended pixel-art source parts rather than procedural/hash-scattered filler;
2. four complementary cardinal contour-mask families and all 16 N/E/S/W adjacency combinations;
3. explicit Water/Deep-Water depth-contour, Growth/Groundcover height-boundary and Chasm-rim parts;
4. Water and Deep-Water motion frames plus Groundcover and Growth flex frames;
5. a pure request normalizer and compositor exporting static body and transparent motion overlay separately;
6. a separate recolorable Snow/settled-Ash cover kit that can lie over legal underlying grounds without changing their
   identity, passability or adjacency;
7. semantic palette-role masks and exact conformance to three receipt-backed `WorldGrade2V1` descriptors,
   with unchanged form/alpha hashes across recolors;
8. final terrain-consistent south-facing wall/cliff sources for every ground/substrate family that can legally
   own elevated terrain, including exact one-, two- and three-level faces plus continuous spans, caps and
   corner/end joins. These are authored material pixels using the higher surface's semantic palette roles,
   not stretched bands, generic shade, repeated stakes or procedural filler;
9. manifest dimensions, bottom pivots/overflow, palette slots, layer ownership, phase counts,
   command/bitmap hashes and `integrationReady:false`; and
10. no static whole-map image as a production source.

The static body must be cacheable independently of the motion overlay. A native implementation must not
reraster terrain bodies four times per second. Motion cache identity includes terrain family, palette
receipt, edge identity, motion band, phase and static variant; it excludes gameplay state unrelated to art.

## Exact Asset proof

Use one fixed 11×11 top-down phone fixture at 368×800 containing:

- all twelve ground types in rule-based contacts rather than an alphabetical swatch grid;
- connected shallow and deep water with a route turning along the deep boundary;
- Stone/Rubble, Soil/Mud and Groundcover/Growth direct contacts;
- a Chasm edge, genuine elevations 0/1/2/3 and equal-height different-material boundaries;
- party, route, portal, discovered site, world resource, placed flora and one ordinary creature collision;
- one cracking tile and one already-crumbled tile;
- full, fringe, remembered and literally hidden regions; and
- three exact live receipt-backed descriptors—including one close relative and one materially opposed world—applied to
  identical geometry.

Evidence must include:

1. native 16×16 and true 400% contact sheets for every production part;
2. all 16 adjacency masks for Water, one ordinary loose surface and Growth;
3. exact color and literal-grayscale 368×800 static phones;
4. calm/moving/strong frame strips and an exported short lossless loop at exact phone scale;
5. Reduce Motion/static phone beside the animated representative frame;
6. equal-elevation material A/B proving zero wall/shade and genuine southern exposure 1/2/3 fixtures proving
   the exact authored wall/cliff plus supplemental contact shade;
7. an exact 368×800 physical-phone old/new comparison proving the replacement is equal-or-better for
   elevation readability, legal route continuity, seated occupants/overlays, row occlusion and bottom-edge
   containment before the old cue is removed;
8. hidden-south-neighbor, map-boundary and remembered-remote mutation byte-identity proofs, with zero safe
   exposure and no leaked height or material;
9. same receipt/tick, copied object and shuffled-key determinism;
10. rule receipt hashes proving geometry, passability, movement, sight and content are unchanged; and
11. a frame-difference report enforcing every per-surface pixel budget.

## Game Design visual acceptance

At native phone size and without debug labels:

- the map reads as connected material regions before it reads as a square grid;
- every rules-critical ground comparison remains immediate in literal grayscale;
- no equal-elevation material change creates a sidewall or false height;
- genuine southern exposures at levels 1, 2 and 3 retain an immediate wall/cliff read, with contact shade
  visibly supplemental rather than the sole height cue;
- no accepted placeholder or current function has been replaced by a lower-effort or lower-function version;
- shallow/deep water and Groundcover/Growth remain distinct during every motion frame;
- motion feels alive but does not resemble loot sparkle, damage, route guidance or a warning;
- route, content, cracks, party and adjacent-consequence cues retain first-read ownership;
- similar palette receipts still look related, while opposed receipts separate proportionally; and
- six seconds of observation reveals no popping seam, synchronized whole-map pulse or busy shimmer.

Passing tests alone does not authorize promotion. Asset stops at consolidated evidence and waits for Game
Design/Aimee review.

## Later Engineering slices

These are scheduled only after Asset acceptance and the active Engineering primary releases:

1. pin the immutable accepted top-surface Asset pack and reproduce its normalizer/bitmap hashes;
2. add a pure game-owned safe-neighbor/edge-contour adapter with hidden-neighbor exclusion and required
   `southExposureLevels` closure;
3. port static terrain layering behind a DEBUG comparison while preserving the current renderer and its
   functioning south-facing wall/cliff presentation;
4. integrate the final authored one-/two-/three-level wall/cliff family without changing the game-owned
   elevation, hit, route, occupant or visibility facts;
5. port transparent motion overlays and one shared pausable presentation clock;
6. compose current-full motion, static fringe, static remembered and no hidden request;
7. prove cache separation, redraw determinism and no gameplay-state mutation; and
8. capture exact old/new 368×800 physical-phone, Reduce Motion, grayscale and performance evidence. Remove
   the prior wall cue only after the candidate proves equal-or-better readability and function.

## Explicit exclusions

- no new base terrain kind, weather, puddle, improvised/transient snow or ash accumulation, erosion, current,
  wave hazard or wind rule; the separately authorized frozen Snow/Ash cover is an orthogonal rules receipt, not
  Asset-invented weather state;
- no animated placed flora, creature, resource, site, portal, crack, collapse or village asset;
- no parallax, isometric x-offset, perspective camera, **false** sidewall, unearned height extrusion or
  screen-space shader; the required genuine south-facing 1...3-level wall/cliff is not an exclusion;
- no per-world novelty optimizer or forced visual difference between similar worlds;
- no tutorial, accessibility-layout redesign, broad UI restyle or final-art claim; and
- no native/PBX/gameplay edit inside the Asset checkpoint.
