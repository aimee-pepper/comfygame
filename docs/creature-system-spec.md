# The Creature System — traits, cast, combat, loot

**Status:** Claude's design. Implements session 15's decisions (cast + jitter, Vitality sets cast size not spread, anchored worlds keep their cast, free sampling with derived identity) and §3–5 of `generation-spine-spec.md`. Numbers are **[PLACEHOLDER]** throughout.

**What it replaces:** three authored creatures with flat `maxHP` / `attack` / `sightRadius`.

---

<details open>
<summary><b>1. The mechanism in one paragraph</b></summary>

A world's pressures produce **weights** over trait axes and a **budget** scaled by Vitality. Each species in the cast is made by **spending that budget across the costly axes, weighted-randomly** — so pressures decide what a world *tends* to build, the budget decides how much there is to build with, and randomness decides where each species actually lands. Free axes (colour, sensory allocation, body shape) are shaped by pressures without spending anything. Identity is read off the result afterwards. Combat stats and loot both derive from the same trait vector.

**Why budget-allocation rather than independent rolls:** it produces trade-offs for free. A world pushing both size and armour cannot have both maxed — every species is a different answer to the same constrained problem, which is exactly what makes a cast feel like an ecosystem rather than a list.

</details>

<details>
<summary><b>2. The trait axes</b></summary>

### Costly — these spend budget

| Axis | Range | Notes |
|---|---|---|
| **size** | 0–100 | The dominant cost; scales several others |
| **covering.hardness** | 0–100 | Armour |
| **covering.length** | 0–100 | Insulation, quills |
| **covering.coverage** | 0–100 | Bare → dense |
| **boneDensity** | 0–100 | Ballast vs. lightness |
| **armament.pierce / .crush / .rend** | 0–100 each | The weapon triangle; all-low = unarmed |
| **ornament** | 0–100 | Derived from finish brightness and iridescence; a costly signal |

### Free — shaped by pressures, no budget cost

| Axis | Range | Notes |
|---|---|---|
| **build** | 0–100 | sinuous → sleek → bulky. Shape, not investment |
| **appendages.count** | 0–8 | |
| **appendages.type** | membrane / feathered / finned / limbed / none | |
| **armament.reach** | close / mid / far | |
| **armament.delivery** | single / multi / area | |
| **coloration** | CMY triangle | |
| **finish** | opacity / shine / schiller triangle | Feeds `ornament` cost |
| **sensory** | vision / mechano / chemo / thermo, summing to 100 | An *allocation*, not an amount |
| **emanation** | absent, or an element triangle | Rare; gated by pressures |

**v1 subset if scope needs cutting:** size, covering (3), boneDensity, armament (3 + reach), build, coloration, sensory. Appendages, finish, delivery and emanation can arrive later without reshaping anything.

</details>

<details>
<summary><b>3. Pressures → weights</b></summary>

Pressures produce a **weight per costly axis** (how much of the budget tends to go there) and **shifts on free axes**. Weights, not values — this is what keeps two worlds with the same pressures from producing the same animals.

| Pressure | Costly-axis weights | Free-axis shifts |
|---|---|---|
| Thermal floor ↓ | **size ↑↑ · covering.length ↑↑ · covering.coverage ↑↑** | build → bulky · reach → close |
| Thermal floor ↓ **+ wet** | shifts weight from covering → size and build bulk (fat, not fur) | |
| Thermal peak ↑ | size ↓ · covering.coverage ↓ | reach → far (radiators) · coloration pale |
| Illumination peak 10–35 | — | **sensory → vision ↑↑** · coloration dark |
| Illumination peak <10 | — | **sensory → mechano/chemo ↑↑, vision → ~0** · coloration pale · appendages.count ↑ |
| Illumination peak >75 | ornament ↑ (signalling pays) | coloration countershaded · finish schiller ↑ |
| Illumination floor >0, no celestial | — | **emanation enabled** |
| Hydrology saturation ↑ | — | coloration darker |
| Hydrology standing + concentrated | boneDensity ↑ (shallow) or ↓ (deep) | build → sinuous · appendages.type → finned |
| Hydrology + cold | — | appendages.count ↑ · build → sinuous |
| Substrate mineral-rich | **covering.hardness ↑↑ · boneDensity ↑** | finish → metallic |
| Substrate volatile | — | emanation ↑ · finish → schiller |
| Relief openness ↑ | size → mid · covering ↓ | build → sleek · reach → mid |
| Relief openness ↓ | armament.pierce ↑ | build → compact · reach → close · **coloration → cryptic** |
| Vitality ↑ | **budget ↑** (see §4) · ornament ↑ | |
| Trophic depth ↑ | armament ↑↑ on some species, ↓ on others | — |
| Atmosphere density ↑ | size ↑ for small forms | |
| Cycle amplitude ↑ | — | **widens the cast draw** (session 15), not the jitter |

