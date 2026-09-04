# Early progression design direction — 4 September 2026

**T2 closure:** [the specialist packet](early-specialist-implementation-packet-v1.md) now settles Blacksmith T2 Iron Ingots, its raw-material upgrade cost and first useful consumers; it supersedes the T2 proposal language below.

## 1. Authority and status

Aimee directly authorized this design work in Game Design task `01a06e50-9d04-72a0-a0ab-80a2b3aa7aa7`
following the [takeover assessment](game-design-takeover-assessment-2026-09-04.md). This is the first bounded
design packet. It records her decisions separately from the concrete proposals below. It changes no runtime
or public Wiki, and is not a claim that the whole overhaul is ready for implementation.

**Host/consumer closure:** [early material contract V1](early-material-host-consumer-contract-v1.md)
now supplies the exact eligible material sets, finite geological/flora producers, starter blade statistics,
salve/tool outcomes and trade/recovery rules that were still open in this initial packet. Its remaining
promotion gates distinguish specified behavior from unverified source frequency, runtime and phone proof.

Direct Aimee direction superseding earlier freezes:

1. Recipes, upgrade costs, and order of progression are placeholders. Game Design may reorder and revise
   them for playability, enjoyment, coherence, and intuitive understanding.
2. Physical crafting should be intuitive where possible because other parts of Bookbinder already provide
   deliberate arcane complexity. She agrees with an early Halloway tool-upgrade path and welcomes related
   corrections.
3. Starter Blacksmith gear can use raw materials. Later specialty shops may require crafted components.
4. She likes refinement and proposes one Mote plus a maximum-level shop plus its attending shopkeeper for
   100% Peerless success; having only one or two of those advantages should still permit a chance. This is
   the direction to develop, with incomplete-setup odds and spending details not yet settled.
5. Exploration should not routinely allow whole-map completion. Trees and canopy may make routes interesting;
   a successful trip can leave substantial territory unexplored.
6. Different materials can be desirable for statistics or colour. Appearance is a legitimate reason to gather
   a material; it need not always win a combat comparison.
7. Traveller/building order may be rearranged so late systems have enough useful campaign life.
8. She agrees with the Writing/clue teaching concerns and the crafting-persistence and Wiki corrections.
9. She authorizes the early design priority and asks that the concerns and takeover document be relayed to
   the current Project Manager.

During this work Aimee additionally proposed opening Ingot production at Blacksmith T2 or T3 alongside
the player's expanding buildings. Game Design recommends **T2** for that first processed-metal milestone;
the staged proposal is recorded below. This is a proposed tier placement, not a shipped unlock.

Aimee subsequently suggested stone starting tools. Game Design adopts stone Pick/Axe/Scythe working parts
for the existing opening kit and iron heads for the first Halloway upgrades. This is recorded in the host/
consumer contract, with no pre-expedition crafting chore or change to tool classes and their dedicated roll.

These decisions do not revoke physical-material identity, ungraded geological/flora stock, explicit source
choice when meaningful, saved-world preservation, or the AGENTS.md fixed-phone and Asset restrictions.
Authorization to proceed with this Game Design work is not a blanket resumption of every other lead's queue.

**Later closure:** [early progression implementation packet](early-progression-implementation-packet-v1.md)
settles the first-six priority, signatures, blind gates, clue migration and ordinary source tables.
Its exact rows supersede the proposed opening and outstanding host-frequency authoring below.

## 2. First journey: gain a useful capability before adding another prerequisite

Proposed opening tendency, replacing the inherited mandatory sell → recycle → forge emphasis:

| Cohort | Proposed authored tie-break order | First useful contribution |
|---|---|---|
| Opening contact | 1 Vance | Exchange surplus and understand value |
| First practical makers | 2 Nessa, 3 Halloway | Make a healing supply; make simple equipment and improve a field tool |
| Broaden early choices | 4 Bryn, 5 Corrin, 6 Noll | Protective party play; flexible gear/packing; recover materials and sort Rubble |

These are proposed content priorities, not six compulsory single-file arrivals. Legitimate clue-backed
discoveries may still reach ahead. Both Nessa and Halloway should be discoverable without first recruiting
all three members of the old opening-economy group. Noll's service is useful but need not delay healing.

