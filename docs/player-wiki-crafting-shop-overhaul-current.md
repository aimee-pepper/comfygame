# Crafting overhaul, shop by shop

Updated 5 September 2026. This is the complete crafting review you requested, beginning with Apothecary, Blacksmith and Tannery. **Current behavior** means existing rules or reported delivered changes. **Decided intended behavior** means the agreed destination. **Proposals** are the whole-shop recipe and balance changes still being worked out; they are not already playable.

## What the review found

Stone tools lead to useful raw-material equipment. Blacksmith T2 introduces Ingots, while Tannery textiles provide a parallel route into clothing and later specialist components. The later recipes still contain older rules that do not fit that sequence. The Apothecary now has a complete first-pass recipe-and-source plan; implementation remains pending. The Forge now also has its complete first-pass family/tool/material plan. The Tannery also has its complete first-pass textile, Leather, clothing and carrying plan below. The Bowyer, Weaponsmith and Armoury now also have complete first-pass plans. Subsequent shops continue as complete batches, including gathering, item effects, prices and recycling.

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

## Blacksmith — complete Forge first-pass plan

**Current behavior:** the early raw-Iron blade, Pick/Axe improvements, T2 ingots and Scythe improvement have reported implementations. Older material-based Pointed Blade crafting remains a separate path. The complete new Forge batch below is not implemented or delivered; the older live Blacksmith list does not already contain all eight catalogue families.

**Retained decisions:** stone opening tools, useful raw-material starter gear, ingots at T2 and a clear progression into prepared components. Material quality, workmanship, actual statistics and tool level remain different things.

**Design-authored first-pass plan:** the new T3 costs, whole-family material choices, statistics, learning, prices and refit rules are now specified together. These are revisable Design choices under your whole-shop direction, not personal approvals attributed to you. Bone’s old individual approval question has been absorbed into this plan.

### Forge and tools

| Operation | What you need | What you get |
| --- | --- | --- |
| Build Forge T1 | Halloway, 20 Essence, 8 Iron, 4 Plant Fibre, 4 Logs | The first Forge, without free equipment |
| Pick 1→2 or Axe 1→2 | Forge T1, that owned tool, 4 Iron, 1 Log, 2 Plant Fibre, 1 Coal | The same tool at level 2; no Essence fee |
| Forge T1→T2 | 20 Essence, 8 Iron, 4 Clay, 4 Logs | Ingot making and the next Forge recipes |
| Make an Iron Ingot | Forge T2, 2 Iron, 1 Coal | 1 ungraded Ingot; no Essence fee |
| Scythe 1→2 | Forge T2, that owned Scythe, 2 Ingots, 1 Log, 2 Plant Fibre | The same Scythe at level 2; no Essence fee |
| Forge T2→T3 | 40 Essence, 6 Ingots, 8 Clay, 6 Logs, 2 Quartz | The third Forge level; no free tool or Peerless piece |
| Pick, Axe or Scythe 2→3 | Forge T3, that owned level-2 tool, 4 Ingots, 1 Log, 1 Plant Cord, 2 Coal | The same tool at level 3; no Essence fee |

The three starting tools stay in their dedicated tool roll. Improving one preserves its identity and its selection/packing links; it does not create a duplicate tool or refund earlier construction materials. The next level is required in order. Tool level decides harvesting access, and Bone quality does not secretly bypass it.

Pick 2 supplies the Quartz needed for Forge T3. Pick 3 then reaches Rift-glass for the later Apothecary recipes. Cord makes Corrin useful at this later stage while leaving the first Pick, Axe and weapon independent of the Tannery. The route needs no rare mineral before Pick 3, no Mote and no new Steel-processing step.

### Every family and its exact choices

T1 teaches Pointed Blade, Cutting Blade, Hand Maul and Shield. T2 adds Long Spear, Helm, Rigid Guard, Ingot making, the Scythe improvement and Refit. Existing learned schematics remain learned, while their actual facility requirement still applies. T3 adds the third tool levels.

Each equipment row makes one piece for **0 Essence**. Choose one working option and the listed supporting parts. Ingot options require T2. “Fibre” means actual Stem or Leaf Fibre; “Log” means Softwood or Hardwood Log.

| Family | Working part: choose one bundle | Supporting parts | Fixed role |
| --- | --- | --- | --- |
| Pointed Blade | 4 Iron + 1 Coal; **or** 2 Ingots; **or** 2 Quartz; **or** 1 Bone | 1 Log + 2 Fibre; **or** 1 Bone grip | Close, Pierce |
| Cutting Blade | 4 Iron + 1 Coal; **or** 2 Ingots; **or** 1 Bone | Same grip choices | Close, Rend |
| Hand Maul | 4 Iron + 1 Coal; **or** 2 Ingots; **or** 2 Bone | 1 Log + 2 Fibre; **or** 2 Bone + 2 Fibre | Close, Crush |
| Long Spear | 4 Iron + 1 Coal; **or** 2 Ingots; **or** 2 Quartz; **or** 1 Bone | 2 Logs + 4 Fibre; **or** 3 Bone + 4 Fibre | Mid, Pierce |
| Shield | 4 Iron + 1 Coal; **or** 2 Ingots; **or** 2 Softwood Logs; **or** 2 Hardwood Logs; **or** 2 Bone | 1 Log + 2 Fibre; **or** 1 Bone + 2 Fibre | Offhand protection |
| Helm | 4 Iron + 1 Coal; **or** 2 Ingots; **or** 2 Bone | 4 Fibre; **or** 1 Cloth lining | Head protection |
| Rigid Guard | 8 Iron + 2 Coal; **or** 4 Ingots; **or** 4 Bone | Lining: 4 Fibre or 1 Cloth; binding: 2 Fibre or 1 Cord | Body protection |
| Field Pick | Uses the owned Pick improvement table above | Its listed upgrade materials | One Pick progression, without a second competing tool item |

Raw Forge materials do not need matching colours. Separate boards, wraps, lining portions and Bone pieces keep their real colours and sources. A shield face uses the selected Softwood or Hardwood type, but its boards may differ in colour. Already prepared Cloth and Cord retain their own manufacturing rules.

Bone can combine with the other supported new materials in these bundles. Older Bone or similarly named legacy stock does not automatically qualify. Bone’s actual producer still needs implementation; not every creature has a qualifying skeleton. Other older materials retain their supported older recipe paths until their new physical roles and sources are specified.

