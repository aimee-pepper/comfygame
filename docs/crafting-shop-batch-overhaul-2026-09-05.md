# Crafting overhaul — complete shop batches

> **Apothecary production closure:** `apothecary-whole-shop-production-v1.md` now supersedes this audit’s proposed Apothecary recipes, unnamed chemical-source placeholders and source-choice gate. It contains all 19 exact recipes and six named plant profiles plus four mineral source contracts. This audit remains the all-shop scope and historical contradiction review; later shop tables remain their own work.

5 September 2026. Design review and implementation direction, not an implementation delivery.

## Authority and disposition

Aimee directed Design to audit all crafting changed so far, then overhaul whole shops in order: Apothecary, Blacksmith, Tannery, then their dependent systems. This replaces isolated next-recipe assignments. Costs and order are tuning owned by Design; routine ingredient and pricing decisions do not require individual Aimee approvals.

Keep completed work. Engineering reports Briar Oil at 2188a0fb in phone310; no Venom or Bone adapter has been implemented. That report is the delivery authority; Design has not repeated native or phone verification. Source inspection below describes rules and gaps, not proof of natural acquisition or a complete playable overhaul.

The Briar and Venom adapter documents preserve interim rules. Their “ready” wording must not authorize a new isolated recipe assignment. In particular, preserving current one-hit coatings in an input-only change never supersedes the accepted excursion-long coating design. The proposed two-Bone blade is absorbed into the Blacksmith batch, not approved by this audit.

## Findings that change the work

1. **Apothecary has 19 recipes, not 17.** Seamlight and Scent Mask belong in the same source, progression, inventory and pricing review as remedies and coatings. Migrating only Fibre users leaves the shop dependent on unrelated property samples and uncertain sources.
2. **Coating lifetime contradicts the intended design.** All four currently use a charge on a successful strike. The accepted destination is exactly one world excursion, bound to that weapon/world, surviving encounters and relaunch. Preserve status payloads and their own durations separately. This is a shared system correction, not four recipe edits.
3. **Physical roles must replace eligibility thresholds.** An insulating stone should not qualify as medicine merely because its bar is high. Properties may affect a real output stat; they are not the final ingredient vocabulary. Briar's Flexibility 50 and Venom's proposed Reactivity 55 are temporary compatibility conditions.
4. **Old six-band gear arithmetic is not the new quality model.** World/flora materials are ungraded; creature parts have four bands; workmanship and actual Power/Protection are separate. Do not derive Power from quality and multiply by material quality again. Old quality-priced Essence fees must not leak into ordinary new crafts.
5. **Processing and starter gear need one progression.** Keep raw-material starter Iron gear before ingot making at Forge T2. Cord, Cloth and Leather are real stock. Later specialists may require those prepared parts. Do not make every early craft wait for every specialist.
6. **Named stock and ownership remain unresolved in several shops.** Legacy scalar Toxin, Reagent, Fibre and Timber cannot be silently relabelled as new physical units. Distinct sources with the same label are not interchangeable balances. Finished Venom is not raw venom.
7. **Resale and salvage need batch economics.** The Bone-only resale suggestion and Leather's full prepared-component recovery cannot establish unrelated global price rules. Reforge/refit/recycle must never manufacture raw Hide plus Leather, fees, or duplicated component histories.
8. **Some “current” documents are historical.** Blank Core manufacture in the old Distillery document is superseded by direct 16-Essence attunement. The 21-schematic catalogue includes seven Blacksmith families outside the current live list. Source-defined recipes are not automatically playable.

## Complete scope and dependency order

