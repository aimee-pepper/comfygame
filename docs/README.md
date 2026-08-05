# Handoff — 3 docs

Verified against `a883f81`. Sessions 1–12 are in the repo; these are new.

## Read `audit-what-pressures-actually-do.md` first — it's the big one

**`PressureReadings` has exactly three consumers:** the description prose, the contradiction catalogue, and site eligibility. **Terrain, flora, fauna, loot, encounters and map layout don't read pressures at all** — they still come from the old symbol fields (`yieldModifiers`, `enemyTableModifiers`, `enemyTierDelta`).

So the pressure model describes worlds it doesn't generate. That's why descriptions feel disconnected from what's actually in a world — they are. Every "content pressures" table in `pressure-model.md` is unimplemented intent.

**This is a designer failure, not an engineering one.** The downstream effects were specced and validated by reading the sentences they produced, never by checking they reached generation.

**What has to happen:** wire pressures into generation (resource nodes from Substrate, spawns from Vitality and the trait pressures, terrain from Relief, map size possibly from Relief too), then delete the old symbol modifier fields — they're the parallel system keeping the real one decorative.

## `decisions-session-13.md`

- **Cycle gets real primary sources.** It had none — its primary would have been the sun, already Illumination's. Candidates in `cycle-sources-draft.md`.
- **Bigger maps AND shorter days**, half measure of each. Starting numbers to tune: **18×18** map, **~40-turn day** (four or five day/night turns per exploration). **Stability must buy proportionally more turns.**
- **The map no longer has to fit one screen** — only the page does, because you compose on a page and walk through a world. Camera: follow the character, clamped at map edges (recommendation, not yet confirmed).
- **A minimap** under the movement arrows: explored / unexplored / **nothing there**. The third state is what makes a bigger map navigable.
- **World size becomes a variable** — proposed as the existing Scale qualifier on the primary Relief source. **Bigger worlds must cost more stability**, so size is a greed-shaped decision.
- **Night changes vision and spawns.** This is what finally makes Illumination's dynamic range mean anything.

## `cycle-sources-draft.md`

Eleven candidates for Aimee to cut down. Not decided — don't build from it yet.
