# The Flora System — growth, cover, harvest, hazard

**Status:** Claude's design. Parallel in structure to `creature-system-spec.md` and using the same cast/jitter model from session 15. Numbers **[PLACEHOLDER]**.

**Why it's next:** `growth` is a ground type with **nothing producing it**, and growth is what makes cover — and therefore ambush terrain, and therefore the whole openness axis — actually exist. Flora is also the base of the food web that Vitality's trophic depth assumes, and the loot source parallel to creatures.

---

<details open>
<summary><b>1. What flora does that creatures don't</b></summary>

Four jobs, and only the last overlaps with creatures:

1. **It is terrain.** Flora writes `growth` tiles — cover that blocks sight, slows movement, and makes cryptic creatures dangerous.
2. **It is harvestable.** Fibre, timber, resin, toxin — the non-mineral half of the material economy.
3. **It can be hostile.** Thorned, toxic, or actually predatory: a hazard you walk into rather than one that comes to you.
4. **It gates life.** Trophic depth needs a base; a world with no producers supports nothing above them.

</details>

<details>
<summary><b>2. The axes</b></summary>

### Metabolism — the axis that decides whether a world can live at all

**[PROPOSAL]** This is new and it's the most important one, because it's what lifts the Vitality cap in worlds that have no light.

| Metabolism | Needs | Produces |
|---|---|---|
| **Photosynthetic** | Illumination | The default; scales with light |
| **Fungal** | decay, moisture, darkness tolerance | Lets **dark worlds have life** |
| **Chemosynthetic** | volatile Substrate | Lets **dark, dead, mineral worlds have life** |

A world's flora draws its metabolism from what's actually available. A lightless world with volatile substrate grows chemosynthetic things and is *not* barren — which is the interesting case, and currently impossible.

### Costly axes — spend budget

| Axis | Range | Notes |
|---|---|---|
| **stature** | 0–100 | groundcover → shrub → canopy. The dominant cost |
| **tissue.woody / .fibrous / .fleshy** | 0–100 each | A triangle. Woody is structure, fibrous is tensile, fleshy is storage |
| **defence** | 0–100 | How much is invested in not being eaten |

### Free axes

| Axis | Notes |
|---|---|
| **defence.type** | physical (thorns) · chemical (toxic) · **active** (it moves) |
| **habit** | spreading · clustered · solitary — decides `growth` tile *patterning* |
| **coloration** | CMY, same as creatures |
| **finish** | feeds loot lustre |

</details>

<details>
<summary><b>3. Pressures → weights</b></summary>

