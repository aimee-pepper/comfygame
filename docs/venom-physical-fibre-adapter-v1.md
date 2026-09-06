# Venom: physical Fibre compatibility adapter

> **5 September batch supersession:** Retained as an interim compatibility/design record. Do not queue this as an isolated next-recipe implementation or treat its preserved legacy behavior as the final overhaul. See `crafting-shop-batch-overhaul-2026-09-05.md`. Excursion-long coatings remain the accepted destination; the Bone choice is now part of the whole Blacksmith batch.

5 September 2026. **Implementation-ready Design contract; not implemented or delivered.** This is the next existing Apothecary coating migration after Briar Oil. Bone's separate proposal remains pending.

## Selection and authority

The accepted overhaul roadmap's Phase 7 names Apothecary preparations/coatings after the initial maker slices; the existing Nessa packet includes all four coatings. In the settled coating table, Venom is the first remaining coating with a named ingredient already supported by the delivered physical-material set: Stem/Leaf Fibre. Firebrand and Flashsalt require other named-material migrations. This is an ordering choice within that existing work, not a new recipe or a guarantee of when Nessa/materials appear.

Authority: `apothecary-coating-identity-current.md`, `consumable-economy-field-kit-current.md`, current affliction rules, early physical Fibre ownership, and the delivered [Briar Oil adapter](briar-oil-physical-input-adapter-v1.md). Source owners: `ConsumableCraftingRules` Venom recipe, `BriarOilPhysicalInputs` transaction seam, item definition `venom`, `CombatRules`, `Tuning.Encounter`, and `TradingPostRules`/`TradingPostTradeBand`. PM reports Briar delivered; Design trusts that report and performed no native/artifact checks.

## Exact existing recipe with one migrated named slot

| Fact | Required behavior |
| --- | --- |
| Access | Home, built Apothecary, known `venom` recipe. Keep existing unlock/inference; no T2, research, active Nessa assignment or new grant. |
| Fibre | **1 Stem Fibre or Leaf Fibre**, exactly `flora.fibre.stem` / `flora.fibre.leaf`, from Home physical holdings. Choose one type for a batch. No Bark, Cord, Cloth or guessed generic Fibre. |
| Toxin | **1 existing legacy scalar Toxin** (`toxin`) from its current owned balance. Preserve its legacy identity; do not convert it into a named sap, creature venom or a new universal typed Toxin. |
| Reactive ingredient | **1 separate owned World-domain property-bearing unit with recorded Reactivity ≥55.** Validate existing schema, exact ID/current receipt and finite 0–100 properties. No guessed property on Fibre/Toxin. |
| Cost/output | Three separate portions → **1 existing Venom coating**, identified `venom`; **0 Essence, 0 Motes, 0 Gold fee, 0 world turns**. |
| Quality/appearance | Standardized fixed preparation. Keep Uncommon item rarity and recognizable authored appearance. No new creature-quality band, source tint, potency bonus or workmanship. |
| Existing trade | Finished coating sells **5 Gold**, bought for **15 Gold** only when legitimately stocked. Retain sale restrictions and existing stock rules. Legacy Toxin retains its existing 2 sell / 6 buy table; no new-material pricing is substituted. |

The actual third unit is essential. A highly reactive creature unit, scalar Toxin, an extra Fibre, a prepared Venom bottle or an unadapted typed creature material cannot replace it on this bridge. Old recipes continue to use their old broad selection rules. The new World-only predicate follows the settled coating recipe and matches the Briar bridge's explicit domain boundary; it does not globally narrow Smith or remove old preparations.

The finished consumable named **Venom** is not the future raw creature material of the same word. Domain/record type owns that distinction, never display-name comparison. Toxin remains visibly legacy stock until a separate exact source/material migration proves what it physically is. This packet adds no Toxin harvest, new toxic plant, guaranteed stock or raw-venom producer.

## Learning and user selection

Extend the existing inference entry point with the bridge's evidence: built Apothecary, one eligible reactive World unit, and either owned physical Stem/Leaf Fibre or owned legacy Toxin. Full recipe quantities are not needed to learn the recipe; crafting still requires them. Keep the union with legitimate existing legacy inference, and never erase known recipes if inputs are later spent. No recipe is learned merely by rendering its card, seeing dangerous growth, suffering poison, or holding the finished coating.

Selection is one physical Fibre type, batch count n, and n distinct eligible reactive unit IDs. Toxin has one explicit legacy scalar owner in this slice; do not offer a fictional new-material source selector. Default physical source lots may use the delivered oldest-eligible rule because output is standardized. The player confirms the exact reactive units to be spent; older sample quality changes neither cost nor result.

Preview n Fibre + n legacy Toxin + n selected reactive World units → n Venom, zero fees, resulting Essence and actual Storehouse merge/new/Waiting destination. One quantity cannot satisfy two roles; resolve aliases to one owner and reject overlapping deductions. Positive count and overflow-safe arithmetic are required. Never silently mix Fibre types, substitute reactive units, draw from the carried Field Kit, or craft a partial batch.

