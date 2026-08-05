# Engineering notes — response to Session 2 decisions

**From:** Claude Code (engineer) · **To:** Aimee + designer Claude · **Date:** 2026-08-04
**Re:** `docs/decisions-log.md` § "2026-08-04 — Session 2", now filed in the repo.

Self-contained by design (per `WORKFLOW.md`) — everything needed to discuss this is below, no chat
history required.

**Two things need an answer.** Everything else is decided and I can build it. Skip to
[§4](#4-two-things-i-need-back) if you want just those.

---

## 1. Where the build actually is

Milestones 1–3 are committed and working. 67 tests pass. Force-quit/resume verified in the
simulator, including mid-encounter and mid-run; still wants one pass on Aimee's actual phone.

| Built | Notes |
|---|---|
| Three-layer save (Reality / Base / Worlds) | Atomic debounced writes; every state change goes through one function and is saved |
| Seeded deterministic worldgen | Same seed rebuilds the same world; RNG position survives a kill, so a force-quit isn't a re-roll |
| Base hub + Writing Desk + pre-bind projection | Station list is data-driven; projection shares its code with the bind, so it can't drift |
| 14×14 world: fog, movement, harvesting, hazards, crumbling, collapse, banking | D-pad is the primary control — a 14×14 grid can't give every tile a 44pt target |
| Encounter-flag registry (bestiary) | In the Reality layer; drives silhouette→revealed in the preview |
| Encounters, gambits, Workshop/Storehouse/Constellation spending | **Not built** — milestones 4–5 |

The full loop is playable end to end apart from real combat, which is currently a placeholder
"fight one round" button.

---

## 2. The redesign heads-up: cheap, and well-timed

Nothing built so far is expensive to unwind. Concretely, the four-slot-type assumption lives in
**three places** — `SymbolSlot.allCases` in the book resolver and in the projection, plus the enum
itself — and it touches **three save fields** (`BookDraft.slots`, `BoundBook.symbols`,
`BoundBook.randomlyFilled`). That's an afternoon's work, not a rewrite.

It's also the right moment: the app hasn't been installed on Aimee's phone yet, so there are no real
saves to migrate. Doing this now is nearly free; doing it after a week of play means writing a
migration.

**Why the rest survives the redesign.** Worldgen and combat don't consume symbols — they consume
*weighted tables* ("give me a resource", "give me a creature"). Whatever computes those weights can
change completely — per-creature modifiers today, pressure-driven distributions tomorrow — without
the map generator, fog, decay, banking or encounters noticing. That seam is why the "unaffected and
safe to keep building" list in the decisions log looks right to me.

**What I'll do:** make slot count and types content-defined (a `slots.json` entry with an id, a
display name and an order), and store books as slot-id-keyed rather than enum-keyed. No hardcoded
slot count anywhere in storage, UI, validation or the save format. The Constellation "+1 slot"
unlock stays unresolved and unpurchasable, as instructed.

---

## 3. The flat-rate answer changes the UI more than I think was intended — for the better

**Decision 1** says empty slots cost a flat cheap rate *regardless of what rolls*, and to "keep
quoting the worst case on the Bind button, but quote the actual (discounted) charge."

Here's the thing: with a flat rate, **the cost stops being a range at all.**

    cost = base + Σ(chosen symbols) + (empty slots × flat rate)

Every term is known while you're still composing. There's no worst case left to quote — the Bind
button shows one exact number.

I think that's strictly better, and it makes the "precision costs, serendipity is cheap" principle
visible in the moment: clear a slot and watch the price *drop*. It also sharpens the split the
projection panel is trying to draw — **the price is certain, the world is not.** Stability, danger
and yield stay ranged, because what rolls still shifts instability, so the panel keeps its honest
"you know the bounds, you don't know where in them you'll land" while cost becomes a single
committed number.

Before: `Bind & Depart — 19–28` · *"You'll be charged what the finished book comes to — at most 28."*
After: `Bind & Depart — 14` · *"Costs 14 essence of your 40."*

**One knob to set.** For "serendipity is cheap" to actually bite, the flat rate has to undercut the
cheapest symbol, which is currently 2 essence. I'll place it at **1** as a `// PLACEHOLDER` in
`Tuning.swift`. If it should scale with something (slot type, book size, progression) rather than
being a constant, say so — a constant is the simplest thing that satisfies the stated principle.

---

## 4. Two things I need back

### 4a. What does a bestiary entry key off, once creatures are generated? ← the important one

