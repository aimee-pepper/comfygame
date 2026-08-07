# Fossil Audit — things that no longer make sense

**Prompted by** *"The Fifth Mark: +1 symbol slot in every book you bind"* — an unlock for a system that no longer exists.

**Method:** looked for content and code that made sense when it was written and stopped making sense when something underneath it changed. This is a distinct failure from a bug: nothing is broken, it just doesn't mean anything any more.

---

## 1. The Fifth Mark — **dead, and it was dead on arrival**

`extra_symbol_slot`, three motes, *"+1 symbol slot in every book you bind."*

**Books have no symbol slots.** They had four — Terrain, Biome, Bounty, Quirk — and the page grid replaced them entirely. The unlock survived the replacement.

**And it was never connected even before that.** `RealityState.bonusBookSlots` is defined and **read by nothing** — grep returns exactly one hit, its own definition. It has never done anything at all.

**Cut it.** And it's worth a moment on how it survived: session 6 answered a question about what the fifth slot *should be* by saying **"defer it, make slots data-driven, don't build against a four-type model."** The deferral was right, the node stayed, and nobody came back for it.

## 2. The Kept Spring — **an unlock for a feature that doesn't exist**

`essence_head_start`, *"+10% starting essence after any future reset."*

**There is no reset.** No `resetBase`, no reality reset, no new-game-plus anywhere in `Rules/` or `Screens/`. This is a bonus that applies to an event the game cannot currently produce.

**Not a fossil exactly — a promissory note.** It's specced (session 17, `companions-base-anchoring-spec.md` §5) and reasonable to want. But **selling it now takes three motes for nothing**, and motes are rare.

**[PROPOSAL] hide it until a reset exists**, the way the Tannery and Apothecary were correctly held back rather than shipped as dead buttons.

## 3. The Long Instruction — **works, but it's about to be wrong**

`extra_gambit_slot`, *"+1 gambit slot for your **companion**."*

**It functions** — `GambitEngine` reads `bonusGambitSlots`. But it's written for **the** companion, singular, from when there was one hardcoded slot. **There's a roster of five now.**

**Two questions this raises, both real:**
- **Does the bonus apply to everyone, or one person?** Everyone is the obvious reading and much more valuable, which means it may be underpriced at three motes.
- **Session 17 gives gambit slots to Wit.** So slots will come from a stat, a research node (`longer_instruction` ×2), *and* a Constellation node. **Three sources for one number** wants deciding rather than accumulating.

## 4. `symbol.slot` — the taxonomy is gone but every symbol still declares one

All 21 symbols carry `"slot": "terrain"` and the like, and `slots.json` still exists with a content-check that **fails the build if it's empty**: *"books would have nowhere to put a symbol."*

**Books put symbols on a page now.** The palette groups by **subject**, not by slot.

**Not urgent** — it's inert data, and `SlotID` is still used for *gear* slots, which is a different thing with the same name. But it's a trap: the next person to read `slot` on a symbol will reasonably think it means something.

**[PROPOSAL]** remove `slot` from symbols and retire `slots.json` once the old draft path goes (§5). Keep `SlotID` for gear.

## 5. The old draft/slot projection path is still there

`BookProjection.project(draft:)` and `BookRules.resolveBook(draft:)` are the **pre-page** implementation — slot plans, per-slot candidates, random-fill by slot. The UI is page-only; the sole remaining reference is **a SwiftUI preview** (`PreviewPanel.swift:284`) building a fake two-slot draft.

**It's dead except for a preview.** It also contains the **only correct stability-range logic in the codebase** (`stabilityLow`/`stabilityHigh` over unfilled slots), which the page path doesn't do — that's the bug in `illumination-void-and-stability.md` §3.

**So: don't just delete it.** Move the range logic to the page path *first*, then remove the draft path. Otherwise the one place that got uncertainty right disappears with it.

---

## 6. The pattern, and a cheap guard

All five are the same shape: **a thing was built correctly, the ground moved, and the thing stayed.** None is a bug; each is a small lie the game tells about itself.

**[PROPOSAL] When a system is replaced, the replacement isn't done until its predecessor's content is gone too.** The page grid replaced slots in the *interface* and left the slot vocabulary in content, the Constellation, and a dead projection path.

**A cheap test that would have caught three of these:** assert that **every Constellation node's effect is read somewhere**, the same way the research tree already asserts no node is unreachable. Anything granting a value nothing consumes is a fossil by definition.
