# Expedition experience recap — current

Status: implemented correctness and observability boundary, 10 August 2026.

## Current rule

- Every active party member receives the full expedition award. Experience is not divided by
  party size.
- Combat experience is the sum of defeated-foe awards, scaled by foe level against the party
  reference level.
- First discoveries add fixed per-member awards: species 14, site 20, writing 25 and traveller 120.
- The expedition recap compares each character's real persisted experience with their departure
  snapshot. It does not cap or replace the total with a placeholder.

## Correctness fix

A tolerant old or anchored world can contain a diary-page tile whose page is already known in
Reality. The tile is cleared when reached, but it no longer pays another 25 experience unless
`readPage` actually records a new page. Other discovery paths retain their existing first-only
guards.

## Source attribution

`WorldRun.experienceBreakdown` records equal per-member awards from combat, new species, new sites,
new writing and new travellers. The breakdown is tolerant on old saves, resets for a new anchored
visit, and freezes into `RunExitSummary`. The recap displays those sources once above the individual
party totals so repeated round totals such as `+100 XP` can be understood and audited.

This ledger is explanatory; it does not change XP balance or split awards among the party.
