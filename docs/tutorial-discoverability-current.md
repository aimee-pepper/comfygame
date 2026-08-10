# Tutorial and discoverability — current design

**Status:** implementation-facing structure and copy direction. Exact presentation timing is
playtest work. This teaches the current game without solving its interpretive puzzles.

## Principle

The tutorial teaches **verbs, consequences and where records live**. It does not translate diary
prose into conditions, recommend an optimal book, reveal undiscovered vocabulary or explain a
world's hidden roll.

The player's first lesson should be the actual loop:

> Write as much or as little as you choose. Enter what results. Bring evidence home. Use that
> evidence to write more deliberately next time.

Do not build a separate tutorial world with false rules. A blank first page must remain genuinely
varied; collapse, creatures and chance remain real. Failure is an acceptable first expedition
because the return safely demonstrates that a run is disposable and Reality knowledge is not.

## Presentation rules

- Use one short anchored card at a time, attached to the control or record it explains.
- Never freeze the whole interface behind a tour sequence. The player may ignore the highlighted
  action and continue playing.
- Cards dismiss on the demonstrated durable fact, not merely on a tap: binding a book, moving a
  world turn, inspecting something, returning, opening recovered writing.
- Every card has **Not now**. Deferred cards reappear only at their next relevant context, never on a
  timer.
- Completed and deferred lessons live under **Settings → Field Notes**, grouped by Writing, Worlds,
  Combat, People and Base. They may be replayed without resetting progress.
- Tutorial state saves after every dismissal/demonstration and never depends on wall-clock time.
- Returning after interruption resumes the current game screen; it does not replay an opening or
  stack several missed cards.
- A screen may show at most one tutorial card. System warnings such as full storage or imminent
  collapse take priority.

## Opening fiction

The first launch uses three brief, tap-advanced text/image beats, each skippable:

1. **There was an Atlas.** Its bindings held many realms in relation to one another.
2. **The Atlas was torn apart.** The known world became scattered pages and places that do not last.
3. **You can still bind a page.** At a small base beside Quill and an empty fire, the next world is
   yours to risk.

Do not show the cult, the destruction's perpetrator, Tam, a completed Atlas or a canonical player
face. The opening establishes loss and the Binder's capability, not answers. The splash art may show
separated fragments or page-like apertures, but should not depict worlds as literal paper dioramas;
the writing binds reality rather than making a toy model.

After the opening, the Base appears with the primary **Bind & Depart** action visually dominant.
Station cards may remain available, but no tour enumerates them before they matter.

## The first binding

Entering the Writing Desk for the first time produces these contextual lessons:

### 1. The page

> **A page is a request, not a blueprint.** Choose a word below, then place its mark on the page.
> Leave anything unwritten and the world will decide it.

The player may place a mark or leave the page blank. Do not force a starter word and do not remove
the full starter vocabulary they genuinely own.

### 2. Page space

Shown only after selecting or placing a first mark:

> **Marks take room.** The number on a word is its footprint. A page cannot hold every request.

Rotation and cluster connection are not explained yet. They receive just-in-time cards on the first
attempt to move/rotate a mark or place a dependent modifier incorrectly.

### 3. The world preview

When the player first opens **The world**:

> **This is what your page can promise.** Written subjects are described directly. Unwritten ones
> remain ranges until you enter the world.

The stability headline gets a separate expandable “What does this mean?” note:

> Stability estimates how long the world can hold together. More demanding writing can buy a rarer
> place at the cost of time. The complete value is saved with the book.

Never call stability a difficulty rating or safety guarantee.

### 4. Binding

The bind button already shows exact essence cost. Its first-use card says:

> **Binding spends essence and opens one expedition.** Returning ends the trip; the book and what
> you learned remain recorded.

No free scripted bind is required. Starting essence must support at least three ordinary low-cost
bindings after any mandatory opening action; verify this through tuning rather than a tutorial-only
currency exception.

## The first world

Teach only the controls required to survive one turn:

1. **Navigation:** “Tap a reachable space to travel there, or use the arrows one step at a time.”
   The minimap is framed simultaneously as orientation, not a second lesson. Auto-travel interrupts
   when something needs attention.
2. **Inspect/interact:** when the current tile first exposes an ordinary action, highlight it.
   “Standing somewhere useful tells you what can be done here.”
3. **Stability:** after the first spent turn, point to the meter. “World actions spend turns. When
   stability runs out the world begins coming apart; it does not end instantly.”
4. **Return:** once the portal is visible/reachable in the current interface, identify it. “Return
   safely to keep the full haul. If the world throws you out, some of it still comes home.”

Do not explain harvesting, sites, pages, flora, hazards and creatures in advance. Their first valid
interaction supplies a one-line contextual card. A discovered page receives priority over ordinary
resource teaching because writing is the campaign spine.

### First encounter

Combat teaches itself only when an encounter begins:

- identify the acting portrait and reachable targets;
- explain the damage triangle only when the player inspects a weapon or protected foe;
- introduce gambits after the player has completed at least one manual encounter, even though Quill
  may already carry starter rules;
