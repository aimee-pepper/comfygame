# Distillery — complete first-pass production contract

**6 September 2026 · Game Design.** Accepted direction plus clearly identified Design-authored first-pass recipes and tuning. Implementation is pending. This is the whole three-attunement batch, followed by the complete Channelworks contract; not three isolated ingredient approvals. Existing player reports remain delivery authority. No native or phone checks were repeated by Design.

## 1. Current behavior and replacement boundary

Current `DistilleryRules` makes Heat, Caustic and Light Cores directly for **16 Essence**, a catalyst and one qualifying individual property sample. Heat uses Sulfur2 and Reactivity60/Insulation25; Caustic uses Toxin2 or Ichor1 and a qualifying Reagent/Toxin/Ichor sample with Reactivity60; Light uses Silver2 and Lustre60/Hardness30. Current potency is respectively rounded .65 Reactivity + .35 Insulation, Reactivity, or .65 Lustre + .35 Hardness. The current Channelworks consumes one valid player-made Heat Core into a stored fixture; neither that conversion nor story restoration proves an equipped combat weapon exists.

**Accepted retained:** direct 16-Essence attunement, named actual materials, Heat/Caustic/Light only, finite Core items, Auber makes Cores/Oda makes housings. No Blank Core or crystallisation prerequisite. Refinery conversion remains separate. No second Essence currency, material-property scavenger hunt, universal Reagent/Toxin, waste/residue stock, timer, failure roll, mana or ammunition.

The new recipes and fixed new-Core potency below replace the old qualifying-sample mechanics for new production. Existing Cores keep their actual saved potency, inputs, recipe version, quantity and value. Existing Essence Crystals used by the real wallet are currency; never delete or relabel them as obsolete blank crafting intermediates.

## 2. Foundation and complete recipes

**Design first pass:** after Auber is recruited, build for **60 Essence + 4 Iron Ingots + 4 Quartz + 6 Clay**. The completed shop teaches all three direct recipes. No separate Heat/Caustic/Light Research fee, repeat unlock, attending-Auber prerequisite or paid potency-preview tier. These are base costs before any existing applicable foundation modifier; do not invent a new discount. A built internal tier0 is usable. Preserve previously built shops and learned recipes without charging the new foundation or refunding old construction.

| Recipe / retained item ID | Exact inputs for one Core | Essence | New output |
| --- | --- | ---: | --- |
| Heat Core / `heat_core` | 2 Sulfur + 1 World Resin | 16 | Heat, potency60, clear |
| Caustic Core / `caustic_core` | 2 Toxic Sap + 1 Salt | 16 | Caustic, potency60, clear |
| Light Core / `light_core` | 2 Silver + 1 Quartz | 16 | Light, potency60, clear |

No extra sample, Quartz for Heat/Caustic, Clay vessel, Glass, fuel or Mote is consumed. Ingredients are physical units with true source custody. Salt is the stabilising carrier in the Caustic recipe, not a cure applied to the final Core. Recipe chemistry is an authored game property, not inferred from RGB or a generic Reactivity score.

**New potency is fixed first-pass tuning.** These named world/flora materials are ungraded. Every valid new recipe yields potency60, retaining the existing 0–39 faint /40–64 clear /65–84 strong /85–100 brilliant labels for saved Core compatibility. Do not synthesize old six-property samples or a creature-quality roll to make the old formula accept these inputs. Mixed source colours do not alter potency, attunement, reach or affliction identity. Potency remains a real housing input, including the authored starter40 and valid older saved values; future higher-potency recipes require a named design, not a hidden quality lottery.

The previously suggested Creature Oil alternative to World Resin, and Irritant Spore/Venom/Ichor alternatives for Caustic, remain **unavailable extensions** until their actual producer and relevant processing are defined. They do not gate the complete Resin/Toxic Sap route and are not shown as purchasable or selectable missing ingredients. Existing old Reagent/Toxin/Ichor stock is preserved in its supported uses; no automatic name-based conversion to Toxic Sap, Resin or a new Core.

## 3. Actual producers and progression

Use the existing shared source contracts, not new bonus spawns:

- **Iron Ingots:** Forge T2; 2 Iron +1 Coal →1 Ingot. No Silver or Distillery dependency in the Forge route.
- **Quartz:** Apothecary mineral producer; Substrate peak≥38 and hard form≥30. Pick2, two successful pulls of2, total4 per node.
- **Sulfur:** shared producer; Substrate volatile≥22 and Thermal peak≥50. Pick2, two pulls of2, total4.
- **World Resin:** the established physical world/flora Resin route; use its real source receipt and current finite yield. No Creature Oil or generic Reagent adapter is needed.
- **Toxic Sap:** the Apothecary's explicitly sap-producing toxic flora profile, `flora.part.sap.toxic`; retain its exact anatomy/host/harvesting rules and shared named-preparation flora pool. This is actual sap, not any colourful or high-reactivity plant.
- **Salt:** existing finite hand-gathered Salt Crust, no Pick requirement or extra container.
- **Silver:** add/complete the physical producer `world.silver` using the existing mineral definition: Substrate peak≥45 and ductile form≥25; preference for valuable tag and dispersion≤40. Preference is not an additional eligibility gate. Pick2; two pulls of2, total4. Its occurrence group is the accepted uncommon/Pick2 material group, while its existing nominal trade policy remains separate. Use ordinary mineral-node budgets and lawful written-source promises; no bonus nodes or universal presence. Do not copy a legacy trade rarity into the harvest requirement.

