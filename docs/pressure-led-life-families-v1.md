# Pressure-led life families v1

7 September2026. **Aimee accepted the lightweight taxonomy recommendation and authorized proceeding. Implementation d3b7b79f source-reviewed against this contract; installed351, phone entry unverified.** Exact weights below are Design-authored first-pass tuning. Public player authority: the Pressure-led families section in `player-wiki-design-decisions-current.md`, published0fdb875b. This contract extends generation after the current morphology corrections; it does not roll them back or require a new Asset family.

## Product scope and meaning

Use a small family → species → individual hierarchy. World pressures and actual habitat/host support influence family probabilities; family structure supplies a coherent foundation while species retain independent parts, dimensions and source traits. Similar worlds can contain different compatible mixtures. Repeated families remain possible. No complete-eight-rank taxonomy, ancestry/phylogeny claims, breeding, editor, fixed Earth-animal catalogue or new simulation is required.

Family means **construction family**, not habitat, behaviour, chemistry, reward or a new discovery identity. Begin with existing six creature layouts and five flora families; no extra subfamily layer is required. The family labels are shared structural categories across worlds, not a claim that two generated worlds share ancestors or species. This improves composition and authoring scale; it does not increase cast size, placed population, map size or renderer budgets. Numerical combination counts are not a quality target.

| Layer | Creature authority | Flora authority | Persistence/disclosure |
| --- | --- | --- | --- |
| Family | Axial, elongated, segmented, radial, amorphous, piscine; existing layout compatibility and builder | Woody, fibrous, fleshy, fungal, chemical; actual metabolism/tissue and compatible builder | Freeze the chosen actual structural family with generation; no hidden-family population listing |
| Species/kind | Existing world/species ID and finalized habitat, anatomy, gameplay traits and source regions | Existing world/flora ID, metabolism/tissue, habit, structural groups and source links | One existing canonical identity; names and role labels remain derived, not identity keys |
| Individual/source | Existing saved specimen variation, instance ID, position and real rewards | Existing patches of the shared kind plus any already supported exact source-owned variants | No newly invented per-tile biology, new individual roll or borrowing another source's colour |

Keep Sky/Water/Amphibious/Land Bestiary navigation and current body subgroups. One family may occur in several permitted habitats, and a habitat contains several families. Axial2/4/many-legged grouping still reads real limb count. No extra bookshelf depth, locked silhouettes, unseen totals, read fee or new discovery/Seen prerequisite follows. Existing earned knowledge remains intact.

## Current source and the bounded changes

Inspected Engineering consumers in early-material-regions-v1: `ModularCreatureGeneration.swift`, `ModularCreatureRules.swift`, `LifeRules.swift`, `FloraRules.swift`, `ModularFloraRules.swift`. Current creature cast selects supported habitat, samples pressure-budgeted gameplay traits, then uses a fixed habitat/layout row before independent anatomy. Current flora samples pressure-biased tissue mix and viable metabolism, allocates traits, then derives construction family from final metabolism/dominant tissue. These are source findings, not new phone verification.

New-policy changes are only: creature family weights read the already-resolved species traits; both casts discourage excessive family repetition; flora makes its family choice before allocation and constructs a matching tissue mix. Independent group builders, family contact corrections, silhouettes, rewards and source custody retain their actual owners. Do not make the renderer pick a different family or reapply pressure transformations.

### Common probability and identity rules

Stable family order for arithmetic/draws is creature `[axial, elongated, segmented, radial, amorphous, piscine]` and flora `[woody, fibrous, fleshy, fungal, chemical]`. Map existing enums explicitly if their declaration order differs. A zero habitat/viability weight stays zero. Require finite nonnegative weights and positive total for an available selection. Negative/nonfinite input refuses new-policy preparation through the existing failure owner; it is not a reason to choose random life. No viable flora means no generated flora, retaining the current count/refusal rules.

First-pass repetition factor `R(n) = pow(0.80, min(n,4))`, where n is the number of previously accepted species of that construction family in this one cast. Creature and flora counts are separate. Counts are temporary generation state, reset for each new world, not influenced by exploration, prior worlds, Bestiary discovery or rendering. Increment only after that species is successfully constructed/validated. The floor0.4096 retains common families instead of forcing novelty. No minimum distinct-family count, quota, retry-until-different loop, extra species slot or replacement of a successful kind.

Use new-policy domain-separated family RNG streams from world seed and stable species slot, separate animal/flora salts and independent anatomy/appearance/action streams. Family selection must not consume combat/loot/action RNG. Engineering chooses the existing stable derivation utility; store policy version, selected final family and the actual finalized source, not a seed-only promise that future code will reproduce it. Preview and authoritative preparation must use the same policy/seed/slot order. No dependence on dictionary iteration, current time or scene load order.

