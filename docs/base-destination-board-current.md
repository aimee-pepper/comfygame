# Base destination board — current design

**Status:** current destination-ID/order compatibility authority, but its four-tab board presentation and
damage lifecycle are superseded by `home-house-and-village-current.md`. Native routes may reuse this
catalogue beneath House/Village hotspots.
**Owner:** Game Design; Engineering owns responsive navigation/state; Aimee owns final station
silhouettes. AssetLab may use labelled functional placeholders for layout/conformance only.  
**Priority:** P1 spatial-language correction after current blocker checkpoints.

## Player outcome

Base reads as a compact place the player knows, not an ever-growing settings list. Opening verbs fit
without unnecessary scrolling; later buildings join one understandable district; a construction
site occupies the same destination position as the finished station it will become.

The board has four persistent tabs:

1. **Home** — the essential recurring campaign verbs.
2. **Make** — circulation, recovery, equipment and material transformation.
3. **Study** — records, analysis, writing craft and survey.
4. **Realms** — travel preparation, living-world care and anchored-world work.

These are navigation groups, not fictional zoning, progression tiers or restrictions. A station may
depend on another system without moving tabs. Do not infer membership from route name, keeper order,
`builtBy` or unlock timing.

## Complete station mapping

`sectionOrder` is unique within its section and is the only ordinary board-order authority.

The table below is the **visible destination** mapping. Native compatibility currently retains a
`party` station definition at Home order 2 so old route/content data decode, then
`BaseBoardRules.destinations` filters it before presentation. Therefore the visible Home orders have
a harmless compatibility gap: Firepit/Essence Spring/Workshop are currently encoded 3/4/5 while
presenting as the third/fourth/fifth tiles. Party still appears exactly once in the bottom utility
row. A later catalogue cleanup may remove/renumber that hidden row atomically, but no UI consumer may
render it or depend on contiguous integers.

| Section | Order | Stable station ID | Player-facing destination | Lifecycle note |
|---|---:|---|---|---|
| Home | 0 | `writing_desk` | Writing Desk | opening infrastructure |
| Home | 1 | `storehouse` | Storehouse | opening infrastructure |
| Home | 2 | `firepit` | Firepit → Tavern | opening place; later in-place upgrade |
| Home | 3 | `essence_spring` | Essence Spring | opening infrastructure |
| Home | 4 | `workshop` | Workshop | opening infrastructure |
| Make | 0 | `trading_post` | Trading Post | Vance; first intended found station |
| Make | 1 | `recycler` | Recycler | Noll; second intended found station |
| Make | 2 | `blacksmith` | Blacksmith | Halloway; third intended found station |
| Make | 3 | `apothecary` | Apothecary | Nessa integration remains separate |
| Make | 4 | `tannery` | Tannery | Corrin |
| Make | 5 | `bowyer` | Bowyer | Fen; physical ranged weapons |
| Make | 6 | `armoury` | Armoury | Bracken; advanced armour |
| Make | 7 | `weaponsmith` | Weaponsmith | Maud; advanced melee |
| Make | 8 | `distillery` | Distillery | Auber; essence cores |
| Make | 9 | `channelworks` | Channelworks | Oda; magic weapons |
| Study | 0 | `library` | Library | opening room; Lys later deepens it |
| Study | 1 | `constellation` | Constellation | opening Reality progression |
| Study | 2 | `bestiary` | Bestiary | opening creature record |
| Study | 3 | `survey_post` | Survey Post | Mara |
| Study | 4 | `reliquary` | Reliquary | Edren |
| Study | 5 | `scriptorium` | Scriptorium | Isolde |
| Realms | 0 | `wayfarers_table` | Wayfarer's Table | Sela; routes/provisions |
| Realms | 1 | `menagerie` | Menagerie | Sabine; animal care/assignment |
| Realms | 2 | `deep_works` | Deep Works | Grimmond; depth/sign work |
| Realms | 3 | `anchorage` | Anchorage | Tovin; realm portfolio |

