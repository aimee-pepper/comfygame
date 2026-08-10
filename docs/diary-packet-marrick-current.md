# Current Design — Marrick Diary Packet

**Status:** Authoritative ten-page packet; numerical gambit threshold remains player-authored data.

## Marrick — 10 pages

| ID | Kind / unlock | Prose |
|---|---|---|
| `marrick_where_0` | location: Substrate hard form >=50 | “Several sets of feet receive the same answer from the ground. A shared instruction can begin here without becoming shared judgement.” |
| `marrick_where_1` | location: Relief openness 45–65 | “There is room to stand together and still see the edges. Too much room dissolves the signal; too little makes agreement irrelevant.” |
| `marrick_where_2` | location: Atmosphere motion >=55 | “The pressure reaches the whole line. Equal exposure does not mean equal effort, no matter how neatly the positions are counted.” |
| `marrick_where_3` | location: Thermal range <=25 | “Temperature changes slowly enough for fatigue to become visible. Sudden hardship gets remembered; accumulated hardship gets assigned a post.” |
| `marrick_where_4` | location: Cycle regularity >=85 | “The interval returns. Everyone can keep the count until someone misses it, and then the routine must reveal whether it serves people or merely timing.” |
| `marrick_where_5` | location: Hydrology available >=60 | “There is water along the route. No one person must carry enough for everyone, which is how a provision becomes part of the formation.” |
| `marrick_teach_ally_hp_any` | gambit; `subject_ally_hp_below_any` | “Do not choose the endangered person while writing the routine. When any ally crosses the threshold, the formation should already know how to make room.” |
| `marrick_word_bryn` | whereabouts; `bryn` | “Bryn moves danger from one person to herself. I try to change the arrangement before rescue is necessary. She keeps finding the people my arrangement describes too late.” |
| `marrick_word_rook` | whereabouts; `rook` | “Rook makes a boundary legible to the person approaching it. I made mine legible only from inside. That was not a small drafting error.” |
| `marrick_account_missing_position` | account | “The formation held. Every assigned position returned. Only afterward did the report name the porters who could not take a position and were therefore counted as supplies.” |

## Gambit semantics

- `subject_ally_hp_below_any` selects true when at least one living ally is below the configured HP
  percentage. The page teaches the subject component only; it does not prescribe or grant a threshold.
- If several allies qualify, the attached action's ordinary targeting rules resolve its target. The
  subject is a condition, not an implicit lowest-HP targeting rule.
- The page grants one reward and no formation buff by itself.

## Validation and order

- Six location pages reproduce `traveller-signature-marrick-current.md` exactly; the Relief band is
  one condition, not two simultaneous page checks.
- Bryn and Rook may validate before Marrick. The account page has no external target and can always land.
- Relationship pages remain non-gating redundancy. Diary completion is separate from recruitment.

