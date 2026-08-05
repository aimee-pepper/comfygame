# Engineering notes — response to Session 4 + the rune spec

**From:** Claude Code · **To:** Aimee + designer Claude · **Date:** 2026-08-04
**Re:** `decisions-session-4.md` (filed) and `writing-system-rune-spec.md`.

Static travellers make my two session-3 worries evaporate. The writing system is a bigger change
than the slot rewrite, but there's one property in the spec that makes it much less risky than it
looks — §2 below. Three questions I'd want answered before building it, and a sequencing
recommendation at the end.

*(Small bookkeeping: session 4 voids "N1, N2 and N3 from session 4" — I think that means my
session-3 notes, which had an N1 and an N2 and no N3. Reading it as: traveller movement and clue
history are both off.)*

---

## 1. Travellers standing still is a real simplification

No `worldClock`, no deterministic paths, no cadence rules — and the honesty invariant becomes free
rather than something I'd have had to defend with tests. Nothing to build, which is the best kind of
answer. Agreed that the counter pattern stays on the shelf for whenever something genuinely does
need to change between visits.

The cross-referencing clue subset (N4) is also cheap: an optional list of references on a page,
authored only. No relationship graph, no traversal, no inference engine.

---

## 2. The load-bearing property of the writing system: **the page is a budget, not a syntax**

§1.5 and the "no page-wide adjacency effects" rule together say something stronger than they might
appear to. If sigils are assembled internally and neighbours never interact, then:

> **Where a sigil sits on the page never affects what the world becomes. Position is a packing
> constraint and nothing else.**

Which means the whole thing splits cleanly into two independent halves:

1. **The language** — sigils, pressures, implicit secondaries, contradiction, instability, preview.
   Consumes an unordered *set* of sigils. No grid anywhere in it.
2. **The page** — footprints, packing, instruments, compression, drag-and-drop. Consumes a set of
   sigils and answers one question: does this fit?

Those can be built and tested in either order, by different people, at different times. It also
means the simulation can be finished and playable with a plain list-of-sigils UI long before the
tetris page exists or a single rune has been drawn — the art and the packing puzzle stop blocking
anything.

I'd want to lock that property in with a test that asserts **the same sigils in any two valid
arrangements produce byte-identical worlds.** It's cheap now and it's the kind of invariant that
quietly rots the moment someone adds "well, adjacent water sigils could pool…". If adjacency ever
does become desirable, that's a real decision to make deliberately, not to discover.

**One consequence worth naming:** if position doesn't matter, then a page is exactly a *multiset of
sigils plus a proof it fits*. So the save can store the sigil list as the truth and the layout as
presentation — and a page re-written in a better hand is the same page, just re-packed. That's the
"same book, better hand" moment from §2 of the spec falling out for free.

---

## 3. Contradiction has to be measured **gross, not net**

§8's contradiction rule is the part most likely to be built wrong, so, concretely:

"A sun that does not warm" contributes **+heat from the sun's implicit secondary** and **−heat from
the negation**. If instability reads the *net* pressure on Thermal, those cancel to zero and the
page looks like it simply made no thermal statement — the single most interesting thing the player
did becomes invisible.

So each target needs two numbers tracked separately:

- **net** — what the world actually becomes (drives climate, spawns, yields)
- **opposed magnitude** — how much force was applied in conflicting directions and cancelled out

Instability then reads from both origins: **greed** from abundance and value (what I have today),
**contradiction** from opposed magnitude. A world can be perfectly ordinary to stand in and
violently unstable, which is exactly the flavour §8 is reaching for.

Cheap to build if it's designed in from the start; awkward to retrofit once pressures are a single
number per target.

---

## 4. The "attributable" reveal rule is nearly free — because worldgen is already pure

§10's rule — reveal a hidden component when its marginal effect is observable and not masked — reads
like it needs elaborate bookkeeping. It doesn't, given how worldgen is built: it's a pure function
of (page, seed) with no side effects, so I can simply **generate the world twice, with and without
the component, and diff the pressures.** Masking falls out of the arithmetic: if another source
dominates that target, the diff is small, and the component stays hidden. No special-casing.

That's a nice accident of the existing architecture, and a reason to keep worldgen pure as it grows.

Two things it does need:
- **Confidence state per unknown slot**, accumulated across bindings. Reality layer (knowledge is
  never taken back), shaped like `runebook: [compound: [slotIndex: evidence]]`.
- **A threshold** for "observable". Suggest expressing it as a fraction of that target's total
  pressure rather than an absolute, so it behaves the same on quiet and loud pages.

---

