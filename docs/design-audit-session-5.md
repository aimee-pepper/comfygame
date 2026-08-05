# Design Audit — repo vs. decisions (2026-08-04)

**From:** designer Claude · Audited commit `88f0643` against `decisions-log.md` sessions 2–5, the v0 brief, and `writing-system-rune-spec.md`.

**Verdict: fidelity is high.** Every locked decision I could test for is honoured, and `deviations-audit.md` is an honest document — the three fixes in it are real fixes, not restatements. Rulings on the open questions at the end.

---

## 1. Verified faithful

| Decision | Status |
|---|---|
| Pillar 2 — no wall-clock in gameplay | ✅ Only `state.meta.lastSavedAt = Date()`, commented "diagnostics only — no gameplay rule may read this". Clean. |
| Save after every mutation; force-quit resume incl. mid-encounter | ✅ Tested (`testEveryMutationIsPersistedAndCounted`, `testAFightSurvivesAForceQuitMidRound`, `testRelaunchResumesExactly`) |
| Cost is one exact number; outcomes ranged | ✅ Bind shows a single figure; range language appears only on the stability bar |
| Motes losable on collapse | ✅ Cut by `collapseHaulKeptFraction`; they bank to Reality, they aren't immune |
| Eleven starter symbols | ✅ Exactly the eleven named |
| Entry portal doubles as exit, plus 1–2 more | ✅ |
| Gambit editing out-of-combat only | ✅ Enforced in the store, not just hidden in UI |
| Bestiary in Reality layer, silhouette until met | ✅ |
| Satchel decoupled, smaller, items-only | ✅ (but see §3.2) |
| Slots fully data-driven | ✅ No enum, no count constant |
| Three-layer save separation | ✅ `testResetBaseKeepsReality` |
| Nothing advances without player action | ✅ `testNothingHappensWithoutAPlayerAction` |

**Session-5 tuning flags — both acted on, and better than asked.** Vision 2→3 with the reasoning recorded. Locked cache 0.5→0.4 with an explicit key-supply calculation (≈0.7 keys/run vs 0.4 caches/run) showing key supply outruns cache supply after a run or two while the *first* cache stays reliably unopenable — which is the moment the design wants. Correctly annotated "move these two together, never one alone."

---

## 2. Live design thread

Gambits are now a compositional grammar (subject + property + comparator + threshold + action) and the writing system is heading the same way. Session 3's Q-D put symbol and gambit acquisition on *parallel tracks* — worth revisiting, since they're much more similar systems than they were when that was decided.

---

## 3. His flagged items — rulings

### 3.1 Manual override (his #4) — **keep as built (A)**

Pre-emptive override is correct. You tap the companion on your turn to claim their next turn; their turn then waits for you.

The literal FF12 reading is ruled out. Any "intervene during their turn" design requires either a window (a timer — outright forbidden) or a prompt every round (which breaks unattended fighting and makes the game demand attention at a moment it chooses). Nothing may resolve differently because of how fast the player reacts, or whether they reacted at all. The game must sit still indefinitely at every point.

Claude Code's judgement here was right and his instinct to flag it was also right — but the answer is A.

### 3.2 Satchel "keep or leave it" (his #5) — build the real decision

Correctly identified: a notification is not a decision. Build the prompt — what dropped, what you're carrying, choose. This is the itemization pillar's in-world half; without it the satchel is just a smaller number.

### 3.3 Rarity ladder invisible (his #6) — fix

Common/Uncommon/Rare/Mythic must be visible and colour-coded. An entire designed axis rendering identically is a straightforward miss.

### 3.4 Skill cooldown (his #7 / Q11) — **blessed**, with a preference

Keep the round-counted cooldown. It's the right call and the knock-on he found — a skill on cooldown falls through to the next gambit rule, so cooldowns are what make rule *order* matter — is a genuinely good emergent property.

Preference for later: when the economy is richer, consider **charges that refill on returning home** as an *additional* layer, since it ties combat to the run economy. Not now.

### 3.5 Q10 — items that don't fit when banking

**Never lose silently.** Build the overflow: banking refuses to discard, and anything that doesn't fit goes to a **spillover** the Storehouse holds until sorted. The player then chooses at leisure, at home, with full information — which is the right place for that decision, unlike the satchel one, which belongs in the world.

Auto-converting to essence is the wrong answer: it quietly prices a Mythic drop at scrap value.

### 3.6 Q9 — entry portal as exit

Already decided (session 2, #6): keep as built. No change.

---

## 4. Nothing outstanding on my side

Sessions 2–5 decisions are all either built, scheduled, or correctly flagged as questions. The writing-system order-invariance test isn't present yet, which is correct — the system doesn't exist. It should land with the first sigil code.
