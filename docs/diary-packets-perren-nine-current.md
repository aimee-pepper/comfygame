# Current Design — Perren and Nine Diary Packets

**Status:** Authoritative endgame books. Perren has twelve pages; Nine has thirteen. Their longer
length supports interpretive arcs, not extra signature conditions.

## Perren — 12 pages

Perren's book has no canonical discovery order. Location passages double as arguments he could have
written while entering or leaving the Sundering. No page identifies itself as “before” or “after.”

| ID | Kind / unlock | Prose |
|---|---|---|
| `perren_where_0` | location: Illumination opposed >=20 | “Light is made and smothered together. They taught that conflict reveals the truer source. It may only reveal who selected the frame.” |
| `perren_where_1` | location: Thermal opposed >=20 | “Heat and cold press into the same interval. A forced choice between them would make either answer feel discovered.” |
| `perren_where_2` | location: Vitality opposed >=15 | “Growth and suppression are both active. The bare patch is evidence of relation, not proof that one side was always barren.” |
| `perren_where_3` | location: Relief tag `ruined` present | “This ground has been shaped, broken and cited as more than one history. A ruin becomes doctrine when alternatives are filed as debris.” |
| `perren_where_4` | location: Relief openness <=35 | “The route is framed tightly enough for the next choice to resemble the only one. The instruction can disappear once the corridor is built.” |
| `perren_where_5` | location: Substrate dispersion >=70 | “Worked matter is spread evenly. Any chosen sample can represent the whole if no one asks who chose it.” |
| `perren_where_6` | location: Atmosphere clarity <=40 | “Distance removes context before it removes the object. Certainty improves exactly where relation becomes hardest to inspect.” |
| `perren_where_7` | location: Cycle regularity >=85 | “The interval repeats until recurrence resembles proof. A ritual can teach expectation and then present fulfilment as revelation.” |
| `perren_where_8` | location: Hydrology salinity >=45 | “Withdrawal leaves a bright boundary. It looks inevitable after it appears; the water remembers otherwise.” |
| `perren_mirror` | focus; `mirror` | “A mirror reverses while appearing exact and excludes everything outside its edge. Use it to test a frame, never to certify one.” |
| `perren_word_lys` | whereabouts; `lys` | “Lys keeps contradictory accounts together without requiring one to disappear. I once called that failure to conclude. I had been trained to fear the space she preserves.” |
| `perren_turn_unframed` | turn | “I cannot mark the sentence where belief became departure. Perhaps there was none. I began keeping the questions the lesson told me were already answered.” |

### Order-independent structure rules

- UI sorting may use acquisition order, but prose must not label pages with chronology, conversion
  stages, or a hidden “correct” sequence.
- The turn page complicates every other page; it does not reveal which readings are loyal or apostate.
- Mirror is an interpretive focus, not a truth detector, false-clue remover, or cult-world key.
- Perren's opposed-pressure signature receives a survivability fixture before shipping; difficulty is
  allowed, an effectively lethal arrival world is not.

## Nine — 13 pages

Nine numbers markers she chooses in the present, not recovered pieces of a prior identity. The page
IDs use descriptive names rather than `memory_1`, and no completion event replaces her current self.

| ID | Kind / unlock | Prose |
|---|---|---|
| `nine_where_0` | location: Cycle regularity <=35 | “No interval arrives when the last one taught me to expect it. I can record surprise without treating it as failure.” |
| `nine_where_1` | location: Cycle amplitude >=65 | “When change comes it divides one account from the next. Both accounts belong to the person who wrote them.” |
| `nine_where_2` | location: Illumination tag `sourceless` present | “A little light persists without naming its source. Continuity does not require a complete origin.” |
| `nine_where_3` | location: Thermal range <=12 | “Temperature keeps one answer while duration does not. I choose it as a reference because it holds, not because it is more true.” |
| `nine_where_4` | location: Hydrology dispersion >=70 | “Water reaches nearly every route and never the same point twice. Repetition may preserve a relation without preserving a shape.” |
| `nine_where_5` | location: Substrate dispersion >=70 | “The material repeats while the surface changes. Familiarity can be verified without pretending it is recollection.” |
| `nine_where_6` | location: Relief openness 45–65 | “The horizon is present and bounded. I can use it to check my place without asking it to become an escape.” |
| `nine_where_7` | location: Vitality produced >=40 | “New growth stands beside what the last interval damaged. The later life is not a repair pretending nothing happened.” |
| `nine_where_8` | location: Atmosphere motion <=20 | “A loose marker remains where I placed it. I trust the choice again when I see it, even if I cannot recover making it.” |
| `nine_dream` | focus; `dream` | “A dream joins things without proving they once happened together. It can make a possibility inhabitable without turning it into recovered fact.” |
| `nine_word_isolde` | whereabouts; `isolde` | “Isolde reads discipline in the pressure of a hand. She does not claim the pressure tells her who the hand truly was. This is why I let her teach me.” |
| `nine_word_ashe` | whereabouts; `ashe` | “Ashe is treated as evidence of a force larger than them. We agree that being evidence does not surrender authorship of what happens next.” |
| `nine_word_tovin` | whereabouts; `tovin` | “Tovin binds a world so return remains possible. I bind a marker to a choice for the same reason: return, not restoration.” |

### Identity and implementation rules

- Dream is a world-writing focus. It does not recover biography, generate canonical flashbacks, or
  unlock a memory minigame.
- Two Drift marks plus Tide are the intended deliberate route to low Cycle regularity and high
  amplitude; validation must test the actual combined pressure result.
- The Relief band is one condition. Every other location page is exactly one signature condition.
- Relationships provide redundant story paths and never gate Nine's discovery.
- Diary completion may deepen present-tense dialogue, but cannot reveal a prior name/personality as a
  more authentic replacement for Nine.

## Shared validation

1. All focus and relationship IDs must validate before pages enter the live catalog.
2. Unknown forward references remain deferred; neither book permits silent no-op rewards.
3. Page recovery order is stochastic and every individual page must make sense alone.
4. Recruitment and diary completion remain separate.
