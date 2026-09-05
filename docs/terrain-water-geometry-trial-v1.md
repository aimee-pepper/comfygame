# Terrain and local water: approved bounded 3D study

5 September 2026. **Aimee approved the separate authored study with “allowed!” Decided intended demonstration; implementation pending. Production terrain and save conversion are not approved by this decision.**

Purpose: unblock the shallow-bed/raised-pond portion of the agreed renderer trial without inventing facts in generated worlds. Engineering's reduced camera/depth proof can proceed independently. No early-game rules, phone campaign, renderer selection or Asset assignment changes here.

Authority: [accepted three-quarter direction](three-quarter-world-direction-2026-09-04.md), [physical and visibility semantics](three-quarter-world-semantics-v1.md), and [bounded renderer comparison](orthographic-3d-prototype-acceptance-v1.md). Engineering's 5 September feasibility report identifies the missing numerical water facts. Its delivery/feasibility reports are trusted; Design has not repeated native or phone verification.

## What is settled, and what exists

**Decided intended:** one support/bed per square, optional local water, independent physical height and drawing order, separate high ponds and low rivers, and disclosure-limited translucency. No stacked floors. The existing Design contract already specifies cardinal same-height access and explicit bidirectional one-level steps/slopes, no added movement surcharge, ordinary deep-water/chasm restrictions, and a shared movement/access graph before new edges activate. Those are not new approval questions.

**Current implementation facts:** saved tile elevations are integers 0–3. The documented generator relaxes cardinal neighbours to a maximum one-level difference. Standing water forms connected basins, prefers low elevations, and uses categorical deep cores; flowing channels connect a high source toward an outlet, with an uphill penalty. A penalty is not proof of strictly downhill geometry. Water/deep-water/ice categories and some saved regional liquid identity/submerged/frozen facts exist. Numerical water surface, bed and positive depth, and per-edge step/slope ownership do not yet exist in those owners. Current canEnter uses destination passability, not a height-edge graph.

Consequently neither a water tile's elevation nor its shallow category proves a measured depth. A connected categorical water patch is not sufficient evidence for one level pond surface: it may include channels, differing heights, or unavailable formation identity. Aggregate body/channel counts cannot reconstruct those missing facts. Current generation need not already admit the proposed physical representation without a separately versioned change.

## Approved next step

**Approved scope:** add one separate, labelled, authored geometry demonstration beside the existing generated-patch camera/interaction proof. Its label should say **Terrain and water study — example heights, not a generated expedition**. It is temporary isolated test state, never a campaign conversion or additional resource world. The original generated-patch proof retains actual saved positions, actions and facts; this study does not impersonate missing geometry in that patch.

The study contains a small shallow pond on raised land, a lower shallow channel, and a dry route passing their banks. Use placeholders. Numerical heights are explicit example data owned by the fixture, not renderer guesses. Aimee approved supplementing the earlier existing-generated-patch-only brief with this authored geometry study on 5 September. Both parts can proceed without another scope confirmation.

For this first study, the actor's actionable route stays on equal-height dry ground using the already implemented action rules. The raised bank and pond are viewed from beside it. Do not imply that walking a rendered ramp proves new edge rules. A later interactive slope/shore demonstration depends on the shared graph implementation already required by the accepted semantics. The study can prove local water rendering; it cannot complete the entire terrain/movement milestone.

## Minimal representation for the approved study

Names below are semantic suggestions; Engineering owns exact types and persistence placement. Keep the authored fixture format versioned and distinct from production saves. No new game-world version activates as a side effect of opening it.

| Fact | Contract |
| --- | --- |
| Support | One finite height per supported cell in abstract elevation-level units; dry ground or wet bed, never both separate walkable floors. No metres implied. Chasm has no support. |
| Liquid | Existing explicit liquid identity and shallow/deep category, plus one surface height above this cell's bed. Unknown identity stays unknown. Frozen cells are outside this liquid study. |
| Depth | Derived exactly as surface minus bed; strictly positive. Do not save a third independent number that can disagree with the other two. |
| Surface region | Explicit group of cells sharing a local level surface. This is not necessarily a whole river or an existing diagnostic body ID. No region extends through land or fills every lower cell. |
| Surface transition | Different-level water regions may meet only through a future explicitly represented transition; the first study has none. Separate the pond and low channel by land. |
| Ground edge | Canonical cardinal pair, with an explicit level/step/slope/no-passage relationship for the future physical graph. Record only authored examples for illustration until rules consume it; renderer never grants access. |
| Disclosure | Separate admission of support geometry/bed appearance, water surface and stationary/live contents. Visible water is not evidence of known bed composition or resources. |

