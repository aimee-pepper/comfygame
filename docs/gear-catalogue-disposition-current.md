# Gear catalogue disposition — current

**Status:** exact Game Design authority for the 75 current Gear catalogue IDs during the six-band/component
migration.  This closes the remaining catalogue ambiguity left by the schematic table; it does not begin
the gameplay migration or authorize bulk final art.
**Machine authority:** `gear-catalogue-disposition-authority.json`.
**Updated:** 21 August 2026.

## The catalogue has three jobs, not one

1. **Crafted gear** is identified by its frozen Schematic and component receipt. Its catalogue fallback is
   only a decode/icon fallback and must never replace the crafted name, materials or appearance.
2. **Found ordinary gear** keeps an authored object name and silhouette. A legacy found item does not gain
   fictional component provenance merely because the new crafting system can make a similar object.
3. **Wild/singular gear** keeps its exact authored rule and protected identity. Being unique is not a seventh
   quality band and does not make the item orange by itself.

The six quality bands remain Rough, Standard, Fine, Superior, Exceptional and Peerless. Old Tier 1–4 gear
migrates to Standard/Fine/Superior/Exceptional while exact effective power is preserved as legacy credit.
Old `common/uncommon/rare/mythic` labels disappear from player-facing copy; they cannot coexist with the new
quality vocabulary. No migrated Rough or Peerless item is invented.

## Exact catalogue disposition

The machine authority partitions every current Gear ID exactly once:

- **44 ordinary found items** remain transferable/recyclable authored catalogue identities and may appear
  in campaign-banded ordinary find tables. Their frozen quality is instance data; their names do not imply
  hidden component receipts.
- **8 wild/apex weapons** remain apex-only, protected and non-recyclable. Their special rules are separate
  from quality. Living Hook growth, for example, may not silently recolour the item into another band.
- **12 resource-named found items** have an exact truthful component or fixed-special receipt. Eleven are
  ordinary find candidates; Rift-glass Rapier remains protected/special.
- **11 incoherent placeholders** become decode-only: existing copies remain intact, but new drops, merchant
  stock and authored pages cannot produce them until an exact mechanic/source is designed.

This retirement is deliberate content cleanup, not save deletion. A `Toxin Edge` that already exists keeps
its current power and current transfer rules; the new game simply stops promising that permanent toxin is a
physical blade component when coatings are the actual toxin system.

## Future distribution rules

- Territory finds and generic world loot select only IDs marked eligible by this authority, then apply the
  campaign/danger band table. They never fabricate a component receipt for a legacy object.
- The Trading Post may stock ordinary eligible catalogue gear and exact component-authored found gear. It
  never stocks apex/singular or decode-only items.
- Crafted objects do not enter a random find table merely because their internal catalogue fallback is an
  eligible ordinary ID.
- Peerless ordinary physical gear first comes from Peerless crafting inputs. A later authored Peerless find
  requires an explicit exact item/source addition; the drop system may not promote arbitrary catalogue gear
  to orange on its own.
- Rough found gear may be added later through an explicit damaged-object family. The migration does not
  relabel intact Tier-1 inventory as vendor trash.

## UI and Asset contract

An object tile shows, in priority order: authored/crafted silhouette, quality frame geometry and colour,
small source/status treatment outside the object, then quantity/location. A protected wild object uses a
lock/provenance treatment outside the quality frame; it does not fake Peerless quality.

For component-authored items, the exact receipt in the JSON is also the multipart visual recipe. The
Schematic silhouette stays stable while only those named component regions change. Fixed-found Keepsakes
and Rift-glass Rapier remain exact authored silhouettes, not procedural assemblies.

## Engineering sequence

1. Validate the exact 75-ID partition before changing a save or loot table.
2. Add the six-band instance field and preserve existing effective power through legacy credit.
3. Stop rendering old rarity labels; render the frozen quality band redundantly.
4. Add the 12 exact component/fixed receipts without altering their current live instances yet.
5. Remove the 11 retired IDs from every *new acquisition* table while leaving catalogue decode and existing
   inventory behavior intact.
6. Convert Trading Post, territory-find and generic loot selection to explicit disposition metadata; never
   infer eligibility from name, old rarity or `materialProfileID`.
7. Only after the Pointed Blade fixture is live, allow new crafted items to use their own Schematic/component
   identity rather than the fallback catalogue object.

Acceptance requires: exact 75-ID coverage/no duplicates; old-save round-trip with no loss; no retired ID in
10,000 deterministic new-acquisition selections; no apex ID outside apex rewards; and exact receipt/visual/
Recycler round-trip for all 12 component-authored found items.
