# Tutorial opening slices — exact triggers and copy

**Status:** Implementation-ready slices 1–2. This specializes `tutorial-discoverability-current.md`
against the live Writing Desk and World UI; it does not add a tutorial world.  
**Updated:** 9 Aug 2026

## State model

Persist a versioned record per lesson ID outside transient view state:

```text
status: unseen | deferred | completed
firstEligibleRunIndex: optional
completedByFact: optional stable fact key
```

`Not now` sets deferred. A deferred lesson becomes eligible only when its owning screen/context is
encountered again. Replay from Settings → Field Notes does not reset the durable fact or mark another
lesson unseen.

On migration, if the durable completion fact already exists, mark the lesson completed and place it
in Field Notes without presenting it over the player's next launch. Unknown future lesson IDs decode
safely; removing a lesson never blocks the save.

One card maximum per screen. Priority within an opening context follows the tables below. Critical
world warnings, loot decisions and encounter outcome UI always outrank tutorial cards.

## Slice 1 — Writing Desk

| Priority | Stable ID | Eligible when | Complete when | Anchor and copy |
|---:|---|---|---|---|
| 1 | `writing.page_request.v1` | First Writing Desk visit | First bind, whether the page is written or blank | Page grid: **A page is a request, not a blueprint.** Choose a word and place its mark—or leave subjects unwritten and let the world decide. |
| 2 | `writing.page_space.v1` | First mark selected or placed | A placed mark exists | Palette footprint/ghost: **Marks take room.** The number on a word is its footprint; one page cannot hold every request. |
| 3 | `writing.preview.v1` | First switch to The world | The world pane has been opened once | Pane switch/Projection: **This is what the page can promise.** Written subjects are described; unwritten subjects remain ranges until binding. |
| 4 | `writing.bind.v1` | Bind action first becomes enabled | First run is created | Bind button: **Binding spends the shown essence and opens one expedition.** The book and everything you learn remain recorded after the trip ends. |

Rules:

- `page_space` never appears on a blank-page route and remains available for the next time a mark is
  selected; it does not delay Preview or Bind.
- Do not force the player to select a word, write one subject, clear chance, or accept a starter
  template.
- Invalid link/placement feedback is normal UI and outranks a page-space card attached to the same
  gesture.
- The existing blank-page warning and unwritten-subject count remain visible; tutorial copy does not
  repeat their live numbers.

The Stability disclosure inside Projection is permanent help rather than a one-use tutorial:

> **Stability is how long this world can hold together.** Demanding worlds may offer more and last
> less time. Unwritten subjects make the estimate a range.

Do not say the complete value is saved “with the book” before bind; the page composition is saved,
while the seed-resolved world value belongs to the generated run/history.

## Slice 2 — first world essentials

The live UI supports both D-pad stepping and tap-to-travel. The older adjacent-only wording is
superseded.

| Priority | Stable ID | Eligible when | Complete when | Anchor and copy |
|---:|---|---|---|---|
| 1 | `world.navigation.v1` | First world opens with no encounter/loot decision | First movement event | Map + D-pad: **Tap a reachable space to travel there, or use the arrows one step at a time.** Movement spends world turns and stops when something needs you. |
| 2 | `world.stability.v1` | After first spent world turn | Player has seen the post-turn meter state | Stability header: **World actions spend turns.** At zero Stability the world starts coming apart; you may still race for a portal while floor remains. |
| 3 | `world.interaction.v1` | First time the current tile exposes a valid action | First valid Survey/Harvest/Search/site/cache/anchor action | Context action stack: **Standing somewhere useful reveals what you can do here.** Each action says whether it spends a turn or consumes something. |
| 4 | `world.return.v1` | After navigation and Stability lessons, while a portal action is available | First expedition outcome of any kind | Portal action: **A portal returns the full haul.** If defeat or the collapsing floor carries you home, knowledge stays and only part of what you found may be lost. |

The minimap is framed within `world.navigation`; it does not get a second opening card. Its replay
entry says:

> The minimap remembers revealed ground, known routes and landmarks. Empty fog does not tell you
> what is hidden there.

Rules:

- Interaction teaching triggers on the **current** actionable tile, not merely an adjacent object.
- Diary pages and found writing currently resolve automatically when entered rather than exposing a
  context-action button. They do not falsely trigger this action-stack lesson. If reading later
  becomes a deliberate current-tile action, it takes priority over ordinary harvesting when both
  become newly eligible, because writing is the campaign spine.
- A first encounter interrupts these cards. Combat owns the screen until its outcome is resolved;
  the next eligible world card returns afterward if the expedition continues.
- A first-run defeat/collapse completes `world.return` through the exit recap and teaches the real
  partial-return rule. Do not immediately replay a portal card at Base.
- The tutorial never reveals the portal path, hidden writing, sites, enemies or safe route beyond
  what normal map/reveal rules already permit.

## Card behavior

- Maximum 58 words is a ceiling; opening cards above are deliberately shorter.
- Card actions are `Got it` and `Not now`. Neither consumes a turn nor dismisses underlying loot.
- Anchor arrows may point to a control but never intercept its 44pt target.
- VoiceOver order: heading, body, anchored control label, Got it, Not now.
- Dynamic Type may move the card below the anchor; it must never cover the Stability meter and
  portal action simultaneously.

## Field Notes structure

Settings gains **Field Notes** with five groups already established by the broader design. These two
slices populate:

- Writing: A page is a request; Marks take room; Reading the preview; Binding an expedition.
- Worlds: Moving through a world; Stability and collapse; Actions where you stand; Returning home;
  Reading the minimap.

Every entry is readable from new game, but undisplayed lessons use neutral how-to copy only; they do
not mark themselves completed or reveal campaign discoveries.

## Debug and verification

1. Reset/replay one lesson or group without resetting the save.
2. Interrupt immediately before eligibility, while visible, after defer and after durable completion;
   each resumes with at most one appropriate card.
3. Blank first page reaches Preview/Bind lessons without ever forcing Page space.
4. Tap-to-travel and D-pad movement both complete Navigation.
5. An encounter or loot decision suppresses—not completes or duplicates—the pending world card.
6. First collapse completes Return through the real recap and never claims the full haul was kept.
7. An old save with at least one bound run/world turn receives completed Field Notes entries rather
   than an opening-screen takeover.