Recycler, Menagerie and Deep Works are current design IDs even where the live station catalogue has
not added them yet. Adding them must use this mapping rather than creating another tied legacy order.

The opening economy sequence is deliberate and protected: whenever all three are known, **Trading
Post → Recycler → Blacksmith** is their visible order. This does not hard-gate a player who recruited
somebody else first.

## Responsive board

At ordinary 368-point portrait width:

- the top strip is one compact orientation/status row, not a title card: **Base** identity, the
  rules-owned purse totals that matter here, and one trailing utility menu for Settings/Testing;
- Settings, Testing, DEBUG and other app utilities never masquerade as village destinations;
- tabs remain fixed beneath that compact strip;
- use three equal destination columns with at least 44×44-point interactive ownership;
- tile height targets 104–120 points, with station silhouette, name (maximum two lines), current
  state badge and one attention marker;
- permanent blurbs do not consume every tile. VoiceOver and an optional info affordance expose the
  station's short purpose; tapping an available built place performs the primary navigation;
- do not shrink station names to preserve three columns and do not add chevrons/menu-row chrome.
  Switch to the two-column fallback before a two-line name or 44-point target would compress;
- Home's five places fit in two rows without scrolling. Study's six fit in two rows. Realms fits in
  two rows. Make may use four rows when the complete long-campaign catalogue exists; scrolling is
  then genuine collection growth rather than oversized cards.

At accessibility text sizes, reduce to two columns and permit scrolling. Do not shrink text or tap
targets to preserve three columns. Landscape/tablet may use four columns while retaining the same
section/order facts.

One compact persistent bottom action row remains outside all four tabs:

- **Party** — secondary/neutral action, opening party assembly and equipment;
- **Bind & Depart** — visually primary blue shortcut to Writing Desk's **The world** review. It
  commits nothing at Home; only the final action inside Writing Desk spends/consumes and creates a
  run.

They use ordinary 44-point-or-larger buttons sized to their labels and shared row, not full-width
screen-height cards. Party is a campaign utility, not a fictional building; it therefore no longer
occupies a Home destination tile. The player never hunts through a district to assemble the active
party or leave Base.

Contextual first-return/tutorial guidance overlays or anchors to its destination without entering
the board's height calculation. It cannot push Home's five tiles or the Party/Bind & Depart row
below the ordinary 368×800 frame. DEBUG reporter/harness controls clamp outside purse, tab, station
and departure ownership; they remain compile-gated and visually subordinate.

## Station states on one tile

One stable station ID occupies one board position through its lifecycle:

1. **Absent:** not legitimately known; no locked silhouette leaks it.
2. **Foundation:** keeper recruited and construction available; tile uses the authored foundation
   silhouette and a **Build** badge. Tap opens exact cost, first useful capability and confirmation.
3. **Built:** tap enters the station. Tier appears as a compact badge only when meaningful.
4. **Improved:** the same place gains authored functional additions; it does not become a replacement row.
5. **Attention:** persisted truthful construction/contribution/stock/waiting events overlay the current built
   state and clear under `home-house-and-village-current.md`.

The village is never damaged. Remove damaged/repair/rebuilding presentation. Anchored-realm dormancy remains
a separate realm lifecycle and must not be inferred as a village-building state.

Firepit→Tavern changes identity/state in the same Home tile. Library keeper attachment deepens the
same Study tile. Neither creates a duplicate destination.

Building sites therefore leave the separate full-width `buildingSites` list and join their eventual
section as foundation tiles. A newly available site may badge its tab and tile; it does not
automatically switch tabs, scroll the player or open a cost sheet.

## Tab behavior and persistence

- A fresh launch/campaign begins on Home.
- During one app session, returning from a station restores the selected tab and board position.
- Persisting the last tab is optional UI preference, not campaign state. If persisted, missing or
  empty sections fall back to Home safely.
- A tutorial/deep link may navigate directly to a known destination without first changing the
  player's stored tab preference. Back returns to the destination's section with its tile focused.
