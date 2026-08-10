# Current Design — Companion Worldwork Aptitude

**Status:** implementation-facing first-slice rule. Rating values and level cadence are playtest
tuning; the authored-aptitude principle is current.

## Why level alone is insufficient

A level-only assignment formula makes whichever companion fought most automatically best at every
anchored-world job. That erases calling and story, over-rewards party rotation, and makes a skilled
surveyor or delver worse than an unrelated veteran fighter at the work that defines them.

The first Anchoring slice needs one legible authored aptitude, not a worker-management subsystem.

## Worldwork

Every companion has a visible **Worldwork** rating:

| Rating | Label | Meaning |
|---:|---|---|
| 0 | Unsuited | Can be posted, but contributes only the universal minimum |
| 1 | Capable | Ordinary default, including generated companions without a strong field trait |
| 2 | Skilled | Calling or lived practice directly supports sustained work in a realm |
| 3 | Expert | Anchored-world fieldwork is central to this person's identity |

Working production formula:

`production contribution = 1 + Worldwork + floor((level - 1) / 5)`

- Everyone contributes at least 1; “Unsuited” never means useless or forbidden.
- Levels 1–5 add no bonus, 6–10 add 1, and so on.
- Expose the level cadence and contribution multiplier in debug tuning.
- The formula may later read world/task specialities, but the first slice has one number only.

## Implemented six

| Traveller | Worldwork | Reason |
|---|---:|---|
| Mara | 2 | Surveying, mapping and reading terrain |
| Edren | 2 | Field sites, ruins and careful recovery |
| Halloway | 2 | Material judgement and practical making |
| Isolde | 1 | Capable, but her defining work belongs at the page |
| Sela | 3 | Routes, provisions, flora recognition and sustained travel |
| Tovin | 3 | Binding, realm failure and anchored-world stewardship |

Generated companions default to 1. A later generator may derive 0–2 from visible traits/calling, but
must never secretly roll an aptitude the player cannot inspect.

## Current roster guidance

These are content defaults for future data, not a new order gate:

- **3 Expert:** Sela, Tovin, Kestrel, Grimmond.
- **2 Skilled:** Mara, Edren, Halloway, Corrin, Nessa, Bracken, Fen, Sabine, Auber, Rook, Wren.
- **1 Capable:** Isolde, Orsa, Vance, Maud, Oda, Lys, Bryn, Talin, Dagg, Marrick, Ashe, Perren, Nine.
- **Tam:** held until their actual contribution exists.

Ratings do not judge a person's worth. They describe fit for one posting. Fighters retain their party
advantage; station keepers retain their home-posting value.

## Scope boundary

Do not add separate Mining, Farming, Defence, Morale or Maintenance stats in the first slice. They
would create UI and balancing work before the anchored-world tasks exist. Add a speciality only when
two real realm assignments create meaningfully different companion choices that Worldwork cannot
express.

Permanent injury/loss remains excluded. Dormancy returns workers safely to base.

