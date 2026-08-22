# Expedition Return object layout — current

**Status:** Game Design implementation authority for B2.14 presentation
**Depends on:** the source-complete typed `RunExitSummary` receipt; final Creature-material family/quality
projection before native category migration
**Owners:** Engineering owns receipt projection, navigation and anchored detail; Asset owns shared object,
paper/book and person identities; Game Design owns grouping, hierarchy and copy
**Updated:** 21 August 2026

## Player result

Returning Home feels like laying out what the expedition produced, not reading an accounting export. The
player can recognize what came home, what was lost, what became permanent knowledge and how the party
advanced without scrolling through repeated full-width rows.

The screen is a pure presentation of one immutable `RunExitSummary`. It never diffs current Storehouse,
Library, Party or catalogue state to reconstruct an outcome.

## Screen shell

The large Return sheet has three fixed regions:

1. compact outcome header;
2. one **Recovered / Lost / Progress** segmented body;
3. fixed **Continue** action above the bottom safe area.

At 368×800, the complete header, segmented control, at least the first three object rows and the complete
Continue button are visible without scrolling. Only the selected tab's body scrolls. Changing tabs never
dismisses, acknowledges or mutates the receipt.

### Outcome header

Show:

- outcome silhouette/shape, not a giant SF Symbol;
- exact outcome title: Returned through a portal, Returned by Waystone, Carried home, Lost to the collapsing
  world or Expedition abandoned;
- one rules-frozen plain-language statement about the actual world at departure, using
  `canonical-player-terminology-current.md`; never repeat the outcome title in sentence form;
- `World {runIndex} · {turnsTaken} turns`;
- `All physical haul returned` or exact retained fraction language.

Do not repeat separate `Outcome`, `Recovered`, `Lost` and `Kept for good` title cards down one scroll.

The permanent-gains summary uses **Writing found**, **Joined the village** and **XP earned**. It never says
`marks / current draft`, counts a newly recruited traveller as `returned`, or collapses XP/levels into generic
`progress / party total`.

### Tab rules

- All three tabs remain visible even when Lost is empty, so outcome type does not move navigation.
- Lost shows `Nothing was lost from this expedition.` when empty.
- Continue is enabled after the immutable receipt has rendered once. There is no timer and no requirement to
  inspect every detail.
- Continue is the only dismissal/acknowledgement. Interactive swipe dismissal remains disabled.
- Relaunch before Continue reopens the exact receipt on Recovered; no award is applied again.
- Tutorial is outside this checkpoint and, if still present, is a non-displacing overlay.

## Receipt-only projection

```text
ReturnCollectionModel
  outcomeHeader
  recoveredWorldResourceStacks[]
  recoveredCreatureMaterialStacks[]
  recoveredItemLines[]
  recoveredWorldPages[]
  recoveredDiaryBundles[]
  recoveredOtherWriting[]
  recruitedPeople[]
  lostWorldResourceStacks[]
  lostCreatureMaterialStacks[]
  lostItemLines[]
  lostWorldPages[]
  essenceProgress
  experienceSources[]
  partyProgress[]
```

Every projected entry retains the receipt-line stable ID. Current catalogue assets may improve its picture;
frozen fallback name/icon remains historical fallback. Current inventory quantities, equipment location,
traveller assignment or Library thickness never replace the receipt's facts.

## Recovered tab

Render only nonempty sections, in this exact order.

### World resources

- six 44×44-point object targets across at ordinary phone width;
- stable resource silhouette, quality frame when the resource is quality-bearing, aggregate quantity badge;
- final stack key is `world + family + qualityBand`;
- currently qualityless bulk resources remain their truthful legacy/live stack; migration never invents
  `Rough` merely to fit the new frame;
- tap opens anchored detail with frozen quantity, resource name, known uses and collection-source record link
  when present.

World resources include ground, flora, site and other world-node materials. They never include Creature
materials merely because both are slot-free.

### Creature materials

- six across using the exact body-derived family silhouette;
- stack key is `creature + family + qualityBand`;
- one tile per family/band, so nineteen Standard Hides are one `Hides ×19` tile;
- Standard Hides and Fine Hides are two tiles;
- different families never merge because their display names or crafting tags happen to match;
- merged stacks link to Bestiary collection-source records rather than claiming all units came from one
  exact specimen.

During migration, old exact `MaterialSample` units must first map through the settled projection receipt.
The final Return surface never exposes continuous grade numbers or treats a material sample as an item slot.

### Items

- six across using exact stack/instance identity;
- genuinely homogeneous stackables aggregate by their frozen receipt key;
- gear, curios and other property-bearing instances remain separate even when catalogue IDs match;
- quantity, quality, identified/unknown, favourite/locked and protected-return state use the shared corner/
  frame grammar where that fact exists in the frozen line;
- opening detail never navigates away from Return.

### World Pages

- three physical-page thumbnails across because their 6×6 writing must remain legible;
- each exact kept instance remains separate;
- inspected page shows frozen title; uninspected page says **Unknown page** and reveals no canonical title in
  accessibility;
- detail shows the frozen page/provenance and `Added to Writing Desk → Pages` without offering an edit or
  bind action here.

### Writing recovered

Use object tiles, not prose rows:

- **Diary pages:** one growing-book tile per traveller represented in this outcome, with `+N pages`; tap detail
  lists the exact recovered page titles/excerpts in authored order. The permanent Library book may now be
  thicker, but Return depicts only this outcome's addition.
- **Field notes, route marks, site fragments and working scraps:** one paper/object tile per exact recovered
  writing, four across; family silhouette plus short title; detail owns the prose.
- long diary/field-note prose never prints permanently under every tile.

### People who came home

