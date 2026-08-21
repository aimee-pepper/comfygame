# Atmospheric world presentation — current

**Status:** Design settled; Asset proof and native implementation queued
**Owner:** Game Design owns resolved facts, disclosure and acceptance; Asset owns the pixel grammar;
Engineering owns the frozen receipt, visibility memory and native composition
**Progression:** B1.7c — early core-loop presentation, after current encounter-scaling source closure
**Updated:** 21 August 2026

## Player promise

A world that actually contains smoke, airborne ash, mist/fog, miasma, rain, snow or strong moving
air should look and move like that world at phone size. The effect must be visible before the player
needs a receipt sentence to understand that the place is unusual, while remaining subordinate to
terrain, passability, creatures, resources and field-warning cues.

The presentation must be causally truthful:

- atmosphere is created by a resolved source, never by a generic mood palette;
- color qualifies an atmosphere that exists and never creates smoke, poison, darkness or danger;
- current light and obscuring air affect current sight, not saved terrain color;
- hidden tiles remain literally opaque and cannot leak through particles, shadows, adjacency or
  animation;
- remembered terrain is visibly a last-seen memory, not remote live surveillance; and
- a flat material/color boundary never produces a wall, riser or shadow.

This is an early world-identity feature. It is not polish and must not be held behind late buildings,
late combat-tree consumers or final art for unrelated systems.

## Current defect and authority seam

The live `WorldVisualReceipt` has one `Atmosphere` record with `medium`, `density` and palette. The
bind adapter currently produces only `none` or `smoke`, and current visibility recognizes only
`smoke` and the not-yet-produced string `ash`. Rain, Snow, Mist, Miasma and Wind exist as real
pressure sources, but do not yet have a frozen presentation identity.

Do not extend this by making render code inspect rune names or pressure readings. New binds freeze a
typed `WorldAtmospherePresentationReceiptV1` from the same resolved book used by Worldgen. Asset and
native renderers consume that receipt; neither independently decides what weather the numbers
"feel like."

## Frozen receipt

The first live schema contains the following fields. Names may follow Swift style, but their meaning
and closed cases are fixed here.

| Field | Closed values / rule |
|---|---|
| `schemaVersion` | `world-atmosphere-presentation-1` |
| `suspendedMedium` | `none`, `smoke`, `airborneAsh`, `mist`, `miasma` |
| `suspendedDensity` | finite `0...100`; exactly `0` only with `none` |
| `suspendedSourceIDs` | all exact contributing Sigil instance IDs of the selected medium, sorted |
| `precipitation` | `none`, `rain`, `snow`, `mixedRainSnow` |
| `precipitationDensity` | finite `0...100`; exactly `0` only with `none` |
| `precipitationSourceIDs` | exact contributing Rain/Snow Sigil instance IDs, sorted |
| `motionBand` | `calm`, `moving`, `strong` |
| `presentationDirection` | one of eight compass directions, deterministically frozen from the world seed; presentation only |
| `mediumPalette` | default reviewed palette or the exact eligible authored atmosphere-color receipt |
| `phaseSeed` | frozen presentation-only seed; never generation, encounter or loot RNG |
| `resolverVersion` | immutable resolver identifier included in cache/pixel identity |

The receipt is stored with the bound run and immutable World History. Save/load, anchored revisit and
redraw reproduce it exactly. It is included in the world-arrival image request so the arrival image,
map and History description cannot disagree about the world, although arrival-image implementation
remains a separate checkpoint.

### Migration

- A current valid saved `WorldVisualReceipt` whose exact medium is `smoke` migrates to Smoke with the
  same density and palette. Do not reread mutable catalogue data.
- Every other legacy bound/anchored world migrates to clear/calm presentation. Existing books are
  not reinterpreted to fabricate Rain, Snow, Mist or Wind after the fact.
- New binds use the v1 resolver.
- Unknown future cases fail closed to a clear static presentation while preserving the undecodable
  raw save envelope under the save-compatibility policy. They never fall back to a guessed medium.

## Resolution from authored causes

An eligible source contributes only when its exact Sigil is present, has non-absent intensity, is
not negated for the relevant target and survives normal projection. An unwritten/randomly rolled
Atmosphere or Hydrology magnitude does not invent a named visual medium or precipitation.

