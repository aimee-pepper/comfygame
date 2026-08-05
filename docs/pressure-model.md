# The Pressure Model (v1)

**One document, all eight targets.** Illumination, Thermal and Hydrology are worked in full; Substrate, Vitality, Relief, Atmosphere and Cycle are roughed in. The **schema is decided**; individual numbers and source *characters* are Claude-proposed and pending Aimee's review.

**Shared rules:** 0–100 scale everywhere · two-valued targets are **Illumination and Thermal only** (peak + floor) · light colour is mechanical · position on the page never affects outcome · diminishing returns on stacking · every target resolves to net value(s) + **opposed magnitude (tracked gross, never net)** + modality tags · three consumers: player-facing effects, content pressures, instability.

---

## 1. Decided rules

1. **Shared 0–100 scale** for every target. One mental model, one preview language.
2. **Two-valued targets: Illumination and Thermal only** (peak + floor). The other six are single-valued.
3. **Light colour is mechanical**, not cosmetic — it biases creature coloration and iridescence.
4. **Position on the page never affects outcome** (locked previously). Pressure resolution consumes an unordered set of sigils.

## 2. What a target resolves to

Each target produces values that feed **three separate consumers**. Keeping them separate matters — a world can be pleasant to walk through and still produce very strange creatures.

| Consumer | Uses |
|---|---|
| **Player-facing effects** | Vision radius, hazards, movement, encounter conditions |
| **Content pressures** | Creature trait distributions, flora, resource tables |
| **Instability** | Greed (abundance/value) and contradiction (opposed magnitude) |

Per target, resolution outputs:
- **net value(s)** on the 0–100 scale (one number, or peak+floor for Illumination/Thermal)
- **opposed magnitude** — force applied in conflicting directions and cancelled (drives contradiction instability; tracked gross, never net)
- **modality tags** — qualitative facts that aren't scalar (e.g. *lit-without-sun*, *banded*, *cyclic*)

## 3. How a sigil contributes

`[qualifiers] → source → Bind → target`

1. **Base contribution** — every source has a base magnitude and a *character* (see §4).
2. **Qualifiers scale or shape it** — Intensity scales magnitude; Constancy sets whether it's cyclic or constant; Count/Scale scale it; Distribution and Elevation add modality tags; Colour tags it.
3. **Implicit secondaries** — the source also contributes to other targets automatically, at its own rates.
4. **Negation** subtracts, and records the subtraction in opposed magnitude.

**Stacking [PROPOSAL]:** contributions to a target sum with **diminishing returns** — three suns are brighter than one but not three times brighter, and nothing exceeds 100. Diminishing returns is what stops the correct strategy from being "write the same rune as many times as it fits."

---

## 4. ILLUMINATION — worked in full

### 4.1 Resolves to

