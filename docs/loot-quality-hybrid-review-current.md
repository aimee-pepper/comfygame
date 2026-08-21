# Material identity + six-band loot quality — review candidate

**Status:** Historical first recommendation, superseded for current review by
`crafting-intuition-and-quality-review-current.md`; not implementation authority.
Engineering must not remove the legacy grade field or migrate current material/gear power until this choice
is accepted. Ecology families, habitats and storage-domain work may be designed independently.
**Question preserved for history:** Should family/material identity and a discrete six-band loot-quality
system replace continuous sample grade and the current overlapping gear rarity/construction-tier presentation?
**Updated:** 21 August 2026

## Recommendation

Use both systems, but make them answer different questions:

1. **Material/family identity answers “what can this do?”** Adamant is intrinsically hard and dense; Gold is
   lustrous and workable; Pelt insulates; Feather is light and flexible; Plate is hard and dense.
2. **Quality band answers “how good is this particular yield or object?”** It changes value and the strength
   available within that material's real capability range.
3. **Gear item level answers “how powerful is this finished object?”** Found gear freezes an authored item
   level. Crafted gear derives item level from recipe baseline, selected material quality and maker cap. Its
   frame colour is derived from that item level/quality band; colour is not a second random rarity roll.

This hybrid is stronger than either extreme. A material-only system makes every piece of Gold or every Pelt
interchangeable and removes exciting drops. A quality-only system makes material identity cosmetic and can
produce nonsense such as a high-colour Hide serving every role better than Adamant. The hybrid preserves
both target hunting and loot excitement.

## Six global bands

Use one stable ordinal `qualityBand` from 0 through 5. Recommended initial player labels and colours:

| Rank | Colour | Label | Redundant frame cue |
|---:|---|---|---|
| 0 | grey | Rough | plain broken-corner frame |
| 1 | white | Standard | plain complete frame |
| 2 | green | Fine | one lower notch |
| 3 | blue | Superior | two lower notches |
| 4 | purple | Exceptional | three lower notches |
| 5 | orange | Peerless | four notches + crown cap |

Names are deliberately usable for ore, creature parts and gear. Do not use Common/Uncommon/Rare as a
second player-facing classification. Existing catalogue rarity may remain an internal drop/stock-authorship
flag during migration, but the object tile has one quality colour/frame only.

Colour is redundant with the label and frame cue. Quality is never communicated by hue alone.

## What receives quality

Quality applies to:

- property-bearing world materials such as Timber, Fibre and Pulp;
- bulk harvestable resources where variation makes physical sense, including ore, minerals, resin and
  similar crafting stock;
- Creature materials;
- ordinary found and crafted gear;
- ordinary consumable ingredients if their recipes actually read ingredient quality later.

Quality does **not** apply to:

- Gold Coins, Raw Essence, refined Essence or Motes, which are currencies/currency precursors;
- Diary Pages, World Pages, runes, keys, quest objects or other authored knowledge/narrative identities;
- unique trophies whose exact authored receipt already defines their power;
- a finished consumable unless a real potency rule consumes quality. Do not colour Salves orange merely
  because an ingredient was orange when every Salve has the same effect.

## Stack identity and provenance

Resource stack identity is exactly:

```text
domain + familyID/resourceID + qualityBand
```

Thus Fine Gold stacks with Fine Gold, and Superior Pelt stacks with Superior Pelt. Fine and Superior never
merge. Different source creatures/worlds may contribute to the same stack.

Exact per-unit provenance is removed from ordinary fungible resource inventory. Instead:

- Bestiary remembers which species yielded each discovered Creature-material family/band;
- World History remembers which worlds yielded each World-resource family/band;
- stack detail may say `Known sources: 3 species · 2 worlds` and open those records;
- an object whose exact source matters to a quest, special recipe or story is an exact Trophy/Item, not a
  fungible resource stack.

This is the deliberate UX price of useful stacking. Engineering must not pretend to retain exact per-unit
source after merging and then choose an arbitrary source when one unit is consumed.

