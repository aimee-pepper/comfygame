# Whole Tannery production — textiles, Leather, clothing and Carry

**5 September 2026 · Complete Design-authored first-pass implementation contract; delivered in phone323 on6 September2026.**

Authority: Aimee delegated recipe, order and cost tuning and requested whole-shop batches. Preserve her accepted raw-to-prepared progression, real material identity/colour, creature quality, no ordinary crafting Essence toll, and capacity preservation. The changed ratios, mixed textile construction, new Leather accessories and future-craft pricing below are Design choices under that delegation, not newly attributed personal approvals or measured balance.

This packet closes Corrin's whole foundational shop: three prepared materials, three clothing families with seven variants, ordinary refitting and Carry's exact relationship to existing storage. It supersedes future Tannery instructions in `tannery-system-current.md`, the Tannery rows of `crafting-shop-batch-overhaul-2026-09-05.md`, and affected rows of the early specialist, Leather and carrying packets and their companion JSON. Those earlier rows describe retained v1 compatibility; they are not the new construction table. Apothecary and Forge retain their completed contracts except that their Cord/Cloth consumers accept the complete mixed textile receipts defined here.

## 1. Earlier behavior and the delivered changes

Reported early implementations make Cord from two matching Fibre portions, Cloth from four matching portions, and Leather from two matching eligible Hide/Skin plus Salt. Woven Guard, Buckled Woven Guard, Woven Gloves/Boots and Leather Guard already have delivered routes. Older sample-based Supple Coat/Working Gloves/Working Boots families coexist. This paragraph describes the preceding routes; phone323 now delivers the full-shop rules below.

| Subject | Earlier rule / existing receipt | Delivered first-pass rule |
| --- | --- | --- |
| Fibre processing | Matching Fibre type and full colour | Select any actual Stem/Leaf Fibre portions; retain each constituent |
| Leather dressing | 2 matching raw Hide/Skin + 1 Salt → 1 Leather | 1 eligible raw portion + 1 Salt → 1 Leather |
| Leather Guard | 2 output-equivalent matching Leather + Cord | 2 individually selected Leather panels + Cord |
| Clothing catalogue | Early items alongside three older named families | Three families, with woven/leather variants and the buckled woven body variant |
| Gear sale values | Frozen older authored prices | New crafts use actual recoverable component values, as in Forge |
| Carry | Delivered early projects plus older historical routes | Keep 8→11→14→23 and preserve old purchases; no new root fee |

Do not reprice, weaken, recolour or replace already-owned garments or prepared/raw lots. Version new crafting and price policies, not the player's material names. Recipe UI shows the new ordinary route once; old inventory support is not a second competing novice recipe menu.

## 2. Access, ownership and learning

Corrin's foundation remains **20 Essence, 6 Logs, 4 Clay, 4 Plant Fibre** after recruiting Corrin. Logs are actual Softwood/Hardwood and Fibre actual Stem/Leaf. Mixed sources are valid. Use the existing construction/staffing price modifier rules only where they already apply; the listed costs are authored base quotes. An attending Corrin is not required to use the completed shop or make normal gear. Staffing cannot create a second material refund, improve raw quality, or turn a zero-Essence craft negative.

Building the Tannery supplies its Wear/Carry access and teaches the ordinary processing and all seven garment variants. Reveal missing ingredient names in these known recipes; unknown species remain undisclosed. Buckled Woven Guard needs an actual Iron Ingot from Forge T2, not a new paid pattern or Tannery tier. Already known legacy patterns stay known. No separate Study, 18-Essence Carry toll, T2 Tannery, Leather prerequisite for cloth or carrying, or invented new facility.

All processing, garment crafting and the ordinary refit below cost **0 Essence**. No timers, durability, repairs, encumbrance, tanning vats, strap tokens, sewing-kit tolls or compulsory crafting sequence. Corrin owns flexible foundational garments; Bracken retains later Armoury profiles. Forge still owns its rigid families. The max-level/Mote service is separate from ordinary refit and is not made available by this T1 plan.

## 3. Whole prepared-material table

Every row outputs one unit and records exact consumed quantities. Multi-count preparation repeats that unit recipe with an explicit allocation; it must not consume the same portion twice.

