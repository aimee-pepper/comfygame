# Plant support and foliage proportions — accepted intended revision

8 September 2026. **ACCEPTED INTENDED — installed355 with verified implementation and matched examples; final Aimee visual acceptance pending.** PM explicitly relayed her instruction to implement this plant revision and show the comparisons. The exact listed ratios, scope and preservation boundaries are accepted for bounded implementation. Ratios were authored by Design, not measured from screenshots; final appearance still requires review. This acceptance is separate from the unresolved universal-Schiller/plant-numerousness reconsideration.

## Accepted direction and tradeoff

Adopt one arrangement-aware revision: make leaf-bearing unbranched fibrous stems slimmer, let more of their existing leaf length show, give basal rosettes a compact central support, and let fleshy branches emerge from the actual outside of their body before carrying their foliage. Preserve already-readable branched woody/fibrous forms.

This should make stalks, basal leaf clusters and swollen fleshy bodies distinguishable at ordinary map scale. The tradeoff is a shorter silhouette for basal fibrous rosettes and a broader visible footprint for branched fleshy plants. A fleshy body remains visibly substantial; rear foliage may still be occluded. Neither every individual leaf nor all hidden contacts must become visible. Existing books retain their appearance. This revision does not change plant abundance, harvesting or crafting value.

## Evidence and cause

Delivered baseline: Engineering source `af172dd5e747950afd314144d015b8d7ec872bad`, phone354. Design inspected the actual builder and four existing close/ordinary PNGs; no new capture, native run, world search or parameter sweep. Asset advised from its already-reviewed blade/needle/frond images.

- [Current dimensions and family support rules](/Users/aimeepepper/Documents/comfygame-worktrees/frond-component/Sources/Rules/ModularFloraFormV2.swift:52): fibrous support height is0.75h and width2r. [Growth dimensions](/Users/aimeepepper/Documents/comfygame-worktrees/frond-component/Sources/Rules/ModularFloraFormV2.swift:91) additionally cap most leaves at0.25h and0.40c. The retained unbranched blade forms therefore have a tall, thick support relative to short foliage. [Opposed ordinary view](/Users/aimeepepper/Documents/comfygame-worktrees/frond-component/docs/test-artifacts/fibrous-blade-component-v1/blender-blade-opposed-ordinary-scale.png) and [basal-rosette close view](/Users/aimeepepper/Documents/comfygame-worktrees/frond-component/docs/test-artifacts/fibrous-blade-component-v1/blender-blade-rosette-close.png) show the different compositions; merely moving basal leaves upward would erase their arrangement.
- Fleshy support is an ellipsoid of height h and width1.5c, while [branches currently begin on its centreline](/Users/aimeepepper/Documents/comfygame-worktrees/frond-component/Sources/Rules/ModularFloraFormV2.swift:70) and extend only0.55c radially. Their foliage occupies the terminal30% of that branch. The branch span can therefore remain within the central mass. This code explains a real burial mechanism; the screenshots alone could not distinguish it from camera-only overlap. [Frond close view](/Users/aimeepepper/Documents/comfygame-worktrees/frond-component/docs/test-artifacts/frond-component/fleshy-close.png) and [ordinary view](/Users/aimeepepper/Documents/comfygame-worktrees/frond-component/docs/test-artifacts/frond-component/fleshy-ordinary-scale.png) expose only fragments.
- Asset receipts `fibrous-blade-blender-native-review-2026-09-07.md`, `needle-blender-native-review-2026-09-08.md` and `frond-blender-native-review-2026-09-08.md` in woody-components-blender-v1 pass the component replacements while explicitly leaving whole-plant readability open. Branched woody/fibrous needle/frond fans already read adequately in that bounded evidence, so this revision leaves them alone.

Current v2 explicitly preserves these dimensions/roots. These accepted changes are a new morphology decision, not a claim Engineering violated the component contracts.

## Exact accepted scope

Keep the current source-derived h=0.12+2.38×stature/100, r=0.025+0.075×largest actual tissue/100 and c=0.12+0.43×stature/100. Let S be the already-saved leafLength. Eligible leafy growth is the existing blade/broad/needle/frond set. No new family or growth type is introduced.

