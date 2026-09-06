# Typed Bone → existing Pointed Blade: compatibility contract and proposal

> **5 September batch supersession:** Retained as an interim compatibility/design record. Do not queue this as an isolated next-recipe implementation or treat its preserved legacy behavior as the final overhaul. See `crafting-shop-batch-overhaul-2026-09-05.md`. Excursion-long coatings remain the accepted destination; the Bone choice is now part of the whole Blacksmith batch.

5 September 2026. **Historical isolated proposal, superseded by `blacksmith-whole-shop-production-v1.md`.** The whole-shop packet now supplies Design-authored first-pass Bone roles, mixed new-material bundles, prices and recovery under delegated tuning authority. This is not a personal Bone approval attributed to Aimee; the old isolated approval/implementation hold below is no longer the active instruction.

## Existing consumer and settled rules

Source owners inspected: `PhysicalGearCraftingRules.pointedBlade`, preview/craft/materialEffects; `RecyclerRules` construction-receipt recovery; existing Blacksmith foundation schematic grant. This is source evidence, not a new delivery check.

| Concern | Existing/settled authority |
| --- | --- |
| Recipe identity | Existing `pointed_blade`; one `point.0` primary and one `grip.0` secondary. Both already accept legacy Bone, one distinct material unit each. Weapon, Pierce, Close; existing fallback item identity is `blade_chipped`. |
| Access | Existing unlocked Blacksmith and known Pointed Blade schematic. Its minimum effective tier is 0. Current early foundation grants the schematic; this adapter grants no person, station, schematic or research. |
| Legacy calculation | Six material ranks; rounded 70% point / 30% grip sets output band/tier. Essence base is 12/24/48/80 for tiers 1/2/3/4, 80 otherwise; rank 0 uses tier 1 for pricing. Existing staffing discounts apply. Bone has no extra material-effect bonus. Preserve this complete path for legacy inputs and existing items. |
| New Bone | Strict typed `creature.bone` with validated actual-source boneDensity, size, four-band quality, full CMY/Depth/Patterning, source IDs and generation/reward history; body/Bone producer implementation still pending. No Hollow/Dense subtype inferred. |
| Four-band arithmetic | Poor/Common/Rare/Exceptional ranks 0/1/2/3 and contribution multipliers 0.75/1/1.25/1.5. Role contribution is ceiling × (0.5 + named source measurement/200) × multiplier; final continuous statistic rounded once to quarters. |
| Workmanship | Primary 70%, secondary structural 30%; round half up to Rough/Fine/Superior/Exceptional. No Standard result and no ordinary Peerless output. A workmanship name does not multiply already-calculated material stats again. |
| Provenance | Exact selected units, independent component colours, frozen output and exact recoverable components. Legacy material is not guessed into new source facts. |

Authority: [Bone producer](creature-bone-production-v1.md), [first-pass arithmetic](resource-world-first-pass-tuning-v1.md), cohesive overhaul, and the existing Pointed Blade socket/Balanced-material records. The old six-to-four migration table is a one-way migration policy, not permission to reverse-map new Bone into six-band crafting or migrate stock in this slice.

## Historical isolated proposal — no longer an approval request

Let the **existing** Pointed Blade use two pieces of new typed Bone, one point and one grip, for **0 Essence**. Retain its two existing sockets, access, identity, Pierce and Close behavior. No Log, Coal, Fibre, Ingot, new recipe, new unlock or mandatory processing step is added. This is a narrow new calculator for an already-supported material combination; other legacy choices remain available under their old rules.

Three Bone-specific choices are proposed together, not claimed as previously settled:

1. **Point contribution:** use the point source's actual boneDensity as its named structural attack measurement, with the already-settled primary ceiling of 4 **Power**. This is a crafting measurement choice, not a claim that boneDensity equals material Hardness or a new anatomical cutting-edge measurement. Do not substitute the source size, part-quality score, rounded species traits or danger score.
2. **Grip:** retain Bone's existing Balanced role: required structure, separate source colour and a 30% workmanship vote, but no extra numeric Power, Initiative, ward or value bonus. Bone has no authored flexibility/lightness measurement for this grip. It is explicitly a non-stat-bearing socket; do not invent a consolation bonus. Point quality improves Power; grip quality improves the workmanship result.
3. **Fee and item resale:** 0 Essence; no grade-linked fee. Proposed ordinary sell value for this exact typed-Bone output is the sum of its two selected Bone portions' nominal raw sell values, frozen in the quote. This adds no craftsmanship premium or new merchant stock. It is a named item pricing rule, not a global rule for finished gear.

Rationale: preserve the useful raw-material construction choice while separating quality, performance and fees. It supplies an optional Bone use without making creature hunting a new starter requirement. Balance remains first-pass, not a demonstrated improvement over the starter Iron blade.

