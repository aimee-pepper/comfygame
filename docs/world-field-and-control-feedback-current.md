# World field and control feedback — functional authority

**Status:** Game Design implementation authority
**Functional owner:** Game Design
**Visual owner:** Asset Lead; Aimee owns final visual acceptance
**Implementation owner:** Engineering
**Updated:** 22 August 2026
**Priority:** immediate World-screen repair; before World Splash and before resuming dynamic gear

## Outcome

The World screen must continuously answer two different player questions:

1. **Where am I standing, and what can I do here?**
2. **What just happened because of my action?**

The first answer is persistent current-place truth. The second is an ordered transient event stream. Neither
may replace the other. Player controls must acknowledge a touch immediately, admit at most one mutation,
and then report the actual committed result or refusal without presenting touch-down as success.

This authority specializes the functional behavior in `player-facing-ui-system-current.md`. It does not
choose font, colour, opacity, border, material, icon treatment, animation art, haptic character or other
visual styling. Asset Lead owns those decisions.

## Hard boundaries

This checkpoint does not change:

- world rules, event production, damage, movement cost, turn cost, rewards, site placement or search time;
- existing player-facing event copy except where a separate terminology authority requires it;
- adjacent consequence cues or local pickup motion in
  `field-feedback-and-loot-presentation-current.md`;
- terrain, flora, site or hazard artwork;
- atmosphere, World Splash, Writing, dynamic gear or creature work;
- hidden-information rules;
- save schema merely to preserve transient feedback.

Per Aimee's 22 August 2026 priority correction, all accessibility-specific work is deferred and
non-operative until she explicitly reauthorizes it. Accessibility clauses in referenced current
authorities do not enter this assignment. This checkpoint contains no VoiceOver, Dynamic Type,
Accessibility XXXL, accessibility-layout, accessibility-proof or accessibility-remediation work.

It also does not authorize generic hazard art to become fire art. `wildfire` is an authored pressure, but
there is no live placed-fire state connecting it to a cell. That missing rules-owned receipt is recorded
below rather than invented by presentation.

## Current source truth and exact regression

The current `WorldRules.Event` order is authoritative. On a successful step it is:

1. movement;
2. slow-ground entry, when applicable;
3. immediate flora contact;
4. content underfoot, including pickup, generic hazard or site discovery;
5. each turn-advance consequence in emitted order, including environmental damage, poison, stability,
   crumbling and creature awareness/contact.

`WorldView.eventLog` still maps those events to player narration, but the view has no mounted call site.
`placeInformation(run)` is the only bottom map presentation. `GameStore.recentEvents` is replaced whenever a
new action completes, and `finishTurn` keeps only a suffix. Therefore a later action can erase an earlier
unseen batch and the existing source test proves only that the obsolete map overlay is absent; it never
proves that narratable events have a replacement consumer.

The repair must remove that false gate and prove a mounted, behaviorally exercised consumer.

## One functional presentation, two regions

At ordinary phone width, one field-feedback row contains:

- **persistent context region:** preferred one quarter of usable row width;
- **transient event region:** preferred three quarters of usable row width.

The ratio applies after the owning visual system's outer insets and inter-region separation. It does not
freeze literal dimensions or styling. A 50/50 fallback is legal only when 368×800 phone evidence proves
that the one-quarter context cannot expose its required complete ground identity. It is not an aesthetic
alternative.

The row reserves layout space and may not cover the current party cell, map controls or fixed action area.

### Persistent context contract

`WorldFieldContextReceiptV1` is a pure projection of the current fully visible player cell after the last
committed mutation:

```text
worldRunID = runIndex + mapSeed
position
groundID + player-facing ground name
elevation 0...3
surfaceDeposits: snow + settledAsh
stabilitySurfaceState: ordinary | cracking
floraIdentity?                    // only the actually present, legitimately disclosed flora
contentSummary: none | node | item | genericHazard | portal | lockedCache |
                site | writing | traveller
interaction: none | harvest | searchSite | enterPortal | openCache |
             takePage | survey | useAnchor | placeAnchor
interactionState: available | unavailable(reason)
inputStateHash                    // canonical SHA-256, never Swift hashValue
```