Do not migrate this order by changing one JSON sort key. New signatures, story bands, earliest teachable
vocabulary, clue links, and the selector's blind-discovery floor must be reconciled together. The current
three-recruit floor would otherwise undermine the intended first-maker cohort. Design the needed early
land facts first; author signatures after those facts are closed.

Firepit, Writing Desk, Storehouse, Party, and the other opening capabilities retain their established
ownership. Workshop does not return. The Storehouse retains the first two pack projects; neither raw
materials nor the three-place tool roll consume item slots.

## 3. Concrete first-pass foundations and making

The numbers below are Game Design's working tuning proposals. They are deliberately reviewable and
revisable; they are not measured affordability results or secretly final product requirements.

| Project | Access | Proposed inputs | Immediate result |
|---|---|---|---|
| Apothecary foundation | Recruit Nessa | 20 Essence, 4 Clay, 4 of any Log | Know Lesser Salve and use the starting preparation service |
| Blacksmith foundation | Recruit Halloway | 20 Essence, 8 Iron, 4 Plant Fibre, 4 of any Log | Use the starter metal Pointed Blade recipe and first tool upgrades |
| Lesser Salve | Starting Apothecary | 1 Resin, 1 Plant Fibre; 0 Essence | 1 Lesser Salve; preserve its current base healing of 10 and existing scaling |
| Starter metal Pointed Blade | Starting Blacksmith | 4 Iron, 1 of any Log, 2 Plant Fibre, 1 Coal; 0 Essence | 1 close-reach piercing weapon; exact stat row must be closed before promotion |
| Pick level 1 → 2 | Starting Blacksmith | Owned Pick 1, 4 Iron, 1 of any Log, 2 Plant Fibre, 1 Coal; 0 Essence | Upgrade the same tool to Pick 2 in its tool-roll place |
| Axe level 1 → 2 | Starting Blacksmith | Owned Axe 1, 4 Iron, 1 of any Log, 2 Plant Fibre, 1 Coal; 0 Essence | Upgrade the same tool to Axe 2; independent optional purchase |

The salve uses the existing Resin role with a fibre applicator instead of a hidden flexibility threshold.
It introduces no new medicinal subtype or generic Reagent. Its standardized appearance and healing result
do not vary by raw fibre colour or source; those inputs require no source picker for this operation.
The exact eligible Plant Fibre set must be enumerated in the registry before this recipe ships.

The starter blade line is a bounded metal variant, not permission to delete existing crafted weapons or
all later anatomical-material recipes. Iron supplies the point, Log the handle, Plant Fibre the binding,
and Coal the forge heat. Blade/handle/binding retain the chosen material's appearance; fuel does not tint
the weapon. No material measurement can make an unrelated ingredient eligible.

Halloway performs heating and shaping within the single craft. The player need not separately create
an Ingot, Haft, or Cord. This preserves physically sensible work without requiring intermediate inventory.
Later specialists can require a useful prepared component: for example, Leather plus raw binding material
for a better garment. Ordinary projects should continue to avoid a chain of mandatory visits to several
shops; extra processing belongs where the result earns it.

### Blacksmith tiers and settlement growth

Use player-facing tiers to describe the progression; Engineering must explicitly map them to the registry's
stored tier indices rather than assuming the older starting `tier: 0` means a different player stage.

| Player-facing stage | Blacksmith role | Relationship to other buildings |
|---|---|---|
| T1: working forge | Starter gear and first field-tool improvements directly from raw stock | Useful as soon as Halloway's foundation is built; no separately stored Ingot is required |
| T2: smelting | Make exact named Ingots for recipes that need prepared metal | Arrives by the first specialist gear buildings that consume those Ingots; a new specialist recipe can point back to Halloway's upgrade |
| T3: advanced forge | Proposed advanced forgework and high-end refinement role | Supports the later equipment journey; exact recipes and mastery benefits remain to be designed |

Keep ordinary T1 recipes usable after upgrading. Early raw-stock crafting is not a permanent exemption
from physical forging; Halloway simply performs the work inside the finished-item transaction. T2 adds
exportable prepared stock for other recipes, rather than charging players for an extra step on the same
starter blade they already know how to make.

