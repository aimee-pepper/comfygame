# Expedition outcomes and loss — current design

**Status:** current safety boundary with reversible 50% partial-haul tuning. This reconciles the
original run-risk brief with session 17's no-permanent-loss decision.

**Engineering status, 9 Aug 2026:** the carried-supplies safety boundary is implemented. Each live
stack records the exact quantity packed from Home; use reduces that protected quantity, newly
acquired items merged into the same stack remain unprotected, and partial retention partitions the
stack before the saved-RNG selection. Old mid-run saves reconstruct the boundary conservatively.
Explicit exit kinds, collapse-only lifetime counting and the Recovered/Lost/Kept-for-good recap are
also implemented. Random retention versus player-chosen recovery remains a later review/playtest.

## The failure state

The game has no campaign-ending death state. Expedition failure is meaningful through **lost
opportunity, a disposable world's collapse and partial loss of things acquired during that trip**.
It never erases banked progress, people, knowledge, anchored places or pre-departure property.

That is a real failure state for this game. Do not add permanent companion death, save deletion,
Base damage, XP loss or offline punishment merely to make defeat more conventional.

### Design audit — consequence is sufficient

For this game's intended month-long, bedtime-friendly campaign, partial new-haul loss plus the end of
an unanchored expedition is enough consequence. The player also already paid the binding cost and
spent the session's opportunity. Adding wounds, repair debt, XP loss, temporary stat penalties or a
mandatory recovery timer would make the next session less inviting without creating a new decision
inside the failed run.

A failed run with no acquired haul may therefore have no additional inventory penalty. The player
still keeps the knowledge earned and loses the expedition opportunity; do not manufacture debt to
make the recap look harsher.

## Outcomes

| Outcome | Haul | World/party state |
|---|---|---|
| Portal return | 100% acquired haul | Party recovers; unanchored expedition closes, anchored snapshot persists |
| Waystone return | 100% acquired haul after consuming the Waystone | Same controlled return; item cost bought certainty |
| Binder passes out / combat defeat | Placeholder 50% of acquired haul | Party safely returns and recovers |
| Floor/collapse ejection | Placeholder 50% of acquired haul | Party safely returns; anchored realm itself persists if already anchored |
| Player leaves an unanchored run by an explicit future abandon action | Treat as partial-haul failure, never a free full return | Must confirm exact consequence before action exists |

Companions who pass out take no more turns and revive at Base. Other party members cannot continue
walking the Binder's body through the world.

## What “acquired haul” means

Partial loss applies only to net gains obtained after departure:

- bulk world resources gathered this run;
- motes gathered this run;
- newly found gear, curios, keys, treasures and unused newly found consumables;
- property-bearing world resources harvested this run.

It does **not** apply to:

- unused consumables, Anchor Frames, instruments or other field-kit items owned before departure;
- any other item transferred from the Base into the expedition;
- equipped gear;
- pages, focuses, bestiary/discovery records, analysis readings or World History;
- XP, levels, research or permanent recognition;
- recruited people or accepted animals;
- anchored-realm identity/history.

Pre-departure items return in full unless the player actually consumed them through their authored
effect. This is not insurance; those objects were already banked property and the settled loss table
risks only **unbanked haul**.

Implementation must partition field inventory into `carriedAtStart`, `acquiredThisRun` and consumed
amounts before applying any partial-retention algorithm. Comparing only catalogue totals is
insufficient when stacks split, merge or carry provenance.

## Knowledge and completion

Reality-layer knowledge commits at discovery and survives every outcome. A page does not become
unread because the physical expedition failed; a person already invited does not vanish; an animal
that accepted follows the party home.

Unique physical loot is different: if first found during the run, it is unbanked haul and may be in
the lost fraction. In an anchored realm, the saved site records that it was removed even if it was
lost during retreat. This is the current run-risk rule, not an accidental deletion. The exit summary
should name a lost unique object clearly rather than merely omitting it.