### Statistics and workmanship

| Working construction | Weapon Power | Shield / Helm Protection | Rigid Guard Protection |
| --- | ---: | ---: | ---: |
| Raw Iron | 2.0 | 1.0 | 2.0 |
| Iron Ingot | 2.5 | 1.5 | 2.5 |
| Quartz point, Pointed Blade or Long Spear only | 2.25 | — | — |
| Softwood shield face | — | 0.75 | — |
| Hardwood shield face | — | 1.0 | — |
| Bone | From actual skeletal density and material quality | Same rule, with the smaller defensive contribution | From actual skeletal density and material quality |

Bone uses the agreed material calculation: contribution ceiling × (0.5 + actual density ÷ 200) × the material-quality multiplier. The ceiling is 4 for a weapon or Body piece, 2 for a Shield or Helm. Several Bone portions in one working part are averaged, then the final statistic is rounded once to a quarter point. They do not each add another full weapon’s Power.

For example, a Common Bone point at density 50 gives 3 Power; at density 40 it gives 2.75. Two Common Bone head portions at densities 0 and 100 average to 3 Power. Their separate colours remain recorded.

The supporting parts supply structure, colour and workmanship without invented handling or heat bonuses. Workmanship gives the working group a 70% share and the supports 30%; ungraded stock supplies the Fine baseline. Rough, Fine, Superior and Exceptional remain the ordinary results. A better Bone grip can change that label without changing an Iron point’s actual Power, and the preview must show both facts clearly. No ordinary craft or refit creates Peerless.

### Value, recovery and improving a favourite piece

For new pieces made under this whole-shop plan, ordinary sale value is the sum of the actual recoverable components’ ordinary values when made. Offered purchase costs twice that sum. Fuel is spent, and neither source colour nor the workmanship label adds a hidden price premium. This does not guarantee merchant stock.

| New piece | Sale value | Buy price, if offered |
| --- | ---: | ---: |
| Raw-Iron or Ingot Pointed Blade with Log/Fibre grip | 11 Gold | 22 Gold |
| Quartz Pointed Blade with Log/Fibre grip | 15 Gold | 30 Gold |
| Two Common Bone Pointed Blade | 8 Gold | 16 Gold |
| Two Rare Bone Pointed Blade | 16 Gold | 32 Gold |
| Softwood Shield with Log/Fibre brace | 5 Gold | 10 Gold |
| Raw-Iron Helm with Fibre lining | 12 Gold | 24 Gold |
| Raw-Iron Rigid Guard with Fibre lining/binding | 22 Gold | 44 Gold |
| Ingot Rigid Guard with Cloth lining/Cord binding | 19 Gold | 38 Gold |

Existing pieces keep their saved values. The earlier 10-Gold starter blade does not silently become an 11-Gold item; the new value belongs to a newly made piece under the revised rules.

Recycling a supported new Forge piece returns its exact structural components, following the early crafting approach already used for these materials. It does not also return Coal, smelting fuel, Salt, fees or the raw ancestors of an Ingot, Cloth or Cord. Older gear keeps its actual recovery rules and protections. Buying, making, recycling and selling cannot create an unlimited profit loop.

**New first-pass Refit service at Forge T2:** keep an eligible piece’s identity and family, replace a chosen complete working or support bundle using its listed materials, and recover the outgoing structural parts. The service costs no Essence. It recalculates the result from the final components; repeated refits cannot keep adding the same bonus. The preview shows changed statistics, colours, value and returned parts. Weapons do not silently switch damage type or reach through refitting.

The older Reforge system remains for items it actually supports. It does not automatically become a new-quality calculator or a working Peerless service. The separate Mote-on-miss choice remains open for later refinement; getting Forge T3 alone grants no Peerless item.

### Dependencies and remaining work

This closes the Forge’s first-pass design, including the missing Pick-3 route. Engineering still needs to implement the new families, tool levels, source connections, learning, refit and recovery. The shared physical Quartz source belongs to the Apothecary source batch; Bone has its own already specified creature-source contract. Existing Corrin Cord/Cloth supplies the prepared components. Those are implementation dependencies, not new individual approval questions.

The minimum raw accounting route from the starting tools to Forge T3 and Pick 3, including Corrin and one Cord, totals 100 Essence, 40 Iron, 13 Coal, 22 Logs, 12 Fibre, 16 Clay and 2 Quartz. This excludes departures, optional gear and surplus harvested units. It is a consistency check, not a promise to complete it in one world or a measured pacing claim.

Glass remains planned until its consuming system is ready; empty processing steps and additional metal intermediates are not added just to fill the Forge menu. Blacksmith’s and Tannery’s full first passes are now specified; later specialist batches continue in dependency order.

## Tannery — the complete textile, Leather, clothing and carrying plan

**Current behavior:** early Cord, Cloth, Leather, woven garments, Leather Guard and carrying improvements have reported implementations. The current processing routes require matching Fibre and two matching Hide portions for Leather. Older sample-based clothing recipes also exist. The complete replacement described here is **not yet implemented**.

**Retained decisions:** Corrin makes flexible foundational clothing and prepared stock shared with other shops. Her foundation costs **20 Essence, 6 Logs, 4 Clay and 4 Plant Fibre** after recruitment. Ordinary preparation, garment crafting and the refit described below cost **no Essence**. Woven clothing and carrying remain available before Leather or Ingots. Bought capacity and existing owned items stay yours.

**New Design-authored first-pass choices:** simplify material matching, dress one Hide portion at a time, combine the clothing into three families with seven variants, and use consistent component-based prices and recovery. These choices use Aimee's delegated tuning authority; they are not new personal approvals or measured balance results.

### Preparing usable materials

| Make | New ingredients | What is retained | New sale / buy |
| --- | --- | --- | --- |
| 1 Plant Cord | 2 Stem and/or Leaf Fibre | The two actual strands and their source colours | 1 / 2 Gold |
| 1 Plant Cloth | 4 Stem and/or Leaf Fibre | Four actual constituent sections and their source colours | 2 / 4 Gold |
| 1 Leather | 1 eligible Smooth Skin, Supple Hide or Tough Hide, plus 1 Salt | That raw portion's quality, colour and material properties | Raw portion's recorded sale value plus Salt's; buy twice the result |

