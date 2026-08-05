# Handoff — pressure model, sites, and audit rulings

Drop everything in `docs/` into the repo's `docs/`. Two of these **replace** files already there.

## Replaces existing files

| File | What changed |
|---|---|
| `writing-system-rune-spec.md` | **Vocabulary audit:** 156 → **149 base runes** (79 sources). Cut Starfield, Gale, Ember, Heartfire, Song, Weight/dense-air; Fumarole folded into Geyser. Audit note records what was cut and why so it doesn't drift back. Also fixed §2's wrong claim that refinement "dissolves the packing puzzle" — fitting runes on the page is deliberate gameplay throughout. |
| `decisions-session-4.md` | Same packing correction in the summary paragraph. |

## New

| File | What it is |
|---|---|
| `pressure-model-illumination.md` | **The pattern.** Fully worked: schema, source characters, base values, downstream effects. Read this first — the others follow its shape. |
| `pressure-model-thermal.md` | Fully worked. Introduces **retention** (sources that narrow the range without adding heat). |
| `pressure-model-hydrology.md` | Fully worked. Introduces **form** (standing/flowing/frozen/airborne) and **dispersion** (concentrated ↔ pervasive). |
| `pressure-model-remaining-five.md` | Substrate, Vitality, Relief, Atmosphere, Cycle — **deliberately rough**, enough to build against. Also holds the cross-target constraints and the energy budget. |
| `sites-system.md` | **Separate system** from pressures. Ruins, landmarks, hazards — things a world *contains*. Own trigger rules. Don't fold into targets. |
| `design-audit-session-5.md` | Audit of the repo against decisions, plus **rulings on your open questions** (Q10, Q11, override, satchel, rarity). |

## The rulings you're waiting on (all in the audit doc)

- **Manual override — keep as built (A), pre-emptive.** Ruled out the literal FF12 version: any intervene-during-their-turn design needs either a timer (forbidden) or a prompt every round. Nothing may resolve differently based on how fast the player reacts, or whether they reacted at all.
- **Satchel full — build the real prompt.** A notification is not a decision.
- **Rarity ladder — make it visible and colour-coded.**
- **Skill cooldown — blessed** as built.
- **Q10 banking overflow — never lose silently.** Build a spillover the Storehouse holds until sorted. Not auto-conversion to essence.

## Build notes for the pressure system

- **Schema:** every target resolves to net value(s) + **opposed magnitude** (tracked gross, never net — this is what makes contradiction visible) + modality tags. Shared 0–100 scale. Diminishing returns on stacking.
- **Two-valued targets: Illumination and Thermal only** (peak + floor). The other six are single-valued.
- **Each target has its own character axis** — they are not copy-paste. Illumination's describes *when* a source acts; Thermal's describes *add/hold/remove*; Hydrology's describes *what form*.
- **Build the cross-target constraints and the energy budget** (both in `remaining-five.md`). These are load-bearing, not polish — without them every world produces everything-creatures.
- **Light colour is mechanical**, not cosmetic.
- All numbers everywhere are `PLACEHOLDER`.

## Still open (not yours to resolve)

Q-A anchoring timing, the sustain economy, reality-layer reset, permanent-loss policy per layer, the quirk catalog — all still in `open-questions.md`.

---

## Added in the second batch — the story layer

| File | What it is |
|---|---|
| `narrative-systems-spec.md` | Travellers, **trails**, clues, diaries, the Library, named places, the great work |
| `companions-base-anchoring-spec.md` | Companions, recruitment, assignment, tavern, base buildings, **anchoring (Q-A)**, **sustain economy (Q-B)**, **reality reset (Q-C)**, **permanent-loss policy (Q-F)** — all four previously-open questions now have proposed resolutions |

**The structural idea worth reading first:** travellers are static, but they *travelled* before the game began, and their pages are scattered along that historical path. So the search is a **trail** — a page in one world describes the next world along their route, and the final page describes where they stopped. This keeps the honesty invariant trivially true, gives difficulty a natural knob (trail length), and turns clue-following into a chain rather than a lookup.

**Proposed resolutions to the four open questions** (override freely, but they're specced so the game is buildable end-to-end):
- **Anchoring:** two-step — cheap in-world **tether** preserves the seed, expensive **anchor** performed later at base.
- **Sustain:** upkeep charged on run completion, paid first from what the world produces via assigned workers; failure means **dormancy, not destruction**.
- **Reality reset:** player-initiated, knowledge/runes/named places/great work survive, with the gain **previewed before committing**.
- **Permanent loss:** un-banked haul yes; companions in unstable anchored worlds yes (the price of greed); people in the party, anchored worlds, and all knowledge never.

Build order for the story layer is in §7 of the companions spec.
