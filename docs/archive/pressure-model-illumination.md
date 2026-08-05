# The Pressure Model — Schema + Illumination (v1 draft)

**Status:** schema is decided; **Illumination is fully worked** as the pattern. The other seven targets follow. **[PROPOSAL]** marks my calls; overrule freely.

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