## Material capability ranges

Each material family owns an authored lower and upper value for the six current physical capabilities:
hardness, density, insulation, flexibility, lustre and reactivity. Quality chooses a deterministic point
inside that family's range:

```text
capability(family, band) = lower + (upper - lower) × band / 5
```

Round only at the presentation boundary. A family with capability `0...0` never gains that capability from
quality. Quality therefore strengthens what the material already is; it does not erase material identity.

Examples of the required ordering, not yet the complete balance table:

- Gold's maximum hardness remains below Adamant's minimum hardness;
- Adamant's maximum lustre may remain below Gold's useful lustre range;
- Pelt's insulation/flexibility range exceeds Plate's, while Plate's hardness/density range exceeds Pelt's;
- Feather never becomes a dense maul head at Peerless quality;
- Peerless Hide may be extremely flexible/insulating but cannot satisfy an Adamant-family-only recipe.

Recipes may require a named family, one or more capability floors, or both. They never require only a colour.

## Quality generation

Quality is frozen at the moment the yield/object is created and never rerolls on inspection, relaunch,
transfer or stacking.

### World resources

The source owns one deterministic `sourceQualityScore` from 0 through 100, resolved from actual world facts:

- 60% authored/resolved source richness or relevant pressure strength;
- 25% site/node concentration and danger class;
- 15% isolated deterministic yield roll salted by bound world seed + stable node ID.

Map score to bands: 0–19 Rough, 20–44 Standard, 45–64 Fine, 65–79 Superior, 80–92 Exceptional, 93–100
Peerless. Starter Pages cap ordinary resource nodes at Fine. Known authored exceptional sites may raise the
cap explicitly. An undefined/open world can still roll any band permitted by its campaign/danger cap.

### Creature materials

Family comes entirely from persisted morphology. Quality score uses:

- 70% strength/completeness of the exact producing anatomy;
- 20% creature size or relevant body investment;
- 10% isolated deterministic specimen roll.

The same score bands apply. Different parts from one creature may have different bands because a creature
can have an exceptional pelt but ordinary bone. Identical frozen specimen traits and seed produce identical
results after relaunch. Quality never changes which family the body yields.

### Found gear

Found gear quality is authored or source-banded, never rolled again when identified. Ordinary creature
territory gear uses the encounter's permitted campaign/danger range. Sites and authored rewards may declare
their own minimum/maximum. Unique/apex rules remain explicit and do not infer “orange” from uniqueness.

## Crafting and gear item level

Migrate the current four construction tiers into the middle four global bands:

| Current construction tier | New quality band |
|---:|---|
| 1 | Standard / white |
| 2 | Fine / green |
| 3 | Superior / blue |
| 4 | Exceptional / purple |

Rough/grey is below current Tier 1 and is valid for damaged-looking starter/found work or an intentionally
poor craft. Peerless/orange is above current Tier 4 and remains unavailable to ordinary station processes
until a real late masterwork route is designed.

For a recipe consuming quality ranks `q`:

```text
inputQuality = floor(0.6 × minimum(q) + 0.4 × average(q))
outputQuality = min(inputQuality, makerQualityCap, recipeQualityCap)
```

The preview shows every selected stack, `inputQuality`, maker cap and exact output band. Default selection
uses the lowest qualifying family/capability and then lowest quality band, preserving better stock. The
player may replace selections explicitly.

Initial maker caps preserve the settled hierarchy:

- Blacksmith and Tannery opening process: Standard; improvement: Fine;
- Bowyer, Weaponsmith and Armoury opening specialist process: Superior; masterwork improvement: Exceptional;
- Peerless requires a later explicit masterwork source and is not silently granted by station tier.

Material family/capabilities determine recipe eligibility and frozen secondary effects such as insulation.
Output quality determines the base item-level band. Recipe baseline and slot/profile still determine what
the item does; reforge rank remains a within-band improvement and cannot promote quality without a separate
authored quality-upgrade transaction.

