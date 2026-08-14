# The Generation Spine — how pressures actually make worlds

**Status:** Claude's design, start to finish. Aimee has decided none of this. It's written as a system rather than a menu because the pieces only work together, but every part of it is arguable.

**The problem it solves.** `PressureReadings` currently feeds prose, contradictions, sites, pages and travellers. It does **not** decide what a world is made of, what grows there, what lives there, or what you get for killing it. That's why worlds read differently and play identically.

---

<details open>
<summary><b>0. The architecture, and the missing piece</b></summary>

Today:

```
Sigils → PressureReadings → { description · contradictions · sites · pages }
                            worldgen ← old symbol modifiers (parallel, unrelated)
```

What it should be:

```
Sigils → PressureReadings → WorldProfile → worldgen → a world
                                        ↘ creature sampling → instances → combat + loot
```

**`WorldProfile` is the missing interface.** Readings are *what a world is like*; the profile is *the instructions for building it*. Without it, every target would need its own bespoke hook into worldgen and nothing would compose.

**Two blocking prerequisites**, neither of which exists:

1. **Tiles have no terrain.** A `Tile` is content + fog + crumble. No ground type, no water, no elevation, no cover. **Relief has nothing to write to**, and every "openness sets ambush vs. pursuit" rule is unimplementable. Terrain must exist first.
2. **Creatures have no traits.** Three authored creatures with flat stats. Every trait pressure in the pressure model writes to nothing.

</details>

<details>
<summary><b>1. What a WorldProfile contains</b></summary>

Eight fields. Each is written by several targets, and **every target writes to at least three** — that's the test for whether a pressure is real or decorative.

| Field | Contents | Written by |
|---|---|---|
| **Extent** | width, height | Relief |
| **Terrain** | ground-type weights, openness, elevation variance, water coverage & form, connectivity | Relief · Hydrology · Substrate · Thermal |
| **Nodes** | resource-type weights, density, clustering | Substrate · Vitality · Hydrology |
| **Life** | fixed-budget trait distributions (mean + variance per axis), population density, trophic depth | Vitality magnitude (cast/population only) · Vitality aspects + **all eight** (trait shaping) |
| **Flora** | stature/tissue/defence distributions, cover density | Vitality · Hydrology · Illumination · Substrate |
| **Hazards** | types present, frequency | Thermal · Atmosphere · Substrate · contradiction · danger runes |
| **Ambient** | vision modifier, day length, night rules, movement cost | Illumination · Cycle · Atmosphere · Hydrology |
| **Sites** | eligibility (already built) | all |

</details>

<details>
<summary><b>2. Terrain — the prerequisite</b></summary>

**Add a ground type to `Tile`**, orthogonal to content. Proposed set, deliberately small:

`stone · soil · sand · ice · ash · water · deepWater · rubble · growth · void`

Plus two per-tile scalars: **elevation** (0–3, for cover and sightlines) and **passable** (derived).

### How targets write it

**Relief** — the primary author.
- *Extent*: Scale qualifier on the primary Relief source sets map dimensions.
- *Openness* (0–100): high → few obstructions, long sightlines, cursorial terrain. Low → dense obstruction, short sightlines, chokepoints.
- *Elevation variance*: flat → all elevation 0; mountainous → 0–3 spread, creating cover and blocked sightlines.

**Substrate** decides the ground under everything: composition mix → `stone` / `sand` / `soil` / `rubble` weights. Volatile-heavy adds `ash`.

**Hydrology** paints water: available saturation → total water coverage; form decides `water` vs `ice`; dispersion decides one lake versus many ponds.

**Thermal** overrides: floor below freezing converts `water` → `ice`; extreme peak converts `soil` → `sand`.

**Vitality** adds `growth` over passable ground at high productivity — which is also the cover that makes ambush terrain work.

### Why this matters for play

Openness plus elevation plus growth **is** cover, and cover is what makes the ambush/pursuit distinction real — both in what spawns and in how a fight starts. It also makes movement genuinely different world to world: an open plain is crossed in a straight line; a broken, overgrown world is a maze.

</details>

<details>
<summary><b>3. Life — creatures from trait distributions</b></summary>

**The core mechanism.** The profile carries, per trait axis, a **mean and a variance**. Generation samples each creature independently. Two worlds with identical pressures still produce different animals; one world produces a *population* that varies.

**Variance is the anti-sameness mechanism and must be generous.** Convergent evolution says environment predicts the *ecomorph class*, not the individual.

