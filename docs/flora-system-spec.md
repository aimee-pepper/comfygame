# The Flora System — growth, cover, harvest, hazard

**Status:** **Core implemented and verified, 8 Aug 2026.** Parallel in structure to
`creature-system-spec.md`. The implementation has a per-world flora cast; unlike creatures, it does
not currently add per-tile specimen jitter. Numbers remain **[PLACEHOLDER]** pending playtesting.

**Why it was needed:** `growth` was a ground type with nothing producing it. Flora now creates
groundcover and sight-blocking growth, supplies the producer base of the food web, generates organic
harvest nodes, and creates physical, chemical, and active hazards.

## Implementation review — 8 Aug 2026

The six-stage core in §8 is present. The targeted `FloraTests` suite passes **25/25**.

| Spec responsibility | Current state |
|---|---|
| Trait model, metabolism, budget, derived identity and names | Implemented |
| Flora cast deterministic per world | Implemented |
| Habit-patterned groundcover and sight-blocking growth | Implemented as two legible ground types |
| Organic resource nodes derived from nearby plants | Implemented for fibre, timber, pulp, toxin, spore and reagent |
| Producer productivity gates the food web | Implemented |
| Thorn, toxin and rooted active-defence hazards | Implemented |
| Resin in the organic crafting economy | **Gap:** catalogued and required by recipes, but flora never yields it |
| Growth slows movement | **Built:** tall growth costs one extra turn; pathing prices it and pauses before danger |
| Per-instance flora jitter | **Gap or obsolete claim:** tiles reference the per-world species directly |

The core system is therefore complete enough to leave the immediate sequence after these calls are
resolved. Remaining work is integration and tuning, not a missing flora architecture.

### Review decisions — settled by Aimee, 8 Aug 2026

1. **Keep separate flora and creature budgets.** A shared zero-sum budget sounds ecological but is
   not: abundant producers ordinarily support more consumer biomass rather than losing their own
   traits to it. Producer productivity already gates trophic depth, which creates the causal link we
   need without making large animals arbitrarily imply thin plants.
2. **Do not add per-tile plant jitter.** Creature specimens are individually encountered, fought,
   and recorded; individual grass tiles are not. Tile jitter would add save weight and invisible
   complexity. Variation belongs in the world's small flora cast and its spatial patterning.
3. **Make resin a secondary harvest from woody, defended flora rather than another dominant tissue.**
   Resin is secretion/defence, not a fourth structural material. A woody plant should primarily
   yield timber or fibre and sometimes resin as an additional product, with likelihood or quantity
   rising with chemical defence/reactivity.
4. **Let tall growth cost an extra world turn; keep groundcover at one.** This makes an overgrown
   world mechanically maze-like as promised. The UI and pathfinder must quote the cost, and
   auto-pathing should pause before entering costly growth when danger is nearby. Mud produced by
   marsh conditions follows the same extra-turn rule.

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

This is the axis that lifts the Vitality cap in worlds that have no light.

| Metabolism | Needs | Produces |
|---|---|---|
| **Photosynthetic** | Illumination | The default; scales with light |
| **Fungal** | decay, moisture, darkness tolerance | Lets **dark worlds have life** |
| **Chemosynthetic** | volatile Substrate | Lets **dark, dead, mineral worlds have life** |

A world's flora draws its metabolism from what's actually available. A lightless world with volatile substrate grows chemosynthetic things and is *not* barren.

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
<summary><b>4. Cast and budget — parallel to creatures</b></summary>

```
floraCastSize = 1 + floor(vitality / 30)     → 1 at barren, 4 at teeming   [PLACEHOLDER]
floraBudget   = base + vitalityScale × vitality
```

Same rule as session 15: **Vitality changes how many species, not how strange they are.**

Species are drawn by spending the budget across costly axes weighted by pressures. Free axes are
shaped, not spent. There is no per-tile specimen jitter; variation lives in the small flora cast
and its spatial patterning.

**Identity is derived**, same as creatures — authored regions (*bramble · canopy tree · succulent · mat · fungal bloom · reed · crust*) with **composed descriptive names for anything unmatched**.

</details>

<details>
<summary><b>5. Flora → terrain</b></summary>

**This is the piece the terrain system is missing.**

- **Cover density** = f(vitality, mean stature). Decides what fraction of passable tiles become `growth`.
- **Habit decides patterning:** *spreading* → large connected swathes · *clustered* → thickets with gaps · *solitary* → scattered single tiles.
- **Stature decides whether growth blocks sight.** Low-stature flora writes legible `groundcover`;
  high-stature flora writes sight-blocking `growth`.

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

Active defence is rare and gated behind high defence and high vitality, because a world where the
undergrowth attacks you is a memorable world and shouldn't be common.

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

1. ✅ **Flora trait model + budget sampling** (mirrors creature §1–4).
2. ✅ **Flora → growth tiles**, with habit patterning and stature deciding sight-blocking.
3. ✅ **Flora → resource nodes**, replacing generic node yields for organic materials.
4. ✅ **Metabolism gating**, including the dark-world cases.
5. ✅ **Trophic depth from producers**, feeding creature generation.
6. ✅ **Hazardous flora**, including active defence.

</details>

<details>
<summary><b>9. What I'd want challenged</b></summary>

1. ✅ **Metabolism remains a distinct axis.** It produces writable dark-world ecologies and is
   covered by reachability tests.
2. ✅ **Flora has a small cast.** This produces meaningful harvest and terrain variation without a
   large authored catalog.
3. ✅ **Active-defence plants use both systems:** grown as flora, fought through creature combat,
   rooted by the map.
4. ✅ **Flora and creatures retain separate budgets** and influence one another through producer
   productivity and trophic depth.
5. ✅ **Two ground types shipped:** `groundcover` is visible through and `growth` blocks sight.

</details>
