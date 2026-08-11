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

## Coherent spent graph build

The generator creates and persists a **graph build plan**:

- one legal eight-node route in Offense, one in Defense and one in Craft, selected from validated
  pure or authored hybrid route templates;
- one route marked as the person's primary expression;
- a stable ordered list of explicit `CombatNodeID` purchases through level 25;
- a one-point calling lean above the level budget, normally the primary route's first root and
  supported by visible calling/personality;
- one final legal breadth node after the three capstone routes, because 24 standard points plus the
  free calling root produce 25 owned nodes rather than only the 24 nodes in three routes.

The old instruction to persist branch steps and “buy next” is superseded. It encodes the retired
linear ladder, cannot represent a crossover and lets a later graph revision silently change what a
person practised. Stable semantic node ID is now the ownership and plan authority. Wording/numeric
effect changes preserve that identity; topology changes require an explicit versioned plan migration.

The first `level - 1` earned entries that are legal after the calling root arrive spent. The default
cadence is:

1. calling root, then seven earned nodes finish the primary route by level 8;
2. each supporting route receives its root and first technique by level 12, then reaches one legal
   development by level 14 (three nodes in each supporting tree);
3. finish the secondary route, then the tertiary route, by level 24;
4. level 25 buys the saved legal breadth node.

This is an arrival-plan cadence, not a rule imposed on player-built people. A hybrid route must be
one of the same validated eight-point paths the player can buy, including authored adjacent hybrids,
the connected-seven route gate and five-node capstone commitment. The plan may not scatter through arbitrary available nodes or
claim a route the ordinary graph rejects.

The player-facing card shows a short build phrase assembled from the three final capstone lanes—for example
**Precise · Evasive · Venom-wise**—plus the exact spent nodes on inspection. The plan is not a secret
lean or an uninspectable quality roll.

## After recruitment

- Unspent future level points belong to the player normally.
- Until the player diverges or respecs, a one-tap **Follow their practice** action may preview and
  spend the next exact stable node in the persisted build plan. It never auto-spends on level-up and
  cannot silently skip an invalid planned node.
- Full paid respec at the Essence Spring is available exactly as it is for every other person. It
  returns both earned and calling-lean points under `combat-progression-current.md`.
- After a respec, the old plan remains only as a readable recommendation; the character never
  silently rebuilds toward it.

This lets an encountered person feel like somebody who survived before meeting the Binder while
preserving the player's ownership of their future.

## Save and generation boundaries

Persist first-met level, three route-template IDs, ordered stable-node plan, plan schema version and
initial calling-lean node with the generated
identity. Repeated Tavern appearances, app relaunches and recruitment refusal cannot reroll any of
them. If a future catalogue patch invalidates a planned branch step, refund it as an unspent point
and mark the plan for repair; never substitute a similarly positioned node silently.

Implementation stores the plan on the generated-person record, not on generic `CharacterState`.
Build the arrival character by setting:

- `level` to the saved first-met level;
- `experience` to exactly `CharacterRules.experienceForLevel(level)`;
- `freePoints = 1`, with the saved calling-root node owned;
- owned-node IDs produced by validating and replaying the first `level - 1` earned plan entries after
  that root;
- stats produced by replaying the ordinary deterministic level-growth rule from level 1 to arrival
  level using the person's saved starting lean—not by setting a high level beside level-1 stats.

This keeps the next XP threshold, respec budget, combat output and visible level mutually honest.
Plan repair validates exact prerequisites, route template and point source. If a node disappears or
its route becomes illegal, preserve the person and every valid owned stable ID, leave unmatched
earned points unspent, and flag the recommendation as needing repair. Never reconstruct identity from
screen column/rank alone.

Legacy generated records containing branch-step plans migrate once by replaying each old step against
the decode-only pure lane path for that stable branch ID, preserving the old spend count and effects
as far as possible. The migrated explicit node list is then saved with the current graph version.

## Explicit exclusions

- no rarity tier or “perfect build” roll;
- no recruitment fee based on spent points;
- no permanent respec restriction;
- no hidden stat advantage over named travellers;
- no animal use of human combat branches;
- no automatic matching to the current party's gaps.

## Required fixtures

1. A level-1 generated person has zero earned points plus one calling-lean point.
2. A level-14 person has thirteen earned nodes plus one calling root: one legal capstone route and
   three connected legal nodes in each supporting tree, including each route's first technique, all
   as explicit stable IDs.
3. Revisiting or delaying recruitment preserves level and plan exactly.
4. Respec refunds every spent point including the lean and prevents later auto-spending.
5. Animal companions never enter this generation path.
6. Pure and hybrid templates pass the ordinary graph validator; authored hybrid, connected-seven and
   five-node capstone requirements cannot be bypassed by arrival generation.
7. Legacy branch-step migration preserves spend count/effects where possible and refunds every
   unresolved point without positional aliasing.
