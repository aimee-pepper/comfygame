# Stability: Why a Sun Costs 25, and the Two Axes That Fix It

> *"the sun as a focus SHOULD NOT DESTABILIZE SO MUCH MORE THAN EVERYTHING ELSE WHEN IT IS THE MOST STANDARD SOURCE OF ILLUMINATION IN ANY WORLD"*

**Correct, and the numbers show how far off it is.**

---

## 1. What's happening

```
greed = Σ over written subjects of (baseline − peak) × 0.45
```

**A sun bound to Illumination:** baseline **0**, peak **55** → `(0 − 55) × 0.45` = **−25**.

### What everything else costs, for scale

| Focus | Bound to | Peak | Baseline | Stability |
|---|---|---|---|---|
| **Sun** | illumination | 55 | **0** | **−25** |
| Gold | substrate | 40 | 0 | −18 |
| Magma | illumination | 30 | 0 | −14 |
| Root | vitality | 25 | 0 | −11 |
| Crystal | illumination | 18 | 0 | −8 |
| Sea | hydrology | 45 | **35** | −4 |
| Granite | substrate | 8 | 0 | −4 |
| Ice | hydrology | 20 | 35 | **+7** |
| Wind | atmosphere | 15 | **50** | **+16** |

**A sun destabilises more than a vein of gold**, and more than half as much as *Rich Ore* (−45), the symbol whose entire identity is greed.

## 2. Two separate faults

### 2a. Illumination's baseline is 0 — so "normal" is pitch dark

Every subject is measured against its baseline, and **illumination's is zero.** So the neutral, unremarkable, costs-nothing state of a world is *lightless*, and **any light at all is an extravagant demand.**

Compare Atmosphere (baseline 50) and Hydrology (35), where writing something ordinary costs nearly nothing and writing *less* than ordinary is a stabilising gift. Illumination has no "ordinary" — it only has *absence* and *demands*.

That's why Wind is **+16** and a Sun is **−25**. Wind is asking for slightly less than a normal atmosphere; the sun is asking for infinitely more than a normal sky, because a normal sky has no light in it.

### 2b. Greed measures *deviation*, when it should measure *value*

This is the deeper fault, and it contradicts what was specced.

`pressure-model.md` §4.4 says plainly:

> **Greed:** high peak from *valuable* sources (Crystal, Magma) contributes; **Sun does not — sunlight isn't loot.**

That principle was written and never implemented. The current formula charges identically for **anything unusual**, so it bills you for daylight, warmth, water, and mountains at the same rate as gold.

**Greed was supposed to mean "you asked the world for wealth."** It currently means "you asked the world for anything."

## 3. The fix — two axes (Aimee)

> *"probably another axis to measure instability on is how much of a deviation from a neutral something is. like a mid-grey sky, mid plain field... a barren world increases stability since it's worse than the norm, and a verdant lush world slowly scales up destabilization with how much more life than normal it has."*

**That's the missing half**, and together with per-subject weighting it makes the meter mean something coherent.

### The principle underneath it

**A world resists being asked for more. It doesn't resist being asked for less.**

A dead, frozen, lightless world is easy to hold together — there is nothing in it to hold. A lush, blazing, ore-veined world is hard. So:

- **Above neutral → destabilises**, scaled by how far above
- **At neutral → free**
- **Below neutral → stabilises**

That's the Mystcraft model generalised past ore: *greed* stops being about treasure specifically and becomes **asking the world for more than it ordinarily carries, of anything.**

### The two axes, and why both are needed

| Axis | Measures | Applies to |
|---|---|---|
| **Deviation** | How far from ordinary, in either direction | **Every** subject, lightly |
| **Value** | How much of what you asked for is *wealth* | **Substrate** and **Vitality**, heavily |

**Deviation alone** would charge a mountainous world the same as a gold-veined one. **Value alone** would let you write a blazing, drowned, shattered world for free as long as it was poor. Both together say the true thing: *a strange world is hard to hold, and a rich one is harder.*

### The baselines are the actual bug

The current formula already measures deviation. **Its baselines just aren't neutrals** — four of eight are zero, meaning "ordinary" is *nothing at all*.

| Subject | Now | **Proposed neutral** | What neutral should mean |
|---|---|---|---|
| **Illumination** | **0** | **45** | A mid-grey sky. Day and night, nothing remarkable |
| Thermal | 50 | 50 ✓ | Temperate |
| Hydrology | 35 | **40** | Rivers and lakes. Wet in places |
| **Substrate** | **0** | **30** | Ordinary rock with common minerals in it |
| **Relief** | **0** | **35** | Rolling country. Neither flat nor shattered |
| **Vitality** | **0** | **40** | A plain field. Grass, and things that eat it |
| Atmosphere | 50 | 50 ✓ | Air you can breathe |
| Cycle | 50 | 50 ✓ | Days that turn |

**Aimee's examples, made numeric.** *"Mid-grey sky"* is Illumination 45. *"Mid plain field"* is Vitality 40 and Relief 35.

### What that fixes, in one line each

- **A sun costs almost nothing** — 55 against a neutral of 45 is a slight excess, not an outrage.
- **A barren world grants stability**, because Vitality 0 is far below a neutral of 40.
- **A teeming world costs, and scales** — exactly as she describes.
- **Dim Sky earns its stabilising effect** instead of being handed +12 as an authored constant.
- **A world of plain stone costs nothing**; a world of gold veins costs a great deal.

### The biggest consequence: stability becomes emergent

Hand-authored `stabilityDelta` values on symbols — Rich Ore −45, Teeming Life −35, Dim Sky +12 — **become unnecessary.** The number falls out of what the world actually *is*.

That's the profiling model from the research (Mystcraft charged instability by measuring an age's contents against the overworld, not by tallying symbols), and it has the property hand-tuning never will: **it self-balances as the vocabulary grows.** A focus added next year is priced correctly the moment it exists, because it's priced by what it does.

## 4. Why this matters beyond one number

The stability meter is the main feedback the player gets while composing, and **the fault teaches the wrong lesson.** Right now it says *writing a sunny world is nearly as reckless as strip-mining one.* A player learning the system from the meter would conclude that light is expensive and darkness is safe — which is exactly backwards from the fiction, where a lightless world is the strange and difficult thing.

**Greed should punish avarice, not ambition** — and under the two-axis model it punishes *strangeness* lightly and *avarice* heavily, which is the honest reading of both.

## 5. Terminology note

There's a live translation problem worth fixing alongside this: **`symbols.json` (21 old entries) and `pressure_sources.json` (41 focuses) are two separate vocabularies**, and both get called "symbols" in conversation. The sun is a **focus** and has no entry in `symbols.json` at all — which is why "is there a sun in the symbol list?" has a confusing answer.

`vocabulary-settled.md` fixes this for the player (**subject · focus · main focus · modifier**). Worth applying the same words to the *files* — `focuses.json` rather than `pressure_sources.json`, and retiring `symbols.json` with the old taxonomy (see `fossil-audit.md` §4).


---

## 6. Open

1. **The eight neutral values** — §3's table is a first pass. They want playing rather than arithmetic, and Illumination's especially, since it decides how ordinary a sunlit world feels.
2. **The two weights** — how much heavier Substrate and Vitality are than everything else.
3. **Does the danger-rune gift still balance?** Danger runes currently grant up to a capped +40. If typical worlds get much cheaper under the new neutrals, that cap may now be enormous.
4. **Retiring the authored `stabilityDelta` values.** They should become unnecessary rather than additive — worth checking nothing is charged twice, which is the one rule the meter has always been held to.
