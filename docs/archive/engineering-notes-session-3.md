# Engineering notes — response to Session 3 decisions

**From:** Claude Code · **To:** Aimee + designer Claude · **Date:** 2026-08-04
**Re:** `docs/decisions-log.md` § "2026-08-04 — Session 3", now filed.

Short one. All four answers landed cleanly and are either built or scheduled. Two forward-risks in
the narrative direction are worth naming now, while they're still free to design around.

---

## Built this session, off the session 2 + 3 answers

- **Slot count and types are now content** (`Content/Data/slots.json`). No enum, no
  `allCases`, no slot-count constant anywhere — storage, UI, validation and save format all read
  from that file. Rewriting the taxonomy for pressure sigils is now a data edit.
- **Flat-rate pricing.** Cost is one exact number on the Bind button; clearing a slot visibly drops
  the price. A test asserts the price is a point while stability stays a range — "the price is
  certain, the world is not," enforced rather than just intended.
- **Satchel decoupled** from the Storehouse: smaller, separately upgradeable, items only. Resources
  stay stackable and slot-free as confirmed.
- **Stale-draft pruning at launch**, so a book referring to slots or symbols that no longer exist
  after the content rewrite is dropped rather than lingering invisibly.

67 tests pass.

**On 4a (specimens):** the principle — *saves store observation, not interpretation* — is the right
one, and it generalises exactly as you said. Nothing needs building until traits exist, and today's
`DiscoveryLog` maps onto the **identity tier** as-is. The **specimen tier** is an added field when
the time comes; it won't reshape what's already stored.

---

## Two things in the narrative direction worth designing around now

### N1. "Travellers move between worlds over time" — over *what*, exactly?

The doc says travellers move over time, and also says no timers, ever, and nothing advances while
the player is idle. Those are compatible, but only if "time" here means **an in-session counter** —
runs completed, or world turns taken — and never a date.

I raise it because this is the first system that wants a world to change *between* the player's
visits, and that is precisely the shape of thing that accidentally reaches for a clock. If traveller
movement is indexed to runs completed, it stays pillar-safe by construction: close the app for a
month, come back, and nobody has moved — because you haven't done anything yet.

**What I'd build unless told otherwise:** a `worldClock` counter in the save that increments on run
completion, with all traveller movement a function of it. No `Date` anywhere near it.

### N2. "Clues are never wrong, but may be stale" needs traveller *history*, not just position

This is a lovely constraint and I want to make sure it survives contact with implementation. For a
stale clue to be **true-but-outdated** rather than false, the game has to be able to say "she *was*
in a cold, dim, mineral-rich world" and have that be a fact about the past.

That means either the traveller's **position history is recorded** in the save, or their whole path
is a deterministic function of their seed and the world clock, so any past position can be recomputed.

Either works; the second is cheaper and fits how everything else here is built. What doesn't work is
storing only "where they are now" and generating clue text from it — that's the version where a clue
can turn retroactively false, which is the one thing the rule forbids.

**The honesty invariant, stated mechanically:** every clue ever emitted must remain true *of the
moment it describes*. Worth writing into the design doc in those terms, because it's the property
tests can actually check.

---

## Small notes, no action needed

- **The Library costs almost nothing to add** — the base is a data-driven station list, so a new
  station is a JSON entry plus a screen. Good validation of that call.
- **"Highlight what matters, never what it means"** is a rule I can enforce in code: highlighting is
  a property of the *page*, and there is simply no code path from a highlight to a sigil. Cheap to
  guarantee if it's built that way from the start; near-impossible to walk back once a helpful
  tooltip exists.
- **Diaries as reward-not-gate** — noted, and it's a good instinct. Scattered-collectible gates are
  where players lose runs to bad luck rather than bad decisions.
- **Achievements as discovery records** fits the specimen tier neatly; percentile data is already
  implied by 4a, so "only prismatic one you've seen" is a query, not a new system.

---

## Next

Milestone 4: encounter screen, gambit engine, out-of-combat gambit editor, manual override — with
foes carrying resolved stat blocks in the save, per the approved forward-compat catch.
