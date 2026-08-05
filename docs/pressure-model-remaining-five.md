# The Pressure Model — Remaining Five Targets (rough draft)

**Deliberately rougher than the Illumination / Thermal / Hydrology drafts.** Purpose: give Claude Code a complete, buildable model so the pressure system can exist end-to-end. Everything here is **[PLACEHOLDER]** and expected to be revised after playtesting. Audit later; build now.

Same schema throughout: **0–100 scale · net value + opposed magnitude + modality tags · three consumers (player-facing / content pressures / instability) · diminishing returns on stacking.**

---

<details>
<summary><b>4. SUBSTRATE — what the ground is made of</b></summary>

### Resolves to
- **Richness** (0–100) — how much value is in the ground
- **Composition mix** — proportions across **hard / ductile / volatile** (the material triangle; corners and edges name material families)
- **Dispersion** (0–100) — veined/concentrated ↔ uniform. Same axis Hydrology introduced.
- **Tags** — *layered*, *unstable-ground*, *fossil-bearing*, *toxic*

### Character axis: hard / ductile / volatile
Not add/hold/remove — Substrate sources are **compositional**. Each source pushes the mix toward a corner and raises richness by its own value.

| Character | Yields | Sources |
|---|---|---|
| **Hard** | Stone, armour materials, abrasives | Granite · Basalt · Obsidian · Quartz · Adamant · Chitin · Bone · Glass |
| **Ductile** | Metals, workable materials | Iron · Copper · Silver · Gold · Lead · Mercury · Amber · Silk |
| **Volatile** | Reactive, energetic, unstable | Sulfur · Salt · Tar · Crystal · Magma · Rift |
| **Inert** (low richness) | Fill | Limestone · Chalk · Clay · Sand |

### Rough values
Richness contribution: inert +2 · common (Iron, Granite, Basalt, Salt) +8 · uncommon (Copper, Obsidian, Quartz, Sulfur, Amber) +15 · rare (Silver, Mercury, Crystal, Tar) +25 · precious (Gold, Adamant) +40.
Dispersion: metals and crystal push **veined** (−20); sand, clay, chalk push **uniform** (+20).

### Downstream
- **Player-facing:** hard substrate slows harvesting, resists crumbling; volatile substrate creates hazard tiles and unstable ground; veined dispersion concentrates nodes into seams worth finding.
- **Content:** calcium/mineral-rich → **biomineralised armour, shells, dense bone** (robust). Toxic/metal-rich (serpentine analogue) → **stunted, tough, sclerophyllous flora**; metal-tolerant specialists. Hard layered substrate → enables **iridescent finishes** (needs light too, per Illumination). Volatile → **emanation trait probability up**.
- **Instability:** the largest single **greed** contributor — but not the only one (see `sites-system.md` §0). Volatile composition adds instability directly, independent of value.

</details>

<details>
<summary><b>5. VITALITY — how much life the world supports</b></summary>

### Resolves to
- **Productivity** (0–100) — total biomass the world can carry
- **Trophic depth** (0–100) — how many layers the food web has; gates whether large predators are viable
- **Dispersion** — clustered (oases) ↔ even
- **Tags** — *fungal*, *decaying*, *swarming*, *barren*

### Character axis: producing / consuming / decomposing
| Character | Effect | Sources |
|---|---|---|
| **Producing** | Productivity ↑ | Root · Bloom · Grass · Canopy · Moss · Vine · Coral · Kelp |
| **Consuming** | Trophic depth ↑, productivity ↓ slightly | Swarm · Hive · Herd · Thorn |
| **Decomposing** | Productivity ↑ slowly, adds *decaying* tag | Fungus · Rot |
| **Suppressing** | Productivity ↓ | Ash · Salt · Wildfire · Miasma · Void |

### Hard caps (the cross-target constraints — build these)
- **Productivity ≤ f(available saturation)** — dry worlds cap life regardless of what's written.
- **Productivity ≤ f(Illumination peak)** unless the *fungal* or *decaying* tag is present — lightless worlds need a non-photosynthetic base, which is exactly the interesting case.
- **Creature size ≤ f(productivity)** — cold + poor cannot produce huge insulated fauna. This is the main brake on everything-creatures.

### Downstream
- **Player-facing:** node density; encounter frequency; flora cover affects vision and movement.
- **Content:** high productivity → larger sizes viable, more ornament/finish affordable (costly signals need surplus), K-selection. Low → dwarfism, minimal ornament, r-selection. High trophic depth → apex predators exist at all; low → grazers and scavengers only. Clustered dispersion → oasis structure: dense encounters at hotspots, empty between.
- **Instability:** contributes **greed** via valuable creatures/flora. *Swarming* + high productivity is dangerous rather than valuable.

</details>

<details>
<summary><b>6. RELIEF — the shape of the land</b></summary>

### Resolves to
- **Elevation range** (0–100) — flat ↔ mountainous
- **Openness** (0–100) — enclosed/broken ↔ open sightlines. **This is the axis the tile grid reads most directly.**
- **Verticality** — presence of layers (skyland, cavern, canyon)
- **Tags** — *two-storey*, *broken*, *labyrinthine*, *sheer*

