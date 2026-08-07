# Code Audit #2 (2026-08-05, commit `945eda1`)

285 tests, up from 200. Everything previously reported is fixed. New findings below.

---

## 1. Fixed since the last audit

| Issue | Status |
|---|---|
| Description revealed rolled content | ✅ The desk now passes only the targets the page **actually touches**, secondaries included. Blank page → nothing said. |
| Contradictions cost nothing | ✅ `stabilityScore` now subtracts `contradictionPenalty`, base plus disclosed escalation. |
| `holds ~9999 turns` sentinel | ✅ Gone. |
| Q17 — ruins paying essence | ✅ All three ruin types at 0; landmarks and living sites keep theirs. |
| Gambit modal sheet | ✅ Rebuilt: numbered list, one row per rule, tappable segments, drag to reorder, mute without deleting. |
| Research as lists | ✅ Real trees — nodes tiered by depth, curved edges to prerequisites. |
| Forge branch | ✅ Removed. Gear derives from what's worn; sites carry it, ruins carry the best. |
| Session 11 exclusivity | ✅ `PageRules.exclusivityConflict` — one primary per target, lifted by a single chaining unlock. |
| Session 11 sectioned palette | ✅ Sectioned by pressure target. |
| Session 8 analysis gating | ✅ Red/green underlining behind `description.showsAttribution`. |

**Also built, unprompted and correctly:** the Library — travellers present by condition signature, diary pages with weighted placement, and hint pages that expose only known passages plus the shape of what's missing. Matches session 7 including the "collects, never interprets" rule.

---

## 2. Open — the big one, already reported

**Pressures still don't drive content generation.** `Worldgen` reads readings for **sites, diary pages and travellers** — genuinely more than last time — but resource nodes and enemies still come from `yieldModifiers`, `enemyTableModifiers` and `enemyTierDelta` on the old symbols.

So the eight targets shape *where things are found* and *who is there*, but not *what the world is made of or what lives in it*. `audit-what-pressures-actually-do.md` covers this; it's in the current handoff and hasn't been actioned yet.

---

## 3. New findings

### 3.1 Icons are still SF Symbols — session 11 §4 not actioned
`mountain.2`, `leaf`, `snowflake`, `water.waves`. Session 11 asked for icons representing the **rune's shape**, with the interim guidance that a wrong-but-glyph-shaped placeholder beats a correct-looking app icon. Not started.

This one has knock-on effects for session 14: with clusters as single objects and outlines marking connections, pictographic app icons will read even less like writing than they do now.

### 3.2 The old symbol layer is now doing three jobs at once
`SymbolDef` currently carries: pressure expansion (`expandsTo`, `primaryTarget`), legacy content drivers (`yieldModifiers`, `enemyTableModifiers`, `enemyTierDelta`), and danger-rune data (`danger.tierDelta`). Two of the three are meant to disappear once pressures drive generation.

Worth flagging now because **exclusivity and the palette both key off `primaryTarget`**, which lives on this same object. When the legacy fields are removed, that has to survive the surgery.

### 3.3 Danger runes route tier through two paths
`BookProjection` reads `$0.enemyTierDelta + ($0.danger?.tierDelta ?? 0)` — the comment says danger runes carry their shift on the profile "rather than on `enemyTierDelta`", but the code sums both. Harmless today because danger runes leave `enemyTierDelta` at 0, but it's a place where a future edit could silently double-count.

### 3.4 Session 13 not yet reflected — expected
Map is still `Tuning.World.gridWidth/Height` constants; no day/night, no minimap, no world-size variable. Session 13 is in the current handoff.

---

## 4. Suggested priority

1. **Wire pressures into generation** (§2) — until this lands, most of the design is decoration.
2. **Session 14 grammar** — in progress.
3. **Session 13 map/day scaling** — needed before Cycle or Illumination range mean anything.
4. **Glyph placeholders** (§3.1) — cheap, and it makes the page read as writing.
5. **Retire the legacy symbol fields** (§3.2) once §1 lands, protecting `primaryTarget`.
