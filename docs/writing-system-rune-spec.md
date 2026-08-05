# The Writing System — Rune Vocabulary Spec (v1 draft)

**Purpose:** a complete rune vocabulary to illustrate from, plus the grammar that assembles them. Everything marked **[PROPOSAL]** is my call where the design hadn't decided; overrule freely. Everything else follows from decisions already made.

**Scale note:** for calibration, Mystcraft's structural vocabulary is roughly 100 symbols, but with one page per block and per biome its real total runs into the several hundreds. This spec lands at **156 base runes**, which is the right order of magnitude for the richness we want. Vocabulary size is driven by what the world model needs to express — not by asset budget.

---

<details>
<summary><b>1. Principles</b></summary>

1. **Runes are causes, not settings.** You write a sun, not a light-level. The simulation derives pressures from causes, and pressures shift trait distributions. Players write poetry; the game does physics.
2. **Space is the only constraint.** Every discovered rune stays writable forever. The page limits how much you can say, never what you're allowed to say.
3. **Depth vs. breadth is the core tension.** The same page can hold one richly specified condition or four coarse ones. Neither is correct.
4. **Refinement is literacy, not power.** Better instruments and learned compounds let you say the same thing in less space. They never unlock meanings.
5. **Sigils are self-contained.** A sigil is assembled from components internally, then placed on the page as one unit. No page-wide adjacency effects, no accidental interactions between neighbors.
6. **Nothing on the page is hidden from the player except unidentified compounds.** Cost is exact; outcomes are ranged.

</details>

<details>
<summary><b>2. The three tiers</b></summary>

**ONE ALPHABET, THREE HANDS.** Every rune has a single canonical form that never changes. What changes is the *instrument it's drawn with*. This is a font change, not a new symbol — recognition transfers instantly, and there is never any relearning.

| Tier | Instrument | Rendering | Footprint |
|---|---|---|---|
| **Crude** | Burnt stick / charcoal | Thick, blunt, uneven strokes; visible grain and crumble; wobbling lines. | 4–6 cells, irregular shapes |
| **Plain** | Pencil | More control, still loose and sketchy; visible construction lines, slight overshoot at corners. | 2–3 cells, simple shapes |
| **Refined** | Fountain pen | Precise and beautiful; fine consistent line weight, clean joins, confident terminals. | 1 cell, always a single square |

**Why size differs is now physical, not symbolic:** charcoal cannot render fine detail, so the same mark must be drawn large to stay legible. The glyph is constant; the tool sets the minimum size at which it survives. This is more coherent than tying size to symbol complexity, and it means the player is always reading the same script.

Consequences:
- **Refinement dissolves the packing puzzle.** At refined tier every rune is 1×1, so late-game pages are pure design freedom while early-game scrawl genuinely fights you.
- **The same book rewritten later looks like a different document** — the same words in a better hand. Strong visual progression, and a real reason to revisit old work.
- **A page can mix hands.** You write in whatever hand you have.

**Production note:** because the form is constant, it may be possible to draw each rune **once** as a vector and render the three hands programmatically (rough charcoal stroke / sketchy pencil / fine ink). Worth testing on a few runes before committing to 3× the drawing. If it works, asset load drops to ~156 drawings rather than 395.

**Which runes need which hands:** all of them, in principle — it's a font. If hand-drawing each separately, Structural runes can stay tier-invariant (they're punctuation, and minimal marks change least between instruments).

