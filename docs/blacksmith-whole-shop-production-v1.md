# Forge / Blacksmith — complete first-pass production batch

> **Consumer-backed Forge extension — Weaponsmith whole batch:** `weaponsmith-whole-shop-production-v1.md` adds Iron Collar (`processed.collar.iron`) casting at Forge T2 after either Weaponsmith or Armoury foundation teaches it: 2 Iron + 1 Coal → 1 ungraded Collar, 0 Essence, nominal4/buy8. This directly supplies all four fitted families without an Iron→Ingot→Collar chain. Existing Forge gear/tool recipes remain unchanged; no Collar is retrofitted onto starter equipment.

> **Shared textile dependency update — 5 September:** `tannery-whole-shop-production-v1.md` now defines Cord/Cloth from mixed actual Stem/Leaf constituents. Accept complete prepared-unit receipts with their nested source appearance; prior matching-only manufacturing references are superseded. This changes no recipe count, output effect, finished quality role or nominal Cord/Cloth value in this shop. Never count or recover prepared ancestors twice.

5 September 2026. **Complete first-pass Forge equipment contract delivered in phone324; tool/smelting/T3 dependencies were delivered in322. Iron Collar is delivered in328 as the consumer-backed extension: ForgeT2, either Weaponsmith/Armoury foundation knowledge,2Iron+Coal,0E,sale4/buy8.** Covers all eight catalogue families, the entire three-level field-tool progression, Iron Ingots, facility upgrades, material statistics/workmanship, pricing, deterministic refit and recovery compatibility.

## Authority and retained decisions

Aimee asks for whole-shop coherence and delegates recipe/cost/order tuning. Stone opening tools, raw-material starter gear, ingots at Forge T2, meaningful prepared components, actual source/colour custody and separate material quality/workmanship/statistics are retained accepted directions. The new T3 costs, family bundles, fixed world-material baselines, refit and value policy below are **Design-authored first-pass tuning**, not personal approvals invented on Aimee's behalf.

The former two-Bone Pointed Blade proposal is absorbed into the material rules for this whole shop. No individual Bone approval is assumed or requested. Bone production uses the existing `creature-bone-production-v1.md` contract; this packet closes its weapon/body roles, mixed **new typed** material construction, prices and recovery. It does not infer Hollow Bone from flight, invent new anatomy, or convert legacy Bone into measured new Bone.

Keep delivered early crafting and old items. The old six-band Pointed Blade path remains an explicitly supported compatibility route for its actual old materials; it is not the intended calculator for new stock. The other seven Blacksmith definitions in the old catalogue are not all live merely because they exist in source. This packet deliberately closes their new disposition and access.

## Facility and tool progression — no circular ingredient gate

Display facility levels as T1/T2/T3. Built internal tiers 0/1/2 correspond to those display levels; unbuilt state remains separate. Extend the Forge maximum to built T3 for this version. The legacy physical-recipe `stationCap: 5` is not a facility level or permission to infer a six-tier new shop. Forge level never directly becomes item workmanship or Power.

| Operation | Prerequisite | Exact costs / inputs | Result |
| --- | --- | --- | --- |
| Build Forge T1 | Halloway recruited, unbuilt Forge | 20 Essence, 8 Iron, 4 Plant Fibre, 4 Logs | Built T1; no free gear |
| Improve Pick 1→2 | Forge T1+, owned exact Pick 1 | 4 Iron, 1 Log, 2 Plant Fibre, 1 Coal; 0 Essence | Same Pick instance, tier 2 |
| Improve Axe 1→2 | Forge T1+, owned exact Axe 1 | Same bundle as Pick 2; 0 Essence | Same Axe instance, tier 2 |
| Upgrade Forge T1→T2 | Built T1 | 20 Essence, 8 Iron, 4 Clay, 4 Logs | Built T2 |
| Smelt Iron Ingot | Forge T2+ | 2 Iron, 1 Coal; 0 Essence | 1 ungraded Iron Ingot |
| Improve Scythe 1→2 | Forge T2+, owned exact Scythe 1 | 2 Iron Ingots, 1 Log, 2 Plant Fibre; 0 Essence | Same Scythe instance, tier 2 |
| Upgrade Forge T2→T3 | Built T2 | 40 Essence, 6 Iron Ingots, 8 Clay, 6 Logs, 2 Quartz | Built T3; no free tool or Peerless item |
| Improve Pick 2→3 | Forge T3, owned exact Pick 2 | 4 Iron Ingots, 1 Log, 1 Plant Cord, 2 Coal; 0 Essence | Same Pick instance, tier 3 |
| Improve Axe 2→3 | Forge T3, owned exact Axe 2 | Same bundle as Pick 3; 0 Essence | Same Axe instance, tier 3 |
| Improve Scythe 2→3 | Forge T3, owned exact Scythe 2 | Same bundle as Pick 3; 0 Essence | Same Scythe instance, tier 3 |