Discovery lives in the **Reality layer** — the one thing a reset never takes back (decision 4).
Today it's keyed by `CreatureID`, an authored catalog entry. Under part-by-part generation there is
no authored creature.

The note says coherent part combinations "resolve into recognizable identities," so there *is* a
stable identity concept — but I need to know what the durable **key** is, because two things hang
off it:

1. **It's permanent.** If the identity scheme shifts later, lifetime records break in the layer
   whose entire promise is that nothing breaks. This is the only part of the redesign that reaches
   into the permanent layer.
2. **"Have I met this before?" becomes a similarity question**, not a dictionary lookup. That's
   different code and a different *feel*. Is an ambusher with different colouration the same
   bestiary entry, a variant of it, or a new one? That choice decides whether the collection reads
   as a tidy set you can complete, or an open-ended field journal you keep adding to. Both are
   good; they're not the same game.

Sub-question with the same root: the pre-bind preview currently promises "silhouette until
encountered, then real icon + likelihood + expected ratio." Under generated creatures, what does the
preview show for something the world *might* assemble but that no one has ever seen — a silhouette
of what, exactly?

**Not blocking.** I'll keep discovery keyed by a `CreatureID`-shaped string, which survives whatever
you land on. But it's worth deciding deliberately rather than by default.

### 4b. Confirm the cost display

See §3. If "one exact number on the Bind button" is right, I'll build it. If you intended costs to
stay uncertain in some way I've missed, tell me what varies and I'll model that instead.

---

## 5. A forward-compat catch for Milestone 4

Right now a foe looks up its attack stat from the content catalog mid-fight
(`ContentCatalog.shared.creature(id)?.attack`). Under generated creatures there is nothing to look
up.

So I'll build encounters such that **a foe carries its own resolved stat block in the save**, rather
than a pointer into a catalog. Cheap now, genuinely annoying to retrofit, and it buys a real
property for free: a fight you force-quit mid-round still resolves correctly even if the generation
rules change underneath it between builds.

Same reasoning will apply to loot once items derive from trait vectors — an item instance in a save
should carry what it *is*, not a reference to a definition that may be regenerated.

---

## 6. Already correct — no work needed

- **Motes losable in collapse** (decision 5) — that's how it works; unbanked motes are lost like any
  other haul.
- **Entry portal doubles as an exit** (decision 6) — as built, plus 1–2 further portals per world.
- **Eleven starter symbols** (decision 3) — shipped.
- **Bestiary in the Reality layer** (decision 4) — shipped; see 4a for the forward risk.

## 7. Satchel decoupling (decision 8)

Straightforward: a separate, smaller carry capacity with its own upgrade track, independent of
Storehouse tiers.

Worth flagging the sequencing — the "keep or leave it" pressure needs a drop/swap moment when the
satchel is full, and **items don't drop in worlds until milestone 5**. So the capacity split lands
now and the decision UI lands alongside the things there are to decide about. Until then the split
is real but invisible.

One open detail I'll pick a default for unless told otherwise: resources (ore, fibre, essence) are
stackable and slot-free, so the satchel limit only ever bites on *items*. If carry pressure is meant
to apply to raw materials too, that's a different and much more aggressive design — say so and I'll
model it.

---

## 8. What I'm doing next, in order

1. **Data-driven slots** — first, because it's a save-format change.
2. **Flat-rate pricing** — pending §4b, though I'll build it as an exact number unless told otherwise.
3. **Satchel decoupling.**
4. **Milestone 4** — encounter screen, gambit engine, out-of-combat gambit editor, manual override.

Nothing in the redesign blocks milestone 4. Nothing here is waiting on an answer to start.

---

## Appendix: what's cheap to change vs. expensive

Useful when weighing design options — a rough guide to what a decision costs me.

**Cheap (data or one file):** any gameplay number (all in `Tuning.swift`); symbol/creature/item/
gambit/station definitions (JSON); adding a base station; adding a tile type; changing decay
curves, thresholds, spawn rates, vision rules, banking fractions.

**Moderate (one system, no save impact):** how weights are computed from a book; enemy AI behaviour;
pathfinding rules; what the projection panel shows; adding a new screen.

**Expensive (save format — best decided before the app is on a phone):** anything that changes the
*shape* of stored state. Slot structure (doing it now), what identity a bestiary entry keys off,
whether items are instances or references, whether party members become a list.

**Very expensive (violates a pillar, would need the pillar revisited):** anything requiring
wall-clock time, real-time input, or state that can't be serialised mid-action.
