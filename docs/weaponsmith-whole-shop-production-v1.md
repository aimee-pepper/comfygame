# Whole Weaponsmith production — fitted physical melee weapons

**5 September 2026 · Complete Design-authored first-pass contract; replacement implementation pending.**

Authority: Aimee's delegated whole-shop recipe/cost/order tuning and PM's complete Weaponsmith assignment. Preserve the four family identities, ordinary physical combat, Maud's singular Polearm teaching, real component identity, four-band material/workmanship rules, no soulbinding, and the completed Forge/Tannery/Bowyer/Apothecary contracts. The exact foundation, processing recipes, component bundles and two fitting choices below are Design first-pass tuning, not new personal approvals attributed to Aimee or measured balance.

This supersedes future Weaponsmith instructions in `weaponsmith-implementation-current.md`, the relevant gear-family/component/category briefs and the proposed whole-shop audit. Old six-band fees, grade caps, generic property requirements and automatic +.5 specialty offset remain legacy compatibility only. This one packet closes all four families, the real Haft/collar producers, learning, material/quality/stat rules, prices, recovery/refit and legacy services. Next existing whole-shop batch: Armoury.

## 1. Current behavior and complete dispositions

Current source defines Fitted Point, Fitted Edge, Fitted Maul and damage-selectable Fitted Polearm, using broad legacy material families and the older shared six-band calculator. The older design brief also lists numerical property thresholds that the current family allowlists no longer implement; neither is the new typed-material destination. The authored old foundation costs 150 Essence, 32 Iron Ore, 12 Copper and 4 Gold, with separate 75/150-Essence station rungs. Current source inventory is not a fresh native playtest or delivery claim.

| Stable family | Retained output | New route |
| --- | --- | --- |
| `weaponsmith_fitted_point` | Weapon · Pierce · Close | Actual point, shaped grip, wrap and collar |
| `weaponsmith_fitted_edge` | Weapon · Rend · Close | Actual cutting edge, shaped grip, wrap and collar |
| `weaponsmith_fitted_maul` | Weapon · Crush · Close | Actual head, Hardwood brace, wrap and collar |
| `weaponsmith_fitted_polearm` | Weapon · chosen Pierce/Rend/Crush · Mid | Chosen matching head, reinforced Hardwood haft assembly, binding and collar |

Fitted means a visible construction choice using existing **Power and Initiative**, not a new fit score, stat, wearer ID or equip restriction. Any lawful wielder may use the finished weapon. No magical attack, Far weapon, ammunition, durability, repair, fatigue, attack-speed stat, critical chance, random affix or extra action is added. Found/apex identities and their special rules remain outside ordinary manufacture.

## 2. Recruitment, foundation and knowledge

Retain Maud's existing recruitment/world signature and mid-late story timing. No guaranteed encounter, new search charge, extra written world or early free recruitment.

New Weaponsmith foundation base quote: **40 Essence, 4 Iron Ingots, 2 Hafts, 2 Plant Cord** after recruiting Maud. Hafts may be actual Softwood or Hardwood. Ingots come from Forge T2; Hafts from the existing Bowyer; Cord from Tannery. These are actual material dependencies. Existing legitimate trading may supply prepared stock without the player owning each producer; it never grants a missing station tier or new merchant stock. Producer knowledge may precede facility access and must remain saved. Existing applicable construction/staffing price rules remain, without double discounts or new material refunds. Already-built Weaponsmiths stay built, with no second foundation or refund of their historical expenditure.

Successful construction teaches **Point, Edge, Maul, both fitting choices and ordinary refit**, plus Bone Collar preparation at Maud and Iron Collar casting at Forge T2. No paid Wear-style root, Study, attending Maud, Bowyer T2, Weaponsmith upgrade or grade-based Essence toll is needed for these ordinary recipes. New built-shop logic must handle an existing internal tier0 correctly. Preserve old purchased tiers, keeper-earned progress, known patterns and supported legacy services; do not sell old broaden/masterwork rungs as necessary for these now-included recipes or pretend purchases never happened.

**Polearm keeps the accepted diary gate:** known `maud_fitting_pattern` plus the built Weaponsmith. Learning-before-building stays known and becomes usable on construction; building-before-learning does not invent the diary reward. Its actual existing teaching acquisition remains unchanged. Display that exact missing teaching rather than a false material/shop-tier requirement. Polearm chooses Pierce, Rend or Crush before head selection, and the quote names the chosen kind. Both fitting choices apply after the family/kind is selected.

