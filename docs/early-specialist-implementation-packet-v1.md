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
One processing operation selects one exact fibre subtype and source-colour group across its inputs; if the
player lacks that output-equivalent quantity, do not silently blend colours. Mixing source lots needs a later
explicit recipe, not an arbitrary averaged colour. Several same-colour units from the same eligible group
may supply a batch. Both Stem and Leaf Fibre are eligible; Bark and generic legacy Fibre remain excluded.

A finished garment's body and ties may deliberately use different source colours. The buckled version's
two Cloth units must share one selected group/colour; its buckles use Iron. Show a source picker only where
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
verify source-colour selection, one output-equivalent processing group, no double-returned raw ingredients,
normal-merchant no-arbitrage, and save-failure rollback for each transaction family. No native or pacing
checks are claimed by this design document. JSON arithmetic and declared-ID checks are authoring checks.

**Ready:** all recipes, output statistics, prices, eligibility, minimum new flora row and dependency costs
in this packet. **Implementation dependencies:** completed early source/registry/custody route, prepared
source-lot support, facility tier mapping and exact garment/Scythe native consumers. Literal assets stay
with Asset only after Engineering names those implemented consumers and state protocols. **Separate:**
Leather/creature production, later Ingots, T3 and Peerless. No Aimee approval or Homework answer blocks T2.

## Source grouping clarification

A source group is not one harvested instance or one historical receipt. Combine owned units whose exact
material subtype, quality (when present), colour and recipe-relevant source measurements are identical,
while retaining every parent receipt and selected quantity. Two matching patches may supply one Cloth;
two matching animals may supply four Hide. No numerical averaging, guessed provenance, or loss of parent
identity is permitted. In the picker, identical-result groups need no duplicate choices. Different
measurements or colours still require an explicit choice; grouping never makes an ineligible type qualify.

## Bounded forge and Scythe runtime milestone — 5 September 2026

Engineering preserved the forge milestone at `f1acb661` and the connected field milestone at `cf613f5c03a371c069bc67e5d8ac631b591e295c`, tree `88e292794b048925bb4e3fdf1687c06a2f3c1fc2`, in its named early-material-regions-v1 worktree. Exact receipt: `docs/early-blacksmith-native-acceptance-2026-09-05.md`. It implements the closed basic Pick/Axe improvements, T2 upgrade, Iron smelting, same-instance Scythe2 and finite Tall Stem Patch with unchanged starter reservations. Consumed Iron/Coal parents remain retained after prepared ingots are spent; legacy valid Iron parents are supported without fabricated harvest provenance. Original tools retain identity and order, and higher legacy shop tiers remain.

Focused transaction/material tests, stale/replay/write-failure/reopen cases, harvest/host/threshold tests and final legacy/written-Iron compatibility checks pass. Native isolated forge operation and reopen pass; the isolated Tall Stem Patch harvest commits one turn/three Stem Fibre. Its following UI test encountered a tutorial after the successful action; durable inspection and a separate read-only reopen verify the harvest without replaying it. Evidence is iPhone17Pro Simulator402×874pt/default text/current appearance, not a physical-phone receipt or natural affordability journey.

Design accepts this bounded functional milestone. Tannery Cord/Cloth/garment consumers and literal source-colour presentation are not included. No final art, natural Nessa/search progression or phone delivery is established, and no fourth paid search is authorized. Natural Home remains29 Essence/issued3. Full test IDs and native artifacts stay in the named Engineering receipt rather than duplicating them here.

## Early fibre colour mapping dependency — 5 September 2026

The intended inheritance and source-grouping rules above are closed; their exact mapping onto early
Stem/Leaf producers is not. At Engineering `cf613f5c`, `EarlyMaterialSourceReceipt` retains the world seed,
region, producer, anchor and immutable `WorldVisualReceipt`, but no dedicated resolved fibre colour or
linked flora-species identity. A saved world flora tendency is not itself proof of an individual plant's
colour; an unrelated cast entry cannot supply that missing identity. The older Bloom-to-flora tendency
contract does not close this gap. No new palette rule is adopted by this finding.

Continue bounded Tannery costs, custody, output statistics and durable transactions while preserving all
parents. Do not combine unknown-colour sources as proven identical-colour groups or present placeholder
colours as accepted source-colour output. Exact source-colour selection and visual acceptance remain a
Design/Engineering dependency, not an Aimee decision or a reason to block unrelated transaction work.
Existing saved lots must remain intact; a later versioned resolution must not silently invent historical
species provenance or reroll owned materials.

## Early fibre colour closure — 5 September 2026