The Fibre portions may come from different plants and have different colours. They become a composite textile; the game does not average them into an invented plant or colour. You can choose the strands/sections for appearance, or accept the ordinary stock selection. Known source colours stay recorded even when final artwork is unfinished; genuinely unknown old colour stays honestly unknown. Mixing does not add a new material type or make plants Rare/Exceptional.

One-to-one dressing makes a small creature's single Hide drop useful. Leather inherits that exact portion's quality and properties. A garment can use two different Leather panels without requiring identical creatures or blending their measurements into fictional Leather. Salt does not improve its grade or add another colour.

Existing gathering stays: medium Stem Fibre gives 2 with Scythe 1, low Leaf Fibre gives 1 with Scythe 1, and Tall Stem gives 3 with Scythe 2. Salt remains hand-gathered from actual deposits. These recipes add no free resources, extra source placements or guaranteed Hide-bearing animals.

Only creatures whose actual primary covering supports Hide produce these new covering parts: aquatic/piscine bodies give Smooth Skin; other eligible bodies give Supple or Tough Hide according to their hardness. The existing 70% covering-drop chance and size-based quantity remain. Anatomy improves a successful quantity once, from 1/2/3/4 to 2/3/4/5; it does not make a missed roll succeed. Existing quality still comes from the real covering/flexibility and source-world Danger. Other body materials are not silently treated as Hide, and the broader creature anatomy catalogue remains unfinished.

### Three clothing families, seven complete variants

Building Corrin's shop teaches these ordinary choices without a second paid pattern, Study or shop-upgrade toll. The Buckled Guard's Ingot comes from Blacksmith T2; that ingredient is its progression requirement. Corrin need not be actively attending for normal crafting. Existing applicable construction/staffing price rules remain; the foundation and project prices on this page are their base quotes.

| Family and garment | Complete ingredients | Total Protection | New sale value using newly produced Common Leather |
| --- | --- | --- | ---: |
| Guards — Woven Guard | 1 Cloth, 1 Cord | 1.5 | 3 Gold |
| Guards — Buckled Woven Guard | 2 Cloth, 1 Cord, 1 Iron Ingot | 2.0 | 9 Gold |
| Guards — Leather Guard | 2 separately chosen Leather panels, 1 Cord | From each panel, plus the existing 0.25 construction contribution | 9 Gold |
| Gloves — Woven Gloves | 1 Cloth, 1 Cord | 1.0 | 3 Gold |
| Gloves — Leather Gloves | 1 Leather, 1 Cord | From its Leather, plus 0.25 construction contribution | 5 Gold |
| Boots — Woven Boots | 1 Cloth, 1 Cord, 1 Resin | 1.0 | 5 Gold |
| Boots — Leather Boots | 1 Leather, 1 Cord, 1 Resin | From its Leather, plus 0.25 construction contribution | 7 Gold |

Guards use the Body slot, Gloves the Hands slot and Boots the Feet slot. These are the existing Supple Coat, Working Gloves and Working Boots families organized into clear material choices, not a second unrelated clothing catalogue. Older owned clothing keeps its identity and saved statistics. The older hidden-property recipe offers retire from new ordinary crafting when the full replacement is enabled; unsupported old samples do not become new Leather by name alone.

Woven garments remain Fine workmanship. They add exactly the listed Protection, with no hidden Initiative, ward, handling, harvesting or carrying bonus. The two Cloth pieces of a Buckled Guard may have different compositions. Resin seals Boots; it adds no quality vote or separate colour region.

Leather Protection uses the actual hardness and coverage of each selected panel, scaled by that panel's quality. In exact terms, covering protection is hardness × coverage ÷ 100. Each Leather piece contributes **2 × (0.5 + covering protection ÷ 200) × its quality multiplier**; the Guard has two pieces, Gloves/Boots one. Add 0.25 for construction, then round the final total to the nearest quarter. Poor/Common/Rare/Exceptional multipliers are 0.75/1/1.25/1.5. This preserves the existing Guard result when its two panels match.

For example, two Common panels with covering protection 50 produce **3.25 Protection** and Fine workmanship. A Poor panel at 20 plus an Exceptional panel at 80 produces **3.75 Protection** and Superior workmanship. The exact preview retains quarter-point calculation with the game's usual one-decimal display. Workmanship averages only the Leather panels' quality ranks and rounds half up; minor Cord does not drag Exceptional Leather toward Fine. Processing never applies quality twice or upgrades the original Hide.

### Value, recovery and changing a garment

A newly made garment sells for the sum of its actual recoverable components' recorded sale values, and costs twice that to buy. This matches the new Forge rule. No extra grade, colour or species multiplier is added to that sum. Finished items retain their frozen prices when later tuning changes.

New Skin/Hide rewards use **2 / 3 / 6 / 12 Gold** sale value at Poor/Common/Rare/Exceptional, consistent with the existing common-base-3 creature market plan. With ordinary Salt worth 1, newly dressed Leather is **3 / 4 / 7 / 13 Gold**. Existing raw Hide, Skin and Leather keep their old values. Dressing cheap older stock uses its actual old value plus the Salt value, so buying an old cheap Exceptional Skin cannot create a newly expensive Leather profit. The quote shows the actual total for the selected pieces.

With newly produced same-band Leather, a Guard sells for **7 / 9 / 15 / 27**, Gloves for **4 / 5 / 8 / 14**, and Boots for **6 / 7 / 10 / 16 Gold**. Mixed panels use their actual values. Existing early garments keep their older prices: these new numbers apply to future crafts.

Dismantling a supported garment returns its recorded prepared pieces once: Cloth, Cord, Leather and any recorded Ingot or Resin. It does not also return the Fibre inside a textile, Hide inside Leather, Salt used in dressing, or crafting currencies. Loose prepared stock has no reverse-processing recipe. Older equipment with a different recorded recovery rule keeps that rule.

**Ordinary refit:** at Corrin's built shop, replace a selected complete component of a garment whose construction is recorded. Pay the new inputs, receive the replaced recoverable pieces once, and preview the final stats, appearance and value before confirming. The exact owned item remains the same; the result is recalculated from its final parts, not given a repeating bonus.

