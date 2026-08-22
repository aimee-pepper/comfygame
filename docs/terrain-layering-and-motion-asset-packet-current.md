# Terrain layering and motion — Asset production packet

**Status:** Game Design complete; held behind the active World Arrival correction
**Priority:** B1.7b, after B1.6a visual acceptance; not a native implementation assignment
**Owners:** Game Design owns terrain meaning, disclosure and motion limits; Asset owns the isolated logical
pixel kit and compositor proof; Engineering later owns the native receipt adapter, cache and shared clock
**Updated:** 21 August 2026

## Player result

The explorable map remains a straight top-down, tile-addressable world, but it should no longer read first as
a spreadsheet of individually filled squares. Ground materials meet through irregular top-surface contours;
water, rock, loose ground and growth have an obvious physical order; and a few surfaces move gently enough
to make the world feel present without changing, hiding or predicting a single rule.

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

- Every explorable-map terrain source is **straight top-down**. No horizon, front wall, side face, isometric
  lift or shallow tableau camera is permitted.
- One game tile remains exactly **16×16 logical RGBA pixels** before integer nearest-neighbour scaling.
- Production sources are exact bounded-palette logical pixel bitmaps or reviewed binary masks. HTML, CSS,
  SVG, antialiased canvas paths and procedurally drawn rectangles may present evidence but are not production
  art.
- Generated or painted composition references are `productionSource:false`. Asset must deliberately author
  the final logical pixels and publish their exact hashes.
- Each tile paints every one of its own visible pixels. Layer contours never leave transparent cracks between
  tiles or draw outside the tile's 16×16 ownership rectangle.
- The accepted `world-grade-2` descriptor recolors reviewed material ramps. This packet does not create a
  second palette resolver or read raw pressure values.

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
7. genuine elevation contact shade from the separate accepted atmosphere contract;
8. cracking/crumbled truth, route and stationary visible flora/resource decoration;
9. atmosphere, precipitation, actors, content and field-feedback layers in their already-settled order.

Priority resolves a boundary's visual overlap; it does not change either tile's ground identity. A higher
layer may intrude at most two pixels into the lower-priority tile's side of a shared contour, using its own
**top-surface** colors. It may never add a dark vertical strip or exposed sidewall.

## Exact ground-family grammar

| Ground | Required first read | Static top-surface form | Motion in v1 | Prohibited implication |
|---|---|---|---|---|
| Stone | ordinary hard ground | joined plates, fine irregular seams, sparse chips | none | Ore, richness or raised blocks |
| Soil | ordinary worked/earthen ground | small clods, shallow value pockets, soft broken edge | none | Mud slow, furrows or a guaranteed crop |
| Sand | ordinary loose ground | low ripples and granular pockets with an irregular dry edge | none | quicksand, wind hazard or treasure |
| Ice | solid passable surface | continuous hard sheet, restrained cracks trapped inside the surface | rare glint only | shallow/deep water or slipperiness not owned by rules |
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

## Elevation and false-sidewall prohibition

Material boundaries and height are independent.

- Equal-elevation neighbors produce **no** contact shadow, wall or vertical face regardless of color,
  palette, material, water depth or edge contour.
- Different elevations retain the already-accepted one- or two-pixel contact shade on the **lower tile**
  only. That shade is composed after terrain and is not part of these material bitmaps.
- Terrain animation cannot move, widen or recolor the elevation shade.
- An elevation difference does not authorize a side-view cliff face. The world map stays top-down.
- The former `southExposure` lifted-wall grammar is outside this production contract and must not be copied
  into new Asset sources.

## Frozen render request

The Asset proof accepts exactly one closed request per currently constructed tile:

| Field | Type | Owner and use |
|---|---|---|
| `schemaVersion` | literal `terrain-layers-v1` | fail closed on another version |
| `ground` | exact 12-value `GroundType` | game rules; chooses reviewed terrain family |
| `point` | integer x/y | edge and phase identity only; never display |
| `visualSeed` | unsigned frozen value | deterministic detail, contour and phase offsets; no gameplay RNG |
| `worldGradeDescriptorHash` | accepted stable hash | selects the already-resolved palette receipt |
| `featureVariant` | `0...3` | frozen static detail variant |
| `cardinalNeighbors` | N/E/S/W safe fact | exact disclosed neighbor or `unknown` |
| `edgeContourIDs` | N/E/S/W `0...3` | canonical shared edge identity |
| `elevation` | `0...2` | supplied for external contact-shade composition only |
| `isCrumbled` | Boolean | game-owned missing/unsafe state; static override |
| `isCracking` | Boolean | game-owned overlay selection; never inferred from texture |
| `visibility` | `full`, `fringe`, `remembered` | hidden has no request |
| `motionBand` | `calm`, `moving`, `strong` | accepted Atmosphere-derived presentation band |
| `phaseOffset` | `0...23` | frozen from seed, point and terrain family |
| `presentationTick` | nonnegative integer | shared UI clock input; never persisted or used by rules |
| `reduceMotion` | Boolean | current presentation policy, not campaign state |

No pressure numbers, passability booleans, resource/site/entity facts or prose enter Asset. Asset does not
infer a mechanic from pixels; the game continues to own labels, Look text, hit testing and pathing.

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
| Ice | one rare glint event per eligible six-second loop | same | same | at most 3 pixels on the eligible 25% of Ice tiles |

