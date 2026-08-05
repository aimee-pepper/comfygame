# Decisions Log — Session 12 (2026-08-05)

Append to `docs/decisions-log.md`. From Aimee testing.

---

## 1. The gambit UI is unusable and must be rebuilt

Currently: a **modal sheet** with "When" and "Then" sections and a stack of `Picker`s. You leave the list, assemble a rule through pickers, come back. That is nothing like FF12 and it's painful.

**What FF12 got right, and what to copy:**

- **The whole priority list is visible at once**, numbered. You read your party's logic top to bottom without opening anything.
- **One rule is ONE ROW.** Condition on the left, action on the right.
- **Editing happens in place.** Tap a part of the row, change it, done. **No modal sheet.**
- **Drag to reorder.** Priority is positional and reordering is the main act of authoring, so it must be effortless.
- **Toggle a rule on/off** without deleting it, so you can experiment.

**The complication, and the answer.** Our rules have five components (subject · property · comparator · threshold · action) where FF12 had two dropdowns. **Granularity is a content decision, not a UI one** — it must still read as one line.

**[PROPOSAL — Aimee to confirm]** Render each rule as a **tappable sentence**:

> `2. Ally · HP · < · 30% → Mend`

Every segment is individually tappable; tapping one opens a compact inline picker for that segment only, in place, without leaving the list. Unset segments show as placeholder chips (`Ally · HP · ? · ?`), so a half-written rule is still readable and you can see exactly what's missing.

Whatever the final form: **the list stays visible, editing is in place, and reordering is a drag.**

## 2. The research trees are not trees

They're collapsible lists of rows. Prerequisites exist in the data but are never drawn.

**They must render as actual trees** — nodes with visible edges to their prerequisites, so you can see what leads where and plan a route. The branching structure is the point; a list of rows with hidden dependencies is just a shop with extra steps.

## 3. Crafting buildings come from PEOPLE, not research

**Remove the Forge / party-modification section from research.** Modifying party members through a research node is not how this works and never was.

**Crafting buildings arrive as you recruit the people who staff them** — a blacksmith, an armorer, a bowyer, and so on. You don't research a smithy; you find a smith.

This supersedes `materials-crafting-spec.md` §6, which had three research-unlocked buildings (Blacksmith / Tannery / Apothecary). The building set is now **larger, more specialised, and companion-gated** — which ties crafting to the search loop and gives recruiting a concrete mechanical payoff beyond party slots.

**[OPEN]** the full list of crafting trades, and whether a recruited specialist *is* the building or unlocks the ability to build it.

## 4. Gear is lootable in the wild

Until custom crafting exists — and after — **gear should be findable**. Party members need something to wear before there's a smith to make it.

**Sites are the right home for better-than-average gear.** This fits the Q17 ruling (ruins pay knowledge and unique items, never currency): gear *is* the unique-item reward. It also gives sites a reward identity that ordinary nodes can't match, and it means walking to a site with a full satchel is worth it.

Suggested distribution: ordinary gear from encounters and common finds; **notably better gear from sites**, especially ruins, where it reads as something left behind by someone.

---

## Consequences for existing docs

- `materials-crafting-spec.md` §6 — building list superseded (see §3 above).
- Research content — the Forge branch needs removing; its non-party contents may need rehoming.
