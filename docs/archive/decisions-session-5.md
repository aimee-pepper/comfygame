# Decisions Log — Session 5 (2026-08-04)

Append to `docs/decisions-log.md`. Responds to `engineering-notes-session-4.md`.

*(Bookkeeping: you read it correctly — I mislabelled. Session 4's "N1, N2 and N3 are void" meant your session-3 N1 and N2, plus the N3 I had introduced in the same session-4 doc. Traveller movement and clue history are both off. My error.)*

---

## Approved without changes

**§2 — the page/language separation, and the invariant.** This is the best structural catch on the project. Yes: **where a sigil sits on the page never affects what the world becomes.** Build the test asserting that the same sigils in any two valid arrangements produce byte-identical worlds. If adjacency ever becomes desirable it is a deliberate decision, never a discovery.

The consequence you drew — a page is a multiset of sigils plus a proof it fits, so the save stores the sigil list as truth and layout as presentation — is right, and "same book, better hand" falling out for free is exactly the intent.

**§3 — contradiction measured gross, not net.** Correct, and this would have been a real bug. Track **net** (what the world becomes) and **opposed magnitude** (force applied in conflicting directions and cancelled) separately per target. Instability reads greed from abundance and contradiction from opposed magnitude. A world that is perfectly ordinary to stand in and violently unstable is precisely the flavor wanted.

**§4 — generate-twice-and-diff for the attributable reveal rule.** Elegant, and it's a good reason to keep worldgen pure as it grows. Confidence state in the Reality layer as described. On the threshold: yes, express "observable" as a **fraction of that target's total pressure**, not an absolute.

**§7 — sequencing.** Agreed. Milestone 5 first, then the writing system as its own milestone in the order §2 implies. The curio identify flow as a rehearsal for per-component identification is a good instinct.

---

## Q12. Named places — SAME INSTANCE (option A), with a resource caveat

Reinehaven is a real place. If it re-rolls on each visit it is a description, not a place, and "her family was in Reinehaven" stops meaning anything.

**Lore that makes this consistent rather than an exception:** named places are worlds that were **anchored long ago, by the people who came before**. That's *why* they persist and have names. This is load-bearing in three ways:

1. It explains persistence without special-casing.
2. It teaches anchoring before the player can do it — you visit anchored worlds for a long time before you learn to anchor your own, so the concept is familiar when it arrives.
3. It gives Q-A (when does the player anchor?) a natural narrative on-ramp.

**What persists between visits:**
- **Layout and structure** — same seed, same place, recognizably.
- **Unique things** — a unique item taken stays taken; a door opened stays open; a found page is not re-findable.
- **Ordinary resources replenish.** It's a living place, not a stripped mine. This avoids both bricking authored content and needing any clock to regenerate it.

Everything not a named place stays disposable and instanced as today.

## Q13. Precision — distance AND coverage, as you proposed

Approved as specced, including the three-outcome table (close+vague → a world that resembles it; close+specific → the place; far → elsewhere).

**Named places form a difficulty progression.** They are not uniformly gated — there's a ladder from easy-to-reach to hard-to-reach, and where a place sits on it is authored per place.

- **Early places** are reachable with a small common vocabulary and a loose description. They're how the player learns that named places exist at all.
- **Mid places** need more of their signature named, more tightly.
- **Late places** require rare vocabulary and enough page space (refined hands, compounds) to say something very specific.

The rare/hard-to-write conditions belong to the **later tiers**, not to every place. That keeps precision meaningful as a gate at the top of the ladder while letting the bottom of it be welcoming.

Practically: a place's tier is a function of how many conditions its signature demands, how tightly, and how rare the runes needed to express them are. Some late places should be unreachable until specific vocabulary is learned — which ties named places directly to the writing-system progression and gives long-hunted runes an obvious destination.

## Q14. Rotation — YES, free rotation

A rune drawn sideways is still that rune; the fiction doesn't object. Rotation makes crude irregular shapes tractable to arrange without removing the spatial decision — fitting runes on the page is deliberate gameplay, and it's where depth-versus-breadth actually gets decided. If glyph legibility suffers visually, rotate the glyph with the piece rather than restricting rotation.

---

## Two tuning flags (design-side, not engineering)

**`World.baseVisionRadius = 2` on a 14×14 grid may be too tight.** That's roughly 24 of 196 tiles visible; exploration risks feeling like groping rather than discovering, and a vision-reducing quirk pushing it to 1 leaves nowhere to cut. Suggest trying **3** as the baseline so quirks have room to bite. Playtest call, but worth testing 3 first.

**`World.lockedCacheChance = 0.5` needs a look alongside key drop rates.** Worlds are disposable, so a cache you can't open is gone permanently. That's a good "come back with a key" tease *if* players routinely carry keys — but at 50% players will often watch caches die unopened, which reads as taunting rather than tantalising. Either lower the rate or ensure key availability keeps pace. Worth deciding deliberately rather than discovering in playtest.
