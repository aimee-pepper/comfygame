# Crafting overhaul, shop by shop

Updated 5 September 2026. This is the complete crafting review you requested, beginning with Apothecary, Blacksmith and Tannery. **Current behavior** means existing rules or reported delivered changes. **Decided intended behavior** means the agreed destination. **Proposals** are the whole-shop recipe and balance changes still being worked out; they are not already playable.

## What the review found

The early sequence is coherent: stone tools, useful raw-material equipment, ingots at Blacksmith T2, then cloth, leather and specialist components. The later recipes still contain older rules that do not fit that sequence. The Apothecary now has a complete first-pass recipe-and-source plan; implementation remains pending. Blacksmith, Tannery and subsequent shops continue as complete batches, including gathering, item effects, prices and recycling.

The biggest corrections are:

- An unrelated material should not become medicine just because it has a high Insulation or Reactivity number. New recipes should ask for recognizable ingredients that actually do the job.
- Coatings are intended to last an entire excursion. Recent ingredient updates preserved the current one-strike rule temporarily; that did not change the agreed destination.
- Material quality, workmanship and actual equipment statistics must remain distinct. A better-looking grip must not secretly multiply blade Power a second time.
- Prepared Cord, Cloth, Leather and Ingots need useful consumers. Starter gear should not require a long chain of specialist buildings.
- Making, selling and recycling must use consistent values and return the actual recoverable components, without also returning the raw materials used to prepare them.

## Apothecary — all 19 preparations

**Current behavior:** the shop has 19 recipes, including Seamlight and Scent Mask. Lesser Salve has its new Resin-and-Plant-Fibre path. Briar Oil’s new selection is reported delivered in phone build 310 alongside its older recipe. The complete new recipe/source batch below is not implemented or delivered; Venom’s isolated ingredient update has not been implemented.

**Decided intended behavior:** recognizable physical ingredients replace unrelated property requirements. Ordinary preparations cost no Essence; Stillwater and Waystone retain their explicit supernatural costs. Standardized preparations do not gain colour, quality or potency from the selected ingredients. Prepared goods remain stored or claimable until deliberately packed.

**Design-authored first-pass production plan:** the whole shop now has exact recipes and named sources. This closes the earlier unnamed-ingredient proposals as a complete implementation plan. The new plant names, quantities, source frequency and learning choices are Game Design’s revisable first-pass tuning under your shop-overhaul direction; they are not claims that you personally approved each row, or that these changes are already playable.

Each row makes one item. Existing ordinary recipes cost 0 Essence; existing Stillwater also costs 6 Essence and Waystone costs 12 Essence plus 1 Mote. Those fees are included explicitly in the new recipe column. A property material in the existing recipe is a separate ingredient. Base healing/status values still follow the existing character, prevention and cure rules.