You may also explicitly remake a garment as another known variant in its own family, such as Woven Guard → Buckled Woven Guard or Woven Gloves → Leather Gloves. This uses the complete new recipe and returns the old recoverable construction once. Repeatedly adding a buckle cannot accumulate Protection. Older pieces without sufficient component records remain usable and sellable but cannot have missing materials guessed for refitting. Peerless refinement remains a separate unfinished service.

### Carry and useful paths through the shop

| Improvement | Access and price | Field-pack spaces before Sela |
| --- | --- | ---: |
| Opening pack | Already owned | 8 |
| Reinforced Stitching | Opening Storehouse; 5 Essence, 4 Fibre | 11 |
| Balanced Straps | After Stitching; 10 Essence, 6 Fibre, 1 Resin | 14 |
| Deepened Satchel | Both previous improvements and built Tannery; 20 Essence, 2 Cloth, 2 Cord, 1 Resin | 23 |

Sela's separate Wayfarer Table costs **30 Essence, 6 Logs and 4 Fibre** after recruitment and adds **2** at any stage: 10/13/16/25. No active posting or duplicate purchase is required. Carry has no extra root fee, Leather requirement, paid pattern, T2 Tannery gate or sellable bag item. Colour and quality do not change its capacity.

Old ranks 0/1/2 map to 8/11/14 spaces; old ranks 3/4/5 receive the completed three-project capacity of 23. Repeated historical records do not grant extra slots, and supported higher old capacity remains preserved. An excursion already underway keeps its bound capacity until the next Home packing boundary. Nothing is discarded or automatically packed. Home shelving remains **16 plus nine improvements of 6, through 70**, under its existing owners and prerequisites; this plan adds no Tannery toll to it.

After building Corrin's shop, a complete basic woven outfit needs **18 Fibre and 1 Resin**, for 3.5 total Protection. Choosing the Buckled Guard instead needs **22 Fibre, 1 Ingot and 1 Resin**, for 4.0. A full Leather outfit needs **4 eligible raw portions, 4 Salt, 6 Fibre and 1 Resin**; at Common quality and covering protection 50 throughout, it gives 6.75. These are choices across gathering trips, not an opening checklist or required purchase order.

The first two pack improvements remain **15 Essence, 10 Fibre and 1 Resin**, leaving 25 of the opening 40 Essence before other spending. All three plus the Tannery foundation remain **55 Essence, 26 Fibre, 2 Resin, 6 Logs and 4 Clay**. The actual next-Bind quote determines departure affordability; there is no invented universal departure price.

Apothecary's Salve ladder and Forge's linings, bindings and tool improvements consume these same prepared textiles, with their complete source records. Their recipe counts, effects and quality rules stay as specified; mixed textiles add no new colour gate. Later specialist shops can build on these outputs without a new arbitrary facility.

**Implementation still needed:** mixed-textile selection and appearance, one-to-one Leather dressing and price preservation, all seven garment variants, refit and their connected save/trade/recovery behavior. This is a complete first-pass plan, not seven new homework approvals. The broader creature catalogue and the existing Mote-on-miss decision remain separate open work.

## Bowyer — the complete three-family first-pass plan

**Current behavior:** the Bowyer has Longbow, Sling and Throwing Set recipe definitions and an existing native crafting screen. Those routes use older broad material families, six-band crafting calculations and Essence fees. The new plan below has not yet been implemented; this is not a new playtest or delivery claim.

**Retained decisions:** Longbow is **Pierce · Far**, Sling **Crush · Far**, and Throwing Set **Rend · Far**. Each occupies the ordinary weapon slot. Maintained projectiles are part of the weapon: no ammunition inventory, replenishment, retrieval roll, durability or extra attack is added.

**Design-authored first-pass choices:** Fen's foundation becomes **30 Essence, 6 Logs, 2 Cord and 2 Resin** after recruitment, replacing the older 110-Essence legacy-material foundation. All three families and ordinary refit are included at the built shop. There is no extra pattern fee, Study, paid research root, attending-keeper requirement or new Bowyer tier for these recipes. Ordinary crafting and refit cost **0 Essence**, regardless of input quality. Fen's existing recruitment/story timing stays unchanged; these are base construction prices, subject to existing applicable staffing rules.

### All three complete recipes

Choose one listed alternative within each working part or support. Every other ingredient in its row is required.

| Weapon | Working material | Complete supports |
| --- | --- | --- |
| Longbow | Maintained points: 1 Iron Ingot **or** 2 Quartz **or** 1 Bone | 2 Hardwood Logs, 1 Resin, 1 Cord |
| Sling | Shot: 2 Clay + 1 Coal **or** 1 Iron Ingot **or** 1 Bone | 2 Cord; pouch of 1 Cloth **or** 1 Leather |
| Throwing Set | Two edges, each independently 1 Iron Ingot **or** 1 Bone | Carrier of 1 Cloth **or** 1 Leather, plus 1 Cord |

Fen shapes and laminates Hardwood into the Longbow's bending limbs. Softwood, a generic Timber sample or ordinary Bone is not automatically a suitable spring limb. Hardwood is the explicit first-pass material choice; there is no new hidden springiness threshold or seasoning timer. The added points are a deliberate component change: Bone makes a hard point without pretending every bone can bend into a bow. They stay part of the maintained weapon, not a separate arrow stockpile.

Clay is shaped and fired during the Sling craft using its Coal; no fired-shot inventory or new kiln building appears. Metal and Bone shot need no extra Coal. Soft cloth is a pouch, never the hard shot. Quartz is allowed for Longbow points, not slicing Throwing edges. The two edges may differ, but still produce one maintained weapon and one ordinary attack per action.

All prepared materials are the same shared Tannery/Forge stock. Different-colour Cord, Cloth, Leather, Logs and Bone retain their actual components and source histories. No matching-colour chore or invented averaged material is added. Ordinary world/plant materials stay ungraded. Bone and Leather keep their actual source quality, and an old same-name sample does not silently become a new typed material.

### How the weapons perform

| Working choice | New weapon Power before final rounding |
| --- | ---: |
| Iron Ingot point, shot or one throwing edge | 2.0 |
| Quartz Longbow points | 1.75 |
| Fired Clay Sling shot | 1.5 |
| Bone working piece | 3 × (0.5 + actual skeletal Density ÷ 200) × its quality multiplier |

Bone multipliers remain 0.75/1/1.25/1.5 for Poor/Common/Rare/Exceptional. Longbow and Sling use their working group's result. Throwing Set averages its two edge contributions; it does not double the damage. Round final Power once to the nearest quarter, with the existing one-decimal preview. Power is an equipment contribution, not a promise of that much final HP loss.