**Completion correction:** no truly one-copy progression or narrative object may use that rule.
Keys, authored quest objects and anything whose source can be exhausted forever must either commit
as permanent knowledge/state on discovery, return as protected property, or remain recoverable at
its source until banked. Rare but repeatably obtainable objects—such as wild weapons from future
apex encounters—may remain ordinary acquired haul. “Unique” presentation is not permission to make
campaign completion unknowingly missable.

## Partial-retention presentation

Current implementation randomly retains items from the acquired pool using the run's saved RNG, so
force-quit cannot reroll the result. Bulk resources retain the configured fraction by quantity.

This is a valid reversible first slice, but the UI must show both **Recovered** and **Lost** sections.
“About half came home” without naming the lost objects conceals the only consequence of failure.

### Design-lead recommendation for review

Test replacing random item retention with a short post-outcome **What did you hold onto?** choice at
Base. The player would choose acquired item slots up to the same retention budget; bulk quantities
would remain automatic. This preserves the 50% cost while protecting attachment and making the
satchel's keep/leave decisions culminate in agency rather than a lottery.

Do not implement that recommendation silently. It materially changes the texture of collapse and
belongs in Aimee's review after both versions can be compared.

### Outcome recap

Before returning control at Base, show one compact, dismissible recap in this order:

1. **Outcome:** “Returned safely,” “The Binder was carried home,” “The ground gave way,” or the
   future explicit abandon wording. Do not call every partial return a collapse.
2. **Recovered:** acquired resources/items that banked successfully. Pre-departure property need not
   appear as gain; a short “Packed supplies returned” reassurance is enough after failure.
3. **Lost:** only acquired resources/items actually removed by the partial-retention result. If
   empty, say “Nothing you found was lost” rather than omitting the section.
4. **Kept for good:** new pages/focuses, recruits/animals, observations, XP/levels and other permanent
   discoveries earned during the expedition.

The recap is explanation, not a second punishment. Dismissal returns to an ordinary usable Base;
there is no forced healing bill or cooldown gate.

Persist an explicit tolerant outcome kind (`portal`, `waystone`, `defeat`, `collapse`, and future
`abandon`) beside the prose reason. Use it for World History, lifetime statistics and playtest
telemetry. The current single `runsLostToCollapse` counter conflates combat defeat with structural
collapse and cannot answer whether combat or world duration is causing failed expeditions.

## Rounding and empty-haul behavior

- Fractional bulk amounts round down per resource, except one gathered unit is retained when the
  configured fraction is above zero. A one-unit first discovery should not always be mathematically
  deleted.
- Item retention budgets round up to one acquired unit when any acquired item exists and the fraction
  is above zero.
- Failure with no acquired haul still records the world/outcome and awards earned XP/knowledge.
- Items already consumed during the run are neither returned nor counted as lost at exit.

These rules are debug-tunable only through the overall retained fraction; safety categories are not
tuning.

## Anchoring and settlement

Failure after anchoring saves the durable realm snapshot, including depletion and discoveries, then
runs the ordinary Anchorage settlement. Failure never unanchors the realm. Settlement cannot spend
essence silently and dormancy returns assigned companions safely as already specified.

## Required fixtures

1. Every unused pre-departure field item returns after defeat/collapse regardless of retained
   fraction.
2. A consumed pre-departure item does not duplicate on return.
3. Only net-new stack quantities enter the partial-loss pool after stack merge/split.
4. Pages, readings, XP, recruits and tamed animals always survive.
5. Saved RNG makes random retained items identical across force-quit/resume.
6. Exit summary names recovered and lost item/resource quantities separately.
7. Anchored-world persistence and settlement run correctly after both defeat and collapse.
8. A finite one-copy progression/narrative object cannot become permanently unobtainable through
   partial retention.
9. Defeat and collapse produce distinct saved outcome kinds and lifetime counts.
10. The recap names Recovered, Lost and Kept-for-good results, including honest empty sections.