Use the existing first-pass smelting ratio as the working T2 recipe: **2 matching raw solid metal + 1 Coal
→ 1 matching named Ingot**, with no Essence charge. Start only with named metals whose specialist consumers
are closed. Mercury is not a solid smeltable-metal input; glass, stone, and creature parts never qualify.

The T2 upgrade itself must be affordable with T1-accessible raw materials. Neither its foundation nor its
first indispensable consumer may require a process available only after that same dependency. Make the
upgrade available alongside the appropriate specialist cohort; do not invent a generic recruitment-count
gate. Exact T2 cost and specialist placement are the next progression-table work.

An Ingot prerequisite should first express a better or more demanding craft, not leave a newly built shop
with no useful action. Check the combined expense of the specialist foundation, forge upgrade, and first
item as one player journey. The Ingot family must have two sensible consumers or one broadly reused
consumer family before promotion.

Quartz leaves the basic Apothecary foundation. It remains a sensible later optical/instrument ingredient.
This removes the healing/tool dependency altogether while retaining the useful early Pick upgrade.
Pick 2 opens the currently intended uncommon mineral group, including Quartz; a future harvesting-table
revision may split that access if play evidence warrants it. Do not quietly restore the obsolete four-rank,
party-equipped Extraction model: use the current three-tier packed-tool model.

Upgrading a tool preserves its exact identity, increases only its defined capability, and occupies the
same class slot. No duplicate old tool, durability system, or mandatory upgrade of all three tools is added.
Missing inputs, stale selection, cancelled quotes, or failed saves change neither tool nor materials.

## 4. Producers and acquisition checks

| Needed stock | Intended early producer | Opening access | Useful destinations in this packet |
|---|---|---|---|
| Iron | Common Iron-bearing formation | Rock Pick 1; 2 units per hit | Forge foundation, blade, Pick/Axe upgrades |
| Coal | Common fuel-bearing formation | Rock Pick 1; 2 units per hit | Blade and tool-making family |
| Logs | Small softwood trunks | Axe 1; 2 Logs per completed trunk | Both foundations, blade and tools |
| Plant Fibre | Compatible ordinary low/medium fibre-bearing flora | Scythe 1; saved size yield | Forge, salve, blade/tools, existing pack projects |
| Resin | Explicit resin-producing ordinary flora | Opening-accessible harvest must be authored | Salve and existing packing/recipe consumers |
| Clay | Explicit loose-earth placement on a compatible surface/margin | Hand gathering; 2 units per placement | Apothecary and other later vessel/construction families |

The node/plant yields above inherit the published first-pass harvesting model. Exact host frequency,
Resin's placed harvest interaction, and the early flora eligibility set remain content work. Do not claim
that a material is obtainable simply because its name exists in a registry. None of these inputs may
depend exclusively on Noll, a lucky shop roll, a rare nearby-find bonus, a creature drop, or a later Sigil.

Harvest-only arithmetic, before travel, encounters, and actual placement:

- Apothecary stock is two Clay gathers and two small trees: four successful actions, plus 20 Essence.
- Blacksmith stock is four Iron pulls, two small trees, and two to four ordinary fibre cuts: eight to ten
  successful actions, plus 20 Essence.
- Either tool improvement needs two Iron pulls, one small tree, one to two fibre cuts, and one Coal pull:
  five to six successful actions, with spare stock from some yields. These are costs to source from empty
  holdings, not minimum new actions when the player already has surplus.

The full Halloway foundation + blade + Pick improvement needs 16 Iron, 6 Logs, 8 Plant Fibre, and 2 Coal.
It is intentionally more work than one project and need not be completed in one trip. The player chooses
which improvement to pursue; the game should not present the whole shopping list as the next objective.

Before promotion, establish each foundation's ordinary acquisition route without direct resource Writing,
then verify the first useful craft and enough retained Essence for another legal ordinary Bind. A warning
may explain the remaining expedition budget; a player may still knowingly spend it. Do not invent a hidden
protected currency reserve or force a purchase order.

## 5. Exploration success is a worthwhile return, not complete coverage

Working design standard: an ordinary expedition lets the player accomplish one meaningful intention and
encounter something unexpected while leaving credible reasons to wonder about the rest of the world.

