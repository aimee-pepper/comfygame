# Creature territory finds — current recommendation

**Status:** implementation-complete Game Design recommendation; exact frequency awaits Aimee's Homework
choice before gameplay implementation
**Scope:** rare gear, consumable and ordinary-key objects recovered after an ordinary generated-creature
encounter
**Not creature remains:** body-derived Creature materials resolve separately and remain guaranteed by anatomy
**Updated:** 21 August 2026

## Player promise

Animals do not inexplicably carry swords and keys. Very occasionally, an ordinary creature encounter leads
the party to an object in its territory: a torn pack in a den, something caught in shore wrack, a cache in
silt or a useful object woven into a high nest.

This is a small surprise channel, not a progression dependency. Ordinary gear still primarily comes from
sites, the Trading Post, crafting and authored rewards. Cache keys still primarily come from ordinary cache
content. Creature materials always come from the creature's visible body.

## One exact roll

After victory over an eligible ordinary generated-creature encounter, resolve exactly one frozen
`TerritoryFindReceipt`:

```text
TerritoryFindReceipt {
  tableVersion
  expeditionOutcomeID
  encounterStableID
  rollBasisPoints
  resultCategory       // none | gear | consumable | cacheKey
  selectedItemID?
  sourceBand
  traceID?
}
```

The recommended initial table uses one 0–9,999 basis-point roll:

| Range | Result | Absolute chance |
|---:|---|---:|
| 0–299 | eligible ordinary gear | 3.0% |
| 300–449 | eligible consumable | 1.5% |
| 450–499 | one ordinary Cache Key | 0.5% |
| 500–9,999 | no territory find | 95.0% |

This is equivalently a 5% find chance followed by category weights 60:30:10. At most one object appears.
Teeming, party size, number of defeated creatures and material yield never add rolls.

The roll is derived from the expedition outcome, encounter stable identity and table version, then frozen
before the reward is shown. Relaunch, recap dismissal and encounter reconstruction cannot reroll it. If the
selected category has no eligible candidate, the result is `none`; do not fall through to another category.

There is no pity timer in the first slice. No essential item uses this route, and DEBUG can force each range
for testing. If playtesting shows the feature is functionally invisible, tune the four ranges as one table;
do not add hidden per-creature rolls.

## Eligible encounter boundary

The encounter qualifies only when all of these are true:

1. it is a generated ordinary-creature encounter;
2. its reward is being concluded as a victory for the first time;
3. it is not an apex, authored guardian, traveller meeting, hostile-flora-only contact or story encounter;
4. it has not already frozen a territory-find receipt.

An encounter containing an apex or authored guardian uses that encounter's explicit reward route and gets no
ordinary territory roll. Hostile flora produces its authored flora/world yield, not animal territory loot.
Defeat, escape or an interrupted/unconcluded encounter awards nothing and preserves no claim to reroll.

## Explicit catalogue disposition

Eligibility is authored data. Never infer it from an item's name, colour, rarity string, price or broad
`kind` alone.

```text
TerritoryFindProfile {
  disposition          // eligible | excluded
  minSourceBand
  maxSourceBand
  selectionWeight
  traceCompatibility   // ordinary | dryOnly | shoreOrWater | aerial
}
```

Every gear, consumable and key definition must declare a disposition before this system ships. Missing or
unknown data fails closed and is a content-validation error. Selection is weighted only among entries whose
source-band and trace compatibility pass. Stable item ID breaks equal-weight ties.

### Gear

- Eligible: explicitly ordinary, non-singular found gear assigned to the current encounter source band.
- Excluded: authored uniques, apex weapons, Channelworks singular objects, quest/story objects, Keepsakes
  whose identity implies a named owner, and anything above the source cap.
- Current catalogue `mythic` named gear is excluded unless a later entry is individually re-authored as an
  ordinary territory find. Mythic colour alone never grants eligibility.
- The selected exact item freezes its authored/found quality band and instance identity. It is never rolled
  again on identification or return.
- After material-responsive found gear exists, its explicit found-component receipt is generated once from
  the same source band. The system must not invent a construction receipt or imply that the creature was
  crafted into the object.

### Consumables

