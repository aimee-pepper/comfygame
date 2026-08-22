# Cross-lead delivery contract — current

**Status:** current orchestration and handoff authority  
**Owner:** Game Design owns player promise and mechanics; Asset Lead owns visual solutions inside
that promise; Engineering Lead owns the native transaction and integration  
**Updated:** 22 August 2026

## Why this exists

The project has repeatedly treated a good-looking candidate, a green source checkpoint, an installed
build and a player-accepted result as if they were the same state. They are not. It has also allowed
visual mockups to invent mechanics that were never requested. This contract prevents both errors
without turning every feature into another audit project.

Use it only when a feature crosses leads or when materially different implementations are possible.
A one-line copy correction or isolated bug fix does not need a ceremonial packet.

## One feature, separate receipts

These are independent facts. Never infer one from another.

| Receipt | Exact meaning |
|---|---|
| **Design settled** | The player promise, legal actions, state ownership, non-goals and acceptance result are explicit. |
| **Asset candidate** | A reviewable visual solution exists in AssetLab or an authored-art source. It is not approved and does not authorize native work. |
| **Visual approved** | Aimee approved the named candidate/hash for the stated state families. Approval covers presentation only. |
| **Asset frozen** | The approved candidate has immutable source/export identity and can be compared without drift. |
| **Source-complete** | Native rules, persistence, interaction and focused tests implement the settled scope. This is still unfinished acceptance work. |
| **Integrated** | The exact source checkpoint is on the shared integration line; an isolated branch or AssetLab proof is not integration. |
| **Installed** | A signed build from a named checkpoint was installed. Repository HEAD is not device provenance. |
| **Playtest accepted** | Aimee completed the named ordinary-play acceptance or explicitly accepted the observed result. |

The machine roadmap may summarize one scheduling status, but its detail must name the latest receipt
and the missing next receipt. `readyToTest` means **awaiting acceptance**, not complete and not “test
all of these now.” Only `isPrimary` identifies the one current acceptance checkpoint.

## Minimum feature packet

Before Asset or Engineering starts a cross-lead feature, its current authority must answer these ten
questions. Existing system documents may supply the answers by reference.

1. **Player promise:** What can the player do or understand afterward that they cannot now?
2. **Stage fit:** Which progression band can first reach it, and why is it active now?
3. **Authoritative inputs:** Which saved or derived values are real? Which are deliberately unknown?
4. **Legal actions:** Exact player verbs, their targets, cost, time/turn effect and refusal behavior.
5. **State matrix:** Empty, ordinary, selected, unavailable, failure and result states that actually
   exist. Do not add states merely to fill a mockup.
6. **Transaction owner:** The one rules action that previews and commits; views do not recreate it.
7. **Visual/disclosure boundary:** What art must communicate, may suggest and must conceal.
8. **Persistence:** Stable identity, relaunch behavior, migration and idempotence requirements.
9. **Non-goals:** Plausible adjacent mechanics that are explicitly outside this checkpoint.
10. **Acceptance:** One ordinary-player route, exact build provenance and pass/fail observations.

If one of these answers would materially change the feature, Game Design resolves it before the
handoff. Engineering and Asset should reject a handoff that asks them to choose the game design.

## Dispatch evidence gate

Before Game Design assigns or reprioritizes work, it must inspect the current repository and record
the following in the assignment itself. Memory, an older chat receipt or a plausible roadmap status
is not sufficient evidence.

1. exact shared HEAD and the exact installed-device revision, when one exists;
2. current roadmap primary and why this assignment does or does not pre-empt it;
3. current owner and dirty-file boundary, including any overlap with another lead;
4. the latest direct Aimee decision that controls scope, permanence or priority, preserved without
   paraphrasing away a material distinction;
5. the exact player-visible result and the receipt that would prove it;
6. explicit exclusions, including nearby work that must not be inferred from the assignment.

If current evidence contradicts the proposed assignment, reconcile the contradiction before sending
the order. If a new interpretation would materially change scope, priority, permanence or architecture,
surface it as an inference rather than dispatching it as settled authority.

## Cost and scope-expansion circuit breaker

An approved feature does not automatically authorize an unbounded implementation mechanism. Stop and
surface the choice before continuing when a bounded task unexpectedly becomes any of the following:

- a new generator, runtime framework, persistence model or cross-screen architecture;
- hundreds of generated assets or combinations rather than a small directly reviewed family;
- a substantial implementation whose player-visible result is still temporary or replaceable;
- work that delays a currently untestable core route, despite not repairing that route;
- a proof system whose size or complexity exceeds the production consumer it is meant to unblock.

