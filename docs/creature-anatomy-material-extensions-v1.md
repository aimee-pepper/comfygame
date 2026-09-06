# Remaining creature anatomy and material uses — bounded first pass

**6 September 2026 · Design-authored proposal; not implemented and not a broad rollout instruction.** Continues the assigned Body → materials work. This defines the missing physical records and narrow optional consumers for teeth/claws/tusks, Down, fins/membranes and recoverable fluids. It preserves the settled Hide, Bone and solid-part contracts. These choices are not attributed to personal Aimee approval.

Read with [solid-part rewards](creature-body-material-rewards-production-v1.md), [body/habitat](generated-creature-body-habitat-v1.md), [disclosure](creature-disclosure-player-journey-v1.md), [food/habitat/shelter](creature-food-habitat-shelter-v1.md), and the complete maker contracts. Ordinary shops remain complete with their existing plant/mineral alternatives; no creature hunt becomes a new foundation, tool, research or upgrade requirement.

## 1. Supported facts versus new anatomy

Current source in Engineering's `early-material-regions-v1` worktree records body plan, cranial feature, accessory appendages, covering, bone density, attack axes, defence, coloration and emanation. It lacks independent jaw/dentition, claw-bearing limb terminals, Down layers, membrane-sheet material measurements and recoverable fluid organs/chemistry. The existing membrane/finned appendage types identify shapes, not their complete material properties. Attack `pierce/rend/crush`, `isToxic`, insulation and emanation cannot supply the missing records.

The following are **new proposed anatomy**, not recovered facts about existing creatures. Author a versioned extension to the existing frozen anatomical manifest, suggested `creatureAnatomyMaterialVersion = 2`, requiring the solid-part policy. No absent/legacy extension is inferred, backfilled or rerolled. Existing species, specimen measurements, attack/defence outcomes, settled rewards and stock retain their policy.

Each proposed part needs a stable part ID, actual region/anchor ID, physical structure/material identity, complete finite measurements, exact source/part appearance and species recovery budget. Validate against the actual specimen before reward eligibility. A manifest describes the body before encounters; the reward handler cannot fabricate anatomy from the stock it wants to award. Missing measurements or anchor mean unavailable, not zero-quality invented stock.

**Generation/adoption boundary:** these are compatible source-profile definitions for a future explicitly enabled anatomy group. This packet does not assign new cast frequencies, retune the costly trait budget, resample existing bodies or assume that a measured damage axis builds a particular organ. The generation owner must instantiate the declared structure and its own measurements before selecting this profile. A profile without that producer remains unavailable. Engineering can implement one complete source/consumer group without enabling the rest. Natural prevalence and visual fit remain the later combined-world design/playtest dependency, not a new Aimee approval chore.

## 2. Physical eligibility — complete disposition

