# Design referrals from BACKLOG — worked through

Everything in `BACKLOG.md` marked open that needs design rather than engineering. I've answered what I can and flagged what's genuinely Aimee's.

---

## 1. Re-audit the qualifiers against session 14 — **done; the list is already correct**

Session 14's rule: *a qualifier earns its place only if no generic ladder covers it.*

**Built today: 17 qualifiers across four ladders** — Intensity (4), Scale (4), Count (5), Phase (4). Against my specced 51.

**Auditing the built set: all seventeen pass.** Intensity, Scale and Count are the three generic workhorses; Phase is genuinely hydrology-only and irreplaceable. Nothing here is redundant.

So the shortfall isn't a pruning job — **the cuts already happened, correctly.** What's left is deciding which of the *unbuilt* ladders survive the same rule:

| Proposed ladder | Verdict |
|---|---|
| **Colour (12)** | **Keep, but not as a ladder** — colour isn't ordered, so it's a set, not a scale. Needed for creature crypsis, iridescence and material inheritance. |
| **Constancy (4)** | **Keep** — constant/cyclic/seasonal/erratic can't be said by Intensity, and Cycle needs it. |
| **Elevation (4)** | **Merge into Scale?** — "high" and "vast" are different, so probably keep, but it only matters once Relief has its own sources (Q30). |
| **Direction (4)** | **Keep** — celestial-only, irreplaceable, small. |
| **Distribution (4)** | **Cut.** Scattered/clustered/banded/uniform is **dispersion**, which is already a target *aspect*. Saying it twice invites disagreement between the two. |
| **Finish (5)** | **Cut as qualifiers.** Finish is derived from creature traits and material properties; writing it on a world is the wrong direction of causation. |

**Net: roughly 17 → 41**, not 51. And "bright" stays cut.

## 2. The three grammar opens (session 14)

### Does breaking a mid-chain link give two clusters, or loose sigils? — **[PROPOSAL] two clusters**

A cluster is one object that moves and rotates whole. Breaking one link should sever it into **two intact objects**, each keeping its internal links. Exploding a five-sigil cluster into five loose pieces because you cut one link would punish experimentation, and session 14 made arranging deliberately exploratory.

### Is the target sigil mandatory? — **[PROPOSAL] yes, mandatory**

Session 14 made the grammar target-first: a cluster *is* a target with sources connected into it. Letting an unambiguous source imply its target would mean two ways to write the same thing, and the implied version would silently stop working the moment a second source became eligible for that target.

Also practical: the palette is organised by target, exclusivity is per target, and the description panel reads per target. Making the target optional puts a hole in all three.

### Can qualifiers modify the target rather than the source? — **[AIMEE]**

Currently they scale the source only, so there's no way to say something about *illumination itself* independent of what produces it.

Worth asking whether that's a limitation you want. "Great sun" and "great illumination" mean different things — the first is one big light, the second is a bright world however it got that way. **My lean: keep it source-only.** Writing causes rather than settings is the whole design, and a qualifier on a target is a setting.

## 3. Over-hanging placement — **[AIMEE], though I'd change it**

Currently a rune that won't fit is **refused**. Session 11 asked for it to **glow red and not be counted**, which is a different thing — you should be able to reach for it and watch it refuse, not have it silently unavailable.

**My reading: allow the drag, show it red, refuse the drop.** That's the conservative behaviour *and* the legible one.

## 4. Cycle's own sources — **[AIMEE]: cut the list**

Eleven candidates in `cycle-sources-draft.md`, waiting on you. He's explicitly holding off because *"adding core vocabulary isn't mine to do."* Cycle is currently the only target with no primaries of its own.

Tightest four if you want the short answer: **Tide, Orrery, Stillness, Drift.**

## 5. Scale and Count are written but consume nothing

Both are read back and displayed; nothing downstream uses them. **Scale already has a job specced** — world size, session 13 — so that's a wiring gap rather than a design one.

**Count needs a job.** **[PROPOSAL]** it should multiply a source's *presence* rather than its intensity: "many suns" is a different world from "one great sun." That distinction is exactly what session 14 protected when it refused to collapse Intensity, Scale and Count into "big."

## 6. Crafting trades — **[AIMEE]**

Q37 answered the Tannery/Apothecary question; the **full list of trades** is still open. Now more interesting than it was, because session 17 ties a companion's class to what they were before the sundering — so **the trade list and the class list are the same list.**

## 7. Salvage — **[PROPOSAL] yes, and it should be the Blacksmith's**

Breaking down gear you don't want, returning some material. Fits the reforging station, keeps the hoard from clogging with obsolete pieces, and gives the bin system something to do beyond storage. Low risk.

## 8. Tutorial — **[AIMEE], and he's right that it's needed**

Four vocabularies, connection, clusters, rotation, exclusivity. Not discoverable cold.

But this collides with session 8: **opacity is the joy and explanation is earned.** The resolution is that those apply to *consequences* — what a sun does to a world — not to *interface*. Teaching that runes connect by adjacency is not the same as telling someone their sun will warm the world. A tutorial should teach the grammar and stay silent about outcomes.

## 9. Device-testing items — **[AIMEE]**

Exact page dimensions, the stability→turns curve against 18×18 (audit #6), day length, viewport. All want playing rather than arithmetic.