The escalation must state the player-visible benefit, why the expansion is necessary, the smallest
coherent alternative, what will be final versus temporary, and the acceptance evidence. Deterministic
generation, green tests or available compute do not by themselves justify the expansion.

## Asset permanence and replacement authority

Every Asset assignment and receipt classifies each output as exactly one of: **final production art**,
**accepted production candidate**, **temporary integration scaffold**, **test fixture**, or
**rejected/superseded**. Classification is per surface; one package may not imply that every contained
surface has the same permanence.

- Temporary art must remain replaceable through stable semantic keys and may not become a design
  constraint merely because Engineering integrated it.
- Final production art requires an explicit brief and visual acceptance at its actual phone scale.
- Asset failure may remove optional presentation, but may not erase canonical player-facing names,
  disable a legal gameplay action or make a core route unusable.
- Current Writing Desk truth is intentionally split: Aimee owns the final sigil drawings, so generated
  sigils are temporary integration scaffolding; the page parchment is final production art and must
  not be represented by placeholder geometry or a neutral coded substitute.

## Core-route reliability and acceptance

Campaign load, Writing, binding/departure, exploration, return and save continuity are stop-the-line
routes. A regression that makes one unusable pre-empts documentation, late-game expansion and unrelated
polish until the intended current implementation is repaired.

For a phone-critical route, build success and Simulator evidence are necessary but not sufficient.
Acceptance requires the exact signed installed revision to complete the named ordinary-player path.
Failure-state fixtures must also prove that optional visual content cannot destroy gameplay-owned
identity or legal actions. Rollback is not inferred from a regression report; repair the intended
current design unless Aimee explicitly authorizes rollback or the current architecture is proven
unsafe to retain.

### Phone update installation default

Once a signed update is verified phone-ready, install it in place promptly by default. An ongoing Aimee
test does not imply an installation hold, and no lead waits for that test to finish before installing the
available update. Preserve the existing app and campaign data: do not uninstall the app, reset it, delete
saves or substitute a clean install. Defer installation only when Aimee explicitly asks for a hold.

Installation does not by itself authorize launching the app. Do not auto-launch after installation unless
Aimee separately requests it or launch is already the next normal coordinated step in the requested work.
The installation receipt still names the exact revision; later acceptance names the exact installed
revision actually tested.

## Mockup behavior fence

An Asset mockup may rearrange, group, illustrate and visually prioritize only the data and actions in
the settled feature packet. Unless Game Design explicitly settles them first, it may not invent:

- currencies, health, ranks, resources, roles, route graphs or risk ratings;
- actions, confirmations, tabs, filters, transactions or navigation destinations;
- additional selection steps, automatic commits or long-press-only essential behavior;
- remote knowledge, forecasts or exact values that the player has not earned;
- station functions implied by a room, prop, label or attractive empty space.

Fixture content must be marked `fixture`, `placeholder` or `derived from native authority`. A visual
approval freezes appearance; it does not make placeholder behavior canonical.

Engineering must compare a native candidate against both the frozen visual and the feature packet.
Matching pixels while changing the interaction is a failure. Matching behavior while discarding the
approved hierarchy is also a failure.

All asset candidates also obey `asset-production-output-contract-current.md`. HTML/CSS may host review
chrome, but production art is a lossless pixel sprite/scene/modular kit with task-appropriate native
dimensions and a manifest. Deterministic placeholder geometry is still placeholder art and cannot be
promoted merely because its export is reproducible.

## Current early-game ambiguity resolutions

These decisions govern the current Campaign → Home → Writing → World → Return chain.

### Campaigns

- Loading completes before the Campaigns screen owns interaction.
- The shelf is data-driven and uses only real slot metadata: name, validity/version, last-played
  context and existing progression summary. No invented health or “book fullness” score.
- Tapping a campaign selects it. An explicit **Continue _name_** action loads the selected campaign;
  tapping a card never silently switches saves.
- The selected card exposes a visible Details control. Export and confirmed Delete live in Details;
  no essential action is long-press-only.
- **New Game** is a peer action and always creates a separate slot. It never reuses a selected slot.
- A future/incompatible campaign remains visible and exportable but cannot be loaded or overwritten.
- Non-goals: difficulty selection, cloud accounts, health metadata and a second confirmation page
  before every healthy load.

### Home and departure