- **Peak** (0–100) — brightest it gets
- **Floor** (0–100) — darkest it gets
- **Dynamic range** = peak − floor (a derived value; it's its own pressure)
- **Spectrum** — dominant colour, from Colour qualifiers on light sources
- **Modality tags** — *cyclic*, *constant*, *sourceless*, etc.

Two numbers rather than one because **dim and dark are different pressures** — biologically and mechanically. Constant twilight produces enlarged eyes and tapetums; true dark produces eye loss and depigmentation. One number can't say both.

### 4.2 Sources have a *character* that determines what they lift

| Character | Lifts | Sources |
|---|---|---|
| **Cyclic** — present part of the time | **Peak only** | Sun, Moon, Stars, Comet, Aurora, Eclipse, Second Light |
| **Constant** — never sets | **Peak and Floor** | Magma, Crystal, Fungus (glowing), Rift |
| **Occluding** — reduces light | **Lowers both** | Cloud, Ash, Smoke, Miasma, Canopy, Void |

This falls out of the fiction rather than being imposed, and it produces the interesting cases for free:

- **Great Sun alone** → peak 85, floor 0. Blazing days, black nights. Wide dynamic range → *both* a diurnal and a nocturnal niche in one world.
- **Great Sun + Faint Fungus** → peak 86, floor 12. Nights are never fully black. Narrower range, no true nocturnal specialists.
- **Fungus alone** → peak 20, floor 20. A lightless world that is nonetheless lit. Zero dynamic range. Evocative, and exactly what this system should make writable.
- **Great Sun + Great Canopy** → peak 45, floor 0. Bright above, dim below — with an *elevation* modality tag, this is a two-storey world.

### 4.3 Base values **[ALL PLACEHOLDER]**

Magnitude at Moderate intensity; Intensity scales it (Faint ×0.4, Moderate ×1.0, Great ×1.6, Overwhelming ×2.2).

| Source | Peak | Floor | Thermal secondary | Notes |
|---|---|---|---|---|
| Sun | +55 | — | **+40** | The default; hard to have light without heat |
| Moon | +12 | — | +2 | |
| Stars | +4 | — | 0 | |
| Comet | +15 | — | +5 | erratic by default |
| Aurora | +14 | — | **0** | light without heat, no contradiction needed |
| Second Light | +25 | — | +5 | unexplained; adds instability |
| Magma | +30 | +30 | **+60** | also Substrate |
| Crystal | +18 | +18 | **0** | pairs with Substrate |
| Fungus (glowing) | +12 | +12 | 0 | pairs with Vitality |
| Rift | +20 | +20 | ±0 | unstable; wide variance |
| Cloud | −20 | −5 | −10 | |
| Ash | −30 | −8 | −15 | also Substrate, Atmosphere |
| Smoke | −25 | −6 | +5 | |
| Miasma | −18 | −4 | 0 | also Vitality (negative) |
| Canopy | −35 | −10 | −8 | elevation-tagged; also Vitality |
| Void | −25 | −15 | −20 | absence of celestial light |

**Floor rule:** peak can never resolve below floor; if occlusion drives peak under floor, they converge (a uniformly murky world).

### 4.4 Downstream — what Illumination pushes

Only the light-driven pressures listed; other targets contribute to the same trait axes independently.

**Player-facing**

| Condition | Effect |
|---|---|
| Peak < 25 | Vision radius −1 |
| Peak < 10 | Vision radius −2; light sources become carryable/needed |
| Floor > 40 | No true night; night-only content never triggers |
| Dynamic range > 60 | Day and night are meaningfully different runs |

**Content pressures** (grounded in the biology research)

| Condition | Trait pressure | Evidence |
|---|---|---|
| Peak 10–35 (dim, not dark) | **Sensory → vision up**: enlarged eyes, tapetum. Coloration → darker. | Robust |
| Peak < 10 (aphotic) | **Sensory → non-visual** (mechano/chemo/thermo). Eyes reduced/lost. Coloration → depigmented/pale. Frame → elongated appendages. | Robust — troglomorphy is one of biology's most reliable convergences |
| Peak > 75 (bright, open) | Vision acute; eye protection. Coloration → countershaded, UV-dark dorsal. **Finish → iridescence enabled.** | Moderate–robust |
| Floor < 5 **and** range > 50 | **Two niches**: a nocturnal and a diurnal population in one world | Inferred |
| Constant tag, range ≈ 0 | Cycle-independent life; no seasonal/diurnal morphs | Inferred |
| *Sourceless* tag (floor > 0, no celestial) | **Emanation trait probability up** — bioluminescence is overwhelmingly a dark-environment adaptation | Robust |

**Spectrum → coloration [PROPOSAL]**
- Creature coloration biases toward **crypsis in the ambient spectrum** — red-lit worlds produce red-cryptic fauna.
- **Aposematic** (warning) species invert this: they bias toward maximum contrast *against* ambient.
- **Iridescence/Finish** requires both light to signal in (peak > 40) and a hard layered covering. Narrow-spectrum light suppresses it (nothing to refract); broad-spectrum encourages it.

**Instability**
- **Greed:** high peak from *valuable* sources (Crystal, Magma) contributes; Sun does not — sunlight isn't loot.
- **Contradiction:** negating a source's implicit secondary (a Sun that does not warm) records opposed magnitude on *Thermal*, not Illumination. Illumination's own contradictions come from stacking strong emitters and strong occluders — a world both blazing and smothered.

### 4.5 Preview panel shows

Peak and floor as a band, dominant spectrum as a colour swatch, modality tags as words (*cyclic*, *sourceless*, *two-storey*), and derived range with a plain-language reading: *"blazing days, absolute nights."*

---

## 5. What generalizes to the other seven

The pattern to reuse:

1. **Resolve to** net value(s) + opposed magnitude + modality tags.
2. **Sources have a character** that determines *how* they contribute (Illumination's cyclic/constant/occluding is the model — each target needs its own character axis).
3. **Base table** of source → magnitude + implicit secondaries.
4. **Downstream table** split into player-facing / content pressures / instability.
5. **Diminishing returns** on stacking.

**Candidate character axes for the rest [PROPOSAL]:**
- **Thermal** (two-valued): *retaining* vs *radiating* vs *cooling*
- **Hydrology:** *standing* vs *flowing* vs *frozen* vs *airborne*
- **Substrate:** *hard* vs *ductile* vs *volatile* (reuse the material triangle)
- **Relief:** *raising* vs *cutting* vs *flattening*
- **Vitality:** *producing* vs *consuming* vs *decomposing*
- **Atmosphere:** *thickening* vs *thinning* vs *moving*
- **Cycle:** *lengthening* vs *shortening* vs *destabilizing*

## 6. Open

1. Do the numbers in §4.3 survive contact with play? All placeholders.
2. Does Thermal's peak/floor use the same cyclic/constant logic, or its own? (Likely its own: thermal mass and retention matter, so an ocean narrows the range without adding heat.)
3. Should modality tags be authored per source, or derived from qualifier combinations?
4. How many sigils can bind one target before it's incoherent — or does diminishing returns plus contradiction handle it? (I lean: it handles it.)

---

# THERMAL

## 1. Resolves to

- **Peak** (0–100) — hottest it gets. *(~0 = lethal cold, 30 = cold, 50 = temperate, 70 = hot, 100 = lethal heat)*
- **Floor** (0–100) — coldest it gets
- **Swing** = peak − floor (derived; its own pressure)
- **Modality tags** — *arid-swing*, *thermally-buffered*, *geothermal*, *seasonal* etc.

## 2. Sources have three characters, not two

| Character | Acts on | How | Sources |
|---|---|---|---|
| **Producing** | Raises peak, usually floor a little | Adds heat | Sun, Magma, Wildfire, Hot Spring, Geyser, Volcano |
| **Retaining** | **Raises floor, lowers peak — narrows swing** | Thermal mass / insulation. Adds almost no heat of its own. | Sea, Lake, Marsh, Cloud, Canopy, Ash |
| **Sinking** | Lowers both | Removes heat | Ice, Glacier, Snow, Thin Air, Wind, Void |

**Retention is the mechanic that makes Thermal interesting**, and it has no Illumination equivalent. It means two worlds with identical heat input can be completely different places to live:

- **Faint Sun + Vast Sea** → peak 48, floor 38. Mild, stable, buffered. Swing 10.
- **Faint Sun + Thin Air, no water** → peak 62, floor 8. Scorching days, lethal nights. Swing 54.

Same sun. Opposite worlds. That's the design working.

## 3. Base values [PLACEHOLDER]

At Moderate intensity; Intensity scales (Faint ×0.4, Moderate ×1.0, Great ×1.6, Overwhelming ×2.2). Baseline world with no thermal sigils sits at peak 50 / floor 50 — **[PROPOSAL]** temperate and dead-flat, so every interesting climate is authored.

### Producing

| Source | Peak | Floor | Other secondaries |
|---|---|---|---|
| Sun | **+40** | +8 | Illumination (primary) |
| Magma | +60 | +45 | Illumination, Substrate |
| Volcano | +45 | +20 | Substrate, Atmosphere (ash) |
| Wildfire | +30 | +5 | Vitality (negative), Atmosphere |
| Geyser | +20 | +15 | Hydrology, Atmosphere, Substrate — steam vents folded in here |
| Hot Spring | +15 | +12 | Hydrology; local not global |

*Dense atmosphere as a heat retainer is handled by the **Atmosphere** target, not by a source rune.*

### Retaining (floor up, peak down — the signature move)

| Source | Peak | Floor | Notes |
|---|---|---|---|
| Sea | **−15** | **+22** | Strongest buffer in the set |
| Lake | −7 | +10 | |
| Marsh | −5 | +8 | Also Hydrology, Vitality |
| Cloud | −12 | +10 | Blocks sun, traps warmth |
| Canopy | −10 | +6 | Shade above, still air below |
| Ash | −18 | +4 | Blocks more than it holds — the volcanic-winter case |

### Sinking

| Source | Peak | Floor | Notes |
|---|---|---|---|
| Glacier | −30 | −35 | Also Relief, Hydrology |
| Ice | −22 | −28 | Also Hydrology |
| Snow | −15 | −18 | Coloration secondary: white-biasing |
| Thin Air | −5 | **−30** | Nothing to hold heat — huge swing |
| Void | −20 | −30 | Absence of everything |
| Wind | −8 | −6 | Wind chill |

**Clamp rule:** floor may never exceed peak; if retention drives them together they converge (a world with no meaningful day/night difference).

## 4. Downstream

### Player-facing

| Condition | Effect |
|---|---|
| Peak > 85 or Floor < 15 | Exposure damage without protection; a hazard tied to the extreme end |
| Swing > 45 | Day and night are meaningfully different runs |
| Floor < 25 | Water sources freeze; some harvesting blocked |
| Peak > 75 | Water sources evaporate/dry seasonally |

### Content pressures

**This is the target with the most co-valid answers — deliberately.** Cold does *not* dictate a single body plan. Resolution picks among branches, weighted, with secondary pressures breaking ties.

| Condition | Trait pressure | Branching |
|---|---|---|
| **Floor < 30 (cold)** | Any of: **Size ↑** (Bergmann); **Covering denser + longer**; **Build bulkier / extremities shorter**; fat reserves | **4 co-valid answers.** Wet-cold (high Hydrology) favours fat/bulk over covering — fur fails when wet. Dry-cold favours covering. |
| **Floor < 15 (severe)** | Above, intensified; Coloration → white **if** snow/ice present, else darker (solar absorption) | Two opposite colour answers; the Hydrology tag decides |
| **Peak > 70 (hot)** | Size ↓; **extremities larger** (radiators); covering sparse/short; Coloration pale/reflective | Also pushes *nocturnal* behaviour → interacts with Illumination's dynamic range |
| **Swing > 45** | Burrowing and shelter-seeking traits; generalist tolerance | The extreme-desert profile |
| **Swing < 12** | Specialists; narrow tolerance; no seasonal morphs | Buffered worlds breed fragile specialists — a nice hidden consequence |
| **Peak > 70 + low Hydrology** | Water-conservation morphology; flora → succulent/spined/low stature | The arid syndrome; robust in the literature |
| **Floor < 30 + aquatic** | **Meristic counts ↑** (Jordan's rule): more segments/appendages, more elongated bodies | Only fires with Hydrology |

**Energy budget interaction:** insulation and large size both cost energy, so **cold + low Vitality caps size.** You cannot have huge, heavily insulated fauna on a world that can't feed them. This is the main cross-target constraint, and it's what stops cold worlds from producing everything-creatures.

### Instability

- **Greed:** Magma and geothermal sources contribute (they're valuable), plain Sun does not.
- **Contradiction:** this is where the classic case lands — *a sun that does not warm* records opposed magnitude **here**, not on Illumination. Also: a strong producer plus a strong sink (Magma + Glacier) is a world at war with itself — high opposed magnitude, ordinary net temperature, violently unstable. Exactly the flavour wanted.

## 5. Preview shows

Peak/floor as a band with a swing readout, plus plain language: *"mild and steady"*, *"scorching days, killing nights"*, *"frozen throughout"*. Modality tags as words.

## 6. Notes for the remaining six

Thermal confirms **the schema generalizes but each target needs its own character axis** — and that the axis isn't always about magnitude. Illumination's characters describe *when* a source acts; Thermal's describe *whether it adds, holds, or removes*. Expect at least one more target (probably Hydrology or Atmosphere) to need a third kind of axis.

Also confirmed: **cross-target constraints are where the design gets its teeth.** Cold+wet ≠ cold+dry; cold+poor caps size; hot+dry is a whole syndrome. Those interactions are worth authoring explicitly rather than hoping they emerge.

---

# HYDROLOGY

## 1. Resolves to

- **Saturation** (0–100) — how much water the world holds. *(0 = bone dry, 25 = arid, 50 = temperate, 75 = wet, 100 = drowned)*
- **Form mix** — proportions across **standing / flowing / frozen / airborne**. Not a magnitude; a distribution.
- **Dispersion** (0–100) — **concentrated** (one sea, dry elsewhere) ↔ **pervasive** (evenly damp everywhere). This is the axis that decides whether water is a *place* or a *condition*.
- **Salinity** (0–100) — **[PROPOSAL]** folded in here rather than being its own target, since it only ever matters where there's water.
- **Modality tags** — *tidal*, *seasonal-flood*, *subterranean*, *brine*, *stagnant*.

### Why form matters more than amount

Thermal already showed cold+wet ≠ cold+dry. Form sharpens it: **frozen water is water the world can't use.** A glacier world reads as high saturation but is biologically arid — which is true of real polar deserts and gives you a genuinely counterintuitive world type that still makes sense once you see it.

Cross-target coupling that falls out for free: **Thermal decides which forms are even possible.** Floor < 25 converts standing water to frozen; peak > 75 converts standing to airborne. So writing "Sea" on a frozen world gets you a glacier whether you asked for one or not — the simulation correcting your description is exactly the Myst-flavored behavior we want.

## 2. Source characters

| Character | Effect | Sources |
|---|---|---|
| **Standing** | Saturation ↑, dispersion → concentrated | Sea, Lake, Marsh, Spring, Hot Spring |
| **Flowing** | Saturation ↑, dispersion → middling; adds *erosion* to Relief | River, Waterfall, Geyser |
| **Frozen** | Saturation ↑ but **biologically unavailable**; Thermal sink | Ice, Glacier, Snow |
| **Airborne** | Saturation ↑, dispersion → **pervasive** | Rain, Mist, Cloud |
| **Draining** | Saturation ↓ | Sand, Thin Air, Wildfire, Ash, Salt |

## 3. Base values [PLACEHOLDER]

Baseline with no hydrology sigils: **saturation 35, dispersion 50, salinity 20** — **[PROPOSAL]** slightly dry, so wetness is authored and dryness is the default. Intensity scales as elsewhere.

| Source | Saturation | Form | Dispersion push | Salinity | Other secondaries |
|---|---|---|---|---|---|
| Sea | **+45** | standing | → concentrated (−30) | **+55** | Thermal (retaining), Relief |
| Lake | +25 | standing | → concentrated (−15) | +2 | Thermal (retaining) |
| Marsh | +22 | standing | → pervasive (+15) | +5 | Vitality ↑, *stagnant* |
| Spring | +10 | standing | neutral | 0 | Vitality ↑ locally |
| River | +20 | flowing | +5 | 0 | **Relief (cutting)**, Vitality ↑ |
| Waterfall | +12 | flowing | −10 | 0 | Relief, Atmosphere (spray) |
| Geyser | +8 | flowing | −20 | +10 | Thermal ↑, Substrate, Atmosphere — steam vents folded in here |
| Rain | +30 | airborne | **→ pervasive (+35)** | 0 | Vitality ↑↑, Illumination ↓ slightly |
| Mist | +14 | airborne | +25 | 0 | Illumination ↓, vision ↓ |
| Cloud | +10 | airborne | +20 | 0 | Illumination ↓, Thermal (retaining) |
| Ice | +20 | **frozen** | +10 | 0 | Thermal (sinking) |
| Glacier | +35 | **frozen** | −20 | 0 | Thermal (sinking), Relief |
| Snow | +15 | frozen | +30 | 0 | Thermal (sinking), Coloration → white |
| Sand | −20 | — | — | +5 | Substrate |
| Salt | −10 | — | — | **+40** | Substrate, Vitality ↓ |
| Thin Air | −12 | — | → pervasive dryness | 0 | Thermal, Atmosphere |
| Wildfire | −15 | — | — | 0 | Vitality ↓↓ |

**Available saturation** = saturation × (1 − frozen fraction). This is the number downstream pressures actually read; raw saturation only drives visuals and terrain.

## 4. Downstream

### Player-facing

| Condition | Effect |
|---|---|
| Available saturation < 15 | Water becomes a consumable concern; springs are landmarks |
| Standing fraction high + concentrated | Large impassable water bodies; terrain routing matters |
| Frozen fraction high | Traversable but slick; ice hazards |
| Airborne high | **Vision ↓** (couples with Illumination); harvesting slowed |
| Salinity > 70 | Water present but undrinkable — a cruel and very writable world |

### Content pressures

| Condition | Trait pressure | Notes |
|---|---|---|
| **Available saturation > 70** | Coloration **darker** (Gloger's rule — humidity, robust); flora → large-leaved, fleshy, low-defense; Vitality ceiling ↑ | The humid syndrome |
| **Available saturation < 20** | Water-conservation morphology; nocturnal/burrowing bias; flora → succulent, spined, low stature; Coloration pale | Arid syndrome; robust, convergent (cacti/euphorbias) |
| **Standing + concentrated** | **Aquatic body plans**: fusiform build, finned appendages, limb reduction. Bone density → dense if shallow, light if deep/fast | Robust convergence |
| **+ Thermal floor < 30** | **Meristic counts ↑** (Jordan's rule): more segments, elongation | Only in aquatic cold |
| **Salinity > 60** | Osmoregulatory specialists; **bone density ↑** (ballast in denser water); flora → halophytes, stunted | Moderate evidence |
| **Flowing high** | Anchoring/gripping traits; streamlined; upstream-migration behaviours | |
| **Frozen high** | Reads as **arid** biologically despite high raw saturation; cold+dry favours covering over fat | The polar-desert case |
| **Dispersion concentrated + low saturation** | **Oasis structure** — life clusters at water; high local density, empty elsewhere | Good tactical texture: predictable dense encounters |
| **Dispersion pervasive** | Life spread evenly; no refuges, no clustering | |

**Cross-target constraint:** Vitality cannot exceed what available saturation supports. Dry worlds cap life regardless of what else is written — the second major cross-target cap after cold+poor capping size.

### Instability

- **Greed:** low. Water isn't loot — *except* brine/salt flats and geyser-fed mineral deposits, which are.
- **Contradiction:** the good cases here are thermal contradictions — standing water written onto a world whose floor is below freezing, or airborne water on a world with no atmosphere. Both record opposed magnitude and produce genuinely strange places.

## 5. Preview shows

Saturation bar, form mix as a small stacked proportion, dispersion as a concentrated↔pervasive slider, salinity if above baseline. Plain language: *"a drowned world of warm shallow seas"*, *"dry, with life crowded around three springs"*, *"frozen through — water everywhere, none of it usable."*

## 6. What Hydrology added to the schema

Confirmed the prediction from Thermal: a third kind of axis appeared. Illumination's characters describe *when*; Thermal's describe *add/hold/remove*; Hydrology's describe **what form**, plus a *distribution* axis that no prior target needed.

**Generalized schema is now:** magnitude + (optional second magnitude) + character-derived qualitative state + optional distribution + modality tags.

**Dispersion is likely to recur** — Substrate (veins vs. uniform), Vitality (oases vs. even), and Relief all plausibly want it. Worth building as a shared concept rather than a Hydrology special case.

**Salinity folded in here** rather than becoming a ninth target. Flag if that turns out to constrain something later.

---

# THE REMAINING FIVE

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