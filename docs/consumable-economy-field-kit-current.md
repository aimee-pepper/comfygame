# Consumable economy and Field Kit — current design

> **Incoming material-domain correction (21 August 2026):** Field Kit capacity, packing and consumable
> transaction rules remain authoritative. Creature materials become their own slot-free domain and no longer
> carry universal grade under `creature-ecology-and-materials-overhaul-current.md`; older “world-resource
> sample/provenance/grade” wording below describes the implemented transitional model only.

**Status:** implementation-ready packing correction with reversible Recommended cost profile.  
**Owner:** Game Design owns roles, packing and economy; Engineering owns atomic inventory movement and
save migration; Aimee owns final item-family silhouettes, while Asset Design may validate functional
placeholder layout/state only.  
**Supersedes:** automatic inventory-order packing and the assumption that every preparation must
consume refined Essence.

## Audit result

The 17 live preparations have real recipes and consumers, but their surrounding loop is not yet
viable:

1. Every recipe costs refined Essence, including ordinary salves, antidotes, coatings, Torch, Lure
   and Solvent. Optional preparation therefore competes directly with writing the next world.
2. Departure automatically moves every identified consumable into the satchel in inventory order
   until capacity is full. The player cannot decide what to carry, and a later item can be excluded
   for reasons unrelated to its value.
3. Apothecary and field-use screens return to full-width recipe/item lists rather than the settled
   physical-object grammar.

This combination teaches the player not to craft and then denies control over what they did craft.

## Resource roles

Refined Essence is the medium that binds worlds and changes Reality. It is not a generic solvent or
crafting tax. Ordinary chemistry is paid for by named and property-qualified **world resources**;
those ingredients already create scarcity and world-writing goals. Do not expose “sample” as a
second player-facing inventory category: it is provenance/grade data on a world-resource instance.

### Recommended playtest profile

| Preparation family | Refined Essence | Reason |
|---|---:|---|
| Salves, cures, Stonebark | 0 | Ordinary treatment; world resources are the cost |
| Four one-hit coatings | 0 | Combat preparation; should be usable often enough to evaluate |
| Torch, Farsight, Solvent, Lure | 0 | Field tools whose rare resources already price their utility |
| Stillwater | **6** | Directly holds a written world together longer |
| Waystone | **12 + 1 mote** | Forces a Reality-level full-haul return |

These values are reversible DEBUG/playtest values. The structural rule is stronger: only an item
whose effect directly rewrites or escapes a bound world's Reality should normally cost refined
Essence. Do not reintroduce small Essence taxes across mundane recipes merely to make every currency
appear on every station.

The Apothecary preview shows **Essence after preparation** and **recent ordinary authored binds
remaining** whenever an Essence-bearing item is selected. This is information, not a hard reserve:
the player may deliberately spend below one-world runway.

## Explicit Field Kit loadout

Home owns one saved preparation loadout. It records desired quantities by stable item catalogue ID;
it never records inventory stack indices.

```text
FieldKitPreparationEntry {
  itemID: ItemID
  desiredCount: Int
  order: Int
}
BaseState.preparationLoadout: [FieldKitPreparationEntry]
```

- Configure it from a **Supplies** tab in the Field Kit surface and through a compact link beside
  Bind at the Writing Desk.
- Show available consumables as six-across item icons. Tap opens an anchored detail with current
  stock, desired count, effect and plus/minus controls.
- The footer always shows `distinct bins selected / satchel bins available`. Quantity within one
  stack does not consume another bin; a different item family does.
- At capacity, `+` on a zero-desired family is disabled with **All supply bins assigned**; `+` on an
  already selected family remains available because quantity does not consume another bin.
- A migrated/tuning-changed save that somehow contains more positive desired families than current
  capacity is shown as **Resolve N excess selections** and blocks Bind/Revisit until the player
  chooses which families return to zero. It never silently treats only the first families as selected.
- Instruments remain the Field Kit's **Instruments** tab and keep their existing independent
  carried-set rule. They do not silently consume preparation bins.
