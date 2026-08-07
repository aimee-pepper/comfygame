# Code Audit #12 (2026-08-06, commit `6e6818c`)

486 tests. World history is built, and the Scale trap is fixed at the source.

---

## 1. World history — built, and better than specced

`VisitedWorld` records the seed, the run index, the prose you were shown, **the chains you placed**, every target's peak and floor, and who was standing in it. Keepable, erasable, capped — and **a kept world is never dropped.**

**What you can read of it grows with your analysis tier**, which is the part that makes it an answer key rather than an explanation.

**Two things he added that I didn't spec, and both are better than what I wrote:**

**`inertRungs` — a rung written where it changed nothing.** Recorded explicitly, per world. That's the *"vast sun"* failure preserved as evidence, so when you can finally read it you don't have to infer that something did nothing — the record says so directly. His comment calls it *"the thing you most want to find later,"* which is right.

**Marking each reading with whether you wrote it or the world rolled it** — a pencil or a die. That's the actual question a failed deduction has, and I'd framed it too vaguely: not *"what did I write"* but *"what got me."* Seven of eight targets never being yours is the thing you need to see.

## 2. The Scale trap — fixed at the right level

Rather than wiring Scale to do something on every source, the palette now **only offers a qualifier where it applies**: generic ladders in the shared modifier section, narrow ones like Scale in their own target's section. His comment names the failure precisely — *"offering it beside a Sun is how 'a giant sun' became a thing you could write that did nothing at all."*

**That's the better fix.** I'd offered two options — wire it or hide it. Hiding it *per source* rather than globally means the qualifier still exists where it's real, and can't be written where it isn't. The bug class is gone rather than the symptom.

## 3. Still outstanding

**The hands.** Recorded as a *state of the code*, not as something owed: `pen_pencil` is 30 essence and 6 fibre with no `station` field. **`hands-and-calligrapher-spec.md` had not been handed over when this audit ran**, so there was nothing to action. Included only so the audit describes the build accurately.

**No statuses beyond bleed** (audit #11). Emanation, toxic flora and Apothecary coatings all have producers specced or built and no effect to produce.

**Session 17 not yet in** — stats, levels, ranks, escape item.

**Per-building trees (Q40) and the Exchange (Q41)** — both answered, neither built.

---

## Priority

Things with specs already in hand:

1. **Statuses for emanation and toxicity** — producers exist, effects don't.
2. Session 17: stats, levels, ranks, escape item.
3. Per-building trees (Q40); the Exchange (Q41).

Arriving with this handoff, not previously available: the hands and the Calligrapher.
