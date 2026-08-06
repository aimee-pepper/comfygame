# Answers — Q21 to Q34

**Process note:** these piled up because my code audits weren't reading `questions-for-design.md`. They are now. Fourteen questions had been sitting unanswered.

Marked **[AIMEE]** where the call is genuinely hers. Everything else follows from decisions already made or is a recommendation she can overrule.

---

## Q21 — Chance-fills firing assertion contradictions — **CONFIRMED, and add the warning**

Aimee already ruled on the principle (session 12): *"the chance of punishment for leaving things up to chance is fine and part of the gameplay. it's a tradeoff."*

So: **they participate.** Ship the **middle option** — participate *and* warn. The preview should say plainly that what you've left to chance could contradict what you've written. That matches how the preview already works everywhere else: **cost is exact, outcomes are ranged**, and a warning is a statement about range.

Your safety analysis is the right one: negations can never happen by chance because chance has no rune to write, and that's the category that matters.

## Q22 — Two copies of the pressure model — **delete the four originals**

Keep the consolidated `pressure-model.md`. The four `pressure-model-*.md` files were only ever turn-by-turn fragments of one system. A stale duplicate under a "newest wins" rule is a real hazard.

## Q23 — Danger-rune cap breaking meter literalism — **keep the cap, keep the disclosure**

Right call and right implementation. The disclosed shortfall line is the same discipline §3 already requires for contradiction escalation, so there's precedent for a non-linear term that shows its working.

Your note that **the cap can't currently bite** is worth keeping visible rather than acting on — it's future-proofing for the page, and the test that will start failing when two runes fit is exactly the right alarm.

## Q24 — Energy budget pricing creatures out of their own worlds — **option 1 now, option 3 when flora lands**

Author around it for now. Appetite quietly encoding "how marginal is this" is a genuinely readable idea and it's already working.

**But option 3 is where this should end up, and flora is what makes it cheap.** `flora-system-spec.md` introduces a **metabolism axis** — photosynthetic, fungal, chemosynthetic — precisely so dark and dead worlds can support life. That's the alternative budget currency you're describing: a scavenger's budget comes from `decaying`, a dark-world creature's from chemosynthetic production. Once flora is in, the mechanism is already there and it's a wiring job rather than a new system.

The invariant you added — **a world always holds something** — is correct and should stay a permanent rule.

## Q25 — Cold worlds making smaller animals — **test it and adjust** (Aimee)

Poverty beating Bergmann is defensible: a frozen desert genuinely shouldn't grow giants, and Bergmann's rule is about endotherms in places that can still feed them.

**The test that matters is cold *plus* productive** — a cold sea, or a cold world with geothermal warmth and standing water. If a rich cold world still produces small animals, the thermal nudge really is too weak. If it produces large ones, the model is right and the spec's table just needs the caveat you describe.

**Aimee's ruling: test it and adjust as needed.** So add the cold-plus-productive case as a test rather than settling it by argument, and tune the thermal nudge against what it shows.

## Q26 — Ornament and finish circularity — **your cut is correct**

Allocation spends budget on `ornament`; `finish` follows from what was spent, plus pressure shifts. The other direction makes costly signalling free, which defeats the point of ornament being costly at all.

## Q27 — Colour needing depth and patterning — **correct addition, keep it**

A CMY triangle normalised to 100 carries hue and nothing else, and crypsis and aposematism are claims about *darkness* and *patterning*. The spec was underspecified; you fixed it. Both as free axes is right — colour shouldn't compete with armour for budget.

## Q28 — Naming vocabulary — **[AIMEE]**

Yours to write. The two constraints you've identified are the useful part: **order within a band matters** (mildest → strongest), and **an empty list means "not remarkable in that direction"**, which is a genuinely elegant way to encode that being *less* ornamented than average isn't worth saying.

Your lengthening of *close* → *short-limbed* was right; "close grazer" isn't English.

## Q29 — Composed fallback names sitting oddly beside matched ones — **[AIMEE]**, with a lean

Two readings, both defensible:
- **Keep them long.** The mismatch is informative — a thing that matches no known form *should* read as strange next to a *sable grazer*. This is what `name-generation-spec.md` §8.3 intended.
- **Shorten to two words** for a consistent list.

I lean toward keeping them long, but it's voice, which makes it Aimee's.

