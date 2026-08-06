# Code Audit #4 (2026-08-05, commit `52d0c15`)

343 tests. `LifeRules` and `CreatureTraits` are in. **One significant finding: the creature system is built but not connected.**

---

## 1. Built

**`CreatureTraits`** — twelve scalars: `size · build · covering · coveringHardness · boneDensity · reach · armament · conspicuousness · ornament · vision · nonVisualSense · emanation`, plus a derived `appetite`.

**`LifeRules`** — the whole session-15 model: `cast(for:seed:)`, `castSize` from Vitality only, `spawn(of:rng:)` for jitter, distributions nudged per pressure, and budget rejection so no species exceeds what the world can feed. Deterministic in the world seed, so **anchored worlds keep their cast**.

The doc comments are faithful to the decisions, including the abundance-versus-strangeness distinction.

## 2. THE FINDING — sampled species never reach a world

**`Worldgen` does not reference `LifeRules`, `Species`, or `cast` at all.** It still populates enemies from `BookRules.enemyTable(from: readings)`, which filters the **authored** `creatures.json` by appetite.

So the generator produces a cast that nothing spawns. The system is complete and inert.

Two consequences while it stays disconnected:
- Traits are computed but never seen, so nothing validates whether the distributions produce interesting animals.
- The authored-creature path is still the real one, which means `creatures.json` remains load-bearing and the trait system is a parallel structure — the same shape of problem the pressure model had two audits ago.

**Also still unwired:** combat reads no traits (`CombatRules` has no `traits` reference), and loot derives from nothing.

## 3. Simplifications from the spec — mostly fine, two with consequences

He collapsed several structures. Sensible for v1, but two lose something downstream:

| Spec | Built | Consequence |
|---|---|---|
| `armament` as a **pierce/crush/rend triangle** | single scalar | **No damage types, and no fang/tusk/claw distinction in loot.** The materials spec derives three different materials from the three corners; with one scalar there's one weapon material. |
| `covering` as **hardness × length × coverage** | `covering` + `coveringHardness` | **Fewer materials.** Plate/quill/pelt/down/hide/chitin needed all three axes; two axes can't separate quill from plate, or pelt from down. |
| `coloration` as a **CMY triangle** | `conspicuousness` scalar | Crypsis versus aposematism still works — but **colour can't be inherited into materials**, so no prismatic hides, and no "cryptic *in the ambient spectrum*". |
| appendages · finish · delivery | absent | Deferred cleanly; nothing depends on them yet. |

**Recommendation:** restore the armament triangle and covering's third axis **before loot derivation is built**, since both exist specifically to make loot varied. Colour can stay collapsed longer, but it's what makes materials *look* like where they came from.

## 4. Naming — his own flag, and it's a real gap

`CreatureIdentity.name` is a fall-through ladder returning single words: *lantern · bulwark · ambusher · courser · hunter · herald · drifter · browser · groper · creature*.

That's the identity **class**, which is right — but it's the only name a creature has. Every armoured thing in the game is "bulwark," and anything unmatched is literally "creature."

The spec called for **composed descriptive names for unmatched species**, and I never designed the composer. His commit message flags the same gap for creatures, flora *and* items. Addressed in `name-generation-spec.md`.

---

## 5. Priority

1. **Wire `LifeRules` into `Worldgen`** — the cast must actually spawn. Everything else about creatures is unvalidated until it does.
2. **Restore the armament triangle and covering's third axis** before loot derivation.
3. **Combat from traits** — retire flat stats.
4. **Loot from traits** — retire drop tables.
5. **Naming** (see the naming spec).
6. **Flora** — spec just handed over.
