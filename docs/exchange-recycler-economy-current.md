# Exchange / Recycler economy and provenance migration

**Status:** Implementation-facing first-slice economy under `exchange-recycler-current.md`. Prices,
stock counts and recovery fractions are debug/playtest values; destructive-action and provenance
boundaries are current.

## Authored trade bands

World resources receive an authored `tradeBand`; do not infer Home price from one world's abundance
or pressure values.

| Band | Sell / unit | Buy / unit | Current resources |
|---|---:|---:|---|
| Staple | 1 gold | 3 gold | Rubble, Clay, Iron Ore, Salt, Fibre, Timber, Pulp, Resin |
| Uncommon | 2 gold | 6 gold | Copper, Quartz, Obsidian, Sulfur, Toxin, Spore, Reagent |
| Rare | 5 gold | not ordinary stock | Silver, Mercury, Ichor, Rift-glass |
| Precious | 12 gold | never ordinary stock | Gold, Adamant |

Gold's premium is deliberate economic identity; Adamant shares the sell band without becoming
minted currency. Raw Essence and Motes are not Exchange goods. Refined essence uses only the explicit
currency offer below.

Material samples sell by grade, independent of kind: common 1, uncommon 2, rare 4, mythic 7 gold.
Ordinary non-gear items use authored rarity: common 2, uncommon 5, rare 10, mythic 20. Gear uses
`floor(4 × effectivePower)`, minimum 4. Unique, apex, narrative and legacy-masterwork gear are
excluded rather than receiving a tempting price.

## Currency door

- **Sell essence:** 10 refined essence → 1 gold, in positive multiples of ten.
- **Buy essence offer:** 10 refined essence for 8 gold, stock 1–3 bundles when rolled.

The same essence cannot cycle profitably. Rates are intentionally harsh because this is emergency
flexibility, not the research-income loop. Home discounts do not apply to conversion or stock.

## Expedition-refreshed stock

Each resolved expedition generates one persisted snapshot until the next resolution:

- 3–5 distinct Staple resources, 3–8 units each;
- 0–2 Uncommon resources, 1–3 units each;
- 0–2 common material samples with complete properties/grade;
- 0–2 basic known consumables, 1–2 each;
- 35% chance of the capped essence offer.

Stock reads only content currently eligible in the save. It never rolls an unknown recipe output,
diary reward, world-only rare/precious material, apex/unique gear, curio or key. Purchase decrements
the persisted quantity atomically; reopening does not reroll. Buy price is at least three times sell.

## Selling safety

- Bulk sale may target world-resource stacks or material grade bands only.
- Preview lists exact quantities/samples, gold total, bins removed and remaining storage.
- Equipped, unidentified, locked/favorited, unique/narrative, legacy-masterwork and nontransferable
  objects never enter bulk selection.
- Ordinary eligible gear uses a deliberate single-piece confirmation showing equipped status,
  effective power, provenance and Recycler comparison.
- Sale and gold credit are one saved mutation. Cancel changes nothing.

Safety comes from exact scope and one atomic confirmation, not repeated confirmation per resource.

## Recycler provenance

### Cumulative construction receipt

`consumedSamples` is the recoverable construction receipt:

- new crafted piece: exact construction samples;
- reforge: receipt unchanged; reforge stock/essence are never recoverable;
- specialist rebuild of crafted gear: prior receipt plus new construction samples;
- specialist rebuild of found/catalog gear: only new samples; the old base is nonrecoverable legacy
  structure, never reverse-engineered into invented samples;
- apex/unique/Channelworks: ordinary Recycler ineligible.

The receipt round-trips through equipment, saves and profile/name changes. Recycling consumes it.

### Recovery count and choice

For receipts with at least two samples, recovery capacity is:

`max(1, floor(eligible sample count × efficiency))`

Efficiencies remain 40/55/70% at Recycler tiers 1/2/3. Zero/one-sample exceptional receipts show
their exact authored result rather than manufacturing a sample.

The player chooses which recorded samples to recover up to that count; default selection favors
highest grade, then the sample central to the recipe's primary requirement. Returned samples retain
exact kind, properties, grade, source and qualifier. A cumulative rebuild receipt is one pool; no
sample returns twice. Recycling deletes gear and receipt atomically.

### Found-gear salvage

Found gear without real provenance uses an authored salvage profile. It returns 1/2/3 clearly
labelled **reclaimed outputs** for construction tiers 1–2 / 3 / 4. A profile may return a world
resource when the object is visibly mineral/forged, or a material sample when it is visibly organic;
do not turn an iron shield into a fictional creature plate merely to keep one output type. Reclaimed
samples are capped at rare grade. Their properties fit visible construction but never copy a
creature/world source. Reclaimed world resources retain only their ordinary resource identity. No
profile means sellable but not recyclable.

Current ordinary catalogue families use these reversible profiles:

| Visible construction family | Reclaimed sequence at tiers 1–2 / 3 / 4 |
|---|---|
| Blade, awl, edge, maul or mace | Iron Ore / + Timber / + Iron Ore |
| Pick or other headed tool | Iron Ore / + Timber / + Iron Ore |
| Spear or long haft | Timber / + Iron Ore / + Fibre |
| Board, buckler or tower guard | Timber / + Iron Ore / + Fibre |
| Helm, rigid guard, plate or gauntlet | Iron Ore / + Fibre / + Iron Ore |
| Padded or wrapped protective gear | Fibre / + Hide sample / + Fibre |
| Boots and longstrider gear | Fibre / + Hide sample / + Timber |
| Paper, leaf or ring-like keepsake | Pulp / + Fibre / + Quartz |

Read a row cumulatively: a tier-3 item returns its first two outputs; a tier-4 item returns all three.
Tier-1 and tier-2 both return only the first output. If an item's visible authored description
contradicts its broad slot family, its item-level profile wins. The eight apex-rule weapons,
Channelworks objects, narrative keys and legacy masterworks remain ineligible; mythic rarity alone
does not make an otherwise ordinary catalogue family unique.

## Anti-loop verification

1. Immediate sell → buy and buy → sell strictly loses gold.
2. Essence conversion cannot increase either currency through any finite cycle.
3. Craft → recycle loses at least one construction sample, or an exceptional one-sample recipe loses
   all essence and grants no extra material.
4. Reforge stock never enters the receipt; rebuild appends only actual construction samples.
5. Found/legacy gear gains no fabricated provenance; legacy-masterworks are protected.
6. Bulk preview and committed mutation contain identical objects/amounts under interruption.
