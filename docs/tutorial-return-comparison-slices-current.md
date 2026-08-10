# Tutorial return and comparison slices — exact triggers and copy

**Status:** Implementation-ready slices 3–4 under `tutorial-discoverability-current.md`. Values and
copy are current; presentation density remains DRQ-070/109 playtest work.  
**Updated:** 9 Aug 2026

These slices begin only after a real expedition outcome. They do not alter world generation, grant
loot, prescribe a rune, or pretend that changing one request holds every random roll constant.

## Required persisted context

Tutorial state gains one optional, tolerant `firstReturnContext`:

```text
runIndex
route: library | storehouse | workshop | firepit | writingDesk
reason: diaryPage | fieldNote | routeMark | siteFragment | workingScrap |
        unidentifiedObject | rawEssence | traveller | ordinaryReturn
writingID: optional stable diary/found-writing ID
```

Choose and freeze it once when the first `RunExitSummary` is committed. Do not recalculate it from
later inventory or station state. Old saves with no context infer only from still-provable durable
facts and otherwise use `writingDesk / ordinaryReturn`; inference files the lesson into Field Notes
without taking over the next launch.

For exact first-return evidence, a run snapshots `foundWritingsAtStart` and
`foundTravellersAtStart` alongside the existing `foundPagesAtStart`. Its exit summary may retain the
new stable IDs and unidentified returned item IDs needed for recap/routing. This is history, not
recoverable haul: writing and traveller knowledge survive every exit kind.

Route priority is deterministic:

1. any newly found diary page or anonymous writing → Library;
2. otherwise any newly returned unidentified object → Storehouse;
3. otherwise newly returned raw essence while refined essence is below the cheapest currently
   bindable known page → Workshop;
4. otherwise a newly found traveller → Firepit;
5. otherwise → Writing Desk.

Within the Library tier choose the earliest collected new record; diary pages precede anonymous
writing only when collection order cannot be recovered. Never show several next-step badges.

## Slice 3 — the first return

| Priority | Stable ID | Eligible when | Complete when | Anchor and copy |
|---:|---|---|---|---|
| 1 | `return.persistence_boundary.v1` | First exit recap is visible | That recap is acknowledged | Recap headings: **The expedition ended.** Resources and objects crossed into the Base. Writing, discoveries and people are remembered in Reality even when part of a haul was lost. |
| 2 | `base.first_result_route.v1` | Base first appears after that recap is acknowledged | Frozen destination is opened | One frozen destination card: dynamic copy below. |
| 3 | `library.first_writing.v1` | Frozen Library route opens with its selected record visible | That Library visit has displayed the selected record and the player leaves or acknowledges the anchored note | Selected record: type-aware copy below. |

The persistence card must use the real recap sections. It cannot say an item came home if the lost
section says otherwise, and it never describes a portal/Waystone return as a collapse.

### Frozen destination copy

- **Library:** “You brought back writing. The Library keeps its words beside everything else you
  have learned.”
- **Storehouse:** “Something returned without a known name. The Storehouse is where an object can
  be identified without guessing at its use.”
- **Workshop:** “Raw essence cannot bind a page. Refine what returned at the Workshop.”
- **Firepit:** “Someone new is at the Base. The Firepit is where you choose who travels; Party holds
  their stats, gear, rank and gambits.”
- **Writing Desk:** “This journey is now part of World History. Bind again when you want another
  comparison.”

The badge is a tutorial anchor, not a replacement for ordinary station badges. `Not now` preserves
the frozen route and offers it only on the next Base visit. Opening the destination by any normal
navigation path completes it.

### Type-aware Library copy

The selected recovered record determines one body; never show all bodies as a catalogue:

- **Traveller location page:** “Every world holds some kind of writing. This passage describes one
  part of a world where **{traveller}** can be found. Compare its words with world descriptions;
  the Library will not translate it into a checklist.”
- **Other diary page:** “This page belongs to **{traveller}**’s book. Its heading shows what kind of
  knowledge it carries; it is not necessarily a location clue.”
- **Field note:** “A Field note remembers one truthful relation from the place where it was found.
  It can help you read worlds, but it is not part of a traveller’s location.”
- **Route mark:** “A Route mark preserves one short path from that world. It reveals no destination
  beyond the marked ground.”
