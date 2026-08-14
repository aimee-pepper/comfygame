# Playability Priority Sequence — historical phase plan

**Status:** archived capture-time ordering; not the current cross-lead execution queue  
**Current authority:** Aimee sets priority; live execution status is
`Sources/Content/Data/playability-roadmap.json`; exact install receipts own phone provenance  
**Captured:** 11 August 2026

> The prioritization principles below remain valid. Numbered phases and “now” statements preserve
> the plan as it existed when `ce9b1af` was protected and must not be dispatched as current work.

## Scheduling rule

A design audit does **not** enter Engineering's active queue merely because it is implementation-
ready. It lands in the numbered phase below and may be handed off as reference, explicitly marked
noninterrupting. Engineering pulls only from the current phase unless:

1. Aimee changes priority;
2. the active item is blocked and the next work does not obscure its acceptance evidence; or
3. a small correctness dependency must land first.

No new feature breadth enters Phases 0–4. `feature-completion-priority-audit-current.md` defines the
completion gate: `readyToTest` remains unfinished work. Tutorials are Phase 9, dead last.

### Playable-first promotion gate

The implementation queue follows this order unless Aimee explicitly changes it:

1. a blocker in Aimee's ordinary play loop: crash, data loss, inability to continue/fund/offload,
   missing required result or a control that cannot perform its primary action;
2. finish mechanics and ordinary player-facing interaction for a system already present in the game;
3. correct the ordinary phone layout/visual design when it makes that existing system confusing,
   list-like, unreadable or unpleasant to use;
4. balance and authored-content quality needed to make those finished systems play well together;
5. secondary device sizes, accessibility-size adaptations, localization, animation and edge-case
   hardening; and
6. tutorial expansion, dead last.

An accessibility, audit, fuzz, static-analysis or rare-layout failure may be recorded immediately,
but it **cannot promote itself** above unfinished gameplay or ordinary UI. Game Design may not label
such a finding P0/P1 merely because it is severe within its own test matrix. It enters active work
only when Aimee requests it, it also breaks her ordinary current play path, or the already-active
ordinary implementation can include the correction trivially without displacing scope or evidence.

Before sending Engineering or Asset any new implementation order, Game Design must state internally
and verify against the live roadmap:

- the exact current active item;
- the most recent Aimee instruction that authorizes its priority;
- the ordinary player-visible result it will produce; and
- which queued item it displaces, if any.

If those four facts are not available, the finding stays queued. A design audit may inform future
work but never acts as a dispatch order. Only Aimee can reorder across these tiers; Game Design may
sequence dependencies *inside* the active authorized outcome.

### Development-stage and rework gate

Before **any** queue change—even between two items in the same priority tier—Game Design must inspect
the current source, live roadmap and planned dependent work and answer:

1. **Are the foundations stable?** The mechanic, ownership/schema, transaction boundary and ordinary
   screen structure that this work depends on must already be settled or be part of the same active
   outcome.
2. **Will a known queued change invalidate it?** If planned mechanics, content scale, navigation,
   save migration, asset ownership or screen redesign would require this work to be substantially
   redone, it stays after that dependency.
3. **Does it produce a complete playable result now?** A checkpoint must shorten Aimee's ordinary
   play/test loop, not merely create scaffolding, a disabled replacement or evidence for a later
   system.
4. **Is any temporary work truly necessary?** Disposable scaffolding is allowed only when it is the
   smallest way to unblock the current authorized outcome, is clearly isolated, and does not replace
   functioning production behavior.
5. **Will its acceptance evidence remain valid?** Do not spend phone, visual or balance-review effort
   on a surface whose geometry, data model or rules are scheduled to change first.

The proposed change may enter the queue only when all five answers support doing it now. Otherwise,
record its dependency and leave it in place. The required handoff statement is: **stage fit, stable
dependencies, expected player-visible result, known rework risk, displaced item**. Game Design must
inspect rather than infer these facts, and Engineering/Asset should reject a handoff that omits them.

Examples of mistimed work include accessibility-size tuning before the ordinary screen redesign;
final balance before combat consumers/scaling are stable; final art before identity/asset contracts;
and production graph presentation before its ownership/purchase/consumer model can preserve working
progression. These are not banned tasks—they are sequenced after the work that would invalidate them.

### Current UI is provisional but must be playtest-quality — hard limit

Aimee expects **almost the entire application UI to change**. Until she settles the overall interface
direction, no current screen is presumed close to final. That does not mean bare or minimum UI: every
ordinary phone surface currently under active development should still feel good, look intentional,
play well and support direct comparison of layouts when Aimee finds that the current approach fails.
The boundary is:

- design and implement a coherent playtest-quality ordinary-phone experience for the prioritized
  mechanic, including meaningful layout alternatives when they answer an observed problem;
- keep rules, transactions, stable IDs, state machines and view models independent from replaceable
  screen composition;
