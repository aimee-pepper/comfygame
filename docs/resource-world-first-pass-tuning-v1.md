# Resource, Harvesting, and World Numbers Decided So Far

> **Review status:** This is the complete first-pass tuning proposal for the resource, harvesting, terrain, canopy, and Rubble decisions Aimee has discussed so far. It describes the intended game, not what the current build already does. Nothing on this page should be presented as implemented until its own game slice has shipped and been tested.

This page keeps the proposed values in one place so they can be read and adjusted together. It deliberately stops before the next design subjects: generated creature body plans, the full flora catalogue, Sigil acquisition order, clue progression, complete recipes, processing chains, facility upgrades, and the final parallax-world art catalogue.

## Biological material quality

Creature materials use four quality bands. Mined resources do not use this table: Sand is always Sand, Gold is always Gold, and both remain normal green stacks.

| Biological quality | Display colour | Quality score | Stat multiplier |
|---|---:|---:|---:|
| Poor | White | 0–24 | ×0.75 |
| Common | Green | 25–59 | ×1.00 |
| Rare | Blue | 60–84 | ×1.25 |
| Exceptional | Purple | 85–100 | ×1.50 |

The score comes from the creature and the world that actually produced the part:

> **Quality score = round(75% part expression + 25% source-world Danger).**

The part expression is the rounded average of the two real creature measurements that produced that physical part. Source-world Danger contributes the following value:

| World Danger | Value used in the quality score |
|---:|---:|
| 0 | 20 |
| 1 | 35 |
| 2 | 50 |
| 3 | 65 |
| 4 | 80 |
| 5 | 95 |

Source measurements are clamped to 0–100. The final score is rounded half up once, after the two weighted parts are combined. Species name never changes the band by itself.

Each physical part uses measurements that make sense for that part. Covering and flexibility can describe Hide; covering and insulation can describe Pelt; armour and coverage can describe Scales; hardness and armour can describe Shell or Chitin; mass and skeletal strength can describe Bone; natural-weapon strength and skeletal strength can describe Fang, Claw, Tusk, or Horn. The final creature-generation catalogue still needs its own design pass, so this page does not invent unapproved body parts or species mappings.

## How a selected biological material changes an item

A recipe chooses a material because it is the correct physical family, type, or subtype. Its numerical measurements do **not** make an unrelated material eligible. Once a valid material is selected, its real source measurements and quality change the finished item's concrete statistics.

> **Material contribution = round(role ceiling × source measurement ÷ 100 × quality multiplier).**

Every recipe names which source measurement and finished-item statistic that component uses. The crafting preview shows the final number before anything is spent.

| Component's job in the recipe | Maximum contribution at a source measurement of 100 before quality | Permitted source measurement |
|---|---:|---|
| Primary weapon component | 4 damage | The recipe-named natural weapon, Hardness, or other appropriate attack measurement |
| Primary protective component | 4 Armour | Covering protection, Hardness, or structural Density |
| Secondary damage or protection component | 2 points | The recipe-named supporting measurement |
| Grip, binding, or other handling component | 2 Initiative | Flexibility or lightness, only where the finished item already supports Initiative |
| Insulating layer | 20 ward points | Insulation against the exact supported damage type |
| Valuable visible finish | +30% sale value | Lustre, only where that item can visibly use the finish |
| Reactive component | 2 potency steps | Reactivity, only for a recipe with an existing named reactive effect |

These are per-role ceilings, not extra recipe requirements. A finished item cannot receive a made-up statistic merely because a material has a high value. Mined materials have fixed, recipe-authored contributions and no quality multiplier.

### Finished crafted quality

Quality-bearing primary sockets share 70% of the result score. Quality-bearing secondary sockets share 30%. Within each group, average the input band ranks, combine the two weighted group averages, and round half up:

| Rounded result | Finished quality name |
|---:|---|
| 0 | Rough |
| 1 | Fine |
| 2 | Superior |
| 3 | Exceptional |

Poor, Common, Rare, and Exceptional have ranks 0, 1, 2, and 3 respectively. If a recipe has only primary or only secondary quality-bearing sockets, that present group supplies the whole score. Mined and other quality-free ingredients do not vote in the calculation. A recipe with no quality-bearing ingredient uses its fixed authored result.