The starting Rock Pick/Axe/Scythe and their dedicated three-place tool roll remain. Tier 3 is hardened existing Iron construction, not a new Steel inventory item. Coal supplies the improvement process; it is consumed fuel. There is no repeated intermediate hardening material, smelting subgrade, tool durability, repair chore or extra Essence fee.

Only the next legal tier is offered for an owned tool; no 1→3 skip, repeat tier-3 craft, fourth tier or duplicate tool roll object is granted. Keep its exact identity, tool class, selected preference and packed-state linkage. Upgrading refunds neither the starting stone nor prior-tier construction materials; retain the previous maker receipt as history without restoring spendable stock. A normal preference remains active only when that exact tool is actually packed. These tools have harvesting tier, not weapon Power or creature quality. Bone/ornamental components do not let a low-tier Pick harvest rare material.

**Access now closed:** Pick 2 gathers Quartz, Sulfur and Mercury under the accepted new material table. Quartz can therefore help build T3 before Pick 3 exists. Pick 3 gathers Obsidian, Adamant and Rift-glass using the accepted rare-node two hits of one unit. This closes the late Apothecary dependency for Stillwater and Waystone; it does not make Rift-glass common or guarantee a node in every world. Axe 3 and Scythe 3 retain their already specified tree/plant access and yields, including actual dangerous-flora admission.

Plant Cord makes Corrin a useful later collaborator, while the first Pick/Axe/blade do not depend on the Tannery. Cord needs only2 eligible actual Stem/Leaf Fibre, with ordered mixed source constituents supported; Corrin's existing foundation requires 20 Essence, 6 Logs, 4 Clay and 4 Fibre. Neither Cord nor Forge T3 requires rare minerals, a creature drop, Nessa, Isolde, Distillery or Motes. Existing cheaper-next-Bind safety checks and actual currency ownership remain where applicable; never invent an extra fee or silently show 40 Essence while charging a different amount.

## Complete family register and knowledge

| Catalogue family | New Forge availability | Fixed output identity |
| --- | --- | --- |
| `pointed_blade` | T1 foundation teaches | Weapon, Pierce, Close |
| `cutting_blade` | T1 foundation teaches | Weapon, Rend, Close |
| `hand_maul` | T1 foundation teaches | Weapon, Crush, Close |
| `shield` | T1 foundation teaches | Offhand protection |
| `long_spear` | T2 upgrade teaches | Weapon, Pierce, Mid |
| `helm` | T2 upgrade teaches | Head protection |
| `rigid_guard` | T2 upgrade teaches | Body protection |
| `field_pick` | Tool section from T1; shows the owned Pick and its next upgrade | **The same dedicated Pick progression above**, not a competing craftable Tool item or a second extraction-level system |

T2 also teaches ingot making, the Scythe improvement and the refit service. T3 exposes the next upgrades of all three owned tools. Already known schematics remain known; an early discovery does not bypass the displayed facility gate. Apply grants through actual committed construction/upgrade/compatibility events, not screen rendering. No random research roll or additional fee teaches these basic families. Ingot working bundles below require T2 even on a T1 family.

Found catalogue equipment and old `field_pick` gear retain their existing frozen identity and uses. This does not transform a found Tool item into a free packed Pick-3 capability, migrate every old mining item, or add a new tool-disassembly route. Reconcile the new Field Pick catalogue card with the one owned-tool action rather than mounting two apparently different Pick progressions.

