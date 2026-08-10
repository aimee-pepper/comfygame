# Playability-first roadmap — Aimee's test campaign

**Status:** current cross-lead priority authority  
**Owner:** Aimee; Game Design coordinates Engineering and Asset Design  
**Updated:** 10 Aug 2026  
**Supersedes for scheduling:** feature-breadth ordering in `the-queue.md` and `state-of-the-build.md`
where they conflict. Those files remain useful inventories and history.

## Operating assumption

Aimee is the only expected player for this phase. The purpose of the build is to let her complete a
real campaign loop repeatedly, find defects, and make balance judgments. Outside-player onboarding,
broad catalogue completeness, visual breadth and polished late-game content do not outrank a blocker
she encounters in ordinary play.

We work in **small check-in checkpoints**, not an unattended continuous queue:

1. agree on one player-visible outcome;
2. Engineering produces a green simulator build and installs that exact checkpoint on Aimee's phone;
3. Asset Design supplies only the minimum readability proof needed for that checkpoint;
4. Aimee plays the named test script and reports pass/problems;
5. Design updates this roadmap and the relevant current/history docs before the next checkpoint.

No checkpoint is called done because code exists locally. Installed build identity, focused fixtures
and Aimee's play result are separate evidence.

## Hard blockers

### B0 — Essence continuation

**Player outcome:** after reasonable exploration, Aimee can usually write the next ordinary authored
world and still sometimes choose an optional Essence expense.

The mechanical correction is committed at `a816113`: Recommended defaults are 5–7 dedicated Raw
Essence drops worth 2–3 raw each, with independent DEBUG controls and generation/return telemetry.
This is **ready for focused device play**, not balance-final.

Check-in gate:

- use Recommended with all multipliers at 1×;
- play at least three ordinary expeditions first, then continue toward ten over later check-ins;
- for each, record bind cost, generated/collected raw, refined equivalent, Spring yield, exit kind,
  ending spendable Essence and whether anti-lock assistance appeared;
- fail the checkpoint immediately if an ordinary reasonably explored return cannot fund another
  ordinary authored world, even if the blank 10-Essence escape remains technically available.

Asset need: none before play. Raw Essence already has an accepted map identity. Do not delay this
test for new pickup art.

### B1 — early item offloading

**Player outcome:** unwanted equipment stops accumulating as dead inventory. The first two intended
finds teach two distinct decisions: **sell for gold** and **dismantle for known materials**.

This is not live. The design is ready in `opening-economy-traveller-reorder-current.md`,
`trading-post-recycler-current.md`, `trading-post-recycler-economy-current.md` and
`traveller-identity-noll-recycler-current.md`. Implement it as two check-ins so Aimee gets relief
before the entire opening-trio migration is complete.

#### B1 prerequisite — one expedition-outcome receipt

Before stock refresh or other return consumers expand, land the monotonic campaign-local
`ExpeditionOutcomeID` and idempotent atomic return contract in `expedition-outcomes-current.md`.
This is enabling correctness, not a feature detour: without it, relaunch or repeated anchored-realm
returns can duplicate/skip Trading Post refresh and later production.

Gate: ordinary, collapse and anchored returns mint exactly one receipt; combat victory/flee and recap
dismissal mint none; relaunch replays no consumer; repeated visits to one anchored realm receive
distinct outcome IDs.

#### B1a — sell-first Trading Post engine, then Vance integration

- land `goldCoins`, authored trade metadata and safe atomic selling before optional stock breadth;
- selling must work independently of whether the first stock refresh has happened; persisted stock
  refresh consumes one ExpeditionOutcomeID once;
- protected, equipped, unidentified, unique and non-transferable objects explain why they cannot be
  sold; cancellation/stale state costs nothing;
- anti-loop pricing, inventory locks and stale-preview checks are fixture gates;
- then migrate Vance to authored order 1 with the one-condition opening signature, Trading-Post-only
  ownership and provisional 10-Essence construction without rewriting unreviewed prose.

