# Playtest Notes

**Purpose:** Aimee's observations from playable builds, kept separate from design decisions and the
engineering backlog. The design lead triages each observation; engineering records implementation
work in `BACKLOG.md`.

## 8 Aug 2026 — current issues and requests

| Observation | Triage | Intended design / next question |
|---|---|---|
| Selecting a skill tree from Party crashed | **Fixed by engineering** | Verify in the next build; no design change |
| Move party-member stats to a tab, consistent with the rest of the member page | **UI change requested** | Preserve the roster as a quick overview; move the detailed stat presentation into the member's tabbed page. Exact tab structure to review with engineering |
| No collectible pages appeared across the last 5+ generated worlds | **Design mismatch confirmed** | Session 18: guarantee at least one writing per world. Retain the eight-world mismatched-diary fallback provisionally, but age only one nominated page at a time; explicitly revisit its story cost after playtesting |
| Requested minimap is absent below the navigation area | **Implementation omission confirmed** | `MinimapView` already exists and session 13 specifies placement under the movement arrows, but `WorldView` does not embed it |
| Raw essence seems rarer since other resources began spawning | **Acquisition bug confirmed; balance still to measure** | Raw Essence has its own removable wild-drop pass, but it was also eligible to consume an ordinary harvest-node draw. Exclude it from node tables, retain separate frequency/yield controls, then measure obtainable essence per world before tuning |
| Writing no parameters appears to produce the same neutral, stable world consistently | **Likely implementation or tuning bug; conflicts with settled design** | Every unwritten subject is meant to roll at bind. A blank page should be cheap and unpredictable, not a reliable neutral-world strategy. Verify variation in the generated terrain, readings, life, resources, and stability—not merely the preview text |
| Add a debug menu with sliders for balancing | **Direction approved; ready for engineering specification** | Next-world/run scope; grouped controls; separate persistent debug profile; visible non-default state; Reset All. Initial controls listed in `decisions-session-18.md` |

## Debug menu — approved first batch

See `decisions-session-18.md` §3. This direction was approved by Aimee on 8 Aug 2026.
