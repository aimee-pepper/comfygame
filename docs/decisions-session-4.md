# Decisions Log — Session 4 (2026-08-04)

Append to `docs/decisions-log.md`. Responds to `engineering-notes-session-3.md`.

---

## N1–N3. Traveller movement — CANCELLED. Travellers do not move.

**Reverse the session-3 direction. Travellers hold static positions.** Their scattering and wandering happened in the *past*, before the player began searching — that's why pages by one person are found across several worlds. Nobody relocates during play.

Rationale: a found page must still point true. If travellers moved live, a diary could stop describing where its author actually is, which destroys the entire premise of the search. **Do not build the `worldClock` traveller machinery, deterministic paths, or cadence rules.** N1, N2, and N3 from session 4 are void.

The honesty invariant still stands and gets easier: *every clue must remain true of the moment it describes* — trivially satisfied when positions don't change. Clues describe the past because pages are old, not because anyone is in motion.

(`worldClock`-style counters remain the correct pattern for anything that genuinely must change between visits. Nothing currently does.)

## N4. Clues: mostly simple, sometimes cross-referencing

**Most clues point at one thing** — a place, or a person, or a condition. Straightforward single-thread pointers, and that's the normal case.

**Some** pages reference other travellers or places by name, e.g.: *"I'll be trying to stop by Reinehaven, I think maybe Serena had family there so maybe I can find her and resupply on water before I make the desert trek."* That one carries Marek's destination, Reinehaven's existence, Serena's connection to it, and a desert beyond.

So the clue set is a **list with some cross-links in it** — not a fully interconnected web. Build for the simple case; support the linked case.

Consequences of the linked subset:
- Some pages about an already-found person retain value by advancing other threads.
- Travellers need optional **relationship references** (who mentions whom), not a full relationship graph for everyone.
- Generic procedural travellers can carry simple clues only; cross-references can stay authored.

## N5. Named places — worlds are DESCRIBED, not created

Taking the Myst-derived lore literally, and it resolves how a diary can name a place:

**Most descriptions link you to some world matching them. A sufficiently precise description links you to a specific, real, named place.** Reinehaven exists independently of the player. Writing "cold, coastal, mercury ponds" gets you *a* cold coastal mercury world; writing it precisely enough gets you **Reinehaven itself**.

This gives the page's depth-vs-breadth tradeoff a narrative engine: **breadth explores, precision arrives somewhere specific.** It's also why finding people requires literacy — you must be able to write your way to an actual address.

Implications to design around:
- Named places are **authored content** with a defined condition-signature and a precision threshold for linking to them.
- A named place should be **discoverable by accident** at low precision (you land somewhere that *resembles* Reinehaven, or brushes its edges) and reliably reachable once you can write precisely enough.
- Precision comes from page space, refined hands, and compounds — so the whole writing-system progression is in service of reaching specific places.
- Travellers, diaries, and named places are one system: people are *at* places, pages *name* places, and writing precisely is how you get there.

---

## Writing system — redesigned; expect a content rewrite

Full spec: `writing-system-rune-spec.md` (Aimee's illustration doc). Summary of what it means for the build:

**Books become a spatial grid, not a slot list.** Sigils are tetris-like pieces placed on a page grid. Page size is permanent progression; essence remains the per-bind consumable. This supersedes the slot taxonomy — but your `slots.json` work is what makes it a data edit rather than a rewrite, so the timing is good.

**Four rune classes:** Targets (8, fixed — the world's dials), Sources (86, growing — concrete causes), Qualifiers (51, reusable modifiers), Structural (11, grammar). 156 base runes total.

**A sigil is self-contained:** `[qualifiers] → source → Bind → target`, assembled internally and placed as one unit. **No page-wide adjacency effects** — neighbours never interact. This was a deliberate design choice to keep the page readable on a phone.

**Footprint shrinks with instrument:** crude (charcoal) 4–6 cells and irregular; plain (pencil) 2–3 cells; refined (fountain pen) always 1×1. Same glyph throughout — it's a font change, not a new symbol. Refined tier dissolves the packing puzzle entirely, which is the intended late-game arc.

**Compounds** are learned single glyphs meaning several components at a reduced footprint (proposal: `ceil(sum × 0.6)`). Stored in a player **runebook**. Acquired by inventing, finding in the wild, learning from diary pages, or from NPCs.

**Two new proposals with mechanical weight:**
- **Implicit secondary effects.** A source bound to one target also contributes secondary pressures automatically (a Sun bound to Illumination also warms). This is what makes the system causal rather than a set of sliders.
- **Contradiction as an instability source.** "A sun that does not warm" is writable, and deeply unstable. Instability now has two origins: **greed** (abundance/value) and **contradiction**. Fits the Myst lore and gives advanced writers a reason to court danger deliberately.

**Unidentified compounds** (found in the wild) are usable immediately, identified per-component, and reveal a component when its effect is *attributable* — i.e. not masked by another source acting on the same target. Sparse pages become laboratories. Subtle components need evidence accumulated across multiple bindings, with a **confidence meter per unknown slot** (required — without it, slow reveals feel broken). Identifying an unseen component **grants that base rune outright**. Full mechanics in §10 of the spec.

**Not blocking milestone 4.** Encounters and gambits are unaffected.

---

## Small confirmations

- **Library highlighting enforced in code** — yes, please build it so there is no code path from a highlight to a sigil. Exactly right that it's cheap now and near-impossible to walk back later.
- **Specimen tier as an added field** — agreed, nothing to build until traits exist.
- **Achievements as queries over the specimen tier** — agreed, and it's why that structure was chosen.
