# Code Audit #3 (2026-08-05, commit `5ea9b3a`)

329 tests, up from 285. **The central gap from `audit-what-pressures-actually-do.md` is closed.**

---

## 1. Pressures now drive generation

The finding two audits ago was that `PressureReadings` fed only prose, contradictions and sites. That's fixed:

| Consumer | Now driven by |
|---|---|
| **Terrain** | `TerrainRules.paint(&map, readings:)` — the ground itself, before anything is placed on it |
| **Resource nodes** | `BookRules.yieldTable(from: readings)` and `nodeCount(for: readings)` — reads Substrate and Vitality |
| **Enemies** | `BookRules.enemyTable(from: readings)` and `enemyCount(for:readings:)` |
| Sites, pages, travellers | readings (already were) |

**Terrain exists**, as specced: `GroundType` (stone · soil · sand · ice · ash · water · deepWater · rubble · growth · void) plus `elevation` 0–3, orthogonal to `content`. `deepWater` and `void` are impassable; **`growth` and `rubble` block sight** — which is what makes ambush terrain real rather than a word in a description.

Session 13 is largely in too: **grid at 18**, day/night with `isNight` and a **nocturnal roster swap**, and a `MinimapView`.

---

## 2. `WorldProfile` was not built — and that's defensible

The spec proposed an intermediate `WorldProfile` between readings and worldgen. He wired readings **directly** into each generation step instead.

Fine for now: fewer moving parts, and the seam exists conceptually. Worth revisiting only if generation steps start needing to agree with each other (e.g. flora placement needing to know what terrain painting decided). Flagging so the omission is deliberate rather than forgotten.

---

## 3. Still open

### 3.1 Creature traits — the remaining big one
`WorldConstraints` computes **world-level trait tags** (`pursuit`/`ambush`, `wet-cold`/`dry-cold`, `arid-syndrome`, `iridescence-enabled`) — the pressures are ready. But creatures themselves are still authored entries with flat stats.

**Nothing of session 15 exists yet**: no cast sampling, no per-spawn jitter, no species/specimen split, no Vitality-driven cast size, no free-sampled identity. This is now the largest unbuilt system, and combat behaviour and trait-derived loot both sit behind it.

### 3.2 Legacy symbol fields still present
`yieldModifiers` and `enemyTableModifiers` remain on `SymbolDef` and are still read by `BookProjection` for the preview, even though worldgen no longer uses them for generation. So **the preview and the actual world can now disagree** — the preview averages old per-symbol modifiers while the world is built from readings.

Worth checking whether the projection's expected-harvest numbers still match what a bound world produces.

### 3.3 Session 15 not yet reflected
Expected — it's in the current handoff.

---

## 4. Suggested priority

1. **Creature traits + cast/jitter sampling** (session 15) — the last big generation gap.
2. **Traits → combat behaviour**, then **traits → loot**. Both blocked by 1.
3. **Reconcile the preview with generation** (§3.2) and retire the legacy modifier fields.
4. **Flora**, including `growth` placement from Vitality — the ground type exists but needs a producer.