| Preparation | Existing recipe | What it does; ordinary sale value | New first-pass recipe, not yet delivered |
| --- | --- | --- | --- |
| Seamlight | Quartz 1, Resin 1, Fibre 1 | Portal guidance; 5 | 1 Quartz, 1 Resin, 1 Plant Fibre |
| Scent Mask | Reagent 1, selected Hide/Pelt/Down/Oil 1 | Scent interference, base 12 world turns; 2 | 2 Aromatic Leaf, 1 Resin |
| Lesser Salve | New route: Resin 1, Stem/Leaf Fibre 1. Old: Resin 1, Flexibility 25 sample | Heal 10; 2 | 1 Resin, 1 Plant Fibre |
| Salve | Pulp 2, Spore 1, Resin 1, Insulation 40 sample | Heal 24; 5 | 1 Cloth, 2 Soothing Leaf, 1 Resin |
| Greater Salve | Ichor 1, Spore 2, Resin 2, Reactivity 60 sample | Heal 45; 10 | 1 Cloth, 2 Soothing Leaf, 2 Restorative Spore, 2 Resin |
| Clearing Draught | Pulp 1, Salt 1, Reactivity 35 sample | Clear Poison and Bleed; 5 | 1 Bitter Root, 1 Salt |
| Quenching Draught | Reagent 1, Resin 1, Insulation 45 sample | Clear Burn and Dazzle; 5 | 2 Soothing Leaf, 1 Salt |
| Broad Antidote | Ichor 1, Reagent 1, Spore 1, Reactivity 65 sample | Clear one affliction; 10 | 1 Bitter Root, 1 Restorative Spore, 1 Salt |
| Stonebark Tonic | Timber 1, Resin 1, Hardness 45 sample | Prevent next affliction; 5 | 1 Tough Bark, 1 Resin |
| Venom | Toxin 1, Fibre 1, Reactivity 55 sample | Poison, base 2 damage / 4 rounds; 5 | 1 Toxic Sap, 1 Plant Fibre |
| Firebrand | Reagent 1, Sulfur 1, Reactivity 60 sample | Burn, base 4 damage / 2 rounds; 5 | 1 Sulfur, 1 Resin |
| Briar Oil | Old Fibre 1, Resin 1, Flexibility 50 sample. Delivered new route uses Stem/Leaf Fibre and a separately selected Resin owner plus qualifying world material | Bleed, base 2 damage / 3 rounds; 5 | 2 Plant Fibre, 1 Resin |
| Flashsalt | Reagent 1, Mercury 1, Lustre 55 sample | Dazzle, base 2 rounds; 5 | 1 Quartz, 1 Sulfur, 1 Salt |
| Solvent | Reagent 1, Salt 1, Reactivity 40 sample | Identify a field curio; 5 | 1 Bitter Root, 1 Sulfur |
| Lure | Toxin 1, Pulp 1, Reactivity 50 sample | Attract nearest roaming creature; 5 | 1 Aromatic Leaf, 1 Plant Fibre |
| Stillwater | Riftglass 1, Mercury 1, Lustre 60 sample | Restore Stability 25; 10 | 1 Rift-glass, 1 Mercury, 6 Essence |
| Waystone | Riftglass 1, Hardness 70 sample, 1 Mote | Return with eligible haul; 20 | 1 Rift-glass, 1 Quartz, 12 Essence, 1 Mote |
| Torch | Resin 1, Timber 2, Reactivity 30 sample | Journey illumination, base 2; 2 | 1 Resin, 1 Log, 1 Plant Fibre |
| Farsight Draught | Quartz 1, Ichor 1, Lustre 50 sample | Reveal nearest site and surroundings, base 2; 10 | 1 Quartz, 1 Restorative Spore |


The new recipes remove the unrelated property ingredient completely. Briar Oil’s two Fibre and Resin are sufficient in the new plan; Venom uses actual Toxic Sap and Fibre. Neither asks for a hidden third sample. Stem and Leaf Fibre are the supported alternatives, and Softwood or Hardwood Logs fill a Log requirement. Similar names do not make other materials interchangeable.

### Six useful plant parts

| New ingredient | Where its real source belongs | Tool and harvest | Ordinary sell / buy per unit |
| --- | --- | --- | --- |
| Aromatic Leaf | Leafy herbs on fresh damp Loam or clay soil, with enough daylight | Scythe 1; one hit gives 2 | 2 / 4 Gold |
| Soothing Leaf | Fleshy-leaved herbs on fresh moist Loam or clay soil, with enough daylight | Scythe 1; one hit gives 2 | 2 / 4 Gold |
| Bitter Root | Root-clump herbs on fresh damp or moist Loam or clay soil | Scythe 1; one hit gives 2 | 2 / 4 Gold |
| Restorative Spore | Actual spore-bearing fungi on fresh damp or moist ground; low light is allowed | Scythe 1; one hit gives 2 portions | 6 / 12 Gold |
| Toxic Sap | Plants that actually bear this sap, on fresh moist growing ground | Scythe 1; one hit gives 1 portion | 6 / 12 Gold |
| Tough Bark | Bark-bearing shrubs on fresh damp Loam over Granite or Sandstone | Scythe 2; one hit gives 3 portions | 2 / 4 Gold |

These sources have unfrozen, unsubmerged roots and retain the established physical growing conditions. A plant’s colour does not prove its medicinal properties. Each species keeps its actual named material; looking, harvesting or reopening does not reroll it. Fungi do not become leaves, and an arbitrary spore is not automatically restorative.

