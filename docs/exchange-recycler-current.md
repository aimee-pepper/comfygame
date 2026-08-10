# Exchange and Recycler — current design

**Status:** Current direction with playtest-placeholder prices and recovery rates.  
**Owner:** Vance.  
**Supersedes:** Conflicting class and provenance claims in `merchant-recycler-spec.md`.

## Purpose

The Exchange turns unwanted holdings into flexibility without replacing expeditions. The Recycler
turns unwanted gear into useful making stock without pretending that every found object has a known
recipe. Together they create a real choice between keeping, selling and reclaiming.

Vance is not a separate Trader class. Classes are emergent from shared combat branches; Vance's
calling, diary and station ownership carry the trader identity.

## Gold and exchange boundaries

Gold remains a separate wallet currency, as chosen by Aimee.

| Exchange | Availability | Boundary |
|---|---|---|
| Holdings → gold | Always | Identified, transferable goods only |
| Essence → gold | Always | Intentionally poor rate |
| Gold → essence | Rotating stock only | Capped quantity at an intentionally expensive rate |
| Gold ore → gold | Sell as a high-value world resource | No direct mint action |

Gold ore receives a premium sell value because its economic identity matters, but it does not bypass
the Exchange through a unique refining rule. All rates, premiums and stock caps belong in debug
tuning.

## Stock and refresh

- Stock refreshes when an expedition resolves by return or collapse, never on wall-clock time.
- Buying is limited to common and uncommon staples. It can complete an ordinary recipe but cannot
  substitute for hunting rare, signature or diary-exclusive things.
- Stock may include ordinary world resources, common material samples, basic consumables and a
  capped essence offer. It excludes unique gear, apex weapons, diary rewards, schematics, quest or
  narrative objects and unidentified curios.
- Buy prices exceed sell prices enough that immediate arbitrage is impossible.
- A sold eligible good may enter the current stock only if doing so cannot raise stock beyond its
  rarity and quantity caps. This is optional flavor, not required for v1.

## Selling

The Exchange buys world resources, material samples, ordinary items and ordinary gear. Gear must be
sellable because the intended decision is **gold now versus making stock later**.

Material bins support selling selected samples and bulk selection by grade band. Every bulk action
shows the exact goods, gold total and remaining inventory before confirmation. Equipped, favorited or
locked, unidentified, unique, diary, schematic, quest and narrative objects are excluded by default
and cannot be swept into a bulk sale. A deliberate single-item path may sell an eligible favorite
only after it is unlocked.

Vance's field appraisal may reveal an estimated sale-value band for identified goods. It does not
identify curios, reveal hidden effects or bypass the Storehouse and permanent-knowledge loops.

## Recycler

The Recycler is an Exchange upgrade, not a Blacksmith function.

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

The Recycler never returns gold or essence. Its efficiency improves through the Exchange's own
upgrade path, but remains below 100%; making and unmaking cannot multiply materials.

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
sample-selection behavior are in `exchange-recycler-economy-current.md`.

## Implementation invariants

1. No operation creates gold, essence or materials through a buy/sell/recycle loop.
2. World-only rarity remains world-only; the Exchange relieves shortages but does not replace writing
   and travelling.
3. Identification and permanent knowledge remain separate systems.
4. Every destructive action has an exact preview and confirmation.
5. Old saves tolerate absent `craftProvenance` and salvage profiles; absence never invents provenance.