## 5. Named places (N5) — two questions I can't answer from the spec

This is the part with the largest save-shape implications, and the one I'd most like pinned down
before it's built.

### Q12. Is Reinehaven the *same instance* every time, or a fresh world matching a description?

"Reinehaven exists independently of the player" and "writing precisely enough links you to
Reinehaven itself" imply a specific place. But worlds are currently instanced and disposable: bind,
visit, collapse, gone.

- **A — Same instance, persistent.** Reinehaven has a fixed seed, and *state* that survives between
  visits: what you harvested stays harvested, what you left is still there. Structurally, a named
  place is an already-anchored world, which is a big deal — it partly answers open-question Q-A by
  the back door, and it needs somewhere in the save for persistent per-place state.
- **B — Same recipe, fresh instance.** Reinehaven has a fixed *signature*, and each visit generates
  a world from it. You return to the same character of place, not the same rocks. Cheap; fits the
  current model exactly; but "her family was in Reinehaven" lands differently if the town is
  re-rolled each time you knock.

I lean **A** for named places specifically (they're few and authored), with everything else staying
disposable — but it's a real design decision about what permanence means, not a technical toss-up.

### Q13. What exactly is "precision", as a number?

"A sufficiently precise description links you to a specific place" needs a metric. Two candidates
that behave very differently:

- **Distance** — how close your page's pressures are to the place's signature. A vague page that
  happens to land nearby would arrive at Reinehaven, which undercuts "precision arrives somewhere
  specific."
- **Coverage** — how many of the place's defining conditions you actually named, and how tightly. A
  page can be close by accident but can't be *specific* by accident.

**Proposal:** require both — within distance **and** above a coverage floor. Then the three tiers in
the spec fall out naturally:

| Your page | Where you land |
|---|---|
| Close, vague | A generic world that *resembles* Reinehaven — traces, weather, maybe a page |
| Close, specific | Reinehaven |
| Far | Somewhere else entirely |

That gives you the "discoverable by accident" behaviour §N5 asks for without letting an accident
substitute for literacy.

### Q14. Do sigils rotate on the page?

Not addressed in the spec, and it changes both the packing puzzle and the UI substantially.
Irregular 4–6 cell crude shapes with rotation is a genuinely different (and much more forgiving)
puzzle than without. I'd default to **yes, free rotation** unless the fiction objects — a rune
drawn sideways is still that rune.

*(Non-question: page size. 6×6 at phone width gives ~60pt cells, which is comfortably above the
44pt floor. The starting size is playtestable without any layout worry.)*

---

## 6. What this does to what already exists

| Area | Impact |
|---|---|
| `slots.json`, `BookDraft`, `BookProjection` | Replaced by the page/sigil model. This is the save-shape change; it's why the slot work was worth doing — it's a data-and-model swap, not an excavation. |
| `symbols.json` | Replaced by runes. Expected; nothing was polished. |
| Instability | Gains a second origin. Needs the gross/net split in §3 above. |
| `BookRules` weighted tables | **Survive.** Pressures become the new input, tables stay the output, so worldgen, fog, decay, banking and encounters are untouched. |
| Preview panel | **Survives structurally.** Spec §1.6 — "cost is exact; outcomes are ranged" — is the rule already built and tested. Unidentified compounds just widen the ranges and add an "unknown influence" marker. |
| Encounters, gambits, world, base, economy | Untouched. |

Nothing built so far needs unbuilding.

---

## 7. Sequencing — my recommendation

**Finish milestone 5 first, then take the writing system as its own milestone.**

Milestone 5 is the economy and payoff pass: Workshop purchases, the identify flow, the key→locked-
cache moment, Motes and the Constellation. It's small, it closes the v0 loop, and it's almost
entirely unaffected — the only touch point is "2 researchable symbols", which becomes "2
researchable runes" with no structural change to the buying machinery.

It's also useful *preparation*: the curio identify flow is a simplified version of §10's
per-component identification. Building the small one first is a decent way to find out what the big
one wants.

Then the writing system as a milestone of its own, in the order §2 implies:

1. Sigil + pressure model, contradiction, instability — no grid, list UI, placeholder glyphs
2. The page: footprints, packing, instruments, compression
3. Compounds and the runebook
4. Unidentified compounds and the confidence meter

That order keeps a playable game at every step, and none of it waits on the 42 drawings.

**Also queued, and cheap:** Library highlighting with no code path from a highlight to a sigil.
Confirmed in session 4. I'll build it that way when the Library exists — and it's worth a test that
asserts the absence, since "no path" is the kind of guarantee that erodes by accident.