## Exact component bundles

A player chooses the family, one working bundle, and its support bundle(s). A listed **or** is a real explicit choice; every ingredient inside a chosen bundle is required. All ordinary new construction costs **0 Essence** and succeeds deterministically once its valid quote is committed.

| Family | Working bundle — choose one | Support ingredients |
| --- | --- | --- |
| Pointed Blade | 4 Iron + 1 Coal **or** 2 Iron Ingots **or** 2 Quartz **or** 1 Bone | Short grip: 1 Log + 2 Plant Fibre **or** 1 Bone |
| Cutting Blade | 4 Iron + 1 Coal **or** 2 Iron Ingots **or** 1 Bone | Same short-grip choices |
| Hand Maul | 4 Iron + 1 Coal **or** 2 Iron Ingots **or** 2 Bone | Haft: 1 Log + 2 Plant Fibre **or** 2 Bone + 2 Plant Fibre |
| Long Spear | 4 Iron + 1 Coal **or** 2 Iron Ingots **or** 2 Quartz **or** 1 Bone | Long haft: 2 Logs + 4 Plant Fibre **or** 3 Bone + 4 Plant Fibre |
| Shield | 4 Iron + 1 Coal **or** 2 Iron Ingots **or** 2 Softwood Logs **or** 2 Hardwood Logs **or** 2 Bone | Brace: 1 Log + 2 Plant Fibre **or** 1 Bone + 2 Plant Fibre |
| Helm | 4 Iron + 1 Coal **or** 2 Iron Ingots **or** 2 Bone | Lining: 4 Plant Fibre **or** 1 Cloth |
| Rigid Guard | 8 Iron + 2 Coal **or** 4 Iron Ingots **or** 4 Bone | Lining: 4 Plant Fibre **or** 1 Cloth; binding: 2 Plant Fibre **or** 1 Plant Cord |

The Pick family uses the exact owned-tool table, not these working bundles. There is no blank eighth weapon recipe. Coal is process fuel, never a physical socket, Power contribution, workmanship vote, visual component or recoverable material. The Ingot route already includes its smelting fuel and adds none beyond its listed bundle; tool-3 hardening explicitly lists its additional Coal. Cold-shaped Bone, Quartz and wood consume no fictitious forging fuel.

Material allowlists: Iron=`world.iron`; Ingot=`processed.ingot.iron`; Coal=`world.coal`; Logs are only Softwood/Hardwood Logs; Fibre only Stem/Leaf Fibre; Cloth=`processed.cloth.plant`; Cord=`processed.cord.plant`; Bone is the new validated `creature.bone`. Quartz=`world.quartz` is also allowed as a point in the two explicitly listed piercing families, retaining a supported material role from the older POINT catalogue. Clay appears only in the facility table. No generic Timber/Fibre, legacy graded world units, alternate metal, raw Hide, Pelt, Horn, Fang, Chitin, Glass or similarly named holding silently enters these new bundles.

The older Pointed Blade family's broad material options remain under the old recipe/receipt version until their actual typed producer and role mapping is supplied. That preserves existing stock without pretending this Forge batch completes every creature part or metal in the game. New Bone may mix with the listed new ungraded materials according to the bundles; the former two-Bone-only adapter restriction is withdrawn for this whole-shop version. Old and new Bone still do not mix by name.

### Physical roles and appearance

The working group is point, edge, head, spear point, shield face, helmet shell or body structure respectively. Support comprises actual grip/haft/brace, its wrap/binding and any lining. Fuel never participates. Do not import the old recipe's multi-primary IDs and accidentally give the haft an extra attack contribution.

Multi-piece Bone assemblies retain each selected portion's actual source, band, Density and full CMY/Depth/Pattern. A spear's three-Bone haft is an assembled long structure with its listed binding, not an invented long-bone subtype or a claim that any one tiny bone has spear length. Two Bone in a head or four in body structure are an assembly, not four times the Power. World-metal units are ungraded fungible material with retained source quantities.

