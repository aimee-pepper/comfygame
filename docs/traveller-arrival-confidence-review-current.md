# Traveller arrival confidence — telemetry-first review

**Status:** settled implementation direction; percentage and near-miss increment remain DEBUG-tunable  
**Date:** 11 August 2026  
**Decision:** one bounded arrival-confidence roll occurs after deterministic one-person selection

## Question

Should a traveller whose complete signature happened to resolve correctly—but whose required values
were not causally produced by the player's writing—sometimes fail to appear?

The instinct is sound: a fully accidental late signature should not make the cast feel thrown at the
player. Applying a separate failure chance to every unauthored condition is not sound. Even 70% per
condition yields only `0.70^8 = 5.76%` for an eight-condition late traveller after the player has
already produced the rare full match. That double-charges condition count and makes correct worlds
look broken.

## Settled model

Apply the structural selector first:

- complete signature required;
- blind authored-order frontier;
- earliest matching story-arrival band;
- recovered/causally-authored evidence tie-break only inside that band; and
- one traveller maximum per newly bound world.

Then roll once for the selected candidate:

```text
authoredFraction = causallyAuthoredConditions / totalConditions
baseChance       = 0.25 + 0.75 × authoredFraction
arrivalChance    = min(1.0, baseChance + 0.25 × priorNearMisses)
```

Examples before near-miss protection:

- no causally authored conditions: **25%**;
- half causally authored: **62.5%**;
- every condition causally authored: **100%**.

`causallyAuthoredConditions` includes any required condition that would fail in the same seeded world
with the player's authored pressure contribution removed. It does not require the player to have
recovered that clue; clue knowledge belongs to same-band selection weight, while arrival confidence
measures what the page actually caused.

The removal counterfactual reopens the affected targets and reruns the ordinary unwritten-target
fill with the same world seed. Reusing only the original world's rolled sigils would leave those
targets artificially blank and over-credit authored causality.

If the selected candidate fails the roll, place no substitute traveller and record one saved near
miss for that traveller. The next selected full match gains 25 percentage points; the third selected
full match is guaranteed. A successful arrival clears that person's near misses. Unrelated worlds,
other recruits, relaunch and array order do not alter them.

## Required receipt

For each new bound world, DEBUG/bug-report context records without changing gameplay:

- all full-signature matches and exclusion reasons;
- selected traveller, story band and authored order;
- total signature conditions;
- recovered location-clue count;
- causally authored known-condition count;
- accidental satisfied-condition count; and
- whether the world placed no traveller because no eligible full match existed.

Release UI exposes no hidden traveller, condition or score. A recruited traveller's later History
record may truthfully distinguish **your writing led here** from **the world happened to fit** only
after that person is known.

## Presentation boundary

If every location clue for the selected person is recovered, a failed arrival may truthfully record
**The signs aligned, but [name] left no trace** and show that another matching world is more likely.
With incomplete clues, Release UI does not reveal the hidden full match or name; only DEBUG/bug
context exposes it. Fully causally authored signatures never produce this message because arrival is
guaranteed.

## Evaluation

Compare at least ten fresh campaigns and long-campaign seeded simulations:

1. worlds between recruited travellers by story band;
2. proportion of recruits with zero/some/all causally authored conditions;
3. full-match near misses and worlds required to recover from them;
4. opening time to Trading Post, Recycler and Blacksmith;
5. whether a player can reasonably distinguish a wrong draft from a hidden failed arrival roll; and
6. whether late books feel deliberate without becoming more arduous merely because they contain
   more conditions.

Retune the 25-point floor/increment only from this evidence. Do not remove the 100% all-authored
guarantee, add per-condition multiplication or let a failed candidate fall through to somebody else.
