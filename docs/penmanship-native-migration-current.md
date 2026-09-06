# Penmanship native migration — current

> **6 September production authority:** Historical identity/topology reference. Native Brush naming/topology and the current45-Essence source cost already exist; the old150-Essence discussion and economy-review permission questions are superseded. Use the complete Scriptorium contract for new costs, material sources, exact currency spending and campaign preservation. Do not repeat its historical verification programme. See [Scriptorium and Writing Desk](scriptorium-writing-desk-whole-system-production-v1.md).

**Status:** implementation-ready identity/topology migration; economy values remain playtest tuning  
**Date:** 11 August 2026  
**Authority:** `writing-tool-progression-current.md`, `authored-color-vocabulary-current.md`, and
`compound-assembly-station-trees-current.md`

## Why this checkpoint exists

When this historical checkpoint was authored, the catalogue and model exposed `pen_pencil`, display `Hand.plain` as **Pencil**, route
Isolde's diary rewards to the old ID, and tested Penmanship as a line. The settled game instead uses
Rough Charcoal → Brush → Fountain Pen, with three independent practices branching after Brush.
Changing only visible strings would leave misleading stable IDs, stale prerequisites and no place
for Ink Mixing or Compound Assembly.

This checkpoint changes identity and topology together. It does not implement the mixer, personal
compound receipts or a new research-screen layout by itself.

## Current node graph

```text
pen_brush                  Brush; first purchased hand
    |\
    | +-- pen_desk         A table that doesn't rock; supplies Scriptorium tier 1
    | +-- pen_ink_mixing   Ink Mixing capability; effective tier 1 gate
    | +-- pen_compounds    Compound Assembly capability; effective tier 1 gate
    | +-- pen_chaining     Chaining capability; effective tier 1 gate
    |          |\
    |          | +-- pen_press      supplies Scriptorium tier 2
    |          +---- pen_fountain   final hand; effective tier 2 gate
```

Exact prerequisite rules:

| Node | Requires | Station tier | Consequence |
|---|---|---:|---|
| `pen_brush` | none; Scriptorium must exist through the branch owner rule | 0 | one `finerHand`: crude → plain |
| `pen_desk` | `pen_brush` | 0 | set/raise Scriptorium to tier 1 |
| `pen_ink_mixing` | `pen_brush` | 1 | capability `inkMixing` |
| `pen_compounds` | `pen_brush` | 1 | capability `compoundAssembly` |
| `pen_chaining` | `pen_brush` | 1 | effect/capability `chaining` |
| `pen_press` | `pen_chaining` | 1 | set/raise Scriptorium to tier 2 |
| `pen_fountain` | `pen_chaining` | 2 | one `finerHand`: plain → refined |

The three tier-1 practices are siblings. None requires or grants another. The Fountain Pen does not
require Ink Mixing or Compound Assembly: precision, deliberate color and semantic compression are
different choices. `pen_desk` and `pen_press` are the purchased routes to effective tiers 1 and 2;
they are not duplicated as hard prerequisites because keeper-earned tier uses the same effective-tier
authority. Their completed tier grants must be idempotent.

### Costs are owned by the complete system contract

The runtime now uses the later 45-Essence Brush and Brush identity. The earlier 150-Essence proposal is historical and must not be implemented from this document. The complete Scriptorium contract replaces the next implementation's full cost profile, starting with a 35-Essence Brush and named Iron/Fibre/Log inputs. It also closes Ink Mixing, Compounds, Chaining's actual Mote currency, the frame, Fountain and all lens recipes together.

Retain the actual continuation advisory, not an old full-map income assumption or a new telemetry programme. Graph/identity facts below remain useful migration constraints; old prices and historical pending approvals do not.

## Stable migration

Before catalogue validation, migrate every saved `pen_pencil` completion to `pen_brush` and remove
the old ID. Apply the same alias when decoding diary teaching/reward progress. The current catalogue,
new saves, prerequisites and runtime checks contain only `pen_brush`; `pen_pencil` is accepted solely
at legacy decode boundaries.

`Hand.plain` remains the serialized page value and displays **Brush**. Existing rune shapes,
footprints, rotations and placed-page geometry do not change. A save that owned Pencil owns exactly
one Brush and receives neither Ink Mixing nor a refund. A save that already owns dependent legacy
nodes remains reachable after prerequisite migration.

Introduce the permanent capabilities through the shared capability set identified by the dynamic-
authority audit, rather than adding one Boolean per Scriptorium practice. Legacy `chaining` decodes
into that set once; typed conveniences may remain computed accessors. Completion and keeper-supplied
station tiers remain separate from capabilities.

## Presentation and behavior boundary

- `Hand.crude` displays **Rough charcoal**, `Hand.plain` **Brush**, and `Hand.refined`
  **Fountain pen**.
- The graph presents the three practices as adjacent siblings, not as a linear shopping list.
- Ink Mixing may be visible while locked before tier 1, but cannot be bought before both Brush and
  the table/tier gate.
- Buying Brush enables Ash/open liquid-ink writing. It does not expose colored recipes.
- Buying Ink Mixing exposes the mixer and saved mixtures. It does not change footprint.
- Buying Fountain Pen enables refined one-cell shapes. It does not grant Ink Mixing.
- Rough-charcoal marks reject mixed ink before mutation; existing plain marks may use it once the
  capability and vial/application rules are satisfied.

## Acceptance gates

1. Fresh save and built tier-0 Scriptorium show Brush as the only purchasable Penmanship root.
2. Brush alone enables plain-hand/Ash writing and leaves all three practices gated by effective
   tier 1; the graph still shows each as a direct Brush child.
3. Tier 1 exposes three independent sibling nodes; purchasing each leaves the other two unchanged.
4. Fountain Pen remains unreachable without Chaining and effective tier 2, but remains reachable
   without Ink Mixing or Compound Assembly; keeper-earned tier 2 may honestly replace buying the
   ruling frame under the shared effective-tier rule.
5. Legacy `pen_pencil` save/diary data becomes one `pen_brush` completion with no duplicate cost,
   point, node or altered page geometry after save/relaunch.
6. Current catalogue, UI, VoiceOver, diary and DEBUG strings contain no player-facing Pencil.
7. Capability-set migration preserves legacy Chaining and round-trips all three new practices.
8. Research DAG validation proves every node reachable and cycle-free, and a shuffled JSON array
   cannot change graph position or prerequisite meaning.
9. The Brush cost preview names ferrule, bristles and handle; a forced Isolde-phase fixture proves
   the three materials have at least one reachable world/merchant route and the purchase leaves the
   configured next-bind Essence runway.

## Not in this checkpoint

- tutorial prompts;
- final Ink Mixing tuning/feel; Decision 164 already settles the first native interaction as one
  atomic just-in-time vial preparation, while DRQ-156 may later compare explicit batching;
- personal compound receipt/Runebook implementation;
- colored-world renderer integration;
- final research-screen art.