- use a consistent intentional visual vocabulary now, while recognizing that containers, navigation
  and the broader design system may be replaced later;
- treat ordinary-phone captures as both gameplay and current visual/layout evidence, not as permanent
  final-art acceptance;
- do not commission accessibility-size variants, animation, final navigation, final spacing/type,
  decorative transitions, screen-wide responsive polish or exhaustive device matrices; and
- do revise list/grid/card/navigation/layout choices when Aimee observes that the current ordinary UI
  is unpleasant, repetitive, confusing or plays badly; iterative UI design is current game work.

Structural interaction that *is the mechanic*—the spatial writing page, world map, combat stage and
true combat-tree topology—deserves especially strong current visual and interaction design because it
directly determines play feel. Its present layout can be accepted for playtesting without being frozen
as final product UI. Aimee's explicit request may promote any observed ordinary-screen design problem;
that iteration is not premature edge-case hardening.

## Work-in-progress and visible-delivery rule

The project may have at most:

1. **one Engineering implementation slice** in progress;
2. **one phone acceptance checkpoint** waiting on Aimee; and
3. **one narrowly named Asset consumer** in progress, only when it directly enables the active
   implementation or acceptance checkpoint.

Game Design may triage new findings while those lanes are occupied, but may not turn later-system
audits into active Engineering or Asset work. A new design document is not progress against the
playable build unless it resolves a decision that blocks the active slice.

Every Engineering slice must end in one of four explicit states:

- **installed for acceptance** — signed phone build and exact player-visible test;
- **accepted** — Aimee confirms the behavior, or the named objective evidence passes;
- **rejected with one bounded correction** — the same slice stays active; or
- **blocked** — the missing authority or external requirement is surfaced immediately.

Source-green, pushed and `readyToTest` are intermediate states. They do not authorize starting a
large unrelated feature. When a phone test is protected, Engineering may prepare only the next
bounded checkpoint; it must not accumulate a hidden chain of source-only features.

At each regular check-in, report only:

1. what visibly changed in the build Aimee can use;
2. what is waiting to be installed or accepted;
3. the single implementation slice in progress; and
4. the next slice after acceptance.

Token or elapsed effort is not evidence of progress. The default measure is a shorter path through
the repeatable loop: create/load a save → write a world → explore/fight → return → understand the
result → sell/recycle/refine → afford and write the next world → report a defect.

> **Historical execution plan:** this document preserves the phase ordering discussed at its capture
> time, including references to the then-installed `ce9b1af`. It no longer owns “now,” current phone
> provenance, install order or active work. Use `Sources/Content/Data/playability-roadmap.json` for
> live scheduling and exact install receipts for device provenance. Do not periodically rewrite this
> history to resemble the current queue.

## Phase 0 — protected test at capture time

**Now**

1. Aimee completes the active fresh-save traveller/Essence test on installed `ce9b1af`.
2. Engineering may finish and push the already-started Essence Spring checkpoint in source, but
   does not replace the phone build during that test.
3. Asset remains idle unless current phone evidence contradicts accepted resource/terrain output.
4. Design triages incoming playtest findings; feature audits are documented into later phases only.

**Exit:** Aimee says the current run may be interrupted/replaced, and Engineering has a green bounded
Spring source checkpoint or has reported a concrete blocker.

## Phase 1 — the playtest-enabling acceptance chain

Run as separate, attributable device checkpoints where practical.
The compact execution script is `phase-1-phone-acceptance-card-current.md`.

### 1.1 Recycler and opening economy

- Install Noll/Recycler checkpoint `aaf6280` before combining it with unrelated new behavior.
- Fresh save proves Vance → Noll → Halloway tendency without violating full-signature/one-person
  world rules.
- Build the 15-Essence Recycler; recycle eligible gear, reject protected gear, cancel once, relaunch,
  and prove no duplication.
- Recheck next-bind Essence runway after Trading Post + Recycler.

### 1.2 Resource/terrain/UI corrections already built

- Verify six-across Storehouse resources and recognizable resource v0.6 graphics.
- Verify no false terrain sidewalls on material/color boundaries; genuine elevation may retain a
  restrained riser.
- Verify compact Party, accurate Library grouping, anchored item popovers, Look + fixed controls and
  the unclipped world map.
- Contradictory screenshots reopen only the exact failing consumer; do not restart broad Asset work.

### 1.3 Direct bug-report delivery

- Local capture/outbox/Share is already implemented and must remain honestly labelled.
- Select and configure one approved HTTPS relay destination and Keychain credential.
- Only a durable remote receipt changes **Unsent** to **Submitted**; Save/Done never does.
- This is the highest implementation priority after 1.1/1.2 because it improves every subsequent
  test cycle. If relay infrastructure needs Aimee's authorization, surface that single decision
  immediately rather than silently moving to another feature.

### 1.4 Save-slot acceptance

- Start New, Continue, Load, details/export and confirmed Delete on phone.
- Prove independent autosaves and lossless legacy adoption before relying on fresh-save comparisons.