Each node remains one actual resource placement per tile. Quote the real source/tool requirement; an insufficient tool spends no turn and depletes nothing. Preserve legitimate old scalar stock through explicit supported ownership adapters without double-counting typed and scalar quantities. No fake source appearance or measurements are manufactured for old stock.

Auber can be built after Forge T2 and Pick2; Heat/Caustic are usable without Silver, and Light follows an actual Silver source. Oda's restored Heat Conduit supplies the earlier introduction independently of Auber. Do not reorder either traveller's recruitment clues or invent a guaranteed visit. Distillery recipe knowledge names the Channelworks dependency. Promote a Core as a practical weapon goal only when its corresponding equippable housing is delivered; existing lawful Core production may remain visible honestly as stored preparation.

## 4. Transactions, appearance and value

Quote one attunement, exact selected input lot IDs/quantities, 16 real Essence, resulting potency/identity, full source history and destination. Select by existing persisted inventory order by default; allow source choice when provenance, appearance or price differs. Re-evaluate the exact quote, actual built-shop state, currency and material custody at commit. Spend all inputs and Essence and persist one output atomically before success. Failed/stale/cancelled actions spend nothing. Use safe Storehouse/claimable Waiting where supported; otherwise refuse before paying. No automatic field packing, use, equip or sale.

Cores have their attunement's recognizable presentation. Actual input colour/Pattern is retained in source history, including Aimee's flora clarification, but attunement colour is not a mixture of catalyst pixels. A Core's saved potency and full inputs transfer into the housing when consumed; history is not a second inventory Core.

**First-pass new nominal value:** Core sale value = 16 + the sum of the actual consumed ingredients' frozen nominal sale values; buy value = twice that Core sale value. This records the real Essence committed without allowing a sale at a higher value than total nominal inputs. Existing discount rules must not create a resale arbitrage; the attunement charge remains the accepted exact16. Old Core prices remain unchanged. Cores are not independently dismantlable into Essence, catalysts or samples. No fractional unused Core, catalyst residue, recyclable wallet payment or free refill is produced.

Stack equivalence requires the same attunement, potency, output-policy/value and equivalent displayed source facts; keep the actual underlying receipts when presentation groups quantities. Never lose a high-potency old Core in an apparently equivalent60 stack or consume a different selected unit. The Channelworks accepts an explicitly validated old recipe1 Core or new versioned named-input Core; its current strict recipeVersion==1 gate must be extended with the real new receipt validator, not weakened to catalog name alone.

## 5. Closed scope and connected examples

**Foundation plus one Heat Core:** 76 Essence,4 Ingots,4 Quartz,6 Clay,2 Sulfur,1 Resin. Expanding Ingots:8 Iron,4 Coal,4 Quartz,6 Clay,2 Sulfur,1 Resin. **Foundation plus one of each Core:**108 Essence,4 Ingots,5 Quartz,6 Clay,2 Sulfur,1 Resin,2 Toxic Sap,1 Salt,2 Silver. Other facilities, recruitment, travel and Binding are separate costs; these examples do not assume full-map harvesting or fixed excursion income.

Infusion remains a later direction without a named traded-off item consumer. Omit its service/research button; do not create generic +1/reforge ranks, hidden potency upgrades or a fourth attunement. Spent Emanation Housing remains its own existing site, not a Core mine or mandatory schematic source. No extra Aimee approval question is needed for this complete first pass.

Engineering's bounded cases: all three exact recipes consume once and produce60; no old property gate survives new inputs; poor/exceptional creature labels or input RGB cannot change new potency; valid legacy40/80 Cores keep their values; correct Essence wallet, stale/save failure and full storage preserve ownership; named Silver/Toxic Sap source → harvest → Return → selected Core is complete; one Core transfers into one real matching housing without a duplicate receipt item. Use ordinary focused implementation tests and native owner checks, not another Design audit or phone run.

This contract supersedes the old Distillery implementation document and the Distillery recipe proposals in the 5 September batch. The companion **Channelworks whole-system production contract** owns all nine housings, permanent attacks, one-time restoration, retuning and dismantling.

## Conditional anatomy extension — separate first-pass proposal

[Remaining creature anatomy/material uses](creature-anatomy-material-extensions-v1.md) now defines narrow optional uses for actual typed parts, including exact eligible sockets, measures, stats, workmanship, colour and recovery. Its new anatomy producers and adapters are not implemented. This complete ordinary batch stays independently implementable; generic legacy family names cannot satisfy the new alternatives. The extension does not make every fluid an Oil/Venom/pigment, add one-strike coatings, or replace any existing world/flora route.
