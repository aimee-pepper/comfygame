# Briar Oil: physical-input compatibility adapter

> **5 September batch supersession:** Retained as an interim compatibility/design record. Do not queue this as an isolated next-recipe implementation or treat its preserved legacy behavior as the final overhaul. See `crafting-shop-batch-overhaul-2026-09-05.md`. Excursion-long coatings remain the accepted destination; the Bone choice is now part of the whole Blacksmith batch.

5 September 2026. **PM reports the bounded bridge delivered in development. Design trusts that report; phone availability is not established here.** Scope is one existing Apothecary preparation's named-input migration. It preserves the third property-qualified resource rather than inventing a replacement recipe. No new facility, coating, affliction, material producer, guarantee or creature migration.

## Why this consumer is next

The overhaul roadmap's maker sequence places Apothecary preparations/coatings after the initial preparation, weapon and protective-item slices. Briar Oil already has an authored recipe and combat consumer; Stem/Leaf Fibre and Resin already have early physical custody. This adapter gives those holdings an existing additional use while Forge/Tannery/Carry and the pending Bone proposal remain separate.

Source/design authority: `apothecary-coating-identity-current.md`, `consumable-economy-field-kit-current.md`, `combat-affliction-authority-current.md`, the early physical material set, and `resource-world-first-pass-tuning-v1.md`. Source owners inspected: `ConsumableCraftingRules`, `SmithRules.candidates`, `BaseState.craftMaterialSelections`, `TradingPostRules`, `CombatRules` and the current item definition. No native/delivery checks were repeated.

## Exact transaction

| Input or output | Rule |
| --- | --- |
| Facility/access | Home, built Apothecary, known `briar_oil` recipe; existing station access. No T2 upgrade, research, attending Nessa requirement or new schematic grant. |
| Named carrier | **1 Plant Fibre**, exactly Stem Fibre `flora.fibre.stem` or Leaf Fibre `flora.fibre.leaf`, from owned physical lots. No Bark Fibre, Cord, Cloth, Hide or guessed generic Fibre. |
| Named resin | **1 Resin**, `world.resin`, from its exact physical custody owner. Proven compatible legacy scalar Resin may use the existing compatibility reader, without fabricated source history or a second balance. |
| Separate flexible resource | **1 existing World-domain property-bearing material unit with recorded Flexibility ≥50**, exact owned unit and full existing receipt. It is an additional ingredient, not a property inferred onto the named Fibre above. |
| Cost | **0 Essence, 0 Motes, 0 Gold fee, 0 world turns.** Three separate input portions per copy. |
| Output | **1 Briar Oil**, existing `briar_oil`, identified consumable, existing icon/name and `coatBleed` effect. No new inventory material or extract stage. |
| Quality/stat | Standardized preparation: no new quality band, workmanship, material-stat multiplier, stronger Bleed or new effect from source grade/density/colour. Keep authored Uncommon item rarity distinct from material quality. |
| Price | Existing ordinary item sale **5 Gold**; existing legitimately generated merchant stock quotes **15 Gold**. Existing sale restrictions remain. Do not apply raw-material multipliers or create merchant stock. |

This is deliberately a compatibility bridge. Newly gathered named Fibre/Resin can now satisfy their existing jobs, while the third ingredient still needs a real supported property record. Having two new Plant Fibre portions and Resin is **not sufficient**. Their current typed lots do not contain a Flexibility measurement, and calling all Fibre “50+” would invent eligibility. The bridge does not claim that every fresh early campaign can already source the third ingredient.

### Source-domain distinction

The settled coating recipe says flexible **world resource**. The current generic Smith selector scans both World and Creature reserves. Preserve that existing broad behavior on the **legacy preparation path**; do not silently change old recipes/items while migrating named slots. This new explicitly versioned bridge follows the settled World-domain requirement. New typed creature materials, including typed Hide/Bone, and prepared Leather cannot enter through a family or old-shape fallback. An old recipe's use of an old Creature unit does not authorize a new typed material to bypass its consumer hold.

This narrow distinction is intentional and reviewable: legacy preparation remains available with its exact old requirements; the new physical-input choice lists its own eligible flexible world resources. It does not globally redefine Smith eligibility or turn old stock into new stock.

## Knowledge, selection and preview

Keep the existing inference structure: built Apothecary, at least one eligible flexible world-resource unit, and at least one of the named reagent kinds owned. Extend that named-reagent check to actual physical Plant Fibre/Resin for this bridge. Full recipe quantity is not required to learn it; learning never grants missing stock. Existing known recipes remain known. Use the existing durable inference entry point, not a view-render mutation or a new guaranteed reward.

One quote names the selected Fibre subtype/quantity, Resin quantity, exact flexible unit, output count, zero fee, current Essence after preparation and the actual Storehouse/Waiting destination. Fixed-output source differences are not quality choices. The player may deliberately choose which existing flexible resource to spend; no hidden six-band cost is applied. Outcome-neutral lots within the confirmed physical type may use the existing deterministic oldest-eligible order. Retain full provenance even when no extra source-colour picker is necessary.

No unit or quantity may satisfy two input roles. If compatibility views expose the same underlying holding more than once, resolve them to one owner and ensure disjoint deductions. Do not materialize scalar copies, silently fall back to generic Fibre, substitute a higher grade or consume from the carried Field Kit. A stale source/selection, changed station/knowledge, malformed unit, insufficient quantity, cancelled review or failed durable save spends nothing and reports no success.