- Anchor Frames are explicit supplies and never displace medicine merely because their catalogue
  order is earlier.

### Departure transaction

On a successful new bind or anchored-realm revisit:

1. Resolve loadout entries in saved order, then stable item ID as a tie-break.
2. For each entry, pack `min(desiredCount, identified stock available)` using exact inventory
   instances/counts.
3. Stop only when the distinct-bin capacity is full. Never pack an unselected item as filler.
4. Present shortages before the final Bind/Revisit confirmation: **Wanted 3, available 1**. A
   shortage does not block departure unless the selected action independently requires that item.
5. Commit the book/revisit, Essence payment and exact item transfer as one mutation. If any required
   source became stale, nothing is spent or moved.
6. Freeze carried-in counts for the existing protected-return boundary.

Returning restores unused packed quantities through the normal exact inventory/spillover path.
Prepared supplies remain player property; ordinary collapse loss applies only to newly acquired haul,
not to supplies packed before departure.

### Migration

Legacy saves with no preparation loadout receive a one-time conservative template derived from
identified Home stock: up to two Lesser Salves, then one available status cure, then one available
world-facing escape/stability item, within current capacity. It is visibly marked **Suggested—review
before departure** and is saved only after the player confirms or edits it.

Do not snapshot the old “everything in inventory order” result: that preserves an accident rather
than player intent. A save with no qualifying stock simply has an empty preparation loadout.

## Apothecary screen

The station uses **Treatments / Coatings / Fieldwork** tabs:

- three-column recipe-family tiles at ordinary phone size;
- stable pictorial output identity, readiness frame and owned quantity;
- tap opens one persistent detail with effect, exact world resources, cost, shortfall and Prepare;
- preparing several copies uses an explicit quantity step and one atomic preview/commit;
- prepared outputs enter Storehouse/spillover and do not silently alter the saved Field Kit.

Recipe discovery remains permanent once inferred. Newly inferred recipes receive one restrained
badge until inspected; recipe order never controls what departs with the party.

## In-world use

Combat and world Field Kit surfaces reuse the six-across item tray. Selecting an item opens its legal
target/effect step; it does not immediately consume it. Invalid states—no injured ally, no curio, no
eligible roaming creature, already-lit world—are visibly disabled with a reason and cost nothing.

Coatings target one party member's current weapon and are consumed only when successfully prepared
for that member. Their one-hit effect and Stonebark's encounter boundary remain authoritative in
`crafting-spec (1).md`.

## Acceptance

1. Ordinary preparations can be crafted with zero refined Essence; Stillwater and Waystone use only
   their Recommended 6 and 12+1 costs.
2. A player with more consumable families than satchel bins can select the exact families/counts that
   depart, independent of inventory/catalogue order.
   Adding a fifth family at four-bin capacity is visibly rejected while increasing an existing
   family's desired quantity succeeds without changing the bin count.
3. Short stock, stale source, full spillover, cancel and interrupted departure preserve exact items,
   book, currencies and saved loadout.
4. New bind and anchored revisit use the same resolver and produce the same carried result.
5. Unused packed supplies remain protected on every exit kind; newly found items retain the existing
   haul-risk behavior.
6. Preparing an item does not auto-pack it or mutate the saved loadout.
7. At 368×800, Apothecary categories, six-across stock, quantity controls and Field Kit capacity are
   usable without full-width item lists; edge items open collision-safe detail.
8. VoiceOver identifies item, owned/desired/carried quantity, readiness, target legality and action
   consequence without relying on colour.

## Playtest questions

- Do zero-Essence mundane recipes make world-resource decisions sufficient, or does one family need
  another non-Essence reagent sink?
- Are 6 Essence for Stillwater and 12+1 mote for Waystone meaningful without threatening ordinary
  continuation?
- Does saved exact-quantity packing feel useful between expeditions, or should quantity default to
  “all available up to a cap” after repeated use?
