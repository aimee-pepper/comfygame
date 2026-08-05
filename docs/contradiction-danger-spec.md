# Contradiction, Danger & the Description Panel (v1 spec)

**Status:** specced from Aimee's session-7 decisions. Contradiction is **in**, but tightly scoped. All numbers **[PLACEHOLDER]**.

---

## 1. The core rule: contradiction is a CATALOG, not a formula

**Contradiction is never computed from opposed magnitudes.** It fires only from an **enumerated catalogue of named contradictions**, each with an explicit trigger, value, and description string.

This is the whole safety mechanism. It means:

- **Ordinary rich worldbuilding is never punished.** A sunny snowy world is real — sun producing heat, glacier sinking it, equilibrium. Nature is full of opposed forces. Nothing in that combination appears in the catalogue, so nothing fires.
- **No chilling effect.** Players never learn to avoid interesting combinations out of fear that opposition itself is penalised.
- **Every contradiction is authored, testable, and nameable in the preview.**
- **The catalogue can grow** with the vocabulary without retuning anything.

> **Invariant to test:** no world composed only of non-negated, catalogue-clean sigils ever accrues contradiction instability, regardless of how opposed its pressures are.

---

## 2. The two contradiction categories

### 2.1 Negation contradictions — denying a source's nature

Fires when a **Negate** rune is written against an implicit property a source inherently has.

| Written | Name | Why it's a contradiction |
|---|---|---|
| Sun + Negate-thermal | *A sun that does not warm* | Light of that intensity carries heat |
| Magma + Negate-thermal | *Cold fire* | |
| Ice + Negate-cold | *Ice that does not chill* | |
| Rain + Negate-hydrology | *Rain that does not wet* | |
| Canopy + Negate-occlusion | *A forest that casts no shade* | |
| Sea + Negate-retention | *A sea that does not temper* | |

**Always deliberate, always visible** — you had to write a Negate rune, so it can never happen by accident. This is the safest category and probably where most contradiction lives.

### 2.2 Impossible assertions — enumerated only

Fires when a world asserts a state its own conditions forbid. **Only from the catalogue** — never inferred.

| Assertion | Name | Condition |
|---|---|---|
| Standing water where thermal floor < freezing | *Water that will not freeze* | Explicitly written standing source + floor below threshold |
| Airborne moisture with negligible atmosphere | *Rain without air* | Airborne source + atmosphere density below threshold |
| Photosynthetic flora in an aphotic world | *Green in the dark* | Non-fungal flora + illumination peak below threshold |
| Constant cycle written alongside cyclic sources | *A day that never turns* | Zero-period + cyclic celestial |

**Note the interaction with the existing Thermal→Hydrology conversion.** Currently, writing Sea on a frozen world silently converts it to a glacier. Two valid readings, and they should not both be true:

- **Conversion** (current): the world corrects your description. No contradiction.
- **Contradiction**: the world *obeys* you and tears. Liquid sea on a frozen world, and it costs.

**[PROPOSAL — needs Aimee]** Conversion by default; contradiction only if you write **Negate-freeze** alongside, insisting on liquid water. That way the world corrects you unless you explicitly refuse to be corrected — which is a much better fiction and keeps 2.2 tiny.

---

## 3. Stacking

**Additive base, plus a small disclosed superlinear term.**

```
contradictionPenalty = Σ(individual values) + escalation(n)
escalation(n) = 0 for n ≤ 1;  small and rising for n ≥ 2   [PLACEHOLDER]
```

Rationale: purely additive under-sells that a world at war with itself in several ways is worse than several separate problems. Purely multiplicative makes the third contradiction do five times the work of the first, invisibly — players can't reason about marginal cost, so they learn never to stack, which kills the interesting writing.

**The escalation term must be shown as its own line in the preview.** Hidden superlinearity is the failure mode.

---

## 4. Contradiction produces DANGER, and sometimes value

Per Aimee: contradiction feeds instability **and** can create value, with value scaling alongside danger.

**Danger expressions** (composes with the Q19 ruling that rich places are guarded):
- More spawns; higher creature tier
- More hostile flora
- Environmental hazards: damaging hail, poison air, unstable ground, and so on
- Hazard sites — the places a contradictory world tears

**Value expressions:**
- **[PROPOSAL]** Materials that exist *only* in contradictory worlds — reactivity-extreme, emanation-bearing, or otherwise impossible elsewhere.
- Higher grades on ordinary materials.