The first combat conversion should map the existing Tier 1–4 power values exactly to Standard–Exceptional,
so migration changes presentation and future input resolution without altering already-owned gear power.
Rough and Peerless power values require isolated balance fixtures before they enter ordinary drop tables.

## Exact existing-consumer mapping if accepted

- **Trading Post:** use family/item `baseValue × quality multiplier`; exact repurchase remains strictly higher.
- **Recipe eligibility:** read family plus derived capability values. Default consumes the lowest qualifying
  band, then stable stack key; one stack quantity may supply several units only when enough count exists.
- **Distillery:** use the derived capabilities of the selected family/band. Heat potency is
  `round(0.65 × reactivity + 0.35 × insulation)`; Caustic is `round(reactivity)`; Light is
  `round(0.65 × lustre + 0.35 × hardness)`. Clamp 0–100.
- **Scent Mask:** one Reagent plus one Hide, Pelt, Down or Oil of any quality. Quality is consumed and
  retained in the item receipt but does not change the fixed first-slice duration/effect.
- **Instrument upgrades and reforging:** use the one authored working capability and choose the lowest
  qualifying band by default. Quality adds no unrelated bonus.
- **Recycler:** constructed gear freezes consumed domain/family/band/count receipt entries. Recovery capacity
  is unchanged; default checks first receipt entries in construction order and the player may change them.
  Catalogue salvage never fabricates a Creature-material source.
- **Storehouse/Return:** render one tile per domain/family/band with count. Different bands never merge; source
  links open Bestiary/World History and do not pretend one merged unit has exact provenance.
- **Failure retention:** partition counts per exact stack key with the current deterministic outcome-wide
  apportionment. It never promotes/demotes quality to make totals fit.

## Value

Every tradable family/item has an authored `baseValue`. Recommended quality multipliers are:

| Band | Multiplier |
|---|---:|
| Rough | 0.5× |
| Standard | 1.0× |
| Fine | 1.5× |
| Superior | 2.25× |
| Exceptional | 3.5× |
| Peerless | 5.0× |

`sell = max(1, floor(baseValue × multiplier))`. A merchant's purchase price for the same exact stack unit is
always strictly greater than its sale price. Base value is where Adamant, Gold, Hide and Feather differ;
quality multiplies that identity rather than replacing it.

## Rare ordinary-animal gear

Ordinary animal encounters receive one **3% roll per victorious encounter**, not per creature. Success adds
at most one eligible ordinary gear item from the encounter's campaign/danger band, described as recovered
from the creature's territory or traces—not as body material. It cannot produce a key, quest object,
authored unique, apex weapon or gear above the current source cap. There is no pity timer in the first
slice; the DEBUG World/Encounter tools report the roll and source table.

Body-derived Creature materials always resolve independently. A Teeming encounter does not multiply gear
rolls merely because it contains more animals.

## Migration implications

If accepted:

1. convert every legacy material grade to the nearest quality band once, preserving count;
2. merge units sharing domain + family + band and move source identities into Bestiary/World-History source
   records;
3. migrate existing gear construction Tier 1–4 to Standard–Exceptional with identical frozen power;
4. remove the old player-facing catalogue rarity colour to avoid two colour hierarchies;
5. update Trading Post, crafting, Recycler, Distillery, Scent Mask, Instrument and reforge consumers against
   discrete family/band stacks;
6. preserve old saves when lossless; otherwise use the visible newest-save-version boundary already settled.

## Decision comparison

| Model | Strength | Main cost |
|---|---|---|
| Material only | very causal; simple | repeated finds lack excitement; less value variation |
| Quality only | familiar loot dopamine; easy value ladder | material names become cosmetic; nonsense substitutions |
| **Hybrid — recommended** | distinct targets plus exciting drops; stackable; supports crafting | needs one careful family capability table and one migration |

## Decision needed

Accept or revise the hybrid before Engineering implements the material-domain migration. The firm ecology
corrections—habitat, body-derived families, separate storage category and rare territory gear—do not depend
on choosing the final quality formula, but storage keys and crafting migration do.