At a maximum level-3 facility, a craft using only Rare or Exceptional quality-bearing inputs has a 3% chance to become Peerless. The chance is 5% when the matching specialist is staffing that facility. The twentieth consecutive eligible craft is guaranteed to be Peerless; any Peerless result resets that facility's counter. Peerless remains a finished-equipment quality, never a raw-material quality.

## Mined and gathered world materials

Every mined or hand-gathered geological material is one exact named normal/green stack. It has no Poor, Rare, species, or source-world variant. Source history can still say where the player found it, but that history never fragments the stack or changes its strength.

| Access | Initial material groups | Yield from one placement |
|---|---|---:|
| Hand gathering | Sand, Clay, Gravel, Salt crust, Ochre | 2 units, then depleted |
| Pick level 1 · Rock Pick | Rubble; Granite, Limestone, Sandstone, Slate; Iron, Copper, Tin; Coal | Common node: 3 pulls of 2 units |
| Pick level 2 | Basalt, Marble, Quartz; Silver, Gold, Mercury; Sulfur, Alum, Saltpeter | Uncommon node: 2 pulls of 2 units |
| Pick level 3 | Obsidian, Adamant, Rift-glass | Rare node: 2 pulls of 1 unit |

The individual recipes for tools, processing, and finished items are intentionally not set on this page. Those belong to the later recipe and facility pass.

## Geological placement in a generated world

Each world receives a mineral-node budget of:

> **max(3, round(passable land tiles ÷ 28)).**

Each ordinary node slot chooses only among materials supported by its resolved region. The starting rarity weights are 70% common, 25% uncommon, and 5% rare.

If the player's writing directly names a ground or mined resource, the world guarantees one eligible, start-connected source between 3 and 8 movement steps from entry. That source counts against the ordinary node budget and keeps its ordinary yield; it is not a bonus cache.

An advanced node may exist before the player owns the required Pick. Look names the required Pick level. Trying the wrong or insufficient tool costs no turn and does not reduce the node.

## World sizes

| Generated size | Starting weight | Player-facing scale |
|---|---:|---|
| 12×12 | 10% | Small |
| 15×15 | 25% | Compact |
| 18×18 | 40% | Ordinary |
| 26×26 | 20% | Large |
| 36×36 | 5% | Vast; exactly four times the area of an 18×18 world |

These are generation weights before an explicit written size pressure modifies the result.

## Regional arrangements

Arrangement controls the large-scale shape of the land. It is separate from which actual ground, water, weather, plants, resources, creatures, and sites fill the world.

| Arrangement | Starting weight | Concrete starting rule |
|---|---:|---|
| Homogeneous | 10% | Exactly one ground composition throughout |
| Dominant | 30% | Two ground types on 12×12 and 15×15 worlds; three on larger worlds. The main type fills 75%. |
| Banded | 15% | 2, 2, 3, 4, or 5 bands across the five world sizes. Every band is at least 3 tiles wide. |
| Patchwork | 15% | 3, 4, 5, 7, or 9 patches across the five world sizes. |
| Clustered | 15% | 2, 2, 3, 4, or 5 major clusters across the five world sizes. |
| Gradient | 10% | Two endpoint ground types with 3, 3, 4, 6, or 8 transition bands across the five world sizes. |
| Fractured | 5% | 2, 2, 3, 4, or 5 regions across the five world sizes, divided by one-tile breaks on the first three sizes and one-to-two-tile breaks on the last two. |

Every arrangement must still produce a start-connected playable world. Impossible environmental combinations are resolved by the relevant pressures; they do not cause the entire world to be rejected.

## Harvesting controls and turn costs

Holding the centre of the movement arrows opens quick-use or Field Kit items. Holding Interact opens the field-tool selector. Both holds use a 0.40-second threshold.

Opening either menu, choosing or changing a tool, cancelling, selecting the wrong tool, lacking the required level, targeting something that moved, encountering stale state, or failing custody costs 0 turns and changes nothing. Every successful harvest hit costs exactly 1 world turn.