Use exact quarter-level example values; they require no physical unit scale or universal shallow-depth threshold. Engineering's vertical scene scaling remains a display transform applied equally to support and liquid heights. Mesh thickness, wave displacement and foot-sprite pivots do not write physical state. Wave decoration must not visually spill into unrelated land.

Liquid category retains current movement authority. This study does not turn a given numerical depth into swimming, drowning, wading costs, new habitat eligibility or a resource host. A production depth-to-category policy is still Design work. Do not extrapolate this fixture's shallow depth to every Water cell or give every DeepWater cell an arbitrary deeper value.

## Concrete geometry and action examples

All heights below are authored examples, not historical world measurements.

| Example | Support/bed | Surface | Depth | Expected result |
| --- | --- | --- | --- | --- |
| Lower channel, two adjacent cells | 0 in both | 0.25 in both | 0.25 | One local shallow surface, beside bank height 1; ends at the study boundary without inventing an outlet simulation. |
| Raised pond, two adjacent cells | 2 in both | 2.25 in both | 0.25 | Separate local shallow surface, beside bank height 3. It does not cover lower ground elsewhere. |
| Dry dividing land | 1, then 2, then 3 across successive cells | absent | absent | Raised terrain remains dry even below the unrelated pond's numerical water level; a contained pond is not a world-sized flood plane. |
| Explicit illustrative step | dry support 1 to 2 | absent | absent | Meets the accepted one-level step shape. Actual traversal awaits the physical graph; no access is inferred from mesh shape. |
| Adjacent cliff | dry support 1 to 2, no connection | absent | absent | Same height difference, different legal connection. Do not put this boundary on a route still governed by legacy destination-only movement. |
| Invalid liquid | bed 2 | 2 or lower | zero/negative | Refuse this authored geometry; do not silently lift water or lower the bed. |

Both example water surfaces lie below their immediate banks. All adjoining pond perimeter banks must contain the local surface; the boundary channel may leave the displayed patch. A raised pond directly adjoining uncontained lower land would require an outlet/transition design, so it is excluded rather than drawn with a vertical free-standing water wall. Equal-level touching water with compatible identity can use one region; unlike liquids, falls, sloping river surfaces and inter-region flow are outside this study.

A production generator must eventually resolve support/bed and surface regions together, preserve quotas/identity, and validate containment/outlets before mandatory route/source checks. Do not retrofit that by flooding all cells below a chosen level, joining separate ponds from a screen-space overlap, or assuming the existing uphill-penalized channel path provides a valid water profile.

## Bed visibility and opacity

The adapter must omit unknown geometry and contents, including their effects on edges, normals, shadows and reflections. An invisible mesh is still a possible disclosure leak. No raw hidden bed height, bed material, node or actor reaches the renderer.

- **Known shallow surface and permitted bed:** show only the permitted bed geometry/material through the water. A resource needs its own disclosure permission even when the bed is known.
- **Known surface, bed not permitted:** show a neutral water treatment that reveals no measured bottom or material. Do not add a fake visible floor at the example depth. Disable bottom-dependent effects. This is not a newly learned depth category.
- **Unknown neighbour:** use the existing neutral unknown boundary. Shore/cliff shapes cannot reveal that neighbour's height, wetness or contents.
- **Remembered water:** show only the permitted remembered stationary facts, never live underwater creatures or newly changed resources. Opacity changes earn no discovery.

The first study explicitly permits the simple bed in its shallow example. That authored permission is not a new exploration/reveal rule. Asset will choose literal opacity, tint and fade after the native consumer exists; no percentage is needed from Aimee. Future deep water may obscure more, but no unapproved depth-disclosure or discovery progression follows from that visual direction.

## Exact dependencies and decisions

1. **Aimee decision closed:** the separate authored geometry study with labelled example heights is approved. Engineering may implement this bounded supplement alongside the reduced generated-patch proof. No further approval is needed for this scope; local ponds, one support per cell and agreed steps/slopes remain settled.
2. **Design/Engineering before production terrain:** choose and specify the versioned numerical bed/surface generation policy, its relationship to existing categorical elevation and shallow/deep bands, local outlet representation, and generation failure behavior. This requires a real generator packet, not guesses in the renderer. It does not require Aimee to supply numerical tables.
3. **Engineering before interactive height/shore proof:** implement the single shared cardinal-edge authority and reachable action positions across its consumers, preserving old worlds. A new fixture is not permission to enable that graph in the early playtest. Numeric shore connection details must be specified with the production packet; the trial does not invent them.
4. **Existing scope exclusions remain:** no save migration, stacked floors, flooding/flow simulation, new movement costs or abilities, opaque-water knowledge unlock, or new generator guarantees. Any later proposal adding those needs explicit scope approval.

Design delivery is this approved bounded contract plus its player-facing Wiki/Homework summary; Engineering owns implementation. No renderer research, new evaluator, native test or phone verification is part of Design's work here.
