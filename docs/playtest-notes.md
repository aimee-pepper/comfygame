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
| Minimap placement regressed | **Corrected and visually accepted 9 Aug** | Keep the minimap beside the D-pad in the otherwise blank area above Portal home; never stack it beneath the arrows on an ordinary phone |
| Raw essence seems rarer since other resources began spawning | **Acquisition correction installed; balance still to measure** | Raw Essence has a dedicated drop pass, is excluded from ordinary node competition, and has independent DEBUG frequency/yield controls. Continue recording obtainable Essence and next-bind runway before further tuning |
| Writing no parameters appears to produce the same neutral, stable world consistently | **Fixed in `9bd9ca2`** | Blank pages now roll all unwritten subjects and derive Stability from the resolved whole world rather than only placed runes. Keep distribution telemetry; blank remains cheap and unpredictable, not reliably neutral |
| Add a debug menu with sliders for balancing | **Direction approved; ready for engineering specification** | Next-world/run scope; grouped controls; separate persistent debug profile; visible non-default state; Reset All. Initial controls listed in `decisions-session-18.md` |

## Debug menu — approved first batch

See `decisions-session-18.md` §3. This direction was approved by Aimee on 8 Aug 2026.

## 9 Aug 2026 — physical-phone and content pass

Full priority and design interpretation: `playtest-triage-9-aug-2026-current.md`.

| Observation | Triage | Intended design / next question |
|---|---|---|
| Isolde's meeting reads nonsensically; tapping choices reorders text and gives no distinct branch response | **Correctness bug plus copy audit** | Preserve transcript order; append only the selected question/reply. Review Isolde's optional branches as independent exchanges rather than one forced sequence |
| Tutorial distorted the world layout; map clipped at the bottom on phone | **Fixed and accepted after reopened physical-phone pass** | Lossless v2 proofs show 11×11 whole cells/full border, overlay-independent geometry, D-pad left, minimap right and Portal below; full suite 810/0 |
| Sabine's trophic-depth hint reads nonsensically | **Corpus-level clarity issue** | Rewrite Sabine's location pages concrete observation first, inference second. Do not approve one line while the rest retain the same abstraction problem |
| Need an atlas for reviewing every character's dialogue and clues | **Approved DEBUG tooling direction** | Same rendering path as game; stable node/page metadata; Good/Needs revision flags, notes, filters and export; never save-game state |
| Apex and ordinary encounters feel too easy for developed parties | **Balance/design audit confirmed** | Fix full-party level input, then simulate modest size-based encounter budget and separate apex floor/multiplier before tuning |
| Add ways to avoid animal aggro or encounters and reduce visibility | **Design-ready after scaling** | Make existing Shadow nodes truthful through readable awareness; review one animal-only Scent Mask and retain existing Lure as the risky opposite. No equipment family is required for the first slice |
| App hangs on a black screen during launch | **Fixed and accepted** | Native v1 moves preparation behind matching static/in-app Atlas pages, records cold/warm timing, serializes timeout/retry writers, supports diagnostics and one-shot VoiceOver transitions; 816/0 and ordered transition evidence |

**Map-regression final verification:** Engineering's measured-scroll-viewport layout fixture and full
suite were green (810 tests). Design inspected the replacement 368×800 in-game artifact at
`docs/test-artifacts/world-map-compact-phone-after.jpg`, but later physical-phone evidence invalidated
that acceptance: the tutorial still affects layout and the last grid row is visibly fractional. The
artifact is retained as historical evidence, not current acceptance proof. The intended result simultaneously
shows the complete square including its bottom row, D-pad, minimap and Portal home control, all unobscured.
The reopened fix is accepted against `world-map-phone-overlay-v2.png` and
`world-map-phone-controls-v2.png`, both lossless 1206×2622 captures. The earlier PNG was an invalid
1206×2622 Home Screen capture and is superseded;
Engineering removed it in the evidence-correction commit.

## 10 Aug 2026 — playability and compact-layout pass

| Observation | Triage | Intended design / next question |
|---|---|---|
| Reliable Essence and no way to offload items block continued campaign testing | **Hard blockers** | Trading Post/Vance first; Recycler/Noll follows after the sell loop is proven. Baseline Essence remains telemetry-driven and refining progression cannot excuse a failed continuation loop |
| Equipment picker may not expose every owned item | **Critical fix installed in `a77c9dd`** | Exact physical instances from stored, waiting and worn sources; carried gear remains visible/read-only outside an explicit field-loadout rule |
| Recovered pages and recruited people were absent from the expedition recap | **Fixed in `9bd9ca2`; audit reconfirmed 10 Aug** | Recap freezes only pages, other writings and people newly recovered/recruited during that run for portal and partial-haul exits; permanent knowledge survives collapse |
| Repeated recap totals of exactly 100 XP | **Observability/correctness fix installed in `a77c9dd`** | Full XP still goes to every active member; recap now names sources and duplicate known diary pages cannot award page XP |
| Terrain displayed false sidewalls | **Renderer correction installed in `a77c9dd`; device verification pending** | Material changes alone never create a wall; genuine elevation may show a restrained material-matched riser |
| Major collection screens still feel like lists; two columns is only marginal | **Current UI grammar settled** | Physical things use six-across icons and tap detail; people use identity tiles; places use destination boards; recipes use compact choice tiles; genuinely ordered prose/logic may remain lists |
| Party member buttons are unnecessarily tall and force scrolling | **P1 layout defect** | All five ordinary Party tiles fit simultaneously on 368×800 while retaining ≥44pt targets, name, Level, Health and Rank; accessibility sizes may reflow/scroll |
| Library page section appears inaccurate | **P1 presentation audit complete** | Separate pages written by an author from clues about a person over one stable recovered-page set; counts name their basis |
| Information text lets Field Kit/resources hide under the fixed direction/minimap pane | **P1 layout defect** | Measured bottom scroll inset follows actual fixed controls; final content can be brought fully above them at phone and large-text sizes |
| Add Look beside Use tile to inspect adjacent terrain | **Approved interaction; queued** | Arm Look then press one D-pad direction; no movement/turn/disclosure; report authoritative terrain cost, known harm and visible traversal facts |
| Need floating screenshot + text bug submission | **Maximum priority after Trading Post/Vance and resource visuals** | Durable DEBUG outbox plus screenshot/context and idempotent HTTPS relay; only a real remote receipt says Submitted |
| Storehouse Resources should be iconized | **P1 UI requirement; does not displace blockers** | Six-across quantity icons with tapped resource detail during the later collection UI pass |
