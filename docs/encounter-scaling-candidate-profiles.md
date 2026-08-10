# Encounter Scaling — First Three DEBUG Candidate Profiles

**Status:** implementation-ready comparison inputs, not final difficulty. These three profiles exist
to satisfy the device-comparison gate in `encounter-scaling-simulation-current.md`; none becomes the
default shipped balance merely because its fixtures pass.

All profiles share the settled correctness boundaries: full active party including Binder, upper
median level, maximum three actual visible persisted foes, ordinary Stability/greed contribution
applied once, deterministic remainder, opt-in stationary apex, and unchanged Unbind.

| Parameter | A — Reserved | B — Recommended start | C — Pressing |
|---|---:|---:|---:|
| Ordinary equivalents per extra party member | 0.35 | 0.50 | 0.65 |
| Missing-visible-foe conversion cap | +1 level | +2 levels | +2 levels |
| Half/remainder strength step | +1 when stable roll fires | +1 when stable roll fires | +1 whenever remainder ≥0.35 |
| Apex level offset above party upper median | +1 | +2 | +3 |
| Apex HP per extra member | +0.25 | +0.35 | +0.45 |
| Apex HP multiplier cap | 2.0× | 2.4× | 2.8× |
| Apex offence per extra member | +0.06 | +0.10 | +0.12 |
| Apex offence multiplier cap | 1.25× | 1.4× | 1.5× |
| Apex action slots for party 1–2 / 3–4 / 5 | 1 / 2 / 2 | 1 / 2 / 3 | 1 / 2 / 3 |

Profile A tests whether better level reference and modest tempo are already enough. Profile B is the
current recommendation. Profile C intentionally tests the upper comfortable bound; it should be
rejected if protection choices cannot prevent a one-round party collapse or ordinary fights become
boss-length attrition.

## Required fixture matrix

For each profile export one deterministic result for party counts 1, 2, 3 and 5 at level bands 1,
8 and 16. Each band needs:

- one isolated ordinary foe, proving missing budget becomes a bounded visible adjustment;
- three adjacent awake ordinary foes, proving no fourth foe appears and no double danger applies;
- one apex, reporting level, HP, offence and explicit round action schedule;
- one uneven party (`2,4,6,8,20` at five members), proving upper median 6 rather than max 20;
- relaunch equality for entity IDs, level adjustments, remainder roll and apex schedule.

The comparison report includes expected incoming opening-round range and neutral rounds-to-defeat,
but no single analytic score chooses the winner. Aimee plays at least one mid-level five-person
ordinary and apex fixture under A/B/C on phone. Record preference separately for ordinary density,
apex duration, perceived fairness and whether defence/Unbind remained meaningful.

## Promotion rule

After device comparison, copy the selected values—or a deliberately interpolated result—into a new
dated balance decision. Preserve this file and exported results as history. Do not relabel Profile B
“final” without the comparison, and do not change creature trait generation to make a combat profile
look successful.
