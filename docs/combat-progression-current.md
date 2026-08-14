# Current Design — Combat Progression

**Status:** Current economy plus implementation-ready graph correction. The live build still uses
legacy ordered depth; `combat-tree-true-graph-current.md` is the authoritative replacement.

## Current shape

- Three trees, each with three discipline roots, paired choices at three middle depths and three
  capstones: **72 stable nodes**. Exact authored adjacent-discipline hybrid edges supplement the
  internal forks. Capstones require a connected seven-node prior route and five nodes in their final
  discipline including the capstone.
- One standard tree point per level after level 1.
- Maximum level **25**, producing **24 standard points**.
- Twenty-four points are exactly enough for three pure or valid hybrid eight-node capstone routes.
- Partial investment is legal; the system limits total points rather than enforcing one branch/tree.
- Nodes cost one point; scarcity and prerequisites create route commitment rather than escalating prices.
- Respec is available at the Essence Spring, returns every spent point and costs a visible amount of essence.
- Player-facing and new graph identity are **Emanation** / `emanation`; legacy branch ID `kindling`
  maps one-way during graph migration and remains decode-only.
- The level-up receipt, first-point teaching, banking, companion-arrival and respec presentation are
  authoritative in `combat-tree-progression-experience-current.md`.

## Starting lean clarification

An authored calling lean is a **bonus above the 24 level-earned points**. It is not charged against a
new recruit's level budget, and respec returns those points into the flexible pool.

Therefore the precise max-level statement is:

> Every person can complete three eight-point capstone routes from levelling, one per tree if the player chooses,
> **plus their authored calling-lean points**.

Older text claiming a finished companion has exactly three branches and six entirely untouched is too
strict for the implemented free-lean rule. A max-level person may place their small lean bonus into a
fourth partial branch. This does not create convergence: an extra one-to-three points cannot complete
another eight-node branch, while it preserves the settled advantage of arriving with a lived trade.

## Why keep eight / one / level 25

- An eight-point capstone route gives room for paired fundamentals/developments/masteries and at
  least two active-technique opportunities without making early identity wait too long.
- One point per level makes the next choice visible and avoids phone-hostile cost arithmetic.
- Level 25 follows the player's stated requirement that a person can finish one branch from each tree.
- The late XP curve, not escalating node price, controls campaign length.

This is now a tuning target rather than an unanswered structural question. Change branch depth only if
long-campaign play shows capstones arrive too early/late across exploration and combat XP together.

## Respec boundary

- Respec is all-at-once, out of combat, at the Spring.
- Cost is `base + spent points × per-point cost`; both values belong in debug tuning.
- It returns calling-lean bonus points as well as earned points. It never deletes skills without
  returning their budget.
- It should remain meaningfully priced but never become so expensive that a player is trapped by
  choices made before understanding a branch.

## Playtest evidence to collect

1. Levels at first active skill, second active skill and first capstone during ordinary mixed play.
2. Whether discovery XP lets low-combat players progress without making combat XP irrelevant.
3. Number of respecs and whether cost prevents experimentation or makes builds disposable.
4. How often max-level builds complete three capstone routes versus spread into broader partial graphs.
5. Whether the strongest capstones create one mandatory branch in each tree.
