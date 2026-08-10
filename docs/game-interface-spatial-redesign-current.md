# Game Interface Spatial Redesign — Current Direction

**Status:** Design audit opened by Aimee, 10 August 2026. Library accuracy correction is a bug;
broader screen conversions require staged phone review.

## Problem

Outside world exploration and world writing, the app relies too heavily on vertically stacked,
full-width rows and cards. This resembles a settings or database app rather than a game. It weakens
visual identity, makes categories harder to remember spatially, and scales poorly as content grows.

## Current Library bug

The Library's `Pages` card claims to contain pages that are not location clues, but it renders and
counts **every** recovered diary page. Location-clue pages therefore appear once inside a traveller's
diary/search card and again in the generic Pages card. This makes both the label and the apparent
collection structure inaccurate.

The immediate correction should classify recovered writing once:

- **People:** one tile per known traveller; opening it shows that traveller's complete recovered
  diary, with location passages and other page types on distinct tabs.
- **World notes:** field notes, route marks, site fragments and working scraps, grouped by family.
- **World history:** worlds the player wrote, unchanged as its own destination.

No diary page appears in two top-level collections. Counts state `found / known total` only where
the denominator is player-legible; they must not reveal undiscovered travellers or secret corpus
size.

## Interface grammar

- Use compact square or nearly-square icon tiles for destinations, categories, people, item families
  and discovered species.
- Use tabs/segmented categories when one destination contains several peer modes.
- Use full-width rows only when scanning and comparing text or numbers is the actual task.
- Open a focused detail screen after tile selection; do not place the entire database on the hub.
- Preserve 44pt targets, labels in addition to icon/color, large-text reflow and VoiceOver order.
- Phone portrait is authoritative. Grids normally use two columns; allow one column at large text.

## Screen triage

| Screen | Direction | Reason |
|---|---|---|
| Base | 2-column station/building tile hub; persistent Depart action | A place should be spatially remembered, not read as a directory |
| Library | Tabs: People / World notes / History; people and note families as tiles | Fixes duplicate/inaccurate pages and gives the collection structure |
| Party overview | Character portrait tiles; retain per-character swipe pager and Gear/Training/Stats/Gambits tabs | Existing detail structure is good; overview is still a card list |
| Storehouse/equipment | Slot/category tabs plus item icon grid; visible location badges for Stored/Worn/Overflow/Carried | Inventory ownership must be visible before comparison rows |
| Bestiary | Species tiles; focused specimen detail | Discovery collection benefits from silhouettes and spatial recognition |
| Workshop/station research | Branch icon grid leading to the existing node tree | Branches are destinations, not prose rows |
| Stations with recipes | Category tabs + recipe/item grids; comparison/confirmation may remain rows | Selection should be visual; transaction details still need exact text |
| World history | Keep chronological list, add compact filters/tabs | Timeline comparison genuinely benefits from ordered rows |
| Settings, Debug queues, bug reports | Keep lists/forms | These are utilities rather than game-world spaces |
| Combat gambit rules | Keep ordered rule list inside its character tab | Priority order is the mechanic |

## Delivery order

1. Correct Library classification and prove the People / Notes / History shell on phone.
2. Correct equipment ownership/slot visibility, then prove the reusable item-grid component there.
3. Convert Base to a station tile hub using authored station identities.
4. Reuse the tile/detail grammar for Party overview and Bestiary.
5. Convert research branches and recipe-heavy stations after the blocker economy loop works.

Do not convert every row mechanically. Exact comparisons, chronological history and ordered rules
remain lists because their sequence and alignment carry meaning.