| Batch | Complete scope | Status and dependency |
| --- | --- | --- |
| 1 Apothecary | 19 preparations below; all four coatings; discovery, batch preparation, packing, use and trade | Lesser Salve/new plant materials and Briar have delivered paths; rest includes old recipes. Whole-shop replacement below is proposed tuning. |
| 2 Blacksmith | 8 schematic families; starter Iron blade; Pick/Axe/Scythe upgrades; ingots; shop T2; future Glass | Only Pointed Blade is in the legacy live Blacksmith list. Other seven catalogue families require explicit implementation. Tool identity/progression must be reconciled with Field Pick. |
| 3 Tannery | Cord, Cloth, Leather; Woven/Buckled/Leather Guards; early Gloves/Boots; 3 legacy flexible gear families; carrying upgrades | Delivered early paths coexist with legacy sample-based families. Prepared stock is the downstream contract. |
| 4 Bowyer and Weaponsmith | Longbow, Sling, Throwing Set; Fitted Point/Edge/Maul/Polearm | Close after Blacksmith roles and Tannery stock; all variants in each shop move together. |
| 5 Armoury and equipment services | Rigid, Insulated, Balanced rebuilds over five protective slots; reforge, refit, Peerless refinement; salvage of all gear above | Depends on one stat/quality/identity contract; Mote-on-miss experience is the real open Aimee decision. |
| 6 Field Instruments | Eight instruments, each Crude→Good→Fine: 16 improvements | Replace property-only inputs as a complete set; retain owned instrument and precision identity. |
| 7 Scriptorium / Writing Desk | CMY+Depth ink; personal Compound formalization; Seamward install/erase; later Paper/Pulp/pigments and inscription consumers | Preserve authored Writing effects and current separate service recipes. Later Lantern/Light presentation requires Engineering's exact consumer. |
| 8 Distillery / Channelworks | Heat/Caustic/Light Cores; Heat Fixture construction and story restoration; proposed three attunements × three reaches | Raw Essence refining is a different system. Do not spend effort making unsupported Light/Caustic weapon promises. |
| 9 Anchorage | Six-component Anchor Frame; assignment/anchoring services | Requires actual supported component categories and current world/portfolio ownership. |
| 10 Processing / economy / access | Essence Spring, Recycler and Rubble sorting; Fen's Planks/Hafts; Isolde's Paper/Pulp/pigments; structural Blocks/Glass; foundations, research, staff effects, Storehouse/Waiting, carrying | Audit every new process with its consumers and acquisition route. Do not add an intermediate with no playable purpose. |

This scope includes authored and delivered early packets, the 21-schematic design catalogue, all rows in the Wiki crafting catalogue, and service actions omitted from that recipe array. Found equipment is not another crafting list. Deep Works/building research are access and processing dependencies, not permission to invent recipes for every station.

## Preventing deprecated rules from becoming new instructions

The coating failure was in Design scope selection: newer input packets explicitly told Engineering to keep an old runtime rule without reconciling the already accepted replacement. Existing implementation is evidence of current behavior, not authority for future behavior. We have not found evidence that Engineering implemented excursion-long coatings and then reverted them.

Before releasing an affected shop packet, compare its ingredients, effects/lifetimes, progression, identity and economy against the accepted Wiki decisions. For each old rule deliberately preserved, state either “still intended” or “temporary pending [named replacement].” If a conflict exists, correct the operative instruction, mark the older packet superseded and carry the accepted replacement into the shop handoff. A banner alone must not leave an actionable “keep deprecated behavior” instruction below it. Use the normal implementation acceptance cases for the replacement; do not add a separate audit framework or repeat phone delivery verification.

## Shared implementation contract

Each whole-shop release supplies: exact input IDs or an explicit category allowlist; per-unit quantities and source grouping; owned-item prerequisites; station/research/knowledge conditions; displayed output stats and price; currencies; output destination; migration and recovery behavior. A category must have a real producer before being offered as available. Until then mark the new recipe unavailable and retain its honest legacy path; never guess missing anatomy or turn scalar balances into attributed physical units.

Use explicit player selection where material source, colour or stats matter. A quoted unit cannot fill two sockets. Prepared items retain component identities and full source colour; standardized consumables retain their authored appearance and effects. History is non-spendable. Preserve distinctions through merge, Waiting, packing, Return, trade, reload and recycle. Save the complete deduction, output and history atomically before reporting success. Cancel, stale stock, save failure and replay produce no partial craft.

New ordinary preparation, processing and initial physical construction use the established zero-Essence direction. Keep named supernatural/service fees explicit; do not infer zero cost for research, buildings, instruments or refinement. Existing items keep frozen stats and existing prices until a deliberate versioned migration says otherwise.

