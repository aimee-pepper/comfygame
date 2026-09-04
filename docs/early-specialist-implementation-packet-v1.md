# T2 smelting and the first useful specialist crafts — V1

**4 September 2026 · Decided intended behavior. All costs/statistics are first-pass tuning.**

Companion authored data: [early-specialist-production-v1.json](early-specialist-production-v1.json).
Depends on [the early route](early-progression-implementation-packet-v1.md) and its exact material sets.
This closes the earlier T2-versus-T3 proposal: **Blacksmith T2 makes Iron Ingots.** No other Ingot is promoted
without a consumer. Mercury remains ineligible. This packet does not block the first Salve or Pick delivery.

## 1. Two independent useful steps

T1 is a built working forge; T2 is smelting. For the current zero-based facility representation these are
stored tiers 0 and 1 respectively, with built state separate. Upgrade to T2 for **20 Essence, 8 Iron,
4 Clay and 4 Logs**, using only T1-accessible materials. No Ingot, later building, recruited-person count,
Mote, rare material, research, or attending assignment is required. The matching keeper remains the
facility owner; active posting is optional for these ordinary services. Old higher facility ownership is
preserved, not reset to charge this project again. If a saved tier mapping differs, explicitly map the
existing capability before applying this index rule; never interpret an unbuilt tier-zero record as built.

Smelt **2 Iron + 1 Coal → 1 Iron Ingot** for zero Essence. T1 recipes remain available from raw stock.
An Ingot is exportable prepared metal, not a mandatory new step on an already-known starter blade.
T3 remains later design; do not add a placeholder paid upgrade with no useful output.

Corrin's Tannery foundation is **20 Essence, 6 Logs, 4 Clay and 4 Plant Fibre**. It immediately teaches
Plant Cord, Plant Cloth and two garment recipes; it grants no free stock. This replaces the early Salt
foundation dependency. Salt will accompany the later Leather process, with an actual harvesting route.
The first useful garment needs only the fibre already available on the early route:

| Process or craft | Ingredients | Result |
|---|---|---|
| Plant Cord | 2 Stem/Leaf Fibre | 1 Plant Cord |
| Plant Cloth | 4 Stem/Leaf Fibre | 1 Plant Cloth |
| Woven Guard | 1 Plant Cloth + 1 Plant Cord | Fine Body equipment; **total Protection 1.5** |
| Buckled Woven Guard | 2 Plant Cloth + 1 Plant Cord + 1 Iron Ingot | Fine Body equipment; **total Protection 2.0** |
| Scythe 1 → 2 at Blacksmith T2 | Owned Scythe 1 + 2 Iron Ingots + 1 Log + 2 Plant Fibre | Same tool and roll place, iron working edge, tier 2 |

All recipes cost zero Essence. These are explicit total statistics, not additions to an unseen quality
base. Neither garment adds Initiative, insulation/heat ward, damage, magic, capacity or an extra slot.
They are ordinary woven protection: the buckles secure overlapping layers, rather than pretending one
Ingot turns cloth into plate. Existing garments remain intact and usable. No one is auto-equipped.
Cloth and Cord have real repeated garment consumers; Iron Ingot has the specialist garment and curved
Scythe edge. Tannery's Woven Guard is useful before upgrading the forge. No forced shop-to-shop tour
is added to the already-simple Blacksmith T1 recipes.

## 2. Physical identity, colour and transactions

The three new prepared materials are exact **ungraded World-material** stocks. Preserve ingredient-source
lots through processing so cloth/ties use the selected fibre colour and the Ingot keeps its metal receipt.
One processing operation selects one exact fibre subtype and source-colour lot across its inputs; if the
player lacks that homogeneous quantity, do not silently blend colours. Mixing source lots needs a later
explicit recipe, not an arbitrary averaged colour. Several same-colour units from the same eligible lot
may supply a batch. Both Stem and Leaf Fibre are eligible; Bark and generic legacy Fibre remain excluded.

