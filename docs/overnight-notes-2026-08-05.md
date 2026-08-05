# Overnight notes — 5 Aug 2026

Every judgement call I made while Aimee was asleep, so they can be audited rather than discovered.
Anything here can be reverted without unpicking anything else.

---

## 1. Symbols are now compounds (the load-bearing one)

**The problem.** The pressure model — 8 targets, 41 sources, cross-target constraints, the energy
budget — was fully built and fully tested, and **nothing in the app called it.** It was an island.
Worlds were still generated entirely from the old 14-symbol catalog. Meanwhile the sites system
needs pressure readings to test its conditions, so it couldn't be built on top of nothing.

**The call.** Every symbol now declares `expandsTo` — what it says in the atomic vocabulary.
Frostbound is *Ice → Thermal* plus *Snow → Hydrology*. Rich Ore is *great Iron* plus *Gold*.

I want to be clear this isn't me inventing a third system to bridge two others. The rune spec's own
§9 defines a **compound** as "a learned single glyph meaning what several components mean together,
at a smaller footprint" — which is precisely what the v0 symbols are. Spelling them out is
translating the coarse vocabulary into the fine one.

**What it buys:** every world now has a real climate, hydrology, substrate and character, derived
through the constraints, today, with no page UI. **What it costs:** the 14 expansions are my
readings of each symbol's blurb and existing numbers. They're PLACEHOLDER and they're the most
likely thing in this batch to want your eye.

**What did *not* change:** `stabilityDelta`, `yieldModifiers`, `enemyTableModifiers`, `visionDelta`
still drive the v0 loop exactly as before. Pressures ride alongside. Nothing about how a book plays
today was rebalanced by this.

## 2. Sites (`docs/sites-system.md`, built as specced)

Seven sites: Wayfarer's Camp, Binder's Workshop, Glacial Vault, Crystal Cavern, Geyser Basin, Brood
Warren, Tear. The doc suggested starting with 4–6; I went to 7 to cover all five categories.

Faithful to the doc on the points it was emphatic about:
- **Conditions are threshold ranges, never exact matches.** There's a test asserting a family of
  worlds can host the Glacial Vault, not one specific seed.
- **Rarity is emergent from condition narrowness**, not a rarity tag. There is no rarity field.
- **Hazards are produced by contradiction, not contributors to it.** The Tear has *no* pressure
  conditions — it keys off `totalOpposed`, the gross opposed magnitude. A world that argues with
  itself tears. There's a test that an honest but extreme world does *not* tear.
- **Greed is charged on total world value** (the audit correction carried into §0): a run's decay
  now reads `book score + site deltas`, so a book that happens to place a Crystal Cavern is
  genuinely more unstable than the same book that didn't.

Judgement calls inside that:
- **Guardians stand *on* their site**, so the fight is the price of the search rather than a new
  mechanic. Searching under a guardian is refused and doesn't cost a turn.
- **Searching takes turns** (1–3), and contents land only on the turn it completes — so a
  force-quit mid-search resumes mid-search with nothing granted and nothing lost.
- **Taught symbols bank to Base immediately**, not into the satchel. Literacy is permanent (rune
  spec §1), so a collapse can't take back what a ruin taught you. Tested.
- **1–3 sites per world** (`Tuning.Sites.perWorldCountRange`). PLACEHOLDER.
- I did **not** build site items into the satchel yet — `contents.items` is honoured by the catalog
  and validated, but granting them needs to route through the loot-decision flow you specced, and
  I'd rather do that properly than bolt it on.

**Two questions logged rather than answered** — Q17 (sites grant essence, because no "research
points" currency exists and inventing one is your call) and Q18 (whether the preview should show
which sites a world can host — the doc leans yes-as-silhouettes; I left it a surprise for now).

## 3. Two stale comments corrected

`BookRules.resolveBook` still claimed random fills "draw only from symbols the player owns", and
`BookProjection.SlotPlan.candidates` said the same. Both were describing the behaviour from before
your correction. The *code* was right; the comments were lying about it.
