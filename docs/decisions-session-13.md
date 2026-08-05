# Decisions Log — Session 13 (2026-08-05)

Append to `docs/decisions-log.md`. Aimee's decisions. Follows `audit-what-pressures-actually-do.md`.

---

## 1. Cycle gets real sources

Per-target exclusivity exposed that **Cycle had no primary source of its own** — its period came from celestials, its amplitude was derived, its regularity came from qualifiers on other targets' sources. Under one-primary-per-target, its primary would have been the sun, which is already Illumination's.

**Fix: Cycle gets its own primaries** — things that dictate how a world keeps time rather than inheriting it. Candidate list in `cycle-sources-draft.md` (Tide, Orrery, Pulse, Procession, Stillness, Drift, Stutter, Unwinding, Breath, Cascade, Echo) for Aimee to cut down.

The sun stays Illumination's primary; celestial Length and Phase qualifiers still modify *how* it moves within whatever rhythm the world has.

## 2. Bigger maps AND shorter days — a half measure of each

The audit found roughly a fifth of the pressure model describes **change over time in a game where nothing changes during a run** — a ~200-turn run on a 14×14 grid has no room for a day to turn.

**Decision: combine options A and C at half strength.** A moderately bigger world, and a day compressed to fit inside a run.

**[PLACEHOLDER starting numbers, to be tuned on device]**
- Map **18×18** rather than 14×14 — 2.6× the area, roughly 1.7× the turns to explore
- A day of **~40 turns**, so a full exploration sees four or five day/night turns

Enough that planning around nightfall matters; not so many that it strobes.

**Stability must buy proportionally more turns** so runs aren't cut short simply by the map growing.

## 3. The map no longer has to fit one screen

**Only the page has that constraint** — you compose on a page, so you must see all of it. You *walk through* a world, so it can extend past the screen.

**Camera: follow the character, clamped at the map edges** — the view stops at the border rather than showing empty space past it. Avoids both wasted screen and the disorientation of fully-centred scrolling at edges. **[Aimee was undecided; this is the recommendation, not a decision.]**

## 4. A minimap

**Under the movement arrows.** Shows:
- What you've explored
- What you haven't
- Where there's nothing

That third state matters — knowing an area is empty is as useful as knowing it's unexplored, and it's what makes a bigger map navigable rather than tedious.

## 5. World size becomes a variable

Size is no longer a constant. **[PROPOSAL]** rather than a new mechanism, use the **Scale qualifier** (Minute · Small · Large · Vast) that already exists in the vocabulary, applied to the world's primary **Relief** source.

**Size must interact with stability:** a bigger world needs more turns to explore, so it should **cost more stability**. That makes size a greed-shaped decision — a vast world holds more, but you need it to last longer, and writing one you can't finish exploring is a real and instructive mistake.

## 6. What changes at night

**Vision and spawns.** Darkness cuts sight radius; the nocturnal roster swaps in.

This is what finally makes **Illumination's dynamic range** mean something: a world with blazing days and black nights genuinely plays as two worlds, and a world lit by something constant never has a night at all.

Anything beyond vision and spawns (hazards, harvest rates) is optional and not decided.

---

## Consequences

- **Cycle's period becomes genuinely writable.** A short-period world flickers between day and night several times a run; a long-period one might be dark for an entire expedition. Only meaningful now that days fit inside runs.
- `Tuning.World.gridWidth/Height` stop being constants.
- Stability→turns curve needs rescaling against the new map size.
- The pressure model's temporal variables (Illumination dynamic range, Thermal swing) now have room to matter — but still need **wiring into generation**, which is the larger outstanding problem from the audit.

## Still open

1. Camera behaviour — confirm the clamped-follow recommendation.
2. Whether Scale-on-Relief is the right home for world size.
3. Exact map size, day length, and the stability rescale — all need device testing.
4. Which Cycle sources ship.