### 1.5 Essence continuation and refining

- Complete the three-run Recommended Essence evidence, building toward ten.
- Install the separate Spring checkpoint: exact selected/all 2:1, practice-earned 3:1 and
  once-per-outcome Continuous settling.
- Fail immediately if reasonable exploration still cannot fund the next ordinary authored bind;
  refining skills do not excuse an acquisition deficit.

**Exit:** Aimee can start/replace saves, fund continued testing, offload items, read the world/UI and
send a bug package to the actual shared queue.

## Phase 2 — correctness before breadth

1. **Encounter/scaling acceptance first:** finish the two-/five-person × early/established ordinary
   and apex phone matrix and tune the existing system into its intended pressure bands.
2. **One return receipt:** consolidate portal/Waystone/collapse/defeat/abandon results without losing
   exact item/page/person identity.
3. **Failure retention correctness:** total-unit budgets independent of stack/bin shape.
4. **Combat affliction authority:** exact-combatant Burn/Poison/Dazzle/Bleed, Broad Antidote and
   Barbed Edge's one 3×3 Bleed.
5. **Combat-tree completion:** every one of the 72 accepted nodes must have a real consumer and
   migration/device proof; do not treat a graph-shaped screen over inert rules as completion.
6. **Apothecary reachability/cost correction:** Nessa build path, Lesser Salve, valid `fiber`, distinct
   Briar Oil and sustainable zero-Essence ordinary recipes.
7. **Anchorage/person-placement acceptance:** explicit settlement and one true placement per person.

**Exit:** return, loss, combat conditions, healing/crafting access, encounter pressure and assignment
cannot corrupt or misreport a test campaign.

## Phase 3 — finish identity and authored quality already in use

1. Finish recognizable item/character identity once Aimee freezes the immutable authored art
   registry; preserve existing generated fallbacks until then.
2. Accept world-color relative diversity on phone: similar inputs may look similar, opposed inputs
   must separate proportionally.
3. Review Isolde/Sabine authored text through the Atlas; promote only Aimee-selected units.

**Exit:** core progression choices work, their objects/people/worlds are recognizable, and known bad
prose is reviewed.

## Phase 4 — writing progression

1. Rough Charcoal → Brush → Fountain Pen tool progression.
2. Adjacent Brush-gated CMYK Ink Mixing using resource-derived bases; Ash ink leaves color open.
3. Compound Assembly and Chaining as sibling Penmanship capabilities.
4. Scoped Source→Focus / Symbol→Compound migration with seeded mechanical equivalence.
5. Compound hostility authority and retired Token/Quirk cleanup.

**Exit:** the central writing loop has honest tool, color, compound and vocabulary progression.

## Phase 5 — requested encounter agency

1. Nessa's Scent Mask after Apothecary acceptance.
2. Finish Quiet Step/awareness presentation and avoidance composition.
3. Validate deliberate-contact rules for apexes, active flora and ordinary animals.

**Exit:** players can invest in or prepare for avoiding animal encounters without trivializing
apexes or hiding world truth.

## Phase 6 — specialist station depth, serially completed

1. Channelworks restoration receipt, then Oda's schematic/Contact/Projection route; finish and
   accept it before the next specialist system.
2. Talin's typed armour-threshold gambit teaching.
3. Deep Works first slice and site-catalogue correctness; finish and accept it before breadth.
4. Remaining maker/research graph presentation reuse.

**Exit:** existing specialist promises are reachable, receipt-safe and mechanically distinct.

## Phase 7 — community and living worlds

1. Stable generated-person identity and arrival builds.
2. Tavern visitor pool/rotation and wants.
3. Menagerie Attend/taming.
4. Tamed-animal combat.
5. Predation, then optional group-motion tie-break after performance evidence.

**Exit:** generated people and animals persist safely before ambient ecosystem simulation expands.

## Phase 8 — realm/endgame depth

1. Anchored-realm renewable production and stable worker/source identities.
2. Instrumented three-route anchor balance receipts before numerical retuning.
3. Curio/identification depth and remaining late sites.
4. Great Work, Reality continuation/reset decision and Tam only after Aimee reviews the linked
   endgame packet.

**Exit:** long-campaign realm value and ending structure are proven without disposable-world grind.

## Phase 9 — tutorials, dead last

No tutorial-content expansion begins until Phases 1–8 are accepted or explicitly cut. A layout bug
caused by an existing tutorial remains an ordinary correctness defect; authoring more tutorial
content does not.

## Parking disposition for recent design audits

| Audit | Phase | Engineering priority now? |
|---|---:|---|
| Diary Talin/Oda rewards | 6 | No |
| Ashe site named fixture | 6 opportunistic test coverage | No |
| Animal combat | 7 | No |
| Tavern visitors | 7 | No |
| Vocabulary migration | 4 | No |
| Group motion | 7, after predation performance | No |
| Anchor balance receipts | 8 | No |