| Proposed source | Required actual structure and measurements | Typed output and exclusion |
| --- | --- | --- |
| Ordinary teeth | Explicit jaw/mouth anchor and attached dentition; positive actual tooth count | No generic Teeth crafting stock in this slice. Small teeth are still valid anatomy; they do not automatically become Fangs, Tusks or extra Bone |
| Fang | Jaw-anchored elongated pointed tooth, explicit usable point portion; positive count, material hardness and structural integrity | `creature.fang`; no Fang from Pierce, horn, beak, spine or a tooth without the usable-point declaration |
| Claw | A keratinous/hard claw sheath attached to a real limb terminal, with a usable curved cutting portion; hardness and structural integrity | `creature.claw`; a limb, Rend attack or fin tip alone is insufficient |
| Tusk | Jaw-anchored projecting elongated tooth with an explicit usable long-point portion; hardness and structural integrity | `creature.tusk`; not a cranial horn and not inferred from Crush; the same tooth is not also Fang |
| Down | Explicit soft plumulaceous body layer, distinct from vaned appendage feathers; actual layer coverage, length and flexibility | `creature.down`; layer insulation = its own length × coverage /100. No Down from insulation alone, and no duplicate Pelt/Hide from the same layer |
| Membrane wing/appendage | Actual continuous skin sheet on a recorded appendage, with its own coverage, hardness and flexibility; sheet covering length is explicitly0 | `creature.skin.membrane`; no copied body-covering values and no inferred flight |
| Webbed fin | Actual fin with an explicitly recorded continuous skin web and the same complete sheet measurements | The same `creature.skin.membrane`, retaining fin provenance; no extra Fin reward |
| Solid fleshy fin | Actual fleshy fin, without a recoverable skin-sheet declaration | No new craft material. No meat/cooking route is added; a fin can be meaningful anatomy without a stock token |
| Fin rays/supports | Explicit supporting structure, if present | No separate generic Fin/Bone bonus. Existing Bone owns any qualifying internal skeleton; the same structure cannot be paid twice |
| Recoverable oil | Actual gland/reservoir containing a separable oily secretion, with explicit combustible-carrier chemistry | `creature.oil`; neither aquatic habitat nor body bulk/insulation proves it |
| Recoverable venom | Actual gland/reservoir, connecting duct and a real anatomical injection structure; explicit Poison-preparation chemistry | `creature.venom`; no inference from warning colour, contact toxicity, fang shape alone or a generic toxin value |
| Dye-bearing ichor | Actual circulatory-fluid reservoir/profile with explicit extractable Magenta pigment chemistry | `creature.ichor.magenta`; no other unnamed Ichor output. Glow, external pink colour or Caustic emanation is insufficient |

Supporting limbs and accessory appendages remain distinct. A quadruped with membrane accessories still has four supporting legs; accessory count is not the total limb inventory. Claw anchors must name the actual limb terminals, not blindly reinterpret each wing/fin as a foot. No jaw or hard weapon is supplied to an amorphous source merely to make these profiles fit.

Down is a **separate anatomical declaration**, not a bonus roll over a Fur Pelt. A new producer may explicitly construct soft body plumage within its existing covering allocation; it must reconcile that region with the covering manifest before admission. The same covering region yields Down or Pelt/Hide, never both. Actual flight/contour feathers on separate appendages can coexist. No new free insulation, armour, flight, attack, status or survival stat is added by identifying the layer or a gland.

Fluid records retain `reservoirPartID`, physical phase, exact chemistry profile, recoverable portion budget, active fraction and preparation stability (finite0…100, positive usable fraction/stability), plus actual fluid coloration/Pattern. These are new source properties, not aliases for an old six-property sample. The profile establishes suitability for its named preparation; quality does not secretly change the preparation's dose. A gland/injection record does not independently grant Poison attacks; natural combat changes would need their own rules. Ichor is a specific material profile, not a universal synonym for blood, healing fluid, acid and dye.

## 3. Recovery, quality, source appearance and value

Use the solid-part contract's existing successful ordinary-victory settlement, exact source identity, once-only custody and no extra harvesting action. No bottle item, portable kit, knife, fee, decay timer or new success roll is added for fluids. A material portion includes ordinary recovery/containment as part of that abstract reward; it does not create a reusable container economy. Existing flight/encounter access still governs whether the creature can actually be defeated.

**Species yield:** membrane uses the established size/eligible-appendage quantity, counting only actual sheet-bearing appendages; Down uses the established covering size band. Teeth/claws/tusks and fluids require an explicit species `baseRecoverablePortions` budget1…4 per eligible family, attached to the real part/reservoir. Aggregate multiple contributing parts into that single frozen budget rather than awarding the full budget per tooth, claw or gland. Ordinary teeth, unsupported anatomy and empty/unusable reservoirs yield0. A portion is usable craft stock, not a claim of an additional literal tooth or litre.

Apply the already-decided Anatomy recovery bonus once to each positive family total: q + max(1,floor(.35q)), hence1/2/3/4 →2/3/4/5. This improves usable recovery from the same source and does not grow extra organs. Keep Bone's separate1–3 base rule and Hide's existing70% rule; no second award through the legacy projection.

| New part | Actual quality expression |
| --- | --- |
| Fang / Claw / Tusk | Mean of part hardness and structural integrity |
| Down | Mean of actual layer insulation and flexibility |
| Membrane | Mean of actual sheet coverage and flexibility |
| Oil / Venom / dye-bearing Ichor | Mean of the fluid's active fraction and preparation stability |