- three identity tiles across;
- portrait/silhouette, name and one concise `Joined the community` state;
- one exact traveller appears once even if multiple events referenced them;
- tap opens compact arrival detail or their Library diary route after dismissal; it does not alter the
  departure party from the recap.

Knowledge and recruited people are permanent once legitimately earned. They do not move into Lost merely
because the outcome retained only part of the physical haul.

## Lost tab

Use the same object positions, silhouettes, quantities and anchored receipt detail as Recovered, with a
distinct lost frame/crosshatch that is redundant with colour. Exact order:

1. World resources;
2. Creature materials;
3. Items;
4. World Pages.

Do not list zero-value empty section cards. Do not show diary knowledge, other recorded writing, recruited
people or earned XP as lost unless a future rules authority actually makes that category losable.

For partial return, Recovered and Lost quantities must exactly partition the expedition receipt. Selecting
the same family in each tab displays two independent frozen lines; neither detail looks up the post-return
Storehouse total.

## Progress tab

### Essence and next-world runway

Lead with **Spendable Essence now: {netRunway}** and one compact causal flow:

```text
Raw returned {rawCollected}
Current refined value {refinedEquivalent}
Auto-refined {rawAutoRefined} Raw → {automaticallyRefinedEssence} Essence   // only when nonzero
Spring +{springYield}
Shortfall aid +{antiLockSubsidy}                                          // only when nonzero
Previous bind −{bindCostPaid}
```

Use compact icon/value chips or a two-column flow, not full-width `LabeledContent` rows. Raw and refined
Essence remain different identities. `netRunway` is the final authoritative quantity, not a locally summed
guess. If a field is zero and has no explanatory value, omit it.

### Party progress

- one compact source strip: Combat, New species, New sites, Writing and New travellers, omitting zero sources;
- then three person tiles across where space permits;
- tile shows identity, `+N XP`, final level and `+N levels` only when nonzero;
- every active member may correctly earn the same full source award; the screen does not imply XP was split;
- tap detail shows the frozen per-source breakdown and before→after level progress for that member;
- the recap never derives XP by subtracting current mutable character state.

## Anchored detail behavior

All object/person tiles use the shared edge-clamped anchored detail grammar:

- relationship to selected tile remains visually clear;
- prefer above/below, then shift inward; bottom/edge rows never clip;
- only one detail open; tapping another retargets;
- tapping outside closes and returns focus/scroll to the originating tile;
- detail is read-only and uses the frozen receipt entry;
- no Sell, Recycle, Equip, Use or Party action belongs in Return;
- a Library/Bestiary source link may navigate only after explicit activation, preserving the pending receipt
  until Continue.

## Empty and large outcomes

- A section with no objects is omitted, except the Lost tab's one explicit all-clear sentence.
- The first three section rows remain above Continue; larger collections scroll inside their tab.
- Six-across grids use lazy layout and stable receipt IDs; no dynamic name length changes column count.
- Duplicate fallback names or icons never merge distinct stable lines.
- A maximum stress outcome may contain all five Recovered sections and all four Lost sections without losing
  Continue, tab state or selected detail.

## Asset production boundary

Use the same shared production identities as field, Storehouse, Trading Post, crafting and Library:

- 23 World-resource families plus Raw/Refined Essence distinction;
- 18 Creature-material family silhouettes;
- six quality frames with redundant shape/colour grammar;
- existing item/gear/curio/unknown identities;
- physical World Page, loose paper, folio and diary-growth assets;
- traveller identity tiles;
- five outcome silhouettes and one lost-state overlay;
- compact Essence-flow and XP-source glyphs.

Asset does not paint a fixed haul screenshot. Provide reusable logical sprites/components and a compositor
fixture driven by typed receipt data. Missing final family art uses a truthful provisional silhouette labelled
as such; it never substitutes an unrelated SF Symbol and claims final identity.

### First proof fixture

One 368×800 composite must include:

- Rubble ×6 and Raw Essence ×12;
- Standard Hides ×19, Fine Hides ×2, Standard Bone ×4;
- one stacked consumable, two same-catalogue gear instances with different profiles and one unknown curio;
- two exact World Pages, one uninspected;
- three pages from one diary, one page from another and two other writing families;
- one recruited traveller;
- nonempty Lost resources/item/page;
- full Essence flow and two party members with identical total XP but different level outcomes.

Also export literal grayscale, every edge-detail placement, an empty-Lost state and a relaunch-identical model
snapshot. These are evidence; production assets remain independent.

## Engineering acceptance

1. Screen reads only the frozen typed receipt; changing Storehouse/Library/Party after return changes no tile.
2. World resources and Creature materials are separate and use exact family/quality stack keys.
3. Nineteen same-band Hides appear once; another quality band and Bone remain separate.
4. Exact item profiles, unknown state, World Page instances, diary IDs and traveller IDs remain independently
   reachable.
5. Recovered/Lost lines exactly partition partial outcomes for portal, Waystone, collapse, defeat and abandon.
6. Knowledge, people and XP do not disappear on partial physical-haul outcomes.
7. Essence flow equals the receipt and ends on authoritative net runway.
8. Identical XP totals may appear for multiple active members without hardcoded/capped 100 behavior.
9. Relaunch before Continue restores the exact receipt; Continue dismisses once and cannot reapply rewards.
10. 368×800 shows stable tabs, first object rows and complete Continue; every bottom/edge detail remains on-screen.

## Explicit exclusions

- no tutorial creation or polish;
- no automatic selling/recycling from recap;
- no reward reroll or reveal animation that owns mutation;
- no generic “Resources” category combining world and creature domains;
- no per-unit provenance invented after stack merging;
- no continuous material-grade UI;
- no list of full diary prose on the landing surface.
