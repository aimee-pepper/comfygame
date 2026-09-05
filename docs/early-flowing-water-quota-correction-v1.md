# Flowing-water quotas must fit physical channels

**Decided intended correction · 4 September 2026.** Authority: Engineering diagnosis `505e55fbd404e12c25f098b41f5db5c873215b7c`, tree `7aa6c6f067c8a78e43ecf357b5208284f7ae8b55`, and PM's bounded blocker request. Original legacy pressure generates seed 264. Adopted pressure fails before material allocation under both terrain paths: standing/flowing/frozen quotas are 0/4/102, but the flowing allocation splits as 2/1/1 while its ordinary path requires distinct cells. Frozen placement is not the cause. No runtime terrain correction is claimed here.

## Partition without changing water

For the corrected new-world policy, retain the resolved total surface-water budget and exact standing, flowing and frozen quotas. Dispersion is a desired channel count subject to physically feasible minimum sizes, not a command to create impossible one-cell ordinary paths.

Let Q be the nonnegative flowing-cell quota and D the existing dispersion-derived desired count (currently at most four). For Q >= 2, use `min(D, floor(Q / 2))` channels, with a minimum of one, then divide Q with the existing stable largest-remainder rule. Every ordinary channel receives at least two cells. Keep the existing non-uphill source-to-outlet path, connected growth to fill its allocation, occupied-site protections and exact final quota checks. No terrain grading, pressure reroll, transfer between water forms, bonus water or silent loss is allowed.

Examples at high dispersion: Q=2 gives [2]; Q=3 gives [3]; Q=4 gives [2,2]; Q=5 gives [3,2]; Q=6 with desired three gives [2,2,2]. Q=0 yields no flowing channel. This changes feasible subdivision only; it does not retune the world's dispersion value or ecology. Where an ordinary route still cannot be placed, retain an explicit generation refusal rather than declaring the quota fulfilled.

## Exactly one flowing cell: a short outflow with an actual outlet

For Q=1, place **one shallow flowing cell draining directly to an existing outlet**, rather than invoking the two-cell ordinary path. Its source is within that cell; its outlet is a distinct physical boundary, not a second invented water cell. Legal outlet choices are:

- A cardinal edge of that cell at the map boundary, using the same open-boundary outflow assumption as existing channels; or
- A cardinal edge into an already-placed standing-water cell whose current modeled elevation is no higher than the source cell. That receiving cell stays in its existing standing quota and is not counted again as flowing water.

The flowing cell must be an eligible unoccupied source position and must not consume protected content. Use stable candidate/edge ordering and the selected world's deterministic generation stream. Prefer the existing source-ranking conventions where applicable. A cell merely surrounded by dry interior ground is **not** a valid isolated flowing puddle; adjacency to frozen water is not a liquid outlet. No new spring resource, water source class, flow tick, cliff waterfall, neighbor repaint or water-form conversion follows from this short segment.

Record an explicit single-cell-outflow witness: its one owned tile plus the selected boundary edge or existing receiver cell. Engineering may map this onto current diagnostic/receipt types. Do not fabricate a two-cell route by duplicating the source or imply two distinct tile endpoints. The physical distinction is source-to-outlet-edge, while its grid footprint and flowing budget remain exactly one. If no legal outlet exists, report a specific one-cell-flowing-outlet refusal and preserve the failed quota; do not discard the cell, turn it into standing/frozen water or relax the exact quota test. Rendering/disclosure continue to use existing rules and may not reveal an unseen receiver through a new marker or effect.

## Compatibility and bounded acceptance

Engineering owns the smallest saved generation-policy version needed. Existing worlds/books without it retain their original channel partition and source/outlet semantics; frozen terrain and work receipts are not regenerated. New early Binds, previews and causal counterfactuals consistently use their selected policy. Leave source/intensity rolls, root-water composition, thermal phase conversion, material hosts, budgets and action/save rules unchanged. No scene/renderer or art work is needed.

Prove the correction with actual seed 264 under adopted pressure (exact 0/4/102 quotas, two two-cell flowing allocations, successful generation through material placement), the existing flat fixture, and small Q=0/1/2/3/4/5 partition cases. For Q=1 cover a valid boundary outlet, an equal/lower standing receiver without double counting, and an enclosed/no-valid-outlet refusal; reject an uphill receiver. Verify unchanged original-policy reproduction and deterministic corrected saved-book regeneration. Keep final quota and protected-route checks. No full 1,000-world rerun, extra Sun cohort or parameter sweep is requested.

The diagnosis is now closed into implementable semantics. Written early-resource guarantees/credits remain separate implementation work; natural Nessa pacing, visual acceptance and phone cutover remain outstanding. No new Aimee decision is required for this bounded correction.
