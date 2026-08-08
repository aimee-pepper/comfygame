# Comprehensive Audit #2 (2026-08-07, commit `6d6b538`)

**596 tests, 47 docs, 47 questions.** Two new docs from him — `for-design.md` and `the-queue.md` — plus a large archive reorganisation.

**Headline: three of my four clause-audit findings are closed, the fourth is halfway, and he found a fault class underneath the greed fix that neither of us had a method for.**

---

## 1. The clause-audit findings

| | Finding | Status |
|---|---|---|
| **F1** | Global percentile missing | ✅ **CLOSED** — `BestiaryRules.globalPercentile`, shown in `BestiaryView` alongside personal |
| **F2** | Analysis progression unreachable | ⚠️ **HALF** — `analysisTier` now rises in `EconomyRules` via four research nodes (*Grind a lens*, *Rule and gauge*, *The fine scale*, *The long glass*). **He calls this a placeholder himself** and queues the real system |
| **F3** | Compound assembly ungated | 🔴 **OPEN** — still no gate in `research.json` |
| **F4** | Focus icons are SF Symbols | 🔴 **OPEN** — `aqi.medium`, `rays`, `camera.macro.circle` |

**F2's placeholder is the right call.** Four generic +1 nodes is not the design, but it means the five tiers are reachable *today* rather than after the instrument system lands. He's flagged it as temporary in `the-queue.md` §2 rather than letting it pass as done.

## 2. The finding underneath the greed fix — his, and it's a class of fault

**`for-design.md` §0.** Once writing started at *ordinary* rather than at zero, he measured what the vocabulary could actually say and found:

> **33 of 97 authored contributions are subtractive, and thirteen focuses wrote literally zero.**
> `canopy` shades light by 35 and did nothing. `salt` suppresses life by 25 and did nothing. *A salt flat where nothing grows* was not a sentence the vocabulary could say.

**Readings clamp at zero and four subjects started there**, so every subtraction from nothing was nothing. A third of the vocabulary was inert and no audit had caught it — mine included.

**The method he names is the valuable part**, and it generalises past this:

> *"What does this word do when there is nothing for it to act on?"*

That's the same shape as *what would be observably different if this clause were false* — the question that caught the six half-built decisions. **`ReachableContentTests` now asserts every clause can be said, every site hosted, every creature housed, every condition satisfied**, and it immediately found three more faults none of which were his.

**Two corrections to me in there, both right:**
- **He nearly overwrote my neutral table and didn't.** His first pass concluded Vitality's neutral of 40 sat above what any life source could write, so the table was too high. **It wasn't — the floor was too low.**
- **My "physics and judgement shouldn't share a number" argument was right in general and its premise was wrong here.** I argued illumination 0 is physically correct — no light source, no light. Once writing starts at ordinary, an unwritten world isn't *a void being lit*; it's *an ordinary world being changed*.

## 3. Flora has started, and for the right reason

`6d6b538` fixes the exact thing `crafting-spec.md` PART FIVE flagged: **six organic resources were driven by Vitality's peak, which counts herds and swarms** — so a plain full of grazing animals and no plants produced fibre, timber, pulp, resin and toxin.

**The fix was already in the codebase**: `PressureReading.producedPeak` tracks *"how much of this came from sources that make rather than take"* and was read by exactly one thing. Conditions read it now.

**That's the material economy standing on something real for the first time.**

## 4. The two new docs

**`for-design.md`** — a live list of what's blocked on a design call, ordered by what it unblocks, in the format *question → why it's blocking → what I built meanwhile*. **The framing is the good part:** *"if you answer nothing, all of it still ships with the interpretation noted, and I'll have chosen conservatively rather than well."*

**`the-queue.md`** — everything specced-and-unbuilt, in build order, with blockers. Order set by Aimee: **flora → instruments → apexes → the traveller roster.**

**Both are things I should have been maintaining and wasn't.** My audits have been point-in-time reports; these are living documents, and the difference is that a reader can act on them without reading fourteen audits first.

## 5. Where his asks and my recent specs overlap

**Several of his blocking questions are now answered in docs you haven't handed over yet.** Worth knowing, so they don't get answered twice:

| His ask (`for-design.md`) | Answered in |
|---|---|
| **1.1 The class set** | `combat-trees-full.md` — **classes emerge from 9 branches**, so the answer is *there is no class list*, which is a bigger answer than he's expecting |
| **1.2 Skills: character or party?** | `combat-trees-full.md` — **per character**, which matches his lean |
| **1.3 The trade list = the class list** | `cast-roster.md` — 16 trades, named, with buildings and diary runes |
| **1.4 Cycle sources** | Partly built already (Tide, Orrery, Stillness); **Drift and Time still open** |
| **1.5 Q37 Tannery capacity** | Answered yes in audit #9; **still needs Aimee's yes/no on whether the old nodes disappear** |
| **§2 vocabulary shortfall** | `sigil-vocabulary.md` — 39 → 85 focuses, rated and routed |

**The one genuinely still open is 1.5** — whether the Workshop's capacity nodes vanish or stay as a parallel ladder.

## 6. Verified still honoured

- **No wall-clock.** ✅
- **Q17 — ruins pay no essence.** ✅
- **Q19 — site stability built, deliberately unwired.** ✅ Still the right state
- **Cost exact, stability ranged.** ✅
- **Contradiction charged, greed self-balancing.** ✅

## 7. Content volume

| | Now | Target |
|---|---|---|
| Focuses | **44** | ~85 specced |
| Travellers | **6** *(5 with meeting scenes)* | ~28 specced |
| Consumables | **1** | 18 specced |
| Recipes | **0** | ~60 specced |
| Instruments | **0** *(4 placeholder nodes)* | 12 specced |
| Skills | 13 | +19 for the trees |
| Rune shapes | 13 | ≥21 |

**Everything in the right column is specced and handed over or pending.** The gap is authoring and building, not design.

## 8. Assessment

**Healthy, and better instrumented than it was.** The two things I'd watch:

**One.** `for-design.md` §1.1 asks for a class list, and `combat-trees-full.md` says there shouldn't be one — classes emerge from where you spend. **That's a bigger answer than a list, and it should reach him before he builds a class system he'll then have to remove.**

**Two.** F3 and F4 have been open across four audits now. Neither is hard: compound assembly needs one research node, and the focus icons need a placeholder that's *glyph-shaped* rather than pictographic. **F4 in particular gets worse the longer it waits** — every new focus added is another icon to redo.