Keep the existing shared quantity control if available; total costs for n copies are n Fibre + n Resin + n distinct flexible units, output n. Do not simulate a batch by repeatedly committing until one fails. A missing output slot follows the existing Storehouse merge/Waiting path, not silent loss or automatic Field Kit packing.

## Historical input-only scope — lifetime is not final design

Crafting creates a bottle. Applying it through the existing legal target/action path consumes one bottle and prepares the selected member's eligible physical weapon. Keep Channelworks restrictions, action cost, target validation and existing replacement/refusal behavior; this adapter does not introduce an extra attack or a second preparation slot.

The prepared charge persists across a miss. The next successful weapon strike consumes that charge even if the hit defeats the target; a defeated target receives no new wound. Against a surviving target it applies the existing ordinary **Bleed: 2 damage at each of 3 round boundaries**, subject to the existing affliction rules. It does not add an immediate fourth tick. Existing Stonebark prevention, same-kind maximum refresh, actor/target ownership, cures and encounter cleanup remain authoritative. Ingredient properties do not change severity or duration. That encounter-only lifetime was retained by this delivered input bridge. It is temporary runtime behavior, not intended design. The accepted replacement lasts one excursion across encounters and relaunch; see the complete Apothecary batch.

Finished supplies retain the authored recognizable Briar Oil appearance. Selected raw colours stay in the preparation history rather than tinting the bottle into a different apparent supply. The output is not equipment and supplies no Recycler salvage or recipe-ingredient refund.

## Custody, durable history and legacy coexistence

Add one explicitly versioned route to the existing consumable quote/commit owner, e.g. `briar-oil-physical-inputs-v1`. Reuse its expected output identity, destination, before/after state and durable-save boundary. Extend the quote with selected physical lot deductions plus the separate existing property-unit selection; do not send typed lots into the old sample calculator.

Freeze an immutable preparation receipt: route/version, recipe ID, exact owned input IDs/quantities and source receipts, selected type, retained legacy facts where present, output ID/count/destination and paid costs. On merging identical standardized bottles, retain each contributing batch record and its quantity association without inventing source history for older unreceipted bottles. This history confers no quality or hidden price difference. Normal item use/trading/Return may handle the same gameplay-equivalent bottle; they must not duplicate its ownership or rewrite earlier origins.

All input deductions and output placement save together. The success UI follows that durable commit. Retry/reopen cannot replay a spent quote; Waiting output remains claimable through its existing owner. Preserve the saved Field Kit plan, packing capacity and ordinary Return loss/protection rules. A later cosmetic update does not remake preparations.

Legacy scalar Fibre/Resin, compatible property units, old quotes and already prepared Briar Oil retain their existing supported route, effect and price. No world generation flag, material conversion, stock-quality mapping or old save rewrite is required. The bridge never makes generic legacy Fibre into Stem/Leaf Fibre. Unsupported typed-material versions fail explicitly.

## Concrete review cases

| Owned state / action | Expected |
| --- | --- |
| 1 Stem Fibre, 1 Resin, World unit A Flexibility 50; known recipe, built Apothecary, Home | Quote 1 Briar Oil, 0 Essence; commit exactly those inputs once. |
| Same, but A Flexibility 49.99 | No bridge craft; show missing flexible world resource 50+. No rounding into eligibility. |
| 2 Leaf Fibre, 1 Resin, no property-bearing unit | No craft. Do not assign fictional Flexibility to the extra Fibre. |
| 1 Leaf Fibre, 1 Resin, eligible World A and B with different old grades | Player selects A or B. Same standardized output/effect/price; chosen unit alone is spent. |
| Typed Hide/Bone with high values is the only third candidate | Ineligible for the new bridge. No family or six-band fallback. |
| Eligible legacy Creature unit and full old scalar recipe | Existing legacy route retains its old behavior; this bridge does not reinterpret or remove it. |
| Eligible flexible unit and only Resin, no Fibre; recipe not yet known | Existing-style inference may learn Briar Oil; preparation still reports the missing Fibre. |
| 2 Fibre + 2 Resin + only 1 eligible flexible unit, request 2 copies | Whole batch refuses, no partial spend. One-copy quote remains possible. |
| Full ordinary inventory, no merge target | Preview Waiting; commit preserves one claimable bottle there and the preparation receipt. |
| Cancel, changed unit after quote, failed save, replay | No extra deduction or bottle; successful retry after a fresh quote commits once. |
| Buy named Fibre for 2 and Resin for 4, plus any legitimately priced third input; craft/sell | Output sells 5: below even the 6 Gold named-input subtotal. No buy/craft/sell profit. |
| Apply bottle, miss, then hit living foe | Bottle consumed at preparation; charge retained on miss, spent on hit; existing Bleed rules apply. |
| Hit defeats foe | Charge spent; no new Bleed/Stonebark event on defeated target. |

## Readiness and the one optional later simplification

**Implemented per PM delivery report:** named physical Fibre/Resin admission, exact retained third World-resource requirement, existing access/inference shape, output/effect/quality/price, transaction history, Field Kit/Return and legacy coexistence. No new Aimee decision is needed for this bounded bridge. Its natural acquisition/affordability and phone availability remain separate from the reported development delivery.

**Recipe proposal now covered by the whole-shop batch:** replace the old flexible-resource slot with one additional Stem/Leaf Fibre, making the complete recipe 2 Plant Fibre + 1 Resin. This would remove the property-record dependency and make an all-new-material route, but it changes the authored eligibility rather than merely adapting custody. Do not infer or implement it from the bridge. No new homework approval is required to proceed with the settled portion; present this simplification when choosing the fully migrated Apothecary recipe, not as a blocker to current work.