Apply the same unrounded75% expression +25% saved source-Danger value, then round-half-up once into Poor/Common/Rare/Exceptional. Preserve the original source measurements; neither rarity names nor stock grouping create averaged source parts. Only an explicitly named stat-bearing gear socket applies the usual .75/1/1.25/1.5 multiplier.

Full actual CMY/Depth/Pattern and provenance survive recovery, Return, grouping, selected use, save/reopen and recovery from equipment. A part's explicit appearance overrides its parent's appearance only for that part; retain both records. Unassigned part appearance inherits the actual specimen record, not white tooth/Down or green Venom defaults. Recipe preview uses the actual selected visible component; don't invent RGB where the colour mapping is not implemented. Fluid preparations may deliberately transform material under their named chemistry, while retaining the source receipt. This never makes any brightly coloured fluid a pigment.

First-pass raw nominal sale for Fang/Claw/Tusk/Down/Oil/Venom/dye-bearing Ichor is2/4/8/16; buy twice sale where actually offered. Membrane uses the new raw Skin values2/3/6/12 because it is an eligible skin source; its Leather then adds the actual Salt value. Existing Hide/Bone/legacy values are unchanged. No merchant stock or guaranteed encounter source is introduced.

## 4. Narrow optional consumers — first-pass proposals

These extend exact sockets, not a universal substitution system. Every other cost, unlock, output identity, source selection, workmanship calculation and recovery rule stays with the complete shop contract. No new Essence fee or ingredient is required in the ordinary route.

| Material / exact proposed use | Optional bundle change | Effect |
| --- | --- | --- |
| Fang, Forge Pointed Blade | Replace its1 Bone point with1 Fang; retain its separately paid grip | Physical point only, not a Bone grip alternative |
| Fang, Bowyer Longbow | Replace its1 Bone point with1 Fang; retain2 Hardwood Logs, Resin and Cord | Point, not bending bow limbs |
| Fang, Weaponsmith Pointed Weapon or Polearm | Replace its1 Bone head/point with1 Fang; retain the complete haft/binding/Collar bundle | Point only |
| Claw, Forge Cutting Blade or Weaponsmith Edged Weapon | Replace its1 Bone edge with1 Claw; retain all other components | Cutting edge only |
| Claw, Bowyer Throwing Blades | Each of the2 separately selected edges may use1 Claw in its existing Bone/metal socket | Average the2 actual edge contributions; no extra blade or attack |
| Tusk, Weaponsmith Polearm | Replace its1 Bone point with1 Tusk; retain2 Hardwood Hafts, complete binding and Collar | The declared long-point use; not an automatic Maul or haft |
| Down, Armoury Insulated lining only |2 Down for Body,1 for Head/Hands/Feet, instead of that lining's Cloth bundle | Existing outer and binding enclose the lining. Balanced/Rigid and the no-Insulated-offhand rule stay unchanged |
| Membrane, Tannery Leather |1 Membrane +1 Salt →1 Leather,0 Essence | Preserve actual sheet hardness/coverage/flexibility/length0, source quality/appearance and Salt receipt; same existing Leather consumers |
| Creature Oil, Distillery Heat Core |16 Essence +2 Sulfur +1 Creature Oil instead of the Resin route | Same fixed potency60 and existing Core identity/effect |
| Creature Venom, Apothecary Venom coating |1 Creature Venom +1 Plant Fibre instead of Toxic Sap +Fibre | Same Poison2 for4 status turns; preparation stays on that weapon for the full excursion |
| Dye-bearing Ichor, Scriptorium Magenta |1 explicitly pigment-qualified Ichor →4 Magenta measures,0 Essence | Existing measure/vial rules; no new requirement in place of Dyer's Root |