Acceptance on phone: from a fresh campaign, deliberately find Vance, recruit him, build the Trading Post,
sell one eligible item, cancel one sale, and verify inventory/gold/save-reload. If Vance requires
several unrelated discoveries or an unknown post-opening rune, the authored-priority migration fails.

#### B1b — Recycler engine, then Noll/opening-order integration

- first land an independent Recycler station/state plus exactly-one recovery route: real cumulative
  construction receipt when present, otherwise an explicit authored found-gear salvage profile;
- preview names exact outputs and irreversible item loss; cancel/stale state costs nothing;
- capacity, interruption/relaunch and no-invented-provenance fixtures are mandatory;
- then add Noll as stable traveller order 2, construct the provisional 15-Essence Recycler, and move
  Halloway to order 3 together after Aimee reviews Noll's live identity/meeting presentation;
- do not repurpose another person, grant Noll to old saves, or leave Recycler with Vance;
- `field_separation_kit` remains review/playtest content and must not hold up baseline Recycler.

Acceptance on phone: recycle one found eligible item, reject one ineligible item honestly, cancel
one transaction, then reload and prove neither item nor outputs duplicated.

Asset need for B1a/B1b: a compact economy proof, not a new world-art milestone. Trading Post and Recycler
need distinct station silhouettes/states plus a shared, redundant UI grammar for **Keep / Sell /
Recycle / Cannot act / Preview / Confirm / Result**. Item icon, name and provenance remain primary;
colour alone never communicates transaction eligibility.

## Next after blockers

### P1 — Halloway / Blacksmith as the third intended find

Complete the opening trio only after both offload verbs work. Halloway remains authored order 3 and
owns repair/reforge/making-whole. Verify that the opening now reads **circulate → recover → retain/
make**, and that provisional 10/15-Essence stations do not recreate the Essence blocker.

### P1 — close current field/map checkpoints

- install/commit/push the already-green awareness foundation (837 tests) when Engineering approval
  capacity returns; Scent Mask is a later separate check-in;
- integrate AssetLab's corrected terrain contract: remove the native universal grid, replace the
  false full-width dirt ledge with inset terrain-coloured elevation contours, and never put elevation
  marks on chasm;
- phone proof must show ordinary borderless terrain, valid water/ice/chasm adjacency, several nearby
  heights, route/content/flora ownership and a complete unclipped map.

These are visible correctness fixes, but they do not outrank B0/B1 unless they prevent Aimee from
reading or navigating the test world.

### P1 — repeatable playtest observability

- DEBUG Roadmap tab mirrors this file's checkpoint status and next test;
- existing Balancing and Authored-Text Atlas remain development-only tools;
- after B0/B1 pass, add the DEBUG bug reporter specified in `debug-bug-reporting-current.md`: one
  persistent floating button, screenshot + build/context capture, player text, durable untriaged
  outbox and explicit transport state; Aimee never has to assign priority;
- add deterministic grant/fixture actions only as a named test requires them; do not turn the debug
  screen into a second game state editor;
- every installed checkpoint shows a build/commit identifier in DEBUG before Aimee reports results.

### P1 after baseline telemetry — Essence refining progression

Add the keeper-free Spring branch in `essence-refining-progression-current.md`: Measured batches,
Second pass (reversible 2→3 rate), Continuous settling, plus the existing distinct Deepen the Spring
choice. This is long-campaign progression, not permission for the baseline economy to fail. Schedule
its exact costs/rate only after B0's first ten returns and the B1 offloading blockers pass.

## Explicitly paused

Until B0 and B1 pass on Aimee's phone:

- broad new terrain/flora/creature/portrait catalogue work beyond blocker readability;
- additional traveller prose promotion beyond Vance/Noll/Halloway and live nonsense/bug fixes;
- tutorial-content slices for hypothetical new players (existing tutorial layout regressions remain
  bugs and are not paused);
- Great Work, Reality reset, Tam, generic Glass and other endgame expansion;
- new stations, focus breadth, companion systems and balance layers not needed by the test script;
- animation, status-bar polish and other visual breadth that does not clarify a blocker action.