- Home opens on the Binder House/yard defined by `home-house-and-village-current.md`: Writing Desk,
  Library, Party and yard Essence Spring are the settled anchors; left/right/down lead to Commerce Row,
  Makers' Row and The Commons. Storehouse and Firepit are Commons buildings. Workshop is being removed and
  Constellation remains under explicit role review; neither may be invented from an older five-tile plan.
- Home's departure shortcut opens Writing Desk directly to **The world** review. It does not spend
  Essence, consume a collected World Page or create a run.
- The only final **Bind & Depart** commit is inside Writing Desk after a fresh rules-owned preview.
  Refusal remains on that screen with the exact current reason.
- The Wayfarer's Table remains the passive shared field workspace defined by
  `wayfarers-table-flora-recognition-current.md`. It has no world-route graph, party planner,
  provisions shop or departure transaction.

### Writing Desk

- The player-facing roots are **Write**, **Pages** and **The world**. Pages contains Collected and
  Templates; Templates are only player-authored drafts.
- The spatial 6×6 page remains the hero. A visual treatment may not turn sigil placement into a
  linear form or make position semantically meaningful.
- The world review may display only values from the current projection authority. Estimated ranges
  must read as estimates; undefined marks may not leak resolved meaning.
- Selecting, viewing or previewing a collected page never consumes it. Its exact instance consumes
  atomically only when the bind succeeds.
- Non-goals: automatic “best” layout, template-generated collected pages, invented harvest
  guarantees and navigation that bypasses the final review.

### World visibility and memory

| State | Terrain | Contents | Persistence/minimap |
|---|---|---|---|
| **Hidden** | Opaque black; no tile-art request and no hidden-neighbour sampling | None | No reveal and no POI |
| **Current fringe** | Transient terrain silhouette/colour only; atmosphere may dim or blur it | None | Never writes exploration or minimap |
| **Current full** | Full terrain and truthful current effects | Currently visible contents, subject to crypsis | Writes explored terrain and eligible discovered facts |
| **Remembered** | Previously explored terrain, visually subordinate to current full sight | Only already-discovered stationary content; never a current enemy | May remain on the explored minimap; creates no new discovery |

Illumination and obscuring atmosphere change these disclosure states. Fog is not a decorative tint
over hidden content. A remote apex, traveller, resource, page, site or portal can never reveal itself
by affecting tile art, adjacency, minimap or layout before discovery.

### Terrain edges and elevation

- A **material boundary** is two tiles at equal elevation with different ground or colour. It is
  flat and never produces a riser, wall or dark vertical band.
- A **genuine elevation edge** is a real height difference. It may use a restrained,
  material-matched southern riser or contour, but must still read as a top-down surface.
- A **fog boundary** is disclosure, not geometry. Hidden neighbours cannot contribute their ground,
  colour or elevation to a visible tile.
- A **map boundary** cannot clip a bottom row or fabricate a sidewall. Transparent lifted-sprite
  padding composites over the game-owned terrain/fog field.
- The acceptance vocabulary in `resource-sidewall-phone-acceptance-current.md` is canonical.

## Package and checkpoint rules

- A package spanning several screens is not `integrationReady` as a whole unless each screen has a
  settled behavior fence and an approved/frozen visual. Track each screen separately.
- A completed isolated branch is protected work, not the shared source of truth. Reconcile it before
  starting another overlapping native slice.
- One Engineering implementation slice, one Asset consumer and one phone acceptance checkpoint may
  be active. Asset may be idle.
- When a candidate is rejected, correct the same bounded feature. Do not use the rejection as an
  excuse to start an adjacent system.
- Every check-in names: visible installed change; waiting acceptance; active source slice; exact next
  slice after acceptance. Test counts and documents are supporting evidence, not the result.

## Proactive lead reporting

Asset and Engineering Leads report directly to the current Game Design/Orchestrator task without waiting
for Aimee to relay the result or for Game Design to poll them.

- Report immediately when a bounded task becomes source-complete, integrated, installed, visually rejected,
  blocked or abandoned, before beginning a different task.
- Name the exact boundary, commit/hash or uncommitted paths, automated evidence, visual/player-visible
  result, remaining acceptance gap, any decision needed and the next safe action.
- A green test report may not say “complete” when visual review, native integration, installation or playtest
  acceptance is still missing; name the exact receipt achieved.
- A lead who discovers that current repository status conflicts with an assignment stops before editing and
  reports the conflict. They do not silently follow a stale chat instruction.
- Routine in-progress narration is optional. Completion/blocker reporting is mandatory and should not
  require a reminder.
