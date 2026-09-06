# Ink economy friction audit — current

> **6 September production authority:** Just-in-time vial preparation remains the intended/current interaction. The complete Scriptorium contract replaces the source table with Copper/Dyer's Root/Sulfur/Obsidian and explicit preserved legacy Ichor support. Ichor is not a newly generated world resource; no broader old comparison/audit is requested. See [Scriptorium and Writing Desk](scriptorium-writing-desk-whole-system-production-v1.md).

**Status:** current role/resource boundary plus reversible first-slice interaction placeholder.  
**Authority:** `authored-color-vocabulary-current.md` remains the live recipe and resolver contract;
this document owns the just-in-time preparation interaction pending Aimee's later feel review.

## Settled ownership

Isolde owns ordinary **writing ink** through the Scriptorium's Penmanship branch. Ink mixing unlocks
CMY+Depth formulas, pigment processing, saved mixtures and colored focus applications at every
Writing Desk. Nessa's Apothecary does not unlock, prepare or sell this color-authorship system.

Nessa may later own a specifically designed reactive stain, identifying reagent or harmful coating
whose effect is materially chemical. Such an item must be named and designed as that effect; the word
“ink” in older roster/crafting proposals does not grant her the current writing-pigment economy.

This split keeps the identities clear:

- **Isolde:** how a mark is made, read, repeated and deliberately colored;
- **Nessa:** what a prepared substance does to a body, tool or observable sample;
- **Auber:** how a carrier and remainder separate or changes phase.

## Resource check

The following is the intended source mapping from the whole Scriptorium contract; typed producer integration is still pending:

| Use | Existing resource | Current recipe role |
|---|---|---|
| Cyan | Copper | 1 unit → 4 Cyan measures |
| Magenta | Dyer's Root | 1 unit → 4 Magenta measures; supported old Ichor stock keeps its legacy route |
| Yellow | Sulfur | 1 unit → 4 Yellow measures |
| Depth | Obsidian | 1 unit → 4 Depth measures |
| Vial binder | Resin | 1 per prepared vial |

No generic “color sample,” new pigment loot family or name-based conversion is needed. Exact source
resource IDs—not their current icon or rendered hue—own these recipes. Ash remains unlimited, so the
optional color loop cannot block writing another world.

## Friction finding

The current implementation-ready contract contains three player-visible objects/actions between a
world resource and use:

```text
resource → process into stored base measures → prepare mixture vial → spend applications on bind
```

That is mechanically honest but may be one interaction layer too many for a visual authorship system.
Four additional station stocks also risk recreating the Storehouse/list clutter that the six-across
resource redesign is removing. The player already makes the meaningful decisions when they choose a
formula and decide which focus deserves a limited vial application; manually converting Copper into
an inevitable Cyan counter may be accounting rather than play.

## Reversible first-slice decision

For the first native slice, collapse the separate processing verb into **one atomic Scriptorium vial
transaction with automatic just-in-time processing**:

1. choose or mix the exact formula;
2. preview the required Copper/Dyer's Root/Sulfur/Obsidian units, Resin and 12 applications;
3. confirm once; spend existing station measures, automatically process the minimum exact world
   resources needed to cover the shortfall, retain any resulting excess measures at the Scriptorium,
   and create the vial.

The conversion remains visibly explained—one resource unit supplies four measures, and
`ceil(channel/25)` determines required measures. Base measures remain small station-local ingredient
balances, not Storehouse resources, and the player never has to run a foregone “turn Copper into
Cyan” action before making the vial. For example, a Cyan-26 vial needs two measures: with no Cyan
stock it processes one Copper, spends two measures and leaves two for a later vial.

This recommendation preserves every settled creative rule: CMY+Depth, resource derivation, Resin,
saved formulas, free drafting, bounded applications, unlimited Ash, exact recipes and atomic commit.
It changes only whether the deterministic intermediate stock requires its own manufacturing action.

Engineering should implement this just-in-time path for the first native slice. Keep base-stock
persistence so the interaction can later expose explicit processing without a save break, but make
vial preparation the sole ordinary player-facing processing action. This is a deliberately
reversible placeholder—not a claim that batching pigment could never become interesting.

## Current integration boundary

Keep the existing just-in-time vial interaction. The next implementation changes exact physical ingredient ownership and source profiles, not the number of screens. No second stored-measures comparison or new audit is requested.

## Retained transaction requirements

1. No Scriptorium action infers pigment from a resource's artwork or name at runtime.
2. Insufficient material and stale confirmation consume nothing.
3. Formula editing and page drafting consume nothing; successful bind spends exact applications.
4. The Writing Desk shows remaining applications but does not expose four base counters unless the
   stored-measures option is retained.
5. Trading Post/Recycler cannot treat intermediate pigment measures as ordinary world resources.
6. Nessa's Apothecary presents no generic colored-writing-ink category.
