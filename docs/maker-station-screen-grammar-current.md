# Maker-station screen grammar — current design

**Status:** implementation-ready shared presentation contract; mechanical recipes and station
ownership remain governed by their system documents.  
**Owner:** Game Design; Engineering owns reusable native components; Aimee owns final family/item
glyph art. AssetLab may use labelled functional placeholders for layout/conformance only.  
**First implementation:** Blacksmith, then reuse for Tannery/Bowyer/Armoury/Weaponsmith.

## Player outcome

A maker station answers three questions without becoming a catalogue spreadsheet:

1. **What kind of thing can this place do?**
2. **What exact stock will I spend, and why does it qualify?**
3. **What will change if I confirm?**

The landing screen shows recognizable choices, not every requirement sentence. Rules and provenance
remain fully available in the selected detail. Scrolling reflects a genuinely broad catalogue, not
full-width rows or permanent tutorial cards.

## Shared station shell

Every maker begins with one compact header:

- station silhouette/name and effective tier;
- Essence plus relevant stock count;
- one sentence of identity behind an info affordance, not a full-width permanent card;
- attention state such as **New pattern**, **Upgrade available** or **Result waiting** only when
  derived from actual game state.

Below it, station-local tabs expose real verbs. Tabs with no implemented action do not appear.

| Station | Primary tabs | Distinct promise |
|---|---|---|
| Blacksmith | **Make · Reforge · Learn** | foundational rigid gear; improve a retained exact piece |
| Tannery | **Make · Learn** | flexible living-material armour and capacity |
| Bowyer | **Make · Learn** | physical far-reach weapons without ammunition chores |
| Armoury | **Rebuild · Learn** | preserve exact armour identity while replacing construction profile |
| Weaponsmith | **Make · Learn** | advanced melee/reach forms; diary pattern remains earned |
| Apothecary | **Remedies · Coatings · Learn** | consumables grouped by purpose, not a long recipe ledger |
| Distillery | **Crystallise · Attune · Learn** | blank crystal, then one explicit provenanced core recipe |
| Channelworks | **Make · Restore · Learn** | magic weapon housings and Oda's one authored damaged fixture |

“Learn” uses the station's compact branch/tree component. It is not mixed between craftable outputs.
If a station has no live research branch, omit the tab rather than showing Coming later.

## Choice grids

### Recipe and profile tiles

Recipes, construction families, rebuild profiles and known consumables use compact choice tiles:

- three columns at ordinary 368-point portrait width; two at accessibility sizes;
- authored family/output glyph, short name and one readiness badge;
- no ingredient paragraph or permanent chevron row;
- readiness states: **Ready**, **Needs stock**, **Needs Essence**, **Tier N**, **Learn first** and
  **Unavailable**, each with redundant shape and VoiceOver wording;
- filters use a compact chip row only where the catalogue genuinely needs them: slot, physical
  damage kind, reach or consumable purpose. A filter never changes recipe eligibility.

A family with several deliberate variants opens one family detail rather than duplicating nearly
identical landing tiles. Weaponsmith damage kinds and polearm variants are chosen inside their family.
An unrecovered diary-exclusive pattern such as Maud's polearm remains absent; a generic lock must not
reveal it. Legitimately known next-tier station recipes may appear locked with their exact known gate.

### Owned-object and material trays

Owned gear targets and selectable physical stock use the settled six-across object grammar:

- exact item/sample identity, quantity and location/provenance badges;
- no name beneath every icon;
- tap opens/retargets compact anchored detail without leaving the workflow;
- candidate trays show only real stable instances/quantities; never identify by catalogue ID alone;
- a selected requirement slot points visibly to the exact candidate satisfying it.

The anchored detail follows the tapped icon and automatically flips/clamps above, below or inward at
screen edges. It may become a compact bottom sheet at accessibility sizes, but selecting stock never
navigates to a full-screen item page.

At accessibility sizes, trays may reduce columns and use the established compact-sheet fallback.
Property-bearing world-resource samples remain individual objects even when their base kind matches.
Fungible bulk requirements may use quantity controls on one resource tile.

## One craft/rebuild workflow

Opening a recipe/profile presents one contained detail sheet with four ordered regions:

1. **Result** — output silhouette/name, tier, slot/reach/damage/profile and concise current→result
   comparison where an existing item changes.
2. **Requirements** — visible requirement sockets stating property, minimum grade/quantity and current
   selected candidate. Rules supply these structured needs.
3. **Stock** — six-across eligible candidate tray; selecting a socket filters/highlights candidates
   without hiding why rejected stock fails.
4. **Commit** — exact Essence, consumed objects, preserved identity/history and irreversible losses;
   one explicit action button.

Result remains visible while stock changes. Do not force the player to remember a prior comparison
after navigating into a separate material picker. The detail may scroll at small/large-text heights,
but Result and current total cost remain in a compact sticky summary once they leave view.

Rules may preselect a deterministic valid set to reduce taps. Preselection is a suggestion, clearly
marked, and changing it never mutates inventory until confirm. A **Reset suggestion** action restores
the rules-owned default.

Only one nested decision surface is open. Selecting an object uses anchored detail; it does not push
another navigation stack or sheet over the craft sheet.

## Blacksmith first checkpoint

Blacksmith proves the shared grammar because it owns both creation and exact-item rework.

### Make

- Show the eight foundational physical construction families as a three-column glyph grid, grouped
  by weapon/armour filters only if all eight do not scan comfortably.
- A tile's badge derives from `PhysicalGearCraftingRules` readiness. **Ready · Tier 2** is useful;
  “3 selected samples · Tier 1–2” is detail, not landing copy.
