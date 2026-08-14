# World-grade-2 v1 production pack — Design review

**Status:** corrected immutable pack accepted by Game Design for native conformance integration;
native phone color/grayscale acceptance remains.
**Reviewed:** 11 Aug 2026.
**Scope:** Game Design review of the generated schemas/manifest/vectors in
`AssetLab/integration/world-grade-2-v1/`. Engineering portability/hash review remains separate.

## What passes

The first pack correctly establishes a new production boundary rather than renaming the exploratory
v0.2 proof. It provides closed request/descriptor schemas, explicit frozen pipeline versions,
canonical serialization/digests, nine request→descriptor vectors, command/geometry/RGBA/PNG hashes,
monotonic identical/near/mid/far evidence, opposed composition and fog invariance. It structurally
rejects Illumination, raw Vitality, authored ink recipes, named Sigil colors, current visibility and
the art categories Aimee reserved.

The accepted calibration strengths and relative-diversity rule remain unchanged: twins may match,
near worlds stay related and meaningful far/opposed inputs separate proportionally. No broad palette
recalibration is requested.

## Blocker 1 — one world-level flora color collapses species identity

The request/descriptor currently stores one optional exact `resolvedColors.flora` and
`worldGrade2V1Color` blends that same sRGB value into every flora sprite. This is not the settled
meaning of a colored Bloom or open flora color.

Each persisted species owns its anatomy and base palette relationship. A Bloom color is a
world/ecology **tendency** that influences the cast as species palettes resolve; it is not the final
color of every plant. Final per-species palettes/tendencies must be frozen so redraw, revisit and
generator updates cannot reroll them.

Required correction:

- represent an optional world-level flora color tendency separately from final colors;
- give each cast member an exact persisted resolved palette/color result (or an equivalently exact
  species-palette descriptor);
- preserve stable `speciesID`, form and stature without deriving color from placement;
- add a two-to-four-species vector where one shared Bloom/open tendency still produces visibly
  distinct, stable species palette relationships in color and literal grayscale; and
- reject a cast member whose resolved palette is missing, duplicated under another species ID or
  silently supplied by a global fallback.

This does not require Creature color; Creature remains excluded.

## Blocker 2 — six live ground families have no declared color owner

The renderer currently applies material family/transform only to:

`stone`, `soil`, `sand`, `ash`, `rubble`, `mud`.

It silently skips:

`water`, `deepWater`, `ice`, `growth`, `groundcover`, `chasm`.

Not every ground must accept the same material transform. Indeed, doing so could create the rejected
global wash. But every one of the twelve live ground grammars needs an explicit palette owner and
invariance statement. Water/deep water may resolve through Hydrology/temperature; ice through
thermal/hydrology; growth/groundcover through an ecology-compatible ground palette; chasm may remain
deliberately value-stable. Those are legitimate scoped choices. Silent omission is not.

Required correction:

- add a closed all-twelve-ground ownership table to the manifest/contract;
- declare for each ground which material, hydrology/thermal, ecology, atmosphere and emitter layers
  may affect it;
- preserve terrain identity, adjacency, elevation, cracking, passability and disclosure;
- include representative vectors proving ordinary water/deep water remain related but distinct,
  ice keeps its identity, growth/groundcover cohere without becoming flora species, and chasm remains
  legible under the accepted near/far/opposed grades; and
- make unsupported scope application fail or remain explicitly invariant rather than disappearing
  through a private `generalGrounds` list.

## Acceptance after correction

The pack may return to `integrationReady:true` when:

1. manifest/schema/hash/vector tests are regenerated from the corrected contract;
2. per-species palette persistence and shared-tendency distinction are directly covered;
3. all twelve grounds have explicit scope ownership and representative conformance evidence;
4. the original similarity, fog, no-Illumination/no-raw-Vitality and exclusions remain intact; and
5. Engineering independently accepts canonical-number portability, native version/cache/migration
   ownership and exact vector reproducibility.

Until then, Engineering keeps world-grade v1 native behavior and must not pin the candidate manifest.

## Corrected-pack disposition — 11 August 2026

**Design accepted for native conformance implementation.** The regenerated pack closes both prior
blockers without reopening the accepted calibration:

- `floraTendency` remains a game-resolver input and is deliberately absent from the renderer
  descriptor; each persisted cast member now carries its own required `speciesID`, form, stature and
  frozen `resolvedColor`;
- the four-species conformance vector proves four distinct resolved colors survive one shared world
  tendency, while changing only that tendency after resolution leaves the frozen descriptor
  unchanged;
- the manifest now assigns every live ground family to an explicit owner: six material grounds,
  hydrology-owned water/deep water/ice, ecology-owned growth/groundcover and atmosphere-visible void
  for chasm; and
- the closed schemas, canonical manifest, byte hashes and ten vectors retain the original
  similarity, empty-fog and excluded-input guarantees.

The AssetLab suite passes with canonical manifest hash
`e601d2f77a15d545fd2d893dbb2e41891518cba2900c3f6d66890d56294824c1`; the three packaged file
hashes also match their manifest entries. Engineering may now pin this exact immutable pack and
port it by conformance rather than interpretation. This is acceptance of the **contract**, not final
acceptance of native phone appearance: native color and literal-grayscale evidence still gates
promotion, and similar worlds must remain allowed to look similar.
