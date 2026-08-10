# Historical open design questions — superseded routing

**Authority notice (9 Aug 2026):** This file preserves an earlier question set and is not the live
review queue. Several entries—especially anchoring timing and sustain—have since been resolved or
given current implementation boundaries. Use `current-design-index.md` for system authority,
`design-review-queue.md` for Aimee's active design reviews, and `engineering-questions-for-aimee.md`
for reversible implementation questions. Do not implement an alternative from this file over a
newer current document.

The original questions follow unchanged for historical provenance.

## Q-A. WHEN does the anchor choice happen? (the big one)
Aimee wants permanent anchoring of even high-instability worlds at great cost. Three candidate designs from the designer Claude (not decisions — pick/blend/reject):

1. **Anchor at bind time.** Premium binding materials produce a born-anchored world. Pro: fully informed pre-commitment, cleanest economy. Con: you can never fall in love with a world you already rolled — which cuts against the "found it, kept it, perfect use later" joy.
2. **Anchor in-world at a discovered site.** Each world generates an anchor-point (waystone/wellspring); reaching it and paying (possibly sacrificing part of the run's haul) anchors before collapse. Pro: dramatic mid-run decision, exploration-gated, the instability meter becomes a countdown you're racing. Con: pressure-laden; hardest to price.
3. **Anchor retroactively from base.** The book retains the seed; within N subsequent runs you can re-open and pay to anchor from the Writing Desk. Pro: sleep on it — best fit for interruptibility; supports "I realized later that world was special." Con: lowest tension.
Hybrid worth considering: a cheap in-world **tether** (option 2) that pauses decay for N turns / preserves the seed, with the expensive **permanent anchor** performed from base (option 3). Tension in the moment, commitment at leisure.

## Q-B. Sustain economy specifics
What resource sustains anchored worlds, produced where, at what scaling vs. world value? (Research pass 2 Q1; RFTools per-tick model vs. self-sustaining rich worlds.) Related: do minion harvesters in a world offset its own upkeep?

## Q-C. Reality-layer reset
What triggers it, what persists, what's the previewed payoff? (Pass 2 Q4.)

## Q-D. Symbol vs. gambit acquisition economies
Shared loop/currency or parallel tracks? v0 ships parallel. (Pass 2 Q5.)

## Q-E. Automation vs. content scaling
Which content assumes full automation; do some high-value worlds resist automation? (Pass 2 Q6.)

## Q-F. Permanent-loss policy per layer
Un-banked haul is losable (decided). Can anchored worlds ever die? Can the base? Offline time is always safe (decided).

## Q-G. Quirk catalog
Which paired-tradeoff quirks ship, and does the PoE-style veto/reroll affordance apply to random-filled slots?