| Output / stable material ID | Inputs | Grade and appearance | Base sale / buy |
| --- | --- | --- | --- |
| Plant Cord / `processed.cord.plant` | 2 Stem and/or Leaf Fibre | Ungraded; both selected strands retained | 1 / 2 |
| Plant Cloth / `processed.cloth.plant` | 4 Stem and/or Leaf Fibre | Ungraded; four selected constituent sections retained | 2 / 4 |
| Leather / `processed.leather` | 1 eligible Skin/Hide portion + 1 Salt | Exactly that raw portion's band, measurements and colour | Actual raw portion's frozen nominal sale + consumed Salt nominal; buy twice result |

**Aimee confirmed on 6 September:** harvested flora colours must remain usable as visible crafting colours, not only source history. The selected Cord strands and Cloth sections carry those appearances into equipment bindings and woven regions, and retain them through refit/recovery. See the flora clarification in [the source-colour contract](player-feedback-wood-hide-apex-notices-2026-09-06.md).

Fibre IDs remain `flora.fibre.stem` and `flora.fibre.leaf`; no new generic Mixed Fibre, Strap or Lining stock is minted. Cord/Cloth never gain creature quality. They retain nested source snapshots and appearance rather than averaging colours into a fictional plant. A homogeneous composition can keep its ordinary single-colour display; mixed Cord has two source-coloured strands and mixed Cloth four source-coloured sections in the selected order. This is a semantic composition contract, not a new assignment for speculative artwork. Until a native consumer presents the exact composition, preserve the data and use honest names/swatches; never substitute guessed final art.

Resolve auto-selection deterministically from the persisted inventory order, then freeze it in the quote. Players may change a section/strand selection for appearance. Gathering source colour is not an extra eligibility threshold. A missing approved RGB artwork mapping is different from missing actual CMY/Depth/Pattern source data: retain known source data without fabricating RGB. Truly unresolved old colour uses an explicit unknown appearance and its real legacy owner; it must not be guessed or described as a known-colour source. This mixed composition rule replaces the earlier matching-colour refusal as the new manufacturing destination.

These remain two ungraded material stack types, with individual source/composition lots beneath them. Composites do not add top-level material subtypes, fake species or quality variants. Reopening, Return, transfer, trade and crafting preserve the complete actual constituent receipts.

Prepared materials are not reverse-processing recipes. Recycling Cord, Cloth or loose Leather never returns their raw ancestors or Salt. Garment recovery returns prepared components intact, including their older manufacturing version if applicable.

## 4. Actual producers and anatomical boundary

Retain existing flora rules: Stem Fibre from the medium source with Scythe 1 yields 2 in one hit; Leaf Fibre from the low source with Scythe 1 yields 1; Tall Stem uses Scythe 2 and yields 3. Sources remain finite actual generated plants in the existing eligible fresh/photosynthetic cohort. Preserve full source history/colour and existing world source budgets. No extra placement, guaranteed animal, or generated ingredient because a recipe is known. Salt remains the existing hand-gathered geological material and its existing source/guarantee rules.

The eligible raw covering IDs are exactly:

| Raw part | Existing physical classification after primary Hide wins |
| --- | --- |
| `creature.skin.smooth` — Smooth Skin | Aquatic habitat or piscine body plan |
| `creature.hide.supple` — Supple Hide | Otherwise, covering hardness below 25 |
| `creature.hide.tough` — Tough Hide | Otherwise, covering hardness at least 25 |

Both the species projection and actual placed primary-covering priority must support Hide. Retain the existing minimum coverage and harder/longer covering precedence from the early Leather source contract. Unsupported/mismatched legacy data stays on its supported legacy path; it does not get a newly invented typed drop. Pelt, Scale, Chitin, Shell, Plate, Feather, Fin and Bone are not admitted merely because an old property predicate could pass. Other anatomical rewards retain their current versioned branches. Future body-to-material catalogue work remains separate; this shop has a complete usable path without inventing those producers.

Preserve the **70%** eligible primary-covering reward chance, base quantity `clamp(1 + floor(size/25), 1, 4)`, and strongest departure-frozen Anatomy benefit once: on success add `max(1, floor(base × .35))`; on miss zero. Thus base 1/2/3/4 becomes 2/3/4/5 with Anatomy, without changing the chance. Persist the actual per-foe eligibility, quantity and roll policy/decision before granting, and consume once. Never recompute from the roster at Return or create a second primary-Hide reward.