The compact visible identity always includes the current ground name. A resource, site or action may not
replace it. Ground, relevant surface/elevation state, disclosed content and current interaction remain
available in that semantic order.

Only a committed state change or an actual external world-state update rebuilds the receipt. Touch-down,
an in-flight action, refusal, feedback dismissal and event expiry do not alter context. Hidden adjacent
facts never enter it. A stale input hash fails closed and rebuilds from current state rather than being
patched.

### Transient event contract

Each admitted player attempt that reaches rules owns at most one `WorldFieldEventBatchV1`:

```text
batchID                         // session-monotonic attemptID + canonical payload hash
worldRunID
attemptID
sourceAction: step | travel | harvest | searchSite | interact | useItem | survey | otherWorldAction
turnBefore + turnAfter
orderedEvents[]                // complete rules-emitted order
orderedNarrations[]            // existing closed player-facing adapter; nil events omitted
createdAtMonotonicTime
```

The receipt is presentation-only and never persisted. Relaunch, return Home and starting another run clear
it; History and save files do not replay it. It may reference stable content IDs internally, but only
player-facing names/copy reach the screen.

## Eligibility and ordering

### Event eligibility

Every event already mapped by the closed `WorldView.narrate` adapter is eligible. The only intentional
non-narrated cases are:

- `moved`: the map and persistent context own position;
- `encounterBegan`: the encounter transition owns the result;
- a state whose existing adapter returns `nil`, such as the stable threshold or zero crumbled tiles.

No view invents narration from enum names. An event that transitions away from World remains in the
transaction receipt, but the destination surface owns any final critical explanation; it is not flashed
behind the destination.

### Exact queue rules

1. Accepted batches enter one FIFO queue in commit order.
2. Events inside a batch retain rules order. No severity, colour or copy sorting is legal.
3. Every eligible narration in a simultaneous batch remains reachable. A visual implementation may show
   them together or advance within the batch, but may not keep only a suffix.
4. A new batch never replaces the currently presented batch. It waits behind it.
5. Re-rendering the same `batchID` does not enqueue it again. That is the only event dedupe.
6. Identical semantic events in different batches are never deduped. Repeated poison ticks, repeated
   environmental damage and repeated same-family harvests remain distinct.
7. Multiple equal events inside one authoritative rules array are also retained. Presentation does not
   second-guess rules output.
8. An attempt refused before rules mutation may create one refusal batch, with `turnBefore == turnAfter`,
   but never a success event.

### Expiry and dismissal

- Ordinary presentation: a batch remains current for at least **4 seconds after it becomes visible**.
  When that interval ends, the next queued batch becomes current; if none exists, the transient region
  returns to its non-event state.
- New input does not erase or reset a current batch. It may append a later batch.
- Explicit **Dismiss feedback** removes only the current batch and reveals the next. It spends no turn,
  changes no world state and does not cancel an in-flight action.
- A transition to Encounter, Return or another owning screen clears ordinary queued field feedback only
  after the destination has accepted responsibility for its transition outcome.

There is no fixed three-line or three-event cap. Engineering may compact already presented batches after
expiry, but it may not drop an unpresented batch or narration.

## World action and control feedback

### Closed action-attempt states

Every player-facing control uses one functional state machine:

```text
available
touchDown
accepted(attemptID)
inFlight(attemptID)
completed(attemptID, outcome)
refused(attemptID, reason)
disabled(reason)
```

- `touchDown` acknowledges physical contact only. It performs no mutation, spends no turn and never uses
  success language.
- `accepted` means the current input snapshot admitted the attempt. It does not promise success.
- `inFlight` means that attempt exclusively owns the control's pending mutation/revalidation.
- `completed` exists only after the authoritative mutation commits and names the actual outcome.
- `refused` means no mutation committed; it preserves the attempted context and exact current reason.
- `disabled` is a known unavailable state before touch. Its label remains complete and its reason is visible
  or reachable in the same decision context.

Asset owns how these states look and the supplementary haptic/motion language. Engineering must expose the
states semantically and must not simulate them with a local colour toggle that is unrelated to transaction
truth.

