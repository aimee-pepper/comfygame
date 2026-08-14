# Essence Spring progression — concise review batch

**Status:** accepted reversible playtest profile under Decision 186; implementation queued  
**Priority:** implement after the active opening-economy checkpoint; baseline Essence continuation
remains independently playable/testable.  
**Does not include:** new currencies, offline income, altered world drops or tutorial work.

## Why this needed one decision batch

Aimee requested unlockable Essence-refining skills because Raw Essence should develop beyond one
flat opening conversion. The first proposal has the right long-campaign direction but two structural
problems:

1. refining currently lives in the Workshop even though the Essence Spring already owns return
   Essence and unlearning; and
2. **Measured batches** charges for a quantity selector, encouraging players to hoard Raw until the
   later 3:1 rate rather than use the opening continuation loop.

The following pair keeps multiple meaningful upgrades without selling basic transaction control.
Game Design has promoted it as one reversible playtest profile under Aimee's standing permission to
make placeholder decisions that unblock work. Exact thresholds/costs remain DEBUG-tunable and the
profile does not claim final economy approval.

## Decision 1 — make the Essence Spring the single Essence hub

Move the existing raw→refined action from Workshop to Essence Spring. The Spring then owns:

- selected/all Raw refinement;
- return dividend and **Deepen the Spring**;
- refining research and Continuous settling;
- full combat-tree unlearning/respec.

Workshop remains writing/research infrastructure. Storehouse directions and every other player-facing
reference update atomically; no screen says both places refine. Existing Raw/refined quantities,
transaction behavior, completed stable node IDs and Spring tier remain exact.

`deepen_spring` becomes a Spring-root sibling and stops requiring unrelated `shelving_one`. Existing
completion migrates without repayment or relock.

### Why

This is clearer fiction and navigation. A dedicated restorative Essence place can visibly deepen,
settle, refine and unmake learned patterns; a generic Workshop should not secretly own the campaign's
central currency conversion because that happened to be its first implementation screen.

## Decision 2 — baseline quantity control; practice-earned efficiency

Use this small graph:

```text
Spring tier 0: Refine selected / Refine all at 2:1
        │
        └── Second pass: 3:1
                    │
                    └── Continuous settling: auto-refine newly retained Raw

Deepen the Spring: parallel return-dividend branch
```

### Baseline

Quantity selection, **Refine selected**, **Refine all**, before/after preview and atomic cancel/stale
handling are free baseline controls. Retire **Measured batches** rather than charging 20 Essence +
4 Pulp for permission to avoid an all-or-nothing conversion.

### Second pass

- requirement: **50 lifetime Raw Essence refined** plus **80 Essence + 10 Quartz**;
- effect: future ordinary refinement changes from 2→3 Essence per Raw;
- lifetime practice increments only on committed conversions and never decreases;
- old saves begin practice at zero unless exact receipts prove otherwise; do not infer history from
  current currency;
- held Raw benefits after purchase; past conversions are never recomputed.

The values are DEBUG-tunable. The practice gate makes actual baseline use—not hoarding—the route to
efficiency. Fifty Raw is roughly three to four well-explored Recommended worlds; the Essence price
then takes roughly five to six future such worlds to repay before Quartz opportunity cost.

### Continuous settling

Keep the current provisional **120 Essence + 12 Quartz + 8 Pulp**, Second-pass prerequisite and
Spring-tier-1 gate. Its toggle automatically refines only Raw retained by a new committed outcome,
once per `ExpeditionOutcomeID`, at the active rate. Existing stored Raw remains untouched. This is
convenience, not extra yield.

### Deepen the Spring

Keep it parallel and distinct: it increases the small return dividend, not refinement rate or
practice. Its existing exact tuning remains reviewable after baseline telemetry.

## What is deliberately not added

- no filler +5% node or fractional hidden remainder;
- no 4:1 late node before 3:1 economy evidence exists;
- no Raw Essence alternate use invented solely to justify a quantity selector;
- no retroactive refund guessed from current holdings;
- no requirement that baseline drop rates fail until research repairs them.

If play later shows a missing tier, add a new meaningful operation or tradeoff—not another box for
visual symmetry.

## Later playtest questions

1. Does the 50-lifetime-Raw gate arrive after enough baseline use without becoming bookkeeping?
2. Does 80 Essence + 10 Quartz make 3:1 feel earned without teaching another long hoard?
3. Does Continuous settling remove late-game repetition without obscuring what returned and what was
   converted?

## Acceptance for the playtest profile

1. Fresh save can refine an exact quantity at 2:1 at the Spring without research.
2. Workshop and every direction string contain no refinery claim.
3. Old `deepen_spring` completion/tier survives; fresh saves need no shelving prerequisite.
4. Practice increments exactly once for manual/automatic committed conversions; cancelled, stale,
   interrupted and duplicate outcome paths add zero.
5. Second pass affects only future conversion and all runway/preview/DEBUG consumers read the same
   active rate.
6. Continuous settling processes exactly one retained haul per outcome after loss/retention resolves.
7. Spring graph and transaction controls fit 368×800 and Large Text without permanent explanatory
   cards or routine scrolling.
