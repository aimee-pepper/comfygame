# Weaponsmith — Current Implementation Contract

**Status:** implementation-ready with reversible balance values  
**Owner:** Maud  
**Authority:** this file makes the Weaponsmith rows in `gear-crafting-families-current.md` exact.

## Purpose and boundary

The Weaponsmith constructs advanced **non-magical melee** weapons. It owns close fitted point,
edge and maul families plus the diary-taught mid-reach polearm. It does not own armour, thrown or
other physical ranged weapons, Channelworks weapons, apex weapons, coatings, ammunition, durability
or soulbinding.

“Fitted” is an authored shop philosophy, not another item subsystem. The player chooses a recipe
whose delivery suits an intended wielder and the preview names the relevant combat lean. The output
stores ordinary weapon kind, reach, tier, reforge and provenance only. It does **not** store a chosen
wielder, fit score or equip restriction; anybody may equip it later without penalty.

## Station lifecycle

| Effective station tier | Capability | Output cap |
|---:|---|---:|
| 0 | Fitted point root | 3 |
| 1 | Fitted edge and Fitted maul roots | 3 |
| 2 | Tier-4 construction | 4 |

The two paid station rungs are ordinary reversible economy tuning:

| Stable research ID | Name | Cost | Grant |
|---|---|---|---|
| `weaponsmith_broaden` | Balance and consequence | 75 essence · 16 Iron Ore · 6 Copper · 2 Gold | Set purchased station tier to at least 1; expose edge and maul |
| `weaponsmith_masterwork` | Masterwork leverage | 150 essence · 28 Iron Ore · 10 Copper · 4 Gold | Set purchased station tier to at least 2; permit Tier 4 |

`weaponsmith_masterwork` follows `weaponsmith_broaden`, but a keeper-earned Tier 1 satisfies that
rung under Decision 105 without charging the redundant broaden cost. Grants set the authored target
tier rather than blindly incrementing the current purchased value.

Maud's singular diary teaching `maud_fitting_pattern` unlocks **Fitted polearm** independently of
station tier, but the Weaponsmith must already be built. If the pattern arrives first, its known
state persists and the recipe appears when the station becomes available. Construction itself
grants the Fitted point root idempotently, including migration of an already-built Weaponsmith.

Specialist construction permits rather than guarantees the headline tier. Natural tier remains the
shared grade result, output is `min(natural tier, station cap)`, and essence uses the actual output
tier. Natural Tier 1/2 stock remains craftable behind **This stock yields Tier N; this Weaponsmith
can do better** confirmation. Above-cap stock uses the separate wasted-grade confirmation.

## Exact recipes

All entries consume the selected samples and the shared actual-tier essence cost. “Timber/bone” is
an OR family, not two required categories.

| Recipe ID | Output | Required selected samples | Previewed lean |
|---|---|---|---|
| `weaponsmith_fitted_point` | pierce · close | 1 hard ≥65; 1 flexible ≥55; 1 lustrous OR dense ≥40 | Finesse |
| `weaponsmith_fitted_edge` | rend · close | 1 hard ≥65; 1 flexible ≥55; 1 reactive OR lustrous ≥40 | Finesse |
| `weaponsmith_fitted_maul` | crush · close | 1 dense ≥70; 1 hard ≥55; 1 flexible ≥45 | Might |
| `weaponsmith_fitted_polearm` | chosen pierce/rend/crush · mid | 1 chosen head property ≥65; 1 Timber OR Bone with flexibility ≥55; 1 flexible binding ≥55 | Finesse for pierce/rend; Might for crush |

For the polearm, the player first chooses the physical output kind. That choice determines the head
qualification: hard for pierce, hard for rend, dense for crush. The selected head still participates
in the ordinary weakest-input/average grade calculation; “chosen kind” never grants a free damage
conversion. If one sample could satisfy multiple parts, inventory quantity and stable sample identity
must still support every selected part independently.

## Preview and commit

Preview must show recipe, output kind/reach, intended stat lean, each selected sample, natural tier,
station cap, actual output tier, discounted essence/resource debit and every applicable confirmation.
The lean is advice derived from the ordinary combat rule—crush uses Might; pierce/rend use Finesse—not
a bonus or hidden modifier.

Commit is atomic and rejects a stale preview if the station tier, pattern/root knowledge, Home keeper
discount, chosen output kind, selected samples or their quantities changed. A failed or cancelled
commit consumes nothing. Successful construction creates one stable gear instance with the exact
construction receipt used by the Recycler and starts at reforge rank 0.

## Required fixtures

1. A newly built tier-0 Weaponsmith can make Fitted point with qualifying stock; an already-built
   migrated save gains the root once and no resources are charged.
2. Tier 0 hides/locks edge and maul; effective tier 1 opens both without raising the cap above 3.
3. Tier 2 alone permits Tier 4, and below-headline versus wasted-grade confirmations remain distinct;
   keeper-earned tier satisfies the same rungs without false paid history.
4. Each fixed family resolves its triangle kind, close reach and stat lean exactly.
5. The diary pattern survives learning-before-building and save/load; polearm remains unavailable
   without both the built station and the known pattern.
6. All three polearm kinds use mid reach and require the matching head property; a thrown weapon is
   never produced by this recipe.
7. Exact-sample replacement, duplicate-quantity validation, Home discount and stale commit rejection
   behave like the shared physical-construction engine.
8. Output has no wearer/fit field or equip restriction, and its cumulative receipt recycles only
   actual selected construction samples.

## Complexity guard

Do not add a fit meter, character-specific weapon copies, permanent wearer choice, animation-speed
stat, fatigue resource or bespoke polearm stance. If later play needs a stronger fitting decision,
first prove that the existing damage kind, reach, material grade and visible Might/Finesse lean do not
already create it.