Preserve exact source IDs, coverage, hardness, covering length, flexibility, full CMY/Depth/Pattern and the early formula: part expression `(coverage + flexibility)/2`; score `roundHalfUp(.75 × partExpression + .25 × DangerValue)`, with Danger 0–5 → 20/35/50/65/80/95. Clamp measured inputs 0–100 and round only the final score. Scores 0–24/25–59/60–84/85–100 give Poor/Common/Rare/Exceptional, rank 0/1/2/3 and stat multiplier .75/1/1.25/1.5. `coveringProtection = hardness × coverage / 100`.

One-to-one dressing preserves those facts verbatim. It does not average several bodies, upgrade a band, or add Salt to quality/colour. Two Leather panels on a garment may differ in all these facts; each contributes from its own real measurements.

## 5. Complete garment catalogue and construction

Use three existing stable family identities: `supple_coat` (Body), `working_gloves` (Hands), `working_boots` (Feet). Present player-facing family headings **Guards**, **Gloves**, **Boots**, with explicit material variants below. Keep existing authored early item IDs and their equipment identity; family membership is metadata, not an inventory conversion. New Leather accessory variant keys are `tannery.leather_gloves.v1` and `tannery.leather_boots.v1`; exact generated item identity follows the existing gear allocator. New recipe versions carry this contract's rule version separately from existing item IDs.

| Family / variant | Complete selected ingredients | Finished Protection | New sale C with ordinary new Common Leather |
| --- | --- | --- | ---: |
| Body — Woven Guard | 1 Cloth, 1 Cord | 1.5 | 3 |
| Body — Buckled Woven Guard | 2 Cloth, 1 Cord, 1 Iron Ingot | 2.0 | 9 |
| Body — Leather Guard | 2 Leather panels, 1 Cord | Panel formula below + .25 | 9 |
| Hands — Woven Gloves | 1 Cloth, 1 Cord | 1.0 | 3 |
| Hands — Leather Gloves | 1 Leather, 1 Cord | Leather formula below + .25 | 5 |
| Feet — Woven Boots | 1 Cloth, 1 Cord, 1 Resin | 1.0 | 5 |
| Feet — Leather Boots | 1 Leather, 1 Cord, 1 Resin | Leather formula below + .25 | 7 |

Each row outputs one owned item; no auto-equip. Resin seals Boots and remains a recoverable recorded construction input under the retained early Boots/Forge recovery convention. It has no separate tint region or quality vote. Ingot supplies the Buckled Guard's authored fixed construction profile, with no hidden extra property formula. Multiple Cloth units may have different compositions. The garment records actual selected Cloth, Cord and Leather regions rather than flattening their parents into one colour.

Woven recipes stay Fine workmanship with exactly the listed total Protection, no Initiative change, ward, HP, handling or harvesting/extraction bonus. Do not compute the old tier base plus its `powerOffset` and then add the new full total again.

For each Leather panel i, let `p_i = coveringProtection` and `q_i = band multiplier`:

- Leather Guard: `roundQuarter(2 × (.5 + p_A/200) × q_A + 2 × (.5 + p_B/200) × q_B + .25)`.
- Leather Gloves/Boots: `roundQuarter(2 × (.5 + p/200) × q + .25)`.

Here `roundQuarter(x) = floor(4x + .5)/4` for nonnegative x. Keep full precision until that one final rounding and use the existing one-decimal display. The Guard reproduces the accepted earlier formula exactly when its two panels match. The **.25 construction contribution is retained and explicit**; it is not a grade bonus or a reason to revive an old hidden handling statistic. Accessories use the same two-point common role ceiling per material-bearing piece. No stat is recomputed from a fabricated averaged Leather sample.

Leather panels are the sole quality-bearing primary group. Average their band ranks, round half up, and map 0/1/2/3 to Rough/Fine/Superior/Exceptional. Minor Cord and expendable Salt do not vote, consistent with the accepted primary/secondary rule. A woven item has no creature-quality input and remains Fine. Do not import Forge's specifically designated structural-support weighting into these minor garment ties.