- Each non-Home tab is omitted only when it contains neither a known built station nor a legitimate
  foundation. In DEBUG complete-catalogue fixtures all four remain visible.
- Tab badges aggregate only legitimately known attention/foundation states and clear from their own
  underlying state, never from a separate manual unread counter.

## Content and code authority

The native catalogue now uses:

- `homeSection: home | make | study | realms`
- `sectionOrder: Int`, unique within `homeSection`

Missing `homeSection/sectionOrder` decodes through one closed stable-ID compatibility map. Current
JSON definitions author both fields explicitly, and catalogue validation rejects duplicate
`(section, order)` pairs, unknown sections and current definitions relying only on legacy
`sortOrder`. The compatibility map includes hidden Party at Home 2 and the planned Recycler,
Menagerie and Deep Works positions; this does not make absent planned stations known or visible.

Do **not** add a `campaignBand` merely to preserve today's duplicated numbers. There is no live
consumer proving those ties mean progression. Traveller `authoredOrder`, station lifecycle,
construction availability and board placement remain separate facts.

`stationsInOrder` becomes section-aware and deterministic for non-UI consumers, sorting by fixed
section order then `sectionOrder`, with stable ID only as diagnostic fallback for invalid legacy data.
No ordinary presentation may depend on JSON array/decode order.

## Art and disclosure boundary

Each tile uses the accepted authored station silhouette and lifecycle state from the place kit,
adapted to the current Base palette. Icons may remain an interim fallback, but section/order work
must not invent generic house art or delay functionality until every later station is illustrated.

The destination board can show:

- the identity and state of a legitimately known station;
- exact build readiness for an exposed foundation;
- truthful available-output attention.

It cannot reveal an unrecruited keeper, future building, unknown recipe, hidden traveller order or
undiscovered material route. “Make” is navigation language, not a promise that every output is known.

The current scenic implementation is bounded by `home-house-and-village-current.md`: the Binder House owns
the writing, study, workshop/storage and Party zones; Firepit and Essence Spring remain in Village. Scenic
hotspots and their image share one coordinate authority, with no unaccounted fill-cropping.

## Acceptance gates

1. On 368×800, fresh Home shows all five opening destinations, compact context, tabs and the
   Party/Bind & Depart bottom row without ordinary scrolling or clipping.
2. Trading Post, Recycler and Blacksmith appear in that order in Make under every unlock subset.
3. Every current/planned station resolves to exactly one section/order; no duplicate pair exists.
   Hidden Party compatibility is validated but excluded from the visible destination set.
4. JSON array shuffling leaves the board byte-for-byte/semantically ordered the same.
5. Recruit→foundation→build→tier/attention and Firepit→Tavern/Library keeper transitions preserve one
   stable tile and focus.
6. Unknown stations remain absent; tab badges cannot leak them.
7. Back navigation restores tab, scroll and accessibility focus; deep links land on the correct tile.
8. Large Text uses two columns without truncating names/actions; VoiceOver reads section, station,
   lifecycle, tier/attention and action in that order.
9. Grayscale/value distinguish known-buildable, built, improved and attention without color. No village
   damage/dormancy state exists.
10. Existing saves migrate without relocking stations or changing purchased tier/keeper/build state.
11. No tile uses text scaling or a chevron to preserve the grid; long/accessibility names trigger
    the two-column fallback and retain full labels.
12. First-return guidance and DEBUG overlays do not displace or cover context, tabs, any Home tile
    or either bottom action on the ordinary phone fixture.
13. Party exists exactly once as the persistent bottom utility; it is absent from every destination
    section. Settings/Testing/DEBUG likewise remain utilities rather than board tiles.

## Explicit non-goals

- no freeform village map or drag-to-place building system;
- no station relocation mechanic;
- no campaign gating based on tabs;
- no alphabetical auto-sort;
- no broad station-art expansion required before the navigation checkpoint;
- no redesign of the screens inside each destination.
