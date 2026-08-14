# Named traveller arrival level — review

**Status:** reversible playtest authority; implementation authorized in campaign order  
**Priority:** playability correction for long campaigns, after the active combat-v2 checkpoint  
**Homework ID:** `named-traveller-arrival-level`

## The live problem

`BaseState.seat` creates every named traveller with a level-1 `CharacterState`, regardless of the
Binder's level or the traveller's story phase. After recruitment, active party members receive the
same XP award. Equal awards preserve an existing XP/level gap rather than closing it.

The additive encounter scaler correctly keeps the Binder as the world-level anchor and gives a very
low-level companion only a small pressure contribution. It does not—and should not—lower every foe
to protect one recruit. In a long campaign, those rules together can make a newly earned late
traveller too fragile to field and unable to catch up through ordinary equal-share play.

## Recommendation

Freeze a named traveller's arrival level to the Binder's current level when recruitment commits.

- Replay the ordinary deterministic level-growth rule to that level; do not invent authored stat
  blocks or copy the Binder's stats.
- Bank the normal level-earned combat points unspent so the player chooses the route.
- Preserve the traveller's authored calling lean as free bonus ownership above those points.
- Freeze the result once. Roster reconciliation and old-save repair never re-level an existing
  traveller merely because the Binder later advances.
- Preserve the live transaction order: award the recruitment discovery to the expedition party,
  then seat the newcomer at the Binder's resulting level. The newcomer does not also receive XP for
  discovering themself. This order must not add the same level or point twice.

This matches generated-person arrival's core principle—first-met capability is appropriate to the
current campaign—without importing generated wants or route templates into named characters.

This decision fixes **arrival**, not every later roster gap. The current game awards expedition XP
to the active party, so somebody deliberately left Home can later trail the Binder. That is tied to
the still-unfinished keeper/posting bargain: fielding a specialist is meant to grow them and their
station, while keeping them at their station buys an immediate service benefit. Do not smuggle a
full-roster XP rule into recruitment. After staffing is playable, measure whether ordinary rotation
creates an unhealthy permanent deficit; only then compare reduced posted XP or an explicit catch-up
route as its own rule.

## Alternatives

1. **Two levels behind plus accelerated catch-up.** Creates a visible growth period, but needs a new
   XP multiplier, stopping rule, UI explanation and migration behavior.
2. **Level 1 plus strong catch-up.** Preserves the longest growth arc but can still make late
   travellers unusable for several expeditions.
3. **Keep level 1.** Simplest technically, but the current equal-award economy makes the deficit
   permanent and conflicts with recruitment as an immediately playable reward.

## Acceptance

1. Opening and late named travellers join at the Binder's exact current level across levels 1–25.
2. Deterministic stat replay, XP threshold, banked points and authored lean are correct and stable.
3. Recruitment/relaunch/reconciliation cannot duplicate levels, stats or points.
4. Existing recruited travellers retain their saved progression; no global catch-up migration is
   inferred without a separate decision.
5. A newly joined traveller can enter the next ordinary encounter without changing foe world level,
   while their additive pressure contribution is monotonic and correctly frozen.
