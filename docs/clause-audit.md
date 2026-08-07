# Clause Audit — every decision, checked clause by clause

**Why this exists.** My previous fifteen audits used one method: take a decision, grep for evidence it exists, confirm. That answers *"was this built?"* and cannot answer *"was **all** of this built?"* — which is why six half-built decisions survived every one of them and were found by Claude Code instead.

**This audit breaks each decision into its individually-falsifiable claims and checks each separately.** Sessions 1–15 in `decisions-log.md`, plus sessions 16–17.

**Result: three genuinely unbuilt clauses inside decisions that read as done, and two more that are scaffolded but unreachable.** Everything else in the log is honoured — several things more thoroughly than specced.

---

## FINDINGS

### F1 — The global percentile does not exist (Session 3, §4a)

**The clause:** *"This is where computed-rarity percentiles live (**personal + global, both shown**)."*

**Built:** `Discovery.percentile(of:by:)` — measures a specimen against **peers of its own kind that you have personally met**. That's the personal half.

**Not built:** any percentile against a fixed global distribution. There is no notion of *"top 3% in nature"* anywhere.

**Why it matters:** the two halves do different jobs and the spec was explicit about both. Personal carries the early game (*"finest pelt you've recovered"*); **global is what keeps a late find objectively meaningful** once you've seen hundreds and your personal distribution has drifted. Without it, "rare" quietly stops meaning anything the longer you play — which is precisely the failure the two-percentile design existed to prevent.

**Scope:** the same clause governs material grades (`materials-crafting-spec.md` §4), so the gap is wider than the bestiary.

### F2 — The analysis progression has no acquisition path (Session 8, §3–4)

**The clauses:** five tiers · *"analysis is a third progression axis"* · *"analysis comes from **instruments**, crafted from materials"* · field instruments · the page lens · *"the lens only shows you what you have already measured"*.

**Built:** all five tiers are defined in `Tuning.Analysis`, and **tiers 3 and 4 are genuinely implemented** — `showsAttribution` gates the red/green underlining exactly as specced, and `analysisTier` threads correctly through `DescriptionRules` and `BookProjection`.

**Not built:** any way to raise it. `analysisTier` is written in exactly **two** places — decoding a save, and `Debug/HarnessActions.swift`. **There is no in-game route past tier 1.**

**And no instruments exist at all** — no field instruments, no page lens, no readings-feed-the-lens link. The word appears only in comments.

**Why it matters:** this is a whole progression axis, sitting beside vocabulary and page space, and it is currently unreachable in play. Tier 4's red/green attribution is *finished work no player can see.* It's also load-bearing for `world-history-and-feedback-spec.md` — the world history is designed to become readable *as analysis rises*, which currently never happens.

### F3 — Compound assembly has no gate and no unlock (Session 10, §4)

**The clause:** *"assembling a composite sigil is **unlocked in the skill tree**, not available from the start."*

**Built:** compounds exist as a page content type (`Page.swift`), render, and have a palette section.

**Not built:** the gate. No `compound` node in `research.json`, no `canAssembleCompound` anywhere. Nothing checks whether the player has earned the ability.

**Why it matters:** compounds are the second half of the writing progression — the hands shrink footprints, compounds compress meaning. Handing them over ungated gives away half of what `hands-and-calligrapher-spec.md` is designed to sell.

### F4 — Focus icons are still SF Symbols (Session 11, §4)

**The clause:** *"Runes need icons that represent their shape."*

**Built:** the old `symbols.json` entries got glyph shapes (13 of them).

**Not built:** the **focuses** — the vocabulary the player now actually writes with — still use SF Symbols: `aqi.medium`, `rays`, `camera.macro.circle`, `tree.fill`, `cloud.fill`, `comet`.

So the runes that were replaced have glyphs, and the runes that replaced them don't. **[AIMEE]** flagged the interim guidance already: *a wrong-but-glyph-shaped placeholder beats a correct-looking app icon.*

### F5 — Session 3's satchel clause is honoured; noting it because I mis-checked it before

Resources live in a `ResourcePool` separate from `inventory`, so they consume no item slots. **Correct.** I record this because in an earlier audit I checked for the wrong symbol name and reported it as unverifiable.

---

## VERIFIED HONOURED — clause by clause

**Session 3 — bestiary and forward-compat**
- Specimen tier stores raw trait vectors ✅
- Identity derived at read time, never stored as the key ✅
- Silhouette until first encounter ✅
- **`FoeState.stats` is a resolved `CombatStats` in the save** ✅ — and better than specced: `identityKey` is *also* stored, so a later change to identity regions can't rename a creature mid-fight
- Item instances carry `MaterialSample` rather than a catalogue pointer ✅
- Personal percentile ✅ / global ❌ (F1)

**Session 7 — the search loop**
- Pages are partial descriptions that accumulate ✅
- One page, one unlock ✅
- Weighted placement with an anywhere-fallback ✅ — tested as *"nothing may become permanently unreachable because of how a player happens to write"*
- Hint page shows a **count** of missing pieces, never their kind ✅

**Session 10 — the page**
- Fixed size, never grows ✅
- Fits one screen, no scrolling ✅
- Sigils pick up and move ✅
- Compound assembly gated ❌ (F3)

**Session 11**
- Blank page → no description; only what you wrote ✅
- Palette sectioned by subject ✅
- One main focus per subject, single chaining unlock ✅
- Glyph icons ❌ for focuses (F4)

**Session 14 — the grammar**
- Target-first ✅
- Adjacency **and** an explicit join ✅
- Clusters move and rotate as one object ✅
- **Both invariant tests exist** ✅ — translating the whole page changes nothing, *and* rotating a cluster changes nothing. Plus the converse asserted: breaking a link **does** change what the page says
- One-tap disconnect ✅

**Session 15 — the cast**
- Cast sampled per world, deterministic in the seed ✅ (so an anchored world would keep its cast, once anchoring exists)
- Vitality sets cast **size**, not spread ✅
- Free sampling, identity derived ✅
- **Jitter never changes identity, combat, or drops** ✅ — and *asserted*, not merely commented: three separate assertions in `LifeTests`

**Sessions 16–17** — verified in audits #14–16: roster of five ✅, ranks including targeting ✅, defeat on Binder at zero ✅, discovery XP from all three sources ✅, party restored on return ✅, items usable in the world ✅, both fossils cut with a guard test ✅.

---

## What changed in my method

Four things, applied above:

1. **Every decision split into individually-falsifiable claims** before checking. *"Front takes the melee hits and deals full melee damage"* is two rows, not one.
2. **Checked for absence inside presence.** F2 and F3 are both *"the thing exists; nothing reaches it."* Grep finds the thing and stops — the question has to be **"who writes this? who consumes it?"** `analysisTier` is read in eight places and written in one debug file, which is the whole finding.
3. **Audited old decisions, not the newest commit.** F1 dates to session 3, F2 to session 8. Both were reachable in every audit since.
4. **Recorded what's honoured, not only what's broken** — otherwise the next audit re-checks everything from scratch and samples again.
