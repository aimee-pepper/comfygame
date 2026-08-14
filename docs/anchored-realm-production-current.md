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

### Stable identity boundary

The live `assignedCompanions: [Int]` and map-tile-only node representation are not safe persistence
contracts for this system. Roster positions can change, and an exhausted node currently becomes an
empty tile. Production must not build durable work on either value.

- Assignments save a stable `PersistentPartyMemberID`, never a roster index. The shared identity
  vocabulary must distinguish named travellers, generated people and tamed animals; eligibility may
  initially admit only named/generated people, but the saved reference cannot make that assumption.
- Each eligible source receives a stable realm-local `RenewableSourceID` when the manifest entry is
  first registered. Its tile coordinate is location metadata, not its identity.
- Exhaustion changes saved source state to depleted; it does not delete the source receipt by
  rewriting the tile to semantically empty. Rendering may look empty, but inspection, replenishment
  and production still resolve the saved source.
- Legacy roster-index assignments migrate only when the saved roster position still resolves to one
  unambiguous persistent identity. Invalid or ambiguous assignments return the worker safely to base
  and emit a migration diagnostic; never guess.

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

### Deliberately narrow first implementation

The first end-to-end slice registers only ordinary generated `ResourceNode` sources whose output is
already represented by `ResourcePool`. It produces the same bulk `ResourceID` and saved ordinary
yield basis; it does **not** invent an individual material-sample object or reconstruct properties
that the live node never stored. Flora and property-bearing samples wait for their existing exact
instance/provenance receipts to be available. This keeps “one node produces one known resource”
honest while proving the sustain/progress/tray loop.

First-slice manifest entry fields are therefore:

- stable `RenewableSourceID` and realm ID;
- source tile/location and saved source kind;
- exact output `ResourceID`, saved yield basis and renewable/finite classification;
- current availability/depletion state and next eligible expedition outcome;
- saved production progress and last settlement receipt that touched it.

Do not derive output or renewability later from a possibly changed catalogue definition.

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

Production and field harvesting atomically reserve the same saved source. If field harvesting has
depleted it, posted work pauses until replenishment. If posted work completes its output, it marks
the source field-depleted before placing the output in the tray. There is no frame in which both
routes can claim the same renewal.

## Settlement receipt and save safety

Every completed expedition mints one stable `ExpeditionOutcomeID`. Anchored production saves the
last processed outcome ID (and, where useful for diagnostics, a monotonic outcome sequence). The
entire settlement is one atomic persisted transition:

1. verify this outcome has not already been processed;
2. replenish sources whose saved cadence is due;
3. resolve worker identity and total Worldwork;
4. cover sustain, then advance exactly the selected source;
5. reserve/deplete the source for every completed output and place it in the delivery tray;
6. save realm progress, tray, worker assignments, Essence payment/dormancy decision and the outcome
   receipt together.

Reopening a return summary, force-quitting during it or replaying a dismissed UI action cannot tick
production twice. A settlement that cannot commit leaves the prior state intact. RNG is unnecessary
in the first deterministic slice; any later random event must use a dedicated stream derived from
realm ID plus outcome ID rather than consuming world/combat RNG.

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

1. Introduce stable persistent worker/source/outcome identities and preserve depleted node receipts;
   migrate legacy roster-index assignments conservatively.
2. Persist renewable-manifest entries, selected work, per-entry progress, delivery tray and last
   processed outcome with empty/default migration.
3. Register one discovered ordinary bulk `ResourceNode`; resolve one deterministic, idempotent
   output through the shared source reservation.
4. Make sustain consume Worldwork before surplus harvest progress and commit payment/dormancy in the
   same settlement transition.
5. Add collection UI, settlement prose and debug rate/capacity/receipt diagnostics.
6. Add flora and explicitly non-lethal animal yields only after their exact source/sample receipts
   exist.

## Live-code audit notes — 9 Aug 2026

- `AnchoredRealm.assignedCompanions: [Int]` is a migration source only, not the target schema.
- `ResourceNode` presently stores resource/count/yield but no source ID or renewable classification.
- `WorldRules.harvest` presently replaces an exhausted node with `.empty`; this must change before
  field replenishment or production can be correct.
- Live anchoring currently recalculates upkeep contribution but has no manifest, progress, tray or
  processed-outcome receipt. These are implementation gaps, not evidence that production occurs.