- Opening a family enters the shared four-region workflow and uses the existing exact recipe,
  requirement and output-cap rules unchanged.

### Reforge

- Show every accessible Home piece in a six-across tray, including worn/stored/spillover locations
  already permitted by the equipment authority; expedition-carried gear remains read-only/unavailable
  unless a future mid-run station rule exists.
- Badges identify wearer/location, construction tier, reforge rank and Legacy masterwork warning.
- Reforge detail compares exact current and result power/cost while preserving stable instance,
  profile, wild growth and provenance according to current mechanics.
- Legacy work loss remains a distinct destructive confirmation. Merely selecting a piece never
  removes or swaps it.

### Learn

Blacksmith research appears as its authored branch/compact tree. Learned nodes update Make/Reforge
readiness immediately without changing selected stock silently.

## Station-specific reuse

- **Tannery/Bowyer:** reuse Make and material sockets; retain flexible/far-reach identity in result.
- **Armoury:** target tray first, then Rigid/Balanced/Insulated profile tiles inside one detail;
  preserve exact piece identity and show reforge/Legacy loss before stock commitment.
- **Weaponsmith:** close-form families are the landing grid. The fitted polearm family appears only
  after its pattern is known; damage kind and intended Might/Finesse lean are visible variant choices,
  never wearer locks.
- **Apothecary:** remedies/coatings use purpose tabs and recipe tiles; effects/targets/ingredients
  live in detail. Craft quantity is explicit before confirm.
- **Distillery:** Attune begins with one core identity then shows catalysts and qualifying samples;
  candidate provenance remains visible. No generic “material” row.
- **Channelworks:** housing/reach family and core are separate sockets. Restore is reserved for
  Oda's exact authored fixture and disappears/completes truthfully after restoration.

Shared components do not merge these mechanics. Each station retains its own rules-owned preview,
eligibility, transaction and result type.

## State, interruption and stale previews

- Opening/closing/retargeting detail costs nothing and changes no inventory.
- Confirmation passes stable candidate IDs, expected quantities, station/effective tier, recipe
  version, exact quoted cost and expected result to one atomic rules action.
- Any changed/missing input rejects with zero mutation and refreshes the complete preview. Copy:
  **“The stock, station, or cost changed. Review the refreshed result.”**
- Success consumes inputs and Essence exactly once, creates/rebuilds the exact output, dismisses to
  the originating tab and focuses the resulting item or updated target.
- Force-quit before confirm loses only ephemeral selection. Force-quit after success resumes the
  committed result, never the pre-confirm sheet and never a duplicate output.
- Tab, filters and grid position survive ordinary detail dismissal and successful return.

## Rules/presentation authority

One structured rules preview owns:

- recipe/profile identity and version;
- readiness/gate reason;
- ordered requirement sockets;
- eligible/rejected candidates with reason;
- deterministic suggested selection;
- output/current comparison;
- Essence and consumed quantities;
- irreversible warnings and commit token/fingerprint.

Landing tiles, detail, accessibility labels and commit validation project that same preview. UI must
not repeat thresholds, infer tier from colors, count samples separately or author a second cost line.
Final Aimee-authored glyphs communicate family identity/readiness but own no prices, grades or
eligibility; functional placeholders remain explicitly labelled as such.

## Accessibility and visual grammar

- Recipe tiles remain identifiable by glyph + name; state never relies on tint.
- Candidate icons retain at least 44×44-point ownership even when six visible artworks fit across.
- VoiceOver order: station/tab → recipe/profile and readiness → result → each requirement and selected
  stock → total cost/warning → confirm.
- Dynamic Type reduces recipe columns and object columns before clipping; sheets use one vertical
  scroll and no horizontal prose scroll.
- Grayscale/High Contrast distinguish Ready, selected, rejected, locked and destructive warning.
- Reduce Motion removes flourish only; no progress/result state depends on animation.

## Acceptance gates

1. Blacksmith Make/Reforge/Learn landing fits on 368×800 without permanent explanatory cards or one
   full-width row per recipe/item.
2. Eight construction families are distinguishable and reachable through at most one family detail.
3. A worn, stored and spillover piece can be identified in Reforge; inaccessible carried gear is
   visible only where truthful and cannot teleport Home.
4. Requirement sockets and candidate tray consume the same rules preview; rejected stock explains
   its failed property/grade/quantity without changing selection.
5. Result/cost updates immediately and deterministically for every selection; reset restores the
   exact suggestion.
6. Cancel, stale input, insufficient Essence and interrupted commit have zero partial mutation.
7. Successful creation/rebuild preserves exact stable identity/provenance rules and cannot duplicate
   through relaunch.
8. Legacy/rebuild losses receive explicit destructive confirmation with before→after values.
9. Large Text, VoiceOver, grayscale and edge/bottom anchored details pass on the phone fixture.
10. Tannery/Bowyer/Armoury/Weaponsmith reuse the shared shell/tray/workflow without copying mechanical
    thresholds into view code or erasing their distinct verbs.
11. Every edge/bottom object detail remains fully onscreen; tapping an item never pushes a new
    full-screen destination or loses the current station selection.

## Non-goals

- no crafting minigame, timers or progress bars;
- no drag-and-drop requirement for accessibility-critical selection;
- no universal recipe model that flattens distinct station rules;
- no automatic use of highest-grade stock without preview;
- no recipe search until real catalogue size demonstrates a need;
- no broad art dependency before the Blacksmith structural checkpoint.