Raw Forge bundles do not require matching colours. Listed Plant Fibre quantities may combine selected Stem/Leaf portions; support Logs may combine the two admitted Log types. A Shield face uses its explicitly chosen all-Softwood or all-Hardwood bundle, but colours may differ. Keep raw boards, wrap and lining portions as ordered source-coloured subcomponents rather than flattening them into an invented average-colour stock item. Bone pieces may likewise differ. Already prepared Cord/Cloth keeps its existing manufacturing/grouping rules. A Log core and Fibre wrap remain separate visible component treatments; exact final art belongs to the existing native-consumer/Asset process, not a new speculative artwork assignment. This avoids adding a matching-colour gathering chore before the first weapon.

## Statistics and workmanship — one calculator

Fixed world-material values below are **authored ungraded component baselines**. They do not create invented Hardness/Density bars for an Iron stack. Bone uses the actual source skeletal Density from its production receipt; Density is an explicitly chosen structural material measurement, not a claim that it is anatomical attack strength or material Hardness.

| Working material / role | Pointed Blade, Cutting Blade, Hand Maul, Long Spear Power | Shield or Helm Protection | Rigid Guard Protection |
| --- | ---: | ---: | ---: |
| Raw Iron construction | 2.0 | 1.0 | 2.0 |
| Iron Ingot construction | 2.5 | 1.5 | 2.5 |
| Quartz point, Pointed Blade/Long Spear only | 2.25 | unavailable | unavailable |
| Softwood face, Shield only | unavailable | 0.75 | unavailable |
| Hardwood face, Shield only | unavailable | 1.0 | unavailable |
| Bone working group | Actual contribution with ceiling 4 | Actual contribution with ceiling 2 | Actual contribution with ceiling 4 |

Each Bone unit i contributes `ceiling × (0.5 + density_i / 200) × multiplier_i`; multipliers for Poor/Common/Rare/Exceptional are 0.75/1/1.25/1.5. Average those unit contributions **within the working group**, then round the final item statistic once to the nearest quarter, half up. Counts are construction quantities, not repeated stat bonuses. Every selected Bone must have a valid actual source Density in 0–100; no fallback to size, species average, grade, Danger or invented 50.

Support parts in this first Forge batch provide required structure, separate colour and workmanship. They add **no invented Power, Initiative, Heat Ward, HP, weight penalty, elemental effect or hidden affix**. Damage kind/reach/slot remain the fixed family choice. Iron Ingot's listed construction improvement is the full improvement; do not add the old tier base, an extra +0.5 specialist offset or a quality multiplier again. Do not convert equipment Power into a guaranteed HP-loss claim.

Workmanship ranks use Rough/Fine/Superior/Exceptional at 0/1/2/3. A new ungraded material component votes rank 1. A Bone component votes its actual Poor/Common/Rare/Exceptional rank 0/1/2/3. For a multi-unit component, average its Bone unit ranks. Average the logical support subparts equally: for example core/haft/brace and wrap/binding, or lining and binding; quantity does not give a wrapping bundle extra votes. A one-piece Bone short grip has one support vote. Compute `roundHalfUp(0.70 × workingGroupRank + 0.30 × supportGroupRank)`. No animal parts means Fine. No ordinary construction/refit produces Peerless.

A superior Bone grip can improve the workmanship label without improving an Iron point's actual Power. The preview must show both facts plainly. Workmanship is not an extra damage multiplier. Tool tiers are separate again: they do not use this calculation.

### Numeric examples

- Retained raw-Iron Pointed Blade recipe (4 Iron, 1 Log, 2 Fibre, 1 Coal): Fine, Power 2.0, no Initiative bonus.
- Ingot point with the same Log/Fibre grip: Fine, Power 2.5, no hidden tier bonus.
- Common Bone point, actual Density 50, with Common Bone grip: Fine, Power 3.0. At Density 40 its Power is 2.75 after the one quarter rounding.
- Poor Bone point at Density 0: Power 1.5; an Exceptional grip may change workmanship but not that working contribution.
- Exceptional Bone working group at Density 100: weapon/body contribution 6.0, or shield/helm 3.0. This is a valid upper bound of the accepted material formula, not a guarantee of an obtainable early specimen.
- Two Common Bone head portions at Density 0 and 100: contributions 2 and 4 average to Power 3, not 6. Preserve both source colours.

