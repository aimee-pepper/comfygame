# Reforge progression audit

**Status:** design correction recommended; requires Aimee review before native revision

**Updated:** 11 Aug 2026

**Authority:** DRQ-065 and DRQ-110; `crafted-gear-migration-current.md`

## Finding

The current three-rank, `+0.2 effectivePower` progression does not deliver three meaningful
upgrades under the live combat rules.

Weapons multiply effective power by 2 and then round the whole attack once. Relative to rank 0:

| Reforge rank | Continuous weapon contribution | Final attack change |
|---:|---:|---:|
| 1 | +0.4 | 0 |
| 2 | +0.8 | +1 |
| 3 | +1.2 | +1 |

The first paid reforge and the third paid reforge can therefore produce no combat improvement. The
equipment screen's rounded comparison can also report no change even though the Blacksmith consumes
increasingly scarce stock and Essence.

Protective gear carries fractional power into one loadout sum, which is structurally correct, but a
single `+0.2` piece commonly remains below a final protection boundary. Several upgrades may combine
later; that does not make each escalating transaction honest when purchased.

This contradicts the current migration fixture's stated requirement that three reforges produce
three real monotonic combat changes. The test proves continuous `effectivePower` rises; it does not
prove the player's final attack or damage taken changes at each rank.

## Recommended correction

Replace three repeated micro-ranks with **one deliberate Reforge per construction**:

- maximum ordinary reforge improvement: **+0.5 effective power**;
- first-slice price remains **2 qualifying samples at property 30+ and 8 Essence**;
- a specialist rebuild resets the reforge as it does now;
- the result remains below the next construction tier and cannot unlock a specialist recipe;
- the preview shows continuous power and the actor's actual current combat change;
- if a protective piece does not cross this actor's current final rounding boundary, state that
  honestly before confirmation instead of displaying a fabricated `+1`.

At ordinary weapon scaling, +0.5 produces exactly +1 attack. At default armour scaling, +0.5 is the
smallest half-tier step that can cross one protection boundary while remaining composition-sensitive
under Fortitude. The single transaction removes two escalating chores and better expresses
Halloway's identity: retain and improve this exact object, rather than fill a three-pip meter.

## Why not increase all three ranks

Three individually guaranteed armour increases would require roughly a whole tier of protection per
rank, allowing ordinary gear to overwhelm specialist construction. Smaller steps inevitably collide
with integer combat rounding. Adding a separate reforge-only damage stat, proc or reroll would make
the gear system more complicated merely to justify the meter.

A one-step half-tier improvement preserves the intended hierarchy and removes the dishonest ranks.

## Save migration if approved

Do not reinterpret or delete paid work. Add one frozen continuous `reforgePower` authority (or an
equivalent versioned field) on the exact gear instance:

- legacy/new-schema rank 0 decodes to 0;
- existing rank 1/2/3 decodes to `0.2/0.4/0.6` respectively;
- existing rank 3 therefore remains a grandfathered +0.6 piece;
- existing +0.2 or +0.4 pieces may buy one clearly previewed completion to +0.5; and
- new reforges write +0.5 directly and display simply **Reforged** rather than `1/3`.

Preserve `legacyPowerCredit` separately. It describes pre-migration strength above Tier 4 and must
not absorb ordinary reforge work or trigger the Legacy-masterwork rebuild warning.

Old `reforgeRank` remains decode compatibility only after migration. Selling, equipment comparison,
combat, save/load and specialist rebuild read the frozen continuous value from one authority.

## Acceptance gates

1. A new weapon reforge changes the live actor's attack by exactly +1 at ordinary scaling.
2. A new protective reforge shows exact continuous protection and the actual rounded damage boundary
   for at least low/default/high Fortitude loadouts.
3. New gear cannot be reforged repeatedly and never gains construction-tier eligibility.
4. Existing rank 0/1/2/3 saves preserve 0/0.2/0.4/0.6 power exactly through migration and relaunch.
5. Existing rank-3 gear is never weakened or charged again.
6. A +0.2/+0.4 legacy-new reforge may complete to +0.5 once, paying only after exact confirmation.
7. Rebuild resets ordinary reforge power, with the current warning and atomic behavior.
8. Worn/stored/spillover targets preserve stable instance identity and never consume themselves as
   material.
9. Recycler receipts still exclude reforge inputs; Trading Post value reads the exact resulting
   power without inferring a rank.
10. Release copy contains no `rank N/3`, `level N/3` or promise of three improvements after the
    migration.

## Held alternative

Keeping three ranks is acceptable only if each purchase gains a legible, rules-owned effect that
does not duplicate construction tier or add arbitrary subsystems. No such effect currently exists.
The audit therefore recommends simplification rather than inventing one.