The six initial gathering profiles have no contact damage. Having a useful toxic substance is different from being an actually harmful contact patch. Existing dangerous flora still keeps its own warning, harm and tool rules; this plan does not make every Toxic Sap plant dangerous to walk over or make existing dangerous plants harmless.

Existing early-maker resources keep their reserved places. For remaining suitable flora placements, the starting plan gives the new herb group one quarter of the selection weight when both it and the existing group can grow; eligible herbs share that group equally. Total flora counts stay the same. This does not put every ingredient in every world or add a second resource to an occupied tile.

### Progress through the complete shop

Lesser Salve, Briar Oil and Torch use the opening raw sources. Suitable worlds can provide five of the six new plant parts with Scythe 1. Corrin’s Cloth gives the stronger Salves a meaningful prepared component without blocking the first remedy. Scythe 2 adds Tough Bark for Stonebark Tonic.

The new material rules put Quartz, Sulfur and Mercury at Pick 2 and Rift-glass at Pick 3. Their sources retain their existing world conditions: Quartz needs hard mineral ground, Sulfur hot volatile ground, Mercury suitable metallic/volatile ground, and Rift-glass unstable ground. Local placement still needs a legal free source position and a reachable working position. These are conditions for finding minerals, not material-quality bars that must be checked when making a potion.

Pick 2 opens the relevant Seamlight, Firebrand, Flashsalt, Solvent and Farsight ingredient routes. Stillwater and Waystone remain later supernatural supplies because they require actual Rift-glass; Waystone also needs a real Mote. The complete Pick-3 upgrade route is a connected Blacksmith dependency, not claimed delivered by this Apothecary plan. None of those later items is required to make the first Salve.

Nessa’s early foundation remains 20 Essence, 4 Clay and 4 Logs. No new Apothecary tier, keeper attendance, creature hunt, Isolde detour or universal extract-processing step is added. Ichor and other creature fluids remain valid materials elsewhere; ordinary preparations no longer depend on their unfinished new creature-source rules.

Recipes are learned through their signature ingredients reaching Home once the shop is built; Lesser Salve remains taught at construction. Leaf, Root, Spore, Sap and Bark recipes follow their named parts. Mixed recipes may need their two signature types present, such as Quartz and Sulfur for Flashsalt. Learning never gives a free bottle, and already learned recipes stay learned after ingredients are spent.

### Quality, storage and value

All six plant parts are ungraded, with actual source colour and history retained. Named minerals have ordinary named stacks. These facts do not change standardized bottle appearance or potency. Existing 10/24/45 base healing, cures, prevention and field effects remain intact, apart from the already agreed shared coating lifetime below.

Every new row’s full ingredient purchase cost exceeds the finished item’s ordinary sale value, even before counting Essence or Motes. Trading stock is not guaranteed. Making a useful remedy is not an unlimited buy–craft–sell profit loop, and finished preparations do not recycle into free ingredients.

Batch preparation must spend the exact chosen quantities once and leave the finished items stored or claimable if storage is full. Mixing visually identical bottles must preserve their preparation history without creating extra usable stock. Legacy materials keep an honestly labelled compatible route until their actual identities can be supported; generic Toxin or Reagent never silently becomes one of these new plant parts.

### All four weapon coatings

**Current behavior:** Venom, Firebrand, Briar Oil and Flashsalt use up their prepared coating on the next successful applicable strike. A miss retains it.

**Decided intended behavior:** one preparation lasts exactly one world excursion on the chosen weapon. It survives travel, encounters and reopening the game during that excursion. Strikes and elapsed time do not consume it. Returning home or otherwise ending the excursion ends the preparation; it cannot carry into another world or jump to another weapon.

Each hit still follows that coating's own Poison, Burn, Bleed or Dazzle rules, including existing prevention, cures and refresh behavior. Keeping a coating prepared does not make an individual affliction permanent. An older active coating should remain on its weapon for the rest of its current excursion; unused bottles do not turn into free preparations.

Longer-lived coatings are much stronger than single-strike bottles. Their effects and ingredient availability need to be compared together. The agreed lifetime stays intact while those numbers are tuned.