Stat-bearing roles use the first-pass material rules: actual property contribution, creature quality multiplier once, then quarter-point rounding after summation. Primary ceiling 4, secondary ceiling 2; handling uses Initiative only where there is a meaningful handling effect. Workmanship uses the separate 70/30 role weighting and ungraded Fine baseline; no ordinary craft creates Peerless. Do not introduce incidental bonuses merely to give every grip a stat.

Economy acceptance covers each new shop as a connected graph: buy inputs → process → craft → sell or salvage → recraft. Recoverable outputs must never exceed the paid inputs' value through a cycle. Raw purchase is twice raw sale under the new registry; legacy scalar prices remain legacy. Ordinary consumable sale values remain Common 2, Uncommon 5, Rare 10, Mythic 20, with normal merchant availability rather than a promised stock source. Do not automatically copy that pricing policy to gear.

## Batch 1 — Apothecary

### Current and proposed catalogue

All rows yield one preparation. Current “sample” means a distinct qualifying exact material in addition to listed stock; it is not merely a description of that stock. Ordinary fees are 0 Essence; Stillwater costs 6, Waystone costs 12 plus 1 Mote. Effects below are authored base effects, not a guarantee against cures, prevention or actor modifiers.

**Proposed whole-shop recipe tuning:** the right column removes unrelated property samples and gives each recipe a short material explanation. This is Design's consolidated proposal, not an approved or delivered all-new-material catalogue. Existing typed Resin, Logs, Stem/Leaf Fibre, Cloth, Quartz and Salt should use their established physical owners. Entries marked * need the named chemical/flora/creature source catalogue closed by Design before final physical implementation; keeping a legacy name here does not create that new source. Counts are tuning, not homework.

| Preparation | Current recipe (plus fee above) | Output role / base effect; sell Gold | Proposed batch recipe |
| --- | --- | --- | --- |
| Seamlight | Quartz 1, Resin 1, Fibre 1 | Portal guidance; 5 | Quartz 1, Resin 1, Stem/Leaf Fibre 1 |
| Scent Mask | Reagent 1, selected Hide/Pelt/Down/Oil 1 | Scent interference, base 12 world turns; 2 | Named masking substance* 1, compatible scent-bearing creature portion* 1 |
| Lesser Salve | New route: Resin 1, Stem/Leaf Fibre 1. Old: Resin 1, Flexibility 25 sample | Heal 10; 2 | Keep new route: Resin 1, Stem/Leaf Fibre 1 |
| Salve | Pulp 2, Spore 1, Resin 1, Insulation 40 sample | Heal 24; 5 | Cloth 1, Resin 1, medicinal Spore* 1 |
| Greater Salve | Ichor 1, Spore 2, Resin 2, Reactivity 60 sample | Heal 45; 10 | Cloth 1, Resin 2, medicinal Spore* 2, Ichor* 1 |
| Clearing Draught | Pulp 1, Salt 1, Reactivity 35 sample | Clear Poison and Bleed; 5 | Pulp* 1, Salt 1 |
| Quenching Draught | Reagent 1, Resin 1, Insulation 45 sample | Clear Burn and Dazzle; 5 | Named quenching substance* 1, Resin 1 |
| Broad Antidote | Ichor 1, Reagent 1, Spore 1, Reactivity 65 sample | Clear one affliction; 10 | Ichor* 1, neutralizing substance* 1, medicinal Spore* 1 |
| Stonebark Tonic | Timber 1, Resin 1, Hardness 45 sample | Prevent next affliction; 5 | Bark* 1, Resin 1; do not relabel a Log as harvested Bark |
| Venom | Toxin 1, Fibre 1, Reactivity 55 sample | Poison, base 2 damage / 4 boundaries; 5 | Eligible raw toxin* 1, Stem/Leaf Fibre 1 |
| Firebrand | Reagent 1, Sulfur 1, Reactivity 60 sample | Burn, base 4 damage / 2 boundaries; 5 | Sulfur* 1, Resin 1 |
| Briar Oil | Old Fibre 1, Resin 1, Flexibility 50 sample. Delivered new route uses Stem/Leaf Fibre and a separately selected Resin owner plus qualifying World sample | Bleed, base 2 damage / 3 boundaries; 5 | Stem/Leaf Fibre 2, Resin 1 |
| Flashsalt | Reagent 1, Mercury 1, Lustre 55 sample | Dazzle, base 2 boundaries; 5 | Salt 1, Quartz 1, light-reactive substance* 1 |
| Solvent | Reagent 1, Salt 1, Reactivity 40 sample | Identify a field curio; 5 | Named solvent substance* 1, Salt 1 |
| Lure | Toxin 1, Pulp 1, Reactivity 50 sample | Attract nearest roaming creature; 5 | Bait substance* 1, Pulp* 1; toxin is not automatically appetizing |
| Stillwater | Riftglass 1, Mercury 1, Lustre 60 sample | Restore Stability 25; 10 | Riftglass* 1, Mercury* 1, 6 Essence |
| Waystone | Riftglass 1, Hardness 70 sample, 1 Mote | Return with eligible haul; 20 | Riftglass* 1, hard Stone component* 1, 1 Mote, 12 Essence |
| Torch | Resin 1, Timber 2, Reactivity 30 sample | Journey illumination, base 2; 2 | Resin 1, Log 1, Stem/Leaf Fibre 1 |
| Farsight Draught | Quartz 1, Ichor 1, Lustre 50 sample | Reveal nearest site and surroundings, base 2; 10 | Quartz 1, Ichor* 1 |

