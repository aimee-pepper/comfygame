# Decisions Log — Session 15 (2026-08-05)

Append to `docs/decisions-log.md`. Aimee's decisions. Answers §9 questions 3, 4 and 5 of `generation-spine-spec.md`.

---

## 1. Two levels: a CAST of species, then individual variation

Variety is not one number. A world has a **small cast of distinct species**, and each species has **individual jitter** within it.

- **Cast**: a world samples a handful of trait vectors from its distributions. Those are its species.
- **Jitter**: every actual spawn is its species plus **small variation — mostly coloration and minor form.** Never enough to change what it is or how it fights.

So you meet the same few animals repeatedly, and each one you meet is visibly its own animal. On a scale where 1 is "every mob identical" and 10 is "every mob different," this sits at **3–5**.

**This is what the bestiary's two tiers were waiting for:** the **species** is the entry; individual spawns are **specimens** under it. Species come from the world; specimens come from the jitter.

## 2. Vitality controls cast SIZE, not SPREAD

**Richer worlds hold more species. They do not hold stranger ones.**

A rich world might carry six species where a barren one carries two — but those six are drawn from the same distribution and are no more exotic than the two. **Spread stays governed by the pressures that shape the distribution itself.**

**Consequence worth protecting: abundance and strangeness are independent knobs.** You can write a teeming ordinary world or a sparse bizarre one, and those are different places for different reasons. A single variance number would have collapsed them into one.

## 3. Anchored worlds keep their cast permanently

Anchor a world and its species are fixed forever. The same animals live there; you learn them.

A species you've only ever seen in *your* anchored world is meaningfully **yours** — which is a reason to anchor beyond resource yield.

## 4. FREE SAMPLING — identity is derived, never imposed

Traits are rolled straight from the world's distributions. **No role is decided in advance.** What the creature *is* — ambusher, tank, grazer — is read off the traits afterwards.

**Why, in Aimee's words: not every world is going to have predators or grazers or scavengers, and it doesn't make sense to decide that before the world pressures.** Assigning roles from a list would smuggle Earth's ecology into worlds that were never meant to have it. If nothing grows, nothing grazes.

**This is safe specifically because the cast is small.** Free sampling with fifty creatures per world would pile up incoherent results; with three to five species, a strange one is the animal you remember from that world.

**Consequence: the food web is derived too.** Trophic depth comes from Vitality, so a barren world might produce three things that all subsist on mineral or light rather than on each other, while a rich one develops layers. The causal model runs at the ecosystem level, not just the individual.

---

## Consequences for `generation-spine-spec.md`

- §3 "Life" — sampling is **two-stage**: draw the cast from distributions, then jitter per spawn. Cast size is a function of Vitality.
- §9 Q3 (variance magnitude) — **answered**: it isn't one number. Cast size and jitter are separate, and jitter is deliberately small.
- §9 Q4 (branch weights) — **answered by implication**: with a small cast, a cold world will naturally show one or two of cold's four answers rather than all of them. Which ones is per-world contingency, and that's desirable.
- §9 Q5 (identity constraining sampling) — **answered**: free sampling, identity derived.

## Still open from §9

1. Ground-type list (ten proposed).
2. Whether elevation is worth having, or openness suffices.
3. Energy budget severity.
4. Whether Cycle amplitude driving trait variance is clever or confusing — **note this now interacts with §1**: it would presumably widen the *cast* draw rather than the jitter.
