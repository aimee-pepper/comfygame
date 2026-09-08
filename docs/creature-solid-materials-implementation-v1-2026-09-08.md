# Solid creature materials — consolidated implementation packet

8 September2026. **Implementation-ready intended contract; not delivered or enabled.** PM assigned this consolidation of the existing Body→materials direction after356. It replaces stale source adapters in creature-body-material-rewards-production-v1.md and carries forward its physical identities, quantities, four-band quality, sale values and the existing optional Forge uses. No new organs, fluids, diets, later-shop breadth or recipe microqueue. Main3D remains Engineering’s active priority; this packet does not silently activate a broad reward catalogue.

## 1. Delivered baseline and corrections

Source81f5cc03 in combat-securing-action (installed356) supplies the inspected baseline. ModularCreatureRules freezes actual bodySurface, independent wing state/type/count, horns and other source groups. ModularCreatureGeneration.spendableProjection intentionally includes ONLY supported typed Skin/Hide and Bone. CreatureMaterialRewardRules validates that restriction, awards EarlyCovering/EarlyBone plans and then skips all generic projection fallback for modular sources. A visible chitin/shell/feather/horn therefore does not yet prove a spendable new typed reward.

Three obsolete assumptions must not re-enter implementation:

1. The primary material identity comes from saved **bodySurface**, never a new reward-time hardness/body-plan/Schiller classification. Generation already makes that declaration.
2. Modular horns live in **structure.horn**; structure.cranial excludes horns. Testing only cranialFeature==horns would make the new Horn path unreachable.
3. Feather extent/quantity uses independent **wingCount**, not legacy appendageCount, finCount, support limbs or the three visual fan pieces per wing.

The old projection’s Chitin quality pair includes Schiller and generic rewards use early rounding/six bands. Those compatibility calculations stay on old sources. The new typed Chitin pair below has been the intended hardness/protection pair since6September; implementing it here is separate from the iridescence project and changes no stored Finish values.

## 2. One frozen source and reward boundary

Add a distinct new-book creatureSolidMaterialVersion1 and species-owned solid manifest after valid modular anatomy, before placement. Nil preserves existing source behavior. Keep the current Hide/Bone materialProjection and its equality/validation intact; do not insert new families into it or change its quantity/rounding to make this extension fit.

Manifest entries carry canonical material ID, semantic source group/region IDs, supporting saved anatomy, species measurements and base quantity rule. They describe existing parts, not a new mesh or organ catalogue. Freeze a matching actual-specimen solid plan before encounter admission: source world/book/species/foe identity, species manifest, actual stable anatomy, actual measurements, source appearance assignments, frozen pre-party/pre-debug Danger, policy and any explicit ineligibility. Species and specimen must agree on structure/source identity. Do not reclassify the frozen covering when specimen measurement variation crosses an old generator threshold; variation changes measured quality, not what anatomy exists.

Malformed or contradictory newly generated source data is refused before encounter admission, never repaired after victory. A physically present but non-useful Horn is explicitly ineligible, not an invalid encounter. No new material RNG draws. No renderer, nickname, habitat label, attack type or nearby species may supply a missing body part.

## 3. Exact part mapping

| Saved source fact | Typed material | Actual quality pair | Species base quantity |
| --- | --- | --- | --- |
| bodySurface.fur | creature.pelt.fur · Fur Pelt | insulation, coverage | size band |
| bodySurface.overlappingScales | creature.scales.overlapping · Overlapping Scales | protection, coverage | size band |
| bodySurface.armouredScales | creature.scales.armoured · Armoured Scales | protection, coverage | size band |
| bodySurface.chitin | creature.chitin · Chitin | hardness, protection | size band |
| bodySurface.chitinPlate | creature.chitin.plate · Chitin Plate | hardness, protection | size band |
| bodySurface.shell | creature.shell · Shell | hardness, protection | size band |
| bodySurface.protectiveSpines | creature.spines.protective · Protective Spines | hardness, length | size band |
| nonabsent feathered wings, positive wingCount, aerial habitat and functional wingState | creature.feather.flight · Flight Feathers | wing extent, source Finish Lustre | wing quantity |
| other actual nonabsent feathered wings with positive wingCount | creature.feather.contour · Contour Feathers | wing extent, source Finish Lustre | wing quantity |
| nonabsent structure.horn, non-amorphous layout, useful Crush boundary below | creature.horn · Horn | actual Crush, boneDensity |2 if species armament total≥65, otherwise1 |

Only one primary covering row may apply. Skin delegates to existing EarlyCovering; absent covering yields none. Fur is not an additional Hide. An ordinary ridge/sail/decorative spine is not the protective-spine covering. Body, wings, useful horns and the existing skeleton can coexist as different source groups without counting the same tissue twice.