**Aimee choice:** approve this bounded Bone option (two Bone, no Essence fee; point supplies Power, grip contributes workmanship/colour, resale preserves the two portions' nominal value), or retain the crafting hold while revising it. Aimee need not author conversion tables. Engineering may implement only after this choice and the independently authorized typed-material prerequisites are resolved.

## Exact proposed calculator

For point source density `d`, point rank `p` and grip rank `g`:

```
pointPower = 4 × (0.50 + d/200) × multiplier[p]
finalPower = floor(pointPower × 4 + 0.5) / 4
workmanshipRank = floor(0.70 × p + 0.30 × g + 0.5)
workmanship = [Rough, Fine, Superior, Exceptional][workmanshipRank]
sellGold = [2,4,8,16][p] + [2,4,8,16][g]
Essence = 0
```

Power is the equipment contribution used by the existing combat pipeline, not a promise of that much HP damage on every hit. Keep the current attack/stat/armour rules. The existing preview precision applies; the saved quarter value remains authoritative. No legacy rank-base Power, strongest-positive bonus, construction-tier power, new density penalty, generic item-price fallback or second quality multiplier may be added.

Same-band pairs sell for 4/8/16/32 Gold. Two legitimately purchased raw portions cost twice their summed sell value, so buying inputs → crafting → selling returns half the purchase price, never a profit. Colours, species, density, final workmanship and staffing do not alter this quoted resale rule. Crafting does not refresh shop stock. A price revision affects new quotes under its version; it does not silently recalculate existing frozen items.

## Admission and legacy compatibility

- Dispatch by explicit typed receipt/version and adapter identity, not the word Bone, family enum or overlapping quality names. Proposed construction authority `typed-bone-pointed-blade-v1` is distinct from the legacy calculator and the starter Iron recipe.
- First slice admits **two valid typed Bone units only**, independently selected for the two existing sockets. At least two available units are required even if they share a source. One unit cannot fill both sockets. Different sources, densities, colours and quality bands may be selected; no same-source requirement is invented.
- This slice does not bridge new Bone to legacy Bone, six-band Fang/Pelt, or the separate ungraded Iron/Log ingredient path. Such mixed recipes require their own explicit role mappings. Show the incompatibility before spending. Preserve every old recipe's legacy options.
- Require Home, existing access, unlocked station, exact current ownership and destination checks. Quote both roles, units, bands, colours, final Power/workmanship, 0 Essence, resale and destination. Never auto-substitute quality or colour. Cancel, malformed source, stale unit, wrong version, duplicate socket or failed save spends nothing.
- Do not enable body/habitat or Bone generation, convert old stock, migrate a creature, retrofit an old weapon or copy new rules into a current early campaign as part of this adapter contract.

## Frozen output, use and salvage

The new output retains its stable item identity and Pointed Blade family, plus a versioned construction record holding ordered point/grip unit receipts, exact source IDs/measurements/full colours, input bands and ranks, named contribution policy, unrounded point contribution, final quarter Power, workmanship, paid cost, resale policy/value and destination. Preserve both independent material colours; do not average them, paint Bone white, or fabricate missing RGB artwork.

Use a typed workmanship field and frozen gameplay facts. A new rank 1 Fine is not an old rank 1 Standard. If compatibility fields are required, they must not drive new-item Power, price, eligibility, salvage or display by reading the legacy rank/tier. Inventory, equipment/Combat and trading use the same frozen facts; reload does not re-run the latest tuning against an old item. Save/ownership failure cannot grant an item while leaving both components spendable.

**Retain the existing Recycler quantity rule**, rather than returning both inputs because provenance stores both. Construction receipts with two components recover one at each current service tier: max(1, floor(2 × 0.40/0.55/0.70)) = 1. Preserve existing service/access/cost and selectable component behavior. Default receipt order is point then grip; the player may choose the eligible recorded component within that capacity. Return exactly that typed component's source, quality and colour through the existing ownership-safe recovery path; destroy the item and unrecovered component once. No Essence refund, quality reroll, Bone multiplication, generic family substitute or duplicate active unit. Old-item Recycler behavior stays unchanged.

New output refit/reforge/Peerless paths remain unavailable until their own explicit adapter supports this receipt. Existing legacy-item paths continue unchanged. Merely sharing the Pointed Blade display family cannot send new typed stock or output into an old six-band calculator.

## Worked review examples

These are calculator examples, not native test receipts. Density/quality examples below are available from the Bone producer's valid actual-source cases.

| Point / grip | Point density | Power (unrounded → saved) | Workmanship | Sell | Recovery |
| --- | ---: | --- | --- | ---: | --- |
| Poor / Poor | 20 | 1.8 → 1.75 | Rough | 4 | one selected Poor portion |
| Common / Common | 40 | 2.8 → 2.75 | Fine | 8 | one selected Common portion |
| Rare / Common | 80 | 4.5 → 4.5 | Superior (1.7 → 2) | 12 | chosen Rare point or Common grip |
| Poor / Exceptional | 20 | 1.8 → 1.75 | Fine (0.9 → 1) | 18 | chosen Poor point or Exceptional grip |
| Exceptional / Poor | 100 | 6 → 6 | Superior (2.1 → 2) | 18 | chosen Exceptional point or Poor grip |
| Exceptional / Exceptional | 100 | 6 → 6 | Exceptional | 32 | one selected Exceptional portion |

The mixed Poor-point/Exceptional-grip example is intentionally honest: a Fine workmanship name does not turn a weak point into a high-Power weapon. Always preview the actual number. A Common source with density 60 would give 3.25 saved Power instead of density 40's 2.75; source variation remains meaningful within the same band.

## Completion boundary

Closed: existing consumer/slots/access, legacy isolation, four-band workmanship arithmetic, exact source selection and output/recovery ownership, bounded input scope, and identified new numerical/cost/pricing choices. **Pending Aimee:** the proposed Bone role/fee/resale bundle. **Pending Engineering:** typed Bone producer and consumer implementation under separately authorized versions. No new native checks, delivery audit, broad crafting migration or alternate weapon recipe was performed or assigned by Design.
