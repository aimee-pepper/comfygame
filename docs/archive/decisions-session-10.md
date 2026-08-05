# Decisions Log — Session 10 (2026-08-05)

Append to `docs/decisions-log.md`. Aimee's decisions, for the page-grid work currently in progress.

---

## 1. CORRECTION — the page never grows

`writing-system-rune-spec.md` §3 said the page starts at 6×6 and is "expanded by permanent (Reality/base) unlocks." **That was Claude's invention and it is wrong.** It contradicts the instrument progression, which is the actual design.

**The page is a fixed grid. It never grows.** You have one page your whole life. Progression is **learning to write smaller on it** — finer instruments shrink footprints, learned compounds compress meaning. That is the entire point of the burnt stick → pencil → fountain pen ladder.

Spec corrected.

## 2. The page fits on one screen

**No scrolling.** The whole page is visible at once while composing.

Practical consequence: on an iPhone in portrait, with the projection panel also on screen, that caps the grid at roughly **7–8 cells across** at a comfortable touch size. **Page size is a UI constraint, not a progression dial** — pick the size that makes a crude page feel constrained but not miserable, and leave it fixed.

Worth noting what this implies: at 6×6 (36 cells), crude runes at 4–6 cells give you about **seven** sigils on a page; refined 1×1 runes give you **thirty-six**. The progression is dramatic without the page changing at all.

## 3. Sigils can be picked up and moved

Placed sigils can be lifted and repositioned freely while composing. Arranging is not a one-shot commitment.

## 4. Compound sigils (glyphs) are assembled in a popup

**Assembling a composite sigil is unlocked in the skill tree**, not available from the start.

Once unlocked, assembly happens in a **smaller popup within the page-writing menu** — you build the glyph there, then place the finished thing on the page. Keeps the page itself purely about placement.

---

## Open (for Aimee, not to be assumed)

1. **When a sigil won't fit** — refuse the placement outright, or allow it and highlight the overflow so it can be rearranged?
2. **Does moving a placed sigil cost anything**, or is arranging free until you bind?
3. **Exact fixed page dimensions** — needs playtesting on device.
