# Equipment access and spatial picker — current

Status: current implementation contract, 10 August 2026.

## Player promise

At Home, choosing equipment shows every compatible physical item the player owns. The picker must
never imply that an item vanished merely because it is in overflow or worn by somebody who is not
in the active party.

Each tile names its location: **Stored**, **Waiting to sort**, **Worn by _name_**, or **Carried in
world**. Expedition-carried equipment is visible but read-only from Home; moving it would bypass
the expedition return and collapse rules.

## Identity and movement

- A physical item's frozen instance profile determines its slot and combat identity. Current
  catalogue data is only a legacy fallback.
- Stored and overflow choices move the exact stable instance to the selected person. Replaced gear
  returns through ordinary Base storage and may enter overflow if the Storehouse is full.
- Choosing an item worn by somebody else performs an atomic same-slot swap. This keeps both people
  valid and makes “Worn by Quill” mean exactly what the tap suggests.
- The selected person's current item is displayed separately as **Worn now**, never duplicated in
  the candidate grid.
- Stale tiles and invalid targets do nothing and do not dismiss the picker. No action identifies a
  physical item by catalogue ID alone.

## Interface grammar

Equipment is a visual selection task, not an inventory ledger. The picker uses a two-column
adaptive tile grid at ordinary phone text sizes and one column at accessibility sizes. Tiles retain
the important comparison information: icon, rarity/name, tier or combat property, direct damage or
protection delta, quantity, and ownership location.

## Verification gates

- Frozen slot overrides changed catalogue slot.
- Overflow equips exactly one item without loss.
- Gear swaps preserve stable identity, reforge work, and wild growth.
- Inactive roster wearers are included.
- Stale worn references and invalid targets are atomic no-ops.
- Carried gear remains in the active expedition.

