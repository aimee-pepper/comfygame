# Trading Post / Recycler economy and provenance migration

> **Incoming material-domain correction (21 August 2026):** Gold currency, rotating stock, exact atomic
> transactions, outcome refresh and Recycler receipt/capacity behavior remain authoritative. Universal
> material grade, grade-band sale prices, animal parts as World resources, highest-grade Recycler defaults
> and fabricated reclaimed Hide are superseded by `creature-ecology-and-materials-overhaul-current.md`.
> Family/capability price and frozen receipt order replace them when that migration lands.

**Status:** Trading Post and Recycler first rules slices implemented. Prices, stock counts, recovery
fractions and phone interaction remain debug/playtest values; destructive-action and provenance
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
minted currency. Raw Essence and Motes are not Trading Post goods. Refined essence uses only the explicit
currency offer below.

Material samples sell by grade, independent of kind: common 1, uncommon 2, rare 4, mythic 7 gold.
Ordinary non-gear items use authored rarity: common 2, uncommon 5, rare 10, mythic 20. Gear uses
`floor(4 × effectivePower)`, minimum 4. Unique, apex, narrative and legacy-masterwork gear are
excluded rather than receiving a tempting price.

Implement `tradeBand` as tolerant authored resource metadata or a validated versioned table keyed by
`ResourceID`. Do not infer it from catalogue order, rarity colour, pressure value or display name.
Every transferable resource must resolve exactly one band; Raw Essence and Mote resolve an explicit
nontradeable classification. Renaming “Ore” to player-facing “Iron Ore” cannot change price.

Ordinary item transferability likewise needs explicit authored metadata (`transferable`, plus
optional salvage-profile ID). Defaults for old content are conservative: unknown/missing metadata is
sell-ineligible until validated, not silently common and sellable.

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

### Merchant sample identity

A generated material line is an honest **supplier lot**, not a fabricated drop from a named creature,
flora species or visited world. Its frozen `MaterialSample` uses:

- one sample per line and 0–2 distinct kinds per refresh;
- ordinary physical kinds only: plate, quill, pelt, down, hide, chitin, fang, tusk, claw, bone,
  timber, fibre or pulp;
- grade 25–39, keeping it common and useful without becoming rare-world substitution;
- one kind-appropriate primary property at 30–39, one secondary at 15–29 and all other properties
  at 0–14, generated from the Trading Post's isolated versioned refresh RNG;
- `source: "Vance's supplier"` and no invented qualifier.

The primary/secondary pair is authored by kind: plate/chitin/bone/tusk use hardness/density;
fang/claw use hardness/reactivity; quill uses flexibility/hardness; pelt/down use
insulation/flexibility; hide uses flexibility/hardness; timber uses density/hardness; fibre uses
flexibility/insulation; and pulp uses flexibility/reactivity. This table is content authority, not a
rule inferred from enum order.

Ichor, toxin and reagent samples are excluded from ordinary merchant generation; their biological or
specialist origin should remain meaningful. A supplier lot may still satisfy a basic recipe because
merchant stock is intended as a bounded recovery route, but it cannot claim a creature name,
world-derived qualifier or ecology the player never encountered. Buy price is 3 gold for the single
common sample (three times its 1-gold sell price). The complete sample is frozen into the stock line;
purchase never regenerates its properties.

Stock reads only content currently eligible in the save. It never rolls an unknown recipe output,
diary reward, world-only rare/precious material, apex/unique gear, curio or key. Purchase decrements
the persisted quantity atomically; reopening does not reroll. Buy price is at least three times sell.

For this checkpoint, **basic known consumable** means an output in
`knownConsumableRecipes` whose authored catalogue rarity is common or uncommon. Rare/mythic outputs
remain exploration/specialist stock even when their recipes are known. A consumable line carries 1–2
ordinary instances. Its unit buy price is exactly three times its current authored sell value:
6 gold for common and 15 for uncommon. The ordinary tier-1 equipment line likewise uses exactly
three times that exact frozen piece's sell price and quantity one. “At least three times” is the
economic invariant; these exact 3× values are the first playtest profile and belong in DEBUG tuning
before any balance promotion.

### Persisted refresh contract