Nothing is deleted. Current specifications and historical decisions remain available, but this phase
does not spend implementation attention on them.

## Current board

| Priority | Checkpoint | State | Next proof / decision |
|---|---|---|---|
| A | Awareness housekeeping | **Complete — `5731aa9`, installed in `d12a8e8`** | 837/837 relevant product tests; phone launch passed |
| B0 / B | Essence continuation | **Current Aimee playtest** | Three Recommended-profile returns; continue toward ten |
| C | ExpeditionOutcomeID / atomic return | **Authorize only after B evidence** | Ordinary/collapse/anchored idempotence and relaunch |
| D | Sell-first Trading Post engine | **Queued** | Sell/cancel/reload, anti-loop and one stock refresh |
| E | Vance order 1 / 10e Trading Post | **Queued separately after D** | Fresh-campaign find/build/sell and old-save migration |
| F | Independent Recycler engine | **Queued separately after E** | Recycle/reject/cancel/reload with one recovery route |
| G | Noll order 2 + Halloway order 3 | **Needs Aimee identity/live-copy approval** | Find/build/order migration; no free Noll |
| P1 | Halloway third / opening trio loop | **Queued after offloading** | Circulate → recover → retain/make playthrough |
| P1 | Awareness foundation | **Green locally; install/checkpoint pending** | Exact phone build, commit and push |
| P1 | Terrain border/elevation correction | **Asset contract ready; native integration pending** | Adjacent-height phone strip and full map |
| P1 after blockers | In-game DEBUG bug reporter | **Designed / transport check-in pending** | Capture, submit, relaunch persistence and triage ingestion |
| P1 after telemetry | Spring refining branch | **Designed; values need B0 evidence** | Batch control, 3:1 future conversion, outcome-safe auto-refine |
| Paused | Breadth and outside-player polish | **Paused** | Reconsider only after B0/B1 pass |

## Check-in record

Add one short entry after each device checkpoint:

| Date | Build | Test | Result | Next action |
|---|---|---|---|---|
| 10 Aug 2026 | `a816113` baseline | Roadmap established; Essence profile awaits focused run | Pending Aimee | Start B0 play; Engineering scopes B1a |
| 10 Aug 2026 | `5731aa9` + `d12a8e8` | Awareness housekeeping plus Settings → Debug Tools tabs | 837/837 relevant product tests; signed iPhone build installed/launched 15:19 PT | Aimee runs B: three Recommended Essence expeditions |

## Cross-lead notes

- **Engineering:** HEAD/origin and Aimee's installed build are `a816113`. A green awareness slice is
  local but uncommitted/uninstalled and owns `WorldMap.swift`, `WorldRules.swift`, `WorldView.swift`,
  `WorldTests.swift` and `ConsumableCraftingTests.swift`; Roadmap work must not touch them. Engineering
  recommends outcome receipt → Trading Post engine → Vance integration → Recycler engine → Noll plus
  Halloway order migration → physical end-to-end loop, with device evidence at each checkpoint.
- **Asset Design:** Raw Essence and Blacksmith already have sufficient identities. Trading Post and
  Recycler are absent from the authored-place catalogue. The only blocker-facing asset scope is a
  compact economy grammar—Keep/Sell/Recycle/Cannot act/Preview/Confirm/Result—and distinct Trading Post/
  Recycler silhouettes. Terrain and creature breadth pause.

## Agreed first check-in

Engineering will not begin a new feature checkpoint until Aimee selects it. Cross-lead recommendation:

1. **A — housekeeping only:** install, commit and push the already-green awareness slice; no added
   mechanics or redesign.
2. **B — Aimee playtest:** run the three-expedition Recommended Essence script on installed
   `a816113` and record the B0 evidence.
3. Return for a regular check-in. If B passes, authorize **C — OutcomeID only**. If B fails, diagnose
   the measured Essence path before beginning Trading Post work.