**Defence branching.** Where predation pressure is high, a species takes **one** of four routes, chosen per species, never blended: **armour** (covering.hardness + coverage), **speed** (build sleek, size ↓, covering ↓), **crypsis** (coloration matched to ambient), or **aposematism** (coloration maximally contrasting + toxic flag). Blending them is what produces mush.

</details>

<details>
<summary><b>4. The budget</b></summary>

```
budget = base + vitalityScale × vitality        [PLACEHOLDER]
```

Every costly axis has a **cost curve**, superlinear so extremes are expensive:

```
cost(axis, value) = (value / 100) ^ 1.5 × axisWeight
```

`size` should cost the most, since the square–cube law says a big animal needs dense bone and thick limbs to exist at all. **[PROPOSAL]** size additionally *raises* the cost of covering and boneDensity, so large armoured creatures are genuinely rare and worth the world that grows them.

**Allocation:** draw repeatedly from the weighted axes, spending budget, until exhausted. Randomness in the draw order produces species variety within one world.

</details>

<details>
<summary><b>5. Cast and jitter</b></summary>

### Cast size — from Vitality

```
castSize = 2 + floor(vitality / 25)      → 2 at barren, 6 at teeming   [PLACEHOLDER]
```

**Vitality changes how many species, never how strange they are** (session 15). All species are drawn from the same weights regardless of cast size.

### Sampling a cast

For each species: allocate the budget as §4, apply free-axis shifts, pick one defence branch if predation is high. **No role is decided in advance** — identity is read afterwards (§6).

### Jitter — per individual spawn

Every spawn is its species plus small variation. **[PLACEHOLDER]** coloration ±10, size ±5%, finish ±5, everything else untouched.

**Jitter must never change identity, combat behaviour, or which materials drop.** It's texture: you meet the same animal, and this one is a bit paler and a bit smaller.

### Persistence

- **Disposable world:** cast is ephemeral. Specimens you recorded persist.
- **Anchored world:** cast is **fixed forever** (session 15). The same animals live there.

</details>

<details>
<summary><b>6. Identity — derived, never imposed</b></summary>

**Stored:** the trait vector. **Derived at read time:** the name.

Authored **identity regions** are ranges over trait space. A species matching one within a threshold takes its name; **anything else gets a composed descriptive name** rather than being forced into the nearest role.

Starter regions **[PLACEHOLDER]**:

| Identity | Roughly |
|---|---|
| **Ambusher** | build sleek/compact · reach close · pierce-dominant · cryptic coloration |
| **Pursuer** | build sleek · size mid · reach mid · limbed |
| **Tank** | size high · hardness high · coverage high · armament low |
| **Grazer** | armament ≈0 · covering moderate · size mid–high |
| **Swarmer** | size very low · count high · armament low |
| **Apex** | size high · armament high · build sleek |
| **Drifter** | boneDensity low · finned or membrane · build sinuous |
| **Sentinel** | size mid · hardness high · reach far |

**Unmatched species get composed names** from their dominant traits — *a huge blind armoured thing* reads better than forcing it into "Tank," and free sampling guarantees these will happen. They're the animals players remember.

### Bestiary