Do not replace one universal “Reagent” with a different universal bottle. The chemical catalogue should answer which actual obtainable substances perform masking, quenching, neutralizing, solvent and light-reactive roles, and whether a substance legitimately supports several recipes. Medicinal versus irritant spores and bait versus toxin need explicit classifications. This is one content-authoring dependency shared with creatures/flora and Distillery, not seven questions for Aimee.

The proposed stronger Salves deliberately make Cloth useful after the immediate raw-fibre remedy. Keep Lesser Salve available without Corrin. If stronger healing arrives too late in play, tune Cloth access or quantities as a shop-level progression decision; do not strand healing behind an unrelated specialist chain. Core remedies and coatings should be learnable from their actual ingredients, without needing a sample that is never consumed by the final recipe. Preserve already learned recipes.

### Coatings: accepted implementation direction for all four

Prepare on the chosen eligible physical weapon using existing action/eligibility rules and consume one bottle. Bind the preparation to that exact weapon and current excursion. Successful hits apply the corresponding existing status; hitting, missing, defeating a target or ending an encounter does not consume the preparation. Existing status refresh/prevention/cure rules remain authoritative. No status is applied to an already defeated target.

Travel, swaps, storage transitions allowed by current gameplay, backgrounding and cold relaunch retain the same weapon-bound preparation within that excursion. It cannot jump to another weapon or a later world. Excursion completion, including Return or defeat ending the excursion, clears it exactly once. Migrate an existing active encounter coating onto that same weapon for the remainder of its current excursion; do not infer a preparation from inventory bottles. Replacing a coating uses one legal explicit preparation action, never stacks four effects silently. Keep Channelworks eligibility distinct.

Balance concern: excursion-long application makes coatings substantially stronger than one-hit bottles. Keep this accepted lifetime; tune effect strength or ingredient availability across all four after Engineering's focused gameplay comparison. Do not “fix” the balance by silently reverting lifetime, adding durability, or charging Essence to ordinary coatings.

### Acceptance and release dependencies

One Apothecary release must cover all 19 recipe definitions, knowledge/display, real-source selection and missing-ingredient text, multi-count atomic preparation, ordinary output custody, correct effect/use and pricing. At minimum: new campaign can make Lesser Salve without Corrin; Salve ladder has obtainable components; all four coatings survive encounter transitions/relaunch and expire on excursion end; cure/prevention behavior remains distinct; finished Venom cannot feed its recipe; same visible name does not merge legacy and physical owners; full storage sends output to Waiting; stale quote/save failure cannot lose materials or duplicate bottles.

Input migration and excursion lifetime may have separate code commits inside this shop batch, but do not issue another isolated Venom ticket. Author and implement the shared chemical-source table before advertising every new recipe as ready. Legacy bottles retain authored effects, value and custody; changed recipes affect future crafts only.

