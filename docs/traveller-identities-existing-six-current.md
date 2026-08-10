# Current Design — Mara, Edren, Halloway, Isolde, Sela and Tovin

**Status:** Current authored direction; preserves implemented meetings and voices  
**Implementation boundary:** Content handoff for engineering; the design thread does not edit
traveller data

## Shared decisions

- Preserve all six names, identities and implemented meeting scenes.
- Relative order among these six is **Mara → Edren → Halloway → Isolde → Sela → Tovin**. In the
  full roster, other travellers occupy orders 6–25 and Tovin is global authored order **26**. Do not
  rely on JSON array order once explicit order/phase fields exist.
- Repair dishonest clue prose before expanding diaries. Keep current thresholds unless measured
  reachability later proves they should change.
- Sela remains a **wanderer**. Fieldcraft follows from that life; it does not replace it.
- One location page remains paired with each signature condition.
- Tovin remains last of this set. His eight-condition implementation profile is now specified below;
  exact thresholds remain playtest tuning.

### Authored order and campaign phase

| Global order | Traveller | Design phase | Recommended schema value |
|---:|---|---|---|
| 1 | Mara | Opening | `opening` |
| 2 | Edren | Opening | `opening` |
| 3 | Halloway | Opening | `opening` |
| 4 | Isolde | Start of mid | `startOfMid` |
| 5 | Sela | Mid | `mid` |
| 26 | Tovin | Late | `late` |

The non-contiguous jump is intentional and follows `roster-progression-current.md`, which is the
authority for whole-cast ordering. `startOfMid` is intentionally distinct from `mid`: Isolde is the required hand-progression hinge
that begins the middle campaign, while Sela is the first hunt designed to exercise that expanded hand.

## Clue-honesty handoff

These passages describe what the existing conditions guarantee. They supersede the current
overclaims in `travellers.json`; final copy may polish rhythm without restoring unsupported facts.

| Traveller | Existing mechanical condition | Current-design passage |
|---|---|---|
| **Mara** | Illumination peak ≥ 60 | “At its brightest, the horizon burns white enough to swallow my sighting line.” |
| **Edren** | Hard substrate form ≥ 35 | “More hard stone than loose ground. My trowel complains before I do.” |
| **Edren** | Thermal floor ≤ 25 | “The cold settles low enough to numb my fingers through the cloth.” |
| **Sela** | Available hydrology ≥ 30 | “Enough water that I can choose the next crossing instead of rationing the last.” |
| **Isolde** | Relief peak ≥ 55 | “The land rises until every line I rule looks level by comparison.” |
| **Isolde** | Substrate peak ≥ 55 | “So much of this place is ground and stone that even the horizon feels written in it.” |
| **Tovin** | Substrate peak ≥ 40 | “Ground in every direction—floor, wall, ceiling, and the dust between.” |

Mara's old passage claimed a high light floor, not peak. Edren's added worked stone and darkness;
Sela's added motion and ubiquity; Isolde's added enclosure, stillness and luminous rock. Those images
may appear on non-signature pages but cannot guide the player toward conditions that do not produce
them.

## Current identity sheets

### Mara — Surveyor

- **Identity:** Searches for fixed points in places that drift; dry, persistent and more comfortable
  measuring uncertainty than claiming it is solved.
- **Contribution:** Survey Post, field instruments, entry mapping and minimap depth.
- **Teaching:** **Scarp**, diary-exclusive. This uses the existing surveyor-owned relief proposal
  instead of adding the near-synonym Bluff.
- **Diary:** 6 pages—one location, Scarp, Sela whereabouts, one world worth writing, one surveyed
  landmark/site and one personal/cast fragment.
- **Arc:** Measurement first appears to be Mara's stable refuge; later pages show that choosing what
  counts as fixed is itself a consequential judgement.
- **Relationships:** Sela, Tovin and Rook.

### Edren — Archaeologist

- **Identity:** Keeps finding evidence that every apparent nowhere was once somewhere; patient with
  traces and less patient with stories that skip the people who made them.
- **Contribution:** Reliquary, site discovery, field interpretation and richer site outcomes.
- **Teaching:** **Ruin**, diary-exclusive.
- **Diary:** 7 pages—two location, existing ruin and research lead, Ruin, one cast whereabouts page
  and one fragment changing how the player reads habitation or the Sundering.
- **Arc:** Floors first prove that people were here; later pages complicate his tendency to infer
  continuity or intention from whatever survived.
- **Relationships:** Lys, Grimmond and Perren.

### Halloway — Smith

- **Identity:** Understands craft as staying with a process through heat, cooling and revision; terse,
  concrete and uninterested in strength that cannot remain useful afterward.
