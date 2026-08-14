# Essence refining progression audit — current

**Status:** accepted by Decision 186; retained as rationale and implementation acceptance for
`essence-refining-progression-current.md`.  
**Reason:** the requested refining progression should reward participation, not teach the player that
using the opening conversion rate was a mistake.

## Audit finding

Raw Essence currently has exactly one legitimate use: conversion into refined Essence. It cannot be
traded, written with, spent as an ordinary world resource or used in recipes directly.

Therefore the proposed **Measured batches** research node does not unlock a strategic choice worth
20 Essence + 4 Pulp. A quantity selector is baseline transaction safety/accessibility. Before the
3:1 upgrade, refining less than the available amount matters mainly because already-held Raw benefits
from the future rate. The branch accidentally creates this lesson:

> Refining at the opening rate destroys future value; hoard as much Raw as continuation permits.

That conflicts with the continuation design, makes the 2:1 rate feel punitive, and turns the first
“skill” into permission to optimize around a later skill.

## Accepted correction

### Baseline Spring capability — not a research node

Moving the Refinery interaction to the Essence Spring remains recommended. At tier 0 it includes:

- exact quantity selection;
- **Refine selected** and **Refine all**;
- exact 2:1 preview and before/after runway;
- atomic stale/cancel/interruption behavior.

This is ordinary control over a destructive conversion, not progression. Remove the 20-Essence
Measured batches purchase rather than renaming it into a cosmetic toll.

### Second pass — earned efficiency root

Keep the legible 2→3-per-Raw upgrade and current provisional 80 Essence + 10 Quartz price, but add a
DEBUG-tunable **lifetime Raw refined** practice gate. Start comparison at **50 Raw refined**.

- increment the stable lifetime counter only on committed manual/automatic conversions;
- old saves decode the counter as zero unless exact historical receipts exist—do not infer it from
  current Essence or expedition count;
- the node detail says **“Refine 50 Raw Essence first”** and shows progress;
- current held Raw may benefit after purchase, but the player has already used the baseline route
  substantially to qualify;
- the counter is practice evidence, not a spent currency and never decreases.

Fifty Raw is roughly three to four well-explored Recommended-profile worlds. The existing 80-Essence
price then retains its roughly five-to-six-future-world payback. Both values remain tuning, but the
structure ensures the upgrade arrives after baseline experience rather than before it.

### Continuous settling — convenience child

Keep the current outcome-safe auto-refine toggle after Second pass and Spring tier 1. Its effect,
receipt and provisional cost remain unchanged. It automates a proven action; it does not improve
yield or process stored Raw retroactively.

### Deepen the Spring — parallel return branch

Keep `deepen_spring` as a sibling choice that improves return dividend, detached from shelving. It
does not satisfy the lifetime-refined practice gate and does not alter the conversion rate.

The resulting small graph is honest:

```text
Spring tier 0: selected/all 2:1 refining
        │
        └── Second pass (practice + cost): 3:1
                    │
                    └── Continuous settling: auto-refine new retained Raw

Deepen the Spring: parallel return-income choice
```

There are still multiple meaningful refining/Spring unlocks: efficiency, automation and return depth.
The branch simply stops selling a basic quantity control as character growth.

## Why not protect old 2:1 transactions retroactively

Retroactive compensation would require reconstructing every historical Raw conversion or granting a
guess from current Essence, both of which can fabricate value. The practice gate prevents the worst
hoarding incentive without pretending earlier choices were economically identical. The better rate
is a future reward once earned.

## Alternative rejected for now

Do not add a small percentage-yield node merely to preserve three boxes in one line. A hidden +5–10%
bonus is hard to read, introduces rounding/remainder state and makes the later integer rate less
legible. If play later reveals a missing middle step, add a new operation or decision with its own
purpose—not filler throughput.

## Acceptance

1. A fresh save can refine any selected legal quantity at 2:1 without research.
2. The lifetime counter advances by exact Raw consumed, once per atomic commit and once per automatic
   outcome; cancelled/stale/failed actions add zero.
3. Second pass cannot be purchased before both practice and material/Essence cost are satisfied.
4. Held Raw gains the new rate only after purchase; previously refined Raw is not recomputed.
5. Continuous settling remains once-per-outcome and uses the active rate.
6. The Spring graph shows the two-node refining route and parallel Deepen choice without a fake
   placeholder node.
7. Storehouse, recap, Writing Desk runway and DEBUG report all read one rules-owned active rate and
   lifetime counter.
8. Ten-return telemetry reports the unlock world, Raw refined before/after, price, payback and whether
   the player delayed necessary binds to hoard Raw.