## Creatures — retain the allocator, improve family selection

1. Keep final physical habitat availability,338 access/scenery exclusions and current slot count/placement rules. Aimee explicitly permits dark-water aquatic spawns outside current player reach, with approach to shallow contact only when their actual detection/behaviour calls for it. Preserve lawful remote components; family eligibility must not demand every animal be immediately reachable or every aquatic component have a contact route. Select habitat through the existing `habitatWeight` and habitat repetition factor0.65, preserving the first contact-eligible slot. That habitat-diversity owner is separate from family repetition; do not apply either twice.
2. Run the existing `sampleGameplayTraits` once with `WorldTendencies(readings:, modularCounts:true)`. Retain its budget, defence branch, costly allocation and free-axis ownership. This provisional allocation precedes final family selection so a chosen family never grants free stats. The player-facing broad-to-specific hierarchy is a construction model, not a demand to resample traits until an early label fits.
3. Set `B = traits.build / 100`, `C = (traits.covering.hardness / 100) * (traits.covering.coverage / 100)` from validated resolved values. B and C are shape/covering signals, not skeleton, immunity or material-entitlement deductions.
4. For each layout, weight = existing habitat/layout base × coherence factor below ×R(family count). Existing base zeros remain exclusions. These mild factors range1…1.4; normalize the final positive choices for the single draw. No raw cold/wind/mineral bonus is applied again: the allocated values already carry those pressures.

| Family | First-pass coherence factor | Visual rationale, not a biological gate |
| --- | --- | --- |
| Axial | 1+0.4B | Broad supported torso expression |
| Elongated | 1+0.4(1−B) | Slender sinuous expression |
| Segmented | 1+0.4C | More articulated hard-covered expression |
| Radial | 1+0.2B+0.2C | Broad radial covered expression |
| Amorphous | 1+0.4(1−C) | Softly expressed connected mass |
| Piscine | 1+0.4(1−B) | Tapered/sinuous swimming form, only in its already-supported habitats |

These factors bias structural interpretation without changing the sampled build/covering or establishing recoverable tissue by label. They do not grant a skeleton to amorphous life, fur to every cold-world animal, flight from wind, water access from rain, or Apex from size. Current actual source/material rules still resolve after the finalized anatomy, so future material frequency may change and must pass the relevant source checks.

5. Pass the selected layout to the real new-policy structure constructor. Do not enable production through `_layoutForTesting`; provide the ordinary validated selection path. Freeze independent limbs/wings/fins/horns/cranial/spine/tail, proportions, colour and Pattern as before. Preserve the existing conditional cold-water count owner exactly once. Family constraints remain those of the current accepted structure; no new blanket prohibition on unusual compatible combinations.
6. Resolve actual body surface/material regions, supported spendable projection, names, assembly and placement from the final source, once. Validate then increment family count. Do not draw another family to rescue invalid geometry or an inconvenient material result. Report the exact source conflict through PM/Design.

This keeps same-family species different: limb counts, wing states/types, fins, horn shape/direction, spine and covering coexistence, tails, source dimensions and coloration remain independent within their real compatibility rules. Rendering refinements stay a separate appearance revision. Existing specimen variation is retained rather than replaced by family defaults.

## Flora — select a supported family before spending tissue

Retain `GrowingConditions`, cast-size calculation, metabolism viability floor, actual source/host placement exclusions, existing tissue cost and total budget. Metabolism weights describe potential supported life; they do not prove a tile has its required host. Final placement and resource reservation still validate actual physical facts. Do not reorder map generation merely to invent an early placement proof.

For one species slot, let `Mphoto`, `Mfungal`, `Mchemical` be the existing admitted metabolism weights (absent means zero). Let `t_i=max(0.05, world.free.tissueMix[i])` for the three tissues, `T=sum(t)`. Reject nonfinite input before clamping. Construct these weights:

| Family | Base family weight before R |
| --- | --- |
| Woody | Mphoto×t_woody/T |
| Fibrous | Mphoto×t_fibrous/T |
| Fleshy | Mphoto×t_fleshy/T |
| Fungal | Mfungal |
| Chemical | Mchemical |

Multiply each by its ownR and draw once. Before repetition weighting, the three photosynthetic rows sum to exactly Mphoto: listing three photosynthetic families must not triple that metabolism's opportunity. No generic photosynthetic fallback in a lightless unsupported world. A world can remain dominated by one supported family; the policy does not promise every family or a mandatory mixed ecosystem.

