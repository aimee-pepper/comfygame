# Natural Nessa trip one: recruitment delay and remaining runway

**Measured finding and bounded continuation · 5 September 2026.** Engineering `66e744c0f7e8c9f45e431fb2222b25fd4f786482`, tree `dbdb129cd533a163e7b35017e501bc013edb6467`. Only the new natural-route evidence is in scope. This does not decide unrelated writing questions or change rewards, odds, prices, gates or generation.

## What passed, and what stopped

One normally bound blank world, seed754603960377645849, paid40→30. Six harvests returned all4Clay/4Softwood/1Resin/2Stem with zero material loss. Movement cost47 turns across44 actions; harvest6; total53/546 (9.71%). Five natural encounters required ten player Attacks; combat did not increment the world-turn counter. Binder ended24/30, Quill13/24. The route meets the existing48-movement/60%-budget targets for this trip, with little movement margin and meaningful combat activity. None of these figures establishes a typical-world rate.

The Nessa clue was auto-read during the expedition. No traveller appeared, was invited or joined. Nessa has one recorded near-miss. Her foundation and the natural Salve journey remain unproved. Stock is sufficient; recruitment is the first stopping point. The wallet is33 (40−10+3 spring yield), with no collected/refined Essence or subsidy. The next displayed blank Bind costs10, unspent; no second seed was issued.

## Recruitment: distinguish selection from appearing

Current `Worldgen` chooses the matching eligible traveller first, then makes that candidate's confidence roll, then attempts physical placement. `LibraryState.applyTravellerArrival` increments a person's near-misses only for a receipt naming that selected candidate with `confidenceFailed`; a placement failure does not increment it. Therefore the report's “no traveller selected” must distinguish **no traveller placed** from internal candidate selection. The observed first Nessa near-miss implies Nessa was selected and failed confidence under these rules; Engineering must confirm the exact saved receipt rather than infer its numeric roll.

Read the retained first-world receipt without regeneration: selected candidate, outcome, chance/roll, prior near-misses, evidence, matches/exclusions. Correct only the human report if its terminology is imprecise. If the receipt contradicts the saved increment, stop and report a persistence/selection defect; do not manufacture a receipt or clear history.

The clue arrived after the world was frozen, so it cannot change that world's choice or roll. It helps ranking on a later matching world; it neither creates habitat nor guarantees Nessa's selection. The existing chance rule is25% plus causal authored contribution and25 percentage points per prior selected near-miss; two prior selected misses make the next selected attempt certain. Thus on another blank world **if Nessa matches and is selected**, one prior miss yields50%, and a second miss would make the following selected attempt100%. These are conditional selected-attempt chances, not next-world recruitment probabilities. No retrospective placement, replacement NPC or odds change is justified by this one failed roll.

## Essence and healing are separate constraints

| Conditional budget, retaining the observed10 Bind /3 Return income only | Balance |
| --- | ---: |
| Current measured Home balance |33|
| Pay the displayed next Bind |23|
| If its eventual Return again yields3 with no other income |26|
| If Nessa then joins, pay current20 foundation |6|
| Deficit against another10 Bind, before any additional income |**4**|
| If two more10-cost/3-income trips were needed from now |19 before foundation; **11 short** of foundation plus another10 Bind |

The later rows are arithmetic scenarios, not forecasts or played outcomes. Habitat/selection delays may add more trips; a third paid trip is not necessarily a third selected Nessa attempt. The existing anti-lock floor protects departure affordability, not a20-Essence building reserve. Record any automatic subsidy as a subsidy; do not count it as earned progression income or disable it for the test. Do not assume hides/fins/XP convert to Essence.

Health is run-scoped. The normal new-Bind constructor fills Binder and companion health to their current caps; a prior expedition's injuries do not create a paid Home recovery requirement. Verify those normal full caps on next entry. This does not supply an in-world Salve or make five encounters harmless: healing still extends the current excursion, and real injury/use must remain visible. No new healing grant is needed to take the next legal Bind.

## Exact next action for Engineering

1. Preserve and read the first arrival receipt and current Home state as above. No seed issue or rewrite for diagnosis.
2. If it confirms the expected confidence miss, continue **one ordinary forward expedition** from this same saved campaign using the already displayed legal blank10 quote. Keep the clue, near-miss, stock, ordinary selection, fog and normal income. No reset, seed screening, alternate candidate search, grants or extra corpus. This is a bounded continuation after the documented stop, not permission to repeat until success.
3. Confirm actual departure health and wallet. Seek the known goal through normally visible play, noting naturally encountered Essence opportunities and their costs. Existing foundation ingredients are already banked; do not repeat the old six-harvest shopping list unnecessarily. No hidden traveller coordinates or automatic population inspection to steer play.
4. On safe Return or the next concrete stopping point, report actual traveller outcome, stock/losses, health/encounters, movement/world budget, income/subsidy and wallet. Inspect the real foundation and cheapest legal next-Bind quotes. If Nessa joins and both are affordable from actual funds, proceed through the already-authorized foundation/Salve/packing/next-Bind/use route. If recruitment still fails or the combined budget falls short, preserve the exact state and stop for a bounded Design correction; do not buy the building just to trigger a subsidy or issue another search seed.

This observation boundary is not a new player-facing purchase restriction. No tuning is adopted from the hypothetical deficit. Engineering's exact current implementation blocker takes priority over running this continuation. Public Wiki should record first-trip success, conditional recruitment and budget limits, not claim the natural Nessa route or phone release passed.

## Retained-state clarification — Engineering 61c0623f

Engineering correction `61c0623f0438aedcc3bfcb2e2550cc604ddf4bf9`, tree `44d37eafa00d266b6654277c03de35c4bb4a2c3a`, confirms post-Return Home and backup preserve no placed travellers, Nessa near-miss1, no recruits and one issued seed. The separate generation TravellerArrivalReceipt was not retained in History; exact roll and complete candidate/exclusion lists are unavailable. Do not recreate them by generating the old world. Candidate Nessa/confidence failure follow the existing near-miss invariant; first-attempt chance25% and zero prior/evidence values are rule-derived, not recovered receipt fields. Corrected wording and evidence limits close the read-only diagnosis sufficiently for the one forward continuation; missing historical diagnostics do not require a new gameplay gate.

Home/new-departure health is confirmed Binder30/30 and Quill24/24 with no paid recovery. Wallet33, next blank10 remains unspent, no recipe/item has been granted. On the authorized next run, retain its existing arrival receipt in the bounded test evidence before Return removes active diagnostics; do not build a new framework or require a save-schema change for this observation. Keep diagnostic inspection separate from the normally visible play route. All continuation, stop and no-retuning boundaries above remain in force.