### Whole-surface interaction

The complete visible surface of a player-facing button, tab, chip, card action or compact control is one
hit target owned by one semantic control. Its minimum target is 44×44 pt. Text, icons, padding and visible
background have no dead zones; overlapping sibling targets are prohibited.

Canvas interactions whose geometry is the game object itself—map cells, Page sockets and authored drag
surfaces—are explicit semantic exceptions. They may not be used to avoid whole-surface buttons for ordinary
UI.

### Repeated taps and turn ownership

1. One physical gesture creates at most one `attemptID`.
2. While an attempt is accepted or in flight, additional taps on that action are rejected as busy. They do
   not queue, mutate, spend a turn or restart feedback.
3. One successful turn-consuming attempt advances exactly the rules-owned number of turns. Presentation
   adds none.
4. After completion, a new deliberate tap may begin the next repeatable harvest, search or step.
5. Direction controls perform one step per completed activation; there is no implicit press-and-hold repeat.
6. Tap-to-travel owns one route attempt. A second destination while it is resolving does not create a
   hidden route queue; it is refused as busy unless a separately authored cancel action exists.
7. A stale accepted snapshot is revalidated inside the transaction. Failure becomes `refused`, consumes no
   turn and emits no success batch.
8. Peer navigation to the already selected peer is idempotent and never creates gameplay feedback.

### Control labels and result truth

Controls keep a complete visible player-facing label and their current value/state. Disabled controls and
refusals retain an exact reason in the same decision context. `touchDown` never changes the label to success;
committed outcome or refusal remains inspectable in the transient event region. A navigating action changes
surfaces only after the destination accepts ownership.

## Existing hazard identities and functional states for Asset

This inventory tells Asset what current mechanics can truthfully request. It is not an art brief and adds
no identities.

| Functional identity | Current rules-owned states | Asset-safe request boundary |
|---|---|---|
| slow footing | `mud` or `growth` with actual extra turn | ground identity plus known slow consequence; no separate invented hazard |
| deep water | impassable `deepWater` | disclosed terrain blocker only |
| chasm | impassable `chasm` | disclosed terrain blocker only |
| cracking/collapse | tile `cracking`; tile `isCrumbled`; emitted crumble/loss/floor events | terrain state owned by current cell and visibility |
| generic damaging tile | `TileContent.hazard`; entry emits `hazardHit` | neutral damaging-field identity; never infer fire, poison, site or cause |
| environmental per-turn harm | `BookRules.dangerProfile.damagePerTurn`; emits `hazardHit` | event/status feedback only; it has no placed source cell |
| physical flora defence | generated flora identity; immediate `scratchedByGrowth` | existing flora identity plus learned/actual harm cue; no bespoke named animal/plant |
| chemical flora defence | generated flora identity; immediate harm plus `poisonWorking` turns | existing flora identity plus actual lingering status/event |
| active flora defence | generated flora identity represented by sessile `WorldEnemy` | existing dynamic creature/flora handoff; encounter state, not tile-damage art |
| animated fire | existing pressure ID `wildfire`, but **no live placed-fire state** | **blocked**: no final fire-cell request until rules supply exact disclosed cells and lifecycle |

The minimum future fire presentation receipt, if separately authorized, must use the existing `wildfire`
identity and carry exact current cell coordinates, current visibility, presence/lifecycle state, actual
damage relation and a bounded presentation phase driven by one shared clock. Phase is presentation-only.
Hidden cells emit no request; remembered cells never animate; damage is never inferred from the presence of
fire art. Until that receipt exists, generic hazards remain neutral and Asset is not asked to invent fire
placement, spread, extinction or damage mechanics.

## Existing site identities and states for Asset

Only the nine live site IDs are in this checkpoint:

