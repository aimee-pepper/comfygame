# Phone game UI benchmark audit

**Status:** current functional UI audit; recommendations only where they do not repeat an already
settled Bookbinder screen contract. Final handmade character, place, item, weapon and sigil art is
Aimee-owned.

**Reviewed:** 11 Aug 2026 against the current SwiftUI screens, Apple game-control guidance,
Shattered Pixel Dungeon's official mobile UI notes/source, and the official Slice & Dice store
presentation.

## Benchmark conclusions

### What the reference games do well

- **The playfield remains the dominant object.** Shattered Pixel Dungeon keeps persistent status and
  frequent actions at the perimeter, moves secondary menus away from the thumb/play area, and adapts
  its top geometry around cutouts instead of letting system furniture collide with game UI.
- **Controls appear for the current decision.** Apple explicitly recommends reducing controls that
  overlap play and showing/hiding virtual controls by context. Slice & Dice demonstrates the same
  economy: the current dice/targets and the next irreversible action dominate; explanatory depth is
  available without making every action a prose row.
- **Density comes from stable spatial ownership, not tiny tap targets.** A compact icon can sit inside
  a 44pt target. Apple recommends 44x44pt for frequent controls and roughly 17pt type on iPhone/iPad.
- **Primary commitment has one stable thumb-zone owner.** It is visually stronger than inspection,
  filters, settings and alternate navigation, but it does not consume an entire card-height region.
- **State feedback is immediate and redundant.** Selection, availability, press, quantity and result
  are not communicated by hue alone.

### What Bookbinder should not copy

- Pixel-art density is not permission to ship 8–10pt player text. Bookbinder has longer authored
  names and more explanatory state than either reference.
- A combat HUD grammar should not be pasted onto Base, Library or maker stations. Those surfaces
  browse places, collections and transactions rather than acting continuously on a stage.
- Permanent bottom navigation is not justified merely because bottom controls are reachable. Only
  frequent, cross-tab commitments belong there; screen-local filters and details remain local.

## Current Bookbinder strengths

- Base now separates top context, destination tabs, place tiles and the compact persistent
  Party / Bind & Depart pair.
- World History, Bestiary, Campaigns and Research now present their primary objects before prose.
- Six-across physical-object trays, anchored detail and explicit transaction confirmation establish
  a reusable economy grammar.
- Combat true-graph and Large Text proofs preserve topology instead of replacing it with a misleading
  list.
- The Writing Desk now keeps the page first, puts palette navigation before its contents, uses a
  compact category menu at accessibility sizes, and preserves a compact primary bind action.

## Highest-value remaining corrections

### P1 — Encounter action selection

Current `EncounterView.SkillSheet` and `CombatItemSheet` are full-screen lists that remove the battle
stage and duplicate carried items by ally. Replace them with a context-sensitive action palette over
the retained stage:

- techniques as compact choices using temporary identity marks until handmade art exists;
- carried items once in a six-across tray;
- actor and target selection as separate, explicit steps;
- one compact confirm/commit owner in the thumb zone;
- combat log remains chronological text.

This is the clearest place to apply the Slice & Dice lesson: show the current tactical choice and its
consequence, not every possible explanation simultaneously.

### P1 — In-world Field Kit

`WorldView.FieldKitSheet` remains a prose list. Convert only its functional shell:

- Instruments / Supplies tabs;
- compact instrument placeholders and the existing carried-item identities;
- anchored inspection/use detail while the world context remains recoverable;
- no home inventory, recipe or loadout editing inside the expedition sheet.

### P1 — Maker selection subflows

Blacksmith and related stations still use full-width lists for profile and exact-material selection.
Keep exact before/after transaction tables, but replace browsing portions with:

- three-column recipe/profile choices;
- six-across eligible stock;
- one persistent selected-result/requirements/shortfall region;
- disabled reasons beside the commit action, not buried in a row.

### P1 — App-wide top-bar normalization

The original Base screenshot exposed a systemic problem: large titles, detached utility pills and
floating debug controls competed for the top safe area. Audit every ordinary screen against one
compact top-context pattern:

- concise place/screen identity;
- at most one relevant purse/status summary;
- one ordinary utility affordance or overflow;
- DEBUG and Testing never share visual weight with player navigation;
- no control under a cutout/Dynamic Island, and no empty hero-header height without meaningful
  content.

### P2 — Typography and compression debt

Fixed 8–12pt player-facing text and `minimumScaleFactor` are still present in several live surfaces,
notably combat/tree annotations, minimap marks, item overlays and single-line party summaries. Tiny
icon annotations may remain visual redundancy, but names, effects, quantities and actions need a
semantic text style and Large Text reflow. Never use scale-down as the only way a long localized name
fits.

### P2 — Selection/detail consistency

Standardize one interaction across collections:

1. tap object or choice;
2. retain its position and visibly select it;
3. open edge-clamped anchored detail (compact sheet at accessibility sizes);
4. perform a separately labelled mutation;
5. dismiss or cancel back to the same tab/filter/scroll location.

Campaign deletion remains a deliberate exception: destructive confirmation is modal and names the
campaign.

## App-wide acceptance checklist

1. Frequent controls are at least 44x44pt and reachable without colliding with system safe areas.
2. Ordinary explanatory/action type targets approximately 17pt; smaller text is secondary metadata,
   never the only statement of rules or state.
3. The primary screen object (map, page, graph, collection, person, campaign, transaction) receives
   more space and visual weight than navigation chrome.
4. One screen has one obvious primary commitment; a primary button is compact but persistent, not a
   full-width card unless the content genuinely requires that height.
5. Secondary utilities are grouped or moved to overflow. DEBUG controls are absent from Release.
6. Color is never the sole indication of state, selection, danger, quantity or availability.
7. Large Text completes the same task. It may reduce columns or use a sheet, but cannot remove Search,
   filters, actions or context.
8. VoiceOver order follows player intent: context, selected object/state, consequence, then action.
9. Cancellation returns to the exact prior spatial position and never mutates state.
10. Phone snapshots include 368x800 ordinary and accessibility sizes, safe-area/cutout checks, literal
    grayscale, and the longest plausible localized labels.

## References

- Apple Human Interface Guidelines, Game controls:
  https://developer.apple.com/design/human-interface-guidelines/game-controls
- Apple WWDC24, Design advanced games for Apple platforms:
  https://developer.apple.com/videos/play/wwdc2024/10085/
- Shattered Pixel Dungeon official mobile fullscreen/UI note:
  https://shatteredpixel.com/blog/coming-soon-to-shattered-title-graphics-and-mobile-fullscreen.html
- Shattered Pixel Dungeon official source:
  https://github.com/00-Evan/shattered-pixel-dungeon
- Slice & Dice official store page:
  https://play.google.com/store/apps/details?id=com.com.tann.dice

