# Essence continuation economy — current design

**Status:** Current invariant; temporary playtest values pending run data  
**Updated:** 9 Aug 2026

## Problem confirmed in playtest

This is not adequately explained by an unlucky world. The live default places 2–4 Raw Essence
drops worth 1–2 units each. At the 2:1 Refinery rate that is 4–16 refined Essence if every drop is
found, averaging 9. The base Spring adds 3 on return, for an average gross return of roughly 12.
That barely covers the 10-Essence blank-page bind and cannot reliably support an ordinarily authored
world, much less make Essence available for crafting, research or other discretionary uses.

`ensureDepartureIsPossible` remains a valid last-resort anti-lock rule, but reaching that subsidy
regularly is evidence of an economy failure. A blank random world is an emergency exit, not the
intended campaign loop.

## Settled continuation rule

A reasonably explored ordinary world should normally fund another **ordinarily authored** world.
It need not fully refund a highly specified or deliberately expensive book. Exploration matters,
but the player should also accumulate a modest surplus over several successful expeditions for
optional Essence spending.

These roles remain separate:

- Raw Essence found in worlds is the principal renewable income and reason to explore.
- The Essence Spring provides a small visible return dividend and the existing exact anti-lock
  shortfall only when the player truly cannot afford the cheapest bind.
- Precision remains a real net cost; expensive books are allowed to draw down savings.
- Sites and ordinary world-resource nodes do not become additional disguised Essence sources.

## Temporary recommended profile

For the next playtest checkpoint, use **5–7 dedicated Raw Essence drops worth 2–3 units each**.
At the existing 2:1 refinement rate plus the tier-0 Spring return, a fully explored world returns
23–45 Essence, averaging 33. This is intentionally reversible and should be exposed as the middle
DEBUG economy profile rather than presented as final balance.

Compare three profiles without changing the settled acquisition grammar:

| Profile | Drops | Raw per drop | Average refined + Spring |
|---|---:|---:|---:|
| Lean | 4–6 | 2–3 | 28 |
| Recommended | 5–7 | 2–3 | 33 |
| Generous | 6–8 | 2–3 | 38 |

The current 2–4 × 1–2 profile should remain available only as a diagnostic legacy comparison.

## Placement and measurement requirements

- Dedicated drops must remain separate from ordinary resource-node draws.
- At least one Raw Essence drop must be reachable within the explored connected component without
  defeating an apex or crossing an impassable barrier. This is not a minimap disclosure rule.
- Fog of war continues to conceal Raw Essence until normally revealed.
- World diagnostics record eligible tiles, placed drops and obtainable Raw Essence as they do now.
- The return report/debug export should additionally record Raw Essence collected, refined-value
  equivalent, bind cost paid, Spring yield and net Essence runway.
- A useful headline is **ordinary authored binds available**, calculated from current spendable
  Essence and the campaign's recent median non-blank bind cost. Do not imply that the 10-Essence
  blank minimum represents a healthy runway.

## Playtest questions

Revisit the temporary profile after at least ten ordinary returns spanning partial and thorough
exploration:

1. Can Aimee usually author the next world without invoking the anti-lock subsidy?
2. Does precise writing still feel meaningfully expensive?
3. Does optional Essence spending feel possible without making it consequence-free?
4. What percentage of obtainable Raw Essence is actually collected before a normal portal exit?
5. Does finding 5–7 pickups feel pleasantly exploratory or visually repetitive?