The active field tool persists between expeditions and through a cold relaunch until the player changes it or no longer owns it. Underfoot passable plants use Interact. An adjacent blocking trunk uses the movement direction facing that trunk. Ordinary movement never harvests a plant accidentally.

| Harvestable placement | Required tool | Successful work and yield |
|---|---|---|
| Low or groundcover plant | Scythe level 1 | 1 hit · 1 unit |
| Medium ordinary plant | Scythe level 1 | 1 hit · 2 units |
| Tall or tough ordinary plant | Scythe level 2 | 1 hit · 3 units |
| Explicitly dangerous harvestable plant | Scythe level 3 | 1 hit · 4 units; its separately disclosed danger still applies |
| Small softwood trunk | Axe level 1 | 1 hit · 2 Logs |
| Mature softwood or small hardwood trunk | Axe level 2 | 2 hits · 5 Logs total |
| Large hardwood, dense, or resinous trunk | Axe level 3 | 3 hits · 9 Logs total |

Multiple-hit trees save their completed hits. Leaving, returning, backgrounding, or relaunching cannot restore work already completed or grant the yield twice.

## Canopy and discovery

| Tree size | Saved crown footprint |
|---|---|
| Small | Five-tile cross |
| Mature | 3×3 square · 9 tiles |
| Large | Radius-two diamond · 13 tiles |

A sight line can pass through one canopy tile. A second consecutive canopy tile conceals tiles beyond it. While the party is beneath a canopy, its own tile and the eight adjacent tiles are shown in full before that same rule continues outward.

The final successful Axe hit removes only that trunk's own crown footprint. An overlapping crown from another standing tree remains.

Once a feature has been fully revealed, its normal minimap record remains revealed permanently. Canopy may later cover it in the main world view, but cannot restore fog or erase a known resource, creature, site, hazard, or portal marker.

## Aquatic and flying habitat boundaries

Both shallow and deep water support aquatic creatures. Shore and shallow water can also support amphibious or crocodile-like creatures when their generated body plan supports movement between water and land. Flying creatures may cross ground and water; they do not receive a universal perch requirement. Their actual food, nesting, weather, and body-plan relationships belong to the upcoming creature-generation pass.

## Sorting Rubble at Noll's Recycler

Rubble is one ungraded normal/green inventory stack, but each unit retains its hidden source-region batch so the Recycler can return only materials that truly existed there.

| Rule | First-pass value |
|---|---|
| Input | 4 Rubble from one retained source-region batch |
| Access | Recycler level 1, the initially built Recycler |
| Additional cost | 0 Essence and no world turn |
| Base output | 2 mined-material units |
| First unit | 100% common local material |
| Second unit | 75% common local material; 25% uncommon local material |
| Rare bonus | 5% chance for one additional rare local material |

If the source region has no uncommon material, the second unit is common. If it has no rare material, the bonus cannot occur. The common, uncommon, and rare pools contain only materials in that exact source-region receipt.

The ordinary inventory still shows one Rubble stack. Inside the Recycler, retained batches are grouped by source world. The oldest eligible batch is selected by default, and the player may choose another before opening the preview.

The preview freezes the result for those four exact units. Confirming consumes exactly four Rubble and grants the previewed materials exactly once. Cancelling, refusing, backgrounding, or relaunching never rerolls the preview. A full destination, stale stock, changed batch, or failed save spends nothing and grants nothing.

## What remains for the next design passes

The following subjects are intentionally not filled with guessed numbers here:

- generated creature body plans, body-part availability, species ecology, encounter makeup, and creature-to-drop quantities;
- which flora-derived materials, if any, need quality bands;
- complete flora species and harvest catalogues beyond the size-and-tool rules above;
- Sigil acquisition order, teachable land vocabulary, and clue progression;
- every recipe's exact ingredients, output statistics, price, station tier, and unlock;
- processing conversions other than Rubble sorting;
- tool acquisition and upgrade recipes;
- the full compatibility matrix for combined environmental pressures; and
- final parallax-world visual assets and geometry.

Those are separate conversations. Adding numbers for them here would make this page look complete by quietly deciding systems Aimee has not covered yet.
