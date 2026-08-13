# Trading Post and Recycler — current design

**Status:** Sell-first Trading Post and first Recycler rules slices are implemented. The Trading Post's
buying side is not yet feature-complete: live refreshes contain world resources and occasional Essence,
but the settled material-sample, consumable and ordinary-equipment shelves are still missing. Prices,
recovery rates and phone interaction remain playtest concerns.  
**Owners:** Vance owns the Trading Post; Noll (working name) owns the Recycler.
**Stable station IDs:** `trading_post` and `recycler`.
**Supersedes:** Conflicting class and provenance claims in `merchant-recycler-spec.md`.

## Purpose

The Trading Post turns unwanted holdings into flexibility without replacing expeditions. The Recycler
turns unwanted gear into useful making stock without pretending that every found object has a known
recipe. Together they create a real choice between keeping, selling and reclaiming, but they are
separate stations and separate people from the opening campaign.

Vance is not a separate Trader class. Classes are emergent from shared combat branches; Vance's
calling, diary and Trading Post ownership carry the merchant identity. Noll likewise owns recovery through
identity and station practice, not a Recycler combat class. See
`opening-economy-traveller-reorder-current.md`.

## Gold and trade boundaries

Gold remains a separate wallet currency, as chosen by Aimee.

| Trading Post stock | Availability | Boundary |
|---|---|---|
| Holdings → gold | Always | Identified, transferable goods only |
| Essence → gold | Always | Intentionally poor rate |
| Gold → essence | Rotating stock only | Capped quantity at an intentionally expensive rate |
| Gold ore → gold | Sell as a high-value world resource | No direct mint action |

Gold ore receives a premium sell value because its economic identity matters, but it does not bypass
the Trading Post through a unique refining rule. All rates, premiums and stock caps belong in debug
tuning.

## Stock and refresh

- Stock refreshes when an expedition resolves by return or collapse, never on wall-clock time.
- Buying is limited to common and uncommon staples. It can complete an ordinary recipe but cannot
  substitute for hunting rare, signature or diary-exclusive things.
- Stock may include ordinary world resources, common material samples, basic consumables and a
  capped essence offer. A complete merchant refresh also carries one ordinary tier-1 equipment piece;
  until the party owns any weapon, that equipment line is a weapon. This is a bounded early route, not
  starting gear or a promise of one exact damage kind. It excludes unique gear, apex weapons, diary
  rewards, schematics, quest or narrative objects and unidentified curios.
- Buy prices exceed sell prices enough that immediate arbitrage is impossible.
- A sold eligible good may enter the current stock only if doing so cannot raise stock beyond its
  rarity and quantity caps. This is optional flavor, not required for v1.

### Missing merchant-stock completion checkpoint

The existing `.item` and `.material` stock cases are saved forward-compatible scaffolding, not proof
that these shelves work. Finish them as one contained playability checkpoint:

- add 0–2 common material samples with complete frozen sample receipts;
- add 0–2 basic consumable lines, but only from permanently known recipes/identities;
- add exactly one ordinary tier-1 catalogue equipment line per refresh. Before the campaign owns any
  weapon in storage, overflow or on a person, constrain that line to an ordinary weapon; afterward it
  may use any ordinary tier-1 slot;
- create the purchased object once with a collision-free stable instance ID and its ordinary frozen
  catalogue profile. Do not regenerate its identity when previewing, reopening or committing;
- store the result through the ordinary capacity-safe path, including Waiting overflow, and decrement
  stock plus gold in the same atomic mutation;
- retain the current resource/Essence stock and expedition-outcome refresh cadence.

The weapon constraint is evaluated only when a new stock snapshot is made. Selling, equipping or
losing a weapon cannot rewrite the current shelves. The Trading Post therefore supplies a plausible
early recovery route after Vance is recruited and the station is built, while world/site/loot routes
remain meaningful before then. It does not guarantee a weapon before the first combat-tree point;
early point banking and first-expedition gear availability remain playtest evidence.

Purchase fixtures must cover stable item identity across preview/relaunch, stale-preview no-op,
insufficient gold, full Storehouse spillover without loss, exact sample preservation, recipe-knowledge
eligibility, no weapon-owned refresh versus weapon-owned refresh, and exclusion of unique/apex/
narrative stock. Phone acceptance buys one resource, one sample or consumable and one equipment piece
from the same persisted shelves, then reloads without a reroll or duplicate.

## Selling

The Trading Post buys world resources, material samples, ordinary items and ordinary gear. Gear must be
sellable because the intended decision is **gold now versus making stock later**.

Material bins support selling selected samples and bulk selection by grade band. Every bulk action
shows the exact goods, gold total and remaining inventory before confirmation. Equipped, favorited or
locked, unidentified, unique, diary, schematic, quest and narrative objects are excluded by default
and cannot be swept into a bulk sale. A deliberate single-item path may sell an eligible favorite
only after it is unlocked.

Vance's field appraisal may reveal an estimated sale-value band for identified goods. It does not
identify curios, reveal hidden effects or bypass the Storehouse and permanent-knowledge loops.

## Recycler

The Recycler is its own early station, not a Trading Post upgrade and not a Blacksmith function.

- **Crafted gear:** when gear crafting exists, each crafted instance records a compact immutable
  `craftProvenance` describing the material samples actually consumed. Recycling returns a tunable
  fraction of those inputs, rounded down by sample count. Returned samples keep their recorded kind,
  properties, grade and source; reforging costs and essence are never returned.
- **Found or catalog gear:** current gear has no component provenance. Recycling therefore yields an
  authored **salvage profile**, not alleged original materials. The profile names one or more honest
  material kinds appropriate to the object and generates modest, clearly labelled reclaimed samples
  at a grade capped by the item's rarity/tier. Until a catalog entry has such a profile, that piece is
  sellable but not recyclable.
- **Unique/apex/narrative gear:** not recyclable in v1. This prevents accidental destruction and
  avoids converting singular rule-breaking objects into ordinary stock.
- The result is previewed before confirmation. Recycling is irreversible after confirmation.

The Recycler never returns gold or essence. Its efficiency improves through its own upgrade path,
but remains below 100%; making and unmaking cannot multiply materials.

## Placeholder tuning

- Tier 1 Recycler: recover 40% of eligible crafted samples, rounded down.
- Tier 2: 55%.
- Tier 3: 70%.
- Found-gear salvage profiles return 1–3 samples according to tier and never exceed rare grade in v1.
- Any item whose rounded crafted return is zero shows that result plainly and should normally be sold
  instead.

These values are debug-exposed and playtestable. The structural distinction between real crafted
provenance and authored found-gear salvage is current.

Exact first-slice trade bands, stock counts, currency rates, cumulative rebuild provenance and
sample-selection behavior are in `trading-post-recycler-economy-current.md`.

## Implementation invariants

1. No operation creates gold, essence or materials through a buy/sell/recycle loop.
2. World-only rarity remains world-only; the Trading Post relieves shortages but does not replace writing
   and travelling.
3. Identification and permanent knowledge remain separate systems.
4. Every destructive action has an exact preview and confirmation.
5. Old saves tolerate absent `craftProvenance` and salvage profiles; absence never invents provenance.
