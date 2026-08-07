# Reading What You Wrote — the missing feedback loop

**Status:** Claude's design, from Aimee's brief and a live failure while playing.

---

## 1. What happened

Aimee read Mara's clue — *"There is no shadow anywhere. I have looked."* — reasoned that it meant a very bright world, wrote **a giant sun**, and Mara wasn't there.

**Her reasoning was correct.** Mara's signature is a single condition: **illumination peak ≥ 60**. Bright *is* the right answer.

Two things could have stopped it, and **she has no way to tell which**:

### Suspect 1 — "giant" is Scale, and Scale does nothing
Only `sigil.intensity.multiplier` reaches the resolver. **Scale is written, displayed, and consumed by nothing.** So a *vast* sun is a plain sun — she needed *great* or *overwhelming*.

This is a genuine trap: **"giant sun" reads as scale in English and needs to be intensity in the game.** And the interface gave no sign, because the qualifier was accepted and shown.

### Suspect 2 — an unwritten target rolled against her
Atmosphere left blank can roll occluding — cloud, ash, mist — which suppresses illumination peak. The same mechanism that produced *"frozen over"* on a world she never wrote as cold.

### The actual finding

**A wrong deduction currently teaches nothing.** You write a world, the person isn't there, and you learn *nothing about why*. Was the reading wrong? The qualifier? Did something roll over you? With no feedback, the deduction loop — which is the heart of the search — can't be learned by playing.

That's not a hard puzzle. That's a puzzle with no answer key, ever.

---

## 2. Aimee's two requests, which are the fix

### 2.1 "The World" page lists the sigil chains you placed

> *"the 'The World' page should list the sigil chains you've placed on the page"*

The world pane describes the world but doesn't show **what you wrote to get it**. Adding the chains puts cause and effect on one screen, so the description stops being an oracle and becomes a *readout of your own writing*.

**[PROPOSAL]** list each cluster as its target and connected sources with their qualifiers — *Illumination ← great Sun* — because that's the level at which a mistake like *vast* versus *great* becomes visible.

### 2.2 A history of visited worlds, in the Library

> *"there should be a history of visited worlds that you can erase or save from a tab in the library. that way once you get the lens you can go over the world generated info on previously visited worlds"*

**This is the answer key**, and it's a very good one because it's *delayed* rather than given.

- Every visited world is recorded: its **page** (what you wrote) and its **readings** (what it became).
- **Saveable or erasable**, so the list is curated rather than infinite.
- **What you can see of it grows with your analysis tier.** At tier 1, the description you already saw. Later, the actual numbers. With the **page lens**, full attribution — including which unwritten targets rolled and what they did.

**Why this is the right shape:** it doesn't explain your mistake at the moment you make it, which would violate "explanation is earned." It records the evidence and lets you come back and read it once you've learned how. The world where Mara wasn't becomes, later, the world where you can finally see that Atmosphere rolled ash and ate your sunlight.

It also makes the analysis instruments dramatically more valuable — they don't just help with the next world, they **unlock everything you've already done.**

---

## 3. What I'd fix beyond the two requests

### 3.1 Give Scale a job, or stop accepting it — this one is a bug in effect

A qualifier that is offered, accepted, displayed, and does nothing is worse than one that doesn't exist. Two ways out:

- **Wire it** — session 13 already specced Scale as world size. That's a real job and it's specced; it's just not connected.
- **Or hide it** on sources where it does nothing, until it is.

**Either is fine; the current state isn't.** This is the single most likely cause of the failure above.

### 3.2 **[PROPOSAL]** Say when a signature was *nearly* met

Not what was missing — that's the answer. But something like *"someone could have been here"* when a world clears most of a traveller's conditions and misses one.

That's the same near-miss idea already specced for named places, and it turns a dead end into a hot-and-cold signal without giving anything away. **[AIMEE]** — it may be too generous.

### 3.3 Passages should hint at the measure, not just the sensation

*"There is no shadow anywhere"* is beautiful and it's genuinely ambiguous — no shadow could mean blazing light, or diffuse light with no direction, or no light at all to cast one.

Worth a pass over the passages asking: **could a careful reader arrive at the wrong pressure entirely?** Ambiguity about *how much* is good. Ambiguity about *which target* is a trap.

---

## 4. Why this matters more than it looks

The search loop is the spine of the story half, and it currently has **no learning curve** — you either guess right or you're told nothing. These two features convert it into a system you get better at: you write, you fail, you record it, and later you read back your own failures with better instruments and understand them.

That's the same shape as everything else in the design — knowledge earned rather than given — applied to the one place it was missing.