| Stable ID | Player identity | Category | Search turns | Current special fact |
|---|---|---:|---:|---|
| `wayfarers_camp` | Wayfarer's Camp | recent ruin | 2 | ordinary searchable site |
| `binders_workshop` | Binder's Workshop | old ruin | 3 | ordinary searchable site |
| `glacial_vault` | Glacial Vault | old ruin | 3 | ordinary searchable site |
| `spent_emanation_housing` | Spent Emanation Housing | old ruin | 2 | ordinary searchable site |
| `crystal_cavern` | Crystal Cavern | landmark | 3 | ordinary searchable site |
| `geyser_basin` | Geyser Basin | landmark | 2 | ordinary searchable site |
| `brood_warren` | Brood Warren | living site | 2 | authored guardian `ink_hound` |
| `the_tear` | Tear | hazard site | 1 | contradiction-gated site, not generic tile hazard |
| `natural_anchor` | Atlas Seam | landmark | 0 | natural-anchor interaction |

The reusable functional states are:

```text
hidden                         -> no site render request
disclosedUnsearched            -> exact site ID + category
searching(turnsRemaining)       -> same persistent site; progress is UI truth, not a new building
opened/isLooted                 -> persisted on the placed instance
interactionBlocked(reason)     -> current enemy/stale-state refusal; not a persisted site appearance
```

`PlacedSite.id`, `siteID`, `position`, `isLooted` and `searchTurnsRemaining` are the exact persistence
authority. Asset may later design visuals for these IDs/states but may not infer loot, guardians, danger or
search completion from category or silhouette. Authored-but-not-live proposed sites are outside this handoff.

## Engineering slices

### F0 — pure feedback models and regression gate

- Add pure `WorldFieldContextReceiptV1`, `WorldFieldEventBatchV1` and the action-attempt state model.
- Adapt the existing closed narration mapping; do not fork player copy in the view.
- Replace overwrite/suffix presentation storage with FIFO batch storage while retaining any rules consumers
  that legitimately inspect the most recent event.
- Delete the source-string test that merely bans the old overlay. Add behavioral queue, ordering, expiry,
  dismissal, persistence and context-projection tests.

No player-visible composition ships from F0 alone.

### F1 — first playable World repair

- Mount the persistent context and transient event regions in `WorldView` at the preferred 1/4 + 3/4
  semantic allocation.
- Route step, travel, harvest, search, pickup, blocked movement and other World interactions through one
  action-attempt owner.
- Make the entire visible D-pad and World action surfaces tappable and expose truthful states.
- Preserve map-cell and Look canvas semantics as explicit exceptions.
- Prove 368×800 dark/light behavior with placeholder visual tokens if Asset's system is not yet integrated.
  Placeholder styling cannot change this functional contract.

This is the smallest player-visible Engineering slice and the immediate priority.

### F2 — phone-critical shared controls

Migrate the same action state and whole-surface primitive, without redesigning screens, through:

1. Home destinations and fixed actions;
2. Writing Desk tabs, vocabulary choices and Bind & Depart;
3. Expedition Return Continue and object-detail actions;
4. Encounter decisions and retreat;
5. shared item detail Equip/Unequip/Move.

Each route keeps its existing mutation/revalidation rules. This phase fixes hit ownership and feedback only.

### F3 — economy, Library and remaining player routes

Migrate maker commits, Reforge, Recycler, Trading Post, Library collections, Party, Research and Settings.
Record legitimate canvas/native-control exceptions. Do not bulk-restyle screens.

### F4 — enforcement

- Add a source validator preventing a new player-facing ad hoc tap gesture or custom button from bypassing
  the semantic action primitive unless its documented canvas/native-control exception is registered.
- Keep a checked-in legacy baseline so existing debt decreases monotonically rather than blocking an
  unbounded whole-app rewrite.
- DEBUG tools use the same player-facing action/state names; raw IDs may appear only as secondary evidence.

## Exact acceptance matrix

### Field feedback