## Batch 2 — Blacksmith, whole family and tool plan

**Production closure:** `blacksmith-whole-shop-production-v1.md` supersedes the provisional choices and unfinished Forge role/value/tool tables in this audit. It supplies all eight family dispositions, T1–T3 and Pick-3 access, whole-shop Bone/metal mappings, new-gear recovery and deterministic refit. Older unchanged items and the audit history remain preserved.

Retain accepted early progression: stone Pick/Axe/Scythe in the dedicated tool roll; Halloway's 20 Essence / 8 Iron / 4 Fibre / 4 Logs foundation; starter Iron Pointed Blade and Pick/Axe improvements each 4 Iron + 1 Log + 2 Fibre + 1 Coal, zero Essence. Forge T2 costs 20 Essence + 8 Iron + 4 Clay + 4 Logs and makes 1 Ingot from 2 Iron + 1 Coal for zero Essence. Scythe improvement uses 2 Ingots + 1 Log + 2 Fibre. Do not move ingots back ahead of the first blade/Pick/Axe.

| Family | Catalogue construction / fixed role | Whole-shop disposition |
| --- | --- | --- |
| Pointed Blade | Point + grip; Pierce / Close | Keep delivered starter Iron route and honest legacy path. Review typed Bone as one allowed material role in this family, not a new recipe or automatic approval. |
| Cutting Blade | Edge + grip; Rend / Close | Define physical cutting-material list alongside Point; legacy definition is not live Blacksmith availability. |
| Hand Maul | Head + haft; Crush / Close | Use actual dense impact materials; shared raw handles before specialized Hafts. |
| Long Spear | Point + haft + binding; Pierce / Mid | Introduce reach and a binding choice after basic weapons; avoid simultaneous tool and specialist gates. |
| Shield | Face + brace + binding; Offhand protection | Define load-bearing face rather than accepting arbitrary hard samples. |
| Helm | Shell + lining; Head protection | Named rigid shell and comfortable lining; no invented insulation bonus unless it changes the actual ward stat. |
| Rigid Guard | Body ×2 + binding; Body protection | Compare role and Protection against Woven/Buckled/Leather Guard before release; no universally superior early duplicate. |
| Field Pick | Pick + weight + haft; hard-node tool | Resolve against the owned Pick upgrade route. Recommend one owned tool progression, with this schematic as customization/refit rather than a second contradictory extraction level. |

The seven families after Pointed Blade are catalogue scope, not a claim that their current selectors are reachable. Freeze their damage/reach/slot identities; author physical allowlists together from the material catalogue. Starter raw materials remain enough for the first tool/weapon successes; prepared Ingots, Hafts and Cord create later improvement choices rather than retroactively taxing starter recipes.

Apply the shared real-stat model to every typed component and set each family's role ceilings together. Bone's proposed Density-based point and neutral grip are reasonable candidates, but the 70/30 workmanship display must not imply that a better grip increases point Power. Resolve all family sale prices and recovery in one table before shipping typed Bone; the prior sum-of-two-inputs value is not global policy.

**Cases/dependencies:** existing owned tools improve without a second tool or lost level; T1 can make its starter blade before T2; T2 ingots have Scythe and Buckled Guard consumers; each damage/reach choice is fixed before materials; colour and source stay per component; old gear retains frozen stats; all eight families are explicitly labelled reachable or planned. Glass's two proposed routes (2 Sand + 1 Coal or 1 Quartz + 1 Coal → 1 Glass) wait for named consumers and ordinary Glass identity, never Riftglass.

## Batch 3 — Tannery and carrying

Corrin's accepted foundation is 20 Essence + 6 Logs + 4 Clay + 4 Fibre. Keep prepared stock physical and useful across shops.