Examples: two Common panels with p=50 give Leather Guard 3.25 Protection and Fine workmanship. Poor p=20 plus Exceptional p=80 gives `.9 + 2.7 + .25 = 3.85`, rounded to **3.75**, Superior workmanship (mean rank 1.5→2). One Rare p=40 accessory gives `2 × .7 × 1.25 + .25 = 2.0`, Superior. No protective item gains attack damage from high hardness.

### Existing catalogue dispositions

- Supple Coat becomes the shared Body family containing all three Guards; preserve older owned Supple Coats and their frozen authored profile.
- Working Gloves contains the woven and Leather glove routes; old item instances remain unchanged.
- Working Boots contains the woven and Leather boot routes; old item instances remain unchanged.
- Retire the older invisible FLEX_BODY/LINING/FLEX_FACING/SOLE/BINDING threshold recipe offers for future ordinary crafts once this batch is enabled. Preserve their old receipts and already purchased knowledge; show supported old equipment honestly. Do not silently convert an untyped old sample into a newly eligible Hide, Cloth or Leather.
- The old family slots/thresholds are compatibility data, not additional new variants promised by this plan. There are seven complete variants, not seven plus an unbounded property-based fallback.

## 6. Prices, receipts and recovery without trading exploits

Future typed Skin/Hide uses the accepted common Skin/Hide market base **3**, applying the global .5/1/2/4 sale multipliers and positive half-up rounding: **2/3/6/12** for Poor/Common/Rare/Exceptional. Buy is twice the actual sale. This deliberately replaces the delivered dampened subtype tables for newly produced rewards only; species, colour and hardness do not add a premium. Freeze the selected reward price policy with the foe/reward owner, so reopening or defeating an already-snapshotted old foe cannot reprice it.

Old Smooth Skin stays at its frozen 2/2/3/3; old Supple/Tough stays 2/3/4/5; already-made v1 Leather stays 3/4/5/6. Resolve a pre-policy lot's value from its known old subtype/band once, never from the new table by accident. Unsupported legacy samples keep their existing price owner and eligibility.

For newly dressed Leather, value is **the actual selected raw portion's frozen nominal sale plus the consumed Salt's frozen nominal sale** (normally 1). Thus genuinely new typed Leather is **3/4/7/13**. Dressing older Supple/Tough yields 3/4/5/6, and older Smooth yields 3/3/4/4. Never buy cheap old Exceptional Skin for 6 and turn it into newly priced Leather worth 13. This compatibility difference reflects the real input value, not a new biological subtype or source premium. Underlying lots retain exact prices beneath the existing material stack; quantity selection and trade quotes disclose their actual totals.

Every new garment's sale C is the sum of **actual selected recoverable components' frozen nominal unit sale × quantity**, identical to the Forge contract. Buy is 2C. New standard nominal values are Fibre 1, Cord 1, Cloth 2, Resin 2, Iron Ingot 4, and each Leather lot's own recorded value. No additional grade/species/colour multiplier is applied to C. Prepared ancestors, processing Salt, craft currencies and fuel are not counted twice. Freeze C in the finished item's receipt; do not reprice owned equipment when registries change.

Examples with two same-band newly produced Leather: Guard C = **7/9/15/27**; Gloves **4/5/8/14**; Boots **6/7/10/16**. The mixed Poor/Exceptional Guard example is C=3+13+1=17, buy34; quality is Superior without replacing its two Leather prices with a Superior table. Existing v1 Guards keep 8/10/13/15 and old woven items keep 5/12/5/7 for Guard/Buckled/Gloves/Boots.

Full dismantling of new or already-supported early complete-receipt garments returns precisely the selected prepared components once. It returns no original Fibre from returned Cloth/Cord, no Hide or Salt from returned Leather, no duplicated family sample, no Essence and no replacement gear. Older partial-recovery legacy items retain their existing versioned policy; do not manufacture a complete receipt from a display name. Existing lock/equipped/ownership dismantle protection remains.

Buying a new garment for 2C and selling recovered inputs yields C; buying inputs to craft costs at least 2C and yields sale C. Cord consumes raw nominal2 and sells1; Cloth consumes4 and sells2. Dressing consumes raw+Salt nominal equal to output sale, so buying its inputs costs twice output sale, including legacy-priced portions. Higher gear quality cannot bypass this accounting. Recovery is bounded by exact selected inputs and their frozen nominal values, not a generic percentage layered over full recovery.