Consistent with session 3: **entries are identities** (derived), **specimens are trait vectors** (stored). Two similar ambushers from different worlds are one entry with two specimens — which is where personal and global percentiles come from.

</details>

<details>
<summary><b>7. Traits → combat</b></summary>

Replaces flat `maxHP` / `attack` / `sightRadius`.

| Stat | Derived from |
|---|---|
| **HP** | size ↑↑ · build bulky ↑ · boneDensity ↑ |
| **Damage** | armament total ↑ · size ↑ |
| **Damage type** | dominant armament corner — pierce ignores some armour · crush hits hard and slow · rend applies damage over time |
| **Armour** | covering.hardness × covering.coverage |
| **Initiative** | build sleek ↑ · size ↓ · boneDensity ↓ · coverage ↓ |
| **Evasion** | build sleek ↑ · size ↓ |
| **Detection radius** | sensory.vision ↑ |

### Behaviours that fall out

- **Cryptic coloration → ambush.** Doesn't appear on the map until adjacent, and acts first on engagement. In a low-openness world full of `growth` tiles, this is genuinely tense.
- **Non-visual sensory → unaffected by darkness or sight-blocking terrain.** A blind creature that hunts by touch doesn't care that it's night.
- **Aposematic coloration → attacking it costs you.** Warning colours are honest.
- **Far reach → strikes first** on engagement regardless of initiative.
- **Emanation → elemental attack.**

This is what makes a bulky armoured ambusher play differently from a swift fragile pursuer, which is currently not true of anything.

</details>

<details>
<summary><b>8. Traits → loot</b></summary>

No authored drop tables — the parts that composed the creature compose what it leaves.

| Trait region | Material | Properties inherited |
|---|---|---|
| covering hard + short + dense | **Plate** | hardness, density |
| covering hard + long | **Quill** | hardness, flexibility |
| covering soft + long + dense | **Pelt** | insulation, flexibility |
| covering soft + long + sparse | **Down** | insulation |
| covering soft + short | **Hide** | flexibility |
| covering hard + layered (schiller) | **Chitin** | hardness, lustre |
| armament pierce-dominant | **Fang** | hardness |
| armament crush-dominant | **Tusk** | density |
| armament rend-dominant | **Claw** | hardness |
| boneDensity | **Bone** | density |
| finish | applied to all of the above | lustre |
| emanation | **Ichor** | reactivity |

**Quantity** scales with size. **Grade** scales with trait extremity. So a world that grows monstrous armoured things drops monstrous plates — which is the reason to write such a world.

</details>

<details>
<summary><b>9. Build order</b></summary>

1. **Trait vector model + budget allocation sampling.** Testable without any UI.
2. **Cast sampling per world; jitter per spawn.** Wire into `Worldgen` where `enemyTable` is read today.
3. **Identity regions + composed fallback names.**
4. **Combat derivation** — replace flat stats. Retire authored creatures.
5. **Map behaviours** — crypsis, non-visual sensing, reach-first.
6. **Loot derivation** — retire drop tables.
7. **Bestiary split** into identity entries and specimen records, with percentiles.
8. **Anchored-world cast persistence.**

</details>

<details>
<summary><b>10. What I'd want challenged</b></summary>

1. **Budget-allocation as the core mechanism** — elegant, but it means you can't write a world of small heavily-armoured things *and* have them be numerous, because the budget is per-creature. Is that right?
2. **Cast size 2–6** — too few? A 6-species world may still feel thin on an 18×18 map.
3. **Jitter at ±10 colour / ±5% size** — enough to notice, or invisible?
4. **Eight starter identity regions** — and whether composed fallback names will read as evocative or as broken.
5. **Superlinear cost curve exponent (1.5)** — decides how rare extremes are.
6. **Whether `ornament` should cost budget at all**, or whether costly signalling is a subtlety that only makes creatures worse.
7. **Free axes being genuinely free** — sensory allocation costs nothing, so every creature has *some* sense at full strength. Correct, or should perception compete too?

</details>
