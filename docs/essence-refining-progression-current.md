# Essence refining progression — current design

**Status:** settled implementation direction under Decision 186; costs, practice gate and rate are
reversible playtest values  
**Priority:** progression follow-up after baseline Essence continuation is measured; baseline may not
depend on these unlocks  
**Updated:** 10 Aug 2026

`essence-refining-progression-audit-current.md` identified a hoarding/basic-UX problem with the paid
Measured batches node. Decision 186 accepts its correction: quantity control is free baseline
functionality, while lifetime practice gates the 3:1 Second pass.

## Decision

Raw Essence should not remain a flat opening conversion for an entire long campaign. The Essence
Spring receives a small keeper-free research branch that improves **control, yield and convenience**
without turning the base rate into a trap or moving refining to Auber's Distillery.

The settled baseline remains:

- ordinary reasonably explored worlds normally fund another ordinary authored world at the opening
  `2 refined Essence per 1 Raw Essence` rate;
- the current 5–7 drops × 2–3 raw profile is measured on its own before unlocks are added;
- research makes investment rewarding and creates optional surplus; it does not repair an economy
  that only works after research.

## Station ownership correction — settled 11 August 2026

The current native build places **Refinery** inside the Workshop, tells the Storehouse player to
refine there, and comments that the Workshop is where raw becomes refined. That conflicts with this
design, with the requested unlockable Essence-refining progression, and even with the Workshop
screen's own rule that the Workshop is for improving writing. Meanwhile the Essence Spring owns
return yield, respec and a stale “tier 2 at the Workshop” placeholder, but not the central Essence
operation.

The **Essence Spring is the single player-facing Essence hub**.

- Move the existing raw → refined interaction unchanged from Workshop to Essence Spring.
- Keep return yield and Unlearning there; those are distinct uses of the same restorative place.
- Give the refining nodes and `deepen_spring` one Spring-owned research branch, displayed at the
  Spring rather than in the Workshop's general writing tree.
- Workshop retains writing/research infrastructure and stops being an unexplained refinery.
- Update every direction string together; Storehouse must never send the player to the old station.

This is a presentation/ownership migration, not an opening-economy change. Existing raw, refined
Essence, completed node IDs, Spring tier and transaction behavior remain intact. Decision 186
authorizes implementation; later play reviews the reversible costs/rate, not whether Workshop and
Spring remain competing authorities.

`deepen_spring` currently belongs to the generic `hold` branch and requires `shelving_one`. That
dependency reads as an implementation remnant rather than a meaningful design relationship. Preserve
the completed ID for old saves, but make it an independent Spring-root choice when the branch moves;
do not require Storehouse shelving to improve the Spring.

## Spring research branch

The Spring has no exclusive keeper. Its root is available from the beginning through ordinary Base
research, but costs ensure the player first experiences basic refining.

### Baseline measured batches — control, not a research node

Provide a quantity selector alongside **Refine all** from Spring tier 0. The preview states raw
consumed, refined gained and the active rate before commit. This exposes the existing amount-based
refining action rather than inventing a second currency, recipe or paid permission.

- cost: **free baseline capability**;
- exact amount revalidates atomically; cancel/stale input costs nothing;
- accessibility includes stepper/direct amount semantics and a clear maximum action.

### 1. Second pass — practiced efficiency

Requires **50 lifetime Raw Essence refined** through committed conversions. Permanently changes
ordinary refinement from **2 → 3 refined Essence per Raw Essence**. It does not change Raw Essence
placement, Spring return income, anti-lock calculation semantics or Auber's crystal work.

- provisional cost: **80 Essence + 10 Quartz**;
- effective rate is shown everywhere raw/refined equivalent is previewed;
- already-held raw benefits; historical transactions are never recomputed;
- DEBUG can compare 2/3-per-raw, but no fractional hidden remainder is introduced.

The jump is intentionally legible rather than a concealed percentage. Its price and campaign timing
must be tuned against B0 telemetry so the payback feels like long-campaign progression rather than a
mandatory tax.

At the provisional 80-Essence price, the extra one Essence per Raw repays the Essence portion after
80 future Raw. Under the current Recommended 5–7 drops × 2–3 Raw profile, that is roughly five to six
well-explored ordinary worlds before accounting for the ten Quartz. That is a reasonable first
long-campaign comparison, but the UI should show **“+1 Essence per Raw”** and an example batch, not a
payback promise; actual collection varies and Quartz has other uses.

### 2. Continuous settling — convenience

Requires Second pass and Spring tier 1. Adds an **Auto-refine returned Raw Essence** toggle at the
Spring. When enabled, newly banked raw from a committed expedition outcome refines once at the active
rate after haul retention is final.

- existing stored raw is untouched until the player acts;
- collapse/failure refines only the raw units actually retained;
- the toggle and one-per-outcome receipt persist across relaunch;
- recap shows raw retained → refined gained as a distinct line;
- provisional cost: **120 Essence + 12 Quartz + 8 Pulp**.

This removes repeated housekeeping late in a campaign without giving extra yield. It depends on the
shared `ExpeditionOutcomeID`; do not implement a second return counter locally.

### Existing Deepen the Spring — return income

Keep `deepen_spring` as a sibling progression choice that raises the small return dividend. It is not
a refining-rate node and its UI must not imply that it changes raw conversion. Review its current
cost/yield beside the new branch after B0 data; do not silently bundle it into Second pass.

## Boundaries

- Auber's Distillery still crystallises/attunes refined Essence and never owns the raw conversion
  rate.
- Trading Post stock may sell a limited refined-Essence bundle, but cannot buy/sell Raw Essence or
  become the best refining route.
- No offline/wall-clock accumulation.
- No chance to lose raw during refining and no quality grades on Essence.
- No node merely says “+5%.” Each adds a readable operation, integer rate or automation choice.
- Anti-lock assistance uses the true spendable amount at the active unlocked rate and remains an
  exact last-resort shortfall, never an income strategy.

## Acceptance and playtest

1. Old saves default to the basic rate with no false completed nodes; already-completed
   `deepen_spring` remains complete.
2. Preview, bind runway and return diagnostics all use the same active rate.
3. Refining a selected amount, cancelling, stale inventory and force-quit cannot duplicate or lose
   raw/refined Essence.
4. Second pass changes only future conversions and survives save/load.
5. Continuous settling processes one committed outcome once, after retention, and clearly reports
   the conversion.
6. Compare unlock timing and payback after at least ten B0 returns; if 3:1 erases precision cost,
   raise its investment/timing rather than weakening the opening 2:1 economy.
7. One station owns every player-facing raw-refinement action and direction string; Workshop and
   Spring never both claim to be the refinery.
8. Moving `deepen_spring` preserves old completion and Spring tier exactly, while a fresh save no
   longer needs unrelated shelving before it can deepen the Spring.
