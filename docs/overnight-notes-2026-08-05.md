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

---

## 4. Q10 spillover — built (Milestone 6)

Banking used to call `inventory.add(stack)` and throw the result away. `add` returns `false` when
full, so **loot coming home to a full Storehouse was silently deleted** — the exact thing the
session-5 ruling forbids. Now anything that doesn't fit lands in `base.spillover` and waits.

At the Storehouse it shows as "Waiting to be sorted", with three options per stack: store it (if
there's room), make room (swap — and the thing you displace goes *back* to the pile, so still
nothing is destroyed), or throw away, which is the only path that ever removes an item and requires
a deliberate tap. No auto-conversion to essence, per your ruling that it prices a rare drop at scrap.

7 tests, including one that force-quits with loot in the pile.

## 5. A save-compatibility bug, found by accident

Writing the spillover test turned up something worse than the spillover itself.

`BaseState` has a hand-written `init(from:)`. My new field encoded fine and then **silently decoded
as empty**, because the decoder didn't know about it. Same class of bug, more serious: `WorldRun`
used fully synthesised `Codable`, which **throws** when a field is missing rather than defaulting.
So the build you installed tonight, loading a save written by the build before it, would have failed
to decode the active run — and `SaveFileIO` would have quarantined the whole save. Mid-run, on
launch, silently.

`Migrations.swift` already claims this can't happen: *"Every layer struct decodes tolerantly, so
adding a field never breaks an old save."* `WorldRun` wasn't holding up its end. It has a tolerant
decoder now, and an explicit memberwise init so adding fields stays cheap.

**Worth knowing:** this means any save from before tonight is fine, but it's the second time a
hand-written decoder has quietly diverged from its struct. Might be worth a test that round-trips
every layer struct through a JSON object missing each field in turn. Not built — flagging it.

## 6. What I did NOT do, and why

- **Site instability is switched off.** Long version in Q19. Short version: it broke your "the
  number on the symbol is the number on the meter" rule, and that rule is a ruling while the sites
  doc's version is a `[PROPOSAL]`. So yours won and the proposal became a question. The code is
  built and tested and one line from being switched on once you've picked an option.
- **Site items don't reach the satchel yet.** `contents.items` is catalogued and validated but not
  granted, because granting it properly means routing through the loot-decision flow you specced.
  Half-doing it would have made a second, worse path for the same decision.
- **The 44pt audit and haptics** (the rest of Milestone 6) — not started.

## 7. A save test that can't be forgotten

Since the decoder-drift bug in §5 was the second of its kind, it now has tests
(`Tests/SaveToleranceTests.swift`):

- **Round-trip** a fully-populated save and compare layer by layer. This is the one that would have
  caught the spillover bug — the field encoded fine and came back empty.
- **Load a save with the new fields deleted**, standing in for one written before tonight. This is
  the one that would have caught the `WorldRun` bug.
- **A tripwire** pinning the current set of fields that genuinely *can't* go missing. If that set
  grows, someone has added a field to a struct that decodes strictly, and it fails while it's still
  cheap to fix rather than after you've lost a world.

The tripwire is deliberately not a rule — a map with no `tiles` is corrupt, not old, and there's no
honest default for it. It's a list that should shrink and must not grow.

## 8. Something the tests found that you should probably look at

A persistence test started failing *intermittently*, which turned out not to be a persistence
problem at all: a book with slots left to chance can roll Mote Vein (−70) and Rich Ore (−45) and
arrive at a world that collapses inside five steps.

That's your whole-pool ruling meeting the literal end of the steps curve. Both are working as
designed; together they mean an under-specified book can be a near-total loss, and the preview's
honest answer is a range so wide it says nothing. Written up as **Q20** with four options — I'd
weight the chance pool and improve the preview rather than change either rule, but it's yours.

I pinned the test's book rather than touch the rule.