| Operation | Accepted early inputs / output | Coherence requirement |
| --- | --- | --- |
| Plant Cord | 2 matching Fibre → 1 Cord, 0 Essence | Same Fibre type/colour grouping; preserve source portions. |
| Cloth | 4 matching Fibre → 1 Cloth, 0 Essence | Same rule; ingredient for stronger remedies and later makers. |
| Leather | 2 matching raw Hide subtype/band/colour/property groups + 1 Salt → 1 Leather, 0 Essence | Retain actual covering/flexibility and full source colour; no invented common Hide. |
| Woven Guard | Cloth 1 + Cord 1 → Fine, Protection 1.5 | Accessible first garment. |
| Buckled Guard | Cloth 2 + Cord 1 + Ingot 1 → Fine, Protection 2 | First cross-shop fitting, after Forge T2. |
| Woven Gloves | Cloth 1 + Cord 1 → Protection 1 | Keep early route distinct from old generic-sample family. |
| Woven Boots | Cloth 1 + Cord 1 + Resin 1 → Protection 1 | Same identity discipline. |
| Leather Guard | Leather 2 + Cord 1 | Existing early Leather stat calculation, quarter Protection, no hidden Initiative/ward. |
| Pack upgrades | Capacity 8→11: 5 Essence + Fibre 4; 11→14: 10 Essence + Fibre 6 + Resin 1; 14→23: Corrin, 20 Essence + Cloth 2 + Cord 2 + Resin 1 | Improve owned capacity; do not duplicate containers or automatically pack outputs. |
| Sela's extra capacity | Separate +2, 30 Essence + Logs 6 + Fibre 4 | Keep separate from Corrin's capacity sequence. |

The legacy catalogue also contains Supple Coat (outer + lining), Working Gloves (hand + facing) and Working Boots (upper + sole + binding). Reconcile these as later material choices within three clear wearable families; do not show two unrelated recipes with the same gloves/boots name and unexplained quality rules. Preserve existing items and all eight early operations above while the broader family mapping is authored.

Leather sale values 3/4/5/6 and Leather Guard 8/10/13/15 remain early-route values. Its existing recovery returns prepared Leather/Cord, never both raw Hide and Leather, and never Salt. Audit that full prepared-component recovery against the older partial Recycler rates across the full clothing set. Retain safe existing receipts; choose the final consistent recovery policy at the equipment-services batch, with visible before/after terms for new crafts.

**Cases/dependencies:** complete Woven→Buckled and Woven→Leather alternatives; no fabricated colour/property averaging across incompatible portions; manufacture then merge/reopen retains real material stock; salvage never reverses processing into extra raw units; keeping a good Hide for colour is a meaningful choice; higher workmanship labels do not secretly change two different stat formulae. Stronger Salve's proposed Cloth consumer requires the Apothecary batch to be coordinated here.

## Batches 4–10 — complete remaining system packets

### Bowyer / Weaponsmith

Bowyer's three outputs are Longbow (two limbs + string, Pierce/Far), Sling (cord + projectile + pouch, Crush/Far), Throwing Set (two edges + carrier, Rend/Far). No ammunition chore. Replace old broad Fibre with explicit appropriate Cord/Cloth/Leather roles together; do not make soft wrapping a projectile. Require a physically suitable bow limb rather than every timber or bone piece. Source-shaped eligibility and role stats are needed before final typed recipes.

Weaponsmith's four families are Fitted Point (point/grip/fitting), Fitted Edge (edge/grip/fitting), Fitted Maul (head/brace/grip), and Fitted Polearm (chosen point/edge/crush head, haft, binding). First three are Close; polearm is Mid with explicit damage choice before materials. The legacy +0.5 specialty offset is a current compatibility fact, not automatically added again to new material ceilings. Recommend meaningful fitting/handling choices as the specialist advantage. Author all four costs/stat receipts/prices together after Blacksmith, then compare against starter gear of the same materials.

Acceptance: all three damage corners have obtainable recipes; exact reach and physical/coating eligibility are visible; fitting cannot double count quality; alternate accepted materials preserve source appearance; no simple buy/craft/salvage profit. Dependencies: physical role allowlists, Tannery stock and Fen's useful Hafts.

### Armoury / reforge / refit / Peerless / recovery

