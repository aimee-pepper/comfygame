# Feature Completion Priority Audit — Current

**Status:** Current scheduling authority beneath Aimee's numbered priority sequence  
**Date:** 11 August 2026  
**Principle:** Finish and validate systems already present in ordinary play before adding major new
systems, late-game buildings or simulation breadth.

## What “fully implemented” means

A feature is not complete merely because its model or first rules slice exists. Before the queue
moves past it, the relevant scope must have:

1. one authoritative rules path rather than parallel legacy behavior;
2. tolerant persistence and idempotent receipts where state can be replayed;
3. player-facing access, truthful preview/result and no dead room/button;
4. focused and cross-system fixtures covering the real failure boundary;
5. a signed phone build containing the exact checkpoint; and
6. Aimee's named acceptance pass, or an explicit decision to defer tuning after the behavior is
   proven correct.

`readyToTest` is therefore **unfinished acceptance work**, not “done enough to start another huge
feature.”

## Completion accounting

Roadmap reporting uses three counts, kept separate:

- **Accepted on phone:** finished for the current scope.
- **Waiting for phone acceptance:** implementation exists, but still consumes WIP until accepted.
- **In source development:** not yet available to Aimee and therefore not a visible build change.

Do not combine these into a broad percentage-complete claim. A checkpoint that touches many files
but has not reached the phone belongs only in the third count.

## Completion Tier A — finish before new breadth

Ordered by effect on the repeatable play loop:

| Order | Existing system | Current truth | Completion gate |
|---:|---|---|---|
| 1 | Opening economy / Recycler | Noll+Recycler source is green at `aaf6280`, not installed for its own acceptance | Fresh-save find/build/recycle/cancel/reload and next-bind runway pass |
| 2 | Resource/terrain/spatial readability | Implemented and installed; still belongs to physical-phone observation | Resource identity, six-across stock, no false sidewalls, unclipped map, compact Party/Library/Look pass |
| 3 | Bug reporting | Capture/outbox/Share work; direct submission has no approved relay | Real relay receipt makes Submitted truthful |
| 4 | Saves | Multi-slot system is implemented but awaiting phone acceptance | New/Continue/Load/Delete/export and legacy/corrupt-slot paths pass |
| 5 | Essence continuation/refining | Acquisition profile awaits multi-run evidence; Spring is actively being completed | Reasonable returns fund the next authored world; 2:1/3:1/auto paths are exact and installed |
| 6 | Encounter scaling | Rules are installed, but ordinary/apex feel is unaccepted | 2/5-person × early/established phone matrix lands in intended pressure bands |
| 7 | Expedition return/loss | Summary constructors and retention math still have split authority | One typed return receipt and stack-independent loss budgets pass every exit |
| 8 | Combat afflictions | Bleed has parallel legacy ownership and Barbed can double-tick | One exact-combatant affliction store, cure/prevention and migration pass |
| 9 | Combat progression | True graph authority exists; not all 72 nodes have working consumers/acceptance | Every node has a real consumer, migration preserves points and phone graph is playable |
| 10 | Apothecary | Existing station can be unreachable/empty and recipes contain invalid/stale costs | Nessa build path, Lesser Salve and all sustainable typed recipes work end to end |
| 11 | Existing assignment/Anchorage safety | Settlement/person placement are implemented but awaiting device acceptance | No silent spend, duplicate placement or lost person/realm on relaunch |

No late building, generated-person, animal, predation or realm-production implementation begins
while a Tier-A item is active and useful work remains on it.

## Completion Tier B — deepen existing core systems

After Tier A:

1. finish core object/person/world visual identity using accepted authored assets;
2. complete known Isolde/Sabine prose review;
3. complete the existing Writing Desk progression: Charcoal → Brush → Fountain Pen, Ink Mixing,
   Compound Assembly/Chaining and safe vocabulary migration;
4. complete requested encounter-avoidance agency through the existing awareness/Apothecary systems;
5. close retired Token/Quirk and compound-hostility fossils.

These deepen systems the player already uses. They still outrank new simulation breadth.

## Completion Tier C — specialist depth, one system at a time

Only after Tiers A–B are accepted:

1. finish one existing specialist promise at a time: Channelworks restoration/schematic, Talin's
   teaching, then Deep Works/site breadth;
2. require full rules/persistence/UI/device completion for that system before starting the next;
3. do not build several station backends in parallel merely because their design documents exist.

## Completion Tier D — genuinely new breadth

Strict order:

1. generated-person stable identity and arrival builds;
2. Tavern visitors/wants;
3. Menagerie/taming;
4. tamed-animal combat;
5. predation;
6. optional group-motion texture;
7. anchored-realm renewable production and instrumented anchor-route retuning;
8. Great Work/Tam/endgame after explicit story review;
9. tutorials dead last.

Each entry requires the previous entry's full implementation gate. Design may continue documenting
future constraints, but those documents are parked and do not authorize Engineering work.

## Immediate correction to cross-lead behavior

- Game Design sends Tier-C/D audits as **parked reference only**, not “next task” suggestions.
- Engineering completes its already-started Spring slice, then returns to the numbered Tier-A chain.
- Asset works only on a Tier-A/B consumer or an explicitly requested authored-art decision; broad
  catalogue expansion stays paused.
- The DEBUG roadmap should show acceptance work as active debt, not bury it beneath newer feature
  entries.
