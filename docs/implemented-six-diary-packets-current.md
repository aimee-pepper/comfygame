# Current Design — Implemented-Six Complete Diary Packets

**Status:** implementation-facing page plan and authored prose. Existing live pages remain unless
explicitly superseded. New relationship pages that reference not-yet-live travellers are marked
**defer until target exists** so catalog validation never accepts dangling IDs.

## Packet totals

| Traveller | Live now | Target | Add now | Deferred relationship additions |
|---|---:|---:|---:|---:|
| Mara | 3 | 6 | 3 | 0 |
| Edren | 5 | 7 | 1 | 1 (Lys) |
| Halloway | 4 | 6 | 1 | 1 (Dagg) |
| Isolde | 4 | 7 | 2 | 1 (Lys) |
| Sela | 6 | 7 | 0 | 1 (Orsa) |
| Tovin | 11 | 14 | 3 | 0 |

Every page has exactly one unlock. Prose may carry character and relationship meaning in addition to
that unlock, but no page grants two mechanical rewards.

## Mara — 6 pages

Existing live pages remain: `mara_where_0`, `mara_scarp`, `mara_word_sela`.

| New ID | Kind / field | Prose | Status |
|---|---|---|---|
| `mara_world_fixed_line` | `worldWorthWriting` | “A useful world gives you one line that stays put while everything else argues. Write for that line first. Decide what it meant after you have stood on it.” | add now |
| `mara_site_crystal_cavern` | `ruin`; site `crystal_cavern` | “There is a cut in the stone where every face returns the same crooked horizon. I marked it twice. The fault is in the place, not the instrument.” | add now |
| `mara_word_tovin` | `whereabouts`; about `tovin` | “Tovin measured distance in bindings instead of miles. If a world felt too costly to leave, that was the one he stayed in.” | add now |

Shape: location · focus · Sela · Tovin · worthwhile world · surveyed site.

## Edren — 7 pages

Existing live pages remain: two location clues, Ruin, Binder's Workshop site lead and research lead.

| New ID | Kind / field | Prose | Status |
|---|---|---|---|
| `edren_world_second_floor` | `worldWorthWriting` | “Write somewhere the ground has been used more than once. A first floor tells you who arrived. A second tells you who refused to begin again.” | add now |
| `edren_word_lys` | `whereabouts`; about `lys` | “Lys would object to my ordering these fragments before she saw them. She is correct. She is also not here, and the mud is.” | **defer until Lys exists** |

Shape: two location · focus · site · research · worthwhile world · Lys.

## Halloway — 6 pages

Existing live pages remain: two location clues, Gold ore and one worthwhile world.

| New ID | Kind / field | Prose | Status |
|---|---|---|---|
| `halloway_lead_pencil` | `researchLead`; node `pen_pencil` | “A nib does not need to be precious. It needs to wear at the same rate on both sides. Bring Isolde metal that can keep that promise.” | add now |
| `halloway_word_dagg` | `whereabouts`; about `dagg` | “Dagg waits before a strike until waiting becomes the work. Look for hard ground, changing pressure, and someone testing where his weight will go afterward.” | **defer until Dagg exists** |

Shape: two location · focus · worthwhile world · hand-material lead · Dagg.

## Isolde — 7 pages

Existing live pages remain: two location clues, Hush and one worthwhile world.

| New ID | Kind / field | Prose | Status |
|---|---|---|---|
| `isolde_lead_pencil` | `researchLead`; node `pen_pencil` | “Charcoal teaches confidence because it cannot hide a correction. A pencil teaches revision. Do not call the second lesson refinement until you have learned both.” | add now |
| `isolde_word_tovin` | `whereabouts`; about `tovin` | “Tovin learned to close a binding neatly before he learned when not to make one. His lines improve whenever he is frightened. This is not the compliment he thinks it is.” | add now |
| `isolde_word_lys` | `whereabouts`; about `lys` | “Lys reads the pressure left by a hand after the words are understood. If she found shelter, there will be pages arranged by disagreement rather than date.” | **defer until Lys exists** |

Shape: two location · focus · worthwhile world · pencil lead · Tovin · Lys.

## Sela — 7 pages

Existing live pages remain: three location clues, Pond, Halloway whereabouts and one worthwhile world.

| New ID | Kind / field | Prose | Status |
|---|---|---|---|
| `sela_word_orsa` | `whereabouts`; about `orsa` | “Orsa can make stopping feel temporary without making it feel unsafe. Follow the places where several routes have used the same fire and nobody has claimed the ashes.” | **defer until Orsa exists** |

Shape: three location · focus · Halloway · Orsa · worthwhile world.

## Tovin — 14 pages

Existing live pages remain: eight location clues, Drift, Edren whereabouts and the cross-diary Isolde
location clue. The extra pages make his longer book about worlds he chose and lost, not merely a longer
password.

| New ID | Kind / field | Prose | Status |
|---|---|---|---|
| `tovin_world_held_four` | `worldWorthWriting` | “The fourth world paid for its own binding, which is how I described it while I was taking the payment. It had blue mineral rain and nothing living beneath it. I still miss the sound.” | add now |
| `tovin_world_left_open` | `worldWorthWriting` | “I once wrote a generous place and left it unbound because I was afraid greed would make the choice for me. Caution made the choice instead. Loss does not become wisdom because you can defend it.” | add now |
| `tovin_site_atlas_seam` | `ruin`; site `natural_anchor` | “Some worlds have a place where the old binding still catches. You can feel the page pull taut around it. Do not mistake finding the seam for deciding what deserves to hang from it.” | add now |

Shape: eight location · Drift · Edren · Isolde cross-clue · two lost/held worlds · Atlas Seam.

## Implementation rules

1. Add all **add now** pages without waiting for the later cast.
2. Add a deferred page in the same batch that introduces its target traveller; never weaken catalog
   validation to accept a dangling `about` reference.
3. Preserve live prose and IDs unless a separate honesty audit supersedes a line.
4. Each `researchLead` grants progress only, never the finished node.
5. A `ruin` page reveals the named site definition; it does not place that site in every world.
6. The two Isolde/Halloway pencil leads may both point to `pen_pencil`: separate partial leads can
   contribute toward one study, but neither page completes it alone.
7. Diary completion remains a reward, never a gate. Location pages alone plus redundancy must suffice
   to find each person.