Catalogue rebuilds: Rigid shell = two bodies + binding; Insulated layer = two linings + outer; Balanced laminate = body + lining + binding + fitting. Cover the existing five protective slots and preserve the exact rebuilt item's identity/custody. Existing +0.5/−0.5/0 offsets and six-band quality fees are legacy behavior; the replacement must expose actual Protection/ward tradeoffs under one stat calculation.

Reforge currently uses its own old within-tier upgrades; do not describe it as the approved Peerless journey. Separate replacing a component, improving workmanship and changing Armoury construction. A preview must show which facts change and which old components are consumed/recovered, so repeated service calls cannot stack the same bonus. Proposed common policy: new recovery returns only committed recoverable components, at a displayed service rate; no Essence, Salt, fuel, processed raw ancestors or fabricated better-grade stock. Legacy receipts remain compatible.

Accepted Peerless guarantee: Mote + maximum shop + attending shopkeeper gives 100%; partial combinations permit a chance. Aimee's open decision is the experience when a Mote-funded partial attempt misses. Recommend durable progress, no destruction/downgrade. Probability tables, service fees and protections are Design's batch work after that one choice. This does not gate Apothecary or ordinary gear.

Acceptance: refit the same item twice without additive stat inflation; moving/wearing the item invalidates a stale quote appropriately; recover exactly the displayed components once; no old/new quality conversion by label; max setup guarantees Peerless; no new random failure in ordinary crafting.

### Survey Post — all eight instruments

Current pair of improvements for every owned instrument: 2 samples at linked property ≥35 + 20 Essence gives Good; 3 at ≥65 + 50 Essence gives Fine. Links: illumination/cycle Lustre; thermal Insulation; hydrology Flexibility; substrate Hardness; relief/atmosphere Density; vitality Reactivity. This is sixteen improvements, not two generic recipes with interchangeable magical materials.

Proposed physical roles to author as a set: optics for illumination, timing mechanism for cycle, thermal insulation/sensing for thermal, water-sensing element for hydrology, geological probe for substrate, surveying measure for relief, air-sensing element for atmosphere and living-response reagent for vitality. Exact component identities remain a Design/producer dependency; these role names alone are not implementable allowlists. Keep Crude/Good/Fine precision separate from creature quality and gear workmanship. Retain fees until instrument progression is priced as a complete set. Acceptance includes all eight targets, owned identity, accuracy gain, missing prerequisite and no silent consumption of the best exceptional specimen.

### Scriptorium / Writing Desk / inscriptions

Current prepared ink uses CMY+Depth channel stock: Copper/Cyan, Ichor/Magenta, Sulfur/Yellow, Obsidian/Depth, plus Resin 1, yielding 12 applications; zero channels cost none of their pigment. Personal Compound formalization is 20 Essence + Pulp 4 under its Runebook conditions; naming/ordering/deletion must not rewrite existing Pages/worlds. Seamward installation uses an identified Seamlight, 10 Essence and one ink application on eligible Body/Keepsake gear; erase is free and refunds nothing. Do not confuse this with Waystone's Riftglass/Mote recipe.

Overhaul the ingredient layer alongside Isolde's proposed production (two fibrous units → two Pulp or four Paper; one pigment source → four measures). Preserve distinct preparation, application and inscription charges; pigment output is not automatically a whole vial. Paper does not grant a learned rune or a guaranteed world feature. Lantern/Light inscription authoring remains tied to named native consumers and activation completion, not speculative animation or inferred illumination. Acceptance: channel shortfalls spend exactly once, zero channels stay free, no extra ink on reload, permanent gear identity and existing world records survive rename/delete/erase.

### Distillery / Channelworks

Current direct attunement costs 16 Essence, an exact qualifying material and a selected catalyst. Heat: Reactivity ≥60/Insulation ≥25, Sulfur 2; Caustic: eligible Reagent/Toxin/Ichor with Reactivity ≥60, selected Toxin 2 or Ichor 1; Light: Lustre ≥60/Hardness ≥30, Silver 2. Current potency is its attunement's property function; do not multiply by an invented material grade. Blank Core manufacture is obsolete. Current repeatable Heat Fixture consumes a valid Heat Core; story restoration is a separate authored route. Do not equate either stored fixture with the entire proposed weapon system.