| Existing form | Accepted mapping | Purpose |
| --- | --- | --- |
| Fibrous, no branches, leafy growth, alternate/opposed/whorled | Keep support height0.75h; reduce support width from2r to1.25r. Use L=min(S,0.35h,0.65c), replacing min(S,0.25h,0.40c). | Preserve tall-stalk stature while reducing support dominance and exposing more of the already-declared leaf length. |
| Fibrous, no branches, leafy growth, basal rosette | Same width/L rule, but support height0.20h. Place the basal roots at0.10 of that new support height. | A compact basal leaf cluster with a short central support; leaves remain basal. |
| Fleshy, sparse/repeated branches, leafy growth | Keep body height/width, branch dimensions, azimuths and existing ordered root heights. Start each branch at the actual outer support surface at that height/azimuth; use its existing branch span outside that surface. Keep growth on the terminal30% of that external span. | Expose existing branches and their foliage without shrinking the fleshy body or inflating leaves to escape it. |
| Fleshy, no branches, non-rosette leafy growth | Keep body/growth dimensions and the0.55h root zone. Seat each growth base on the actual outer support at its existing arrangement azimuth, with its direction pointing outward. | Avoid placing an entire short leaf group at the centre of a large body. |

For affected unbranched fibrous plants, also seat each growth base on the actual support surface: retain the upper30% zone for non-rosettes and the new basal height for rosettes. Keep the existing azimuth order, opposed partner grouping, tilt magnitude and cohort assignment; use the already-corrected outward rotation convention so moving the root to the surface cannot send its leaf inward. Surface seating uses the evaluated geometry in the support frame with a small0.001h inward overlap, not a screen-space offset or detached ring.

Fleshy branch roots use the same existing heights/azimuths but an actual radial surface intersection. Preserve the branch's current outward delta, length/rise and angle after translating its base; this makes its existing length external, rather than adding a second branch segment. Contact, displayed geometry, child roots and bounds must use the same evaluated result. If a real source fails contact admission, report that source; do not silently draw unattached foliage.

**Explicitly unchanged:** branched fibrous forms; all woody, fungal and chemical forms; growth-absent forms; already-corrected unbranched fleshy rosettes. Fleshy leafy forms keep their existing growth length caps. Growth widths/thicknesses remain the existing type ratios/values, and cohort factors remain0.80/1/0.90. Only the scoped unbranched fibrous L changes. Reuse the approved Blender meshes and current UV/Pattern/source-colour rules; no new artwork batch is needed for this revision.

Stature continues to scale the support within each affected arrangement. Tissue still controls girth through r; saved leaf length remains an upper bound. Basal forms become shorter relative to upright forms, which is an explicitly accepted silhouette change. No source trait is rewritten to justify that change.

## Retained example for the accepted comparison

For the existing ID7/seed42, stature80, dominant tissue70, saved leafLength0.30 fixture: h=2.024, r=0.0775, c=0.464.

| Fibrous measurement | Current | Accepted |
| --- | ---: | ---: |
| Support width | 0.155 | 0.096875 |
| Unbranched blade length before cohort scaling | 0.1856 | 0.30 |
| Upright opposed support height | 1.518 | 1.518 |
| Basal-rosette support height | 1.518 | 0.4048 |
| Basal-rosette root height | 0.2024 | 0.04048 |

For the same fleshy source, body width remains0.696 and branch radial span remains0.2552. The proposed difference is that the span begins at the outside of the body instead of the centreline. These are arithmetic consequences of the single proposal, not newly rendered or visually accepted results. The saved0.30 leaf limit remains intact.

## Preservation and acceptance boundary

All family/growth/branch/arrangement choices, source counts, anatomy, tissue quantities, defence/thorns, displays, identity, colours, Pattern, Finish, harvest eligibility, yields, quality, costs, growth blocking and one-resource-per-tile rules remain unchanged. Recompute existing display/thorn attachments against the resulting support/growth using their current source-owned rules; do not add a stalk, leaf, branch, fruit or resource. Visual overhang creates no new occupied tile, target or reach. Keep current64-part/128-instance/128-socket/16,384-triangle limits and existing geometry bounds policy; never prune source members to fit.