## Transaction and output history

Reuse the existing `ConsumableCraftQuoteV1` and durable commit owner. Add a distinct route/receipt, suggested `venom-physical-fibre-v1`. Briar's existing quote stores a Briar-specific optional selection/receipt: extend that seam explicitly without labelling a Venom transaction as Briar or reinterpreting saved Briar records. A local shared helper is fine; no general recipe-engine rewrite is a prerequisite.

Freeze recipe/route version, output definition, count, exact Fibre lot deductions/source receipts, Toxin scalar before amount and deduction, n full reactive holdings, station/knowledge/currency state, output identity/destination and input/output before/after ownership. Append an immutable Venom preparation history entry on the same successful transaction, including legacy origin only as far as it is known. Do not fabricate species, colour or world for scalar Toxin.

Store the ordinary gameplay-equivalent bottles through the existing merge/Waiting path and preserve the batch-to-output association when merging. Do not mint another spendable balance in the history record. Failed save, changed stock, Cancel, stale quote or replay must leave source holdings, output/history and currencies unchanged. Save first, then report success. The current Field Kit plan is unchanged; future packing, Return and item use retain their existing owners. The output is not recyclable gear and refunds no recipe ingredients.

## Historical input-only scope — lifetime is not final design

Bottle consumption and coating-charge consumption are separate existing events: successful preparation on the selected eligible physical weapon spends one bottle; the next successful strike spends its charge. A miss retains the charge. Legal-target checks, physical-versus-Channelworks restrictions and action ownership remain relevant. The instruction to preserve encounter-only lifetime is withdrawn from future implementation: it is temporary runtime behavior, and the accepted whole-shop replacement is excursion-long preparation.

The current default Venom payload is Poison at **2 damage per round boundary for 4 boundaries**, from the existing Poison tuning. Do not copy Briar's three-tick Bleed duration or treat the consumable's authored potency 0 as zero Poison damage. Existing actor-owned modifiers, same-kind max refresh, Stonebark, target ownership, cures and encounter cleanup still apply; this input adapter changes none of them. Ingredient Reactivity 55 and 100 make the same standardized coating. There is no new instant tick or guaranteed total HP loss through prevention/cures/death.

A successful hit that defeats the target spends the prepared charge but creates no affliction/Stonebark event on that defeated target. Reload preserves the existing coating/affliction state; no additional roll, attack or action is introduced.

## Legacy and concrete cases

Legacy scalar Fibre + scalar Toxin + old qualified material continue through the unchanged old route, including its old candidate domain behavior. New physical Fibre enters only the explicit new route. No migration converts legacy Fibre or Toxin, no typed Bone/Hide hold is bypassed, and no old prepared bottle is rebuilt or repriced.

| Case | Expected |
| --- | --- |
| 1 Stem Fibre, 1 legacy Toxin, World unit A Reactivity 55; access/knowledge valid | Quote and make 1 Venom; deduct each exact input once, no fees. |
| A Reactivity 54.99 | Refuse the bridge; no rounding up to eligibility. |
| Fibre + Toxin only, or only a reactive Creature unit | No bridge craft; explain the separate reactive World resource. Existing old route remains independently available if it truly qualifies. |
| Extra physical Fibre or a finished Venom bottle offered as the reactive unit | Refuse; no invented property or bottle-to-input loop. |
| World A Reactivity 55 and B Reactivity 100, different old grades | Select either; identical output effect/price. Spend only the confirmed ID. |
| Eligible World unit + physical Fibre, no Toxin, recipe unknown | Existing-style inference can learn it; craft reports missing legacy Toxin. |
| Request 2 with 2 Leaf Fibre, 2 Toxin and distinct A/B | One atomic 2-bottle transaction, both histories/identities retained. |
| Request 2 but A selected twice, or Toxin drops to 1 after preview | Refuse whole quote; no partial bottle or deduction. |
| Full Storehouse without merge target | Quote Waiting; retain claimable output/history there. No automatic packing. |
| Cancel, save failure, reopened/replayed spent quote | No duplicate stock, history or output. |
| Buy physical Fibre for 2 + legacy Toxin for 6 + legitimate third unit; craft/sell | Sale 5 is below the 8 Gold named-input subtotal; no purchase/craft/resell profit. |
| Prepare, miss, hit surviving foe; then reload | Existing charge lifecycle and Poison 2/4/default registry behavior; no extra tick from reload. |

**Implementation disposition — superseded:** Do not implement this as the next isolated recipe. No Venom implementation has started. Retain this technical selection/custody analysis as reference for the complete Apothecary batch; the batch must reconcile final ingredients and the already accepted excursion-long lifetime. See `crafting-shop-batch-overhaul-2026-09-05.md`.
