# Binder House and village — current

**Status:** Game Design implementation authority; replaces the opening spatial model in
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

Home should first read as **the Binder's house**, then as a village growing around it. The player should
recognize where they write, study, store things, make basic preparations and assemble a party without
interpreting a categorized list of backend stations.

This is a spatial navigation surface, not a walking simulation. It adds no avatar locomotion, clock,
upkeep, visitors wandering between rooms or decorative chores.

## Root information architecture

The Base root has two scene selectors:

1. **House** — default after launch, load and return.
2. **Village** — exterior community and recruit-enabled places.

Do not keep **Home / Make / Study / Realms** as four equally weighted category tabs on the root. Their
routes continue to exist behind spatial hotspots and destination-local screens. Anchored Realms remain a
later dedicated surface reached from an appropriate village destination; they are not painted into the
opening house.

Persistent utilities:

- the floating bug-report control remains global;
- **Prepare a world** opens Writing Desk → The world and commits nothing;
- the actual bind transaction remains only inside the Writing Desk;
- Settings remains ordinary app navigation, not a room or village building.

## House cutaway

### Camera and layout

Use one fixed oblique cutaway/dollhouse illustration: the exterior wall facing the player is removed and
the four functional zones are visible together. This is not the straight top-down explorable-world camera.
Hotspot geometry and art share the same normalized coordinate file and aspect fit. Cropped
`scaledToFill` art over uncropped coordinates is prohibited.

On a 368×800 ordinary phone, the full house, scene selector and persistent preparation/party affordances
must fit without vertical scrolling. Derive the art height from the safe region actually remaining after
the navigation chrome; use `scaledToFit`. If the measured region is exceptionally short, use a compact
two-by-two room grid made from the same four zones rather than clipping or shrinking tap targets below
44×44 points.

### Exact zones and hotspots

| Zone | Visual anchors | Exact destinations/actions |
|---|---|---|
| Writing study | Writing Desk, paper, writing tools | **Writing Desk** |
| Library/study | shelves, star chart, specimen cabinet | **Library**, **Constellation**, **Bestiary** as three distinct hotspots |
| Workshop/store room | workbench, tools, shelves/chest | **Workshop**, **Storehouse** as two distinct hotspots |
| Common/planning room | table, chairs/party tokens | **Party** |

The Library, Constellation and Bestiary may share a room but never share one generic “Study” destination.
Workshop and Storehouse likewise remain distinct verbs. The room label may support orientation; the actual
hotspot label and silhouette must identify the destination.

The house contains no Firepit, Essence Spring, Trading Post, Recycler, Blacksmith or recruit station. Those
are village places. Do not distort the fiction by turning an outdoor spring into a household sink or a
community fire into a stove merely to preserve the old five-tile Home set.

### House change over time

The opening house may gain restrained persistent detail when its real systems improve: more bound books,
a better writing-tool rack, upgraded workshop fixtures or fuller specimen storage. These are visual
reflections of existing receipts. They are not separate construction projects and grant no extra bonuses.

## Village exterior

### Opening places

The opening village scene contains exactly:

- the **Binder House** as the stable return landmark and route back to House;
- **Firepit**;
- **Essence Spring**.

Recruit-enabled places appear only when their real construction/availability rules permit them. The
opening sequence remains Trading Post, Recycler, then Blacksmith under its separate campaign authority.

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

For dense later villages, spatial districts may be paged with fixed landmarks. Do not shrink every
building into illegibility, create a free-panning town, or return to a single vertically scrolling station
list.

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

Back from a house destination returns to House at the same scroll/focus state. Back from a village
destination returns to Village. Diary deep-links are governed by the Party/Library contract and return to
their originating character.

## Asset Design packet

Asset Design must prove, before native consumption:

1. the ordinary-phone house cutaway with all seven exact hotspots above;
2. a collision overlay showing 44×44 minimum targets and no overlap;
3. color and grayscale/value versions;
4. Village opening scene with House, Firepit and Essence Spring;
5. one station in known-buildable, built, improved and attention states—no damaged state;
6. a six-building identity row proving silhouettes remain distinct before labels;
7. standardized sign treatment on one obvious and two obscure specialist stations;
8. attention glow on dark/light adjacent backgrounds, still identifiable with motion disabled.

The proof cannot invent tabs, verbs, route graphs, supplies, risk ratings or construction states to fill
space. Any visible value/action must exist in the game-owned adapter.

## Engineering checkpoint order

1. Freeze the normalized House/Village scene metadata schema and stable hotspot-to-destination map; no
   native visual replacement yet.
2. Add presentation-event receipts, idempotent creation/clear rules and migration defaults; expose a DEBUG
   injector for the four exact reasons.
3. Integrate House cutaway behind a DEBUG route using the existing destination navigation; verify no route
   duplicates or transactions occur.
4. Promote House as Base root, retaining a reversible fallback to the current board until ordinary-phone
   acceptance.
5. Integrate Village opening scene and the exact five lifecycle/attention states.
6. Add recruit-station placements in actual campaign order only as each station becomes reachable; do not
   batch-render unimplemented late-game stations into the live village.
7. Remove native damaged/dormant town presentation and its unreachable assets/tests. This is a UI/state
   removal only; do not delete historical decision records.

## Acceptance

1. Fresh launch, load and expedition return land on the full unclipped House scene.
2. All seven house hotspots route to the correct existing destinations; no generic Study or Make screen is
   required to find them.
3. Party management and Prepare a world are reachable without scrolling on 368×800.
4. Firepit and Essence Spring exist in Village, not the house.
5. Unknown future stations leak neither name nor silhouette; known buildable stations truthfully explain
   construction.
6. Each attention reason survives relaunch, clears only on the exact inspection rule and can recur for a
   later distinct event.
7. A station sign improves recognition without being the only distinction between adjacent buildings.
8. No town damage, repair or rebuilding UI appears under any campaign outcome.
9. Voice/touch order follows visible room/scene order; this is ordinary structural correctness, not a new
   broad accessibility project.
10. Physical-phone playtest confirms the Base feels like a house/community rather than a menu and that no
    real opening verb became harder to find.

## Explicit exclusions

- no town damage or defence;
- no walking avatar or interior navigation simulation;
- no day/night schedule, upkeep or generated errands;
- no decorative NPC routines;
- no late-game districts before their campaign systems are reachable;
- no Anchored Realm management folded into the house;
- no new station mechanics inferred from AssetLab imagery.
