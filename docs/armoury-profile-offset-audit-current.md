# Armoury profile-offset audit

**Status:** recommended native playtest profile; values remain DEBUG-tunable after comparable fights

**Updated:** 11 Aug 2026

**Authority:** DRQ-123; `armoury-rebuild-implementation-current.md`

## Outcome

Keep the implemented Armoury offsets for the first real playtest:

| Profile | Physical contribution from a Tier-N rebuild | Heat protection |
|---|---:|---|
| Rigid shell | `N` | exact selected-sample insulation |
| Balanced laminate | `N − 0.5` | exact selected-sample insulation |
| Insulated layer | `N − 1.0` | exact selected-sample insulation |

This is a recommendation to gather evidence, not a claim that the final numbers are balanced. The
three profiles already create the intended decision without adding another resistance statistic,
armour subtype or equipment slot.

## Why the current spacing is coherent

Physical protection is summed fractionally across every protective slot, multiplied by the wearer's
Fortitude value, and rounded once. The half-step therefore is not decorative: several Balanced
pieces can cross a real final-damage boundary, while a mixed loadout can retain some Rigid strength.
At equal Tier 3, five rebuilt pieces contribute 15 Rigid, 12.5 Balanced or 10 Insulated protection
before Fortitude. The profiles remain the same construction tier; only their combat emphasis moves.

Heat protection reads the frozen insulation of every worn protective instance. One 65-insulation
piece reduces heat damage by 16.25 percentage points before the shared 60% cap. Four such pieces
reach the cap, so Insulated cannot create immunity and a fifth piece can be chosen for physical
strength. Balanced stock is allowed to land between the extremes instead of receiving a fabricated
fixed resistance bonus.

The profile recipes also make the trade honest. Rigid requires hard/dense stock, Insulated requires
two genuinely insulating samples and excludes offhand, and Balanced asks for all four relevant
properties. The game never labels Balanced or Insulated as a lower tier.

## What would make the profile fail

Retune only from comparable encounters. A profile has failed if:

- **Rigid dominates:** players choose it even for known Heat-heavy encounters because ordinary
  damage avoided exceeds the entire thermal benefit;
- **Insulated dominates:** it reaches the heat cap too cheaply and the physical loss rarely changes
  damage taken;
- **Balanced is invisible:** changing one or more equal-tier pieces never changes a final physical
  damage boundary and its material burden produces no useful insulation;
- **profile identity depends on lucky unrelated properties:** Rigid routinely matches Insulated's
  heat performance because its selected stock happens to carry similarly high insulation; or
- **full-set pressure replaces gear composition:** optimal play always demands five copies of one
  profile rather than a readable mixed loadout.

## DEBUG comparison receipt

For Armoury rebuild playtests, record the following without exposing hidden foe arithmetic in the
ordinary game:

1. actor and exact protective stable-instance IDs;
2. per-piece construction tier, specialist profile, physical contribution and insulation;
3. summed physical contribution, Fortitude multiplier and summed/capped heat reduction;
4. incoming raw/final damage and harm kind;
5. whether replacing exactly one equal-tier piece with each alternate profile changes the result.

Compare at least Tier 3 and Tier 4 against ordinary physical, mixed and Heat-heavy encounters. Use
the same actor, foes, ranks and RNG receipt for each profile substitution. Do not tune from unrelated
random fights or from the crafting preview alone.

## Tuning boundary

If evidence demands a change, tune the profile offsets and/or the shared insulation conversion—not
construction tier, recipe provenance or station progression. Preserve:

- one fractional summation and one final physical rounding boundary;
- exact selected-sample insulation;
- the shared 60% heat-reduction cap;
- Insulated's offhand exclusion; and
- stable profile IDs and saved instance identity.

These constraints allow reversible number changes without recoloring old equipment as a different
recipe or invalidating saved gear.
