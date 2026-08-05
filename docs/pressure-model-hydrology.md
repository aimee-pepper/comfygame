# The Pressure Model — Hydrology (v1 draft)

**Companion to the Illumination and Thermal drafts.** Same schema, 0–100 scale, three consumers. All numbers **[PLACEHOLDER]**.

Single-valued (per the locked decision — only Illumination and Thermal are two-valued), but it needs **two extra dimensions that aren't magnitude at all**: what *form* the water takes, and how it's *distributed*. A world can be 60% wet as a hundred scattered ponds or one vast ocean, and those are completely different places.

---

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