**Open:** whether a 4th hand is wanted late-game (gold pen / master's). I'd hold at 3 — the instruments need to be visually distinguishable at a glance, and compounds already provide unlimited further compression.

</details>

<details>
<summary><b>3. The page and footprints</b></summary>

- **Page is a grid.** Starting size **[PROPOSAL] 6×6 (36 cells)**, expanded by permanent (Reality/base) unlocks. Page size = what you're *capable* of writing.
- **Essence remains the per-bind consumable** — whether you can afford to write it today. Two different pressures, both kept.
- Footprints per tier as in §2. Crude shapes are irregular *on purpose*: the scrawl is awkward to fit.
- **Compound footprint:** less than the sum of its parts. **[PROPOSAL]** `ceil(sum × 0.6)`, so compounds are always worth learning but never free. Compounds have their own tiers and compress further.
- **Unwritten targets** cost the flat cheap rate (already decided) and are rolled at bind. A target explicitly marked with the **Wild** rune is the same thing said deliberately.

</details>

<details>
<summary><b>4. TARGETS — the world's dials (8)</b></summary>

Few and fixed. Every sigil attaches to exactly one target. These are the pressure axes the simulation reads.

| Rune | Governs |
|---|---|
| **Illumination** | How much light, from what, and when |
| **Thermal** | Temperature and its extremes |
| **Hydrology** | Water: how much, what form, where |
| **Substrate** | What the ground is made of; mineral richness |
| **Relief** | The shape and openness of the land |
| **Vitality** | How much life the world can support |
| **Atmosphere** | Air: density, wind, weather |
| **Cycle** | Time: day length, seasonality, constancy |

*Illustration note:* targets should read as **containers or receptacles** — the thing a cause is poured into. Visually distinct as a class from sources, since every sigil pairs one of each.

</details>

<details>
<summary><b>5. SOURCES — concrete causes (86)</b></summary>

The flavorful nouns, and the set that grows forever. Each attaches to a target.

**Celestial (12)** — Sun · Moon · Stars · Starfield · Comet · Meteor · Aurora · Eclipse · Ring · Shattered Moon · Void (starless dark) · Second Light (an unexplained glow)

**Water (12)** — Sea · Lake · River · Rain · Mist · Ice · Glacier · Snow · Geyser · Spring · Marsh · Waterfall

**Fire & Thermal (10)** — Volcano · Magma · Ember · Wildfire · Hot Spring · Fumarole · Ash · Cinder · Smoke · Heartfire (a hot world-core)

**Stone & Mineral (18)** — Granite · Basalt · Limestone · Chalk · Clay · Sand · Salt · Crystal · Quartz · Obsidian · Iron · Copper · Silver · Gold · Lead · **Mercury** · Sulfur · Adamant

**Air (8)** — Wind · Gale · Stillness · Cloud · Thunder · Weight (dense air) · Thin Air · Miasma

**Living (14)** — Root · Bloom · Grass · Canopy · Fungus · Moss · Vine · Thorn · Coral · Kelp · Swarm · Hive · Herd · Rot

**Strange (12)** — Bone · Amber · Tar · Glass · Mirror · Silk · Chitin · Ruin · Echo · **Song** (resonant stone) · Dream · Rift

*Notes:* Mercury and Song are here because you named them — mercury ponds and singing stone. The Strange set is where rare/late vocabulary lives and where the most evocative worlds come from; expect it to grow most.

*Illustration note:* sources are the **pictographic heart** of the script. Crude tier should look like something a frightened person drew on a wall.

</details>

<details>
<summary><b>6. QUALIFIERS — modifiers (51)</b></summary>

Small, reusable, and where combinatorial richness comes from cheaply. Attach to sources inside a sigil.

- **Intensity (5):** Absent · Faint · Moderate · Great · Overwhelming
- **Scale (4):** Minute · Small · Large · Vast
- **Count (5):** Single · Pair · Few · Many · Countless
- **Constancy (4):** Constant · Cyclic · Seasonal · Erratic
- **Elevation (4):** Sunken · Low · High · Aloft
- **Direction (4):** North · East · South · West
- **Phase (4):** Frozen · Solid · Liquid · Vaporous
- **Distribution (4):** Scattered · Clustered · Banded · Uniform
- **Color (12):** Red · Orange · Yellow · Green · Cyan · Blue · Violet · Magenta · White · Black · Grey · Pale
- **Finish (5):** Dull · Bright · Glassy · Metallic · Iridescent

*Finish maps to the creature/material finish system, so a world's light and mineral character can bias iridescence — the coupling the biology research recommended.*

*Illustration note:* qualifiers should read as **diacritics** — marks that modify, subordinate to the source they attach to. Never compete visually with sources.

</details>

<details>
<summary><b>7. STRUCTURAL — grammar (11)</b></summary>

| Rune | Function |
|---|---|
| **Bind** | Attaches a source-assembly to a target. The core verb. |
| **Duplicate** | ×N multiplier. Cheaper than N copies at high N, more than one copy — a real crossover point. |
| **Negate** | Absence/without. Enables contradictions (see §8). |
| **Except** | Excludes a qualifier from an otherwise general statement. |
| **Group** | Brackets several components as one unit. |
| **Dominant** | This source overrides others on the same target. |
| **Trace** | This source is barely present. |
| **Then** | Sequence, for cyclic/seasonal statements. |
| **Anchor** | Page opening mark. |
| **Terminus** | Page closing seal. |
| **Wild** | Deliberately leaves a target to chance. |

*Illustration note:* punctuation, not pictures. Tier-invariant. Should look like they belong to the page rather than to any word — think brackets, ticks, seals.

</details>

<details>
<summary><b>8. Composition grammar</b></summary>

**A sigil = [qualifiers] → source → Bind → target.** Assembled internally, placed as one unit.

**[PROPOSAL] Implicit secondary effects — the most important rule here.** A source attaches to one target explicitly, but contributes *secondary pressures automatically*. A Sun bound to Illumination also warms the world. Ice bound to Hydrology also chills it. This is what makes the system causal rather than a set of sliders, and it means players discover real consequences: you cannot have bright without hot unless you do something about it.

**[PROPOSAL] Contradiction as an instability source.** You *can* write "a sun that does not warm" (Sun + Negate-thermal). The grammar permits it, the world will do it — and it is deeply unstable. This gives instability a second origin alongside abundance/greed: **greed destabilizes, and so do contradictions.** It also fits the Myst lore precisely (the Art's central discipline was avoiding contradiction) and gives advanced writers a reason to court danger deliberately.

**Multiple sigils on one target** stack and interact; Dominant and Trace let you weight them.

**On "does cold get its own rune?"** — **[PROPOSAL] composition is the general mechanism** (Thermal + Ice/Faint-Sun/etc.), *and* dedicated compounds exist as discoverable compressions. So "cold" as a single compact glyph is something you *learn*, not something you start with. Both answers, in the right order.

</details>

<details>
<summary><b>9. Compounds & the runebook</b></summary>

- A **compound** is a learned single glyph meaning what several components mean together, at a smaller footprint (§3).
- The **runebook** stores compounds — parameter combinations, not whole realms. Your personal signature forms.
- Compounds are acquired by: inventing them (composing something repeatedly, then formalizing it), finding them in the wild, learning them from diary pages, or from NPCs.
- **Diary pages teach rune forms.** A recovered page is both a clue to a person's location and a sample of their hand — studying it can teach a compound they invented. Named NPCs have distinct rune styles. This makes clues and writing knowledge the same loot.

</details>

<details>
<summary><b>10. Unidentified compounds — mechanics</b></summary>

Found in the wild; usable immediately, readable only through investigation.

**Known on sight:** its form, its footprint (so its complexity), and which target it binds to. Nicknameable in the runebook until identified.

**Identification is per-component**, not binary. A 3-component compound shows 3 slots, filled independently.

**The reveal rule — a component identifies when its contribution is *attributable*.** Compute each hidden component's marginal effect on the generated world; reveal it if that effect is observable and *not masked* by another source acting on the same target. Write the unknown rune beside your own ice sigils and frost tells you nothing. Write it on an otherwise sparse page and every anomaly is necessarily its doing.

This produces the behavior we want: **players invent controlled experiments.** A crowded page buys a good world; a sparse page buys information. It also makes "leave targets unwritten" strategically interesting rather than merely cheap — a sparse page is a laboratory.

**Observation costs runs.** Effects must be *seen*:
- **Strong effects** (a second sun, hostile flora, an impossible mineral) resolve on sighting.
- **Subtle effects** (slight moisture shift, a skew in creature trait distributions) accumulate **evidence across multiple bindings** — use the rune in varied contexts, notice the pattern. A **confidence meter per unknown slot** makes this progress legible.

**Payoff: identifying a component you've never seen grants you that base rune outright.** Wild compounds are the primary way rare vocabulary enters your hands, wiring the writing system into exploration. A rune found early can pay off much later.

**Preview behavior:** cost stays exact (page space is physical even for unknowns), but stability/danger/yield ranges *widen*, with explicit "unknown influence" markers. Unread runes may carry something destabilizing — early experiments are a real gamble.

**Compression is gated on knowledge.** An unidentified compound can't be rewritten more efficiently, because you don't know what it says. Identifying it lets you decompose, recompose, or rewrite it in your own hand — so identification literally buys page space.

**Other routes** (so it never dead-ends): a scholar NPC reads it for a price; the Library cross-references it against recovered diary pages; named NPCs recognize their own handwriting — finding a person can unlock the rune they invented.

**Duplicates** identify instantly once known.

**Edge case to watch:** a component whose only effect is on creature trait distributions needs enough bestiary specimens to reveal a skew. That's correctly slow, but the confidence meter is *required* or it will feel like nothing is happening.

</details>

<details>
<summary><b>11. Asset inventory & suggested illustration order</b></summary>

**Full vocabulary: 156 base runes** — 8 targets, 86 sources, 51 qualifiers, 11 structural.

Because the three hands are renderings of one form (§2), the drawing count depends on whether hands are generated or drawn:

| Approach | Drawings |
|---|---|
| Vector form drawn once, three hands rendered programmatically | **156** |
| Each hand drawn by hand (structural tier-invariant) | **~446** |

Test the programmatic route on a handful of runes first — it's the difference between a large project and an enormous one.

**Either way, v0 needs far less — and the reason is fictional, not budgetary: the player starts with a burnt stick.** Ship **crude hand only**, and only the starting vocabulary.

**Suggested v0 set — 42 runes, 42 drawings:**
- All 8 targets
- 14 sources: Sun, Moon, Stars, Sea, Rain, Ice, Volcano, Ash, Granite, Sand, Crystal, Wind, Root, Fungus
- 14 qualifiers: Faint, Moderate, Great · Small, Large · Single, Pair, Many · Constant, Cyclic · High, Low · Red, Blue
- 6 structural: Bind, Duplicate, Negate, Anchor, Terminus, Wild

**Then, in order:** remaining structural → Plain and Refined hands for the v0 set (or the programmatic renderer, if it works) → the rest of the qualifiers → sources by domain (Water and Stone first; Strange last, since it's late-game vocabulary).

</details>

<details>
<summary><b>12. Open questions</b></summary>

1. **Page size and growth curve.** 6×6 start is a guess; the right answer is whatever makes a *crude* page feel constrained but not miserable. Needs playtesting.
2. **Do targets have to be present to be written?** Can you bind Hydrology on a world with no water source at all, or is Hydrology+Absent the way to say "dry"? (I lean: Absent is a qualifier, so yes, you write it explicitly.)
3. **Does the Duplicate rune scale sublinearly in *footprint* as well as cost?** Probably yes, or high counts become impossible.
4. **How many sigils can bind one target** before it's incoherent — hard cap, or let contradiction/instability handle it naturally? (I lean: let instability handle it.)
5. **Are contradictions ever *productive*?** Some rare materials/creatures might only exist in contradictory worlds — which would make instability a deliberate goal rather than only a cost.
6. **Do instruments have any effect besides tier access?** Recommendation: no. Clean ladder, no sidegrades — there's enough combinatorial depth already.

</details>
