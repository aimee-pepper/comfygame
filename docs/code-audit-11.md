# Code Audit #11 — skills landed (2026-08-06, commit `a4056b7`)

483 tests. **Skills went 2 → 13.** Comparing against the spec I was holding (`skill-effects-spec.md`), which I now think should mostly be discarded.

---

## 1. He built all twelve, plus one

Every skill from `resources-skills-spec.md` §2 is in — Pry, Overbear, Flense, Sight, Ward, Draw Off, Snuff, Quicken, Steady, Rout, Read — plus Unbind and Mend as the baseline pair.

**And the thing I most wanted is there.** Flense scales with the foe's covering:

```swift
let purchase = (foe.traits?.covering.insulation ?? 0) / Tuning.Pressure.scaleMaximum
```

with the failure message written properly: *"there's nothing here to open."* That's the mechanism that makes a skill **answer a kind of creature** rather than just hit harder, and it's the single thing I'd have argued for.

## 2. Where his design differs from mine — and his is better

**I specced eight generic effect kinds plus nine statuses**, on the reasoning that bleed/ward/taunt are all "apply a status" and should collapse into one parameterised kind.

**He built thirteen named kinds**, one per skill, with no status system.

I was wrong, for a reason worth writing down: **my version was a generalisation with one instance of each case.** Nine statuses where five are damage-over-time variants, an `applyStatus` kind used by three skills that share nothing else, a `scalesWith` parameter used by exactly one skill. That's the shape of abstraction that costs more to read than it saves, and it would have made every skill's behaviour indirect — you'd read `applyStatus(foe, bleed, 3, scalesWith: coveringLength)` instead of a `case .bleed` that says what it does in six lines.

**Thirteen explicit cases with comments explaining what each answers is more legible and no harder to extend.** If a fourteenth skill needs a status system, that's the moment to build one.

**So: discard `skill-effects-spec.md`.** Its one live idea — damage scaling on foe traits — is already built, better than I specced it.

## 3. What is genuinely missing, and worth raising

**No statuses exist beyond bleed.** Poison, burn, freeze and shock have no implementation, which matters because **things upstream are already producing them**:

- `emanation` is a creature trait, generated, named in creature descriptions — and an emanating creature currently has no elemental attack
- Toxic flora is specced (`flora-system-spec.md` §6) and will need poison
- Apothecary coatings are specced and will need burn

So the gap isn't "the skill list is short," it's that **elemental and toxic damage have producers and no effect**. That's the next combat piece, and it wants exactly one decision: whether burn/freeze/shock are three things or one *elemental* status carrying its element. **[AIMEE]** — one is simpler and reads fine; three give Ward something specific to turn aside.

**Also still open:** ranks (session 17, wanted), and `reposition` has nothing to reposition until they exist.

## 4. Small note

`SkillDef.Kind` cleanly separates offensive from supportive at the bottom of the enum, which is what lets gambits reason about skills without knowing what each one does. That'll matter when skill-aware gambit conditions arrive.

---

## Priority

1. **Statuses for emanation and toxicity** — producers exist, effects don't.
2. Session 17: stats, levels, ranks, escape item.
3. Per-building trees (Q40, answered).
4. The Exchange (Q41, answered).