**Anti-farming guard** — the failure mode to design against is writing tiny, cheap, maximally contradictory worlds and harvesting the wreckage. Two defences, both wanted:
1. **Value scales with danger, not with contradiction count** — so a cheap contradictory world is dangerous *and* poor, because it has little in it to be valuable.
2. **[PROPOSAL] Contradiction value requires substance** — a world must have real richness written into it for contradiction to elevate anything. Contradiction is a multiplier on value present, never a source of value from nothing.

---

## 5. The Peace rune and the danger runes

### Peace — buys calm, costs stability

The inversion of Mystcraft's design, where danger symbols *added* stability.

- Reduces danger expressions — fewer guardians, milder hazards, lower creature tier.
- **Subtracts stability** — the world holds together less well.

You are not buying safety; you are **trading danger for time**. That makes it genuinely interesting rather than a strict upgrade, and it has an obvious best use: a world you intend to *anchor and staff with companions* rather than raid, where a long calm life matters more than surviving one violent expedition.

**[PROPOSAL]** It does not touch contradiction penalties — peace calms the inhabitants, it doesn't reconcile the world with itself.

### Danger runes — release valves for instability (DECIDED)

The symmetric opposite, and Mystcraft's original design: **accept danger, buy stability.** Writing a danger rune makes the world more hostile and, in exchange, makes it hold together longer.

This is the **release valve** that makes greedy worlds viable at all. A world rich enough to be worth writing may be too unstable to survive; you buy it time by accepting that it crawls with things. That is a real, thematic, and self-explaining trade — and it's the precedent that made Mystcraft's Dense Ores worlds playable.

**[PLACEHOLDER] Candidate danger runes**, each adding stability and a distinct hostility flavour:

| Rune | Hostility added |
|---|---|
| **Storm** | Environmental — damaging weather, lightning |
| **Blight** | Hostile flora; poisoned ground |
| **Swarm** | Many weak creatures; density rather than tier |
| **Predation** | Fewer, stronger creatures; higher tier |
| **Miasma** | Poison air; damage over turns |
| **Tremor** | Unstable ground; hazard tiles; collapse pockets |

**[PROPOSAL]** Each danger rune's stability gift is capped so stacking six of them can't make an arbitrarily greedy world safe — the Mystcraft precedent caps the scorched/lightning bonus to apply once, and the same logic applies here. Stacking should broaden the *kinds* of danger rather than multiply the stability gift.

Peace and danger runes are two ends of one axis: **danger ↔ time**. Peace spends stability to buy calm; danger spends calm to buy stability.

---

## 6. The live world-description panel

Generated as the player places symbols, updating continuously. This is the panel from Q18 that makes the pressure model visible, and it's where contradiction becomes legible.

**Content:** a qualitative sentence about the world — *"Frozen over. Enclosed, layered stone. Little light, and what lives here doesn't need it."* Descriptive, never a condition list, never naming sigil values. This is what the player matches against a Library hint page.

**Colour coding (Aimee's proposal):**
- **Underline red** — clauses arising from things that generate instability
- **Underline green** — clauses arising from things that promote stability

So the description doubles as the instability explanation, without a separate table of numbers. You read *why* a world is fragile in the same sentence that tells you what it's like.

**Contradictions get named explicitly** as their own line, not folded into a number: *"The sun you have written does not warm."*

**But naming them is tier-4 analysis** (session 8), not a starting feature. Early on the panel says only that something here is wrong; *what* is wrong is something you work out, or later something you can read. Opacity is the joy — figuring out what your own writing did to a world is the game, not a usability problem.

**[PROPOSAL]** If per-clause colour proves fiddly, fall back to: plain description + a separate short list of named contributors, red and green. Less elegant, same information.

---

## 7. Open

1. **The conversion-vs-contradiction ruling in §2.2** — does Negate-freeze gate it, as proposed?
2. **Do chance-filled slots participate in contradiction?** Aimee has ruled the *risk* is acceptable gameplay, so presumably yes — but confirm whether the preview should warn that unwritten slots could contradict.
3. **Escalation curve shape** — how hard should stacking bite?
4. **Danger-rune stability caps** — how hard is the cap, and does stacking broaden kinds of danger as proposed?
5. **Contradiction-only materials** — do they exist, and if so are they authored per contradiction or derived?
