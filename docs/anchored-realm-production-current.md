# Anchored-realm production — current design

**Status:** implementation-facing structural design. Rates and storage caps are reversible playtest
values. This extends `anchoring-system-current.md` and `companion-worldwork-current.md` without
adding worker specialities or offline simulation.

## Design purpose

An anchored realm should become a place the player knows and relies on, not merely a saved map that
charges essence. Posted companions maintain the binding first and bring back modest, predictable
yields from renewable sources the player actually discovered there.

Production resolves once per completed expedition. Nothing accumulates with wall-clock time, and
there is no reward for leaving the app closed or repeatedly opening the Anchorage.

## Two outputs from one posting

Each posted companion contributes the existing Worldwork amount:

`1 + Worldwork + floor((level - 1) / 5)`

At settlement, a realm spends those points in this order:

1. **Sustain:** points cancel that realm's current obligation one for one.
2. **Harvest:** surplus points fill progress toward the realm's selected renewable yield.

This makes upkeep and production one understandable allocation rather than two unrelated worker
systems. Essence pays only the remaining sustain shortfall. A realm that is costly to hold can still
be worthwhile, but it does not generate a full harvest while its workers are occupied keeping it
open.

**Placeholder rate:** four surplus production points produce one unit/sample. Fractional progress
is saved on the realm. The rate belongs in debug tuning.

## The renewable manifest

Every anchored realm stores a **renewable manifest** made only from sources the player has personally
discovered in that realm. Discovery means inspecting or harvesting the source, not merely generating
it somewhere under fog.

Eligible first-slice yields are ordinary repeatable world resources from:

- replenishing mineral/resource nodes;
- renewable flora harvests such as fibre, timber, resin and reagents;
- non-lethal or naturally shed animal yields only when the species definition explicitly supports
  them.

The manifest never includes diary pages, curios, caches, site rewards, apex trophies, unique objects,
Gold, essence, equipment, consumables or carcass-only animal parts. Posted workers do not silently
hunt, kill apexes or exhaust unique finds.

Each entry keeps its source identity, output kind, provenance qualifier, ordinary source grade and
whether the source remains available. This is saved realm data, not regenerated from the current
content catalogue after every balance patch.

## Choosing work

- The Anchorage shows the realm's discovered eligible yields and their expected interval.
- The player selects one **Current work** yield per realm. This is a destination choice, not a
  companion skill test; Worldwork remains the only worker aptitude in the first slice.
- Newly anchored realms default to **Maintain only**. They never choose or produce a resource
  without the player's knowledge.
- Changing Current work is free at base and takes effect at the next settlement. Existing partial
  progress stays with its manifest entry, so experimentation does not destroy work.
- If a source becomes unavailable, work pauses visibly and does not redirect itself.

One selected yield per realm is enough to express why the player kept that world while avoiding a
multi-row automation board.

## Output quality and inventory

Produced samples use the source's saved ordinary grade and provenance. Assignment never improves a
resource beyond what the realm can naturally yield; companion level changes quantity cadence, not
material quality. This prevents combat levelling from becoming the best crafting-quality upgrade.

Completed outputs go to a per-realm **delivery tray**, not directly into a possibly full Storehouse.
The player collects them from the Anchorage in one action. **Placeholder capacity:** six completed
units per realm. When full, progress pauses rather than discarding output. Capacity is shown before
the player departs and exposed in debug tuning.

Bulk stackable resources may occupy one tray entry per resource stack. Individually provenanced
samples remain distinct instances even when the interface groups them.

## World persistence and field replenishment

Production does not erase map nodes or duplicate unique depletion. Field replenishment and posted
production are two views of the same renewable source:

- unique and explicitly finite sources never replenish and never enter the manifest;
- ordinary renewable sources may be harvested again on revisits according to their own cadence;
- a source can support posted production while it is not presently depleted in the saved world;
- when posted production completes a unit, that source becomes field-depleted until its normal
  replenishment step completes.

This prevents collecting the same renewal simultaneously in the field and at base. The first
implementation may use one common **one completed-expedition** replenishment cadence for ordinary
eligible sources; source-specific cadences should be added only when they create an observable
choice.

## Dormancy and reassignment

- Dormant realms generate neither sustain nor harvest progress.
- When dormancy returns workers home, accumulated progress and tray contents remain safe.
- Reactivation does not instantly advance or collect production.
- Unassigning a worker preserves progress. No travel-time penalty is added.

## Feedback

The return settlement should read as a short account of places, not a spreadsheet:

> Sela kept Quiet Mere steady. 2 work remained after the binding; resin work is now 3/4.

The detailed Anchorage card may show the arithmetic, but the normal summary presents only sustain
covered, shortfall, completed deliveries and paused/full states.

## Explicit complexity boundary

Do not add offline timers, worker hunger/morale, injury rolls, route travel time, equipment wear,
per-resource worker aptitudes, probabilistic mission success, raids, defence teams or production
chains in this slice. Add a second kind of realm job only after play demonstrates that choosing a
known renewable yield is too shallow.

## Implementation order

1. Persist renewable-manifest entries, selected work, per-entry progress and delivery tray with
   empty/default migration.
2. Register one ordinary harvested node into the manifest and resolve one deterministic output.
3. Make sustain consume Worldwork before surplus harvest progress.
4. Add flora and explicitly non-lethal animal yields.
5. Link field depletion/replenishment to production and expose debug rates/capacity.
6. Add settlement prose and collection UI.