- present **Unbind** as retreat before the player becomes trapped in a losing encounter.

The first fight is not secretly weakened by the tutorial. If early world generation needs a safer
encounter envelope, that must be an explicit opening-campaign tuning rule exposed in debug settings,
not an invisible tutorial exception.

## The first return

The exit summary teaches what crossed each persistence boundary:

> **The expedition ended.** Resources and objects came to the Base. Pages, discoveries and people
> you found are remembered in Reality.

Then the Base shows one contextual next-step badge, chosen from actual results:

- recovered writing → **Library**;
- unidentified object → **Storehouse**;
- raw essence with insufficient refined essence → **Workshop/Essence Spring**, using the current
  implemented refining location;
- recruited person → **Firepit**;
- otherwise → **Writing Desk**, inviting a second comparison.

Never show all badges together. The most important unreviewed result wins; the others remain visible
through ordinary station badges.

Opening recovered writing teaches three facts and no solution:

1. every world contains some kind of writing;
2. a named traveller's location passages describe one world where they can be found;
3. the prose is evidence to compare against world descriptions, not a checklist the UI will solve.

If the first writing is not a traveller location passage, explain only its actual type and retain the
traveller-search lesson until the first location passage appears.

## The second binding: comparison

The tutorial's only authored exercise is optional:

> **Change one request and compare.** Write one focus under its subject, then look at The world
> before binding. Everything else may still roll differently.

The player chooses the subject and focus. The game does not prescribe Sun or Mara's signature. On
return, World History offers the previous and current descriptions side by side with the written
marks emphasized. This teaches causality honestly: one requested difference amid several rolled
ones, not a fabricated laboratory result.

## Just-in-time campaign lessons

Later systems teach one decision at their moment of use:

| Trigger | Lesson |
|---|---|
| First complete traveller clue set | Complete evidence guarantees the next world matching that person's signature; it does not reveal the translation |
| Traveller encountered | Talk, invite, and what declining preserves |
| First recruit returns | Firepit chooses who travels; Party holds stats, gear, rank and gambits |
| First station site appears | People enable buildings; build costs are permanent Base commitments |
| First instrument equipped | It measures one subject in the world; it does not alter generation |
| First curio | Unknown objects may be tried, analysed or identified; recognition becomes lasting knowledge |
| First full satchel | Leaving an item is an expedition choice; home storage is separate |
| First collapse | The portal remains the full-haul route while the floor begins to fail |
| Tovin/Anchorage built | Three anchoring routes, one permanent result; sustain resolves only on expedition return |
| First world assignment | Worldwork covers sustain first, then a chosen discovered renewable yield |

Complex stations should include a permanent one-paragraph **How this place works** disclosure rather
than depending on an ephemeral tutorial card.

## Discoverability requirements independent of tutorials

A tutorial cannot rescue unclear normal UI. The live interface should always provide:

- disabled actions with a concrete reason and exact missing requirement;
- source/provenance on unfamiliar materials and crafted previews;
- a visible next effect before consuming essence, a rare item or unique stock;
- station badges for newly available actions, capped at one badge per station rather than one per
  recipe/node;
- an empty-state sentence that names the gameplay route into that screen;
- glossary definitions reached by tapping repeated terms such as Stability, focus, subject, hand,
  tier and Worldwork;
- no unexplained bare numbers where two nearby systems could plausibly own them.

## Tutorial telemetry and debug controls

Without external analytics, the debug menu should expose:

- reset/replay all tutorial lessons without resetting the save;
- mark individual lesson groups unseen/completed;
- current durable trigger facts and the next eligible card;
- opening-safe encounter tuning, if such a campaign rule is adopted;
- starter essence and ordinary bind-cost range;
- a test action that simulates interruption immediately before and after every tutorial dismissal.

## Implementation slices

1. Persist tutorial lesson IDs as seen/deferred/completed and add Field Notes replay.
2. Implement the Writing Desk and first-world essentials only.
3. Add result-driven first-return routing and Library type-aware teaching.
4. Add the optional second-binding comparison in World History.
5. Add first-combat and first-recruit lessons.
6. Add later station/system hooks as those systems become playable.

Tutorial work should begin before the rest of the content catalogue is complete. Every implemented
slice must tolerate a player whose save already passed its trigger: surface the lesson in Field Notes
without hijacking their next launch.

Exact lesson IDs, trigger facts and opening copy for slices 1–2 live in
`tutorial-opening-slices-current.md`; that document supersedes older adjacent-only movement wording.
Exact first-return routing, type-aware Library teaching and honest two-world comparison for slices
3–4 live in `tutorial-return-comparison-slices-current.md`.
Exact first-combat, retreat, gambit and first-recruit teaching for slice 5 lives in
`tutorial-combat-recruit-slice-current.md`.
Exact just-in-time hooks for buildings, instruments, curios, capacity, collapse, anchoring and
Worldwork in final slice 6 live in `tutorial-later-system-hooks-current.md`.