Water motion changes short internal ripple/highlight pixels only. It cannot change the shoreline, depth
contour, route read or a tile's apparent passability. Adjacent water tiles use their shared edge identity
and phase offsets so a ripple crossing a boundary does not pop or reverse at the seam.

Groundcover and Growth flex within one pixel of a fixed top-down cluster. Their density, height silhouette,
far edge and visible content aperture remain fixed. Strong motion changes cadence, not pixel count or
mechanical severity.

Ice glints are sparse hard-surface reflections, not a collectible sheen, rarity sparkle or hazard warning.
Only one quarter of Ice tiles are eligible by stable seed; at most one three-pixel event appears in their
six-second loop. Stone, Soil, Sand, Ash, Rubble, Mud and Chasm are static in v1. Clear air does not invent
dust; Rain does not create puddles; Snow does not accumulate; Mud does not bubble.

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

1. twelve 16×16 terrain-family top-surface kits with four reviewed static detail variants each;
2. four complementary cardinal contour-mask families and all 16 N/E/S/W adjacency combinations;
3. explicit Water/Deep-Water depth-contour, Growth/Groundcover height-boundary and Chasm-rim parts;
4. Water and Deep-Water motion frames, Groundcover and Growth flex frames, and Ice glint overlay frames;
5. a pure request normalizer and compositor exporting static body and transparent motion overlay separately;
6. manifest dimensions, pivots, palette slots, layer ownership, phase counts, command/bitmap hashes and
   `integrationReady:false`; and
7. no static whole-map image as a production source.

The static body must be cacheable independently of the motion overlay. A native implementation must not
reraster terrain bodies four times per second. Motion cache identity includes terrain family, palette
receipt, edge identity, motion band, phase and static variant; it excludes gameplay state unrelated to art.

## Exact Asset proof

Use one fixed 11×11 top-down phone fixture at 368×800 containing:

- all twelve ground types in rule-based contacts rather than an alphabetical swatch grid;
- connected shallow and deep water with a route turning along the deep boundary;
- Stone/Rubble, Soil/Mud and Groundcover/Growth direct contacts;
- a Chasm edge, genuine elevations 0/1/2 and equal-height different-material boundaries;
- party, route, portal, discovered site, world resource, placed flora and one ordinary creature collision;
- one cracking tile and one already-crumbled tile;
- full, fringe, remembered and literally hidden regions; and
- the accepted current palette descriptor plus one near-related and one far-related descriptor applied to
  identical geometry.

Evidence must include:

1. native 16×16 and true 400% contact sheets for every production part;
2. all 16 adjacency masks for Water, one ordinary loose surface and Growth;
3. exact color and literal-grayscale 368×800 static phones;
4. calm/moving/strong frame strips and an exported short lossless loop at exact phone scale;
5. Reduce Motion/static phone beside the animated representative frame;
6. equal-elevation material A/B proving zero wall/shade and genuine-height A/B proving only accepted contact
   shade;
7. hidden-neighbor mutation and remembered-remote-mutation byte-identity proofs;
8. same receipt/tick, copied object and shuffled-key determinism;
9. rule receipt hashes proving geometry, passability, movement, sight and content are unchanged; and
10. a frame-difference report enforcing every per-surface pixel budget.

## Game Design visual acceptance

At native phone size and without debug labels:

- the map reads as connected material regions before it reads as a square grid;
- every rules-critical ground comparison remains immediate in literal grayscale;
- no material change creates a sidewall or false height;
- shallow/deep water and Groundcover/Growth remain distinct during every motion frame;
- motion feels alive but does not resemble loot sparkle, damage, route guidance or a warning;
- route, content, cracks, party and adjacent-consequence cues retain first-read ownership;
- similar palette receipts still look related, while opposed receipts separate proportionally; and
- six seconds of observation reveals no popping seam, synchronized whole-map pulse or busy shimmer.

Passing tests alone does not authorize promotion. Asset stops at consolidated evidence and waits for Game
Design/Aimee review.

## Later Engineering slices

These are scheduled only after Asset acceptance and the active Engineering primary releases:

1. pin the immutable Asset pack and reproduce its normalizer/bitmap hashes;
2. add a pure game-owned safe-neighbor/edge-contour adapter with hidden-neighbor exclusion;
3. port static terrain layering behind a DEBUG comparison while preserving the current renderer;
4. port transparent motion overlays and one shared pausable presentation clock;
5. compose current-full motion, static fringe, static remembered and no hidden request;
6. prove cache separation, redraw determinism and no gameplay-state mutation; and
7. capture ordinary phone, Reduce Motion, grayscale and performance evidence before native promotion.

## Explicit exclusions

- no new terrain kind, weather, puddle, snow accumulation, erosion, current, wave hazard or wind rule;
- no animated placed flora, creature, resource, site, portal, crack, collapse or village asset;
- no parallax, isometric lift, perspective camera, sidewall, height extrusion or screen-space shader;
- no per-world novelty optimizer or forced visual difference between similar worlds;
- no tutorial, accessibility-layout redesign, broad UI restyle or final-art claim; and
- no native/PBX/gameplay edit inside the Asset checkpoint.
