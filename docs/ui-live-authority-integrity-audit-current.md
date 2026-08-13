# UI live-authority integrity audit

Date: 12 August 2026
Scope: every release and DEBUG SwiftUI surface under `Sources/Screens`, `Sources/App`, and
`Sources/Debug`, plus the rule/model/persistence paths that supply displayed progress, counts,
prices, previews, availability, status, probability, health, damage, and provenance.

## Standard used

A display is **authoritative** only when the visible claim is computed from the same current or
frozen receipt that commit/gameplay consumes. A test that merely finds text, observes a phase, or
checks monotonicity does not establish truth.

Classifications:

- **False authority**: the UI states or strongly implies a measured/current fact that is not that.
- **Stale authority**: the UI captured a formerly valid value and can act without atomic recheck or
  truthful refusal.
- **Over-precise estimate**: a model/sample/heuristic is shown as an exact measurement.
- **Decorative inference**: a visual metaphor is derived heuristically but does not state a numeric
  fact. It should still be disclosed and consistently derived.
- **Provisional content risk**: the UI faithfully shows its catalogue, but the catalogue itself says
  the value/copy is placeholder. This is not the same as a runtime authority mismatch.

## Executive result

Confirmed defects:

- 2 P0 fabricated determinate progress authorities for the same launch work.
- 10 P1 release or diagnostic false/stale-authority defects.
- 4 P2 over-precision, duplicated-constant, or decorative-inference risks.
- 1 systemic provisional-content provenance risk spanning at least 17 bundled catalogues.

The audit also identified important surfaces that pass: Trading Post, Recycler, Apothecary
readiness, Essence refining, most Blacksmith construction/rebuild previews, world Look consequence
copy, DEBUG direct-hit preview, and bug-report transport state all revalidate or consume the same
authority they display.

## P0 — fabricated determinate progress

### A1. Initial and selected-campaign loading percentages are invented

`CampaignAppCoordinator.LoadingPhase.completedFraction` assigns fixed values `0`, `0.15`, `0.25`,
`0.5`, `0.65`, `0.75`, and `1` to named phases. They are not files inspected, bytes read, units
completed, or time-weighted measurements. The determinate orange fill renders those constants.

Evidence:

- `Sources/App/CampaignAppCoordinator.swift:9-25`
- `Sources/App/BookbinderApp.swift:257-261,307-321`
- introduced by `71974de` under the inaccurate title “Show real campaign launch progress”

The initial campaign shelf is measurable: enumerate slot URLs, then publish
`descriptors decoded / total descriptors`. Before enumeration, use an indeterminate indicator.

### A2. Save preparation has a second incompatible invented scale

`GameStore.PreparationStep.completedFraction` maps four labels to `0`, `1/3`, `2/3`, and `1` merely
because four events exist. A healthy save can skip the commit, and real measured phase timings
already exist separately. `CampaignAppCoordinator` then remaps those same phases to a different
`0.25/0.5/0.75/1` scale.

Evidence:

- `Sources/Persistence/GameStore.swift:31-49,145-177`
- `Sources/App/CampaignAppCoordinator.swift:21-24`
- `Tests/PersistenceTests.swift:227-232` explicitly freezes the invented thirds

Use indeterminate named phases until a phase exposes real completed/total units. Do not convert
event count into percentage.

### A3. Tests supplied false assurance

`testInitialInspectionPublishesHonestProgressBeforeChooser` checks only that two phase enum cases and
the phrase “Reading campaign shelf” appeared. Other tests check phase order, final `1`, fixed track
geometry, and monotonicity. None proves the fraction derives from work.

Evidence: `Tests/CampaignLaunchProgressTests.swift:14-82,133-165`.

New gate: every determinate fraction must carry explicit `completedUnitCount` and `totalUnitCount`
from the operation; tests must vary workload and prove proportional output.

## P1 — release false or stale authority

### A4. Combat skill sheet labels power as cooldown

When a skill is cooling, the right-hand number is remaining cooldown. When ready, it becomes raw
catalogue `skill.power`, while the footer says every right-hand number is rounds until reuse.
Committed potency and cooldown are separately actor-derived, so the ready number is neither the
promised cooldown nor necessarily the actual potency.

Evidence:

- `Sources/Screens/EncounterView.swift:658-679`
- `Sources/Rules/CombatRules.swift:548-550,750-752`

### A5. Bestiary calls automatically recorded encounters “kept specimens”

Every foe is recorded as a specimen on encounter creation/contact. There is no keep/capture action,
yet the UI says “N kept,” “Kept specimens,” “No kept specimen,” and “The best you've found.”

Evidence:

- `Sources/Rules/WorldRules.swift:1265-1271`
- `Sources/Screens/BestiaryView.swift:78-81,139-159`
- `Tests/BestiaryTests.swift:105-117` reinforces the mismatch by equating meeting with recording

Rename these to sightings/encounter records, or add a real keep receipt and action.

