# The Pressure Model — Thermal (v1 draft)

**Companion to `pressure-model-illumination.md`.** Same schema, same 0–100 scale, same three consumers. All numbers **[PLACEHOLDER]**.

Thermal is the second (and last) two-valued target — and it diverges from Illumination in one important way: **some sources act on the *range* rather than the level.**

---

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
