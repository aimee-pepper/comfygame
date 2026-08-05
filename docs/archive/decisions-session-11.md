# Decisions Log — Session 11 (2026-08-05)

Append to `docs/decisions-log.md`. From Aimee testing the page-grid build.

---

## 1. THE DESCRIPTION RULE — absolute

**A description may reveal nothing the player did not directly place.**

Currently a description appears **before any runes are placed at all**. That's the leak in its purest form: the panel is describing a rolled world.

The rule, stated fully:

- **While composing:** the description derives **only** from runes actually on the page. Place nothing, get nothing — a blank page has no description. Place three runes, the description speaks to those three and is silent on everything else.
- **Rolled values are never surfaced pre-departure.** Not as text, not as a hint, not as a stability number that only makes sense if you know what rolled.
- **Two things unseal it:** anchoring the page before entering, or having visited. After either, the rolled values are known and the description may show them in full.

That second part is the useful nuance: **anchoring or visiting is the reveal trigger.** A world you've been to has no secrets; a world you haven't written and haven't seen has nothing but secrets.

## 2. The palette must be sectioned

Runes are currently presented as one undifferentiated box of everything. They need **sorting into sections** by category, so the palette reads as a vocabulary rather than a pile.

## 3. EXCLUSIVITY AND CHAINING — new mechanic

**One main choice per category, then modifiers.** You cannot place multiple land-defining runes in the same book. Same for the other categories: one primary, and then whatever modifiers you like.

**Chaining is an unlock.** An **advanced chaining rune** lifts the restriction for its category, letting you combine multiple primaries — multiple lands in one world, and so on.

Why this matters beyond tidiness: it makes the early game *legibly constrained* (one land, one climate, then decoration), and it turns "a world with two kinds of land in it" into an earned capability rather than something you could always do. It also mirrors the source grammar this design took from — one biome controller, one terrain controller, everything else layered on.

### Answered

**"Category" = pressure target.** Exclusivity is **one primary source per pressure target**, plus unlimited modifiers on each. The eight targets:

| Target | Governs |
|---|---|
| **Illumination** | Light: how much, from what, when |
| **Thermal** | Temperature |
| **Hydrology** | Water: how much, what form, where |
| **Substrate** | What the ground is made of |
| **Relief** | The shape and openness of the land |
| **Vitality** | How much life the world supports |
| **Atmosphere** | Air: density, wind, weather |
| **Cycle** | Time: day length, seasonality, constancy |

So: one thing making light, one thing shaping the land, one thing setting the climate — then decorate.

**Chaining is a SINGLE unlock for now**, lifting the restriction across all targets at once. Per-target chaining runes remain possible later if the single unlock proves too blunt.

**The palette's sections (§2) should be these same eight targets**, so the vocabulary's organisation and its grammar are the same thing.

### Standing caveat

These eight targets are on the tier-1 list in `audit-claude-invented-assumptions.md` — Claude pruned them from a research candidate set and stated them as settled without asking. They are now load-bearing for exclusivity, the palette, all 41 pressure sources, every description clause, and the contradiction catalogue. **Cycle is the weakest**: it has few sources of its own and mostly describes what other targets are doing. If the target list changes, exclusivity and the palette change with it.

## 4. Runes need icons that represent their shape

Symbols currently use SF Symbols (`mountain.2`, `leaf`, `snowflake`, `cloud.bolt.rain`). **They need icons that represent the actual rune shape** — the glyph as it would be drawn on the page.

This is the point where the writing system stops being a metaphor: the thing in the palette should be the thing that gets written. It also connects to the illustration work — the crude-hand glyphs are the first asset set needed, and they're needed here before anywhere else.

**Interim, if artwork isn't ready:** a placeholder that is clearly a *glyph* — abstract, monochrome, drawn-looking — rather than a pictographic app icon. A wrong-but-glyph-shaped placeholder is closer to right than a correct-looking SF Symbol.
