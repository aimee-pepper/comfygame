# Bone from generated bodies — bounded producer and custody contract

**5 September 2026 · Decided intended contract, awaiting implementation assignment.** This advances the first creature Homework goal; it does not complete that goal or the wider rework. Bone implementation remains separate from the Bestiary arrangement, whose work hold Aimee lifted on 5 September; see creature-role-coherence-v1.md section 8.

**Scope:** one canonical raw material, **Bone**, from generated ordinary creatures, through reward, carried stock, Return, Storehouse and the existing Trading Post material-sale consumer. Current Bone-compatible crafting is recorded accurately below; a new-material crafting adapter is a separate unfinished dependency. No new weapon recipe, maker unlock, anatomy catalogue or final art is approved here.

**Starting authority:** body/habitat slice `b0c24016c626cc69687fefb071c72d9058b8946d`; accepted physical Bone vocabulary, four-band quality/source-colour/market rules in the cohesive plan and first-pass tuning; retained skeletal eligibility and species quantity from `creature-material-projection-authority.json`; actual-body provenance discipline from the completed Hide path. Exact companion: `creature-bone-production-v1.json`.

## 1. Current behavior versus this intended slice

Inspected native source `d273b408a0e46061fa4de5ffc1164ff06bc3ecaf` in `early-material-regions-v1`. This is source inspection, not a new native acceptance claim.

- `CreatureMaterialProjectionRules` adds Bone when species boneDensity is at least 20 and bodyPlan is not amorphous. It freezes quantity as clamp(1 + floor(species size / 34), 1, 3). Habitat does not exclude a skeleton.
- `CreatureMaterialRewardRules` awards each projected Bone entry on its eligible defeated-specimen reward path, with Anatomy. There is no Bone chance roll. It uses rounded species expression and the older six-band score; the generic unit does not contain the full new actual-body/colour receipt.
- The live `pointed_blade` recipe in `PhysicalGearCraftingRules` accepts legacy Bone in either point or grip. Other authored recipe tables also list Bone, but that does not prove all those recipes are unlocked or natively accepted. The Pointed Blade preview still uses six-band ranks, tier/Essence pricing and older material effects.
- `TradingPostRules.materialSaleUnitPrice` currently values generic legacy Bone at base 1 plus the existing capability-count adjustment. It already has a typed Hide override, providing a concrete material-sale consumer to extend. This is not the intended raw-Bone market table.
- Existing material reserve, Return, sale and recipe selection operate on exact unit identities. Extend those owners; do not create a second Bone balance.

**Intended:** introduce strict typed Bone for newly opted-in creatures, with actual physical source and the accepted four-band quality and raw-material pricing. Preserve old Bone and its existing recipe/market behavior as Legacy. The new source is not ready to feed an obsolete crafting calculator simply because both records say “bone.”

## 2. One material, no invented subtypes

Canonical ID `creature.bone`; domain Creature; category **Hard Animal Part**; type **Bone**; no narrower subtype in this slice. The canonical ID must be interpreted with the new typed receipt/version, never inferred from the old family enum or name alone.

Bone means a useful portion of an internal mineralized frame. One inventory unit is a crafting portion, not an assertion that a creature has one whole bone. Existing boneDensity is the skeletal measurement: a shell, horn, fang or hard skin is not interchangeable with it.

No Hollow Bone, Dense Bone, limb-specific stock or aerial “hollow bone” inference is introduced. The current model has no explicit hollow/solid anatomy field; flight or a low number cannot be relabelled as proof. Segmented and radial creatures may have an internal frame if the existing skeletal rule establishes it; do not force Earth taxonomy onto generated forms.

## 3. Exact source eligibility and generation order

Requires the new body/habitat policy from the preceding slice. Proposed opt-in name `creatureBoneVersion = 1`, separately frozen on the book, generated species/source plan and reward. Nil preserves the old system, including older books already using early Hide or habitat policies.

After final habitat-conditioned morphology and before encounter reward planning:

1. Final species body is not amorphous and clamped species boneDensity >= 20.
2. Its validated persisted material projection contains the Bone entry, with the retained skeletal measurement/size pair and species quantity.
3. Actual placed specimen body is not amorphous and actual boneDensity >= 20.
4. Source fields, IDs, world Danger and colour are complete and valid.

Both species authority and actual body must qualify; neither a label nor an old projection alone is sufficient. For a new-policy species, disagreement between generated traits and its projection is a generation/receipt error, resolved before encounter admission, not silently repaired during reward settlement.