## Blacksmith — starter gear, tools and the whole family

**Current behavior:** the early raw-Iron blade, tool improvements and T2 ingots have reported implementations. Older material-based Pointed Blade crafting remains a separate path. The wider eight-family catalogue is not all available: the older live Blacksmith list contains Pointed Blade, while seven additional families remain planned.

**Decided intended behavior and retained first-pass costs:** Halloway's early foundation costs 20 Essence, 8 Iron, 4 Plant Fibre and 4 Logs. The starter Iron blade and Pick/Axe improvements each use 4 Iron, 1 Log, 2 Plant Fibre and 1 Coal, with no Essence fee. These come before ingots.

Blacksmith T2 costs 20 Essence, 8 Iron, 4 Clay and 4 Logs. It turns 2 Iron and 1 Coal into 1 Ingot without an Essence fee. The Scythe improvement uses 2 Ingots, 1 Log and 2 Plant Fibre. Ingots therefore arrive with useful tools and the Buckled Guard to make.

| Family in the complete plan | Purpose | Main construction choices |
| --- | --- | --- |
| Pointed Blade | Close piercing weapon | Point and grip |
| Cutting Blade | Close cutting weapon | Edge and grip |
| Hand Maul | Close crushing weapon | Head and haft |
| Long Spear | Mid-range piercing weapon | Point, haft and binding |
| Shield | Offhand protection | Face, brace and binding |
| Helm | Head protection | Shell and lining |
| Rigid Guard | Body protection | Rigid body and binding |
| Field Pick | Mining tool | Working point, weight and haft |

**Proposals still being worked out:** review all allowed material choices, resulting statistics, prices and recoverable parts together. Keep a single understandable Pick progression; the Field Pick should not create a competing extraction level. New Bone is one possible material in the existing blade family, not a separately approved weapon recipe. Its previous two-Bone recipe and resale suggestion remain proposals inside this batch. No individual Bone-blade decision is required from you now.

## Tannery — prepared stock, clothing and carrying

**Current behavior:** the early Cord, Cloth, Leather, garments and carrying paths have reported implementations alongside older sample-based clothing recipes. These are useful foundations, not proof that every later clothing choice has been reconciled.

**Decided intended behavior and retained first-pass recipes:** Corrin's foundation costs 20 Essence, 6 Logs, 4 Clay and 4 Plant Fibre. Preparing these materials and making the ordinary garments below costs no Essence.

| Make | Ingredients | Result |
| --- | --- | --- |
| Plant Cord | 2 matching Plant Fibre | 1 Cord |
| Plant Cloth | 4 matching Plant Fibre | 1 Cloth |
| Leather | 2 compatible matching Hide portions and 1 Salt | 1 Leather, retaining its material character |
| Woven Guard | 1 Cloth and 1 Cord | Fine workmanship, 1.5 Protection |
| Buckled Woven Guard | 2 Cloth, 1 Cord and 1 Ingot | Fine workmanship, 2 Protection |
| Woven Gloves | 1 Cloth and 1 Cord | 1 Protection |
| Woven Boots | 1 Cloth, 1 Cord and 1 Resin | 1 Protection |
| Leather Guard | 2 Leather and 1 Cord | Protection from the actual Leather, with no hidden handling or heat bonus |

Matching matters where type, quality, colour and the material's actual properties affect the result. Preparing Leather does not erase its source, and recycling it does not also refund the raw Hide and Salt.

Carrying grows from 8 to 11 spaces for 5 Essence and 4 Fibre, then to 14 for 10 Essence, 6 Fibre and 1 Resin. Corrin's later improvement reaches 23 for 20 Essence, 2 Cloth, 2 Cord and 1 Resin. Sela's separate +2 improvement remains separate.

**Proposed consolidation:** Supple Coat, Working Gloves and Working Boots are the broader clothing families. Their later material choices should connect clearly to the early woven and leather garments. They should not become two confusing sets of similarly named clothes with unrelated quality rules. The full clothing batch also needs one consistent explanation of recovery and sale value.

## Every remaining shop and crafting system

The sequence below follows material dependencies. It includes services and processing that do not appear as ordinary recipe cards.

