# Generated local water and shared shore edges — operative first policy

6 September2026. **Design first-pass intended generation policy, reviewed for representability with Engineering; not delivered waterfalls.** Replaces every earlier interim exclusion/numerical proposal in this file. Mixed shallow/deep components are eligible. Aimee requests real connected higher→lower water without false shores, changed terrain, invented deepening or new swimming/fluids mechanics.

**7 September new terrain-version override:** `terrain-height-routes-and-scenery-v1.md` now defines direct Aimee's structural≤1-level routes, sparse inaccessible scenery and source/animal exclusions. For that new version, baseline pairs below are the already height-legal structural pairs; a measured-water fallback preserves structural supports and cliff refusals, not333's unrestricted dry walking. Existing333 worlds retain their frozen policy. This amendment changes no existing waterfall surface arithmetic.

## 1. Actual source evidence and version boundary

`TerrainRules.paint` uses paintCoherentElevation → paintChasms → paintWater → relaxCardinalElevation. Standing-water paint currently overwrites wet Tile.elevation with0; flowing routes retain scaffold levels. The field is categorical cover/sightline/routing data, not a measured wet bed. Capture the wet routing scaffold immediately before water paint, but compute banks from FINAL accepted dry terrain after relaxation and mandatory terrain edits. Do not use captured old dry levels as final banks. All new bed/surface values below are deliberately generated versioned facts, never invented measurements of old worlds.

Engineering’s WorldWaterTopology foundation preserves standing-body IDs/cells, channel IDs/source/ordered route/route endpoint/membership, final wet-cell membership and explicit single-cell outflow evidence. General `routed.last` is an endpoint, not a receiver; Boolean channel adjacency does not identify one. The new model must own explicit receiver/edge decisions. Missing policy keeps current saves/movement/water presentation. Existing332 opening and source stock are unchanged.

## 2. Canonical geometry and edge facts

Use integer **quarter-level units** for stored geometry. One ordinary terrain elevation level equals4 quarters. Dry support=4×FINAL Tile.elevation and is immutable under this policy. Wet support/bed and local water surface are new facts; depth is surface−bed, not a third saved degree of freedom. Preserve original shallow/deep category, liquid identity, frozen state and source/world IDs. Do not derive or change a ground category from new numerical depth.

Persist local surface regions with member cells and one level, each wet cell’s bed, directed source/receiver region IDs, exact cardinal shared inlet/outlet edge, lip endpoints, direction, exposed drop and receiver landing cell. An edge has independent fields for liquid connection and ordinary crossing classification; a flowing fall is not automatically a walking prohibition. Root/source action positions continue to refer to existing cells.

A standing body supplies one local surface region. Split an ordered flowing route into reaches at scaffold-level changes; attach its off-route water cells to the nearest reach through its own actual membership, route-order then row-major ties. Shared cells have one canonical owner. Adjacent equal-level water may merge only with actual shared topology and compatible liquid; never merge disconnected pools or manufacture a deep-only island inside a shallow component.

Choose an endpoint’s receiver only from actual cardinal adjacent compatible unfrozen water bodies/reaches in the raw generation topology, excluding its predecessor/self and cycle-producing choices. Priority: existing standing body, then another channel, canonical ID then cell order. Freeze the chosen receiver and edge. A boundary outflow may leave the world without a receiving pool, but cannot display an in-world waterfall landing. Directed route/junction graph must be acyclic after legitimate equal-surface merging; unresolved cycles or lost final membership are unsupported, not rerolled.

## 3. One surface/bed policy

For region R, in stable topological order:

- Desired surface D =4×minimum captured pre-water scaffold elevation over its members +3 quarters.
- Closed-bank ceiling C = minimum FINAL adjacent dry support −1 quarter, excluding actual persisted inlet/outlet edges. No dry bank means no ceiling term. A chasm/open edge must have an explicit outflow or the candidate is not contained.
- Surface H = min(D, C when present, every incoming source H when present). The receiving region has one shared H for all incoming sources. This preserves local containment and never invents uphill flow.
- Shallow bed B=H−2 quarters; deep bed B=H−5 quarters. These are generated first-pass depths, not changed ground categories or artificial deepening to satisfy a waterfall. Never deepen/reclassify a shallow cell, flatten a bank or widen a water footprint to make an invalid candidate pass.
- Positive directed surface drop Δ=Hsource−Hreceiver across an open exposed lip forms a waterfall. Equal surfaces form an ordinary level connection; missing/blocked/uphill edges form no fall. Width starts at0.35 tile, centered on the actual shared edge, and the curtain lands at the receiver surface. There is no chance roll once the accepted physical conditions exist.

The upstream perimeter must be contained except at actual open connections. The lip occupies the open side of the bank/drop face; no water route tunnels through solid support. Water surface cannot become a free-standing wall against an unrelated low dry tile. Regional levels remain independent unless an actual connection constrains them. Wave/spray drawing stays within admitted geometry and changes no volume or gameplay.

## 4. Exact shared crossing admission — replaces the empty filter

Start with the current baseline cardinal passable pairs: both cells satisfy the existing `WorldRules.canEnter` and are neighbors. The candidate geometry must preserve **every such pair touching its connected liquid component**, not merely one route through it. This is an admission test, not permission to add a cliff restriction afterward.

For each affected pair, let δ=abs(supportA−supportB) in integer quarters, using final dry support and candidate wet bed:

