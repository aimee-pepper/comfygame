# Top-down map asset integration — current first playable slice

**Status:** frozen boundary implemented and pushed in native checkpoint `a7a99bc`; retain as the
world-grade-1/native geometry conformance authority  
**Owner:** Engineering + Asset Lead, reviewed by Game Design  
**Updated:** 9 Aug 2026

> **11 Aug color-semantic supersession:** `world-grade-1.0.0` remains immutable and authoritative
> for worlds/native fixtures that record it, but it is not the future color model. Its direct
> Illumination→brightness and Vitality→green mapping is superseded by Decision127 and
> `world-color-differentiation-current.md`. Terrain geometry, camera, adjacency, elevation, seed,
> fog, disclosure, layering and native-pixel requirements below remain current. A reviewed
> world-grade-2 contract must use a new version/descriptor and cannot silently mutate v1 hashes.

**Canonical manifest:** `AssetLab/integration/map-slice-v1/manifest.json`, canonical manifest SHA-256
`f776ae97f252f462570014ca81d06df40e5a6de82aaa06c53671310e1912c28d`. This supersedes `05e23…`
only; the immutable pipeline tuple, 198 outputs and renderer pixels are unchanged. The correction
truthfully specifies invariant fog fill and exact same-ground cardinal adjacency.

## Outcome

Replace the exploration grid's flat colour/SF-Symbol presentation with the accepted AssetLab
top-down terrain and flora grammar in the playable iOS build. This is a visual adapter milestone,
not a world-generation rewrite. Movement, passability, sight, reveal, collision, interaction and
content disclosure remain owned by the current game rules.

The first slice is successful when ordinary exploration visibly uses the new terrain and overhead
flora on device, while the old simple renderer remains available as a DEBUG fallback.

## Camera and native scale

- Every explorable-map asset is straight top-down. This includes ordinary flora and triggered active
  flora; hostility changes radial pose, never camera.
- Compose at a native **16×16 pixels per tile** and scale with nearest-neighbour sampling. SwiftUI
  layout/tap geometry remains independent of those pixels.
- The viewport and clamped-follow camera do not change merely to fit the art.

## Exact renderer inputs

Terrain receives only saved/live tile facts:

```text
ground: all 12 live GroundType values
adjacency: N/E/S/W mask derived from neighbouring ground/edge family
revealed, crumbled, cracking, elevation
world seed + tile coordinate + terrain pipeline version
world-grade inputs derived from the saved world readings through a versioned adapter
```

The renderer must not collapse each ground to one canonical coloured tile. Every ground owns a
bounded family of compatible feature templates, selected deterministically per placement, and the
whole world receives a coherent world-conditioned visual grade. Ground/state/adjacency owns
affordance; world grade owns shared atmosphere; placement template owns mechanically neutral surface
variation. Palette and detail never invent or hide passability, resource, route, crack, elevation,
site or hazard facts. World grade may suggest the world's known character but must not encode exact
hidden values or authored rune IDs.

### Frozen world-grade adapter v1 — historical/native compatibility

The first native slice needs an exact mapping rather than arbitrary “warm” and “cool” presets. Use
resolved, post-constraint `PressureReadings` from the saved bound book and map only broad visible
environmental character. This grade is a visual suggestion, not an analysis surface.

```text
center(x) = clamp((x - 50) / 50, -1, 1)
mid(reading) = (reading.peak + reading.floor) / 2

warmth   = center(mid(thermal))
wetness  = center(hydrology.availableMagnitude)
life     = center(vitality.peak)
light    = center(mid(illumination))
mineral  = center(substrate.peak)

red   = round(clamp(24*warmth + 8*mineral, -32, 32))
green = round(clamp(22*life + 8*wetness, -32, 32))
blue  = round(clamp(20*wetness - 8*warmth, -32, 32))
value = round(clamp(16*light + 4*mineral, -20, 20))
```

The four signed integers are stable for the whole world and become the AssetLab `worldGrade` input.
Use ordinary round-to-nearest with halves away from zero in both implementations and fixture the
same vectors cross-language. Do not incorporate current turn/day-night phase: a tile must not change
species/material identity as the clock moves. Lighting overlays may later express time separately.
Do not incorporate authored rune IDs, greed, Stability, traveller signature matches or undiscovered
content. Bump the adapter/pipeline version before changing coefficients.