These first-pass ranged values account for Far reach's existing tactical benefit. They sit below comparable Forge working values without adding another ranged penalty to combat. Existing damage matchups, formation, action timing and skill rules remain. Supports add no hidden Initiative, ward, HP, damage bonus or automatic affliction.

Workmanship uses the accepted 70% working parts / 30% designated structural supports rule. Ungraded inputs count as Fine; Bone or Leather uses its actual band. Longbow's working group is its maintained points, with limbs and string as supports. Sling's supports are cords and pouch; Throwing Set's are carrier and ties. Resin and Coal do not vote. This does not change Tannery's separate rule that minor garment closures have no quality vote.

For example, Common Bone with Density 60 makes a **2.5-Power Fine Longbow**. Rare Bone at 60 makes a **3.0-Power Superior Sling** with a Cloth pouch. A Throwing Set with Poor Bone at 20 and Exceptional Bone at 80 makes **2.75 Power**; its workmanship is Fine with Cloth/Cord support or Superior with an Exceptional Leather carrier. The actual two bones stay distinct. Ordinary crafting/refit does not produce Peerless.

All three physical weapons use the accepted **one-weapon, one-excursion coating** rule. One bottle prepares the maintained weapon, not one projectile. Hits, misses, encounters and reopening do not consume it; ending the excursion does. Individual target afflictions keep their own durations and cures. This adds no new preparation location, free coating or one-strike exception.

### Prices, recovery and refit

New weapons sell for their actual recoverable components' recorded sale value and cost twice that to buy, as in Forge and Tannery. Existing owned weapons and old material lots keep their frozen values.

| Complete weapon | New sale / buy |
| --- | --- |
| Ingot Longbow | 9 / 18 Gold |
| Quartz Longbow | 17 / 34 Gold |
| Bone Longbow, Poor/Common/Rare/Exceptional | 7/9/13/21 sale; buy twice |
| Clay Sling with Cloth pouch | 6 / 12 Gold |
| Ingot Sling with Cloth pouch | 8 / 16 Gold |
| Bone Sling with Cloth pouch | 6/8/12/20 sale; buy twice |
| Two-Ingot Throwing Set with Cloth carrier | 11 / 22 Gold |
| Two same-band Bone edges with Cloth carrier | 7/11/19/35 sale; buy twice |

A Leather pouch/carrier changes the price by that exact Leather piece's recorded value minus the replaced Cloth's 2 Gold. Mixed edges use their actual individual prices. No extra quality, species or colour premium is multiplied on top.

Dismantling returns the selected construction materials once; Coal never returns. Selected Clay returns under the game's component-recycling convention without creating an unfiring recipe or extra shot item. Prepared Cloth/Cord/Leather/Ingots return intact, not their raw ancestors as well. Resin follows the existing recoverable construction-material rule. Older equipment keeps its own supported recovery policy. No ammunition is returned as a second reward.

Ordinary refit replaces a complete selected part, pays its new inputs and returns the old recoverable part once. The weapon keeps its exact identity, family, damage type and Far reach, with stats and price recalculated from the final components. Throwing edges can be replaced independently. Repeating a refit cannot stack Power, duplicate a weapon or restore a previous excursion's coating. Old items without a compatible construction record keep their existing supported service path; missing new Longbow points are not guessed into them.

### Progression and shared producers

A **Clay Sling** needs Tannery stock, ordinary Clay and Coal, without animals or Forge upgrades. A Longbow's Hardwood comes from an appropriate Axe-2 tree; metal points come from Forge T2, Quartz from its specified Pick-2 source, and Bone from the existing planned skeleton reward. Throwing Set also has a fully animal-free Ingot route. None requires Pick 3, a new Bowyer facility or a guaranteed material placement.

At base prices, Corrin's foundation, Fen's foundation and a Clay/Cloth Sling total **50 Essence, 12 Logs, 6 Clay, 16 Fibre, 2 Resin and 1 Coal**. A full shop/tool route to an Ingot Longbow, including Forge T1/T2 and Axe 2, totals **90 Essence, 22 Iron, 2 Coal, 23 Logs (at least 2 Hardwood), 16 Fibre, 8 Clay and 3 Resin**. These staged production totals exclude recruitment/search/Binding costs; they are not an opening shopping list or completed affordability playtest.

The Weaponsmith plan below now gives Fen's Hafts actual consumers: one Softwood or Hardwood Log becomes one matching Haft, with knowledge taught on Maud's recruitment. This replaces the earlier unused-Haft hold. Planks remain withheld until needed. Longbow limbs keep their own construction, and Forge's raw-Log starters gain no retroactive Haft prerequisite.

**Still needed:** implement the complete new Bowyer recipes/calculator, shared typed producer dependencies, actual combat projection, prices, refit/recovery and save/custody behavior. The three weapon families move together. Existing Mote/Peerless and broader creature-anatomy questions remain separate grouped work; this first pass adds no individual recipe approval homework.

## Weaponsmith — the complete fitted-weapon first-pass plan

**Current behavior:** Fitted Point, Fitted Edge, Fitted Maul and the damage-selectable Fitted Polearm have existing crafting definitions. Older routes use broad material families, six-band calculations and Essence fees; the earlier written property-threshold table also differs from those current definitions. The complete new plan below is **pending implementation**.

**Retained decisions:** Maud makes physical melee weapons. Point is Pierce/Close, Edge Rend/Close, Maul Crush/Close, and Polearm is an explicitly chosen Pierce/Rend/Crush weapon with Mid reach. Fitted weapons are not bound to a particular wearer and introduce no fit score, durability, repair, ammunition or extra attack. Maud's existing recruitment timing and singular Polearm diary teaching stay intact.

**New Design-authored first-pass choices:** a foundation of **40 Essence, 4 Iron Ingots, 2 Hafts and 2 Cord** includes Point, Edge, Maul, both fitting choices and ordinary refit. Ordinary processing, crafting, refit and fitting adjustment cost **0 Essence**. These are base quotes under the existing applicable staffing rules, not new personal approvals or measured balance results. The older 150-Essence foundation and extra ordinary recipe-tier tolls are replaced for future construction; existing paid progress remains recorded.

### Useful Hafts and collars, with no circular unlock

