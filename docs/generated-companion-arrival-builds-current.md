# Generated companion arrival builds — current design

**Status:** current implementation-facing rule. This replaces “wild companion” language in the
combat-tree drafts; tame animals follow `animal-companion-combat-current.md` and have no human tree.

## Who this applies to

This applies to generated **people** encountered in worlds or through Orsa's Tavern. Named
travellers retain their authored level/lean rules. Tamed animals retain their trait-derived fixed
action kits.

## Arrival level

A generated person is created at the Binder's current level, capped by the ordinary level cap. The
level is fixed when the person first enters the persistent met pool, not rerolled when they revisit
the Tavern or when recruitment is delayed.

This preserves the settled intent that a late find is immediately usable without letting players
cycle visitors until one copies a temporarily over-levelled party member.

## Coherent spent build

The generator creates and persists a **build plan**:

- one preferred branch in Offense, one in Defense and one in Craft;
- one of those branches marked as the person's primary expression;
- a stable ordered list of the 24 ordinary nodes they would take through level 25;
- a one-point calling lean above the level budget, placed in a branch supported by their visible
  calling/personality.

The first `level - 1` entries in that plan arrive spent. The order should reach a useful active
identity early, then keep all three chosen branches recognisable; it must not scatter points across
more than those three branches. Exact node order follows prerequisites and is validated when the
person is generated.

The player-facing card shows a short build phrase assembled from the three branch names—for example
**Precise · Evasive · Venom-wise**—plus the exact spent nodes on inspection. The plan is not a secret
lean or an uninspectable quality roll.

## After recruitment

- Unspent future level points belong to the player normally.
- Until the player spends a point or respecs, a one-tap **Follow their practice** action may spend
  the next valid node in the persisted build plan. It never auto-spends on level-up.
- Full paid respec at the Essence Spring is available exactly as it is for every other person. It
  returns both earned and calling-lean points under `combat-progression-current.md`.
- After a respec, the old plan remains only as a readable recommendation; the character never
  silently rebuilds toward it.

This lets an encountered person feel like somebody who survived before meeting the Binder while
preserving the player's ownership of their future.

## Save and generation boundaries

Persist first-met level, branch choices, node plan and initial calling-lean node with the generated
identity. Repeated Tavern appearances, app relaunches and recruitment refusal cannot reroll any of
them. If a future catalogue patch invalidates a planned node, refund it as an unspent point and mark
the plan for repair; never substitute a different branch silently.

## Explicit exclusions

- no rarity tier or “perfect build” roll;
- no recruitment fee based on spent points;
- no permanent respec restriction;
- no hidden stat advantage over named travellers;
- no animal use of human combat branches;
- no automatic matching to the current party's gaps.

## Required fixtures

1. A level-1 generated person has zero earned points plus one calling-lean point.
2. A level-14 person has thirteen earned nodes, all valid and confined to three declared branches.
3. Revisiting or delaying recruitment preserves level and plan exactly.
4. Respec refunds every spent point including the lean and prevents later auto-spending.
5. Animal companions never enter this generation path.