To avoid a foundation loop, **Maud's recruitment teaches the two Haft processing recipes**, even if Fen's shop is not yet built. The knowledge persists; using it needs the built Bowyer. Recruitment does not grant materials or a new paid search. On migration, an already-recruited Maud grants this knowledge once; an already-built Weaponsmith supplies its included family/producer knowledge once. Persist grants through the actual recruitment/build/compatibility event, never repeated menu rendering.

All ordinary processing, construction, refit and fitting adjustment below cost **0 Essence**. They are deterministic valid transactions, not random rolls toward Peerless. The existing separate Mote/maximum-shop/attending-keeper proposal is not resolved or made available by this ordinary fitting service.

## 3. Complete Haft and collar production

Each row outputs one actual prepared material unit, with complete input/source history and a frozen value. No new facility is introduced.

| Output / exact proposed ID | Existing maker and unlock | Exact input | Grade, source and nominal sale / buy |
| --- | --- | --- | --- |
| Softwood Haft / `processed.haft.softwood` | Built Bowyer; Maud-recruitment knowledge | 1 Softwood Log | Ungraded, exact Log appearance/history;1 /2 |
| Hardwood Haft / `processed.haft.hardwood` | Same | 1 Hardwood Log | Ungraded, exact Log appearance/history;1 /2 |
| Iron Collar / `processed.collar.iron` | Forge T2; Weaponsmith-foundation knowledge | 2 Iron +1 Coal | Ungraded, exact metal/input receipt;4 /8 |
| Bone Collar / `processed.collar.bone` | Built Weaponsmith; foundation knowledge | 1 valid typed Bone | Preserve that Bone's band, actual Density/size/full colour; actual frozen Bone nominal / twice that |

These four new registered material IDs require their normal source/custody/selection support; this document does not claim current registry implementation. Hafts remain separate named wood types, not an anonymous Haft that erases the selected Log. Bone Collar uses the same creature-derived prepared-material discipline as Leather, not a finished-equipment rarity or new skeletal subtype. It preserves the actual raw Bone's2/4/8/16 nominal price rather than regrading/repricing it. Preparing a collar never upgrades Bone, applies its quality multiplier, or adds a Salt fee.

Iron Collar is **cast directly from Iron + Coal**, alongside the Forge's existing Ingot process. It does not require Iron→Ingot→Collar as two mandatory processing steps. This is a named consumer-backed Forge extension, not a second generic metal-refining shop. Maud then fits the collar during final weapon construction. Bone shaping is Maud's corresponding direct one-step process. A craft may consume several different prepared parts, but no ordinary material needs a new serial two-step processing chain.

Fen shapes Hafts for these named consumers; the preceding Bowyer packet's deliberate hold on an unused Haft menu is now lifted only for these two exact recipes and unlock events. Planks still have no newly closed consumer here and remain withheld. Longbow bending limbs remain their own inline Hardwood construction, not generic straight Hafts. **Forge's raw-Log starter gear and tool upgrades stay unchanged**; do not retrofit a Haft or collar prerequisite onto them.

No timer, seasoning, crafting kit, intermediate strap, blanket fitting token or bonus from species names. Material quantities are stock units; Polearm's two Hardwood Hafts form its reinforced shaft assembly during final construction, with the listed binding/collar. Source-colour regions remain distinct even when assembly combines two pieces.

## 4. Every construction recipe and fitting choice

All four recipes output one identified owned weapon at no Essence cost. Every row includes one actual **Iron Collar OR Bone Collar**. Select the collar itself; do not substitute a finished weapon, a raw Bone, arbitrary Gold or an unrelated lustrous sample.

| Family / damage | Working bundle — choose one | Complete shaft/grip and wrap/binding | Collar |
| --- | --- | --- | --- |
| Fitted Point · Pierce/Close | 2 Iron Ingots OR 2 Quartz OR 1 Bone | 1 Softwood/Hardwood Haft;1 Cord OR 1 Leather wrap | 1 Iron OR Bone Collar |
| Fitted Edge · Rend/Close | 2 Iron Ingots OR 1 Bone | Same Haft and wrap choices | Same |
| Fitted Maul · Crush/Close | 2 Iron Ingots OR 2 Bone | 1 Hardwood Haft;1 Cord OR 1 Leather wrap | Same |
| Fitted Polearm · Pierce/Mid | 2 Iron Ingots OR 2 Quartz OR 1 Bone | 2 Hardwood Hafts;2 Cord OR 2 independently chosen Leather bindings | Same |
| Fitted Polearm · Rend/Mid | 2 Iron Ingots OR 1 Bone | Same two-Haft/binding assembly | Same |
| Fitted Polearm · Crush/Mid | 2 Iron Ingots OR 2 Bone | Same two-Haft/binding assembly | Same |