Strictly validate numeric inputs as finite and within 0–100 before using them. “Clamp” in the inherited formula is not permission to hide corrupt saved values. Keep full actual traits, species traits/projection, source world, species and specimen IDs, habitat, generation versions and pre-party/pre-debug Danger. No foreign species or neighbouring creature can supply a missing field.

For a valid new-policy creature without a qualifying skeleton, Bone output is zero. The new policy owns its Bone branch completely, including explicit ineligibility: do not fall through to a second generic Bone award. Other material families, including narrow Hide eligibility/rolls, remain unchanged.

## 4. Quantity, quality and colour

**Quantity keeps the existing species rule.** Freeze base quantity from species size before specimen jitter:

- size 0 through <34: 1 portion;
- size 34 through <68: 2 portions;
- size 68 through 100: 3 portions.

This deliberately does not use the Hide size/25 bands. Actual specimen size variation can describe the recovered part, but cannot reroll the species' number of Bone portions.

**Recovery keeps the existing Bone behavior:** a qualifying specimen on the ordinary successful-victory material-reward path supplies its frozen Bone quantity. No new chance roll and no shared 70% Hide roll. A failed encounter, non-defeat, repeated settlement or absent skeleton supplies no new Bone. Retain the existing reward admission rules; do not add harvesting turns, tools, carcass timers, dissection fees or a second loot action.

**Anatomy:** use the expedition-frozen strongest-once receipt, exactly as existing creature rewards. For positive base q, q + max(1, floor(0.35q)); base 1/2/3 becomes 2/3/4. Zero remains zero. No respec/roster/health changes may recompute that departure benefit or change quality.

**Quality:** use the actual source specimen's boneDensity and size, each 0–100:

```
partExpression = (actualBoneDensity + actualSize) / 2
score = roundHalfUp(0.75 × partExpression + 0.25 × sourceDangerValue)
Danger 0/1/2/3/4/5 → 20/35/50/65/80/95
Poor 0–24; Common 25–59; Rare 60–84; Exceptional 85–100
```

Do not round the average first. Keep the unrounded expression and actual measurements in the receipt. This applies the accepted actual-source quality rule; it does not alter the retained species quantity. Stat multipliers 0.75/1/1.25/1.5 are retained for future eligible recipe contributions, not new recipe permission.

**Colour:** preserve the actual source's complete validated Coloration (Cyan, Magenta, Yellow, Depth, Patterning), exactly as for Hide. Do not paint Bone white by default or synthesize a marrow/interior colour. Source colour is known functional identity even while the exact creature-to-RGB/art conversion remains unfinished. No normalisation, rounding, averaging, species fallback or reroll during storage, sale or Return. This authorizes no new art family.

## 5. Exact custody, display and commercial consumer

Use the existing Creature reserve and exact unit IDs. One plan may create several units, each with a unique stable ID referring to the same single reward and source. Freeze the award and quantity once, stage all changes, and save atomically; a failed save/retry cannot duplicate rewards.

Default display grouping is canonical Bone + four-band quality. Keep the actual source/measurements/colour underneath the compact stack. Unlike a crafting selector, a sale does not need a colour or source choice because those facts do not change its ordinary price. Select existing eligible units in the established deterministic order and freeze the exact selected IDs in the quote.

Existing Return rules determine what is recovered or lost, including protected outbound stock and the deterministic partition of newly gathered units. Both sides retain full source facts and add back to the carried quantity. No synthetic conversion of lost Bone to money; no extra capacity costs or protection.

The accepted **raw-material market multipliers** are 0.5/1/2/4, distinct from stat multipliers. Common Bone's base is 4 Gold:

| Quality | Sell per unit | Buy per unit, if legitimately stocked |
|---|---:|---:|
| Poor | 2 | 4 |
| Common | 4 | 8 |
| Rare | 8 | 16 |
| Exceptional | 16 | 32 |

Extend the exact typed-material branch of Trading Post valuation/selection/transaction. New Bone uses this table, with no capability-count bonus, species premium or colour premium. Quantity q costs q times the frozen unit price. Preserve the existing shop access and save/cancel/stale-selection behavior. This adds no merchant stock, buyback mechanism or guaranteed buyer encounter; the buy column governs stock only when an existing authorized source actually offers it.