The three close weapon corners share an understandable baseline. Mid-range Spear arrives at T2 and uses its larger support bundle; it does not get a free extra Power bonus from its longer haft. Normal gameplay comparison should check that existing range/skill distinctions remain useful without inventing a new combat restriction or hidden penalty in crafting. Numeric balance stays revisable after that check.

## Whole-shop prices and full component recovery

For **new items made under this batch**, freeze sale value at the sum of the nominal sale values of all actual recoverable structural inputs at that craft/refit quote. Name this sum C. Raw Iron is 2/unit, Ingot 4, Quartz 6, Logs/Fibre/Cord 1, Cloth 2, Bone 2/4/8/16 by its actual band. Ignore fuel, previously spent process inputs, currencies, colour, species name, raw Density and output workmanship for the value calculation. Normal offered purchase is 2C; this does not create merchant stock. Keep source price-book version and exact component nominal values in the receipt; do not dynamically reprice owned gear.

This unifies the old isolated Bone resale suggestion with every new Forge family. It is first-pass Design pricing, not a special Bone privilege. Existing crafted items keep their frozen values: the earlier starter Iron blade remains worth its recorded 10 Gold. A future equivalent blade made with this batch's consistent component policy has C=11 (8 Iron value + 1 Log + 2 Fibre) and sells for 11, buys for 22 when actually offered. The revision is deliberate; do not silently alter an owned 10-Gold blade.

| New construction example | Recoverable structural value / sale | Ordinary purchase if offered |
| --- | ---: | ---: |
| Raw-Iron Pointed Blade, Log/Fibre grip | 11 | 22 |
| Ingot Pointed Blade, Log/Fibre grip | 11 | 22 |
| Quartz Pointed Blade, Log/Fibre grip | 15 | 30 |
| Two Common Bone Pointed Blade | 8 | 16 |
| Two Rare Bone Pointed Blade | 16 | 32 |
| Softwood Shield with Log/Fibre brace | 5 | 10 |
| Raw-Iron Helm with raw Fibre lining | 12 | 24 |
| Raw-Iron Rigid Guard, raw Fibre lining/binding | 22 | 44 |
| Ingot Rigid Guard, Cloth lining/Cord binding | 19 | 38 |

**New Forge receipt recovery follows the already delivered early-material approach:** at an available Recycler, dismantling one eligible new piece returns all of its exact recorded structural components and consumes that item once. This makes experimentation with material colours and roles recoverable. It never refunds Coal, smelting fuel, Salt, fees, ancestor raw inputs of an Ingot/Cloth/Cord, or a second balance from history. The same receipts feed deterministic refit below. No new field-tool dismantling route is added.

Legacy six-band gear keeps its existing 40%/55%/70% service rules and protected/undefined recovery dispositions. Early already-delivered full-component receipts keep their actual recovery. Do not retroactively grant full recovery to legacy gear, guess components from its silhouette or fallback catalogue ID, or restore both a processed component and its raw ancestors. Future migrated maker batches should adopt this explicit new-component model; do not silently alter other shops in this change. Recycler tier's old percentage advantage still applies to old receipts; its future wider role is part of that shop's own batch, not an invented perk here.

The economy proof is structural: input purchase is 2(C + consumed-fuel value), so it strictly exceeds either new-item sale C or sale of all recovered components C. Smelting 2 Iron + 1 Coal costs 12 Gold if bought; one Ingot is worth 4, so processing cannot close a profit loop. Existing offered item purchase 2C also exceeds full recovery C. Refitting transfers outgoing components back while consuming incoming ones and recalculating the item from its new contents; it never creates extra quantities. Old-price compatibility must not grant new-valued components that the old item never owned.

## Refit, legacy Reforge and later refinement

