# Debug balancing surface — current scope and growth plan

**Status:** Current design. The existing first batch is live; the next two batches below are
implementation-ready in priority order. Exact ranges and step sizes remain tool tuning.  
**Updated:** 9 Aug 2026

## Purpose

This is Aimee's on-device playtest instrument, not a player progression system. It should make a
question fast to test—“are pages too sparse?”, “does collapse feel fair?”, “how often do I meet a
traveller?”—without turning Settings into a mirror of every constant in the code.

The current implementation correctly provides a DEBUG-only Balancing screen, persistent profile,
non-default warning, Reset All and next-bound-world scope. It currently controls raw-essence
frequency/yield, resource-node density, second-writing chance and creature density.

## Rules for every control

1. Group by the experience being tested, not by source-code subsystem.
2. Show the default beside the current value and give each group a **Reset Section** action.
3. Mark scope explicitly: **next world**, **next encounter**, **new campaign only** or **immediate**.
4. Snapshot world-generation and encounter-generation values into the created object. Existing
   worlds/fights never mutate under the player.
5. A non-default profile is always visible from Settings and on the debug screen; exported playtest
   summaries list every override.
6. Persist the profile outside game saves. Loading a save on another build uses defaults unless a
   profile is deliberately imported.
7. Prefer one causal control over several correlated ones. Do not expose semantic invariants,
   stable IDs, authored relationships or save migration behavior as sliders.
8. An override that forces content is an **experiment**, not balance. Keep it in a separate Test
   Setup section so its results are never confused with natural distribution.

## Existing first batch — keep

| Group | Control | Scope | Note |
|---|---|---|---|
| Resources | Raw essence frequency | Next world | Spawn frequency, separate from quantity |
| Resources | Raw essence yield | Next world | Quantity per eligible drop |
| Resources | World-resource node density | Next world | Rename UI from generic “Resource-node” when convenient |
| Writing | Second writing chance | Next world | The guaranteed first writing cannot be disabled |
| Creatures | Creature density | Next world | Ordinary non-apex population only |

The existing 0.25×–3× range is suitable for density/yield diagnosis. A value of zero should be
available only where “none” is a valid world, and must not bypass the one-writing guarantee.

For Raw Essence, the old 2–4 drops × 1–2 units default is a diagnostic legacy profile, not a viable
balance center. The temporary current profile is 5–7 × 2–3 as specified in
`essence-continuation-economy-current.md`. Add named Lean/Recommended/Generous presets alongside the
independent multipliers so Aimee can compare complete, reproducible economy conditions.

## Batch two — expedition feel

These have the highest value because they answer current playtest questions across a single evening.

| Group | Control | Recommended presentation | Scope |
|---|---|---|---|
| Writing | Diary / other-writing mix | 0–100% diary, default 70%; remainder other | Next world |
| Writing | Diary patience floor | Integer worlds, default 8; one nominated page only | Next resolved world |
| World duration | Stability duration multiplier | 0.5×–2×, default 1× | Next world |
| World duration | Collapse recovery fraction | 0–100%, default 50% | Next world |
| Encounters | Apex chance multiplier | 0×–3×, default 1× | Next world |
| Encounters | Opening encounter envelope | Natural / Gentle / Clear approach; default Natural | Next world on fresh-save testing only |
| Navigation | Base vision radius | Integer 1–6, show default | Next world |
| Navigation | Slow-ground extra turns | Integer 0–3, show default | Next world |
| Flora | Active-flora frequency | 0×–3×, default 1× | Next world |
| Flora | Thorn/toxin severity | 0.5×–2×, default 1× | Next world |

“Opening encounter envelope” is an explicit diagnostic switch, never a hidden first-world rule.
The reversible first implementation is spatial rather than a hidden combat modifier:

- **Natural** performs no filtering or relocation.
- **Gentle** allows at most one ordinary mobile enemy in the entry's initially revealed area.
- **Clear approach** allows no ordinary mobile enemy in that area.

Excess ordinary enemies are deterministically relocated to valid unrevealed free tiles, not deleted,
so species, total population and possible rewards remain unchanged. Guardians, apexes and active
flora are never rewritten by this tool; their normal placement-clearance rules still apply. The
control is honored only when generating the first expedition of a fresh campaign. Otherwise the
report says **ignored — not a fresh first expedition** rather than silently changing an established
campaign. “Off” is not a picker value because it was ambiguous between “no envelope” and “no nearby
encounter”; the three labels above name the actual outcomes.

## Batch three — long-campaign pacing

| Group | Control | Scope |
|---|---|---|
| Knowledge | Rune pity escalation values and guaranteed-world floor | Next resolved world |
| Travellers | Signature-match appearance multiplier | Next world |
| Travellers | Random-companion additive chance | Next world |
| Animals | Patient trust turns and property-offering threshold | Next interaction/world as applicable |
| Anchoring | Anchor-site appearance multiplier | Next world |
| Anchoring | Renewable production rate and delivery capacity | Future production ticks; never erase stored progress |
| Economy | Station build-cost multiplier | Future purchases only |
| Economy | Trading Post buy/sell spread | Future transactions only |
| Cycle | Period-band values and maximum regularity jitter | Next world |

Keep authored station recipes and traveller conditions visible as read-only inspection rather than
individual sliders. If one needs experimentation, provide a clearly named temporary multiplier.

## Test Setup — separate from balancing

The smallest useful deterministic tools are:

- enter or copy a world seed;
- force a named traveller eligible, a writing type, an apex roll or an anchored-site roll;
- select day/night entry and, once Cycle drives the clock, jump to the next transition;
- grant only the resources/items needed for a station or encounter fixture;
- copy a compact run report containing seed, bound composition, resolved readings, tuning profile,
  generated counts, exit type and acquired/recovered/lost haul.

Forced runs wear a persistent **TEST SETUP ACTIVE** banner and are excluded from natural-frequency
summaries.

## Inspection before more sliders

For each generated world, show a compact read-only diagnostics page:

- writing guaranteed/selected/placed and second-roll result;
- raw essence eligible nodes, placed drops and obtainable total;
- raw essence collected, refined-value equivalent, bind cost paid, Spring yield, anti-lock subsidy
  use and net authored-book runway;
- ordinary world-resource nodes by type;
- creature/flora species and instance counts, apex roll and result;
- stability score, turn budget, projected collapse and actual exit turn;
- traveller candidates, signature matches and appearance result;
- world seed and profile snapshot.

This is more useful than exposing hundreds of constants: it distinguishes a bad rate from a broken
consumer or unreachable placement rule.

## Verification

1. Reset All and Reset Section reproduce code defaults exactly.
2. Existing worlds and encounters do not change when a slider moves.
3. Same seed, page and profile reproduce the same diagnostic report.
4. Custom and forced-state banners survive navigation and app relaunch.
5. Guaranteed writing remains guaranteed at every allowed setting.
6. Exported reports contain no private device data and are compact enough to paste into a task.
7. Release builds contain no balancing or Test Setup entry point.
