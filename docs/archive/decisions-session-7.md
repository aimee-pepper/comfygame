# Decisions Log — Session 7 (2026-08-05)

Append to `docs/decisions-log.md`. **Supersedes parts of `narrative-systems-spec.md` §1–3** — the trail model there was Claude's invention and is corrected below. All decisions here are Aimee's.

---

## The search loop, corrected

### Distance is difficulty of description, not hops

**Disregard hop count entirely.** A traveller is not "N worlds away." A traveller is **at a condition signature**, and what varies is how hard that signature is to *write*.

- An **early** traveller sits somewhere a starting vocabulary can describe — "any sunny world."
- A **late** traveller sits at a hyper-specific signature needing rare runes and page space you don't have yet.

So search difficulty scales off the **writing system**, not off traversal. The multi-hop "trail" model in `narrative-systems-spec.md` §1 is **wrong and should be removed** — long journeys exist, but as a *range*, not the default shape.

### Trail length is a scaling range

Most travellers are found straightforwardly once you can write their signature. **Long, elaborate searches are reserved** for exceptional companions and for ones that make sense later in the story. Do not make length the norm.

### Pages are partial descriptions that accumulate

**The number of location pages scales with signature complexity.**

- Simple signature ("a sunny world") → **one page** says it all.
- Complex signature → **each page names another piece of it**, and you assemble the description across several.

Pages are a **guide, never a gate**: a traveller is simply *at* a signature, so a player who writes the right world — deliberately or by luck — finds them without ever reading a page. A lucky early clue leading to a late-game character is fine and should not be prevented.

**Consequence worth protecting:** partial knowledge is playable. Knowing four of six conditions means either hunting for more pages or writing what you know and **leaving the rest to chance-fill** — a real gamble with a real price, since binding costs essence. This is the first place leaving slots empty is strategically meaningful rather than merely cheap.

### One page, one unlock

Each page unlocks exactly **one** thing. Page unlock types:

- A piece of a traveller's location description
- Another companion's whereabouts
- A specific world worth writing
- A ruin's existence
- A symbol, taught outright
- **A head start on a research node** (partial progress, not the finished thing)

### All pages come from travellers' diaries

There is **no separate class of found writing** — no scholar's notes, no workshop records. Everything is somebody's diary. This is what makes completing the diary of an easy-to-find companion coherent: you already have the person, and their diary is still scattered and still paying into four other systems.

**Diaries contain all page types, with a slight lean toward the author's specialisation.** An archaeologist's diary skews toward ruins and research leads; a wanderer's toward places and people. A soft preference, not a hard filter — so chasing a *particular* person's diary can be motivated by what they knew.

### Page placement: weighted, with a fallback

Pages prefer worlds **relevant to their author** — an archaeologist's pages surface in worlds with ruins. But if the player hasn't generated a matching world after **a set amount of exploring/generation [PLACEHOLDER threshold]**, the system stops waiting and places those pages **anywhere**.

Nothing is permanently unreachable because of how a player happens to write.

### The Library: a hint page per diary

Each diary gets a **hint page** that accumulates as pages are found — a single place where everything known about that traveller's location is assembled.

Rules:
- **It collects, it does not interpret.** The hint page assembles the actual passages ("no shadow anywhere," "warm to the touch a foot down") side by side, with gaps shown as gaps. It never renders them as a condition list, and never names a sigil, target, or value. The player does the translation.
- **It shows how many pieces are still missing** — a count only. Knowing you have four of six tells you whether to keep hunting or gamble.
- **It does not show what *kind* of piece is missing.** That crosses the line into interpretation.

---

## Anchoring (Q-A) — RESOLVED. Three routes, not two.

Supersedes the two-step tether/anchor proposal in `companions-base-anchoring-spec.md` §3.

Anchoring is accessible **multiple ways**:

1. **Anchor at bind.** Pay the cost up front and the world is born anchored. This is how you deliberately build a world for a purpose — a grazing world you intend to staff with companions — without gambling on finding anything inside it.
2. **Find an anchor point in-world.** A site the world may generate; reach it and anchor there. Cheapest route, but you must survive to it.
3. **Place an anchor manually with an expensive crafted item.** For when hunting for a natural anchor point before collapse is too risky. The item is a genuine treasure and gives crafting a high-value sink.

All three produce the same result: a permanent, revisitable world.

**Open:** relative costs, and whether route 1's premium is large enough that routes 2 and 3 stay attractive.

---

## Still Claude's inventions, awaiting Aimee's review

Flagged so they aren't mistaken for decisions. In rough order of how much rests on them:

1. **Implicit secondary effects** — a source bound to one target also affects others (sun warms).
2. **Contradiction as an instability source** — "a sun that does not warm" is writable and unstable.
3. **"Named places were anchored long ago by the people who came before"** — invented lore now load-bearing.
4. **The great work's structure** — 5–7 components, each needing a rare material *and* a named person's knowledge.
5. **Companion "wants"** as the recruitment mechanic.
6. **Sustain economy** — upkeep on run completion, paid from production, failure means dormancy.
7. **Reality reset** — trigger, what survives, what resets.
8. **Permanent-loss policy** — the whole table.
9. **The 149-rune vocabulary** — reviewed only in part.
10. **System-shaping calls** — source characters, cross-target constraints, energy budget, material properties, crafting buildings, gear slots, site categories, unidentified-compound reveal rule, page size and footprints.
