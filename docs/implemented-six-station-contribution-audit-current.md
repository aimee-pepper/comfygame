# Implemented Six — Station Contribution Audit

**Status:** source-complete; ordinary-phone acceptance remains
**Date:** 18 August 2026

## Result

The original six traveller identities do not require six new feature expansions. All six now have a
real, immediately usable gameplay contribution in the native build. Sela's previously missing flora
recognition landed in `12c5759`: the built Wayfarer's Table adds exact visible-flora identity,
defence family and rules-owned yield notes without leaking hidden flora or changing Look consequences.

| Traveller | Promised contribution | Current evidence | Disposition |
|---|---|---|---|
| Mara | Survey Post; instruments, field reading and loadout | Eight subject instruments, selected frozen field kit, one-turn survey, calibration and Scriptorium lens dependency | **Fulfilled first slice.** Do not add a generic minimap bonus merely to create another perk |
| Edren | Reliquary; site record, interpretation and richer outcomes | Reliquary catalogue of discovered sites plus rules-owned bonus to each authored site resource yield | **Fulfilled first slice.** Deeper recovery/history may grow with site provenance, not a parallel loot table |
| Halloway | Blacksmith; foundational gear and reforge path | Eight physical families, rules-owned construction, item identity and maker-screen checkpoint | **Fulfilled/active presentation testing.** Recycler salvage remains Noll's verb, not a reason to duplicate it here |
| Isolde | Scriptorium; hands, compounds and lens | Scriptorium, Brush, hands, lens and persistent Ink Mixing are live; later Compound/Chaining/Fountain breadth remains separately gated | **Fulfilled first slice.** Do not freeze obsolete Pencil/150-Essence values |
| Sela | Wayfarer's Table; packing, organic yield and flora recognition | +2 satchel, +1 organic harvest and station-owned visible-flora identity/defence/yield notes are live; hidden flora and pre-Table Look remain disclosure-neutral | **Fulfilled first slice at `12c5759`.** Ordinary-phone field acceptance remains |
| Tovin | Anchorage; anchor lifecycle, sustain and realm assignments | Portfolio/settlement/person-placement checkpoints are implemented and ready to test | **Fulfilled first slice.** Device play, not a second tether model, is next |

## Boundaries

- A contribution is fulfilled when it creates one honest player decision or capability immediately;
  it need not reproduce every old aspirational noun as a separate subsystem.
- Later depth belongs in the station's existing branch and receipts. Do not add screen-local bonuses
  simply to make the rows look equally large.
- The six fulfilled slices remain open to playtest/balance and UI fixes; “fulfilled” does not claim
  final polish or final numbers.
- Sela's recognition is station-owned because her Table is shared field knowledge. Requiring her
  active presence would contradict its established fiction and the existing station-owned
  packing/harvest benefits.

## Acceptance

The Table recognition fixture is green. Final acceptance is ordinary-phone play confirming all six
built stations visibly perform their first stated function. Any later expansion must answer a new
play need rather than a desire for symmetric feature counts.