The contribution for a source uses the same Intensity, Scale and Count multipliers as the pressure
system. Same-kind contributions combine through the existing diminished-contribution authority.
No renderer duplicates that arithmetic.

### Suspended medium

Eligible exact sources are:

| Source | Receipt kind | Atmosphere contribution used |
|---|---|---|
| Smoke | `smoke` | its positive occluding Atmosphere contribution |
| Ash | `airborneAsh` | its positive occluding Atmosphere contribution |
| Mist | `mist` | its positive occluding Atmosphere contribution |
| Miasma | `miasma` | its positive occluding Atmosphere contribution |

For each kind, combine its eligible contributions. Select the kind with the greatest combined
contribution. An exact tie resolves by the lowest contributing stable Sigil instance ID. All source
IDs for the selected kind are retained. Non-selected kinds remain true authored causes in the book
and History, but the 16-pixel exploration grammar shows one dominant suspended medium rather than a
muddy stack of four effects. A later arrival/detail renderer may show subordinate causes only after
its own reviewed composition contract.

Density is the current smoke normalization generalized to the selected medium:

`clamp(round(combinedContribution / 50 × 100), 10, 100)`.

If no kind has a positive eligible contribution, use `none / 0` even when generic Atmosphere
clarity is low. Cloud, Thin Air, Hush and Wind are not silently renamed Mist or Smoke.

### Precipitation

Rain and Snow use their positive Hydrology contributions after the same authored multipliers.

- Only Rain contributes: `rain`.
- Only Snow contributes: `snow`.
- Both contribute and one is at least `1.5×` the other: use the dominant kind.
- Both contribute and neither reaches `1.5×`: use `mixedRainSnow`.
- Neither contributes: `none`.

Density uses the same bounded normalization as suspended media. Mixed rain/snow uses the diminished
combination of both contributions and retains both source-ID groups. `mixedRainSnow` is visual
sleet, not a new rune, resource, terrain type or gameplay condition.

Rain and Snow may coexist with one suspended medium because precipitation and suspended air are
different physical layers. This is not permission for Asset to add generic clouds, lightning,
puddles, ice or snowdrifts.

### Motion

`motionBand` derives only from the resolved Atmosphere `motion` aspect:

- `calm`: `motion <= 40`
- `moving`: `40 < motion <= 65`
- `strong`: `motion > 65`

Motion changes presentation speed and lateral drift only. It does not move actors, alter movement
cost, spread hazards, change projectile rules or become a direction puzzle. The eight-way
`presentationDirection` is seeded visual variation, not a revealed world fact and never appears as
a compass reading.

### Visibility ownership

Only a selected suspended medium supplies `obscurantDensity` to the current visibility profile.
Use its exact `suspendedDensity`; do not add a second material-specific coefficient. Smoke, Ash,
Mist and Miasma therefore differ through their authored contributions and visuals, not undocumented
visibility multipliers.

Rain, Snow, mixed precipitation and Wind are presentation-only in v1. They do not contract sight
until Game Design separately settles and Engineering implements a typed gameplay rule. The DEBUG
Visibility World must label those profiles `Visual only · visibility rule not implemented` until
that consumer exists.

Miasma presentation does not apply damage or poison. Its existing rules-owned pressure consequences
remain separate. Mist does not make ground wet; Snow does not freeze ordinary water; Rain does not
create Mud. Those outcomes require actual terrain/rules facts.

## Visual grammar

All exploration-map treatments are straight top-down. Atmospheric pixels are world-space overlays,
not side-view horizons, full-screen photo filters or decorative CSS. Native production output uses
lossless RGBA pixel assets/commands at the live map scale.

### Shared density bands

Asset evidence labels, but ordinary play does not display, these bands:

| Density | Band | Coverage intent |
|---:|---|---|
| 0 | none | no atmosphere pixels |
| 10–24 | trace | occasional unmistakable marks with large clean gaps |
| 25–49 | light | continuously recognizable without owning the map |
| 50–74 | heavy | strong atmosphere, terrain and icons still immediately legible |
| 75–100 | dense | oppressive but never a substitute for the visibility/fog mask |

