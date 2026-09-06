# Early material host and consumer contract V1

> **5 September resource-occupancy clarification:** Aimee requires one tile, one node/resource across every resource pass, including guarantees and reservations. This contract never grants a per-pass stacking allowance. Preserve required quantities, legal hosts, protected content and reachability using distinct resource coordinates. See `field-tool-gesture-and-resource-occupancy-2026-09-05.md`. Implementation correction remains pending.

**T2 closure:** [the specialist packet](early-specialist-implementation-packet-v1.md) now settles Blacksmith T2 Iron Ingots, its raw-material upgrade cost and first useful consumers; it supersedes the T2 proposal language below.

**Status:** completed bounded Game Design specification; first-pass tuning, not shipped or play-verified.
Closes physical eligibility, finite harvests, starter outputs and transaction behavior. The [early progression packet](early-progression-implementation-packet-v1.md) now closes category mapping,
ordinary source reservations and recruitment. Full route pacing and native implementation remain verification/promotion gates.

Authority: [Aimee's direction and first packet](game-design-early-progression-direction-2026-09-04.md),
the four resource/world authorities at `b4081f63`, and runtime inspection at `216d2498`. Aimee additionally
suggested stone starting tools while this contract was being written. Game Design adopts that suggestion.
Identifiers below are **reserved design contract IDs**, not claims of existing runtime definitions.

## 1. Stone, iron, then prepared metal

The opening three-place tool roll supplies a Stone Pick, Stone Axe and Stone Scythe, each tool tier 1.
Their working parts are stone, with wooden handles and plant-fibre bindings. This is the existing opening
tool grant with a concrete physical identity, not a new crafting chore before the first expedition.
The Pick remains the Rock Pick class from the accepted harvesting plan. The Scythe retains its class and
interaction protocol; exact silhouettes belong to the later named native art consumer.

Blacksmith T1 upgrades those working parts to iron and reworks handle/binding, producing tool tier 2.
Blacksmith shop tier and tool tier are separate ladders. T2 Ingot production remains the next proposed
settlement milestone, accompanying specialist crafts; it is unnecessary for these early upgrades.
No durability, breakage, mandatory replacement cycle, or compulsory upgrade of all tools is introduced.
Stone-tool salvage/rebuilding is outside this packet; do not invent harvested source-world history for
an authored starting grant. Existing saved tools are not downgraded or silently renamed into these grants.

## 2. Exact materials and eligibility

All rows use the World-material reserve, including flora-origin stock; all are ungraded. Recipe eligibility
is an explicit physical set, never a numerical property threshold. Source/colour remains beneath the stack.

| Contract ID | Name | Category in this slice | Sell / buy per unit |
|---|---|---|---|
| `world.iron` | Iron | Common metal | 2 / 4 Gold |
| `world.coal` | Coal | Fuel | 2 / 4 Gold |
| `world.clay` | Clay | Loose earth | 1 / 2 Gold |
| `world.resin` | Resin | Plant part | 2 / 4 Gold |
| `flora.log.softwood` | Softwood Log | Log | 1 / 2 Gold |
| `flora.log.hardwood` | Hardwood Log | Log | 1 / 2 Gold |
| `flora.fibre.stem` | Stem Fibre | Plant Fibre | 1 / 2 Gold |
| `flora.fibre.leaf` | Leaf Fibre | Plant Fibre | 1 / 2 Gold |

`early.log.v1` = exactly {Softwood Log, Hardwood Log}. `early.plant_fibre.v1` = exactly {Stem Fibre,
Leaf Fibre}. These are the complete expansions of "any Log" and "Plant Fibre" for these recipes.
Bark Fibre, dense/resinous wood, Hafts, Planks, Cord, Cloth, Hide and generic legacy Timber/Fibre are not
implicitly admitted. Later closed material families can enter an explicitly revised eligibility set.

Current `ore` is documented as Iron in `resources.json`: proven ordinary scalar Iron Ore maps 1:1 to
`world.iron`; exact Clay and Resin likewise map 1:1. Preserve legacy lot value overrides. Generic `timber`
and `fiber` remain Legacy unless a receipt proves the precise new type. Never issue two balances for one
holding. Canonical physical names do not authorize guessed provenance.

## 3. Finite geological producers

Host tests read the saved resolved region: formation, bedrock, surface, hydrology and occupancy are separate
facts. Stone composition alone never guarantees a metal or fuel. Deposits have their own tool requirement;
an Iron node in Basalt still uses Pick 1 even though harvesting Basalt itself requires Pick 2.

| Producer ID | Exact host rule | Interaction | Yield/depletion |
|---|---|---|---|
| `early.node.iron.v1` | Formation includes `iron_bearing`; bedrock Granite, Sandstone or Basalt; exposed dry face adjacent to passable land | Direction toward node with Pick 1 | Three hits, 2 Iron each; total 6 |
| `early.node.coal.v1` | Formation includes `coal_bearing`; bedrock Sandstone; exposed dry seam adjacent to passable land | Direction toward node with Pick 1 | Three hits, 2 Coal each; total 6 |
| `early.gather.clay.v1` | Clay-soil surface, or mud over an explicitly clay-bearing deposit; passable, unfrozen, unsubmerged placement | Interact underfoot, by hand | One action, 2 Clay, then depleted |

Mineral nodes inherit the accepted passable-area budget and 70/25/5 rarity weighting. Within an eligible
rarity tier these candidates have equal selection weight; only actual regional candidates participate.
Clay uses explicit loose-surface placements, not the mineral-node budget. A written common-resource
guarantee reserves two common nodes; a written hand-gathered resource reserves one placement. Ordinary
host compatibility alone is not a written guarantee. Old/anchored worlds keep their generation version.

## 4. Finite ordinary flora producers

This is the small body/harvest catalogue needed for this route, not fixed named species or the full flora
system. Name, colour and ornament may vary within each profile without changing its physical harvest.

The following ordinary cohort requires resolved cool/temperate/warm conditions, enough resolved light for
photosynthesis, fresh-damp or fresh-moist roots, and no acid precipitation, corrosive air, permanently
submerged root zone or frozen root zone. These are exact environmental categories for the new compatibility
registry; mapping them to the pressure resolver is an implementation prerequisite, not permission to make
each producer invent its own temperature or light thresholds.

| Profile ID | Compatible root surface | Body / interaction | Tool, work and output |
|---|---|---|---|
| `early.flora.stem_patch.v1` | Loam or clay soil | Medium fibrous stems, passable; Interact underfoot | Scythe 1; one hit; 2 Stem Fibre |
| `early.flora.leaf_rosette.v1` | Loam or clay soil | Low fibrous rosette, passable; Interact underfoot | Scythe 1; one hit; 1 Leaf Fibre |
| `early.flora.resin_shrub.v1` | Loam over Granite or Sandstone | Low shrub with visible resin-bearing shoots, passable; Interact underfoot | Scythe 1; one hit; 1 Resin |
| `early.flora.small_softwood.v1` | Loam over Granite or Sandstone | Small blocking trunk; five-tile cross crown; adjacent direction | Axe 1; one hit; 2 Softwood Logs |
| `early.flora.small_hardwood.v1` | Loam or clay soil | Small blocking hardwood trunk; five-tile cross crown; adjacent direction | Axe 2; two hits; 5 Hardwood Logs on final hit |

All additionally require the ordinary cohort conditions. Profiles are equally weighted within their
eligible size group; world flora abundance controls counts. The wider generator must not scatter this
whole starter catalogue into every world regardless of habitat. Exact ordinary acquisition frequency is
unverified and must be measured before promotion.

These profiles have no intrinsic contact hazard; separately disclosed world hazards can still affect a
route. Resin is a primary, finite harvest, not a random secondary drop requiring the older `isDefended`
trait. The shrub yields Resin only, never an additional Log/Fibre roll, generic Reagent, Pulp or Toxin.

Harvest spends one world turn per successful hit. Save the depleted instance; no regrowth in this slice.
A hardwood's first hit saves progress and yields nothing; the second gives all five Logs and removes only
that trunk's crown. Its remnant is inert and passable. Overlapping surviving crowns remain. Earned minimap
knowledge persists. Encounters and authored tile interactions retain priority over harvesting. Wrong tools,
stale targets, cancellation and failed saves change nothing and cost no turns.

## 5. Closed starter recipes and outputs

Base service access requires its keeper recruited and its facility built, without another study entitlement
or active keeper posting. Staffing, Peerless rolls and specialist recipes do not gate these first uses.

| Recipe ID | Exact inputs | Exact result |
|---|---|---|
| `early.build.apothecary.v1` | Nessa recruited; 20 Essence, 4 Clay, 4 `early.log.v1` | Built base Apothecary; learn `salve_lesser`; no free item |
| `early.build.blacksmith.v1` | Halloway recruited; 20 Essence, 8 Iron, 4 `early.plant_fibre.v1`, 4 `early.log.v1` | Built base Blacksmith; the three forge recipes below available |
| `early.craft.lesser_salve.v1` | 1 Resin, 1 `early.plant_fibre.v1`; 0 Essence | One existing `salve_lesser`; base healing 10 with current beneficial scaling and target rules |
| `early.craft.iron_pointed_blade.v1` | 4 Iron, 1 `early.log.v1`, 2 `early.plant_fibre.v1`, 1 Coal; 0 Essence | One Pointed Blade; weapon; Pierce; Close; total equipment Power 2.0; Fine workmanship |
| `early.upgrade.pick_2.v1` | Exact owned Pick 1, 4 Iron, 1 `early.log.v1`, 2 `early.plant_fibre.v1`, 1 Coal; 0 Essence | Same tool ID becomes iron-headed Pick 2; no extra Pick 1 |
| `early.upgrade.axe_2.v1` | Exact owned Axe 1, 4 Iron, 1 `early.log.v1`, 2 `early.plant_fibre.v1`, 1 Coal; 0 Essence | Same tool ID becomes iron-headed Axe 2; no extra Axe 1 |

The blade's Power 2.0 is the **finished total**, including its fixed authored Iron contribution. Do not add
Fine rank or the older construction tier again. No extra Initiative, Armour, ward, status, reactivity or
value modifier. Logs/Fibres change handle/binding colour, not statistics in this starter variant. Later
recipes may attach stat differences to physical variants. Compared with the current Power-1 rending
Chipped Blade, this supplies a stronger equipment Power value and a different damage kind, not a promise
of double damage against every foe. Comparative combat verification remains required.

Quality-defining sockets: point 70%, handle 30%; both ungraded rank-1 inputs give Fine. Fibre is a minor
fitting and Coal expendable fuel; neither votes. No random outcome on this initial ordinary recipe.
Peerless adoption must later explicitly reconcile this route, including all-ungraded gear eligibility.

Pick 2 follows the intended uncommon-node access list, including Quartz. Axe 2 opens mature-softwood and
small-hardwood harvesting. Neither upgrade increases lower-tier yield or speed. The exact tool stays in
its existing owned location and occupies one class slot when packed. Tool ownership at home does not
grant field access. Scythe upgrades and tool tier 3 remain outside this slice.

Heating/shaping occurs within the finished forge transaction: no Ingot, Haft, Cord or hidden sample
threshold. Resin supplies the salve and fibre its applicator; standard appearance and healing do not vary
by source. Quartz is not part of basic healing. Higher shop tiers never remove the starter recipes.

## 6. Appearance, custody, trade and recovery

Iron supplies the blade's authored point appearance; Log/Fibre source colours tint handle/binding with
shading preserved. Coal tints nothing. Salve stays standardized. Asset work waits for exact native
consumer/protocol/geometry; no speculative production assignment is made here.

Choose physical type for category sockets, then source only when output changes. One adequate source lot
supplies a multi-unit socket; combine disclosed lots only when needed. Foundation/salve operations do not
open outcome-neutral source pickers. Freeze exact units, output, price and destination before committing.
Refuse stale choices without substitution. Use persist-before-publication so failed saves do not report
success. Preserve item identity, selected colours, exact receipts and quantities through cold relaunch.

Materials remain slot-free through Field → frozen Return → Storehouse, using the accepted protected
outbound-unit and deterministic partial-loss rules. Craft items enter Storehouse or legitimate Waiting;
do not silently equip/use/discard them. New and legacy yield owners cannot both grant a reward.

Blade sell value: 10 Gold. Buy price if actually stocked: 20 Gold; no stock guarantee. All listed input
combinations cost 26 Gold to buy. Recycler returns exactly 4 Iron, its 1 Log and its 2 Fibre; no Coal,
because heat was spent. Recovered stock sells for 11 Gold, below the blade's purchase price. Preserve
source identity/colour; do not return generic Timber/Fibre or reroll salvage. These receipts apply only
to the new recipe. Tool-roll tools are not dismantlable under this packet.

## 7. First-use quantity proofs

**Nessa from empty material holdings:** two Clay gathers, two small-softwood trees, one Resin shrub and
one stem patch yield 4 Clay, 4 Logs, 1 Resin, 2 Stem Fibre. Six successful harvest actions supply the
foundation and one salve, leaving 1 Fibre. Spend 20 Essence total; after packing, a valid salve use applies
the existing heal-10/scaling behavior and consumes one item.

**Halloway foundation plus Pick improvement:** two Iron nodes, three small-softwood trees, three stem
patches and one Coal pull yield 12 Iron, 6 Logs, 6 Stem Fibre and 2 Coal. Thirteen harvest actions supply
both projects, leaving 1 Log and 1 Coal; spend 20 Essence total. A subsequent valid Quartz pull with the
packed Pick 2 yields its declared 2 Quartz and spends one world turn.

**One blade at the built forge:** two Iron pulls, one small tree, one stem patch and one Coal pull yield
4 Iron, 2 Logs, 2 Fibre and 2 Coal. Five harvest actions supply the blade, leaving 1 Log and 1 Coal.
The forge previews Power 2.0 / Pierce / Close / Fine and exact appearance. Later dismantling recovers
the seven structural units once, with no Coal.

These are conservation/work examples, not claims of six/thirteen/five-turn expeditions. They exclude
travel, discovery, encounters, return distance and Essence income. A route must succeed without requiring
map clearance. Small favourable worlds may still be explored thoroughly; there is no hard reveal cap.

## 8. Remaining promotion gates

1. Adopt/map the exact IDs and environmental facts; implement compatible finite placements and versioned
   old-world preservation. Non-behavioral registry work need not await a full new generator.
2. Verify ordinary acquisition frequency and complete goal routes without later resource Sigils, debug
   grants, lucky trade or compulsory map clearance. Include the first useful craft and enough Essence
   for another ordinary Bind. Do not silently reserve currency or force a purchase order.
3. Close early traveller signatures, teachable vocabulary and selector changes. This contract supplies
   physical cues; it does not imply the player already knows a writable `iron_bearing` or `loam` Sigil.
4. Verify stale/cancelled/failed-save and cold-relaunch paths, including a half-felled tree, exact units,
   partial Return, and a single upgraded tool. Resolve the known crafting persistence gap before reuse.
5. Connect native first use and check the actual target iPhone/default text, recording device/viewport;
   preserve all AGENTS.md exclusions. No visual acceptance is claimed here.
6. Verify comparative combat balance, trade/salvage quotes and overall effort; adjust first-pass values
   from full journeys. Arithmetic closure alone is not a playability result.
7. Publish accurate current/intended distinctions with the delivered slice. Preserve the public Wiki
   and exact Aimee Reference section; separately resolve its Scent Mask/Seamlight contradiction.

Later T2 Ingot cost/consumers, broader land/flora, traveller/Sigil/clue progression, and Peerless/refinement
remain separate design work. The closed inputs, outputs and finite hosts above change only through an
explicit next version. No full campaign reorder, runtime patch, or successful phone test is claimed.

## Direct Aimee solid-deposit clarification —4 September2026

The first Iron/Coal producers now have blocking physical bases in new cutover worlds. Deliberate movement into their adjacent base mines with the selected packed Pick; successful hits remain one turn and do not move the actor, even on depletion. Automatic routes never mine. Loose Clay, Salt and low flora remain walkable with their existing underfoot gathering. Exact intent, refusal, protected-route, durable depletion and legacy/canopy separation rules are in [Solid deposits and manual bump mining](early-solid-deposit-interaction-v1.md) and its authored JSON. These rules supersede any assumption that every mineral source is walkable or can be mined by standing on its footprint. Current installed/older worlds retain their saved behavior.