This section supersedes the unresolved mapping disposition immediately above. It closes only the named
Stem Patch, Leaf Rosette and Tall Stem Patch consumers, using Aimee's accepted stable foliage channel and
assigned-shade precedence. This is **new decided intended behavior**, not a claim that the old world
receipt already resolved these producers or that source-colour presentation has passed.

### Authoritative source value

Add optional `plantColour` to `EarlyMaterialSourceReceipt`. Its version-1 payload stores `channel = foliage`,
exact integer sRGB `[r,g,b]` in `0...255`, resolution version `early-source-colour-1.0.0`, basis, and the
source's existing world visual receipt hash. Basis records either an actual assigned source shade, an
inherited saved flora tendency, or the new world's generated foliage base. Preserve the existing source
ID, producer ID, region, anchor and seed; no species ID is invented. A real assigned source shade must
have an actual rules-owned saved assignment receipt; none is inferred from a display name or screenshot.

All three named producer families inherit the same world foliage base unless an actual specific shade
is assigned. Their different anatomy, subtype and harvest rules remain unchanged. For this bounded new
bridge, the base is the exact validated RGB from `visualReceipt.request.resolvedColors.floraTendency`
when present. This explicitly promotes that saved colour to the early-producer base; it does **not**
claim that it was already a species colour, and does not change old flora-cast rendering. Assigned source
shade wins over that base. Never choose the first, nearest, or similarly named flora-cast species.

If that field is absent, resolve the world's early foliage base once with a separate versioned seed
stream: `SeededRNG(seed: worldSeed).derived(0x4541524C464F4C31)` (EARLFOL1). Consume exactly four draws:
hue = draw1 modulo 360; band = draw2 modulo 100; saturation = lower bound + draw3 modulo inclusive range
count, using ranges 0...12 for band<20, 25...55 for band<70, otherwise 60...85; lightness = 35 + draw4
modulo 31. Convert using the existing `WorldGrade2V1.resolvedSRGB` hue/saturation/lightness conversion.
This reuses the existing open-colour distribution without a fabricated Sigil/species ID. It does not
consume placement, encounter, teaching or harvest RNG. Copy the exact resulting base into each eligible
source receipt; do not reroll at a coordinate, per unit, harvest, Return, processing, redraw or relaunch.
A missing field uses this rule only for newly generated version-1 sources; malformed present colour
refuses source creation instead of falling through to a different colour.

### Binding, legacy sources and component lineage

Engineering must version new source generation (for example optional `earlyPlantColourVersion = 1` on
newly bound books) so old books/worlds retain their prior behavior. Persist the colour with each source
at generation, before any harvest; harvest freezes that exact source receipt in custody. Existing sources
with no colour decode as **unresolved**, not a neutral colour. Never backfill old lots by sampling their
saved seed, adding a species link, or reading the currently rendered world. Keep old stock and old crafted
items usable under their existing rules, including colour-independent foundation and raw-material costs.
For a new colour-bearing Cord/Cloth quote, exclude unresolved sources and explain “Choose fibres with a
known colour.” No eligible complete group means refusal before spending, not conversion into generic
beige output or an automatic material grant. Legacy finished equipment is not invalidated.

Known inputs group only by exact material subtype, ungraded quality, channel, exact sRGB and every other
recipe-relevant measurement; source/world IDs and ancestry are retained but do not split identical-result
choices. Different worlds with the same exact eligible result may combine. Unknown is never equal to a
known colour or to another unknown as proof of output equivalence. Stem and Leaf remain distinct groups;
Stem Patch and Tall Stem Patch may share a Stem group when their relevant values match.

Cord and Cloth persist their selected colour plus every parent source/quantity through the prepared
receipt. Processing does not bleach, average, shade-shift or grade fibre. Garment body uses the selected
Cloth RGB, ties the selected Cord RGB; those two component colours may differ. Buckled Guard's two Cloth
units must be output-equivalent. Iron buckles keep their metal appearance/receipt. Salvage returns the
recorded prepared components with the same colours and parents, never a new raw-fibre refund. Display,
source selection, spending and saved result must agree on the frozen component values.

The same saved source base must be exposed to the implemented plant and material/garment presentation
consumers; renderer lighting and preserved shading do not rewrite inherent RGB. This closes rules and
lineage, not final pixels or an Asset assignment. Engineering must name the exact consumer/state protocol
before Asset receives work. Scoped acceptance: assigned-shade precedence, saved tendency and absent-base
branches, identical/different/unknown grouping, multi-parent processing, selected garment panels,
stale/failure/reopen and legacy preservation. No extra natural search, grading, eligibility expansion,
world-palette rewrite, new species or phone-delivery claim is authorized by this section.