Opacity and coverage increase monotonically inside one visual family. A density change does not
change the medium's silhouette vocabulary or palette family.

### Exact family reads

| Kind | Must read as | Must not become |
|---|---|---|
| Clear | no atmosphere overlay | generic beige haze or random "ambience" particles |
| Smoke | broad irregular plume fragments and curls that join into uneven drifting bodies across neighbouring tiles; slow rolling displacement; default neutral charcoal/warm-grey value family | parallel dash texture, scanlines, fire, clouds, black fog, UI blur or a universal dark wash |
| Airborne Ash | restrained cool-grey veil plus sparse angular falling/drifting flecks; more particulate and less billowed than Smoke | Snow, sparkles, rain, volcanic fire or a solid grey recolor |
| Mist/Fog | overlapping low-contrast dithered banks and wisps with a horizontal tendency, staggered lengths/heights and irregular clean pockets across neighbouring tiles; trace/light reads airy Mist, while heavy/dense forms unmistakably broader translucent Fog bodies | repeated scanlines, sparse scratch/dust texture at heavy density, one band copied through every tile, discrete white dots, clouds floating above a horizon or hidden-content silhouettes |
| Miasma | uneven low pooled curls/tendrils with interrupted boundaries and slower local eddies | default poison green, skulls, bubbles, damage numbers or proof of an undiscovered mechanic |
| Rain | short narrow directional streaks with sparse truthful ripples only on already-visible water pixels | puddles, Mud, lightning, clouds, screen-long lines or a movement-cost cue |
| Snow | slower compact flakes with lateral drift; no automatic terrain whitening in v1 | Rain, permanent accumulation, frozen water or a new white ground material |
| Mixed rain/snow | visibly interleaved narrow Rain streaks and compact Snow flecks in the same direction | a third fantasy particle, hail damage or an invented named weather system |

Default palette separates families by value, particle shape, spacing and motion—not hue alone. An
eligible authored atmosphere color tints only the selected medium family. It preserves the family's
literal-grayscale value ordering and cannot tint terrain, water, flora, actors, fog or precipitation
from a different source.

The 16×16 tile is an implementation cell, not the visible scale of the atmospheric composition.
Smoke and Mist/Fog must use stable tile coordinates to form an irregular multi-tile macro-pattern;
repeating the same horizontal marks once per tile fails this contract even when each isolated cell is
technically different. Heavy/dense coverage may leave fewer clean pockets, but it must not turn the
map into a uniformly striped texture. Conversely, avoiding stripes by reducing Fog to scattered
one-pixel marks also fails: density must change the visible mass/coverage monotonically, and heavy Fog
must read clearly stronger than light Mist at ordinary phone scale.

Wind has no standalone speed-line overlay because motion is not matter. It changes the drift of an
existing suspended/precipitation layer. Once the separately accepted terrain-motion contract exists,
the same motion band may drive grass/water motion. A clear world with no movable layer may therefore
look still even when its Atmosphere motion is high; the renderer must not invent dust to advertise it.

### Native motion

- Particle/plume placement is deterministic from `phaseSeed`, tile coordinate and layer kind.
- Animation advances from UI presentation time only and pauses when the scene is not active. It
  never consumes a turn or advances any game RNG.
- `calm`, `moving` and `strong` use the same identity at increasing bounded travel speed. Strong air
  may not triple particle count or obscure more of the map; density owns coverage.
- Effects tile continuously across map cells and do not pop to new unrelated positions every frame.
- Reduce Motion/static evidence uses one frozen representative phase derived from `phaseSeed`.
- Atmospheric pixels never change hit targets, layout size, map bounds or the 11×11/phone viewport.

## Composition and disclosure

Native composition order is exact:

1. opaque game-owned map backdrop;
2. currently legal terrain and genuine elevation contact shade;
3. terrain decoration and static flora/resource art permitted by the visibility state;
4. suspended-medium veil/body;
5. precipitation/particulate marks;
6. currently visible actors, interactable contents and field consequence cues;
7. selection, route, Look/Use feedback and player marker;
8. current-visibility/fringe/remembered treatment;
9. opaque hidden mask and fog-boundary softening;
10. HUD and tutorial overlays.