### A6. “The best you've found” secretly means highest appetite

`BestiaryRules.finest` selects maximum `traits.appetite`, but the sheet presents size, covering,
armament, ornament, and build. Appetite is not shown. A record worse on every displayed measure can
be crowned best due to the invisible field.

Evidence: `Sources/Rules/BestiaryRules.swift:128-130`; `Sources/Screens/BestiaryView.swift:139-144`.

### A7. Library “At Home” means recruited, not physically at Home

Library tiles use `foundTravellers.contains` to render “At Home.” Actual placement may be active
party or anchored realm and is tracked elsewhere.

Evidence:

- `Sources/Screens/LibraryView.swift:242-247,372-379`
- `Sources/Rules/LibraryRules.swift:237-243`
- actual placement consumer: `Sources/Screens/FirepitView.swift:20-32`

### A8. Party cards label maximum health as current HP

Party cards print `HP N` and accessibility “Health N,” but `N` is
`CharacterRules.maximumHealth`. Elsewhere HP consistently means current/max.

Evidence: `Sources/Screens/PartyRosterView.swift:83,103,122-131`.

### A9. Loot swap promise can delete the offered item after a stale/failed swap

The detail sheet captures offered/carried stacks while background interaction remains enabled.
Commit ignores carried removal success, ignores offered add/capacity success, and always deletes the
offered item. The UI promises “Drop this and take …” and dismisses.

Evidence:

- `Sources/Screens/LootDecisionView.swift:39,66,75-77,140`
- `Sources/Screens/ItemGrid.swift:127,137`
- `Sources/Rules/GameActions+World.swift:164-170`

This requires a rules-owned revisioned quote and atomic result; on stale state, retain both objects
and show the fresh refusal.

### A10. Storehouse/spillover details and confirmations can become stale and fail silently

Sheets display captured quantities/locations while allowing background interaction. “Store it” and
swap confirmations dismiss without surfacing no-op/stale outcomes. The mutations have no shared
revision/result authority comparable to Trading Post and Recycler.

Evidence: `Sources/Screens/StationViews.swift:319-451,542-622`;
`Sources/Rules/GameActions+Economy.swift:384-397`.

### A11. Party transfer displays exact before/after production, then conceals stale refusal

Firepit renders exact projected production/shortfall changes from a captured placement and discards
the Boolean result of `setComing`. That rules action deliberately rejects stale placement/capacity.
The user can confirm, receive no mutation, and see no reason.

Evidence: `Sources/Screens/FirepitView.swift:77-79,169-178`;
`Sources/Rules/GameActions+Economy.swift:740-772`.

### A12. DEBUG roadmap claims manually authored status is “Live” and “Installed”

The roadmap reads bundled JSON prose and presents it as “Live DEBUG view” and “Installed
checkpoint.” It does not observe the installed binary, Git commit, device state, or test result.
Bug reports then copy the same claim into “Roadmap checkpoint,” contaminating otherwise useful
evidence.

Evidence:

- `Sources/Debug/DebugRoadmapView.swift:52-80,165-182`
- `Sources/Content/Data/playability-roadmap.json:3-7`
- `Sources/Debug/DebugBugReporterView.swift:198-200,260-281`
- circular test: `Tests/DebugBugReporterTests.swift:62-70`

Rename to “Bundled roadmap claim” until build provenance is generated and signed.

### A13. Artificial splash hold presents completed inspection as ongoing 65% work

The one-second anti-flicker hold occurs after inspection, but the visible phase remains
`.inspectingCampaigns` at fabricated 65%. Keeping branded art perceptible is legitimate; describing
finished work as ongoing is not.

Evidence: `Sources/App/CampaignAppCoordinator.swift:67-106`;
`Tests/CampaignLaunchProgressTests.swift:133-149`.

Show a completed/ready state during any deliberate minimum display, or remove the hold once the OS
and SwiftUI handoff is stable.

## P1/P2 — simulated authority and excessive precision

### A14. Bestiary “% in nature” is a fixed synthetic reference and can exceed 100%

The value is derived from deterministic generated samples, not observed nature. The UI labels it
simply “in nature.” The percentile calculation can produce `count/(count-1)` for a value above every
reference, yielding more than 100%.

Evidence: `Sources/Rules/BestiaryRules.swift:55-98`;
`Sources/Screens/BestiaryView.swift:225-264`; weak range/order-only gates in
`Tests/BestiaryTests.swift:40-72`.

Label the sample model and build/profile, clamp to `0...1`, and test boundary values.

### A15. Living Analysis prints exact percentages from 96 deterministic samples

Tier-5 analysis renders `N% likely` and quartiles as “usually” from a fixed 96-seed simulation. The
history section at least says “Likely distributions,” but integer precision still implies more
calibration than exists.

