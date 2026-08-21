# Storehouse and field-pack capacity — current authority

**Status:** Game Design implementation authority for the capacity portion of Workshop removal. Exact values
are reversible tuning, but the ownership, number of upgrades and lossless migration shape are settled.
**Priority:** implement only with the ordered Workshop/Storehouse/Tannery migration; it does not pre-empt
opening playability work.
**Updated:** 21 August 2026

## Player-facing shape

World Resources and Creature Materials use their own stacking reserves and consume no item slots. Capacity
below is for exact Items/World Pages and distinct prepared Field Kit families only; it must not recreate a
resource-hoarding tax.

### Storehouse

| State | Project | Item-stack capacity | Cost | Physical receipt |
|---|---|---:|---|---|
| Built · Tier 0 | opening Storehouse | 16 | opening infrastructure | double doors, shelving, packing bench and manual hoist |
| Improved · Tier 1 | **Ordered Shelving** | 28 | 75 Essence + 12 Timber + 8 Fibre | side shelving bay, taller labelled racks and second loading door |
| Mastered · Tier 2 | **Receiving Annex** | 40 | 340 Essence + 24 Timber + 16 Iron Ore + 8 Fibre | connected annex, stronger hoist and covered receiving bay |

The increments are exactly +12 and +12. Storehouse tier never affects resource/material reserve capacity,
quality, crafting, Waiting safety or Trading Post stock. Waiting remains lossless overflow and cannot be used
to pretend a smaller active capacity did not lose an item.

If the three-district Constellation proposal is accepted, Commons Mastery permits the Tier-2 purchase but
does not pay its cost. Until that proposal is accepted, Tier 2 remains content-held rather than silently
gated by a Mote.

### Field pack

| Order | Owner | Project | Capacity before Sela | Cost | Physical receipt |
|---:|---|---|---:|---|---|
| 0 | opening Field Kit | ordinary pack | 8 | opening equipment | compact plain pack |
| 1 | Storehouse packing bench | **Reinforced Stitching** | 11 | 15 Essence + 4 Fibre | doubled seams and first fitted divider |
| 2 | Storehouse packing bench | **Balanced Straps** | 14 | 35 Essence + 8 Fibre + 2 Resin | load-spreading second strap and second divider |
| 3 | Corrin's Tannery → Carry | **Deepened Satchel** | 20 | 70 Essence + 8 Fibre + 4 Hide + 2 Resin | shaped pack frame, deeper body and weather flap |

Each project is one permanent campaign entitlement. The first two exist before Corrin so early testing and
economy do not deadlock behind a later traveller. Deepened Satchel requires Tannery Built and both earlier
projects; it adds +6 rather than another repetitive +3 rung. No fourth ordinary pack project exists.

Sela's Wayfarer's Table adds its separate existing +2 fieldcraft packing bonus after these projects, for a
new-campaign maximum of 22. That bonus belongs to Sela's passive fieldcraft receipt and is not displayed as
a fourth satchel construction.

## Exact packing semantics

- Capacity counts distinct prepared Item/World-Page families, not raw quantity within a stack.
- Resources, Creature Materials, currencies, recovered teachings and Diary Pages never consume it.
- The durable player-authored Field Kit plan remains authoritative. Capacity never authorizes automatic
  selection or resurrection of the retired inventory-order auto-pack behavior.
- Bind/revisit previews show `used / capacity`, every over-cap family and the project that would expand it.
- A refused or stale purchase/bind changes nothing. Purchase and exact stock consumption are atomic.

## Lossless legacy migration

The old Storehouse formula was `16 + 6 × oldShelvingCount` through nine purchases. Migrate once:

| Old shelving purchases | Old capacity | New receipt |
|---:|---:|---|
| 0 | 16 | Tier 0 |
| 1–2 | 22–28 | Ordered Shelving (28) |
| 3–4 | 34–40 | Receiving Annex (40) |
| 5–9 | 46–70 | Receiving Annex (40) + decode-only `legacyStorehouseCapacityCredit = oldCapacity − 40` |

The old satchel formula was `8 + 3 × oldSatchelCount` through five purchases. Migrate once:

| Old satchel purchases | Old capacity before Sela | New receipt |
|---:|---:|---|
| 0 | 8 | no project |
| 1 | 11 | Reinforced Stitching |
| 2 | 14 | + Balanced Straps |
| 3–4 | 17–20 | + Deepened Satchel (20) |
| 5 | 23 | all three + decode-only `legacySatchelCapacityCredit = 3` |

Legacy credits are frozen non-purchasable integer entitlements shown in Debug/save provenance, not new UI
rungs. They survive relaunch and never shrink. New campaigns always start with zero legacy credit. If the
project chooses a clean save-version break before this migration ships, incompatible old saves are visibly
version-gated instead; Engineering may not silently decode them at a lower capacity.

Completed old nodes remain in history/decode receipts. Do not refund Essence automatically, because the
equal-or-better capacity is preserved and a refund could duplicate value across migrated saves.

## Acceptance

1. Fresh-save capacities are exactly 16 Storehouse and 8/11/14/20 pack; Wayfarer's Table makes the last 22.
2. World/Creature/currency/teaching/Diary holdings never change either used-slot count.
3. Every old shelving count 0–9 and satchel count 0–5 migrates to capacity at least its old value.
4. Legacy credits cannot be bought, sold, reset, doubled on decode or shown as a future project.
5. Full storage sends an exact displaced Item to Waiting without identity loss; it never discards or merges it.
6. No auto-pack, inventory-order dependence or hidden capacity appears.
7. Storehouse and pack visuals change only at the exact projects above.