The first table is exact and campaign-banded:

| Minimum source band | Eligible IDs |
|---:|---|
| 0 | `salve_lesser`, `scent_mask`, `torch` |
| 1 | `salve`, `draught_clearing`, `draught_quenching`, `stonebark_tonic`, `venom`, `firebrand`, `briar_oil`, `flashsalt`, `solvent`, `lure` |
| 2 | `salve_greater`, `antidote_broad`, `stillwater`, `farsight_draught` |

`seamlight` joins at minimum source band 1 only after that item is live. Finding a consumable does not teach
its recipe; the player may use the found item normally. `waystone` is excluded because rare automatic full
extraction would undercut the escape economy. Unknown future consumables remain excluded until authored.

### Keys

The only eligible key is `cache_key`, at every source band. It opens an ordinary cache in a later world and
is not tied to this animal or world. `anchor_frame`, story keys, quest objects, traveller objects and future
unique lock identities are always excluded.

## Territory trace and presentation

The reward card says **Found nearby**, never **Dropped**, and uses one deterministic habitat-compatible trace:

| Habitat | Trace IDs and plain copy |
|---|---|
| terrestrial | `den_pack` — *Recovered from a torn pack in the den.*; `dragged_scrap` — *Found among objects dragged into the territory.* |
| shore | `wrack_line` — *Recovered from the wrack at the edge of the territory.*; `mud_pack` — *Found in a pack half-buried in shore mud.* |
| aquatic | `silt_cache` — *Recovered from a cache lodged in the silt.*; `waterlogged_pack` — *Found in a waterlogged pack caught nearby.* |
| aerial | `high_nest` — *Recovered from debris woven into a high nest.*; `ledge_pack` — *Found in a pack caught on the creature's ledge.* |

Trace choice is visual/provenance flavour only and never changes the item roll. Use the encounter's persisted
habitat. If a legacy encounter has no habitat identity, use neutral copy: *Found among traces in the
creature's territory.* Never claim an aquatic animal swallowed armour, that a key grew from a corpse, or
that a territory object is a body-derived material.

The expedition return receipt keeps the object under **Loot**, separate from **Creature materials**, and
retains its trace copy. Creature materials aggregate by family+quality; territory objects retain exact item
identity.

## Capacity and failure behavior

Territory finds are Items and use ordinary carried-item capacity. They do not bypass the Field Kit or become
slot-free merely because an animal encounter found them.

- If capacity exists, place the exact item in carried loot.
- If capacity is full, use the existing explicit keep/swap/leave transaction. Never silently discard it or
  move it Home during an expedition.
- The decision is atomic; interruption or stale selection leaves both the old carried item and find
  unchanged until the player resolves or explicitly leaves it.
- Once kept, expedition failure/return uses the same loss and persistence rules as any item of that class.

## Economy and disclosure

- The object uses its normal Trading Post, Recycler, equip/use and identification rules.
- It is not marked as creature-made and receives no special sale multiplier.
- A Cache Key remains identifiable as a Cache Key; this route does not revive unidentified generic keys.
- The roll never reveals remote sites, caches, portals, species, resources or map tiles.
- DEBUG shows eligibility, basis-point roll, category, candidate set, selected ID, source band and trace. The
  ordinary UI shows only a successful find.

## Acceptance

1. Zero, one and many defeated ordinary creatures each produce at most one roll per victorious encounter.
2. Teeming does not multiply the roll, while body-derived material quantities remain independent.
3. Reload before or after reward resolution cannot change roll/category/item/trace.
4. Apex, guardian, hostile-flora, story, defeat and escape fixtures never use the table.
5. Exact boundary rolls 299/300/449/450/499/500 select the four intended outcomes.
6. Empty candidate sets fail to `none` without category fallthrough or mutation.
7. Every catalogue gear/consumable/key has an explicit validated disposition; all prohibited identities are
   excluded.
8. Consumable discovery does not teach a recipe; Cache Key never becomes a story/anchor key.
9. Full-capacity keep/swap/leave and relaunch are atomic and lossless.
10. Recap and history call the result **Found nearby**, preserve truthful habitat trace, and keep it separate
    from Creature materials.