Maud's recruitment teaches the Haft recipes. Fen can then make them at the built Bowyer **before** the Weaponsmith foundation needs them. Building the Weaponsmith teaches the Collar recipes; Armoury construction also teaches the same Iron Collar recipe, so Bracken does not require Maud. Knowledge stays saved if its producer is not built yet. Existing legitimate trade can also supply prepared parts without granting a missing facility tier or inventing merchant stock.

| Prepared material | Maker and access | Ingredients | Quality and sale / buy |
| --- | --- | --- | --- |
| Softwood Haft | Bowyer; Maud recruited | 1 Softwood Log | Ungraded; 1 / 2 Gold |
| Hardwood Haft | Bowyer; Maud recruited | 1 Hardwood Log | Ungraded; 1 / 2 Gold |
| Iron Collar | Blacksmith T2; Weaponsmith or Armoury built | 2 Iron, 1 Coal | Ungraded; 4 / 8 Gold |
| Bone Collar | Built Weaponsmith | 1 eligible typed Bone | Same Bone quality and actual recorded value; buy twice |

A Haft is a shaped handle or shaft component; a Collar secures the fitted assembly. The Log's type and colour stay recognizable. Bone Collar preserves its exact Bone source, band and colour without applying quality twice or inventing a new skeletal subtype.

Iron Collar casts directly from Iron and Coal, avoiding an extra Iron→Ingot→Collar chain. No new kiln, workshop, timer or anonymous fitting token is required. These prepared parts have real consumers below; Planks still wait for a named use. Early Forge weapons/tool upgrades keep their raw-Log recipes, and Longbow limbs keep their own Hardwood construction.

### All four families and every Polearm damage choice

Choose one alternative within each listed part. Every other part in that row is required. The Collar choice is always one actual prepared Iron Collar or Bone Collar.

| Weapon | Working part | Handle/shaft and wrapping | Collar |
| --- | --- | --- | --- |
| Fitted Point — Pierce/Close | 2 Ingots **or** 2 Quartz **or** 1 Bone | 1 Softwood/Hardwood Haft; 1 Cord **or** 1 Leather | 1 Iron **or** Bone Collar |
| Fitted Edge — Rend/Close | 2 Ingots **or** 1 Bone | Same choices | Same |
| Fitted Maul — Crush/Close | 2 Ingots **or** 2 Bone | 1 Hardwood Haft; 1 Cord **or** 1 Leather | Same |
| Fitted Polearm — Pierce/Mid | 2 Ingots **or** 2 Quartz **or** 1 Bone | 2 Hardwood Hafts; 2 Cord **or** 2 Leather | Same |
| Fitted Polearm — Rend/Mid | 2 Ingots **or** 1 Bone | Same Polearm shaft/binding | Same |
| Fitted Polearm — Crush/Mid | 2 Ingots **or** 2 Bone | Same Polearm shaft/binding | Same |

Polearm additionally requires **Maud's existing fitting-pattern diary teaching**. Knowing it before building the shop stays valid; building alone does not grant that teaching. Its three damage choices are one family, not three paid patterns. Choose the damage kind before selecting its head; material overlap never silently picks the best matchup.

Two Bone pieces may differ in quality, Density, colour and source; two Leather bindings may also differ. The two Hardwood Hafts form a reinforced shaft assembly and need not match colour. Prepared textiles keep their actual mixed strands and sections. No hidden numerical threshold asks for another unrelated sample to make a pictured component valid.

### Two clear fittings using existing combat stats

| Fitting choice | What it adds |
| --- | --- |
| **Balanced** | +1 Initiative |
| **Driving** | +0.75 Power |

Both use the same recipe parts and price. The choice is between these benefits, with no hidden penalty, wearer lock or new attack-speed system. Driving does not inherit a second automatic bonus from the older specialty rules.

Working Power uses the same starting values as Forge: **2.5 for Ingots**, **2.25 for Quartz points**, or **4 × (0.5 + actual Bone Density ÷ 200) × the Bone quality multiplier**. Average multiple Bone pieces within the working part, add any Driving contribution, and round the final result once to the nearest quarter. Ordinary one-decimal display remains; Power is not guaranteed final HP loss.

Hafts, wraps and collars supply structure, source appearance and the designated workmanship contribution. They add no unlisted combat bonus or automatic coating. Workmanship uses the accepted 70% working-part / 30% structural-support rule. Supports are three equal groups: Haft assembly, wrap/binding assembly and Collar. Ungraded parts count as Fine; Bone/Leather use their actual ranks. Raw ancestors do not vote again, and ordinary crafting never produces Peerless.

For example, an all-metal Fitted Point is **2.5 Power and +1 Initiative when Balanced**, or **3.25 Power with no added Initiative when Driving**. It is Fine either way. Common Bone with Density 60 and a Common Bone Collar gives **3.25/+1 Balanced** or **4.0/0 Driving**. With Exceptional Bone at Density 80 and an Exceptional Bone Collar, those values become **5.5/+1** or **6.25/0**, with Exceptional workmanship. An expensive source or colour choice cannot imply an extra damage bonus absent from the preview.

These are first-pass equipment comparisons, not completed combat balancing. Existing melee targeting, damage matchups, formation, skill and turn-order rules stay unchanged. All four physical families use the accepted **one-weapon, one-excursion coating** lifetime, with target afflictions retaining their own durations. No one-strike exception or free intrinsic status is added.

### Prices, recovery and ordinary refit

New weapon sale value is the sum of the actual recoverable components' recorded values; buy price is twice that, as in the other completed shops. The fitting choice itself adds no price multiplier.

| Full route using Cord wrapping/binding | New sale / buy |
| --- | --- |
| Ingot Point, Edge or Maul with Iron Collar | 14 / 28 Gold |
| Quartz Point with Iron Collar | 18 / 36 Gold |
| Ingot Polearm, any kind, with Iron Collar | 16 / 32 Gold |
| Quartz Pierce Polearm with Iron Collar | 20 / 40 Gold |
| Single-Bone Point/Edge with same-band Bone Collar | Poor/Common/Rare/Exceptional sale 6/10/18/34; buy twice |
| Two-Bone Maul with same-band Bone Collar | Sale 8/14/26/50; buy twice |
| Single-Bone Pierce/Rend Polearm with same-band Bone Collar | Sale 8/12/20/36; buy twice |
| Two-Bone Crush Polearm with same-band Bone Collar | Sale 10/16/28/52; buy twice |