### The axes

`size · build · covering(hard/long/dense) · boneDensity · appendages(count,type) · armament(pierce/crush/rend, delivery, reach) · coloration(CMY) · finish · sensory(vision/mechano/chemo/thermo) · emanation(rare)`

### Pressure → trait shifts

Every shift below is a **distribution nudge**, never a fixed outcome. Where a pressure has several valid answers, the profile carries **branch weights** and each creature picks one — so a cold world contains both shaggy and fat animals.

| Pressure | Trait shift | Branches |
|---|---|---|
| Thermal floor ↓ | size ↑ · covering dense+long ↑ · build bulky ↑ · extremity reach ↓ | **4 co-valid**; wet-cold weights fat/bulk, dry-cold weights covering |
| Thermal peak ↑ | size ↓ · covering sparse ↑ · reach ↑ (radiators) · coloration pale | |
| Illumination peak 10–35 | sensory→vision ↑↑ (big eyes) · coloration darker | |
| Illumination peak <10 | sensory→non-visual ↑↑ · vision ↓↓ · coloration pale · appendages long | |
| Illumination peak >75 | vision acute · coloration countershaded · **finish: iridescence enabled** | needs hard layered covering too |
| Illumination floor >0, no celestial | **emanation probability ↑↑** | the bioluminescence case |
| Hydrology saturation ↑ | coloration darker (Gloger) | |
| Hydrology standing+concentrated | build fusiform · appendages finned · bone dense (shallow) or light (deep) | |
| Hydrology + Thermal cold | appendage/segment count ↑ · build sinuous | Jordan's rule |
| Substrate mineral-rich | covering hard ↑↑ · bone dense ↑ | biomineralisation |
| Substrate volatile | emanation ↑ · finish metallic ↑ | |
| Relief openness ↑ | **pursuit build**: reach medium, build sleek, size mid, speed | |
| Relief openness ↓ | **ambush build**: crypsis coloration, build compact, reach close, armament pierce ↑ | |
| Vitality ↑ | size ceiling ↑ · ornament affordable · trophic depth ↑ | |
| Vitality ↓ | size ↓ · armament ↓ · minimal finish | |
| Predation (derived from trophic depth) | **armour** OR **speed** OR **crypsis** OR **aposematism** | **4 mutually exclusive branches** |
| Atmosphere density ↑ | size ↑ for small-bodied forms | |
| Cycle amplitude ↑ | generalist tolerance · storage traits · **variance ↑ on every axis** | |
| Cycle amplitude ≈0 | specialists · **variance ↓** | buffered worlds breed fragile things |

### The energy budget

Each sampled creature draws `size + armour + insulation + armament + ornament` from **one pool scaled by Vitality**. This single rule reproduces the square–cube law, the defence–mobility trade-off, and costly signalling, and it guarantees no world produces an everything-creature. Already stubbed in `WorldConstraints.energyBudget`.

### Identity

Sampled traits resolve to a **named identity** at read time (ambusher, grazer, tank, skirmisher…) from authored regions of trait space. Stored record is the trait vector; identity is derived — so identity definitions can change without breaking saves.

</details>

<details>
<summary><b>4. Traits → combat</b></summary>

Currently `maxHP`, `attack`, `sightRadius`. Traits should *derive* those and add behaviour, so a bulky armoured ambusher plays differently from a swift fragile pursuer.

| Trait | Combat effect |
|---|---|
| size | HP ↑, initiative ↓ |
| build bulky | HP ↑, evasion ↓ |
| build sleek | initiative ↑, evasion ↑ |
| covering hardness | damage reduction |
| covering density | damage reduction, initiative ↓ |
| boneDensity | HP ↑, initiative ↓ |
| armament pierce | ignores some armour |
| armament crush | higher damage, slower |
| armament rend | damage over time |
| reach | who strikes first on engagement |
| sensory vision | detection radius on the map |
| sensory non-visual | detects through obstruction; unaffected by darkness |
| coloration crypsis | **ambushes** — engages from concealment, acts first |
| coloration aposematic | signals toxicity; attacking it costs you |
| emanation | elemental attack |

**Two map-level behaviours fall straight out:** cryptic creatures don't show until adjacent (which makes overgrown low-openness worlds genuinely tense), and non-visual sensory means darkness doesn't hide you from them.

</details>

<details>
<summary><b>5. Traits → loot</b></summary>