**One thing worth changing either way:** a composed name hands its *first* word to its materials, which is arbitrary. It should hand over its **most distinctive** word — the same rule that chose the name in the first place — so a *small shape* drops something that actually appears in its name.

## Q30 — Relief has no words of its own — **[AIMEE], but yes, add them**

Relief being unwritable was a real hole and `attachesTo` as a list is a good fix. The seven borrowed sources are a stopgap.

The proposed set — *mountain · canyon · plain · dune · terrace · scarp* — is good, evocative, and exactly the kind of thing the source vocabulary is short of (41 of a specced 79). **My recommendation is to add all six.** But adding to the core vocabulary is Aimee's call, and she may want different words.

## Q31 — Greed reading aspects or only magnitude — **selectively, not either option**

Neither of your two readings quite fits. The distinction that matters is **whether an aspect is asking for something valuable, or just describing a shape.**

- **Concentrated dispersion is greed.** Veins of ore concentrated where you can reach them are worth more than the same ore spread thin. That should cost.
- **Openness is not greed.** An open world isn't asking for value, it's asking for a shape.
- **Cycle amplitude and atmosphere motion are not greed** either — they're character, and dangerous character at that, which the danger-rune economy already prices.

So: **aspects that concentrate or increase value count toward greed; aspects that describe form don't.** That's more work than either option but it's the only version that doesn't either undercharge for real greed or tax the player for choosing a shape.

## Q32 — A lone cluster resolving to nothing — **don't explain it. This is what analysis tiers are for.**

Session 8 settled the principle: **opacity is the joy, and explanation is earned, not front-loaded.** So at tier 1 the preview says *"Nothing lives here"* and stops. Learning that darkness is what stopped the bloom **is the game**.

And it's a perfect fit for the analysis ladder: **naming the constraint that bit is exactly what tier 3 (attribution) should unlock.** So this isn't a gap — it's content for a system already specced. Add it as a tier-3 behaviour rather than as a tier-1 explanation.

## Q33 — Only the companion can carry a weapon — **option 2. The Binder gets its own slots.**

**My first answer to this was wrong and Aimee has already corrected it.** I endorsed option 1 — the party shares one weapon — on the grounds that it added no structure. No RPG works that way, and "adds no structure" is not a design argument.

**Every party member has their own gear slots.** That's the standard everywhere and it's what session 17's stats and classes assume: a character is a set of stats, a class, *and* their own equipment.

Option 3 is separately wrong — it would leave §1 giving the player nothing to decide.

## Q34 — Ranks — **BUILD THEM** (Aimee, session 17)

Standard JRPG front/back position: front takes the melee hits and deals full melee damage, back is protected but weakened in melee.

**Strike the "skip them" recommendation from `combat-depth-spec.md` §7.2** — that was my call and it's overruled.

Worth knowing *why* it changed: session 17 adds **character stats and classes**, which makes ranks considerably more valuable than they looked. A fragile high-Focus scholar standing behind a high-Fortitude front-liner is a real composition decision, not positional fiddling. My argument against was that everything else in combat derives from existing traits — that stops being true once characters have stats of their own.


---

# Session 17 supersedes several of the above

`decisions-session-17.md` lands alongside this and changes things these answers assumed:

- **Characters get stats, classes and levels.** `CompanionState` having no level, no XP and no stats came from Claude's v0 brief and was never a design decision. Five stats proposed (Might · Finesse · Fortitude · Perception · **Focus**, which governs gambit slots).
- **Mobs level too** — scaling slowly with the player, and higher in high-instability and high-greed worlds.
- **Ranks are wanted** (Q34 above).
- **Every party member has their own gear** (Q33 above).
- **Nobody dies.** Companions pass out and are revived in town; if the Binder passes out it's treated as a collapse — carried home, some of the run's haul lost.
- **No permanent loss at all for now.** Companions in unstable worlds, animal companions, and displaced tethers are all **no longer losable**. Revisit only when difficulty modes arrive.
- **An emergency escape item** — expensive or rare, forces an immediate return home, keeps the full haul.

**One knock-on worth surfacing:** companions being at risk in unstable anchored worlds was what made holding a greedy world expensive. That cost now needs paying another way — resource upkeep and dormancy are the obvious candidates, but it's open.