| System | Complete scope of its batch | Main correction or dependency |
| --- | --- | --- |
| Bowyer | Longbow, Sling, Throwing Set | Three far-reaching damage choices; suitable limbs, Cord, projectiles and carriers, without ammunition chores |
| Weaponsmith | Fitted Point, Fitted Edge, Fitted Maul, Fitted Polearm | Useful specialist fittings and explicit damage/reach choices; compare all four against Blacksmith gear |
| Armoury | Rigid, Insulated and Balanced rebuilds across the five protective slots | Show actual Protection/ward tradeoffs and preserve the piece being rebuilt |
| Equipment improvement and recovery | Reforge, component replacement, Peerless refinement, recycling | One explanation of identity, improvement, fees and recoverable components; no repeated bonus or material duplication |
| Survey Post | Eight instruments, each with Good and Fine improvements | Sixteen improvements with understandable instrument components, not a generic property sample masquerading as every instrument part |
| Scriptorium / Writing Desk | Ink, personal Compounds, Seamward installation/erasure, later Paper and pigments | Keep making ink, using ink, recording a Compound and inscribing an item distinct |
| Distillery | Heat, Caustic and Light Cores | Direct attunement, recognizable catalysts and preserved potency/source; no obsolete Blank Core manufacturing step |
| Channelworks | Current Heat Fixture and restoration; planned three attunements across three reaches | A complete nine-configuration plan; a stored fixture does not mean every planned weapon is playable |
| Anchorage | Anchor Frame construction and world assignment | Actual structural, ballast, binding and attunement parts; creating a frame is separate from assigning it |
| Essence Spring | Refining, Second Pass and Continuous Settling | Keep Raw Essence conversion separate from Core attunement |
| Processing | Recycler/Rubble sorting, Planks/Hafts, Pulp/Paper/pigments, Blocks and Glass | Each new intermediate arrives with a real use and consistent prices |
| Shared progression and storage | Building foundations, research, staffing, carrying, Storehouse and Waiting | An obtainable route into each shop, honest missing requirements and claimable outputs |

Existing instrument improvements cost 20 Essence plus two suitable materials for Good, and 50 Essence plus three for Fine. The eventual physical component choices remain design work. These fees have not silently become zero because ordinary crafting is moving away from Essence fees.

Existing direct Core attunement costs 16 Essence plus the appropriate material and catalyst. Current repeatable Channelworks work consumes a Heat Core to make a Heat Fixture; the complete Heat/Caustic/Light weapon family remains intended work. Older references to making Blank Cores are historical.

Current ink makes 12 applications from the requested Cyan, Magenta, Yellow and Depth stock plus Resin. Personal Compound formalization costs 20 Essence and 4 Pulp. Seamward installation uses an identified Seamlight, 10 Essence and an ink application on eligible gear; it is a different recipe from Waystone. These services need their own ingredient review while preserving their existing effects.

## Keeping accepted decisions intact

The one-strike coating rule remained in the game while its replacement was unfinished. The newer ingredient plans then mistakenly instructed Engineering to preserve that old lifetime without naming it as temporary. Those instructions have now been withdrawn from future work; the accepted destination remains one full excursion.

For each shop, Design will compare its proposed ingredients, item effects, progression and costs with the accepted decisions before handing it over. Any old behavior deliberately kept must say whether it is still intended or temporary until a named replacement. Conflicting older instructions will be marked superseded, and the replacement will be included in the ordinary implementation checks. This does not add another phone-delivery verification step.

## What needs your decision

The actual crafting choice still waiting on you is **what a spent Mote should buy when an incomplete Peerless setup misses**. The recommended direction is lasting progress without destroying or downgrading your piece. The full Mote + maximum shop + attending keeper setup remains the intended 100% guarantee.

Recipe quantities, individual Bone roles, the named ingredient catalogue, shop prices and recovery tables are Design work. We will bring you a grouped question if a broader player-experience choice needs your preference, rather than asking you to approve one recipe after another.

See [Aimee Homework](aimee-homework.html) for that choice and your creature-generator goals. See [the existing decisions](design-decisions-september-4.html) for the wider world, material and early-progression plan.
