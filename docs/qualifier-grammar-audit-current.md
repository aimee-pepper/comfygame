# Qualifier grammar audit — live 17-rung catalogue

**Status:** Generic ladder semantics and connection validity are implementation-ready. Hydrology
Phase vocabulary is held for Aimee's review; hide it rather than ship inert choices.  
**Updated:** 9 Aug 2026

## What actually exists

The old backlog request to “re-audit the 51 qualifiers” no longer describes the game. The live
catalogue contains **17 rungs across four populated ladders**:

| Ladder | Live rungs | Scope | Live effect |
|---|---|---|---|
| Intensity | Faint · Moderate · Great · Overwhelming | Generic | Scales the focus's primary and implicit-secondary contributions |
| Scale | Minute · Small · Large · Vast | Generic | Changes extent/dispersion where the subject has extent; otherwise changes magnitude; on Relief also selects world map size |
| Count | Single · Pair · Few · Many · Countless | Generic | Uses representative counts 1/2/3/4/5, sublinearly scales contribution and increases dispersion |
| Phase | Frozen · Solid · Liquid · Vaporous | Hydrology only | **Not implemented:** no Phase value survives page resolution or binding |

The model enum also contains `direction`, but no Direction rungs exist. It is dormant schema, not
player vocabulary, and should not be presented or counted as content.

## Settled generic semantics

Intensity, Scale and Count remain distinct because they answer different authorship questions:

- **Intensity:** how much force or amount each instance contributes.
- **Scale:** how far or how large each instance extends.
- **Count:** how many distinct instances exist.

This preserves writable differences such as one vast shallow sea, many small springs, and one
overwhelming sun. Count stays sublinear so it is not a duplicate Intensity ladder. Scale changes
dispersion rather than magnitude where a subject has a separate extent axis; Relief's Scale also
sets map size and its stability/traversal trade-off.

### Omitted and explicit ordinary rungs

Omitting a ladder uses the ordinary reading: Moderate Intensity, ordinary Scale and one instance.
Moderate and Single therefore express deliberate ordinary values rather than increasing the number.
They may remain because the writing language needs to distinguish an authored statement from a
missing modifier, but UI copy must not promise a numeric increase. Their page-space cost is the cost
of precision. Do not describe every applicable rung as “stronger.”

One correction is required for Scale arithmetic: **Small must be below ordinary**, not the same as
ordinary on every non-Relief subject. Treat the four written rungs as signed offsets around the
unwritten ordinary centre:

| Rung | Offset from ordinary |
|---|---:|
| Minute | -2 |
| Small | -1 |
| *(unwritten ordinary)* | 0 |
| Large | +1 |
| Vast | +2 |

This preserves current world sizes while making a Small Sun or Small Sea honestly smaller than an
unqualified one. Exact magnitude/dispersion per offset remains debug tuning.

## Connection grammar

Adjacency is necessary but not sufficient. A proposed link is valid only if the resulting connected
component can be read as one unambiguous statement.

### Valid component

- exactly one target anchor;
- one or more focuses that may legally attach to that target;
- zero or more modifiers, each linked **directly to exactly one focus**;
- no more than one rung from each ladder on a given focus;
- multiple focuses only when the existing chaining capability permits them.

### Invalid links

Reject a link, with a short visible reason, when it would create:

- two target anchors in one component;
- a focus bound to a target outside its authored `attachesTo` list;
- qualifier→target, qualifier→qualifier, or a qualifier shared by several focuses;
- two Intensity, Scale, Count or Phase rungs on one focus;
- a narrow modifier applied outside its allowed target;
- another focus when chaining is not unlocked.

Composition order remains flexible. A focus and qualifier may be joined before a target is added;
the later target link must validate the whole prospective component. Do not silently choose the
lowest target ID, first link-set element or first rung. Invalid old pages remain loadable and receive
the existing inert/ambiguous warning, but new edits cannot create the ambiguity.

## Hydrology Phase — review, not silent canon

The present four labels do not align with the simulation's actual Hydrology forms:

- simulation: `standing`, `flowing`, `frozen`, `airborne`;
- palette: Frozen, Solid, Liquid, Vaporous.

“Solid” duplicates frozen water, while “Liquid” cannot say whether water stands or flows. Wiring
those labels directly would either create synonyms or make the resolver guess a mechanically
important form.

### Recommendation for Aimee

Replace the Phase choices with the four actual form directions:

- **Standing**
- **Flowing**
- **Frozen**
- **Airborne**

A Phase modifier would redirect that focus's positive Hydrology form contribution before
cross-target constraints. Thermal constraints may still freeze liquid water afterward; the world
should visibly record that the written form was changed by another pressure rather than pretending
the qualifier was ignored.

Until Aimee reviews this vocabulary correction, **hide the Phase palette section**. Preserve its
catalogue IDs/save decoding, but do not let players spend page cells on a modifier known to be inert.
This is a reversible correctness hold, not approval of the replacement names.

## Preview, Library and analysis

- The page readout names every attached modifier and marks no applicable generic rung inert.
- Pre-bind projection uses the same signed Scale offsets and Count representative values as bind.
- Tier-3 attribution includes all three generic multipliers in primary and secondary contributions.
- World History stores the written modifier words even if constraints changed the outcome.
- Analysis distinguishes **what was written** from the resolved form/amount; it does not claim a
  constraint-induced result was authored.

## Debug controls and verification

Expose Scale magnitude, Scale dispersion, Count exponent and world-size/stability values. Add tests:

1. Small < ordinary < Large for a non-extent focus and for dispersion on an extent-bearing subject.
2. Count uses 1/2/3/4/5 representative values and remains sublinear.
3. Every valid generic rung changes resolution or deliberately expresses the documented ordinary.
4. New linking rejects every ambiguous component shape above without damaging the page.
5. Connection and resolution are deterministic regardless of set/placement order.
6. Phase is absent from the writable palette until an approved mapping reaches `Sigil`, save/load,
   preview, resolver, constraints and History together.