Legacy Bone retains its original units, six-band record, value and consumer access. New and Legacy stock never silently merge, rewrite one another or become a scalar Bone balance.

## 6. Consumer designs closed; implementation remains required

The complete `blacksmith-whole-shop-production-v1.md`, `bowyer-whole-shop-production-v1.md`, `weaponsmith-whole-shop-production-v1.md` and `armoury-whole-shop-production-v1.md` now supply the explicit Design-authored first-pass Bone roles, quantities, source-based Power/Protection, four-band workmanship, values and recovery under Aimee's delegated whole-shop tuning authority. The former isolated Pointed Blade proposal/approval hold is superseded. These contracts are not personal new Bone approvals attributed to Aimee or evidence of native implementation.

New typed Bone must not enter the old six-band calculator through a family-enum/name match. Implement each complete shop's exact versioned typed consumer, preserving actual measurements/colour and frozen item/custody/value/recovery. Until its consumer is implemented, that operation refuses typed Bone; custody/Return and the specified trade route remain independently implementable. This is a named implementation dependency, not a fresh design question or a permanent ban on the specified recipes. Unsupported consumers remain excluded.

Legacy Bone and already-crafted items retain their exact compatible old recipes, quotes, profiles and values. Do not project the new raw-Bone market values into the old family calculator. This source→reward→Return→sale packet is independently implementable after body/habitat integration; a complete crafting journey additionally requires the appropriate whole-shop consumer.

## 7. Concrete acceptance examples

These are expected results for eventual implementation, not executed native receipts.

| Species / actual specimen / source | Expected |
|---|---|
| Quadruped; species size 20, boneDensity 19.99 | No Bone |
| Amorphous; size 80, boneDensity 100 | No Bone despite high density |
| Aquatic piscine; species/actual size 34, density 40, Danger2 | 2 Bone, expression37, score40 Common; Anatomy gives3; sell4 each |
| Aerial winged serpentine; species/actual size68, density80, Danger3 | 3 Bone, expression74, score72 Rare; Anatomy gives4; no automatic Hollow subtype |
| Non-amorphous; species/actual size0, density20, Danger0 | 1 Bone, expression10, score13 Poor |
| Non-amorphous; species/actual size100, density100, Danger5 | 3 Bone, score99 Exceptional; sell16 each |
| Species size33.9, actual size34.1, density40, Danger2 | Base1 remains1; actual expression37.05, score40 Common |
| Valid species Bone receipt, actual amorphous body | Refuse inconsistent new-policy source before encounter admission; no generic Bone fallback |
| Qualifying Bone skeleton plus a qualified Hide covering whose 70% roll misses | Bone remains eligible; no typed Hide; no extra generic covering/Bone award |
| Identical Common Bone, two colours/worlds | One compact Bone-quality stack with exact sources; ordinary price4 per unit, no invented colour choice for sale |
| Sell2 Rare Bone, then Cancel | Quote16 Gold; no units/Gold change |
| Sell2 Rare Bone successfully, reopen/retry | Exact2 removed and16 Gold granted once; any retained units keep their source |
| Missing Patterning, malformed colour or unsupported new version | Reject typed operation without defaulting or rewriting legacy stock |
| Old book/new policy nil | Old Bone reward, market, recipes and saved placements unchanged |
| New Bone offered to old Pointed Blade calculator | Ineligible until explicit canonical adapter; old Bone remains usable |

Eventual bounded native proof: one isolated new-policy ordinary victory grants typed Bone; Return preserves it; Trading Post preview/Cancel preserves stock, then a separately committed sale/reopen changes the exact units/Gold once. Use Engineering's actual target iPhone/default text/current appearance. Include one no-skeleton refusal and a focused retry/failed-save check. Do not replay spent fixtures, start a paid natural search, open Library UI or create final art.

## 8. What is settled, what remains open

Settled for this slice: plain Bone identity, existing skeleton predicate and species quantity, actual-source four-band quality/colour, existing Anatomy behavior, exact custody/Return, and accepted raw-material market prices. These are carried-forward rules with a bounded new typed adapter.

Unfinished: full anatomical catalogue, implementation of the now-specified whole-shop Bone consumers, useful finer subtypes if supported by future anatomy, other materials and consumers, and natural incidence/pacing. No new user decision is required for this source/market contract. The first Homework checkbox remains **unchecked**, with Bone recorded as partial design progress; ecology and complete player experience remain untouched.
