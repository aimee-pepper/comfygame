# Decisions Log — Session 14 (2026-08-05)

Append to `docs/decisions-log.md`. Aimee's decisions. **Supersedes the sigil grammar in `writing-system-rune-spec.md` §8**, which was Claude's invention.

---

## 1. The grammar: target first, then connected sources

A composition reads **target sigil → connected sigils**. You write the **Illumination sigil**, and connect sources to it.

This replaces Claude's invented `[qualifiers] → source → Bind → target` ordering.

## 2. Connection requires BOTH adjacency and a connector

**Sigils must be adjacent to connect** — but adjacency alone is not enough.

Why both are needed:
- **Adjacency alone fails**: the page is small, so on a full page nearly everything touches everything. Everything would connect to everything.
- **A connector alone fails**: you could link across the page and relative position would stop meaning anything.

**Together they do distinct jobs: adjacency constrains, the connector declares intent.** Two things touching are only joined if you say so.

### How connecting works (decided)

**A connect mode, entered by a button.** Then tap a sigil, tap an adjacent one — they're joined. Keep tapping onward to chain further sigils into the same cluster.

**No page space is spent on connections.** There is no connector rune occupying a cell; the link is a relationship, not an object. This matters on a page that holds about seven crude sigils.

### Linked sigils become ONE object

**Once linked, the whole cluster moves and rotates together.** You are not placing individual runes any more — you assemble a piece, then fit that piece onto the page.

Consequences:
- **Links can never break by accident.** Moving preserves the shape, so it preserves every internal connection.
- **Rotating a cluster is where the packing gameplay actually lives.** An L-shaped cluster of four sigils has to fit somewhere as an L. More interesting than rotating single runes, and it's the tetris framing made literal.
- **Unlinking splits a cluster back into movable parts.** **[OPEN]** whether breaking a mid-chain link yields two smaller clusters or loose sigils.

### Adjacent ≠ connected, and the page must show which

**Separate clusters can and must sit adjacent without connecting** — otherwise nothing could be packed next to anything else.

So the visual has to distinguish them unmistakably: **an outline around connected sigils**, marking a cluster as one object. Touching-but-unjoined clusters read as separate. Without this a page's meaning would live in an invisible adjacency graph and be unreadable.

## 3. CORRECTED INVARIANT — absolute position is meaningless, relative position is not

The old rule ("position on the page never affects outcome," with a test asserting any two arrangements produce identical worlds) is **superseded but only partly**.

**What still holds:** absolute position carries no meaning. The same cluster written top-left and bottom-right produces the same world.

**What changes:** *relative* position carries meaning. Which sigils touch which is the composition.

**The test to replace the old one:** translate every sigil by the same offset, or rotate the whole page — the resulting world must be byte-identical. Only the adjacency graph may affect outcome.

**Consequence:** arranging is now *writing*, not tidying. Packing stops being a container problem and becomes a semantic one. It also means a list UI can no longer stand in for the page — the grid is load-bearing.

## 4. QUALIFIER RULE — generic ladders first

**A qualifier earns its place only if no generic ladder covers it.**

**"Bright" is cut.** A great sun *is* a bright sun — it's a redundant word that only works on one target.

**But "big" is not one idea, and must not collapse into one word.** A big sun is *intense*; a big sea is *extensive*; a big swarm is *numerous*. Those are three existing ladders and merging them would lose real expressiveness — you could no longer write a small-but-blinding light, or a vast shallow sea.

**The three generic workhorses, applying across all eight targets:**
- **Intensity** (Faint · Moderate · Great · Overwhelming)
- **Scale** (Minute · Small · Large · Vast)
- **Count** (Single · Pair · Few · Many · Countless)

**Target-specific qualifiers survive only where no ladder can say it:**
- **Phase** (Frozen · Solid · Liquid · Vaporous) — genuinely hydrology-only, irreplaceable
- **Direction** (N/E/S/W) — celestial-only

Everything else in the 51-qualifier list gets re-examined against this rule. Expect cuts, which also means fewer runes to illustrate.

---

## Still open from this conversation

1. **Does breaking a mid-chain link** yield two smaller clusters, or loose sigils?
2. **Does the target sigil's presence stay mandatory?** With target-first ordering it's the anchor of the cluster, so probably yes — but confirm whether an unambiguous source can imply its target.
3. **Can qualifiers modify the target rather than the source?** Currently they scale the source only, so there's no way to say something about illumination itself independent of what produces it. Possibly fine; noting the limitation.
4. **Re-audit the 51 qualifiers** against §4.

## Noted for later — not now

**Footprint numbers** (crude 4–6 cells · plain 2–3 · refined 1×1) are **fine as placeholders**, but need finessing in a later version. They require manual sigil-generation effort until Aimee builds the sigil generator, so tuning them now would be wasted work.
