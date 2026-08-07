# Answer — Q44: retiring the authored deltas, and the baselines

> **His question, in brief.** The greed fix landed and works — a sun went from −25 to −2, a mountain to +2, a dead world to +14. But the **authored `stabilityDelta` values are three to four times the emergent numbers** and were tuned against the old formula, so a greedy book is now charged twice and bottoms out at zero. §3 said they *"become unnecessary"*; §6.4 listed retiring them as open. His lean: retire them. He also **added a separate `neutral` per subject instead of moving the baselines**, deliberately, and asks whether the baselines should move too.

---

## 1. Retire them — but they are two different things, and only one should go

**His lean is right, and his reasoning is the right reasoning:** the whole argument for the two-axis model is that a focus added next year is priced correctly the moment it exists. Hand-tuned deltas are exactly what stops that being true.

**But `stabilityDelta` is doing two unrelated jobs**, and the split falls exactly along whether the symbol has a `danger` block:

### Retire these — eleven symbols whose delta duplicates greed

| | |
|---|---|
| `mote_vein` −70 · `rich_ore` −45 · `teeming_life` −35 · `gilded_veins` −30 | asking for wealth |
| `ashen` −15 · `archipelago` −12 · `verdigris_bloom` −10 · `caverns` −8 | asking for other things |
| `sparse_ore` +10 · `dim_sky` +12 · `frostbound` +8 | asking for **less** than ordinary |

**Every one of these is now measured.** Rich Ore's −45 and its emergent greed are the same claim made twice — that's the double-charging in his table. And **Dim Sky's +12 is the clearest case for retiring**: it was a hand-authored apology for a broken formula, and under proper neutrals it *earns* its stabilising effect the way Ice and Wind already do, by asking for less than ordinary. Keeping it means paying it twice for one virtue.

### Keep these — seven symbols whose delta **is** their mechanic

`storm` +22 · `blight` +20 · `swarm_rune` +26 · `predation` +24 · `miasma_rune` +18 · `tremor` +28 · `peace` −30

**These aren't greed and never were.** They are the **danger↔time axis** — *accept hostility, buy stability*, and Peace as its inverse. They already run through a separate capped path (`dangerStabilityGift`), and retiring `stabilityDelta` wholesale would delete the danger runes entirely.

**[PROPOSAL] Make the split structural rather than conventional.** Move the danger and peace values onto their own field — `stabilityTrade` on the `danger` block, say — so nothing on a symbol is ever *greed asserted by hand* again. Then "no authored greed" is enforceable rather than remembered, the same shape as the Constellation fossil guard.

### Two things to re-check once they're gone

1. **The danger cap.** Danger runes grant up to +40. If typical worlds are much cheaper now, that cap is a far larger share of the meter than when it was set.
2. **Peace's −30.** It's the one *cost* in the danger family, tuned against the old scale. Worth re-measuring alongside the cap.

---

## 2. Don't move the baselines — his separation is better than my spec

**He's right, and this is a case where the implementation improved the design.**

My §3 said *"the baselines are the actual bug"* and proposed moving illumination's from 0 to 45. **That conflated two genuinely different quantities**, and he's identified the distinction precisely:

- **`baseline` is physics** — what a subject reads when nothing acts on it. A world with no light source really is dark. **Illumination 0 is correct.**
- **`neutral` is judgement** — what an *ordinary* world has. An ordinary world really does have a sky. **That's what greed should measure against.**

**And the blast radius argument is decisive.** `baseline` is the floor that rolled sources build on, and it feeds terrain, life caps, creature budgets and descriptions. Moving illumination's to 45 would mean **an unwritten world is mid-lit** — a much larger change than the meter fix, arriving as a side effect of it. That's precisely the kind of coupling that produces a bug three sessions later that nobody traces back.

**So: keep them separate, don't move the baselines.** If a lit-by-default world is ever wanted, it should be its own change, with its own measurements, decided on its own merits — which is what he offered.

**Worth recording as a general principle**, because it will come up again: **physics and judgement should not share a number.** A quantity the simulation needs and a quantity the scoring needs will drift apart eventually, and merging them means every later tuning of one silently retunes the other.

---

## 3. On the numbers he measured

The three-book table is the right instrument for this, and it's what made the double-charge visible. **Worth keeping as a test** rather than a one-off measurement: assert that no book's emergent greed and authored stability are both large and in the same direction. That's the shape of the fault, expressed so it can't come back.