- **Site fragment:** “A Site fragment records words tied to a place you could already see. It does
  not reveal what the site contains.”
- **Working scrap:** “A Working scrap teaches one ordinary recipe. It grants the knowledge, not the
  item or the materials to make it.”

Only the traveller-location version states the search loop. If the first writing is another type,
`library.traveller_location.v1` remains unseen and uses the location copy on the first later Library
visit containing a newly recovered location passage.

## Slice 4 — optional second-world comparison

### Semantic comparison record

World History gains an optional persisted comparison pair of two `VisitedWorld.id` values. A pair is
valid only while both records remain retained; keeping either world does not silently keep the
other. If pruning removes one, clear the pair and retain the tutorial lesson for a later pair.

The comparison surface shows, side by side:

- each world’s description sentence;
- `What you wrote`, with unchanged lines subdued and added/removed/replaced lines shaped and labelled
  independently of colour;
- measured resolved values only at the player’s current analysis tier;
- a permanent note: “Unwritten subjects and other chance may differ between worlds.”

It never subtracts two hidden numeric readings, claims that one changed mark caused every
difference, or exposes a value the player’s current instruments cannot read.

### Lessons

| Priority | Stable ID | Eligible when | Complete when | Anchor and copy |
|---:|---|---|---|---|
| 1 | `writing.compare_request.v1` | Writing Desk opens after one recorded expedition and before a comparison pair exists | Preview is opened after the semantic request differs from the latest recorded world | Page/Preview switch: **Change one request and compare.** Add, remove or replace one focus under a subject, then inspect The world. Everything you leave unwritten may still roll differently. |
| 2 | `history.compare_worlds.v1` | A later world is recorded after `writing.compare_request.v1` completes | Player opens the two-world comparison surface | World History compare action: **Read the two records together.** Changed writing is emphasized; other differences may have come from what neither page controlled. |

`writing.compare_request` is optional and nonblocking. Binding an unchanged page, changing several
requests, or leaving the Desk does not prevent play and does not falsely complete the lesson. It is
deferred until the next relevant Desk visit.

For this lesson, a **semantic request** is a normalized target chain, not rune position, rotation,
hand, glyph footprint or instance ID. Exactly one request differs when one chain is added or removed,
or one chain for the same target has its focus/qualifier content replaced. Moving the same marks on
the page does not count. Once such a preview is opened, freeze the prior world ID as the comparison
origin; the next successfully recorded world becomes its partner even if the expedition ends by
defeat or collapse.

If the player changes more than one request, normal History comparison remains available after the
world, but the tutorial copy changes to “Compare these pages” and makes no one-change claim.

## Suppression and migration

- Exit warnings, loss decisions, anchor settlement and spillover decisions outrank all Slice-3
  cards. Routing begins only after those real obligations resolve.
- One card maximum per screen remains absolute.
- A route never unlocks a station. If its desired destination is unavailable, use the next eligible
  priority and record the actual frozen route.
- Existing histories receive no fabricated pair. A migrated save with two retained worlds may use
  normal comparison immediately, while both tutorial lessons are filed as completed Field Notes
  only if a prior one-change exercise is provable; otherwise they remain replayable and nonintrusive.
- Unknown future reasons/routes decode safely to `writingDesk / ordinaryReturn` without discarding
  the raw tutorial record.

## Debug and verification

1. Force each exit kind with each route reason; the recap remains truthful and exactly one route is
   frozen.
2. Lose an unidentified item during collapse: Storehouse must not be chosen for that lost item.
3. Find anonymous writing and a traveller in one run: Library wins, Firepit remains normally usable.
4. First non-location writing does not display the traveller-location explanation; a later location
   passage still can.
5. Defer the Base route, mutate inventory, return again: destination and reason do not change.
6. Moving/rotating marks without semantic change does not complete the comparison request.
7. One added, removed and replaced chain each complete it; two changed chains do not claim the
   one-change exercise.
8. Compare in colour, grayscale, VoiceOver and Large Text; added/removed/replaced state and column
   ownership remain legible without colour or left/right-only wording.
9. Raise analysis tier after both trips: the comparison reveals newly readable old measurements but
   never changes stored world facts.
10. Prune one unkept comparison world: the stale pair clears safely and History still opens.
