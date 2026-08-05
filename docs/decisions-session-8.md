# Decisions Log — Session 8 (2026-08-05)

Append to `docs/decisions-log.md`. All decisions here are Aimee's.

---

## 1. Correcting a premise Claude repeated

Claude has repeatedly written that **opacity was Mystcraft's real failure** and designed around "fixing" it. **That is wrong and should be struck from the docs wherever it appears** (`writing-system-rune-spec.md`, `pressure-model.md`, `contradiction-danger-spec.md` §6, `decisions-session-*`).

**Aimee, who played it:** opacity was the *joy*. Figuring out what your own writing had done to a world is the game, not a usability problem to be solved.

Design consequence: **do not front-load explanation.** The player is meant to write half-blind at first and learn by observing.

---

## 2. Implicit secondary effects — CONFIRMED, and **discovered, not printed**

A source bound to one target also affects others (Sun bound to Illumination also warms; Magma feeds Substrate; Canopy lowers Vitality's light ceiling). This stands — it's what makes the system causal rather than a set of sliders, and it's what gives contradiction something to negate.

**Secondaries are NOT listed on the rune.** A Sun rune does not read "light, and warmth." You write suns for a while and work out that your worlds keep coming out hot. That realisation is content.

---

## 3. Analysis is a third progression axis

Alongside **vocabulary** (what you can say) and **page space** (how much you can say), there is now **analysis** — how much you can *read*. Unlocked over the game, so the same book is a different object depending on how well you can read it.

**Rough tiers** (order decided; exact contents **[PLACEHOLDER]**):

1. **Qualitative only.** The world-description panel gives sensations, no numbers. "Frozen over. Little light."
2. **Targets become readable.** You can see where a world sits on illumination, thermal, and so on.
3. **Attribution.** Which sigils are responsible for what — *including secondaries*. This is where "the sun has been heating my worlds all along" clicks.
4. **Instability broken out.** Greed vs. contradiction, and which contributor is which. **The red/green underlining lives here**, not at the start.
5. **The living layer.** Trait distributions, why this world grows what it grows, predicted spawns.

**The world-description panel always *describes*; what it *attributes* grows with what you've unlocked.** That keeps its deduction job (matching a clue's description to a world's description) intact from the very beginning, while attribution is earned.

---

## 4. Instruments — analysis is crafted, not researched

Analysis comes from **instruments**, crafted from materials, mirroring how pens and inks gate writing. Reading and writing are symmetrical: both crafted, both material-gated.

### 4.1 Field instruments — measure a world you're standing in

- Carried into a world; take readings **after generation**.
- **Per-target** — a thermometer reads thermal, a hygrometer reads water, and so on. More of them, collectible, each needing materials with matching properties.
- **Grade matters.** A fine instrument reads more precisely than a crude one. This gives material grade a job beyond gear.
- **[OPEN]** whether they occupy gear slots or have their own carry allowance.

### 4.2 The page lens — predict before you spend

- A desk instrument. Shows the impact of runes **as you build and change the page**, so you can calibrate before binding and stop wasting materials on experiments.
- Later-game. Its arrival is a real progression beat: you stop discovering what you made and start deciding it.
- **The lens only shows you what you have already measured.** Field readings *feed* it. So field work and prediction are **one progression**, not two systems — early measuring is visibly building toward something.
- Field instruments aren't made worthless; they're superseded gradually, target by target, as your readings accumulate.

### 4.3 Readings are permanent knowledge

**Field readings become permanent, like specimens.** Measuring thermal in a volcanic world teaches you about volcanic worlds generally.

Same storage rule as the bestiary: **store the observation, derive the meaning.** Readings live in the Reality layer and are never taken away — consistent with "knowledge is never taken back."

This connects readings to the specimen model directly and means the analysis axis is built on machinery that already exists.

---

## 5. Consequences for existing docs

- `contradiction-danger-spec.md` §6 — the description panel's red/green underlining is **tier 4**, not a starting feature. The panel still ships early, describing only.
- Any doc claiming the game should explain instability up front — revise. Explanation is earned.
- `materials-crafting-spec.md` — instruments join pens, inks and book covers as crafted goods. The Blacksmith and Apothecary are the likely makers; **[OPEN]** whether a dedicated station is wanted.

---

## 6. Open

1. Do field instruments take gear slots, or a separate allowance?
2. Which building crafts instruments?
3. Do instrument *grades* map to the analysis tiers, or are tiers separate unlocks that grade only sharpens?
4. Can readings be shared/traded, or found in ruins as someone else's notes?