Evidence: `Sources/Rules/LivingAnalysisRules.swift:13-65`;
`Sources/Screens/WorldHistoryView.swift:488-496`;
`Tests/InstrumentTests.swift:236-246`.

Label sample size/model and use bands or approximate notation unless calibration is validated.

### A16. Writing runway is a heuristic displayed to one decimal bind

The value divides post-construction Essence by the median of up to five previous authored bind
costs. It is useful advice, not a measured number of future binds, because the next page may cost
differently.

Evidence: `Sources/Screens/BaseView.swift:395-408`;
`Sources/Rules/StationRunwayRules.swift:3,33-54`.

Use “Estimated runway at recent median · ≈N binds.”

### A17. Reforge maximum is duplicated as literal `3`

Several release views print `of 3` instead of using `SmithRules.maximumLevel` /
`Tuning.Smith.maximumReforgeRank`. It is true today but becomes false on the next tuning change.

Evidence: `Sources/Screens/TradingPostView.swift:244`, `GearView.swift:195`,
`StationViews.swift:622`; authority `Sources/Rules/SmithRules.swift:47-52`.

### A18. Campaign shelf fullness is an opaque inferred score

The visible book motif is not a literal collection count. It weights level, travellers, writings,
research, stations, and runs, divides by six, and clamps to 2...12. Old metadata missing the score is
inferred from Binder level only. This is currently decorative rather than an explicit numeric lie,
but it should be described as a decorative campaign-progress motif and derived consistently.

Evidence: `Sources/Persistence/SaveSlotCatalogue.swift:20-22,40-55`;
`Sources/Screens/CampaignStartView.swift:70-74,309,364`.

## Systemic adjacent risk — provisional catalogues presented as settled

At least 17 bundled release catalogues describe some or all of their player-facing values/copy as
placeholder or provisional in internal `_note` fields, while ordinary UI presents those values as
the game's settled content. This does **not** prove every value is mechanically false; it proves the
project lacks a promotion boundary between provisional authority and release authority.

Affected catalogues include combat trees, Constellation, contradictions, legacy creatures,
descriptions, gambit components/pieces, items, pressure sources/targets, research, resources, rune
shapes, sites, skills, stations, symbols, travellers, and upgrades. Representative evidence:

- `Sources/Content/Data/items.json:2,150,159` (two live blurbs literally say “placeholder”)
- `Sources/Content/Data/skills.json:2`
- `Sources/Content/Data/research.json:2`
- `Sources/Content/Data/stations.json:2`
- `Sources/Content/Data/upgrades.json:2`
- `Sources/Content/Data/pressure_sources.json:2`
- `Sources/Content/Data/pressure_targets.json:2`
- `Sources/Content/Data/travellers.json:2`

Required content gate: every bundled catalogue needs per-field disposition (`settled`,
`playtestTuning`, `provisionalCopy`, `legacyDecodeOnly`) rather than a broad historical note. Release
must reject undisclosed placeholder copy and distinguish tunable playtest numbers from invented
stopgaps.

## Surfaces that passed this audit

- Trading Post listing and purchase use frozen identities/revisions and reject stale commits.
- Recycler preview/commit uses exact inventory identity and revision.
- Apothecary readiness and shortfalls recompute from current state.
- Essence Spring conversion uses the current rules-owned rate and revalidates the transaction.
- Blacksmith construction/rebuild paths generally use typed previews and surface stale failure.
- World Look consequence text is rules-owned, disclosure-bounded, and no-mutation tested.
- DEBUG direct-hit preview uses the same `CombatDamageRules` arithmetic as commit.
- Bug reporter Save/Done/Submit language and transport state are materially accurate; submission is
  not claimed until a server receipt exists.

## Remediation order

1. Replace both launch percentage maps and their misleading tests. Guarantee first-frame rendering,
   use real shelf completed/total progress, and use indeterminate save phases until measurable.
2. Correct the combat skill number, Bestiary vocabulary/selection/percentile bounds, Library
   placement label, and Party max-HP label.
3. Add revisioned, atomic rules-owned quotes/results for loot swap, spillover/storehouse, and party
   transfer; never dismiss on refusal.
4. Rename manually authored roadmap evidence and stop copying it as installed provenance.
5. Qualify model outputs (nature baseline, living analysis, writing runway) and remove duplicated UI
   literals.
6. Establish catalogue promotion metadata and a release validation gate for provisional content.

## Permanent acceptance rules

- A determinate progress bar requires real completed/total units.
- An exact preview requires preview and commit to share one typed quote/receipt plus stale rejection.
- “Current,” “installed,” “live,” “at home,” “kept,” “HP,” and similar state words require the exact
  persisted/runtime authority named by the word.
- A probability must state whether it is observed, analytic, or simulated; simulated output names
  its profile/sample and stays within valid bounds.
- A test name may not claim honesty, parity, or exactness unless it asserts the authority relation,
  not only output shape/order/text.
- Release content cannot inherit a broad placeholder note without a field-level disposition.
