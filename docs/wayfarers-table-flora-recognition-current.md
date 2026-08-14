# Wayfarer's Table — Flora Recognition

**Status:** implementation-ready completion of Sela's settled station contribution  
**Date:** 11 August 2026  
**Owner:** Game Design; Engineering owns rules/UI/save fixtures

## Why this exists

Sela's accepted contribution is routes, provisions, organic yield, carrying support and **flora
identified on sight**. The native Wayfarer's Table currently implements only the satchel and organic
yield bonuses. Adjacent Look meanwhile reads generated defence details directly, giving every party
the missing benefit without an owned knowledge boundary.

The Table is a shared field workspace, not a shop counter and not a reason Sela must remain Home.
Building it makes her field guide and route notes available to every later expedition.

## First slice

### Before the Table is built

Look reports only what the player needs to decide whether to enter:

- a visible descriptive label such as growth, thorn growth or coiled growth, plus its silhouette at
  the map's current disclosure level; the exact generated species name remains unidentified;
- total and extra entry turns;
- physical: entering will hurt the party;
- chemical: entering carries a lingering hazard;
- active: entering will start an encounter.

It does not name exact defence type where that would add hidden biological interpretation, expected
yield, tissue allocation, metabolism, severity, damage, status duration or quality.

### After the Table is built

Look adds one compact **Sela's field note** line for visible flora:

- exact generated flora name;
- defence family: unguarded, barbed, chemical or active;
- the ordinary world-resource kind this species would yield: Fibre, Timber, Pulp, Toxin or Reagent.

Example:

> Hookrush · entering will hurt the party  
> Sela's field note · barbed · yields Fibre

Do not show numeric defence/tissue percentages, exact damage/status duration, harvest quantity,
sample grade or hidden metabolism. “Identified” means practical field recognition, not full Tier-5
analysis.

## Ownership and persistence

- Entitlement derives from the durable unlocked `wayfarers_table` station. Do not add a second
  Boolean or require Sela in the active party.
- The flora identity and yield derive from the exact visible `Flora` instance through
  `FloraRules.yield`; do not maintain a prose lookup table.
- The Table does not mark remote/fogged flora discovered and creates no minimap POI.
- Legacy saves with the Table unlocked receive the field guide automatically. Saves without it do
  not gain fabricated per-species knowledge.
- Building the Table mid-campaign affects future and currently visible Look results immediately; it
  does not rewrite historical world records.

## Interaction with other systems

- Existing +2 satchel capacity and +1 organic node yield remain separate station benefits.
- Look remains zero-turn and never wakes, triggers or harvests flora.
- Active-flora entry still starts combat; identification grants no initiative or protection.
- Future deeper flora records may remember encountered species, but must consume this same derived
  identity rather than replacing the Table with a second catalogue.
- Scent Mask remains animal-only and gains no flora interaction from recognition.

## Acceptance

1. The same visible physical/chemical/active flora yields disclosure-neutral entry copy before the
   Table and exact name/defence family/yield kind after it.
2. Hidden flora produces no note before or after construction.
3. Table state, not Party membership or roster position, owns the benefit across save/relaunch.
4. The displayed yield matches `FloraRules.yield` for every current flora tissue/defence branch.
5. Looking mutates no run, discovery, awareness, inventory, Stability or RNG state.
6. No inspection string contains numeric generated traits, exact harm magnitude, harvest amount or
   sample grade.
7. Phone and VoiceOver present the consequence before the optional field-note detail without adding
   a permanent explanatory card.
