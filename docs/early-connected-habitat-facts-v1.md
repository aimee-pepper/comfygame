# Connected habitat facts and the first actual-map result

**Decided intended correction.** Evidence: Engineering`dbce306e31acc3dcad11e276013d90c6466d3517`, tree`d2c5ff8d8eeb573b6933620b58b45bf22825889d`. Current intensity weights, root-water rules and deposit behavior stay unchanged. New fact scope is for newly generated worlds; no installed-game delivery is claimed.

## What the actual sample says

The adopted-policy128-world sample uses seeds0–63 for blank and moderate-Sun inputs, with new blocking Iron/Coal. All128 terrain generations succeeded and placed sources retained reachable work positions.

| Measure | Blank, out of64 | Sun moderate, out of64 |
| --- | ---: | ---: |
| Pressure pass without shore | 16 | 23 |
| Worlds with each of Stem, Leaf, Resin and Softwood actually placed | 16 (25%) | 23 (35.9375%) |
| Old single-region fresh-growing-land / Nessa fact | 13 (20.3125%) | 18 (28.125%) |
| Old single-region fibre-growth / Corrin fact | 16 | 21 |
| Workable Iron host and placed Iron | 64 | 64 |
| Coal host and placed Coal | 58 | 58 |

These are different measures. The13/64 value does not mean only13 worlds supplied the starter plant materials. Conversely, the16/64 source-availability result does not establish the full1000-seed25% review floor. Do not pool the two authored cohorts or project a definitive success/failure from this small sample.

## Exact correction: habitat does not restart at an internal boundary

`EarlyMaterialMapRules` currently requires twelve qualifying roots inside one region to set the Nessa/Corrin world facts. Regions split on base ground, elevation and shore/root-input differences. `EarlyMaterialPlacementRules` already counts qualifying roots across the whole entry-connected area for its flora budget. The sample contains real complete source sets which the narrower recruitment predicate fails to recognize. This is a hidden region-boundary restriction, not evidence that those plants are absent.

For **fresh growing land** and **fibre growth**, aggregate **unique qualifying root cells across the entry-connected ground component**, using the exact same pre-population eligibility basis as the flora budget. Keep the threshold **12**. Internal ground, elevation, shore or geological boundaries do not reset the count. Every cell must independently pass the existing ordinary-root ecology; do not count disconnected, saline, frozen, submerged, dark or otherwise incompatible ground.

Fresh growing land also needs legal Resin-shrub and Small-Softwood sites in that connected area. Fibre growth needs legal Stem-patch and Leaf-rosette sites. Keep the existing host/occupancy/work-position checks. No extra plants are inserted to satisfy the fact. Final source and work-position reachability continues to be verified by placement. The fact is a saved generation result, not a predicate that disappears after the player harvests its sources.

The counting pass is pure: no random draw, terrain mutation, placement reroll, extra NPC, teaching or reward. Keep traveller/fact/clue identities and near-miss history. Freeze prior world facts and selected people; version the derivation for newly generated worlds rather than reinterpreting saved regions. Causal interventions apply the same scope to their own frozen candidate map facts while retaining unrelated rolls. This does not waive any actual habitat requirement.

Focused cases: two six-cell qualified regions in the same entry-connected area with required legal profiles now qualify; eleven unique cells do not; mixing six good cells with six incompatible cells does not; disconnected cells/sites do not help; missing either required profile refuses its corresponding fact; duplicates count once and old saved facts stay unchanged. Engineering must check these before the large run. New aggregate fact incidences have not been measured yet.

## Clay exceptions are real capacity, not missing eligible sources

The initial128 diagnostic failed a blanket zero-missing assertion for blank7 and Sun0/61/62. Focused regeneration proved each has one intrinsically legal Clay site and one placed Clay. The desired reservation is two; actual permitted reservation is `min(2, legal site capacity)` within the same source budget. Report the remaining one as a capacity reduction. Do not force a second deposit or charge the player for a missing placement.

This is not permission to hide an allocation bug. If an intrinsically eligible reserved site is lost to allocation, avoidable blocking or mishandled occupancy, it remains a placement failure. Count initial legal capacity separately from losses caused by population placement. The four cases passed their focused check; the revised128 assertion was not rerun, so do not call that whole revised suite passed. No terrain or allocation behavior was changed to make the diagnostic pass.

## Next bounded measurement decision

**Do not retune the intensity weights from this64-seed sample.** After the small aggregation fixtures and exact native checkpoint, run one actual **blank0–999** corpus using the adopted intensity policy, root baseline, new blocking deposits and connected habitat scope. Preserve the original25% review target. Report old single-region facts as well as new connected facts from the same generated snapshots, so the semantic correction is not hidden inside a claimed climate improvement. Report actual material hosts and placed source-world counts independently of either recruitment fact.

No second Sun1000 run, extra128 rerun, drainage change or parameter sweep is required now. Collect the original full-run result even if the tool response times out; do not start a duplicate. Keep exact generation refusals, genuine capacity reductions, lost eligible reservations and work-position reachability separate. The mounted Nessa/Return/foundation/Salve/next-Bind journey continues independently; a population percentage is not an affordability or phone-delivery receipt.

## Completed single full corpus — result supersedes the pending measurement above

Measured implementation `566755c9e822fc4094d3f9ae6daebc14002011e5`, tree `a817c987ebc7955490c760a6d37f8c0673b6e9a2`; Engineering preserved result `43273921efe0fbb2a231062826b06cc345e57880`, tree `2885c1373252586752af513648bd2bc9b03c852b`. Raw report: `docs/test-artifacts/early-material-generation-v1/connected-adopted-blank-worlds-0-999-initial.json` in the Engineering worktree. One run, 1234.196 seconds, result `test_sim_2026-09-05T03-29-31-629Z_pid44441_9ed84dc1.xcresult`. No duplicate or Sun cohort.

999 of 1,000 requested worlds generated; seed 264 refused terrain generation. All counts retain the full 1,000 denominator. Same-snapshot fresh habitat: old scope 202, connected 296 (29.6%); fibre 278 to 299. Iron placed in 997 worlds, Coal hosts in 928 and placed in 927; Resin placed in 296, Softwood 293, Stem 299, Leaf 299. Do not infer the full source-set intersection from individual material counts. The habitat review floor passes, while the overall test fails the reservation assertion. All final placed-source work positions are reachable.

Diagnose exactly Softwood seeds 174, 505, 548, 900, 909 and Coal 811. Their legal-site counts alone do not establish final capacity. Preserve distinctions between intrinsically insufficient capacity, protected-route constraints and prior placements consuming a usable reserved site. Twenty-two separate Clay cases have one legal site against two requested and are confirmed capacity reductions. Do not classify the six unresolved cases the same way without evidence. Diagnose terrain 264 separately; do not assume it is inherited from the earlier generator without comparison.

**Disposition:** keep the adopted intensity weights, root ecology, connected scope and protected routes. No new full-corpus run is required for this diagnosis; use the six exact cases. No free stock, forced incompatible source or hidden route obstruction is authorized. Source availability and natural journey pacing remain separate from the passed habitat floor. This report does not approve cutover or phone release.

The arranged native Nessa route now completes six gathers, invitation, Return, foundation, preparation, packing, actual next Bind and carried Salve use. Native use was on full-health You and proved dispatch, consumption and turn one; a separate controlled injured test proved heal 10 and durable refusal/retry. This establishes connected consumers, not naturally generated pacing. The gameplay gate remains off and phone build 306 is unchanged at this receipt.
