# Binder House and village districts — current

**Status:** Game Design implementation authority for the House/district topology. The earlier six-hotspot
destination list is temporarily narrowed by `workshop-constellation-role-audit-current.md`: Workshop and
Constellation are not final interactive hotspots until Aimee chooses their disposition. This document replaces the opening spatial model in
`starting-town-band1-integration-current.md` and the Home-tab presentation in
`base-destination-board-current.md`. It does not change the rules or internal routes of the destinations
named here.
**Priority:** opening-campaign spatial presentation after the first-three-world survival and field-cue
baseline; before adding more late-game station screens.
**Owners:** Game Design owns rooms, destinations, lifecycle and attention semantics; Asset Design owns the
cutaway/building/sign grammar; Engineering owns route adapters, persisted event receipts and measured phone
layout; Aimee owns final visual acceptance.
**Updated:** 21 August 2026

## Product outcome

Home is **the Binder's house and yard**, with directional exits into three parts of a village growing around
it. The player should recognize where they write, study, make basic preparations and assemble a party without
interpreting a categorized list of backend stations. The Storehouse is a separate central village building
that supplies the whole town rather than a cupboard inside the house.

This is a spatial navigation surface, not a walking simulation. It adds no avatar locomotion, clock,
upkeep, visitors wandering between rooms or decorative chores.

## Root information architecture

The Base root is always the **Binder House** screen. It is not a tile inside a separate all-village screen.
From the house, three spatial arrows open fixed village-district screens:

- **left — Commerce Row:** Trading Post, Recycler and future genuinely commercial/service destinations;
- **right — Makers' Row:** Blacksmith and the reachable crafting specialists;
- **down — The Commons:** Storehouse, Firepit and noncommercial/noncraft community or fieldwork places.

**The Commons** is the current recommended district name; it is player-facing and may be renamed later
without changing the stable district ID `commons`. Do not call it “Other,” “More” or “The Rest.”

Each district has one obvious **Home** arrow that returns to the Binder House. Device Back does the same.
District-to-district shortcuts may be added only if their visible spatial direction is consistent; no place
may require navigating a hidden category stack.

Do not keep **Home / Make / Study / Realms** as equally weighted category tabs. Their routes continue to
exist behind spatial hotspots and destination-local screens. Anchored Realms remain a later dedicated
surface reached from an appropriate Commons destination; they are not painted into the opening house.

Persistent utilities:

- the floating bug-report control remains global;
- **Prepare a world** opens Writing Desk → The world and commits nothing;
- the actual bind transaction remains only inside the Writing Desk;
- Settings remains ordinary app navigation, not a room or village building.

## House cutaway

### Camera and layout

Use one fixed oblique cutaway/dollhouse illustration plus a narrow visible yard: the exterior wall facing the
player is removed and the functional zones are visible together. This is not the straight top-down
explorable-world camera.
Hotspot geometry and art share the same normalized coordinate file and aspect fit. Cropped
`scaledToFill` art over uncropped coordinates is prohibited.

On a 368×800 ordinary phone, the full house/yard, three direction arrows and persistent preparation affordances
must fit without vertical scrolling. Derive the art height from the safe region actually remaining after
the navigation chrome; use `scaledToFit`. If the measured region is exceptionally short, use a compact
room grid plus yard strip made from the same zones rather than clipping or shrinking tap targets below 44×44
points.

### Current settled zones and hotspots

| Zone | Visual anchors | Exact destinations/actions |
|---|---|---|
| Writing study | Writing Desk, paper, writing tools | **Writing Desk** |
| Library/study | shelves; optional removable star-chart dressing | **Library** |
| Work area | optional removable workbench dressing | no settled standalone destination while Workshop is under review |
| Common/planning room | table, chairs/party tokens | **Party** |
| Yard | spring basin and restrained runoff/growth | **Essence Spring** |