Different bands use their actual individual values. Replacing Cord with Leather changes the price by the real replacement value, including older Leather's frozen price; it does not reprice the entire weapon by its finished grade.

Dismantling returns exact selected working materials, Hafts, wraps/bindings and Collar once. Hafts stay Hafts and Collars stay Collars; their original Logs, Iron, Bone or fuel do not also return. Other prepared stock similarly keeps its complete receipt without an extra ancestor refund. No reverse-processing service is added for loose Hafts/Collars. Owned older gear keeps its existing values and supported recovery/service rules.

At Home, ordinary refit replaces a complete selected component, pays the new inputs and returns the old recoverable part once. The exact weapon, family, damage kind, reach and supported inscriptions/custody remain. Final stats and price are recalculated from its final parts; repeated refits do not stack bonuses.

**Balanced↔Driving can be adjusted at Home for no Essence or new materials**, using the existing complete construction. This preserves quality, sources, price and item identity. It is not available mid-encounter. Polearm's damage kind stays fixed through refit; a different kind requires explicitly crafting that known variant. Old items without a compatible record are not given invented new components or a free modern fitting.

### Progression and implementation still needed

Ingots come from Forge T2, Cord/Leather from Tannery, Hafts from Fen and the new Collars from their named existing makers. All four families have an animal-free metal route. Softwood is enough for the first fitted Point/Edge; Maul and Polearm require Hardwood Hafts, with the existing Axe-2 small-Hardwood route sufficient.

A full base-price production route through Forge T1/T2, Corrin, Fen, Weaponsmith and one all-metal fitted Point totals **130 Essence, 30 Iron, 7 Coal, 23 Logs, 18 Fibre, 8 Clay and 2 Resin**. After the shops exist, that Point/Edge needs expanded raw **6 Iron, 3 Coal, 1 Log and 2 Fibre**. These totals include intermediate preparation but exclude search, recruitment and Binding costs; they are staged options, not an opening checklist or affordability playtest.

**Still needed:** implement the four prepared-material routes, actual event-owned knowledge, complete new recipe/fitting calculator, combat projection, trade/recovery/refit and legacy routing. No individual recipe approval is needed from Aimee for this first pass. Mote/Peerless and wider creature-anatomy work remain the existing grouped questions. **Armoury is the next complete shop batch.**

## Armoury — the complete protective-rebuild first-pass plan

**Current behavior:** Bracken already has a protective rebuild screen and Rigid Shell, Insulated Layer and Balanced Laminate profiles. Older routes use broad material families, six-band calculations, profile offsets and selected-sample insulation. The complete new plan below is **pending implementation**.

**Retained decisions:** rebuild one existing ordinary physical protective piece while keeping its identity, supported inscriptions, slot and ownership. Profiles are defensive choices, not quality ranks. Unique/apex/narrative gear, magical housings, weapons, field tools and keepsakes are excluded. Worn equipment can remain on its existing wearer when the legitimate Home service supports it. Unsupported old construction/upgrade records retain their existing service paths rather than having missing history guessed.

### Every supported profile and slot

| Slot | Rigid Shell | Insulated Layer | Balanced Laminate |
| --- | --- | --- | --- |
| Offhand shield | Yes | No | Yes |
| Head | Yes | Yes | Yes |
| Body | Yes | Yes | Yes |
| Hands | Yes | Yes | Yes |
| Feet | Yes | Yes | Yes |

These are **14 supported combinations**. The existing Insulated offhand exclusion stays: a carried shield does not become an Insulated worn layer. A rebuild cannot turn boots into a Helm or add another equipment slot. The piece keeps its name/origin history, with its current profile and real materials shown separately.

**New Design-authored first-pass choices:** the Armoury foundation is **35 Essence, 4 Ingots, 2 Cloth and 2 Cord** after recruiting Bracken. All applicable profiles and ordinary component refit are included. Rebuilds/refits cost **0 Essence**, with no extra profile research fee, Study, attending-keeper or new shop-tier requirement. Existing applicable construction/staffing rules still govern the base quote; old paid progress is preserved. These choices are not newly attributed personal approvals or completed balance tests.

Armoury construction teaches the **same Iron Collar recipe at Forge T2** as Weaponsmith construction: 2 Iron and 1 Coal make 1 Collar. This gives Balanced a complete metal route without requiring Maud. Bone Collar remains Maud's optional alternative. No new facility or duplicate material is introduced.

### Complete construction materials

Body uses the large recipe. Other allowed slots use the small recipe. Choose one listed alternative within each part; every other part is required.

| Profile and size | Structural outer | Lining | Binding | Fitting |
| --- | --- | --- | --- | --- |
| Rigid Body | 4 Ingots **or** 4 Bone | — | 2 Cord **or** 2 Leather | — |
| Rigid other slots | 2 Ingots **or** 2 Bone | — | 1 Cord **or** 1 Leather | — |
| Balanced Body | 2 Ingots **or** 2 Bone **or** 2 Leather | 2 Cloth | 2 Cord **or** 2 Leather | 1 Iron **or** Bone Collar |
| Balanced other slots | 1 Ingot **or** 1 Bone **or** 1 Leather | 1 Cloth | 1 Cord **or** 1 Leather | Same |
| Insulated Body | 2 Cloth **or** 2 Leather | 2 Cloth | 2 Cord **or** 2 Leather | — |
| Insulated Head/Hands/Feet | 1 Cloth **or** 1 Leather | 1 Cloth | 1 Cord **or** 1 Leather | — |

Every profile has an animal-free route. Cloth supplies the actual lining; the plan does not wait for an invented Pelt/Down producer or require an unrelated “insulation sample.” Bone and Leather pieces may differ in quality, measurements, colour and source. The actual Tannery textiles retain their mixed strands/sections. A piece cannot supply both an outer and a binding unless the owned quantity really supports both allocations.

### Protection and Heat Ward tradeoffs

These are the **complete new Protection results**, not bonuses added to the item's old statistics.