Useful Horn retains total armament≥30 and dominant Crush, with the existing stable armament dominance order. Require that boundary in species and actual specimen; if either fails, the physical horn remains visible but the new useful-Horn award is zero. A nonhorn cranial crest never qualifies. Quantities are useful material portions, not a count of literal horns; the model’s left/right horn pieces do not double the specified quantity.

Membrane wings and fins stay visible anatomy but yield no new typed sheet here: their required sheet coverage/flexibility records are absent. Down, Fang, Claw, Tusk, Oil, Venom and Ichor remain unavailable in this policy. No generic Fin/Plate/Quill token, inferred white Bone/Feather, layered Shell or automatic Pelt→Leather conversion. Those exclusions never disable an existing attack, defence, emanation or movement ability. Preserve old legitimate stock and old non-opted-in projection/reward behavior.

## 4. Exact measures and quality

All participating values must be finite0…100. Protection=hardness×coverage/100; insulation=length×coverage/100; wing extent=actual wingCount/8×100; Lustre=the owning source’s shine+Schiller under existing normalized Finish. For a source-region override, use its actual owning Finish rather than an unrelated body value. This grants no new iridescence or Lustre bonus.

Expression=(A+B)/2, unrounded. Score=floor(.75×expression+.25×savedDangerInput+.5). Danger bands0…5 map20/35/50/65/80/95. Physical bands: Poor0–24, Common25–59, Rare60–84, Exceptional85–100. Source ranks0/1/2/3 and working-role multipliers.75/1/1.25/1.5 are authoritative only in an allowed consumer. Do not feed the generic rounded partExpression back into quality or derive physical rank from the container’s six-band enum.

Size band=min(4,max(1,1+floor(species.size/25))). Wing band=min(4,max(1,ceil(species.wingCount/2))); wing quantity=clamp(floor((sizeBand+wingBand)/2+.5),1,4), only for an eligible positive wing group. Apply existing frozen Anatomy once per positive material group: q+max(1,floor(.35q)); zero remains zero. New positive solids have no70% recovery roll. Hide retains its own actual-specimen quantity,70% roll, subtype, prices and safeguards unchanged. Bone retains its separate species size/34 quantity, predicate, typed plan and source quality unchanged.

## 5. Source colour and custody

Use actual full saved CMY/Depth/Pattern and source region/part identity; do not sample a rendered pixel or choose a catalogue colour. RuntimeSurfaceRegion.Appearance and the actual specimen projection already preserve inheritance versus explicit overrides. Snapshot the corresponding biological source appearance, with parent provenance, rather than making the inventory depend on a later renderer. A colour override known only as sRGB remains explicitly sRGB-only; do not invent CMY or admit it to a consumer that needs unavailable source coordinates. Ordinary new full-source records remain fully coloured.

Repeated visual pieces do not create regions or material quantities: deduplicate the actual wing/horn owners. If a positive group has distinct actual regional appearances, distribute its total q portions across canonically ordered real region IDs with ordinal modulo region count; never q per region. Apply Anatomy to the group total first. Freeze the chosen exact region for each portion; its quality uses that region’s actual pair, including any legitimate regional Finish. Uniform-source groups remain uniform. No hidden colour averaging or source borrowing.

Extend the existing typed award pattern with a dedicated solidPart plan/award on material units and reward entries, mutually exclusive with earlyCovering/earlyBone. Its strict decoder validates exact source links, physical material, physical score/band, portion region and Anatomy. Keep any compatibility family tag only for storage routing: Pelt→pelt, Scales→scale/plate, Chitin types→chitin, Shell→shell, Protective Spines→quill, Feathers→feather, Horn→horn. That tag is never typed eligibility or a public generic name. Reuse the existing physical-to-compatibility mapping (Poor→rough, Common→standard, Rare→superior, Exceptional→exceptional) without treating it as a new grading scale.

CreatureMaterialRewardRules evaluates the typed solid branch before its existing modular-source early exit. The old Hide/Bone-only projection guard can stay. Typed solid entries validate their manifest/plan instead of searching the old projection for a family it intentionally lacks. Split a group into rows only for distinct actual region/quality lots; each row carries its portion ordinals and references the one group-total/Anatomy plan. Typed uniqueness is foe+group+region+typed material, while old rows retain foe+family uniqueness. Validate that typed rows partition the exact group ordinals without gaps or overlaps and sum to the one final group quantity; never apply Anatomy per row. This is required when different wing-region Finish produces different physical quality, because the old entry has only one scalar quality per row. New award IDs include policy, run/world, encounter, foe, source group, typed material and ordinal, under existing allocator conventions. Encounter resolution, reserve insertion and reward receipt commit atomically once; failed save leaves no published units. Replays/retries reopen the same durable result, never another roll. Escape/non-defeat and nonordinary authored reward paths gain nothing from this extension.

Return/loss protection, Storehouse, sale, buyback, selected crafting and recovery preserve exact unit/ancestor identity. Update cloning/withStableID and strict unit/receipt validators so payloads cannot fall off in any of those routes. Same canonical subtype and physical quality form one visible stack; colours, scores, region, Finish and provenance expand on tap. No exact-value stack split and no averaging of the underlying stock. Useful properties are rounded for display only; no raw IDs or debug contracts in player copy.