**Bestiary is inside the Library** as its own shelf, governed by `library-shelves-current.md`; it is not a
separate house hotspot. The Constellation and Workshop implementations remain preserved, but their current
single-star/catch-all roles do not justify final House hotspots without Aimee's decision. Asset work may
reserve removable decorative space and must not label or wire either. If one remains after review, this
table and the final hotspot manifest are revised before native implementation.

The house contains no Storehouse, Firepit, Trading Post, Recycler, Blacksmith or recruit station. The Essence
Spring is outside in the house's visible yard, never turned into a household sink. Storehouse and Firepit
belong in The Commons; commercial and craft places belong in their named districts.

### House change over time

The opening house may gain restrained persistent detail when its real systems improve: more bound books,
a better writing-tool rack, upgraded owned-tool fixtures or fuller specimen storage. These are visual
reflections of existing receipts. They are not separate construction projects and grant no extra bonuses.

## Village districts

### Opening geography

- Binder House screen: house interior plus yard Essence Spring and three district arrows;
- Commerce Row: no invented shop; Trading Post appears first, Recycler second, when real rules permit;
- Makers' Row: Blacksmith is the first reachable maker; later craft buildings appear only with their real
  owners/construction;
- The Commons: Storehouse and Firepit are visible opening community buildings.

The Binder House does not appear again as a building tile inside any district. Recruit-enabled places appear
only when their real construction/availability rules permit them.

### Place lifecycle

Every village destination uses these states only:

1. **Unknown/absent** — nothing on the board leaks the future place.
2. **Known buildable** — a foundation/plot and sign identify the promised function and exact cost/status.
3. **Built** — complete functional structure.
4. **Improved** — the same structure with one or more authored additions; never a replacement menu card.
5. **Attention** — a temporary overlay on its current built/improved state, not a construction state.

The town is safe and **will never be damaged**. There is no damaged, ruined, broken, repair, defence or
rebuilding lifecycle for the Binder House or any village station. Remove those states from current native
contracts and do not reserve art/engineering capacity for them.

### Building identity and signs

Silhouette and functional fixtures remain the first identity: forge/chimney, merchant awning, sorting
machinery, greenhouse, towers, pens, vats and other authored forms. Because the complete village contains
many unfamiliar specialist places, every buildable/built station also receives a standardized sign:

- mounted on the façade or immediately beside the entrance;
- one stable functional pictogram plus the short station name;
- legible at the village camera without opening detail;
- included in the destination's tap target;
- redundant with, not a substitute for, the building silhouette;
- never an invented mechanic (a route-map sign cannot make Wayfarer's Table a route planner).

For dense later districts, one district may use fixed sub-areas with landmarks. Do not shrink every building
into illegibility, create a free-panning town, or return to a single vertically scrolling station list.

## Attention and “something changed” receipt

### Valid attention reasons

A place glows only for one or more unchecked truthful events:

- construction completed;
- a contribution/recipe/action became newly available;
- merchant stock refreshed;
- an item or recovery is waiting at that destination.

Do not glow for a permanently available action, affordable purchase, unspent currency, routine crafting,
character idleness or decorative activity.

### Persistence model

Each destination stores a monotonic presentation-event receipt, not a fragile Boolean:

- stable `eventID`;
- destination ID;
- reason enum;
- source outcome/campaign receipt when applicable;
- created sequence;
- checked sequence or `nil`.

Repeated refresh/construction callbacks with the same stable event ID remain one event across relaunch.
Several unchecked reasons create one visible glow and a compact reason count/detail, not several badges.

### Clear behavior

- Opening a destination marks construction, contribution and stock events for that destination checked
  once the destination's real content has rendered.
- A waiting-item/recovery event clears when the player opens the exact Waiting/Recovery view and sees the
  object; claiming it is not required.
- Merely showing the village, hovering/touching the sign, switching scenes or opening an unrelated tab does
  not clear anything.
- Events remain checked after relaunch. A later new event may glow again.

### Visual grammar

Use a restrained warm-gold rim/light on the building and its sign, with a slow low-amplitude pulse. It may
not use the red danger grammar, obscure the building identity or make the whole village flash. Shape/value
must remain apparent without color. Once all current events are checked, the place returns immediately to
its ordinary current lifecycle state.

## Route contract

Every hotspot maps directly to one existing stable destination ID. The illustration owns no economy or
availability rule. A rules-owned adapter supplies:

- destination ID;
- lifecycle state;
- attention reasons/count;
- short truthful label;
- enabled/disabled status and exact blocker;
- normalized hotspot rectangle/polygon;
- visual identity key.

Tapping an enabled hotspot navigates once. Tapping a disabled known-buildable plot opens its construction
detail; it does not silently fail. Hidden destinations have no hotspot or accessibility element.

Back from a house destination returns to Binder House at the same focus state. Back from a district
destination returns to its originating district; that district's Home arrow or device Back returns to Binder
House. Diary deep-links are governed by the Party/Library contract and return to their originating character.

## Asset Design packet

Asset Design must prove, before native consumption:

1. the ordinary-phone house/yard cutaway with the four settled hotspots above and three district arrows;
2. a collision overlay showing 44×44 minimum targets and no overlap;
3. color and grayscale/value versions;
4. opening Commerce Row, Makers' Row and Commons scenes with no duplicate House tile;
5. one station in known-buildable, built, improved and attention states—no damaged state;
6. a six-building density row proving accepted station silhouettes remain distinct before labels without
   assigning unreached stations to final districts;
7. standardized sign treatment on one obvious and two obscure specialist stations;
8. attention glow on dark/light adjacent backgrounds, still identifiable with motion disabled.

The proof cannot invent tabs, verbs, route graphs, supplies, risk ratings or construction states to fill
space. Any visible value/action must exist in the game-owned adapter.

## Engineering checkpoint order

1. After the Workshop/Constellation decision, freeze normalized Binder-House/district metadata and the
   stable hotspot-to-destination map; no native visual replacement before that decision.
2. Add presentation-event receipts, idempotent creation/clear rules and migration defaults; expose a DEBUG
   injector for the four exact reasons.
3. Integrate House cutaway behind a DEBUG route using the existing destination navigation; verify no route
   duplicates or transactions occur.
4. Promote Binder House as Base root, retaining a reversible fallback to the current board until ordinary-phone
   acceptance.
5. Integrate Commerce Row, Makers' Row and The Commons with the exact five lifecycle/attention states.
6. Add recruit-station placements in actual campaign order only as each station becomes reachable; do not
   batch-render unimplemented late-game stations into the live village.
7. Remove native damaged/dormant town presentation and its unreachable assets/tests. This is a UI/state
   removal only; do not delete historical decision records.

## Acceptance

1. Fresh launch, load and expedition return land on the full unclipped Binder House/yard scene.
2. All accepted house/yard hotspots and three arrows route correctly; no generic Study or Make screen is
   required to find them. Workshop/Constellation are absent unless the role decision explicitly retains one.
3. Party management, Prepare a world and all three districts are reachable without scrolling on 368×800.
4. Essence Spring is in the house yard; Storehouse and Firepit are in The Commons.
5. Unknown future stations leak neither name nor silhouette; known buildable stations truthfully explain
   construction.
6. Each attention reason survives relaunch, clears only on the exact inspection rule and can recur for a
   later distinct event.
7. A station sign improves recognition without being the only distinction between adjacent buildings.
8. No town damage, repair or rebuilding UI appears under any campaign outcome.
9. Voice/touch order follows visible room/scene order; this is ordinary structural correctness, not a new
   broad accessibility project.
10. Physical-phone playtest confirms the House/district route feels like a place rather than a menu and no
    real opening verb became harder to find.

## Explicit exclusions

- no town damage or defence;
- no walking avatar or interior navigation simulation;
- no day/night schedule, upkeep or generated errands;
- no decorative NPC routines;
- no late-game districts before their campaign systems are reachable;
- no Anchored Realm management folded into the house;
- no new station mechanics inferred from AssetLab imagery.