No authored drop tables. **The parts that composed the creature compose what it leaves.**

| Source trait | Material | Properties inherited |
|---|---|---|
| covering hard+short+dense | **Plate** | hardness, density |
| covering hard+long | **Quill** | hardness, flexibility |
| covering soft+long+dense | **Pelt** | insulation, flexibility |
| covering soft+long+sparse | **Down** | insulation |
| covering soft+short | **Hide** | flexibility |
| covering hard+layered | **Chitin** | hardness, lustre |
| armament pierce | **Fang** | hardness |
| armament crush | **Tusk** | density |
| armament rend | **Claw** | hardness |
| boneDensity | **Bone** | density |
| finish | applied to all of the above | lustre |
| emanation | **Ichor** | reactivity |

**Quantity** scales with size; **grade** scales with how extreme the traits were. So a world that produces monstrous armoured things produces monstrous plates — and that is the entire reason to write such a world.

Flora and substrate drop by the same principle from their own axes.

</details>

<details>
<summary><b>6. Flora, hazards, ambient</b></summary>

**Flora** — three axes (stature, tissue, defence), same distribution treatment.
- Vitality → cover density and stature ceiling
- Hydrology low → succulent tissue, spined defence, low stature; high → large, soft, low-defence
- Substrate poor/toxic → tough, woody, defended (resource availability hypothesis)
- Illumination low → fungal (and it's what lifts the vitality cap in dark worlds)
- **Flora writes `growth` tiles**, which is the cover feeding §2 and §4.

**Hazards** — types, not just a flag.
- Thermal extremes → exposure damage
- Atmosphere toxic → damage over turns
- Atmosphere motion → weather events
- Substrate volatile → unstable ground
- Contradiction → **tears** (already specced as sites)
- Danger runes → their named hazard

**Ambient**
- Illumination peak → vision radius; **floor → night vision radius**
- Cycle period → day length in turns; amplitude → how much conditions shift
- Atmosphere clarity → vision modifier stacking with illumination
- Hydrology → movement cost on water/ice/marsh

</details>

<details>
<summary><b>7. The currencies</b></summary>

Aimee's call: binding needs its own currency, and it should **compete** with research.

**Three stages: raw essence → essence → crystals.**

- **Raw essence** — wild drops, harvested.
- **Essence** — refined from raw. Buys **research and crafting**.
- **Crystals** — condensed *from essence* at a rate. **Binds books.**

Because crystallising consumes essence, **every book you write is research you didn't do**. That's the tension. It also gives the Refinery a real job and makes binding cost something deliberately concentrated rather than skimmed off the top.

**A fourth resource for anchoring unstable worlds** — a rare thing, not on the essence ladder, scaling with the world's instability. High-instability worlds need a great deal of it, which is what makes holding a greedy world open genuinely expensive. **[OPEN: what it is and where it comes from — plausibly only from unstable worlds themselves, so greed funds greed.]**

</details>

<details>
<summary><b>8. Build order</b></summary>

Each step is playable and each unblocks the next.

1. **Terrain on tiles** — ground types, elevation, passability. Nothing else can proceed.
2. **`WorldProfile` + Relief/Substrate/Hydrology/Thermal → terrain.** First point where writing a sigil changes what the map *looks like*.
3. **Nodes from Substrate + Vitality.** Retire `yieldModifiers`.
4. **Creature traits + sampling from distributions.** The big one.
5. **Traits → combat stats and behaviour.** Retire flat creature stats and `enemyTableModifiers`.
6. **Traits → loot.** Retire authored drop tables.
7. **Flora**, including `growth` tiles feeding cover.
8. **Hazards and ambient**, including day/night from session 13.
9. **Currencies.**

</details>

<details>
<summary><b>9. What I'd want challenged</b></summary>

1. **Ten ground types** — too many, too few, wrong ones?
2. **Elevation 0–3** — is elevation worth having at all, or is openness enough?
3. **Trait variance magnitude** — this single number decides whether worlds feel varied or noisy, and I have no principled value for it.
4. **Branch weights** — should a cold world produce *both* shaggy and fat animals (variety) or commit to one (identity)?
5. **Whether identity should constrain sampling** rather than be derived after — i.e. pick "ambusher" then sample traits within it, which guarantees coherence at the cost of surprise.
6. **The energy budget's severity** — too tight and everything is mediocre, too loose and it does nothing.
7. **Whether Cycle amplitude driving trait *variance*** is clever or just confusing.

</details>