**New deterministic Refit** is a Forge T2 service for the seven new gear families with complete structural receipts. At Home choose the exact identified, unlocked owned item and a working or support bundle to replace. Family, damage kind, reach, slot and item identity stay the same. Replace the complete selected logical bundle; do not treat a fuel unit as a replaceable part. Pay the new bundle's listed materials/fuel, 0 Essence; return the outgoing bundle's recorded recoverable components once. Existing item location must be quoted and preserved through supported stored/worn custody; never operate on a live excursion item through a Home-only screen.

Recompute the final statistics, workmanship, appearance receipt and C from the final actual component set. Do not add the new contribution to the old item's stored Power. Old unaffected components retain their identity/colour. The preview shows exactly what changes and what returns. Favorite status can remain on the same nondestroyed item; locked items keep their existing protection. Dismantling still follows normal favorite/equipped/locked/unique/narrative safeguards.

Changing an item into another family is ordinary new construction with actual materials, not a refit that silently changes its combat corner. Owned field tools use their explicit upgrade operation. Refit cannot consume another equipment item as if it were raw Bone or an Ingot. It cannot duplicate an inscription, coating, protected return or old legacy workmanship credit.

The old Reforge action remains compatible only with the old item versions it actually supports. It must not feed the new four-band item into the old tier/rank Power formula. A new item exposes the new deterministic Refit where supported, and does not claim a working Mote refinement action. A legacy item with incomplete measured components cannot enter the new calculator until a deliberate supported rebuild supplies the actual materials/identity treatment; do not guess one from its old quality name.

Aimee's later Peerless journey remains: maximum shop + attending keeper + Mote gives the intended 100% outcome; partial setups offer chances. Forge T3 is the maximum in this authored batch, but merely reaching it does not implement or grant Peerless. The actual Mote-on-miss preference, probability/progress/service design and the later Peerless statistical effect stay in the dedicated equipment-refinement batch. Ordinary forging/refit never destroys or downgrades a piece through a random miss and does not depend on that unresolved choice.

## Producer and cross-system dependencies

- Iron, Coal, Clay, Logs and Fibre use their existing finite physical producers. Preserve actual-source selection, saved multi-hit work, one-turn successful harvesting and zero-turn wrong-tool/stale refusals. No new mining/gathering resource is added to pay for the Forge.
- New physical Quartz comes from the shared named-mineral producer in `apothecary-whole-shop-production-v1.md`; the existing legacy Quartz balance is not secretly retyped. Integrate that source/Return owner before presenting the complete new T3 construction as obtainable.
- Plant Cord/Cloth use already delivered Corrin processing. No later Tannery overhaul is required to unlock the basic Cord needed by tool 3. Raw alternatives remain for earlier wearable supports.
- Bone uses the complete existing anatomy/source/quality/yield/Return contract. Its native production is still a real implementation dependency, not a promise that every creature drops it. Mixed new Bone construction must wait for valid typed source records; missing records never default to a fabricated average.
- Pick 3 closes Rift-glass access for the later Apothecary recipes. Requiring Pick-2 Quartz for the Forge upgrade and ordinary Cord for the tool prevents a Rift-glass→Pick-3→Rift-glass cycle.
- Bowyer/Weaponsmith retain their own families and future prepared-part choices; this batch neither absorbs their range/damage options nor attaches their old +0.5 offset to every Forge item. Armoury retains its own rebuild ownership and receipt compatibility.

**Minimum raw path check**, excluding departures, combat gear, optional Axe/Scythe upgrades, Nessa and surplus harvest quantities: from the owned starting stone tool kit to built T3 plus Pick 3, including Corrin's foundation and making the one Cord, requires **100 Essence, 40 Iron, 13 Coal, 22 Logs, 12 Plant Fibre, 16 Clay and 2 Quartz**. Ten total Ingots are made from the counted Iron/Coal (six for T3, four for Pick 3); the Cord uses the counted two Fibre. Do not also add those processed units to the raw total. This is a dependency/accounting check, not a promise of one-world completion or a measured pacing claim.

## Planned Forge work deliberately kept out of active recipes