Atmosphere is clipped to **current full or current fringe** tiles before composition. It does not
animate across remembered tiles because those tiles are memories, not a live remote view. The hidden
mask is authoritative and literally opaque black. A hidden tile constructs no terrain or atmosphere
art request, does not sample hidden-neighbour pixels and remains byte-identical across hidden
terrain/content fixtures.

Current fringe may show the same atmosphere family at the existing fringe opacity/blur, but contains
terrain silhouette only. It never reveals flora, resource, site, portal, page, traveller, creature,
crack or particle-shaped content.

## Remembered world state

The four-state table in `cross-lead-delivery-contract-current.md` remains canonical. This checkpoint
adds the minimum snapshot needed to honor it without remote disclosure.

When a tile is in current full visibility, rules update a versioned `LastSeenTileSnapshot` with:

- ground identity, elevation, passability/crumbled state and cracking state as last seen;
- last-seen stationary flora identity/neutral pose;
- last-seen fixed resource node identity and remaining visible body stage;
- an already-discovered fixed site or portal identity/state; and
- route/entry/exit knowledge already legitimately disclosed.

Do **not** store a moving enemy, apex location, traveller, loose wild drop, loose World Page, active
hostile-flora pose, current selection, warning cue, particle phase or undiscovered content.

When currently hidden but permanently revealed, the exploration map renders the frozen snapshot in
the remembered treatment. If current world state changes remotely, memory remains stale until the
tile is seen again; the old snapshot must not update and reveal that mutation. Remembered atmosphere
is absent. Remembered resources and sites are visibly dim/subordinate, and accessibility labels say
`Last seen ...`, never assert that the object is still present.

Legacy revealed tiles without a snapshot render the existing terrain-only memory until revisited.
Do not synthesize a current resource/site snapshot during decode.

The minimap remains permanent legitimate knowledge. It may show a previously discovered POI class,
but never current enemy positions, undiscovered POIs, live quantities or remote state changes.

## Genuine elevation contact shade

This checkpoint does not restore false sidewalls.

- Equal-elevation neighbours produce no elevation shade regardless of material, ground type,
  palette, water, fog or world-grade color.
- A visible cardinal edge with a real positive elevation difference may shade only the **lower
  horizontal surface** immediately beside that shared edge.
- Shade depth is one logical pixel for one elevation step and at most two logical pixels for two or
  more steps. The second pixel is a dithered fade, not a solid band.
- Shade color is a bounded darker value from the lower material family. It is never an opaque black
  rectangle or a separately colored vertical face.
- Hidden neighbours contribute no height, shade or exposure. At the fog edge, disclosure owns the
  boundary.
- Current ordinary light uses the reviewed full shade; dim light weakens it; pitch black contributes
  no live shade. Remembered snapshots use one restrained static contact contour derived only from
  last-seen elevations.
- Cracks, routes, resources, flora and warning cues composite after the contact shade and remain
  legible.

This is ambient top-down height separation. It does not claim a sun direction, create climb rules or
add collision.

## Asset checkpoint

Asset must produce one bounded, reusable atmosphere kit—not attractive full-screen snapshots that
cannot be composed at runtime.

Required products:

1. exact native-scale reusable pixel families for Smoke, Airborne Ash, Mist/Fog, Miasma, Rain, Snow
   and mixed Rain/Snow;
2. a manifest containing stable family IDs, native dimensions, palette ramps, density band, phase
   seed, motion-band input, layer order and binary/static fallback;
3. the exact true-elevation contact-shade command/asset grammar;
4. lossless 368×800 phone proofs using the same fixed Earth-like 15×15 fixture and camera;
5. literal-grayscale proofs and a native-scale contact sheet; and
6. deterministic export/tests proving no geometry, disclosure or map-layout mutation.

The review matrix contains, at minimum:

- clear, trace/light/heavy Smoke;
- light/heavy Airborne Ash;
- light/heavy Mist/Fog;
- light/heavy Miasma;
- Rain, Snow and mixed Rain/Snow at light/heavy density;
- one Smoke+Rain and one Mist+Snow composition;
- calm/moving/strong motion using the same density and seed;
- current full/fringe/remembered/hidden boundaries with a resource, fixed site, ordinary creature
  and remote mutation fixture;
