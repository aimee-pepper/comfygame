# Encounter scaling playtest — current

Status: current diagnosis and reversible test direction, 10 August 2026. No candidate coefficient
is promoted to final balance without Aimee's play result.

## Diagnosis

The live encounter path correctly derives an upper-median level from the Binder and every valid
active party member. That fixes the older single-companion correctness bug.

However, the default DEBUG profile previously labelled **Current live balance** maps to no
party-size scaling profile. Under it:

- additional party members do not add ordinary encounter budget;
- apexes receive no party-size HP or offence multiplier;
- apexes receive only one action slot regardless of party size.

Therefore an apex feeling far too easy with a developed large party is expected behavior under the
legacy profile, not merely an unlucky creature roll.

## Immediate playtest choice

Use **B · Recommended start** for the next deliberate combat comparison. It preserves visible map
foes and converts any missing group budget into bounded foe-level pressure rather than inventing
off-map enemies. Its reversible starting profile is:

- ordinary budget: `1 + 0.5 × each additional party member`;
- apex level floor: upper-median party level +2 after world scaling;
- apex HP: +35% per additional member, capped at 2.4×;
- apex offence: +10% per additional member, capped at 1.4×;
- apex actions: 1 for parties of 1–2, 2 for 3–4, 3 for 5.

The DEBUG encounter report already records party levels, upper median, visible foe IDs, budget,
level adjustment, apex floor/multipliers/action slots, and final foe stats. Values freeze when the
encounter begins and persist across relaunch.

## Promotion gate

Compare at least:

1. one ordinary encounter and one apex with a two-person party;
2. one ordinary encounter and one apex with the largest currently practical party;
3. whether the apex creates meaningful pressure without one-hit defeats or an exhausting HP wall;
4. whether extra apex actions choose legible targets and remain readable on the phone stage.

If Recommended is consistently closer, promote it deliberately as live/default balance in a named
checkpoint. Until then the selector calls the old option **Legacy · level only** so it no longer
conceals what is absent.

