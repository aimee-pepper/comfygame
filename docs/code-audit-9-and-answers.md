# Code Audit #9 + Answers Q35–Q38 (2026-08-05, commit `fa9ffa9`)

471 tests. Content volume from audit #8 partly addressed.

---

## Part 1 — Audit

### Content growth

| Content | Was | Now |
|---|---|---|
| **resources** | 4 | **23** ✅ |
| **items** | 10 | **48** ✅ |
| creatures | 3 | 3 |
| pressure sources | 41 | 41 |
| **skills** | **2** | **2** ⚠️ |

**Resources and items are handled.** `resources-skills-spec.md` proposed ~21 resources and 23 landed.

**Skills are still two**, and they're the other half of that spec. The player side of combat remains two buttons while foes have trait-derived armour, damage character, retaliation and elemental attacks. This is now the single biggest imbalance in the game — and session 17's stats and classes will make it worse, because a class with no distinct skills isn't really a class.

**Pressure sources still 41 of a specced 79.** Q30 (Relief's own words) is part of this.

### Session 17 not yet reflected

No stats, no levels, no XP, no ranks, no escape item. Expected — just handed over.

---

## Part 2 — Answers

### Q35 — Rarity as the reforge ceiling — **as built (option 1)**

Rarity capping upgrades is the genre standard and it's the only option where finding a mythic stays an event. Option 3 (no ceiling, rising costs) sounds generous but in practice the curve becomes the real ceiling and it's less legible than a stated one.

### Q36 — One property per slot — **as built, with one addition**

The mapping is sensible and giving every property a job is the right instinct.

**For insulation and reactivity, don't wait for new slots — give them *secondary* effects on existing gear.** A body or feet piece made of high-insulation material should resist thermal hazards; a weapon made of high-reactivity material should carry a status effect. That way the reforging property stays one-per-slot and legible, while the other properties still make a specific material worth choosing.

This also connects gear to world conditions: a cold world is one you dress for. **[PROPOSAL]**

### Q37 — Tannery taking capacity upgrades off the Workshop — **[AIMEE], and I'd say yes**

Session 12 decided crafting buildings come from **people, not research**. Satchel and storehouse capacity being research-bought is a leftover from before that decision.

Moving them to the Tannery makes *finding a tanner* a concrete moment with a payoff you can feel, which is exactly what session 12 was for. It's a real move of an existing system, so it's Aimee's call — but leaving them in research keeps a system that the design has already moved past.

Not shipping dead buttons was right.

### Q38 — Teeming Life producing a median vitality of 8 — **option 1, with a refinement**

This is a good catch and it's wider than it looks: vitality feeds the creature cast, butchery, flora, and every organic resource, so a median of 8 is very likely part of why play reads samey.

**The fix is option 1: consumers stop subtracting from vitality.** They add `trophicDepth` and take nothing off `peak`.

**Why, beyond convenience — the current model is biologically backwards.** Consumers *are* biomass. A world with herds and swarms in it holds **more** life than one with only plants, not less. Productivity limits how much a web can support; it isn't reduced by the things it supports.

**The refinement that keeps the model honest:** producers set a **ceiling on trophic depth**, so a page of nothing but consumers can't produce a rich world with nothing to eat. Consumers add depth *up to* what producers can carry, and contribute their own biomass within it.

That gives two clean, separately-meaningful readings:
- **Vitality** — how much life is here
- **Trophic depth** — how complex it is, capped by what the producers can feed

Option 2 (split the symbol) also works but leaves the same backwards subtraction in place elsewhere. Option 3 papers over it.

**Also worth checking once this lands:** the same pattern may exist in other symbols whose expansion mixes characters that pull against each other. Worth a sweep rather than a single fix.

---

## Priority

1. **Q38 vitality fix** — it's upstream of the cast, butchery, flora and every organic resource.
2. **Skills, 2 → 10+** — the biggest remaining imbalance, and session 17's classes need them.
3. **Session 17** — stats, levels, ranks, escape item.
4. Pressure sources toward 79, including Relief's own words (Q30).