- Spread optional opportunities into branching routes. A tree or stand of canopy should create a choice
  between a detour, spending turns felling, and pursuing another lead.
- Mandatory teaching and written guarantees remain start-connected. Canopy must not make them impossible,
  erase earned minimap knowledge, or add an undisclosed dangerous contact.
- Reserve the full written source cluster, but do not position every valuable activity on the same short
  corridor. The guaranteed material is a dependable target, not a promise of total world completion.
- Tune Stability against a representative goal route, harvesting and return margin. Do not automatically
  increase it enough to clear all passable ground in a larger world.
- Do not add completion percentages, a universal clear-map bonus, or empty travel as the pacing solution.
  Small or unusually favourable worlds may still be thoroughly explored; there is no artificial reveal cap.
- Assess route branches, unexplored territory on a successful return, interesting discoveries per trip,
  and whether continuing farther creates a meaningful tradeoff. No universal percentage is fixed yet.

Colour-led gathering is a valid expedition goal alongside stronger statistics. Recipe eligibility remains
physical; optional source selection explains the actual colour/stat result. A material does not need a
fabricated combat advantage merely to justify a desirable finish.

## 6. Refinement and Motes: working design to develop

Use Aimee's three advantages as the proposed Peerless route:

| Available advantages, after the ordinary recipe/service requirements | Intended opportunity |
|---|---|
| One of maximum shop, attending matching keeper, offered Mote | A small disclosed Peerless chance |
| Any two | A larger disclosed chance |
| All three | 100% Peerless for the eligible craft/refinement, consuming one Mote |

This explicitly considers Mote-only, shop-only, keeper-only, and all two-way combinations. It does not
quietly preserve maximum shop as an additional eligibility gate for every chance attempt. Ordinary recipe
access and sensible input requirements still apply. Exact partial odds, zero-advantage behavior, Mote
consumption on a missed partial attempt, and refinement costs require the next bounded reward pass.

Preferred direction: refine an existing piece, preserving identity and selected appearance, with a plainly
shown current result and possible improvement. A miss never destroys or downgrades the item. This avoids
requiring disposable copies. It does not yet authorize repeatedly spending a Mote for no improvement.

Before implementation, close these interactions together:

1. Whether partial-setup Mote spending is allowed on a miss and what lasting benefit that spend guarantees.
2. Chance disclosure versus the older requirement to preview the exact rolled output. If the player sees
   the completed random result before paying, ordinary cancel/requote must not become free outcome shopping.
3. Which event advances an attempt, how cancelled/edited quotes retain randomness, and how persistence
   failure leaves inputs, item, Mote, and attempt state unchanged.
4. How all-ungraded metal/wood equipment participates. Do not smuggle creature quality in as a fourth
   requirement for Aimee's three-advantage guarantee.
5. What replaces or retains the old twenty-copy pity rule. Do not implement it alongside refinement by
   accident or convert historical progress without an explicit mapping.
6. Mote demand across Constellation, world-keeping/Waystone, and optional masterwork gear. The new route
   must not require spending the same scarce Mote on both basic progression and a compulsory gear gate.

These are Game Design follow-ups. The early raw-material crafting packet can proceed independently.

## 7. Promotion boundary and remaining work

Ready as direction: reopened order/costs, raw starter crafting, proposed first-maker cohorts, removal of
Quartz from basic healing, bounded early tool routes, exploration without routine full clearance, and a
three-advantage guaranteed-Peerless proposal alongside refinement.

Before an affected playable slice: enumerate exact resource/recipe IDs and eligible categories; complete
the required early host and flora entries; close the starter blade stat row and comparative balance;
reconcile early traveller selection/signatures; validate route affordability and durable transactions; and
publish current/intended distinctions. Existing people, buildings, tools, knowledge, and crafted items
remain intact in saves. Changed quotes become stale rather than consuming substitute stock.

No full 29-person reorder, creature catalogue, new art assignment, phone acceptance, or Peerless mechanic
is claimed complete by this packet. Game Design's next work is the early host/consumer closure followed by
the signatures that use those exact terms. The current Project Manager receives this packet and the
assessment for coordination; Engineering's unrelated work is not interrupted.