### Character axis: raising / cutting / flattening
| Character | Effect | Sources |
|---|---|---|
| **Raising** | Elevation ↑, openness ↓ | Volcano · Granite · Basalt · Glacier · Coral · Canopy |
| **Cutting** | Elevation range ↑, openness ↓, adds *broken* | River · Waterfall · Wind · Gale-force weather · Rift |
| **Flattening** | Elevation ↓, openness ↑ | Sand · Sea · Ash · Marsh |

### Downstream
- **Player-facing:** the grid's actual layout — impassable terrain, chokepoints, sightline rules, vision interacting with Illumination. High verticality may mean multiple map layers (defer if expensive).
- **Content:** **openness sets the ambush↔pursuit axis** (robust): enclosed → ambush predators, crypsis, close reach, concealable builds; open → pursuit predators, long limbs, sleek builds, endurance. Elevation range → climbing/gripping traits; *sheer* → gliding and flight favoured. Broken terrain → refuges, so prey survives without armour.
- **Instability:** minimal directly. *Broken* + volatile substrate compounds hazard density.

</details>

<details>
<summary><b>7. ATMOSPHERE — the air</b></summary>

### Resolves to
- **Density** (0–100) — thin ↔ thick
- **Motion** (0–100) — still ↔ storming
- **Clarity** (0–100) — clear ↔ occluded (couples hard with Illumination and Hydrology's airborne form)
- **Tags** — *toxic*, *charged*, *choking*

### Character axis: thickening / thinning / moving
| Character | Effect | Sources |
|---|---|---|
| **Thickening** | Density ↑; heat retention (feeds Thermal) | Weight · Cloud · Mist · Miasma |
| **Thinning** | Density ↓; heat loss; swing ↑ | Thin Air · Void |
| **Moving** | Motion ↑; erosion (feeds Relief); clarity varies | Wind · Thunder · Gale-force weather |
| **Occluding** | Clarity ↓ | Ash · Smoke · Mist · Miasma |

*Dense air as a Thermal retainer lives here, not as its own source rune.*

### Downstream
- **Player-facing:** clarity modifies vision alongside Illumination; motion creates weather hazards; *toxic* forces protection or damages over turns.
- **Content:** **high density → invertebrate gigantism** (evocative, flagged contested in research — flavour, not balance). Low density → smaller sizes, efficient respiration, and it amplifies Thermal swing. High motion → anchoring/gripping traits, flight either favoured (soaring) or suppressed (too violent) depending on magnitude.
- **Instability:** *toxic* and *charged* contribute. Extreme density or thinness with contradictory sources is a common contradiction site.

</details>

<details>
<summary><b>8. CYCLE — time and rhythm</b></summary>

### Resolves to
- **Period** (0–100) — how long a full day/season cycle runs
- **Amplitude** (0–100) — how much conditions swing across the cycle
- **Regularity** (0–100) — erratic ↔ metronomic
- **Tags** — *seasonal*, *tidal*, *arrhythmic*, *frozen-in-time*

### Character axis: lengthening / shortening / destabilising
Mostly driven by **qualifiers** (Constancy, Length) rather than by sources — Cycle is the target most written *about* other targets. Celestial sources set period; Constancy qualifiers set regularity; Amplitude derives from how much Illumination and Thermal actually move.

### Downstream
- **Player-facing:** whether a run experiences day/night at all; whether conditions shift mid-run (they may, since it advances on player turns only — never wall-clock).
- **Content:** high amplitude → generalists, seasonal morphs, storage/dormancy traits. Low amplitude → specialists with narrow tolerance (buffered worlds breed fragile things). *Arrhythmic* → stress-tolerant generalists, and it amplifies variance across every other axis (the Schmalhausen effect from the research).
- **Instability:** *arrhythmic* contributes modestly. Zero-period worlds (nothing ever changes) are a contradiction if written alongside cyclic sources.

</details>

---

## Cross-target constraints to build (the teeth)

These are where the design gets its character. Author them explicitly rather than hoping they emerge:

1. **Vitality ≤ f(available saturation)** — dry caps life.
2. **Vitality ≤ f(Illumination peak)** unless *fungal*/*decaying* — lightless worlds need a non-photosynthetic base.
3. **Creature size ≤ f(Vitality)** — poor worlds can't feed giants.
4. **Thermal decides Hydrology's form** — freezing converts standing→frozen; heat converts standing→airborne.
5. **Iridescent finish requires** hard/layered covering **and** Illumination peak > 40.
6. **Cold's four answers are chosen by other targets** — wet-cold favours fat/bulk, dry-cold favours covering.
7. **Openness (Relief) sets ambush vs. pursuit**, which then constrains build, reach, and crypsis.
8. **Atmosphere density feeds Thermal retention**; thinness amplifies swing.

## Energy budget (build this once, applies everywhere)

Each generated creature draws size, armour, insulation, weapons, and ornament from a single implicit budget scaled by world productivity. This one mechanic reproduces the square-cube, defence-mobility, and costly-signal trade-offs and guarantees no world produces an everything-creature.

## Known rough edges

- Numbers throughout are guesses; expect a full balance pass.
- Cycle is the least worked target and may want folding into Illumination/Thermal if it stays thin.
- Relief's verticality may be more than the tile grid wants; defer multi-layer maps if costly.
- Sites (`sites-system.md`) read pressures but are a separate system — don't fold them in.
