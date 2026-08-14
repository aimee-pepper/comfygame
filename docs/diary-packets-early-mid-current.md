# Current Design — Early–Mid Diary Packets

**Status:** implementation-ready for Bryn, Orsa and Talin. Vance's reordered six-page opening packet
below supersedes his former three-location/seven-page shape; exact revised prose enters the atlas as
review-needed where text changed.

## Required content schema

Fighter diaries need one optional page field analogous to `teachesFocus`:

- `teachesGambit: GambitComponentID?`

A page with this field uses kind `gambit` (preferred) or a clearly named equivalent. Acquiring it
permanently grants exactly that component. Do not disguise gambit teaching as `researchLead` or
`symbol`; the Library should say what kind of knowledge the page contains.

Catalog validation must reject an unknown component ID and reject a page that sets more than one
teaching/reveal field.

## Bryn — 7 pages

| ID | Kind / unlock | Prose |
|---|---|---|
| `bryn_where_0` | location clue 0: Relief openness ≤40 | “The land closes around every path. An approach can be watched here, provided somebody agrees to be the one watching it.” |
| `bryn_where_1` | location clue 1: Substrate hard form ≥35 | “The footing does not yield when weight moves onto it. That matters most when the weight was meant for somebody else.” |
| `bryn_where_2` | location clue 2: Atmosphere peak ≥62 | “The air presses at every chest alike. It does not care who volunteered to stand first.” |
| `bryn_teach_back_rank` | gambit; `subject_ally_back_rank` | “Do not ask who is weakest. Ask who has been placed where harm reaches them before help does: the ally in the back rank.” |
| `bryn_word_marrick` | whereabouts; `marrick` | “Marrick will have made a routine wherever he stopped. Look for several bedrolls aligned too neatly and one place left open for somebody who never joined.” |
| `bryn_world_two_exits` | world worth writing | “Write somewhere with a narrow approach and two exits. One lets you hold. The other keeps holding from becoming a sentence.” |
| `bryn_site_wayfarers_camp` | ruin/site; `wayfarers_camp` | “A camp is not safer because somebody stood guard. It is safer when the guard can wake the others without asking permission to command them.” |

Arc coverage: intervention · consent · formation exclusion · Marrick · practical retreat.

## Orsa — 7 pages

| ID | Kind / unlock | Prose |
|---|---|---|
| `orsa_where_0` | location clue 0: Vitality peak ≥62 | “Every cleared place is used again by morning. Nothing here mistakes vacancy for abandonment.” |
| `orsa_where_1` | location clue 1: Relief openness ≤45 | “The ground makes rooms without doors: shelter enough to gather, and more than one way to leave.” |
| `orsa_where_2` | location clue 2: Atmosphere motion ≤20 | “Smoke climbs without being torn sideways. A person can choose where to sit before the air chooses for them.” |
| `orsa_hive` | focus; `hive` | “A hive is many lives returning to one structure. Convergence is not intimacy. Repetition is not consent.” |
| `orsa_word_sela` | whereabouts; `sela` | “Sela leaves before a place can ask what staying means. She still marks the routes back. Do not confuse reluctance with indifference.” |
| `orsa_word_vance` | whereabouts; `vance` | “Vance can tell you what passed through a room by what people bothered to repair. He will call this trade knowledge. Let him.” |
| `orsa_site_wayfarers_camp` | ruin/site; `wayfarers_camp` | “The same fire ring has been rebuilt three times, each smaller than the last. Whoever stopped here understood that shelter can be inherited without being owned.” |

Arc coverage: temporary shelter · privacy · Sela · Vance · convergence without forced closeness.

## Vance — 6 pages (opening reorder)

| ID | Kind / unlock | Prose |
|---|---|---|
| `vance_where_0` | location clue 0: Relief openness ≥68 | “A load can cross the horizon here without the land inventing a toll.” |
| `vance_world_seams` | world observation | “The useful ground keeps to seams. Value is easier to bargain over when both people can point to its edge.” |
| `vance_world_pockets` | world observation | “Life gathers in separate pockets. Moving something between them changes its price before it changes the thing.” |
| `vance_amber` | focus; `amber` | “Amber preserves by removing a thing from circulation. Sometimes that protects a history. Sometimes it only makes the theft last.” |
| `vance_word_orsa` | whereabouts; `orsa` | “Orsa never charged for the fire. She did expect anyone using it to notice who else was cold. Some debts become clearer when nobody names them.” |
| `vance_site_binders_workshop` | ruin/site; `binders_workshop` | “The tools in the old binder's room came from six hands. I know because every handle was changed for the next one. Ownership is rarely the longest fact about an object.” |

Arc coverage: circulation · provenance · Orsa · unequal need · preservation versus use. The removed
seventh page's repaired-handle idea is already carried by the Workshop page and should not be kept as
near-duplicate padding.

## Talin — 7 pages

| ID | Kind / unlock | Prose |
|---|---|---|
| `talin_where_0` | location clue 0: Substrate hard form ≥40 | “The ground breaks into plates with edges clean enough to show where force will glance away.” |
| `talin_where_1` | location clue 1: Relief openness ≥70 | “Nothing here hides an approach. That does not make deciding when to meet it easier.” |
| `talin_where_2` | location clue 2: Illumination peak ≥65 | “At the brightest interval every edge separates from the surface behind it. A visible opening can still close while you consider it.” |
| `talin_teach_armour` | gambit; `subject_foe_armour_above` | “Do not spend the narrow point on every target. Ask first whether the foe's armour is above the mark where an ordinary blow stops being honest.” |
| `talin_word_dagg` | whereabouts; `dagg` | “Dagg will be on ground that punishes a hurried commitment. He calls waiting discipline. Ask who bears the time while he practises it.” |
| `talin_word_bryn` | whereabouts; `bryn` | “Bryn decides quickly when somebody else is exposed and slowly when the choice concerns only her. Both habits have saved us. Neither is automatically right.” |
| `talin_world_one_clear_edge` | world worth writing | “Write somewhere with one clear edge and enough distance to see it early. The exercise is not finding the correct decision. It is accepting that correctness also has a time.” |

Arc coverage: decisive action · revised judgement · Dagg contrast · Bryn · responsibility before
certainty.

## Implementation and validation

1. Introduce all four traveller definitions in authored order before resolving cross-references, or
   land each relationship page only after its target ID validates.
2. `subject_ally_back_rank` and `subject_foe_armour_above` are semantic IDs; engineering may retain an
   already-established stable ID if the player-facing meaning matches exactly. Record any mapping.
3. Location conditions come from `traveller-signatures-early-mid-current.md`; these passages may
   replace the shorter working lines there without changing mechanical meaning.
4. Page completion is never required to recruit. Three location clues provide the complete signature;
   other pages provide redundancy, character and useful unlocks.
5. Site pages reveal a known site definition and never guarantee placement in the current world.
6. No prose page is mechanically blank and no page grants two unlocks.