Required conformance vectors:

| Thermal midpoint | Available water | Vitality peak | Light midpoint | Substrate peak | Grade `(r,g,b,v)` |
|---:|---:|---:|---:|---:|---:|
| 50 | 50 | 50 | 50 | 50 | `(0,0,0,0)` |
| 90 | 20 | 25 | 80 | 75 | `(23,-16,-18,12)` |
| 10 | 90 | 85 | 20 | 30 | `(-22,22,22,-11)` |

The output bounds deliberately stay narrower than AssetLab's emergency accepted range. World-grade
shifts must preserve minimum value separation between ordinary/deep water and all passability-owned
edges in both colour and grayscale.

Flora receives the exact persisted flora identity/traits and the placement's stable species/world
inputs. A view redraw, navigation cycle or app relaunch must not reroll it. The renderer may use
render-only topology hints but may not infer or disclose hidden yield, defence, senses or toxicity.

AssetLab proof defaults, random buttons and sample-world descriptors are never native game inputs.
The app-facing adapter uses a versioned closed manifest/command contract and rejects unknown enum
values rather than silently substituting plausible art.

### Frozen native terrain-seed adapter v1

Do not use Swift `Hasher`, `hashValue`, redraw RNG or proof seed 404. Build this ASCII/UTF-8 payload
with decimal integers and the exact manifest tuple in the shown order:

```text
bookbinder-terrain-seed-v1|<mapSeed UInt64>|<x Int>|<y Int>|1|1|1|1|world-grade-1.0.0|map-slice-1.1.0|rect-compositor-0.2.0|top-down-map-16px-1.0.0
```

Hash its bytes with standard **FNV-1a 32-bit** (offset basis `2166136261`, xor each byte, then
multiply modulo 2^32 by `16777619`). The unsigned result is `terrainSeedUInt32` and
`featureVariant = terrainSeedUInt32 & 3`. Coordinates use the persisted map's zero-based logical
grid coordinates, never viewport/screen position. The delimiter is safe because every version token
in this tuple is closed and cannot contain `|`; changing the tuple or payload prefix is a versioned
visual-identity change.

Fixture the canonical payload string as well as its result so an apparently harmless formatting or
integer-transport change cannot reroll existing maps. This seed chooses only mechanically neutral
terrain variation. Flora identity continues to use its separately documented persisted ID/worldSeed
adapter and must not consume the terrain seed.

Required seed vectors:

| `mapSeed` | `(x,y)` | `terrainSeedUInt32` | Variant |
|---:|---:|---:|---:|
| `0` | `(0,0)` | `1940317494` | `2` |
| `18446744073709551615` | `(10,10)` | `3919347185` | `1` |

## Layer ownership

Render one tile in this order:

1. revealed terrain and adjacency/elevation treatment;
2. ordinary overhead flora/decor legitimately present on the tile;
3. crack overlay, after terrain/flora so structural danger remains visible;
4. disclosed tile content, site, traveller or visible enemy;
5. route/action/target overlays;
6. party/current-position/selection treatment.

Crumbled/chasm/passability remain rule facts, not colour guesses. Deep water remains impassable and
visually distinct from ordinary water; water transitions use water-family edges rather than tan
corridors. Crack and elevation each use redundant shape/value, not colour alone.

**Fog short-circuits ordinary tile composition.** An unrevealed tile draws the accepted empty fog
value and no terrain texture, flora, tile-body content, route, site, resource, traveller, enemy or
decorative hint. The complete world descriptor must not leak into the fog renderer. There are no
type-based minimap exceptions: portals, writing and apex locations are also hidden until legitimate
reveal/discovery state permits their overlay (`minimap-disclosure-current.md`).

## Content and interaction

This slice may retain existing content symbols temporarily if replacing all ten content families
would delay terrain/flora playtesting. Their visible geometry must remain distinct in native
grayscale, and the following ownership cannot regress:

