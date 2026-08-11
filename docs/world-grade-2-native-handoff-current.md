# World-grade-2 native handoff gate

Status: **Corrected Asset pack Design-accepted and native conformance checkpoint green; game-owned
bind adapter frozen in `world-grade-2-bind-adapter-current.md` for implementation.**

The exploratory keyed `world-grade-2` v0.2 proof has been superseded for integration by the immutable
`AssetLab/integration/world-grade-2-v1/` pack. Design accepted the corrected pack after it added
per-species frozen Flora colors and explicit ownership for all twelve ground families. Its canonical
manifest SHA-256 is `e601d2f77a15d545fd2d893dbb2e41891518cba2900c3f6d66890d56294824c1`.

Engineering pinned and ported the request → descriptor → recolor contract at `57d8850`. The focused
9-test conformance suite and the 1,031-test product suite pass. This does **not** authorize inventing
the remaining game-fact → request adapter. Those derivations are now frozen in
`world-grade-2-bind-adapter-current.md`; Engineering must persist its immutable receipt at successful
bind rather than re-derive it during rendering.

## Frozen Asset handoff

Publish one immutable `AssetLab/integration/world-grade-2-v1/` pack containing:

- a closed request and resolved-descriptor JSON Schema;
- a manifest with its own canonical SHA-256 and `integrationReady: true`;
- frozen resolver, palette-catalogue, renderer and light-layer version identifiers;
- canonical UTF-8 descriptor serialization and a cross-language digest algorithm;
- representative request → resolved-descriptor vectors;
- exact rectangle-command, decoded-RGBA and geometry hashes for every representative vector;
- explicit fog-invariance and no-Illumination/no-raw-Vitality vectors;
- controlled identical/near/mid/far/opposed comparisons, without a universal uniqueness rule;
- an exact coverage statement for material, atmosphere and Flora scopes; and
- an explicit exclusion list for unsettled authored ink, compound color, multiple same-scope
  contributions, Creature color and current-visibility behavior.

The production pack consumes **resolved** game-owned visual facts. Named proof swatches are gamut
labels, not the player-facing CMY+Depth authorship model and not persisted `Sigil.color` values.

## Native ownership after the pack freeze

Asset owns the immutable pack and generated command registries. Engineering owns:

- `WorldVisualDescriptor` persistence and tolerant future-version rejection;
- the one-time bind adapter from legitimate resolved world facts;
- the v1/v2 renderer selection and versioned cache key;
- raster/compositor integration, disclosure and accessibility behavior; and
- save/load, anchored revisit, conformance and phone evidence.

Legacy bound and anchored worlds remain permanently on the immutable world-grade-1 renderer.
Unbound books use the accepted resolver only when they are successfully bound. No decoder, redraw,
app update, map seed, save slot, expedition count or prior-world appearance may synthesize or alter a
world palette.

## Similarity invariant

Visual distance follows meaningful resolved input distance. Exact twins may look identical; near
neighbors remain related; opposed inputs separate proportionally within comparable layers. Authored
thresholds may produce justified steps or plateaus. Runtime never novelty-optimizes and neutral/Ash
worlds receive no arbitrary differentiation.

## Integration order and current disposition

1. **Complete:** Asset froze and hashed the corrected production pack.
2. **Complete:** Engineering pinned the exact manifest and ported the pure contract.
3. **Complete for published representative vectors:** Swift matches descriptor, recolor, fog and
   geometry evidence; broader product integration remains below.
4. **Active:** freeze and implement the game-owned bind adapter without interpreting raw
   Illumination/Vitality or inventing temperature/wetness color.
5. Product tests prove v1 compatibility, v2 persistence, anchored revisit, deterministic redraw,
   cache invalidation and fog/disclosure invariance.
6. Aimee compares lossless phone color and literal-grayscale captures before promotion.
