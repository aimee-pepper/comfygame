# Code Audit #15 (2026-08-06, commit `fb55e99`)

507 tests. The recruitment problem is fixed properly — a roster exists, recruiting fills it, and the Firepit gives people somewhere to be.

---

## 1. Recruitment — fixed, and the diagnosis was the right one

`BaseState.roster` replaces the single hardcoded slot. Recruiting now puts a person in it with **their name, their calling, and a rule list.** Room for five. Ranks are set at the fire, never mid-fight — the same rule as gambits, which is the right consistency.

**The `companion` computed property is a good migration choice** — the hundred places reading `base.companion` keep working while the roster lands underneath. That's how to change a load-bearing shape without a big-bang rewrite.

**And the Firepit is built exactly as specced:** present from the start, `builtBy` empty — the one exception to found-then-built, because you need somewhere to put the first person before anyone can build anything.

## 2. Party of five — the roster holds five, combat doesn't yet

`activeCompanion` is flagged `[PLACEHOLDER]` and the comment is honest: *"a party of five fights together and that's the next piece; today one of them comes along."*

**`CombatRules` has no reference to `roster` or `activeCompanion`.** So today: five on the roster, one in the fight.

**Not a gap to chase yet** — it's the correct order. The roster had to exist first. But two things depend on it and are worth naming so they don't get built twice:

- **Ranks** (session 17) are close to meaningless with a party of two; five is what makes front/back a real composition decision.
- **Gambits scale with party size.** Five rule lists is where the automation system either pays off or becomes a chore — and it's where Wit-governed slot counts start to matter.

## 3. Also landed

- **Items usable in the world** — `useItemInWorld(_:on:)`, for the price of a turn.
- **The party is restored on coming home**, reading earned Fortitude rather than a constant.

## 4. Outstanding — nothing owed, listed for tracking

**From the current handoff** (just received): identification becoming permanent knowledge · use-to-identify · more consumables and curios · the Tavernkeeper and the firepit→tavern upgrade · Light and Shadow sections · Second Light cut · the moon's night floor · the Rift/Void merge · **the stability-range bug**.

**Longer-standing:** rune pacing (tiers, needed set, pity, affinity, hard floor) · the Library's *"you don't have the words for this one"* marker · session 17's stats, levels, ranks and escape item · per-building trees (Q40) · the Exchange (Q41) · flora · predation · anchoring's three routes · the vocabulary rename.

**Of those, the stability range is the one I'd pull forward** — it's small, it's a correctness problem rather than a feature, and it's showing the player a certain number for an uncertain world on every single bind.

## 5. One thing to watch

`roster: [CompanionState] = [CompanionState()]` — Quill is index 0 and always present. Fine, but it means **the roster is never empty**, so any future code asking *"do I have anyone?"* will always get yes. Worth a distinct notion of *recruited* versus *starting* if anything ever needs to know the difference — the Firepit's own progression being the obvious candidate.