## 7. Ordinary garment refit

At the built Tannery, permit **0-Essence deterministic component replacement** for an unlocked, owned garment with a supported complete construction receipt. Preserve the exact item identity, custody, slot and family. Preview outgoing components, selected replacement bundle, final appearance, total Protection, workmanship, sale value and destination before committing.

Replace a complete recipe socket/bundle; never edit a panel's source measurements or grade. Leather Guard exposes two ordered one-panel sockets, its Cord one socket. Cloth/body regions, ties and a boot seal/buckle are their actual defined recipe inputs. Return replaced recoverable inputs exactly once; retained components remain attached and are not refunded. Unchanged selection is a no-op with no duplicated history or output. Freeze the final complete receipt and recompute the full final stats and C from that receipt, not by adding a bonus to the old item.

A whole style change within the same family (for example Woven→Buckled Guard or Woven→Leather Gloves) is one explicit **Remake as [variant]** using the complete new variant recipe. It returns the complete old recoverable construction once and consumes the complete new recipe once. It does not move slots or keep obsolete stats/buckles. Reuse an outgoing component only through an explicit quote allocation that nets it once; otherwise reserve new inputs from owned available stock. Neither adding an Ingot repeatedly nor repeating a variant switch grants cumulative Protection. Existing item IDs remain stable while a persisted construction/variant record supplies its current name and profile; do not mint a duplicate inventory item.

Old garments without enough source evidence to refit remain usable/sellable under their known legacy policy and explain “This older piece has no recoverable component record.” Do not guess or silently weaken them. Existing unrelated Reforge/service compatibility is unchanged; this new receipt path never layers the older six-band grade formula, discounts or partial-recovery percentage over the new deterministic result. No refit to Peerless is promised here.

## 8. Carry and Home storage — complete retained relationship

| Project | Prerequisite / location | Authored base price | Ordinary field capacity |
| --- | --- | --- | ---: |
| Opening pack | Already owned | None | 8 |
| Reinforced Stitching | Opening Storehouse; no recruit | 5 Essence, 4 Fibre | 11 |
| Balanced Straps | Stitching; Storehouse | 10 Essence, 6 Fibre, 1 Resin | 14 |
| Deepened Satchel | Both previous projects and built Tannery | 20 Essence, 2 Cloth, 2 Cord, 1 Resin | 23 |
| Sela's Wayfarer Table | Recruit Sela; independent of pack projects | 30 Essence, 6 Logs, 4 Fibre | +2 at any stage |

Carry is a permanent capacity benefit, not a sellable bag or a second capacity stat. Deepened grants +9 once. Colour and material quality do not affect capacity; choose exact stock deterministically without requiring a cosmetic choice for an invisible capacity stat, while preserving consumed receipts. No active posting, paid Carry root, Leather, Ingot, Study or extra shop upgrade gate.

Sela yields 10/13/16/25 at the four stages, once. Home Storehouse stays **16 + nine × 6 = 70**, retaining its existing Noll/Halloway/Grimmond transfer owners and prerequisites. The older Tannery Keep proposal adds no new Home shelving toll or gate in this batch; its paid history remains. No reopening of the retired 16→28→40 compression.

Old satchel ranks 0/1/2/3/4/5 map respectively to no projects/Stitching/Stitching+Straps/all/all/all, capacities 8/11/14/23/23/23. Direct upgrades and research records are duplicate evidence of the highest ordinal, not additive slot grants. Preserve historical purchases without forging new old purchase history. Old completed Carry-root access adds no slots and is not refunded.

For supported higher historical capacity, freeze credit `max(0, proven old capacity excluding Sela − mapped new base capacity)`. Include previous credit in the proven total, not again afterward. Add the actual Sela passive once. Version migration once; repeated decode uses mapped entitlements/credit rather than replaying historic ranks. An active expedition retains its bound capacity/inventory until the next Home packing boundary. No moving, discarding, merging, auto-packing or selecting a tool during migration. Unknown evidence cannot authorize shrinking proven capacity or destroying items.

## 9. Progression examples and cross-shop dependencies

