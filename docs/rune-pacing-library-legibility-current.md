# Rune pacing and Library legibility — current design

**Status:** Current structure; pity probabilities and floor are playtest placeholders.  
**Scope:** Vocabulary needed for traveller hunts, acquisition protection and Library feedback.

## The next needed word

Pity targets exactly one word at a time: the first unowned entry in the authored `pityFocuses` list
of the earliest known, unrecruited traveller by global `authoredOrder`.

`pityFocuses` is not inferred from numerical signature thresholds. Many different focuses can push a
reading across the same threshold, and an inference would silently decide that one solution is
canonical. Each traveller instead authors a short ordered list of non-exclusive focuses that make
their hunt deliberately writable at the intended campaign point.

Rules:

- entries must be ordinary multi-route vocabulary (`worldDrop`, research or future merchant), never
  diary-, quest- or story-exclusive;
- a list includes only genuine capability gaps, not every useful optimization;
- the traveller must already be known through a page/relationship lead before their list can become
  active;
- if every entry is owned, there is no pity target even if the player has not solved the clue;
- random companions and Tam's held design do not enter this queue.

This makes the cast order the pity order without turning every unowned rune into a warmed-up pool.

## Authored pity lists

These lists target only the non-exclusive capability words that materially open the intended hunt.
An empty list means starter/earlier guaranteed vocabulary already provides a deliberate route; it is
not an omission. Later entries are considered only after earlier ones are owned.

| Order | Traveller | `pityFocuses` | Reason |
|---:|---|---|---|
| 1 | Mara | — | Sun/start vocabulary writes the single condition |
| 2 | Edren | — | Granite/Ice routes are available at start |
| 3 | Halloway | — | Starter heat and ductile substrate suffice |
| 4 | Isolde | — | Her two raised thresholds remain starter-writable |
| 5 | Sela | — | Starter hydrology and ordinary routes suffice |
| 6 | Bryn | — | All three routes are starter-writable |
| 7 | Orsa | — | Hush is earlier diary-guaranteed, not pity-eligible |
| 8 | Vance | — | Starter seams/pockets/open terrain provide routes |
| 9 | Talin | — | Starter hard/open/bright composition |
| 10 | Nessa | `sulfur` | First intentional volatile-substrate route |
| 11 | Corrin | — | Starter living/wind/rain composition |
| 12 | Dagg | `tide` | Opens the required high cycle amplitude |
| 13 | Rook | — | Hush is earlier diary-guaranteed; other routes are starters |
| 14 | Lys | `orrery`, `crystal` | Exact cycle, then persistent light floor |
| 15 | Bracken | — | Starter Ice/Sun/Granite/Cloud routes |
| 16 | Fen | `orrery` | Exact recurring interval |
| 17 | Wren | `tide` | High cycle amplitude |
| 18 | Kestrel | — | Starter ecology plus earlier Hush |
| 19 | Maud | `orrery` | Exact recurring interval |
| 20 | Marrick | `orrery` | Formation-count regularity |
| 21 | Sabine | `orrery` | Repeated care routine |
| 22 | Grimmond | `thin_air` | Deliberately low atmosphere peak |
| 23 | Oda | `crystal`, `orrery` | Persistent light, then exact testing interval |
| 24 | Auber | `tide`, `mist` | Separation cycle, then retained vapour |
| 25 | Ashe | `tide` | Bodily variation across a strong cycle |
| 26 | Tovin | `orrery` | Exact time; Hush/Ruin-like needs are earlier diary knowledge |
| 27 | Perren | `mist`, `orrery` | Context-obscuring distance, then coercive repetition |
| 28 | Nine | — | Drift/Hush are earlier diary-guaranteed; other routes are established |
| 29 | Tam | **held** | No pity entry until Tam's signature and act are settled |

Stable IDs above match current content. A future roster insertion receives its own list and shifts
order without rewriting already-earned vocabulary.

## Escalation and hard floor

When an expedition resolves and the active target is still unowned, roll the target grant at:

| Consecutive unresolved expeditions | Chance |
|---:|---:|
| 1 | 10% |
| 2 | 25% |
| 3 | 40% |
| 4 | 55% |
| 5 | 70% |
| 6 | **100% hard floor** |

The granted fiction is a legible rune trace recovered with the expedition's records, not an item
that consumes a satchel slot. Return and collapse both count because failed sessions must still
advance something permanent. Abandoning a world before taking any world turn does not count.

The counter resets when the target is acquired by any route or when recruitment advances the
authored traveller target. It does not reset merely because another rune was found, a different book
was written, the app was closed or a run collapsed. If content migration invalidates the target,
recompute it and preserve the current count up to the new floor rather than erasing dry progress.

Pity supplements normal wild/research/merchant acquisition and never removes those routes. Exact
rates and the six-world floor are debug-exposed.

## Library marker

The Library continues to present prose, not a translated condition checklist. For each recovered
location passage, it may append one of three literacy states derived by a reachability solver using
the currently owned vocabulary and current hand:

- **Writable:** the known passage can be deliberately satisfied by at least one legal composition.
- **Not yet writable:** no owned composition can deliberately satisfy it at the current hand.
- **Unknown:** the Library lacks enough passage information to assess it.

Player-facing copy for the second state:

> **You do not yet have the words to ask for this reliably. Chance may still write it.**

The marker never names the missing rune, target, threshold or solution. It tells the player that the
problem is vocabulary rather than a bad interpretation while preserving translation as gameplay.
“Reliably” matters: under-specified worlds can still roll the needed condition, and accidental
traveller meetings remain valid.

The whole traveller page also shows a compact summary such as **“4 passages recovered · 1 not yet
writable”**. It does not reveal whether unrecovered passages will need additional vocabulary.

## Reachability test

The solver asks only whether at least one composition of owned atomic focuses and legal known
modifiers can satisfy the single revealed signature condition within current page/hand constraints.
It does not require simultaneously solving the traveller's whole signature, spend essence, predict
random fill, or recommend an optimal book.

Because this is player guidance, every authored signature condition and `pityFocuses` entry needs a
fixture proving:

1. the intended pre-word state is marked not yet writable;
2. acquiring the target word makes it writable with a legal page;
3. no diary-exclusive word is required before its owner can be found;
4. a different valid solution is accepted where one exists.

## Acquisition guardrails

- Starter vocabulary is reconciled upward on old saves and never removed.
- Diary-exclusive focuses cannot enter caches, merchants, research or pity.
- End-of-branch and future story-exclusive focuses do not enter pity unless their route is itself
  guaranteed before the relevant traveller.
- A cache may continue to award any eligible unowned focus; pity is a separate expedition-resolution
  guarantee and does not consume the cache's normal reward.
- Once learned, a word remains writable forever under the finality rule.

## Save data

Store `pityTarget`, `pityTraveller` and `unresolvedExpeditions` in Reality alongside permanent
vocabulary knowledge. Decode all fields tolerantly. The target is cached for stable progress but
validated against current authored order and ownership on load.