- **Contribution:** Blacksmith, ordinary equipment, repair, reforging, salvage, instruments and nibs.
- **Teaching:** **Gold ore**, diary-exclusive. This remains distinct from the more general Gold focus.
- **Diary:** 6 pages—two location, existing worthwhile-world page, Gold ore, one forge/resource site
  and one kept-fire relationship fragment.
- **Arc:** The kept fire appears to prove endurance; later material asks what she neglected while
  preserving the one process she could still control.
- **Relationships:** Dagg, Maud, Bracken and Sela.

### Isolde — Calligrapher

- **Identity:** A teacher for whom discipline enlarges expression by making it smaller and more exact;
  demanding about material conditions without confusing difficulty with virtue.
- **Contribution:** Scriptorium, hands, compounds and page lens. She remains the required progression
  hinge.
- **Teaching:** **Hush**, diary-exclusive; it lowers atmospheric motion. Hush replaces the atmospheric
  use of Stillness, leaving Stillness solely to Cycle.
- **Diary:** 7 own pages—two location, existing hand page, Hush, one penmanship/compound page, one
  relationship page and one site/world observation. Tovin's external clue remains extra redundancy.
- **Arc:** Her exacting practice first reads as certainty; later pages show the cost of teaching one
  correct form as though every hand should reach it identically.
- **Relationships:** Tovin, Lys and Nine.

### Sela — Wanderer

- **Identity:** Keeps moving because destinations imply an obligation to become finished; curious,
  tired and skilled at finding a way through without pretending every route leads somewhere.
- **Contribution:** **The Wayfarer's Table**, a shared route-and-provisions workspace for fieldcraft,
  organic yield, flora identification and carrying support. It holds maps, field notes, packs and
  prepared provisions without trapping Sela behind a counter.
- **Teaching:** **Pond**, diary-exclusive.
- **Diary:** 7 pages—three location, existing Halloway whereabouts and worthwhile-world page, Pond,
  and one route/site or relationship fragment.
- **Arc:** Movement first appears to be freedom from imposed destinations; later pages show how leaving
  can pass unfinished consequences to people with fewer routes.
- **Relationships:** Mara, Orsa, Wren and Halloway. Halloway uses she/her throughout.

### Tovin — Binder

- **Identity:** Understands written-world costs without pretending understanding prevents desire;
  capable, candid and vulnerable to repeating a choice after explaining why it is dangerous.
- **Contribution:** Anchorage, anchor lifecycle, sustain and world assignments—as eventually settled,
  not by assuming the superseded two-step tether model.
- **Teaching:** **Drift**, diary-exclusive.
- **Signature (8 conditions; placeholder thresholds, approved direction):**
  1. Illumination peak ≤ 20 — “It is dark, and the dark is not empty.”
  2. Vitality carries `fungal` — “What grows here does not need the sun.”
  3. Substrate peak ≥ 60 — “Ground in every direction—floor, wall, ceiling, and the dust between.”
  4. Relief openness ≤ 35 — “Everything is close. I do not like it.”
  5. Hydrology salinity ≥ 45 — “The water leaves a white seam wherever it withdraws.”
  6. Thermal floor ≤ 25 — “Even the deepest hours never soften the cold.”
  7. Atmosphere motion ≤ 20 — “No draft reaches the loose corner of this page.”
  8. Cycle regularity ≥ 85 — “Every interval arrives exactly when the last one promised.”
- **Reachability:** the signature never requires Drift, its own reward. Existing/research vocabulary
  can satisfy the first six; Hush comes from earlier Isolde and the regular Cycle condition can be
  written with Orrery. Halloway's Gold ore can supply the rich, concentrated substrate.
- **World identity:** a dark, enclosed fungal mineral world with briny seams, deep cold, still air and
  unnervingly exact time. Tovin teaches Drift in contrast to the over-controlled realm where he was
  found: a binder understands uneven passage because he has also tried to make it obey.
- **Diary:** Longer than 10 after signature expansion—eventually 7–8 location pages, Drift, existing
  Edren/Isolde connections and several written/held/lost-world or anchoring pages.
- **Arc:** Tovin first seems wiser because he can name the temptation; later pages establish that
  literacy and self-control are different capabilities.
- **Relationships:** Isolde, Mara, Oda/Ashe and Nine.

## Engineering sequence

1. Correct the seven clue passages and Sela's Halloway pronoun.
2. Add explicit authored order and campaign phase when traveller schema work is in scope.
3. Add missing pages/teachings only after station and vocabulary references validate.
4. Build Edren's Reliquary and Sela's Wayfarer's Table from current specs, not old Library,
   Forager's Shed, Workshop or tether notes.
5. Implement Tovin's eight conditions after the generic diary-teaching work; measure accidental
   matches before treating the placeholder thresholds as balance-final.
