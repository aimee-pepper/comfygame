# World-grade-2 native handoff gate

Status: **Engineering boundary review complete; waiting for an immutable Asset production pack.**

The keyed `world-grade-2` v0.2 proof is accepted calibration evidence. It is not yet a native
contract: its machine-readable report says `integrationReady: false`, its version remains
`world-grade-2-candidate-0.2.0`, and no closed schema or conformance manifest exists. Engineering
must not turn that exploratory implementation into persisted save authority by copying its current
JavaScript constants into Swift.

## Required Asset handoff

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

## Native ownership after the pack freezes

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

## Integration order

1. Asset freezes and hashes the production pack in its isolated worktree.
2. Engineering pins that exact manifest in a separate native worktree.
3. Swift matches every descriptor, command, RGBA and geometry vector.
4. Product tests prove v1 compatibility, v2 persistence, anchored revisit, deterministic redraw,
   cache invalidation and fog/disclosure invariance.
5. Aimee compares lossless phone color and literal-grayscale captures before promotion.