Ordinary Glass retains the already specified two alternatives: 2 Sand + 1 Coal or 1 Quartz + 1 Coal → 1 Glass, 0 Essence. It remains unpromoted until an implemented consuming family justifies it; the future optical-instrument batch is the named dependency. Do not add empty Glass stock to this Forge menu, treat Glass as Rift-glass or replace the Apothecary's actual Quartz with it. Additional named metal Ingots likewise require real consumers and source contracts; no generic Metal or new Steel intermediate is created here.

This is the complete **first-pass Forge batch** over its existing catalogue and actual tool/processing dependencies, not a claim that every future mineral, creature part or specialty shop has been implemented. Held Glass/expanded metals are explicitly scoped planned work, not hidden unfinished rows inside an advertised ready recipe.

## Quote, persistence and acceptance

Use the existing durable candidate/commit route. Quote station/knowledge, exact item/tool state, every physical lot and source portion, currency, component bundle, computed quarter stats/workmanship, C, recovery and destination. A physical unit cannot pay two sockets. Unsupported IDs/versions, stale custody, duplicate selections, wrong tier, insufficient stock, Cancel, failed save and replay leave all balances, output/history and knowledge unchanged. Batch ordinary gear by multiplying exact ingredients; facility/tool upgrades/refit target one exact instance and cannot be multiplied as stack crafts.

Persist input deduction, output or same-instance mutation, returned components, complete source/colour history and any knowledge grants atomically before success. Full Storehouse follows supported merge/Waiting for a newly crafted item; no automatic equipment or Field Kit packing. Refitting/recovering must keep all returned goods claimable. Output history is not usable inventory. All existing specific identity/protection rules remain; the new material model is not permission to erase an inscription or duplicate an excursion coating. Home crafting cannot fabricate a new active-world coating state.

| Bounded case for Engineering | Expected |
| --- | --- |
| Stone start → Forge T1 → raw Iron blade/Pick 2 | No Ingot/Corrin/rare-mineral prerequisite; exact established raw costs; blade Power 2 |
| T2 upgrade → Ingot → Scythe 2 and Tannery Buckled Guard | Existing first useful consumers remain obtainable; each actual input spent once |
| Pick 2 Quartz + ordinary materials → Forge T3 + Pick 3 | No circular rare-material gate; then actual Rift-glass mining supports late Apothecary supplies |
| Already owned tool, selected/packed preference, repeated upgrade or reload | Same instance/class, next tier only, no duplicated tool or free tier skip |
| Open all eight catalogue families across T1/T2/T3 | Seven real gear construction families and one owned-Pick route, not eight misleading gear cards |
| Raw Iron / Ingot / Bone combinations in each allowed role | Exact bundle quantities and closed allowlists; old material names cannot substitute; unsupported legacy options remain honest old-route choices |
| Bone point Density 40/Common, exceptional grip; mixed-density two-Bone head | Correct quarter Power and separate 70/30 workmanship; no extra handling bonus or quantity-based Power multiplication |
| Pure metal/wood gear and T3 facility | Fine ordinary workmanship; no imaginary Creature grade or automatic Peerless |
| Craft → sell or dismantle; craft → refit A→B→A → dismantle | No buy/craft/salvage profit, added component quantity, fuel/ancestor refund, additive Power or identity duplication |
| Existing 10-Gold starter blade vs new C=11 equivalent | Preserve old frozen value; new version displays its explicit value consistently at preview, store and trade |
| Old six-band protected/partial-recovery gear enters new menus | No unsupported conversion, full-recovery upgrade or old tier calculator applied to new gear |
| New Bone producer absent, low tool tier, unknown source, full storage or stale quote | Honest unavailability/claimable result; no guessed source facts or partial spend |

All rule choices needed for this first Forge batch are supplied. Engineering may split implementation commits within the batch and coordinate shared source code with Apothecary, but do not restart the isolated Bone approval/adapter queue. Any actual incompatibility should be raised against the specific closed rule. **Consolidated personal decision list:** no new Forge recipe question; the separate Mote-on-miss experience remains the real Aimee choice for later refinement. Source/producer implementation and normal play balancing remain team work.

Design checked the cumulative raw path and structural price-loop arithmetic. Repository organization/whitespace checks accompany the checkpoint. No native build, mounted test, phone delivery re-verification, new audit framework or claim of delivered gameplay is included.

