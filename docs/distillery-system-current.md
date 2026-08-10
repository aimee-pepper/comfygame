# The Distillery — current design

**Status:** implementation-facing first slice. Recipe costs and potency bands are playtest values.
This makes the approved direction in `traveller-identity-auber-distillery.md` buildable without
prematurely inventing a universal infusion upgrade.

## Boundary

The Refinery keeps raw essence → spendable essence. Auber never improves that exchange rate.
The Distillery spends ordinary essence to create finite crafted components:

1. **Crystallise** essence into a stable blank crystal.
2. **Attune** that crystal toward Heat, Caustic or Light for Channelworks and later authored recipes.
3. **Infuse** remains an approved later operation, but is not available until crafted-instance
   profiles provide a specific constrained consumer.

There is one essence wallet. Crystals and attuned cores are items, never new currencies.

## Crystallise

**Placeholder recipe — Essence crystal**

- 40 essence;
- 2 Quartz;
- one Distillery action at base, resolving immediately.

Output is one stackable **Essence crystal**. Quartz supplies a stable legible lattice; it does not
become generic Glass or consume Rift-glass. The recipe has no failure chance, timer or yield roll.

Blank crystals stack and carry Auber/Distillery provenance. They do not carry a world attunement,
deal damage, replace spendable essence or satisfy a recipe that explicitly requires an attuned core.

## Attune

Attuning consumes one blank crystal, 15 essence, one named bulk catalyst and one selected
provenance-bearing world resource sample. The sample is chosen explicitly and previewed; the
weakest qualifying sample is suggested first.

| Core | Bulk catalyst | Selected sample requirement | Channelworks result |
|---|---|---|---|
| **Heat core** | 2 Sulfur | reactivity ≥60 and insulation ≥25 | Heat; Burn |
| **Caustic core** | 2 Toxin or 1 Ichor | reagent/toxin/ichor with reactivity ≥60 | Caustic; Poison |
| **Light core** | 2 Silver | lustre ≥60 and hardness ≥30 | Light; Dazzle |

“World resource” is the player-facing term for the selected property-bearing sample; implementation
may retain `MaterialSample`. Aggregate ResourcePool stock does not falsely acquire provenance or
properties.

An attuned core stores:

- attunement ID;
- potency grade;
- selected sample source/qualifier/kind;
- consumed bulk catalyst and recipe version;
- Distillery provenance.

It stacks only with a core whose attunement, potency band and display provenance are equivalent.

### Potency

**Placeholder:**

`core potency = 0.7 × selected sample grade + 0.3 × relevant qualifying property`

For Heat and Caustic the relevant property is reactivity; for Light it is lustre. Use the same
0–39/40–64/65–84/85+ display bands as crafted gear, but call them **faint, clear, strong, brilliant**
rather than equipment tiers. Oda's housing tier caps usable potency and warns before consuming a
core whose excess would be wasted.

Core potency may tune raw emanation/affliction strength within the Channelworks profile. It never
changes reach family, grants a new status or bypasses Ward.

## Channelworks handoff

Oda consumes one attuned core when constructing or retuning a housing. The resulting weapon records
the core's attunement, potency band and provenance; it does not retain a hidden pointer to an item
that no longer exists.

Retuning consumes a new core. The removed core is not recovered: containment work changes it. The
confirmation previews the old and new attunements and names that the old core is lost.

The Distillery never builds a weapon. The Channelworks never crystallises or attunes essence. This
two-station dependency is intentional late-game cooperation and is displayed on both recipe cards.

## Infuse — approved direction, held implementation

Infusion may eventually concentrate one already-present property or authored behavior on a crafted
instance while imposing a visible compensating limit. It must not:

- add a generic item tier or reforge rank;
- apply to every found object through one universal +1;
- overwrite immutable material provenance;
- stack recursively;
- create new statuses or damage axes;
- bypass the Armoury, Weaponsmith, Bowyer, Tannery or Channelworks.

Do not implement an Infuse button until at least one named item profile has a designed trade-off and
a downstream rule that reads it. Crystallise and Attune form a complete useful first Distillery.

## Station progression

Use three short station-owned branches rather than filler:

- **Separate:** Essence crystal root, then lower waste/cost choices only where they create a visible
  material decision.
- **Attune:** Heat root; Caustic and Light as sibling unlocks; potency preview follows.
- **Concentrate:** held Infuse leads remain visible as unavailable research only after a real
  consumer exists. Before then, omit the branch entirely.

Building the Distillery exposes Crystallise and Heat-core research. Caustic/Light placement may
follow the player's existing status vocabulary, but neither is randomly dropped.

## Residue and inventory

Auber's fiction names carrier and residue, but v1 does not create waste stacks. Consumed catalysts
are recorded in provenance/history and are gone. Adding residue items before they have a use would
turn his character theme into storage punishment.

Core storage uses ordinary Storehouse rules and safe spillover. Distillation cannot run when its
output has nowhere safely representable to go; it never deletes or auto-sells another item.

## Complexity boundary

No real-time still, batch queue, fuel meter, purity minigame, random failure, essence provenance per
wallet unit, universal item infusion, charge/ammunition system or fourth attunement enters the first
slice. Freeze, shock and Arc remain absent.

## Implementation order

1. Add Auber as `builtBy`, build cost and route owner for the Distillery.
2. Add blank crystal item/recipe and safe stack persistence.
3. Add one Heat core and its provenance/potency preview.
4. Connect Heat core to one Conduit housing fixture.
5. Add Caustic and Light through the identical schema.
6. Add retuning only after construction/save behavior is proven.
7. Leave Infuse unimplemented until a separate current design names its first consumer.