After Corrin's foundation:

- Woven Guard needs 6 Fibre; all three basic woven slots need **18 Fibre + 1 Resin**, 3.5 total Protection, all Fine, new nominal sale total11. No animal, Salt, Forge or pack upgrade is needed.
- Buckled Guard instead of the plain Guard makes that full outfit **22 Fibre + 1 Ingot + 1 Resin**, total Protection4.0 and nominal sale17. From raw metal this is 2 Iron + 1 Coal. It is an optional raw-to-ingot improvement, not a prerequisite for Leather or carrying.
- Complete Leather Guard/Gloves/Boots needs **4 eligible raw portions + 4 Salt + 6 Fibre + 1 Resin**. At Common p=50 throughout, Protection totals **6.75**, nominal sale21. The four portions need not share colour, subtype or measurements. Animal encounters and reward chance remain real costs; no guaranteed Hide placement is introduced.
- First two pack projects remain 15 Essence, 10 Fibre, 1 Resin, leaving25 from opening40 before other spending. All three plus Corrin's foundation remain **55 Essence, 26 Fibre, 2 Resin, 6 Logs, 4 Clay**. No changed textile matching requirement or new garment unlock adds to that arithmetic.

These are staged options, not an opening checklist. Use the actual campaign's cheapest legal next Bind quote when evaluating affordability; do not invent a universal departure cost or block purchases merely to reserve it.

**Shared producers:** Apothecary already consumes Cloth in its Salve ladder; recipe IDs, counts, standardized effects and prices do not change. Its selection must consume the complete chosen Cloth receipt, including mixed constituents, without requiring a new colour match or flattening source history. Forge consumes Cord/Cloth for tool upgrades, linings and bindings; its unchanged stats/quality roles and C formula operate on prepared units, never all their raw ancestors. This packet replaces only the older manufacturing matching requirement cited by those packets. Forge Ingot supplies the Buckled Guard. All use the same registered material IDs and actual lot owners; no parallel Tannery-only stock. Bowyer/Weaponsmith/Armoury can depend on these defined prepared outputs in their own whole-shop packets; no unnamed new facility is required here.

## 10. Transaction, migration and bounded implementation acceptance

Use the existing actual-material quote/transaction owners. Freeze exact available input allocations, manufacturing policy, output formula/value, source composition and destination; save consumption, returned refit components, item changes/output and history atomically. Stale/insufficient selection, invalid ownership or a failed save spends nothing and grants nothing. Do not create in-memory output before durable success. Full storage uses existing Waiting custody, with no discard or auto-equip. Reopen must not repeat any grant or recipe conversion.

The required new data is bounded to existing material/gear owners: constituent allocations/appearance for mixed textiles, one-source Leather manufacturing version, frozen nominal price/policy where current raw/prepared ownership lacks it, and versioned complete garment construction/family/variant. Engineering owns exact field names and codec placement. Do not claim those fields already exist, and do not build a generic materials framework or duplicate receipt registry. Existing old receipt decoding stays supported; old manufacturing provenance remains true.

Complete this **one shop batch** across producer reward price snapshots, stock/processing, all seven garment rows, knowledge/quotes, ordinary refit/recovery, trading and capacity migration. Engineering may separate code commits without treating one isolated new recipe as the finished overhaul.

Focused normal acceptance cases belong in the existing tests and one bounded native shop route, not a new Design audit suite:

| Case | Required outcome |
| --- | --- |
| 1 Skin + Salt; separately two differently sourced Hide portions | Each dresses one intact Leather; no matching-specimen gate, unchanged per-source measurements/colour |
| Mixed Stem/Leaf and four different source colours | Exact Cord/Cloth output count, preserved ordered constituents, no invented grade/species/averaged colour |
| Existing v1 Leather and textiles after migration/reload | Same owned quantity/value/appearance, valid downstream consumption and full prepared-component recovery |
| Three family menus and all seven recipe previews | No duplicate threshold fallback; exact counts, real missing ingredients, no ordinary Essence charge |
| Uniform Common and mixed Poor/Exceptional Guard; Rare accessory | 3.25/Fine, 3.75/Superior and 2.0/Superior respectively; no repeated old offset |
| Old Exceptional Smooth Skin bought then dressed; new Exceptional Hide | Old Skin6 buy→Leather4 sale; new Hide12 nominal→Leather13; no migration repricing exploit |
| New woven/Buckled/Leather trade and dismantle | C/2C exact; original prepared inputs once, no Fibre/Hide/Salt ancestors or duplicated sample |
| Refit panel and same-family remake, then repeat/reopen | One exact item, final recomputed profile, one outgoing return, no cumulative bonus or free copied components |
| Refused/stale/save-failed craft/refit; full storage | No partial spend/grant; supported Waiting custody; exact provenance survives reload |
| Old rank0–5 × Sela absent/present; duplicate old purchase evidence | Correct 12 capacities, no duplicate grants; higher credit frozen; active expedition unchanged |
| Corrin→woven garment/Carry; Forge Ingot→Buckled; Cloth→Apothecary | Same shared units consumed, no added facility/colour gate; actual next-Bind quote remains honest |

**Actual remaining gates:** implement mixed constituent selection/presentation on the existing consumers; version one-to-one dressing and actual nominal prices; complete three family/seven-variant menus and refit persistence; integrate existing Carry preservation and shared Apothecary/Forge consumption. No individual recipe approval or new source choice is required from Aimee for this first pass. Mote-on-miss/Peerless tuning and the fuller creature anatomy catalogue remain grouped existing homework, not blockers for this ordinary shop. Balance and artwork may improve after play without silently reverting accepted lifetime, identity or capacity rules.

## Shared service resolution · 6 September

The [shared equipment improvement and recovery contract](equipment-improvement-recovery-production-v1.md) now resolves this packet's ordinary-service/legacy-preservation boundary. New-policy gear uses its specified deterministic refit/remake/rebuild or fitting; it does not inherit old Reforge ranks or the unapproved +0.5 proposal. Only active components are recoverable. Unsupported old paid-credit targets keep their supported legacy services. Peerless remains a separate pending service with the existing Mote-on-miss question open; Apothecary consumables gain no equipment-refinement route. This supersedes references above to an unnamed future ordinary-service batch.

## Conditional anatomy extension — separate first-pass proposal

[Remaining creature anatomy/material uses](creature-anatomy-material-extensions-v1.md) defines optional actual Fang/Claw components, measured Membrane-to-Leather processing and a chemically qualified creature Venom alternative, where this shop owns the exact named role. Those producers/adapters are not implemented. The complete ordinary batch remains independent, including full-excursion coatings; no generic family sample satisfies a new typed source.

## Delivered checkpoint — phone323,6 September2026

Engineering reports installed source9ac7301d5f53715652fd919d9ab385595eca4c1a, tree f64adbf4c785ab303bcb231d103d33ffe9cdcc9a; delivery6007b9d531f7975cc7169ff86bcf9047daa57b39, tree baa05b4712b0dcadda82e0feb17f6ed80ec1a7dc. Persistent `/Users/aimeepepper/Documents/comfygame-worktrees/early-material-regions-v1`, branch `codex/early-material-regions-v1`. Installed22:11:17UTC, ordinarily launched22:11UTC on Aimee's iPhone16Pro,402×874/default/current ordinary configuration. Source receipts: `docs/tannery-whole-shop-implementation-2026-09-06.md` and `docs/phone-build-323-delivery-2026-09-06.md` in that worktree.

Delivered: one actual Skin/Hide+Salt→one Leather at frozen input value; new-world covering market policy2/3/6/12 with existing receipts preserved; all seven garment variants and independent Leather panels; actual component prices; same-instance free refit/remake with current attached-component recovery; ordered fibre swatches in stock/review/equipment; fractional equipment comparisons. Known Leather CMY stays visible without invented RGB. Carry and supported paid equipment credits remain. Complete Forge/Bone and the separate creature extensions are not included as complete systems.

Engineering's47 focused tests and3 distinct native routes passed, including processing, all variants/remake/reopen and equipment composition/Equip. The seven identical baseline older-version migration failures are deferred under Aimee's explicit6 September compatibility override; this is not a claim that the broader historical suite is wholly green. Current-version save/reopen and durable transaction safety remain required and passed. No campaign deletion, reset or uninstall is authorized. Design read the supplied receipts; no duplicate native/phone verification was performed.