| ID | Fixture | Required result |
|---|---|---|
| FF-01 | step onto ordinary ground | context updates to committed destination; no invented event narration |
| FF-02 | blocked boundary/deep water/chasm/crumble | one exact refusal; no move, no turn, context unchanged |
| FF-03 | physical damaging flora | flora event appears after movement and before later tile/turn events; exact HP result; context names actual destination ground |
| FF-04 | chemical flora then two poison turns | entry and each later poison tick are three distinct FIFO events; none deduped |
| FF-05 | generic damaging tile | neutral hazard event after entry; no fire/poison/site claim |
| FF-06 | per-turn environmental damage plus poison | both simultaneous events remain reachable in exact rules order |
| FF-07 | harvest with remaining pulls | exact resource/amount narration, one rules-owned turn, updated remaining interaction |
| FF-08 | final harvest | amount plus depleted truth; later interaction refuses without success |
| FF-09 | step pickup item/resource | actual item/resource and amount; no extra feedback turn; consumed content disappears atomically |
| FF-10 | site search progress | exact site and remaining turns; one turn per accepted search |
| FF-11 | site opens with multiple yields | site-opened then every emitted pickup remains in one ordered reachable batch |
| FF-12 | five rapid accepted actions | five batches remain FIFO; batch N+1 never replaces unpresented N |
| FF-13 | same SwiftUI batch rendered repeatedly | `batchID` enqueued once |
| FF-14 | two identical pickups on separate turns | both batches retained |
| FF-15 | dismiss current feedback | no world/turn/context mutation; next queued batch appears |
| FF-16 | ordinary 4-second expiry | next batch advances; persistent context remains mounted |
| FF-17 | save/relaunch | no transient replay; current context rebuilds from active run |
| FF-18 | encounter/return transition | destination owns outcome; stale field event is not flashed behind it |
| FF-19 | 368×800 | both regions are complete; ordinary allocation is 25/75 unless measured evidence requires 50/50 |
| FF-20 | mounted-consumer regression | narratable committed batch is observable through the mounted World consumer; test cannot pass from an unused `eventLog` declaration |
| FF-21 | fire fail-closed | `wildfire` pressure or generic hazard alone produces no fire-cell Asset request |

### Control feedback

| ID | Fixture | Required result |
|---|---|---|
| CF-01 | center and four near-corner points of visible control | all invoke the same semantic control; no dead surface |
| CF-02 | touch-down without release | immediate pressed state only; no mutation, success or turn |
| CF-03 | accepted synchronous action | accepted then one committed outcome; one mutation |
| CF-04 | accepted asynchronous/in-flight action | whole control remains owned by attempt; duplicate taps rejected as busy |
| CF-05 | ten taps during one turn action | one attempt, one mutation, exact rules-owned turns, no hidden queue |
| CF-06 | stale state between accepted and commit | exact refusal; zero mutation/turn; retained remedy when known |
| CF-07 | known disabled action | complete label and reason; no misleading touch/success state |
| CF-08 | repeatable harvest/search after completion | second deliberate tap creates a new attempt only after first completion |
| CF-09 | D-pad activation | one release equals one step; no implicit hold repeat |
| CF-10 | tap-to-travel while busy | second route request refused; no replacement or concealed queue |
| CF-11 | map/Page canvas exception | correct semantic action without pretending each logical cell is an ordinary 44pt button |

### Site and hazard identity

| ID | Fixture | Required result |
|---|---|---|
| HI-01 | each nine live site IDs, disclosed | exact stable identity/category/state reaches Asset adapter |
| HI-02 | hidden site | no request and no feedback disclosure |
| HI-03 | search progress then relaunch | same placed instance and remaining turns; transient event does not replay |
| HI-04 | opened site | persisted `isLooted`; no false unopened state |
| HI-05 | Brood Warren guardian blocks interaction | refusal derives from actual enemy state; site art does not imply resolution |
| HI-06 | generic hazard, `the_tear`, `wildfire` pressure | three identities remain distinct; none aliases to another's art/mechanics |

## Dispatch and stop conditions

Engineering may begin F0/F1 after PM reconciliation. F1 is accepted only after the matrix passes on an
ordinary 368×800 phone. The repair must be installed whenever a new signed phone build is available under
the standing install policy.

Stop and return to Game Design if implementation would require:

- changing rules event order or turn costs;
- dropping or semantically merging authoritative events;
- inventing a fire placement/lifecycle/damage model;
- adding a new site or hazard identity;
- exposing hidden facts;
- choosing visual styling on Asset's behalf.

After F1 acceptance, the queued order remains World Splash, then the preserved dynamic-gear completion plan,
unless Aimee or PM redirects it.
