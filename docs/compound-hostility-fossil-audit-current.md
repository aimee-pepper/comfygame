# Compound hostility fossil audit — current

**Status:** implementation-ready comparison; no balance removal is authorized until the comparison
gate passes  
**Owner:** Game Design  
**Roadmap ID:** `compound-hostility-authority`  
**Updated:** 11 August 2026

## Why this is broader than Dim Sky

The old symbol catalogue still contains three parallel ways to describe what a world yields and
what lives there:

1. `yieldModifiers`;
2. `enemyTableModifiers`;
3. `enemyTierDelta`.

The first two no longer generate live worlds. Resource abundance comes from resolved Substrate,
Vitality and the other pressure readings; creature eligibility and affinity come from the generated
world's energy budget and readings. The only remaining callers of the old book-based yield and
creature tables are compatibility tests. Their fields are therefore dead authored mirrors and may
be removed together with those dead functions once old-save decode is proven tolerant.

`enemyTierDelta` is different: it is still live. `Worldgen.enemyCount` reads the book's tier and adds
two base creatures for every ordinary tier before applying vitality, world area, encounter-family
and Danger multipliers. The six non-Danger compounds that still carry it are:

| Compound | Flat tier | Pre-scaling population addition | Pressure identity already present |
|---|---:|---:|---|
| Ashen | +1 | +2 | moderate Ash atmosphere + faint Wildfire thermal |
| Rich Ore | +1 | +2 | great Iron + moderate Gold substrate |
| Teeming Life | +1 | +2 | great Bloom + moderate Herd + faint Swarm vitality |
| Dim Sky | +1 | +2 | great Cloud illumination; direct vision −1 |
| Gilded Veins | +1 | +2 | great Gold + faint Crystal substrate |
| Mote Vein | +2 | +4 | moderate Crystal illumination + substrate |

Because vitality can scale population up to three times the base and larger maps scale it again,
these are not harmless `+1` labels. They can add considerably more than two actual map entities.
Removing only Dim Sky and Gilded Veins would also preserve an arbitrary special-case system for the
other four. The honest question is whether *ordinary composition itself* should derive hostility,
or whether each old compound should continue carrying a second unexplained population charge.

## Current design boundary

- **Danger runes remain explicit hostility bargains.** Their typed Danger profile owns tier,
  grouping/spawn effects and Stability trade. This audit does not remove or weaken them.
- **Vitality remains the authority for how much life stands in a world.** Teeming Life must still
  feel crowded without a second flat tier charge.
- **Resolved ecology remains the authority for what can live there and how it behaves.** Darkness,
  heat, air, water and substrate must continue changing the cast through real traits and affinity.
- **Greed and resolved world level remain the authority for encounter strength and reward pressure.**
  Valuable rock should not secretly mean extra bodies unless a disclosed systemic rule says so.
- **A compound name is not itself a balance permission.** If Mote Vein needs guardians or Gilded
  Veins needs greater risk, that consequence must be an explicit readable mechanic, not a leftover
  integer that bypasses the pressure model.

## Recommended migration

The design recommendation is to retire all six ordinary `enemyTierDelta` values as one coherent
migration, leaving tier changes to typed Danger profiles. This is a recommendation pending the
comparison below, not authorization to quietly reduce difficulty.

If the comparison shows encounters become too sparse or too easy, tune a current systemic authority
instead:

- vitality-to-population for world density;
- encounter scaling for party size and level;
- greed/world-level contribution for foe strength;
- a named Danger rune for deliberately authored hostility;
- a site/apex guardian rule for a local defended prize.

Do not restore per-compound flat tiers merely to recover an old enemy count. That would keep two
causal models and ensure future compounds require hand-maintained secret hostility numbers.

## Controlled comparison gate

Engineering should add a DEBUG-only comparison that resolves identical page, seed, cast, map size
and party inputs under `legacy ordinary tier deltas on` and `off`. It must include all six compounds,
a pressure-equivalent page written without the compound, and at least one no-compound control.

For each fixture record:

- resolved pressure readings, Stability, greed and world level;
- vitality multiplier, area multiplier and Danger profile;
- generated map-entity count and reachable awake encounter group sizes;
- ordinary encounter preview after party-size/level scaling;
- apex profile (which must not change merely because a dead flat population charge was removed);
- projected XP and resource opportunity per completed expedition.

Run at minimum party sizes 1, 3 and 5; early and established party levels; ordinary and high-vitality
worlds; and one larger map. Use the same seed on both sides. The comparison passes when:

1. pressure-equivalent worlds have equivalent population before explicit Danger;
2. Teeming Life remains visibly crowded through vitality alone;
3. high-value substrate remains risky through greed/world level, not unexplained extra bodies;
4. ordinary encounters still satisfy the settled party-scaling acceptance range;
5. no apex, traveller, page, resource or Stability outcome changes except through a documented live
   authority; and
6. old books containing these stable compound IDs decode and resolve without rewriting history.

If difficulty falls outside the accepted range, hold the migration and tune the appropriate systemic
rule in a separate measured change. Do not use the legacy delta as both the control and the fix.

## Cleanup after acceptance

Only after the comparison is accepted:

1. remove ordinary `enemyTierDelta` from all six catalogue entries and then from the untyped symbol
   schema if no legitimate consumer remains;
2. remove `yieldModifiers`, `enemyTableModifiers`, `yieldTable(for:)` and `enemyTable(for:)` after
   tolerant old-save fixtures prove they are not serialized campaign facts;
3. keep Danger-profile hostility typed and validation-covered;
4. update preview/History copy to explain density, strength and Danger from their real authorities;
5. preserve this document and the decision log as the historical explanation for the migration.