Set metabolism from the chosen family. Sample the existing three tissue jitters once: `m_i=max(0.05,t_i+j_i)`, `j_i∈[−0.4,+0.4]`. For a chosen photosynthetic family only, ensure its actual corresponding tissue is dominant by `m_chosen=max(m_chosen,max(m_other1,m_other2)+0.05)`. Leave the other two raw proportions unchanged, then let existing `Tissue.setTotal` normalize the mix when spending. This is a minimal construction constraint, not another pressure multiplier, fixed tissue percentage or post-allocation overwrite. Rare families can therefore express mixtures close to a boundary instead of turning every member into a pure tissue template. Fungal/chemical families keep the sampled mix without a dominant-tissue constraint because their actual metabolism owns their construction family.

Run the existing costly allocator and free axes once with the chosen mix/metabolism. No second metabolism draw or extra tissue budget. Verify the resulting actual `ModularFloraRules.family(for: traits)` matches the selected family before freezing structure and creating source/material records. If a later allocator step contradicts that source, refuse/report the exact case rather than relabel the renderer or reroll a kind. Existing minimum tissue, stature, defence gates and timing remain. Independent branching/growth/arrangement/display/surface choices use the accepted family grammar, including corrected fleshy rosette direction and current display attachment ownership.

**Explicit supersession for this new policy only:** the older flora contract derives family without a separate family draw. Here the pressure-weighted family choice happens first, but final metabolism/tissue must still substantiate it. Legacy policy keeps its exact old sampling path, tie behavior and saved outputs. The sentence 'no role decided in advance' still applies to gameplay roles and legacy generation; the new construction-family choice is not a Grazer/Healer/medicinal/hostile-role assignment.

Fungal caps, chemical plates, visible blossoms, thorn shapes and swollen tissue create no new edible part, Oil, medicine or harvest count. Final actual tissue proportions may affect existing yielded-material properties through their current owner, so provenance must use those actual values. No family defaults may overwrite wood/foliage/source colours or quantities.

## Save, progression and cross-system boundaries

Use a new optional world-generation policy field, proposed `lifeFamilyVersion=1`; nil keeps the current path. It is separate from `modularFormVersion` and recipe wire format. Carry it through book preview/authoritative bind preparation, frozen world provenance and resume. Existing templates/books/worlds and unfinished opening continuations retain their established policy unless the existing explicit new-book workflow actually creates a new-policy book; never retrofit a saved world on load. Do not infer this flag from an app version or an appearance revision.

Existing final structure already records creature layout/flora family. Reuse those facts; a new redundant public family-ID registry is unnecessary. Reopening must not reweight or repartition a species when siblings are missing/pruned, nor recalculate source colours or old rewards. Species IDs and discovery keys stay the existing actual world/species identity. If future tuning changes selection, bump the new generation policy rather than silently reroll old recipes. Preview cannot promise a family roster based on a different seed or on uncommitted variants.

Leave fixed terrain/scenery rules, one-resource-per-tile, source custodians, traveler/lesson progression and explicit opening reserves authoritative. A family selection cannot manufacture a host, put an animal on excluded scenery, remove mandatory obtainable materials, convert scenery to a source or force an extra species to fill a checklist. Use the existing consolidated required-source/route validation before commit/spend. A new-policy preparation failure stays atomic and goes through the established failure owner; no paid retry or loss of earned stock. Exact generated source distributions may change in new worlds, so Engineering must run the existing relevant admission/custody checks; this is not a promise that every material is now available.

Food, nesting, weather-response simulation and missing anatomical resource consumers retain their separate status. Taxonomy supplies structure, not those missing mechanisms. Bestiary known-specimen measurements, actual Apex, harmful-growth warning, source-colour crafting and discovery disclosures remain unchanged. Any display family explanation uses only a legitimately known current record, not hidden cast membership.

## Bounded implementation and acceptance

Engineering owns one consolidated policy change covering both casts, source finalization, save/version routing and required-source interactions. Finish the current morphology correctness/delivery checkpoint independently; PM places this generation batch against surface/readability priorities. Asset uses the existing approved family builders; no speculative new family art or native consumer is assigned here.

Meaningful focused checks, using existing generation/structure tests:

- Existing habitat/viability zeros remain zero; a rainy world without certified liquid gains no aquatic route. Zero viable metabolism yields no fabricated flora. Nonfinite weights refuse before spending.
- Same family weights and stable supplied draw thresholds yield multiple compatible families; repeated-family factor bottoms at0.4096 and never forces every family. Test arithmetic/branch boundaries, not a statistical seed corpus or a required entropy score.
- Resolved creature traits/allocator budget match their one allocation; only family selection changes. Independent legal appendage combinations/counts remain intact and no family status creates materials/Apex.
- Photosynthetic family weights sum to the old metabolism weight before repetition; each chosen photosynthetic family yields matching actual dominant tissue with unchanged total-cost accounting. Fungal/chemical cannot gain photosynthetic parts or rewards.
- Preview/new-world preparation and reopen retain identical policy/source/assembly/colours; legacy books/worlds and opening continuations do not enter the new path. Actual first material/source routes remain possible and selected units retain provenance.
- Reuse existing per-family geometry/contact evidence unless generation exposes a concrete new combination failure. One existing ordinary native entry/movement/reopen route can establish integration when enabled; report the families/harvests actually seen, without searching worlds to fill categories. No new player trial, full-map expedition, performance/cast-size promise or Design native/phone/deployment recheck.

First-pass weights are tunable, not a claim of measured diversity improvement. Review actual authored family mixtures and natural player experience when available; do not postpone implementation for a broad research/census project. New structural or material conflicts route to Design, and any failure needing Aimee's engagement routes to PM, not to this intermittently monitored chat.

## Fibrous whole-plant readability — unresolved design concern

Carry Asset7dfa2185’s opposed/rosette fibrous finding alongside this consolidated work: current support dominates ordinary-scale foliage despite a correct blade replacement. The existing policy here changes family selection and does not prescribe a support/foliage proportion correction. Current morphology explicitly preserves those dimensions. See `blender-flora-components-v1.md` and `procedural-life-form-batch-v2.md`; any proportion or trait-to-shape adjustment is a proposed separately specified morphology revision, not an implicit change to this accepted policy. Do not block accepted component rollout, silently enlarge art, or add a component microbatch/native rerun.

## Design semantic review — implementation d3b7b79f

Reviewed the actual consolidated diff in pressure-led-life-families against this contract, including `LifeFamilyRules`, creature cast/freeze, `Worldgen`, shared bound-book policy, decoding/arrival copies and focused tests. No contract mismatch found in this bounded review. Explicit stable family arrays map existing habitat base rows correctly; factors and0.80 repetition floor match the specified formula, zero choices remain excluded, and distinct animal/flora slot streams isolate selection. Creature traits allocate once before production `selectedLayout`; counts advance only after valid material/assembly construction. Flora partitions photosynthetic mass, applies exactly three tissue jitters and minimal dominance before one allocation/free-axis pass, validates actual family, and freezes structure/assembly without later overwriting it. Apothecary profile assignment adds only the profile and does not alter those source traits.

New books carry optional `lifeFamilyVersion1` through the shared preparation policy and arrival copy. Nil keeps the old generation branch, unsupported versions refuse, and existing saved structures remain actual facts. Existing cast sizes, geometry/proportions, required-source/placement owners and resource rules remain unchanged. Engineering’s supplied nine distinct focused checks include weight boundaries, one-allocation replay, no-life/remote-water cases, saved-source custody and actual Bind→Enter→step→cold reopen. No Design native rerun was performed.

The retained saved mixture was axial/piscine/elongated/amorphous and fungal/fungal; these are source facts, not a visual diversity sample or a promised distribution. No harvest occurred on that route. Engineering corrected the supposed negative counter observation: the display reads `~532` (an approximation), not minus532, as confirmed against WorldDurationPresentation.status in WorldView.swift. No negative-counter bug was established and no code or budget change is needed. Actual internal capture device was iPhone17Pro at the target-matching402×874/default/current-dark viewport. The351 receipt below establishes installation; usable phone entry remains unverified. Fibrous whole-plant proportions/readability remain unresolved; no semantic-review PASS closes them or authorizes a silent adjustment.

## Phone351 installation — entry verification pending

Engineering receipt `docs/phone-351-installation-2026-09-07.md` in pressure-led-life-families, delivery HEADcd9e480b, establishes physical installation/readback at2026-09-08T05:10:19.073592Z for source `d3b7b79f3dccd889cd21d29d6c2029a89f5ee10b`. New books use lifeFamilyVersion1 alongside the preserved350 artwork policy; legacy nil books keep their original generation. Nine distinct focused checks and the bounded Design semantic review apply. No change to anatomy, proportions, cast size or material rights, and no measured diversity claim.

No ordinary launch retry was made following350’s locked-phone refusal, per PM instruction. Phone entry and Aimee playtest readiness remain unverified; PM owns follow-up. No gameplay/reset/uninstall/progress edits or duplicate Design verification. Fibrous whole-plant readability remains unresolved. The earlier pixel-font counter misreading is corrected above and is not an outstanding defect.
