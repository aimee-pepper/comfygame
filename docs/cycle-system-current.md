# Cycle — live vocabulary and world-clock first slice

**Status:** Current implementation-facing first slice; period bands and regularity jitter are
debug-tunable. No new focus names are requested.  
**Updated:** 9 Aug 2026

## Audit result

Cycle is no longer missing a vocabulary. The live direct focuses are:

| Focus | Direction | Distinction | Acquisition |
|---|---|---|---|
| Tide | faster, high amplitude, regular | Natural recurring pull | Research |
| Orrery | faster, low amplitude, highly regular | Authored clockwork order | Research after Tide |
| Drift | slower, uneven, moderate swing | Unequal spans | Tovin diary |
| Stillness | stopped, low amplitude | No transition | World discovery |
| Echo | slightly faster, recurring, context-shifted | Place answering a prior rhythm | Lys diary |
| Dream | near-ordinary pace, uneven, high swing | Associative rather than chronological recurrence | Nine diary |

Moon contributes a regular cyclic secondary while attaching to Illumination; Amber contributes slow
change secondarily while attaching to Vitality/Substrate. This is healthy implicit-secondary
grammar, not evidence Cycle needs more primaries.

The old `cycle-sources-draft.md` candidate list is superseded. Do not add Time, Pulse, Procession,
Stutter, Unwinding, Breath or Cascade merely to reach an old numeric target:

- broad **Time** duplicates the Cycle subject sigil;
- Pulse/Procession/Breath/Cascade are expressible through the existing pace, amplitude and
  regularity axes;
- Stutter implies repeated simulation events and Unwinding implies historical decay that the game
  does not possess;
- extra synonyms dilute six already distinct late discoveries.

## What remains missing

Every run currently reads `Tuning.DayNight.turnsPerDay == 40`. Cycle magnitude and regularity do not
reach the world clock, so Stillness can produce “A day that never turns” while day/night transitions
continue. That is a broken promise, not a need for more prose.

## First-slice world clock

Cycle remains driven only by **player turns**, never wall-clock time.

### Base period from Cycle magnitude

| Resolved Cycle peak | Clock state | Base turns per full cycle |
|---:|---|---:|
| 0–8 | **Stopped** | No phase advancement |
| 9–29 | Slow | 64 |
| 30–69 | Measured | 40 |
| 70–84 | Quick | 28 |
| 85–100 | Restless | 20 |

These bands deliberately align Stopped with the live `day_that_never_turns` contradiction threshold.
They are playtest values exposed in debug tuning. The named band may appear in earned Cycle analysis;
ordinary world description remains qualitative.

### Regularity changes reliability, not direction

For a non-stopped world, derive each completed cycle's actual length deterministically from world
seed, cycle index and resolved regularity:

```text
maximum jitter fraction = 0.40 × (1 − regularity / 100)
actual cycle length = base period × deterministic value in [1 − jitter, 1 + jitter]
```

Round to whole turns and clamp to at least 12. The schedule must be monotonic: low regularity changes
how long the next span lasts but never reverses time, repeats a turn, steals an action or moves the
player. Save/load and anchored revisits reproduce the same schedule.

The existing night fraction remains the same portion of the actual cycle for this first slice. Event
notifications fire when the derived phase crosses nightfall/daybreak, exactly as they do now.

### Stopped worlds

A stopped world holds the entry phase for the expedition and has no daybreak/nightfall roster swap.
Entry phase should be deterministic from the resolved illumination character:

- cyclic celestial light: hold at day;
- sourceless/constant light: ordinary no-night behavior already applies;
- no usable light: hold dark.

The player never waits for a stopped clock to resume. A sun written into Stillness remains visibly
present and produces the existing contradiction; “stopped” means it does not traverse the sky, not
that the light source is deleted.

## Amplitude boundary

Amplitude is already real in flora generation: high swing favours storage tissue. It is intended
eventually to scale how far light, temperature and ecological activity move between phases, but the
current simulation does not store per-phase readings for every subject. Do not fake that breadth by
turning amplitude into a second day-length control.

For the first slice:

- preserve its current ecology contribution and analysis/description;
- record it with the world clock for future dynamic consumers;
- add no global damage, stability tax or random event rate merely to make the number louder.

The later dynamic-state pass must modulate resolved ranges without changing the page's mean world or
rerolling species identity.

## Count, Scale and qualifiers

Generic qualifiers retain their normal grammar on Cycle focuses:

- Intensity changes the focus's contribution;
- Count sublinearly strengthens multiple pulls/clocks/recurrences;
- Scale changes strength where Cycle has no separate spatial extent.

No Cycle-specific Constancy or Length ladder is needed for the first slice. Regularity and period are
already written through distinct focuses, and adding a second set of controls now would overcomplicate
the page before the first set affects play.

## Preview, History and debug

- Pre-bind projection shows a qualitative clock band only when Cycle is deliberately written and the
  existing knowledge gate permits it; an unwritten rolled Cycle remains a range/surprise.
- World History records resolved base period, regularity and stopped state after visiting.
- Debug exposes peak-band boundaries, base periods, maximum jitter coefficient, forced stopped state
  and the next two scheduled day/night transitions.
- Existing saves without clock state derive it from bound composition and seed. Mid-run saves keep
  their current phase; migration must not jump immediately from day to night.

## Verification

1. Peaks 8 and 9 fall on opposite sides of the stopped boundary and match contradiction semantics.
2. Same book/seed produces the same full transition schedule across save/load.
3. Low regularity changes at least some cycle lengths while remaining within the bound and monotonic.
4. Stopped worlds never emit daybreak/nightfall or swap rosters.
5. Ordinary Cycle reproduces the current 40-turn behavior closely enough for old saves.
6. No wall-clock pause changes phase.
7. Tide, Orrery, Drift, Stillness, Echo and Dream remain reachable through their current distinct
   acquisition routes; no draft focus enters random distribution.