| δ | Shared edge classification | Ordinary movement/action consequence |
| --- | --- | --- |
|0|level|Existing crossing and existing movementCost |
|1–3|slope|Existing crossing, connected ramp/shore shape, same cost |
|4|step|Existing bidirectional one-level step, same cost |
|>4|unrepresentable for this candidate|Reject measured geometry for the entire actual liquid component; preserve original passability/cost/world |

Both endpoints must remain ordinarily enterable. Deep water/chasm/blocked-source cells keep their existing refusal; a numerical small delta never creates a crossing. Dry-only pairs outside the component remain under existing rules. Direct movement/refusal, path search, generation/source reachability and the renderer consume the same read-only accepted edge classification. Do not ship geometry with a private renderer-only cliff rule. Existing tool/collection target admission remains its owner; revalidate all required action positions and source/entry connectivity against the unchanged accepted pairs before freezing.

A waterfall and a short traversable water step can coexist: flow crosses its open lip while the existing party route uses the actual bed/support step. This adds no swimming, drowning, fall damage, pushing or movement surcharge. A taller drop can be admitted where no existing passable pair crosses it, for example at an actual deep-water boundary. No artificial deep-water restriction is needed for all falls, and ordinary shallow margins do not disqualify the whole component merely by existing.

Admit/refuse a whole connected liquid component atomically. Do not leave a measured upstream node feeding an unmeasured receiver inside that same component. On rejection keep its current categorical representation and original rules; no new source, seed, quota, world, changed depth class or charged retry is created. Other genuinely separate components may be admitted independently. This fallback is an explicit unsupported geometry case, not a completed waterfall. A requested explicit water-source promise still follows its existing quote/refusal owner; this policy adds no waterfall Writing rune/guarantee.

Current sight/disclosure rules remain authoritative. Tile.elevation keeps its categorical sightline meaning; measured bed is not substituted into cover/vision rules. The renderer receives permitted physical support/surface/edge facts separately, as already required for local water. Actor footing uses its admitted support while turn, visibility and interaction results stay rules-owned. Unknown bed appearance stays unknown even when a movement edge is legal.

## 5. Ordinary viable witness and counterexamples

**Representative ordinary-topology witness, not an observed-world prevalence claim:** an actual directed channel descends from a reach surrounded by final level2 banks to a level1 reach with shallow margins, eventually joining a real standing body. Its route/reaches/cells/receiver come from the ordinary generator, not two disconnected study pools. Captured wet scaffold is2 then1.

Upper region: D11, final bank8 gives H7; shallow bed5/deep bed2. Lower region: D7, final bank4 gives H3; shallow bed1/deep bed−2. Upper dry→shallow shore δ3, lower dry→shallow shore δ3; an existing shallow→shallow channel crossing δ4 is a valid step. The actual directed water edge has Δ4 and therefore a one-level waterfall. Surrounding dry level2→level1 edges retain their existing connection. Mixed-depth margins, cell categories and dry elevations are unchanged. A source or receiver already deep remains non-walkable as before; no artificial deepening is necessary. This is a feasible ordinary generation shape and a direct rules fixture; Engineering must separately report any actual generated/native witness it encounters.

**Exact invalid cases:**

- Change one adjacent FINAL bank from level2 tolevel3 while the same upper shallow support is5: δ=12−5=7. Reject this candidate component’s measured geometry; do not block its old crossing or paint a false climbable cliff.
- Final terrain relaxation lowers a bank: recompute H/edge checks from that final bank, never retain a stale prepaint ceiling. Missing raw scaffold in an older save is unsupported, not a reconstructed measurement.
- Same pool heights separated by a dry ridge, unselected receiver behind a Boolean join flag, invalid final route membership, unlike/frozen liquids, blocked lip, self/cyclic edge, or out-of-world landing: no valid waterfall.
- Two sources of different H share one receiver at the minimum admissible incoming/bank level; preserve each real Δ. No duplicate overlapping receiver surfaces.
- Equal H means no fall. Geometry that preserves one portal route but destroys another previously passable shore pair still fails the exact pair test.

## 6. Disclosure and readiness boundary

An animated visible fall requires both permitted endpoint surfaces and the intervening permitted edge/drop. Unknown neighbors retain the neutral unknown boundary; reflections, normals, spray and sound may not disclose a hidden receiver. Remembered water uses the last-observed stationary recipe, not hidden live updates; no new audio is required. Rendering consumes no hydrology/world RNG and simulates no erosion, flooding, fluid transfer or new habitat/party ability.

Engineering confirmed integer-quarter pair-preservation and atomic component admission are representable. Implementation dependencies are explicit scaffold/final-bank capture, canonical region/receiver/DAG finalization, numerical facts, shared read-only edge classification across direct/path/generation consumers, atomic persistence and sanitized render projection. Raw topology alone is not a waterfall delivery. Existing focused tests can cover the witness and invalid cases; ordinary native evidence uses the existing Settings3D consumer with no seed-search corpus, new menu or Design repeat. Final literal motion/opacity follows the exact implemented consumer. Later shops and Essence recovery remain excluded.

## 8 September bounded presentation amendment

waterfall-receiver-face-contact-v1-2026-09-08.md authorizes the falling sheet on its own matched shore-step receiver face, with exact surface heights/width and normal occlusion preserved. Current .03step/.025sheet needs .030tile downstream center offset for .0025clearance, plus narrow static source-height lip contact. No logical source/receiver, elevation, crossing, disclosure or saved-world change. This is pending presentation correction, not current readability acceptance.
