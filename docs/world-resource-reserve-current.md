# Property-Bearing Harvest Reserve — storage foundation

**Status:** source-complete slot/correctness foundation; player-facing category and quality semantics are
reopened under `creature-ecology-and-materials-overhaul-current.md` and the unaccepted
`loot-quality-hybrid-review-current.md`
**Priority:** active Band 1.4e checkpoint, after the landed durable Field Kit; before later crafting,
station, creature-display, or world-content breadth
**Supersedes:** the slot-consuming material-bin decision in `decisions-session-16.md` and the open
stacking question in `materials-crafting-spec.md` §9
**Preserves:** exact counts/identity through the current reserve while the later accepted migration splits
animal-derived units into Creature materials and may convert continuous grade/provenance units into discrete
domain+family+quality stacks.

Do not implement the withdrawn pure-no-grade proposal or the hybrid stack conversion until Aimee settles the
quality review. The current slot-free behavior remains valid groundwork; final stack key, price, crafting,
provenance and consumer conversion will come from the accepted quality authority.

## Player promise

Hides, bones, and every other ordinary harvested creature/flora material do not consume item or Field Kit
slots. A player may carry nineteen hides without losing the ability to carry a blade, curio, consumable, or
other actual item.

The settled player-facing split is now:

- **World resources:** named ground, flora and site yields;
- **Creature materials:** body-derived animal parts such as hides, bones, feathers, scales and ichor;
- **Items:** gear, consumables, curios and other capacity-bearing instances.

The current combined reserve implementation is useful storage/migration groundwork, not authority to call
Hides/Bones world resources in final UI.

The UI groups them by kind and quantity:

- `Hides ×19`
- `Bones ×6`

A material detail may expose the individual samples when that distinction is useful for crafting:
inherited properties, source creature/world, and qualifier remain intact. Aggregated
presentation must not flatten mechanically distinct samples into one averaged or invented sample.

## Canonical storage boundary

`ItemStack` / `Inventory` is not the canonical owner of `MaterialSample`.

Both Home and an active expedition need a non-slot reserve whose durable payload is an ordered
collection of exact `MaterialSample` values. The implementation may index or group that collection
by `MaterialKind`, but ordering and exact sample identity must remain deterministic so a crafting
selection can still commit the exact sample previewed.

- **Home:** property-bearing harvest reserves, independently grouped as World resources or Creature
  materials and independent of Storehouse item capacity.
- **Expedition:** property-bearing haul reserves with the same domain split, independent of satchel item
  capacity.
- **Bulk `ResourcePool`:** remains appropriate for homogeneous named resources whose individual
  provenance/properties do not matter. It must not absorb a `MaterialSample` by discarding facts.
- **Items:** gear, consumables, curios, keys, treasures, cores, and other physical item instances.

The internal exact-sample representation may be shared where useful, but internal storage reuse cannot
collapse the player-facing World-resource/Creature-material distinction.

## Acquisition and capacity

Creature butchery and flora harvesting deposit exact samples directly into the expedition resource
reserve. They never:

- consume a satchel item slot;
- enter `offeredItems`;
- open the item swap decision;
- cause an item-capacity failure;
- occupy Storehouse inventory or spillover on return.

Item capacity continues to constrain items only, as settled in `decisions-log.md` §7.

## Return and loss receipt

The atomic expedition outcome applies the existing success/failure retention policy to
property-bearing resources, then transfers retained exact samples to Home. The frozen outcome keeps
sample-level receipt identity for idempotence and provenance, while its ordinary recap projection is
grouped by `MaterialKind`.

The recap has separate **Resources** and **Items** sections. Each resource kind appears at most once
per recovered/lost section:

- nineteen retained hide samples render as `Hides +19`, not nineteen `Hides +1` rows;
- hides and bones remain separate rows;
- a material never appears in the Items section;
- tapping a grouped row may show the constituent samples without changing the receipt.

Grouping is presentation over frozen exact lines, not destructive coalescing. Outcome replay and
relaunch must not duplicate either the aggregate quantity or any underlying sample.

## Crafting and trading consumers