For Fang/Claw/Tusk primary weapon sockets, measurement = mean(actual hardness, actual structural integrity). Power = existing Bone-role ceiling × (.5 + measurement/200) × actual band multiplier; ceiling4 in Forge/Weaponsmith and3 in Bowyer. Average separately selected Throwing Blade edges before the one existing quarter rounding. The new material votes its actual band in that same designated primary workmanship group; no second multiplier, minimum damage-axis eligibility or legacy Power is added. Tusk does not get bonus reach beyond the Polearm's already-owned reach.

For Down lining, use the mean selected Down quality rank in place of that Insulated recipe's Cloth lining rank1. The structural outer still alone supplies Protection; Down grants no extra Heat Ward. The existing profile continues Head15/Body25/Hands10/Feet10, applied once through Heat Ward, with the established cap. No cold/weather protection, Burn immunity or additional insulation stat is implied. Its real quality affects workmanship and price, not an unannounced stronger ward. Actual source colour is used wherever the lining is visibly exposed; no invented exposed region is required.

The full active construction records all selected parts. New physical gear nominal sale C is the sum of active recoverable component values; buy2C. Refit/rebuild returns or reuses exact old components once and installs exact paid new components; it never refunds an ingredient twice or returns both Leather and the raw Membrane/Salt ancestors. Fluid preparation consumes its raw ingredient under the existing recipe owner; an exhausted coating or dismantled Core does not refund raw fluid. New Oil Core value is16 plus the actual Sulfur/Oil values, just as the Resin variant uses its real catalyst values. No quality-derived Core potency or coating damage is introduced.

These are conditional recipe extensions for actual typed producers. The baseline Resin Heat Core, Toxic Sap Venom coating, Dyer's Root Magenta, Cloth lining and existing Bone/metal equipment remain complete. Do not delay Engineering's full Apothecary batch or advertise unavailable animal alternatives before the producer, recipe adapter and truthful disclosure are implemented together.

## 5. Bounded acceptance examples and honest remaining scope

Design examples, not executed native results:

- Pierce80, no jaw/tooth entry:0 Fang. Actual injected-venom chemistry absent despite `isToxic`:0 Venom. Light emanation with no fluid:0 Ichor. Real combat behavior remains unchanged.
- Two actual Fang point portions with hardness80/integrity60, Danger2: expression70, score65 Rare. Base2 gives3 portions with Anatomy, not an invented third tooth. Forge point Power4×.85×1.25=4.25; Bowyer point3×.85×1.25=3.1875→3.25.
- A tusk part cannot also enter the Fang pool. A real quadruped limb terminal may own a Claw even when its accessories are membrane wings; the wings do not supply claws merely by index.
- Flight feathers without body Down: no Down. Explicit soft Down region and separate flight-feather appendages may yield both; the Down region cannot also yield Pelt/Hide. Replacing Cloth lining with Exceptional Down changes the one workmanship vote, never the fixed ward/Protection.
- Fin web coverage80/flexibility60/hardness40, Danger2: score65 Rare; actual protection32. Raw Membrane value6 +Salt1 becomes Leather value7. No generic Fin bonus; no use of the main body's covering metrics.
- Oil active fraction80/stability60, Danger2: Rare, sale8. Its Heat Core remains potency60 at16 Essence +2 Sulfur +1 Oil, regardless of band. Toxic Sap remains sufficient for ordinary Venom preparation; a creature source is optional.
- Magenta-qualified fluid yields4 measures even if its external source creature is blue. A pink or luminous animal without that chemistry yields none. Ink retains its specified transform and source receipt.
- Same quality/type, different source colour or measurements: retain distinct selectable lots. Failed save/repeated settlement pays nothing extra; legacy sources retain their recorded rule and no new organs.

**Progress against Aimee's three goals:** Body → materials now has explicit eligibility, part measurements, quantity ownership and narrow consumers for all previously held families; existing-solid equipment roles beyond this extension and actual generation prevalence remain unfinished. Ecological coherence gains honest anatomical/chemical constraints without pretending damage or habitat proves physiology; other food/weather/shelter behavior remains separate. The player journey now names an optional source → selected component/preparation → result → recovery route, but its actual native implementation, visual truth and natural exploration/crafting feel still need integration/playtesting. All three broader goals stay open. No new owner approval, testing framework, speculative art request or Design native recheck is created.
