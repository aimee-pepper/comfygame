# Three-quarter world: minimum physical and visibility contract

**4 September 2026 · Decided intended behavior. No new renderer or gameplay delivery claimed.**

Authority: [Aimee's accepted direction](three-quarter-world-direction-2026-09-04.md), the accepted region,
finite-producer and canopy rules, and current AGENTS. This packet closes the narrow shared semantics for
Engineering's later native proof. The active material/Return/Nessa route continues; no replacement world
catalogue, final asset sheet or camera experiment is a prerequisite for its delivery.

**5 September clarification:** the numerical water examples below are illustrative, not facts present in current saves. See [the bounded terrain/water trial proposal](terrain-water-geometry-trial-v1.md) for the missing geometry owner, an optional authored study requiring approval, and the unchanged movement implementation dependency.

## 1. Physical truth before drawing order

Keep the square grid and four-way movement. A map position has at most one supporting ground/bed surface,
its saved elevation, and optional local liquid above that bed. A chasm has no traversable support. There
is no second bridge floor, walkable underpass, 3D collision world or off-grid diagonal movement in this slice.

The new physical context needs these distinguishable facts; Engineering may map names to its current model:

| Fact | Minimum meaning |
|---|---|
| Support/bed height | Saved physical elevation; not sprite height or an art offset |
| Local liquid | Identity, bed association, positive depth, surface height, and the existing shallow/deep eligibility band |
| Surface connection | Canonical cardinal edge between support positions; ordinary level connection, explicit step/slope, or no ground passage |
| Object base | Stable owning cell/ground-contact footprint and support height; separate from upper-sprite/canopy bounds |
| Harvest approach | Reachable adjacent action positions with legal height access to the named base or exposed mineral face |
| Semantic visibility | Current full/fringe/hidden state, permitted remembered terrain/markers, and rules-owned canopy concealment |
| Display overlap | Which already-authorized sprite/face pixels obscure the character; presentation-only and not save authority |

A low river and a high pond can have different surfaces. For example, a shallow low river might have bed
height 0/surface 0.5, while a shallow pond on raised land has bed 2/surface 2.5 with a surrounding bank at 3.
These are illustrative normalized height values, not pixel dimensions or new shallow-depth thresholds.
The local surface must remain above its bed and be consistent with the existing shallow/deep band.
Pond surfaces are local; a river may use connected local segments. No global sea-level plane, fluid
simulation, waterfall, erosion, flooding, evaporation tick or new water-writing guarantee follows from this.

Render the applicable disclosed local bed, shallow liquid, surface treatment, shoreline and above-water
objects in physical order. A high land surface is not covered merely because some unrelated lower tile
contains Water. Deeper liquid may obscure more bed art. A visible water surface does not automatically
identify hidden bedrock/resources; only bed facts permitted by the visibility/disclosure projection may
enter its image. Liquid identity is not inferred from colour or opacity. Existing root-water/chemistry and
resource-host rules continue to read resolved facts, including exclusion of Mercury from ordinary roots.

## 2. Movement and action access

**Concrete current gap:** inspected source `d175ee81` still checks `canEnter(point)` using destination
passability; it is not an elevation-edge traversal rule. An artistically convincing cliff must not become
a place the player can walk through while the route planner claims it is blocked, or vice versa.

For the new physical-edge version:

1. Same-height cardinal neighbours allow ordinary surface access, subject to ground, occupancy, crumble
   and other existing action rules.
2. Different-height neighbours require a saved explicit legal step or slope. The first slice permits one
   elevation level per such connection. A larger climb needs a sequence of supported cells/connections;
   a bare cliff is not traversable. No automatic falling, jumping, climb skill or damage rule is introduced.
3. The connection is bidirectional for this initial slice. Destination-ground movement cost remains the
   existing cost; a step/slope adds no separate time or stamina tax. Deep liquid and chasm remain impassable
   to ordinary party movement. Shallow water is still traversable where its legal shore/bed access permits.
4. Manual movement, route planning, automatic movement, source placement, guaranteed-source validation,
   entry/portal/teaching/traveller reachability and ordinary terrestrial creature movement must read the
   same ground-edge eligibility. Preserve existing separate aquatic/aerial owners; this does not grant a
   new flying/cliff-crossing capability or force their movement through the party's ground graph.
5. An interaction's target may itself block movement, as a trunk or mineral node does. Check reachable
   operator position, physical height access, exact target and existing tool rules separately from entering
   the target cell. Equal-height adjacency is an ordinary legal approach. A cliff-separated base is not
   reachable merely because its upper art overlaps the operator. Any mineable cliff face needs an explicit
   saved approach/face relationship at the operator's working height; do not infer one from cliff pixels.

The early source reservations are counts of *reachable action sites*, not merely passable-looking tiles.
When the new physical-edge version is enabled, run those reservations and mandatory-route checks after
edge resolution. Do not randomly add blocking elevation boundaries to the active early route before
its consumers share that graph. Until then, keep its existing generation version and movement semantics.
A temporary renderer may depict those existing saved facts without claiming new cliff traversal physics.
Old and anchored worlds retain their generation/movement version; no decode-time re-roll, invented water
body, relocated source, newly blocked return path or reinterpretation of their historical elevation.

## 3. Trees: target the base, preserve the saved work

A tall sprite's extent can cross cells. Blocking, occupancy, felling and targeting belong to the ground
footprint. The first small-tree profile retains its current single trunk cell and five-cell crown; larger
art does not enlarge the blocking footprint or change its harvest tier/yield.

With the correct packed Axe selected at an eligible adjacent approach, identify the disclosed trunk base
with a small valid-target highlight, show **Chop tree**, and place the impact at that base. The existing
adjacent-direction action owns the hit. Wrong tool/tier, an inaccessible base, stale target, failed custody
or cancellation costs zero turns. Encounters and higher-priority existing interactions still win.
The successful hit costs one world turn; partial work persists; the final hit removes only that tree's
own crown, and overlapping standing crowns remain. Foliage membership is never a harvest command.
A hidden base receives no revealing highlight merely because a crown or tall sprite overlaps a known tile.

## 4. Visibility is not transparency

Use the existing rules-owned visibility result before deciding which geometry may be rendered. Foreground
art covering the character may fade only over otherwise permissible content. Restore opacity when the
character emerges. Keep a faint silhouette and the already-disclosed blocking base. On a plateau, only
the obstructing foreground cliff face fades; its whole top surface does not disappear.

Preserve the accepted canopy rule: a sight line crosses one crown tile; a second consecutive crown tile
conceals beyond. Under a canopy, the party's own tile and eight neighbours receive the local canopy
exception. That exception removes *canopy* concealment only; it does not abolish normal range, other terrain/
elevation occlusion, fog, or undisclosed entity rules. The current rules already treat intervening higher
terrain as sight-blocking. No extra sight range or new high-ground vision bonus is added here.

A fade frame must not call reveal, add a minimap marker, turn remembered terrain into live entity vision,
expose a resource/creature/site beyond the semantic mask, or provide a hidden neighbour's height/material
through a shoreline, cliff face or shadow. The same mask applies to base, upper sprite, canopy, water and
foreground passes. A silhouette is only of the obstructing object already allowed to be shown, never a
new outline of a concealed entity behind it. Earned minimap records remain earned; transient live entities
still follow their current disclosure rules. Camera overlap, redraw, fade timing and opacity spend no turn
and do not change a frozen world receipt. Moving, chopping and other real actions continue to own rules.

## 5. Reconciliation with inherited terrain packets

The shared `terrain-layering-and-motion-asset-packet-current.md` is an older copy forbidding all side faces.
The later retained 22-August production record permits only compact south-height walls, with a fixed
16×19 profile and 16×16 hit plane. Neither is a complete contract for the newly accepted direction.

| Earlier constraint | Disposition for the new three-quarter proof |
|---|---|
| Strict straight-down/no front faces; only the old south-wall exception | Superseded by Aimee's accepted three-quarter view with real ground-contact height |
| Global water below rock/dirt/grass compositing | Superseded as a scene-wide rule; resolve local bed/surface and height boundaries |
| Every object image fits the tile's ownership rectangle | Superseded for sprite artwork bounds; logical cell and footprint ownership remain |
| Fixed old source/display dimensions, pivot and south-only face profile | Historical consumer contract; Engineering names the successor's measured geometry before Asset exports |
| Equal-height material changes do not invent elevation/cliffs | Retained |
| Hidden neighbours cannot influence visible edge/shadow information | Retained |
| Current square-grid movement, saved truth, palette/colour ownership and rules-owned turns | Retained; new edge physics is a separately versioned bounded change |
| Old 368×800/alternate-configuration and Reduce Motion requirements | Invalid under current AGENTS; closed historical evidence, not a new work or acceptance requirement |

Do not queue or revive those invalid historical directions. Keep existing functioning terrain assets and
legacy rendering as appropriate until the named replacement is proven; this packet neither approves nor
rejects old visual evidence anew. Updating the Wiki's intended behavior does not promote new native work.

## 6. Narrow behavioral proof and readiness

At Engineering's next safe source boundary, use temporary test state and its own single Simulator only if
needed. Native visual acceptance remains the actual target iPhone/default text with device and native
viewport recorded. Do not change Aimee's campaign or test excluded configurations.

The proof needs just: one tree to walk behind and chop; a shallow local bed; a raised pond beside lower
terrain; a legal step/slope and an adjacent cliff without a connection; foreground character overlap; and
a still-concealed object beyond canopy. Check that routes and manual steps agree, the Axe works at the base,
partial work survives reload, local water does not paint over high land, and face/canopy fade changes no
knowledge, collision, target, turn, tool, reward or saved population. Use a fully revealed comparison only
as a controlled semantic fixture, not to expose a preserved campaign. No full world catalogue is required.

**Ready:** physical/support/liquid separation, ground-edge and harvest-approach rules, visibility/fade
invariants, exact inherited conflicts and bounded behavioral cases. **Engineering supplies:** exact final
native consumer, saved/runtime fields, events, rendering interfaces and measured tile/source/display sizes.
**Asset then supplies:** source pieces actually needed by that consumer, pivots, layer extents, opacity,
fade duration/easing, edges/corners and existing palette/material tint application. The current task makes
no speculative export brief or final art assignment. Remaining overhaul source/consumer packets remain
ready independently; only enabling new physical edges requires the corresponding shared graph checks.
