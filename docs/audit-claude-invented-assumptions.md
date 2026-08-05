# Audit — Claude-invented assumptions stated as settled

**What this is.** The page-size error (page grows via unlocks) was invented by Claude, written as fact, and then built on. This audit looks for the same failure everywhere else: **things stated flatly in the specs that Aimee never decided, and that other decisions now rest on.**

`[PROPOSAL]`-tagged items are excluded — those are visibly provisional, and there are 58 of them across the docs. **What follows is the more dangerous category: assertions written without any tag at all**, which read as decided.

Ordered by how much rests on them.

---

## Tier 1 — load-bearing, other decisions already depend on these

### 1.1 The three-hand ladder maps to specific footprints
"Crude 4–6 cells · Plain 2–3 · Refined always 1×1."

The *concept* (finer instruments write smaller) is Aimee's. **The specific footprint numbers, and that refined is exactly 1×1, are Claude's.** Session 10's "seven sigils crude, thirty-six refined" arithmetic — and the argument that the page needn't grow — rests entirely on these numbers. If refined is 2 cells rather than 1, that argument weakens considerably.

### 1.2 Sigil grammar is `[qualifiers] → source → Bind → target`
The whole composition model. Aimee said sigils should be self-contained and gave the example of sun connecting to illumination. **The formal four-part grammar, the Bind rune, and the notion that a sigil binds to exactly one target are Claude's.** Everything in the pressure model assumes it.

### 1.3 There are exactly 8 targets, and they are these 8 — **CONFIRMED (Aimee, 5 Aug 2026)**

Settled and intentionally load-bearing. See `decisions-log.md`.
Illumination, Thermal, Hydrology, Substrate, Relief, Vitality, Atmosphere, Cycle. **Claude's list**, pruned from a research candidate set. Aimee never picked these. All 41 built pressure sources, every description clause, and the entire contradiction catalogue key off them.

### 1.4 Only Illumination and Thermal are two-valued
Aimee answered "only for light and temperature" to a question **Claude framed** as peak/floor. That the other six are single-valued follows from Claude's framing, not from a separate decision.

### 1.5 Essence remains the per-bind consumable alongside page space
Stated flatly. Aimee decided page space is a real constraint; **that essence continues as a parallel cost was never confirmed.** The whole economy assumes it.

---

## Tier 2 — structural, built or being built on

### 2.1 The qualifier vocabulary — 51 runes across 10 categories
Intensity 5, Scale 4, Count 5, Constancy 4, Elevation 4, Direction 4, Phase 4, Distribution 4, Colour 12, Finish 5. **Entirely Claude's**, presented as a list rather than a proposal. Aimee has audited sources but never these.

### 2.2 The structural rune set — Bind, Duplicate, Negate, Except, Group, Dominant, Trace, Then, Anchor, Terminus, Wild
**Claude's.** Contradiction depends on Negate existing; chance-fill depends on Wild.

### 2.3 Modality tags as a concept
That targets emit non-scalar qualitative tags (*sourceless*, *two-storey*, *banded*) which downstream systems read. **Claude's invention.** Description generation and several cross-target constraints use them.

### 2.4 Iridescence requires light peak > 40 **and** hard layered covering
A hard gate connecting three systems. Drawn from real biology, but **the coupling and threshold are Claude's.**

### 2.5 "Greed" instability comes from *valuable* sources, and sunlight isn't loot
The rule distinguishing which sources contribute to greed. **Claude's.**

### 2.6 Unidentified compounds: the attributable-reveal rule
That a component reveals when its effect isn't masked by another source on the same target, and that this makes sparse pages laboratories. **Claude's whole design.** Aimee asked for "glean the unknown components"; the mechanism is invented.

---

## Tier 3 — invented but lower blast radius

- **Site categories** (recent ruin / old ruin / landmark / living / hazard / anchor point) — Claude's taxonomy; now in `sites.json`.
- **Site rarity from condition narrowness** rather than a rarity tag.
- **Six material properties** (hardness, density, flexibility, insulation, reactivity, lustre) and the Organic/Mineral + Toxic flags.
- **Three crafting buildings** keyed to material families; **four gear slots**.
- **The energy budget** — that every creature draws size, armour, insulation, weapons and ornament from one pool scaled by productivity.
- **Cross-target constraints** as a list (dry caps life, poor caps size, freezing converts standing water). Individually defensible, collectively Claude's.
- **Source "characters"** per target (cyclic/constant/occluding · producing/retaining/sinking · standing/flowing/frozen/airborne).
- **Dispersion** as a shared axis across Hydrology, Substrate, Vitality.
- **Grade as dual percentiles** against nature and against your own finds.

---

## What to do with this

Nothing here is necessarily wrong — several are probably right. The problem is that they read as settled and are being built on.

**Suggested handling:**
- **Tier 1** deserves explicit review, especially 1.1 (the footprint numbers, since the page-size argument depends on them) and 1.3 (the eight targets, since everything keys off them).
- **Tier 2** can be reviewed as it comes up in build order.
- **Tier 3** can wait, but should be re-tagged as proposals in the docs so nobody treats it as decided.

**Process fix:** Claude should stop writing invented material as flat assertions. Anything Aimee hasn't said gets marked, every time, without exception — including things that seem obvious or that follow naturally from something she did say.