A finished garment's body and ties may deliberately use different source colours. The buckled version's
two Cloth units must share one selected lot/colour; its buckles use Iron. Show a source picker only where
that choice changes visible output. Standard Iron processing requires no chooser when its result is
identical. Chosen units, intermediate provenance, displayed result, value and destination freeze before
spending. All processing/crafting/upgrading is durable-save-first, idempotent and capacity-independent for
material stock. Finished equipment goes to Storehouse/Waiting, never directly into a character's slot.
No timed queue, fuel refund, durability, random affix or automatic Peerless result is introduced.

The JSON contains exact Gold and salvage rows. Dismantling returns the recorded **prepared** components,
not an expanded raw-material refund as well. Processing has no reverse action in this slice. Consumed
Coal never returns. Ingot sell/buy is 4/8; Cord 1/2; Cloth 2/4. Woven Guard 5/10, Buckled Woven Guard 12/24.
Purchased components cost 6 and 18 respectively, above the finished sale values of 5 and 12. Their salvage
sells for 3 and 9, below finished purchase values. Thus these authored base prices contain no buy/craft/sell
or buy/dismantle/sell profit loop. Existing merchant modifiers still need the normal economy check.

## 3. Only the additional flora row that has a consumer

`early.flora.tall_stem.v1` adds a passable tall fibrous plant on the existing stem host, requiring the same
ordinary root conditions plus Vitality peak at least 60. Scythe 2 harvests it underfoot in one successful
turn for **3 Stem Fibre**; Scythe 1 refuses for zero turns. The remnant is inert/passable with no regrowth
and no intrinsic contact damage. It may appear before Scythe 2 and honestly names the tool requirement.
This gives the new tool an actual improved harvest opportunity using an existing consumed material.

Do not change the six reserved starter plants. For remaining flora slots where tall stems are eligible,
use low/medium/tall/tree weights 30/30/10/30. Otherwise retain 35/30/35. Within a size group candidates
remain equally weighted. Regions lacking the tall host receive no tall roll and no compensating fiction.
Existing partial-work, visibility, recipe relevance, custody and saved-world rules apply unchanged.
No new land family or creature material is needed for these named crafts. The separate next creature
packet must close Hide/Skin → Leather with Salt and actual compatible animals before adding Leather
consumers; it is not a prerequisite for this working plant-cloth Tannery.

## 4. Combined cost and behavioral acceptance

From an already-built T1 forge and otherwise empty new material stock:

| Useful journey | Full new cost |
|---|---|
| Tannery + Woven Guard | 20 Essence, 6 Logs, 4 Clay, 10 Plant Fibre |
| Tannery + T2 forge + Buckled Woven Guard | 40 Essence, 10 Logs, 8 Clay, 14 Plant Fibre, 10 Iron, 1 Coal |
| T2 forge + Scythe 2 | 20 Essence, 5 Logs, 4 Clay, 2 Plant Fibre, 12 Iron, 2 Coal |

These are exact dependency-expanded quantities, not a measured number of expeditions. The first two need
Corrin; smelting/Scythe can proceed without her. The player chooses an improvement rather than receiving
a shopping list demanding every project. Verify actual journey income and retain the true next-Bind
runway; do not assume both new foundations/upgrades are affordable from starting Essence.

Engineering's focused acceptance: resolve every input set; verify acyclic unlocks from the stone kit;
compare displayed quote with the expanded totals; ensure Tannery has Woven Guard before any Ingot; preserve
T1 recipes after T2; require a packed Scythe 2 at a real tall-stem producer; retain the exact tool identity;
verify source-colour selection, one homogeneous processing lot, no double-returned raw ingredients,
normal-merchant no-arbitrage, and save-failure rollback for each transaction family. No native or pacing
checks are claimed by this design document. JSON arithmetic and declared-ID checks are authoring checks.

**Ready:** all recipes, output statistics, prices, eligibility, minimum new flora row and dependency costs
in this packet. **Implementation dependencies:** completed early source/registry/custody route, prepared
source-lot support, facility tier mapping and exact garment/Scythe native consumers. Literal assets stay
with Asset only after Engineering names those implemented consumers and state protocols. **Separate:**
Leather/creature production, later Ingots, T3 and Peerless. No Aimee approval or Homework answer blocks T2.