All rules that currently search `base.inventory.stacks[*].materials` must instead query the Home
world-resource reserve. A selection must use a stable exact-sample handle owned by the reserve—not
an inventory-bin ID plus a mutable array index. Preview and commit revalidate the same sample and
fail atomically if it is no longer present.

Trading Post and Recycler surfaces classify samples under Resources. Buying, selling, recycling,
and recipe consumption preserve exact quantities and never route them through item capacity.

### Trading Post sale rule

Vance buys exact material samples, not a flattened quantity detached from quality. The collapsed
Trading Post Resources grid groups the reserve by `MaterialKind`; opening one kind shows its exact
samples, source/qualifier and quoted value. Selling commits stable reserve-unit IDs atomically.

Version 1 prices one exact sample from its frozen grade:

`sale value = clamp(1 + floor(grade / 20), 1...6) Gold`

Thus an ordinary grade-25–39 merchant sample bought for 3 Gold resells for 2 Gold, preventing a
buy/sell loop; exceptional grade-80+ finds are worth 5+ Gold and feel meaningfully costly to give
up. Grade is already the canonical summary of sample quality, so V1 must not invent a second hidden
rarity score. A later convenience control may sell all samples in an explicitly selected grade
band, but the game must never silently choose the player's finest sample merely because a grouped
kind tile was tapped.

## Save migration

Prefer lossless compatible migration:

1. Decode the new reserve if present.
2. Lift every legacy `ItemStack.materials` sample from Home inventory, overflow/spillover, active-run
   satchel items, and pending offered loot into the corresponding Home or expedition reserve.
3. Remove only the migrated material quantities/empty legacy bins; preserve unrelated stack state.
4. Deduplicate through a versioned one-time migration receipt or schema version so relaunch cannot
   lift the same samples twice.
5. If exact sample preservation cannot be made safe, use the project save-version policy and clearly
   mark the incompatible save in UI rather than keeping both gameplay implementations alive.

## Acceptance gates

1. Defeating creatures that yield nineteen hides and six bones produces exactly two recovered
   resource rows: `Hides +19`, `Bones +6`.
2. The same haul changes neither expedition item-slot usage nor Home Storehouse item-slot usage.
3. A full item satchel and full Storehouse still accept additional harvested samples without an
   offer/swap/spillover state.
4. Every retained sample keeps kind, six properties, grade, source, and qualifier through return and
   save/relaunch.
5. Partial-failure partitioning is deterministic, lossless across kept+lost, and grouped truthfully
   in both recap sections.
6. Crafting previews and consumes the exact selected sample; stale selection is a zero-mutation
   failure.
7. Trading/Recycler classify the stock as Resources and never affect item capacity.
   Trading Post sale preview names and prices each selected exact sample; stale/duplicate IDs fail
   with zero mutation, and buying then immediately reselling ordinary merchant stock cannot profit.
8. Legacy material bins migrate once from every supported location without duplication or loss.
9. Ordinary phone proof shows grouped resource rows without the repeated `+1` list seen in the
   14 Aug 2026 playtest screenshot.

## Implementation review — 14 Aug 2026

The active source candidate now has separate Home and expedition reserves with stable exact-unit
identity. Butchery, expedition return/failure, Storehouse Resources, Trading Post stock, Recycler
returns, and the current crafting consumers have been routed through that reserve. The frozen recap
continues to hold one receipt line per exact sample while its player-facing projection groups by
material kind.

The screenshot-shaped fixture is explicit: nineteen Hides plus six Bones produces two Resource
totals, no Item totals, twenty-five distinct receipt lines, and twenty-five exact Home reserve units.
Legacy Home inventory, spillover, expedition satchel, and pending offered-material locations have
lossless migration fixtures. Every live crafting consumer now uses only stable reserve selections;
legacy item bins migrate during decode and do not fund current gameplay directly. Exact-sample
Trading Post sales expose grade, provenance, and the rules-owned price, reject stale or duplicate
selections atomically, and preserve the ordinary buy/sell spread. The focused reserve suites and a
full generic iOS build-for-testing are green. Ordinary-phone recap and Storehouse presentation
remain the final acceptance gate before this checkpoint can move beyond `readyToTest`.