The three Polearm rows are the three explicit choices within one family, not three extra recipe-learning fees. A two-unit working bundle uses that selected material type throughout; Bone units may differ in source, Density, colour and band. Two leather bindings may differ; choose the all-Cord or all-Leather binding bundle, without silently blending an unselected half of each alternative. The two Hardwood Hafts need not match colour/world. Tannery textiles retain their full mixed strands/sections.

No raw-metal working option is added to this specialist table: the early Forge already supplies useful raw-material equipment, while these later constructions use Ingots and shaped components. Quartz remains a piercing point choice only. No implicit Obsidian, Adamant, Copper, Gold, Horn, Claw, Shell or Fin producer is added from old allowlists. No hidden Hardness/Flexibility/Lustre threshold requires another sample to fill a pictured part.

Choose one visible fitting at craft or later at Home:

| Fitting | Authored contribution to the completed weapon |
| --- | --- |
| **Balanced** | +1 Initiative; no added Power |
| **Driving** | +0.75 Power; no added Initiative |

Both use the same actual recipe parts and prices. The tradeoff is the selected benefit, not a hidden penalty or extra scarce material. “Driving” is a new explicit first-pass construction choice, not the inherited automatic+.5 specialty offset; neither fitting stacks the old offset underneath it. Neither changes the weapon's damage type/reach, grants extra actions or locks it to the intended wielder. All material/band/appearance choices remain visible in the full result preview.

## 5. Power, Initiative and workmanship — one final calculation

Use the same working baselines as the completed Forge:

| Working material | Base contribution before fitting and final rounding |
| --- | --- |
| Iron Ingot working assembly | 2.5 Power |
| Quartz piercing assembly | 2.25 Power |
| Bone working assembly | Mean of `4 × (.5 + actualDensity_i/200) × multiplier_i` across its selected Bone units |

Poor/Common/Rare/Exceptional multipliers are .75/1/1.25/1.5. Add the chosen fitting's Power contribution to the working result, then round the complete final Power once to the nearest quarter, half up: `floor(4 × total + .5)/4`. Initiative contribution is exactly the fitting's0 or1 on the existing Initiative axis. Keep the ordinary one-decimal Power display and exact final preview. Material counts are construction quantities, not repeated damage bonuses or extra blows.

There is no old grade-derived base, automatic+.5 specialist offset, strongest-material effect, collar Density bonus, hidden reactivity coating or second quality multiplier. Hafts, wraps and collars are required structure, real appearance and explicit workmanship contributors; their properties do not supply undisclosed Power/Initiative/wards/HP. Grade can change workmanship without adding a second combat bonus. The preview must show actual final Power and Initiative, so a more expensive colour/grade choice cannot imply an unlisted damage gain.

Primary quality group is **the working head/point/edge alone** for every family. This deliberately replaces the old Maul brace/Polearm haft primary grouping and makes their raw-material interpretation consistent with Forge. Average the ranks of multiple Bone units in that working group. Ungraded Ingot/Quartz votes rank1; Bone votes0/1/2/3.

Secondary group has exactly three equal logical votes: **Haft assembly**, **wrap/binding assembly**, **collar**. The Haft assembly is ungraded rank1. Cord assembly is1; Leather assembly is the mean of its selected real bands. Iron Collar is1; Bone Collar uses its preserved band. Quantity gives neither a two-piece shaft nor two bindings extra group weight. Raw ancestors never vote again. Compute `roundHalfUp(.70 × primaryRank + .30 × meanSecondaryRank)` → Rough/Fine/Superior/Exceptional. All-world construction is Fine. This explicit structural weighting does not change Tannery's minor-closure no-vote rule.

Examples:

- Ingot Point with Haft/Cord/Iron Collar: **Balanced Power2.5, Initiative+1** OR **Driving Power3.25, Initiative0**. Fine either way; sale14/buy28. Forge Ingot blade stays Power2.5 with no fitting Initiative; an Ingot Bowyer weapon stays Power2.0/Far.
- Common Bone Density60 Point with ordinary Cord/Haft and Common Bone Collar: base3.2; **Balanced3.25/+1**, **Driving4.0/0**, Fine, sale10/buy20. The Collar does not add its own Density to attack.
- Rare Bone Density60 Point with Rare Bone Collar and Cord/Haft: base4.0; Balanced4.0/+1 or Driving4.75/0; rank1.8→Superior, sale18/buy36.
- Exceptional Bone Density80 Point and Exceptional Bone Collar with Cord/Haft: base5.4; Balanced5.5/+1 or Driving6.25/0; rank2.6→Exceptional, sale34/buy68. Its original Bone source properties remain unchanged.
- Two-Bone Maul with Poor Density20 and Exceptional Density80: working mean `(1.8+5.4)/2=3.6`; Balanced3.5/+1 or Driving4.25/0. With Cord/Hardwood Haft/Iron Collar, primary rank1.5 and secondary1 gives1.35→Fine; sale24/buy48. No average Bone material is created.

These are authored comparisons, not a claim of measured whole-combat balance or guaranteed HP loss. Retain actual skill/formation/damage rules; Initiative changes the existing turn-order calculation only. Do not add a new attack-speed multiplier or make Close outrange Far.

## 6. Shared producers and complete prices/recovery

Retain the Tannery's source-preserving textile/Leather rules, including mixed constituents and old frozen nominal values; Forge Ingot and tool rules; Apothecary Quartz and coating contract; the full typed Bone source/reward contract. Bone remains canonical `creature.bone` with supported skeleton/species/placed-body agreement, source Density/size/colour, the retained species size/34 quantity, no new Bone chance roll and departure-frozen Anatomy once. Collar processing consumes an already-owned Bone; it never re-runs a reward, creates a new species, or turns a no-skeleton creature into stock.

Hardwood Hafts need actual Hardwood; the accepted Axe2 small-hardwood route is sufficient, not every Axe3 tree or a guaranteed new log. Softwood handles remain a useful Axe1 option for the Point/Edge and foundation. Source budgets, one-resource-per-tile, mining/harvesting actions, Return/haul loss, quality scoring and material market tables do not change.

New weapon sale **C=sum actual selected recoverable prepared/working components' frozen nominal sale values**, buy2C. Same rule as Forge/Tannery/Bowyer, with no profile, workmanship, species or colour multiplier. Nominal values: Haft1, Cord1, Ingot4, Quartz6, Iron Collar4; raw Bone2/4/8/16; Bone Collar its actual input Bone value; Leather its own recorded nominal (new standard3/4/7/13, older values retained). Freeze final C on the item and recompute only for an explicit new refit result, not when registry prices change.

| Full material route with Cord and Iron Collar unless stated | Sale / buy |
| --- | --- |
| Ingot Point, Edge or Maul | 14 /28 |
| Quartz Point | 18 /36 |
| Ingot Polearm, any damage choice | 16 /32 |
| Quartz Pierce Polearm | 20 /40 |
| Single-Bone Point/Edge + same-band Bone Collar | 6/10/18/34 sale at Poor/Common/Rare/Exceptional; buy twice |
| Two same-band Bone Maul + same-band Bone Collar | 8/14/26/50 sale; buy twice |
| Single-Bone Pierce/Rend Polearm + same-band Bone Collar | 8/12/20/36 sale; buy twice |
| Two-Bone Crush Polearm + same-band Bone Collar | 10/16/28/52 sale; buy twice |

Replacing Iron Collar with Bone Collar changes C by the exact collar value minus4. Replacing a one-Cord wrap with Leather changes C by that Leather value minus1; replacing two-Cord binding changes it by the sum of the two Leather values minus2. Mixed Bone heads use actual individual values, not a fabricated finished-band raw price. Changing Balanced/Driving alone changes no value.

Full recovery of a supported new weapon returns its exact selected Ingots/Quartz/Bone, Hafts, Cord/Leather and Collar once. Returned Collar stays a Collar: no original Iron/Bone or casting Coal as well. Returned Haft stays a Haft, not a second Log. Other prepared stock likewise returns intact with its full original receipt, not Fibre/Hide/Salt/Iron ancestors. Loose processed Hafts/Collars add no reverse-processing service. Fuel and fees never return. Existing lock/equipped/ownership protection remains; old equipment keeps its known versioned recovery policy without synthetic source reconstruction.