- equal-elevation different-material neighbours proving zero sidewall/shade;
- one-step and two-step genuine height neighbours proving contact shade; and
- color, literal grayscale and static/reduced-motion variants.

Every proof labels its fixture facts outside the phone frame. No label, legend or debugging value may
be required for the in-frame atmosphere to read correctly. HTML/CSS may host review controls but is
not production art. `integrationReady` remains false until Game Design and Aimee accept the named
manifest/hash.

## Engineering implementation slices

Do not start these while encounter scaling is the sole active Engineering primary. After that
checkpoint closes, the dependency-safe order is:

1. **Receipt/resolver:** typed v1 schema, exact source resolver, migration, persistence, hash/cache
   identity and unit fixtures. No UI.
2. **Visibility consumer:** generalize the existing obscurant input to the typed selected suspended
   medium; Rain/Snow/Wind remain presentation-only; add fail-closed tests.
3. **Memory snapshot:** versioned `LastSeenTileSnapshot`, update only in current full sight, tolerant
   legacy terrain-only behavior and disclosure tests.
4. **Native atmosphere compositor:** consume the accepted Asset kit behind the game-owned
   full/fringe/remembered/hidden states; no renderer-side source inference.
5. **Elevation contact shade:** consume actual visible/last-seen elevation only; equal-elevation and
   hidden-neighbour counter-fixtures are mandatory.
6. **DEBUG Visibility World:** turn the already specified eight-profile fixture into the acceptance
   harness; upgrade Rain/Snow/Fog labels from `Visual only` only when their typed consumers exist.
7. **Ordinary phone acceptance:** new bind, movement through visibility boundaries, save/load,
   anchored revisit and one remote-mutation memory check from an exact installed build.

Each slice owns one rules transaction or pure projection. `WorldView` does not reconstruct the
receipt, decide weather from source strings or write snapshots during view rendering.

## Non-goals

This checkpoint does not add:

- a procedural weather schedule, weather changing during a run or weather forecasts;
- clouds, lightning, hail, thunder, puddles, snowdrifts, frozen water or new terrain;
- Wind movement costs, projectile effects, hazard spread or directional navigation;
- Miasma damage, poison, Smoke suffocation or protective gear rules;
- a screen-wide color filter, post-processing blur over UI or per-world novelty randomization;
- new sigils, color-mixing acquisition, the arrival splash itself or splash-site disclosure;
- final terrain layering/water/grass motion; or
- live tracking of enemies, resources or sites outside current sight.

## Acceptance gates

The checkpoint passes only when all are true:

1. **Causal identity:** each named treatment appears only from its exact typed resolved cause; clear
   counter-fixtures remain clear despite similar numeric pressure readings.
2. **Distinct read:** all seven families are distinguishable at native phone scale in color and
   literal grayscale by shape/spacing/motion, not labels or hue alone.
3. **Proportional density:** trace < light < heavy < dense is monotonic inside each family without
   hiding terrain, actors, resources, route or warning cues.
4. **Disclosure:** hidden tile RGBA is identical across different hidden ground/content/atmosphere;
   fringe and remembered never reveal live content.
5. **Memory honesty:** last-seen fixed content persists visually, a remote mutation does not update
   it, and revisiting refreshes it; moving entities are absent.
6. **No false walls:** equal-elevation material/color changes produce no height shade; only genuine
   visible/remembered elevation edges do.
7. **Rule isolation:** atmosphere animation and profile switching consume no turns, no RNG and no
   save/economy/combat state; Rain/Snow/Wind do not change sight in v1.
8. **Persistence:** new bind, relaunch, anchored revisit and redraw reproduce identical receipt and
   static frame; legacy Smoke migrates exactly and other legacy worlds do not gain guessed weather.
9. **Performance/layout:** ordinary phone viewport, targets and HUD remain unchanged; representative
   dense combined atmosphere stays within the existing map-frame performance budget without scroll
   or clipping.
10. **Arrival handoff:** the same immutable receipt is available to the later dynamic arrival-image
    and description generator, with no independent re-resolution.