## 6. One complete stock and Forge consumer bundle

All newly enabled types require their actual typed reward, Return/Storehouse details and raw-material trade path together. Nominal raw sale values2/4/8/16 for Poor/Common/Rare/Exceptional; buyback/authorized buy twice sale. TradingPostRules currently special-cases only EarlyBone/EarlyCovering and otherwise uses generic family capabilities; add explicit validated solid handling before that fallback, including its buyback-price branch. Do not change Hide/Bone/legacy prices or add merchant stock.

Carry forward the existing optional Forge roles as a single maker contract update, not separate recipe adapters:

- Shield face:2 actual Shell as another whole alternative to the existing2 Bone face. Brace remains1 Log+2 Fibre OR1 Bone+2 Fibre. Every existing wood/stone/metal alternative, cost and gate remains.
- Pointed Blade/Cutting Blade short grip:1 actual Horn as another whole alternative to1 Bone. The separately selected working point/edge remains required and alone supplies Power. Horn grip has the same short-grip wrapping rule as Bone; no new fibre surcharge.
- Shell face contribution per selected portion=2×(.5+actualProtection/200)×physicalBandMultiplier. Average the two contributions, then the existing single final quarter rounding floor(4v+.5)/4. Horn supports contribute rank only, no Crush-to-Power bonus. Workmanship uses physical ranks and the maker’s existing70% working/30% support calculation; no second stat multiplier.
- EarlyForgeGearRules needs typed material requirements rather than the current bone Boolean for these alternatives, and EarlyForgeConstruction.valid must validate their exact values/ancestors instead of assuming every creature input is EarlyBone. Keep the shared EarlyMakerReceipt.Input custody intact. Material choices, quotes, complete contribution, cancellation, manufacture, refit, improvement and recycling use the same consolidated validated source adapter.

Freeze a separate Forge construction revision for new typed alternatives; existing version1 construction validation, components and final statistics stay exact. New source admission does not retroactively change an old Bone or wood recipe.

Use existing exact unit nominal values for C; finished sell=C and buy=2C under the accepted shop/service contracts. Processing adds no hidden quality/colour premium. Refit/repurpose and recycling restore only actual recoverable ancestors once; preserve existing fees, paid work and improved-work removal rules. Missing/invalid typed source refuses before spending; no generic family compatibility bridge.

Fur/Scales/Chitin uses in Armoury and Horn Collar/Weaponsmith remain the previously described **later extension, paused**, not silently enabled here. Feathers/Spines remain explicitly raw-sale-only; no writing ingredient, arrow, extra attack or promise of a future recipe. Other solids can be sold even while their later equipment roles are paused. All starter alternatives remain sufficient; no first-craft requirement now depends on finding a rare creature or reaching dark water.

## 7. Rollout and bounded evidence

Engineering schedules this as one source/material system plus its stock/trade and existing Forge bundle after current priorities; do not turn on body groups merely by adding enum names. New-book opt-in is explicit and independently frozen; preview/Bind/species/actual plans/encounter/Return/reopen share it. Old books, active encounters, saved awards and earned stock are never reprojected. No automatic backfill from a visible old creature, old generic sample or current renderer. Native runtime enablement remains a delivery milestone, not implied by this document.

Focused implementation cases: all mutually exclusive covering declarations; water Fur without Oil/Scales/Hide; independent wing counts versus limbs/fins/fan pieces; horn present with cranial absent; decorative/non-useful/amorphous horn zero; region override and ordinal allocation with unchanged group quantity; physical quality boundary before rounding; Anatomy once; old/new exact reward validation; failed save/replay; same-subtype/quality grouped stock; typed trade/buyback and whole Forge alternatives/refit/recycle without duplicating ancestors. One bounded source→reward→Return→Forge route is enough for native integration evidence; controlled sources are valid and must be labeled. No census, seed hunt, new trial, Design native rerun, phone polling or configuration matrix.

Arithmetic examples (design fixtures, not played outcomes): Chitin Plate hardness80/coverage80 gives expression72 and Danger2 score67 Rare; species size60 yields3, Anatomy4. Water Fur length60/coverage90 gives the same72/67 without Hide or Oil. Four feathered wings, size60, Lustre60 gives expression55, score54 Common, quantity3/Anatomy4 regardless of old combined appendage count. Useful Horn with actual Crush60/bone60, species total70 gives58 Common and2/Anatomy3. Pair50.4/74.8 at Danger2 gives expression62.6 and score59 Common; rounding expression63 first would incorrectly cross into Rare.

No new Aimee decision is needed for this consolidation. Natural prevalence, completed broader ecology and enjoyment still require later actual play evidence; keep the three creature homework goals open. Unsupported source anatomy and later shops remain excluded rather than becoming team-wide blockers.