- entry and exit portals differ;
- traveller and wild drop cannot collide;
- chasm contains no action or route;
- a location-only apex mark reveals no apex identity;
- sites/writing/resources appear only under their settled discovery rules;
- party, route and action remain legible over every ground family and crack state.

The entire tile remains the tap target currently owned by the map. D-pad navigation remains primary;
16px art must never shrink accessibility labels or control geometry.

## Minimap boundary

Do not turn the minimap into a thumbnail of the art. It remains a disclosure-neutral symbolic map.
Revealed terrain/growth class and party position follow ordinary knowledge. Every point of interest—
including portals, writing, sites, resources/items, travellers, encounters and the singular apex—is
fog/discovery-gated by default. The entrance portal is visible only because its starting tile is
legitimately revealed. Explicit invested knowledge effects may reveal a bounded location or region;
the asset layer never grants that knowledge. The minimap shows no plant dots, species, exact hidden
resource family, undiscovered site or creature identity. See `minimap-disclosure-current.md`.

## Native adapter choices

Engineering may port the small rectangle/line command compositor to Swift or consume a generated
atlas plus versioned manifest. Do not embed a browser/JavaScript runtime in the game and do not copy
proof-page UI logic into production. The selected path must preserve:

- exact manifest/pipeline versions and deterministic hashable inputs;
- bounded 16×16 output with no clipping;
- nearest-neighbour display and stable sRGB/RGBA interpretation;
- explicit composition of transparent sprite padding/overhang over the game-owned terrain/fog field;
  transparent pixels must never reveal an implicit white/system view background or create seams
  between adjacent tiles;
- a visible DEBUG fallback to the previous simple tile renderer;
- no filesystem/network dependency during ordinary play.

“Port” means semantic equality with the accepted AssetLab command grammar, not a new Swift grammar
that merely uses similar colours and rectangles. Every conformance fixture applicable to the chosen
runtime path must reproduce its normalized rectangle commands and/or exact 16×16 RGBA pixels under
test. The fixture pack is not an exhaustive atlas; equality on fixtures proves the port while live
descriptors continue to generate the broader range. Rasterize at 16×16 first and display that image
with interpolation disabled. Drawing commands directly into a point-scaled Canvas at fractional
boundaries is not evidence of native-pixel or nearest-neighbour behavior.

For fog, “empty” is semantic rather than transparent: the accepted renderer returns exactly one
uniform `#17171a` fill and no terrain-/flora-/content-dependent commands. It must not consult hidden
descriptor layers. The earlier manifest field name `containsPixels:false` is misleading because the
conformance source and test deliberately contain that one concealment fill; the corrected manifest
must say **no informative/descriptor-dependent pixels**, not claim zero raster pixels.

## Verification gate

1. All 12 ground types render at native scale in colour and grayscale; water/deep-water and all 16
   water-family adjacency masks remain distinct and bounded. Each ground exercises multiple
   compatible feature templates, and at least two materially different world-grade vectors recolour
   a coherent whole-world set without losing invariant affordance/value grammar.
2. Same save/seed/coordinate produces identical terrain and flora pixels after relaunch; a different
   coordinate may select a different compatible terrain template, a different world grade changes
   the family coherently, and a different specimen placement does not mutate flora species identity.
3. Fog contains no non-fog pixels even when hidden content/flora/site/enemy inputs exist.
4. Route, party, portal, writing, resource, traveller, site, visible creature, crack and chasm are
   exercised together; interaction/passability results match the pre-art renderer.
5. Minimap disclosure is byte/semantic-equivalent to the prior rules unless an intentional reviewed
   symbol substitution is recorded.
6. Native map scrolling/following is responsive on the target simulator/device with no redraw RNG,
   geometry warnings or clipped sprites.
7. The fast game suite, relevant map/reveal fixtures, AssetLab contract tests and a simulator
   exploration pass are green before commit/push.
8. Native conformance tests catch a one-command geometry/color mutation and a one-pixel RGBA mutation;
   visual similarity alone cannot bless an approximate reimplementation.

## Explicitly later

Combat sprites/UI, animation, portraits, splash animation, bestiary art, full content-family
replacement and authored base architecture are not prerequisites for this playable map slice.