Base purchase→craft→sale is nonprofitable: buying ingredients costs2C and selling output givesC; buying finished for2C and selling full recovered pieces yieldsC. Iron Collar input buy12 (2Iron plusCoal) produces sale4, Haft input buy2 produces sale1, and Bone Collar input buy2B produces saleB. Direct production and recovery cannot duplicate source materials or arbitrage grade labels. Existing authored merchant requests retain their separately disclosed frozen quote rules.

## 7. Ordinary refit and legacy services

At the built Weaponsmith, an identified owned new-policy item with a complete construction receipt may replace a complete component bundle. Preserve exact item identity, family, **damage kind**, Close/Mid reach, inscriptions/other supported ownership facts and custody. Preview incoming inputs, outgoing recoverable parts, final Power/Initiative/workmanship/appearance/C and destination. Pay new selected stock, return only outgoing recoverable pieces once, retain other pieces without refund, and recalculate the complete final result. No partial stat patch or additive bonus.

The fitting can also be adjusted **Balanced↔Driving at Home for 0 Essence and no new materials**, reusing the actual existing complete construction. This explicit adjustment changes only the declared fitting and its computed result; it is not a raw-material upgrade, new weapon, repair, quality reroll or free combat turn. Save it atomically once, treat an unchanged selection as a no-op, and retain the same collar/source history and C. No field or mid-encounter fitting menu is introduced.

Polearm refit/adjustment retains its chosen damage kind. For a different damage kind, explicitly craft that variant using its complete known recipe; an overlap in allowed Bone/Ingot materials never auto-selects a favourable matchup. Learning its pattern once covers all three lawful choices, with no second teaching or hidden conversion button.

New refit may net explicitly reused outgoing components once in the quote; otherwise reserve distinct new available stock. Failed/stale quotes or insufficient quantities cannot return an outgoing part before the new result is durably committed. A long shaft and collar do not independently claim the same prepared unit. No source measurement/band is edited, and no Bone Collar is decoded back into an untyped legacy sample.

Legacy Weaponsmith items remain usable/tradable and retain their existing lawful service/grade/fee/recovery rules; do not retrofit Balanced/Driving or the new 0-Essence calculator onto an unsupported old receipt. Existing purchased research/keeper progress is retained without forging historical payments or charging the old 75/150 rungs again. New ordinary recipes have no cap/wasted-grade/below-headline warning based on the retired six-band system; old supported paths can still explain their own actual constraints. Peerless improvement remains its separate unfinished system, not a second name for this deterministic service.

## 8. Combat, coatings and custody

Use the exact item's frozen new construction profile in ordinary combat projection; an old fallback catalogue blade/maul must not supply its damage, reach, Power or Initiative. Keep existing physical damage matchups, skill access/scaling, formation, turn order, retaliation, target rules and one-action cadence. Fitted Point/Edge are not new Finesse-only equip locks, and Fitted Maul is not a new Might requirement.

All four physical families use Apothecary's **one exact weapon, one excursion** coating owner and existing legal preparation action. One bottle prepares the weapon; hits/misses/encounters/travel/relaunch do not consume it. The actual excursion end clears it; a new weapon or later world gets no free preparation. Per-target status payloads and durations remain separate. Do not restore one-strike lifetime, infer a free intrinsic coating from raw reactivity, or change Channelworks eligibility. Home refit must not resurrect an ended excursion's coating or create a new active run.

New source/producer/processing/craft/refit owners are the existing actual-material and gear custody records plus the four named material registrations and an explicit construction fitting choice. Do not invent a global material framework, anonymous specimen, parallel resource balance or chosen-wielder subsystem. Engineering must name the actual native consumers/state before Asset receives literal Haft/collar/fitting artwork work; this packet supplies semantic parts and preserved colour, not new final-art approval.

## 9. Progression examples and integration order inside the batch

No user choice or unnamed ingredient blocks this whole first pass. The required progression is explicit:

1. Existing Forge T1/T2 and Corrin give Ingots and Cord.
2. Fen's built shop plus Maud's recruitment knowledge can shape Softwood/Hardwood Hafts before the Weaponsmith foundation needs them.
3. Build Weaponsmith using4Ingots/2Hafts/2Cord/40Essence; included knowledge enables Iron Collar at Forge T2 and Bone Collar at Maud.
4. Craft any of the three Close families; the retained diary teaching separately enables Polearm. All have an animal-free metal route.

