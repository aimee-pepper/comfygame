# Audit — what the pressure variables actually DO

**The question Aimee asked, and should have been asked much earlier:** every pressure variable exists to shape world generation and what's found in it. What do they actually shape?

**The answer: almost nothing.**

---

## 1. The finding

`PressureReadings` — all 8 targets, their aspects, forms and tags, produced by 41 sources through cross-target constraints — has exactly **three consumers**:

| Consumer | What it does with pressures |
|---|---|
| `DescriptionRules` | Writes the prose sentence |
| `ContradictionRules` | Fires named contradictions |
| `SiteRules` | Decides which sites are eligible |

**That is the entire list.** Terrain, flora, fauna, loot, encounters and map layout **do not read pressures at all.**

### What actually generates world content

From `Worldgen.swift`, everything comes from **old symbol fields**:

| Content | Driven by |
|---|---|
| Map size | `Tuning.World.gridWidth/Height` — a constant, not a pressure |
| Terrain layout | `layoutRNG` — seed only, no pressure input |
| Resource nodes | `symbol.yieldModifiers` — flat per-symbol multipliers |
| Node density | average of `yieldModifiers` values |
| Enemy species | `BookRules.enemyTable` ← `symbol.enemyTableModifiers` |
| Enemy count | `BookRules.enemyTier` ← `symbol.enemyTierDelta` |
| Loot | flat tables on creatures and resources |

So the pressure model is a **parallel system that describes worlds it does not generate.** A world can read "frozen over, barren, nothing keeps time" while its actual spawns come from a `verdant` symbol's `paper_moth: 0.6` modifier.

**This is why the descriptions felt disconnected from the worlds.** They *are* disconnected. Not a bug — an architecture gap I created by speccing downstream effects and never checking they were wired.

### What the specced downstream tables are worth today

Every "content pressures" table in `pressure-model.md` — cold pushing size and covering, openness setting ambush vs. pursuit, light driving sensory allocation, dispersion creating oasis structure, the energy budget, the cross-target constraints — **is unimplemented design intent.** `WorldConstraints` runs, but it only edits readings; nothing downstream reads the result except prose, contradictions and site eligibility.

---

## 2. The second finding: variables specced without checking they fit the run

Cycle is the clearest case but not the only one. **I specced temporal behaviour for a game whose runs are ~200 turns on a 14×14 grid** — a day/night cycle has no room to happen.

Anything I wrote as a **rate or a cycle** has the same problem:

| Variable | Specced as | Fits a 200-turn run? |
|---|---|---|
| Cycle: period | Length of a day/season | **No** — nothing turns in one run |
| Cycle: amplitude | How much conditions swing across the cycle | **No** — nothing to swing across |
| Cycle: regularity | Erratic ↔ metronomic | **No** |
| Illumination: dynamic range | "Day and night are meaningfully different runs" | **No** — there is no night |
| Thermal: swing | "Day and night are meaningfully different runs" | **No** |
| Thermal: seasonal morphs | Creatures with seasonal states | **No** |
| Hydrology: seasonal flood, tidal | Tags implying change over time | **No** |

**Roughly a fifth of the pressure model describes change over time in a game where nothing changes during a run.**

---

## 3. The three ways out (Aimee's call)

**A. Bigger maps, more turns.** Cycles become real — night falls, conditions shift mid-run. Costs: longer runs, fights the short-session pillar, stability must buy far more turns.

**B. Cycles become world *character*, not events.** A high-amplitude world isn't one that swings while you watch — it's one whose inhabitants are *built for* swinging: generalists, dormancy traits, relict features, storage organs. Keeps runs short; loses the drama of nightfall. **Everything drafted for Unwinding already works this way** (evidence of a rhythm, not the rhythm itself).

**C. Rescale the unit.** A "day" is a handful of turns rather than a real cycle, so night falls two or three times per run. Tactical without lengthening anything.

These aren't exclusive — C for Illumination and Thermal, B for Cycle, would give you nightfall *and* keep the slow stuff as character.

---

## 4. What has to happen regardless

**Wire pressures into generation.** Until content derives from readings, the eight targets are decoration. Minimum:

1. **Resource nodes** from Substrate composition + richness + dispersion, not `yieldModifiers`.
2. **Creature spawns** from Vitality, trophic depth, and the trait pressures — currently three hand-authored creatures with flat stats.
3. **Terrain layout** from Relief: elevation range, openness, verticality. Openness in particular is specced to set ambush-vs-pursuit and does nothing.
4. **Loot** from creature traits, once traits exist.
5. **Map size** possibly from Relief too, rather than a constant.

**And the old symbol fields should go** once pressures drive generation — `yieldModifiers`, `enemyTableModifiers`, `enemyTierDelta` are the parallel system keeping the real one decorative.

---

## 5. Process failure, stated plainly

I specced eight targets, dozens of aspects, tags and downstream tables, and validated them by reading the sentences they produced. I never checked that any of it reached generation, and never sized any of it against run length. **The description panel was the easiest consumer to build, so it became the only one — and I mistook it for the system working.**

Every variable from here gets two questions before it's written: **what reads this**, and **does it have room to matter in a 200-turn run?**