Add a tolerant optional `TradingPostState` at Home rather than deriving stock every time the view opens:

- `goldCoins` wallet (never name this `gold`, which is already the Gold Ore `ResourceID`);
- stock schema/version, refresh sequence and the expedition outcome ID that produced it;
- exact stock lines with stable line IDs, kind/identity, remaining quantity, unit price and any full
  sample receipt;
- optional essence-offer bundles remaining;
- next deterministic stock instance ID.

Old saves begin with zero gold and no stock snapshot. The first resolved expedition after migration
creates stock; opening the station before that shows an honest empty/awaiting-refresh state and does
not roll. Return, collapse and other recorded expedition outcomes each refresh exactly once after the
outcome is durably committed. Reopening, relaunching, changing the clock or visiting another station
cannot refresh it.

Use a dedicated versioned RNG derived from persistent campaign identity plus refresh sequence. Do not
consume world-generation, combat or current-run RNG, and do not use Swift `Hasher`. Content changes
may alter a future refresh but never mutate the saved current snapshot.

Stock eligibility is snapshotted from permanent knowledge at refresh. Losing or gaining knowledge
afterward does not silently replace lines; a newly learned recipe becomes eligible at the next
refresh. A line holding a material sample stores the complete sample, not instructions to regenerate
one later.

## Selling safety

- Bulk sale may target world-resource stacks or material grade bands only.
- Preview lists exact quantities/samples, gold total, bins removed and remaining storage.
- Equipped, unidentified, locked/favorited, unique/narrative, legacy-masterwork and nontransferable
  objects never enter bulk selection.
- Ordinary eligible gear uses a deliberate single-piece confirmation showing equipped status,
  effective power, provenance and Recycler comparison.
- Sale and gold credit are one saved mutation. Cancel changes nothing.

Safety comes from exact scope and one atomic confirmation, not repeated confirmation per resource.

The current item schema has no favorite/lock flags. Add tolerant per-instance `isFavorite` and
`isLocked` flags to ordinary item stacks/gear before exposing bulk sale. They default false on old
saves and survive storage/equip transfers. “Equipped” remains derived from actual equipped-instance
ownership; never copy an equipped boolean that can become stale. Nontransferable/unique/narrative
eligibility is authored metadata plus the existing unique-rule boundary, not rarity alone.

Sale previews carry a revision token/hash over the exact selected resource quantities,
`(binID, sample index, full sample receipt)` handles or gear stable-instance IDs and their current
prices. Commit revalidates the same objects, eligibility, wallet arithmetic and inventory revision.
Any mismatch returns to preview without partially removing goods or crediting gold. This first slice
does not require adding a global identity field to every historical material sample.

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

Store an authored salvage-profile ID on the item definition (or a versioned table keyed by stable
catalogue ID), not on each found instance. A crafted piece with non-empty `consumedSamples` always
uses its real receipt even when its catalogue fallback also has a salvage profile. A rebuilt found
piece with newly consumed samples recovers only that real appended receipt; it must not receive both
the receipt and the found-base profile in one recycle.

The broad family table is a migration/default authoring aid, not permission to infer salvage at
runtime from slot alone. Every recyclable catalogue item resolves to an explicit validated profile;
otherwise it remains sell-only. Reclaimed organic samples use a dedicated reclaimed source label and
stable deterministic properties authored by profile/version—never random current-world properties.

The first implementation uses an explicit versioned Swift table keyed by stable `ItemID`; it does
not infer from slot at runtime, and current validation reports zero ordinary unprofiled gear. Before
the next ordinary gear catalogue expansion, move `salvageProfileID` onto item metadata and validate
the profile registry from content. This is a dynamic-authority maintenance boundary, not permission
to change current outputs or make missing metadata recyclable by default.

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
7. One expedition outcome produces one stock refresh across force-quit/relaunch; opening the station
   or changing wall time produces none.
8. Gold Ore and `goldCoins` never share a storage field, price lookup or accessibility label.
9. Crafted/rebuilt gear chooses exactly one recovery route: real receipt when present, otherwise an
   explicit found-gear salvage profile.
10. Favorite/locked/equipped protections survive storage and old-save migration, and stale previews
    fail atomically.
