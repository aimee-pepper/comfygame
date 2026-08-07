# Code Audit #16 + Why My Audits Missed These (2026-08-06, commit `82b9104`)

516 tests. Six half-built decisions found and fixed — **by him, from Aimee's prompt, not by any of my fifteen audits.** The second half of this document is about why.

---

## Part 1 — The six, verified

| Decision | What was half-built | Now |
|---|---|---|
| **Ranks** | Both damage halves built; **targeting left uniform**, so the back rank was pure upside — less damage *and* no less chance of being picked | Target selection prefers the front; far reach and elemental foes ignore the line; if everyone's at the back there's nobody to hide behind |
| **Nobody dies** | Defeat needed **both** at zero, so a Binder at zero kept walking on Quill's legs | Binder at zero ends the run as a collapse, per session 17 |
| **Discovery XP** | Sites and travellers wired; **`.species` and `.page` defined and never awarded** — two of three stated sources paid nothing | Both award |
| **Traveller placement** | Built the fallback, not the preference | Fitting site preferred, fallback when none exists |
| **Q36 secondaries** | Insulation and reactivity did nothing outside the Blacksmith's asking bar | What you wear turns aside heat; what you swing leaves something in the wound |
| **Fall Back** | Held for ranks, which then landed | Built |

**Plus both fossils cut** (`extra_symbol_slot`, `essence_head_start`), and **the guard I asked for is in**: every Constellation effect must be consumed somewhere, asserted in `EconomyTests`.

**One honest note in his commit worth repeating:** Q36's answer assumes gear knows what it's made of, and found gear is a catalogue entry. He authored the effects on the gear instead and **said so** rather than claiming the spec was met.

---

## Part 2 — Why fifteen audits missed all six

Aimee asked. The answer isn't "I didn't look hard enough" — it's that **I was auditing the wrong thing, in a way that was structurally blind to exactly this class of fault.**

### What I was actually checking

Every audit followed the same method: **take a decision, grep for evidence it exists, confirm.** Does contradiction fire? Does the cast reach worldgen? Are ruins paying essence?

That method answers **"was this built?"** It cannot answer **"was all of this built?"** — and every one of the six *was* built. Ranks existed. Defeat existed. Discovery XP existed. I found the evidence I went looking for and stopped.

### The specific blindness

**A decision has several clauses; I checked whichever one was easiest to grep for.**

*"Front takes the melee hits and deals full melee damage"* is two claims. I grepped `backRankProtection`, found it, and moved on. **The damage clause was searchable; the targeting clause required asking what wasn't there.**

Same shape every time:
- `.species` and `.page` **existed as enum cases** — a grep for them succeeds. Only their *award sites* were missing.
- Traveller placement had a rule — just the fallback rather than the preference.
- Ranks, defeat, secondaries: all present, all partial.

**Absence inside a present thing is invisible to grep**, and grep was my whole method.

### Three habits that made it worse

**I audited what changed, not what was claimed done.** Each audit looked at the newest commit against the newest decisions. A decision built two sessions ago and never revisited was never re-examined — and half-built things stay half-built silently.

**I treated his commit messages as evidence.** They're unusually good, which made it worse: a message saying "ranks landed" reads as completion, and I checked the code for *ranks* rather than for *every clause of the ranks decision*.

**I never wrote the decisions down as testable clauses.** My specs are prose. *"Front takes the melee hits and deals full melee damage"* is one sentence containing two independently-verifiable claims, and I never split it into two.

### What I'm changing

**1. Audit against a clause list, not a grep list.** Break each decision into its individually-false-able claims and check each. *"Back rank takes less damage"* and *"back rank is less likely to be targeted"* are two rows, not one.

**2. Ask what's missing, not what's present.** For every enum case, effect kind and reward source: **is it awarded/read/consumed anywhere?** The Constellation guard he just built is exactly this, generalised — `.species` and `.page` were the same fossil pattern, defined and never fired.

**3. Re-audit old decisions, not just new commits.** Rotate through the decisions log rather than only diffing the latest work. All six were reachable at any point in the last several audits.

**4. Say when a spec is untestable.** *"Front takes the melee hits"* should have been written as two clauses from the start. Prose that can't be checked is prose that won't be.

### The uncomfortable part

He found these because **Aimee asked him to audit himself against the stated design.** That is the question I should have been asking every time and wasn't — I was asking *"is the newest thing right?"* instead of *"is everything still right?"*

**Reviewing the newest work is the easy half of an audit.** The valuable half is checking that old decisions are still fully honoured, and I hadn't been doing it once.

---

## Part 3 — Still outstanding

**From the current handoff:** the greed/neutral-baseline rework · the stability range · identification as knowledge · use-to-identify · more consumables and curios · the Tavernkeeper · Light/Shadow sections · the moon's night floor · Rift/Void merge.

**Longer-standing:** rune pacing · the *"you don't have the words"* marker · stats and levels · per-building trees (Q40) · the Exchange (Q41) · flora · predation · anchoring · the vocabulary rename · **the party of five reaching combat** (roster holds five, one fights).
