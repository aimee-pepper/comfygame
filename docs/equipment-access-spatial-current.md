# Equipment access and spatial picker — current

Status: current implementation contract, 10 August 2026.

## Player promise

At Home, choosing equipment shows every compatible physical item the player owns. The picker must
never imply that an item vanished merely because it is in overflow or worn by somebody who is not
in the active party.

Each icon carries a compact location marker for **Stored**, **Waiting to sort**, **Worn**, or
**Carried in world**; tapping it names the exact wearer/location in the detail sheet.
Expedition-carried equipment is visible but read-only from Home; moving it would bypass the
expedition return and collapse rules.

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

Equipment is a visual selection task, not an inventory ledger. At ordinary phone sizes the picker
uses **six square item icons per row**. The grid does not print an item name, blurb, stat sentence or
location sentence under every icon. A tap opens the focused detail/selection sheet containing name,
provenance, tier and combat properties, direct damage/protection delta, quantity, exact ownership
location and the available action.

Each grid cell remains at least 44×44 points. Item identity comes from dedicated pictorial art rather
than unrelated SF Symbols. Quantity, unknown identity, rarity and location use compact redundant
badges/frame shapes; colour is supplementary. VoiceOver supplies the full item name, quantity,
location and action even though those words are not visually repeated in the grid. At accessibility
text sizes the detail sheet reflows, but the icon collection remains a compact collection rather
than becoming six prose cards.

## Verification gates

- Frozen slot overrides changed catalogue slot.
- Overflow equips exactly one item without loss.
- Gear swaps preserve stable identity, reforge work, and wild growth.
- Inactive roster wearers are included.
- Stale worn references and invalid targets are atomic no-ops.
- Carried gear remains in the active expedition.