| Profile / outer material | Body Protection | Other allowed slots |
| --- | --- | --- |
| Rigid Ingot | 3.25 | 2.0 |
| Rigid Bone | Source formula with ceiling 4.5 | Ceiling 2.5 |
| Balanced Ingot | 2.5 | 1.5 |
| Balanced Bone or Leather | Source formula with ceiling 4 | Ceiling 2 |
| Insulated Cloth | 2.0 | 1.0 |
| Insulated Leather | Source formula with ceiling 3 | Ceiling 1.5 |

For Bone, the source formula is **ceiling × (0.5 + actual Density ÷ 200) × quality multiplier**. Leather uses its preserved covering protection—hardness × coverage ÷ 100—in place of Density. Poor/Common/Rare/Exceptional multipliers stay 0.75/1/1.25/1.5. Average several outer pieces' contributions, then round the final total once to the nearest quarter. Do not create averaged raw material or add the old item's Protection again.

The actual Cloth-lined construction gives these fixed **Heat Ward percentage points**:

| Profile | Shield | Head | Body | Hands | Feet |
| --- | ---: | ---: | ---: | ---: | ---: |
| Rigid | 0 | 0 | 0 | 0 | 0 |
| Balanced | 5 | 8 | 15 | 5 | 5 |
| Insulated | Unavailable | 15 | 25 | 10 | 10 |

Heat Ward uses the existing Heat emanation damage rule. This plan does not change Burn ticks, weather exposure or other damage types. It adds no new resistance stat or immunity.

**A lining counts once.** New Armoury pieces use Heat Ward without also adding the same lining to the older insulation calculation. Other old equipment keeps its recorded behavior. Equipment Heat Ward still caps at **50 points**, and the existing combined heat mitigation calculation with legacy insulation retains its **60% cap** and existing skill rules.

Examples make the choices clearer:

- An Ingot Rigid Body gives **3.25 Protection / 0 Heat Ward**; Balanced gives **2.5 / 15**; an all-Cloth Insulated Body gives **2.0 / 25**.
- Common Bone at Density 50 gives **3.5 / 0** as Rigid Body or **3.0 / 15** as Balanced.
- Common Leather at covering protection 50 gives **3.0 / 15** as Balanced Body or **2.25 / 25** as Insulated. An older Leather Guard may already have 3.25 Protection: the comparison must show the trade, not promise that every rebuild increases every stat.
- At the ordinary world-material values, five Rigid pieces total **11.25 Protection / 0 Ward**; five Balanced pieces total **8.5 / 38**.
- Insulated Body, Head and Hands with Rigid Feet and shield total **8.0 Protection / 50 Ward**. Making the Feet Insulated too drops Protection to 7.0 without improving the capped Ward; the extra ten points are already covered.

These are first-pass arithmetic, not completed encounter balancing. The actual before/after view must show the wearer's resulting totals, including the cap, so a mixed set can be a deliberate choice.

### Quality, prices and exact recovery

Workmanship keeps the accepted 70% structural outer / 30% designated support rule. Rigid's support is its binding; Balanced's supports are lining, binding and Collar; Insulated's are lining and binding. Ungraded Cloth/Cord/Ingot counts as Fine, while creature-derived parts use their actual bands. Multiple units do not gain extra group votes. No ordinary rebuild creates Peerless or applies quality twice to combat stats.

New sale value is the sum of the actual recoverable components' recorded values, and buy price is twice that. No profile or finished-grade premium is added. Existing cheaper Leather stays at its actual old value.

| Full world-material route with Cord binding | Body sale / buy | Other allowed slots sale / buy |
| --- | --- | --- |
| Rigid Ingot | 18 / 36 Gold | 9 / 18 Gold |
| Balanced Ingot with Cloth lining and Iron Collar | 18 / 36 Gold | 11 / 22 Gold |
| Insulated Cloth outer and lining | 10 / 20 Gold | 5 / 10 Gold |

A full rebuild uses the complete new recipe and **returns the outgoing active construction's recoverable parts once**, keeping the same item. The quote may explicitly reuse those parts, accounting for each once. Its old sale value is not another ingredient or a hidden Gold refund.

The item's history can remember previous versions, but dismantling later returns **only the currently attached components**. It cannot refund old parts already returned by an earlier rebuild. Cloth, Cord, Leather and Collars return as their exact prepared units; their original Fibre, Hide, Salt, Iron, Bone or fuel do not also return. No old base item is duplicated.

Ordinary component refit replaces one complete part while preserving profile and slot. Changing Rigid/Balanced/Insulated is a full rebuild using the destination recipe; it is not a free toggle because the construction changes. Failed or stale transactions spend nothing and return nothing. Existing overflow custody remains safe, and active excursions are not rewritten by a Home recipe update.

Old legacy credits, bought Reforge work, unsupported construction records and special gear are not silently erased to enter the new path. They keep their existing supported services. The later equipment-improvement batch must reconcile those services with Peerless; no new personal approval checklist is created for ordinary new-profile equipment.

### Practical progression and remaining work

The foundation's prepared materials expand to **8 Iron, 4 Coal and 12 Fibre**, plus 35 Essence. Including Forge T1/T2 and Corrin's foundations gives **95 Essence, 24 Iron, 4 Coal, 14 Logs, 20 Fibre and 8 Clay**, before the chosen base item/rebuild and any recruitment/search/Binding costs. Bracken does not require Fen or Maud for ordinary profiles.

After those shops exist, an Ingot Rigid Body recipe expands to **8 Iron, 4 Coal and 4 Fibre**; Balanced Ingot Body to **6 Iron, 3 Coal and 12 Fibre**; an all-Cloth Insulated Body to **20 Fibre**. These are complete destination recipes; the exact old parts being returned or reused are quoted separately. They are staged options, not a required full wardrobe or an affordability playtest.

**Still needed:** implement the complete typed rebuild calculator, all 14 supported choices, current-versus-historical component ownership, new/legacy Heat Ward projection, shared Collar knowledge, refit/recovery and durable custody. No individual profile/material approval is needed from Aimee for this first pass.

The six ordinary maker plans are now specified. **Next is the complete equipment-improvement/recovery service plan**, including retained legacy Reforge and eventual Peerless. The real existing owner question remains the experience when a Mote-funded partial attempt misses; the recommendation is lasting progress without destruction or downgrading. That answer does not gate these ordinary shop plans.

## Every remaining shop and crafting system

The sequence below follows material dependencies. It includes services and processing that do not appear as ordinary recipe cards.

| System | Complete scope of its batch | Main correction or dependency |
| --- | --- | --- |
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