## Shared service resolution · 6 September

The [shared equipment improvement and recovery contract](equipment-improvement-recovery-production-v1.md) now resolves this packet's ordinary-service/legacy-preservation boundary. New-policy gear uses its specified deterministic refit/remake/rebuild or fitting; it does not inherit old Reforge ranks or the unapproved +0.5 proposal. Only active components are recoverable. Unsupported old paid-credit targets keep their supported legacy services. Peerless remains a separate pending service with the existing Mote-on-miss question open; Apothecary consumables gain no equipment-refinement route. This supersedes references above to an unnamed future ordinary-service batch.

## Conditional anatomy extension — separate first-pass proposal

[Remaining creature anatomy/material uses](creature-anatomy-material-extensions-v1.md) defines optional actual Fang/Claw components, measured Membrane-to-Leather processing and a chemically qualified creature Venom alternative, where this shop owns the exact named role. Those producers/adapters are not implemented. The complete ordinary batch remains independent, including full-excursion coatings; no generic family sample satisfies a new typed source.

## Conditional solid-material extension — later first-pass proposal

[Solid creature equipment uses](creature-solid-equipment-extensions-v1.md) now defines the exact applicable Shell Shield, Horn grip/Collar, scaled/chitin/shell Armoury outer and Fur Pelt lining sockets, with complete stat/quality/colour/value/recovery rules. Its typed source producers and adapters remain unimplemented. This ordinary batch keeps its present recipes and progression; no legacy generic family automatically enters the alternatives. Spines and Feathers are intentionally raw-sale-only, not a request for another recipe.

## Delivered checkpoint — phone324,6 September2026

Engineering reports installed source f6466a0b69285e67c432294e3fc9dd0f43a9eb5a, tree52937b4cd1df5091cd30dafe1ff595a3ad5732ce; delivery4ec0ec8ae2ca621a86cc9c12ea18b79a8a14cf0d, tree6b2abecb6086600d535e513a0709128658a256fa. Persistent `/Users/aimeepepper/Documents/comfygame-worktrees/early-material-regions-v1`, branch `codex/early-material-regions-v1`. Installed23:41:13UTC, ordinarily launched23:42UTC on Aimee's iPhone16Pro; acceptance used402×874/default/current ordinary configuration. Supplied receipts: `docs/phone-build-324-delivery-2026-09-06.md` and `docs/forge-whole-shop-implementation-2026-09-06.md` in that worktree.

Delivered seven Forge equipment families, exact world/Bone working/support choices and tier gates, quarter-precision stats, four-band workmanship, fixed version-one prices, same-instance refitting across stored/Waiting/worn gear and current-component recovery. Existing322 Pick/Axe/Scythe and smelting/T3 routes remain their owners. New opted-in Bone keeps full actual source measurements/CMY/Depth/Pattern, species quantity and frozen Anatomy, has no additional roll/generic duplicate, and survives reward/Return/current saves/sale with2/4/8/16 values and2× repurchase. Unsupported legacy property-only services refuse typed Bone.

Sixteen distinct focused/native tests passed, including50 working/support combinations, seven default constructions, two native journeys and injected write-failure/recovery/replay. This is Engineering-provided evidence, not a Design native/phone recheck. Older-version migrations remain deferred under Aimee's instruction; current-version durability remains required. Iron Collar, Bowyer/specialist complete batches, wider creature anatomy and Asset's separate Forge polish are not claimed delivered here. No reset/uninstall or new runtime rollout is authorized by this record.

## Forge presentation delivered — phone325

Engineering integrated the approved parchment panels, explicit picker role/unit labels, individually numbered source parts, and separated frozen-result/returned/attached component review. Shared composition ink has a paper backing in current ordinary Storehouse/equipment presentation. The existing seven-family craft/cancel/Bone-refit/exact-ID reopen regression passed; phone325 is installed and ordinarily launched. Prices, source facts, transactions and stats are unchanged. Evidence: Engineering’s phone325 delivery and forge-equipment-presentation-2026-09-06 receipts; no duplicate Design native checks.
