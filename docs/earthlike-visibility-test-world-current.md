# Earth-like visibility test world — current

**Status:** implementation-ready DEBUG testing authority; not a collectible World Page, campaign reward or
fourth starter world.
**Owner:** Settings → Testing, using the live World renderer/rules through an isolated test-session state.
**Roadmap:** Band 1.7d; non-preemptive behind the ordinary World presentation checkpoints.
**Updated:** 21 August 2026.

## Purpose

Aimee needs to compare ordinary Earth-like visibility against controlled atmosphere variants on the phone
without spending Essence, hunting a compatible seed, changing a campaign or repeatedly exploring an unknown
map. This tool answers that one testing need. It is not a general free-world sandbox.

Player-facing entry:

> **Visibility World**
> Compare the same small landscape under different light and air. Testing sessions give no rewards and do
> not change this save.

## Access and state boundary

- DEBUG builds only: Settings → Testing → World presentation → Visibility World.
- It does not appear at the Writing Desk, in Collected Pages, Templates, Library, History or ordinary saves.
- Entry costs zero Essence and has no use limit.
- The session uses `DebugVisibilityWorldState`, separate from `GameState`, Base, Reality and expedition
  outcomes. It may serialize only to DEBUG testing storage so a renderer crash/relaunch can reproduce the
  test. Release decode ignores it.
- Entering snapshots the display/testing toggles needed by the live World screen, but never copies mutable
  campaign party, inventory, pages, traveller progress or resource reserves into the session.
- Leaving or choosing **Reset test** discards the session. No Return recap is created.

Every screen carries the persistent header:

> **TESTING WORLD · rewards, discoveries and campaign changes are disabled**

## One exact comparison map

All profiles use fixture ID `earth_visibility_fixture_v1` and seed `0x45415254484C4947` (`EARTHLIG`). The
fixture is 15×15 and must contain, at stable coordinates:

- entry portal and party start near the south edge;
- one reachable ordinary soil route with a corner and a narrow passage;
- one shallow-water shore and connected deep-water patch;
- one mud strip, one rubble patch, one low-growth patch and one high-growth patch;
- elevations 0, 1 and 2 with at least one LOS-blocking relationship;
- one cracked-but-standing tile and one impassable chasm;
- three ordinary neutral flora silhouettes: one beside the route, one behind growth and one across water;
- one neutral creature silhouette that does not initiate contact;
- one disclosed site marker and one Raw Essence node solely to check visibility/disclosure rendering.

Those objects are inert fixtures. The creature cannot aggro or award Bestiary knowledge. The site cannot be
searched. The resource cannot be harvested. Use/Look may explain **Testing fixture — not collectible** and
spend no turn. The entry portal's action is **Leave test**, not Return Home with a haul.

The map must not use the ordinary generator and then delete rewards afterward. A frozen purpose-built fixture
prevents generator changes from invalidating visual comparisons or accidentally leaking a traveller/page.

## Selectable profiles

The profile picker is available before entry and from a small anchored **Conditions** control in the test.
Switching profile does not move the party, reroll the map, change fog memory or spend a turn.

| Stable profile | Illumination | Air/particles | Visibility ownership |
|---|---|---|---|
| `clear_day` | ordinary daylight | clear | baseline current full radius and fringe |
| `dim_overcast` | low, not pitch black | clear | illumination contraction only |
| `pitch_black` | pitch black | clear | one-adjacent full visibility, no fringe |
| `rain` | ordinary daylight | rain | rain presentation; radius changes only if the live visibility authority explicitly owns one |
| `snow` | ordinary daylight | snow | snow presentation; same no-invented-radius rule |
| `fog` | ordinary daylight | fog | use the typed fog-density rule once it exists; until then label **visual only** rather than borrowing smoke |
| `smoke` | ordinary daylight | explicit smoke density 70 | smoke contraction/opacity/blur from the live authority |
| `airborne_ash` | ordinary daylight | explicit airborne-ash density 70 | ash contraction/opacity/blur from the live authority |

Rain, snow and fog never inherit smoke's numbers merely because all three obscure a view. If their typed live
visibility consumer is absent, the test still renders the atmosphere and truthfully labels the current
profile **Visual only · visibility rule not implemented**.

## Fog, movement and party safety

- Starting a new test resets persistent fixture reveal to the entry-radius result for the selected profile.
- Switching conditions preserves the fixture's already-revealed memory and recomputes current full/fringe
  visibility only. This makes memory-versus-current-vision comparison possible.
- **Reset reveal** returns the same session to entry and clears its reveal memory without rerolling.
- Movement uses normal passability, turn cost, Look and adjacent-consequence cues. It increments a test-only
  turn counter.
- Terrain/flora harm may animate and write test-only event copy, but test HP is a disposable fixed 30/30 and
  cannot fall below 1. No injuries, XP, conditions, item use or campaign stats persist.
- God mode is irrelevant inside this fixture; the test's nonlethal boundary is always on and clearly stated.

## UI

The test entry shows one compact profile grid, **Enter test**, and **Reset test**. The live World screen is the
ordinary phone composition—not a special expanded map—plus:

- persistent Testing header;
- anchored **Conditions** button;
- compact current profile label;
- test-only **Reset reveal** and **Leave test** actions inside the Conditions popover.

Tutorial overlays never appear. Debug controls may not resize the map or fixed field controls.

## Suppressed receipts

The following must remain byte-for-byte unchanged across entry, movement, profile switching, relaunch and
exit: Gold Coins; Raw/refined Essence; Motes; World/Creature resources; inventory and Field Kit; equipment;
XP/levels; diary/world pages; known/encountered runes; Bestiary; travellers; stations; world history;
expedition outcomes; pity/near-miss counters; Trading Post refresh; Recycler; achievements/telemetry used for
campaign balancing.

Only DEBUG testing history may record: fixture version, selected profile, test turn count, current point and
test reveal bits. Exported bug reports may include those fields with an explicit `debugVisibilityWorld`
source tag.

## Acceptance

1. Twenty repeated entries cost nothing and change no campaign byte covered by the suppression list.
2. Every profile renders the same fixture/objects/coordinates and switching never rerolls or moves anything.
3. Clear → dim → pitch-black current visibility contracts according to the live authority; smoke/ash use
   their exact typed density; unimplemented rain/snow/fog rules say Visual only.
4. Revealed-memory versus current full/fringe visibility remains truthful through profile switch and relaunch.
5. Inert creature/site/resource cannot aggro, teach, award, collect or enter any outcome receipt.
6. Movement/passability/Look/cues use live World behavior while test HP never falls below 1 or persists.
7. Ordinary phone map/control layout is unchanged and the Testing header/Conditions popover do not deform it.
8. Release build has no route to the tool and tolerant decode ignores DEBUG session data.