From no relevant shops, a base-price path through Forge T1/T2, Corrin, Fen, Weaponsmith and one all-metal fitted Point with Cord is **130 Essence,30 Iron,7 Coal,23 Logs,18 Fibre,8 Clay,2 Resin**. This includes all consumed Ingots, Collar, Hafts and Cord preparation. Softwood can supply all needed Logs; no improved Axe is compulsory for this first specialist Point/Edge. It excludes search/recruitment/Binding costs, unrelated gear, existing paid progress and later Polearm teaching; it is a staged production total, not an opening shopping list or affordability playtest.

After those shops exist, one new all-metal Point/Edge uses expanded raw **6 Iron,3 Coal,1 Log,2 Fibre**. An all-metal Maul additionally needs its Haft's Log to be Hardwood, obtainable with Axe2. An all-metal Polearm uses **6 Iron,3 Coal,2 Hardwood Logs,4 Fibre** plus its known teaching. Raw Forge starter weapons remain independent alternatives, not ingredients destroyed automatically when a specialist recipe is learned.

The real next-Bind quote and actual campaign timing remain the pacing evidence. Do not invent a universal departure cost, mandatory checklist or affordability gate to make the first-pass totals appear measured. Ordinary mineral/tree/creature placement stays unchanged; this plan never guarantees every material in a single world.

## 10. Focused acceptance and actual remaining gates

Implement this as one whole shop plus its named producer extensions; separate code commits are fine, isolated recipe dispatch is not. Cover foundation/knowledge, all six family/kind rows and both fittings, four prepared producers, shared selections/quotes, new stat projection, trade/recovery/refit, legacy compatibility and durable custody together.

Freeze exact canonical input owners, quantities, source/composition, recipe/fitting version, chosen kind, final stats/value and destination. Commit spend/output/returns/history atomically. Cancel, stale/invalid selection, lost ownership or save failure changes none of them. Full storage uses the existing Waiting path; never auto-equip, discard or create a second weapon. Reload must not replay preparation, knowledge grants or fitting bonuses.

| Bounded case | Required outcome |
| --- | --- |
| Maud recruited before/after Fen build; foundation before/after diary | Haft knowledge persists without free stock; no circular foundation gate; Polearm requires exact retained teaching |
| New and already-built Weaponsmith | Correct included three families/two fittings/refit/producers, no duplicate costs or old empty tier gate |
| Each of4prepared processes | Exact one-step inputs/output, source/grade/value, no silent subtype loss or extra ancestor stock |
| All family/kind recipes with both fittings | Exact bundles, fixed Close/Mid and chosen damage, +1Initiative OR+.75Power once |
| Source/stat/workmanship examples above | Exact quarter Power/four-band result; no old+.5/base/material-effect/quality double count |
| Softwood Maul/Polearm shaft, Quartz Rend head, wrong/legacy sample | Honest refusal before spend; no arbitrary numerical property sample to repair eligibility |
| Mixed Bone head, two Leather bindings, different-colour Hafts/textiles | Per-piece source retained, correct averages of logical groups, no fictitious average material |
| Full trade/recovery then reuse; old-priced Leather | C/2C exact, prepared units returned once, no raw Bone/Log/Iron/Fibre ancestors or fuel refund |
| Component refit, fitting-only change, repeat/reload | Same exact item, complete result recalculation, one outgoing return, no stacking/refund/quality reroll |
| Polearm kind retained during refit | No automatic physical damage conversion; different kind requires explicit known craft |
| Failed/stale/save-refused craft/refit and full storage | No partial spend/grant; existing Waiting/custody behavior |
| New profiles used in existing melee combat and shared coating route | Actual Power/Initiative reach combat, no added action/fit stat, coating persists through excursion and expires once |
| Old owned weapons, purchased tiers, pattern and active-run snapshot | Preserved identity/knowledge/value/compatible services, no guessed modern fitting or in-run mutation |

**Remaining implementation gates:** exact four producer registrations/custody and event-owned knowledge; the complete new Weaponsmith calculator/menu and combat projection; shared new-policy Bone/Leather/textile/Quartz support; legacy service routing; accepted shared coating lifetime. None is a new personal recipe approval request. Mote-on-miss/Peerless and wider anatomical work remain existing grouped homework. No new Aimee decision is required for this first pass.

**Next existing whole-shop batch:** Armoury — Rigid/Insulated/Balanced rebuilds across supported protective slots, actual protection/ward tradeoffs, fitting/recovery services and legacy migration, using the now-defined prepared material producers.
