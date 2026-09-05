# Three-quarter world presentation — accepted direction

Aimee accepted this direction in the PM conversation on 4 September 2026 and explicitly requested coordination with the other leads. This is decided intended behavior, not implemented artwork, a delivered renderer, or a reason to stop the active overhaul.

## Physical world and presentation

Use three-quarter top-down presentation over the existing square-grid gameplay. Ground remains readable from above while fronts of trees, rocks, characters and cliffs convey height. Preserve existing movement, targeting and material/progression work unless an explicitly scoped implementation requires a design change.

Physical elevation and drawing order are separate. Water belongs to a local bed and surface elevation: a low river and a pond on a plateau can coexist. Water is not one global layer painted over every land surface. Draw applicable local bed, translucent shallow water, water surface treatment, shoreline and above-water objects in coherent order. Deeper water may obscure more of its bed; exact opacity/art tokens remain Asset work after native consumer definition.

Initial model: one walkable ground surface/elevation per map position, with optional water, and explicit legal slope/step connections between heights. Cliffs express neighbouring height boundaries. Bridges with separate walkable space underneath and other stacked floors are outside the initial scope; do not infer them from the art references. Resolve elevation from saved world facts, not sprite appearance.

## Objects, targeting and concealment

A tall sprite can overlap several cells while its ground-contact footprint owns blocking/interaction. A tree’s trunk base is its Axe target. Use a visible base, a small valid-target base highlight, the action label “Chop tree”, and an impact at the trunk. Retain the existing selected-Axe/adjacent-direction interaction and rules-owned work/depletion; do not grant harvesting merely from foliage membership.

Foreground tree/bush/object artwork overlapping the character becomes partly transparent, restoring opacity when the character emerges. Preserve a faint silhouette and understandable blocking base. Fade only the obstructing foreground cliff face, not an entire plateau. Exact fade duration, opacity and extent require Asset’s consumer-backed prescription.

Transparency exposes the character and already-visible surroundings only. It never grants exploration knowledge, reveals fogged terrain, bypasses gameplay canopy concealment, or erases earned minimap knowledge. Sprite overlap and rules-owned visibility are separate inputs; rendering must respect both.

## First native proof and asset boundary

Prove one bounded native scene on the actual iPhone/default text: a tree to walk behind and chop, shallow water over a visible bed, a raised pond beside lower terrain, and relevant character/object overlap. Use temporary test state; preserve Aimee’s campaign. This proof defines geometry, layering, ground-contact footprint, targeting and concealment before final terrain production.

Engineering must name the exact final native consumer, saved/runtime state and event protocol, tile/source/display dimensions and layering interfaces before Asset production assignments. Asset then prescribes required base/upper/canopy/shadow/water pieces, reusable edge/corner transitions and tint channels. Do not assume every object needs every layer or ask Aimee to paint a combinatorial sheet upfront. Use existing accepted palette/material-colour direction. No new celestial cycles, full 3D engine or unrelated mechanics inferred.

## Execution priority

Keep Engineering’s active early material/region/producer/custody/Nessa route moving toward a playable delivery. First identify the narrow compatibility requirements so a temporary renderer does not force a rewrite of saved world facts. Implement the native visual proof as a separately bounded checkpoint at a safe source boundary; do not replace the current overhaul with a sweeping renderer rewrite or block it waiting for final art.

Game Design owns physical/elevation/visibility consistency and public Wiki decided-intended synchronization. Asset owns consumer-backed composition and authoring requirements, not speculative final exports. PM coordinates concrete dependencies and deliveries. References and tests do not establish final phone visual acceptance.
