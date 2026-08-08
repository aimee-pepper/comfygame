# Comprehensive Audit (2026-08-07, commit `3a9602c`)

**561 tests, 35 docs, 47 questions.** Everything from every prior audit, re-checked — not just the newest commit.

**Headline: nothing has regressed, four things landed well, and four clause-audit findings are unchanged since I reported them.**

---

## 1. Landed since the last full check

| | Verified |
|---|---|
| **Party of five in combat** | ✅ `Combatant.companion` now carries an index; `rosterIndex` throughout `CombatRules` |
| **Ranks for five** | ✅ Per-character `rank`, set at the fire |
| **Session 17 stats** | ✅ `might · finesse · fortitude · perception · wit` on `Character` |
| **Levels and XP** | ✅ `level`, `experience` |
| **The Wit rename** | ✅ And the comment records why: *"focus is the writing word now"* |
| **Vocabulary rename** | ✅ Palette reads **Subject** and **Focuses**; comment notes *"Causes was my word and Aimee's answer was focuses"* |
| **`inertRungs` → `inertModifiers`** | ✅ With a comment recording that *rung* was an undefined spec coinage |
| **🐛 Stability range** | ✅ **Fixed properly** — `stabilityScore: ClosedRange<Int>`, and `rolledStabilitySpread` genuinely models what unwritten subjects could do. The comment states the principle: *"the price is certain, the world is not"* |
| **Q44 double-charge** | ✅ Greed now charged on **everything the book says**, clusters and compounds alike, so *Rich Ore* and *"great iron, gold"* cost the same |
| **Five new focuses** | ✅ chasm · silt · stillness · tide · orrery — see `rune-work-collation.md` |

## 2. Still open from the clause audit — **all four unchanged**

These were reported in `clause-audit.md` and none has moved. **Not chiding — three of the four have never been handed to him as work.** Recording so they don't drift out of view.

| | Finding | Status |
|---|---|---|
| **F1** | **Global percentile doesn't exist.** Session 3 said *"personal + global, both shown"*; only personal is built | unchanged |
| **F2** | **Analysis progression has no acquisition path.** All five tiers implemented; `analysisTier` is written only by `Debug/HarnessActions`. **Tiers 3 and 4 are finished work no player can see** | unchanged |
| **F3** | **Compound assembly has no gate.** Session 10 §4 said skill-tree unlocked; nothing checks | unchanged |
| **F4** | **Focus icons are SF Symbols** — `aqi.medium`, `rays`, `camera.macro.circle`. The retired symbols got glyphs; the vocabulary that replaced them didn't | unchanged |

**F2 is the one I'd raise first.** It's a whole progression axis, it's specced, it's *implemented*, and there's no way in. `cast-roster.md` proposes the fix — **field instruments from Mara's Survey Post** — which turns it from a missing system into a wiring job.

## 3. Verified still honoured — no regressions

Re-checked rather than assumed:

- **No wall-clock in gameplay.** One `Date()` in `SaveFileIO`, for a backup filename. Clean.
- **Q17 — ruins pay no essence.** All three ruin types at 0; landmarks and living sites keep theirs.
- **Q19 — sites are guarded, not destabilising.** `SiteRules.stabilityDelta` is **built, tested, and deliberately not wired**, with a comment at `WorldsState:79` saying so. **That's the right state** — Q19 chose guarding now and derived instability later, and this is that decision held rather than drifted.
- **Contradiction charged, greed self-balancing, cost exact.**

## 4. The one thing worth watching

**Site `stabilityDelta` values now exist in `sites.json`** — landmark −8, living −5, hazard −12 — while `SiteRules.stabilityDelta` remains unwired.

**That's a loaded gun, not a bug.** The values are authored and dormant; the moment someone adds the call, sites start destabilising worlds and the Q19 ruling silently reverses.

**[PROPOSAL]** either a comment on the JSON saying these are dormant pending the Q19 migration, or a test asserting they aren't summed into any live score. The existing comment is in the Swift; the values are in the JSON, and those are read by different people.

## 5. Specced and handed over, not yet built

**Recent handoffs — no action owed:**
combat trees (3×3) · building staffing · the 16-person trade roster and Lys the archivist · Isolde's Hush · the sigil purpose audit (11 cuts, Ring reinstated, Meteor as hazard) · random companion spawn rules · the subtractive-word additions.

**Longer-standing:**
identification as permanent knowledge · use-to-identify · more consumables and curios · the Tavernkeeper and firepit→tavern · Light/Shadow palette sections · the moon's night floor · Rift/Void merge · rune pacing (needed set, pity, hard floor) · the *"you don't have the words"* marker · per-building trees (Q40) · the Exchange (Q41) · flora · predation · anchoring's three routes · the escape item.

## 6. His open questions

**Q46 §3 — the thin subjects.** Answered in `rune-work-collation.md`: Atmosphere has **one** downward word, Cycle has one, Substrate has two. Seven additions proposed.

**Q47 — traveller pacing.** His Isolde fix is a defect fix and stands (67% → 26% of blank books). **The three levers are genuinely Aimee's**, and worth answering soon because `the-cast.md`'s condition scaling (2 → 12) is a partial answer to lever 1 already.

**My view on lever 3 — should finding someone need the clue in hand?** Gating placement on `knownTravellers` would make the diary genuinely *how* you find people. But it removes the accidental meeting, which is a good moment and is how a player learns that travellers exist at all. **A middle: the first traveller can be met blind; everyone after needs the clue.**

## 7. Content volume

| | Count | Against |
|---|---|---|
| Focuses | **44** | ~85 proposed |
| Modifiers | 17 | ~25 proposed |
| Compounds | 14 | reclassified, ungated |
| Danger runes | 7 | complete |
| Skills | 13 | 12 specced, complete |
| Resources | 23 | complete |
| Items | 48 | consumables still thin — **1** |
| Travellers | **6** | **~28 proposed** |
| Sites | 7 | |
| Creatures | 3 authored *(generation is live)* | |

**The two real gaps are travellers (6 of ~28) and consumables (1).** Both are content rather than systems, and both are now specced.

## 8. Assessment

**On track.** The systems are in good shape — generation is end-to-end, combat has five people and real trait interaction, the writing desk works, and the greed model is coherent after two significant corrections.

**What's thin is content and the last few progression hooks.** Six travellers against twenty-eight, one consumable, and an analysis axis with no door into it. None of that is architectural; all of it is filling in what the systems are already built to hold.