For this accepted implementation, Engineering supplies a separately frozen flora-only morphology path for newly bound books; do not reinterpret saved form2/component5 recipes or change creature forms. Component meshes and surface2 remain independently versioned. Preview, actual preparation, memory and reopen must share the selected path. Existing books and unfinished saved expeditions keep their exact old geometry.

Validate this as one coherent revision using the retained opposed/basal blade and fleshy needle/frond sources, plus focused existing source/contact/persistence checks. Preserve a same-source comparison at the actual target/default/current appearance; do not run a world census, parameter sweep, configuration matrix or repeated component microbatch. The intended acceptance is a recognizable foliage-bearing upright plant, a recognizable basal rosette, and fleshy branch fans emerging outside the body with seated visible joins. Natural rear occlusion is allowed. Correct counts alone do not pass visual readability, and an image alone does not pass hidden contact. The already-readable branched woody/fibrous recipe fields should remain unchanged.

## Direct approval and required examples

Aimee explicitly instructed: “implement the plant generation revision you mentioned and show me the examples when comparing them.” PM relayed that approval after reading the full contract and assigned Engineering the exact scope. The original proposal-only status is superseded. Implement the listed revision and show matched same-source before/after close and ordinary-scale examples; preserve the actual target/default/current appearance and source facts. Do not replace those examples with a source-count-only receipt. No duplicate Design native run is requested.

Approval authorizes this bounded implementation, not materially different ratios, additional families or accepted final visuals. Installed355 delivers this revision; internal verification and delivery are recorded below. Phone-launch confirmation is never a production dependency. The universal-Schiller/numerousness recommendation remains a separate unsettled design task.

## Implementation receipt — delivered in phone355

Engineering candidate3f386c725d40332875af1dc777f2791ff4fdcce8/tree f1a8f1113b55e24e3f0f6cfac8212a2e128294c2, plant-foliage-generation worktree, records the exact revision in `docs/plant-foliage-generation-implementation-2026-09-08.md`. Five focused checks pass, including actual Bind/Enter/native movement/cold reopen, old/new source preservation, observed changed-plant memory, scoped contact/exclusions and matched captures. Independent floraMorphologyVersion1 freezes new-book geometry; nil old geometry, creature form2/component5/surface2 remain unchanged.

Asset13b5fdd5 reviewed the same eight comparisons: clearer upright foliage, compact basal clusters and external fleshy fans with seated visible joins; rear occlusion and fine map-scale limits remain. Actual capture device is Engineering iPhone17Pro Simulator/iOS26.2 at402×874pt/default/current dark, matching target viewport; no duplicate Design capture. PM has all eight BEFORE LEFT / AFTER RIGHT images for Aimee. This is internal verification, not her final visual acceptance. Phone355 installation is confirmed by the following receipt; no launch dependency.

### Phone355 installation complete

Engineering delivery77d3ccc904fddd6ffabddbb79b04d0b133d0b99b, receipt `docs/phone-355-installation-2026-09-08.md` in plant-foliage-generation: installed/read back2026-09-08T14:07:39.637060Z on Aimee’s physical iPhone16Pro. ArtifactSHA e041d69be247e37a9a5de0bc18dc2bcc2a1510ed18cb26e5fdb83a855fe91695. No launch attempted, campaign interaction or reset; usable entry remains unverified and is not a production dependency. New books receive the scoped revision, nil old books remain exact. Final Aimee visual acceptance and Schiller/count proposals remain separate.

## New direct correction — believable supports

Aimee prefers355 foliage but rejects generic egg stalks. [Believable supports v2](plant-believable-supports-v2-2026-09-08.md) is the accepted next mapping; old355 geometry remains for old books. The prior unchanged-fleshy-body boundary is superseded only for this new version. [Current execution sequence](accepted-work-sequence-2026-09-08.md) keeps independent accepted work moving.