| Pressure | Effect |
|---|---|
| Illumination peak ↑ | metabolism → photosynthetic · **stature ↑↑** (competition for light) |
| Illumination peak <10 | metabolism → **fungal or chemosynthetic** · stature ↓ |
| Substrate volatile | metabolism → chemosynthetic viable |
| Hydrology saturation ↑ | tissue → fleshy · stature ↑ · **defence ↓** (regrow rather than defend) |
| Hydrology saturation ↓ | tissue → fleshy but **stature ↓↓** (succulence) · **defence ↑, type → physical** (spines are reduced leaves) |
| Substrate poor or toxic | tissue → woody · **defence ↑↑** (resource availability hypothesis — slow growth defends what it can't replace) |
| Substrate rich | tissue → fleshy · defence ↓ |
| Thermal floor ↓ | stature ↓ · tissue → woody · habit → clustered |
| Thermal peak ↑ + dry | stature ↓ · fleshy · physical defence |
| Trophic depth ↑ (herbivores exist) | **defence ↑** — and this can override the RAH lean |
| Vitality ↑ | **budget ↑ and cast size ↑** |
| Cycle amplitude ↑ | storage tissue ↑ (fleshy) · dormancy |

**Note the deliberate conflict:** nutrient-poor soil says defend, herbivore pressure says defend, but rich soil says don't bother. A rich world *with* heavy grazing still grows thorns — herbivore pressure wins. That's real ecology and it stops flora defence from being a single-variable readout.

</details>

<details>
<summary><b>4. Cast, budget, jitter — same model as creatures</b></summary>

```
floraCastSize = 1 + floor(vitality / 30)     → 1 at barren, 4 at teeming   [PLACEHOLDER]
floraBudget   = base + vitalityScale × vitality
```

Same rule as session 15: **Vitality changes how many species, not how strange they are.**

Species are drawn by spending the budget across costly axes weighted by pressures. Free axes shaped, not spent. **Jitter** per instance: coloration ±10, stature ±10%.

**Identity is derived**, same as creatures — authored regions (*bramble · canopy tree · succulent · mat · fungal bloom · reed · crust*) with **composed descriptive names for anything unmatched**.

</details>

<details>
<summary><b>5. Flora → terrain</b></summary>

**This is the piece the terrain system is missing.**

- **Cover density** = f(vitality, mean stature). Decides what fraction of passable tiles become `growth`.
- **Habit decides patterning:** *spreading* → large connected swathes · *clustered* → thickets with gaps · *solitary* → scattered single tiles.
- **Stature decides whether `growth` blocks sight.** Groundcover shouldn't hide anything; canopy should. **[PROPOSAL]** low-stature flora writes `growth` that is passable and *doesn't* block sight; high-stature writes sight-blocking `growth`.

**Ordering:** flora placement must run **with or after** terrain painting, since it converts passable ground to `growth` and needs to know what's passable.

**Consequence worth naming:** openness as written by Relief is now *modified* by flora. A world can be topographically open and still be a maze because it's overgrown — and that combination (open terrain, dense growth) is a genuinely distinct place from either alone.

</details>

<details>
<summary><b>6. Flora → harvest and hazard</b></summary>

### Harvest — flora becomes resource nodes

Nodes on or adjacent to `growth`, yielding by tissue:

| Tissue dominant | Material | Properties |
|---|---|---|
| woody | **Timber** | hardness mid, density mid |
| fibrous | **Fibre** | flexibility high |
| fleshy | **Pulp** | insulation, reactivity |
| defence chemical | **Toxin** | reactivity high, Toxic flag |
| metabolism chemosynthetic | **Reagent** | reactivity very high |

Quantity from stature; grade from trait extremity — same rule as creature loot.

### Hazard — defended flora fights back

| Defence type | Effect |
|---|---|
| **physical** | Entering the tile costs HP |
| **chemical** | Entering applies damage over turns |
| **active** | It **engages you** — a combat encounter with a plant |

**[PROPOSAL]** active defence should be rare and gated behind high defence *and* high vitality, because a world where the undergrowth attacks you is a memorable world and shouldn't be common.

</details>

<details>
<summary><b>7. Flora → the food web</b></summary>

Trophic depth currently comes from Vitality alone. It should come from **producers**:

```
trophicDepth = f(flora productivity)    where productivity = f(castSize, stature, metabolism viability)
```

Consequences:
- A world with no viable metabolism has **no flora, therefore no herbivores, therefore no predators**. Whatever lives there subsists on something else entirely — which is exactly the "not every world has grazers" point from session 15.
- **Chemosynthetic worlds get full food webs in total darkness**, which is a genuinely strange and writable place.
- Herbivore presence feeds back into flora defence (§3), so the two systems shape each other rather than running in parallel.

</details>

<details>
<summary><b>8. Build order</b></summary>

1. **Flora trait model + budget sampling** (mirrors creature §1–4).
2. **Flora → `growth` tiles**, with habit patterning and stature deciding sight-blocking. *Unblocks the cover that ambush terrain needs.*
3. **Flora → resource nodes**, replacing generic node yields for organic materials.
4. **Metabolism gating**, including the dark-world cases.
5. **Trophic depth from producers**, feeding creature generation.
6. **Hazardous flora**; active defence last.

</details>

<details>
<summary><b>9. What I'd want challenged</b></summary>

1. **Metabolism as a distinct axis** — it's the newest idea here and it carries a lot (it's the whole reason dark worlds can live). Too clever?
2. **Whether flora needs a cast at all**, or whether one dominant plant type per world is enough. Four species may be more bookkeeping than it's worth if flora is mostly terrain.
3. **Active-defence plants** — good rare surprise, or does a plant that attacks you belong in the creature system with `build: sessile`?
4. **Whether flora should have its own budget** or draw from the same pool as creatures (one world-wide life budget split between producers and consumers, which would be more ecologically honest and more constraining).
5. **Low-stature `growth` not blocking sight** — two ground types would be clearer than one type with a hidden property.

</details>