Decided destination includes Heat/Caustic/Light across three reaches. Author nine configurations in one Channelworks matrix, including casing/handle/conductor roles, actual output stats, attunement effect and replacement/retuning costs. Do not restore unsupported Freeze/Shock assumptions. Core catalyst identities share Apothecary's named chemistry dependency; adding a high-Reactivity threshold does not solve it. Acceptance: core source and potency survive manufacture/Return/recycle; no duplicate Core from dismantling both fixture and history; no “working Light weapon” claim before its native consumer; no physical coating automatically applied to an ineligible conduit.

### Anchorage

Current Frame requires six distinct exact units: two Hardness ≥65, two Density ≥65, one Flexibility ≥55, one Reactivity ≥65, plus 60 Essence. No unit may fill two positions. Proposed replacement roles are structural members, ballast, binding and attunement medium, backed by real eligible materials; finalize alongside Blocks/Hafts/Cord and the shared chemical catalogue. Keep physical Frame manufacture separate from assignment to an exact eligible world/portfolio. Acceptance: same unit cannot pay twice; assignment/reassignment follows world ownership, no orphan frame on stale quote or full storage; salvage does not duplicate an assigned anchor. Do not advertise permanent world access from an unassigned stock item.

### Refining, processing, building access and inventory

Essence Spring currently converts one Raw Essence to two Crystals, three after Second Pass; Continuous Settling remains its own researched operation. Do not conflate this with Core attunement or ordinary zero-Essence material processing.

Recycler's existing gear recovery tiers use 40%/55%/70%, with a minimum recovered component for qualifying multi-component receipts. Preserve exact current exceptions such as early Leather Guard until a versioned batch policy replaces them. Proposed Rubble sorting accepts even batches 2/4/6 and yields one output per pair under its authored common/uncommon/rare distribution; it is not a delivered infinite resource faucet.

Other proposed processes: Fen Logs → two Planks or one Haft; structural Stone → Blocks; the two ordinary Glass routes at Blacksmith; Isolde's Pulp/Paper/pigments above. Keep each process gated on a real repeat consumer or one broad useful family, rather than adding mandatory empty steps. Review its full input purchase / output sale / downstream recovery values before releasing it. Do not copy a conversion ratio from one process to another without its authored production row.

For every shop include recruitment, foundation, research, upgrade and attending-keeper effects in the same plan. Early makers retain their accepted cheaper costs and priority. Later legacy foundation prices are placeholders, not an endorsed progression curve. Keep at most one newly encountered person per world and existing opportunities to reach ahead. Shared Storehouse/Waiting and carrying must keep finished goods claimable; output success is not permission to silently pack or sell the item.

## Release order and outstanding work

Next implementation handoff is the **Apothecary batch**, after Design closes the shared named chemical/flora source table and proposed recipe tuning. Engineering can size the shared coating-lifetime change now from the accepted rules; no new Aimee lifetime decision is needed. Keep Briar delivered and the untouched Venom bridge out of an isolated queue. Blacksmith and Tannery preparation can proceed as whole matrices using their existing early production contracts, but do not call all typed recipes implementable before the role/source/economy tables exist.

This audit closes the scope census and the contradiction review. It does **not** claim that the complete overhaul, chemistry catalogue, nine Channelworks configurations or every later physical allowlist is finished. Those are explicitly bounded production work in the shop packets above, with dependency order and concrete acceptance cases. Only Mote-on-miss remains a mandatory Aimee crafting decision. Creature ecology/player-experience review and optional artwork remain her separate references.

## Evidence and handoff

Reviewed: Engineering ConsumableCraftingRules, BriarOilPhysicalInputs, InstrumentCraftingRules and DistilleryRules; item definitions for all 19 preparations; physical schematic catalogue and live Blacksmith list; early maker/specialist/leather/carrying packets; Wiki crafting catalogue, crafting overview, service source guide and September decisions. The Wiki's coatingLifecycle is the retained accepted excursion-lifetime authority. Do not use older input-adapter prose to supersede it.

This is docs-only Design work. No native builds, mounted checks, phone installs or delivery polling were performed. Repository organization and whitespace checks accompany the checkpoint. Not an installable revision or Engineering implementation parent.
