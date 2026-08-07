# Code Audit #6 (2026-08-05, commit `5af8db2`)

413 tests. The last handoff (combat depth, stacking, storage) hasn't been picked up yet — expected, not a finding.

One real issue, and it's a balance problem that makes low-stability worlds unplayable rather than merely short.

---

## 1. THE FINDING — the turn budget was never rescaled for the bigger map

Session 13 grew the map from 14×14 to 18×18 and stated: *"Stability must buy proportionally more turns so runs aren't cut short simply by the map growing."*

**The map grew. The bands didn't.**

```
turnsAvailable = stabilityScore × bandMultiplier
bands: ≥76 → ×4 · ≥51 → ×3 · ≥26 → ×2 · ≥0 → ×1
```

Area went from 196 tiles to **324** — a 1.65× increase — with no change here.

### What that means in practice

With `baseVisionRadius = 3`, thorough exploration of 324 tiles needs roughly **100+ turns** of walking, before any turns spent harvesting.

| Stability | Turns | What you can actually do |
|---|---|---|
| 25 | **25** | Can't cross the map once. You see maybe 15% of it. |
| 26 | 52 | A corner |
| 50 | 150 | A decent run |
| 76 | 304 | Thorough |
| 100 | indefinite | — |

**The bottom band is the problem.** 25 turns on an 18×18 map isn't a short run, it's an arrival and an ejection. A player writing a greedy world doesn't get a tense scramble — they get nothing, which reads as the game being broken rather than as a consequence they chose.

### Interaction with day/night

`turnsPerDay = 40`. So:
- Below stability 26, **you never see a night** — the whole day/night system, the nocturnal roster swap and Illumination's dynamic range are invisible on exactly the worlds most likely to be interesting.
- At 50 you get three or four turns of the cycle, which is about right.

### Suggested fix **[PLACEHOLDER]**

Multiply the bands by roughly the area increase — ×7 / ×5 / ×3.5 / ×2 — giving 175 / 130 / 91 / 50 turns at the same scores. That restores the pre-growth feel and guarantees even the worst band sees one full day.

Or set the bottom band by a floor rather than a multiplier: **no run should be shorter than one day plus a traverse** (~60 turns), whatever its stability. A greedy world should be *dangerous*, not *pointless*.

**Either way this needs testing on device rather than arithmetic — the numbers above are a starting point, not a recommendation.**

---

## 2. Legacy paths — partly retired, one live

- **`yieldTable(from: readings)` is the live path** in `Worldgen`, and the preview no longer uses the legacy per-symbol version. The audit-#3 concern that preview and world could disagree on harvest is **resolved**.
- **`enemyTable(for book:)` (legacy) is now dead** — defined at `BookRules.swift:327` and called nowhere. Safe to delete along with `enemyTableModifiers`.
- **`yieldModifiers` is still read** at `BookRules.swift:315` and `BookProjection.swift:248`. Worth checking whether that path is still reachable now that readings drive yields; if not, it can go with the rest.

Not urgent, but the longer both systems exist the easier it is to edit the wrong one.

---

## 3. Still unbuilt (all specced and handed over)

Stacking and storage tiers · combat depth (gear still has no damage type) · flora · predation · anchoring's three routes · crafting · named places · companions · the crystal currency.
